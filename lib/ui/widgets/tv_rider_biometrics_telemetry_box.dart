import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Stan obciążenia baterii beztlenowej $W'$ kolarza.
enum WPrimeBatteryStatus {
  /// Pełna lub wysoka rezerwa beztlenowa (>= 60%).
  optimal,

  /// Średni drenaż podczas mocnego tempa lub ataku (25%–59%).
  draining,

  /// Krytycznie niski poziom baterii (< 25%) — ryzyko "odcięcia".
  critical,

  /// Bateria na granicy wyczerpania (<= 5%).
  depleted,
}

/// Model danych biometrycznych kolarza dla telewizyjnego okienka [TvRiderBiometricsTelemetryBox].
@immutable
class TvRiderBiometricsData {
  /// Identyfikator kolarza.
  final String riderId;

  /// Imię i nazwisko kolarza (np. `T. POGAČAR` lub `R. EVENEPOEL`).
  final String riderName;

  /// Skrót drużyny (np. `UAD`, `TVL`, `SOQ`).
  final String teamShortCode;

  /// Numer startowy kolarza.
  final int? bibNumber;

  /// Aktualne tętno [BPM].
  final int heartRateBpm;

  /// Maksymalne tętno kolarza [BPM].
  final int maxHeartRateBpm;

  /// Chwilowa moc na pedałach [W].
  final double powerWatts;

  /// Próg mleczanowy FTP kolarza [W].
  final double ftpWatts;

  /// Masa ciała kolarza [kg] do wyliczenia W/kg.
  final double riderWeightKg;

  /// Aktualna kadencja pedałowania [RPM].
  final int cadenceRpm;

  /// Pozostała pojemność beztlenowa $W'_{bal}$ [kJ].
  final double wPrimeRemainingKj;

  /// Maksymalna pojemność beztlenowa $W'$ [kJ] (np. 20.0–28.0 kJ).
  final double wPrimeMaxKj;

  /// Chwilowe tempo zmiany $W'$ [kJ/s] (ujemne = drenaż, dodatnie = regeneracja).
  final double wPrimeDeltaKjPerSec;

  /// Opcjonalna historia ostatnich próbek tętna [BPM] do mini-trendu.
  final List<int> heartRateHistoryBpm;

  /// Czy kolarz jest w trakcie aktywnego ataku lub zrywu.
  final bool isAttacking;

  /// Czy transmisja biometrii na żywo jest aktywna (WHOOP / F1 LIVE).
  final bool isLiveFeedActive;

  const TvRiderBiometricsData({
    required this.riderId,
    required this.riderName,
    required this.teamShortCode,
    this.bibNumber,
    required this.heartRateBpm,
    this.maxHeartRateBpm = 195,
    required this.powerWatts,
    this.ftpWatts = 390.0,
    this.riderWeightKg = 67.0,
    required this.cadenceRpm,
    required this.wPrimeRemainingKj,
    this.wPrimeMaxKj = 22.0,
    this.wPrimeDeltaKjPerSec = 0.0,
    this.heartRateHistoryBpm = const <int>[],
    this.isAttacking = false,
    this.isLiveFeedActive = true,
  });

  /// Bezpieczna wartość tętna [BPM].
  int get safeHeartRateBpm => heartRateBpm.clamp(0, 240);

  /// Bezpieczne maksymalne tętno [BPM].
  int get safeMaxHeartRateBpm => maxHeartRateBpm <= 0 ? 195 : maxHeartRateBpm.clamp(100, 240);

  /// Udział aktualnego tętna względem HRmax (0.0–1.0).
  double get heartRateMaxFraction {
    if (safeMaxHeartRateBpm <= 0) return 0.0;
    return (safeHeartRateBpm / safeMaxHeartRateBpm).clamp(0.0, 1.0);
  }

  /// Procent maksymalnego tętna (0–100).
  int get heartRateMaxPercent => (heartRateMaxFraction * 100.0).round().clamp(0, 100);

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

  /// Moc względna [W/kg].
  double get wattsPerKg {
    if (riderWeightKg.isNaN || riderWeightKg.isInfinite || riderWeightKg <= 20.0) {
      return 0.0;
    }
    return safePowerWatts / riderWeightKg;
  }

  /// Strefa mocy Coggana (1–7).
  int get powerZone {
    final double ratio = safePowerWatts / safeFtpWatts;
    if (ratio < 0.55) return 1;
    if (ratio < 0.75) return 2;
    if (ratio < 0.90) return 3;
    if (ratio < 1.05) return 4;
    if (ratio < 1.20) return 5;
    if (ratio < 1.50) return 6;
    return 7;
  }

  /// Nazwa strefy mocy Coggana Z1–Z7.
  String get powerZoneName {
    switch (powerZone) {
      case 1:
        return 'RECOVERY';
      case 2:
        return 'ENDURANCE';
      case 3:
        return 'TEMPO';
      case 4:
        return 'THRESHOLD';
      case 5:
        return 'VO2 MAX';
      case 6:
        return 'ANAEROBIC';
      case 7:
        return 'NEUROMAX';
      default:
        return 'RECOVERY';
    }
  }

  /// Kolor strefy mocy Z1–Z7 z palety [AppColors].
  Color get powerZoneColor => AppColors.getPowerZoneColor(powerZone);

  /// Bezpieczna kadencja [RPM].
  int get safeCadenceRpm => cadenceRpm.clamp(0, 220);

  /// Etykieta rytmu kadencji.
  String get cadenceProfileLabel {
    if (safeCadenceRpm == 0) return 'COASTING';
    if (safeCadenceRpm < 70) return 'GRIND';
    if (safeCadenceRpm <= 98) return 'OPTIMAL';
    return 'HIGH SPIN';
  }

  /// Bezpieczna maksymalna pojemność $W'$ [kJ].
  double get safeWPrimeMaxKj {
    if (wPrimeMaxKj.isNaN || wPrimeMaxKj.isInfinite || wPrimeMaxKj <= 0.0) {
      return 0.0;
    }
    return wPrimeMaxKj;
  }

  /// Bezpieczna pozostała pojemność $W'_{bal}$ [kJ].
  double get safeWPrimeRemainingKj {
    if (wPrimeRemainingKj.isNaN || wPrimeRemainingKj.isInfinite) return 0.0;
    if (safeWPrimeMaxKj <= 0.0) return math.max(0.0, wPrimeRemainingKj);
    return wPrimeRemainingKj.clamp(0.0, safeWPrimeMaxKj);
  }

  /// Udział pozostałej baterii beztlenowej $W'$ (0.0–1.0).
  double get wPrimeFraction {
    if (safeWPrimeMaxKj <= 0.0) return 0.0;
    return (safeWPrimeRemainingKj / safeWPrimeMaxKj).clamp(0.0, 1.0);
  }

  /// Procent pozostałej baterii $W'$ (0–100).
  int get wPrimePercent => (wPrimeFraction * 100.0).round().clamp(0, 100);

  /// Bezpieczne tempo zmiany $W'$ [kJ/s].
  double get safeWPrimeDeltaKjPerSec {
    if (wPrimeDeltaKjPerSec.isNaN || wPrimeDeltaKjPerSec.isInfinite) return 0.0;
    return wPrimeDeltaKjPerSec;
  }

  /// Status baterii beztlenowej $W'$.
  WPrimeBatteryStatus get wPrimeStatus {
    final double frac = wPrimeFraction;
    if (frac <= 0.05) return WPrimeBatteryStatus.depleted;
    if (frac < 0.25) return WPrimeBatteryStatus.critical;
    if (safeWPrimeDeltaKjPerSec < -0.05 || frac < 0.60) {
      return WPrimeBatteryStatus.draining;
    }
    return WPrimeBatteryStatus.optimal;
  }
}

/// Telewizyjne okienko biometryczne kolarza w stylu transmisji F1 / Whoop Live.
///
/// Prezentuje na żywo:
/// - wykres EKG tętna zsynchronizowany z aktualnym BPM,
/// - procent maksymalnego tętna (`% HRmax`),
/// - strefę mocy Coggana Z1–Z7 wraz z mocą [W] i [W/kg],
/// - kadencję pedałowania [RPM],
/// - pasek drenażu baterii beztlenowej $W'$ w [kJ].
class TvRiderBiometricsTelemetryBox extends StatefulWidget {
  /// Dane telemetryczne kolarza.
  final TvRiderBiometricsData data;

  /// Czy widżet jest aktywny i interaktywny.
  final bool enabled;

  /// Czy widżet jest aktualnie zaznaczony (np. przypięty kolarz na transmisji).
  final bool isSelected;

  /// Czy okienko jest rozwinięte (pokazuje pełny pasek detali Z1–Z7 i status $W'$).
  final bool isExpanded;

  /// Opcjonalny callback po kliknięciu / naciśnięciu Enter/Space.
  final VoidCallback? onTap;

  /// Opcjonalny callback przełączenia trybu rozwiniętego.
  final ValueChanged<bool>? onExpandedChanged;

  const TvRiderBiometricsTelemetryBox({
    super.key,
    required this.data,
    this.enabled = true,
    this.isSelected = false,
    this.isExpanded = true,
    this.onTap,
    this.onExpandedChanged,
  });

  @override
  State<TvRiderBiometricsTelemetryBox> createState() =>
      _TvRiderBiometricsTelemetryBoxState();
}

class _TvRiderBiometricsTelemetryBoxState
    extends State<TvRiderBiometricsTelemetryBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ecgController;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant TvRiderBiometricsTelemetryBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.data.isLiveFeedActive != widget.data.isLiveFeedActive) {
      _syncAnimationState();
    }
  }

  void _syncAnimationState() {
    final bool shouldAnimate = widget.enabled && widget.data.isLiveFeedActive;
    if (shouldAnimate) {
      if (!_ecgController.isAnimating) {
        _ecgController.repeat();
      }
    } else {
      _ecgController.stop();
    }
  }

  @override
  void dispose() {
    _ecgController.dispose();
    super.dispose();
  }

  void _handleActivate() {
    if (!widget.enabled) return;
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.onExpandedChanged != null) {
      widget.onExpandedChanged!(!widget.isExpanded);
    }
  }

  Color _resolveHeartRateColor(int hrPercent) {
    if (!widget.enabled) return AppColors.textSecondary;
    if (hrPercent >= 92) return AppColors.crimsonAlert;
    if (hrPercent >= 82) return AppColors.amberWarning;
    if (hrPercent >= 68) return AppColors.statusSuccess;
    return AppColors.cyanAccent;
  }

  Color _resolveWPrimeColor(WPrimeBatteryStatus status) {
    if (!widget.enabled) return AppColors.textSecondary;
    switch (status) {
      case WPrimeBatteryStatus.optimal:
        return AppColors.statusSuccess;
      case WPrimeBatteryStatus.draining:
        return AppColors.amberWarning;
      case WPrimeBatteryStatus.critical:
      case WPrimeBatteryStatus.depleted:
        return AppColors.crimsonAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive =
        widget.enabled && (widget.onTap != null || widget.onExpandedChanged != null);

    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : widget.isSelected
            ? AppColors.goldAccent
            : _isFocused
                ? AppColors.cyanAccent
                : _isHovered
                    ? AppColors.goldAccent.withValues(alpha: 0.72)
                    : const Color(0xFF2A2F3D);

    final Color surfaceColor = !widget.enabled
        ? AppColors.surface.withValues(alpha: 0.65)
        : _isPressed
            ? AppColors.surfaceLight
            : _isHovered
                ? const Color(0xFF1D212B)
                : AppColors.surface;

    return FocusableActionDetector(
      enabled: interactive,
      onShowFocusHighlight: (bool focused) {
        if (mounted && _isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      onShowHoverHighlight: (bool hovered) {
        if (mounted && _isHovered != hovered) {
          setState(() => _isHovered = hovered);
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            _handleActivate();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (mounted && !_isHovered) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted && (_isHovered || _isPressed)) {
            setState(() {
              _isHovered = false;
              _isPressed = false;
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: interactive
              ? (_) {
                  if (mounted) setState(() => _isPressed = true);
                }
              : null,
          onTapUp: interactive
              ? (_) {
                  if (mounted) setState(() => _isPressed = false);
                }
              : null,
          onTapCancel: interactive
              ? () {
                  if (mounted) setState(() => _isPressed = false);
                }
              : null,
          onTap: interactive ? _handleActivate : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            opacity: widget.enabled ? 1.0 : 0.55,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              scale: _isPressed ? 0.992 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected || _isFocused ? 1.5 : 1.0,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    if (widget.isSelected && widget.enabled)
                      BoxShadow(
                        color: AppColors.goldAccent.withValues(alpha: 0.16),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final double maxWidth = constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : 420.0;
                      final bool isCompact = maxWidth < 340.0;
                      final bool isWide = maxWidth >= 520.0;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildBroadcastHeader(isCompact: isCompact),
                          Padding(
                            padding: EdgeInsets.all(isCompact ? 10.0 : 14.0),
                            child: isWide
                                ? _buildWideBody()
                                : _buildStackedBody(isCompact: isCompact),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBroadcastHeader({required bool isCompact}) {
    final TvRiderBiometricsData data = widget.data;
    final Color hrColor = _resolveHeartRateColor(data.heartRateMaxPercent);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10.0 : 14.0,
        vertical: isCompact ? 8.0 : 10.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          // Pasek F1 / Whoop akcentowy
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: data.isAttacking
                  ? AppColors.crimsonAlert
                  : AppColors.goldAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          // Skrót drużyny + numer startowy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.7),
                width: 1,
              ),
            ),
            child: Text(
              data.bibNumber != null
                  ? '${data.teamShortCode.toUpperCase()} #${data.bibNumber}'
                  : data.teamShortCode.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.textPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Nazwisko kolarza
          Expanded(
            child: Text(
              data.riderName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Status LIVE / BIO
          AnimatedBuilder(
            animation: _ecgController,
            builder: (BuildContext context, _) {
              final double pulse = widget.enabled && data.isLiveFeedActive
                  ? 0.45 + 0.55 * (0.5 + 0.5 * math.sin(_ecgController.value * math.pi * 2))
                  : 0.35;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: hrColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hrColor.withValues(alpha: pulse),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      data.isLiveFeedActive ? 'BIO LIVE' : 'PAUSED',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (widget.onExpandedChanged != null) ...<Widget>[
            const SizedBox(width: 6),
            _HeaderExpandToggleButton(
              isExpanded: widget.isExpanded,
              enabled: widget.enabled,
              onPressed: () => widget.onExpandedChanged!(!widget.isExpanded),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWideBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 12,
                child: _buildEcgMonitorPanel(isCompact: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 11,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _buildPowerZoneAndCadenceRow(isCompact: false),
                    const SizedBox(height: 10),
                    _buildWPrimeBatteryPanel(isCompact: false),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.isExpanded) ...<Widget>[
          const SizedBox(height: 10),
          _buildPowerZoneSpectrumStrip(isCompact: false),
        ],
      ],
    );
  }

  Widget _buildStackedBody({required bool isCompact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildEcgMonitorPanel(isCompact: isCompact),
        SizedBox(height: isCompact ? 8 : 10),
        _buildPowerZoneAndCadenceRow(isCompact: isCompact),
        SizedBox(height: isCompact ? 8 : 10),
        _buildWPrimeBatteryPanel(isCompact: isCompact),
        if (widget.isExpanded) ...<Widget>[
          SizedBox(height: isCompact ? 8 : 10),
          _buildPowerZoneSpectrumStrip(isCompact: isCompact),
        ],
      ],
    );
  }

  Widget _buildEcgMonitorPanel({required bool isCompact}) {
    final TvRiderBiometricsData data = widget.data;
    final int hrPercent = data.heartRateMaxPercent;
    final Color hrColor = _resolveHeartRateColor(hrPercent);

    return Container(
      padding: EdgeInsets.all(isCompact ? 9 : 11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Icon(
                Icons.monitor_heart_outlined,
                size: isCompact ? 15 : 17,
                color: hrColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${data.safeHeartRateBpm}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'BPM',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // % HRmax pigułka
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hrColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hrColor.withValues(alpha: 0.55),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$hrPercent% HRmax',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompact ? 10 : 11,
                          fontWeight: FontWeight.w800,
                          color: hrColor,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Wykres EKG na żywo
          SizedBox(
            height: isCompact ? 48 : 58,
            child: AnimatedBuilder(
              animation: _ecgController,
              builder: (BuildContext context, _) {
                return CustomPaint(
                  painter: _LiveEcgWaveformPainter(
                    phase: _ecgController.value,
                    heartRateBpm: data.safeHeartRateBpm,
                    traceColor: hrColor,
                    enabled: widget.enabled,
                    heartRateHistory: data.heartRateHistoryBpm,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          // Pasek procentu HRmax
          Row(
            children: <Widget>[
              Text(
                'MAX ${data.safeMaxHeartRateBpm} BPM',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        const ColoredBox(color: AppColors.surfaceLight),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: data.heartRateMaxFraction,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  AppColors.statusSuccess,
                                  hrColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPowerZoneAndCadenceRow({required bool isCompact}) {
    final TvRiderBiometricsData data = widget.data;
    final Color zoneColor =
        widget.enabled ? data.powerZoneColor : AppColors.textSecondary;

    return Row(
      children: <Widget>[
        // Strefa mocy Z1-Z7 + waty
        Expanded(
          flex: 6,
          child: Container(
            padding: EdgeInsets.all(isCompact ? 8 : 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: zoneColor.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: zoneColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Z${data.powerZone}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.background,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.powerZoneName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: zoneColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(
                      '${data.safePowerWatts.round()}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 17 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'W',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${data.wattsPerKg.toStringAsFixed(1)} W/kg',
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Kadencja RPM
        Expanded(
          flex: 5,
          child: Container(
            padding: EdgeInsets.all(isCompact ? 8 : 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2A2F3D),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.autorenew_rounded,
                      size: 13,
                      color: widget.enabled
                          ? AppColors.accentBlue
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data.cadenceProfileLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(
                      '${data.safeCadenceRpm}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 17 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'RPM',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWPrimeBatteryPanel({required bool isCompact}) {
    final TvRiderBiometricsData data = widget.data;
    final WPrimeBatteryStatus status = data.wPrimeStatus;
    final Color batteryColor = _resolveWPrimeColor(status);
    final double delta = data.safeWPrimeDeltaKjPerSec;
    final String deltaFormatted = delta == 0.0
        ? '0.00 kJ/s'
        : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)} kJ/s';

    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == WPrimeBatteryStatus.critical ||
                  status == WPrimeBatteryStatus.depleted
              ? AppColors.crimsonAlert.withValues(alpha: 0.65)
              : const Color(0xFF2A2F3D),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                status == WPrimeBatteryStatus.critical ||
                        status == WPrimeBatteryStatus.depleted
                    ? Icons.battery_alert_rounded
                    : Icons.bolt_rounded,
                size: 14,
                color: batteryColor,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  "W' ANAEROBIC",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${data.safeWPrimeRemainingKj.toStringAsFixed(1)} / ${data.safeWPrimeMaxKj.toStringAsFixed(1)} kJ',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Segmentowany pasek drenażu baterii W'
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const ColoredBox(color: AppColors.background),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: data.wPrimeFraction,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            batteryColor.withValues(alpha: 0.78),
                            batteryColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Siatka segmentów baterii (5 bloków po 20%)
                  Row(
                    children: List<Widget>.generate(
                      5,
                      (int index) => Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: index < 4
                                  ? BorderSide(
                                      color: AppColors.background.withValues(
                                        alpha: 0.75,
                                      ),
                                      width: 1.5,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text(
                '${data.wPrimePercent}% BAL',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: batteryColor,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Text(
                deltaFormatted,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: delta < -0.05
                      ? AppColors.crimsonAlert
                      : delta > 0.05
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPowerZoneSpectrumStrip({required bool isCompact}) {
    final int activeZone = widget.data.powerZone;

    return Row(
      children: List<Widget>.generate(7, (int index) {
        final int zone = index + 1;
        final bool isActive = zone == activeZone;
        final Color zoneColor = AppColors.getPowerZoneColor(zone);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 6 ? 4.0 : 0.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(vertical: isCompact ? 3 : 4),
              decoration: BoxDecoration(
                color: isActive
                    ? zoneColor.withValues(alpha: 0.24)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive
                      ? zoneColor
                      : const Color(0xFF2A2F3D),
                  width: isActive ? 1.2 : 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Z$zone',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive ? zoneColor : AppColors.textSecondary,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _HeaderExpandToggleButton extends StatefulWidget {
  final bool isExpanded;
  final bool enabled;
  final VoidCallback onPressed;

  const _HeaderExpandToggleButton({
    required this.isExpanded,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_HeaderExpandToggleButton> createState() =>
      _HeaderExpandToggleButtonState();
}

class _HeaderExpandToggleButtonState extends State<_HeaderExpandToggleButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (bool v) {
        if (mounted) setState(() => _focused = v);
      },
      onShowHoverHighlight: (bool v) {
        if (mounted) setState(() => _hovered = v);
      },
      child: InkWell(
        onTap: widget.enabled ? widget.onPressed : null,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _hovered || _focused
                ? AppColors.surfaceLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _focused ? AppColors.cyanAccent : Colors.transparent,
              width: 1,
            ),
          ),
          child: Icon(
            widget.isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// CustomPainter rysujący żywy wykres EKG z zespołem P-QRS-T zsynchronizowanym z BPM.
class _LiveEcgWaveformPainter extends CustomPainter {
  final double phase;
  final int heartRateBpm;
  final Color traceColor;
  final bool enabled;
  final List<int> heartRateHistory;

  const _LiveEcgWaveformPainter({
    required this.phase,
    required this.heartRateBpm,
    required this.traceColor,
    required this.enabled,
    required this.heartRateHistory,
  });

  /// Oblicza znormalizowaną amplitudę załamka EKG P-QRS-T dla fazy cyklu `t` w [0, 1).
  double _ecgSample(double t) {
    // Załamek P
    if (t >= 0.08 && t < 0.18) {
      final double u = (t - 0.08) / 0.10;
      return 0.16 * math.sin(u * math.pi);
    }
    // Załamek Q
    if (t >= 0.22 && t < 0.26) {
      final double u = (t - 0.22) / 0.04;
      return -0.22 * math.sin(u * math.pi);
    }
    // Szczyt R (ostry pik)
    if (t >= 0.26 && t < 0.32) {
      final double u = (t - 0.26) / 0.06;
      return u < 0.5 ? (u * 2.0) * 1.0 : (1.0 - (u - 0.5) * 2.0) * 1.0;
    }
    // Załamek S
    if (t >= 0.32 && t < 0.37) {
      final double u = (t - 0.32) / 0.05;
      return -0.34 * math.sin(u * math.pi);
    }
    // Załamek T
    if (t >= 0.48 && t < 0.66) {
      final double u = (t - 0.48) / 0.18;
      return 0.28 * math.sin(u * math.pi);
    }
    return 0.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Subtelna siatka EKG w tle
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D).withValues(alpha: 0.45)
      ..strokeWidth = 0.7;

    final double midY = size.height * 0.58;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    const int cols = 8;
    for (int i = 1; i < cols; i++) {
      final double x = size.width * (i / cols);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Opcjonalny mini-trend historii HR w tle
    if (heartRateHistory.length >= 2) {
      final Path historyPath = Path();
      final int count = heartRateHistory.length;
      for (int i = 0; i < count; i++) {
        final double x = (i / (count - 1)) * size.width;
        final double normalized =
            ((heartRateHistory[i].clamp(80, 210) - 80) / 130.0).clamp(0.0, 1.0);
        final double y = size.height * (0.90 - normalized * 0.72);
        if (i == 0) {
          historyPath.moveTo(x, y);
        } else {
          historyPath.lineTo(x, y);
        }
      }
      final Paint historyPaint = Paint()
        ..color = traceColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.drawPath(historyPath, historyPaint);
    }

    // Częstotliwość cykli na szerokości okna zależna od BPM (ok. 2.5 - 5.2 uderzeń)
    final double beatsInWindow =
        (heartRateBpm.clamp(45, 220) / 48.0).clamp(1.2, 5.0);
    const int samples = 120;
    final double amplitudeUp = size.height * 0.50;
    final double amplitudeDown = size.height * 0.34;

    final Path ecgPath = Path();
    Offset? headPoint;

    for (int i = 0; i <= samples; i++) {
      final double u = i / samples;
      final double x = u * size.width;
      final double cyclePos = ((u * beatsInWindow) - phase) % 1.0;
      final double positiveCycle = cyclePos < 0 ? cyclePos + 1.0 : cyclePos;
      final double sample = _ecgSample(positiveCycle);
      final double dy = sample >= 0
          ? -sample * amplitudeUp
          : -sample * amplitudeDown;
      final double y = (midY + dy).clamp(3.0, size.height - 3.0);

      if (i == 0) {
        ecgPath.moveTo(x, y);
      } else {
        ecgPath.lineTo(x, y);
      }
      if (i == samples) {
        headPoint = Offset(x, y);
      }
    }

    // Poświata śladu EKG
    if (enabled) {
      final Paint glowPaint = Paint()
        ..color = traceColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.0);
      canvas.drawPath(ecgPath, glowPaint);
    }

    // Główna linia EKG z zanikiem po lewej stronie
    final Paint tracePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        <Color>[
          traceColor.withValues(alpha: 0.15),
          traceColor.withValues(alpha: 0.85),
          traceColor,
        ],
        const <double>[0.0, 0.55, 1.0],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(ecgPath, tracePaint);

    // Świecący punkt głowicy na końcu wykresu
    if (headPoint != null && enabled) {
      canvas.drawCircle(
        headPoint,
        4.2,
        Paint()..color = traceColor.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        headPoint,
        2.3,
        Paint()..color = AppColors.textPrimary,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveEcgWaveformPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.heartRateBpm != heartRateBpm ||
        oldDelegate.traceColor != traceColor ||
        oldDelegate.enabled != enabled ||
        oldDelegate.heartRateHistory != heartRateHistory;
  }
}
