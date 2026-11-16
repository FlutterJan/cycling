import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/physics/aero_calculator.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import '../../models/team/cycling_team.dart';
import '../widgets/rider_avatar_painter.dart';

/// Archetypy genetyczne kolarza w trybie "Zostań Legendą" (Be a Pro).
enum BeAProGeneticArchetype {
  alpineClimber,
  northernClassics,
  explosivePuncheur,
  sprinter,
  ittAllRounder;

  String get label {
    switch (this) {
      case BeAProGeneticArchetype.alpineClimber:
        return 'Alpejski Góral';
      case BeAProGeneticArchetype.northernClassics:
        return 'Klasykowiec Północy';
      case BeAProGeneticArchetype.explosivePuncheur:
        return 'Wybuchowy Puncheur';
      case BeAProGeneticArchetype.sprinter:
        return 'Sprinter';
      case BeAProGeneticArchetype.ittAllRounder:
        return 'Specjalista ITT / All-Rounder';
    }
  }

  String get shortCode {
    switch (this) {
      case BeAProGeneticArchetype.alpineClimber:
        return 'CLM';
      case BeAProGeneticArchetype.northernClassics:
        return 'COB';
      case BeAProGeneticArchetype.explosivePuncheur:
        return 'PUN';
      case BeAProGeneticArchetype.sprinter:
        return 'SPR';
      case BeAProGeneticArchetype.ittAllRounder:
        return 'ITT';
    }
  }

  String get description {
    switch (this) {
      case BeAProGeneticArchetype.alpineClimber:
        return 'Niska masa, wysokie VO2max i dominacja na długich przełęczach HC powyżej 2000 m n.p.m.';
      case BeAProGeneticArchetype.northernClassics:
        return 'Wytrzymałość na bruku, jazda w rantach przy bocznym wietrze i odporność na trudne warunki.';
      case BeAProGeneticArchetype.explosivePuncheur:
        return 'Ogromna moc 1–5 min na ściankach 12–18% oraz szybka regeneracja po atakach.';
      case BeAProGeneticArchetype.sprinter:
        return 'Maksymalna moc nerwowo-mięśniowa (5s > 1300 W) i dynamika w pociągu sprinterskim.';
      case BeAProGeneticArchetype.ittAllRounder:
        return 'Aerodynamiczna sylwetka, stabilny próg mleczanowy i wszechstronność w wyścigach etapowych.';
    }
  }

  Color get accentColor {
    switch (this) {
      case BeAProGeneticArchetype.alpineClimber:
        return AppColors.crimsonAlert;
      case BeAProGeneticArchetype.northernClassics:
        return AppColors.amberWarning;
      case BeAProGeneticArchetype.explosivePuncheur:
        return AppColors.goldAccent;
      case BeAProGeneticArchetype.sprinter:
        return AppColors.statusSuccess;
      case BeAProGeneticArchetype.ittAllRounder:
        return AppColors.accentBlue;
    }
  }

  RiderSpecialization get riderSpecialization {
    switch (this) {
      case BeAProGeneticArchetype.alpineClimber:
        return RiderSpecialization.pureClimber;
      case BeAProGeneticArchetype.northernClassics:
        return RiderSpecialization.classicCobbles;
      case BeAProGeneticArchetype.explosivePuncheur:
        return RiderSpecialization.puncher;
      case BeAProGeneticArchetype.sprinter:
        return RiderSpecialization.pureSprinter;
      case BeAProGeneticArchetype.ittAllRounder:
        return RiderSpecialization.timeTrialist;
    }
  }

  BodyBuildType get defaultBodyBuild {
    switch (this) {
      case BeAProGeneticArchetype.alpineClimber:
        return BodyBuildType.climberLean;
      case BeAProGeneticArchetype.northernClassics:
      case BeAProGeneticArchetype.explosivePuncheur:
      case BeAProGeneticArchetype.ittAllRounder:
        return BodyBuildType.allRounder;
      case BeAProGeneticArchetype.sprinter:
        return BodyBuildType.sprinterMuscular;
    }
  }

  String get idealHeightRangeLabel {
    switch (this) {
      case BeAProGeneticArchetype.alpineClimber:
        return '164–178 cm';
      case BeAProGeneticArchetype.northernClassics:
        return '178–190 cm';
      case BeAProGeneticArchetype.explosivePuncheur:
        return '170–182 cm';
      case BeAProGeneticArchetype.sprinter:
        return '175–188 cm';
      case BeAProGeneticArchetype.ittAllRounder:
        return '176–188 cm';
    }
  }

  String get idealWeightRangeLabel {
    switch (this) {
      case BeAProGeneticArchetype.alpineClimber:
        return '54–63 kg';
      case BeAProGeneticArchetype.northernClassics:
        return '70–80 kg';
      case BeAProGeneticArchetype.explosivePuncheur:
        return '62–71 kg';
      case BeAProGeneticArchetype.sprinter:
        return '72–84 kg';
      case BeAProGeneticArchetype.ittAllRounder:
        return '65–75 kg';
    }
  }
}

/// Zakładki kreatora kolarza.
enum BeAProCreatorStep {
  identityAndPhysique,
  geneticArchetype,
  appearance3d,
  u23Team;

  String get title {
    switch (this) {
      case BeAProCreatorStep.identityAndPhysique:
        return 'Tożsamość i Ciało';
      case BeAProCreatorStep.geneticArchetype:
        return 'Archetyp';
      case BeAProCreatorStep.appearance3d:
        return 'Wygląd 3D';
      case BeAProCreatorStep.u23Team:
        return 'Drużyna U23';
    }
  }

  IconData get icon {
    switch (this) {
      case BeAProCreatorStep.identityAndPhysique:
        return Icons.badge_outlined;
      case BeAProCreatorStep.geneticArchetype:
        return Icons.bolt_outlined;
      case BeAProCreatorStep.appearance3d:
        return Icons.palette_outlined;
      case BeAProCreatorStep.u23Team:
        return Icons.groups_outlined;
    }
  }
}

/// Opcja narodowości w kreatorze.
class BeAProNationalityOption {
  final String iso;
  final String countryName;
  final Color primaryFlagColor;
  final Color secondaryFlagColor;
  final Color tertiaryFlagColor;
  final bool isHorizontal;

  const BeAProNationalityOption({
    required this.iso,
    required this.countryName,
    required this.primaryFlagColor,
    required this.secondaryFlagColor,
    this.tertiaryFlagColor = Colors.transparent,
    this.isHorizontal = true,
  });
}

/// Oferta startowej drużyny U23 / Continental.
class BeAProU23TeamOffer {
  final String id;
  final String name;
  final String countryIso;
  final String regionLabel;
  final String specialtyFocus;
  final String bikeBrand;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String accentColorHex;
  final int monthlySalaryEur;
  final double initialDsTrust;
  final int prestigeStars;

  const BeAProU23TeamOffer({
    required this.id,
    required this.name,
    required this.countryIso,
    required this.regionLabel,
    required this.specialtyFocus,
    required this.bikeBrand,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.accentColorHex,
    required this.monthlySalaryEur,
    required this.initialDsTrust,
    required this.prestigeStars,
  });

  Color get primaryColor => _parseHex(primaryColorHex, AppColors.primaryAccent);
  Color get secondaryColor => _parseHex(secondaryColorHex, AppColors.surfaceLight);
  Color get accentColor => _parseHex(accentColorHex, AppColors.goldAccent);
}

/// Wyliczone parametry fizyczne i aerodynamiczne na podstawie wzrostu, wagi i archetypu.
class BeAProPhysiqueMetrics {
  final double heightCm;
  final double weightKg;
  final double bmi;
  final double bodySurfaceAreaM2;
  final double frontalAreaM2;
  final double baseCdaHoodsM2;
  final double baseCdaDropsM2;
  final double baseCdaTtM2;
  final int estimatedFtpWatts;
  final double wattsPerKg;
  final double vo2Max;
  final int wPrimeJoules;
  final int sprint5sWatts;
  final int mountainPredisposition; // 0-100
  final int flatPredisposition; // 0-100
  final int cobblesPredisposition; // 0-100
  final int ttPredisposition; // 0-100
  final int sprintPredisposition; // 0-100

  const BeAProPhysiqueMetrics({
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.bodySurfaceAreaM2,
    required this.frontalAreaM2,
    required this.baseCdaHoodsM2,
    required this.baseCdaDropsM2,
    required this.baseCdaTtM2,
    required this.estimatedFtpWatts,
    required this.wattsPerKg,
    required this.vo2Max,
    required this.wPrimeJoules,
    required this.sprint5sWatts,
    required this.mountainPredisposition,
    required this.flatPredisposition,
    required this.cobblesPredisposition,
    required this.ttPredisposition,
    required this.sprintPredisposition,
  });

  /// Bilans Gór vs Płaskie w zakresie -1.0 (czysty góral) .. +1.0 (czyste płaskie/sprint).
  double get terrainBalanceRatio {
    final diff = flatPredisposition - mountainPredisposition;
    return (diff / 50.0).clamp(-1.0, 1.0);
  }
}

/// Kalkulator fizyki i fizjologii startowej 18-letniego kolarza Neo-Pro U23.
class BeAProPhysicsCalculator {
  BeAProPhysicsCalculator._();

  static const double minHeightCm = 160.0;
  static const double maxHeightCm = 198.0;
  static const double minWeightKg = 52.0;
  static const double maxWeightKg = 86.0;

  static BeAProPhysiqueMetrics evaluate({
    required double heightCm,
    required double weightKg,
    required BeAProGeneticArchetype archetype,
  }) {
    final h = heightCm.clamp(minHeightCm, maxHeightCm);
    final w = weightKg.clamp(minWeightKg, maxWeightKg);
    final hMeters = h / 100.0;
    final bmi = w / (hMeters * hMeters);

    // Wzór DuBois na powierzchnię ciała BSA [m^2]
    final bsa = 0.007184 * math.pow(w, 0.425) * math.pow(h, 0.725);
    final frontalArea = bsa * 0.268;
    final aeroScale = frontalArea / AeroCalculator.referenceFrontalAreaM2;

    final archetypeAeroFactor = switch (archetype) {
      BeAProGeneticArchetype.ittAllRounder => 0.94,
      BeAProGeneticArchetype.alpineClimber => 0.98,
      BeAProGeneticArchetype.explosivePuncheur => 0.99,
      BeAProGeneticArchetype.northernClassics => 1.01,
      BeAProGeneticArchetype.sprinter => 1.03,
    };

    final cdaHoods = PhysicsConstants.cdaHoods * aeroScale * archetypeAeroFactor;
    final cdaDrops = PhysicsConstants.cdaDrops * aeroScale * archetypeAeroFactor;
    final cdaTt = PhysicsConstants.cdaTimeTrial * aeroScale * archetypeAeroFactor;

    // Startowe FTP 18-letniego talentu U23 skalowane allometrycznie (masa^0.68)
    final massScaling = math.pow(w / 68.0, 0.68).toDouble();
    final archetypeBaseFtp = switch (archetype) {
      BeAProGeneticArchetype.alpineClimber => 342.0,
      BeAProGeneticArchetype.northernClassics => 358.0,
      BeAProGeneticArchetype.explosivePuncheur => 346.0,
      BeAProGeneticArchetype.sprinter => 334.0,
      BeAProGeneticArchetype.ittAllRounder => 364.0,
    };

    // Lekka kara za ekstremalne BMI poza pasmem kolarskim (18.5..24.0)
    final bmiPenalty = bmi < 18.0
        ? (18.0 - bmi) * 3.5
        : (bmi > 24.5 ? (bmi - 24.5) * 2.5 : 0.0);

    final estimatedFtp = (archetypeBaseFtp * massScaling - bmiPenalty)
        .round()
        .clamp(250, 420);
    final wPerKg = estimatedFtp / w;

    final baseVo2 = switch (archetype) {
      BeAProGeneticArchetype.alpineClimber => 81.5,
      BeAProGeneticArchetype.explosivePuncheur => 78.5,
      BeAProGeneticArchetype.ittAllRounder => 77.5,
      BeAProGeneticArchetype.northernClassics => 75.5,
      BeAProGeneticArchetype.sprinter => 71.0,
    };
    final vo2 = (baseVo2 - (w - 65.0) * 0.14).clamp(64.0, 86.0);

    final wPrime = switch (archetype) {
      BeAProGeneticArchetype.sprinter => 26500 + ((w - 70) * 180).round(),
      BeAProGeneticArchetype.explosivePuncheur => 24000 + ((w - 66) * 140).round(),
      BeAProGeneticArchetype.northernClassics => 22500 + ((w - 72) * 130).round(),
      BeAProGeneticArchetype.ittAllRounder => 20500 + ((w - 68) * 110).round(),
      BeAProGeneticArchetype.alpineClimber => 18500 + ((w - 60) * 90).round(),
    }.clamp(15000, 32000);

    final sprint5sBase = switch (archetype) {
      BeAProGeneticArchetype.sprinter => 1380.0,
      BeAProGeneticArchetype.explosivePuncheur => 1160.0,
      BeAProGeneticArchetype.northernClassics => 1140.0,
      BeAProGeneticArchetype.ittAllRounder => 1020.0,
      BeAProGeneticArchetype.alpineClimber => 910.0,
    };
    final sprint5s = (sprint5sBase * (0.75 + 0.25 * (w / 72.0)))
        .round()
        .clamp(780, 1620);

    // Predyspozycje terenowe (0..100) wynikające fizycznie z W/kg i CdA
    final mountainScore =
        (46 + (wPerKg - 4.4) * 26 + (archetype == BeAProGeneticArchetype.alpineClimber ? 12 : 0) + (archetype == BeAProGeneticArchetype.explosivePuncheur ? 6 : 0))
            .round()
            .clamp(38, 88);

    final flatSpeedIndex = (estimatedFtp / cdaHoods) / 1000.0; // W/m^2
    final flatScore =
        (42 + (flatSpeedIndex - 0.90) * 85 + (archetype == BeAProGeneticArchetype.northernClassics ? 10 : 0) + (archetype == BeAProGeneticArchetype.ittAllRounder ? 8 : 0))
            .round()
            .clamp(40, 88);

    final cobblesScore =
        (44 + (w - 64.0) * 0.65 + (archetype == BeAProGeneticArchetype.northernClassics ? 20 : 0) + (archetype == BeAProGeneticArchetype.explosivePuncheur ? 6 : 0))
            .round()
            .clamp(35, 88);

    final ttScore =
        (44 + ((estimatedFtp / cdaTt) / 1400.0 - 0.95) * 65 + (archetype == BeAProGeneticArchetype.ittAllRounder ? 16 : 0))
            .round()
            .clamp(38, 88);

    final sprintScore =
        (40 + (sprint5s - 900) / 14.0 + (archetype == BeAProGeneticArchetype.sprinter ? 14 : 0))
            .round()
            .clamp(35, 88);

    return BeAProPhysiqueMetrics(
      heightCm: h,
      weightKg: w,
      bmi: bmi,
      bodySurfaceAreaM2: bsa,
      frontalAreaM2: frontalArea,
      baseCdaHoodsM2: cdaHoods,
      baseCdaDropsM2: cdaDrops,
      baseCdaTtM2: cdaTt,
      estimatedFtpWatts: estimatedFtp,
      wattsPerKg: wPerKg,
      vo2Max: vo2,
      wPrimeJoules: wPrime,
      sprint5sWatts: sprint5s,
      mountainPredisposition: mountainScore,
      flatPredisposition: flatScore,
      cobblesPredisposition: cobblesScore,
      ttPredisposition: ttScore,
      sprintPredisposition: sprintScore,
    );
  }
}

/// Pełny roboczy stan kreatora kolarza Be a Pro.
class BeAProCharacterDraft {
  final String firstName;
  final String lastName;
  final String nationalityIso;
  final double heightCm;
  final double weightKg;
  final BeAProGeneticArchetype archetype;
  final int faceShapeIndex;
  final String skinToneHex;
  final int hairStyleIndex;
  final String hairColorHex;
  final int facialHairIndex;
  final String glassesModelId;
  final String glassesLensColorHex;
  final String helmetModelId;
  final String shoeColorHex;
  final double sockHeightProportion;
  final String selectedTeamId;

  const BeAProCharacterDraft({
    this.firstName = 'Kacper',
    this.lastName = 'Kowalski',
    this.nationalityIso = 'POL',
    this.heightCm = 176.0,
    this.weightKg = 64.0,
    this.archetype = BeAProGeneticArchetype.explosivePuncheur,
    this.faceShapeIndex = 0,
    this.skinToneHex = '#E8BA9B',
    this.hairStyleIndex = 1,
    this.hairColorHex = '#2C1B18',
    this.facialHairIndex = 0,
    this.glassesModelId = 'aero_visor',
    this.glassesLensColorHex = '#D4AF37',
    this.helmetModelId = 'aero_pro_v2',
    this.shoeColorHex = '#F3F4F6',
    this.sockHeightProportion = 0.65,
    this.selectedTeamId = 'u23_veloce_krakow',
  });

  BeAProCharacterDraft copyWith({
    String? firstName,
    String? lastName,
    String? nationalityIso,
    double? heightCm,
    double? weightKg,
    BeAProGeneticArchetype? archetype,
    int? faceShapeIndex,
    String? skinToneHex,
    int? hairStyleIndex,
    String? hairColorHex,
    int? facialHairIndex,
    String? glassesModelId,
    String? glassesLensColorHex,
    String? helmetModelId,
    String? shoeColorHex,
    double? sockHeightProportion,
    String? selectedTeamId,
  }) {
    return BeAProCharacterDraft(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      archetype: archetype ?? this.archetype,
      faceShapeIndex: faceShapeIndex ?? this.faceShapeIndex,
      skinToneHex: skinToneHex ?? this.skinToneHex,
      hairStyleIndex: hairStyleIndex ?? this.hairStyleIndex,
      hairColorHex: hairColorHex ?? this.hairColorHex,
      facialHairIndex: facialHairIndex ?? this.facialHairIndex,
      glassesModelId: glassesModelId ?? this.glassesModelId,
      glassesLensColorHex: glassesLensColorHex ?? this.glassesLensColorHex,
      helmetModelId: helmetModelId ?? this.helmetModelId,
      shoeColorHex: shoeColorHex ?? this.shoeColorHex,
      sockHeightProportion: sockHeightProportion ?? this.sockHeightProportion,
      selectedTeamId: selectedTeamId ?? this.selectedTeamId,
    );
  }

  BodyBuildType get resolvedBodyBuild {
    if (weightKg <= 61.5) return BodyBuildType.climberLean;
    if (weightKg >= 75.5 || archetype == BeAProGeneticArchetype.sprinter) {
      return BodyBuildType.sprinterMuscular;
    }
    return archetype.defaultBodyBuild;
  }

  RiderAppearance toAppearance() {
    return RiderAppearance(
      faceShapeIndex: faceShapeIndex,
      skinToneHex: skinToneHex,
      hairStyleIndex: hairStyleIndex,
      hairColorHex: hairColorHex,
      facialHairIndex: facialHairIndex,
      glassesModelId: glassesModelId,
      glassesLensColorHex: glassesLensColorHex,
      helmetModelId: helmetModelId,
      shoeColorHex: shoeColorHex,
      sockHeightProportion: sockHeightProportion,
      bodyBuildType: resolvedBodyBuild,
    );
  }

  BeAProPhysiqueMetrics computeMetrics() {
    return BeAProPhysicsCalculator.evaluate(
      heightCm: heightCm,
      weightKg: weightKg,
      archetype: archetype,
    );
  }

  BeAProU23TeamOffer resolveTeamOffer() {
    return BeAProCatalog.u23Teams.firstWhere(
      (t) => t.id == selectedTeamId,
      orElse: () => BeAProCatalog.u23Teams.first,
    );
  }

  bool get isValidIdentity =>
      firstName.trim().length >= 2 && lastName.trim().length >= 2;

  /// Buduje gotowy obiekt [Rider] oraz [ProCyclistCareerState] do startu kariery.
  BeAProCreatorResult buildCareerResult({DateTime? startDate}) {
    final now = startDate ?? DateTime(2026, 1, 15);
    final team = resolveTeamOffer();
    final metrics = computeMetrics();
    final cleanFirst = firstName.trim().isEmpty ? 'Kacper' : firstName.trim();
    final cleanLast = lastName.trim().isEmpty ? 'Kowalski' : lastName.trim();

    final physiology = RiderPhysiology(
      heightCm: heightCm,
      weightKg: weightKg,
      bodyFatPercentage: (7.2 + (weightKg - 58.0) * 0.08).clamp(5.8, 12.5),
      ftpWatts: metrics.estimatedFtpWatts,
      wPrimeJoules: metrics.wPrimeJoules,
      vo2Max: metrics.vo2Max,
      maxHr: 198,
      restingHr: 42,
      lactateThresholdHr: 178,
      recoveryRate: 74.0,
      glycogenCapacityGrams: 520.0,
      form: 68.0,
      fatigue: 18.0,
    );

    final ftp = metrics.estimatedFtpWatts;
    final s5 = metrics.sprint5sWatts;
    final powerProfile = RiderPowerProfile(
      watts5s: s5,
      watts15s: (s5 * 0.86).round(),
      watts30s: (s5 * 0.72).round(),
      watts1m: (ftp * 1.62 + (metrics.wPrimeJoules / 140.0)).round(),
      watts3m: (ftp * 1.28).round(),
      watts5m: (ftp * 1.18).round(),
      watts20m: (ftp * 1.05).round(),
      watts60m: ftp,
    );

    final skills = RiderSkills(
      cobbles: metrics.cobblesPredisposition,
      descending: archetype == BeAProGeneticArchetype.explosivePuncheur ? 72 : 66,
      bikeHandling: archetype == BeAProGeneticArchetype.sprinter ? 74 : 68,
      aeroPositioning: metrics.ttPredisposition,
      draftingEfficiency: 68,
      raceIq: 64,
      rainResistance: archetype == BeAProGeneticArchetype.northernClassics ? 76 : 62,
      heatTolerance: 65,
      timeTrialPositioning: metrics.ttPredisposition,
    );

    final rider = Rider(
      id: 'be_a_pro_${cleanFirst.toLowerCase()}_${cleanLast.toLowerCase()}',
      firstName: cleanFirst,
      lastName: cleanLast,
      nationalityIso: nationalityIso,
      birthDate: DateTime(now.year - 18, 4, 12),
      potential: 92,
      specialization: archetype.riderSpecialization,
      physiology: physiology,
      powerProfile: powerProfile,
      skills: skills,
      appearance: toAppearance(),
      contract: RiderContract(
        teamId: team.id,
        role: RiderRole.neoPro,
        monthlySalaryEur: team.monthlySalaryEur,
        signingBonusEur: 1500,
        winBonusEur: 500,
        releaseClauseEur: 120000,
        contractEndYear: now.year + 1,
        morale: 0.85,
        leaderLoyalty: 0.80,
        requiredRacesIds: const ['tour_de_lavenir', 'giro_next_gen'],
      ),
      health: const RiderHealth(
        acuteTrainingLoad: 18.0,
        chronicTrainingLoad: 68.0,
      ),
      careerPointsUci: 0,
    );

    final careerState = ProCyclistCareerState.createNew(
      careerId: 'pro_cyclist_${now.millisecondsSinceEpoch}',
      careerName: '$cleanFirst $cleanLast — Droga do WorldTouru',
      playerRider: rider,
      startDate: now,
      currentTeamId: team.id,
      currentTeamName: team.name,
      currentDivision: TeamDivision.continental,
      initialDsTrustScore: team.initialDsTrust,
      initialSkillPoints: 6,
      initialPrivateBalanceEur: 2500,
    );

    return BeAProCreatorResult(
      playerRider: rider,
      careerState: careerState,
      selectedTeam: team,
      physiqueMetrics: metrics,
    );
  }
}

/// Wynik utworzenia kolarza i nowej kariery Be a Pro.
class BeAProCreatorResult {
  final Rider playerRider;
  final ProCyclistCareerState careerState;
  final BeAProU23TeamOffer selectedTeam;
  final BeAProPhysiqueMetrics physiqueMetrics;

  const BeAProCreatorResult({
    required this.playerRider,
    required this.careerState,
    required this.selectedTeam,
    required this.physiqueMetrics,
  });
}

/// Katalog opcji personalizacji i drużyn startowych U23/Continental.
class BeAProCatalog {
  BeAProCatalog._();

  static const List<BeAProNationalityOption> nationalities = [
    BeAProNationalityOption(
      iso: 'POL',
      countryName: 'Polska',
      primaryFlagColor: Color(0xFFFFFFFF),
      secondaryFlagColor: Color(0xFFDC143C),
    ),
    BeAProNationalityOption(
      iso: 'BEL',
      countryName: 'Belgia',
      primaryFlagColor: Color(0xFF111827),
      secondaryFlagColor: Color(0xFFFACC15),
      tertiaryFlagColor: Color(0xFFEF4444),
      isHorizontal: false,
    ),
    BeAProNationalityOption(
      iso: 'FRA',
      countryName: 'Francja',
      primaryFlagColor: Color(0xFF1D4ED8),
      secondaryFlagColor: Color(0xFFFFFFFF),
      tertiaryFlagColor: Color(0xFFEF4444),
      isHorizontal: false,
    ),
    BeAProNationalityOption(
      iso: 'ITA',
      countryName: 'Włochy',
      primaryFlagColor: Color(0xFF10B981),
      secondaryFlagColor: Color(0xFFFFFFFF),
      tertiaryFlagColor: Color(0xFFEF4444),
      isHorizontal: false,
    ),
    BeAProNationalityOption(
      iso: 'ESP',
      countryName: 'Hiszpania',
      primaryFlagColor: Color(0xFFDC2626),
      secondaryFlagColor: Color(0xFFFACC15),
      tertiaryFlagColor: Color(0xFFDC2626),
    ),
    BeAProNationalityOption(
      iso: 'NED',
      countryName: 'Holandia',
      primaryFlagColor: Color(0xFFDC2626),
      secondaryFlagColor: Color(0xFFFFFFFF),
      tertiaryFlagColor: Color(0xFF1D4ED8),
    ),
    BeAProNationalityOption(
      iso: 'SLO',
      countryName: 'Słowenia',
      primaryFlagColor: Color(0xFFFFFFFF),
      secondaryFlagColor: Color(0xFF2563EB),
      tertiaryFlagColor: Color(0xFFDC2626),
    ),
    BeAProNationalityOption(
      iso: 'DEN',
      countryName: 'Dania',
      primaryFlagColor: Color(0xFFDC2626),
      secondaryFlagColor: Color(0xFFFFFFFF),
    ),
    BeAProNationalityOption(
      iso: 'GBR',
      countryName: 'Wlk. Brytania',
      primaryFlagColor: Color(0xFF1E3A8A),
      secondaryFlagColor: Color(0xFFDC2626),
      tertiaryFlagColor: Color(0xFFFFFFFF),
    ),
    BeAProNationalityOption(
      iso: 'COL',
      countryName: 'Kolumbia',
      primaryFlagColor: Color(0xFFFACC15),
      secondaryFlagColor: Color(0xFF1D4ED8),
      tertiaryFlagColor: Color(0xFFDC2626),
    ),
  ];

  static const List<String> skinTones = [
    '#F5D0B5',
    '#E8BA9B',
    '#D49B78',
    '#B57A56',
    '#8D5534',
    '#5C3620',
  ];

  static const List<String> hairColors = [
    '#1A1512',
    '#2C1B18',
    '#6B4226',
    '#C49648',
    '#9E3A24',
    '#9CA3AF',
  ];

  static const List<String> faceShapeLabels = [
    'Atletyczna',
    'Kanciasta',
    'Smukła',
    'Owalna',
    'Wyrazista',
  ];

  static const List<String> hairStyleLabels = [
    'Krótki sportowy',
    'Klasyczny czesany',
    'Falisty średni',
    'Buzz Cut',
    'Dłuższy aero',
    'Undercut',
  ];

  static const List<String> facialHairLabels = [
    'Brak',
    'Kilku-dniowy',
    'Krótka broda',
    'Kozia bródka',
    'Wąsy kolarskie',
    'Pełna broda',
  ];

  static const List<({String id, String label})> glassesModels = [
    (id: 'aero_visor', label: 'Aero Visor Pro'),
    (id: 'pro_shield', label: 'Shield Panoramic'),
    (id: 'classic_frame', label: 'Klasyczne Ramki'),
    (id: 'ultralight_rimless', label: 'Bezramkowe Light'),
    (id: 'none', label: 'Bez okularów'),
  ];

  static const List<({String hex, String label})> glassesLensColors = [
    (hex: '#D4AF37', label: 'Złote Lustro'),
    (hex: '#00E5FF', label: 'Cyjan Prizm'),
    (hex: '#8E4A49', label: 'Burgund Road'),
    (hex: '#38BDF8', label: 'Błękit Alpejski'),
    (hex: '#1F2937', label: 'Ciemny Dym'),
  ];

  static const List<({String hex, String label})> shoeColors = [
    (hex: '#F3F4F6', label: 'Białe Pro'),
    (hex: '#181B22', label: 'Czarne Carbon'),
    (hex: '#D4AF37', label: 'Złote Mistrz'),
    (hex: '#8E4A49', label: 'Burgund Aero'),
    (hex: '#00E5FF', label: 'Neon Cyjan'),
    (hex: '#38BDF8', label: 'Błękit Nieba'),
    (hex: '#10B981', label: 'Szmaragd'),
    (hex: '#F59E0B', label: 'Bursztyn'),
  ];

  static const List<BeAProU23TeamOffer> u23Teams = [
    BeAProU23TeamOffer(
      id: 'u23_veloce_krakow',
      name: 'Veloce Kraków U23 Dev',
      countryIso: 'POL',
      regionLabel: 'Małopolska / Karpaty',
      specialtyFocus: 'Wyścigi etapowe i podjazdy U23',
      bikeBrand: 'Kross Vento Carbon',
      primaryColorHex: '#8E4A49',
      secondaryColorHex: '#F3F4F6',
      accentColorHex: '#D4AF37',
      monthlySalaryEur: 1850,
      initialDsTrust: 42.0,
      prestigeStars: 4,
    ),
    BeAProU23TeamOffer(
      id: 'u23_flanders_espoirs',
      name: 'Flanders Cobbles Espoirs',
      countryIso: 'BEL',
      regionLabel: 'Gent / Flandria',
      specialtyFocus: 'Klasyki brukowane i wiatr boczny',
      bikeBrand: 'Ridley Noah Fast',
      primaryColorHex: '#1E3A8A',
      secondaryColorHex: '#38BDF8',
      accentColorHex: '#FACC15',
      monthlySalaryEur: 2100,
      initialDsTrust: 36.0,
      prestigeStars: 5,
    ),
    BeAProU23TeamOffer(
      id: 'u23_alpen_tyrol',
      name: 'Alpenverein Tyrol U23',
      countryIso: 'SLO',
      regionLabel: 'Innsbruck / Alpy',
      specialtyFocus: 'Giro Next Gen & wysokie góry',
      bikeBrand: 'Simplon Pavo IV',
      primaryColorHex: '#0F766E',
      secondaryColorHex: '#111827',
      accentColorHex: '#10B981',
      monthlySalaryEur: 1950,
      initialDsTrust: 38.0,
      prestigeStars: 4,
    ),
    BeAProU23TeamOffer(
      id: 'u23_bretagne_avenir',
      name: 'Bretagne Avenir Continental',
      countryIso: 'FRA',
      regionLabel: 'Rennes / Bretania',
      specialtyFocus: 'Agresywne ucieczki i Tour de l’Avenir',
      bikeBrand: 'Lapierre Xelius DRS',
      primaryColorHex: '#111827',
      secondaryColorHex: '#DC2626',
      accentColorHex: '#F3F4F6',
      monthlySalaryEur: 2050,
      initialDsTrust: 37.0,
      prestigeStars: 4,
    ),
    BeAProU23TeamOffer(
      id: 'u23_lombardia_devo',
      name: 'Lombardia Sprint & Devo',
      countryIso: 'ITA',
      regionLabel: 'Bergamo / Lombardia',
      specialtyFocus: 'Pociągi sprinterskie i klasyki włoskie',
      bikeBrand: 'Bianchi Oltre RC',
      primaryColorHex: '#0D9488',
      secondaryColorHex: '#F3F4F6',
      accentColorHex: '#00E5FF',
      monthlySalaryEur: 1900,
      initialDsTrust: 40.0,
      prestigeStars: 4,
    ),
    BeAProU23TeamOffer(
      id: 'u23_nordic_watt',
      name: 'Nordic Watt Continental',
      countryIso: 'DEN',
      regionLabel: 'Aarhus / Jutlandia',
      specialtyFocus: 'Jazda na czas ITT/TTT i nauka aero',
      bikeBrand: 'Argon 18 E-119',
      primaryColorHex: '#7F1D1D',
      secondaryColorHex: '#181B22',
      accentColorHex: '#D4AF37',
      monthlySalaryEur: 2200,
      initialDsTrust: 34.0,
      prestigeStars: 5,
    ),
  ];
}

Color _parseHex(String hex, Color fallback) {
  try {
    String clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.parse(clean, radix: 16));
  } catch (_) {
    return fallback;
  }
}

/// Ekran kreatora własnego kolarza w trybie "Zostań Legendą" (Be a Pro).
class BeAProCharacterCreatorScreen extends StatefulWidget {
  final void Function(BeAProCreatorResult result)? onCareerCreated;
  final VoidCallback? onBack;

  const BeAProCharacterCreatorScreen({
    super.key,
    this.onCareerCreated,
    this.onBack,
  });

  @override
  State<BeAProCharacterCreatorScreen> createState() =>
      _BeAProCharacterCreatorScreenState();
}

class _BeAProCharacterCreatorScreenState
    extends State<BeAProCharacterCreatorScreen>
    with SingleTickerProviderStateMixin {
  BeAProCharacterDraft _draft = const BeAProCharacterDraft();
  BeAProCreatorStep _currentStep = BeAProCreatorStep.identityAndPhysique;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final AnimationController _turntableController;

  double _previewYawRad = 0.58; // Kąt 3/4 przód
  bool _autoRotate = false;
  bool _showHelmet = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: _draft.firstName);
    _lastNameController = TextEditingController(text: _draft.lastName);
    _turntableController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (!mounted || !_autoRotate) return;
        setState(() {
          _previewYawRad = (_previewYawRad + 0.015) % (math.pi * 2);
        });
      });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _turntableController.dispose();
    super.dispose();
  }

  void _toggleAutoRotate() {
    setState(() {
      _autoRotate = !_autoRotate;
      if (_autoRotate) {
        _turntableController.repeat();
      } else {
        _turntableController.stop();
      }
    });
  }

  void _randomizeProfile() {
    final seed = DateTime.now().microsecondsSinceEpoch;
    final rng = math.Random(seed);
    const firstNames = ['Kacper', 'Mateusz', 'Lukas', 'Thibaut', 'Matteo', 'Jonas', 'Remco', 'Juan'];
    const lastNames = ['Kowalski', 'Nowak', 'De Vries', 'Moreau', 'Rossi', 'Vestergaard', 'Almeida', 'Vermeer'];
    final nat = BeAProCatalog.nationalities[rng.nextInt(BeAProCatalog.nationalities.length)];
    final arch = BeAProGeneticArchetype.values[rng.nextInt(BeAProGeneticArchetype.values.length)];
    final height = (165 + rng.nextInt(28)).toDouble();
    final weight = (55 + rng.nextInt(26)).toDouble();
    final first = firstNames[rng.nextInt(firstNames.length)];
    final last = lastNames[rng.nextInt(lastNames.length)];

    _firstNameController.text = first;
    _lastNameController.text = last;

    setState(() {
      _draft = _draft.copyWith(
        firstName: first,
        lastName: last,
        nationalityIso: nat.iso,
        archetype: arch,
        heightCm: height,
        weightKg: weight,
        faceShapeIndex: rng.nextInt(BeAProCatalog.faceShapeLabels.length),
        skinToneHex: BeAProCatalog.skinTones[rng.nextInt(BeAProCatalog.skinTones.length)],
        hairStyleIndex: rng.nextInt(BeAProCatalog.hairStyleLabels.length),
        hairColorHex: BeAProCatalog.hairColors[rng.nextInt(BeAProCatalog.hairColors.length)],
        facialHairIndex: rng.nextInt(BeAProCatalog.facialHairLabels.length),
        glassesModelId: BeAProCatalog.glassesModels[rng.nextInt(BeAProCatalog.glassesModels.length)].id,
        glassesLensColorHex: BeAProCatalog.glassesLensColors[rng.nextInt(BeAProCatalog.glassesLensColors.length)].hex,
        shoeColorHex: BeAProCatalog.shoeColors[rng.nextInt(BeAProCatalog.shoeColors.length)].hex,
        selectedTeamId: BeAProCatalog.u23Teams[rng.nextInt(BeAProCatalog.u23Teams.length)].id,
      );
    });
  }

  void _submitCareer() {
    if (!_draft.isValidIdentity) {
      setState(() {
        _currentStep = BeAProCreatorStep.identityAndPhysique;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Podaj imię i nazwisko kolarza (min. 2 znaki).'),
          backgroundColor: AppColors.crimsonAlert,
        ),
      );
      return;
    }

    final result = _draft.buildCareerResult();
    if (widget.onCareerCreated != null) {
      widget.onCareerCreated!(result);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.goldAccent, width: 1.0),
          ),
          title: const Text(
            'Kolarz U23 Gotowy do Startu!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            '${result.playerRider.fullName} (${result.playerRider.nationalityIso}) podpisał kontrakt z ${result.selectedTeam.name}.\n'
            'FTP: ${result.physiqueMetrics.estimatedFtpWatts} W '
            '(${result.physiqueMetrics.wattsPerKg.toStringAsFixed(2)} W/kg) • '
            'CdA: ${result.physiqueMetrics.baseCdaHoodsM2.toStringAsFixed(3)} m².',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Zamknij',
                style: TextStyle(color: AppColors.goldAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _draft.computeMetrics();
    final team = _draft.resolveTeamOffer();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1100;
            final isTablet = width >= 700 && width < 1100;

            return Column(
              children: [
                _buildTopHeader(context, isCompact: !isDesktop && !isTablet),
                Expanded(
                  child: (isDesktop || isTablet)
                      ? _buildWideLayout(metrics, team, isDesktop: isDesktop)
                      : _buildMobileLayout(metrics, team),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, {required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          _CreatorIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Powrót',
            onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'ZOSTAŃ LEGENDĄ • BE A PRO',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isCompact
                      ? 'Kreator Kolarza U23'
                      : 'Kreator Kolarza — Kariera Indywidualna U23',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 16 : 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CreatorActionChip(
            icon: Icons.casino_outlined,
            label: isCompact ? 'Losuj' : 'Losuj Profil',
            onTap: _randomizeProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BeAProPhysiqueMetrics metrics,
    BeAProU23TeamOffer team, {
    required bool isDesktop,
  }) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 20 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lewa kolumna: Podgląd 3D na żywo + Telemetria fizyczna
          Expanded(
            flex: isDesktop ? 44 : 46,
            child: Column(
              children: [
                Expanded(
                  child: _build3dPreviewCard(metrics, team, isCompact: false),
                ),
                const SizedBox(height: 12),
                _buildLivePhysicsSummaryCard(metrics, isCompact: false),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 20 : 14),
          // Prawa kolumna: Zakładki i formularz kreatora
          Expanded(
            flex: isDesktop ? 56 : 54,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
              ),
              child: Column(
                children: [
                  _buildStepTabBar(isCompact: false),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isDesktop ? 20 : 16),
                      child: _buildStepContent(metrics, team, isCompact: false),
                    ),
                  ),
                  _buildBottomActionBar(isCompact: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BeAProPhysiqueMetrics metrics,
    BeAProU23TeamOffer team,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 256,
                  child: _build3dPreviewCard(metrics, team, isCompact: true),
                ),
                const SizedBox(height: 10),
                _buildLivePhysicsSummaryCard(metrics, isCompact: true),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor, width: 1.0),
                  ),
                  child: Column(
                    children: [
                      _buildStepTabBar(isCompact: true),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: _buildStepContent(metrics, team, isCompact: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomActionBar(isCompact: true),
      ],
    );
  }

  Widget _build3dPreviewCard(
    BeAProPhysiqueMetrics metrics,
    BeAProU23TeamOffer team, {
    required bool isCompact,
  }) {
    final appearance = _draft.toAppearance();
    final natOption = BeAProCatalog.nationalities.firstWhere(
      (n) => n.iso == _draft.nationalityIso,
      orElse: () => BeAProCatalog.nationalities.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Interaktywne płótno 3D z rzutowaniem perspektywicznym
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _previewYawRad =
                      (_previewYawRad + details.delta.dx * 0.012) % (math.pi * 2);
                });
              },
              child: CustomPaint(
                painter: BeAPro3dRiderPreviewPainter(
                  yawRadians: _previewYawRad,
                  heightCm: _draft.heightCm,
                  weightKg: _draft.weightKg,
                  appearance: appearance,
                  teamPrimaryColor: team.primaryColor,
                  teamSecondaryColor: team.secondaryColor,
                  teamAccentColor: team.accentColor,
                  showHelmet: _showHelmet,
                ),
              ),
            ),
          ),
          // Górny lewy badge kolarza
          Positioned(
            top: isCompact ? 10 : 14,
            left: isCompact ? 10 : 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniCountryFlag(option: natOption),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_draft.firstName.trim().isEmpty ? 'Kolarz' : _draft.firstName.trim()} '
                        '${_draft.lastName.trim().isEmpty ? 'U23' : _draft.lastName.trim()}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_draft.archetype.label} • 18 lat',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _draft.archetype.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Górny prawy zbliżeniowy portret twarzy (RiderAvatarWidget)
          Positioned(
            top: isCompact ? 10 : 14,
            right: isCompact ? 10 : 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RiderAvatarWidget(
                  appearance: appearance,
                  primaryJerseyColorHex: team.primaryColorHex,
                  secondaryJerseyColorHex: team.secondaryColorHex,
                  accentJerseyColorHex: team.accentColorHex,
                  nationalityIso: _draft.nationalityIso,
                  size: isCompact ? 54 : 74,
                  showHelmet: _showHelmet,
                  showGlasses: _draft.glassesModelId != 'none',
                  borderColor: AppColors.goldAccent,
                  borderWidth: 2.0,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Text(
                    'PODGLĄD 3D (PRZECIĄGNIJ)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Dolny pasek sterowania kamerą 3D
          Positioned(
            left: isCompact ? 8 : 12,
            right: isCompact ? 8 : 12,
            bottom: isCompact ? 8 : 12,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    _CameraPresetPill(
                      label: 'Przód',
                      isActive: (_previewYawRad - 0.0).abs() < 0.2,
                      onTap: () => setState(() => _previewYawRad = 0.0),
                    ),
                    _CameraPresetPill(
                      label: '3/4',
                      isActive: (_previewYawRad - 0.58).abs() < 0.2,
                      onTap: () => setState(() => _previewYawRad = 0.58),
                    ),
                    _CameraPresetPill(
                      label: 'Bok',
                      isActive: (_previewYawRad - 1.57).abs() < 0.2,
                      onTap: () => setState(() => _previewYawRad = 1.57),
                    ),
                    _CameraPresetPill(
                      label: 'Tył',
                      isActive: (_previewYawRad - 3.14).abs() < 0.2,
                      onTap: () => setState(() => _previewYawRad = 3.14),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    _CameraPresetPill(
                      label: _showHelmet ? 'Kask: WŁ' : 'Kask: WYŁ',
                      isActive: _showHelmet,
                      onTap: () => setState(() => _showHelmet = !_showHelmet),
                    ),
                    _CameraPresetPill(
                      label: _autoRotate ? 'Obrót: WŁ' : 'Obrót 360°',
                      isActive: _autoRotate,
                      onTap: _toggleAutoRotate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePhysicsSummaryCard(
    BeAProPhysiqueMetrics metrics, {
    required bool isCompact,
  }) {
    final balanceText = metrics.terrainBalanceRatio < -0.15
        ? 'Przewaga Gór'
        : (metrics.terrainBalanceRatio > 0.15
            ? 'Przewaga Płaskie / Sprint'
            : 'Zrównoważony Teren');

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.speed_rounded,
                size: 16,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'FIZYKA CIAŁA I AERODYNAMIKA CdA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                balanceText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: metrics.terrainBalanceRatio < -0.15
                      ? AppColors.crimsonAlert
                      : (metrics.terrainBalanceRatio > 0.15
                          ? AppColors.statusSuccess
                          : AppColors.goldAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'CdA (Chwyty)',
                  value: '${metrics.baseCdaHoodsM2.toStringAsFixed(3)} m²',
                  accent: AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'CdA (TT)',
                  value: '${metrics.baseCdaTtM2.toStringAsFixed(3)} m²',
                  accent: AppColors.cyanAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'FTP / W·kg',
                  value:
                      '${metrics.estimatedFtpWatts} W (${metrics.wattsPerKg.toStringAsFixed(2)})',
                  accent: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TerrainPredispositionBar(
            mountainScore: metrics.mountainPredisposition,
            flatScore: metrics.flatPredisposition,
          ),
        ],
      ),
    );
  }

  Widget _buildStepTabBar({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 14,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: BeAProCreatorStep.values.map((step) {
          final isSelected = _currentStep == step;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _StepTabButton(
                step: step,
                isSelected: isSelected,
                isCompact: isCompact,
                onTap: () => setState(() => _currentStep = step),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepContent(
    BeAProPhysiqueMetrics metrics,
    BeAProU23TeamOffer team, {
    required bool isCompact,
  }) {
    switch (_currentStep) {
      case BeAProCreatorStep.identityAndPhysique:
        return _buildIdentityAndPhysiqueStep(metrics);
      case BeAProCreatorStep.geneticArchetype:
        return _buildGeneticArchetypeStep(metrics);
      case BeAProCreatorStep.appearance3d:
        return _buildAppearance3dStep();
      case BeAProCreatorStep.u23Team:
        return _buildU23TeamStep(team);
    }
  }

  Widget _buildIdentityAndPhysiqueStep(BeAProPhysiqueMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Dane Osobowe Kolarza',
          subtitle: '18-letni debiutant wchodzący do peletonu U23 Continental.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DarkTextField(
                controller: _firstNameController,
                label: 'Imię',
                hint: 'np. Kacper',
                onChanged: (val) =>
                    setState(() => _draft = _draft.copyWith(firstName: val)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DarkTextField(
                controller: _lastNameController,
                label: 'Nazwisko',
                hint: 'np. Kowalski',
                onChanged: (val) =>
                    setState(() => _draft = _draft.copyWith(lastName: val)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Narodowość',
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
          children: BeAProCatalog.nationalities.map((nat) {
            final selected = _draft.nationalityIso == nat.iso;
            return _SelectableOptionChip(
              isSelected: selected,
              onTap: () =>
                  setState(() => _draft = _draft.copyWith(nationalityIso: nat.iso)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniCountryFlag(option: nat),
                  const SizedBox(width: 6),
                  Text(
                    '${nat.iso} • ${nat.countryName}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Antropometria: Wzrost i Waga Startowa',
          subtitle:
              'Wzrost i masa bezpośrednio determinują powierzchnię czołową (CdA), W/kg oraz predyspozycje terenowe.',
        ),
        const SizedBox(height: 12),
        _PhysicsSliderCard(
          label: 'Wzrost',
          valueText: '${_draft.heightCm.round()} cm',
          subValueText: 'BSA: ${metrics.bodySurfaceAreaM2.toStringAsFixed(2)} m²',
          value: _draft.heightCm,
          min: BeAProPhysicsCalculator.minHeightCm,
          max: BeAProPhysicsCalculator.maxHeightCm,
          divisions: 38,
          accentColor: AppColors.accentBlue,
          onChanged: (val) => setState(
            () => _draft = _draft.copyWith(heightCm: val.roundToDouble()),
          ),
        ),
        const SizedBox(height: 12),
        _PhysicsSliderCard(
          label: 'Waga startowa',
          valueText: '${_draft.weightKg.toStringAsFixed(1)} kg',
          subValueText: 'BMI: ${metrics.bmi.toStringAsFixed(1)}',
          value: _draft.weightKg,
          min: BeAProPhysicsCalculator.minWeightKg,
          max: BeAProPhysicsCalculator.maxWeightKg,
          divisions: 68,
          accentColor: AppColors.goldAccent,
          onChanged: (val) => setState(
            () => _draft = _draft.copyWith(
              weightKg: (val * 2).round() / 2.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneticArchetypeStep(BeAProPhysiqueMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Archetyp Genetyczny',
          subtitle:
              'Określa proporcje włókien mięśniowych, pułap VO2max, pojemność beztlenową W\' oraz profil mocy.',
        ),
        const SizedBox(height: 12),
        ...BeAProGeneticArchetype.values.map((arch) {
          final isSelected = _draft.archetype == arch;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ArchetypeCard(
              archetype: arch,
              isSelected: isSelected,
              onTap: () =>
                  setState(() => _draft = _draft.copyWith(archetype: arch)),
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WYNIKOWY PROFIL WYDOLNOŚCIOWY (18 LAT)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _AttributeBarRow(
                label: 'Góry / Wspinaczka',
                score: metrics.mountainPredisposition,
                color: AppColors.crimsonAlert,
              ),
              _AttributeBarRow(
                label: 'Płaskie / Ranty',
                score: metrics.flatPredisposition,
                color: AppColors.accentBlue,
              ),
              _AttributeBarRow(
                label: 'Bruk / Klasyki',
                score: metrics.cobblesPredisposition,
                color: AppColors.amberWarning,
              ),
              _AttributeBarRow(
                label: 'Jazda na czas (ITT)',
                score: metrics.ttPredisposition,
                color: AppColors.cyanAccent,
              ),
              _AttributeBarRow(
                label: 'Sprint (${metrics.sprint5sWatts} W / 5s)',
                score: metrics.sprintPredisposition,
                color: AppColors.statusSuccess,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearance3dStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Personalizacja 3D na Żywo',
          subtitle:
              'Dostosuj rysy twarzy, fryzurę, okulary i kolor butów — zmiany natychmiast aktualizują model 3D.',
        ),
        const SizedBox(height: 14),
        // Kształt twarzy
        _LabelledSelectorRow(
          label: 'Kształt twarzy',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(BeAProCatalog.faceShapeLabels.length, (i) {
              return _SelectableOptionChip(
                isSelected: _draft.faceShapeIndex == i,
                onTap: () =>
                    setState(() => _draft = _draft.copyWith(faceShapeIndex: i)),
                child: Text(
                  BeAProCatalog.faceShapeLabels[i],
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        // Karnacja
        _LabelledSelectorRow(
          label: 'Karnacja skóry',
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: BeAProCatalog.skinTones.map((hex) {
              return _ColorSwatchCircle(
                color: _parseHex(hex, const Color(0xFFE8BA9B)),
                isSelected: _draft.skinToneHex == hex,
                onTap: () =>
                    setState(() => _draft = _draft.copyWith(skinToneHex: hex)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        // Fryzura i kolor włosów
        _LabelledSelectorRow(
          label: 'Fryzura (odznacz kask w podglądzie 3D, aby zobaczyć całość)',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(BeAProCatalog.hairStyleLabels.length, (i) {
              return _SelectableOptionChip(
                isSelected: _draft.hairStyleIndex == i,
                onTap: () =>
                    setState(() => _draft = _draft.copyWith(hairStyleIndex: i)),
                child: Text(
                  BeAProCatalog.hairStyleLabels[i],
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        _LabelledSelectorRow(
          label: 'Kolor włosów i zarostu',
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: BeAProCatalog.hairColors.map((hex) {
              return _ColorSwatchCircle(
                color: _parseHex(hex, const Color(0xFF2C1B18)),
                isSelected: _draft.hairColorHex == hex,
                onTap: () =>
                    setState(() => _draft = _draft.copyWith(hairColorHex: hex)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _LabelledSelectorRow(
          label: 'Zarost',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(BeAProCatalog.facialHairLabels.length, (i) {
              return _SelectableOptionChip(
                isSelected: _draft.facialHairIndex == i,
                onTap: () =>
                    setState(() => _draft = _draft.copyWith(facialHairIndex: i)),
                child: Text(
                  BeAProCatalog.facialHairLabels[i],
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        // Okulary
        _LabelledSelectorRow(
          label: 'Okulary sportowe',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BeAProCatalog.glassesModels.map((model) {
              return _SelectableOptionChip(
                isSelected: _draft.glassesModelId == model.id,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(glassesModelId: model.id),
                ),
                child: Text(
                  model.label,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
        if (_draft.glassesModelId != 'none') ...[
          const SizedBox(height: 12),
          _LabelledSelectorRow(
            label: 'Soczewki okularów',
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: BeAProCatalog.glassesLensColors.map((lens) {
                return _ColorSwatchCircle(
                  color: _parseHex(lens.hex, AppColors.goldAccent),
                  tooltip: lens.label,
                  isSelected: _draft.glassesLensColorHex == lens.hex,
                  onTap: () => setState(
                    () => _draft = _draft.copyWith(glassesLensColorHex: lens.hex),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Kolor butów
        _LabelledSelectorRow(
          label: 'Kolor butów kolarskich (widoczne na modelu 3D)',
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: BeAProCatalog.shoeColors.map((shoe) {
              return _ColorSwatchCircle(
                color: _parseHex(shoe.hex, Colors.white),
                tooltip: shoe.label,
                isSelected: _draft.shoeColorHex == shoe.hex,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(shoeColorHex: shoe.hex),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _PhysicsSliderCard(
          label: 'Wysokość skarpet UCI',
          valueText: '${(_draft.sockHeightProportion * 22).round()} cm',
          subValueText: 'Regulamin UCI max 50% piszczeli',
          value: _draft.sockHeightProportion,
          min: 0.35,
          max: 0.85,
          divisions: 10,
          accentColor: AppColors.primaryAccent,
          onChanged: (val) => setState(
            () => _draft = _draft.copyWith(sockHeightProportion: val),
          ),
        ),
      ],
    );
  }

  Widget _buildU23TeamStep(BeAProU23TeamOffer selectedTeam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Wybór Pierwszej Drużyny U23 / Continental',
          subtitle:
              'Podpisz pierwszy roczny kontrakt zawodowy. Barwy drużyny zmienią strój kolarza w podglądzie 3D.',
        ),
        const SizedBox(height: 12),
        ...BeAProCatalog.u23Teams.map((team) {
          final isSelected = team.id == selectedTeam.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _U23TeamCard(
              team: team,
              isSelected: isSelected,
              onTap: () =>
                  setState(() => _draft = _draft.copyWith(selectedTeamId: team.id)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomActionBar({required bool isCompact}) {
    const steps = BeAProCreatorStep.values;
    final idx = steps.indexOf(_currentStep);
    final isFirst = idx == 0;
    final isLast = idx == steps.length - 1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          _CreatorButton(
            label: 'Wstecz',
            icon: Icons.chevron_left_rounded,
            isPrimary: false,
            isDisabled: isFirst,
            onPressed: isFirst
                ? null
                : () => setState(() => _currentStep = steps[idx - 1]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CreatorButton(
              label: isLast
                  ? (isCompact ? 'Podpisz Kontrakt' : 'Rozpocznij Karierę U23')
                  : 'Dalej: ${steps[idx + 1].title}',
              icon: isLast
                  ? Icons.check_circle_outline_rounded
                  : Icons.chevron_right_rounded,
              iconTrailing: !isLast,
              isPrimary: true,
              isGoldAccent: isLast,
              isDisabled: isLast && !_draft.isValidIdentity,
              onPressed: () {
                if (isLast) {
                  _submitCareer();
                } else {
                  setState(() => _currentStep = steps[idx + 1]);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Rzutnik 3D na żywo prezentujący kolarza na rowerze szosowym na podświetlonym podium.
class BeAPro3dRiderPreviewPainter extends CustomPainter {
  final double yawRadians;
  final double heightCm;
  final double weightKg;
  final RiderAppearance appearance;
  final Color teamPrimaryColor;
  final Color teamSecondaryColor;
  final Color teamAccentColor;
  final bool showHelmet;

  BeAPro3dRiderPreviewPainter({
    required this.yawRadians,
    required this.heightCm,
    required this.weightKg,
    required this.appearance,
    required this.teamPrimaryColor,
    required this.teamSecondaryColor,
    required this.teamAccentColor,
    required this.showHelmet,
  });

  Offset _project(
    double x,
    double y,
    double z,
    Size size,
    double scale,
  ) {
    final cosY = math.cos(yawRadians);
    final sinY = math.sin(yawRadians);
    final rx = x * cosY - z * sinY;
    final rz = x * sinY + z * cosY;

    const cameraDistance = 4.6;
    final perspective = cameraDistance / (cameraDistance + rz);
    final cx = size.width * 0.5;
    final cy = size.height * 0.78;
    return Offset(
      cx + rx * scale * perspective,
      cy - y * scale * perspective + rz * scale * 0.12,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Tło studia 3D z subtelnym reflektorem
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.15),
        radius: 0.95,
        colors: [
          teamPrimaryColor.withValues(alpha: 0.24),
          AppColors.surfaceLight,
          AppColors.background,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final scale = math.min(size.width, size.height) * 0.36;

    // 2. Siatka podłogi i obrotowe podium 3D
    _drawStudioPedestal(canvas, size, scale);

    // 3. Skalowanie proporcji sylwetki (wzrost i waga fizycznie zmieniają sylwetkę 3D)
    final heightScale = 0.88 + ((heightCm - 160.0) / 38.0) * 0.24;
    final bulkScale = 0.82 + ((weightKg - 52.0) / 34.0) * 0.42;

    // 4. Rower szosowy 3D
    _drawRoadBike3d(canvas, size, scale);

    // 5. Kolarz 3D (nogi, buty, skarpety, tułów, ręce, głowa, kask, okulary)
    _drawRider3d(canvas, size, scale, heightScale, bulkScale);
  }

  void _drawStudioPedestal(Canvas canvas, Size size, double scale) {
    final center = _project(0, -0.02, 0, size, scale);
    final rx = scale * 1.15;
    final ry = scale * 0.30;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.22),
          teamPrimaryColor.withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCenter(center: center, width: rx * 2.4, height: ry * 2.6),
      );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2.2, height: ry * 2.2),
      glowPaint,
    );

    final discPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.85);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 1.75, height: ry * 1.75),
      discPaint,
    );

    final ringPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 1.75, height: ry * 1.75),
      ringPaint,
    );
  }

  void _drawRoadBike3d(Canvas canvas, Size size, double scale) {
    final rearHub = _project(-0.62, 0.34, 0, size, scale);
    final frontHub = _project(0.64, 0.34, 0, size, scale);
    final bb = _project(-0.10, 0.32, 0, size, scale);
    final seatCluster = _project(-0.24, 0.82, 0, size, scale);
    final headTubeTop = _project(0.42, 0.86, 0, size, scale);
    final headTubeBot = _project(0.46, 0.72, 0, size, scale);
    final stemTop = _project(0.50, 0.94, 0, size, scale);
    final barLeft = _project(0.54, 0.92, -0.22, size, scale);
    final barRight = _project(0.54, 0.92, 0.22, size, scale);

    // Koła 3D (elipsy spłaszczone w osi yaw)
    final wheelAspect = math.cos(yawRadians).abs().clamp(0.18, 1.0);
    _drawWheel3d(canvas, rearHub, scale * 0.34, wheelAspect);
    _drawWheel3d(canvas, frontHub, scale * 0.34, wheelAspect);

    // Rama szosowa w barwach drużyny
    final framePaint = Paint()
      ..color = teamPrimaryColor
      ..strokeWidth = (scale * 0.048).clamp(2.5, 6.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stayPaint = Paint()
      ..color = teamSecondaryColor
      ..strokeWidth = (scale * 0.030).clamp(1.8, 4.0)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(rearHub, bb, stayPaint);
    canvas.drawLine(rearHub, seatCluster, stayPaint);
    canvas.drawLine(bb, seatCluster, framePaint);
    canvas.drawLine(bb, headTubeBot, framePaint);
    canvas.drawLine(seatCluster, headTubeTop, framePaint);
    canvas.drawLine(headTubeTop, headTubeBot, framePaint);
    canvas.drawLine(headTubeBot, frontHub, framePaint);

    // Kierownica karbonowa
    final barPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = (scale * 0.032).clamp(2.0, 4.2)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(headTubeTop, stemTop, barPaint);
    canvas.drawLine(barLeft, barRight, barPaint);

    // Siodełko
    final saddleBack = _project(-0.34, 0.92, 0, size, scale);
    final saddleFront = _project(-0.18, 0.92, 0, size, scale);
    canvas.drawLine(seatCluster, _project(-0.25, 0.91, 0, size, scale), barPaint);
    canvas.drawLine(
      saddleBack,
      saddleFront,
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = (scale * 0.042).clamp(2.5, 5.0)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawWheel3d(
    Canvas canvas,
    Offset center,
    double radius,
    double widthAspect,
  ) {
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 2 * widthAspect,
      height: radius * 2,
    );
    final tirePaint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius * 0.18).clamp(3.0, 7.0);
    canvas.drawOval(rect, tirePaint);

    final rimPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawOval(rect.deflate(radius * 0.12), rimPaint);

    // Piasta
    canvas.drawCircle(
      center,
      (radius * 0.10).clamp(2.0, 4.5),
      Paint()..color = teamAccentColor,
    );
  }

  void _drawRider3d(
    Canvas canvas,
    Size size,
    double scale,
    double heightScale,
    double bulkScale,
  ) {
    final skinColor = _parseHex(appearance.skinToneHex, const Color(0xFFE8BA9B));
    final hairColor = _parseHex(appearance.hairColorHex, const Color(0xFF2C1B18));
    final shoeColor = _parseHex(appearance.shoeColorHex, Colors.white);
    final lensColor = _parseHex(appearance.glassesLensColorHex, AppColors.goldAccent);

    final hip = _project(-0.24, 0.96 * heightScale, 0, size, scale);
    final shoulderCenter = _project(0.14, 1.32 * heightScale, 0, size, scale);
    final headCenter = _project(0.24, 1.54 * heightScale, 0, size, scale);

    final legThickness = (scale * 0.075 * bulkScale).clamp(4.0, 11.0);
    final armThickness = (scale * 0.052 * bulkScale).clamp(3.0, 8.0);
    final torsoThickness = (scale * 0.145 * bulkScale).clamp(9.0, 22.0);

    // Lewa i prawa noga w układzie 3D (prawa noga niżej na pedale)
    _drawLegWithShoe(
      canvas: canvas,
      size: size,
      scale: scale,
      hip: hip,
      knee3d: _project(0.02, 0.68 * heightScale, -0.14, size, scale),
      ankle3d: _project(-0.08, 0.28, -0.15, size, scale),
      toe3d: _project(0.06, 0.25, -0.15, size, scale),
      legThickness: legThickness,
      skinColor: skinColor,
      shoeColor: shoeColor,
    );

    // Tułów w koszulce drużyny
    final jerseyPaint = Paint()
      ..color = teamPrimaryColor
      ..strokeWidth = torsoThickness
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hip, shoulderCenter, jerseyPaint);

    // Pasek drużynowy na piersi
    final midTorso = Offset.lerp(hip, shoulderCenter, 0.56)!;
    final upperTorso = Offset.lerp(hip, shoulderCenter, 0.80)!;
    canvas.drawLine(
      midTorso,
      upperTorso,
      Paint()
        ..color = teamSecondaryColor
        ..strokeWidth = torsoThickness * 0.96
        ..strokeCap = StrokeCap.butt,
    );

    // Prawa noga (bliżej kamery w ujęciu bocznym)
    _drawLegWithShoe(
      canvas: canvas,
      size: size,
      scale: scale,
      hip: hip,
      knee3d: _project(0.08, 0.78 * heightScale, 0.14, size, scale),
      ankle3d: _project(-0.12, 0.42, 0.15, size, scale),
      toe3d: _project(0.02, 0.40, 0.15, size, scale),
      legThickness: legThickness,
      skinColor: skinColor,
      shoeColor: shoeColor,
    );

    // Ręce na klamkomanetkach
    final barLeft = _project(0.54, 0.92, -0.20, size, scale);
    final barRight = _project(0.54, 0.92, 0.20, size, scale);
    final sleevePaint = Paint()
      ..color = teamPrimaryColor
      ..strokeWidth = armThickness * 1.15
      ..strokeCap = StrokeCap.round;
    final armSkinPaint = Paint()
      ..color = skinColor
      ..strokeWidth = armThickness
      ..strokeCap = StrokeCap.round;

    final leftElbow = Offset.lerp(shoulderCenter, barLeft, 0.48)!;
    final rightElbow = Offset.lerp(shoulderCenter, barRight, 0.48)!;
    canvas.drawLine(shoulderCenter, leftElbow, sleevePaint);
    canvas.drawLine(leftElbow, barLeft, armSkinPaint);
    canvas.drawLine(shoulderCenter, rightElbow, sleevePaint);
    canvas.drawLine(rightElbow, barRight, armSkinPaint);

    // Głowa, włosy, kask i okulary
    final headRadius = (scale * 0.115).clamp(7.0, 17.0);
    canvas.drawCircle(headCenter, headRadius, Paint()..color = skinColor);

    if (!showHelmet) {
      // Włosy na głowie
      final hairRect = Rect.fromCenter(
        center: headCenter.translate(0, -headRadius * 0.32),
        width: headRadius * 2.05,
        height: headRadius * 1.35,
      );
      canvas.drawArc(
        hairRect,
        math.pi,
        math.pi,
        true,
        Paint()..color = hairColor,
      );
    } else {
      // Kask aero w barwach zespołu
      final helmetRect = Rect.fromCenter(
        center: headCenter.translate(0, -headRadius * 0.26),
        width: headRadius * 2.35,
        height: headRadius * 1.55,
      );
      canvas.drawArc(
        helmetRect,
        math.pi * 0.95,
        math.pi * 1.1,
        true,
        Paint()..color = teamPrimaryColor,
      );
      canvas.drawArc(
        helmetRect.deflate(2),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        Paint()
          ..color = teamAccentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Okulary sportowe
    if (appearance.glassesModelId != 'none') {
      final eyeOffset = Offset(
        math.sin(yawRadians) * headRadius * 0.45,
        -headRadius * 0.08,
      );
      final visorCenter = headCenter + eyeOffset;
      final visorWidth = headRadius * 1.35;
      final visorHeight = headRadius * 0.46;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: visorCenter,
            width: visorWidth,
            height: visorHeight,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = lensColor,
      );
    }
  }

  void _drawLegWithShoe({
    required Canvas canvas,
    required Size size,
    required double scale,
    required Offset hip,
    required Offset knee3d,
    required Offset ankle3d,
    required Offset toe3d,
    required double legThickness,
    required Color skinColor,
    required Color shoeColor,
  }) {
    // Spodenki kolarskie (udo)
    final midThigh = Offset.lerp(hip, knee3d, 0.72)!;
    canvas.drawLine(
      hip,
      midThigh,
      Paint()
        ..color = const Color(0xFF111827)
        ..strokeWidth = legThickness * 1.12
        ..strokeCap = StrokeCap.round,
    );
    // Dolna część uda + łydka
    canvas.drawLine(
      midThigh,
      knee3d,
      Paint()
        ..color = skinColor
        ..strokeWidth = legThickness * 0.95
        ..strokeCap = StrokeCap.round,
    );
    final sockStart = Offset.lerp(
      ankle3d,
      knee3d,
      appearance.sockHeightProportion.clamp(0.3, 0.85) * 0.55,
    )!;
    canvas.drawLine(
      knee3d,
      sockStart,
      Paint()
        ..color = skinColor
        ..strokeWidth = legThickness * 0.82
        ..strokeCap = StrokeCap.round,
    );
    // Skarpeta kolarska
    canvas.drawLine(
      sockStart,
      ankle3d,
      Paint()
        ..color = teamSecondaryColor
        ..strokeWidth = legThickness * 0.86
        ..strokeCap = StrokeCap.round,
    );
    // But kolarski w wybranym kolorze + podeszwa karbonowa
    canvas.drawLine(
      ankle3d.translate(0, 2),
      toe3d.translate(0, 2),
      Paint()
        ..color = const Color(0xFF0B0D11)
        ..strokeWidth = legThickness * 0.95
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      ankle3d,
      toe3d,
      Paint()
        ..color = shoeColor
        ..strokeWidth = legThickness * 0.82
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant BeAPro3dRiderPreviewPainter oldDelegate) {
    return oldDelegate.yawRadians != yawRadians ||
        oldDelegate.heightCm != heightCm ||
        oldDelegate.weightKg != weightKg ||
        oldDelegate.appearance != appearance ||
        oldDelegate.teamPrimaryColor != teamPrimaryColor ||
        oldDelegate.teamSecondaryColor != teamSecondaryColor ||
        oldDelegate.teamAccentColor != teamAccentColor ||
        oldDelegate.showHelmet != showHelmet;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LabelledSelectorRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabelledSelectorRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DarkTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;

  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_DarkTextField> createState() => _DarkTextFieldState();
}

class _DarkTextFieldState extends State<_DarkTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhysicsSliderCard extends StatelessWidget {
  final String label;
  final String valueText;
  final String subValueText;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _PhysicsSliderCard({
    required this.label,
    required this.valueText,
    required this.subValueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                subValueText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                valueText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: accentColor,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: AppColors.background,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.16),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TerrainPredispositionBar extends StatelessWidget {
  final int mountainScore;
  final int flatScore;

  const _TerrainPredispositionBar({
    required this.mountainScore,
    required this.flatScore,
  });

  @override
  Widget build(BuildContext context) {
    final total = (mountainScore + flatScore).clamp(1, 200);
    final mountainRatio = (mountainScore / total).clamp(0.2, 0.8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Góry: $mountainScore',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.crimsonAlert,
              ),
            ),
            Text(
              'Płaskie / Aero: $flatScore',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 7,
            child: Row(
              children: [
                Expanded(
                  flex: (mountainRatio * 100).round(),
                  child: Container(color: AppColors.crimsonAlert),
                ),
                Expanded(
                  flex: ((1.0 - mountainRatio) * 100).round(),
                  child: Container(color: AppColors.accentBlue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttributeBarRow extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _AttributeBarRow({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$score / 100',
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
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchetypeCard extends StatefulWidget {
  final BeAProGeneticArchetype archetype;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArchetypeCard({
    required this.archetype,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ArchetypeCard> createState() => _ArchetypeCardState();
}

class _ArchetypeCardState extends State<_ArchetypeCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.archetype.accentColor;
    final borderColor = widget.isSelected
        ? accent
        : (_focused
            ? AppColors.goldAccent
            : (_hovered ? AppColors.textSecondary : AppTheme.borderColor));

    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? accent.withValues(alpha: 0.12)
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.archetype.shortCode,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.archetype.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${widget.archetype.idealHeightRangeLabel} • ${widget.archetype.idealWeightRangeLabel}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.archetype.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _U23TeamCard extends StatefulWidget {
  final BeAProU23TeamOffer team;
  final bool isSelected;
  final VoidCallback onTap;

  const _U23TeamCard({
    required this.team,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_U23TeamCard> createState() => _U23TeamCardState();
}

class _U23TeamCardState extends State<_U23TeamCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final team = widget.team;
    final nat = BeAProCatalog.nationalities.firstWhere(
      (n) => n.iso == team.countryIso,
      orElse: () => BeAProCatalog.nationalities.first,
    );

    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? team.primaryColor.withValues(alpha: 0.16)
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.9)
                    : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : (_focused
                      ? AppColors.goldAccent
                      : (_hovered
                          ? AppColors.textSecondary
                          : AppTheme.borderColor)),
              width: widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Swatch barw drużyny
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [team.primaryColor, team.secondaryColor],
                  ),
                  border: Border.all(color: team.accentColor, width: 1.5),
                ),
                alignment: Alignment.center,
                child: _MiniCountryFlag(option: nat),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${team.monthlySalaryEur} €/mies.',
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
                    const SizedBox(height: 3),
                    Text(
                      '${team.regionLabel} • ${team.specialtyFocus}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Rower: ${team.bikeBrand} • Zaufanie DS start: ${team.initialDsTrust.round()}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTabButton extends StatefulWidget {
  final BeAProCreatorStep step;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _StepTabButton({
    required this.step,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_StepTabButton> createState() => _StepTabButtonState();
}

class _StepTabButtonState extends State<_StepTabButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 6 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.25)
                : (_hovered ? AppColors.background.withValues(alpha: 0.6) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : (_focused ? AppColors.accentBlue : Colors.transparent),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.step.icon,
                size: 15,
                color: widget.isSelected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              if (!widget.isCompact) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.step.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: widget.isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableOptionChip extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _SelectableOptionChip({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  State<_SelectableOptionChip> createState() => _SelectableOptionChipState();
}

class _SelectableOptionChipState extends State<_SelectableOptionChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.28)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : (_focused
                      ? AppColors.accentBlue
                      : (_hovered
                          ? AppColors.textSecondary
                          : AppTheme.borderColor)),
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchCircle extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final String? tooltip;
  final VoidCallback onTap;

  const _ColorSwatchCircle({
    required this.color,
    required this.isSelected,
    this.tooltip,
    required this.onTap,
  });

  @override
  State<_ColorSwatchCircle> createState() => _ColorSwatchCircleState();
}

class _ColorSwatchCircleState extends State<_ColorSwatchCircle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final swatch = FocusableActionDetector(
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : (_hovered ? AppColors.textPrimary : AppTheme.borderColor),
              width: widget.isSelected ? 2.5 : 1.2,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: swatch);
    }
    return swatch;
  }
}

class _CameraPresetPill extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CameraPresetPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CameraPresetPill> createState() => _CameraPresetPillState();
}

class _CameraPresetPillState extends State<_CameraPresetPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.goldAccent.withValues(alpha: 0.22)
                : AppColors.background.withValues(alpha: _hovered ? 0.92 : 0.78),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.goldAccent
                  : (_hovered ? AppColors.textSecondary : AppTheme.borderColor),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: widget.isActive
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniCountryFlag extends StatelessWidget {
  final BeAProNationalityOption option;

  const _MiniCountryFlag({required this.option});

  @override
  Widget build(BuildContext context) {
    final hasThird = option.tertiaryFlagColor != Colors.transparent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: 18,
        height: 12,
        child: option.isHorizontal
            ? Column(
                children: [
                  Expanded(child: Container(color: option.primaryFlagColor)),
                  Expanded(child: Container(color: option.secondaryFlagColor)),
                  if (hasThird)
                    Expanded(child: Container(color: option.tertiaryFlagColor)),
                ],
              )
            : Row(
                children: [
                  Expanded(child: Container(color: option.primaryFlagColor)),
                  Expanded(child: Container(color: option.secondaryFlagColor)),
                  if (hasThird)
                    Expanded(child: Container(color: option.tertiaryFlagColor)),
                ],
              ),
      ),
    );
  }
}

class _CreatorIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CreatorIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_CreatorIconButton> createState() => _CreatorIconButtonState();
}

class _CreatorIconButtonState extends State<_CreatorIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered ? AppColors.goldAccent : AppTheme.borderColor,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatorActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CreatorActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_CreatorActionChip> createState() => _CreatorActionChipState();
}

class _CreatorActionChipState extends State<_CreatorActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceLight : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? AppColors.goldAccent : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: AppColors.goldAccent),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool iconTrailing;
  final bool isPrimary;
  final bool isGoldAccent;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const _CreatorButton({
    required this.label,
    required this.icon,
    this.iconTrailing = false,
    required this.isPrimary,
    this.isGoldAccent = false,
    this.isDisabled = false,
    required this.onPressed,
  });

  @override
  State<_CreatorButton> createState() => _CreatorButtonState();
}

class _CreatorButtonState extends State<_CreatorButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isDisabled || widget.onPressed == null;
    final bgColor = disabled
        ? AppColors.background.withValues(alpha: 0.45)
        : (widget.isPrimary
            ? (widget.isGoldAccent
                ? (_hovered
                    ? AppColors.goldAccent.withValues(alpha: 0.92)
                    : AppColors.goldAccent)
                : (_hovered
                    ? AppColors.primaryAccent.withValues(alpha: 0.92)
                    : AppColors.primaryAccent))
            : (_hovered ? AppColors.surfaceLight : AppColors.background));

    final fgColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isPrimary && widget.isGoldAccent
            ? Colors.black
            : AppColors.textPrimary);

    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      mouseCursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.accentBlue
                    : (disabled
                        ? AppTheme.borderColor.withValues(alpha: 0.5)
                        : (widget.isGoldAccent
                            ? AppColors.goldAccent
                            : AppTheme.borderColor)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.iconTrailing) ...[
                  Icon(widget.icon, size: 18, color: fgColor),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                    ),
                  ),
                ),
                if (widget.iconTrailing) ...[
                  const SizedBox(width: 6),
                  Icon(widget.icon, size: 18, color: fgColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
