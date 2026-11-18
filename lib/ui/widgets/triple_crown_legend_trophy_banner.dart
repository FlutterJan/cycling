// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/career/historical_grand_tour_winners_timeline_db.dart';

/// Identyfikator jednego z trzech filarów Potrójnej Korony Kolarstwa.
enum TripleCrownLegId {
  giroDItalia(
    titlePl: "Giro d'Italia",
    jerseyName: 'Maglia Rosa',
    shortCode: 'GIRO',
    accentColor: AppColors.crimsonAlert,
    monthLabel: 'Maj',
  ),
  tourDeFrance(
    titlePl: 'Tour de France',
    jerseyName: 'Maillot Jaune',
    shortCode: 'TDF',
    accentColor: AppColors.goldAccent,
    monthLabel: 'Lipiec',
  ),
  uciWorldChampionship(
    titlePl: 'Mistrzostwa Świata UCI',
    jerseyName: 'Maillot Arc-en-Ciel',
    shortCode: 'MŚ UCI',
    accentColor: AppColors.accentBlue,
    monthLabel: 'Wrzesień',
  );

  final String titlePl;
  final String jerseyName;
  final String shortCode;
  final Color accentColor;
  final String monthLabel;

  const TripleCrownLegId({
    required this.titlePl,
    required this.jerseyName,
    required this.shortCode,
    required this.accentColor,
    required this.monthLabel,
  });

  String toJson() => name;

  static TripleCrownLegId fromJson(String value) {
    return TripleCrownLegId.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TripleCrownLegId.giroDItalia,
    );
  }
}

/// Podsumowanie pojedynczego wyścigu wchodzącego w skład Potrójnej Korony.
@immutable
class TripleCrownLegSummary {
  final TripleCrownLegId leg;
  final String raceName;
  final int? winningMarginSeconds;
  final double? averageSpeedKmh;
  final String? editionNotes;
  final bool isCompleted;

  const TripleCrownLegSummary({
    required this.leg,
    required this.raceName,
    this.winningMarginSeconds,
    this.averageSpeedKmh,
    this.editionNotes,
    this.isCompleted = true,
  });

  factory TripleCrownLegSummary.fromHistoryEntry(
    TripleCrownLegId leg,
    HistoricalRaceWinnerEntry entry,
  ) {
    return TripleCrownLegSummary(
      leg: leg,
      raceName: entry.raceId.displayName,
      winningMarginSeconds: entry.winningMarginSeconds,
      averageSpeedKmh: entry.averageSpeedKmh,
      editionNotes: entry.editionNotes,
      isCompleted: true,
    );
  }

  /// Formatuje przewagę czasową w formacie czytelnym dla kibica (`+1'42"` lub `+12 s`).
  String get formattedMargin {
    final seconds = winningMarginSeconds;
    if (seconds == null || seconds <= 0) {
      return 'Zwycięstwo';
    }
    if (seconds < 60) {
      return '+$seconds s';
    }
    final mins = seconds ~/ 60;
    final rem = seconds % 60;
    final remPadded = rem.toString().padLeft(2, '0');
    return "+$mins'$remPadded\"";
  }

  /// Formatuje średnią prędkość etapu/wyścigu z precyzją do 1 miejsca po przecinku.
  String get formattedSpeed {
    final speed = averageSpeedKmh;
    if (speed == null || speed <= 0) {
      return '— km/h';
    }
    return '${speed.toStringAsFixed(1)} km/h';
  }

  Map<String, dynamic> toJson() => {
        'leg': leg.toJson(),
        'raceName': raceName,
        'winningMarginSeconds': winningMarginSeconds,
        'averageSpeedKmh': averageSpeedKmh,
        'editionNotes': editionNotes,
        'isCompleted': isCompleted,
      };

  factory TripleCrownLegSummary.fromJson(Map<String, dynamic> json) {
    return TripleCrownLegSummary(
      leg: TripleCrownLegId.fromJson(json['leg'] as String? ?? 'giroDItalia'),
      raceName: json['raceName'] as String? ?? '',
      winningMarginSeconds: (json['winningMarginSeconds'] as num?)?.toInt(),
      averageSpeedKmh: (json['averageSpeedKmh'] as num?)?.toDouble(),
      editionNotes: json['editionNotes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }
}

/// Niemodyfikowalny model danych banera gratulacyjnego Potrójnej Korony Kolarstwa.
@immutable
class TripleCrownBannerData {
  final String riderId;
  final String riderName;
  final String countryCode;
  final String countryName;
  final String teamId;
  final String teamName;
  final int seasonYear;
  final bool isPlayerManaged;
  final TripleCrownLegSummary giroLeg;
  final TripleCrownLegSummary tourLeg;
  final TripleCrownLegSummary worldsLeg;
  final int totalSeasonWins;
  final int historicalRank;
  final bool isTrophyClaimed;

  const TripleCrownBannerData({
    required this.riderId,
    required this.riderName,
    required this.countryCode,
    required this.countryName,
    required this.teamId,
    required this.teamName,
    required this.seasonYear,
    required this.isPlayerManaged,
    required this.giroLeg,
    required this.tourLeg,
    required this.worldsLeg,
    required this.totalSeasonWins,
    this.historicalRank = 4,
    this.isTrophyClaimed = false,
  });

  /// Buduje dane banera bezpośrednio z rekordu [TripleCrownWinnerRecord].
  factory TripleCrownBannerData.fromRecord(
    TripleCrownWinnerRecord record, {
    int historicalRank = 4,
    bool isTrophyClaimed = false,
  }) {
    return TripleCrownBannerData(
      riderId: record.riderId,
      riderName: record.riderName,
      countryCode: record.countryCode,
      countryName: record.countryName,
      teamId: record.teamId,
      teamName: record.teamName,
      seasonYear: record.year,
      isPlayerManaged: record.isPlayerManaged,
      giroLeg: TripleCrownLegSummary.fromHistoryEntry(
        TripleCrownLegId.giroDItalia,
        record.giroEntry,
      ),
      tourLeg: TripleCrownLegSummary.fromHistoryEntry(
        TripleCrownLegId.tourDeFrance,
        record.tourEntry,
      ),
      worldsLeg: TripleCrownLegSummary.fromHistoryEntry(
        TripleCrownLegId.uciWorldChampionship,
        record.worldsRoadEntry,
      ),
      totalSeasonWins: record.totalTimelineWinsInYear,
      historicalRank: historicalRank,
      isTrophyClaimed: isTrophyClaimed,
    );
  }

  List<TripleCrownLegSummary> get legs => [giroLeg, tourLeg, worldsLeg];

  bool get isCompleteTripleCrown =>
      giroLeg.isCompleted && tourLeg.isCompleted && worldsLeg.isCompleted;

  TripleCrownBannerData copyWith({
    String? riderId,
    String? riderName,
    String? countryCode,
    String? countryName,
    String? teamId,
    String? teamName,
    int? seasonYear,
    bool? isPlayerManaged,
    TripleCrownLegSummary? giroLeg,
    TripleCrownLegSummary? tourLeg,
    TripleCrownLegSummary? worldsLeg,
    int? totalSeasonWins,
    int? historicalRank,
    bool? isTrophyClaimed,
  }) {
    return TripleCrownBannerData(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      seasonYear: seasonYear ?? this.seasonYear,
      isPlayerManaged: isPlayerManaged ?? this.isPlayerManaged,
      giroLeg: giroLeg ?? this.giroLeg,
      tourLeg: tourLeg ?? this.tourLeg,
      worldsLeg: worldsLeg ?? this.worldsLeg,
      totalSeasonWins: totalSeasonWins ?? this.totalSeasonWins,
      historicalRank: historicalRank ?? this.historicalRank,
      isTrophyClaimed: isTrophyClaimed ?? this.isTrophyClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'countryCode': countryCode,
        'countryName': countryName,
        'teamId': teamId,
        'teamName': teamName,
        'seasonYear': seasonYear,
        'isPlayerManaged': isPlayerManaged,
        'giroLeg': giroLeg.toJson(),
        'tourLeg': tourLeg.toJson(),
        'worldsLeg': worldsLeg.toJson(),
        'totalSeasonWins': totalSeasonWins,
        'historicalRank': historicalRank,
        'isTrophyClaimed': isTrophyClaimed,
      };

  factory TripleCrownBannerData.fromJson(Map<String, dynamic> json) {
    return TripleCrownBannerData(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? 'UCI',
      countryName: json['countryName'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      isPlayerManaged: json['isPlayerManaged'] as bool? ?? false,
      giroLeg: TripleCrownLegSummary.fromJson(
        (json['giroLeg'] as Map<String, dynamic>?) ?? const {},
      ),
      tourLeg: TripleCrownLegSummary.fromJson(
        (json['tourLeg'] as Map<String, dynamic>?) ?? const {},
      ),
      worldsLeg: TripleCrownLegSummary.fromJson(
        (json['worldsLeg'] as Map<String, dynamic>?) ?? const {},
      ),
      totalSeasonWins: (json['totalSeasonWins'] as num?)?.toInt() ?? 3,
      historicalRank: (json['historicalRank'] as num?)?.toInt() ?? 4,
      isTrophyClaimed: json['isTrophyClaimed'] as bool? ?? false,
    );
  }
}

/// Stan Riverpod zarządzający aktualnym banerem gratulacyjnym Potrójnej Korony.
@immutable
class TripleCrownCelebrationState {
  final TripleCrownBannerData? activeBanner;
  final bool isDismissed;
  final bool isExpanded;
  final TripleCrownLegId selectedLeg;

  const TripleCrownCelebrationState({
    this.activeBanner,
    this.isDismissed = false,
    this.isExpanded = false,
    this.selectedLeg = TripleCrownLegId.uciWorldChampionship,
  });

  bool get isVisible =>
      activeBanner != null && activeBanner!.isPlayerManaged && !isDismissed;

  TripleCrownCelebrationState copyWith({
    TripleCrownBannerData? activeBanner,
    bool clearBanner = false,
    bool? isDismissed,
    bool? isExpanded,
    TripleCrownLegId? selectedLeg,
  }) {
    return TripleCrownCelebrationState(
      activeBanner: clearBanner ? null : (activeBanner ?? this.activeBanner),
      isDismissed: isDismissed ?? this.isDismissed,
      isExpanded: isExpanded ?? this.isExpanded,
      selectedLeg: selectedLeg ?? this.selectedLeg,
    );
  }
}

/// Notifier obsługujący pojawienie się i odbiór Trofeum Potrójnej Korony Kolarstwa.
class TripleCrownCelebrationNotifier
    extends StateNotifier<TripleCrownCelebrationState> {
  TripleCrownCelebrationNotifier() : super(const TripleCrownCelebrationState());

  void showFromRecord(
    TripleCrownWinnerRecord record, {
    int historicalRank = 4,
  }) {
    if (!record.isPlayerManaged) return;
    state = TripleCrownCelebrationState(
      activeBanner: TripleCrownBannerData.fromRecord(
        record,
        historicalRank: historicalRank,
      ),
      isDismissed: false,
      isExpanded: false,
      selectedLeg: TripleCrownLegId.uciWorldChampionship,
    );
  }

  void showBanner(TripleCrownBannerData data) {
    state = TripleCrownCelebrationState(
      activeBanner: data,
      isDismissed: false,
      isExpanded: false,
      selectedLeg: TripleCrownLegId.uciWorldChampionship,
    );
  }

  void claimTrophy() {
    final current = state.activeBanner;
    if (current == null || current.isTrophyClaimed) return;
    state = state.copyWith(
      activeBanner: current.copyWith(isTrophyClaimed: true),
    );
  }

  void selectLeg(TripleCrownLegId leg) {
    state = state.copyWith(selectedLeg: leg, isExpanded: true);
  }

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void dismiss() {
    state = state.copyWith(isDismissed: true);
  }

  void reset() {
    state = const TripleCrownCelebrationState();
  }
}

/// Globalny provider banera gratulacyjnego Potrójnej Korony Kolarstwa.
final tripleCrownCelebrationProvider = StateNotifierProvider<
    TripleCrownCelebrationNotifier, TripleCrownCelebrationState>(
  (ref) => TripleCrownCelebrationNotifier(),
);

/// Pięć oficjalnych pasów tęczowych UCI (niebieski, czerwony, czarny, żółty, zielony).
const List<Color> _kUciRainbowStripeColors = [
  Color(0xFF0072CE),
  Color(0xFFEF3340),
  Color(0xFF111318),
  Color(0xFFFFD100),
  Color(0xFF009A44),
];

/// Specjalny złoto-tęczowy baner gratulacyjny wyświetlany, gdy kolarz
/// prowadzony przez gracza zdobędzie historyczną *Potrójną Koronę Kolarstwa*
/// (Giro d'Italia + Tour de France + Mistrzostwa Świata UCI w jednym sezonie).
class TripleCrownLegendTrophyBanner extends StatefulWidget {
  final TripleCrownBannerData? data;
  final bool isEnabled;
  final bool showOnlyForPlayerManaged;
  final bool initialExpanded;
  final VoidCallback? onClaimTrophy;
  final VoidCallback? onOpenHallOfFame;
  final VoidCallback? onDismiss;
  final ValueChanged<TripleCrownLegId>? onLegSelected;

  const TripleCrownLegendTrophyBanner({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.showOnlyForPlayerManaged = true,
    this.initialExpanded = false,
    this.onClaimTrophy,
    this.onOpenHallOfFame,
    this.onDismiss,
    this.onLegSelected,
  });

  @override
  State<TripleCrownLegendTrophyBanner> createState() =>
      _TripleCrownLegendTrophyBannerState();
}

class _TripleCrownLegendTrophyBannerState
    extends State<TripleCrownLegendTrophyBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late bool _isExpanded;
  TripleCrownLegId _selectedLeg = TripleCrownLegId.uciWorldChampionship;
  bool _isBannerHovered = false;
  bool _isBannerFocused = false;
  bool _localClaimed = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _localClaimed = widget.data?.isTrophyClaimed ?? false;
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant TripleCrownLegendTrophyBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data?.isTrophyClaimed != oldWidget.data?.isTrophyClaimed) {
      _localClaimed = widget.data?.isTrophyClaimed ?? false;
    }
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled && !_shimmerController.isAnimating) {
        _shimmerController.repeat();
      } else if (!widget.isEnabled && _shimmerController.isAnimating) {
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  bool get _isClaimed => (widget.data?.isTrophyClaimed ?? false) || _localClaimed;

  void _handleSelectLeg(TripleCrownLegId leg) {
    if (!widget.isEnabled) return;
    setState(() {
      if (_selectedLeg == leg && _isExpanded) {
        _isExpanded = false;
      } else {
        _selectedLeg = leg;
        _isExpanded = true;
      }
    });
    widget.onLegSelected?.call(leg);
  }

  void _handleClaim() {
    if (!widget.isEnabled || _isClaimed) return;
    setState(() {
      _localClaimed = true;
    });
    widget.onClaimTrophy?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bannerData = widget.data;
    if (bannerData == null) {
      return _buildEmptyStateCard();
    }
    if (widget.showOnlyForPlayerManaged && !bannerData.isPlayerManaged) {
      return _buildNonPlayerStateCard(bannerData);
    }

    final borderColor = !widget.isEnabled
        ? AppColors.cardBorder
        : _isBannerFocused
            ? AppColors.cyanAccent
            : _isBannerHovered
                ? AppColors.goldAccent
                : AppColors.goldAccent.withValues(alpha: 0.72);

    return Semantics(
      container: true,
      label:
          'Baner gratulacyjny Potrójnej Korony Kolarstwa dla ${bannerData.riderName} za sezon ${bannerData.seasonYear}',
      child: FocusableActionDetector(
        enabled: widget.isEnabled,
        onShowFocusHighlight: (focused) {
          if (_isBannerFocused != focused) {
            setState(() => _isBannerFocused = focused);
          }
        },
        child: MouseRegion(
          onEnter: (_) {
            if (widget.isEnabled && !_isBannerHovered) {
              setState(() => _isBannerHovered = true);
            }
          },
          onExit: (_) {
            if (_isBannerHovered) {
              setState(() => _isBannerHovered = false);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: _isBannerFocused || _isBannerHovered ? 1.5 : 1.0,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceLight,
                  AppColors.surface,
                  AppColors.background,
                ],
              ),
              boxShadow: [
                if (widget.isEnabled)
                  BoxShadow(
                    color: AppColors.goldAccent.withValues(
                      alpha: _isBannerHovered ? 0.24 : 0.14,
                    ),
                    blurRadius: _isBannerHovered ? 24 : 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRainbowGoldTopRibbon(),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isMobile = width < 600;
                      final isDesktop = width >= 980;
                      final horizontalPad = isMobile ? 14.0 : 20.0;

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPad,
                          16,
                          horizontalPad,
                          16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isDesktop)
                              _buildDesktopMainRow(bannerData)
                            else
                              _buildCompactMainColumn(
                                bannerData,
                                isMobile: isMobile,
                              ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              child: _isExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: _buildExpandedLegDetail(
                                        bannerData,
                                        isMobile: isMobile,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildRainbowGoldBottomAccent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRainbowGoldTopRibbon() {
    return SizedBox(
      height: 8,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          return CustomPaint(
            painter: _TripleCrownRainbowBandPainter(
              shimmerProgress:
                  widget.isEnabled ? _shimmerController.value : 0.25,
              isEnabled: widget.isEnabled,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRainbowGoldBottomAccent() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isEnabled
              ? const [
                  AppColors.goldAccent,
                  Color(0xFF0072CE),
                  Color(0xFFEF3340),
                  Color(0xFFFFD100),
                  Color(0xFF009A44),
                  AppColors.goldAccent,
                ]
              : const [
                  AppColors.cardBorder,
                  AppColors.surfaceLight,
                  AppColors.cardBorder,
                ],
        ),
      ),
    );
  }

  Widget _buildDesktopMainRow(TripleCrownBannerData bannerData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTrophyCrestBadge(size: 80),
        const SizedBox(width: 18),
        Expanded(
          flex: 5,
          child: _buildIdentityHeader(bannerData, isMobile: false),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: _buildLegChipsRow(bannerData, isMobile: false),
        ),
        const SizedBox(width: 16),
        _buildActionCluster(bannerData, isVertical: true),
      ],
    );
  }

  Widget _buildCompactMainColumn(
    TripleCrownBannerData bannerData, {
    required bool isMobile,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrophyCrestBadge(size: isMobile ? 58 : 70),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: _buildIdentityHeader(bannerData, isMobile: isMobile),
            ),
            if (widget.onDismiss != null) ...[
              const SizedBox(width: 6),
              _TripleCrownIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Zamknij baner',
                isEnabled: widget.isEnabled,
                onPressed: widget.onDismiss,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _buildLegChipsRow(bannerData, isMobile: isMobile),
        const SizedBox(height: 14),
        _buildActionCluster(bannerData, isVertical: false, isMobile: isMobile),
      ],
    );
  }

  Widget _buildTrophyCrestBadge({required double size}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final pulse = widget.isEnabled
            ? 0.5 + 0.5 * math.sin(_shimmerController.value * 2 * math.pi)
            : 0.0;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
            border: Border.all(
              color: widget.isEnabled
                  ? Color.lerp(
                      AppColors.goldAccent,
                      const Color(0xFFFFE58F),
                      pulse * 0.5,
                    )!
                  : AppColors.cardBorder,
              width: 2.0,
            ),
            boxShadow: [
              if (widget.isEnabled)
                BoxShadow(
                  color: AppColors.goldAccent.withValues(
                    alpha: 0.18 + pulse * 0.16,
                  ),
                  blurRadius: 14 + pulse * 6,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: CustomPaint(
            painter: _TripleCrownTrophyCrestPainter(
              glowPhase: pulse,
              isEnabled: widget.isEnabled,
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentityHeader(
    TripleCrownBannerData bannerData, {
    required bool isMobile,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildGoldRainbowPill(
              label: 'POTRÓJNA KORONA KOLARSTWA • ${bannerData.seasonYear}',
            ),
            _buildRankBadge(bannerData.historicalRank),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          bannerData.riderName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isMobile ? 19 : 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: widget.isEnabled
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${bannerData.teamName} • ${bannerData.countryCode} • ${bannerData.totalSeasonWins} zw. w sezonie',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildGoldRainbowPill({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: widget.isEnabled
              ? [
                  AppColors.goldAccent.withValues(alpha: 0.24),
                  AppColors.primaryAccent.withValues(alpha: 0.22),
                  AppColors.accentBlue.withValues(alpha: 0.2),
                ]
              : [
                  AppColors.surfaceLight,
                  AppColors.surfaceLight,
                ],
        ),
        border: Border.all(
          color: widget.isEnabled
              ? AppColors.goldAccent.withValues(alpha: 0.8)
              : AppColors.cardBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: widget.isEnabled
              ? AppColors.goldAccent
              : AppColors.textSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Text(
        '#$rank W HISTORII',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildLegChipsRow(
    TripleCrownBannerData bannerData, {
    required bool isMobile,
  }) {
    final legs = bannerData.legs;
    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < legs.length; i++) ...[
            _TripleCrownLegTile(
              summary: legs[i],
              isSelected: _isExpanded && _selectedLeg == legs[i].leg,
              isEnabled: widget.isEnabled,
              onTap: () => _handleSelectLeg(legs[i].leg),
            ),
            if (i < legs.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < legs.length; i++) ...[
          Expanded(
            child: _TripleCrownLegTile(
              summary: legs[i],
              isSelected: _isExpanded && _selectedLeg == legs[i].leg,
              isEnabled: widget.isEnabled,
              onTap: () => _handleSelectLeg(legs[i].leg),
            ),
          ),
          if (i < legs.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildExpandedLegDetail(
    TripleCrownBannerData bannerData, {
    required bool isMobile,
  }) {
    final summary = bannerData.legs.firstWhere(
      (l) => l.leg == _selectedLeg,
      orElse: () => bannerData.worldsLeg,
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: summary.leg.accentColor.withValues(alpha: 0.45),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: summary.leg.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${summary.leg.titlePl} • ${summary.leg.jerseyName}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Przewaga: ${summary.formattedMargin}  |  Śr. prędkość: ${summary.formattedSpeed}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (summary.editionNotes != null &&
              summary.editionNotes!.trim().isNotEmpty)
            Text(
              summary.editionNotes!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCluster(
    TripleCrownBannerData bannerData, {
    required bool isVertical,
    bool isMobile = false,
  }) {
    final claimButton = _TripleCrownActionButton(
      label: _isClaimed ? 'Trofeum w Gablocie' : 'Odbierz Trofeum',
      icon: _isClaimed
          ? Icons.verified_rounded
          : Icons.emoji_events_rounded,
      isPrimary: true,
      isEnabled: widget.isEnabled && !_isClaimed,
      onPressed: _handleClaim,
    );

    final historyButton = _TripleCrownActionButton(
      label: 'Aleja Legend',
      icon: Icons.history_edu_rounded,
      isPrimary: false,
      isEnabled: widget.isEnabled && widget.onOpenHallOfFame != null,
      onPressed: widget.onOpenHallOfFame,
    );

    if (isVertical) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 185, maxWidth: 215),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _TripleCrownIconButton(
                  icon: _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  tooltip: _isExpanded ? 'Zwiń szczegóły' : 'Pokaż szczegóły',
                  isEnabled: widget.isEnabled,
                  onPressed: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                ),
                if (widget.onDismiss != null) ...[
                  const SizedBox(width: 6),
                  _TripleCrownIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Zamknij baner',
                    isEnabled: widget.isEnabled,
                    onPressed: widget.onDismiss,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            claimButton,
            const SizedBox(height: 8),
            historyButton,
          ],
        ),
      );
    }

    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          claimButton,
          const SizedBox(height: 8),
          historyButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: claimButton),
        const SizedBox(width: 10),
        Expanded(child: historyButton),
      ],
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: AppColors.textSecondary,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Brak aktywnego osiągnięcia Potrójnej Korony Kolarstwa w tym sezonie.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonPlayerStateCard(TripleCrownBannerData bannerData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.public_rounded,
            color: AppColors.goldAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Historyczna Potrójna Korona ${bannerData.seasonYear} zdobyta przez rywala: ${bannerData.riderName} (${bannerData.teamName}).',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripleCrownLegTile extends StatefulWidget {
  final TripleCrownLegSummary summary;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _TripleCrownLegTile({
    required this.summary,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_TripleCrownLegTile> createState() => _TripleCrownLegTileState();
}

class _TripleCrownLegTileState extends State<_TripleCrownLegTile> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.summary.leg.accentColor;
    final bgColor = !widget.isEnabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _isPressed
            ? accent.withValues(alpha: 0.24)
            : widget.isSelected
                ? accent.withValues(alpha: 0.18)
                : _isHovered
                    ? AppColors.surfaceLight
                    : AppColors.background.withValues(alpha: 0.68);

    final borderColor = !widget.isEnabled
        ? AppColors.cardBorder
        : _isFocused
            ? AppColors.cyanAccent
            : widget.isSelected || _isHovered
                ? accent
                : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowFocusHighlight: (focused) {
        if (_isFocused != focused) setState(() => _isFocused = focused);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) {
          if (widget.isEnabled) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (_isHovered || _isPressed) {
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
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: () {
            if (_isPressed) setState(() => _isPressed = false);
          },
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isEnabled
                            ? accent
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.summary.leg.shortCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: widget.isEnabled
                              ? accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      widget.summary.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: widget.isEnabled
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.summary.leg.titlePl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.summary.leg.jerseyName} • ${widget.summary.formattedMargin}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripleCrownActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _TripleCrownActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<_TripleCrownActionButton> createState() =>
      _TripleCrownActionButtonState();
}

class _TripleCrownActionButtonState extends State<_TripleCrownActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled && widget.onPressed != null;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    if (!enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.5);
      fgColor = AppColors.textSecondary;
      borderColor = AppColors.cardBorder;
    } else if (widget.isPrimary) {
      bgColor = _isPressed
          ? const Color(0xFFB59128)
          : _isHovered
              ? const Color(0xFFE5C14B)
              : AppColors.goldAccent;
      fgColor = AppColors.background;
      borderColor = _isFocused ? AppColors.cyanAccent : AppColors.goldAccent;
    } else {
      bgColor = _isPressed
          ? AppColors.surfaceLight
          : _isHovered
              ? AppColors.surfaceLight
              : AppColors.background;
      fgColor = AppColors.textPrimary;
      borderColor = _isFocused
          ? AppColors.cyanAccent
          : _isHovered
              ? AppColors.goldAccent
              : const Color(0xFF2A2F3D);
    }

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (focused) {
        if (_isFocused != focused) setState(() => _isFocused = focused);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (enabled) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (_isHovered || _isPressed) {
            setState(() {
              _isHovered = false;
              _isPressed = false;
            });
          }
        },
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: () {
            if (_isPressed) setState(() => _isPressed = false);
          },
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: fgColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: fgColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripleCrownIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _TripleCrownIconButton({
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<_TripleCrownIconButton> createState() => _TripleCrownIconButtonState();
}

class _TripleCrownIconButtonState extends State<_TripleCrownIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled && widget.onPressed != null;

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (focused) {
          if (_isFocused != focused) setState(() => _isFocused = focused);
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (enabled) widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor:
              enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) {
            if (enabled) setState(() => _isHovered = true);
          },
          onExit: (_) {
            if (_isHovered || _isPressed) {
              setState(() {
                _isHovered = false;
                _isPressed = false;
              });
            }
          },
          child: GestureDetector(
            onTapDown:
                enabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel: () {
              if (_isPressed) setState(() => _isPressed = false);
            },
            onTap: enabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _isPressed
                    ? AppColors.surfaceLight
                    : _isHovered
                        ? AppColors.surfaceLight
                        : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isFocused
                      ? AppColors.cyanAccent
                      : _isHovered
                          ? AppColors.goldAccent
                          : const Color(0xFF2A2F3D),
                ),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rysuje 5-pasmową tęczę Mistrza Świata UCI z ruchomym złotym połyskiem.
class _TripleCrownRainbowBandPainter extends CustomPainter {
  final double shimmerProgress;
  final bool isEnabled;

  const _TripleCrownRainbowBandPainter({
    required this.shimmerProgress,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stripeWidth = size.width / _kUciRainbowStripeColors.length;
    for (var i = 0; i < _kUciRainbowStripeColors.length; i++) {
      final paint = Paint()
        ..color = isEnabled
            ? _kUciRainbowStripeColors[i]
            : AppColors.surfaceLight;
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth + 0.5, size.height),
        paint,
      );
    }

    if (!isEnabled) return;

    final shimmerCenter = (shimmerProgress * 1.4 - 0.2) * size.width;
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          AppColors.goldAccent.withValues(alpha: 0.72),
          const Color(0xFFFFF3C4).withValues(alpha: 0.85),
          AppColors.goldAccent.withValues(alpha: 0.72),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(
          center: Offset(shimmerCenter, size.height / 2),
          width: math.max(90, size.width * 0.28),
          height: size.height,
        ),
      );
    canvas.drawRect(Offset.zero & size, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant _TripleCrownRainbowBandPainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.isEnabled != isEnabled;
  }
}

/// Rysuje złote trofeum z trzema koronami i tęczową wstęgą w środku.
class _TripleCrownTrophyCrestPainter extends CustomPainter {
  final double glowPhase;
  final bool isEnabled;

  const _TripleCrownTrophyCrestPainter({
    required this.glowPhase,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.36;

    final goldColor = isEnabled
        ? Color.lerp(
            AppColors.goldAccent,
            const Color(0xFFFFE58F),
            glowPhase * 0.35,
          )!
        : AppColors.textSecondary;

    // Złota korona z trzema szczytami
    final crownPath = Path()
      ..moveTo(cx - radius * 0.72, cy + radius * 0.32)
      ..lineTo(cx - radius * 0.82, cy - radius * 0.34)
      ..lineTo(cx - radius * 0.36, cy - radius * 0.04)
      ..lineTo(cx, cy - radius * 0.56)
      ..lineTo(cx + radius * 0.36, cy - radius * 0.04)
      ..lineTo(cx + radius * 0.82, cy - radius * 0.34)
      ..lineTo(cx + radius * 0.72, cy + radius * 0.32)
      ..close();

    final crownPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          goldColor,
          isEnabled ? const Color(0xFF9C7A1C) : AppColors.surfaceLight,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawPath(crownPath, crownPaint);

    // Trzy klejnoty korony (Różowy Giro, Żółty Tour, Niebieski MŚ)
    final jewelColors = isEnabled
        ? const [
            AppColors.crimsonAlert,
            AppColors.goldAccent,
            AppColors.accentBlue,
          ]
        : const [
            AppColors.textSecondary,
            AppColors.textSecondary,
            AppColors.textSecondary,
          ];
    final jewelOffsets = [
      Offset(cx - radius * 0.82, cy - radius * 0.38),
      Offset(cx, cy - radius * 0.60),
      Offset(cx + radius * 0.82, cy - radius * 0.38),
    ];
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        jewelOffsets[i],
        radius * 0.13,
        Paint()..color = jewelColors[i],
      );
    }

    // Dolna 5-pasmowa wstęga tęczowa UCI
    final bandTop = cy + radius * 0.42;
    final bandWidth = radius * 1.44;
    final bandLeft = cx - bandWidth / 2;
    final stripeW = bandWidth / _kUciRainbowStripeColors.length;
    for (var i = 0; i < _kUciRainbowStripeColors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          bandLeft + i * stripeW,
          bandTop,
          stripeW + 0.4,
          radius * 0.22,
        ),
        Paint()
          ..color = isEnabled
              ? _kUciRainbowStripeColors[i]
              : AppColors.surfaceLight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TripleCrownTrophyCrestPainter oldDelegate) {
    return oldDelegate.glowPhase != glowPhase ||
        oldDelegate.isEnabled != isEnabled;
  }
}
