import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/multi_season_rider_aging_and_decline_curve.dart';

Rider _buildTestRider({
  int birthYear = 2008,
  RiderSpecialization specialization = RiderSpecialization.gcClimber,
  int potential = 94,
  int ftpWatts = 345,
  double vo2Max = 76.0,
  double recoveryRate = 0.88,
  int raceIq = 68,
}) {
  return Rider(
    id: 'rider_test_01',
    firstName: 'Jan',
    lastName: 'Kowalski',
    nationalityIso: 'POL',
    birthDate: DateTime(birthYear, 5, 14),
    potential: potential,
    specialization: specialization,
    physiology: RiderPhysiology(
      heightCm: 179.0,
      weightKg: 66.0,
      bodyFatPercentage: 7.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: 19500,
      vo2Max: vo2Max,
      maxHr: 196,
      restingHr: 41,
      lactateThresholdHr: 176,
      recoveryRate: recoveryRate,
      glycogenCapacityGrams: 460.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: 1180,
      watts15s: 1020,
      watts30s: 880,
      watts1m: 690,
      watts3m: 510,
      watts5m: 445,
      watts20m: 380,
      watts60m: ftpWatts,
    ),
    skills: RiderSkills(
      cobbles: 64,
      descending: 74,
      bikeHandling: 72,
      aeroPositioning: 71,
      draftingEfficiency: 70,
      raceIq: raceIq,
      rainResistance: 69,
      heatTolerance: 71,
      timeTrialPositioning: 73,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#E8B89A',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'vent_01',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.45,
      bodyBuildType: BodyBuildType.climberLean,
    ),
    contract: const RiderContract(
      teamId: 'team_pol',
      role: RiderRole.neoPro,
      monthlySalaryEur: 8500,
      signingBonusEur: 0,
      winBonusEur: 1000,
      releaseClauseEur: 250000,
      contractEndYear: 2029,
      morale: 0.85,
      leaderLoyalty: 0.80,
      requiredRacesIds: [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 32.0,
      chronicTrainingLoad: 72.0,
    ),
    careerPointsUci: 120,
  );
}

void main() {
  group('MultiSeasonRiderAgingAndDeclineCurve', () {
    test('ages 18-23 yield rapid VO2max and explosive 5s/1m growth', () {
      final youth = _buildTestRider(birthYear: 2008); // 18 in 2026
      final report = MultiSeasonRiderAgingAndDeclineCurve.projectTrajectory(
        rider: youth,
        startSeasonYear: 2026,
        seasons: 5, // 18 -> 23
        randomSeed: 101,
      );

      final start = report.snapshots.first;
      final at23 = report.snapshots.last;

      expect(start.age, 18);
      expect(at23.age, 23);
      expect(start.phase, CareerLifecyclePhase.youthExplosiveDevelopment);
      expect(at23.vo2Max - start.vo2Max, greaterThan(4.0));
      expect(at23.watts5s, greaterThan(start.watts5s + 80));
      expect(at23.watts1m, greaterThan(start.watts1m + 50));
      expect(at23.wPrimeJoules, greaterThan(start.wPrimeJoules + 1500));
    });

    test('ages 24-29 achieve peak FTP and multi-day endurance', () {
      final rider = _buildTestRider(birthYear: 2007); // 19 in 2026
      final report = MultiSeasonRiderAgingAndDeclineCurve.projectTrajectory(
        rider: rider,
        startSeasonYear: 2026,
        seasons: 15, // 19 -> 34
        randomSeed: 77,
      );

      expect(report.snapshots.length, 16);
      expect(report.peakFtpSeason.age, inInclusiveRange(24, 30));

      final at24 = report.snapshots.firstWhere((s) => s.age == 24);
      final at29 = report.snapshots.firstWhere((s) => s.age == 29);
      expect(at24.phase, CareerLifecyclePhase.primePeakPerformance);
      expect(at29.phase, CareerLifecyclePhase.primePeakPerformance);
      expect(at29.recoveryRate, greaterThan(at24.recoveryRate));
      expect(at29.ftpWatts, greaterThanOrEqualTo(at24.ftpWatts));
    });

    test(
      'after age 31, 5s/1m peak power declines slowly while pedaling economy, raceIq and Week-3 resilience rise',
      () {
        final primeRider = _buildTestRider(
          birthYear: 1995, // 31 in 2026
          ftpWatts: 410,
          vo2Max: 84.0,
          recoveryRate: 1.02,
          raceIq: 82,
        );

        final report = MultiSeasonRiderAgingAndDeclineCurve.projectTrajectory(
          rider: primeRider,
          startSeasonYear: 2026,
          seasons: 5, // 31 -> 36
          randomSeed: 303,
        );

        final at31 = report.snapshots.first;
        final at36 = report.snapshots.last;

        expect(at31.age, 31);
        expect(at36.age, 36);
        expect(at36.phase, CareerLifecyclePhase.veteranEfficiencyAndResilience);

        // Slow decline of peak explosive power 5s / 1m
        expect(at36.watts5s, lessThan(at31.watts5s));
        expect(at36.watts1m, lessThan(at31.watts1m));
        expect(at36.watts5s, greaterThan((at31.watts5s * 0.80).round()));

        // Simultaneous increase in pedaling economy, raceIq, and 3rd-week resilience
        expect(
          at36.pedalingEconomyPercent,
          greaterThan(at31.pedalingEconomyPercent),
        );
        expect(at36.raceIq, greaterThan(at31.raceIq));
        expect(
          at36.thirdWeekFatigueResilience,
          greaterThan(at31.thirdWeekFatigueResilience),
        );
      },
    );

    test('15-season trajectory maintains monotonic MMP curve and JSON roundtrip', () {
      final rider = _buildTestRider(
        birthYear: 2006,
        specialization: RiderSpecialization.pureSprinter,
      );
      final report = MultiSeasonRiderAgingAndDeclineCurve.projectTrajectory(
        rider: rider,
        startSeasonYear: 2026,
        seasons: 15,
        randomSeed: 12,
      );

      expect(report.seasonsSimulated, 15);
      expect(report.snapshots.length, 16);

      for (final s in report.snapshots) {
        expect(s.watts5s, greaterThan(s.watts1m));
        expect(s.watts1m, greaterThan(s.watts5m));
        expect(s.watts5m, greaterThan(s.watts20m));
        expect(s.watts20m, greaterThanOrEqualTo(s.watts60m));
        expect(s.ftpWatts, equals(s.watts60m));

        final decoded = RiderSeasonEvolutionSnapshot.fromJson(s.toJson());
        expect(decoded, equals(s));
      }

      final json = report.toJson();
      expect((json['snapshots'] as List).length, 16);
    });

    testWidgets(
      'MultiSeasonRiderAgingCurvePanel renders cleanly at 390x844, 1024x768, 1600x900',
      (tester) async {
        final rider = _buildTestRider(birthYear: 2007);

        for (final size in const [
          Size(390, 844),
          Size(1024, 768),
          Size(1600, 900),
        ]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: MultiSeasonRiderAgingCurvePanel(
                    rider: rider,
                    startSeasonYear: 2026,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Krzywa Kariery (15 Sezonów)'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        // Verify metric tab interaction
        await tester.tap(find.text('Ekonomia, IQ & 3. Tydzień'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  });
}
