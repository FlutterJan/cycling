import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/simulation/multi_race_parallel_day_simulator.dart';
import 'package:pro_peloton_manager/ui/widgets/split_squad_calendar_assignment_modal.dart';

void main() {
  group('SplitSquadBikeCatalog & Validation', () {
    test('SplitSquadBikeAsset serializes and deserializes cleanly', () {
      const asset = SplitSquadBikeAsset(
        bikeId: 'bike_test_1',
        modelName: 'Veloce SL-R #1',
        frameBrand: 'Pinarello',
        wheelsetLabel: '35mm Carbon',
        category: SplitSquadBikeCategory.climbing,
        weightKg: 6.82,
        cdaModifier: -0.004,
        conditionPercent: 95,
      );

      final restored = SplitSquadBikeAsset.fromJson(asset.toJson());
      expect(restored.bikeId, asset.bikeId);
      expect(restored.category, SplitSquadBikeCategory.climbing);
      expect(restored.weightKg, 6.82);
      expect(restored.isUciCompliant, isTrue);
    });

    test('autoAssignBikes assigns unique bikes to all active riders', () {
      final defaults = ParallelDaySimulatorState.initialDefault();
      final fleet = SplitSquadBikeCatalog.generateTeamFleet();

      final bikeAssignments = SplitSquadBikeCatalog.autoAssignBikes(
        squad: defaults.squad,
        riderAssignments: defaults.assignments,
        fleet: fleet,
        frontA: defaults.frontAEvent,
        frontB: defaults.frontBEvent,
      );

      final validation = SplitSquadBikeCatalog.validateBikeAssignments(
        squad: defaults.squad,
        riderAssignments: defaults.assignments,
        bikeAssignments: bikeAssignments,
        fleet: fleet,
        frontA: defaults.frontAEvent,
        frontB: defaults.frontBEvent,
      );

      expect(validation.isValid, isTrue);
      expect(validation.missingRiderIds, isEmpty);
      expect(validation.duplicateBikeIds, isEmpty);
      expect(bikeAssignments.values.toSet().length, bikeAssignments.length);
    });

    test('validateBikeAssignments flags duplicate bike across Front A and B',
        () {
      final defaults = ParallelDaySimulatorState.initialDefault();
      final fleet = SplitSquadBikeCatalog.generateTeamFleet();
      final bikeAssignments = SplitSquadBikeCatalog.autoAssignBikes(
        squad: defaults.squad,
        riderAssignments: defaults.assignments,
        fleet: fleet,
        frontA: defaults.frontAEvent,
        frontB: defaults.frontBEvent,
      );

      final frontARider = defaults.assignments.entries
          .firstWhere((e) => e.value == ParallelFrontSlot.frontA)
          .key;
      final frontBRider = defaults.assignments.entries
          .firstWhere((e) => e.value == ParallelFrontSlot.frontB)
          .key;

      bikeAssignments[frontBRider] = bikeAssignments[frontARider]!;

      final validation = SplitSquadBikeCatalog.validateBikeAssignments(
        squad: defaults.squad,
        riderAssignments: defaults.assignments,
        bikeAssignments: bikeAssignments,
        fleet: fleet,
        frontA: defaults.frontAEvent,
        frontB: defaults.frontBEvent,
      );

      expect(validation.isValid, isFalse);
      expect(validation.duplicateBikeIds, contains(bikeAssignments[frontARider]));
    });
  });

  group('SplitSquadCalendarAssignmentModal Responsive & Interaction', () {
    Future<void> pumpModalAtSize(
      WidgetTester tester,
      Size size, {
      bool isReadOnly = false,
      ValueChanged<SplitSquadCalendarAssignmentResult>? onConfirm,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SplitSquadCalendarAssignmentModal(
                isReadOnly: isReadOnly,
                onConfirm: onConfirm,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpModalAtSize(tester, size);
          expect(find.text('Przydział Kolarzy i Rowerów'), findsOneWidget);
          expect(find.text('Zatwierdź Skład i Sprzęt'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('switches tabs, filters riders and confirms assignment',
        (tester) async {
      SplitSquadCalendarAssignmentResult? confirmed;
      await pumpModalAtSize(
        tester,
        const Size(1280, 860),
        onConfirm: (res) => confirmed = res,
      );

      // Przełącz na zakładkę Flota Rowerów
      await tester.tap(find.text('Flota Rowerów'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Veloce SL-R'), findsWidgets);

      // Przełącz na zakładkę Sztab i Autobus
      await tester.tap(find.text('Sztab i Autobus'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Logistyka Autobusów i Dyrektorów Sportowych'),
        findsOneWidget,
      );

      // Wróć na Kadra i Rowery i zatwierdź
      await tester.tap(find.text('Kadra i Rowery'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Zatwierdź Skład i Sprzęt'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmed, isNotNull);
      expect(confirmed!.rosterValidation.isValid, isTrue);
      expect(confirmed!.bikeValidation.isValid, isTrue);
    });

    testWidgets('disables confirm button when isReadOnly is true',
        (tester) async {
      SplitSquadCalendarAssignmentResult? confirmed;
      await pumpModalAtSize(
        tester,
        const Size(1280, 860),
        isReadOnly: true,
        onConfirm: (res) => confirmed = res,
      );

      await tester.tap(find.text('Zatwierdź Skład i Sprzęt'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(confirmed, isNull);
    });
  });
}
