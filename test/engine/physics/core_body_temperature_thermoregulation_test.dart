import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/core_body_temperature_thermoregulation.dart';

void main() {
  group('CoreBodyTemperatureThermoregulation', () {
    test('calculates metabolic heat production Q_prod = P * (1 - eta) / eta',
        () {
      const power = 350.0;
      const eta = 0.23;
      final qProd =
          CoreBodyTemperatureThermoregulation.calculateMetabolicHeatProductionWatts(
        powerWatts: power,
        grossEfficiency: eta,
      );

      expect(qProd, closeTo(power * (1.0 - eta) / eta, 1e-6));
      expect(
        CoreBodyTemperatureThermoregulation.calculateMetabolicHeatProductionWatts(
          powerWatts: -50.0,
        ),
        0.0,
      );
    });

    test('convective cooling scales proportionally to v^0.6', () {
      const v1 = 4.0;
      const v2 = 12.0;

      final q1 =
          CoreBodyTemperatureThermoregulation.calculateConvectiveCoolingWatts(
        airSpeedMps: v1,
        skinTemperatureCelsius: 35.0,
        ambientTemperatureCelsius: 20.0,
      );
      final q2 =
          CoreBodyTemperatureThermoregulation.calculateConvectiveCoolingWatts(
        airSpeedMps: v2,
        skinTemperatureCelsius: 35.0,
        ambientTemperatureCelsius: 20.0,
      );

      expect(q2 / q1, closeTo(math.pow(v2 / v1, 0.6), 1e-6));
    });

    test('core temperature rises on steep hot climb and stays within [37.0, 40.5]',
        () {
      var state = const ThermoregulationState();
      const input = ThermoregulationStepInput(
        powerWatts: 380.0,
        airSpeedMps: 3.5, // slow climb
        ambientTemperatureCelsius: 36.0,
        relativeHumidity: 0.75,
        deltaTimeSeconds: 60.0,
      );

      for (int i = 0; i < 60; i++) {
        final result = CoreBodyTemperatureThermoregulation.step(
          currentState: state,
          input: input,
        );
        state = result.updatedState;
        expect(state.coreBodyTemperatureCelsius, greaterThanOrEqualTo(37.0));
        expect(state.coreBodyTemperatureCelsius, lessThanOrEqualTo(40.5));
      }

      expect(state.coreBodyTemperatureCelsius, greaterThan(39.2));
    });

    test('evaporative cooling is reduced by high humidity and rain jacket', () {
      final dryEvap =
          CoreBodyTemperatureThermoregulation.calculateEvaporativeCooling(
        coreTemperatureCelsius: 38.8,
        skinTemperatureCelsius: 35.5,
        ambientTemperatureCelsius: 34.0,
        relativeHumidity: 0.30,
        airSpeedMps: 4.0,
      );

      final humidEvap =
          CoreBodyTemperatureThermoregulation.calculateEvaporativeCooling(
        coreTemperatureCelsius: 38.8,
        skinTemperatureCelsius: 35.5,
        ambientTemperatureCelsius: 34.0,
        relativeHumidity: 0.95,
        airSpeedMps: 4.0,
      );

      final jacketEvap =
          CoreBodyTemperatureThermoregulation.calculateEvaporativeCooling(
        coreTemperatureCelsius: 38.8,
        skinTemperatureCelsius: 35.5,
        ambientTemperatureCelsius: 34.0,
        relativeHumidity: 0.30,
        airSpeedMps: 4.0,
        wearingRainJacket: true,
      );

      expect(dryEvap.evaporativeCoolingWatts,
          greaterThan(humidEvap.evaporativeCoolingWatts));
      expect(dryEvap.evaporativeCoolingWatts,
          greaterThan(jacketEvap.evaporativeCoolingWatts));
    });

    test('applies max power drop and +12 BPM heart rate drift above 39.2 C',
        () {
      expect(
        CoreBodyTemperatureThermoregulation.evaluateMaxPowerMultiplier(39.2),
        1.0,
      );
      expect(
        CoreBodyTemperatureThermoregulation.evaluateHeartRateDriftBpm(39.2),
        0.0,
      );

      final overheatedPowerMult =
          CoreBodyTemperatureThermoregulation.evaluateMaxPowerMultiplier(39.8);
      final overheatedHrDrift =
          CoreBodyTemperatureThermoregulation.evaluateHeartRateDriftBpm(39.8);

      expect(overheatedPowerMult, lessThan(1.0));
      expect(overheatedPowerMult, greaterThanOrEqualTo(0.75));
      expect(overheatedHrDrift, 12.0);
      expect(
        CoreBodyTemperatureThermoregulation.classifyZone(39.8),
        CoreThermalZone.hyperthermicCollapse,
      );
    });

    test('cool descent brings elevated core temperature back down toward 37.0 C',
        () {
      var state = const ThermoregulationState(
        coreBodyTemperatureCelsius: 39.4,
        skinTemperatureCelsius: 35.5,
      );
      const descentInput = ThermoregulationStepInput(
        powerWatts: 50.0,
        airSpeedMps: 18.0, // 64.8 km/h
        ambientTemperatureCelsius: 14.0,
        relativeHumidity: 0.45,
        deltaTimeSeconds: 60.0,
      );

      for (int i = 0; i < 20; i++) {
        final result = CoreBodyTemperatureThermoregulation.step(
          currentState: state,
          input: descentInput,
        );
        state = result.updatedState;
      }

      expect(state.coreBodyTemperatureCelsius, lessThan(39.2));
      expect(state.coreBodyTemperatureCelsius, greaterThanOrEqualTo(37.0));
    });
  });
}
