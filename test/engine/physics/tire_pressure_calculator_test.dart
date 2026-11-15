// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/tire_pressure_calculator.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/groupset_model.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';

void main() {
  const samplePhysiology = RiderPhysiology(
    heightCm: 178.0,
    weightKg: 68.0,
    bodyFatPercentage: 6.8,
    ftpWatts: 420,
    wPrimeJoules: 24000,
    vo2Max: 84.5,
    maxHr: 198,
    restingHr: 39,
    lactateThresholdHr: 176,
    recoveryRate: 88.0,
    glycogenCapacityGrams: 520.0,
  );

  const sampleBike = CompleteBike(
    id: 'bike-aero-1',
    name: 'Canyon Aeroad CFR',
    frame: FrameModel(
      id: 'frame-1',
      brandId: 'canyon',
      name: 'Aeroad CFR',
      category: FrameCategory.aero,
      weightGrams: 915,
      aeroCdaModifier: -0.018,
      stiffnessToWeightIndex: 2.1,
      comfortCompliance: 0.65,
      priceEur: 4500,
      mesh3dAssetPath: 'assets/models/frame.glb',
      primaryColorHex: '#1A1A1A',
    ),
    wheelset: WheelsetModel(
      id: 'wheels-1',
      brandId: 'dt_swiss',
      name: 'ARC 1100 50mm',
      rimDepthMm: 50,
      weightGrams: 1470,
      aeroCdaModifier: -0.012,
      crosswindStabilityPenalty: 0.22,
      momentOfInertia: 0.125,
      hubEngagementDragWatts: 0.45,
      priceEur: 2400,
    ),
    groupset: GroupsetModel(
      id: 'groupset-1',
      brandId: 'shimano',
      name: 'Dura-Ace Di2 R9200',
      weightGrams: 2200,
      isElectronic: true,
      speedCount: 12,
      mechanicalEfficiency: 0.985,
      priceEur: 3800,
    ),
    tire: TireModel(
      id: 'tire-gp5000-28',
      brandId: 'continental',
      name: 'GP5000 S TR',
      widthMm: 28,
      weightGrams: 275,
      rollingResistanceCrr: 0.0035,
      punctureResistanceIndex: 4.0,
      wetGripIndex: 4.5,
      isTubeless: true,
      priceEur: 85,
    ),
    cockpitWidthMm: 380,
    hoodInwardTiltDegrees: 12.0,
    slammedStem: true,
  );

  group('TirePressureCalculator - Szerokość Opon (25, 28, 30, 32 mm)', () {
    test('Węższa opona (25mm) wymaga znacznie wyższego ciśnienia niż szersza (30/32mm)', () {
      const totalMass = 76.0; // 68kg kolarz + 7kg rower + 1kg bidon

      final rec25 = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: totalMass,
        tireWidthMm: 25,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      final rec28 = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: totalMass,
        tireWidthMm: 28,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      final rec30 = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: totalMass,
        tireWidthMm: 30,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      final rec32 = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: totalMass,
        tireWidthMm: 32,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      // Ciśnienie powinno ściśle maleć wraz ze wzrostem szerokości opony
      expect(rec25.rearPressureBar, greaterThan(rec28.rearPressureBar));
      expect(rec28.rearPressureBar, greaterThan(rec30.rearPressureBar));
      expect(rec30.rearPressureBar, greaterThan(rec32.rearPressureBar));

      // Dla 28mm na szosie ciśnienie z tyłu powinno wynosić ok. 3.9 - 4.4 BAR (56 - 64 PSI)
      expect(rec28.rearPressureBar, inInclusiveRange(3.9, 4.4));
      expect(rec28.rearPressurePsi, inInclusiveRange(56.0, 64.0));

      // Dla 32mm ciśnienie z tyłu powinno spaść poniżej 3.7 BAR
      expect(rec32.rearPressureBar, lessThan(3.7));
    });

    test('Wewnętrzna szerokość felgi poszerza balon opony i obniża optymalne ciśnienie', () {
      final recNarrowRim = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 78.0,
        tireWidthMm: 28,
        internalRimWidthMm: 19.0, // Standard ETRTO
      );

      final recWideRim = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 78.0,
        tireWidthMm: 28,
        internalRimWidthMm: 25.0, // Nowoczesna szeroka felga szosowa/gravel
      );

      expect(recWideRim.effectiveTireWidthMm, greaterThan(recNarrowRim.effectiveTireWidthMm));
      expect(recWideRim.rearPressureBar, lessThanOrEqualTo(recNarrowRim.rearPressureBar));
    });
  });

  group('TirePressureCalculator - System Ogumienia (Tubeless vs TPU vs Lateks vs Butyl)', () {
    test('System Tubeless pozwala na najniższe bezpieczne ciśnienie bez ryzyka snakebite', () {
      const mass = 75.0;

      final recTubeless = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: mass,
        tireWidthMm: 28,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      final recTpu = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: mass,
        tireWidthMm: 28,
        tireSystem: TireSystemType.tpuTube,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      final recLatex = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: mass,
        tireWidthMm: 28,
        tireSystem: TireSystemType.latexTube,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      final recButyl = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: mass,
        tireWidthMm: 28,
        tireSystem: TireSystemType.butylTube,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      // Tubeless wymaga najniższego ciśnienia, Butyl najwyższego
      expect(recTubeless.rearPressureBar, lessThan(recTpu.rearPressureBar));
      expect(recTpu.rearPressureBar, lessThanOrEqualTo(recLatex.rearPressureBar));
      expect(recLatex.rearPressureBar, lessThan(recButyl.rearPressureBar));

      // Dętka butylowa ma minimalne bezpieczne ciśnienie wyższe z powodu ryzyka dobicia
      expect(recButyl.minSafeRearPressureBar, greaterThan(recTubeless.minSafeRearPressureBar));
    });

    test('Wewnętrzne straty dętki (Internal Tube Loss) są zerowe w Tubeless i najwyższe w butylu', () {
      expect(TireSystemType.tubeless.internalTubeLossWatts, equals(0.0));
      expect(TireSystemType.tpuTube.internalTubeLossWatts, inInclusiveRange(0.5, 1.0));
      expect(TireSystemType.latexTube.internalTubeLossWatts, inInclusiveRange(0.3, 0.7));
      expect(TireSystemType.butylTube.internalTubeLossWatts, greaterThan(3.0));
    });
  });

  group('TirePressureCalculator - Nawierzchnie i Warunki (Asfalt vs Bruk vs Deszcz)', () {
    test('Gładki asfalt pozwala na wyższe ciśnienie, a chropowaty wymaga redukcji', () {
      final recSmooth = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 75.0,
        tireWidthMm: 28,
        surface: RoadSurfaceCategory.smoothAsphalt,
      );

      final recRough = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 75.0,
        tireWidthMm: 28,
        surface: RoadSurfaceCategory.roughAsphalt,
      );

      expect(recSmooth.rearPressureBar, greaterThan(recRough.rearPressureBar));
    });

    test('Na deszczowym asfalcie ciśnienie jest redukowane o ~8% dla przyczepności', () {
      final recDry = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 75.0,
        tireWidthMm: 28,
        surface: RoadSurfaceCategory.averageAsphalt,
        isWet: false,
      );

      final recWet = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 75.0,
        tireWidthMm: 28,
        surface: RoadSurfaceCategory.averageAsphalt,
        isWet: true,
      );

      expect(recWet.isWet, isTrue);
      expect(recWet.rearPressureBar, lessThan(recDry.rearPressureBar));
      expect(recWet.frontPressureBar, lessThan(recDry.frontPressureBar));
    });

    test('Na bruku (Paris-Roubaix) optymalne ciśnienie spada poniżej 3.3 BAR dla opon 30-32mm', () {
      final recCobblesDry = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 75.0,
        tireWidthMm: 30,
        surface: RoadSurfaceCategory.cobblestones,
      );

      final recCobblesWet = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 75.0,
        tireWidthMm: 32,
        surface: RoadSurfaceCategory.wetCobblestones,
      );

      // Zgodne z praktyką WorldTour (np. Jumbo-Visma, UAE Team Emirates na Roubaix)
      expect(recCobblesDry.rearPressureBar, inInclusiveRange(2.8, 3.4));
      expect(recCobblesDry.frontPressureBar, inInclusiveRange(2.5, 3.1));

      // Mokry bruk wymaga jeszcze niższego ciśnienia na oponie 32mm
      expect(recCobblesWet.rearPressureBar, inInclusiveRange(2.4, 2.9));
      expect(recCobblesWet.frontPressureBar, inInclusiveRange(2.1, 2.6));
    });
  });

  group('TirePressureCalculator - Rozkład Masy Przód / Tył', () {
    test('Tylne koło nosi więcej masy (55% vs 45%), więc wymaga wyższego ciśnienia', () {
      final rec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 78.0,
        tireWidthMm: 28,
        frontWeightRatio: 0.45,
      );

      expect(rec.rearPressureBar, greaterThan(rec.frontPressureBar));
      expect(rec.rearPressurePsi, greaterThan(rec.frontPressurePsi));
      // Typowa różnica między przodem a tyłem to ok. 0.3 - 0.5 BAR
      expect(rec.rearPressureBar - rec.frontPressureBar, inInclusiveRange(0.2, 0.6));
    });
  });

  group('TirePressureCalculator - Fizyka Strat Mocy (Impedancja vs Histereza) i Bruk', () {
    test('Przepompowanie opon na bruku generuje potężne straty impedancyjne (+15W do +25W)', () {
      final recRoubaix = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 76.0,
        tireWidthMm: 30,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.cobblestones,
      );

      // Rekomendowane optymalne ciśnienie na bruku dla 30mm wynosi ~3.1 BAR z tyłu
      expect(recRoubaix.rearPressureBar, inInclusiveRange(2.8, 3.3));

      // Załóżmy, że zawodnik wjechał na bruk z kołami napompowanymi szosowo do 5.5 BAR z tyłu i 5.0 BAR z przodu!
      final evaluation = TirePressureCalculator.evaluatePressure(
        frontPressureBar: 5.0,
        rearPressureBar: 5.5,
        recommendation: recRoubaix,
        speedKmh: 42.0,
      );

      // Straty impedancyjne wynikające z odbijania od kamieni powinny wynosić 15 - 25W lub więcej!
      expect(evaluation.impedanceLossWatts, greaterThanOrEqualTo(15.0));
      expect(evaluation.verdict, equals(PressureEvaluationVerdict.severeOverpressureImpedance));
      expect(evaluation.corneringGripPercent, lessThan(80.0));
      expect(evaluation.diagnosticMessage, contains('Ekstremalne nadciśnienie'));
    });

    test('Optymalne ciśnienie skutkuje zerowymi stratami impedancyjnymi i maksymalną przyczepnością', () {
      final rec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 76.0,
        tireWidthMm: 28,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      final evaluation = TirePressureCalculator.evaluatePressure(
        frontPressureBar: rec.frontPressureBar,
        rearPressureBar: rec.rearPressureBar,
        recommendation: rec,
      );

      expect(evaluation.impedanceLossWatts, equals(0.0));
      expect(evaluation.hysteresisLossDeltaWatts, equals(0.0));
      expect(evaluation.totalRollingPenaltyWatts, equals(0.0));
      expect(evaluation.corneringGripPercent, equals(100.0));
      expect(evaluation.verdict, equals(PressureEvaluationVerdict.optimal));
    });

    test('Niedopompowane opony generują straty histerezy karkasu i uginanie gumy', () {
      final rec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 76.0,
        tireWidthMm: 28,
        surface: RoadSurfaceCategory.averageAsphalt,
      );

      // Obniżamy ciśnienie o 1.0 BAR poniżej optymalnego
      final evaluation = TirePressureCalculator.evaluatePressure(
        frontPressureBar: rec.frontPressureBar - 1.0,
        rearPressureBar: rec.rearPressureBar - 1.0,
        recommendation: rec,
      );

      expect(evaluation.impedanceLossWatts, equals(0.0));
      expect(evaluation.hysteresisLossDeltaWatts, greaterThan(2.0));
      expect(evaluation.verdict, anyOf(
        equals(PressureEvaluationVerdict.slightlyLow),
        equals(PressureEvaluationVerdict.dangerouslyLowPinchFlatRisk),
      ));
    });
  });

  group('TirePressureCalculator - Zagrożenie Dobicie Dętki (Snakebite Pinch-Flat)', () {
    test('Drastycznie niskie ciśnienie w dętce butylowej na bruku wywołuje wysokie ryzyko snakebite', () {
      final rec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 80.0,
        tireWidthMm: 25,
        tireSystem: TireSystemType.butylTube,
        surface: RoadSurfaceCategory.cobblestones,
      );

      // Pompowanie zaledwie 2.2 BAR na dętce butylowej na bruku
      final evaluation = TirePressureCalculator.evaluatePressure(
        frontPressureBar: 2.2,
        rearPressureBar: 2.4,
        recommendation: rec,
      );

      expect(evaluation.pinchFlatRiskPercent, greaterThan(40.0));
      expect(evaluation.verdict, equals(PressureEvaluationVerdict.dangerouslyLowPinchFlatRisk));
      expect(evaluation.diagnosticMessage, contains('snakebite'));
    });

    test('System Tubeless nie posiada dętki, więc ma 0% ryzyka przyszczypnięcia dętki', () {
      final rec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 75.0,
        tireWidthMm: 30,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.cobblestones,
      );

      // Nawet przy ciśnieniu poniżej progu minSafe, ryzyko snakebite dętki wynosi 0
      final evaluation = TirePressureCalculator.evaluatePressure(
        frontPressureBar: rec.minSafeFrontPressureBar - 0.2,
        rearPressureBar: rec.minSafeRearPressureBar - 0.2,
        recommendation: rec,
      );

      expect(evaluation.pinchFlatRiskPercent, equals(0.0));
    });
  });

  group('TirePressureCalculator - Limity Bezpieczeństwa Obręczy Hookless (5.0 BAR / 72.5 PSI)', () {
    test('Ostrzega, gdy wyliczone ciśnienie dla wąskiej opony i ciężkiego kolarza przekracza normę Hookless', () {
      final rec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 95.0, // Ciężki zawodnik z rowerem
        tireWidthMm: 25, // Zbyt wąska opona
        rimType: RimType.hookless,
      );

      expect(rec.isHooklessExceededWarning, isTrue);
      expect(rec.technicalNotes.any((note) => note.contains('Hookless')), isTrue);
    });

    test('Ewaluacja wykrywa przekroczenie 5.0 BAR na hookless jako krytyczne niebezpieczeństwo', () {
      final rec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 75.0,
        tireWidthMm: 28,
        rimType: RimType.hookless,
      );

      final evaluation = TirePressureCalculator.evaluatePressure(
        frontPressureBar: 5.4,
        rearPressureBar: 5.6,
        recommendation: rec,
      );

      expect(evaluation.isHooklessExceededDanger, isTrue);
      expect(evaluation.verdict, equals(PressureEvaluationVerdict.hooklessDanger));
      expect(evaluation.diagnosticMessage, contains('Hookless'));
    });
  });

  group('TirePressureCalculator - Integracja z CompleteBike i SegmentSurfaceType', () {
    test('calculateFromBikeAndRider poprawnie pobiera masę, szerokość opony i system tubeless', () {
      final rec = TirePressureCalculator.calculateFromBikeAndRider(
        bike: sampleBike,
        physiology: samplePhysiology,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        isWet: false,
      );

      // Kolarz 68kg + Canyon Aeroad (~7.5kg) + 1kg ekwipunek = ~76.5kg
      expect(rec.totalMassKg, inInclusiveRange(75.0, 78.0));
      expect(rec.nominalTireWidthMm, equals(28));
      expect(rec.tireSystem, equals(TireSystemType.tubeless));
      expect(rec.surface, equals(RoadSurfaceCategory.cobblestones));
      expect(rec.frontPressureBar, lessThan(rec.rearPressureBar));
    });

    test('calculateFromBikeAndRider uwzględnia mokry segment jako wetCobblestones', () {
      final rec = TirePressureCalculator.calculateFromBikeAndRider(
        bike: sampleBike,
        physiology: samplePhysiology,
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        isWet: true,
      );

      expect(rec.isWet, isTrue);
      expect(rec.surface, equals(RoadSurfaceCategory.wetCobblestones));
    });
  });

  group('TirePressureCalculator - Konwersje BAR <-> PSI i Serializacja JSON', () {
    test('Konwersja BAR na PSI i odwrotnie jest matematycznie dokładna', () {
      expect(TirePressureCalculator.barToPsi(1.0), closeTo(14.50377, 0.001));
      expect(TirePressureCalculator.psiToBar(14.50377), closeTo(1.0, 0.001));
      expect(TirePressureCalculator.barToPsi(4.0), closeTo(58.015, 0.01));
    });

    test('Serializacja TirePressureRecommendation do JSON i deserializacja fromJson działa bezstratnie', () {
      final rec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: 77.5,
        tireWidthMm: 28,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.roughAsphalt,
        isWet: true,
        rimType: RimType.hooked,
      );

      final json = rec.toJson();
      final restored = TirePressureRecommendation.fromJson(json);

      expect(restored.frontPressureBar, equals(rec.frontPressureBar));
      expect(restored.rearPressureBar, equals(rec.rearPressureBar));
      expect(restored.frontPressurePsi, equals(rec.frontPressurePsi));
      expect(restored.rearPressurePsi, equals(rec.rearPressurePsi));
      expect(restored.totalMassKg, equals(rec.totalMassKg));
      expect(restored.nominalTireWidthMm, equals(rec.nominalTireWidthMm));
      expect(restored.tireSystem, equals(rec.tireSystem));
      expect(restored.surface, equals(rec.surface));
      expect(restored.rimType, equals(rec.rimType));
      expect(restored.isWet, equals(rec.isWet));
      expect(restored.adviceSummary, equals(rec.adviceSummary));
    });
  });
}
