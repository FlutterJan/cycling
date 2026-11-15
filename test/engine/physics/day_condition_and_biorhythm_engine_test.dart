import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/day_condition_and_biorhythm_engine.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';

void main() {
  group('DayConditionAndBiorhythmEngine', () {
    test('weighted draw stays within [-5, +5] and responds to TSB/sleep/weather/morale/loyalty', () {
      final DayConditionAndBiorhythmEngine engine =
          DayConditionAndBiorhythmEngine(seed: 42);

      const DayConditionDrawInputs peakInputs = DayConditionDrawInputs(
        trainingStressBalance: 20.0,
        sleepQuality: 0.95,
        weatherCondition: WeatherCondition.heavyStorm,
        temperatureCelsius: 10.0,
        rainResistance: 95,
        heatTolerance: 60,
        morale: 0.95,
        leaderLoyalty: 0.95,
      );

      const DayConditionDrawInputs crisisInputs = DayConditionDrawInputs(
        trainingStressBalance: -35.0,
        sleepQuality: 0.25,
        weatherCondition: WeatherCondition.extremeHeat,
        temperatureCelsius: 38.0,
        rainResistance: 70,
        heatTolerance: 20,
        morale: 0.25,
        leaderLoyalty: 0.30,
      );

      expect(
        engine.computeReadinessBias(peakInputs),
        greaterThan(engine.computeReadinessBias(crisisInputs)),
      );

      final Map<int, double> peakWeights =
          engine.computeConditionWeights(peakInputs);
      final Map<int, double> crisisWeights =
          engine.computeConditionWeights(crisisInputs);

      expect(peakWeights[3]!, greaterThan(peakWeights[-3]!));
      expect(crisisWeights[-3]!, greaterThan(crisisWeights[3]!));

      double peakSum = 0.0;
      double crisisSum = 0.0;
      const int samples = 200;
      for (int i = 0; i < samples; i++) {
        final int peakScore = engine.drawConditionScore(peakInputs);
        final int crisisScore = engine.drawConditionScore(crisisInputs);
        expect(peakScore, inInclusiveRange(-5, 5));
        expect(crisisScore, inInclusiveRange(-5, 5));
        peakSum += peakScore;
        crisisSum += crisisScore;
      }

      expect(peakSum / samples, greaterThan(0.5));
      expect(crisisSum / samples, lessThan(-0.5));
    });

    test('condition descriptions match extremes', () {
      expect(
        DayConditionAndBiorhythmEngine.describeCondition(-5),
        'Kryzys / Ciężkie nogi',
      );
      expect(
        DayConditionAndBiorhythmEngine.describeCondition(5),
        'Dzień Konia / Diamentowa noga',
      );
    });

    test('modifiers apply +1.2% FTP, +2.5% W\', recovery speed, and negative VO2max penalty', () {
      final DayConditionModifiers plus1 = DayConditionModifiers.fromScore(1);
      expect(plus1.ftpMultiplier, closeTo(1.012, 1e-6));
      expect(plus1.wPrimeMultiplier, closeTo(1.025, 1e-6));
      expect(plus1.recoverySpeedMultiplier, greaterThan(1.0));
      expect(plus1.applyToFtp(400), 405); // 400 * 1.012 = 404.8 -> 405
      expect(plus1.applyToWPrime(20000), 20500);
      expect(plus1.applyToRecoveryTau(300.0), lessThan(300.0));

      final DayConditionModifiers minus3 = DayConditionModifiers.fromScore(-3);
      expect(minus3.ftpMultiplier, closeTo(0.964, 1e-6));
      expect(minus3.wPrimeMultiplier, closeTo(0.925, 1e-6));
      expect(minus3.vo2MaxMultiplier, closeTo(0.964, 1e-6));
      expect(minus3.applyToVo2Max(80.0), closeTo(77.12, 1e-6));
      expect(minus3.applyToRecoveryTau(300.0), greaterThan(300.0));

      const RiderPhysiology basePhys = RiderPhysiology(
        heightCm: 180.0,
        weightKg: 68.0,
        bodyFatPercentage: 6.5,
        ftpWatts: 400,
        wPrimeJoules: 20000,
        vo2Max: 82.0,
        maxHr: 192,
        restingHr: 38,
        lactateThresholdHr: 172,
        recoveryRate: 1.0,
        glycogenCapacityGrams: 550.0,
      );

      final RiderPhysiology boosted =
          DayConditionModifiers.fromScore(5).applyToPhysiology(basePhys);
      expect(boosted.ftpWatts, 424); // +6.0%
      expect(boosted.wPrimeJoules, 22500); // +12.5%
      expect(boosted.vo2Max, closeTo(82.0 * 1.06, 1e-6));
      expect(boosted.recoveryRate, greaterThan(1.0));
    });

    test('discovery mechanics: hidden under ? until HR > LT1 on first climb unless player did warmup', () {
      final DayConditionAndBiorhythmEngine engine =
          DayConditionAndBiorhythmEngine(seed: 7);

      const DayConditionDrawInputs playerWarmupInputs = DayConditionDrawInputs(
        trainingStressBalance: 5.0,
        sleepQuality: 0.8,
        weatherCondition: WeatherCondition.sunny,
        temperatureCelsius: 22.0,
        rainResistance: 70,
        heatTolerance: 75,
        morale: 0.85,
        leaderLoyalty: 0.9,
        isPlayerRider: true,
        didTrainerWarmup: true,
      );

      const DayConditionDrawInputs playerNoWarmupInputs = DayConditionDrawInputs(
        trainingStressBalance: 5.0,
        sleepQuality: 0.8,
        weatherCondition: WeatherCondition.sunny,
        temperatureCelsius: 22.0,
        rainResistance: 70,
        heatTolerance: 75,
        morale: 0.85,
        leaderLoyalty: 0.9,
        isPlayerRider: true,
        didTrainerWarmup: false,
      );

      const DayConditionDrawInputs rivalInputs = DayConditionDrawInputs(
        trainingStressBalance: 5.0,
        sleepQuality: 0.8,
        weatherCondition: WeatherCondition.sunny,
        temperatureCelsius: 22.0,
        rainResistance: 70,
        heatTolerance: 75,
        morale: 0.85,
        leaderLoyalty: 0.9,
        isPlayerRider: false,
        didTrainerWarmup: true,
      );

      final RiderDayConditionState warmedUp = engine.createInitialStageState(
        riderId: 'p1',
        inputs: playerWarmupInputs,
      );
      expect(warmedUp.isRevealed, isTrue);
      expect(warmedUp.displayBadge, isNot('?'));

      final RiderDayConditionState coldPlayer = engine.createInitialStageState(
        riderId: 'p2',
        inputs: playerNoWarmupInputs,
      );
      expect(coldPlayer.isRevealed, isFalse);
      expect(coldPlayer.displayBadge, '?');

      final RiderDayConditionState rival = engine.createInitialStageState(
        riderId: 'r1',
        inputs: rivalInputs,
      );
      expect(rival.isRevealed, isFalse);
      expect(rival.displayBadge, '?');

      // Na płaskim terenie nawet przy wysokim tętnie dyspozycja pozostaje ukryta
      final RiderDayConditionState flatHighHr = engine.evaluateRevealOnClimb(
        currentState: coldPlayer,
        currentHeartRateBpm: 165,
        lt1HeartRateBpm: 150,
        currentGradientPercent: 0.5,
        distanceCoveredMeters: 12000.0,
      );
      expect(flatHighHr.isRevealed, isFalse);

      // Na podjeździe, ale tętno dokładnie na LT1 (nie przekroczyło) -> nadal ukryte
      final RiderDayConditionState climbAtLt1 = engine.evaluateRevealOnClimb(
        currentState: flatHighHr,
        currentHeartRateBpm: 150,
        lt1HeartRateBpm: 150,
        currentGradientPercent: 5.5,
        distanceCoveredMeters: 25000.0,
      );
      expect(climbAtLt1.isRevealed, isFalse);

      // Na pierwszym podjeździe i tętno > LT1 -> odkrycie!
      final RiderDayConditionState revealed = engine.evaluateRevealOnClimb(
        currentState: climbAtLt1,
        currentHeartRateBpm: 151,
        lt1HeartRateBpm: 150,
        currentGradientPercent: 5.5,
        distanceCoveredMeters: 25400.0,
      );
      expect(revealed.isRevealed, isTrue);
      expect(revealed.revealedAtDistanceMeters, 25400.0);
      expect(revealed.revealedAtHeartRateBpm, 151);
      expect(revealed.displayBadge, isNot('?'));

      // Round-trip JSON
      final RiderDayConditionState roundTrip =
          RiderDayConditionState.fromJson(revealed.toJson());
      expect(roundTrip, equals(revealed));
    });
  });
}
