import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/simulation/stage_results_calculator.dart';
import '../../models/career/career_save.dart';
import '../../models/race/race_stage.dart';
import '../../models/rider/rider.dart';
import '../../services/analysis/post_race_ai_tactical_coach_analyzer.dart';

/// Zakładka szczegółowa w karcie Asystenta Taktycznego AI.
enum AiCoachCardDetailTab {
  insights,
  windSegments,
  attackTimings,
}

/// Kontener danych wejściowych dla karty [PostRaceAiCoachInsightsCard].
class PostRaceAiCoachInsightsData {
  final String stageName;
  final List<PostRaceTacticalCoachReport> reports;
  final bool isFromLiveTelemetry;

  const PostRaceAiCoachInsightsData({
    required this.stageName,
    required this.reports,
    this.isFromLiveTelemetry = true,
  });

  /// Tworzy dane karty z gotowych raportów [PostRaceTacticalCoachReport].
  factory PostRaceAiCoachInsightsData.fromReports({
    required String stageName,
    required List<PostRaceTacticalCoachReport> reports,
    bool isFromLiveTelemetry = true,
  }) {
    return PostRaceAiCoachInsightsData(
      stageName: stageName,
      reports: reports,
      isFromLiveTelemetry: isFromLiveTelemetry,
    );
  }

  /// Syntetyzuje raporty taktyczne AI na podstawie oficjalnego podsumowania etapu
  /// [StageSummaryReport] (np. po szybkiej symulacji lub gdy brak pełnej telemetrii 1 Hz).
  factory PostRaceAiCoachInsightsData.fromStageReport({
    required StageSummaryReport report,
    required String playerTeamId,
    CareerSave? save,
    PostRaceAiTacticalCoachAnalyzer analyzer =
        const PostRaceAiTacticalCoachAnalyzer(),
  }) {
    final List<OfficialRiderStageResult> teamResults = report.results
        .where((r) => r.teamId == playerTeamId && !r.isDnf)
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    if (teamResults.isEmpty) {
      return PostRaceAiCoachInsightsData(
        stageName: report.stageName,
        reports: const [],
        isFromLiveTelemetry: false,
      );
    }

    final Map<String, Rider> ridersById = <String, Rider>{
      if (save != null)
        for (final Rider r in save.riders) r.id: r,
    };

    final List<PostRaceCoachAnalysisInput> inputs = <PostRaceCoachAnalysisInput>[];
    final int limit = math.min(6, teamResults.length);

    for (int i = 0; i < limit; i++) {
      final OfficialRiderStageResult res = teamResults[i];
      final Rider? rider = ridersById[res.riderId];
      final int ftp = rider?.physiology.ftpWatts ?? (385 - i * 8);
      final double wPrime =
          (rider?.physiology.wPrimeJoules ?? 22000).toDouble();
      final double weight = rider?.physiology.weightKg ?? 68.0;
      final TacticalCoachRiderRole role = _inferRole(
        stageType: report.stageType,
        rider: rider,
        teamIndex: i,
      );

      final List<PostRaceTelemetrySample> samples = _synthesizeSamplesForResult(
        result: res,
        stageType: report.stageType,
        ftpWatts: ftp,
        maxWPrimeJoules: wPrime,
        isCombative: report.mostCombativeRiderId == res.riderId,
      );

      inputs.add(
        PostRaceCoachAnalysisInput(
          riderId: res.riderId,
          riderName: res.riderName,
          role: role,
          ftpWatts: ftp,
          maxWPrimeJoules: wPrime,
          weightKg: weight,
          stageName: report.stageName,
          totalStageDistanceKm: 165.0,
          finishPosition: res.rank,
          samples: samples,
        ),
      );
    }

    final List<PostRaceTacticalCoachReport> generated =
        analyzer.analyzeTeam(inputs);

    return PostRaceAiCoachInsightsData(
      stageName: report.stageName,
      reports: generated,
      isFromLiveTelemetry: false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stageName': stageName,
        'isFromLiveTelemetry': isFromLiveTelemetry,
        'reports': reports.map((r) => r.toJson()).toList(),
      };

  factory PostRaceAiCoachInsightsData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawReports =
        json['reports'] as List<dynamic>? ?? const <dynamic>[];
    return PostRaceAiCoachInsightsData(
      stageName: json['stageName'] as String? ?? 'Etap',
      isFromLiveTelemetry: json['isFromLiveTelemetry'] as bool? ?? true,
      reports: rawReports
          .whereType<Map<String, dynamic>>()
          .map(PostRaceTacticalCoachReport.fromJson)
          .toList(),
    );
  }

  static TacticalCoachRiderRole _inferRole({
    required StageType stageType,
    required Rider? rider,
    required int teamIndex,
  }) {
    if (rider != null) {
      switch (rider.specialization) {
        case RiderSpecialization.pureSprinter:
        case RiderSpecialization.versatileSprinter:
          return TacticalCoachRiderRole.sprinter;
        case RiderSpecialization.gcClimber:
          return TacticalCoachRiderRole.gcLeader;
        case RiderSpecialization.pureClimber:
          return TacticalCoachRiderRole.climber;
        case RiderSpecialization.puncher:
        case RiderSpecialization.classicCobbles:
          return TacticalCoachRiderRole.puncheur;
        case RiderSpecialization.breakawaySpecialist:
          return TacticalCoachRiderRole.breakawaySpecialist;
        case RiderSpecialization.timeTrialist:
        case RiderSpecialization.domestiqueEngine:
          return teamIndex == 0
              ? TacticalCoachRiderRole.gcLeader
              : TacticalCoachRiderRole.domestique;
      }
    }
    if (teamIndex == 0) {
      return stageType == StageType.flat
          ? TacticalCoachRiderRole.sprinter
          : TacticalCoachRiderRole.gcLeader;
    }
    return TacticalCoachRiderRole.domestique;
  }

  static List<PostRaceTelemetrySample> _synthesizeSamplesForResult({
    required OfficialRiderStageResult result,
    required StageType stageType,
    required int ftpWatts,
    required double maxWPrimeJoules,
    required bool isCombative,
  }) {
    final int seed = result.riderId.hashCode.abs();
    final bool goodResult = result.rank <= 10;
    final bool exposedToWind =
        !goodResult && (result.gapToWinnerSeconds > 90.0 || seed % 3 == 0);
    final bool isMountain = stageType == StageType.highMountain ||
        stageType == StageType.summitFinish ||
        stageType == StageType.hilly;

    final List<PostRaceTelemetrySample> samples = <PostRaceTelemetrySample>[];
    const int sampleCount = 24;
    const double dtSeconds = 600.0;

    for (int i = 0; i < sampleCount; i++) {
      final double progress = i / (sampleCount - 1);
      final double distanceMeters = progress * 165000.0;
      final bool isWindSector = i >= 6 && i <= 11;
      final bool isFinalClimbOrSprint = i >= 18 && i <= 21;

      final bool drafting = !(exposedToWind && isWindSector);
      final double draftSavings = drafting ? (goodResult ? 36.0 : 28.0) : 4.0;
      final bool inGutter = !drafting && (seed % 2 == 0);
      final bool attacking =
          (isFinalClimbOrSprint && (goodResult || isCombative)) ||
              (isCombative && i == 10);

      final double wPrimeRatio = attacking
          ? (goodResult ? 0.42 : 0.08)
          : (0.78 - (progress * 0.15)).clamp(0.25, 1.0);

      final int powerWatts = attacking
          ? (ftpWatts * (goodResult ? 1.32 : 1.44)).round()
          : (drafting ? (ftpWatts * 0.72).round() : (ftpWatts * 1.06).round());

      samples.add(
        PostRaceTelemetrySample(
          timestampSeconds: i * dtSeconds,
          distanceMeters: distanceMeters,
          speedMs: isMountain && i >= 16 ? 6.8 : 11.8,
          powerWatts: powerWatts,
          heartRateBpm: attacking ? 184 : (drafting ? 144 : 168),
          gradientPercent: isMountain && i >= 16 ? 7.8 : 0.8,
          wPrimeJoules: maxWPrimeJoules * wPrimeRatio,
          wPrimeRatio: wPrimeRatio,
          isDrafting: drafting,
          draftingSavingsPercent: draftSavings,
          windSpeedKmh: isWindSector ? 32.0 : 12.0,
          windAngleDegrees: isWindSector ? 75.0 : 25.0,
          isEchelonZone: isWindSector && stageType == StageType.flat,
          isInGutter: inGutter,
          isAttacking: attacking,
          isPlannedPull: false,
          groupIndex: result.gapToWinnerSeconds > 60 ? 2 : 1,
        ),
      );
    }

    return samples;
  }
}

/// Karta raportu Asystenta Taktycznego AI na ekranie podsumowania etapu.
class PostRaceAiCoachInsightsCard extends StatefulWidget {
  final PostRaceAiCoachInsightsData data;
  final bool isDisabled;
  final ValueChanged<PostRaceTacticalCoachReport>? onRiderSelected;
  final ValueChanged<TacticalCoachingInsight>? onApplyNextStageAction;
  final VoidCallback? onOpenFullAnalysis;

  const PostRaceAiCoachInsightsCard({
    super.key,
    required this.data,
    this.isDisabled = false,
    this.onRiderSelected,
    this.onApplyNextStageAction,
    this.onOpenFullAnalysis,
  });

  @override
  State<PostRaceAiCoachInsightsCard> createState() =>
      _PostRaceAiCoachInsightsCardState();
}

class _PostRaceAiCoachInsightsCardState
    extends State<PostRaceAiCoachInsightsCard>
    with SingleTickerProviderStateMixin {
  int _selectedRiderIndex = 0;
  TacticalInsightCategory? _selectedCategory;
  AiCoachCardDetailTab _detailTab = AiCoachCardDetailTab.insights;
  final Set<String> _appliedInsightIds = <String>{};
  String? _expandedInsightId;

  late final AnimationController _entryController;
  late final Animation<double> _entryProgress;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _entryProgress = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();
  }

  @override
  void didUpdateWidget(covariant PostRaceAiCoachInsightsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.reports.length != widget.data.reports.length) {
      if (widget.data.reports.isEmpty) {
        _selectedRiderIndex = 0;
      } else {
        _selectedRiderIndex =
            _selectedRiderIndex.clamp(0, widget.data.reports.length - 1);
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  PostRaceTacticalCoachReport? get _activeReport {
    final List<PostRaceTacticalCoachReport> reports = widget.data.reports;
    if (reports.isEmpty) return null;
    final int safeIndex = _selectedRiderIndex.clamp(0, reports.length - 1);
    return reports[safeIndex];
  }

  @override
  Widget build(BuildContext context) {
    final PostRaceTacticalCoachReport? report = _activeReport;

    return IgnorePointer(
      ignoring: widget.isDisabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        opacity: widget.isDisabled ? 0.52 : 1.0,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final bool isCompact = width < 520;
            final bool isWide = width >= 920;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor, width: 1),
              ),
              padding: EdgeInsets.all(isCompact ? 14 : 20),
              child: report == null
                  ? _buildEmptyState(isCompact)
                  : FadeTransition(
                      opacity: _entryProgress,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildHeader(report, isCompact),
                          const SizedBox(height: 14),
                          _buildRiderSelectorStrip(),
                          const SizedBox(height: 14),
                          _buildExecutiveVerdictBanner(report, isCompact),
                          const SizedBox(height: 14),
                          _buildKpiGrid(report, isCompact, isWide),
                          const SizedBox(height: 16),
                          _buildDetailTabsBar(report, isCompact),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeOutCubic,
                            child: _buildActiveDetailContent(
                              report: report,
                              isCompact: isCompact,
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 24,
        vertical: isCompact ? 22 : 28,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.psychology_alt_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'Brak raportów Asystenta Taktycznego AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Po ukończeniu etapu z aktywną telemetrią kolarzy drużyny pojawi się tutaj szczegółowa ocena strat na wietrze oraz timingu ataków W\'.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PostRaceTacticalCoachReport report, bool isCompact) {
    final Color gradeColor = _gradeColor(report.grade);
    final String sourceBadge = widget.data.isFromLiveTelemetry
        ? 'TELEMETRIA 1 HZ'
        : 'SYNTETYCZNY AUDYT';

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.65),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      const Text(
                        'ASYSTENT TAKTYCZNY AI',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.goldAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          sourceBadge,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.accentBlue,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.data.stageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildAnimatedScoreBadge(report, gradeColor),
            if (widget.onOpenFullAnalysis != null) ...<Widget>[
              const SizedBox(width: 10),
              _AiCoachActionButton(
                label: isCompact ? 'Szczegóły' : 'Pełna Analiza',
                icon: Icons.open_in_new_rounded,
                isDisabled: widget.isDisabled,
                onTap: widget.onOpenFullAnalysis,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedScoreBadge(
    PostRaceTacticalCoachReport report,
    Color gradeColor,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: report.overallTacticalScore.clamp(0.0, 100.0),
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedScore, Widget? child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: gradeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: gradeColor.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _gradeLabel(report.grade),
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: gradeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${animatedScore.toStringAsFixed(0)} / 100',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      fontFeatures: <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const Text(
                    'Ocena AI',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiderSelectorStrip() {
    final List<PostRaceTacticalCoachReport> reports = widget.data.reports;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(reports.length, (int index) {
          final PostRaceTacticalCoachReport r = reports[index];
          final bool isSelected = index == _selectedRiderIndex;
          final Color gradeColor = _gradeColor(r.grade);
          return Padding(
            padding: EdgeInsets.only(right: index < reports.length - 1 ? 8 : 0),
            child: _AiCoachInteractiveChip(
              label: r.riderName,
              badgeText: _gradeLabel(r.grade),
              badgeColor: gradeColor,
              subtitle: _roleLabel(r.role),
              isSelected: isSelected,
              isDisabled: widget.isDisabled,
              onTap: () {
                setState(() {
                  _selectedRiderIndex = index;
                  _expandedInsightId = null;
                });
                widget.onRiderSelected?.call(r);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildExecutiveVerdictBanner(
    PostRaceTacticalCoachReport report,
    bool isCompact,
  ) {
    final Color accent = _gradeColor(report.grade);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.record_voice_over_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              report.executiveVerdict.isNotEmpty
                  ? report.executiveVerdict
                  : 'Analiza etapu zakończona — sprawdź szczegóły poniżej.',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    PostRaceTacticalCoachReport report,
    bool isCompact,
    bool isWide,
  ) {
    final WindAeroEfficiencySummary wind = report.windSummary;
    final WPrimeAttackTimingSummary atk = report.attackSummary;

    final List<_KpiTileSpec> tiles = <_KpiTileSpec>[
      _KpiTileSpec(
        title: 'Strata na wietrze',
        value: '${wind.totalWastedEnergyKj.toStringAsFixed(1)} kJ',
        subtitle:
            '${wind.averageWastedWattsWhenExposed.toStringAsFixed(0)} W śr. • ${wind.equivalentFtpMinutesWasted.toStringAsFixed(1)} min FTP',
        icon: Icons.air_rounded,
        accentColor: wind.totalWastedEnergyKj > 95
            ? AppColors.crimsonAlert
            : (wind.totalWastedEnergyKj > 45
                ? AppColors.amberWarning
                : AppColors.statusSuccess),
      ),
      _KpiTileSpec(
        title: 'Osłona w peletonie',
        value: '${wind.shelteredPercentOfStage.toStringAsFixed(0)}%',
        subtitle: wind.gutterExposureCount > 0
            ? '${wind.gutterExposureCount}x ekspozycja w rancie'
            : 'Stabilna jazda w drafcie',
        icon: Icons.shield_rounded,
        accentColor: wind.shelteredPercentOfStage >= 75
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
      ),
      _KpiTileSpec(
        title: 'Timing ataków W\'',
        value: atk.totalAttacks == 0
            ? 'Brak'
            : '${atk.averageTimingScore.toStringAsFixed(0)}/100',
        subtitle: atk.totalAttacks == 0
            ? 'Jazda defensywna w grupie'
            : '${atk.optimalAttacks}/${atk.totalAttacks} opt. • ${atk.blowupCount} odcięć',
        icon: Icons.bolt_rounded,
        accentColor: atk.blowupCount > 0
            ? AppColors.crimsonAlert
            : AppColors.cyanAccent,
      ),
      _KpiTileSpec(
        title: 'Wnioski AI',
        value: '${report.insights.length}',
        subtitle: _insightSeveritySummary(report.insights),
        icon: Icons.tips_and_updates_rounded,
        accentColor: AppColors.goldAccent,
      ),
    ];

    final int columns = isWide ? 4 : (isCompact ? 1 : 2);
    const double spacing = 10;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double itemWidth =
            (box.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles.map((_KpiTileSpec spec) {
            return SizedBox(
              width: itemWidth,
              child: _AiCoachKpiCard(spec: spec),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDetailTabsBar(
    PostRaceTacticalCoachReport report,
    bool isCompact,
  ) {
    final List<({AiCoachCardDetailTab tab, String label, int count})> tabs =
        <({AiCoachCardDetailTab tab, String label, int count})>[
      (
        tab: AiCoachCardDetailTab.insights,
        label: isCompact ? 'Wskazówki' : 'Wskazówki AI',
        count: report.insights.length,
      ),
      (
        tab: AiCoachCardDetailTab.windSegments,
        label: isCompact ? 'Wiatr' : 'Odcinki Wiatru',
        count: report.windSummary.topMistakeSegments.length,
      ),
      (
        tab: AiCoachCardDetailTab.attackTimings,
        label: isCompact ? 'Ataki W\'' : 'Ocena Ataków W\'',
        count: report.attackSummary.attacks.length,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((item) {
          final bool active = _detailTab == item.tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _AiCoachInteractiveChip(
              label: item.label,
              badgeText: '${item.count}',
              badgeColor:
                  active ? AppColors.goldAccent : AppColors.textSecondary,
              isSelected: active,
              isDisabled: widget.isDisabled,
              onTap: () => setState(() => _detailTab = item.tab),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveDetailContent({
    required PostRaceTacticalCoachReport report,
    required bool isCompact,
  }) {
    switch (_detailTab) {
      case AiCoachCardDetailTab.insights:
        return _buildInsightsTabContent(report, isCompact);
      case AiCoachCardDetailTab.windSegments:
        return _buildWindSegmentsContent(report, isCompact);
      case AiCoachCardDetailTab.attackTimings:
        return _buildAttackTimingsContent(report, isCompact);
    }
  }

  Widget _buildInsightsTabContent(
    PostRaceTacticalCoachReport report,
    bool isCompact,
  ) {
    final List<TacticalCoachingInsight> filtered = _selectedCategory == null
        ? report.insights
        : report.insights
            .where((i) => i.category == _selectedCategory)
            .toList();

    return Column(
      key: ValueKey<String>('insights_${report.riderId}_$_selectedCategory'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _AiCoachInteractiveChip(
                label: 'Wszystkie',
                badgeText: '${report.insights.length}',
                badgeColor: AppColors.accentBlue,
                isSelected: _selectedCategory == null,
                isDisabled: widget.isDisabled,
                onTap: () => setState(() => _selectedCategory = null),
              ),
              const SizedBox(width: 8),
              ...TacticalInsightCategory.values.map((cat) {
                final int count =
                    report.insights.where((i) => i.category == cat).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _AiCoachInteractiveChip(
                    label: _categoryLabel(cat),
                    badgeText: '$count',
                    badgeColor: _categoryColor(cat),
                    isSelected: _selectedCategory == cat,
                    isDisabled: widget.isDisabled,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _buildSectionEmptyBox('Brak wskazówek w wybranej kategorii.')
        else
          ...filtered.map((TacticalCoachingInsight insight) {
            final bool isApplied = _appliedInsightIds.contains(insight.id);
            final bool isExpanded = _expandedInsightId == insight.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AiCoachInsightTile(
                insight: insight,
                isCompact: isCompact,
                isExpanded: isExpanded,
                isApplied: isApplied,
                isDisabled: widget.isDisabled,
                onToggleExpand: () {
                  setState(() {
                    _expandedInsightId = isExpanded ? null : insight.id;
                  });
                },
                onApplyAction: () {
                  setState(() {
                    if (isApplied) {
                      _appliedInsightIds.remove(insight.id);
                    } else {
                      _appliedInsightIds.add(insight.id);
                    }
                  });
                  widget.onApplyNextStageAction?.call(insight);
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildWindSegmentsContent(
    PostRaceTacticalCoachReport report,
    bool isCompact,
  ) {
    final List<WindExposureSegment> segments =
        report.windSummary.topMistakeSegments;

    if (segments.isEmpty) {
      return _buildSectionEmptyBox(
        'Brak wykrytych odcinków kosztownej ekspozycji na wiatr.',
      );
    }

    return Column(
      key: ValueKey<String>('wind_${report.riderId}'),
      children: segments.map((WindExposureSegment seg) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(isCompact ? 12 : 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seg.occurredInGutter
                  ? AppColors.crimsonAlert.withValues(alpha: 0.45)
                  : AppColors.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'km ${seg.startKm.toStringAsFixed(1)} – ${seg.endKm.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      fontFeatures: <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      _buildTagPill(
                        '-${seg.wastedEnergyKj.toStringAsFixed(1)} kJ',
                        AppColors.crimsonAlert,
                      ),
                      _buildTagPill(
                        '${seg.averageWastedWatts.toStringAsFixed(0)} W śr.',
                        AppColors.amberWarning,
                      ),
                      if (seg.occurredInGutter)
                        _buildTagPill('RANT', AppColors.crimsonAlert),
                      if (seg.occurredInEchelon)
                        _buildTagPill('WACHLARZ', AppColors.accentBlue),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                seg.diagnosis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttackTimingsContent(
    PostRaceTacticalCoachReport report,
    bool isCompact,
  ) {
    final List<AttackTimingEvaluation> attacks = report.attackSummary.attacks;

    if (attacks.isEmpty) {
      return _buildSectionEmptyBox(
        'Kolarz nie zainicjował samodzielnych ataków z zasobów beztlenowych W\'.',
      );
    }

    return Column(
      key: ValueKey<String>('attacks_${report.riderId}'),
      children: attacks.map((AttackTimingEvaluation atk) {
        final Color verdictColor = _attackVerdictColor(atk.verdict);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(isCompact ? 12 : 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: verdictColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _buildTagPill(
                    'Atak #${atk.attackIndex}',
                    AppColors.goldAccent,
                  ),
                  _buildTagPill(
                    _attackVerdictLabel(atk.verdict),
                    verdictColor,
                  ),
                  Text(
                    'km ${atk.startKm.toStringAsFixed(1)} (${atk.distanceToFinishKm.toStringAsFixed(1)} km do mety)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: <Widget>[
                  _buildMetricInline('Szczyt', '${atk.peakWatts} W'),
                  _buildMetricInline('Średnia', '${atk.averageWatts} W'),
                  _buildMetricInline(
                    'W\' start',
                    '${(atk.preAttackWPrimeRatio * 100).toStringAsFixed(0)}%',
                  ),
                  _buildMetricInline(
                    'Ocena',
                    '${atk.timingScore.toStringAsFixed(0)}/100',
                  ),
                ],
              ),
              if (atk.coachingNote.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  atk.coachingNote,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionEmptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textSecondary,
          fontSize: 12.5,
        ),
      ),
    );
  }

  Widget _buildTagPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildMetricInline(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static Color _gradeColor(TacticalCoachGrade grade) {
    switch (grade) {
      case TacticalCoachGrade.s:
        return AppColors.goldAccent;
      case TacticalCoachGrade.a:
        return AppColors.statusSuccess;
      case TacticalCoachGrade.b:
        return AppColors.accentBlue;
      case TacticalCoachGrade.c:
        return AppColors.amberWarning;
      case TacticalCoachGrade.d:
      case TacticalCoachGrade.f:
        return AppColors.crimsonAlert;
    }
  }

  static String _gradeLabel(TacticalCoachGrade grade) {
    return grade.name.toUpperCase();
  }

  static String _roleLabel(TacticalCoachRiderRole role) {
    switch (role) {
      case TacticalCoachRiderRole.gcLeader:
        return 'Lider GC';
      case TacticalCoachRiderRole.sprinter:
        return 'Sprinter';
      case TacticalCoachRiderRole.puncheur:
        return 'Puncheur';
      case TacticalCoachRiderRole.climber:
        return 'Góral';
      case TacticalCoachRiderRole.domestique:
        return 'Pomocnik';
      case TacticalCoachRiderRole.breakawaySpecialist:
        return 'Uciekinier';
    }
  }

  static String _categoryLabel(TacticalInsightCategory category) {
    switch (category) {
      case TacticalInsightCategory.windProtection:
        return 'Wiatr & Aero';
      case TacticalInsightCategory.wPrimeTiming:
        return 'Ataki W\'';
      case TacticalInsightCategory.echelonPositioning:
        return 'Ranty';
      case TacticalInsightCategory.pacingDiscipline:
        return 'Tempo';
    }
  }

  static Color _categoryColor(TacticalInsightCategory category) {
    switch (category) {
      case TacticalInsightCategory.windProtection:
        return AppColors.accentBlue;
      case TacticalInsightCategory.wPrimeTiming:
        return AppColors.cyanAccent;
      case TacticalInsightCategory.echelonPositioning:
        return AppColors.amberWarning;
      case TacticalInsightCategory.pacingDiscipline:
        return AppColors.statusSuccess;
    }
  }

  static Color _attackVerdictColor(AttackTimingVerdict verdict) {
    switch (verdict) {
      case AttackTimingVerdict.optimal:
        return AppColors.goldAccent;
      case AttackTimingVerdict.wellTimed:
        return AppColors.statusSuccess;
      case AttackTimingVerdict.risky:
        return AppColors.amberWarning;
      case AttackTimingVerdict.poorlyTimedHeadwind:
      case AttackTimingVerdict.emptyTankBlowup:
        return AppColors.crimsonAlert;
    }
  }

  static String _attackVerdictLabel(AttackTimingVerdict verdict) {
    switch (verdict) {
      case AttackTimingVerdict.optimal:
        return 'OPTYMALNY';
      case AttackTimingVerdict.wellTimed:
        return 'DOBRY TIMING';
      case AttackTimingVerdict.risky:
        return 'RYZYKOWNY';
      case AttackTimingVerdict.poorlyTimedHeadwind:
        return 'POD WIATR';
      case AttackTimingVerdict.emptyTankBlowup:
        return 'ODCIĘCIE W\'';
    }
  }

  static String _insightSeveritySummary(List<TacticalCoachingInsight> list) {
    final int critical = list
        .where((i) => i.severity == TacticalInsightSeverity.critical)
        .length;
    final int warning =
        list.where((i) => i.severity == TacticalInsightSeverity.warning).length;
    if (critical > 0) return '$critical kryt. • $warning ostrz.';
    if (warning > 0) return '$warning ostrz. taktyczne';
    return 'Czysty przejazd';
  }
}

class _KpiTileSpec {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _KpiTileSpec({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}

class _AiCoachKpiCard extends StatelessWidget {
  final _KpiTileSpec spec;

  const _AiCoachKpiCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(spec.icon, size: 15, color: spec.accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  spec.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            spec.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              color: spec.accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.3,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCoachInteractiveChip extends StatefulWidget {
  final String label;
  final String badgeText;
  final Color badgeColor;
  final String? subtitle;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _AiCoachInteractiveChip({
    required this.label,
    required this.badgeText,
    required this.badgeColor,
    this.subtitle,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_AiCoachInteractiveChip> createState() =>
      _AiCoachInteractiveChipState();
}

class _AiCoachInteractiveChipState extends State<_AiCoachInteractiveChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    final Color background = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.25)
        : (_pressed || _hovered
            ? AppColors.surfaceLight.withValues(alpha: 0.95)
            : AppColors.surfaceLight);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
      onShowFocusHighlight: (bool value) => setState(() => _focused = value),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: widget.isSelected ? 1.4 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  widget.badgeText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: widget.badgeColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: widget.isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiCoachActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isDisabled;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _AiCoachActionButton({
    required this.label,
    required this.icon,
    required this.isDisabled,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  State<_AiCoachActionButton> createState() => _AiCoachActionButtonState();
}

class _AiCoachActionButtonState extends State<_AiCoachActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isHighlighted;
    final Color bg = active
        ? AppColors.statusSuccess.withValues(alpha: 0.2)
        : (_pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.45)
            : (_hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.3)
                : AppColors.surfaceLight));
    final Color border = active
        ? AppColors.statusSuccess
        : (_focused
            ? AppColors.goldAccent
            : (_hovered ? AppColors.primaryAccent : AppColors.cardBorder));
    final Color fg =
        active ? AppColors.statusSuccess : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.isDisabled && widget.onTap != null,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(widget.icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: fg,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiCoachInsightTile extends StatefulWidget {
  final TacticalCoachingInsight insight;
  final bool isCompact;
  final bool isExpanded;
  final bool isApplied;
  final bool isDisabled;
  final VoidCallback onToggleExpand;
  final VoidCallback onApplyAction;

  const _AiCoachInsightTile({
    required this.insight,
    required this.isCompact,
    required this.isExpanded,
    required this.isApplied,
    required this.isDisabled,
    required this.onToggleExpand,
    required this.onApplyAction,
  });

  @override
  State<_AiCoachInsightTile> createState() => _AiCoachInsightTileState();
}

class _AiCoachInsightTileState extends State<_AiCoachInsightTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color sevColor = _severityColor(widget.insight.severity);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.isDisabled ? null : widget.onToggleExpand,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(widget.isCompact ? 12 : 14),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.96)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.isExpanded
                      ? sevColor.withValues(alpha: 0.6)
                      : AppColors.cardBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    _severityIcon(widget.insight.severity),
                    color: sevColor,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: sevColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                _severityLabel(widget.insight.severity),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: sevColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (widget.insight.impactMetricLabel.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(5),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  widget.insight.impactMetricLabel,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.textPrimary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.insight.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    widget.isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.insight.description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.42,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topLeft,
                child: widget.isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color:
                                  AppColors.goldAccent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'PLAN NA KOLEJNY ETAP',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.goldAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.insight.nextStageAction,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _AiCoachActionButton(
                                label: widget.isApplied
                                    ? 'Zastosowano w planie'
                                    : 'Zastosuj wskazówkę',
                                icon: widget.isApplied
                                    ? Icons.check_circle_rounded
                                    : Icons.playlist_add_check_rounded,
                                isDisabled: widget.isDisabled,
                                isHighlighted: widget.isApplied,
                                onTap: widget.onApplyAction,
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _severityColor(TacticalInsightSeverity severity) {
    switch (severity) {
      case TacticalInsightSeverity.critical:
        return AppColors.crimsonAlert;
      case TacticalInsightSeverity.warning:
        return AppColors.amberWarning;
      case TacticalInsightSeverity.positive:
        return AppColors.statusSuccess;
      case TacticalInsightSeverity.tip:
        return AppColors.accentBlue;
    }
  }

  static IconData _severityIcon(TacticalInsightSeverity severity) {
    switch (severity) {
      case TacticalInsightSeverity.critical:
        return Icons.error_outline_rounded;
      case TacticalInsightSeverity.warning:
        return Icons.warning_amber_rounded;
      case TacticalInsightSeverity.positive:
        return Icons.verified_rounded;
      case TacticalInsightSeverity.tip:
        return Icons.lightbulb_outline_rounded;
    }
  }

  static String _severityLabel(TacticalInsightSeverity severity) {
    switch (severity) {
      case TacticalInsightSeverity.critical:
        return 'KRYTYCZNE';
      case TacticalInsightSeverity.warning:
        return 'OSTRZEŻENIE';
      case TacticalInsightSeverity.positive:
        return 'SUKCES';
      case TacticalInsightSeverity.tip:
        return 'WSKAZÓWKA';
    }
  }
}
