import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Status blokady sędziowskiej (Barrage) dla wozów technicznych w wyścigu.
enum TeamCarBarrageStatus {
  /// Przewaga grupy lidera >= 60 s — sędziowie wpuszczają wóz techniczny w lukę.
  cleared,

  /// Przewaga grupy lidera < 60 s — sędziowie blokują wjazd wozu w lukę (Barrage Active).
  barrageActive,

  /// Kolarz jedzie w peletonie — wóz techniczny porusza się w kolumnie za peletonem.
  convoyBehindPeloton,

  /// Łączność lub wskaźnik wyłączony.
  disabled;

  /// Czytelna etykieta statusu wyświetlana w nagłówku HUD.
  String get badgeLabel {
    switch (this) {
      case TeamCarBarrageStatus.cleared:
        return 'CONVOY OPEN';
      case TeamCarBarrageStatus.barrageActive:
        return 'BARRAGE ACTIVE';
      case TeamCarBarrageStatus.convoyBehindPeloton:
        return 'PELOTON CONVOY';
      case TeamCarBarrageStatus.disabled:
        return 'RADIO OFFLINE';
    }
  }

  /// Krótki opis konsekwencji taktycznych dla dyrektora sportowego.
  String get description {
    switch (this) {
      case TeamCarBarrageStatus.cleared:
        return 'Sędziowie otworzyli lukę — wóz techniczny bezpośrednio za grupą.';
      case TeamCarBarrageStatus.barrageActive:
        return 'Luka < 60 s: sędziowie blokują wóz za peletonem (dłuższy czas serwisu).';
      case TeamCarBarrageStatus.convoyBehindPeloton:
        return 'Kolarz w peletonie — obsługa z kolumny aut za grupą zasadniczą.';
      case TeamCarBarrageStatus.disabled:
        return 'Brak danych telemetrycznych z radia wyścigowego.';
    }
  }

  /// Kolor przewodni z palety [AppColors].
  Color get color {
    switch (this) {
      case TeamCarBarrageStatus.cleared:
        return AppColors.statusSuccess;
      case TeamCarBarrageStatus.barrageActive:
        return AppColors.crimsonAlert;
      case TeamCarBarrageStatus.convoyBehindPeloton:
        return AppColors.accentBlue;
      case TeamCarBarrageStatus.disabled:
        return AppColors.textSecondary;
    }
  }

  /// Czy wóz techniczny jest aktualnie zatrzymany przez sędziów.
  bool get isBlocked => this == TeamCarBarrageStatus.barrageActive;
}

/// Rodzaj zgłoszenia serwisowego z wozu technicznego.
enum TeamCarServiceRequestType {
  /// Wymiana koła po przebiciu lub defekcie.
  wheelChange(
    label: 'Wymiana koła',
    shortLabel: 'Koło',
    icon: Icons.tire_repair_rounded,
    baseSeconds: 10.0,
    barragePenaltySeconds: 42.0,
  ),

  /// Podanie bidonów i żeli energetycznych.
  bidonFeed(
    label: 'Bidony / Żele',
    shortLabel: 'Bidony',
    icon: Icons.local_drink_rounded,
    baseSeconds: 7.0,
    barragePenaltySeconds: 38.0,
  ),

  /// Pełna wymiana roweru z dachu wozu.
  bikeSwap(
    label: 'Wymiana roweru',
    shortLabel: 'Rower',
    icon: Icons.pedal_bike_rounded,
    baseSeconds: 14.0,
    barragePenaltySeconds: 48.0,
  );

  final String label;
  final String shortLabel;
  final IconData icon;
  final double baseSeconds;
  final double barragePenaltySeconds;

  const TeamCarServiceRequestType({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.baseSeconds,
    required this.barragePenaltySeconds,
  });
}

/// Niemutowalny model danych telemetrycznych odległości wozu technicznego od kolarza.
@immutable
class TeamCarGapTelemetryData {
  /// Nazwisko kolarza monitorowanego na HUD.
  final String riderName;

  /// Trzyliterowy kod drużyny (np. `PLM`).
  final String teamShortCode;

  /// Numer wozu dyrektora sportowego w kolumnie aut (1..25).
  final int dsCarNumber;

  /// Przewaga grupy lidera nad peletonem w sekundach (próg UCI: 60.0 s).
  final double leaderGroupGapToPelotonSeconds;

  /// Czy kolarz znajduje się przed peletonem (np. w ucieczce lub grupie lidera).
  final bool isRiderAheadOfPeloton;

  /// Aktualna odległość wozu technicznego od kolarza w metrach.
  final double teamCarDistanceMeters;

  /// Aktualna strata czasowa wozu technicznego do kolarza w sekundach.
  final double teamCarGapSeconds;

  /// Regulaminowy próg sędziowski UCI (domyślnie 60.0 s).
  final double barrageThresholdSeconds;

  /// Aktywne zlecenie serwisowe (jeśli kolarz wezwał wóz).
  final TeamCarServiceRequestType? activeRequest;

  /// Czy telemetria wozu jest aktywna.
  final bool isEnabled;

  const TeamCarGapTelemetryData({
    required this.riderName,
    required this.teamShortCode,
    required this.dsCarNumber,
    required this.leaderGroupGapToPelotonSeconds,
    required this.teamCarDistanceMeters,
    required this.teamCarGapSeconds,
    this.isRiderAheadOfPeloton = true,
    this.barrageThresholdSeconds = 60.0,
    this.activeRequest,
    this.isEnabled = true,
  });

  /// Bezpieczna wartość przewagi grupy lidera (>= 0, bez NaN/Infinity).
  double get safeLeaderGapSeconds {
    if (leaderGroupGapToPelotonSeconds.isNaN ||
        leaderGroupGapToPelotonSeconds.isInfinite) {
      return 0.0;
    }
    return math.max(0.0, leaderGroupGapToPelotonSeconds);
  }

  /// Bezpieczna wartość progu barrage (minimum 1.0 s).
  double get safeBarrageThresholdSeconds {
    if (barrageThresholdSeconds.isNaN ||
        barrageThresholdSeconds.isInfinite ||
        barrageThresholdSeconds <= 0.0) {
      return 60.0;
    }
    return barrageThresholdSeconds;
  }

  /// Bezpieczna odległość wozu w metrach (>= 0).
  double get safeCarDistanceMeters {
    if (teamCarDistanceMeters.isNaN || teamCarDistanceMeters.isInfinite) {
      return 0.0;
    }
    return math.max(0.0, teamCarDistanceMeters);
  }

  /// Bezpieczna strata czasowa wozu w sekundach (>= 0).
  double get safeCarGapSeconds {
    if (teamCarGapSeconds.isNaN || teamCarGapSeconds.isInfinite) {
      return 0.0;
    }
    return math.max(0.0, teamCarGapSeconds);
  }

  /// Wyznaczony numer wozu w kolumnie (>= 1).
  int get safeDsCarNumber => dsCarNumber < 1 ? 1 : dsCarNumber;

  /// Aktualny status blokady sędziowskiej na podstawie progu 60 s.
  TeamCarBarrageStatus get barrageStatus {
    if (!isEnabled) {
      return TeamCarBarrageStatus.disabled;
    }
    if (!isRiderAheadOfPeloton) {
      return TeamCarBarrageStatus.convoyBehindPeloton;
    }
    if (safeLeaderGapSeconds < safeBarrageThresholdSeconds) {
      return TeamCarBarrageStatus.barrageActive;
    }
    return TeamCarBarrageStatus.cleared;
  }

  /// Czy sędziowie aktualnie blokują wjazd wozu technicznego w lukę.
  bool get isBarrageActive =>
      barrageStatus == TeamCarBarrageStatus.barrageActive;

  /// Ile sekund przewagi brakuje grupie lidera do zniesienia blokady (0 gdy otwarte).
  double get secondsToLiftBarrage {
    if (!isBarrageActive) {
      return 0.0;
    }
    return math.max(0.0, safeBarrageThresholdSeconds - safeLeaderGapSeconds);
  }

  /// Stosunek postępu przewagi do progu 60 s w zakresie [0.0, 1.0].
  double get barrageThresholdProgress {
    return (safeLeaderGapSeconds / safeBarrageThresholdSeconds).clamp(0.0, 1.0);
  }

  /// Szacowany czas oczekiwania (ETA) na obsługę wozu technicznego w sekundach.
  /// Gdy aktywny jest `Barrage Active`, czas wydłuża się o karę blokady za peletonem.
  double estimateServiceEtaSeconds(TeamCarServiceRequestType type) {
    final double convoyFactor = (safeDsCarNumber - 1) * 1.2;
    final double baseEta = type.baseSeconds + safeCarGapSeconds + convoyFactor;
    if (isBarrageActive) {
      return baseEta + type.barragePenaltySeconds;
    }
    return baseEta;
  }

  /// Zwraca kopię danych ze zmodyfikowanymi wybranymi polami.
  TeamCarGapTelemetryData copyWith({
    String? riderName,
    String? teamShortCode,
    int? dsCarNumber,
    double? leaderGroupGapToPelotonSeconds,
    bool? isRiderAheadOfPeloton,
    double? teamCarDistanceMeters,
    double? teamCarGapSeconds,
    double? barrageThresholdSeconds,
    TeamCarServiceRequestType? activeRequest,
    bool clearActiveRequest = false,
    bool? isEnabled,
  }) {
    return TeamCarGapTelemetryData(
      riderName: riderName ?? this.riderName,
      teamShortCode: teamShortCode ?? this.teamShortCode,
      dsCarNumber: dsCarNumber ?? this.dsCarNumber,
      leaderGroupGapToPelotonSeconds:
          leaderGroupGapToPelotonSeconds ?? this.leaderGroupGapToPelotonSeconds,
      isRiderAheadOfPeloton:
          isRiderAheadOfPeloton ?? this.isRiderAheadOfPeloton,
      teamCarDistanceMeters:
          teamCarDistanceMeters ?? this.teamCarDistanceMeters,
      teamCarGapSeconds: teamCarGapSeconds ?? this.teamCarGapSeconds,
      barrageThresholdSeconds:
          barrageThresholdSeconds ?? this.barrageThresholdSeconds,
      activeRequest:
          clearActiveRequest ? null : (activeRequest ?? this.activeRequest),
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Wskaźnik odległości wozu technicznego od kolarza w interfejsie wyścigu (HUD).
///
/// Monitoruje regulaminowy próg 60 s przewagi grupy lidera nad peletonem:
/// poniżej 60 s sędziowie zamykają lukę (`Barrage Active`), co wydłuża czas
/// oczekiwania na wymianę koła, roweru lub podanie bidonów.
class LiveTeamCarGapIndicatorHud extends StatefulWidget {
  /// Dane telemetryczne pozycji wozu i przewagi grupy lidera.
  final TeamCarGapTelemetryData data;

  /// Callback wywoływany po kliknięciu żądania serwisu (koło, bidony, rower).
  final ValueChanged<TeamCarServiceRequestType>? onRequestService;

  /// Callback anulowania aktywnego zgłoszenia serwisowego.
  final VoidCallback? onCancelRequest;

  /// Callback zmiany stanu rozwinięcia panelu.
  final VoidCallback? onToggleExpanded;

  /// Czy panel startuje w stanie rozwiniętym.
  final bool initiallyExpanded;

  /// Czy cały widżet jest aktywny i przyjmuje interakcje.
  final bool enabled;

  const LiveTeamCarGapIndicatorHud({
    super.key,
    required this.data,
    this.onRequestService,
    this.onCancelRequest,
    this.onToggleExpanded,
    this.initiallyExpanded = true,
    this.enabled = true,
  });

  @override
  State<LiveTeamCarGapIndicatorHud> createState() =>
      _LiveTeamCarGapIndicatorHudState();
}

class _LiveTeamCarGapIndicatorHudState extends State<LiveTeamCarGapIndicatorHud>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late final AnimationController _pulseController;
  bool _isCardHovered = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _syncPulseAnimation();
  }

  @override
  void didUpdateWidget(covariant LiveTeamCarGapIndicatorHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.isBarrageActive != widget.data.isBarrageActive ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.data.isEnabled != widget.data.isEnabled) {
      _syncPulseAnimation();
    }
  }

  void _syncPulseAnimation() {
    final bool shouldPulse =
        widget.enabled && widget.data.isEnabled && widget.data.isBarrageActive;
    if (shouldPulse) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleToggleExpanded() {
    if (!widget.enabled || !widget.data.isEnabled) {
      return;
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggleExpanded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = widget.enabled && widget.data.isEnabled;
    final TeamCarBarrageStatus status = widget.data.barrageStatus;
    final Color statusColor = status.color;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact =
            constraints.maxWidth.isFinite && constraints.maxWidth < 360.0;
        final double horizontalPadding = isCompact ? 12.0 : 16.0;
        final double verticalPadding = isCompact ? 10.0 : 14.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _isCardHovered = true),
          onExit: (_) => setState(() => _isCardHovered = false),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            opacity: isInteractive ? 1.0 : 0.55,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: status == TeamCarBarrageStatus.barrageActive
                      ? statusColor.withValues(
                          alpha: _isCardHovered ? 0.85 : 0.55,
                        )
                      : (_isCardHovered && isInteractive
                          ? AppColors.goldAccent.withValues(alpha: 0.6)
                          : AppColors.cardBorder),
                  width: 1.0,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildHeader(
                    status: status,
                    statusColor: statusColor,
                    isInteractive: isInteractive,
                    isCompact: isCompact,
                  ),
                  const SizedBox(height: 10),
                  _buildBarrageThresholdBar(
                    status: status,
                    statusColor: statusColor,
                    isCompact: isCompact,
                  ),
                  const SizedBox(height: 10),
                  _buildConvoyDiagram(
                    status: status,
                    statusColor: statusColor,
                    isCompact: isCompact,
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 260),
                    sizeCurve: Curves.easeOutCubic,
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildExpandedServiceSection(
                        isInteractive: isInteractive,
                        isCompact: isCompact,
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required TeamCarBarrageStatus status,
    required Color statusColor,
    required bool isInteractive,
    required bool isCompact,
  }) {
    final String riderLabel = widget.data.riderName.trim().isEmpty
        ? 'Kolarz'
        : widget.data.riderName.trim();
    final String teamCode = widget.data.teamShortCode.trim().isEmpty
        ? 'TEAM'
        : widget.data.teamShortCode.trim().toUpperCase();

    return Row(
      children: <Widget>[
        Container(
          width: isCompact ? 30 : 34,
          height: isCompact ? 30 : 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Icon(
            status.isBlocked
                ? Icons.block_rounded
                : Icons.directions_car_filled_rounded,
            size: isCompact ? 16 : 18,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'WÓZ TECHNICZNY #${widget.data.safeDsCarNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      riderLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    child: Text(
                      teamCode,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (BuildContext context, Widget? child) {
            final double pulseAlpha = status.isBlocked
                ? (0.16 + 0.18 * _pulseController.value)
                : 0.14;
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 7 : 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: pulseAlpha),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.65),
                  width: 1.0,
                ),
              ),
              child: Text(
                status.badgeLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 9 : 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: statusColor,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        _HudIconButton(
          icon: _isExpanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          tooltip: _isExpanded ? 'Zwiń panel serwisu' : 'Rozwiń panel serwisu',
          enabled: isInteractive,
          onPressed: _handleToggleExpanded,
        ),
      ],
    );
  }

  Widget _buildBarrageThresholdBar({
    required TeamCarBarrageStatus status,
    required Color statusColor,
    required bool isCompact,
  }) {
    final double gapSec = widget.data.safeLeaderGapSeconds;
    final double thresholdSec = widget.data.safeBarrageThresholdSeconds;
    final double progress = widget.data.barrageThresholdProgress;

    final String helperText;
    if (status == TeamCarBarrageStatus.disabled) {
      helperText = 'Telemetria radia wyścigowego nieaktywna';
    } else if (status == TeamCarBarrageStatus.convoyBehindPeloton) {
      helperText = 'Kolarz w peletonie — brak blokady sędziowskiej';
    } else if (status == TeamCarBarrageStatus.barrageActive) {
      final double missing = widget.data.secondsToLiftBarrage;
      helperText =
          'Barrage: brakuje ${missing.toStringAsFixed(1)} s do otwarcia luki';
    } else {
      final double surplus = gapSec - thresholdSec;
      helperText =
          'Luka otwarta (+${surplus.toStringAsFixed(1)} s ponad próg UCI)';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Przewaga grupy lidera nad peletonem',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${gapSec.toStringAsFixed(1)} s / ${thresholdSec.toStringAsFixed(0)} s',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Container(color: AppColors.background),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0.0, end: progress),
                    builder: (BuildContext context, double animatedProgress,
                        Widget? child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: animatedProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helperText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: status.isBlocked
                  ? AppColors.amberWarning
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvoyDiagram({
    required TeamCarBarrageStatus status,
    required Color statusColor,
    required bool isCompact,
  }) {
    final double meters = widget.data.safeCarDistanceMeters;
    final double seconds = widget.data.safeCarGapSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'ODLEGŁOŚĆ WOZU OD KOLARZA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 9.5 : 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${meters.toStringAsFixed(0)} m  •  ${seconds.toStringAsFixed(1)} s',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  painter: _TeamCarConvoyGapPainter(
                    status: status,
                    statusColor: statusColor,
                    distanceMeters: meters,
                    pulseValue: _pulseController.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedServiceSection({
    required bool isInteractive,
    required bool isCompact,
  }) {
    final TeamCarServiceRequestType? activeRequest = widget.data.activeRequest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.data.barrageStatus.description,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        if (activeRequest != null) ...<Widget>[
          _buildActiveRequestBanner(
            requestType: activeRequest,
            isInteractive: isInteractive,
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TeamCarServiceRequestType.values.map((
            TeamCarServiceRequestType type,
          ) {
            final double eta = widget.data.estimateServiceEtaSeconds(type);
            final bool isSelected = activeRequest == type;
            return _ServiceActionButton(
              type: type,
              etaSeconds: eta,
              isBarrageDelayed: widget.data.isBarrageActive,
              isSelected: isSelected,
              enabled: isInteractive,
              compact: isCompact,
              onPressed: () => widget.onRequestService?.call(type),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildActiveRequestBanner({
    required TeamCarServiceRequestType requestType,
    required bool isInteractive,
  }) {
    final double eta = widget.data.estimateServiceEtaSeconds(requestType);
    final Color accent = widget.data.isBarrageActive
        ? AppColors.amberWarning
        : AppColors.goldAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Row(
        children: <Widget>[
          Icon(requestType.icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Wezwano: ${requestType.label} (ETA ~${eta.toStringAsFixed(0)} s)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: accent,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _HudTextActionButton(
            label: 'Anuluj',
            enabled: isInteractive,
            onPressed: widget.onCancelRequest,
          ),
        ],
      ),
    );
  }
}

class _TeamCarConvoyGapPainter extends CustomPainter {
  final TeamCarBarrageStatus status;
  final Color statusColor;
  final double distanceMeters;
  final double pulseValue;

  const _TeamCarConvoyGapPainter({
    required this.status,
    required this.statusColor,
    required this.distanceMeters,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height * 0.5;
    const double leftX = 12.0;
    final double rightX = size.width - 12.0;
    final double trackWidth = math.max(1.0, rightX - leftX);

    final Paint roadPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(leftX, centerY), Offset(rightX, centerY), roadPaint);

    final Paint pelotonPaint = Paint()..color = AppColors.textSecondary;
    canvas.drawCircle(Offset(leftX, centerY), 5.0, pelotonPaint);

    final Paint riderPaint = Paint()..color = AppColors.goldAccent;
    canvas.drawCircle(Offset(rightX, centerY), 5.5, riderPaint);

    final double normalizedDistance = (distanceMeters / 500.0).clamp(0.08, 0.85);
    final double carX = status.isBlocked
        ? leftX + trackWidth * 0.22
        : rightX - trackWidth * normalizedDistance;

    final Paint activeSpanPaint = Paint()
      ..color = statusColor.withValues(alpha: 0.75)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(carX, centerY),
      Offset(rightX, centerY),
      activeSpanPaint,
    );

    if (status.isBlocked) {
      final double gateX = leftX + trackWidth * 0.34;
      final Paint gatePaint = Paint()
        ..color = AppColors.crimsonAlert.withValues(
          alpha: 0.65 + 0.35 * pulseValue,
        )
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(gateX, centerY - 9),
        Offset(gateX, centerY + 9),
        gatePaint,
      );
    }

    final Rect carRect = Rect.fromCenter(
      center: Offset(carX, centerY),
      width: 16,
      height: 10,
    );
    final Paint carPaint = Paint()..color = statusColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(carRect, const Radius.circular(3)),
      carPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TeamCarConvoyGapPainter oldDelegate) {
    return oldDelegate.status != status ||
        oldDelegate.statusColor != statusColor ||
        oldDelegate.distanceMeters != distanceMeters ||
        oldDelegate.pulseValue != pulseValue;
  }
}

class _HudIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_HudIconButton> createState() => _HudIconButtonState();
}

class _HudIconButtonState extends State<_HudIconButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (_hovered && widget.enabled
            ? AppColors.textSecondary
            : AppColors.cardBorder);

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (bool focused) =>
            setState(() => _focused = focused),
        onShowHoverHighlight: (bool hovered) =>
            setState(() => _hovered = hovered),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _pressed
                  ? AppColors.primaryAccent.withValues(alpha: 0.35)
                  : (_hovered && widget.enabled
                      ? AppColors.surfaceLight
                      : AppColors.background),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceActionButton extends StatefulWidget {
  final TeamCarServiceRequestType type;
  final double etaSeconds;
  final bool isBarrageDelayed;
  final bool isSelected;
  final bool enabled;
  final bool compact;
  final VoidCallback onPressed;

  const _ServiceActionButton({
    required this.type,
    required this.etaSeconds,
    required this.isBarrageDelayed,
    required this.isSelected,
    required this.enabled,
    required this.compact,
    required this.onPressed,
  });

  @override
  State<_ServiceActionButton> createState() => _ServiceActionButtonState();
}

class _ServiceActionButtonState extends State<_ServiceActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color etaColor = widget.isBarrageDelayed
        ? AppColors.amberWarning
        : AppColors.statusSuccess;

    final Color bgColor;
    if (!widget.enabled) {
      bgColor = AppColors.background.withValues(alpha: 0.5);
    } else if (_pressed) {
      bgColor = AppColors.primaryAccent.withValues(alpha: 0.35);
    } else if (widget.isSelected) {
      bgColor = AppColors.primaryAccent.withValues(alpha: 0.25);
    } else if (_hovered) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.background;
    }

    final Color borderColor;
    if (_focused) {
      borderColor = AppColors.goldAccent;
    } else if (widget.isSelected) {
      borderColor = AppColors.goldAccent.withValues(alpha: 0.85);
    } else if (_hovered && widget.enabled) {
      borderColor = AppColors.textSecondary;
    } else {
      borderColor = AppColors.cardBorder;
    }

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (bool focused) =>
          setState(() => _focused = focused),
      onShowHoverHighlight: (bool hovered) =>
          setState(() => _hovered = hovered),
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 9 : 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.type.icon,
                size: 14,
                color: widget.isSelected
                    ? AppColors.goldAccent
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.compact ? widget.type.shortLabel : widget.type.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: etaColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '~${widget.etaSeconds.toStringAsFixed(0)}s',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: etaColor,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudTextActionButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  const _HudTextActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_HudTextActionButton> createState() => _HudTextActionButtonState();
}

class _HudTextActionButtonState extends State<_HudTextActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool canTap = widget.enabled && widget.onPressed != null;

    return FocusableActionDetector(
      enabled: canTap,
      onShowFocusHighlight: (bool focused) =>
          setState(() => _focused = focused),
      onShowHoverHighlight: (bool hovered) =>
          setState(() => _hovered = hovered),
      child: GestureDetector(
        onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
        onTapUp: canTap ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: canTap ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.crimsonAlert.withValues(alpha: 0.3)
                : (_hovered && canTap
                    ? AppColors.surfaceLight
                    : AppColors.background),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: canTap ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
