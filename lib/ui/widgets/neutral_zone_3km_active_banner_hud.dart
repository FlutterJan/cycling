import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/peloton/late_race_mechanical_neutral_zone_3km.dart';

/// Stan wyświetlania telewizyjnego znacznika strefy ochronnej UCI w widoku 3D.
enum NeutralZoneBannerStatus {
  /// Peleton zbliża się do strefy ochronnej (poniżej 2 km przed bramką 3 km / 5 km).
  approaching(
    badgeLabel: 'APPROACHING ZONE',
    shortPl: 'Zbliżanie do strefy',
    accentColor: AppColors.amberWarning,
  ),

  /// Czołówka wyścigu znajduje się wewnątrz strefy ochronnej — czasy GC zneutralizowane.
  active(
    badgeLabel: 'LIVE UCI RULE',
    shortPl: 'Ochrona GC aktywna',
    accentColor: AppColors.goldAccent,
  ),

  /// Poza strefą ochronną lub etap nieobjęty regułą (np. finisz na szczycie, ITT/TTT).
  inactive(
    badgeLabel: 'STANDBY',
    shortPl: 'Strefa nieaktywna',
    accentColor: AppColors.textSecondary,
  ),

  /// Znacznik wyłączony w ustawieniach HUD lub przez rodzica.
  disabled(
    badgeLabel: 'HUD OFF',
    shortPl: 'Znacznik wyłączony',
    accentColor: AppColors.textSecondary,
  );

  final String badgeLabel;
  final String shortPl;
  final Color accentColor;

  const NeutralZoneBannerStatus({
    required this.badgeLabel,
    required this.shortPl,
    required this.accentColor,
  });
}

/// Niemodyfikowalny model danych dla telewizyjnego znacznika `3 KM ZONE — GC TIMES NEUTRALIZED`.
@immutable
class NeutralZoneBannerHudData {
  /// Nazwa bieżącego etapu.
  final String stageName;

  /// Typ etapu decydujący o aktywności reguły UCI Art. 2.6.027.
  final NeutralZoneStageType stageType;

  /// Preset długości strefy (3 km lub 5 km).
  final NeutralZoneDistancePreset distancePreset;

  /// Czy kolegium sędziów UCI rozszerzyło strefę do 5 km.
  final bool juryExtendedTo5Km;

  /// Opcjonalny powód rozszerzenia strefy do 5 km.
  final String? extensionReason;

  /// Dystans pozostały liderowi wyścigu do linii mety [m].
  final double remainingToFinishMeters;

  /// Całkowita długość strefy ochronnej [m] (0.0 jeśli etap bez ochrony).
  final double zoneLengthMeters;

  /// Liczba kolarzy z potwierdzoną neutralizacją czasu GC.
  final int neutralizedIncidentsCount;

  /// Liczba incydentów oczekujących na weryfikację VAR UCI.
  final int pendingReviewCount;

  /// Czy znacznik jest włączony w HUD 3D.
  final bool isEnabled;

  const NeutralZoneBannerHudData({
    required this.stageName,
    required this.stageType,
    required this.distancePreset,
    required this.juryExtendedTo5Km,
    this.extensionReason,
    required this.remainingToFinishMeters,
    required this.zoneLengthMeters,
    this.neutralizedIncidentsCount = 0,
    this.pendingReviewCount = 0,
    this.isEnabled = true,
  });

  /// Buduje dane znacznika bezpośrednio ze stanu silnika [LateRaceNeutralZoneState].
  factory NeutralZoneBannerHudData.fromNeutralZoneState(
    LateRaceNeutralZoneState state, {
    bool isEnabled = true,
  }) {
    return NeutralZoneBannerHudData(
      stageName: state.config.stageName,
      stageType: state.config.stageType,
      distancePreset: state.config.distancePreset,
      juryExtendedTo5Km: state.config.juryExtendedTo5Km,
      extensionReason: state.config.extensionReason,
      remainingToFinishMeters: state.remainingToFinishMeters,
      zoneLengthMeters: state.config.activeZoneLengthMeters,
      neutralizedIncidentsCount: state.summary.neutralizedCount,
      pendingReviewCount: state.summary.pendingCount,
      isEnabled: isEnabled,
    );
  }

  /// Czy etap w ogóle kwalifikuje się do strefy ochronnej UCI.
  bool get isProtectionEligible =>
      stageType.isEligible && zoneLengthMeters > 0.0;

  /// Czy lider znajduje się obecnie w granicach strefy ochronnej.
  bool get isInsideZone =>
      isProtectionEligible &&
      remainingToFinishMeters >= 0.0 &&
      remainingToFinishMeters <= zoneLengthMeters;

  /// Ile metrów pozostało do przekroczenia bramki strefy ochronnej.
  double get distanceToZoneEntryMeters =>
      math.max(0.0, remainingToFinishMeters - zoneLengthMeters);

  /// Czy peleton jest w oknie ostrzegawczym (<= 2000 m przed wejściem do strefy).
  bool get isApproachingZone =>
      isProtectionEligible &&
      !isInsideZone &&
      distanceToZoneEntryMeters > 0.0 &&
      distanceToZoneEntryMeters <= 2000.0;

  /// Wyliczony status znacznika HUD.
  NeutralZoneBannerStatus get status {
    if (!isEnabled) {
      return NeutralZoneBannerStatus.disabled;
    }
    if (isInsideZone) {
      return NeutralZoneBannerStatus.active;
    }
    if (isApproachingZone) {
      return NeutralZoneBannerStatus.approaching;
    }
    return NeutralZoneBannerStatus.inactive;
  }

  /// Postęp przejazdu przez strefę ochronną w zakresie 0.0–1.0.
  double get zoneProgress {
    if (!isInsideZone || zoneLengthMeters <= 0.0) {
      return 0.0;
    }
    final coveredInZone = zoneLengthMeters - remainingToFinishMeters;
    return (coveredInZone / zoneLengthMeters).clamp(0.0, 1.0);
  }

  /// Czy aktywna jest strefa rozszerzona 5 km.
  bool get isFiveKmZone =>
      juryExtendedTo5Km && stageType.supportsFiveKmExtension ||
      distancePreset == NeutralZoneDistancePreset.extended5Km ||
      zoneLengthMeters >= 4500.0;

  /// Krótka etykieta bramki strefy (np. `3 KM ZONE` lub `5 KM ZONE`).
  String get zoneBadgeText {
    if (!isProtectionEligible) {
      return 'NO NEUTRAL ZONE';
    }
    return isFiveKmZone ? '5 KM ZONE' : '3 KM ZONE';
  }

  /// Główny napis telewizyjny w stylu transmisji WorldTour.
  String get tvHeadlineText {
    if (!isEnabled) {
      return '$zoneBadgeText — HUD DISABLED';
    }
    if (!isProtectionEligible) {
      return 'NO NEUTRAL ZONE — ${stageType.shortLabel.toUpperCase()}';
    }
    if (isInsideZone) {
      return '$zoneBadgeText — GC TIMES NEUTRALIZED';
    }
    if (isApproachingZone) {
      return '$zoneBadgeText — ENTERING IN ${_formatCompactDistance(distanceToZoneEntryMeters)}';
    }
    return '$zoneBadgeText — STANDBY (${_formatCompactDistance(remainingToFinishMeters)} TO FINISH)';
  }

  /// Sformatowany dystans pozostały do mety.
  String get formattedRemainingToFinish =>
      _formatCompactDistance(remainingToFinishMeters);

  static String _formatCompactDistance(double meters) {
    final clamped = math.max(0.0, meters);
    if (clamped >= 1000.0) {
      return '${(clamped / 1000.0).toStringAsFixed(1)} km';
    }
    return '${clamped.round()} m';
  }

  NeutralZoneBannerHudData copyWith({
    String? stageName,
    NeutralZoneStageType? stageType,
    NeutralZoneDistancePreset? distancePreset,
    bool? juryExtendedTo5Km,
    String? extensionReason,
    double? remainingToFinishMeters,
    double? zoneLengthMeters,
    int? neutralizedIncidentsCount,
    int? pendingReviewCount,
    bool? isEnabled,
  }) {
    return NeutralZoneBannerHudData(
      stageName: stageName ?? this.stageName,
      stageType: stageType ?? this.stageType,
      distancePreset: distancePreset ?? this.distancePreset,
      juryExtendedTo5Km: juryExtendedTo5Km ?? this.juryExtendedTo5Km,
      extensionReason: extensionReason ?? this.extensionReason,
      remainingToFinishMeters:
          remainingToFinishMeters ?? this.remainingToFinishMeters,
      zoneLengthMeters: zoneLengthMeters ?? this.zoneLengthMeters,
      neutralizedIncidentsCount:
          neutralizedIncidentsCount ?? this.neutralizedIncidentsCount,
      pendingReviewCount: pendingReviewCount ?? this.pendingReviewCount,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Telewizyjny znacznik HUD `3 KM ZONE — GC TIMES NEUTRALIZED` w widoku 3D.
///
/// Prezentuje belkę transmisji WorldTour z pulsującym wskaźnikiem aktywnej
/// neutralizacji czasów GC, obsługą strefy rozszerzonej 5 km, rozwijanym
/// panelem szczegółów UCI oraz pełną responsywnością (`390x844`, `1024x768`, `1600x900`).
class NeutralZone3kmActiveBannerHud extends StatefulWidget {
  /// Dane telemetryczne i regulaminowe strefy ochronnej.
  final NeutralZoneBannerHudData data;

  /// Wymusza stan nieaktywny/wyłączony kontrolki.
  final bool isDisabled;

  /// Czy panel szczegółów UCI ma być domyślnie rozwinięty.
  final bool initiallyExpanded;

  /// Wywołanie po przełączeniu widoku szczegółów.
  final ValueChanged<bool>? onExpandedChanged;

  /// Opcjonalny callback otwierający pełny panel Kolegium Sędziów UCI.
  final VoidCallback? onOpenJuryPanel;

  const NeutralZone3kmActiveBannerHud({
    super.key,
    required this.data,
    this.isDisabled = false,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    this.onOpenJuryPanel,
  });

  @override
  State<NeutralZone3kmActiveBannerHud> createState() =>
      _NeutralZone3kmActiveBannerHudState();
}

class _NeutralZone3kmActiveBannerHudState
    extends State<NeutralZone3kmActiveBannerHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late bool _isExpanded;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncPulseAnimation();
  }

  @override
  void didUpdateWidget(covariant NeutralZone3kmActiveBannerHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulseAnimation();
  }

  bool get _effectiveDisabled =>
      widget.isDisabled || !widget.data.isEnabled;

  NeutralZoneBannerStatus get _effectiveStatus => _effectiveDisabled
      ? NeutralZoneBannerStatus.disabled
      : widget.data.status;

  void _syncPulseAnimation() {
    final shouldPulse =
        !_effectiveDisabled && _effectiveStatus == NeutralZoneBannerStatus.active;
    if (shouldPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!shouldPulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (_effectiveDisabled) {
      return;
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpandedChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final status = _effectiveStatus;
    final accent = status.accentColor;
    final borderColor = _resolveBorderColor(accent);
    final backgroundColor = _resolveBackgroundColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompactMobile = maxWidth < 520.0;
        final isTablet = maxWidth >= 520.0 && maxWidth < 1100.0;
        final targetMaxWidth = isCompactMobile
            ? maxWidth
            : (isTablet ? math.min(maxWidth, 640.0) : math.min(maxWidth, 720.0));

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: targetMaxWidth),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            opacity: _effectiveDisabled ? 0.58 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (!_effectiveDisabled &&
                      status == NeutralZoneBannerStatus.active)
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInteractiveHeader(
                      status: status,
                      accent: accent,
                      isCompactMobile: isCompactMobile,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _isExpanded && !_effectiveDisabled
                          ? _buildExpandedDetails(
                              accent: accent,
                              isCompactMobile: isCompactMobile,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _resolveBorderColor(Color accent) {
    if (_effectiveDisabled) {
      return AppColors.cardBorder;
    }
    if (_isFocused) {
      return AppColors.accentBlue;
    }
    if (_isPressed || _isHovered) {
      return accent.withValues(alpha: 0.85);
    }
    if (_effectiveStatus == NeutralZoneBannerStatus.active) {
      return accent.withValues(alpha: 0.55);
    }
    return const Color(0xFF2A2F3D);
  }

  Color _resolveBackgroundColor() {
    if (_effectiveDisabled) {
      return AppColors.surface;
    }
    if (_isPressed) {
      return AppColors.surfaceLight.withValues(alpha: 0.96);
    }
    if (_isHovered) {
      return AppColors.surfaceLight;
    }
    return AppColors.surface;
  }

  Widget _buildInteractiveHeader({
    required NeutralZoneBannerStatus status,
    required Color accent,
    required bool isCompactMobile,
  }) {
    return Semantics(
      button: true,
      enabled: !_effectiveDisabled,
      expanded: _isExpanded,
      label: widget.data.tvHeadlineText,
      child: FocusableActionDetector(
        enabled: !_effectiveDisabled,
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
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggleExpanded();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _effectiveDisabled
              ? null
              : (_) => setState(() => _isPressed = true),
          onTapUp: _effectiveDisabled
              ? null
              : (_) => setState(() => _isPressed = false),
          onTapCancel: _effectiveDisabled
              ? null
              : () => setState(() => _isPressed = false),
          onTap: _effectiveDisabled ? null : _toggleExpanded,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompactMobile ? 12 : 16,
              vertical: isCompactMobile ? 10 : 12,
            ),
            child: isCompactMobile
                ? _buildCompactHeaderContent(status: status, accent: accent)
                : _buildWideHeaderContent(status: status, accent: accent),
          ),
        ),
      ),
    );
  }

  Widget _buildWideHeaderContent({
    required NeutralZoneBannerStatus status,
    required Color accent,
  }) {
    return Row(
      children: [
        _buildBroadcastShieldBadge(status: status, accent: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.data.tvHeadlineText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.data.isFiveKmZone &&
                      widget.data.isProtectionEligible) ...[
                    const SizedBox(width: 8),
                    _buildPillChip(
                      label: 'EXTENDED 5 KM',
                      color: AppColors.accentBlue,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  _buildPulseDot(status: status, accent: accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${status.shortPl} • ${widget.data.stageName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildFinishDistanceChip(accent: accent),
        const SizedBox(width: 8),
        _buildExpandChevron(accent: accent),
      ],
    );
  }

  Widget _buildCompactHeaderContent({
    required NeutralZoneBannerStatus status,
    required Color accent,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildBroadcastShieldBadge(
              status: status,
              accent: accent,
              compact: true,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.data.tvHeadlineText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildExpandChevron(accent: accent),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildPulseDot(status: status, accent: accent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                status.shortPl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildFinishDistanceChip(accent: accent),
          ],
        ),
      ],
    );
  }

  Widget _buildBroadcastShieldBadge({
    required NeutralZoneBannerStatus status,
    required Color accent,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == NeutralZoneBannerStatus.active
                ? Icons.shield_rounded
                : (status == NeutralZoneBannerStatus.approaching
                    ? Icons.timelapse_rounded
                    : Icons.shield_outlined),
            size: compact ? 14 : 16,
            color: accent,
          ),
          const SizedBox(width: 5),
          Text(
            widget.data.zoneBadgeText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseDot({
    required NeutralZoneBannerStatus status,
    required Color accent,
  }) {
    if (status != NeutralZoneBannerStatus.active || _effectiveDisabled) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_pulseController.value);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.goldAccent,
              AppColors.statusSuccess,
              t * 0.45,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35 + (t * 0.4)),
                blurRadius: 4 + (t * 5),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinishDistanceChip({required Color accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_rounded,
            size: 13,
            color: accent,
          ),
          const SizedBox(width: 5),
          Text(
            widget.data.formattedRemainingToFinish,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandChevron({required Color accent}) {
    return AnimatedRotation(
      turns: _isExpanded ? 0.5 : 0.0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
        color: _effectiveDisabled ? AppColors.textSecondary : accent,
      ),
    );
  }

  Widget _buildPillChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }

  Widget _buildExpandedDetails({
    required Color accent,
    required bool isCompactMobile,
  }) {
    final progress = widget.data.zoneProgress;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      padding: EdgeInsets.all(isCompactMobile ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.data.isProtectionEligible) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Przejazd przez strefę ochronną (${widget.data.zoneBadgeText})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricTile(
                label: 'Typ etapu',
                value: widget.data.stageType.shortLabel,
                color: AppColors.textPrimary,
              ),
              _buildMetricTile(
                label: 'Zneutralizowani',
                value: '${widget.data.neutralizedIncidentsCount}',
                color: AppColors.statusSuccess,
              ),
              _buildMetricTile(
                label: 'Weryfikacja VAR',
                value: '${widget.data.pendingReviewCount}',
                color: widget.data.pendingReviewCount > 0
                    ? AppColors.amberWarning
                    : AppColors.textSecondary,
              ),
            ],
          ),
          if (widget.data.extensionReason != null &&
              widget.data.extensionReason!.trim().isNotEmpty &&
              widget.data.isFiveKmZone) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder, width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Decyzja UCI 5 km: ${widget.data.extensionReason}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.onOpenJuryPanel != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _JuryPanelActionButton(
                enabled: !_effectiveDisabled,
                onPressed: widget.onOpenJuryPanel!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _JuryPanelActionButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _JuryPanelActionButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_JuryPanelActionButton> createState() => _JuryPanelActionButtonState();
}

class _JuryPanelActionButtonState extends State<_JuryPanelActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surface
        : (_pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.9)
            : (_hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.28)
                : AppColors.surfaceLight));

    final borderColor = !widget.enabled
        ? AppColors.cardBorder
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.primaryAccent : AppColors.cardBorder));

    return FocusableActionDetector(
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
            if (widget.enabled) {
              widget.onPressed();
            }
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.gavel_rounded,
                size: 14,
                color: widget.enabled
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Kolegium Sędziów UCI',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kontener Riverpod podłączający [NeutralZone3kmActiveBannerHud]
/// bezpośrednio do [lateRaceNeutralZoneProvider] w widoku 3D.
class NeutralZone3kmBannerHudConnector extends ConsumerWidget {
  /// Czy ukryć znacznik całkowicie, gdy lider jest daleko poza strefą.
  final bool hideWhenStandby;

  /// Wymusza stan wyłączony.
  final bool isDisabled;

  /// Callback otwierający panel sędziowski UCI.
  final VoidCallback? onOpenJuryPanel;

  const NeutralZone3kmBannerHudConnector({
    super.key,
    this.hideWhenStandby = false,
    this.isDisabled = false,
    this.onOpenJuryPanel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoneState = ref.watch(lateRaceNeutralZoneProvider);
    final hudData = NeutralZoneBannerHudData.fromNeutralZoneState(
      zoneState,
      isEnabled: !isDisabled,
    );

    if (hideWhenStandby &&
        hudData.status == NeutralZoneBannerStatus.inactive) {
      return const SizedBox.shrink();
    }

    return NeutralZone3kmActiveBannerHud(
      data: hudData,
      isDisabled: isDisabled,
      onOpenJuryPanel: onOpenJuryPanel,
    );
  }
}
