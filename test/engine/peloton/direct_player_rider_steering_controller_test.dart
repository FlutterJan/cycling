import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/direct_player_rider_steering_controller.dart';

void main() {
  group('DirectPlayerRiderSteeringController', () {
    late DirectPlayerRiderSteeringController controller;

    setUp(() {
      controller = DirectPlayerRiderSteeringController(
        const DirectPlayerSteeringState(
          controlledRiderId: 'rider_1',
          controlledRiderName: 'Jan Kowalski',
          riderFtpWatts: 400,
          currentSpeedMs: 12.5,
          currentEffortPercent: 0.75,
          preSprintEffortPercent: 0.75,
          currentGearIndex: 15,
        ),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('W/S oraz strzałki góra/dół zmieniają intensywność i przełożenie', () {
      final double initialEffort = controller.state.currentEffortPercent;
      final int initialGear = controller.state.currentGearIndex;

      final bool handledUp = controller.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyW,
          logicalKey: LogicalKeyboardKey.keyW,
          timeStamp: Duration(milliseconds: 10),
        ),
      );
      expect(handledUp, isTrue);
      expect(controller.state.currentEffortPercent, greaterThan(initialEffort));
      expect(controller.state.currentGearIndex,
          greaterThanOrEqualTo(initialGear));

      controller.stepFrame(0.2);
      final double rampedEffort = controller.state.currentEffortPercent;
      expect(rampedEffort, greaterThan(initialEffort + 0.05));

      controller.handleKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.keyW,
          logicalKey: LogicalKeyboardKey.keyW,
          timeStamp: Duration(milliseconds: 220),
        ),
      );

      final bool handledDown = controller.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowDown,
          logicalKey: LogicalKeyboardKey.arrowDown,
          timeStamp: Duration(milliseconds: 240),
        ),
      );
      expect(handledDown, isTrue);
      controller.stepFrame(0.2);
      expect(controller.state.currentEffortPercent, lessThan(rampedEffort));
    });

    test('A/D i strzałki lewo/prawo przesuwają kolarza i skanują luki', () {
      controller.syncRiderTelemetry(
        nearbyRiders: const [
          SteeringPelotonNeighbor(
            riderId: 'r_left',
            riderName: 'Rywal Lewy',
            teamCode: 'TJV',
            distanceAheadMeters: 1.8,
            lateralPositionRoad: -0.25,
            speedMs: 12.4,
          ),
          SteeringPelotonNeighbor(
            riderId: 'r_right_far',
            riderName: 'Rywal Prawy',
            teamCode: 'UAE',
            distanceAheadMeters: 2.5,
            lateralPositionRoad: 0.80,
            speedMs: 12.5,
          ),
        ],
      );

      expect(controller.state.gapScan.isLeftLaneOpen, isFalse);
      expect(controller.state.gapScan.isRightLaneOpen, isTrue);

      controller.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyD,
          logicalKey: LogicalKeyboardKey.keyD,
          timeStamp: Duration(milliseconds: 10),
        ),
      );
      final DirectPlayerSteeringCommand cmd = controller.stepFrame(0.2);
      expect(cmd.targetLateralPositionRoad, greaterThan(0.0));
      expect(cmd.lateralVelocityNormalized, greaterThan(0.0));
      expect(cmd.leanAngleRad, greaterThan(0.0));

      // Granica szosy [-1.0, 1.0]
      for (int i = 0; i < 15; i++) {
        controller.stepFrame(0.2);
      }
      expect(controller.state.lateralPositionRoad, lessThanOrEqualTo(1.0));
    });

    test('Shift aktywuje wstanie w pedały i maksymalny sprint', () {
      controller.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.shiftLeft,
          logicalKey: LogicalKeyboardKey.shiftLeft,
          timeStamp: Duration(milliseconds: 10),
        ),
      );
      expect(controller.state.isStandingOnPedals, isTrue);
      expect(controller.state.isSprinting, isTrue);
      expect(controller.state.targetWatts, greaterThanOrEqualTo(750));
      expect(controller.state.powerZone, 7);

      controller.handleKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.shiftLeft,
          logicalKey: LogicalKeyboardKey.shiftLeft,
          timeStamp: Duration(milliseconds: 400),
        ),
      );
      expect(controller.state.isStandingOnPedals, isFalse);
      expect(controller.state.isSprinting, isFalse);
      expect(controller.state.currentEffortPercent, closeTo(0.75, 0.001));
    });

    test('Shift respektuje wyczerpane W prime', () {
      controller.syncRiderTelemetry(wPrimeRemainingJ: 50.0);
      controller.setSprintEngaged(true);

      expect(controller.state.isStandingOnPedals, isTrue);
      expect(controller.state.isSprinting, isFalse);
      expect(controller.state.currentEffortPercent, closeTo(1.0, 0.001));
    });

    test('Spacja chowa kolarza na koło najbliższego rywala (Snap to Wheel)', () {
      controller.syncRiderTelemetry(
        nearbyRiders: const [
          SteeringPelotonNeighbor(
            riderId: 'far_rider',
            riderName: 'Daleki Rywal',
            teamCode: 'IGD',
            distanceAheadMeters: 11.5,
            lateralPositionRoad: 0.6,
            speedMs: 12.6,
          ),
          SteeringPelotonNeighbor(
            riderId: 'near_rider',
            riderName: 'Bliski Pomocnik',
            teamCode: 'PPM',
            distanceAheadMeters: 2.2,
            lateralPositionRoad: 0.35,
            speedMs: 12.5,
          ),
        ],
      );

      final bool handled = controller.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.space,
          logicalKey: LogicalKeyboardKey.space,
          timeStamp: Duration(milliseconds: 20),
        ),
      );
      expect(handled, isTrue);
      expect(controller.state.snapToWheelStatus, SnapToWheelStatus.locked);
      expect(controller.state.snapTarget?.riderId, 'near_rider');
      expect(controller.state.estimatedDraftSavingsPercent, greaterThan(30.0));

      // Krok symulacji powinien przesunąć kolarza w stronę toru celu
      for (int i = 0; i < 6; i++) {
        controller.stepFrame(0.1);
      }
      expect(controller.state.lateralPositionRoad, closeTo(0.35, 0.05));

      // Ruch A/D anuluje Snap to Wheel
      controller.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyA,
          logicalKey: LogicalKeyboardKey.keyA,
          timeStamp: Duration(milliseconds: 700),
        ),
      );
      expect(controller.state.snapToWheelStatus, SnapToWheelStatus.idle);
      expect(controller.state.snapTarget, isNull);
    });

    test('Spacja bez rywala w zasięgu ustawia status noTargetInRange', () {
      controller.syncRiderTelemetry(nearbyRiders: const []);
      final SnapToWheelTarget? target = controller.triggerSnapToWheel();
      expect(target, isNull);
      expect(
        controller.state.snapToWheelStatus,
        SnapToWheelStatus.noTargetInRange,
      );
    });

    test('Wyłączenie sterowania blokuje obsługę klawiatury i akcji', () {
      controller.setControlEnabled(false);
      final bool handled = controller.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyW,
          logicalKey: LogicalKeyboardKey.keyW,
          timeStamp: Duration(milliseconds: 10),
        ),
      );
      expect(handled, isFalse);
      expect(controller.state.isControlEnabled, isFalse);
    });
  });

  group('DirectPlayerRiderSteeringHudPanel responsywność', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(12),
                  child: DirectPlayerRiderSteeringHudPanel(autofocus: true),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się bez przepełnień na 390x844 (mobile)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.byType(DirectPlayerRiderSteeringHudPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się bez przepełnień na 1024x768 (tablet)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.byType(DirectPlayerRiderSteeringHudPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się bez przepełnień na 1600x900 (desktop)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.byType(DirectPlayerRiderSteeringHudPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
