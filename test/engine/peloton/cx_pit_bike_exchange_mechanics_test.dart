import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/cx_pit_bike_exchange_mechanics.dart';
import 'package:pro_peloton_manager/models/race/cyclocross_course_and_mud_model.dart';

void main() {
  group('CxPitBikeExchangeMechanics', () {
    const mechanics = CxPitBikeExchangeMechanics();

    test('heavy mud adds between 0.4 kg and 1.8 kg per km and +12 W drag per km',
        () {
      final minMudRate = mechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 0.0,
        mudViscosityIndex: 0.0,
      );
      final maxMudRate = mechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 25.0,
        mudViscosityIndex: 1.0,
      );
      final dragRate = mechanics.computeDrivetrainDragRateWattsPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.deepMud,
      );

      expect(minMudRate, closeTo(0.4, 1e-6));
      expect(maxMudRate, closeTo(1.8, 1e-6));
      expect(dragRate, closeTo(12.0, 1e-6));

      var state = mechanics.createInitialState(
        riderId: 'wout_cx',
        baseBikeWeightKg: 7.9,
      );
      const mudSegment = CyclocrossCourseSegment(
        index: 1,
        startMeter: 0.0,
        lengthMeters: 1000.0,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 15.0,
        mudViscosityIndex: 0.7,
      );

      final stepResult = mechanics.step(
        state: state,
        dtSeconds: 180.0,
        distanceMeters: 1000.0,
        mudCondition: CyclocrossMudCondition.heavyMud,
        segment: mudSegment,
      );

      state = stepResult.state;
      expect(state.accumulatedMudKg, inInclusiveRange(0.4, 1.8));
      expect(state.drivetrainDragWatts, closeTo(12.0, 1e-6));
      expect(
        state.currentBikeWeightKg,
        closeTo(7.9 + state.accumulatedMudKg, 1e-6),
      );
      expect(state.heavyMudDistanceOnCurrentBikeKm, closeTo(1.0, 1e-6));
    });

    test('pit lane exchange lasts 4.5 s and returns clean second bike at base weight',
        () {
      var state = mechanics.createInitialState(
        riderId: 'mvdp_cx',
        baseBikeWeightKg: 7.8,
      );

      const mudSegment = CyclocrossCourseSegment(
        index: 2,
        startMeter: 300.0,
        lengthMeters: 1500.0,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 20.0,
        mudViscosityIndex: 0.9,
      );

      // Ride 1.5 km in heavy mud
      state = mechanics
          .step(
            state: state,
            dtSeconds: 250.0,
            distanceMeters: 1500.0,
            mudCondition: CyclocrossMudCondition.heavyMud,
            segment: mudSegment,
          )
          .state;

      expect(state.accumulatedMudKg, greaterThan(1.5));
      expect(state.drivetrainDragWatts, closeTo(18.0, 1e-6));
      expect(state.activeBikeSlot, CxBikeSlot.bikeA);

      // Enter Pit Lane (4.5 s)
      state = mechanics.enterPitLane(state: state);
      expect(state.status, CxPitExchangeStatus.inPitLane);
      expect(state.pitRemainingSeconds, closeTo(4.5, 1e-6));

      // Step 2.0 s inside Pit Lane — still exchanging
      final midPit = mechanics.step(state: state, dtSeconds: 2.0);
      expect(midPit.completedBikeExchange, isFalse);
      expect(midPit.state.status, CxPitExchangeStatus.inPitLane);
      expect(midPit.state.pitRemainingSeconds, closeTo(2.5, 1e-6));

      // Step remaining 2.5 s — exchange completes!
      final donePit = mechanics.step(state: midPit.state, dtSeconds: 2.5);
      expect(donePit.completedBikeExchange, isTrue);
      expect(donePit.state.status, CxPitExchangeStatus.onCourse);
      expect(donePit.state.activeBikeSlot, CxBikeSlot.bikeB);
      expect(donePit.state.accumulatedMudKg, closeTo(0.0, 1e-6));
      expect(donePit.state.drivetrainDragWatts, closeTo(0.0, 1e-6));
      expect(donePit.state.currentBikeWeightKg, closeTo(7.8, 1e-6));
      expect(donePit.state.exchangeCount, 1);
      expect(donePit.state.totalPitTimeSeconds, closeTo(4.5, 1e-6));
      expect(donePit.state.isSpareBikeClean, isFalse);

      // Mechanics pressure-wash Bike A clean over the next 45 s
      final washed = mechanics.step(
        state: donePit.state,
        dtSeconds: 45.0,
        distanceMeters: 200.0,
        segment: const CyclocrossCourseSegment(
          index: 0,
          startMeter: 0.0,
          lengthMeters: 200.0,
          terrainType: CyclocrossTerrainType.pavedStartFinish,
        ),
      );
      expect(washed.state.isSpareBikeClean, isTrue);
    });

    test('tactical evaluation recommends pitNow when mud drag outweighs 4.5 s stop',
        () {
      final muddyState = mechanics
          .createInitialState(riderId: 't_pidcock', baseBikeWeightKg: 7.9)
          .copyWith(
            accumulatedMudKg: 2.4,
            drivetrainDragWatts: 24.0,
            heavyMudDistanceOnCurrentBikeKm: 2.0,
          );

      final eval = mechanics.evaluatePitExchangeRecommendation(
        state: muddyState,
        remainingRaceDistanceKm: 6.0,
        riderPowerWatts: 340.0,
      );

      expect(eval.recommendation, CxPitRecommendation.pitNow);
      expect(eval.estimatedTimeSavedSeconds, greaterThan(2.5));
      expect(eval.pitStopCostSeconds, closeTo(4.5, 1e-6));
    });

    testWidgets(
      'CxPitBikeExchangePanel renders cleanly without overflow on 390x844, 1024x768, 1600x900',
      (tester) async {
        const state = CxPitBikeExchangeState(
          riderId: 'rider_1',
          baseBikeWeightKg: 7.9,
          accumulatedMudKg: 1.45,
          drivetrainDragWatts: 12.0,
          heavyMudDistanceOnCurrentBikeKm: 1.0,
          exchangeCount: 1,
          totalPitTimeSeconds: 4.5,
        );
        const eval = CxPitTacticalEvaluation(
          recommendation: CxPitRecommendation.pitNow,
          estimatedTimeSavedSeconds: 7.8,
          pitStopCostSeconds: 4.5,
          mudMassKg: 1.45,
          drivetrainDragWatts: 12.0,
          reasonPl: 'Zjazd 4.5 s zwróci się z nawiązką.',
        );

        var pitTapped = false;

        for (final size in const [
          Size(390, 844),
          Size(1024, 768),
          Size(1600, 900),
        ]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: CxPitBikeExchangePanel(
                    state: state,
                    evaluation: eval,
                    onPitExchangePressed: () {
                      pitTapped = true;
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.textContaining('9.35 kg'), findsOneWidget);
          expect(find.textContaining('+12.0 W'), findsOneWidget);
        }

        await tester.tap(
          find.textContaining('Zjazd do boksu — wymiana roweru (4.5 s)'),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(pitTapped, isTrue);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
