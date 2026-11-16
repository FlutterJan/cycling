// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Tryb biomechaniczny jazdy na stojąco ("en danseuse").
enum StandingRockingMode {
  /// Kolarz pozostaje w siodle (brak kołysania ramy).
  seated('W siodle'),

  /// Wspinaczka na stojąco na stromym podjeździe (>9%).
  steepClimbEnDanseuse('Wspinaczka >9% (En Danseuse)'),

  /// Agresywny atak na stojąco z oderwaniem od grupy.
  attackEnDanseuse('Atak na stojąco'),

  /// Połączony atak na stromym podjeździe (>9%) z maksymalnym momentem obrotowym.
  attackOnSteepClimb('Atak na podjeździe >9%');

  final String label;

  const StandingRockingMode(this.label);

  bool get isStanding => this != StandingRockingMode.seated;
}

/// Konfiguracja parametrów biomechanicznych kołysania roweru na stojąco.
class StandingBikeRockingConfig {
  /// Minimalne nachylenie [%], powyżej którego wspinaczka wymusza jazdę "en danseuse".
  final double steepClimbGradientThresholdPercent;

  /// Maksymalny kąt przechyłu bocznego roweru $\phi_{max}$ w stopniach ($\pm 7^\circ$).
  final double maxRockAngleDegrees;

  /// Współczynnik przeciw-pochylenia tułowia względem przechyłu roweru.
  final double torsoCounterLeanRatio;

  /// Maksymalne boczne przesunięcie środka ciężkości (CoM) tułowia w metrach [m] w przeciwfazie.
  final double maxTorsoComLateralOffsetMeters;

  /// Amplituda pionowego unoszenia miednicy (2x na obrót korby) [m].
  final double pelvisVerticalBobAmplitudeMeters;

  /// Maksymalny kąt skrętu/kontry barków w osi podłużnej [stopnie].
  final double maxShoulderCounterRollDegrees;

  /// Wysokość osi suportu nad punktem styku opony z asfaltem [m] (do obliczenia wychylenia suportu).
  final double bottomBracketHeightMeters;

  /// Szybkość narastania/wygaszania przejścia między siodłem a jazdą na stojąco [1/s].
  final double transitionSmoothingRate;

  const StandingBikeRockingConfig({
    this.steepClimbGradientThresholdPercent = 9.0,
    this.maxRockAngleDegrees = 7.0,
    this.torsoCounterLeanRatio = 0.78,
    this.maxTorsoComLateralOffsetMeters = 0.085,
    this.pelvisVerticalBobAmplitudeMeters = 0.032,
    this.maxShoulderCounterRollDegrees = 5.5,
    this.bottomBracketHeightMeters = 0.27,
    this.transitionSmoothingRate = 5.5,
  });

  StandingBikeRockingConfig copyWith({
    double? steepClimbGradientThresholdPercent,
    double? maxRockAngleDegrees,
    double? torsoCounterLeanRatio,
    double? maxTorsoComLateralOffsetMeters,
    double? pelvisVerticalBobAmplitudeMeters,
    double? maxShoulderCounterRollDegrees,
    double? bottomBracketHeightMeters,
    double? transitionSmoothingRate,
  }) {
    return StandingBikeRockingConfig(
      steepClimbGradientThresholdPercent:
          steepClimbGradientThresholdPercent ??
          this.steepClimbGradientThresholdPercent,
      maxRockAngleDegrees: maxRockAngleDegrees ?? this.maxRockAngleDegrees,
      torsoCounterLeanRatio:
          torsoCounterLeanRatio ?? this.torsoCounterLeanRatio,
      maxTorsoComLateralOffsetMeters:
          maxTorsoComLateralOffsetMeters ?? this.maxTorsoComLateralOffsetMeters,
      pelvisVerticalBobAmplitudeMeters:
          pelvisVerticalBobAmplitudeMeters ??
          this.pelvisVerticalBobAmplitudeMeters,
      maxShoulderCounterRollDegrees:
          maxShoulderCounterRollDegrees ?? this.maxShoulderCounterRollDegrees,
      bottomBracketHeightMeters:
          bottomBracketHeightMeters ?? this.bottomBracketHeightMeters,
      transitionSmoothingRate:
          transitionSmoothingRate ?? this.transitionSmoothingRate,
    );
  }
}

/// Dane wejściowe klatki dla obliczeń biomechaniki jazdy na stojąco.
class StandingRockingFrameInput {
  /// Aktualny kąt korby $\theta_{crank}$ w radianach $[0, 2\pi)$ (0 = godz. 12:00, $\pi/2$ = prawa noga w dół).
  final double crankAngleRadians;

  /// Nachylenie drogi w procentach [%].
  final double gradientPercent;

  /// Czy kolarz wykonuje atak lub dynamiczne przyspieszenie.
  final bool isAttacking;

  /// Aktualna kadencja w obrotach na minutę [RPM].
  final double cadenceRpm;

  /// Aktualna generowana moc w watach [W].
  final double powerWatts;

  /// Opcjonalne wymuszenie stanu stania (null = automatyczna detekcja ataku lub wspinaczki >9%).
  final bool? forceStanding;

  const StandingRockingFrameInput({
    required this.crankAngleRadians,
    required this.gradientPercent,
    this.isAttacking = false,
    this.cadenceRpm = 78.0,
    this.powerWatts = 420.0,
    this.forceStanding,
  });
}

/// Wynik obliczeń biomechanicznych pojedynczej klatki dla roweru i kolarza "en danseuse".
class StandingBikeRockingState {
  /// Aktywny tryb jazdy na stojąco.
  final StandingRockingMode mode;

  /// Czy biomechanika "en danseuse" jest aktywna (atak lub wspinaczka >9%).
  final bool isStandingActive;

  /// Wygładzony współczynnik przejścia siodło <-> stojąco $[0.0, 1.0]$.
  final double standingBlend;

  /// Kąt korby $\theta_{crank}$ znormalizowany do $[0, 2\pi)$ [rad].
  final double crankAngleRadians;

  /// Efektywna amplituda maksymalnego kołysania $\phi_{max}$ [stopnie].
  final double effectiveMaxRockDegrees;

  /// Kąt przechyłu roweru pod kolarzem $\phi(t) = \phi_{max} \cdot \sin(\theta_{crank})$ [stopnie].
  final double bikeRollAngleDegrees;

  /// Kąt przechyłu roweru $\phi(t)$ w radianach [rad].
  final double bikeRollAngleRadians;

  /// Kąt przeciw-pochylenia tułowia w przeciwfazie do roweru [stopnie].
  final double torsoCounterRollDegrees;

  /// Kąt kontry linii barków w przeciwfazie do przechyłu roweru [stopnie].
  final double shoulderCounterRollDegrees;

  /// Boczne przesunięcie środka ciężkości (CoM) tułowia względem osi symetrii [m] (w przeciwfazie do $\phi(t)$).
  final double torsoComLateralOffsetMeters;

  /// Boczne wychylenie suportu wynikające z przechyłu roweru nad punktem styku opony [m].
  final double bottomBracketLateralSwingMeters;

  /// Pionowe uniesienie miednicy (podwójna częstotliwość względem korby) [m].
  final double pelvisVerticalBobMeters;

  /// Znormalizowana siła podciągania kierownicy prawą ręką $[-1.0, +1.0]$ (w przeciwfazie do $\phi(t)$).
  final double rightArmPullNormalized;

  /// Znormalizowana siła podciągania kierownicy lewą ręką $[-1.0, +1.0]$ (w przeciwfazie do prawej ręki).
  final double leftArmPullNormalized;

  /// Macierz rotacji 3D ramy roweru wokół osi podłużnej Z.
  final vm.Matrix4 bikeRollMatrix;

  const StandingBikeRockingState({
    required this.mode,
    required this.isStandingActive,
    required this.standingBlend,
    required this.crankAngleRadians,
    required this.effectiveMaxRockDegrees,
    required this.bikeRollAngleDegrees,
    required this.bikeRollAngleRadians,
    required this.torsoCounterRollDegrees,
    required this.shoulderCounterRollDegrees,
    required this.torsoComLateralOffsetMeters,
    required this.bottomBracketLateralSwingMeters,
    required this.pelvisVerticalBobMeters,
    required this.rightArmPullNormalized,
    required this.leftArmPullNormalized,
    required this.bikeRollMatrix,
  });
}

/// Silnik ultra-realistycznej biomechaniki jazdy na stojąco ("en danseuse").
///
/// Modeluje cykliczne kołysanie roweru pod kolarzem podczas ataku lub wspinaczki $>9\%$
/// zgodnie z prawem harmonicznym:
/// $$\phi(t) = \phi_{max} \cdot \sin(\theta_{crank})$$
/// dla $\phi_{max} \le 7^\circ$, przy jednoczesnym ruchu ramion i środka ciężkości tułowia
/// w ścisłej przeciwfazie ($\Delta\varphi = \pi$) w celu stabilizacji środka masy nad torem jazdy.
class StandingBikeRockingPhysics3d {
  final StandingBikeRockingConfig config;

  double _standingBlend = 0.0;
  double _crankAngleRadians = 0.0;

  StandingBikeRockingPhysics3d({
    this.config = const StandingBikeRockingConfig(),
    double initialCrankAngleRadians = 0.0,
    double initialStandingBlend = 0.0,
  }) : _crankAngleRadians = _normalizeAngle(initialCrankAngleRadians),
       _standingBlend = initialStandingBlend.clamp(0.0, 1.0);

  double get currentStandingBlend => _standingBlend;
  double get currentCrankAngleRadians => _crankAngleRadians;

  /// Określa tryb jazdy "en danseuse" na podstawie ataku i nachylenia drogi ($>9\%$).
  StandingRockingMode resolveMode({
    required double gradientPercent,
    required bool isAttacking,
    bool? forceStanding,
  }) {
    if (forceStanding == false) {
      return StandingRockingMode.seated;
    }

    final bool steepClimb =
        gradientPercent > config.steepClimbGradientThresholdPercent;

    if (isAttacking && steepClimb) {
      return StandingRockingMode.attackOnSteepClimb;
    }
    if (isAttacking) {
      return StandingRockingMode.attackEnDanseuse;
    }
    if (steepClimb || forceStanding == true) {
      return StandingRockingMode.steepClimbEnDanseuse;
    }
    return StandingRockingMode.seated;
  }

  /// Wylicza stan biomechaniczny w trybie krokowym (60/120 FPS) z płynnym wygładzaniem przejść.
  StandingBikeRockingState step({
    required double dtSeconds,
    required double gradientPercent,
    required bool isAttacking,
    required double cadenceRpm,
    double powerWatts = 420.0,
    bool? forceStanding,
  }) {
    final double safeDt = dtSeconds.clamp(0.0001, 0.1);
    final double safeCadence = cadenceRpm.clamp(0.0, 180.0);
    final double omega = (safeCadence * 2.0 * math.pi) / 60.0;
    _crankAngleRadians = _normalizeAngle(_crankAngleRadians + omega * safeDt);

    final mode = resolveMode(
      gradientPercent: gradientPercent,
      isAttacking: isAttacking,
      forceStanding: forceStanding,
    );

    final double targetBlend = mode.isStanding ? 1.0 : 0.0;
    final double alpha = (safeDt * config.transitionSmoothingRate).clamp(
      0.0,
      1.0,
    );
    _standingBlend = (_standingBlend + (targetBlend - _standingBlend) * alpha)
        .clamp(0.0, 1.0);

    return evaluateAtBlend(
      input: StandingRockingFrameInput(
        crankAngleRadians: _crankAngleRadians,
        gradientPercent: gradientPercent,
        isAttacking: isAttacking,
        cadenceRpm: safeCadence,
        powerWatts: powerWatts,
        forceStanding: forceStanding,
      ),
      standingBlendOverride: _standingBlend,
    );
  }

  /// Bezstanowe wyliczenie pojedynczej klatki dla zadanego kąta korby $\theta_{crank}$ i parametrów jazdy.
  StandingBikeRockingState evaluateFrame(StandingRockingFrameInput input) {
    final mode = resolveMode(
      gradientPercent: input.gradientPercent,
      isAttacking: input.isAttacking,
      forceStanding: input.forceStanding,
    );
    return evaluateAtBlend(
      input: input,
      standingBlendOverride: mode.isStanding ? 1.0 : 0.0,
    );
  }

  /// Bezstanowe wyliczenie pojedynczej klatki z jawnym współczynnikiem przejścia $[0.0, 1.0]$.
  StandingBikeRockingState evaluateAtBlend({
    required StandingRockingFrameInput input,
    required double standingBlendOverride,
  }) {
    final double blend = standingBlendOverride.clamp(0.0, 1.0);
    final double theta = _normalizeAngle(input.crankAngleRadians);
    final mode = resolveMode(
      gradientPercent: input.gradientPercent,
      isAttacking: input.isAttacking,
      forceStanding: input.forceStanding,
    );

    // Brak aktywnego ruchu korby lub całkowicie w siodle -> brak kołysania.
    final double cadenceFactor = input.cadenceRpm <= 1.0
        ? 0.0
        : (input.cadenceRpm / 40.0).clamp(0.35, 1.0);
    final double effectiveBlend = blend * cadenceFactor;

    final double phiMaxDeg = computeEffectiveMaxRockDegrees(
      gradientPercent: input.gradientPercent,
      isAttacking: input.isAttacking,
      powerWatts: input.powerWatts,
      forceStanding: input.forceStanding,
    );

    // Podstawowe prawo harmoniczne: \phi(t) = \phi_{max} * \sin(\theta_{crank})
    final double sinTheta = math.sin(theta);
    final double bikeRollDeg = phiMaxDeg * sinTheta * effectiveBlend;
    final double bikeRollRad = bikeRollDeg * (math.pi / 180.0);

    // Przeciwfaza (\Delta\varphi = \pi): tułów, środek ciężkości (CoM) i ramiona działają odwrotnie do przechyłu roweru.
    final double torsoCounterRollDeg =
        -bikeRollDeg * config.torsoCounterLeanRatio;
    final double shoulderCounterRollDeg =
        -config.maxShoulderCounterRollDegrees * sinTheta * effectiveBlend;
    final double torsoComLateralOffset =
        -config.maxTorsoComLateralOffsetMeters * sinTheta * effectiveBlend;

    // Boczne wychylenie suportu pod kolarzem nad punktem styku opony z asfaltem.
    final double bottomBracketSwing =
        config.bottomBracketHeightMeters * math.sin(bikeRollRad);

    // Pionowe unoszenie miednicy 2x na obrót korby (maksimum przy przejściu przez środek suwu).
    final double pelvisBob =
        config.pelvisVerticalBobAmplitudeMeters *
        0.5 *
        (1.0 - math.cos(2.0 * theta)) *
        effectiveBlend;

    // Ramiona w przeciwfazie: gdy prawa noga naciska (+sinTheta), lewa ręka ciągnie (+sinTheta), a prawa kontruje (-sinTheta).
    final double rightArmPull = -sinTheta * effectiveBlend;
    final double leftArmPull = sinTheta * effectiveBlend;

    final vm.Matrix4 rollMatrix = vm.Matrix4.identity()
      ..setRotationZ(bikeRollRad);

    return StandingBikeRockingState(
      mode: mode,
      isStandingActive: mode.isStanding,
      standingBlend: blend,
      crankAngleRadians: theta,
      effectiveMaxRockDegrees: phiMaxDeg,
      bikeRollAngleDegrees: bikeRollDeg,
      bikeRollAngleRadians: bikeRollRad,
      torsoCounterRollDegrees: torsoCounterRollDeg,
      shoulderCounterRollDegrees: shoulderCounterRollDeg,
      torsoComLateralOffsetMeters: torsoComLateralOffset,
      bottomBracketLateralSwingMeters: bottomBracketSwing,
      pelvisVerticalBobMeters: pelvisBob,
      rightArmPullNormalized: rightArmPull,
      leftArmPullNormalized: leftArmPull,
      bikeRollMatrix: rollMatrix,
    );
  }

  /// Wyznacza maksymalny kąt kołysania $\phi_{max} \in [0, 7.0^\circ]$ dla aktualnego wysiłku.
  double computeEffectiveMaxRockDegrees({
    required double gradientPercent,
    required bool isAttacking,
    required double powerWatts,
    bool? forceStanding,
  }) {
    final mode = resolveMode(
      gradientPercent: gradientPercent,
      isAttacking: isAttacking,
      forceStanding: forceStanding,
    );
    if (!mode.isStanding) {
      return 0.0;
    }

    final double baseMax = config.maxRockAngleDegrees.clamp(0.0, 7.0);
    if (isAttacking) {
      return baseMax;
    }

    // Na stromym podjeździe >9% amplituda rośnie płynnie z nachyleniem i mocą aż do pełnych ±7°.
    final double gradientGain =
        ((gradientPercent - config.steepClimbGradientThresholdPercent) / 5.0)
            .clamp(0.65, 1.0);
    final double powerGain = (powerWatts / 400.0).clamp(0.75, 1.0);
    return (baseMax * math.max(gradientGain, powerGain)).clamp(0.0, baseMax);
  }

  /// Resetuje stan fazowy silnika.
  void reset({
    double initialCrankAngleRadians = 0.0,
    double initialStandingBlend = 0.0,
  }) {
    _crankAngleRadians = _normalizeAngle(initialCrankAngleRadians);
    _standingBlend = initialStandingBlend.clamp(0.0, 1.0);
  }

  static double _normalizeAngle(double angle) {
    const double twoPi = 2.0 * math.pi;
    final double wrapped = angle % twoPi;
    return wrapped < 0.0 ? wrapped + twoPi : wrapped;
  }
}

/// Responsywny panel inspektora biomechaniki jazdy na stojąco ("en danseuse").
class StandingBikeRockingControlPanel extends StatefulWidget {
  final StandingBikeRockingPhysics3d? engine;
  final ValueChanged<StandingBikeRockingState>? onStateChanged;

  const StandingBikeRockingControlPanel({
    super.key,
    this.engine,
    this.onStateChanged,
  });

  @override
  State<StandingBikeRockingControlPanel> createState() =>
      _StandingBikeRockingControlPanelState();
}

class _StandingBikeRockingControlPanelState
    extends State<StandingBikeRockingControlPanel> {
  late final StandingBikeRockingPhysics3d _engine;
  double _gradientPercent = 11.5;
  bool _isAttacking = false;
  final double _cadenceRpm = 76.0;
  double _crankDegrees = 90.0;
  bool _controlsEnabled = true;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? StandingBikeRockingPhysics3d();
  }

  StandingBikeRockingState _computeCurrentState() {
    final state = _engine.evaluateFrame(
      StandingRockingFrameInput(
        crankAngleRadians: _crankDegrees * (math.pi / 180.0),
        gradientPercent: _gradientPercent,
        isAttacking: _isAttacking,
        cadenceRpm: _cadenceRpm,
        powerWatts: _isAttacking ? 680.0 : 440.0,
      ),
    );
    return state;
  }

  void _notifyChanged(StandingBikeRockingState state) {
    widget.onStateChanged?.call(state);
  }

  @override
  Widget build(BuildContext context) {
    final state = _computeCurrentState();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 540;

        return Container(
          padding: EdgeInsets.all(isCompact ? 14.0 : 18.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(state, isCompact),
                const SizedBox(height: 14),
                if (isCompact) ...[
                  _buildPhaseDiagramCard(state),
                  const SizedBox(height: 12),
                  _buildTelemetryGrid(state, isCompact),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildPhaseDiagramCard(state)),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 6,
                        child: _buildTelemetryGrid(state, isCompact),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _buildControlsSection(isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(StandingBikeRockingState state, bool isCompact) {
    final Color badgeColor = state.isStandingActive
        ? AppColors.goldAccent
        : AppColors.textSecondary;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bike_rounded,
              color: state.isStandingActive
                  ? AppColors.goldAccent
                  : AppColors.accentBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Biomechanika En Danseuse 3D',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  fontSize: isCompact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Text(
            state.mode.label,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseDiagramCard(StandingBikeRockingState state) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: CustomPaint(
        painter: StandingRockingPhasePainter(state: state),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildTelemetryGrid(StandingBikeRockingState state, bool isCompact) {
    final items = <_MetricTileData>[
      _MetricTileData(
        label: 'Przechył roweru φ(t)',
        value: '${state.bikeRollAngleDegrees.toStringAsFixed(2)}°',
        accent: AppColors.goldAccent,
      ),
      _MetricTileData(
        label: 'Kontra tułowia (CoM)',
        value: '${state.torsoCounterRollDegrees.toStringAsFixed(2)}°',
        accent: AppColors.cyanAccent,
      ),
      _MetricTileData(
        label: 'Przesunięcie CoM',
        value:
            '${(state.torsoComLateralOffsetMeters * 100.0).toStringAsFixed(1)} cm',
        accent: AppColors.accentBlue,
      ),
      _MetricTileData(
        label: 'Ciąg ramion (L / P)',
        value:
            '${state.leftArmPullNormalized.toStringAsFixed(2)} / ${state.rightArmPullNormalized.toStringAsFixed(2)}',
        accent: AppColors.statusSuccess,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: isCompact ? 72 : 80,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: item.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlsSection(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RockingActionButton(
                label: _isAttacking ? 'Atak aktywny' : 'Symuluj Atak',
                isActive: _isAttacking,
                enabled: _controlsEnabled,
                onPressed: () {
                  setState(() {
                    _isAttacking = !_isAttacking;
                  });
                  _notifyChanged(_computeCurrentState());
                },
              ),
              _RockingActionButton(
                label: 'Podjazd 12%',
                isActive: _gradientPercent > 9.0,
                enabled: _controlsEnabled,
                onPressed: () {
                  setState(() {
                    _gradientPercent = _gradientPercent > 9.0 ? 4.0 : 12.0;
                  });
                  _notifyChanged(_computeCurrentState());
                },
              ),
              _RockingActionButton(
                label: _controlsEnabled ? 'Blokuj' : 'Odblokuj',
                isActive: !_controlsEnabled,
                enabled: true,
                onPressed: () {
                  setState(() {
                    _controlsEnabled = !_controlsEnabled;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSliderRow(
            label: 'Nachylenie: ${_gradientPercent.toStringAsFixed(1)}%',
            value: _gradientPercent,
            min: 0.0,
            max: 20.0,
            enabled: _controlsEnabled,
            isCompact: isCompact,
            onChanged: (val) {
              setState(() => _gradientPercent = val);
              _notifyChanged(_computeCurrentState());
            },
          ),
          _buildSliderRow(
            label: 'Kąt korby θ: ${_crankDegrees.toStringAsFixed(0)}°',
            value: _crankDegrees,
            min: 0.0,
            max: 360.0,
            enabled: _controlsEnabled,
            isCompact: isCompact,
            onChanged: (val) {
              setState(() => _crankDegrees = val);
              _notifyChanged(_computeCurrentState());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required bool enabled,
    required bool isCompact,
    required ValueChanged<double> onChanged,
  }) {
    final labelWidget = Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        letterSpacing: -0.2,
        fontSize: 12,
        color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final sliderWidget = Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      activeColor: AppColors.goldAccent,
      inactiveColor: AppTheme.borderColor,
      onChanged: enabled ? onChanged : null,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          labelWidget,
          sliderWidget,
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: 132, child: labelWidget),
        Expanded(child: sliderWidget),
      ],
    );
  }
}

class _MetricTileData {
  final String label;
  final String value;
  final Color accent;

  const _MetricTileData({
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _RockingActionButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback onPressed;

  const _RockingActionButton({
    required this.label,
    required this.isActive,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_RockingActionButton> createState() => _RockingActionButtonState();
}

class _RockingActionButtonState extends State<_RockingActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = !widget.enabled
        ? AppColors.surface
        : widget.isActive
        ? AppColors.primaryAccent
        : AppColors.background;
    final Color borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
        ? AppColors.goldAccent
        : _hovered
        ? AppColors.accentBlue
        : widget.isActive
        ? AppColors.goldAccent
        : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
            _pressed ? 0.97 : 1.0,
            _pressed ? 0.97 : 1.0,
            1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

/// Rysuje schemat fazowy przechyłu roweru $\phi(t)$ oraz przeciwfazy tułowia i ramion.
class StandingRockingPhasePainter extends CustomPainter {
  final StandingBikeRockingState state;

  const StandingRockingPhasePainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.84);
    final double frameLen = size.height * 0.58;

    final Paint axisPaint = Paint()
      ..color = AppTheme.borderColor
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(center.dx, size.height * 0.08),
      center,
      axisPaint,
    );

    // Linia ramy roweru przechylona o \phi(t)
    final double bikeRad = state.bikeRollAngleRadians;
    final Offset handlebarTop = Offset(
      center.dx + math.sin(bikeRad) * frameLen,
      center.dy - math.cos(bikeRad) * frameLen,
    );
    final Paint bikePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, handlebarTop, bikePaint);

    // Wektor przeciwfazy tułowia (CoM) nad rowerem
    final double torsoRad = state.torsoCounterRollDegrees * (math.pi / 180.0);
    final Offset torsoStart = Offset(
      handlebarTop.dx + state.torsoComLateralOffsetMeters * 160.0,
      handlebarTop.dy,
    );
    final Offset torsoEnd = Offset(
      torsoStart.dx + math.sin(torsoRad) * (frameLen * 0.42),
      torsoStart.dy - math.cos(torsoRad) * (frameLen * 0.42),
    );
    final Paint torsoPaint = Paint()
      ..color = AppColors.cyanAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(torsoStart, torsoEnd, torsoPaint);

    canvas.drawCircle(
      torsoEnd,
      5.0,
      Paint()..color = AppColors.cyanAccent,
    );
    canvas.drawCircle(
      center,
      4.0,
      Paint()..color = AppColors.goldAccent,
    );
  }

  @override
  bool shouldRepaint(covariant StandingRockingPhasePainter oldDelegate) {
    return oldDelegate.state.bikeRollAngleDegrees !=
            state.bikeRollAngleDegrees ||
        oldDelegate.state.torsoCounterRollDegrees !=
            state.torsoCounterRollDegrees ||
        oldDelegate.state.standingBlend != state.standingBlend;
  }
}
