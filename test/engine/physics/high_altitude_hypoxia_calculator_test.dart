import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/high_altitude_hypoxia_calculator.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';

void main() {
  group('HighAltitudeHypoxiaCalculator', () {
    test('No VO2max or FTP loss at or below 1500 m (normoxia)', () {
      for (final alt in [0.0, 450.0, 1500.0]) {
        final result = HighAltitudeHypoxiaCalculator.calculate(
          altitudeMeters: alt,
          baseVo2Max: 84.0,
          baseFtpWatts: 420.0,
          nationalityIso: 'POL',
        );

        expect(result.isAboveHypoxiaThreshold, isFalse);
        expect(result.isHighMountainZone, isFalse);
        expect(result.severityZone, HypoxiaSeverityZone.normoxia);
        expect(result.rawDeltaP, 0.0);
        expect(result.effectiveDeltaP, 0.0);
        expect(result.performanceMultiplier, 1.0);
        expect(result.availableVo2Max, 84.0);
        expect(result.availableFtpWatts, 420.0);
        expect(result.vo2MaxLossPercent, 0.0);
        expect(result.ftpLossPercent, 0.0);
      }
    });

    test('Applies exact non-linear formula ΔP = -0.0085 * ((h - 1500)/100)^1.4',
        () {
      final passes = [
        AlpineHypoxiaPassBenchmark.tourmalet, // 2115 m
        AlpineHypoxiaPassBenchmark.galibier, // 2642 m
        AlpineHypoxiaPassBenchmark.stelvio, // 2758 m
      ];

      for (final pass in passes) {
        final h = pass.summitAltitudeMeters;
        final expectedDeltaP = -0.0085 * math.pow((h - 1500.0) / 100.0, 1.4);
        final expectedMultiplier = 1.0 + expectedDeltaP;

        final result = HighAltitudeHypoxiaCalculator.calculate(
          altitudeMeters: h,
          baseVo2Max: 85.0,
          baseFtpWatts: 400.0,
          nationalityIso: 'FRA',
        );

        expect(result.isAboveHypoxiaThreshold, isTrue);
        expect(result.isHighMountainZone, isTrue);
        expect(result.rawDeltaP, closeTo(expectedDeltaP, 1e-9));
        expect(result.effectiveDeltaP, closeTo(expectedDeltaP, 1e-9));
        expect(result.performanceMultiplier, closeTo(expectedMultiplier, 1e-9));
        expect(
          result.availableVo2Max,
          closeTo(85.0 * expectedMultiplier, 1e-6),
        );
        expect(
          result.availableFtpWatts,
          closeTo(400.0 * expectedMultiplier, 1e-6),
        );
      }
    });

    test('Reduces hypoxia penalty by half after altitude training camp', () {
      const altitude = 2642.0; // Col du Galibier
      final unacclimatized = HighAltitudeHypoxiaCalculator.calculate(
        altitudeMeters: altitude,
        baseVo2Max: 82.0,
        baseFtpWatts: 410.0,
        nationalityIso: 'BEL',
        hasCompletedAltitudeCamp: false,
      );

      final postCamp = HighAltitudeHypoxiaCalculator.calculate(
        altitudeMeters: altitude,
        baseVo2Max: 82.0,
        baseFtpWatts: 410.0,
        nationalityIso: 'BEL',
        hasCompletedAltitudeCamp: true,
      );

      expect(postCamp.hasAltitudeCampAdaptation, isTrue);
      expect(postCamp.acclimatizationMitigationFraction, 0.5);
      expect(
        postCamp.effectiveDeltaP,
        closeTo(unacclimatized.rawDeltaP * 0.5, 1e-9),
      );
      expect(
        postCamp.ftpLossPercent,
        closeTo(unacclimatized.ftpLossPercent * 0.5, 1e-6),
      );
      expect(
        postCamp.vo2MaxLossPercent,
        closeTo(unacclimatized.vo2MaxLossPercent * 0.5, 1e-6),
      );
      expect(postCamp.availableFtpWatts,
          greaterThan(unacclimatized.availableFtpWatts));
    });

    test('Reduces hypoxia penalty by half for Andean riders (COL, ECU, BOL, PER)',
        () {
      const altitude = 2758.0; // Passo dello Stelvio
      final european = HighAltitudeHypoxiaCalculator.calculate(
        altitudeMeters: altitude,
        baseVo2Max: 80.0,
        baseFtpWatts: 380.0,
        nationalityIso: 'ITA',
      );

      for (final iso in ['COL', 'ecu', ' BOL ', 'PER']) {
        final andean = HighAltitudeHypoxiaCalculator.calculate(
          altitudeMeters: altitude,
          baseVo2Max: 80.0,
          baseFtpWatts: 380.0,
          nationalityIso: iso,
        );

        expect(andean.isAndeanNative, isTrue);
        expect(andean.acclimatizationMitigationFraction, 0.5);
        expect(
          andean.effectiveDeltaP,
          closeTo(european.rawDeltaP * 0.5, 1e-9),
        );
        expect(
          andean.availableVo2Max,
          closeTo(80.0 * (1.0 + european.rawDeltaP * 0.5), 1e-6),
        );
      }
    });

    test('Classifies hypoxia severity zones accurately', () {
      expect(
        HighAltitudeHypoxiaCalculator.classifyZone(1200.0),
        HypoxiaSeverityZone.normoxia,
      );
      expect(
        HighAltitudeHypoxiaCalculator.classifyZone(1800.0),
        HypoxiaSeverityZone.moderateAltitude,
      );
      expect(
        HighAltitudeHypoxiaCalculator.classifyZone(2115.0),
        HypoxiaSeverityZone.highMountain,
      );
      expect(
        HighAltitudeHypoxiaCalculator.classifyZone(2642.0),
        HypoxiaSeverityZone.extremeAlpine,
      );
    });

    test('Handles edge cases safely (NaN, negative inputs, extreme altitude)',
        () {
      final nanResult = HighAltitudeHypoxiaCalculator.calculate(
        altitudeMeters: double.nan,
        baseVo2Max: -10.0,
        baseFtpWatts: double.infinity,
      );
      expect(nanResult.performanceMultiplier, 1.0);
      expect(nanResult.availableVo2Max, 0.0);
      expect(nanResult.availableFtpWatts, 0.0);

      final extreme = HighAltitudeHypoxiaCalculator.calculate(
        altitudeMeters: 6000.0,
        baseVo2Max: 80.0,
        baseFtpWatts: 400.0,
      );
      expect(
        extreme.performanceMultiplier,
        HighAltitudeHypoxiaCalculator.minPerformanceMultiplier,
      );
      expect(
        extreme.availableFtpWatts,
        closeTo(400.0 * HighAltitudeHypoxiaCalculator.minPerformanceMultiplier,
            1e-6),
      );
    });

    test('calculateForRider reads Rider physiology and nationalityIso', () {
      final rider = Rider(
        id: 'r_col_1',
        firstName: 'Egan',
        lastName: 'Bernal',
        nationalityIso: 'COL',
        birthDate: DateTime(1997, 1, 13),
        potential: 92,
        specialization: RiderSpecialization.gcClimber,
        physiology: const RiderPhysiology(
          heightCm: 175.0,
          weightKg: 60.0,
          bodyFatPercentage: 6.0,
          ftpWatts: 410,
          wPrimeJoules: 21000,
          vo2Max: 88.0,
          maxHr: 196,
          restingHr: 38,
          lactateThresholdHr: 176,
          recoveryRate: 88.0,
          glycogenCapacityGrams: 520.0,
        ),
        powerProfile: const RiderPowerProfile(
          watts5s: 1120,
          watts15s: 920,
          watts30s: 780,
          watts1m: 690,
          watts3m: 540,
          watts5m: 495,
          watts20m: 425,
          watts60m: 390,
        ),
        skills: const RiderSkills(
          cobbles: 64,
          descending: 82,
          bikeHandling: 80,
          aeroPositioning: 76,
          draftingEfficiency: 80,
          raceIq: 86,
          rainResistance: 75,
          heatTolerance: 78,
          timeTrialPositioning: 78,
        ),
        appearance: const RiderAppearance(
          faceShapeIndex: 1,
          skinToneHex: '#C68642',
          hairStyleIndex: 1,
          hairColorHex: '#1A1A1A',
          facialHairIndex: 0,
          glassesModelId: 'aero_pro',
          glassesLensColorHex: '#D4AF37',
          helmetModelId: 'climber_ultralight',
          shoeColorHex: '#FFFFFF',
          sockHeightProportion: 0.6,
          bodyBuildType: BodyBuildType.climberLean,
        ),
        contract: const RiderContract(
          teamId: 'team_1',
          role: RiderRole.teamLeader,
          monthlySalaryEur: 200000,
          signingBonusEur: 100000,
          winBonusEur: 50000,
          releaseClauseEur: 5000000,
          contractEndYear: 2028,
          morale: 0.9,
          leaderLoyalty: 0.9,
          requiredRacesIds: ['tdf'],
        ),
        health: const RiderHealth(
          acuteTrainingLoad: 30.0,
          chronicTrainingLoad: 80.0,
        ),
        careerPointsUci: 1850,
      );

      final result = HighAltitudeHypoxiaCalculator.calculateForRider(
        rider: rider,
        altitudeMeters: AlpineHypoxiaPassBenchmark.galibier.summitAltitudeMeters,
      );

      expect(result.isAndeanNative, isTrue);
      expect(result.acclimatizationMitigationFraction, 0.5);
      expect(result.baseVo2Max, 88.0);
      expect(result.baseFtpWatts, 410.0);
      expect(result.availableVo2Max, lessThan(88.0));
      expect(result.availableFtpWatts, lessThan(410.0));
    });
  });
}
