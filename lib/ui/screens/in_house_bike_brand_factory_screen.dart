import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/team/in_house_bike_brand_manufacturing_model.dart';

/// Zakładki główne ekranu Fabryki i Działu R&D własnej marki rowerowej.
enum BikeBrandFactoryTab {
  factoryAndRd,
  geometryStudio,
  externalLicenses,
  retailAnalytics;

  String get labelPl {
    switch (this) {
      case BikeBrandFactoryTab.factoryAndRd:
        return 'Fabryka & R&D';
      case BikeBrandFactoryTab.geometryStudio:
        return 'Studio Geometrii';
      case BikeBrandFactoryTab.externalLicenses:
        return 'Licencje B2B';
      case BikeBrandFactoryTab.retailAnalytics:
        return 'Sprzedaż & Finanse';
    }
  }

  IconData get icon {
    switch (this) {
      case BikeBrandFactoryTab.factoryAndRd:
        return Icons.precision_manufacturing_rounded;
      case BikeBrandFactoryTab.geometryStudio:
        return Icons.architecture_rounded;
      case BikeBrandFactoryTab.externalLicenses:
        return Icons.handshake_rounded;
      case BikeBrandFactoryTab.retailAnalytics:
        return Icons.analytics_rounded;
    }
  }
}

/// Parametry geometryczne ramy szosowej/TT projektowanej w Studio Geometrii.
class FrameGeometrySpec {
  final double stackMm;
  final double reachMm;
  final double headTubeAngleDeg;
  final double seatTubeAngleDeg;
  final double chainstayMm;
  final double wheelbaseMm;
  final double bbDropMm;

  const FrameGeometrySpec({
    this.stackMm = 548.0,
    this.reachMm = 392.0,
    this.headTubeAngleDeg = 73.2,
    this.seatTubeAngleDeg = 73.5,
    this.chainstayMm = 410.0,
    this.wheelbaseMm = 988.0,
    this.bbDropMm = 72.0,
  });

  factory FrameGeometrySpec.presetForCategory(FrameCategory category) {
    switch (category) {
      case FrameCategory.aero:
        return const FrameGeometrySpec(
          stackMm: 532.0,
          reachMm: 400.0,
          headTubeAngleDeg: 73.5,
          seatTubeAngleDeg: 73.8,
          chainstayMm: 408.0,
          wheelbaseMm: 984.0,
          bbDropMm: 72.0,
        );
      case FrameCategory.lightweightClimbing:
        return const FrameGeometrySpec(
          stackMm: 544.0,
          reachMm: 390.0,
          headTubeAngleDeg: 73.0,
          seatTubeAngleDeg: 73.5,
          chainstayMm: 406.0,
          wheelbaseMm: 980.0,
          bbDropMm: 71.0,
        );
      case FrameCategory.allRounder:
        return const FrameGeometrySpec();
      case FrameCategory.cobbleEndurance:
        return const FrameGeometrySpec(
          stackMm: 576.0,
          reachMm: 380.0,
          headTubeAngleDeg: 72.0,
          seatTubeAngleDeg: 73.0,
          chainstayMm: 420.0,
          wheelbaseMm: 1012.0,
          bbDropMm: 75.0,
        );
      case FrameCategory.timeTrial:
        return const FrameGeometrySpec(
          stackMm: 512.0,
          reachMm: 416.0,
          headTubeAngleDeg: 72.8,
          seatTubeAngleDeg: 75.5,
          chainstayMm: 405.0,
          wheelbaseMm: 996.0,
          bbDropMm: 70.0,
        );
    }
  }

  double get stackToReachRatio => stackMm / math.max(1.0, reachMm);

  FrameGeometrySpec copyWith({
    double? stackMm,
    double? reachMm,
    double? headTubeAngleDeg,
    double? seatTubeAngleDeg,
    double? chainstayMm,
    double? wheelbaseMm,
    double? bbDropMm,
  }) {
    return FrameGeometrySpec(
      stackMm: stackMm ?? this.stackMm,
      reachMm: reachMm ?? this.reachMm,
      headTubeAngleDeg: headTubeAngleDeg ?? this.headTubeAngleDeg,
      seatTubeAngleDeg: seatTubeAngleDeg ?? this.seatTubeAngleDeg,
      chainstayMm: chainstayMm ?? this.chainstayMm,
      wheelbaseMm: wheelbaseMm ?? this.wheelbaseMm,
      bbDropMm: bbDropMm ?? this.bbDropMm,
    );
  }
}

/// Wynik obliczeń inżynieryjnych geometrii i laminatu ramy.
class FrameGeometryEvaluation {
  final int estimatedWeightGrams;
  final double aeroCdaModifier;
  final double stiffnessToWeightIndex;
  final double comfortCompliance;
  final double forkTrailMm;
  final int unitManufacturingCostEur;
  final int wholesalePriceEur;
  final int retailMsrpEur;
  final bool uciLegal;
  final String handlingVerdictPl;

  const FrameGeometryEvaluation({
    required this.estimatedWeightGrams,
    required this.aeroCdaModifier,
    required this.stiffnessToWeightIndex,
    required this.comfortCompliance,
    required this.forkTrailMm,
    required this.unitManufacturingCostEur,
    required this.wholesalePriceEur,
    required this.retailMsrpEur,
    required this.uciLegal,
    required this.handlingVerdictPl,
  });
}

/// Kalkulator parametrów fizycznych, masy i kosztów produkcji z geometrii ramy.
class FrameGeometryCalculator {
  FrameGeometryCalculator._();

  static FrameGeometryEvaluation evaluate({
    required FrameGeometrySpec spec,
    required FrameCategory category,
    required CarbonLayupGrade carbonGrade,
    required int rdEngineeringLevel,
  }) {
    final str = spec.stackToReachRatio;
    final rdBonus = (rdEngineeringLevel - 50).clamp(-20, 50) * 0.0001;

    int baseWeight;
    double baseCda;
    double baseStiffness;
    double baseCompliance;
    int baseCost;

    switch (category) {
      case FrameCategory.aero:
        baseWeight = 890;
        baseCda = -0.017;
        baseStiffness = 1.94;
        baseCompliance = 0.56;
        baseCost = 1420;
        break;
      case FrameCategory.lightweightClimbing:
        baseWeight = 675;
        baseCda = -0.004;
        baseStiffness = 1.88;
        baseCompliance = 0.72;
        baseCost = 1360;
        break;
      case FrameCategory.allRounder:
        baseWeight = 745;
        baseCda = -0.009;
        baseStiffness = 1.84;
        baseCompliance = 0.74;
        baseCost = 1250;
        break;
      case FrameCategory.cobbleEndurance:
        baseWeight = 860;
        baseCda = 0.002;
        baseStiffness = 1.70;
        baseCompliance = 0.92;
        baseCost = 1210;
        break;
      case FrameCategory.timeTrial:
        baseWeight = 1090;
        baseCda = -0.029;
        baseStiffness = 2.05;
        baseCompliance = 0.42;
        baseCost = 1780;
        break;
    }

    final carbonWeightFactor = switch (carbonGrade) {
      CarbonLayupGrade.standardModulusT700 => 1.09,
      CarbonLayupGrade.highModulusT800 => 1.00,
      CarbonLayupGrade.ultraHighModulusT1100 => 0.91,
      CarbonLayupGrade.aerospacePitchFiber => 0.85,
    };

    final stackWeightPenalty = ((spec.stackMm - 540.0) * 0.9).round();
    final chainstayPenalty = ((spec.chainstayMm - 410.0) * 1.4).round();
    final estimatedWeight = math.max(
      580,
      ((baseWeight * carbonWeightFactor) + stackWeightPenalty + chainstayPenalty - (rdEngineeringLevel * 0.5)).round(),
    );

    final aggressiveAeroGain = ((1.40 - str) * 0.018).clamp(-0.008, 0.010);
    final cdaModifier = double.parse(
      (baseCda - aggressiveAeroGain - rdBonus).clamp(-0.038, 0.010).toStringAsFixed(4),
    );

    final compactStiffnessGain = ((412.0 - spec.chainstayMm) * 0.008).clamp(-0.10, 0.10);
    final stiffness = double.parse(
      (baseStiffness + carbonGrade.stiffnessBonus + compactStiffnessGain).clamp(1.1, 2.7).toStringAsFixed(2),
    );

    final enduranceComplianceGain =
        ((spec.chainstayMm - 410.0) * 0.012 + (spec.bbDropMm - 70.0) * 0.008).clamp(-0.08, 0.14);
    final compliance = double.parse(
      (baseCompliance + enduranceComplianceGain).clamp(0.25, 1.0).toStringAsFixed(2),
    );

    // Przybliżony wyprzedzenie widelca (Trail) dla koła 700x28c (R=340mm) i rake=45mm
    final headRad = spec.headTubeAngleDeg * math.pi / 180.0;
    final trail = (340.0 * math.cos(headRad) - 45.0) / math.sin(headRad);

    final unitCost = (baseCost * carbonGrade.manufacturingCostMultiplier).round();
    final wholesale = (unitCost * 2.10).round();
    final retailMsrp = (unitCost * 4.35).round();

    final uciLegal = spec.wheelbaseMm <= 1050.0 &&
        spec.chainstayMm >= 395.0 &&
        spec.headTubeAngleDeg >= 70.0 &&
        spec.seatTubeAngleDeg <= 78.0 &&
        estimatedWeight >= 580;

    final String verdict;
    if (trail < 53.0) {
      verdict = 'Bardzo ostra reakcja kierownicy (Kryterium / Sprint)';
    } else if (trail <= 61.0) {
      verdict = 'Zbalansowana precyzja WorldTour (Zjazdy i Peleton)';
    } else {
      verdict = 'Wysoka stabilność kierunkowa (Bruk / Wiatr boczny)';
    }

    return FrameGeometryEvaluation(
      estimatedWeightGrams: estimatedWeight,
      aeroCdaModifier: cdaModifier,
      stiffnessToWeightIndex: stiffness,
      comfortCompliance: compliance,
      forkTrailMm: double.parse(trail.toStringAsFixed(1)),
      unitManufacturingCostEur: unitCost,
      wholesalePriceEur: wholesale,
      retailMsrpEur: retailMsrp,
      uciLegal: uciLegal,
      handlingVerdictPl: verdict,
    );
  }
}

/// Oferta zewnętrznej drużyny zainteresowanej licencją na ramy marki gracza.
class ExternalLicenseTeamOffer {
  final String offerId;
  final String teamId;
  final String teamName;
  final TeamFrameTargetDivision division;
  final int annualLicenseFeeEur;
  final int framesOrderedPerSeason;
  final int royaltyPerWorldTourWinEur;
  final int contractYears;

  const ExternalLicenseTeamOffer({
    required this.offerId,
    required this.teamId,
    required this.teamName,
    required this.division,
    required this.annualLicenseFeeEur,
    required this.framesOrderedPerSeason,
    required this.royaltyPerWorldTourWinEur,
    required this.contractYears,
  });

  static const List<ExternalLicenseTeamOffer> defaultMarketOffers = [
    ExternalLicenseTeamOffer(
      offerId: 'offer_polonia_pro',
      teamId: 'team_polonia_pro',
      teamName: 'Polonia Cycling ProTeam',
      division: TeamFrameTargetDivision.proTeam,
      annualLicenseFeeEur: 145000,
      framesOrderedPerSeason: 52,
      royaltyPerWorldTourWinEur: 12000,
      contractYears: 2,
    ),
    ExternalLicenseTeamOffer(
      offerId: 'offer_alpes_conti',
      teamId: 'team_alpes_conti',
      teamName: 'Savoie Alpes Development U23',
      division: TeamFrameTargetDivision.continental,
      annualLicenseFeeEur: 68000,
      framesOrderedPerSeason: 28,
      royaltyPerWorldTourWinEur: 5000,
      contractYears: 2,
    ),
    ExternalLicenseTeamOffer(
      offerId: 'offer_nordic_wt',
      teamId: 'team_nordic_wt',
      teamName: 'Nordic Fjord WorldTeam',
      division: TeamFrameTargetDivision.worldTour,
      annualLicenseFeeEur: 320000,
      framesOrderedPerSeason: 85,
      royaltyPerWorldTourWinEur: 28000,
      contractYears: 3,
    ),
    ExternalLicenseTeamOffer(
      offerId: 'offer_iberia_pro',
      teamId: 'team_iberia_pro',
      teamName: 'Sierra Nevada Pro Cycling',
      division: TeamFrameTargetDivision.proTeam,
      annualLicenseFeeEur: 165000,
      framesOrderedPerSeason: 60,
      royaltyPerWorldTourWinEur: 15000,
      contractYears: 2,
    ),
  ];
}

/// Stan kontrolera fabryki własnej marki rowerowej.
class InHouseBikeBrandFactoryState {
  final InHouseBikeBrandModel model;
  final int teamCashEur;
  final int currentSeasonYear;
  final int currentQuarter;
  final List<ExternalLicenseTeamOffer> availableOffers;

  const InHouseBikeBrandFactoryState({
    required this.model,
    required this.teamCashEur,
    required this.currentSeasonYear,
    required this.currentQuarter,
    required this.availableOffers,
  });

  factory InHouseBikeBrandFactoryState.initial() {
    final starter = InHouseBikeBrandModel.createStarter(
      brandId: 'brand_vanguard_works',
      ownerTeamId: 'player_team',
      ownerTeamName: 'Vanguard Pro Cycling',
      brandName: 'Vanguard Works',
      seasonYear: 2026,
    );
    final q1Result = starter.simulateQuarterFinancials(
      seasonYear: 2026,
      quarter: 1,
      ownTeamFramesConsumed: 22,
      partnerWorldTourWins: 0,
    );
    return InHouseBikeBrandFactoryState(
      model: q1Result.model,
      teamCashEur: 4850000,
      currentSeasonYear: 2026,
      currentQuarter: 2,
      availableOffers: ExternalLicenseTeamOffer.defaultMarketOffers,
    );
  }

  InHouseBikeBrandFactoryState copyWith({
    InHouseBikeBrandModel? model,
    int? teamCashEur,
    int? currentSeasonYear,
    int? currentQuarter,
    List<ExternalLicenseTeamOffer>? availableOffers,
  }) {
    return InHouseBikeBrandFactoryState(
      model: model ?? this.model,
      teamCashEur: teamCashEur ?? this.teamCashEur,
      currentSeasonYear: currentSeasonYear ?? this.currentSeasonYear,
      currentQuarter: currentQuarter ?? this.currentQuarter,
      availableOffers: availableOffers ?? this.availableOffers,
    );
  }
}

/// Notifier Riverpod zarządzający stanem Fabryki i Działu R&D własnej marki.
class InHouseBikeBrandFactoryNotifier extends StateNotifier<InHouseBikeBrandFactoryState> {
  InHouseBikeBrandFactoryNotifier([InHouseBikeBrandFactoryState? initialState])
      : super(initialState ?? InHouseBikeBrandFactoryState.initial());

  BrandOperationResult upgradeFacility(ManufacturingFacilityTier nextTier) {
    final result = state.model.upgradeFacility(
      nextTier: nextTier,
      availableTeamCashEur: state.teamCashEur,
    );
    if (result.success) {
      state = state.copyWith(
        model: result.model,
        teamCashEur: state.teamCashEur + result.cashDeltaEur,
      );
    }
    return result;
  }

  BrandOperationResult startRdProject({
    required String title,
    required String targetBlueprintId,
    required RdProjectFocus focus,
    required int budgetEur,
  }) {
    final projectId = 'rd_${DateTime.now().microsecondsSinceEpoch}';
    final result = state.model.startRdProject(
      projectId: projectId,
      title: title,
      targetBlueprintId: targetBlueprintId,
      focus: focus,
      budgetEur: budgetEur,
      availableTeamCashEur: state.teamCashEur,
    );
    if (result.success) {
      state = state.copyWith(
        model: result.model,
        teamCashEur: state.teamCashEur + result.cashDeltaEur,
      );
    }
    return result;
  }

  void advanceRdDays(int days) {
    final updated = state.model.advanceRdProjects(days);
    state = state.copyWith(model: updated);
  }

  void saveBlueprintGeometry({
    required String blueprintId,
    required FrameCategory category,
    required CarbonLayupGrade carbonGrade,
    required FrameGeometryEvaluation evaluation,
  }) {
    final updatedBlueprints = state.model.blueprints.map((bp) {
      if (bp.blueprintId != blueprintId) return bp;
      return bp.copyWith(
        category: category,
        carbonGrade: carbonGrade,
        weightGrams: evaluation.estimatedWeightGrams,
        aeroCdaModifier: evaluation.aeroCdaModifier,
        stiffnessToWeightIndex: evaluation.stiffnessToWeightIndex,
        comfortCompliance: evaluation.comfortCompliance,
        unitManufacturingCostEur: evaluation.unitManufacturingCostEur,
        wholesalePriceEur: evaluation.wholesalePriceEur,
        retailMsrpEur: evaluation.retailMsrpEur,
        uciHomologated: evaluation.uciLegal,
      );
    }).toList(growable: false);

    state = state.copyWith(
      model: state.model.copyWith(blueprints: updatedBlueprints),
    );
  }

  InHouseFrameBlueprint createNewBlueprint({
    required String modelName,
    required FrameCategory category,
    required CarbonLayupGrade carbonGrade,
    required FrameGeometryEvaluation evaluation,
  }) {
    final id = '${state.model.brandId}_custom_${state.model.blueprints.length + 1}';
    final meshPath = switch (category) {
      FrameCategory.aero => 'assets/3d/bikes/aero_pro_frame.glb',
      FrameCategory.timeTrial => 'assets/3d/bikes/tt_pro_frame.glb',
      _ => 'assets/3d/bikes/road_pro_frame.glb',
    };
    final created = InHouseFrameBlueprint(
      blueprintId: id,
      modelName: modelName,
      category: category,
      carbonGrade: carbonGrade,
      weightGrams: evaluation.estimatedWeightGrams,
      aeroCdaModifier: evaluation.aeroCdaModifier,
      stiffnessToWeightIndex: evaluation.stiffnessToWeightIndex,
      comfortCompliance: evaluation.comfortCompliance,
      unitManufacturingCostEur: evaluation.unitManufacturingCostEur,
      wholesalePriceEur: evaluation.wholesalePriceEur,
      retailMsrpEur: evaluation.retailMsrpEur,
      uciHomologated: evaluation.uciLegal,
      rdGeneration: 1,
      primaryColorHex: state.model.primaryColorHex,
      mesh3dAssetPath: meshPath,
    );
    state = state.copyWith(
      model: state.model.copyWith(
        blueprints: [...state.model.blueprints, created],
      ),
    );
    return created;
  }

  BrandOperationResult signLicenseOffer({
    required ExternalLicenseTeamOffer offer,
    required InHouseFrameBlueprint blueprint,
  }) {
    final contract = ExternalTeamLicenseContract(
      contractId: 'lic_${offer.teamId}_${state.currentSeasonYear}',
      partnerTeamId: offer.teamId,
      partnerTeamName: offer.teamName,
      targetDivision: offer.division,
      suppliedBlueprintId: blueprint.blueprintId,
      annualLicenseFeeEur: offer.annualLicenseFeeEur,
      framesOrderedPerSeason: offer.framesOrderedPerSeason,
      pricePerFrameEur: blueprint.wholesalePriceEur,
      royaltyPerWorldTourWinEur: offer.royaltyPerWorldTourWinEur,
      yearsRemaining: offer.contractYears,
      status: BrandLicenseDealStatus.active,
      satisfactionScore: 86.0,
    );

    final result = state.model.signLicenseContract(contract);
    if (result.success) {
      state = state.copyWith(
        model: result.model,
        availableOffers: state.availableOffers
            .where((o) => o.offerId != offer.offerId)
            .toList(growable: false),
      );
    }
    return result;
  }

  BrandOperationResult simulateQuarter({
    required int ownTeamFramesConsumed,
    required int partnerWorldTourWins,
  }) {
    final result = state.model.simulateQuarterFinancials(
      seasonYear: state.currentSeasonYear,
      quarter: state.currentQuarter,
      ownTeamFramesConsumed: ownTeamFramesConsumed,
      partnerWorldTourWins: partnerWorldTourWins,
    );
    if (result.success) {
      final nextQuarter = state.currentQuarter == 4 ? 1 : state.currentQuarter + 1;
      final nextYear =
          state.currentQuarter == 4 ? state.currentSeasonYear + 1 : state.currentSeasonYear;
      final updatedModel = nextQuarter == 1
          ? result.model.copyWith(framesProducedThisSeason: 0)
          : result.model;
      state = state.copyWith(
        model: updatedModel,
        teamCashEur: state.teamCashEur + result.cashDeltaEur,
        currentQuarter: nextQuarter,
        currentSeasonYear: nextYear,
      );
    }
    return result;
  }
}

final inHouseBikeBrandFactoryProvider = StateNotifierProvider<
    InHouseBikeBrandFactoryNotifier, InHouseBikeBrandFactoryState>(
  (ref) => InHouseBikeBrandFactoryNotifier(),
);

/// Ekran Fabryki i Działu R&D własnej marki rowerowej z projektowaniem geometrii
/// oraz analizą sprzedaży detalicznej i licencji B2B.
class InHouseBikeBrandFactoryScreen extends ConsumerStatefulWidget {
  const InHouseBikeBrandFactoryScreen({
    super.key,
    this.initialState,
    this.onStateChanged,
    this.showAppBar = true,
  });

  final InHouseBikeBrandFactoryState? initialState;
  final ValueChanged<InHouseBikeBrandFactoryState>? onStateChanged;
  final bool showAppBar;

  @override
  ConsumerState<InHouseBikeBrandFactoryScreen> createState() =>
      _InHouseBikeBrandFactoryScreenState();
}

class _InHouseBikeBrandFactoryScreenState
    extends ConsumerState<InHouseBikeBrandFactoryScreen> {
  InHouseBikeBrandFactoryState? _localState;
  BikeBrandFactoryTab _activeTab = BikeBrandFactoryTab.factoryAndRd;

  String? _selectedBlueprintId;
  FrameGeometrySpec _geometrySpec = const FrameGeometrySpec();
  FrameCategory _selectedCategory = FrameCategory.allRounder;
  CarbonLayupGrade _selectedCarbonGrade = CarbonLayupGrade.highModulusT800;

  RdProjectFocus _selectedRdFocus = RdProjectFocus.aeroTubeProfiles;
  int _selectedRdBudgetEur = 180000;

  int _quarterOwnFrames = 24;
  int _quarterPartnerWins = 2;

  String? _bannerMessage;
  bool _bannerIsError = false;

  bool get _usesLocalState => widget.initialState != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialState != null) {
      _localState = widget.initialState;
    }
    final InHouseBikeBrandFactoryState state =
        widget.initialState ?? ref.read(inHouseBikeBrandFactoryProvider);
    _syncSelectionFromModel(state.model);
  }

  @override
  void didUpdateWidget(covariant InHouseBikeBrandFactoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialState != null &&
        widget.initialState != oldWidget.initialState) {
      _localState = widget.initialState;
      _syncSelectionFromModel(widget.initialState!.model);
    }
  }

  void _syncSelectionFromModel(InHouseBikeBrandModel model) {
    if (model.blueprints.isNotEmpty) {
      final first = model.blueprints.first;
      _selectedBlueprintId ??= first.blueprintId;
      _selectedCategory = first.category;
      _selectedCarbonGrade = first.carbonGrade;
      _geometrySpec = FrameGeometrySpec.presetForCategory(first.category);
    }
  }

  InHouseBikeBrandFactoryState _currentState() {
    if (_usesLocalState) {
      return _localState!;
    }
    return ref.watch(inHouseBikeBrandFactoryProvider);
  }

  void _applyLocalState(InHouseBikeBrandFactoryState next) {
    setState(() {
      _localState = next;
    });
    widget.onStateChanged?.call(next);
  }

  void _setFeedback(String message, {bool isError = false}) {
    setState(() {
      _bannerMessage = message;
      _bannerIsError = isError;
    });
  }

  InHouseFrameBlueprint? _selectedBlueprint(InHouseBikeBrandModel model) {
    if (model.blueprints.isEmpty) return null;
    return model.blueprints.cast<InHouseFrameBlueprint?>().firstWhere(
          (b) => b?.blueprintId == _selectedBlueprintId,
          orElse: () => model.blueprints.first,
        );
  }

  void _onSelectBlueprint(InHouseFrameBlueprint bp) {
    setState(() {
      _selectedBlueprintId = bp.blueprintId;
      _selectedCategory = bp.category;
      _selectedCarbonGrade = bp.carbonGrade;
      _geometrySpec = FrameGeometrySpec.presetForCategory(bp.category);
    });
  }

  void _handleUpgradeFacility(ManufacturingFacilityTier nextTier) {
    final current = _currentState();
    if (_usesLocalState) {
      final result = current.model.upgradeFacility(
        nextTier: nextTier,
        availableTeamCashEur: current.teamCashEur,
      );
      if (result.success) {
        _applyLocalState(
          current.copyWith(
            model: result.model,
            teamCashEur: current.teamCashEur + result.cashDeltaEur,
          ),
        );
      }
      _setFeedback(result.message, isError: !result.success);
    } else {
      final result =
          ref.read(inHouseBikeBrandFactoryProvider.notifier).upgradeFacility(nextTier);
      if (result.success) {
        widget.onStateChanged?.call(ref.read(inHouseBikeBrandFactoryProvider));
      }
      _setFeedback(result.message, isError: !result.success);
    }
  }

  void _handleStartRdProject(InHouseFrameBlueprint blueprint) {
    final title = '${blueprint.modelName} — ${_selectedRdFocus.displayNamePl}';
    final current = _currentState();
    if (_usesLocalState) {
      final result = current.model.startRdProject(
        projectId: 'rd_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        targetBlueprintId: blueprint.blueprintId,
        focus: _selectedRdFocus,
        budgetEur: _selectedRdBudgetEur,
        availableTeamCashEur: current.teamCashEur,
      );
      if (result.success) {
        _applyLocalState(
          current.copyWith(
            model: result.model,
            teamCashEur: current.teamCashEur + result.cashDeltaEur,
          ),
        );
      }
      _setFeedback(result.message, isError: !result.success);
    } else {
      final result = ref
          .read(inHouseBikeBrandFactoryProvider.notifier)
          .startRdProject(
            title: title,
            targetBlueprintId: blueprint.blueprintId,
            focus: _selectedRdFocus,
            budgetEur: _selectedRdBudgetEur,
          );
      if (result.success) {
        widget.onStateChanged?.call(ref.read(inHouseBikeBrandFactoryProvider));
      }
      _setFeedback(result.message, isError: !result.success);
    }
  }

  void _handleAdvanceRdDays(int days) {
    final current = _currentState();
    if (_usesLocalState) {
      final updated = current.model.advanceRdProjects(days);
      _applyLocalState(current.copyWith(model: updated));
    } else {
      ref.read(inHouseBikeBrandFactoryProvider.notifier).advanceRdDays(days);
      widget.onStateChanged?.call(ref.read(inHouseBikeBrandFactoryProvider));
    }
    _setFeedback('Zasymulowano +$days dni prac laboratoryjnych i testów CFD.');
  }

  void _handleSaveGeometry(
    InHouseFrameBlueprint blueprint,
    FrameGeometryEvaluation evaluation,
  ) {
    final current = _currentState();
    if (_usesLocalState) {
      final updatedBlueprints = current.model.blueprints.map((bp) {
        if (bp.blueprintId != blueprint.blueprintId) return bp;
        return bp.copyWith(
          category: _selectedCategory,
          carbonGrade: _selectedCarbonGrade,
          weightGrams: evaluation.estimatedWeightGrams,
          aeroCdaModifier: evaluation.aeroCdaModifier,
          stiffnessToWeightIndex: evaluation.stiffnessToWeightIndex,
          comfortCompliance: evaluation.comfortCompliance,
          unitManufacturingCostEur: evaluation.unitManufacturingCostEur,
          wholesalePriceEur: evaluation.wholesalePriceEur,
          retailMsrpEur: evaluation.retailMsrpEur,
          uciHomologated: evaluation.uciLegal,
        );
      }).toList(growable: false);
      _applyLocalState(
        current.copyWith(
          model: current.model.copyWith(blueprints: updatedBlueprints),
        ),
      );
    } else {
      ref.read(inHouseBikeBrandFactoryProvider.notifier).saveBlueprintGeometry(
            blueprintId: blueprint.blueprintId,
            category: _selectedCategory,
            carbonGrade: _selectedCarbonGrade,
            evaluation: evaluation,
          );
      widget.onStateChanged?.call(ref.read(inHouseBikeBrandFactoryProvider));
    }
    _setFeedback(
      'Zapisano geometrię i specyfikację CAD dla modelu ${blueprint.modelName}.',
    );
  }

  void _handleCreateNewBlueprint(FrameGeometryEvaluation evaluation) {
    final current = _currentState();
    final idx = current.model.blueprints.length + 1;
    final name = '${current.model.brandName} Proto-R$idx';
    if (_usesLocalState) {
      final meshPath = switch (_selectedCategory) {
        FrameCategory.aero => 'assets/3d/bikes/aero_pro_frame.glb',
        FrameCategory.timeTrial => 'assets/3d/bikes/tt_pro_frame.glb',
        _ => 'assets/3d/bikes/road_pro_frame.glb',
      };
      final created = InHouseFrameBlueprint(
        blueprintId: '${current.model.brandId}_custom_$idx',
        modelName: name,
        category: _selectedCategory,
        carbonGrade: _selectedCarbonGrade,
        weightGrams: evaluation.estimatedWeightGrams,
        aeroCdaModifier: evaluation.aeroCdaModifier,
        stiffnessToWeightIndex: evaluation.stiffnessToWeightIndex,
        comfortCompliance: evaluation.comfortCompliance,
        unitManufacturingCostEur: evaluation.unitManufacturingCostEur,
        wholesalePriceEur: evaluation.wholesalePriceEur,
        retailMsrpEur: evaluation.retailMsrpEur,
        uciHomologated: evaluation.uciLegal,
        rdGeneration: 1,
        primaryColorHex: current.model.primaryColorHex,
        mesh3dAssetPath: meshPath,
      );
      _applyLocalState(
        current.copyWith(
          model: current.model.copyWith(
            blueprints: [...current.model.blueprints, created],
          ),
        ),
      );
      setState(() {
        _selectedBlueprintId = created.blueprintId;
      });
    } else {
      final created =
          ref.read(inHouseBikeBrandFactoryProvider.notifier).createNewBlueprint(
                modelName: name,
                category: _selectedCategory,
                carbonGrade: _selectedCarbonGrade,
                evaluation: evaluation,
              );
      widget.onStateChanged?.call(ref.read(inHouseBikeBrandFactoryProvider));
      setState(() {
        _selectedBlueprintId = created.blueprintId;
      });
    }
    _setFeedback('Utworzono nowy blueprint ramy: $name.');
  }

  void _handleSignLicense(
    ExternalLicenseTeamOffer offer,
    InHouseFrameBlueprint blueprint,
  ) {
    final current = _currentState();
    if (_usesLocalState) {
      final contract = ExternalTeamLicenseContract(
        contractId: 'lic_${offer.teamId}_${current.currentSeasonYear}',
        partnerTeamId: offer.teamId,
        partnerTeamName: offer.teamName,
        targetDivision: offer.division,
        suppliedBlueprintId: blueprint.blueprintId,
        annualLicenseFeeEur: offer.annualLicenseFeeEur,
        framesOrderedPerSeason: offer.framesOrderedPerSeason,
        pricePerFrameEur: blueprint.wholesalePriceEur,
        royaltyPerWorldTourWinEur: offer.royaltyPerWorldTourWinEur,
        yearsRemaining: offer.contractYears,
        status: BrandLicenseDealStatus.active,
        satisfactionScore: 86.0,
      );
      final result = current.model.signLicenseContract(contract);
      if (result.success) {
        _applyLocalState(
          current.copyWith(
            model: result.model,
            availableOffers: current.availableOffers
                .where((o) => o.offerId != offer.offerId)
                .toList(growable: false),
          ),
        );
      }
      _setFeedback(result.message, isError: !result.success);
    } else {
      final result = ref
          .read(inHouseBikeBrandFactoryProvider.notifier)
          .signLicenseOffer(offer: offer, blueprint: blueprint);
      if (result.success) {
        widget.onStateChanged?.call(ref.read(inHouseBikeBrandFactoryProvider));
      }
      _setFeedback(result.message, isError: !result.success);
    }
  }

  void _handleSimulateQuarter() {
    final current = _currentState();
    if (_usesLocalState) {
      final result = current.model.simulateQuarterFinancials(
        seasonYear: current.currentSeasonYear,
        quarter: current.currentQuarter,
        ownTeamFramesConsumed: _quarterOwnFrames,
        partnerWorldTourWins: _quarterPartnerWins,
      );
      if (result.success) {
        final nextQ = current.currentQuarter == 4 ? 1 : current.currentQuarter + 1;
        final nextYear =
            current.currentQuarter == 4 ? current.currentSeasonYear + 1 : current.currentSeasonYear;
        final updatedModel = nextQ == 1
            ? result.model.copyWith(framesProducedThisSeason: 0)
            : result.model;
        _applyLocalState(
          current.copyWith(
            model: updatedModel,
            teamCashEur: current.teamCashEur + result.cashDeltaEur,
            currentQuarter: nextQ,
            currentSeasonYear: nextYear,
          ),
        );
      }
      _setFeedback(result.message, isError: !result.success);
    } else {
      final result =
          ref.read(inHouseBikeBrandFactoryProvider.notifier).simulateQuarter(
                ownTeamFramesConsumed: _quarterOwnFrames,
                partnerWorldTourWins: _quarterPartnerWins,
              );
      if (result.success) {
        widget.onStateChanged?.call(ref.read(inHouseBikeBrandFactoryProvider));
      }
      _setFeedback(result.message, isError: !result.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _currentState();
    final model = state.model;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              title: Text(
                '${model.brandName} — Fabryka & R&D',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(
                        'Budżet: ${Formatters.formatCurrency(state.teamCashEur)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 680;
            final isDesktop = width >= 1150;
            final padding = isMobile ? 12.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandHeaderBanner(state, isMobile: isMobile),
                  if (_bannerMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildFeedbackBanner(),
                  ],
                  const SizedBox(height: 16),
                  _buildTabSelector(isMobile: isMobile),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_activeTab),
                      child: switch (_activeTab) {
                        BikeBrandFactoryTab.factoryAndRd => _buildFactoryAndRdTab(
                            state,
                            isMobile: isMobile,
                            isDesktop: isDesktop,
                          ),
                        BikeBrandFactoryTab.geometryStudio => _buildGeometryStudioTab(
                            state,
                            isMobile: isMobile,
                            isDesktop: isDesktop,
                          ),
                        BikeBrandFactoryTab.externalLicenses => _buildExternalLicensesTab(
                            state,
                            isMobile: isMobile,
                            isDesktop: isDesktop,
                          ),
                        BikeBrandFactoryTab.retailAnalytics => _buildRetailAnalyticsTab(
                            state,
                            isMobile: isMobile,
                            isDesktop: isDesktop,
                          ),
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandHeaderBanner(
    InHouseBikeBrandFactoryState state, {
    required bool isMobile,
  }) {
    final model = state.model;
    final capacityPct = model.annualProductionCapacityFrames > 0
        ? (model.framesProducedThisSeason / model.annualProductionCapacityFrames).clamp(0.0, 1.0)
        : 0.0;

    return _FactoryCard(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryAccent),
                    ),
                    child: const Icon(
                      Icons.pedal_bike_rounded,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.brandName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          '${model.brandTagline} • ${model.facilityTier.displayNamePl}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  'Q${state.currentQuarter}/${state.currentSeasonYear} • ★ ${model.prestigeStars}/5',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiMetricTile(
                label: 'Prestiż Marki',
                value: '${model.prestigeScore.toStringAsFixed(1)}/100',
                accentColor: AppColors.goldAccent,
              ),
              _KpiMetricTile(
                label: 'Poziom R&D',
                value: 'LVL ${model.rdEngineeringLevel}',
                accentColor: AppColors.accentBlue,
              ),
              _KpiMetricTile(
                label: 'Wartość Marki',
                value: Formatters.formatCompactCurrency(model.brandEquityValueEur),
                accentColor: AppColors.statusSuccess,
              ),
              _KpiMetricTile(
                label: 'Moce Produkcyjne',
                value:
                    '${model.framesProducedThisSeason}/${model.annualProductionCapacityFrames} (${(capacityPct * 100).round()}%)',
                accentColor: AppColors.cyanAccent,
              ),
              _KpiMetricTile(
                label: 'Popyt Detaliczny',
                value: '${model.retailConsumerDemandIndex.toStringAsFixed(2)}x',
                accentColor: AppColors.amberWarning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner() {
    final color = _bannerIsError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(
            _bannerIsError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _bannerMessage!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _bannerMessage = null),
            icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector({required bool isMobile}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BikeBrandFactoryTab.values.map((tab) {
        final isSelected = tab == _activeTab;
        return _InteractiveTabChip(
          label: tab.labelPl,
          icon: tab.icon,
          selected: isSelected,
          compact: isMobile,
          onTap: () => setState(() => _activeTab = tab),
        );
      }).toList(growable: false),
    );
  }

  // ===========================================================================
  // TAB 1: FABRYKA & DZIAŁ R&D
  // ===========================================================================

  Widget _buildFactoryAndRdTab(
    InHouseBikeBrandFactoryState state, {
    required bool isMobile,
    required bool isDesktop,
  }) {
    final facilityCard = _buildFacilityUpgradeCard(state);
    final rdLaunchCard = _buildRdLauncherCard(state);
    final rdProjectsCard = _buildActiveRdProjectsCard(state);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                facilityCard,
                const SizedBox(height: 16),
                rdLaunchCard,
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: rdProjectsCard,
          ),
        ],
      );
    }

    return Column(
      children: [
        facilityCard,
        const SizedBox(height: 16),
        rdLaunchCard,
        const SizedBox(height: 16),
        rdProjectsCard,
      ],
    );
  }

  Widget _buildFacilityUpgradeCard(InHouseBikeBrandFactoryState state) {
    final currentTier = state.model.facilityTier;
    final nextTierIndex = currentTier.index + 1;
    final hasNextTier = nextTierIndex < ManufacturingFacilityTier.values.length;
    final nextTier =
        hasNextTier ? ManufacturingFacilityTier.values[nextTierIndex] : null;
    final canAfford =
        nextTier != null && state.teamCashEur >= nextTier.upgradeCostEur;

    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Infrastruktura Produkcyjna',
            subtitle: 'Skalowanie mocy produkcyjnych, tunelu CFD i licencji B2B',
            icon: Icons.factory_rounded,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTier.displayNamePl,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _InlineStat(
                      label: 'Limit ram/rok',
                      value: '${currentTier.annualFrameCapacity} szt.',
                    ),
                    _InlineStat(
                      label: 'Sloty licencji',
                      value: '${currentTier.maxExternalLicenses}',
                    ),
                    _InlineStat(
                      label: 'Mnożnik retail',
                      value: '${currentTier.retailMultiplier.toStringAsFixed(2)}x',
                    ),
                    _InlineStat(
                      label: 'OPEX / kwartał',
                      value: Formatters.formatCurrency(currentTier.quarterlyFixedOpexEur),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (nextTier != null) ...[
            Text(
              'Następny poziom: ${nextTier.displayNamePl}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pojemność: ${nextTier.annualFrameCapacity} ram/rok • Sloty B2B: ${nextTier.maxExternalLicenses} • Retail: ${nextTier.retailMultiplier}x',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _FactoryActionButton(
              label:
                  'Rozbuduj Fabrykę (${Formatters.formatCurrency(nextTier.upgradeCostEur)})',
              icon: Icons.upgrade_rounded,
              enabled: canAfford,
              primary: true,
              onPressed: () => _handleUpgradeFacility(nextTier),
            ),
          ] else
            const Text(
              'Osiągnięto maksymalny poziom Global OEM Powerhouse.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.statusSuccess,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRdLauncherCard(InHouseBikeBrandFactoryState state) {
    final blueprint = _selectedBlueprint(state.model);
    final canStart =
        blueprint != null && state.teamCashEur >= _selectedRdBudgetEur;

    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Nowy Projekt Badawczy R&D',
            subtitle: 'Ulepszaj aerodynamikę, masę laminatu lub sztywność suportu',
            icon: Icons.science_rounded,
          ),
          const SizedBox(height: 14),
          if (blueprint == null)
            const Text(
              'Brak dostępnych blueprintów ram.',
              style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
            )
          else ...[
            const Text(
              'Docelowy model ramy',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.model.blueprints.map((bp) {
                final selected = bp.blueprintId == blueprint.blueprintId;
                return _SelectableOptionChip(
                  label: '${bp.modelName} (Gen ${bp.rdGeneration})',
                  selected: selected,
                  onTap: () => _onSelectBlueprint(bp),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 14),
            const Text(
              'Kierunek R&D',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RdProjectFocus.values.map((focus) {
                return _SelectableOptionChip(
                  label: focus.displayNamePl,
                  selected: _selectedRdFocus == focus,
                  onTap: () => setState(() => _selectedRdFocus = focus),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Budżet projektu R&D',
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
                  Formatters.formatCurrency(_selectedRdBudgetEur),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Slider(
              value: _selectedRdBudgetEur.toDouble(),
              min: 90000,
              max: 450000,
              divisions: 12,
              activeColor: AppColors.goldAccent,
              inactiveColor: AppColors.surfaceLight,
              onChanged: (v) => setState(() => _selectedRdBudgetEur = v.round()),
            ),
            const SizedBox(height: 8),
            _FactoryActionButton(
              label: 'Uruchom Projekt R&D',
              icon: Icons.rocket_launch_rounded,
              enabled: canStart,
              primary: true,
              onPressed: () => _handleStartRdProject(blueprint),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveRdProjectsCard(InHouseBikeBrandFactoryState state) {
    final projects = state.model.activeRdProjects;
    final hasInProgress =
        projects.any((p) => !p.isCompleted && p.status != RdProjectStatus.cancelled);

    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _SectionHeader(
                title: 'Aktywne Projekty R&D',
                subtitle: 'Postęp prac inżynieryjnych i walidacji w tunelu CFD',
                icon: Icons.engineering_rounded,
              ),
              _FactoryActionButton(
                label: '+15 dni R&D',
                icon: Icons.fast_forward_rounded,
                enabled: hasInProgress,
                primary: false,
                compact: true,
                onPressed: () => _handleAdvanceRdDays(15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (projects.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Text(
                'Brak aktywnych projektów R&D. Uruchom nowy program rozwojowy po lewej stronie, aby obniżyć masę lub poprawić współczynnik CdA ramy.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: projects.map((project) {
                final pct = (project.progressRatio * 100).round();
                final statusColor = project.isCompleted
                    ? AppColors.statusSuccess
                    : (project.status == RdProjectStatus.windTunnelValidation
                        ? AppColors.goldAccent
                        : AppColors.accentBlue);
                final statusLabel = project.isCompleted
                    ? 'HOMOLOGOWANY'
                    : (project.status == RdProjectStatus.windTunnelValidation
                        ? 'WALIDACJA CFD'
                        : 'W TOKU');

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: project.progressRatio.clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _InlineStat(label: 'Postęp', value: '$pct%'),
                          _InlineStat(
                            label: 'Pozostało',
                            value: '${project.estimatedDaysRemaining} dni',
                          ),
                          _InlineStat(
                            label: 'Δ Masa',
                            value: '${project.expectedWeightDeltaGrams} g',
                          ),
                          _InlineStat(
                            label: 'Δ CdA',
                            value: project.expectedCdaDelta.toStringAsFixed(4),
                          ),
                          _InlineStat(
                            label: 'Δ Sztywność',
                            value: '+${project.expectedStiffnessDelta.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: STUDIO GEOMETRII & BLUEPRINTY
  // ===========================================================================

  Widget _buildGeometryStudioTab(
    InHouseBikeBrandFactoryState state, {
    required bool isMobile,
    required bool isDesktop,
  }) {
    final blueprint = _selectedBlueprint(state.model);
    final evaluation = FrameGeometryCalculator.evaluate(
      spec: _geometrySpec,
      category: _selectedCategory,
      carbonGrade: _selectedCarbonGrade,
      rdEngineeringLevel: state.model.rdEngineeringLevel,
    );

    final cadCanvasCard = _buildGeometryCadCard(
      state,
      blueprint: blueprint,
      evaluation: evaluation,
      isMobile: isMobile,
    );
    final controlsCard = _buildGeometryControlsCard(
      state,
      blueprint: blueprint,
      evaluation: evaluation,
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: cadCanvasCard),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: controlsCard),
        ],
      );
    }

    return Column(
      children: [
        cadCanvasCard,
        const SizedBox(height: 16),
        controlsCard,
      ],
    );
  }

  Widget _buildGeometryCadCard(
    InHouseBikeBrandFactoryState state, {
    required InHouseFrameBlueprint? blueprint,
    required FrameGeometryEvaluation evaluation,
    required bool isMobile,
  }) {
    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Rysunek Techniczny CAD 2D',
            subtitle: blueprint != null
                ? 'Model: ${blueprint.modelName} • Generacja R&D ${blueprint.rdGeneration}'
                : 'Projektowanie nowej geometrii ramy',
            icon: Icons.architecture_rounded,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.model.blueprints.map((bp) {
              return _SelectableOptionChip(
                label: bp.modelName,
                selected: bp.blueprintId == blueprint?.blueprintId,
                onTap: () => _onSelectBlueprint(bp),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: isMobile ? 250 : 320,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: FrameGeometryBlueprintPainter(
                  spec: _geometrySpec,
                  evaluation: evaluation,
                  category: _selectedCategory,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _KpiMetricTile(
                label: 'Masa Ramy',
                value: '${evaluation.estimatedWeightGrams} g',
                accentColor: AppColors.cyanAccent,
              ),
              _KpiMetricTile(
                label: 'Aero CdA',
                value: evaluation.aeroCdaModifier.toStringAsFixed(4),
                accentColor: AppColors.accentBlue,
              ),
              _KpiMetricTile(
                label: 'Sztywność/Masa',
                value: '${evaluation.stiffnessToWeightIndex.toStringAsFixed(2)} idx',
                accentColor: AppColors.goldAccent,
              ),
              _KpiMetricTile(
                label: 'Stack / Reach',
                value: _geometrySpec.stackToReachRatio.toStringAsFixed(2),
                accentColor: AppColors.textPrimary,
              ),
              _KpiMetricTile(
                label: 'Trail Widelca',
                value: '${evaluation.forkTrailMm} mm',
                accentColor: AppColors.amberWarning,
              ),
              _KpiMetricTile(
                label: 'Homologacja UCI',
                value: evaluation.uciLegal ? 'ZGODNA' : 'POZA LIMITEM',
                accentColor: evaluation.uciLegal
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Charakterystyka prowadzenia: ${evaluation.handlingVerdictPl}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeometryControlsCard(
    InHouseBikeBrandFactoryState state, {
    required InHouseFrameBlueprint? blueprint,
    required FrameGeometryEvaluation evaluation,
  }) {
    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Parametry Geometrii & Laminatu',
            subtitle: 'Korekta wymiarów w czasie rzeczywistym',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 12),
          const Text(
            'Kategoria Ramy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FrameCategory.values.map((cat) {
              return _SelectableOptionChip(
                label: _frameCategoryLabel(cat),
                selected: _selectedCategory == cat,
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _geometrySpec = FrameGeometrySpec.presetForCategory(cat);
                  });
                },
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 14),
          const Text(
            'Laminat Włókna Węglowego',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CarbonLayupGrade.values.map((grade) {
              return _SelectableOptionChip(
                label: grade.displayNamePl,
                selected: _selectedCarbonGrade == grade,
                onTap: () => setState(() => _selectedCarbonGrade = grade),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 14),
          _GeometrySliderRow(
            label: 'Stack',
            valueText: '${_geometrySpec.stackMm.round()} mm',
            value: _geometrySpec.stackMm,
            min: 500,
            max: 605,
            onChanged: (v) => setState(
              () => _geometrySpec = _geometrySpec.copyWith(stackMm: v),
            ),
          ),
          _GeometrySliderRow(
            label: 'Reach',
            valueText: '${_geometrySpec.reachMm.round()} mm',
            value: _geometrySpec.reachMm,
            min: 365,
            max: 425,
            onChanged: (v) => setState(
              () => _geometrySpec = _geometrySpec.copyWith(reachMm: v),
            ),
          ),
          _GeometrySliderRow(
            label: 'Kąt główki (HTA)',
            valueText: '${_geometrySpec.headTubeAngleDeg.toStringAsFixed(1)}°',
            value: _geometrySpec.headTubeAngleDeg,
            min: 70.5,
            max: 74.5,
            onChanged: (v) => setState(
              () => _geometrySpec = _geometrySpec.copyWith(headTubeAngleDeg: v),
            ),
          ),
          _GeometrySliderRow(
            label: 'Kąt rury podsiodłowej (STA)',
            valueText: '${_geometrySpec.seatTubeAngleDeg.toStringAsFixed(1)}°',
            value: _geometrySpec.seatTubeAngleDeg,
            min: 72.0,
            max: 76.5,
            onChanged: (v) => setState(
              () => _geometrySpec = _geometrySpec.copyWith(seatTubeAngleDeg: v),
            ),
          ),
          _GeometrySliderRow(
            label: 'Tylne widełki (Chainstay)',
            valueText: '${_geometrySpec.chainstayMm.round()} mm',
            value: _geometrySpec.chainstayMm,
            min: 400,
            max: 428,
            onChanged: (v) => setState(
              () => _geometrySpec = _geometrySpec.copyWith(chainstayMm: v),
            ),
          ),
          _GeometrySliderRow(
            label: 'Baza kół (Wheelbase)',
            valueText: '${_geometrySpec.wheelbaseMm.round()} mm',
            value: _geometrySpec.wheelbaseMm,
            min: 965,
            max: 1035,
            onChanged: (v) => setState(
              () => _geometrySpec = _geometrySpec.copyWith(wheelbaseMm: v),
            ),
          ),
          const Divider(color: AppTheme.borderColor, height: 22),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _InlineStat(
                label: 'Koszt prod.',
                value: Formatters.formatCurrency(evaluation.unitManufacturingCostEur),
              ),
              _InlineStat(
                label: 'Hurt B2B',
                value: Formatters.formatCurrency(evaluation.wholesalePriceEur),
              ),
              _InlineStat(
                label: 'Detal MSRP',
                value: Formatters.formatCurrency(evaluation.retailMsrpEur),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (blueprint != null)
                _FactoryActionButton(
                  label: 'Zapisz do ${blueprint.modelName}',
                  icon: Icons.save_rounded,
                  enabled: true,
                  primary: true,
                  onPressed: () => _handleSaveGeometry(blueprint, evaluation),
                ),
              _FactoryActionButton(
                label: 'Nowy Model Ramy',
                icon: Icons.add_circle_outline_rounded,
                enabled: true,
                primary: false,
                onPressed: () => _handleCreateNewBlueprint(evaluation),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: LICENCJE ZEWNĘTRZNE B2B
  // ===========================================================================

  Widget _buildExternalLicensesTab(
    InHouseBikeBrandFactoryState state, {
    required bool isMobile,
    required bool isDesktop,
  }) {
    final activeContractsCard = _buildActiveContractsCard(state);
    final marketOffersCard = _buildLicenseOffersCard(state);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: activeContractsCard),
          const SizedBox(width: 16),
          Expanded(child: marketOffersCard),
        ],
      );
    }

    return Column(
      children: [
        activeContractsCard,
        const SizedBox(height: 16),
        marketOffersCard,
      ],
    );
  }

  Widget _buildActiveContractsCard(InHouseBikeBrandFactoryState state) {
    final model = state.model;
    final active = model.activeLicenseContracts;

    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Aktywne Kontrakty Licencyjne',
            subtitle:
                'Sloty: ${active.length}/${model.facilityTier.maxExternalLicenses} • Przychód roczny: ${Formatters.formatCurrency(model.contractedAnnualLicenseRevenueEur)}',
            icon: Icons.verified_rounded,
          ),
          const SizedBox(height: 14),
          if (active.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Text(
                'Brak podpisanych licencji z innymi drużynami. Wybierz ofertę partnerską, aby generować stały przychód z opłat licencyjnych i dostaw ram.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: active.map((deal) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              deal.partnerTeamName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${Formatters.formatCurrency(deal.totalAnnualRevenueEur)}/rok',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusSuccess,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _InlineStat(
                            label: 'Dywizja',
                            value: deal.targetDivision.displayNamePl,
                          ),
                          _InlineStat(
                            label: 'Zamówienie',
                            value: '${deal.framesOrderedPerSeason} ram',
                          ),
                          _InlineStat(
                            label: 'Premia WT',
                            value: Formatters.formatCurrency(deal.royaltyPerWorldTourWinEur),
                          ),
                          _InlineStat(
                            label: 'Lata',
                            value: '${deal.yearsRemaining} sez.',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _buildLicenseOffersCard(InHouseBikeBrandFactoryState state) {
    final model = state.model;
    final homologated = model.homologatedBlueprints;
    final selectedBp = homologated.isNotEmpty
        ? homologated.firstWhere(
            (b) => b.blueprintId == _selectedBlueprintId,
            orElse: () => homologated.first,
          )
        : null;

    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Zapytania Ofertowe Drużyn',
            subtitle: 'Podpisuj kontrakty na dostawy homologowanych ram UCI',
            icon: Icons.handshake_rounded,
          ),
          const SizedBox(height: 12),
          if (selectedBp != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: homologated.map((bp) {
                return _SelectableOptionChip(
                  label: '${bp.modelName} (${Formatters.formatCurrency(bp.wholesalePriceEur)})',
                  selected: bp.blueprintId == selectedBp.blueprintId,
                  onTap: () => _onSelectBlueprint(bp),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 14),
          ],
          if (state.availableOffers.isEmpty)
            const Text(
              'Wszystkie bieżące oferty partnerskie zostały już zakontraktowane.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: state.availableOffers.map((offer) {
                final hasSlot = model.availableLicenseSlots > 0;
                final hasCap =
                    offer.framesOrderedPerSeason <= model.remainingProductionCapacity;
                final canSign = selectedBp != null && hasSlot && hasCap;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.teamName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            offer.division.displayNamePl,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _InlineStat(
                            label: 'Licencja/rok',
                            value: Formatters.formatCurrency(offer.annualLicenseFeeEur),
                          ),
                          _InlineStat(
                            label: 'Wolumen',
                            value: '${offer.framesOrderedPerSeason} ram',
                          ),
                          _InlineStat(
                            label: 'Bonus za wygraną',
                            value: Formatters.formatCurrency(offer.royaltyPerWorldTourWinEur),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _FactoryActionButton(
                        label: hasSlot
                            ? (hasCap
                                ? 'Podpisz Kontrakt (${offer.contractYears} lata)'
                                : 'Za mała moc produkcyjna')
                            : 'Brak wolnych slotów fabryki',
                        icon: Icons.edit_document,
                        enabled: canSign,
                        primary: true,
                        compact: true,
                        onPressed: selectedBp == null
                            ? null
                            : () => _handleSignLicense(offer, selectedBp),
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: ANALIZA SPRZEDAŻY DETALICZNEJ I FINANSE
  // ===========================================================================

  Widget _buildRetailAnalyticsTab(
    InHouseBikeBrandFactoryState state, {
    required bool isMobile,
    required bool isDesktop,
  }) {
    final simulationCard = _buildQuarterSimulationCard(state);
    final chartCard = _buildRetailChartCard(state, isMobile: isMobile);
    final reportsCard = _buildQuarterlyReportsCard(state);

    if (isDesktop) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: simulationCard),
              const SizedBox(width: 16),
              Expanded(flex: 6, child: chartCard),
            ],
          ),
          const SizedBox(height: 16),
          reportsCard,
        ],
      );
    }

    return Column(
      children: [
        simulationCard,
        const SizedBox(height: 16),
        chartCard,
        const SizedBox(height: 16),
        reportsCard,
      ],
    );
  }

  Widget _buildQuarterSimulationCard(InHouseBikeBrandFactoryState state) {
    final model = state.model;
    final avgMsrp = model.blueprints.isEmpty
        ? 5500
        : (model.blueprints.fold<int>(0, (s, b) => s + b.retailMsrpEur) /
                model.blueprints.length)
            .round();
    final avgMargin = model.blueprints.isEmpty
        ? 4000
        : (model.blueprints.fold<int>(0, (s, b) => s + b.retailGrossMarginEur) /
                model.blueprints.length)
            .round();

    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Symulacja Sprzedaży Q${state.currentQuarter}/${state.currentSeasonYear}',
            subtitle: 'Analiza popytu detalicznego (D2C) i zamknięcie kwartału',
            icon: Icons.storefront_rounded,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _KpiMetricTile(
                label: 'Średnie MSRP',
                value: Formatters.formatCurrency(avgMsrp),
                accentColor: AppColors.textPrimary,
              ),
              _KpiMetricTile(
                label: 'Marża Detaliczna',
                value: Formatters.formatCurrency(avgMargin),
                accentColor: AppColors.statusSuccess,
              ),
              _KpiMetricTile(
                label: 'Mnożnik Retail',
                value: '${model.facilityTier.retailMultiplier.toStringAsFixed(2)}x',
                accentColor: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GeometrySliderRow(
            label: 'Ramy zużyte przez własny zespół',
            valueText: '$_quarterOwnFrames szt.',
            value: _quarterOwnFrames.toDouble(),
            min: 10,
            max: 60,
            onChanged: (v) => setState(() => _quarterOwnFrames = v.round()),
          ),
          _GeometrySliderRow(
            label: 'Zwycięstwa WT ekip partnerskich',
            valueText: '$_quarterPartnerWins wygr.',
            value: _quarterPartnerWins.toDouble(),
            min: 0,
            max: 12,
            onChanged: (v) => setState(() => _quarterPartnerWins = v.round()),
          ),
          const SizedBox(height: 10),
          _FactoryActionButton(
            label: 'Zamknij Kwartał Q${state.currentQuarter} i Rozlicz Sprzedaż',
            icon: Icons.calculate_rounded,
            enabled: true,
            primary: true,
            onPressed: _handleSimulateQuarter,
          ),
        ],
      ),
    );
  }

  Widget _buildRetailChartCard(
    InHouseBikeBrandFactoryState state, {
    required bool isMobile,
  }) {
    final reports = state.model.quarterlyReports;
    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Przychody Detaliczne vs B2B i Zysk Netto',
            subtitle: 'Porównanie kanałów sprzedaży w kolejnych kwartałach',
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: isMobile ? 210 : 250,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: reports.isEmpty
                ? const Center(
                    child: Text(
                      'Zamknij pierwszy kwartał, aby zobaczyć wykres sprzedaży.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: RetailSalesAnalyticsChartPainter(reports: reports),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(label: 'Sprzedaż Detaliczna', color: AppColors.goldAccent),
              _LegendDot(label: 'Licencje & B2B', color: AppColors.accentBlue),
              _LegendDot(label: 'Zysk Netto', color: AppColors.statusSuccess),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterlyReportsCard(InHouseBikeBrandFactoryState state) {
    final reports = state.model.quarterlyReports.reversed.toList(growable: false);
    return _FactoryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Historia Raportów Kwartalnych',
            subtitle: 'Wolumen produkcji, sprzedaż detaliczna i wynik finansowy',
            icon: Icons.receipt_long_rounded,
          ),
          const SizedBox(height: 12),
          if (reports.isEmpty)
            const Text(
              'Brak wygenerowanych raportów kwartalnych.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: reports.map((r) {
                final profitColor =
                    r.netProfitEur >= 0 ? AppColors.statusSuccess : AppColors.crimsonAlert;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Q${r.quarter} / ${r.seasonYear}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Netto: ${Formatters.formatCurrency(r.netProfitEur)}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: profitColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _InlineStat(label: 'Produkcja', value: '${r.framesProduced} szt.'),
                          _InlineStat(label: 'B2B', value: '${r.framesSoldToTeams} szt.'),
                          _InlineStat(label: 'Detal', value: '${r.framesSoldRetail} szt.'),
                          _InlineStat(
                            label: 'Przychód Detal',
                            value: Formatters.formatCompactCurrency(r.retailRevenueEur),
                          ),
                          _InlineStat(
                            label: 'Przychód B2B',
                            value: Formatters.formatCompactCurrency(
                              r.licenseRevenueEur + r.frameSalesRevenueEur,
                            ),
                          ),
                          _InlineStat(
                            label: 'Koszty',
                            value: Formatters.formatCompactCurrency(r.totalCostsEur),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }

  String _frameCategoryLabel(FrameCategory category) {
    switch (category) {
      case FrameCategory.aero:
        return 'Aero Race';
      case FrameCategory.lightweightClimbing:
        return 'Ultralekka Górska';
      case FrameCategory.allRounder:
        return 'All-Rounder';
      case FrameCategory.cobbleEndurance:
        return 'Bruk / Endurance';
      case FrameCategory.timeTrial:
        return 'Czasówka TT';
    }
  }
}

// =============================================================================
// CUSTOM PAINTERS: CAD GEOMETRY BLUEPRINT & RETAIL ANALYTICS CHART
// =============================================================================

/// Rysownik technicznego schematu geometrii ramy CAD 2D na siatce inżynieryjnej.
class FrameGeometryBlueprintPainter extends CustomPainter {
  final FrameGeometrySpec spec;
  final FrameGeometryEvaluation evaluation;
  final FrameCategory category;

  const FrameGeometryBlueprintPainter({
    required this.spec,
    required this.evaluation,
    required this.category,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.45)
      ..strokeWidth = 0.8;

    const gridStep = 24.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final scale = math.min(size.width / 1500.0, size.height / 900.0) * 1.05;
    final groundY = size.height * 0.80;
    final centerX = size.width * 0.48;

    final wheelRadius = 340.0 * scale;
    final bbDrop = spec.bbDropMm * scale;
    final rearCenter = spec.chainstayMm * scale;
    final wheelbase = spec.wheelbaseMm * scale;

    final rearAxle = Offset(centerX - wheelbase * 0.46, groundY - wheelRadius);
    final frontAxle = Offset(rearAxle.dx + wheelbase, rearAxle.dy);
    final bb = Offset(
      rearAxle.dx + math.sqrt(math.max(100.0, rearCenter * rearCenter - bbDrop * bbDrop)),
      rearAxle.dy + bbDrop,
    );

    final headTop = Offset(
      bb.dx + spec.reachMm * scale,
      bb.dy - spec.stackMm * scale,
    );
    final seatAngleRad = spec.seatTubeAngleDeg * math.pi / 180.0;
    final seatTopY = headTop.dy + (category == FrameCategory.timeTrial ? 10 * scale : 24 * scale);
    final seatTubeDx = (bb.dy - seatTopY) / math.tan(seatAngleRad);
    final seatTop = Offset(bb.dx - seatTubeDx, seatTopY);

    final headAngleRad = spec.headTubeAngleDeg * math.pi / 180.0;
    final headTubeLen = (135.0 * scale).clamp(18.0, 72.0);
    final headBottom = Offset(
      headTop.dx + headTubeLen * math.cos(headAngleRad),
      headTop.dy + headTubeLen * math.sin(headAngleRad),
    );

    // Koła
    final wheelPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(rearAxle, wheelRadius, wheelPaint);
    canvas.drawCircle(frontAxle, wheelRadius, wheelPaint);

    // Linia podłoża
    canvas.drawLine(
      Offset(16, groundY),
      Offset(size.width - 16, groundY),
      Paint()
        ..color = AppTheme.borderColor
        ..strokeWidth = 1.2,
    );

    // Rury ramy
    final framePaint = Paint()
      ..color = evaluation.uciLegal ? AppColors.goldAccent : AppColors.crimsonAlert
      ..style = PaintingStyle.stroke
      ..strokeWidth = category == FrameCategory.aero || category == FrameCategory.timeTrial
          ? 4.6
          : 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final forkPaint = Paint()
      ..color = AppColors.primaryAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    // Trójkąt przedni i tylny
    canvas.drawLine(bb, seatTop, framePaint);
    canvas.drawLine(seatTop, headTop, framePaint);
    canvas.drawLine(headTop, headBottom, framePaint);
    canvas.drawLine(headBottom, bb, framePaint);
    canvas.drawLine(bb, rearAxle, framePaint);
    canvas.drawLine(seatTop, rearAxle, framePaint);
    canvas.drawLine(headBottom, frontAxle, forkPaint);

    // Linie wymiarowe Stack & Reach
    final dimPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.75)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(bb.dx, bb.dy), Offset(bb.dx, headTop.dy), dimPaint);
    canvas.drawLine(Offset(bb.dx, headTop.dy), headTop, dimPaint);

    _drawLabel(
      canvas,
      'STACK ${spec.stackMm.round()}',
      Offset(bb.dx - 76, (bb.dy + headTop.dy) / 2 - 8),
      AppColors.accentBlue,
    );
    _drawLabel(
      canvas,
      'REACH ${spec.reachMm.round()}',
      Offset((bb.dx + headTop.dx) / 2 - 30, headTop.dy - 18),
      AppColors.accentBlue,
    );
    _drawLabel(
      canvas,
      'WB ${spec.wheelbaseMm.round()} mm',
      Offset((rearAxle.dx + frontAxle.dx) / 2 - 36, groundY + 6),
      AppColors.textSecondary,
    );
    _drawLabel(
      canvas,
      'HTA ${spec.headTubeAngleDeg.toStringAsFixed(1)}°',
      Offset(headBottom.dx + 10, headBottom.dy - 8),
      AppColors.goldAccent,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant FrameGeometryBlueprintPainter oldDelegate) {
    return oldDelegate.spec != spec ||
        oldDelegate.evaluation != evaluation ||
        oldDelegate.category != category;
  }
}

/// Wykres słupkowy sprzedaży detalicznej vs B2B oraz zysku netto.
class RetailSalesAnalyticsChartPainter extends CustomPainter {
  final List<BrandManufacturingQuarterlyReport> reports;

  const RetailSalesAnalyticsChartPainter({required this.reports});

  @override
  void paint(Canvas canvas, Size size) {
    if (reports.isEmpty) return;

    final visible = reports.length > 6 ? reports.sublist(reports.length - 6) : reports;
    int maxVal = 100000;
    for (final r in visible) {
      final b2b = r.licenseRevenueEur + r.frameSalesRevenueEur;
      maxVal = math.max(maxVal, math.max(r.retailRevenueEur, math.max(b2b, r.netProfitEur.abs())));
    }

    final chartBottom = size.height - 24;
    const chartTop = 14.0;
    final chartHeight = math.max(20.0, chartBottom - chartTop);
    final groupWidth = size.width / visible.length;
    final barWidth = (groupWidth * 0.22).clamp(8.0, 22.0);

    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 3; i++) {
      final y = chartTop + (chartHeight * i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i < visible.length; i++) {
      final r = visible[i];
      final center = groupWidth * i + groupWidth / 2;
      final b2b = r.licenseRevenueEur + r.frameSalesRevenueEur;

      _drawBar(
        canvas,
        x: center - barWidth * 1.4,
        width: barWidth,
        bottom: chartBottom,
        height: (r.retailRevenueEur / maxVal) * chartHeight,
        color: AppColors.goldAccent,
      );
      _drawBar(
        canvas,
        x: center - barWidth * 0.3,
        width: barWidth,
        bottom: chartBottom,
        height: (b2b / maxVal) * chartHeight,
        color: AppColors.accentBlue,
      );
      _drawBar(
        canvas,
        x: center + barWidth * 0.8,
        width: barWidth,
        bottom: chartBottom,
        height: (math.max(0, r.netProfitEur) / maxVal) * chartHeight,
        color: AppColors.statusSuccess,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: 'Q${r.quarter}/${r.seasonYear % 100}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center - tp.width / 2, chartBottom + 6));
    }
  }

  void _drawBar(
    Canvas canvas, {
    required double x,
    required double width,
    required double bottom,
    required double height,
    required Color color,
  }) {
    final clampedH = height.clamp(2.0, bottom);
    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(x, bottom - clampedH, width, clampedH),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant RetailSalesAnalyticsChartPainter oldDelegate) {
    return oldDelegate.reports != reports;
  }
}

// =============================================================================
// REUSABLE UI COMPONENTS (AppColors, Inter, BorderRadius 16, Full States)
// =============================================================================

class _FactoryCard extends StatelessWidget {
  const _FactoryCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.goldAccent, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
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
      ],
    );
  }
}

class _KpiMetricTile extends StatelessWidget {
  const _KpiMetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
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
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GeometrySliderRow extends StatelessWidget {
  const _GeometrySliderRow({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueText,
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppColors.accentBlue,
            inactiveColor: AppColors.surfaceLight,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _InteractiveTabChip extends StatefulWidget {
  const _InteractiveTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_InteractiveTabChip> createState() => _InteractiveTabChipState();
}

class _InteractiveTabChipState extends State<_InteractiveTabChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered ? AppColors.surfaceLight : AppColors.surface));
    final border = widget.selected
        ? AppColors.goldAccent
        : (_focused ? AppColors.accentBlue : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: widget.selected || _focused ? 1.4 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.selected ? AppColors.goldAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                  color: widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableOptionChip extends StatefulWidget {
  const _SelectableOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SelectableOptionChip> createState() => _SelectableOptionChipState();
}

class _SelectableOptionChipState extends State<_SelectableOptionChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.35)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final border = widget.selected
        ? AppColors.goldAccent
        : (_focused ? AppColors.accentBlue : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FactoryActionButton extends StatefulWidget {
  const _FactoryActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final bool primary;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  State<_FactoryActionButton> createState() => _FactoryActionButtonState();
}

class _FactoryActionButtonState extends State<_FactoryActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onPressed != null;
    final Color bg;
    if (!active) {
      bg = AppColors.surfaceLight.withValues(alpha: 0.45);
    } else if (widget.primary) {
      bg = _pressed
          ? AppColors.primaryAccent.withValues(alpha: 0.85)
          : (_hovered ? AppColors.primaryAccent : AppColors.primaryAccent.withValues(alpha: 0.9));
    } else {
      bg = _pressed
          ? AppColors.surfaceLight
          : (_hovered ? AppColors.surfaceLight : AppColors.background);
    }

    final border = !active
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.accentBlue
            : (widget.primary ? AppColors.goldAccent.withValues(alpha: 0.7) : AppTheme.borderColor));

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 16,
            vertical: widget.compact ? 8 : 11,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: !active
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : (widget.primary ? AppColors.goldAccent : AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: !active
                        ? AppColors.textSecondary.withValues(alpha: 0.55)
                        : AppColors.textPrimary,
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
