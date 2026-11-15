import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/live_tv_commentary_ticker.dart';

void main() {
  group('LiveTvCommentaryGenerator', () {
    test('generuje dialog 2 komentatorów dla ataku >10 W/kg', () {
      final generator = LiveTvCommentaryGenerator(random: math.Random(42));
      final lines = generator.generateDialogue(
        const TvCommentaryInputEvent(
          triggerType: TvCommentaryTriggerType.wattBombAttack,
          kilometerMark: 142.5,
          riderName: 'Tadej V.',
          teamName: 'Team Apex',
          wattsPerKg: 11.4,
          absoluteWatts: 752,
        ),
      );

      expect(lines.length, 2);
      expect(lines[0].role, TvCommentatorRole.leadPlayByPlay);
      expect(lines[1].role, TvCommentatorRole.formerProExpert);
      expect(lines[0].isBreaking, isTrue);
      expect(lines[0].telemetryTag, '11.4 W/kg • 752 W');
      expect(lines[0].message, contains('Tadej V.'));
    });

    test('generuje dialog dla rantów, kraksy, bufetu i Virtual GC', () {
      final generator = LiveTvCommentaryGenerator(random: math.Random(7));

      final echelon = generator.generateDialogue(
        const TvCommentaryInputEvent(
          triggerType: TvCommentaryTriggerType.crosswindEchelonSplit,
          kilometerMark: 88.0,
          windSpeedKmh: 42.0,
          echelonGroupsCount: 3,
        ),
      );
      expect(echelon.length, 2);
      expect(echelon[0].telemetryTag, 'Wiatr 42 km/h • 3 grupy');

      final crash = generator.generateDialogue(
        const TvCommentaryInputEvent(
          triggerType: TvCommentaryTriggerType.crashOrMechanical,
          kilometerMark: 54.2,
          riderName: 'Jan K.',
          crashRiderCount: 4,
        ),
      );
      expect(crash.length, 2);
      expect(crash[0].isBreaking, isTrue);
      expect(crash[0].telemetryTag, '4 kolarzy na asfalcie');

      final feed = generator.generateDialogue(
        const TvCommentaryInputEvent(
          triggerType: TvCommentaryTriggerType.feedZoneAndHydration,
          kilometerMark: 96.0,
          isFeedZoneActive: true,
        ),
      );
      expect(feed.length, 2);
      expect(feed[0].telemetryTag, 'BUFET • KM 96.0');

      final gc = generator.generateDialogue(
        const TvCommentaryInputEvent(
          triggerType: TvCommentaryTriggerType.virtualGcShift,
          kilometerMark: 164.0,
          virtualGcLeaderName: 'Jonas R.',
          virtualGcGapSeconds: 22,
        ),
      );
      expect(gc.length, 2);
      expect(gc[0].telemetryTag, 'VIRTUAL GC +0:22');
      expect(gc[0].message, contains('Jonas R.'));
    });

    test('fromLiveTelemetry automatycznie klasyfikuje priorytet zdarzeń', () {
      final attack = TvCommentaryInputEvent.fromLiveTelemetry(
        kilometerMark: 120.0,
        riderName: 'Remco E.',
        wattsPerKg: 10.8,
      );
      expect(attack.triggerType, TvCommentaryTriggerType.wattBombAttack);

      final crash = TvCommentaryInputEvent.fromLiveTelemetry(
        kilometerMark: 120.0,
        wattsPerKg: 11.2,
        crashRiderCount: 2,
      );
      expect(crash.triggerType, TvCommentaryTriggerType.crashOrMechanical);
    });
  });

  group('LiveTvCommentaryTicker UI & Responsiveness', () {
    Future<void> pumpTickerAtSize(
      WidgetTester tester,
      Size size, {
      bool enabled = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LiveTvCommentaryTicker(
                  enabled: enabled,
                  events: const [
                    TvCommentaryInputEvent(
                      triggerType: TvCommentaryTriggerType.wattBombAttack,
                      kilometerMark: 151.4,
                      riderName: 'Michał K.',
                      teamName: 'Polska Pro',
                      wattsPerKg: 12.1,
                      absoluteWatts: 820,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
    }

    testWidgets('renderuje się poprawnie w 390x844 (mobile) bez przepełnień',
        (tester) async {
      await pumpTickerAtSize(tester, const Size(390, 844));
      expect(find.byType(LiveTvCommentaryTicker), findsOneWidget);
      expect(find.text('LIVE TV'), findsOneWidget);
      expect(find.text('KM 151.4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie w 1024x768 (tablet) bez przepełnień',
        (tester) async {
      await pumpTickerAtSize(tester, const Size(1024, 768));
      expect(find.byType(LiveTvCommentaryTicker), findsOneWidget);
      expect(find.text('ATAK >10 W/KG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie w 1600x900 (desktop) bez przepełnień',
        (tester) async {
      await pumpTickerAtSize(tester, const Size(1600, 900));
      expect(find.byType(LiveTvCommentaryTicker), findsOneWidget);
      expect(find.text('12.1 W/kg • 820 W'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('przyciski nawigacji, wyciszenia i historii działają poprawnie',
        (tester) async {
      await pumpTickerAtSize(tester, const Size(1280, 800));

      // Przejście do eksperta (kolejna wypowiedź)
      await tester.tap(find.byTooltip('Następna wypowiedź'));
      await tester.pump(const Duration(milliseconds: 320));
      expect(find.textContaining('EKSPERT • EX-PRO'), findsOneWidget);

      // Wyciszenie komentarza TV
      await tester.tap(find.byTooltip('Wycisz komentarz TV'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('TV MUTED'), findsOneWidget);

      // Rozwinięcie historii transmisji
      await tester.tap(find.byTooltip('Historia transmisji (2/2)'));
      await tester.pump(const Duration(milliseconds: 320));
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('stan disabled blokuje interakcję', (tester) async {
      await pumpTickerAtSize(tester, const Size(1024, 768), enabled: false);
      await tester.tap(find.byTooltip('Wycisz komentarz TV'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('LIVE TV'), findsOneWidget);
      expect(find.text('TV MUTED'), findsNothing);
    });
  });
}
