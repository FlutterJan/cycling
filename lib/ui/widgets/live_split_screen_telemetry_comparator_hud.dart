import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Tryb filtrowania metryk w porównywaczu Split-Screen na żywo.
enum SplitScreenMetricMode {
  /// Pełny przegląd wszystkich kluczowych parametrów fizjologicznych i tempa.
  overview('Przegląd', Icons.dashboard_rounded),

  /// Fokus na moc, W/kg, strefę Coggana Z1–Z7 oraz baterię beztlenową W'.
  powerAndWPrime('Moc & W\'', Icons.bolt_rounded),

  /// Fokus na VAM, prędkość, oszczędność aerodynamiczną i nachylenie.
  aeroAndClimbing('VAM & Aero', Icons.terrain_rounded);

  final String label;
  final IconData icon;

  const SplitScreenMetricMode(this.label, this.icon);
}

/// Telemetria pojedynczego kolarza (lidera lub rywala GC) w widoku Split-Screen.
@immutable
class SplitScreenRiderTelemetry {
  /// Unikalny identyfikator kolarza.
  final String riderId;

  /// Imię i nazwisko lub skrót telewizyjny (np. `T. POGAČAR`).
  final String riderName;

  /// Kod drużyny (np. `UAD`, `TVL`).
  final String teamShortCode;

  /// Kolor akcentu drużyny lub koszulki klasyfikacji.
  final Color accentColor;

  /// Numer startowy kolarza.
  final int? bibNumber;

  /// Aktualna pozycja w klasyfikacji generalnej (GC).
  final int gcPosition;

  /// Czy kolarz należy do drużyny gracza.
  final bool isPlayerRider;

  /// Czy kolarz jedzie w koszulce lidera klasyfikacji generalnej.
  final bool isYellowJersey;

  /// Chwilowa moc [W].
  final double powerWatts;

  /// Próg mleczanowy FTP [W].
  final double ftpWatts;

  /// Masa ciała [kg].
  final double riderWeightKg;

  /// Kadencja pedałowania [RPM].
  final int cadenceRpm;

  /// Aktualne tętno [BPM].
  final int heartRateBpm;

  /// Maksymalne tętno [BPM].
  final int maxHeartRateBpm;

  /// Prędkość chwilowa [km/h].
  final double speedKmh;

  /// Prędkość wznoszenia VAM [m/h].
  final double vamMetersPerHour;

  /// Pozostała energia beztlenowa $W'$ [kJ].
  final double wPrimeRemainingKj;

  /// Maksymalna pojemność beztlenowa $W'$ [kJ].
  final double wPrimeMaxKj;

  /// Oszczędność aerodynamiczna z draftu [%].
  final double aerodynamicDraftPercent;

  /// Nachylenie pod kolarzem [%].
  final double gradientPercent;

  /// Dystans pozostały do mety [km].
  final double distanceToFinishKm;

  /// Historia mocy [W] do wykresu Dual-Trace na żywo.
  final List<double> powerHistoryWatts;

  /// Czy kolarz jest w trakcie aktywnego ataku.
  final bool isAttacking;

  /// Czy kolarz wykazuje oznaki kryzysu energetycznego ("bonk").
  final bool isCracking;

  /// Czy transmisja telemetryczna dla tego kolarza jest aktywna.
  final bool hasLiveTelemetry;

  const SplitScreenRiderTelemetry({
    required this.riderId,
    required this.riderName,
    required this.teamShortCode,
    this.accentColor = AppColors.goldAccent,
    this.bibNumber,
    this.gcPosition = 1,
    this.isPlayerRider = false,
    this.isYellowJersey = false,
    required this.powerWatts,
    this.ftpWatts = 400.0,
    this.riderWeightKg = 65.0,
    required this.cadenceRpm,
    required this.heartRateBpm,
    this.maxHeartRateBpm = 195,
    required this.speedKmh,
    this.vamMetersPerHour = 0.0,
    required this.wPrimeRemainingKj,
    this.wPrimeMaxKj = 22.0,
    this.aerodynamicDraftPercent = 0.0,
    this.gradientPercent = 0.0,
    this.distanceToFinishKm = 0.0,
    this.powerHistoryWatts = const <double>[],
    this.isAttacking = false,
    this.isCracking = false,
    this.hasLiveTelemetry = true,
  });

  /// Bezpieczna moc chwilowa [W].
  double get safePowerWatts {
    if (powerWatts.isNaN || powerWatts.isInfinite) return 0.0;
    return math.max(0.0, powerWatts);
  }

  /// Bezpieczne FTP [W].
  double get safeFtpWatts {
    if (ftpWatts.isNaN || ftpWatts.isInfinite || ftpWatts <= 40.0) return 380.0;
    return ftpWatts;
  }

  /// Bezpieczna masa ciała [kg].
  double get safeWeightKg {
    if (riderWeightKg.isNaN || riderWeightKg.isInfinite || riderWeightKg <= 35.0) {
      return 65.0;
    }
    return riderWeightKg;
  }

  /// Moc względna [W/kg].
  double get wattsPerKg => safePowerWatts / safeWeightKg;

  /// Udział mocy względem FTP (np. 1.05 = 105% FTP).
  double get ftpRatio => safePowerWatts / safeFtpWatts;

  /// Procent FTP (0–250%).
  int get ftpPercent => (ftpRatio * 100.0).round().clamp(0, 250);

  /// Strefa mocy Coggana (1–7).
  int get powerZone {
    final double pct = ftpRatio * 100.0;
    if (pct < 55.0) return 1;
    if (pct < 76.0) return 2;
    if (pct < 91.0) return 3;
    if (pct < 106.0) return 4;
    if (pct < 121.0) return 5;
    if (pct < 151.0) return 6;
    return 7;
  }

  /// Bezpieczna kadencja [RPM].
  int get safeCadenceRpm => cadenceRpm.clamp(0, 180);

  /// Bezpieczne tętno [BPM].
  int get safeHeartRateBpm => heartRateBpm.clamp(0, 240);

  /// Bezpieczne tętno maksymalne [BPM].
  int get safeMaxHeartRateBpm =>
      maxHeartRateBpm <= 0 ? 195 : maxHeartRateBpm.clamp(100, 240);

  /// Procent tętna maksymalnego (0–100%).
  int get heartRatePercent =>
      ((safeHeartRateBpm / safeMaxHeartRateBpm) * 100.0).round().clamp(0, 100);

  /// Bezpieczna maksymalna pojemność $W'$ [kJ].
  double get safeWPrimeMaxKj {
    if (wPrimeMaxKj.isNaN || wPrimeMaxKj.isInfinite || wPrimeMaxKj <= 1.0) {
      return 22.0;
    }
    return wPrimeMaxKj;
  }

  /// Bezpieczna pozostała pojemność $W'$ [kJ].
  double get safeWPrimeRemainingKj {
    if (wPrimeRemainingKj.isNaN || wPrimeRemainingKj.isInfinite) return 0.0;
    return wPrimeRemainingKj.clamp(0.0, safeWPrimeMaxKj);
  }

  /// Ułamek pozostałego $W'$ (0.0–1.0).
  double get wPrimeFraction =>
      (safeWPrimeRemainingKj / safeWPrimeMaxKj).clamp(0.0, 1.0);

  /// Procent pozostałego $W'$ (0–100%).
  int get wPrimePercent => (wPrimeFraction * 100.0).round().clamp(0, 100);

  /// Bezpieczna prędkość [km/h].
  double get safeSpeedKmh {
    if (speedKmh.isNaN || speedKmh.isInfinite) return 0.0;
    return speedKmh.clamp(0.0, 130.0);
  }

  /// Bezpieczny VAM [m/h].
  double get safeVam {
    if (vamMetersPerHour.isNaN || vamMetersPerHour.isInfinite) return 0.0;
    return vamMetersPerHour.clamp(0.0, 3500.0);
  }

  /// Bezpieczny draft aerodynamiczny [%].
  double get safeDraftPercent {
    if (aerodynamicDraftPercent.isNaN || aerodynamicDraftPercent.isInfinite) {
      return 0.0;
    }
    return aerodynamicDraftPercent.clamp(0.0, 100.0);
  }
}

/// Zbiorczy model porównania Split-Screen lidera i głównego rywala GC na żywo.
@immutable
class SplitScreenTelemetryComparisonData {
  /// Telemetria lidera klasyfikacji lub wyścigu.
  final SplitScreenRiderTelemetry leader;

  /// Telemetria głównego rywala GC.
  final SplitScreenRiderTelemetry rival;

  /// Różnica czasu na etapie [s] (> 0 oznacza przewagę lidera na trasie).
  final double liveStageGapSeconds;

  /// Wirtualna różnica w klasyfikacji generalnej GC [s] (> 0 lider prowadzi).
  final double gcOverallGapSeconds;

  /// Tempo zmiany różnicy czasowej [s/km] (< 0 rywal odrabia, > 0 lider odjeżdża).
  final double gapTrendSecondsPerKm;

  /// Nazwa aktualnego etapu.
  final String stageName;

  /// Opcjonalna nazwa aktualnego podjazdu lub sektora.
  final String? climbName;

  /// Czy transmisja na żywo jest aktywna.
  final bool isLiveFeedActive;

  /// Czy symulacja jest aktualnie wstrzymana.
  final bool isPaused;

  const SplitScreenTelemetryComparisonData({
    required this.leader,
    required this.rival,
    required this.liveStageGapSeconds,
    required this.gcOverallGapSeconds,
    this.gapTrendSecondsPerKm = 0.0,
    this.stageName = 'Etap Górski',
    this.climbName,
    this.isLiveFeedActive = true,
    this.isPaused = false,
  });

  /// Przykładowe dane telemetryczne do podglądu lub testów integracyjnych.
  factory SplitScreenTelemetryComparisonData.sample() {
    return const SplitScreenTelemetryComparisonData(
      stageName: 'Etap 17 • Col du Galibier',
      climbName: 'Col du Galibier (HC • 8.4%)',
      liveStageGapSeconds: 18.4,
      gcOverallGapSeconds: 42.0,
      gapTrendSecondsPerKm: -1.6,
      leader: SplitScreenRiderTelemetry(
        riderId: 'leader_1',
        riderName: 'T. POGAČAR',
        teamShortCode: 'UAD',
        accentColor: AppColors.goldAccent,
        bibNumber: 1,
        gcPosition: 1,
        isPlayerRider: true,
        isYellowJersey: true,
        powerWatts: 418,
        ftpWatts: 415,
        riderWeightKg: 66.0,
        cadenceRpm: 94,
        heartRateBpm: 176,
        maxHeartRateBpm: 194,
        speedKmh: 24.6,
        vamMetersPerHour: 1740,
        wPrimeRemainingKj: 13.8,
        wPrimeMaxKj: 22.0,
        aerodynamicDraftPercent: 14.0,
        gradientPercent: 8.4,
        distanceToFinishKm: 6.2,
        powerHistoryWatts: <double>[390, 405, 410, 422, 415, 430, 425, 418],
      ),
      rival: SplitScreenRiderTelemetry(
        riderId: 'rival_2',
        riderName: 'J. VINGEGAARD',
        teamShortCode: 'TVL',
        accentColor: AppColors.accentBlue,
        bibNumber: 11,
        gcPosition: 2,
        isPlayerRider: false,
        isYellowJersey: false,
        powerWatts: 432,
        ftpWatts: 410,
        riderWeightKg: 60.0,
        cadenceRpm: 98,
        heartRateBpm: 181,
        maxHeartRateBpm: 196,
        speedKmh: 25.4,
        vamMetersPerHour: 1815,
        wPrimeRemainingKj: 9.4,
        wPrimeMaxKj: 21.0,
        aerodynamicDraftPercent: 8.0,
        gradientPercent: 8.6,
        distanceToFinishKm: 6.3,
        powerHistoryWatts: <double>[395, 402, 418, 440, 445, 438, 435, 432],
        isAttacking: true,
      ),
    );
  }
}

/// Obliczone różnice head-to-head pomiędzy lewą i prawą stroną Split-Screen.
@immutable
class SplitScreenComparisonDelta {
  final double powerDeltaWatts;
  final double wattsPerKgDelta;
  final int cadenceDeltaRpm;
  final int heartRateDeltaBpm;
  final int wPrimePercentDelta;
  final double speedDeltaKmh;
  final double vamDelta;

  const SplitScreenComparisonDelta({
    required this.powerDeltaWatts,
    required this.wattsPerKgDelta,
    required this.cadenceDeltaRpm,
    required this.heartRateDeltaBpm,
    required this.wPrimePercentDelta,
    required this.speedDeltaKmh,
    required this.vamDelta,
  });

  factory SplitScreenComparisonDelta.compute(
    SplitScreenRiderTelemetry left,
    SplitScreenRiderTelemetry right,
  ) {
    return SplitScreenComparisonDelta(
      powerDeltaWatts: left.safePowerWatts - right.safePowerWatts,
      wattsPerKgDelta: left.wattsPerKg - right.wattsPerKg,
      cadenceDeltaRpm: left.safeCadenceRpm - right.safeCadenceRpm,
      heartRateDeltaBpm: left.safeHeartRateBpm - right.safeHeartRateBpm,
      wPrimePercentDelta: left.wPrimePercent - right.wPrimePercent,
      speedDeltaKmh: left.safeSpeedKmh - right.safeSpeedKmh,
      vamDelta: left.safeVam - right.safeVam,
    );
  }
}

/// Produkcyjny porównywacz telemetrii Split-Screen lidera i głównego rywala GC na żywo.
///
/// Obsługuje pełne stany `hover` / `active` / `disabled` / `focus`, płynne animacje
/// `200–350ms` (`Curves.easeOutCubic`), wykres Dual-Trace mocy oraz responsywny układ
/// `LayoutBuilder` dla `390x844`, `1024x768` i `1600x900`.
class LiveSplitScreenTelemetryComparatorHud extends StatefulWidget {
  /// Dane telemetryczne obu kolarzy i różnice czasowe.
  final SplitScreenTelemetryComparisonData data;

  /// Czy widget jest aktywny (false wyświetla stan zablokowany/disabled).
  final bool isEnabled;

  /// Początkowy tryb filtrowania metryk.
  final SplitScreenMetricMode initialMetricMode;

  /// Callback po kliknięciu wybranego kolarza (np. fokus kamery 3D).
  final ValueChanged<SplitScreenRiderTelemetry>? onFocusRider;

  /// Callback po zmianie trybu metryk.
  final ValueChanged<SplitScreenMetricMode>? onMetricModeChanged;

  /// Callback po zamianie stron Split-Screen.
  final VoidCallback? onSwapSides;

  /// Opcjonalny callback zamknięcia lub zminimalizowania HUD.
  final VoidCallback? onClose;

  const LiveSplitScreenTelemetryComparatorHud({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.initialMetricMode = SplitScreenMetricMode.overview,
    this.onFocusRider,
    this.onMetricModeChanged,
    this.onSwapSides,
    this.onClose,
  });

  @override
  State<LiveSplitScreenTelemetryComparatorHud> createState() =>
      _LiveSplitScreenTelemetryComparatorHudState();
}

class _LiveSplitScreenTelemetryComparatorHudState
    extends State<LiveSplitScreenTelemetryComparatorHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _livePulseController;
  late SplitScreenMetricMode _metricMode;
  bool _isSwapped = false;
  String? _selectedRiderId;

  @override
  void initState() {
    super.initState();
    _metricMode = widget.initialMetricMode;
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.data.isLiveFeedActive && !widget.data.isPaused) {
      _livePulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(
    covariant LiveSplitScreenTelemetryComparatorHud oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    final bool shouldAnimate =
        widget.isEnabled && widget.data.isLiveFeedActive && !widget.data.isPaused;
    if (shouldAnimate && !_livePulseController.isAnimating) {
      _livePulseController.repeat(reverse: true);
    } else if (!shouldAnimate && _livePulseController.isAnimating) {
      _livePulseController.stop();
    }
  }

  @override
  void dispose() {
    _livePulseController.dispose();
    super.dispose();
  }

  void _handleSwapSides() {
    if (!widget.isEnabled) return;
    setState(() {
      _isSwapped = !_isSwapped;
    });
    widget.onSwapSides?.call();
  }

  void _handleSelectMetricMode(SplitScreenMetricMode mode) {
    if (!widget.isEnabled || _metricMode == mode) return;
    setState(() {
      _metricMode = mode;
    });
    widget.onMetricModeChanged?.call(mode);
  }

  void _handleFocusRider(SplitScreenRiderTelemetry rider) {
    if (!widget.isEnabled || !rider.hasLiveTelemetry) return;
    setState(() {
      _selectedRiderId = rider.riderId;
    });
    widget.onFocusRider?.call(rider);
  }

  @override
  Widget build(BuildContext context) {
    final SplitScreenRiderTelemetry leftRider =
        _isSwapped ? widget.data.rival : widget.data.leader;
    final SplitScreenRiderTelemetry rightRider =
        _isSwapped ? widget.data.leader : widget.data.rival;
    final SplitScreenComparisonDelta delta =
        SplitScreenComparisonDelta.compute(leftRider, rightRider);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool isMobile = width < 620;
        final bool isDesktop = width >= 1100;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          opacity: widget.isEnabled ? 1.0 : 0.55,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderColor,
                width: 1.0,
              ),
            ),
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildTopHeader(isMobile: isMobile),
                const SizedBox(height: 12),
                _buildGcGapBanner(
                  leftRider: leftRider,
                  rightRider: rightRider,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 12),
                if (isMobile)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _RiderSplitCard(
                        rider: leftRider,
                        isLeftSide: true,
                        isSelected: _selectedRiderId == leftRider.riderId,
                        isEnabled: widget.isEnabled,
                        isCompact: true,
                        metricMode: _metricMode,
                        onTap: () => _handleFocusRider(leftRider),
                      ),
                      const SizedBox(height: 10),
                      _RiderSplitCard(
                        rider: rightRider,
                        isLeftSide: false,
                        isSelected: _selectedRiderId == rightRider.riderId,
                        isEnabled: widget.isEnabled,
                        isCompact: true,
                        metricMode: _metricMode,
                        onTap: () => _handleFocusRider(rightRider),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _RiderSplitCard(
                          rider: leftRider,
                          isLeftSide: true,
                          isSelected: _selectedRiderId == leftRider.riderId,
                          isEnabled: widget.isEnabled,
                          isCompact: !isDesktop,
                          metricMode: _metricMode,
                          onTap: () => _handleFocusRider(leftRider),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RiderSplitCard(
                          rider: rightRider,
                          isLeftSide: false,
                          isSelected: _selectedRiderId == rightRider.riderId,
                          isEnabled: widget.isEnabled,
                          isCompact: !isDesktop,
                          metricMode: _metricMode,
                          onTap: () => _handleFocusRider(rightRider),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _buildHeadToHeadDeltaMatrix(
                  leftRider: leftRider,
                  rightRider: rightRider,
                  delta: delta,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 12),
                _buildDualPowerSparklineCard(
                  leftRider: leftRider,
                  rightRider: rightRider,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeader({required bool isMobile}) {
    final bool isLive =
        widget.isEnabled && widget.data.isLiveFeedActive && !widget.data.isPaused;

    final Widget liveBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive
              ? AppColors.crimsonAlert.withValues(alpha: 0.55)
              : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: _livePulseController,
            builder: (BuildContext context, Widget? child) {
              final double pulse =
                  isLive ? (0.45 + 0.55 * _livePulseController.value) : 0.4;
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLive
                      ? AppColors.crimsonAlert.withValues(alpha: pulse)
                      : AppColors.textSecondary,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            widget.data.isPaused
                ? 'PAUZA'
                : (isLive ? 'LIVE SPLIT-SCREEN' : 'OFFLINE'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    final Widget modeSelector = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: SplitScreenMetricMode.values.map((SplitScreenMetricMode mode) {
        return _InteractivePillButton(
          label: mode.label,
          icon: mode.icon,
          isSelected: _metricMode == mode,
          isEnabled: widget.isEnabled,
          onTap: () => _handleSelectMetricMode(mode),
        );
      }).toList(),
    );

    final Widget actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _InteractiveIconButton(
          tooltip: 'Zamień strony Split-Screen',
          icon: Icons.swap_horiz_rounded,
          isEnabled: widget.isEnabled,
          onTap: _handleSwapSides,
        ),
        if (widget.onClose != null) ...<Widget>[
          const SizedBox(width: 6),
          _InteractiveIconButton(
            tooltip: 'Zamknij porównywacz',
            icon: Icons.close_rounded,
            isEnabled: widget.isEnabled,
            onTap: widget.onClose!,
          ),
        ],
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              liveBadge,
              const Spacer(),
              actionButtons,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.data.climbName ?? widget.data.stageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          modeSelector,
        ],
      );
    }

    return Row(
      children: <Widget>[
        liveBadge,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.data.stageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.data.climbName != null)
                Text(
                  widget.data.climbName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.goldAccent,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        modeSelector,
        const SizedBox(width: 10),
        actionButtons,
      ],
    );
  }

  Widget _buildGcGapBanner({
    required SplitScreenRiderTelemetry leftRider,
    required SplitScreenRiderTelemetry rightRider,
    required bool isMobile,
  }) {
    final double stageGap = widget.data.liveStageGapSeconds;
    final double gcGap = widget.data.gcOverallGapSeconds;
    final double trend = widget.data.gapTrendSecondsPerKm;

    final bool rivalClosing = trend < -0.15;
    final bool leaderExtending = trend > 0.15;
    final Color trendColor = rivalClosing
        ? AppColors.amberWarning
        : (leaderExtending ? AppColors.statusSuccess : AppColors.textSecondary);
    final IconData trendIcon = rivalClosing
        ? Icons.trending_down_rounded
        : (leaderExtending
            ? Icons.trending_up_rounded
            : Icons.trending_flat_rounded);

    final String trendLabel = trend.abs() < 0.05
        ? 'Stabilnie (0.0 s/km)'
        : '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)} s/km';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _GapStatChip(
            label: 'RÓŻNICA NA TRASIE',
            value: _formatGapSeconds(stageGap),
            valueColor: stageGap >= 0
                ? AppColors.goldAccent
                : AppColors.accentBlue,
          ),
          _GapStatChip(
            label: 'WIRTUALNE GC',
            value: _formatGapSeconds(gcGap),
            valueColor: AppColors.textPrimary,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(trendIcon, size: 16, color: trendColor),
              const SizedBox(width: 5),
              Text(
                trendLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: trendColor,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          Text(
            '${leftRider.teamShortCode} vs ${rightRider.teamShortCode}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadToHeadDeltaMatrix({
    required SplitScreenRiderTelemetry leftRider,
    required SplitScreenRiderTelemetry rightRider,
    required SplitScreenComparisonDelta delta,
    required bool isMobile,
  }) {
    final List<Widget> rows = <Widget>[];

    if (_metricMode == SplitScreenMetricMode.overview ||
        _metricMode == SplitScreenMetricMode.powerAndWPrime) {
      rows.add(
        _HeadToHeadDeltaRow(
          label: 'Moc względna',
          leftValueText: '${leftRider.wattsPerKg.toStringAsFixed(2)} W/kg',
          rightValueText: '${rightRider.wattsPerKg.toStringAsFixed(2)} W/kg',
          leftMagnitude: leftRider.wattsPerKg,
          rightMagnitude: rightRider.wattsPerKg,
          leftColor: leftRider.accentColor,
          rightColor: rightRider.accentColor,
          deltaText:
              '${delta.wattsPerKgDelta >= 0 ? '+' : ''}${delta.wattsPerKgDelta.toStringAsFixed(2)}',
          isCompact: isMobile,
        ),
      );
      rows.add(
        _HeadToHeadDeltaRow(
          label: 'Moc chwilowa',
          leftValueText: '${leftRider.safePowerWatts.round()} W',
          rightValueText: '${rightRider.safePowerWatts.round()} W',
          leftMagnitude: leftRider.safePowerWatts,
          rightMagnitude: rightRider.safePowerWatts,
          leftColor: leftRider.accentColor,
          rightColor: rightRider.accentColor,
          deltaText:
              '${delta.powerDeltaWatts >= 0 ? '+' : ''}${delta.powerDeltaWatts.round()} W',
          isCompact: isMobile,
        ),
      );
      rows.add(
        _HeadToHeadDeltaRow(
          label: 'Rezerwa W\'',
          leftValueText: '${leftRider.wPrimePercent}%',
          rightValueText: '${rightRider.wPrimePercent}%',
          leftMagnitude: leftRider.wPrimePercent.toDouble(),
          rightMagnitude: rightRider.wPrimePercent.toDouble(),
          leftColor: leftRider.accentColor,
          rightColor: rightRider.accentColor,
          deltaText:
              '${delta.wPrimePercentDelta >= 0 ? '+' : ''}${delta.wPrimePercentDelta}%',
          isCompact: isMobile,
        ),
      );
    }

    if (_metricMode == SplitScreenMetricMode.overview ||
        _metricMode == SplitScreenMetricMode.aeroAndClimbing) {
      rows.add(
        _HeadToHeadDeltaRow(
          label: 'VAM (wspinaczka)',
          leftValueText: '${leftRider.safeVam.round()} m/h',
          rightValueText: '${rightRider.safeVam.round()} m/h',
          leftMagnitude: leftRider.safeVam,
          rightMagnitude: rightRider.safeVam,
          leftColor: leftRider.accentColor,
          rightColor: rightRider.accentColor,
          deltaText:
              '${delta.vamDelta >= 0 ? '+' : ''}${delta.vamDelta.round()}',
          isCompact: isMobile,
        ),
      );
      rows.add(
        _HeadToHeadDeltaRow(
          label: 'Prędkość',
          leftValueText: '${leftRider.safeSpeedKmh.toStringAsFixed(1)} km/h',
          rightValueText: '${rightRider.safeSpeedKmh.toStringAsFixed(1)} km/h',
          leftMagnitude: leftRider.safeSpeedKmh,
          rightMagnitude: rightRider.safeSpeedKmh,
          leftColor: leftRider.accentColor,
          rightColor: rightRider.accentColor,
          deltaText:
              '${delta.speedDeltaKmh >= 0 ? '+' : ''}${delta.speedDeltaKmh.toStringAsFixed(1)}',
          isCompact: isMobile,
        ),
      );
    }

    if (_metricMode == SplitScreenMetricMode.overview) {
      rows.add(
        _HeadToHeadDeltaRow(
          label: 'Kadencja / HR',
          leftValueText:
              '${leftRider.safeCadenceRpm} rpm • ${leftRider.safeHeartRateBpm}',
          rightValueText:
              '${rightRider.safeCadenceRpm} rpm • ${rightRider.safeHeartRateBpm}',
          leftMagnitude: leftRider.safeCadenceRpm.toDouble(),
          rightMagnitude: rightRider.safeCadenceRpm.toDouble(),
          leftColor: leftRider.accentColor,
          rightColor: rightRider.accentColor,
          deltaText:
              '${delta.cadenceDeltaRpm >= 0 ? '+' : ''}${delta.cadenceDeltaRpm} rpm',
          isCompact: isMobile,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'PORÓWNANIE HEAD-TO-HEAD NA ŻYWO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            rows[i],
            if (i < rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildDualPowerSparklineCard({
    required SplitScreenRiderTelemetry leftRider,
    required SplitScreenRiderTelemetry rightRider,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'PRZEBIEG MOCY DUAL-TRACE [W]',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _LegendDot(
                color: leftRider.accentColor,
                label: leftRider.riderName,
              ),
              const SizedBox(width: 10),
              _LegendDot(
                color: rightRider.accentColor,
                label: rightRider.riderName,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: isMobile ? 58 : 72,
            child: CustomPaint(
              painter: _DualPowerSparklinePainter(
                leftSeries: leftRider.powerHistoryWatts,
                rightSeries: rightRider.powerHistoryWatts,
                leftColor: leftRider.accentColor,
                rightColor: rightRider.accentColor,
                referenceFtpWatts:
                    (leftRider.safeFtpWatts + rightRider.safeFtpWatts) * 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatGapSeconds(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '0.0 s';
    final String sign = seconds > 0.05 ? '+' : (seconds < -0.05 ? '-' : '');
    final double absVal = seconds.abs();
    if (absVal < 60.0) {
      return '$sign${absVal.toStringAsFixed(1)} s';
    }
    final int mins = absVal ~/ 60;
    final int secs = (absVal % 60).round();
    return '$sign$mins:${secs.toString().padLeft(2, '0')}';
  }
}

class _RiderSplitCard extends StatefulWidget {
  final SplitScreenRiderTelemetry rider;
  final bool isLeftSide;
  final bool isSelected;
  final bool isEnabled;
  final bool isCompact;
  final SplitScreenMetricMode metricMode;
  final VoidCallback onTap;

  const _RiderSplitCard({
    required this.rider,
    required this.isLeftSide,
    required this.isSelected,
    required this.isEnabled,
    required this.isCompact,
    required this.metricMode,
    required this.onTap,
  });

  @override
  State<_RiderSplitCard> createState() => _RiderSplitCardState();
}

class _RiderSplitCardState extends State<_RiderSplitCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _interactive => widget.isEnabled && widget.rider.hasLiveTelemetry;

  @override
  Widget build(BuildContext context) {
    final SplitScreenRiderTelemetry r = widget.rider;
    final Color zoneColor = AppColors.getPowerZoneColor(r.powerZone);
    final Color wPrimeColor = r.wPrimeFraction >= 0.55
        ? AppColors.statusSuccess
        : (r.wPrimeFraction >= 0.25
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);

    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : (widget.isSelected
            ? r.accentColor
            : (_isHovered && _interactive
                ? r.accentColor.withValues(alpha: 0.75)
                : AppColors.cardBorder));

    final Color surfaceColor = _isPressed && _interactive
        ? AppColors.surfaceLight.withValues(alpha: 0.9)
        : (_isHovered && _interactive
            ? AppColors.surfaceLight
            : AppColors.background);

    return Focus(
      canRequestFocus: _interactive,
      onFocusChange: (bool focused) {
        if (mounted) {
          setState(() => _isFocused = focused);
        }
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (_interactive &&
            event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor:
            _interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (mounted) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted) {
            setState(() {
              _isHovered = false;
              _isPressed = false;
            });
          }
        },
        child: GestureDetector(
          onTapDown: _interactive
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: _interactive
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onTap();
                }
              : null,
          onTapCancel: _interactive
              ? () => setState(() => _isPressed = false)
              : null,
          child: AnimatedScale(
            scale: _isPressed && _interactive ? 0.985 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(widget.isCompact ? 10 : 12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused || widget.isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: r.accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    r.riderName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (r.isYellowJersey) ...<Widget>[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    size: 14,
                                    color: AppColors.goldAccent,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'GC #${r.gcPosition} • ${r.teamShortCode}'
                              '${r.bibNumber != null ? ' • #${r.bibNumber}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusBadge(rider: r, zoneColor: zoneColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!r.hasLiveTelemetry)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'BRAK SYGNAŁU TELEMETRII',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else ...<Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _TelemetryCell(
                          label: 'MOC',
                          value: '${r.safePowerWatts.round()} W',
                          subValue:
                              '${r.wattsPerKg.toStringAsFixed(2)} W/kg (${r.ftpPercent}%)',
                          accentColor: zoneColor,
                        ),
                        _TelemetryCell(
                          label: 'TĘTNO',
                          value: '${r.safeHeartRateBpm} bpm',
                          subValue: '${r.heartRatePercent}% HRmax',
                          accentColor: r.heartRatePercent >= 92
                              ? AppColors.crimsonAlert
                              : AppColors.textPrimary,
                        ),
                        if (widget.metricMode !=
                            SplitScreenMetricMode.aeroAndClimbing)
                          _TelemetryCell(
                            label: 'KADENCJA',
                            value: '${r.safeCadenceRpm} rpm',
                            subValue: 'Strefa Z${r.powerZone}',
                            accentColor: AppColors.cyanAccent,
                          ),
                        if (widget.metricMode !=
                            SplitScreenMetricMode.powerAndWPrime)
                          _TelemetryCell(
                            label: 'VAM / PRĘDK.',
                            value: '${r.safeVam.round()} m/h',
                            subValue:
                                '${r.safeSpeedKmh.toStringAsFixed(1)} km/h • Draft ${r.safeDraftPercent.round()}%',
                            accentColor: AppColors.accentBlue,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        const Text(
                          'Bateria W\'',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${r.safeWPrimeRemainingKj.toStringAsFixed(1)} / ${r.safeWPrimeMaxKj.toStringAsFixed(1)} kJ (${r.wPrimePercent}%)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: wPrimeColor,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: <Widget>[
                            Container(color: AppColors.surfaceLight),
                            AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              widthFactor: r.wPrimeFraction,
                              child: Container(color: wPrimeColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SplitScreenRiderTelemetry rider;
  final Color zoneColor;

  const _StatusBadge({
    required this.rider,
    required this.zoneColor,
  });

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color badgeColor;

    if (!rider.hasLiveTelemetry) {
      text = 'OFF';
      badgeColor = AppColors.textSecondary;
    } else if (rider.isCracking) {
      text = 'KRYZYS';
      badgeColor = AppColors.crimsonAlert;
    } else if (rider.isAttacking) {
      text = 'ATAK';
      badgeColor = AppColors.amberWarning;
    } else {
      text = 'Z${rider.powerZone}';
      badgeColor = zoneColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.55),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: badgeColor,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _TelemetryCell extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color accentColor;

  const _TelemetryCell({
    required this.label,
    required this.value,
    required this.subValue,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadToHeadDeltaRow extends StatelessWidget {
  final String label;
  final String leftValueText;
  final String rightValueText;
  final double leftMagnitude;
  final double rightMagnitude;
  final Color leftColor;
  final Color rightColor;
  final String deltaText;
  final bool isCompact;

  const _HeadToHeadDeltaRow({
    required this.label,
    required this.leftValueText,
    required this.rightValueText,
    required this.leftMagnitude,
    required this.rightMagnitude,
    required this.leftColor,
    required this.rightColor,
    required this.deltaText,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final double safeLeft = math.max(0.0, leftMagnitude);
    final double safeRight = math.max(0.0, rightMagnitude);
    final double total = safeLeft + safeRight;
    final double leftRatio = total <= 0.0001 ? 0.5 : (safeLeft / total).clamp(0.05, 0.95);
    final double rightRatio = 1.0 - leftRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                leftValueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: leftColor,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$label ($deltaText)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Text(
                rightValueText,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: rightColor,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 5,
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: (leftRatio * 1000).round(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    color: leftColor,
                  ),
                ),
                Container(width: 2, color: AppColors.background),
                Expanded(
                  flex: (rightRatio * 1000).round(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    color: rightColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GapStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _GapStatChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _InteractivePillButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.32)
        : (_isHovered && widget.isEnabled
            ? AppColors.surfaceLight
            : AppColors.background);

    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : (widget.isSelected
            ? AppColors.goldAccent
            : (_isHovered && widget.isEnabled
                ? AppColors.textSecondary
                : AppColors.cardBorder));

    final Color textColor = !widget.isEnabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isSelected ? AppColors.goldAccent : AppColors.textPrimary);

    return Focus(
      canRequestFocus: widget.isEnabled,
      onFocusChange: (bool focused) {
        if (mounted) setState(() => _isFocused = focused);
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (widget.isEnabled &&
            event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) {
          if (mounted) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted) {
            setState(() {
              _isHovered = false;
              _isPressed = false;
            });
          }
        },
        child: GestureDetector(
          onTapDown: widget.isEnabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.isEnabled
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onTap();
                }
              : null,
          onTapCancel: widget.isEnabled
              ? () => setState(() => _isPressed = false)
              : null,
          child: AnimatedScale(
            scale: _isPressed && widget.isEnabled ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(widget.icon, size: 13, color: textColor),
                  const SizedBox(width: 5),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textColor,
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
}

class _InteractiveIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _InteractiveIconButton({
    required this.tooltip,
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : (_isHovered && widget.isEnabled
            ? AppColors.textSecondary
            : AppColors.cardBorder);

    return Tooltip(
      message: widget.tooltip,
      child: Focus(
        canRequestFocus: widget.isEnabled,
        onFocusChange: (bool focused) {
          if (mounted) setState(() => _isFocused = focused);
        },
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (widget.isEnabled &&
              event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: widget.isEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) {
            if (mounted) setState(() => _isHovered = true);
          },
          onExit: (_) {
            if (mounted) {
              setState(() {
                _isHovered = false;
                _isPressed = false;
              });
            }
          },
          child: GestureDetector(
            onTapDown: widget.isEnabled
                ? (_) => setState(() => _isPressed = true)
                : null,
            onTapUp: widget.isEnabled
                ? (_) {
                    setState(() => _isPressed = false);
                    widget.onTap();
                  }
                : null,
            onTapCancel: widget.isEnabled
                ? () => setState(() => _isPressed = false)
                : null,
            child: AnimatedScale(
              scale: _isPressed && widget.isEnabled ? 0.94 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _isHovered && widget.isEnabled
                      ? AppColors.surfaceLight
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: _isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isEnabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rysuje wykres Dual-Trace mocy na żywo dla obu porównywanych kolarzy.
class _DualPowerSparklinePainter extends CustomPainter {
  final List<double> leftSeries;
  final List<double> rightSeries;
  final Color leftColor;
  final Color rightColor;
  final double referenceFtpWatts;

  const _DualPowerSparklinePainter({
    required this.leftSeries,
    required this.rightSeries,
    required this.leftColor,
    required this.rightColor,
    required this.referenceFtpWatts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final List<double> combined = <double>[
      ...leftSeries,
      ...rightSeries,
      referenceFtpWatts,
    ].where((double v) => v.isFinite && v >= 0).toList();

    if (combined.isEmpty) return;

    double minVal = combined.reduce(math.min);
    double maxVal = combined.reduce(math.max);
    if ((maxVal - minVal) < 40.0) {
      minVal = math.max(0.0, minVal - 20.0);
      maxVal = maxVal + 20.0;
    }
    final double range = math.max(1.0, maxVal - minVal);

    // Linia odniesienia FTP.
    final double ftpY =
        size.height - ((referenceFtpWatts - minVal) / range) * size.height;
    final Paint ftpPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1.0;
    const double dashWidth = 5.0;
    const double dashGap = 4.0;
    double x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, ftpY.clamp(0.0, size.height)),
        Offset(math.min(size.width, x + dashWidth), ftpY.clamp(0.0, size.height)),
        ftpPaint,
      );
      x += dashWidth + dashGap;
    }

    _drawSeries(canvas, size, rightSeries, rightColor, minVal, range);
    _drawSeries(canvas, size, leftSeries, leftColor, minVal, range);
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> series,
    Color color,
    double minVal,
    double range,
  ) {
    final List<double> clean =
        series.where((double v) => v.isFinite && v >= 0).toList();
    if (clean.length < 2) {
      if (clean.length == 1) {
        final double y =
            size.height - ((clean.first - minVal) / range) * size.height;
        canvas.drawCircle(
          Offset(size.width * 0.5, y.clamp(2.0, size.height - 2.0)),
          3.0,
          Paint()..color = color,
        );
      }
      return;
    }

    final ui.Path linePath = ui.Path();
    final ui.Path fillPath = ui.Path();
    for (int i = 0; i < clean.length; i++) {
      final double px = (i / (clean.length - 1)) * size.width;
      final double py =
          (size.height - ((clean[i] - minVal) / range) * size.height)
              .clamp(2.0, size.height - 2.0);
      if (i == 0) {
        linePath.moveTo(px, py);
        fillPath.moveTo(px, size.height);
        fillPath.lineTo(px, py);
      } else {
        linePath.lineTo(px, py);
        fillPath.lineTo(px, py);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        <Color>[
          color.withValues(alpha: 0.20),
          color.withValues(alpha: 0.0),
        ],
      );
    canvas.drawPath(fillPath, fillPaint);

    final Paint strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _DualPowerSparklinePainter oldDelegate) {
    return oldDelegate.leftSeries != leftSeries ||
        oldDelegate.rightSeries != rightSeries ||
        oldDelegate.leftColor != leftColor ||
        oldDelegate.rightColor != rightColor ||
        oldDelegate.referenceFtpWatts != referenceFtpWatts;
  }
}
