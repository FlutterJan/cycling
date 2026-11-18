import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/drafting_behind_team_car_and_motos_solver.dart';
import 'package:pro_peloton_manager/ui/widgets/caravan_drafting_risk_meter_hud.dart';

void main() {
  group('CaravanDraftingRiskHudData', () {
    test('builds cleanly from DraftingBehindTeamCarAndMotosSolver output', () {
      const CaravanDraftingInput input = CaravanDraftingInput(
        vehicleType: CaravanVehicleType.teamSupportCar,
        longitudinalDistanceMeters: 1.8,
        riderSpeedMs: 14.5,
        context: CaravanDraftingContext.droppedRiderConvoyHop,
        commissaireInSight: true,
        isTvCameraFocused: true,
        exposureDurationSeconds: 22.0,
        currentPenaltyExposure: 58.0,
      );
      final CaravanDraftingResult result =
          DraftingBehindTeamCarAndMotosSolver.solveInstantDrafting(
        input,
        dtSeconds: 1.0,
      );

      final CaravanDraftingRiskHudData hudData =
          CaravanDraftingRiskHudData.fromSolver(
        riderName: 'K. Vauquelin',
        riderTeamCode: 'ARK',
        input: input,
        result: result,
        remainingGapToPelotonMeters: 180.0,
      );

      expect(hudData.riderName, 'K. Vauquelin');
      expect(hudData.riderTeamCode, 'ARK');
      expect(hudData.aeroPowerSavedWatts, greaterThan(0.0));
      expect(hudData.penaltyExposurePercent, inInclusiveRange(0.0, 100.0));
      expect(hudData.commissaireInSight, isTrue);
      expect(hudData.isTvCameraFocused, isTrue);
      expect(hudData.remainingGapToPelotonMeters, 180.0);
    });

    test('sanitizes NaN/Infinity and supports JSON round-trip', () {
      const CaravanDraftingRiskHudData raw = CaravanDraftingRiskHudData(
        riderName: 'M. Van Wilder',
        riderTeamCode: 'SOQ',
        vehicleType: CaravanVehicleType.neutralServiceCar,
        context: CaravanDraftingContext.mechanicalOrCrashReturn,
        riskLevel: CaravanPenaltyRiskLevel.warning,
        penaltyExposurePercent: 42.5,
        exposureRatePerSec: 1.8,
        timePenaltyProbability: 0.25,
        projectedTimePenaltySeconds: 0,
        projectedFineChf: 200,
        longitudinalDistanceMeters: 2.2,
        aeroPowerSavedWatts: 195.0,
        dragReductionPercent: 61.0,
        riderSpeedKmh: 52.4,
        commissaireInSight: false,
        isTvCameraFocused: true,
        isDangerouslyCloseToBumper: false,
        remainingGapToPelotonMeters: 95.0,
      );

      final Map<String, dynamic> json = raw.toJson();
      final CaravanDraftingRiskHudData restored =
          CaravanDraftingRiskHudData.fromJson(json);

      expect(restored.riderName, raw.riderName);
      expect(restored.vehicleType, raw.vehicleType);
      expect(restored.riskLevel, raw.riskLevel);
      expect(restored.penaltyExposurePercent, 42.5);
      expect(restored.projectedFineChf, 200);

      final CaravanDraftingRiskHudData nanData = raw.copyWith(
        penaltyExposurePercent: double.nan,
      );
      expect(nanData.safeExposurePercent, 0.0);
    });
  });

  group('CaravanDraftingRiskMeterHud widget', () {
    CaravanDraftingRiskHudData makeSampleData({
      CaravanPenaltyRiskLevel riskLevel = CaravanPenaltyRiskLevel.timePenaltyRisk,
      double exposure = 88.0,
      bool isEnabled = true,
      bool bumperDanger = true,
    }) {
      return CaravanDraftingRiskHudData(
        riderName: 'T. Pogacar',
        riderTeamCode: 'UAD',
        vehicleType: CaravanVehicleType.teamSupportCar,
        context: CaravanDraftingContext.finalKilometersNoShelter,
        riskLevel: riskLevel,
        penaltyExposurePercent: exposure,
        exposureRatePerSec: 4.5,
        timePenaltyProbability: 0.84,
        projectedTimePenaltySeconds: 20,
        projectedFineChf: 200,
        longitudinalDistanceMeters: bumperDanger ? 0.7 : 2.5,
        aeroPowerSavedWatts: 245.0,
        dragReductionPercent: 68.0,
        riderSpeedKmh: 55.2,
        isoPowerSpeedGainKmh: 8.4,
        commissaireInSight: true,
        isTvCameraFocused: true,
        isDangerouslyCloseToBumper: bumperDanger,
        remainingGapToPelotonMeters: 120.0,
        isEnabled: isEnabled,
      );
    }

    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size,
      CaravanDraftingRiskHudData data, {
      ValueChanged<CaravanTacticalAction>? onAction,
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
            backgroundColor: const Color(0xFF0F1115),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: CaravanDraftingRiskMeterHud(
                data: data,
                onActionSelected: onAction,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          await pumpAtSize(tester, viewport, makeSampleData());

          expect(find.byType(CaravanDraftingRiskMeterHud), findsOneWidget);
          expect(find.textContaining('T. Pogacar'), findsOneWidget);
          expect(find.text('88%'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('handles action taps, disabled state, and collapse toggle', (
      WidgetTester tester,
    ) async {
      final List<CaravanTacticalAction> tapped = <CaravanTacticalAction>[];
      await pumpAtSize(
        tester,
        const Size(1024, 768),
        makeSampleData(isEnabled: true),
        onAction: tapped.add,
      );

      await tester.tap(find.text('Opuść cień'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tapped, <CaravanTacticalAction>[CaravanTacticalAction.easeOutOfWake]);

      // Collapse HUD
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Opuść cień'), findsNothing);

      // Expand HUD again
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Opuść cień'), findsOneWidget);

      // Disabled HUD should ignore taps
      await pumpAtSize(
        tester,
        const Size(1024, 768),
        makeSampleData(
          riskLevel: CaravanPenaltyRiskLevel.clean,
          exposure: 12.0,
          isEnabled: false,
          bumperDanger: false,
        ),
        onAction: tapped.add,
      );
      await tester.tap(find.text('Trzymaj cień'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tapped.length, 1);
    });
  });
}
