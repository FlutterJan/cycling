import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/career_achievements_and_trophies_engine.dart';

void main() {
  group('CareerAchievementsAndTrophiesEngine — Catalog & Logic', () {
    test('catalog has exactly 60 unique achievements across 6 categories', () {
      const catalog = CareerAchievementsAndTrophiesEngine.catalog;
      expect(catalog.length, 60);

      final ids = catalog.map((e) => e.id).toSet();
      expect(ids.length, 60);

      final codes = catalog.map((e) => e.codeNumber).toSet();
      expect(codes.length, 60);
      expect(codes.containsAll(List.generate(60, (i) => i + 1)), isTrue);

      for (final category in CareerAchievementCategory.values) {
        final count = catalog.where((e) => e.category == category).length;
        expect(count, 10, reason: 'Category $category must have 10 items');
      }
    });

    test('evaluates Grand Tour, Monuments, Tactics & Equipment milestones', () {
      var state = CareerAchievementsEngineState.initial();

      // 1. Tour de France overall + summit stage + 3 stages + <10s margin
      final gtRes = CareerAchievementsAndTrophiesEngine.evaluateEvent(
        state,
        const CareerAchievementEvaluationInput(
          seasonYear: 2027,
          raceTier: AchievementRaceTier.grandTour,
          grandTourId: 'tour_de_france',
          raceName: 'Tour de France',
          stageWon: true,
          raceWonOverall: true,
          isSummitFinish: true,
          winMarginSeconds: 8.0,
          stageWinsInSingleGrandTour: 3,
          peak20MinWkg: 6.62,
          peak5SecWatts: 1640,
        ),
      );
      state = gtRes.nextState;

      expect(state.progressById['gt_first_stage_win']!.isUnlocked, isTrue);
      expect(state.progressById['gt_stage_hattrick']!.isUnlocked, isTrue);
      expect(state.progressById['gt_first_overall_win']!.isUnlocked, isTrue);
      expect(state.progressById['gt_summit_hc_queen']!.isUnlocked, isTrue);
      expect(state.progressById['gt_millimeter_gc_win']!.isUnlocked, isTrue);
      expect(state.progressById['eqp_mutant_wkg_65']!.isUnlocked, isTrue);
      expect(state.progressById['eqp_sprint_1600w']!.isUnlocked, isTrue);
      expect(state.progressById['mgt_first_win']!.isUnlocked, isTrue);

      // 2. All 5 Monuments
      for (final mon in [
        'msr',
        'ronde',
        'roubaix',
        'liege',
        'lombardia',
      ]) {
        state = CareerAchievementsAndTrophiesEngine.evaluateEvent(
          state,
          CareerAchievementEvaluationInput(
            seasonYear: 2028,
            raceTier: AchievementRaceTier.monument,
            monumentId: mon,
            raceName: mon,
            raceWonOverall: true,
          ),
        ).nextState;
      }

      expect(state.progressById['mon_first_monument']!.isUnlocked, isTrue);
      expect(state.progressById['mon_roubaix_cobbles']!.isUnlocked, isTrue);
      expect(state.progressById['mon_flanders_berg']!.isUnlocked, isTrue);
      expect(state.progressById['mon_sanremo_poggio']!.isUnlocked, isTrue);
      expect(state.progressById['mon_ardennes_liege']!.isUnlocked, isTrue);
      expect(state.progressById['mon_lombardia_leaves']!.isUnlocked, isTrue);
      expect(state.progressById['mon_all_five_monuments']!.isUnlocked, isTrue);
      expect(state.platinumTrophy.isUnlocked, isFalse);
    });

    test('unlocks Platinum Trophy when all 60 achievements are completed', () {
      var state = CareerAchievementsEngineState.initial();
      const catalog = CareerAchievementsAndTrophiesEngine.catalog;

      for (int i = 0; i < catalog.length - 1; i++) {
        final def = catalog[i];
        final res =
            CareerAchievementsAndTrophiesEngine.incrementAchievementProgress(
          state,
          def.id,
          delta: def.targetValue,
          seasonYear: 2030,
        );
        state = res.nextState;
        expect(res.platinumJustUnlocked, isFalse);
      }

      expect(state.platinumTrophy.unlockedCount, 59);
      expect(state.platinumTrophy.isUnlocked, isFalse);

      // Unlock the 60th achievement
      final lastDef = catalog.last;
      final finalRes =
          CareerAchievementsAndTrophiesEngine.incrementAchievementProgress(
        state,
        lastDef.id,
        delta: lastDef.targetValue,
        seasonYear: 2030,
      );
      state = finalRes.nextState;

      expect(finalRes.platinumJustUnlocked, isTrue);
      expect(state.platinumTrophy.isUnlocked, isTrue);
      expect(state.platinumTrophy.unlockedCount, 60);
      expect(state.platinumTrophy.completionPercent, 100);
      expect(
        finalRes.newlyUnlocked.any((e) => e.isPlatinumTrophy),
        isTrue,
      );
      expect(
        state.platinumTrophy.totalPointsEarned,
        CareerAchievementsAndTrophiesEngine.maxBaseAchievementPoints +
            PlatinumTrophyRecord.platinumBonusPoints,
      );
    });

    test('JSON serialization round-trip preserves progress and platinum state',
        () {
      var state = CareerAchievementsEngineState.initial();
      state = CareerAchievementsAndTrophiesEngine.evaluateEvent(
        state,
        const CareerAchievementEvaluationInput(
          seasonYear: 2029,
          raceTier: AchievementRaceTier.olympicGames,
          raceName: 'Olympic Road Race',
          raceWonOverall: true,
          olympicGoldMedalWon: true,
          hourRecordDistanceKm: 56.820,
        ),
      ).nextState;

      final json = state.toJson();
      final restored = CareerAchievementsEngineState.fromJson(json);

      expect(restored.progressById['pro_olympic_gold']!.isUnlocked, isTrue);
      expect(restored.progressById['pro_uci_hour_record']!.isUnlocked, isTrue);
      expect(
        restored.platinumTrophy.unlockedCount,
        state.platinumTrophy.unlockedCount,
      );
      expect(restored.unlockHistory.length, state.unlockHistory.length);
    });

    test('Riverpod CareerAchievementsNotifier evaluates and consumes toasts',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(careerAchievementsProvider.notifier);
      final events = notifier.evaluate(
        const CareerAchievementEvaluationInput(
          seasonYear: 2026,
          raceTier: AchievementRaceTier.worldTourClassic,
          raceWonOverall: true,
          soloAttackDistanceKm: 55.0,
        ),
      );

      expect(events.isNotEmpty, isTrue);
      expect(
        container.read(careerAchievementsProvider).pendingToastQueue.length,
        events.length,
      );

      final firstToast = notifier.consumeNextToast();
      expect(firstToast, isNotNull);
      expect(
        container.read(careerAchievementsProvider).pendingToastQueue.length,
        events.length - 1,
      );

      notifier.resetProgress();
      expect(
        container.read(careerAchievementsProvider).platinumTrophy.unlockedCount,
        0,
      );
    });
  });

  group('CareerAchievementsAndTrophiesPanel — Responsive & Interaction', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      bool readOnly = false,
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: CareerAchievementsAndTrophiesPanel(readOnly: readOnly),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpPanelAtSize(tester, size);
          expect(tester.takeException(), isNull);
          expect(
            find.text(PlatinumTrophyRecord.platinumTitle),
            findsOneWidget,
          );
          expect(find.textContaining('#01 '), findsOneWidget);
        },
      );
    }

    testWidgets('supports search, category filter and disabled readOnly mode',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));

      await tester.enterText(find.byType(TextField), 'Roubaix');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Piekła Północy'), findsOneWidget);

      await tester.tap(find.text('Wyczyść'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('#01 '), findsOneWidget);

      await pumpPanelAtSize(tester, const Size(1024, 768), readOnly: true);
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.enabled, isFalse);
    });
  });
}
