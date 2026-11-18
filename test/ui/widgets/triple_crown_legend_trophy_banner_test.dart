// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/services/career/historical_grand_tour_winners_timeline_db.dart';
import 'package:pro_peloton_manager/ui/widgets/triple_crown_legend_trophy_banner.dart';

TripleCrownWinnerRecord _buildSampleRecord({bool isPlayerManaged = true}) {
  return TripleCrownWinnerRecord(
    year: 2027,
    riderId: 'rider_player_01',
    riderName: 'Kacper Kowalski',
    countryCode: 'POL',
    countryName: 'Polska',
    teamId: 'team_player',
    teamName: 'Orzeł WorldTeam',
    giroEntry: HistoricalRaceWinnerEntry(
      id: '2027_giro',
      year: 2027,
      raceId: HistoricalTimelineRaceId.giroDItalia,
      riderId: 'rider_player_01',
      riderName: 'Kacper Kowalski',
      countryCode: 'POL',
      countryName: 'Polska',
      teamId: 'team_player',
      teamName: 'Orzeł WorldTeam',
      winningMarginSeconds: 142,
      averageSpeedKmh: 41.8,
      isPlayerTeam: isPlayerManaged,
      isPlayerRider: isPlayerManaged,
      editionNotes: 'Rzym — dominacja w Dolomitach',
    ),
    tourEntry: HistoricalRaceWinnerEntry(
      id: '2027_tour',
      year: 2027,
      raceId: HistoricalTimelineRaceId.tourDeFrance,
      riderId: 'rider_player_01',
      riderName: 'Kacper Kowalski',
      countryCode: 'POL',
      countryName: 'Polska',
      teamId: 'team_player',
      teamName: 'Orzeł WorldTeam',
      winningMarginSeconds: 215,
      averageSpeedKmh: 42.4,
      isPlayerTeam: isPlayerManaged,
      isPlayerRider: isPlayerManaged,
      editionNotes: 'Paryż — atak na Col du Galibier',
    ),
    worldsRoadEntry: HistoricalRaceWinnerEntry(
      id: '2027_worlds',
      year: 2027,
      raceId: HistoricalTimelineRaceId.worldChampionshipRoadRace,
      riderId: 'rider_player_01',
      riderName: 'Kacper Kowalski',
      countryCode: 'POL',
      countryName: 'Polska',
      teamId: 'team_player',
      teamName: 'Orzeł WorldTeam',
      winningMarginSeconds: 34,
      averageSpeedKmh: 43.6,
      isPlayerTeam: isPlayerManaged,
      isPlayerRider: isPlayerManaged,
      editionNotes: 'Haute-Savoie — 65 km samotnej ucieczki',
    ),
    totalTimelineWinsInYear: 5,
  );
}

void main() {
  group('TripleCrownBannerData & Notifier', () {
    test('builds from TripleCrownWinnerRecord and round-trips JSON', () {
      final record = _buildSampleRecord();
      final data = TripleCrownBannerData.fromRecord(record, historicalRank: 4);

      expect(data.riderName, 'Kacper Kowalski');
      expect(data.seasonYear, 2027);
      expect(data.isPlayerManaged, isTrue);
      expect(data.isCompleteTripleCrown, isTrue);
      expect(data.giroLeg.formattedMargin, "+2'22\"");
      expect(data.worldsLeg.formattedMargin, '+34 s');
      expect(data.tourLeg.formattedSpeed, '42.4 km/h');

      final roundTrip = TripleCrownBannerData.fromJson(data.toJson());
      expect(roundTrip.riderId, data.riderId);
      expect(roundTrip.riderName, data.riderName);
      expect(roundTrip.seasonYear, data.seasonYear);
      expect(roundTrip.historicalRank, 4);
      expect(roundTrip.tourLeg.averageSpeedKmh, 42.4);
    });

    test('TripleCrownCelebrationNotifier manages lifecycle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tripleCrownCelebrationProvider.notifier);
      expect(container.read(tripleCrownCelebrationProvider).isVisible, isFalse);

      // Ignores non-player-managed record
      notifier.showFromRecord(_buildSampleRecord(isPlayerManaged: false));
      expect(container.read(tripleCrownCelebrationProvider).isVisible, isFalse);

      // Accepts player-managed record
      notifier.showFromRecord(_buildSampleRecord(isPlayerManaged: true));
      expect(container.read(tripleCrownCelebrationProvider).isVisible, isTrue);

      notifier.selectLeg(TripleCrownLegId.tourDeFrance);
      expect(
        container.read(tripleCrownCelebrationProvider).selectedLeg,
        TripleCrownLegId.tourDeFrance,
      );
      expect(
        container.read(tripleCrownCelebrationProvider).isExpanded,
        isTrue,
      );

      notifier.claimTrophy();
      expect(
        container
            .read(tripleCrownCelebrationProvider)
            .activeBanner
            ?.isTrophyClaimed,
        isTrue,
      );

      notifier.dismiss();
      expect(container.read(tripleCrownCelebrationProvider).isVisible, isFalse);
    });
  });

  group('TripleCrownLegendTrophyBanner Widget', () {
    for (final size in const [
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

          final data = TripleCrownBannerData.fromRecord(_buildSampleRecord());
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: TripleCrownLegendTrophyBanner(
                    data: data,
                    onClaimTrophy: () {},
                    onOpenHallOfFame: () {},
                    onDismiss: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Kacper Kowalski'), findsOneWidget);
          expect(find.text('Odbierz Trofeum'), findsOneWidget);
          expect(find.text('Aleja Legend'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('supports leg selection, claim trophy and callbacks',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var claimed = false;
      var hallOpened = false;
      var dismissed = false;
      TripleCrownLegId? selectedLeg;

      final data = TripleCrownBannerData.fromRecord(_buildSampleRecord());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TripleCrownLegendTrophyBanner(
                data: data,
                onClaimTrophy: () => claimed = true,
                onOpenHallOfFame: () => hallOpened = true,
                onDismiss: () => dismissed = true,
                onLegSelected: (leg) => selectedLeg = leg,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text("Giro d'Italia"));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selectedLeg, TripleCrownLegId.giroDItalia);
      expect(find.textContaining('Rzym — dominacja w Dolomitach'), findsOneWidget);

      await tester.tap(find.text('Odbierz Trofeum'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(claimed, isTrue);
      expect(find.text('Trofeum w Gablocie'), findsOneWidget);

      await tester.tap(find.text('Aleja Legend'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(hallOpened, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(dismissed, isTrue);
    });

    testWidgets('handles null, non-player and disabled states gracefully',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TripleCrownLegendTrophyBanner(data: null),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('Brak aktywnego osiągnięcia'),
        findsOneWidget,
      );

      final nonPlayerData = TripleCrownBannerData.fromRecord(
        _buildSampleRecord(isPlayerManaged: false),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripleCrownLegendTrophyBanner(
              data: nonPlayerData,
              showOnlyForPlayerManaged: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('zdobyta przez rywala'), findsOneWidget);

      final playerData = TripleCrownBannerData.fromRecord(_buildSampleRecord());
      var claimedWhenDisabled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TripleCrownLegendTrophyBanner(
                data: playerData,
                isEnabled: false,
                onClaimTrophy: () => claimedWhenDisabled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Odbierz Trofeum'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(claimedWhenDisabled, isFalse);
    });
  });
}
