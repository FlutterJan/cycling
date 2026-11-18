import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/rider_running_uphill_incident_3d.dart';

void main() {
  group('RiderRunningUphillIncident3d', () {
    test('progresses through all emergency phases to resolved', () {
      final RiderRunningUphillIncident3d engine = RiderRunningUphillIncident3d(
        config: const RiderRunningUphillConfig(
          riderName: 'M. KWIATKOWSKI',
          trigger: UphillRunningIncidentTrigger.tvVehicleBlocked,
          gradientPercent: 12.0,
        ),
      );

      expect(engine.currentPhase, UphillRunningPhase.emergencyStopAndDismount);

      // Symulujemy 15 sekund w krokach po 0.1 s
      RiderRunningUphillFrame3d frame = engine.computeFrame();
      for (int i = 0; i < 150; i++) {
        frame = engine.step(0.1);
      }

      expect(engine.isCompleted, isTrue);
      expect(frame.phase, UphillRunningPhase.resolved);
      expect(frame.distanceRunMeters, greaterThan(15.0));
      expect(frame.estimatedTimeLostSeconds, greaterThan(2.0));
      expect(frame.tvBlockade.isVisible, isTrue);
      expect(frame.teamCar.handoverProgress, 1.0);
    });

    test('handles uphillCrashNoSpareBike without TV vehicle blockade', () {
      final RiderRunningUphillIncident3d engine = RiderRunningUphillIncident3d(
        config: const RiderRunningUphillConfig(
          trigger: UphillRunningIncidentTrigger.uphillCrashNoSpareBike,
          gradientPercent: 14.5,
        ),
      );

      engine.jumpToPhase(UphillRunningPhase.runningUphillInCleats);
      RiderRunningUphillFrame3d frame = engine.computeFrame();
      for (int i = 0; i < 25; i++) {
        frame = engine.step(0.1);
      }

      expect(frame.phase, UphillRunningPhase.runningUphillInCleats);
      expect(frame.tvBlockade.isVisible, isFalse);
      expect(frame.damagedBike.hasVisibleDamage, isTrue);
      expect(frame.damagedBike.tiltAngleRad, greaterThan(1.0));
      expect(frame.runningCadenceSpm, greaterThan(110.0));
      expect(frame.cleatSlipCount, greaterThanOrEqualTo(1));
    });

    test('clamps gradient percent and resets cleanly on startIncident', () {
      final RiderRunningUphillIncident3d engine = RiderRunningUphillIncident3d();
      engine.setGradientPercent(35.0);
      expect(engine.config.gradientPercent, 22.0);

      engine.jumpToPhase(UphillRunningPhase.teamCarApproachingWithRoofBike);
      engine.step(0.2);
      expect(engine.distanceRunMeters, greaterThan(0.0));

      engine.startIncident();
      expect(engine.currentPhase, UphillRunningPhase.emergencyStopAndDismount);
      expect(engine.distanceRunMeters, 0.0);
      expect(engine.estimatedTimeLostSeconds, 0.0);
      expect(engine.cleatSlipCount, 0);
    });
  });

  group('RiderRunningUphillIncident3dPanel responsive layout', () {
    for (final Size viewportSize in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: RiderRunningUphillIncident3dPanel(autoPlay: false),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(RiderRunningUphillIncident3dPanel), findsOneWidget);
          expect(find.textContaining('INCYDENT 3D: BIEG POD GÓRĘ'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Przełączenie scenariusza i skok fazy
          await tester.ensureVisible(find.text('Kraksa / brak roweru'));
          await tester.tap(find.text('Kraksa / brak roweru'));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.ensureVisible(find.text('Następna faza'));
          await tester.tap(find.text('Następna faza'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
