import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/tandem_and_handbike_physics_solver.dart';
import 'package:pro_peloton_manager/models/paracycling/uci_paracycling_tandem_handbike_model.dart';

void main() {
  late ParacyclingBikeSpec tandemRoadBike;
  late ParacyclingBikeSpec tandemTtBike;
  late ParacyclingBikeSpec recumbentHandbike;
  late ParacyclingBikeSpec kneelingHandbike;
  late TandemCrewPairing eliteCrew;
  late ParacyclingAthleteProfile recumbentAthlete;
  late ParacyclingAthleteProfile kneelingAthlete;

  setUp(() {
    final fleet = ParacyclingBikeSpec.defaultFleet();
    tandemRoadBike = fleet.firstWhere(
      (b) => b.equipmentType == ParacyclingEquipmentType.tandemRoadBike,
    );
    tandemTtBike = fleet.firstWhere(
      (b) => b.equipmentType == ParacyclingEquipmentType.tandemTimeTrialBike,
    );
    recumbentHandbike = fleet.firstWhere(
      (b) => b.equipmentType == ParacyclingEquipmentType.recumbentHandbike,
    );
    kneelingHandbike = fleet.firstWhere(
      (b) => b.equipmentType == ParacyclingEquipmentType.kneelingHandbike,
    );

    eliteCrew = TandemCrewPairing(
      id: 'elite_tandem',
      pilot: const ParacyclingAthleteProfile(
        id: 'p1',
        name: 'J. Kowalski',
        nationalityCode: 'POL',
        age: 28,
        sportClass: ParacyclingSportClass.b,
        gender: ParacyclingGenderCategory.men,
        ftpWatts: 440.0,
        peak5sWatts: 1220.0,
        vo2Max: 77.0,
        weightKg: 75.0,
        downhillConfidence: 96,
        bikeHandling: 94,
        isPilot: true,
      ),
      stoker: const ParacyclingAthleteProfile(
        id: 's1',
        name: 'M. Zieliński',
        nationalityCode: 'POL',
        age: 26,
        sportClass: ParacyclingSportClass.b,
        gender: ParacyclingGenderCategory.men,
        ftpWatts: 420.0,
        peak5sWatts: 1160.0,
        vo2Max: 75.0,
        weightKg: 72.0,
        downhillConfidence: 90,
        bikeHandling: 85,
      ),
      synchronizationIndex: 0.98,
      communicationChemistry: 95,
      tandemBike: tandemTtBike,
    );

    recumbentAthlete = const ParacyclingAthleteProfile(
      id: 'h3_rider',
      name: 'R. Wilk',
      nationalityCode: 'POL',
      age: 31,
      sportClass: ParacyclingSportClass.h3,
      gender: ParacyclingGenderCategory.men,
      ftpWatts: 255.0,
      peak5sWatts: 580.0,
      vo2Max: 62.0,
      weightKg: 66.0,
      upperBodyEndurance: 92,
      bikeHandling: 89,
    );

    kneelingAthlete = recumbentAthlete.copyWith(
      id: 'h5_rider',
      sportClass: ParacyclingSportClass.h5,
    );
  });

  group('TandemAndHandbikePhysicsSolver — Tandemy Klasy B', () {
    test('przekracza 800 W mocy łącznej i osiąga wysoką prędkość na płaskim', () {
      final result = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteCrew,
          pilotTargetWatts: 440.0,
          stokerTargetWatts: 420.0,
          pilotCadenceRpm: 94.0,
          stokerCadenceRpm: 94.0,
          currentSpeedMs: 16.0,
          gradientPercent: 0.0,
        ),
      );

      expect(result.combinedInputWatts, 860.0);
      expect(result.isOver800Watts, isTrue);
      expect(result.syncPhase, TandemSyncPhase.synchronized);
      expect(result.effectiveWheelWatts, greaterThan(800.0));
      expect(result.equilibriumSpeedKmh, greaterThan(55.0));
      expect(result.solverIterations, greaterThan(0));
    });

    test('rozsynchronizowana kadencja pilota i stokera obniża moc efektywną', () {
      final synced = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteCrew,
          pilotTargetWatts: 410.0,
          stokerTargetWatts: 410.0,
          pilotCadenceRpm: 92.0,
          stokerCadenceRpm: 92.0,
        ),
      );

      final mismatched = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteCrew,
          pilotTargetWatts: 410.0,
          stokerTargetWatts: 410.0,
          pilotCadenceRpm: 105.0,
          stokerCadenceRpm: 72.0,
        ),
      );

      expect(
        mismatched.syncEfficiencyMultiplier,
        lessThan(synced.syncEfficiencyMultiplier),
      );
      expect(mismatched.effectiveWheelWatts, lessThan(synced.effectiveWheelWatts));
      expect(mismatched.syncPhase, isNot(TandemSyncPhase.synchronized));
    });

    test('elitarny tandem przekracza 95 km/h na szybkim zjeździe', () {
      final roadCrew = eliteCrew.copyWith(tandemBike: tandemRoadBike);
      final summary = TandemAndHandbikePhysicsSolver.simulateTandemDescent(
        crew: roadCrew,
        gradientPercent: -9.5,
        pilotWatts: 280.0,
        stokerWatts: 260.0,
        initialSpeedKmh: 55.0,
        technicalDifficulty: 18.0,
        durationSeconds: 35.0,
        altitudeMeters: 1500.0,
      );

      expect(summary.exceeded95Kmh, isTrue);
      expect(summary.peakSpeedKmh, greaterThan(95.0));
      expect(summary.distanceCoveredM, greaterThan(600.0));
    });

    test('ostry zakręt na zjeździe wymusza hamowanie i nagrzewa tarcze', () {
      final result = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteCrew.copyWith(tandemBike: tandemRoadBike),
          pilotTargetWatts: 120.0,
          stokerTargetWatts: 100.0,
          currentSpeedMs: 26.0, // 93.6 km/h
          gradientPercent: -9.0,
          cornerRadiusM: 35.0,
          technicalDifficulty: 65.0,
          rotorTempCelsius: 130.0,
          dtSeconds: 1.0,
        ),
      );

      expect(result.isDescentSpeedLimited, isTrue);
      expect(result.brakingForceN, greaterThan(0.0));
      expect(result.estimatedRotorTempCelsius, greaterThan(130.0));
    });
  });

  group('TandemAndHandbikePhysicsSolver — Handbike H1–H5', () {
    test('leżący handbike H3 jest szybszy na płaskim niż klęczący H5 przy tej samej mocy', () {
      final recumbentResult = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: recumbentAthlete,
          bike: recumbentHandbike,
          armCrankWatts: 250.0,
          currentSpeedMs: 11.0,
          gradientPercent: 0.0,
        ),
      );

      final kneelingResult = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: kneelingAthlete,
          bike: kneelingHandbike,
          armCrankWatts: 250.0,
          currentSpeedMs: 11.0,
          gradientPercent: 0.0,
        ),
      );

      expect(recumbentResult.effectiveCdaM2, lessThan(kneelingResult.effectiveCdaM2));
      expect(
        recumbentResult.equilibriumSpeedKmh,
        greaterThan(kneelingResult.equilibriumSpeedKmh),
      );
    });

    test('klęczący H5 ma mniejszą stratę trakcji na stromym podjeździe >10%', () {
      final recumbentClimb = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: recumbentAthlete,
          bike: recumbentHandbike,
          armCrankWatts: 270.0,
          currentSpeedMs: 3.5,
          gradientPercent: 12.0,
        ),
      );

      final kneelingClimb = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: kneelingAthlete,
          bike: kneelingHandbike,
          armCrankWatts: 270.0,
          currentSpeedMs: 3.5,
          gradientPercent: 12.0,
        ),
      );

      expect(
        kneelingClimb.climbingTractionPenaltyFactor,
        greaterThan(recumbentClimb.climbingTractionPenaltyFactor),
      );
    });

    test('ciasny zakręt trójkołowca ogranicza prędkość i wykrywa ryzyko wywrotki', () {
      final tightTurn = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: kneelingAthlete,
          bike: kneelingHandbike,
          armCrankWatts: 260.0,
          currentSpeedMs: 13.5, // 48.6 km/h w bardzo ciasnym łuku
          cornerRadiusM: 14.0,
          trackWidthM: 0.68,
        ),
      );

      expect(tightTurn.lateralAccelerationG, greaterThan(0.8));
      expect(tightTurn.turnStabilityZone, isNot(HandbikeTurnStabilityZone.planted));
      expect(tightTurn.isCorneringLimited, isTrue);
      expect(tightTurn.newSpeedKmh, lessThanOrEqualTo(tightTurn.maxSafeCorneringSpeedKmh + 0.01));
    });
  });

  group('TandemAndHandbikePhysicsPanel — Responsywność UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renderuje się poprawnie bez przepełnień przy ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(12),
                child: TandemAndHandbikePhysicsPanel(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Solver Fizyki Tandemów'), findsOneWidget);
        expect(find.textContaining('W'), findsWidgets);

        await tester.tap(find.textContaining('Handbike H1–H5'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Stabilność 3-Kołowa'), findsOneWidget);
      });
    }
  });
}
