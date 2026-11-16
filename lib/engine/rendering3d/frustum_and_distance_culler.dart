// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import 'scene_3d_math_projection.dart';

/// Kategoria obiektu 3D poddawanego rygorystycznemu odrzucaniu (Culling).
enum CullableObjectCategory {
  rider('Kolarz', 1.35),
  tree('Drzewo', 4.5),
  building('Budynek', 9.0),
  roadProp('Element trasy', 3.0);

  final String label;
  final double defaultBoundingRadiusMeters;

  const CullableObjectCategory(this.label, this.defaultBoundingRadiusMeters);
}

/// Powód natychmiastowego odrzucenia obiektu przed rzutowaniem wielokątów.
enum CullRejectionReason {
  none('Widoczny'),
  behindCamera('Za kamerą'),
  beyondMaxDistance('Poza zasięgiem (>450 m)'),
  outsideFrustum('Poza bryłą widzenia (Frustum)'),
  invalidCoordinates('Nieprawidłowe współrzędne');

  final String label;
  const CullRejectionReason(this.label);
}

/// Krzywa zanikania mgły odległościowej przed granicą odcięcia 450 m.
enum DistanceFogCurve {
  linear('Liniowa'),
  smoothstep('Smoothstep (płynna)'),
  exponentialSquared('Wykładnicza');

  final String label;
  const DistanceFogCurve(this.label);
}

/// Konfiguracja systemu odrzucania obiektów poza polem widzenia i dystansem.
class FrustumCullingConfig {
  /// Bezwzględna granica odległości renderowania [m]. Domyślnie 450.0 m.
  final double maxRenderDistanceMeters;

  /// Minimalny dystans przed płaszczyzną kamery (Near Clip) [m].
  final double nearClipMeters;

  /// Odległość, od której zaczyna narastać mgła odległościowa [m].
  final double fogStartDistanceMeters;

  /// Odległość pełnego zaniknięcia w mgle [m] (zazwyczaj równa [maxRenderDistanceMeters]).
  final double fogEndDistanceMeters;

  /// Funkcja przejścia mgły odległościowej.
  final DistanceFogCurve fogCurve;

  /// Kolor horyzontu / mgły atmosferycznej używany do wygaszania odległych obiektów.
  final Color fogColor;

  /// Czy włączyć natychmiastowe odrzucanie obiektów za plecami kamery (iloczyn skalarny).
  final bool enableBehindCameraCulling;

  /// Czy włączyć odrzucanie 6 płaszczyznami bryły widzenia (Frustum).
  final bool enableFrustumPlanesCulling;

  /// Dodatkowy margines bryły widzenia [m] (0.0 = rygorystyczne obcinanie).
  final double frustumMarginMeters;

  const FrustumCullingConfig({
    this.maxRenderDistanceMeters = 450.0,
    this.nearClipMeters = 0.35,
    this.fogStartDistanceMeters = 280.0,
    this.fogEndDistanceMeters = 450.0,
    this.fogCurve = DistanceFogCurve.smoothstep,
    this.fogColor = const Color(0xFF94A3B8),
    this.enableBehindCameraCulling = true,
    this.enableFrustumPlanesCulling = true,
    this.frustumMarginMeters = 0.0,
  });

  FrustumCullingConfig copyWith({
    double? maxRenderDistanceMeters,
    double? nearClipMeters,
    double? fogStartDistanceMeters,
    double? fogEndDistanceMeters,
    DistanceFogCurve? fogCurve,
    Color? fogColor,
    bool? enableBehindCameraCulling,
    bool? enableFrustumPlanesCulling,
    double? frustumMarginMeters,
  }) {
    return FrustumCullingConfig(
      maxRenderDistanceMeters: maxRenderDistanceMeters ?? this.maxRenderDistanceMeters,
      nearClipMeters: nearClipMeters ?? this.nearClipMeters,
      fogStartDistanceMeters: fogStartDistanceMeters ?? this.fogStartDistanceMeters,
      fogEndDistanceMeters: fogEndDistanceMeters ?? this.fogEndDistanceMeters,
      fogCurve: fogCurve ?? this.fogCurve,
      fogColor: fogColor ?? this.fogColor,
      enableBehindCameraCulling:
          enableBehindCameraCulling ?? this.enableBehindCameraCulling,
      enableFrustumPlanesCulling:
          enableFrustumPlanesCulling ?? this.enableFrustumPlanesCulling,
      frustumMarginMeters: frustumMarginMeters ?? this.frustumMarginMeters,
    );
  }
}

/// Wynik ewaluacji widoczności pojedynczego obiektu 3D.
class CullDecision {
  /// Czy obiekt powinien zostać przekazany do rzutowania wielokątów.
  final bool isVisible;

  /// Przyczyna odrzucenia (lub [CullRejectionReason.none] gdy widoczny).
  final CullRejectionReason rejectionReason;

  /// Odległość euklidesowa od kamery [m].
  final double distanceMeters;

  /// Rzut odległości na oś patrzenia kamery [m] (ujemny = za kamerą).
  final double forwardDepthMeters;

  /// Współczynnik mgły w zakresie [0.0, 1.0] (0.0 = brak mgły, 1.0 = pełne zaniknięcie).
  final double fogFactor;

  /// Mnożnik krycia (opacity) wynikający z mgły: `1.0 - fogFactor` w [0.0, 1.0].
  final double opacityMultiplier;

  const CullDecision({
    required this.isVisible,
    required this.rejectionReason,
    required this.distanceMeters,
    required this.forwardDepthMeters,
    required this.fogFactor,
    required this.opacityMultiplier,
  });

  const CullDecision.rejected({
    required this.rejectionReason,
    this.distanceMeters = double.infinity,
    this.forwardDepthMeters = 0.0,
  })  : isVisible = false,
        fogFactor = 1.0,
        opacityMultiplier = 0.0;
}

/// Element zakwalifikowany do renderowania wraz z jego głębokością i współczynnikiem mgły.
class CulledRenderEntry<T> {
  final T item;
  final double distanceMeters;
  final double forwardDepthMeters;
  final double fogFactor;
  final double opacityMultiplier;

  const CulledRenderEntry({
    required this.item,
    required this.distanceMeters,
    required this.forwardDepthMeters,
    required this.fogFactor,
    required this.opacityMultiplier,
  });
}

/// Zagregowane statystyki odrzucania z jednej klatki renderowania.
class CullingFrameStats {
  final int totalEvaluated;
  final int visibleCount;
  final int rejectedBehindCamera;
  final int rejectedBeyondDistance;
  final int rejectedOutsideFrustum;
  final int rejectedInvalid;
  final int ridersEvaluated;
  final int ridersVisible;
  final int treesEvaluated;
  final int treesVisible;
  final int buildingsEvaluated;
  final int buildingsVisible;

  const CullingFrameStats({
    this.totalEvaluated = 0,
    this.visibleCount = 0,
    this.rejectedBehindCamera = 0,
    this.rejectedBeyondDistance = 0,
    this.rejectedOutsideFrustum = 0,
    this.rejectedInvalid = 0,
    this.ridersEvaluated = 0,
    this.ridersVisible = 0,
    this.treesEvaluated = 0,
    this.treesVisible = 0,
    this.buildingsEvaluated = 0,
    this.buildingsVisible = 0,
  });

  int get totalRejected => totalEvaluated - visibleCount;

  double get cullRatePercent =>
      totalEvaluated == 0 ? 0.0 : (totalRejected / totalEvaluated) * 100.0;
}

/// Rygorystyczny system odrzucania obiektów poza polem widzenia kamery i dystansem > 450 m.
///
/// Zapewnia natychmiastowe pomijanie rzutowania wielokątów dla kolarzy, drzew i budynków:
/// 1. Wczesne odrzucenie obiektów za plecami kamery (iloczyn skalarny z wektorem patrzenia, bez sqrt).
/// 2. Natychmiastowe odrzucenie obiektów powyżej [FrustumCullingConfig.maxRenderDistanceMeters] (450 m).
/// 3. Test 6 płaszczyzn bryły widzenia (Frustum) bez alokacji pamięci w pętli klatki.
/// 4. Wyliczenie płynnego zanikania mgły odległościowej na krańcu zasięgu widoczności.
class FrustumAndDistanceCuller {
  FrustumCullingConfig config;

  // Stan kamery w płaskich zmiennych skalarnych dla maksymalnej wydajności (Zero-GC)
  double _camX = 0.0;
  double _camY = 2.0;
  double _camZ = -6.0;

  double _fwdX = 0.0;
  double _fwdY = 0.0;
  double _fwdZ = 1.0;

  double _rightX = 1.0;
  double _rightY = 0.0;
  double _rightZ = 0.0;

  double _upX = 0.0;
  double _upY = 1.0;
  double _upZ = 0.0;

  double _tanHalfFovY = 0.577350269; // tan(60 deg / 2)
  double _tanHalfFovX = 1.026400478; // 16:9

  // 6 płaszczyzn frustuma: [nx, ny, nz, constant] x 6 = 24 wartości double
  final Float64List _planes = Float64List(24);
  bool _hasFrustumPlanes = false;

  // Liczniki bieżącej klatki
  int _totalEvaluated = 0;
  int _visibleCount = 0;
  int _rejectedBehindCamera = 0;
  int _rejectedBeyondDistance = 0;
  int _rejectedOutsideFrustum = 0;
  int _rejectedInvalid = 0;
  int _ridersEvaluated = 0;
  int _ridersVisible = 0;
  int _treesEvaluated = 0;
  int _treesVisible = 0;
  int _buildingsEvaluated = 0;
  int _buildingsVisible = 0;

  FrustumAndDistanceCuller({
    this.config = const FrustumCullingConfig(),
  });

  /// Resetuje liczniki statystyk przed rozpoczęciem nowej klatki renderowania.
  void beginFrame() {
    _totalEvaluated = 0;
    _visibleCount = 0;
    _rejectedBehindCamera = 0;
    _rejectedBeyondDistance = 0;
    _rejectedOutsideFrustum = 0;
    _rejectedInvalid = 0;
    _ridersEvaluated = 0;
    _ridersVisible = 0;
    _treesEvaluated = 0;
    _treesVisible = 0;
    _buildingsEvaluated = 0;
    _buildingsVisible = 0;
  }

  /// Zwraca migawkę statystyk z bieżącej klatki.
  CullingFrameStats get currentStats => CullingFrameStats(
        totalEvaluated: _totalEvaluated,
        visibleCount: _visibleCount,
        rejectedBehindCamera: _rejectedBehindCamera,
        rejectedBeyondDistance: _rejectedBeyondDistance,
        rejectedOutsideFrustum: _rejectedOutsideFrustum,
        rejectedInvalid: _rejectedInvalid,
        ridersEvaluated: _ridersEvaluated,
        ridersVisible: _ridersVisible,
        treesEvaluated: _treesEvaluated,
        treesVisible: _treesVisible,
        buildingsEvaluated: _buildingsEvaluated,
        buildingsVisible: _buildingsVisible,
      );

  /// Synchronizuje stan kamery i 6 płaszczyzn bryły widzenia z [Scene3DMathProjection].
  void updateFromProjection(Scene3DMathProjection projection) {
    final Vector3 pos = projection.cameraPosition;
    final Vector3 target = projection.cameraTarget;

    _camX = pos.x;
    _camY = pos.y;
    _camZ = pos.z;

    double fx = target.x - pos.x;
    double fy = target.y - pos.y;
    double fz = target.z - pos.z;
    final double fLen = math.sqrt(fx * fx + fy * fy + fz * fz);
    if (fLen > 1e-8) {
      fx /= fLen;
      fy /= fLen;
      fz /= fLen;
    } else {
      fx = 0.0;
      fy = 0.0;
      fz = 1.0;
    }
    _fwdX = fx;
    _fwdY = fy;
    _fwdZ = fz;

    _extractPlanesFromMatrix(projection.viewProjectionMatrix);
    _hasFrustumPlanes = true;
  }

  /// Ręczna aktualizacja parametrów kamery (np. dla testów lub własnego rig-a kamery).
  void updateCamera({
    required Vector3 position,
    required Vector3 forward,
    Vector3? up,
    double fovYRadians = math.pi / 3.0,
    double aspectRatio = 16.0 / 9.0,
    Matrix4? viewProjectionMatrix,
  }) {
    _camX = position.x;
    _camY = position.y;
    _camZ = position.z;

    final double fLen = forward.length;
    if (fLen > 1e-8) {
      _fwdX = forward.x / fLen;
      _fwdY = forward.y / fLen;
      _fwdZ = forward.z / fLen;
    } else {
      _fwdX = 0.0;
      _fwdY = 0.0;
      _fwdZ = 1.0;
    }

    final Vector3 worldUp = up ?? Vector3(0.0, 1.0, 0.0);
    // right = forward x up
    double rx = _fwdY * worldUp.z - _fwdZ * worldUp.y;
    double ry = _fwdZ * worldUp.x - _fwdX * worldUp.z;
    double rz = _fwdX * worldUp.y - _fwdY * worldUp.x;
    double rLen = math.sqrt(rx * rx + ry * ry + rz * rz);
    if (rLen < 1e-6) {
      // Awaryjny wektor przy patrzeniu pionowo w dół/górę
      rx = 1.0;
      ry = 0.0;
      rz = 0.0;
      rLen = 1.0;
    }
    _rightX = rx / rLen;
    _rightY = ry / rLen;
    _rightZ = rz / rLen;

    // trueUp = right x forward
    _upX = _rightY * _fwdZ - _rightZ * _fwdY;
    _upY = _rightZ * _fwdX - _rightX * _fwdZ;
    _upZ = _rightX * _fwdY - _rightY * _fwdX;

    final double safeFov = fovYRadians.clamp(0.1, math.pi * 0.95);
    final double safeAspect = aspectRatio <= 0.0 ? 1.0 : aspectRatio;
    _tanHalfFovY = math.tan(safeFov * 0.5);
    _tanHalfFovX = _tanHalfFovY * safeAspect;

    if (viewProjectionMatrix != null) {
      _extractPlanesFromMatrix(viewProjectionMatrix);
      _hasFrustumPlanes = true;
    } else {
      _hasFrustumPlanes = false;
    }
  }

  /// Szybka ocena widoczności kolarza w świecie 3D.
  CullDecision evaluateRider(
    Vector3 worldPosition, {
    double boundingRadius = 1.35,
  }) {
    return evaluatePoint(
      worldPosition,
      boundingRadius: boundingRadius,
      category: CullableObjectCategory.rider,
    );
  }

  /// Szybka ocena widoczności drzewa przydrożnego.
  CullDecision evaluateTree(
    Vector3 worldPosition, {
    double scale = 1.0,
    double baseRadius = 4.5,
  }) {
    final double safeScale = scale.isFinite && scale > 0.0 ? scale : 1.0;
    return evaluatePoint(
      worldPosition,
      boundingRadius: baseRadius * safeScale,
      category: CullableObjectCategory.tree,
    );
  }

  /// Szybka ocena widoczności budynku / kamienicy / trybuny.
  CullDecision evaluateBuilding(
    Vector3 worldPosition, {
    double boundingRadius = 9.0,
  }) {
    return evaluatePoint(
      worldPosition,
      boundingRadius: boundingRadius,
      category: CullableObjectCategory.building,
    );
  }

  /// Rygorystyczna ewaluacja punktu / sfery otaczającej w 3 krokach:
  /// 1) Odrzucenie za kamerą, 2) Odrzucenie > 450 m, 3) Odrzucenie poza bryłą Frustum.
  CullDecision evaluatePoint(
    Vector3 worldPosition, {
    double? boundingRadius,
    CullableObjectCategory category = CullableObjectCategory.roadProp,
  }) {
    final double radius =
        boundingRadius ?? category.defaultBoundingRadiusMeters;
    final double wx = worldPosition.x;
    final double wy = worldPosition.y;
    final double wz = worldPosition.z;

    _totalEvaluated++;
    _incrementCategoryEvaluated(category);

    if (!wx.isFinite || !wy.isFinite || !wz.isFinite || !radius.isFinite) {
      _rejectedInvalid++;
      return const CullDecision.rejected(
        rejectionReason: CullRejectionReason.invalidCoordinates,
      );
    }

    final double dx = wx - _camX;
    final double dy = wy - _camY;
    final double dz = wz - _camZ;

    // 1. Natychmiastowe odrzucenie obiektów za plecami kamery (bez sqrt)
    final double forwardDepth = dx * _fwdX + dy * _fwdY + dz * _fwdZ;
    if (config.enableBehindCameraCulling &&
        forwardDepth + radius < config.nearClipMeters) {
      _rejectedBehindCamera++;
      return CullDecision.rejected(
        rejectionReason: CullRejectionReason.behindCamera,
        forwardDepthMeters: forwardDepth,
      );
    }

    // 2. Natychmiastowe odrzucenie obiektów w odległości > maxRenderDistanceMeters (450 m)
    final double distSq = dx * dx + dy * dy + dz * dz;
    final double maxDist = config.maxRenderDistanceMeters;
    if (distSq > maxDist * maxDist) {
      _rejectedBeyondDistance++;
      return CullDecision.rejected(
        rejectionReason: CullRejectionReason.beyondMaxDistance,
        distanceMeters: math.sqrt(distSq),
        forwardDepthMeters: forwardDepth,
      );
    }

    // 3. Test 6 płaszczyzn bryły widzenia (lub stożka kamery przy braku macierzy)
    if (config.enableFrustumPlanesCulling) {
      final double effectiveRadius =
          math.max(0.0, radius) + config.frustumMarginMeters;
      final bool inside = _hasFrustumPlanes
          ? _intersectsExtractedPlanes(wx, wy, wz, effectiveRadius)
          : _intersectsCameraCone(dx, dy, dz, forwardDepth, effectiveRadius);
      if (!inside) {
        _rejectedOutsideFrustum++;
        return CullDecision.rejected(
          rejectionReason: CullRejectionReason.outsideFrustum,
          distanceMeters: math.sqrt(distSq),
          forwardDepthMeters: forwardDepth,
        );
      }
    }

    final double distance = math.sqrt(distSq);
    final double fogFactor = computeDistanceFogFactor(distance);
    final double opacity = (1.0 - fogFactor).clamp(0.0, 1.0);

    _visibleCount++;
    _incrementCategoryVisible(category);

    return CullDecision(
      isVisible: true,
      rejectionReason: CullRejectionReason.none,
      distanceMeters: distance,
      forwardDepthMeters: forwardDepth,
      fogFactor: fogFactor,
      opacityMultiplier: opacity,
    );
  }

  /// Ewaluacja prostopadłościanu otaczającego (AABB) np. dla dużych budynków.
  CullDecision evaluateAabb(
    Aabb3 box, {
    CullableObjectCategory category = CullableObjectCategory.building,
  }) {
    final Vector3 center = box.center;
    final Vector3 halfExtents = Vector3.zero();
    box.copyCenterAndHalfExtents(center, halfExtents);
    final double boundingRadius = halfExtents.length;
    return evaluatePoint(
      center,
      boundingRadius: boundingRadius,
      category: category,
    );
  }

  /// Szybkie sprawdzenie binarne (bez alokacji obiektu [CullDecision]).
  bool isVisibleFast(
    Vector3 worldPosition, {
    double boundingRadius = 1.35,
  }) {
    return evaluatePoint(
      worldPosition,
      boundingRadius: boundingRadius,
    ).isVisible;
  }

  /// Oblicza współczynnik mgły odległościowej w [0.0, 1.0] dla zadanego dystansu [m].
  double computeDistanceFogFactor(double distanceMeters) {
    if (!distanceMeters.isFinite || distanceMeters <= 0.0) return 0.0;
    final double start = config.fogStartDistanceMeters;
    final double end = math.max(start + 1e-4, config.fogEndDistanceMeters);

    if (distanceMeters <= start) return 0.0;
    if (distanceMeters >= end) return 1.0;

    final double t = ((distanceMeters - start) / (end - start)).clamp(0.0, 1.0);
    switch (config.fogCurve) {
      case DistanceFogCurve.linear:
        return t;
      case DistanceFogCurve.smoothstep:
        return t * t * (3.0 - 2.0 * t);
      case DistanceFogCurve.exponentialSquared:
        final double raw = 1.0 - math.exp(-(t * 2.5) * (t * 2.5));
        final double norm = 1.0 - math.exp(-6.25);
        return (raw / norm).clamp(0.0, 1.0);
    }
  }

  /// Miesza kolor obiektu z kolorem mgły horyzontu i płynnie wygasza kanał alfa.
  Color applyDistanceFog(
    Color baseColor,
    double fogFactor, {
    Color? fogColorOverride,
    bool fadeAlpha = true,
  }) {
    final double f = fogFactor.clamp(0.0, 1.0);
    if (f <= 0.001) return baseColor;
    final Color targetFog = fogColorOverride ?? config.fogColor;
    final Color blended = Color.lerp(baseColor, targetFog, f * 0.85) ?? baseColor;
    if (!fadeAlpha) return blended;
    final double alpha = (blended.a * (1.0 - f)).clamp(0.0, 1.0);
    return blended.withValues(alpha: alpha);
  }

  /// Filtruje listę obiektów dowolnego typu i zwraca widoczne elementy posortowane od najdalszych (Back-to-Front).
  List<CulledRenderEntry<T>> cullAndSortBackToFront<T>({
    required Iterable<T> items,
    required Vector3 Function(T item) positionOf,
    double Function(T item)? radiusOf,
    CullableObjectCategory Function(T item)? categoryOf,
  }) {
    final List<CulledRenderEntry<T>> visible = <CulledRenderEntry<T>>[];
    for (final T item in items) {
      final CullableObjectCategory cat =
          categoryOf != null ? categoryOf(item) : CullableObjectCategory.roadProp;
      final double rad =
          radiusOf != null ? radiusOf(item) : cat.defaultBoundingRadiusMeters;
      final CullDecision decision = evaluatePoint(
        positionOf(item),
        boundingRadius: rad,
        category: cat,
      );
      if (decision.isVisible) {
        visible.add(
          CulledRenderEntry<T>(
            item: item,
            distanceMeters: decision.distanceMeters,
            forwardDepthMeters: decision.forwardDepthMeters,
            fogFactor: decision.fogFactor,
            opacityMultiplier: decision.opacityMultiplier,
          ),
        );
      }
    }
    visible.sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
    return visible;
  }

  void _incrementCategoryEvaluated(CullableObjectCategory category) {
    switch (category) {
      case CullableObjectCategory.rider:
        _ridersEvaluated++;
        break;
      case CullableObjectCategory.tree:
        _treesEvaluated++;
        break;
      case CullableObjectCategory.building:
        _buildingsEvaluated++;
        break;
      case CullableObjectCategory.roadProp:
        break;
    }
  }

  void _incrementCategoryVisible(CullableObjectCategory category) {
    switch (category) {
      case CullableObjectCategory.rider:
        _ridersVisible++;
        break;
      case CullableObjectCategory.tree:
        _treesVisible++;
        break;
      case CullableObjectCategory.building:
        _buildingsVisible++;
        break;
      case CullableObjectCategory.roadProp:
        break;
    }
  }

  /// Ekstrahuje 6 znormalizowanych płaszczyzn Gribb-Hartmanna z macierzy View-Projection.
  void _extractPlanesFromMatrix(Matrix4 vp) {
    final Float64List m = vp.storage;
    // Wektory wierszowe macierzy kolumnowej vector_math:
    // r0 = [m[0], m[4], m[8], m[12]]
    // r1 = [m[1], m[5], m[9], m[13]]
    // r2 = [m[2], m[6], m[10], m[14]]
    // r3 = [m[3], m[7], m[11], m[15]]

    // Left: r3 + r0
    _setNormalizedPlane(0, m[3] + m[0], m[7] + m[4], m[11] + m[8], m[15] + m[12]);
    // Right: r3 - r0
    _setNormalizedPlane(1, m[3] - m[0], m[7] - m[4], m[11] - m[8], m[15] - m[12]);
    // Bottom: r3 + r1
    _setNormalizedPlane(2, m[3] + m[1], m[7] + m[5], m[11] + m[9], m[15] + m[13]);
    // Top: r3 - r1
    _setNormalizedPlane(3, m[3] - m[1], m[7] - m[5], m[11] - m[9], m[15] - m[13]);
    // Near: r3 + r2
    _setNormalizedPlane(4, m[3] + m[2], m[7] + m[6], m[11] + m[10], m[15] + m[14]);
    // Far: r3 - r2
    _setNormalizedPlane(5, m[3] - m[2], m[7] - m[6], m[11] - m[10], m[15] - m[14]);
  }

  void _setNormalizedPlane(int index, double nx, double ny, double nz, double d) {
    final double len = math.sqrt(nx * nx + ny * ny + nz * nz);
    final int base = index * 4;
    if (len > 1e-12) {
      final double invLen = 1.0 / len;
      _planes[base] = nx * invLen;
      _planes[base + 1] = ny * invLen;
      _planes[base + 2] = nz * invLen;
      _planes[base + 3] = d * invLen;
    } else {
      _planes[base] = 0.0;
      _planes[base + 1] = 0.0;
      _planes[base + 2] = 0.0;
      _planes[base + 3] = 0.0;
    }
  }

  bool _intersectsExtractedPlanes(double x, double y, double z, double radius) {
    for (int i = 0; i < 6; i++) {
      final int base = i * 4;
      final double signedDist =
          _planes[base] * x + _planes[base + 1] * y + _planes[base + 2] * z + _planes[base + 3];
      if (signedDist < -radius) {
        return false;
      }
    }
    return true;
  }

  bool _intersectsCameraCone(
    double dx,
    double dy,
    double dz,
    double forwardDepth,
    double radius,
  ) {
    final double rightDist = dx * _rightX + dy * _rightY + dz * _rightZ;
    final double upDist = dx * _upX + dy * _upY + dz * _upZ;

    final double safeDepth = math.max(0.0, forwardDepth);
    final double maxHalfWidth = safeDepth * _tanHalfFovX + radius * math.sqrt(1.0 + _tanHalfFovX * _tanHalfFovX);
    if (rightDist.abs() > maxHalfWidth) return false;

    final double maxHalfHeight = safeDepth * _tanHalfFovY + radius * math.sqrt(1.0 + _tanHalfFovY * _tanHalfFovY);
    if (upDist.abs() > maxHalfHeight) return false;

    return true;
  }
}

/// Panel diagnostyczny i sterujący dla [FrustumAndDistanceCuller].
///
/// Zapewnia podgląd wydajności odrzucania (kolarze/drzewa/budynki), regulację progu
/// dystansu 450 m, krzywej mgły oraz przełączników trybu z pełną responsywnością.
class FrustumCullingInspectorPanel extends StatefulWidget {
  final FrustumCullingConfig config;
  final CullingFrameStats stats;
  final ValueChanged<FrustumCullingConfig>? onConfigChanged;
  final bool enabled;

  const FrustumCullingInspectorPanel({
    super.key,
    required this.config,
    required this.stats,
    this.onConfigChanged,
    this.enabled = true,
  });

  @override
  State<FrustumCullingInspectorPanel> createState() =>
      _FrustumCullingInspectorPanelState();
}

class _FrustumCullingInspectorPanelState
    extends State<FrustumCullingInspectorPanel> {
  bool _isCardHovered = false;

  void _emitConfig(FrustumCullingConfig next) {
    if (!widget.enabled) return;
    widget.onConfigChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 480.0;
        final double padding = isCompact ? 12.0 : 16.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _isCardHovered = true),
          onExit: (_) => setState(() => _isCardHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCardHovered && widget.enabled
                    ? AppColors.goldAccent.withValues(alpha: 0.7)
                    : AppColors.cardBorder,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 12),
                _buildStatsGrid(isCompact),
                const SizedBox(height: 12),
                _buildCurveSelector(isCompact),
                const SizedBox(height: 10),
                _buildToggles(isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      children: [
        const Icon(
          Icons.filter_center_focus_rounded,
          color: AppColors.goldAccent,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Frustum & Distance Culler (${widget.config.maxRenderDistanceMeters.toStringAsFixed(0)} m)',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 13 : 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            '-${widget.stats.cullRatePercent.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.statusSuccess,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isCompact) {
    final s = widget.stats;
    final List<Widget> tiles = [
      _StatPill(
        label: 'Kolarze',
        value: '${s.ridersVisible}/${s.ridersEvaluated}',
        accent: AppColors.accentBlue,
      ),
      _StatPill(
        label: 'Drzewa',
        value: '${s.treesVisible}/${s.treesEvaluated}',
        accent: AppColors.statusSuccess,
      ),
      _StatPill(
        label: 'Budynki',
        value: '${s.buildingsVisible}/${s.buildingsEvaluated}',
        accent: AppColors.amberWarning,
      ),
      _StatPill(
        label: 'Za kamerą / >450m',
        value: '${s.rejectedBehindCamera} / ${s.rejectedBeyondDistance}',
        accent: AppColors.crimsonAlert,
      ),
    ];

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tiles,
      );
    }

    return Row(
      children: tiles
          .map(
            (tile) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: tile,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCurveSelector(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Mgła:',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        for (final curve in DistanceFogCurve.values)
          _FogCurveButton(
            label: curve.label,
            selected: widget.config.fogCurve == curve,
            enabled: widget.enabled,
            onPressed: () => _emitConfig(widget.config.copyWith(fogCurve: curve)),
          ),
      ],
    );
  }

  Widget _buildToggles(bool isCompact) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _CullToggleChip(
          label: 'Odrzucaj za kamerą',
          active: widget.config.enableBehindCameraCulling,
          enabled: widget.enabled,
          onTap: () => _emitConfig(
            widget.config.copyWith(
              enableBehindCameraCulling: !widget.config.enableBehindCameraCulling,
            ),
          ),
        ),
        _CullToggleChip(
          label: 'Frustum 6-Plane',
          active: widget.config.enableFrustumPlanesCulling,
          enabled: widget.enabled,
          onTap: () => _emitConfig(
            widget.config.copyWith(
              enableFrustumPlanesCulling: !widget.config.enableFrustumPlanesCulling,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _FogCurveButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  const _FogCurveButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_FogCurveButton> createState() => _FogCurveButtonState();
}

class _FogCurveButtonState extends State<_FogCurveButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    if (!widget.enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.4);
    } else if (widget.selected) {
      bgColor = _pressed
          ? AppColors.primaryAccent.withValues(alpha: 0.85)
          : AppColors.primaryAccent;
    } else if (_pressed) {
      bgColor = AppColors.cardBorder;
    } else if (_hovered) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.9);
    } else {
      bgColor = AppColors.surfaceLight;
    }

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.selected ? AppColors.goldAccent : AppColors.cardBorder),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _CullToggleChip extends StatefulWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _CullToggleChip({
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_CullToggleChip> createState() => _CullToggleChipState();
}

class _CullToggleChipState extends State<_CullToggleChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: !widget.enabled
                ? AppColors.surfaceLight.withValues(alpha: 0.4)
                : (_pressed
                    ? AppColors.cardBorder
                    : (_hovered ? AppColors.surfaceLight : AppColors.background)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.active ? AppColors.statusSuccess : AppColors.cardBorder),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.active
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: widget.enabled
                    ? (widget.active
                        ? AppColors.statusSuccess
                        : AppColors.textSecondary)
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
