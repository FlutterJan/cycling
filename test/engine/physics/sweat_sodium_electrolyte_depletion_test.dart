import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/sweat_sodium_electrolyte_depletion.dart';

void main() {
  group('SweatSodiumElectrolyteDepletion', () {
    test('clamps sweat rate to [0.8, 2.5] l/h and sweat sodium to [500, 1500] mg/l', () {
      final lowProfile = RiderSweatProfile(
        baseSweatRateLitersPerHour: 0.2,
        sweatSodiumConcentrationMgPerL: 150.0,
        riderMassKg: 65.0,
      );
      final highProfile = RiderSweatProfile(
        baseSweatRateLitersPerHour: 4.0,
        sweatSodiumConcentrationMgPerL: 2500.0,
        riderMassKg: 75.0,
      );

      expect(lowProfile.baseSweatRateLitersPerHour, 0.8);
      expect(lowProfile.sweatSodiumConcentrationMgPerL, 500.0);
      expect(highProfile.baseSweatRateLitersPerHour, 2.5);
      expect(highProfile.sweatSodiumConcentrationMgPerL, 1500.0);

      final coldLowRate =
          SweatSodiumElectrolyteDepletion.calculateEffectiveSweatRateLitersPerHour(
        profile: lowProfile,
        powerWatts: 100.0,
        ftpWatts: 350.0,
        ambientTemperatureCelsius: 8.0,
      );
      final hotHighRate =
          SweatSodiumElectrolyteDepletion.calculateEffectiveSweatRateLitersPerHour(
        profile: highProfile,
        powerWatts: 480.0,
        ftpWatts: 350.0,
        ambientTemperatureCelsius: 40.0,
        coreBodyTemperatureCelsius: 39.4,
      );

      expect(coldLowRate, inInclusiveRange(0.8, 2.5));
      expect(hotHighRate, inInclusiveRange(0.8, 2.5));
      expect(hotHighRate, 2.5);
    });

    test('heat acclimatization reduces effective sweat sodium concentration', () {
      final unacclimatized = RiderSweatProfile(
        sweatSodiumConcentrationMgPerL: 1200.0,
        heatAcclimatization: 0.0,
      );
      final acclimatized = RiderSweatProfile(
        sweatSodiumConcentrationMgPerL: 1200.0,
        heatAcclimatization: 1.0,
      );

      final naUnacc =
          SweatSodiumElectrolyteDepletion.calculateEffectiveSweatSodiumMgPerL(
        profile: unacclimatized,
      );
      final naAcc =
          SweatSodiumElectrolyteDepletion.calculateEffectiveSweatSodiumMgPerL(
        profile: acclimatized,
      );

      expect(naUnacc, 1200.0);
      expect(naAcc, lessThan(naUnacc));
      expect(naAcc, inInclusiveRange(500.0, 1500.0));
    });

    test('dehydration above 3% body mass triggers Muscle Cramps and blocks final sprint', () {
      // 65 kg rider -> 3% body mass = 1.95 kg = 1950 ml fluid deficit
      final profile = RiderSweatProfile(
        baseSweatRateLitersPerHour: 2.2,
        sweatSodiumConcentrationMgPerL: 800.0,
        riderMassKg: 65.0,
      );
      var state = SweatElectrolyteState.initial(profile);

      // Simulate 90 minutes in heat with no fluid intake
      for (int i = 0; i < 90; i++) {
        final result = SweatSodiumElectrolyteDepletion.step(
          profile: profile,
          currentState: state,
          input: SweatElectrolyteStepInput(
            deltaTimeSeconds: 60.0,
            powerWatts: 310.0,
            ftpWatts: 350.0,
            ambientTemperatureCelsius: 34.0,
            coreBodyTemperatureCelsius: 38.7,
            distanceToFinishMeters: i == 89 ? 1500.0 : 40000.0,
            isSprintingOrHighTorque: i == 89,
          ),
        );
        state = result.updatedState;
      }

      final finalStep = SweatSodiumElectrolyteDepletion.step(
        profile: profile,
        currentState: state,
        input: const SweatElectrolyteStepInput(
          deltaTimeSeconds: 10.0,
          powerWatts: 950.0,
          ftpWatts: 350.0,
          ambientTemperatureCelsius: 34.0,
          coreBodyTemperatureCelsius: 38.9,
          distanceToFinishMeters: 800.0,
          isSprintingOrHighTorque: true,
        ),
      );

      expect(finalStep.dehydrationPercent, greaterThan(3.0));
      expect(finalStep.isDehydrationAboveCrampThreshold, isTrue);
      expect(finalStep.hasMuscleCramps, isTrue);
      expect(finalStep.isSprintBlocked, isTrue);
      expect(finalStep.status, HydrationElectrolyteStatus.muscleCramps);
      expect(finalStep.sprintPowerCapMultiplier, lessThanOrEqualTo(0.55));
      expect(finalStep.heartRateDriftBpm, greaterThan(4.0));
    });

    test('sodium depletion without electrolyte tablets triggers Muscle Cramps even when drinking plain water', () {
      // Heavy salty sweater (1500 mg/l) drinking only plain water
      final profile = RiderSweatProfile(
        baseSweatRateLitersPerHour: 1.8,
        sweatSodiumConcentrationMgPerL: 1500.0,
        riderMassKg: 70.0,
      );
      var state = SweatElectrolyteState.initial(profile);

      late SweatElectrolyteStepResult lastResult;
      for (int min = 0; min < 110; min++) {
        final intakes = (min % 20 == 10)
            ? <ElectrolyteIntakeEvent>[
                ElectrolyteIntakeEvent.plainWaterBidon(volumeMl: 600.0),
              ]
            : const <ElectrolyteIntakeEvent>[];

        lastResult = SweatSodiumElectrolyteDepletion.step(
          profile: profile,
          currentState: state,
          input: SweatElectrolyteStepInput(
            deltaTimeSeconds: 60.0,
            powerWatts: 320.0,
            ftpWatts: 350.0,
            ambientTemperatureCelsius: 32.0,
            coreBodyTemperatureCelsius: 38.5,
            distanceToFinishMeters: min >= 105 ? 2000.0 : 30000.0,
            intakes: intakes,
          ),
        );
        state = lastResult.updatedState;
      }

      expect(lastResult.dehydrationPercent, lessThan(3.0));
      expect(lastResult.isSodiumCriticallyDepleted, isTrue);
      expect(lastResult.hasMuscleCramps, isTrue);
      expect(lastResult.isSprintBlocked, isTrue);
      expect(state.electrolyteTabletsTaken, 0);
    });

    test('electrolyte tablets prevent sodium cramps and keep final sprint unlocked', () {
      final profile = RiderSweatProfile(
        baseSweatRateLitersPerHour: 1.5,
        sweatSodiumConcentrationMgPerL: 1200.0,
        riderMassKg: 70.0,
      );
      var state = SweatElectrolyteState.initial(profile);

      late SweatElectrolyteStepResult lastResult;
      for (int min = 0; min < 110; min++) {
        final intakes = (min % 15 == 10)
            ? <ElectrolyteIntakeEvent>[
                ElectrolyteIntakeEvent.electrolyteTablet(
                  fluidMl: 550.0,
                  tabletSodiumMg: 750.0,
                ),
              ]
            : const <ElectrolyteIntakeEvent>[];

        lastResult = SweatSodiumElectrolyteDepletion.step(
          profile: profile,
          currentState: state,
          input: SweatElectrolyteStepInput(
            deltaTimeSeconds: 60.0,
            powerWatts: 320.0,
            ftpWatts: 350.0,
            ambientTemperatureCelsius: 32.0,
            coreBodyTemperatureCelsius: 38.5,
            distanceToFinishMeters: min >= 105 ? 1200.0 : 30000.0,
            isSprintingOrHighTorque: min == 109,
            intakes: intakes,
          ),
        );
        state = lastResult.updatedState;
      }

      expect(state.electrolyteTabletsTaken, greaterThanOrEqualTo(5));
      expect(lastResult.dehydrationPercent, lessThan(3.0));
      expect(lastResult.hasMuscleCramps, isFalse);
      expect(lastResult.isSprintBlocked, isFalse);
      expect(lastResult.sprintPowerCapMultiplier, 1.0);
    });

    test('handles zero deltaTimeSeconds and negative power safely', () {
      final profile = RiderSweatProfile();
      final state = SweatElectrolyteState.initial(profile);

      final result = SweatSodiumElectrolyteDepletion.step(
        profile: profile,
        currentState: state,
        input: const SweatElectrolyteStepInput(
          deltaTimeSeconds: 0.0,
          powerWatts: -100.0,
        ),
      );

      expect(result.sweatLossStepMl, 0.0);
      expect(result.sodiumLossStepMg, 0.0);
      expect(result.dehydrationPercent, 0.0);
      expect(result.hasMuscleCramps, isFalse);
      expect(result.status, HydrationElectrolyteStatus.optimal);
    });
  });
}
