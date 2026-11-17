import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/carbohydrate_hydrogel_and_ketones_engine.dart';
import 'package:pro_peloton_manager/ui/widgets/nutrition_strategy_planner_panel.dart';

void main() {
  List<RiderNutritionPlanEntry> sampleRiders() {
    return const [
      RiderNutritionPlanEntry(
        riderId: 'r1',
        riderName: 'Tadej Kowalski',
        roleLabel: 'Lider GC',
        gutTrainingLevel: 0.86,
        bicarbonateTolerance: 0.80,
        carbsGramsPerHour: 110.0,
        useBicarbonatePreLoad: false,
        usePostStageKetones: true,
      ),
      RiderNutritionPlanEntry(
        riderId: 'r2',
        riderName: 'Marek Nowak',
        roleLabel: 'Czasowiec TT',
        gutTrainingLevel: 0.52,
        bicarbonateTolerance: 0.68,
        carbsGramsPerHour: 90.0,
        useBicarbonatePreLoad: true,
        usePostStageKetones: false,
      ),
      RiderNutritionPlanEntry(
        riderId: 'r3',
        riderName: 'Jan Wiśniewski',
        roleLabel: 'Pomocnik',
        gutTrainingLevel: 0.40,
        bicarbonateTolerance: 0.42,
        carbsGramsPerHour: 60.0,
        useBicarbonatePreLoad: false,
        usePostStageKetones: false,
        isClearedForSupplementation: false,
      ),
    ];
  }

  group('NutritionStrategyPlannerCalculator & Models', () {
    test('serializes and deserializes RiderNutritionPlanEntry cleanly', () {
      const entry = RiderNutritionPlanEntry(
        riderId: 'rider_42',
        riderName: 'Kamil Zieliński',
        roleLabel: 'Sprinter',
        gutTrainingLevel: 0.78,
        bicarbonateTolerance: 0.72,
        carbsGramsPerHour: 115.0,
        useBicarbonatePreLoad: true,
        usePostStageKetones: true,
        isClearedForSupplementation: true,
        riderRecoveryRate: 1.15,
      );

      final json = entry.toJson();
      final decoded = RiderNutritionPlanEntry.fromJson(json);

      expect(decoded.riderId, 'rider_42');
      expect(decoded.riderName, 'Kamil Zieliński');
      expect(decoded.carbsGramsPerHour, 115.0);
      expect(decoded.useBicarbonatePreLoad, isTrue);
      expect(decoded.usePostStageKetones, isTrue);
      expect(decoded.riderRecoveryRate, 1.15);
    });

    test('evaluates 60-120 g/h carbs, bicarbonate W\' bonus, and ketone recovery bonus', () {
      final highGutRider = sampleRiders().first;
      final eval = NutritionStrategyPlannerCalculator.evaluateRiderPlan(
        entry: highGutRider.copyWith(
          carbsGramsPerHour: 120.0,
          useBicarbonatePreLoad: true,
          usePostStageKetones: true,
        ),
      );

      expect(eval.targetCarbsGramsPerHour, 120.0);
      expect(eval.meetsGutRequirement, isTrue);
      expect(eval.wPrimeBonusPercent, closeTo(6.0, 0.01));
      expect(eval.overnightRecoveryBonusPercent, closeTo(12.0, 0.01));
      expect(eval.giTolerancePercent, inInclusiveRange(20.0, 100.0));
      expect(eval.costEur, greaterThan(0));
    });

    test('flags low gut training at high carb dose and handles empty roster', () {
      const lowGutEntry = RiderNutritionPlanEntry(
        riderId: 'r_low',
        riderName: 'Debiutant',
        gutTrainingLevel: 0.30,
        carbsGramsPerHour: 120.0,
      );
      final eval = NutritionStrategyPlannerCalculator.evaluateRiderPlan(
        entry: lowGutEntry,
        raceTemperatureCelsius: 33.0,
      );

      expect(eval.meetsGutRequirement, isFalse);
      expect(eval.projectedSeverity, isNot(GiDistressSeverity.none));

      final emptySummary = NutritionStrategyPlannerCalculator.evaluateTeamSummary(
        entries: const [],
      );
      expect(emptySummary.riderCount, 0);
      expect(emptySummary.totalCostEur, 0);
    });
  });

  group('NutritionStrategyplannerPanel Widget & Responsiveness', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester, {
      required Size size,
      required List<RiderNutritionPlanEntry> riders,
      bool isTimeTrial = false,
      bool enabled = true,
      ValueChanged<List<RiderNutritionPlanEntry>>? onPlanChanged,
      ValueChanged<List<RiderNutritionPlanEntry>>? onApplyTeamPlan,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NutritionStrategyplannerPanel(
                initialRiders: riders,
                isTimeTrialStage: isTimeTrial,
                enabled: enabled,
                onPlanChanged: onPlanChanged,
                onApplyTeamPlan: onApplyTeamPlan,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          await pumpPanelAtSize(
            tester,
            size: viewport,
            riders: sampleRiders(),
            isTimeTrial: true,
          );

          expect(find.text('Tadej Kowalski'), findsAtLeastNWidgets(1));
          expect(find.text('Zatwierdź Plan Żywienia'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('renders empty state cleanly when rider list is empty', (tester) async {
      await pumpPanelAtSize(
        tester,
        size: const Size(1024, 768),
        riders: const [],
      );

      expect(find.text('Brak przypisanych kolarzy do planu żywienia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports team presets, rider selection, protocol toggles, and save callback',
        (tester) async {
      List<RiderNutritionPlanEntry>? lastChanged;
      List<RiderNutritionPlanEntry>? appliedPlan;

      await pumpPanelAtSize(
        tester,
        size: const Size(1600, 900),
        riders: sampleRiders(),
        isTimeTrial: true,
        onPlanChanged: (plan) => lastChanged = plan,
        onApplyTeamPlan: (plan) => appliedPlan = plan,
      );

      // Apply Pro Max 120 g/h preset
      await tester.tap(find.text('Pro Max 120 g/h'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastChanged, isNotNull);
      expect(lastChanged!.first.carbsGramsPerHour, 120.0);

      // Select second rider
      await tester.tap(find.text('Marek Nowak').first);
      await tester.pump(const Duration(milliseconds: 300));

      // Toggle a dose chip to reset _applyFeedbackVisible back to save prompt
      await tester.ensureVisible(find.text('110 g/h').first);
      await tester.tap(find.text('110 g/h').first);
      await tester.pump(const Duration(milliseconds: 300));

      // Commit plan
      await tester.ensureVisible(find.text('Zatwierdź Plan Żywienia'));
      await tester.tap(find.text('Zatwierdź Plan Żywienia'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(appliedPlan, isNotNull);
      expect(find.text('Plan Żywienia Zapisany'), findsOneWidget);
    });

    testWidgets('ignores interactions when disabled', (tester) async {
      List<RiderNutritionPlanEntry>? appliedPlan;

      await pumpPanelAtSize(
        tester,
        size: const Size(1024, 768),
        riders: sampleRiders(),
        enabled: false,
        onApplyTeamPlan: (plan) => appliedPlan = plan,
      );

      await tester.ensureVisible(find.text('Pro Max 120 g/h'));
      await tester.tap(find.text('Pro Max 120 g/h'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.ensureVisible(find.text('Zatwierdź Plan Żywienia'));
      await tester.tap(find.text('Zatwierdź Plan Żywienia'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(appliedPlan, isNull);
    });
  });
}
