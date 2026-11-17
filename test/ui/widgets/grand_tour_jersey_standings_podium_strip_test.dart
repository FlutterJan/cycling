import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/ui/widgets/grand_tour_jersey_standings_podium_strip.dart';

void main() {
  group('GrandTourJerseyStandingsData', () {
    test('fromRaceClassifications builds 4 holders with gaps', () {
      const classifications = RaceClassifications(
        generalClassification: [
          RiderClassificationEntry(
            riderId: 'r1',
            riderName: 'T. Pogačar',
            teamId: 'uae',
            totalTimeSeconds: 180000,
            points: 0,
            rank: 1,
            timeBehindLeaderSeconds: 0,
          ),
          RiderClassificationEntry(
            riderId: 'r2',
            riderName: 'J. Vingegaard',
            teamId: 'vis',
            totalTimeSeconds: 180045,
            points: 0,
            rank: 2,
            timeBehindLeaderSeconds: 45,
          ),
        ],
        pointsClassification: [
          RiderClassificationEntry(
            riderId: 'r3',
            riderName: 'B. Girmay',
            teamId: 'iwa',
            totalTimeSeconds: 0,
            points: 250,
            rank: 1,
            timeBehindLeaderSeconds: 0,
          ),
          RiderClassificationEntry(
            riderId: 'r4',
            riderName: 'J. Philipsen',
            teamId: 'adc',
            totalTimeSeconds: 0,
            points: 210,
            rank: 2,
            timeBehindLeaderSeconds: 0,
          ),
        ],
        mountainsClassification: [
          RiderClassificationEntry(
            riderId: 'r5',
            riderName: 'R. Carapaz',
            teamId: 'efe',
            totalTimeSeconds: 0,
            points: 95,
            rank: 1,
            timeBehindLeaderSeconds: 0,
          ),
        ],
        youthClassification: [
          RiderClassificationEntry(
            riderId: 'r6',
            riderName: 'R. Evenepoel',
            teamId: 'soq',
            totalTimeSeconds: 180200,
            points: 0,
            rank: 1,
            timeBehindLeaderSeconds: 0,
          ),
        ],
        teamClassification: [],
      );

      final data = GrandTourJerseyStandingsData.fromRaceClassifications(
        edition: GrandTourEdition.tourDeFrance,
        stageNumber: 12,
        stageName: 'Alpe d\'Huez',
        kmRemaining: 8.5,
        classifications: classifications,
        playerTeamId: 'uae',
        teamNamesById: const {
          'uae': 'UAE Team Emirates',
          'iwa': 'Intermarché-Wanty',
          'efe': 'EF Education',
          'soq': 'Soudal Quick-Step',
        },
        virtualChangedJerseys: const {
          GrandTourJerseyClassification.mountainsClassification,
        },
      );

      expect(data.holders.length, 4);
      expect(data.holders[0].isPlayerTeam, isTrue);
      expect(data.holders[0].formattedAdvantageOverSecond(), '+45s nad #2');
      expect(data.holders[1].formattedAdvantageOverSecond(), '+40 pkt nad #2');
      expect(data.holders[2].isVirtualLeaderChange, isTrue);
      expect(data.holders[3].teamCode, 'SOU');
    });
  });

  group('GrandTourJerseyStandingsPodiumStrip widget', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size,
      Widget child,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final Size viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          final data = GrandTourJerseyStandingsData.sample(
            edition: GrandTourEdition.tourDeFrance,
            mode: GrandTourStripMode.liveRace,
          );

          await pumpAtSize(
            tester,
            viewport,
            GrandTourJerseyStandingsPodiumStrip(
              data: data,
              mode: GrandTourStripMode.liveRace,
              showModeToggle: true,
              onModeChanged: (_) {},
              onOpenFullStandings: () {},
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.text('T. Pogačar'), findsOneWidget);
          expect(find.text('B. Girmay'), findsOneWidget);
          expect(find.text('R. Carapaz'), findsOneWidget);
          expect(find.text('R. Evenepoel'), findsOneWidget);
        },
      );
    }

    testWidgets('selects jersey card and switches between live and podium', (
      tester,
    ) async {
      GrandTourStripMode currentMode = GrandTourStripMode.liveRace;
      GrandTourJerseyHolder? tappedHolder;
      bool fullStandingsOpened = false;

      await pumpAtSize(
        tester,
        const Size(1280, 800),
        StatefulBuilder(
          builder: (context, setState) {
            return GrandTourJerseyStandingsPodiumStrip(
              data: GrandTourJerseyStandingsData.sample(
                edition: GrandTourEdition.giroDItalia,
                mode: currentMode,
              ),
              mode: currentMode,
              showModeToggle: true,
              onModeChanged: (next) => setState(() => currentMode = next),
              onJerseySelected: (holder) => tappedHolder = holder,
              onOpenFullStandings: () => fullStandingsOpened = true,
            );
          },
        ),
      );

      expect(find.text('KLASYFIKACJE NA ŻYWO'), findsOneWidget);

      await tester.tap(find.text('R. Carapaz'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tappedHolder?.riderId, 'r_kom_1');
      expect(find.textContaining('2. miejsce: J. Vingegaard'), findsOneWidget);

      await tester.tap(find.text('Podium'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CEREMONIA PODIUM'), findsOneWidget);

      await tester.tap(find.text('Pełna klasyfikacja'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(fullStandingsOpened, isTrue);
    });

    testWidgets('handles disabled state and empty holders cleanly', (
      tester,
    ) async {
      GrandTourJerseyHolder? tapped;
      await pumpAtSize(
        tester,
        const Size(1024, 768),
        Column(
          children: [
            GrandTourJerseyStandingsPodiumStrip(
              data: GrandTourJerseyStandingsData.sample(),
              mode: GrandTourStripMode.podiumCeremony,
              isEnabled: false,
              onJerseySelected: (h) => tapped = h,
            ),
            const SizedBox(height: 16),
            const GrandTourJerseyStandingsPodiumStrip(
              data: GrandTourJerseyStandingsData(
                edition: GrandTourEdition.vueltaAEspana,
                stageNumber: 1,
                stageName: 'Etap 1',
                holders: [],
              ),
              mode: GrandTourStripMode.liveRace,
            ),
          ],
        ),
      );

      await tester.tap(find.text('T. Pogačar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tapped, isNull);
      expect(
        find.text('Brak aktywnych klasyfikacji koszulek dla tego etapu.'),
        findsOneWidget,
      );
    });
  });
}
