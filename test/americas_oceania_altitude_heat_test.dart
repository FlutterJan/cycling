import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/altitude_acclimatization_and_heat_engine.dart';
import 'package:pro_peloton_manager/engine/physics/extreme_altitude_3000m_and_heatwave_solver.dart';
import 'package:pro_peloton_manager/models/race/americas_and_oceania_tours_model.dart';

void main() {
  group('Americas & Oceania Tours — Alto del Colorado (>3000 m) & Tour Down Under (42°C)', () {
    test('AmericasAndOceaniaToursModel definiuje Vuelta a San Juan (>3000 m) i Tour Down Under (>=40°C)', () {
      final model = AmericasAndOceaniaToursModel.standard(seasonYear: 2026);

      final sanJuan = model.findById(AmericasOceaniaRaceId.vueltaASanJuan);
      expect(sanJuan, isNotNull);
      expect(sanJuan!.climateHazard, AmericasOceaniaClimateHazard.andeanHighAltitudeHypoxia);
      expect(
        sanJuan.stageTemplates.any(
          (s) => s.signatureFeature == AmericasOceaniaSignatureFeature.altoDelColorado3265mSummit,
        ),
        isTrue,
      );
      expect(sanJuan.logistics.peakAltitudeMeters, greaterThan(3000.0));
      expect(
        sanJuan.logistics.recommendedMethod,
        AmericasOceaniaAcclimatizationMethod.hypobaricAltitudeCamp,
      );

      final tdu = model.findById(AmericasOceaniaRaceId.santosTourDownUnder);
      expect(tdu, isNotNull);
      expect(tdu!.climateHazard, AmericasOceaniaClimateHazard.australianOutbackExtremeHeat);
      expect(
        tdu.stageTemplates.any(
          (s) => s.signatureFeature == AmericasOceaniaSignatureFeature.willungaHillExplosiveClimb,
        ),
        isTrue,
      );
      expect(tdu.logistics.maxTemperatureCelsius, greaterThanOrEqualTo(40.0));
      expect(
        tdu.logistics.recommendedMethod,
        AmericasOceaniaAcclimatizationMethod.heatChamberAndIceCooling,
      );

      final sanJuanUnprepared = model.evaluateRaceEntry(
        raceId: AmericasOceaniaRaceId.vueltaASanJuan,
        daysOnSite: 0,
        method: AmericasOceaniaAcclimatizationMethod.none,
        availableBudgetEur: 250000,
      );
      final sanJuanPrepared = model.evaluateRaceEntry(
        raceId: AmericasOceaniaRaceId.vueltaASanJuan,
        daysOnSite: sanJuan.logistics.recommendedAcclimatizationDays,
        method: AmericasOceaniaAcclimatizationMethod.hypobaricAltitudeCamp,
        availableBudgetEur: 250000,
      );

      expect(sanJuanUnprepared.hypoxiaPowerDropPercent, greaterThan(8.0));
      expect(sanJuanPrepared.readinessScore, closeTo(1.0, 1e-6));
      expect(sanJuanPrepared.climatePenaltyPercent, lessThan(sanJuanUnprepared.climatePenaltyPercent));
      expect(sanJuanPrepared.isRecommendedForSquad, isTrue);

      final tduUnprepared = model.evaluateRaceEntry(
        raceId: AmericasOceaniaRaceId.santosTourDownUnder,
        daysOnSite: 0,
        method: AmericasOceaniaAcclimatizationMethod.none,
        availableBudgetEur: 250000,
      );
      final tduPrepared = model.evaluateRaceEntry(
        raceId: AmericasOceaniaRaceId.santosTourDownUnder,
        daysOnSite: tdu.logistics.recommendedAcclimatizationDays,
        method: AmericasOceaniaAcclimatizationMethod.heatChamberAndIceCooling,
        availableBudgetEur: 250000,
      );

      expect(tduUnprepared.heatStressIndex, greaterThan(0.8));
      expect(tduPrepared.readinessScore, closeTo(1.0, 1e-6));
      expect(tduPrepared.climatePenaltyPercent, lessThan(tduUnprepared.climatePenaltyPercent));
    });
  });

  group('Fizjologia wspinaczki >3000 m n.p.m. w Andach (Alto del Colorado)', () {
    test('Alto del Colorado (3050–3265 m) aktywuje strefę ekstremalnej hipoksji i wydłuża tau W\' o >=45%', () {
      const seaLevelInput = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 50.0,
        ambientTempCelsius: 18.0,
        criticalPowerWatts: 400.0,
        recoveryPowerWatts: 220.0,
      );
      const alto3050Input = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 3050.0,
        ambientTempCelsius: 14.0,
        solarRadiationFactor: 0.90,
        windSpeedMs: 4.5,
        criticalPowerWatts: 400.0,
        recoveryPowerWatts: 220.0,
      );
      const alto3265Input = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 3265.0,
        ambientTempCelsius: 12.0,
        solarRadiationFactor: 0.90,
        windSpeedMs: 4.5,
        criticalPowerWatts: 400.0,
        recoveryPowerWatts: 220.0,
      );

      final seaLevel = ExtremeAltitude3000mAndHeatwaveSolver.solve(seaLevelInput);
      final alto3050 = ExtremeAltitude3000mAndHeatwaveSolver.solve(alto3050Input);
      final alto3265 = ExtremeAltitude3000mAndHeatwaveSolver.solve(alto3265Input);

      expect(seaLevel.altitudeZone, ExtremeAltitudeZone.seaLevelOrLow);
      expect(seaLevel.isExtremeHypoxiaWPrimeZone, isFalse);
      expect(seaLevel.tauWPrimeMultiplier, closeTo(1.0, 1e-6));

      expect(alto3050.altitudeZone, ExtremeAltitudeZone.extremeHypoxiaAbove2800m);
      expect(alto3050.isExtremeHypoxiaWPrimeZone, isTrue);
      expect(alto3050.barometricPressureHpa, lessThan(720.0));
      expect(alto3050.arterialPao2MmHg, lessThan(60.0));
      expect(alto3050.arterialSpo2Percent, lessThan(90.0));
      expect(alto3050.airDensityKgM3, lessThan(0.95));

      expect(alto3050.tauWPrimeMultiplier, greaterThanOrEqualTo(1.45));
      expect(alto3050.tauWPrimePenaltyPercent, greaterThanOrEqualTo(45.0));
      expect(alto3050.attackRecoveryTimeRatio, greaterThan(1.7));
      expect(alto3050.effectiveCriticalPowerWatts, lessThan(400.0));
      expect(alto3050.aerobicCpMultiplier, lessThan(0.90));

      // Na szczycie 3265 m hipoksja jest jeszcze silniejsza niż na 3050 m
      expect(alto3265.arterialPao2MmHg, lessThan(alto3050.arterialPao2MmHg));
      expect(alto3265.tauWPrimeMultiplier, greaterThan(alto3050.tauWPrimeMultiplier));
      expect(alto3265.effectiveCriticalPowerWatts, lessThan(alto3050.effectiveCriticalPowerWatts));

      // Krzywa regeneracji W' na wysokości regeneruje się wolniej niż na poziomie morza
      expect(alto3265.recoveryCurve, isNotEmpty);
      final midPoint = alto3265.recoveryCurve.firstWhere((p) => p.elapsedSeconds >= 180.0);
      expect(midPoint.altitudeRatio, lessThan(midPoint.seaLevelRatio));
    });

    test('Góral z Andów (isAndeanNative) oraz kolarz po obozie (hasAltitudeAcclimatization) łagodzą spadek na 3265 m', () {
      const unacclimatizedInput = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 3265.0,
        ambientTempCelsius: 12.0,
        criticalPowerWatts: 400.0,
        hasAltitudeAcclimatization: false,
        isAndeanNative: false,
      );
      final campAcclimatizedInput = unacclimatizedInput.copyWith(
        hasAltitudeAcclimatization: true,
      );
      final andeanNativeInput = unacclimatizedInput.copyWith(
        isAndeanNative: true,
      );

      final unacclimatized = ExtremeAltitude3000mAndHeatwaveSolver.solve(unacclimatizedInput);
      final campAcclimatized = ExtremeAltitude3000mAndHeatwaveSolver.solve(campAcclimatizedInput);
      final andeanNative = ExtremeAltitude3000mAndHeatwaveSolver.solve(andeanNativeInput);

      expect(
        campAcclimatized.effectiveCriticalPowerWatts,
        greaterThan(unacclimatized.effectiveCriticalPowerWatts),
      );
      expect(
        andeanNative.effectiveCriticalPowerWatts,
        greaterThan(campAcclimatized.effectiveCriticalPowerWatts),
      );
      // Nawet z aklimatyzacją powyżej 2800 m obowiązuje bazowe wydłużenie tau W' (+45%)
      expect(andeanNative.tauWPrimeMultiplier, greaterThanOrEqualTo(1.45));
      expect(andeanNative.tauWPrimeMultiplier, lessThanOrEqualTo(unacclimatized.tauWPrimeMultiplier));

      // Sprawdzenie kompatybilności z AltitudeAcclimatizationAndHeatEngine
      final engineUnacclimatized = AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 3265.0,
        baseFtpWatts: 400.0,
        altitudeAcclimatizationScore: 0.0,
      );
      final engineColombian = AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 3265.0,
        baseFtpWatts: 400.0,
        nationalityIso: 'COL',
      );
      expect(engineColombian.isHighAltitudeNative, isTrue);
      expect(engineColombian.ftpLossPercent, closeTo(engineUnacclimatized.ftpLossPercent * 0.5, 1e-6));
    });
  });

  group('Fizjologia upałów 42°C na Tour Down Under', () {
    test('Upał 42°C na Willunga Hill nagrzewa asfalt >=58°C, podnosi Crr o >=8% i wymusza 2x nawadnianie', () {
      const temperateInput = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 160.0,
        ambientTempCelsius: 20.0,
        solarRadiationFactor: 0.55,
        windSpeedMs: 2.5,
        baseCrr: 0.0032,
        baseHydrationLitersPerHour: 0.85,
      );
      const tdu42cInput = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 160.0,
        ambientTempCelsius: 42.0,
        solarRadiationFactor: 1.0,
        windSpeedMs: 2.0,
        baseCrr: 0.0032,
        baseHydrationLitersPerHour: 0.85,
        hasHeatAcclimatization: false,
      );

      final temperate = ExtremeAltitude3000mAndHeatwaveSolver.solve(temperateInput);
      final tdu42c = ExtremeAltitude3000mAndHeatwaveSolver.solve(tdu42cInput);

      expect(temperate.heatwaveZone, HeatwaveSeverityZone.temperate);
      expect(temperate.requiresDoubleHydration, isFalse);
      expect(temperate.crrMultiplier, closeTo(1.0, 1e-6));

      expect(tdu42c.heatwaveZone, HeatwaveSeverityZone.australianExtremeHeat);
      expect(tdu42c.asphaltSurfaceTempCelsius, greaterThanOrEqualTo(58.0));
      expect(tdu42c.crrMultiplier, greaterThanOrEqualTo(1.08));
      expect(tdu42c.crrIncreasePercent, greaterThanOrEqualTo(8.0));
      expect(tdu42c.effectiveCrr, greaterThan(tdu42cInput.baseCrr * 1.079));

      expect(tdu42c.requiresDoubleHydration, isTrue);
      expect(tdu42c.hydrationMultiplier, greaterThanOrEqualTo(2.0));
      expect(
        tdu42c.requiredHydrationLitersPerHour,
        greaterThanOrEqualTo(tdu42cInput.baseHydrationLitersPerHour * 2.0),
      );
      expect(tdu42c.requiredBidonsPerHour, greaterThanOrEqualTo(3.4));
      expect(tdu42c.coreTempDriftCelsiusPerHour, greaterThan(temperate.coreTempDriftCelsiusPerHour));
    });

    test('Aklimatyzacja cieplna oraz Ice Socks redukują dryf temperatury głębokiej w 42°C', () {
      const unacclimatized42c = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 160.0,
        ambientTempCelsius: 42.0,
        solarRadiationFactor: 1.0,
        windSpeedMs: 2.0,
        hasHeatAcclimatization: false,
      );
      final acclimatized42c = unacclimatized42c.copyWith(hasHeatAcclimatization: true);

      final resUnaccl = ExtremeAltitude3000mAndHeatwaveSolver.solve(unacclimatized42c);
      final resAccl = ExtremeAltitude3000mAndHeatwaveSolver.solve(acclimatized42c);

      expect(resAccl.coreTempDriftCelsiusPerHour, lessThan(resUnaccl.coreTempDriftCelsiusPerHour));
      // Nawet po aklimatyzacji w 42°C nadal wymagane jest podwójne nawadnianie (>= 2.0x)
      expect(resAccl.requiresDoubleHydration, isTrue);

      // Symulacja kroku termicznego w AltitudeAcclimatizationAndHeatEngine przy 42°C na podjeździe
      const thermalState = RiderThermalState(
        coreBodyTemperatureCelsius: 38.6,
        heatAcclimatizationScore: 10.0,
        iceSocksAvailableInTeamCar: 3,
      );

      final hotStep = AltitudeAcclimatizationAndHeatEngine.simulateThermalStep(
        currentState: thermalState,
        deltaTimeSeconds: 300.0,
        ambientTemperatureCelsius: 42.0,
        airSpeedMetersPerSecond: 4.5,
        currentPowerWatts: 380.0,
        baseFtpWatts: 400.0,
        gradientPercent: 7.5,
      );

      expect(hotStep.deltaCoreTempCelsius, greaterThan(0.0));
      expect(hotStep.updatedState.coreBodyTemperatureCelsius, greaterThan(38.6));
      expect(hotStep.thermalFtpMultiplier, lessThan(1.0));
      expect(hotStep.shouldRecommendIceSocks, isTrue);

      final cooledState = AltitudeAcclimatizationAndHeatEngine.deployIceSocks(
        hotStep.updatedState,
      );
      expect(cooledState.isIceSockActive, isTrue);

      final cooledStep = AltitudeAcclimatizationAndHeatEngine.simulateThermalStep(
        currentState: cooledState,
        deltaTimeSeconds: 300.0,
        ambientTemperatureCelsius: 42.0,
        airSpeedMetersPerSecond: 4.5,
        currentPowerWatts: 380.0,
        baseFtpWatts: 400.0,
        gradientPercent: 7.5,
      );
      expect(
        cooledStep.netThermalRateCelsiusPerSecond,
        lessThan(hotStep.netThermalRateCelsiusPerSecond),
      );
    });

    test('Obsługa wartości brzegowych i scenariusza łączonego (wysokość + upał) bez błędów numerycznych', () {
      const extremeEdge = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: -100.0,
        ambientTempCelsius: 60.0,
        solarRadiationFactor: 1.5,
        windSpeedMs: -2.0,
        criticalPowerWatts: 50.0,
      );
      final edgeResult = ExtremeAltitude3000mAndHeatwaveSolver.solve(extremeEdge);
      expect(edgeResult.altitudeMeters, 0.0);
      expect(edgeResult.ambientTempCelsius, 52.0);
      expect(edgeResult.effectiveCriticalPowerWatts.isFinite, isTrue);
      expect(edgeResult.tauWPrimeMultiplier.isFinite, isTrue);

      const combinedPreset = ExtremeClimateScenarioPreset.combinedSanJuanDesertClimb;
      final combinedResult = ExtremeAltitude3000mAndHeatwaveSolver.solve(
        ExtremeAltitudeAndHeatwaveInput(
          altitudeMeters: combinedPreset.altitudeMeters,
          ambientTempCelsius: combinedPreset.ambientTempCelsius,
          solarRadiationFactor: combinedPreset.solarRadiationFactor,
          windSpeedMs: combinedPreset.windSpeedMs,
        ),
      );
      expect(combinedResult.isExtremeHypoxiaWPrimeZone, isTrue);
      expect(combinedResult.heatwaveZone, HeatwaveSeverityZone.heatwaveAlert);
      expect(combinedResult.tauWPrimeMultiplier, greaterThanOrEqualTo(1.45));
      expect(combinedResult.crrIncreasePercent, greaterThan(0.0));
    });
  });
}
