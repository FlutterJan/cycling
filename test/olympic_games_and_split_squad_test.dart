import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/simulation/multi_race_parallel_day_simulator.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/olympic_games_quadrennial_cycle_service.dart';
import 'package:pro_peloton_manager/ui/screens/olympic_games_hub_and_medal_table_screen.dart';
import 'package:pro_peloton_manager/ui/widgets/split_squad_calendar_assignment_modal.dart';

Rider _buildOlympicCandidate({
  required String id,
  required String firstName,
  required String lastName,
  required String nationalityIso,
  int ftpWatts = 415,
  double weightKg = 68.0,
  int raceIq = 85,
  int ttPos = 82,
  int aeroPos = 82,
  int careerPoints = 1800,
  Injury? injury,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: nationalityIso,
    birthDate: DateTime(1998, 6, 15),
    potential: 92,
    specialization: RiderSpecialization.puncher,
    physiology: RiderPhysiology(
      heightCm: 179.0,
      weightKg: weightKg,
      bodyFatPercentage: 6.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: 24500,
      vo2Max: 84.0,
      maxHr: 194,
      restingHr: 38,
      lactateThresholdHr: 176,
      recoveryRate: 1.15,
      glycogenCapacityGrams: 580.0,
      form: 88.0,
      fatigue: 20.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: 1340,
      watts15s: 1120,
      watts30s: 900,
      watts1m: 690,
      watts3m: 530,
      watts5m: 480,
      watts20m: ftpWatts + 20,
      watts60m: ftpWatts,
    ),
    skills: RiderSkills(
      cobbles: 79,
      descending: 85,
      bikeHandling: 86,
      aeroPositioning: aeroPos,
      draftingEfficiency: 83,
      raceIq: raceIq,
      rainResistance: 80,
      heatTolerance: 80,
      timeTrialPositioning: ttPos,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F2C9AC',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_gold',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'pro_aero',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.48,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_1',
      role: RiderRole.teamLeader,
      monthlySalaryEur: 85000,
      signingBonusEur: 50000,
      winBonusEur: 25000,
      releaseClauseEur: 1200000,
      contractEndYear: 2031,
      morale: 0.9,
      leaderLoyalty: 0.85,
      requiredRacesIds: [],
    ),
    health: RiderHealth(
      acuteTrainingLoad: 64.0,
      chronicTrainingLoad: 82.0,
      currentInjury: injury,
    ),
    careerPointsUci: careerPoints,
  );
}

List<Rider> _buildInternationalOlympicPool() {
  return [
    _buildOlympicCandidate(
      id: 'bel_1',
      firstName: 'Remco',
      lastName: 'Aero',
      nationalityIso: 'BEL',
      ftpWatts: 440,
      weightKg: 62.0,
      raceIq: 92,
      ttPos: 98,
      aeroPos: 98,
      careerPoints: 5000,
    ),
    _buildOlympicCandidate(
      id: 'bel_2',
      firstName: 'Wout',
      lastName: 'Classic',
      nationalityIso: 'BEL',
      ftpWatts: 445,
      weightKg: 76.0,
      raceIq: 90,
      ttPos: 93,
      aeroPos: 91,
      careerPoints: 4100,
    ),
    _buildOlympicCandidate(
      id: 'bel_3',
      firstName: 'Jasper',
      lastName: 'Sprint',
      nationalityIso: 'BEL',
      ftpWatts: 410,
      weightKg: 74.0,
      raceIq: 84,
      careerPoints: 3200,
    ),
    _buildOlympicCandidate(
      id: 'bel_4',
      firstName: 'Tiesj',
      lastName: 'Dom',
      nationalityIso: 'BEL',
      ftpWatts: 398,
      weightKg: 71.0,
      raceIq: 86,
      careerPoints: 1900,
    ),
    _buildOlympicCandidate(
      id: 'bel_5',
      firstName: 'Yves',
      lastName: 'Reserve',
      nationalityIso: 'BEL',
      ftpWatts: 382,
      weightKg: 72.0,
      raceIq: 80,
      careerPoints: 950,
    ),
    _buildOlympicCandidate(
      id: 'bel_6_inj',
      firstName: 'Injured',
      lastName: 'Star',
      nationalityIso: 'BEL',
      ftpWatts: 460,
      injury: const Injury(
        name: 'Clavicle',
        type: InjuryType.clavicleFracture,
        daysRemaining: 21,
        trainingAllowed: false,
      ),
    ),
    _buildOlympicCandidate(
      id: 'pol_1',
      firstName: 'Michał',
      lastName: 'Orzeł',
      nationalityIso: 'POL',
      ftpWatts: 420,
      weightKg: 67.0,
      raceIq: 93,
      ttPos: 90,
      aeroPos: 90,
      careerPoints: 2800,
    ),
    _buildOlympicCandidate(
      id: 'pol_2',
      firstName: 'Filip',
      lastName: 'Sokół',
      nationalityIso: 'POL',
      ftpWatts: 405,
      weightKg: 73.0,
      raceIq: 84,
      ttPos: 86,
      aeroPos: 85,
      careerPoints: 1700,
    ),
    _buildOlympicCandidate(
      id: 'fra_1',
      firstName: 'Valentin',
      lastName: 'Bleu',
      nationalityIso: 'FRA',
      ftpWatts: 424,
      weightKg: 66.0,
      raceIq: 88,
      careerPoints: 3000,
    ),
    _buildOlympicCandidate(
      id: 'slo_1',
      firstName: 'Tadej',
      lastName: 'Apex',
      nationalityIso: 'SLO',
      ftpWatts: 448,
      weightKg: 65.0,
      raceIq: 94,
      ttPos: 94,
      aeroPos: 92,
      careerPoints: 5200,
    ),
  ];
}

void main() {
  group('Olympic Games 4-Year Cycle, No Race Radio & Gold Gear', () {
    test('enforces 4-year cycle, host editions and seasonal phases', () {
      final service = OlympicGamesQuadrennialCycleService();

      expect(service.isOlympicYear(2024), isTrue);
      expect(service.isOlympicYear(2025), isFalse);
      expect(service.isOlympicYear(2026), isFalse);
      expect(service.isOlympicYear(2027), isFalse);
      expect(service.isOlympicYear(2028), isTrue);
      expect(service.isOlympicYear(2032), isTrue);
      expect(service.isOlympicYear(2036), isTrue);

      expect(service.nextOlympicYear(2025), 2028);
      expect(service.yearsUntilNextOlympics(2025), 3);
      expect(service.nextOlympicYear(2028), 2028);
      expect(service.yearsUntilNextOlympics(2028), 0);

      expect(
        service.evaluateCyclePhase(DateTime(2026, 7, 12)),
        OlympicCyclePhase.offCycle,
      );
      expect(
        service.evaluateCyclePhase(DateTime(2028, 4, 15)),
        OlympicCyclePhase.qualificationWindow,
      );
      expect(
        service.evaluateCyclePhase(DateTime(2028, 8, 5)),
        OlympicCyclePhase.olympicGamesWindow,
      );

      final paris = service.getEditionForYear(2024);
      final la = service.getEditionForYear(2028);
      final brisbane = service.getEditionForYear(2032);
      expect(paris.hostCity, 'Paryż');
      expect(la.hostCity, 'Los Angeles');
      expect(brisbane.year, 2032);
    });

    test('enforces No Race Radio rules and autonomous rider decisions', () {
      final service = OlympicGamesQuadrennialCycleService();
      final rrRules = service.getNoRaceRadioRules(OlympicDiscipline.roadRace);
      final ittRules =
          service.getNoRaceRadioRules(OlympicDiscipline.individualTimeTrial);

      expect(rrRules.raceRadioEnabled, isFalse);
      expect(rrRules.canReceiveLiveTimeGaps, isFalse);
      expect(rrRules.canIssueInstantTacticalOrders, isFalse);
      expect(rrRules.motoChalkboardDelaySeconds, greaterThan(0));
      expect(rrRules.breakawayChaosMultiplier, greaterThan(1.0));
      expect(ittRules.raceRadioEnabled, isFalse);

      final pool = _buildInternationalOlympicPool();
      final highIqDecision = service.evaluateNoRadioRiderDecision(
        rider: pool.first,
        actualGapToBreakawaySeconds: 50,
        distanceRemainingKm: 12.0,
        nearestTeammateDistanceMeters: 18.0,
        seed: 42,
      );
      final isolatedLowIqDecision = service.evaluateNoRadioRiderDecision(
        rider: _buildOlympicCandidate(
          id: 'low_iq',
          firstName: 'Solo',
          lastName: 'Rider',
          nationalityIso: 'USA',
          raceIq: 58,
        ),
        actualGapToBreakawaySeconds: 95,
        distanceRemainingKm: 35.0,
        nearestTeammateDistanceMeters: 180.0,
        seed: 42,
      );

      expect(highIqDecision.teammateInVisualContact, isTrue);
      expect(isolatedLowIqDecision.teammateInVisualContact, isFalse);
      expect(
        highIqDecision.tacticalAccuracy,
        greaterThanOrEqualTo(isolatedLowIqDecision.tacticalAccuracy),
      );
      expect(highIqDecision.rationale, isNotEmpty);
    });

    test('enforces small national quotas (max 4 RR / max 2 ITT) and injury filter',
        () {
      final service = OlympicGamesQuadrennialCycleService();
      final pool = _buildInternationalOlympicPool();

      final belRr = service.buildNationalTeamRoster(
        olympicYear: 2028,
        nationalityIso: 'BEL',
        discipline: OlympicDiscipline.roadRace,
        worldRiders: pool,
        nationUciRank: 1,
      );
      expect(belRr.maxAllowedQuota, 4);
      expect(belRr.squadSize, 4);
      expect(belRr.isWithinOlympicLimit, isTrue);
      expect(belRr.selectedRiderIds, isNot(contains('bel_6_inj')));
      expect(belRr.selectedRiderIds, isNot(contains('bel_5')));

      final belItt = service.buildNationalTeamRoster(
        olympicYear: 2028,
        nationalityIso: 'BEL',
        discipline: OlympicDiscipline.individualTimeTrial,
        worldRiders: pool,
        nationUciRank: 1,
      );
      expect(belItt.maxAllowedQuota, 2);
      expect(belItt.squadSize, 2);
      expect(belItt.isWithinOlympicLimit, isTrue);
    });

    test('awards Gold Helmet & Frame for 4 years, expires next cycle, and roundtrips JSON',
        () {
      final service = OlympicGamesQuadrennialCycleService();
      final pool = _buildInternationalOlympicPool();

      final rrReport = service.simulateOlympicRace(
        olympicYear: 2028,
        discipline: OlympicDiscipline.roadRace,
        worldRiders: pool,
        nationUciRanks: {'BEL': 1, 'SLO': 2, 'FRA': 4, 'POL': 8},
        seed: 2028,
      );
      final ittReport = service.simulateOlympicRace(
        olympicYear: 2028,
        discipline: OlympicDiscipline.individualTimeTrial,
        worldRiders: pool,
        nationUciRanks: {'BEL': 1, 'SLO': 2, 'FRA': 4, 'POL': 8},
        seed: 2029,
      );

      expect(rrReport.goldMedalist?.medal, OlympicMedalTier.gold);
      expect(rrReport.awardedGoldGear, isNotNull);
      expect(ittReport.goldMedalist?.medal, OlympicMedalTier.gold);

      final rrChampId = rrReport.goldMedalist!.riderId;
      final appearance2028 = service.resolveEquipmentAppearanceForRace(
        riderId: rrChampId,
        currentYear: 2028,
        raceDiscipline: OlympicDiscipline.roadRace,
      );
      final appearance2031 = service.resolveEquipmentAppearanceForRace(
        riderId: rrChampId,
        currentYear: 2031,
        raceDiscipline: OlympicDiscipline.roadRace,
      );
      final appearance2032 = service.resolveEquipmentAppearanceForRace(
        riderId: rrChampId,
        currentYear: 2032,
        raceDiscipline: OlympicDiscipline.roadRace,
      );

      expect(appearance2028.usesGoldHelmet, isTrue);
      expect(appearance2028.usesGoldFrame, isTrue);
      expect(appearance2028.helmetHex, '#D4AF37');
      expect(appearance2031.usesGoldHelmet, isTrue);
      expect(appearance2032.usesGoldHelmet, isFalse);

      final medalTable = OlympicMedalTableAggregator.buildMedalTable(
        olympicYear: 2028,
        reports: [rrReport, ittReport],
        playerNationalityIso: 'POL',
        service: service,
      );
      expect(medalTable, isNotEmpty);
      expect(
        medalTable.first.goldCount,
        greaterThanOrEqualTo(medalTable.last.goldCount),
      );

      final restored =
          OlympicGamesQuadrennialCycleService.fromJson(service.toJson());
      expect(restored.goldGearRegistry.length, 2);
      expect(restored.simulationHistory.length, 2);
    });
  });

  group('Parallel Races & 28-Rider Split Squad Simulation', () {
    test('splits 28-rider squad across Front A, Front B & Reserve without overlap',
        () {
      final squad = MultiRaceParallelDaySimulator.generateSample28RiderSquad();
      expect(squad.length, 28);
      expect(squad.where((r) => !r.isFitToRace).length, 1);

      const frontA = ParallelRaceEventSpec(
        raceId: 'tdf_s14',
        raceName: 'Tour de France',
        stageNumber: 14,
        stageName: 'Col du Tourmalet',
        terrain: ParallelRaceTerrain.highMountain,
        tier: ParallelRaceTier.grandTour,
        distanceKm: 178.0,
        elevationGainM: 4100,
        requiredMinRiders: 8,
        requiredMaxRiders: 8,
      );
      const frontB = ParallelRaceEventSpec(
        raceId: 'poland_s2',
        raceName: 'Tour de Pologne',
        stageNumber: 2,
        stageName: 'Katowice Sprint',
        terrain: ParallelRaceTerrain.flat,
        tier: ParallelRaceTier.worldTourStage,
        distanceKm: 182.0,
        elevationGainM: 950,
        requiredMinRiders: 7,
        requiredMaxRiders: 7,
      );

      for (final strategy in ParallelSplitStrategy.values) {
        final assignments =
            MultiRaceParallelDaySimulator.autoSplitSquadForTwoFronts(
          squad: squad,
          frontA: frontA,
          frontB: frontB,
          strategy: strategy,
        );
        final validation = MultiRaceParallelDaySimulator.validateSplit(
          squad: squad,
          assignments: assignments,
          frontA: frontA,
          frontB: frontB,
        );

        expect(validation.isValid, isTrue, reason: 'Failed for $strategy');
        expect(validation.frontACount, 8);
        expect(validation.frontBCount, 7);
        expect(validation.reserveCount, 13);
        expect(validation.duplicateRiderIds, isEmpty);
      }
    });

    test('assigns unique terrain-matched bikes across both fronts & catches conflicts',
        () {
      final defaults = ParallelDaySimulatorState.initialDefault();
      final fleet = SplitSquadBikeCatalog.generateTeamFleet();
      expect(fleet.length, greaterThanOrEqualTo(30));

      final bikeAssignments = SplitSquadBikeCatalog.autoAssignBikes(
        squad: defaults.squad,
        riderAssignments: defaults.assignments,
        fleet: fleet,
        frontA: defaults.frontAEvent,
        frontB: defaults.frontBEvent,
      );

      final validResult = SplitSquadBikeCatalog.validateBikeAssignments(
        squad: defaults.squad,
        riderAssignments: defaults.assignments,
        bikeAssignments: bikeAssignments,
        fleet: fleet,
        frontA: defaults.frontAEvent,
        frontB: defaults.frontBEvent,
      );
      expect(validResult.isValid, isTrue);
      expect(validResult.missingRiderIds, isEmpty);
      expect(validResult.duplicateBikeIds, isEmpty);

      final frontARider = defaults.assignments.entries
          .firstWhere((e) => e.value == ParallelFrontSlot.frontA)
          .key;
      final frontBRider = defaults.assignments.entries
          .firstWhere((e) => e.value == ParallelFrontSlot.frontB)
          .key;
      final conflictedBikes = Map<String, String>.from(bikeAssignments)
        ..[frontBRider] = bikeAssignments[frontARider]!;

      final invalidResult = SplitSquadBikeCatalog.validateBikeAssignments(
        squad: defaults.squad,
        riderAssignments: defaults.assignments,
        bikeAssignments: conflictedBikes,
        fleet: fleet,
        frontA: defaults.frontAEvent,
        frontB: defaults.frontBEvent,
      );
      expect(invalidResult.isValid, isFalse);
      expect(
        invalidResult.duplicateBikeIds,
        contains(bikeAssignments[frontARider]),
      );
    });

    test('runs deterministic parallel race day simulation & integrates Olympic Gold Gear',
        () {
      final olympicService = OlympicGamesQuadrennialCycleService();
      final pool = _buildInternationalOlympicPool();
      final olympicReport = olympicService.simulateOlympicRace(
        olympicYear: 2028,
        discipline: OlympicDiscipline.roadRace,
        worldRiders: pool,
        nationUciRanks: {'BEL': 1, 'SLO': 2, 'FRA': 4, 'POL': 8},
        seed: 2028,
      );
      final champId = olympicReport.goldMedalist!.riderId;

      final state = ParallelDaySimulatorState.initialDefault();
      final reportA = MultiRaceParallelDaySimulator.simulateParallelRaceDay(
        calendarDate: DateTime(2029, 7, 14),
        squad: state.squad,
        assignments: state.assignments,
        frontA: state.frontAEvent,
        frontB: state.frontBEvent,
        staffSplit: state.staffSplit,
        seed: 909,
      );
      final reportB = MultiRaceParallelDaySimulator.simulateParallelRaceDay(
        calendarDate: DateTime(2029, 7, 14),
        squad: state.squad,
        assignments: state.assignments,
        frontA: state.frontAEvent,
        frontB: state.frontBEvent,
        staffSplit: state.staffSplit,
        seed: 909,
      );

      expect(reportA.frontAResult.riderOutcomes.length, 7);
      expect(reportA.frontBResult.riderOutcomes.length, 7);
      expect(reportA.reserveRiderIds.length, 14);
      expect(reportA.reserveTsbRecoveryDelta, 4.5);
      expect(
        reportA.combinedUciPoints,
        reportA.frontAResult.totalUciPoints + reportA.frontBResult.totalUciPoints,
      );
      expect(reportA.frontAResult.bestTeamRank, reportB.frontAResult.bestTeamRank);
      expect(reportA.frontBResult.bestTeamRank, reportB.frontBResult.bestTeamRank);

      // Olympic Champion retains Gold Helmet & Gold Frame in 2029 parallel race calendar
      final champAppearance2029 = olympicService.resolveEquipmentAppearanceForRace(
        riderId: champId,
        currentYear: 2029,
        raceDiscipline: OlympicDiscipline.roadRace,
      );
      expect(champAppearance2029.usesGoldHelmet, isTrue);
      expect(champAppearance2029.usesGoldFrame, isTrue);
    });
  });

  group('Responsive UI: Olympic Hub & Split Squad Modal (390x844 / 1024x768 / 1600x900)',
      () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'OlympicGamesHubAndMedalTableScreen renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const MaterialApp(
              home: OlympicGamesHubAndMedalTableScreen(
                playerNationalityIso: 'POL',
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.textContaining('IGRZYSKA OLIMPIJSKIE'), findsOneWidget);
          expect(find.textContaining('TABELA MEDALOWA PAŃSTW'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'SplitSquadCalendarAssignmentModal renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: SplitSquadCalendarAssignmentModal(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Przydział Kolarzy i Rowerów'), findsOneWidget);
          expect(find.text('Zatwierdź Skład i Sprzęt'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('OlympicHub & SplitSquadModal respect isReadOnly disabled state',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SplitSquadCalendarAssignmentResult? confirmed;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SplitSquadCalendarAssignmentModal(
                isReadOnly: true,
                onConfirm: (res) => confirmed = res,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Zatwierdź Skład i Sprzęt'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(confirmed, isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
