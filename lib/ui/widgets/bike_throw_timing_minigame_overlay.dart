import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/peloton/finish_line_bike_throw_physics.dart';

/// Strefa wyczucia czasu na pierścieniu synchronizacji w minigrze Bike Throw.
enum BikeThrowRingZone {
  /// Poza strefą aktywacji (>150 m) lub oczekiwanie przed linią.
  waiting('Oczekiwanie', AppColors.textSecondary),

  /// Zbyt wcześnie — czerwona strefa (strata pędu przed kreską).
  redEarly('Za wcześnie', AppColors.crimsonAlert),

  /// Strefa ostrzegawcza przed idealnym momentem (bursztynowa).
  amberEarly('Prawie...', AppColors.amberWarning),

  /// Zielona strefa idealnej synchronizacji z linią mety (+28 cm).
  greenOptimal('ZIELONA STREFA', AppColors.statusSuccess),

  /// Strefa ostrzegawcza tuż po idealnym momencie (bursztynowa).
  amberLate('Spóźniony', AppColors.amberWarning),

  /// Za późno — czerwona strefa lub po przekroczeniu mety.
  redLate('Za późno', AppColors.crimsonAlert);

  final String label;
  final Color color;

  const BikeThrowRingZone(this.label, this.color);
}

/// Wynik próby gracza w minigrze `BikeThrowTimingMinigameOverlay`.
class BikeThrowMinigameResult {
  final BikeThrowRingZone zone;
  final BikeThrowTimingQuality timingQuality;
  final double wheelExtensionCm;
  final double timeSavedSeconds;
  final double triggerDistanceMeters;
  final double optimalDistanceMeters;
  final bool isMaxImpulse;

  const BikeThrowMinigameResult({
    required this.zone,
    required this.timingQuality,
    required this.wheelExtensionCm,
    required this.timeSavedSeconds,
    required this.triggerDistanceMeters,
    required this.optimalDistanceMeters,
    required this.isMaxImpulse,
  });

  Map<String, dynamic> toJson() => {
        'zone': zone.name,
        'timingQuality': timingQuality.name,
        'wheelExtensionCm': wheelExtensionCm,
        'timeSavedSeconds': timeSavedSeconds,
        'triggerDistanceMeters': triggerDistanceMeters,
        'optimalDistanceMeters': optimalDistanceMeters,
        'isMaxImpulse': isMaxImpulse,
      };
}

/// Kalkulator i ewaluator strefy synchronizacji dla ostatnich 150 m sprintu.
class BikeThrowMinigameEvaluator {
  BikeThrowMinigameEvaluator._();

  /// Dystans od mety, na którym pojawia się pierścień synchronizacji [m].
  static const double appearanceDistanceMeters = 150.0;

  /// Maksymalny impuls wysunięcia przedniego koła w zielonej strefie [cm].
  static const double maxGreenZoneImpulseCm = 28.0;

  /// Początek zielonej strefy na znormalizowanym postępie pierścienia (0.0 -> 1.0).
  static const double greenZoneStartProgress = 0.86;

  /// Koniec zielonej strefy na znormalizowanym postępie pierścienia (0.0 -> 1.0).
  static const double greenZoneEndProgress = 0.96;

  /// Przelicza aktualny dystans do mety [m] (150 m -> 0 m) na postęp pierścienia `0.0..1.0`.
  static double computeRingProgress(double distanceToFinishMeters) {
    final clamped = distanceToFinishMeters.clamp(0.0, appearanceDistanceMeters);
    return (1.0 - (clamped / appearanceDistanceMeters)).clamp(0.0, 1.0);
  }

  /// Określa aktualną strefę na pierścieniu dla zadanego dystansu do mety [m].
  static BikeThrowRingZone evaluateZoneForDistance(
    double distanceToFinishMeters,
  ) {
    if (distanceToFinishMeters > appearanceDistanceMeters) {
      return BikeThrowRingZone.waiting;
    }
    if (distanceToFinishMeters <= 0.0) {
      return BikeThrowRingZone.redLate;
    }
    final progress = computeRingProgress(distanceToFinishMeters);
    if (progress < 0.72) {
      return BikeThrowRingZone.redEarly;
    }
    if (progress < greenZoneStartProgress) {
      return BikeThrowRingZone.amberEarly;
    }
    if (progress <= greenZoneEndProgress) {
      return BikeThrowRingZone.greenOptimal;
    }
    if (progress <= 0.985) {
      return BikeThrowRingZone.amberLate;
    }
    return BikeThrowRingZone.redLate;
  }

  /// Wylicza pełny wynik fizyczny rzutu rowerem po naciśnięciu przycisku `Rzut Rowerem`.
  static BikeThrowMinigameResult evaluateThrow({
    required BikeThrowRiderProfile profile,
    required double distanceToFinishMeters,
    required double speedKmh,
  }) {
    final zone = evaluateZoneForDistance(distanceToFinishMeters);
    final optimalDist = FinishLineBikeThrowPhysics.computeOptimalTriggerDistanceMeters(
      profile: profile,
      speedKmh: speedKmh,
    );
    final speedMs = speedKmh.clamp(25.0, 95.0) / 3.6;

    if (zone == BikeThrowRingZone.greenOptimal) {
      // Naciśnięcie w zielonej strefie daje gwarantowany maksymalny impuls +28 cm.
      final timeSaved = (maxGreenZoneImpulseCm / 100.0) / speedMs;
      return BikeThrowMinigameResult(
        zone: zone,
        timingQuality: BikeThrowTimingQuality.perfect,
        wheelExtensionCm: maxGreenZoneImpulseCm,
        timeSavedSeconds: timeSaved,
        triggerDistanceMeters: distanceToFinishMeters,
        optimalDistanceMeters: optimalDist,
        isMaxImpulse: true,
      );
    }

    if (distanceToFinishMeters <= 0.0 ||
        distanceToFinishMeters > appearanceDistanceMeters) {
      return BikeThrowMinigameResult(
        zone: zone,
        timingQuality: BikeThrowTimingQuality.notTriggered,
        wheelExtensionCm: 0.0,
        timeSavedSeconds: 0.0,
        triggerDistanceMeters: distanceToFinishMeters,
        optimalDistanceMeters: optimalDist,
        isMaxImpulse: false,
      );
    }

    // Poza zieloną strefą delegujemy do symulatora fizyki ostatnich 10 m
    // (lub skalujemy dla wczesnego impulsu między 10 m a 150 m).
    if (distanceToFinishMeters <= FinishLineBikeThrowPhysics.activationZoneMeters) {
      final outcome = FinishLineBikeThrowPhysics.simulateFinal10Meters(
        BikeThrowAttemptInput(
          profile: profile,
          entrySpeedKmh: speedKmh,
          triggerDistanceToFinishMeters: distanceToFinishMeters,
          isManualPlayer: true,
        ),
      );
      return BikeThrowMinigameResult(
        zone: zone,
        timingQuality: outcome.timingQuality,
        wheelExtensionCm:
            (outcome.actualGainAtLineMm / 10.0).clamp(0.0, maxGreenZoneImpulseCm),
        timeSavedSeconds: outcome.timeSavedSeconds,
        triggerDistanceMeters: distanceToFinishMeters,
        optimalDistanceMeters: outcome.optimalTriggerDistanceMeters,
        isMaxImpulse: false,
      );
    }

    // Wcześniejszy rzut (>10 m) powoduje wytracenie pozycji przed samą kreską.
    final earlyGainCm = zone == BikeThrowRingZone.amberEarly ? 14.5 : 6.0;
    final earlyQuality = zone == BikeThrowRingZone.amberEarly
        ? BikeThrowTimingQuality.early
        : BikeThrowTimingQuality.tooEarly;
    return BikeThrowMinigameResult(
      zone: zone,
      timingQuality: earlyQuality,
      wheelExtensionCm: earlyGainCm,
      timeSavedSeconds: (earlyGainCm / 100.0) / speedMs,
      triggerDistanceMeters: distanceToFinishMeters,
      optimalDistanceMeters: optimalDist,
      isMaxImpulse: false,
    );
  }
}

/// Opcjonalna nakładka minigry wyczucia czasu dla finiszu sprinterskiego (ostatnie 150 m).
///
/// Wyświetla dynamiczny pierścień synchronizacji z linią mety, przycisk `Rzut Rowerem`
/// z pełnymi stanami `hover`/`active`/`disabled`/`focus`, podgląd animacji wyrzutu 3D
/// oraz impuls $+28\text{ cm}$ przy trafieniu w zieloną strefę.
class BikeThrowTimingMinigameOverlay extends StatefulWidget {
  /// Aktualny dystans kolarza do linii mety [m]. Overlay jest aktywny dla `<= 150.0 m`.
  final double distanceToFinishMeters;

  /// Aktualna prędkość kolarza [km/h].
  final double currentSpeedKmh;

  /// Profil kolarza wykonującego finisz.
  final BikeThrowRiderProfile riderProfile;

  /// Czy opcjonalna minigra jest włączona przez gracza.
  final bool isEnabled;

  /// Callback wywoływany przy przełączeniu opcjonalnego trybu minigry.
  final ValueChanged<bool>? onToggleEnabled;

  /// Callback wywoływany po wykonaniu rzutu rowerem z obliczonym rezultatem.
  final ValueChanged<BikeThrowMinigameResult>? onBikeThrowTriggered;

  /// Opcjonalny callback resetujący próbę (np. w trybie treningowym / powtórce).
  final VoidCallback? onResetAttempt;

  const BikeThrowTimingMinigameOverlay({
    super.key,
    required this.distanceToFinishMeters,
    required this.currentSpeedKmh,
    required this.riderProfile,
    this.isEnabled = true,
    this.onToggleEnabled,
    this.onBikeThrowTriggered,
    this.onResetAttempt,
  });

  @override
  State<BikeThrowTimingMinigameOverlay> createState() =>
      _BikeThrowTimingMinigameOverlayState();
}

class _BikeThrowTimingMinigameOverlayState
    extends State<BikeThrowTimingMinigameOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _throwAnimController;
  late final Animation<double> _throwLungeCurve;
  late final AnimationController _pulseController;

  final FocusNode _throwButtonFocusNode = FocusNode(
    debugLabel: 'bike_throw_action_button',
  );
  final FocusNode _toggleFocusNode = FocusNode(
    debugLabel: 'bike_throw_toggle_switch',
  );

  bool _isThrowHovered = false;
  bool _isThrowPressed = false;
  bool _isThrowFocused = false;
  bool _isToggleHovered = false;
  bool _isToggleFocused = false;

  BikeThrowMinigameResult? _result;

  @override
  void initState() {
    super.initState();
    _throwAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _throwLungeCurve = CurvedAnimation(
      parent: _throwAnimController,
      curve: Curves.easeOutCubic,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BikeThrowTimingMinigameOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset lokalnego wyniku, jeśli dystans został cofnięty ponad 145 m (nowy finisz).
    if (oldWidget.distanceToFinishMeters < 20.0 &&
        widget.distanceToFinishMeters >= 145.0 &&
        _result != null) {
      _result = null;
      _throwAnimController.reset();
    }
  }

  @override
  void dispose() {
    _throwAnimController.dispose();
    _pulseController.dispose();
    _throwButtonFocusNode.dispose();
    _toggleFocusNode.dispose();
    super.dispose();
  }

  bool get _isIn150mWindow =>
      widget.distanceToFinishMeters <=
          BikeThrowMinigameEvaluator.appearanceDistanceMeters &&
      widget.distanceToFinishMeters >= 0.0;

  bool get _canTriggerThrow =>
      widget.isEnabled &&
      _isIn150mWindow &&
      widget.distanceToFinishMeters > 0.0 &&
      _result == null;

  void _triggerBikeThrow() {
    if (!_canTriggerThrow) {
      return;
    }
    final evaluated = BikeThrowMinigameEvaluator.evaluateThrow(
      profile: widget.riderProfile,
      distanceToFinishMeters: widget.distanceToFinishMeters,
      speedKmh: widget.currentSpeedKmh,
    );
    setState(() {
      _result = evaluated;
    });
    _throwAnimController.forward(from: 0.0);
    HapticFeedback.mediumImpact();
    widget.onBikeThrowTriggered?.call(evaluated);
  }

  void _handleReset() {
    setState(() {
      _result = null;
    });
    _throwAnimController.reset();
    widget.onResetAttempt?.call();
  }

  @override
  Widget build(BuildContext context) {
    final currentZone = BikeThrowMinigameEvaluator.evaluateZoneForDistance(
      widget.distanceToFinishMeters,
    );
    final ringProgress = BikeThrowMinigameEvaluator.computeRingProgress(
      widget.distanceToFinishMeters,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 460.0;
        final isCompactMobile = maxWidth < 440.0;
        final isDesktop = maxWidth >= 900.0;

        final cardMaxWidth = isCompactMobile
            ? maxWidth
            : (isDesktop ? 560.0 : math.min(maxWidth, 500.0));

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: cardMaxWidth,
              maxHeight: constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 520.0,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(isCompactMobile ? 12.0 : 16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _resolveBorderColor(currentZone),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.background.withValues(alpha: 0.72),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isCompactMobile, currentZone),
                    SizedBox(height: isCompactMobile ? 10.0 : 14.0),
                    if (!widget.isEnabled)
                      _buildDisabledBanner()
                    else if (!_isIn150mWindow)
                      _buildWaitingOutsideWindowBanner()
                    else if (isCompactMobile)
                      _buildCompactBody(currentZone, ringProgress)
                    else
                      _buildWideBody(currentZone, ringProgress),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _resolveBorderColor(BikeThrowRingZone currentZone) {
    if (!widget.isEnabled) {
      return AppColors.cardBorder;
    }
    if (_result != null) {
      return _result!.isMaxImpulse
          ? AppColors.statusSuccess
          : _result!.timingQuality.color;
    }
    if (_isIn150mWindow && currentZone == BikeThrowRingZone.greenOptimal) {
      return AppColors.statusSuccess;
    }
    return const Color(0xFF2A2F3D);
  }

  Widget _buildHeader(bool isCompact, BikeThrowRingZone currentZone) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.65),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_bike_rounded,
                size: 14,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 6),
              Text(
                isCompact ? 'FINISZ 150M' : 'FINISZ SPRINTERSKI • 150 M',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.riderProfile.riderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildOptionalToggle(),
      ],
    );
  }

  Widget _buildOptionalToggle() {
    final active = widget.isEnabled;
    final hasCallback = widget.onToggleEnabled != null;

    return Focus(
      focusNode: _toggleFocusNode,
      onFocusChange: (focused) => setState(() => _isToggleFocused = focused),
      child: MouseRegion(
        cursor: hasCallback
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isToggleHovered = true),
        onExit: (_) => setState(() => _isToggleHovered = false),
        child: Semantics(
          button: true,
          toggled: active,
          label: 'Opcjonalna minigra Rzut Rowerem',
          child: InkWell(
            onTap: hasCallback ? () => widget.onToggleEnabled!(!active) : null,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? (_isToggleHovered
                        ? AppColors.surfaceLight
                        : AppColors.background)
                    : AppColors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isToggleFocused
                      ? AppColors.goldAccent
                      : (active
                          ? AppColors.statusSuccess.withValues(alpha: 0.7)
                          : AppColors.cardBorder),
                  width: _isToggleFocused ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    active ? 'AKTYWNA' : 'WYŁ.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.auto_mode_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tryb automatyczny AI — włącz minigrę, aby ręcznie wykonać rzut rowerem na ostatnich 150 m.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                letterSpacing: -0.2,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingOutsideWindowBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 18,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pierścień synchronizacji pojawi się na ostatnich 150 m (pozostało ${widget.distanceToFinishMeters.toStringAsFixed(0)} m).',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                letterSpacing: -0.2,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBody(
    BikeThrowRingZone currentZone,
    double ringProgress,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildSyncRingWidget(
              size: 112.0,
              currentZone: currentZone,
              ringProgress: ringProgress,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTelemetryAnd3dColumn(currentZone, isCompact: true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionButtonsRow(currentZone, isCompact: true),
      ],
    );
  }

  Widget _buildWideBody(
    BikeThrowRingZone currentZone,
    double ringProgress,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildSyncRingWidget(
          size: 138.0,
          currentZone: currentZone,
          ringProgress: ringProgress,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTelemetryAnd3dColumn(currentZone, isCompact: false),
              const SizedBox(height: 12),
              _buildActionButtonsRow(currentZone, isCompact: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncRingWidget({
    required double size,
    required BikeThrowRingZone currentZone,
    required double ringProgress,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _SyncRingPainter(
              progress: ringProgress,
              zone: currentZone,
              pulseValue: _pulseController.value,
              result: _result,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.distanceToFinishMeters.clamp(0.0, 999.9).toStringAsFixed(1)} m',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: size < 120 ? 15 : 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: _result != null
                          ? _result!.timingQuality.color
                          : (currentZone == BikeThrowRingZone.greenOptimal
                              ? AppColors.statusSuccess
                              : AppColors.textPrimary),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _result != null
                        ? (_result!.isMaxImpulse ? '+28.0 cm' : '+${_result!.wheelExtensionCm.toStringAsFixed(1)} cm')
                        : '${widget.currentSpeedKmh.toStringAsFixed(1)} km/h',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTelemetryAnd3dColumn(
    BikeThrowRingZone currentZone, {
    required bool isCompact,
  }) {
    final result = _result;
    final statusColor = result != null
        ? result.timingQuality.color
        : currentZone.color;
    final statusText = result != null
        ? (result.isMaxImpulse
            ? 'MAKSYMALNY IMPULS +28 cm!'
            : result.timingQuality.label)
        : currentZone.label;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: isCompact ? 62 : 76,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: result != null && result.isMaxImpulse
                  ? AppColors.statusSuccess.withValues(alpha: 0.8)
                  : AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: _throwLungeCurve,
            builder: (context, _) {
              final extensionFraction = result == null
                  ? 0.0
                  : (_throwLungeCurve.value *
                          (result.wheelExtensionCm /
                              BikeThrowMinigameEvaluator.maxGreenZoneImpulseCm))
                      .clamp(0.0, 1.0);
              return CustomPaint(
                painter: _BikeThrow3dPreviewPainter(
                  extensionFraction: extensionFraction,
                  distanceToFinishMeters: widget.distanceToFinishMeters,
                  jerseyColor: widget.riderProfile.primaryJerseyColor,
                  bikeColor: widget.riderProfile.bikeColor,
                  isPerfect: result?.isMaxImpulse ?? false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: statusColor,
                ),
              ),
            ),
            if (result != null) ...[
              const SizedBox(width: 8),
              Text(
                '-${result.timeSavedSeconds.toStringAsFixed(3)} s',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtonsRow(
    BikeThrowRingZone currentZone, {
    required bool isCompact,
  }) {
    final canTrigger = _canTriggerThrow;
    final inGreen = currentZone == BikeThrowRingZone.greenOptimal;

    final Color bgColor;
    if (!canTrigger) {
      bgColor = AppColors.surfaceLight;
    } else if (_isThrowPressed) {
      bgColor = inGreen
          ? AppColors.statusSuccess.withValues(alpha: 0.78)
          : AppColors.primaryAccent.withValues(alpha: 0.85);
    } else if (_isThrowHovered) {
      bgColor = inGreen
          ? AppColors.statusSuccess
          : const Color(0xFFA65756);
    } else {
      bgColor = inGreen ? AppColors.statusSuccess : AppColors.primaryAccent;
    }

    return Row(
      children: [
        Expanded(
          child: Focus(
            focusNode: _throwButtonFocusNode,
            onFocusChange: (focused) =>
                setState(() => _isThrowFocused = focused),
            onKeyEvent: (node, event) {
              if (canTrigger &&
                  event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.space ||
                      event.logicalKey == LogicalKeyboardKey.enter)) {
                _triggerBikeThrow();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: MouseRegion(
              cursor: canTrigger
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.forbidden,
              onEnter: (_) => setState(() => _isThrowHovered = true),
              onExit: (_) => setState(() {
                _isThrowHovered = false;
                _isThrowPressed = false;
              }),
              child: GestureDetector(
                onTapDown: canTrigger
                    ? (_) => setState(() => _isThrowPressed = true)
                    : null,
                onTapUp: canTrigger
                    ? (_) {
                        setState(() => _isThrowPressed = false);
                        _triggerBikeThrow();
                      }
                    : null,
                onTapCancel: () => setState(() => _isThrowPressed = false),
                child: Semantics(
                  button: true,
                  enabled: canTrigger,
                  label: 'Rzut Rowerem',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    height: isCompact ? 42 : 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isThrowFocused
                            ? AppColors.goldAccent
                            : (canTrigger && inGreen
                                ? AppColors.textPrimary.withValues(alpha: 0.6)
                                : AppColors.cardBorder),
                        width: _isThrowFocused ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _result != null
                              ? Icons.check_circle_rounded
                              : Icons.bolt_rounded,
                          size: 18,
                          color: canTrigger
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _result != null
                                ? (_result!.isMaxImpulse
                                    ? 'WYRZUT +28 cm!'
                                    : 'RZUT WYKONANY')
                                : 'Rzut Rowerem',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: isCompact ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: canTrigger
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.onResetAttempt != null && _result != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: 'Powtórz próbę',
            child: InkWell(
              onTap: _handleReset,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: isCompact ? 42 : 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 1.0),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SyncRingPainter extends CustomPainter {
  final double progress;
  final BikeThrowRingZone zone;
  final double pulseValue;
  final BikeThrowMinigameResult? result;

  const _SyncRingPainter({
    required this.progress,
    required this.zone,
    required this.pulseValue,
    required this.result,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (math.min(size.width, size.height) / 2) - 8.0;
    const strokeWidth = 9.0;
    const startAngle = -math.pi / 2;
    const fullSweep = 2 * math.pi;

    // 1. Bazowy tor pierścienia
    final trackPaint = Paint()
      ..color = AppColors.surfaceLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, outerRadius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: outerRadius);

    // 2. Strefy bursztynowe (przed i po zielonej strefie)
    final amberPaint = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      rect,
      startAngle + fullSweep * 0.72,
      fullSweep * (BikeThrowMinigameEvaluator.greenZoneStartProgress - 0.72),
      false,
      amberPaint,
    );
    canvas.drawArc(
      rect,
      startAngle + fullSweep * BikeThrowMinigameEvaluator.greenZoneEndProgress,
      fullSweep * (0.985 - BikeThrowMinigameEvaluator.greenZoneEndProgress),
      false,
      amberPaint,
    );

    // 3. Zielona strefa idealnej synchronizacji (+28 cm)
    final isInGreen = zone == BikeThrowRingZone.greenOptimal && result == null;
    final greenPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(
        alpha: isInGreen ? (0.75 + 0.25 * pulseValue) : 0.85,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInGreen ? strokeWidth + 3.0 : strokeWidth + 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      startAngle +
          fullSweep * BikeThrowMinigameEvaluator.greenZoneStartProgress,
      fullSweep *
          (BikeThrowMinigameEvaluator.greenZoneEndProgress -
              BikeThrowMinigameEvaluator.greenZoneStartProgress),
      false,
      greenPaint,
    );

    // 4. Dynamiczny łuk postępu dojazdu do mety
    final activeColor = result != null ? result!.timingQuality.color : zone.color;
    final sweepPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      startAngle,
      fullSweep * progress.clamp(0.0, 1.0),
      false,
      sweepPaint,
    );

    // 5. Kurczący się wewnętrzny pierścień synchronizacji z linią mety
    final targetInnerRadius = outerRadius * 0.64;
    final contractingRadius =
        outerRadius - ((outerRadius - targetInnerRadius) * progress);

    final targetRingPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, targetInnerRadius, targetRingPaint);

    final syncPulsePaint = Paint()
      ..color = activeColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, contractingRadius, syncPulsePaint);

    // 6. Znacznik aktualnej pozycji na obwodzie
    final markerAngle = startAngle + fullSweep * progress;
    final markerOffset = Offset(
      center.dx + outerRadius * math.cos(markerAngle),
      center.dy + outerRadius * math.sin(markerAngle),
    );
    canvas.drawCircle(
      markerOffset,
      5.5,
      Paint()..color = AppColors.textPrimary,
    );
    canvas.drawCircle(
      markerOffset,
      3.5,
      Paint()..color = activeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _SyncRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.zone != zone ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.result != result;
  }
}

class _BikeThrow3dPreviewPainter extends CustomPainter {
  final double extensionFraction;
  final double distanceToFinishMeters;
  final Color jerseyColor;
  final Color bikeColor;
  final bool isPerfect;

  const _BikeThrow3dPreviewPainter({
    required this.extensionFraction,
    required this.distanceToFinishMeters,
    required this.jerseyColor,
    required this.bikeColor,
    required this.isPerfect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tło perspektywiczne nawierzchni asfaltowej
    final roadTop = size.height * 0.64;
    final roadPaint = Paint()..color = AppColors.surfaceLight;
    canvas.drawRect(
      Rect.fromLTWH(0, roadTop, size.width, size.height - roadTop),
      roadPaint,
    );

    // Biała linia mety w rzucie 3D (ukośna kreska po prawej stronie)
    final finishX = size.width * 0.80;
    final finishLinePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.9)
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(finishX - 8, roadTop),
      Offset(finishX + 8, size.height),
      finishLinePaint,
    );

    // Złoty / zielony błysk przy maksymalnym rzucie +28 cm
    if (isPerfect && extensionFraction > 0.1) {
      final glowPaint = Paint()
        ..color = AppColors.statusSuccess.withValues(
          alpha: 0.28 * extensionFraction,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(
        Offset(finishX, size.height * 0.56),
        22 * extensionFraction,
        glowPaint,
      );
    }

    // Pozycja roweru przesuwająca się do przodu wraz z wyrzutem (+28 cm)
    final approachRatio = (1.0 - (distanceToFinishMeters.clamp(0.0, 150.0) / 150.0));
    final baseCenterX = size.width * (0.24 + 0.36 * approachRatio);
    final lungeShiftPx = extensionFraction * (size.width * 0.16);
    final bikeCenterX = baseCenterX + lungeShiftPx;
    final groundY = size.height * 0.78;
    final wheelRadius = size.height * 0.14;

    final rearWheelCenter = Offset(bikeCenterX - 24, groundY - wheelRadius);
    final frontWheelCenter = Offset(bikeCenterX + 24, groundY - wheelRadius);

    // Cień pod rowerem
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bikeCenterX, groundY + 2),
        width: 58,
        height: 6,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Koła 3D (obręcze z połyskiem)
    final wheelPaint = Paint()
      ..color = bikeColor == AppColors.background
          ? AppColors.textSecondary
          : bikeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(rearWheelCenter, wheelRadius, wheelPaint);
    canvas.drawCircle(frontWheelCenter, wheelRadius, wheelPaint);

    // Rama roweru wypchnięta do przodu
    final framePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final bb = Offset(bikeCenterX - 4, groundY - wheelRadius);
    final seatCluster = Offset(bikeCenterX - 11, groundY - wheelRadius * 2.2);
    final headTube = Offset(bikeCenterX + 14, groundY - wheelRadius * 2.15);

    canvas.drawLine(rearWheelCenter, bb, framePaint);
    canvas.drawLine(rearWheelCenter, seatCluster, framePaint);
    canvas.drawLine(bb, seatCluster, framePaint);
    canvas.drawLine(seatCluster, headTube, framePaint);
    canvas.drawLine(bb, headTube, framePaint);
    canvas.drawLine(headTube, frontWheelCenter, framePaint);

    // Sylwetka kolarza (podczas wyrzutu biodra cofają się za siodełko, ramiona wyprostowane)
    final hipBackShift = extensionFraction * 11.0;
    final hip = Offset(
      seatCluster.dx - 4 - hipBackShift,
      seatCluster.dy - 5 + (extensionFraction * 3.0),
    );
    final shoulder = Offset(
      hip.dx + 14,
      hip.dy - 9 + (extensionFraction * 4.0),
    );
    final handlebar = Offset(headTube.dx + 3, headTube.dy - 2);

    final riderPaint = Paint()
      ..color = jerseyColor
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hip, shoulder, riderPaint);

    final armPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(shoulder, handlebar, armPaint);

    // Kask
    canvas.drawCircle(
      Offset(shoulder.dx + 5, shoulder.dy - 4),
      4.5,
      Paint()..color = AppColors.textPrimary,
    );

    // Linie pędu podczas wyrzutu
    if (extensionFraction > 0.05) {
      final speedLinePaint = Paint()
        ..color = (isPerfect ? AppColors.statusSuccess : AppColors.cyanAccent)
            .withValues(alpha: 0.7 * extensionFraction)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = size.height * (0.28 + i * 0.16);
        canvas.drawLine(
          Offset(rearWheelCenter.dx - 26 - (i * 6), y),
          Offset(rearWheelCenter.dx - 8 - (i * 6), y),
          speedLinePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BikeThrow3dPreviewPainter oldDelegate) {
    return oldDelegate.extensionFraction != extensionFraction ||
        oldDelegate.distanceToFinishMeters != distanceToFinishMeters ||
        oldDelegate.isPerfect != isPerfect;
  }
}
