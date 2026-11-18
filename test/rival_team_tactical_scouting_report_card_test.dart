import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/career/ai_director_sportif_tactical_styles_engine.dart';
import 'package:pro_peloton_manager/ui/widgets/rival_team_tactical_scouting_report_card.dart';

void main() {
  const mountainContext = StageTacticalContextInput(
    stageName: 'Etap 14 • Col du Tourmalet',
    terrain: DsStageTerrainFocus.highMountain,
    distanceKm: 178.0,
    remainingKm: 178.0,
    crosswindKmh: 26.0,
    elevationGainM: 4120,
    isGrandTour: true,
    hasCobbleSectors: false,
    leaderGcGapSeconds: 24.0,
  );

  Future<void> pumpCardAtSize(
    WidgetTester tester,
    Size size, {
    bool isDisabled = false,
    PelotonTacticalMatchupReport? customReport,
    ValueChanged<DsStageTacticalPlan>? onSelectRivalPlan,
    ValueChanged<String>? onApplyCounterStrategy,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: RivalTeamTacticalScoutingReportCard(
              stageContext: mountainContext,
              report: customReport,
              isDisabled: isDisabled,
              onSelectRivalPlan: onSelectRivalPlan,
              onApplyCounterStrategy: onApplyCounterStrategy,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('renderuje bez przepełnienia na 390x844, 1024x768 i 1600x900', (
    tester,
  ) async {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      await pumpCardAtSize(tester, size);
      expect(find.text('WYWIAD TAKTYCZNY RYWALI'), findsOneWidget);
      expect(find.text('PRZEWIDYWANY PLAN NA ETAP'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Overflow at $size');
    }
  });

  testWidgets('obsługuje przełączanie zakładek, filtrów i wybór kontrtaktyki', (
    tester,
  ) async {
    DsStageTacticalPlan? selectedPlan;
    String? appliedTip;

    await pumpCardAtSize(
      tester,
      const Size(1280, 860),
      onSelectRivalPlan: (plan) => selectedPlan = plan,
      onApplyCounterStrategy: (tip) => appliedTip = tip,
    );

    // Wybór drugiego rywala z listy zagrożeń
    await tester.tap(find.text('2'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(selectedPlan, isNotNull);

    // Zastosowanie kontrtaktyki
    final applyButton = find.textContaining('Zastosuj kontrtaktykę przeciw');
    expect(applyButton, findsOneWidget);
    await tester.tap(applyButton);
    await tester.pump(const Duration(milliseconds: 250));
    expect(appliedTip, isNotNull);
    expect(find.text('Kontrtaktyka aktywna w odprawie'), findsOneWidget);

    // Przełączenie na zakładkę Rozkład Peletonu
    await tester.tap(find.text('Rozkład Peletonu'));
    await tester.pump(const Duration(milliseconds: 280));
    expect(
      find.text('ROZKŁAD ARCHETYPÓW TAKTYCZNYCH W PELETONIE'),
      findsOneWidget,
    );

    // Przełączenie na zakładkę Kontrtaktyka
    await tester.tap(find.text('Kontrtaktyka'));
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('Aktywna w planie'), findsOneWidget);
  });

  testWidgets('obsługuje stan pusty oraz stan wyłączony (disabled)', (
    tester,
  ) async {
    const emptyReport = PelotonTacticalMatchupReport(
      playerTeamId: 'team_player',
      rivalTeamCount: 0,
      archetypeDistribution: {},
      topThreatPlans: [],
      expectedBreakawayTeams: [],
      expectedChaseTeams: [],
      expectedEchelonInstigators: [],
    );

    await pumpCardAtSize(
      tester,
      const Size(1024, 768),
      customReport: emptyReport,
    );
    expect(
      find.text('Brak ekip spełniających kryterium "Wszystkie".'),
      findsOneWidget,
    );

    String? disabledApplied;
    await pumpCardAtSize(
      tester,
      const Size(1024, 768),
      isDisabled: true,
      onApplyCounterStrategy: (tip) => disabledApplied = tip,
    );
    await tester.tap(
      find.textContaining('Zastosuj kontrtaktykę przeciw'),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(disabledApplied, isNull);
  });
}
