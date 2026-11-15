// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/nutrition_and_glycogen_engine.dart';
import 'package:pro_peloton_manager/models/rider/lactate_and_lab_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  group('LactateAndLabProfile - Model & Laboratory Parameters', () {
    test('Tworzy pełny profil laboratoryjny z prawidłowymi progami LT1, LT2, VLaMax, VO2max i GE', () {
      const profile = LactateAndLabProfile(
        lt1Watts: 280,
        lt1LactateMmolL: 1.8,
        lt1HeartRateBpm: 148,
        fatMaxWatts: 270,
        fatMaxOxidationRateGramsPerHour: 58.0,
        lt2Watts: 380,
        lt2LactateMmolL: 4.0,
        lt2HeartRateBpm: 174,
        vlaMaxMmolLPerSec: 0.35,
        vo2MaxMlKgMin: 82.0,
        powerAtVo2MaxWatts: 460,
        grossEfficiencyPercent: 22.8,
        deltaEfficiencyPercent: 24.6,
        referenceWeightKg: 68.0,
      );

      // Weryfikacja parametrów progu tlenowego LT1
      expect(profile.lt1Watts, 280);
      expect(profile.lt1LactateMmolL, 1.8);
      expect(profile.lt1HeartRateBpm, 148);
      expect(profile.fatMaxWatts, 270);
      expect(profile.fatMaxOxidationRateGramsPerHour, 58.0);
      expect(profile.lt1WattsPerKg, closeTo(280 / 68.0, 0.01));

      // Weryfikacja parametrów progu beztlenowego LT2 / MLSS
      expect(profile.lt2Watts, 380);
      expect(profile.lt2LactateMmolL, 4.0);
      expect(profile.lt2HeartRateBpm, 174);
      expect(profile.lt2WattsPerKg, closeTo(380 / 68.0, 0.01));
      expect(profile.fractionalUtilization, closeTo(380 / 460, 0.01));

      // Weryfikacja VLaMax i fenotypu
      expect(profile.vlaMaxMmolLPerSec, 0.35);
      expect(profile.metabolicPhenotype, MetabolicPhenotype.allRounder);
      expect(profile.isSprinterPhenotype, isFalse);
      expect(profile.isDieselPhenotype, isFalse);

      // Weryfikacja VO2max
      expect(profile.vo2MaxMlKgMin, 82.0);
      expect(profile.vo2MaxAbsoluteLitersMin, closeTo((82.0 * 68.0) / 1000.0, 0.01));
      expect(profile.powerAtVo2MaxWatts, 460);
      expect(profile.powerAtVo2MaxWattsPerKg, closeTo(460 / 68.0, 0.01));

      // Weryfikacja ekonomii jazdy (Gross Efficiency)
      expect(profile.grossEfficiencyPercent, 22.8);
      expect(profile.deltaEfficiencyPercent, 24.6);
      expect(profile.metabolicKcalPerKjWork, closeTo(0.2390057 / 0.228, 0.01));
    });

    test('Wzorzec World Tour Sprinter ma wysoki VLaMax i fenotyp sprinterski', () {
      final sprinter = LactateAndLabProfile.benchmarkWorldTourSprinter(
        weightKg: 75.0,
        ftpWatts: 410,
      );

      expect(sprinter.vlaMaxMmolLPerSec, greaterThanOrEqualTo(0.70));
      expect(sprinter.isSprinterPhenotype, isTrue);
      expect(sprinter.isDieselPhenotype, isFalse);
      expect(sprinter.metabolicPhenotype, MetabolicPhenotype.pureSprinter);
      expect(sprinter.lt1LactateMmolL, greaterThanOrEqualTo(1.8));
      expect(sprinter.lt2LactateMmolL, greaterThanOrEqualTo(4.0));
      expect(sprinter.fractionalUtilization, lessThan(0.85)); // Mniejszy ułamek VO2max na progu przez wysoki VLaMax
    });

    test('Wzorzec World Tour Climber ma niski VLaMax i potężne W/kg na LT2', () {
      final climber = LactateAndLabProfile.benchmarkWorldTourClimber(
        weightKg: 60.0,
        ftpWatts: 390,
      );

      expect(climber.vlaMaxMmolLPerSec, lessThanOrEqualTo(0.35));
      expect(climber.lt2WattsPerKg, 6.5);
      expect(climber.vo2MaxMlKgMin, greaterThan(85.0));
      expect(climber.isDieselPhenotype, isFalse);
      expect(climber.metabolicPhenotype, MetabolicPhenotype.dieselClimber);
      expect(climber.grossEfficiencyPercent, greaterThanOrEqualTo(23.0));
    });

    test('Wzorzec World Tour Time Trialist ma ekstremalnie niski VLaMax i fenotyp diesla', () {
      final tt = LactateAndLabProfile.benchmarkWorldTourTimeTrialist(
        weightKg: 76.0,
        ftpWatts: 460,
      );

      expect(tt.vlaMaxMmolLPerSec, lessThanOrEqualTo(0.28));
      expect(tt.isDieselPhenotype, isTrue);
      expect(tt.isSprinterPhenotype, isFalse);
      expect(tt.metabolicPhenotype, MetabolicPhenotype.timeTrialistDiesel);
      expect(tt.grossEfficiencyPercent, greaterThanOrEqualTo(24.0));
    });

    test('Wzorzec World Tour Puncheur ma średnio-wysoki VLaMax i dynamiczny profil', () {
      final puncheur = LactateAndLabProfile.benchmarkWorldTourPuncheur(
        weightKg: 72.0,
        ftpWatts: 430,
      );

      expect(puncheur.vlaMaxMmolLPerSec, inInclusiveRange(0.50, 0.65));
      expect(puncheur.metabolicPhenotype, MetabolicPhenotype.explosivePuncheur);
      expect(puncheur.lt2Watts, 430);
    });
  });

  group('LactateAndLabProfile - Kinetyka kwasu mlekowego i model Madera', () {
    test('estimateLactateAtPower odzwierciedla fazy tlenową, SweetSpot i gwałtowny wzrost ponad MLSS', () {
      final climber = LactateAndLabProfile.benchmarkWorldTourClimber(
        weightKg: 60.0,
        ftpWatts: 390,
      );

      // Poniżej LT1 (~308 W)
      final la150W = climber.estimateLactateAtPower(150);
      final la250W = climber.estimateLactateAtPower(250);
      expect(la150W, lessThanOrEqualTo(1.5));
      expect(la250W, lessThanOrEqualTo(climber.lt1LactateMmolL));

      // Na progu LT1
      final laLt1 = climber.estimateLactateAtPower(climber.lt1Watts.toDouble());
      expect(laLt1, closeTo(climber.lt1LactateMmolL, 0.05));

      // Pomiędzy LT1 a LT2
      final la350W = climber.estimateLactateAtPower(350);
      expect(la350W, greaterThan(climber.lt1LactateMmolL));
      expect(la350W, lessThan(climber.lt2LactateMmolL));

      // Na progu LT2 / MLSS
      final laLt2 = climber.estimateLactateAtPower(climber.lt2Watts.toDouble());
      expect(laLt2, closeTo(climber.lt2LactateMmolL, 0.05));

      // Ponad LT2 – gwałtowny wzrost stężenia
      final la500W = climber.estimateLactateAtPower(500);
      expect(la500W, greaterThan(6.0));
    });

    test('Sprinter o wysokim VLaMax akumuluje kwas mlekowy znacznie szybciej niż góral/czasowiec', () {
      final sprinter = LactateAndLabProfile.benchmarkWorldTourSprinter(
        weightKg: 75.0,
        ftpWatts: 400,
      );
      final timeTrialist = LactateAndLabProfile.benchmarkWorldTourTimeTrialist(
        weightKg: 75.0,
        ftpWatts: 400,
      );

      // Przy 480W (wysiłek ponadprogowy)
      final sprinterLactate = sprinter.estimateLactateAtPower(480);
      final ttLactate = timeTrialist.estimateLactateAtPower(480);

      expect(sprinterLactate, greaterThan(ttLactate));
    });
  });

  group('LactateAndLabProfile - Spalanie substratów i próba stopniowana', () {
    test('estimateSubstrateOxidation modeluje krzywą FatMax i dominację węglowodanów przy wyższych mocach', () {
      final climber = LactateAndLabProfile.benchmarkWorldTourClimber(
        weightKg: 60.0,
        ftpWatts: 390,
      );

      // W punkcie FatMax spalanie tłuszczów powinno być zbliżone do maksymalnego
      final fatMaxCombustion = climber.estimateSubstrateOxidation(climber.fatMaxWatts.toDouble());
      expect(fatMaxCombustion.fatOxidationRateGramsPerHour, greaterThan(50.0));
      expect(fatMaxCombustion.fatCombustionPercent, greaterThan(35.0));

      // Przy mocy LT2 (390 W) węglowodany dominują, a spalanie tłuszczu zanika
      final lt2Combustion = climber.estimateSubstrateOxidation(climber.lt2Watts.toDouble());
      expect(lt2Combustion.carbCombustionPercent, greaterThan(75.0));
      expect(lt2Combustion.respiratoryExchangeRatioRer, greaterThanOrEqualTo(0.95));

      // Przy mocy MAP (460 W) niemal 100% węglowodanów i RER >= 1.0
      final mapCombustion = climber.estimateSubstrateOxidation(climber.powerAtVo2MaxWatts.toDouble());
      expect(mapCombustion.carbCombustionPercent, greaterThan(88.0));
      expect(mapCombustion.respiratoryExchangeRatioRer, greaterThanOrEqualTo(1.0));
    });

    test('generateLactateCurveSteps generuje poprawny protokół testu stopniowanego (Ramp Test)', () {
      final profile = LactateAndLabProfile.benchmarkWorldTourPuncheur(
        weightKg: 72.0,
        ftpWatts: 420,
      );

      final steps = profile.generateLactateCurveSteps(
        startWatts: 140,
        stepWatts: 40,
        endWatts: 460,
      );

      expect(steps.isNotEmpty, isTrue);
      expect(steps.first.powerWatts, 140);
      expect(steps.last.powerWatts, 460);

      // Wartości mleczanu i tętna rosną monotonicznie ze wzrostem mocy
      for (int i = 1; i < steps.length; i++) {
        expect(steps[i].powerWatts, greaterThan(steps[i - 1].powerWatts));
        expect(steps[i].lactateMmolL, greaterThanOrEqualTo(steps[i - 1].lactateMmolL));
        expect(steps[i].heartRateBpm, greaterThanOrEqualTo(steps[i - 1].heartRateBpm));
      }
    });

    test('getTrainingZones zwraca 7 stref opartych o LT1 i LT2', () {
      final profile = LactateAndLabProfile.benchmarkWorldTourClimber(
        weightKg: 60.0,
        ftpWatts: 390,
      );

      final zones = profile.getTrainingZones();
      expect(zones.length, 7);

      expect(zones[0].code, 'Z1');
      expect(zones[1].code, 'Z2');
      expect(zones[1].maxWatts, profile.lt1Watts); // Z2 kończy się na LT1
      expect(zones[3].code, 'Z4'); // Z4 skupiona wokół LT2
      expect(zones[3].typicalLactateMmolL, profile.lt2LactateMmolL);
      expect(zones[4].code, 'Z5'); // Z5 VO2max
      expect(zones[5].code, 'Z6'); // Z6 Beztlenowa
      expect(zones[6].code, 'Z7'); // Z7 Neuromuscular
    });
  });

  group('LactateAndLabProfile - Integracja z generatorem proceduralnym i kolarzem', () {
    test('RiderProceduralGenerator automatycznie tworzy kolarzy z dopasowanym profilem laboratoryjnym', () {
      final sprinter = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
        targetOverallRating: 88,
      );
      final climber = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureClimber,
        targetOverallRating: 88,
      );
      final tt = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        targetOverallRating: 88,
      );

      // Sprinter powinien mieć wyraźnie wyższy VLaMax niż czysty góral i czasowiec
      expect(sprinter.labProfile.vlaMaxMmolLPerSec, greaterThan(climber.labProfile.vlaMaxMmolLPerSec));
      expect(sprinter.labProfile.vlaMaxMmolLPerSec, greaterThan(tt.labProfile.vlaMaxMmolLPerSec));

      // Czasowiec powinien mieć najwyższą sprawność mechaniczną Gross Efficiency
      expect(tt.labProfile.grossEfficiencyPercent, greaterThanOrEqualTo(23.0));

      // Góral powinien mieć wybitny pułap tlenowy VO2max i wysokie W/kg na LT2
      expect(climber.labProfile.vo2MaxMlKgMin, greaterThanOrEqualTo(78.0));
      expect(climber.labProfile.lt2WattsPerKg, greaterThan(4.8));
    });

    test('NutritionAndGlycogenEngine uwzględnia profil laboratoryjny przy spalaniu węglowodanów', () {
      final sprinter = LactateAndLabProfile.benchmarkWorldTourSprinter(
        weightKg: 75.0,
        ftpWatts: 400,
      );
      final tt = LactateAndLabProfile.benchmarkWorldTourTimeTrialist(
        weightKg: 75.0,
        ftpWatts: 400,
      );

      // Przy 320W (80% FTP / tempo): sprinter ze względu na wysoki VLaMax zużywa więcej glikogenu
      final sprinterBurn = NutritionAndGlycogenEngine.calculateCarbBurnRateGramsPerSecond(
        currentPowerWatts: 320,
        ftpWatts: 400,
        labProfile: sprinter,
      );
      final ttBurn = NutritionAndGlycogenEngine.calculateCarbBurnRateGramsPerSecond(
        currentPowerWatts: 320,
        ftpWatts: 400,
        labProfile: tt,
      );

      expect(sprinterBurn, greaterThan(ttBurn));
    });

    test('Serializacja toJson i deserializacja fromJson zachowuje wszystkie parametry', () {
      final original = LactateAndLabProfile.benchmarkWorldTourClimber(
        weightKg: 62.0,
        ftpWatts: 395,
      );

      final json = original.toJson();
      final restored = LactateAndLabProfile.fromJson(json);

      expect(restored, equals(original));
      expect(restored.lt1Watts, original.lt1Watts);
      expect(restored.lt1LactateMmolL, original.lt1LactateMmolL);
      expect(restored.lt2Watts, original.lt2Watts);
      expect(restored.lt2LactateMmolL, original.lt2LactateMmolL);
      expect(restored.vlaMaxMmolLPerSec, original.vlaMaxMmolLPerSec);
      expect(restored.vo2MaxMlKgMin, original.vo2MaxMlKgMin);
      expect(restored.grossEfficiencyPercent, original.grossEfficiencyPercent);
      expect(restored.referenceWeightKg, original.referenceWeightKg);
    });

    test('copyWith poprawnie nadpisuje wybrane właściwości', () {
      final base = LactateAndLabProfile.benchmarkWorldTourClimber(
        weightKg: 60.0,
        ftpWatts: 390,
      );

      final modified = base.copyWith(
        vlaMaxMmolLPerSec: 0.28,
        grossEfficiencyPercent: 24.5,
      );

      expect(modified.vlaMaxMmolLPerSec, 0.28);
      expect(modified.grossEfficiencyPercent, 24.5);
      expect(modified.lt1Watts, base.lt1Watts);
      expect(modified.lt2Watts, base.lt2Watts);
    });
  });
}
