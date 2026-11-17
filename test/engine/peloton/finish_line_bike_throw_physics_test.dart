import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/finish_line_bike_throw_physics.dart';
import 'package:pro_peloton_manager/engine/rendering3d/photo_finish_replay_widget.dart';

void main() {
  group('FinishLineBikeThrowPhysics', () {
    const sprinterTop = BikeThrowRiderProfile(
      riderId: 'sprinter_top',
      riderName: 'Jasper Philipsen',
      teamName: 'Alpecin-Deceuninck',
      bibNumber: 41,
      countryIso: 'BEL',
      sprintSkill: 97,
      bikeHandling: 94,
      riderHeightCm: 186.0,
      wPrimeRemainingFraction: 0.90,
      entryTimestampSeconds: 14200.000,
    );

    const sprinterAverage = BikeThrowRiderProfile(
      riderId: 'sprinter_avg',
      riderName: 'Biniam Girmay',
      teamName: 'Intermarché-Wanty',
      bibNumber: 51,
      countryIso: 'ERI',
      sprintSkill: 72,
      bikeHandling: 70,
      riderHeightCm: 170.0,
      wPrimeRemainingFraction: 0.15,
      entryTimestampSeconds: 14200.000,
    );

    test('zasięg maksymalny rzutu rowerem mieści się w 18–28 cm (180–280 mm)', () {
      final topGain = FinishLineBikeThrowPhysics.computeMaxThrowGainMm(sprinterTop);
      final avgGain = FinishLineBikeThrowPhysics.computeMaxThrowGainMm(sprinterAverage);

      expect(topGain, inInclusiveRange(180.0, 280.0));
      expect(avgGain, inInclusiveRange(180.0, 280.0));
      expect(topGain, greaterThan(avgGain));
    });

    test('perfekcyjny timing daje maksymalne wysunięcie koła i przewagę czasową', () {
      const speedKmh = 70.0;
      final optimalDist = FinishLineBikeThrowPhysics.computeOptimalTriggerDistanceMeters(
        profile: sprinterTop,
        speedKmh: speedKmh,
      );

      final perfectOutcome = FinishLineBikeThrowPhysics.simulateFinal10Meters(
        BikeThrowAttemptInput(
          profile: sprinterTop,
          entrySpeedKmh: speedKmh,
          triggerDistanceToFinishMeters: optimalDist,
          isManualPlayer: true,
        ),
      );

      final noThrowOutcome = FinishLineBikeThrowPhysics.simulateFinal10Meters(
        const BikeThrowAttemptInput(
          profile: sprinterTop,
          entrySpeedKmh: speedKmh,
          triggerDistanceToFinishMeters: null,
          isManualPlayer: true,
        ),
      );

      expect(perfectOutcome.timingQuality, BikeThrowTimingQuality.perfect);
      expect(perfectOutcome.actualGainAtLineMm, greaterThan(220.0));
      expect(perfectOutcome.timeSavedSeconds, greaterThan(0.010));
      expect(
        perfectOutcome.finalFinishTimeSeconds,
        lessThan(noThrowOutcome.finalFinishTimeSeconds),
      );
    });

    test('zbyt wczesny lub spóźniony rzut daje mniejszy zysk niż idealny moment', () {
      const speedKmh = 68.0;
      final optimalDist = FinishLineBikeThrowPhysics.computeOptimalTriggerDistanceMeters(
        profile: sprinterTop,
        speedKmh: speedKmh,
      );

      final perfect = FinishLineBikeThrowPhysics.simulateFinal10Meters(
        BikeThrowAttemptInput(
          profile: sprinterTop,
          entrySpeedKmh: speedKmh,
          triggerDistanceToFinishMeters: optimalDist,
        ),
      );

      final tooEarly = FinishLineBikeThrowPhysics.simulateFinal10Meters(
        const BikeThrowAttemptInput(
          profile: sprinterTop,
          entrySpeedKmh: speedKmh,
          triggerDistanceToFinishMeters: 9.2,
        ),
      );

      final tooLate = FinishLineBikeThrowPhysics.simulateFinal10Meters(
        const BikeThrowAttemptInput(
          profile: sprinterTop,
          entrySpeedKmh: speedKmh,
          triggerDistanceToFinishMeters: 0.25,
        ),
      );

      expect(tooEarly.timingQuality, BikeThrowTimingQuality.tooEarly);
      expect(tooLate.timingQuality, BikeThrowTimingQuality.tooLate);
      expect(tooEarly.actualGainAtLineMm, lessThan(perfect.actualGainAtLineMm));
      expect(tooLate.actualGainAtLineMm, lessThan(perfect.actualGainAtLineMm));
    });

    test('resolveToPhotoFinishData rozstrzyga finisz co do 0.001 s dla PhotoFinishReplayWidget', () {
      const speedKmh = 68.5;
      final optimalDist = FinishLineBikeThrowPhysics.computeOptimalTriggerDistanceMeters(
        profile: sprinterTop,
        speedKmh: speedKmh,
      );

      final resolution = FinishLineBikeThrowPhysics.resolveToPhotoFinishData(
        stageName: 'Etap 5: Sprint w Troyes',
        stageNumber: 5,
        finishLocation: 'Troyes',
        attempts: [
          BikeThrowAttemptInput(
            profile: sprinterTop,
            entrySpeedKmh: speedKmh,
            triggerDistanceToFinishMeters: optimalDist,
            isManualPlayer: true,
          ),
          const BikeThrowAttemptInput(
            profile: sprinterAverage,
            entrySpeedKmh: speedKmh,
            triggerDistanceToFinishMeters: 0.35,
            isManualPlayer: false,
          ),
        ],
      );

      expect(resolution.rankedOutcomes.length, 2);
      expect(resolution.winner.profile.riderId, 'sprinter_top');
      expect(resolution.requiredPhotoFinish, isTrue);
      expect(resolution.winnerGapSeconds, greaterThan(0.0));
      expect(resolution.photoFinishData.riders.first.rank, 1);
      expect(resolution.photoFinishData.riders[1].rank, 2);
      expect(
        resolution.photoFinishData.riders[1].gapToWinnerSeconds,
        equals(resolution.winnerGapSeconds),
      );
      expect(resolution.photoFinishData.status, PhotoFinishStatus.officialConfirmed);
    });

    test('buildTrajectoryTrace generuje kroki aż do przekroczenia linii mety', () {
      final trace = FinishLineBikeThrowPhysics.buildTrajectoryTrace(
        const BikeThrowAttemptInput(
          profile: sprinterTop,
          entrySpeedKmh: 68.0,
          triggerDistanceToFinishMeters: 2.8,
          isManualPlayer: true,
        ),
      );

      expect(trace, isNotEmpty);
      expect(trace.first.phase, BikeThrowPhase.approaching);
      expect(trace.last.phase, BikeThrowPhase.crossedFinish);
      expect(trace.last.distanceToFinishMeters, 0.0);
    });
  });

  group('FinishLineBikeThrowPanel Responsiveness', () {
    const player = BikeThrowRiderProfile(
      riderId: 'be_a_pro_player',
      riderName: 'Jan Kowalski',
      teamName: 'Pro Peloton Team',
      bibNumber: 77,
      countryIso: 'POL',
    );

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień przy ${size.width.toInt()}x${size.height.toInt()}',
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
                body: Center(
                  child: FinishLineBikeThrowPanel(
                    playerProfile: player,
                    approachSpeedKmh: 68.4,
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('RZUT ROWEREM NA KRESKĘ (BIKE THROW)'), findsOneWidget);
          expect(find.text('START FINISZU (10 m)'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
