import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/network/dual_screen_telemetry_wall_server.dart';
import 'package:pro_peloton_manager/ui/screens/companion_car_dashboard_screen.dart';

void main() {
  group('CompanionCarDemoTelemetryGenerator', () {
    test('creates initial frame with 8 riders, 4 groups, and radio feed', () {
      final frame = CompanionCarDemoTelemetryGenerator.createInitialFrame();
      expect(frame.riders.length, 8);
      expect(frame.groupGaps.length, 4);
      expect(frame.radioFeed, isNotEmpty);
      expect(frame.serviceStatus.bottlesRemaining, greaterThan(0));
    });

    test('advanceTick increments sequence and kmCompleted', () {
      final frame = CompanionCarDemoTelemetryGenerator.createInitialFrame();
      final next = CompanionCarDemoTelemetryGenerator.advanceTick(frame, 1);
      expect(next.sequence, frame.sequence + 1);
      expect(next.kmCompleted, greaterThanOrEqualTo(frame.kmCompleted));
    });

    test('applyCommand updates effort, tactical orders, presets, and service inventory', () {
      var frame = CompanionCarDemoTelemetryGenerator.createInitialFrame();

      frame = CompanionCarDemoTelemetryGenerator.applyCommand(
        frame,
        const CompanionCarCommand(
          commandId: 'c1',
          type: CompanionCommandType.setEffort,
          clientId: 'test',
          issuedAtMs: 1000,
          riderId: 'r_1',
          effortPercent: 95,
        ),
      );
      expect(frame.riders.first.effortPercent, 95);
      expect(frame.riders.first.powerZone, 6);

      final initialBottles = frame.serviceStatus.bottlesRemaining;
      frame = CompanionCarDemoTelemetryGenerator.applyCommand(
        frame,
        const CompanionCarCommand(
          commandId: 'c2',
          type: CompanionCommandType.serviceRequest,
          clientId: 'test',
          issuedAtMs: 1001,
          serviceType: 'bottles',
        ),
      );
      expect(frame.serviceStatus.bottlesRemaining, initialBottles - 1);

      frame = CompanionCarDemoTelemetryGenerator.applyCommand(
        frame,
        const CompanionCarCommand(
          commandId: 'c3',
          type: CompanionCommandType.teamPreset,
          clientId: 'test',
          issuedAtMs: 1002,
          presetName: 'Pełny Atak',
        ),
      );
      expect(frame.riders.every((r) => r.effortPercent == 96), isTrue);
    });
  });

  group('CompanionCarDashboardScreen responsive & interactive tests', () {
    Widget buildSubject() {
      return const ProviderScope(
        child: MaterialApp(
          home: CompanionCarDashboardScreen(enableLiveTicker: false),
        ),
      );
    }

    testWidgets('renders all 3 monitors simultaneously on Desktop 1600x900 without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('MON-01'), findsOneWidget);
      expect(find.text('MON-02'), findsOneWidget);
      expect(find.text('MON-03'), findsOneWidget);
      expect(find.text('Biometria & Moc'), findsOneWidget);
      expect(find.text('Taktyka & Luki'), findsOneWidget);
      expect(find.text('Radio & Serwis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders 2+1 layout on Tablet 1024x768 without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('MON-01'), findsOneWidget);
      expect(find.text('MON-02'), findsOneWidget);
      expect(find.text('MON-03'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches between 3 monitors via tabs on Mobile 390x844 without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Biometria & Moc'), findsOneWidget);
      expect(find.text('Taktyka & Luki'), findsNothing);

      await tester.tap(find.text('MON-02 Taktyka'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Taktyka & Luki'), findsOneWidget);
      expect(find.text('PRESETY TAKTYCZNE DRUŻYNY'), findsOneWidget);

      await tester.tap(find.text('MON-03 Radio'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Radio & Serwis'), findsOneWidget);
      expect(find.text('RADIO TOUR & KOMUNIKATY DS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dispatches effort, service, and barrage commands interactively',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 300));

      // Initial bottles count x34 -> tap Bidony -> x33
      expect(find.text('x34'), findsOneWidget);
      await tester.tap(find.text('Bidony'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('x33'), findsOneWidget);

      // Toggle barrage -> bottles remain x33 even if tapped
      await tester.tap(find.text('Barrage'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('BARRAGE UCI AKTYWNY'), findsOneWidget);
      await tester.tap(find.text('Bidony'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('x33'), findsOneWidget);
    });
  });
}
