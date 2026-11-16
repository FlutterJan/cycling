import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../models/rider/rider_health.dart';

/// Grupy mięśniowe oraz układ nerwowy wizualizowane na diagramie zmęczenia kolarza.
enum BodyFatigueGroup {
  quadriceps,
  calves,
  glutes,
  lumbarSpine,
  centralNervousSystem;

  /// Nazwa grupy w języku polskim.
  String get labelPl {
    switch (this) {
      case BodyFatigueGroup.quadriceps:
        return 'Czworogłowe uda';
      case BodyFatigueGroup.calves:
        return 'Łydki';
      case BodyFatigueGroup.glutes:
        return 'Pośladki';
      case BodyFatigueGroup.lumbarSpine:
        return 'Odcinek lędźwiowy';
      case BodyFatigueGroup.centralNervousSystem:
        return 'Układ nerwowy (CNS)';
    }
  }

  /// Krótki opis biomechaniczny i kolarski danej grupy.
  String get cyclingRoleDescription {
    switch (this) {
      case BodyFatigueGroup.quadriceps:
        return 'Główny generator mocy w fazie pchnięcia (12–5 na tarczy zegara), szczególnie obciążony na podjazdach i w sprintach.';
      case BodyFatigueGroup.calves:
        return 'Stabilizacja stawu skokowego i transfer momentu obrotowego w dolnej fazie obrotu korby oraz podczas jazdy na stojąco.';
      case BodyFatigueGroup.glutes:
        return 'Napęd biodrowy przy wysokiej kadencji, w pozycji aerodynamicznej TT oraz podczas ataków w górach.';
      case BodyFatigueGroup.lumbarSpine:
        return 'Stabilizacja tułowia w głębokim chwycie dolnym i ochrona przed utratą mocy na sektorach bruku.';
      case BodyFatigueGroup.centralNervousSystem:
        return 'Gotowość nerwowo-mięśniowa, czas reakcji w peletonie, rekrutacja włókien szybkokurczliwych i tolerancja bólu.';
    }
  }
}

/// Poziom zmęczenia danej grupy mięśniowej.
enum FatigueSeverityLevel {
  fresh,
  moderate,
  high,
  critical;

  String get labelPl {
    switch (this) {
      case FatigueSeverityLevel.fresh:
        return 'Świeży';
      case FatigueSeverityLevel.moderate:
        return 'Obciążony';
      case FatigueSeverityLevel.high:
        return 'Zmęczony';
      case FatigueSeverityLevel.critical:
        return 'Przeciążony';
    }
  }

  static FatigueSeverityLevel fromValue(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped < 0.30) return FatigueSeverityLevel.fresh;
    if (clamped < 0.58) return FatigueSeverityLevel.moderate;
    if (clamped < 0.80) return FatigueSeverityLevel.high;
    return FatigueSeverityLevel.critical;
  }
}

/// Profil zmęczenia mięśniowego oraz układu nerwowego kolarza (wartości 0.0–1.0).
@immutable
class RiderMuscleFatigueProfile {
  final double quadriceps;
  final double calves;
  final double glutes;
  final double lumbarSpine;
  final double centralNervousSystem;

  const RiderMuscleFatigueProfile({
    required this.quadriceps,
    required this.calves,
    required this.glutes,
    required this.lumbarSpine,
    required this.centralNervousSystem,
  });

  /// Profil w pełni wypoczętego kolarza.
  const RiderMuscleFatigueProfile.fresh()
      : quadriceps = 0.08,
        calves = 0.06,
        glutes = 0.07,
        lumbarSpine = 0.05,
        centralNervousSystem = 0.09;

  /// Wylicza profil zmęczenia mięśni i CNS na podstawie modelu [RiderHealth].
  factory RiderMuscleFatigueProfile.fromRiderHealth(
    RiderHealth health, {
    double stageIntensityBias = 0.0,
  }) {
    final tsb = health.trainingStressBalance;
    // TSB od +20 (świeży) do -35 (skrajne zmęczenie)
    final baseLoad = ((-tsb + 15.0) / 50.0).clamp(0.05, 0.92);
    final atlRatio = (health.acuteTrainingLoad / 120.0).clamp(0.0, 1.0);
    final bias = stageIntensityBias.clamp(-0.2, 0.25);

    double quads = (baseLoad * 0.95 + atlRatio * 0.12 + bias).clamp(0.0, 1.0);
    double calves = (baseLoad * 0.82 + atlRatio * 0.10 + bias * 0.8).clamp(0.0, 1.0);
    double glutes = (baseLoad * 0.88 + atlRatio * 0.08 + bias * 0.9).clamp(0.0, 1.0);
    double lumbar = (baseLoad * 0.72 + atlRatio * 0.10 + bias * 0.6).clamp(0.0, 1.0);
    double cns = (baseLoad * 0.78 + atlRatio * 0.16 + bias * 0.7).clamp(0.0, 1.0);

    final injury = health.currentInjury;
    if (injury != null) {
      switch (injury.type) {
        case InjuryType.kneeTendinitis:
          quads = math.max(quads, 0.86);
          calves = math.max(calves, 0.72);
        case InjuryType.muscleTear:
          quads = math.max(quads, 0.92);
          glutes = math.max(glutes, 0.85);
        case InjuryType.concussion:
          cns = math.max(cns, 0.95);
        case InjuryType.clavicleFracture:
        case InjuryType.wristFracture:
          lumbar = math.max(lumbar, 0.68);
          cns = math.max(cns, 0.74);
        case InjuryType.roadRash:
          cns = math.max(cns, 0.62);
          glutes = math.max(glutes, 0.65);
      }
    }

    if (health.currentIllness != null && health.currentIllness!.isNotEmpty) {
      cns = (cns + 0.22).clamp(0.0, 1.0);
    }

    return RiderMuscleFatigueProfile(
      quadriceps: quads,
      calves: calves,
      glutes: glutes,
      lumbarSpine: lumbar,
      centralNervousSystem: cns,
    );
  }

  /// Zwraca poziom zmęczenia (0.0–1.0) dla wskazanej grupy.
  double valueFor(BodyFatigueGroup group) {
    switch (group) {
      case BodyFatigueGroup.quadriceps:
        return quadriceps.clamp(0.0, 1.0);
      case BodyFatigueGroup.calves:
        return calves.clamp(0.0, 1.0);
      case BodyFatigueGroup.glutes:
        return glutes.clamp(0.0, 1.0);
      case BodyFatigueGroup.lumbarSpine:
        return lumbarSpine.clamp(0.0, 1.0);
      case BodyFatigueGroup.centralNervousSystem:
        return centralNervousSystem.clamp(0.0, 1.0);
    }
  }

  /// Ważony wskaźnik ogólnego zmęczenia (0.0–1.0).
  double get overallFatigue =>
      (quadriceps * 0.28 +
              glutes * 0.22 +
              calves * 0.16 +
              lumbarSpine * 0.14 +
              centralNervousSystem * 0.20)
          .clamp(0.0, 1.0);

  /// Grupa o najwyższym aktualnym obciążeniu.
  BodyFatigueGroup get mostFatiguedGroup {
    BodyFatigueGroup top = BodyFatigueGroup.quadriceps;
    double maxVal = -1.0;
    for (final group in BodyFatigueGroup.values) {
      final val = valueFor(group);
      if (val > maxVal) {
        maxVal = val;
        top = group;
      }
    }
    return top;
  }

  /// Szacowany czas pełnej regeneracji w godzinach.
  int get estimatedRecoveryHours => (overallFatigue * 48.0).round().clamp(2, 72);

  RiderMuscleFatigueProfile copyWith({
    double? quadriceps,
    double? calves,
    double? glutes,
    double? lumbarSpine,
    double? centralNervousSystem,
  }) {
    return RiderMuscleFatigueProfile(
      quadriceps: quadriceps ?? this.quadriceps,
      calves: calves ?? this.calves,
      glutes: glutes ?? this.glutes,
      lumbarSpine: lumbarSpine ?? this.lumbarSpine,
      centralNervousSystem: centralNervousSystem ?? this.centralNervousSystem,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderMuscleFatigueProfile &&
        other.quadriceps == quadriceps &&
        other.calves == calves &&
        other.glutes == glutes &&
        other.lumbarSpine == lumbarSpine &&
        other.centralNervousSystem == centralNervousSystem;
  }

  @override
  int get hashCode => Object.hash(
        quadriceps,
        calves,
        glutes,
        lumbarSpine,
        centralNervousSystem,
      );
}

/// Anatomiczny painter diagramu zmęczenia mięśniowego kolarza (`RiderFatigueBodyHeatmapPainter`).
///
/// Rysuje dwustronną sylwetkę kolarza (rzut przedni i tylny) z podświetleniem
/// grup mięśniowych: czworogłowych uda, łydek, pośladków, odcinka lędźwiowego
/// oraz osi układu nerwowego (CNS) w skali barwnej od zieleni do ciemnoczerwonego.
class RiderFatigueBodyHeatmapPainter extends CustomPainter {
  /// Profil zmęczenia kolarza (0.0–1.0 dla każdej grupy).
  final RiderMuscleFatigueProfile profile;

  /// Aktualnie wybrana (aktywna) grupa mięśniowa.
  final BodyFatigueGroup? selectedGroup;

  /// Grupa nad którą znajduje się kursor.
  final BodyFatigueGroup? hoveredGroup;

  /// Czy diagram jest aktywny (stan disabled przygasza paletę).
  final bool isEnabled;

  /// Faza pulsacji (0.0–1.0) dla przeciążonych mięśni i impulsów CNS.
  final double pulsePhase;

  /// Czy wyświetlać etykiety rzutów `PRZÓD` / `TYŁ` i linie pomocnicze.
  final bool showAnatomicalGuides;

  const RiderFatigueBodyHeatmapPainter({
    required this.profile,
    this.selectedGroup,
    this.hoveredGroup,
    this.isEnabled = true,
    this.pulsePhase = 0.0,
    this.showAnatomicalGuides = true,
  });

  /// Ciemnoczerwony kolor skrajnego przeciążenia mięśniowego.
  static const Color deepCrimson = Color(0xFF7F1D1D);

  /// Przelicza znormalizowany poziom zmęczenia [level] (0.0–1.0) na kolor
  /// płynnie przechodzący od zieleni (`AppColors.statusSuccess`) przez bursztyn
  /// (`AppColors.amberWarning`) i czerwień (`AppColors.crimsonAlert`) do ciemnoczerwonego.
  static Color fatigueColorForLevel(double level, {bool isEnabled = true}) {
    final t = level.clamp(0.0, 1.0);
    final Color base;
    if (t <= 0.0) {
      base = AppColors.statusSuccess;
    } else if (t >= 1.0) {
      base = deepCrimson;
    } else if (t < 0.35) {
      final local = t / 0.35;
      base = Color.lerp(AppColors.statusSuccess, AppColors.amberWarning, local)!;
    } else if (t < 0.70) {
      final local = (t - 0.35) / 0.35;
      base = Color.lerp(AppColors.amberWarning, AppColors.crimsonAlert, local)!;
    } else {
      final local = (t - 0.70) / 0.30;
      base = Color.lerp(AppColors.crimsonAlert, deepCrimson, local)!;
    }
    if (!isEnabled) {
      return Color.lerp(base, AppColors.textSecondary, 0.55)!.withValues(alpha: 0.45);
    }
    return base;
  }

  /// Wykrywa grupę mięśniową pod współrzędnymi [localPosition] na płótnie o rozmiarze [size].
  static BodyFatigueGroup? hitTestGroup(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) return null;
    final layout = _HeatmapLayoutGeometry.compute(size);
    final regions = _buildHitRegions(layout);

    // Najpierw sprawdzamy CNS (najmniejsza, centralna oś), potem mięśnie.
    for (final entry in regions.entries) {
      for (final path in entry.value) {
        if (path.contains(localPosition)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static Map<BodyFatigueGroup, List<Path>> _buildHitRegions(
    _HeatmapLayoutGeometry layout,
  ) {
    final front = layout.frontCenter;
    final back = layout.backCenter;
    final s = layout.scale;

    return {
      BodyFatigueGroup.centralNervousSystem: [
        _cnsHeadPath(front, s),
        _cnsHeadPath(back, s),
        _cnsSpineHitPath(back, s),
      ],
      BodyFatigueGroup.quadriceps: [
        _quadPath(front, s, isLeft: true),
        _quadPath(front, s, isLeft: false),
      ],
      BodyFatigueGroup.calves: [
        _calfAnteriorPath(front, s, isLeft: true),
        _calfAnteriorPath(front, s, isLeft: false),
        _calfPosteriorPath(back, s, isLeft: true),
        _calfPosteriorPath(back, s, isLeft: false),
      ],
      BodyFatigueGroup.glutes: [
        _glutePath(back, s, isLeft: true),
        _glutePath(back, s, isLeft: false),
      ],
      BodyFatigueGroup.lumbarSpine: [
        _lumbarPath(back, s),
      ],
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 20 || size.height < 20) return;

    final layout = _HeatmapLayoutGeometry.compute(size);

    if (showAnatomicalGuides) {
      _drawDiagnosticBackdropGrid(canvas, size, layout);
    }

    // 1. Rzut przedni (Przód) — Czworogłowe uda, łydki boczne, projekcja CNS
    _drawCyclistSilhouette(canvas, layout.frontCenter, layout.scale, isPosterior: false);
    _drawAnteriorAnatomicalLines(canvas, layout.frontCenter, layout.scale);

    // 2. Rzut tylny (Tył) — Pośladki, odcinek lędźwiowy, łydki tylne, rdzeń CNS
    _drawCyclistSilhouette(canvas, layout.backCenter, layout.scale, isPosterior: true);
    _drawPosteriorAnatomicalLines(canvas, layout.backCenter, layout.scale);

    // 3. Warstwy ciepła grup mięśniowych
    _paintMuscleGroup(
      canvas,
      BodyFatigueGroup.quadriceps,
      [
        _quadPath(layout.frontCenter, layout.scale, isLeft: true),
        _quadPath(layout.frontCenter, layout.scale, isLeft: false),
      ],
    );

    _paintMuscleGroup(
      canvas,
      BodyFatigueGroup.calves,
      [
        _calfAnteriorPath(layout.frontCenter, layout.scale, isLeft: true),
        _calfAnteriorPath(layout.frontCenter, layout.scale, isLeft: false),
        _calfPosteriorPath(layout.backCenter, layout.scale, isLeft: true),
        _calfPosteriorPath(layout.backCenter, layout.scale, isLeft: false),
      ],
    );

    _paintMuscleGroup(
      canvas,
      BodyFatigueGroup.glutes,
      [
        _glutePath(layout.backCenter, layout.scale, isLeft: true),
        _glutePath(layout.backCenter, layout.scale, isLeft: false),
      ],
    );

    _paintMuscleGroup(
      canvas,
      BodyFatigueGroup.lumbarSpine,
      [_lumbarPath(layout.backCenter, layout.scale)],
    );

    _paintCnsNeuralSystem(canvas, layout);

    if (showAnatomicalGuides) {
      _drawViewLabels(canvas, layout);
    }
  }

  void _drawDiagnosticBackdropGrid(
    Canvas canvas,
    Size size,
    _HeatmapLayoutGeometry layout,
  ) {
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: isEnabled ? 0.28 : 0.12)
      ..strokeWidth = 0.75;

    const step = 22.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Subtelny krąg telemetryczny pod obiema sylwetkami
    final padPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: isEnabled ? 0.14 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (final centerX in [layout.frontCenter.dx, layout.backCenter.dx]) {
      final footY = layout.frontCenter.dy + 132 * layout.scale;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, footY),
          width: 82 * layout.scale,
          height: 14 * layout.scale,
        ),
        padPaint,
      );
    }
  }

  void _drawCyclistSilhouette(
    Canvas canvas,
    Offset center,
    double s, {
    required bool isPosterior,
  }) {
    final bodyPath = _silhouettePath(center, s);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.surfaceLight.withValues(alpha: isEnabled ? 0.92 : 0.45),
          AppColors.surface.withValues(alpha: isEnabled ? 0.96 : 0.50),
        ],
      ).createShader(bodyPath.getBounds());

    final strokePaint = Paint()
      ..color = (isPosterior ? AppColors.cardBorder : AppColors.textSecondary.withValues(alpha: 0.42))
          .withValues(alpha: isEnabled ? 0.85 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(bodyPath, fillPaint);
    canvas.drawPath(bodyPath, strokePaint);
  }

  void _drawAnteriorAnatomicalLines(Canvas canvas, Offset c, double s) {
    final guidePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: isEnabled ? 0.16 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // Linia środkowa mostka i brzucha
    canvas.drawLine(
      Offset(c.dx, c.dy - 88 * s),
      Offset(c.dx, c.dy - 14 * s),
      guidePaint,
    );
    // Łuk klatki piersiowej
    final pecLeft = Path()
      ..moveTo(c.dx - 2 * s, c.dy - 80 * s)
      ..quadraticBezierTo(c.dx - 18 * s, c.dy - 78 * s, c.dx - 24 * s, c.dy - 64 * s);
    final pecRight = Path()
      ..moveTo(c.dx + 2 * s, c.dy - 80 * s)
      ..quadraticBezierTo(c.dx + 18 * s, c.dy - 78 * s, c.dx + 24 * s, c.dy - 64 * s);
    canvas.drawPath(pecLeft, guidePaint);
    canvas.drawPath(pecRight, guidePaint);

    // Stawy kolanowe
    for (final sign in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(c.dx + sign * 15.5 * s, c.dy + 60 * s),
        4.2 * s,
        guidePaint,
      );
    }
  }

  void _drawPosteriorAnatomicalLines(Canvas canvas, Offset c, double s) {
    final guidePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: isEnabled ? 0.16 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // Łopatki
    for (final sign in [-1.0, 1.0]) {
      final scapula = Path()
        ..moveTo(c.dx + sign * 8 * s, c.dy - 82 * s)
        ..quadraticBezierTo(
          c.dx + sign * 24 * s,
          c.dy - 72 * s,
          c.dx + sign * 14 * s,
          c.dy - 54 * s,
        );
      canvas.drawPath(scapula, guidePaint);
    }
  }

  void _paintMuscleGroup(
    Canvas canvas,
    BodyFatigueGroup group,
    List<Path> paths,
  ) {
    final level = profile.valueFor(group);
    final color = fatigueColorForLevel(level, isEnabled: isEnabled);
    final isSelected = selectedGroup == group;
    final isHovered = hoveredGroup == group;

    // Pulsacja dla wysokiego zmęczenia (>= 0.72)
    final pulseBoost = (level >= 0.72 && isEnabled)
        ? (0.14 * (0.5 + 0.5 * math.sin(pulsePhase * math.pi * 2)))
        : 0.0;

    for (final path in paths) {
      final bounds = path.getBounds();

      // Zewnętrzna poświata termiczna
      if (isEnabled && (level > 0.25 || isSelected || isHovered)) {
        final glowPaint = Paint()
          ..color = color.withValues(
            alpha: (0.28 + level * 0.25 + pulseBoost + (isSelected ? 0.22 : 0.0))
                .clamp(0.0, 0.85),
          )
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            isSelected || isHovered ? 9.0 : 5.5,
          );
        canvas.drawPath(path, glowPaint);
      }

      // Wypełnienie gradientowe grupy mięśniowej
      final fillPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Color.lerp(color, Colors.white, isSelected ? 0.22 : 0.10)!
                .withValues(alpha: isEnabled ? (0.86 + pulseBoost).clamp(0.0, 1.0) : 0.42),
            color.withValues(alpha: isEnabled ? 0.68 : 0.30),
          ],
        ).createShader(bounds);

      canvas.drawPath(path, fillPaint);

      // Włókna mięśniowe (subtelne prążkowanie dla realizmu anatomicznego)
      _drawMuscleFiberStriations(canvas, path, bounds, color);

      // Obrys interaktywny (hover / active)
      final borderPaint = Paint()
        ..color = isSelected
            ? AppColors.goldAccent
            : isHovered
                ? AppColors.textPrimary.withValues(alpha: 0.90)
                : color.withValues(alpha: isEnabled ? 0.90 : 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected
            ? 2.1
            : isHovered
                ? 1.7
                : 1.0;
      canvas.drawPath(path, borderPaint);
    }
  }

  void _drawMuscleFiberStriations(
    Canvas canvas,
    Path clipPath,
    Rect bounds,
    Color baseColor,
  ) {
    if (bounds.width < 4 || bounds.height < 6) return;
    canvas.save();
    canvas.clipPath(clipPath);
    final fiberPaint = Paint()
      ..color = Colors.black.withValues(alpha: isEnabled ? 0.16 : 0.08)
      ..strokeWidth = 0.7;

    final step = math.max(3.5, bounds.height / 6.0);
    for (double y = bounds.top + step * 0.5; y < bounds.bottom; y += step) {
      canvas.drawLine(
        Offset(bounds.left, y),
        Offset(bounds.right, y + step * 0.35),
        fiberPaint,
      );
    }
    canvas.restore();
  }

  void _paintCnsNeuralSystem(Canvas canvas, _HeatmapLayoutGeometry layout) {
    final level = profile.valueFor(BodyFatigueGroup.centralNervousSystem);
    final color = fatigueColorForLevel(level, isEnabled: isEnabled);
    final isSelected = selectedGroup == BodyFatigueGroup.centralNervousSystem;
    final isHovered = hoveredGroup == BodyFatigueGroup.centralNervousSystem;
    final s = layout.scale;

    final pulse = isEnabled ? (0.5 + 0.5 * math.sin(pulsePhase * math.pi * 2)) : 0.0;

    // 1. Oś mózgowa w obu rzutach
    for (final center in [layout.frontCenter, layout.backCenter]) {
      final headPath = _cnsHeadPath(center, s);
      if (isEnabled) {
        canvas.drawPath(
          headPath,
          Paint()
            ..color = color.withValues(alpha: 0.35 + pulse * 0.18)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 10.0 : 6.0),
        );
      }

      canvas.drawPath(
        headPath,
        Paint()
          ..color = color.withValues(alpha: isEnabled ? 0.85 : 0.40)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        headPath,
        Paint()
          ..color = isSelected
              ? AppColors.goldAccent
              : isHovered
                  ? AppColors.textPrimary
                  : color
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 : (isHovered ? 1.6 : 1.0),
      );
    }

    // 2. Rdzeń kręgowy i rozgałęzienia nerwowe na rzucie tylnym
    final back = layout.backCenter;
    final spineTop = Offset(back.dx, back.dy - 102 * s);
    final spineBottom = Offset(back.dx, back.dy - 14 * s);

    if (isEnabled) {
      canvas.drawLine(
        spineTop,
        spineBottom,
        Paint()
          ..color = color.withValues(alpha: 0.40 + pulse * 0.20)
          ..strokeWidth = (isSelected ? 7.5 : 5.0) * s
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
      );
    }

    canvas.drawLine(
      spineTop,
      spineBottom,
      Paint()
        ..color = isSelected
            ? AppColors.goldAccent
            : Color.lerp(color, Colors.white, 0.25)!
        ..strokeWidth = (isSelected ? 2.8 : 2.1) * s
        ..strokeCap = StrokeCap.round,
    );

    // Węzły synaptyczne wzdłuż kręgosłupa
    const nodeFractions = [0.15, 0.36, 0.58, 0.80];
    for (final f in nodeFractions) {
      final ny = spineTop.dy + (spineBottom.dy - spineTop.dy) * f;
      final nodeCenter = Offset(back.dx, ny);
      canvas.drawCircle(
        nodeCenter,
        (isSelected ? 3.2 : 2.3) * s,
        Paint()..color = isSelected ? AppColors.goldAccent : Colors.white.withValues(alpha: isEnabled ? 0.9 : 0.4),
      );
      // Krótkie wypustki nerwowe
      final nervePaint = Paint()
        ..color = color.withValues(alpha: isEnabled ? 0.65 : 0.3)
        ..strokeWidth = 0.9 * s;
      canvas.drawLine(
        nodeCenter,
        Offset(back.dx - 11 * s, ny + 4 * s),
        nervePaint,
      );
      canvas.drawLine(
        nodeCenter,
        Offset(back.dx + 11 * s, ny + 4 * s),
        nervePaint,
      );
    }
  }

  void _drawViewLabels(Canvas canvas, _HeatmapLayoutGeometry layout) {
    final style = TextStyle(
      fontFamily: 'Inter',
      fontSize: math.max(9.5, 10.5 * layout.scale.clamp(0.8, 1.15)),
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
      color: AppColors.textSecondary.withValues(alpha: isEnabled ? 0.85 : 0.45),
    );

    for (final entry in {
      'PRZÓD': layout.frontCenter.dx,
      'TYŁ': layout.backCenter.dx,
    }.entries) {
      final tp = TextPainter(
        text: TextSpan(text: entry.key, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(entry.value - tp.width / 2, layout.labelTopY),
      );
    }
  }

  // ===========================================================================
  // Ścieżki wektorowe anatomii kolarza (skalowane względem [c] i [s])
  // ===========================================================================

  static Path _silhouettePath(Offset c, double s) {
    return Path()
      // Głowa i szyja
      ..addOval(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - 118 * s),
          width: 24 * s,
          height: 28 * s,
        ),
      )
      // Tułów, barki, ramiona, biodra i nogi
      ..moveTo(c.dx - 7 * s, c.dy - 104 * s)
      ..lineTo(c.dx - 31 * s, c.dy - 95 * s) // lewy bark
      ..quadraticBezierTo(c.dx - 40 * s, c.dy - 88 * s, c.dx - 42 * s, c.dy - 55 * s) // ramię
      ..lineTo(c.dx - 46 * s, c.dy - 12 * s) // przedramię / dłoń
      ..lineTo(c.dx - 37 * s, c.dy - 10 * s)
      ..lineTo(c.dx - 30 * s, c.dy - 58 * s) // pacha
      ..lineTo(c.dx - 23 * s, c.dy - 22 * s) // talia
      ..quadraticBezierTo(c.dx - 28 * s, c.dy - 2 * s, c.dx - 27 * s, c.dy + 16 * s) // biodro
      ..lineTo(c.dx - 23 * s, c.dy + 58 * s) // udo zewnętrzne
      ..lineTo(c.dx - 21 * s, c.dy + 95 * s) // łydka zewnętrzna
      ..lineTo(c.dx - 17 * s, c.dy + 126 * s) // kostka
      ..lineTo(c.dx - 22 * s, c.dy + 134 * s) // stopa
      ..lineTo(c.dx - 9 * s, c.dy + 134 * s)
      ..lineTo(c.dx - 9 * s, c.dy + 100 * s)
      ..lineTo(c.dx - 6 * s, c.dy + 58 * s) // kolano wewnętrzne
      ..lineTo(c.dx - 3 * s, c.dy + 14 * s) // krocze
      ..lineTo(c.dx + 3 * s, c.dy + 14 * s)
      ..lineTo(c.dx + 6 * s, c.dy + 58 * s)
      ..lineTo(c.dx + 9 * s, c.dy + 100 * s)
      ..lineTo(c.dx + 9 * s, c.dy + 134 * s)
      ..lineTo(c.dx + 22 * s, c.dy + 134 * s)
      ..lineTo(c.dx + 17 * s, c.dy + 126 * s)
      ..lineTo(c.dx + 21 * s, c.dy + 95 * s)
      ..lineTo(c.dx + 23 * s, c.dy + 58 * s)
      ..quadraticBezierTo(c.dx + 28 * s, c.dy - 2 * s, c.dx + 27 * s, c.dy + 16 * s)
      ..lineTo(c.dx + 23 * s, c.dy - 22 * s)
      ..lineTo(c.dx + 30 * s, c.dy - 58 * s)
      ..lineTo(c.dx + 37 * s, c.dy - 10 * s)
      ..lineTo(c.dx + 46 * s, c.dy - 12 * s)
      ..lineTo(c.dx + 42 * s, c.dy - 55 * s)
      ..quadraticBezierTo(c.dx + 40 * s, c.dy - 88 * s, c.dx + 31 * s, c.dy - 95 * s)
      ..lineTo(c.dx + 7 * s, c.dy - 104 * s)
      ..close();
  }

  static Path _quadPath(Offset c, double s, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(c.dx + sign * 7 * s, c.dy + 14 * s)
      ..quadraticBezierTo(
        c.dx + sign * 24 * s,
        c.dy + 18 * s,
        c.dx + sign * 21 * s,
        c.dy + 52 * s,
      )
      ..quadraticBezierTo(
        c.dx + sign * 14 * s,
        c.dy + 57 * s,
        c.dx + sign * 8 * s,
        c.dy + 51 * s,
      )
      ..quadraticBezierTo(
        c.dx + sign * 5 * s,
        c.dy + 34 * s,
        c.dx + sign * 7 * s,
        c.dy + 14 * s,
      )
      ..close();
  }

  static Path _calfAnteriorPath(Offset c, double s, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(c.dx + sign * 18 * s, c.dy + 68 * s)
      ..quadraticBezierTo(
        c.dx + sign * 23 * s,
        c.dy + 82 * s,
        c.dx + sign * 18 * s,
        c.dy + 104 * s,
      )
      ..lineTo(c.dx + sign * 14 * s, c.dy + 102 * s)
      ..quadraticBezierTo(
        c.dx + sign * 16 * s,
        c.dy + 82 * s,
        c.dx + sign * 14 * s,
        c.dy + 68 * s,
      )
      ..close();
  }

  static Path _calfPosteriorPath(Offset c, double s, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(c.dx + sign * 10 * s, c.dy + 66 * s)
      ..quadraticBezierTo(
        c.dx + sign * 22 * s,
        c.dy + 76 * s,
        c.dx + sign * 17 * s,
        c.dy + 104 * s,
      )
      ..lineTo(c.dx + sign * 11 * s, c.dy + 104 * s)
      ..quadraticBezierTo(
        c.dx + sign * 8 * s,
        c.dy + 80 * s,
        c.dx + sign * 10 * s,
        c.dy + 66 * s,
      )
      ..close();
  }

  static Path _glutePath(Offset c, double s, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;
    return Path()
      ..moveTo(c.dx + sign * 2 * s, c.dy - 10 * s)
      ..quadraticBezierTo(
        c.dx + sign * 24 * s,
        c.dy - 8 * s,
        c.dx + sign * 24 * s,
        c.dy + 12 * s,
      )
      ..quadraticBezierTo(
        c.dx + sign * 12 * s,
        c.dy + 18 * s,
        c.dx + sign * 2 * s,
        c.dy + 11 * s,
      )
      ..close();
  }

  static Path _lumbarPath(Offset c, double s) {
    return Path()
      ..moveTo(c.dx, c.dy - 46 * s)
      ..quadraticBezierTo(c.dx - 16 * s, c.dy - 30 * s, c.dx - 14 * s, c.dy - 14 * s)
      ..lineTo(c.dx, c.dy - 10 * s)
      ..lineTo(c.dx + 14 * s, c.dy - 14 * s)
      ..quadraticBezierTo(c.dx + 16 * s, c.dy - 30 * s, c.dx, c.dy - 46 * s)
      ..close();
  }

  static Path _cnsHeadPath(Offset c, double s) {
    return Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - 120 * s),
          width: 14 * s,
          height: 15 * s,
        ),
      );
  }

  static Path _cnsSpineHitPath(Offset c, double s) {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(c.dx, c.dy - 58 * s),
            width: 14 * s,
            height: 90 * s,
          ),
          Radius.circular(6 * s),
        ),
      );
  }

  @override
  bool shouldRepaint(covariant RiderFatigueBodyHeatmapPainter oldDelegate) {
    return oldDelegate.profile != profile ||
        oldDelegate.selectedGroup != selectedGroup ||
        oldDelegate.hoveredGroup != hoveredGroup ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.showAnatomicalGuides != showAnatomicalGuides;
  }
}

class _HeatmapLayoutGeometry {
  final Offset frontCenter;
  final Offset backCenter;
  final double scale;
  final double labelTopY;

  const _HeatmapLayoutGeometry({
    required this.frontCenter,
    required this.backCenter,
    required this.scale,
    required this.labelTopY,
  });

  factory _HeatmapLayoutGeometry.compute(Size size) {
    // Sylwetka mieści się w zakresie Y: [-136, +140] -> 276 jednostek wysokości
    // Szerokość jednej sylwetki: ~96 jednostek, dwie obok siebie: ~215 jednostek
    final scaleByHeight = (size.height - 26) / 276.0;
    final scaleByWidth = (size.width - 24) / 225.0;
    final scale = math.min(scaleByHeight, scaleByWidth).clamp(0.45, 2.2);

    final centerY = size.height * 0.52;
    final separation = math.min(size.width * 0.25, 62.0 * scale + 28.0);
    final midX = size.width * 0.5;

    return _HeatmapLayoutGeometry(
      frontCenter: Offset(midX - separation, centerY),
      backCenter: Offset(midX + separation, centerY),
      scale: scale,
      labelTopY: math.max(6.0, centerY - 144 * scale),
    );
  }
}

/// Kompletny, responsywny widżet karty diagramu zmęczenia mięśniowego kolarza.
///
/// Obsługuje interakcję myszą (hover, kliknięcie bezpośrednio na mięśnie lub listę),
/// nawigację klawiaturą (`Tab`, strzałki, `Enter`/`Space`), stan wyłączony (`enabled: false`)
/// oraz responsywny układ `LayoutBuilder` dla `390x844`, `1024x768` i `1600x900`.
class RiderFatigueBodyHeatmapWidget extends StatefulWidget {
  final RiderMuscleFatigueProfile profile;
  final String? riderName;
  final BodyFatigueGroup? initialSelectedGroup;
  final ValueChanged<BodyFatigueGroup>? onGroupSelected;
  final bool enabled;

  const RiderFatigueBodyHeatmapWidget({
    super.key,
    required this.profile,
    this.riderName,
    this.initialSelectedGroup,
    this.onGroupSelected,
    this.enabled = true,
  });

  @override
  State<RiderFatigueBodyHeatmapWidget> createState() =>
      _RiderFatigueBodyHeatmapWidgetState();
}

class _RiderFatigueBodyHeatmapWidgetState
    extends State<RiderFatigueBodyHeatmapWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  BodyFatigueGroup? _selectedGroup;
  BodyFatigueGroup? _hoveredGroup;
  BodyFatigueGroup? _focusedGroup;
  Size _lastCanvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _selectedGroup =
        widget.initialSelectedGroup ?? widget.profile.mostFatiguedGroup;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.enabled) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RiderFatigueBodyHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _selectGroup(BodyFatigueGroup group) {
    if (!widget.enabled) return;
    setState(() {
      _selectedGroup = group;
    });
    widget.onGroupSelected?.call(group);
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = _selectedGroup ?? widget.profile.mostFatiguedGroup;
    final activeLevel = widget.profile.valueFor(activeGroup);
    final activeSeverity = FatigueSeverityLevel.fromValue(activeLevel);
    final activeColor = RiderFatigueBodyHeatmapPainter.fatigueColorForLevel(
      activeLevel,
      isEnabled: widget.enabled,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: widget.enabled ? 1.0 : 0.58,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 540;
            final isDesktopWide = constraints.maxWidth >= 820;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 14),
                if (isCompact) ...[
                  _buildInteractiveDiagram(height: 280),
                  const SizedBox(height: 14),
                  _buildGroupList(),
                  const SizedBox(height: 12),
                  _buildSelectedGroupBanner(
                    activeGroup,
                    activeLevel,
                    activeSeverity,
                    activeColor,
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isDesktopWide ? 5 : 6,
                        child: _buildInteractiveDiagram(
                          height: isDesktopWide ? 340 : 300,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: isDesktopWide ? 6 : 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildGroupList(),
                            const SizedBox(height: 12),
                            _buildSelectedGroupBanner(
                              activeGroup,
                              activeLevel,
                              activeSeverity,
                              activeColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _buildHeatmapLegend(isCompact),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final overallPct = (widget.profile.overallFatigue * 100).round();
    final overallColor = RiderFatigueBodyHeatmapPainter.fatigueColorForLevel(
      widget.profile.overallFatigue,
      isEnabled: widget.enabled,
    );

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: overallColor.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: overallColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Obciążenie: $overallPct%  •  Regeneracja ~${widget.profile.estimatedRecoveryHours}h',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.riderName != null
                  ? 'Mapa Zmęczenia — ${widget.riderName}'
                  : 'Anatomiczna Mapa Zmęczenia Mięśniowego',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 15 : 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Diagnostyka biomechaniczna grup napędowych i układu nerwowego (CNS)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        badge,
      ],
    );
  }

  Widget _buildInteractiveDiagram({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          _lastCanvasSize = Size(box.maxWidth, box.maxHeight);
          return MouseRegion(
            cursor: widget.enabled && _hoveredGroup != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onHover: widget.enabled
                ? (event) {
                    final hit = RiderFatigueBodyHeatmapPainter.hitTestGroup(
                      event.localPosition,
                      _lastCanvasSize,
                    );
                    if (hit != _hoveredGroup) {
                      setState(() => _hoveredGroup = hit);
                    }
                  }
                : null,
            onExit: (_) {
              if (_hoveredGroup != null) {
                setState(() => _hoveredGroup = null);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.enabled
                  ? (details) {
                      final hit = RiderFatigueBodyHeatmapPainter.hitTestGroup(
                        details.localPosition,
                        _lastCanvasSize,
                      );
                      if (hit != null) {
                        _selectGroup(hit);
                      }
                    }
                  : null,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    size: _lastCanvasSize,
                    painter: RiderFatigueBodyHeatmapPainter(
                      profile: widget.profile,
                      selectedGroup: _selectedGroup,
                      hoveredGroup: _hoveredGroup,
                      isEnabled: widget.enabled,
                      pulsePhase: _pulseController.value,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < BodyFatigueGroup.values.length; i++) ...[
          _buildGroupTile(BodyFatigueGroup.values[i]),
          if (i < BodyFatigueGroup.values.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildGroupTile(BodyFatigueGroup group) {
    final level = widget.profile.valueFor(group);
    final pct = (level * 100).round();
    final color = RiderFatigueBodyHeatmapPainter.fatigueColorForLevel(
      level,
      isEnabled: widget.enabled,
    );
    final severity = FatigueSeverityLevel.fromValue(level);
    final isSelected = _selectedGroup == group;
    final isHovered = _hoveredGroup == group;
    final isFocused = _focusedGroup == group;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (hovering) {
        setState(() {
          if (hovering) {
            _hoveredGroup = group;
          } else if (_hoveredGroup == group) {
            _hoveredGroup = null;
          }
        });
      },
      onShowFocusHighlight: (focused) {
        setState(() {
          if (focused) {
            _focusedGroup = group;
          } else if (_focusedGroup == group) {
            _focusedGroup = null;
          }
        });
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _selectGroup(group);
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.enabled ? () => _selectGroup(group) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.surfaceLight
                : isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.65)
                    : AppColors.background.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFocused
                  ? AppColors.accentBlue
                  : isSelected
                      ? AppColors.goldAccent
                      : isHovered
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : AppColors.cardBorder,
              width: isSelected || isFocused ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.labelPl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: level,
                        minHeight: 5,
                        backgroundColor: AppColors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    severity.labelPl,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedGroupBanner(
    BodyFatigueGroup group,
    double level,
    FatigueSeverityLevel severity,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                group == BodyFatigueGroup.centralNervousSystem
                    ? Icons.psychology_alt_rounded
                    : Icons.monitor_heart_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${group.labelPl} — ${severity.labelPl} (${(level * 100).round()}%)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            group.cyclingRoleDescription,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              height: 1.38,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend(bool isCompact) {
    return Row(
      children: [
        const Text(
          'Świeży',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.statusSuccess,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [
                  AppColors.statusSuccess,
                  AppColors.amberWarning,
                  AppColors.crimsonAlert,
                  RiderFatigueBodyHeatmapPainter.deepCrimson,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isCompact ? 'Krytyczny' : 'Skrajne przeciążenie',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.crimsonAlert,
          ),
        ),
      ],
    );
  }
}
