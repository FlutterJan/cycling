import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/manager_profile_and_reputation_screen.dart';

void main() {
  group('ManagerProfileAndReputationScreen — Logika i Model', () {
    test('ManagerReputationTier.fromScore poprawnie mapuje progi 0-100', () {
      expect(
        ManagerReputationTier.fromScore(10),
        ManagerReputationTier.rookieDirector,
      );
      expect(
        ManagerReputationTier.fromScore(35),
        ManagerReputationTier.proTactician,
      );
      expect(
        ManagerReputationTier.fromScore(62),
        ManagerReputationTier.worldTourDirector,
      );
      expect(
        ManagerReputationTier.fromScore(82),
        ManagerReputationTier.dynastyArchitect,
      );
      expect(
        ManagerReputationTier.fromScore(95),
        ManagerReputationTier.cyclingLegend,
      );
    });

    test('ManagerLifetimeStats serializuje i deserializuje JSON bez straty', () {
      final base = ManagerProfileSnapshot.demoPreview().lifetimeStats;
      final restored = ManagerLifetimeStats.fromJson(base.toJson());
      expect(restored.seasonsManaged, base.seasonsManaged);
      expect(restored.totalVictories, base.totalVictories);
      expect(restored.grandTourTitles, base.grandTourTitles);
      expect(restored.monumentWins, base.monumentWins);
      expect(restored.totalPrizeMoneyEur, base.totalPrizeMoneyEur);
      expect(restored.tacticalEfficiencyPct, base.tacticalEfficiencyPct);
    });
  });

  group('ManagerProfileAndReputationScreen — Widgety i Responsywność', () {
    Widget buildTestHost({
      required Size size,
      ManagerProfileSnapshot? snapshot,
      bool isReadOnly = false,
      ValueChanged<ManagerMediaStance>? onMediaStanceChanged,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: ManagerProfileAndReputationScreen(
              initialSnapshot: snapshot,
              isReadOnly: isReadOnly,
              onMediaStanceChanged: onMediaStanceChanged,
            ),
          ),
        ),
      );
    }

    testWidgets('Stan pusty pozwala wczytać podgląd profilu', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestHost(size: const Size(1280, 800)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak aktywnego profilu menedżera'), findsOneWidget);
      await tester.tap(find.text('Wczytaj podgląd profilu'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Jan Kowalski'), findsOneWidget);
      expect(find.text('5 Filarów Reputacji Menedżera'), findsOneWidget);
    });

    testWidgets('Przełączanie zakładek, filarów i trybu tylko do odczytu', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      ManagerMediaStance? changedStance;
      final snapshot = ManagerProfileSnapshot.demoPreview();

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1600, 900),
          snapshot: snapshot,
          onMediaStanceChanged: (s) => changedStance = s,
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      // Kliknięcie filaru rozwija opis wpływu
      await tester.tap(find.text('Sukcesy Sportowe'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('dzikie karty ASO/RCS'), findsOneWidget);

      // Zakładka Statystyki Życiowe
      await tester.tap(find.text('Statystyki Życiowe'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Rozkład Zwycięstw według Terenu'), findsOneWidget);

      await tester.tap(find.text('Monumenty'));
      await tester.pump(const Duration(milliseconds: 200));

      // Zakładka Taktyka i Cechy
      await tester.tap(find.text('Taktyka i Cechy'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Dyplomatyczny'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(changedStance, ManagerMediaStance.diplomatic);

      // Zakładka Historia i Kamienie
      await tester.tap(find.text('Historia i Kamienie'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kamienie Milowe i Kronika Kariery'), findsOneWidget);

      await tester.tap(find.text('Tylko kluczowe'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Debiut na poziomie UCI WorldTour'), findsNothing);
      expect(find.text('Triumf na welodromie Paris–Roubaix'), findsOneWidget);
    });

    testWidgets('Tryb isReadOnly blokuje zmianę stylu medialnego', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      ManagerMediaStance? changedStance;
      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1280, 800),
          snapshot: ManagerProfileSnapshot.demoPreview(),
          isReadOnly: true,
          onMediaStanceChanged: (s) => changedStance = s,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tylko odczyt'), findsOneWidget);
      await tester.tap(find.text('Taktyka i Cechy'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Bezkompromisowy'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(changedStance, isNull);
    });

    for (final resolution in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'Brak przepełnień RenderFlex dla rozdzielczości ${resolution.width.toInt()}x${resolution.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = resolution;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildTestHost(
              size: resolution,
              snapshot: ManagerProfileSnapshot.demoPreview(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 350));

          for (final tab in ManagerProfileTab.values) {
            final finder = find.text(tab.label);
            await tester.ensureVisible(finder);
            await tester.tap(finder);
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  });
}
