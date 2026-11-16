import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/team_service_course_hq_upgrades.dart';

void main() {
  group('TeamServiceCourseHqUpgrades — Logika i Ekonomia', () {
    test('Katalog zawiera dokładnie 5 modułów po 5 poziomów każdy', () {
      expect(TeamServiceCourseHqUpgrades.catalog.length, 5);
      for (final def in TeamServiceCourseHqUpgrades.catalog) {
        expect(def.levels.length, 5);
        expect(def.maxLevel, 5);
      }
    });

    test('Rozpoczęcie rozbudowy pobiera budżet i uruchamia budowę', () {
      final initial = TeamServiceCourseHqUpgrades.initialState(
        teamName: 'Test WorldTour',
        availableBudgetEur: 2000000,
      );

      final result = TeamServiceCourseHqUpgrades.startUpgrade(
        initial,
        ServiceCourseModuleId.windTunnel,
      );

      expect(result.success, isTrue);
      final mod = result.state.moduleState(ServiceCourseModuleId.windTunnel);
      expect(mod.currentLevel, 0);
      expect(mod.isUnderConstruction, isTrue);
      expect(mod.targetLevel, 1);
      expect(mod.remainingConstructionDays, 21);
      expect(result.state.availableBudgetEur, 2000000 - 350000);
      expect(result.state.upgradeHistory.length, 1);
    });

    test('Postęp dni kończy budowę i odblokowuje stałe bonusy kariery', () {
      var state = TeamServiceCourseHqUpgrades.initialState(
        availableBudgetEur: 5000000,
      );

      state = TeamServiceCourseHqUpgrades.startUpgrade(
        state,
        ServiceCourseModuleId.drivetrainWaxWorkshop,
      ).state;

      state = TeamServiceCourseHqUpgrades.advanceConstructionDays(state, 7);
      expect(
        state
            .moduleState(ServiceCourseModuleId.drivetrainWaxWorkshop)
            .remainingConstructionDays,
        7,
      );
      expect(state.bonuses.drivetrainWattsSaved, 0.0);

      state = TeamServiceCourseHqUpgrades.advanceConstructionDays(state, 7);
      final mod =
          state.moduleState(ServiceCourseModuleId.drivetrainWaxWorkshop);
      expect(mod.isUnderConstruction, isFalse);
      expect(mod.currentLevel, 1);
      expect(state.bonuses.drivetrainWattsSaved, 1.0);
      expect(state.bonuses.equipmentWearReductionPercent, 7.0);
    });

    test('Walidacja blokuje rozbudowę przy braku budżetu i na max poziomie', () {
      final lowBudget = TeamServiceCourseHqUpgrades.initialState(
        availableBudgetEur: 100000,
      );
      final lowRes = TeamServiceCourseHqUpgrades.startUpgrade(
        lowBudget,
        ServiceCourseModuleId.windTunnel,
      );
      expect(lowRes.success, isFalse);

      final maxed = TeamServiceCourseHqUpgrades.initialState(
        availableBudgetEur: 10000000,
        initialLevels: <ServiceCourseModuleId, int>{
          ServiceCourseModuleId.scoutingAcademy: 5,
        },
      );
      final maxRes = TeamServiceCourseHqUpgrades.startUpgrade(
        maxed,
        ServiceCourseModuleId.scoutingAcademy,
      );
      expect(maxRes.success, isFalse);
      expect(
        maxRes.state.bonuses.scoutingAccuracyBonusPercent,
        25.0,
      );
      expect(
        maxRes.state.bonuses.u23PotentialGrowthBonusPercent,
        18.0,
      );
    });

    test('Anulowanie budowy zwraca 50% kosztów do budżetu', () {
      final initial = TeamServiceCourseHqUpgrades.initialState(
        availableBudgetEur: 1000000,
      );
      final started = TeamServiceCourseHqUpgrades.startUpgrade(
        initial,
        ServiceCourseModuleId.hypoxiaCenter,
      ).state;

      expect(started.availableBudgetEur, 1000000 - 280000);

      final cancelled = TeamServiceCourseHqUpgrades.cancelConstruction(
        started,
        ServiceCourseModuleId.hypoxiaCenter,
      );

      expect(cancelled.success, isTrue);
      expect(cancelled.state.availableBudgetEur, 1000000 - 140000);
      expect(
        cancelled.state
            .moduleState(ServiceCourseModuleId.hypoxiaCenter)
            .isUnderConstruction,
        isFalse,
      );
    });

    test('Serializacja JSON zachowuje pełny stan HQ i historię', () {
      var state = TeamServiceCourseHqUpgrades.initialState(
        teamName: 'Bora Test',
        availableBudgetEur: 3200000,
        initialLevels: <ServiceCourseModuleId, int>{
          ServiceCourseModuleId.recoveryBusFleet: 3,
        },
      );
      state = TeamServiceCourseHqUpgrades.startUpgrade(
        state,
        ServiceCourseModuleId.windTunnel,
      ).state;

      final json = state.toJson();
      final restored = TeamServiceCourseHqState.fromJson(json);

      expect(restored.teamName, 'Bora Test');
      expect(restored.availableBudgetEur, state.availableBudgetEur);
      expect(
        restored.moduleState(ServiceCourseModuleId.recoveryBusFleet).currentLevel,
        3,
      );
      expect(
        restored
            .moduleState(ServiceCourseModuleId.windTunnel)
            .isUnderConstruction,
        isTrue,
      );
      expect(restored.bonuses.postStageRecoveryBonusPercent, 12.0);
    });

    test('TeamServiceCourseHqNotifier poprawnie obsługuje akcje Riverpod', () {
      final notifier = TeamServiceCourseHqNotifier(
        initialState: TeamServiceCourseHqUpgrades.initialState(
          availableBudgetEur: 3000000,
        ),
      );

      final res = notifier.startUpgrade(ServiceCourseModuleId.scoutingAcademy);
      expect(res.success, isTrue);
      expect(notifier.state.activeConstructionsCount, 1);

      notifier.advanceDays(16);
      expect(
        notifier.state
            .moduleState(ServiceCourseModuleId.scoutingAcademy)
            .currentLevel,
        1,
      );
    });
  });

  group('TeamServiceCourseHqPanel — Responsywność i Interakcja UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      TeamServiceCourseHqState? state,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamServiceCourseHqPanel(initialState: state),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('Renderuje się bez overflow na 390x844, 1024x768 i 1600x900', (
      tester,
    ) async {
      for (final size in const <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size);
        expect(find.text('SERVICE COURSE HQ'), findsOneWidget);
        expect(find.text('Własny Tunel Aerodynamiczny'), findsOneWidget);
        expect(find.text('Akademia Skautingu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Interakcja przycisku rozbudowy i symulacji +7 dni działa w UI', (
      tester,
    ) async {
      await pumpPanelAtSize(
        tester,
        const Size(1600, 900),
        state: TeamServiceCourseHqUpgrades.initialState(
          availableBudgetEur: 4000000,
        ),
      );

      final upgradeBtn = find.textContaining('Rozbuduj Poz. 1').first;
      await tester.ensureVisible(upgradeBtn);
      await tester.tap(upgradeBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Symuluj +7 dni'), findsOneWidget);
      expect(find.textContaining('Anuluj budowę'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
