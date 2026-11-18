import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/brake_rotor_heat_and_fade_descent_solver.dart';

void main() {
  group('BrakeRotorHeatAndFadeDescentSolver', () {
    test('computeFadeFactor returns 1.0 up to 450°C and drops above 450°C', () {
      expect(
        BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
          rotorTempCelsius: 250.0,
        ),
        1.0,
      );
      expect(
        BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
          rotorTempCelsius: 450.0,
        ),
        1.0,
      );

      final fade490 = BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
        rotorTempCelsius: 490.0,
      );
      final fade560 = BrakeRotorHeatAndFadeDescentSolver.computeFadeFactor(
        rotorTempCelsius: 560.0,
      );

      expect(fade490, lessThan(1.0));
      expect(fade560, lessThan(fade490));
      expect(
        fade560,
        greaterThanOrEqualTo(BrakePadCompound.worldTourFinned.minFadeFloor),
      );
    });

    test('85 km/h to 25 km/h braking heats front rotor more than rear rotor', () {
      const corner = AlpineHairpinCornerSpec(
        index: 1,
        entrySpeedKmh: 85.0,
        apexSpeedKmh: 25.0,
        gradientPercent: -9.0,
        altitudeMeters: 2200.0,
      );
      const config = BrakeRotorSystemConfig(
        frontRotor: BrakeRotorDiameter.mm140,
        rearRotor: BrakeRotorDiameter.mm140,
        coolingTech: BrakeRotorCoolingTech.standardSteel,
        totalSystemMassKg: 78.0,
      );

      final result =
          BrakeRotorHeatAndFadeDescentSolver.simulateSingleHairpinBraking(
        corner: corner,
        config: config,
        frontTempBeforeCelsius: 120.0,
        rearTempBeforeCelsius: 120.0,
      );

      expect(result.frontTempAfterCelsius, greaterThan(120.0));
      expect(
        result.frontTempAfterCelsius,
        greaterThan(result.rearTempAfterCelsius),
      );
      expect(result.energyDissipatedKj, greaterThan(15.0));
      expect(result.fadeFactor, 1.0);
      expect(result.brakingDistanceExtensionMeters, 0.0);
    });

    test('overheating > 450°C causes Brake Fade and extends braking distance', () {
      const corner = AlpineHairpinCornerSpec(
        index: 10,
        entrySpeedKmh: 85.0,
        apexSpeedKmh: 25.0,
        gradientPercent: -10.0,
        altitudeMeters: 2100.0,
        availableBrakingRunwayMeters: 52.0,
      );
      const config = BrakeRotorSystemConfig(
        frontRotor: BrakeRotorDiameter.mm140,
        rearRotor: BrakeRotorDiameter.mm140,
        coolingTech: BrakeRotorCoolingTech.standardSteel,
        padCompound: BrakePadCompound.worldTourFinned,
        totalSystemMassKg: 82.0,
      );

      final fadedResult =
          BrakeRotorHeatAndFadeDescentSolver.simulateSingleHairpinBraking(
        corner: corner,
        config: config,
        frontTempBeforeCelsius: 485.0,
        rearTempBeforeCelsius: 340.0,
      );

      expect(fadedResult.isFading, isTrue);
      expect(fadedResult.fadeFactor, lessThan(1.0));
      expect(fadedResult.brakeForceLossPercent, greaterThan(5.0));
      expect(
        fadedResult.actualBrakingDistanceMeters,
        greaterThan(fadedResult.baselineBrakingDistanceMeters),
      );
      expect(fadedResult.brakingDistanceExtensionMeters, greaterThan(2.0));
      expect(fadedResult.timeLostToFadeSeconds, greaterThan(0.0));
      expect(
        fadedResult.frontThermalZone,
        anyOf(RotorThermalZone.fadeOnset, RotorThermalZone.criticalBoil),
      );
    });

    test('140 mm rotors run hotter and fade more than 160 mm rotors on Stelvio', () {
      final corners = BrakeRotorHeatAndFadeDescentSolver.buildPresetCorners(
        AlpineDescentPreset.passoDelloStelvio,
      );
      const baseConfig = BrakeRotorSystemConfig(
        coolingTech: BrakeRotorCoolingTech.standardSteel,
        padCompound: BrakePadCompound.worldTourFinned,
        totalSystemMassKg: 82.0,
        descenderSkill: 45,
      );

      final comparison =
          BrakeRotorHeatAndFadeDescentSolver.compare140mmVs160mm(
        baseConfig: baseConfig,
        corners: corners,
        environment: const DescentEnvironmentConditions(
          ambientTempCelsius: 26.0,
          isWetRoad: false,
        ),
      );

      expect(
        comparison.result140mm.peakMaxTempCelsius,
        greaterThan(comparison.result160mm.peakMaxTempCelsius),
      );
      expect(comparison.peakTempDifferenceCelsius, greaterThan(25.0));
      expect(comparison.result140mm.fadeTriggeredHairpinCount, greaterThan(0));
      expect(
        comparison.result140mm.maxBrakingDistanceExtensionMeters,
        greaterThan(comparison.result160mm.maxBrakingDistanceExtensionMeters),
      );
      expect(comparison.totalTimeSavedWith160mmSeconds, greaterThanOrEqualTo(0.0));
    });

    test('convective cooling lowers rotor temp and wet road cools faster', () {
      final dryCooled =
          BrakeRotorHeatAndFadeDescentSolver.simulateCoolingInterval(
        startTempCelsius: 400.0,
        intervalDistanceMeters: 400.0,
        averageSpeedKmh: 75.0,
        rotor: BrakeRotorDiameter.mm160,
        coolingTech: BrakeRotorCoolingTech.iceTechFinned,
        altitudeMeters: 1500.0,
        environment: const DescentEnvironmentConditions(isWetRoad: false),
      );

      final wetCooled =
          BrakeRotorHeatAndFadeDescentSolver.simulateCoolingInterval(
        startTempCelsius: 400.0,
        intervalDistanceMeters: 400.0,
        averageSpeedKmh: 75.0,
        rotor: BrakeRotorDiameter.mm160,
        coolingTech: BrakeRotorCoolingTech.iceTechFinned,
        altitudeMeters: 1500.0,
        environment: const DescentEnvironmentConditions(isWetRoad: true),
      );

      expect(dryCooled, lessThan(400.0));
      expect(wetCooled, lessThan(dryCooled));
    });

    test('handles empty corners and non-braking speed edge cases gracefully', () {
      const config = BrakeRotorSystemConfig();
      final emptyResult =
          BrakeRotorHeatAndFadeDescentSolver.simulateAlpineDescent(
        config: config,
        corners: const [],
      );
      expect(emptyResult.hairpinSteps, isEmpty);
      expect(emptyResult.fadeTriggeredHairpinCount, 0);
      expect(emptyResult.minFadeFactorObserved, 1.0);

      final noBrakeCorner =
          BrakeRotorHeatAndFadeDescentSolver.simulateSingleHairpinBraking(
        corner: const AlpineHairpinCornerSpec(
          index: 1,
          entrySpeedKmh: 30.0,
          apexSpeedKmh: 35.0,
        ),
        config: config,
        frontTempBeforeCelsius: 90.0,
        rearTempBeforeCelsius: 80.0,
      );
      expect(noBrakeCorner.energyDissipatedKj, 0.0);
      expect(noBrakeCorner.actualBrakingDistanceMeters, 0.0);
      expect(noBrakeCorner.isFading, isFalse);
    });
  });
}
