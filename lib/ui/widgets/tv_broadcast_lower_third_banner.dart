import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/rendering3d/broadcast_tv_graphics_overlay.dart';
import '../../models/rider/rider_appearance.dart';
import '../../services/career/national_championships_and_worlds_service.dart';
import 'rider_avatar_painter.dart';

/// Wariant kolorystyczny telewizyjnej belki dolnej w stylu transmisji Tour de France.
enum TvBroadcastBannerStyle {
  /// Klasyczna złoto-czarna belka ASO / Tour de France (`#0F1115` + `#D4AF37`).
  goldBlack,

  /// Bordowo-złota belka mistrzowska (`#8E4A49` + `#D4AF37`).
  burgundyGold,
}

/// Model danych wyświetlanych w telewizyjnej belce dolnej [TvBroadcastLowerThirdBanner].
@immutable
class TvBroadcastLowerThirdData {
  final String riderId;
  final String riderName;
  final String teamName;
  final String teamShortCode;
  final String nationalityIso;
  final RiderAppearance? appearance;
  final String primaryJerseyHex;
  final String secondaryJerseyHex;
  final String accentJerseyHex;
  final SpecialJerseyDesignation specialJersey;
  final double currentPowerWatts;
  final double riderWeightKg;
  final double? ftpWatts;
  final int heartRateBpm;
  final int maxHeartRateBpm;
  final double speedKmh;
  final int gcPosition;

  /// Różnica w klasyfikacji generalnej w sekundach:
  /// - `0.0`: równo z liderem / lider GC
  /// - `< 0.0`: wirtualna przewaga (np. `-18.0` -> `-0'18"`)
  /// - `> 0.0`: strata do lidera (np. `84.0` -> `+1'24"`)
  final double gcGapSeconds;
  final bool isAttacking;
  final bool isGcLeader;
  final String? statusLabel;
  final int? cadenceRpm;

  const TvBroadcastLowerThirdData({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.teamShortCode,
    this.nationalityIso = 'INT',
    this.appearance,
    this.primaryJerseyHex = '#D4AF37',
    this.secondaryJerseyHex = '#181B22',
    this.accentJerseyHex = '#8E4A49',
    this.specialJersey = SpecialJerseyDesignation.standardTeamJersey,
    required this.currentPowerWatts,
    this.riderWeightKg = 68.0,
    this.ftpWatts,
    required this.heartRateBpm,
    this.maxHeartRateBpm = 195,
    required this.speedKmh,
    required this.gcPosition,
    this.gcGapSeconds = 0.0,
    this.isAttacking = true,
    this.isGcLeader = false,
    this.statusLabel,
    this.cadenceRpm,
  });

  /// Konwertuje [BroadcastRiderSpotlightData] z nakładki 3D na model belki dolnej.
  factory TvBroadcastLowerThirdData.fromSpotlight(
    BroadcastRiderSpotlightData spotlight, {
    double? ftpWatts,
  }) {
    return TvBroadcastLowerThirdData(
      riderId: spotlight.riderId,
      riderName: spotlight.riderName,
      teamName: spotlight.teamName,
      teamShortCode: spotlight.teamShortCode,
      nationalityIso: spotlight.nationalityIso,
      appearance: spotlight.appearance,
      primaryJerseyHex: spotlight.primaryJerseyHex,
      secondaryJerseyHex: spotlight.secondaryJerseyHex,
      accentJerseyHex: spotlight.accentJerseyHex,
      specialJersey: spotlight.specialJersey,
      currentPowerWatts: spotlight.currentPowerWatts,
      riderWeightKg: spotlight.riderWeightKg,
      ftpWatts: ftpWatts,
      heartRateBpm: spotlight.heartRateBpm,
      maxHeartRateBpm: spotlight.maxHeartRateBpm,
      speedKmh: spotlight.speedKmh,
      gcPosition: spotlight.gcPosition,
      gcGapSeconds: spotlight.gcGapSeconds,
      isAttacking: spotlight.isAttacking,
      isGcLeader: spotlight.isRaceLeader || spotlight.gcPosition == 1,
      statusLabel: spotlight.statusTag,
      cadenceRpm: spotlight.cadenceRpm,
    );
  }

  /// Moc względna w W/kg (zabezpieczona przed dzieleniem przez zero).
  double get wattsPerKg {
    if (riderWeightKg <= 0.0 ||
        currentPowerWatts.isNaN ||
        currentPowerWatts.isInfinite) {
      return 0.0;
    }
    return math.max(0.0, currentPowerWatts) / riderWeightKg;
  }

  /// Wyznacza strefę mocy Coggana (1–7) na podstawie FTP (lub szacowanego 380 W).
  int get powerZone {
    final double effectiveFtp =
        (ftpWatts != null && ftpWatts! > 50.0) ? ftpWatts! : 380.0;
    final double ratio = math.max(0.0, currentPowerWatts) / effectiveFtp;
    if (ratio < 0.55) return 1;
    if (ratio < 0.75) return 2;
    if (ratio < 0.90) return 3;
    if (ratio < 1.05) return 4;
    if (ratio < 1.20) return 5;
    if (ratio < 1.50) return 6;
    return 7;
  }

  /// Udział aktualnego tętna względem HRmax (0.0–1.0).
  double get heartRateFraction {
    if (maxHeartRateBpm <= 0) return 0.0;
    return (heartRateBpm / maxHeartRateBpm).clamp(0.0, 1.0);
  }

  /// Etykieta statusu na belce (np. `ATAK`, `LIDER GC`, `POŚCIG`).
  String get resolvedStatusLabel {
    if (statusLabel != null && statusLabel!.trim().isNotEmpty) {
      return statusLabel!.trim().toUpperCase();
    }
    if (isAttacking) return 'ATAK';
    if (isGcLeader || gcPosition == 1) return 'LIDER GC';
    return 'W GRUPIE';
  }

  /// Sformatowana różnica czasu w klasyfikacji generalnej (np. `-0'18"`, `+1'24"`, `0'00"`).
  String get formattedGcGap {
    if (gcGapSeconds.isNaN || gcGapSeconds.isInfinite) return "0'00\"";
    final int rounded = gcGapSeconds.round();
    if (rounded == 0) {
      return isGcLeader || gcPosition == 1 ? 'LIDER' : "0'00\"";
    }
    final String sign = rounded < 0 ? '-' : '+';
    final int absSec = rounded.abs();
    final int hours = absSec ~/ 3600;
    final int minutes = (absSec % 3600) ~/ 60;
    final int seconds = absSec % 60;
    if (hours > 0) {
      return "$sign${hours}h${minutes.toString().padLeft(2, '0')}'${seconds.toString().padLeft(2, '0')}\"";
    }
    return "$sign$minutes'${seconds.toString().padLeft(2, '0')}\"";
  }
}

/// Telewizyjna belka dolna (Lower-Third) w stylu oficjalnej transmisji Tour de France.
///
/// Prezentuje atakującego kolarza (nazwisko, drużyna, narodowość), aktualne waty (W oraz W/kg),
/// tętno (BPM), prędkość (km/h) oraz pozycję i stratę/przewagę w klasyfikacji generalnej (GC).
/// Obsługuje płynne animacje wejścia/wyjścia, warianty złoto-czarny i bordowo-złoty,
/// pełne stany interakcji (`hover`, `active`, `focus`, `disabled`) oraz responsywność `LayoutBuilder`.
class TvBroadcastLowerThirdBanner extends StatefulWidget {
  final TvBroadcastLowerThirdData? data;
  final TvBroadcastBannerStyle style;
  final bool visible;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final ValueChanged<TvBroadcastBannerStyle>? onStyleChanged;

  const TvBroadcastLowerThirdBanner({
    super.key,
    required this.data,
    this.style = TvBroadcastBannerStyle.goldBlack,
    this.visible = true,
    this.enabled = true,
    this.onTap,
    this.onDismiss,
    this.onStyleChanged,
  });

  @override
  State<TvBroadcastLowerThirdBanner> createState() =>
      _TvBroadcastLowerThirdBannerState();
}

class _TvBroadcastLowerThirdBannerState
    extends State<TvBroadcastLowerThirdBanner>
    with TickerProviderStateMixin {
  static const Color _borderColor = Color(0xFF2A2F3D);

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final AnimationController _pulseController;

  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    if (widget.visible && widget.data != null) {
      _entranceController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant TvBroadcastLowerThirdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool shouldShow = widget.visible && widget.data != null;
    final bool wasShowing = oldWidget.visible && oldWidget.data != null;
    if (shouldShow && !wasShowing) {
      _entranceController.forward();
    } else if (!shouldShow && wasShowing) {
      _entranceController.reverse();
    } else if (shouldShow &&
        oldWidget.data?.riderId != widget.data?.riderId) {
      _entranceController.forward(from: 0.35);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleActivate() {
    if (!widget.enabled) return;
    widget.onTap?.call();
  }

  void _handleToggleStyle() {
    if (!widget.enabled || widget.onStyleChanged == null) return;
    final next = widget.style == TvBroadcastBannerStyle.goldBlack
        ? TvBroadcastBannerStyle.burgundyGold
        : TvBroadcastBannerStyle.goldBlack;
    widget.onStyleChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data == null && _entranceController.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        if (_entranceController.isDismissed &&
            (!widget.visible || widget.data == null)) {
          return const SizedBox.shrink();
        }
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: data == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 1024.0;
                final bool isCompact = maxWidth < 560.0;
                final bool isWide = maxWidth >= 960.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 980.0 : maxWidth,
                    ),
                    child: _buildInteractiveShell(
                      context,
                      data: data,
                      isCompact: isCompact,
                      isWide: isWide,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInteractiveShell(
    BuildContext context, {
    required TvBroadcastLowerThirdData data,
    required bool isCompact,
    required bool isWide,
  }) {
    final bool isInteractive = widget.enabled && widget.onTap != null;
    final bool isBurgundy =
        widget.style == TvBroadcastBannerStyle.burgundyGold;

    final Color surfaceStart = isBurgundy
        ? AppColors.primaryAccent.withValues(alpha: 0.94)
        : AppColors.background;
    final Color surfaceEnd = isBurgundy
        ? const Color(0xFF281518)
        : AppColors.surface;
    final Color activeBorderColor = !widget.enabled
        ? _borderColor.withValues(alpha: 0.6)
        : (_isFocused || _isHovered)
            ? AppColors.goldAccent
            : (isBurgundy
                ? AppColors.goldAccent.withValues(alpha: 0.55)
                : _borderColor);

    final double scale = !widget.enabled
        ? 1.0
        : (_isPressed ? 0.992 : (_isHovered ? 1.003 : 1.0));

    return Semantics(
      container: true,
      enabled: widget.enabled,
      button: isInteractive,
      label:
          'Transmisja TV: ${data.riderName}, ${data.teamName}, ${data.currentPowerWatts.round()} W, ${data.heartRateBpm} BPM, ${data.speedKmh.toStringAsFixed(1)} km/h, GC ${data.formattedGcGap}',
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (focused) {
          if (_isFocused != focused) {
            setState(() => _isFocused = focused);
          }
        },
        onShowHoverHighlight: (hovered) {
          if (_isHovered != hovered) {
            setState(() => _isHovered = hovered);
          }
        },
        shortcuts: isInteractive
            ? <ShortcutActivator, Intent>{
                const SingleActivator(LogicalKeyboardKey.enter):
                    const ActivateIntent(),
                const SingleActivator(LogicalKeyboardKey.space):
                    const ActivateIntent(),
              }
            : const <ShortcutActivator, Intent>{},
        actions: isInteractive
            ? <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    _handleActivate();
                    return null;
                  },
                ),
              }
            : const <Type, Action<Intent>>{},
        child: MouseRegion(
          cursor: isInteractive
              ? SystemMouseCursors.click
              : (widget.enabled
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.forbidden),
          child: GestureDetector(
            onTap: isInteractive ? _handleActivate : null,
            onTapDown: isInteractive
                ? (_) => setState(() => _isPressed = true)
                : null,
            onTapUp: isInteractive
                ? (_) => setState(() => _isPressed = false)
                : null,
            onTapCancel: isInteractive
                ? () => setState(() => _isPressed = false)
                : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              opacity: widget.enabled ? 1.0 : 0.48,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                scale: scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [surfaceStart, surfaceEnd],
                    ),
                    border: Border.all(
                      color: activeBorderColor,
                      width: (_isFocused || _isHovered) ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                      if (_isHovered || _isFocused)
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.16),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BroadcastRibbonBackdropPainter(
                              style: widget.style,
                              isAttacking: data.isAttacking,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTopGoldAccentStrip(data),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 12.0 : 16.0,
                                vertical: isCompact ? 10.0 : 12.0,
                              ),
                              child: isCompact
                                  ? _buildCompactLayout(data)
                                  : _buildWideLayout(data, isWide: isWide),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopGoldAccentStrip(TvBroadcastLowerThirdData data) {
    final Color zoneColor = AppColors.getPowerZoneColor(data.powerZone);
    return SizedBox(
      height: 3.5,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldAccent,
                    Color(0xFFF3D578),
                    AppColors.goldAccent,
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              color: data.isAttacking ? zoneColor : AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(TvBroadcastLowerThirdData data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildRiderIdentityBadge(data, size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: _buildRiderTitleBlock(data, isCompact: true),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(data, isCompact: true),
            if (widget.onStyleChanged != null || widget.onDismiss != null) ...[
              const SizedBox(width: 4),
              _buildActionButtons(compact: true),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          color: _borderColor.withValues(alpha: 0.75),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTelemetryTile(
                label: 'MOC',
                value: '${data.currentPowerWatts.round()} W',
                subValue: '${data.wattsPerKg.toStringAsFixed(1)} W/kg',
                accentColor: AppColors.getPowerZoneColor(data.powerZone),
                icon: Icons.bolt_rounded,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTelemetryTile(
                label: 'TĘTNO',
                value: '${data.heartRateBpm}',
                subValue: 'BPM',
                accentColor: data.heartRateFraction > 0.9
                    ? AppColors.crimsonAlert
                    : AppColors.primaryAccent,
                icon: Icons.favorite_rounded,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTelemetryTile(
                label: 'PRĘDKOŚĆ',
                value: data.speedKmh.toStringAsFixed(1),
                subValue: 'km/h',
                accentColor: AppColors.accentBlue,
                icon: Icons.speed_rounded,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildTelemetryTile(
                label: 'GC #${data.gcPosition}',
                value: data.formattedGcGap,
                subValue: data.gcGapSeconds < 0
                    ? 'PRZEWAGA'
                    : (data.gcGapSeconds == 0 ? 'LIDER' : 'STRATA'),
                accentColor: _gcGapAccentColor(data),
                icon: Icons.emoji_events_rounded,
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWideLayout(
    TvBroadcastLowerThirdData data, {
    required bool isWide,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTeamStripe(data),
        const SizedBox(width: 12),
        _buildRiderIdentityBadge(data, size: isWide ? 52 : 46),
        const SizedBox(width: 14),
        Expanded(
          flex: isWide ? 4 : 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusBadge(data, isCompact: false),
                  const SizedBox(width: 8),
                  _buildCountryChip(data.nationalityIso),
                ],
              ),
              const SizedBox(height: 5),
              _buildRiderTitleBlock(data, isCompact: false),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: isWide ? 6 : 5,
          child: Row(
            children: [
              Expanded(
                child: _buildTelemetryTile(
                  label: 'MOC',
                  value: '${data.currentPowerWatts.round()} W',
                  subValue: '${data.wattsPerKg.toStringAsFixed(2)} W/kg',
                  accentColor: AppColors.getPowerZoneColor(data.powerZone),
                  icon: Icons.bolt_rounded,
                  isCompact: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryTile(
                  label: 'TĘTNO',
                  value: '${data.heartRateBpm} BPM',
                  subValue:
                      '${(data.heartRateFraction * 100).round()}% HRmax',
                  accentColor: data.heartRateFraction > 0.9
                      ? AppColors.crimsonAlert
                      : AppColors.primaryAccent,
                  icon: Icons.favorite_rounded,
                  isCompact: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryTile(
                  label: 'PRĘDKOŚĆ',
                  value: '${data.speedKmh.toStringAsFixed(1)} km/h',
                  subValue: data.cadenceRpm != null
                      ? '${data.cadenceRpm} RPM'
                      : 'LIVE GPS',
                  accentColor: AppColors.accentBlue,
                  icon: Icons.speed_rounded,
                  isCompact: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryTile(
                  label: 'KLASYF. GC (#${data.gcPosition})',
                  value: data.formattedGcGap,
                  subValue: data.gcGapSeconds < 0
                      ? 'PRZEWAGA'
                      : (data.gcGapSeconds == 0 ? 'ŻÓŁTA KOSZ.' : 'STRATA'),
                  accentColor: _gcGapAccentColor(data),
                  icon: Icons.emoji_events_rounded,
                  isCompact: false,
                ),
              ),
            ],
          ),
        ),
        if (widget.onStyleChanged != null || widget.onDismiss != null) ...[
          const SizedBox(width: 10),
          _buildActionButtons(compact: false),
        ],
      ],
    );
  }

  Widget _buildTeamStripe(TvBroadcastLowerThirdData data) {
    final Color teamPrimary = _parseHexColor(
      data.primaryJerseyHex,
      fallback: AppColors.goldAccent,
    );
    final Color teamSecondary = _parseHexColor(
      data.secondaryJerseyHex,
      fallback: AppColors.primaryAccent,
    );
    return Container(
      width: 6,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [teamPrimary, teamSecondary],
        ),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
    );
  }

  Widget _buildRiderIdentityBadge(
    TvBroadcastLowerThirdData data, {
    required double size,
  }) {
    if (data.appearance != null) {
      return RiderAvatarWidget(
        appearance: data.appearance!,
        primaryJerseyColorHex: data.primaryJerseyHex,
        secondaryJerseyColorHex: data.secondaryJerseyHex,
        accentJerseyColorHex: data.accentJerseyHex,
        specialJersey: data.specialJersey,
        nationalityIso: data.nationalityIso,
        size: size,
        showHelmet: true,
        showGlasses: true,
        showBorder: true,
        borderColor: AppColors.goldAccent,
        borderWidth: 1.5,
      );
    }

    final Color teamColor = _parseHexColor(
      data.primaryJerseyHex,
      fallback: AppColors.primaryAccent,
    );
    final String initials = _extractInitials(data.riderName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [teamColor, AppColors.surfaceLight],
        ),
        border: Border.all(color: AppColors.goldAccent, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Inter',
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );
  }

  Widget _buildRiderTitleBlock(
    TvBroadcastLowerThirdData data, {
    required bool isCompact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.riderName.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
            fontSize: isCompact ? 14.5 : 17.5,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                  width: 0.8,
                ),
              ),
              child: Text(
                data.teamShortCode.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: 0.4,
                  color: AppColors.goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                data.teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                  fontSize: isCompact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    TvBroadcastLowerThirdData data, {
    required bool isCompact,
  }) {
    final bool attacking = data.isAttacking;
    final Color badgeColor = attacking
        ? AppColors.crimsonAlert
        : (data.isGcLeader ? AppColors.goldAccent : AppColors.accentBlue);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final double dotOpacity =
            attacking ? (0.45 + 0.55 * _pulseController.value) : 1.0;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 7 : 9,
            vertical: isCompact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.65),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor.withValues(alpha: dotOpacity),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                data.resolvedStatusLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: 0.5,
                  color: attacking
                      ? AppColors.textPrimary
                      : badgeColor,
                  fontSize: isCompact ? 9.5 : 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountryChip(String iso) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _borderColor, width: 0.8),
      ),
      child: Text(
        iso.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          letterSpacing: 0.4,
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTelemetryTile({
    required String label,
    required String value,
    required String subValue,
    required Color accentColor,
    required IconData icon,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.32),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: isCompact ? 11 : 12, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: 0.2,
                    color: AppColors.textSecondary,
                    fontSize: isCompact ? 8.5 : 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
                fontSize: isCompact ? 13 : 15,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.1,
              color: accentColor,
              fontSize: isCompact ? 9 : 10,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({required bool compact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onStyleChanged != null)
          _BannerIconAction(
            icon: Icons.palette_outlined,
            tooltip: 'Zmień motyw belki (Złoto / Bordo)',
            enabled: widget.enabled,
            size: compact ? 26 : 28,
            onPressed: _handleToggleStyle,
          ),
        if (widget.onStyleChanged != null && widget.onDismiss != null)
          const SizedBox(height: 4),
        if (widget.onDismiss != null)
          _BannerIconAction(
            icon: Icons.close_rounded,
            tooltip: 'Ukryj belkę transmisji',
            enabled: widget.enabled,
            size: compact ? 26 : 28,
            onPressed: widget.onDismiss!,
          ),
      ],
    );
  }

  Color _gcGapAccentColor(TvBroadcastLowerThirdData data) {
    if (data.gcGapSeconds < 0 || data.isGcLeader || data.gcPosition == 1) {
      return AppColors.statusSuccess;
    }
    if (data.gcGapSeconds == 0) {
      return AppColors.goldAccent;
    }
    return AppColors.amberWarning;
  }

  static Color _parseHexColor(String hex, {required Color fallback}) {
    final String cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length == 6) {
      final int? parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) return Color(parsed);
    } else if (cleaned.length == 8) {
      final int? parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }

  static String _extractInitials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) {
      return parts.first.substring(0, math.min(2, parts.first.length)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _BannerIconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final double size;
  final VoidCallback onPressed;

  const _BannerIconAction({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.size,
    required this.onPressed,
  });

  @override
  State<_BannerIconAction> createState() => _BannerIconActionState();
}

class _BannerIconActionState extends State<_BannerIconAction> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (widget.enabled) widget.onPressed();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: GestureDetector(
            onTap: widget.enabled ? widget.onPressed : null,
            onTapDown: widget.enabled
                ? (_) => setState(() => _pressed = true)
                : null,
            onTapUp: widget.enabled
                ? (_) => setState(() => _pressed = false)
                : null,
            onTapCancel: widget.enabled
                ? () => setState(() => _pressed = false)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _pressed
                    ? AppColors.goldAccent.withValues(alpha: 0.25)
                    : (_hovered || _focused)
                        ? AppColors.surfaceLight
                        : AppColors.background.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_hovered || _focused)
                      ? AppColors.goldAccent
                      : const Color(0xFF2A2F3D),
                  width: 1.0,
                ),
              ),
              child: Icon(
                widget.icon,
                size: widget.size * 0.56,
                color: !widget.enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : (_hovered || _focused)
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BroadcastRibbonBackdropPainter extends CustomPainter {
  final TvBroadcastBannerStyle style;
  final bool isAttacking;

  const _BroadcastRibbonBackdropPainter({
    required this.style,
    required this.isAttacking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Color accent = style == TvBroadcastBannerStyle.burgundyGold
        ? AppColors.goldAccent
        : AppColors.goldAccent;

    // Subtelne skośne paski w stylu oprawy graficznej Tour de France.
    final Paint stripePaint = Paint()
      ..color = accent.withValues(alpha: isAttacking ? 0.065 : 0.035)
      ..style = PaintingStyle.fill;

    final Path slash1 = Path()
      ..moveTo(size.width * 0.72, 0)
      ..lineTo(size.width * 0.78, 0)
      ..lineTo(size.width * 0.71, size.height)
      ..lineTo(size.width * 0.65, size.height)
      ..close();
    canvas.drawPath(slash1, stripePaint);

    final Path slash2 = Path()
      ..moveTo(size.width * 0.81, 0)
      ..lineTo(size.width * 0.84, 0)
      ..lineTo(size.width * 0.77, size.height)
      ..lineTo(size.width * 0.74, size.height)
      ..close();
    canvas.drawPath(slash2, stripePaint);
  }

  @override
  bool shouldRepaint(covariant _BroadcastRibbonBackdropPainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.isAttacking != isAttacking;
  }
}
