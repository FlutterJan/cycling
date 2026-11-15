// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/weather/dynamic_mountain_weather_engine.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/equipment_sponsorship_bidding_engine.dart';

void main() {
  group('DynamicMountainWeatherEngine - Fizyka atmosferyczna i mikroklimaty', () {
    test('Prawidłowo wylicza spadek temperatury ISA 0.65°C / 100m oraz marznący deszcz na przełęczy', () {
      // Dolina: 200m n.p.m., +24.0°C, słonecznie, wiatr 15 km/h
      final valleyWeather = DynamicMountainWeatherEngine.calculateLocalWeather(
        distanceKm: 10.0,
        altitudeMeters: 200.0,
        baseValleyAltM: 200.0,
        baseValleyTempC: 24.0,
        baseWindSpeedKmh: 15.0,
        baseWindDirectionDeg: 180.0,
        baseCondition: WeatherCondition.sunny,
      );

      expect(valleyWeather.altitudeMeters, equals(200.0));
      expect(valleyWeather.ambientTemperatureCelsius, closeTo(24.0, 0.1));
      expect(valleyWeather.weatherType, equals(MountainWeatherType.sunnyValley));
      expect(valleyWeather.weatherCondition, equals(WeatherCondition.sunny));
      expect(valleyWeather.roadSurface, equals(RoadSurfaceState.dry));
      expect(valleyWeather.isHighMountainPass, isFalse);

      // Przełęcz: 2400m n.p.m. (różnica 2200m)
      // Spadek ISA: 2200 * 0.0065 = 14.3°C -> 24.0 - 14.3 = 9.7°C
      // Ochłodzenie ewaporacyjne deszczem (-1.7°C) -> dokładnie 8.0°C!
      final passWeather = DynamicMountainWeatherEngine.calculateLocalWeather(
        distanceKm: 145.0,
        altitudeMeters: 2400.0,
        baseValleyAltM: 200.0,
        baseValleyTempC: 24.0,
        baseWindSpeedKmh: 15.0,
        baseWindDirectionDeg: 180.0,
        baseCondition: WeatherCondition.sunny,
        isSummit: true,
      );

      expect(passWeather.altitudeMeters, equals(2400.0));
      expect(passWeather.ambientTemperatureCelsius, closeTo(8.0, 0.1));
      // Zgodnie z wymaganiem: zrywa się porywisty wiatr i zaczyna padać marznący deszcz
      expect(passWeather.weatherType, equals(MountainWeatherType.freezingRain));
      expect(passWeather.weatherCondition, equals(WeatherCondition.heavyStorm));
      expect(passWeather.windSpeedKmh, greaterThan(35.0)); // Porywisty wiatr graniowy
      expect(passWeather.windGustKmh, greaterThan(50.0));
      expect(passWeather.precipitationIntensity, greaterThan(0.70));
      expect(passWeather.isHighMountainPass, isTrue);
      expect(passWeather.requiresRainJacketForDescent, isTrue);
    });

    test('Wiatr na przełęczy jest spotęgowany efektem Venturi w porównaniu z doliną', () {
      final valleyWeather = DynamicMountainWeatherEngine.calculateLocalWeather(
        distanceKm: 0.0,
        altitudeMeters: 300.0,
        baseValleyAltM: 300.0,
        baseValleyTempC: 22.0,
        baseWindSpeedKmh: 20.0,
        baseWindDirectionDeg: 90.0,
        baseCondition: WeatherCondition.sunny,
      );

      final summitWeather = DynamicMountainWeatherEngine.calculateLocalWeather(
        distanceKm: 85.0,
        altitudeMeters: 2200.0,
        baseValleyAltM: 300.0,
        baseValleyTempC: 22.0,
        baseWindSpeedKmh: 20.0,
        baseWindDirectionDeg: 90.0,
        baseCondition: WeatherCondition.sunny,
        isSummit: true,
      );

      expect(summitWeather.windSpeedKmh, greaterThan(valleyWeather.windSpeedKmh * 2.0));
      expect(summitWeather.windGustKmh, greaterThan(summitWeather.windSpeedKmh));
    });

    test('Oblicza poprawnie odczuwalną temperaturę wiatru (Wind Chill) na mokrym zjeździe', () {
      // 8.0°C przy prędkości 75 km/h z mokrym strojem
      final windChill = DynamicMountainWeatherEngine.calculateWindChill(
        ambientTempC: 8.0,
        effectiveAirspeedKmh: 75.0,
        wetnessLevel: 0.9,
      );

      // Wind chill powinien spaść w okolice poniżej zera lub blisko 0°C
      expect(windChill, lessThanOrEqualTo(1.0));
      expect(windChill, lessThan(8.0));
    });

    test('Gęstość powietrza spada wraz z wysokością n.p.m.', () {
      final seaLevelRho = DynamicMountainWeatherEngine.calculateAirDensityAtPoint(0.0, 15.0);
      final passRho = DynamicMountainWeatherEngine.calculateAirDensityAtPoint(2400.0, 8.0);

      expect(seaLevelRho, closeTo(1.225, 0.03));
      expect(passRho, lessThan(seaLevelRho));
      expect(passRho, closeTo(0.97, 0.06));
    });
  });

  group('DynamicMountainWeatherEngine - Profil etapu i ostrzeżenia meteo', () {
    late RaceStage alpineStage;

    setUp(() {
      // Tworzymy etap alpejski: Dolina 300m -> Podjazd na Col du Galibier 2642m -> Zjazd do doliny 700m
      alpineStage = const RaceStage(
        id: 'stage_alpine_test',
        stageNumber: 15,
        name: 'Bourg d\'Oisans - Col du Galibier - Valloire',
        stageType: StageType.highMountain,
        baseTemperatureCelsius: 23.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 14.0,
        segments: [
          // 1. Dolina (0 - 30 km, 300m -> 750m)
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 30.0,
            startElevationM: 300.0,
            endElevationM: 750.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 90.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          // 2. Podjazd HC na Col du Galibier (30 - 65 km, 750m -> 2642m)
          StageSegment(
            index: 1,
            startKm: 30.0,
            lengthKm: 35.0,
            startElevationM: 750.0,
            endElevationM: 2642.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 65.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 45.0,
            sprintOrKomClassification: SegmentClassification.horsCategorie,
          ),
          // 3. Długi zjazd z przełęczy (65 - 85 km, 2642m -> 1400m)
          StageSegment(
            index: 2,
            startKm: 65.0,
            lengthKm: 20.0,
            startElevationM: 2642.0,
            endElevationM: 1400.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 85.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 20.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          // 4. Dojazd doliną do mety (85 - 100 km, 1400m -> 1200m)
          StageSegment(
            index: 3,
            startKm: 85.0,
            lengthKm: 15.0,
            startElevationM: 1400.0,
            endElevationM: 1200.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 30.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.finishLine,
          ),
        ],
      );
    });

    test('Generuje kompletny profil pogodowy etapu z ostrzeżeniem o przełęczy', () {
      final profile = DynamicMountainWeatherEngine.generateStageWeatherProfile(
        stage: alpineStage,
      );

      expect(profile.stageId, equals('stage_alpine_test'));
      expect(profile.peakAltitudeM, equals(2642.0));
      expect(profile.waypoints.length, greaterThanOrEqualTo(8));
      expect(profile.meteorologicalAlerts.isNotEmpty, isTrue);

      // Ostrzeżenie o konieczności założenia kurtki na zjeździe z Galibier
      final galibierAlert = profile.meteorologicalAlerts.first;
      expect(galibierAlert, contains('Przełęcz'));
      expect(galibierAlert, contains('kurtki przeciwdeszczowe'));

      // Pogoda w dolinie vs na szczycie Galibier
      final valleyWeather = profile.getWeatherAtDistance(10.0);
      final summitWeather = profile.getWeatherAtDistance(65.0);

      expect(valleyWeather.ambientTemperatureCelsius, greaterThan(18.0));
      expect(summitWeather.ambientTemperatureCelsius, lessThan(10.0));
      expect(summitWeather.requiresRainJacketForDescent, isTrue);
    });

    test('getWeatherAtDistance płynnie interpoluje temperaturę i wysokość w trakcie wspinaczki', () {
      final profile = DynamicMountainWeatherEngine.generateStageWeatherProfile(
        stage: alpineStage,
      );

      final w30 = profile.getWeatherAtDistance(30.0); // Początek podjazdu
      final w47 = profile.getWeatherAtDistance(47.5); // Środek podjazdu
      final w65 = profile.getWeatherAtDistance(65.0); // Szczyt

      expect(w30.altitudeMeters, lessThan(w47.altitudeMeters));
      expect(w47.altitudeMeters, lessThan(w65.altitudeMeters));

      expect(w30.ambientTemperatureCelsius, greaterThan(w47.ambientTemperatureCelsius));
      expect(w47.ambientTemperatureCelsius, greaterThan(w65.ambientTemperatureCelsius));
    });
  });

  group('DynamicMountainWeatherEngine - Termoregulacja kolarza i hipotermia na zjeździe', () {
    late RiderPhysiology climberPhysiology;
    late RiderSkills climberSkills;

    setUp(() {
      climberPhysiology = const RiderPhysiology(
        heightCm: 176.0,
        weightKg: 61.5,
        bodyFatPercentage: 6.2, // Ultra szczupły góral Grand Tour (niska izolacja tłuszczowa!)
        ftpWatts: 410,
        wPrimeJoules: 19500,
        vo2Max: 84.5,
        maxHr: 196,
        restingHr: 39,
        lactateThresholdHr: 174,
        recoveryRate: 88.0,
        glycogenCapacityGrams: 480.0,
      );

      climberSkills = const RiderSkills(
        cobbles: 35,
        descending: 78,
        bikeHandling: 82,
        aeroPositioning: 85,
        draftingEfficiency: 80,
        raceIq: 84,
        rainResistance: 50, // Średnia tolerancja na deszcz
        heatTolerance: 88,
        timeTrialPositioning: 75,
      );
    });

    test('Kolarz BEZ KURTKI na długim zjeździe w chłodzie i deszczu wpada w hipotermię i traci moc', () {
      // Warunki na zjeździe z przełęczy: 7.5°C, marznący deszcz, wiatr 40 km/h
      const coldPassWeather = LocalWeatherSnapshot(
        distanceKm: 70.0,
        altitudeMeters: 2300.0,
        ambientTemperatureCelsius: 7.5,
        apparentTemperatureCelsius: 0.5,
        weatherType: MountainWeatherType.freezingRain,
        weatherCondition: WeatherCondition.heavyStorm,
        windSpeedKmh: 40.0,
        windGustKmh: 58.0,
        windDirectionDegrees: 180.0,
        precipitationIntensity: 0.85,
        relativeHumidityPercent: 96.0,
        airDensityKgM3: 0.98,
        roadSurface: RoadSurfaceState.wet,
        isHighMountainPass: true,
      );

      // Kolarz zjeżdża w samym letnim stroju bez kurtki
      var thermal = RiderThermalSnapshot.initial(
        riderId: 'climber_1',
        riderName: 'Tadej P.',
        startingClothing: RiderClothingType.summerAeroJersey,
      );

      // Symulujemy 12 minut zjazdu z prędkością 72 km/h i minimalną mocą (45 W)
      for (int sec = 0; sec < 720; sec += 30) {
        thermal = DynamicMountainWeatherEngine.updateRiderThermalState(
          currentThermal: thermal,
          physiology: climberPhysiology,
          skills: climberSkills,
          weather: coldPassWeather,
          riderSpeedKmh: 72.0,
          powerOutputWatts: 45.0, // Brak produkcji metabolicznej ciepła na zjeździe
          timeStepSeconds: 30.0,
        );
      }

      // Wychłodzenie organizmu i rozwój hipotermii
      expect(thermal.wetnessLevel, greaterThan(0.60)); // Przemoczony strój
      expect(thermal.coreTemperatureCelsius, lessThan(36.0)); // Hipotermia
      expect(thermal.hypothermiaStage != HypothermiaStage.none, isTrue);
      expect(thermal.totalPowerPenaltyPercent, greaterThan(7.0)); // Spadek mocy
      expect(thermal.descendingPenaltyPercent, greaterThan(10.0)); // Kara do zjazdów (zdrętwiałe dłonie)
      expect(thermal.shiveringIntensity, greaterThan(0.20)); // Drgawki
      expect(thermal.shiveringGlycogenMultiplier, greaterThan(1.10)); // Szybsze zużycie glikogenu
    });

    test('Kolarz W KURTCE PRZECIWDESZCZOWEJ na tym samym zjeździe zachowuje komfort i pełną moc', () {
      const coldPassWeather = LocalWeatherSnapshot(
        distanceKm: 70.0,
        altitudeMeters: 2300.0,
        ambientTemperatureCelsius: 7.5,
        apparentTemperatureCelsius: 0.5,
        weatherType: MountainWeatherType.freezingRain,
        weatherCondition: WeatherCondition.heavyStorm,
        windSpeedKmh: 40.0,
        windGustKmh: 58.0,
        windDirectionDegrees: 180.0,
        precipitationIntensity: 0.85,
        relativeHumidityPercent: 96.0,
        airDensityKgM3: 0.98,
        roadSurface: RoadSurfaceState.wet,
        isHighMountainPass: true,
      );

      // Kolarz założył kurtkę przeciwdeszczową przed zjazdem
      var thermal = RiderThermalSnapshot.initial(
        riderId: 'climber_1',
        riderName: 'Tadej P.',
        startingClothing: RiderClothingType.rainJacket,
      );

      // Symulujemy te same 12 minut zjazdu z prędkością 72 km/h
      for (int sec = 0; sec < 720; sec += 30) {
        thermal = DynamicMountainWeatherEngine.updateRiderThermalState(
          currentThermal: thermal,
          physiology: climberPhysiology,
          skills: climberSkills,
          weather: coldPassWeather,
          riderSpeedKmh: 72.0,
          powerOutputWatts: 45.0,
          timeStepSeconds: 30.0,
        );
      }

      // Dzięki membranie hydrofobowej i blokadzie wiatru kolarz unika hipotermii!
      expect(thermal.hypothermiaStage, equals(HypothermiaStage.none));
      expect(thermal.totalPowerPenaltyPercent, equals(0.0)); // Brak straty mocy!
      expect(thermal.descendingPenaltyPercent, equals(0.0));
      expect(thermal.coreTemperatureCelsius, greaterThanOrEqualTo(36.5));
      expect(thermal.effectiveCdaPenalty, greaterThan(0.015)); // Trzepotanie kurtki daje lekką karę aero
    });

    test('Odzież sponsorska z wysokim badWeatherThermalProtectionScore daje lepszą ochronę', () {
      const highTechApparel = ApparelTechnicalPerks(
        ttSkinsuitWattSavings: 20.0,
        roadAeroJerseyWattSavings: 6.5,
        badWeatherThermalProtectionScore: 95, // Topowa membrana hydrofobowa
        antiChafingComfortScore: 92,
        customWindTunnelFittingsCount: 4,
      );

      var initialThermal = RiderThermalSnapshot.initial(
        riderId: 'climber_1',
        riderName: 'Jonas V.',
        startingClothing: RiderClothingType.rainJacket,
      );

      final jacketState = DynamicMountainWeatherEngine.orderPutOnJacket(
        current: initialThermal,
        newClothing: RiderClothingType.rainJacket,
        teamApparel: highTechApparel,
      );

      // Dopasowany aerodynamiczny krój z tunelem zmniejsza narzut CdA
      expect(jacketState.effectiveCdaPenalty, lessThan(RiderClothingType.rainJacket.baseCdaPenalty));
      expect(jacketState.isJacketWorn, isTrue);
    });

    test('Kolarz podjeżdżający w upale w zapiętej kurtce ulega hipertermii (przegrzaniu)', () {
      // Gorąca dolina: 27.0°C, pełne słońce
      const warmValleyWeather = LocalWeatherSnapshot(
        distanceKm: 120.0,
        altitudeMeters: 250.0,
        ambientTemperatureCelsius: 27.0,
        apparentTemperatureCelsius: 27.0,
        weatherType: MountainWeatherType.heatWave,
        weatherCondition: WeatherCondition.extremeHeat,
        windSpeedKmh: 8.0,
        windGustKmh: 12.0,
        windDirectionDegrees: 180.0,
        precipitationIntensity: 0.0,
        relativeHumidityPercent: 55.0,
        airDensityKgM3: 1.18,
        roadSurface: RoadSurfaceState.dry,
        isHighMountainPass: false,
      );

      // Kolarz zapomniał zdjąć kurtkę przeciwdeszczową i jedzie podjazd z mocą 380 W
      var thermal = RiderThermalSnapshot.initial(
        riderId: 'climber_1',
        riderName: 'Remco E.',
        startingClothing: RiderClothingType.rainJacket,
      );

      for (int sec = 0; sec < 900; sec += 30) {
        thermal = DynamicMountainWeatherEngine.updateRiderThermalState(
          currentThermal: thermal,
          physiology: climberPhysiology,
          skills: climberSkills,
          weather: warmValleyWeather,
          riderSpeedKmh: 19.0, // Wolny podjazd pod górę
          powerOutputWatts: 380.0, // Ogromna produkcja ciepła metabolicznego
          timeStepSeconds: 30.0,
        );
      }

      // Kolarz "gotuje się" w kurtce pod górę!
      expect(thermal.coreTemperatureCelsius, greaterThan(37.8));
      expect(thermal.hyperthermiaStage != HyperthermiaStage.none, isTrue);
      expect(thermal.totalPowerPenaltyPercent, greaterThan(0.0));
      expect(thermal.statusDescription, contains('PRZEGRZANIE'));

      // Zdjęcie kurtki pozwala na powrót do chłodzenia
      final withoutJacket = DynamicMountainWeatherEngine.orderTakeOffJacket(current: thermal);
      expect(withoutJacket.isJacketWorn, isFalse);
      expect(withoutJacket.clothingType, equals(RiderClothingType.summerAeroJersey));
      expect(withoutJacket.effectiveCdaPenalty, equals(0.0));
    });

    test('Rekomendacja taktyczna sugeruje założenie kurtki przed zjazdem z zimnej przełęczy', () {
      const coldPassWeather = LocalWeatherSnapshot(
        distanceKm: 65.0,
        altitudeMeters: 2400.0,
        ambientTemperatureCelsius: 7.0,
        apparentTemperatureCelsius: 2.0,
        weatherType: MountainWeatherType.freezingRain,
        weatherCondition: WeatherCondition.heavyStorm,
        windSpeedKmh: 35.0,
        windGustKmh: 50.0,
        windDirectionDegrees: 180.0,
        precipitationIntensity: 0.8,
        relativeHumidityPercent: 95.0,
        airDensityKgM3: 0.98,
        roadSurface: RoadSurfaceState.wet,
        isHighMountainPass: true,
      );

      const summitSegment = StageSegment(
        index: 5,
        startKm: 55.0,
        lengthKm: 10.0,
        startElevationM: 1800.0,
        endElevationM: 2400.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 60.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      );

      const nextDescentSegment = StageSegment(
        index: 6,
        startKm: 65.0,
        lengthKm: 18.0,
        startElevationM: 2400.0,
        endElevationM: 900.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 80.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      );

      final thermal = RiderThermalSnapshot.initial(
        riderId: 'climber_1',
        riderName: 'Primoz R.',
        startingClothing: RiderClothingType.summerAeroJersey,
      );

      final recommendation = DynamicMountainWeatherEngine.evaluateTacticalClothingDecision(
        currentThermal: thermal,
        currentWeather: coldPassWeather,
        currentSegment: summitSegment,
        nextSegment: nextDescentSegment,
      );

      expect(recommendation.recommendedAction, equals(TacticalClothingAction.putOnJacket));
      expect(recommendation.recommendedClothing, equals(RiderClothingType.rainJacket));
      expect(recommendation.priority, greaterThan(0.95));
      expect(recommendation.reasonPl, contains('hipotermią'));
    });
  });

  group('DynamicMountainWeatherEngine - Serializacja JSON', () {
    test('LocalWeatherSnapshot poprawnie serializuje się i deserializuje z JSON', () {
      const snap = LocalWeatherSnapshot(
        distanceKm: 85.5,
        altitudeMeters: 2150.0,
        ambientTemperatureCelsius: 8.5,
        apparentTemperatureCelsius: 1.2,
        weatherType: MountainWeatherType.freezingRain,
        weatherCondition: WeatherCondition.heavyStorm,
        windSpeedKmh: 42.0,
        windGustKmh: 61.5,
        windDirectionDegrees: 210.0,
        precipitationIntensity: 0.88,
        relativeHumidityPercent: 97.0,
        airDensityKgM3: 0.995,
        roadSurface: RoadSurfaceState.freezingGlaze,
        isHighMountainPass: true,
        warningNote: 'Marznący deszcz na grani!',
      );

      final json = snap.toJson();
      final reconstituted = LocalWeatherSnapshot.fromJson(json);

      expect(reconstituted.distanceKm, equals(snap.distanceKm));
      expect(reconstituted.altitudeMeters, equals(snap.altitudeMeters));
      expect(reconstituted.ambientTemperatureCelsius, equals(snap.ambientTemperatureCelsius));
      expect(reconstituted.weatherType, equals(MountainWeatherType.freezingRain));
      expect(reconstituted.roadSurface, equals(RoadSurfaceState.freezingGlaze));
      expect(reconstituted.warningNote, equals('Marznący deszcz na grani!'));
    });

    test('RiderThermalSnapshot poprawnie serializuje się i deserializuje z JSON', () {
      const thermal = RiderThermalSnapshot(
        riderId: 'rider_99',
        riderName: 'Michał K.',
        clothingType: RiderClothingType.rainJacket,
        isJacketWorn: true,
        coreTemperatureCelsius: 36.85,
        skinTemperatureCelsius: 31.4,
        wetnessLevel: 0.25,
        hypothermiaStage: HypothermiaStage.none,
        hyperthermiaStage: HyperthermiaStage.none,
        totalPowerPenaltyPercent: 0.0,
        descendingPenaltyPercent: 0.0,
        effectiveCdaPenalty: 0.022,
        shiveringIntensity: 0.0,
        shiveringGlycogenMultiplier: 1.0,
        statusDescription: 'Stabilny bilans termiczny.',
      );

      final json = thermal.toJson();
      final reconstituted = RiderThermalSnapshot.fromJson(json);

      expect(reconstituted.riderId, equals('rider_99'));
      expect(reconstituted.isJacketWorn, isTrue);
      expect(reconstituted.clothingType, equals(RiderClothingType.rainJacket));
      expect(reconstituted.coreTemperatureCelsius, equals(36.85));
      expect(reconstituted.effectiveCdaPenalty, equals(0.022));
    });

    test('StageWeatherProfile poprawnie serializuje się i deserializuje z JSON', () {
      const snap1 = LocalWeatherSnapshot(
        distanceKm: 0.0,
        altitudeMeters: 200.0,
        ambientTemperatureCelsius: 24.0,
        apparentTemperatureCelsius: 24.0,
        weatherType: MountainWeatherType.sunnyValley,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 12.0,
        windGustKmh: 18.0,
        windDirectionDegrees: 180.0,
        precipitationIntensity: 0.0,
        relativeHumidityPercent: 48.0,
        airDensityKgM3: 1.21,
        roadSurface: RoadSurfaceState.dry,
        isHighMountainPass: false,
      );

      const profile = StageWeatherProfile(
        stageId: 'st_1',
        stageName: 'Alpe d\'Huez Stage',
        baseValleyAltitudeM: 200.0,
        baseValleyTemperatureC: 24.0,
        peakAltitudeM: 1860.0,
        minAltitudeM: 200.0,
        waypoints: [snap1],
        meteorologicalAlerts: ['Uwaga na deszcz na szczycie!'],
      );

      final json = profile.toJson();
      final reconstituted = StageWeatherProfile.fromJson(json);

      expect(reconstituted.stageId, equals('st_1'));
      expect(reconstituted.waypoints.length, equals(1));
      expect(reconstituted.meteorologicalAlerts.first, equals('Uwaga na deszcz na szczycie!'));
    });
  });
}

