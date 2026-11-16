import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/career_save.dart';
import '../../models/race/tour_race.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/season_awards_velo_dor_ceremony.dart';
import '../../state/career_state_notifier.dart';

/// Podsumowanie osiągnięć pojedynczego kolarza drużyny gracza w sezonie.
class VeloDorTeamRiderSummary {
  final String riderName;
  final String roleLabel;
  final int seasonWins;
  final int uciPoints;
  final int overallRating;

  const VeloDorTeamRiderSummary({
    required this.riderName,
    required this.roleLabel,
    required this.seasonWins,
    required this.uciPoints,
    required this.overallRating,
  });
}

/// Podsumowanie osiągnięć drużyny gracza prezentowane podczas Gali Vélo d'Or.
class VeloDorPlayerSeasonSummary {
  final String teamName;
  final String divisionLabel;
  final int seasonYear;
  final int totalWins;
  final int grandTourWins;
  final int monumentWins;
  final int uciPointsTotal;
  final int uciTeamRank;
  final int sponsorObjectivesCompleted;
  final int sponsorObjectivesTotal;
  final int prizeMoneyEarnedEur;
  final int awardsWonCount;
  final int prestigeGain;
  final int moraleBoost;
  final List<VeloDorTeamRiderSummary> topRiders;

  const VeloDorPlayerSeasonSummary({
    required this.teamName,
    required this.divisionLabel,
    required this.seasonYear,
    required this.totalWins,
    required this.grandTourWins,
    required this.monumentWins,
    required this.uciPointsTotal,
    required this.uciTeamRank,
    required this.sponsorObjectivesCompleted,
    required this.sponsorObjectivesTotal,
    required this.prizeMoneyEarnedEur,
    required this.awardsWonCount,
    required this.prestigeGain,
    required this.moraleBoost,
    this.topRiders = const [],
  });

  double get sponsorCompletionRatio {
    if (sponsorObjectivesTotal <= 0) return 0.0;
    return (sponsorObjectivesCompleted / sponsorObjectivesTotal).clamp(0.0, 1.0);
  }

  /// Buduje podsumowanie drużyny gracza bezpośrednio z aktywnego zapisu [CareerSave].
  factory VeloDorPlayerSeasonSummary.fromCareerSave(
    CareerSave save,
    VeloDorCeremonyReport report,
  ) {
    final playerTeam = save.teams.cast<CyclingTeam?>().firstWhere(
          (t) => t?.id == save.playerTeamId,
          orElse: () => save.teams.isNotEmpty ? save.teams.first : null,
        );

    final teamId = playerTeam?.id ?? save.playerTeamId;
    int totalWins = 0;
    int gtWins = 0;
    int monumentWins = 0;
    int prizePool = 0;
    final riderWins = <String, int>{};

    for (final entry in save.calendar.raceHistory.values) {
      if (entry.winnerTeamId == teamId) {
        totalWins++;
        riderWins[entry.winnerRiderId] =
            (riderWins[entry.winnerRiderId] ?? 0) + 1;
        final race = save.calendar.getRaceById(entry.raceId);
        if (race != null) {
          prizePool += race.prizePoolEur ~/ 2;
          if (race.uciCategory == RaceCategory.grandTour) {
            gtWins++;
          } else if (race.uciCategory == RaceCategory.monument) {
            monumentWins++;
          }
        }
      }
    }

    final sortedTeams = [...save.teams]
      ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));
    final rankIndex = sortedTeams.indexWhere((t) => t.id == teamId);
    final teamRank = rankIndex >= 0 ? rankIndex + 1 : 1;

    final allObjectives =
        playerTeam?.sponsors.expand((s) => s.objectives).toList() ?? const [];
    final completedObjectives =
        allObjectives.where((o) => o.isCompleted).length;

    final rosterIds = playerTeam?.rosterRiderIds.toSet() ?? const <String>{};
    final teamRiders = save.riders
        .where((r) => rosterIds.contains(r.id))
        .toList()
      ..sort((a, b) => b.careerPointsUci.compareTo(a.careerPointsUci));

    final topRiders = teamRiders.take(4).map((r) {
      return VeloDorTeamRiderSummary(
        riderName: r.fullName,
        roleLabel: r.specialization.displayName,
        seasonWins: riderWins[r.id] ?? 0,
        uciPoints: r.careerPointsUci,
        overallRating: r.overallRating,
      );
    }).toList();

    return VeloDorPlayerSeasonSummary(
      teamName: playerTeam?.name ?? 'Drużyna Gracza',
      divisionLabel: playerTeam?.division.label ?? 'WorldTour',
      seasonYear: save.currentSeasonYear,
      totalWins: totalWins,
      grandTourWins: gtWins,
      monumentWins: monumentWins,
      uciPointsTotal: playerTeam?.uciPointsSeason ?? 0,
      uciTeamRank: teamRank,
      sponsorObjectivesCompleted: completedObjectives,
      sponsorObjectivesTotal: allObjectives.length,
      prizeMoneyEarnedEur: prizePool,
      awardsWonCount: report.playerTeamAwardsWon,
      prestigeGain: report.playerTeamPrestigeGain,
      moraleBoost: report.playerTeamMoraleBoost,
      topRiders: topRiders,
    );
  }

  /// Buduje podsumowanie demonstracyjne spójne z raportem gali Vélo d'Or.
  factory VeloDorPlayerSeasonSummary.fromReportDemo(
    VeloDorCeremonyReport report,
  ) {
    final playerWinners = report.orderedCategories
        .map((c) => c.winner)
        .whereType<VeloDorNomineeResult>()
        .where((w) => w.isPlayerTeam)
        .toList();

    final teamName = playerWinners.isNotEmpty
        ? playerWinners.first.teamName
        : 'Orzeł WorldTour Team';

    return VeloDorPlayerSeasonSummary(
      teamName: teamName,
      divisionLabel: 'UCI WorldTour',
      seasonYear: report.seasonYear,
      totalWins: 28,
      grandTourWins: 1,
      monumentWins: 1,
      uciPointsTotal: 11840,
      uciTeamRank: 3,
      sponsorObjectivesCompleted: 4,
      sponsorObjectivesTotal: 5,
      prizeMoneyEarnedEur: 1480000,
      awardsWonCount: report.playerTeamAwardsWon,
      prestigeGain: report.playerTeamPrestigeGain,
      moraleBoost: report.playerTeamMoraleBoost,
      topRiders: const [
        VeloDorTeamRiderSummary(
          riderName: 'Michał Kowalski',
          roleLabel: 'Lider GC',
          seasonWins: 11,
          uciPoints: 4920,
          overallRating: 91,
        ),
        VeloDorTeamRiderSummary(
          riderName: 'Kacper Nowak',
          roleLabel: 'Klasykowiec',
          seasonWins: 7,
          uciPoints: 3180,
          overallRating: 87,
        ),
        VeloDorTeamRiderSummary(
          riderName: 'Jan Zieliński',
          roleLabel: 'Talent U23',
          seasonWins: 5,
          uciPoints: 1940,
          overallRating: 83,
        ),
      ],
    );
  }
}

/// Uroczysty ekran gali kończącej sezon Vélo d'Or w kolorystyce czerni `#0F1115`
/// i złota `#D4AF37`, prezentujący zwycięzców plebiscytu, ich statystyki z całego
/// roku oraz podsumowanie osiągnięć drużyny gracza.
class VeloDorGalaCeremonyScreen extends ConsumerStatefulWidget {
  final VeloDorCeremonyReport? report;
  final VeloDorPlayerSeasonSummary? playerSummary;
  final VoidCallback? onProceedToOffseason;

  const VeloDorGalaCeremonyScreen({
    super.key,
    this.report,
    this.playerSummary,
    this.onProceedToOffseason,
  });

  @override
  ConsumerState<VeloDorGalaCeremonyScreen> createState() =>
      _VeloDorGalaCeremonyScreenState();
}

class _VeloDorGalaCeremonyScreenState
    extends ConsumerState<VeloDorGalaCeremonyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _galaAtmosphereController;
  VeloDorAwardCategory _selectedCategory = VeloDorAwardCategory.worldBestRider;
  int _selectedFinalistRank = 1;
  final Set<VeloDorAwardCategory> _presentedCategories =
      <VeloDorAwardCategory>{};
  bool _ceremonyConcluded = false;

  @override
  void initState() {
    super.initState();
    _galaAtmosphereController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _galaAtmosphereController.dispose();
    super.dispose();
  }

  VeloDorCeremonyReport _resolveReport(CareerSave? activeSave) {
    if (widget.report != null) {
      return widget.report!;
    }
    if (activeSave != null && activeSave.riders.isNotEmpty) {
      return const SeasonAwardsVeloDorCeremony()
          .conductCeremonyFromCareerSave(activeSave);
    }
    return SeasonAwardsVeloDorCeremony.generateSampleCeremonyReport();
  }

  VeloDorPlayerSeasonSummary _resolvePlayerSummary(
    CareerSave? activeSave,
    VeloDorCeremonyReport report,
  ) {
    if (widget.playerSummary != null) {
      return widget.playerSummary!;
    }
    if (activeSave != null && activeSave.teams.isNotEmpty) {
      return VeloDorPlayerSeasonSummary.fromCareerSave(activeSave, report);
    }
    return VeloDorPlayerSeasonSummary.fromReportDemo(report);
  }

  void _presentStatuette(VeloDorAwardCategory category) {
    setState(() {
      _presentedCategories.add(category);
    });
  }

  void _presentAllStatuettes(VeloDorCeremonyReport report) {
    setState(() {
      for (final cat in report.orderedCategories) {
        _presentedCategories.add(cat.category);
      }
      _ceremonyConcluded = true;
    });
  }

  void _handleFinishGala(VeloDorCeremonyReport report) {
    if (!_ceremonyConcluded) {
      _presentAllStatuettes(report);
    }
    if (widget.onProceedToOffseason != null) {
      widget.onProceedToOffseason!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSave = widget.report == null
        ? ref.watch(careerStateNotifierProvider).rawSave
        : null;
    final report = _resolveReport(activeSave);
    final playerSummary = _resolvePlayerSummary(activeSave, report);
    final activeCategoryResult = report.resultFor(_selectedCategory);
    final orderedCategories = report.orderedCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _galaAtmosphereController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _VeloDorGalaBackdropPainter(
                    progress: _galaAtmosphereController.value,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isCompact = width < 680;
                final isDesktopWide = width >= 1120;
                final horizontalPadding = isCompact ? 14.0 : 24.0;

                return Column(
                  children: [
                    _buildTopHeader(
                      context,
                      report: report,
                      isCompact: isCompact,
                      horizontalPadding: horizontalPadding,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1480),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCategoryNavigationBar(
                                  orderedCategories,
                                  isCompact: isCompact,
                                ),
                                const SizedBox(height: 18),
                                if (isDesktopWide)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 7,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _buildMainStageCard(
                                              report,
                                              activeCategoryResult,
                                              isCompact: false,
                                            ),
                                            const SizedBox(height: 18),
                                            _buildYearStatsAndFinalistsCard(
                                              activeCategoryResult,
                                              isCompact: false,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _buildPlayerTeamSummaryCard(
                                              playerSummary,
                                              isCompact: false,
                                            ),
                                            const SizedBox(height: 18),
                                            _buildHonorRollCard(
                                              orderedCategories,
                                              isCompact: false,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildMainStageCard(
                                        report,
                                        activeCategoryResult,
                                        isCompact: isCompact,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildYearStatsAndFinalistsCard(
                                        activeCategoryResult,
                                        isCompact: isCompact,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildPlayerTeamSummaryCard(
                                        playerSummary,
                                        isCompact: isCompact,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildHonorRollCard(
                                        orderedCategories,
                                        isCompact: isCompact,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildBottomCeremonyBar(
                      report: report,
                      orderedCategories: orderedCategories,
                      isCompact: isCompact,
                      horizontalPadding: horizontalPadding,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context, {
    required VeloDorCeremonyReport report,
    required bool isCompact,
    required double horizontalPadding,
  }) {
    final canPop =
        widget.onProceedToOffseason != null || Navigator.of(context).canPop();
    final formattedDate =
        '${report.ceremonyDate.day.toString().padLeft(2, '0')}.'
        '${report.ceremonyDate.month.toString().padLeft(2, '0')}.'
        '${report.ceremonyDate.year}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canPop) ...[
                _GalaActionButton(
                  icon: Icons.arrow_back_rounded,
                  label: isCompact ? 'Powrót' : 'Powrót do Kariery',
                  isPrimary: false,
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      widget.onProceedToOffseason?.call();
                    }
                  },
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.55),
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "GALA VÉLO D'OR • SEZON ${report.seasonYear}",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 15 : 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    Text(
                      '${report.venue} • $formattedDate',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _GalaBadgePill(
                icon: Icons.verified_rounded,
                label: report.isOfficialLateOctoberWindow
                    ? 'Oficjalne Okno Październikowe'
                    : 'Gala Specjalna',
                color: AppColors.goldAccent,
              ),
              _GalaBadgePill(
                icon: Icons.military_tech_rounded,
                label:
                    '${_presentedCategories.length}/${report.orderedCategories.length} Statuetek',
                color: _presentedCategories.length ==
                        report.orderedCategories.length
                    ? AppColors.statusSuccess
                    : AppColors.accentBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNavigationBar(
    List<VeloDorCategoryResult> orderedCategories, {
    required bool isCompact,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: orderedCategories.map((result) {
          final category = result.category;
          final isSelected = category == _selectedCategory;
          final isPresented = _presentedCategories.contains(category);
          final isPlayerWinner = result.winner?.isPlayerTeam ?? false;

          return _GalaCategoryTab(
            label: category.shortLabel,
            isSelected: isSelected,
            isPresented: isPresented,
            isPlayerWinner: isPlayerWinner,
            compact: isCompact,
            onTap: () {
              setState(() {
                _selectedCategory = category;
                _selectedFinalistRank = 1;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainStageCard(
    VeloDorCeremonyReport report,
    VeloDorCategoryResult? categoryResult, {
    required bool isCompact,
  }) {
    final winner = categoryResult?.winner;
    if (categoryResult == null || winner == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 1),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: AppColors.textSecondary,
              size: 40,
            ),
            SizedBox(height: 10),
            Text(
              'Brak nominowanych w tej kategorii plebiscytu.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final isPresented = _presentedCategories.contains(categoryResult.category);
    final statuetteSpec = winner.statuetteSpec;

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            const Color(0xFF1A160D),
            AppColors.surfaceLight.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPresented
              ? AppColors.goldAccent.withValues(alpha: 0.85)
              : AppColors.goldAccent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryResult.category.frenchSubtitle.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoryResult.category.displayName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              _GalaBadgePill(
                icon: isPresented
                    ? Icons.auto_awesome_rounded
                    : Icons.hourglass_top_rounded,
                label: isPresented ? 'STATUETKA WRĘCZONA' : 'OCZEKUJE NA WRĘCZENIE',
                color:
                    isPresented ? AppColors.statusSuccess : AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _buildStatuetteStage(
                    categoryResult.category,
                    isPresented,
                    height: 170,
                  ),
                ),
                const SizedBox(height: 16),
                _buildWinnerSpotlightInfo(
                  categoryResult,
                  winner,
                  statuetteSpec,
                  isPresented,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: _buildStatuetteStage(
                    categoryResult.category,
                    isPresented,
                    height: 205,
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: _buildWinnerSpotlightInfo(
                    categoryResult,
                    winner,
                    statuetteSpec,
                    isPresented,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatuetteStage(
    VeloDorAwardCategory category,
    bool isPresented, {
    required double height,
  }) {
    return AnimatedBuilder(
      animation: _galaAtmosphereController,
      builder: (context, _) {
        return Container(
          height: height,
          width: 170,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPresented
                  ? AppColors.goldAccent.withValues(alpha: 0.75)
                  : AppTheme.borderColor,
              width: 1,
            ),
            boxShadow: isPresented
                ? [
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.18),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: CustomPaint(
            painter: VeloDorStatuettePainter(
              category: category,
              shimmerProgress: _galaAtmosphereController.value,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWinnerSpotlightInfo(
    VeloDorCategoryResult categoryResult,
    VeloDorNomineeResult winner,
    VeloDorStatuetteSpec? spec,
    bool isPresented,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _GalaBadgePill(
              icon: Icons.public_rounded,
              label: winner.nationalityIso,
              color: AppColors.goldAccent,
            ),
            if (winner.isPlayerTeam)
              const _GalaBadgePill(
                icon: Icons.star_rounded,
                label: 'DRUŻYNA GRACZA',
                color: AppColors.statusSuccess,
              ),
            _GalaBadgePill(
              icon: Icons.how_to_vote_rounded,
              label:
                  '${winner.voteBreakdown.voteSharePercent.toStringAsFixed(1)}% GŁOSÓW JURY',
              color: AppColors.accentBlue,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          winner.candidateName,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${winner.teamName} • ${winner.roleOrSpecialty}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.goldAccent,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          categoryResult.ceremonyCitation,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        if (spec != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Grawer: ${spec.engravingLine}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _GalaActionButton(
          icon: isPresented
              ? Icons.check_circle_rounded
              : Icons.emoji_events_rounded,
          label: isPresented
              ? 'Statuetka Wręczona (+${categoryResult.category.prestigeReward} Prestiżu)'
              : 'Wręcz Statuetkę ${categoryResult.category.shortLabel}',
          isPrimary: true,
          enabled: !isPresented,
          onPressed: isPresented
              ? null
              : () => _presentStatuette(categoryResult.category),
        ),
      ],
    );
  }

  Widget _buildYearStatsAndFinalistsCard(
    VeloDorCategoryResult? categoryResult, {
    required bool isCompact,
  }) {
    if (categoryResult == null || categoryResult.podiumFinalists.isEmpty) {
      return const SizedBox.shrink();
    }

    final finalists = categoryResult.podiumFinalists;
    final inspected = finalists.firstWhere(
      (f) => f.rank == _selectedFinalistRank,
      orElse: () => finalists.first,
    );
    final breakdown = inspected.voteBreakdown;
    final maxComponent = [
      breakdown.sportingResultsScore,
      breakdown.prestigeMultiplierScore,
      breakdown.journalistPanelVotes,
      breakdown.peerDirectorsVotes,
      1.0,
    ].reduce(math.max);

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'STATYSTYKI Z CAŁEGO ROKU & GŁOSY JURY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.goldAccent,
                ),
              ),
              Text(
                'Oceniono ${categoryResult.totalCandidatesEvaluated} kandydatów',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: finalists.map((finalist) {
              final isSelected = finalist.rank == inspected.rank;
              return _GalaFinalistChip(
                rank: finalist.rank,
                name: finalist.candidateName,
                votePercent: finalist.voteBreakdown.voteSharePercent,
                isPlayerTeam: finalist.isPlayerTeam,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedFinalistRank = finalist.rank;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: inspected.isWinner
                    ? AppColors.goldAccent.withValues(alpha: 0.5)
                    : AppTheme.borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${inspected.rank}. ${inspected.candidateName} (${inspected.teamName})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${breakdown.totalScore.toStringAsFixed(0)} pkt',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ScoreBreakdownBar(
                  label: 'Wyniki Sportowe Sezonu',
                  value: breakdown.sportingResultsScore,
                  maxValue: maxComponent,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(height: 8),
                _ScoreBreakdownBar(
                  label: 'Prestiż & Koszulki Mistrzowskie',
                  value: breakdown.prestigeMultiplierScore,
                  maxValue: maxComponent,
                  color: AppColors.primaryAccent,
                ),
                const SizedBox(height: 8),
                _ScoreBreakdownBar(
                  label: 'Panel Dziennikarzy Międzynarodowych',
                  value: breakdown.journalistPanelVotes,
                  maxValue: maxComponent,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(height: 8),
                _ScoreBreakdownBar(
                  label: 'Głosy Dyrektorów Sportowych',
                  value: breakdown.peerDirectorsVotes,
                  maxValue: maxComponent,
                  color: AppColors.statusSuccess,
                ),
                if (inspected.seasonHighlights.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Kluczowe osiągnięcia roku:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: inspected.seasonHighlights
                        .map(
                          (highlight) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.goldAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              highlight,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTeamSummaryCard(
    VeloDorPlayerSeasonSummary summary, {
    required bool isCompact,
  }) {
    final sponsorPercent = (summary.sponsorCompletionRatio * 100).round();

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PODSUMOWANIE DRUŻYNY GRACZA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    Text(
                      '${summary.teamName} • ${summary.divisionLabel}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, box) {
              final tileWidth = (box.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _TeamMetricTile(
                    width: tileWidth,
                    label: 'Zwycięstwa w Sezonie',
                    value: '${summary.totalWins}',
                    accent: AppColors.goldAccent,
                  ),
                  _TeamMetricTile(
                    width: tileWidth,
                    label: 'Ranking UCI Drużyn',
                    value: '#${summary.uciTeamRank} (${summary.uciPointsTotal} pkt)',
                    accent: AppColors.accentBlue,
                  ),
                  _TeamMetricTile(
                    width: tileWidth,
                    label: 'Grand Tour / Monumenty',
                    value: '${summary.grandTourWins} GT • ${summary.monumentWins} Mon.',
                    accent: AppColors.primaryAccent,
                  ),
                  _TeamMetricTile(
                    width: tileWidth,
                    label: 'Nagrody Finansowe',
                    value: Formatters.formatCurrency(summary.prizeMoneyEarnedEur),
                    accent: AppColors.statusSuccess,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Realizacja Celów Sponsora',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${summary.sponsorObjectivesCompleted}/${summary.sponsorObjectivesTotal} ($sponsorPercent%)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: summary.sponsorCompletionRatio,
                    minHeight: 7,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.goldAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GalaBadgePill(
                icon: Icons.emoji_events_rounded,
                label: "${summary.awardsWonCount}× Statuetka Vélo d'Or",
                color: AppColors.goldAccent,
              ),
              _GalaBadgePill(
                icon: Icons.trending_up_rounded,
                label: '+${summary.prestigeGain} Prestiżu',
                color: AppColors.accentBlue,
              ),
              _GalaBadgePill(
                icon: Icons.mood_rounded,
                label: '+${summary.moraleBoost} Morale Zespołu',
                color: AppColors.statusSuccess,
              ),
            ],
          ),
          if (summary.topRiders.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Liderzy Drużyny w Sezonie:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...summary.topRiders.map(
              (rider) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider.riderName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${rider.roleLabel} • OVR ${rider.overallRating}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${rider.seasonWins} zw. • ${rider.uciPoints} pkt',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHonorRollCard(
    List<VeloDorCategoryResult> orderedCategories, {
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "PEŁNA LISTA LAUREATÓW VÉLO D'OR",
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 12),
          ...orderedCategories.map((result) {
            final winner = result.winner;
            final isActive = result.category == _selectedCategory;
            final isPresented = _presentedCategories.contains(result.category);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HonorRollRow(
                categoryTitle: result.category.shortLabel,
                winnerName: winner?.candidateName ?? 'Brak danych',
                teamName: winner?.teamName ?? '-',
                isPlayerTeam: winner?.isPlayerTeam ?? false,
                isActive: isActive,
                isPresented: isPresented,
                onTap: () {
                  setState(() {
                    _selectedCategory = result.category;
                    _selectedFinalistRank = 1;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomCeremonyBar({
    required VeloDorCeremonyReport report,
    required List<VeloDorCategoryResult> orderedCategories,
    required bool isCompact,
    required double horizontalPadding,
  }) {
    final allPresented =
        _presentedCategories.length >= orderedCategories.length;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            allPresented
                ? 'Wszystkie statuetki zostały wręczone. Gratulacje za sezon ${report.seasonYear}!'
                : 'Wręczono ${_presentedCategories.length} z ${orderedCategories.length} statuetek gali.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _GalaActionButton(
                icon: Icons.auto_awesome_rounded,
                label: 'Wręcz Wszystkie',
                isPrimary: false,
                enabled: !allPresented,
                onPressed:
                    allPresented ? null : () => _presentAllStatuettes(report),
              ),
              _GalaActionButton(
                icon: Icons.celebration_rounded,
                label: isCompact
                    ? 'Zakończ Galę'
                    : 'Zakończ Galę i Przejdź Dalej',
                isPrimary: true,
                onPressed: () => _handleFinishGala(report),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VeloDorGalaBackdropPainter extends CustomPainter {
  final double progress;

  const _VeloDorGalaBackdropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, basePaint);

    final sway = math.sin(progress * math.pi * 2) * 0.08;
    final leftBeam = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.14),
          AppColors.goldAccent.withValues(alpha: 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final leftPath = Path()
      ..moveTo(size.width * (0.18 + sway), 0)
      ..lineTo(size.width * (0.34 + sway), 0)
      ..lineTo(size.width * 0.62, size.height * 0.85)
      ..lineTo(size.width * 0.08, size.height * 0.85)
      ..close();
    canvas.drawPath(leftPath, leftBeam);

    final rightBeam = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.12),
          AppColors.primaryAccent.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final rightPath = Path()
      ..moveTo(size.width * (0.66 - sway), 0)
      ..lineTo(size.width * (0.82 - sway), 0)
      ..lineTo(size.width * 0.92, size.height * 0.85)
      ..lineTo(size.width * 0.38, size.height * 0.85)
      ..close();
    canvas.drawPath(rightPath, rightBeam);

    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 20; i++) {
      final seedX = ((i * 73) % 100) / 100.0;
      final seedY = ((i * 41 + (progress * 25).round()) % 100) / 100.0;
      particlePaint.color = AppColors.goldAccent.withValues(
        alpha: 0.08 + ((i % 4) * 0.04),
      );
      canvas.drawCircle(
        Offset(size.width * seedX, size.height * seedY),
        1.5 + (i % 3) * 0.8,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VeloDorGalaBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GalaActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback? onPressed;

  const _GalaActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    this.enabled = true,
    this.onPressed,
  });

  @override
  State<_GalaActionButton> createState() => _GalaActionButtonState();
}

class _GalaActionButtonState extends State<_GalaActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.enabled && widget.onPressed != null;

    Color backgroundColor;
    Color borderColor;
    Color foregroundColor;

    if (!isInteractive) {
      backgroundColor = AppColors.surfaceLight.withValues(alpha: 0.55);
      borderColor = AppTheme.borderColor;
      foregroundColor = AppColors.textSecondary;
    } else if (widget.isPrimary) {
      backgroundColor = _pressed
          ? const Color(0xFFB38E22)
          : _hovered
              ? const Color(0xFFE5C452)
              : AppColors.goldAccent;
      borderColor = _focused ? AppColors.textPrimary : AppColors.goldAccent;
      foregroundColor = AppColors.background;
    } else {
      backgroundColor = _pressed
          ? AppColors.surfaceLight
          : _hovered
              ? AppColors.surfaceLight.withValues(alpha: 0.9)
              : AppColors.surface;
      borderColor = _focused
          ? AppColors.goldAccent
          : _hovered
              ? AppColors.goldAccent.withValues(alpha: 0.7)
              : AppTheme.borderColor;
      foregroundColor = AppColors.textPrimary;
    }

    return FocusableActionDetector(
      enabled: isInteractive,
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      mouseCursor:
          isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isInteractive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isInteractive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            isInteractive ? () => setState(() => _pressed = false) : null,
        onTap: isInteractive ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 17, color: foregroundColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
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

class _GalaCategoryTab extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isPresented;
  final bool isPlayerWinner;
  final bool compact;
  final VoidCallback onTap;

  const _GalaCategoryTab({
    required this.label,
    required this.isSelected,
    required this.isPresented,
    required this.isPlayerWinner,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_GalaCategoryTab> createState() => _GalaCategoryTabState();
}

class _GalaCategoryTabState extends State<_GalaCategoryTab> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.goldAccent.withValues(alpha: 0.20)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final borderColor = _focused
        ? AppColors.textPrimary
        : widget.isSelected
            ? AppColors.goldAccent
            : _hovered
                ? AppColors.goldAccent.withValues(alpha: 0.5)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isPresented
                    ? Icons.check_circle_rounded
                    : Icons.emoji_events_rounded,
                size: 15,
                color: widget.isPresented
                    ? AppColors.statusSuccess
                    : widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
                ),
              ),
              if (widget.isPlayerWinner) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.goldAccent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GalaFinalistChip extends StatefulWidget {
  final int rank;
  final String name;
  final double votePercent;
  final bool isPlayerTeam;
  final bool isSelected;
  final VoidCallback onTap;

  const _GalaFinalistChip({
    required this.rank,
    required this.name,
    required this.votePercent,
    required this.isPlayerTeam,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GalaFinalistChip> createState() => _GalaFinalistChipState();
}

class _GalaFinalistChipState extends State<_GalaFinalistChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.goldAccent.withValues(alpha: 0.18)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.textPrimary
                  : widget.isSelected
                      ? AppColors.goldAccent
                      : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${widget.rank}. ${widget.name}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.votePercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
              if (widget.isPlayerTeam) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: AppColors.statusSuccess,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HonorRollRow extends StatefulWidget {
  final String categoryTitle;
  final String winnerName;
  final String teamName;
  final bool isPlayerTeam;
  final bool isActive;
  final bool isPresented;
  final VoidCallback onTap;

  const _HonorRollRow({
    required this.categoryTitle,
    required this.winnerName,
    required this.teamName,
    required this.isPlayerTeam,
    required this.isActive,
    required this.isPresented,
    required this.onTap,
  });

  @override
  State<_HonorRollRow> createState() => _HonorRollRowState();
}

class _HonorRollRowState extends State<_HonorRollRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.goldAccent.withValues(alpha: 0.14)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.textPrimary
                  : widget.isActive
                      ? AppColors.goldAccent
                      : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.isPresented
                    ? Icons.check_circle_rounded
                    : Icons.emoji_events_outlined,
                size: 18,
                color: widget.isPresented
                    ? AppColors.statusSuccess
                    : AppColors.goldAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.categoryTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    Text(
                      widget.winnerName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.teamName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isPlayerTeam)
                const _GalaBadgePill(
                  icon: Icons.star_rounded,
                  label: 'GRACZ',
                  color: AppColors.statusSuccess,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBreakdownBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const _ScoreBreakdownBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: ratio),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: animatedValue,
                minHeight: 6,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TeamMetricTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Color accent;

  const _TeamMetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalaBadgePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GalaBadgePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
