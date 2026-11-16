// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/cadence_and_gearing_efficiency_solver.dart';
import 'package:pro_peloton_manager/models/equipment/drivetrain_gearing_configuration.dart';

void main() {
  const solver = CadenceAndGearingEfficiencySolver();

  group('CadenceAndGearingEfficiencySolver — 54/40T vs 50/34T na nachyleniu 14%', () {
    test('wylicza dokładnie przełożenie i kadencję dla 54/40T oraz 50/34T na 14%', () {
      const speedKmh = 10.5;
      const speedMs = speedKmh / 3.6;

      final pro5440 = DrivetrainGearingConfiguration.proPelotonStandard();
      final compact5034 = DrivetrainGearingConfiguration.alpineClimber();

      final result5440 = solver.solve(
        CadenceAndGearingInput(
          drivetrain: pro5440,
          speedMs: speedMs,
          powerWatts: 380.0,
          gradePercent: 14.0,
        ),
      );

      final result5034 = solver.solve(
        CadenceAndGearingInput(
          drivetrain: compact5034,
          speedMs: speedMs,
          powerWatts: 380.0,
          gradePercent: 14.0,
        ),
      );

      // 54/40T + 11-30T na 14% przy 10.5 km/h automatycznie wrzuca najlżejsze 40x30.
      expect(result5440.frontTeeth, 40);
      expect(result5440.rearTeeth, 30);
      expect(result5440.gearRatio, closeTo(40 / 30, 1e-6));

      const expectedCadence5440 =
          (speedMs * 60.0) / (2.136 * (40.0 / 30.0));
      expect(result5440.cadenceRpm, closeTo(expectedCadence5440, 1e-4));
      expect(result5440.cadenceRpm, closeTo(61.4466, 1e-3));

      // 50/34T + 11-34T na 14% przy 10.5 km/h wrzuca najlżejsze 34x34 (1.00).
      expect(result5034.frontTeeth, 34);
      expect(result5034.rearTeeth, 34);
      expect(result5034.gearRatio, closeTo(1.0, 1e-6));

      const expectedCadence5034 = (speedMs * 60.0) / (2.136 * 1.0);
      expect(result5034.cadenceRpm, closeTo(expectedCadence5034, 1e-4));
      expect(result5034.cadenceRpm, closeTo(81.9288, 1e-3));

      // Tarcza 50/34T daje zauważalnie wyższą kadencję i niższy moment na korbie.
      expect(result5034.cadenceRpm, greaterThan(result5440.cadenceRpm + 15.0));
      expect(result5034.crankTorqueNm, lessThan(result5440.crankTorqueNm));
      expect(result5034.zone, CadenceEfficiencyZone.optimal);
      expect(result5440.zone, CadenceEfficiencyZone.lowTorque);
    });

    test('porównanie 54/40T i 50/34T na tej samej kasecie 11-28T przy 14% i 10.5 km/h', () {
      const speedMs = 10.5 / 3.6;

      const drivetrain5440 = DrivetrainGearingConfiguration(
        chainring: CranksetChainringOption.proStandard54_40,
        cassette: Cassette12SpeedOption.sprint11_28,
      );
      const drivetrain5034 = DrivetrainGearingConfiguration(
        chainring: CranksetChainringOption.compact50_34,
        cassette: Cassette12SpeedOption.sprint11_28,
      );

      final res5440 = solver.solve(
        const CadenceAndGearingInput(
          drivetrain: drivetrain5440,
          speedMs: speedMs,
          powerWatts: 370.0,
          gradePercent: 14.0,
        ),
      );
      final res5034 = solver.solve(
        const CadenceAndGearingInput(
          drivetrain: drivetrain5034,
          speedMs: speedMs,
          powerWatts: 370.0,
          gradePercent: 14.0,
        ),
      );

      // 40x28 spada poniżej 60 RPM (mielenie), podczas gdy 34x28 utrzymuje > 67 RPM.
      expect(res5440.frontTeeth, 40);
      expect(res5440.rearTeeth, 28);
      expect(res5440.cadenceRpm, closeTo(57.3502, 1e-3));
      expect(res5440.isGrinding, isTrue);
      expect(res5440.zone, CadenceEfficiencyZone.grinding);

      expect(res5034.frontTeeth, 34);
      expect(res5034.rearTeeth, 28);
      expect(res5034.cadenceRpm, closeTo(67.4708, 1e-3));
      expect(res5034.isGrinding, isFalse);
      expect(res5034.zone, CadenceEfficiencyZone.lowTorque);
    });

    test('ręcznie wymuszona duża tarcza 54T i 50T na 14% poprawnie obniża kadencję', () {
      const speedMs = 12.0 / 3.6;
      final drivetrain5440 = DrivetrainGearingConfiguration.proPelotonStandard();
      final drivetrain5034 = DrivetrainGearingConfiguration.alpineClimber();

      final forced54 = solver.solve(
        CadenceAndGearingInput(
          drivetrain: drivetrain5440,
          speedMs: speedMs,
          powerWatts: 400.0,
          gradePercent: 14.0,
          forcedFrontTeeth: 54,
          forcedRearTeeth: 24,
        ),
      );
      final forced50 = solver.solve(
        CadenceAndGearingInput(
          drivetrain: drivetrain5034,
          speedMs: speedMs,
          powerWatts: 400.0,
          gradePercent: 14.0,
          forcedFrontTeeth: 50,
          forcedRearTeeth: 24,
        ),
      );

      expect(forced54.gearLabel, '54x24');
      expect(forced50.gearLabel, '50x24');
      expect(forced54.cadenceRpm, closeTo((speedMs * 60.0) / (2.136 * (54 / 24)), 1e-4));
      expect(forced50.cadenceRpm, closeTo((speedMs * 60.0) / (2.136 * (50 / 24)), 1e-4));
      expect(forced54.isGrinding, isTrue);
      expect(forced50.isGrinding, isTrue);
    });
  });

  group('CadenceAndGearingEfficiencySolver — kara energetyczna poniżej 60 RPM', () {
    test('nalicza +18% kosztu glikogenu i podwyższone zmęczenie Typ II poniżej 60 RPM', () {
      final drivetrain5440 = DrivetrainGearingConfiguration.proPelotonStandard();
      final ratio4030 = CadenceAndGearingEfficiencySolver.calculateGearRatio(
        frontTeeth: 40,
        rearTeeth: 30,
      );

      final speedBelow60 = CadenceAndGearingEfficiencySolver.calculateSpeedMs(
        cadenceRpm: 55.0,
        wheelCircumferenceMeters: 2.136,
        gearRatio: ratio4030,
      );
      final speedAt60 = CadenceAndGearingEfficiencySolver.calculateSpeedMs(
        cadenceRpm: 60.0,
        wheelCircumferenceMeters: 2.136,
        gearRatio: ratio4030,
      );
      final speedOptimal = CadenceAndGearingEfficiencySolver.calculateSpeedMs(
        cadenceRpm: 85.0,
        wheelCircumferenceMeters: 2.136,
        gearRatio: ratio4030,
      );

      final grindingResult = solver.solve(
        CadenceAndGearingInput(
          drivetrain: drivetrain5440,
          speedMs: speedBelow60,
          powerWatts: 380.0,
          gradePercent: 14.0,
          deltaTimeSeconds: 10.0,
          forcedFrontTeeth: 40,
          forcedRearTeeth: 30,
        ),
      );

      final thresholdResult = solver.solve(
        CadenceAndGearingInput(
          drivetrain: drivetrain5440,
          speedMs: speedAt60,
          powerWatts: 380.0,
          gradePercent: 14.0,
          deltaTimeSeconds: 10.0,
          forcedFrontTeeth: 40,
          forcedRearTeeth: 30,
        ),
      );

      final optimalResult = solver.solve(
        CadenceAndGearingInput(
          drivetrain: drivetrain5440,
          speedMs: speedOptimal,
          powerWatts: 380.0,
          gradePercent: 14.0,
          deltaTimeSeconds: 10.0,
          forcedFrontTeeth: 40,
          forcedRearTeeth: 30,
        ),
      );

      // Poniżej 60 RPM aktywuje się pełna kara +18% glikogenu.
      expect(grindingResult.cadenceRpm, closeTo(55.0, 1e-4));
      expect(grindingResult.isGrinding, isTrue);
      expect(grindingResult.zone, CadenceEfficiencyZone.grinding);
      expect(grindingResult.glycogenCostMultiplier, closeTo(1.18, 1e-6));
      expect(grindingResult.glycogenPenaltyPercent, closeTo(18.0, 1e-4));
      expect(grindingResult.fastTwitchFatigueMultiplier, greaterThanOrEqualTo(1.45));
      expect(grindingResult.fastTwitchFatigueDelta, greaterThan(0.0));

      // Dokładnie przy 60.0 RPM brak jeszcze statusu mielenia i +18% kary.
      expect(thresholdResult.cadenceRpm, closeTo(60.0, 1e-4));
      expect(thresholdResult.isGrinding, isFalse);
      expect(thresholdResult.zone, CadenceEfficiencyZone.lowTorque);
      expect(thresholdResult.glycogenCostMultiplier, closeTo(1.06, 1e-6));
      expect(
        grindingResult.fastTwitchFatigueDelta,
        greaterThan(thresholdResult.fastTwitchFatigueDelta),
      );

      // W strefie optymalnej (85 RPM) koszt glikogenu = 1.00 i brak przyrostu zmęczenia Typ II.
      expect(optimalResult.isGrinding, isFalse);
      expect(optimalResult.zone, CadenceEfficiencyZone.optimal);
      expect(optimalResult.glycogenCostMultiplier, closeTo(1.0, 1e-6));
      expect(optimalResult.fastTwitchFatigueMultiplier, closeTo(1.0, 1e-6));
      expect(optimalResult.fastTwitchFatigueDelta, closeTo(0.0, 1e-6));
    });

    test('skrajnie niska kadencja (<45 RPM) dodatkowo obniża biomechaniczny współczynnik mocy', () {
      final drivetrain = DrivetrainGearingConfiguration.proPelotonStandard();
      const ratio4030 = 40.0 / 30.0;
      final verySlowSpeed = CadenceAndGearingEfficiencySolver.calculateSpeedMs(
        cadenceRpm: 35.0,
        wheelCircumferenceMeters: 2.136,
        gearRatio: ratio4030,
      );

      final extremeGrind = solver.solve(
        CadenceAndGearingInput(
          drivetrain: drivetrain,
          speedMs: verySlowSpeed,
          powerWatts: 360.0,
          gradePercent: 14.0,
          deltaTimeSeconds: 5.0,
          forcedFrontTeeth: 40,
          forcedRearTeeth: 30,
        ),
      );

      expect(extremeGrind.cadenceRpm, closeTo(35.0, 1e-4));
      expect(extremeGrind.isGrinding, isTrue);
      expect(extremeGrind.glycogenCostMultiplier, closeTo(1.18, 1e-6));
      expect(extremeGrind.biomechanicalPowerFactor, lessThan(0.94));
      expect(extremeGrind.crankTorqueNm, greaterThan(90.0));
      expect(extremeGrind.averagePedalForceNewtons, greaterThan(500.0));
    });

    test('jazda bez pedałowania (coasting) nie nalicza kary energetycznej', () {
      final drivetrain = DrivetrainGearingConfiguration.proPelotonStandard();
      final coasting = solver.solve(
        CadenceAndGearingInput(
          drivetrain: drivetrain,
          speedMs: 12.0,
          powerWatts: 0.0,
          gradePercent: -6.0,
          deltaTimeSeconds: 10.0,
        ),
      );

      expect(coasting.zone, CadenceEfficiencyZone.coasting);
      expect(coasting.isGrinding, isFalse);
      expect(coasting.cadenceRpm, 0.0);
      expect(coasting.glycogenCostMultiplier, 1.0);
      expect(coasting.fastTwitchFatigueDelta, 0.0);
    });
  });
}
