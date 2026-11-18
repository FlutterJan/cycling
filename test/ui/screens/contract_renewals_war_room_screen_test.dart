import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/screens/contract_renewals_war_room_screen.dart';
import 'package:pro_peloton_manager/ui/widgets/contract_negotiation_chat_simulator.dart';

void main() {
  Widget buildTestApp({
    bool isReadOnly = false,
    int annualWageBudgetEur = 6800000,
    ValueChanged<ContractRenewalsOutcome>? onContractsUpdated,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: ContractRenewalsWarRoomScreen(
          seasonYear: 2027,
          annualWageBudgetEur: annualWageBudgetEur,
          isReadOnly: isReadOnly,
          onContractsUpdated: onContractsUpdated,
          negotiationReplyDelay: const Duration(milliseconds: 20),
        ),
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Size size, {
    bool isReadOnly = false,
    int annualWageBudgetEur = 6800000,
    ValueChanged<ContractRenewalsOutcome>? onContractsUpdated,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      buildTestApp(
        isReadOnly: isReadOnly,
        annualWageBudgetEur: annualWageBudgetEur,
        onContractsUpdated: onContractsUpdated,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  test('ContractRenewalsWarRoomCalculator classifies priorities and forecasts payroll',
      () {
    final roster = ContractRenewalsWarRoomCalculator.buildDefaultRoster(
      seasonYear: 2027,
    );
    final entries = ContractRenewalsWarRoomCalculator.buildEntries(
      roster,
      seasonYear: 2027,
    );

    expect(
      entries.where((e) => e.priorityTier == RenewalPriorityTier.leaders).length,
      2,
    );
    expect(
      entries
          .where((e) => e.priorityTier == RenewalPriorityTier.keyDomestiques)
          .length,
      2,
    );
    expect(
      entries
          .where((e) => e.priorityTier == RenewalPriorityTier.u23Talents)
          .length,
      2,
    );

    final forecast = ContractRenewalsWarRoomCalculator.computeForecast(
      fullRoster: roster,
      entries: entries,
      seasonYear: 2027,
      annualWageBudgetEur: 6800000,
    );

    expect(forecast.expiringCount, 6);
    expect(forecast.renewedCount, 0);
    expect(
      forecast.committedNextSeasonPayrollEur,
      (95000 + 48000) * 12,
    );
    expect(
      forecast.totalProjectedNextSeasonPayrollEur,
      greaterThan(forecast.committedNextSeasonPayrollEur),
    );
    expect(forecast.isOverBudget, isFalse);

    final tightForecast = ContractRenewalsWarRoomCalculator.computeForecast(
      fullRoster: roster,
      entries: entries,
      seasonYear: 2027,
      annualWageBudgetEur: 2500000,
    );
    expect(tightForecast.isOverBudget, isTrue);
  });

  testWidgets('responsive layout passes at 390x844, 1024x768, and 1600x900',
      (tester) async {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      await pumpScreen(tester, size);
      expect(find.byType(ContractRenewalsWarRoomScreen), findsOneWidget);
      expect(find.text('Centrum Przedłużeń Kontraktów'), findsOneWidget);
      expect(find.textContaining('Liderzy (2)'), findsOneWidget);
      expect(find.textContaining('Klucowi Pomocnicy (2)'), findsOneWidget);
      expect(find.textContaining('Młode Talenty U23 (2)'), findsOneWidget);
      expect(find.textContaining('Prognoza Budżetu Płacowego 2028'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('priority filter and instant negotiation modal work properly',
      (tester) async {
    await pumpScreen(tester, const Size(1600, 900));

    // Filter to U23 Talents only
    await tester.tap(
      find.byKey(const ValueKey<String>('filter_tier_u23Talents')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('Młode Talenty U23 (2)'), findsOneWidget);
    expect(find.textContaining('Liderzy (2)'), findsNothing);

    // Open instant negotiation modal
    final negotiateFinder = find.text('Natychmiastowe negocjacje').first;
    await tester.ensureVisible(negotiateFinder);
    await tester.tap(negotiateFinder);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ContractNegotiationChatSimulator), findsOneWidget);

    // Close modal
    await tester.tap(find.byTooltip('Zamknij okno negocjacji'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ContractNegotiationChatSimulator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('readOnly mode disables negotiation actions', (tester) async {
    await pumpScreen(tester, const Size(1024, 768), isReadOnly: true);

    expect(find.text('Podgląd'), findsOneWidget);

    final negotiateFinder = find.text('Natychmiastowe negocjacje').first;
    await tester.ensureVisible(negotiateFinder);
    await tester.tap(negotiateFinder);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ContractNegotiationChatSimulator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
