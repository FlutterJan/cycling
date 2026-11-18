import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/uci/technical_scrutiny_and_cas_tribunal_model.dart';
import 'package:pro_peloton_manager/services/uci/technical_scrutiny_and_reputation_defense_service.dart';

RiderEquipmentMeasurements _buildMeasurements({
  double bikeWeightKg = 7.1,
  double sockHeightCm = 18.0,
  double shinLengthCm = 40.0,
  double brakeLeverTiltDeg = 7.0,
  double ttExtensionReachMm = 760.0,
  bool isTimeTrialSetup = true,
  bool frameJigCompliant = true,
}) {
  return RiderEquipmentMeasurements(
    riderId: 'rider_1',
    riderName: 'Jan Kowalski',
    teamId: 'team_1',
    frameSerialNumber: 'PPM-2026-001',
    bikeWeightKg: bikeWeightKg,
    sockHeightCm: sockHeightCm,
    shinLengthCm: shinLengthCm,
    brakeLeverTiltDeg: brakeLeverTiltDeg,
    ttExtensionReachMm: ttExtensionReachMm,
    isTimeTrialSetup: isTimeTrialSetup,
    frameJigCompliant: frameJigCompliant,
    measuredAtIso: '2026-07-10T13:57:00.000Z',
  );
}

void main() {
  group('TechnicalScrutinyAndReputationDefenseService', () {
    const service = TechnicalScrutinyAndReputationDefenseService();

    test('assessSetupRisk detects aero violations and estimates watt gain', () {
      final profile = service.assessSetupRisk(
        measurements: _buildMeasurements(
          sockHeightCm: 23.0, // 57.5% > 50%
          brakeLeverTiltDeg: 14.0, // > 10°
          ttExtensionReachMm: 820.0, // > 800mm
        ),
      );

      expect(profile.hasAnyRuleViolation, isTrue);
      expect(profile.leverViolationDeg, closeTo(4.0, 0.01));
      expect(profile.sockViolationPercent, closeTo(7.5, 0.01));
      expect(profile.ttExtensionViolationMm, closeTo(20.0, 0.1));
      expect(profile.estimatedAeroGainWatts, greaterThan(5.0));
      expect(profile.atRiskZones, hasLength(3));
    });

    test(
      'pre-start ITT ramp inspection forces torque wrench fix with stress spike and focus drop',
      () {
        final model = TechnicalScrutinyAndCasTribunalModel.initial();
        final outcome = service.executeInspection(
          currentModel: model,
          inspectionId: 'insp_itt_1',
          raceId: 'tdf_2026',
          stageNumber: 7,
          timingWindow: ScrutinyTimingWindow.preStartIttRamp,
          selectionMode: ScrutinySelectionMode.targetedSuspectedAero,
          measurements: _buildMeasurements(
            sockHeightCm: 22.0,
            brakeLeverTiltDeg: 13.5,
            ttExtensionReachMm: 815.0,
          ),
        );

        expect(
          outcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.passedAfterTorqueCorrection,
        );
        expect(outcome.inspectionRecord.riderStressSpikeDelta, 22.0);
        expect(outcome.inspectionRecord.riderFocusDropDelta, 14.0);
        expect(outcome.inspectionRecord.torqueCorrectionSeconds, 95);
        expect(outcome.torqueCorrection, isNotNull);
        expect(
          outcome.torqueCorrection!.correctedMeasurements.isLeverTiltCompliant,
          isTrue,
        );
        expect(
          outcome.torqueCorrection!.correctedMeasurements.isSockCompliant,
          isTrue,
        );
        expect(
          outcome
              .torqueCorrection!.correctedMeasurements.isTtExtensionCompliant,
          isTrue,
        );
      },
    );

    test(
      'post-finish DSQ allows CAS appeal with sports lawyers and hearing resolution',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier =
            container.read(technicalScrutinyDefenseProvider.notifier);

        final dsqOutcome = notifier.runTechnicalScrutiny(
          inspectionId: 'insp_dsq_1',
          raceId: 'paris_roubaix',
          stageNumber: 1,
          timingWindow: ScrutinyTimingWindow.postFinishLine,
          selectionMode: ScrutinySelectionMode.targetedStageWinner,
          measurements: _buildMeasurements(
            bikeWeightKg: 6.72,
            brakeLeverTiltDeg: 14.5,
            isTimeTrialSetup: false,
          ),
        );

        expect(
          dsqOutcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.disqualifiedDsq,
        );
        expect(dsqOutcome.canAppealToCas, isTrue);

        final afterDsqState = container.read(technicalScrutinyDefenseProvider);
        expect(afterDsqState.clubReputationScore, lessThan(78.0));

        final filing = notifier.submitCasAppeal(
          caseId: 'cas_case_1',
          inspection: dsqOutcome.inspectionRecord,
          grounds: const [
            CasAppealGround.forceMajeureMechanicalShift,
            CasAppealGround.sensorCalibrationDispute,
          ],
          counselTier: CasLegalCounselTier.lausanneSeniorArbitrationQc,
          requestProvisionalStay: true,
          submittedEvidenceSummaryPl: 'Zapis telemetrii i raport kraksy.',
        );

        expect(filing.accepted, isTrue);
        expect(filing.appealCase, isNotNull);
        expect(filing.appealCase!.provisionalStayGranted, isTrue);

        final resolution = notifier.resolveCasAppeal(
          caseId: 'cas_case_1',
          forcedVerdict: CasTribunalStatus.verdictOverturnedReinstated,
        );

        expect(
          resolution.resolvedCase.status,
          CasTribunalStatus.verdictOverturnedReinstated,
        );
        expect(resolution.fineRefundChf, 2000.0);

        final repOk = notifier.triggerReputationDefenseAction(
          actionType: ReputationDefenseActionType.independentLabAudit,
          entryId: 'rep_1',
          relatedInspectionId: 'insp_dsq_1',
        );
        expect(repOk, isTrue);

        final finalState = container.read(technicalScrutinyDefenseProvider);
        expect(finalState.clubReputationScore, greaterThan(80.0));
      },
    );
  });

  group('TechnicalScrutinyAndReputationDefensePanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: TechnicalScrutinyAndReputationDefensePanel(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Kontrole Techniczne UCI & Trybunał CAS'),
          findsOneWidget,
        );

        await tester.tap(find.text('Kontrola po mecie (ryzyko DSQ)'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Złóż odwołanie do CAS'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
