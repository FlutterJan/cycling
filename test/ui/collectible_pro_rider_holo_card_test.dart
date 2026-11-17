import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/collectible_pro_rider_holo_card.dart';

CollectibleProRiderCardData _sampleGoldLegendData({
  int ovr = 94,
  List<GrandTourWinBadge> grandTourWins = const [
    GrandTourWinBadge(tour: GrandTourType.tourDeFrance, years: [2024, 2025]),
    GrandTourWinBadge(tour: GrandTourType.giroDItalia, years: [2024]),
  ],
}) {
  return CollectibleProRiderCardData(
    riderId: 'rider_pog_01',
    fullName: 'Tadej Pogačar',
    shortRoleLabel: 'GC',
    nationalityIso: 'SLO',
    teamName: 'UAE Team Emirates',
    teamShortCode: 'UAD',
    ovr: ovr,
    editionYear: 2026,
    cardSerialNumber: '01/99',
    stats: const ProRiderCardStats(
      mon: 96,
      hil: 95,
      itt: 89,
      spr: 86,
      cob: 84,
      rec: 94,
    ),
    grandTourWins: grandTourWins,
  );
}

Widget _wrapCard(
  Widget child, {
  Size viewportSize = const Size(1600, 900),
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: viewportSize),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        body: Center(
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CollectibleProRiderCardData & Tier unit tests', () {
    test('ProRiderCardTier maps OVR thresholds accurately', () {
      expect(ProRiderCardTier.fromOvr(90), ProRiderCardTier.goldLegend);
      expect(ProRiderCardTier.fromOvr(99), ProRiderCardTier.goldLegend);
      expect(ProRiderCardTier.fromOvr(89), ProRiderCardTier.chromeSilver);
      expect(ProRiderCardTier.fromOvr(82), ProRiderCardTier.chromeSilver);
      expect(ProRiderCardTier.fromOvr(81), ProRiderCardTier.carbonPro);
      expect(ProRiderCardTier.fromOvr(65), ProRiderCardTier.carbonPro);
    });

    test('ProRiderCardStats exposes 6 ordered stats MON..REC', () {
      const stats = ProRiderCardStats(
        mon: 96,
        hil: 95,
        itt: 89,
        spr: 86,
        cob: 84,
        rec: 94,
      );
      expect(
        stats.orderedEntries.map((e) => e.code).toList(),
        ['MON', 'HIL', 'ITT', 'SPR', 'COB', 'REC'],
      );
      expect(
        stats.orderedEntries.map((e) => e.value).toList(),
        [96, 95, 89, 86, 84, 94],
      );
    });

    test('JSON round-trip preserves all card data and Grand Tour badges', () {
      final original = _sampleGoldLegendData(
        grandTourWins: const [
          GrandTourWinBadge(
            tour: GrandTourType.tourDeFrance,
            years: [2024, 2025],
          ),
          GrandTourWinBadge(
            tour: GrandTourType.vueltaAEspana,
            years: [2026],
          ),
        ],
      );
      final json = original.toJson();
      final decoded = CollectibleProRiderCardData.fromJson(json);

      expect(decoded.riderId, original.riderId);
      expect(decoded.fullName, original.fullName);
      expect(decoded.ovr, original.ovr);
      expect(decoded.isGoldLegend, isTrue);
      expect(decoded.totalGrandTourWins, 3);
      expect(decoded.grandTourWins.length, 2);
      expect(decoded.grandTourWins[0].tour, GrandTourType.tourDeFrance);
      expect(decoded.grandTourWins[1].tour, GrandTourType.vueltaAEspana);
      expect(decoded.stats.mon, 96);
      expect(decoded.stats.rec, 94);
    });
  });

  group('CollectibleProRiderHoloCard widget tests', () {
    testWidgets('renders OVR, 6 stats, gold tier label, and Grand Tour badges',
        (tester) async {
      await tester.pumpWidget(
        _wrapCard(
          CollectibleProRiderHoloCard(
            data: _sampleGoldLegendData(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('94'), findsNWidgets(2)); // OVR + REC
      expect(find.text('GOLD REFRACTOR'), findsOneWidget);
      expect(find.text('TADEJ POGAČAR'), findsOneWidget);
      expect(find.text('MON'), findsOneWidget);
      expect(find.text('HIL'), findsOneWidget);
      expect(find.text('ITT'), findsOneWidget);
      expect(find.text('SPR'), findsOneWidget);
      expect(find.text('COB'), findsOneWidget);
      expect(find.text('REC'), findsOneWidget);
      expect(find.text('TDF ×2'), findsOneWidget);
      expect(find.text('GIRO'), findsOneWidget);
    });

    testWidgets('renders fallback palmares row when grandTourWins is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrapCard(
          CollectibleProRiderHoloCard(
            data: _sampleGoldLegendData(ovr: 85, grandTourWins: const []),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CHROME PRISM'), findsOneWidget);
      expect(find.text('WORLDTOUR PALMARES'), findsOneWidget);
    });

    testWidgets('handles hover, tap, and disabled state properly',
        (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        _wrapCard(
          CollectibleProRiderHoloCard(
            data: _sampleGoldLegendData(),
            onTap: () => tapCount++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final cardFinder = find.byType(CollectibleProRiderHoloCard);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(cardFinder));
      await tester.pump(const Duration(milliseconds: 250));
      await gesture.removePointer();

      await tester.tap(cardFinder);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tapCount, 1);

      // Disabled state blocks onTap
      await tester.pumpWidget(
        _wrapCard(
          CollectibleProRiderHoloCard(
            data: _sampleGoldLegendData(),
            enabled: false,
            onTap: () => tapCount++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(cardFinder);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tapCount, 1);
    });

    testWidgets('responds to gyroscope tiltStream and disposes cleanly',
        (tester) async {
      final controller = StreamController<HoloTiltSample>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        _wrapCard(
          CollectibleProRiderHoloCard(
            data: _sampleGoldLegendData(),
            tiltStream: controller.stream,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      controller.add(const HoloTiltSample(0.75, -0.45));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _wrapCard(
            CollectibleProRiderHoloCard(
              data: _sampleGoldLegendData(),
            ),
            viewportSize: viewport,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
