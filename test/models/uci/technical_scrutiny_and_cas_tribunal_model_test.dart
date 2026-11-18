import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/uci/technical_scrutiny_and_cas_tribunal_model.dart';

void main() {
  group('TechnicalScrutinyAndCasTribunalModel', () {
    test('evaluates compliant bike and rider setup as passedClean', () {
      final model = TechnicalScrutinyAndCasTribunalModel.initial(
        seasonYear: 2026,
      );

      final record = model.evaluateInspection(
        inspectionId: 'insp-001',
        raceId: 'tour-de-france',
        stageNumber: 1,
        timingWindow: ScrutinyTimingWindow.preStartPaddock,
        selectionMode: ScrutinySelectionMode.randomLottery,
        measurements: const RiderEquipmentMeasurements(
          riderId: 'rider-1',
          riderName: 'Jan Kowalski',
          teamId: 'team-1',
          frameSerialNumber: 'UCI-FR-9921',
          bikeWeightKg: 6.85,
          sockHeightCm: 19.5,
          shinLengthCm: 40.0,
          brakeLeverTiltDeg: 8.5,
          ttExtensionReachMm: 750.0,
          isTimeTrialSetup: false,
          frameJigCompliant: true,
          measuredAtIso: '2026-07-04T09:00:00Z',
        ),
        xrayScans: const [
          XrayAndMagneticScanTelemetry(
            scanId: 'scan-bb-1',
            deviceType: ScrutinyDeviceType.mobileXrayScanner,
            zone: EquipmentInspectionZone.bottomBracketShell,
            magneticFluxMicroTesla: 12.0,
            xrayMetalDensityScore: 0.22,
            hiddenMotorSignatureDetected: false,
            unusualBatteryCellDetected: false,
            serialNumberVerified: true,
            scanDurationSeconds: 15,
            operatorCommissaireId: 'UCI-TECH-04',
            timestampIso: '2026-07-04T09:01:00Z',
          ),
        ],
        inspectedAtIso: '2026-07-04T09:02:00Z',
      );

      expect(record.overallOutcome, ScrutinySessionOutcome.passedClean);
      expect(record.hasAnyViolation, isFalse);
      expect(record.fineChf, 0.0);
    });

    test('triggers mandatory 3-min ramp correction for sock > 50% and lever > 10°', () {
      final model = TechnicalScrutinyAndCasTribunalModel.initial();

      final record = model.evaluateInspection(
        inspectionId: 'insp-002',
        raceId: 'giro-itt',
        stageNumber: 7,
        timingWindow: ScrutinyTimingWindow.preStartIttRamp,
        selectionMode: ScrutinySelectionMode.targetedSuspectedAero,
        measurements: const RiderEquipmentMeasurements(
          riderId: 'rider-2',
          riderName: 'Marek Nowak',
          teamId: 'team-1',
          frameSerialNumber: 'UCI-FR-9922',
          bikeWeightKg: 7.20,
          sockHeightCm: 22.0, // 55% of 40 cm
          shinLengthCm: 40.0,
          brakeLeverTiltDeg: 13.0, // > 10°
          ttExtensionReachMm: 790.0,
          isTimeTrialSetup: true,
          frameJigCompliant: true,
          measuredAtIso: '2026-05-15T14:57:00Z',
        ),
        xrayScans: const [],
        inspectedAtIso: '2026-05-15T14:57:30Z',
      );

      expect(
        record.overallOutcome,
        ScrutinySessionOutcome.passedAfterTorqueCorrection,
      );
      expect(record.failedZones.length, 2);
      expect(record.riderStressSpikeDelta, greaterThan(0));
      expect(record.riderFocusDropDelta, greaterThan(0));
      expect(record.torqueCorrectionSeconds, greaterThan(0));
    });

    test('detects hidden motor via X-Ray and supports CAS appeal lifecycle', () {
      var model = TechnicalScrutinyAndCasTribunalModel.initial();

      final record = model.evaluateInspection(
        inspectionId: 'insp-003',
        raceId: 'paris-roubaix',
        stageNumber: 1,
        timingWindow: ScrutinyTimingWindow.postFinishLine,
        selectionMode: ScrutinySelectionMode.targetedStageWinner,
        measurements: const RiderEquipmentMeasurements(
          riderId: 'rider-3',
          riderName: 'Lucas Bernard',
          teamId: 'team-2',
          frameSerialNumber: 'UCI-FR-8810',
          bikeWeightKg: 7.10,
          sockHeightCm: 18.0,
          shinLengthCm: 40.0,
          brakeLeverTiltDeg: 5.0,
          ttExtensionReachMm: 750.0,
          isTimeTrialSetup: false,
          frameJigCompliant: true,
          measuredAtIso: '2026-04-12T17:10:00Z',
        ),
        xrayScans: const [
          XrayAndMagneticScanTelemetry(
            scanId: 'scan-hub-1',
            deviceType: ScrutinyDeviceType.magneticInductionTablet,
            zone: EquipmentInspectionZone.rearHubMotorCheck,
            magneticFluxMicroTesla: 142.0,
            xrayMetalDensityScore: 0.91,
            hiddenMotorSignatureDetected: true,
            unusualBatteryCellDetected: false,
            serialNumberVerified: true,
            scanDurationSeconds: 22,
            operatorCommissaireId: 'UCI-TECH-01',
            timestampIso: '2026-04-12T17:11:00Z',
          ),
        ],
        inspectedAtIso: '2026-04-12T17:12:00Z',
      );

      expect(record.overallOutcome, ScrutinySessionOutcome.impoundedForLabXray);
      expect(record.isAppealableToCas, isTrue);

      model = model.recordInspection(record);
      expect(model.inspectionHistory.length, 1);
      expect(model.totalFinesPaidChf, 20000.0);

      model = model.fileCasAppeal(
        caseId: 'CAS-2026-104',
        inspection: record,
        grounds: const [CasAppealGround.sensorCalibrationDispute],
        counselTier: CasLegalCounselTier.lausanneSeniorArbitrationQc,
        requestProvisionalStay: true,
        submittedEvidenceSummaryPl:
            'Wniosek o ponowną kalibrację skanera magnetycznego.',
        nowIso: '2026-04-13T10:00:00Z',
      );

      expect(model.pendingCasCases.length, 1);
      expect(model.casCases.first.provisionalStayGranted, isFalse);

      model = model.resolveCasCase(
        caseId: 'CAS-2026-104',
        finalStatus: CasTribunalStatus.verdictOverturnedReinstated,
        verdictSummaryPl: 'Uchylono sankcję z powodu błędu kalibracji.',
        fineRefundChf: 20000.0,
        nowIso: '2026-05-01T12:00:00Z',
      );

      expect(model.pendingCasCases, isEmpty);
      expect(model.appealSuccessRate, 1.0);
      expect(model.totalFinesPaidChf, 0.0);

      final roundTrip = TechnicalScrutinyAndCasTribunalModel.fromJson(
        model.toJson(),
      );
      expect(roundTrip.seasonYear, model.seasonYear);
      expect(roundTrip.inspectionHistory.length, 1);
      expect(roundTrip.casCases.length, 1);
      expect(
        roundTrip.casCases.first.status,
        CasTribunalStatus.verdictOverturnedReinstated,
      );
    });
  });
}
