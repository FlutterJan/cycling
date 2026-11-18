import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/engine/physics/tandem_and_handbike_physics_solver.dart';
import 'package:pro_peloton_manager/models/paracycling/uci_paracycling_tandem_handbike_model.dart';

void main() {
  late ParacyclingBikeSpec tandemRoadBike;
  late ParacyclingBikeSpec tandemTtBike;
  late ParacyclingBikeSpec recumbentHandbike;
  late ParacyclingBikeSpec kneelingHandbike;
  late TandemCrewPairing eliteTandemCrew;
  late ParacyclingAthleteProfile h3Athlete;
  late ParacyclingAthleteProfile h5Athlete;

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

    eliteTandemCrew = TandemCrewPairing(
      id: 'crew_pol_b1',
      pilot: const ParacyclingAthleteProfile(
        id: 'pilot_pol_1',
        name: 'M. Kowalski',
        nationalityCode: 'POL',
        age: 29,
        sportClass: ParacyclingSportClass.b,
        gender: ParacyclingGenderCategory.men,
        ftpWatts: 440.0,
        peak5sWatts: 1210.0,
        vo2Max: 77.0,
        weightKg: 74.0,
        downhillConfidence: 95,
        bikeHandling: 92,
        isPilot: true,
      ),
      stoker: const ParacyclingAthleteProfile(
        id: 'stoker_pol_1',
        name: 'A. Nowak',
        nationalityCode: 'POL',
        age: 27,
        sportClass: ParacyclingSportClass.b,
        gender: ParacyclingGenderCategory.men,
        ftpWatts: 420.0,
        peak5sWatts: 1160.0,
        vo2Max: 75.0,
        weightKg: 72.0,
        downhillConfidence: 90,
        bikeHandling: 84,
      ),
      synchronizationIndex: 0.96,
      communicationChemistry: 94,
      tandemBike: tandemRoadBike,
    );

    h3Athlete = const ParacyclingAthleteProfile(
      id: 'athlete_h3',
      name: 'R. Wilk',
      nationalityCode: 'POL',
      age: 32,
      sportClass: ParacyclingSportClass.h3,
      gender: ParacyclingGenderCategory.men,
      ftpWatts: 250.0,
      peak5sWatts: 580.0,
      vo2Max: 62.0,
      weightKg: 66.0,
      upperBodyEndurance: 91,
      bikeHandling: 88,
    );

    h5Athlete = h3Athlete.copyWith(
      id: 'athlete_h5',
      sportClass: ParacyclingSportClass.h5,
    );
  });

  group('TandemAndHandbikePhysicsSolver — Tandem Klasy B', () {
    test('przekracza 800 W mocy łącznej i osiąga wysoką prędkość na płaskim', () {
      final result = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteTandemCrew,
          pilotTargetWatts: 440.0,
          stokerTargetWatts: 420.0,
          pilotCadenceRpm: 94.0,
          stokerCadenceRpm: 94.0,
          currentSpeedMs: 14.0,
          gradientPercent: 0.0,
        ),
      );

      expect(result.combinedInputWatts, 860.0);
      expect(result.isOver800Watts, isTrue);
      expect(result.syncPhase, TandemSyncPhase.synchronized);
      expect(result.syncEfficiencyMultiplier, greaterThan(1.0));
      expect(result.effectiveWheelWatts, greaterThan(800.0));
      expect(result.accelerationMs2, greaterThan(0.0));
      expect(result.equilibriumSpeedKmh, greaterThan(54.0));
      expect(result.totalSystemMassKg, closeTo(157.4, 0.1));
    });

    test('rozjazd kadencji pilota i stokera obniża efektywną moc na kole', () {
      final synced = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteTandemCrew,
          pilotTargetWatts: 400.0,
          stokerTargetWatts: 400.0,
          pilotCadenceRpm: 92.0,
          stokerCadenceRpm: 92.0,
        ),
      );

      final marginal = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteTandemCrew.copyWith(synchronizationIndex: 0.80),
          pilotTargetWatts: 400.0,
          stokerTargetWatts: 400.0,
          pilotCadenceRpm: 92.0,
          stokerCadenceRpm: 95.0,
        ),
      );

      final mismatched = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteTandemCrew.copyWith(synchronizationIndex: 0.72),
          pilotTargetWatts: 400.0,
          stokerTargetWatts: 400.0,
          pilotCadenceRpm: 96.0,
          stokerCadenceRpm: 74.0,
        ),
      );

      expect(synced.syncPhase, TandemSyncPhase.synchronized);
      expect(marginal.syncPhase, TandemSyncPhase.marginalDrift);
      expect(mismatched.syncPhase, TandemSyncPhase.cadenceMismatch);
      expect(
        mismatched.effectiveWheelWatts,
        lessThan(marginal.effectiveWheelWatts),
      );
      expect(marginal.effectiveWheelWatts, lessThan(synced.effectiveWheelWatts));
    });

    test('wiatr boczny zwiększa CdA, a drafting redukuje opór aerodynamiczny', () {
      final baseline = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteTandemCrew,
          pilotTargetWatts: 400.0,
          stokerTargetWatts: 400.0,
          currentSpeedMs: 15.0,
        ),
      );

      final crosswind = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteTandemCrew,
          pilotTargetWatts: 400.0,
          stokerTargetWatts: 400.0,
          currentSpeedMs: 15.0,
          crosswindMs: 12.0,
        ),
      );

      final drafted = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteTandemCrew,
          pilotTargetWatts: 400.0,
          stokerTargetWatts: 400.0,
          currentSpeedMs: 15.0,
          draftingFactor: 0.65,
        ),
      );

      expect(crosswind.effectiveCdaM2, greaterThan(baseline.effectiveCdaM2));
      expect(crosswind.aeroDragForceN, greaterThan(baseline.aeroDragForceN));
      expect(drafted.aeroDragForceN, lessThan(baseline.aeroDragForceN));
      expect(
        drafted.equilibriumSpeedKmh,
        greaterThan(baseline.equilibriumSpeedKmh),
      );
    });

    test('tandem czasowy TT ma mniejsze CdA i wyższą prędkość od szosowego', () {
      final ttCrew = eliteTandemCrew.copyWith(tandemBike: tandemTtBike);

      final roadRes = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteTandemCrew,
          pilotTargetWatts: 420.0,
          stokerTargetWatts: 410.0,
        ),
      );
      final ttRes = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: ttCrew,
          pilotTargetWatts: 420.0,
          stokerTargetWatts: 410.0,
        ),
      );

      expect(ttRes.effectiveCdaM2, lessThan(roadRes.effectiveCdaM2));
      expect(ttRes.equilibriumSpeedKmh, greaterThan(roadRes.equilibriumSpeedKmh));
    });

    test('zjazd alpejski tandemu przekracza 95 km/h i nagrzewa tarcze w zakrętach', () {
      final maxStraight =
          TandemAndHandbikePhysicsSolver.calculateTandemMaxDescentKmh(
        crew: eliteTandemCrew,
        technicalDifficulty: 18.0,
      );
      final maxTightCorner =
          TandemAndHandbikePhysicsSolver.calculateTandemMaxDescentKmh(
        crew: eliteTandemCrew,
        technicalDifficulty: 18.0,
        cornerRadiusM: 24.0,
      );

      expect(maxStraight, greaterThan(95.0));
      expect(maxTightCorner, lessThan(maxStraight));

      final descent = TandemAndHandbikePhysicsSolver.simulateTandemDescent(
        crew: eliteTandemCrew,
        gradientPercent: -9.5,
        pilotWatts: 250.0,
        stokerWatts: 230.0,
        technicalDifficulty: 18.0,
        durationSeconds: 35.0,
      );

      expect(descent.exceeded95Kmh, isTrue);
      expect(descent.peakSpeedKmh, greaterThanOrEqualTo(95.0));
      expect(descent.distanceCoveredM, greaterThan(700.0));
      expect(descent.averageSpeedKmh, greaterThan(60.0));

      // Wymuszone dohamowanie przed ciasnym zakrętem przy 90 km/h podnosi temp. tarcz.
      final hardBraking = TandemAndHandbikePhysicsSolver.solveTandemStep(
        TandemPhysicsInput(
          crew: eliteTandemCrew,
          pilotTargetWatts: 100.0,
          stokerTargetWatts: 100.0,
          currentSpeedMs: 26.0, // 93.6 km/h
          gradientPercent: -10.0,
          cornerRadiusM: 22.0,
          rotorTempCelsius: 205.0,
          dtSeconds: 2.0,
        ),
      );

      expect(hardBraking.isDescentSpeedLimited, isTrue);
      expect(hardBraking.brakingForceN, greaterThan(0.0));
      expect(
        hardBraking.estimatedRotorTempCelsius,
        greaterThan(205.0),
      );
      expect(
        hardBraking.brakeStatus == DescentThermalBrakeStatus.fadeWarning ||
            hardBraking.brakeStatus == DescentThermalBrakeStatus.thermalFade,
        isTrue,
      );
    });
  });

  group('TandemAndHandbikePhysicsSolver — Handbike H1–H5', () {
    test('pozycja leżąca H3 ma mniejsze CdA i wyższą prędkość na płaskim niż klęcząca H5', () {
      final resH3 = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h3Athlete,
          bike: recumbentHandbike,
          armCrankWatts: 250.0,
          currentSpeedMs: 11.0,
        ),
      );

      final resH5 = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h5Athlete,
          bike: kneelingHandbike,
          armCrankWatts: 250.0,
          currentSpeedMs: 11.0,
        ),
      );

      expect(resH3.posture, HandbikePostureType.recumbentLow);
      expect(resH5.posture, HandbikePostureType.kneeling);
      expect(resH3.effectiveCdaM2, lessThan(resH5.effectiveCdaM2));
      expect(resH3.equilibriumSpeedKmh, greaterThan(resH5.equilibriumSpeedKmh));
      // Trzy koła podnoszą bazowe Crr o 8% (0.0034 * 1.08 = 0.003672)
      expect(resH3.effectiveCrr, closeTo(recumbentHandbike.crr * 1.08, 1e-6));
    });

    test('na stromym podjeździe 12% klęczący H5 ma lepszą trakcję niż leżący H3', () {
      final climbH3 = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h3Athlete,
          bike: recumbentHandbike,
          armCrankWatts: 260.0,
          currentSpeedMs: 4.5,
          gradientPercent: 12.0,
        ),
      );

      final climbH5 = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h5Athlete,
          bike: kneelingHandbike,
          armCrankWatts: 260.0,
          currentSpeedMs: 4.5,
          gradientPercent: 12.0,
        ),
      );

      expect(climbH3.climbingTractionPenaltyFactor, lessThan(1.0));
      expect(
        climbH5.climbingTractionPenaltyFactor,
        greaterThan(climbH3.climbingTractionPenaltyFactor),
      );
    });

    test('zmęczenie ramion i zła kadencja obniżają efektywną moc na kole', () {
      final fresh = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h3Athlete,
          bike: recumbentHandbike,
          armCrankWatts: 250.0,
          crankCadenceRpm: 84.0,
          upperBodyFatigueFactor: 0.0,
        ),
      );

      final fatiguedAndSlowCadence =
          TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h3Athlete,
          bike: recumbentHandbike,
          armCrankWatts: 250.0,
          crankCadenceRpm: 52.0,
          upperBodyFatigueFactor: 0.55,
        ),
      );

      expect(
        fatiguedAndSlowCadence.effectiveWheelWatts,
        lessThan(fresh.effectiveWheelWatts),
      );
    });

    test('ocenia stabilność 3-kołowego handbike\'a w zakręcie i ogranicza prędkość graniczną', () {
      final straight = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h3Athlete,
          bike: recumbentHandbike,
          armCrankWatts: 240.0,
          currentSpeedMs: 11.0,
        ),
      );
      expect(straight.turnStabilityZone, HandbikeTurnStabilityZone.planted);
      expect(straight.lateralAccelerationG, 0.0);
      expect(straight.corneringScrubForceN, 0.0);
      expect(straight.isCorneringLimited, isFalse);

      final tightCornerFast = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h5Athlete, // wyższy środek ciężkości (0.42 m)
          bike: kneelingHandbike,
          armCrankWatts: 280.0,
          currentSpeedMs: 13.5, // ~48.6 km/h
          cornerRadiusM: 16.0,
          trackWidthM: 0.68,
        ),
      );

      expect(tightCornerFast.lateralAccelerationG, greaterThan(0.75));
      expect(
        tightCornerFast.turnStabilityZone,
        HandbikeTurnStabilityZone.tipOverCritical,
      );
      expect(tightCornerFast.corneringScrubForceN, greaterThan(0.0));
      expect(tightCornerFast.isCorneringLimited, isTrue);
      expect(tightCornerFast.brakingForceN, greaterThan(0.0));
      expect(
        tightCornerFast.newSpeedKmh,
        lessThanOrEqualTo(tightCornerFast.maxSafeCorneringSpeedKmh + 0.01),
      );
    });

    test('obsługuje przypadki brzegowe (0 W mocy i wysoka wysokość n.p.m.)', () {
      final zeroPower = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h3Athlete,
          bike: recumbentHandbike,
          armCrankWatts: 0.0,
          currentSpeedMs: 0.0,
        ),
      );

      expect(zeroPower.propulsionForceN, 0.0);
      expect(zeroPower.effectiveWheelWatts, 0.0);
      expect(zeroPower.newSpeedMs, 0.0);

      final seaLevel = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h3Athlete,
          bike: recumbentHandbike,
          armCrankWatts: 240.0,
          currentSpeedMs: 11.0,
          altitudeMeters: 0.0,
        ),
      );
      final highAltitude = TandemAndHandbikePhysicsSolver.solveHandbikeStep(
        HandbikePhysicsInput(
          athlete: h3Athlete,
          bike: recumbentHandbike,
          armCrankWatts: 240.0,
          currentSpeedMs: 11.0,
          altitudeMeters: 2200.0,
        ),
      );

      expect(
        highAltitude.aeroDragForceN,
        lessThan(seaLevel.aeroDragForceN),
      );
    });
  });

  group('TandemAndHandbikePhysicsPanel — Responsywność UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
          ),
          home: const Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: TandemAndHandbikePhysicsPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień w ${size.width.toInt()}x${size.height.toInt()} i przełącza tryby',
        (tester) async {
          await pumpPanelAtSize(tester, size);

          expect(tester.takeException(), isNull);
          expect(find.text('Moc Łączna Duetu'), findsOneWidget);
          expect(find.text('Prędkość na Płaskim'), findsOneWidget);

          // Przełączenie na tryb Handbike H1-H5
          await tester.tap(find.text('Handbike H1–H5 (Aero & Zakręty)'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('Stabilność 3-Kołowa'), findsOneWidget);
          expect(find.text('Klasa H3'), findsOneWidget);

          // Przełączenie pozycji z leżącej H3 na klęczącą H5
          await tester.tap(find.text('Klęczący H5 (CdA 0.242)'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('Klasa H5'), findsOneWidget);
        },
      );
    }
  });
}
