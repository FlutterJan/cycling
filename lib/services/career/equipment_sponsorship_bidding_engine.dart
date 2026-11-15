import 'dart:math' as math;
import '../../models/team/bike_manufacturer_deal.dart';
import '../../models/team/cycling_team.dart';

/// Kategorie kontraktów technicznych i przetargów sprzętowych pod koniec sezonu.
enum EquipmentSponsorCategory {
  /// Główny producent ram szosowych i czasowych (TT)
  frames,

  /// Koła wyścigowe (stożki aero, koła górskie, pełne dyski czasowe TT)
  wheels,

  /// Grupy osprzętu elektronicznego (Di2, AXS, EPS) i zintegrowane mierniki mocy
  groupsetAndPower,

  /// Kaski aerodynamiczne/szosowe oraz specjalistyczna optyka i okulary
  helmetsAndEyewear,

  /// Odzież kolarska: kombinezony czasowe aero, stroje aerodynamiczne i odzież termiczna
  apparel,

  /// Żywienie sportowe: żele wysokowęglowodanowe (do 120g/h), hydrożele i nawadnianie
  nutrition;

  String toJson() => name;

  static EquipmentSponsorCategory fromJson(String value) {
    return EquipmentSponsorCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EquipmentSponsorCategory.apparel,
    );
  }

  String get displayName {
    switch (this) {
      case EquipmentSponsorCategory.frames:
        return 'Ramy Szosowe & Czasowe (Główny Producent)';
      case EquipmentSponsorCategory.wheels:
        return 'Koła Wyścigowe & Dyski Czasowe TT';
      case EquipmentSponsorCategory.groupsetAndPower:
        return 'Grupy Osprzętu & Mierniki Mocy';
      case EquipmentSponsorCategory.helmetsAndEyewear:
        return 'Kaski Aerodynamiczne & Okulary';
      case EquipmentSponsorCategory.apparel:
        return 'Odzież Kolarska & Kombinezony Aero TT';
      case EquipmentSponsorCategory.nutrition:
        return 'Żywienie Sportowe & Żele 120g/h (Hydrogel)';
    }
  }

  String get technicalScopeDescription {
    switch (this) {
      case EquipmentSponsorCategory.frames:
        return 'Geometria aerodynamiczna ramy szosowej i czasowej, sztywność węzła suportu i limit wagowy UCI 6.80 kg.';
      case EquipmentSponsorCategory.wheels:
        return 'Wysokość stożka aero (30-80mm), opory łożysk ceramicznych piast oraz pełne dyski karbonowe na czasówki.';
      case EquipmentSponsorCategory.groupsetAndPower:
        return 'Sprawność mechaniczna łańcucha (W), prędkość zmiany przełożeń Di2/AXS oraz dwustronna telemetria mocy ±0.5%.';
      case EquipmentSponsorCategory.helmetsAndEyewear:
        return 'Kaski teardrop z wizjerem zyskujące waty na czasówkach oraz soczewki fotochromowe chroniące wzrok w deszczu.';
      case EquipmentSponsorCategory.apparel:
        return 'Kombinezony aerodynamiczne ze strukturą prążkowaną vortex sleeves (-15 do -25W) oraz kurtki termo-ochronne.';
      case EquipmentSponsorCategory.nutrition:
        return 'Maltodekstryna z fruktozą w formule 1:0.8 absorbująca 90-120g węgli/h bez ryzyka skurczów i problemów żołądkowych.';
    }
  }
}

/// Status reakcji kontrahenta technicznego w negocjacjach przetargowych.
enum TenderNegotiationReaction {
  /// Kontroferta menedżera zaakceptowana bez zastrzeżeń
  accepted,

  /// Sponsor składa kompromisową propozycję pośrednią
  counterOffered,

  /// Żądania odrzucone, pierwotna oferta pozostaje na stole
  rejected,

  /// Żądania były zbyt wysokie i sponsor zerwał negocjacje (wycofał ofertę)
  withdrawn;

  String toJson() => name;

  static TenderNegotiationReaction fromJson(String value) {
    return TenderNegotiationReaction.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TenderNegotiationReaction.rejected,
    );
  }
}

/// Zestaw parametrów technicznych kół wyścigowych.
class WheelsetTechnicalPerks {
  final double aeroCdAReduction; // Redukcja współczynnika oporu czołowego [m²] (np. 0.010 - 0.016 m²)
  final double rollingResistanceWattsSaved; // Zysk na łożyskach ceramicznych i technologii tubeless [W]
  final int crosswindStabilityScore; // Odporność na podmuchy bocznego wiatru (1-100)
  final int climbingWeightSavingGrams; // Oszczędność wagi kompletu kół w gramach
  final int annualFreeWheelsetsPool; // Pula darmowych kompletów kół na sezon (np. 80-140)
  final bool includesTtDiscWheel; // Czy umowa gwarantuje pełne karbonowe dyski na próby czasowe

  const WheelsetTechnicalPerks({
    required this.aeroCdAReduction,
    required this.rollingResistanceWattsSaved,
    required this.crosswindStabilityScore,
    required this.climbingWeightSavingGrams,
    required this.annualFreeWheelsetsPool,
    required this.includesTtDiscWheel,
  });

  Map<String, dynamic> toJson() => {
        'aeroCdAReduction': aeroCdAReduction,
        'rollingResistanceWattsSaved': rollingResistanceWattsSaved,
        'crosswindStabilityScore': crosswindStabilityScore,
        'climbingWeightSavingGrams': climbingWeightSavingGrams,
        'annualFreeWheelsetsPool': annualFreeWheelsetsPool,
        'includesTtDiscWheel': includesTtDiscWheel,
      };

  factory WheelsetTechnicalPerks.fromJson(Map<String, dynamic> json) {
    return WheelsetTechnicalPerks(
      aeroCdAReduction: (json['aeroCdAReduction'] as num).toDouble(),
      rollingResistanceWattsSaved:
          (json['rollingResistanceWattsSaved'] as num).toDouble(),
      crosswindStabilityScore: (json['crosswindStabilityScore'] as num).toInt(),
      climbingWeightSavingGrams:
          (json['climbingWeightSavingGrams'] as num).toInt(),
      annualFreeWheelsetsPool: (json['annualFreeWheelsetsPool'] as num).toInt(),
      includesTtDiscWheel: json['includesTtDiscWheel'] as bool? ?? true,
    );
  }
}

/// Zestaw parametrów technicznych grup napędowych i mierników mocy.
class GroupsetTechnicalPerks {
  final double drivetrainEfficiency; // Sprawność układu napędowego (np. 0.985 vs 0.974 daje ~3-5W zysku)
  final int shiftLatencyMs; // Czas zmiany biegu pod pełnym obciążeniem (ms)
  final double chainDropRiskReductionPct; // Redukcja ryzyka spadnięcia łańcucha na brukach [%]
  final double powerMeterAccuracyPct; // Precyzja pomiaru mocy (np. ±0.5% lub ±1.0%)
  final bool dualSidedTorqueTelemetry; // Czy miernik analizuje niezależny bilans lewa/prawa noga i moment obrotowy
  final int annualFreeGroupsetsPool; // Pula kompletnych grup osprzętu na sezon

  const GroupsetTechnicalPerks({
    required this.drivetrainEfficiency,
    required this.shiftLatencyMs,
    required this.chainDropRiskReductionPct,
    required this.powerMeterAccuracyPct,
    required this.dualSidedTorqueTelemetry,
    required this.annualFreeGroupsetsPool,
  });

  Map<String, dynamic> toJson() => {
        'drivetrainEfficiency': drivetrainEfficiency,
        'shiftLatencyMs': shiftLatencyMs,
        'chainDropRiskReductionPct': chainDropRiskReductionPct,
        'powerMeterAccuracyPct': powerMeterAccuracyPct,
        'dualSidedTorqueTelemetry': dualSidedTorqueTelemetry,
        'annualFreeGroupsetsPool': annualFreeGroupsetsPool,
      };

  factory GroupsetTechnicalPerks.fromJson(Map<String, dynamic> json) {
    return GroupsetTechnicalPerks(
      drivetrainEfficiency: (json['drivetrainEfficiency'] as num).toDouble(),
      shiftLatencyMs: (json['shiftLatencyMs'] as num).toInt(),
      chainDropRiskReductionPct:
          (json['chainDropRiskReductionPct'] as num).toDouble(),
      powerMeterAccuracyPct: (json['powerMeterAccuracyPct'] as num).toDouble(),
      dualSidedTorqueTelemetry: json['dualSidedTorqueTelemetry'] as bool? ?? true,
      annualFreeGroupsetsPool:
          (json['annualFreeGroupsetsPool'] as num).toInt(),
    );
  }
}

/// Zestaw parametrów kasków aero i optyki sportowej.
class HelmetsAndEyewearTechnicalPerks {
  final double ttHelmetAeroWattSavings; // Zysk aerodynamiczny kasku czasowego przy 50 km/h [W] (np. 8.5 - 14.0W)
  final double roadHelmetVentilationEfficiencyPct; // Skuteczność chłodzenia głowy chroniąca przed przegrzaniem w upale [%]
  final int eyewearOpticsContrastRating; // Ocena kontrastu soczewek w cieniu i ulewie (1-100, bonus do bikeHandling)
  final int crashProtectionSafetyFactor; // Bezpieczeństwo powłoki kasku i redukcja urazów mózgu (1-100)
  final int annualFreeHelmetsCount; // Liczba dostarczanych kasków szosowych i czasowych na sezon

  const HelmetsAndEyewearTechnicalPerks({
    required this.ttHelmetAeroWattSavings,
    required this.roadHelmetVentilationEfficiencyPct,
    required this.eyewearOpticsContrastRating,
    required this.crashProtectionSafetyFactor,
    required this.annualFreeHelmetsCount,
  });

  Map<String, dynamic> toJson() => {
        'ttHelmetAeroWattSavings': ttHelmetAeroWattSavings,
        'roadHelmetVentilationEfficiencyPct':
            roadHelmetVentilationEfficiencyPct,
        'eyewearOpticsContrastRating': eyewearOpticsContrastRating,
        'crashProtectionSafetyFactor': crashProtectionSafetyFactor,
        'annualFreeHelmetsCount': annualFreeHelmetsCount,
      };

  factory HelmetsAndEyewearTechnicalPerks.fromJson(Map<String, dynamic> json) {
    return HelmetsAndEyewearTechnicalPerks(
      ttHelmetAeroWattSavings:
          (json['ttHelmetAeroWattSavings'] as num).toDouble(),
      roadHelmetVentilationEfficiencyPct:
          (json['roadHelmetVentilationEfficiencyPct'] as num).toDouble(),
      eyewearOpticsContrastRating:
          (json['eyewearOpticsContrastRating'] as num).toInt(),
      crashProtectionSafetyFactor:
          (json['crashProtectionSafetyFactor'] as num).toInt(),
      annualFreeHelmetsCount:
          (json['annualFreeHelmetsCount'] as num).toInt(),
    );
  }
}

/// Zestaw parametrów odzieży kolarskiej i kombinezonów czasowych (Real Watt Savings).
class ApparelTechnicalPerks {
  final double ttSkinsuitWattSavings; // Realny zysk kombinezonu czasowego w watach przy 50 km/h [W] (np. 16.0 - 24.5W!)
  final double roadAeroJerseyWattSavings; // Zysk koszulki aero w ucieczkach i finiszach przy 45 km/h [W]
  final int badWeatherThermalProtectionScore; // Skuteczność membran hydrofobowych w deszczu i chłodzie (1-100)
  final int antiChafingComfortScore; // Ochrona przed otarciami na etapach >200km (1-100)
  final int customWindTunnelFittingsCount; // Liczba dedykowanych sesji dopasowania kroju w tunelu dla liderów

  const ApparelTechnicalPerks({
    required this.ttSkinsuitWattSavings,
    required this.roadAeroJerseyWattSavings,
    required this.badWeatherThermalProtectionScore,
    required this.antiChafingComfortScore,
    required this.customWindTunnelFittingsCount,
  });

  Map<String, dynamic> toJson() => {
        'ttSkinsuitWattSavings': ttSkinsuitWattSavings,
        'roadAeroJerseyWattSavings': roadAeroJerseyWattSavings,
        'badWeatherThermalProtectionScore':
            badWeatherThermalProtectionScore,
        'antiChafingComfortScore': antiChafingComfortScore,
        'customWindTunnelFittingsCount': customWindTunnelFittingsCount,
      };

  factory ApparelTechnicalPerks.fromJson(Map<String, dynamic> json) {
    return ApparelTechnicalPerks(
      ttSkinsuitWattSavings: (json['ttSkinsuitWattSavings'] as num).toDouble(),
      roadAeroJerseyWattSavings:
          (json['roadAeroJerseyWattSavings'] as num).toDouble(),
      badWeatherThermalProtectionScore:
          (json['badWeatherThermalProtectionScore'] as num).toInt(),
      antiChafingComfortScore:
          (json['antiChafingComfortScore'] as num).toInt(),
      customWindTunnelFittingsCount:
          (json['customWindTunnelFittingsCount'] as num).toInt(),
    );
  }
}

/// Zestaw parametrów żywienia sportowego i technologii żeli węglowodanowych (120g/h).
class NutritionTechnicalPerks {
  final int maxCarbIntakeGramsPerHour; // Maksymalna wchłanialność węglowodanów na godzinę (np. 90-120g/h)
  final double giDistressRiskPct; // Prawdopodobieństwo problemów żołądkowo-jelitowych i mdłości [%] (np. 0.2 - 2.0%)
  final int electrolytePlasmaBufferScore; // Równowaga elektrolitowa chroniąca przed spadkiem mocy w upale (1-100)
  final double glycogenRecoverySpeedupPct; // Przyspieszenie resyntezy glikogenu po wyczerpującym etapie [%]
  final int annualNutritionUnitsProvided; // Liczba dostarczanych żeli hydrogel, batonów i napojów izotonicznych na sezon

  const NutritionTechnicalPerks({
    required this.maxCarbIntakeGramsPerHour,
    required this.giDistressRiskPct,
    required this.electrolytePlasmaBufferScore,
    required this.glycogenRecoverySpeedupPct,
    required this.annualNutritionUnitsProvided,
  });

  Map<String, dynamic> toJson() => {
        'maxCarbIntakeGramsPerHour': maxCarbIntakeGramsPerHour,
        'giDistressRiskPct': giDistressRiskPct,
        'electrolytePlasmaBufferScore': electrolytePlasmaBufferScore,
        'glycogenRecoverySpeedupPct': glycogenRecoverySpeedupPct,
        'annualNutritionUnitsProvided': annualNutritionUnitsProvided,
      };

  factory NutritionTechnicalPerks.fromJson(Map<String, dynamic> json) {
    return NutritionTechnicalPerks(
      maxCarbIntakeGramsPerHour:
          (json['maxCarbIntakeGramsPerHour'] as num).toInt(),
      giDistressRiskPct: (json['giDistressRiskPct'] as num).toDouble(),
      electrolytePlasmaBufferScore:
          (json['electrolytePlasmaBufferScore'] as num).toInt(),
      glycogenRecoverySpeedupPct:
          (json['glycogenRecoverySpeedupPct'] as num).toDouble(),
      annualNutritionUnitsProvided:
          (json['annualNutritionUnitsProvided'] as num).toInt(),
    );
  }
}

/// Oferta kontraktowa złożona przez producenta w przetargu technicznym.
class TechnicalContractOffer {
  final String id;
  final EquipmentSponsorCategory category;
  final String brandId;
  final String brandName;
  final int prestigeStars; // 1-5 gwiazdek
  final String countryIso;
  final int annualCashContributionEur; // Roczna dopłata gotówkowa sponsora do budżetu
  final int equipmentMarketValueEur; // Szacunkowa rynkowa wartość darmowego sprzętu/produktów na sezon
  final int contractDurationYears; // Czas trwania umowy (1-3 lata)
  final TeamDivision minimumTeamDivision; // Wymagana minimalna dywizja zespołu
  final int minimumUciRank; // Wymagana pozycja w rankingu UCI
  final Map<String, int> performanceBonuses; // Premie wynikowe (np. wygrana etapu Tour de France, tęczowa koszulka TT)
  final Map<String, dynamic> perksJson; // Szczegółowe parametry techniczne w formacie JSON
  final String pitchDescription; // Tekst marketingowy i argumentacja oferty
  final bool proprietaryWheelsMandatory; // Jeśli oferta ram: czy wymusza koła własnej marki (np. Specialized -> Roval)
  final String? proprietaryWheelBrandName;

  const TechnicalContractOffer({
    required this.id,
    required this.category,
    required this.brandId,
    required this.brandName,
    required this.prestigeStars,
    required this.countryIso,
    required this.annualCashContributionEur,
    required this.equipmentMarketValueEur,
    required this.contractDurationYears,
    required this.minimumTeamDivision,
    required this.minimumUciRank,
    required this.performanceBonuses,
    required this.perksJson,
    required this.pitchDescription,
    this.proprietaryWheelsMandatory = false,
    this.proprietaryWheelBrandName,
  });

  WheelsetTechnicalPerks? get wheelsetPerks =>
      category == EquipmentSponsorCategory.wheels
          ? WheelsetTechnicalPerks.fromJson(perksJson)
          : null;

  GroupsetTechnicalPerks? get groupsetPerks =>
      category == EquipmentSponsorCategory.groupsetAndPower
          ? GroupsetTechnicalPerks.fromJson(perksJson)
          : null;

  HelmetsAndEyewearTechnicalPerks? get helmetsEyewearPerks =>
      category == EquipmentSponsorCategory.helmetsAndEyewear
          ? HelmetsAndEyewearTechnicalPerks.fromJson(perksJson)
          : null;

  ApparelTechnicalPerks? get apparelPerks =>
      category == EquipmentSponsorCategory.apparel
          ? ApparelTechnicalPerks.fromJson(perksJson)
          : null;

  NutritionTechnicalPerks? get nutritionPerks =>
      category == EquipmentSponsorCategory.nutrition
          ? NutritionTechnicalPerks.fromJson(perksJson)
          : null;

  TechnicalContractOffer copyWith({
    String? id,
    EquipmentSponsorCategory? category,
    String? brandId,
    String? brandName,
    int? prestigeStars,
    String? countryIso,
    int? annualCashContributionEur,
    int? equipmentMarketValueEur,
    int? contractDurationYears,
    TeamDivision? minimumTeamDivision,
    int? minimumUciRank,
    Map<String, int>? performanceBonuses,
    Map<String, dynamic>? perksJson,
    String? pitchDescription,
    bool? proprietaryWheelsMandatory,
    String? proprietaryWheelBrandName,
  }) {
    return TechnicalContractOffer(
      id: id ?? this.id,
      category: category ?? this.category,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      prestigeStars: prestigeStars ?? this.prestigeStars,
      countryIso: countryIso ?? this.countryIso,
      annualCashContributionEur:
          annualCashContributionEur ?? this.annualCashContributionEur,
      equipmentMarketValueEur:
          equipmentMarketValueEur ?? this.equipmentMarketValueEur,
      contractDurationYears:
          contractDurationYears ?? this.contractDurationYears,
      minimumTeamDivision: minimumTeamDivision ?? this.minimumTeamDivision,
      minimumUciRank: minimumUciRank ?? this.minimumUciRank,
      performanceBonuses: performanceBonuses != null
          ? Map<String, int>.unmodifiable(performanceBonuses)
          : this.performanceBonuses,
      perksJson: perksJson != null
          ? Map<String, dynamic>.unmodifiable(perksJson)
          : this.perksJson,
      pitchDescription: pitchDescription ?? this.pitchDescription,
      proprietaryWheelsMandatory:
          proprietaryWheelsMandatory ?? this.proprietaryWheelsMandatory,
      proprietaryWheelBrandName:
          proprietaryWheelBrandName ?? this.proprietaryWheelBrandName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.toJson(),
        'brandId': brandId,
        'brandName': brandName,
        'prestigeStars': prestigeStars,
        'countryIso': countryIso,
        'annualCashContributionEur': annualCashContributionEur,
        'equipmentMarketValueEur': equipmentMarketValueEur,
        'contractDurationYears': contractDurationYears,
        'minimumTeamDivision': minimumTeamDivision.toJson(),
        'minimumUciRank': minimumUciRank,
        'performanceBonuses': performanceBonuses,
        'perksJson': perksJson,
        'pitchDescription': pitchDescription,
        'proprietaryWheelsMandatory': proprietaryWheelsMandatory,
        'proprietaryWheelBrandName': proprietaryWheelBrandName,
      };

  factory TechnicalContractOffer.fromJson(Map<String, dynamic> json) {
    return TechnicalContractOffer(
      id: json['id'] as String,
      category: EquipmentSponsorCategory.fromJson(json['category'] as String),
      brandId: json['brandId'] as String,
      brandName: json['brandName'] as String,
      prestigeStars: (json['prestigeStars'] as num).toInt(),
      countryIso: json['countryIso'] as String,
      annualCashContributionEur:
          (json['annualCashContributionEur'] as num).toInt(),
      equipmentMarketValueEur: (json['equipmentMarketValueEur'] as num).toInt(),
      contractDurationYears: (json['contractDurationYears'] as num).toInt(),
      minimumTeamDivision:
          TeamDivision.values.firstWhere((d) => d.name == json['minimumTeamDivision']),
      minimumUciRank: (json['minimumUciRank'] as num).toInt(),
      performanceBonuses: (json['performanceBonuses'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      perksJson: Map<String, dynamic>.from(json['perksJson'] as Map),
      pitchDescription: json['pitchDescription'] as String,
      proprietaryWheelsMandatory:
          json['proprietaryWheelsMandatory'] as bool? ?? false,
      proprietaryWheelBrandName: json['proprietaryWheelBrandName'] as String?,
    );
  }
}

/// Aktywny podpisany kontrakt techniczny w danej kategorii sprzętu.
class ActiveTechnicalContract {
  final String id;
  final EquipmentSponsorCategory category;
  final String brandId;
  final String brandName;
  final int annualCashContributionEur;
  final int contractYearsTotal;
  final int contractYearsRemaining;
  final int signedSeasonYear;
  final Map<String, int> performanceBonuses;
  final Map<String, dynamic> perksJson;

  const ActiveTechnicalContract({
    required this.id,
    required this.category,
    required this.brandId,
    required this.brandName,
    required this.annualCashContributionEur,
    required this.contractYearsTotal,
    required this.contractYearsRemaining,
    required this.signedSeasonYear,
    required this.performanceBonuses,
    required this.perksJson,
  });

  bool get isExpiring => contractYearsRemaining <= 1;

  WheelsetTechnicalPerks? get wheelsetPerks =>
      category == EquipmentSponsorCategory.wheels
          ? WheelsetTechnicalPerks.fromJson(perksJson)
          : null;

  GroupsetTechnicalPerks? get groupsetPerks =>
      category == EquipmentSponsorCategory.groupsetAndPower
          ? GroupsetTechnicalPerks.fromJson(perksJson)
          : null;

  HelmetsAndEyewearTechnicalPerks? get helmetsEyewearPerks =>
      category == EquipmentSponsorCategory.helmetsAndEyewear
          ? HelmetsAndEyewearTechnicalPerks.fromJson(perksJson)
          : null;

  ApparelTechnicalPerks? get apparelPerks =>
      category == EquipmentSponsorCategory.apparel
          ? ApparelTechnicalPerks.fromJson(perksJson)
          : null;

  NutritionTechnicalPerks? get nutritionPerks =>
      category == EquipmentSponsorCategory.nutrition
          ? NutritionTechnicalPerks.fromJson(perksJson)
          : null;

  ActiveTechnicalContract copyWith({
    String? id,
    EquipmentSponsorCategory? category,
    String? brandId,
    String? brandName,
    int? annualCashContributionEur,
    int? contractYearsTotal,
    int? contractYearsRemaining,
    int? signedSeasonYear,
    Map<String, int>? performanceBonuses,
    Map<String, dynamic>? perksJson,
  }) {
    return ActiveTechnicalContract(
      id: id ?? this.id,
      category: category ?? this.category,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      annualCashContributionEur:
          annualCashContributionEur ?? this.annualCashContributionEur,
      contractYearsTotal: contractYearsTotal ?? this.contractYearsTotal,
      contractYearsRemaining:
          contractYearsRemaining ?? this.contractYearsRemaining,
      signedSeasonYear: signedSeasonYear ?? this.signedSeasonYear,
      performanceBonuses: performanceBonuses != null
          ? Map<String, int>.unmodifiable(performanceBonuses)
          : this.performanceBonuses,
      perksJson: perksJson != null
          ? Map<String, dynamic>.unmodifiable(perksJson)
          : this.perksJson,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.toJson(),
        'brandId': brandId,
        'brandName': brandName,
        'annualCashContributionEur': annualCashContributionEur,
        'contractYearsTotal': contractYearsTotal,
        'contractYearsRemaining': contractYearsRemaining,
        'signedSeasonYear': signedSeasonYear,
        'performanceBonuses': performanceBonuses,
        'perksJson': perksJson,
      };

  factory ActiveTechnicalContract.fromJson(Map<String, dynamic> json) {
    return ActiveTechnicalContract(
      id: json['id'] as String,
      category: EquipmentSponsorCategory.fromJson(json['category'] as String),
      brandId: json['brandId'] as String,
      brandName: json['brandName'] as String,
      annualCashContributionEur:
          (json['annualCashContributionEur'] as num).toInt(),
      contractYearsTotal: (json['contractYearsTotal'] as num).toInt(),
      contractYearsRemaining: (json['contractYearsRemaining'] as num).toInt(),
      signedSeasonYear: (json['signedSeasonYear'] as num).toInt(),
      performanceBonuses: (json['performanceBonuses'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      perksJson: Map<String, dynamic>.from(json['perksJson'] as Map),
    );
  }
}

/// Raport polityki producenta ram w sprawie kół (czy producent wymusza własne koła).
class ProprietaryWheelsPolicy {
  final bool isRestricted;
  final String frameManufacturerName;
  final String? proprietaryWheelBrand;
  final String explanation;

  const ProprietaryWheelsPolicy({
    required this.isRestricted,
    required this.frameManufacturerName,
    this.proprietaryWheelBrand,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'isRestricted': isRestricted,
        'frameManufacturerName': frameManufacturerName,
        'proprietaryWheelBrand': proprietaryWheelBrand,
        'explanation': explanation,
      };

  factory ProprietaryWheelsPolicy.fromJson(Map<String, dynamic> json) {
    return ProprietaryWheelsPolicy(
      isRestricted: json['isRestricted'] as bool,
      frameManufacturerName: json['frameManufacturerName'] as String,
      proprietaryWheelBrand: json['proprietaryWheelBrand'] as String?,
      explanation: json['explanation'] as String,
    );
  }
}

/// Zestaw wszystkich aktywnych umów technicznych drużyny (Portfolio Sprzętowe).
class TeamTechnicalPortfolio {
  final BikeManufacturerDeal frameDeal;
  final ActiveTechnicalContract? wheelsContract;
  final ActiveTechnicalContract? groupsetContract;
  final ActiveTechnicalContract? helmetsEyewearContract;
  final ActiveTechnicalContract? apparelContract;
  final ActiveTechnicalContract? nutritionContract;

  const TeamTechnicalPortfolio({
    required this.frameDeal,
    this.wheelsContract,
    this.groupsetContract,
    this.helmetsEyewearContract,
    this.apparelContract,
    this.nutritionContract,
  });

  /// Czy producent ram wymusza własną markę kół (np. Specialized -> Roval, Giant -> Cadex, Trek -> Bontrager)
  bool get enforcesProprietaryWheels {
    final name = frameDeal.manufacturerName.toLowerCase();
    final id = frameDeal.manufacturerId.toLowerCase();
    return name.contains('specialized') ||
        id.contains('specialized') ||
        name.contains('trek') ||
        id.contains('trek') ||
        name.contains('giant') ||
        id.contains('giant') ||
        name.contains('cadex') ||
        name.contains('roval');
  }

  /// Nazwa marki kół zintegrowanych z producentem ram
  String? get proprietaryWheelBrandName {
    final name = frameDeal.manufacturerName.toLowerCase();
    if (name.contains('specialized')) return 'Roval (Specialized Works)';
    if (name.contains('trek')) return 'Bontrager Aeolus RSL';
    if (name.contains('giant')) return 'Cadex Ultra Carbon';
    return null;
  }

  /// Łączna suma rocznych wpływów gotówkowych ze wszystkich sponsoringów technicznych [EUR]
  int get totalAnnualCashContributionEur {
    int total = frameDeal.annualCashContributionEur;
    if (wheelsContract != null) {
      total += wheelsContract!.annualCashContributionEur;
    }
    if (groupsetContract != null) {
      total += groupsetContract!.annualCashContributionEur;
    }
    if (helmetsEyewearContract != null) {
      total += helmetsEyewearContract!.annualCashContributionEur;
    }
    if (apparelContract != null) {
      total += apparelContract!.annualCashContributionEur;
    }
    if (nutritionContract != null) {
      total += nutritionContract!.annualCashContributionEur;
    }
    return total;
  }

  /// Efektywna wchłanialność węglowodanów na godzinę (g/h)
  int get effectiveCarbIntakePerHourGrams {
    return nutritionContract?.nutritionPerks?.maxCarbIntakeGramsPerHour ?? 60;
  }

  /// Prawdopodobieństwo problemów żołądkowo-jelitowych pod intensywnym wysiłkiem
  double get effectiveGiDistressRisk {
    return nutritionContract?.nutritionPerks?.giDistressRiskPct ?? 15.0;
  }

  /// Sumaryczny szacowany zysk mocy w watach w jeździe indywidualnej na czas (ITT) przy 50 km/h
  double calculateTotalTtWattSavings() {
    double total = 0.0;

    // 1. Kombinezon czasowy aero (np. Bioracer / Castelli / Rule 28)
    final apparel = apparelContract?.apparelPerks;
    if (apparel != null) {
      total += apparel.ttSkinsuitWattSavings;
    } else {
      total += 5.0; // Standardowy strój
    }

    // 2. Kask czasowy aero teardrop z wizjerem
    final helmet = helmetsEyewearContract?.helmetsEyewearPerks;
    if (helmet != null) {
      total += helmet.ttHelmetAeroWattSavings;
    } else {
      total += 3.0; // Standardowy kask
    }

    // 3. Koła czasowe (Dysk TT + wysoki stożek + łożyska ceramiczne)
    final wheels = wheelsContract?.wheelsetPerks;
    if (wheels != null) {
      // Zamiana redukcji CdA na waty przy 50 km/h (13.88 m/s): P = 0.5 * rho * v^3 * deltaCdA
      // Przy rho=1.205 kg/m^3 i v=13.89 m/s, mnożnik to około 1610 W / m^2 CdA
      total += (wheels.aeroCdAReduction * 1600.0) + wheels.rollingResistanceWattsSaved;
    } else if (enforcesProprietaryWheels) {
      total += 8.5; // Przyzwoity zysk fabrycznych kół Roval / Cadex
    }

    // 4. Sprawność mechaniczna napędu
    final groupset = groupsetContract?.groupsetPerks;
    if (groupset != null) {
      // Sprawność 98.6% vs 97.4% przy mocy progowej 400W na czasówce daje 4.8W
      total += (groupset.drivetrainEfficiency - 0.974) * 400.0;
    }

    return double.parse(total.toStringAsFixed(1));
  }

  TeamTechnicalPortfolio copyWith({
    BikeManufacturerDeal? frameDeal,
    ActiveTechnicalContract? wheelsContract,
    ActiveTechnicalContract? groupsetContract,
    ActiveTechnicalContract? helmetsEyewearContract,
    ActiveTechnicalContract? apparelContract,
    ActiveTechnicalContract? nutritionContract,
  }) {
    return TeamTechnicalPortfolio(
      frameDeal: frameDeal ?? this.frameDeal,
      wheelsContract: wheelsContract ?? this.wheelsContract,
      groupsetContract: groupsetContract ?? this.groupsetContract,
      helmetsEyewearContract:
          helmetsEyewearContract ?? this.helmetsEyewearContract,
      apparelContract: apparelContract ?? this.apparelContract,
      nutritionContract: nutritionContract ?? this.nutritionContract,
    );
  }

  Map<String, dynamic> toJson() => {
        'frameDeal': frameDeal.toJson(),
        'wheelsContract': wheelsContract?.toJson(),
        'groupsetContract': groupsetContract?.toJson(),
        'helmetsEyewearContract': helmetsEyewearContract?.toJson(),
        'apparelContract': apparelContract?.toJson(),
        'nutritionContract': nutritionContract?.toJson(),
      };

  factory TeamTechnicalPortfolio.fromJson(Map<String, dynamic> json) {
    return TeamTechnicalPortfolio(
      frameDeal:
          BikeManufacturerDeal.fromJson(json['frameDeal'] as Map<String, dynamic>),
      wheelsContract: json['wheelsContract'] != null
          ? ActiveTechnicalContract.fromJson(
              json['wheelsContract'] as Map<String, dynamic>)
          : null,
      groupsetContract: json['groupsetContract'] != null
          ? ActiveTechnicalContract.fromJson(
              json['groupsetContract'] as Map<String, dynamic>)
          : null,
      helmetsEyewearContract: json['helmetsEyewearContract'] != null
          ? ActiveTechnicalContract.fromJson(
              json['helmetsEyewearContract'] as Map<String, dynamic>)
          : null,
      apparelContract: json['apparelContract'] != null
          ? ActiveTechnicalContract.fromJson(
              json['apparelContract'] as Map<String, dynamic>)
          : null,
      nutritionContract: json['nutritionContract'] != null
          ? ActiveTechnicalContract.fromJson(
              json['nutritionContract'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Rezultat negocjacji oferty ze sponsorem technicznym.
class TenderNegotiationResult {
  final TenderNegotiationReaction reaction;
  final TechnicalContractOffer originalOffer;
  final TechnicalContractOffer? revisedOffer;
  final String sponsorCommentary;
  final int roundsRemaining;

  const TenderNegotiationResult({
    required this.reaction,
    required this.originalOffer,
    this.revisedOffer,
    required this.sponsorCommentary,
    required this.roundsRemaining,
  });

  bool get isAccepted => reaction == TenderNegotiationReaction.accepted;
  bool get isCounterOffered => reaction == TenderNegotiationReaction.counterOffered;
  bool get isRejected => reaction == TenderNegotiationReaction.rejected;
  bool get isWithdrawn => reaction == TenderNegotiationReaction.withdrawn;

  Map<String, dynamic> toJson() => {
        'reaction': reaction.toJson(),
        'originalOffer': originalOffer.toJson(),
        'revisedOffer': revisedOffer?.toJson(),
        'sponsorCommentary': sponsorCommentary,
        'roundsRemaining': roundsRemaining,
      };
}

/// Aktywna sesja przetargowa prowadzona pod koniec sezonu (październik / listopad).
class EquipmentTenderSession {
  final int seasonYear;
  final String teamId;
  final TeamTechnicalPortfolio currentPortfolio;
  final Map<EquipmentSponsorCategory, List<TechnicalContractOffer>> availableOffersByCategory;
  final Map<EquipmentSponsorCategory, ActiveTechnicalContract> signedContracts;
  final int negotiationRoundsRemaining;
  final bool isConcluded;

  const EquipmentTenderSession({
    required this.seasonYear,
    required this.teamId,
    required this.currentPortfolio,
    required this.availableOffersByCategory,
    required this.signedContracts,
    required this.negotiationRoundsRemaining,
    required this.isConcluded,
  });

  EquipmentTenderSession copyWith({
    int? seasonYear,
    String? teamId,
    TeamTechnicalPortfolio? currentPortfolio,
    Map<EquipmentSponsorCategory, List<TechnicalContractOffer>>?
        availableOffersByCategory,
    Map<EquipmentSponsorCategory, ActiveTechnicalContract>? signedContracts,
    int? negotiationRoundsRemaining,
    bool? isConcluded,
  }) {
    return EquipmentTenderSession(
      seasonYear: seasonYear ?? this.seasonYear,
      teamId: teamId ?? this.teamId,
      currentPortfolio: currentPortfolio ?? this.currentPortfolio,
      availableOffersByCategory: availableOffersByCategory ??
          this.availableOffersByCategory,
      signedContracts: signedContracts ?? this.signedContracts,
      negotiationRoundsRemaining:
          negotiationRoundsRemaining ?? this.negotiationRoundsRemaining,
      isConcluded: isConcluded ?? this.isConcluded,
    );
  }

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'teamId': teamId,
        'currentPortfolio': currentPortfolio.toJson(),
        'availableOffersByCategory': availableOffersByCategory.map(
          (k, v) => MapEntry(k.name, v.map((o) => o.toJson()).toList()),
        ),
        'signedContracts': signedContracts.map(
          (k, v) => MapEntry(k.name, v.toJson()),
        ),
        'negotiationRoundsRemaining': negotiationRoundsRemaining,
        'isConcluded': isConcluded,
      };

  factory EquipmentTenderSession.fromJson(Map<String, dynamic> json) {
    final offersMap = <EquipmentSponsorCategory, List<TechnicalContractOffer>>{};
    final rawOffers =
        json['availableOffersByCategory'] as Map<String, dynamic>? ?? {};
    rawOffers.forEach((k, v) {
      final cat = EquipmentSponsorCategory.fromJson(k);
      final list = (v as List<dynamic>)
          .map((e) => TechnicalContractOffer.fromJson(e as Map<String, dynamic>))
          .toList();
      offersMap[cat] = list;
    });

    final signedMap = <EquipmentSponsorCategory, ActiveTechnicalContract>{};
    final rawSigned = json['signedContracts'] as Map<String, dynamic>? ?? {};
    rawSigned.forEach((k, v) {
      final cat = EquipmentSponsorCategory.fromJson(k);
      signedMap[cat] =
          ActiveTechnicalContract.fromJson(v as Map<String, dynamic>);
    });

    return EquipmentTenderSession(
      seasonYear: (json['seasonYear'] as num).toInt(),
      teamId: json['teamId'] as String,
      currentPortfolio: TeamTechnicalPortfolio.fromJson(
          json['currentPortfolio'] as Map<String, dynamic>),
      availableOffersByCategory: offersMap,
      signedContracts: signedMap,
      negotiationRoundsRemaining:
          (json['negotiationRoundsRemaining'] as num).toInt(),
      isConcluded: json['isConcluded'] as bool? ?? false,
    );
  }
}

/// Raport korzyści mocy watów w wyścigu z podziałem na komponenty.
class EquipmentWattAdvantageReport {
  final double totalWattsSaved;
  final double cdaDeltaSquareMeters;
  final Map<String, double> componentBreakdown;
  final String engineeringSummary;

  const EquipmentWattAdvantageReport({
    required this.totalWattsSaved,
    required this.cdaDeltaSquareMeters,
    required this.componentBreakdown,
    required this.engineeringSummary,
  });

  Map<String, dynamic> toJson() => {
        'totalWattsSaved': totalWattsSaved,
        'cdaDeltaSquareMeters': cdaDeltaSquareMeters,
        'componentBreakdown': componentBreakdown,
        'engineeringSummary': engineeringSummary,
      };
}

/// Raport żywieniowy i metaboliczny kolarza na trasie etapu.
class RaceNutritionPerformanceReport {
  final int targetCarbIntakePerHourGrams;
  final double giDistressRiskPercent;
  final double bonkRiskPercent;
  final double staminaRetentionPercent;
  final String nutritionistAssessment;

  const RaceNutritionPerformanceReport({
    required this.targetCarbIntakePerHourGrams,
    required this.giDistressRiskPercent,
    required this.bonkRiskPercent,
    required this.staminaRetentionPercent,
    required this.nutritionistAssessment,
  });

  Map<String, dynamic> toJson() => {
        'targetCarbIntakePerHourGrams': targetCarbIntakePerHourGrams,
        'giDistressRiskPercent': giDistressRiskPercent,
        'bonkRiskPercent': bonkRiskPercent,
        'staminaRetentionPercent': staminaRetentionPercent,
        'nutritionistAssessment': nutritionistAssessment,
      };
}

/// Główny silnik przetargów sprzętowych pod koniec sezonu (Equipment Sponsorship Bidding Engine).
class EquipmentSponsorshipBiddingEngine {
  EquipmentSponsorshipBiddingEngine._();

  /// 1. Sprawdza, czy producent ram wymusza własną markę kół (Proprietary Wheels Policy).
  static ProprietaryWheelsPolicy checkProprietaryWheelsPolicy({
    required BikeManufacturerDeal frameDeal,
  }) {
    final nameLower = frameDeal.manufacturerName.toLowerCase();
    final idLower = frameDeal.manufacturerId.toLowerCase();

    if (nameLower.contains('specialized') || idLower.contains('specialized')) {
      return const ProprietaryWheelsPolicy(
        isRestricted: true,
        frameManufacturerName: 'Specialized S-Works',
        proprietaryWheelBrand: 'Roval (Rapide CLX / Alpinist CLX)',
        explanation:
            'Umowa fabryczna ze Specialized wymaga wyłącznego stosowania kół marki Roval. Zespół nie może ogłosić osobnego przetargu na koła niezależne.',
      );
    }

    if (nameLower.contains('trek') || idLower.contains('trek')) {
      return const ProprietaryWheelsPolicy(
        isRestricted: true,
        frameManufacturerName: 'Trek Factory Racing',
        proprietaryWheelBrand: 'Bontrager (Aeolus RSL Carbon)',
        explanation:
            'Kontrakt sponsorski Trek nakłada klauzulę wyłączności na koła Bontrager. Osobny przetarg na koła jest zablokowany.',
      );
    }

    if (nameLower.contains('giant') || idLower.contains('giant') || nameLower.contains('cadex')) {
      return const ProprietaryWheelsPolicy(
        isRestricted: true,
        frameManufacturerName: 'Giant Bicycles',
        proprietaryWheelBrand: 'Cadex (Cadex 50 Ultra / TT Aero)',
        explanation:
            'Giant dostarcza zintegrowane komponenty Cadex. Stosowanie kół innych marek stanowi naruszenie umowy sponsorskiej.',
      );
    }

    // W przypadku innych producentów (Cervélo, Colnago, Pinarello, Factor, Canyon, Merida itp.)
    return ProprietaryWheelsPolicy(
      isRestricted: false,
      frameManufacturerName: frameDeal.manufacturerName,
      proprietaryWheelBrand: null,
      explanation:
          'Producent ${frameDeal.manufacturerName} pozwala na pełną swobodę techniczną i podpisanie niezależnego kontraktu na koła wyścigowe.',
    );
  }

  /// 2. Inicjuje przetarg sprzętowy pod koniec sezonu (październik / listopad).
  static EquipmentTenderSession openEndOfSeasonTender({
    required CyclingTeam team,
    required int seasonYear,
    TeamTechnicalPortfolio? currentPortfolio,
  }) {
    final portfolio = currentPortfolio ??
        TeamTechnicalPortfolio(
          frameDeal: team.bikeDeal,
        );

    final wheelsPolicy = checkProprietaryWheelsPolicy(frameDeal: portfolio.frameDeal);

    final offersByCategory = <EquipmentSponsorCategory, List<TechnicalContractOffer>>{};

    for (final category in EquipmentSponsorCategory.values) {
      if (category == EquipmentSponsorCategory.frames) {
        // Ramy są obsługiwane przez główny serwis producenta rowerów
        continue;
      }

      if (category == EquipmentSponsorCategory.wheels && wheelsPolicy.isRestricted) {
        // Koła są zablokowane przez politykę wyłączności producenta ram
        offersByCategory[category] = [];
        continue;
      }

      offersByCategory[category] = generateOffersForCategory(
        category: category,
        team: team,
        seasonYear: seasonYear,
      );
    }

    return EquipmentTenderSession(
      seasonYear: seasonYear,
      teamId: team.id,
      currentPortfolio: portfolio,
      availableOffersByCategory: offersByCategory,
      signedContracts: {},
      negotiationRoundsRemaining: 3,
      isConcluded: false,
    );
  }

  /// 3. Generuje oferty techniczne dla wybranej kategorii sprzętu.
  static List<TechnicalContractOffer> generateOffersForCategory({
    required EquipmentSponsorCategory category,
    required CyclingTeam team,
    required int seasonYear,
  }) {
    final isWorldTour = team.division == TeamDivision.worldTour;
    final isProTeam = team.division == TeamDivision.proTeam;

    switch (category) {
      case EquipmentSponsorCategory.wheels:
        return _generateWheelsetOffers(isWorldTour, isProTeam, seasonYear);
      case EquipmentSponsorCategory.groupsetAndPower:
        return _generateGroupsetOffers(isWorldTour, isProTeam, seasonYear);
      case EquipmentSponsorCategory.helmetsAndEyewear:
        return _generateHelmetsEyewearOffers(isWorldTour, isProTeam, seasonYear);
      case EquipmentSponsorCategory.apparel:
        return _generateApparelOffers(isWorldTour, isProTeam, seasonYear);
      case EquipmentSponsorCategory.nutrition:
        return _generateNutritionOffers(isWorldTour, isProTeam, seasonYear);
      case EquipmentSponsorCategory.frames:
        return [];
    }
  }

  // --- GENERATORY OFERT POSZCZEGÓLNYCH KATEGORII ---

  static List<TechnicalContractOffer> _generateWheelsetOffers(
      bool isWorldTour, bool isProTeam, int year) {
    return [
      TechnicalContractOffer(
        id: 'wheels_reserve_$year',
        category: EquipmentSponsorCategory.wheels,
        brandId: 'brand_reserve',
        brandName: 'Reserve Wheels (Aero Works)',
        prestigeStars: 5,
        countryIso: 'USA',
        annualCashContributionEur: isWorldTour ? 280000 : (isProTeam ? 140000 : 45000),
        equipmentMarketValueEur: 220000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.proTeam,
        minimumUciRank: 22,
        performanceBonuses: {'monument_win': 35000, 'grand_tour_stage': 15000},
        pitchDescription:
            'Opracowane w tunelu z inżynierami aerodynamics profile Turbulent Aero. Zapewniają -0.013 m² oporu czołowego oraz łożyska ceramiczne redukujące opory o 3.8 W.',
        perksJson: const WheelsetTechnicalPerks(
          aeroCdAReduction: 0.013,
          rollingResistanceWattsSaved: 3.8,
          crosswindStabilityScore: 92,
          climbingWeightSavingGrams: 320,
          annualFreeWheelsetsPool: 110,
          includesTtDiscWheel: true,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'wheels_vision_$year',
        category: EquipmentSponsorCategory.wheels,
        brandId: 'brand_vision',
        brandName: 'Vision Metron CarbonLab',
        prestigeStars: 4,
        countryIso: 'ITA',
        annualCashContributionEur: isWorldTour ? 320000 : (isProTeam ? 160000 : 50000),
        equipmentMarketValueEur: 240000,
        contractDurationYears: 3,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 30,
        performanceBonuses: {'tt_world_champ': 40000, 'grand_tour_podium': 30000},
        pitchDescription:
            'Metron 60 SL i dyski Metron TFW to sprawdzona broń w peletonie WorldTour. Oferujemy hojną dopłatę gotówkową i pełny serwis kół na każdym Grand Tourze.',
        perksJson: const WheelsetTechnicalPerks(
          aeroCdAReduction: 0.014,
          rollingResistanceWattsSaved: 3.2,
          crosswindStabilityScore: 86,
          climbingWeightSavingGrams: 280,
          annualFreeWheelsetsPool: 130,
          includesTtDiscWheel: true,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'wheels_princeton_$year',
        category: EquipmentSponsorCategory.wheels,
        brandId: 'brand_princeton',
        brandName: 'Princeton CarbonWorks',
        prestigeStars: 5,
        countryIso: 'USA',
        annualCashContributionEur: isWorldTour ? 240000 : (isProTeam ? 110000 : 30000),
        equipmentMarketValueEur: 260000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.proTeam,
        minimumUciRank: 18,
        performanceBonuses: {'monument_win': 45000, 'tt_stage_win': 25000},
        pitchDescription:
            'Sinusoidalny profil obręczy Wake 6560 i dyski Blur 633 zapewniają niezrównaną stabilność na bocznych podmuchach wiatru i zysk aerodynamiczny rzędu 0.015 m² CdA.',
        perksJson: const WheelsetTechnicalPerks(
          aeroCdAReduction: 0.015,
          rollingResistanceWattsSaved: 4.2,
          crosswindStabilityScore: 98,
          climbingWeightSavingGrams: 350,
          annualFreeWheelsetsPool: 90,
          includesTtDiscWheel: true,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'wheels_dtswiss_$year',
        category: EquipmentSponsorCategory.wheels,
        brandId: 'brand_dtswiss',
        brandName: 'DT Swiss ARC Racing',
        prestigeStars: 5,
        countryIso: 'SUI',
        annualCashContributionEur: isWorldTour ? 260000 : (isProTeam ? 130000 : 40000),
        equipmentMarketValueEur: 210000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 25,
        performanceBonuses: {'grand_tour_stage': 12000},
        pitchDescription:
            'Legendarna szwajcarska precyzja piast Ratchet EXP i koła ARC 1100 Dicut opracowane ze Swiss Side. Niemal zerowe opory toczenia i stuprocentowa niezawodność.',
        perksJson: const WheelsetTechnicalPerks(
          aeroCdAReduction: 0.012,
          rollingResistanceWattsSaved: 3.6,
          crosswindStabilityScore: 90,
          climbingWeightSavingGrams: 290,
          annualFreeWheelsetsPool: 120,
          includesTtDiscWheel: true,
        ).toJson(),
      ),
    ];
  }

  static List<TechnicalContractOffer> _generateGroupsetOffers(
      bool isWorldTour, bool isProTeam, int year) {
    return [
      TechnicalContractOffer(
        id: 'groupset_shimano_$year',
        category: EquipmentSponsorCategory.groupsetAndPower,
        brandId: 'brand_shimano',
        brandName: 'Shimano Dura-Ace Pro Works',
        prestigeStars: 5,
        countryIso: 'JPN',
        annualCashContributionEur: isWorldTour ? 450000 : (isProTeam ? 210000 : 70000),
        equipmentMarketValueEur: 350000,
        contractDurationYears: 3,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 28,
        performanceBonuses: {'monument_win': 30000, 'grand_tour_stage': 15000},
        pitchDescription:
            'Dura-Ace Di2 12-speed z miernikami FC-R9200-P. Sprawność napędu 98.7% (oszczędność 4W), zmiana biegów w 140ms i 95% redukcja ryzyka spadnięcia łańcucha na brukach.',
        perksJson: const GroupsetTechnicalPerks(
          drivetrainEfficiency: 0.987,
          shiftLatencyMs: 140,
          chainDropRiskReductionPct: 95.0,
          powerMeterAccuracyPct: 1.0,
          dualSidedTorqueTelemetry: true,
          annualFreeGroupsetsPool: 65,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'groupset_sram_$year',
        category: EquipmentSponsorCategory.groupsetAndPower,
        brandId: 'brand_sram',
        brandName: 'SRAM RED AXS & Quarq Lab',
        prestigeStars: 5,
        countryIso: 'USA',
        annualCashContributionEur: isWorldTour ? 520000 : (isProTeam ? 240000 : 80000),
        equipmentMarketValueEur: 380000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.proTeam,
        minimumUciRank: 20,
        performanceBonuses: {'monument_win': 40000, 'grand_tour_overall': 80000},
        pitchDescription:
            'W pełni bezprzewodowy napęd RED AXS z pomiarem mocy Quarq DZero (dokładność ±0.5%). Najwyższa dopłata budżetowa i zintegrowana telemetria obciążenia mięśniowego.',
        perksJson: const GroupsetTechnicalPerks(
          drivetrainEfficiency: 0.985,
          shiftLatencyMs: 160,
          chainDropRiskReductionPct: 90.0,
          powerMeterAccuracyPct: 0.5,
          dualSidedTorqueTelemetry: true,
          annualFreeGroupsetsPool: 60,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'groupset_campagnolo_$year',
        category: EquipmentSponsorCategory.groupsetAndPower,
        brandId: 'brand_campagnolo',
        brandName: 'Campagnolo Super Record Wireless',
        prestigeStars: 5,
        countryIso: 'ITA',
        annualCashContributionEur: isWorldTour ? 380000 : (isProTeam ? 180000 : 60000),
        equipmentMarketValueEur: 320000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 32,
        performanceBonuses: {'giro_stage_win': 25000, 'monument_win': 35000},
        pitchDescription:
            'Klasyczny włoski prestiż i ceramiczne łożyska CULT. Sprawność mechaniczna 98.8% oraz wyjątkowa ergonomia klamkomanetek doceniana przez liderów w górach.',
        perksJson: const GroupsetTechnicalPerks(
          drivetrainEfficiency: 0.988,
          shiftLatencyMs: 170,
          chainDropRiskReductionPct: 88.0,
          powerMeterAccuracyPct: 1.0,
          dualSidedTorqueTelemetry: true,
          annualFreeGroupsetsPool: 50,
        ).toJson(),
      ),
    ];
  }

  static List<TechnicalContractOffer> _generateHelmetsEyewearOffers(
      bool isWorldTour, bool isProTeam, int year) {
    return [
      TechnicalContractOffer(
        id: 'helmets_kask_$year',
        category: EquipmentSponsorCategory.helmetsAndEyewear,
        brandId: 'brand_kask',
        brandName: 'KASK & KOO Eyewear',
        prestigeStars: 5,
        countryIso: 'ITA',
        annualCashContributionEur: isWorldTour ? 180000 : (isProTeam ? 90000 : 30000),
        equipmentMarketValueEur: 110000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 30,
        performanceBonuses: {'tt_stage_win': 20000, 'grand_tour_stage': 10000},
        pitchDescription:
            'Kask czasowy Bambino Pro Evo dający +12.5 W przewagi w próbach czasowych oraz szosowy Valegro o 94% efektywności chłodzenia na morderczych podjazdach w 35°C.',
        perksJson: const HelmetsAndEyewearTechnicalPerks(
          ttHelmetAeroWattSavings: 12.5,
          roadHelmetVentilationEfficiencyPct: 94.0,
          eyewearOpticsContrastRating: 92,
          crashProtectionSafetyFactor: 95,
          annualFreeHelmetsCount: 120,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'helmets_oakley_$year',
        category: EquipmentSponsorCategory.helmetsAndEyewear,
        brandId: 'brand_oakley',
        brandName: 'Oakley Speed Optics & Helmets',
        prestigeStars: 5,
        countryIso: 'USA',
        annualCashContributionEur: isWorldTour ? 220000 : (isProTeam ? 110000 : 35000),
        equipmentMarketValueEur: 130000,
        contractDurationYears: 3,
        minimumTeamDivision: TeamDivision.proTeam,
        minimumUciRank: 22,
        performanceBonuses: {'monument_win': 25000, 'tt_world_champ': 35000},
        pitchDescription:
            'Soczewki Prizm Road i kask czasowy ARO7. Zysk +13.2 W na czasówce oraz bezkonkurencyjny kontrast w deszczu i podczas zjazdów w zacienionych lasach.',
        perksJson: const HelmetsAndEyewearTechnicalPerks(
          ttHelmetAeroWattSavings: 13.2,
          roadHelmetVentilationEfficiencyPct: 88.0,
          eyewearOpticsContrastRating: 98,
          crashProtectionSafetyFactor: 92,
          annualFreeHelmetsCount: 140,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'helmets_poc_$year',
        category: EquipmentSponsorCategory.helmetsAndEyewear,
        brandId: 'brand_poc',
        brandName: 'POC Sports Sweden',
        prestigeStars: 4,
        countryIso: 'SWE',
        annualCashContributionEur: isWorldTour ? 160000 : (isProTeam ? 80000 : 25000),
        equipmentMarketValueEur: 105000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 35,
        performanceBonuses: {'tt_stage_win': 25000},
        pitchDescription:
            'Radykalny kask czasowy POC Tempor generujący aż +14.0 W przewagi w ITT oraz ochrona MIPS Integra minimalizująca ryzyko wstrząśnienia mózgu.',
        perksJson: const HelmetsAndEyewearTechnicalPerks(
          ttHelmetAeroWattSavings: 14.0,
          roadHelmetVentilationEfficiencyPct: 85.0,
          eyewearOpticsContrastRating: 90,
          crashProtectionSafetyFactor: 99,
          annualFreeHelmetsCount: 100,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'helmets_ekoi_$year',
        category: EquipmentSponsorCategory.helmetsAndEyewear,
        brandId: 'brand_ekoi',
        brandName: 'Ekoï Racing Pro',
        prestigeStars: 4,
        countryIso: 'FRA',
        annualCashContributionEur: isWorldTour ? 250000 : (isProTeam ? 130000 : 45000),
        equipmentMarketValueEur: 125000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 35,
        performanceBonuses: {'grand_tour_stage': 12000},
        pitchDescription:
            'Bardzo wysoka dopłata finansowa, kaski Aerodinamica z wizjerami magnetycznymi i okulary z pełną personalizacją kolorystyczną pod barwy ekipy.',
        perksJson: const HelmetsAndEyewearTechnicalPerks(
          ttHelmetAeroWattSavings: 11.2,
          roadHelmetVentilationEfficiencyPct: 89.0,
          eyewearOpticsContrastRating: 88,
          crashProtectionSafetyFactor: 90,
          annualFreeHelmetsCount: 160,
        ).toJson(),
      ),
    ];
  }

  static List<TechnicalContractOffer> _generateApparelOffers(
      bool isWorldTour, bool isProTeam, int year) {
    return [
      TechnicalContractOffer(
        id: 'apparel_bioracer_$year',
        category: EquipmentSponsorCategory.apparel,
        brandId: 'brand_bioracer',
        brandName: 'Bioracer Speedwear Works',
        prestigeStars: 5,
        countryIso: 'BEL',
        annualCashContributionEur: isWorldTour ? 350000 : (isProTeam ? 170000 : 60000),
        equipmentMarketValueEur: 280000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 25,
        performanceBonuses: {'tt_world_champ': 50000, 'grand_tour_stage': 20000},
        pitchDescription:
            'Kombinezony czasowe Speedmaster 2.0 z prążkowanymi rękawami Vortex dające aż +23.5 W zysku w tunelu aero! Zapewniamy 5 sesji w tunelu aerodynamicznym w Beringen.',
        perksJson: const ApparelTechnicalPerks(
          ttSkinsuitWattSavings: 23.5,
          roadAeroJerseyWattSavings: 6.8,
          badWeatherThermalProtectionScore: 90,
          antiChafingComfortScore: 94,
          customWindTunnelFittingsCount: 5,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'apparel_castelli_$year',
        category: EquipmentSponsorCategory.apparel,
        brandId: 'brand_castelli',
        brandName: 'Castelli Squadra Corse',
        prestigeStars: 5,
        countryIso: 'ITA',
        annualCashContributionEur: isWorldTour ? 390000 : (isProTeam ? 190000 : 65000),
        equipmentMarketValueEur: 310000,
        contractDurationYears: 3,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 26,
        performanceBonuses: {'monument_win': 35000, 'giro_overall': 60000},
        pitchDescription:
            'Sanremo BT Speedsuit (+21.5 W w ITT) i niepokonane kurtki Gabba RoS chroniące kolarzy przed hipotermią w ulewach i śniegu na przełęczach alpejskich.',
        perksJson: const ApparelTechnicalPerks(
          ttSkinsuitWattSavings: 21.5,
          roadAeroJerseyWattSavings: 7.2,
          badWeatherThermalProtectionScore: 98,
          antiChafingComfortScore: 96,
          customWindTunnelFittingsCount: 4,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'apparel_rule28_$year',
        category: EquipmentSponsorCategory.apparel,
        brandId: 'brand_rule28',
        brandName: 'Rule 28 Aero Lab',
        prestigeStars: 5,
        countryIso: 'GBR',
        annualCashContributionEur: isWorldTour ? 270000 : (isProTeam ? 130000 : 45000),
        equipmentMarketValueEur: 230000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.proTeam,
        minimumUciRank: 18,
        performanceBonuses: {'tt_stage_win': 30000, 'tt_world_champ': 60000},
        pitchDescription:
            'Bezwzględna obsesja na punkcie watów. Tkaniny z silikonowymi żebrami aero i ochraniacze czasowe dające rekordowe +24.5 W oszczędności przy 50 km/h!',
        perksJson: const ApparelTechnicalPerks(
          ttSkinsuitWattSavings: 24.5,
          roadAeroJerseyWattSavings: 5.5,
          badWeatherThermalProtectionScore: 82,
          antiChafingComfortScore: 88,
          customWindTunnelFittingsCount: 6,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'apparel_santini_$year',
        category: EquipmentSponsorCategory.apparel,
        brandId: 'brand_santini',
        brandName: 'Santini Maglificio Sportivo',
        prestigeStars: 4,
        countryIso: 'ITA',
        annualCashContributionEur: isWorldTour ? 320000 : (isProTeam ? 160000 : 55000),
        equipmentMarketValueEur: 260000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 32,
        performanceBonuses: {'tour_de_france_stage': 25000},
        pitchDescription:
            'Oficjalny producent koszulek liderów Tour de France i La Vuelta. Kombinezony Redux TT (+19.0 W) i pełna garderoba na wszystkie strefy klimatyczne.',
        perksJson: const ApparelTechnicalPerks(
          ttSkinsuitWattSavings: 19.0,
          roadAeroJerseyWattSavings: 6.0,
          badWeatherThermalProtectionScore: 92,
          antiChafingComfortScore: 92,
          customWindTunnelFittingsCount: 3,
        ).toJson(),
      ),
    ];
  }

  static List<TechnicalContractOffer> _generateNutritionOffers(
      bool isWorldTour, bool isProTeam, int year) {
    return [
      TechnicalContractOffer(
        id: 'nutrition_maurten_$year',
        category: EquipmentSponsorCategory.nutrition,
        brandId: 'brand_maurten',
        brandName: 'Maurten Hydrogel Lab',
        prestigeStars: 5,
        countryIso: 'SWE',
        annualCashContributionEur: isWorldTour ? 260000 : (isProTeam ? 130000 : 40000),
        equipmentMarketValueEur: 220000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.proTeam,
        minimumUciRank: 20,
        performanceBonuses: {'grand_tour_overall': 75000, 'monument_win': 35000},
        pitchDescription:
            'Opatentowana technologia hydrożelu 1:0.8 pozwala na bezproblemowe przyswajanie aż 120 g/h węglowodanów przy zaledwie 0.2% ryzyka problemów żołądkowych. Zero spadków energii!',
        perksJson: const NutritionTechnicalPerks(
          maxCarbIntakeGramsPerHour: 120,
          giDistressRiskPct: 0.2,
          electrolytePlasmaBufferScore: 96,
          glycogenRecoverySpeedupPct: 28.0,
          annualNutritionUnitsProvided: 20000,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'nutrition_sis_$year',
        category: EquipmentSponsorCategory.nutrition,
        brandId: 'brand_sis',
        brandName: 'Science in Sport (SiS Beta Fuel)',
        prestigeStars: 5,
        countryIso: 'GBR',
        annualCashContributionEur: isWorldTour ? 290000 : (isProTeam ? 145000 : 45000),
        equipmentMarketValueEur: 240000,
        contractDurationYears: 3,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 26,
        performanceBonuses: {'grand_tour_stage': 15000, 'monument_podium': 25000},
        pitchDescription:
            'Beta Fuel Dual Source dostarcza 120 g/h węglowodanów w płynie i żelach. Dostarczamy 25 000 jednostek żywienia na sezon i zapewniamy wsparcie dietetyków klinicznych.',
        perksJson: const NutritionTechnicalPerks(
          maxCarbIntakeGramsPerHour: 120,
          giDistressRiskPct: 0.5,
          electrolytePlasmaBufferScore: 94,
          glycogenRecoverySpeedupPct: 25.0,
          annualNutritionUnitsProvided: 25000,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'nutrition_neversecond_$year',
        category: EquipmentSponsorCategory.nutrition,
        brandId: 'brand_neversecond',
        brandName: 'Neversecond C-Series Fuel',
        prestigeStars: 4,
        countryIso: 'USA',
        annualCashContributionEur: isWorldTour ? 220000 : (isProTeam ? 110000 : 35000),
        equipmentMarketValueEur: 190000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 30,
        performanceBonuses: {'monument_win': 30000},
        pitchDescription:
            'Seria C90 i C120 oparta na badaniach Dr. Asker Jeukendrupa. Precyzyjne dozowanie 110-120 g/h z optymalnym indeksem osmolarności zapobiegającym skurczom.',
        perksJson: const NutritionTechnicalPerks(
          maxCarbIntakeGramsPerHour: 115,
          giDistressRiskPct: 0.8,
          electrolytePlasmaBufferScore: 92,
          glycogenRecoverySpeedupPct: 24.0,
          annualNutritionUnitsProvided: 18000,
        ).toJson(),
      ),
      TechnicalContractOffer(
        id: 'nutrition_precision_$year',
        category: EquipmentSponsorCategory.nutrition,
        brandId: 'brand_precision',
        brandName: 'Precision Fuel & Hydration',
        prestigeStars: 4,
        countryIso: 'GBR',
        annualCashContributionEur: isWorldTour ? 240000 : (isProTeam ? 120000 : 38000),
        equipmentMarketValueEur: 180000,
        contractDurationYears: 2,
        minimumTeamDivision: TeamDivision.continental,
        minimumUciRank: 32,
        performanceBonuses: {'grand_tour_stage': 12000},
        pitchDescription:
            'Zindywidualizowane testy potu dla każdego kolarza ekipy. Niezrównane nawodnienie w 38°C upałach i żele 100g/h o delikatnym, nieobciążającym smaku.',
        perksJson: const NutritionTechnicalPerks(
          maxCarbIntakeGramsPerHour: 105,
          giDistressRiskPct: 0.4,
          electrolytePlasmaBufferScore: 99,
          glycogenRecoverySpeedupPct: 22.0,
          annualNutritionUnitsProvided: 16000,
        ).toJson(),
      ),
    ];
  }

  /// 4. Negocjuje warunki oferty sponsorskiej (kontroferta menedżera).
  static TenderNegotiationResult negotiateOffer({
    required EquipmentTenderSession session,
    required TechnicalContractOffer offer,
    required int requestedAnnualCashEur,
    required int requestedDurationYears,
    bool demandWindTunnelAllocation = false,
  }) {
    if (session.negotiationRoundsRemaining <= 0) {
      return TenderNegotiationResult(
        reaction: TenderNegotiationReaction.rejected,
        originalOffer: offer,
        sponsorCommentary:
            'Termin składania kontrofert minął. Nie możemy już prowadzić dalszych negocjacji w tej turze przetargowej.',
        roundsRemaining: 0,
      );
    }

    final cashIncreaseRatio =
        offer.annualCashContributionEur > 0
            ? (requestedAnnualCashEur - offer.annualCashContributionEur) /
                offer.annualCashContributionEur
            : 0.5;

    final roundsLeft = session.negotiationRoundsRemaining - 1;

    // Przesadne żądania (>45% więcej gotówki) skutkują zerwaniem rozmów
    if (cashIncreaseRatio > 0.45) {
      return TenderNegotiationResult(
        reaction: TenderNegotiationReaction.withdrawn,
        originalOffer: offer,
        sponsorCommentary:
            'Dyrektor finansowy marki ${offer.brandName} uznał Wasze żądania za nierealistyczne i obraźliwe. Oferta została natychmiast wycofana z rynku.',
        roundsRemaining: roundsLeft,
      );
    }

    // Umiarkowane żądania (do +15%) zostają zaakceptowane
    if (cashIncreaseRatio <= 0.15 &&
        requestedDurationYears == offer.contractDurationYears) {
      final updatedOffer = offer.copyWith(
        annualCashContributionEur: requestedAnnualCashEur,
      );
      return TenderNegotiationResult(
        reaction: TenderNegotiationReaction.accepted,
        originalOffer: offer,
        revisedOffer: updatedOffer,
        sponsorCommentary:
            'Zarząd ${offer.brandName} z satysfakcją przyjmuje Waszą propozycję. Warunki zostały zaktualizowane i czekają na finalny podpis.',
        roundsRemaining: roundsLeft,
      );
    }

    // Średnie żądania (15% - 40%) spotykają się z kompromisową kontrofertą
    final compromisedCash = (offer.annualCashContributionEur +
            (requestedAnnualCashEur - offer.annualCashContributionEur) * 0.55)
        .round();

    final updatedPerks = Map<String, dynamic>.from(offer.perksJson);
    if (demandWindTunnelAllocation &&
        offer.category == EquipmentSponsorCategory.apparel) {
      final appPerks = ApparelTechnicalPerks.fromJson(updatedPerks);
      final upgraded = ApparelTechnicalPerks(
        ttSkinsuitWattSavings:
            double.parse((appPerks.ttSkinsuitWattSavings + 1.0).toStringAsFixed(1)),
        roadAeroJerseyWattSavings: appPerks.roadAeroJerseyWattSavings,
        badWeatherThermalProtectionScore:
            appPerks.badWeatherThermalProtectionScore,
        antiChafingComfortScore: appPerks.antiChafingComfortScore,
        customWindTunnelFittingsCount: appPerks.customWindTunnelFittingsCount + 2,
      );
      updatedPerks.addAll(upgraded.toJson());
    }

    final counterOffer = offer.copyWith(
      annualCashContributionEur: compromisedCash,
      contractDurationYears: requestedDurationYears,
      perksJson: updatedPerks,
    );

    return TenderNegotiationResult(
      reaction: TenderNegotiationReaction.counterOffered,
      originalOffer: offer,
      revisedOffer: counterOffer,
      sponsorCommentary:
          'Proponujemy kompromis: podnosimy kwotę roczną do $compromisedCash € i zatwierdzamy umowę na $requestedDurationYears lata.',
      roundsRemaining: roundsLeft,
    );
  }

  /// 5. Podpisuje kontrakt techniczny na kolejny sezon.
  static EquipmentTenderSession signContract({
    required EquipmentTenderSession session,
    required CyclingTeam team,
    required TechnicalContractOffer offer,
  }) {
    // Sprawdzenie restrykcji producenta ram przy kołach
    if (offer.category == EquipmentSponsorCategory.wheels &&
        session.currentPortfolio.enforcesProprietaryWheels) {
      throw ArgumentError(
        'Nie można podpisać kontraktu na koła: producent ram ${session.currentPortfolio.frameDeal.manufacturerName} wymusza stosowanie kół własnych.',
      );
    }

    final contract = ActiveTechnicalContract(
      id: 'contract_${offer.category.name}_${session.seasonYear}',
      category: offer.category,
      brandId: offer.brandId,
      brandName: offer.brandName,
      annualCashContributionEur: offer.annualCashContributionEur,
      contractYearsTotal: offer.contractDurationYears,
      contractYearsRemaining: offer.contractDurationYears,
      signedSeasonYear: session.seasonYear,
      performanceBonuses: offer.performanceBonuses,
      perksJson: offer.perksJson,
    );

    final updatedSigned = Map<EquipmentSponsorCategory, ActiveTechnicalContract>.from(
      session.signedContracts,
    );
    updatedSigned[offer.category] = contract;

    // Aktualizacja portfolio
    var updatedPortfolio = session.currentPortfolio;
    switch (offer.category) {
      case EquipmentSponsorCategory.wheels:
        updatedPortfolio = updatedPortfolio.copyWith(wheelsContract: contract);
        break;
      case EquipmentSponsorCategory.groupsetAndPower:
        updatedPortfolio =
            updatedPortfolio.copyWith(groupsetContract: contract);
        break;
      case EquipmentSponsorCategory.helmetsAndEyewear:
        updatedPortfolio =
            updatedPortfolio.copyWith(helmetsEyewearContract: contract);
        break;
      case EquipmentSponsorCategory.apparel:
        updatedPortfolio = updatedPortfolio.copyWith(apparelContract: contract);
        break;
      case EquipmentSponsorCategory.nutrition:
        updatedPortfolio =
            updatedPortfolio.copyWith(nutritionContract: contract);
        break;
      case EquipmentSponsorCategory.frames:
        break;
    }

    return session.copyWith(
      signedContracts: updatedSigned,
      currentPortfolio: updatedPortfolio,
    );
  }

  /// 6. Zamyka przetarg i zwraca zaktualizowany zespół kolarski z nowym budżetem.
  static ({CyclingTeam updatedTeam, TeamTechnicalPortfolio portfolio})
      concludeTenderAndApplyPortfolio({
    required EquipmentTenderSession session,
    required CyclingTeam team,
  }) {
    final portfolio = session.currentPortfolio;

    // Suma gotówki z nowo podpisanych kontraktów
    final addedCash = portfolio.totalAnnualCashContributionEur;
    final updatedTeam = team.copyWith(
      cashBalanceEur: team.cashBalanceEur + addedCash,
    );

    return (
      updatedTeam: updatedTeam,
      portfolio: portfolio,
    );
  }

  /// 7. Wylicza realne korzyści w watach (Watt Advantage) podczas etapu wyścigu.
  static EquipmentWattAdvantageReport calculateRaceWattImpact({
    required TeamTechnicalPortfolio portfolio,
    required bool isTimeTrial,
    double raceSpeedKmh = 50.0,
    double ambientTempC = 22.0,
  }) {
    final breakdown = <String, double>{};
    double totalWatts = 0.0;
    double deltaCdA = 0.0;

    if (isTimeTrial) {
      // 1. Kombinezon aero TT
      final apparel = portfolio.apparelContract?.apparelPerks;
      final apparelWatts = apparel?.ttSkinsuitWattSavings ?? 6.0;
      breakdown['Kombinezon czasowy Aero TT'] = apparelWatts;
      totalWatts += apparelWatts;
      deltaCdA += (apparelWatts / 1600.0);

      // 2. Kask aero teardrop z wizjerem
      final helmet = portfolio.helmetsEyewearContract?.helmetsEyewearPerks;
      final helmetWatts = helmet?.ttHelmetAeroWattSavings ?? 4.0;
      breakdown['Kask czasowy Aero TT'] = helmetWatts;
      totalWatts += helmetWatts;
      deltaCdA += (helmetWatts / 1600.0);

      // 3. Koła czasowe (Dysk TT i łożyska ceramiczne)
      final wheels = portfolio.wheelsContract?.wheelsetPerks;
      if (wheels != null) {
        final wheelWatts = (wheels.aeroCdAReduction * 1600.0) +
            wheels.rollingResistanceWattsSaved;
        breakdown['Koła aero & Dysk TT (łożyska)'] =
            double.parse(wheelWatts.toStringAsFixed(1));
        totalWatts += wheelWatts;
        deltaCdA += wheels.aeroCdAReduction;
      } else if (portfolio.enforcesProprietaryWheels) {
        breakdown['Koła zintegrowane producenta ram'] = 8.0;
        totalWatts += 8.0;
        deltaCdA += 0.005;
      }

      // 4. Napęd i sprawność łańcucha
      final groupset = portfolio.groupsetContract?.groupsetPerks;
      final groupsetWatts = groupset != null
          ? (groupset.drivetrainEfficiency - 0.974) * 400.0
          : 1.5;
      breakdown['Sprawność napędu Di2/AXS'] =
          double.parse(groupsetWatts.toStringAsFixed(1));
      totalWatts += groupsetWatts;

      final summary =
          'Konfiguracja czasowa generuje łącznie +${totalWatts.toStringAsFixed(1)} W przewagi przy ${raceSpeedKmh.round()} km/h (redukcja CdA o -${deltaCdA.toStringAsFixed(4)} m²). Na 30-kilometrowej czasówce przekłada się to na zysk około ${(totalWatts * 1.85).round()} sekund!';

      return EquipmentWattAdvantageReport(
        totalWattsSaved: double.parse(totalWatts.toStringAsFixed(1)),
        cdaDeltaSquareMeters: double.parse(deltaCdA.toStringAsFixed(4)),
        componentBreakdown: breakdown,
        engineeringSummary: summary,
      );
    } else {
      // Wyścig ze startu wspólnego (Road Race)
      // 1. Koszulka aero
      final apparel = portfolio.apparelContract?.apparelPerks;
      final jerseyWatts = apparel?.roadAeroJerseyWattSavings ?? 2.5;
      breakdown['Koszulka szosowa Aero'] = jerseyWatts;
      totalWatts += jerseyWatts;

      // 2. Chłodzenie głowy w kasku (kluczowe przy temp > 28°C)
      final helmet = portfolio.helmetsEyewearContract?.helmetsEyewearPerks;
      if (ambientTempC > 28.0 && helmet != null) {
        final coolingBonus =
            (ambientTempC - 28.0) * (helmet.roadHelmetVentilationEfficiencyPct / 100.0) * 1.5;
        breakdown['Wentylacja kasku (ochrona przed przegrzaniem)'] =
            double.parse(coolingBonus.toStringAsFixed(1));
        totalWatts += coolingBonus;
      }

      // 3. Łożyska ceramiczne kół
      final wheels = portfolio.wheelsContract?.wheelsetPerks;
      if (wheels != null) {
        breakdown['Łożyska piast i aerodynamika kół'] =
            wheels.rollingResistanceWattsSaved + 2.0;
        totalWatts += wheels.rollingResistanceWattsSaved + 2.0;
      }

      // 4. Sprawność napędu
      final groupset = portfolio.groupsetContract?.groupsetPerks;
      final groupsetWatts = groupset != null
          ? (groupset.drivetrainEfficiency - 0.974) * 300.0
          : 1.0;
      breakdown['Sprawność napędu'] =
          double.parse(groupsetWatts.toStringAsFixed(1));
      totalWatts += groupsetWatts;

      final summary =
          'Optymalizacja sprzętowa na etapie ze startu wspólnego daje +${totalWatts.toStringAsFixed(1)} W oszczędności przy prędkości peletonu. Kolarze oszczędzają energię przed finałowym podjazdem.';

      return EquipmentWattAdvantageReport(
        totalWattsSaved: double.parse(totalWatts.toStringAsFixed(1)),
        cdaDeltaSquareMeters: 0.008,
        componentBreakdown: breakdown,
        engineeringSummary: summary,
      );
    }
  }

  /// 8. Wylicza wydajność metaboliczną i ryzyko problemów żołądkowych z żywienia (Hydrogel 120g/h).
  static RaceNutritionPerformanceReport evaluateInRaceNutrition({
    required TeamTechnicalPortfolio portfolio,
    required int stageDistanceKm,
    required double raceIntensityPct,
    double ambientTempC = 25.0,
  }) {
    final nutrition = portfolio.nutritionContract?.nutritionPerks;

    final targetCarbs = nutrition?.maxCarbIntakeGramsPerHour ?? 60;
    final baseGiDistress = nutrition?.giDistressRiskPct ?? 15.0;

    // Im dłuższy i cięższy etap, tym większe ryzyko kryzysu bez odpowiedniego żywienia
    final isQueenStage = stageDistanceKm >= 180 && raceIntensityPct >= 0.82;

    double bonkRisk = 0.0;
    double staminaRetention = 98.0;

    if (targetCarbs >= 110) {
      // Hydrożel 110-120g/h: zapobiega hipoglikemii i wyczerpaniu glikogenu
      bonkRisk = isQueenStage ? 0.8 : 0.2;
      staminaRetention = 98.5;
    } else if (targetCarbs >= 90) {
      bonkRisk = isQueenStage ? 4.5 : 1.5;
      staminaRetention = 95.0;
    } else {
      // Standardowe żele 60g/h
      bonkRisk = isQueenStage ? 22.0 : 8.5;
      staminaRetention = isQueenStage ? 86.0 : 91.0;
    }

    // Wpływ upału na żołądek
    final heatGiPenalty = ambientTempC > 30.0 ? (ambientTempC - 30.0) * 0.8 : 0.0;
    final effectiveGiRisk = math.min(35.0, baseGiDistress + heatGiPenalty);

    final assessment = targetCarbs >= 110
        ? 'Elitarne żywienie 120g/h (Hydrogel): kolarze zachowują ${staminaRetention.toStringAsFixed(1)}% mocy na finałowym podjeździe. Ryzyko odcięcia prądu (bonk) wynosi poniżej 1%!'
        : 'Podstawowe żywienie ${targetCarbs}g/h: kolarze są narażeni na spadek glikogenu po 4. godzinie ścigania (spadek mocy o ${(100 - staminaRetention).toStringAsFixed(1)}%).';

    return RaceNutritionPerformanceReport(
      targetCarbIntakePerHourGrams: targetCarbs,
      giDistressRiskPercent: double.parse(effectiveGiRisk.toStringAsFixed(1)),
      bonkRiskPercent: double.parse(bonkRisk.toStringAsFixed(1)),
      staminaRetentionPercent:
          double.parse(staminaRetention.toStringAsFixed(1)),
      nutritionistAssessment: assessment,
    );
  }
}
