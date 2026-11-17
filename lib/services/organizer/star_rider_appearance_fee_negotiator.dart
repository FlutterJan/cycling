import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/organizer/race_organizer_empire_model.dart';

/// Archetyp gwiazdy peletonu wpływający na wymagania dotyczące trasy i premii TV.
enum StarRiderArchetype {
  gcContender,
  pureSprinter,
  classicsSpecialist,
  timeTrialSpecialist,
  allRounderSuperstar;

  String toJson() => name;

  static StarRiderArchetype fromJson(String value) {
    return StarRiderArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StarRiderArchetype.gcContender,
    );
  }

  String get displayNamePl {
    switch (this) {
      case StarRiderArchetype.gcContender:
        return 'Lider Klasyfikacji Generalnej (GC)';
      case StarRiderArchetype.pureSprinter:
        return 'Czysty Sprinter';
      case StarRiderArchetype.classicsSpecialist:
        return 'Specjalista Klasyków / Puncheur';
      case StarRiderArchetype.timeTrialSpecialist:
        return 'Mistrz Jazdy na Czas (ITT)';
      case StarRiderArchetype.allRounderSuperstar:
        return 'Supergwiazda Wszechstronna';
    }
  }

  String get shortTag {
    switch (this) {
      case StarRiderArchetype.gcContender:
        return 'GC';
      case StarRiderArchetype.pureSprinter:
        return 'SPR';
      case StarRiderArchetype.classicsSpecialist:
        return 'CLX';
      case StarRiderArchetype.timeTrialSpecialist:
        return 'ITT';
      case StarRiderArchetype.allRounderSuperstar:
        return 'STAR';
    }
  }
}

/// Ranga marketingowa i prestiż gwiazdy determinująca cenę wywoławczą i wzrost oglądalności.
enum StarPrestigeTier {
  generationalIcon,
  grandTourWinner,
  worldTourStar,
  risingPhenom;

  String toJson() => name;

  static StarPrestigeTier fromJson(String value) {
    return StarPrestigeTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StarPrestigeTier.worldTourStar,
    );
  }

  String get displayNamePl {
    switch (this) {
      case StarPrestigeTier.generationalIcon:
        return 'Ikona Pokolenia';
      case StarPrestigeTier.grandTourWinner:
        return 'Zwycięzca Wielkiego Touru';
      case StarPrestigeTier.worldTourStar:
        return 'Gwiazda WorldTour';
      case StarPrestigeTier.risingPhenom:
        return 'Wschodzący Fenomen';
    }
  }
}

/// Profil strategiczny zaprojektowanej trasy wyścigu.
enum CourseAttractionFocus {
  balancedTour,
  highMountainGcBattle,
  sprinterFestival,
  classicsCobblesPunch,
  timeTrialShowcase;

  String toJson() => name;

  static CourseAttractionFocus fromJson(String value) {
    return CourseAttractionFocus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CourseAttractionFocus.balancedTour,
    );
  }

  String get displayNamePl {
    switch (this) {
      case CourseAttractionFocus.balancedTour:
        return 'Zbalansowany Tour';
      case CourseAttractionFocus.highMountainGcBattle:
        return 'Alpejska Bitwa Liderów GC';
      case CourseAttractionFocus.sprinterFestival:
        return 'Festiwal Sprinterów';
      case CourseAttractionFocus.classicsCobblesPunch:
        return 'Klasyki, Bruk i Ścianki';
      case CourseAttractionFocus.timeTrialShowcase:
        return 'Arena Czasowców (ITT)';
    }
  }
}

/// Status negocjacji opłaty startowej (`Appearance Fee`) z gwiazdą.
enum AppearanceNegotiationStatus {
  available,
  inNegotiation,
  signed,
  walkedAway,
  blockedByCalendar;

  String toJson() => name;

  static AppearanceNegotiationStatus fromJson(String value) {
    return AppearanceNegotiationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AppearanceNegotiationStatus.available,
    );
  }

  String get displayNamePl {
    switch (this) {
      case AppearanceNegotiationStatus.available:
        return 'Dostępny do rozmów';
      case AppearanceNegotiationStatus.inNegotiation:
        return 'W trakcie negocjacji';
      case AppearanceNegotiationStatus.signed:
        return 'Kontrakt podpisany';
      case AppearanceNegotiationStatus.walkedAway:
        return 'Zerwał rozmowy';
      case AppearanceNegotiationStatus.blockedByCalendar:
        return 'Kolizja kalendarza';
    }
  }
}

/// Specyfikacja projektu trasy wyścigu oceniana przez liderów GC i sprinterów.
class CourseBlueprintSpec {
  final String raceId;
  final String raceName;
  final UciRaceClassificationTier tier;
  final int totalStages;
  final int flatSprintStages;
  final int hillyPuncheurStages;
  final int mountainFinishStages;
  final double ittKilometers;
  final int cobbleSectorsCount;
  final int summitFinishCount;
  final int bonificationSecondsPerStage;
  final int prizePoolEur;
  final double tvCoverageHoursPerStage;

  const CourseBlueprintSpec({
    required this.raceId,
    required this.raceName,
    required this.tier,
    required this.totalStages,
    required this.flatSprintStages,
    required this.hillyPuncheurStages,
    required this.mountainFinishStages,
    required this.ittKilometers,
    required this.cobbleSectorsCount,
    required this.summitFinishCount,
    required this.bonificationSecondsPerStage,
    required this.prizePoolEur,
    required this.tvCoverageHoursPerStage,
  });

  int get allocatedStages =>
      flatSprintStages + hillyPuncheurStages + mountainFinishStages;

  /// Ocena atrakcyjności trasy dla liderów GC (0..100).
  double get gcAttractivenessScore {
    final safeTotal = math.max(1, totalStages);
    final mountainRatio = (mountainFinishStages / safeTotal).clamp(0.0, 1.0);
    final summitBonus = (summitFinishCount * 9.5).clamp(0.0, 38.0);
    final ittScore = ittKilometers <= 0
        ? 0.0
        : (ittKilometers <= 55.0
            ? (ittKilometers / 55.0) * 24.0
            : math.max(10.0, 24.0 - (ittKilometers - 55.0) * 0.3));
    final tierBonus = switch (tier) {
      UciRaceClassificationTier.grandTour => 18.0,
      UciRaceClassificationTier.uci2Uwt => 15.0,
      UciRaceClassificationTier.monument => 10.0,
      UciRaceClassificationTier.uci2Pro => 10.0,
      _ => 5.0,
    };
    final prizeBonus = (prizePoolEur / 500000.0 * 10.0).clamp(0.0, 12.0);

    return ((mountainRatio * 34.0) +
            summitBonus +
            ittScore +
            tierBonus +
            prizeBonus)
        .clamp(0.0, 100.0);
  }

  /// Ocena atrakcyjności trasy dla sprinterów (0..100).
  double get sprinterAttractivenessScore {
    final safeTotal = math.max(1, totalStages);
    final flatRatio = (flatSprintStages / safeTotal).clamp(0.0, 1.0);
    final bonifScore = (bonificationSecondsPerStage * 2.2).clamp(0.0, 22.0);
    final tvScore = (tvCoverageHoursPerStage * 4.5).clamp(0.0, 20.0);
    final mountainPenalty =
        (mountainFinishStages / safeTotal > 0.65) ? 14.0 : 0.0;
    final flatStageCountBonus = (flatSprintStages * 4.5).clamp(0.0, 24.0);

    return ((flatRatio * 38.0) +
            flatStageCountBonus +
            bonifScore +
            tvScore -
            mountainPenalty)
        .clamp(0.0, 100.0);
  }

  /// Ocena atrakcyjności trasy dla klasykowców i puncheurów (0..100).
  double get classicsAttractivenessScore {
    final safeTotal = math.max(1, totalStages);
    final hillyRatio = (hillyPuncheurStages / safeTotal).clamp(0.0, 1.0);
    final cobbleBonus = (cobbleSectorsCount * 3.8).clamp(0.0, 34.0);
    final bonifScore = (bonificationSecondsPerStage * 1.4).clamp(0.0, 15.0);
    return ((hillyRatio * 46.0) + cobbleBonus + bonifScore + 12.0)
        .clamp(0.0, 100.0);
  }

  /// Ogólna ocena jakości projektu trasy (0..100).
  double get overallCourseQualityScore {
    final avg = (gcAttractivenessScore * 0.40) +
        (sprinterAttractivenessScore * 0.35) +
        (classicsAttractivenessScore * 0.25);
    final stageMismatchPenalty = (allocatedStages - totalStages).abs() * 3.5;
    return (avg - stageMismatchPenalty).clamp(0.0, 100.0);
  }

  CourseAttractionFocus get inferredFocus {
    if (ittKilometers >= 50 && gcAttractivenessScore >= 60) {
      return CourseAttractionFocus.timeTrialShowcase;
    }
    if (cobbleSectorsCount >= 6 ||
        classicsAttractivenessScore >
            math.max(gcAttractivenessScore, sprinterAttractivenessScore) + 8) {
      return CourseAttractionFocus.classicsCobblesPunch;
    }
    if (gcAttractivenessScore - sprinterAttractivenessScore >= 14) {
      return CourseAttractionFocus.highMountainGcBattle;
    }
    if (sprinterAttractivenessScore - gcAttractivenessScore >= 14) {
      return CourseAttractionFocus.sprinterFestival;
    }
    return CourseAttractionFocus.balancedTour;
  }

  /// Praktyczne wskazówki dla organizatora jak przyciągnąć więcej liderów lub sprinterów.
  List<String> get designRecommendations {
    final tips = <String>[];
    if (allocatedStages != totalStages) {
      tips.add(
        'Suma etapów ($allocatedStages) różni się od długości wyścigu ($totalStages) — wyrównaj profil.',
      );
    }
    if (gcAttractivenessScore < 65) {
      tips.add(
        'Dodaj metę na szczycie (Summit Finish) lub 20–35 km ITT, aby przyciągnąć liderów GC.',
      );
    }
    if (sprinterAttractivenessScore < 60) {
      tips.add(
        'Zwiększ liczbę płaskich etapów oraz bonifikaty czasowe (10-6-4s) dla topowych sprinterów.',
      );
    }
    if (tvCoverageHoursPerStage < tier.minLiveTvHoursPerStage) {
      tips.add(
        'Wydłuż transmisję TV na żywo do min. ${tier.minLiveTvHoursPerStage.toStringAsFixed(1)}h/etap.',
      );
    }
    if (tips.isEmpty) {
      tips.add(
        'Trasa optymalnie zbalansowana — maksymalna szansa na zniżki Appearance Fees.',
      );
    }
    return tips;
  }

  CourseBlueprintSpec applyPreset(CourseAttractionFocus focus) {
    final stages = math.max(1, totalStages);
    switch (focus) {
      case CourseAttractionFocus.balancedTour:
        final flat = math.max(1, (stages * 0.40).round());
        final mountain = math.max(1, (stages * 0.30).round());
        final hilly = math.max(0, stages - flat - mountain);
        return copyWith(
          flatSprintStages: flat,
          hillyPuncheurStages: hilly,
          mountainFinishStages: mountain,
          ittKilometers: stages >= 7 ? 32.0 : 16.0,
          cobbleSectorsCount: 2,
          summitFinishCount: math.max(1, (mountain * 0.8).round()),
          bonificationSecondsPerStage: 10,
        );
      case CourseAttractionFocus.highMountainGcBattle:
        final mountain = math.max(1, (stages * 0.55).round());
        final flat = math.max(1, (stages * 0.20).round());
        final hilly = math.max(0, stages - flat - mountain);
        return copyWith(
          flatSprintStages: flat,
          hillyPuncheurStages: hilly,
          mountainFinishStages: mountain,
          ittKilometers: stages >= 7 ? 42.0 : 22.0,
          cobbleSectorsCount: 0,
          summitFinishCount: math.max(2, mountain),
          bonificationSecondsPerStage: 10,
        );
      case CourseAttractionFocus.sprinterFestival:
        final flat = math.max(1, (stages * 0.65).round());
        final hilly = math.max(0, (stages * 0.25).round());
        final mountain = math.max(0, stages - flat - hilly);
        return copyWith(
          flatSprintStages: flat,
          hillyPuncheurStages: hilly,
          mountainFinishStages: mountain,
          ittKilometers: 12.0,
          cobbleSectorsCount: 1,
          summitFinishCount: mountain > 0 ? 1 : 0,
          bonificationSecondsPerStage: 12,
        );
      case CourseAttractionFocus.classicsCobblesPunch:
        final hilly = math.max(1, (stages * 0.55).round());
        final flat = math.max(0, (stages * 0.30).round());
        final mountain = math.max(0, stages - hilly - flat);
        return copyWith(
          flatSprintStages: flat,
          hillyPuncheurStages: hilly,
          mountainFinishStages: mountain,
          ittKilometers: 14.0,
          cobbleSectorsCount: 10,
          summitFinishCount: 0,
          bonificationSecondsPerStage: 10,
        );
      case CourseAttractionFocus.timeTrialShowcase:
        final mountain = math.max(1, (stages * 0.35).round());
        final flat = math.max(1, (stages * 0.35).round());
        final hilly = math.max(0, stages - mountain - flat);
        return copyWith(
          flatSprintStages: flat,
          hillyPuncheurStages: hilly,
          mountainFinishStages: mountain,
          ittKilometers: 58.0,
          cobbleSectorsCount: 0,
          summitFinishCount: math.max(1, mountain - 1),
          bonificationSecondsPerStage: 8,
        );
    }
  }

  CourseBlueprintSpec copyWith({
    String? raceId,
    String? raceName,
    UciRaceClassificationTier? tier,
    int? totalStages,
    int? flatSprintStages,
    int? hillyPuncheurStages,
    int? mountainFinishStages,
    double? ittKilometers,
    int? cobbleSectorsCount,
    int? summitFinishCount,
    int? bonificationSecondsPerStage,
    int? prizePoolEur,
    double? tvCoverageHoursPerStage,
  }) {
    return CourseBlueprintSpec(
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      tier: tier ?? this.tier,
      totalStages: totalStages ?? this.totalStages,
      flatSprintStages: flatSprintStages ?? this.flatSprintStages,
      hillyPuncheurStages: hillyPuncheurStages ?? this.hillyPuncheurStages,
      mountainFinishStages: mountainFinishStages ?? this.mountainFinishStages,
      ittKilometers: ittKilometers ?? this.ittKilometers,
      cobbleSectorsCount: cobbleSectorsCount ?? this.cobbleSectorsCount,
      summitFinishCount: summitFinishCount ?? this.summitFinishCount,
      bonificationSecondsPerStage:
          bonificationSecondsPerStage ?? this.bonificationSecondsPerStage,
      prizePoolEur: prizePoolEur ?? this.prizePoolEur,
      tvCoverageHoursPerStage:
          tvCoverageHoursPerStage ?? this.tvCoverageHoursPerStage,
    );
  }

  Map<String, dynamic> toJson() => {
        'raceId': raceId,
        'raceName': raceName,
        'tier': tier.toJson(),
        'totalStages': totalStages,
        'flatSprintStages': flatSprintStages,
        'hillyPuncheurStages': hillyPuncheurStages,
        'mountainFinishStages': mountainFinishStages,
        'ittKilometers': ittKilometers,
        'cobbleSectorsCount': cobbleSectorsCount,
        'summitFinishCount': summitFinishCount,
        'bonificationSecondsPerStage': bonificationSecondsPerStage,
        'prizePoolEur': prizePoolEur,
        'tvCoverageHoursPerStage': tvCoverageHoursPerStage,
      };

  factory CourseBlueprintSpec.fromJson(Map<String, dynamic> json) {
    return CourseBlueprintSpec(
      raceId: json['raceId'] as String? ?? 'race_custom',
      raceName: json['raceName'] as String? ?? 'Wyścig Organizatora',
      tier: UciRaceClassificationTier.fromJson(
        json['tier'] as String? ?? 'uci2Uwt',
      ),
      totalStages: (json['totalStages'] as num?)?.toInt() ?? 7,
      flatSprintStages: (json['flatSprintStages'] as num?)?.toInt() ?? 3,
      hillyPuncheurStages: (json['hillyPuncheurStages'] as num?)?.toInt() ?? 2,
      mountainFinishStages:
          (json['mountainFinishStages'] as num?)?.toInt() ?? 2,
      ittKilometers: (json['ittKilometers'] as num?)?.toDouble() ?? 28.0,
      cobbleSectorsCount: (json['cobbleSectorsCount'] as num?)?.toInt() ?? 2,
      summitFinishCount: (json['summitFinishCount'] as num?)?.toInt() ?? 2,
      bonificationSecondsPerStage:
          (json['bonificationSecondsPerStage'] as num?)?.toInt() ?? 10,
      prizePoolEur: (json['prizePoolEur'] as num?)?.toInt() ?? 450000,
      tvCoverageHoursPerStage:
          (json['tvCoverageHoursPerStage'] as num?)?.toDouble() ?? 4.0,
    );
  }
}

/// Kandydat gwiazdy peletonu do zakontraktowania za opłatą startową.
class StarRiderCandidate {
  final String riderId;
  final String riderName;
  final String nationalityCode;
  final String teamName;
  final StarRiderArchetype archetype;
  final StarPrestigeTier prestigeTier;
  final int overallRating;
  final int baseAppearanceFeeEur;
  final int minimumAcceptableFeeEur;
  final int maxPatience;
  final double tvViewershipBoostIndex;
  final double starPowerContribution;
  final double gcAffinity;
  final double sprinterAffinity;
  final double classicsAffinity;
  final bool calendarConflict;

  const StarRiderCandidate({
    required this.riderId,
    required this.riderName,
    required this.nationalityCode,
    required this.teamName,
    required this.archetype,
    required this.prestigeTier,
    required this.overallRating,
    required this.baseAppearanceFeeEur,
    required this.minimumAcceptableFeeEur,
    required this.maxPatience,
    required this.tvViewershipBoostIndex,
    required this.starPowerContribution,
    required this.gcAffinity,
    required this.sprinterAffinity,
    required this.classicsAffinity,
    this.calendarConflict = false,
  });

  /// Dopasowanie zaprojektowanej trasy do profilu gwiazdy (0..100).
  double calculateCourseFitScore(CourseBlueprintSpec course) {
    final totalWeight =
        math.max(0.01, gcAffinity + sprinterAffinity + classicsAffinity);
    final weighted = ((course.gcAttractivenessScore * gcAffinity) +
            (course.sprinterAttractivenessScore * sprinterAffinity) +
            (course.classicsAttractivenessScore * classicsAffinity)) /
        totalWeight;
    return weighted.clamp(0.0, 100.0);
  }

  /// Dynamiczne żądanie opłaty startowej zależne od dopasowania trasy i rangi wyścigu.
  int calculateDynamicDemandEur(CourseBlueprintSpec course) {
    final fit = calculateCourseFitScore(course);
    double multiplier = 1.0;

    if (fit >= 80.0) {
      multiplier -= 0.16;
    } else if (fit >= 65.0) {
      multiplier -= 0.07;
    } else if (fit < 45.0) {
      multiplier += 0.28;
    } else if (fit < 55.0) {
      multiplier += 0.12;
    }

    if (course.tier == UciRaceClassificationTier.grandTour ||
        course.tier == UciRaceClassificationTier.monument) {
      multiplier -= 0.06;
    } else if (course.tier == UciRaceClassificationTier.uci1_1 ||
        course.tier == UciRaceClassificationTier.uci2_1) {
      multiplier += 0.18;
    }

    if (calendarConflict) {
      multiplier += 0.22;
    }

    final raw = (baseAppearanceFeeEur * multiplier).round();
    return math.max(minimumAcceptableFeeEur, (raw / 1000).round() * 1000);
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'nationalityCode': nationalityCode,
        'teamName': teamName,
        'archetype': archetype.toJson(),
        'prestigeTier': prestigeTier.toJson(),
        'overallRating': overallRating,
        'baseAppearanceFeeEur': baseAppearanceFeeEur,
        'minimumAcceptableFeeEur': minimumAcceptableFeeEur,
        'maxPatience': maxPatience,
        'tvViewershipBoostIndex': tvViewershipBoostIndex,
        'starPowerContribution': starPowerContribution,
        'gcAffinity': gcAffinity,
        'sprinterAffinity': sprinterAffinity,
        'classicsAffinity': classicsAffinity,
        'calendarConflict': calendarConflict,
      };

  factory StarRiderCandidate.fromJson(Map<String, dynamic> json) {
    return StarRiderCandidate(
      riderId: json['riderId'] as String? ?? 'star_unknown',
      riderName: json['riderName'] as String? ?? 'Nieznana Gwiazda',
      nationalityCode: json['nationalityCode'] as String? ?? 'INT',
      teamName: json['teamName'] as String? ?? 'WorldTour Pro',
      archetype: StarRiderArchetype.fromJson(
        json['archetype'] as String? ?? 'gcContender',
      ),
      prestigeTier: StarPrestigeTier.fromJson(
        json['prestigeTier'] as String? ?? 'worldTourStar',
      ),
      overallRating: (json['overallRating'] as num?)?.toInt() ?? 88,
      baseAppearanceFeeEur:
          (json['baseAppearanceFeeEur'] as num?)?.toInt() ?? 120000,
      minimumAcceptableFeeEur:
          (json['minimumAcceptableFeeEur'] as num?)?.toInt() ?? 85000,
      maxPatience: (json['maxPatience'] as num?)?.toInt() ?? 100,
      tvViewershipBoostIndex:
          (json['tvViewershipBoostIndex'] as num?)?.toDouble() ?? 8.5,
      starPowerContribution:
          (json['starPowerContribution'] as num?)?.toDouble() ?? 11.0,
      gcAffinity: (json['gcAffinity'] as num?)?.toDouble() ?? 0.5,
      sprinterAffinity: (json['sprinterAffinity'] as num?)?.toDouble() ?? 0.3,
      classicsAffinity: (json['classicsAffinity'] as num?)?.toDouble() ?? 0.2,
      calendarConflict: json['calendarConflict'] as bool? ?? false,
    );
  }
}

/// Warunki oferty składanej agentowi gwiazdy peletonu.
class AppearanceOfferTerms {
  final int offeredFeeEur;
  final bool includePrivateJetAndVipHospitality;
  final bool includeGuaranteedTvSpotlight;
  final bool includeWildcardTeamInvite;
  final int stageWinBonusEur;

  const AppearanceOfferTerms({
    required this.offeredFeeEur,
    this.includePrivateJetAndVipHospitality = false,
    this.includeGuaranteedTvSpotlight = false,
    this.includeWildcardTeamInvite = false,
    this.stageWinBonusEur = 0,
  });

  /// Koszt natychmiastowych dodatków poza bazową stawką startową.
  int get extrasUpfrontCostEur =>
      (includePrivateJetAndVipHospitality ? 35000 : 0) +
      (includeGuaranteedTvSpotlight ? 15000 : 0);

  /// Łączny koszt gwarantowany z budżetu organizatora.
  int get totalGuaranteedCostEur =>
      math.max(0, offeredFeeEur) + extrasUpfrontCostEur;

  AppearanceOfferTerms copyWith({
    int? offeredFeeEur,
    bool? includePrivateJetAndVipHospitality,
    bool? includeGuaranteedTvSpotlight,
    bool? includeWildcardTeamInvite,
    int? stageWinBonusEur,
  }) {
    return AppearanceOfferTerms(
      offeredFeeEur: offeredFeeEur ?? this.offeredFeeEur,
      includePrivateJetAndVipHospitality:
          includePrivateJetAndVipHospitality ??
              this.includePrivateJetAndVipHospitality,
      includeGuaranteedTvSpotlight:
          includeGuaranteedTvSpotlight ?? this.includeGuaranteedTvSpotlight,
      includeWildcardTeamInvite:
          includeWildcardTeamInvite ?? this.includeWildcardTeamInvite,
      stageWinBonusEur: stageWinBonusEur ?? this.stageWinBonusEur,
    );
  }

  Map<String, dynamic> toJson() => {
        'offeredFeeEur': offeredFeeEur,
        'includePrivateJetAndVipHospitality':
            includePrivateJetAndVipHospitality,
        'includeGuaranteedTvSpotlight': includeGuaranteedTvSpotlight,
        'includeWildcardTeamInvite': includeWildcardTeamInvite,
        'stageWinBonusEur': stageWinBonusEur,
      };

  factory AppearanceOfferTerms.fromJson(Map<String, dynamic> json) {
    return AppearanceOfferTerms(
      offeredFeeEur: (json['offeredFeeEur'] as num?)?.toInt() ?? 0,
      includePrivateJetAndVipHospitality:
          json['includePrivateJetAndVipHospitality'] as bool? ?? false,
      includeGuaranteedTvSpotlight:
          json['includeGuaranteedTvSpotlight'] as bool? ?? false,
      includeWildcardTeamInvite:
          json['includeWildcardTeamInvite'] as bool? ?? false,
      stageWinBonusEur: (json['stageWinBonusEur'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Stan trwającej lub zakończonej sesji negocjacyjnej z gwiazdą.
class AppearanceNegotiationSession {
  final String sessionId;
  final StarRiderCandidate rider;
  final AppearanceNegotiationStatus status;
  final int currentRound;
  final int patienceRemaining;
  final AppearanceOfferTerms? lastOffer;
  final int? counterOfferFeeEur;
  final int? agreedFeeEur;
  final List<String> dialogueLog;
  final double projectedTvLiftPercent;
  final double projectedStarPowerDelta;

  const AppearanceNegotiationSession({
    required this.sessionId,
    required this.rider,
    required this.status,
    required this.currentRound,
    required this.patienceRemaining,
    this.lastOffer,
    this.counterOfferFeeEur,
    this.agreedFeeEur,
    this.dialogueLog = const [],
    this.projectedTvLiftPercent = 0.0,
    this.projectedStarPowerDelta = 0.0,
  });

  AppearanceNegotiationSession copyWith({
    String? sessionId,
    StarRiderCandidate? rider,
    AppearanceNegotiationStatus? status,
    int? currentRound,
    int? patienceRemaining,
    AppearanceOfferTerms? lastOffer,
    int? counterOfferFeeEur,
    int? agreedFeeEur,
    List<String>? dialogueLog,
    double? projectedTvLiftPercent,
    double? projectedStarPowerDelta,
  }) {
    return AppearanceNegotiationSession(
      sessionId: sessionId ?? this.sessionId,
      rider: rider ?? this.rider,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      patienceRemaining: patienceRemaining ?? this.patienceRemaining,
      lastOffer: lastOffer ?? this.lastOffer,
      counterOfferFeeEur: counterOfferFeeEur ?? this.counterOfferFeeEur,
      agreedFeeEur: agreedFeeEur ?? this.agreedFeeEur,
      dialogueLog: dialogueLog ?? this.dialogueLog,
      projectedTvLiftPercent:
          projectedTvLiftPercent ?? this.projectedTvLiftPercent,
      projectedStarPowerDelta:
          projectedStarPowerDelta ?? this.projectedStarPowerDelta,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'rider': rider.toJson(),
        'status': status.toJson(),
        'currentRound': currentRound,
        'patienceRemaining': patienceRemaining,
        'lastOffer': lastOffer?.toJson(),
        'counterOfferFeeEur': counterOfferFeeEur,
        'agreedFeeEur': agreedFeeEur,
        'dialogueLog': dialogueLog,
        'projectedTvLiftPercent': projectedTvLiftPercent,
        'projectedStarPowerDelta': projectedStarPowerDelta,
      };

  factory AppearanceNegotiationSession.fromJson(Map<String, dynamic> json) {
    return AppearanceNegotiationSession(
      sessionId: json['sessionId'] as String? ?? 'neg_session',
      rider: StarRiderCandidate.fromJson(
        (json['rider'] as Map<String, dynamic>?) ?? const {},
      ),
      status: AppearanceNegotiationStatus.fromJson(
        json['status'] as String? ?? 'available',
      ),
      currentRound: (json['currentRound'] as num?)?.toInt() ?? 0,
      patienceRemaining: (json['patienceRemaining'] as num?)?.toInt() ?? 100,
      lastOffer: json['lastOffer'] is Map<String, dynamic>
          ? AppearanceOfferTerms.fromJson(
              json['lastOffer'] as Map<String, dynamic>,
            )
          : null,
      counterOfferFeeEur: (json['counterOfferFeeEur'] as num?)?.toInt(),
      agreedFeeEur: (json['agreedFeeEur'] as num?)?.toInt(),
      dialogueLog: (json['dialogueLog'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      projectedTvLiftPercent:
          (json['projectedTvLiftPercent'] as num?)?.toDouble() ?? 0.0,
      projectedStarPowerDelta:
          (json['projectedStarPowerDelta'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Wynik pojedynczej rundy negocjacji z agentem gwiazdy.
class AppearanceNegotiationOutcome {
  final bool accepted;
  final bool walkedAway;
  final AppearanceNegotiationSession session;
  final String message;
  final int ledgerCostEur;

  const AppearanceNegotiationOutcome({
    required this.accepted,
    required this.walkedAway,
    required this.session,
    required this.message,
    required this.ledgerCostEur,
  });
}

/// Zbiorczy raport wpływu zakontraktowanych gwiazd i projektu trasy na wyścig.
class StarAppearancePortfolioImpact {
  final int signedStarsCount;
  final int totalAppearanceFeesEur;
  final int totalStageBonusExposureEur;
  final double totalStarPowerDelta;
  final double totalViewershipBoostPercent;
  final int projectedExtraTvRevenueEur;
  final double roiMultiplier;
  final ManagedRacePortfolioItem? updatedRace;

  const StarAppearancePortfolioImpact({
    required this.signedStarsCount,
    required this.totalAppearanceFeesEur,
    required this.totalStageBonusExposureEur,
    required this.totalStarPowerDelta,
    required this.totalViewershipBoostPercent,
    required this.projectedExtraTvRevenueEur,
    required this.roiMultiplier,
    this.updatedRace,
  });
}

/// Główny serwis negocjacji opłat startowych (`Appearance Fees`) i projektowania tras
/// przyciągających liderów GC oraz sprinterów w trybie Organizatora Wyścigów.
class StarRiderAppearanceFeeNegotiator {
  const StarRiderAppearanceFeeNegotiator();

  static List<StarRiderCandidate> createDefaultCatalog() {
    return const [
      StarRiderCandidate(
        riderId: 'star_pogacar_archetype',
        riderName: 'Tadej Vranješ',
        nationalityCode: 'SLO',
        teamName: 'UAE Emirates XRG',
        archetype: StarRiderArchetype.allRounderSuperstar,
        prestigeTier: StarPrestigeTier.generationalIcon,
        overallRating: 97,
        baseAppearanceFeeEur: 320000,
        minimumAcceptableFeeEur: 250000,
        maxPatience: 100,
        tvViewershipBoostIndex: 18.5,
        starPowerContribution: 22.0,
        gcAffinity: 0.70,
        sprinterAffinity: 0.10,
        classicsAffinity: 0.65,
      ),
      StarRiderCandidate(
        riderId: 'star_vingegaard_archetype',
        riderName: 'Jonas Lindqvist',
        nationalityCode: 'DEN',
        teamName: 'Visma Lease a Bike',
        archetype: StarRiderArchetype.gcContender,
        prestigeTier: StarPrestigeTier.grandTourWinner,
        overallRating: 95,
        baseAppearanceFeeEur: 270000,
        minimumAcceptableFeeEur: 215000,
        maxPatience: 95,
        tvViewershipBoostIndex: 15.0,
        starPowerContribution: 19.0,
        gcAffinity: 0.92,
        sprinterAffinity: 0.02,
        classicsAffinity: 0.18,
      ),
      StarRiderCandidate(
        riderId: 'star_philipsen_archetype',
        riderName: 'Jasper Verhoeven',
        nationalityCode: 'BEL',
        teamName: 'Alpecin Deceuninck',
        archetype: StarRiderArchetype.pureSprinter,
        prestigeTier: StarPrestigeTier.worldTourStar,
        overallRating: 92,
        baseAppearanceFeeEur: 145000,
        minimumAcceptableFeeEur: 105000,
        maxPatience: 90,
        tvViewershipBoostIndex: 11.2,
        starPowerContribution: 14.0,
        gcAffinity: 0.05,
        sprinterAffinity: 0.90,
        classicsAffinity: 0.35,
      ),
      StarRiderCandidate(
        riderId: 'star_merlier_archetype',
        riderName: 'Tim De Smet',
        nationalityCode: 'BEL',
        teamName: 'Soudal Quick-Step',
        archetype: StarRiderArchetype.pureSprinter,
        prestigeTier: StarPrestigeTier.worldTourStar,
        overallRating: 90,
        baseAppearanceFeeEur: 120000,
        minimumAcceptableFeeEur: 88000,
        maxPatience: 92,
        tvViewershipBoostIndex: 9.4,
        starPowerContribution: 11.5,
        gcAffinity: 0.02,
        sprinterAffinity: 0.95,
        classicsAffinity: 0.22,
      ),
      StarRiderCandidate(
        riderId: 'star_mvdp_archetype',
        riderName: 'Mathieu Van Der Berg',
        nationalityCode: 'NED',
        teamName: 'Alpecin Deceuninck',
        archetype: StarRiderArchetype.classicsSpecialist,
        prestigeTier: StarPrestigeTier.generationalIcon,
        overallRating: 95,
        baseAppearanceFeeEur: 260000,
        minimumAcceptableFeeEur: 205000,
        maxPatience: 88,
        tvViewershipBoostIndex: 16.8,
        starPowerContribution: 20.5,
        gcAffinity: 0.15,
        sprinterAffinity: 0.30,
        classicsAffinity: 0.95,
        calendarConflict: true,
      ),
      StarRiderCandidate(
        riderId: 'star_evenepoel_archetype',
        riderName: 'Remco Janssens',
        nationalityCode: 'BEL',
        teamName: 'Soudal Quick-Step',
        archetype: StarRiderArchetype.timeTrialSpecialist,
        prestigeTier: StarPrestigeTier.grandTourWinner,
        overallRating: 94,
        baseAppearanceFeeEur: 245000,
        minimumAcceptableFeeEur: 190000,
        maxPatience: 85,
        tvViewershipBoostIndex: 14.4,
        starPowerContribution: 18.0,
        gcAffinity: 0.80,
        sprinterAffinity: 0.05,
        classicsAffinity: 0.45,
      ),
      StarRiderCandidate(
        riderId: 'star_kopecky_rising',
        riderName: 'Kacper Wiśniewski',
        nationalityCode: 'POL',
        teamName: 'Bahrain Victorious',
        archetype: StarRiderArchetype.gcContender,
        prestigeTier: StarPrestigeTier.risingPhenom,
        overallRating: 87,
        baseAppearanceFeeEur: 85000,
        minimumAcceptableFeeEur: 60000,
        maxPatience: 100,
        tvViewershipBoostIndex: 7.5,
        starPowerContribution: 9.5,
        gcAffinity: 0.82,
        sprinterAffinity: 0.08,
        classicsAffinity: 0.30,
      ),
      StarRiderCandidate(
        riderId: 'star_milan_sprinter',
        riderName: 'Jonathan Moretti',
        nationalityCode: 'ITA',
        teamName: 'Lidl Trek',
        archetype: StarRiderArchetype.pureSprinter,
        prestigeTier: StarPrestigeTier.risingPhenom,
        overallRating: 89,
        baseAppearanceFeeEur: 105000,
        minimumAcceptableFeeEur: 75000,
        maxPatience: 95,
        tvViewershipBoostIndex: 8.8,
        starPowerContribution: 10.5,
        gcAffinity: 0.04,
        sprinterAffinity: 0.92,
        classicsAffinity: 0.25,
      ),
    ];
  }

  static CourseBlueprintSpec createDefaultCourseBlueprint({
    String raceId = 'race_tour_poland_uwt',
    String raceName = 'Tour de Pologne WorldTour',
    UciRaceClassificationTier tier = UciRaceClassificationTier.uci2Uwt,
    int totalStages = 7,
  }) {
    return CourseBlueprintSpec(
      raceId: raceId,
      raceName: raceName,
      tier: tier,
      totalStages: totalStages,
      flatSprintStages: 3,
      hillyPuncheurStages: 2,
      mountainFinishStages: 2,
      ittKilometers: 24.0,
      cobbleSectorsCount: 2,
      summitFinishCount: 2,
      bonificationSecondsPerStage: 10,
      prizePoolEur: 450000,
      tvCoverageHoursPerStage: 4.0,
    );
  }

  static List<AppearanceNegotiationSession> createInitialSessions(
    List<StarRiderCandidate> catalog,
  ) {
    return catalog
        .map(
          (rider) => AppearanceNegotiationSession(
            sessionId: 'neg_${rider.riderId}',
            rider: rider,
            status: rider.calendarConflict
                ? AppearanceNegotiationStatus.blockedByCalendar
                : AppearanceNegotiationStatus.available,
            currentRound: 0,
            patienceRemaining: rider.maxPatience,
            dialogueLog: [
              rider.calendarConflict
                  ? 'Agent ${rider.riderName}: Kolarz ma kolizję w kalendarzu — potrzebne zaproszenie Wildcard dla drużyny i wyższa stawka.'
                  : 'Agent ${rider.riderName}: Jesteśmy gotowi wysłuchać oferty startowej.',
            ],
          ),
        )
        .toList();
  }

  /// Ocenia pojedynczą ofertę negocjacyjną na podstawie profilu trasy, dodatków VIP i cierpliwości.
  AppearanceNegotiationOutcome evaluateOffer({
    required AppearanceNegotiationSession session,
    required AppearanceOfferTerms offer,
    required CourseBlueprintSpec course,
    required int availableBudgetEur,
  }) {
    final rider = session.rider;
    if (session.status == AppearanceNegotiationStatus.signed) {
      return AppearanceNegotiationOutcome(
        accepted: true,
        walkedAway: false,
        session: session,
        message: '${rider.riderName} ma już podpisany kontrakt startowy.',
        ledgerCostEur: 0,
      );
    }
    if (session.status == AppearanceNegotiationStatus.walkedAway) {
      return AppearanceNegotiationOutcome(
        accepted: false,
        walkedAway: true,
        session: session,
        message: '${rider.riderName} zerwał negocjacje w tej edycji wyścigu.',
        ledgerCostEur: 0,
      );
    }
    if (offer.totalGuaranteedCostEur > availableBudgetEur) {
      return AppearanceNegotiationOutcome(
        accepted: false,
        walkedAway: false,
        session: session,
        message:
            'Niewystarczający budżet organizatora (${offer.totalGuaranteedCostEur} EUR > $availableBudgetEur EUR).',
        ledgerCostEur: 0,
      );
    }

    final dynamicDemand = rider.calculateDynamicDemandEur(course);
    final courseFit = rider.calculateCourseFitScore(course);

    // Dodatki i premie obniżają efektywny próg akceptacji agenta.
    double effectiveOffer = offer.offeredFeeEur.toDouble();
    if (offer.includePrivateJetAndVipHospitality) {
      effectiveOffer += 22000;
    }
    if (offer.includeGuaranteedTvSpotlight) {
      effectiveOffer += dynamicDemand * 0.06;
    }
    if (offer.includeWildcardTeamInvite) {
      effectiveOffer += dynamicDemand * (rider.calendarConflict ? 0.16 : 0.05);
    }
    effectiveOffer += (offer.stageWinBonusEur * 0.45).clamp(0.0, 28000.0);

    final ratio = dynamicDemand <= 0 ? 1.0 : effectiveOffer / dynamicDemand;
    final nextRound = session.currentRound + 1;

    // Natychmiastowa akceptacja przy spełnieniu progu (>= 96% dynamicznego żądania).
    if (ratio >= 0.96) {
      final tvLift = rider.tvViewershipBoostIndex *
          (offer.includeGuaranteedTvSpotlight ? 1.15 : 1.0);
      final starDelta =
          rider.starPowerContribution * (courseFit >= 70 ? 1.10 : 1.0);
      final updated = session.copyWith(
        status: AppearanceNegotiationStatus.signed,
        currentRound: nextRound,
        lastOffer: offer,
        agreedFeeEur: offer.totalGuaranteedCostEur,
        counterOfferFeeEur: null,
        projectedTvLiftPercent: tvLift,
        projectedStarPowerDelta: starDelta,
        dialogueLog: [
          ...session.dialogueLog,
          'Runda $nextRound: Podpisano! Opłata ${offer.totalGuaranteedCostEur} EUR (dopasowanie trasy ${courseFit.toStringAsFixed(0)}%).',
        ],
      );
      return AppearanceNegotiationOutcome(
        accepted: true,
        walkedAway: false,
        session: updated,
        message:
            'Sukces! ${rider.riderName} potwierdził start w ${course.raceName}.',
        ledgerCostEur: offer.totalGuaranteedCostEur,
      );
    }

    // Utrata cierpliwości przy zbyt niskiej ofercie lub kolejnej rundzie.
    final patienceDrop = ratio < 0.72
        ? 45
        : ratio < 0.85
            ? 28
            : 16;
    final bonusPatienceShield =
        offer.includePrivateJetAndVipHospitality ? 8 : 0;
    final int newPatience = math.max<int>(
      0,
      session.patienceRemaining -
          math.max<int>(6, patienceDrop - bonusPatienceShield),
    );

    if (newPatience <= 0 || nextRound >= 4) {
      final updated = session.copyWith(
        status: AppearanceNegotiationStatus.walkedAway,
        currentRound: nextRound,
        patienceRemaining: 0,
        lastOffer: offer,
        dialogueLog: [
          ...session.dialogueLog,
          'Runda $nextRound: Agent odrzucił ${offer.offeredFeeEur} EUR i zerwał rozmowy.',
        ],
      );
      return AppearanceNegotiationOutcome(
        accepted: false,
        walkedAway: true,
        session: updated,
        message:
            '${rider.riderName} wycofał się z rozmów z powodu zbyt niskiej oferty.',
        ledgerCostEur: 0,
      );
    }

    // Wyliczenie kontroferty agenta zbliżającej się do minimum akceptowalnego.
    final concessionFactor = (nextRound * 0.05).clamp(0.05, 0.18);
    final rawCounter = (dynamicDemand * (1.0 - concessionFactor)).round();
    final counter = math.max(
      rider.minimumAcceptableFeeEur,
      (rawCounter / 1000).round() * 1000,
    );

    final updated = session.copyWith(
      status: AppearanceNegotiationStatus.inNegotiation,
      currentRound: nextRound,
      patienceRemaining: newPatience,
      lastOffer: offer,
      counterOfferFeeEur: counter,
      dialogueLog: [
        ...session.dialogueLog,
        'Runda $nextRound: Oferta ${offer.offeredFeeEur} EUR odrzucona. Kontroferta agenta: $counter EUR (dopasowanie trasy ${courseFit.toStringAsFixed(0)}%).',
      ],
    );

    return AppearanceNegotiationOutcome(
      accepted: false,
      walkedAway: false,
      session: updated,
      message:
          'Kontroferta agenta ${rider.riderName}: $counter EUR (cierpliwość $newPatience%).',
      ledgerCostEur: 0,
    );
  }

  /// Oblicza zbiorczy wpływ zakontraktowanych gwiazd i projektu trasy na wyścig oraz budżet.
  StarAppearancePortfolioImpact computePortfolioImpact({
    required List<AppearanceNegotiationSession> sessions,
    required CourseBlueprintSpec course,
    ManagedRacePortfolioItem? raceItem,
  }) {
    final signed = sessions
        .where((s) => s.status == AppearanceNegotiationStatus.signed)
        .toList();

    final totalFees = signed.fold<int>(
      0,
      (sum, s) => sum + (s.agreedFeeEur ?? 0),
    );
    final totalBonuses = signed.fold<int>(
      0,
      (sum, s) => sum + (s.lastOffer?.stageWinBonusEur ?? 0),
    );
    final totalStarDelta = signed.fold<double>(
      0.0,
      (sum, s) => sum + s.projectedStarPowerDelta,
    );
    final totalTvBoost = signed.fold<double>(
      0.0,
      (sum, s) => sum + s.projectedTvLiftPercent,
    );

    final baseTvRevenue = raceItem?.annualTvRightsRevenueEur ?? 1400000;
    final extraTvRevenue =
        (baseTvRevenue * (totalTvBoost / 100.0)).round();
    final roi = totalFees <= 0
        ? (extraTvRevenue > 0 ? 2.0 : 0.0)
        : extraTvRevenue / totalFees;

    final updatedRace = raceItem?.copyWith(
      courseQualityScore: course.overallCourseQualityScore,
      starPowerScore:
          (raceItem.starPowerScore + totalStarDelta).clamp(0.0, 100.0),
      globalViewershipIndex:
          (raceItem.globalViewershipIndex + (totalTvBoost * 0.65))
              .clamp(0.0, 100.0),
    );

    return StarAppearancePortfolioImpact(
      signedStarsCount: signed.length,
      totalAppearanceFeesEur: totalFees,
      totalStageBonusExposureEur: totalBonuses,
      totalStarPowerDelta: totalStarDelta,
      totalViewershipBoostPercent: totalTvBoost,
      projectedExtraTvRevenueEur: extraTvRevenue,
      roiMultiplier: roi,
      updatedRace: updatedRace,
    );
  }

  /// Rejestruje zaakceptowaną opłatę startową w księdze budżetowej organizatora (`#513`).
  OrganizerBudgetLedger recordSignedFeeInLedger({
    required OrganizerBudgetLedger ledger,
    required AppearanceNegotiationSession session,
    required String raceId,
    int seasonYear = 2026,
  }) {
    final fee = session.agreedFeeEur ?? 0;
    if (fee <= 0 || session.status != AppearanceNegotiationStatus.signed) {
      return ledger;
    }
    return ledger.recordTransaction(
      OrganizerLedgerEntry(
        entryId:
            'app_fee_${session.rider.riderId}_r${session.currentRound}',
        description:
            'Opłata startowa (Appearance Fee) — ${session.rider.riderName}',
        category: OrganizerCashflowCategory.appearanceFee,
        amountEur: fee,
        seasonYear: seasonYear,
        relatedRaceId: raceId,
      ),
    );
  }
}

/// Stan Riverpod dla modułu negocjacji gwiazd i projektowania tras.
class StarAppearanceNegotiatorState {
  final CourseBlueprintSpec course;
  final List<AppearanceNegotiationSession> sessions;
  final String selectedRiderId;
  final int availableBudgetEur;
  final String statusBanner;
  final bool isReadOnly;
  final ManagedRacePortfolioItem? activeRaceItem;

  const StarAppearanceNegotiatorState({
    required this.course,
    required this.sessions,
    required this.selectedRiderId,
    required this.availableBudgetEur,
    required this.statusBanner,
    this.isReadOnly = false,
    this.activeRaceItem,
  });

  factory StarAppearanceNegotiatorState.initial({
    int availableBudgetEur = 1250000,
    bool isReadOnly = false,
    ManagedRacePortfolioItem? activeRaceItem,
  }) {
    final catalog = StarRiderAppearanceFeeNegotiator.createDefaultCatalog();
    final sessions =
        StarRiderAppearanceFeeNegotiator.createInitialSessions(catalog);
    final course = StarRiderAppearanceFeeNegotiator.createDefaultCourseBlueprint(
      raceId: activeRaceItem?.raceId ?? 'race_tour_poland_uwt',
      raceName: activeRaceItem?.raceName ?? 'Tour de Pologne WorldTour',
      tier: activeRaceItem?.tier ?? UciRaceClassificationTier.uci2Uwt,
    );
    return StarAppearanceNegotiatorState(
      course: course,
      sessions: sessions,
      selectedRiderId: sessions.first.rider.riderId,
      availableBudgetEur: availableBudgetEur,
      statusBanner:
          'Zaprojektuj profil trasy i wynegocjuj kontrakty startowe z gwiazdami.',
      isReadOnly: isReadOnly,
      activeRaceItem: activeRaceItem,
    );
  }

  AppearanceNegotiationSession get selectedSession {
    return sessions.firstWhere(
      (s) => s.rider.riderId == selectedRiderId,
      orElse: () => sessions.first,
    );
  }

  StarAppearanceNegotiatorState copyWith({
    CourseBlueprintSpec? course,
    List<AppearanceNegotiationSession>? sessions,
    String? selectedRiderId,
    int? availableBudgetEur,
    String? statusBanner,
    bool? isReadOnly,
    ManagedRacePortfolioItem? activeRaceItem,
  }) {
    return StarAppearanceNegotiatorState(
      course: course ?? this.course,
      sessions: sessions ?? this.sessions,
      selectedRiderId: selectedRiderId ?? this.selectedRiderId,
      availableBudgetEur: availableBudgetEur ?? this.availableBudgetEur,
      statusBanner: statusBanner ?? this.statusBanner,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      activeRaceItem: activeRaceItem ?? this.activeRaceItem,
    );
  }

  Map<String, dynamic> toJson() => {
        'course': course.toJson(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'selectedRiderId': selectedRiderId,
        'availableBudgetEur': availableBudgetEur,
        'statusBanner': statusBanner,
        'isReadOnly': isReadOnly,
      };

  factory StarAppearanceNegotiatorState.fromJson(Map<String, dynamic> json) {
    final sessionsList = (json['sessions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AppearanceNegotiationSession.fromJson)
        .toList();
    final fallbackSessions = sessionsList.isEmpty
        ? StarRiderAppearanceFeeNegotiator.createInitialSessions(
            StarRiderAppearanceFeeNegotiator.createDefaultCatalog(),
          )
        : sessionsList;
    return StarAppearanceNegotiatorState(
      course: json['course'] is Map<String, dynamic>
          ? CourseBlueprintSpec.fromJson(json['course'] as Map<String, dynamic>)
          : StarRiderAppearanceFeeNegotiator.createDefaultCourseBlueprint(),
      sessions: fallbackSessions,
      selectedRiderId: json['selectedRiderId'] as String? ??
          fallbackSessions.first.rider.riderId,
      availableBudgetEur:
          (json['availableBudgetEur'] as num?)?.toInt() ?? 1250000,
      statusBanner: json['statusBanner'] as String? ?? '',
      isReadOnly: json['isReadOnly'] as bool? ?? false,
    );
  }
}

/// Kontroler Riverpod zarządzający negocjacjami opłat startowych i projektem trasy.
class StarAppearanceNegotiatorNotifier
    extends StateNotifier<StarAppearanceNegotiatorState> {
  final StarRiderAppearanceFeeNegotiator _service;

  StarAppearanceNegotiatorNotifier({
    StarRiderAppearanceFeeNegotiator service =
        const StarRiderAppearanceFeeNegotiator(),
    StarAppearanceNegotiatorState? initialState,
  })  : _service = service,
        super(initialState ?? StarAppearanceNegotiatorState.initial());

  void selectRider(String riderId) {
    if (state.sessions.any((s) => s.rider.riderId == riderId)) {
      state = state.copyWith(selectedRiderId: riderId);
    }
  }

  void updateCourseBlueprint(
    CourseBlueprintSpec Function(CourseBlueprintSpec current) updater,
  ) {
    if (state.isReadOnly) return;
    final nextCourse = updater(state.course);
    state = state.copyWith(
      course: nextCourse,
      statusBanner:
          'Zaktualizowano trasę: GC ${nextCourse.gcAttractivenessScore.toStringAsFixed(0)}% / Sprinterzy ${nextCourse.sprinterAttractivenessScore.toStringAsFixed(0)}%.',
    );
  }

  void applyCoursePreset(CourseAttractionFocus focus) {
    if (state.isReadOnly) return;
    final nextCourse = state.course.applyPreset(focus);
    state = state.copyWith(
      course: nextCourse,
      statusBanner: 'Zastosowano profil trasy: ${focus.displayNamePl}.',
    );
  }

  AppearanceNegotiationOutcome submitOffer(
    String riderId,
    AppearanceOfferTerms terms,
  ) {
    final target = state.sessions.firstWhere(
      (s) => s.rider.riderId == riderId,
      orElse: () => state.selectedSession,
    );
    if (state.isReadOnly) {
      return AppearanceNegotiationOutcome(
        accepted: false,
        walkedAway: false,
        session: target,
        message: 'Tryb tylko do odczytu — negocjacje są zablokowane.',
        ledgerCostEur: 0,
      );
    }

    final outcome = _service.evaluateOffer(
      session: target,
      offer: terms,
      course: state.course,
      availableBudgetEur: state.availableBudgetEur,
    );

    final updatedSessions = state.sessions
        .map((s) => s.rider.riderId == riderId ? outcome.session : s)
        .toList();

    state = state.copyWith(
      sessions: updatedSessions,
      availableBudgetEur:
          math.max(0, state.availableBudgetEur - outcome.ledgerCostEur),
      statusBanner: outcome.message,
    );

    return outcome;
  }

  void resetNegotiation(String riderId) {
    if (state.isReadOnly) return;
    final updatedSessions = state.sessions.map((s) {
      if (s.rider.riderId != riderId) return s;
      return AppearanceNegotiationSession(
        sessionId: s.sessionId,
        rider: s.rider,
        status: s.rider.calendarConflict
            ? AppearanceNegotiationStatus.blockedByCalendar
            : AppearanceNegotiationStatus.available,
        currentRound: 0,
        patienceRemaining: s.rider.maxPatience,
        dialogueLog: [
          'Wznowiono kontakt z agentem ${s.rider.riderName}.',
        ],
      );
    }).toList();

    state = state.copyWith(
      sessions: updatedSessions,
      statusBanner: 'Zresetowano sesję negocjacyjną.',
    );
  }
}

final starAppearanceNegotiatorProvider = StateNotifierProvider<
    StarAppearanceNegotiatorNotifier, StarAppearanceNegotiatorState>(
  (ref) => StarAppearanceNegotiatorNotifier(),
);

/// Produkcyjny panel UI systemu negocjacji opłat startowych i projektowania tras.
class StarRiderAppearanceFeeNegotiatorPanel extends ConsumerStatefulWidget {
  final bool? isReadOnlyOverride;

  const StarRiderAppearanceFeeNegotiatorPanel({
    super.key,
    this.isReadOnlyOverride,
  });

  @override
  ConsumerState<StarRiderAppearanceFeeNegotiatorPanel> createState() =>
      _StarRiderAppearanceFeeNegotiatorPanelState();
}

class _StarRiderAppearanceFeeNegotiatorPanelState
    extends ConsumerState<StarRiderAppearanceFeeNegotiatorPanel> {
  final StarRiderAppearanceFeeNegotiator _service =
      const StarRiderAppearanceFeeNegotiator();

  double _offerSliderEur = 180000;
  bool _vipJet = false;
  bool _tvSpotlight = true;
  bool _wildcardInvite = false;
  double _stageWinBonusEur = 15000;
  String? _lastSyncedRiderId;
  String? _hoveredRiderId;
  StarRiderArchetype? _archetypeFilter;

  void _syncSliderToRider(
    AppearanceNegotiationSession session,
    CourseBlueprintSpec course,
  ) {
    if (_lastSyncedRiderId == session.rider.riderId) return;
    _lastSyncedRiderId = session.rider.riderId;
    final demand = session.counterOfferFeeEur ??
        session.rider.calculateDynamicDemandEur(course);
    _offerSliderEur = demand.toDouble().clamp(40000.0, 500000.0);
    _wildcardInvite = session.rider.calendarConflict;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(starAppearanceNegotiatorProvider);
    final notifier = ref.read(starAppearanceNegotiatorProvider.notifier);
    final isReadOnly = widget.isReadOnlyOverride ?? state.isReadOnly;
    final selected = state.selectedSession;
    _syncSliderToRider(selected, state.course);

    final impact = _service.computePortfolioImpact(
      sessions: state.sessions,
      course: state.course,
      raceItem: state.activeRaceItem,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textPrimary,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1180;
            final isTablet = width >= 740 && width < 1180;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderBar(state, impact, isReadOnly),
                  const SizedBox(height: 14),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildStarRosterCard(
                            state,
                            notifier,
                            isReadOnly,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 4,
                          child: _buildNegotiationTableCard(
                            state,
                            selected,
                            notifier,
                            isReadOnly,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 4,
                          child: _buildCourseDesignerCard(
                            state,
                            impact,
                            notifier,
                            isReadOnly,
                          ),
                        ),
                      ],
                    )
                  else if (isTablet)
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildStarRosterCard(
                                state,
                                notifier,
                                isReadOnly,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildNegotiationTableCard(
                                state,
                                selected,
                                notifier,
                                isReadOnly,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildCourseDesignerCard(
                          state,
                          impact,
                          notifier,
                          isReadOnly,
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildStarRosterCard(state, notifier, isReadOnly),
                        const SizedBox(height: 14),
                        _buildNegotiationTableCard(
                          state,
                          selected,
                          notifier,
                          isReadOnly,
                        ),
                        const SizedBox(height: 14),
                        _buildCourseDesignerCard(
                          state,
                          impact,
                          notifier,
                          isReadOnly,
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderBar(
    StarAppearanceNegotiatorState state,
    StarAppearancePortfolioImpact impact,
    bool isReadOnly,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: AppColors.goldAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Negocjacje Gwiazd & Projektant Trasy — ${state.course.raceName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                state.statusBanner,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildMetricPill(
                label: 'Budżet Startowy',
                value: _formatEur(state.availableBudgetEur),
                accent: AppColors.statusSuccess,
              ),
              _buildMetricPill(
                label: 'Gwiazdy',
                value: '${impact.signedStarsCount}/${state.sessions.length}',
                accent: AppColors.goldAccent,
              ),
              _buildMetricPill(
                label: 'Wzrost TV',
                value: '+${impact.totalViewershipBoostPercent.toStringAsFixed(1)}%',
                accent: AppColors.accentBlue,
              ),
              if (isReadOnly)
                _buildMetricPill(
                  label: 'Tryb',
                  value: 'Tylko Odczyt',
                  accent: AppColors.amberWarning,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRosterCard(
    StarAppearanceNegotiatorState state,
    StarAppearanceNegotiatorNotifier notifier,
    bool isReadOnly,
  ) {
    final filtered = _archetypeFilter == null
        ? state.sessions
        : state.sessions
            .where((s) => s.rider.archetype == _archetypeFilter)
            .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Gwiazdy Peletonu (Appearance Fees)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildFilterChip(
                label: 'Wszyscy',
                selected: _archetypeFilter == null,
                onTap: () => setState(() => _archetypeFilter = null),
              ),
              ...StarRiderArchetype.values.map(
                (arch) => _buildFilterChip(
                  label: arch.shortTag,
                  selected: _archetypeFilter == arch,
                  onTap: () => setState(() => _archetypeFilter = arch),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...filtered.map((session) {
            final rider = session.rider;
            final isSelected = rider.riderId == state.selectedRiderId;
            final isHovered = _hoveredRiderId == rider.riderId;
            final fit = rider.calculateCourseFitScore(state.course);
            final demand = rider.calculateDynamicDemandEur(state.course);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredRiderId = rider.riderId),
                onExit: (_) => setState(() => _hoveredRiderId = null),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  focusColor: AppColors.goldAccent.withValues(alpha: 0.2),
                  onTap: () => notifier.selectRider(rider.riderId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.surfaceLight
                          : isHovered
                              ? AppColors.surfaceLight.withValues(alpha: 0.65)
                              : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.goldAccent
                            : isHovered
                                ? AppColors.primaryAccent
                                : AppColors.cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.goldAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            '${rider.overallRating}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldAccent,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${rider.riderName} (${rider.nationalityCode})',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${rider.archetype.shortTag} • Fit ${fit.toStringAsFixed(0)}% • Żądanie ${_formatEur(demand)}',
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
                        _buildStatusBadge(session.status),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryAccent : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.goldAccent : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppearanceNegotiationStatus status) {
    final (Color color, String label) = switch (status) {
      AppearanceNegotiationStatus.signed => (
          AppColors.statusSuccess,
          'Podpisano',
        ),
      AppearanceNegotiationStatus.inNegotiation => (
          AppColors.accentBlue,
          'Rozmowy',
        ),
      AppearanceNegotiationStatus.walkedAway => (
          AppColors.crimsonAlert,
          'Zerwano',
        ),
      AppearanceNegotiationStatus.blockedByCalendar => (
          AppColors.amberWarning,
          'Kolizja',
        ),
      AppearanceNegotiationStatus.available => (
          AppColors.textSecondary,
          'Wolny',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNegotiationTableCard(
    StarAppearanceNegotiatorState state,
    AppearanceNegotiationSession selected,
    StarAppearanceNegotiatorNotifier notifier,
    bool isReadOnly,
  ) {
    final rider = selected.rider;
    final dynamicDemand = rider.calculateDynamicDemandEur(state.course);
    final fitScore = rider.calculateCourseFitScore(state.course);
    final isLocked = isReadOnly ||
        selected.status == AppearanceNegotiationStatus.signed ||
        selected.status == AppearanceNegotiationStatus.walkedAway;

    final currentTerms = AppearanceOfferTerms(
      offeredFeeEur: _offerSliderEur.round(),
      includePrivateJetAndVipHospitality: _vipJet,
      includeGuaranteedTvSpotlight: _tvSpotlight,
      includeWildcardTeamInvite: _wildcardInvite,
      stageWinBonusEur: _stageWinBonusEur.round(),
    );

    final canAfford =
        currentTerms.totalGuaranteedCostEur <= state.availableBudgetEur;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${rider.teamName} • ${rider.prestigeTier.displayNamePl}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(selected.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  label: 'Żądanie (z trasą)',
                  value: _formatEur(dynamicDemand),
                  accent: AppColors.goldAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  label: 'Dopasowanie trasy',
                  value: '${fitScore.toStringAsFixed(0)}%',
                  accent: fitScore >= 65
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cierpliwość agenta: ${selected.patienceRemaining}% (Runda ${selected.currentRound}/4)',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (selected.patienceRemaining / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                selected.patienceRemaining >= 60
                    ? AppColors.statusSuccess
                    : selected.patienceRemaining >= 30
                        ? AppColors.amberWarning
                        : AppColors.crimsonAlert,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Proponowane Appearance Fee: ${_formatEur(_offerSliderEur.round())}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Slider(
            value: _offerSliderEur.clamp(40000.0, 500000.0),
            min: 40000,
            max: 500000,
            divisions: 92,
            activeColor: AppColors.goldAccent,
            inactiveColor: AppColors.surfaceLight,
            onChanged: isLocked
                ? null
                : (v) => setState(() => _offerSliderEur = v),
          ),
          Text(
            'Premia za wygrany etap: ${_formatEur(_stageWinBonusEur.round())}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Slider(
            value: _stageWinBonusEur.clamp(0.0, 50000.0),
            min: 0,
            max: 50000,
            divisions: 20,
            activeColor: AppColors.accentBlue,
            inactiveColor: AppColors.surfaceLight,
            onChanged: isLocked
                ? null
                : (v) => setState(() => _stageWinBonusEur = v),
          ),
          _buildClauseSwitch(
            title: 'Prywatny Jet & VIP Hospitality (+35k EUR)',
            value: _vipJet,
            enabled: !isLocked,
            onChanged: (v) => setState(() => _vipJet = v),
          ),
          _buildClauseSwitch(
            title: 'Gwarantowany czas TV (+15k EUR, +15% TV)',
            value: _tvSpotlight,
            enabled: !isLocked,
            onChanged: (v) => setState(() => _tvSpotlight = v),
          ),
          _buildClauseSwitch(
            title: 'Zaproszenie Wildcard dla drużyny',
            value: _wildcardInvite,
            enabled: !isLocked,
            onChanged: (v) => setState(() => _wildcardInvite = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (!isLocked && canAfford)
                      ? () => notifier.submitOffer(rider.riderId, currentTerms)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.textPrimary,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    disabledForegroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.handshake, size: 18),
                  label: Text(
                    'Złóż ofertę (${_formatEur(currentTerms.totalGuaranteedCostEur)})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (selected.status == AppearanceNegotiationStatus.walkedAway &&
                  !isReadOnly) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => notifier.resetNegotiation(rider.riderId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.goldAccent,
                    side: const BorderSide(color: AppColors.goldAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Wznów'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selected.dialogueLog
                  .reversed
                  .take(3)
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $line',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClauseSwitch({
    required String title,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        value: value,
        activeThumbColor: AppColors.goldAccent,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildCourseDesignerCard(
    StarAppearanceNegotiatorState state,
    StarAppearancePortfolioImpact impact,
    StarAppearanceNegotiatorNotifier notifier,
    bool isReadOnly,
  ) {
    final course = state.course;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Projektant Trasy (GC vs Sprinterzy)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CourseAttractionFocus.values.map((focus) {
              final active = course.inferredFocus == focus;
              return _buildFilterChip(
                label: focus.displayNamePl,
                selected: active,
                onTap: isReadOnly
                    ? () {}
                    : () => notifier.applyCoursePreset(focus),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _buildCourseScoreRow(
            'Atrakcyjność dla Liderów GC',
            course.gcAttractivenessScore,
            AppColors.goldAccent,
          ),
          const SizedBox(height: 8),
          _buildCourseScoreRow(
            'Atrakcyjność dla Sprinterów',
            course.sprinterAttractivenessScore,
            AppColors.statusSuccess,
          ),
          const SizedBox(height: 8),
          _buildCourseScoreRow(
            'Atrakcyjność dla Klasykowców',
            course.classicsAttractivenessScore,
            AppColors.accentBlue,
          ),
          const SizedBox(height: 14),
          _buildStageStepper(
            label: 'Etapy płaskie (Sprinterskie)',
            value: course.flatSprintStages,
            enabled: !isReadOnly,
            onDecrement: course.flatSprintStages > 0
                ? () => notifier.updateCourseBlueprint(
                      (c) => c.copyWith(
                        flatSprintStages: c.flatSprintStages - 1,
                      ),
                    )
                : null,
            onIncrement: () => notifier.updateCourseBlueprint(
              (c) => c.copyWith(flatSprintStages: c.flatSprintStages + 1),
            ),
          ),
          _buildStageStepper(
            label: 'Etapy górskie (GC)',
            value: course.mountainFinishStages,
            enabled: !isReadOnly,
            onDecrement: course.mountainFinishStages > 0
                ? () => notifier.updateCourseBlueprint(
                      (c) => c.copyWith(
                        mountainFinishStages: c.mountainFinishStages - 1,
                      ),
                    )
                : null,
            onIncrement: () => notifier.updateCourseBlueprint(
              (c) => c.copyWith(
                mountainFinishStages: c.mountainFinishStages + 1,
              ),
            ),
          ),
          _buildStageStepper(
            label: 'Mety na szczycie (Summit Finish)',
            value: course.summitFinishCount,
            enabled: !isReadOnly,
            onDecrement: course.summitFinishCount > 0
                ? () => notifier.updateCourseBlueprint(
                      (c) => c.copyWith(
                        summitFinishCount: c.summitFinishCount - 1,
                      ),
                    )
                : null,
            onIncrement: () => notifier.updateCourseBlueprint(
              (c) => c.copyWith(summitFinishCount: c.summitFinishCount + 1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dystans Jazdy na Czas (ITT): ${course.ittKilometers.toStringAsFixed(0)} km',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Slider(
            value: course.ittKilometers.clamp(0.0, 80.0),
            min: 0,
            max: 80,
            divisions: 16,
            activeColor: AppColors.goldAccent,
            inactiveColor: AppColors.surfaceLight,
            onChanged: isReadOnly
                ? null
                : (v) => notifier.updateCourseBlueprint(
                      (c) => c.copyWith(ittKilometers: v),
                    ),
          ),
          const SizedBox(height: 8),
          Container(
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
                  'Zwrot z Gwiazd (ROI): ${impact.roiMultiplier.toStringAsFixed(2)}x • Extra TV: ${_formatEur(impact.projectedExtraTvRevenueEur)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                ...course.designRecommendations.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '• $tip',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildCourseScoreRow(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${score.toStringAsFixed(0)}/100',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100.0).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildStageStepper({
    required String label,
    required int value,
    required bool enabled,
    required VoidCallback? onDecrement,
    required VoidCallback? onIncrement,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: enabled ? onDecrement : null,
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            color: AppColors.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            onPressed: enabled ? onIncrement : null,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            color: AppColors.goldAccent,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _formatEur(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M €';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k €';
    }
    return '$amount €';
  }
}
