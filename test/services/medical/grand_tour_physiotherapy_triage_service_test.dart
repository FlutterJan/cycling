import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/medical/grand_tour_nightly_hrv_and_physio_model.dart';
import 'package:pro_peloton_manager/services/medical/grand_tour_physiotherapy_triage_service.dart';

void main() {
  group('GrandTourPhysiotherapyTriageService', () {
    const service = GrandTourPhysiotherapyTriageService();

    final sampleSquad = <RiderPostStageTriageInput>[
      const RiderPostStageTriageInput(
        riderId: 'r1',
        riderName: 'Lider GC',
        role: GrandTourTriageRole.gcLeader,
        currentHrvMs: 60.0,
        baselineHrvMs: 80.0,
        currentCkUL: 1000.0,
        currentReadinessScore: 62.0,
        plannedSleepHoursWithBus: 6.0,
      ),
      const RiderPostStageTriageInput(
        riderId: 'r2',
        riderName: 'Sprinter po kraksie',
        role: GrandTourTriageRole.sprinterLeader,
        currentHrvMs: 70.0,
        baselineHrvMs: 78.0,
        currentCkUL: 800.0,
        currentReadinessScore: 65.0,
        plannedSleepHoursWithBus: 6.2,
        crashedOnStage: true,
        contusionHealingDaysRemaining: 4,
        contusionPainPenalty: 8.0,
      ),
      const RiderPostStageTriageInput(
        riderId: 'r3',
        riderName: 'Pomocnik Górski',
        role: GrandTourTriageRole.mountainDomestique,
        currentHrvMs: 72.0,
        baselineHrvMs: 75.0,
        currentCkUL: 900.0,
        currentReadinessScore: 68.0,
        plannedSleepHoursWithBus: 6.1,
      ),
    ];

    test('Głęboki Masaż Powięziowy redukuje CK o dokładnie 25%', () {
      const config = PhysiotherapyTriageConfig(stageDay: 10);
      final report = service.evaluateTriagePlan(
        squad: [sampleSquad.first],
        assignments: const [
          PhysiotherapyTreatmentAssignment(
            riderId: 'r1',
            treatment: PhysiotherapyTreatmentType.deepFasciaMassage,
            specialistSlotIndex: 0,
            durationMinutes: 45,
          ),
        ],
        transportDecision: TransferTransportDecision.fourHourTeamBus,
        config: config,
      );

      final outcome = report.riderOutcomes.single;
      expect(outcome.initialCkUL, 1000.0);
      expect(outcome.projectedCkUL, 750.0);
      expect(outcome.ckReductionPercent, 25.0);
    });

    test('Krioterapia Ogólnoustrojowa podnosi nocne HRV o +12 ms', () {
      const config = PhysiotherapyTriageConfig(stageDay: 10);
      final report = service.evaluateTriagePlan(
        squad: [sampleSquad.first],
        assignments: const [
          PhysiotherapyTreatmentAssignment(
            riderId: 'r1',
            treatment: PhysiotherapyTreatmentType.wholeBodyCryotherapy,
            specialistSlotIndex: 0,
            durationMinutes: 25,
          ),
        ],
        transportDecision: TransferTransportDecision.fourHourTeamBus,
        config: config,
      );

      final outcome = report.riderOutcomes.single;
      expect(outcome.initialHrvMs, 60.0);
      expect(outcome.projectedHrvMs, 72.0);
      expect(outcome.hrvDeltaMs, 12.0);
    });

    test('Terapia Tecar / Ultradźwięki przyspiesza gojenie stłuczeń po kraksie', () {
      const config = PhysiotherapyTriageConfig(stageDay: 10);
      final report = service.evaluateTriagePlan(
        squad: [sampleSquad[1]],
        assignments: const [
          PhysiotherapyTreatmentAssignment(
            riderId: 'r2',
            treatment: PhysiotherapyTreatmentType.tecarAndUltrasound,
            specialistSlotIndex: 1,
            durationMinutes: 40,
          ),
        ],
        transportDecision: TransferTransportDecision.fourHourTeamBus,
        config: config,
      );

      final outcome = report.riderOutcomes.single;
      expect(outcome.initialContusionDays, 4);
      expect(outcome.projectedContusionDays, 2);
      expect(outcome.readinessDelta, greaterThan(7.0));
    });

    test('Czarter lotniczy daje liderom +2h snu i redukuje stratę transferu', () {
      const config = PhysiotherapyTriageConfig(
        stageDay: 14,
        charterFlightCostEur: 18500,
        charterSleepBonusHours: 2.0,
      );

      final report = service.evaluateTriagePlan(
        squad: sampleSquad,
        assignments: const [],
        transportDecision: TransferTransportDecision.airCharterForLeaders,
        config: config,
        availableBudgetEur: 50000,
      );

      expect(report.charterCostEur, 18500);
      expect(report.riderOutcomes[0].receivedCharterFlightSleepBonus, isTrue);
      expect(report.riderOutcomes[0].sleepBonusHours, 2.0);
      expect(report.riderOutcomes[0].projectedSleepHours, 8.0);
      expect(report.riderOutcomes[1].receivedCharterFlightSleepBonus, isTrue);
      expect(report.riderOutcomes[2].receivedCharterFlightSleepBonus, isFalse);
      expect(report.riderOutcomes[2].sleepBonusHours, 0.0);

      const baseBus = BusTransferSleepImpact(
        transferDistanceKm: 220,
        transferDurationMinutes: 240,
        hotelArrivalHourDecimal: 22.0,
        dinnerDelayMinutes: 45,
      );
      final resolved = service.resolveTransferLogistics(
        baseBusTransfer: baseBus,
        decision: TransferTransportDecision.airCharterForLeaders,
      );
      expect(resolved.transferDurationMinutes, lessThanOrEqualTo(55));
      expect(resolved.dinnerDelayMinutes, 0);
      expect(
        resolved.sleepDurationPenaltyMinutes,
        lessThan(baseBus.sleepDurationPenaltyMinutes),
      );
    });

    test('Pilnuje limitu czasu 3 specjalistów i blokuje duplikaty zabiegów', () {
      const tightConfig = PhysiotherapyTriageConfig(
        specialistCount: 1,
        minutesPerSpecialist: 60,
      );

      final firstCheck = service.canAssignTreatment(
        riderId: 'r1',
        treatment: PhysiotherapyTreatmentType.deepFasciaMassage,
        currentAssignments: const [],
        config: tightConfig,
      );
      expect(firstCheck.allowed, isTrue);

      const existing = [
        PhysiotherapyTreatmentAssignment(
          riderId: 'r1',
          treatment: PhysiotherapyTreatmentType.deepFasciaMassage,
          specialistSlotIndex: 0,
          durationMinutes: 45,
        ),
      ];

      final duplicateCheck = service.canAssignTreatment(
        riderId: 'r1',
        treatment: PhysiotherapyTreatmentType.deepFasciaMassage,
        currentAssignments: existing,
        config: tightConfig,
      );
      expect(duplicateCheck.allowed, isFalse);

      final overTimeCheck = service.canAssignTreatment(
        riderId: 'r2',
        treatment: PhysiotherapyTreatmentType.wholeBodyCryotherapy,
        currentAssignments: existing,
        config: tightConfig,
      );
      expect(overTimeCheck.allowed, isFalse);
    });

    test('autoAssignOptimalTriage przydziela zabiegi priorytetowo w ramach limitu', () {
      const config = PhysiotherapyTriageConfig(
        specialistCount: 3,
        minutesPerSpecialist: 110,
      );
      final state = GrandTourPhysiotherapyTriageState.demo();
      final auto = service.autoAssignOptimalTriage(
        squad: state.squad,
        config: config,
      );

      final usedMinutes =
          auto.fold<int>(0, (sum, a) => sum + a.durationMinutes);
      expect(auto, isNotEmpty);
      expect(usedMinutes, lessThanOrEqualTo(config.totalSpecialistMinutes));
      expect(
        auto.any(
          (a) =>
              a.riderId == 'r2' &&
              a.treatment == PhysiotherapyTreatmentType.tecarAndUltrasound,
        ),
        isTrue,
      );
      expect(
        auto.any(
          (a) =>
              a.riderId == 'r1' &&
              a.treatment == PhysiotherapyTreatmentType.deepFasciaMassage,
        ),
        isTrue,
      );
    });

    test('fromMorningReport konwertuje raport GrandTourNightlyHrvAndPhysioModel', () {
      final model = GrandTourNightlyHrvAndPhysioModel.initializeSquad(
        tourId: 'tdf_2026',
        tourName: 'Tour de France',
        squadBaselines: const [
          RiderBaselineBiomarkers(
            riderId: 'r1',
            riderName: 'Lider',
            baselineHrvRmssdMs: 82.0,
            baselineRhrBpm: 42,
            baselineCkUL: 220.0,
            baselineCortisolNmolL: 410.0,
            baselineTestosteroneNmolL: 22.0,
            baselineSleepEfficiencyPct: 86.0,
          ),
        ],
      );
      final eval = model.evaluateNightlyRecoveryAndMorningCheck(
        stageDay: 11,
        workloadsByRider: const {
          'r1': StageWorkloadInput(
            stageDay: 11,
            stageDistanceKm: 195,
            elevationGainMeters: 4200,
            kilojoulesExpended: 4400,
            intensityFactor: 0.85,
            crashedOnStage: true,
          ),
        },
        transferImpact: const BusTransferSleepImpact(
          transferDistanceKm: 180,
          transferDurationMinutes: 240,
          hotelArrivalHourDecimal: 21.5,
          dinnerDelayMinutes: 30,
        ),
      );

      final converted = GrandTourPhysiotherapyTriageService.fromMorningReport(
        report: eval.report,
        baselines: model.baselines,
        rolesByRiderId: const {'r1': GrandTourTriageRole.gcLeader},
        crashedRiderIds: const {'r1'},
      );
      expect(converted.length, 1);
      expect(converted.first.role, GrandTourTriageRole.gcLeader);
      expect(converted.first.crashedOnStage, isTrue);
      expect(converted.first.contusionHealingDaysRemaining, 3);
    });

    test('GrandTourPhysiotherapyTriageNotifier przełącza zabiegi i zatwierdza plan', () {
      final notifier = GrandTourPhysiotherapyTriageNotifier();
      notifier.applyAutoTriage();
      expect(notifier.state.assignments, isNotEmpty);

      notifier.setTransportDecision(
        TransferTransportDecision.airCharterForLeaders,
      );
      expect(
        notifier.state.transportDecision,
        TransferTransportDecision.airCharterForLeaders,
      );

      final initialBudget = notifier.state.availableBudgetEur;
      final committed = notifier.commitTriagePlan();
      expect(
        notifier.state.availableBudgetEur,
        initialBudget - committed.totalCostEur,
      );
      expect(notifier.state.lastCommittedReport, isNotNull);
    });
  });

  group('GrandTourPhysiotherapyTriagePanel Responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje bez przepełnień przy ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: GrandTourPhysiotherapyTriagePanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.textContaining('Triaż Fizjoterapii'), findsOneWidget);
          expect(find.textContaining('Czarter Lotniczy'), findsOneWidget);

          await tester.tap(find.text('Auto-Przydział Sztabu'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Zatwierdź Plan Nocy'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('obsługuje pusty skład oraz tryb isReadOnly', (tester) async {
      final emptyState = GrandTourPhysiotherapyTriageState.demo().copyWith(
        squad: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            grandTourPhysiotherapyTriageProvider.overrideWith(
              (ref) => GrandTourPhysiotherapyTriageNotifier(
                initialState: emptyState,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GrandTourPhysiotherapyTriagePanel(isReadOnly: true),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(
        find.text('Brak kolarzy w składzie do nocnego triażu.'),
        findsOneWidget,
      );
    });
  });
}
