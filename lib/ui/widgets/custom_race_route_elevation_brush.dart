// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/stage_segment.dart';
import '../screens/stage_editor_creator_screen.dart';

/// Tryb pracy pędzla rzeźbienia terenu w Kreatorze Etapów.
enum ElevationBrushMode {
  /// Rysowanie/rzeźbienie wysokości bezpośrednio kursorem myszy lub palcem.
  sculpt,

  /// Wygładzanie ostrych szczytów i uskoków w promieniu pędzla.
  smooth,

  /// Wypłaszczanie terenu w kierunku wysokości docelowej w promieniu pędzla.
  flatten,

  /// Wybór i inspekcja pojedynczego węzła bez modyfikacji terenu.
  inspect,
}

/// Podsumowanie automatycznie wykrytego podjazdu na trasie.
class DetectedClimbSummary {
  final int startPointIndex;
  final int summitPointIndex;
  final double startKm;
  final double summitKm;
  final double lengthKm;
  final double elevationGainM;
  final double averageGradientPercent;
  final double maxGradientPercent;
  final SegmentClassification category;

  const DetectedClimbSummary({
    required this.startPointIndex,
    required this.summitPointIndex,
    required this.startKm,
    required this.summitKm,
    required this.lengthKm,
    required this.elevationGainM,
    required this.averageGradientPercent,
    required this.maxGradientPercent,
    required this.category,
  });

  String get categoryLabel {
    switch (category) {
      case SegmentClassification.horsCategorie:
        return 'HC';
      case SegmentClassification.cat1:
        return 'Cat 1';
      case SegmentClassification.cat2:
        return 'Cat 2';
      case SegmentClassification.cat3:
        return 'Cat 3';
      case SegmentClassification.cat4:
        return 'Cat 4';
      default:
        return '-';
    }
  }
}

/// Kalkulator nachylenia % oraz automatycznej kategoryzacji podjazdów (Cat 4, 3, 2, 1, HC).
class ClimbCategoryCalculator {
  ClimbCategoryCalculator._();

  /// Oblicza nachylenie [%] pomiędzy dwoma kolejnymi punktami trasy.
  static double calculateSegmentGradientPercent(
    StageEditorPoint prev,
    StageEditorPoint curr,
  ) {
    final double distMeters = (curr.distanceKm - prev.distanceKm) * 1000.0;
    if (distMeters <= 0.001) return 0.0;
    return ((curr.elevationMeters - prev.elevationMeters) / distMeters) * 100.0;
  }

  /// Klasyfikuje podjazd na podstawie długości [km], przewyższenia [m] i średniego nachylenia [%].
  static SegmentClassification classifyClimb({
    required double lengthKm,
    required double elevationGainM,
    required double avgGradientPercent,
  }) {
    if (lengthKm < 0.6 || elevationGainM < 35.0 || avgGradientPercent < 2.2) {
      return SegmentClassification.none;
    }

    // Skala trudności oparta na indeksie kolarskim (długość * nachylenie^2 + bonus za przewyższenie).
    final double difficultyScore =
        (lengthKm * avgGradientPercent * avgGradientPercent) +
            (elevationGainM * 0.08);

    if ((elevationGainM >= 800.0 && avgGradientPercent >= 6.0) ||
        difficultyScore >= 620.0) {
      return SegmentClassification.horsCategorie;
    }
    if (difficultyScore >= 320.0 ||
        (elevationGainM >= 450.0 && avgGradientPercent >= 5.5)) {
      return SegmentClassification.cat1;
    }
    if (difficultyScore >= 160.0 ||
        (elevationGainM >= 250.0 && avgGradientPercent >= 4.5)) {
      return SegmentClassification.cat2;
    }
    if (difficultyScore >= 70.0 ||
        (elevationGainM >= 110.0 && avgGradientPercent >= 4.0)) {
      return SegmentClassification.cat3;
    }
    if (difficultyScore >= 24.0 || elevationGainM >= 45.0) {
      return SegmentClassification.cat4;
    }
    return SegmentClassification.none;
  }

  /// Wykrywa wszystkie podjazdy na trasie i oblicza ich kategorię oraz nachylenia.
  static List<DetectedClimbSummary> analyzeClimbs(
    List<StageEditorPoint> points,
  ) {
    if (points.length < 2) return const [];

    final List<DetectedClimbSummary> climbs = [];
    int? climbStartIdx;
    double maxSegGrad = 0.0;

    void finalizeClimb(int startIdx, int endIdx) {
      if (endIdx <= startIdx) return;
      final startPt = points[startIdx];
      final endPt = points[endIdx];
      final double lenKm = endPt.distanceKm - startPt.distanceKm;
      final double gainM = endPt.elevationMeters - startPt.elevationMeters;
      if (lenKm <= 0.05 || gainM <= 0.0) return;

      final double avgGrad = (gainM / (lenKm * 1000.0)) * 100.0;
      final SegmentClassification cat = classifyClimb(
        lengthKm: lenKm,
        elevationGainM: gainM,
        avgGradientPercent: avgGrad,
      );
      if (cat == SegmentClassification.none) return;

      climbs.add(
        DetectedClimbSummary(
          startPointIndex: startIdx,
          summitPointIndex: endIdx,
          startKm: startPt.distanceKm,
          summitKm: endPt.distanceKm,
          lengthKm: lenKm,
          elevationGainM: gainM,
          averageGradientPercent: avgGrad,
          maxGradientPercent: math.max(maxSegGrad, avgGrad),
          category: cat,
        ),
      );
    }

    for (int i = 1; i < points.length; i++) {
      final double segGrad = calculateSegmentGradientPercent(
        points[i - 1],
        points[i],
      );

      if (segGrad >= 2.0) {
        climbStartIdx ??= i - 1;
        if (segGrad > maxSegGrad) {
          maxSegGrad = segGrad;
        }
      } else if (climbStartIdx != null) {
        // Tolerujemy krótkie wypłaszczenie (< 1.2 km i > -1.0%) w środku długiego podjazdu
        final bool isShortPlateau = i + 1 < points.length &&
            (points[i].distanceKm - points[i - 1].distanceKm) < 1.2 &&
            segGrad > -1.0 &&
            calculateSegmentGradientPercent(points[i], points[i + 1]) >= 2.5;
        if (!isShortPlateau) {
          finalizeClimb(climbStartIdx, i - 1);
          climbStartIdx = null;
          maxSegGrad = 0.0;
        }
      }
    }

    if (climbStartIdx != null) {
      finalizeClimb(climbStartIdx, points.length - 1);
    }

    return climbs;
  }

  /// Automatycznie przypisuje kategorie KOM (Cat 4..HC) na wykrytych szczytach,
  /// zachowując lotne premie sprinterskie oraz linię mety.
  static List<StageEditorPoint> applyAutoClimbClassifications(
    List<StageEditorPoint> points,
  ) {
    if (points.length < 2) return List<StageEditorPoint>.from(points);

    final climbs = analyzeClimbs(points);
    final Map<int, SegmentClassification> summitMap = {
      for (final c in climbs) c.summitPointIndex: c.category,
    };

    final List<StageEditorPoint> updated = [];
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (pt.classification == SegmentClassification.intermediateSprint ||
          pt.classification == SegmentClassification.finishLine) {
        updated.add(pt);
        continue;
      }

      final detectedCat = summitMap[i] ?? SegmentClassification.none;
      updated.add(pt.copyWith(classification: detectedCat));
    }
    return updated;
  }

  /// Zagęszcza długie odcinki (powyżej [maxSegmentKm]) przez liniową interpolację,
  /// aby pędzel mógł płynnie rzeźbić teren na dowolnym etapie.
  static List<StageEditorPoint> ensureBrushResolution(
    List<StageEditorPoint> points, {
    double maxSegmentKm = 2.5,
  }) {
    if (points.length < 2) return List<StageEditorPoint>.from(points);

    final List<StageEditorPoint> dense = [];
    int idSeed = DateTime.now().microsecondsSinceEpoch;

    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      dense.add(a);

      final double span = b.distanceKm - a.distanceKm;
      if (span > maxSegmentKm) {
        final int steps = (span / maxSegmentKm).ceil();
        for (int s = 1; s < steps; s++) {
          final double t = s / steps;
          dense.add(
            StageEditorPoint(
              id: 'brush_${idSeed++}',
              distanceKm: a.distanceKm + (span * t),
              elevationMeters:
                  a.elevationMeters + ((b.elevationMeters - a.elevationMeters) * t),
              surfaceType: b.surfaceType,
              classification: SegmentClassification.none,
              technicalDifficulty: a.technicalDifficulty,
              roadBearingDegrees: b.roadBearingDegrees,
              windDirectionDegrees: b.windDirectionDegrees,
            ),
          );
        }
      }
    }
    dense.add(points.last);
    return dense;
  }

  /// Nakłada pędzel rzeźbienia (Sculpt) o zadanej wysokości docelowej w promieniu [radiusKm].
  static List<StageEditorPoint> applySculptBrush({
    required List<StageEditorPoint> points,
    required double centerKm,
    required double targetElevationM,
    required double radiusKm,
    required double strength,
    double minElevationM = 0.0,
    double maxElevationM = 2850.0,
  }) {
    if (points.isEmpty) return const [];
    final double safeRadius = math.max(0.5, radiusKm);
    final double safeStrength = strength.clamp(0.05, 1.0);

    return points.map((pt) {
      final double dist = (pt.distanceKm - centerKm).abs();
      if (dist > safeRadius) return pt;

      // Krzywa kosinusowa dla gładkiego opadania wpływu pędzla na krawędziach.
      final double normalized = dist / safeRadius;
      final double falloff = 0.5 * (1.0 + math.cos(math.pi * normalized));
      final double weight = (falloff * safeStrength).clamp(0.0, 1.0);

      final double nextElev = (pt.elevationMeters +
              (targetElevationM - pt.elevationMeters) * weight)
          .clamp(minElevationM, maxElevationM);
      return pt.copyWith(elevationMeters: nextElev);
    }).toList();
  }

  /// Nakłada pędzel wygładzania (Smooth) w promieniu [radiusKm].
  static List<StageEditorPoint> applySmoothBrush({
    required List<StageEditorPoint> points,
    required double centerKm,
    required double radiusKm,
    required double strength,
    double minElevationM = 0.0,
    double maxElevationM = 2850.0,
  }) {
    if (points.length < 3) return List<StageEditorPoint>.from(points);
    final double safeRadius = math.max(0.5, radiusKm);
    final double safeStrength = strength.clamp(0.05, 1.0);
    final List<StageEditorPoint> result = List<StageEditorPoint>.from(points);

    for (int i = 1; i < points.length - 1; i++) {
      final pt = points[i];
      final double dist = (pt.distanceKm - centerKm).abs();
      if (dist > safeRadius) continue;

      final double falloff =
          0.5 * (1.0 + math.cos(math.pi * (dist / safeRadius)));
      final double avgNeighbor =
          (points[i - 1].elevationMeters + points[i + 1].elevationMeters) / 2.0;
      final double weight = (falloff * safeStrength).clamp(0.0, 1.0);
      final double nextElev =
          (pt.elevationMeters + (avgNeighbor - pt.elevationMeters) * weight)
              .clamp(minElevationM, maxElevationM);
      result[i] = pt.copyWith(elevationMeters: nextElev);
    }
    return result;
  }

  /// Nakłada pędzel wypłaszczania (Flatten) w kierunku średniej wysokości pod pędzlem.
  static List<StageEditorPoint> applyFlattenBrush({
    required List<StageEditorPoint> points,
    required double centerKm,
    required double radiusKm,
    required double strength,
    double minElevationM = 0.0,
    double maxElevationM = 2850.0,
  }) {
    if (points.isEmpty) return const [];
    final double safeRadius = math.max(0.5, radiusKm);
    final inRadius = points
        .where((p) => (p.distanceKm - centerKm).abs() <= safeRadius)
        .toList();
    if (inRadius.isEmpty) return List<StageEditorPoint>.from(points);

    final double avgElevation = inRadius
            .map((p) => p.elevationMeters)
            .reduce((a, b) => a + b) /
        inRadius.length;

    return applySculptBrush(
      points: points,
      centerKm: centerKm,
      targetElevationM: avgElevation,
      radiusKm: safeRadius,
      strength: strength,
      minElevationM: minElevationM,
      maxElevationM: maxElevationM,
    );
  }

  /// Zwraca kolor odpowiadający nachyleniu [gradientPercent] zgodnie ze standardem telewizyjnym.
  static Color colorForGradient(double gradientPercent) {
    if (gradientPercent >= 12.0) return AppColors.crimsonAlert;
    if (gradientPercent >= 9.0) return const Color(0xFFF97316);
    if (gradientPercent >= 6.0) return AppColors.amberWarning;
    if (gradientPercent >= 3.0) return AppColors.goldAccent;
    if (gradientPercent <= -4.0) return AppColors.accentBlue;
    return AppColors.statusSuccess;
  }
}

/// Interaktywny pędzel rzeźbienia terenu w Kreatorze Etapów.
///
/// Pozwala rysować kursorem myszy lub palcem profil wysokościowy trasy
/// z automatycznym wyliczaniem kategorii podjazdów (Cat 4, 3, 2, 1, HC)
/// oraz procentowego nachylenia terenu.
class CustomRaceRouteElevationBrush extends StatefulWidget {
  final List<StageEditorPoint> points;
  final int selectedPointIndex;
  final ValueChanged<List<StageEditorPoint>> onPointsChanged;
  final ValueChanged<int> onPointSelected;
  final bool enabled;
  final double minElevationLimit;
  final double maxElevationLimit;

  const CustomRaceRouteElevationBrush({
    super.key,
    required this.points,
    required this.selectedPointIndex,
    required this.onPointsChanged,
    required this.onPointSelected,
    this.enabled = true,
    this.minElevationLimit = 0.0,
    this.maxElevationLimit = 2850.0,
  });

  @override
  State<CustomRaceRouteElevationBrush> createState() =>
      _CustomRaceRouteElevationBrushState();
}

class _CustomRaceRouteElevationBrushState
    extends State<CustomRaceRouteElevationBrush> {
  static const double _padL = 42.0;
  static const double _padR = 20.0;
  static const double _padT = 26.0;
  static const double _padB = 30.0;

  ElevationBrushMode _mode = ElevationBrushMode.sculpt;
  double _brushRadiusKm = 10.0;
  final double _brushStrength = 0.65;
  bool _autoDetectClimbs = true;

  final List<List<StageEditorPoint>> _undoHistory = [];
  Offset? _cursorLocalPos;
  double? _hoverKm;
  double? _hoverElevationM;
  double? _hoverGradientPercent;
  bool _isDragging = false;

  double get _totalKm =>
      widget.points.isNotEmpty && widget.points.last.distanceKm > 0
          ? widget.points.last.distanceKm
          : 1.0;

  double get _minChartAlt {
    if (widget.points.isEmpty) return 0.0;
    final minP = widget.points
        .map((p) => p.elevationMeters)
        .reduce((a, b) => math.min(a, b));
    return math.max(widget.minElevationLimit, (minP - 80.0).floorToDouble());
  }

  double get _maxChartAlt {
    if (widget.points.isEmpty) return 1000.0;
    final maxP = widget.points
        .map((p) => p.elevationMeters)
        .reduce((a, b) => math.max(a, b));
    return math.min(
      widget.maxElevationLimit,
      math.max(600.0, maxP + 180.0),
    );
  }

  void _pushUndoSnapshot() {
    if (_undoHistory.length >= 20) {
      _undoHistory.removeAt(0);
    }
    _undoHistory.add(List<StageEditorPoint>.from(widget.points));
  }

  void _undo() {
    if (!widget.enabled || _undoHistory.isEmpty) return;
    final previous = _undoHistory.removeLast();
    widget.onPointsChanged(previous);
  }

  void _subdivideRoute() {
    if (!widget.enabled || widget.points.length < 2) return;
    _pushUndoSnapshot();
    final dense = ClimbCategoryCalculator.ensureBrushResolution(
      widget.points,
      maxSegmentKm: 2.0,
    );
    final finalPts = _autoDetectClimbs
        ? ClimbCategoryCalculator.applyAutoClimbClassifications(dense)
        : dense;
    widget.onPointsChanged(finalPts);
  }

  void _recalculateClimbsNow() {
    if (!widget.enabled || widget.points.length < 2) return;
    _pushUndoSnapshot();
    widget.onPointsChanged(
      ClimbCategoryCalculator.applyAutoClimbClassifications(widget.points),
    );
  }

  void _updateHoverTelemetry(Offset localPos, Size canvasSize) {
    final double chartW = math.max(1.0, canvasSize.width - _padL - _padR);
    final double chartH = math.max(1.0, canvasSize.height - _padT - _padB);

    final double ratioX =
        ((localPos.dx - _padL) / chartW).clamp(0.0, 1.0);
    final double ratioY =
        (1.0 - ((localPos.dy - _padT) / chartH)).clamp(0.0, 1.0);

    final double km = ratioX * _totalKm;
    final double minA = _minChartAlt;
    final double maxA = _maxChartAlt;
    final double elev = minA + ((maxA - minA) * ratioY);

    double? segGrad;
    if (widget.points.length >= 2) {
      for (int i = 1; i < widget.points.length; i++) {
        if (km <= widget.points[i].distanceKm || i == widget.points.length - 1) {
          segGrad = ClimbCategoryCalculator.calculateSegmentGradientPercent(
            widget.points[i - 1],
            widget.points[i],
          );
          break;
        }
      }
    }

    setState(() {
      _cursorLocalPos = localPos;
      _hoverKm = km;
      _hoverElevationM = elev;
      _hoverGradientPercent = segGrad;
    });
  }

  void _applyBrushAt(Offset localPos, Size canvasSize) {
    if (!widget.enabled || widget.points.length < 2) return;

    final double chartW = math.max(1.0, canvasSize.width - _padL - _padR);
    final double chartH = math.max(1.0, canvasSize.height - _padT - _padB);

    final double ratioX =
        ((localPos.dx - _padL) / chartW).clamp(0.0, 1.0);
    final double ratioY =
        (1.0 - ((localPos.dy - _padT) / chartH)).clamp(0.0, 1.0);

    final double targetKm = ratioX * _totalKm;
    final double minA = _minChartAlt;
    final double maxA = _maxChartAlt;
    final double targetElev = (minA + ((maxA - minA) * ratioY))
        .clamp(widget.minElevationLimit, widget.maxElevationLimit);

    // Zapewniamy odpowiednią gęstość węzłów przy pierwszym pociągnięciu pędzla
    final workingPoints = widget.points.length < 18
        ? ClimbCategoryCalculator.ensureBrushResolution(
            widget.points,
            maxSegmentKm: 2.5,
          )
        : widget.points;

    List<StageEditorPoint> sculpted;
    switch (_mode) {
      case ElevationBrushMode.sculpt:
        sculpted = ClimbCategoryCalculator.applySculptBrush(
          points: workingPoints,
          centerKm: targetKm,
          targetElevationM: targetElev,
          radiusKm: _brushRadiusKm,
          strength: _brushStrength,
          minElevationM: widget.minElevationLimit,
          maxElevationM: widget.maxElevationLimit,
        );
        break;
      case ElevationBrushMode.smooth:
        sculpted = ClimbCategoryCalculator.applySmoothBrush(
          points: workingPoints,
          centerKm: targetKm,
          radiusKm: _brushRadiusKm,
          strength: _brushStrength,
          minElevationM: widget.minElevationLimit,
          maxElevationM: widget.maxElevationLimit,
        );
        break;
      case ElevationBrushMode.flatten:
        sculpted = ClimbCategoryCalculator.applyFlattenBrush(
          points: workingPoints,
          centerKm: targetKm,
          radiusKm: _brushRadiusKm,
          strength: _brushStrength,
          minElevationM: widget.minElevationLimit,
          maxElevationM: widget.maxElevationLimit,
        );
        break;
      case ElevationBrushMode.inspect:
        _selectClosestPoint(targetKm);
        return;
    }

    if (_autoDetectClimbs) {
      sculpted = ClimbCategoryCalculator.applyAutoClimbClassifications(sculpted);
    }

    widget.onPointsChanged(sculpted);
  }

  void _selectClosestPoint(double tappedKm) {
    if (widget.points.isEmpty) return;
    int bestIdx = 0;
    double bestDiff = double.infinity;
    for (int i = 0; i < widget.points.length; i++) {
      final diff = (widget.points[i].distanceKm - tappedKm).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestIdx = i;
      }
    }
    widget.onPointSelected(bestIdx);
  }

  @override
  Widget build(BuildContext context) {
    final detectedClimbs = ClimbCategoryCalculator.analyzeClimbs(widget.points);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 620;
        final bool isMedium =
            constraints.maxWidth >= 620 && constraints.maxWidth < 1050;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. PASEK NARZĘDZI PĘDZLA
              _buildToolbar(
                isCompact: isCompact,
                isMedium: isMedium,
              ),
              const Divider(height: 1, color: AppColors.cardBorder),

              // 2. GŁÓWNE PŁÓTNO RZEŹBIENIA TERENU
              Expanded(
                child: LayoutBuilder(
                  builder: (context, canvasConstraints) {
                    final canvasSize = Size(
                      canvasConstraints.maxWidth,
                      canvasConstraints.maxHeight,
                    );
                    return Stack(
                      children: [
                        MouseRegion(
                          cursor: !widget.enabled
                              ? SystemMouseCursors.forbidden
                              : _mode == ElevationBrushMode.inspect
                                  ? SystemMouseCursors.click
                                  : SystemMouseCursors.precise,
                          onHover: (event) {
                            _updateHoverTelemetry(event.localPosition, canvasSize);
                          },
                          onExit: (_) {
                            setState(() {
                              _cursorLocalPos = null;
                              _hoverKm = null;
                              _hoverElevationM = null;
                              _hoverGradientPercent = null;
                            });
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              if (!widget.enabled) return;
                              final double chartW = math.max(
                                  1.0, canvasSize.width - _padL - _padR);
                              final double ratioX =
                                  ((details.localPosition.dx - _padL) / chartW)
                                      .clamp(0.0, 1.0);
                              final double tappedKm = ratioX * _totalKm;

                              if (_mode == ElevationBrushMode.inspect) {
                                _selectClosestPoint(tappedKm);
                              } else {
                                _pushUndoSnapshot();
                                _applyBrushAt(details.localPosition, canvasSize);
                              }
                            },
                            onPanStart: (details) {
                              if (!widget.enabled) return;
                              _isDragging = true;
                              if (_mode != ElevationBrushMode.inspect) {
                                _pushUndoSnapshot();
                              }
                              _updateHoverTelemetry(
                                  details.localPosition, canvasSize);
                              _applyBrushAt(details.localPosition, canvasSize);
                            },
                            onPanUpdate: (details) {
                              if (!widget.enabled || !_isDragging) return;
                              _updateHoverTelemetry(
                                  details.localPosition, canvasSize);
                              _applyBrushAt(details.localPosition, canvasSize);
                            },
                            onPanEnd: (_) {
                              setState(() => _isDragging = false);
                            },
                            child: CustomPaint(
                              size: canvasSize,
                              painter: _ElevationBrushCanvasPainter(
                                points: widget.points,
                                selectedIndex: widget.selectedPointIndex,
                                minAlt: _minChartAlt,
                                maxAlt: _maxChartAlt,
                                cursorPos: _cursorLocalPos,
                                brushRadiusKm: _brushRadiusKm,
                                brushMode: _mode,
                                isDragging: _isDragging,
                                padL: _padL,
                                padR: _padR,
                                padT: _padT,
                                padB: _padB,
                              ),
                            ),
                          ),
                        ),

                        // Pigułka telemetrii na żywo pod kursorem
                        Positioned(
                          top: 8,
                          left: 48,
                          right: 12,
                          child: IgnorePointer(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _buildTelemetryBadge(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // 3. PASEK WYKRYTYCH PODJAZDÓW (CAT 4 - HC)
              if (detectedClimbs.isNotEmpty) ...[
                const Divider(height: 1, color: AppColors.cardBorder),
                _buildDetectedClimbsBar(detectedClimbs, isCompact: isCompact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar({
    required bool isCompact,
    required bool isMedium,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Tryby pędzla
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _BrushActionChip(
                icon: Icons.brush_rounded,
                label: isCompact ? 'Rzeźbij' : 'Rzeźbienie',
                selected: _mode == ElevationBrushMode.sculpt,
                enabled: widget.enabled,
                accentColor: AppColors.goldAccent,
                onPressed: () =>
                    setState(() => _mode = ElevationBrushMode.sculpt),
              ),
              _BrushActionChip(
                icon: Icons.waves_rounded,
                label: isCompact ? 'Wygładź' : 'Wygładzanie',
                selected: _mode == ElevationBrushMode.smooth,
                enabled: widget.enabled,
                accentColor: AppColors.accentBlue,
                onPressed: () =>
                    setState(() => _mode = ElevationBrushMode.smooth),
              ),
              _BrushActionChip(
                icon: Icons.horizontal_rule_rounded,
                label: isCompact ? 'Wypłaszcz' : 'Wypłaszczanie',
                selected: _mode == ElevationBrushMode.flatten,
                enabled: widget.enabled,
                accentColor: AppColors.statusSuccess,
                onPressed: () =>
                    setState(() => _mode = ElevationBrushMode.flatten),
              ),
              _BrushActionChip(
                icon: Icons.ads_click_rounded,
                label: isCompact ? 'Węzeł' : 'Wybór Węzła',
                selected: _mode == ElevationBrushMode.inspect,
                enabled: widget.enabled,
                accentColor: AppColors.primaryAccent,
                onPressed: () =>
                    setState(() => _mode = ElevationBrushMode.inspect),
              ),
            ],
          ),

          // Parametry pędzla i akcje
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Promień pędzla
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.radar_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_brushRadiusKm.round()} km',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? 68 : (isMedium ? 84 : 100),
                      height: 24,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5.5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 10,
                          ),
                        ),
                        child: Slider(
                          value: _brushRadiusKm,
                          min: 3.0,
                          max: 25.0,
                          divisions: 22,
                          activeColor: AppColors.goldAccent,
                          inactiveColor: AppColors.cardBorder,
                          onChanged: widget.enabled
                              ? (v) => setState(() => _brushRadiusKm = v)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Auto-KOM przełącznik
              _BrushActionChip(
                icon: Icons.landscape_rounded,
                label: 'Auto-KOM',
                selected: _autoDetectClimbs,
                enabled: widget.enabled,
                accentColor: AppColors.amberWarning,
                onPressed: () {
                  setState(() => _autoDetectClimbs = !_autoDetectClimbs);
                  if (_autoDetectClimbs) {
                    _recalculateClimbsNow();
                  }
                },
              ),

              // Zagęść siatkę węzłów
              _BrushActionChip(
                icon: Icons.grain_rounded,
                label: 'Zagęść',
                selected: false,
                enabled: widget.enabled && widget.points.length >= 2,
                accentColor: AppColors.cyanAccent,
                onPressed: _subdivideRoute,
              ),

              // Cofnij
              _BrushActionChip(
                icon: Icons.undo_rounded,
                label: 'Cofnij',
                selected: false,
                enabled: widget.enabled && _undoHistory.isNotEmpty,
                accentColor: AppColors.textPrimary,
                onPressed: _undo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBadge() {
    final String modeHint = switch (_mode) {
      ElevationBrushMode.sculpt => 'Przeciągnij, aby wyrzeźbić wysokość',
      ElevationBrushMode.smooth => 'Przeciągnij, aby wygładzić profil',
      ElevationBrushMode.flatten => 'Przeciągnij, aby wypłaszczyć teren',
      ElevationBrushMode.inspect => 'Kliknij na węzeł, aby go edytować',
    };

    if (_hoverKm == null || _hoverElevationM == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(200),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          modeHint,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final double grad = _hoverGradientPercent ?? 0.0;
    final Color gradColor = ClimbCategoryCalculator.colorForGradient(grad);
    final String gradSign = grad > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_hoverKm!.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_hoverElevationM!.round()} m n.p.m.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: gradColor.withAlpha(35),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: gradColor.withAlpha(140)),
            ),
            child: Text(
              '$gradSign${grad.toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: gradColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedClimbsBar(
    List<DetectedClimbSummary> climbs, {
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: 7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(
              Icons.terrain_rounded,
              size: 14,
              color: AppColors.goldAccent,
            ),
            const SizedBox(width: 6),
            const Text(
              'Podjazdy:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            for (final climb in climbs) ...[
              _ClimbBadgePill(
                climb: climb,
                isSelected: widget.selectedPointIndex == climb.summitPointIndex,
                onTap: () => widget.onPointSelected(climb.summitPointIndex),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

/// Przycisk pędzla z pełnymi stanami hover, active, focus i disabled.
class _BrushActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _BrushActionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_BrushActionChip> createState() => _BrushActionChipState();
}

class _BrushActionChipState extends State<_BrushActionChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled;
    final Color bg = !active
        ? AppColors.surface.withAlpha(110)
        : widget.selected
            ? widget.accentColor.withAlpha(42)
            : _pressed
                ? AppColors.surface
                : _hovered
                    ? AppColors.cardBorder.withAlpha(160)
                    : AppColors.background;

    final Color border = !active
        ? AppColors.cardBorder.withAlpha(90)
        : widget.selected || _focused
            ? widget.accentColor
            : _hovered
                ? AppColors.textSecondary.withAlpha(140)
                : AppColors.cardBorder;

    final Color fg = !active
        ? AppColors.textSecondary.withAlpha(100)
        : widget.selected
            ? widget.accentColor
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: active,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (active) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: MouseRegion(
          cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: fg),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight:
                        widget.selected ? FontWeight.bold : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pigułka wykrytego podjazdu z kategorią KOM i parametrami nachylenia.
class _ClimbBadgePill extends StatefulWidget {
  final DetectedClimbSummary climb;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClimbBadgePill({
    required this.climb,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ClimbBadgePill> createState() => _ClimbBadgePillState();
}

class _ClimbBadgePillState extends State<_ClimbBadgePill> {
  bool _hovered = false;

  Color _catColor(SegmentClassification cat) {
    switch (cat) {
      case SegmentClassification.horsCategorie:
        return AppColors.powerZone7;
      case SegmentClassification.cat1:
        return AppColors.crimsonAlert;
      case SegmentClassification.cat2:
        return const Color(0xFFF97316);
      case SegmentClassification.cat3:
        return AppColors.amberWarning;
      case SegmentClassification.cat4:
        return AppColors.accentBlue;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color cColor = _catColor(widget.climb.category);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? cColor.withAlpha(45)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected ? cColor : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: cColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.climb.categoryLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.climb.summitKm.toStringAsFixed(1)} km • '
                '${widget.climb.lengthKm.toStringAsFixed(1)}km @ '
                '${widget.climb.averageGradientPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElevationBrushCanvasPainter extends CustomPainter {
  final List<StageEditorPoint> points;
  final int selectedIndex;
  final double minAlt;
  final double maxAlt;
  final Offset? cursorPos;
  final double brushRadiusKm;
  final ElevationBrushMode brushMode;
  final bool isDragging;
  final double padL;
  final double padR;
  final double padT;
  final double padB;

  const _ElevationBrushCanvasPainter({
    required this.points,
    required this.selectedIndex,
    required this.minAlt,
    required this.maxAlt,
    required this.cursorPos,
    required this.brushRadiusKm,
    required this.brushMode,
    required this.isDragging,
    required this.padL,
    required this.padR,
    required this.padT,
    required this.padB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double chartW = math.max(1.0, size.width - padL - padR);
    final double chartH = math.max(1.0, size.height - padT - padB);
    final double totalKm =
        points.last.distanceKm > 0 ? points.last.distanceKm : 1.0;
    final double altSpan = maxAlt > minAlt ? maxAlt - minAlt : 1.0;

    // 1. Siatka wysokości
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withAlpha(110)
      ..strokeWidth = 1.0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const int gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final double altVal = minAlt + (altSpan * (i / gridSteps));
      final double y = padT + chartH - (chartH * (i / gridSteps));
      canvas.drawLine(Offset(padL, y), Offset(padL + chartW, y), gridPaint);

      textPainter.text = TextSpan(
        text: '${altVal.round()}m',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          color: AppColors.textSecondary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - 6));
    }

    // 2. Współrzędne punktów
    final List<Offset> chartOffsets = [];
    for (final p in points) {
      final double x = padL + (chartW * (p.distanceKm / totalKm));
      final double y =
          padT + chartH - (chartH * ((p.elevationMeters - minAlt) / altSpan));
      chartOffsets.add(Offset(x, y));
    }

    // 3. Wypełnienie terenu + kolorowana linia nachylenia
    if (chartOffsets.length >= 2) {
      final fillPath = Path()..moveTo(chartOffsets.first.dx, padT + chartH);
      for (final off in chartOffsets) {
        fillPath.lineTo(off.dx, off.dy);
      }
      fillPath.lineTo(chartOffsets.last.dx, padT + chartH);
      fillPath.close();

      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryAccent.withAlpha(165),
          AppColors.surfaceLight.withAlpha(80),
        ],
      );
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader =
              fillGradient.createShader(Rect.fromLTWH(padL, padT, chartW, chartH))
          ..style = PaintingStyle.fill,
      );

      for (int i = 0; i < chartOffsets.length - 1; i++) {
        final double grad = ClimbCategoryCalculator.calculateSegmentGradientPercent(
          points[i],
          points[i + 1],
        );
        final segPaint = Paint()
          ..color = ClimbCategoryCalculator.colorForGradient(grad)
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(chartOffsets[i], chartOffsets[i + 1], segPaint);
      }
    }

    // 4. Pasek nawierzchni na dole
    final double barY = padT + chartH + 8.0;
    const double barH = 7.0;
    for (int i = 0; i < points.length - 1; i++) {
      final off1 = chartOffsets[i];
      final off2 = chartOffsets[i + 1];
      final surface = points[i + 1].surfaceType;
      Color surfColor = AppColors.surfaceLight;
      if (surface == SegmentSurfaceType.gravelStrade) {
        surfColor = AppColors.goldAccent;
      } else if (surface.name.contains('cobble')) {
        surfColor = const Color(0xFF8B5A2B);
      } else if (surface == SegmentSurfaceType.smoothAsphalt) {
        surfColor = const Color(0xFF4A5568);
      }
      canvas.drawRect(
        Rect.fromLTRB(off1.dx, barY, off2.dx, barY + barH),
        Paint()..color = surfColor,
      );
    }

    // 5. Węzły oraz flagi premii KOM / Sprint / Meta
    for (int i = 0; i < chartOffsets.length; i++) {
      final off = chartOffsets[i];
      final pt = points[i];
      final bool isSelected = i == selectedIndex;

      if (isSelected || pt.classification != SegmentClassification.none) {
        canvas.drawCircle(
          off,
          isSelected ? 6.0 : 3.8,
          Paint()..color = isSelected ? AppColors.goldAccent : Colors.white,
        );
        canvas.drawCircle(
          off,
          isSelected ? 6.0 : 3.8,
          Paint()
            ..color = Colors.black
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke,
        );
      }

      if (pt.classification != SegmentClassification.none) {
        String badge = '';
        Color badgeColor = Colors.white;
        switch (pt.classification) {
          case SegmentClassification.horsCategorie:
            badge = 'HC';
            badgeColor = AppColors.powerZone7;
            break;
          case SegmentClassification.cat1:
            badge = '1';
            badgeColor = AppColors.crimsonAlert;
            break;
          case SegmentClassification.cat2:
            badge = '2';
            badgeColor = const Color(0xFFF97316);
            break;
          case SegmentClassification.cat3:
            badge = '3';
            badgeColor = AppColors.amberWarning;
            break;
          case SegmentClassification.cat4:
            badge = '4';
            badgeColor = AppColors.accentBlue;
            break;
          case SegmentClassification.intermediateSprint:
            badge = 'S';
            badgeColor = AppColors.statusSuccess;
            break;
          case SegmentClassification.finishLine:
            badge = 'META';
            badgeColor = AppColors.goldAccent;
            break;
          case SegmentClassification.none:
            break;
        }

        if (badge.isNotEmpty) {
          final double boxW = badge.length > 2 ? 28.0 : 18.0;
          final r = Rect.fromCenter(
            center: Offset(off.dx, off.dy - 15),
            width: boxW,
            height: 14,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(4)),
            Paint()..color = badgeColor,
          );
          textPainter.text = TextSpan(
            text: badge,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(off.dx - (textPainter.width / 2), off.dy - 20.5),
          );
        }
      }
    }

    // 6. Podgląd pędzla i celownik pod kursorem
    if (cursorPos != null && brushMode != ElevationBrushMode.inspect) {
      final double clampedX = cursorPos!.dx.clamp(padL, padL + chartW);
      final double clampedY = cursorPos!.dy.clamp(padT, padT + chartH);
      final double radiusPx =
          ((brushRadiusKm / totalKm) * chartW).clamp(12.0, chartW * 0.45);

      final Color brushColor = switch (brushMode) {
        ElevationBrushMode.sculpt => AppColors.goldAccent,
        ElevationBrushMode.smooth => AppColors.accentBlue,
        ElevationBrushMode.flatten => AppColors.statusSuccess,
        ElevationBrushMode.inspect => AppColors.primaryAccent,
      };

      // Strefa wpływu pędzla w poziomie
      canvas.drawRect(
        Rect.fromLTRB(
          math.max(padL, clampedX - radiusPx),
          padT,
          math.min(padL + chartW, clampedX + radiusPx),
          padT + chartH,
        ),
        Paint()..color = brushColor.withAlpha(isDragging ? 38 : 22),
      );

      // Okrąg pędzla
      canvas.drawCircle(
        Offset(clampedX, clampedY),
        math.min(radiusPx, 36.0),
        Paint()
          ..color = brushColor.withAlpha(isDragging ? 220 : 160)
          ..strokeWidth = isDragging ? 2.0 : 1.3
          ..style = PaintingStyle.stroke,
      );

      // Linia krzyża
      canvas.drawLine(
        Offset(clampedX, padT),
        Offset(clampedX, padT + chartH),
        Paint()
          ..color = brushColor.withAlpha(110)
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ElevationBrushCanvasPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.minAlt != minAlt ||
        oldDelegate.maxAlt != maxAlt ||
        oldDelegate.cursorPos != cursorPos ||
        oldDelegate.brushRadiusKm != brushRadiusKm ||
        oldDelegate.brushMode != brushMode ||
        oldDelegate.isDragging != isDragging;
  }
}
