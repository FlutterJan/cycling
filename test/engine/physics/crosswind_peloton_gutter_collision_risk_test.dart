import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/crosswind_peloton_gutter_collision_risk.dart';

void main() {
  group('CrosswindPelotonGutterCollisionRisk Physics', () {
    test('wide corridor with low wind yields safe clearance and clean pass', () {
      const GutterCollisionRiskInput input = GutterCollisionRiskInput(
        availableGutterWidthMeters: 1.35,
        pelotonSpeedMs: 12.5,
        overtakeSpeedDeltaMs: 1.5,
        windSpeedMs: 3.0,
        windAngleDeg: 45.0,
        frontRimDepthMm: 35,
        pelotonSqueezeRateMs: 0.0,
        asphaltEdgeStepCm: 0.5,
        shoulderType: GutterShoulderType.pavedDrainageGutter,
        bikeHandlingSkill: 85.0,
        coreStabilitySkill: 85.0,
        fatigueRatio: 0.1,
      );

      final GutterCollisionRiskResult risk =
          CrosswindPelotonGutterCollisionRisk.evaluateRisk(input);
      expect(risk.netClearanceMeters, greaterThan(0.35));
      expect(risk.riskLevel, GutterRiskLevel.safeClearance);
      expect(risk.shouldAbortOvertake, isFalse);

      final GutterOvertakeSimulationResult sim =
          CrosswindPelotonGutterCollisionRisk.simulateOvertakeManeuver(input);
      expect(sim.outcome, GutterOvertakeOutcome.cleanPass);
      expect(sim.trajectory, isNotEmpty);
      expect(sim.timeSpentOffRoadSeconds, 0.0);
    });

    test('narrow corridor with severe crosswind and wet grass triggers abort and high risk', () {
      const GutterCollisionRiskInput input = GutterCollisionRiskInput(
        availableGutterWidthMeters: 0.52,
        pelotonSpeedMs: 15.5,
        overtakeSpeedDeltaMs: 2.2,
        windSpeedMs: 18.0,
        windAngleDeg: 90.0,
        gustFactor: 1.45,
        frontRimDepthMm: 80,
        pelotonSqueezeRateMs: 0.28,
        asphaltEdgeStepCm: 4.5,
        shoulderType: GutterShoulderType.wetGrassVerge,
        isWetAsphalt: true,
        bikeHandlingSkill: 60.0,
        coreStabilitySkill: 58.0,
        fatigueRatio: 0.75,
      );

      final GutterCollisionRiskResult risk =
          CrosswindPelotonGutterCollisionRisk.evaluateRisk(input);
      expect(risk.netClearanceMeters, lessThan(0.0));
      expect(risk.runOffProbability, greaterThan(0.75));
      expect(risk.shouldAbortOvertake, isTrue);
      expect(
        risk.riskLevel == GutterRiskLevel.imminentRunOff ||
            risk.riskLevel == GutterRiskLevel.criticalCrashRisk,
        isTrue,
      );

      final GutterOvertakeSimulationResult sim =
          CrosswindPelotonGutterCollisionRisk.simulateOvertakeManeuver(input);
      expect(
        sim.outcome == GutterOvertakeOutcome.vergeWashoutCrash ||
            sim.outcome == GutterOvertakeOutcome.pelotonDominoCrash ||
            sim.outcome == GutterOvertakeOutcome.shoulderExcursionRecovered,
        isTrue,
      );
      expect(sim.estimatedTimeLostSeconds, greaterThan(0.0));
    });

    test('higher rim depth increases lateral aerodynamic force and sway', () {
      const GutterCollisionRiskInput shallow = GutterCollisionRiskInput(
        availableGutterWidthMeters: 0.90,
        pelotonSpeedMs: 14.0,
        overtakeSpeedDeltaMs: 1.8,
        windSpeedMs: 12.0,
        windAngleDeg: 85.0,
        frontRimDepthMm: 30,
      );
      final GutterCollisionRiskInput deep = shallow.copyWith(frontRimDepthMm: 80);

      final GutterCollisionRiskResult shallowRes =
          CrosswindPelotonGutterCollisionRisk.evaluateRisk(shallow);
      final GutterCollisionRiskResult deepRes =
          CrosswindPelotonGutterCollisionRisk.evaluateRisk(deep);

      expect(
        deepRes.lateralAerodynamicForceN,
        greaterThan(shallowRes.lateralAerodynamicForceN),
      );
      expect(
        deepRes.lateralSwayAmplitudeMeters,
        greaterThan(shallowRes.lateralSwayAmplitudeMeters),
      );
    });

    test('computeMinimumSafeCorridorMeters returns clamped physical minimum', () {
      const GutterCollisionRiskInput input = GutterCollisionRiskInput(
        availableGutterWidthMeters: 0.80,
        pelotonSpeedMs: 13.0,
        overtakeSpeedDeltaMs: 1.5,
        windSpeedMs: 10.0,
        windAngleDeg: 75.0,
      );
      final double minSafe =
          CrosswindPelotonGutterCollisionRisk.computeMinimumSafeCorridorMeters(
        input,
      );
      expect(minSafe, inInclusiveRange(0.65, 1.85));
    });
  });

  group('CrosswindPelotonGutterCollisionRiskPanel UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrosswindPelotonGutterCollisionRiskPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844 mobile', (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('RYZYKO WYPRZEDZANIA W RYNSZTOKU'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1024x768 tablet', (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('RYZYKO WYPRZEDZANIA W RYNSZTOKU'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1600x900 desktop and handles interactions',
        (WidgetTester tester) async {
      GutterOvertakeSimulationResult? lastSim;
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrosswindPelotonGutterCollisionRiskPanel(
              onSimulationCompleted: (GutterOvertakeSimulationResult r) {
                lastSim = r;
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Mokre trawiaste pobocze'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Testuj manewr'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(lastSim, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });
}
