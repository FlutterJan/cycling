import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/career/manager_skill_tree_perks_service.dart';

void main() {
  group('ManagerSkillTreePerksService', () {
    test('XP progression levels up and grants milestone bonus SP at level 5', () {
      var state = ManagerSkillTreeState.initial();
      expect(state.managerLevel, 1);
      expect(state.availableSkillPoints, 2);

      // Lvl 1->2: 1000, 2->3: 1350, 3->4: 1700, 4->5: 2050 => 6100 XP total
      state = ManagerSkillTreePerksService.awardExperience(
        state,
        xp: 6200,
        source: ManagerXpSource.grandTourStage,
        title: 'Zwycięstwo na Alpe d\'Huez',
        timestamp: DateTime(2026, 7, 15),
      );

      expect(state.managerLevel, 5);
      // Initial 2 + 1 (lvl2) + 1 (lvl3) + 1 (lvl4) + 2 (lvl5 milestone) = 7 SP
      expect(state.availableSkillPoints, 7);
      expect(state.recentXpLog.length, 1);
      expect(state.recentXpLog.first.source, ManagerXpSource.grandTourStage);
    });

    test('enforces prerequisites, level requirements and computes passive perks', () {
      var state = ManagerSkillTreeState.initial();

      // Cannot unlock Tier 2 without Tier 1 prerequisite
      final blockedPrereq = ManagerSkillTreePerksService.unlockSkillRank(
        state,
        'tac_crosswind_echelons',
      );
      expect(blockedPrereq.success, isFalse);

      // Unlock Tier 1 rank 1
      final unlockT1 = ManagerSkillTreePerksService.unlockSkillRank(
        state,
        'tac_radio_discipline',
      );
      expect(unlockT1.success, isTrue);
      state = unlockT1.state;
      expect(state.availableSkillPoints, 1);
      expect(state.spentSkillPoints, 1);
      expect(state.aggregateEffects.raceTacticalExecutionBonusPct, 2.5);

      // Still cannot unlock Tier 2 because managerLevel == 1 < required 3
      final blockedLevel = ManagerSkillTreePerksService.unlockSkillRank(
        state,
        'tac_crosswind_echelons',
      );
      expect(blockedLevel.success, isFalse);
      expect(blockedLevel.message, contains('Poziom Menedżera: 3'));
    });

    test('full respec refunds exact skill points and clears unlocked ranks', () {
      var state = ManagerSkillTreeState.initial();
      state = ManagerSkillTreePerksService.awardExperience(
        state,
        xp: 15000,
        source: ManagerXpSource.seasonCompletion,
        title: 'Koniec sezonu',
      );
      final initialPool = state.availableSkillPoints;

      state = ManagerSkillTreePerksService.unlockSkillRank(
        state,
        'tac_radio_discipline',
      ).state;
      state = ManagerSkillTreePerksService.unlockSkillRank(
        state,
        'tac_crosswind_echelons',
      ).state;
      expect(state.spentSkillPoints, 2);

      state = ManagerSkillTreePerksService.refundAllSkills(state);
      expect(state.spentSkillPoints, 0);
      expect(state.availableSkillPoints, initialPool);
      expect(state.unlockedRanks, isEmpty);
      expect(state.respecCount, 1);
    });

    test('JSON serialization round-trip preserves state accurately', () {
      var state = ManagerSkillTreeState.initial();
      state = ManagerSkillTreePerksService.awardExperience(
        state,
        xp: 2500,
        source: ManagerXpSource.raceWin,
        title: 'Paryż-Roubaix',
        timestamp: DateTime(2026, 4, 12),
      );
      state = ManagerSkillTreePerksService.unlockSkillRank(
        state,
        'fin_sponsor_pitch',
      ).state;

      final json = state.toJson();
      final restored = ManagerSkillTreeState.fromJson(json);

      expect(restored.managerLevel, state.managerLevel);
      expect(restored.currentXp, state.currentXp);
      expect(restored.availableSkillPoints, state.availableSkillPoints);
      expect(restored.spentSkillPoints, state.spentSkillPoints);
      expect(restored.unlockedRanks, state.unlockedRanks);
      expect(restored.recentXpLog.length, 1);
    });
  });

  group('ManagerSkillTreePerksPanel responsive UI', () {
    for (final size in const <Size>[
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

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: ManagerSkillTreePerksPanel(),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 350));

          expect(find.text('Drzewko Umiejętności Menedżera'), findsOneWidget);
          expect(find.text('Aktywne Perki Pasywne'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('interactive unlock updates skill points and rank', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: ManagerSkillTreePerksPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('2 SP'), findsOneWidget);

      final unlockButton = find.text('Odblokuj rangę (1 SP)');
      expect(unlockButton, findsOneWidget);
      await tester.ensureVisible(unlockButton);
      await tester.tap(unlockButton);
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('1 SP'), findsOneWidget);
      expect(find.text('Ranga: 1/3'), findsOneWidget);
    });
  });
}
