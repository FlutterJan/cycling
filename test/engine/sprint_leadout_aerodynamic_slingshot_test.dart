import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/sprint_leadout_aerodynamic_slingshot.dart';

void main() {
  group('SprintLeadoutAerodynamicSlingshot', () {
    test(
      'sprinter launching at 65 km/h with full W\' in final 250m reaches 72-76 km/h',
      () {
        final SprintSlingshotSimulationSummary summary =
            SprintLeadoutAerodynamicSlingshot.simulateFinal250m(
          const SprintSlingshotInput(
            sprinterId: 'sprinter_1',
            leadoutRiderId: 'leadout_1',
            distanceToFinishMeters: 250.0,
            launchSpeedKmh: 65.0,
            wPrimeTotalJoules: 24000.0,
            wPrimeRemainingJoules: 24000.0,
            criticalPowerWatts: 410.0,
            sprintSkill: 90,
            riderMassKg: 74.0,
            hasLeadoutWheel: true,
          ),
        );

        expect(summary.slingshotTriggered, isTrue);
        expect(summary.peakSpeedKmh, inInclusiveRange(72.0, 76.0));
        expect(summary.slingshotSpeedGainKmh, greaterThan(0.0));
        expect(summary.finishTimeSeconds, greaterThan(10.0));
        expect(summary.finishTimeSeconds, lessThan(15.0));
        expect(summary.timeline, isNotEmpty);
        expect(summary.timeline.last.phase, SlingshotPhase.completed);
      },
    );

    test(
      'elite sprinter (skill 98) and strong sprinter (skill 82) both peak inside 72-76 km/h',
      () {
        final SprintSlingshotSimulationSummary strongSummary =
            SprintLeadoutAerodynamicSlingshot.simulateFinal250m(
          const SprintSlingshotInput(
            sprinterId: 'sprinter_82',
            leadoutRiderId: 'leadout_1',
            sprintSkill: 82,
          ),
        );
        final SprintSlingshotSimulationSummary eliteSummary =
            SprintLeadoutAerodynamicSlingshot.simulateFinal250m(
          const SprintSlingshotInput(
            sprinterId: 'sprinter_98',
            leadoutRiderId: 'leadout_1',
            sprintSkill: 98,
          ),
        );

        expect(strongSummary.peakSpeedKmh, inInclusiveRange(72.0, 76.0));
        expect(eliteSummary.peakSpeedKmh, inInclusiveRange(72.0, 76.0));
        expect(
          eliteSummary.peakSpeedKmh,
          greaterThan(strongSummary.peakSpeedKmh),
        );
      },
    );

    test(
      'frontal drag multiplier ramps smoothly over first 1.5s and is 1.0 afterwards',
      () {
        final double t0 =
            SprintLeadoutAerodynamicSlingshot.computeFrontalDragMultiplier(
          elapsedSinceLaunchSeconds: 0.0,
          hasLeadoutWheel: true,
        );
        final double t075 =
            SprintLeadoutAerodynamicSlingshot.computeFrontalDragMultiplier(
          elapsedSinceLaunchSeconds: 0.75,
          hasLeadoutWheel: true,
        );
        final double t150 =
            SprintLeadoutAerodynamicSlingshot.computeFrontalDragMultiplier(
          elapsedSinceLaunchSeconds: 1.5,
          hasLeadoutWheel: true,
        );
        final double t250 =
            SprintLeadoutAerodynamicSlingshot.computeFrontalDragMultiplier(
          elapsedSinceLaunchSeconds: 2.5,
          hasLeadoutWheel: true,
        );

        expect(
          t0,
          closeTo(
            SprintLeadoutAerodynamicSlingshot.defaultInitialDragMultiplier,
            1e-6,
          ),
        );
        expect(t075, greaterThan(t0));
        expect(t075, lessThan(1.0));
        expect(t150, closeTo(1.0, 1e-6));
        expect(t250, closeTo(1.0, 1e-6));

        // Bez koła rozprowadzającego opór jest od razu pełny (1.0)
        expect(
          SprintLeadoutAerodynamicSlingshot.computeFrontalDragMultiplier(
            elapsedSinceLaunchSeconds: 0.2,
            hasLeadoutWheel: false,
          ),
          closeTo(1.0, 1e-6),
        );
      },
    );

    test(
      'depleted W\' prevents reaching 72-76 km/h peak speed',
      () {
        final SprintSlingshotSimulationSummary depleted =
            SprintLeadoutAerodynamicSlingshot.simulateFinal250m(
          const SprintSlingshotInput(
            sprinterId: 'sprinter_tired',
            leadoutRiderId: 'leadout_1',
            wPrimeTotalJoules: 24000.0,
            wPrimeRemainingJoules: 0.0,
            criticalPowerWatts: 410.0,
            hasLeadoutWheel: true,
          ),
        );

        expect(depleted.slingshotTriggered, isFalse);
        expect(depleted.peakSpeedKmh, lessThan(66.0));
      },
    );

    test('canActivateSlingshot enforces <= 250m and leadout wheel', () {
      expect(
        SprintLeadoutAerodynamicSlingshot.canActivateSlingshot(
          distanceToFinishMeters: 250.0,
          hasLeadoutWheel: true,
        ),
        isTrue,
      );
      expect(
        SprintLeadoutAerodynamicSlingshot.canActivateSlingshot(
          distanceToFinishMeters: 251.0,
          hasLeadoutWheel: true,
        ),
        isFalse,
      );
      expect(
        SprintLeadoutAerodynamicSlingshot.canActivateSlingshot(
          distanceToFinishMeters: 180.0,
          hasLeadoutWheel: false,
        ),
        isFalse,
      );
    });

    test('SprintSlingshotInput serializes and deserializes cleanly', () {
      const SprintSlingshotInput original = SprintSlingshotInput(
        sprinterId: 's_10',
        leadoutRiderId: 'l_02',
        distanceToFinishMeters: 220.0,
        launchSpeedKmh: 65.5,
        sprintSkill: 94,
      );
      final SprintSlingshotInput restored =
          SprintSlingshotInput.fromJson(original.toJson());

      expect(restored.sprinterId, original.sprinterId);
      expect(restored.leadoutRiderId, original.leadoutRiderId);
      expect(restored.distanceToFinishMeters, original.distanceToFinishMeters);
      expect(restored.launchSpeedKmh, original.launchSpeedKmh);
      expect(restored.sprintSkill, original.sprintSkill);
    });
  });
}
