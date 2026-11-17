// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/services/career/world_records_and_strava_kom_segments.dart';

void main() {
  group('WorldRecordsAndStravaKomSegments', () {
    test('seeds iconic climbs and cobble sectors with KOM Crown holders', () {
      final kom = WorldRecordsAndStravaKomSegments();

      expect(kom.totalSegmentsCount, greaterThanOrEqualTo(12));
      expect(kom.getSegment('poggio_di_sanremo'), isNotNull);
      expect(kom.getSegment('mur_de_huy'), isNotNull);
      expect(kom.getSegment('alpe_d_huez'), isNotNull);
      expect(kom.getSegment('col_du_tourmalet'), isNotNull);
      expect(kom.getSegment('trouee_d_arenberg'), isNotNull);

      final alpeLeaderboard = kom.getLeaderboard('alpe_d_huez');
      expect(alpeLeaderboard.length, greaterThanOrEqualTo(2));
      expect(alpeLeaderboard.first.isCurrentKomCrownHolder, isTrue);
      expect(alpeLeaderboard.first.rank, 1);
      expect(alpeLeaderboard.first.formattedDelta, 'KOM');
      expect(alpeLeaderboard.first.effort.riderName, 'Marco Pantani');
      expect(alpeLeaderboard.first.effort.formattedTime, '37:35');
      expect(alpeLeaderboard[1].isCurrentKomCrownHolder, isFalse);
      expect(alpeLeaderboard[1].deltaSecondsToKom, greaterThan(0));
    });

    test('registers virtual KOM segments automatically from StageSegment list',
        () {
      final kom = WorldRecordsAndStravaKomSegments(seedIconicSegments: false);
      final stageSegments = [
        const StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 20.0,
          startElevationM: 100.0,
          endElevationM: 120.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 10.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
        const StageSegment(
          index: 1,
          startKm: 20.0,
          lengthKm: 8.5,
          startElevationM: 200.0,
          endElevationM: 920.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 45.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.cat1,
        ),
        const StageSegment(
          index: 2,
          startKm: 28.5,
          lengthKm: 2.4,
          startElevationM: 920.0,
          endElevationM: 925.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          technicalDifficulty: 95.0,
          windDirectionDegrees: 0.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
      ];

      final registered = kom.registerFromStageSegments(
        raceId: 'tdf_s12',
        raceName: 'Tour de France Etap 12',
        countryCode: 'FRA',
        segments: stageSegments,
      );

      expect(registered.length, 2);
      expect(registered[0].category, KomSegmentCategory.alpineHcClimb);
      expect(registered[1].category, KomSegmentCategory.cobbleSector);
      expect(registered[1].cobbleDifficultyStars, 5);
    });

    test('records passage to the second and transfers KOM Crown on new record',
        () {
      final kom = WorldRecordsAndStravaKomSegments();

      final slowerResult = kom.recordPassage(
        KomPassageInput(
          segmentId: 'mur_de_huy',
          riderId: 'pl_1',
          riderName: 'Jan Kowalski',
          riderNationality: 'POL',
          teamId: 'team_pl',
          teamName: 'Polonia Pro Cycling',
          isPlayerTeam: true,
          seasonYear: 2026,
          raceName: 'La Flèche Wallonne',
          recordedAt: DateTime.utc(2026, 4, 22, 16, 15),
          rawDurationSeconds: 170.0,
          averagePowerWatts: 460.0,
          riderWeightKg: 65.0,
        ),
      );

      expect(slowerResult.isNewKomCrown, isFalse);
      expect(slowerResult.isPersonalBest, isTrue);
      expect(slowerResult.assignedRank, 3);
      expect(kom.countPlayerTeamKomCrowns(), 0);

      final crownResult = kom.recordPassage(
        KomPassageInput(
          segmentId: 'mur_de_huy',
          riderId: 'pl_1',
          riderName: 'Jan Kowalski',
          riderNationality: 'POL',
          teamId: 'team_pl',
          teamName: 'Polonia Pro Cycling',
          isPlayerTeam: true,
          seasonYear: 2027,
          raceName: 'La Flèche Wallonne',
          recordedAt: DateTime.utc(2027, 4, 21, 16, 12),
          rawDurationSeconds: 158.0, // 2:38 beats 2:42
          averagePowerWatts: 510.0,
          riderWeightKg: 65.0,
        ),
      );

      expect(crownResult.isNewKomCrown, isTrue);
      expect(crownResult.assignedRank, 1);
      expect(crownResult.brokenEvent, isNotNull);
      expect(crownResult.brokenEvent!.secondsImproved, 4);
      expect(kom.countPlayerTeamKomCrowns(), 1);
      expect(
        kom.getCurrentKomCrownHolder('mur_de_huy')?.riderName,
        'Jan Kowalski',
      );
      expect(
        kom.getSegmentsWithKomCrownForRider('pl_1').map((s) => s.segmentId),
        contains('mur_de_huy'),
      );
    });

    test('serializes and deserializes losslessly via JSON', () {
      final kom = WorldRecordsAndStravaKomSegments();
      kom.recordPassage(
        KomPassageInput(
          segmentId: 'poggio_di_sanremo',
          riderId: 'pl_2',
          riderName: 'Marek Nowak',
          teamId: 'team_pl',
          teamName: 'Polonia Pro Cycling',
          isPlayerTeam: true,
          seasonYear: 2026,
          raceName: 'Milano-Sanremo',
          recordedAt: DateTime.utc(2026, 3, 21, 16, 40),
          rawDurationSeconds: 320.0,
          averagePowerWatts: 490.0,
          riderWeightKg: 72.0,
        ),
      );

      final json = kom.toJson();
      final restored = WorldRecordsAndStravaKomSegments.fromJson(json);

      expect(restored.totalSegmentsCount, kom.totalSegmentsCount);
      expect(restored.totalEffortsCount, kom.totalEffortsCount);
      expect(
        restored.getCurrentKomCrownHolder('poggio_di_sanremo')?.riderName,
        'Marek Nowak',
      );
      expect(restored.recentBrokenEvents.length, 1);
    });
  });

  group('WorldRecordsAndStravaKomPanel Responsive UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      bool isEnabled = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WorldRecordsAndStravaKomPanel(
                isEnabled: isEnabled,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly without overflow at 390x844 (mobile)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('SEGMENTY KOM & REKORDY WSZECH CZASÓW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 1024x768 (tablet)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('SEGMENTY KOM & REKORDY WSZECH CZASÓW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 1600x900 (desktop)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('SEGMENTY KOM & REKORDY WSZECH CZASÓW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filters by category, search query, and shows broken KOM banner',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: WorldRecordsAndStravaKomPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      container.read(worldRecordsAndStravaKomProvider.notifier).recordPassage(
            KomPassageInput(
              segmentId: 'poggio_di_sanremo',
              riderId: 'pl_99',
              riderName: 'Kacper Zieliński',
              teamId: 'team_pl',
              teamName: 'Polonia Pro Cycling',
              isPlayerTeam: true,
              seasonYear: 2026,
              raceName: 'Milano-Sanremo',
              recordedAt: DateTime.utc(2026, 3, 21, 16, 45),
              rawDurationSeconds: 321.0,
              averagePowerWatts: 500.0,
              riderWeightKg: 73.0,
            ),
          );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('NOWA KORONA KOM!'), findsOneWidget);

      await tester.tap(find.text('Sektory Bruku'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text("Trouée d'Arenberg"), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports disabled state gracefully', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768), isEnabled: false);
      expect(find.text('SEGMENTY KOM & REKORDY WSZECH CZASÓW'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
