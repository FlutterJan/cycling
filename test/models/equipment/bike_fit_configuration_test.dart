// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/equipment/bike_fit_configuration.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/groupset_model.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';

void main() {
  group('BikeFitConfiguration - Model & Core Attributes', () {
    test('Tworzy pełną konfigurację fittingu ze wszystkimi 9 parametrami', () {
      const fit = BikeFitConfiguration(
        saddleHeightMm: 748.0,
        saddleSetbackMm: 62.0,
        saddleTiltDegrees: -2.0,
        cockpitWidthMm: 380,
        stemLengthMm: 120,
        spacersStackMm: 10,
        hoodInwardTiltDegrees: 12.0,
        crankArmLengthMm: 170.0,
        cleatOffsetMm: -4.0,
      );

      expect(fit.saddleHeightMm, equals(748.0));
      expect(fit.saddleSetbackMm, equals(62.0));
      expect(fit.saddleTiltDegrees, equals(-2.0));
      expect(fit.cockpitWidthMm, equals(380));
      expect(fit.stemLengthMm, equals(120));
      expect(fit.spacersStackMm, equals(10));
      expect(fit.hoodInwardTiltDegrees, equals(12.0));
      expect(fit.crankArmLengthMm, equals(170.0));
      expect(fit.cleatOffsetMm, equals(-4.0));

      expect(fit.isSlammedStem, isFalse);
      expect(fit.hasExtremeAeroHoods, isFalse);
      expect(fit.isUciLegal, isTrue);
      expect(fit.uciHoodTiltExcessDegrees, equals(0.0));
    });

    test('Weryfikacja slammed stem dla zerowych podkładek', () {
      final fitSlammed = BikeFitConfiguration.slammedAeroRoad();
      expect(fitSlammed.spacersStackMm, equals(0));
      expect(fitSlammed.isSlammedStem, isTrue);

      final fitSpacers = fitSlammed.copyWith(spacersStackMm: 15);
      expect(fitSpacers.isSlammedStem, isFalse);
    });
  });

  group('BikeFitConfiguration - Zgodność z przepisami technicznymi UCI', () {
    test('Konfiguracja WorldTour Balanced spełnia wszystkie normy UCI', () {
      final fit = BikeFitConfiguration.uciWorldTourBalanced();
      expect(fit.isUciLegal, isTrue);
      expect(fit.hasExtremeAeroHoods, isFalse);
      expect(fit.uciHoodTiltExcessDegrees, equals(0.0));
      expect(fit.biomechanicalWarnings, isEmpty);
    });

    test('Wykrywa nielegalne podgięcie klamkomanetek powyżej 14 stopni', () {
      const extremeFit = BikeFitConfiguration(
        saddleHeightMm: 740.0,
        saddleSetbackMm: 55.0,
        saddleTiltDegrees: -2.0,
        cockpitWidthMm: 360,
        stemLengthMm: 130,
        spacersStackMm: 0,
        hoodInwardTiltDegrees: 24.0, // Przekroczenie limitu 14°
        crankArmLengthMm: 165.0,
        cleatOffsetMm: -5.0,
      );

      expect(extremeFit.hasExtremeAeroHoods, isTrue);
      expect(extremeFit.isUciLegal, isFalse);
      expect(extremeFit.uciHoodTiltExcessDegrees, equals(10.0));
      expect(
        extremeFit.biomechanicalWarnings.any((w) => w.contains('limit UCI: 14.0°')),
        isTrue,
      );
    });

    test('Wykrywa przekroczenie dopuszczalnego kąta siodełka (±9 stopni)', () {
      final invalidTilt = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        saddleTiltDegrees: -10.5,
      );
      expect(invalidTilt.isUciLegal, isFalse);

      final validTilt = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        saddleTiltDegrees: -8.5,
      );
      expect(validTilt.isUciLegal, isTrue);
    });

    test('Wykrywa zbyt wąską kierownicę poniżej limitu UCI 350mm', () {
      final tooNarrow = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        cockpitWidthMm: 340,
      );
      expect(tooNarrow.isUciLegal, isFalse);

      final legalNarrow = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        cockpitWidthMm: 360,
      );
      expect(legalNarrow.isUciLegal, isTrue);
    });

    test('Ostrzega o cofnięciu siodła poniżej 50mm wymagającym ulgi morfologicznej', () {
      final morphologyExemptionFit = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        saddleSetbackMm: 42.0,
      );
      expect(morphologyExemptionFit.isUciLegal, isTrue); // technicznie dopuszczone z ulgą
      expect(
        morphologyExemptionFit.biomechanicalWarnings.any((w) => w.contains('morfologicznego')),
        isTrue,
      );
    });
  });

  group('BikeFitConfiguration - Aerodynamika (CdA) i Oszczędność Watów', () {
    test('Węższa kierownica (360mm vs 400mm) redukuje CdA', () {
      final fit400 = BikeFitConfiguration.uciWorldTourBalanced().copyWith(cockpitWidthMm: 400);
      final fit360 = BikeFitConfiguration.uciWorldTourBalanced().copyWith(cockpitWidthMm: 360);

      expect(fit360.totalCdaModifier, lessThan(fit400.totalCdaModifier));
      expect(fit360.totalCdaModifier - fit400.totalCdaModifier, closeTo(-0.010, 0.001));
    });

    test('Podgięte klamki do wewnątrz generują zysk aerodynamiczny', () {
      final straightHoods = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        hoodInwardTiltDegrees: 0.0,
      );
      final tiltedHoods = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        hoodInwardTiltDegrees: 14.0,
      );

      expect(tiltedHoods.totalCdaModifier, lessThan(straightHoods.totalCdaModifier));
    });

    test('Slammed stem (0mm) jest bardziej opływowy niż wysoki komin podkładek (20mm)', () {
      final slammed = BikeFitConfiguration.uciWorldTourBalanced().copyWith(spacersStackMm: 0);
      final highStack = BikeFitConfiguration.uciWorldTourBalanced().copyWith(spacersStackMm: 20);

      expect(slammed.totalCdaModifier, lessThan(highStack.totalCdaModifier));
    });

    test('Kalkuluje oszczędność mocy w Watach przy 45 km/h', () {
      final aeroFit = BikeFitConfiguration.slammedAeroRoad();
      final wattsSaved = aeroFit.estimatedWattsSavedAt45Kmh;

      expect(wattsSaved, greaterThan(10));
      expect(wattsSaved, lessThanOrEqualTo(50));
    });
  });

  group('BikeFitConfiguration - Sterowność i Biomechanika', () {
    test('Agresywny fitting z wąską kierownicą i klamkami >14° obniża sterowność', () {
      final balancedFit = BikeFitConfiguration.uciWorldTourBalanced();
      final extremeAeroFit = BikeFitConfiguration.slammedAeroRoad();

      expect(extremeAeroFit.handlingControlScore, lessThan(balancedFit.handlingControlScore));
    });

    test('Szeroka kierownica 420mm i 20mm spacerów w Cobbled Endurance maksymalizują kontrolę', () {
      final cobbled = BikeFitConfiguration.cobbledEnduranceComfort();
      final slammed = BikeFitConfiguration.slammedAeroRoad();

      expect(cobbled.handlingControlScore, greaterThan(slammed.handlingControlScore));
      expect(cobbled.comfortScore, greaterThan(slammed.comfortScore));
    });

    test('Krótsze ramiona korby (165mm vs 175mm) otwierają kąt biodrowy w GMP', () {
      final fitShortCrank = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        crankArmLengthMm: 165.0,
      );
      final fitLongCrank = BikeFitConfiguration.uciWorldTourBalanced().copyWith(
        crankArmLengthMm: 175.0,
      );

      expect(fitShortCrank.hipAngleAtTdcDegrees, greaterThan(fitLongCrank.hipAngleAtTdcDegrees));
    });

    test('Krótsza korba sprzyja wyższej optymalnej kadencji', () {
      final fit165 = BikeFitConfiguration.uciWorldTourBalanced().copyWith(crankArmLengthMm: 165.0);
      final fit175 = BikeFitConfiguration.uciWorldTourBalanced().copyWith(crankArmLengthMm: 175.0);

      expect(fit165.optimalCadenceRpm, equals(96));
      expect(fit175.optimalCadenceRpm, equals(86));
    });

    test('Przesunięcie bloków do tyłu (mid-foot) odciąża łydki i ścięgno Achillesa', () {
      final midFoot = BikeFitConfiguration.uciWorldTourBalanced().copyWith(cleatOffsetMm: -6.0);
      final toeForward = BikeFitConfiguration.uciWorldTourBalanced().copyWith(cleatOffsetMm: 6.0);

      expect(midFoot.calfStrainIndex, lessThan(toeForward.calfStrainIndex));
    });
  });

  group('BikeFitConfiguration - Proceduralny Generator dla Kolarza', () {
    test('Dopasowuje wysokość siodła i mostek proporcjonalnie do wzrostu kolarza', () {
      final tallRiderFit = BikeFitConfiguration.proceduralForRider(
        heightCm: 190.0,
        weightKg: 78.0,
        isAeroFocus: false,
      );
      final shortRiderFit = BikeFitConfiguration.proceduralForRider(
        heightCm: 170.0,
        weightKg: 60.0,
        isAeroFocus: false,
      );

      expect(tallRiderFit.saddleHeightMm, greaterThan(shortRiderFit.saddleHeightMm));
      expect(tallRiderFit.stemLengthMm, greaterThan(shortRiderFit.stemLengthMm));
      expect(tallRiderFit.cockpitWidthMm, greaterThanOrEqualTo(shortRiderFit.cockpitWidthMm));
    });

    test('Tryb isAeroFocus generuje węższą kierownicę, slammed stem i krótsze korby', () {
      final aeroFit = BikeFitConfiguration.proceduralForRider(
        heightCm: 180.0,
        weightKg: 68.0,
        isAeroFocus: true,
      );
      final comfortFit = BikeFitConfiguration.proceduralForRider(
        heightCm: 180.0,
        weightKg: 68.0,
        isAeroFocus: false,
      );

      expect(aeroFit.spacersStackMm, equals(0));
      expect(aeroFit.isSlammedStem, isTrue);
      expect(aeroFit.cockpitWidthMm, lessThanOrEqualTo(comfortFit.cockpitWidthMm));
      expect(aeroFit.totalCdaModifier, lessThan(comfortFit.totalCdaModifier));
    });
  });

  group('BikeFitConfiguration - Integracja z CompleteBike', () {
    test('CompleteBike udostępnia właściwość bikeFit i metodę applyBikeFit', () {
      const bike = CompleteBike(
        id: 'test_bike_01',
        name: 'Veloce Aero Pro',
        frame: FrameModel(
          id: 'f_aero_01',
          brandId: 'brand_veloce',
          name: 'AeroFoil Disc',
          category: FrameCategory.aero,
          weightGrams: 890,
          aeroCdaModifier: -0.016,
          stiffnessToWeightIndex: 2.1,
          comfortCompliance: 0.65,
          priceEur: 4200,
          mesh3dAssetPath: 'models/bike.glb',
          primaryColorHex: '#E11D48',
        ),
        wheelset: WheelsetModel(
          id: 'w_carbon_50',
          brandId: 'brand_veloce',
          name: 'HyperSpeed 50 Carbon',
          rimDepthMm: 50,
          weightGrams: 1390,
          aeroCdaModifier: -0.009,
          crosswindStabilityPenalty: 0.25,
          momentOfInertia: 0.12,
          hubEngagementDragWatts: 0.5,
          priceEur: 1800,
        ),
        groupset: GroupsetModel(
          id: 'g_dura_di2',
          brandId: 'brand_shim',
          name: 'Apex Di2 12s',
          weightGrams: 2350,
          isElectronic: true,
          speedCount: 12,
          mechanicalEfficiency: 0.98,
          priceEur: 2800,
        ),
        tire: TireModel(
          id: 't_gp5000',
          brandId: 'brand_conti',
          name: 'Grand Prix 5000 S TR',
          widthMm: 28,
          weightGrams: 275,
          rollingResistanceCrr: 0.0033,
          punctureResistanceIndex: 3.8,
          wetGripIndex: 4.4,
          isTubeless: true,
          priceEur: 75,
        ),
        cockpitWidthMm: 380,
        hoodInwardTiltDegrees: 12.0,
        slammedStem: true,
      );

      final fit = bike.bikeFit;
      expect(fit.cockpitWidthMm, equals(380));
      expect(fit.hoodInwardTiltDegrees, equals(12.0));
      expect(fit.isSlammedStem, isTrue);
      expect(fit.spacersStackMm, equals(0));

      final newFit = fit.copyWith(
        cockpitWidthMm: 360,
        hoodInwardTiltDegrees: 14.0,
        spacersStackMm: 10,
      );
      final updatedBike = bike.applyBikeFit(newFit);

      expect(updatedBike.cockpitWidthMm, equals(360));
      expect(updatedBike.hoodInwardTiltDegrees, equals(14.0));
      expect(updatedBike.slammedStem, isFalse);
    });
  });

  group('BikeFitConfiguration - Serializacja JSON i copyWith', () {
    test('Serializacja toJson i deserializacja fromJson działa bezstratnie', () {
      final original = BikeFitConfiguration.slammedAeroRoad();
      final json = original.toJson();
      final recreated = BikeFitConfiguration.fromJson(json);

      expect(recreated, equals(original));
      expect(recreated.saddleHeightMm, equals(original.saddleHeightMm));
      expect(recreated.saddleSetbackMm, equals(original.saddleSetbackMm));
      expect(recreated.saddleTiltDegrees, equals(original.saddleTiltDegrees));
      expect(recreated.cockpitWidthMm, equals(original.cockpitWidthMm));
      expect(recreated.stemLengthMm, equals(original.stemLengthMm));
      expect(recreated.spacersStackMm, equals(original.spacersStackMm));
      expect(recreated.hoodInwardTiltDegrees, equals(original.hoodInwardTiltDegrees));
      expect(recreated.crankArmLengthMm, equals(original.crankArmLengthMm));
      expect(recreated.cleatOffsetMm, equals(original.cleatOffsetMm));
      expect(recreated.hashCode, equals(original.hashCode));
    });

    test('copyWith poprawnie nadpisuje wybrane właściwości', () {
      final base = BikeFitConfiguration.uciWorldTourBalanced();
      final modified = base.copyWith(
        saddleHeightMm: 765.0,
        cockpitWidthMm: 360,
        crankArmLengthMm: 165.0,
      );

      expect(modified.saddleHeightMm, equals(765.0));
      expect(modified.cockpitWidthMm, equals(360));
      expect(modified.crankArmLengthMm, equals(165.0));
      // Niezmienione pola
      expect(modified.saddleSetbackMm, equals(base.saddleSetbackMm));
      expect(modified.stemLengthMm, equals(base.stemLengthMm));
      expect(modified.spacersStackMm, equals(base.spacersStackMm));
      expect(modified.hoodInwardTiltDegrees, equals(base.hoodInwardTiltDegrees));
    });

    test('toString zawiera kluczowe dane geometryczne i modyfikator CdA', () {
      final fit = BikeFitConfiguration.slammedAeroRoad();
      final str = fit.toString();

      expect(str.contains('BikeFitConfiguration'), isTrue);
      expect(str.contains('saddle:'), isTrue);
      expect(str.contains('cockpit:'), isTrue);
      expect(str.contains('cranks:'), isTrue);
      expect(str.contains('CdA:'), isTrue);
    });
  });
}
