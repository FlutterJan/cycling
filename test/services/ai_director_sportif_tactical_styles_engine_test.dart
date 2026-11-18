// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/ai_director_sportif_tactical_styles_engine.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

void main() {
  group('AiDirectorSportifTacticalStylesEngine', () {
    test('covers all 53 world presets and returns 52 unique AI teams', () {
      final presets = AiDirectorSportifTacticalStylesEngine.allPresetProfiles;
      expect(presets.length, 53);

      final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 7);
      final worldTeamIds = world.teams.map((t) => t.id).toSet();
      final dsTeamIds = presets.map((p) => p.teamId).toSet();
      expect(dsTeamIds, equals(worldTeamIds));

      // Unikalność dyrektorów sportowych i nazw stylów taktycznych
      final directorNames = presets.map((p) => p.directorName).toSet();
      final codenames = presets.map((p) => p.styleCodename).toSet();
      expect(directorNames.length, 53);
      expect(codenames.length, 53);

      final ai52 = AiDirectorSportifTacticalStylesEngine.getAiTeamsProfiles(
        excludePlayerTeamId: 'team_polonia_orlen',
      );
      expect(ai52.length, 52);
      expect(ai52.any((p) => p.teamId == 'team_polonia_orlen'), isFalse);
    });

    test('deterministically generates profile for custom player/AI team', () {
      final a = AiDirectorSportifTacticalStylesEngine.getProfileForTeam(
        'custom_team_alpha',
        teamName: 'Alpha Velo',
        division: TeamDivision.proTeam,
        countryIso: 'POL',
      );
      final b = AiDirectorSportifTacticalStylesEngine.getProfileForTeam(
        'custom_team_alpha',
        teamName: 'Alpha Velo',
        division: TeamDivision.proTeam,
        countryIso: 'POL',
      );
      expect(a, equals(b));
      expect(a.teamId, 'custom_team_alpha');
      expect(a.tendencies.tacticalAggressionIndex, inInclusiveRange(5, 99));
    });

    test('evaluates stage plans accurately for mountain, sprint and crosswind', () {
      final skyProfile = AiDirectorSportifTacticalStylesEngine.getProfileForTeam(
        'team_aethel_ineos',
      );
      final mountainPlan = AiDirectorSportifTacticalStylesEngine.evaluateStagePlan(
        skyProfile,
        const StageTacticalContextInput(
          stageName: 'Col du Galibier',
          terrain: DsStageTerrainFocus.highMountain,
          distanceKm: 178.0,
          remainingKm: 178.0,
          crosswindKmh: 10.0,
          elevationGainM: 4200,
          isGrandTour: true,
          rivalInBreakawayThreat: true,
          leaderGcGapSeconds: 60.0,
        ),
      );
      expect(mountainPlan.recommendedTempoPctFtp, greaterThan(88.0));
      expect(mountainPlan.domestiquesCommittedToPace, greaterThanOrEqualTo(4));

      final nordicProfile =
          AiDirectorSportifTacticalStylesEngine.getProfileForTeam(
        'team_nordic_nor',
      );
      final windPlan = AiDirectorSportifTacticalStylesEngine.evaluateStagePlan(
        nordicProfile,
        const StageTacticalContextInput(
          stageName: 'Etap Nadmorski',
          terrain: DsStageTerrainFocus.flatSprint,
          distanceKm: 190.0,
          remainingKm: 190.0,
          crosswindKmh: 38.0,
          elevationGainM: 400,
        ),
      );
      expect(windPlan.echelonAmbushProbability, greaterThanOrEqualTo(0.8));
    });

    test('builds full 52-team peloton matchup report', () {
      final report =
          AiDirectorSportifTacticalStylesEngine.buildPelotonMatchupReport(
        playerTeamId: 'team_polonia_orlen',
        context: const StageTacticalContextInput(
          stageName: 'Flandria Klasyk',
          terrain: DsStageTerrainFocus.cobblesClassic,
          distanceKm: 255.0,
          remainingKm: 255.0,
          crosswindKmh: 28.0,
          elevationGainM: 2100,
          hasCobbleSectors: true,
        ),
      );

      expect(report.rivalTeamCount, 52);
      expect(report.topThreatPlans.length, 10);
      expect(report.expectedBreakawayTeams, isNotEmpty);
      expect(report.expectedEchelonInstigators, isNotEmpty);
    });

    test('serializes and deserializes state JSON cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(aiDirectorSportifTacticalStylesProvider.notifier);
      notifier.setSearchQuery('Velo');
      notifier.setDivisionFilter(TeamDivision.proTeam);
      notifier.evolveTeamStyleAfterSeason(
        teamId: 'team_adria_slo',
        seasonWins: 12,
        gcTop10Count: 4,
        promoted: true,
      );

      final original =
          container.read(aiDirectorSportifTacticalStylesProvider);
      final restored =
          AiDirectorSportifTacticalStylesState.fromJson(original.toJson());

      expect(restored.searchQuery, 'Velo');
      expect(restored.divisionFilter, TeamDivision.proTeam);
      expect(
        restored.customOverrides['team_adria_slo'],
        equals(original.customOverrides['team_adria_slo']),
      );
    });
  });

  group('AiDirectorSportifTacticalStylesPanel UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      bool isReadOnly = false,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: AiDirectorSportifTacticalStylesPanel(
                  isReadOnly: isReadOnly,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844 mobile', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.textContaining('Wywiad Taktyczny'), findsOneWidget);
      expect(find.text('52 / 52 drużyn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1024x768 tablet', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('52 / 52 drużyn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1600x900 desktop & filters',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('52 / 52 drużyn'), findsOneWidget);

      await tester.tap(find.text('WorldTour'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('18 / 52 drużyn'), findsOneWidget);

      await tester.tap(find.text('Płaskie / Sprint'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Prognoza na etap: Płaskie / Sprint'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects isReadOnly disabled state', (tester) async {
      await pumpPanelAtSize(tester, const Size(1200, 800), isReadOnly: true);
      await tester.tap(find.text('WorldTour'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('52 / 52 drużyn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
