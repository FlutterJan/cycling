import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/physics/mtb_suspension_damping_and_line_choice_solver.dart';
import '../../engine/rendering3d/mtb_forest_rock_garden_3d_renderer.dart';
import '../../models/race/mtb_xco_course_and_suspension_model.dart';

/// Zakładki główne ekranu Pucharu Świata MTB XCO (używane w widoku mobilnym i tabletowym).
enum MtbXcoWorldCupSection {
  calendarAndCourse('Kalendarz i Trasa', Icons.terrain_rounded),
  suspensionAndTires('Zawieszenie i Opony 2.4"', Icons.tune_rounded),
  telemetryAndRace('Telemetria i Wyścig', Icons.speed_rounded);

  final String labelPl;
  final IconData icon;

  const MtbXcoWorldCupSection(this.labelPl, this.icon);
}

/// Pojedyncza runda Pucharu Świata / Igrzysk / MŚ MTB XCO.
class MtbXcoWorldCupRound {
  final String id;
  final int roundNumber;
  final String title;
  final String countryCode;
  final String monthLabelPl;
  final String iconicFeaturePl;
  final MtbForestBiomePreset biomePreset;
  final MtbXcoCourseAndSuspensionModel course;
  final double worldCupPointsScale;

  const MtbXcoWorldCupRound({
    required this.id,
    required this.roundNumber,
    required this.title,
    required this.countryCode,
    required this.monthLabelPl,
    required this.iconicFeaturePl,
    required this.biomePreset,
    required this.course,
    this.worldCupPointsScale = 1.0,
  });
}

/// Katalog 6 oficjalnych rund Pucharu Świata i imprez mistrzowskich MTB XCO.
class MtbXcoWorldCupCatalog {
  MtbXcoWorldCupCatalog._();

  static List<MtbXcoWorldCupRound> buildCalendar() {
    return [
      MtbXcoWorldCupRound(
        id: 'nove_mesto',
        roundNumber: 1,
        title: 'Nové Město na Moravě',
        countryCode: 'CZE',
        monthLabelPl: 'Maj • Runda 1',
        iconicFeaturePl: 'BMX Start, Rock' 'n' 'Roll & Korzenie Expert',
        biomePreset: MtbForestBiomePreset.noveMestoPineForest,
        course: MtbXcoCourseAndSuspensionModel.noveMestoWorldCup(),
      ),
      const MtbXcoWorldCupRound(
        id: 'val_di_sole',
        roundNumber: 2,
        title: 'Val di Sole — Black Snake',
        countryCode: 'ITA',
        monthLabelPl: 'Czerwiec • Runda 2',
        iconicFeaturePl: 'Strome korzenie i czarny granit',
        biomePreset: MtbForestBiomePreset.valDiSoleAlpineRoots,
        course: MtbXcoCourseAndSuspensionModel(
          courseId: 'wc_val_di_sole_xco',
          name: 'Val di Sole World Cup XCO',
          venueLocation: 'Commezzadura, Włochy',
          raceTier: MtbXcoRaceTier.worldCupXco,
          lapDistanceKm: 4.1,
          totalLaps: 6,
          startLoopMeters: 780.0,
          elevationGainPerLapMeters: 192.0,
          altitudeMeters: 865.0,
          soilCondition: MtbTrailSoilCondition.wetRootsAndRock,
          techZoneCountPerLap: 2,
          segments: [
            MtbXcoCourseSegment(
              index: 0,
              name: 'Start Loop — Dolina Noce',
              startMeter: 0.0,
              lengthMeters: 780.0,
              featureType: MtbXcoFeatureType.startLoop,
              gradientPercent: 6.5,
              roughnessIndex: 0.25,
              recommendedLockout: SuspensionLockoutMode.locked,
              recommendedDropper: DropperPostState.extended,
            ),
            MtbXcoCourseSegment(
              index: 1,
              name: 'Black Snake Roots',
              startMeter: 780.0,
              lengthMeters: 620.0,
              featureType: MtbXcoFeatureType.rootSection,
              gradientPercent: -12.4,
              roughnessIndex: 0.88,
              rockSizeCm: 28.0,
              rootDensityPerMeter: 3.4,
              dropHeightMeters: 0.8,
              recommendedLockout: SuspensionLockoutMode.open,
              recommendedDropper: DropperPostState.slammed,
              aLine: MtbXcoLineOption(
                lineChoice: MtbTrailLineChoice.aLine,
                lengthMeters: 595.0,
                technicalDifficulty: 9.1,
                timeAdvantageSeconds: 4.8,
                crashRiskBase: 0.055,
                minSuspensionTravelMm: 120,
                requiresDropperPost: true,
              ),
              bLine: MtbXcoLineOption(
                lineChoice: MtbTrailLineChoice.bLine,
                lengthMeters: 645.0,
                technicalDifficulty: 5.5,
                timeAdvantageSeconds: 0.0,
                crashRiskBase: 0.015,
                minSuspensionTravelMm: 100,
              ),
            ),
            MtbXcoCourseSegment(
              index: 2,
              name: 'Daolasa Punch Climb',
              startMeter: 1400.0,
              lengthMeters: 1150.0,
              featureType: MtbXcoFeatureType.punchyClimb,
              gradientPercent: 14.5,
              roughnessIndex: 0.38,
              recommendedLockout: SuspensionLockoutMode.pedalTrail,
              recommendedDropper: DropperPostState.extended,
            ),
            MtbXcoCourseSegment(
              index: 3,
              name: 'Granite Waterfall Drop',
              startMeter: 2550.0,
              lengthMeters: 540.0,
              featureType: MtbXcoFeatureType.dropOff,
              gradientPercent: -14.0,
              roughnessIndex: 0.84,
              rockSizeCm: 36.0,
              dropHeightMeters: 1.35,
              recommendedLockout: SuspensionLockoutMode.open,
              recommendedDropper: DropperPostState.slammed,
              aLine: MtbXcoLineOption(
                lineChoice: MtbTrailLineChoice.aLine,
                lengthMeters: 515.0,
                dropHeightMeters: 1.35,
                technicalDifficulty: 9.0,
                timeAdvantageSeconds: 4.1,
                crashRiskBase: 0.05,
                minSuspensionTravelMm: 120,
                requiresDropperPost: true,
              ),
              bLine: MtbXcoLineOption(
                lineChoice: MtbTrailLineChoice.bLine,
                lengthMeters: 565.0,
                technicalDifficulty: 4.8,
                timeAdvantageSeconds: 0.0,
                crashRiskBase: 0.012,
                minSuspensionTravelMm: 100,
              ),
            ),
            MtbXcoCourseSegment(
              index: 4,
              name: 'Tech Zone & Finish Straight',
              startMeter: 3090.0,
              lengthMeters: 1010.0,
              featureType: MtbXcoFeatureType.finishStraight,
              gradientPercent: 2.0,
              roughnessIndex: 0.16,
              isTechFeedZone: true,
              recommendedLockout: SuspensionLockoutMode.locked,
              recommendedDropper: DropperPostState.extended,
            ),
          ],
        ),
      ),
      const MtbXcoWorldCupRound(
        id: 'les_gets',
        roundNumber: 3,
        title: 'Les Gets — Haute-Savoie',
        countryCode: 'FRA',
        monthLabelPl: 'Lipiec • Runda 3',
        iconicFeaturePl: 'Szybkie skocznie, pył i wysokie bandy',
        biomePreset: MtbForestBiomePreset.lesGetsBirchAndDust,
        course: MtbXcoCourseAndSuspensionModel(
          courseId: 'wc_les_gets_xco',
          name: 'Les Gets World Cup XCO',
          venueLocation: 'Les Gets, Francja',
          raceTier: MtbXcoRaceTier.worldCupXco,
          lapDistanceKm: 4.3,
          totalLaps: 6,
          startLoopMeters: 820.0,
          elevationGainPerLapMeters: 175.0,
          altitudeMeters: 1172.0,
          soilCondition: MtbTrailSoilCondition.dryHardpack,
          techZoneCountPerLap: 2,
          segments: [
            MtbXcoCourseSegment(
              index: 0,
              name: 'Mont Chéry Start Climb',
              startMeter: 0.0,
              lengthMeters: 1120.0,
              featureType: MtbXcoFeatureType.punchyClimb,
              gradientPercent: 11.2,
              roughnessIndex: 0.22,
              recommendedLockout: SuspensionLockoutMode.locked,
              recommendedDropper: DropperPostState.extended,
            ),
            MtbXcoCourseSegment(
              index: 1,
              name: 'Alpine Pump Rollers & Berms',
              startMeter: 1120.0,
              lengthMeters: 980.0,
              featureType: MtbXcoFeatureType.bermSwitchback,
              gradientPercent: -7.5,
              roughnessIndex: 0.44,
              recommendedLockout: SuspensionLockoutMode.open,
              recommendedDropper: DropperPostState.midDrop,
            ),
            MtbXcoCourseSegment(
              index: 2,
              name: 'Chavannes Rock Garden',
              startMeter: 2100.0,
              lengthMeters: 620.0,
              featureType: MtbXcoFeatureType.rockGarden,
              gradientPercent: -9.8,
              roughnessIndex: 0.76,
              rockSizeCm: 30.0,
              dropHeightMeters: 0.9,
              recommendedLockout: SuspensionLockoutMode.open,
              recommendedDropper: DropperPostState.slammed,
              aLine: MtbXcoLineOption(
                lineChoice: MtbTrailLineChoice.aLine,
                lengthMeters: 595.0,
                technicalDifficulty: 8.2,
                timeAdvantageSeconds: 3.4,
                crashRiskBase: 0.038,
                minSuspensionTravelMm: 110,
                requiresDropperPost: true,
              ),
              bLine: MtbXcoLineOption(
                lineChoice: MtbTrailLineChoice.bLine,
                lengthMeters: 640.0,
                technicalDifficulty: 4.5,
                timeAdvantageSeconds: 0.0,
                crashRiskBase: 0.01,
                minSuspensionTravelMm: 100,
              ),
            ),
            MtbXcoCourseSegment(
              index: 3,
              name: 'Tech Zone & Stadion Meta',
              startMeter: 2720.0,
              lengthMeters: 1580.0,
              featureType: MtbXcoFeatureType.finishStraight,
              gradientPercent: 3.0,
              roughnessIndex: 0.18,
              isTechFeedZone: true,
              recommendedLockout: SuspensionLockoutMode.pedalTrail,
              recommendedDropper: DropperPostState.extended,
            ),
          ],
        ),
      ),
      const MtbXcoWorldCupRound(
        id: 'crans_montana',
        roundNumber: 4,
        title: 'Crans-Montana — MŚ UCI',
        countryCode: 'SUI',
        monthLabelPl: 'Sierpień • Mistrzostwa Świata',
        iconicFeaturePl: 'Kanion modrzewiowy i sypki żwir na 1500 m',
        biomePreset: MtbForestBiomePreset.cransMontanaCedarGorge,
        worldCupPointsScale: 1.4,
        course: MtbXcoCourseAndSuspensionModel(
          courseId: 'worlds_crans_montana_xco',
          name: 'Crans-Montana Worlds XCO',
          venueLocation: 'Valais, Szwajcaria',
          raceTier: MtbXcoRaceTier.worldChampionshipsXco,
          lapDistanceKm: 4.2,
          totalLaps: 6,
          startLoopMeters: 850.0,
          elevationGainPerLapMeters: 185.0,
          altitudeMeters: 1510.0,
          soilCondition: MtbTrailSoilCondition.looseDust,
          techZoneCountPerLap: 2,
          segments: [
            MtbXcoCourseSegment(
              index: 0,
              name: 'Alpine Meadow Climb',
              startMeter: 0.0,
              lengthMeters: 1200.0,
              featureType: MtbXcoFeatureType.punchyClimb,
              gradientPercent: 12.6,
              roughnessIndex: 0.34,
              recommendedLockout: SuspensionLockoutMode.pedalTrail,
              recommendedDropper: DropperPostState.extended,
            ),
            MtbXcoCourseSegment(
              index: 1,
              name: 'Larch Gorge Rock Drop',
              startMeter: 1200.0,
              lengthMeters: 740.0,
              featureType: MtbXcoFeatureType.rockGarden,
              gradientPercent: -11.5,
              roughnessIndex: 0.85,
              rockSizeCm: 34.0,
              dropHeightMeters: 1.15,
              recommendedLockout: SuspensionLockoutMode.open,
              recommendedDropper: DropperPostState.slammed,
              aLine: MtbXcoLineOption(
                lineChoice: MtbTrailLineChoice.aLine,
                lengthMeters: 710.0,
                dropHeightMeters: 1.15,
                technicalDifficulty: 8.8,
                timeAdvantageSeconds: 4.2,
                crashRiskBase: 0.048,
                minSuspensionTravelMm: 120,
                requiresDropperPost: true,
              ),
              bLine: MtbXcoLineOption(
                lineChoice: MtbTrailLineChoice.bLine,
                lengthMeters: 765.0,
                technicalDifficulty: 5.0,
                timeAdvantageSeconds: 0.0,
                crashRiskBase: 0.012,
                minSuspensionTravelMm: 100,
              ),
            ),
            MtbXcoCourseSegment(
              index: 2,
              name: 'Cedar Root Traverse',
              startMeter: 1940.0,
              lengthMeters: 860.0,
              featureType: MtbXcoFeatureType.rootSection,
              gradientPercent: 1.8,
              roughnessIndex: 0.62,
              rootDensityPerMeter: 2.2,
              recommendedLockout: SuspensionLockoutMode.open,
              recommendedDropper: DropperPostState.midDrop,
            ),
            MtbXcoCourseSegment(
              index: 3,
              name: 'Valais Finish Arena',
              startMeter: 2800.0,
              lengthMeters: 1400.0,
              featureType: MtbXcoFeatureType.finishStraight,
              gradientPercent: 2.5,
              roughnessIndex: 0.20,
              isTechFeedZone: true,
              recommendedLockout: SuspensionLockoutMode.locked,
              recommendedDropper: DropperPostState.extended,
            ),
          ],
        ),
      ),
      MtbXcoWorldCupRound(
        id: 'olympic_elancourt',
        roundNumber: 5,
        title: 'Elancourt Hill — XCO Olimpijskie',
        countryCode: 'FRA',
        monthLabelPl: 'Sierpień • Igrzyska XCO',
        iconicFeaturePl: 'Sztuczne rock gardeny i szybkie szutry',
        biomePreset: MtbForestBiomePreset.noveMestoPineForest,
        worldCupPointsScale: 1.5,
        course: MtbXcoCourseAndSuspensionModel.olympicXcoDefault(),
      ),
      const MtbXcoWorldCupRound(
        id: 'lenzerheide_xcc',
        roundNumber: 6,
        title: 'Lenzerheide — Finał XCC/XCO',
        countryCode: 'SUI',
        monthLabelPl: 'Wrzesień • Finał Sezonu',
        iconicFeaturePl: 'Ekspresowe podjazdy i techniczne mostki',
        biomePreset: MtbForestBiomePreset.valDiSoleAlpineRoots,
        course: MtbXcoCourseAndSuspensionModel(
          courseId: 'wc_lenzerheide_xcc',
          name: 'Lenzerheide XCC Short Track',
          venueLocation: 'Graubünden, Szwajcaria',
          raceTier: MtbXcoRaceTier.shortTrackXcc,
          lapDistanceKm: 1.15,
          totalLaps: 9,
          startLoopMeters: 250.0,
          elevationGainPerLapMeters: 42.0,
          altitudeMeters: 1473.0,
          soilCondition: MtbTrailSoilCondition.tackyLoam,
          techZoneCountPerLap: 1,
          segments: [
            MtbXcoCourseSegment(
              index: 0,
              name: 'Arena Sprint Climb',
              startMeter: 0.0,
              lengthMeters: 420.0,
              featureType: MtbXcoFeatureType.punchyClimb,
              gradientPercent: 10.5,
              roughnessIndex: 0.24,
              recommendedLockout: SuspensionLockoutMode.locked,
              recommendedDropper: DropperPostState.extended,
            ),
            MtbXcoCourseSegment(
              index: 1,
              name: 'Heidsee Wooden Bridge & Roots',
              startMeter: 420.0,
              lengthMeters: 360.0,
              featureType: MtbXcoFeatureType.woodBridge,
              gradientPercent: -6.2,
              roughnessIndex: 0.56,
              dropHeightMeters: 0.55,
              recommendedLockout: SuspensionLockoutMode.open,
              recommendedDropper: DropperPostState.midDrop,
            ),
            MtbXcoCourseSegment(
              index: 2,
              name: 'Final Kick Straight',
              startMeter: 780.0,
              lengthMeters: 370.0,
              featureType: MtbXcoFeatureType.finishStraight,
              gradientPercent: 1.5,
              roughnessIndex: 0.14,
              isTechFeedZone: true,
              recommendedLockout: SuspensionLockoutMode.locked,
              recommendedDropper: DropperPostState.extended,
            ),
          ],
        ),
      ),
    ];
  }
}

/// Wpis klasyfikacji wyścigu Pucharu Świata MTB XCO.
class MtbXcoRaceClassificationEntry {
  final int position;
  final String riderName;
  final String teamName;
  final String nationCode;
  final double totalTimeSeconds;
  final double gapSeconds;
  final int aLinesTaken;
  final int uciPoints;
  final bool isPlayerRider;

  const MtbXcoRaceClassificationEntry({
    required this.position,
    required this.riderName,
    required this.teamName,
    required this.nationCode,
    required this.totalTimeSeconds,
    required this.gapSeconds,
    required this.aLinesTaken,
    required this.uciPoints,
    this.isPlayerRider = false,
  });
}

/// Pełny raport ukończonego wyścigu Pucharu Świata MTB XCO.
class MtbXcoRaceSimulationReport {
  final String roundId;
  final String roundTitle;
  final int playerPosition;
  final double playerTotalTimeSeconds;
  final double winnerGapSeconds;
  final double averageLapSeconds;
  final int totalALinesTaken;
  final int uciPointsEarned;
  final List<String> raceEventsLog;
  final List<MtbXcoRaceClassificationEntry> standings;

  const MtbXcoRaceSimulationReport({
    required this.roundId,
    required this.roundTitle,
    required this.playerPosition,
    required this.playerTotalTimeSeconds,
    required this.winnerGapSeconds,
    required this.averageLapSeconds,
    required this.totalALinesTaken,
    required this.uciPointsEarned,
    required this.raceEventsLog,
    required this.standings,
  });
}

/// Deterministyczny symulator wyścigu Pucharu Świata MTB XCO oparty o fizykę zawieszenia i opon 2.4".
class MtbXcoRaceSimulator {
  MtbXcoRaceSimulator._();

  static const List<int> _worldCupPointsTable = [
    250,
    200,
    160,
    140,
    120,
    100,
    90,
    80,
    70,
    60,
    50,
    40,
    30,
  ];

  static const List<_MtbRivalSeed> _rivals = [
    _MtbRivalSeed('Nino Schurter', 'Scott-SRAM MTB', 'SUI', 0.996, 97),
    _MtbRivalSeed('Tom Pidcock', 'INEOS Grenadiers MTB', 'GBR', 1.000, 96),
    _MtbRivalSeed('Victor Koretzky', 'Specialized Factory', 'FRA', 0.993, 93),
    _MtbRivalSeed('Mathieu van der Poel', 'Alpecin-Deceuninck', 'NED', 0.994, 94),
    _MtbRivalSeed('Alan Hatherly', 'Cannondale Factory', 'RSA', 0.989, 91),
    _MtbRivalSeed('Filippo Colombo', 'Scott-SRAM MTB', 'SUI', 0.984, 89),
    _MtbRivalSeed('Jordan Sarrou', 'Team BMC', 'FRA', 0.982, 90),
    _MtbRivalSeed('Luca Braidot', 'Santa Cruz RockShox', 'ITA', 0.980, 88),
    _MtbRivalSeed('Christopher Blevins', 'Specialized Factory', 'USA', 0.977, 87),
    _MtbRivalSeed('Bartłomiej Wawak', 'Kross Orlen Cycling', 'POL', 0.971, 86),
    _MtbRivalSeed('Vlad Dascălu', 'Trek Factory Racing', 'ROU', 0.975, 88),
    _MtbRivalSeed('Martín Vidaurre', 'Specialized Factory', 'CHI', 0.973, 86),
  ];

  static MtbXcoRaceSimulationReport simulateRace({
    required MtbXcoWorldCupRound round,
    required MtbXcoBikeConfiguration bikeConfig,
    required MtbTrailSoilCondition soilCondition,
    required double riderMassKg,
    required double riderPowerWatts,
    required double bikeHandling,
    required MtbLineTacticalPolicy linePolicy,
  }) {
    final effectiveCourse = MtbXcoCourseAndSuspensionModel(
      courseId: round.course.courseId,
      name: round.course.name,
      venueLocation: round.course.venueLocation,
      raceTier: round.course.raceTier,
      lapDistanceKm: round.course.lapDistanceKm,
      totalLaps: round.course.totalLaps,
      startLoopMeters: round.course.startLoopMeters,
      elevationGainPerLapMeters: round.course.elevationGainPerLapMeters,
      altitudeMeters: round.course.altitudeMeters,
      soilCondition: soilCondition,
      segments: round.course.segments,
      techZoneCountPerLap: round.course.techZoneCountPerLap,
    );

    final laps = effectiveCourse.totalLaps.clamp(1, 12);
    final eventsLog = <String>[];
    double playerTotalSeconds = (effectiveCourse.startLoopMeters / 7.8);
    int playerALines = 0;

    for (int lap = 0; lap < laps; lap++) {
      // Symulujemy spadek W' i lekkie zmęczenie w środkowych rundach
      final wPrimeRatio = (0.92 - (lap * 0.06)).clamp(0.42, 0.95);
      final deterministicRoll = ((lap * 0.23 + 0.17) % 0.99);
      final lapSummary = MtbSuspensionDampingAndLineChoiceSolver.simulateLap(
        course: effectiveCourse,
        bikeConfig: bikeConfig,
        riderMassKg: riderMassKg,
        basePowerWatts: riderPowerWatts * (1.0 - lap * 0.008),
        bikeHandling: bikeHandling,
        descendingSkill: bikeHandling - 2.0,
        wPrimeRemainingRatio: wPrimeRatio,
        linePolicy: linePolicy,
        deterministicRoll: deterministicRoll,
      );
      playerTotalSeconds += lapSummary.totalLapTimeSeconds;
      playerALines += lapSummary.aLinesTaken;

      for (final seg in lapSummary.segmentResults) {
        if (seg.outcome.isIncident) {
          eventsLog.add(
            'Runda ${lap + 1}: ${seg.outcome.labelPl} (${seg.segmentName}, +${seg.incidentTimePenaltySeconds.toStringAsFixed(1)}s)',
          );
        }
      }
    }

    if (eventsLog.isEmpty) {
      eventsLog.add(
        'Czysty przejazd wszystkich $laps rund bez defektu opon 2.4" i dobicia zawieszenia.',
      );
    }

    // Wygeneruj czasy rywali na bazie optymalnego tempa trasy
    final optimalRec = MtbSuspensionDampingAndLineChoiceSolver.recommendOptimalSetup(
      course: effectiveCourse,
      riderMassKg: 67.5,
    );
    final rivalBike = MtbXcoBikeConfiguration(
      bikeId: 'rival_pro_xco',
      modelName: 'WorldTour Factory XC 120',
      totalWeightKg: 9.9,
      suspension: MtbForkAndShockSetup(
        architecture: MtbSuspensionArchitecture.fullSuspensionDowncountry120,
        forkTravelMm: optimalRec.recommendedTravelMm,
        rearShockTravelMm: optimalRec.recommendedTravelMm == 120 ? 120 : 100,
        forkAirPressurePsi: optimalRec.recommendedForkPsi,
        rearShockAirPressurePsi: optimalRec.recommendedRearShockPsi,
        forkReboundClicks: optimalRec.recommendedForkReboundClicks,
        rearReboundClicks: optimalRec.recommendedRearReboundClicks,
        hasElectronicFlightAttendant: true,
      ),
      dropperPost: const DropperPostSpec(travelMm: 125),
      tireSetup: MtbTire24Setup(
        widthInches: 2.4,
        treadPattern: optimalRec.recommendedTreadPattern,
        frontPressureBar: optimalRec.recommendedFrontTireBar,
        rearPressureBar: optimalRec.recommendedRearTireBar,
        hasRimInsert: true,
      ),
    );

    final rivalLapBaseline = MtbSuspensionDampingAndLineChoiceSolver.simulateLap(
      course: effectiveCourse,
      bikeConfig: rivalBike,
      riderMassKg: 67.5,
      basePowerWatts: 378.0,
      bikeHandling: 91.0,
      descendingSkill: 90.0,
      wPrimeRemainingRatio: 0.85,
      linePolicy: MtbLineTacticalPolicy.balancedExpectedValue,
      deterministicRoll: 0.65,
    );

    final rawEntries = <MtbXcoRaceClassificationEntry>[
      MtbXcoRaceClassificationEntry(
        position: 0,
        riderName: 'Twój Lider (Pro Peloton)',
        teamName: 'Twoja Drużyna MTB',
        nationCode: 'POL',
        totalTimeSeconds: playerTotalSeconds,
        gapSeconds: 0.0,
        aLinesTaken: playerALines,
        uciPoints: 0,
        isPlayerRider: true,
      ),
    ];

    for (int i = 0; i < _rivals.length; i++) {
      final rival = _rivals[i];
      final seedJitter = ((i * 7 + round.roundNumber * 3) % 11) * 1.6;
      final rivalTime =
          (effectiveCourse.startLoopMeters / 7.9) +
          (rivalLapBaseline.totalLapTimeSeconds / rival.paceFactor) * laps +
          seedJitter;
      rawEntries.add(
        MtbXcoRaceClassificationEntry(
          position: 0,
          riderName: rival.name,
          teamName: rival.team,
          nationCode: rival.nationCode,
          totalTimeSeconds: rivalTime,
          gapSeconds: 0.0,
          aLinesTaken: (laps * (rival.handling >= 90 ? 2 : 1)),
          uciPoints: 0,
        ),
      );
    }

    rawEntries.sort((a, b) => a.totalTimeSeconds.compareTo(b.totalTimeSeconds));
    final winnerTime = rawEntries.first.totalTimeSeconds;

    final ranked = <MtbXcoRaceClassificationEntry>[];
    for (int i = 0; i < rawEntries.length; i++) {
      final entry = rawEntries[i];
      final pos = i + 1;
      final basePts = i < _worldCupPointsTable.length
          ? _worldCupPointsTable[i]
          : 20;
      final scaledPts = (basePts * round.worldCupPointsScale).round();
      ranked.add(
        MtbXcoRaceClassificationEntry(
          position: pos,
          riderName: entry.riderName,
          teamName: entry.teamName,
          nationCode: entry.nationCode,
          totalTimeSeconds: entry.totalTimeSeconds,
          gapSeconds: entry.totalTimeSeconds - winnerTime,
          aLinesTaken: entry.aLinesTaken,
          uciPoints: scaledPts,
          isPlayerRider: entry.isPlayerRider,
        ),
      );
    }

    final playerEntry = ranked.firstWhere((e) => e.isPlayerRider);
    return MtbXcoRaceSimulationReport(
      roundId: round.id,
      roundTitle: round.title,
      playerPosition: playerEntry.position,
      playerTotalTimeSeconds: playerEntry.totalTimeSeconds,
      winnerGapSeconds: playerEntry.gapSeconds,
      averageLapSeconds:
          (playerTotalSeconds - (effectiveCourse.startLoopMeters / 7.8)) / laps,
      totalALinesTaken: playerALines,
      uciPointsEarned: playerEntry.uciPoints,
      raceEventsLog: eventsLog,
      standings: ranked,
    );
  }
}

class _MtbRivalSeed {
  final String name;
  final String team;
  final String nationCode;
  final double paceFactor;
  final int handling;

  const _MtbRivalSeed(
    this.name,
    this.team,
    this.nationCode,
    this.paceFactor,
    this.handling,
  );
}

/// CustomPainter prezentujący ugięcie wstępne (SAG %) widelca i dampera ze strefą Sweet Spot.
class MtbSuspensionSagGaugePainter extends CustomPainter {
  final double forkSagPercent;
  final double rearShockSagPercent;
  final bool hasRearShock;

  const MtbSuspensionSagGaugePainter({
    required this.forkSagPercent,
    required this.rearShockSagPercent,
    required this.hasRearShock,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double barHeight = hasRearShock ? 12.0 : 16.0;
    _drawSagBar(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 4, size.width, barHeight),
      sagPercent: forkSagPercent,
      sweetMin: 15.0,
      sweetMax: 21.0,
      accentColor: AppColors.accentBlue,
    );

    if (hasRearShock) {
      _drawSagBar(
        canvas: canvas,
        rect: Rect.fromLTWH(0, barHeight + 14, size.width, barHeight),
        sagPercent: rearShockSagPercent,
        sweetMin: 21.0,
        sweetMax: 27.0,
        accentColor: AppColors.goldAccent,
      );
    }
  }

  void _drawSagBar({
    required Canvas canvas,
    required Rect rect,
    required double sagPercent,
    required double sweetMin,
    required double sweetMax,
    required Color accentColor,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final bgPaint = Paint()..color = AppColors.surfaceLight;
    canvas.drawRRect(rrect, bgPaint);

    // Strefa Sweet Spot (skala 0–40% SAG)
    final double leftFrac = (sweetMin / 40.0).clamp(0.0, 1.0);
    final double rightFrac = (sweetMax / 40.0).clamp(0.0, 1.0);
    final sweetRect = Rect.fromLTWH(
      rect.left + rect.width * leftFrac,
      rect.top,
      rect.width * (rightFrac - leftFrac),
      rect.height,
    );
    final sweetPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: 0.25);
    canvas.drawRect(sweetRect, sweetPaint);

    // Wypełnienie aktualnego ugięcia SAG
    final double fillFrac = (sagPercent / 40.0).clamp(0.04, 1.0);
    final bool inSweetSpot = sagPercent >= sweetMin && sagPercent <= sweetMax;
    final Color markerColor = inSweetSpot
        ? AppColors.statusSuccess
        : (sagPercent > sweetMax + 4.0
              ? AppColors.crimsonAlert
              : accentColor);

    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.top, rect.width * fillFrac, rect.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(fillRect, Paint()..color = markerColor.withValues(alpha: 0.85));

    // Kreska znacznika na końcu paska
    final double markerX = rect.left + rect.width * fillFrac;
    canvas.drawLine(
      Offset(markerX, rect.top - 2),
      Offset(markerX, rect.bottom + 2),
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant MtbSuspensionSagGaugePainter oldDelegate) {
    return oldDelegate.forkSagPercent != forkSagPercent ||
        oldDelegate.rearShockSagPercent != rearShockSagPercent ||
        oldDelegate.hasRearShock != hasRearShock;
  }
}

/// Ekran Pucharu Świata MTB XCO oraz konfiguratora ciśnienia widelca/dampera i opon 2.4".
class MtbXcoWorldCupScreen extends StatefulWidget {
  final bool isReadOnly;
  final bool show3dPreview;
  final VoidCallback? onBack;
  final ValueChanged<MtbXcoRaceSimulationReport>? onRaceCompleted;

  const MtbXcoWorldCupScreen({
    super.key,
    this.isReadOnly = false,
    this.show3dPreview = true,
    this.onBack,
    this.onRaceCompleted,
  });

  @override
  State<MtbXcoWorldCupScreen> createState() => _MtbXcoWorldCupScreenState();
}

class _MtbXcoWorldCupScreenState extends State<MtbXcoWorldCupScreen> {
  late final List<MtbXcoWorldCupRound> _rounds;
  int _selectedRoundIndex = 0;
  MtbXcoWorldCupSection _activeSection =
      MtbXcoWorldCupSection.suspensionAndTires;

  // Parametry kolarza i trasy
  double _riderMassKg = 68.0;
  double _riderPowerWatts = 355.0;
  double _bikeHandling = 85.0;
  late MtbTrailSoilCondition _soilCondition;
  MtbLineTacticalPolicy _linePolicy =
      MtbLineTacticalPolicy.balancedExpectedValue;

  // Parametry zawieszenia (Widelec + Damper)
  MtbSuspensionArchitecture _architecture =
      MtbSuspensionArchitecture.fullSuspensionDowncountry120;
  double _forkPsi = 90.0;
  double _rearShockPsi = 165.0;
  int _forkReboundClicks = 9;
  int _rearReboundClicks = 8;
  int _volumeSpacers = 2;
  SuspensionLockoutMode _lockoutMode = SuspensionLockoutMode.open;
  bool _hasFlightAttendant = false;

  // Parametry sztycy i opon 2.4"
  int _dropperTravelMm = 125;
  MtbTireTreadPattern _treadPattern = MtbTireTreadPattern.allRoundXcKnob;
  double _frontTireBar = 1.30;
  double _rearTireBar = 1.40;
  bool _hasRimInsert = true;
  int _sealantVolumeMl = 90;

  bool _is3dExpanded = true;
  final Map<String, MtbXcoRaceSimulationReport> _completedResults = {};

  @override
  void initState() {
    super.initState();
    _rounds = MtbXcoWorldCupCatalog.buildCalendar();
    _soilCondition = _rounds.first.course.soilCondition;
  }

  MtbXcoWorldCupRound get _currentRound => _rounds[_selectedRoundIndex];

  MtbXcoCourseAndSuspensionModel get _effectiveCourse {
    final c = _currentRound.course;
    return MtbXcoCourseAndSuspensionModel(
      courseId: c.courseId,
      name: c.name,
      venueLocation: c.venueLocation,
      raceTier: c.raceTier,
      lapDistanceKm: c.lapDistanceKm,
      totalLaps: c.totalLaps,
      startLoopMeters: c.startLoopMeters,
      elevationGainPerLapMeters: c.elevationGainPerLapMeters,
      altitudeMeters: c.altitudeMeters,
      soilCondition: _soilCondition,
      segments: c.segments,
      techZoneCountPerLap: c.techZoneCountPerLap,
    );
  }

  /// Dynamicznie obliczany SAG % widelca na podstawie wagi kolarza i ciśnienia PSI.
  double get _computedForkSagPercent {
    final recPsi = MtbForkAndShockSetup.computeRecommendedForkPsi(_riderMassKg);
    return (18.0 * (recPsi / _forkPsi.clamp(40.0, 160.0))).clamp(8.0, 38.0);
  }

  /// Dynamicznie obliczany SAG % dampera tylnego.
  double get _computedRearSagPercent {
    if (_architecture == MtbSuspensionArchitecture.hardtail) return 0.0;
    final recPsi = MtbForkAndShockSetup.computeRecommendedRearPsi(_riderMassKg);
    return (24.0 * (recPsi / _rearShockPsi.clamp(80.0, 260.0)))
        .clamp(10.0, 39.0);
  }

  MtbXcoBikeConfiguration get _currentBikeConfig {
    final insertWeightKg = _hasRimInsert ? 0.14 : 0.0;
    final dropperWeightKg = _dropperTravelMm > 0 ? 0.12 : 0.0;
    return MtbXcoBikeConfiguration(
      bikeId: 'wc_xco_custom_setup',
      modelName: _architecture == MtbSuspensionArchitecture.hardtail
          ? 'Pro XC Carbon HT 100'
          : (_architecture == MtbSuspensionArchitecture.fullSuspensionXc100
                ? 'Pro XC Factory FS 100'
                : 'Pro XCO Downcountry 120'),
      totalWeightKg: double.parse(
        (_architecture.baseBikeWeightKg + insertWeightKg + dropperWeightKg)
            .toStringAsFixed(2),
      ),
      suspension: MtbForkAndShockSetup(
        architecture: _architecture,
        forkTravelMm: _architecture.frontTravelMm,
        rearShockTravelMm: _architecture.rearTravelMm,
        forkAirPressurePsi: _forkPsi,
        rearShockAirPressurePsi: _rearShockPsi,
        forkSagPercent: _computedForkSagPercent,
        rearShockSagPercent: _computedRearSagPercent,
        forkReboundClicks: _forkReboundClicks,
        rearReboundClicks: _rearReboundClicks,
        volumeSpacersCount: _volumeSpacers,
        remoteLockoutMode: _lockoutMode,
        hasElectronicFlightAttendant: _hasFlightAttendant,
      ),
      dropperPost: DropperPostSpec(
        travelMm: _dropperTravelMm,
        isWirelessElectronic: _dropperTravelMm >= 100,
      ),
      tireSetup: MtbTire24Setup(
        widthInches: 2.4,
        treadPattern: _treadPattern,
        frontPressureBar: _frontTireBar,
        rearPressureBar: _rearTireBar,
        hasRimInsert: _hasRimInsert,
        sealantVolumeMl: _sealantVolumeMl,
      ),
    );
  }

  void _selectRound(int index) {
    if (widget.isReadOnly) return;
    setState(() {
      _selectedRoundIndex = index;
      _soilCondition = _rounds[index].course.soilCondition;
    });
  }

  void _applyOptimalMechanicSetup() {
    if (widget.isReadOnly) return;
    final rec = MtbSuspensionDampingAndLineChoiceSolver.recommendOptimalSetup(
      course: _effectiveCourse,
      riderMassKg: _riderMassKg,
    );
    setState(() {
      _architecture = rec.recommendedTravelMm >= 120
          ? MtbSuspensionArchitecture.fullSuspensionDowncountry120
          : MtbSuspensionArchitecture.fullSuspensionXc100;
      _forkPsi = rec.recommendedForkPsi;
      _rearShockPsi = rec.recommendedRearShockPsi;
      _forkReboundClicks = rec.recommendedForkReboundClicks;
      _rearReboundClicks = rec.recommendedRearReboundClicks;
      _frontTireBar = rec.recommendedFrontTireBar;
      _rearTireBar = rec.recommendedRearTireBar;
      _treadPattern = rec.recommendedTreadPattern;
      _volumeSpacers = _effectiveCourse.dropCount > 0 ? 2 : 1;
      _dropperTravelMm = 125;
      _hasRimInsert = true;
    });
  }

  void _resetDefaultSetup() {
    if (widget.isReadOnly) return;
    setState(() {
      _riderMassKg = 68.0;
      _riderPowerWatts = 355.0;
      _bikeHandling = 85.0;
      _soilCondition = _currentRound.course.soilCondition;
      _linePolicy = MtbLineTacticalPolicy.balancedExpectedValue;
      _architecture = MtbSuspensionArchitecture.fullSuspensionDowncountry120;
      _forkPsi = 90.0;
      _rearShockPsi = 165.0;
      _forkReboundClicks = 9;
      _rearReboundClicks = 8;
      _volumeSpacers = 2;
      _lockoutMode = SuspensionLockoutMode.open;
      _hasFlightAttendant = false;
      _dropperTravelMm = 125;
      _treadPattern = MtbTireTreadPattern.allRoundXcKnob;
      _frontTireBar = 1.30;
      _rearTireBar = 1.40;
      _hasRimInsert = true;
      _sealantVolumeMl = 90;
    });
  }

  void _runWorldCupSimulation() {
    if (widget.isReadOnly) return;
    final report = MtbXcoRaceSimulator.simulateRace(
      round: _currentRound,
      bikeConfig: _currentBikeConfig,
      soilCondition: _soilCondition,
      riderMassKg: _riderMassKg,
      riderPowerWatts: _riderPowerWatts,
      bikeHandling: _bikeHandling,
      linePolicy: _linePolicy,
    );
    setState(() {
      _completedResults[_currentRound.id] = report;
      _activeSection = MtbXcoWorldCupSection.telemetryAndRace;
    });
    widget.onRaceCompleted?.call(report);
  }

  @override
  Widget build(BuildContext context) {
    final course = _effectiveCourse;
    final bikeConfig = _currentBikeConfig;
    final readiness = bikeConfig.evaluateCourseReadiness(course, _riderMassKg);
    final lapSummary = MtbSuspensionDampingAndLineChoiceSolver.simulateLap(
      course: course,
      bikeConfig: bikeConfig,
      riderMassKg: _riderMassKg,
      basePowerWatts: _riderPowerWatts,
      bikeHandling: _bikeHandling,
      descendingSkill: _bikeHandling - 2.0,
      linePolicy: _linePolicy,
      deterministicRoll: 0.65,
    );
    final currentReport = _completedResults[_currentRound.id];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompact = constraints.maxWidth < 720;
            final bool isDesktopWide = constraints.maxWidth >= 1220;

            return Column(
              children: [
                _buildHeaderBar(context, isCompact: isCompact),
                if (!isDesktopWide)
                  _buildSectionSelectorBar(isCompact: isCompact),
                Expanded(
                  child: isDesktopWide
                      ? _buildDesktopBentoLayout(
                          course: course,
                          readiness: readiness,
                          lapSummary: lapSummary,
                          report: currentReport,
                        )
                      : _buildSingleSectionLayout(
                          isCompact: isCompact,
                          course: course,
                          readiness: readiness,
                          lapSummary: lapSummary,
                          report: currentReport,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, {required bool isCompact}) {
    final int totalPoints = _completedResults.values.fold<int>(
      0,
      (sum, r) => sum + r.uciPointsEarned,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 24,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          if (widget.onBack != null || Navigator.of(context).canPop()) ...[
            _MtbIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Powrót',
              disabled: false,
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.65),
              ),
            ),
            child: const Icon(
              Icons.terrain_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Puchar Świata MTB XCO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  '${_currentRound.title} • Konfigurator Widelca, Dampera i Opon 2.4"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isCompact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PŚ UCI: $totalPoints pkt',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          if (widget.isReadOnly) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.amberWarning.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.amberWarning.withValues(alpha: 0.5),
                ),
              ),
              child: const Text(
                'Tylko podgląd',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amberWarning,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionSelectorBar({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: MtbXcoWorldCupSection.values.map((section) {
          final bool active = _activeSection == section;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _MtbInteractiveChip(
                label: section.labelPl,
                icon: section.icon,
                selected: active,
                disabled: false,
                compact: isCompact,
                onTap: () => setState(() => _activeSection = section),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopBentoLayout({
    required MtbXcoCourseAndSuspensionModel course,
    required MtbXcoSetupReadinessReport readiness,
    required MtbXcoLapPhysicsSummary lapSummary,
    required MtbXcoRaceSimulationReport? report,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 10,
            child: SingleChildScrollView(
              child: _buildCalendarAndCourseColumn(
                course: course,
                isCompact: false,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 12,
            child: SingleChildScrollView(
              child: _buildSuspensionAndTiresColumn(
                course: course,
                isCompact: false,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 10,
            child: SingleChildScrollView(
              child: _buildTelemetryAndRaceColumn(
                course: course,
                readiness: readiness,
                lapSummary: lapSummary,
                report: report,
                isCompact: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSectionLayout({
    required bool isCompact,
    required MtbXcoCourseAndSuspensionModel course,
    required MtbXcoSetupReadinessReport readiness,
    required MtbXcoLapPhysicsSummary lapSummary,
    required MtbXcoRaceSimulationReport? report,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: switch (_activeSection) {
        MtbXcoWorldCupSection.calendarAndCourse => _buildCalendarAndCourseColumn(
          course: course,
          isCompact: isCompact,
        ),
        MtbXcoWorldCupSection.suspensionAndTires =>
          _buildSuspensionAndTiresColumn(course: course, isCompact: isCompact),
        MtbXcoWorldCupSection.telemetryAndRace => _buildTelemetryAndRaceColumn(
          course: course,
          readiness: readiness,
          lapSummary: lapSummary,
          report: report,
          isCompact: isCompact,
        ),
      },
    );
  }

  Widget _buildCalendarAndCourseColumn({
    required MtbXcoCourseAndSuspensionModel course,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MtbSectionCard(
          title: 'Kalendarz Pucharu Świata XCO',
          subtitle: 'Wybierz rundę, aby dostosować skok i bieżnik opon',
          icon: Icons.calendar_month_rounded,
          child: Column(
            children: List.generate(_rounds.length, (i) {
              final r = _rounds[i];
              final selected = i == _selectedRoundIndex;
              final doneReport = _completedResults[r.id];
              return Padding(
                padding: EdgeInsets.only(bottom: i == _rounds.length - 1 ? 0 : 8),
                child: _MtbRoundCardTile(
                  round: r,
                  selected: selected,
                  disabled: widget.isReadOnly,
                  completedReport: doneReport,
                  onTap: () => _selectRound(i),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.show3dPreview)
          _MtbSectionCard(
            title: 'Podgląd 3D Szlaku i Rock Gardenów',
            subtitle: _currentRound.biomePreset.labelPl,
            icon: Icons.view_in_ar_rounded,
            trailing: _MtbInteractiveChip(
              label: _is3dExpanded ? 'Zwiń 3D' : 'Rozwiń 3D',
              selected: _is3dExpanded,
              disabled: false,
              compact: true,
              onTap: () => setState(() => _is3dExpanded = !_is3dExpanded),
            ),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 260),
              sizeCurve: Curves.easeOutCubic,
              crossFadeState: _is3dExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: SizedBox(
                height: isCompact ? 240 : 280,
                child: MtbForestRockGarden3dViewportWidget(
                  key: ValueKey(
                    'mtb_3d_${_currentRound.id}_${_linePolicy.name}',
                  ),
                  initialConfig: MtbForestRockGarden3dConfig(
                    biomePreset: _currentRound.biomePreset,
                    selectedLineChoice:
                        _linePolicy == MtbLineTacticalPolicy.conservativeBLine ||
                            _linePolicy == MtbLineTacticalPolicy.forcedBLine
                        ? MtbTrailLineChoice.bLine
                        : MtbTrailLineChoice.aLine,
                    sunbeamIntensity:
                        _currentRound.biomePreset.defaultSunbeamIntensity,
                    dustDensity: _currentRound.biomePreset.defaultDustDensity,
                    canopyDensity:
                        _currentRound.biomePreset.defaultCanopyDensity,
                    showTelemetryOverlay: true,
                  ),
                ),
              ),
              secondChild: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Podgląd 3D zwinięty — kliknij „Rozwiń 3D”, aby wyświetlić leśną trasę.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        if (widget.show3dPreview) const SizedBox(height: 16),
        _MtbSectionCard(
          title: 'Sekcje Techniczne (A-Line vs B-Line)',
          subtitle:
              '${course.lapDistanceKm.toStringAsFixed(2)} km × ${course.totalLaps} rund • +${course.elevationGainPerLapMeters.toInt()} m/rundę',
          icon: Icons.alt_route_rounded,
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MtbStatPill(
                    label: 'Rock Gardeny',
                    value: '${course.rockGardenCount}',
                    color: AppColors.amberWarning,
                  ),
                  _MtbStatPill(
                    label: 'Dropy',
                    value: '${course.dropCount}',
                    color: AppColors.crimsonAlert,
                  ),
                  _MtbStatPill(
                    label: 'Korzenie',
                    value: '${course.rootSectionCount}',
                    color: AppColors.accentBlue,
                  ),
                  _MtbStatPill(
                    label: 'Zalecany skok',
                    value: '${course.recommendedTravelMm} mm',
                    color: AppColors.statusSuccess,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...course.segments.map((seg) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seg.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${seg.featureType.displayNamePl} • ${seg.lengthMeters.toInt()} m (${seg.gradientPercent >= 0 ? '+' : ''}${seg.gradientPercent.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (seg.hasLineSplit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.goldAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'A-Line -${seg.aLine!.timeAdvantageSeconds.toStringAsFixed(1)}s',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuspensionAndTiresColumn({
    required MtbXcoCourseAndSuspensionModel course,
    required bool isCompact,
  }) {
    final bool isHardtail =
        _architecture == MtbSuspensionArchitecture.hardtail;
    final double recForkPsi =
        MtbForkAndShockSetup.computeRecommendedForkPsi(_riderMassKg);
    final double recRearPsi =
        MtbForkAndShockSetup.computeRecommendedRearPsi(_riderMassKg);
    final double forkSag = _computedForkSagPercent;
    final double rearSag = _computedRearSagPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MtbSectionCard(
          title: 'Konfigurator Widelca i Dampera',
          subtitle: 'Dobór skoku, ciśnienia PSI, ugięcia SAG i tłumienia powrotu',
          icon: Icons.settings_input_component_rounded,
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MtbActionButton(
                label: 'Auto-Optymalizuj',
                icon: Icons.auto_fix_high_rounded,
                variant: _MtbButtonVariant.gold,
                disabled: widget.isReadOnly,
                onPressed: _applyOptimalMechanicSetup,
              ),
              _MtbActionButton(
                label: 'Reset',
                icon: Icons.refresh_rounded,
                variant: _MtbButtonVariant.secondary,
                disabled: widget.isReadOnly,
                onPressed: _resetDefaultSetup,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Architektura ramy i skok zawieszenia',
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
                children: MtbSuspensionArchitecture.values.map((arch) {
                  return _MtbInteractiveChip(
                    label: arch.displayNamePl,
                    selected: _architecture == arch,
                    disabled: widget.isReadOnly,
                    compact: isCompact,
                    onTap: () => setState(() => _architecture = arch),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _MtbSliderRow(
                label: 'Waga kolarza',
                valueLabel: '${_riderMassKg.toStringAsFixed(1)} kg',
                value: _riderMassKg,
                min: 50.0,
                max: 95.0,
                divisions: 90,
                accentColor: AppColors.textPrimary,
                disabled: widget.isReadOnly,
                onChanged: (v) => setState(() => _riderMassKg = v),
              ),
              const SizedBox(height: 10),
              _MtbSliderRow(
                label: 'Ciśnienie widelca (Przód)',
                valueLabel:
                    '${_forkPsi.round()} PSI (zalec. ${recForkPsi.round()})',
                value: _forkPsi,
                min: 55.0,
                max: 145.0,
                divisions: 90,
                accentColor: AppColors.accentBlue,
                disabled: widget.isReadOnly,
                onChanged: (v) => setState(() => _forkPsi = v),
              ),
              const SizedBox(height: 10),
              _MtbSliderRow(
                label: isHardtail
                    ? 'Ciśnienie dampera (Brak w Hardtailu)'
                    : 'Ciśnienie dampera (Tył)',
                valueLabel: isHardtail
                    ? 'Sztywny tył'
                    : '${_rearShockPsi.round()} PSI (zalec. ${recRearPsi.round()})',
                value: _rearShockPsi,
                min: 110.0,
                max: 240.0,
                divisions: 130,
                accentColor: AppColors.goldAccent,
                disabled: widget.isReadOnly || isHardtail,
                onChanged: (v) => setState(() => _rearShockPsi = v),
              ),
              const SizedBox(height: 12),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Ugięcie wstępne (SAG) • Widelec: ${forkSag.toStringAsFixed(1)}%',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        if (!isHardtail) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Damper: ${rearSag.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldAccent,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: isHardtail ? 24 : 42,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: MtbSuspensionSagGaugePainter(
                          forkSagPercent: forkSag,
                          rearShockSagPercent: rearSag,
                          hasRearShock: !isHardtail,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Zielona strefa oznacza optymalny Sweet Spot (15–21% przód, 21–27% tył).',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MtbStepperTile(
                      label: 'Rebound Wid.',
                      valueLabel: '$_forkReboundClicks klik.',
                      disabled: widget.isReadOnly,
                      onDecrement: _forkReboundClicks > 1
                          ? () => setState(() => _forkReboundClicks--)
                          : null,
                      onIncrement: _forkReboundClicks < 16
                          ? () => setState(() => _forkReboundClicks++)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MtbStepperTile(
                      label: 'Rebound Damper',
                      valueLabel:
                          isHardtail ? 'N/D' : '$_rearReboundClicks klik.',
                      disabled: widget.isReadOnly || isHardtail,
                      onDecrement: !isHardtail && _rearReboundClicks > 1
                          ? () => setState(() => _rearReboundClicks--)
                          : null,
                      onIncrement: !isHardtail && _rearReboundClicks < 16
                          ? () => setState(() => _rearReboundClicks++)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MtbStepperTile(
                      label: 'Tokeny obj.',
                      valueLabel: '$_volumeSpacers szt.',
                      disabled: widget.isReadOnly,
                      onDecrement: _volumeSpacers > 0
                          ? () => setState(() => _volumeSpacers--)
                          : null,
                      onIncrement: _volumeSpacers < 4
                          ? () => setState(() => _volumeSpacers++)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...SuspensionLockoutMode.values.map((mode) {
                    return _MtbInteractiveChip(
                      label: mode.displayNamePl,
                      selected: _lockoutMode == mode && !_hasFlightAttendant,
                      disabled: widget.isReadOnly || _hasFlightAttendant,
                      compact: true,
                      onTap: () => setState(() => _lockoutMode = mode),
                    );
                  }),
                  _MtbInteractiveChip(
                    label: 'Flight Attendant (Auto)',
                    icon: Icons.bolt_rounded,
                    selected: _hasFlightAttendant,
                    disabled: widget.isReadOnly,
                    compact: true,
                    onTap: () => setState(
                      () => _hasFlightAttendant = !_hasFlightAttendant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _MtbSectionCard(
          title: 'Konfigurator Opon 2.4" i Sztycy Dropper',
          subtitle: 'Ciśnienie BAR/PSI, mieszanka bieżnika, wkładki i mleczko Tubeless',
          icon: Icons.tire_repair_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bieżnik opony 2.4" Tubeless',
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
                children: MtbTireTreadPattern.values.map((pattern) {
                  return _MtbInteractiveChip(
                    label: pattern.displayNamePl,
                    selected: _treadPattern == pattern,
                    disabled: widget.isReadOnly,
                    compact: isCompact,
                    onTap: () => setState(() => _treadPattern = pattern),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _MtbSliderRow(
                label: 'Ciśnienie opony 2.4" Przód',
                valueLabel:
                    '${_frontTireBar.toStringAsFixed(2)} bar (${(_frontTireBar * 14.5038).toStringAsFixed(1)} PSI)',
                value: _frontTireBar,
                min: 1.05,
                max: 1.85,
                divisions: 80,
                accentColor: AppColors.cyanAccent,
                disabled: widget.isReadOnly,
                onChanged: (v) => setState(
                  () => _frontTireBar = double.parse(v.toStringAsFixed(2)),
                ),
              ),
              const SizedBox(height: 10),
              _MtbSliderRow(
                label: 'Ciśnienie opony 2.4" Tył',
                valueLabel:
                    '${_rearTireBar.toStringAsFixed(2)} bar (${(_rearTireBar * 14.5038).toStringAsFixed(1)} PSI)',
                value: _rearTireBar,
                min: 1.05,
                max: 1.85,
                divisions: 80,
                accentColor: AppColors.statusSuccess,
                disabled: widget.isReadOnly,
                onChanged: (v) => setState(
                  () => _rearTireBar = double.parse(v.toStringAsFixed(2)),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MtbInteractiveChip(
                    label: 'Wkładka antyprzebiciowa (Rim Insert)',
                    icon: Icons.shield_rounded,
                    selected: _hasRimInsert,
                    disabled: widget.isReadOnly,
                    compact: isCompact,
                    onTap: () =>
                        setState(() => _hasRimInsert = !_hasRimInsert),
                  ),
                  ...[0, 100, 125, 150].map((travel) {
                    return _MtbInteractiveChip(
                      label: travel == 0 ? 'Sztyca stała' : 'Dropper $travel mm',
                      selected: _dropperTravelMm == travel,
                      disabled: widget.isReadOnly,
                      compact: true,
                      onTap: () => setState(() => _dropperTravelMm = travel),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Warunki podłoża (Prognoza na dzień wyścigu)',
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
                children: MtbTrailSoilCondition.values.map((soil) {
                  return _MtbInteractiveChip(
                    label: soil.displayNamePl,
                    selected: _soilCondition == soil,
                    disabled: widget.isReadOnly,
                    compact: true,
                    onTap: () => setState(() => _soilCondition = soil),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryAndRaceColumn({
    required MtbXcoCourseAndSuspensionModel course,
    required MtbXcoSetupReadinessReport readiness,
    required MtbXcoLapPhysicsSummary lapSummary,
    required MtbXcoRaceSimulationReport? report,
    required bool isCompact,
  }) {
    final Color scoreColor = readiness.overallScore >= 84
        ? AppColors.statusSuccess
        : (readiness.overallScore >= 68
              ? AppColors.amberWarning
              : AppColors.crimsonAlert);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MtbSectionCard(
          title: 'Telemetria Fizyki i Gotowości XCO',
          subtitle: 'Ocena dopasowania zawieszenia, opon 2.4" i linii A/B',
          icon: Icons.analytics_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.55),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${readiness.overallScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Text(
                          'SETUP',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        _MtbMetricProgressRow(
                          label: 'Zawieszenie',
                          percent: readiness.suspensionMatchScore,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(height: 6),
                        _MtbMetricProgressRow(
                          label: 'Przyczepność 2.4"',
                          percent: readiness.tireGripScore,
                          color: AppColors.statusSuccess,
                        ),
                        const SizedBox(height: 6),
                        _MtbMetricProgressRow(
                          label: 'Pewność A-Line',
                          percent: readiness.aLineConfidenceScore,
                          color: AppColors.goldAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MtbStatPill(
                    label: 'Szac. runda',
                    value: _formatDuration(lapSummary.totalLapTimeSeconds),
                    color: AppColors.textPrimary,
                  ),
                  _MtbStatPill(
                    label: 'Zysk A-Line',
                    value:
                        '-${lapSummary.timeSavedByALinesSeconds.toStringAsFixed(1)}s',
                    color: AppColors.goldAccent,
                  ),
                  _MtbStatPill(
                    label: 'Straty Chatter',
                    value:
                        '${lapSummary.totalChatterEnergyKj.toStringAsFixed(1)} kJ',
                    color: AppColors.accentBlue,
                  ),
                  _MtbStatPill(
                    label: 'Ryzyko defektu',
                    value:
                        '${(lapSummary.cumulativeIncidentProbability * 100).toStringAsFixed(1)}%',
                    color: lapSummary.cumulativeIncidentProbability > 0.14
                        ? AppColors.crimsonAlert
                        : AppColors.statusSuccess,
                  ),
                ],
              ),
              if (readiness.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...readiness.warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.crimsonAlert.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.crimsonAlert.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: AppColors.crimsonAlert,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              w,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (readiness.recommendations.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...readiness.recommendations.map(
                  (rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates_rounded,
                          size: 14,
                          color: AppColors.goldAccent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rec,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _MtbSectionCard(
          title: 'Taktyka Linii i Start Wyścigu',
          subtitle: 'Wybierz strategię na rock gardenach i uruchom wyścig',
          icon: Icons.flag_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MtbLineTacticalPolicy.values.map((policy) {
                  return _MtbInteractiveChip(
                    label: policy.labelPl,
                    selected: _linePolicy == policy,
                    disabled: widget.isReadOnly,
                    compact: true,
                    onTap: () => setState(() => _linePolicy = policy),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _MtbSliderRow(
                label: 'Moc progowa / Tempo wyścigu',
                valueLabel: '${_riderPowerWatts.round()} W',
                value: _riderPowerWatts,
                min: 260.0,
                max: 460.0,
                divisions: 40,
                accentColor: AppColors.primaryAccent,
                disabled: widget.isReadOnly,
                onChanged: (v) => setState(() => _riderPowerWatts = v),
              ),
              const SizedBox(height: 14),
              _MtbActionButton(
                label: 'Symuluj Wyścig PŚ XCO (${course.totalLaps} rund)',
                icon: Icons.play_arrow_rounded,
                variant: _MtbButtonVariant.primary,
                disabled: widget.isReadOnly,
                fullWidth: true,
                onPressed: _runWorldCupSimulation,
              ),
            ],
          ),
        ),
        if (report != null) ...[
          const SizedBox(height: 16),
          _MtbSectionCard(
            title: 'Wyniki Wyścigu — ${report.roundTitle}',
            subtitle:
                'Miejsce #${report.playerPosition} • +${report.uciPointsEarned} pkt UCI • A-Line: ${report.totalALinesTaken}×',
            icon: Icons.emoji_events_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...report.raceEventsLog.map(
                  (ev) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $ev',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...report.standings.take(8).map((entry) {
                  final bool isTop3 = entry.position <= 3;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: entry.isPlayerRider
                          ? AppColors.primaryAccent.withValues(alpha: 0.22)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: entry.isPlayerRider
                            ? AppColors.goldAccent
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: Text(
                            '#${entry.position}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isTop3
                                  ? AppColors.goldAccent
                                  : AppColors.textSecondary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.riderName} (${entry.nationCode})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: entry.isPlayerRider
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          entry.position == 1
                              ? _formatDuration(entry.totalTimeSeconds)
                              : '+${_formatDuration(entry.gapSeconds)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _formatDuration(double totalSeconds) {
    final int mins = (totalSeconds ~/ 60);
    final double secs = totalSeconds % 60.0;
    return '$mins:${secs.toStringAsFixed(1).padLeft(4, '0')}';
  }
}

class _MtbSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _MtbSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stackTrailing =
              trailing != null && constraints.maxWidth < 460;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: AppColors.goldAccent),
                  const SizedBox(width: 8),
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
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                  if (trailing != null && !stackTrailing) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              if (stackTrailing) ...[
                const SizedBox(height: 10),
                trailing!,
              ],
              const SizedBox(height: 14),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _MtbRoundCardTile extends StatefulWidget {
  final MtbXcoWorldCupRound round;
  final bool selected;
  final bool disabled;
  final MtbXcoRaceSimulationReport? completedReport;
  final VoidCallback onTap;

  const _MtbRoundCardTile({
    required this.round,
    required this.selected,
    required this.disabled,
    required this.completedReport,
    required this.onTap,
  });

  @override
  State<_MtbRoundCardTile> createState() => _MtbRoundCardTileState();
}

class _MtbRoundCardTileState extends State<_MtbRoundCardTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.selected
        ? AppColors.goldAccent
        : (_focused
              ? AppColors.accentBlue
              : (_hovered ? AppColors.primaryAccent : AppColors.cardBorder));

    return Focus(
      canRequestFocus: !widget.disabled,
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.disabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent.withValues(alpha: 0.18)
                  : (_hovered
                        ? AppColors.surfaceLight
                        : AppColors.background.withValues(alpha: 0.65)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.selected ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? AppColors.goldAccent.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.round.countryCode,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.selected
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.round.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.round.monthLabelPl} • ${widget.round.iconicFeaturePl}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.completedReport != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${widget.completedReport!.playerPosition}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MtbInteractiveChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool disabled;
  final bool compact;
  final VoidCallback onTap;

  const _MtbInteractiveChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.disabled,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_MtbInteractiveChip> createState() => _MtbInteractiveChipState();
}

class _MtbInteractiveChipState extends State<_MtbInteractiveChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (widget.selected
              ? AppColors.primaryAccent.withValues(alpha: 0.28)
              : (_hovered ? AppColors.surfaceLight : AppColors.background));

    final Color borderColor = widget.disabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : (widget.selected
              ? AppColors.goldAccent
              : (_focused
                    ? AppColors.accentBlue
                    : (_hovered
                          ? AppColors.textSecondary
                          : AppColors.cardBorder)));

    return Focus(
      canRequestFocus: !widget.disabled,
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: widget.disabled
              ? null
              : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.disabled ? null : widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: _pressed ? 0.97 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 10 : 12,
                vertical: widget.compact ? 7 : 9,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 14,
                      color: widget.disabled
                          ? AppColors.textSecondary
                          : (widget.selected
                                ? AppColors.goldAccent
                                : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: widget.compact ? 11 : 12,
                        fontWeight: widget.selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: widget.disabled
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _MtbButtonVariant { primary, gold, secondary }

class _MtbActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final _MtbButtonVariant variant;
  final bool disabled;
  final bool fullWidth;
  final VoidCallback onPressed;

  const _MtbActionButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.disabled,
    this.fullWidth = false,
    required this.onPressed,
  });

  @override
  State<_MtbActionButton> createState() => _MtbActionButtonState();
}

class _MtbActionButtonState extends State<_MtbActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = switch (widget.variant) {
      _MtbButtonVariant.primary => AppColors.primaryAccent,
      _MtbButtonVariant.gold => AppColors.goldAccent.withValues(alpha: 0.18),
      _MtbButtonVariant.secondary => AppColors.surfaceLight,
    };
    final Color fgColor = switch (widget.variant) {
      _MtbButtonVariant.primary => AppColors.textPrimary,
      _MtbButtonVariant.gold => AppColors.goldAccent,
      _MtbButtonVariant.secondary => AppColors.textPrimary,
    };

    return Focus(
      canRequestFocus: !widget.disabled,
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: widget.disabled
              ? null
              : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.disabled ? null : widget.onPressed,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: _pressed ? 0.98 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: widget.fullWidth ? double.infinity : null,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: widget.disabled
                    ? AppColors.surfaceLight.withValues(alpha: 0.5)
                    : (_hovered ? baseBg.withValues(alpha: 0.9) : baseBg),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.accentBlue
                      : (widget.variant == _MtbButtonVariant.gold
                            ? AppColors.goldAccent.withValues(alpha: 0.6)
                            : AppColors.cardBorder),
                ),
              ),
              child: Row(
                mainAxisSize:
                    widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.disabled ? AppColors.textSecondary : fgColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            widget.disabled ? AppColors.textSecondary : fgColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MtbIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool disabled;
  final VoidCallback onPressed;

  const _MtbIconButton({
    required this.icon,
    required this.tooltip,
    required this.disabled,
    required this.onPressed,
  });

  @override
  State<_MtbIconButton> createState() => _MtbIconButtonState();
}

class _MtbIconButtonState extends State<_MtbIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.disabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.disabled
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MtbSliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color accentColor;
  final bool disabled;
  final ValueChanged<double> onChanged;

  const _MtbSliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.accentColor,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: disabled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: disabled ? AppColors.textSecondary : accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: disabled ? AppColors.cardBorder : accentColor,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: disabled ? AppColors.textSecondary : accentColor,
            overlayColor: accentColor.withValues(alpha: 0.16),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: disabled ? null : onChanged,
          ),
        ),
      ],
    );
  }
}

class _MtbStepperTile extends StatelessWidget {
  final String label;
  final String valueLabel;
  final bool disabled;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _MtbStepperTile({
    required this.label,
    required this.valueLabel,
    required this.disabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MtbMiniStepButton(
                icon: Icons.remove_rounded,
                disabled: disabled || onDecrement == null,
                onTap: onDecrement,
              ),
              Flexible(
                child: Text(
                  valueLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: disabled
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _MtbMiniStepButton(
                icon: Icons.add_rounded,
                disabled: disabled || onIncrement == null,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MtbMiniStepButton extends StatelessWidget {
  final IconData icon;
  final bool disabled;
  final VoidCallback? onTap;

  const _MtbMiniStepButton({
    required this.icon,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: disabled ? AppColors.cardBorder : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _MtbStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MtbStatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
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
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MtbMetricProgressRow extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _MtbMetricProgressRow({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              '${percent.toStringAsFixed(0)}%',
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
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100.0).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
