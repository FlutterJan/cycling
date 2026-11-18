import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/dynamic_puddle_splash_and_tire_spray_3d.dart';

void main() {
  group('DynamicPuddleSplashAndTireSpray3d', () {
    test('generates roadside puddles and detects wheel hit', () {
      final engine = DynamicPuddleSplashAndTireSpray3d();
      final puddles = engine.generateRoadsidePuddles(
        startDistanceM: 50.0,
        endDistanceM: 250.0,
        preset: WetRoadRainPreset.flemishDownpour,
      );

      expect(puddles, isNotEmpty);
      expect(
        puddles.any(
          (p) =>
              p.side == RoadPuddleSide.leftShoulder ||
              p.side == RoadPuddleSide.rightShoulder,
        ),
        isTrue,
      );

      final target = puddles.first;
      expect(
        target.depthFactorAt(target.distanceMeters, target.lateralOffsetMeters),
        closeTo(1.0, 0.001),
      );
      expect(
        target.depthFactorAt(target.distanceMeters + 25.0, target.lateralOffsetMeters),
        equals(0.0),
      );
    });

    test('puddle splash creates heavy plume and cools drafting rival', () {
      final engine = DynamicPuddleSplashAndTireSpray3d();
      engine.setPuddles(const <RoadsidePuddle3D>[
        RoadsidePuddle3D(
          id: 'shoulder_hit',
          distanceMeters: 100.0,
          lateralOffsetMeters: 2.5,
          lengthMeters: 4.0,
          widthMeters: 1.5,
          depthMm: 14.0,
          side: RoadPuddleSide.rightShoulder,
        ),
      ]);

      const riders = <RiderWetRoadInput>[
        RiderWetRoadInput(
          riderId: 'lead',
          riderName: 'Leader',
          teamColor: Colors.amber,
          distanceMeters: 100.0,
          lateralOffsetMeters: 2.5,
          speedKmh: 50.0,
          ambientTempCelsius: 6.0,
          baseThermalComfort: 90.0,
        ),
        RiderWetRoadInput(
          riderId: 'wheel',
          riderName: 'Wheel Sucker',
          teamColor: Colors.cyan,
          distanceMeters: 98.5,
          lateralOffsetMeters: 2.45,
          speedKmh: 50.0,
          ambientTempCelsius: 6.0,
          baseThermalComfort: 90.0,
        ),
        RiderWetRoadInput(
          riderId: 'clear',
          riderName: 'Clear Line',
          teamColor: Colors.green,
          distanceMeters: 98.5,
          lateralOffsetMeters: -1.2,
          speedKmh: 50.0,
          ambientTempCelsius: 6.0,
          baseThermalComfort: 90.0,
        ),
      ];

      late PuddleSplashFrameSnapshot snap;
      for (var i = 0; i < 15; i++) {
        snap = engine.stepSimulation(
          dtSeconds: 0.1,
          riders: riders,
          preset: WetRoadRainPreset.flemishDownpour,
        );
      }

      final leadState =
          snap.riderStates.firstWhere((r) => r.riderId == 'lead');
      final wheelState =
          snap.riderStates.firstWhere((r) => r.riderId == 'wheel');
      final clearState =
          snap.riderStates.firstWhere((r) => r.riderId == 'clear');

      expect(leadState.inPuddle, isTrue);
      expect(leadState.sprayTier, equals(TireSprayIntensityTier.heavyPlume));
      expect(snap.totalActiveDroplets, greaterThan(0));

      expect(wheelState.drenchedByRiderId, equals('lead'));
      expect(wheelState.wetnessLevel, greaterThan(clearState.wetnessLevel));
      expect(wheelState.thermalComfort, lessThan(clearState.thermalComfort));
      expect(
        wheelState.effectiveSkinTempCelsius,
        lessThan(clearState.effectiveSkinTempCelsius),
      );
    });
  });

  group('DynamicPuddleSplashControlPanel responsive UI', () {
    for (final size in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: DynamicPuddleSplashControlPanel(),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(
            find.text('Rozbryzg z kałuż i wychłodzenie na kole 3D'),
            findsOneWidget,
          );

          await tester.tap(find.text('Kałuża na poboczu'));
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('W kałuży!'), findsWidgets);
        },
      );
    }
  });
}
