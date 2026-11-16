import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/ice_socks_and_water_dousing_mechanics.dart';

void main() {
  group('IceSocksAndWaterDousingMechanics', () {
    test('immediate Ice Sock order lowers core temp by 0.4 C for 15 minutes', () {
      const initial = RiderHeatCoolingState(
        riderId: 'leader_1',
        coreBodyTemperatureCelsius: 39.0,
        ambientTemperatureCelsius: 35.0,
        iceSocksAvailableInTeamCar: 3,
      );

      final outcome = IceSocksAndWaterDousingMechanics.orderIceSockFromTeamCar(
        initial,
        immediateDelivery: true,
      );

      expect(outcome.accepted, isTrue);
      expect(outcome.immediateTempDropCelsius, closeTo(0.4, 1e-6));
      expect(outcome.activeDurationSeconds, closeTo(900.0, 1e-6));
      expect(
        outcome.updatedState.coreBodyTemperatureCelsius,
        closeTo(38.6, 1e-6),
      );
      expect(outcome.updatedState.iceSockRemainingSeconds, closeTo(900.0, 1e-6));
      expect(outcome.updatedState.iceSocksAvailableInTeamCar, 2);
      expect(outcome.updatedState.iceSocksUsedCount, 1);
      expect(outcome.updatedState.isIceSockActive, isTrue);
    });

    test('delayed Ice Sock order fetches from team car and activates on arrival', () {
      const initial = RiderHeatCoolingState(
        riderId: 'leader_1',
        coreBodyTemperatureCelsius: 38.9,
        iceSocksAvailableInTeamCar: 2,
      );

      final orderOutcome =
          IceSocksAndWaterDousingMechanics.orderIceSockFromTeamCar(
        initial,
        fetchDurationSeconds: 20.0,
      );

      expect(orderOutcome.accepted, isTrue);
      expect(orderOutcome.updatedState.isFetchingIceSockFromCar, isTrue);
      expect(orderOutcome.immediateTempDropCelsius, 0.0);

      final midStep = IceSocksAndWaterDousingMechanics.step(
        orderOutcome.updatedState,
        deltaTimeSeconds: 10.0,
      );
      expect(midStep.updatedState.isFetchingIceSockFromCar, isTrue);
      expect(midStep.didActivateIceSock, isFalse);

      final arrivalStep = IceSocksAndWaterDousingMechanics.step(
        midStep.updatedState,
        deltaTimeSeconds: 10.0,
      );
      expect(arrivalStep.didActivateIceSock, isTrue);
      expect(arrivalStep.stepCoolingDropCelsius, closeTo(-0.4, 1e-6));
      expect(
        arrivalStep.updatedState.coreBodyTemperatureCelsius,
        closeTo(38.5, 1e-6),
      );
      expect(
        arrivalStep.updatedState.iceSockRemainingSeconds,
        closeTo(900.0, 1e-6),
      );
      expect(arrivalStep.externalCoolingWatts, closeTo(95.0, 1e-6));
    });

    test('Ice Sock order is rejected in closed UCI 20km zone or when empty', () {
      const closedZone = RiderHeatCoolingState(
        riderId: 'r1',
        isTeamCarZoneClosed: true,
        iceSocksAvailableInTeamCar: 4,
      );
      final closedOutcome =
          IceSocksAndWaterDousingMechanics.orderIceSockFromTeamCar(closedZone);
      expect(closedOutcome.accepted, isFalse);
      expect(closedOutcome.rejectionReasonPl, isNotNull);

      const noStock = RiderHeatCoolingState(
        riderId: 'r2',
        iceSocksAvailableInTeamCar: 0,
      );
      final emptyOutcome =
          IceSocksAndWaterDousingMechanics.orderIceSockFromTeamCar(noStock);
      expect(emptyOutcome.accepted, isFalse);
    });

    test('Water Douse lowers core temp by 0.4 C for 15 minutes and uses 1 bidon', () {
      const initial = RiderHeatCoolingState(
        riderId: 'sprinter_1',
        coreBodyTemperatureCelsius: 38.8,
        bidonsAvailable: 2,
      );

      final outcome =
          IceSocksAndWaterDousingMechanics.douseHeadWithWater(initial);

      expect(outcome.accepted, isTrue);
      expect(outcome.immediateTempDropCelsius, closeTo(0.4, 1e-6));
      expect(
        outcome.updatedState.coreBodyTemperatureCelsius,
        closeTo(38.4, 1e-6),
      );
      expect(
        outcome.updatedState.waterDouseRemainingSeconds,
        closeTo(900.0, 1e-6),
      );
      expect(outcome.updatedState.bidonsAvailable, 1);
      expect(outcome.updatedState.waterDousesUsedCount, 1);

      final expiredStep = IceSocksAndWaterDousingMechanics.step(
        outcome.updatedState,
        deltaTimeSeconds: 900.0,
      );
      expect(expiredStep.didExpireWaterDouse, isTrue);
      expect(expiredStep.updatedState.isWaterDouseActive, isFalse);
      expect(expiredStep.externalCoolingWatts, 0.0);
    });

    test('Water Douse is rejected when no bidons are left', () {
      const noBidons = RiderHeatCoolingState(
        riderId: 'r3',
        bidonsAvailable: 0,
      );

      final outcome =
          IceSocksAndWaterDousingMechanics.douseHeadWithWater(noBidons);

      expect(outcome.accepted, isFalse);
      expect(outcome.updatedState.bidonsAvailable, 0);
    });

    test('JSON serialization roundtrip preserves state', () {
      const state = RiderHeatCoolingState(
        riderId: 'rider_99',
        coreBodyTemperatureCelsius: 38.7,
        ambientTemperatureCelsius: 36.2,
        iceSockRemainingSeconds: 420.0,
        waterDouseRemainingSeconds: 180.0,
        iceSocksAvailableInTeamCar: 2,
        iceSocksUsedCount: 2,
        bidonsAvailable: 1,
        waterDousesUsedCount: 1,
      );

      final restored = RiderHeatCoolingState.fromJson(state.toJson());
      expect(restored.riderId, state.riderId);
      expect(
        restored.coreBodyTemperatureCelsius,
        closeTo(state.coreBodyTemperatureCelsius, 1e-6),
      );
      expect(
        restored.iceSockRemainingSeconds,
        closeTo(state.iceSockRemainingSeconds, 1e-6),
      );
      expect(restored.bidonsAvailable, state.bidonsAvailable);
    });
  });

  group('IceSocksAndWaterDousingPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          CoolingOrderOutcome? lastOutcome;
          const initialState = RiderHeatCoolingState(
            riderId: 'leader_1',
            coreBodyTemperatureCelsius: 39.1,
            ambientTemperatureCelsius: 35.4,
            iceSocksAvailableInTeamCar: 3,
            bidonsAvailable: 2,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF0F1115),
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: IceSocksAndWaterDousingPanel(
                      state: initialState,
                      riderName: 'Tadej Kowalski',
                      onOrderExecuted: (outcome) => lastOutcome = outcome,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Ice Sock (Wóz)'), findsOneWidget);
          expect(find.text('Polej głowę wodą'), findsOneWidget);

          await tester.tap(find.text('Ice Sock (Wóz)'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(lastOutcome, isNotNull);
          expect(lastOutcome!.accepted, isTrue);
          expect(lastOutcome!.actionType, CoolingActionType.iceSock);
        },
      );
    }
  });
}
