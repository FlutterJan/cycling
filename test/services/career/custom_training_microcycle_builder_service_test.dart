import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/custom_training_microcycle_builder_service.dart';

Rider _createTestRider({Injury? injury}) {
  return Rider(
    id: 'test_rider_638',
    firstName: 'Jan',
    lastName: 'Nowak',
    nationalityIso: 'PL',
    birthDate: DateTime(1999, 4, 10),
    potential: 88,
    specialization: RiderSpecialization.puncher,
    physiology: const RiderPhysiology(
      heightCm: 180.0,
      weightKg: 68.0,
      bodyFatPercentage: 7.5,
      ftpWatts: 400,
      wPrimeJoules: 24000,
      vo2Max: 80.0,
      maxHr: 192,
      restingHr: 40,
      lactateThresholdHr: 174,
      recoveryRate: 1.05,
      glycogenCapacityGrams: 520.0,
      form: 72.0,
      fatigue: 65.0,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1280,
      watts15s: 1050,
      watts30s: 840,
      watts1m: 660,
      watts3m: 500,
      watts5m: 460,
      watts20m: 420,
      watts60m: 395,
    ),
    skills: const RiderSkills(
      cobbles: 76,
      descending: 80,
      bikeHandling: 82,
      aeroPositioning: 78,
      draftingEfficiency: 80,
      raceIq: 84,
      rainResistance: 75,
      heatTolerance: 74,
      timeTrialPositioning: 75,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#E8C3A9',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'sport_shield',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'aero_pro',
      shoeColorHex: '#F3F4F6',
      sockHeightProportion: 0.85,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_test',
      role: RiderRole.coLeader,
      monthlySalaryEur: 45000,
      signingBonusEur: 25000,
      winBonusEur: 10000,
      releaseClauseEur: 1500000,
      contractEndYear: 2028,
      morale: 0.85,
      leaderLoyalty: 80.0,
      requiredRacesIds: [],
    ),
    health: RiderHealth(
      acuteTrainingLoad: 65.0,
      chronicTrainingLoad: 72.0,
      currentInjury: injury,
    ),
    careerPointsUci: 950,
  );
}

void main() {
  const service = CustomTrainingMicrocycleBuilderService();

  group('CustomTrainingMicrocycleBuilderService', () {
    test('generates valid 7-day presets for VO2max, Sweet Spot and Motor-Pacing', () {
      for (final preset in MicrocycleGoalPreset.values) {
        final cycle = service.buildPresetMicrocycle(preset);
        final validation = service.validateMicrocycle(cycle);

        expect(cycle.sessions.length, 7);
        expect(validation.isValid, isTrue, reason: 'Preset ${preset.name} should be valid');
        expect(cycle.totalWeeklyTss, greaterThan(0));
      }
    });

    test('simulates Banister CTL/ATL/TSB curves and physiological adaptations', () {
      final rider = _createTestRider();
      final vo2Cycle = service.buildPresetMicrocycle(MicrocycleGoalPreset.vo2maxPeak);
      final projection = service.simulateMicrocycleForRider(
        microcycle: vo2Cycle,
        rider: rider,
      );

      expect(projection.dailyProjections.length, 7);
      expect(projection.projectedVo2maxDelta, greaterThan(0));
      expect(projection.projected5mWattsDelta, greaterThan(0));
      expect(projection.synergyScore, inInclusiveRange(15, 99));
    });

    test('applies microcycle to healthy rider and blocks injured rider', () {
      final healthyRider = _createTestRider();
      final motorCycle =
          service.buildPresetMicrocycle(MicrocycleGoalPreset.motorPacingClassics);

      final successResult = service.applyMicrocycleToRider(
        microcycle: motorCycle,
        rider: healthyRider,
      );
      expect(successResult.success, isTrue);
      expect(
        successResult.updatedRider.skills.draftingEfficiency,
        greaterThanOrEqualTo(healthyRider.skills.draftingEfficiency),
      );

      final injuredRider = _createTestRider(
        injury: const Injury(
          name: 'Złamanie obojczyka',
          type: InjuryType.clavicleFracture,
          daysRemaining: 21,
          trainingAllowed: false,
        ),
      );
      final blockedResult = service.applyMicrocycleToRider(
        microcycle: motorCycle,
        rider: injuredRider,
      );
      expect(blockedResult.success, isFalse);
      expect(blockedResult.updatedRider, equals(injuredRider));
    });

    test('detects 3 consecutive high-intensity days warning', () {
      final base = service.buildPresetMicrocycle(MicrocycleGoalPreset.custom);
      final overloadedSessions = base.sessions.map((s) {
        if (s.day.dayIndex <= 2) {
          return MicrocycleDaySession.fromType(
            day: s.day,
            workoutType: TrainingWorkoutType.vo2maxIntervals,
          );
        }
        return s;
      }).toList();

      final overloaded = base.copyWith(sessions: overloadedSessions);
      final validation = service.validateMicrocycle(overloaded);

      expect(overloaded.hasThreeConsecutiveHardDays, isTrue);
      expect(validation.warnings, isNotEmpty);
    });

    test('supports full JSON round-trip serialization', () {
      final original =
          service.buildPresetMicrocycle(MicrocycleGoalPreset.sweetSpotBase);
      final json = original.toJson();
      final decoded = WeeklyTrainingMicrocycle.fromJson(json);

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.preset, original.preset);
      expect(decoded.sessions, equals(original.sessions));
    });
  });

  group('CustomTrainingMicrocycleBuilderPanel responsiveness', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: CustomTrainingMicrocycleBuilderPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('KREATOR MIKROCYKLI'), findsOneWidget);
          expect(find.text('Zastosuj Cykl'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
