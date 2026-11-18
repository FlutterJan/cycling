import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/custom_training_microcycle_builder_service.dart';
import 'package:pro_peloton_manager/services/career/youth_talent_summer_combine_camp.dart';
import 'package:pro_peloton_manager/ui/screens/weekly_training_microcycle_planner_screen.dart';

Rider _buildTestRider({
  String id = 'rider_test_01',
  RiderSpecialization specialization = RiderSpecialization.puncher,
  int potential = 90,
  int ftpWatts = 400,
  double vo2Max = 80.0,
  double ctl = 75.0,
  double atl = 70.0,
  Injury? currentInjury,
}) {
  return Rider(
    id: id,
    firstName: 'Jan',
    lastName: 'Nowak',
    nationalityIso: 'POL',
    birthDate: DateTime(1999, 4, 12),
    potential: potential,
    specialization: specialization,
    physiology: RiderPhysiology(
      heightCm: 178.0,
      weightKg: 67.0,
      bodyFatPercentage: 7.2,
      ftpWatts: ftpWatts,
      wPrimeJoules: 24000,
      vo2Max: vo2Max,
      maxHr: 192,
      restingHr: 38,
      lactateThresholdHr: 174,
      recoveryRate: 1.05,
      glycogenCapacityGrams: 540.0,
      form: ctl,
      fatigue: atl,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1300,
      watts15s: 1080,
      watts30s: 860,
      watts1m: 680,
      watts3m: 505,
      watts5m: 465,
      watts20m: 422,
      watts60m: 398,
    ),
    skills: const RiderSkills(
      cobbles: 76,
      descending: 81,
      bikeHandling: 83,
      aeroPositioning: 78,
      draftingEfficiency: 80,
      raceIq: 84,
      rainResistance: 75,
      heatTolerance: 73,
      timeTrialPositioning: 75,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#E8C3A9',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'sport_shield',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'aero_pro',
      shoeColorHex: '#F3F4F6',
      sockHeightProportion: 0.85,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_player',
      role: RiderRole.coLeader,
      monthlySalaryEur: 60000,
      signingBonusEur: 40000,
      winBonusEur: 12000,
      releaseClauseEur: 2000000,
      contractEndYear: 2028,
      morale: 0.85,
      leaderLoyalty: 82.0,
      requiredRacesIds: [],
    ),
    health: RiderHealth(
      acuteTrainingLoad: atl,
      chronicTrainingLoad: ctl,
      currentInjury: currentInjury,
    ),
    careerPointsUci: 1250,
  );
}

Future<void> _pumpResponsiveWidget(
  WidgetTester tester,
  Size size,
  Widget child,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('Mikrocykle TSS/TSB — CustomTrainingMicrocycleBuilderService', () {
    const service = CustomTrainingMicrocycleBuilderService();

    test('poprawnie wylicza TSS sesji dziennych oraz premię motor-pacing 1.06', () {
      final rest = MicrocycleDaySession.fromType(
        day: MicrocycleDayOfWeek.monday,
        workoutType: TrainingWorkoutType.restDay,
      );
      expect(rest.estimatedTss, 0.0);
      expect(rest.intensityFactor, 0.0);

      final z2 = MicrocycleDaySession.fromType(
        day: MicrocycleDayOfWeek.tuesday,
        workoutType: TrainingWorkoutType.zone2Endurance,
        durationMinutes: 120,
        intensityFactor: 0.70,
      );
      // 2.0 h * 0.70^2 * 100 = 98.0 TSS
      expect(z2.estimatedTss, closeTo(98.0, 0.001));

      final motor = MicrocycleDaySession.fromType(
        day: MicrocycleDayOfWeek.wednesday,
        workoutType: TrainingWorkoutType.motorPacing,
        durationMinutes: 120,
        intensityFactor: 0.90,
      );
      // 2.0 h * 0.90^2 * 100 * 1.06 = 171.72 TSS
      expect(motor.behindMotorPacer, isTrue);
      expect(motor.estimatedTss, closeTo(171.72, 0.001));
    });

    test('buduje presety 7-dniowe i zachowuje spójność JSON round-trip', () {
      final vo2 = service.buildPresetMicrocycle(MicrocycleGoalPreset.vo2maxPeak);
      final sweetSpot =
          service.buildPresetMicrocycle(MicrocycleGoalPreset.sweetSpotBase);
      final motor =
          service.buildPresetMicrocycle(MicrocycleGoalPreset.motorPacingClassics);
      final taper =
          service.buildPresetMicrocycle(MicrocycleGoalPreset.taperingPreRace);

      expect(vo2.sessions.length, 7);
      expect(sweetSpot.sessions.length, 7);
      expect(motor.sessions.length, 7);
      expect(taper.sessions.length, 7);
      expect(taper.totalWeeklyTss, lessThan(sweetSpot.totalWeeklyTss));
      expect(taper.totalWeeklyTss, lessThan(vo2.totalWeeklyTss));

      final restored = WeeklyTrainingMicrocycle.fromJson(vo2.toJson());
      expect(restored.id, vo2.id);
      expect(restored.name, vo2.name);
      expect(restored.preset, vo2.preset);
      expect(restored.sessions.length, 7);
      expect(restored.totalWeeklyTss, closeTo(vo2.totalWeeklyTss, 0.001));
    });

    test('waliduje błędy strukturalne oraz ostrzeżenia przeciążenia TSS', () {
      final invalidShort = WeeklyTrainingMicrocycle(
        id: 'invalid_short',
        name: 'Za krótki',
        preset: MicrocycleGoalPreset.custom,
        createdAt: DateTime(2026, 3, 1),
        sessions: [
          MicrocycleDaySession.fromType(
            day: MicrocycleDayOfWeek.monday,
            workoutType: TrainingWorkoutType.zone2Endurance,
          ),
          MicrocycleDaySession.fromType(
            day: MicrocycleDayOfWeek.monday,
            workoutType: TrainingWorkoutType.sweetSpot,
            durationMinutes: 0,
          ),
        ],
      );

      final invalidReport = service.validateMicrocycle(invalidShort);
      expect(invalidReport.isValid, isFalse);
      expect(invalidReport.errors.length, greaterThanOrEqualTo(2));

      final extremeOverload = WeeklyTrainingMicrocycle(
        id: 'overload',
        name: 'Ekstremalne obciążenie',
        preset: MicrocycleGoalPreset.custom,
        createdAt: DateTime(2026, 3, 1),
        sessions: MicrocycleDayOfWeek.values
            .map(
              (d) => MicrocycleDaySession.fromType(
                day: d,
                workoutType: TrainingWorkoutType.vo2maxIntervals,
                durationMinutes: 220,
                intensityFactor: 1.05,
              ),
            )
            .toList(),
      );

      final overloadReport = service.validateMicrocycle(extremeOverload);
      expect(overloadReport.isValid, isTrue);
      expect(overloadReport.warnings.length, greaterThanOrEqualTo(3));
      expect(extremeOverload.hasThreeConsecutiveHardDays, isTrue);
      expect(extremeOverload.recoveryDaysCount, 0);
      expect(extremeOverload.totalWeeklyTss, greaterThan(1150));
    });

    test('symuluje model Banistera CTL/ATL/TSB i wykrywa ryzyko przetrenowania', () {
      final rider = _buildTestRider(ctl: 75.0, atl: 70.0);

      final taper =
          service.buildPresetMicrocycle(MicrocycleGoalPreset.taperingPreRace);
      final taperProj =
          service.simulateMicrocycleForRider(microcycle: taper, rider: rider);

      expect(taperProj.dailyProjections.length, 7);
      expect(taperProj.initialTsb, closeTo(5.0, 0.001));
      expect(taperProj.projectedTsb, greaterThan(taperProj.initialTsb));
      expect(taperProj.riskLevel, MicrocycleRiskLevel.optimal);

      final extreme = WeeklyTrainingMicrocycle(
        id: 'extreme_hit',
        name: '7 dni HIT',
        preset: MicrocycleGoalPreset.custom,
        createdAt: DateTime(2026, 3, 2),
        sessions: MicrocycleDayOfWeek.values
            .map(
              (d) => MicrocycleDaySession.fromType(
                day: d,
                workoutType: TrainingWorkoutType.vo2maxIntervals,
                durationMinutes: 200,
                intensityFactor: 1.0,
              ),
            )
            .toList(),
      );
      final extremeProj =
          service.simulateMicrocycleForRider(microcycle: extreme, rider: rider);

      expect(extremeProj.projectedAtl, greaterThan(rider.health.acuteTrainingLoad));
      expect(extremeProj.projectedTsb, lessThan(-22.0));
      expect(extremeProj.riskLevel, MicrocycleRiskLevel.overtrainingDanger);
    });

    test('aplikuje mikrocykl zdrowemu kolarzowi i blokuje kontuzjowanego', () {
      final vo2 = service.buildPresetMicrocycle(MicrocycleGoalPreset.vo2maxPeak);
      final healthyRider = _buildTestRider(
        specialization: RiderSpecialization.puncher,
        ftpWatts: 400,
        ctl: 76.0,
        atl: 68.0,
      );

      final okResult = service.applyMicrocycleToRider(
        microcycle: vo2,
        rider: healthyRider,
      );
      expect(okResult.success, isTrue);
      expect(
        okResult.updatedRider.physiology.ftpWatts,
        greaterThanOrEqualTo(healthyRider.physiology.ftpWatts),
      );
      expect(
        okResult.updatedRider.physiology.vo2Max,
        greaterThan(healthyRider.physiology.vo2Max),
      );
      expect(
        okResult.updatedRider.health.chronicTrainingLoad,
        closeTo(okResult.projection.projectedCtl, 0.001),
      );
      expect(
        okResult.updatedRider.health.acuteTrainingLoad,
        closeTo(okResult.projection.projectedAtl, 0.001),
      );

      final injuredRider = _buildTestRider(
        currentInjury: const Injury(
          name: 'Złamany obojczyk',
          type: InjuryType.clavicleFracture,
          daysRemaining: 21,
          trainingAllowed: false,
        ),
      );
      final blockedResult = service.applyMicrocycleToRider(
        microcycle: vo2,
        rider: injuredRider,
      );
      expect(blockedResult.success, isFalse);
      expect(blockedResult.updatedRider, injuredRider);
      expect(blockedResult.message, contains('zablokowany'));
    });

    test('CustomTrainingMicrocycleNotifier zarządza szablonami, zamianą dni i zapisem', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(customTrainingMicrocycleProvider.notifier);
      final initial = container.read(customTrainingMicrocycleProvider);
      expect(initial.savedTemplates.length, 4);
      expect(initial.activeMicrocycle.preset, MicrocycleGoalPreset.vo2maxPeak);

      final monBefore = initial.activeMicrocycle.sessions
          .firstWhere((s) => s.day == MicrocycleDayOfWeek.monday)
          .workoutType;
      final tueBefore = initial.activeMicrocycle.sessions
          .firstWhere((s) => s.day == MicrocycleDayOfWeek.tuesday)
          .workoutType;

      notifier.swapDays(MicrocycleDayOfWeek.monday, MicrocycleDayOfWeek.tuesday);
      final afterSwap = container.read(customTrainingMicrocycleProvider);
      expect(
        afterSwap.activeMicrocycle.sessions
            .firstWhere((s) => s.day == MicrocycleDayOfWeek.monday)
            .workoutType,
        tueBefore,
      );
      expect(
        afterSwap.activeMicrocycle.sessions
            .firstWhere((s) => s.day == MicrocycleDayOfWeek.tuesday)
            .workoutType,
        monBefore,
      );

      notifier.updateDayWorkoutType(
        MicrocycleDayOfWeek.wednesday,
        TrainingWorkoutType.motorPacing,
      );
      notifier.updateDayDuration(MicrocycleDayOfWeek.wednesday, 150);
      notifier.updateDayIntensityFactor(MicrocycleDayOfWeek.wednesday, 0.92);
      notifier.updateMicrocycleName('Mój Blok Wiosenny');
      notifier.saveCurrentAsTemplate();

      final afterSave = container.read(customTrainingMicrocycleProvider);
      expect(afterSave.savedTemplates.length, 5);
      expect(afterSave.activeMicrocycle.name, 'Mój Blok Wiosenny');

      final applied = notifier.applyActiveMicrocycle();
      expect(applied.success, isTrue);
    });
  });

  group('Obóz Selekcyjny Juniorów — YouthTalentSummerCombineCampService', () {
    const combineService = YouthTalentSummerCombineCampService();

    test('uruchamia edycję z Mgłą Wojny, testuje stacje lab i zawęża widełki potencjału', () {
      final edition = combineService.launchAnnualCombine(
        seasonYear: 2026,
        location: CombineCampLocation.gironaCatalonia,
        candidateCount: 16,
        maxSlotsToSign: 3,
        random: math.Random(42),
      );

      expect(edition.candidates.length, 16);
      expect(edition.phase, CombineCampPhase.labTestingInProgress);
      expect(
        edition.budgetSpentEur,
        CombineCampLocation.gironaCatalonia.organizationCostEur,
      );
      for (final c in edition.candidates) {
        expect(c.rider.birthDate.year, 2026 - 17);
        expect(c.potentialSpread, greaterThan(0));
      }

      final target = edition.candidates.first;
      final initialSpread = target.potentialSpread;
      final stationOutcome = combineService.runLabTestStation(
        edition: edition,
        candidateId: target.id,
        station: CombineTestStation.vo2MaxLabRamp,
        scoutSkill: 92,
        availableBudgetEur: 200000,
        random: math.Random(7),
      );

      expect(stationOutcome.success, isTrue);
      expect(stationOutcome.costEur, CombineTestStation.vo2MaxLabRamp.testFeeEur);

      final testedCandidate =
          stationOutcome.updatedEdition.findCandidate(target.id)!;
      expect(testedCandidate.testedStations.length, 1);
      expect(testedCandidate.potentialSpread, lessThanOrEqualTo(initialSpread));
      expect(testedCandidate.combineCompositeScore, greaterThan(0.0));
      expect(testedCandidate.status, CombineCandidateStatus.tested);

      // Ponowne wykonanie tej samej stacji powinno zostać odrzucone
      final duplicateOutcome = combineService.runLabTestStation(
        edition: stationOutcome.updatedEdition,
        candidateId: target.id,
        station: CombineTestStation.vo2MaxLabRamp,
        random: math.Random(7),
      );
      expect(duplicateOutcome.success, isFalse);
    });

    test('wykonuje Batch Lab, symuluje wyścig 85 km, shortlistuje, podpisuje i zamyka obóz', () {
      final edition = combineService.launchAnnualCombine(
        seasonYear: 2027,
        location: CombineCampLocation.sierraNevadaAltitude,
        candidateCount: 12,
        maxSlotsToSign: 2,
        random: math.Random(101),
      );

      final batchOutcome = combineService.runBatchLabTestsForAll(
        edition: edition,
        scoutSkill: 85,
        availableBudgetEur: 500000,
        random: math.Random(102),
      );
      expect(batchOutcome.success, isTrue);
      expect(
        batchOutcome.updatedEdition.candidates.every((c) => c.isFullyLabTested),
        isTrue,
      );

      final raceOutcome = combineService.simulateSelectionRoadRace(
        edition: batchOutcome.updatedEdition,
        courseMountainWeight: 0.55,
        courseSprintWeight: 0.25,
        random: math.Random(103),
      );
      expect(raceOutcome.success, isTrue);
      expect(
        raceOutcome.updatedEdition.phase,
        CombineCampPhase.draftingWindowOpen,
      );
      expect(raceOutcome.updatedEdition.isSelectionRaceCompleted, isTrue);

      final sortedByRace = combineService.filterAndSortCandidates(
        candidates: raceOutcome.updatedEdition.candidates,
        sortBy: CombineSortField.selectionRaceRank,
      );
      expect(sortedByRace.first.raceResult?.rank, 1);
      expect(sortedByRace.first.raceResult?.timeGapSeconds, 0);

      // Shortlist toggle
      final winner = sortedByRace.first;
      final shortlistedEdition = combineService.toggleShortlist(
        edition: raceOutcome.updatedEdition,
        candidateId: winner.id,
      );
      expect(
        shortlistedEdition.findCandidate(winner.id)?.status,
        CombineCandidateStatus.shortlisted,
      );

      // Podpisanie #1 do Akademii U19/U23
      final signAcademy = combineService.signTalentFromCombine(
        edition: shortlistedEdition,
        candidateId: winner.id,
        targetTeamId: 'team_player',
        availableBudgetEur: 250000,
        toSeniorProSquad: false,
      );
      expect(signAcademy.success, isTrue);
      expect(signAcademy.signedRider?.contract.monthlySalaryEur, 1850);
      final signedWinner = signAcademy.updatedEdition.findCandidate(winner.id)!;
      expect(signedWinner.status, CombineCandidateStatus.signedToAcademy);
      expect(
        signedWinner.estimatedPotentialMin,
        signedWinner.hiddenTruePotential,
      );
      expect(
        signedWinner.estimatedPotentialMax,
        signedWinner.hiddenTruePotential,
      );

      // Podpisanie #2 bezpośrednio do kadry Pro
      final runnerUp = sortedByRace[1];
      final signPro = combineService.signTalentFromCombine(
        edition: signAcademy.updatedEdition,
        candidateId: runnerUp.id,
        targetTeamId: 'team_player',
        availableBudgetEur: 250000,
        toSeniorProSquad: true,
      );
      expect(signPro.success, isTrue);
      expect(signPro.signedRider?.contract.monthlySalaryEur, 3600);
      expect(signPro.updatedEdition.remainingSignSlots, 0);

      // Limit 2 slotów osiągnięty -> 3. podpis zablokowany
      final thirdBlocked = combineService.signTalentFromCombine(
        edition: signPro.updatedEdition,
        candidateId: sortedByRace[2].id,
        targetTeamId: 'team_player',
        availableBudgetEur: 250000,
      );
      expect(thirdBlocked.success, isFalse);

      // Zamknięcie obozu i zapis JSON round-trip
      final concluded = combineService.concludeCombineCamp(
        edition: signPro.updatedEdition,
      );
      expect(concluded.edition.phase, CombineCampPhase.concluded);
      expect(concluded.historyEntry.signedCount, 2);

      final restoredEdition =
          CombineCampEdition.fromJson(concluded.edition.toJson());
      expect(restoredEdition.seasonYear, concluded.edition.seasonYear);
      expect(restoredEdition.candidates.length, 12);
      expect(restoredEdition.signedCandidateIds.length, 2);

      final restoredHistory =
          CombineCampHistoryEntry.fromJson(concluded.historyEntry.toJson());
      expect(restoredHistory.signedCount, 2);
      expect(restoredHistory.location, CombineCampLocation.sierraNevadaAltitude);
    });

    test('YouthTalentSummerCombineNotifier obsługuje cały cykl edycji obozu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(youthTalentSummerCombineProvider.notifier);
      notifier.launchNewEdition(
        seasonYear: 2028,
        location: CombineCampLocation.calpeAlicante,
        candidateCount: 10,
        maxSlotsToSign: 2,
        random: math.Random(99),
      );
      notifier.runBatchLabForAll(scoutSkill: 82, random: math.Random(99));
      notifier.simulateSelectionRace(random: math.Random(99));

      final afterRace = container.read(youthTalentSummerCombineProvider);
      expect(afterRace.activeEdition, isNotNull);
      expect(afterRace.activeEdition!.isSelectionRaceCompleted, isTrue);

      final firstId = afterRace.activeEdition!.candidates.first.id;
      notifier.signCandidate(candidateId: firstId, toSeniorProSquad: false);
      notifier.concludeActiveCamp();

      final concludedState = container.read(youthTalentSummerCombineProvider);
      expect(concludedState.activeEdition?.phase, CombineCampPhase.concluded);
      expect(concludedState.history.length, 1);
      expect(concludedState.history.first.signedCount, 1);
    });
  });

  group('Responsywność UI mikrocykli i obozu juniorów', () {
    for (final entry in const <String, Size>{
      '390x844 (mobile)': Size(390, 844),
      '1024x768 (tablet)': Size(1024, 768),
      '1600x900 (desktop)': Size(1600, 900),
    }.entries) {
      testWidgets(
        'WeeklyTrainingMicrocyclePlannerScreen renderuje się bez przepełnień w ${entry.key}',
        (tester) async {
          await _pumpResponsiveWidget(
            tester,
            entry.value,
            const WeeklyTrainingMicrocyclePlannerScreen(),
          );

          expect(find.byType(WeeklyTrainingMicrocyclePlannerScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'YouthTalentSummerCombineCampPanel renderuje się bez przepełnień w ${entry.key}',
        (tester) async {
          await _pumpResponsiveWidget(
            tester,
            entry.value,
            const Scaffold(
              body: SingleChildScrollView(
                child: YouthTalentSummerCombineCampPanel(),
              ),
            ),
          );

          expect(find.byType(YouthTalentSummerCombineCampPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
