import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/historic_legend_hall_of_fame_compare.dart';
import 'package:pro_peloton_manager/services/career/historical_records_and_palmares_service.dart';
import 'package:pro_peloton_manager/ui/widgets/all_time_goat_pyramid_widget.dart';

void main() {
  Widget wrapResponsive({
    required Size size,
    required Widget child,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: SingleChildScrollView(
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('AllTimeGoatPyramidWidget', () {
    testWidgets('renders all 5 GOAT tiers and default historic legends', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapResponsive(
          size: const Size(1600, 900),
          child: const AllTimeGoatPyramidWidget(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      for (final tier in GoatTier.values) {
        expect(find.text(tier.displayName), findsOneWidget);
      }
      expect(find.text('Piramida Legend Wszech Czasów'), findsOneWidget);
      expect(find.text('Eddy Merckx'), findsWidgets);
    });

    testWidgets('no overflow at 390x844, 1024x768, and 1600x900', (
      tester,
    ) async {
      const resolutions = [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ];

      for (final size in resolutions) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          wrapResponsive(
            size: size,
            child: const AllTimeGoatPyramidWidget(
              careerRiders: [
                RiderPalmares(
                  riderId: 'career_star_1',
                  riderName: 'Jan Kowalski',
                  nationalityIso: 'POL',
                  grandTourOverallWins: 1,
                  tourDeFranceGcWins: 1,
                  monumentWins: 2,
                  totalCareerVictories: 24,
                ),
              ],
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: 'Unexpected exception or overflow at $size',
        );
      }

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets(
      'supports rider selection, tier selection, hover, era filter, and empty reset',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        AllTimeHallOfFameLeaderboardEntry? selectedRider;
        GoatTier? selectedTier;
        bool? eraAdjustmentValue;

        await tester.pumpWidget(
          wrapResponsive(
            size: const Size(1600, 900),
            child: AllTimeGoatPyramidWidget(
              onRiderSelected: (entry) => selectedRider = entry,
              onTierSelected: (tier) => selectedTier = tier,
              onEraAdjustmentChanged: (val) => eraAdjustmentValue = val,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Hover over a rider medallion to exercise hover state.
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        final tadejFinder = find.text('Tadej Pogačar').first;
        await gesture.moveTo(tester.getCenter(tadejFinder));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(tadejFinder);
        await tester.pump(const Duration(milliseconds: 300));
        expect(selectedRider?.riderName, 'Tadej Pogačar');

        // Tap a tier header.
        await tester.tap(find.text(GoatTier.pantheonTitan.displayName));
        await tester.pump(const Duration(milliseconds: 300));
        expect(selectedTier, GoatTier.pantheonTitan);

        // Toggle Era adjustment.
        await tester.tap(find.text('Korekta Epoki: WŁ.'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(eraAdjustmentValue, isFalse);
        expect(find.text('Korekta Epoki: WYŁ.'), findsOneWidget);

        // Filter to Career Riders (none provided -> empty state), then reset.
        await tester.tap(find.text('Kariera Aktywna'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text('Brak legend spełniających wybrane kryteria'),
          findsOneWidget,
        );

        await tester.tap(find.text('Resetuj filtry'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Eddy Merckx'), findsWidgets);
      },
    );

    testWidgets('disabled state blocks interactions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var riderTapped = false;
      var eraToggled = false;

      await tester.pumpWidget(
        wrapResponsive(
          size: const Size(1024, 768),
          child: AllTimeGoatPyramidWidget(
            enabled: false,
            onRiderSelected: (_) => riderTapped = true,
            onEraAdjustmentChanged: (_) => eraToggled = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Eddy Merckx').first);
      await tester.tap(find.text('Korekta Epoki: WŁ.'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(riderTapped, isFalse);
      expect(eraToggled, isFalse);
    });
  });
}
