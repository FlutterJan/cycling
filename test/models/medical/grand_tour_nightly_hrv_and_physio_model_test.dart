import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/medical/grand_tour_nightly_hrv_and_physio_model.dart';

void main() {
  List<RiderBaselineBiomarkers> buildEightRiders() {
    return List<RiderBaselineBiomarkers>.generate(8, (index) {
      return RiderBaselineBiomarkers(
        riderId: 'rider_${index + 1}',
        riderName: 'Kolarz ${index + 1}',
        baselineHrvRmssdMs: 82.0 + index * 3.0,
        baselineRhrBpm: 38 + index,
        baselineCkUL: 140.0 + index * 5.0,
        baselineCortisolNmolL: 420.0,
        baselineTestosteroneNmolL: 16.5,
        baselineSleepEfficiencyPct: 91.0,
      );
    });
  }

  group('GrandTourNightlyHrvAndPhysioModel', () {
    test('initializes squad capped at 8 riders', () {
      final tenRiders = [
        ...buildEightRiders(),
        const RiderBaselineBiomarkers(
          riderId: 'rider_9',
          riderName: 'Rezerwowy 9',
          baselineHrvRmssdMs: 75.0,
          baselineRhrBpm: 42,
          baselineCkUL: 150.0,
          baselineCortisolNmolL: 410.0,
          baselineTestosteroneNmolL: 15.0,
          baselineSleepEfficiencyPct: 90.0,
        ),
      ];

      final model = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'tdf_2026',
        tourName: 'Tour de France 2026',
        squadBaselines: tenRiders,
      );

      expect(model.baselines.length, 8);
      expect(model.baselines.containsKey('rider_9'), isFalse);
    });

    test('grueling bus transfer degrades sleep quality and increases cortisol', () {
      final model = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'giro_2026',
        tourName: "Giro d'Italia 2026",
        squadBaselines: buildEightRiders(),
      );

      const easyTransfer = BusTransferSleepImpact(
        transferDistanceKm: 12.0,
        transferDurationMinutes: 20,
        hotelArrivalHourDecimal: 18.5,
        dinnerDelayMinutes: 0,
      );

      const gruelingTransfer = BusTransferSleepImpact(
        transferDistanceKm: 235.0,
        transferDurationMinutes: 210,
        hotelArrivalHourDecimal: 23.0,
        dinnerDelayMinutes: 75,
        altitudeHotelMeters: 2150.0,
        roomNoiseOrHeatDisturbance: 0.7,
      );

      expect(easyTransfer.severity, TransferLogisticsSeverity.noTransfer);
      expect(
        gruelingTransfer.severity,
        TransferLogisticsSeverity.gruelingBusTransfer,
      );

      final easyResult = model.evaluateNightlyRecoveryAndMorningCheck(
        stageDay: 5,
        workloadsByRider: const {},
        transferImpact: easyTransfer,
        seed: 100,
      );

      final hardResult = model.evaluateNightlyRecoveryAndMorningCheck(
        stageDay: 5,
        workloadsByRider: const {},
        transferImpact: gruelingTransfer,
        seed: 100,
      );

      expect(
        hardResult.report.teamAverageSleepScore,
        lessThan(easyResult.report.teamAverageSleepScore - 20.0),
      );
      expect(
        hardResult.report.rosterSamples.first.cortisolNmolL,
        greaterThan(easyResult.report.rosterSamples.first.cortisolNmolL),
      );
      expect(
        hardResult.report.rosterSamples.first.totalSleepHours,
        lessThan(easyResult.report.rosterSamples.first.totalSleepHours),
      );
    });

    test('tracks CK spike after crash and clearance on rest day', () {
      var model = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'vuelta_2026',
        tourName: 'La Vuelta a España 2026',
        squadBaselines: buildEightRiders(),
      );

      const shortTransfer = BusTransferSleepImpact(
        transferDistanceKm: 45.0,
        transferDurationMinutes: 50,
        hotelArrivalHourDecimal: 19.5,
        dinnerDelayMinutes: 10,
      );

      final stage15 = model.evaluateNightlyRecoveryAndMorningCheck(
        stageDay: 15,
        workloadsByRider: {
          'rider_1': const StageWorkloadInput(
            stageDay: 15,
            stageDistanceKm: 198.0,
            elevationGainMeters: 4600.0,
            kilojoulesExpended: 4950.0,
            intensityFactor: 0.89,
            crashedOnStage: true,
          ),
        },
        transferImpact: shortTransfer,
      );
      model = stage15.updatedModel;

      final rider1Stage15 = stage15.report.rosterSamples
          .firstWhere((s) => s.riderId == 'rider_1');
      expect(rider1Stage15.creatineKinaseUL, greaterThan(850.0));
      expect(rider1Stage15.isElevatedCkAlert, isTrue);

      final restDay16 = model.evaluateNightlyRecoveryAndMorningCheck(
        stageDay: 16,
        isRestDay: true,
        workloadsByRider: {
          'rider_1': const StageWorkloadInput(
            stageDay: 16,
            isRestDay: true,
            stageDistanceKm: 38.0,
            elevationGainMeters: 250.0,
            kilojoulesExpended: 800.0,
            intensityFactor: 0.48,
            recoveryProtocolApplied: true,
            recoveryProtocolEffectiveness: 0.9,
          ),
        },
        transferImpact: const BusTransferSleepImpact(
          transferDistanceKm: 0.0,
          transferDurationMinutes: 0,
          hotelArrivalHourDecimal: 18.0,
          dinnerDelayMinutes: 0,
        ),
      );
      model = restDay16.updatedModel;

      final rider1Rest = restDay16.report.rosterSamples
          .firstWhere((s) => s.riderId == 'rider_1');
      expect(rider1Rest.creatineKinaseUL, lessThan(rider1Stage15.creatineKinaseUL));
      expect(model.getRiderTrend('rider_1').length, 2);
      expect(model.getSquadReadinessRanking(16).length, 8);
    });

    test('JSON serialization round-trip preserves state', () {
      final initial = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'tdf_2026',
        tourName: 'Tour de France 2026',
        squadBaselines: buildEightRiders(),
      );

      final result = initial.evaluateNightlyRecoveryAndMorningCheck(
        stageDay: 3,
        workloadsByRider: const {},
        transferImpact: const BusTransferSleepImpact(
          transferDistanceKm: 95.0,
          transferDurationMinutes: 90,
          hotelArrivalHourDecimal: 20.75,
          dinnerDelayMinutes: 25,
        ),
      );

      final json = result.updatedModel.toJson();
      final restored = GrandTourNightlyHrvAndPhysioModel.fromJson(json);

      expect(restored.tourId, result.updatedModel.tourId);
      expect(restored.currentStageDay, 3);
      expect(restored.baselines.length, 8);
      expect(restored.historyByDay[3]?.rosterSamples.length, 8);
      expect(
        restored.historyByDay[3]?.teamAverageHrvMs,
        result.report.teamAverageHrvMs,
      );
    });
  });
}
