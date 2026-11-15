// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/feeding_and_rain_jacket_mechanics.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/physics/nutrition_and_glycogen_engine.dart';
import 'package:pro_peloton_manager/engine/weather/dynamic_mountain_weather_engine.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';

void main() {
  group('FeedingAndRainJacketMechanics - Strefy Bufetu (Feed Zones) i Torby Musette', () {
    test('generateFeedZonesForStage poprawnie tworzy strefy bufetu na etapie szosowym', () {
      const stage = RaceStage(
        id: 'st_alps_180',
        stageNumber: 12,
        name: 'Briançon - Alpe d\'Huez',
        stageType: StageType.highMountain,
        baseTemperatureCelsius: 22.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 12.0,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 180.0,
            startElevationM: 1200.0,
            endElevationM: 1860.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 50.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 90.0,
            sprintOrKomClassification: SegmentClassification.horsCategorie,
          ),
        ],
      );

      final zones = FeedingAndRainJacketMechanics.generateFeedZonesForStage(stage);

      expect(zones.isNotEmpty, isTrue);
      // Główny bufet w połowie trasy (~90 km)
      final midZone = zones.first;
      expect(midZone.startKm, closeTo(90.0, 10.0));
      expect(midZone.lengthKm, greaterThanOrEqualTo(1.5));
      expect(midZone.isMusetteStation, isTrue);

      // Sprawdzenie wykrywania obecności kolarza w strefie
      final inZone = FeedingAndRainJacketMechanics.getActiveFeedZoneAtDistance(midZone.startKm + 0.5, zones);
      final outsideZone = FeedingAndRainJacketMechanics.getActiveFeedZoneAtDistance(10.0, zones);

      expect(inZone, isNotNull);
      expect(outsideZone, isNull);
    });

    test('attemptGrabMusette odnawia zapas bidonów, żeli i dostarcza awaryjną pelerynkę', () {
      const skills = RiderSkills(
        cobbles: 50,
        descending: 70,
        bikeHandling: 85, // Dobra technika chwytu torby
        aeroPositioning: 75,
        draftingEfficiency: 80,
        raceIq: 80,
        rainResistance: 50,
        heatTolerance: 75,
        timeTrialPositioning: 70,
      );

      const musette = MusetteBagContent(
        bidonsCount: 2,
        energyGelsCount: 3,
        energyBarsCount: 1,
        containsEmergencyRainGilet: true,
      );

      final result = FeedingAndRainJacketMechanics.attemptGrabMusette(
        skills: skills,
        currentSpeedKmh: 35.0, // Bezpieczna prędkość w strefie
        bagContent: musette,
      );

      expect(result.success, isTrue);
      expect(result.isDropped, isFalse);
      expect(result.bidonsAdded, equals(2));
      expect(result.gelsAdded, equals(3));
      expect(result.emergencyGiletReceived, isTrue);
      expect(result.radioMessagePl, contains('Musette przejęte pewnie'));
    });
  });

  group('FeedingAndRainJacketMechanics - Cykl Ubierania i Zdejmowania Kurtki', () {
    test('Kolarz przechodzi pełny cykl zakładania kurtki (reachingPocket -> zippingUp -> isWearingJacket)', () {
      var state = const JacketDeploymentState(
        riderId: 'rider_1',
        currentClothing: RiderClothingType.summerAeroJersey,
        hasJacketInPocket: true,
      );

      expect(state.isWearingJacket, isFalse);

      // 1. Rozpoczęcie ubierania kurtki
      state = FeedingAndRainJacketMechanics.startPuttingOnJacket(
        currentState: state,
        targetClothing: RiderClothingType.rainJacket,
      );
      expect(state.phase, equals(JacketOperationPhase.reachingPocket));
      expect(state.isWearingJacket, isFalse);

      // 2. Po 3 sekundach: przekłada ręce przez rękawy
      state = FeedingAndRainJacketMechanics.updateJacketOperation(state: state, dtSeconds: 3.0);
      expect(state.phase, equals(JacketOperationPhase.puttingOnSleeves));

      // 3. Po kolejnych 3 sekundach: zasuwa zamek (zippingUp)
      state = FeedingAndRainJacketMechanics.updateJacketOperation(state: state, dtSeconds: 3.0);
      expect(state.phase, equals(JacketOperationPhase.zippingUp));

      // 4. Po przekroczeniu 7 sekund: kurtka w pełni założona i zapięta
      state = FeedingAndRainJacketMechanics.updateJacketOperation(state: state, dtSeconds: 2.0);
      expect(state.phase, equals(JacketOperationPhase.none));
      expect(state.isZipped, isTrue);
      expect(state.isWearingJacket, isTrue);
      expect(state.currentClothing, equals(RiderClothingType.rainJacket));

      // 5. Zdjęcie kurtki po zjeździe
      state = FeedingAndRainJacketMechanics.startTakingOffJacket(currentState: state);
      expect(state.phase, equals(JacketOperationPhase.takingOff));

      state = FeedingAndRainJacketMechanics.updateJacketOperation(state: state, dtSeconds: 5.0);
      expect(state.phase, equals(JacketOperationPhase.none));
      expect(state.isWearingJacket, isFalse);
      expect(state.currentClothing, equals(RiderClothingType.summerAeroJersey));
    });
  });

  group('FeedingAndRainJacketMechanics - Wychłodzenie na Przełęczy 2200m n.p.m. i Utrata 15% Energii', () {
    late RiderPhysiology testPhysiology;

    setUp(() {
      testPhysiology = const RiderPhysiology(
        heightCm: 178.0,
        weightKg: 63.0,
        bodyFatPercentage: 6.5,
        ftpWatts: 420,
        wPrimeJoules: 20000,
        vo2Max: 85.0,
        maxHr: 195,
        restingHr: 40,
        lactateThresholdHr: 175,
        recoveryRate: 90.0,
        glycogenCapacityGrams: 500.0,
      );
    });

    test('Kolarz z NISKIM rainResistance BEZ KURTKI na zjeździe z 2200m w ulewie traci czucie, jedzie wolniej w zakrętach i traci 15% energii na drżenie', () {
      const lowRainResistSkills = RiderSkills(
        cobbles: 40,
        descending: 75,
        bikeHandling: 70,
        aeroPositioning: 80,
        draftingEfficiency: 75,
        raceIq: 70,
        rainResistance: 25, // Bardzo niski rainResistance!
        heatTolerance: 85,
        timeTrialPositioning: 75,
      );

      final impact = FeedingAndRainJacketMechanics.calculateDescentColdImpact(
        riderId: 'rider_cold',
        isWearingJacket: false, // BEZ KURTKI!
        altitudeMeters: 2200.0, // Przełęcz 2200m n.p.m.
        isHeavyRainOrStorm: true, // W ulewie
        skills: lowRainResistSkills,
        physiology: testPhysiology,
      );

      // Weryfikacja dokładnych wymagań z promptu:
      // 1. Utrata czucia w dłoniach (zdrętwiałe palce na klamkach hamulców)
      expect(impact.handNumbnessLevel, greaterThan(0.70));

      // 2. Jedzie wolniej w zakrętach (kara prędkości w zakrętach > 20%)
      expect(impact.corneringSpeedPenaltyPercent, greaterThan(20.0));

      // 3. Traci dodatkowe 15% zapasu energii na drżenie mięśniowe!
      expect(impact.shiveringEnergyLossPercent, closeTo(15.0, 3.0));
      expect(impact.extraGlycogenBurnGrams, greaterThanOrEqualTo(65.0)); // ~15% z 500g

      // 4. Wyższe ryzyko kraksy
      expect(impact.crashRiskMultiplier, greaterThan(2.5));
      expect(impact.diagnosticMessagePl, contains('BRAK KURTKI'));
      expect(impact.diagnosticMessagePl, contains('drżenie mięśniowe'));
    });

    test('Ten sam kolarz W ZAŁOŻONEJ KURTCE zachowuje czucie, nie zwalnia w zakrętach i nie traci energii', () {
      const lowRainResistSkills = RiderSkills(
        cobbles: 40,
        descending: 75,
        bikeHandling: 70,
        aeroPositioning: 80,
        draftingEfficiency: 75,
        raceIq: 70,
        rainResistance: 25,
        heatTolerance: 85,
        timeTrialPositioning: 75,
      );

      final impact = FeedingAndRainJacketMechanics.calculateDescentColdImpact(
        riderId: 'rider_protected',
        isWearingJacket: true, // ZAŁOŻYŁ KURTKĘ PRZED ZJAZDEM!
        altitudeMeters: 2200.0,
        isHeavyRainOrStorm: true,
        skills: lowRainResistSkills,
        physiology: testPhysiology,
      );

      // Pełna ochrona termiczna i membranowa
      expect(impact.handNumbnessLevel, equals(0.0));
      expect(impact.corneringSpeedPenaltyPercent, equals(0.0));
      expect(impact.shiveringEnergyLossPercent, equals(0.0));
      expect(impact.extraGlycogenBurnGrams, equals(0.0));
      expect(impact.crashRiskMultiplier, equals(1.0));
      expect(impact.diagnosticMessagePl, contains('zabezpieczony kurtką'));
    });

    test('Kolarz z WYSOKIM rainResistance radzi sobie lepiej niż kolarz z niskim rainResistance', () {
      const toughFlemishSkills = RiderSkills(
        cobbles: 85,
        descending: 80,
        bikeHandling: 85,
        aeroPositioning: 80,
        draftingEfficiency: 85,
        raceIq: 85,
        rainResistance: 92, // Kolarz zahartowany na deszcz i chłód
        heatTolerance: 65,
        timeTrialPositioning: 75,
      );

      const fragileClimberSkills = RiderSkills(
        cobbles: 30,
        descending: 70,
        bikeHandling: 70,
        aeroPositioning: 80,
        draftingEfficiency: 75,
        raceIq: 75,
        rainResistance: 20, // Nie znosi zimnego deszczu
        heatTolerance: 90,
        timeTrialPositioning: 70,
      );

      final toughImpact = FeedingAndRainJacketMechanics.calculateDescentColdImpact(
        riderId: 'tough_guy',
        isWearingJacket: false,
        altitudeMeters: 2200.0,
        isHeavyRainOrStorm: true,
        skills: toughFlemishSkills,
        physiology: testPhysiology,
      );

      final fragileImpact = FeedingAndRainJacketMechanics.calculateDescentColdImpact(
        riderId: 'fragile_guy',
        isWearingJacket: false,
        altitudeMeters: 2200.0,
        isHeavyRainOrStorm: true,
        skills: fragileClimberSkills,
        physiology: testPhysiology,
      );

      // Kolarz zahartowany ma mniejszy spadek czucia i mniejszą karę w zakrętach
      expect(toughImpact.handNumbnessLevel, lessThan(fragileImpact.handNumbnessLevel));
      expect(toughImpact.corneringSpeedPenaltyPercent, lessThan(fragileImpact.corneringSpeedPenaltyPercent));
    });
  });

  group('FeedingAndRainJacketMechanics - Krok Symulacyjny (processStep)', () {
    test('processStep uzupełnia bidony i żele kolarza podczas przejazdu przez strefę bufetu', () {
      final feedZones = [
        const FeedZoneLocation(
          id: 'fz_1',
          zoneName: 'Strefa Bufetu 80km',
          startKm: 80.0,
          endKm: 82.5,
          elevationMeters: 400.0,
        ),
      ];

      var riderState = RiderRaceState.initial(
        riderId: 'r_test',
        teamId: 't_test',
        initialWPrimeJoules: 20000,
        initialGlycogenGrams: 400,
      ).copyWith(
        distanceCoveredMeters: 80500.0, // 80.5 km (w strefie!)
        bidonsLeft: 0, // Puste koszyki
        gelsLeft: 1,
      );

      var nutritionState = const NutritionState(
        currentGlycogenGrams: 400.0,
        maxGlycogenGrams: 500.0,
      );

      var jacketState = const JacketDeploymentState(
        riderId: 'r_test',
        currentClothing: RiderClothingType.summerAeroJersey,
      );

      const segment = StageSegment(
        index: 2,
        startKm: 75.0,
        lengthKm: 15.0,
        startElevationM: 350.0,
        endElevationM: 450.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      );

      const weather = LocalWeatherSnapshot(
        distanceKm: 80.5,
        altitudeMeters: 400.0,
        ambientTemperatureCelsius: 22.0,
        apparentTemperatureCelsius: 22.0,
        weatherType: MountainWeatherType.sunnyValley,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 12.0,
        windGustKmh: 18.0,
        windDirectionDegrees: 180.0,
        precipitationIntensity: 0.0,
        relativeHumidityPercent: 50.0,
        airDensityKgM3: 1.21,
        roadSurface: RoadSurfaceState.dry,
        isHighMountainPass: false,
      );

      const skills = RiderSkills(
        cobbles: 50,
        descending: 70,
        bikeHandling: 80,
        aeroPositioning: 70,
        draftingEfficiency: 70,
        raceIq: 70,
        rainResistance: 50,
        heatTolerance: 70,
        timeTrialPositioning: 70,
      );

      const physiology = RiderPhysiology(
        heightCm: 180.0,
        weightKg: 68.0,
        bodyFatPercentage: 8.0,
        ftpWatts: 400,
        wPrimeJoules: 20000,
        vo2Max: 80.0,
        maxHr: 195,
        restingHr: 45,
        lactateThresholdHr: 172,
        recoveryRate: 85.0,
        glycogenCapacityGrams: 500.0,
      );

      final stepResult = FeedingAndRainJacketMechanics.processStep(
        riderState: riderState,
        nutritionState: nutritionState,
        jacketState: jacketState,
        skills: skills,
        physiology: physiology,
        currentSegment: segment,
        currentWeather: weather,
        feedZones: feedZones,
        dtSeconds: 5.0,
      );

      // Kolarz pobrał musette i ma pełne bidony oraz dodatkowe żele!
      expect(stepResult.updatedRiderState.bidonsLeft, equals(2));
      expect(stepResult.updatedRiderState.gelsLeft, greaterThan(1));
      expect(stepResult.radioMessage, contains('Musette'));
    });
  });

  group('FeedingAndRainJacketMechanics - Serializacja JSON', () {
    test('Wszystkie modele mechaniki bufetu i ubioru serializują się bezstratnie', () {
      const feedZone = FeedZoneLocation(
        id: 'fz_alps',
        zoneName: 'Strefa Bufetu Galibier',
        startKm: 105.0,
        endKm: 107.5,
        elevationMeters: 1450.0,
        isMusetteStation: true,
        isVehicleFeedingAllowed: true,
        isClosedForFinalKms: false,
      );

      final zoneJson = feedZone.toJson();
      final zoneReconst = FeedZoneLocation.fromJson(zoneJson);
      expect(zoneReconst.id, equals(feedZone.id));
      expect(zoneReconst.startKm, equals(105.0));
      expect(zoneReconst.elevationMeters, equals(1450.0));

      const bag = MusetteBagContent(
        bidonsCount: 2,
        energyGelsCount: 4,
        energyBarsCount: 2,
        containsEmergencyRainGilet: true,
        totalCarbsGrams: 110.0,
      );

      final bagJson = bag.toJson();
      final bagReconst = MusetteBagContent.fromJson(bagJson);
      expect(bagReconst.bidonsCount, equals(2));
      expect(bagReconst.containsEmergencyRainGilet, isTrue);

      const jacketState = JacketDeploymentState(
        riderId: 'r_10',
        currentClothing: RiderClothingType.rainJacket,
        phase: JacketOperationPhase.zippingUp,
        phaseProgressSeconds: 5.5,
        hasJacketInPocket: false,
        isZipped: false,
      );

      final jacketJson = jacketState.toJson();
      final jacketReconst = JacketDeploymentState.fromJson(jacketJson);
      expect(jacketReconst.riderId, equals('r_10'));
      expect(jacketReconst.phase, equals(JacketOperationPhase.zippingUp));
      expect(jacketReconst.phaseProgressSeconds, equals(5.5));

      const exposure = DescentColdExposureResult(
        riderId: 'r_cold',
        isWearingJacket: false,
        altitudeMeters: 2200.0,
        isHeavyRainOrStorm: true,
        rainResistanceSkill: 35,
        handNumbnessLevel: 0.82,
        corneringSpeedPenaltyPercent: 24.5,
        shiveringEnergyLossPercent: 15.2,
        extraGlycogenBurnGrams: 76.0,
        crashRiskMultiplier: 3.2,
        diagnosticMessagePl: 'Zdrętwiałe dłonie!',
      );

      final exposureJson = exposure.toJson();
      final exposureReconst = DescentColdExposureResult.fromJson(exposureJson);
      expect(exposureReconst.riderId, equals('r_cold'));
      expect(exposureReconst.shiveringEnergyLossPercent, equals(15.2));
      expect(exposureReconst.handNumbnessLevel, equals(0.82));
    });
  });
}

