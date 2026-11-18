import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/rider_relationship_chemistry_web_model.dart';

/// Filtr widocznych połączeń w okrągłym grafie sieci relacji drużyny.
enum RelationshipWebToneFilter {
  /// Wszystkie widoczne połączenia (złote, zielone, czerwone i opcjonalnie neutralne).
  all,

  /// Wyłącznie złote pakty lojalności *Blood Brothers*.
  goldOnly,

  /// Pozytywne więzi (złote *Blood Brothers* oraz zielone sojusze).
  positiveOnly,

  /// Wyłącznie napięcia i konflikty (czerwone krawędzie).
  conflictsOnly;

  String get labelPl {
    switch (this) {
      case RelationshipWebToneFilter.all:
        return 'Wszystkie';
      case RelationshipWebToneFilter.goldOnly:
        return 'Blood Brothers';
      case RelationshipWebToneFilter.positiveOnly:
        return 'Pozytywne';
      case RelationshipWebToneFilter.conflictsOnly:
        return 'Konflikty';
    }
  }
}

/// Obliczona pozycja i promień pojedynczego węzła kolarza na okręgu grafu.
@immutable
class ChemistryWebNodeLayout {
  final String riderId;
  final RiderLockerRoomProfile profile;
  final Offset center;
  final double radius;
  final double angleRadians;
  final int index;

  const ChemistryWebNodeLayout({
    required this.riderId,
    required this.profile,
    required this.center,
    required this.radius,
    required this.angleRadians,
    required this.index,
  });

  /// Zwraca 1–2 literowe inicjały kolarza do wyświetlenia w węźle.
  String get initials {
    final parts = profile.riderName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, math.min(2, parts.first.length)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Zwraca skróconą etykietę nazwiska kolarza do podpisu na obwodzie.
  String get shortLabel {
    final parts = profile.riderName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return riderId;
    if (parts.length == 1) return parts.first;
    return '${parts.first[0]}. ${parts.last}';
  }
}

/// Geometria krzywej Béziera reprezentującej krawędź relacji w grafie.
@immutable
class ChemistryWebEdgeGeometry {
  final RiderRelationshipEdge edge;
  final RelationshipConnectionVisualTone tone;
  final Offset start;
  final Offset controlPoint;
  final Offset end;
  final BloodBrothersPact? activePact;

  const ChemistryWebEdgeGeometry({
    required this.edge,
    required this.tone,
    required this.start,
    required this.controlPoint,
    required this.end,
    this.activePact,
  });

  /// Oblicza punkt na kwadratowej krzywej Béziera dla parametru `t` z zakresu `0..1`.
  Offset pointAt(double t) {
    final inv = 1.0 - t;
    final x = inv * inv * start.dx +
        2.0 * inv * t * controlPoint.dx +
        t * t * end.dx;
    final y = inv * inv * start.dy +
        2.0 * inv * t * controlPoint.dy +
        t * t * end.dy;
    return Offset(x, y);
  }
}

/// Kalkulator układu kołowego i hit-testingu dla grafu sieci relacji drużyny.
class TeamChemistryWebLayoutCalculator {
  const TeamChemistryWebLayoutCalculator._();

  /// Wylicza deterministyczne pozycje węzłów kolarzy na okręgu wewnątrz `size`.
  static List<ChemistryWebNodeLayout> computeNodeLayouts({
    required RiderRelationshipChemistryWebModel model,
    required Size size,
  }) {
    if (model.profiles.isEmpty || size.width <= 0 || size.height <= 0) {
      return const <ChemistryWebNodeLayout>[];
    }

    final sortedProfiles = model.profiles.values.toList(growable: false)
      ..sort((a, b) {
        if (a.isTeamCaptain != b.isTeamCaptain) {
          return a.isTeamCaptain ? -1 : 1;
        }
        final leadDiff = b.leadershipWeight.compareTo(a.leadershipWeight);
        if (leadDiff != 0) return leadDiff;
        return a.riderName.compareTo(b.riderName);
      });

    final count = sortedProfiles.length;
    final minDim = math.min(size.width, size.height);
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final nodeRadius = (minDim * 0.068).clamp(14.0, 26.0);
    final labelPadding = (minDim * 0.145).clamp(34.0, 56.0);
    final orbitRadius = math.max(24.0, (minDim / 2.0) - labelPadding);

    if (count == 1) {
      return <ChemistryWebNodeLayout>[
        ChemistryWebNodeLayout(
          riderId: sortedProfiles.first.riderId,
          profile: sortedProfiles.first,
          center: center,
          radius: nodeRadius,
          angleRadians: -math.pi / 2.0,
          index: 0,
        ),
      ];
    }

    final result = <ChemistryWebNodeLayout>[];
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2.0 + (2.0 * math.pi * i / count);
      final nodeCenter = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );
      result.add(
        ChemistryWebNodeLayout(
          riderId: sortedProfiles[i].riderId,
          profile: sortedProfiles[i],
          center: nodeCenter,
          radius: nodeRadius,
          angleRadians: angle,
          index: i,
        ),
      );
    }
    return List<ChemistryWebNodeLayout>.unmodifiable(result);
  }

  /// Buduje listę widocznych krawędzi wraz z geometrią krzywych Béziera.
  static List<ChemistryWebEdgeGeometry> computeVisibleEdges({
    required RiderRelationshipChemistryWebModel model,
    required List<ChemistryWebNodeLayout> nodes,
    required Size size,
    required RelationshipWebToneFilter filter,
    bool showNeutralEdges = false,
    String? focusRiderId,
  }) {
    if (nodes.length < 2) return const <ChemistryWebEdgeGeometry>[];

    final nodeById = <String, ChemistryWebNodeLayout>{
      for (final node in nodes) node.riderId: node,
    };
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final result = <ChemistryWebEdgeGeometry>[];

    for (final edge in model.edges.values) {
      final nodeA = nodeById[edge.riderAId];
      final nodeB = nodeById[edge.riderBId];
      if (nodeA == null || nodeB == null) continue;

      final pact = model.getPactBetween(edge.riderAId, edge.riderBId);
      final hasActivePact = pact != null && pact.isActive;
      final tone = edge.visualTone(activePact: hasActivePact);

      if (!_matchesFilter(
        tone: tone,
        filter: filter,
        showNeutralEdges: showNeutralEdges,
        isFocusedRiderEdge:
            focusRiderId != null && edge.involves(focusRiderId),
      )) {
        continue;
      }

      final midPoint = Offset(
        (nodeA.center.dx + nodeB.center.dx) / 2.0,
        (nodeA.center.dy + nodeB.center.dy) / 2.0,
      );
      // Zakrzywienie w stronę środka okręgu (silniejsze dla sąsiednich węzłów).
      final pullFactor = tone == RelationshipConnectionVisualTone.gold
          ? 0.42
          : (tone == RelationshipConnectionVisualTone.red ? 0.36 : 0.28);
      final controlPoint = Offset(
        midPoint.dx + (center.dx - midPoint.dx) * pullFactor,
        midPoint.dy + (center.dy - midPoint.dy) * pullFactor,
      );

      result.add(
        ChemistryWebEdgeGeometry(
          edge: edge,
          tone: tone,
          start: nodeA.center,
          controlPoint: controlPoint,
          end: nodeB.center,
          activePact: hasActivePact ? pact : null,
        ),
      );
    }

    // Rysuj od neutralnych do złotych, aby najważniejsze połączenia były na wierzchu.
    result.sort((a, b) => _toneZOrder(a.tone).compareTo(_toneZOrder(b.tone)));
    return List<ChemistryWebEdgeGeometry>.unmodifiable(result);
  }

  static bool _matchesFilter({
    required RelationshipConnectionVisualTone tone,
    required RelationshipWebToneFilter filter,
    required bool showNeutralEdges,
    required bool isFocusedRiderEdge,
  }) {
    switch (filter) {
      case RelationshipWebToneFilter.all:
        if (tone == RelationshipConnectionVisualTone.neutral) {
          return showNeutralEdges || isFocusedRiderEdge;
        }
        return true;
      case RelationshipWebToneFilter.goldOnly:
        return tone == RelationshipConnectionVisualTone.gold;
      case RelationshipWebToneFilter.positiveOnly:
        return tone == RelationshipConnectionVisualTone.gold ||
            tone == RelationshipConnectionVisualTone.green;
      case RelationshipWebToneFilter.conflictsOnly:
        return tone == RelationshipConnectionVisualTone.red;
    }
  }

  static int _toneZOrder(RelationshipConnectionVisualTone tone) {
    switch (tone) {
      case RelationshipConnectionVisualTone.neutral:
        return 0;
      case RelationshipConnectionVisualTone.green:
        return 1;
      case RelationshipConnectionVisualTone.red:
        return 2;
      case RelationshipConnectionVisualTone.gold:
        return 3;
    }
  }

  /// Zwraca węzeł pod punktem kursora/dotyku lub `null`.
  static ChemistryWebNodeLayout? hitTestNode({
    required Offset position,
    required List<ChemistryWebNodeLayout> nodes,
  }) {
    for (final node in nodes.reversed) {
      final hitRadius = node.radius + 6.0;
      if ((position - node.center).distanceSquared <= hitRadius * hitRadius) {
        return node;
      }
    }
    return null;
  }

  /// Zwraca krawędź najbliższą punktowi `position` w promieniu `maxDistance`.
  static ChemistryWebEdgeGeometry? hitTestEdge({
    required Offset position,
    required List<ChemistryWebEdgeGeometry> edges,
    double maxDistance = 10.0,
  }) {
    ChemistryWebEdgeGeometry? best;
    var bestDistance = maxDistance;
    const samples = 20;

    for (final edgeGeo in edges.reversed) {
      for (var i = 0; i <= samples; i++) {
        final t = i / samples;
        final pt = edgeGeo.pointAt(t);
        final dist = (position - pt).distance;
        if (dist <= bestDistance) {
          bestDistance = dist;
          best = edgeGeo;
        }
      }
    }
    return best;
  }
}

/// Dedykowany `CustomPainter` rysujący okrągły graf sieci relacji w drużynie
/// ze złotymi (Blood Brothers), zielonymi (sojusze) i czerwonymi (konflikty) połączeniami.
class TeamChemistryRelationshipWebPainter extends CustomPainter {
  final RiderRelationshipChemistryWebModel model;
  final List<ChemistryWebNodeLayout> nodes;
  final List<ChemistryWebEdgeGeometry> edges;
  final String? selectedRiderId;
  final String? hoveredRiderId;
  final String? focusedRiderId;
  final String? selectedEdgePairKey;
  final String? hoveredEdgePairKey;
  final double pulseProgress;
  final bool enabled;

  const TeamChemistryRelationshipWebPainter({
    required this.model,
    required this.nodes,
    required this.edges,
    this.selectedRiderId,
    this.hoveredRiderId,
    this.focusedRiderId,
    this.selectedEdgePairKey,
    this.hoveredEdgePairKey,
    this.pulseProgress = 0.5,
    this.enabled = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2.0, size.height / 2.0);
    final minDim = math.min(size.width, size.height);
    final orbitRadius = nodes.isNotEmpty && nodes.length > 1
        ? (nodes.first.center - center).distance
        : (minDim * 0.34);

    _paintBackdropRings(canvas, center, orbitRadius);
    _paintEdges(canvas);
    _paintNodes(canvas, center);
  }

  void _paintBackdropRings(Canvas canvas, Offset center, double orbitRadius) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppTheme.borderColor.withValues(alpha: enabled ? 0.55 : 0.25);

    canvas.drawCircle(center, orbitRadius, ringPaint);
    canvas.drawCircle(
      center,
      orbitRadius * 0.66,
      ringPaint..color = AppTheme.borderColor.withValues(alpha: enabled ? 0.28 : 0.14),
    );
    canvas.drawCircle(
      center,
      orbitRadius * 0.33,
      ringPaint..color = AppTheme.borderColor.withValues(alpha: enabled ? 0.18 : 0.08),
    );

    // Subtelny punkt centralny sieci.
    final centerDotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.goldAccent.withValues(alpha: enabled ? 0.22 : 0.1);
    canvas.drawCircle(center, 3.5, centerDotPaint);
  }

  void _paintEdges(Canvas canvas) {
    final activeRiderId = hoveredRiderId ?? selectedRiderId;
    final activeEdgeKey = hoveredEdgePairKey ?? selectedEdgePairKey;
    final hasAnyFocus = activeRiderId != null || activeEdgeKey != null;

    for (final geo in edges) {
      final isEdgeDirectlyActive = geo.edge.pairKey == activeEdgeKey;
      final isConnectedToActiveRider =
          activeRiderId != null && geo.edge.involves(activeRiderId);
      final isEmphasized = isEdgeDirectlyActive || isConnectedToActiveRider;
      final isDimmed = hasAnyFocus && !isEmphasized;

      final baseColor = _colorForTone(geo.tone);
      final baseWidth = _strokeWidthForEdge(geo);
      final effectiveAlpha = !enabled
          ? 0.25
          : isDimmed
              ? 0.12
              : isEmphasized
                  ? 1.0
                  : 0.78;

      final path = Path()
        ..moveTo(geo.start.dx, geo.start.dy)
        ..quadraticBezierTo(
          geo.controlPoint.dx,
          geo.controlPoint.dy,
          geo.end.dx,
          geo.end.dy,
        );

      // Złota poświata dla paktu Blood Brothers lub podświetlonej krawędzi.
      if ((geo.tone == RelationshipConnectionVisualTone.gold || isEmphasized) &&
          !isDimmed &&
          enabled) {
        final glowAlpha = geo.tone == RelationshipConnectionVisualTone.gold
            ? 0.22 + 0.16 * math.sin(pulseProgress * math.pi * 2.0).abs()
            : 0.24;
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = baseWidth + (isEmphasized ? 6.0 : 4.5)
          ..color = baseColor.withValues(alpha: glowAlpha);
        canvas.drawPath(path, glowPaint);
      }

      final linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isEmphasized ? baseWidth + 1.2 : baseWidth
        ..color = baseColor.withValues(alpha: effectiveAlpha);

      canvas.drawPath(path, linePaint);

      // Dodatkowy znacznik na środku krzywej dla paktów Blood Brothers lub toksycznych konfliktów.
      if (!isDimmed &&
          enabled &&
          (geo.tone == RelationshipConnectionVisualTone.gold ||
              geo.edge.isToxicFeud ||
              isEdgeDirectlyActive)) {
        _paintEdgeMidpointBadge(
          canvas: canvas,
          geo: geo,
          color: baseColor,
          isDirectlyActive: isEdgeDirectlyActive,
        );
      }
    }
  }

  void _paintEdgeMidpointBadge({
    required Canvas canvas,
    required ChemistryWebEdgeGeometry geo,
    required Color color,
    required bool isDirectlyActive,
  }) {
    final mid = geo.pointAt(0.5);
    final badgeRadius = isDirectlyActive ? 11.0 : 7.5;

    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.surface;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;

    canvas.drawCircle(mid, badgeRadius, bgPaint);
    canvas.drawCircle(mid, badgeRadius, borderPaint);

    if (isDirectlyActive) {
      final scoreText = geo.edge.clampedScore >= 0
          ? '+${geo.edge.clampedScore}'
          : '${geo.edge.clampedScore}';
      final tp = TextPainter(
        text: TextSpan(
          text: scoreText,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, mid - Offset(tp.width / 2.0, tp.height / 2.0));
    } else if (geo.tone == RelationshipConnectionVisualTone.gold) {
      // Mały złoty diament w środku paktu Blood Brothers.
      final diamond = Path()
        ..moveTo(mid.dx, mid.dy - 3.8)
        ..lineTo(mid.dx + 3.8, mid.dy)
        ..lineTo(mid.dx, mid.dy + 3.8)
        ..lineTo(mid.dx - 3.8, mid.dy)
        ..close();
      canvas.drawPath(
        diamond,
        Paint()
          ..style = PaintingStyle.fill
          ..color = AppColors.goldAccent,
      );
    } else if (geo.edge.isToxicFeud) {
      // Znak ostrzegawczy X dla toksycznego konfliktu.
      final crossPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = AppColors.crimsonAlert;
      canvas.drawLine(
        Offset(mid.dx - 2.6, mid.dy - 2.6),
        Offset(mid.dx + 2.6, mid.dy + 2.6),
        crossPaint,
      );
      canvas.drawLine(
        Offset(mid.dx + 2.6, mid.dy - 2.6),
        Offset(mid.dx - 2.6, mid.dy + 2.6),
        crossPaint,
      );
    }
  }

  void _paintNodes(Canvas canvas, Offset graphCenter) {
    final activeRiderId = hoveredRiderId ?? selectedRiderId;

    for (final node in nodes) {
      final isSelected = node.riderId == selectedRiderId;
      final isHovered = node.riderId == hoveredRiderId;
      final isFocused = node.riderId == focusedRiderId;
      final isCaptain = node.profile.isTeamCaptain;

      // Sprawdź czy węzeł jest powiązany z aktywną krawędzią lub wybranym kolarzem.
      var isRelated = activeRiderId == null || activeRiderId == node.riderId;
      if (activeRiderId != null && activeRiderId != node.riderId) {
        isRelated = edges.any(
          (e) => e.edge.involves(activeRiderId) && e.edge.involves(node.riderId),
        );
      }

      final nodeOpacity = !enabled
          ? 0.45
          : isRelated
              ? 1.0
              : 0.52;

      // Zewnętrzna poświata przy selekcji lub focusie klawiatury.
      if (enabled && (isSelected || isHovered || isFocused)) {
        final ringColor = isFocused
            ? AppColors.cyanAccent
            : isSelected
                ? AppColors.goldAccent
                : AppColors.accentBlue;
        canvas.drawCircle(
          node.center,
          node.radius + 5.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isFocused ? 2.2 : 2.0
            ..color = ringColor.withValues(alpha: 0.72),
        );
      }

      // Wypełnienie węzła.
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = (isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.38)
                : AppColors.surfaceLight)
            .withValues(alpha: nodeOpacity);
      canvas.drawCircle(node.center, node.radius, fillPaint);

      // Obramowanie węzła (złote dla kapitana/wybranego, w przeciwnym razie AppTheme.borderColor).
      final borderColor = isSelected
          ? AppColors.goldAccent
          : isHovered
              ? AppColors.accentBlue
              : isCaptain
                  ? AppColors.goldAccent.withValues(alpha: 0.85)
                  : AppTheme.borderColor;
      canvas.drawCircle(
        node.center,
        node.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected || isCaptain ? 2.0 : 1.3
          ..color = borderColor.withValues(alpha: nodeOpacity),
      );

      // Inicjały wewnątrz węzła.
      final initialsPainter = TextPainter(
        text: TextSpan(
          text: node.initials,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: (node.radius * 0.62).clamp(10.0, 14.0),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textPrimary.withValues(alpha: nodeOpacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      initialsPainter.paint(
        canvas,
        node.center -
            Offset(initialsPainter.width / 2.0, initialsPainter.height / 2.0),
      );

      // Etykieta z nazwiskiem na zewnątrz okręgu.
      _paintNodeLabel(
        canvas: canvas,
        node: node,
        graphCenter: graphCenter,
        opacity: nodeOpacity,
        isHighlighted: isSelected || isHovered || isFocused,
      );
    }
  }

  void _paintNodeLabel({
    required Canvas canvas,
    required ChemistryWebNodeLayout node,
    required Offset graphCenter,
    required double opacity,
    required bool isHighlighted,
  }) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: node.shortLabel,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: -0.2,
          color: (isHighlighted ? AppColors.textPrimary : AppColors.textSecondary)
              .withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 88.0);

    final radialDir = node.center - graphCenter;
    final unit = radialDir.distance > 0.001
        ? radialDir / radialDir.distance
        : const Offset(0, -1);
    final labelAnchor = node.center + unit * (node.radius + 14.0);

    final labelOffset = Offset(
      labelAnchor.dx - labelPainter.width / 2.0,
      labelAnchor.dy - labelPainter.height / 2.0,
    );
    labelPainter.paint(canvas, labelOffset);
  }

  Color _colorForTone(RelationshipConnectionVisualTone tone) {
    switch (tone) {
      case RelationshipConnectionVisualTone.gold:
        return AppColors.goldAccent;
      case RelationshipConnectionVisualTone.green:
        return AppColors.statusSuccess;
      case RelationshipConnectionVisualTone.neutral:
        return AppColors.textSecondary;
      case RelationshipConnectionVisualTone.red:
        return AppColors.crimsonAlert;
    }
  }

  double _strokeWidthForEdge(ChemistryWebEdgeGeometry geo) {
    final absScore = geo.edge.clampedScore.abs();
    switch (geo.tone) {
      case RelationshipConnectionVisualTone.gold:
        return 3.4;
      case RelationshipConnectionVisualTone.green:
        return 1.6 + (absScore / 100.0) * 1.4;
      case RelationshipConnectionVisualTone.red:
        return geo.edge.isToxicFeud ? 3.1 : (1.7 + (absScore / 100.0) * 1.2);
      case RelationshipConnectionVisualTone.neutral:
        return 1.1;
    }
  }

  @override
  bool shouldRepaint(covariant TeamChemistryRelationshipWebPainter oldDelegate) {
    return oldDelegate.model != model ||
        oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.hoveredRiderId != hoveredRiderId ||
        oldDelegate.focusedRiderId != focusedRiderId ||
        oldDelegate.selectedEdgePairKey != selectedEdgePairKey ||
        oldDelegate.hoveredEdgePairKey != hoveredEdgePairKey ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.enabled != enabled;
  }
}

/// Pełny interaktywny panel okrągłego grafu sieci relacji w drużynie (#618).
///
/// Obsługuje:
/// - Złote (`#D4AF37` Blood Brothers), zielone (`#10B981`) i czerwone (`#EF4444`)
///   połączenia między kolarzami na okręgu.
/// - Pełne stany `hover`, `active`, `disabled` i `focus` (w tym nawigację klawiaturą).
/// - Responsywny układ `LayoutBuilder` dla `390x844`, `1024x768` i `1600x900`.
class TeamChemistryRelationshipWebWidget extends StatefulWidget {
  final RiderRelationshipChemistryWebModel model;
  final String? selectedRiderId;
  final ValueChanged<RiderLockerRoomProfile?>? onRiderSelected;
  final ValueChanged<RiderRelationshipEdge?>? onEdgeSelected;
  final void Function(String riderAId, String riderBId)? onForgePactRequested;
  final RelationshipWebToneFilter initialFilter;
  final bool showNeutralEdgesInitially;
  final bool enabled;
  final bool enableAmbientAnimation;

  const TeamChemistryRelationshipWebWidget({
    super.key,
    required this.model,
    this.selectedRiderId,
    this.onRiderSelected,
    this.onEdgeSelected,
    this.onForgePactRequested,
    this.initialFilter = RelationshipWebToneFilter.all,
    this.showNeutralEdgesInitially = false,
    this.enabled = true,
    this.enableAmbientAnimation = true,
  });

  @override
  State<TeamChemistryRelationshipWebWidget> createState() =>
      _TeamChemistryRelationshipWebWidgetState();
}

class _TeamChemistryRelationshipWebWidgetState
    extends State<TeamChemistryRelationshipWebWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final FocusNode _canvasFocusNode = FocusNode(debugLabel: 'ChemistryWebCanvas');

  late RelationshipWebToneFilter _filter;
  late bool _showNeutralEdges;
  String? _selectedRiderId;
  String? _hoveredRiderId;
  String? _focusedRiderId;
  String? _selectedEdgePairKey;
  String? _hoveredEdgePairKey;
  bool _isCanvasFocused = false;
  bool _isPointerPressed = false;

  Size _lastCanvasSize = Size.zero;
  List<ChemistryWebNodeLayout> _cachedNodes = const <ChemistryWebNodeLayout>[];
  List<ChemistryWebEdgeGeometry> _cachedEdges =
      const <ChemistryWebEdgeGeometry>[];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _showNeutralEdges = widget.showNeutralEdgesInitially;
    _selectedRiderId = widget.selectedRiderId;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.enableAmbientAnimation && widget.enabled) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant TeamChemistryRelationshipWebWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRiderId != oldWidget.selectedRiderId) {
      _selectedRiderId = widget.selectedRiderId;
    }
    if (widget.enabled != oldWidget.enabled ||
        widget.enableAmbientAnimation != oldWidget.enableAmbientAnimation) {
      if (widget.enableAmbientAnimation && widget.enabled) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        _pulseController.stop();
        _pulseController.value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _canvasFocusNode.dispose();
    super.dispose();
  }

  void _updateGeometry(Size size) {
    _lastCanvasSize = size;
    _cachedNodes = TeamChemistryWebLayoutCalculator.computeNodeLayouts(
      model: widget.model,
      size: size,
    );
    _cachedEdges = TeamChemistryWebLayoutCalculator.computeVisibleEdges(
      model: widget.model,
      nodes: _cachedNodes,
      size: size,
      filter: _filter,
      showNeutralEdges: _showNeutralEdges,
      focusRiderId: _hoveredRiderId ?? _selectedRiderId,
    );
  }

  void _handleHover(Offset localPosition) {
    if (!widget.enabled || _lastCanvasSize.isEmpty) return;

    final hitNode = TeamChemistryWebLayoutCalculator.hitTestNode(
      position: localPosition,
      nodes: _cachedNodes,
    );
    if (hitNode != null) {
      if (_hoveredRiderId != hitNode.riderId || _hoveredEdgePairKey != null) {
        setState(() {
          _hoveredRiderId = hitNode.riderId;
          _hoveredEdgePairKey = null;
        });
      }
      return;
    }

    final hitEdge = TeamChemistryWebLayoutCalculator.hitTestEdge(
      position: localPosition,
      edges: _cachedEdges,
    );
    final nextEdgeKey = hitEdge?.edge.pairKey;
    if (_hoveredRiderId != null || _hoveredEdgePairKey != nextEdgeKey) {
      setState(() {
        _hoveredRiderId = null;
        _hoveredEdgePairKey = nextEdgeKey;
      });
    }
  }

  void _handleTap(Offset localPosition) {
    if (!widget.enabled || _lastCanvasSize.isEmpty) return;
    _canvasFocusNode.requestFocus();

    final hitNode = TeamChemistryWebLayoutCalculator.hitTestNode(
      position: localPosition,
      nodes: _cachedNodes,
    );
    if (hitNode != null) {
      final isDeselect = _selectedRiderId == hitNode.riderId;
      setState(() {
        _selectedRiderId = isDeselect ? null : hitNode.riderId;
        _focusedRiderId = _selectedRiderId;
        _selectedEdgePairKey = null;
      });
      widget.onRiderSelected?.call(isDeselect ? null : hitNode.profile);
      widget.onEdgeSelected?.call(null);
      return;
    }

    final hitEdge = TeamChemistryWebLayoutCalculator.hitTestEdge(
      position: localPosition,
      edges: _cachedEdges,
    );
    if (hitEdge != null) {
      final isDeselect = _selectedEdgePairKey == hitEdge.edge.pairKey;
      setState(() {
        _selectedEdgePairKey = isDeselect ? null : hitEdge.edge.pairKey;
        _selectedRiderId = null;
      });
      widget.onEdgeSelected?.call(isDeselect ? null : hitEdge.edge);
      widget.onRiderSelected?.call(null);
      return;
    }

    if (_selectedRiderId != null || _selectedEdgePairKey != null) {
      setState(() {
        _selectedRiderId = null;
        _selectedEdgePairKey = null;
      });
      widget.onRiderSelected?.call(null);
      widget.onEdgeSelected?.call(null);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent || _cachedNodes.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _cycleFocusedRider(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _cycleFocusedRider(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      if (_focusedRiderId != null) {
        final match = _cachedNodes.where((n) => n.riderId == _focusedRiderId);
        if (match.isNotEmpty) {
          final isDeselect = _selectedRiderId == _focusedRiderId;
          setState(() {
            _selectedRiderId = isDeselect ? null : _focusedRiderId;
            _selectedEdgePairKey = null;
          });
          widget.onRiderSelected?.call(isDeselect ? null : match.first.profile);
          return KeyEventResult.handled;
        }
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _selectedRiderId = null;
        _selectedEdgePairKey = null;
        _focusedRiderId = null;
      });
      widget.onRiderSelected?.call(null);
      widget.onEdgeSelected?.call(null);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _cycleFocusedRider(int delta) {
    if (_cachedNodes.isEmpty) return;
    final currentIdx = _cachedNodes.indexWhere(
      (n) => n.riderId == (_focusedRiderId ?? _selectedRiderId),
    );
    final nextIdx = currentIdx == -1
        ? 0
        : (currentIdx + delta + _cachedNodes.length) % _cachedNodes.length;
    final nextNode = _cachedNodes[nextIdx];
    setState(() {
      _focusedRiderId = nextNode.riderId;
      _selectedRiderId = nextNode.riderId;
      _selectedEdgePairKey = null;
    });
    widget.onRiderSelected?.call(nextNode.profile);
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.model.calculateOverallTeamChemistry();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCanvasFocused
              ? AppColors.cyanAccent.withValues(alpha: 0.7)
              : AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;
          final isWideDesktop = constraints.maxWidth >= 1000;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(summary, isCompact: isCompact),
              const SizedBox(height: 12),
              _buildFilterBar(isCompact: isCompact),
              const SizedBox(height: 14),
              if (widget.model.profiles.isEmpty)
                _buildEmptyState()
              else if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGraphCanvas(
                      height: math.min(340.0, math.max(250.0, constraints.maxWidth - 16)),
                    ),
                    const SizedBox(height: 12),
                    _buildLegendStrip(),
                    const SizedBox(height: 12),
                    _buildInspectorPanel(summary),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isWideDesktop ? 6 : 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGraphCanvas(height: isWideDesktop ? 430.0 : 370.0),
                          const SizedBox(height: 10),
                          _buildLegendStrip(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: isWideDesktop ? 4 : 5,
                      child: _buildInspectorPanel(summary),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(TeamChemistrySummary summary, {required bool isCompact}) {
    final atmosphereColor = _atmosphereColor(summary.atmosphere);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.hub_outlined,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sieć Relacji Szatni',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Sezon ${widget.model.seasonYear} • ${widget.model.profiles.length} kolarzy',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: atmosphereColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: atmosphereColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${summary.atmosphere.displayNamePl} (${summary.overallScore.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: atmosphereColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar({required bool isCompact}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final filterOption in RelationshipWebToneFilter.values)
          _ChemistryFilterChip(
            label: filterOption.labelPl,
            selected: _filter == filterOption,
            enabled: widget.enabled,
            accentColor: _filterAccentColor(filterOption),
            onPressed: () {
              setState(() {
                _filter = filterOption;
              });
            },
          ),
        _ChemistryFilterChip(
          label: 'Neutralne',
          selected: _showNeutralEdges,
          enabled: widget.enabled && _filter == RelationshipWebToneFilter.all,
          accentColor: AppColors.accentBlue,
          onPressed: () {
            setState(() {
              _showNeutralEdges = !_showNeutralEdges;
            });
          },
        ),
      ],
    );
  }

  Widget _buildGraphCanvas({required double height}) {
    final hasInteractiveTarget =
        _hoveredRiderId != null || _hoveredEdgePairKey != null;

    return Focus(
      focusNode: _canvasFocusNode,
      onFocusChange: (focused) {
        setState(() {
          _isCanvasFocused = focused;
          if (!focused) _focusedRiderId = null;
        });
      },
      onKeyEvent: _handleKeyEvent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isCanvasFocused
                ? AppColors.cyanAccent
                : (_isPointerPressed
                    ? AppColors.goldAccent.withValues(alpha: 0.7)
                    : AppTheme.borderColor),
            width: _isCanvasFocused ? 1.5 : 1.0,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, box.maxHeight);
            _updateGeometry(size);

            return MouseRegion(
              cursor: widget.enabled && hasInteractiveTarget
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onHover: (event) => _handleHover(event.localPosition),
              onExit: (_) {
                if (_hoveredRiderId != null || _hoveredEdgePairKey != null) {
                  setState(() {
                    _hoveredRiderId = null;
                    _hoveredEdgePairKey = null;
                  });
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: widget.enabled
                    ? (_) => setState(() => _isPointerPressed = true)
                    : null,
                onTapCancel: widget.enabled
                    ? () => setState(() => _isPointerPressed = false)
                    : null,
                onTapUp: widget.enabled
                    ? (details) {
                        setState(() => _isPointerPressed = false);
                        _handleTap(details.localPosition);
                      }
                    : null,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: size,
                      painter: TeamChemistryRelationshipWebPainter(
                        model: widget.model,
                        nodes: _cachedNodes,
                        edges: _cachedEdges,
                        selectedRiderId: _selectedRiderId,
                        hoveredRiderId: _hoveredRiderId,
                        focusedRiderId: _isCanvasFocused ? _focusedRiderId : null,
                        selectedEdgePairKey: _selectedEdgePairKey,
                        hoveredEdgePairKey: _hoveredEdgePairKey,
                        pulseProgress: _pulseController.value,
                        enabled: widget.enabled,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegendStrip() {
    return const Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _LegendItem(
          color: AppColors.goldAccent,
          label: 'Blood Brothers',
        ),
        _LegendItem(
          color: AppColors.statusSuccess,
          label: 'Zaufanie (+25..+100)',
        ),
        _LegendItem(
          color: AppColors.crimsonAlert,
          label: 'Konflikt (-25..-100)',
        ),
      ],
    );
  }

  Widget _buildInspectorPanel(TeamChemistrySummary summary) {
    final activeEdgeKey = _selectedEdgePairKey ?? _hoveredEdgePairKey;
    if (activeEdgeKey != null) {
      final edge = widget.model.edges[activeEdgeKey];
      if (edge != null) {
        return _buildEdgeInspector(edge);
      }
    }

    final activeRiderId = _selectedRiderId ?? _hoveredRiderId;
    if (activeRiderId != null) {
      final profile = widget.model.profiles[activeRiderId];
      if (profile != null) {
        return _buildRiderInspector(profile);
      }
    }

    return _buildSummaryInspector(summary);
  }

  Widget _buildSummaryInspector(TeamChemistrySummary summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Podsumowanie Chemii',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Najedź lub kliknij kolarza albo połączenie, aby zbadać szczegóły relacji.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Pakty Blood Brothers',
            value: '${summary.activeBloodBrothersCount}',
            valueColor: AppColors.goldAccent,
          ),
          _MetricRow(
            label: 'Połączenia pozytywne',
            value: '${summary.positiveEdgesCount}',
            valueColor: AppColors.statusSuccess,
          ),
          _MetricRow(
            label: 'Konflikty / Waśnie',
            value: '${summary.conflictEdgesCount} (${summary.toxicFeudsCount} toks.)',
            valueColor: summary.conflictEdgesCount > 0
                ? AppColors.crimsonAlert
                : AppColors.textPrimary,
          ),
          _MetricRow(
            label: 'Zgranie w dniu wyścigu',
            value: '${(summary.raceDayCohesionMultiplier * 100).toStringAsFixed(1)}%',
            valueColor: AppColors.accentBlue,
          ),
          _MetricRow(
            label: 'Ryzyko buntu liderów',
            value: '${summary.leadershipConflictRisk.toStringAsFixed(1)}%',
            valueColor: summary.leadershipConflictRisk >= 35
                ? AppColors.amberWarning
                : AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildRiderInspector(RiderLockerRoomProfile profile) {
    final connections = widget.model.getConnectionsForRider(profile.riderId);
    final bloodBrothers = widget.model.getBloodBrothersFor(profile.riderId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: profile.isTeamCaptain
              ? AppColors.goldAccent.withValues(alpha: 0.6)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      profile.archetype.displayNamePl,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (profile.isTeamCaptain)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.goldAccent),
                  ),
                  child: const Text(
                    'Kapitan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: 'Morale',
            value: '${profile.currentMorale}%',
            valueColor: profile.currentMorale >= 70
                ? AppColors.statusSuccess
                : AppColors.amberWarning,
          ),
          _MetricRow(
            label: 'Wpływ / Ego',
            value: '${profile.leadershipWeight} / ${profile.egoLevel}',
          ),
          _MetricRow(
            label: 'Blood Brothers',
            value: '${bloodBrothers.length}',
            valueColor: AppColors.goldAccent,
          ),
          const SizedBox(height: 8),
          const Text(
            'Kluczowe relacje:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          for (final edge in connections.take(4)) ...[
            _ConnectionMiniTile(
              partnerName: widget.model.profiles[edge.otherRiderId(profile.riderId)]
                      ?.riderName ??
                  edge.otherRiderId(profile.riderId),
              edge: edge,
              hasActivePact:
                  widget.model.getPactBetween(edge.riderAId, edge.riderBId)?.isActive ??
                      false,
              onTap: widget.enabled
                  ? () {
                      setState(() {
                        _selectedEdgePairKey = edge.pairKey;
                      });
                      widget.onEdgeSelected?.call(edge);
                    }
                  : null,
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildEdgeInspector(RiderRelationshipEdge edge) {
    final nameA = widget.model.profiles[edge.riderAId]?.riderName ?? edge.riderAId;
    final nameB = widget.model.profiles[edge.riderBId]?.riderName ?? edge.riderBId;
    final pact = widget.model.getPactBetween(edge.riderAId, edge.riderBId);
    final hasActivePact = pact != null && pact.isActive;
    final tier = edge.tierWithPactStatus(activePact: hasActivePact);
    final canForge = widget.model.canForgeBloodBrothersPact(
      edge.riderAId,
      edge.riderBId,
    );

    final scoreColor = hasActivePact
        ? AppColors.goldAccent
        : edge.clampedScore >= 25
            ? AppColors.statusSuccess
            : edge.clampedScore <= -25
                ? AppColors.crimsonAlert
                : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scoreColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$nameA ↔ $nameB',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${tier.displayNamePl} (${edge.clampedScore >= 0 ? '+' : ''}${edge.clampedScore})',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scoreColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          _MetricRow(label: 'Zaufanie taktyczne', value: '${edge.trust}/100'),
          _MetricRow(label: 'Szacunek sportowy', value: '${edge.respect}/100'),
          _MetricRow(
            label: 'Napięcie w szatni',
            value: '${edge.tension}/100',
            valueColor: edge.tension >= 60 ? AppColors.crimsonAlert : AppColors.textPrimary,
          ),
          _MetricRow(label: 'Wspólne wyścigi', value: '${edge.sharedRacesCount}'),
          const SizedBox(height: 6),
          Text(
            edge.lastInteractionReason,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (canForge && widget.onForgePactRequested != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.enabled
                    ? () => widget.onForgePactRequested!(
                          edge.riderAId,
                          edge.riderBId,
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.surface,
                  disabledForegroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.workspace_premium, size: 16),
                label: const Text(
                  'Zawrzyj pakt Blood Brothers',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_off_outlined, size: 32, color: AppColors.textSecondary),
          SizedBox(height: 8),
          Text(
            'Brak kolarzy w sieci relacji szatni',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _atmosphereColor(LockerRoomAtmosphere atmosphere) {
    switch (atmosphere) {
      case LockerRoomAtmosphere.unitedFront:
        return AppColors.goldAccent;
      case LockerRoomAtmosphere.harmonious:
        return AppColors.statusSuccess;
      case LockerRoomAtmosphere.professional:
        return AppColors.accentBlue;
      case LockerRoomAtmosphere.tense:
        return AppColors.amberWarning;
      case LockerRoomAtmosphere.fractured:
      case LockerRoomAtmosphere.civilWar:
        return AppColors.crimsonAlert;
    }
  }

  Color _filterAccentColor(RelationshipWebToneFilter filter) {
    switch (filter) {
      case RelationshipWebToneFilter.all:
        return AppColors.primaryAccent;
      case RelationshipWebToneFilter.goldOnly:
        return AppColors.goldAccent;
      case RelationshipWebToneFilter.positiveOnly:
        return AppColors.statusSuccess;
      case RelationshipWebToneFilter.conflictsOnly:
        return AppColors.crimsonAlert;
    }
  }
}

class _ChemistryFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _ChemistryFilterChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_ChemistryFilterChip> createState() => _ChemistryFilterChipState();
}

class _ChemistryFilterChipState extends State<_ChemistryFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surface
        : widget.selected
            ? widget.accentColor.withValues(alpha: _pressed ? 0.34 : 0.22)
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.background);

    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
            ? AppColors.cyanAccent
            : widget.selected
                ? widget.accentColor
                : (_hovered ? AppColors.accentBlue : AppTheme.borderColor);

    final textColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.selected
            ? widget.accentColor
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionMiniTile extends StatelessWidget {
  final String partnerName;
  final RiderRelationshipEdge edge;
  final bool hasActivePact;
  final VoidCallback? onTap;

  const _ConnectionMiniTile({
    required this.partnerName,
    required this.edge,
    required this.hasActivePact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tone = edge.visualTone(activePact: hasActivePact);
    final color = tone == RelationshipConnectionVisualTone.gold
        ? AppColors.goldAccent
        : tone == RelationshipConnectionVisualTone.green
            ? AppColors.statusSuccess
            : tone == RelationshipConnectionVisualTone.red
                ? AppColors.crimsonAlert
                : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                partnerName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${edge.clampedScore >= 0 ? '+' : ''}${edge.clampedScore}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
