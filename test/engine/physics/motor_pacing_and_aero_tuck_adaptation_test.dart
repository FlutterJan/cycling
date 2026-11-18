import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/motor_pacing_and_aero_tuck_adaptation.dart';

void main() {
  const engine = MotorPacingAndAeroTuckAdaptation();

  group('MotorPacingAndAeroTuckAdaptation physics & physiology', () {
    test('adapted rider loses significantly less power in low TT tuck than unadapted', () {
      const unadapted = RiderAeroAdaptationProfile(
        riderId: 'r1',
        riderName: 'Janek Kowalski',
        uprightFtpWatts: 400.0,
        adaptationScore: 0.05,
        hipMobilityScore: 0.40,
        coreAndNeckEndurance: 0.40,
        diaphragmEfficiency: 0.45,
      );
      const adapted = RiderAeroAdaptationProfile(
        riderId: 'r1',
        riderName: 'Janek Kowalski',
        uprightFtpWatts: 400.0,
        adaptationScore: 0.92,
        hipMobilityScore: 0.85,
        coreAndNeckEndurance: 0.88,
        diaphragmEfficiency: 0.85,
      );

      final resUnadapted = engine.evaluateAeroTuckPerformance(
        const AeroTuckPowerAndCdaInput(
          profile: unadapted,
          posture: AeroTuckPosturePreset.extremeLowPrayingMantis,
          elapsedTtMinutes: 40.0,
        ),
      );
      final resAdapted = engine.evaluateAeroTuckPerformance(
        const AeroTuckPowerAndCdaInput(
          profile: adapted,
          posture: AeroTuckPosturePreset.extremeLowPrayingMantis,
          elapsedTtMinutes: 40.0,
        ),
      );

      expect(
        resAdapted.effectiveSustainablePowerWatts,
        greaterThan(resUnadapted.effectiveSustainablePowerWatts + 20.0),
      );
      expect(
        resAdapted.actualPowerDropPercent,
        lessThan(resUnadapted.actualPowerDropPercent),
      );
      expect(resAdapted.predictedTtSpeedKmh, greaterThan(resUnadapted.predictedTtSpeedKmh));
      expect(resAdapted.timeSavedOver40KmSeconds, greaterThan(30.0));
      expect(resAdapted.adaptationTier, AeroAdaptationTier.worldTourTtSpecialist);
    });

    test('motor pacing behind scooter produces draft savings and positive adaptation gain', () {
      const initial = RiderAeroAdaptationProfile(
        riderId: 'r2',
        riderName: 'Piotr Nowak',
        uprightFtpWatts: 390.0,
        adaptationScore: 0.20,
      );

      final result = engine.applyMotorPacingSession(
        initial,
        const MotorPacingSessionInput(
          vehicleType: MotorPacingVehicleType.vespaScooter125,
          protocol: MotorPacingSessionProtocol.ttThresholdBehindDerny,
          posture: AeroTuckPosturePreset.standardTtExtensions,
          durationMinutes: 80.0,
          targetSpeedKmh: 60.0,
          averageCadenceRpm: 102.0,
        ),
      );

      expect(result.adaptationGain, greaterThan(0.02));
      expect(
        result.updatedProfile.adaptationScore,
        closeTo(initial.adaptationScore + result.adaptationGain, 1e-6),
      );
      expect(result.effectiveRiderPowerWatts, lessThan(result.soloEquivalentPowerWatts));
      expect(result.updatedProfile.motorPacingSessionsCompleted, 1);
      expect(result.updatedProfile.cumulativeAeroTuckMinutes, 80.0);
      expect(result.trainingStressScoreTss, greaterThan(0.0));
    });

    test('detraining decay only applies after 10 days without aero training', () {
      const profile = RiderAeroAdaptationProfile(
        riderId: 'r3',
        riderName: 'Marek Lis',
        uprightFtpWatts: 410.0,
        adaptationScore: 0.80,
      );

      final noDecay = engine.applyDetrainingDecay(profile, 10);
      expect(noDecay.adaptationScore, 0.80);

      final decayed = engine.applyDetrainingDecay(profile, 30);
      expect(decayed.adaptationScore, lessThan(0.80));
      expect(decayed.adaptationScore, greaterThan(0.40));
    });

    test('simulateTrainingBlock progresses adaptation and handles empty sessions', () {
      const initial = RiderAeroAdaptationProfile(
        riderId: 'r4',
        riderName: 'Filip Kaczmarek',
        uprightFtpWatts: 420.0,
        adaptationScore: 0.15,
      );

      final emptyBlock = engine.simulateTrainingBlock(
        initialProfile: initial,
        sessions: const [],
      );
      expect(emptyBlock.steps, isEmpty);
      expect(emptyBlock.totalAdaptationGain, 0.0);

      final sessions = List.generate(
        8,
        (i) => MotorPacingSessionInput(
          vehicleType: MotorPacingVehicleType.vespaScooter125,
          protocol: i.isEven
              ? MotorPacingSessionProtocol.highCadenceOverspeed
              : MotorPacingSessionProtocol.ttThresholdBehindDerny,
          posture: AeroTuckPosturePreset.extremeLowPrayingMantis,
          durationMinutes: 75.0,
          targetSpeedKmh: 60.0,
          averageCadenceRpm: 105.0,
        ),
      );

      final block = engine.simulateTrainingBlock(
        initialProfile: initial,
        sessions: sessions,
        evaluationPosture: AeroTuckPosturePreset.extremeLowPrayingMantis,
      );

      expect(block.steps.length, 8);
      expect(block.totalAdaptationGain, greaterThan(0.25));
      expect(block.totalPowerRecoveredWatts, greaterThan(15.0));
      expect(block.total40KmTimeGainSeconds, greaterThan(20.0));
      expect(
        block.steps.last.adaptationScoreAfter,
        greaterThan(block.steps.first.adaptationScoreAfter),
      );
    });

    test('RiderAeroAdaptationProfile JSON round-trip preserves all fields', () {
      const original = RiderAeroAdaptationProfile(
        riderId: 'r_json',
        riderName: 'Michal Kwiatkowski',
        uprightFtpWatts: 415.0,
        massKg: 68.5,
        hipMobilityScore: 0.78,
        coreAndNeckEndurance: 0.82,
        diaphragmEfficiency: 0.76,
        adaptationScore: 0.74,
        motorPacingSessionsCompleted: 12,
        cumulativeAeroTuckMinutes: 940.0,
        daysSinceLastAeroSession: 3,
        preferredPosture: AeroTuckPosturePreset.extremeLowPrayingMantis,
      );

      final restored = RiderAeroAdaptationProfile.fromJson(original.toJson());
      expect(restored.riderId, original.riderId);
      expect(restored.riderName, original.riderName);
      expect(restored.uprightFtpWatts, original.uprightFtpWatts);
      expect(restored.adaptationScore, original.adaptationScore);
      expect(restored.preferredPosture, original.preferredPosture);
      expect(restored.motorPacingSessionsCompleted, 12);
    });
  });

  group('MotorPacingAndAeroTuckPanel responsive UI tests', () {
    const testProfile = RiderAeroAdaptationProfile(
      riderId: 'ui_1',
      riderName: 'Filippo Ganna',
      uprightFtpWatts: 460.0,
      adaptationScore: 0.45,
    );

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()} and runs session',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          RiderAeroAdaptationProfile? updated;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MotorPacingAndAeroTuckPanel(
                  initialProfile: testProfile,
                  onProfileUpdated: (p) => updated = p,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 350));

          expect(find.text('Motor-Pacing & Adaptacja Pozycji TT'), findsOneWidget);
          expect(find.text('Wykonaj trening za skuterem'), findsOneWidget);

          await tester.ensureVisible(find.text('Wykonaj trening za skuterem'));
          await tester.tap(find.text('Wykonaj trening za skuterem'));
          await tester.pump(const Duration(milliseconds: 350));

          expect(updated, isNotNull);
          expect(updated!.adaptationScore, greaterThan(testProfile.adaptationScore));
          expect(updated!.motorPacingSessionsCompleted, 1);
        },
      );
    }
  });
}
