import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/mud_and_dust_splatter_accumulation.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('MudAndDustSplatterAccumulation', () {
    const engine = MudAndDustSplatterAccumulation();

    test('narasta błoto na mokrym bruku Paris-Roubaix na wszystkich 5 strefach', () {
      var state = RiderSplatterState.clean(101);
      const input = RiderSplatterFrameInput(
        riderId: 101,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        wetness: 0.92,
        rainIntensity: 0.70,
        speedKmh: 42.0,
        draftingSavingsRatio: 0.25,
        distanceToAheadRiderMeters: 0.9,
        nearbyRidersCount: 3,
      );

      for (int i = 0; i < 20; i++) {
        state = engine.step(state, input, 1.0);
      }

      expect(state.exposureRole, PelotonDraftExposureRole.onWheel);
      for (final zone in RiderSplatterZone.values) {
        expect(state.mudForZone(zone), greaterThan(0.15));
      }
      // Łydki i rama roweru brudzą się szybciej niż twarz.
      expect(
        state.mudForZone(RiderSplatterZone.calves),
        greaterThan(state.mudForZone(RiderSplatterZone.face)),
      );
      expect(
        state.mudForZone(RiderSplatterZone.bikeFrame),
        greaterThan(state.mudForZone(RiderSplatterZone.face)),
      );
      expect(state.dominantMedium, SplatterMedium.mud);
    });

    test('narasta biały pył na suchym szutrze Strade Bianche', () {
      var state = RiderSplatterState.clean(202);
      const input = RiderSplatterFrameInput(
        riderId: 202,
        surfaceType: SegmentSurfaceType.gravelStrade,
        wetness: 0.02,
        rainIntensity: 0.0,
        speedKmh: 39.0,
        draftingSavingsRatio: 0.35,
        distanceToAheadRiderMeters: 0.8,
        nearbyRidersCount: 10,
      );

      for (int i = 0; i < 15; i++) {
        state = engine.step(state, input, 1.0);
      }

      expect(state.exposureRole, PelotonDraftExposureRole.deepPeloton);
      expect(state.averageDustRatio, greaterThan(0.30));
      expect(state.averageMudRatio, lessThan(0.01));
      expect(state.dominantMedium, SplatterMedium.chalkDust);
    });

    test('jadący na kole brudzi się szybciej niż samotny lider', () {
      var soloState = RiderSplatterState.clean(1);
      var wheelState = RiderSplatterState.clean(2);

      const soloInput = RiderSplatterFrameInput(
        riderId: 1,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        wetness: 0.85,
        rainIntensity: 0.60,
        speedKmh: 40.0,
        draftingSavingsRatio: 0.0,
        distanceToAheadRiderMeters: 30.0,
        nearbyRidersCount: 0,
      );

      const wheelInput = RiderSplatterFrameInput(
        riderId: 2,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        wetness: 0.85,
        rainIntensity: 0.60,
        speedKmh: 40.0,
        draftingSavingsRatio: 0.24,
        distanceToAheadRiderMeters: 0.8,
        nearbyRidersCount: 2,
      );

      for (int i = 0; i < 15; i++) {
        soloState = engine.step(soloState, soloInput, 1.0);
        wheelState = engine.step(wheelState, wheelInput, 1.0);
      }

      expect(soloState.exposureRole, PelotonDraftExposureRole.soloLeader);
      expect(wheelState.exposureRole, PelotonDraftExposureRole.onWheel);
      expect(
        wheelState.overallDirtyRatio,
        greaterThan(soloState.overallDirtyRatio * 3.0),
      );
    });

    test('przetarcie okularów czyści soczewki, a deszcz na asfalcie spłukuje pył', () {
      var state = RiderSplatterState.clean(303);
      const dustInput = RiderSplatterFrameInput(
        riderId: 303,
        surfaceType: SegmentSurfaceType.gravelStrade,
        wetness: 0.0,
        rainIntensity: 0.0,
        speedKmh: 40.0,
        draftingSavingsRatio: 0.25,
        distanceToAheadRiderMeters: 1.0,
        nearbyRidersCount: 4,
      );

      for (int i = 0; i < 15; i++) {
        state = engine.step(state, dustInput, 1.0);
      }
      final dustBeforeWipe = state.totalCoverageForZone(RiderSplatterZone.eyewear);
      final totalDustBeforeRain = state.averageDustRatio;

      state = engine.step(
        state,
        const RiderSplatterFrameInput(
          riderId: 303,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          wetness: 0.4,
          rainIntensity: 0.8,
          speedKmh: 42.0,
          isWipingEyewear: true,
        ),
        1.0,
      );

      expect(
        state.totalCoverageForZone(RiderSplatterZone.eyewear),
        lessThan(dustBeforeWipe),
      );
      expect(state.averageDustRatio, lessThan(totalDustBeforeRain));
    });

    test('generuje deterministyczną pulę kropek i obsługuje przypadki brzegowe', () {
      final clean = RiderSplatterState.clean(55);
      expect(
        engine.buildDropletsForZone(
          riderId: 55,
          zone: RiderSplatterZone.face,
          state: clean,
        ),
        isEmpty,
      );
      expect(
        engine.step(
          clean,
          const RiderSplatterFrameInput(
            riderId: 55,
            surfaceType: SegmentSurfaceType.cobblestonesSector5,
            wetness: 1.0,
            rainIntensity: 1.0,
            speedKmh: 40.0,
          ),
          0.0,
        ),
        equals(clean),
      );

      var dirty = clean;
      for (int i = 0; i < 10; i++) {
        dirty = engine.step(
          dirty,
          const RiderSplatterFrameInput(
            riderId: 55,
            surfaceType: SegmentSurfaceType.cobblestonesSector5,
            wetness: 0.9,
            rainIntensity: 0.8,
            speedKmh: 45.0,
            draftingSavingsRatio: 0.3,
            distanceToAheadRiderMeters: 0.9,
            nearbyRidersCount: 8,
          ),
          1.0,
        );
      }
      final d1 = engine.buildDropletsForZone(
        riderId: 55,
        zone: RiderSplatterZone.calves,
        state: dirty,
      );
      final d2 = engine.buildDropletsForZone(
        riderId: 55,
        zone: RiderSplatterZone.calves,
        state: dirty,
      );
      expect(d1, isNotEmpty);
      expect(d1.length, equals(d2.length));
      expect(d1.first.u, equals(d2.first.u));
      expect(d1.first.v, equals(d2.first.v));
    });
  });

  group('MudAndDustSplatterControlPanel responsywność', () {
    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień w ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MudAndDustSplatterControlPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Akumulacja Błota i Pyłu 3D'), findsOneWidget);
          expect(find.text('+5s jazdy'), findsOneWidget);

          await tester.ensureVisible(find.text('+5s jazdy'));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text('+5s jazdy'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Brud: 0%'), findsNothing);
        },
      );
    }
  });
}
