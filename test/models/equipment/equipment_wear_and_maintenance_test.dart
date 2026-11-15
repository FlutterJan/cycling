// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/equipment_wear_and_maintenance.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/groupset_model.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';

void main() {
  group('EquipmentWearAndMaintenance - Łańcuch i Woskowanie (Hot Melt Wax vs Deszcz)', () {
    test('Świeży wosk na gorąco (Hot Melt Wax) zapewnia najniższe straty tarcia w peletonie', () {
      final freshStandard = ChainAndWaxCondition.brandNewHotMeltWax(allWeatherFormula: false);
      final freshAllWeather = ChainAndWaxCondition.brandNewHotMeltWax(allWeatherFormula: true);
      const wetLube = ChainAndWaxCondition(
        lubricantType: DrivetrainLubricantType.syntheticWetLube,
        waxFilmRemainingPercent: 100.0,
        chainElongationPercent: 0.05,
        totalChainMileageKm: 0.0,
        mileageSinceLastWaxKm: 0.0,
        isWashedOut: false,
      );

      // Wosk na gorąco ma straty poniżej 4W
      expect(freshStandard.effectiveFrictionLossWatts, closeTo(3.7, 0.3));
      expect(freshAllWeather.effectiveFrictionLossWatts, closeTo(4.1, 0.3));

      // Tradycyjny olej ma straty wyraźnie wyższe (>7W)
      expect(wetLube.effectiveFrictionLossWatts, greaterThan(7.0));
      expect(wetLube.effectiveFrictionLossWatts, greaterThan(freshStandard.effectiveFrictionLossWatts + 3.0));
    });

    test('Na suchym etapie 160 km wosk nie ulega wypłukaniu i degraduje się powoli', () {
      final wear = EquipmentWearAndMaintenance.brandNew(allWeatherWax: false);

      final result = wear.simulateStageWear(
        stageDistanceKm: 160.0,
        elevationGainMeters: 1200.0,
        descentElevationMeters: 1200.0,
        isRaining: false,
        roadWetness: 0.0,
      );

      expect(result.didWaxWashoutOccur, isFalse);
      expect(result.updatedChain.isWashedOut, isFalse);
      expect(result.updatedChain.waxFilmRemainingPercent, greaterThan(70.0));
      expect(result.drivetrainLossWattsDelta, lessThan(1.5));
    });

    test('Na deszczowym etapie powyżej 150 km standardowy wosk ulega wypłukaniu, a straty mocy rosną', () {
      final wear = EquipmentWearAndMaintenance.brandNew(allWeatherWax: false);

      // Etap 180 km w ulewnym deszczu
      final result = wear.simulateStageWear(
        stageDistanceKm: 180.0,
        elevationGainMeters: 1800.0,
        descentElevationMeters: 1800.0,
        isRaining: true,
        roadWetness: 0.85,
      );

      // Standardowy wosk nie wytrzymuje 180 km deszczu (limit ~140 km)
      expect(result.didWaxWashoutOccur, isTrue);
      expect(result.updatedChain.isWashedOut, isTrue);
      expect(result.updatedChain.waxFilmRemainingPercent, equals(0.0));
      expect(result.washoutDistanceKm, closeTo(140.0, 10.0));

      // Straty tarcia napędu drastycznie skaczą
      expect(result.updatedChain.effectiveFrictionLossWatts, greaterThan(11.0));
      expect(result.drivetrainLossWattsDelta, greaterThan(7.0));

      // Pojawia się nota serwisowa
      expect(
        result.mechanicNotes.any((n) => n.contains('wypłukaniu') && n.contains('All-Weather')),
        isTrue,
      );
    });

    test('Formuła All-Weather na tym samym 180 km etapie w deszczu NIE ulega wypłukaniu', () {
      final wearAllWeather = EquipmentWearAndMaintenance.brandNew(allWeatherWax: true);

      final result = wearAllWeather.simulateStageWear(
        stageDistanceKm: 180.0,
        elevationGainMeters: 1800.0,
        descentElevationMeters: 1800.0,
        isRaining: true,
        roadWetness: 0.85,
      );

      // Mieszanka hydrofobowa wytrzymuje 270 km w deszczu
      expect(result.didWaxWashoutOccur, isFalse);
      expect(result.updatedChain.isWashedOut, isFalse);
      expect(result.updatedChain.waxFilmRemainingPercent, greaterThan(20.0));
      expect(result.updatedChain.effectiveFrictionLossWatts, lessThan(6.5));
    });

    test('Wyciągnięcie łańcucha powyżej 0.50% generuje alert o konieczności wymiany', () {
      const wornChain = ChainAndWaxCondition(
        lubricantType: DrivetrainLubricantType.hotMeltWaxStandard,
        waxFilmRemainingPercent: 80.0,
        chainElongationPercent: 0.52,
        totalChainMileageKm: 3200.0,
        mileageSinceLastWaxKm: 120.0,
        isWashedOut: false,
      );

      expect(wornChain.needsReplacement, isTrue);
      expect(wornChain.chainSnapRiskFactor, greaterThan(0.015));
    });
  });

  group('EquipmentWearAndMaintenance - Opony, Bieżnik i Mikronacięcia po Bruku', () {
    test('Etap po bruku Paryż-Roubaix generuje mikronacięcia kordu podnoszące ryzyko defektu', () {
      final wear = EquipmentWearAndMaintenance.brandNew();

      // Etap z 32 km bruku
      final result = wear.simulateStageWear(
        stageDistanceKm: 255.0,
        elevationGainMeters: 600.0,
        descentElevationMeters: 600.0,
        isRaining: false,
        cobblestoneDistanceKm: 32.0,
      );

      expect(result.newFrontTireMicroCuts, greaterThanOrEqualTo(4));
      expect(result.newRearTireMicroCuts, greaterThanOrEqualTo(5));
      expect(result.updatedRearTire.microCutsCount, greaterThanOrEqualTo(5));

      // Ryzyko przebicia rośnie po mikronacięciach
      expect(
        result.updatedRearTire.punctureRiskMultiplier,
        greaterThan(wear.rearTire.punctureRiskMultiplier),
      );
    });

    test('Tylna opona zużywa się szybciej niż przednia z racji przenoszenia napędu', () {
      final wear = EquipmentWearAndMaintenance.brandNew();

      final result = wear.simulateStageWear(
        stageDistanceKm: 200.0,
        elevationGainMeters: 1500.0,
        descentElevationMeters: 1500.0,
        isRaining: false,
      );

      expect(
        result.updatedRearTire.treadWearPercent,
        greaterThan(result.updatedFrontTire.treadWearPercent),
      );
    });

    test('Wyschnięte lub brakujące mleczko tubeless dramatycznie zwiększa podatność na przebicie', () {
      const dryTire = TireWearCondition(
        treadWearPercent: 20.0,
        microCutsCount: 2,
        tubelessSealantVolumeMl: 2.0, // Resztki mleczka
        tubelessSealantFreshnessPercent: 10.0, // Zaschnięte
        totalMileageKm: 1200.0,
      );

      const freshTire = TireWearCondition(
        treadWearPercent: 20.0,
        microCutsCount: 2,
        tubelessSealantVolumeMl: 35.0,
        tubelessSealantFreshnessPercent: 90.0,
        totalMileageKm: 1200.0,
      );

      expect(dryTire.needsSealantTopUp, isTrue);
      expect(dryTire.punctureRiskMultiplier, greaterThan(freshTire.punctureRiskMultiplier * 2.0));
    });
  });

  group('EquipmentWearAndMaintenance - Hamulce na Deszczowych Zjazdach Alpejskich', () {
    test('Klocki żywiczne w deszczu na alpejskim zjeździe 3500m ścierają się drastycznie szybciej niż spiekane', () {
      final wearResin = EquipmentWearAndMaintenance.brandNew(
        padCompound: BrakePadCompound.organicResin,
      );
      final wearMetallic = EquipmentWearAndMaintenance.brandNew(
        padCompound: BrakePadCompound.metallicSintered,
      );

      // Deszczowy alpejski etap królewski z 3500m zjazdów
      final resultResin = wearResin.simulateStageWear(
        stageDistanceKm: 175.0,
        elevationGainMeters: 3800.0,
        descentElevationMeters: 3500.0,
        isRaining: true,
        roadWetness: 0.90,
      );

      final resultMetallic = wearMetallic.simulateStageWear(
        stageDistanceKm: 175.0,
        elevationGainMeters: 3800.0,
        descentElevationMeters: 3500.0,
        isRaining: true,
        roadWetness: 0.90,
      );

      // Klocki żywiczne tracą ponad 35-45% okładziny w jeden etap!
      expect(resultResin.frontPadWearDeltaPercent, greaterThan(35.0));
      expect(resultResin.updatedFrontBrake.padWearPercent, greaterThan(35.0));

      // Klocki metaliczne ścierają się znacznie mniej (<18%)
      expect(resultMetallic.frontPadWearDeltaPercent, lessThan(18.0));
      expect(resultResin.frontPadWearDeltaPercent, greaterThan(resultMetallic.frontPadWearDeltaPercent * 2.5));

      // Wynik żywicznych zawiera rekomendację wymiany
      expect(
        resultResin.mechanicNotes.any((n) => n.contains('żywiczne') && n.contains('Sintered')),
        isTrue,
      );
    });

    test('Zeszklenie tarcz i klocków na stromych zjazdach obniża indeks efektywności hamowania', () {
      final wear = EquipmentWearAndMaintenance.brandNew(
        padCompound: BrakePadCompound.metallicSintered,
      );

      final result = wear.simulateStageWear(
        stageDistanceKm: 140.0,
        elevationGainMeters: 3200.0,
        descentElevationMeters: 3200.0,
        isRaining: false,
      );

      expect(result.updatedFrontBrake.rotorGlazingPercent, greaterThan(15.0));
      expect(result.updatedFrontBrake.brakingEfficiencyIndex, lessThan(1.0));
    });
  });

  group('EquipmentWearAndMaintenance - Akcje Warsztatowe Mechaników', () {
    test('Wygotowanie w wosku na gorąco przywraca 100% filmu woskowego', () {
      final worn = EquipmentWearAndMaintenance.brandNew().copyWith(
        chain: const ChainAndWaxCondition(
          lubricantType: DrivetrainLubricantType.hotMeltWaxStandard,
          waxFilmRemainingPercent: 12.0,
          chainElongationPercent: 0.25,
          totalChainMileageKm: 850.0,
          mileageSinceLastWaxKm: 420.0,
          isWashedOut: true,
        ),
      );

      final serviced = worn.performHotMeltWaxing(allWeatherFormula: true);
      expect(serviced.chain.waxFilmRemainingPercent, equals(100.0));
      expect(serviced.chain.isWashedOut, isFalse);
      expect(serviced.chain.lubricantType, equals(DrivetrainLubricantType.hotMeltWaxAllWeather));
      expect(serviced.chain.mileageSinceLastWaxKm, equals(0.0));
    });

    test('Wymiana klocków i opon resetuje ich wskaźniki zużycia', () {
      final worn = EquipmentWearAndMaintenance.brandNew().copyWith(
        rearTire: const TireWearCondition(
          treadWearPercent: 88.0,
          microCutsCount: 7,
          tubelessSealantVolumeMl: 8.0,
          tubelessSealantFreshnessPercent: 30.0,
          totalMileageKm: 2800.0,
        ),
        frontBrake: const BrakeWearCondition(
          padCompound: BrakePadCompound.organicResin,
          padWearPercent: 84.0,
          rotorWearPercent: 40.0,
          rotorGlazingPercent: 60.0,
          hydraulicFluidConditionPercent: 75.0,
        ),
      );

      expect(worn.rearTire.needsReplacement, isTrue);
      expect(worn.frontBrake.needsPadReplacement, isTrue);

      final refreshed = worn
          .replaceTires(front: false, rear: true)
          .replaceBrakePads(compound: BrakePadCompound.metallicSintered, front: true, rear: false);

      expect(refreshed.rearTire.treadWearPercent, equals(0.0));
      expect(refreshed.rearTire.microCutsCount, equals(0));
      expect(refreshed.rearTire.needsReplacement, isFalse);

      expect(refreshed.frontBrake.padWearPercent, equals(0.0));
      expect(refreshed.frontBrake.padCompound, equals(BrakePadCompound.metallicSintered));
      expect(refreshed.frontBrake.needsPadReplacement, isFalse);
    });

    test('Grand Tour Complete Overhaul przywraca rower do stanu idealnego', () {
      final worn = EquipmentWearAndMaintenance.brandNew().copyWith(
        chain: const ChainAndWaxCondition(
          lubricantType: DrivetrainLubricantType.strippedNoLube,
          waxFilmRemainingPercent: 0.0,
          chainElongationPercent: 0.45,
          totalChainMileageKm: 1800.0,
          mileageSinceLastWaxKm: 300.0,
          isWashedOut: true,
        ),
        frontTire: const TireWearCondition(
          treadWearPercent: 65.0,
          microCutsCount: 4,
          tubelessSealantVolumeMl: 12.0,
          tubelessSealantFreshnessPercent: 40.0,
          totalMileageKm: 1800.0,
        ),
      );

      final overhauled = worn.performCompleteGrandTourOverhaul(
        allWeatherWax: true,
        padCompound: BrakePadCompound.metallicSintered,
      );

      expect(overhauled.overallHealthIndex, greaterThanOrEqualTo(95));
      expect(overhauled.urgentMaintenanceAlerts, isEmpty);
      expect(overhauled.chain.isWashedOut, isFalse);
      expect(overhauled.chain.lubricantType, equals(DrivetrainLubricantType.hotMeltWaxAllWeather));
    });
  });

  group('EquipmentWearAndMaintenance - Integracja z CompleteBike i Serializacja JSON', () {
    test('CompleteBike udostępnia właściwość wear i metodę applyWear', () {
      const bike = CompleteBike(
        id: 'bike_test',
        name: 'Race Lab Aero',
        frame: FrameModel(
          id: 'f1',
          brandId: 'b1',
          name: 'Aero 1',
          category: FrameCategory.aero,
          weightGrams: 900,
          aeroCdaModifier: -0.015,
          stiffnessToWeightIndex: 2.0,
          comfortCompliance: 0.6,
          priceEur: 3500,
          mesh3dAssetPath: 'models/bike.glb',
          primaryColorHex: '#00E5FF',
        ),
        wheelset: WheelsetModel(
          id: 'w1',
          brandId: 'b1',
          name: 'Wheels 50',
          rimDepthMm: 50,
          weightGrams: 1400,
          aeroCdaModifier: -0.010,
          crosswindStabilityPenalty: 0.2,
          momentOfInertia: 0.12,
          hubEngagementDragWatts: 0.5,
          priceEur: 1500,
        ),
        groupset: GroupsetModel(
          id: 'g1',
          brandId: 'b1',
          name: 'Di2 12s',
          weightGrams: 2200,
          isElectronic: true,
          speedCount: 12,
          mechanicalEfficiency: 0.985,
          priceEur: 2400,
        ),
        tire: TireModel(
          id: 't1',
          brandId: 'b1',
          name: 'GP5000',
          widthMm: 28,
          weightGrams: 230,
          rollingResistanceCrr: 0.0032,
          punctureResistanceIndex: 3.5,
          wetGripIndex: 4.0,
          isTubeless: true,
          priceEur: 70,
        ),
        cockpitWidthMm: 380,
        hoodInwardTiltDegrees: 12.0,
        slammedStem: true,
      );

      // Domyślnie rower ma fabrycznie nowy stan
      expect(bike.wear.chain.waxFilmRemainingPercent, equals(100.0));
      expect(bike.wear.overallHealthIndex, greaterThanOrEqualTo(95));

      // Zastosowanie nowego stanu zużycia
      final newWear = bike.wear.copyWith(
        chain: bike.wear.chain.copyWith(chainElongationPercent: 0.55),
      );
      final updatedBike = bike.applyWear(newWear);

      expect(updatedBike.wear.chain.chainElongationPercent, equals(0.55));
      expect(updatedBike.wear.chain.needsReplacement, isTrue);
    });

    test('Serializacja toJson i deserializacja fromJson działa bezstratnie', () {
      final original = EquipmentWearAndMaintenance.brandNew(
        allWeatherWax: true,
        padCompound: BrakePadCompound.metallicSintered,
      ).copyWith(
        chain: const ChainAndWaxCondition(
          lubricantType: DrivetrainLubricantType.hotMeltWaxAllWeather,
          waxFilmRemainingPercent: 64.5,
          chainElongationPercent: 0.28,
          totalChainMileageKm: 1240.0,
          mileageSinceLastWaxKm: 310.0,
          isWashedOut: false,
        ),
        rearTire: const TireWearCondition(
          treadWearPercent: 42.0,
          microCutsCount: 3,
          tubelessSealantVolumeMl: 26.5,
          tubelessSealantFreshnessPercent: 78.0,
          totalMileageKm: 1240.0,
        ),
      );

      final json = original.toJson();
      final restored = EquipmentWearAndMaintenance.fromJson(json);

      expect(restored.chain.lubricantType, equals(original.chain.lubricantType));
      expect(restored.chain.waxFilmRemainingPercent, equals(original.chain.waxFilmRemainingPercent));
      expect(restored.chain.chainElongationPercent, equals(original.chain.chainElongationPercent));
      expect(restored.rearTire.microCutsCount, equals(original.rearTire.microCutsCount));
      expect(restored.frontBrake.padCompound, equals(original.frontBrake.padCompound));
      expect(restored.overallHealthIndex, equals(original.overallHealthIndex));
    });
  });
}

