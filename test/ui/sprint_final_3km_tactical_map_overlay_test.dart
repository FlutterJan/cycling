import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/ui/widgets/sprint_final_3km_tactical_map_overlay.dart';

void main() {
  group('SprintFinal3kmTacticalMapOverlay - logika i serializacja', () {
    test('JSON round-trip zachowuje komplet danych telemetrycznych', () {
      final sample = SprintFinal3kmTacticalCalculator.generateDefaultSample();
      final json = sample.toJson();
      final restored = SprintFinal3kmTelemetryData.fromJson(json);

      expect(restored.stageName, sample.stageName);
      expect(restored.windSpeedKmh, sample.windSpeedKmh);
      expect(restored.windDirectionDegrees, sample.windDirectionDegrees);
      expect(restored.distanceToFinishMeters, sample.distanceToFinishMeters);
      expect(restored.riders.length, sample.riders.length);
      expect(restored.corners.length, sample.corners.length);
      expect(restored.selectedRiderId, sample.selectedRiderId);
      expect(restored.activeOrder, sample.activeOrder);
    });

    test('kalkulator poprawnie ocenia pociąg i wykrywa zamknięcie przy barierkach', () {
      final sample = SprintFinal3kmTacticalCalculator.generateDefaultSample();
      final report = SprintFinal3kmTacticalCalculator.evaluateTrainIntegrity(sample);

      expect(report.playerTrainCount, 3);
      expect(report.isTrainConnected, isTrue);
      expect(report.boxedInPlayerRiders, 0);
      expect(report.recommendedOrder, SprintLineOrder.launchLeadout);

      const boxedRider = SprintTacticalRiderDot(
        riderId: 'boxed',
        name: 'R. Zamknięty',
        shortCode: 'ZAM',
        teamName: 'Polonia Pro',
        teamColor: AppColors.goldAccent,
        isPlayerTeam: true,
        role: SprintRiderRoleTag.sprinter,
        distanceToFinishMeters: 400.0,
        lateralOffsetNormalized: -0.90,
        speedKmh: 62.0,
        powerWatts: 500,
        wPrimePercent: 85.0,
        cadenceRpm: 100,
      );
      const frontBlocker = SprintTacticalRiderDot(
        riderId: 'front',
        name: 'F. Bloker',
        shortCode: 'BLO',
        teamName: 'Rival',
        teamColor: AppColors.accentBlue,
        isPlayerTeam: false,
        role: SprintRiderRoleTag.rivalSprinter,
        distanceToFinishMeters: 397.5,
        lateralOffsetNormalized: -0.88,
        speedKmh: 62.0,
        powerWatts: 520,
        wPrimePercent: 80.0,
        cadenceRpm: 100,
      );

      final safety = SprintFinal3kmTacticalCalculator.computeLateralCorridorSafety(
        boxedRider,
        const [boxedRider, frontBlocker],
        7.0,
      );
      expect(safety.leftBlocked, isTrue);
      expect(safety.frontBlocked, isTrue);
      expect(safety.isBoxedIn, isTrue);
    });

    test('kalkulator aktywuje okno procy aerodynamicznej w strefie 250 m', () {
      final sample = SprintFinal3kmTacticalCalculator.generateDefaultSample();
      final final200 = sample.copyWith(
        distanceToFinishMeters: 210.0,
        riders: sample.riders
            .map((r) => r.copyWith(distanceToFinishMeters: 210.0))
            .toList(),
      );
      final report = SprintFinal3kmTacticalCalculator.evaluateTrainIntegrity(final200);

      expect(report.slingshotWindowActive, isTrue);
      expect(report.recommendedOrder, SprintLineOrder.openSprintNow);
    });
  });

  group('SprintFinal3kmTacticalMapOverlay - widget i responsywność', () {
    Widget wrapForSize(Size size, Widget child) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          ),
        ),
      );
    }

    for (final viewport in <Size>[
      const Size(390, 844),
      const Size(1024, 768),
      const Size(1600, 900),
    ]) {
      testWidgets('renderuje bez przepełnienia w rozdzielczości ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final sample = SprintFinal3kmTacticalCalculator.generateDefaultSample();
        await tester.pumpWidget(
          wrapForSize(
            viewport,
            SprintFinal3kmTacticalMapOverlay(data: sample),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Mapa Taktyczna: Ostatnie 3 km'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('obsługuje przełączanie zakresu, rozkazy taktyczne, stan pusty i disabled',
        (tester) async {
      SprintLineOrder? dispatchedOrder;
      final sample = SprintFinal3kmTacticalCalculator.generateDefaultSample();

      await tester.pumpWidget(
        wrapForSize(
          const Size(1024, 768),
          SprintFinal3kmTacticalMapOverlay(
            data: sample,
            onOrderDispatched: (order) => dispatchedOrder = order,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('250 m'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Atakuj Finisz!'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(dispatchedOrder, SprintLineOrder.openSprintNow);

      // Stan disabled blokuje rozkazy
      dispatchedOrder = null;
      await tester.pumpWidget(
        wrapForSize(
          const Size(1024, 768),
          SprintFinal3kmTacticalMapOverlay(
            data: sample,
            isEnabled: false,
            onOrderDispatched: (order) => dispatchedOrder = order,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Skocz na Koło'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(dispatchedOrder, isNull);

      // Stan pusty
      await tester.pumpWidget(
        wrapForSize(
          const Size(1024, 768),
          SprintFinal3kmTacticalMapOverlay(
            data: sample.copyWith(riders: const []),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Brak danych kolarzy w strefie sprintu.'), findsOneWidget);
    });
  });
}
