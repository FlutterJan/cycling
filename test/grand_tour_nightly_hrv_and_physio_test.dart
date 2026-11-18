import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/medical/grand_tour_nightly_hrv_and_physio_model.dart';
import 'package:pro_peloton_manager/services/medical/grand_tour_physiotherapy_triage_service.dart';

List<RiderBaselineBiomarkers> _buildEightRiderSquadBaselines() {
  return const [
    RiderBaselineBiomarkers(
      riderId: 'r1_gc',
      riderName: 'Jan Kowalski',
      baselineHrvRmssdMs: 92.0,
      baselineRhrBpm: 40,
      baselineCkUL: 165.0,
      baselineCortisolNmolL: 380.0,
      baselineTestosteroneNmolL: 19.5,
      baselineSleepEfficiencyPct: 89.0,
    ),
    RiderBaselineBiomarkers(
      riderId: 'r2_sprint',
      riderName: 'Marek Nowak',
      baselineHrvRmssdMs: 85.0,
      baselineRhrBpm: 43,
      baselineCkUL: 185.0,
      baselineCortisolNmolL: 400.0,
      baselineTestosteroneNmolL: 18.8,
      baselineSleepEfficiencyPct: 86.0,
    ),
    RiderBaselineBiomarkers(
      riderId: 'r3_climber',
      riderName: 'Piotr Zieliński',
      baselineHrvRmssdMs: 88.0,
      baselineRhrBpm: 42,
      baselineCkUL: 170.0,
      baselineCortisolNmolL: 390.0,
      baselineTestosteroneNmolL: 18.0,
      baselineSleepEfficiencyPct: 87.0,
    ),
    RiderBaselineBiomarkers(
      riderId: 'r4_climber',
      riderName: 'Tomasz Wiśniewski',
      baselineHrvRmssdMs: 80.0,
      baselineRhrBpm: 44,
      baselineCkUL: 175.0,
      baselineCortisolNmolL: 410.0,
      baselineTestosteroneNmolL: 17.5,
      baselineSleepEfficiencyPct: 85.0,
    ),
    RiderBaselineBiomarkers(
      riderId: 'r5_captain',
      riderName: 'Łukasz Kamiński',
      baselineHrvRmssdMs: 78.0,
      baselineRhrBpm: 45,
      baselineCkUL: 180.0,
      baselineCortisolNmolL: 405.0,
      baselineTestosteroneNmolL: 17.2,
      baselineSleepEfficiencyPct: 84.0,
    ),
    RiderBaselineBiomarkers(
      riderId: 'r6_rouleur',
      riderName: 'Kamil Lewandowski',
      baselineHrvRmssdMs: 82.0,
      baselineRhrBpm: 44,
      baselineCkUL: 190.0,
      baselineCortisolNmolL: 395.0,
      baselineTestosteroneNmolL: 18.4,
      baselineSleepEfficiencyPct: 85.0,
    ),
    RiderBaselineBiomarkers(
      riderId: 'r7_rouleur',
      riderName: 'Adam Wójcik',
      baselineHrvRmssdMs: 76.0,
      baselineRhrBpm: 46,
      baselineCkUL: 182.0,
      baselineCortisolNmolL: 415.0,
      baselineTestosteroneNmolL: 16.9,
      baselineSleepEfficiencyPct: 83.0,
    ),
    RiderBaselineBiomarkers(
      riderId: 'r8_rouleur',
      riderName: 'Paweł Mazur',
      baselineHrvRmssdMs: 79.0,
      baselineRhrBpm: 45,
      baselineCkUL: 178.0,
      baselineCortisolNmolL: 400.0,
      baselineTestosteroneNmolL: 17.6,
      baselineSleepEfficiencyPct: 84.0,
    ),
  ];
}

void main() {
  group('Grand Tour Nightly HRV, CK & Physio/Charter Integration', () {
    test('enforces 8-rider squad cap and tracks 21-day Grand Tour biomarker trends', () {
      final extraSquad = [
        ..._buildEightRiderSquadBaselines(),
        const RiderBaselineBiomarkers(
          riderId: 'r9_extra',
          riderName: 'Rezerwowy Kolarz',
          baselineHrvRmssdMs: 80.0,
          baselineRhrBpm: 44,
          baselineCkUL: 170.0,
          baselineCortisolNmolL: 390.0,
          baselineTestosteroneNmolL: 18.0,
          baselineSleepEfficiencyPct: 85.0,
        ),
      ];

      var model = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'tdf_2026',
        tourName: 'Tour de France 2026',
        squadBaselines: extraSquad,
      );

      expect(model.baselines.length, GrandTourNightlyHrvAndPhysioModel.grandTourSquadSize);
      expect(model.baselines.containsKey('r9_extra'), isFalse);

      const moderateBus = BusTransferSleepImpact(
        transferDistanceKm: 95.0,
        transferDurationMinutes: 85,
        hotelArrivalHourDecimal: 20.8,
        dinnerDelayMinutes: 20,
      );
      const restDayNoTransfer = BusTransferSleepImpact(
        transferDistanceKm: 5.0,
        transferDurationMinutes: 10,
        hotelArrivalHourDecimal: 18.5,
        dinnerDelayMinutes: 0,
      );

      for (int day = 1; day <= GrandTourNightlyHrvAndPhysioModel.maxGrandTourDays; day++) {
        final isRestDay = day == 10 || day == 16;
        final isQueenMountain = day == 14 || day == 18 || day == 19;
        final workloads = <String, StageWorkloadInput>{};

        for (final riderId in model.baselines.keys) {
          workloads[riderId] = StageWorkloadInput(
            stageDay: day,
            isRestDay: isRestDay,
            stageDistanceKm: isRestDay ? 40.0 : (isQueenMountain ? 195.0 : 178.0),
            elevationGainMeters: isRestDay ? 250.0 : (isQueenMountain ? 4600.0 : 1850.0),
            kilojoulesExpended: isRestDay ? 850.0 : (isQueenMountain ? 5100.0 : 3400.0),
            intensityFactor: isRestDay ? 0.50 : (isQueenMountain ? 0.89 : 0.77),
            crashedOnStage: day == 12 && riderId == 'r4_climber',
            heatStressIndex: day >= 14 ? 0.55 : 0.25,
            recoveryProtocolApplied: riderId == 'r1_gc',
            recoveryProtocolEffectiveness: riderId == 'r1_gc' ? 0.85 : 0.0,
          );
        }

        final res = model.evaluateNightlyRecoveryAndMorningCheck(
          stageDay: day,
          workloadsByRider: workloads,
          transferImpact: isRestDay ? restDayNoTransfer : moderateBus,
          isRestDay: isRestDay,
          seed: 100,
        );
        model = res.updatedModel;
      }

      expect(model.currentStageDay, 21);
      expect(model.historyByDay.length, 21);
      expect(model.historyByDay[1]!.weekPhase, GrandTourWeekPhase.week1Opening);
      expect(model.historyByDay[10]!.weekPhase, GrandTourWeekPhase.restDay);
      expect(model.historyByDay[12]!.weekPhase, GrandTourWeekPhase.week2Attrition);
      expect(model.historyByDay[20]!.weekPhase, GrandTourWeekPhase.week3Survival);

      // Verify 21-day trend for crashed rider r4_climber vs protected leader r1_gc
      final r4Trend = model.getRiderTrend('r4_climber');
      final r1Trend = model.getRiderTrend('r1_gc');
      expect(r4Trend.length, 21);
      expect(r1Trend.length, 21);

      final day12Crashed = r4Trend[11];
      final day11BeforeCrash = r4Trend[10];
      expect(day12Crashed.creatineKinaseUL, greaterThan(day11BeforeCrash.creatineKinaseUL + 250.0));
      expect(day12Crashed.isElevatedCkAlert, isTrue);

      // Rest day (day 16) should clear CK and boost HRV compared to day 15
      final day15 = r1Trend[14];
      final day16Rest = r1Trend[15];
      expect(day16Rest.creatineKinaseUL, lessThan(day15.creatineKinaseUL));
      expect(day16Rest.hrvRmssdMs, greaterThan(day15.hrvRmssdMs));

      // Week 3 catabolic stress (C/T ratio) should be higher than Week 1
      expect(
        r4Trend[19].cortisolToTestosteroneRatio,
        greaterThan(r4Trend[2].cortisolToTestosteroneRatio),
      );

      // Rolling 7-day HRV average & readiness ranking
      final rollingAvg = model.getSevenDayHrvRollingAverage('r1_gc', 21);
      expect(rollingAvg, inInclusiveRange(18.0, 185.0));

      final ranking = model.getSquadReadinessRanking(21);
      expect(ranking.length, 8);
      for (int i = 0; i < ranking.length - 1; i++) {
        expect(ranking[i].readinessScore, greaterThanOrEqualTo(ranking[i + 1].readinessScore));
      }

      // JSON round-trip preserves full 21-day history
      final roundTrip = GrandTourNightlyHrvAndPhysioModel.fromJson(model.toJson());
      expect(roundTrip.tourId, model.tourId);
      expect(roundTrip.currentStageDay, 21);
      expect(roundTrip.historyByDay.length, 21);
      expect(
        roundTrip.historyByDay[19]!.teamAverageCkUL,
        model.historyByDay[19]!.teamAverageCkUL,
      );
    });

    test('physiotherapy triage assigns 3 specialists within time cap and improves CK, HRV & contusions', () {
      const service = GrandTourPhysiotherapyTriageService();
      const config = PhysiotherapyTriageConfig(
        stageDay: 14,
        specialistCount: 3,
        minutesPerSpecialist: 110,
      );

      const squad = [
        RiderPostStageTriageInput(
          riderId: 'r1_gc',
          riderName: 'Jan Kowalski',
          role: GrandTourTriageRole.gcLeader,
          currentHrvMs: 68.0,
          baselineHrvMs: 92.0,
          currentCkUL: 1120.0,
          currentReadinessScore: 54.0,
          plannedSleepHoursWithBus: 6.1,
        ),
        RiderPostStageTriageInput(
          riderId: 'r2_sprint',
          riderName: 'Marek Nowak',
          role: GrandTourTriageRole.sprinterLeader,
          currentHrvMs: 70.0,
          baselineHrvMs: 85.0,
          currentCkUL: 910.0,
          currentReadinessScore: 58.0,
          plannedSleepHoursWithBus: 6.1,
        ),
        RiderPostStageTriageInput(
          riderId: 'r3_climber',
          riderName: 'Piotr Zieliński',
          role: GrandTourTriageRole.mountainDomestique,
          currentHrvMs: 62.0,
          baselineHrvMs: 88.0,
          currentCkUL: 1240.0,
          currentReadinessScore: 49.0,
          plannedSleepHoursWithBus: 6.1,
          crashedOnStage: true,
          contusionHealingDaysRemaining: 4,
          contusionPainPenalty: 8.0,
        ),
        RiderPostStageTriageInput(
          riderId: 'r4_climber',
          riderName: 'Tomasz Wiśniewski',
          role: GrandTourTriageRole.mountainDomestique,
          currentHrvMs: 71.0,
          baselineHrvMs: 80.0,
          currentCkUL: 880.0,
          currentReadinessScore: 60.0,
          plannedSleepHoursWithBus: 6.1,
        ),
        RiderPostStageTriageInput(
          riderId: 'r5_captain',
          riderName: 'Łukasz Kamiński',
          role: GrandTourTriageRole.roadCaptain,
          currentHrvMs: 73.0,
          baselineHrvMs: 78.0,
          currentCkUL: 640.0,
          currentReadinessScore: 68.0,
          plannedSleepHoursWithBus: 6.1,
        ),
        RiderPostStageTriageInput(
          riderId: 'r6_rouleur',
          riderName: 'Kamil Lewandowski',
          role: GrandTourTriageRole.rouleurDomestique,
          currentHrvMs: 76.0,
          baselineHrvMs: 82.0,
          currentCkUL: 700.0,
          currentReadinessScore: 66.0,
          plannedSleepHoursWithBus: 6.1,
        ),
        RiderPostStageTriageInput(
          riderId: 'r7_rouleur',
          riderName: 'Adam Wójcik',
          role: GrandTourTriageRole.rouleurDomestique,
          currentHrvMs: 72.0,
          baselineHrvMs: 76.0,
          currentCkUL: 620.0,
          currentReadinessScore: 65.0,
          plannedSleepHoursWithBus: 6.1,
        ),
        RiderPostStageTriageInput(
          riderId: 'r8_rouleur',
          riderName: 'Paweł Mazur',
          role: GrandTourTriageRole.rouleurDomestique,
          currentHrvMs: 74.0,
          baselineHrvMs: 79.0,
          currentCkUL: 610.0,
          currentReadinessScore: 67.0,
          plannedSleepHoursWithBus: 6.1,
        ),
      ];

      final assignments = service.autoAssignOptimalTriage(
        squad: squad,
        config: config,
      );

      expect(assignments, isNotEmpty);

      // Total minutes must not exceed 3 * 110 = 330 min
      final totalMinutes = assignments.fold<int>(0, (s, a) => s + a.durationMinutes);
      expect(totalMinutes, lessThanOrEqualTo(config.totalSpecialistMinutes));

      // All specialist slot indices must be within 0..2
      for (final a in assignments) {
        expect(a.specialistSlotIndex, inInclusiveRange(0, config.specialistCount - 1));
      }

      // Crashed rider r3_climber must receive Tecar / Ultrasound
      expect(
        assignments.any(
          (a) =>
              a.riderId == 'r3_climber' &&
              a.treatment == PhysiotherapyTreatmentType.tecarAndUltrasound,
        ),
        isTrue,
      );

      // Duplicate treatment for same rider is rejected
      final dupCheck = service.canAssignTreatment(
        riderId: 'r3_climber',
        treatment: PhysiotherapyTreatmentType.tecarAndUltrasound,
        currentAssignments: assignments,
        config: config,
      );
      expect(dupCheck.allowed, isFalse);

      // Evaluate with 4-hour bus transfer
      final busReport = service.evaluateTriagePlan(
        squad: squad,
        assignments: assignments,
        transportDecision: TransferTransportDecision.fourHourTeamBus,
        config: config,
      );

      expect(busReport.charterCostEur, 0);
      expect(busReport.averageTeamReadinessAfter, greaterThan(busReport.averageTeamReadinessBefore));
      expect(busReport.averageTeamHrvDeltaMs, greaterThan(0.0));
      expect(busReport.averageTeamCkReductionPct, greaterThan(0.0));

      final r1Outcome = busReport.riderOutcomes.firstWhere((o) => o.riderId == 'r1_gc');
      expect(r1Outcome.ckReductionPercent, closeTo(25.0, 0.2));
      expect(r1Outcome.hrvDeltaMs, greaterThanOrEqualTo(12.0));

      final r3Outcome = busReport.riderOutcomes.firstWhere((o) => o.riderId == 'r3_climber');
      expect(r3Outcome.projectedContusionDays, lessThan(r3Outcome.initialContusionDays));
    });

    test('air charter grants +2h sleep and higher HRV/readiness than 4h bus, respecting budget', () {
      const service = GrandTourPhysiotherapyTriageService();
      const config = PhysiotherapyTriageConfig(
        stageDay: 17,
        specialistCount: 3,
        minutesPerSpecialist: 110,
        charterFlightCostEur: 18500,
        charterSleepBonusHours: 2.0,
      );

      const gruelingBus = BusTransferSleepImpact(
        transferDistanceKm: 210.0,
        transferDurationMinutes: 240,
        hotelArrivalHourDecimal: 22.4,
        dinnerDelayMinutes: 55,
        roomNoiseOrHeatDisturbance: 0.35,
      );

      final charterTransfer = service.resolveTransferLogistics(
        baseBusTransfer: gruelingBus,
        decision: TransferTransportDecision.airCharterForLeaders,
      );

      expect(gruelingBus.severity, TransferLogisticsSeverity.gruelingBusTransfer);
      expect(charterTransfer.transferDurationMinutes, lessThanOrEqualTo(55));
      expect(charterTransfer.hotelArrivalHourDecimal, lessThanOrEqualTo(19.25));
      expect(charterTransfer.dinnerDelayMinutes, 0);
      expect(
        charterTransfer.sleepQualityPenaltyPoints,
        lessThan(gruelingBus.sleepQualityPenaltyPoints),
      );

      const squad = [
        RiderPostStageTriageInput(
          riderId: 'r1_gc',
          riderName: 'Jan Kowalski',
          role: GrandTourTriageRole.gcLeader,
          currentHrvMs: 65.0,
          baselineHrvMs: 92.0,
          currentCkUL: 1050.0,
          currentReadinessScore: 52.0,
          plannedSleepHoursWithBus: 5.8,
        ),
        RiderPostStageTriageInput(
          riderId: 'r6_rouleur',
          riderName: 'Kamil Lewandowski',
          role: GrandTourTriageRole.rouleurDomestique,
          currentHrvMs: 70.0,
          baselineHrvMs: 82.0,
          currentCkUL: 780.0,
          currentReadinessScore: 60.0,
          plannedSleepHoursWithBus: 5.8,
        ),
      ];

      final assignments = service.autoAssignOptimalTriage(squad: squad, config: config);

      final charterReport = service.evaluateTriagePlan(
        squad: squad,
        assignments: assignments,
        transportDecision: TransferTransportDecision.airCharterForLeaders,
        config: config,
        availableBudgetEur: 50000,
      );

      final busReport = service.evaluateTriagePlan(
        squad: squad,
        assignments: assignments,
        transportDecision: TransferTransportDecision.fourHourTeamBus,
        config: config,
        availableBudgetEur: 50000,
      );

      expect(charterReport.transportDecision, TransferTransportDecision.airCharterForLeaders);
      expect(charterReport.charterCostEur, 18500);

      final gcCharter = charterReport.riderOutcomes.firstWhere((o) => o.riderId == 'r1_gc');
      final gcBus = busReport.riderOutcomes.firstWhere((o) => o.riderId == 'r1_gc');
      final domCharter = charterReport.riderOutcomes.firstWhere((o) => o.riderId == 'r6_rouleur');

      expect(gcCharter.receivedCharterFlightSleepBonus, isTrue);
      expect(gcCharter.sleepBonusHours, closeTo(2.0, 0.01));
      expect(gcCharter.projectedSleepHours, closeTo(gcBus.projectedSleepHours + 2.0, 0.01));
      expect(gcCharter.projectedHrvMs, greaterThan(gcBus.projectedHrvMs));
      expect(gcCharter.projectedReadinessScore, greaterThan(gcBus.projectedReadinessScore));
      expect(domCharter.receivedCharterFlightSleepBonus, isFalse);

      // Insufficient budget falls back to 4h team bus
      final lowBudgetReport = service.evaluateTriagePlan(
        squad: squad,
        assignments: assignments,
        transportDecision: TransferTransportDecision.airCharterForLeaders,
        config: config,
        availableBudgetEur: 5000,
      );
      expect(lowBudgetReport.transportDecision, TransferTransportDecision.fourHourTeamBus);
      expect(lowBudgetReport.charterCostEur, 0);

      // Integrated check with GrandTourNightlyHrvAndPhysioModel
      final baseModel = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'vuelta_2026',
        tourName: 'La Vuelta 2026',
        squadBaselines: _buildEightRiderSquadBaselines(),
      );

      final withCharterAndPhysio = baseModel.evaluateNightlyRecoveryAndMorningCheck(
        stageDay: 17,
        workloadsByRider: {
          for (final id in baseModel.baselines.keys)
            id: const StageWorkloadInput(
              stageDay: 17,
              stageDistanceKm: 185.0,
              elevationGainMeters: 3900.0,
              kilojoulesExpended: 4400.0,
              intensityFactor: 0.85,
              recoveryProtocolApplied: true,
              recoveryProtocolEffectiveness: 0.9,
            ),
        },
        transferImpact: charterTransfer,
        seed: 77,
      );

      final withGruelingBusOnly = baseModel.evaluateNightlyRecoveryAndMorningCheck(
        stageDay: 17,
        workloadsByRider: {
          for (final id in baseModel.baselines.keys)
            id: const StageWorkloadInput(
              stageDay: 17,
              stageDistanceKm: 185.0,
              elevationGainMeters: 3900.0,
              kilojoulesExpended: 4400.0,
              intensityFactor: 0.85,
              recoveryProtocolApplied: false,
              recoveryProtocolEffectiveness: 0.0,
            ),
        },
        transferImpact: gruelingBus,
        seed: 77,
      );

      expect(
        withCharterAndPhysio.report.teamAverageHrvMs,
        greaterThan(withGruelingBusOnly.report.teamAverageHrvMs),
      );
      expect(
        withCharterAndPhysio.report.teamAverageCkUL,
        lessThan(withGruelingBusOnly.report.teamAverageCkUL),
      );
      expect(
        withCharterAndPhysio.report.teamAverageSleepScore,
        greaterThan(withGruelingBusOnly.report.teamAverageSleepScore),
      );
      expect(
        withCharterAndPhysio.report.teamAverageReadiness,
        greaterThan(withGruelingBusOnly.report.teamAverageReadiness),
      );
    });
  });
}
