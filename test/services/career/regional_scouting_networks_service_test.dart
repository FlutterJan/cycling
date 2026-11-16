import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/career/regional_scouting_networks_service.dart';

void main() {
  group('RegionalScoutingNetworksService', () {
    test('defines all 8 key cycling regions with valid profiles', () {
      expect(ScoutingRegionId.values.length, 8);
      for (final region in ScoutingRegionId.values) {
        final profile = RegionalScoutingNetworksService.profileFor(region);
        expect(profile.regionId, region);
        expect(profile.specializationWeights, isNotEmpty);
        expect(profile.minWeightKg, lessThan(profile.maxWeightKg));
        expect(profile.baseSetupCostEur, greaterThan(0));
        expect(profile.baseMonthlyUpkeepEur, greaterThan(0));
      }
    });

    test('Colombia/Andes generates climbers strictly under 58 kg', () {
      final rng = math.Random(101);
      for (int i = 0; i < 25; i++) {
        final prospect = RegionalScoutingNetworksService.generateRegionalProspect(
          regionId: ScoutingRegionId.colombiaAndes,
          seasonYear: 2026,
          tier: ScoutingNetworkTier.eliteAcademyPartner,
          scoutSkill: 88,
          random: rng,
        );
        expect(prospect.trueRider.physiology.weightKg, lessThan(58.0));
        expect(
          ['COL', 'ECU'].contains(prospect.nationalityIso),
          isTrue,
        );
      }
    });

    test('Flanders/Belgium generates cobbles & rain specialists', () {
      final rng = math.Random(202);
      int highCobblesCount = 0;
      for (int i = 0; i < 20; i++) {
        final prospect = RegionalScoutingNetworksService.generateRegionalProspect(
          regionId: ScoutingRegionId.flandersBelgium,
          seasonYear: 2026,
          tier: ScoutingNetworkTier.regionalHub,
          scoutSkill: 85,
          random: rng,
        );
        expect(['BEL', 'NED'].contains(prospect.nationalityIso), isTrue);
        if (prospect.trueRider.skills.cobbles >= 65) {
          highCobblesCount++;
        }
        if (prospect.trueRider.specialization ==
            RiderSpecialization.classicCobbles) {
          expect(prospect.trueRider.skills.cobbles, greaterThanOrEqualTo(60));
        }
      }
      expect(highCobblesCount, greaterThan(10));
    });

    test('activation, upgrade, sweep, deactivation and JSON roundtrip', () {
      var state = RegionalScoutingNetworksService.createInitialState();
      expect(state.activeNetworkCount, 1);

      // Activate Colombia
      final act = RegionalScoutingNetworksService.activateRegion(
        state: state,
        regionId: ScoutingRegionId.colombiaAndes,
        availableBudgetEur: 500000,
        scoutSkill: 84,
      );
      expect(act.success, isTrue);
      expect(act.costEur, 75000);
      state = act.state;
      expect(state.activeNetworkCount, 2);

      // Insufficient budget fails gracefully
      final failUpgrade = RegionalScoutingNetworksService.upgradeRegionTier(
        state: state,
        regionId: ScoutingRegionId.colombiaAndes,
        availableBudgetEur: 1000,
      );
      expect(failUpgrade.success, isFalse);

      // Upgrade Colombia to Regional Hub
      final okUpgrade = RegionalScoutingNetworksService.upgradeRegionTier(
        state: state,
        regionId: ScoutingRegionId.colombiaAndes,
        availableBudgetEur: 500000,
      );
      expect(okUpgrade.success, isTrue);
      state = okUpgrade.state;
      expect(
        state.nodeFor(ScoutingRegionId.colombiaAndes).tier,
        ScoutingNetworkTier.regionalHub,
      );

      // Run sweep
      final sweep = RegionalScoutingNetworksService.runRegionalScoutingSweep(
        state: state,
        regionId: ScoutingRegionId.colombiaAndes,
        seasonYear: 2026,
        currentDate: DateTime(2026, 3, 15),
        availableBudgetEur: 500000,
        random: math.Random(42),
      );
      expect(sweep.success, isTrue);
      state = sweep.state;
      expect(state.regionalProspectPool.length, 3);
      expect(state.lastDiscoveryResult?.prospects.length, 3);

      // JSON roundtrip
      final decoded = RegionalScoutingNetworkState.fromJson(state.toJson());
      expect(decoded.activeNetworkCount, state.activeNetworkCount);
      expect(decoded.regionalProspectPool.length, 3);

      // Deactivate
      final deact = RegionalScoutingNetworksService.deactivateRegion(
        state: state,
        regionId: ScoutingRegionId.colombiaAndes,
      );
      expect(deact.success, isTrue);
      expect(deact.state.activeNetworkCount, 1);
    });
  });

  group('RegionalScoutingNetworksPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          var state = RegionalScoutingNetworksService.createInitialState();
          final sweep = RegionalScoutingNetworksService.runRegionalScoutingSweep(
            state: state,
            regionId: ScoutingRegionId.flandersBelgium,
            seasonYear: 2026,
            currentDate: DateTime(2026, 4, 1),
            random: math.Random(7),
          );
          state = sweep.state;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RegionalScoutingNetworksPanel(
                  state: state,
                  availableBudgetEur: 1250000,
                  onActivateRegion: (_) {},
                  onDeactivateRegion: (_) {},
                  onUpgradeRegion: (_) {},
                  onSweepRegion: (_) {},
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('REGIONALNE SIATKI SKAUTINGOWE'), findsOneWidget);
          expect(find.text('Flandria'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
