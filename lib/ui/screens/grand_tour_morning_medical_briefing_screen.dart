// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/medical/grand_tour_nightly_hrv_and_physio_model.dart';
import '../../services/medical/grand_tour_physiotherapy_triage_service.dart';

/// Filtr widoku kart biometrycznych na ekranie porannego raportu medycznego.
enum MorningBriefingFilterMode {
  all,
  alertsOnly,
  leadersOnly;

  String get labelPl {
    switch (this) {
      case MorningBriefingFilterMode.all:
        return 'Wszyscy (8)';
      case MorningBriefingFilterMode.alertsOnly:
        return 'Alerty / Zmęczenie';
      case MorningBriefingFilterMode.leadersOnly:
        return 'Liderzy';
    }
  }
}

/// Tryb sortowania kolarzy w porannym raporcie medycznym Wielkiego Touru.
enum MorningBriefingSortMode {
  readinessAsc,
  hrvDeltaAsc,
  ckDesc,
  rolePriority;

  String get labelPl {
    switch (this) {
      case MorningBriefingSortMode.readinessAsc:
        return 'Gotowość (rosnąco)';
      case MorningBriefingSortMode.hrvDeltaAsc:
        return 'Spadek HRV';
      case MorningBriefingSortMode.ckDesc:
        return 'Kinaza CK (malejąco)';
      case MorningBriefingSortMode.rolePriority:
        return 'Priorytet roli';
    }
  }
}

/// Wynik zatwierdzenia porannego raportu medycznego i przydziału fizjoterapeutów.
class GrandTourMorningBriefingAllocationResult {
  final int stageDay;
  final Map<String, int> physioMinutesByRider;
  final Map<String, PhysiotherapyTreatmentType> treatmentByRider;
  final TransferTransportDecision transportDecision;
  final int totalAllocatedMinutes;
  final int estimatedCostEur;

  const GrandTourMorningBriefingAllocationResult({
    required this.stageDay,
    required this.physioMinutesByRider,
    required this.treatmentByRider,
    required this.transportDecision,
    required this.totalAllocatedMinutes,
    required this.estimatedCostEur,
  });
}

/// Poranny ekran raportu medycznego i przydziału fizjoterapeutów w Wielkim Tourze.
///
/// Prezentuje karty biometryczne 8 kolarzy z 7-dniowym wykresem trendu nocnego HRV
/// (`CustomPainter`), wskaźnikiem gotowości mięśniowej (CK, RHR, Kortyzol/Testosteron, sen)
/// oraz interaktywnymi suwakami przydziału czasu pracy 3 fizjoterapeutów.
class GrandTourMorningMedicalBriefingScreen extends ConsumerStatefulWidget {
  final GrandTourTeamMorningReport? initialReport;
  final Map<String, List<double>>? initialHrvHistoryByRider;
  final Map<String, GrandTourTriageRole>? riderRolesById;
  final int totalPhysioPoolMinutes;
  final int specialistCount;
  final bool isReadOnly;
  final ValueChanged<GrandTourMorningBriefingAllocationResult>? onCommitBriefing;

  const GrandTourMorningMedicalBriefingScreen({
    super.key,
    this.initialReport,
    this.initialHrvHistoryByRider,
    this.riderRolesById,
    this.totalPhysioPoolMinutes = 360,
    this.specialistCount = 3,
    this.isReadOnly = false,
    this.onCommitBriefing,
  });

  @override
  ConsumerState<GrandTourMorningMedicalBriefingScreen> createState() =>
      _GrandTourMorningMedicalBriefingScreenState();
}

class _GrandTourMorningMedicalBriefingScreenState
    extends ConsumerState<GrandTourMorningMedicalBriefingScreen> {
  static const int _maxMinutesPerRider = 90;
  static const int _sliderStepMinutes = 5;

  late GrandTourTeamMorningReport _report;
  late Map<String, List<double>> _hrv7DayByRider;
  late Map<String, double> _baselineHrvByRider;
  late Map<String, GrandTourTriageRole> _rolesByRider;
  late Map<String, int> _allocatedMinutesByRider;
  late Map<String, PhysiotherapyTreatmentType> _treatmentByRider;

  TransferTransportDecision _transportDecision =
      TransferTransportDecision.fourHourTeamBus;
  MorningBriefingFilterMode _filterMode = MorningBriefingFilterMode.all;
  MorningBriefingSortMode _sortMode = MorningBriefingSortMode.readinessAsc;
  String? _selectedRiderId;
  bool _isCommitted = false;

  @override
  void initState() {
    super.initState();
    _initializeBriefingData();
  }

  void _initializeBriefingData() {
    if (widget.initialReport != null) {
      _report = widget.initialReport!;
      _rolesByRider = Map<String, GrandTourTriageRole>.from(
        widget.riderRolesById ?? const {},
      );
      _baselineHrvByRider = {
        for (final s in _report.rosterSamples) s.riderId: s.hrvRmssdMs + 6.0,
      };
      _hrv7DayByRider = {
        for (final s in _report.rosterSamples)
          s.riderId: widget.initialHrvHistoryByRider?[s.riderId] ??
              _synthesizeSevenDayHrvTrend(
                latestHrv: s.hrvRmssdMs,
                baselineHrv: s.hrvRmssdMs + 6.0,
                seed: s.riderId.hashCode,
              ),
      };
    } else {
      final demo = _buildDefaultGrandTourMorningBundle();
      _report = demo.report;
      _hrv7DayByRider = demo.hrvHistoryByRider;
      _baselineHrvByRider = demo.baselineHrvByRider;
      _rolesByRider = widget.riderRolesById != null
          ? Map<String, GrandTourTriageRole>.from(widget.riderRolesById!)
          : demo.rolesByRider;
    }

    _allocatedMinutesByRider = {
      for (final s in _report.rosterSamples) s.riderId: 0,
    };
    _treatmentByRider = {
      for (final s in _report.rosterSamples)
        s.riderId: _defaultTreatmentForSample(s),
    };
    if (_report.rosterSamples.isNotEmpty) {
      _selectedRiderId = _report.rosterSamples.first.riderId;
    }
    _applyAutoAllocation(notifyState: false);
  }

  PhysiotherapyTreatmentType _defaultTreatmentForSample(
    MorningBiomarkerSample sample,
  ) {
    if (sample.creatineKinaseUL >= 950.0) {
      return PhysiotherapyTreatmentType.deepFasciaMassage;
    }
    if (sample.hrvZScore <= -0.8) {
      return PhysiotherapyTreatmentType.wholeBodyCryotherapy;
    }
    if (sample.recommendation ==
        MedicalInterventionRecommendation.aggressiveRecoveryProtocol) {
      return PhysiotherapyTreatmentType.tecarAndUltrasound;
    }
    return PhysiotherapyTreatmentType.deepFasciaMassage;
  }

  List<double> _synthesizeSevenDayHrvTrend({
    required double latestHrv,
    required double baselineHrv,
    required int seed,
  }) {
    final rng = math.Random(seed + 17);
    final points = <double>[];
    for (int i = 0; i < 6; i++) {
      final t = i / 6.0;
      final interpolated =
          baselineHrv * (1.0 - t * 0.6) + latestHrv * (t * 0.6);
      final wave = (rng.nextDouble() - 0.5) * 6.5;
      points.add(double.parse((interpolated + wave).clamp(24.0, 145.0).toStringAsFixed(1)));
    }
    points.add(double.parse(latestHrv.toStringAsFixed(1)));
    return points;
  }

  ({
    GrandTourTeamMorningReport report,
    Map<String, List<double>> hrvHistoryByRider,
    Map<String, double> baselineHrvByRider,
    Map<String, GrandTourTriageRole> rolesByRider,
  }) _buildDefaultGrandTourMorningBundle() {
    const baselines = <RiderBaselineBiomarkers>[
      RiderBaselineBiomarkers(
        riderId: 'r1',
        riderName: 'K. Majka-Nowak',
        baselineHrvRmssdMs: 84.0,
        baselineRhrBpm: 39,
        baselineCkUL: 185.0,
        baselineCortisolNmolL: 410.0,
        baselineTestosteroneNmolL: 21.5,
        baselineSleepEfficiencyPct: 89.0,
      ),
      RiderBaselineBiomarkers(
        riderId: 'r2',
        riderName: 'M. Kowalski',
        baselineHrvRmssdMs: 79.0,
        baselineRhrBpm: 42,
        baselineCkUL: 195.0,
        baselineCortisolNmolL: 430.0,
        baselineTestosteroneNmolL: 20.0,
        baselineSleepEfficiencyPct: 86.0,
      ),
      RiderBaselineBiomarkers(
        riderId: 'r3',
        riderName: 'L. Van Der Berg',
        baselineHrvRmssdMs: 76.0,
        baselineRhrBpm: 41,
        baselineCkUL: 210.0,
        baselineCortisolNmolL: 425.0,
        baselineTestosteroneNmolL: 19.2,
        baselineSleepEfficiencyPct: 84.0,
      ),
      RiderBaselineBiomarkers(
        riderId: 'r4',
        riderName: 'A. Moretti',
        baselineHrvRmssdMs: 81.0,
        baselineRhrBpm: 40,
        baselineCkUL: 175.0,
        baselineCortisolNmolL: 395.0,
        baselineTestosteroneNmolL: 22.0,
        baselineSleepEfficiencyPct: 88.0,
      ),
      RiderBaselineBiomarkers(
        riderId: 'r5',
        riderName: 'P. Zieliński',
        baselineHrvRmssdMs: 74.0,
        baselineRhrBpm: 44,
        baselineCkUL: 190.0,
        baselineCortisolNmolL: 415.0,
        baselineTestosteroneNmolL: 18.8,
        baselineSleepEfficiencyPct: 85.0,
      ),
      RiderBaselineBiomarkers(
        riderId: 'r6',
        riderName: 'J. Lefèvre',
        baselineHrvRmssdMs: 77.0,
        baselineRhrBpm: 43,
        baselineCkUL: 220.0,
        baselineCortisolNmolL: 440.0,
        baselineTestosteroneNmolL: 19.5,
        baselineSleepEfficiencyPct: 83.0,
      ),
      RiderBaselineBiomarkers(
        riderId: 'r7',
        riderName: 'T. Lindqvist',
        baselineHrvRmssdMs: 86.0,
        baselineRhrBpm: 38,
        baselineCkUL: 165.0,
        baselineCortisolNmolL: 380.0,
        baselineTestosteroneNmolL: 23.0,
        baselineSleepEfficiencyPct: 91.0,
      ),
      RiderBaselineBiomarkers(
        riderId: 'r8',
        riderName: 'D. Serrano',
        baselineHrvRmssdMs: 78.0,
        baselineRhrBpm: 41,
        baselineCkUL: 180.0,
        baselineCortisolNmolL: 405.0,
        baselineTestosteroneNmolL: 20.5,
        baselineSleepEfficiencyPct: 87.0,
      ),
    ];

    var model = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
      tourId: 'tdf_2026',
      tourName: 'Tour de France',
      squadBaselines: baselines,
    );

    const roles = <String, GrandTourTriageRole>{
      'r1': GrandTourTriageRole.gcLeader,
      'r2': GrandTourTriageRole.sprinterLeader,
      'r3': GrandTourTriageRole.mountainDomestique,
      'r4': GrandTourTriageRole.mountainDomestique,
      'r5': GrandTourTriageRole.roadCaptain,
      'r6': GrandTourTriageRole.rouleurDomestique,
      'r7': GrandTourTriageRole.rouleurDomestique,
      'r8': GrandTourTriageRole.rouleurDomestique,
    };

    late GrandTourTeamMorningReport latestReport;
    for (int day = 7; day <= 13; day++) {
      final isMountainDay = day == 11 || day == 12;
      final workloads = <String, StageWorkloadInput>{
        for (final b in baselines)
          b.riderId: StageWorkloadInput(
            stageDay: day,
            isRestDay: day == 10,
            stageDistanceKm: day == 10 ? 45.0 : (isMountainDay ? 188.0 : 168.0),
            elevationGainMeters:
                day == 10 ? 320.0 : (isMountainDay ? 4250.0 : 1450.0),
            kilojoulesExpended:
                day == 10 ? 950.0 : (isMountainDay ? 4650.0 : 3350.0),
            intensityFactor: day == 10 ? 0.54 : (isMountainDay ? 0.87 : 0.77),
            crashedOnStage: day == 12 && (b.riderId == 'r2' || b.riderId == 'r6'),
            heatStressIndex: day >= 11 ? 0.62 : 0.35,
            recoveryProtocolApplied: b.riderId == 'r1' || b.riderId == 'r7',
            recoveryProtocolEffectiveness: 0.75,
          ),
      };

      final transfer = BusTransferSleepImpact(
        transferDistanceKm: day == 12 ? 118.0 : 42.0,
        transferDurationMinutes: day == 12 ? 115 : 45,
        hotelArrivalHourDecimal: day == 12 ? 22.1 : 19.6,
        dinnerDelayMinutes: day == 12 ? 45 : 10,
      );

      final result = model.evaluateNightlyRecoveryAndMorningCheck(
        stageDay: day,
        workloadsByRider: workloads,
        transferImpact: transfer,
        isRestDay: day == 10,
        seed: 2026 + day,
      );
      model = result.updatedModel;
      latestReport = result.report;
    }

    final hrvHistory = <String, List<double>>{};
    final baselineMap = <String, double>{};
    for (final b in baselines) {
      baselineMap[b.riderId] = b.baselineHrvRmssdMs;
      final trend = model.getRiderTrend(b.riderId);
      hrvHistory[b.riderId] =
          trend.map((s) => s.hrvRmssdMs).toList(growable: false);
    }

    return (
      report: latestReport,
      hrvHistoryByRider: hrvHistory,
      baselineHrvByRider: baselineMap,
      rolesByRider: roles,
    );
  }

  int get _totalAllocatedMinutes =>
      _allocatedMinutesByRider.values.fold<int>(0, (sum, m) => sum + m);

  int get _remainingPoolMinutes =>
      math.max(0, widget.totalPhysioPoolMinutes - _totalAllocatedMinutes);

  int get _estimatedCostEur {
    int total = _transportDecision ==
            TransferTransportDecision.airCharterForLeaders
        ? 4800
        : 0;
    for (final entry in _allocatedMinutesByRider.entries) {
      if (entry.value <= 0) continue;
      final treatment = _treatmentByRider[entry.key] ??
          PhysiotherapyTreatmentType.deepFasciaMassage;
      total += ((treatment.materialCostEur * entry.value) /
              treatment.defaultDurationMinutes)
          .round();
    }
    return total;
  }

  void _updateRiderPhysioMinutes(String riderId, int requestedMinutes) {
    if (widget.isReadOnly) return;
    final snapped = ((requestedMinutes / _sliderStepMinutes).round() *
            _sliderStepMinutes)
        .clamp(0, _maxMinutesPerRider);
    final currentOtherMinutes = _totalAllocatedMinutes -
        (_allocatedMinutesByRider[riderId] ?? 0);
    final maxAllowedForRider = math.min(
      _maxMinutesPerRider,
      math.max(0, widget.totalPhysioPoolMinutes - currentOtherMinutes),
    );
    final clamped = snapped.clamp(0, maxAllowedForRider);

    setState(() {
      _allocatedMinutesByRider[riderId] = clamped;
      _selectedRiderId = riderId;
      _isCommitted = false;
    });
  }

  void _setRiderTreatment(
    String riderId,
    PhysiotherapyTreatmentType treatment,
  ) {
    if (widget.isReadOnly) return;
    setState(() {
      _treatmentByRider[riderId] = treatment;
      if ((_allocatedMinutesByRider[riderId] ?? 0) == 0 &&
          _remainingPoolMinutes >= _sliderStepMinutes) {
        _allocatedMinutesByRider[riderId] = math.min(
          treatment.defaultDurationMinutes,
          _remainingPoolMinutes,
        );
      }
      _selectedRiderId = riderId;
      _isCommitted = false;
    });
  }

  void _applyAutoAllocation({bool notifyState = true}) {
    if (widget.isReadOnly && notifyState) return;
    final sorted = List<MorningBiomarkerSample>.from(_report.rosterSamples)
      ..sort((a, b) {
        final aRole = _rolesByRider[a.riderId];
        final bRole = _rolesByRider[b.riderId];
        final aScore =
            (100.0 - a.readinessScore) + (aRole?.isProtectedLeader == true ? 18.0 : 0.0);
        final bScore =
            (100.0 - b.readinessScore) + (bRole?.isProtectedLeader == true ? 18.0 : 0.0);
        return bScore.compareTo(aScore);
      });

    var pool = widget.totalPhysioPoolMinutes;
    final nextMinutes = <String, int>{
      for (final s in _report.rosterSamples) s.riderId: 0,
    };

    for (final sample in sorted) {
      if (pool <= 0) break;
      final role = _rolesByRider[sample.riderId];
      final desired = sample.readinessScore < 58.0
          ? 70
          : (role?.isProtectedLeader == true || sample.readinessScore < 70.0)
              ? 50
              : 30;
      final assigned = math.min(
        _maxMinutesPerRider,
        math.min(desired, (pool ~/ _sliderStepMinutes) * _sliderStepMinutes),
      );
      nextMinutes[sample.riderId] = assigned;
      pool -= assigned;
    }

    if (notifyState) {
      setState(() {
        _allocatedMinutesByRider = nextMinutes;
        _isCommitted = false;
      });
    } else {
      _allocatedMinutesByRider = nextMinutes;
    }
  }

  void _clearAllocations() {
    if (widget.isReadOnly) return;
    setState(() {
      _allocatedMinutesByRider = {
        for (final s in _report.rosterSamples) s.riderId: 0,
      };
      _isCommitted = false;
    });
  }

  void _commitBriefing() {
    if (widget.isReadOnly) return;
    final result = GrandTourMorningBriefingAllocationResult(
      stageDay: _report.stageDay,
      physioMinutesByRider: Map.unmodifiable(_allocatedMinutesByRider),
      treatmentByRider: Map.unmodifiable(_treatmentByRider),
      transportDecision: _transportDecision,
      totalAllocatedMinutes: _totalAllocatedMinutes,
      estimatedCostEur: _estimatedCostEur,
    );
    setState(() {
      _isCommitted = true;
    });
    widget.onCommitBriefing?.call(result);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Zatwierdzono poranny protokół medyczny (Etap ${_report.stageDay}): '
            'przydzielono $_totalAllocatedMinutes min pracy fizjoterapeutów.',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
  }

  List<MorningBiomarkerSample> get _filteredAndSortedRiders {
    final list = _report.rosterSamples.where((sample) {
      switch (_filterMode) {
        case MorningBriefingFilterMode.all:
          return true;
        case MorningBriefingFilterMode.alertsOnly:
          return sample.readinessScore < 68.0 ||
              sample.isElevatedCkAlert ||
              sample.isSleepDeprived ||
              sample.isCatabolicCrisis;
        case MorningBriefingFilterMode.leadersOnly:
          return _rolesByRider[sample.riderId]?.isProtectedLeader == true;
      }
    }).toList();

    list.sort((a, b) {
      switch (_sortMode) {
        case MorningBriefingSortMode.readinessAsc:
          return a.readinessScore.compareTo(b.readinessScore);
        case MorningBriefingSortMode.hrvDeltaAsc:
          return a.hrvZScore.compareTo(b.hrvZScore);
        case MorningBriefingSortMode.ckDesc:
          return b.creatineKinaseUL.compareTo(a.creatineKinaseUL);
        case MorningBriefingSortMode.rolePriority:
          final aIdx = _rolesByRider[a.riderId]?.index ?? 99;
          final bIdx = _rolesByRider[b.riderId]?.index ?? 99;
          return aIdx.compareTo(bIdx);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.65),
                ),
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: AppColors.goldAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Poranny Raport Medyczny • ${_report.tourName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Etap ${_report.stageDay}/21 • ${_report.weekPhase.displayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isReadOnly)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Chip(
                backgroundColor: AppColors.surfaceLight,
                side: BorderSide(color: AppTheme.borderColor),
                label: Text(
                  'Tylko podgląd',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 720;
          final isTablet = width >= 720 && width < 1280;
          final horizontalPadding = isMobile ? 12.0 : 20.0;
          final columns = isMobile ? 1 : (isTablet ? 2 : 2);
          final riders = _filteredAndSortedRiders;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryHeaderCard(isMobile: isMobile),
                const SizedBox(height: 14),
                _buildPhysioPoolAndLogisticsBar(isMobile: isMobile),
                const SizedBox(height: 14),
                _buildFilterAndSortToolbar(isMobile: isMobile),
                const SizedBox(height: 14),
                if (riders.isEmpty)
                  _buildEmptyFilterState()
                else
                  _buildRiderCardsGrid(
                    riders: riders,
                    columns: columns,
                    isMobile: isMobile,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeaderCard({required bool isMobile}) {
    final readinessColor = _readinessColor(_report.teamAverageReadiness);
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetricSummaryTile(
                icon: Icons.favorite_rounded,
                label: 'Gotowość Zespołu',
                value: '${_report.teamAverageReadiness.toStringAsFixed(1)}/100',
                accentColor: readinessColor,
              ),
              _MetricSummaryTile(
                icon: Icons.ssid_chart_rounded,
                label: 'Śr. Nocne HRV',
                value: '${_report.teamAverageHrvMs.toStringAsFixed(1)} ms',
                accentColor: AppColors.accentBlue,
              ),
              _MetricSummaryTile(
                icon: Icons.biotech_rounded,
                label: 'Śr. Kinaza CK',
                value: '${_report.teamAverageCkUL.toStringAsFixed(0)} U/L',
                accentColor: _report.teamAverageCkUL >= 850
                    ? AppColors.amberWarning
                    : AppColors.statusSuccess,
              ),
              _MetricSummaryTile(
                icon: Icons.bedtime_rounded,
                label: 'Jakość Snu',
                value: '${_report.teamAverageSleepScore.toStringAsFixed(1)}%',
                accentColor: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.medical_information_outlined,
                  color: AppColors.goldAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _report.medicalDirectorSummary,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysioPoolAndLogisticsBar({required bool isMobile}) {
    final poolRatio = widget.totalPhysioPoolMinutes > 0
        ? (_totalAllocatedMinutes / widget.totalPhysioPoolMinutes)
            .clamp(0.0, 1.0)
        : 0.0;
    final poolColor = _remainingPoolMinutes == 0
        ? AppColors.goldAccent
        : AppColors.statusSuccess;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.spa_outlined,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pula Czasu Fizjoterapeutów (${widget.specialistCount} specjalistów)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$_totalAllocatedMinutes / ${widget.totalPhysioPoolMinutes} min',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: poolColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: poolRatio),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(poolColor),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _BriefingActionButton(
                label: 'Transfer Autobusem (4h)',
                icon: Icons.directions_bus_outlined,
                isSelected: _transportDecision ==
                    TransferTransportDecision.fourHourTeamBus,
                isDisabled: widget.isReadOnly,
                onTap: () => setState(() {
                  _transportDecision =
                      TransferTransportDecision.fourHourTeamBus;
                  _isCommitted = false;
                }),
              ),
              _BriefingActionButton(
                label: 'Czarter Lotniczy (+2h snu)',
                icon: Icons.flight_takeoff_rounded,
                isSelected: _transportDecision ==
                    TransferTransportDecision.airCharterForLeaders,
                isDisabled: widget.isReadOnly,
                onTap: () => setState(() {
                  _transportDecision =
                      TransferTransportDecision.airCharterForLeaders;
                  _isCommitted = false;
                }),
              ),
              _BriefingActionButton(
                label: 'Auto-Przydział',
                icon: Icons.auto_fix_high_rounded,
                isDisabled: widget.isReadOnly,
                onTap: _applyAutoAllocation,
              ),
              _BriefingActionButton(
                label: 'Wyzeruj',
                icon: Icons.restart_alt_rounded,
                isDisabled: widget.isReadOnly || _totalAllocatedMinutes == 0,
                onTap: _clearAllocations,
              ),
              _BriefingActionButton(
                label: _isCommitted
                    ? 'Protokół Zatwierdzony'
                    : 'Zatwierdź Raport ($_estimatedCostEur €)',
                icon: _isCommitted
                    ? Icons.check_circle_rounded
                    : Icons.assignment_turned_in_rounded,
                isPrimary: true,
                isSelected: _isCommitted,
                isDisabled: widget.isReadOnly,
                onTap: _commitBriefing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortToolbar({required bool isMobile}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MorningBriefingFilterMode.values.map((mode) {
            return _BriefingActionButton(
              label: mode.labelPl,
              isSelected: _filterMode == mode,
              onTap: () => setState(() => _filterMode = mode),
            );
          }).toList(),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 260,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MorningBriefingSortMode>(
                isExpanded: true,
                isDense: true,
                value: _sortMode,
                dropdownColor: AppColors.surfaceLight,
                iconEnabledColor: AppColors.goldAccent,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: MorningBriefingSortMode.values.map((sortMode) {
                  return DropdownMenuItem<MorningBriefingSortMode>(
                    value: sortMode,
                    child: Text(
                      'Sortuj: ${sortMode.labelPl}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (next) {
                  if (next != null) {
                    setState(() => _sortMode = next);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFilterState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            color: AppColors.statusSuccess,
            size: 36,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak kolarzy spełniających wybrane kryteria filtra.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _BriefingActionButton(
            label: 'Pokaż wszystkich 8 kolarzy',
            isPrimary: true,
            onTap: () =>
                setState(() => _filterMode = MorningBriefingFilterMode.all),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCardsGrid({
    required List<MorningBiomarkerSample> riders,
    required int columns,
    required bool isMobile,
  }) {
    if (columns == 1) {
      return Column(
        children: [
          for (int i = 0; i < riders.length; i++) ...[
            _buildRiderBiometricCard(riders[i], isCompact: isMobile),
            if (i < riders.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < riders.length; i += columns) {
      final rowItems = riders.skip(i).take(columns).toList();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int c = 0; c < columns; c++) ...[
              Expanded(
                child: c < rowItems.length
                    ? _buildRiderBiometricCard(rowItems[c], isCompact: false)
                    : const SizedBox.shrink(),
              ),
              if (c < columns - 1) const SizedBox(width: 14),
            ],
          ],
        ),
      );
      if (i + columns < riders.length) {
        rows.add(const SizedBox(height: 14));
      }
    }
    return Column(children: rows);
  }

  Widget _buildRiderBiometricCard(
    MorningBiomarkerSample sample, {
    required bool isCompact,
  }) {
    final role = _rolesByRider[sample.riderId];
    final hrvHistory = _hrv7DayByRider[sample.riderId] ?? [sample.hrvRmssdMs];
    final baselineHrv =
        _baselineHrvByRider[sample.riderId] ?? sample.hrvRmssdMs;
    final allocatedMin = _allocatedMinutesByRider[sample.riderId] ?? 0;
    final selectedTreatment = _treatmentByRider[sample.riderId] ??
        PhysiotherapyTreatmentType.deepFasciaMassage;
    final isSelected = _selectedRiderId == sample.riderId;
    final readinessColor = _readinessColor(sample.readinessScore);
    final maxSliderMinutes = math.min(
      _maxMinutesPerRider,
      allocatedMin + _remainingPoolMinutes,
    );

    final projectedReadinessBoost = allocatedMin > 0
        ? (allocatedMin / 15.0) *
            (selectedTreatment == PhysiotherapyTreatmentType.wholeBodyCryotherapy
                ? 2.2
                : 1.7)
        : 0.0;
    final projectedReadiness =
        (sample.readinessScore + projectedReadinessBoost).clamp(0.0, 99.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.goldAccent.withValues(alpha: 0.75)
              : AppTheme.borderColor,
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sample.riderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (role != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: role.isProtectedLeader
                                  ? AppColors.goldAccent.withValues(alpha: 0.16)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: role.isProtectedLeader
                                    ? AppColors.goldAccent.withValues(alpha: 0.5)
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Text(
                              role.labelPl,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: role.isProtectedLeader
                                    ? AppColors.goldAccent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sample.readinessStatus.labelPl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: readinessColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ReadinessBadge(
                score: sample.readinessScore,
                projectedScore: projectedReadiness,
                color: readinessColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Wskaźnik gotowości mięśniowej
          _MuscleReadinessGauge(
            readinessScore: sample.readinessScore,
            projectedScore: projectedReadiness,
            creatineKinaseUL: sample.creatineKinaseUL,
            color: readinessColor,
          ),
          const SizedBox(height: 12),
          // Wykres trendu nocnego HRV z ostatnich 7 dni
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Trend Nocnego HRV (7 dni)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${sample.hrvRmssdMs.toStringAsFixed(1)} ms '
                        '(Z: ${sample.hrvZScore >= 0 ? '+' : ''}${sample.hrvZScore.toStringAsFixed(2)})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: sample.hrvZScore < -0.8
                              ? AppColors.amberWarning
                              : AppColors.accentBlue,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 76,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SevenDayHrvTrendChartPainter(
                      hrvValues: hrvHistory,
                      baselineHrv: baselineHrv,
                      lineColor: sample.hrvZScore < -0.8
                          ? AppColors.amberWarning
                          : AppColors.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Pigułki biomarkerów (RHR, CK, C/T, Sen)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BiomarkerPill(
                label: 'RHR',
                value:
                    '${sample.restingHeartRateBpm} bpm (${sample.rhrDeltaBpm >= 0 ? '+' : ''}${sample.rhrDeltaBpm})',
                isAlert: sample.rhrDeltaBpm >= 5,
              ),
              _BiomarkerPill(
                label: 'Kinaza CK',
                value: '${sample.creatineKinaseUL.toStringAsFixed(0)} U/L',
                isAlert: sample.isElevatedCkAlert,
              ),
              _BiomarkerPill(
                label: 'Kortyzol/Test.',
                value: sample.cortisolToTestosteroneRatio.toStringAsFixed(3),
                isAlert: sample.isCatabolicCrisis,
              ),
              _BiomarkerPill(
                label: 'Sen',
                value:
                    '${sample.totalSleepHours.toStringAsFixed(1)}h (${sample.sleepQualityScore.toStringAsFixed(0)}%)',
                isAlert: sample.isSleepDeprived,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Zalecenie medyczne
          Text(
            'Zalecenie: ${sample.recommendation.labelPl}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          // Wybór rodzaju zabiegu
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: PhysiotherapyTreatmentType.values.map((treatment) {
              final active = selectedTreatment == treatment;
              return _BriefingActionButton(
                label: '${treatment.labelPl} (${treatment.shortEffectPl})',
                isSelected: active,
                isCompact: true,
                isDisabled: widget.isReadOnly,
                onTap: () => _setRiderTreatment(sample.riderId, treatment),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Suwak przydziału czasu pracy fizjoterapeutów
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 6),
              const Text(
                'Czas fizjoterapeuty:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$allocatedMin min',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: allocatedMin > 0
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: widget.isReadOnly
                  ? AppColors.textSecondary
                  : AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
              trackHeight: 4,
            ),
            child: Slider(
              key: ValueKey<String>('physio_slider_${sample.riderId}'),
              value: allocatedMin
                  .clamp(0, math.max(_sliderStepMinutes, maxSliderMinutes))
                  .toDouble(),
              min: 0,
              max: math.max(_sliderStepMinutes, maxSliderMinutes).toDouble(),
              divisions: math.max(
                1,
                math.max(_sliderStepMinutes, maxSliderMinutes) ~/
                    _sliderStepMinutes,
              ),
              label: '$allocatedMin min',
              onChanged: widget.isReadOnly || maxSliderMinutes == 0
                  ? null
                  : (value) =>
                      _updateRiderPhysioMinutes(sample.riderId, value.round()),
            ),
          ),
        ],
      ),
    );
  }

  Color _readinessColor(double score) {
    if (score >= 82.0) return AppColors.statusSuccess;
    if (score >= 66.0) return AppColors.accentBlue;
    if (score >= 50.0) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }
}

class _MetricSummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _MetricSummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessBadge extends StatelessWidget {
  final double score;
  final double projectedScore;
  final Color color;

  const _ReadinessBadge({
    required this.score,
    required this.projectedScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasBoost = (projectedScore - score) >= 0.4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (hasBoost)
            Text(
              '→ ${projectedScore.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

class _MuscleReadinessGauge extends StatelessWidget {
  final double readinessScore;
  final double projectedScore;
  final double creatineKinaseUL;
  final Color color;

  const _MuscleReadinessGauge({
    required this.readinessScore,
    required this.projectedScore,
    required this.creatineKinaseUL,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currentRatio = (readinessScore / 100.0).clamp(0.0, 1.0);
    final projectedRatio = (projectedScore / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Gotowość mięśniowa',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              'CK ${creatineKinaseUL.toStringAsFixed(0)} U/L',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: creatineKinaseUL >= 850.0
                    ? AppColors.amberWarning
                    : AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.surfaceLight),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: projectedRatio,
                  child: Container(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: currentRatio,
                  child: Container(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BiomarkerPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;

  const _BiomarkerPill({
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isAlert
        ? AppColors.crimsonAlert.withValues(alpha: 0.65)
        : AppColors.cardBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isAlert
            ? AppColors.crimsonAlert.withValues(alpha: 0.1)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isAlert ? AppColors.crimsonAlert : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isPrimary;
  final bool isCompact;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _BriefingActionButton({
    required this.label,
    this.icon,
    this.isSelected = false,
    this.isPrimary = false,
    this.isCompact = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  State<_BriefingActionButton> createState() => _BriefingActionButtonState();
}

class _BriefingActionButtonState extends State<_BriefingActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isDisabled || widget.onTap == null;
    final bgColor = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isPrimary
            ? (_pressed
                ? AppColors.primaryAccent
                : _hovered
                    ? AppColors.primaryAccent.withValues(alpha: 0.9)
                    : AppColors.primaryAccent)
            : widget.isSelected
                ? AppColors.goldAccent.withValues(alpha: 0.18)
                : (_pressed || _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background);

    final borderColor = disabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.7)
                : widget.isSelected
                    ? AppColors.goldAccent
                    : AppTheme.borderColor;

    final fgColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : widget.isPrimary
            ? AppColors.textPrimary
            : widget.isSelected
                ? AppColors.goldAccent
                : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 9 : 12,
            vertical: widget.isCompact ? 6 : 9,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.isCompact ? 8 : 10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.isCompact ? 13 : 15, color: fgColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.isCompact ? 11 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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

/// Rysuje wykres trendu nocnego HRV (rMSSD ms) z ostatnich 7 dni wraz z linią bazową.
class _SevenDayHrvTrendChartPainter extends CustomPainter {
  final List<double> hrvValues;
  final double baselineHrv;
  final Color lineColor;

  const _SevenDayHrvTrendChartPainter({
    required this.hrvValues,
    required this.baselineHrv,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hrvValues.isEmpty || size.width <= 0 || size.height <= 0) return;

    const leftPad = 4.0;
    const rightPad = 6.0;
    const topPad = 8.0;
    const bottomPad = 16.0;

    final chartW = math.max(1.0, size.width - leftPad - rightPad);
    final chartH = math.max(1.0, size.height - topPad - bottomPad);

    var minVal = baselineHrv;
    var maxVal = baselineHrv;
    for (final v in hrvValues) {
      minVal = math.min(minVal, v);
      maxVal = math.max(maxVal, v);
    }
    final range = math.max(12.0, (maxVal - minVal) * 1.25);
    final low = minVal - range * 0.15;
    final high = low + range;

    double yFor(double v) {
      final norm = ((v - low) / (high - low)).clamp(0.0, 1.0);
      return topPad + chartH * (1.0 - norm);
    }

    // Linia bazowa (przerywana)
    final baselineY = yFor(baselineHrv);
    final basePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;
    for (double x = leftPad; x < leftPad + chartW; x += 7) {
      canvas.drawLine(
        Offset(x, baselineY),
        Offset(math.min(x + 3.5, leftPad + chartW), baselineY),
        basePaint,
      );
    }

    final points = <Offset>[];
    final count = hrvValues.length;
    for (int i = 0; i < count; i++) {
      final x = count == 1
          ? leftPad + chartW / 2
          : leftPad + (i / (count - 1)) * chartW;
      points.add(Offset(x, yFor(hrvValues[i])));
    }

    if (points.length >= 2) {
      final areaPath = Path()..moveTo(points.first.dx, topPad + chartH);
      for (final p in points) {
        areaPath.lineTo(p.dx, p.dy);
      }
      areaPath
        ..lineTo(points.last.dx, topPad + chartH)
        ..close();

      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.28),
            lineColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH));
      canvas.drawPath(areaPath, areaPaint);

      final strokePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        strokePath.lineTo(points[i].dx, points[i].dy);
      }
      final strokePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(strokePath, strokePaint);
    }

    final dotPaint = Paint()..color = lineColor;
    final lastDotPaint = Paint()..color = AppColors.goldAccent;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      canvas.drawCircle(
        points[i],
        isLast ? 3.5 : 2.3,
        isLast ? lastDotPaint : dotPaint,
      );

      final dayLabel = isLast ? 'D0' : 'D-${points.length - 1 - i}';
      textPainter.text = TextSpan(
        text: dayLabel,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
          color: isLast ? AppColors.goldAccent : AppColors.textSecondary,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (points[i].dx - textPainter.width / 2)
              .clamp(0.0, size.width - textPainter.width),
          size.height - textPainter.height,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SevenDayHrvTrendChartPainter oldDelegate) {
    return oldDelegate.hrvValues != hrvValues ||
        oldDelegate.baselineHrv != baselineHrv ||
        oldDelegate.lineColor != lineColor;
  }
}
