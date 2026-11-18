import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/simulation/what_if_tactical_sandbox_simulator.dart';
import 'package:pro_peloton_manager/models/career/rider_relationship_chemistry_web_model.dart';
import 'package:pro_peloton_manager/ui/widgets/team_chemistry_relationship_web_painter.dart';
import 'package:pro_peloton_manager/ui/widgets/what_if_scenario_comparator_modal.dart';

RiderRelationshipChemistryWebModel _buildSampleLockerRoomModel() {
  final roster = <RiderLockerRoomProfile>[
    const RiderLockerRoomProfile(
      riderId: 'r_alpha',
      riderName: 'Marek Kowalski',
      archetype: LockerRoomPersonalityArchetype.alphaLeader,
      leadershipWeight: 92,
      egoLevel: 80,
      adaptability: 58,
      currentMorale: 82,
      isTeamCaptain: true,
    ),
    const RiderLockerRoomProfile(
      riderId: 'r_dom',
      riderName: 'Jan Nowak',
      archetype: LockerRoomPersonalityArchetype.humbleDomestique,
      leadershipWeight: 60,
      egoLevel: 25,
      adaptability: 88,
      currentMorale: 85,
    ),
    const RiderLockerRoomProfile(
      riderId: 'r_vet',
      riderName: 'Tomasz Zieliński',
      archetype: LockerRoomPersonalityArchetype.mentorVeteran,
      leadershipWeight: 84,
      egoLevel: 40,
      adaptability: 82,
      currentMorale: 78,
    ),
    const RiderLockerRoomProfile(
      riderId: 'r_kid',
      riderName: 'Kacper Wiśniewski',
      archetype: LockerRoomPersonalityArchetype.ambitiousWonderkid,
      leadershipWeight: 48,
      egoLevel: 76,
      adaptability: 64,
      currentMorale: 74,
    ),
    const RiderLockerRoomProfile(
      riderId: 'r_rival',
      riderName: 'Piotr Mazur',
      archetype: LockerRoomPersonalityArchetype.alphaLeader,
      leadershipWeight: 78,
      egoLevel: 88,
      adaptability: 42,
      currentMorale: 68,
    ),
  ];

  return RiderRelationshipChemistryWebModel.fromRoster(
    teamId: 'team_pl_worldtour',
    seasonYear: 2026,
    roster: roster,
    initialDateIso: '2026-01-10',
  );
}

void main() {
  group('RiderRelationshipChemistryWebModel — Graf relacji w szatni', () {
    test('fromRoster inicjalizuje symetryczną macierz i kompatybilność archetypów', () {
      final model = _buildSampleLockerRoomModel();

      expect(model.profiles.length, 5);
      // 5 * 4 / 2 = 10 krawędzi
      expect(model.edges.length, 10);

      final matrix = model.buildRelationshipMatrix();
      expect(matrix['r_alpha']!['r_alpha'], 0);
      expect(matrix['r_alpha']!['r_dom'], matrix['r_dom']!['r_alpha']);

      // Alpha Leader + Humble Domestique ma dodatnią bazę (+15)
      expect(model.getScore('r_alpha', 'r_dom'), 15);
      // Alpha Leader + Alpha Leader ma ujemną bazę (-15)
      expect(model.getScore('r_alpha', 'r_rival'), -15);
      // Mentor Veteran + Ambitious Wonderkid ma wysoką bazę (+18)
      expect(model.getScore('r_vet', 'r_kid'), 18);
    });

    test('applyInteractionEvent aktualizuje relacje, respektuje clamp i waliduje błędy', () {
      var model = _buildSampleLockerRoomModel();

      final selfResult = model.applyInteractionEvent(
        riderAId: 'r_alpha',
        riderBId: 'r_alpha',
        eventType: RelationshipEventType.trainingCampBonding,
        scoreDelta: 10,
        summary: 'Test samego siebie',
        dateIso: '2026-02-01',
      );
      expect(selfResult.success, isFalse);

      final missingResult = model.applyInteractionEvent(
        riderAId: 'r_alpha',
        riderBId: 'non_existent',
        eventType: RelationshipEventType.trainingCampBonding,
        scoreDelta: 10,
        summary: 'Brak kolarza',
        dateIso: '2026-02-01',
      );
      expect(missingResult.success, isFalse);

      final boost = model.applyInteractionEvent(
        riderAId: 'r_alpha',
        riderBId: 'r_dom',
        eventType: RelationshipEventType.wheelOrBikeSacrifice,
        scoreDelta: 65,
        summary: 'Oddanie roweru na bruku',
        dateIso: '2026-03-15',
        raceName: 'Paris-Roubaix',
        incrementSharedRaces: 3,
      );
      expect(boost.success, isTrue);
      model = boost.updatedModel;
      expect(model.getScore('r_alpha', 'r_dom'), 80);
      expect(model.getEdge('r_alpha', 'r_dom')!.sharedRacesCount, 3);

      // Sprawdzenie clampowania powyżej +100
      final overMax = model.applyInteractionEvent(
        riderAId: 'r_alpha',
        riderBId: 'r_dom',
        eventType: RelationshipEventType.heroicMountainDefense,
        scoreDelta: 50,
        summary: 'Obrona żółtej koszulki',
        dateIso: '2026-07-18',
      );
      expect(overMax.updatedModel.getScore('r_alpha', 'r_dom'), 100);
    });

    test('cykl paktu Blood Brothers: zawarcie (złoty ton), premie i zerwanie (toksyczny konflikt)', () {
      var model = _buildSampleLockerRoomModel();

      // Początkowo brak warunków (zbyt niski wynik i 0 wspólnych wyścigów)
      expect(model.canForgeBloodBrothersPact('r_alpha', 'r_dom'), isFalse);

      model = model
          .applyInteractionEvent(
            riderAId: 'r_alpha',
            riderBId: 'r_dom',
            eventType: RelationshipEventType.heroicMountainDefense,
            scoreDelta: 75,
            summary: 'Wspólna obrona w Alpach',
            dateIso: '2026-04-10',
            incrementSharedRaces: 5,
          )
          .updatedModel;

      expect(model.canForgeBloodBrothersPact('r_alpha', 'r_dom'), isTrue);

      final forgeResult = model.forgeBloodBrothersPact(
        riderAId: 'r_alpha',
        riderBId: 'r_dom',
        dateIso: '2026-04-11',
        raceName: 'Tour des Alpes',
        customPactId: 'pact_alpha_dom',
      );
      expect(forgeResult.success, isTrue);
      model = forgeResult.updatedModel;

      final pact = model.getPactBetween('r_alpha', 'r_dom');
      expect(pact, isNotNull);
      expect(pact!.isActive, isTrue);
      expect(model.getBloodBrothersFor('r_alpha'), contains('r_dom'));

      final edgeAfterForge = model.getEdge('r_alpha', 'r_dom')!;
      expect(
        edgeAfterForge.visualTone(activePact: true),
        RelationshipConnectionVisualTone.gold,
      );
      expect(
        edgeAfterForge.tierWithPactStatus(activePact: true),
        RelationshipTier.bloodBrothers,
      );

      final raceBonus = pact.calculateRaceBonus();
      expect(raceBonus.domestiqueSacrificeBonusPct, greaterThan(0.0));
      expect(raceBonus.leadOutSyncBonusPct, greaterThan(0.0));

      // Zerwanie paktu zrzuca wynik do -75 (czerwony konflikt) i blokuje odnowienie
      final breakResult = model.breakBloodBrothersPact(
        pactId: 'pact_alpha_dom',
        reason: 'Pogoń za własnym kolegą z ucieczki',
        dateIso: '2026-07-12',
      );
      expect(breakResult.success, isTrue);
      model = breakResult.updatedModel;

      expect(model.getPactBetween('r_alpha', 'r_dom'), isNull);
      expect(model.getScore('r_alpha', 'r_dom'), -75);
      expect(
        model.getEdge('r_alpha', 'r_dom')!.visualTone(activePact: false),
        RelationshipConnectionVisualTone.red,
      );
      expect(
        model.getEdge('r_alpha', 'r_dom')!.tierWithPactStatus(),
        RelationshipTier.toxicFeud,
      );
      expect(model.canForgeBloodBrothersPact('r_alpha', 'r_dom'), isFalse);
    });

    test('calculateOverallTeamChemistry i evaluateLineupChemistry reagują na konflikty i pakty', () {
      var model = _buildSampleLockerRoomModel();
      model = model
          .applyInteractionEvent(
            riderAId: 'r_alpha',
            riderBId: 'r_dom',
            eventType: RelationshipEventType.winningLeadOut,
            scoreDelta: 70,
            summary: 'Idealne rozprowadzenie',
            dateIso: '2026-05-01',
            incrementSharedRaces: 5,
          )
          .updatedModel
          .forgeBloodBrothersPact(
            riderAId: 'r_alpha',
            riderBId: 'r_dom',
            dateIso: '2026-05-02',
            raceName: 'Giro',
          )
          .updatedModel;

      // Dodaj toksyczny konflikt między liderami
      model = model
          .applyInteractionEvent(
            riderAId: 'r_alpha',
            riderBId: 'r_rival',
            eventType: RelationshipEventType.leadershipClash,
            scoreDelta: -65,
            summary: 'Otwarta wojna o rolę lidera #1',
            dateIso: '2026-05-05',
          )
          .updatedModel;

      final summary = model.calculateOverallTeamChemistry();
      expect(summary.activeBloodBrothersCount, 1);
      expect(summary.toxicFeudsCount, 1);
      expect(summary.atmosphere, LockerRoomAtmosphere.fractured);

      final singleLineup = model.evaluateLineupChemistry(const <String>['r_alpha']);
      expect(singleLineup.lineupChemistryScore, 50.0);

      final conflictedLineup = model.evaluateLineupChemistry(
        const <String>['r_alpha', 'r_dom', 'r_rival'],
      );
      expect(conflictedLineup.activeBloodBrothersPairsCount, 1);
      expect(conflictedLineup.toxicPairsCount, 1);
      expect(conflictedLineup.sabotageRiskPct, greaterThan(0.0));
      expect(conflictedLineup.conflictWarnings, isNotEmpty);
    });

    test('serializacja JSON zachowuje 1:1 profile, krawędzie, pakty i historię', () {
      var model = _buildSampleLockerRoomModel();
      model = model
          .applyInteractionEvent(
            riderAId: 'r_vet',
            riderBId: 'r_kid',
            eventType: RelationshipEventType.trainingCampBonding,
            scoreDelta: 75,
            summary: 'Mentoring na Teneryfie',
            dateIso: '2026-02-20',
            incrementSharedRaces: 5,
          )
          .updatedModel
          .forgeBloodBrothersPact(
            riderAId: 'r_vet',
            riderBId: 'r_kid',
            dateIso: '2026-02-21',
            raceName: 'Vuelta a Andalucía',
          )
          .updatedModel;

      final restored = RiderRelationshipChemistryWebModel.fromJson(
        model.toJson(),
      );

      expect(restored.teamId, model.teamId);
      expect(restored.seasonYear, model.seasonYear);
      expect(restored.profiles.length, model.profiles.length);
      expect(restored.edges.length, model.edges.length);
      expect(restored.bloodBrothersPacts.length, 1);
      expect(restored.recentEvents.length, model.recentEvents.length);
      expect(restored.getScore('r_vet', 'r_kid'), model.getScore('r_vet', 'r_kid'));
    });
  });

  group('TeamChemistryWebLayoutCalculator & TeamChemistryRelationshipWebWidget', () {
    test('wylicza układ kołowy, filtruje krawędzie i obsługuje hit-testing', () {
      var model = _buildSampleLockerRoomModel();
      model = model
          .applyInteractionEvent(
            riderAId: 'r_alpha',
            riderBId: 'r_dom',
            eventType: RelationshipEventType.winningLeadOut,
            scoreDelta: 75,
            summary: 'Pakt zwycięstwa',
            dateIso: '2026-03-01',
            incrementSharedRaces: 5,
          )
          .updatedModel
          .forgeBloodBrothersPact(
            riderAId: 'r_alpha',
            riderBId: 'r_dom',
            dateIso: '2026-03-02',
            raceName: 'Tirreno',
          )
          .updatedModel
          .applyInteractionEvent(
            riderAId: 'r_alpha',
            riderBId: 'r_rival',
            eventType: RelationshipEventType.tacticalBetrayal,
            scoreDelta: -55,
            summary: 'Zgrzyt na etapie',
            dateIso: '2026-03-03',
          )
          .updatedModel;

      const canvasSize = Size(420, 420);
      final nodes = TeamChemistryWebLayoutCalculator.computeNodeLayouts(
        model: model,
        size: canvasSize,
      );
      expect(nodes.length, 5);
      // Kapitan szosy jest pierwszy (na górze okręgu)
      expect(nodes.first.riderId, 'r_alpha');

      final goldEdges = TeamChemistryWebLayoutCalculator.computeVisibleEdges(
        model: model,
        nodes: nodes,
        size: canvasSize,
        filter: RelationshipWebToneFilter.goldOnly,
      );
      expect(goldEdges.length, 1);
      expect(goldEdges.first.tone, RelationshipConnectionVisualTone.gold);

      final conflictEdges = TeamChemistryWebLayoutCalculator.computeVisibleEdges(
        model: model,
        nodes: nodes,
        size: canvasSize,
        filter: RelationshipWebToneFilter.conflictsOnly,
      );
      expect(conflictEdges.length, 1);
      expect(conflictEdges.first.tone, RelationshipConnectionVisualTone.red);

      final hitNode = TeamChemistryWebLayoutCalculator.hitTestNode(
        position: nodes.first.center,
        nodes: nodes,
      );
      expect(hitNode?.riderId, nodes.first.riderId);

      final hitEdge = TeamChemistryWebLayoutCalculator.hitTestEdge(
        position: goldEdges.first.pointAt(0.5),
        edges: goldEdges,
      );
      expect(hitEdge, isNotNull);
    });

    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'TeamChemistryRelationshipWebWidget renderuje się bez przepełnień na ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          final model = _buildSampleLockerRoomModel();
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: TeamChemistryRelationshipWebWidget(
                    model: model,
                    enableAmbientAnimation: false,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(TeamChemistryRelationshipWebWidget), findsOneWidget);
          expect(find.byType(CustomPaint), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('obsługuje stan disabled oraz przełączanie filtrów połączeń', (
      WidgetTester tester,
    ) async {
      final model = _buildSampleLockerRoomModel();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TeamChemistryRelationshipWebWidget(
                model: model,
                enabled: false,
                enableAmbientAnimation: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      // Włączony tryb i kliknięcie filtra Blood Brothers
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TeamChemistryRelationshipWebWidget(
                model: model,
                enabled: true,
                enableAmbientAnimation: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Blood Brothers').first);
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
    });
  });

  group('WhatIfTacticalSandboxSimulator — Symulator scenariuszy What-If', () {
    test('buildDefault20Variants generuje 20 wariantów i simulateVariantsSync mieści się w budżecie < 1500 ms', () {
      final stage = WhatIfTacticalSandboxSimulator.defaultStageContext();
      final rider = WhatIfTacticalSandboxSimulator.defaultRiderProfile();
      final variants =
          WhatIfTacticalSandboxSimulator.buildDefault20Variants(stage);

      expect(variants.length, 20);

      final report = WhatIfTacticalSandboxSimulator.simulateVariantsSync(
        stageContext: stage,
        riderProfile: rider,
        variants: variants,
        runsPerVariant: 100,
      );

      expect(report.variantsCount, 20);
      expect(report.runsPerVariant, 100);
      expect(report.totalSimulationsRun, 2000);
      expect(report.metLatencyBudget, isTrue);
      expect(
        report.elapsedMs,
        lessThan(WhatIfTacticalSandboxSimulator.maxLatencyBudgetMs),
      );
      expect(report.bestWinVariantId, isNotEmpty);
      expect(report.bestSafeVariantId, isNotEmpty);

      for (final outcome in report.outcomes) {
        expect(outcome.winProbability, inInclusiveRange(0.0, 1.0));
        expect(outcome.podiumProbability, inInclusiveRange(0.0, 1.0));
        expect(outcome.top10Probability, inInclusiveRange(0.0, 1.0));
        expect(outcome.p10TimeGapSeconds, lessThanOrEqualTo(outcome.p50TimeGapSeconds));
        expect(outcome.p50TimeGapSeconds, lessThanOrEqualTo(outcome.p90TimeGapSeconds));
        expect(outcome.samples.length, 100);
      }
    });

    test('symulacja jest deterministyczna dla tego samego seeda i wrażliwa na zmianę pogody', () {
      final dryStage = WhatIfTacticalSandboxSimulator.defaultStageContext();
      final wetStage = dryStage.copyWith(
        weather: WhatIfWeatherCondition.heavyRain,
        crosswindProbability: 0.85,
      );
      final rider = WhatIfTacticalSandboxSimulator.defaultRiderProfile();
      final variants = WhatIfTacticalSandboxSimulator.buildDefault20Variants(dryStage)
          .take(5)
          .toList(growable: false);

      final reportA = WhatIfTacticalSandboxSimulator.simulateVariantsSync(
        stageContext: dryStage,
        riderProfile: rider,
        variants: variants,
        runsPerVariant: 40,
      );
      final reportB = WhatIfTacticalSandboxSimulator.simulateVariantsSync(
        stageContext: dryStage,
        riderProfile: rider,
        variants: variants,
        runsPerVariant: 40,
      );
      final reportWet = WhatIfTacticalSandboxSimulator.simulateVariantsSync(
        stageContext: wetStage,
        riderProfile: rider,
        variants: variants,
        runsPerVariant: 40,
      );

      expect(
        reportA.outcomes.first.p50TimeGapSeconds,
        reportB.outcomes.first.p50TimeGapSeconds,
      );
      // Deszcz i boczny wiatr zwiększają średnie ryzyko incydentu w peletonie
      final avgIncidentDry = reportA.outcomes
              .map((o) => o.incidentRiskProbability)
              .reduce((a, b) => a + b) /
          reportA.outcomes.length;
      final avgIncidentWet = reportWet.outcomes
              .map((o) => o.incidentRiskProbability)
              .reduce((a, b) => a + b) /
          reportWet.outcomes.length;
      expect(avgIncidentWet, greaterThanOrEqualTo(avgIncidentDry));
    });

    test('WhatIfSandboxNotifier zarządza stanem, filtrami i symulacją w tle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(whatIfSandboxProvider.notifier);
      expect(container.read(whatIfSandboxProvider).report, isNotNull);

      notifier.selectTerrain(WhatIfStageTerrainProfile.cobbleMonument);
      expect(
        container.read(whatIfSandboxProvider).stageContext.terrain,
        WhatIfStageTerrainProfile.cobbleMonument,
      );

      notifier.selectWeather(WhatIfWeatherCondition.alpineHeat);
      expect(
        container.read(whatIfSandboxProvider).stageContext.weather,
        WhatIfWeatherCondition.alpineHeat,
      );

      notifier.setRunsPerVariant(60);
      expect(container.read(whatIfSandboxProvider).runsPerVariant, 60);

      notifier.setFilterRisk(WhatIfRiskLevel.aggressive);
      expect(
        container.read(whatIfSandboxProvider).filterRiskLevel,
        WhatIfRiskLevel.aggressive,
      );

      notifier.selectVariant('var_04');
      notifier.updateSelectedVariantEffort(118.0);
      final modified = container
          .read(whatIfSandboxProvider)
          .variants
          .firstWhere((v) => v.id == 'var_04');
      expect(modified.effortPercentFtp, 118.0);

      await notifier.runSimulationInBackground();
      final afterBg = container.read(whatIfSandboxProvider);
      expect(afterBg.isRunning, isFalse);
      expect(afterBg.errorMessage, isNull);
      expect(afterBg.report?.runsPerVariant, 60);
    });

    test('integracja symulatora What-If z kalkulatorem pudełkowym H2H', () {
      final stage = WhatIfTacticalSandboxSimulator.defaultStageContext();
      final rider = WhatIfTacticalSandboxSimulator.defaultRiderProfile();
      final variants = WhatIfTacticalSandboxSimulator.buildDefault20Variants(stage)
          .take(4)
          .toList(growable: false);

      final report = WhatIfTacticalSandboxSimulator.simulateVariantsSync(
        stageContext: stage,
        riderProfile: rider,
        variants: variants,
        runsPerVariant: 50,
      );

      final statsA = WhatIfBoxPlotCalculator.computeStats(
        outcome: report.outcomes.first,
        metric: WhatIfComparatorMetric.timeGapSeconds,
      );
      final statsB = WhatIfBoxPlotCalculator.computeStats(
        outcome: report.outcomes.last,
        metric: WhatIfComparatorMetric.timeGapSeconds,
      );

      final delta = WhatIfBoxPlotCalculator.computeHeadToHeadDelta(statsA, statsB);
      expect(delta.primary.variantId, statsA.variantId);
      expect(delta.challenger.variantId, statsB.variantId);
      expect(statsA.min, lessThanOrEqualTo(statsA.median));
      expect(statsA.median, lessThanOrEqualTo(statsA.max));
    });

    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'WhatIfTacticalSandboxPanel renderuje się bez przepełnień na ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const Scaffold(
                  body: WhatIfTacticalSandboxPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(WhatIfTacticalSandboxPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
