import 'dart:math' as math;

/// 5 kategorii nawierzchni szutrowych dla wyścigów UCI Gravel World Series & Ultra-Gravel.
enum GravelSurfaceCategory {
  /// Cat 1: Gładki, ubity szuter typu "champagne gravel" / białe drogi (Strade Bianche).
  cat1ChampagneGravel,

  /// Cat 2: Ubita droga leśna / pożarówka z drobnym kruszywem.
  cat2CompactedForestRoad,

  /// Cat 3: Luźny żwir, "tarka" (washboard) i głębsze koleiny.
  cat3LooseWashboardsAndRuts,

  /// Cat 4: Ostry krzemień (np. Kansas Flint Hills), gruby tłuczeń i kamienie.
  cat4SharpFlintAndChunkyRock,

  /// Cat 5: Techniczny singletrack, korzenie, głębokie błoto i brody wodne.
  cat5TechnicalSingletrackAndMud;

  String toJson() => name;

  static GravelSurfaceCategory fromJson(String value) {
    return GravelSurfaceCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GravelSurfaceCategory.cat2CompactedForestRoad,
    );
  }

  /// Numer kategorii nawierzchni (1–5).
  int get categoryNumber {
    switch (this) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 1;
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 2;
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 3;
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 4;
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 5;
    }
  }

  /// Polska nazwa kategorii nawierzchni.
  String get displayNamePl {
    switch (this) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 'Kat. 1 — Gładki szuter (Champagne Gravel)';
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 'Kat. 2 — Ubita droga leśna';
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 'Kat. 3 — Luźny żwir i tarka';
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 'Kat. 4 — Ostry krzemień i tłuczeń';
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 'Kat. 5 — Techniczny singletrack i błoto';
    }
  }

  /// Angielska nazwa kategorii nawierzchni.
  String get displayNameEn {
    switch (this) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 'Cat 1 — Champagne Gravel';
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 'Cat 2 — Compacted Forest Road';
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 'Cat 3 — Loose Gravel & Washboard';
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 'Cat 4 — Sharp Flint & Chunky Rock';
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 'Cat 5 — Technical Singletrack & Mud';
    }
  }

  /// Mnożnik oporu toczenia CRR względem gładkiego asfaltu (1.0).
  double get crrMultiplier {
    switch (this) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 1.18;
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 1.35;
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 1.62;
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 1.88;
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 2.30;
    }
  }

  /// Bazowy mnożnik ryzyka przebicia opony.
  double get punctureRiskFactor {
    switch (this) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 0.45;
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 0.75;
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 1.15;
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 1.85;
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 1.45;
    }
  }

  /// Mnożnik ryzyka rozcięcia ścianki bocznej opony (wymaga dętki zapasowej).
  double get sidewallCutRiskMultiplier {
    switch (this) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 0.20;
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 0.45;
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 0.85;
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 2.10;
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 1.30;
    }
  }

  /// Zalecana minimalna szerokość opony [mm].
  double get recommendedMinTireWidthMm {
    switch (this) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 35.0;
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 38.0;
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 42.0;
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 45.0;
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 48.0;
    }
  }

  /// Zalecane ciśnienie bazowe opony [bar] dla kolarza ~72 kg.
  double get recommendedTirePressureBar {
    switch (this) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 2.85;
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 2.55;
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 2.25;
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 2.10;
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 1.85;
    }
  }

  /// Znormalizowana intensywność wibracji na kierownicy i ramie (0.0–1.0).
  double get vibrationIntensity {
    switch (this) {
      case GravelSurfaceCategory.cat1ChampagneGravel:
        return 0.22;
      case GravelSurfaceCategory.cat2CompactedForestRoad:
        return 0.38;
      case GravelSurfaceCategory.cat3LooseWashboardsAndRuts:
        return 0.72;
      case GravelSurfaceCategory.cat4SharpFlintAndChunkyRock:
        return 0.86;
      case GravelSurfaceCategory.cat5TechnicalSingletrackAndMud:
        return 0.94;
    }
  }
}

/// Ranga i format wyścigu szutrowego.
enum GravelRaceDisciplineTier {
  uciGravelWorldSeries,
  uciGravelWorldChampionships,
  ultraGravelSelfSupported;

  String toJson() => name;

  static GravelRaceDisciplineTier fromJson(String value) {
    return GravelRaceDisciplineTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GravelRaceDisciplineTier.uciGravelWorldSeries,
    );
  }

  String get displayName {
    switch (this) {
      case GravelRaceDisciplineTier.uciGravelWorldSeries:
        return 'UCI Gravel World Series';
      case GravelRaceDisciplineTier.uciGravelWorldChampionships:
        return 'UCI Gravel World Championships';
      case GravelRaceDisciplineTier.ultraGravelSelfSupported:
        return 'Ultra-Gravel (Self-Supported)';
    }
  }
}

/// Obowiązkowe wyposażenie wymagane przez regulamin wyścigu szutrowego.
enum MandatoryGravelGearItem {
  co2InflatorAndCartridges,
  tubelessPlugKit,
  spareInnerTube,
  handMiniPump,
  frontAndRearLights,
  emergencyThermalBlanket,
  gpsTrackerUnit,
  hydrationVestOrTwoBottles;

  String toJson() => name;

  static MandatoryGravelGearItem fromJson(String value) {
    return MandatoryGravelGearItem.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MandatoryGravelGearItem.co2InflatorAndCartridges,
    );
  }

  String get labelPl {
    switch (this) {
      case MandatoryGravelGearItem.co2InflatorAndCartridges:
        return 'Naboje CO₂ + pompka z głowicą';
      case MandatoryGravelGearItem.tubelessPlugKit:
        return 'Zestaw knotów tubeless';
      case MandatoryGravelGearItem.spareInnerTube:
        return 'Zapasowa dętka TPU/butyl';
      case MandatoryGravelGearItem.handMiniPump:
        return 'Awaryjna mini-pompka ręczna';
      case MandatoryGravelGearItem.frontAndRearLights:
        return 'Oświetlenie przód i tył (Ultra)';
      case MandatoryGravelGearItem.emergencyThermalBlanket:
        return 'Folia termiczna NRC';
      case MandatoryGravelGearItem.gpsTrackerUnit:
        return 'Nadajnik GPS Live Tracker';
      case MandatoryGravelGearItem.hydrationVestOrTwoBottles:
        return 'Kamizelka nawadniająca / min. 2 bidony';
    }
  }
}

/// Typ awarii mechanicznej w terenie podczas wyścigu szutrowego.
enum GravelMechanicalIssueType {
  smallTubelessPuncture,
  largeTreadGash,
  sidewallTear,
  valveCoreLeak,
  chainSnap;

  String toJson() => name;

  static GravelMechanicalIssueType fromJson(String value) {
    return GravelMechanicalIssueType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GravelMechanicalIssueType.smallTubelessPuncture,
    );
  }
}

/// Wynik naprawy terenowej w warunkach samowystarczalności.
enum GravelRepairOutcomeStatus {
  sealedByFluidOnly,
  repairedWithCo2AndPlug,
  repairedWithTubeAndCo2,
  repairedWithHandPumpFallback,
  chainFixedWithQuickLink,
  dnfOutOfSpares;

  String toJson() => name;

  static GravelRepairOutcomeStatus fromJson(String value) {
    return GravelRepairOutcomeStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GravelRepairOutcomeStatus.repairedWithCo2AndPlug,
    );
  }
}

/// Reguły samowystarczalności (Self-Supported Rules) dla wyścigu szutrowego.
class SelfSupportedRulesConfig {
  final bool isStrictlySelfSupported;
  final bool allowOutsideTechnicalAssistance;
  final bool allowFeedZoneSupportOnly;
  final bool allowBikeExchange;
  final bool allowAerobars;
  final bool draftingAllowed;
  final bool outsideAssistanceDisqualifies;
  final int outsideAssistancePenaltyMinutes;
  final int minMandatoryCo2Cartridges;
  final int co2CartridgeGrams;
  final List<MandatoryGravelGearItem> mandatoryGear;

  const SelfSupportedRulesConfig({
    required this.isStrictlySelfSupported,
    required this.allowOutsideTechnicalAssistance,
    required this.allowFeedZoneSupportOnly,
    this.allowBikeExchange = false,
    this.allowAerobars = false,
    this.draftingAllowed = true,
    this.outsideAssistanceDisqualifies = true,
    this.outsideAssistancePenaltyMinutes = 30,
    this.minMandatoryCo2Cartridges = 2,
    this.co2CartridgeGrams = 16,
    this.mandatoryGear = const [
      MandatoryGravelGearItem.co2InflatorAndCartridges,
      MandatoryGravelGearItem.tubelessPlugKit,
      MandatoryGravelGearItem.spareInnerTube,
    ],
  });

  /// Standardowy regulamin UCI Gravel World Series / Mistrzostw Świata.
  factory SelfSupportedRulesConfig.uciGravelStandard() {
    return const SelfSupportedRulesConfig(
      isStrictlySelfSupported: false,
      allowOutsideTechnicalAssistance: false,
      allowFeedZoneSupportOnly: true,
      allowBikeExchange: false,
      allowAerobars: false,
      draftingAllowed: true,
      outsideAssistanceDisqualifies: true,
      outsideAssistancePenaltyMinutes: 30,
      minMandatoryCo2Cartridges: 2,
      co2CartridgeGrams: 16,
      mandatoryGear: [
        MandatoryGravelGearItem.co2InflatorAndCartridges,
        MandatoryGravelGearItem.tubelessPlugKit,
        MandatoryGravelGearItem.spareInnerTube,
      ],
    );
  }

  /// Rygorystyczny regulamin Ultra-Gravel (np. Unbound 200, Traka 360, Badlands).
  factory SelfSupportedRulesConfig.ultraGravelStrict({
    bool allowAerobars = true,
  }) {
    return SelfSupportedRulesConfig(
      isStrictlySelfSupported: true,
      allowOutsideTechnicalAssistance: false,
      allowFeedZoneSupportOnly: false,
      allowBikeExchange: false,
      allowAerobars: allowAerobars,
      draftingAllowed: true,
      outsideAssistanceDisqualifies: true,
      outsideAssistancePenaltyMinutes: 60,
      minMandatoryCo2Cartridges: 3,
      co2CartridgeGrams: 25,
      mandatoryGear: const [
        MandatoryGravelGearItem.co2InflatorAndCartridges,
        MandatoryGravelGearItem.tubelessPlugKit,
        MandatoryGravelGearItem.spareInnerTube,
        MandatoryGravelGearItem.handMiniPump,
        MandatoryGravelGearItem.frontAndRearLights,
        MandatoryGravelGearItem.emergencyThermalBlanket,
        MandatoryGravelGearItem.gpsTrackerUnit,
        MandatoryGravelGearItem.hydrationVestOrTwoBottles,
      ],
    );
  }

  /// Weryfikuje kompletność wyposażenia kolarza względem regulaminu.
  bool isRepairKitCompliant(GravelRepairKitState kit) {
    if (kit.co2CartridgesRemaining < minMandatoryCo2Cartridges) return false;
    if (mandatoryGear.contains(MandatoryGravelGearItem.tubelessPlugKit) &&
        kit.tubelessPlugsRemaining <= 0) {
      return false;
    }
    if (mandatoryGear.contains(MandatoryGravelGearItem.spareInnerTube) &&
        kit.spareInnerTubesRemaining <= 0) {
      return false;
    }
    if (mandatoryGear.contains(MandatoryGravelGearItem.handMiniPump) &&
        !kit.hasMiniPumpBackup) {
      return false;
    }
    return true;
  }

  SelfSupportedRulesConfig copyWith({
    bool? isStrictlySelfSupported,
    bool? allowOutsideTechnicalAssistance,
    bool? allowFeedZoneSupportOnly,
    bool? allowBikeExchange,
    bool? allowAerobars,
    bool? draftingAllowed,
    bool? outsideAssistanceDisqualifies,
    int? outsideAssistancePenaltyMinutes,
    int? minMandatoryCo2Cartridges,
    int? co2CartridgeGrams,
    List<MandatoryGravelGearItem>? mandatoryGear,
  }) {
    return SelfSupportedRulesConfig(
      isStrictlySelfSupported:
          isStrictlySelfSupported ?? this.isStrictlySelfSupported,
      allowOutsideTechnicalAssistance: allowOutsideTechnicalAssistance ??
          this.allowOutsideTechnicalAssistance,
      allowFeedZoneSupportOnly:
          allowFeedZoneSupportOnly ?? this.allowFeedZoneSupportOnly,
      allowBikeExchange: allowBikeExchange ?? this.allowBikeExchange,
      allowAerobars: allowAerobars ?? this.allowAerobars,
      draftingAllowed: draftingAllowed ?? this.draftingAllowed,
      outsideAssistanceDisqualifies:
          outsideAssistanceDisqualifies ?? this.outsideAssistanceDisqualifies,
      outsideAssistancePenaltyMinutes: outsideAssistancePenaltyMinutes ??
          this.outsideAssistancePenaltyMinutes,
      minMandatoryCo2Cartridges:
          minMandatoryCo2Cartridges ?? this.minMandatoryCo2Cartridges,
      co2CartridgeGrams: co2CartridgeGrams ?? this.co2CartridgeGrams,
      mandatoryGear: mandatoryGear ?? this.mandatoryGear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isStrictlySelfSupported': isStrictlySelfSupported,
      'allowOutsideTechnicalAssistance': allowOutsideTechnicalAssistance,
      'allowFeedZoneSupportOnly': allowFeedZoneSupportOnly,
      'allowBikeExchange': allowBikeExchange,
      'allowAerobars': allowAerobars,
      'draftingAllowed': draftingAllowed,
      'outsideAssistanceDisqualifies': outsideAssistanceDisqualifies,
      'outsideAssistancePenaltyMinutes': outsideAssistancePenaltyMinutes,
      'minMandatoryCo2Cartridges': minMandatoryCo2Cartridges,
      'co2CartridgeGrams': co2CartridgeGrams,
      'mandatoryGear': mandatoryGear.map((e) => e.toJson()).toList(),
    };
  }

  factory SelfSupportedRulesConfig.fromJson(Map<String, dynamic> json) {
    final rawGear = json['mandatoryGear'] as List<dynamic>? ?? const [];
    return SelfSupportedRulesConfig(
      isStrictlySelfSupported:
          json['isStrictlySelfSupported'] as bool? ?? false,
      allowOutsideTechnicalAssistance:
          json['allowOutsideTechnicalAssistance'] as bool? ?? false,
      allowFeedZoneSupportOnly:
          json['allowFeedZoneSupportOnly'] as bool? ?? true,
      allowBikeExchange: json['allowBikeExchange'] as bool? ?? false,
      allowAerobars: json['allowAerobars'] as bool? ?? false,
      draftingAllowed: json['draftingAllowed'] as bool? ?? true,
      outsideAssistanceDisqualifies:
          json['outsideAssistanceDisqualifies'] as bool? ?? true,
      outsideAssistancePenaltyMinutes:
          (json['outsideAssistancePenaltyMinutes'] as num?)?.toInt() ?? 30,
      minMandatoryCo2Cartridges:
          (json['minMandatoryCo2Cartridges'] as num?)?.toInt() ?? 2,
      co2CartridgeGrams: (json['co2CartridgeGrams'] as num?)?.toInt() ?? 16,
      mandatoryGear: rawGear
          .map((e) => MandatoryGravelGearItem.fromJson(e.toString()))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SelfSupportedRulesConfig) return false;
    if (mandatoryGear.length != other.mandatoryGear.length) return false;
    for (var i = 0; i < mandatoryGear.length; i++) {
      if (mandatoryGear[i] != other.mandatoryGear[i]) return false;
    }
    return isStrictlySelfSupported == other.isStrictlySelfSupported &&
        allowOutsideTechnicalAssistance ==
            other.allowOutsideTechnicalAssistance &&
        allowFeedZoneSupportOnly == other.allowFeedZoneSupportOnly &&
        allowBikeExchange == other.allowBikeExchange &&
        allowAerobars == other.allowAerobars &&
        draftingAllowed == other.draftingAllowed &&
        outsideAssistanceDisqualifies == other.outsideAssistanceDisqualifies &&
        outsideAssistancePenaltyMinutes ==
            other.outsideAssistancePenaltyMinutes &&
        minMandatoryCo2Cartridges == other.minMandatoryCo2Cartridges &&
        co2CartridgeGrams == other.co2CartridgeGrams;
  }

  @override
  int get hashCode => Object.hash(
        isStrictlySelfSupported,
        allowOutsideTechnicalAssistance,
        allowFeedZoneSupportOnly,
        allowBikeExchange,
        allowAerobars,
        draftingAllowed,
        outsideAssistanceDisqualifies,
        outsideAssistancePenaltyMinutes,
        minMandatoryCo2Cartridges,
        co2CartridgeGrams,
        Object.hashAll(mandatoryGear),
      );
}

/// Wynik pojedynczej naprawy terenowej (np. knot tubeless + nabój CO₂).
class Co2RepairActionResult {
  final GravelMechanicalIssueType issueType;
  final GravelRepairOutcomeStatus outcomeStatus;
  final GravelRepairKitState updatedKit;
  final double timeLostSeconds;
  final int co2CartridgesUsed;
  final int tubelessPlugsUsed;
  final int innerTubesUsed;
  final double restoredTirePressureBar;
  final bool raceContinuing;
  final String diagnosticMessage;

  const Co2RepairActionResult({
    required this.issueType,
    required this.outcomeStatus,
    required this.updatedKit,
    required this.timeLostSeconds,
    required this.co2CartridgesUsed,
    required this.tubelessPlugsUsed,
    required this.innerTubesUsed,
    required this.restoredTirePressureBar,
    required this.raceContinuing,
    required this.diagnosticMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'issueType': issueType.toJson(),
      'outcomeStatus': outcomeStatus.toJson(),
      'updatedKit': updatedKit.toJson(),
      'timeLostSeconds': timeLostSeconds,
      'co2CartridgesUsed': co2CartridgesUsed,
      'tubelessPlugsUsed': tubelessPlugsUsed,
      'innerTubesUsed': innerTubesUsed,
      'restoredTirePressureBar': restoredTirePressureBar,
      'raceContinuing': raceContinuing,
      'diagnosticMessage': diagnosticMessage,
    };
  }

  factory Co2RepairActionResult.fromJson(Map<String, dynamic> json) {
    return Co2RepairActionResult(
      issueType: GravelMechanicalIssueType.fromJson(
        json['issueType'] as String? ?? 'smallTubelessPuncture',
      ),
      outcomeStatus: GravelRepairOutcomeStatus.fromJson(
        json['outcomeStatus'] as String? ?? 'repairedWithCo2AndPlug',
      ),
      updatedKit: GravelRepairKitState.fromJson(
        json['updatedKit'] as Map<String, dynamic>? ?? const {},
      ),
      timeLostSeconds: (json['timeLostSeconds'] as num?)?.toDouble() ?? 0.0,
      co2CartridgesUsed: (json['co2CartridgesUsed'] as num?)?.toInt() ?? 0,
      tubelessPlugsUsed: (json['tubelessPlugsUsed'] as num?)?.toInt() ?? 0,
      innerTubesUsed: (json['innerTubesUsed'] as num?)?.toInt() ?? 0,
      restoredTirePressureBar:
          (json['restoredTirePressureBar'] as num?)?.toDouble() ?? 2.2,
      raceContinuing: json['raceContinuing'] as bool? ?? true,
      diagnosticMessage: json['diagnosticMessage'] as String? ?? '',
    );
  }
}

/// Stan podręcznego zestawu naprawczego kolarza w formule Self-Supported (naboje CO₂, knoty, dętka).
class GravelRepairKitState {
  final int co2CartridgesRemaining;
  final int co2CartridgeGrams;
  final int tubelessPlugsRemaining;
  final int spareInnerTubesRemaining;
  final bool hasMiniPumpBackup;
  final bool hasQuickLinkAndChainTool;
  final double sealantMlRemaining;

  const GravelRepairKitState({
    this.co2CartridgesRemaining = 2,
    this.co2CartridgeGrams = 16,
    this.tubelessPlugsRemaining = 5,
    this.spareInnerTubesRemaining = 1,
    this.hasMiniPumpBackup = true,
    this.hasQuickLinkAndChainTool = true,
    this.sealantMlRemaining = 90.0,
  });

  /// Czy kolarz ma co najmniej jeden nabój CO₂ do błyskawicznego dopompowania opony.
  bool get hasCo2Available => co2CartridgesRemaining > 0;

  /// Czy kolarz ma jakiekolwiek źródło pompowania (CO₂ lub mini-pompka).
  bool get canInflateTire => hasCo2Available || hasMiniPumpBackup;

  /// Symuluje samodzielną naprawę awarii na trasie bez wozu technicznego.
  ///
  /// [mechanicalSkill] w zakresie 1.0–100.0 (wyższa umiejętność skraca czas postoju).
  /// [targetPressureBar] docelowe ciśnienie po naprawie.
  Co2RepairActionResult attemptFieldRepair({
    required GravelMechanicalIssueType issueType,
    double mechanicalSkill = 70.0,
    double targetPressureBar = 2.25,
  }) {
    final skillNorm = (mechanicalSkill.clamp(1.0, 100.0) - 1.0) / 99.0;
    final skillSpeedFactor = 1.18 - (skillNorm * 0.36);

    switch (issueType) {
      case GravelMechanicalIssueType.smallTubelessPuncture:
        if (sealantMlRemaining >= 20.0) {
          final updated = copyWith(
            sealantMlRemaining: math.max(0.0, sealantMlRemaining - 20.0),
          );
          final pressureAfterSeal = math.max(1.55, targetPressureBar - 0.35);
          return Co2RepairActionResult(
            issueType: issueType,
            outcomeStatus: GravelRepairOutcomeStatus.sealedByFluidOnly,
            updatedKit: updated,
            timeLostSeconds: 10.0 * skillSpeedFactor,
            co2CartridgesUsed: 0,
            tubelessPlugsUsed: 0,
            innerTubesUsed: 0,
            restoredTirePressureBar: pressureAfterSeal,
            raceContinuing: true,
            diagnosticMessage:
                'Mleczko uszczelniło drobne przebicie bez zatrzymywania.',
          );
        }
        return _repairWithPlugAndAir(
          issueType: issueType,
          plugsNeeded: 1,
          skillSpeedFactor: skillSpeedFactor,
          targetPressureBar: targetPressureBar,
        );

      case GravelMechanicalIssueType.largeTreadGash:
        return _repairWithPlugAndAir(
          issueType: issueType,
          plugsNeeded: 2,
          skillSpeedFactor: skillSpeedFactor,
          targetPressureBar: targetPressureBar,
        );

      case GravelMechanicalIssueType.sidewallTear:
        return _repairWithInnerTube(
          issueType: issueType,
          skillSpeedFactor: skillSpeedFactor,
          targetPressureBar: targetPressureBar,
        );

      case GravelMechanicalIssueType.valveCoreLeak:
        return _inflateTireOnly(
          issueType: issueType,
          skillSpeedFactor: skillSpeedFactor,
          targetPressureBar: targetPressureBar,
        );

      case GravelMechanicalIssueType.chainSnap:
        if (!hasQuickLinkAndChainTool) {
          return Co2RepairActionResult(
            issueType: issueType,
            outcomeStatus: GravelRepairOutcomeStatus.dnfOutOfSpares,
            updatedKit: this,
            timeLostSeconds: 0.0,
            co2CartridgesUsed: 0,
            tubelessPlugsUsed: 0,
            innerTubesUsed: 0,
            restoredTirePressureBar: targetPressureBar,
            raceContinuing: false,
            diagnosticMessage:
                'Zerwany łańcuch bez spinki i skuwacza — koniec jazdy (DNF).',
          );
        }
        return Co2RepairActionResult(
          issueType: issueType,
          outcomeStatus: GravelRepairOutcomeStatus.chainFixedWithQuickLink,
          updatedKit: copyWith(hasQuickLinkAndChainTool: false),
          timeLostSeconds: 95.0 * skillSpeedFactor,
          co2CartridgesUsed: 0,
          tubelessPlugsUsed: 0,
          innerTubesUsed: 0,
          restoredTirePressureBar: targetPressureBar,
          raceContinuing: true,
          diagnosticMessage:
              'Łańcuch spięty w terenie przy pomocy zapasowej spinki.',
        );
    }
  }

  Co2RepairActionResult _repairWithPlugAndAir({
    required GravelMechanicalIssueType issueType,
    required int plugsNeeded,
    required double skillSpeedFactor,
    required double targetPressureBar,
  }) {
    if (tubelessPlugsRemaining >= plugsNeeded && canInflateTire) {
      final useCo2 = hasCo2Available;
      final co2Used = useCo2 ? 1 : 0;
      final baseSeconds = useCo2 ? 42.0 : 128.0;
      final updated = copyWith(
        tubelessPlugsRemaining: tubelessPlugsRemaining - plugsNeeded,
        co2CartridgesRemaining: co2CartridgesRemaining - co2Used,
        sealantMlRemaining: math.max(0.0, sealantMlRemaining - 15.0),
      );
      return Co2RepairActionResult(
        issueType: issueType,
        outcomeStatus: useCo2
            ? GravelRepairOutcomeStatus.repairedWithCo2AndPlug
            : GravelRepairOutcomeStatus.repairedWithHandPumpFallback,
        updatedKit: updated,
        timeLostSeconds: baseSeconds * skillSpeedFactor,
        co2CartridgesUsed: co2Used,
        tubelessPlugsUsed: plugsNeeded,
        innerTubesUsed: 0,
        restoredTirePressureBar: useCo2
            ? targetPressureBar
            : math.max(1.70, targetPressureBar - 0.25),
        raceContinuing: true,
        diagnosticMessage: useCo2
            ? 'Naprawa knotem tubeless + szybkie pompowanie nabojem CO₂ ($co2CartridgeGrams g).'
            : 'Brak nabojów CO₂ — naprawa knotem i pompowanie mini-pompką ręczną.',
      );
    }
    return _repairWithInnerTube(
      issueType: issueType,
      skillSpeedFactor: skillSpeedFactor,
      targetPressureBar: targetPressureBar,
    );
  }

  Co2RepairActionResult _repairWithInnerTube({
    required GravelMechanicalIssueType issueType,
    required double skillSpeedFactor,
    required double targetPressureBar,
  }) {
    if (spareInnerTubesRemaining <= 0 || !canInflateTire) {
      return Co2RepairActionResult(
        issueType: issueType,
        outcomeStatus: GravelRepairOutcomeStatus.dnfOutOfSpares,
        updatedKit: this,
        timeLostSeconds: 0.0,
        co2CartridgesUsed: 0,
        tubelessPlugsUsed: 0,
        innerTubesUsed: 0,
        restoredTirePressureBar: 0.0,
        raceContinuing: false,
        diagnosticMessage:
            'Brak zapasowej dętki lub naboju CO₂/pompki — wycofanie z wyścigu (DNF).',
      );
    }
    final useCo2 = hasCo2Available;
    final co2Used = useCo2 ? 1 : 0;
    final baseSeconds = useCo2 ? 130.0 : 215.0;
    final updated = copyWith(
      spareInnerTubesRemaining: spareInnerTubesRemaining - 1,
      co2CartridgesRemaining: co2CartridgesRemaining - co2Used,
    );
    return Co2RepairActionResult(
      issueType: issueType,
      outcomeStatus: useCo2
          ? GravelRepairOutcomeStatus.repairedWithTubeAndCo2
          : GravelRepairOutcomeStatus.repairedWithHandPumpFallback,
      updatedKit: updated,
      timeLostSeconds: baseSeconds * skillSpeedFactor,
      co2CartridgesUsed: co2Used,
      tubelessPlugsUsed: 0,
      innerTubesUsed: 1,
      restoredTirePressureBar: useCo2
          ? math.min(2.7, targetPressureBar + 0.15)
          : math.max(1.80, targetPressureBar - 0.15),
      raceContinuing: true,
      diagnosticMessage: useCo2
          ? 'Założono zapasową dętkę i napompowano nabojem CO₂ ($co2CartridgeGrams g).'
          : 'Założono zapasową dętkę — powolne pompowanie mini-pompką ręczną.',
    );
  }

  Co2RepairActionResult _inflateTireOnly({
    required GravelMechanicalIssueType issueType,
    required double skillSpeedFactor,
    required double targetPressureBar,
  }) {
    if (!canInflateTire) {
      return Co2RepairActionResult(
        issueType: issueType,
        outcomeStatus: GravelRepairOutcomeStatus.dnfOutOfSpares,
        updatedKit: this,
        timeLostSeconds: 0.0,
        co2CartridgesUsed: 0,
        tubelessPlugsUsed: 0,
        innerTubesUsed: 0,
        restoredTirePressureBar: 0.0,
        raceContinuing: false,
        diagnosticMessage: 'Brak powietrza (CO₂ ani pompki) do dopompowania opony.',
      );
    }
    final useCo2 = hasCo2Available;
    final co2Used = useCo2 ? 1 : 0;
    final updated = copyWith(
      co2CartridgesRemaining: co2CartridgesRemaining - co2Used,
    );
    return Co2RepairActionResult(
      issueType: issueType,
      outcomeStatus: useCo2
          ? GravelRepairOutcomeStatus.repairedWithCo2AndPlug
          : GravelRepairOutcomeStatus.repairedWithHandPumpFallback,
      updatedKit: updated,
      timeLostSeconds: (useCo2 ? 25.0 : 95.0) * skillSpeedFactor,
      co2CartridgesUsed: co2Used,
      tubelessPlugsUsed: 0,
      innerTubesUsed: 0,
      restoredTirePressureBar: targetPressureBar,
      raceContinuing: true,
      diagnosticMessage: useCo2
          ? 'Dokręcono wentyl i dopompowano nabojem CO₂.'
          : 'Dokręcono wentyl i dopompowano mini-pompką ręczną.',
    );
  }

  GravelRepairKitState copyWith({
    int? co2CartridgesRemaining,
    int? co2CartridgeGrams,
    int? tubelessPlugsRemaining,
    int? spareInnerTubesRemaining,
    bool? hasMiniPumpBackup,
    bool? hasQuickLinkAndChainTool,
    double? sealantMlRemaining,
  }) {
    return GravelRepairKitState(
      co2CartridgesRemaining:
          co2CartridgesRemaining ?? this.co2CartridgesRemaining,
      co2CartridgeGrams: co2CartridgeGrams ?? this.co2CartridgeGrams,
      tubelessPlugsRemaining:
          tubelessPlugsRemaining ?? this.tubelessPlugsRemaining,
      spareInnerTubesRemaining:
          spareInnerTubesRemaining ?? this.spareInnerTubesRemaining,
      hasMiniPumpBackup: hasMiniPumpBackup ?? this.hasMiniPumpBackup,
      hasQuickLinkAndChainTool:
          hasQuickLinkAndChainTool ?? this.hasQuickLinkAndChainTool,
      sealantMlRemaining: sealantMlRemaining ?? this.sealantMlRemaining,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'co2CartridgesRemaining': co2CartridgesRemaining,
      'co2CartridgeGrams': co2CartridgeGrams,
      'tubelessPlugsRemaining': tubelessPlugsRemaining,
      'spareInnerTubesRemaining': spareInnerTubesRemaining,
      'hasMiniPumpBackup': hasMiniPumpBackup,
      'hasQuickLinkAndChainTool': hasQuickLinkAndChainTool,
      'sealantMlRemaining': sealantMlRemaining,
    };
  }

  factory GravelRepairKitState.fromJson(Map<String, dynamic> json) {
    return GravelRepairKitState(
      co2CartridgesRemaining:
          (json['co2CartridgesRemaining'] as num?)?.toInt() ?? 2,
      co2CartridgeGrams: (json['co2CartridgeGrams'] as num?)?.toInt() ?? 16,
      tubelessPlugsRemaining:
          (json['tubelessPlugsRemaining'] as num?)?.toInt() ?? 5,
      spareInnerTubesRemaining:
          (json['spareInnerTubesRemaining'] as num?)?.toInt() ?? 1,
      hasMiniPumpBackup: json['hasMiniPumpBackup'] as bool? ?? true,
      hasQuickLinkAndChainTool:
          json['hasQuickLinkAndChainTool'] as bool? ?? true,
      sealantMlRemaining:
          (json['sealantMlRemaining'] as num?)?.toDouble() ?? 90.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GravelRepairKitState &&
        other.co2CartridgesRemaining == co2CartridgesRemaining &&
        other.co2CartridgeGrams == co2CartridgeGrams &&
        other.tubelessPlugsRemaining == tubelessPlugsRemaining &&
        other.spareInnerTubesRemaining == spareInnerTubesRemaining &&
        other.hasMiniPumpBackup == hasMiniPumpBackup &&
        other.hasQuickLinkAndChainTool == hasQuickLinkAndChainTool &&
        other.sealantMlRemaining == sealantMlRemaining;
  }

  @override
  int get hashCode => Object.hash(
        co2CartridgesRemaining,
        co2CartridgeGrams,
        tubelessPlugsRemaining,
        spareInnerTubesRemaining,
        hasMiniPumpBackup,
        hasQuickLinkAndChainTool,
        sealantMlRemaining,
      );
}

/// Pojedynczy segment trasy wyścigu szutrowego UCI Gravel / Ultra-Gravel.
class GravelCourseSegment {
  final int index;
  final double startKm;
  final double lengthKm;
  final GravelSurfaceCategory surfaceCategory;
  final double gradientPercent;
  final double elevationGainM;
  final double dustDensityIndex;
  final double mudSaturationIndex;
  final double windExposureFactor;
  final bool isFeedOrCheckpointZone;
  final String? checkpointName;
  final bool hasWaterResupply;

  const GravelCourseSegment({
    required this.index,
    required this.startKm,
    required this.lengthKm,
    required this.surfaceCategory,
    this.gradientPercent = 0.0,
    this.elevationGainM = 0.0,
    this.dustDensityIndex = 0.35,
    this.mudSaturationIndex = 0.0,
    this.windExposureFactor = 0.5,
    this.isFeedOrCheckpointZone = false,
    this.checkpointName,
    this.hasWaterResupply = false,
  });

  /// Kilometraż końca segmentu [km].
  double get endKm => startKm + lengthKm;

  /// Efektywny mnożnik oporu toczenia z uwzględnieniem błota.
  double get effectiveCrrMultiplier {
    final mudPenalty = 1.0 + (mudSaturationIndex.clamp(0.0, 1.0) * 0.28);
    return surfaceCategory.crrMultiplier * mudPenalty;
  }

  /// Efektywne ryzyko przebicia uwzględniające kategorię nawierzchni i mokre warunki.
  double get effectivePunctureRisk {
    final wetFlintMultiplier =
        1.0 + (mudSaturationIndex.clamp(0.0, 1.0) * 0.20);
    return surfaceCategory.punctureRiskFactor * wetFlintMultiplier;
  }

  /// Zalecana minimalna szerokość opony na ten segment [mm].
  double get recommendedTireWidthMm => surfaceCategory.recommendedMinTireWidthMm;

  GravelCourseSegment copyWith({
    int? index,
    double? startKm,
    double? lengthKm,
    GravelSurfaceCategory? surfaceCategory,
    double? gradientPercent,
    double? elevationGainM,
    double? dustDensityIndex,
    double? mudSaturationIndex,
    double? windExposureFactor,
    bool? isFeedOrCheckpointZone,
    String? checkpointName,
    bool? hasWaterResupply,
  }) {
    return GravelCourseSegment(
      index: index ?? this.index,
      startKm: startKm ?? this.startKm,
      lengthKm: lengthKm ?? this.lengthKm,
      surfaceCategory: surfaceCategory ?? this.surfaceCategory,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      dustDensityIndex: dustDensityIndex ?? this.dustDensityIndex,
      mudSaturationIndex: mudSaturationIndex ?? this.mudSaturationIndex,
      windExposureFactor: windExposureFactor ?? this.windExposureFactor,
      isFeedOrCheckpointZone:
          isFeedOrCheckpointZone ?? this.isFeedOrCheckpointZone,
      checkpointName: checkpointName ?? this.checkpointName,
      hasWaterResupply: hasWaterResupply ?? this.hasWaterResupply,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'startKm': startKm,
      'lengthKm': lengthKm,
      'surfaceCategory': surfaceCategory.toJson(),
      'gradientPercent': gradientPercent,
      'elevationGainM': elevationGainM,
      'dustDensityIndex': dustDensityIndex,
      'mudSaturationIndex': mudSaturationIndex,
      'windExposureFactor': windExposureFactor,
      'isFeedOrCheckpointZone': isFeedOrCheckpointZone,
      'checkpointName': checkpointName,
      'hasWaterResupply': hasWaterResupply,
    };
  }

  factory GravelCourseSegment.fromJson(Map<String, dynamic> json) {
    return GravelCourseSegment(
      index: (json['index'] as num?)?.toInt() ?? 0,
      startKm: (json['startKm'] as num?)?.toDouble() ?? 0.0,
      lengthKm: (json['lengthKm'] as num?)?.toDouble() ?? 10.0,
      surfaceCategory: GravelSurfaceCategory.fromJson(
        json['surfaceCategory'] as String? ?? 'cat2CompactedForestRoad',
      ),
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 0.0,
      dustDensityIndex: (json['dustDensityIndex'] as num?)?.toDouble() ?? 0.35,
      mudSaturationIndex:
          (json['mudSaturationIndex'] as num?)?.toDouble() ?? 0.0,
      windExposureFactor:
          (json['windExposureFactor'] as num?)?.toDouble() ?? 0.5,
      isFeedOrCheckpointZone: json['isFeedOrCheckpointZone'] as bool? ?? false,
      checkpointName: json['checkpointName'] as String?,
      hasWaterResupply: json['hasWaterResupply'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GravelCourseSegment &&
        other.index == index &&
        other.startKm == startKm &&
        other.lengthKm == lengthKm &&
        other.surfaceCategory == surfaceCategory &&
        other.gradientPercent == gradientPercent &&
        other.elevationGainM == elevationGainM &&
        other.dustDensityIndex == dustDensityIndex &&
        other.mudSaturationIndex == mudSaturationIndex &&
        other.windExposureFactor == windExposureFactor &&
        other.isFeedOrCheckpointZone == isFeedOrCheckpointZone &&
        other.checkpointName == checkpointName &&
        other.hasWaterResupply == hasWaterResupply;
  }

  @override
  int get hashCode => Object.hash(
        index,
        startKm,
        lengthKm,
        surfaceCategory,
        gradientPercent,
        elevationGainM,
        dustDensityIndex,
        mudSaturationIndex,
        windExposureFactor,
        isFeedOrCheckpointZone,
        checkpointName,
        hasWaterResupply,
      );
}

/// Wynik oceny doboru opon i ciśnienia dla konkretnego wyścigu szutrowego.
class GravelTireSetupEvaluation {
  final double selectedTireWidthMm;
  final double recommendedTireWidthMm;
  final double selectedPressureBar;
  final double recommendedPressureBar;
  final double rollingResistancePenaltyFactor;
  final double punctureRiskMultiplier;
  final bool isUnderTired;

  const GravelTireSetupEvaluation({
    required this.selectedTireWidthMm,
    required this.recommendedTireWidthMm,
    required this.selectedPressureBar,
    required this.recommendedPressureBar,
    required this.rollingResistancePenaltyFactor,
    required this.punctureRiskMultiplier,
    required this.isUnderTired,
  });
}

/// Kompletny model danych dla wyścigów szutrowych UCI Gravel World Series & Ultra-Gravel.
class GravelRaceAndSurfaceModel {
  final String id;
  final String name;
  final String countryCode;
  final String region;
  final GravelRaceDisciplineTier tier;
  final double totalDistanceKm;
  final double totalElevationGainM;
  final List<GravelCourseSegment> segments;
  final SelfSupportedRulesConfig selfSupportedRules;
  final GravelRepairKitState defaultRepairKit;
  final double recommendedTireWidthMm;
  final double ambientTemperatureC;
  final double rainIntensity;
  final double cutOffTimeHours;

  const GravelRaceAndSurfaceModel({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.region,
    required this.tier,
    required this.totalDistanceKm,
    required this.totalElevationGainM,
    required this.segments,
    required this.selfSupportedRules,
    this.defaultRepairKit = const GravelRepairKitState(),
    this.recommendedTireWidthMm = 42.0,
    this.ambientTemperatureC = 20.0,
    this.rainIntensity = 0.0,
    this.cutOffTimeHours = 12.0,
  });

  /// Rozkład kilometrów w każdej z 5 kategorii nawierzchni.
  Map<GravelSurfaceCategory, double> get surfaceBreakdownKm {
    final map = <GravelSurfaceCategory, double>{
      for (final cat in GravelSurfaceCategory.values) cat: 0.0,
    };
    for (final seg in segments) {
      map[seg.surfaceCategory] = (map[seg.surfaceCategory] ?? 0.0) + seg.lengthKm;
    }
    return map;
  }

  /// Procentowy udział każdej z 5 kategorii nawierzchni na trasie.
  Map<GravelSurfaceCategory, double> get surfaceBreakdownPercent {
    final totalSegKm = segments.fold<double>(0.0, (sum, s) => sum + s.lengthKm);
    if (totalSegKm <= 0.0) {
      return {for (final cat in GravelSurfaceCategory.values) cat: 0.0};
    }
    final kmMap = surfaceBreakdownKm;
    return {
      for (final entry in kmMap.entries)
        entry.key: (entry.value / totalSegKm) * 100.0,
    };
  }

  /// Średni ważony indeks trudności nawierzchni (1.0–5.0).
  double get weightedSurfaceDifficulty {
    final totalSegKm = segments.fold<double>(0.0, (sum, s) => sum + s.lengthKm);
    if (totalSegKm <= 0.0) return 2.0;
    final weightedSum = segments.fold<double>(
      0.0,
      (sum, s) => sum + (s.surfaceCategory.categoryNumber * s.lengthKm),
    );
    return weightedSum / totalSegKm;
  }

  /// Liczba punktów kontrolnych / stref nawadniania na trasie.
  int get checkpointCount =>
      segments.where((s) => s.isFeedOrCheckpointZone).length;

  /// Zwraca segment trasy odpowiadający zadanemu kilometrażowi [km].
  GravelCourseSegment? segmentAtKm(double km) {
    if (segments.isEmpty) return null;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        return seg;
      }
    }
    return km < segments.first.startKm ? segments.first : segments.last;
  }

  /// Zwraca najbliższy kolejny punkt kontrolny po [km].
  GravelCourseSegment? nextCheckpointAfterKm(double km) {
    for (final seg in segments) {
      if (seg.isFeedOrCheckpointZone && seg.startKm > km) {
        return seg;
      }
    }
    return null;
  }

  /// Ocenia dobór szerokości i ciśnienia opony względem profilu 5 kategorii nawierzchni.
  GravelTireSetupEvaluation evaluateTireSetup({
    required double tireWidthMm,
    required double tirePressureBar,
  }) {
    final totalSegKm = segments.fold<double>(0.0, (sum, s) => sum + s.lengthKm);
    double recPressure = 2.35;
    if (totalSegKm > 0.0) {
      recPressure = segments.fold<double>(
            0.0,
            (sum, s) =>
                sum + (s.surfaceCategory.recommendedTirePressureBar * s.lengthKm),
          ) /
          totalSegKm;
    }

    final widthDeficit = math.max(0.0, recommendedTireWidthMm - tireWidthMm);
    final isUnderTired = widthDeficit >= 3.0;
    final pressureDelta = (tirePressureBar - recPressure).abs();

    // Zbyt wąska opona lub nadmierne ciśnienie na tarce/krzemieniu drastycznie podnosi ryzyko dobicia i CRR.
    final crrPenalty = 1.0 + (widthDeficit * 0.015) + (pressureDelta * 0.06);
    final punctureMult =
        1.0 + (widthDeficit * 0.12) + (tirePressureBar < 1.65 ? 0.35 : 0.0);

    return GravelTireSetupEvaluation(
      selectedTireWidthMm: tireWidthMm,
      recommendedTireWidthMm: recommendedTireWidthMm,
      selectedPressureBar: tirePressureBar,
      recommendedPressureBar: recPressure,
      rollingResistancePenaltyFactor: crrPenalty,
      punctureRiskMultiplier: punctureMult,
      isUnderTired: isUnderTired,
    );
  }

  /// Preset: Mistrzostwa Świata UCI Gravel (np. Veneto / Limburgia, 162 km).
  factory GravelRaceAndSurfaceModel.uciGravelWorldsVeneto() {
    return GravelRaceAndSurfaceModel(
      id: 'uci_gravel_worlds_veneto',
      name: 'UCI Gravel World Championships — Veneto',
      countryCode: 'ITA',
      region: 'Veneto',
      tier: GravelRaceDisciplineTier.uciGravelWorldChampionships,
      totalDistanceKm: 162.0,
      totalElevationGainM: 1850.0,
      selfSupportedRules: SelfSupportedRulesConfig.uciGravelStandard(),
      defaultRepairKit: const GravelRepairKitState(
        co2CartridgesRemaining: 2,
        co2CartridgeGrams: 16,
        tubelessPlugsRemaining: 5,
        spareInnerTubesRemaining: 1,
        hasMiniPumpBackup: false,
      ),
      recommendedTireWidthMm: 40.0,
      ambientTemperatureC: 21.0,
      cutOffTimeHours: 8.5,
      segments: const [
        GravelCourseSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 35.0,
          surfaceCategory: GravelSurfaceCategory.cat1ChampagneGravel,
          gradientPercent: 0.8,
          elevationGainM: 280.0,
          dustDensityIndex: 0.55,
        ),
        GravelCourseSegment(
          index: 1,
          startKm: 35.0,
          lengthKm: 42.0,
          surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
          gradientPercent: 2.1,
          elevationGainM: 640.0,
          dustDensityIndex: 0.40,
          isFeedOrCheckpointZone: true,
          checkpointName: 'Tech & Feed Zone 1 — Bassano',
          hasWaterResupply: true,
        ),
        GravelCourseSegment(
          index: 2,
          startKm: 77.0,
          lengthKm: 45.0,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          gradientPercent: 1.5,
          elevationGainM: 580.0,
          dustDensityIndex: 0.65,
          isFeedOrCheckpointZone: true,
          checkpointName: 'Tech & Feed Zone 2 — Asolo',
          hasWaterResupply: true,
        ),
        GravelCourseSegment(
          index: 3,
          startKm: 122.0,
          lengthKm: 40.0,
          surfaceCategory: GravelSurfaceCategory.cat1ChampagneGravel,
          gradientPercent: -0.4,
          elevationGainM: 350.0,
          dustDensityIndex: 0.45,
        ),
      ],
    );
  }

  /// Preset: Unbound Gravel 200 (Kansas Flint Hills — ostry krzemień Cat 4, 322 km).
  factory GravelRaceAndSurfaceModel.unboundGravel200() {
    return GravelRaceAndSurfaceModel(
      id: 'unbound_gravel_200',
      name: 'Unbound Gravel 200 — Emporia Flint Hills',
      countryCode: 'USA',
      region: 'Kansas',
      tier: GravelRaceDisciplineTier.ultraGravelSelfSupported,
      totalDistanceKm: 322.0,
      totalElevationGainM: 3350.0,
      selfSupportedRules: SelfSupportedRulesConfig.ultraGravelStrict(
        allowAerobars: false,
      ),
      defaultRepairKit: const GravelRepairKitState(
        co2CartridgesRemaining: 4,
        co2CartridgeGrams: 25,
        tubelessPlugsRemaining: 8,
        spareInnerTubesRemaining: 2,
        hasMiniPumpBackup: true,
        sealantMlRemaining: 120.0,
      ),
      recommendedTireWidthMm: 45.0,
      ambientTemperatureC: 31.0,
      cutOffTimeHours: 20.0,
      segments: const [
        GravelCourseSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 75.0,
          surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
          gradientPercent: 0.9,
          elevationGainM: 680.0,
          dustDensityIndex: 0.70,
          windExposureFactor: 0.85,
        ),
        GravelCourseSegment(
          index: 1,
          startKm: 75.0,
          lengthKm: 95.0,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          gradientPercent: 1.4,
          elevationGainM: 1120.0,
          dustDensityIndex: 0.80,
          windExposureFactor: 0.90,
          isFeedOrCheckpointZone: true,
          checkpointName: 'Checkpoint 1 — Eureka',
          hasWaterResupply: true,
        ),
        GravelCourseSegment(
          index: 2,
          startKm: 170.0,
          lengthKm: 82.0,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          gradientPercent: 1.1,
          elevationGainM: 900.0,
          dustDensityIndex: 0.75,
          windExposureFactor: 0.80,
          isFeedOrCheckpointZone: true,
          checkpointName: 'Checkpoint 2 — Madison',
          hasWaterResupply: true,
        ),
        GravelCourseSegment(
          index: 3,
          startKm: 252.0,
          lengthKm: 70.0,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          gradientPercent: 0.8,
          elevationGainM: 650.0,
          dustDensityIndex: 0.65,
          windExposureFactor: 0.88,
        ),
      ],
    );
  }

  /// Preset: The Traka 360 (Girona, Hiszpania — miks wszystkich 5 kategorii nawierzchni).
  factory GravelRaceAndSurfaceModel.theTraka360() {
    return GravelRaceAndSurfaceModel(
      id: 'the_traka_360',
      name: 'The Traka 360 — Girona Ultra Gravel',
      countryCode: 'ESP',
      region: 'Catalonia',
      tier: GravelRaceDisciplineTier.ultraGravelSelfSupported,
      totalDistanceKm: 360.0,
      totalElevationGainM: 5200.0,
      selfSupportedRules: SelfSupportedRulesConfig.ultraGravelStrict(
        allowAerobars: true,
      ),
      defaultRepairKit: const GravelRepairKitState(
        co2CartridgesRemaining: 3,
        co2CartridgeGrams: 25,
        tubelessPlugsRemaining: 6,
        spareInnerTubesRemaining: 2,
        hasMiniPumpBackup: true,
      ),
      recommendedTireWidthMm: 45.0,
      ambientTemperatureC: 24.0,
      cutOffTimeHours: 24.0,
      segments: const [
        GravelCourseSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 80.0,
          surfaceCategory: GravelSurfaceCategory.cat1ChampagneGravel,
          gradientPercent: 1.2,
          elevationGainM: 960.0,
        ),
        GravelCourseSegment(
          index: 1,
          startKm: 80.0,
          lengthKm: 90.0,
          surfaceCategory: GravelSurfaceCategory.cat5TechnicalSingletrackAndMud,
          gradientPercent: 2.8,
          elevationGainM: 1840.0,
          mudSaturationIndex: 0.35,
          isFeedOrCheckpointZone: true,
          checkpointName: 'CP1 — Olot',
          hasWaterResupply: true,
        ),
        GravelCourseSegment(
          index: 2,
          startKm: 170.0,
          lengthKm: 100.0,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          gradientPercent: 1.5,
          elevationGainM: 1450.0,
          isFeedOrCheckpointZone: true,
          checkpointName: 'CP2 — Banyoles',
          hasWaterResupply: true,
        ),
        GravelCourseSegment(
          index: 3,
          startKm: 270.0,
          lengthKm: 90.0,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          gradientPercent: 0.9,
          elevationGainM: 950.0,
        ),
      ],
    );
  }

  GravelRaceAndSurfaceModel copyWith({
    String? id,
    String? name,
    String? countryCode,
    String? region,
    GravelRaceDisciplineTier? tier,
    double? totalDistanceKm,
    double? totalElevationGainM,
    List<GravelCourseSegment>? segments,
    SelfSupportedRulesConfig? selfSupportedRules,
    GravelRepairKitState? defaultRepairKit,
    double? recommendedTireWidthMm,
    double? ambientTemperatureC,
    double? rainIntensity,
    double? cutOffTimeHours,
  }) {
    return GravelRaceAndSurfaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      region: region ?? this.region,
      tier: tier ?? this.tier,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalElevationGainM: totalElevationGainM ?? this.totalElevationGainM,
      segments: segments ?? this.segments,
      selfSupportedRules: selfSupportedRules ?? this.selfSupportedRules,
      defaultRepairKit: defaultRepairKit ?? this.defaultRepairKit,
      recommendedTireWidthMm:
          recommendedTireWidthMm ?? this.recommendedTireWidthMm,
      ambientTemperatureC: ambientTemperatureC ?? this.ambientTemperatureC,
      rainIntensity: rainIntensity ?? this.rainIntensity,
      cutOffTimeHours: cutOffTimeHours ?? this.cutOffTimeHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'countryCode': countryCode,
      'region': region,
      'tier': tier.toJson(),
      'totalDistanceKm': totalDistanceKm,
      'totalElevationGainM': totalElevationGainM,
      'segments': segments.map((s) => s.toJson()).toList(),
      'selfSupportedRules': selfSupportedRules.toJson(),
      'defaultRepairKit': defaultRepairKit.toJson(),
      'recommendedTireWidthMm': recommendedTireWidthMm,
      'ambientTemperatureC': ambientTemperatureC,
      'rainIntensity': rainIntensity,
      'cutOffTimeHours': cutOffTimeHours,
    };
  }

  factory GravelRaceAndSurfaceModel.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'] as List<dynamic>? ?? const [];
    return GravelRaceAndSurfaceModel(
      id: json['id'] as String? ?? 'gravel_custom',
      name: json['name'] as String? ?? 'Gravel Race',
      countryCode: json['countryCode'] as String? ?? 'INT',
      region: json['region'] as String? ?? 'Gravel',
      tier: GravelRaceDisciplineTier.fromJson(
        json['tier'] as String? ?? 'uciGravelWorldSeries',
      ),
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 140.0,
      totalElevationGainM:
          (json['totalElevationGainM'] as num?)?.toDouble() ?? 1500.0,
      segments: rawSegments
          .map((e) => GravelCourseSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      selfSupportedRules: SelfSupportedRulesConfig.fromJson(
        json['selfSupportedRules'] as Map<String, dynamic>? ?? const {},
      ),
      defaultRepairKit: GravelRepairKitState.fromJson(
        json['defaultRepairKit'] as Map<String, dynamic>? ?? const {},
      ),
      recommendedTireWidthMm:
          (json['recommendedTireWidthMm'] as num?)?.toDouble() ?? 42.0,
      ambientTemperatureC:
          (json['ambientTemperatureC'] as num?)?.toDouble() ?? 20.0,
      rainIntensity: (json['rainIntensity'] as num?)?.toDouble() ?? 0.0,
      cutOffTimeHours: (json['cutOffTimeHours'] as num?)?.toDouble() ?? 12.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GravelRaceAndSurfaceModel) return false;
    if (segments.length != other.segments.length) return false;
    for (var i = 0; i < segments.length; i++) {
      if (segments[i] != other.segments[i]) return false;
    }
    return other.id == id &&
        other.name == name &&
        other.countryCode == countryCode &&
        other.region == region &&
        other.tier == tier &&
        other.totalDistanceKm == totalDistanceKm &&
        other.totalElevationGainM == totalElevationGainM &&
        other.selfSupportedRules == selfSupportedRules &&
        other.defaultRepairKit == defaultRepairKit &&
        other.recommendedTireWidthMm == recommendedTireWidthMm &&
        other.ambientTemperatureC == ambientTemperatureC &&
        other.rainIntensity == rainIntensity &&
        other.cutOffTimeHours == cutOffTimeHours;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        countryCode,
        region,
        tier,
        totalDistanceKm,
        totalElevationGainM,
        Object.hashAll(segments),
        selfSupportedRules,
        defaultRepairKit,
        recommendedTireWidthMm,
        ambientTemperatureC,
        rainIntensity,
        cutOffTimeHours,
      );
}
