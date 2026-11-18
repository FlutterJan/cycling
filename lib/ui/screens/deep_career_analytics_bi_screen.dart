import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../state/career_controller.dart';

/// Zakres czasowy analizy Business Intelligence (BI).
enum BiTimeframeFilter {
  seasonCurrent('Sezon bieżący', 1.0),
  last3Seasons('Ostatnie 3 sezony', 2.75),
  allTimeCareer('Cała kariera', 4.5);

  final String label;
  final double horizonMultiplier;

  const BiTimeframeFilter(this.label, this.horizonMultiplier);
}

/// Zakładki główne ekranu analityki BI.
enum BiAnalyticsTab {
  overview('Przegląd & Krzywa ROI', Icons.insights_rounded),
  transfersRoi('ROI Transferów', Icons.swap_horiz_rounded),
  rdRoi('ROI R&D & Innowacji', Icons.science_rounded);

  final String label;
  final IconData icon;

  const BiAnalyticsTab(this.label, this.icon);
}

/// Kryterium sortowania tabeli transferów ROI.
enum TransferRoiSortBy {
  roiDesc('Najwyższy ROI %'),
  netProfitDesc('Najwyższy zysk netto'),
  costPerPointAsc('Najniższy koszt / pkt UCI'),
  investmentDesc('Najwyższa inwestycja');

  final String label;

  const TransferRoiSortBy(this.label);
}

/// Ocena efektywności inwestycji BI.
enum BiEfficiencyGrade {
  elite('S+', AppColors.goldAccent),
  high('A', AppColors.statusSuccess),
  solid('B', AppColors.accentBlue),
  marginal('C', AppColors.amberWarning),
  loss('D', AppColors.crimsonAlert);

  final String badge;
  final Color color;

  const BiEfficiencyGrade(this.badge, this.color);

  static BiEfficiencyGrade fromRoi(double roiPercent) {
    if (roiPercent >= 85.0) return BiEfficiencyGrade.elite;
    if (roiPercent >= 35.0) return BiEfficiencyGrade.high;
    if (roiPercent >= 5.0) return BiEfficiencyGrade.solid;
    if (roiPercent >= -15.0) return BiEfficiencyGrade.marginal;
    return BiEfficiencyGrade.loss;
  }
}

/// Rekord analityczny zwrotu z inwestycji (ROI) pojedynczego transferu / kontraktu kolarza.
class TransferRoiRecord {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final String roleLabel;
  final int age;
  final int acquisitionCostEur;
  final int annualSalaryEur;
  final int contractYears;
  final int uciPointsGenerated;
  final int winsCount;
  final int podiumsCount;
  final int tvExposureValueEur;
  final int prizeMoneyEarnedEur;

  const TransferRoiRecord({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.roleLabel,
    required this.age,
    required this.acquisitionCostEur,
    required this.annualSalaryEur,
    required this.contractYears,
    required this.uciPointsGenerated,
    required this.winsCount,
    required this.podiumsCount,
    required this.tvExposureValueEur,
    required this.prizeMoneyEarnedEur,
  });

  int get totalInvestmentEur =>
      math.max(0, acquisitionCostEur) + math.max(0, annualSalaryEur);

  /// Szacowana wartość sportowo-komercyjna wygenerowana przez kolarza.
  int get uciPointValuationEur => math.max(0, uciPointsGenerated) * 480;

  int get totalCommercialReturnEur =>
      math.max<int>(0, tvExposureValueEur) +
      math.max<int>(0, prizeMoneyEarnedEur) +
      uciPointValuationEur;

  int get netProfitEur => totalCommercialReturnEur - totalInvestmentEur;

  double get roiPercent {
    if (totalInvestmentEur <= 0) return 0.0;
    return (netProfitEur / totalInvestmentEur) * 100.0;
  }

  double get costPerUciPointEur {
    if (uciPointsGenerated <= 0) return double.infinity;
    return totalInvestmentEur / uciPointsGenerated;
  }

  BiEfficiencyGrade get grade => BiEfficiencyGrade.fromRoi(roiPercent);
}

/// Rekord analityczny zwrotu z inwestycji (ROI) projektu R&D i infrastruktury.
class RdInvestmentRoiRecord {
  final String projectId;
  final String projectName;
  final String category;
  final int capexInvestedEur;
  final int opexAnnualEur;
  final double wattsSaved;
  final double cdaDelta;
  final double raceSecondsSavedPer100km;
  final int estimatedPointsGain;
  final int commercialLicensingReturnEur;
  final int estimatedPrizeGainEur;
  final double maturityProgress;
  final bool isPrioritized;

  const RdInvestmentRoiRecord({
    required this.projectId,
    required this.projectName,
    required this.category,
    required this.capexInvestedEur,
    required this.opexAnnualEur,
    required this.wattsSaved,
    required this.cdaDelta,
    required this.raceSecondsSavedPer100km,
    required this.estimatedPointsGain,
    required this.commercialLicensingReturnEur,
    required this.estimatedPrizeGainEur,
    required this.maturityProgress,
    this.isPrioritized = false,
  });

  RdInvestmentRoiRecord copyWith({bool? isPrioritized}) {
    return RdInvestmentRoiRecord(
      projectId: projectId,
      projectName: projectName,
      category: category,
      capexInvestedEur: capexInvestedEur,
      opexAnnualEur: opexAnnualEur,
      wattsSaved: wattsSaved,
      cdaDelta: cdaDelta,
      raceSecondsSavedPer100km: raceSecondsSavedPer100km,
      estimatedPointsGain: estimatedPointsGain,
      commercialLicensingReturnEur: commercialLicensingReturnEur,
      estimatedPrizeGainEur: estimatedPrizeGainEur,
      maturityProgress: maturityProgress,
      isPrioritized: isPrioritized ?? this.isPrioritized,
    );
  }

  int get totalCostEur => math.max(0, capexInvestedEur) + math.max(0, opexAnnualEur);

  int get totalValueGeneratedEur =>
      math.max<int>(0, commercialLicensingReturnEur) +
      math.max<int>(0, estimatedPrizeGainEur) +
      (math.max<int>(0, estimatedPointsGain) * 520);

  int get netValueEur => totalValueGeneratedEur - totalCostEur;

  double get roiPercent {
    if (totalCostEur <= 0) return 0.0;
    return (netValueEur / totalCostEur) * 100.0;
  }

  double get wattsPer100kEur {
    if (totalCostEur <= 0) return 0.0;
    return wattsSaved / (totalCostEur / 100000.0);
  }

  double get paybackMonths {
    if (totalValueGeneratedEur <= 0) return 99.0;
    final monthlyReturn = totalValueGeneratedEur / 12.0;
    return (totalCostEur / monthlyReturn).clamp(1.0, 99.0);
  }

  BiEfficiencyGrade get grade => BiEfficiencyGrade.fromRoi(roiPercent);
}

/// Punkt danych miesięcznej krzywej skumulowanego ROI.
class BiMonthlyRoiPoint {
  final int monthIndex;
  final String monthLabel;
  final double transferRoiPercent;
  final double rdRoiPercent;
  final double blendedRoiPercent;

  const BiMonthlyRoiPoint({
    required this.monthIndex,
    required this.monthLabel,
    required this.transferRoiPercent,
    required this.rdRoiPercent,
    required this.blendedRoiPercent,
  });
}

/// Zbiorczy pakiet danych analityki BI dla ekranu.
class DeepCareerBiDataset {
  final String teamName;
  final int seasonYear;
  final bool isLiveCareerData;
  final List<TransferRoiRecord> transfers;
  final List<RdInvestmentRoiRecord> rdProjects;
  final List<BiMonthlyRoiPoint> monthlyCurve;

  const DeepCareerBiDataset({
    required this.teamName,
    required this.seasonYear,
    required this.isLiveCareerData,
    required this.transfers,
    required this.rdProjects,
    required this.monthlyCurve,
  });

  int get totalTransferInvestmentEur =>
      transfers.fold<int>(0, (sum, e) => sum + e.totalInvestmentEur);

  int get totalTransferReturnEur =>
      transfers.fold<int>(0, (sum, e) => sum + e.totalCommercialReturnEur);

  double get transferRoiPercent {
    if (totalTransferInvestmentEur <= 0) return 0.0;
    return ((totalTransferReturnEur - totalTransferInvestmentEur) /
            totalTransferInvestmentEur) *
        100.0;
  }

  int get totalRdInvestmentEur =>
      rdProjects.fold<int>(0, (sum, e) => sum + e.totalCostEur);

  int get totalRdReturnEur =>
      rdProjects.fold<int>(0, (sum, e) => sum + e.totalValueGeneratedEur);

  double get rdRoiPercent {
    if (totalRdInvestmentEur <= 0) return 0.0;
    return ((totalRdReturnEur - totalRdInvestmentEur) / totalRdInvestmentEur) *
        100.0;
  }

  int get totalCapitalDeployedEur =>
      totalTransferInvestmentEur + totalRdInvestmentEur;

  int get totalValueGeneratedEur => totalTransferReturnEur + totalRdReturnEur;

  double get blendedRoiPercent {
    if (totalCapitalDeployedEur <= 0) return 0.0;
    return ((totalValueGeneratedEur - totalCapitalDeployedEur) /
            totalCapitalDeployedEur) *
        100.0;
  }

  int get totalUciPoints =>
      transfers.fold<int>(0, (sum, e) => sum + e.uciPointsGenerated);

  double get avgCostPerUciPointEur {
    if (totalUciPoints <= 0) return 0.0;
    return totalTransferInvestmentEur / totalUciPoints;
  }

  double get totalWattsGained =>
      rdProjects.fold<double>(0.0, (sum, e) => sum + e.wattsSaved);
}

/// Kalkulator budujący spójny model BI na bazie `CareerSave` lub zestawu benchmarkowego.
class DeepCareerAnalyticsBiCalculator {
  DeepCareerAnalyticsBiCalculator._();

  static const List<String> _monthNames = [
    'Sty',
    'Lut',
    'Mar',
    'Kwi',
    'Maj',
    'Cze',
    'Lip',
    'Sie',
    'Wrz',
    'Paź',
    'Lis',
    'Gru',
  ];

  static DeepCareerBiDataset build({
    CareerSave? save,
    BiTimeframeFilter timeframe = BiTimeframeFilter.seasonCurrent,
  }) {
    if (save != null && save.playerTeam.rosterRiderIds.isNotEmpty) {
      return _buildFromCareerSave(save, timeframe);
    }
    return _buildBenchmarkDataset(timeframe);
  }

  static DeepCareerBiDataset _buildFromCareerSave(
    CareerSave save,
    BiTimeframeFilter timeframe,
  ) {
    final team = save.playerTeam;
    final rosterSet = team.rosterRiderIds.toSet();
    final teamRiders = save.riders.where((r) => rosterSet.contains(r.id)).toList();

    if (teamRiders.isEmpty) {
      return _buildBenchmarkDataset(timeframe, teamName: team.name, seasonYear: save.currentSeasonYear);
    }

    final mult = timeframe.horizonMultiplier;
    final transfers = <TransferRoiRecord>[];

    for (final Rider rider in teamRiders.take(14)) {
      final age = math.max(18, save.currentSeasonYear - rider.birthDate.year);
      final salary = math.max(45000, rider.contract.annualSalaryEur);
      final acquisition = (salary * 0.42).round();
      final uciPts = math.max(15, (rider.careerPointsUci * 0.35 * mult).round());
      final wins = math.max(0, (uciPts / 260).floor());
      final podiums = math.max(wins, (uciPts / 120).floor());
      final tvExposure = ((uciPts * 1150) + (wins * 95000)).round();
      final prizeMoney = ((uciPts * 140) + (wins * 24000)).round();

      transfers.add(
        TransferRoiRecord(
          riderId: rider.id,
          riderName: rider.fullName,
          nationalityIso: rider.nationalityIso,
          roleLabel: rider.specialization.displayName,
          age: age,
          acquisitionCostEur: (acquisition * (mult > 1.5 ? 1.2 : 1.0)).round(),
          annualSalaryEur: (salary * mult).round(),
          contractYears: math.max(1, rider.contract.contractEndYear - save.currentSeasonYear + 1),
          uciPointsGenerated: uciPts,
          winsCount: wins,
          podiumsCount: podiums,
          tvExposureValueEur: tvExposure,
          prizeMoneyEarnedEur: prizeMoney,
        ),
      );
    }

    final rdProjects = _buildRdProjects(
      windTunnelLevel: save.windTunnelLevel,
      serviceCourseLevel: save.serviceCourseLevel,
      medicalCenterLevel: save.medicalCenterLevel,
      mult: mult,
    );

    final curve = _buildMonthlyCurve(
      transferRoi: _calcTransferRoi(transfers),
      rdRoi: _calcRdRoi(rdProjects),
    );

    return DeepCareerBiDataset(
      teamName: team.name,
      seasonYear: save.currentSeasonYear,
      isLiveCareerData: true,
      transfers: transfers,
      rdProjects: rdProjects,
      monthlyCurve: curve,
    );
  }

  static DeepCareerBiDataset _buildBenchmarkDataset(
    BiTimeframeFilter timeframe, {
    String teamName = 'Veloce Apex WorldTour',
    int seasonYear = 2026,
  }) {
    final m = timeframe.horizonMultiplier;

    final transfers = <TransferRoiRecord>[
      TransferRoiRecord(
        riderId: 'r_bi_1',
        riderName: 'Kacper Majewski',
        nationalityIso: 'PL',
        roleLabel: 'Lider GC / Góral',
        age: 24,
        acquisitionCostEur: (380000 * (m > 1.5 ? 1.15 : 1.0)).round(),
        annualSalaryEur: (920000 * m).round(),
        contractYears: 3,
        uciPointsGenerated: (1840 * m).round(),
        winsCount: (6 * m).round(),
        podiumsCount: (14 * m).round(),
        tvExposureValueEur: (1950000 * m).round(),
        prizeMoneyEarnedEur: (320000 * m).round(),
      ),
      TransferRoiRecord(
        riderId: 'r_bi_2',
        riderName: 'Lucas Van Der Berg',
        nationalityIso: 'BE',
        roleLabel: 'Klasykowiec / Bruki',
        age: 26,
        acquisitionCostEur: (540000 * (m > 1.5 ? 1.15 : 1.0)).round(),
        annualSalaryEur: (1150000 * m).round(),
        contractYears: 2,
        uciPointsGenerated: (1620 * m).round(),
        winsCount: (4 * m).round(),
        podiumsCount: (11 * m).round(),
        tvExposureValueEur: (1680000 * m).round(),
        prizeMoneyEarnedEur: (265000 * m).round(),
      ),
      TransferRoiRecord(
        riderId: 'r_bi_3',
        riderName: 'Matteo Ferraro',
        nationalityIso: 'IT',
        roleLabel: 'Czysty Sprinter',
        age: 22,
        acquisitionCostEur: (160000 * (m > 1.5 ? 1.1 : 1.0)).round(),
        annualSalaryEur: (410000 * m).round(),
        contractYears: 4,
        uciPointsGenerated: (1190 * m).round(),
        winsCount: (8 * m).round(),
        podiumsCount: (16 * m).round(),
        tvExposureValueEur: (1020000 * m).round(),
        prizeMoneyEarnedEur: (175000 * m).round(),
      ),
      TransferRoiRecord(
        riderId: 'r_bi_4',
        riderName: 'Henrik Solberg',
        nationalityIso: 'NO',
        roleLabel: 'Czasowiec (TT)',
        age: 29,
        acquisitionCostEur: (290000 * (m > 1.5 ? 1.1 : 1.0)).round(),
        annualSalaryEur: (680000 * m).round(),
        contractYears: 2,
        uciPointsGenerated: (740 * m).round(),
        winsCount: (2 * m).round(),
        podiumsCount: (6 * m).round(),
        tvExposureValueEur: (610000 * m).round(),
        prizeMoneyEarnedEur: (95000 * m).round(),
      ),
      TransferRoiRecord(
        riderId: 'r_bi_5',
        riderName: 'Julien Moreau',
        nationalityIso: 'FR',
        roleLabel: 'Puncher / Pagórki',
        age: 31,
        acquisitionCostEur: (620000 * (m > 1.5 ? 1.05 : 1.0)).round(),
        annualSalaryEur: (1250000 * m).round(),
        contractYears: 1,
        uciPointsGenerated: (520 * m).round(),
        winsCount: (1 * m).round(),
        podiumsCount: (3 * m).round(),
        tvExposureValueEur: (790000 * m).round(),
        prizeMoneyEarnedEur: (82000 * m).round(),
      ),
      TransferRoiRecord(
        riderId: 'r_bi_6',
        riderName: 'Diego Alvarez',
        nationalityIso: 'ES',
        roleLabel: 'Pomocnik (Domestique)',
        age: 21,
        acquisitionCostEur: (85000 * (m > 1.5 ? 1.05 : 1.0)).round(),
        annualSalaryEur: (210000 * m).round(),
        contractYears: 3,
        uciPointsGenerated: (490 * m).round(),
        winsCount: (1 * m).round(),
        podiumsCount: (4 * m).round(),
        tvExposureValueEur: (310000 * m).round(),
        prizeMoneyEarnedEur: (54000 * m).round(),
      ),
    ];

    final rdProjects = _buildRdProjects(
      windTunnelLevel: 3,
      serviceCourseLevel: 3,
      medicalCenterLevel: 2,
      mult: m,
    );

    final curve = _buildMonthlyCurve(
      transferRoi: _calcTransferRoi(transfers),
      rdRoi: _calcRdRoi(rdProjects),
    );

    return DeepCareerBiDataset(
      teamName: teamName,
      seasonYear: seasonYear,
      isLiveCareerData: false,
      transfers: transfers,
      rdProjects: rdProjects,
      monthlyCurve: curve,
    );
  }

  static List<RdInvestmentRoiRecord> _buildRdProjects({
    required int windTunnelLevel,
    required int serviceCourseLevel,
    required int medicalCenterLevel,
    required double mult,
  }) {
    return [
      RdInvestmentRoiRecord(
        projectId: 'rd_aero_1',
        projectName: 'Tunel Aero CFD & Pozycja TT v$windTunnelLevel',
        category: 'Aerodynamika / Tunel',
        capexInvestedEur: (420000 * (1 + windTunnelLevel * 0.15)).round(),
        opexAnnualEur: (135000 * mult).round(),
        wattsSaved: 14.5 + (windTunnelLevel * 1.8),
        cdaDelta: -0.014 - (windTunnelLevel * 0.002),
        raceSecondsSavedPer100km: 48.0 + (windTunnelLevel * 6.5),
        estimatedPointsGain: (390 * mult).round(),
        commercialLicensingReturnEur: (490000 * mult).round(),
        estimatedPrizeGainEur: (240000 * mult).round(),
        maturityProgress: 0.88,
        isPrioritized: true,
      ),
      RdInvestmentRoiRecord(
        projectId: 'rd_frame_2',
        projectName: 'Własna Rama Karbonowa T1100 Layup',
        category: 'Ramy & Karbon',
        capexInvestedEur: 680000,
        opexAnnualEur: (190000 * mult).round(),
        wattsSaved: 9.2 + (serviceCourseLevel * 1.1),
        cdaDelta: -0.008,
        raceSecondsSavedPer100km: 31.0,
        estimatedPointsGain: (310 * mult).round(),
        commercialLicensingReturnEur: (920000 * mult).round(),
        estimatedPrizeGainEur: (185000 * mult).round(),
        maturityProgress: 0.76,
      ),
      RdInvestmentRoiRecord(
        projectId: 'rd_phys_3',
        projectName: 'Lab Mleczanowy LT2 & Krioterapia',
        category: 'Fizjologia & Regeneracja',
        capexInvestedEur: (260000 * (1 + medicalCenterLevel * 0.1)).round(),
        opexAnnualEur: (110000 * mult).round(),
        wattsSaved: 11.4 + (medicalCenterLevel * 1.4),
        cdaDelta: 0.0,
        raceSecondsSavedPer100km: 37.5,
        estimatedPointsGain: (340 * mult).round(),
        commercialLicensingReturnEur: (140000 * mult).round(),
        estimatedPrizeGainEur: (295000 * mult).round(),
        maturityProgress: 0.94,
      ),
      RdInvestmentRoiRecord(
        projectId: 'rd_drivetrain_4',
        projectName: 'Wosk PTFE & Koła Hookless 55mm',
        category: 'Napęd & Toczenie',
        capexInvestedEur: 145000,
        opexAnnualEur: (65000 * mult).round(),
        wattsSaved: 6.8,
        cdaDelta: -0.005,
        raceSecondsSavedPer100km: 22.0,
        estimatedPointsGain: (185 * mult).round(),
        commercialLicensingReturnEur: (110000 * mult).round(),
        estimatedPrizeGainEur: (115000 * mult).round(),
        maturityProgress: 1.0,
      ),
    ];
  }

  static double _calcTransferRoi(List<TransferRoiRecord> items) {
    final inv = items.fold<int>(0, (s, e) => s + e.totalInvestmentEur);
    final ret = items.fold<int>(0, (s, e) => s + e.totalCommercialReturnEur);
    if (inv <= 0) return 0.0;
    return ((ret - inv) / inv) * 100.0;
  }

  static double _calcRdRoi(List<RdInvestmentRoiRecord> items) {
    final inv = items.fold<int>(0, (s, e) => s + e.totalCostEur);
    final ret = items.fold<int>(0, (s, e) => s + e.totalValueGeneratedEur);
    if (inv <= 0) return 0.0;
    return ((ret - inv) / inv) * 100.0;
  }

  static List<BiMonthlyRoiPoint> _buildMonthlyCurve({
    required double transferRoi,
    required double rdRoi,
  }) {
    final points = <BiMonthlyRoiPoint>[];
    for (int i = 0; i < 12; i++) {
      // Kolarstwo: Q1 ujemny cashflow (obozy, zakupy), Q2-Q3 dynamiczny wzrost (klasyki + GT)
      final progress = (i + 1) / 12.0;
      final sCurve = math.sin(progress * math.pi * 0.5);
      final tVal = -28.0 + (transferRoi + 28.0) * math.pow(progress, 0.85);
      final rVal = -42.0 + (rdRoi + 42.0) * sCurve;
      final blended = (tVal * 0.65) + (rVal * 0.35);

      points.add(
        BiMonthlyRoiPoint(
          monthIndex: i,
          monthLabel: _monthNames[i],
          transferRoiPercent: tVal,
          rdRoiPercent: rVal,
          blendedRoiPercent: blended,
        ),
      );
    }
    return points;
  }
}

/// Ekran Analityki Biznesowo-Sportowej BI (zwrot z inwestycji ROI dla transferów i R&D).
class DeepCareerAnalyticsBiScreen extends ConsumerStatefulWidget {
  final CareerSave? overrideSave;

  const DeepCareerAnalyticsBiScreen({
    super.key,
    this.overrideSave,
  });

  @override
  ConsumerState<DeepCareerAnalyticsBiScreen> createState() =>
      _DeepCareerAnalyticsBiScreenState();
}

class _DeepCareerAnalyticsBiScreenState
    extends ConsumerState<DeepCareerAnalyticsBiScreen>
    with SingleTickerProviderStateMixin {
  BiTimeframeFilter _timeframe = BiTimeframeFilter.seasonCurrent;
  BiAnalyticsTab _activeTab = BiAnalyticsTab.overview;
  TransferRoiSortBy _transferSortBy = TransferRoiSortBy.roiDesc;
  String _searchQuery = '';
  BiEfficiencyGrade? _gradeFilter;
  String? _selectedTransferId;
  int _selectedMonthIndex = 11;
  double _whatIfRdBudgetEur = 1200000.0;
  final Set<String> _prioritizedRdIds = {'rd_aero_1'};
  bool _isExporting = false;

  late final TextEditingController _searchController;
  late final AnimationController _entryAnimController;
  late final Animation<double> _entryFade;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _entryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _entryFade = CurvedAnimation(
      parent: _entryAnimController,
      curve: Curves.easeOutCubic,
    );
    _entryAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entryAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CareerSave? activeSave =
        widget.overrideSave ?? ref.watch(careerProvider).save;
    final dataset = DeepCareerAnalyticsBiCalculator.build(
      save: activeSave,
      timeframe: _timeframe,
    );

    final effectiveRdProjects = dataset.rdProjects
        .map((p) => p.copyWith(isPrioritized: _prioritizedRdIds.contains(p.projectId)))
        .toList();

    final effectiveDataset = DeepCareerBiDataset(
      teamName: dataset.teamName,
      seasonYear: dataset.seasonYear,
      isLiveCareerData: dataset.isLiveCareerData,
      transfers: dataset.transfers,
      rdProjects: effectiveRdProjects,
      monthlyCurve: dataset.monthlyCurve,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 720;
              final isTablet = width >= 720 && width < 1200;
              final horizontalPadding = isMobile ? 12.0 : (isTablet ? 20.0 : 28.0);

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isMobile ? 12.0 : 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(effectiveDataset, isMobile: isMobile),
                    const SizedBox(height: 16),
                    _buildKpiStrip(
                      effectiveDataset,
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                    const SizedBox(height: 16),
                    _buildTabBar(isMobile: isMobile),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: _buildTabContent(
                        effectiveDataset,
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    DeepCareerBiDataset dataset, {
    required bool isMobile,
  }) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.55),
                ),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const Text(
              'Analityka BI — ROI Transferów & R&D',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            _StatusPill(
              label: dataset.isLiveCareerData ? 'KARIERA LIVE' : 'BENCHMARK BI',
              color: dataset.isLiveCareerData
                  ? AppColors.statusSuccess
                  : AppColors.accentBlue,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${dataset.teamName} • Sezon ${dataset.seasonYear} • Efektywność kapitału sportowego i technologicznego',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final controlsBlock = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...BiTimeframeFilter.values.map(
          (tf) => _BiInteractiveChip(
            label: tf.label,
            selected: _timeframe == tf,
            onTap: () => setState(() => _timeframe = tf),
          ),
        ),
        _BiActionButton(
          icon: _isExporting ? Icons.hourglass_top_rounded : Icons.download_rounded,
          label: _isExporting ? 'Eksport...' : 'Eksport Raportu BI',
          isPrimary: true,
          enabled: !_isExporting,
          onPressed: () => _handleExportReport(dataset),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                controlsBlock,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                controlsBlock,
              ],
            ),
    );
  }

  Widget _buildKpiStrip(
    DeepCareerBiDataset dataset, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final cards = [
      _BiKpiCard(
        title: 'Skumulowany ROI',
        value: _formatSignedPercent(dataset.blendedRoiPercent),
        subtitle:
            'Kapitał: ${Formatters.formatCompactCurrency(dataset.totalCapitalDeployedEur)}',
        accentColor: dataset.blendedRoiPercent >= 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.trending_up_rounded,
        badge: BiEfficiencyGrade.fromRoi(dataset.blendedRoiPercent).badge,
      ),
      _BiKpiCard(
        title: 'ROI Transferów',
        value: _formatSignedPercent(dataset.transferRoiPercent),
        subtitle:
            'Koszt / pkt UCI: ${Formatters.formatCurrency(dataset.avgCostPerUciPointEur.round())}',
        accentColor: AppColors.goldAccent,
        icon: Icons.groups_rounded,
        badge: '${dataset.totalUciPoints} pkt',
      ),
      _BiKpiCard(
        title: 'ROI Badań R&D',
        value: _formatSignedPercent(dataset.rdRoiPercent),
        subtitle:
            'Zysk aero/lab: +${dataset.totalWattsGained.toStringAsFixed(1)} W',
        accentColor: AppColors.accentBlue,
        icon: Icons.biotech_rounded,
        badge: '${dataset.rdProjects.length} proj.',
      ),
      _BiKpiCard(
        title: 'Wygenerowana Wartość',
        value: Formatters.formatCompactCurrency(
          dataset.totalValueGeneratedEur,
        ),
        subtitle: 'Ekspozycja TV + Nagrody + Licencje',
        accentColor: AppColors.cyanAccent,
        icon: Icons.account_balance_wallet_rounded,
        badge: 'NETTO',
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildTabBar({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: BiAnalyticsTab.values
                  .map(
                    (tab) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _BiTabButton(
                        tab: tab,
                        selected: _activeTab == tab,
                        onTap: () => setState(() => _activeTab = tab),
                      ),
                    ),
                  )
                  .toList(),
            )
          : Row(
              children: BiAnalyticsTab.values
                  .map(
                    (tab) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _BiTabButton(
                          tab: tab,
                          selected: _activeTab == tab,
                          onTap: () => setState(() => _activeTab = tab),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildTabContent(
    DeepCareerBiDataset dataset, {
    required bool isMobile,
    required bool isTablet,
  }) {
    switch (_activeTab) {
      case BiAnalyticsTab.overview:
        return _buildOverviewTab(
          dataset,
          key: const ValueKey('tab_overview'),
          isMobile: isMobile,
          isTablet: isTablet,
        );
      case BiAnalyticsTab.transfersRoi:
        return _buildTransfersTab(
          dataset,
          key: const ValueKey('tab_transfers'),
          isMobile: isMobile,
        );
      case BiAnalyticsTab.rdRoi:
        return _buildRdTab(
          dataset,
          key: const ValueKey('tab_rd'),
          isMobile: isMobile,
        );
    }
  }

  Widget _buildOverviewTab(
    DeepCareerBiDataset dataset, {
    required Key key,
    required bool isMobile,
    required bool isTablet,
  }) {
    final selectedPoint = dataset.monthlyCurve.isNotEmpty
        ? dataset.monthlyCurve[_selectedMonthIndex.clamp(0, dataset.monthlyCurve.length - 1)]
        : null;

    final roiCurveCard = _BiPanel(
      title: 'Krzywa Skumulowanego ROI (12 mies.)',
      subtitle: 'Porównanie zwrotu z transferów vs projektów R&D względem progu Break-Even (0%)',
      trailing: selectedPoint == null
          ? null
          : _StatusPill(
              label:
                  '${selectedPoint.monthLabel}: ${_formatSignedPercent(selectedPoint.blendedRoiPercent)}',
              color: selectedPoint.blendedRoiPercent >= 0
                  ? AppColors.statusSuccess
                  : AppColors.amberWarning,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isMobile ? 210 : 250,
            child: CustomPaint(
              painter: _BiRoiCurvePainter(
                points: dataset.monthlyCurve,
                selectedMonthIndex: _selectedMonthIndex,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: dataset.monthlyCurve.map((pt) {
              return _BiInteractiveChip(
                label: pt.monthLabel,
                selected: _selectedMonthIndex == pt.monthIndex,
                compact: true,
                onTap: () => setState(() => _selectedMonthIndex = pt.monthIndex),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _LegendDot(color: AppColors.goldAccent, label: 'Transfery ROI %'),
              _LegendDot(color: AppColors.accentBlue, label: 'R&D ROI %'),
              _LegendDot(color: AppColors.statusSuccess, label: 'Portfel Łączny'),
            ],
          ),
        ],
      ),
    );

    final scatterCard = _BiPanel(
      title: 'Macierz Efektywności Kapitału',
      subtitle: 'Oś X: Koszt inwestycji (€) • Oś Y: Wartość zwrotu (€)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isMobile ? 210 : 250,
            child: CustomPaint(
              painter: _EfficiencyScatterPainter(
                transfers: dataset.transfers,
                rdProjects: dataset.rdProjects,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _LegendDot(color: AppColors.goldAccent, label: 'Kolarze (Transfery)'),
              _LegendDot(color: AppColors.cyanAccent, label: 'Projekty R&D'),
              _LegendDot(color: AppColors.textSecondary, label: 'Linia Break-Even 1:1'),
            ],
          ),
        ],
      ),
    );

    final allocationCard = _buildCapitalAllocationPanel(dataset, isMobile: isMobile);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMobile || isTablet) ...[
          roiCurveCard,
          const SizedBox(height: 16),
          scatterCard,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: roiCurveCard),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: scatterCard),
            ],
          ),
        const SizedBox(height: 16),
        allocationCard,
      ],
    );
  }

  Widget _buildCapitalAllocationPanel(
    DeepCareerBiDataset dataset, {
    required bool isMobile,
  }) {
    final total = math.max(1, dataset.totalCapitalDeployedEur);
    final transferShare = (dataset.totalTransferInvestmentEur / total).clamp(0.0, 1.0);
    final rdShare = (dataset.totalRdInvestmentEur / total).clamp(0.0, 1.0);

    final sortedTransfers = [...dataset.transfers]
      ..sort((a, b) => b.roiPercent.compareTo(a.roiPercent));
    final bestTransfer = sortedTransfers.isNotEmpty ? sortedTransfers.first : null;
    final sortedRd = [...dataset.rdProjects]
      ..sort((a, b) => b.roiPercent.compareTo(a.roiPercent));
    final bestRd = sortedRd.isNotEmpty ? sortedRd.first : null;

    return _BiPanel(
      title: 'Struktura Alokacji Kapitału & Liderzy Zwrotu',
      subtitle: 'Podział wydatków operacyjnych i najskuteczniejsze aktywa klubu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: math.max(1, (transferShare * 100).round()),
                    child: Container(color: AppColors.goldAccent),
                  ),
                  Expanded(
                    flex: math.max(1, (rdShare * 100).round()),
                    child: Container(color: AppColors.accentBlue),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              Text(
                'Transfery i Kontrakty: ${(transferShare * 100).toStringAsFixed(1)}% (${Formatters.formatCompactCurrency(dataset.totalTransferInvestmentEur)})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Inwestycje R&D: ${(rdShare * 100).toStringAsFixed(1)}% (${Formatters.formatCompactCurrency(dataset.totalRdInvestmentEur)})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isMobile) ...[
            if (bestTransfer != null)
              _HighlightAssetTile(
                label: 'TOP TRANSFER ROI',
                title: bestTransfer.riderName,
                metric: _formatSignedPercent(bestTransfer.roiPercent),
                detail:
                    '${bestTransfer.uciPointsGenerated} pkt UCI • Zysk ${Formatters.formatCompactCurrency(bestTransfer.netProfitEur)}',
                color: AppColors.goldAccent,
              ),
            if (bestTransfer != null && bestRd != null) const SizedBox(height: 10),
            if (bestRd != null)
              _HighlightAssetTile(
                label: 'TOP PROJEKT R&D',
                title: bestRd.projectName,
                metric: _formatSignedPercent(bestRd.roiPercent),
                detail:
                    '+${bestRd.wattsSaved.toStringAsFixed(1)} W • Zwrot po ${bestRd.paybackMonths.toStringAsFixed(1)} mies.',
                color: AppColors.accentBlue,
              ),
          ] else
            Row(
              children: [
                if (bestTransfer != null)
                  Expanded(
                    child: _HighlightAssetTile(
                      label: 'TOP TRANSFER ROI',
                      title: bestTransfer.riderName,
                      metric: _formatSignedPercent(bestTransfer.roiPercent),
                      detail:
                          '${bestTransfer.uciPointsGenerated} pkt UCI • Zysk ${Formatters.formatCompactCurrency(bestTransfer.netProfitEur)}',
                      color: AppColors.goldAccent,
                    ),
                  ),
                if (bestTransfer != null && bestRd != null) const SizedBox(width: 12),
                if (bestRd != null)
                  Expanded(
                    child: _HighlightAssetTile(
                      label: 'TOP PROJEKT R&D',
                      title: bestRd.projectName,
                      metric: _formatSignedPercent(bestRd.roiPercent),
                      detail:
                          '+${bestRd.wattsSaved.toStringAsFixed(1)} W • Zwrot po ${bestRd.paybackMonths.toStringAsFixed(1)} mies.',
                      color: AppColors.accentBlue,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTransfersTab(
    DeepCareerBiDataset dataset, {
    required Key key,
    required bool isMobile,
  }) {
    final filtered = dataset.transfers.where((r) {
      final matchesSearch = _searchQuery.trim().isEmpty ||
          r.riderName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.roleLabel.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGrade = _gradeFilter == null || r.grade == _gradeFilter;
      return matchesSearch && matchesGrade;
    }).toList();

    filtered.sort((a, b) {
      switch (_transferSortBy) {
        case TransferRoiSortBy.roiDesc:
          return b.roiPercent.compareTo(a.roiPercent);
        case TransferRoiSortBy.netProfitDesc:
          return b.netProfitEur.compareTo(a.netProfitEur);
        case TransferRoiSortBy.costPerPointAsc:
          return a.costPerUciPointEur.compareTo(b.costPerUciPointEur);
        case TransferRoiSortBy.investmentDesc:
          return b.totalInvestmentEur.compareTo(a.totalInvestmentEur);
      }
    });

    final selectedRecord = filtered.cast<TransferRoiRecord?>().firstWhere(
          (r) => r?.riderId == _selectedTransferId,
          orElse: () => filtered.isNotEmpty ? filtered.first : null,
        );

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BiPanel(
          title: 'Audyt Rentowności Transferów i Kontraktów',
          subtitle:
              'Koszt pozyskania + pensja vs ekspozycja TV, nagrody i wartość punktów UCI',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 260,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Szukaj kolarza lub roli...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.goldAccent),
                        ),
                      ),
                    ),
                  ),
                  ...TransferRoiSortBy.values.map(
                    (s) => _BiInteractiveChip(
                      label: s.label,
                      selected: _transferSortBy == s,
                      compact: true,
                      onTap: () => setState(() => _transferSortBy = s),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Klasa ROI:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  _BiInteractiveChip(
                    label: 'Wszystkie',
                    selected: _gradeFilter == null,
                    compact: true,
                    onTap: () => setState(() => _gradeFilter = null),
                  ),
                  ...BiEfficiencyGrade.values.map(
                    (g) => _BiInteractiveChip(
                      label: 'Klasa ${g.badge}',
                      selected: _gradeFilter == g,
                      compact: true,
                      accentColor: g.color,
                      onTap: () => setState(() => _gradeFilter = g),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        color: AppColors.textSecondary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Brak transferów spełniających wybrane kryteria.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _BiActionButton(
                        icon: Icons.refresh_rounded,
                        label: 'Wyczyść filtry',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _gradeFilter = null;
                          });
                        },
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: filtered.map((record) {
                    final isSelected = selectedRecord?.riderId == record.riderId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TransferRoiRowCard(
                        record: record,
                        isSelected: isSelected,
                        isMobile: isMobile,
                        onTap: () =>
                            setState(() => _selectedTransferId = record.riderId),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        if (selectedRecord != null) ...[
          const SizedBox(height: 16),
          _buildTransferDetailPanel(selectedRecord, isMobile: isMobile),
        ],
      ],
    );
  }

  Widget _buildTransferDetailPanel(
    TransferRoiRecord record, {
    required bool isMobile,
  }) {
    return _BiPanel(
      title: 'Karta Rentowności: ${record.riderName}',
      subtitle: '${record.roleLabel} • Wiek: ${record.age} lat • Kontrakt: ${record.contractYears} lat',
      trailing: _StatusPill(
        label: 'ROI ${_formatSignedPercent(record.roiPercent)}',
        color: record.grade.color,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _DetailMetricBox(
            label: 'Odstępne + Podpis',
            value: Formatters.formatCurrency(record.acquisitionCostEur),
            width: isMobile ? double.infinity : 210,
          ),
          _DetailMetricBox(
            label: 'Pensja w okresie',
            value: Formatters.formatCurrency(record.annualSalaryEur),
            width: isMobile ? double.infinity : 210,
          ),
          _DetailMetricBox(
            label: 'Ekspozycja TV Sponsora',
            value: Formatters.formatCurrency(record.tvExposureValueEur),
            valueColor: AppColors.accentBlue,
            width: isMobile ? double.infinity : 210,
          ),
          _DetailMetricBox(
            label: 'Nagrody & Pkt UCI',
            value:
                '${Formatters.formatCurrency(record.prizeMoneyEarnedEur + record.uciPointValuationEur)} (${record.uciPointsGenerated} pkt)',
            valueColor: AppColors.goldAccent,
            width: isMobile ? double.infinity : 240,
          ),
          _DetailMetricBox(
            label: 'Bilans Netto',
            value: Formatters.formatCurrency(record.netProfitEur),
            valueColor: record.netProfitEur >= 0
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert,
            width: isMobile ? double.infinity : 210,
          ),
        ],
      ),
    );
  }

  Widget _buildRdTab(
    DeepCareerBiDataset dataset, {
    required Key key,
    required bool isMobile,
  }) {
    final projectedWatts = (_whatIfRdBudgetEur / 100000.0) * 2.45;
    final projectedPoints = (_whatIfRdBudgetEur / 100000.0) * 44.0;
    final projectedReturnEur = (_whatIfRdBudgetEur * 1.48).round();
    final projectedRoi = ((projectedReturnEur - _whatIfRdBudgetEur) /
            _whatIfRdBudgetEur) *
        100.0;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BiPanel(
          title: 'Symulator Alokacji Budżetu R&D (What-If)',
          subtitle: 'Przetestuj wpływ dodatkowego kapitału na zysk aerodynamiczny i punkty UCI',
          trailing: _StatusPill(
            label: 'Prognoza ROI ${_formatSignedPercent(projectedRoi)}',
            color: AppColors.statusSuccess,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alokowany budżet R&D:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(_whatIfRdBudgetEur.round()),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.goldAccent,
                  inactiveTrackColor: AppColors.surfaceLight,
                  thumbColor: AppColors.goldAccent,
                  overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _whatIfRdBudgetEur,
                  min: 200000,
                  max: 3000000,
                  divisions: 28,
                  onChanged: (v) => setState(() => _whatIfRdBudgetEur = v),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _DetailMetricBox(
                    label: 'Szacowany zysk mocy',
                    value: '+${projectedWatts.toStringAsFixed(1)} W',
                    valueColor: AppColors.accentBlue,
                    width: isMobile ? double.infinity : 200,
                  ),
                  _DetailMetricBox(
                    label: 'Dodatkowe pkt UCI',
                    value: '+${projectedPoints.round()} pkt',
                    valueColor: AppColors.goldAccent,
                    width: isMobile ? double.infinity : 200,
                  ),
                  _DetailMetricBox(
                    label: 'Zwrot komercyjny',
                    value: Formatters.formatCompactCurrency(projectedReturnEur),
                    valueColor: AppColors.statusSuccess,
                    width: isMobile ? double.infinity : 220,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _BiPanel(
          title: 'Portfel Projektów R&D i Infrastruktury',
          subtitle: 'Kliknij "Priorytet", aby oznaczyć kluczowe inicjatywy badawcze na bieżący sezon',
          child: Column(
            children: dataset.rdProjects.map((project) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RdProjectRoiCard(
                  project: project,
                  isMobile: isMobile,
                  onTogglePriority: () {
                    setState(() {
                      if (_prioritizedRdIds.contains(project.projectId)) {
                        _prioritizedRdIds.remove(project.projectId);
                      } else {
                        _prioritizedRdIds.add(project.projectId);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _handleExportReport(DeepCareerBiDataset dataset) async {
    setState(() => _isExporting = true);
    final summary =
        'BI Report | ${dataset.teamName} (${dataset.seasonYear}) | '
        'Blended ROI: ${_formatSignedPercent(dataset.blendedRoiPercent)} | '
        'Transfer ROI: ${_formatSignedPercent(dataset.transferRoiPercent)} | '
        'R&D ROI: ${_formatSignedPercent(dataset.rdRoiPercent)}';

    await Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) return;
    setState(() => _isExporting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Skopiowano raport BI (${dataset.seasonYear}) do schowka.',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  static String _formatSignedPercent(double val) {
    final sign = val > 0 ? '+' : '';
    return '$sign${val.toStringAsFixed(1)}%';
  }
}

class _BiPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  const _BiPanel({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BiKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final String badge;

  const _BiKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.badge,
  });

  @override
  State<_BiKpiCard> createState() => _BiKpiCardState();
}

class _BiKpiCardState extends State<_BiKpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.accentColor.withValues(alpha: 0.65)
                : AppColors.cardBorder,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 17, color: widget.accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                _StatusPill(label: widget.badge, color: widget.accentColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: widget.accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiTabButton extends StatefulWidget {
  final BiAnalyticsTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _BiTabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_BiTabButton> createState() => _BiTabButtonState();
}

class _BiTabButtonState extends State<_BiTabButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent
        : (_pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : (_hovered ? AppColors.surfaceLight : Colors.transparent));

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.selected
                      ? AppColors.goldAccent.withValues(alpha: 0.45)
                      : Colors.transparent),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.tab.icon,
                size: 17,
                color: widget.selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.tab.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

class _BiInteractiveChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool compact;
  final Color? accentColor;
  final VoidCallback onTap;

  const _BiInteractiveChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.accentColor,
  });

  @override
  State<_BiInteractiveChip> createState() => _BiInteractiveChipState();
}

class _BiInteractiveChipState extends State<_BiInteractiveChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.goldAccent;
    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: widget.compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? accent.withValues(alpha: 0.18)
                : (_pressed || _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : (widget.selected ? accent : AppColors.cardBorder),
              width: 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: widget.compact ? 11.5 : 12.5,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected ? accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BiActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  const _BiActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.enabled = true,
  });

  @override
  State<_BiActionButton> createState() => _BiActionButtonState();
}

class _BiActionButtonState extends State<_BiActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseBg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight);

    final bgColor = !widget.enabled
        ? baseBg
        : (_pressed
            ? baseBg.withValues(alpha: 0.78)
            : (_hovered ? baseBg.withValues(alpha: 0.92) : baseBg));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: !widget.enabled
                  ? AppColors.cardBorder.withValues(alpha: 0.5)
                  : (_focused
                      ? AppColors.goldAccent
                      : (widget.isPrimary
                          ? AppColors.goldAccent.withValues(alpha: 0.45)
                          : AppColors.cardBorder)),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
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

class _TransferRoiRowCard extends StatefulWidget {
  final TransferRoiRecord record;
  final bool isSelected;
  final bool isMobile;
  final VoidCallback onTap;

  const _TransferRoiRowCard({
    required this.record,
    required this.isSelected,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_TransferRoiRowCard> createState() => _TransferRoiRowCardState();
}

class _TransferRoiRowCardState extends State<_TransferRoiRowCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final roiSign = r.roiPercent > 0 ? '+' : '';
    final costPerPtText = r.costPerUciPointEur.isFinite
        ? Formatters.formatCurrency(r.costPerUciPointEur.round())
        : '—';

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.16)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : (widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.cardBorder),
              width: 1.0,
            ),
          ),
          child: widget.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusPill(
                          label: r.grade.badge,
                          color: r.grade.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.riderName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$roiSign${r.roiPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: r.grade.color,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${r.roleLabel} (${r.nationalityIso}) • ${r.uciPointsGenerated} pkt UCI',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inwestycja: ${Formatters.formatCompactCurrency(r.totalInvestmentEur)} • Koszt/pkt: $costPerPtText',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _StatusPill(label: r.grade.badge, color: r.grade.color),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.riderName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${r.roleLabel} • ${r.nationalityIso} • ${r.winsCount} zw. / ${r.podiumsCount} pod.',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Inw: ${Formatters.formatCompactCurrency(r.totalInvestmentEur)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r.uciPointsGenerated} pkt ($costPerPtText/pkt)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Text(
                      '$roiSign${r.roiPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: r.grade.color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RdProjectRoiCard extends StatelessWidget {
  final RdInvestmentRoiRecord project;
  final bool isMobile;
  final VoidCallback onTogglePriority;

  const _RdProjectRoiCard({
    required this.project,
    required this.isMobile,
    required this.onTogglePriority,
  });

  @override
  Widget build(BuildContext context) {
    final roiSign = project.roiPercent > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: project.isPrioritized
              ? AppColors.goldAccent.withValues(alpha: 0.7)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          project.projectName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        _StatusPill(
                          label: project.category,
                          color: AppColors.accentBlue,
                        ),
                        _StatusPill(
                          label: 'ROI $roiSign${project.roiPercent.toStringAsFixed(1)}%',
                          color: project.grade.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Zysk: +${project.wattsSaved.toStringAsFixed(1)} W • '
                      '-${project.raceSecondsSavedPer100km.toStringAsFixed(0)} s / 100 km • '
                      'Zwrot: ${project.paybackMonths.toStringAsFixed(1)} mies.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _BiActionButton(
                icon: project.isPrioritized
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                label: project.isPrioritized ? 'Priorytet' : 'Oznacz',
                isPrimary: project.isPrioritized,
                onPressed: onTogglePriority,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: project.maturityProgress.clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(project.grade.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(project.maturityProgress * 100).round()}% wdrożenia • '
                '${project.wattsPer100kEur.toStringAsFixed(2)} W/100k€',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightAssetTile extends StatelessWidget {
  final String label;
  final String title;
  final String metric;
  final String detail;
  final Color color;

  const _HighlightAssetTile({
    required this.label,
    required this.title,
    required this.metric,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                metric,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double width;

  const _DetailMetricBox({
    required this.label,
    required this.value,
    required this.width,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BiRoiCurvePainter extends CustomPainter {
  final List<BiMonthlyRoiPoint> points;
  final int selectedMonthIndex;

  const _BiRoiCurvePainter({
    required this.points,
    required this.selectedMonthIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    const leftPad = 38.0;
    const rightPad = 12.0;
    const topPad = 14.0;
    const bottomPad = 24.0;

    final chartWidth = math.max(1.0, size.width - leftPad - rightPad);
    final chartHeight = math.max(1.0, size.height - topPad - bottomPad);

    double minY = -50.0;
    double maxY = 100.0;
    for (final p in points) {
      minY = math.min(
        minY,
        math.min(p.transferRoiPercent, math.min(p.rdRoiPercent, p.blendedRoiPercent)),
      );
      maxY = math.max(
        maxY,
        math.max(p.transferRoiPercent, math.max(p.rdRoiPercent, p.blendedRoiPercent)),
      );
    }
    final rangeY = math.max(10.0, maxY - minY);

    double yFor(double val) {
      final norm = (val - minY) / rangeY;
      return topPad + chartHeight * (1.0 - norm);
    }

    double xFor(int idx) {
      return leftPad + (idx / (points.length - 1)) * chartWidth;
    }

    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;

    // Grid & Break-Even 0%
    for (final tick in [minY, 0.0, maxY * 0.5, maxY]) {
      final y = yFor(tick);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartWidth, y),
        tick == 0.0
            ? (Paint()
              ..color = AppColors.textSecondary.withValues(alpha: 0.7)
              ..strokeWidth = 1.2)
            : gridPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${tick.round()}%',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    void drawSeries(double Function(BiMonthlyRoiPoint) selector, Color color, double stroke) {
      final path = Path();
      for (int i = 0; i < points.length; i++) {
        final pt = Offset(xFor(i), yFor(selector(points[i])));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawSeries((p) => p.transferRoiPercent, AppColors.goldAccent, 2.2);
    drawSeries((p) => p.rdRoiPercent, AppColors.accentBlue, 2.2);
    drawSeries((p) => p.blendedRoiPercent, AppColors.statusSuccess, 2.6);

    final selIdx = selectedMonthIndex.clamp(0, points.length - 1);
    final selX = xFor(selIdx);
    canvas.drawLine(
      Offset(selX, topPad),
      Offset(selX, topPad + chartHeight),
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.45)
        ..strokeWidth = 1.2,
    );

    final selY = yFor(points[selIdx].blendedRoiPercent);
    canvas.drawCircle(
      Offset(selX, selY),
      5.0,
      Paint()..color = AppColors.statusSuccess,
    );
    canvas.drawCircle(
      Offset(selX, selY),
      5.0,
      Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _BiRoiCurvePainter oldDelegate) {
    return oldDelegate.selectedMonthIndex != selectedMonthIndex ||
        oldDelegate.points != points;
  }
}

class _EfficiencyScatterPainter extends CustomPainter {
  final List<TransferRoiRecord> transfers;
  final List<RdInvestmentRoiRecord> rdProjects;

  const _EfficiencyScatterPainter({
    required this.transfers,
    required this.rdProjects,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 26.0;
    final w = math.max(1.0, size.width - pad * 2);
    final h = math.max(1.0, size.height - pad * 2);

    double maxCost = 100000.0;
    double maxVal = 100000.0;

    for (final t in transfers) {
      maxCost = math.max(maxCost, t.totalInvestmentEur.toDouble());
      maxVal = math.max(maxVal, t.totalCommercialReturnEur.toDouble());
    }
    for (final r in rdProjects) {
      maxCost = math.max(maxCost, r.totalCostEur.toDouble());
      maxVal = math.max(maxVal, r.totalValueGeneratedEur.toDouble());
    }

    final maxScale = math.max(maxCost, maxVal) * 1.1;

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(pad, pad), Offset(pad, pad + h), axisPaint);
    canvas.drawLine(Offset(pad, pad + h), Offset(pad + w, pad + h), axisPaint);

    // 1:1 Break-Even diagonal
    canvas.drawLine(
      Offset(pad, pad + h),
      Offset(pad + w, pad),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.45)
        ..strokeWidth = 1.2,
    );

    for (final t in transfers) {
      final x = pad + (t.totalInvestmentEur / maxScale) * w;
      final y = pad + h - (t.totalCommercialReturnEur / maxScale) * h;
      canvas.drawCircle(
        Offset(x, y),
        5.5,
        Paint()..color = AppColors.goldAccent.withValues(alpha: 0.85),
      );
    }

    for (final r in rdProjects) {
      final x = pad + (r.totalCostEur / maxScale) * w;
      final y = pad + h - (r.totalValueGeneratedEur / maxScale) * h;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 10, height: 10),
        Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EfficiencyScatterPainter oldDelegate) {
    return oldDelegate.transfers != transfers ||
        oldDelegate.rdProjects != rdProjects;
  }
}
