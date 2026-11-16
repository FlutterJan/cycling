import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/descender_attack_and_supertuck_physics.dart';
import 'package:pro_peloton_manager/ui/widgets/descent_technicality_radar_hud.dart';

void main() {
  group('DescentTechnicalityRadarData & DescentSlipRiskLevel', () {
    test('wyznacza poprawny poziom ryzyka poślizgu i obsługuje wartości brzegowe', () {
      expect(DescentSlipRiskLevel.fromPercent(-10.0), DescentSlipRiskLevel.low);
      expect(DescentSlipRiskLevel.fromPercent(double.nan), DescentSlipRiskLevel.low);
      expect(DescentSlipRiskLevel.fromPercent(19.9), DescentSlipRiskLevel.low);
      expect(DescentSlipRiskLevel.fromPercent(20.0), DescentSlipRiskLevel.moderate);
      expect(DescentSlipRiskLevel.fromPercent(44.9), DescentSlipRiskLevel.moderate);
      expect(DescentSlipRiskLevel.fromPercent(45.0), DescentSlipRiskLevel.high);
      expect(DescentSlipRiskLevel.fromPercent(70.0), DescentSlipRiskLevel.critical);
      expect(DescentSlipRiskLevel.fromPercent(140.0), DescentSlipRiskLevel.critical);
    });

    test('serializuje i deserializuje JSON oraz normalizuje NaN / wartości ujemne', () {
      final DescentTechnicalityRadarData sample =
          DescentTechnicalityRadarData.sample();
      final Map<String, dynamic> json = sample.toJson();
      final DescentTechnicalityRadarData restored =
          DescentTechnicalityRadarData.fromJson(json);

      expect(restored.descentName, sample.descentName);
      expect(restored.attackerName, sample.attackerName);
      expect(restored.upcomingHairpinsCount, sample.upcomingHairpinsCount);
      expect(restored.slipRiskPercent, sample.slipRiskPercent);
      expect(restored.timeGainSeconds, sample.timeGainSeconds);
      expect(restored.upcomingHairpins.length, sample.upcomingHairpins.length);

      const DescentTechnicalityRadarData invalid = DescentTechnicalityRadarData(
        descentName: 'Test',
        attackerName: 'Rider',
        attackerTeamCode: 'TST',
        upcomingHairpinsCount: -3,
        nextHairpinDistanceMeters: double.nan,
        slipRiskPercent: double.infinity,
        timeGainSeconds: double.nan,
        currentSpeedKmh: 60.0,
        averageGradientPercent: -5.0,
      );
      expect(invalid.safeUpcomingHairpinsCount, 0);
      expect(invalid.safeNextHairpinDistanceMeters, 0.0);
      expect(invalid.normalizedSlipRiskPercent, 0.0);
      expect(invalid.safeTimeGainSeconds, 0.0);
    });
  });

  group('DescentTechnicalityRadarHud Widget', () {
    Widget buildTestHarness({
      required DescentTechnicalityRadarData data,
      bool enabled = true,
      bool initiallyExpanded = true,
      ValueChanged<DescenderAttackAggression>? onAggressionChanged,
      VoidCallback? onTapAttacker,
      Size surfaceSize = const Size(1024, 768),
    }) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: surfaceSize.width - 24,
                child: DescentTechnicalityRadarHud(
                  data: data,
                  enabled: enabled,
                  initiallyExpanded: initiallyExpanded,
                  onAggressionChanged: onAggressionChanged,
                  onTapAttacker: onTapAttacker,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('wyświetla liczbę nawrotów 180°, ryzyko poślizgu % oraz zysk sekundowy', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestHarness(data: DescentTechnicalityRadarData.sample()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('RADAR TRUDNOŚCI ZJAZDU'), findsOneWidget);
      expect(find.text('Col du Galibier — Serpentyny'), findsOneWidget);
      expect(find.text('11'), findsWidgets);
      expect(find.text('54%'), findsOneWidget);
      expect(find.text('+22.8 s'), findsOneWidget);
      expect(find.text('T. Pidcock'), findsOneWidget);
    });

    testWidgets('obsługuje stan pusty bez nawrotów i bez aktywnego ataku', (WidgetTester tester) async {
      const DescentTechnicalityRadarData emptyData = DescentTechnicalityRadarData(
        descentName: 'Dolina Maurienne',
        attackerName: 'Brak',
        attackerTeamCode: '---',
        upcomingHairpinsCount: 0,
        nextHairpinDistanceMeters: 0.0,
        slipRiskPercent: 8.0,
        timeGainSeconds: 0.0,
        currentSpeedKmh: 58.0,
        averageGradientPercent: -3.2,
        hasActiveAttack: false,
      );

      await tester.pumpWidget(buildTestHarness(data: emptyData));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak aktywnego ataku'), findsOneWidget);
      expect(
        find.text('Brak ciasnych nawrotów 180° w najbliższym sektorze'),
        findsOneWidget,
      );
      expect(find.text('8%'), findsOneWidget);
      expect(find.text('0.0 s'), findsOneWidget);
    });

    testWidgets('obsługuje stany hover, focus, tap oraz zmianę agresji i blokuje interakcję gdy disabled', (WidgetTester tester) async {
      DescenderAttackAggression? selectedAggression;
      int attackerTaps = 0;

      await tester.pumpWidget(
        buildTestHarness(
          data: DescentTechnicalityRadarData.sample(),
          onAggressionChanged: (DescenderAttackAggression mode) {
            selectedAggression = mode;
          },
          onTapAttacker: () {
            attackerTaps++;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Hover
      final TestGesture gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(
        tester.getCenter(find.byType(DescentTechnicalityRadarHud)),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap na zmianę agresji
      await tester.tap(find.text('Na granicy ryzyka'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selectedAggression, DescenderAttackAggression.kamikaze);

      // Tap na kartę atakującego
      await tester.tap(find.text('T. Pidcock'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(attackerTaps, 1);

      // Stan disabled — brak wywołań callbacków
      await tester.pumpWidget(
        buildTestHarness(
          data: DescentTechnicalityRadarData.sample(),
          enabled: false,
          onAggressionChanged: (DescenderAttackAggression mode) {
            selectedAggression = mode;
          },
          onTapAttacker: () {
            attackerTaps++;
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Kontrolowany'), warnIfMissed: false);
      await tester.tap(find.text('T. Pidcock'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));

      expect(selectedAggression, DescenderAttackAggression.kamikaze);
      expect(attackerTaps, 1);
    });

    testWidgets('renderuje się bez przepełnień w 390x844, 1024x768 i 1600x900', (WidgetTester tester) async {
      const List<Size> viewports = <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ];

      for (final Size size in viewports) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          buildTestHarness(
            data: DescentTechnicalityRadarData.sample(),
            onAggressionChanged: (_) {},
            surfaceSize: size,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'Overflow na $size');
      }

      await tester.binding.setSurfaceSize(null);
    });
  });
}
