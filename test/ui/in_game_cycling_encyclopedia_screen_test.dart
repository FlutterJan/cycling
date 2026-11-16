import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/in_game_cycling_encyclopedia_screen.dart';

void main() {
  Widget buildTestApp({
    required Size size,
    EncyclopediaTopicId initialTopic = EncyclopediaTopicId.cda,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: InGameCyclingEncyclopediaScreen(initialTopic: initialTopic),
      ),
    );
  }

  Future<void> pumpViewport(
    WidgetTester tester,
    Size size, {
    EncyclopediaTopicId initialTopic = EncyclopediaTopicId.cda,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(size: size, initialTopic: initialTopic),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('EncyclopediaPhysicsCalculator unit tests', () {
    test('aeroPowerWatts scales with CdA and cube of speed', () {
      final double p1 = EncyclopediaPhysicsCalculator.aeroPowerWatts(
        cda: 0.25,
        speedKmh: 36.0,
      );
      final double p2 = EncyclopediaPhysicsCalculator.aeroPowerWatts(
        cda: 0.25,
        speedKmh: 72.0,
      );
      expect(p1, greaterThan(100));
      expect(p2 / p1, closeTo(8.0, 0.01));
    });

    test('rollingPowerWatts scales linearly with Crr and mass', () {
      final double pLow = EncyclopediaPhysicsCalculator.rollingPowerWatts(
        crr: 0.0025,
        totalMassKg: 70.0,
        speedKmh: 40.0,
      );
      final double pHigh = EncyclopediaPhysicsCalculator.rollingPowerWatts(
        crr: 0.0050,
        totalMassKg: 70.0,
        speedKmh: 40.0,
      );
      expect(pHigh / pLow, closeTo(2.0, 0.01));
    });

    test('simulateSkibaWPrime depletes above CP and recovers below CP', () {
      final samples = EncyclopediaPhysicsCalculator.simulateSkibaWPrime(
        cpWatts: 380.0,
        wPrimeMaxKj: 22.0,
        attackWatts: 540.0,
        recoveryWatts: 220.0,
      );
      expect(samples, isNotEmpty);
      final afterAttack = samples.firstWhere((s) => s.second == 150);
      final afterRecovery = samples.firstWhere((s) => s.second == 240);
      expect(afterAttack.wPrimeKj, lessThan(22.0));
      expect(afterRecovery.wPrimeKj, greaterThan(afterAttack.wPrimeKj));
    });

    test('vlaMaxProfileMetrics reflects sprinter vs climber trade-off', () {
      final climber = EncyclopediaPhysicsCalculator.vlaMaxProfileMetrics(
        vlaMax: 0.30,
      );
      final sprinter = EncyclopediaPhysicsCalculator.vlaMaxProfileMetrics(
        vlaMax: 0.85,
      );
      expect(climber.ftpWkg, greaterThan(sprinter.ftpWkg));
      expect(sprinter.peak5sWkg, greaterThan(climber.peak5sWkg));
    });

    test('lactateCurve increases monotonically with power', () {
      final curve = EncyclopediaPhysicsCalculator.lactateCurve(
        vlaMax: 0.45,
        aerobicThresholdW: 300.0,
      );
      expect(curve.length, greaterThan(10));
      for (int i = 1; i < curve.length; i++) {
        expect(
          curve[i].lactateMmol,
          greaterThanOrEqualTo(curve[i - 1].lactateMmol),
        );
      }
    });

    test('computeVam returns realistic climbing VAM and Alpe dHuez time', () {
      final res = EncyclopediaPhysicsCalculator.computeVam(
        wPerKg: 6.0,
        gradientPercent: 8.5,
      );
      expect(res.vamMh, inInclusiveRange(1550, 1900));
      expect(res.alpeDHuezMinutes, inInclusiveRange(35, 44));
    });

    test('echelonEffortDistribution provides shelter in slots 2-5', () {
      final slots = EncyclopediaPhysicsCalculator.echelonEffortDistribution(
        windSpeedKmh: 40.0,
        windAngleDeg: 70.0,
      );
      expect(slots.length, 8);
      expect(slots[0].draftSavingPercent, 0.0);
      expect(slots[2].draftSavingPercent, greaterThan(20.0));
      expect(slots[2].effortPercent, lessThan(slots[0].effortPercent));
    });

    test('sprintTrainProfile reaches > 70 km/h in elite slingshot', () {
      final profile = EncyclopediaPhysicsCalculator.sprintTrainProfile(
        eliteLeadout: true,
      );
      final maxSpeed =
          profile.map((p) => p.speedKmh).reduce((a, b) => a > b ? a : b);
      expect(maxSpeed, greaterThan(70.0));
    });
  });

  group('InGameCyclingEncyclopediaScreen responsive & interaction tests', () {
    testWidgets('renders without overflow on mobile 390x844', (tester) async {
      await pumpViewport(tester, const Size(390, 844));
      expect(
        find.text('ENCYKLOPEDIA TAKTYKI I FIZJOLOGII KOLARSKIEJ'),
        findsOneWidget,
      );
      expect(find.text('CdA — Opór Aerodynamiczny'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on tablet 1024x768', (tester) async {
      await pumpViewport(tester, const Size(1024, 768));
      expect(find.text('CdA — Opór Aerodynamiczny'), findsOneWidget);
      expect(find.text('1/9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on desktop 1600x900', (tester) async {
      await pumpViewport(tester, const Size(1600, 900));
      expect(find.text('CdA — Opór Aerodynamiczny'), findsOneWidget);
      expect(find.text('INTERAKTYWNY WYKRES SYMULACYJNY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches across all 9 topics cleanly without overflow',
        (tester) async {
      await pumpViewport(tester, const Size(1600, 900));

      for (final entry in InGameCyclingEncyclopediaScreen.entries) {
        await tester.tap(find.text(entry.shortLabel).first);
        await tester.pump(const Duration(milliseconds: 280));
        expect(find.text(entry.title), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('supports category filtering and search query', (tester) async {
      await pumpViewport(tester, const Size(1024, 768));

      await tester.tap(find.text('Przepisy UCI'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Zasada 3 km'), findsOneWidget);

      await tester.tap(find.text('Wszystkie'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.enterText(find.byType(TextField), 'VAM');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('TELEMETRIA GÓRSKA'), findsOneWidget);
      expect(find.text('CdA'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
