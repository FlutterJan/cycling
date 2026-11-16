import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/ui/widgets/peloton_group_composition_analyzer_modal.dart';

PelotonGroupCompositionData _buildSampleGroupData({
  bool includePlayerTeam = true,
  bool includePuller = true,
}) {
  final riders = <PelotonGroupRiderEntry>[
    PelotonGroupRiderEntry(
      riderId: 'r1',
      riderName: 'Tadej Pogacar',
      bibNumber: 1,
      teamCode: 'UAE',
      teamName: 'UAE Team Emirates',
      teamColorHex: '#D4AF37',
      isPlayerTeam: includePlayerTeam,
      isPullingFront: includePuller,
      pullSharePercent: 45.0,
      currentSpeedKmh: 47.4,
      currentWatts: 415,
      wattsPerKg: 6.3,
      heartRateBpm: 174,
      fatiguePercent: 38.0,
      tacticalOrder: includePuller
          ? TacticalOrder.pullGroup
          : TacticalOrder.holdPosition,
      gcGapSeconds: 0.0,
      roleLabel: 'Lider GC',
    ),
    PelotonGroupRiderEntry(
      riderId: 'r2',
      riderName: 'Rafal Majka',
      bibNumber: 2,
      teamCode: 'UAE',
      teamName: 'UAE Team Emirates',
      teamColorHex: '#D4AF37',
      isPlayerTeam: includePlayerTeam,
      isPullingFront: false,
      pullSharePercent: 20.0,
      currentSpeedKmh: 47.2,
      currentWatts: 360,
      wattsPerKg: 5.7,
      heartRateBpm: 166,
      fatiguePercent: 52.0,
      roleLabel: 'Góral',
    ),
    const PelotonGroupRiderEntry(
      riderId: 'r3',
      riderName: 'Joao Almeida',
      bibNumber: 3,
      teamCode: 'UAE',
      teamName: 'UAE Team Emirates',
      teamColorHex: '#D4AF37',
      currentSpeedKmh: 47.1,
      currentWatts: 355,
      wattsPerKg: 5.6,
      heartRateBpm: 164,
      fatiguePercent: 44.0,
    ),
    const PelotonGroupRiderEntry(
      riderId: 'r4',
      riderName: 'Adam Yates',
      bibNumber: 4,
      teamCode: 'UAE',
      teamName: 'UAE Team Emirates',
      teamColorHex: '#D4AF37',
      currentSpeedKmh: 47.0,
      currentWatts: 350,
      wattsPerKg: 5.8,
      heartRateBpm: 162,
      fatiguePercent: 49.0,
    ),
    const PelotonGroupRiderEntry(
      riderId: 'r5',
      riderName: 'Jonas Vingegaard',
      bibNumber: 11,
      teamCode: 'Visma',
      teamName: 'Team Visma | Lease a Bike',
      teamColorHex: '#EAB308',
      currentSpeedKmh: 47.1,
      currentWatts: 390,
      wattsPerKg: 6.2,
      heartRateBpm: 170,
      fatiguePercent: 41.0,
      gcGapSeconds: 18.0,
      roleLabel: 'Lider GC',
    ),
    const PelotonGroupRiderEntry(
      riderId: 'r6',
      riderName: 'Sepp Kuss',
      bibNumber: 12,
      teamCode: 'Visma',
      teamName: 'Team Visma | Lease a Bike',
      teamColorHex: '#EAB308',
      currentSpeedKmh: 46.9,
      currentWatts: 345,
      wattsPerKg: 5.6,
      heartRateBpm: 160,
      fatiguePercent: 58.0,
    ),
    const PelotonGroupRiderEntry(
      riderId: 'r7',
      riderName: 'Matteo Jorgenson',
      bibNumber: 13,
      teamCode: 'Visma',
      teamName: 'Team Visma | Lease a Bike',
      teamColorHex: '#EAB308',
      currentSpeedKmh: 46.8,
      currentWatts: 355,
      wattsPerKg: 5.5,
      heartRateBpm: 163,
      fatiguePercent: 47.0,
    ),
    const PelotonGroupRiderEntry(
      riderId: 'r8',
      riderName: 'Remco Evenepoel',
      bibNumber: 21,
      teamCode: 'SOQ',
      teamName: 'Soudal Quick-Step',
      teamColorHex: '#38BDF8',
      currentSpeedKmh: 46.9,
      currentWatts: 382,
      wattsPerKg: 6.0,
      heartRateBpm: 171,
      fatiguePercent: 46.0,
      gcGapSeconds: 34.0,
    ),
  ];

  return PelotonGroupCompositionData(
    groupId: 'grp_fav',
    groupTitle: 'Grupa Liderów — Col du Galibier',
    groupType: GroupType.breakaway,
    gapToLeaderSeconds: 0.0,
    avgSpeedLast5KmKmh: 45.6,
    currentSpeedKmh: 47.1,
    last5KmSpeedSamplesKmh: const [43.8, 44.5, 45.2, 46.4, 47.1],
    distanceRemainingKm: 18.4,
    gradientPercent: 6.8,
    riders: riders,
  );
}

void main() {
  group('PelotonGroupCompositionAnalyzer unit tests', () {
    test('wylicza poprawnie udziały drużyn i formatuje podsumowanie', () {
      final data = _buildSampleGroupData();
      final shares = PelotonGroupCompositionAnalyzer.computeTeamShares(
        data.riders,
      );

      expect(shares.length, 3);
      expect(shares[0].teamCode, 'UAE');
      expect(shares[0].riderCount, 4);
      expect(shares[0].sharePercent, closeTo(50.0, 0.01));

      expect(shares[1].teamCode, 'Visma');
      expect(shares[1].riderCount, 3);
      expect(shares[1].sharePercent, closeTo(37.5, 0.01));

      expect(shares[2].teamCode, 'SOQ');
      expect(shares[2].riderCount, 1);
      expect(shares[2].sharePercent, closeTo(12.5, 0.01));

      final summary = PelotonGroupCompositionAnalyzer.formatTeamSummaryLine(
        shares,
      );
      expect(summary, 'UAE: 4 kolarzy, Visma: 3 kolarzy, SOQ: 1 kolarz');
    });

    test('wykrywa kolarza ciągnącego na czele oraz obsługuje pustą grupę', () {
      final data = _buildSampleGroupData();
      final pullers = PelotonGroupCompositionAnalyzer.resolveFrontPullers(
        data.riders,
      );

      expect(pullers.length, 1);
      expect(pullers.first.riderName, 'Tadej Pogacar');

      expect(
        PelotonGroupCompositionAnalyzer.computeTeamShares(const []),
        isEmpty,
      );
      expect(
        PelotonGroupCompositionAnalyzer.formatTeamSummaryLine(const []),
        'Brak kolarzy w grupie',
      );
    });

    test('wylicza średnią prędkość z ostatnich 5 km z fallbackiem na próbki', () {
      const dataWithSamplesOnly = PelotonGroupCompositionData(
        groupId: 'g2',
        groupTitle: 'Peleton',
        groupType: GroupType.peloton,
        gapToLeaderSeconds: 45,
        avgSpeedLast5KmKmh: 0,
        currentSpeedKmh: 42.0,
        last5KmSpeedSamplesKmh: [40.0, 42.0, 44.0],
        distanceRemainingKm: 30.0,
        riders: [],
      );

      expect(
        PelotonGroupCompositionAnalyzer.computeAverageSpeedLast5Km(
          dataWithSamplesOnly,
        ),
        closeTo(42.0, 0.01),
      );
    });
  });

  group('PelotonGroupCompositionAnalyzerModal widget tests', () {
    testWidgets(
      'wyświetla skład, udział drużyn, średnią prędkość 5 km i pacemakera',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final data = _buildSampleGroupData();
        PelotonGroupRiderEntry? selectedRider;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Center(
                child: PelotonGroupCompositionAnalyzerModal(
                  groupData: data,
                  onSelectRider: (r) => selectedRider = r,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Grupa Liderów — Col du Galibier'), findsOneWidget);
        expect(find.text('45.6'), findsOneWidget);
        expect(find.text('Tadej Pogacar'), findsAtLeastNWidgets(1));
        expect(find.text('Jonas Vingegaard'), findsOneWidget);
        expect(
          find.text('UAE: 4 kolarzy, Visma: 3 kolarzy, SOQ: 1 kolarz'),
          findsOneWidget,
        );

        // Filtrowanie po chipie drużyny Visma
        await tester.tap(find.text('Visma: 3'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Kolarze w grupie (3/8)'), findsOneWidget);
        expect(find.text('Jonas Vingegaard'), findsOneWidget);
        expect(find.text('Remco Evenepoel'), findsNothing);

        // Kliknięcie kolarza wywołuje callback
        await tester.tap(find.text('Jonas Vingegaard'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(selectedRider?.riderId, 'r5');
      },
    );

    testWidgets(
      'obsługuje brak pacemakera oraz wyłączony filtr Tylko moi',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final data = _buildSampleGroupData(
          includePlayerTeam: false,
          includePuller: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: PelotonGroupCompositionAnalyzerModal(groupData: data),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Brak aktywnego pacemakera — jazda pasywna / na kole'),
          findsOneWidget,
        );

        // Kliknięcie wyłączonego chipu "Tylko moi" nie zmienia liczby kolarzy
        await tester.tap(find.text('Tylko moi'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Kolarze w grupie (8/8)'), findsOneWidget);
      },
    );

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez błędów przepełnienia na ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final data = _buildSampleGroupData();

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      PelotonGroupCompositionAnalyzerModal.show(
                        context,
                        groupData: data,
                      );
                    },
                    child: const Text('Otwórz'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Otwórz'));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(PelotonGroupCompositionAnalyzerModal), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Zamknięcie modala przyciskiem X
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(PelotonGroupCompositionAnalyzerModal), findsNothing);
        },
      );
    }
  });
}
