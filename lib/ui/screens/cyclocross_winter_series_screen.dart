import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/race/cyclocross_course_and_mud_model.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';

/// Ranga wyścigu w Zimowym Pucharze Przełajowym (listopad–styczeń).
enum CyclocrossRaceTier {
  c1Classic,
  superprestige,
  worldCup,
  worldChampionships;

  String get labelPl {
    switch (this) {
      case CyclocrossRaceTier.c1Classic:
        return 'UCI C1 Classic';
      case CyclocrossRaceTier.superprestige:
        return 'Superprestige';
      case CyclocrossRaceTier.worldCup:
        return 'Puchar Świata UCI';
      case CyclocrossRaceTier.worldChampionships:
        return 'Mistrzostwa Świata CX';
    }
  }

  double get careerBonusMultiplier {
    switch (this) {
      case CyclocrossRaceTier.c1Classic:
        return 1.0;
      case CyclocrossRaceTier.superprestige:
        return 1.25;
      case CyclocrossRaceTier.worldCup:
        return 1.45;
      case CyclocrossRaceTier.worldChampionships:
        return 1.85;
    }
  }

  int get baseUciPoints {
    switch (this) {
      case CyclocrossRaceTier.c1Classic:
        return 80;
      case CyclocrossRaceTier.superprestige:
        return 140;
      case CyclocrossRaceTier.worldCup:
        return 200;
      case CyclocrossRaceTier.worldChampionships:
        return 400;
    }
  }
}

/// Typ bieżnika szytki przełajowej (33 mm UCI).
enum CyclocrossTubularTread {
  mudAggressive,
  allRounder,
  sandFile,
  iceSpike;

  String get labelPl {
    switch (this) {
      case CyclocrossTubularTread.mudAggressive:
        return 'Błotna (Rhino)';
      case CyclocrossTubularTread.allRounder:
        return 'Uniwersalna (Grifo)';
      case CyclocrossTubularTread.sandFile:
        return 'Piasek / Szybka (Dune)';
      case CyclocrossTubularTread.iceSpike:
        return 'Zmarzlina (Fang)';
    }
  }

  String get shortHint {
    switch (this) {
      case CyclocrossTubularTread.mudAggressive:
        return 'Wysokie klocki na głębokie błoto i trawersy';
      case CyclocrossTubularTread.allRounder:
        return 'Zbalansowany bieżnik na trawę i zmienne podłoże';
      case CyclocrossTubularTread.sandFile:
        return 'Niskie opory toczenia na piasku i asfalcie';
      case CyclocrossTubularTread.iceSpike:
        return 'Krawędziowe trzymanie na zamarzniętych koleinach';
    }
  }
}

/// Pojedynczy wyścig w kalendarzu Zimowego Pucharu Przełajowego.
class CyclocrossRaceEntry {
  final String id;
  final int roundNumber;
  final String name;
  final String location;
  final String dateLabel;
  final CyclocrossRaceTier tier;
  final CyclocrossCourseAndMudModel course;
  final String signatureFeature;

  const CyclocrossRaceEntry({
    required this.id,
    required this.roundNumber,
    required this.name,
    required this.location,
    required this.dateLabel,
    required this.tier,
    required this.course,
    required this.signatureFeature,
  });

  bool get isWorldChampionship =>
      tier == CyclocrossRaceTier.worldChampionships;
}

/// Wynik analizy ciśnienia w szytkach przełajowych (1.30–1.80 bar).
class CyclocrossTirePressureAnalysis {
  final double selectedPressureBar;
  final double recommendedPressureBar;
  final CyclocrossTubularTread recommendedTread;
  final double tractionScorePercent;
  final double rollingResistanceWatts;
  final double rimStrikeRiskPercent;
  final double offCamberGripPercent;
  final bool isOptimalWindow;
  final String statusLabel;

  const CyclocrossTirePressureAnalysis({
    required this.selectedPressureBar,
    required this.recommendedPressureBar,
    required this.recommendedTread,
    required this.tractionScorePercent,
    required this.rollingResistanceWatts,
    required this.rimStrikeRiskPercent,
    required this.offCamberGripPercent,
    required this.isOptimalWindow,
    required this.statusLabel,
  });

  double get psi => selectedPressureBar * 14.5038;
  double get recommendedPsi => recommendedPressureBar * 14.5038;
}

/// Premie przenoszone bezpośrednio na karierę szosową (Wiosenne Klasyki).
class CyclocrossRoadCareerBonus {
  final int bikeHandlingGain;
  final int cobblesGain;
  final int watts1mGain;
  final int watts5mGain;
  final double ctlFitnessDelta;
  final double atlFatigueDelta;
  final int uciPointsEarned;

  const CyclocrossRoadCareerBonus({
    required this.bikeHandlingGain,
    required this.cobblesGain,
    required this.watts1mGain,
    required this.watts5mGain,
    required this.ctlFitnessDelta,
    required this.atlFatigueDelta,
    required this.uciPointsEarned,
  });

  /// Aplikuje zdobyte premie przełajowe do modelu kolarza szosowego.
  Rider applyToRider(Rider rider) {
    final nextSkills = rider.skills.copyWith(
      bikeHandling: (rider.skills.bikeHandling + bikeHandlingGain).clamp(1, 99),
      cobbles: (rider.skills.cobbles + cobblesGain).clamp(1, 99),
    );
    final nextPower = rider.powerProfile.copyWith(
      watts1m: rider.powerProfile.watts1m + watts1mGain,
      watts5m: rider.powerProfile.watts5m + watts5mGain,
    );
    final nextHealth = rider.health.copyWith(
      chronicTrainingLoad:
          (rider.health.chronicTrainingLoad + ctlFitnessDelta).clamp(0.0, 120.0),
      acuteTrainingLoad:
          (rider.health.acuteTrainingLoad + atlFatigueDelta).clamp(0.0, 130.0),
    );
    return rider.copyWith(
      skills: nextSkills,
      powerProfile: nextPower,
      health: nextHealth,
      careerPointsUci: rider.careerPointsUci + uciPointsEarned,
    );
  }
}

/// Wynik ukończonego wyścigu przełajowego.
class CyclocrossRaceResult {
  final String raceId;
  final String raceName;
  final String riderId;
  final String riderName;
  final int placement;
  final int totalTimeSeconds;
  final int pitSwapsCount;
  final int bunnyHopsSucceeded;
  final bool rimStrikeIncident;
  final double pressureBarUsed;
  final CyclocrossTubularTread treadUsed;
  final CyclocrossRoadCareerBonus careerBonus;

  const CyclocrossRaceResult({
    required this.raceId,
    required this.raceName,
    required this.riderId,
    required this.riderName,
    required this.placement,
    required this.totalTimeSeconds,
    required this.pitSwapsCount,
    required this.bunnyHopsSucceeded,
    required this.rimStrikeIncident,
    required this.pressureBarUsed,
    required this.treadUsed,
    required this.careerBonus,
  });

  bool get isPodium => placement <= 3;

  String get formattedTime {
    final hours = totalTimeSeconds ~/ 3600;
    final mins = (totalTimeSeconds % 3600) ~/ 60;
    final secs = totalTimeSeconds % 60;
    if (hours > 0) {
      return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Katalog 8 kultowych wyścigów Zimowego Pucharu Przełajowego (listopad–styczeń).
class CyclocrossWinterCalendarCatalog {
  CyclocrossWinterCalendarCatalog._();

  static List<CyclocrossRaceEntry> build8IconicRaces() {
    return [
      CyclocrossRaceEntry(
        id: 'cx_01_koppenberg',
        roundNumber: 1,
        name: 'Koppenbergcross',
        location: 'Oudenaarde, BEL',
        dateLabel: '1 Listopada',
        tier: CyclocrossRaceTier.superprestige,
        signatureFeature: 'Bruk Koppenbergu 22% i śliskie gliniaste błoto',
        course: _buildCourse(
          id: 'cx_01_koppenberg',
          name: 'Koppenbergcross',
          countryCode: 'BEL',
          month: CyclocrossMonth.november,
          lapLengthKm: 2.65,
          targetLaps: 8,
          airTempC: 7.0,
          precipMmH: 1.8,
          mudCondition: CyclocrossMudCondition.tackyLoam,
          mudShare: 0.24,
          sandShare: 0.0,
          offCamberShare: 0.14,
          planksCount: 2,
          stairsCount: 18,
          frostModifier: 0.96,
        ),
      ),
      CyclocrossRaceEntry(
        id: 'cx_02_koksijde',
        roundNumber: 2,
        name: 'Koksijde Duinencross',
        location: 'Koksijde, BEL',
        dateLabel: '18 Listopada',
        tier: CyclocrossRaceTier.worldCup,
        signatureFeature: 'Głębokie wydmy piaskowe nad Morzem Północnym',
        course: _buildCourse(
          id: 'cx_02_koksijde',
          name: 'Koksijde Duinencross',
          countryCode: 'BEL',
          month: CyclocrossMonth.november,
          lapLengthKm: 2.95,
          targetLaps: 8,
          airTempC: 6.0,
          precipMmH: 0.6,
          mudCondition: CyclocrossMudCondition.tackyLoam,
          mudShare: 0.08,
          sandShare: 0.34,
          offCamberShare: 0.10,
          planksCount: 2,
          stairsCount: 22,
          frostModifier: 0.98,
        ),
      ),
      CyclocrossRaceEntry(
        id: 'cx_03_namur',
        roundNumber: 3,
        name: 'Namur Citadelle Cross',
        location: 'Namur, BEL',
        dateLabel: '8 Grudnia',
        tier: CyclocrossRaceTier.worldCup,
        signatureFeature: 'Ekstremalne trawersy off-camber wokół Cytadeli',
        course: _buildCourse(
          id: 'cx_03_namur',
          name: 'Namur Citadelle Cross',
          countryCode: 'BEL',
          month: CyclocrossMonth.december,
          lapLengthKm: 2.80,
          targetLaps: 8,
          airTempC: 3.0,
          precipMmH: 2.4,
          mudCondition: CyclocrossMudCondition.heavyMud,
          mudShare: 0.26,
          sandShare: 0.0,
          offCamberShare: 0.22,
          planksCount: 2,
          stairsCount: 26,
          frostModifier: 0.90,
        ),
      ),
      CyclocrossRaceEntry(
        id: 'cx_04_gavere',
        roundNumber: 4,
        name: 'Gavere Muddy Castle CX',
        location: 'Gavere, BEL',
        dateLabel: '16 Grudnia',
        tier: CyclocrossRaceTier.worldCup,
        signatureFeature: 'Ciężkie flamandzkie błoto i podjazd pod zamek',
        course: CyclocrossCourseAndMudModel.createFlandersMudClassic(),
      ),
      CyclocrossRaceEntry(
        id: 'cx_05_zonhoven',
        roundNumber: 5,
        name: 'Zonhoven De Kuil',
        location: 'Zonhoven, BEL',
        dateLabel: '23 Grudnia',
        tier: CyclocrossRaceTier.superprestige,
        signatureFeature: 'Kultowy zjazd w piaszczystą nieckę „Kocioł”',
        course: _buildCourse(
          id: 'cx_05_zonhoven',
          name: 'Zonhoven De Kuil',
          countryCode: 'BEL',
          month: CyclocrossMonth.december,
          lapLengthKm: 2.90,
          targetLaps: 8,
          airTempC: 4.5,
          precipMmH: 1.0,
          mudCondition: CyclocrossMudCondition.tackyLoam,
          mudShare: 0.12,
          sandShare: 0.28,
          offCamberShare: 0.12,
          planksCount: 2,
          stairsCount: 16,
          frostModifier: 0.95,
        ),
      ),
      CyclocrossRaceEntry(
        id: 'cx_06_diegem',
        roundNumber: 6,
        name: 'Diegem Night Cross',
        location: 'Diegem, BEL',
        dateLabel: '29 Grudnia',
        tier: CyclocrossRaceTier.superprestige,
        signatureFeature: 'Nocny wyścig przy jupiterach i szybkie belki',
        course: _buildCourse(
          id: 'cx_06_diegem',
          name: 'Diegem Night Cross',
          countryCode: 'BEL',
          month: CyclocrossMonth.december,
          lapLengthKm: 2.60,
          targetLaps: 9,
          airTempC: -1.0,
          precipMmH: 0.2,
          mudCondition: CyclocrossMudCondition.frozenHard,
          mudShare: 0.08,
          sandShare: 0.10,
          offCamberShare: 0.08,
          planksCount: 2,
          stairsCount: 20,
          frostModifier: 0.84,
        ),
      ),
      CyclocrossRaceEntry(
        id: 'cx_07_hoogerheide',
        roundNumber: 7,
        name: 'GP Adrie van der Poel',
        location: 'Hoogerheide, NED',
        dateLabel: '19 Stycznia',
        tier: CyclocrossRaceTier.worldCup,
        signatureFeature: 'Próba generalna przed MŚ, długie schody i błoto',
        course: _buildCourse(
          id: 'cx_07_hoogerheide',
          name: 'GP Adrie van der Poel',
          countryCode: 'NED',
          month: CyclocrossMonth.january,
          lapLengthKm: 3.05,
          targetLaps: 8,
          airTempC: 2.0,
          precipMmH: 3.1,
          mudCondition: CyclocrossMudCondition.boggySwamp,
          mudShare: 0.30,
          sandShare: 0.06,
          offCamberShare: 0.14,
          planksCount: 2,
          stairsCount: 30,
          frostModifier: 0.89,
        ),
      ),
      CyclocrossRaceEntry(
        id: 'cx_08_worlds',
        roundNumber: 8,
        name: 'Mistrzostwa Świata CX UCI',
        location: 'Tabor / Hoogerheide',
        dateLabel: '31 Stycznia',
        tier: CyclocrossRaceTier.worldChampionships,
        signatureFeature:
            'Finał sezonu o Tęczową Koszulkę UCI • Podwójna premia na klasyki',
        course: _buildCourse(
          id: 'cx_08_worlds',
          name: 'Mistrzostwa Świata CX UCI',
          countryCode: 'NED',
          month: CyclocrossMonth.january,
          lapLengthKm: 3.10,
          targetLaps: 9,
          airTempC: 1.5,
          precipMmH: 2.5,
          mudCondition: CyclocrossMudCondition.heavyMud,
          mudShare: 0.25,
          sandShare: 0.12,
          offCamberShare: 0.16,
          planksCount: 2,
          stairsCount: 28,
          frostModifier: 0.88,
        ),
      ),
    ];
  }

  static CyclocrossCourseAndMudModel _buildCourse({
    required String id,
    required String name,
    required String countryCode,
    required CyclocrossMonth month,
    required double lapLengthKm,
    required int targetLaps,
    required double airTempC,
    required double precipMmH,
    required CyclocrossMudCondition mudCondition,
    required double mudShare,
    required double sandShare,
    required double offCamberShare,
    required int planksCount,
    required int stairsCount,
    required double frostModifier,
  }) {
    final totalMeters = lapLengthKm * 1000.0;
    const startLen = 260.0;
    const pitLen = 75.0;
    const planksLen = 45.0;
    const stairsLen = 55.0;
    final mudLen = totalMeters * mudShare;
    final sandLen = totalMeters * sandShare;
    final camberLen = totalMeters * offCamberShare;
    final fixedLen = startLen +
        pitLen * 2 +
        planksLen +
        stairsLen +
        mudLen +
        sandLen +
        camberLen;
    final remaining = math.max(200.0, totalMeters - fixedLen);
    final grassLen = remaining * 0.6;
    final woodLen = remaining * 0.4;

    double cursor = 0.0;
    final segments = <CyclocrossCourseSegment>[];
    int idx = 0;

    void addSeg(
      double len,
      CyclocrossTerrainType type, {
      double gradient = 0.0,
      double camber = 0.0,
      double mudDepth = 0.0,
      double sandDepth = 0.0,
      int planks = 0,
      int stairs = 0,
    }) {
      if (len <= 0.0) return;
      segments.add(
        CyclocrossCourseSegment(
          index: idx++,
          startMeter: cursor,
          lengthMeters: len,
          terrainType: type,
          gradientPercent: gradient,
          camberAngleDegrees: camber,
          mudDepthCm: mudDepth,
          mudViscosityIndex: mudDepth > 0 ? 0.78 : 0.0,
          sandDepthCm: sandDepth,
          plankCount: planks,
          plankHeightCm: 40.0,
          stairStepCount: stairs,
          isBunnyHoppable: type == CyclocrossTerrainType.planks,
          runningSpeedPenaltyFactor: type == CyclocrossTerrainType.staircaseRunUp
              ? 0.46
              : (type == CyclocrossTerrainType.sandPit ? 0.56 : 0.70),
        ),
      );
      cursor += len;
    }

    addSeg(startLen, CyclocrossTerrainType.pavedStartFinish, gradient: 1.5);
    addSeg(grassLen * 0.55, CyclocrossTerrainType.meadowGrass, gradient: 3.5);
    addSeg(
      mudLen,
      CyclocrossTerrainType.deepMud,
      gradient: 2.0,
      mudDepth: mudCondition == CyclocrossMudCondition.boggySwamp ? 17.0 : 12.0,
    );
    addSeg(
      camberLen,
      CyclocrossTerrainType.offCamberSlope,
      gradient: -4.5,
      camber: 24.0,
    );
    addSeg(pitLen, CyclocrossTerrainType.doublePitLane);
    addSeg(sandLen, CyclocrossTerrainType.sandPit, sandDepth: 21.0);
    addSeg(planksLen, CyclocrossTerrainType.planks, planks: planksCount);
    addSeg(
      stairsLen,
      CyclocrossTerrainType.staircaseRunUp,
      gradient: 21.0,
      stairs: stairsCount,
    );
    addSeg(
      woodLen,
      CyclocrossTerrainType.woodlandSingletrack,
      gradient: -2.5,
    );
    addSeg(pitLen, CyclocrossTerrainType.doublePitLane);
    addSeg(grassLen * 0.45, CyclocrossTerrainType.meadowGrass, gradient: -1.5);

    return CyclocrossCourseAndMudModel(
      id: id,
      name: name,
      countryCode: countryCode,
      raceMonth: month,
      lapLengthKm: lapLengthKm,
      targetLaps: targetLaps,
      startFinishStraightMeters: startLen,
      segments: segments,
      doublePitLane: DoublePitLaneConfig(
        firstAccessStartMeter:
            startLen + grassLen * 0.55 + mudLen + camberLen,
        firstAccessLengthMeters: pitLen,
        secondAccessStartMeter: totalMeters - grassLen * 0.45 - pitLen,
        secondAccessLengthMeters: pitLen,
        isBidirectional: true,
        pitSide: CyclocrossPitLaneSide.centerIsland,
        teamPitBoxesCount: 28,
        bikeSwapBaseTimeSeconds: 4.5,
        pressureWashEfficiency: 0.92,
      ),
      weatherAndMudState: CyclocrossWeatherAndMudState(
        month: month,
        airTemperatureCelsius: airTempC,
        precipitationMmPerHour: precipMmH,
        mudCondition: mudCondition,
        mudAccumulationRateKgPerLap:
            mudCondition == CyclocrossMudCondition.frozenHard ? 0.15 : 0.68,
        frostGripModifier: frostModifier,
      ),
    );
  }
}

/// Kalkulator fizyki przełajowej, doboru ciśnienia (1.30–1.80 bar) i integracji z karierą szosową.
class CyclocrossPhysicsAdvisor {
  CyclocrossPhysicsAdvisor._();

  static const double minPressureBar = 1.30;
  static const double maxPressureBar = 1.80;

  static CyclocrossTirePressureAnalysis analyzeTirePressure({
    required CyclocrossCourseAndMudModel course,
    required double pressureBar,
    required CyclocrossTubularTread tread,
    required double riderWeightKg,
  }) {
    final clampedPressure = pressureBar.clamp(minPressureBar, maxPressureBar);
    final mud = course.weatherAndMudState.mudCondition;

    double baseRec = switch (mud) {
      CyclocrossMudCondition.boggySwamp => 1.36,
      CyclocrossMudCondition.heavyMud => 1.44,
      CyclocrossMudCondition.tackyLoam => 1.54,
      CyclocrossMudCondition.frozenHard => 1.66,
    };

    if (course.sandRatio >= 0.22) {
      baseRec -= 0.08;
    }
    // Cięższy kolarz wymaga nieco wyższego ciśnienia, aby uniknąć dobicia obręczy.
    final weightDelta = ((riderWeightKg - 70.0) / 10.0) * 0.04;
    final recommendedBar =
        (baseRec + weightDelta).clamp(minPressureBar, maxPressureBar);

    final recommendedTread = _recommendTread(course);
    final pressureDiff = clampedPressure - recommendedBar;
    final absDiff = pressureDiff.abs();

    final treadMatchBonus = tread == recommendedTread ? 8.0 : 0.0;
    final traction = (94.0 - absDiff * 135.0 + treadMatchBonus -
            (pressureDiff > 0 ? pressureDiff * 35.0 : 0.0))
        .clamp(38.0, 99.0);

    final offCamberGrip = (92.0 -
            (pressureDiff > 0 ? pressureDiff * 165.0 : absDiff * 60.0) +
            treadMatchBonus * 0.6)
        .clamp(35.0, 99.0);

    final underPressure = math.max(0.0, recommendedBar - clampedPressure);
    final rimStrikeRisk = (6.0 +
            underPressure * 290.0 +
            (riderWeightKg > 76 ? 6.0 : 0.0))
        .clamp(2.0, 88.0);

    final rollingWatts = (32.0 +
            course.mudRatio * 28.0 +
            course.sandRatio * 24.0 +
            (maxPressureBar - clampedPressure) * 16.0)
        .clamp(22.0, 78.0);

    final isOptimal = absDiff <= 0.06 && rimStrikeRisk < 28.0;
    final String statusLabel;
    if (isOptimal) {
      statusLabel = 'Okno optymalne — maksymalna trakcja';
    } else if (pressureDiff < -0.06) {
      statusLabel = 'Za niskie ciśnienie — wysokie ryzyko dobicia obręczy';
    } else {
      statusLabel = 'Za wysokie ciśnienie — utrata przyczepności w błocie';
    }

    return CyclocrossTirePressureAnalysis(
      selectedPressureBar: clampedPressure,
      recommendedPressureBar: double.parse(recommendedBar.toStringAsFixed(2)),
      recommendedTread: recommendedTread,
      tractionScorePercent: traction,
      rollingResistanceWatts: rollingWatts,
      rimStrikeRiskPercent: rimStrikeRisk,
      offCamberGripPercent: offCamberGrip,
      isOptimalWindow: isOptimal,
      statusLabel: statusLabel,
    );
  }

  static CyclocrossTubularTread _recommendTread(
    CyclocrossCourseAndMudModel course,
  ) {
    if (course.weatherAndMudState.mudCondition ==
        CyclocrossMudCondition.frozenHard) {
      return CyclocrossTubularTread.iceSpike;
    }
    if (course.sandRatio >= 0.22) {
      return CyclocrossTubularTread.sandFile;
    }
    if (course.weatherAndMudState.mudCondition ==
            CyclocrossMudCondition.heavyMud ||
        course.weatherAndMudState.mudCondition ==
            CyclocrossMudCondition.boggySwamp) {
      return CyclocrossTubularTread.mudAggressive;
    }
    return CyclocrossTubularTread.allRounder;
  }

  /// Oblicza prognozowaną premię do kariery szosowej na podstawie rangi wyścigu i wyniku.
  static CyclocrossRoadCareerBonus computeRoadCareerBonus({
    required CyclocrossRaceEntry race,
    required int placement,
    required CyclocrossTirePressureAnalysis pressureAnalysis,
  }) {
    final mult = race.tier.careerBonusMultiplier;
    final podiumFactor = placement <= 3
        ? 1.35
        : (placement <= 10 ? 1.15 : 1.0);
    final setupFactor = pressureAnalysis.isOptimalWindow ? 1.15 : 1.0;

    final handlingGain =
        math.max(1, (1.4 * mult * podiumFactor).round()).clamp(1, 4);
    final cobblesGain =
        math.max(1, (1.2 * mult * podiumFactor * setupFactor).round()).clamp(1, 4);
    final w1mGain =
        math.max(4, (6.0 * mult * podiumFactor).round()).clamp(4, 22);
    final w5mGain =
        math.max(3, (4.5 * mult * podiumFactor).round()).clamp(3, 16);

    final placementPointsFactor =
        math.max(0.15, (25 - math.min(placement, 24)) / 24.0);
    final uciPts = (race.tier.baseUciPoints * placementPointsFactor).round();

    return CyclocrossRoadCareerBonus(
      bikeHandlingGain: handlingGain,
      cobblesGain: cobblesGain,
      watts1mGain: w1mGain,
      watts5mGain: w5mGain,
      ctlFitnessDelta: double.parse((1.6 * mult).toStringAsFixed(1)),
      atlFatigueDelta: double.parse((3.8 * mult).toStringAsFixed(1)),
      uciPointsEarned: uciPts,
    );
  }

  /// Symuluje start zimowy w przełaju dla wybranego kolarza szosowego.
  static CyclocrossRaceResult simulateWinterRace({
    required CyclocrossRaceEntry race,
    required Rider rider,
    required double pressureBar,
    required CyclocrossTubularTread tread,
    int seed = 42,
  }) {
    final analysis = analyzeTirePressure(
      course: race.course,
      pressureBar: pressureBar,
      tread: tread,
      riderWeightKg: rider.physiology.weightKg,
    );

    final rng = math.Random(seed ^ race.id.hashCode ^ rider.id.hashCode);
    final w1mPerKg = rider.powerProfile.watts1m / rider.physiology.weightKg;
    final w5mPerKg = rider.powerProfile.watts5m / rider.physiology.weightKg;

    final techScore = rider.skills.bikeHandling * 0.48 +
        rider.skills.cobbles * 0.30 +
        rider.skills.raceIq * 0.22;
    final powerScore = w1mPerKg * 5.2 + w5mPerKg * 7.8;
    final setupScore =
        analysis.tractionScorePercent * 0.24 - analysis.rimStrikeRiskPercent * 0.16;

    final rimStrikeIncident =
        rng.nextDouble() * 100.0 < (analysis.rimStrikeRiskPercent * 0.45);
    final incidentPenalty = rimStrikeIncident ? 14.0 : 0.0;
    final variance = (rng.nextDouble() - 0.5) * 8.0;

    final totalScore = techScore + powerScore + setupScore - incidentPenalty + variance;
    // Skala wyniku na miejsce 1..32
    final rawPlacement = (34.0 - (totalScore - 85.0) * 0.34).round();
    final placement = rawPlacement.clamp(1, 32);

    final baseDuration = (race.course.totalRaceDistanceKm / 24.5 * 3600.0).round();
    final totalTimeSeconds =
        baseDuration + (placement - 1) * 9 + (rimStrikeIncident ? 28 : 0);

    final pitSwaps = race.course.weatherAndMudState.mudCondition ==
            CyclocrossMudCondition.frozenHard
        ? 1
        : (race.course.targetLaps ~/ 2);
    final bunnyHops = rider.skills.bikeHandling >= 85
        ? race.course.targetLaps
        : (rider.skills.bikeHandling >= 72 ? (race.course.targetLaps ~/ 2) : 0);

    final bonus = computeRoadCareerBonus(
      race: race,
      placement: placement,
      pressureAnalysis: analysis,
    );

    return CyclocrossRaceResult(
      raceId: race.id,
      raceName: race.name,
      riderId: rider.id,
      riderName: rider.fullName,
      placement: placement,
      totalTimeSeconds: totalTimeSeconds,
      pitSwapsCount: pitSwaps,
      bunnyHopsSucceeded: bunnyHops,
      rimStrikeIncident: rimStrikeIncident,
      pressureBarUsed: analysis.selectedPressureBar,
      treadUsed: tread,
      careerBonus: bonus,
    );
  }
}

/// Ekran Zimowego Pucharu Przełajowego (`CyclocrossWinterSeriesScreen`, listopad–styczeń).
class CyclocrossWinterSeriesScreen extends StatefulWidget {
  final List<Rider>? initialRoster;
  final ValueChanged<Rider>? onRiderUpdated;
  final ValueChanged<CyclocrossRaceEntry>? onLaunch3dCourse;
  final VoidCallback? onBack;

  const CyclocrossWinterSeriesScreen({
    super.key,
    this.initialRoster,
    this.onRiderUpdated,
    this.onLaunch3dCourse,
    this.onBack,
  });

  @override
  State<CyclocrossWinterSeriesScreen> createState() =>
      _CyclocrossWinterSeriesScreenState();
}

class _CyclocrossWinterSeriesScreenState
    extends State<CyclocrossWinterSeriesScreen> {
  late final List<CyclocrossRaceEntry> _races;
  late List<Rider> _roster;
  late String _selectedRiderId;
  late String _selectedRaceId;
  CyclocrossMonth? _monthFilter;
  double _selectedPressureBar = 1.48;
  CyclocrossTubularTread _selectedTread = CyclocrossTubularTread.mudAggressive;
  final Map<String, CyclocrossRaceResult> _completedResults = {};
  final List<CyclocrossRoadCareerBonus> _appliedBonuses = [];
  CyclocrossRaceResult? _latestResult;

  @override
  void initState() {
    super.initState();
    _races = CyclocrossWinterCalendarCatalog.build8IconicRaces();
    _roster = List<Rider>.from(
      widget.initialRoster != null && widget.initialRoster!.isNotEmpty
          ? widget.initialRoster!
          : _buildDefaultRoadRoster(),
    );
    _selectedRiderId = _roster.first.id;
    _selectedRaceId = _races.first.id;
    _syncOptimalSetupForSelectedRace();
  }

  Rider get _selectedRider => _roster.firstWhere(
        (r) => r.id == _selectedRiderId,
        orElse: () => _roster.first,
      );

  CyclocrossRaceEntry get _selectedRace => _races.firstWhere(
        (r) => r.id == _selectedRaceId,
        orElse: () => _races.first,
      );

  List<CyclocrossRaceEntry> get _filteredRaces {
    if (_monthFilter == null) return _races;
    return _races
        .where((r) => r.course.raceMonth == _monthFilter)
        .toList(growable: false);
  }

  String _completionKey(String raceId, String riderId) => '$raceId::$riderId';

  bool get _isSelectedRaceCompletedForRider => _completedResults.containsKey(
        _completionKey(_selectedRace.id, _selectedRider.id),
      );

  void _syncOptimalSetupForSelectedRace() {
    final analysis = CyclocrossPhysicsAdvisor.analyzeTirePressure(
      course: _selectedRace.course,
      pressureBar: _selectedPressureBar,
      tread: _selectedTread,
      riderWeightKg: _selectedRider.physiology.weightKg,
    );
    _selectedPressureBar = analysis.recommendedPressureBar;
    _selectedTread = analysis.recommendedTread;
  }

  void _applyOptimalPressure() {
    setState(() {
      _syncOptimalSetupForSelectedRace();
    });
  }

  void _adjustPressure(double delta) {
    setState(() {
      _selectedPressureBar = double.parse(
        (_selectedPressureBar + delta)
            .clamp(
              CyclocrossPhysicsAdvisor.minPressureBar,
              CyclocrossPhysicsAdvisor.maxPressureBar,
            )
            .toStringAsFixed(2),
      );
    });
  }

  void _runWinterStart() {
    final rider = _selectedRider;
    final race = _selectedRace;
    if (rider.health.currentInjury != null &&
        !rider.health.currentInjury!.trainingAllowed) {
      return;
    }
    if (_isSelectedRaceCompletedForRider) return;

    final result = CyclocrossPhysicsAdvisor.simulateWinterRace(
      race: race,
      rider: rider,
      pressureBar: _selectedPressureBar,
      tread: _selectedTread,
      seed: _completedResults.length + 101,
    );

    final updatedRider = result.careerBonus.applyToRider(rider);
    final idx = _roster.indexWhere((r) => r.id == rider.id);
    if (idx != -1) {
      _roster[idx] = updatedRider;
    }
    widget.onRiderUpdated?.call(updatedRider);

    setState(() {
      _completedResults[_completionKey(race.id, rider.id)] = result;
      _appliedBonuses.add(result.careerBonus);
      _latestResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysis = CyclocrossPhysicsAdvisor.analyzeTirePressure(
      course: _selectedRace.course,
      pressureBar: _selectedPressureBar,
      tread: _selectedTread,
      riderWeightKg: _selectedRider.physiology.weightKg,
    );
    final projectedBonus = CyclocrossPhysicsAdvisor.computeRoadCareerBonus(
      race: _selectedRace,
      placement: 3,
      pressureAnalysis: analysis,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1150;
            final isTablet = width >= 740 && width < 1150;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopHeader(width),
                _buildRiderAndFilterStrip(width),
                Expanded(
                  child: isDesktop
                      ? _buildDesktopBento(analysis, projectedBonus)
                      : isTablet
                          ? _buildTabletLayout(analysis, projectedBonus)
                          : _buildMobileLayout(analysis, projectedBonus),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader(double width) {
    final isCompact = width < 720;
    final totalHandlingGain = _appliedBonuses.fold<int>(
      0,
      (sum, b) => sum + b.bikeHandlingGain,
    );
    final totalCobblesGain = _appliedBonuses.fold<int>(
      0,
      (sum, b) => sum + b.cobblesGain,
    );
    final wonWorlds = _completedResults.values.any(
      (r) => r.raceId == 'cx_08_worlds' && r.placement == 1,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 24,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: isCompact ? width - 28 : null,
            child: Row(
              mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (widget.onBack != null || Navigator.of(context).canPop())
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _InteractiveActionButton(
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                      icon: Icons.arrow_back_rounded,
                      label: isCompact ? '' : 'Powrót',
                      isCompact: isCompact,
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryAccent),
                  ),
                  child: const Icon(
                    Icons.terrain_rounded,
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
                        'Zimowy Puchar Przełajowy (CX)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompact ? 17 : 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Listopad – Styczeń • 8 rund • Premie na Wiosenne Klasyki',
                        style: TextStyle(
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
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderStatPill(
                label: 'Starty CX',
                value: '${_completedResults.length}/8',
                accent: AppColors.accentBlue,
              ),
              _HeaderStatPill(
                label: 'Handling / Bruk',
                value: '+$totalHandlingGain / +$totalCobblesGain',
                accent: AppColors.statusSuccess,
              ),
              if (wonWorlds)
                const _HeaderStatPill(
                  label: 'Tytuł UCI',
                  value: 'Mistrz Świata CX',
                  accent: AppColors.goldAccent,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiderAndFilterStrip(double width) {
    final isCompact = width < 720;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 24,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Wybór kolarza szosowego
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kolarz:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                ..._roster.map((rider) {
                  final selected = rider.id == _selectedRider.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _InteractiveChip(
                      selected: selected,
                      label:
                          '${rider.fullName} (H:${rider.skills.bikeHandling} • C:${rider.skills.cobbles})',
                      onTap: () {
                        setState(() {
                          _selectedRiderId = rider.id;
                          _syncOptimalSetupForSelectedRace();
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          // Filtr miesięcy listopad–styczeń
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InteractiveChip(
                  selected: _monthFilter == null,
                  label: 'Wszystkie (8)',
                  onTap: () => setState(() => _monthFilter = null),
                ),
                const SizedBox(width: 6),
                ...CyclocrossMonth.values.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _InteractiveChip(
                      selected: _monthFilter == m,
                      label: m.displayNamePl,
                      onTap: () => setState(() => _monthFilter = m),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBento(
    CyclocrossTirePressureAnalysis analysis,
    CyclocrossRoadCareerBonus projectedBonus,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _buildCalendarPanel(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCourseTelemetryCard(),
                  const SizedBox(height: 16),
                  _buildTirePressureCard(analysis),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: _buildRoadCareerIntegrationCard(analysis, projectedBonus),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    CyclocrossTirePressureAnalysis analysis,
    CyclocrossRoadCareerBonus projectedBonus,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _buildCalendarPanel(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCourseTelemetryCard(),
                  const SizedBox(height: 14),
                  _buildTirePressureCard(analysis),
                  const SizedBox(height: 14),
                  _buildRoadCareerIntegrationCard(analysis, projectedBonus),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    CyclocrossTirePressureAnalysis analysis,
    CyclocrossRoadCareerBonus projectedBonus,
  ) {
    final races = _filteredRaces;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Kalendarz Przełajowy (${races.length} rund)',
            icon: Icons.calendar_month_rounded,
            child: Column(
              children: races.map(_buildRaceListTile).toList(growable: false),
            ),
          ),
          const SizedBox(height: 14),
          _buildCourseTelemetryCard(),
          const SizedBox(height: 14),
          _buildTirePressureCard(analysis),
          const SizedBox(height: 14),
          _buildRoadCareerIntegrationCard(analysis, projectedBonus),
        ],
      ),
    );
  }

  Widget _buildCalendarPanel() {
    final races = _filteredRaces;
    return _SectionCard(
      title: 'Kalendarz Przełajowy (${races.length})',
      icon: Icons.calendar_month_rounded,
      expandChild: true,
      child: ListView.separated(
        itemCount: races.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildRaceListTile(races[index]),
      ),
    );
  }

  Widget _buildRaceListTile(CyclocrossRaceEntry race) {
    final isSelected = race.id == _selectedRace.id;
    final completed =
        _completedResults[_completionKey(race.id, _selectedRider.id)];
    final borderColor = race.isWorldChampionship
        ? AppColors.goldAccent
        : (isSelected ? AppColors.primaryAccent : AppTheme.borderColor);

    return _HoverableCard(
      selected: isSelected,
      borderColor: borderColor,
      onTap: () {
        setState(() {
          _selectedRaceId = race.id;
          _syncOptimalSetupForSelectedRace();
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: race.isWorldChampionship
                        ? AppColors.goldAccent.withValues(alpha: 0.18)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: race.isWorldChampionship
                          ? AppColors.goldAccent
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    '#${race.roundNumber} • ${race.course.raceMonth.shortCode}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: race.isWorldChampionship
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    race.tier.labelPl,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: race.isWorldChampionship
                          ? AppColors.goldAccent
                          : AppColors.accentBlue,
                    ),
                  ),
                ),
                if (completed != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccess.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.statusSuccess),
                    ),
                    child: Text(
                      'P${completed.placement}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusSuccess,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              race.name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${race.dateLabel} • ${race.location} • ${race.course.lapLengthKm.toStringAsFixed(2)} km × ${race.course.targetLaps} rund',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              race.signatureFeature,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseTelemetryCard() {
    final race = _selectedRace;
    final course = race.course;
    final mudPercent = (course.mudRatio * 100).round();
    final sandPercent = (course.sandRatio * 100).round();
    final temp = course.weatherAndMudState.airTemperatureCelsius;

    return _SectionCard(
      title: 'Profil Rundy: ${race.name}',
      icon: Icons.route_rounded,
      accentBorder:
          race.isWorldChampionship ? AppColors.goldAccent : AppTheme.borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 76,
            child: CustomPaint(
              painter: _CyclocrossLapProfilePainter(course: course),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTelemetryTag(
                label: 'Dystans',
                value: '${course.totalRaceDistanceKm.toStringAsFixed(1)} km',
              ),
              _MiniTelemetryTag(
                label: 'Błoto',
                value: '$mudPercent%',
              ),
              _MiniTelemetryTag(
                label: 'Piasek',
                value: '$sandPercent%',
              ),
              _MiniTelemetryTag(
                label: 'Schody / Belki',
                value:
                    '${course.totalStairStepsCount} st. / ${course.totalPlankObstaclesCount}×40cm',
              ),
              _MiniTelemetryTag(
                label: 'Pogoda',
                value: '${temp.toStringAsFixed(1)}°C',
              ),
              _MiniTelemetryTag(
                label: 'Trudność',
                value: '${course.technicalDifficultyScore.round()}/100',
              ),
            ],
          ),
          if (widget.onLaunch3dCourse != null) ...[
            const SizedBox(height: 12),
            _InteractiveActionButton(
              onPressed: () => widget.onLaunch3dCourse!(race),
              icon: Icons.view_in_ar_rounded,
              label: 'Podgląd Areny 3D CX',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTirePressureCard(CyclocrossTirePressureAnalysis analysis) {
    final statusColor = analysis.isOptimalWindow
        ? AppColors.statusSuccess
        : (analysis.rimStrikeRiskPercent >= 35.0
            ? AppColors.crimsonAlert
            : AppColors.amberWarning);

    return _SectionCard(
      title: 'Ciśnienie Szytek CX (1.30–1.80 bar)',
      icon: Icons.tire_repair_rounded,
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
                      '${_selectedPressureBar.toStringAsFixed(2)} bar',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${analysis.psi.toStringAsFixed(1)} PSI • Zalecane: ${analysis.recommendedPressureBar.toStringAsFixed(2)} bar',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _InteractiveActionButton(
                onPressed: _applyOptimalPressure,
                icon: Icons.auto_fix_high_rounded,
                label: 'Optymalne',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 28,
            child: CustomPaint(
              painter: _TirePressureGaugePainter(
                selectedBar: _selectedPressureBar,
                recommendedBar: analysis.recommendedPressureBar,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _InteractiveActionButton(
                onPressed: _selectedPressureBar >
                        CyclocrossPhysicsAdvisor.minPressureBar
                    ? () => _adjustPressure(-0.02)
                    : null,
                icon: Icons.remove_rounded,
                label: '-0.02',
                isCompact: true,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: statusColor,
                    inactiveTrackColor: AppColors.surfaceLight,
                    thumbColor: AppColors.goldAccent,
                    overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    min: CyclocrossPhysicsAdvisor.minPressureBar,
                    max: CyclocrossPhysicsAdvisor.maxPressureBar,
                    divisions: 50,
                    value: _selectedPressureBar,
                    onChanged: (value) {
                      setState(() {
                        _selectedPressureBar =
                            double.parse(value.toStringAsFixed(2));
                      });
                    },
                  ),
                ),
              ),
              _InteractiveActionButton(
                onPressed: _selectedPressureBar <
                        CyclocrossPhysicsAdvisor.maxPressureBar
                    ? () => _adjustPressure(0.02)
                    : null,
                icon: Icons.add_rounded,
                label: '+0.02',
                isCompact: true,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Icon(
                  analysis.isOptimalWindow
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    analysis.statusLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bieżnik szytki (33 mm UCI)',
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
            children: CyclocrossTubularTread.values.map((tread) {
              return _InteractiveChip(
                selected: _selectedTread == tread,
                label: tread.labelPl,
                onTap: () => setState(() => _selectedTread = tread),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTelemetryTag(
                label: 'Trakcja',
                value: '${analysis.tractionScorePercent.round()}%',
              ),
              _MiniTelemetryTag(
                label: 'Trawers',
                value: '${analysis.offCamberGripPercent.round()}%',
              ),
              _MiniTelemetryTag(
                label: 'Opór toczenia',
                value: '${analysis.rollingResistanceWatts.round()} W',
              ),
              _MiniTelemetryTag(
                label: 'Ryzyko dobicia',
                value: '${analysis.rimStrikeRiskPercent.round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoadCareerIntegrationCard(
    CyclocrossTirePressureAnalysis analysis,
    CyclocrossRoadCareerBonus projectedBonus,
  ) {
    final rider = _selectedRider;
    final race = _selectedRace;
    final injuredBlocked = rider.health.currentInjury != null &&
        !rider.health.currentInjury!.trainingAllowed;
    final alreadyRaced = _isSelectedRaceCompletedForRider;
    final canStart = !injuredBlocked && !alreadyRaced;

    return _SectionCard(
      title: 'Integracja z Karierą Szosową',
      icon: Icons.trending_up_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Starty zimowe podnoszą atrybuty na Wiosenne Klasyki (Flandria / Roubaix) dla ${rider.fullName}:',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _CareerGainRow(
            label: 'Technika / bikeHandling',
            currentValue: '${rider.skills.bikeHandling}',
            deltaValue: '+${projectedBonus.bikeHandlingGain}',
            accent: AppColors.accentBlue,
          ),
          const SizedBox(height: 8),
          _CareerGainRow(
            label: 'Jazda po bruku / cobbles',
            currentValue: '${rider.skills.cobbles}',
            deltaValue: '+${projectedBonus.cobblesGain}',
            accent: AppColors.goldAccent,
          ),
          const SizedBox(height: 8),
          _CareerGainRow(
            label: 'Moc 1 min (ataki na ściankach)',
            currentValue: '${rider.powerProfile.watts1m} W',
            deltaValue: '+${projectedBonus.watts1mGain} W',
            accent: AppColors.powerZone6,
          ),
          const SizedBox(height: 8),
          _CareerGainRow(
            label: 'Moc 5 min (VO2max / selekcja)',
            currentValue: '${rider.powerProfile.watts5m} W',
            deltaValue: '+${projectedBonus.watts5mGain} W',
            accent: AppColors.powerZone5,
          ),
          const SizedBox(height: 14),
          _InteractiveActionButton(
            onPressed: canStart ? _runWinterStart : null,
            icon: alreadyRaced
                ? Icons.verified_rounded
                : Icons.flag_circle_rounded,
            label: injuredBlocked
                ? 'Kolarz kontuzjowany (brak zgody)'
                : alreadyRaced
                    ? 'Start ukończony — premia dodana'
                    : 'Wystartuj w ${race.name}',
            isPrimary: true,
          ),
          if (_latestResult != null) ...[
            const SizedBox(height: 14),
            _buildLatestResultBanner(_latestResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildLatestResultBanner(CyclocrossRaceResult result) {
    final isWin = result.placement == 1;
    final accent = isWin
        ? AppColors.goldAccent
        : (result.isPodium ? AppColors.statusSuccess : AppColors.accentBlue);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isWin ? Icons.emoji_events_rounded : Icons.sports_score_rounded,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${result.raceName} • Miejsce #${result.placement}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              Text(
                result.formattedTime,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Zmiany roweru w boksie: ${result.pitSwapsCount} • Bunny-hopy nad belkami: ${result.bunnyHopsSucceeded} • Ciśnienie: ${result.pressureBarUsed.toStringAsFixed(2)} bar',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          if (result.rimStrikeIncident) ...[
            const SizedBox(height: 4),
            const Text(
              'Uwaga: dobicie obręczy na kamieniu/belce kosztowało ~28 s.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.amberWarning,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Zastosowano do kariery: +${result.careerBonus.bikeHandlingGain} bikeHandling, +${result.careerBonus.cobblesGain} cobbles, +${result.careerBonus.watts1mGain} W (1m), +${result.careerBonus.watts5mGain} W (5m), +${result.careerBonus.uciPointsEarned} pkt UCI',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.statusSuccess,
            ),
          ),
        ],
      ),
    );
  }

  List<Rider> _buildDefaultRoadRoster() {
    return [
      Rider(
        id: 'cx_rider_1',
        firstName: 'Mathieu',
        lastName: 'Vermeer',
        nationalityIso: 'NED',
        birthDate: DateTime(1996, 1, 19),
        potential: 96,
        specialization: RiderSpecialization.classicCobbles,
        physiology: const RiderPhysiology(
          heightCm: 184.0,
          weightKg: 74.0,
          bodyFatPercentage: 7.2,
          ftpWatts: 435,
          wPrimeJoules: 28500,
          vo2Max: 84.5,
          maxHr: 194,
          restingHr: 38,
          lactateThresholdHr: 176,
          recoveryRate: 1.18,
          glycogenCapacityGrams: 540.0,
        ),
        powerProfile: const RiderPowerProfile(
          watts5s: 1420,
          watts15s: 1140,
          watts30s: 910,
          watts1m: 745,
          watts3m: 560,
          watts5m: 510,
          watts20m: 455,
          watts60m: 435,
        ),
        skills: const RiderSkills(
          cobbles: 88,
          descending: 84,
          bikeHandling: 91,
          aeroPositioning: 83,
          draftingEfficiency: 82,
          raceIq: 87,
          rainResistance: 90,
          heatTolerance: 78,
          timeTrialPositioning: 80,
        ),
        appearance: const RiderAppearance(
          faceShapeIndex: 1,
          skinToneHex: '#F1C27D',
          hairStyleIndex: 2,
          hairColorHex: '#5A3825',
          facialHairIndex: 1,
          glassesModelId: 'aero_pro',
          glassesLensColorHex: '#D4AF37',
          helmetModelId: 'aero_road',
          shoeColorHex: '#FFFFFF',
          sockHeightProportion: 0.72,
          bodyBuildType: BodyBuildType.allRounder,
        ),
        contract: const RiderContract(
          teamId: 'player_team',
          role: RiderRole.teamLeader,
          monthlySalaryEur: 85000,
          signingBonusEur: 120000,
          winBonusEur: 25000,
          releaseClauseEur: 2500000,
          contractEndYear: 2028,
          morale: 86.0,
          leaderLoyalty: 90.0,
          requiredRacesIds: [],
        ),
        health: const RiderHealth(
          acuteTrainingLoad: 34.0,
          chronicTrainingLoad: 78.0,
        ),
        careerPointsUci: 1840,
      ),
      Rider(
        id: 'cx_rider_2',
        firstName: 'Kacper',
        lastName: 'Kowalski',
        nationalityIso: 'POL',
        birthDate: DateTime(2001, 5, 12),
        potential: 89,
        specialization: RiderSpecialization.puncher,
        physiology: const RiderPhysiology(
          heightCm: 178.0,
          weightKg: 67.0,
          bodyFatPercentage: 7.8,
          ftpWatts: 398,
          wPrimeJoules: 24000,
          vo2Max: 81.2,
          maxHr: 198,
          restingHr: 42,
          lactateThresholdHr: 179,
          recoveryRate: 1.10,
          glycogenCapacityGrams: 510.0,
        ),
        powerProfile: const RiderPowerProfile(
          watts5s: 1210,
          watts15s: 980,
          watts30s: 790,
          watts1m: 655,
          watts3m: 495,
          watts5m: 455,
          watts20m: 416,
          watts60m: 398,
        ),
        skills: const RiderSkills(
          cobbles: 74,
          descending: 78,
          bikeHandling: 77,
          aeroPositioning: 76,
          draftingEfficiency: 79,
          raceIq: 75,
          rainResistance: 76,
          heatTolerance: 74,
          timeTrialPositioning: 73,
        ),
        appearance: const RiderAppearance(
          faceShapeIndex: 0,
          skinToneHex: '#FFDBAC',
          hairStyleIndex: 1,
          hairColorHex: '#3B2F2F',
          facialHairIndex: 0,
          glassesModelId: 'sport_half',
          glassesLensColorHex: '#38BDF8',
          helmetModelId: 'vented_climb',
          shoeColorHex: '#181B22',
          sockHeightProportion: 0.68,
          bodyBuildType: BodyBuildType.climberLean,
        ),
        contract: const RiderContract(
          teamId: 'player_team',
          role: RiderRole.coLeader,
          monthlySalaryEur: 42000,
          signingBonusEur: 45000,
          winBonusEur: 12000,
          releaseClauseEur: 1200000,
          contractEndYear: 2027,
          morale: 82.0,
          leaderLoyalty: 88.0,
          requiredRacesIds: [],
        ),
        health: const RiderHealth(
          acuteTrainingLoad: 28.0,
          chronicTrainingLoad: 72.0,
        ),
        careerPointsUci: 920,
      ),
    ];
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color accentBorder;
  final bool expandChild;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accentBorder = AppTheme.borderColor,
    this.expandChild = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

class _HeaderStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _HeaderStatPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTelemetryTag extends StatelessWidget {
  final String label;
  final String value;

  const _MiniTelemetryTag({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
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
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerGainRow extends StatelessWidget {
  final String label;
  final String currentValue;
  final String deltaValue;
  final Color accent;

  const _CareerGainRow({
    required this.label,
    required this.currentValue,
    required this.deltaValue,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
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
          Text(
            currentValue,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withValues(alpha: 0.6)),
            ),
            child: Text(
              deltaValue,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveChip extends StatefulWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _InteractiveChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.primaryAccent : AppTheme.borderColor));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent.withValues(alpha: 0.25)
                : (_hovered ? AppColors.surfaceLight : AppColors.surface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverableCard extends StatefulWidget {
  final bool selected;
  final Color borderColor;
  final VoidCallback onTap;
  final Widget child;

  const _HoverableCard({
    required this.selected,
    required this.borderColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<_HoverableCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = _focused
        ? AppColors.accentBlue
        : (widget.selected || _hovered
            ? widget.borderColor
            : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.surfaceLight
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.7)
                    : AppColors.background),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: effectiveBorder, width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isCompact;

  const _InteractiveActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isCompact = false,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isPrimary
            ? (_hovered ? AppColors.goldAccent : AppColors.primaryAccent)
            : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.accentBlue
            : (widget.isPrimary
                ? AppColors.goldAccent
                : AppTheme.borderColor));
    final fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isPrimary && _hovered
            ? AppColors.background
            : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 10 : 14,
            vertical: widget.isCompact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: fgColor),
              if (widget.label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
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

class _CyclocrossLapProfilePainter extends CustomPainter {
  final CyclocrossCourseAndMudModel course;

  const _CyclocrossLapProfilePainter({required this.course});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      bgPaint,
    );

    final totalLen = course.lapLengthMeters;
    if (totalLen <= 0 || course.segments.isEmpty) return;

    double x = 0;
    for (final seg in course.segments) {
      final w = (seg.lengthMeters / totalLen) * size.width;
      final color = _segmentColor(seg.terrainType);
      final heightRatio =
          (0.35 + (seg.gradientPercent.abs() / 25.0) * 0.5).clamp(0.28, 0.88);
      final barHeight = size.height * heightRatio;
      final rect = Rect.fromLTWH(
        x,
        size.height - barHeight,
        math.max(2.0, w - 1.0),
        barHeight,
      );
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.85));
      x += w;
    }
  }

  Color _segmentColor(CyclocrossTerrainType type) {
    switch (type) {
      case CyclocrossTerrainType.pavedStartFinish:
        return AppColors.textSecondary;
      case CyclocrossTerrainType.meadowGrass:
        return AppColors.statusSuccess;
      case CyclocrossTerrainType.deepMud:
        return const Color(0xFF8B5A2B);
      case CyclocrossTerrainType.sandPit:
        return AppColors.goldAccent;
      case CyclocrossTerrainType.offCamberSlope:
        return AppColors.amberWarning;
      case CyclocrossTerrainType.planks:
        return AppColors.crimsonAlert;
      case CyclocrossTerrainType.staircaseRunUp:
        return AppColors.powerZone7;
      case CyclocrossTerrainType.doublePitLane:
        return AppColors.accentBlue;
      case CyclocrossTerrainType.woodlandSingletrack:
        return const Color(0xFF0D9488);
    }
  }

  @override
  bool shouldRepaint(covariant _CyclocrossLapProfilePainter oldDelegate) {
    return oldDelegate.course != course;
  }
}

class _TirePressureGaugePainter extends CustomPainter {
  final double selectedBar;
  final double recommendedBar;

  const _TirePressureGaugePainter({
    required this.selectedBar,
    required this.recommendedBar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const minB = CyclocrossPhysicsAdvisor.minPressureBar;
    const maxB = CyclocrossPhysicsAdvisor.maxPressureBar;
    const span = maxB - minB;

    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.35, size.width, 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(trackRect, Paint()..color = AppColors.surfaceLight);

    // Optymalne okno +-0.06 bar
    final optStart = ((recommendedBar - 0.06 - minB) / span).clamp(0.0, 1.0);
    final optEnd = ((recommendedBar + 0.06 - minB) / span).clamp(0.0, 1.0);
    final optRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        optStart * size.width,
        size.height * 0.35,
        math.max(6.0, (optEnd - optStart) * size.width),
        8,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      optRect,
      Paint()..color = AppColors.statusSuccess.withValues(alpha: 0.75),
    );

    // Marker aktualnego ciśnienia
    final selX = ((selectedBar - minB) / span).clamp(0.0, 1.0) * size.width;
    canvas.drawCircle(
      Offset(selX, size.height * 0.35 + 4),
      7,
      Paint()..color = AppColors.goldAccent,
    );
    canvas.drawCircle(
      Offset(selX, size.height * 0.35 + 4),
      3,
      Paint()..color = AppColors.background,
    );
  }

  @override
  bool shouldRepaint(covariant _TirePressureGaugePainter oldDelegate) {
    return oldDelegate.selectedBar != selectedBar ||
        oldDelegate.recommendedBar != recommendedBar;
  }
}
