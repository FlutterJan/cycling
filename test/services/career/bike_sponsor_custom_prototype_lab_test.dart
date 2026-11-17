import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/services/career/bike_sponsor_custom_prototype_lab.dart';

void main() {
  group('BikeSponsorCustomPrototypeLabService', () {
    const service = BikeSponsorCustomPrototypeLabService();

    const testDeal = BikeManufacturerDeal(
      manufacturerId: 'cervelo_test',
      manufacturerName: 'Cervélo Skunkworks',
      prestigeLevel: 5,
      annualCashContributionEur: 1200000,
      freeBikesQuota: 90,
      researchAndDevelopmentLevel: 92,
      suppliedFrameIds: ['s5_aero'],
      suppliedWheelsetIds: ['reserve_63'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 5,
    );

    test('createInitialState populates prototypes and manufacturer metadata', () {
      final state = service.createInitialState(
        deal: testDeal,
        initialBudgetEur: 500000,
        labSecurityLevel: 3,
      );

      expect(state.activeManufacturerName, 'Cervélo Skunkworks');
      expect(state.manufacturerRndLevel, 92);
      expect(state.labSecurityLevel, 3);
      expect(state.availableRndBudgetEur, 500000);
      expect(state.prototypes.length, 2);
      expect(state.selectedPrototype, isNotNull);
    });

    test('commissionPrototype -> windTunnel -> fieldTest -> homologate -> deploy', () {
      var state = service.createInitialState(
        deal: testDeal,
        initialBudgetEur: 900000,
        labSecurityLevel: 4,
      );

      state = service.commissionPrototype(
        state: state,
        codename: 'Project Valkyrie-TT',
        category: SkunkworksPrototypeCategory.aeroTtFrame,
        targetRaceTier: SkunkworksTargetRaceTier.worldChampionshipItt,
        targetRaceName: 'MŚ ITT Zurich',
        leadRiderId: 'r1',
        leadRiderName: 'Janek Lider',
      );

      expect(state.lastErrorMessage, isNull);
      final created = state.prototypes.last;
      expect(created.codename, 'Project Valkyrie-TT');
      expect(created.phase, SkunkworksPrototypePhase.cadConcept);

      // Run 3 wind tunnel sessions + 1 field test to reach >= 85%
      state = service.runWindTunnelSession(state: state, prototypeId: created.id);
      state = service.runWindTunnelSession(state: state, prototypeId: created.id);
      state = service.runWindTunnelSession(state: state, prototypeId: created.id);
      state = service.runSecretFieldTest(state: state, prototypeId: created.id);

      var updated = state.prototypes.firstWhere((p) => p.id == created.id);
      expect(updated.developmentProgress, greaterThanOrEqualTo(0.85));

      state = service.submitUciHomologation(state: state, prototypeId: created.id);
      updated = state.prototypes.firstWhere((p) => p.id == created.id);
      expect(updated.phase, SkunkworksPrototypePhase.raceReadyHomologated);
      expect(updated.isUciCompliant, isTrue);

      state = service.deployForKeyRace(state: state, prototypeId: created.id);
      updated = state.prototypes.firstWhere((p) => p.id == created.id);
      expect(updated.phase, SkunkworksPrototypePhase.deployedInRace);
      expect(updated.isPrototypeActiveForRace, isTrue);
      expect(state.lastDeploymentOutcome, isNotNull);
      expect(state.completedDeploymentsCount, 1);
    });

    test('rejects commission when budget is insufficient or codename empty', () {
      final lowBudget = service.createInitialState(initialBudgetEur: 10000);

      final emptyName = service.commissionPrototype(
        state: lowBudget,
        codename: '   ',
        category: SkunkworksPrototypeCategory.ceramicDrivetrainWax,
        targetRaceTier: SkunkworksTargetRaceTier.monumentClassic,
        targetRaceName: 'Flandria',
        leadRiderId: 'r1',
        leadRiderName: 'Lider',
      );
      expect(emptyName.lastErrorMessage, isNotNull);

      final noMoney = service.commissionPrototype(
        state: lowBudget,
        codename: 'Zero-Friction',
        category: SkunkworksPrototypeCategory.ceramicDrivetrainWax,
        targetRaceTier: SkunkworksTargetRaceTier.monumentClassic,
        targetRaceName: 'Flandria',
        leadRiderId: 'r1',
        leadRiderName: 'Lider',
      );
      expect(noMoney.lastErrorMessage, contains('Niewystarczający budżet'));
    });

    test('upgradeLabSecurity caps at level 5 and scrapPrototype archives', () {
      var state = service.createInitialState(
        initialBudgetEur: 2000000,
        labSecurityLevel: 4,
      );
      state = service.upgradeLabSecurity(state);
      expect(state.labSecurityLevel, 5);
      expect(state.lastErrorMessage, isNull);

      state = service.upgradeLabSecurity(state);
      expect(state.labSecurityLevel, 5);
      expect(state.lastErrorMessage, isNotNull);

      final targetId = state.prototypes.first.id;
      state = service.scrapPrototype(state: state, prototypeId: targetId);
      final scrapped = state.prototypes.firstWhere((p) => p.id == targetId);
      expect(scrapped.phase, SkunkworksPrototypePhase.scrapped);
    });

    test('SkunkworksPrototypeSpec JSON serialization roundtrip', () {
      final state = service.createInitialState(deal: testDeal);
      final original = state.prototypes.first;
      final restored = SkunkworksPrototypeSpec.fromJson(original.toJson());
      expect(restored, equals(original));
      expect(restored.cdaDeltaPercent, original.cdaDeltaPercent);
      expect(restored.targetRaceName, original.targetRaceName);
    });
  });

  group('SkunkworksLabPanel responsive widget tests', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SkunkworksLabPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('SKUNKWORKS LAB — TAJNE R&D'), findsOneWidget);
      expect(find.text('Project Kestrel-X'), findsWidgets);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('SKUNKWORKS LAB — TAJNE R&D'), findsOneWidget);
      expect(find.text('Dziennik Telemetrii Lab'), findsOneWidget);
    });

    testWidgets('renders cleanly at 1600x900 desktop and runs wind tunnel action', (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('SKUNKWORKS LAB — TAJNE R&D'), findsOneWidget);

      await tester.tap(find.text('Tunel Aero (+10h)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('28/40 h'), findsOneWidget);
    });
  });
}
