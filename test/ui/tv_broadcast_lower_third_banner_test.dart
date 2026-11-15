import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/broadcast_tv_graphics_overlay.dart';
import 'package:pro_peloton_manager/ui/widgets/tv_broadcast_lower_third_banner.dart';

void main() {
  const sampleAttacker = TvBroadcastLowerThirdData(
    riderId: 'rider_pogacar',
    riderName: 'Tadej Pogačar',
    teamName: 'UAE Team Emirates',
    teamShortCode: 'UAD',
    nationalityIso: 'SI',
    currentPowerWatts: 465,
    riderWeightKg: 66.0,
    ftpWatts: 415.0,
    heartRateBpm: 184,
    maxHeartRateBpm: 196,
    speedKmh: 31.4,
    gcPosition: 1,
    gcGapSeconds: -18.0,
    isAttacking: true,
    isGcLeader: true,
    cadenceRpm: 94,
  );

  Widget wrapForSize(Widget child, Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: size.width,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  group('TvBroadcastLowerThirdData', () {
    test('oblicza poprawnie W/kg, strefę mocy i formatuje stratę/przewagę GC', () {
      expect(sampleAttacker.wattsPerKg, closeTo(465 / 66.0, 0.001));
      expect(sampleAttacker.powerZone, 5);
      expect(sampleAttacker.formattedGcGap, "-0'18\"");
      expect(sampleAttacker.resolvedStatusLabel, 'ATAK');

      const chasingRider = TvBroadcastLowerThirdData(
        riderId: 'rider_2',
        riderName: 'Jonas Vingegaard',
        teamName: 'Team Visma',
        teamShortCode: 'TVL',
        currentPowerWatts: 410,
        heartRateBpm: 179,
        speedKmh: 29.8,
        gcPosition: 2,
        gcGapSeconds: 84.0,
        isAttacking: false,
      );
      expect(chasingRider.formattedGcGap, "+1'24\"");
      expect(chasingRider.resolvedStatusLabel, 'W GRUPIE');
    });

    test('fromSpotlight mapuje dane z BroadcastRiderSpotlightData', () {
      const spotlight = BroadcastRiderSpotlightData(
        riderId: 'r_1',
        riderName: 'Remco Evenepoel',
        teamName: 'Soudal Quick-Step',
        teamShortCode: 'SOQ',
        nationalityIso: 'BE',
        gcPosition: 3,
        gcGapSeconds: 45.0,
        currentPowerWatts: 440,
        riderWeightKg: 62.0,
        heartRateBpm: 180,
        speedKmh: 48.2,
        isAttacking: true,
      );

      final mapped = TvBroadcastLowerThirdData.fromSpotlight(spotlight);
      expect(mapped.riderId, 'r_1');
      expect(mapped.riderName, 'Remco Evenepoel');
      expect(mapped.teamShortCode, 'SOQ');
      expect(mapped.formattedGcGap, "+0'45\"");
      expect(mapped.isAttacking, isTrue);
    });
  });

  group('TvBroadcastLowerThirdBanner responsive & interactions', () {
    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje bez przepełnień w rozdzielczości ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapForSize(
              const TvBroadcastLowerThirdBanner(
                data: sampleAttacker,
                style: TvBroadcastBannerStyle.goldBlack,
              ),
              viewport,
            ),
          );
          await tester.pump(const Duration(milliseconds: 350));

          expect(find.text('TADEJ POGAČAR'), findsOneWidget);
          expect(find.text('UAD'), findsOneWidget);
          expect(find.text('465 W'), findsOneWidget);
          expect(find.text("-0'18\""), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('obsługuje przełączanie stylu, kliknięcie i zamknięcie',
        (tester) async {
      bool tapped = false;
      bool dismissed = false;
      TvBroadcastBannerStyle currentStyle = TvBroadcastBannerStyle.goldBlack;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return wrapForSize(
              TvBroadcastLowerThirdBanner(
                data: sampleAttacker,
                style: currentStyle,
                onTap: () => tapped = true,
                onDismiss: () => dismissed = true,
                onStyleChanged: (next) => setState(() => currentStyle = next),
              ),
              const Size(1024, 768),
            );
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pump(const Duration(milliseconds: 250));
      expect(currentStyle, TvBroadcastBannerStyle.burgundyGold);

      await tester.tap(find.text('TADEJ POGAČAR'));
      await tester.pump();
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('stan disabled blokuje akcje, a visible=false ukrywa belkę',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapForSize(
          TvBroadcastLowerThirdBanner(
            data: sampleAttacker,
            enabled: false,
            visible: true,
            onTap: () => tapped = true,
          ),
          const Size(1024, 768),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('TADEJ POGAČAR'));
      await tester.pump();
      expect(tapped, isFalse);

      await tester.pumpWidget(
        wrapForSize(
          const TvBroadcastLowerThirdBanner(
            data: sampleAttacker,
            visible: false,
          ),
          const Size(1024, 768),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TADEJ POGAČAR'), findsNothing);
    });
  });
}
