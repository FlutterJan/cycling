import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/ui/widgets/breakaway_cooperation_trust_meter_hud.dart';

void main() {
  group('BreakawayCooperationCalculator & Models', () {
    test('generuje podsumowanie wkładu zmian z ostrzeżeniem Oszczędza siły!', () {
      final BreakawayCooperationTrustMeterData sample =
          BreakawayCooperationTrustMeterData.sample();

      expect(
        sample.summaryLine,
        'Kolarz A: 42% zmian, Kolarz B: 40% zmian, Kolarz C: 18% — Oszczędza siły!',
      );
      expect(sample.harmonyLevel, BreakawayGroupHarmonyLevel.tense);
      expect(sample.resolvedGroupTrustIndex, greaterThan(45.0));
      expect(sample.resolvedGroupTrustIndex, lessThan(85.0));
    });

    test('normalizuje udziały procentowe oraz obsługuje fallback pullSeconds i wartości brzegowe', () {
      final List<BreakawayRiderContributionEntry> bySeconds =
          BreakawayCooperationCalculator.normalizeShares(
        const <BreakawayRiderContributionEntry>[
          BreakawayRiderContributionEntry(
            riderId: 'r1',
            riderName: 'A',
            teamShortCode: 'T1',
            jerseyColor: AppColors.accentBlue,
            leadSharePercent: 0,
            pullSeconds: 300,
          ),
          BreakawayRiderContributionEntry(
            riderId: 'r2',
            riderName: 'B',
            teamShortCode: 'T2',
            jerseyColor: AppColors.goldAccent,
            leadSharePercent: 0,
            pullSeconds: 100,
          ),
        ],
      );
      expect(bySeconds[0].roundedLeadSharePercent, 75);
      expect(bySeconds[1].roundedLeadSharePercent, 25);

      const BreakawayRiderContributionEntry invalid =
          BreakawayRiderContributionEntry(
        riderId: 'inv',
        riderName: 'Inv',
        teamShortCode: 'INV',
        jerseyColor: AppColors.accentBlue,
        leadSharePercent: double.nan,
        pullSeconds: -10,
        avgPullWatts: -200,
        turnsSkippedCount: -1,
        trustScore: double.infinity,
      );
      expect(invalid.safeLeadSharePercent, 0.0);
      expect(invalid.safePullSeconds, 0);
      expect(invalid.safeAvgPullWatts, 0);
      expect(invalid.safeTurnsSkippedCount, 0);
      expect(invalid.safeTrustScore, 0.0);
    });

    test('serializuje i deserializuje JSON 1:1', () {
      final BreakawayCooperationTrustMeterData sample =
          BreakawayCooperationTrustMeterData.sample();
      final Map<String, dynamic> json = sample.toJson();
      final BreakawayCooperationTrustMeterData restored =
          BreakawayCooperationTrustMeterData.fromJson(json);

      expect(restored.breakawayGroupName, sample.breakawayGroupName);
      expect(restored.gapToPelotonSeconds, sample.gapToPelotonSeconds);
      expect(restored.distanceRemainingKm, sample.distanceRemainingKm);
      expect(restored.groupSpeedKmh, sample.groupSpeedKmh);
      expect(restored.riders.length, sample.riders.length);
      expect(restored.riders[2].riderName, 'Kolarz C');
      expect(restored.riders[2].turnsSkippedCount, 3);
    });
  });

  group('BreakawayCooperationTrustMeterHud Widget', () {
    Widget buildHarness({
      required BreakawayCooperationTrustMeterData data,
      bool isEnabled = true,
      bool initiallyExpanded = true,
      String? selectedRiderId,
      ValueChanged<BreakawayRiderContributionEntry>? onRiderTap,
      ValueChanged<BreakawayRiderContributionEntry>? onDemandPullTap,
      ValueChanged<bool>? onToggleCollapse,
      Size surfaceSize = const Size(1024, 768),
    }) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: surfaceSize.width - 24,
                child: BreakawayCooperationTrustMeterHud(
                  data: data,
                  isEnabled: isEnabled,
                  initiallyExpanded: initiallyExpanded,
                  selectedRiderId: selectedRiderId,
                  onRiderTap: onRiderTap,
                  onDemandPullTap: onDemandPullTap,
                  onToggleCollapse: onToggleCollapse,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('wyświetla procentowy wkład uciekinierów i obsługuje interakcje',
        (WidgetTester tester) async {
      BreakawayRiderContributionEntry? tappedRider;
      BreakawayRiderContributionEntry? demandedRider;
      bool? collapsedState;

      await tester.pumpWidget(
        buildHarness(
          data: BreakawayCooperationTrustMeterData.sample(),
          onRiderTap: (BreakawayRiderContributionEntry r) => tappedRider = r,
          onDemandPullTap: (BreakawayRiderContributionEntry r) =>
              demandedRider = r,
          onToggleCollapse: (bool expanded) => collapsedState = expanded,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('42% zmian'), findsOneWidget);
      expect(find.text('40% zmian'), findsOneWidget);
      expect(find.text('18% zmian'), findsOneWidget);
      expect(find.text('Oszczędza siły!'), findsOneWidget);
      expect(
        find.text(
          'Kolarz A: 42% zmian, Kolarz B: 40% zmian, Kolarz C: 18% — Oszczędza siły!',
        ),
        findsOneWidget,
      );

      // Test kliknięcia kolarza i przycisku "Wymuś zmianę"
      await tester.tap(find.text('Kolarz A'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tappedRider?.riderId, 'rider_a');

      await tester.tap(find.text('Wymuś zmianę'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(demandedRider?.riderId, 'rider_c');

      // Test przełączenia trybu na Moc / Czas
      await tester.tap(find.text('Moc / Czas'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('412 W'), findsOneWidget);

      // Test hovera
      final TestGesture gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Kolarz B')));
      await tester.pump(const Duration(milliseconds: 200));

      // Test zwinięcia panelu
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(collapsedState, isFalse);
    });

    testWidgets('obsługuje stan pusty i stan disabled bez błędów',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildHarness(
          data: BreakawayCooperationTrustMeterData.empty(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Brak aktywnej ucieczki dnia — peleton jedzie razem.'),
        findsOneWidget,
      );

      bool tappedWhileDisabled = false;
      await tester.pumpWidget(
        buildHarness(
          data: BreakawayCooperationTrustMeterData.sample(),
          isEnabled: false,
          onRiderTap: (_) => tappedWhileDisabled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('WYŁĄCZONY'), findsOneWidget);

      await tester.tap(find.text('Kolarz A'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tappedWhileDisabled, isFalse);
    });

    for (final Size size in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień RenderFlex w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildHarness(
              data: BreakawayCooperationTrustMeterData.sample(),
              surfaceSize: size,
              onDemandPullTap: (_) {},
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(BreakawayCooperationTrustMeterHud), findsOneWidget);
        },
      );
    }
  });
}
