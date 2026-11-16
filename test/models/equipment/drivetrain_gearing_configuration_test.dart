import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/equipment/drivetrain_gearing_configuration.dart';

void main() {
  group('CranksetChainringOption', () {
    test('contains all 5 required chainring configurations', () {
      expect(CranksetChainringOption.values.length, 5);
      expect(
        CranksetChainringOption.values.map((e) => e.label),
        containsAll([
          '50/34T Compact',
          '52/36T Semi-Compact',
          '54/40T Pro Standard',
          '56/44T Fast Flat',
          '58T 1x Aero Single',
        ]),
      );
    });

    test('58T 1x Aero Single has no inner chainring and saves weight & aero', () {
      const aero1x = CranksetChainringOption.aeroSingle58_1x;
      expect(aero1x.isSingleRing1x, isTrue);
      expect(aero1x.innerTeeth, isNull);
      expect(aero1x.smallestTeeth, 58);
      expect(aero1x.chainringGapTeeth, 0);
      expect(aero1x.weightDeltaGrams, lessThan(0));
      expect(aero1x.aeroCdaModifier, lessThan(0));
    });
  });

  group('Cassette12SpeedOption', () {
    test('all cassettes have exactly 12 strictly increasing cogs', () {
      expect(Cassette12SpeedOption.values.length, 4);
      for (final cassette in Cassette12SpeedOption.values) {
        expect(cassette.speedCount, 12);
        expect(cassette.cogs.length, 12);
        for (var i = 1; i < cassette.cogs.length; i++) {
          expect(cassette.cogs[i], greaterThan(cassette.cogs[i - 1]));
        }
      }
    });

    test('10-36T Gravel/Steep requires XDR freehub and has 360% range', () {
      const gravel = Cassette12SpeedOption.gravelSteep10_36;
      expect(gravel.label, '10-36T Gravel/Steep');
      expect(gravel.smallestCog, 10);
      expect(gravel.largestCog, 36);
      expect(gravel.requiresXdrFreehub, isTrue);
      expect(gravel.rangePercent, closeTo(360.0, 0.1));
    });

    test('11-28T has the most 1-tooth jumps for cadence smoothness', () {
      expect(
        Cassette12SpeedOption.sprint11_28.oneToothJumpsCount,
        greaterThanOrEqualTo(
          Cassette12SpeedOption.climbing11_34.oneToothJumpsCount,
        ),
      );
    });
  });

  group('DrivetrainGearingConfiguration', () {
    test('alpineClimber preset provides 1:1 easiest gear ratio', () {
      final climber = DrivetrainGearingConfiguration.alpineClimber();
      expect(climber.chainring, CranksetChainringOption.compact50_34);
      expect(climber.cassette, Cassette12SpeedOption.climbing11_34);
      expect(climber.easiestGearRatio, closeTo(1.0, 0.001));
      expect(climber.isSuitableForSteepMountains, isTrue);
      expect(climber.isSpinOutRiskOnDescent, isTrue);
      expect(climber.frontChainrings, [50, 34]);
    });

    test('timeTrialAero preset provides 1x aero setup and high max speed', () {
      final tt = DrivetrainGearingConfiguration.timeTrialAero();
      expect(tt.chainring, CranksetChainringOption.aeroSingle58_1x);
      expect(tt.cassette, Cassette12SpeedOption.sprint11_28);
      expect(tt.frontChainrings, [58]);
      expect(tt.hardestGearRatio, closeTo(58 / 11, 0.001));
      expect(tt.maxSpeedKmhAt110Rpm, greaterThan(70.0));
      expect(tt.isSuitableForSteepMountains, isFalse);
      expect(tt.aeroCdaModifier, lessThan(0.0));
      expect(tt.drivetrainEfficiency, greaterThan(0.98));
    });

    test('speed and cadence calculations are inverse of each other', () {
      final config = DrivetrainGearingConfiguration.proPelotonStandard();
      final speed = config.speedKmhAtCadence(
        ratio: config.hardestGearRatio,
        cadenceRpm: 95.0,
      );
      final cadence = config.requiredCadenceRpm(
        ratio: config.hardestGearRatio,
        speedKmh: speed,
      );
      expect(cadence, closeTo(95.0, 0.0001));
    });

    test('findOptimalGear avoids cross-chaining when clean gear is close', () {
      final config = DrivetrainGearingConfiguration.allRounder();
      final gear = config.findOptimalGear(
        targetSpeedKmh: 42.0,
        preferredCadenceRpm: 90.0,
      );
      expect(gear.cadenceAtTargetSpeedRpm, inInclusiveRange(75.0, 105.0));
      expect(gear.isCrossChained, isFalse);
    });

    test('mechanicalWarnings flags XDR, derailleur capacity, and 1x climbs', () {
      final gravel = DrivetrainGearingConfiguration.gravelSteep();
      expect(gravel.exceedsStandardRoadDerailleurCapacity, isTrue);
      expect(
        gravel.mechanicalWarnings.any((w) => w.contains('SRAM XDR')),
        isTrue,
      );
      expect(
        gravel.mechanicalWarnings.any((w) => w.contains('Gravel/XPLR')),
        isTrue,
      );

      final tt = DrivetrainGearingConfiguration.timeTrialAero();
      expect(
        tt.mechanicalWarnings.any((w) => w.contains('podjazdach >7%')),
        isTrue,
      );
    });

    test('toJson and fromJson round-trip preserves all fields', () {
      const original = DrivetrainGearingConfiguration(
        chainring: CranksetChainringOption.fastFlat56_44,
        cassette: Cassette12SpeedOption.gravelSteep10_36,
        wheelCircumferenceMm: 2150.0,
        crankArmLengthMm: 170.0,
        waxedChain: false,
        oversizedPulleyCage: true,
      );

      final decoded =
          DrivetrainGearingConfiguration.fromJson(original.toJson());
      expect(decoded, original);
      expect(decoded.hashCode, original.hashCode);
    });

    test('copyWith updates only specified fields', () {
      final base = DrivetrainGearingConfiguration.allRounder();
      final updated = base.copyWith(
        chainring: CranksetChainringOption.proStandard54_40,
        oversizedPulleyCage: true,
      );
      expect(updated.chainring, CranksetChainringOption.proStandard54_40);
      expect(updated.cassette, base.cassette);
      expect(updated.oversizedPulleyCage, isTrue);
    });
  });
}
