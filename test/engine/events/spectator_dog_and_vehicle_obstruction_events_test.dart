import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/spectator_dog_and_vehicle_obstruction_events.dart';

void main() {
  group('SpectatorDogAndVehicleObstructionEvents', () {
    const engine = SpectatorDogAndVehicleObstructionEvents();

    test('high bikeHandling evades spectator dog cleanly', () {
      const riders = [
        ObstructionRiderInput(
          riderId: 'r1',
          riderName: 'Skillful Rider',
          teamId: 'T1',
          bikeHandling: 95,
          raceIq: 90,
          currentSpeedKmh: 48.0,
          isRaceLeader: true,
        ),
        ObstructionRiderInput(
          riderId: 'r2',
          riderName: 'Clumsy Rider',
          teamId: 'T2',
          bikeHandling: 35,
          raceIq: 40,
          currentSpeedKmh: 48.0,
        ),
      ];

      final report = engine.evaluateSpectatorDogIntrusion(
        riders: riders,
        kilometerMark: 112.0,
        distanceToFinishKm: 35.0,
        seed: 42,
      );

      expect(report.eventType, ObstructionEventType.spectatorDogIntrusion);
      expect(report.riderImpacts.length, 2);
      expect(report.riderImpacts[0].outcome, RiderObstructionOutcome.agileEvasion);
      expect(report.riderImpacts[0].rawTimeLossSeconds, 0.0);
      expect(
        report.riderImpacts[1].outcome,
        RiderObstructionOutcome.crashOrCollision,
      );
      expect(
        report.commissaireDecision.status,
        NeutralizationVerdictStatus.noNeutralization,
      );
    });

    test('TV vehicle climb obstruction forces leader to run uphill & neutralizes GC loss', () {
      const riders = [
        ObstructionRiderInput(
          riderId: 'r_leader',
          riderName: 'Yellow Jersey',
          teamId: 'SKY',
          bikeHandling: 86,
          raceIq: 92,
          currentSpeedKmh: 18.0,
          isRaceLeader: true,
          isGcContender: true,
        ),
      ];

      final report = engine.evaluateTvVehicleClimbObstruction(
        riders: riders,
        kilometerMark: 170.5,
        distanceToFinishKm: 1.2,
        gradientPercent: 10.4,
        roadWidthMeters: 3.2,
        seed: 2016,
      );

      expect(report.eventType, ObstructionEventType.tvVehicleClimbObstruction);
      expect(report.hasLeaderRunning, isTrue);
      expect(report.riderImpacts.first.runningDistanceMeters, greaterThan(50.0));
      expect(
        report.commissaireDecision.status,
        NeutralizationVerdictStatus.fullNeutralization,
      );
      expect(report.riderImpacts.first.netGcTimeLossSeconds, 0.0);
      expect(report.riderImpacts.first.rawTimeLossSeconds, greaterThan(20.0));
    });

    test('DramaticObstructionEventReport JSON round-trip preserves fields', () {
      const riders = [
        ObstructionRiderInput(
          riderId: 'r1',
          riderName: 'Test Leader',
          teamId: 'TST',
          bikeHandling: 88,
          raceIq: 88,
          currentSpeedKmh: 20.0,
          isRaceLeader: true,
        ),
      ];

      final original = engine.evaluateTvVehicleClimbObstruction(
        riders: riders,
        kilometerMark: 150.0,
        distanceToFinishKm: 2.0,
        seed: 77,
      );

      final decoded =
          DramaticObstructionEventReport.fromJson(original.toJson());
      expect(decoded.id, original.id);
      expect(decoded.eventType, original.eventType);
      expect(
        decoded.commissaireDecision.status,
        original.commissaireDecision.status,
      );
      expect(decoded.riderImpacts.length, original.riderImpacts.length);
    });
  });

  group('SpectatorDogAndVehicleObstructionPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders and simulates cleanly at ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SpectatorDogAndVehicleObstructionPanel(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('ZDARZENIA EKSTREMALNE NA TRASIE'),
          findsOneWidget,
        );

        await tester.tap(find.text('Symuluj: Wóz TV (Ventoux)'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('UCI COMMISSAIRE:'), findsOneWidget);
        expect(find.textContaining('TV-VENTOUX'), findsOneWidget);

        await tester.tap(find.text('Symuluj: Pies kibica'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('DOG'), findsOneWidget);
      });
    }
  });
}
