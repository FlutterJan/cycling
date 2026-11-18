import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/uci/technical_scrutiny_and_cas_tribunal_model.dart';
import 'package:pro_peloton_manager/services/uci/technical_scrutiny_and_reputation_defense_service.dart';
import 'package:pro_peloton_manager/ui/widgets/uci_technical_xray_scrutiny_modal.dart';

void main() {
  const service = TechnicalScrutinyAndReputationDefenseService();

  RiderEquipmentMeasurements buildCompliantTtMeasurements({
    String riderId = 'rider_tt_01',
    String riderName = 'K. Kowalski',
    double bikeWeightKg = 7.12,
    double sockHeightCm = 18.0,
    double shinLengthCm = 40.0,
    double brakeLeverTiltDeg = 7.5,
    double ttExtensionReachMm = 775.0,
    bool isTimeTrialSetup = true,
    bool frameJigCompliant = true,
  }) {
    return RiderEquipmentMeasurements(
      riderId: riderId,
      riderName: riderName,
      teamId: 'team_obsidian',
      frameSerialNumber: 'UCI-TT-2026-0091',
      bikeWeightKg: bikeWeightKg,
      sockHeightCm: sockHeightCm,
      shinLengthCm: shinLengthCm,
      brakeLeverTiltDeg: brakeLeverTiltDeg,
      ttExtensionReachMm: ttExtensionReachMm,
      isTimeTrialSetup: isTimeTrialSetup,
      frameJigCompliant: frameJigCompliant,
      measuredAtIso: '2026-07-10T13:45:00Z',
    );
  }

  List<XrayAndMagneticScanTelemetry> buildCleanXrayScans() {
    return const [
      XrayAndMagneticScanTelemetry(
        scanId: 'SCAN-BB-TT-01',
        deviceType: ScrutinyDeviceType.mobileXrayScanner,
        zone: EquipmentInspectionZone.bottomBracketShell,
        magneticFluxMicroTesla: 12.0,
        xrayMetalDensityScore: 0.29,
        hiddenMotorSignatureDetected: false,
        unusualBatteryCellDetected: false,
        serialNumberVerified: true,
        scanDurationSeconds: 15,
        operatorCommissaireId: 'UCI-TECH-04',
        timestampIso: '2026-07-10T13:44:00Z',
      ),
      XrayAndMagneticScanTelemetry(
        scanId: 'SCAN-ST-TT-02',
        deviceType: ScrutinyDeviceType.mobileXrayScanner,
        zone: EquipmentInspectionZone.seatTubeAndBattery,
        magneticFluxMicroTesla: 14.5,
        xrayMetalDensityScore: 0.35,
        hiddenMotorSignatureDetected: false,
        unusualBatteryCellDetected: false,
        serialNumberVerified: true,
        scanDurationSeconds: 12,
        operatorCommissaireId: 'UCI-TECH-04',
        timestampIso: '2026-07-10T13:44:20Z',
      ),
      XrayAndMagneticScanTelemetry(
        scanId: 'SCAN-HUB-TT-03',
        deviceType: ScrutinyDeviceType.magneticInductionTablet,
        zone: EquipmentInspectionZone.rearHubMotorCheck,
        magneticFluxMicroTesla: 8.4,
        xrayMetalDensityScore: 0.25,
        hiddenMotorSignatureDetected: false,
        unusualBatteryCellDetected: false,
        serialNumberVerified: true,
        scanDurationSeconds: 10,
        operatorCommissaireId: 'UCI-TECH-04',
        timestampIso: '2026-07-10T13:44:40Z',
      ),
    ];
  }

  group('Skanery techniczne UCI przed czasówką (X-Ray & magnetyczne)', () {
    test('Czysta kontrola przed rampą ITT zatwierdza rower bez kar i poprawia audyt', () {
      final initialModel = TechnicalScrutinyAndCasTribunalModel.initial(
        seasonYear: 2026,
      );
      final measurements = buildCompliantTtMeasurements();
      final outcome = service.executeInspection(
        currentModel: initialModel,
        inspectionId: 'INSP-ITT-001',
        raceId: 'tour_de_france',
        stageNumber: 7,
        timingWindow: ScrutinyTimingWindow.preStartIttRamp,
        selectionMode: ScrutinySelectionMode.targetedGcLeader,
        measurements: measurements,
        xrayScans: buildCleanXrayScans(),
        nowIso: '2026-07-10T13:45:00Z',
      );

      expect(outcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.passedClean);
      expect(outcome.inspectionRecord.hasAnyViolation, isFalse);
      expect(outcome.inspectionRecord.fineChf, 0.0);
      expect(outcome.inspectionRecord.uciPointsDeducted, 0);
      expect(outcome.torqueCorrection, isNull);
      expect(outcome.canAppealToCas, isFalse);
      expect(
        outcome.inspectionRecord.devicesUsed,
        containsAll([
          ScrutinyDeviceType.mobileXrayScanner,
          ScrutinyDeviceType.magneticInductionTablet,
          ScrutinyDeviceType.leverAngleInclinometer,
          ScrutinyDeviceType.sockHeightCaliper,
        ]),
      );

      final updated = initialModel.recordInspection(outcome.inspectionRecord);
      expect(updated.inspectionHistory, hasLength(1));
      expect(updated.teamComplianceAuditScore, 100.0);
      expect(updated.scrutinyTargetProbabilityBias, closeTo(0.04, 1e-6));
    });

    test('Wykrycie mikrosilnika lub ukrytych ogniw na skanie X-Ray zabezpiecza rower do laboratorium', () {
      final initialModel = TechnicalScrutinyAndCasTribunalModel.initial();
      final suspiciousScans = [
        buildCleanXrayScans().first.copyWith(
          magneticFluxMicroTesla: 92.5,
          xrayMetalDensityScore: 0.89,
          hiddenMotorSignatureDetected: true,
        ),
        ...buildCleanXrayScans().skip(1),
      ];

      final outcome = service.executeInspection(
        currentModel: initialModel,
        inspectionId: 'INSP-XRAY-FRAUD-01',
        raceId: 'giro_d_italia',
        stageNumber: 14,
        timingWindow: ScrutinyTimingWindow.preStartIttRamp,
        selectionMode: ScrutinySelectionMode.whistleblowerTip,
        measurements: buildCompliantTtMeasurements(),
        xrayScans: suspiciousScans,
        nowIso: '2026-05-23T14:00:00Z',
      );

      expect(outcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.impoundedForLabXray);
      expect(outcome.inspectionRecord.fineChf, 20000.0);
      expect(outcome.inspectionRecord.uciPointsDeducted, 250);
      expect(outcome.canAppealToCas, isTrue);
      expect(
        outcome.inspectionRecord.failedZones.first.severity,
        ScrutinyFindingSeverity.technologicalFraudBan,
      );
      expect(
        outcome.recommendedAppealGrounds,
        contains(CasAppealGround.chainOfCustodyBreach),
      );
    });

    test('Typowanie do kontroli przed rampą ITT zwiększa prawdopodobieństwo dla roweru czasowego', () {
      final model = TechnicalScrutinyAndCasTribunalModel.initial();
      final roadEval = service.evaluateScrutinySelection(
        tribunalModel: model,
        measurements: buildCompliantTtMeasurements(isTimeTrialSetup: false),
        timingWindow: ScrutinyTimingWindow.preStartPaddock,
      );
      final ittEval = service.evaluateScrutinySelection(
        tribunalModel: model,
        measurements: buildCompliantTtMeasurements(isTimeTrialSetup: true),
        timingWindow: ScrutinyTimingWindow.preStartIttRamp,
      );

      expect(ittEval.selectionProbability,
          greaterThan(roadEval.selectionProbability));

      final tipEval = service.evaluateScrutinySelection(
        tribunalModel: model,
        measurements: buildCompliantTtMeasurements(),
        timingWindow: ScrutinyTimingWindow.preStartIttRamp,
        rivalTeamProtestFiled: true,
      );
      expect(tipEval.selectionMode, ScrutinySelectionMode.whistleblowerTip);
      expect(tipEval.selectionProbability, 1.0);
      expect(tipEval.selectedForInspection, isTrue);
    });

    test('Serializacja JSON zachowuje pełną spójność modelu kontroli technicznych i spraw CAS', () {
      var model = TechnicalScrutinyAndCasTribunalModel.initial(
        seasonYear: 2026,
        nowIso: '2026-07-01T08:00:00Z',
      );
      final inspectionOutcome = service.executeInspection(
        currentModel: model,
        inspectionId: 'INSP-JSON-01',
        raceId: 'vuelta_a_espana',
        stageNumber: 1,
        timingWindow: ScrutinyTimingWindow.postFinishLine,
        selectionMode: ScrutinySelectionMode.targetedStageWinner,
        measurements: buildCompliantTtMeasurements(brakeLeverTiltDeg: 13.4),
        xrayScans: buildCleanXrayScans(),
        nowIso: '2026-08-22T17:10:00Z',
      );
      model = model.recordInspection(inspectionOutcome.inspectionRecord);
      model = model.fileCasAppeal(
        caseId: 'CAS-2026-JSON',
        inspection: inspectionOutcome.inspectionRecord,
        grounds: const [
          CasAppealGround.forceMajeureMechanicalShift,
          CasAppealGround.sensorCalibrationDispute,
        ],
        counselTier: CasLegalCounselTier.specialistSportsAttorney,
        requestProvisionalStay: true,
        submittedEvidenceSummaryPl: 'Logi z czujnika momentu i wideo.',
        nowIso: '2026-08-22T20:00:00Z',
      );

      final roundTrip =
          TechnicalScrutinyAndCasTribunalModel.fromJson(model.toJson());
      expect(roundTrip.seasonYear, model.seasonYear);
      expect(roundTrip.inspectionHistory, hasLength(1));
      expect(roundTrip.inspectionHistory.first.overallOutcome,
          ScrutinySessionOutcome.disqualifiedDsq);
      expect(roundTrip.casCases, hasLength(1));
      expect(roundTrip.casCases.first.caseId, 'CAS-2026-JSON');
      expect(roundTrip.casCases.first.grounds, hasLength(2));
      expect(roundTrip.totalFinesPaidChf, model.totalFinesPaidChf);
    });
  });

  group('Wykrywanie nieregulaminowego kąta klamek i wysokości skarpetek', () {
    test('Kąt klamek > 10° przed startem ITT wymusza korektę kluczem dynamometrycznym', () {
      final model = TechnicalScrutinyAndCasTribunalModel.initial();
      final outcome = service.executeInspection(
        currentModel: model,
        inspectionId: 'INSP-LEVER-PRE',
        raceId: 'criterium_du_dauphine',
        stageNumber: 4,
        timingWindow: ScrutinyTimingWindow.preStartIttRamp,
        selectionMode: ScrutinySelectionMode.targetedSuspectedAero,
        measurements: buildCompliantTtMeasurements(brakeLeverTiltDeg: 14.5),
        xrayScans: buildCleanXrayScans(),
        nowIso: '2026-06-10T14:20:00Z',
      );

      expect(outcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.passedAfterTorqueCorrection);
      expect(outcome.inspectionRecord.fineChf, 500.0);
      expect(outcome.inspectionRecord.torqueCorrectionSeconds, 95);
      expect(outcome.inspectionRecord.riderStressSpikeDelta, 22.0);
      expect(outcome.inspectionRecord.riderFocusDropDelta, 14.0);

      final leverZone = outcome.inspectionRecord.zoneResults.firstWhere(
        (z) => z.zone == EquipmentInspectionZone.handlebarBrakeLevers,
      );
      expect(leverZone.passed, isFalse);
      expect(leverZone.severity,
          ScrutinyFindingSeverity.mandatory3MinRampCorrection);
      expect(leverZone.requiresImmediateTorqueCorrection, isTrue);

      final correction = outcome.torqueCorrection;
      expect(correction, isNotNull);
      expect(correction!.correctedZones,
          contains(EquipmentInspectionZone.handlebarBrakeLevers));
      expect(correction.correctedMeasurements.brakeLeverTiltDeg, 10.0);
      expect(correction.correctedMeasurements.isLeverTiltCompliant, isTrue);
      expect(correction.aeroCdaPenaltyPercent, greaterThan(0.0));
    });

    test('Ujemny kąt klamek przekraczający -10° na mecie skutkuje dyskwalifikacją DSQ', () {
      final model = TechnicalScrutinyAndCasTribunalModel.initial();
      final outcome = service.executeInspection(
        currentModel: model,
        inspectionId: 'INSP-LEVER-POST',
        raceId: 'paris_roubaix',
        stageNumber: 1,
        timingWindow: ScrutinyTimingWindow.postFinishLine,
        selectionMode: ScrutinySelectionMode.targetedStageWinner,
        measurements: buildCompliantTtMeasurements(
          brakeLeverTiltDeg: -13.2,
          isTimeTrialSetup: false,
        ),
        xrayScans: buildCleanXrayScans(),
        nowIso: '2026-04-12T17:05:00Z',
      );

      expect(outcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.disqualifiedDsq);
      expect(outcome.inspectionRecord.fineChf, 2000.0);
      expect(outcome.inspectionRecord.uciPointsDeducted, 50);
      expect(outcome.canAppealToCas, isTrue);
      expect(outcome.torqueCorrection, isNull);
    });

    test('Wysokość skarpetek > 50% goleni jest wykrywana zarówno przed startem, jak i na mecie', () {
      final model = TechnicalScrutinyAndCasTribunalModel.initial();

      // 23.0 / 40.0 = 57.5% > 50%
      final preStartOutcome = service.executeInspection(
        currentModel: model,
        inspectionId: 'INSP-SOCK-PRE',
        raceId: 'tour_de_suisse',
        stageNumber: 1,
        timingWindow: ScrutinyTimingWindow.preStartIttRamp,
        selectionMode: ScrutinySelectionMode.randomLottery,
        measurements: buildCompliantTtMeasurements(
          sockHeightCm: 23.0,
          shinLengthCm: 40.0,
        ),
        xrayScans: buildCleanXrayScans(),
      );

      expect(preStartOutcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.passedAfterTorqueCorrection);
      expect(preStartOutcome.torqueCorrection, isNotNull);
      expect(preStartOutcome.torqueCorrection!.correctedZones,
          contains(EquipmentInspectionZone.sockAndOvershoeHeight));
      expect(
          preStartOutcome.torqueCorrection!.correctedMeasurements.sockHeightCm,
          20.0);
      expect(
          preStartOutcome
              .torqueCorrection!.correctedMeasurements.isSockCompliant,
          isTrue);

      final postFinishOutcome = service.executeInspection(
        currentModel: model,
        inspectionId: 'INSP-SOCK-POST',
        raceId: 'tour_de_suisse',
        stageNumber: 2,
        timingWindow: ScrutinyTimingWindow.postFinishLine,
        selectionMode: ScrutinySelectionMode.randomLottery,
        measurements: buildCompliantTtMeasurements(
          sockHeightCm: 23.0,
          shinLengthCm: 40.0,
          isTimeTrialSetup: false,
        ),
        xrayScans: buildCleanXrayScans(),
      );

      expect(postFinishOutcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.relegatedOrTimePenalty);
      expect(postFinishOutcome.inspectionRecord.fineChf, 500.0);
      expect(postFinishOutcome.inspectionRecord.uciPointsDeducted, 15);
      expect(postFinishOutcome.canAppealToCas, isTrue);
    });

    test('Jednoczesne naruszenie klamek, skarpetek i lemondki TT wykrywa wszystkie strefy i koryguje je', () {
      final measurements = buildCompliantTtMeasurements(
        brakeLeverTiltDeg: 15.0,
        sockHeightCm: 24.0,
        shinLengthCm: 40.0,
        ttExtensionReachMm: 825.0,
      );

      final risk = service.assessSetupRisk(measurements: measurements);
      expect(risk.hasAnyRuleViolation, isTrue);
      expect(
        risk.atRiskZones,
        containsAll([
          EquipmentInspectionZone.handlebarBrakeLevers,
          EquipmentInspectionZone.sockAndOvershoeHeight,
          EquipmentInspectionZone.ttExtensionLength,
        ]),
      );
      expect(risk.estimatedAeroGainWatts, greaterThan(0.0));

      final outcome = service.executeInspection(
        currentModel: TechnicalScrutinyAndCasTribunalModel.initial(),
        inspectionId: 'INSP-MULTI-PRE',
        raceId: 'tour_de_france',
        stageNumber: 21,
        timingWindow: ScrutinyTimingWindow.preStartIttRamp,
        selectionMode: ScrutinySelectionMode.targetedSuspectedAero,
        measurements: measurements,
        xrayScans: buildCleanXrayScans(),
      );

      expect(outcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.passedAfterTorqueCorrection);
      final fixed = outcome.torqueCorrection!.correctedMeasurements;
      expect(fixed.isLeverTiltCompliant, isTrue);
      expect(fixed.isSockCompliant, isTrue);
      expect(fixed.isTtExtensionCompliant, isTrue);
    });

    test('Rower poniżej minimalnej wagi 6.80 kg skutkuje natychmiastową dyskwalifikacją DSQ', () {
      final outcome = service.executeInspection(
        currentModel: TechnicalScrutinyAndCasTribunalModel.initial(),
        inspectionId: 'INSP-WEIGHT-DSQ',
        raceId: 'vuelta_a_espana',
        stageNumber: 9,
        timingWindow: ScrutinyTimingWindow.preStartPaddock,
        selectionMode: ScrutinySelectionMode.randomLottery,
        measurements: buildCompliantTtMeasurements(bikeWeightKg: 6.64),
        xrayScans: buildCleanXrayScans(),
      );

      expect(outcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.disqualifiedDsq);
      expect(outcome.inspectionRecord.failedZones.single.zone,
          EquipmentInspectionZone.minimumBikeWeight68Kg);
    });
  });

  group('Procedura odwoławcza przed Trybunałem CAS i Riverpod Notifier', () {
    test('Odrzuca odwołanie od czystej inspekcji, przy braku budżetu lub duplikacie sprawy', () {
      final model = TechnicalScrutinyAndCasTribunalModel.initial();
      final cleanOutcome = service.executeInspection(
        currentModel: model,
        inspectionId: 'INSP-CLEAN',
        raceId: 'milano_sanremo',
        stageNumber: 1,
        timingWindow: ScrutinyTimingWindow.preStartPaddock,
        selectionMode: ScrutinySelectionMode.randomLottery,
        measurements: buildCompliantTtMeasurements(isTimeTrialSetup: false),
        xrayScans: buildCleanXrayScans(),
      );

      final notAppealable = service.fileCasAppeal(
        currentModel: model,
        availableBudgetChf: 100000.0,
        caseId: 'CAS-ERR-1',
        inspection: cleanOutcome.inspectionRecord,
        grounds: const [CasAppealGround.proceduralErrorByCommissaire],
        counselTier: CasLegalCounselTier.clubInternalLegal,
        requestProvisionalStay: false,
        submittedEvidenceSummaryPl: 'Brak podstawy.',
      );
      expect(notAppealable.accepted, isFalse);

      final dsqOutcome = service.executeInspection(
        currentModel: model,
        inspectionId: 'INSP-DSQ',
        raceId: 'milano_sanremo',
        stageNumber: 1,
        timingWindow: ScrutinyTimingWindow.postFinishLine,
        selectionMode: ScrutinySelectionMode.targetedStageWinner,
        measurements: buildCompliantTtMeasurements(
          brakeLeverTiltDeg: 14.0,
          isTimeTrialSetup: false,
        ),
        xrayScans: buildCleanXrayScans(),
      );

      final lowBudget = service.fileCasAppeal(
        currentModel: model,
        availableBudgetChf: 5000.0,
        caseId: 'CAS-ERR-2',
        inspection: dsqOutcome.inspectionRecord,
        grounds: const [CasAppealGround.forceMajeureMechanicalShift],
        counselTier: CasLegalCounselTier.lausanneSeniorArbitrationQc,
        requestProvisionalStay: true,
        submittedEvidenceSummaryPl: 'Kraksa na 40 km przed metą.',
      );
      expect(lowBudget.accepted, isFalse);
      expect(lowBudget.totalCostChargedChf, 0.0);
    });

    test('Pełny cykl w Riverpod: DSQ -> odwołanie CAS (Provisional Stay) -> uchylenie wyroku i zwrot grzywny', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(technicalScrutinyDefenseProvider.notifier);
      final initialState = container.read(technicalScrutinyDefenseProvider);
      expect(initialState.availableClubBudgetChf, 250000.0);

      // 1. DSQ na mecie za kąt klamek > 10°
      final dsqOutcome = notifier.runTechnicalScrutiny(
        inspectionId: 'INSP-CAS-FLOW-01',
        raceId: 'tour_of_flanders',
        stageNumber: 1,
        timingWindow: ScrutinyTimingWindow.postFinishLine,
        selectionMode: ScrutinySelectionMode.targetedStageWinner,
        measurements: buildCompliantTtMeasurements(
          brakeLeverTiltDeg: 12.8,
          isTimeTrialSetup: false,
        ),
        xrayScans: buildCleanXrayScans(),
        nowIso: '2026-04-05T16:50:00Z',
      );
      expect(dsqOutcome.inspectionRecord.overallOutcome,
          ScrutinySessionOutcome.disqualifiedDsq);

      final afterDsq = container.read(technicalScrutinyDefenseProvider);
      expect(afterDsq.availableClubBudgetChf, 248000.0);
      expect(afterDsq.clubReputationScore, lessThan(78.0));

      // 2. Złożenie odwołania do CAS w Lozannie z zespołem QC (1000 + 35000 CHF)
      final filing = notifier.submitCasAppeal(
        caseId: 'CAS-2026-FLANDERS-01',
        inspection: dsqOutcome.inspectionRecord,
        grounds: const [
          CasAppealGround.forceMajeureMechanicalShift,
          CasAppealGround.chainOfCustodyBreach,
        ],
        counselTier: CasLegalCounselTier.lausanneSeniorArbitrationQc,
        requestProvisionalStay: true,
        submittedEvidenceSummaryPl:
            'Uderzenie w barierki na bruku Koppenbergu przesunęło prawą klamkę.',
        nowIso: '2026-04-05T19:30:00Z',
      );
      expect(filing.accepted, isTrue);
      expect(filing.totalCostChargedChf, 36000.0);
      expect(filing.appealCase?.provisionalStayGranted, isTrue);
      expect(filing.appealCase?.status,
          CasTribunalStatus.expeditedProvisionalStayGranted);

      // Duplikat powinien zostać odrzucony
      final duplicate = notifier.submitCasAppeal(
        caseId: 'CAS-2026-FLANDERS-DUP',
        inspection: dsqOutcome.inspectionRecord,
        grounds: const [CasAppealGround.forceMajeureMechanicalShift],
        counselTier: CasLegalCounselTier.clubInternalLegal,
        requestProvisionalStay: false,
        submittedEvidenceSummaryPl: 'Duplikat.',
      );
      expect(duplicate.accepted, isFalse);

      // 3. Rozstrzygnięcie sprawy przez Trybunał CAS: uchylenie DSQ i zwrot grzywny
      final resolution = notifier.resolveCasAppeal(
        caseId: 'CAS-2026-FLANDERS-01',
        forcedVerdict: CasTribunalStatus.verdictOverturnedReinstated,
        nowIso: '2026-04-07T11:00:00Z',
      );
      expect(resolution.resolvedCase.isSuccessfulForTeam, isTrue);
      expect(resolution.fineRefundChf, 2000.0);

      final afterVerdict = container.read(technicalScrutinyDefenseProvider);
      expect(afterVerdict.availableClubBudgetChf, 214000.0);
      expect(afterVerdict.tribunalModel.appealSuccessRate, 1.0);
      expect(afterVerdict.tribunalModel.pendingCasCases, isEmpty);

      // 4. Działanie PR / audyt po wyroku
      final prOk = notifier.triggerReputationDefenseAction(
        actionType: ReputationDefenseActionType.independentLabAudit,
        entryId: 'PR-AUDIT-01',
        relatedInspectionId: 'INSP-CAS-FLOW-01',
        nowIso: '2026-04-07T14:00:00Z',
      );
      expect(prOk, isTrue);
      final finalState = container.read(technicalScrutinyDefenseProvider);
      expect(finalState.reputationLogs, hasLength(1));
      expect(finalState.availableClubBudgetChf, 200000.0);
    });

    test('Zabezpieczenie roweru do analizy X-Ray blokuje tymczasowe zawieszenie kary (Provisional Stay)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(technicalScrutinyDefenseProvider.notifier);
      final fraudOutcome = notifier.runTechnicalScrutiny(
        inspectionId: 'INSP-FRAUD-STAY-01',
        raceId: 'tour_de_france',
        stageNumber: 10,
        timingWindow: ScrutinyTimingWindow.postFinishLine,
        selectionMode: ScrutinySelectionMode.whistleblowerTip,
        measurements: buildCompliantTtMeasurements(isTimeTrialSetup: false),
        xrayScans: [
          buildCleanXrayScans().first.copyWith(
            hiddenMotorSignatureDetected: true,
            magneticFluxMicroTesla: 88.0,
            xrayMetalDensityScore: 0.91,
          ),
        ],
      );

      final filing = notifier.submitCasAppeal(
        caseId: 'CAS-2026-FRAUD-01',
        inspection: fraudOutcome.inspectionRecord,
        grounds: const [CasAppealGround.chainOfCustodyBreach],
        counselTier: CasLegalCounselTier.lausanneSeniorArbitrationQc,
        requestProvisionalStay: true,
        submittedEvidenceSummaryPl: 'Wniosek o powtórny skan laboratoryjny.',
      );

      expect(filing.accepted, isTrue);
      expect(filing.appealCase?.provisionalStayGranted, isFalse);
      expect(filing.appealCase?.status,
          CasTribunalStatus.filedPendingPreliminary);

      final upheld = notifier.resolveCasAppeal(
        caseId: 'CAS-2026-FRAUD-01',
        forcedVerdict: CasTribunalStatus.verdictUpheldDsq,
      );
      expect(upheld.fineRefundChf, 0.0);
      expect(upheld.resolvedCase.isSuccessfulForTeam, isFalse);
    });
  });

  group('Testy widgetowe i responsywne skanera X-Ray oraz panelu CAS', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'UciTechnicalXrayScrutinyModal renderuje alarm kokpitu i wykonuje korektę bez overflow (${size.width.toInt()}x${size.height.toInt()})',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        UciXrayScrutinyModalResult? completedResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: UciTechnicalXrayScrutinyModal(
                  autoStartScan: false,
                  inspectionRecord:
                      UciTechnicalXrayScrutinyModal.buildDefaultPreStartRecord(
                    withCockpitAlarm: true,
                  ),
                  onCompleted: (result) {
                    completedResult = result;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('KONTROLA TECHNICZNA UCI — SKANER X-RAY'),
            findsOneWidget);

        // Dopóki kąt klamek nie jest skorygowany, przycisk "Dopuść do startu" jest nieaktywny
        await tester.tap(find.text('Dopuść do startu'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(completedResult, isNull);

        // Wykonaj korektę kluczem dynamometrycznym jeśli przycisk jest widoczny
        final fixFinder = find.textContaining('Skoryguj');
        if (fixFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(fixFinder.first);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(fixFinder.first);
          await tester.pump(const Duration(milliseconds: 300));
        }

        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'TechnicalScrutinyAndReputationDefensePanel renderuje się responsywnie bez overflow (${size.width.toInt()}x${size.height.toInt()})',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

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
        expect(tester.takeException(), isNull);
      });
    }
  });
}
