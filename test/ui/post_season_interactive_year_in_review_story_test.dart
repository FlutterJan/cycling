import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/post_season_interactive_year_in_review_story.dart';

void main() {
  group('SeasonWrappedStoryData & SeasonWrappedAnalytics', () {
    test('JSON round-trip preserves all fields', () {
      final original = SeasonWrappedStoryData.sample();
      final decoded = SeasonWrappedStoryData.fromJson(original.toJson());

      expect(decoded.seasonYear, original.seasonYear);
      expect(decoded.teamName, original.teamName);
      expect(decoded.totalWins, original.totalWins);
      expect(decoded.mvpRider.name, original.mvpRider.name);
      expect(decoded.breakoutRider?.name, original.breakoutRider?.name);
      expect(decoded.topMoments.length, original.topMoments.length);
      expect(decoded.topMoments.first.raceName, original.topMoments.first.raceName);
    });

    test('fromJson handles empty/missing fields safely', () {
      final decoded = SeasonWrappedStoryData.fromJson(const {});
      expect(decoded.seasonYear, 2026);
      expect(decoded.totalWins, 0);
      expect(decoded.topMoments, isEmpty);
      expect(decoded.breakoutRider, isNull);
    });

    test('analytics helpers compute expected values', () {
      final sample = SeasonWrappedStoryData.sample();
      final slides = SeasonWrappedAnalytics.buildSlides(sample);
      expect(slides.length, 6);
      expect(
        SeasonWrappedAnalytics.deriveSeasonArchetype(sample),
        'Totalna Dominacja WorldTour',
      );
      expect(SeasonWrappedAnalytics.rankDelta(7, 3), 4);
      expect(SeasonWrappedAnalytics.everestEquivalents(8848.86), closeTo(1.0, 0.01));
      expect(SeasonWrappedAnalytics.formatCompactNumber(14820), '14.8k');
      expect(SeasonWrappedAnalytics.formatCurrencyEur(1420000), '1.42 M EUR');
    });
  });

  group('PostSeasonInteractiveYearInReviewStory Widget', () {
    Widget wrapWithViewport(Widget child, Size size) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('navigates slides, toggles play/pause, selects moments and shares',
        (tester) async {
      int lastSlide = -1;
      SeasonWrappedStoryData? sharedData;

      await tester.pumpWidget(
        wrapWithViewport(
          PostSeasonInteractiveYearInReviewStory(
            data: SeasonWrappedStoryData.sample(),
            autoPlay: false,
            onSlideChanged: (i) => lastSlide = i,
            onShareSummary: (d) => sharedData = d,
            onClose: () {},
          ),
          const Size(1024, 768),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1 / 6'), findsOneWidget);
      expect(find.text('Bora-Vistula Pro Cycling'), findsOneWidget);

      // Next slide -> Victories
      await tester.tap(find.byKey(const ValueKey('story_next_btn')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(lastSlide, 1);
      expect(find.text('2 / 6'), findsOneWidget);
      expect(find.text('34 triumfów na szosie'), findsOneWidget);

      // Next slide -> Telemetry
      await tester.tap(find.byKey(const ValueKey('story_next_btn')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('3 / 6'), findsOneWidget);
      expect(find.text('Krew, pot i waty'), findsOneWidget);

      // Next slide -> MVP
      await tester.tap(find.byKey(const ValueKey('story_next_btn')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('4 / 6'), findsOneWidget);
      expect(find.text('Michał Majewski (POL)'), findsOneWidget);

      // Next slide -> Iconic Moments
      await tester.tap(find.byKey(const ValueKey('story_next_btn')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('5 / 6'), findsOneWidget);
      await tester.tap(find.text('Il Lombardia'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.text('Złoty finisz w Como i skok na 3. miejsce UCI'),
        findsOneWidget,
      );

      // Next slide -> Summary Poster
      await tester.tap(find.byKey(const ValueKey('story_next_btn')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('6 / 6'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('story_share_btn')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(sharedData, isNotNull);
      expect(find.text('Zapisano do kroniki'), findsOneWidget);

      // Replay
      await tester.tap(find.byKey(const ValueKey('story_replay_btn')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('1 / 6'), findsOneWidget);
    });

    testWidgets('handles empty moments, zero wins and disabled state safely',
        (tester) async {
      final emptyData = SeasonWrappedStoryData.fromJson({
        'seasonYear': 2027,
        'teamName': 'Nowy Projekt Continental',
        'totalWins': 0,
        'topMoments': const <dynamic>[],
      });

      int slideChanges = 0;
      await tester.pumpWidget(
        wrapWithViewport(
          PostSeasonInteractiveYearInReviewStory(
            data: emptyData,
            initialSlideIndex: 4,
            autoPlay: false,
            isDisabled: true,
            onSlideChanged: (_) => slideChanges++,
          ),
          const Size(390, 844),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak wyróżnionych momentów w tym sezonie'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('story_next_btn')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(slideChanges, 0);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow on ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithViewport(
            PostSeasonInteractiveYearInReviewStory(
              data: SeasonWrappedStoryData.sample(),
              autoPlay: false,
              onShareSummary: (_) {},
              onClose: () {},
            ),
            size,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byKey(const ValueKey('story_next_btn')));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }
      });
    }
  });
}
