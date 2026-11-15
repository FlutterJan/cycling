// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Docelowa strona szosy dla formacji kolarzy (Gutter Target).
enum RoadGutterTarget {
  /// Lewa skrajna krawędź szosy (Lewy rynsztok / krawężnik)
  farLeft(-0.85, 'Lewe Pobocze (Gutter Left)', Icons.arrow_back),

  /// Lewa strona jezdni (przed zakrętem w lewo lub wiatrem z prawej)
  leftGutter(-0.50, 'Lewa Strona', Icons.keyboard_double_arrow_left),

  /// Środek szosy (Bezpieczny środek grupy, osłona z każdej strony)
  centerPack(0.0, 'Środek Szosy', Icons.adjust),

  /// Prawa strona jezdni (przed zakrętem w prawo lub wiatrem z lewej)
  rightGutter(0.50, 'Prawa Strona', Icons.keyboard_double_arrow_right),

  /// Prawa skrajna krawędź szosy (Prawy rynsztok / krawężnik)
  farRight(0.85, 'Prawe Pobocze (Gutter Right)', Icons.arrow_forward);

  final double lateralOffset; // -1.0 (lewa) do +1.0 (prawa)
  final String label;
  final IconData icon;

  const RoadGutterTarget(this.lateralOffset, this.label, this.icon);

  /// Zwraca najbliższy preset dla danego przesunięcia bocznego [-1.0 .. 1.0].
  static RoadGutterTarget fromOffset(double offset) {
    if (offset <= -0.68) return RoadGutterTarget.farLeft;
    if (offset <= -0.25) return RoadGutterTarget.leftGutter;
    if (offset < 0.25) return RoadGutterTarget.centerPack;
    if (offset < 0.68) return RoadGutterTarget.rightGutter;
    return RoadGutterTarget.farRight;
  }
}

/// Dynamiczny kształt aerodynamiczny peletonu zależny od prędkości i wiatru.
enum PelotonShapeType {
  /// Szeroka ława przy niskim tempie (30-38 km/h) – kolarze zajmują całą szerokość szosy
  broadBunch('Szeroka Ława', 'Spokojne tempo peletonu (zwarta grupa, szeroki front)'),

  /// Zrównoważony szyk przy umiarkowanym tempie (39-48 km/h)
  standardPack('Standardowy Szyk', 'Tempo etapowe (zwężający się klin)'),

  /// Długa pojedyncza kreska (Single File) przy prędkości 50-65 km/h – walka o pozycję!
  strungOutSingleFile('Pojedyncza Kreska (Single File)', 'Piekielne tempo (kolarze jadą gęsiego koło w koło)'),

  /// Wachlarz (Echelon) przy silnym wietrze bocznym
  crosswindEchelon('Wachlarz (Echelon)', 'Skośna formacja na rancie szosy pod wiatr');

  final String title;
  final String description;

  const PelotonShapeType(this.title, this.description);

  /// Określa kształt grupy na podstawie prędkości peletonu i wiatru bocznego.
  static PelotonShapeType fromSpeedAndWind(double speedKmh, {double crosswindKmh = 0.0}) {
    if (crosswindKmh >= 28.0) {
      return PelotonShapeType.crosswindEchelon;
    }
    if (speedKmh >= 52.0) {
      return PelotonShapeType.strungOutSingleFile;
    }
    if (speedKmh <= 38.0) {
      return PelotonShapeType.broadBunch;
    }
    return PelotonShapeType.standardPack;
  }
}

/// Pozycja kolarza z drużyny gracza w siatce peletonu.
class PlayerPelotonRider {
  final String id;
  final String name;
  final int bibNumber; // Numer startowy (np. 1-8)
  final double lateralOffset; // -1.0 (lewa krawędź) do +1.0 (prawa krawędź)
  final double depthPercent; // 0.0 (czoło peletonu) do 1.0 (ogon grupy)
  final bool isLeader;
  final double currentWatts;
  final double draftingSavingsPercent;

  const PlayerPelotonRider({
    required this.id,
    required this.name,
    required this.bibNumber,
    this.lateralOffset = 0.0,
    this.depthPercent = 0.35,
    this.isLeader = false,
    this.currentWatts = 280.0,
    this.draftingSavingsPercent = 38.0,
  });

  PlayerPelotonRider copyWith({
    String? id,
    String? name,
    int? bibNumber,
    double? lateralOffset,
    double? depthPercent,
    bool? isLeader,
    double? currentWatts,
    double? draftingSavingsPercent,
  }) {
    return PlayerPelotonRider(
      id: id ?? this.id,
      name: name ?? this.name,
      bibNumber: bibNumber ?? this.bibNumber,
      lateralOffset: lateralOffset ?? this.lateralOffset,
      depthPercent: depthPercent ?? this.depthPercent,
      isLeader: isLeader ?? this.isLeader,
      currentWatts: currentWatts ?? this.currentWatts,
      draftingSavingsPercent: draftingSavingsPercent ?? this.draftingSavingsPercent,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'bibNumber': bibNumber,
    'lateralOffset': lateralOffset,
    'depthPercent': depthPercent,
    'isLeader': isLeader,
    'currentWatts': currentWatts,
    'draftingSavingsPercent': draftingSavingsPercent,
  };

  factory PlayerPelotonRider.fromJson(Map<String, dynamic> json) => PlayerPelotonRider(
    id: json['id'] as String,
    name: json['name'] as String,
    bibNumber: (json['bibNumber'] as num).toInt(),
    lateralOffset: (json['lateralOffset'] as num?)?.toDouble() ?? 0.0,
    depthPercent: (json['depthPercent'] as num?)?.toDouble() ?? 0.35,
    isLeader: json['isLeader'] as bool? ?? false,
    currentWatts: (json['currentWatts'] as num?)?.toDouble() ?? 280.0,
    draftingSavingsPercent: (json['draftingSavingsPercent'] as num?)?.toDouble() ?? 38.0,
  );
}

/// Zbliżające się niebezpieczeństwo lub kluczowy element trasy (zakręt, zwężenie, wiatr).
class UpcomingRoadHazard {
  final String title;
  final String description;
  final double distanceMeters;
  final IconData icon;
  final RoadGutterTarget recommendedGutter;
  final Color alertColor;

  const UpcomingRoadHazard({
    required this.title,
    required this.description,
    required this.distanceMeters,
    required this.icon,
    required this.recommendedGutter,
    this.alertColor = AppColors.goldAccent,
  });
}

/// CustomPainter precyzyjnie rysujący przekrój szosy z lotu ptaka, mapę ciepła gęstości peletonu,
/// odkształcenia aerodynamiczne zależne od prędkości oraz 8 kolarzy gracza.
class PelotonHeatmapPainter extends CustomPainter {
  final double pelotonSpeedKmh;
  final double crosswindKmh;
  final double crosswindAngleDeg; // 0 = czołowy, 90 = boczny z prawej, -90 = boczny z lewej
  final double targetLateralOffset; // -1.0 .. 1.0 (rozkaz gracza)
  final List<PlayerPelotonRider> playerRiders;
  final UpcomingRoadHazard? upcomingHazard;
  final String? selectedRiderId;
  final double pulsePhase; // 0.0 .. 1.0 animacji

  PelotonHeatmapPainter({
    required this.pelotonSpeedKmh,
    this.crosswindKmh = 0.0,
    this.crosswindAngleDeg = 0.0,
    required this.targetLateralOffset,
    required this.playerRiders,
    this.upcomingHazard,
    this.selectedRiderId,
    this.pulsePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double roadLeft = size.width * 0.08;
    final double roadRight = size.width * 0.92;
    final double roadWidth = roadRight - roadLeft;
    final double roadHeight = size.height;

    // 1. Rysowanie szosy i poboczy (Road Asphalt & Shoulders)
    _drawRoadBackground(canvas, size, roadLeft, roadRight, roadWidth, roadHeight);

    // 2. Rysowanie Mapy Ciepła Peletonu (Heatmap Density)
    _drawPelotonHeatmap(canvas, roadLeft, roadWidth, roadHeight);

    // 3. Rysowanie linii taktycznej rozkazu gracza (Target Positioning Guideline)
    _drawTargetGuideline(canvas, roadLeft, roadWidth, roadHeight);

    // 4. Rysowanie ostrzeżenia o zakręcie / wietrze (Road Hazard Marker)
    if (upcomingHazard != null) {
      _drawHazardIndicator(canvas, roadLeft, roadWidth, roadHeight);
    }

    // 5. Rysowanie 8 kolarzy drużyny gracza (Player Riders Pins)
    _drawPlayerRiders(canvas, roadLeft, roadWidth, roadHeight);
  }

  void _drawRoadBackground(
    Canvas canvas,
    Size size,
    double roadLeft,
    double roadRight,
    double roadWidth,
    double roadHeight,
  ) {
    // Trawa / pobocze zewnętrzne
    final shoulderPaint = Paint()..color = const Color(0xFF13171D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shoulderPaint);

    // Asfalt szosy
    final asphaltPaint = Paint()..color = const Color(0xFF1E222A);
    final roadRect = Rect.fromLTRB(roadLeft, 0, roadRight, roadHeight);
    canvas.drawRect(roadRect, asphaltPaint);

    // Krawężniki / białe linie krawędziowe (Edge Lines)
    final edgeLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(roadLeft, 0), Offset(roadLeft, roadHeight), edgeLinePaint);
    canvas.drawLine(Offset(roadRight, 0), Offset(roadRight, roadHeight), edgeLinePaint);

    // Przerywana linia środkowa szosy (Center Line)
    final centerLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const double dashHeight = 16.0;
    const double dashSpace = 12.0;
    double startY = 0.0;
    final double roadCenter = roadLeft + roadWidth / 2;

    while (startY < roadHeight) {
      canvas.drawLine(
        Offset(roadCenter, startY),
        Offset(roadCenter, math.min(startY + dashHeight, roadHeight)),
        centerLinePaint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  void _drawPelotonHeatmap(Canvas canvas, double roadLeft, double roadWidth, double roadHeight) {
    // Obliczenie współczynników odkształcenia grupy:
    // Prędkość 30 km/h: szeroka ława (widthFactor ~0.85, lengthFactor ~0.38)
    // Prędkość 60 km/h: długa pojedyncza kreska (widthFactor ~0.22, lengthFactor ~0.90)
    final double speedT = ((pelotonSpeedKmh - 30.0) / 30.0).clamp(0.0, 1.0);
    final double widthFactor = 0.85 - (speedT * 0.63);
    final double lengthFactor = 0.38 + (speedT * 0.54);

    // Przesunięcie środka masy peletonu na wietrze bocznym (Echelon drift)
    double lateralShift = 0.0;
    if (crosswindKmh > 15.0) {
      // Wiatr z prawej spycha na lewy rant, wiatr z lewej na prawy rant
      final angleRad = crosswindAngleDeg * math.pi / 180.0;
      lateralShift = -math.sin(angleRad) * (crosswindKmh / 50.0).clamp(0.0, 0.45);
    }

    final double packCenterX = roadLeft + (roadWidth / 2) + (lateralShift * roadWidth * 0.4);
    final double packCenterY = roadHeight * 0.48;

    final double packWidthRadius = (roadWidth * widthFactor) / 2;
    final double packHeightRadius = (roadHeight * lengthFactor) / 2;

    // Rysowanie 4 warstw gradientu gęstości ciepła (Density Heatmap)
    // 1. Zewnętrzna strefa rozproszenia (Chłodny błękit/turkus)
    final outerAuraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.22),
          const Color(0xFF38BDF8).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCenter(
        center: Offset(packCenterX, packCenterY),
        width: packWidthRadius * 2.4,
        height: packHeightRadius * 2.2,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(packCenterX, packCenterY),
        width: packWidthRadius * 2.4,
        height: packHeightRadius * 2.2,
      ),
      outerAuraPaint,
    );

    // 2. Średnia gęstość grupy (Żółć / Ciepły bursztyn)
    final mediumDensityPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBBF24).withValues(alpha: 0.45),
          const Color(0xFFF59E0B).withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCenter(
        center: Offset(packCenterX, packCenterY),
        width: packWidthRadius * 1.6,
        height: packHeightRadius * 1.5,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(packCenterX, packCenterY),
        width: packWidthRadius * 1.6,
        height: packHeightRadius * 1.5,
      ),
      mediumDensityPaint,
    );

    // 3. Jądro grupy o najwyższej gęstości i osłonie aero (Czerwień / Szkarłat #8E4A49)
    final coreHeatPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFEF4444).withValues(alpha: 0.65),
          const Color(0xFF8E4A49).withValues(alpha: 0.40),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCenter(
        center: Offset(packCenterX, packCenterY + (packHeightRadius * 0.1)),
        width: packWidthRadius * 1.0,
        height: packHeightRadius * 0.9,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(packCenterX, packCenterY + (packHeightRadius * 0.1)),
        width: packWidthRadius * 1.0,
        height: packHeightRadius * 0.9,
      ),
      coreHeatPaint,
    );

    // 4. Kropki kolarzy rywali w tle (Ambient Pack Particles - symulacja 120 kolarzy)
    final ambientRiderPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final math.Random rnd = math.Random(42);

    for (int i = 0; i < 90; i++) {
      final double u = rnd.nextDouble() * 2 - 1;
      final double v = rnd.nextDouble() * 2 - 1;
      if (u * u + v * v <= 1.0) {
        final double rx = packCenterX + (u * packWidthRadius * 0.95);
        final double ry = packCenterY + (v * packHeightRadius * 0.92);

        // Kropka kolarza w peletonie
        canvas.drawCircle(Offset(rx, ry), 1.8, ambientRiderPaint);
      }
    }
  }

  void _drawTargetGuideline(
    Canvas canvas,
    double roadLeft,
    double roadWidth,
    double roadHeight,
  ) {
    // Pozycja X rozkazu gracza: -1.0 (lewa) do +1.0 (prawa)
    final double targetX = roadLeft + ((targetLateralOffset + 1.0) / 2.0 * roadWidth);

    // Linia laserowa wskazująca docelowy korytarz jazdy
    final linePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const double dashH = 8.0;
    const double dashS = 6.0;
    double curY = 0.0;
    while (curY < roadHeight) {
      canvas.drawLine(
        Offset(targetX, curY),
        Offset(targetX, math.min(curY + dashH, roadHeight)),
        linePaint,
      );
      curY += dashH + dashS;
    }

    // Strzałka / wskaźnik na górze korytarza
    final arrowPaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.fill;

    final arrowPath = Path()
      ..moveTo(targetX, 16)
      ..lineTo(targetX - 7, 28)
      ..lineTo(targetX + 7, 28)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawHazardIndicator(
    Canvas canvas,
    double roadLeft,
    double roadWidth,
    double roadHeight,
  ) {
    final hazard = upcomingHazard!;
    final double recX = roadLeft + ((hazard.recommendedGutter.lateralOffset + 1.0) / 2.0 * roadWidth);

    // Pulsujący punkt zalecanego wejścia w zakręt / osłony
    final pulseRadius = 14.0 + (math.sin(pulsePhase * 2 * math.pi) * 3.0);
    final hazardAuraPaint = Paint()
      ..color = hazard.alertColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(recX, 45), pulseRadius, hazardAuraPaint);

    final hazardCorePaint = Paint()
      ..color = hazard.alertColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(recX, 45), 6.0, hazardCorePaint);
  }

  void _drawPlayerRiders(
    Canvas canvas,
    double roadLeft,
    double roadWidth,
    double roadHeight,
  ) {
    for (int i = 0; i < playerRiders.length; i++) {
      final rider = playerRiders[i];

      // Współrzędne kolarza na szosie
      final double riderX = roadLeft + ((rider.lateralOffset + 1.0) / 2.0 * roadWidth);
      final double riderY = roadHeight * rider.depthPercent.clamp(0.08, 0.92);

      final bool isSelected = rider.id == selectedRiderId;
      final Color markerColor = rider.isLeader ? AppColors.goldAccent : const Color(0xFF00E5FF);

      // Poświata wybranego kolarza
      if (isSelected) {
        final selectPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawCircle(Offset(riderX, riderY), 16.0, selectPaint);
      }

      // Pierścień osłony aerodynamicznej (Drafting Ring)
      final double draftingAlpha = (rider.draftingSavingsPercent / 45.0).clamp(0.2, 0.9);
      final draftRingPaint = Paint()
        ..color = AppColors.statusSuccess.withValues(alpha: draftingAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset(riderX, riderY), 11.5, draftRingPaint);

      // Główny dysk kolarza
      final bodyPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(riderX, riderY), 8.5, bodyPaint);

      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(riderX, riderY), 8.5, borderPaint);

      // Numer startowy kolarza (lub gwiazdka lidera)
      final textSpan = TextSpan(
        text: rider.isLeader ? '★' : '${rider.bibNumber}',
        style: TextStyle(
          color: rider.isLeader ? Colors.black : Colors.black87,
          fontSize: rider.isLeader ? 10 : 9,
          fontWeight: FontWeight.w900,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(riderX - (textPainter.width / 2), riderY - (textPainter.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PelotonHeatmapPainter oldDelegate) {
    return oldDelegate.pelotonSpeedKmh != pelotonSpeedKmh ||
        oldDelegate.crosswindKmh != crosswindKmh ||
        oldDelegate.crosswindAngleDeg != crosswindAngleDeg ||
        oldDelegate.targetLateralOffset != targetLateralOffset ||
        oldDelegate.playerRiders != playerRiders ||
        oldDelegate.upcomingHazard != upcomingHazard ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.pulsePhase != pulsePhase;
  }
}

/// Główny widget taktyczny przekroju peletonu w formie siatki ciepła (Peloton Heatmap Grid).
///
/// Pozwala graczowi jednym przeciągnięciem palca lub kursora myszy nakazać całej 8-osobowej
/// drużynie przesunięcie się na lewą lub prawą stronę szosy przed zakrętem bądź rantem wiatrowym.
class PelotonHeatmapPositionWidget extends StatefulWidget {
  /// Aktualna prędkość peletonu [km/h] determinująca jego rozciągnięcie w kreskę vs szeroką ławę.
  final double pelotonSpeedKmh;

  /// Prędkość wiatru bocznego [km/h].
  final double crosswindKmh;

  /// Kąt wiatru bocznego w stopniach [-90 = z lewej, +90 = z prawej].
  final double crosswindAngleDeg;

  /// Lista 8 kolarzy drużyny gracza z ich pozycjami w grupie.
  final List<PlayerPelotonRider> playerRiders;

  /// Opcjonalne zbliżające się zagrożenie (zakręt, zwężenie jezdni, rondo, rant).
  final UpcomingRoadHazard? upcomingHazard;

  /// Callback wywoływany, gdy gracz przeciąga formację w lewo lub prawo [-1.0 .. 1.0].
  final ValueChanged<double>? onTeamGutterChanged;

  /// Callback wywoływany po wybraniu szybkiego presetu.
  final ValueChanged<RoadGutterTarget>? onPresetSelected;

  /// Callback po kliknięciu w konkretnego kolarza.
  final ValueChanged<PlayerPelotonRider>? onRiderTapped;

  /// Domyślne przesunięcie boczne [-1.0 .. 1.0].
  final double initialLateralOffset;

  /// Wysokość widgetu (domyślnie 420 px).
  final double height;

  const PelotonHeatmapPositionWidget({
    super.key,
    this.pelotonSpeedKmh = 44.0,
    this.crosswindKmh = 0.0,
    this.crosswindAngleDeg = 0.0,
    required this.playerRiders,
    this.upcomingHazard,
    this.onTeamGutterChanged,
    this.onPresetSelected,
    this.onRiderTapped,
    this.initialLateralOffset = 0.0,
    this.height = 420.0,
  });

  @override
  State<PelotonHeatmapPositionWidget> createState() => _PelotonHeatmapPositionWidgetState();
}

class _PelotonHeatmapPositionWidgetState extends State<PelotonHeatmapPositionWidget>
    with SingleTickerProviderStateMixin {
  late double _currentLateralOffset;
  String? _selectedRiderId;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _currentLateralOffset = widget.initialLateralOffset.clamp(-1.0, 1.0);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant PelotonHeatmapPositionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLateralOffset != oldWidget.initialLateralOffset) {
      _currentLateralOffset = widget.initialLateralOffset.clamp(-1.0, 1.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleHorizontalPan(Offset localPosition, double width) {
    final double roadLeft = width * 0.08;
    final double roadRight = width * 0.92;
    final double roadWidth = roadRight - roadLeft;

    final double clampedX = localPosition.dx.clamp(roadLeft, roadRight);
    final double normalizedOffset = ((clampedX - roadLeft) / roadWidth * 2.0) - 1.0;

    setState(() {
      _currentLateralOffset = normalizedOffset.clamp(-1.0, 1.0);
    });

    if (widget.onTeamGutterChanged != null) {
      widget.onTeamGutterChanged!(_currentLateralOffset);
    }
  }

  void _applyGutterPreset(RoadGutterTarget preset) {
    setState(() {
      _currentLateralOffset = preset.lateralOffset;
    });

    if (widget.onTeamGutterChanged != null) {
      widget.onTeamGutterChanged!(_currentLateralOffset);
    }
    if (widget.onPresetSelected != null) {
      widget.onPresetSelected!(preset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shapeType = PelotonShapeType.fromSpeedAndWind(
      widget.pelotonSpeedKmh,
      crosswindKmh: widget.crosswindKmh,
    );
    final activeGutter = RoadGutterTarget.fromOffset(_currentLateralOffset);

    // Średnia oszczędność aerodynamiczna zespołu
    final double avgSavings = widget.playerRiders.isNotEmpty
        ? widget.playerRiders.fold<double>(0.0, (s, r) => s + r.draftingSavingsPercent) /
            widget.playerRiders.length
        : 0.0;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Pasek informacyjny (Nagłówek, prędkość, kształt szyku)
          _buildTopHeader(shapeType),
          const SizedBox(height: 8),

          // 2. Alert o zbliżającym się zakręcie / wietrze (jeśli występuje)
          if (widget.upcomingHazard != null) ...[
            _buildHazardBanner(widget.upcomingHazard!),
            const SizedBox(height: 8),
          ],

          // 3. Główna interaktywna mapa ciepła peletonu (Canvas) z obsługą gestów
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (details) {
                    _handleHorizontalPan(details.localPosition, constraints.maxWidth);
                    _detectRiderTap(details.localPosition, constraints.maxWidth, constraints.maxHeight);
                  },
                  onPanStart: (details) => _handleHorizontalPan(details.localPosition, constraints.maxWidth),
                  onPanUpdate: (details) => _handleHorizontalPan(details.localPosition, constraints.maxWidth),
                  onTapUp: (details) {
                    _handleHorizontalPan(details.localPosition, constraints.maxWidth);
                    _detectRiderTap(details.localPosition, constraints.maxWidth, constraints.maxHeight);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return CustomPaint(
                          key: const ValueKey('peloton_heatmap_canvas'),
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: PelotonHeatmapPainter(
                            pelotonSpeedKmh: widget.pelotonSpeedKmh,
                            crosswindKmh: widget.crosswindKmh,
                            crosswindAngleDeg: widget.crosswindAngleDeg,
                            targetLateralOffset: _currentLateralOffset,
                            playerRiders: widget.playerRiders,
                            upcomingHazard: widget.upcomingHazard,
                            selectedRiderId: _selectedRiderId,
                            pulsePhase: _pulseController.value,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // 4. Pasek szybkiego wyboru krawędzi szosy (Gutter Presets)
          _buildGutterPresetBar(activeGutter),

          const SizedBox(height: 8),

          // 5. Pasek telemetrii zespołu (Średni drafting, stan formacji)
          _buildTeamTelemetryFooter(avgSavings, activeGutter),
        ],
      ),
    );
  }

  void _detectRiderTap(Offset localPos, double width, double height) {
    final double roadLeft = width * 0.08;
    final double roadRight = width * 0.92;
    final double roadWidth = roadRight - roadLeft;

    PlayerPelotonRider? closestRider;
    double minDistance = 60.0;

    for (final rider in widget.playerRiders) {
      final double riderX = roadLeft + ((rider.lateralOffset + 1.0) / 2.0 * roadWidth);
      final double riderY = height * rider.depthPercent.clamp(0.08, 0.92);

      final distance = (Offset(riderX, riderY) - localPos).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestRider = rider;
      }
    }

    final selected = closestRider;
    if (selected != null) {
      setState(() {
        _selectedRiderId = selected.id;
      });
      if (widget.onRiderTapped != null) {
        widget.onRiderTapped!(selected);
      }
    }
  }

  Widget _buildTopHeader(PelotonShapeType shapeType) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, color: AppColors.goldAccent, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Przekrój Peletonu (Positioning Grid)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Badge prędkości i szyku
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.pelotonSpeedKmh.round()} km/h',
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.goldAccent, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${shapeType.title}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHazardBanner(UpcomingRoadHazard hazard) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hazard.alertColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hazard.alertColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(hazard.icon, color: hazard.alertColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${hazard.title} (${hazard.distanceMeters.round()}m) – ${hazard.description}',
              style: TextStyle(color: hazard.alertColor, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _applyGutterPreset(hazard.recommendedGutter),
            child: const Text('Zastosuj pozycję', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGutterPresetBar(RoadGutterTarget activeGutter) {
    return Row(
      children: [
        const Text('Rozkaz strony: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RoadGutterTarget.values.map((target) {
                final isSelected = activeGutter == target;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    avatar: Icon(target.icon, size: 13, color: isSelected ? Colors.black : AppColors.goldAccent),
                    label: Text(
                      target.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.goldAccent,
                    backgroundColor: AppColors.surfaceLight,
                    onSelected: (_) => _applyGutterPreset(target),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamTelemetryFooter(double avgSavings, RoadGutterTarget activeGutter) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        // Średnia osłona aerodynamiczna
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 14, color: AppColors.statusSuccess),
            const SizedBox(width: 4),
            Text(
              'Drafting: -${avgSavings.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 11, color: AppColors.statusSuccess, fontWeight: FontWeight.w600),
            ),
          ],
        ),

        // Wskaźnik przeciągania
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Przeciągnij: ${activeGutter.label}',
              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
