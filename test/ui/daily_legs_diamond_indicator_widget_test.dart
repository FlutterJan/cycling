import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/engine/events/daily_rider_day_form_variance_engine.dart';
import 'package:pro_peloton_manager/ui/widgets/daily_legs_diamond_indicator_widget.dart';

void main() {
  group('DailyLegsIndicatorData', () {
    test('hidden phase exposes ? label and hides actual diamonds', () {
      const data = DailyLegsIndicatorData(
        riderId: 'r1',
        riderName: 'Tadej',
        discoveryPhase: DayFormDiscoveryPhase.hidden,
        diamondScore: 3,
        discoveryProgress: 0.25,
        currentKm: 5.0,
        revealThresholdKm: 25.0,
      );

      expect(data.isRevealed, isFalse);
      expect(data.badgeLabel, '?');
      expect(data.requiresDraftingConservation, isFalse);
    });

    test('sensing phase formats preliminary trends correctly', () {
      const pos = DailyLegsIndicatorData(
        riderId: 'r1',
        riderName: 'A',
        discoveryPhase: DayFormDiscoveryPhase.sensing,
        diamondScore: 2,
        sensingTrend: DayFormSensingTrend.positive,
      );
      const neg = DailyLegsIndicatorData(
        riderId: 'r2',
        riderName: 'B',
        discoveryPhase: DayFormDiscoveryPhase.sensing,
        diamondScore: -2,
        sensingTrend: DayFormSensingTrend.negative,
      );
      const neu = DailyLegsIndicatorData(
        riderId: 'r3',
        riderName: 'C',
        discoveryPhase: DayFormDiscoveryPhase.sensing,
        diamondScore: 0,
        sensingTrend: DayFormSensingTrend.neutral,
      );

      expect(pos.badgeLabel, '+?');
      expect(neg.badgeLabel, '-?');
      expect(neu.badgeLabel, '~0');
    });

    test('revealed positive and negative scores compute W\' and FTP deltas', () {
      const plus3 = DailyLegsIndicatorData(
        riderId: 'r1',
        riderName: 'Lider',
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        diamondScore: 3,
        baseFtpWatts: 400,
        baseWPrimeJoules: 25000,
      );
      expect(plus3.isRevealed, isTrue);
      expect(plus3.badgeLabel, '+3');
      expect(plus3.wPrimeRecoveryDeltaPercent, closeTo(12.0, 0.01));
      expect(plus3.peakWattsDeltaPercent, closeTo(5.4, 0.01));
      expect(plus3.adjustedFtpWatts, 422);
      expect(plus3.requiresDraftingConservation, isFalse);

      const minus2 = DailyLegsIndicatorData(
        riderId: 'r2',
        riderName: 'Pomocnik',
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        diamondScore: -2,
        baseFtpWatts: 400,
      );
      expect(minus2.badgeLabel, '-2');
      expect(minus2.wPrimeRecoveryDeltaPercent, closeTo(-8.0, 0.01));
      expect(minus2.peakWattsDeltaPercent, closeTo(-3.6, 0.01));
      expect(minus2.requiresDraftingConservation, isTrue);
    });

    test('clamps out-of-range diamond scores and round-trips JSON', () {
      const extreme = DailyLegsIndicatorData(
        riderId: 'r99',
        riderName: 'Test',
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        diamondScore: 10,
        discoveryProgress: 1.0,
        currentKm: 28.0,
        revealThresholdKm: 25.0,
        baseFtpWatts: 380,
        baseWPrimeJoules: 22000,
      );

      expect(extreme.clampedDiamondScore, 3);
      expect(extreme.badgeLabel, '+3');

      final json = extreme.toJson();
      final restored = DailyLegsIndicatorData.fromJson(json);
      expect(restored.riderId, extreme.riderId);
      expect(restored.riderName, extreme.riderName);
      expect(restored.discoveryPhase, extreme.discoveryPhase);
      expect(restored.diamondScore, extreme.diamondScore);
      expect(restored.baseFtpWatts, extreme.baseFtpWatts);
      expect(restored.baseWPrimeJoules, extreme.baseWPrimeJoules);
    });

    test('builds from RiderDayFormState', () {
      const state = RiderDayFormState(
        riderId: 'r5',
        riderName: 'Kolarz',
        teamName: 'Pro Team',
        actualDiamonds: -1,
        expectedMeanDiamonds: 0.0,
        tsbContribution: 0.0,
        sleepContribution: 0.0,
        revealThresholdKm: 24.0,
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        discoveryProgress: 1.0,
        lastObservedKm: 25.0,
        sensingTrend: DayFormSensingTrend.negative,
        hasEmittedRadioMessage: true,
      );

      final data = DailyLegsIndicatorData.fromRiderDayFormState(
        state,
        baseFtpWatts: 390,
      );
      expect(data.badgeLabel, '-1');
      expect(data.requiresDraftingConservation, isTrue);
      expect(data.revealThresholdKm, 24.0);
    });
  });

  group('DailyLegsDiamondIndicatorWidget', () {
    Widget buildTestHost({
      required Size size,
      required Widget child,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: SizedBox(
                width: size.width < 500 ? size.width - 24 : 360,
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders gray ? on start and transitions to green +2 diamonds',
        (tester) async {
      const hiddenData = DailyLegsIndicatorData(
        riderId: 'r1',
        riderName: 'Jan Kowalski',
        discoveryPhase: DayFormDiscoveryPhase.hidden,
        diamondScore: 2,
        discoveryProgress: 0.2,
        currentKm: 5.0,
        revealThresholdKm: 25.0,
        baseFtpWatts: 400,
      );

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1024, 768),
          child: const DailyLegsDiamondIndicatorWidget(data: hiddenData),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('?'), findsNWidgets(2));
      expect(find.text('5/25 km'), findsOneWidget);
      expect(find.byIcon(Icons.diamond_rounded), findsNothing);

      const revealedData = DailyLegsIndicatorData(
        riderId: 'r1',
        riderName: 'Jan Kowalski',
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        diamondScore: 2,
        discoveryProgress: 1.0,
        currentKm: 26.0,
        revealThresholdKm: 25.0,
        baseFtpWatts: 400,
      );

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1024, 768),
          child: const DailyLegsDiamondIndicatorWidget(
            data: revealedData,
            initiallyExpanded: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('+2'), findsOneWidget);
      expect(find.byIcon(Icons.diamond_rounded), findsNWidgets(2));
      expect(find.text('+8.0%'), findsOneWidget);
      expect(find.text('+3.6% (414 W)'), findsOneWidget);
    });

    testWidgets(
        'renders red -2 diamonds with drafting conservation warning and action',
        (tester) async {
      bool draftOrdered = false;
      const badLegs = DailyLegsIndicatorData(
        riderId: 'r2',
        riderName: 'Michał',
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        diamondScore: -2,
        discoveryProgress: 1.0,
        currentKm: 28.0,
        revealThresholdKm: 25.0,
      );

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1600, 900),
          child: DailyLegsDiamondIndicatorWidget(
            data: badLegs,
            initiallyExpanded: true,
            onDraftOrderPressed: () => draftOrdered = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('-2'), findsOneWidget);
      expect(find.byIcon(Icons.diamond_rounded), findsNWidgets(2));
      expect(
        find.text('Zalecana oszczędna jazda na kole w peletonie'),
        findsOneWidget,
      );

      await tester.tap(find.text('Na koło'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(draftOrdered, isTrue);
    });

    testWidgets('supports hover, keyboard focus activation, and disabled state',
        (tester) async {
      int tapCount = 0;
      const data = DailyLegsIndicatorData(
        riderId: 'r3',
        riderName: 'Piotr',
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        diamondScore: 1,
      );

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1024, 768),
          child: DailyLegsDiamondIndicatorWidget(
            data: data,
            onTap: () => tapCount++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Hover state
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(
        tester.getCenter(find.byType(DailyLegsDiamondIndicatorWidget)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      // Focus + Enter activation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 300));

      expect(tapCount, 1);
      expect(find.text('Regeneracja W\''), findsOneWidget);

      // Disabled state blocks tap and action button
      bool draftTriggered = false;
      const badData = DailyLegsIndicatorData(
        riderId: 'r3',
        riderName: 'Piotr',
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        diamondScore: -1,
      );
      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1024, 768),
          child: DailyLegsDiamondIndicatorWidget(
            data: badData,
            isDisabled: true,
            initiallyExpanded: true,
            onTap: () => tapCount++,
            onDraftOrderPressed: () => draftTriggered = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(DailyLegsDiamondIndicatorWidget));
      await tester.tap(find.text('Na koło'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(tapCount, 1);
      expect(draftTriggered, isFalse);
    });

    testWidgets('responsive without overflow on 390x844, 1024x768, 1600x900',
        (tester) async {
      const sizes = <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ];

      const badLegs = DailyLegsIndicatorData(
        riderId: 'r4',
        riderName: 'Bardzo Długie Nazwisko Kolarza Testowego',
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        diamondScore: -2,
        baseFtpWatts: 410,
      );

      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: size),
            child: MaterialApp(
              home: Scaffold(
                backgroundColor: AppColors.background,
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DailyLegsDiamondIndicatorWidget(
                        data: badLegs,
                        compact: size.width < 500,
                        initiallyExpanded: true,
                        onDraftOrderPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));

        expect(
          tester.takeException(),
          isNull,
          reason: 'Unexpected layout exception at $size',
        );
      }
      await tester.binding.setSurfaceSize(null);
    });
  });
}
