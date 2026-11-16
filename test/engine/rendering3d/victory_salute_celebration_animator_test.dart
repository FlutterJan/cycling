import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/victory_salute_celebration_animator.dart';

void main() {
  group('VictorySaluteCelebrationAnimator', () {
    const VictorySaluteCelebrationAnimator animator =
        VictorySaluteCelebrationAnimator();

    test('contains all 6 distinct finish-line celebration types', () {
      expect(VictorySaluteType.values.length, 6);
      expect(
        VictorySaluteType.values.map((e) => e.id).toSet().length,
        6,
      );
    });

    test('evaluates all 6 animations with finite 3D coordinates', () {
      for (final VictorySaluteType type in VictorySaluteType.values) {
        final VictorySalutePose3D pose = animator.evaluateFrame(
          VictorySaluteFrameInput(
            riderId: 'rider_1',
            saluteType: type,
            elapsedSeconds: 1.6,
            fatigueLevel: 0.8,
            gradientPercent: 8.0,
          ),
        );

        expect(pose.saluteType, type);
        expect(pose.normalizedProgress, inInclusiveRange(0.0, 1.0));
        expect(pose.torsoInclineDegrees.isFinite, isTrue);
        expect(pose.headPosition.y.isFinite, isTrue);
        expect(pose.rightHandPosition.y.isFinite, isTrue);
        expect(pose.leftHandPosition.y.isFinite, isTrue);
        expect(pose.phaseLabel, isNotEmpty);
      }
    });

    test('bothHandsRaised lifts both hands high above chest', () {
      final VictorySalutePose3D pose = animator.evaluateFrame(
        const VictorySaluteFrameInput(
          riderId: 'sprinter',
          saluteType: VictorySaluteType.bothHandsRaised,
          elapsedSeconds: 1.6,
        ),
      );
      expect(pose.rightHandPosition.y, greaterThan(pose.chestPosition.y + 0.35));
      expect(pose.leftHandPosition.y, greaterThan(pose.chestPosition.y + 0.35));
      expect(pose.torsoInclineDegrees, greaterThan(70.0));
    });

    test('zipUpJersey advances zipper progress from 0 to 1', () {
      final VictorySalutePose3D startPose = animator.evaluateFrame(
        const VictorySaluteFrameInput(
          riderId: 'solo',
          saluteType: VictorySaluteType.zipUpJersey,
          elapsedSeconds: 0.2,
        ),
      );
      final VictorySalutePose3D endPose = animator.evaluateFrame(
        const VictorySaluteFrameInput(
          riderId: 'solo',
          saluteType: VictorySaluteType.zipUpJersey,
          elapsedSeconds: 2.5,
        ),
      );
      expect(startPose.jerseyZipperProgress, lessThan(0.2));
      expect(endPose.jerseyZipperProgress, greaterThan(0.95));
      expect(endPose.sponsorLogoVisibilityScore, greaterThan(0.5));
    });

    test('pointAtSponsorLogo highlights sponsor and extends pointing finger', () {
      final VictorySalutePose3D pose = animator.evaluateFrame(
        const VictorySaluteFrameInput(
          riderId: 'leader',
          saluteType: VictorySaluteType.pointAtSponsorLogo,
          elapsedSeconds: 1.6,
        ),
      );
      expect(pose.rightFingerPointingFactor, greaterThan(0.8));
      expect(pose.sponsorLogoVisibilityScore, greaterThan(0.85));
      // Lewa dłoń stabilizuje kierownicę
      expect(pose.leftHandPosition.z, greaterThan(0.4));
    });

    test('fistBumpChest clenches right fist near chest', () {
      final VictorySalutePose3D pose = animator.evaluateFrame(
        const VictorySaluteFrameInput(
          riderId: 'puncheur',
          saluteType: VictorySaluteType.fistBumpChest,
          elapsedSeconds: 1.6,
        ),
      );
      expect(pose.rightFistClenchFactor, greaterThan(0.85));
      expect(
        (pose.rightHandPosition.y - pose.chestPosition.y).abs(),
        lessThan(0.15),
      );
    });

    test('theatricalBow lowers torso and head at peak bow', () {
      final VictorySalutePose3D pose = animator.evaluateFrame(
        const VictorySaluteFrameInput(
          riderId: 'showman',
          saluteType: VictorySaluteType.theatricalBow,
          elapsedSeconds: 1.6,
        ),
      );
      expect(pose.torsoInclineDegrees, lessThan(26.0));
      expect(pose.headPitchDegrees, lessThan(-10.0));
    });

    test('exhaustedHandlebarLean keeps full steering stability and heavy breath', () {
      final VictorySalutePose3D pose = animator.evaluateFrame(
        const VictorySaluteFrameInput(
          riderId: 'climber',
          saluteType: VictorySaluteType.exhaustedHandlebarLean,
          elapsedSeconds: 1.6,
          fatigueLevel: 0.95,
          gradientPercent: 11.0,
        ),
      );
      expect(pose.steeringStability, 1.0);
      expect(pose.breathingAmplitude, greaterThan(0.8));
      expect(pose.torsoInclineDegrees, lessThan(22.0));
    });

    test('selectCelebration picks exhausted lean on steep uphill fatigue finish', () {
      final VictorySaluteType selected = animator.selectCelebration(
        const VictorySaluteContext(
          riderId: 'gc_rider',
          finishGradientPercent: 9.5,
          fatigueLevel: 0.85,
        ),
      );
      expect(selected, VictorySaluteType.exhaustedHandlebarLean);
    });

    test('selectCelebration respects overrideType and clamps negative time', () {
      final VictorySaluteType selected = animator.selectCelebration(
        const VictorySaluteContext(
          riderId: 'gc_rider',
          overrideType: VictorySaluteType.theatricalBow,
        ),
      );
      expect(selected, VictorySaluteType.theatricalBow);

      final VictorySalutePose3D clampedPose = animator.evaluateFrame(
        const VictorySaluteFrameInput(
          riderId: 'gc_rider',
          saluteType: VictorySaluteType.bothHandsRaised,
          elapsedSeconds: -5.0,
        ),
      );
      expect(clampedPose.normalizedProgress, 0.0);
    });
  });

  group('VictorySaluteCelebrationPanel UI', () {
    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          VictorySaluteType? lastSelected;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: VictorySaluteCelebrationPanel(
                    onSaluteSelected: (VictorySaluteType t) => lastSelected = t,
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.text('Celebracje Zwycięstwa 3D'), findsOneWidget);

          // Wybór animacji zapięcia koszulki
          final Finder zipChip = find.text(
            viewport.width < 560
                ? VictorySaluteType.zipUpJersey.shortLabel
                : VictorySaluteType.zipUpJersey.label,
          );
          await tester.tap(zipChip);
          await tester.pump(const Duration(milliseconds: 300));
          expect(lastSelected, VictorySaluteType.zipUpJersey);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('disabled panel ignores tap interactions', (
      WidgetTester tester,
    ) async {
      VictorySaluteType? lastSelected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VictorySaluteCelebrationPanel(
                enabled: false,
                onSaluteSelected: (VictorySaluteType t) => lastSelected = t,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text(VictorySaluteType.theatricalBow.label));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastSelected, isNull);
    });
  });
}
