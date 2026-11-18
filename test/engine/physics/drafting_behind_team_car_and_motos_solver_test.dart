import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/drafting_behind_team_car_and_motos_solver.dart';

void main() {
  group('DraftingBehindTeamCarAndMotosSolver', () {
    test('Team DS car provides significantly deeper and longer wake than TV moto', () {
      const double speedMs = 13.5; // 48.6 km/h

      final carResult = DraftingBehindTeamCarAndMotosSolver.solveInstantDrafting(
        const CaravanDraftingInput(
          vehicleType: CaravanVehicleType.teamSupportCar,
          longitudinalDistanceMeters: 3.0,
          riderSpeedMs: speedMs,
          hasRoofBikeRack: true,
        ),
      );

      final motoResult = DraftingBehindTeamCarAndMotosSolver.solveInstantDrafting(
        const CaravanDraftingInput(
          vehicleType: CaravanVehicleType.tvBroadcastMoto,
          longitudinalDistanceMeters: 3.0,
          riderSpeedMs: speedMs,
        ),
      );

      expect(carResult.dragReductionFraction, greaterThan(0.60));
      expect(motoResult.dragReductionFraction, inInclusiveRange(0.20, 0.36));
      expect(
        carResult.aeroPowerSavedWatts,
        greaterThan(motoResult.aeroPowerSavedWatts * 1.6),
      );
      expect(carResult.isoPowerSpeedGainKmh, greaterThan(5.0));
      expect(carResult.effectiveCdA, lessThan(motoResult.effectiveCdA));
    });

    test('Crosswind deflects aerodynamic wake laterally downwind', () {
      // Wiatr z lewej na prawo (+6 m/s) przesuwa cień w prawo (+lateralOffset)
      final centeredInCrosswind =
          DraftingBehindTeamCarAndMotosSolver.solveInstantDrafting(
        const CaravanDraftingInput(
          vehicleType: CaravanVehicleType.teamSupportCar,
          longitudinalDistanceMeters: 6.0,
          lateralOffsetMeters: 0.0,
          riderSpeedMs: 12.0,
          crosswindMs: 6.0,
        ),
      );

      final shiftedDownwind =
          DraftingBehindTeamCarAndMotosSolver.solveInstantDrafting(
        const CaravanDraftingInput(
          vehicleType: CaravanVehicleType.teamSupportCar,
          longitudinalDistanceMeters: 6.0,
          lateralOffsetMeters: 3.0,
          riderSpeedMs: 12.0,
          crosswindMs: 6.0,
        ),
      );

      expect(centeredInCrosswind.wakeLateralShiftMeters, greaterThan(2.0));
      expect(
        shiftedDownwind.effectiveLateralMissMeters,
        lessThan(centeredInCrosswind.effectiveLateralMissMeters),
      );
      expect(
        shiftedDownwind.dragReductionFraction,
        greaterThan(centeredInCrosswind.dragReductionFraction),
      );
    });

    test('Out-of-range distance or stationary rider returns zero draft and decays exposure', () {
      final farResult = DraftingBehindTeamCarAndMotosSolver.solveInstantDrafting(
        const CaravanDraftingInput(
          vehicleType: CaravanVehicleType.teamSupportCar,
          longitudinalDistanceMeters: 55.0,
          riderSpeedMs: 12.0,
          currentPenaltyExposure: 40.0,
        ),
        dtSeconds: 4.0,
      );

      expect(farResult.dragReductionFraction, 0.0);
      expect(farResult.aeroPowerSavedWatts, 0.0);
      expect(farResult.updatedPenaltyExposure, lessThan(40.0));
      expect(farResult.isDangerouslyCloseToBumper, isFalse);
    });

    test('Final <20 km context and commissaire sight escalate UCI penalty risk', () {
      final mechanicalReturn =
          DraftingBehindTeamCarAndMotosSolver.solveInstantDrafting(
        const CaravanDraftingInput(
          vehicleType: CaravanVehicleType.teamSupportCar,
          longitudinalDistanceMeters: 2.2,
          riderSpeedMs: 13.0,
          context: CaravanDraftingContext.mechanicalOrCrashReturn,
          commissaireInSight: false,
          currentPenaltyExposure: 20.0,
        ),
        dtSeconds: 5.0,
      );

      final finalKmBreak =
          DraftingBehindTeamCarAndMotosSolver.solveInstantDrafting(
        const CaravanDraftingInput(
          vehicleType: CaravanVehicleType.teamSupportCar,
          longitudinalDistanceMeters: 2.2,
          riderSpeedMs: 13.0,
          context: CaravanDraftingContext.finalKilometersNoShelter,
          commissaireInSight: true,
          isTvCameraFocused: true,
          exposureDurationSeconds: 25.0,
          currentPenaltyExposure: 45.0,
        ),
        dtSeconds: 10.0,
      );

      expect(
        finalKmBreak.penaltyExposureRatePerSec,
        greaterThan(mechanicalReturn.penaltyExposureRatePerSec * 4.0),
      );
      expect(finalKmBreak.updatedPenaltyExposure, greaterThanOrEqualTo(80.0));
      expect(
        finalKmBreak.riskLevel,
        CaravanPenaltyRiskLevel.timePenaltyRisk,
      );
      expect(finalKmBreak.projectedTimePenaltySeconds, greaterThanOrEqualTo(20));
      expect(finalKmBreak.projectedFineChf, 200);
    });

    test('Dangerous bumper proximity (<0.9m) flags collision/sticky-bottle risk', () {
      final bumperResult =
          DraftingBehindTeamCarAndMotosSolver.solveInstantDrafting(
        const CaravanDraftingInput(
          vehicleType: CaravanVehicleType.teamSupportCar,
          longitudinalDistanceMeters: 0.65,
          lateralOffsetMeters: 0.1,
          riderSpeedMs: 13.0,
        ),
      );

      expect(bumperResult.isDangerouslyCloseToBumper, isTrue);
    });

    test('Caravan convoy bridge simulation catches peloton faster and saves energy', () {
      final bridge =
          DraftingBehindTeamCarAndMotosSolver.simulateCaravanConvoyBridge(
        initialGapMeters: 180.0,
        convoyCarCount: 10,
        carSpacingMeters: 15.0,
        riderTargetPowerWatts: 380.0,
        pelotonSpeedMs: 12.2,
        context: CaravanDraftingContext.mechanicalOrCrashReturn,
      );

      expect(bridge.didCatchPeloton, isTrue);
      expect(bridge.totalTimeSeconds, greaterThan(0.0));
      expect(
        bridge.totalTimeSeconds,
        lessThan(bridge.estimatedSoloChaseTimeSeconds),
      );
      expect(bridge.timeSavedVsSoloSeconds, greaterThan(10.0));
      expect(bridge.averageDragReductionFraction, greaterThan(0.25));
      expect(bridge.energySavedKilojoules, greaterThan(5.0));
      expect(bridge.timeline, isNotEmpty);
      expect(bridge.timeline.last.remainingGapMeters, lessThanOrEqualTo(0.5));
    });
  });
}
