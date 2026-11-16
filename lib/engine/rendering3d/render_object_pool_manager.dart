// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';

/// Kategoria cząsteczek atmosferycznych przechowywanych w buforze puli 3D.
enum WeatherParticlePoolKind {
  /// Kropla deszczu w przestrzeni ekranowej/świata.
  raindrop,

  /// Pióropusz wody wyrzucany spod opon kolarzy na mokrym asfalcie.
  waterSpray,

  /// Chmura kurzu na sektorach szutrowych (Strade) i brukowych.
  dustPlume,
}

/// Konfiguracja pojemności prealokowanych buforów dla [RenderObjectPoolManager].
@immutable
class RenderPoolConfig {
  /// Maksymalna liczba kolarzy w peletonie (domyślnie 176 kolarzy Grand Tour).
  final int maxRiders;

  /// Liczba kół przypadająca na jednego kolarza (domyślnie 2: przód i tył).
  final int wheelsPerRider;

  /// Maksymalna liczba kropel deszczu w buforze cząsteczek.
  final int maxRaindrops;

  /// Maksymalna liczba cząsteczek pióropusza wody spod kół.
  final int maxSprayParticles;

  /// Maksymalna liczba cząsteczek kurzu i pyłu.
  final int maxDustParticles;

  /// Maksymalna liczba szprych na jedno koło dla bufora współrzędnych `paint()`.
  final int maxSpokesPerWheel;

  /// Liczba prealokowanych wektorów [Vector3] w puli roboczej scratch.
  final int scratchVector3Capacity;

  /// Liczba prealokowanych macierzy [Matrix4] w puli roboczej scratch.
  final int scratchMatrix4Capacity;

  const RenderPoolConfig({
    this.maxRiders = 176,
    this.wheelsPerRider = 2,
    this.maxRaindrops = 450,
    this.maxSprayParticles = 220,
    this.maxDustParticles = 220,
    this.maxSpokesPerWheel = 24,
    this.scratchVector3Capacity = 32,
    this.scratchMatrix4Capacity = 16,
  })  : assert(maxRiders > 0, 'maxRiders must be positive'),
        assert(wheelsPerRider > 0, 'wheelsPerRider must be positive'),
        assert(maxRaindrops >= 0, 'maxRaindrops cannot be negative'),
        assert(maxSprayParticles >= 0, 'maxSprayParticles cannot be negative'),
        assert(maxDustParticles >= 0, 'maxDustParticles cannot be negative'),
        assert(maxSpokesPerWheel > 0, 'maxSpokesPerWheel must be positive'),
        assert(
          scratchVector3Capacity >= 4,
          'scratchVector3Capacity must be at least 4',
        ),
        assert(
          scratchMatrix4Capacity >= 2,
          'scratchMatrix4Capacity must be at least 2',
        );

  /// Łączna pojemność bufora kół (domyślnie 352).
  int get maxWheels => maxRiders * wheelsPerRider;

  /// Łączna pojemność bufora cząsteczek pogody (domyślnie 890).
  int get maxWeatherParticles =>
      maxRaindrops + maxSprayParticles + maxDustParticles;
}

/// Migawka telemetryczna zużycia pamięci i wykorzystania puli 120 FPS.
@immutable
class RenderPoolMemoryStats {
  final int maxRiders;
  final int activeRiders;
  final int visibleRiders;
  final int maxWheels;
  final int activeWheels;
  final int maxWeatherParticles;
  final int activeWeatherParticles;
  final int activeRaindrops;
  final int activeSprayParticles;
  final int activeDustParticles;
  final int totalPreallocatedBytes;
  final int scratchVector3HighWaterMark;
  final int scratchMatrix4HighWaterMark;
  final int lastFrameMicros;
  final bool zeroAllocationActive;

  const RenderPoolMemoryStats({
    required this.maxRiders,
    required this.activeRiders,
    required this.visibleRiders,
    required this.maxWheels,
    required this.activeWheels,
    required this.maxWeatherParticles,
    required this.activeWeatherParticles,
    required this.activeRaindrops,
    required this.activeSprayParticles,
    required this.activeDustParticles,
    required this.totalPreallocatedBytes,
    required this.scratchVector3HighWaterMark,
    required this.scratchMatrix4HighWaterMark,
    required this.lastFrameMicros,
    required this.zeroAllocationActive,
  });

  double get totalPreallocatedKilobytes => totalPreallocatedBytes / 1024.0;
}

/// Prealokowany bufor macierzy transformacji i telemetrii 3D dla 176 kolarzy.
///
/// Wszystkie dane są przechowywane w płaskich tablicach typu `Float64List`,
/// `Int32List` i `Uint8List` (układ Structure-of-Arrays), co całkowicie eliminuje
/// alokacje na stercie i pracę Garbage Collectora w metodzie `paint()`.
class RiderPoolBuffer {
  /// Maksymalna liczba obsługiwanych kolarzy.
  final int capacity;

  /// Macierze transformacji 4x4 (column-major, 16 wartości double na kolarza).
  final Float64List transformMatrices;

  /// Pozycje w układzie świata 3D (x, y, z) — 3 wartości na kolarza.
  final Float64List worldPositions;

  /// Wektory kierunku jazdy (tx, ty, tz) — 3 wartości na kolarza.
  final Float64List tangents;

  /// Wektory poprzeczne w prawo (rx, ry, rz) — 3 wartości na kolarza.
  final Float64List rights;

  /// Wektory normalne do powierzchni szosy (ux, uy, uz) — 3 wartości na kolarza.
  final Float64List ups;

  /// Rzutowanie ekranowe: (screenX, screenY, screenScale, cameraDistance).
  final Float64List screenCoords;

  /// Kąty pozy i animacji: (yaw, pitch, roll, cadencePhaseRadians).
  final Float64List poseAngles;

  /// Poziom szczegółowości LOD (0 = full, 1 = medium, 2 = distant).
  final Int32List lodLevels;

  /// Spakowany kolor koszulki w formacie 0xAARRGGBB.
  final Int32List jerseyColorsArgb;

  /// Flagi widoczności w klatce (0 = ukryty/culled, 1 = widoczny).
  final Uint8List visibilityFlags;

  /// Indeksy widocznych kolarzy posortowane od najdalszego do najbliższego.
  final Int32List sortedIndices;

  int _activeCount = 0;
  int _visibleCount = 0;

  RiderPoolBuffer({required this.capacity})
      : assert(capacity > 0),
        transformMatrices = Float64List(capacity * 16),
        worldPositions = Float64List(capacity * 3),
        tangents = Float64List(capacity * 3),
        rights = Float64List(capacity * 3),
        ups = Float64List(capacity * 3),
        screenCoords = Float64List(capacity * 4),
        poseAngles = Float64List(capacity * 4),
        lodLevels = Int32List(capacity),
        jerseyColorsArgb = Int32List(capacity),
        visibilityFlags = Uint8List(capacity),
        sortedIndices = Int32List(capacity);

  /// Liczba kolarzy zapisanych w bieżącej klatce.
  int get activeCount => _activeCount;

  /// Liczba widocznych kolarzy po Frustum Cullingu.
  int get visibleCount => _visibleCount;

  /// Łączny rozmiar zaalokowanych tablic typowanych w bajtach.
  int get totalAllocatedBytes =>
      transformMatrices.lengthInBytes +
      worldPositions.lengthInBytes +
      tangents.lengthInBytes +
      rights.lengthInBytes +
      ups.lengthInBytes +
      screenCoords.lengthInBytes +
      poseAngles.lengthInBytes +
      lodLevels.lengthInBytes +
      jerseyColorsArgb.lengthInBytes +
      visibilityFlags.lengthInBytes +
      sortedIndices.lengthInBytes;

  /// Zeruje liczniki klatki bez jakichkolwiek alokacji pamięci.
  void clearFrame() {
    _activeCount = 0;
    _visibleCount = 0;
    visibilityFlags.fillRange(0, capacity, 0);
  }

  /// Zapisuje kompletny stan kolarza w slocie [slot] i buduje macierz 4x4
  /// bezpośrednio w [transformMatrices] bez tworzenia `Vector3` ani `Matrix4`.
  void setRiderState({
    required int slot,
    required double posX,
    required double posY,
    required double posZ,
    required double tangentX,
    required double tangentY,
    required double tangentZ,
    required double rightX,
    required double rightY,
    required double rightZ,
    required double upX,
    required double upY,
    required double upZ,
    required double screenX,
    required double screenY,
    required double screenScale,
    required double cameraDistance,
    double yawRadians = 0.0,
    double pitchRadians = 0.0,
    double rollRadians = 0.0,
    double cadencePhaseRadians = 0.0,
    int lodLevel = 0,
    int jerseyColorArgb = 0xFFD4AF37,
    bool isVisible = true,
    double uniformScale = 1.0,
  }) {
    if (slot < 0 || slot >= capacity) return;

    final int v3 = slot * 3;
    worldPositions[v3] = posX;
    worldPositions[v3 + 1] = posY;
    worldPositions[v3 + 2] = posZ;

    tangents[v3] = tangentX;
    tangents[v3 + 1] = tangentY;
    tangents[v3 + 2] = tangentZ;

    rights[v3] = rightX;
    rights[v3 + 1] = rightY;
    rights[v3 + 2] = rightZ;

    ups[v3] = upX;
    ups[v3 + 1] = upY;
    ups[v3 + 2] = upZ;

    final int v4 = slot * 4;
    screenCoords[v4] = screenX;
    screenCoords[v4 + 1] = screenY;
    screenCoords[v4 + 2] = screenScale;
    screenCoords[v4 + 3] = cameraDistance;

    poseAngles[v4] = yawRadians;
    poseAngles[v4 + 1] = pitchRadians;
    poseAngles[v4 + 2] = rollRadians;
    poseAngles[v4 + 3] = cadencePhaseRadians;

    lodLevels[slot] = lodLevel.clamp(0, 2);
    jerseyColorsArgb[slot] = jerseyColorArgb;
    visibilityFlags[slot] = isVisible ? 1 : 0;

    // Budowa kolumnowej macierzy transformacji 4x4 (Right, Up, Forward/Tangent, Position).
    final int m = slot * 16;
    transformMatrices[m] = rightX * uniformScale;
    transformMatrices[m + 1] = rightY * uniformScale;
    transformMatrices[m + 2] = rightZ * uniformScale;
    transformMatrices[m + 3] = 0.0;

    transformMatrices[m + 4] = upX * uniformScale;
    transformMatrices[m + 5] = upY * uniformScale;
    transformMatrices[m + 6] = upZ * uniformScale;
    transformMatrices[m + 7] = 0.0;

    transformMatrices[m + 8] = tangentX * uniformScale;
    transformMatrices[m + 9] = tangentY * uniformScale;
    transformMatrices[m + 10] = tangentZ * uniformScale;
    transformMatrices[m + 11] = 0.0;

    transformMatrices[m + 12] = posX;
    transformMatrices[m + 13] = posY;
    transformMatrices[m + 14] = posZ;
    transformMatrices[m + 15] = 1.0;

    if (slot + 1 > _activeCount) {
      _activeCount = slot + 1;
    }
  }

  /// Kopiuje 16 elementów macierzy 4x4 kolarza do istniejącego obiektu [target].
  void copyMatrixIntoMatrix4(int slot, Matrix4 target) {
    if (slot < 0 || slot >= capacity) return;
    final int m = slot * 16;
    final Float64List dst = target.storage;
    for (int i = 0; i < 16; i++) {
      dst[i] = transformMatrices[m + i];
    }
  }

  /// Zbiera indeksy widocznych kolarzy i sortuje je malejąco po odległości od kamery
  /// (algorytm malarza Back-to-Front) za pomocą sortowania przez wstawianie
  /// całkowicie w miejscu (zero alokacji list pomocniczych lub domknięć).
  int sortVisibleBackToFront() {
    int count = 0;
    for (int i = 0; i < _activeCount; i++) {
      if (visibilityFlags[i] == 1) {
        sortedIndices[count] = i;
        count++;
      }
    }
    _visibleCount = count;

    for (int i = 1; i < count; i++) {
      final int keyIdx = sortedIndices[i];
      final double keyDist = screenCoords[keyIdx * 4 + 3];
      int j = i - 1;
      while (j >= 0) {
        final int cmpIdx = sortedIndices[j];
        final double cmpDist = screenCoords[cmpIdx * 4 + 3];
        if (cmpDist >= keyDist) break;
        sortedIndices[j + 1] = cmpIdx;
        j--;
      }
      sortedIndices[j + 1] = keyIdx;
    }

    return count;
  }
}

/// Prealokowany bufor macierzy 4x4 i kinematyki obrotu dla kół peletonu (domyślnie 352 koła)
/// wraz ze współrzędnymi szprych dla metody `paint()`.
class WheelPoolBuffer {
  /// Maksymalna liczba kół w buforze.
  final int capacity;

  /// Maksymalna liczba szprych na jedno koło w buforze scratch.
  final int maxSpokesPerWheel;

  /// Macierze transformacji 4x4 kół (16 wartości double na koło).
  final Float64List transformMatrices;

  /// Kinematyka koła: (rotationRadians, angularVelocity, motionBlurFactor, rimDepthMeters, screenX, screenY).
  final Float64List wheelKinematics;

  /// Metryki ekranowe koła: (radiusX, radiusY, tiltRadians, visibleFlag).
  final Float64List wheelScreenMetrics;

  /// Prealokowany bufor odcinków szprych (x1, y1, x2, y2) dla zero-alokacyjnego rysowania w `paint()`.
  final Float64List spokeScratchCoords;

  int _activeCount = 0;

  WheelPoolBuffer({
    required this.capacity,
    required this.maxSpokesPerWheel,
  })  : assert(capacity > 0),
        assert(maxSpokesPerWheel > 0),
        transformMatrices = Float64List(capacity * 16),
        wheelKinematics = Float64List(capacity * 6),
        wheelScreenMetrics = Float64List(capacity * 4),
        spokeScratchCoords = Float64List(maxSpokesPerWheel * 4);

  /// Liczba aktywnych kół w bieżącej klatce.
  int get activeCount => _activeCount;

  /// Łączny rozmiar zaalokowanych tablic typowanych w bajtach.
  int get totalAllocatedBytes =>
      transformMatrices.lengthInBytes +
      wheelKinematics.lengthInBytes +
      wheelScreenMetrics.lengthInBytes +
      spokeScratchCoords.lengthInBytes;

  /// Resetuje licznik aktywnych kół bez alokacji.
  void clearFrame() {
    _activeCount = 0;
  }

  /// Zapisuje pozycję, rotację (obrót osi X oraz skręt/pochylenie) i metryki ekranowe koła.
  void setWheelState({
    required int wheelSlot,
    required double worldX,
    required double worldY,
    required double worldZ,
    required double rotationRadians,
    required double angularVelocityRadPerSec,
    required double motionBlurFactor,
    required double rimDepthMeters,
    required double screenCenterX,
    required double screenCenterY,
    required double screenRadiusX,
    required double screenRadiusY,
    double tiltRadians = 0.0,
    double steerYawRadians = 0.0,
    bool isVisible = true,
  }) {
    if (wheelSlot < 0 || wheelSlot >= capacity) return;

    final double cosSpin = math.cos(rotationRadians);
    final double sinSpin = math.sin(rotationRadians);
    final double cosYaw = math.cos(steerYawRadians);
    final double sinYaw = math.sin(steerYawRadians);

    // Złożona macierz 4x4: T(world) * Ry(steerYaw) * Rx(rotation) w układzie column-major.
    final int m = wheelSlot * 16;
    transformMatrices[m] = cosYaw;
    transformMatrices[m + 1] = 0.0;
    transformMatrices[m + 2] = -sinYaw;
    transformMatrices[m + 3] = 0.0;

    transformMatrices[m + 4] = sinYaw * sinSpin;
    transformMatrices[m + 5] = cosSpin;
    transformMatrices[m + 6] = cosYaw * sinSpin;
    transformMatrices[m + 7] = 0.0;

    transformMatrices[m + 8] = sinYaw * cosSpin;
    transformMatrices[m + 9] = -sinSpin;
    transformMatrices[m + 10] = cosYaw * cosSpin;
    transformMatrices[m + 11] = 0.0;

    transformMatrices[m + 12] = worldX;
    transformMatrices[m + 13] = worldY;
    transformMatrices[m + 14] = worldZ;
    transformMatrices[m + 15] = 1.0;

    final int k = wheelSlot * 6;
    wheelKinematics[k] = rotationRadians;
    wheelKinematics[k + 1] = angularVelocityRadPerSec;
    wheelKinematics[k + 2] = motionBlurFactor.clamp(0.0, 1.0);
    wheelKinematics[k + 3] = rimDepthMeters;
    wheelKinematics[k + 4] = screenCenterX;
    wheelKinematics[k + 5] = screenCenterY;

    final int s = wheelSlot * 4;
    wheelScreenMetrics[s] = screenRadiusX;
    wheelScreenMetrics[s + 1] = screenRadiusY;
    wheelScreenMetrics[s + 2] = tiltRadians;
    wheelScreenMetrics[s + 3] = isVisible ? 1.0 : 0.0;

    if (wheelSlot + 1 > _activeCount) {
      _activeCount = wheelSlot + 1;
    }
  }

  /// Wylicza współrzędne wszystkich szprych w rzucie 2D bezpośrednio do
  /// prealokowanego bufora [spokeScratchCoords], bez tworzenia obiektów `Offset`.
  ///
  /// Zwraca liczbę wyliczonych szprych (ograniczoną przez [maxSpokesPerWheel]).
  int computeSpokeEndpointsInPlace({
    required int spokeCount,
    required double centerX,
    required double centerY,
    required double radiusX,
    required double radiusY,
    required double baseAngleRadians,
    double hubRadiusRatio = 0.16,
  }) {
    final int clampedCount = spokeCount.clamp(0, maxSpokesPerWheel);
    if (clampedCount == 0) return 0;

    final double step = (math.pi * 2.0) / clampedCount;
    for (int i = 0; i < clampedCount; i++) {
      final double angle = baseAngleRadians + (i * step);
      final double cosA = math.cos(angle);
      final double sinA = math.sin(angle);
      final int offset = i * 4;
      spokeScratchCoords[offset] = centerX + (cosA * radiusX * hubRadiusRatio);
      spokeScratchCoords[offset + 1] =
          centerY + (sinA * radiusY * hubRadiusRatio);
      spokeScratchCoords[offset + 2] = centerX + (cosA * radiusX);
      spokeScratchCoords[offset + 3] = centerY + (sinA * radiusY);
    }
    return clampedCount;
  }

  /// Kopiuje macierz 4x4 koła do istniejącego obiektu [target].
  void copyMatrixIntoMatrix4(int wheelSlot, Matrix4 target) {
    if (wheelSlot < 0 || wheelSlot >= capacity) return;
    final int m = wheelSlot * 16;
    final Float64List dst = target.storage;
    for (int i = 0; i < 16; i++) {
      dst[i] = transformMatrices[m + i];
    }
  }
}

/// Prealokowany bufor cząsteczek pogody (deszcz, pióropusz wody, kurz szutrowy/brukowy).
class WeatherParticlePoolBuffer {
  /// Maksymalna łączna liczba cząsteczek w buforze.
  final int capacity;

  /// Pozycje 3D/ekranowe cząsteczek (x, y, z) — 3 wartości na cząsteczkę.
  final Float64List positions;

  /// Prędkości (vx, vy, vz) — 3 wartości na cząsteczkę.
  final Float64List velocities;

  /// Macierze transformacji 4x4 cząsteczek (16 wartości na cząsteczkę).
  final Float64List transformMatrices;

  /// Atrybuty fizyczne i wizualne: (age, maxLifetime, startSize, endSize, initialAlpha, lengthOrThickness).
  final Float64List attributes;

  /// Dane rzutowania ekranowego: (screenX, screenY, screenRadius, currentAlpha).
  final Float64List screenProjection;

  /// Typ cząsteczki (`WeatherParticlePoolKind.index`).
  final Uint8List kinds;

  /// Flaga aktywności cząsteczki (0 = wolny slot, 1 = aktywna).
  final Uint8List activeFlags;

  int _searchCursor = 0;
  int _activeTotal = 0;
  int _activeRaindrops = 0;
  int _activeSpray = 0;
  int _activeDust = 0;

  WeatherParticlePoolBuffer({required this.capacity})
      : assert(capacity >= 0),
        positions = Float64List(capacity * 3),
        velocities = Float64List(capacity * 3),
        transformMatrices = Float64List(capacity * 16),
        attributes = Float64List(capacity * 6),
        screenProjection = Float64List(capacity * 4),
        kinds = Uint8List(capacity),
        activeFlags = Uint8List(capacity);

  int get activeTotal => _activeTotal;
  int get activeRaindrops => _activeRaindrops;
  int get activeSpray => _activeSpray;
  int get activeDust => _activeDust;

  int get totalAllocatedBytes =>
      positions.lengthInBytes +
      velocities.lengthInBytes +
      transformMatrices.lengthInBytes +
      attributes.lengthInBytes +
      screenProjection.lengthInBytes +
      kinds.lengthInBytes +
      activeFlags.lengthInBytes;

  /// Dezaktywuje wszystkie cząsteczki w buforze bez alokacji pamięci.
  void clearAll() {
    if (capacity == 0) return;
    activeFlags.fillRange(0, capacity, 0);
    _searchCursor = 0;
    _activeTotal = 0;
    _activeRaindrops = 0;
    _activeSpray = 0;
    _activeDust = 0;
  }

  /// Zajmuje wolny slot w buforze i inicjalizuje cząsteczkę w czasie O(1) zamortyzowanym.
  /// Zwraca indeks zajętego slotu lub `-1`, jeśli pula jest całkowicie pełna.
  int spawnParticle({
    required WeatherParticlePoolKind kind,
    required double x,
    required double y,
    required double z,
    required double vx,
    required double vy,
    required double vz,
    double maxLifetime = 0.45,
    double startSize = 0.08,
    double endSize = 0.45,
    double initialAlpha = 0.65,
    double lengthOrThickness = 1.4,
  }) {
    if (capacity == 0) return -1;

    int foundSlot = -1;
    for (int offset = 0; offset < capacity; offset++) {
      final int idx = (_searchCursor + offset) % capacity;
      if (activeFlags[idx] == 0) {
        foundSlot = idx;
        _searchCursor = (idx + 1) % capacity;
        break;
      }
    }

    if (foundSlot < 0) return -1;

    activeFlags[foundSlot] = 1;
    kinds[foundSlot] = kind.index;

    final int p = foundSlot * 3;
    positions[p] = x;
    positions[p + 1] = y;
    positions[p + 2] = z;

    velocities[p] = vx;
    velocities[p + 1] = vy;
    velocities[p + 2] = vz;

    final int a = foundSlot * 6;
    attributes[a] = 0.0;
    attributes[a + 1] = maxLifetime > 0.001 ? maxLifetime : 0.001;
    attributes[a + 2] = startSize;
    attributes[a + 3] = endSize;
    attributes[a + 4] = initialAlpha.clamp(0.0, 1.0);
    attributes[a + 5] = lengthOrThickness;

    final int sp = foundSlot * 4;
    screenProjection[sp] = x;
    screenProjection[sp + 1] = y;
    screenProjection[sp + 2] = startSize;
    screenProjection[sp + 3] = initialAlpha.clamp(0.0, 1.0);

    final int m = foundSlot * 16;
    transformMatrices[m] = startSize;
    transformMatrices[m + 1] = 0.0;
    transformMatrices[m + 2] = 0.0;
    transformMatrices[m + 3] = 0.0;
    transformMatrices[m + 4] = 0.0;
    transformMatrices[m + 5] = startSize;
    transformMatrices[m + 6] = 0.0;
    transformMatrices[m + 7] = 0.0;
    transformMatrices[m + 8] = 0.0;
    transformMatrices[m + 9] = 0.0;
    transformMatrices[m + 10] = startSize;
    transformMatrices[m + 11] = 0.0;
    transformMatrices[m + 12] = x;
    transformMatrices[m + 13] = y;
    transformMatrices[m + 14] = z;
    transformMatrices[m + 15] = 1.0;

    _activeTotal++;
    switch (kind) {
      case WeatherParticlePoolKind.raindrop:
        _activeRaindrops++;
      case WeatherParticlePoolKind.waterSpray:
        _activeSpray++;
      case WeatherParticlePoolKind.dustPlume:
        _activeDust++;
    }

    return foundSlot;
  }

  /// Aktualizuje fizykę wszystkich aktywnych cząsteczek w miejscu (zero alokacji).
  void stepParticles({
    required double dtSeconds,
    double gravityY = -9.81,
    double windAccelX = 0.0,
    double windAccelZ = 0.0,
  }) {
    if (capacity == 0 || dtSeconds <= 0.0) return;

    int total = 0;
    int rain = 0;
    int spray = 0;
    int dust = 0;

    for (int i = 0; i < capacity; i++) {
      if (activeFlags[i] == 0) continue;

      final int a = i * 6;
      final double nextAge = attributes[a] + dtSeconds;
      final double maxAge = attributes[a + 1];

      if (nextAge >= maxAge) {
        activeFlags[i] = 0;
        continue;
      }

      attributes[a] = nextAge;
      final double t = (nextAge / maxAge).clamp(0.0, 1.0);

      final int p = i * 3;
      final int kindIdx = kinds[i];
      if (kindIdx == WeatherParticlePoolKind.waterSpray.index) {
        velocities[p + 1] += gravityY * dtSeconds;
      } else if (kindIdx == WeatherParticlePoolKind.dustPlume.index) {
        velocities[p] += windAccelX * dtSeconds;
        velocities[p + 2] += windAccelZ * dtSeconds;
      }

      final double nx = positions[p] + (velocities[p] * dtSeconds);
      final double ny = positions[p + 1] + (velocities[p + 1] * dtSeconds);
      final double nz = positions[p + 2] + (velocities[p + 2] * dtSeconds);

      positions[p] = nx;
      positions[p + 1] = ny;
      positions[p + 2] = nz;

      final double startSize = attributes[a + 2];
      final double endSize = attributes[a + 3];
      final double size = startSize + ((endSize - startSize) * t);
      final double alpha = attributes[a + 4] * (1.0 - t);

      final int sp = i * 4;
      screenProjection[sp] = nx;
      screenProjection[sp + 1] = ny;
      screenProjection[sp + 2] = size;
      screenProjection[sp + 3] = alpha;

      final int m = i * 16;
      transformMatrices[m] = size;
      transformMatrices[m + 5] = size;
      transformMatrices[m + 10] = size;
      transformMatrices[m + 12] = nx;
      transformMatrices[m + 13] = ny;
      transformMatrices[m + 14] = nz;

      total++;
      if (kindIdx == WeatherParticlePoolKind.raindrop.index) {
        rain++;
      } else if (kindIdx == WeatherParticlePoolKind.waterSpray.index) {
        spray++;
      } else {
        dust++;
      }
    }

    _activeTotal = total;
    _activeRaindrops = rain;
    _activeSpray = spray;
    _activeDust = dust;
  }
}

/// Prealokowana pula obiektów pomocniczych [Vector3] i [Matrix4] oraz operacji
/// macierzowych na [Float64List] dla metody `paint()`.
class ScratchMathPool {
  final List<Vector3> _vector3Pool;
  final List<Matrix4> _matrix4Pool;

  int _vector3Cursor = 0;
  int _matrix4Cursor = 0;
  int _vector3HighWaterMark = 0;
  int _matrix4HighWaterMark = 0;

  /// Stałe sloty robocze do bezpośredniego użycia w ciasnych pętlach `paint()`.
  final Vector3 vecA = Vector3.zero();
  final Vector3 vecB = Vector3.zero();
  final Vector3 vecC = Vector3.zero();
  final Vector3 vecD = Vector3.zero();

  final Matrix4 matA = Matrix4.identity();
  final Matrix4 matB = Matrix4.identity();

  ScratchMathPool({
    required int vector3Capacity,
    required int matrix4Capacity,
  })  : _vector3Pool = List<Vector3>.generate(
          vector3Capacity,
          (_) => Vector3.zero(),
          growable: false,
        ),
        _matrix4Pool = List<Matrix4>.generate(
          matrix4Capacity,
          (_) => Matrix4.identity(),
          growable: false,
        );

  int get vector3Capacity => _vector3Pool.length;
  int get matrix4Capacity => _matrix4Pool.length;
  int get vector3HighWaterMark => _vector3HighWaterMark;
  int get matrix4HighWaterMark => _matrix4HighWaterMark;

  int get totalAllocatedBytes =>
      (_vector3Pool.length + 4) * 24 + (_matrix4Pool.length + 2) * 128;

  /// Resetuje kursory puli scratch na początku klatki (zero alokacji).
  void resetFrame() {
    _vector3Cursor = 0;
    _matrix4Cursor = 0;
  }

  /// Pobiera wyzerowany lub zainicjalizowany prealokowany wektor [Vector3] bez `new Vector3()`.
  Vector3 acquireVector3([double x = 0.0, double y = 0.0, double z = 0.0]) {
    final int idx = _vector3Cursor % _vector3Pool.length;
    _vector3Cursor++;
    if (_vector3Cursor > _vector3HighWaterMark) {
      _vector3HighWaterMark = _vector3Cursor;
    }
    final Vector3 v = _vector3Pool[idx];
    v.setValues(x, y, z);
    return v;
  }

  /// Pobiera prealokowaną macierz [Matrix4] ustawioną jako jednostkowa bez alokacji.
  Matrix4 acquireIdentityMatrix4() {
    final int idx = _matrix4Cursor % _matrix4Pool.length;
    _matrix4Cursor++;
    if (_matrix4Cursor > _matrix4HighWaterMark) {
      _matrix4HighWaterMark = _matrix4Cursor;
    }
    final Matrix4 m = _matrix4Pool[idx];
    m.setIdentity();
    return m;
  }

  /// Mnoży dwie macierze 4x4 (column-major) z tablic [Float64List] i zapisuje wynik
  /// bezpośrednio w [out] pod indeksem [outOffset] bez żadnych alokacji.
  static void multiplyMatrix4Into(
    Float64List a,
    int aOffset,
    Float64List b,
    int bOffset,
    Float64List out,
    int outOffset,
  ) {
    final double a00 = a[aOffset];
    final double a10 = a[aOffset + 1];
    final double a20 = a[aOffset + 2];
    final double a30 = a[aOffset + 3];
    final double a01 = a[aOffset + 4];
    final double a11 = a[aOffset + 5];
    final double a21 = a[aOffset + 6];
    final double a31 = a[aOffset + 7];
    final double a02 = a[aOffset + 8];
    final double a12 = a[aOffset + 9];
    final double a22 = a[aOffset + 10];
    final double a32 = a[aOffset + 11];
    final double a03 = a[aOffset + 12];
    final double a13 = a[aOffset + 13];
    final double a23 = a[aOffset + 14];
    final double a33 = a[aOffset + 15];

    for (int col = 0; col < 4; col++) {
      final int bCol = bOffset + (col * 4);
      final int oCol = outOffset + (col * 4);
      final double b0 = b[bCol];
      final double b1 = b[bCol + 1];
      final double b2 = b[bCol + 2];
      final double b3 = b[bCol + 3];

      out[oCol] = (a00 * b0) + (a01 * b1) + (a02 * b2) + (a03 * b3);
      out[oCol + 1] = (a10 * b0) + (a11 * b1) + (a12 * b2) + (a13 * b3);
      out[oCol + 2] = (a20 * b0) + (a21 * b1) + (a22 * b2) + (a23 * b3);
      out[oCol + 3] = (a30 * b0) + (a31 * b1) + (a32 * b2) + (a33 * b3);
    }
  }

  /// Transformuje punkt 3D przez macierz 4x4 z [Float64List] i zapisuje wynik
  /// do prealokowanego obiektu [out].
  static void transformPoint3Into(
    Float64List matrix,
    int matrixOffset,
    double x,
    double y,
    double z,
    Vector3 out,
  ) {
    final double rx = (matrix[matrixOffset] * x) +
        (matrix[matrixOffset + 4] * y) +
        (matrix[matrixOffset + 8] * z) +
        matrix[matrixOffset + 12];
    final double ry = (matrix[matrixOffset + 1] * x) +
        (matrix[matrixOffset + 5] * y) +
        (matrix[matrixOffset + 9] * z) +
        matrix[matrixOffset + 13];
    final double rz = (matrix[matrixOffset + 2] * x) +
        (matrix[matrixOffset + 6] * y) +
        (matrix[matrixOffset + 10] * z) +
        matrix[matrixOffset + 14];
    out.setValues(rx, ry, rz);
  }
}

/// Centralny menedżer puli obiektów dla silnika renderowania 3D 120 FPS.
///
/// Prealokuje przy starcie bufor macierzy transformacji 4x4 dla 176 kolarzy,
/// 352 kół, 890 cząsteczek pogody oraz pule robocze `Vector3`/`Matrix4`,
/// zapewniając zero alokacji na stercie w trakcie wykonywania metody `paint()`.
class RenderObjectPoolManager {
  /// Konfiguracja rozmiarów puli.
  final RenderPoolConfig config;

  /// Bufor 176 kolarzy.
  final RiderPoolBuffer riders;

  /// Bufor 352 kół i współrzędnych szprych.
  final WheelPoolBuffer wheels;

  /// Bufor cząsteczek deszczu, wody i kurzu.
  final WeatherParticlePoolBuffer weatherParticles;

  /// Pula robocza `Vector3` i `Matrix4` dla fazy `paint()`.
  final ScratchMathPool scratch;

  final Stopwatch _frameStopwatch = Stopwatch();
  int _lastFrameMicros = 0;

  RenderObjectPoolManager({
    this.config = const RenderPoolConfig(),
  })  : riders = RiderPoolBuffer(capacity: config.maxRiders),
        wheels = WheelPoolBuffer(
          capacity: config.maxWheels,
          maxSpokesPerWheel: config.maxSpokesPerWheel,
        ),
        weatherParticles = WeatherParticlePoolBuffer(
          capacity: config.maxWeatherParticles,
        ),
        scratch = ScratchMathPool(
          vector3Capacity: config.scratchVector3Capacity,
          matrix4Capacity: config.scratchMatrix4Capacity,
        );

  /// Rozpoczyna nową klatkę renderowania, zerując kursory bez alokacji pamięci.
  void beginFrame() {
    _frameStopwatch
      ..reset()
      ..start();
    scratch.resetFrame();
    riders.clearFrame();
    wheels.clearFrame();
  }

  /// Kończy klatkę renderowania i zapisuje czas jej wykonania w mikrosekundach.
  void endFrame() {
    _frameStopwatch.stop();
    _lastFrameMicros = _frameStopwatch.elapsedMicroseconds;
  }

  /// Czyści wszystkie bufory (np. przy wyjściu z widoku wyścigu 3D).
  void resetAll() {
    scratch.resetFrame();
    riders.clearFrame();
    wheels.clearFrame();
    weatherParticles.clearAll();
    _lastFrameMicros = 0;
  }

  /// Zwraca aktualną migawkę statystyk pamięci i wykorzystania puli.
  RenderPoolMemoryStats get memoryStats {
    final int totalBytes = riders.totalAllocatedBytes +
        wheels.totalAllocatedBytes +
        weatherParticles.totalAllocatedBytes +
        scratch.totalAllocatedBytes;

    return RenderPoolMemoryStats(
      maxRiders: riders.capacity,
      activeRiders: riders.activeCount,
      visibleRiders: riders.visibleCount,
      maxWheels: wheels.capacity,
      activeWheels: wheels.activeCount,
      maxWeatherParticles: weatherParticles.capacity,
      activeWeatherParticles: weatherParticles.activeTotal,
      activeRaindrops: weatherParticles.activeRaindrops,
      activeSprayParticles: weatherParticles.activeSpray,
      activeDustParticles: weatherParticles.activeDust,
      totalPreallocatedBytes: totalBytes,
      scratchVector3HighWaterMark: scratch.vector3HighWaterMark,
      scratchMatrix4HighWaterMark: scratch.matrix4HighWaterMark,
      lastFrameMicros: _lastFrameMicros,
      zeroAllocationActive: true,
    );
  }
}

/// Filtr widoku kategorii obiektów w panelu inspektora puli 3D.
enum PoolInspectorCategory {
  all('Wszystkie'),
  riders('176 Kolarzy'),
  wheels('352 Koła'),
  weather('Pogoda');

  final String label;
  const PoolInspectorCategory(this.label);
}

/// Responsywny panel diagnostyczny i sterujący dla [RenderObjectPoolManager].
class RenderObjectPoolInspectorPanel extends StatefulWidget {
  final RenderObjectPoolManager poolManager;
  final VoidCallback? onChanged;

  const RenderObjectPoolInspectorPanel({
    super.key,
    required this.poolManager,
    this.onChanged,
  });

  @override
  State<RenderObjectPoolInspectorPanel> createState() =>
      _RenderObjectPoolInspectorPanelState();
}

class _RenderObjectPoolInspectorPanelState
    extends State<RenderObjectPoolInspectorPanel> {
  PoolInspectorCategory _selectedCategory = PoolInspectorCategory.all;

  void _simulateFullPelotonFrame() {
    final RenderObjectPoolManager pool = widget.poolManager;
    pool.beginFrame();

    for (int i = 0; i < pool.riders.capacity; i++) {
      final int row = i ~/ 8;
      final int col = i % 8;
      final double posZ = 120.0 - (row * 2.1);
      final double posX = (col - 3.5) * 0.78;
      final double camDist = 140.0 - posZ;
      final int lod = camDist < 30.0 ? 0 : (camDist < 100.0 ? 1 : 2);

      pool.riders.setRiderState(
        slot: i,
        posX: posX,
        posY: 0.0,
        posZ: posZ,
        tangentX: 0.0,
        tangentY: 0.0,
        tangentZ: 1.0,
        rightX: 1.0,
        rightY: 0.0,
        rightZ: 0.0,
        upX: 0.0,
        upY: 1.0,
        upZ: 0.0,
        screenX: 640.0 + (posX * 18.0),
        screenY: 420.0 - (camDist * 0.6),
        screenScale: 1.0 / (1.0 + camDist * 0.02),
        cameraDistance: camDist,
        lodLevel: lod,
        isVisible: true,
      );

      final int frontWheelSlot = i * 2;
      final int rearWheelSlot = frontWheelSlot + 1;
      pool.wheels.setWheelState(
        wheelSlot: frontWheelSlot,
        worldX: posX,
        worldY: 0.34,
        worldZ: posZ + 0.52,
        rotationRadians: i * 0.15,
        angularVelocityRadPerSec: 36.0,
        motionBlurFactor: 0.75,
        rimDepthMeters: 0.05,
        screenCenterX: 640.0 + (posX * 18.0),
        screenCenterY: 420.0 - (camDist * 0.6),
        screenRadiusX: 16.0,
        screenRadiusY: 16.0,
      );
      pool.wheels.setWheelState(
        wheelSlot: rearWheelSlot,
        worldX: posX,
        worldY: 0.34,
        worldZ: posZ - 0.52,
        rotationRadians: i * 0.15,
        angularVelocityRadPerSec: 36.0,
        motionBlurFactor: 0.75,
        rimDepthMeters: 0.05,
        screenCenterX: 640.0 + (posX * 18.0),
        screenCenterY: 420.0 - (camDist * 0.6),
        screenRadiusX: 16.0,
        screenRadiusY: 16.0,
      );
    }

    pool.riders.sortVisibleBackToFront();

    if (pool.weatherParticles.activeTotal == 0) {
      for (int i = 0; i < 60; i++) {
        pool.weatherParticles.spawnParticle(
          kind: WeatherParticlePoolKind.raindrop,
          x: (i % 12) * 80.0,
          y: (i ~/ 12) * 40.0,
          z: 10.0,
          vx: -12.0,
          vy: 640.0,
          vz: 0.0,
          maxLifetime: 1.2,
        );
      }
    }

    pool.endFrame();
    setState(() {});
    widget.onChanged?.call();
  }

  void _clearAllPools() {
    widget.poolManager.resetAll();
    setState(() {});
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final RenderPoolMemoryStats stats = widget.poolManager.memoryStats;
    final bool hasActiveData = stats.activeRiders > 0 ||
        stats.activeWheels > 0 ||
        stats.activeWeatherParticles > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final int columns = width >= 920
              ? 3
              : (width >= 560 ? 2 : 1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildHeader(stats),
              const SizedBox(height: 12),
              _buildCategoryFilterBar(),
              const SizedBox(height: 12),
              _buildMetricsGrid(stats, columns),
              const SizedBox(height: 14),
              _buildActionBar(hasActiveData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(RenderPoolMemoryStats stats) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: stats.zeroAllocationActive
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Pula Obiektów 3D (Zero-GC 120 FPS)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: Text(
            '${stats.totalPreallocatedKilobytes.toStringAsFixed(1)} KB RAM',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PoolInspectorCategory.values.map((PoolInspectorCategory cat) {
        final bool selected = cat == _selectedCategory;
        return _PoolInteractiveButton(
          label: cat.label,
          isSelected: selected,
          isPrimary: false,
          onPressed: () {
            setState(() {
              _selectedCategory = cat;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildMetricsGrid(RenderPoolMemoryStats stats, int columns) {
    final List<Widget> cards = <Widget>[
      if (_selectedCategory == PoolInspectorCategory.all ||
          _selectedCategory == PoolInspectorCategory.riders)
        _PoolMetricCard(
          title: 'Kolarze Peletonu',
          value: '${stats.activeRiders} / ${stats.maxRiders}',
          subtitle: 'Widocznych: ${stats.visibleRiders} (Float64List 4x4)',
          accentColor: AppColors.goldAccent,
        ),
      if (_selectedCategory == PoolInspectorCategory.all ||
          _selectedCategory == PoolInspectorCategory.wheels)
        _PoolMetricCard(
          title: 'Koła i Szprychy',
          value: '${stats.activeWheels} / ${stats.maxWheels}',
          subtitle: 'Prealokowane macierze 4x4 + bufor szprych',
          accentColor: AppColors.accentBlue,
        ),
      if (_selectedCategory == PoolInspectorCategory.all ||
          _selectedCategory == PoolInspectorCategory.weather)
        _PoolMetricCard(
          title: 'Cząsteczki Pogody',
          value:
              '${stats.activeWeatherParticles} / ${stats.maxWeatherParticles}',
          subtitle:
              'Deszcz: ${stats.activeRaindrops} | Spray: ${stats.activeSprayParticles} | Kurz: ${stats.activeDustParticles}',
          accentColor: AppColors.cyanAccent,
        ),
    ];

    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards
            .map(
              (Widget card) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: card,
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double spacing = 10.0;
        final double cardWidth =
            (c.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (Widget card) => SizedBox(
                  width: cardWidth > 0 ? cardWidth : c.maxWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildActionBar(bool hasActiveData) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: <Widget>[
        _PoolInteractiveButton(
          label: 'Symuluj Klatkę 176 Kolarzy',
          isSelected: false,
          isPrimary: true,
          onPressed: _simulateFullPelotonFrame,
        ),
        _PoolInteractiveButton(
          label: 'Wyczyść Pule',
          isSelected: false,
          isPrimary: false,
          onPressed: hasActiveData ? _clearAllPools : null,
        ),
      ],
    );
  }
}

class _PoolMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  const _PoolMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolInteractiveButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _PoolInteractiveButton({
    required this.label,
    required this.isSelected,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_PoolInteractiveButton> createState() => _PoolInteractiveButtonState();
}

class _PoolInteractiveButtonState extends State<_PoolInteractiveButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;

    Color bgColor;
    if (!enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.45);
    } else if (widget.isPrimary) {
      bgColor = _pressed
          ? AppColors.primaryAccent.withValues(alpha: 0.78)
          : (_hovered
              ? AppColors.primaryAccent.withValues(alpha: 0.92)
              : AppColors.primaryAccent);
    } else if (widget.isSelected) {
      bgColor = AppColors.goldAccent.withValues(alpha: 0.18);
    } else {
      bgColor = _pressed
          ? AppColors.surfaceLight.withValues(alpha: 0.7)
          : (_hovered ? const Color(0xFF2B3140) : AppColors.surfaceLight);
    }

    final Color borderColor = !enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : (_focused
            ? AppColors.goldAccent
            : (widget.isSelected
                ? AppColors.goldAccent
                : const Color(0xFF2A2F3D)));

    final Color textColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isSelected ? AppColors.goldAccent : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (bool focused) {
        if (_focused != focused) setState(() => _focused = focused);
      },
      onShowHoverHighlight: (bool hovered) {
        if (_hovered != hovered) setState(() => _hovered = hovered);
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
