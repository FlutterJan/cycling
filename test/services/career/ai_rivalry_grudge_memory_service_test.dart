import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/ai_rivalry_grudge_memory_service.dart';

void main() {
  const service = AiRivalryGrudgeMemoryService();

  group('AiRivalryGrudgeMemoryService', () {
    test('canonicalBondKey is symmetric regardless of rider order', () {
      expect(
        AiRivalryGrudgeMemoryService.canonicalBondKey('r_b', 'r_a'),
        equals(AiRivalryGrudgeMemoryService.canonicalBondKey('r_a', 'r_b')),
      );
    });

    test('recordIncident ignores self-relationships and clamps scores', () {
      var state = AiRivalryGrudgeMemoryState.empty(seasonYear: 2026);

      // Same rider should be ignored
      state = service.recordIncident(
        state,
        riderAId: 'r_1',
        riderBId: 'r_1',
        riderAName: 'Rider 1',
        riderBName: 'Rider 1',
        riderATeam: 'Team A',
        riderBTeam: 'Team A',
        incidentType: RelationshipIncidentType.breakawayBetrayal,
        raceId: 'tdf',
        raceName: 'Tour de France',
      );
      expect(state.bonds, isEmpty);

      // Multiple severe grudges clamp at -100
      for (int i = 0; i < 4; i++) {
        state = service.recordIncident(
          state,
          riderAId: 'r_1',
          riderBId: 'r_2',
          riderAName: 'Rider 1',
          riderBName: 'Rider 2',
          riderATeam: 'Team A',
          riderBTeam: 'Team B',
          incidentType: RelationshipIncidentType.dangerousSprintDeviation,
          raceId: 'race_$i',
          raceName: 'Race $i',
        );
      }

      final key = AiRivalryGrudgeMemoryService.canonicalBondKey('r_1', 'r_2');
      final bond = state.bonds[key]!;
      expect(bond.score, equals(-100.0));
      expect(bond.polarity, equals(PelotonRelationshipPolarity.bloodFeud));
      expect(bond.vendettaActive, isTrue);
      expect(bond.totalGrudgeIncidents, equals(4));
    });

    test('evaluateTacticalModifiers reflects bloodFeud vs pelotonBrotherhood',
        () {
      var state = AiRivalryGrudgeMemoryState.empty(seasonYear: 2026);
      state = service.recordIncident(
        state,
        riderAId: 'r_1',
        riderBId: 'r_2',
        riderAName: 'Rider 1',
        riderBName: 'Rider 2',
        riderATeam: 'Team A',
        riderBTeam: 'Team B',
        incidentType: RelationshipIncidentType.dangerousSprintDeviation,
        raceId: 'rvv',
        raceName: 'Ronde van Vlaanderen',
        customScoreDelta: -75.0,
      );
      state = service.recordIncident(
        state,
        riderAId: 'r_1',
        riderBId: 'r_3',
        riderAName: 'Rider 1',
        riderBName: 'Rider 3',
        riderATeam: 'Team A',
        riderBTeam: 'Team C',
        incidentType: RelationshipIncidentType.sportsmanlikeWaitAfterCrash,
        raceId: 'tdf',
        raceName: 'Tour de France',
        customScoreDelta: 80.0,
      );

      final feudMods = service.evaluateTacticalModifiers(
        state,
        observerRiderId: 'r_2',
        targetRiderId: 'r_1',
      );
      expect(feudMods.chaseAggressionMultiplier, greaterThan(1.3));
      expect(feudMods.breakawayCooperationFactor, lessThan(0.25));
      expect(feudMods.diplomacyAcceptanceBonus, lessThan(-0.3));
      expect(feudMods.transferVetoRisk, isTrue);

      final allyMods = service.evaluateTacticalModifiers(
        state,
        observerRiderId: 'r_1',
        targetRiderId: 'r_3',
      );
      expect(allyMods.chaseAggressionMultiplier, lessThan(1.0));
      expect(allyMods.breakawayCooperationFactor, greaterThan(0.8));
      expect(allyMods.diplomacyAcceptanceBonus, greaterThan(0.2));
      expect(allyMods.transferSalaryDiscountFactor, greaterThan(0.05));
    });

    test('applySeasonTransitionDecay archives old events and preserves feuds',
        () {
      var state = AiRivalryGrudgeMemoryState.empty(seasonYear: 2026);
      state = service.recordIncident(
        state,
        riderAId: 'r_1',
        riderBId: 'r_2',
        riderAName: 'Rider 1',
        riderBName: 'Rider 2',
        riderATeam: 'Team A',
        riderBTeam: 'Team B',
        incidentType: RelationshipIncidentType.dangerousSprintDeviation,
        raceId: 'rvv',
        raceName: 'Ronde',
        customScoreDelta: -80.0,
      );
      state = service.recordIncident(
        state,
        riderAId: 'r_3',
        riderBId: 'r_4',
        riderAName: 'Rider 3',
        riderBName: 'Rider 4',
        riderATeam: 'Team C',
        riderBTeam: 'Team D',
        incidentType: RelationshipIncidentType.podiumRespect,
        raceId: 'msr',
        raceName: 'Milano-Sanremo',
        customScoreDelta: 3.0,
      );

      final result =
          service.applySeasonTransitionDecay(state, newSeasonYear: 2030);
      expect(result.nextState.currentSeasonYear, equals(2030));
      expect(result.report.archivedEventsCount, equals(2));
      expect(result.report.prunedNeutralBondsCount, equals(1));

      final feudKey =
          AiRivalryGrudgeMemoryService.canonicalBondKey('r_1', 'r_2');
      expect(result.nextState.bonds.containsKey(feudKey), isTrue);
      expect(result.nextState.bonds[feudKey]!.score, lessThan(-50.0));
      expect(
        result.nextState.bonds[feudKey]!.events.first.isHistoricalArchive,
        isTrue,
      );
    });

    test('evaluateTeamRosterCompatibility detects toxic conflicts & golden duos',
        () {
      final state = service.createSeededDemoState(seasonYear: 2026);
      final report = service.evaluateTeamRosterCompatibility(
        state,
        ['rider_kwiatek_01', 'rider_vander_02', 'rider_pogacar_03', 'rider_mohoric_05'],
      );
      expect(report.toxicConflicts.length, equals(1));
      expect(report.chemistryModifier, lessThan(0));
    });

    test('JSON serialization round-trip preserves state', () {
      final original = service.createSeededDemoState(seasonYear: 2026);
      final json = original.toJson();
      final restored = AiRivalryGrudgeMemoryState.fromJson(json);

      expect(restored.currentSeasonYear, equals(original.currentSeasonYear));
      expect(
          restored.totalRecordedEvents, equals(original.totalRecordedEvents));
      expect(restored.bonds.length, equals(original.bonds.length));
    });
  });

  group('AiRivalryGrudgeMemoryPanel', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AiRivalryGrudgeMemoryPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844 mobile viewport',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Pamięć Urazów i Przyjaźni Peletonu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1024x768 tablet viewport',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('WPŁYW TAKTYCZNY AI NA SZOSIE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1600x900 desktop viewport',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('KRONIKA ZDARZEŃ'), findsOneWidget);

      await tester.tap(find.text('Urazy i Wendety'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Kwiatkowski'), findsWidgets);

      await tester.tap(find.text('Wygaszenie Sezonu'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Sezon 2027'), findsOneWidget);
    });
  });
}
