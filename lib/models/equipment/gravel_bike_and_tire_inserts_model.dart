import 'dart:math' as math;

import '../race/gravel_race_and_surface_model.dart';

/// Wzór bieżnika opony szutrowej (38–50 mm).
enum GravelTireTreadPattern {
  /// Gładki środek z delikatnym diamentowym bokiem (Champagne Gravel / Kat. 1).
  fileTreadSlick,

  /// Pół-slick z niskimi klockami bocznymi (uniwersalny szybki szuter Kat. 1–2).
  semiSlickMicroKnob,

  /// Średni bieżnik uniwersalny na zmienne warunki (Kat. 2–4).
  allRounderMediumKnob,

  /// Agresywny wysoki klocek z dużym odstępem na błoto i ostre kamienie (Kat. 4–5).
  aggressiveMudAndFlintKnob;

  String toJson() => name;

  static GravelTireTreadPattern fromJson(String value) {
    return GravelTireTreadPattern.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GravelTireTreadPattern.allRounderMediumKnob,
    );
  }

  String get displayNamePl {
    switch (this) {
      case GravelTireTreadPattern.fileTreadSlick:
        return 'Slick / Diamentowy (Kat. 1)';
      case GravelTireTreadPattern.semiSlickMicroKnob:
        return 'Semi-Slick Mikro-Klocek (Kat. 1–2)';
      case GravelTireTreadPattern.allRounderMediumKnob:
        return 'Uniwersalny Średni Klocek (Kat. 2–4)';
      case GravelTireTreadPattern.aggressiveMudAndFlintKnob:
        return 'Agresywny Klocek Błoto/Krzemień (Kat. 4–5)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case GravelTireTreadPattern.fileTreadSlick:
        return 'File-Tread Slick (Cat 1)';
      case GravelTireTreadPattern.semiSlickMicroKnob:
        return 'Semi-Slick Micro-Knob (Cat 1–2)';
      case GravelTireTreadPattern.allRounderMediumKnob:
        return 'All-Rounder Medium Knob (Cat 2–4)';
      case GravelTireTreadPattern.aggressiveMudAndFlintKnob:
        return 'Aggressive Mud & Flint Knob (Cat 4–5)';
    }
  }

  /// Mnożnik oporu toczenia wynikający z geometrii bieżnika.
  double get treadCrrFactor {
    switch (this) {
      case GravelTireTreadPattern.fileTreadSlick:
        return 0.94;
      case GravelTireTreadPattern.semiSlickMicroKnob:
        return 0.98;
      case GravelTireTreadPattern.allRounderMediumKnob:
        return 1.04;
      case GravelTireTreadPattern.aggressiveMudAndFlintKnob:
        return 1.13;
    }
  }

  /// Przyczepność na luźnym i mokrym szutrze (mnożnik względem bazy 1.0).
  double gripFactorForSurface(GravelSurfaceCategory surface, double rainIntensity) {
    final rain = rainIntensity.clamp(0.0, 1.0);
    switch (this) {
      case GravelTireTreadPattern.fileTreadSlick:
        final dryBase = surface.categoryNumber <= 2 ? 1.02 : 0.72;
        return (dryBase - (rain * 0.24)).clamp(0.45, 1.25);
      case GravelTireTreadPattern.semiSlickMicroKnob:
        final dryBase = surface.categoryNumber <= 3 ? 1.05 : 0.85;
        return (dryBase - (rain * 0.16)).clamp(0.55, 1.25);
      case GravelTireTreadPattern.allRounderMediumKnob:
        final dryBase = surface.categoryNumber >= 2 ? 1.08 : 0.98;
        return (dryBase - (rain * 0.08)).clamp(0.75, 1.30);
      case GravelTireTreadPattern.aggressiveMudAndFlintKnob:
        final dryBase = surface.categoryNumber >= 4 ? 1.20 : 0.96;
        return (dryBase + (rain * 0.05)).clamp(0.85, 1.35);
    }
  }
}

/// Typ oplotu i wzmocnienia ścianki bocznej opony szutrowej.
enum GravelTireCasingType {
  /// Lekki, elastyczny oplot wyścigowy (120 TPI, niskie opory, niższa odporność boczna).
  raceSupple,

  /// Wzmocniony oplot uniwersalny (60–120 TPI z pasem ochronnym).
  allRoundReinforced,

  /// Pancerny oplot z ochroną ścianki bocznej przed ostrym krzemieniem (Flint Hills).
  armoredFlintGuard;

  String toJson() => name;

  static GravelTireCasingType fromJson(String value) {
    return GravelTireCasingType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GravelTireCasingType.allRoundReinforced,
    );
  }

  String get displayNamePl {
    switch (this) {
      case GravelTireCasingType.raceSupple:
        return 'Wyścigowy Elastyczny (120 TPI)';
      case GravelTireCasingType.allRoundReinforced:
        return 'Wzmocniony Uniwersalny';
      case GravelTireCasingType.armoredFlintGuard:
        return 'Pancerny Flint-Guard (Ścianki Boczne)';
    }
  }

  /// Mnożnik ochrony przed rozcięciem ścianki bocznej.
  double get sidewallCutProtectionMultiplier {
    switch (this) {
      case GravelTireCasingType.raceSupple:
        return 0.78;
      case GravelTireCasingType.allRoundReinforced:
        return 1.15;
      case GravelTireCasingType.armoredFlintGuard:
        return 1.65;
    }
  }

  /// Mnożnik histerezy oplotu (niższa wartość = mniej strat energii na ugięcie).
  double get casingCrrMultiplier {
    switch (this) {
      case GravelTireCasingType.raceSupple:
        return 0.95;
      case GravelTireCasingType.allRoundReinforced:
        return 1.02;
      case GravelTireCasingType.armoredFlintGuard:
        return 1.10;
    }
  }
}

/// Specyfikacja opony szutrowej Tubeless Ready (zakres 38–50 mm).
class GravelTireSpec {
  static const double minGravelWidthMm = 38.0;
  static const double maxGravelWidthMm = 50.0;

  final String id;
  final String brandId;
  final String name;
  final double widthMm;
  final int weightGramsPerTire;
  final double baseCrr;
  final GravelTireTreadPattern treadPattern;
  final GravelTireCasingType casingType;
  final double punctureResistanceIndex;
  final double sidewallProtectionIndex;
  final double mudClearanceScore;
  final int priceEur;

  const GravelTireSpec({
    required this.id,
    required this.brandId,
    required this.name,
    required this.widthMm,
    required this.weightGramsPerTire,
    required this.baseCrr,
    required this.treadPattern,
    required this.casingType,
    required this.punctureResistanceIndex,
    required this.sidewallProtectionIndex,
    required this.mudClearanceScore,
    required this.priceEur,
  });

  /// Czy szerokość opony mieści się w wyścigowym standardzie szutrowym 38–50 mm.
  bool get isWithinGravelRange =>
      widthMm >= minGravelWidthMm && widthMm <= maxGravelWidthMm;

  /// Masa pary opon (przód + tył) w kilogramach.
  double get weightKgPerPair => (weightGramsPerTire * 2.0) / 1000.0;

  /// Efektywny współczynnik CRR opony dla danej kategorii nawierzchni szutrowej.
  double effectiveCrrForSurface(GravelSurfaceCategory surface) {
    final widthBonus = ((widthMm.clamp(minGravelWidthMm, maxGravelWidthMm) - 40.0) * 0.004);
    final surfaceAdjustedWidthFactor = surface.categoryNumber >= 3
        ? (1.0 - widthBonus).clamp(0.88, 1.08)
        : (1.0 + (widthBonus * 0.5)).clamp(0.95, 1.06);

    return (baseCrr *
            treadPattern.treadCrrFactor *
            casingType.casingCrrMultiplier *
            surface.crrMultiplier *
            surfaceAdjustedWidthFactor)
        .clamp(0.0035, 0.0350);
  }

  /// Przyczepność opony na zadanej nawierzchni i intensywności opadów.
  double gripFactorForSurface(
    GravelSurfaceCategory surface, {
    double rainIntensity = 0.0,
  }) {
    final widthGripBonus =
        ((widthMm.clamp(minGravelWidthMm, maxGravelWidthMm) - 38.0) / 12.0) * 0.12;
    final treadGrip = treadPattern.gripFactorForSurface(surface, rainIntensity);
    return (treadGrip + widthGripBonus).clamp(0.45, 1.45);
  }

  GravelTireSpec copyWith({
    String? id,
    String? brandId,
    String? name,
    double? widthMm,
    int? weightGramsPerTire,
    double? baseCrr,
    GravelTireTreadPattern? treadPattern,
    GravelTireCasingType? casingType,
    double? punctureResistanceIndex,
    double? sidewallProtectionIndex,
    double? mudClearanceScore,
    int? priceEur,
  }) {
    return GravelTireSpec(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      widthMm: widthMm ?? this.widthMm,
      weightGramsPerTire: weightGramsPerTire ?? this.weightGramsPerTire,
      baseCrr: baseCrr ?? this.baseCrr,
      treadPattern: treadPattern ?? this.treadPattern,
      casingType: casingType ?? this.casingType,
      punctureResistanceIndex:
          punctureResistanceIndex ?? this.punctureResistanceIndex,
      sidewallProtectionIndex:
          sidewallProtectionIndex ?? this.sidewallProtectionIndex,
      mudClearanceScore: mudClearanceScore ?? this.mudClearanceScore,
      priceEur: priceEur ?? this.priceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'name': name,
      'widthMm': widthMm,
      'weightGramsPerTire': weightGramsPerTire,
      'baseCrr': baseCrr,
      'treadPattern': treadPattern.toJson(),
      'casingType': casingType.toJson(),
      'punctureResistanceIndex': punctureResistanceIndex,
      'sidewallProtectionIndex': sidewallProtectionIndex,
      'mudClearanceScore': mudClearanceScore,
      'priceEur': priceEur,
    };
  }

  factory GravelTireSpec.fromJson(Map<String, dynamic> json) {
    return GravelTireSpec(
      id: json['id'] as String? ?? 'gravel_tire_default',
      brandId: json['brandId'] as String? ?? 'generic_gravel',
      name: json['name'] as String? ?? 'Gravel All-Round 42mm',
      widthMm: (json['widthMm'] as num?)?.toDouble() ?? 42.0,
      weightGramsPerTire: (json['weightGramsPerTire'] as num?)?.toInt() ?? 490,
      baseCrr: (json['baseCrr'] as num?)?.toDouble() ?? 0.0052,
      treadPattern: GravelTireTreadPattern.fromJson(
        json['treadPattern'] as String? ?? 'allRounderMediumKnob',
      ),
      casingType: GravelTireCasingType.fromJson(
        json['casingType'] as String? ?? 'allRoundReinforced',
      ),
      punctureResistanceIndex:
          (json['punctureResistanceIndex'] as num?)?.toDouble() ?? 3.4,
      sidewallProtectionIndex:
          (json['sidewallProtectionIndex'] as num?)?.toDouble() ?? 3.2,
      mudClearanceScore: (json['mudClearanceScore'] as num?)?.toDouble() ?? 3.0,
      priceEur: (json['priceEur'] as num?)?.toInt() ?? 68,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GravelTireSpec &&
        other.id == id &&
        other.widthMm == widthMm &&
        other.treadPattern == treadPattern &&
        other.casingType == casingType;
  }

  @override
  int get hashCode => Object.hash(id, widthMm, treadPattern, casingType);

  @override
  String toString() => 'GravelTireSpec($name, ${widthMm.toStringAsFixed(0)}mm)';
}

/// Materiał wkładki antyprzebiciowej do opon bezdętkowych (`Foam Tire Inserts`).
enum FoamInsertMaterialType {
  /// Brak wkładek w kołach.
  none,

  /// Ultralekka pianka Pebax o zamkniętych komórkach (wyścigowa).
  ultralightPebax,

  /// Standardowa pianka EVA o dużej gęstości.
  closedCellEva,

  /// Dwuskładnikowa wkładka enduro/flint z wysokim tłumieniem uderzeń.
  highDensityDualCompound;

  String toJson() => name;

  static FoamInsertMaterialType fromJson(String value) {
    return FoamInsertMaterialType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FoamInsertMaterialType.none,
    );
  }

  String get displayNamePl {
    switch (this) {
      case FoamInsertMaterialType.none:
        return 'Brak wkładek';
      case FoamInsertMaterialType.ultralightPebax:
        return 'Ultralekki Pebax (Race)';
      case FoamInsertMaterialType.closedCellEva:
        return 'Pianka EVA (All-Round)';
      case FoamInsertMaterialType.highDensityDualCompound:
        return 'Dwuskładnikowa HD (Flint/Enduro)';
    }
  }
}

/// Model piankowych wkładek antyprzebiciowych (`Foam Tire Inserts`) chroniących obręcz
/// przed dobiciem (snake-bite) oraz umożliwiających jazdę awaryjną (Run-Flat).
class FoamTireInsertSpec {
  final String id;
  final String name;
  final FoamInsertMaterialType materialType;
  final bool isInstalled;
  final int weightGramsPerWheel;
  final double minCompatibleTireWidthMm;
  final double maxCompatibleTireWidthMm;
  final double pinchFlatProtectionFactor;
  final double rimImpactDampingFactor;
  final double runFlatSpeedRetention;
  final double runFlatMaxRangeKm;
  final double pressureReductionAllowanceBar;
  final double hysteresisRollingPenaltyCrr;
  final int priceEur;

  const FoamTireInsertSpec({
    required this.id,
    required this.name,
    required this.materialType,
    required this.isInstalled,
    required this.weightGramsPerWheel,
    required this.minCompatibleTireWidthMm,
    required this.maxCompatibleTireWidthMm,
    required this.pinchFlatProtectionFactor,
    required this.rimImpactDampingFactor,
    required this.runFlatSpeedRetention,
    required this.runFlatMaxRangeKm,
    required this.pressureReductionAllowanceBar,
    required this.hysteresisRollingPenaltyCrr,
    required this.priceEur,
  });

  const FoamTireInsertSpec.none()
      : id = 'insert_none',
        name = 'Brak wkładek antyprzebiciowych',
        materialType = FoamInsertMaterialType.none,
        isInstalled = false,
        weightGramsPerWheel = 0,
        minCompatibleTireWidthMm = 38.0,
        maxCompatibleTireWidthMm = 50.0,
        pinchFlatProtectionFactor = 0.0,
        rimImpactDampingFactor = 0.0,
        runFlatSpeedRetention = 0.0,
        runFlatMaxRangeKm = 0.0,
        pressureReductionAllowanceBar = 0.0,
        hysteresisRollingPenaltyCrr = 0.0,
        priceEur = 0;

  const FoamTireInsertSpec.ultralightRace()
      : id = 'insert_pebax_race',
        name = 'Air-Liner Light Gravel (Pebax)',
        materialType = FoamInsertMaterialType.ultralightPebax,
        isInstalled = true,
        weightGramsPerWheel = 48,
        minCompatibleTireWidthMm = 38.0,
        maxCompatibleTireWidthMm = 45.0,
        pinchFlatProtectionFactor = 0.68,
        rimImpactDampingFactor = 0.62,
        runFlatSpeedRetention = 0.58,
        runFlatMaxRangeKm = 14.0,
        pressureReductionAllowanceBar = 0.20,
        hysteresisRollingPenaltyCrr = 0.00012,
        priceEur = 95;

  const FoamTireInsertSpec.flintGuardEnduro()
      : id = 'insert_hd_flint_guard',
        name = 'Gravel Pro-Core HD Insert',
        materialType = FoamInsertMaterialType.highDensityDualCompound,
        isInstalled = true,
        weightGramsPerWheel = 92,
        minCompatibleTireWidthMm = 40.0,
        maxCompatibleTireWidthMm = 50.0,
        pinchFlatProtectionFactor = 0.88,
        rimImpactDampingFactor = 0.85,
        runFlatSpeedRetention = 0.72,
        runFlatMaxRangeKm = 24.0,
        pressureReductionAllowanceBar = 0.35,
        hysteresisRollingPenaltyCrr = 0.00024,
        priceEur = 135;

  /// Łączna masa obu wkładek (przód + tył) w kilogramach.
  double get totalWeightKg =>
      isInstalled ? (weightGramsPerWheel * 2.0) / 1000.0 : 0.0;

  /// Czy wkładka może być zamontowana w oponie o podanej szerokości [mm].
  bool isCompatibleWithTireWidth(double tireWidthMm) {
    if (!isInstalled) return true;
    return tireWidthMm >= minCompatibleTireWidthMm &&
        tireWidthMm <= maxCompatibleTireWidthMm;
  }

  /// Efektywny mnożnik ryzyka dobicia obręczy (niżej = lepiej).
  double get pinchFlatRiskMultiplier =>
      isInstalled ? (1.0 - pinchFlatProtectionFactor.clamp(0.0, 0.95)) : 1.0;

  FoamTireInsertSpec copyWith({
    String? id,
    String? name,
    FoamInsertMaterialType? materialType,
    bool? isInstalled,
    int? weightGramsPerWheel,
    double? minCompatibleTireWidthMm,
    double? maxCompatibleTireWidthMm,
    double? pinchFlatProtectionFactor,
    double? rimImpactDampingFactor,
    double? runFlatSpeedRetention,
    double? runFlatMaxRangeKm,
    double? pressureReductionAllowanceBar,
    double? hysteresisRollingPenaltyCrr,
    int? priceEur,
  }) {
    return FoamTireInsertSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      materialType: materialType ?? this.materialType,
      isInstalled: isInstalled ?? this.isInstalled,
      weightGramsPerWheel: weightGramsPerWheel ?? this.weightGramsPerWheel,
      minCompatibleTireWidthMm:
          minCompatibleTireWidthMm ?? this.minCompatibleTireWidthMm,
      maxCompatibleTireWidthMm:
          maxCompatibleTireWidthMm ?? this.maxCompatibleTireWidthMm,
      pinchFlatProtectionFactor:
          pinchFlatProtectionFactor ?? this.pinchFlatProtectionFactor,
      rimImpactDampingFactor:
          rimImpactDampingFactor ?? this.rimImpactDampingFactor,
      runFlatSpeedRetention:
          runFlatSpeedRetention ?? this.runFlatSpeedRetention,
      runFlatMaxRangeKm: runFlatMaxRangeKm ?? this.runFlatMaxRangeKm,
      pressureReductionAllowanceBar:
          pressureReductionAllowanceBar ?? this.pressureReductionAllowanceBar,
      hysteresisRollingPenaltyCrr:
          hysteresisRollingPenaltyCrr ?? this.hysteresisRollingPenaltyCrr,
      priceEur: priceEur ?? this.priceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'materialType': materialType.toJson(),
      'isInstalled': isInstalled,
      'weightGramsPerWheel': weightGramsPerWheel,
      'minCompatibleTireWidthMm': minCompatibleTireWidthMm,
      'maxCompatibleTireWidthMm': maxCompatibleTireWidthMm,
      'pinchFlatProtectionFactor': pinchFlatProtectionFactor,
      'rimImpactDampingFactor': rimImpactDampingFactor,
      'runFlatSpeedRetention': runFlatSpeedRetention,
      'runFlatMaxRangeKm': runFlatMaxRangeKm,
      'pressureReductionAllowanceBar': pressureReductionAllowanceBar,
      'hysteresisRollingPenaltyCrr': hysteresisRollingPenaltyCrr,
      'priceEur': priceEur,
    };
  }

  factory FoamTireInsertSpec.fromJson(Map<String, dynamic> json) {
    return FoamTireInsertSpec(
      id: json['id'] as String? ?? 'insert_none',
      name: json['name'] as String? ?? 'Brak wkładek antyprzebiciowych',
      materialType: FoamInsertMaterialType.fromJson(
        json['materialType'] as String? ?? 'none',
      ),
      isInstalled: json['isInstalled'] as bool? ?? false,
      weightGramsPerWheel: (json['weightGramsPerWheel'] as num?)?.toInt() ?? 0,
      minCompatibleTireWidthMm:
          (json['minCompatibleTireWidthMm'] as num?)?.toDouble() ?? 38.0,
      maxCompatibleTireWidthMm:
          (json['maxCompatibleTireWidthMm'] as num?)?.toDouble() ?? 50.0,
      pinchFlatProtectionFactor:
          (json['pinchFlatProtectionFactor'] as num?)?.toDouble() ?? 0.0,
      rimImpactDampingFactor:
          (json['rimImpactDampingFactor'] as num?)?.toDouble() ?? 0.0,
      runFlatSpeedRetention:
          (json['runFlatSpeedRetention'] as num?)?.toDouble() ?? 0.0,
      runFlatMaxRangeKm: (json['runFlatMaxRangeKm'] as num?)?.toDouble() ?? 0.0,
      pressureReductionAllowanceBar:
          (json['pressureReductionAllowanceBar'] as num?)?.toDouble() ?? 0.0,
      hysteresisRollingPenaltyCrr:
          (json['hysteresisRollingPenaltyCrr'] as num?)?.toDouble() ?? 0.0,
      priceEur: (json['priceEur'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoamTireInsertSpec &&
        other.id == id &&
        other.isInstalled == isInstalled &&
        other.materialType == materialType;
  }

  @override
  int get hashCode => Object.hash(id, isInstalled, materialType);
}

/// Rodzaj formuły mleczka uszczelniającego (`Tubeless Sealant`).
enum TubelessSealantFormula {
  /// Brak mleczka (opona dętkowa lub wyschnięta).
  none,

  /// Standardowe mleczko lateksowe bez amoniaku.
  latexAmmoniaFree,

  /// Mleczko wyścigowe z mikrowłóknami węglowymi/aramidowymi (zatyka do 7 mm).
  syntheticMicrofiberRace,

  /// Formuła długodystansowa o obniżonym odparowaniu na upały Ultra-Gravel.
  heavyDutyUltraEndurance;

  String toJson() => name;

  static TubelessSealantFormula fromJson(String value) {
    return TubelessSealantFormula.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TubelessSealantFormula.latexAmmoniaFree,
    );
  }

  String get displayNamePl {
    switch (this) {
      case TubelessSealantFormula.none:
        return 'Brak mleczka (Dętka)';
      case TubelessSealantFormula.latexAmmoniaFree:
        return 'Lateksowe Standard';
      case TubelessSealantFormula.syntheticMicrofiberRace:
        return 'Wyścigowe z Mikrowłóknami';
      case TubelessSealantFormula.heavyDutyUltraEndurance:
        return 'Ultra-Endurance (Odporne na Upał)';
    }
  }
}

/// Wynik próby samonaprawy przebicia przez mleczko Tubeless.
class SealantPunctureOutcome {
  final bool sealedSuccessfully;
  final double sealantConsumedMl;
  final double pressureLostBar;
  final TubelessSealantSpec updatedSealantState;
  final String reasonCode;

  const SealantPunctureOutcome({
    required this.sealedSuccessfully,
    required this.sealantConsumedMl,
    required this.pressureLostBar,
    required this.updatedSealantState,
    required this.reasonCode,
  });
}

/// Stan i specyfikacja mleczka uszczelniającego `Tubeless Sealant` w obu kołach.
class TubelessSealantSpec {
  static const double sealantDensityKgPerLiter = 1.02;

  final String id;
  final String name;
  final TubelessSealantFormula formula;
  final double initialVolumeMlPerTire;
  final double remainingVolumeMlFront;
  final double remainingVolumeMlRear;
  final double maxSealablePunctureMm;
  final double sealingSuccessBaseProbability;
  final double pressureLossPerSealBar;
  final double evaporationRateMlPerHourAt30C;
  final int priceEur;

  const TubelessSealantSpec({
    required this.id,
    required this.name,
    required this.formula,
    required this.initialVolumeMlPerTire,
    required this.remainingVolumeMlFront,
    required this.remainingVolumeMlRear,
    required this.maxSealablePunctureMm,
    required this.sealingSuccessBaseProbability,
    required this.pressureLossPerSealBar,
    required this.evaporationRateMlPerHourAt30C,
    required this.priceEur,
  });

  const TubelessSealantSpec.raceMicrofiber({double volumeMlPerTire = 80.0})
      : id = 'sealant_race_microfiber',
        name = 'Silca / Orange Race Microfiber Sealant',
        formula = TubelessSealantFormula.syntheticMicrofiberRace,
        initialVolumeMlPerTire = volumeMlPerTire,
        remainingVolumeMlFront = volumeMlPerTire,
        remainingVolumeMlRear = volumeMlPerTire,
        maxSealablePunctureMm = 6.5,
        sealingSuccessBaseProbability = 0.92,
        pressureLossPerSealBar = 0.22,
        evaporationRateMlPerHourAt30C = 2.6,
        priceEur = 28;

  const TubelessSealantSpec.ultraEndurance({double volumeMlPerTire = 100.0})
      : id = 'sealant_ultra_endurance',
        name = 'Endurance Ultra-Heat Gravel Sealant',
        formula = TubelessSealantFormula.heavyDutyUltraEndurance,
        initialVolumeMlPerTire = volumeMlPerTire,
        remainingVolumeMlFront = volumeMlPerTire,
        remainingVolumeMlRear = volumeMlPerTire,
        maxSealablePunctureMm = 5.5,
        sealingSuccessBaseProbability = 0.88,
        pressureLossPerSealBar = 0.25,
        evaporationRateMlPerHourAt30C = 1.2,
        priceEur = 32;

  const TubelessSealantSpec.none()
      : id = 'sealant_none',
        name = 'Brak mleczka Tubeless',
        formula = TubelessSealantFormula.none,
        initialVolumeMlPerTire = 0.0,
        remainingVolumeMlFront = 0.0,
        remainingVolumeMlRear = 0.0,
        maxSealablePunctureMm = 0.0,
        sealingSuccessBaseProbability = 0.0,
        pressureLossPerSealBar = 0.0,
        evaporationRateMlPerHourAt30C = 0.0,
        priceEur = 0;

  bool get isActive =>
      formula != TubelessSealantFormula.none &&
      (remainingVolumeMlFront > 5.0 || remainingVolumeMlRear > 5.0);

  double get totalRemainingVolumeMl =>
      remainingVolumeMlFront.clamp(0.0, 250.0) +
      remainingVolumeMlRear.clamp(0.0, 250.0);

  /// Całkowita masa mleczka w obu kołach [kg].
  double get totalWeightKg =>
      (totalRemainingVolumeMl / 1000.0) * sealantDensityKgPerLiter;

  /// Minimalna wymagana ilość mleczka do zalepienia dziury o danej średnicy.
  double requiredMlForPuncture(double punctureSizeMm) {
    return (8.0 + (punctureSizeMm.clamp(0.5, 10.0) * 3.5));
  }

  /// Sprawdza czy w wybranym kole jest dość mleczka oraz czy rozmiar przebicia jest uszczelnialny.
  bool canAttemptSelfSeal({
    required double punctureSizeMm,
    required bool isFrontWheel,
  }) {
    if (formula == TubelessSealantFormula.none) return false;
    if (punctureSizeMm > maxSealablePunctureMm) return false;
    final availableMl =
        isFrontWheel ? remainingVolumeMlFront : remainingVolumeMlRear;
    return availableMl >= requiredMlForPuncture(punctureSizeMm);
  }

  /// Szacuje prawdopodobieństwo samonaprawy przebicia (0.0–1.0) bez zużycia zasobu.
  double estimateSealProbability({
    required double punctureSizeMm,
    required bool isFrontWheel,
  }) {
    if (!canAttemptSelfSeal(
      punctureSizeMm: punctureSizeMm,
      isFrontWheel: isFrontWheel,
    )) {
      return 0.0;
    }
    final sizeRatio =
        (punctureSizeMm / maxSealablePunctureMm).clamp(0.0, 1.0);
    final penalty = sizeRatio * 0.35;
    return (sealingSuccessBaseProbability - penalty).clamp(0.10, 0.98);
  }

  /// Symuluje próbę zalepienia przebicia i zwraca zaktualizowany stan mleczka.
  SealantPunctureOutcome consumeSealantForPuncture({
    required double punctureSizeMm,
    required bool isFrontWheel,
    required double deterministicRoll01,
  }) {
    if (formula == TubelessSealantFormula.none) {
      return SealantPunctureOutcome(
        sealedSuccessfully: false,
        sealantConsumedMl: 0.0,
        pressureLostBar: 1.80,
        updatedSealantState: this,
        reasonCode: 'NO_SEALANT',
      );
    }

    final availableMl =
        isFrontWheel ? remainingVolumeMlFront : remainingVolumeMlRear;
    final neededMl = requiredMlForPuncture(punctureSizeMm);

    if (punctureSizeMm > maxSealablePunctureMm) {
      final sprayedMl = math.min(availableMl, neededMl * 1.4);
      final updated = _withReducedVolume(
        isFrontWheel: isFrontWheel,
        consumedMl: sprayedMl,
      );
      return SealantPunctureOutcome(
        sealedSuccessfully: false,
        sealantConsumedMl: sprayedMl,
        pressureLostBar: 1.65,
        updatedSealantState: updated,
        reasonCode: 'PUNCTURE_TOO_LARGE',
      );
    }

    if (availableMl < neededMl) {
      final updated = _withReducedVolume(
        isFrontWheel: isFrontWheel,
        consumedMl: availableMl,
      );
      return SealantPunctureOutcome(
        sealedSuccessfully: false,
        sealantConsumedMl: availableMl,
        pressureLostBar: 1.50,
        updatedSealantState: updated,
        reasonCode: 'SEALANT_DEPLETED',
      );
    }

    final probability = estimateSealProbability(
      punctureSizeMm: punctureSizeMm,
      isFrontWheel: isFrontWheel,
    );
    final sealed = deterministicRoll01.clamp(0.0, 1.0) <= probability;
    final consumedMl = sealed ? neededMl : neededMl * 1.35;
    final pressureLoss = sealed
        ? (pressureLossPerSealBar * (0.8 + (punctureSizeMm / maxSealablePunctureMm) * 0.6))
        : 1.55;

    return SealantPunctureOutcome(
      sealedSuccessfully: sealed,
      sealantConsumedMl: consumedMl,
      pressureLostBar: pressureLoss,
      updatedSealantState: _withReducedVolume(
        isFrontWheel: isFrontWheel,
        consumedMl: consumedMl,
      ),
      reasonCode: sealed ? 'SEALED_IN_MOTION' : 'SEAL_FAILED',
    );
  }

  /// Odparowanie mleczka w trakcie długiego wyścigu w wysokiej temperaturze.
  TubelessSealantSpec applyHeatEvaporation({
    required double durationHours,
    required double ambientTempC,
  }) {
    if (formula == TubelessSealantFormula.none || durationHours <= 0.0) {
      return this;
    }
    final tempScale = ((ambientTempC - 15.0) / 15.0).clamp(0.25, 2.2);
    final lossMl = evaporationRateMlPerHourAt30C * durationHours * tempScale;
    return copyWith(
      remainingVolumeMlFront: (remainingVolumeMlFront - lossMl).clamp(0.0, 250.0),
      remainingVolumeMlRear: (remainingVolumeMlRear - lossMl).clamp(0.0, 250.0),
    );
  }

  TubelessSealantSpec _withReducedVolume({
    required bool isFrontWheel,
    required double consumedMl,
  }) {
    if (isFrontWheel) {
      return copyWith(
        remainingVolumeMlFront:
            (remainingVolumeMlFront - consumedMl).clamp(0.0, 250.0),
      );
    }
    return copyWith(
      remainingVolumeMlRear:
          (remainingVolumeMlRear - consumedMl).clamp(0.0, 250.0),
    );
  }

  TubelessSealantSpec copyWith({
    String? id,
    String? name,
    TubelessSealantFormula? formula,
    double? initialVolumeMlPerTire,
    double? remainingVolumeMlFront,
    double? remainingVolumeMlRear,
    double? maxSealablePunctureMm,
    double? sealingSuccessBaseProbability,
    double? pressureLossPerSealBar,
    double? evaporationRateMlPerHourAt30C,
    int? priceEur,
  }) {
    return TubelessSealantSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      formula: formula ?? this.formula,
      initialVolumeMlPerTire:
          initialVolumeMlPerTire ?? this.initialVolumeMlPerTire,
      remainingVolumeMlFront:
          remainingVolumeMlFront ?? this.remainingVolumeMlFront,
      remainingVolumeMlRear:
          remainingVolumeMlRear ?? this.remainingVolumeMlRear,
      maxSealablePunctureMm:
          maxSealablePunctureMm ?? this.maxSealablePunctureMm,
      sealingSuccessBaseProbability:
          sealingSuccessBaseProbability ?? this.sealingSuccessBaseProbability,
      pressureLossPerSealBar:
          pressureLossPerSealBar ?? this.pressureLossPerSealBar,
      evaporationRateMlPerHourAt30C:
          evaporationRateMlPerHourAt30C ?? this.evaporationRateMlPerHourAt30C,
      priceEur: priceEur ?? this.priceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formula': formula.toJson(),
      'initialVolumeMlPerTire': initialVolumeMlPerTire,
      'remainingVolumeMlFront': remainingVolumeMlFront,
      'remainingVolumeMlRear': remainingVolumeMlRear,
      'maxSealablePunctureMm': maxSealablePunctureMm,
      'sealingSuccessBaseProbability': sealingSuccessBaseProbability,
      'pressureLossPerSealBar': pressureLossPerSealBar,
      'evaporationRateMlPerHourAt30C': evaporationRateMlPerHourAt30C,
      'priceEur': priceEur,
    };
  }

  factory TubelessSealantSpec.fromJson(Map<String, dynamic> json) {
    return TubelessSealantSpec(
      id: json['id'] as String? ?? 'sealant_race_microfiber',
      name: json['name'] as String? ?? 'Race Microfiber Sealant',
      formula: TubelessSealantFormula.fromJson(
        json['formula'] as String? ?? 'syntheticMicrofiberRace',
      ),
      initialVolumeMlPerTire:
          (json['initialVolumeMlPerTire'] as num?)?.toDouble() ?? 80.0,
      remainingVolumeMlFront:
          (json['remainingVolumeMlFront'] as num?)?.toDouble() ?? 80.0,
      remainingVolumeMlRear:
          (json['remainingVolumeMlRear'] as num?)?.toDouble() ?? 80.0,
      maxSealablePunctureMm:
          (json['maxSealablePunctureMm'] as num?)?.toDouble() ?? 6.5,
      sealingSuccessBaseProbability:
          (json['sealingSuccessBaseProbability'] as num?)?.toDouble() ?? 0.90,
      pressureLossPerSealBar:
          (json['pressureLossPerSealBar'] as num?)?.toDouble() ?? 0.22,
      evaporationRateMlPerHourAt30C:
          (json['evaporationRateMlPerHourAt30C'] as num?)?.toDouble() ?? 2.4,
      priceEur: (json['priceEur'] as num?)?.toInt() ?? 28,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TubelessSealantSpec &&
        other.id == id &&
        other.formula == formula &&
        other.remainingVolumeMlFront == remainingVolumeMlFront &&
        other.remainingVolumeMlRear == remainingVolumeMlRear;
  }

  @override
  int get hashCode => Object.hash(
        id,
        formula,
        remainingVolumeMlFront,
        remainingVolumeMlRear,
      );
}

/// Klasa plecaka bukłakowego (`Aero Hydration Pack`) do wyścigów szutrowych.
enum AeroHydrationPackTier {
  /// Brak plecaka — kolarz korzysta wyłącznie z bidonów na ramie.
  none,

  /// Minimalistyczna kamizelka aero 1.5 L wygładzająca strugę powietrza za karkiem.
  minimalistAeroVest1500Ml,

  /// Wyścigowy plecak 2.0 L z kieszeniami na żele i zestaw naprawczy na klatce.
  enduranceRacePack2000Ml,

  /// Plecak wyprawowy 3.0 L do najdłuższych wyścigów Ultra-Gravel (300+ km).
  ultraExpeditionPack3000Ml;

  String toJson() => name;

  static AeroHydrationPackTier fromJson(String value) {
    return AeroHydrationPackTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AeroHydrationPackTier.none,
    );
  }

  String get displayNamePl {
    switch (this) {
      case AeroHydrationPackTier.none:
        return 'Brak plecaka (Tylko bidony)';
      case AeroHydrationPackTier.minimalistAeroVest1500Ml:
        return 'Kamizelka Aero 1.5 L';
      case AeroHydrationPackTier.enduranceRacePack2000Ml:
        return 'Plecak Wyścigowy 2.0 L';
      case AeroHydrationPackTier.ultraExpeditionPack3000Ml:
        return 'Plecak Ultra-Gravel 3.0 L';
    }
  }
}

/// Model plecaka bukłakowego `Aero Hydration Pack` z wpływem na aero CdA,
/// gospodarkę cieplną i bezdotykowe nawadnianie na wyboistym szutrze.
class AeroHydrationPackSpec {
  final String id;
  final String name;
  final AeroHydrationPackTier tier;
  final int dryWeightGrams;
  final double bladderCapacityMl;
  final double currentFluidMl;
  final double aeroCdaDelta;
  final double thermalInsulationFactor;
  final double heatTrapPenaltyC;
  final int extraCargoToolSlots;
  final double handsFreeDrinkingSafetyBonus;
  final int priceEur;

  const AeroHydrationPackSpec({
    required this.id,
    required this.name,
    required this.tier,
    required this.dryWeightGrams,
    required this.bladderCapacityMl,
    required this.currentFluidMl,
    required this.aeroCdaDelta,
    required this.thermalInsulationFactor,
    required this.heatTrapPenaltyC,
    required this.extraCargoToolSlots,
    required this.handsFreeDrinkingSafetyBonus,
    required this.priceEur,
  });

  const AeroHydrationPackSpec.none()
      : id = 'pack_none',
        name = 'Brak plecaka bukłakowego',
        tier = AeroHydrationPackTier.none,
        dryWeightGrams = 0,
        bladderCapacityMl = 0.0,
        currentFluidMl = 0.0,
        aeroCdaDelta = 0.0,
        thermalInsulationFactor = 0.0,
        heatTrapPenaltyC = 0.0,
        extraCargoToolSlots = 0,
        handsFreeDrinkingSafetyBonus = 0.0,
        priceEur = 0;

  const AeroHydrationPackSpec.aeroVest1500Ml({bool startFull = true})
      : id = 'pack_aero_vest_1500',
        name = 'Aero Streamline Hydration Vest 1.5L',
        tier = AeroHydrationPackTier.minimalistAeroVest1500Ml,
        dryWeightGrams = 245,
        bladderCapacityMl = 1500.0,
        currentFluidMl = startFull ? 1500.0 : 0.0,
        aeroCdaDelta = -0.0028,
        thermalInsulationFactor = 0.65,
        heatTrapPenaltyC = 0.14,
        extraCargoToolSlots = 2,
        handsFreeDrinkingSafetyBonus = 0.22,
        priceEur = 165;

  const AeroHydrationPackSpec.enduranceRace2000Ml({bool startFull = true})
      : id = 'pack_endurance_2000',
        name = 'Outlander Race Hydration Pack 2.0L',
        tier = AeroHydrationPackTier.enduranceRacePack2000Ml,
        dryWeightGrams = 330,
        bladderCapacityMl = 2000.0,
        currentFluidMl = startFull ? 2000.0 : 0.0,
        aeroCdaDelta = 0.0008,
        thermalInsulationFactor = 0.78,
        heatTrapPenaltyC = 0.24,
        extraCargoToolSlots = 4,
        handsFreeDrinkingSafetyBonus = 0.25,
        priceEur = 145;

  const AeroHydrationPackSpec.ultraExpedition3000Ml({bool startFull = true})
      : id = 'pack_ultra_3000',
        name = 'Unbound Ultra Expedition Pack 3.0L',
        tier = AeroHydrationPackTier.ultraExpeditionPack3000Ml,
        dryWeightGrams = 480,
        bladderCapacityMl = 3000.0,
        currentFluidMl = startFull ? 3000.0 : 0.0,
        aeroCdaDelta = 0.0042,
        thermalInsulationFactor = 0.85,
        heatTrapPenaltyC = 0.38,
        extraCargoToolSlots = 6,
        handsFreeDrinkingSafetyBonus = 0.25,
        priceEur = 185;

  bool get isEquipped => tier != AeroHydrationPackTier.none;

  /// Aktualna masa całkowita plecaka z płynem [kg].
  double get currentTotalWeightKg {
    if (!isEquipped) return 0.0;
    return (dryWeightGrams + currentFluidMl.clamp(0.0, bladderCapacityMl)) /
        1000.0;
  }

  /// Poziom wypełnienia bukłaka (0.0–1.0).
  double get hydrationFraction {
    if (bladderCapacityMl <= 0.0) return 0.0;
    return (currentFluidMl / bladderCapacityMl).clamp(0.0, 1.0);
  }

  /// Pobiera zadaną objętość płynu z bukłaka [ml].
  AeroHydrationPackSpec drink(double amountMl) {
    if (!isEquipped || amountMl <= 0.0) return this;
    return copyWith(
      currentFluidMl: (currentFluidMl - amountMl).clamp(0.0, bladderCapacityMl),
    );
  }

  /// Uzupełnia bukłak do pełnej pojemności na punkcie kontrolnym.
  AeroHydrationPackSpec refillToCapacity() {
    if (!isEquipped) return this;
    return copyWith(currentFluidMl: bladderCapacityMl);
  }

  AeroHydrationPackSpec copyWith({
    String? id,
    String? name,
    AeroHydrationPackTier? tier,
    int? dryWeightGrams,
    double? bladderCapacityMl,
    double? currentFluidMl,
    double? aeroCdaDelta,
    double? thermalInsulationFactor,
    double? heatTrapPenaltyC,
    int? extraCargoToolSlots,
    double? handsFreeDrinkingSafetyBonus,
    int? priceEur,
  }) {
    return AeroHydrationPackSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      tier: tier ?? this.tier,
      dryWeightGrams: dryWeightGrams ?? this.dryWeightGrams,
      bladderCapacityMl: bladderCapacityMl ?? this.bladderCapacityMl,
      currentFluidMl: currentFluidMl ?? this.currentFluidMl,
      aeroCdaDelta: aeroCdaDelta ?? this.aeroCdaDelta,
      thermalInsulationFactor:
          thermalInsulationFactor ?? this.thermalInsulationFactor,
      heatTrapPenaltyC: heatTrapPenaltyC ?? this.heatTrapPenaltyC,
      extraCargoToolSlots: extraCargoToolSlots ?? this.extraCargoToolSlots,
      handsFreeDrinkingSafetyBonus:
          handsFreeDrinkingSafetyBonus ?? this.handsFreeDrinkingSafetyBonus,
      priceEur: priceEur ?? this.priceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier.toJson(),
      'dryWeightGrams': dryWeightGrams,
      'bladderCapacityMl': bladderCapacityMl,
      'currentFluidMl': currentFluidMl,
      'aeroCdaDelta': aeroCdaDelta,
      'thermalInsulationFactor': thermalInsulationFactor,
      'heatTrapPenaltyC': heatTrapPenaltyC,
      'extraCargoToolSlots': extraCargoToolSlots,
      'handsFreeDrinkingSafetyBonus': handsFreeDrinkingSafetyBonus,
      'priceEur': priceEur,
    };
  }

  factory AeroHydrationPackSpec.fromJson(Map<String, dynamic> json) {
    return AeroHydrationPackSpec(
      id: json['id'] as String? ?? 'pack_none',
      name: json['name'] as String? ?? 'Brak plecaka bukłakowego',
      tier: AeroHydrationPackTier.fromJson(json['tier'] as String? ?? 'none'),
      dryWeightGrams: (json['dryWeightGrams'] as num?)?.toInt() ?? 0,
      bladderCapacityMl: (json['bladderCapacityMl'] as num?)?.toDouble() ?? 0.0,
      currentFluidMl: (json['currentFluidMl'] as num?)?.toDouble() ?? 0.0,
      aeroCdaDelta: (json['aeroCdaDelta'] as num?)?.toDouble() ?? 0.0,
      thermalInsulationFactor:
          (json['thermalInsulationFactor'] as num?)?.toDouble() ?? 0.0,
      heatTrapPenaltyC: (json['heatTrapPenaltyC'] as num?)?.toDouble() ?? 0.0,
      extraCargoToolSlots: (json['extraCargoToolSlots'] as num?)?.toInt() ?? 0,
      handsFreeDrinkingSafetyBonus:
          (json['handsFreeDrinkingSafetyBonus'] as num?)?.toDouble() ?? 0.0,
      priceEur: (json['priceEur'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AeroHydrationPackSpec &&
        other.id == id &&
        other.tier == tier &&
        other.currentFluidMl == currentFluidMl;
  }

  @override
  int get hashCode => Object.hash(id, tier, currentFluidMl);
}

/// Kategoria geometrii ramy szutrowej.
enum GravelBikeGeometryCategory {
  /// Rama Aero Gravel (UCI Gravel World Series, maksymalna prędkość na twardym szutrze).
  aeroGravelRace,

  /// Rama All-Road / Endurance Gravel (zbalansowany prześwit i tłumienie drgań).
  allRoadEnduranceGravel,

  /// Rama Ultra-Adventure (maksymalny prześwit 50+ mm, tłumienie i mocowania na wyprawy).
  ultraAdventureGravel;

  String toJson() => name;

  static GravelBikeGeometryCategory fromJson(String value) {
    return GravelBikeGeometryCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GravelBikeGeometryCategory.allRoadEnduranceGravel,
    );
  }

  String get displayNamePl {
    switch (this) {
      case GravelBikeGeometryCategory.aeroGravelRace:
        return 'Aero Gravel Race';
      case GravelBikeGeometryCategory.allRoadEnduranceGravel:
        return 'Endurance All-Road Gravel';
      case GravelBikeGeometryCategory.ultraAdventureGravel:
        return 'Ultra-Adventure Gravel (50+ mm)';
    }
  }
}

/// Specyfikacja ramy roweru szutrowego z limitem prześwitu opony.
class GravelBikeFrameSpec {
  final String id;
  final String brandId;
  final String name;
  final GravelBikeGeometryCategory geometryCategory;
  final int frameWeightGrams;
  final double maxTireClearanceMm;
  final double vibrationDampingIndex;
  final double aeroCdaModifier;
  final int bottleCageMountsCount;
  final int priceEur;

  const GravelBikeFrameSpec({
    required this.id,
    required this.brandId,
    required this.name,
    required this.geometryCategory,
    required this.frameWeightGrams,
    required this.maxTireClearanceMm,
    required this.vibrationDampingIndex,
    required this.aeroCdaModifier,
    required this.bottleCageMountsCount,
    required this.priceEur,
  });

  double get weightKg => frameWeightGrams / 1000.0;

  bool supportsTireWidth(double widthMm) => widthMm <= maxTireClearanceMm;

  GravelBikeFrameSpec copyWith({
    String? id,
    String? brandId,
    String? name,
    GravelBikeGeometryCategory? geometryCategory,
    int? frameWeightGrams,
    double? maxTireClearanceMm,
    double? vibrationDampingIndex,
    double? aeroCdaModifier,
    int? bottleCageMountsCount,
    int? priceEur,
  }) {
    return GravelBikeFrameSpec(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      geometryCategory: geometryCategory ?? this.geometryCategory,
      frameWeightGrams: frameWeightGrams ?? this.frameWeightGrams,
      maxTireClearanceMm: maxTireClearanceMm ?? this.maxTireClearanceMm,
      vibrationDampingIndex:
          vibrationDampingIndex ?? this.vibrationDampingIndex,
      aeroCdaModifier: aeroCdaModifier ?? this.aeroCdaModifier,
      bottleCageMountsCount:
          bottleCageMountsCount ?? this.bottleCageMountsCount,
      priceEur: priceEur ?? this.priceEur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'name': name,
      'geometryCategory': geometryCategory.toJson(),
      'frameWeightGrams': frameWeightGrams,
      'maxTireClearanceMm': maxTireClearanceMm,
      'vibrationDampingIndex': vibrationDampingIndex,
      'aeroCdaModifier': aeroCdaModifier,
      'bottleCageMountsCount': bottleCageMountsCount,
      'priceEur': priceEur,
    };
  }

  factory GravelBikeFrameSpec.fromJson(Map<String, dynamic> json) {
    return GravelBikeFrameSpec(
      id: json['id'] as String? ?? 'gravel_frame_default',
      brandId: json['brandId'] as String? ?? 'canyon_gravel',
      name: json['name'] as String? ?? 'Grail CFR Race',
      geometryCategory: GravelBikeGeometryCategory.fromJson(
        json['geometryCategory'] as String? ?? 'aeroGravelRace',
      ),
      frameWeightGrams: (json['frameWeightGrams'] as num?)?.toInt() ?? 960,
      maxTireClearanceMm:
          (json['maxTireClearanceMm'] as num?)?.toDouble() ?? 45.0,
      vibrationDampingIndex:
          (json['vibrationDampingIndex'] as num?)?.toDouble() ?? 3.6,
      aeroCdaModifier: (json['aeroCdaModifier'] as num?)?.toDouble() ?? -0.005,
      bottleCageMountsCount:
          (json['bottleCageMountsCount'] as num?)?.toInt() ?? 2,
      priceEur: (json['priceEur'] as num?)?.toInt() ?? 4200,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GravelBikeFrameSpec && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Raport gotowości zestawu sprzętu szutrowego na konkretny wyścig.
class GravelEquipmentRaceReadinessReport {
  final double suitabilityScore;
  final double weightedExpectedCrr;
  final double punctureProtectionRating;
  final double hydrationAutonomyHours;
  final bool isClearanceValid;
  final List<String> warnings;

  const GravelEquipmentRaceReadinessReport({
    required this.suitabilityScore,
    required this.weightedExpectedCrr,
    required this.punctureProtectionRating,
    required this.hydrationAutonomyHours,
    required this.isClearanceValid,
    required this.warnings,
  });
}

/// Kompletny model sprzętu szutrowego łączący rower szutrowy, opony 38–50 mm,
/// wkładki antyprzebiciowe `Foam Tire Inserts`, mleczko `Tubeless Sealant`
/// oraz plecak bukłakowy `Aero Hydration Pack`.
class GravelBikeAndTireInsertsModel {
  final String id;
  final String name;
  final GravelBikeFrameSpec frame;
  final GravelTireSpec frontTire;
  final GravelTireSpec rearTire;
  final double frontPressureBar;
  final double rearPressureBar;
  final FoamTireInsertSpec tireInserts;
  final TubelessSealantSpec tubelessSealant;
  final AeroHydrationPackSpec hydrationPack;
  final int wheelsetWeightGrams;
  final int groupsetWeightGrams;
  final int cockpitAndSaddleWeightGrams;
  final double frameBottlesCapacityMl;
  final double currentFrameBottlesFluidMl;
  final double mudAccumulationKg;

  const GravelBikeAndTireInsertsModel({
    required this.id,
    required this.name,
    required this.frame,
    required this.frontTire,
    required this.rearTire,
    required this.frontPressureBar,
    required this.rearPressureBar,
    required this.tireInserts,
    required this.tubelessSealant,
    required this.hydrationPack,
    this.wheelsetWeightGrams = 1380,
    this.groupsetWeightGrams = 2350,
    this.cockpitAndSaddleWeightGrams = 1120,
    this.frameBottlesCapacityMl = 1500.0,
    this.currentFrameBottlesFluidMl = 1500.0,
    this.mudAccumulationKg = 0.0,
  });

  /// Preset pod szybkie wyścigi UCI Gravel World Series (opony 40 mm, kamizelka aero 1.5 L).
  factory GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset() {
    const tire40 = GravelTireSpec(
      id: 'tire_terra_speed_40',
      brandId: 'continental',
      name: 'Terra Speed Pro 40mm',
      widthMm: 40.0,
      weightGramsPerTire: 435,
      baseCrr: 0.0045,
      treadPattern: GravelTireTreadPattern.semiSlickMicroKnob,
      casingType: GravelTireCasingType.raceSupple,
      punctureResistanceIndex: 3.1,
      sidewallProtectionIndex: 2.9,
      mudClearanceScore: 3.0,
      priceEur: 72,
    );
    return const GravelBikeAndTireInsertsModel(
      id: 'gravel_setup_uci_race',
      name: 'UCI Gravel World Series Aero Setup',
      frame: GravelBikeFrameSpec(
        id: 'frame_aero_gravel_cfr',
        brandId: 'canyon',
        name: 'Grail CFR Aero Gravel',
        geometryCategory: GravelBikeGeometryCategory.aeroGravelRace,
        frameWeightGrams: 930,
        maxTireClearanceMm: 44.0,
        vibrationDampingIndex: 3.5,
        aeroCdaModifier: -0.0065,
        bottleCageMountsCount: 2,
        priceEur: 4500,
      ),
      frontTire: tire40,
      rearTire: tire40,
      frontPressureBar: 2.45,
      rearPressureBar: 2.55,
      tireInserts: FoamTireInsertSpec.ultralightRace(),
      tubelessSealant: TubelessSealantSpec.raceMicrofiber(volumeMlPerTire: 75.0),
      hydrationPack: AeroHydrationPackSpec.aeroVest1500Ml(),
      wheelsetWeightGrams: 1310,
      groupsetWeightGrams: 2280,
      cockpitAndSaddleWeightGrams: 1050,
      frameBottlesCapacityMl: 1500.0,
      currentFrameBottlesFluidMl: 1500.0,
    );
  }

  /// Preset na najcięższe wyścigi Ultra-Gravel po ostrym krzemieniu (45 mm + HD Inserts + 2 L).
  factory GravelBikeAndTireInsertsModel.flintHillsUltraPreset() {
    const tire45 = GravelTireSpec(
      id: 'tire_pathfinder_armored_45',
      brandId: 'specialized',
      name: 'Pathfinder Pro Flint-Guard 45mm',
      widthMm: 45.0,
      weightGramsPerTire: 545,
      baseCrr: 0.0052,
      treadPattern: GravelTireTreadPattern.allRounderMediumKnob,
      casingType: GravelTireCasingType.armoredFlintGuard,
      punctureResistanceIndex: 4.5,
      sidewallProtectionIndex: 4.7,
      mudClearanceScore: 3.6,
      priceEur: 68,
    );
    return const GravelBikeAndTireInsertsModel(
      id: 'gravel_setup_flint_ultra',
      name: 'Flint Hills Ultra-Endurance Setup',
      frame: GravelBikeFrameSpec(
        id: 'frame_endurance_gravel_slx',
        brandId: 'trek',
        name: 'Checkpoint SLR IsoSpeed',
        geometryCategory: GravelBikeGeometryCategory.allRoadEnduranceGravel,
        frameWeightGrams: 1040,
        maxTireClearanceMm: 48.0,
        vibrationDampingIndex: 4.4,
        aeroCdaModifier: -0.0020,
        bottleCageMountsCount: 3,
        priceEur: 4200,
      ),
      frontTire: tire45,
      rearTire: tire45,
      frontPressureBar: 2.05,
      rearPressureBar: 2.15,
      tireInserts: FoamTireInsertSpec.flintGuardEnduro(),
      tubelessSealant: TubelessSealantSpec.ultraEndurance(volumeMlPerTire: 100.0),
      hydrationPack: AeroHydrationPackSpec.enduranceRace2000Ml(),
      wheelsetWeightGrams: 1420,
      groupsetWeightGrams: 2390,
      cockpitAndSaddleWeightGrams: 1120,
      frameBottlesCapacityMl: 2000.0,
      currentFrameBottlesFluidMl: 2000.0,
    );
  }

  /// Preset na ekstremalne błoto i techniczny singletrack (opony 50 mm + wkładki HD + 3 L).
  factory GravelBikeAndTireInsertsModel.technicalMudAndSingletrackPreset() {
    const tire50 = GravelTireSpec(
      id: 'tire_rammbler_mud_50',
      brandId: 'maxxis',
      name: 'Ravager Mud & Rock 50mm',
      widthMm: 50.0,
      weightGramsPerTire: 625,
      baseCrr: 0.0061,
      treadPattern: GravelTireTreadPattern.aggressiveMudAndFlintKnob,
      casingType: GravelTireCasingType.armoredFlintGuard,
      punctureResistanceIndex: 4.6,
      sidewallProtectionIndex: 4.8,
      mudClearanceScore: 4.8,
      priceEur: 74,
    );
    return const GravelBikeAndTireInsertsModel(
      id: 'gravel_setup_mud_50',
      name: 'Ultra-Adventure 50mm Mud Setup',
      frame: GravelBikeFrameSpec(
        id: 'frame_ultra_adventure_52',
        brandId: 'salsa',
        name: 'Cutthroat Carbon 52mm',
        geometryCategory: GravelBikeGeometryCategory.ultraAdventureGravel,
        frameWeightGrams: 1150,
        maxTireClearanceMm: 52.0,
        vibrationDampingIndex: 4.8,
        aeroCdaModifier: 0.0025,
        bottleCageMountsCount: 4,
        priceEur: 3800,
      ),
      frontTire: tire50,
      rearTire: tire50,
      frontPressureBar: 1.75,
      rearPressureBar: 1.85,
      tireInserts: FoamTireInsertSpec.flintGuardEnduro(),
      tubelessSealant: TubelessSealantSpec.ultraEndurance(volumeMlPerTire: 110.0),
      hydrationPack: AeroHydrationPackSpec.ultraExpedition3000Ml(),
      wheelsetWeightGrams: 1510,
      groupsetWeightGrams: 2450,
      cockpitAndSaddleWeightGrams: 1180,
      frameBottlesCapacityMl: 2250.0,
      currentFrameBottlesFluidMl: 2250.0,
    );
  }

  /// Czy obie opony mieszczą się w zakresie 38–50 mm i w prześwicie ramy.
  bool get isTireClearanceValid =>
      frontTire.isWithinGravelRange &&
      rearTire.isWithinGravelRange &&
      frame.supportsTireWidth(frontTire.widthMm) &&
      frame.supportsTireWidth(rearTire.widthMm);

  /// Czy zamontowane wkładki `Foam Tire Inserts` pasują do obu szerokości opon.
  bool get isInsertWidthCompatible =>
      tireInserts.isCompatibleWithTireWidth(frontTire.widthMm) &&
      tireInserts.isCompatibleWithTireWidth(rearTire.widthMm);

  /// Lista ostrzeżeń konfiguracyjnych (pusta przy poprawnym zestawie).
  List<String> get configurationWarnings {
    final warnings = <String>[];
    if (!frontTire.isWithinGravelRange || !rearTire.isWithinGravelRange) {
      warnings.add('Szerokość opon szutrowych musi mieścić się w zakresie 38–50 mm.');
    }
    if (!frame.supportsTireWidth(frontTire.widthMm) ||
        !frame.supportsTireWidth(rearTire.widthMm)) {
      warnings.add(
        'Opony przekraczają maksymalny prześwit ramy (${frame.maxTireClearanceMm.toStringAsFixed(0)} mm).',
      );
    }
    if (!isInsertWidthCompatible) {
      warnings.add('Wkładki piankowe nie pasują do wybranej szerokości opony.');
    }
    if (frontPressureBar < 1.4 || rearPressureBar < 1.4) {
      warnings.add('Zbyt niskie ciśnienie (<1.4 bar) grozi dobiciem obręczy lub spadnięciem opony.');
    }
    return warnings;
  }

  bool get hasValidConfiguration => configurationWarnings.isEmpty;

  /// Masa suchego roweru bez wkładek, mleczka, płynów i błota [kg].
  double get dryBikeWeightKg {
    final baseGrams = frame.frameWeightGrams +
        wheelsetWeightGrams +
        groupsetWeightGrams +
        cockpitAndSaddleWeightGrams +
        frontTire.weightGramsPerTire +
        rearTire.weightGramsPerTire;
    return baseGrams / 1000.0;
  }

  /// Całkowita masa systemu (rower + wkładki + mleczko + plecak z płynem + bidony + błoto) [kg].
  double get totalSystemWeightKg {
    final frameFluidKg =
        currentFrameBottlesFluidMl.clamp(0.0, frameBottlesCapacityMl) / 1000.0;
    return dryBikeWeightKg +
        tireInserts.totalWeightKg +
        tubelessSealant.totalWeightKg +
        hydrationPack.currentTotalWeightKg +
        frameFluidKg +
        mudAccumulationKg.clamp(0.0, 5.0);
  }

  /// Łączna pojemność nawadniania (bidony na ramie + plecak bukłakowy) [ml].
  double get totalHydrationCapacityMl =>
      frameBottlesCapacityMl + hydrationPack.bladderCapacityMl;

  /// Łączna dostępna ilość płynu [ml].
  double get totalRemainingFluidMl =>
      currentFrameBottlesFluidMl.clamp(0.0, frameBottlesCapacityMl) +
      hydrationPack.currentFluidMl.clamp(0.0, hydrationPack.bladderCapacityMl);

  /// Łączny modyfikator oporu aerodynamicznego CdA [m²] (rama + plecak + szerokość opon).
  double get effectiveCdaModifier {
    final avgWidth = (frontTire.widthMm + rearTire.widthMm) * 0.5;
    final tireAeroPenalty = ((avgWidth - 38.0).clamp(0.0, 14.0)) * 0.00055;
    return frame.aeroCdaModifier +
        hydrationPack.aeroCdaDelta +
        tireAeroPenalty;
  }

  /// Efektywny opór toczenia CRR całego zestawu na danej nawierzchni szutrowej.
  double effectiveCrrForSurface(GravelSurfaceCategory surface) {
    final frontCrr = frontTire.effectiveCrrForSurface(surface);
    final rearCrr = rearTire.effectiveCrrForSurface(surface);
    final baseTireCrr = (frontCrr * 0.45) + (rearCrr * 0.55);

    // Wpływ ciśnienia względem zalecanego (uwzględniając pozwolenie z wkładek piankowych).
    final avgPressure = (frontPressureBar + rearPressureBar) * 0.5;
    final idealPressure = (surface.recommendedTirePressureBar -
            tireInserts.pressureReductionAllowanceBar)
        .clamp(1.55, 3.30);
    final pressureDelta = (avgPressure - idealPressure).abs();

    // Na nierównym szutrze zbyt wysokie ciśnienie mocno zwiększa straty impedancyjne.
    final impedancePenalty = surface.categoryNumber >= 3 && avgPressure > idealPressure
        ? 1.0 + (pressureDelta * 0.14)
        : 1.0 + (pressureDelta * 0.06);

    return (baseTireCrr * impedancePenalty) +
        tireInserts.hysteresisRollingPenaltyCrr;
  }

  /// Mnożnik ryzyka przebicia dla zestawu (niżej = bezpieczniej).
  double effectivePunctureRiskFactor(GravelSurfaceCategory surface) {
    final avgPunctureResistance = ((frontTire.punctureResistanceIndex +
                rearTire.punctureResistanceIndex) *
            0.5)
        .clamp(1.0, 5.0);
    final avgSidewall = ((frontTire.sidewallProtectionIndex +
                rearTire.sidewallProtectionIndex) *
            0.5)
        .clamp(1.0, 5.0);

    final casingProtection =
        ((frontTire.casingType.sidewallCutProtectionMultiplier +
                    rearTire.casingType.sidewallCutProtectionMultiplier) *
                0.5)
            .clamp(0.6, 2.0);

    final baseResistance =
        (avgPunctureResistance * 0.65) + (avgSidewall * 0.35 * casingProtection);
    final sealantBonus = tubelessSealant.isActive ? 1.35 : 0.90;
    final insertFactor = tireInserts.pinchFlatRiskMultiplier;

    return (surface.punctureRiskFactor * insertFactor) /
        (baseResistance * 0.38 * sealantBonus);
  }

  /// Współczynnik tłumienia drgań odciążający mięśnie i stawy (0.0–1.0, wyżej = większy komfort).
  double get vibrationFatigueMitigationFactor {
    final frameScore = (frame.vibrationDampingIndex / 5.0).clamp(0.0, 1.0);
    final widthScore =
        (((frontTire.widthMm + rearTire.widthMm) * 0.5 - 38.0) / 12.0)
            .clamp(0.0, 1.0);
    final insertScore = tireInserts.isInstalled
        ? tireInserts.rimImpactDampingFactor.clamp(0.0, 1.0)
        : 0.0;
    return ((frameScore * 0.38) + (widthScore * 0.38) + (insertScore * 0.24))
        .clamp(0.05, 0.98);
  }

  /// Pobiera płyn najpierw z plecaka bukłakowego (bezpieczniejsze na szutrze), a potem z bidonów.
  GravelBikeAndTireInsertsModel consumeFluid(double amountMl) {
    if (amountMl <= 0.0) return this;
    final fromPack = math.min(amountMl, hydrationPack.currentFluidMl);
    final remainingNeed = amountMl - fromPack;
    final updatedPack = hydrationPack.drink(fromPack);
    final updatedBottles =
        (currentFrameBottlesFluidMl - remainingNeed).clamp(0.0, frameBottlesCapacityMl);
    return copyWith(
      hydrationPack: updatedPack,
      currentFrameBottlesFluidMl: updatedBottles,
    );
  }

  /// Ocenia dopasowanie obecnego zestawu sprzętu do profilu wyścigu szutrowego.
  GravelEquipmentRaceReadinessReport evaluateForRace(
    GravelRaceAndSurfaceModel race,
  ) {
    final warnings = List<String>.from(configurationWarnings);

    // Oblicz średni ważony CRR na trasie wyścigu.
    final totalSegKm =
        race.segments.fold<double>(0.0, (sum, s) => sum + s.lengthKm);
    double weightedCrr;
    if (totalSegKm <= 0.0) {
      weightedCrr = effectiveCrrForSurface(
        GravelSurfaceCategory.cat2CompactedForestRoad,
      );
    } else {
      weightedCrr = race.segments.fold<double>(
            0.0,
            (sum, s) =>
                sum + (effectiveCrrForSurface(s.surfaceCategory) * s.lengthKm),
          ) /
          totalSegKm;
    }

    final avgWidth = (frontTire.widthMm + rearTire.widthMm) * 0.5;
    if (avgWidth + 2.0 < race.recommendedTireWidthMm) {
      warnings.add(
        'Opony (${avgWidth.toStringAsFixed(0)} mm) są węższe niż zalecane na ten wyścig (${race.recommendedTireWidthMm.toStringAsFixed(0)} mm).',
      );
    }

    // Szacowana autonomia nawadniania (zakładane zapotrzebowanie 650–950 ml/h zależnie od temp.).
    final hourlyDrinkMl =
        (650.0 + ((race.ambientTemperatureC - 18.0).clamp(0.0, 20.0) * 18.0));
    final autonomyHours = totalRemainingFluidMl / hourlyDrinkMl;

    if (race.totalDistanceKm > 160.0 && !hydrationPack.isEquipped) {
      warnings.add(
        'Na dystansie Ultra-Gravel (>160 km) zalecany jest plecak bukłakowy Aero Hydration Pack.',
      );
    }

    final weightedDifficulty = race.weightedSurfaceDifficulty;
    if (weightedDifficulty >= 3.2 && !tireInserts.isInstalled) {
      warnings.add(
        'Trudna nawierzchnia (Kat. ${weightedDifficulty.toStringAsFixed(1)}) — rozważ wkładki Foam Tire Inserts.',
      );
    }

    final avgPunctureRisk = effectivePunctureRiskFactor(
      weightedDifficulty >= 3.5
          ? GravelSurfaceCategory.cat4SharpFlintAndChunkyRock
          : GravelSurfaceCategory.cat2CompactedForestRoad,
    );
    final punctureProtectionRating =
        (100.0 - (avgPunctureRisk * 32.0)).clamp(10.0, 99.0);

    // Punktacja przydatności 0–100.
    var score = 82.0;
    score -= (weightedCrr - 0.0065).clamp(0.0, 0.020) * 1800.0;
    score += vibrationFatigueMitigationFactor * 14.0;
    if (isTireClearanceValid) {
      score += 6.0;
    } else {
      score -= 25.0;
    }
    if (!isInsertWidthCompatible) score -= 12.0;
    if (avgWidth + 2.0 < race.recommendedTireWidthMm) score -= 10.0;
    if (race.totalDistanceKm > 160.0 && hydrationPack.isEquipped) score += 5.0;

    return GravelEquipmentRaceReadinessReport(
      suitabilityScore: score.clamp(0.0, 100.0),
      weightedExpectedCrr: weightedCrr,
      punctureProtectionRating: punctureProtectionRating,
      hydrationAutonomyHours: autonomyHours,
      isClearanceValid: isTireClearanceValid,
      warnings: warnings,
    );
  }

  GravelBikeAndTireInsertsModel copyWith({
    String? id,
    String? name,
    GravelBikeFrameSpec? frame,
    GravelTireSpec? frontTire,
    GravelTireSpec? rearTire,
    double? frontPressureBar,
    double? rearPressureBar,
    FoamTireInsertSpec? tireInserts,
    TubelessSealantSpec? tubelessSealant,
    AeroHydrationPackSpec? hydrationPack,
    int? wheelsetWeightGrams,
    int? groupsetWeightGrams,
    int? cockpitAndSaddleWeightGrams,
    double? frameBottlesCapacityMl,
    double? currentFrameBottlesFluidMl,
    double? mudAccumulationKg,
  }) {
    return GravelBikeAndTireInsertsModel(
      id: id ?? this.id,
      name: name ?? this.name,
      frame: frame ?? this.frame,
      frontTire: frontTire ?? this.frontTire,
      rearTire: rearTire ?? this.rearTire,
      frontPressureBar: frontPressureBar ?? this.frontPressureBar,
      rearPressureBar: rearPressureBar ?? this.rearPressureBar,
      tireInserts: tireInserts ?? this.tireInserts,
      tubelessSealant: tubelessSealant ?? this.tubelessSealant,
      hydrationPack: hydrationPack ?? this.hydrationPack,
      wheelsetWeightGrams: wheelsetWeightGrams ?? this.wheelsetWeightGrams,
      groupsetWeightGrams: groupsetWeightGrams ?? this.groupsetWeightGrams,
      cockpitAndSaddleWeightGrams:
          cockpitAndSaddleWeightGrams ?? this.cockpitAndSaddleWeightGrams,
      frameBottlesCapacityMl:
          frameBottlesCapacityMl ?? this.frameBottlesCapacityMl,
      currentFrameBottlesFluidMl:
          currentFrameBottlesFluidMl ?? this.currentFrameBottlesFluidMl,
      mudAccumulationKg: mudAccumulationKg ?? this.mudAccumulationKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'frame': frame.toJson(),
      'frontTire': frontTire.toJson(),
      'rearTire': rearTire.toJson(),
      'frontPressureBar': frontPressureBar,
      'rearPressureBar': rearPressureBar,
      'tireInserts': tireInserts.toJson(),
      'tubelessSealant': tubelessSealant.toJson(),
      'hydrationPack': hydrationPack.toJson(),
      'wheelsetWeightGrams': wheelsetWeightGrams,
      'groupsetWeightGrams': groupsetWeightGrams,
      'cockpitAndSaddleWeightGrams': cockpitAndSaddleWeightGrams,
      'frameBottlesCapacityMl': frameBottlesCapacityMl,
      'currentFrameBottlesFluidMl': currentFrameBottlesFluidMl,
      'mudAccumulationKg': mudAccumulationKg,
    };
  }

  factory GravelBikeAndTireInsertsModel.fromJson(Map<String, dynamic> json) {
    return GravelBikeAndTireInsertsModel(
      id: json['id'] as String? ?? 'gravel_setup_default',
      name: json['name'] as String? ?? 'Gravel Setup',
      frame: GravelBikeFrameSpec.fromJson(
        (json['frame'] as Map<String, dynamic>?) ?? const {},
      ),
      frontTire: GravelTireSpec.fromJson(
        (json['frontTire'] as Map<String, dynamic>?) ?? const {},
      ),
      rearTire: GravelTireSpec.fromJson(
        (json['rearTire'] as Map<String, dynamic>?) ?? const {},
      ),
      frontPressureBar: (json['frontPressureBar'] as num?)?.toDouble() ?? 2.30,
      rearPressureBar: (json['rearPressureBar'] as num?)?.toDouble() ?? 2.40,
      tireInserts: FoamTireInsertSpec.fromJson(
        (json['tireInserts'] as Map<String, dynamic>?) ?? const {},
      ),
      tubelessSealant: TubelessSealantSpec.fromJson(
        (json['tubelessSealant'] as Map<String, dynamic>?) ?? const {},
      ),
      hydrationPack: AeroHydrationPackSpec.fromJson(
        (json['hydrationPack'] as Map<String, dynamic>?) ?? const {},
      ),
      wheelsetWeightGrams:
          (json['wheelsetWeightGrams'] as num?)?.toInt() ?? 1380,
      groupsetWeightGrams:
          (json['groupsetWeightGrams'] as num?)?.toInt() ?? 2350,
      cockpitAndSaddleWeightGrams:
          (json['cockpitAndSaddleWeightGrams'] as num?)?.toInt() ?? 1120,
      frameBottlesCapacityMl:
          (json['frameBottlesCapacityMl'] as num?)?.toDouble() ?? 1500.0,
      currentFrameBottlesFluidMl:
          (json['currentFrameBottlesFluidMl'] as num?)?.toDouble() ?? 1500.0,
      mudAccumulationKg:
          (json['mudAccumulationKg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GravelBikeAndTireInsertsModel &&
        other.id == id &&
        other.frame == frame &&
        other.frontTire == frontTire &&
        other.rearTire == rearTire &&
        other.tireInserts == tireInserts &&
        other.tubelessSealant == tubelessSealant &&
        other.hydrationPack == hydrationPack;
  }

  @override
  int get hashCode => Object.hash(
        id,
        frame,
        frontTire,
        rearTire,
        tireInserts,
        tubelessSealant,
        hydrationPack,
      );

  @override
  String toString() =>
      'GravelBikeAndTireInsertsModel($name, ${frontTire.widthMm.toStringAsFixed(0)}/${rearTire.widthMm.toStringAsFixed(0)}mm, ${totalSystemWeightKg.toStringAsFixed(2)}kg)';
}
