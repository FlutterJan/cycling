import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/career/global_satellite_training_centers_service.dart';
import 'package:pro_peloton_manager/services/career/manager_skill_tree_perks_service.dart';

void main() {
  group('ManagerSkillTreeCatalog & ManagerSkillTreePerksService', () {
    test('catalog contains 20 valid nodes across 4 branches with valid prerequisites', () {
      expect(ManagerSkillTreeCatalog.nodes.length, 20);

      for (final branch in ManagerSkillBranch.values) {
        final branchNodes = ManagerSkillTreeCatalog.byBranch(branch);
        expect(branchNodes.length, 5);
        expect(
          branchNodes.where((n) => n.tier == ManagerPerkTier.tier1Foundation).length,
          1,
        );
        expect(
          branchNodes.where((n) => n.tier == ManagerPerkTier.tier2Specialist).length,
          2,
        );
        expect(
          branchNodes.where((n) => n.tier == ManagerPerkTier.tier3Mastery).length,
          1,
        );
        expect(
          branchNodes.where((n) => n.tier == ManagerPerkTier.tier4Signature).length,
          1,
        );
      }

      for (final node in ManagerSkillTreeCatalog.nodes) {
        expect(ManagerSkillTreeCatalog.byId(node.id), isNotNull);
        for (final prereqId in node.prerequisiteNodeIds) {
          expect(
            ManagerSkillTreeCatalog.byId(prereqId),
            isNotNull,
            reason: 'Missing prerequisite $prereqId for ${node.id}',
          );
        }
      }
    });

    test('awardExperience handles level-ups, bonus skill points every 5th level, and max level cap', () {
      var state = ManagerSkillTreeState.initial();
      expect(state.managerLevel, 1);
      expect(state.availableSkillPoints, 2);

      // Non-positive XP should be ignored
      final unchanged = ManagerSkillTreePerksService.awardExperience(
        state,
        xp: 0,
        source: ManagerXpSource.manualGrant,
        title: 'Brak XP',
      );
      expect(unchanged.totalXpEarned, 0);
      expect(unchanged.recentXpLog, isEmpty);

      // Level 1->2: 1000, 2->3: 1350, 3->4: 1700, 4->5: 2050 => total 6100 XP
      state = ManagerSkillTreePerksService.awardExperience(
        state,
        xp: 6200,
        source: ManagerXpSource.grandTourStage,
        title: 'Zwycięstwo w Alpach',
        timestamp: DateTime(2026, 7, 14),
      );
      expect(state.managerLevel, 5);
      // 2 initial + 1 (lvl2) + 1 (lvl3) + 1 (lvl4) + 2 (lvl5 bonus) = 7 SP
      expect(state.availableSkillPoints, 7);
      expect(state.currentXp, 100);
      expect(state.totalXpEarned, 6200);
      expect(state.recentXpLog.length, 1);

      // Huge XP should cap at maxManagerLevel (50)
      state = ManagerSkillTreePerksService.awardExperience(
        state,
        xp: 5000000,
        source: ManagerXpSource.seasonCompletion,
        title: 'Legenda dekady',
        timestamp: DateTime(2026, 10, 30),
      );
      expect(state.managerLevel, ManagerSkillTreePerksService.maxManagerLevel);
      expect(
        state.currentXp,
        lessThanOrEqualTo(
          ManagerSkillTreePerksService.xpRequiredForLevel(
            ManagerSkillTreePerksService.maxManagerLevel,
          ),
        ),
      );
    });

    test('unlockSkillRank enforces prerequisites, manager level, maxRank, and available SP', () {
      var state = ManagerSkillTreeState.initial();

      // Unknown node fails
      final unknownResult = ManagerSkillTreePerksService.unlockSkillRank(
        state,
        'non_existent_node',
      );
      expect(unknownResult.success, isFalse);

      // Tier 2 node is locked at level 1 without prerequisite
      final tier2Node = ManagerSkillTreeCatalog.byId('tac_crosswind_echelons')!;
      expect(
        ManagerSkillTreePerksService.getNodeStatus(state, tier2Node),
        ManagerSkillNodeState.locked,
      );
      expect(
        ManagerSkillTreePerksService.canUnlockNode(state, tier2Node.id),
        isFalse,
      );
      final lockedResult = ManagerSkillTreePerksService.unlockSkillRank(
        state,
        tier2Node.id,
      );
      expect(lockedResult.success, isFalse);

      // Unlock Tier 1 node (maxRank = 3, cost = 1)
      final tier1Node = ManagerSkillTreeCatalog.byId('tac_radio_discipline')!;
      expect(
        ManagerSkillTreePerksService.getNodeStatus(state, tier1Node),
        ManagerSkillNodeState.available,
      );

      final r1 = ManagerSkillTreePerksService.unlockSkillRank(state, tier1Node.id);
      expect(r1.success, isTrue);
      expect(r1.newRank, 1);
      state = r1.state;
      expect(
        ManagerSkillTreePerksService.getNodeStatus(state, tier1Node),
        ManagerSkillNodeState.partiallyUnlocked,
      );

      final r2 = ManagerSkillTreePerksService.unlockSkillRank(state, tier1Node.id);
      expect(r2.success, isTrue);
      state = r2.state;

      // Out of SP now (initial had 2 SP)
      expect(state.availableSkillPoints, 0);
      final noSpResult = ManagerSkillTreePerksService.unlockSkillRank(
        state,
        tier1Node.id,
      );
      expect(noSpResult.success, isFalse);
      expect(noSpResult.message, contains('Brak punktów'));

      // Grant XP to reach level 3 and get more SP, then max out Tier 1
      state = ManagerSkillTreePerksService.awardExperience(
        state,
        xp: 2500,
        source: ManagerXpSource.raceWin,
        title: 'Klasyk',
      );
      expect(state.managerLevel, greaterThanOrEqualTo(3));
      final r3 = ManagerSkillTreePerksService.unlockSkillRank(state, tier1Node.id);
      expect(r3.success, isTrue);
      state = r3.state;
      expect(
        ManagerSkillTreePerksService.getNodeStatus(state, tier1Node),
        ManagerSkillNodeState.maxed,
      );

      // Tier 2 node is now available
      expect(
        ManagerSkillTreePerksService.getNodeStatus(state, tier2Node),
        ManagerSkillNodeState.available,
      );
    });

    test('computeAggregateEffects, signature perks, recommendedNextNodes, and refundAllSkills work accurately', () {
      var state = ManagerSkillTreeState.initial();
      // Reach level 12 with plenty of SP
      state = ManagerSkillTreePerksService.awardExperience(
        state,
        xp: 60000,
        source: ManagerXpSource.grandTourStage,
        title: 'Tryplet GT',
      );
      expect(state.managerLevel, greaterThanOrEqualTo(10));

      final initialSp = state.availableSkillPoints;

      // Unlock full Tactics branch to Tier 4 Signature
      for (final nodeId in [
        'tac_radio_discipline',
        'tac_crosswind_echelons',
        'tac_sprint_leadout_sync',
        'tac_breakaway_calculus',
        'tac_signature_maestro',
      ]) {
        final res = ManagerSkillTreePerksService.unlockSkillRank(state, nodeId);
        expect(res.success, isTrue, reason: 'Failed unlocking $nodeId: ${res.message}');
        state = res.state;
      }

      final effects = state.aggregateEffects;
      // 2.5 (radio) + 1.5 (breakaway) + 6.0 (signature) = 10.0
      expect(effects.raceTacticalExecutionBonusPct, closeTo(10.0, 0.001));
      expect(effects.echelonPositioningBonusPct, closeTo(8.0, 0.001));
      expect(effects.sprintLeadoutTimingBonusPct, closeTo(7.5, 0.001));
      expect(effects.breakawaySuccessRateBonusPct, closeTo(4.5, 0.001));
      expect(effects.moraleStabilityBonus, closeTo(5.0, 0.001));
      expect(effects.activeSignaturePerks, contains('Szachista Peletonu'));

      // Recommended next nodes capped at 3
      final recommended = ManagerSkillTreePerksService.recommendedNextNodes(state);
      expect(recommended.length, lessThanOrEqualTo(3));
      expect(recommended, isNotEmpty);

      // Respec refunds all spent SP and resets effects
      final refunded = ManagerSkillTreePerksService.refundAllSkills(state);
      expect(refunded.availableSkillPoints, initialSp);
      expect(refunded.spentSkillPoints, 0);
      expect(refunded.unlockedRanks, isEmpty);
      expect(refunded.respecCount, 1);
      expect(refunded.aggregateEffects.raceTacticalExecutionBonusPct, 0.0);
      expect(refunded.aggregateEffects.activeSignaturePerks, isEmpty);

      // Second respec on empty tree is a no-op
      final secondRefund = ManagerSkillTreePerksService.refundAllSkills(refunded);
      expect(secondRefund.respecCount, 1);
    });

    test('ManagerSkillTreeState JSON round-trip and Riverpod notifier integration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(managerSkillTreeProvider.notifier);
      notifier.grantXp(
        xp: 1200,
        source: ManagerXpSource.monumentTop5,
        title: 'Mediolan-San Remo',
      );
      notifier.selectBranch(ManagerSkillBranch.physiologyAndTraining);
      final unlock = notifier.unlockNode('phy_periodization_basics');
      expect(unlock.success, isTrue);

      final passiveEffects = container.read(managerPassivePerksProvider);
      expect(passiveEffects.trainingEffectivenessBonusPct, greaterThan(0.0));

      final currentState = container.read(managerSkillTreeProvider);
      final restored = ManagerSkillTreeState.fromJson(currentState.toJson());
      expect(restored.managerLevel, currentState.managerLevel);
      expect(restored.totalXpEarned, currentState.totalXpEarned);
      expect(restored.availableSkillPoints, currentState.availableSkillPoints);
      expect(restored.spentSkillPoints, currentState.spentSkillPoints);
      expect(restored.unlockedRanks, currentState.unlockedRanks);
      expect(restored.selectedBranchFilter, ManagerSkillBranch.physiologyAndTraining);
      expect(restored.recentXpLog.length, currentState.recentXpLog.length);

      // Unknown node keys in JSON are safely filtered out
      final corruptedJson = Map<String, dynamic>.from(currentState.toJson())
        ..['unlockedRanks'] = <String, dynamic>{
          'phy_periodization_basics': 1,
          'invalid_node_xyz': 5,
        }
        ..['managerLevel'] = 999;
      final sanitized = ManagerSkillTreeState.fromJson(corruptedJson);
      expect(sanitized.managerLevel, 50);
      expect(sanitized.unlockedRanks.containsKey('invalid_node_xyz'), isFalse);
      expect(sanitized.rankOf('phy_periodization_basics'), 1);

      notifier.respecTree();
      expect(container.read(managerPassivePerksProvider).trainingEffectivenessBonusPct, 0.0);
    });
  });

  group('GlobalSatelliteTrainingCentersService & Notifier', () {
    const service = GlobalSatelliteTrainingCentersService();
    final baseDate = DateTime(2026, 2, 1);

    test('createInitialNetwork creates 4 regions with Sierra Nevada unlocked at Tier 1', () {
      final network = service.createInitialNetwork(currentDate: baseDate);
      expect(network.length, 4);

      for (final region in SatelliteAcademyRegionId.values) {
        expect(network[region], isNotNull);
      }

      final sierra = network[SatelliteAcademyRegionId.sierraNevadaGranada]!;
      expect(sierra.isBuilt, isTrue);
      expect(sierra.tier, 1);
      expect(sierra.status, SatelliteAcademyStatus.operational);
      expect(sierra.prospects.length, 1);

      final colombia = network[SatelliteAcademyRegionId.colombiaBoyaca]!;
      expect(colombia.isBuilt, isFalse);
      expect(colombia.tier, 0);
      expect(colombia.status, SatelliteAcademyStatus.locked);
      expect(colombia.prospects, isEmpty);
    });

    test('unlockOrUpgradeAcademy handles budget checks, tier progression, and Tier 4 cap', () {
      final network = service.createInitialNetwork(currentDate: baseDate);
      var colombia = network[SatelliteAcademyRegionId.colombiaBoyaca]!;

      // Insufficient budget fails
      final poorAttempt = service.unlockOrUpgradeAcademy(
        node: colombia,
        availableBudgetEur: 1000.0,
        currentDate: baseDate,
      );
      expect(poorAttempt.success, isFalse);
      expect(poorAttempt.updatedNode, isNull);

      // Unlock Tier 0 -> 1 -> 2 -> 3 -> 4
      var budget = 5000000.0;
      for (var expectedTier = 1; expectedTier <= 4; expectedTier++) {
        final res = service.unlockOrUpgradeAcademy(
          node: colombia,
          availableBudgetEur: budget,
          currentDate: baseDate,
        );
        expect(res.success, isTrue, reason: res.message);
        expect(res.updatedNode!.tier, expectedTier);
        budget -= res.costEur;
        colombia = res.updatedNode!;
      }

      expect(colombia.status, SatelliteAcademyStatus.eliteFlagship);
      expect(colombia.prospects.length, 1);
      expect(colombia.facilityCondition, 100.0);

      // Upgrading past Tier 4 fails
      final overMax = service.unlockOrUpgradeAcademy(
        node: colombia,
        availableBudgetEur: budget,
        currentDate: baseDate,
      );
      expect(overMax.success, isFalse);
    });

    test('changeFocusMode, enrollRiderInCamp, and capacity/duration validation', () {
      final network = service.createInitialNetwork(currentDate: baseDate);
      final locked = network[SatelliteAcademyRegionId.flandersKortrijk]!;
      var sierra = network[SatelliteAcademyRegionId.sierraNevadaGranada]!;

      // Cannot change focus or enroll on locked academy
      expect(
        service
            .changeFocusMode(
              node: locked,
              focusMode: SatelliteAcademyFocusMode.skillMastery,
              currentDate: baseDate,
            )
            .success,
        isFalse,
      );
      expect(
        service
            .enrollRiderInCamp(
              node: locked,
              riderId: 'r1',
              riderName: 'Jan Kowalski',
              durationDays: 14,
              intensity: AcademyCampIntensity.standardBlock,
              currentDate: baseDate,
            )
            .success,
        isFalse,
      );

      // Invalid duration (<7 or >28)
      expect(
        service
            .enrollRiderInCamp(
              node: sierra,
              riderId: 'r1',
              riderName: 'Jan Kowalski',
              durationDays: 3,
              intensity: AcademyCampIntensity.standardBlock,
              currentDate: baseDate,
            )
            .success,
        isFalse,
      );

      // Enroll riders up to Tier 1 maxCampCapacity
      final capacity = sierra.maxCampCapacity;
      for (var i = 0; i < capacity; i++) {
        final res = service.enrollRiderInCamp(
          node: sierra,
          riderId: 'rider_$i',
          riderName: 'Kolarz $i',
          durationDays: 14,
          intensity: AcademyCampIntensity.peakSupercompensation,
          currentDate: baseDate,
        );
        expect(res.success, isTrue);
        sierra = res.updatedNode!;
      }

      // Duplicate rider fails
      final duplicate = service.enrollRiderInCamp(
        node: sierra,
        riderId: 'rider_0',
        riderName: 'Kolarz 0',
        durationDays: 14,
        intensity: AcademyCampIntensity.standardBlock,
        currentDate: baseDate,
      );
      expect(duplicate.success, isFalse);

      // Exceeding capacity fails
      final overflow = service.enrollRiderInCamp(
        node: sierra,
        riderId: 'rider_extra',
        riderName: 'Kolarz Extra',
        durationDays: 14,
        intensity: AcademyCampIntensity.standardBlock,
        currentDate: baseDate,
      );
      expect(overflow.success, isFalse);
    });

    test('advanceNetworkDays trains stints, develops prospects, degrades condition, and maintainFacilities restores 100%', () {
      var network = service.createInitialNetwork(currentDate: baseDate);
      final sierra = network[SatelliteAcademyRegionId.sierraNevadaGranada]!;

      final enrolled = service.enrollRiderInCamp(
        node: sierra,
        riderId: 'leader_1',
        riderName: 'Tadej Nowak',
        durationDays: 14,
        intensity: AcademyCampIntensity.peakSupercompensation,
        currentDate: baseDate,
      );
      expect(enrolled.success, isTrue);
      network[SatelliteAcademyRegionId.sierraNevadaGranada] = enrolled.updatedNode!;

      final initialProspect = enrolled.updatedNode!.prospects.first;

      // Advance 14 days
      network = service.advanceNetworkDays(
        network: network,
        days: 14,
        newCurrentDate: baseDate.add(const Duration(days: 14)),
      );

      final after = network[SatelliteAcademyRegionId.sierraNevadaGranada]!;
      final stint = after.activeStints.first;
      expect(stint.daysCompleted, 14);
      expect(stint.isCompleted, isTrue);
      expect(stint.ftpGainWatts, greaterThan(0.0));
      expect(stint.altitudeGainPercent, greaterThan(0.0));
      expect(stint.vo2MaxGain, greaterThan(0.0));
      expect(stint.fatigueAccumulated, greaterThan(0.0));

      final grownProspect = after.prospects.first;
      expect(grownProspect.trainingWeeksCompleted, greaterThan(initialProspect.trainingWeeksCompleted));
      expect(grownProspect.scoutingConfidence, greaterThanOrEqualTo(initialProspect.scoutingConfidence));
      expect(after.facilityCondition, lessThan(100.0));

      // Maintain facilities back to 100%
      final maint = service.maintainFacilities(
        node: after,
        availableBudgetEur: 500000.0,
        currentDate: baseDate.add(const Duration(days: 14)),
      );
      expect(maint.success, isTrue);
      expect(maint.costEur, greaterThan(0.0));
      expect(maint.updatedNode!.facilityCondition, 100.0);
    });

    test('scoutLocalProspect, promoteProspectToProRoster, summary, and JSON round-trip', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(globalSatelliteTrainingCentersProvider.notifier);
      notifier.selectRegion(SatelliteAcademyRegionId.eastAfricaRiftValley);
      notifier.unlockOrUpgradeRegion(SatelliteAcademyRegionId.eastAfricaRiftValley);

      final stateAfterUnlock = container.read(globalSatelliteTrainingCentersProvider);
      final riftNode = stateAfterUnlock.nodes[SatelliteAcademyRegionId.eastAfricaRiftValley]!;
      expect(riftNode.isBuilt, isTrue);
      expect(riftNode.prospects.length, 1);

      notifier.scoutProspect(SatelliteAcademyRegionId.eastAfricaRiftValley);
      final stateAfterScout = container.read(globalSatelliteTrainingCentersProvider);
      final scoutedNode = stateAfterScout.nodes[SatelliteAcademyRegionId.eastAfricaRiftValley]!;
      expect(scoutedNode.prospects.length, 2);
      expect(
        SatelliteAcademyRegionId.eastAfricaRiftValley.primaryNationalities,
        contains(scoutedNode.prospects.last.nationalityIso),
      );

      final prospectId = scoutedNode.prospects.first.id;
      notifier.promoteProspect(SatelliteAcademyRegionId.eastAfricaRiftValley, prospectId);
      final afterPromote = container.read(globalSatelliteTrainingCentersProvider);
      final promotedNode = afterPromote.nodes[SatelliteAcademyRegionId.eastAfricaRiftValley]!;
      expect(promotedNode.totalGraduatesPromoted, 1);
      expect(promotedNode.prospects.first.isSignedToProRoster, isTrue);

      // Summary check
      final summary = notifier.summary;
      expect(summary.activeCenters, 2);
      expect(summary.totalGraduatesPromoted, 1);
      expect(summary.totalProspectsInPipeline, greaterThanOrEqualTo(2));

      // JSON round-trip
      final restored = GlobalSatelliteTrainingCentersState.fromJson(afterPromote.toJson());
      expect(restored.selectedRegion, afterPromote.selectedRegion);
      expect(restored.teamBudgetEur, closeTo(afterPromote.teamBudgetEur, 0.01));
      expect(restored.nodes.length, 4);
      expect(
        restored.nodes[SatelliteAcademyRegionId.eastAfricaRiftValley]!.totalGraduatesPromoted,
        1,
      );
    });
  });

  group('Responsive Widget Tests (390x844, 1024x768, 1600x900)', () {
    const viewports = <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    for (final size in viewports) {
      testWidgets(
        'ManagerSkillTreePerksPanel renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: SingleChildScrollView(
                    child: ManagerSkillTreePerksPanel(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(ManagerSkillTreePerksPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'GlobalSatelliteTrainingCentersPanel renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: SingleChildScrollView(
                    child: GlobalSatelliteTrainingCentersPanel(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(GlobalSatelliteTrainingCentersPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('GlobalSatelliteTrainingCentersPanel allows selecting regions interactively', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: GlobalSatelliteTrainingCentersPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Kolumbia'), findsWidgets);
      await tester.tap(find.text('Kolumbia').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
