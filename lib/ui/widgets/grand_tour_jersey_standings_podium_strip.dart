import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/race/tour_race.dart';

/// Tryb prezentacji paska 4 koszulek Grand Touru.
enum GrandTourStripMode {
  liveRace,
  podiumCeremony,
}

/// Edycja Wielkiego Touru definiująca nazewnictwo i barwy 4 koszulek.
enum GrandTourEdition {
  tourDeFrance,
  giroDItalia,
  vueltaAEspana,
}

/// Cztery główne klasyfikacje indywidualne Grand Touru.
enum GrandTourJerseyClassification {
  generalClassification,
  pointsClassification,
  mountainsClassification,
  youthClassification,
}

/// Specyfikacja wizualna pojedynczej koszulki w zależności od edycji Grand Touru.
class GrandTourJerseyVisualSpec {
  final GrandTourJerseyClassification classification;
  final String jerseyName;
  final String shortCode;
  final String metricLabel;
  final Color primaryColor;
  final Color trimColor;
  final Color textOnJerseyColor;
  final bool hasPolkaDots;
  final Color? polkaDotColor;

  const GrandTourJerseyVisualSpec({
    required this.classification,
    required this.jerseyName,
    required this.shortCode,
    required this.metricLabel,
    required this.primaryColor,
    required this.trimColor,
    required this.textOnJerseyColor,
    this.hasPolkaDots = false,
    this.polkaDotColor,
  });

  /// Zwraca oficjalną specyfikację koszulki dla danej edycji i klasyfikacji.
  static GrandTourJerseyVisualSpec resolve(
    GrandTourEdition edition,
    GrandTourJerseyClassification classification,
  ) {
    switch (edition) {
      case GrandTourEdition.tourDeFrance:
        switch (classification) {
          case GrandTourJerseyClassification.generalClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.generalClassification,
              jerseyName: 'Maillot Jaune',
              shortCode: 'GC',
              metricLabel: 'Klasyfikacja Generalna',
              primaryColor: Color(0xFFFACC15),
              trimColor: AppColors.background,
              textOnJerseyColor: AppColors.background,
            );
          case GrandTourJerseyClassification.pointsClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.pointsClassification,
              jerseyName: 'Maillot Vert',
              shortCode: 'PTS',
              metricLabel: 'Klasyfikacja Punktowa',
              primaryColor: AppColors.emeraldGreen,
              trimColor: AppColors.background,
              textOnJerseyColor: AppColors.textPrimary,
            );
          case GrandTourJerseyClassification.mountainsClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.mountainsClassification,
              jerseyName: 'Maillot à Pois',
              shortCode: 'KOM',
              metricLabel: 'Klasyfikacja Górska',
              primaryColor: AppColors.textPrimary,
              trimColor: AppColors.crimsonAlert,
              textOnJerseyColor: AppColors.crimsonAlert,
              hasPolkaDots: true,
              polkaDotColor: AppColors.crimsonAlert,
            );
          case GrandTourJerseyClassification.youthClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.youthClassification,
              jerseyName: 'Maillot Blanc',
              shortCode: 'U25',
              metricLabel: 'Klasyfikacja Młodzieżowa',
              primaryColor: AppColors.textPrimary,
              trimColor: AppColors.accentBlue,
              textOnJerseyColor: AppColors.background,
            );
        }
      case GrandTourEdition.giroDItalia:
        switch (classification) {
          case GrandTourJerseyClassification.generalClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.generalClassification,
              jerseyName: 'Maglia Rosa',
              shortCode: 'GC',
              metricLabel: 'Klasyfikacja Generalna',
              primaryColor: Color(0xFFF472B6),
              trimColor: AppColors.background,
              textOnJerseyColor: AppColors.background,
            );
          case GrandTourJerseyClassification.pointsClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.pointsClassification,
              jerseyName: 'Maglia Ciclamino',
              shortCode: 'PTS',
              metricLabel: 'Klasyfikacja Punktowa',
              primaryColor: Color(0xFFC026D3),
              trimColor: AppColors.textPrimary,
              textOnJerseyColor: AppColors.textPrimary,
            );
          case GrandTourJerseyClassification.mountainsClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.mountainsClassification,
              jerseyName: 'Maglia Azzurra',
              shortCode: 'KOM',
              metricLabel: 'Klasyfikacja Górska',
              primaryColor: AppColors.accentBlue,
              trimColor: AppColors.background,
              textOnJerseyColor: AppColors.background,
            );
          case GrandTourJerseyClassification.youthClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.youthClassification,
              jerseyName: 'Maglia Bianca',
              shortCode: 'U25',
              metricLabel: 'Klasyfikacja Młodzieżowa',
              primaryColor: AppColors.textPrimary,
              trimColor: AppColors.goldAccent,
              textOnJerseyColor: AppColors.background,
            );
        }
      case GrandTourEdition.vueltaAEspana:
        switch (classification) {
          case GrandTourJerseyClassification.generalClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.generalClassification,
              jerseyName: 'La Roja',
              shortCode: 'GC',
              metricLabel: 'Klasyfikacja Generalna',
              primaryColor: AppColors.crimsonAlert,
              trimColor: AppColors.goldAccent,
              textOnJerseyColor: AppColors.textPrimary,
            );
          case GrandTourJerseyClassification.pointsClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.pointsClassification,
              jerseyName: 'Maillot Verde',
              shortCode: 'PTS',
              metricLabel: 'Klasyfikacja Punktowa',
              primaryColor: AppColors.emeraldGreen,
              trimColor: AppColors.textPrimary,
              textOnJerseyColor: AppColors.textPrimary,
            );
          case GrandTourJerseyClassification.mountainsClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.mountainsClassification,
              jerseyName: 'Maillot de Lunares',
              shortCode: 'KOM',
              metricLabel: 'Klasyfikacja Górska',
              primaryColor: AppColors.textPrimary,
              trimColor: AppColors.accentBlue,
              textOnJerseyColor: AppColors.accentBlue,
              hasPolkaDots: true,
              polkaDotColor: AppColors.accentBlue,
            );
          case GrandTourJerseyClassification.youthClassification:
            return const GrandTourJerseyVisualSpec(
              classification: GrandTourJerseyClassification.youthClassification,
              jerseyName: 'Maillot Blanco',
              shortCode: 'U25',
              metricLabel: 'Klasyfikacja Młodzieżowa',
              primaryColor: AppColors.textPrimary,
              trimColor: AppColors.primaryAccent,
              textOnJerseyColor: AppColors.background,
            );
        }
    }
  }
}

/// Posiadacz pojedynczej koszulki klasyfikacji Grand Touru (na żywo lub na podium).
class GrandTourJerseyHolder {
  final GrandTourJerseyClassification classification;
  final String riderId;
  final String riderName;
  final String teamName;
  final String teamCode;
  final String nationalityCode;
  final Color teamColor;
  final int? totalTimeSeconds;
  final int? timeAdvantageSeconds;
  final int? points;
  final int? pointsAdvantage;
  final String? stageDeltaText;
  final bool isPlayerTeam;
  final bool isVirtualLeaderChange;
  final String? previousLeaderName;
  final String? runnerUpName;
  final String? runnerUpGapText;
  final bool isEnabled;

  const GrandTourJerseyHolder({
    required this.classification,
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.teamCode,
    required this.nationalityCode,
    required this.teamColor,
    this.totalTimeSeconds,
    this.timeAdvantageSeconds,
    this.points,
    this.pointsAdvantage,
    this.stageDeltaText,
    this.isPlayerTeam = false,
    this.isVirtualLeaderChange = false,
    this.previousLeaderName,
    this.runnerUpName,
    this.runnerUpGapText,
    this.isEnabled = true,
  });

  bool get isTimeBased =>
      classification == GrandTourJerseyClassification.generalClassification ||
      classification == GrandTourJerseyClassification.youthClassification;

  /// Główna wartość liczbowa dla paska (czas łączny lub suma punktów).
  String formattedPrimaryMetric() {
    if (isTimeBased) {
      final int secs = math.max(0, totalTimeSeconds ?? 0);
      final int hours = secs ~/ 3600;
      final int mins = (secs % 3600) ~/ 60;
      final int remSecs = secs % 60;
      return '${hours}h ${mins.toString().padLeft(2, '0')}\' ${remSecs.toString().padLeft(2, '0')}"';
    }
    return '${math.max(0, points ?? 0)} pkt';
  }

  /// Przewaga nad drugim zawodnikiem w klasyfikacji.
  String formattedAdvantageOverSecond() {
    if (isTimeBased) {
      final int adv = math.max(0, timeAdvantageSeconds ?? 0);
      if (adv == 0) return 'Równy czas z #2';
      final int mins = adv ~/ 60;
      final int secs = adv % 60;
      if (mins > 0) {
        return '+$mins:${secs.toString().padLeft(2, '0')} nad #2';
      }
      return '+${secs}s nad #2';
    }
    final int ptsAdv = math.max(0, pointsAdvantage ?? 0);
    if (ptsAdv == 0) return 'Remis z #2';
    return '+$ptsAdv pkt nad #2';
  }
}

/// Kompletny zestaw danych dla paska 4 koszulek klasyfikacji Grand Touru.
class GrandTourJerseyStandingsData {
  final GrandTourEdition edition;
  final int stageNumber;
  final int totalStages;
  final String stageName;
  final double? kmRemaining;
  final List<GrandTourJerseyHolder> holders;

  const GrandTourJerseyStandingsData({
    required this.edition,
    required this.stageNumber,
    this.totalStages = 21,
    required this.stageName,
    this.kmRemaining,
    required this.holders,
  });

  String get editionDisplayName {
    switch (edition) {
      case GrandTourEdition.tourDeFrance:
        return 'Tour de France';
      case GrandTourEdition.giroDItalia:
        return "Giro d'Italia";
      case GrandTourEdition.vueltaAEspana:
        return 'Vuelta a España';
    }
  }

  /// Buduje dane paska bezpośrednio z modelu `RaceClassifications` (`tour_race.dart`).
  factory GrandTourJerseyStandingsData.fromRaceClassifications({
    required GrandTourEdition edition,
    required int stageNumber,
    int totalStages = 21,
    required String stageName,
    double? kmRemaining,
    required RaceClassifications classifications,
    String? playerTeamId,
    Map<String, String> teamNamesById = const {},
    Map<String, Color> teamColorsById = const {},
    Map<String, String> riderNationalitiesById = const {},
    Set<GrandTourJerseyClassification> virtualChangedJerseys = const {},
  }) {
    final List<GrandTourJerseyHolder> result = [];

    void addTimeClassification(
      GrandTourJerseyClassification type,
      List<RiderClassificationEntry> entries,
    ) {
      if (entries.isEmpty) return;
      final RiderClassificationEntry leader = entries.first;
      final RiderClassificationEntry? second =
          entries.length > 1 ? entries[1] : null;
      final int adv = second != null
          ? math.max(0, second.totalTimeSeconds - leader.totalTimeSeconds)
          : 0;
      final String teamName = teamNamesById[leader.teamId] ?? leader.teamId;
      result.add(
        GrandTourJerseyHolder(
          classification: type,
          riderId: leader.riderId,
          riderName: leader.riderName,
          teamName: teamName,
          teamCode: _buildTeamCode(teamName),
          nationalityCode: riderNationalitiesById[leader.riderId] ?? 'INT',
          teamColor: teamColorsById[leader.teamId] ?? AppColors.primaryAccent,
          totalTimeSeconds: leader.totalTimeSeconds,
          timeAdvantageSeconds: adv,
          isPlayerTeam: playerTeamId != null && leader.teamId == playerTeamId,
          isVirtualLeaderChange: virtualChangedJerseys.contains(type),
          runnerUpName: second?.riderName,
          runnerUpGapText: second != null ? _formatGapSeconds(adv) : null,
        ),
      );
    }

    void addPointsClassification(
      GrandTourJerseyClassification type,
      List<RiderClassificationEntry> entries,
    ) {
      if (entries.isEmpty) return;
      final RiderClassificationEntry leader = entries.first;
      final RiderClassificationEntry? second =
          entries.length > 1 ? entries[1] : null;
      final int adv =
          second != null ? math.max(0, leader.points - second.points) : 0;
      final String teamName = teamNamesById[leader.teamId] ?? leader.teamId;
      result.add(
        GrandTourJerseyHolder(
          classification: type,
          riderId: leader.riderId,
          riderName: leader.riderName,
          teamName: teamName,
          teamCode: _buildTeamCode(teamName),
          nationalityCode: riderNationalitiesById[leader.riderId] ?? 'INT',
          teamColor: teamColorsById[leader.teamId] ?? AppColors.accentBlue,
          points: leader.points,
          pointsAdvantage: adv,
          isPlayerTeam: playerTeamId != null && leader.teamId == playerTeamId,
          isVirtualLeaderChange: virtualChangedJerseys.contains(type),
          runnerUpName: second?.riderName,
          runnerUpGapText: second != null ? '-$adv pkt' : null,
        ),
      );
    }

    addTimeClassification(
      GrandTourJerseyClassification.generalClassification,
      classifications.generalClassification,
    );
    addPointsClassification(
      GrandTourJerseyClassification.pointsClassification,
      classifications.pointsClassification,
    );
    addPointsClassification(
      GrandTourJerseyClassification.mountainsClassification,
      classifications.mountainsClassification,
    );
    addTimeClassification(
      GrandTourJerseyClassification.youthClassification,
      classifications.youthClassification,
    );

    return GrandTourJerseyStandingsData(
      edition: edition,
      stageNumber: stageNumber,
      totalStages: totalStages,
      stageName: stageName,
      kmRemaining: kmRemaining,
      holders: result,
    );
  }

  /// Przykładowe dane realistyczne dla podglądu na żywo i podium.
  factory GrandTourJerseyStandingsData.sample({
    GrandTourEdition edition = GrandTourEdition.tourDeFrance,
    GrandTourStripMode mode = GrandTourStripMode.liveRace,
  }) {
    final bool isLive = mode == GrandTourStripMode.liveRace;
    return GrandTourJerseyStandingsData(
      edition: edition,
      stageNumber: 17,
      totalStages: 21,
      stageName: 'Saint-Gervais → Courchevel (Col de la Loze)',
      kmRemaining: isLive ? 14.8 : null,
      holders: [
        GrandTourJerseyHolder(
          classification: GrandTourJerseyClassification.generalClassification,
          riderId: 'r_gc_1',
          riderName: 'T. Pogačar',
          teamName: 'UAE Team Emirates',
          teamCode: 'UAD',
          nationalityCode: 'SLO',
          teamColor: AppColors.goldAccent,
          totalTimeSeconds: 243195,
          timeAdvantageSeconds: isLive ? 48 : 34,
          stageDeltaText: isLive ? '-0:14 na drodze' : '+10s bonifikaty',
          isPlayerTeam: true,
          isVirtualLeaderChange: false,
          runnerUpName: 'J. Vingegaard',
          runnerUpGapText: isLive ? '+0:48' : '+0:34',
        ),
        GrandTourJerseyHolder(
          classification: GrandTourJerseyClassification.pointsClassification,
          riderId: 'r_pts_1',
          riderName: 'B. Girmay',
          teamName: 'Intermarché-Wanty',
          teamCode: 'IWA',
          nationalityCode: 'ERI',
          teamColor: AppColors.emeraldGreen,
          points: 346,
          pointsAdvantage: 52,
          stageDeltaText: isLive ? '+20 pkt lotna' : '+30 pkt etap',
          runnerUpName: 'J. Philipsen',
          runnerUpGapText: '-52 pkt',
        ),
        GrandTourJerseyHolder(
          classification: GrandTourJerseyClassification.mountainsClassification,
          riderId: 'r_kom_1',
          riderName: 'R. Carapaz',
          teamName: 'EF Education-EasyPost',
          teamCode: 'EFE',
          nationalityCode: 'ECU',
          teamColor: AppColors.crimsonAlert,
          points: 118,
          pointsAdvantage: isLive ? 11 : 4,
          stageDeltaText: isLive ? '+20 pkt HC' : '+25 pkt góra',
          isVirtualLeaderChange: isLive,
          previousLeaderName: isLive ? 'J. Vingegaard' : null,
          runnerUpName: 'J. Vingegaard',
          runnerUpGapText: isLive ? '-11 pkt' : '-4 pkt',
        ),
        GrandTourJerseyHolder(
          classification: GrandTourJerseyClassification.youthClassification,
          riderId: 'r_u25_1',
          riderName: 'R. Evenepoel',
          teamName: 'Soudal Quick-Step',
          teamCode: 'SOQ',
          nationalityCode: 'BEL',
          teamColor: AppColors.accentBlue,
          totalTimeSeconds: 243492,
          timeAdvantageSeconds: 185,
          stageDeltaText: isLive ? '+0:00 w grupie' : 'Utrzymana koszulka',
          runnerUpName: 'C. Rodríguez',
          runnerUpGapText: '+3:05',
        ),
      ],
    );
  }

  static String _buildTeamCode(String teamName) {
    final String cleaned = teamName.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (cleaned.length >= 3) {
      return cleaned.substring(0, 3).toUpperCase();
    }
    return cleaned.toUpperCase().padRight(3, 'X');
  }

  static String _formatGapSeconds(int seconds) {
    if (seconds <= 0) return '+0:00';
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return '+$mins:${secs.toString().padLeft(2, '0')}';
  }
}

/// Pasek 4 koszulek klasyfikacji Grand Touru (na żywo w wyścigu oraz na podium).
class GrandTourJerseyStandingsPodiumStrip extends StatefulWidget {
  final GrandTourJerseyStandingsData data;
  final GrandTourStripMode mode;
  final GrandTourJerseyClassification? selectedClassification;
  final ValueChanged<GrandTourJerseyHolder>? onJerseySelected;
  final VoidCallback? onOpenFullStandings;
  final ValueChanged<GrandTourStripMode>? onModeChanged;
  final bool showModeToggle;
  final bool isEnabled;

  const GrandTourJerseyStandingsPodiumStrip({
    super.key,
    required this.data,
    required this.mode,
    this.selectedClassification,
    this.onJerseySelected,
    this.onOpenFullStandings,
    this.onModeChanged,
    this.showModeToggle = false,
    this.isEnabled = true,
  });

  @override
  State<GrandTourJerseyStandingsPodiumStrip> createState() =>
      _GrandTourJerseyStandingsPodiumStripState();
}

class _GrandTourJerseyStandingsPodiumStripState
    extends State<GrandTourJerseyStandingsPodiumStrip> {
  GrandTourJerseyClassification? _internalSelected;

  static const TextStyle _baseInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  GrandTourJerseyClassification? get _activeSelection =>
      widget.selectedClassification ?? _internalSelected;

  void _handleCardTap(GrandTourJerseyHolder holder) {
    if (!widget.isEnabled || !holder.isEnabled) return;
    setState(() {
      if (_internalSelected == holder.classification) {
        _internalSelected = null;
      } else {
        _internalSelected = holder.classification;
      }
    });
    widget.onJerseySelected?.call(holder);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool isMobile = width < 640;
        final bool isTablet = width >= 640 && width < 1120;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.isEnabled ? 1.0 : 0.55,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderColor,
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isMobile: isMobile),
                const SizedBox(height: 12),
                if (widget.data.holders.isEmpty)
                  _buildEmptyState()
                else
                  _buildCardsLayout(
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                if (_activeSelection != null) ...[
                  const SizedBox(height: 12),
                  _buildSelectedDetailBar(isMobile: isMobile),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    final bool isLive = widget.mode == GrandTourStripMode.liveRace;
    final Color modeAccent =
        isLive ? AppColors.cyanAccent : AppColors.goldAccent;
    final String modeBadgeLabel = isLive
        ? 'KLASYFIKACJE NA ŻYWO'
        : 'CEREMONIA PODIUM';

    final Widget titleBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: modeAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: modeAccent.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLive ? Icons.sensors_rounded : Icons.emoji_events_rounded,
                size: 13,
                color: modeAccent,
              ),
              const SizedBox(width: 5),
              Text(
                modeBadgeLabel,
                style: _baseInter.copyWith(
                  color: modeAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            '${widget.data.editionDisplayName} • Etap ${widget.data.stageNumber}/${widget.data.totalStages}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _baseInter.copyWith(
              color: AppColors.textPrimary,
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );

    final Widget telemetryTrail = Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isLive && widget.data.kmRemaining != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: Text(
              'Do mety ${widget.data.kmRemaining!.toStringAsFixed(1)} km',
              style: _baseInter.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        if (widget.showModeToggle && widget.onModeChanged != null)
          _StripModeSegmentedControl(
            mode: widget.mode,
            isEnabled: widget.isEnabled,
            onChanged: widget.onModeChanged!,
          ),
        if (widget.onOpenFullStandings != null)
          _StripActionButton(
            label: isMobile ? 'Tabela' : 'Pełna klasyfikacja',
            icon: Icons.leaderboard_rounded,
            isEnabled: widget.isEnabled,
            onPressed: widget.onOpenFullStandings!,
          ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 4),
          Text(
            widget.data.stageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _baseInter.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          telemetryTrail,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 3),
              Text(
                widget.data.stageName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        telemetryTrail,
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.checkroom_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Brak aktywnych klasyfikacji koszulek dla tego etapu.',
              style: _baseInter.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsLayout({
    required bool isMobile,
    required bool isTablet,
  }) {
    final List<GrandTourJerseyHolder> items =
        widget.data.holders.take(4).toList(growable: false);

    if (isMobile) {
      // Siatka 2x2 na wąskich ekranach (390x844) — zero przepełnień RenderFlex.
      final List<Widget> rows = [];
      for (int i = 0; i < items.length; i += 2) {
        final GrandTourJerseyHolder first = items[i];
        final GrandTourJerseyHolder? second =
            i + 1 < items.length ? items[i + 1] : null;
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCardItem(first, isCompact: true)),
              const SizedBox(width: 8),
              Expanded(
                child: second != null
                    ? _buildCardItem(second, isCompact: true)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
        if (i + 2 < items.length) {
          rows.add(const SizedBox(height: 8));
        }
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      );
    }

    // Tablet (1024x768) i Desktop (1600x900): 4 równoległe karty w jednym pasku.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: _buildCardItem(
              items[i],
              isCompact: isTablet,
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildCardItem(
    GrandTourJerseyHolder holder, {
    required bool isCompact,
  }) {
    final GrandTourJerseyVisualSpec spec = GrandTourJerseyVisualSpec.resolve(
      widget.data.edition,
      holder.classification,
    );
    final bool isSelected = _activeSelection == holder.classification;

    return _JerseyStandingCard(
      holder: holder,
      spec: spec,
      mode: widget.mode,
      isSelected: isSelected,
      isCompact: isCompact,
      stripEnabled: widget.isEnabled,
      onTap: () => _handleCardTap(holder),
    );
  }

  Widget _buildSelectedDetailBar({required bool isMobile}) {
    final GrandTourJerseyHolder? selectedHolder = widget.data.holders
        .cast<GrandTourJerseyHolder?>()
        .firstWhere(
          (h) => h?.classification == _activeSelection,
          orElse: () => null,
        );
    if (selectedHolder == null) return const SizedBox.shrink();

    final GrandTourJerseyVisualSpec spec = GrandTourJerseyVisualSpec.resolve(
      widget.data.edition,
      selectedHolder.classification,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: Container(
        key: ValueKey<GrandTourJerseyClassification>(selectedHolder.classification),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: spec.primaryColor.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: spec.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${spec.jerseyName} (${spec.metricLabel})',
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (selectedHolder.runnerUpName != null)
              Text(
                '2. miejsce: ${selectedHolder.runnerUpName} (${selectedHolder.runnerUpGapText ?? ""})',
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            if (selectedHolder.isVirtualLeaderChange &&
                selectedHolder.previousLeaderName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amberWarning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.amberWarning.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'Zmiana wirtualna (poprzednio: ${selectedHolder.previousLeaderName})',
                  style: _baseInter.copyWith(
                    color: AppColors.amberWarning,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JerseyStandingCard extends StatefulWidget {
  final GrandTourJerseyHolder holder;
  final GrandTourJerseyVisualSpec spec;
  final GrandTourStripMode mode;
  final bool isSelected;
  final bool isCompact;
  final bool stripEnabled;
  final VoidCallback onTap;

  const _JerseyStandingCard({
    required this.holder,
    required this.spec,
    required this.mode,
    required this.isSelected,
    required this.isCompact,
    required this.stripEnabled,
    required this.onTap,
  });

  @override
  State<_JerseyStandingCard> createState() => _JerseyStandingCardState();
}

class _JerseyStandingCardState extends State<_JerseyStandingCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  static const TextStyle _baseInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  bool get _interactive => widget.stripEnabled && widget.holder.isEnabled;

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.spec.primaryColor;
    final bool isLive = widget.mode == GrandTourStripMode.liveRace;

    final Color bgColor;
    if (!_interactive) {
      bgColor = AppColors.background.withValues(alpha: 0.6);
    } else if (_isPressed) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.95);
    } else if (widget.isSelected || _isHovered) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.background;
    }

    final Color borderColor;
    final double borderWidth;
    if (!_interactive) {
      borderColor = AppColors.cardBorder.withValues(alpha: 0.5);
      borderWidth = 1.0;
    } else if (_isFocused) {
      borderColor = AppColors.goldAccent;
      borderWidth = 1.5;
    } else if (widget.isSelected) {
      borderColor = accent;
      borderWidth = 1.5;
    } else if (_isHovered) {
      borderColor = accent.withValues(alpha: 0.65);
      borderWidth = 1.0;
    } else {
      borderColor = AppColors.cardBorder;
      borderWidth = 1.0;
    }

    return FocusableActionDetector(
      enabled: _interactive,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
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
        cursor:
            _interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: _interactive
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: _interactive
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: _interactive
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: _interactive ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: _isPressed
                ? Matrix4.diagonal3Values(0.985, 0.985, 1.0)
                : Matrix4.identity(),
            padding: EdgeInsets.all(widget.isCompact ? 10 : 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Opacity(
              opacity: _interactive ? 1.0 : 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: widget.isCompact ? 28 : 34,
                        height: widget.isCompact ? 28 : 34,
                        child: CustomPaint(
                          painter: GrandTourJerseyIconPainter(spec: widget.spec),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.spec.shortCode,
                                    style: _baseInter.copyWith(
                                      color: accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    widget.spec.jerseyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _baseInter.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: widget.holder.teamColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    widget.holder.riderName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _baseInter.copyWith(
                                      color: widget.holder.isPlayerTeam
                                          ? AppColors.goldAccent
                                          : AppColors.textPrimary,
                                      fontSize: widget.isCompact ? 12 : 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.holder.teamCode} • ${widget.holder.nationalityCode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _baseInter.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isLive && widget.holder.isVirtualLeaderChange) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amberWarning.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NOWY LIDER',
                            style: _baseInter.copyWith(
                              color: AppColors.amberWarning,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ] else if (!isLive && widget.holder.isPlayerTeam) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TWÓJ KOLARZ',
                            style: _baseInter.copyWith(
                              color: AppColors.goldAccent,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          widget.holder.formattedPrimaryMetric(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _baseInter.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: widget.isCompact ? 12 : 14,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.holder.formattedAdvantageOverSecond(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: _baseInter.copyWith(
                            color: AppColors.statusSuccess,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.holder.stageDeltaText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.holder.stageDeltaText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _baseInter.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
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

class _StripModeSegmentedControl extends StatelessWidget {
  final GrandTourStripMode mode;
  final bool isEnabled;
  final ValueChanged<GrandTourStripMode> onChanged;

  const _StripModeSegmentedControl({
    required this.mode,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModePill(
            label: 'Na żywo',
            selected: mode == GrandTourStripMode.liveRace,
            isEnabled: isEnabled,
            onTap: () => onChanged(GrandTourStripMode.liveRace),
          ),
          _ModePill(
            label: 'Podium',
            selected: mode == GrandTourStripMode.podiumCeremony,
            isEnabled: isEnabled,
            onTap: () => onChanged(GrandTourStripMode.podiumCeremony),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatefulWidget {
  final String label;
  final bool selected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ModePill({
    required this.label,
    required this.selected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_ModePill> createState() => _ModePillState();
}

class _ModePillState extends State<_ModePill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
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
        child: GestureDetector(
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent
                  : (_hovered ? AppColors.surfaceLight : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
              border: _focused
                  ? Border.all(color: AppColors.goldAccent, width: 1.0)
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _StripActionButton({
    required this.label,
    required this.icon,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<_StripActionButton> createState() => _StripActionButtonState();
}

class _StripActionButtonState extends State<_StripActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: widget.isEnabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.isEnabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: widget.isEnabled
              ? () => setState(() => _pressed = false)
              : null,
          onTap: widget.isEnabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _pressed
                  ? AppColors.primaryAccent
                  : (_hovered ? AppColors.surfaceLight : AppColors.background),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (_hovered ? AppColors.goldAccent : AppColors.cardBorder),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 13,
                  color: widget.isEnabled
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

/// Wektorowy `CustomPainter` rysujący sylwetkę koszulki kolarskiej Grand Touru.
class GrandTourJerseyIconPainter extends CustomPainter {
  final GrandTourJerseyVisualSpec spec;

  const GrandTourJerseyIconPainter({required this.spec});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path jerseyPath = Path()
      ..moveTo(w * 0.32, h * 0.10)
      ..lineTo(w * 0.08, h * 0.24)
      ..lineTo(w * 0.16, h * 0.45)
      ..lineTo(w * 0.27, h * 0.40)
      ..lineTo(w * 0.27, h * 0.90)
      ..lineTo(w * 0.73, h * 0.90)
      ..lineTo(w * 0.73, h * 0.40)
      ..lineTo(w * 0.84, h * 0.45)
      ..lineTo(w * 0.92, h * 0.24)
      ..lineTo(w * 0.68, h * 0.10)
      ..quadraticBezierTo(w * 0.50, h * 0.20, w * 0.32, h * 0.10)
      ..close();

    final Paint fillPaint = Paint()
      ..color = spec.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(jerseyPath, fillPaint);

    if (spec.hasPolkaDots && spec.polkaDotColor != null) {
      canvas.save();
      canvas.clipPath(jerseyPath);
      final Paint dotPaint = Paint()
        ..color = spec.polkaDotColor!
        ..style = PaintingStyle.fill;
      final double r = math.max(1.6, w * 0.068);
      const List<Offset> dots = [
        Offset(0.36, 0.30),
        Offset(0.62, 0.28),
        Offset(0.49, 0.44),
        Offset(0.34, 0.56),
        Offset(0.64, 0.56),
        Offset(0.49, 0.72),
        Offset(0.36, 0.82),
        Offset(0.63, 0.82),
      ];
      for (final Offset rel in dots) {
        canvas.drawCircle(Offset(w * rel.dx, h * rel.dy), r, dotPaint);
      }
      canvas.restore();
    }

    // Zamek błyskawiczny i lamówka kołnierza
    final Paint trimPaint = Paint()
      ..color = spec.trimColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.04);
    canvas.drawPath(jerseyPath, trimPaint);
    canvas.drawLine(
      Offset(w * 0.50, h * 0.16),
      Offset(w * 0.50, h * 0.42),
      trimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GrandTourJerseyIconPainter oldDelegate) {
    return oldDelegate.spec.classification != spec.classification ||
        oldDelegate.spec.primaryColor != spec.primaryColor ||
        oldDelegate.spec.hasPolkaDots != spec.hasPolkaDots;
  }
}
