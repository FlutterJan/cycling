import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/core/services/haptic_feedback_vibration_controller.dart';

void main() {
  group('HapticFeedbackVibrationController — testy jednostkowe', () {
    test('oblicza gęstszy rytm dla 5-gwiazdkowego bruku przy wysokiej prędkości', () {
      final fast5Star = HapticFeedbackVibrationController.computeCobblePulseInterval(
        sectorStars: 5,
        speedKmh: 48.0,
      );
      final slow1Star = HapticFeedbackVibrationController.computeCobblePulseInterval(
        sectorStars: 1,
        speedKmh: 22.0,
      );

      expect(fast5Star.inMilliseconds, lessThan(slow1Star.inMilliseconds));
      expect(fast5Star.inMilliseconds, inInclusiveRange(140, 220));
    });

    test('emituje subtelne, rytmiczne impulsy na 5★ sektorze bruku i zatrzymuje je po wyjeździe', () async {
      final dispatched = <HapticPulseType>[];
      final controller = HapticFeedbackVibrationController(
        dispatcher: (pulse) async => dispatched.add(pulse),
      );
      addTearDown(controller.dispose);

      controller.startCobbleSectorRhythm(
        sectorStars: 5,
        speedKmh: 45.0,
        sectorName: 'Carrefour de l\'Arbre 5★',
      );

      expect(controller.state.isCobbleRhythmActive, isTrue);
      expect(controller.state.activeCobbleStars, 5);
      expect(dispatched, isNotEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 360));
      expect(dispatched.length, greaterThanOrEqualTo(2));

      controller.updateCobbleSectorTelemetry(sectorStars: 0, speedKmh: 46.0);
      expect(controller.state.isCobbleRhythmActive, isFalse);
      final countAfterStop = dispatched.length;

      await Future<void>.delayed(const Duration(milliseconds: 220));
      expect(dispatched.length, countAfterStop);
    });

    test('emituje mocne uderzenie przy kraksie oraz przy ataku rywala Watt Bomb', () async {
      final dispatched = <HapticPulseType>[];
      final controller = HapticFeedbackVibrationController(
        dispatcher: (pulse) async => dispatched.add(pulse),
      );
      addTearDown(controller.dispose);

      controller.triggerCrashImpact(riderName: 'Kolarz #14', severity: 1.0);
      expect(dispatched.first, HapticPulseType.heavyImpact);
      expect(controller.state.lastEvent?.category, HapticEventCategory.crashImpact);

      await Future<void>.delayed(const Duration(milliseconds: 210));
      expect(dispatched.length, 3);
      expect(dispatched[1], HapticPulseType.heavyImpact);

      dispatched.clear();
      await Future<void>.delayed(const Duration(milliseconds: 130));

      controller.triggerWattBombAttack(
        attackerName: 'Pogačar AI',
        wattsPerKg: 13.6,
        peakWatts: 1450,
      );
      expect(dispatched.first, HapticPulseType.heavyImpact);
      expect(
        controller.state.lastEvent?.category,
        HapticEventCategory.wattBombAttack,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(dispatched.length, 2);
    });

    test('emituje mechaniczne kliknięcie przy zmianie przełożenia i rozkazie taktycznym', () async {
      final dispatched = <HapticPulseType>[];
      final controller = HapticFeedbackVibrationController(
        dispatcher: (pulse) async => dispatched.add(pulse),
      );
      addTearDown(controller.dispose);

      controller.triggerGearShiftClick(
        frontChainringTeeth: 54,
        rearCogTeeth: 14,
        isFrontDerailleur: false,
      );
      expect(dispatched.single, HapticPulseType.selectionClick);
      expect(controller.state.lastEvent?.category, HapticEventCategory.gearShift);

      await Future<void>.delayed(const Duration(milliseconds: 45));
      controller.triggerGearShiftClick(
        frontChainringTeeth: 39,
        rearCogTeeth: 24,
        isFrontDerailleur: true,
      );
      expect(dispatched.last, HapticPulseType.mediumImpact);

      await Future<void>.delayed(const Duration(milliseconds: 45));
      controller.triggerTacticalOrderClick(
        orderLabel: 'Atakuj na sektorze bruku',
        isHighPriority: true,
      );
      expect(
        controller.state.lastEvent?.category,
        HapticEventCategory.tacticalOrder,
      );
      expect(dispatched.last, HapticPulseType.mediumImpact);
    });

    test('nie emituje impulsów po wyłączeniu kontrolera lub wybranej kategorii', () {
      final dispatched = <HapticPulseType>[];
      final controller = HapticFeedbackVibrationController(
        dispatcher: (pulse) async => dispatched.add(pulse),
      );
      addTearDown(controller.dispose);

      controller.setEnabled(false);
      controller.triggerCrashImpact();
      controller.triggerGearShiftClick();
      controller.startCobbleSectorRhythm(sectorStars: 5, speedKmh: 40);
      expect(dispatched, isEmpty);

      controller.setEnabled(true);
      controller.setCategoryEnabled(mechanicalClicks: false);
      controller.triggerTacticalOrderClick(orderLabel: 'Utrzymuj tempo');
      expect(dispatched, isEmpty);
    });
  });

  group('HapticFeedbackControlPanel — responsywność i interakcje', () {
    for (final size in <Size>[
      const Size(390, 844),
      const Size(1024, 768),
      const Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnienia w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final dispatched = <HapticPulseType>[];
          final testController = HapticFeedbackVibrationController(
            dispatcher: (pulse) async => dispatched.add(pulse),
          );

          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                hapticFeedbackVibrationProvider
                    .overrideWith((_) => testController),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: HapticFeedbackControlPanel(),
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.text('Kontroler Haptyki i Wibracji'), findsOneWidget);

          await tester.ensureVisible(find.text('Zmiana biegu'));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text('Zmiana biegu'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(dispatched, contains(HapticPulseType.selectionClick));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('obsługuje przełączanie stanu wyłączonego i czyszczenie logu', (tester) async {
      final dispatched = <HapticPulseType>[];
      final testController = HapticFeedbackVibrationController(
        dispatcher: (pulse) async => dispatched.add(pulse),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hapticFeedbackVibrationProvider
                .overrideWith((_) => testController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HapticFeedbackControlPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Haptyka Włączona'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Haptyka Wyłączona'), findsOneWidget);

      await tester.tap(find.text('Watt Bomb'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(dispatched, isEmpty);
    });
  });
}
