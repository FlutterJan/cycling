import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/altitude_acclimatization_and_heat_engine.dart';

void main() {
  group('AltitudeAcclimatizationAndHeatEngine - Altitude Model', () {
    test('No FTP loss at or below 1500m altitude', () {
      final resultSeaLevel =
          AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 150.0,
        baseFtpWatts: 400.0,
        nationalityIso: 'POL',
      );
      final resultThreshold =
          AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 1500.0,
        baseFtpWatts: 400.0,
        nationalityIso: 'FRA',
      );

      expect(resultSeaLevel.ftpMultiplier, 1.0);
      expect(resultSeaLevel.effectiveFtpWatts, 400.0);
      expect(resultSeaLevel.ftpLossPercent, 0.0);

      expect(resultThreshold.ftpMultiplier, 1.0);
      expect(resultThreshold.effectiveFtpWatts, 400.0);
    });

    test('Unacclimatized rider loses 1.5% FTP per 300m above 1500m (-6% at 2700m)',
        () {
      final result =
          AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 2700.0,
        baseFtpWatts: 400.0,
        altitudeAcclimatizationScore: 0.0,
        nationalityIso: 'BEL',
      );

      expect(result.isHighAltitudeNative, isFalse);
      expect(result.rawFtpLossFraction, closeTo(0.06, 1e-6));
      expect(result.actualFtpLossFraction, closeTo(0.06, 1e-6));
      expect(result.ftpLossPercent, closeTo(6.0, 1e-4));
      expect(result.ftpMultiplier, closeTo(0.94, 1e-6));
      expect(result.effectiveFtpWatts, closeTo(376.0, 1e-4));
    });

    test('Acclimatized rider (score 100) loses half as much (-3% at 2700m)',
        () {
      final result =
          AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 2700.0,
        baseFtpWatts: 400.0,
        altitudeAcclimatizationScore: 100.0,
        nationalityIso: 'FRA',
      );

      expect(result.actualFtpLossFraction, closeTo(0.03, 1e-6));
      expect(result.ftpLossPercent, closeTo(3.0, 1e-4));
      expect(result.ftpMultiplier, closeTo(0.97, 1e-6));
      expect(result.effectiveFtpWatts, closeTo(388.0, 1e-4));
    });

    test('High-altitude native riders (COL, ECU) lose half as much even at score 0',
        () {
      final colResult =
          AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 2700.0,
        baseFtpWatts: 400.0,
        altitudeAcclimatizationScore: 0.0,
        nationalityIso: 'COL',
      );
      final ecuResult =
          AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 2700.0,
        baseFtpWatts: 400.0,
        altitudeAcclimatizationScore: 0.0,
        nationalityIso: 'ecu',
      );

      expect(colResult.isHighAltitudeNative, isTrue);
      expect(colResult.ftpMultiplier, closeTo(0.97, 1e-6));
      expect(colResult.effectiveFtpWatts, closeTo(388.0, 1e-4));

      expect(ecuResult.isHighAltitudeNative, isTrue);
      expect(ecuResult.ftpMultiplier, closeTo(0.97, 1e-6));
    });

    test('Acclimatization score updates properly at camp and decays at sea level',
        () {
      final afterCamp = AltitudeAcclimatizationAndHeatEngine
          .updateAltitudeAcclimatizationScore(
        currentScore: 10.0,
        campAltitudeMeters: 2200.0,
        daysAtAltitude: 14,
      );
      expect(afterCamp, greaterThan(70.0));
      expect(afterCamp, lessThanOrEqualTo(100.0));

      final afterDecay = AltitudeAcclimatizationAndHeatEngine
          .updateAltitudeAcclimatizationScore(
        currentScore: afterCamp,
        campAltitudeMeters: 200.0,
        daysAtAltitude: 10,
      );
      expect(afterDecay, lessThan(afterCamp));
      expect(afterDecay, greaterThanOrEqualTo(0.0));
    });
  });

  group('AltitudeAcclimatizationAndHeatEngine - Heat Stress & Ice Socks', () {
    test('Core body temperature rises toward 39.5°C when climbing in >32°C heat',
        () {
      var state = const RiderThermalState(
        coreBodyTemperatureCelsius: 37.0,
        iceSocksAvailableInTeamCar: 3,
      );

      late HeatStrainStepResult lastStep;
      // Simulate 45 minutes (2700s) of steep climbing in 35°C heat at low airspeed (4.2 m/s)
      for (int i = 0; i < 45; i++) {
        lastStep = AltitudeAcclimatizationAndHeatEngine.simulateThermalStep(
          currentState: state,
          deltaTimeSeconds: 60.0,
          ambientTemperatureCelsius: 35.0,
          airSpeedMetersPerSecond: 4.2,
          currentPowerWatts: 380.0,
          baseFtpWatts: 380.0,
          heatTolerance: 50,
          gradientPercent: 8.5,
        );
        state = lastStep.updatedState;
      }

      expect(state.coreBodyTemperatureCelsius, greaterThan(38.8));
      expect(state.coreBodyTemperatureCelsius, lessThanOrEqualTo(40.2));
      expect(lastStep.thermalFtpMultiplier, lessThan(1.0));
      expect(lastStep.heartRateThermalDriftBpm, greaterThan(5.0));
      expect(lastStep.shouldRecommendIceSocks, isTrue);
    });

    test('Ice Socks from team car cool the rider and prevent overheating', () {
      var hotState = const RiderThermalState(
        coreBodyTemperatureCelsius: 38.6,
        iceSocksAvailableInTeamCar: 2,
      );

      final withIce =
          AltitudeAcclimatizationAndHeatEngine.deployIceSocks(hotState);
      expect(withIce.isIceSockActive, isTrue);
      expect(withIce.iceSocksUsedCount, 1);
      expect(withIce.iceSocksAvailableInTeamCar, 1);

      var cooledState = withIce;
      for (int i = 0; i < 10; i++) {
        final step = AltitudeAcclimatizationAndHeatEngine.simulateThermalStep(
          currentState: cooledState,
          deltaTimeSeconds: 60.0,
          ambientTemperatureCelsius: 34.0,
          airSpeedMetersPerSecond: 4.5,
          currentPowerWatts: 360.0,
          baseFtpWatts: 380.0,
          gradientPercent: 7.0,
        );
        cooledState = step.updatedState;
      }

      expect(
        cooledState.coreBodyTemperatureCelsius,
        lessThan(hotState.coreBodyTemperatureCelsius),
      );
      expect(cooledState.isOverheating, isFalse);
    });

    test('Deploying Ice Socks when stock is empty does nothing', () {
      const emptyStockState = RiderThermalState(
        coreBodyTemperatureCelsius: 38.5,
        iceSocksAvailableInTeamCar: 0,
      );

      final result =
          AltitudeAcclimatizationAndHeatEngine.deployIceSocks(emptyStockState);
      expect(result.isIceSockActive, isFalse);
      expect(result.iceSocksUsedCount, 0);
      expect(result.iceSocksAvailableInTeamCar, 0);
    });

    test('Combined altitude and heat evaluation reduces effective FTP accurately',
        () {
      const hotState = RiderThermalState(
        coreBodyTemperatureCelsius: 39.2,
      );

      final combined =
          AltitudeAcclimatizationAndHeatEngine.evaluateCombinedStep(
        altitudeMeters: 2700.0,
        baseFtpWatts: 400.0,
        altitudeAcclimatizationScore: 0.0,
        nationalityIso: 'POL',
        thermalState: hotState,
        deltaTimeSeconds: 0.0,
        ambientTemperatureCelsius: 33.0,
        airSpeedMetersPerSecond: 5.0,
        currentPowerWatts: 350.0,
      );

      expect(combined.altitudeResult.ftpMultiplier, closeTo(0.94, 1e-6));
      expect(combined.heatResult.thermalFtpMultiplier, lessThan(0.94));
      expect(
        combined.combinedFtpMultiplier,
        closeTo(
          combined.altitudeResult.ftpMultiplier *
              combined.heatResult.thermalFtpMultiplier,
          1e-6,
        ),
      );
      expect(
        combined.effectiveFtpWatts,
        closeTo(400.0 * combined.combinedFtpMultiplier, 1e-4),
      );
    });
  });
}
