import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/models/uci/technical_scrutiny_and_cas_tribunal_model.dart';

/// Kategoria działań obrony reputacji klubu po incydencie technicznym UCI.
enum ReputationDefenseActionType {
  publicPressClarification,
  independentLabAudit,
  publishCadTelemetry,
  sponsorBriefing;

  String get displayNamePl {
    switch (this) {
      case ReputationDefenseActionType.publicPressClarification:
        return 'Oświadczenie prasowe dyrektora sportowego';
      case ReputationDefenseActionType.independentLabAudit:
        return 'Niezależny audyt laboratoryjny (ISO / UCI)';
      case ReputationDefenseActionType.publishCadTelemetry:
        return 'Publikacja geometrii CAD i kalibracji R&D';
      case ReputationDefenseActionType.sponsorBriefing:
        return 'Zamknięta odprawa dla zarządu sponsorów';
    }
  }

  double get costChf {
    switch (this) {
      case ReputationDefenseActionType.publicPressClarification:
        return 1500.0;
      case ReputationDefenseActionType.independentLabAudit:
        return 14000.0;
      case ReputationDefenseActionType.publishCadTelemetry:
        return 4500.0;
      case ReputationDefenseActionType.sponsorBriefing:
        return 3000.0;
    }
  }

  double get reputationRecoveryPoints {
    switch (this) {
      case ReputationDefenseActionType.publicPressClarification:
        return 3.5;
      case ReputationDefenseActionType.independentLabAudit:
        return 9.5;
      case ReputationDefenseActionType.publishCadTelemetry:
        return 5.5;
      case ReputationDefenseActionType.sponsorBriefing:
        return 2.0;
    }
  }

  double get sponsorConfidenceRecoveryPoints {
    switch (this) {
      case ReputationDefenseActionType.publicPressClarification:
        return 2.5;
      case ReputationDefenseActionType.independentLabAudit:
        return 7.0;
      case ReputationDefenseActionType.publishCadTelemetry:
        return 4.5;
      case ReputationDefenseActionType.sponsorBriefing:
        return 8.5;
    }
  }
}

/// Profil ryzyka aerodynamicznego przygotowanego przez mechaników i dział R&D.
class TechnicalScrutinyRiskProfile {
  final double leverViolationDeg;
  final double sockViolationPercent;
  final double ttExtensionViolationMm;
  final double weightDeficitKg;
  final bool frameTemplateViolation;
  final double overallScrutinyRiskScore;
  final double estimatedAeroGainWatts;
  final List<EquipmentInspectionZone> atRiskZones;

  const TechnicalScrutinyRiskProfile({
    required this.leverViolationDeg,
    required this.sockViolationPercent,
    required this.ttExtensionViolationMm,
    required this.weightDeficitKg,
    required this.frameTemplateViolation,
    required this.overallScrutinyRiskScore,
    required this.estimatedAeroGainWatts,
    required this.atRiskZones,
  });

  bool get hasAnyRuleViolation => atRiskZones.isNotEmpty;
}

/// Wynik oceny ryzyka wytypowania kolarza do kontroli komisarza technicznego UCI.
class ScrutinySelectionEvaluation {
  final bool selectedForInspection;
  final double selectionProbability;
  final ScrutinySelectionMode selectionMode;
  final ScrutinyTimingWindow timingWindow;
  final String rationalePl;

  const ScrutinySelectionEvaluation({
    required this.selectedForInspection,
    required this.selectionProbability,
    required this.selectionMode,
    required this.timingWindow,
    required this.rationalePl,
  });
}

/// Skutki natychmiastowej korekty sprzętu kluczem dynamometrycznym przed startem.
class TorqueRampCorrectionResult {
  final String riderId;
  final ScrutinyTimingWindow timingWindow;
  final int correctionDurationSeconds;
  final double riderStressSpikeDelta;
  final double riderFocusDropDelta;
  final double aeroCdaPenaltyPercent;
  final List<EquipmentInspectionZone> correctedZones;
  final RiderEquipmentMeasurements correctedMeasurements;
  final String summaryPl;

  const TorqueRampCorrectionResult({
    required this.riderId,
    required this.timingWindow,
    required this.correctionDurationSeconds,
    required this.riderStressSpikeDelta,
    required this.riderFocusDropDelta,
    required this.aeroCdaPenaltyPercent,
    required this.correctedZones,
    required this.correctedMeasurements,
    required this.summaryPl,
  });
}

/// Kompletny wynik przeprowadzonej kontroli technicznej UCI i jej wpływu na klub.
class ScrutinyExecutionOutcome {
  final TechnicalScrutinyInspectionRecord inspectionRecord;
  final TorqueRampCorrectionResult? torqueCorrection;
  final double clubReputationDelta;
  final double sponsorConfidenceDelta;
  final bool canAppealToCas;
  final List<CasAppealGround> recommendedAppealGrounds;
  final String mediaHeadlinePl;

  const ScrutinyExecutionOutcome({
    required this.inspectionRecord,
    required this.torqueCorrection,
    required this.clubReputationDelta,
    required this.sponsorConfidenceDelta,
    required this.canAppealToCas,
    required this.recommendedAppealGrounds,
    required this.mediaHeadlinePl,
  });
}

/// Wynik złożenia odwołania od decyzji komisarza do Trybunału CAS w Lozannie.
class CasAppealFilingResult {
  final bool accepted;
  final CasTribunalAppealCase? appealCase;
  final double totalCostChargedChf;
  final String messagePl;

  const CasAppealFilingResult({
    required this.accepted,
    required this.appealCase,
    required this.totalCostChargedChf,
    required this.messagePl,
  });
}

/// Wynik rozprawy i wyroku Trybunału CAS w Lozannie.
class CasHearingResolutionResult {
  final CasTribunalAppealCase resolvedCase;
  final double clubReputationDelta;
  final double sponsorConfidenceDelta;
  final double fineRefundChf;
  final String officialCommuniquePl;

  const CasHearingResolutionResult({
    required this.resolvedCase,
    required this.clubReputationDelta,
    required this.sponsorConfidenceDelta,
    required this.fineRefundChf,
    required this.officialCommuniquePl,
  });
}

/// Wpis w dzienniku działań PR i obrony reputacji klubu.
class ReputationDefenseLogEntry {
  final String entryId;
  final ReputationDefenseActionType actionType;
  final String relatedInspectionId;
  final double costChf;
  final double reputationDelta;
  final double sponsorConfidenceDelta;
  final String summaryPl;
  final String createdAtIso;

  const ReputationDefenseLogEntry({
    required this.entryId,
    required this.actionType,
    required this.relatedInspectionId,
    required this.costChf,
    required this.reputationDelta,
    required this.sponsorConfidenceDelta,
    required this.summaryPl,
    required this.createdAtIso,
  });
}

/// Główny serwis kontroli technicznych UCI, korekt przedstartowych i obrony reputacji w CAS.
class TechnicalScrutinyAndReputationDefenseService {
  const TechnicalScrutinyAndReputationDefenseService();

  /// Analizuje konfigurację roweru i stroju pod kątem naginania przepisów aero przez R&D/mechaników.
  TechnicalScrutinyRiskProfile assessSetupRisk({
    required RiderEquipmentMeasurements measurements,
    UciTechnicalRegulationLimits limits = const UciTechnicalRegulationLimits(),
  }) {
    final atRisk = <EquipmentInspectionZone>[];
    final leverExcess = math.max(
      0.0,
      measurements.brakeLeverTiltDeg.abs() - limits.maxBrakeLeverInwardTiltDeg,
    );
    if (leverExcess > 1e-6) {
      atRisk.add(EquipmentInspectionZone.handlebarBrakeLevers);
    }

    final sockExcessPct = math.max(
      0.0,
      (measurements.sockToShinRatio - limits.maxSockHeightRatioToShin) * 100.0,
    );
    if (sockExcessPct > 1e-4) {
      atRisk.add(EquipmentInspectionZone.sockAndOvershoeHeight);
    }

    final ttExcessMm = measurements.isTimeTrialSetup
        ? math.max(
            0.0,
            measurements.ttExtensionReachMm - limits.maxTtExtensionReachMm,
          )
        : 0.0;
    if (ttExcessMm > 1e-6) {
      atRisk.add(EquipmentInspectionZone.ttExtensionLength);
    }

    final weightDeficit = math.max(
      0.0,
      limits.minBikeWeightKg - measurements.bikeWeightKg,
    );
    if (weightDeficit > 1e-6) {
      atRisk.add(EquipmentInspectionZone.minimumBikeWeight68Kg);
    }

    final frameViolation = !measurements.frameJigCompliant;
    if (frameViolation) {
      atRisk.add(EquipmentInspectionZone.frameTubeDimensions3to1);
    }

    final riskScore = (leverExcess * 4.5 +
            sockExcessPct * 3.0 +
            ttExcessMm * 0.65 +
            weightDeficit * 85.0 +
            (frameViolation ? 45.0 : 0.0))
        .clamp(0.0, 100.0);

    final aeroWatts = (leverExcess * 0.85 +
            sockExcessPct * 0.35 +
            ttExcessMm * 0.14 +
            (frameViolation ? 6.5 : 0.0))
        .clamp(0.0, 28.0);

    return TechnicalScrutinyRiskProfile(
      leverViolationDeg: double.parse(leverExcess.toStringAsFixed(2)),
      sockViolationPercent: double.parse(sockExcessPct.toStringAsFixed(2)),
      ttExtensionViolationMm: double.parse(ttExcessMm.toStringAsFixed(1)),
      weightDeficitKg: double.parse(weightDeficit.toStringAsFixed(3)),
      frameTemplateViolation: frameViolation,
      overallScrutinyRiskScore: double.parse(riskScore.toStringAsFixed(1)),
      estimatedAeroGainWatts: double.parse(aeroWatts.toStringAsFixed(1)),
      atRiskZones: List.unmodifiable(atRisk),
    );
  }

  /// Wyznacza prawdopodobieństwo i tryb wytypowania kolarza do inspekcji komisarza UCI.
  ScrutinySelectionEvaluation evaluateScrutinySelection({
    required TechnicalScrutinyAndCasTribunalModel tribunalModel,
    required RiderEquipmentMeasurements measurements,
    required ScrutinyTimingWindow timingWindow,
    bool isGcLeader = false,
    bool isStageWinner = false,
    bool rivalTeamProtestFiled = false,
    int deterministicSeed = 667,
  }) {
    final risk = assessSetupRisk(
      measurements: measurements,
      limits: tribunalModel.regulationLimits,
    );

    late final ScrutinySelectionMode mode;
    var baseProb = 0.12 + tribunalModel.scrutinyTargetProbabilityBias;

    if (isStageWinner && timingWindow == ScrutinyTimingWindow.postFinishLine) {
      mode = ScrutinySelectionMode.targetedStageWinner;
      baseProb = 1.0;
    } else if (rivalTeamProtestFiled) {
      mode = ScrutinySelectionMode.whistleblowerTip;
      baseProb = 0.92;
    } else if (isGcLeader) {
      mode = ScrutinySelectionMode.targetedGcLeader;
      baseProb = math.max(baseProb, 0.78);
    } else if (risk.overallScrutinyRiskScore >= 20.0) {
      mode = ScrutinySelectionMode.targetedSuspectedAero;
      baseProb += risk.overallScrutinyRiskScore * 0.0065;
    } else {
      mode = ScrutinySelectionMode.randomLottery;
      baseProb += risk.overallScrutinyRiskScore * 0.003;
    }

    if (timingWindow == ScrutinyTimingWindow.preStartIttRamp &&
        measurements.isTimeTrialSetup) {
      baseProb += 0.18;
    }

    final clampedProb = baseProb.clamp(0.05, 1.0);
    final roll = math.Random(deterministicSeed).nextDouble();
    final selected = roll <= clampedProb;

    return ScrutinySelectionEvaluation(
      selectedForInspection: selected,
      selectionProbability: double.parse(clampedProb.toStringAsFixed(3)),
      selectionMode: mode,
      timingWindow: timingWindow,
      rationalePl: selected
          ? 'Komisarz UCI skierował rower do kontroli (${mode.displayNamePl}).'
          : 'Kolarz ominął losową kontrolę techniczną w oknie ${timingWindow.displayNamePl}.',
    );
  }

  /// Przeprowadza pełną inspekcję techniczną UCI i obsługuje korektę przed startem ITT lub DSQ.
  ScrutinyExecutionOutcome executeInspection({
    required TechnicalScrutinyAndCasTribunalModel currentModel,
    required String inspectionId,
    required String raceId,
    required int stageNumber,
    required ScrutinyTimingWindow timingWindow,
    required ScrutinySelectionMode selectionMode,
    required RiderEquipmentMeasurements measurements,
    List<XrayAndMagneticScanTelemetry> xrayScans = const [],
    String commissaireName = 'Jean-Luc Moreau (UCI Technical)',
    String? nowIso,
  }) {
    final effectiveScans = xrayScans.isEmpty
        ? _defaultCleanScans(
            inspectionId: inspectionId,
            commissaireName: commissaireName,
            nowIso: nowIso,
          )
        : xrayScans;

    final record = currentModel.evaluateInspection(
      inspectionId: inspectionId,
      raceId: raceId,
      stageNumber: stageNumber,
      timingWindow: timingWindow,
      selectionMode: selectionMode,
      measurements: measurements,
      xrayScans: effectiveScans,
      commissaireName: commissaireName,
      inspectedAtIso: nowIso,
    );

    TorqueRampCorrectionResult? torqueResult;
    if (record.overallOutcome ==
        ScrutinySessionOutcome.passedAfterTorqueCorrection) {
      torqueResult = _buildTorqueCorrectionResult(
        record: record,
        limits: currentModel.regulationLimits,
      );
    }

    final repDelta = _computeReputationDelta(record.overallOutcome);
    final sponsorDelta = _computeSponsorDelta(record.overallOutcome);
    final recommendedGrounds = _recommendAppealGrounds(record);
    final headline = _buildMediaHeadline(record, torqueResult);

    return ScrutinyExecutionOutcome(
      inspectionRecord: record,
      torqueCorrection: torqueResult,
      clubReputationDelta: repDelta,
      sponsorConfidenceDelta: sponsorDelta,
      canAppealToCas: record.isAppealableToCas,
      recommendedAppealGrounds: recommendedGrounds,
      mediaHeadlinePl: headline,
    );
  }

  /// Składa odwołanie od decyzji DSQ/konfiskaty do Trybunału CAS w Lozannie z udziałem prawników.
  CasAppealFilingResult fileCasAppeal({
    required TechnicalScrutinyAndCasTribunalModel currentModel,
    required double availableBudgetChf,
    required String caseId,
    required TechnicalScrutinyInspectionRecord inspection,
    required List<CasAppealGround> grounds,
    required CasLegalCounselTier counselTier,
    required bool requestProvisionalStay,
    required String submittedEvidenceSummaryPl,
    String? nowIso,
  }) {
    if (!inspection.isAppealableToCas) {
      return const CasAppealFilingResult(
        accepted: false,
        appealCase: null,
        totalCostChargedChf: 0.0,
        messagePl:
            'Decyzja inspekcji nie podlega zaskarżeniu do Trybunału CAS.',
      );
    }

    final alreadyFiled = currentModel.casCases.any(
      (c) => c.inspectionId == inspection.inspectionId,
    );
    if (alreadyFiled) {
      return const CasAppealFilingResult(
        accepted: false,
        appealCase: null,
        totalCostChargedChf: 0.0,
        messagePl:
            'Odwołanie od tej kontroli zostało już zarejestrowane w CAS.',
      );
    }

    const filingFeeChf = 1000.0;
    final totalCost = filingFeeChf + counselTier.costChf;
    if (availableBudgetChf < totalCost) {
      return CasAppealFilingResult(
        accepted: false,
        appealCase: null,
        totalCostChargedChf: 0.0,
        messagePl:
            'Brak środków w budżecie na opłatę CAS i obsługę prawną (${totalCost.toStringAsFixed(0)} CHF).',
      );
    }

    final updatedModel = currentModel.fileCasAppeal(
      caseId: caseId,
      inspection: inspection,
      grounds: grounds,
      counselTier: counselTier,
      requestProvisionalStay: requestProvisionalStay,
      submittedEvidenceSummaryPl: submittedEvidenceSummaryPl,
      nowIso: nowIso,
    );
    final createdCase = updatedModel.casCases.last;

    return CasAppealFilingResult(
      accepted: true,
      appealCase: createdCase,
      totalCostChargedChf: totalCost,
      messagePl: createdCase.provisionalStayGranted
          ? 'CAS przyjął skargę w trybie pilnym i zawiesił wykonanie kary (Provisional Stay).'
          : 'Skarga zarejestrowana w kancelarii CAS w Lozannie (${(createdCase.winProbability * 100).toStringAsFixed(0)}% szans).',
    );
  }

  /// Rozstrzyga sprawę przed panelem arbitrów Trybunału CAS w Lozannie.
  CasHearingResolutionResult resolveCasHearing({
    required TechnicalScrutinyAndCasTribunalModel currentModel,
    required String caseId,
    int deterministicSeed = 2026,
    CasTribunalStatus? forcedVerdict,
    String? nowIso,
  }) {
    final targetCase = currentModel.casCases.firstWhere(
      (c) => c.caseId == caseId,
      orElse: () => throw ArgumentError('Nie znaleziono sprawy CAS: $caseId'),
    );

    final relatedInspection = currentModel.inspectionHistory
        .cast<TechnicalScrutinyInspectionRecord?>()
        .firstWhere(
          (r) => r?.inspectionId == targetCase.inspectionId,
          orElse: () => null,
        );

    late final CasTribunalStatus finalStatus;
    if (forcedVerdict != null) {
      finalStatus = forcedVerdict;
    } else {
      final roll = math.Random(deterministicSeed).nextDouble();
      if (roll <= targetCase.winProbability * 0.68) {
        finalStatus = CasTribunalStatus.verdictOverturnedReinstated;
      } else if (roll <= targetCase.winProbability) {
        finalStatus = CasTribunalStatus.verdictReducedToFine;
      } else {
        finalStatus = CasTribunalStatus.verdictUpheldDsq;
      }
    }

    late final double repDelta;
    late final double sponsorDelta;
    late final double fineRefund;
    late final String summaryPl;

    switch (finalStatus) {
      case CasTribunalStatus.verdictOverturnedReinstated:
        repDelta = 11.0;
        sponsorDelta = 8.5;
        fineRefund = relatedInspection?.fineChf ?? 0.0;
        summaryPl =
            'Trybunał CAS w Lozannie uchylił decyzję komisarza UCI, przywrócił kolarza do klasyfikacji i nakazał zwrot grzywny.';
        break;
      case CasTribunalStatus.verdictReducedToFine:
        repDelta = 4.0;
        sponsorDelta = 3.0;
        fineRefund = (relatedInspection?.fineChf ?? 0.0) * 0.5;
        summaryPl =
            'CAS zamienił dyskwalifikację DSQ na łagodniejszą karę finansową, oczyszczając klub z zarzutu celowego oszustwa.';
        break;
      case CasTribunalStatus.verdictUpheldDsq:
      case CasTribunalStatus.notFiled:
      case CasTribunalStatus.filedPendingPreliminary:
      case CasTribunalStatus.expeditedProvisionalStayGranted:
      case CasTribunalStatus.hearingScheduledLausanne:
        repDelta = -7.5;
        sponsorDelta = -6.0;
        fineRefund = 0.0;
        summaryPl =
            'Trybunał CAS podtrzymał decyzję UCI o dyskwalifikacji. Zespół ponosi koszty postępowania oraz stratę wizerunkową.';
        break;
    }

    final resolved = targetCase.copyWith(
      status: finalStatus,
      verdictSummaryPl: summaryPl,
      reputationImpactDelta: repDelta,
      updatedAtIso: nowIso ?? DateTime.now().toUtc().toIso8601String(),
    );

    return CasHearingResolutionResult(
      resolvedCase: resolved,
      clubReputationDelta: repDelta,
      sponsorConfidenceDelta: sponsorDelta,
      fineRefundChf: fineRefund,
      officialCommuniquePl: summaryPl,
    );
  }

  /// Wykonuje działanie PR/audytu w celu odbudowy reputacji klubu i zaufania sponsorów.
  ReputationDefenseLogEntry executeReputationDefenseAction({
    required ReputationDefenseActionType actionType,
    required String entryId,
    required String relatedInspectionId,
    String? nowIso,
  }) {
    return ReputationDefenseLogEntry(
      entryId: entryId,
      actionType: actionType,
      relatedInspectionId: relatedInspectionId,
      costChf: actionType.costChf,
      reputationDelta: actionType.reputationRecoveryPoints,
      sponsorConfidenceDelta: actionType.sponsorConfidenceRecoveryPoints,
      summaryPl:
          '${actionType.displayNamePl}: +${actionType.reputationRecoveryPoints.toStringAsFixed(1)} reputacji, +${actionType.sponsorConfidenceRecoveryPoints.toStringAsFixed(1)} zaufania sponsorów.',
      createdAtIso: nowIso ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  TorqueRampCorrectionResult _buildTorqueCorrectionResult({
    required TechnicalScrutinyInspectionRecord record,
    required UciTechnicalRegulationLimits limits,
  }) {
    final m = record.measurements;
    final correctedZones = record.zoneResults
        .where((z) => z.requiresImmediateTorqueCorrection)
        .map((z) => z.zone)
        .toList(growable: false);

    final fixedLeverDeg = correctedZones
            .contains(EquipmentInspectionZone.handlebarBrakeLevers)
        ? (m.brakeLeverTiltDeg.isNegative
            ? -limits.maxBrakeLeverInwardTiltDeg
            : limits.maxBrakeLeverInwardTiltDeg)
        : m.brakeLeverTiltDeg;

    final fixedSockCm = correctedZones
            .contains(EquipmentInspectionZone.sockAndOvershoeHeight)
        ? double.parse(
            (m.shinLengthCm * limits.maxSockHeightRatioToShin)
                .toStringAsFixed(1),
          )
        : m.sockHeightCm;

    final fixedTtReachMm =
        correctedZones.contains(EquipmentInspectionZone.ttExtensionLength)
            ? limits.maxTtExtensionReachMm
            : m.ttExtensionReachMm;

    final correctedMeasurements = m.copyWith(
      brakeLeverTiltDeg: fixedLeverDeg,
      sockHeightCm: fixedSockCm,
      ttExtensionReachMm: fixedTtReachMm,
    );

    final isRamp = record.timingWindow == ScrutinyTimingWindow.preStartIttRamp;
    final aeroLossPct = double.parse(
      (correctedZones.length * (isRamp ? 1.35 : 0.85)).toStringAsFixed(2),
    );

    return TorqueRampCorrectionResult(
      riderId: record.riderId,
      timingWindow: record.timingWindow,
      correctionDurationSeconds: record.torqueCorrectionSeconds,
      riderStressSpikeDelta: record.riderStressSpikeDelta,
      riderFocusDropDelta: record.riderFocusDropDelta,
      aeroCdaPenaltyPercent: aeroLossPct,
      correctedZones: correctedZones,
      correctedMeasurements: correctedMeasurements,
      summaryPl: isRamp
          ? 'Awaryjna korekta kluczem dynamometrycznym na 3 min przed rampą ITT (${record.torqueCorrectionSeconds}s): stres +${record.riderStressSpikeDelta.toStringAsFixed(0)}, skupienie -${record.riderFocusDropDelta.toStringAsFixed(0)}.'
          : 'Korekta techniczna w padoku przed startem (${record.torqueCorrectionSeconds}s): sprzęt doprowadzony do normy UCI.',
    );
  }

  List<XrayAndMagneticScanTelemetry> _defaultCleanScans({
    required String inspectionId,
    required String commissaireName,
    String? nowIso,
  }) {
    final ts = nowIso ?? DateTime.now().toUtc().toIso8601String();
    return [
      XrayAndMagneticScanTelemetry(
        scanId: '${inspectionId}_xray_bb',
        deviceType: ScrutinyDeviceType.mobileXrayScanner,
        zone: EquipmentInspectionZone.bottomBracketShell,
        magneticFluxMicroTesla: 14.2,
        xrayMetalDensityScore: 0.18,
        hiddenMotorSignatureDetected: false,
        unusualBatteryCellDetected: false,
        serialNumberVerified: true,
        scanDurationSeconds: 18,
        operatorCommissaireId: commissaireName,
        timestampIso: ts,
      ),
    ];
  }

  double _computeReputationDelta(ScrutinySessionOutcome outcome) {
    switch (outcome) {
      case ScrutinySessionOutcome.passedClean:
        return 0.5;
      case ScrutinySessionOutcome.passedAfterTorqueCorrection:
        return -2.5;
      case ScrutinySessionOutcome.relegatedOrTimePenalty:
        return -5.0;
      case ScrutinySessionOutcome.disqualifiedDsq:
        return -12.0;
      case ScrutinySessionOutcome.impoundedForLabXray:
        return -24.0;
    }
  }

  double _computeSponsorDelta(ScrutinySessionOutcome outcome) {
    switch (outcome) {
      case ScrutinySessionOutcome.passedClean:
        return 0.4;
      case ScrutinySessionOutcome.passedAfterTorqueCorrection:
        return -1.8;
      case ScrutinySessionOutcome.relegatedOrTimePenalty:
        return -4.0;
      case ScrutinySessionOutcome.disqualifiedDsq:
        return -10.0;
      case ScrutinySessionOutcome.impoundedForLabXray:
        return -20.0;
    }
  }

  List<CasAppealGround> _recommendAppealGrounds(
    TechnicalScrutinyInspectionRecord record,
  ) {
    final grounds = <CasAppealGround>[];
    final failedZones = record.failedZones.map((z) => z.zone).toSet();

    if (failedZones.contains(EquipmentInspectionZone.handlebarBrakeLevers)) {
      grounds.add(CasAppealGround.forceMajeureMechanicalShift);
      grounds.add(CasAppealGround.sensorCalibrationDispute);
    }
    if (failedZones.contains(EquipmentInspectionZone.ttExtensionLength) ||
        failedZones.contains(EquipmentInspectionZone.frameTubeDimensions3to1)) {
      grounds.add(CasAppealGround.aeroRuleAmbiguity);
    }
    if (record.xrayScans.any((s) => !s.isClean)) {
      grounds.add(CasAppealGround.chainOfCustodyBreach);
    }
    if (grounds.isEmpty) {
      grounds.add(CasAppealGround.proceduralErrorByCommissaire);
    }
    return grounds;
  }

  String _buildMediaHeadline(
    TechnicalScrutinyInspectionRecord record,
    TorqueRampCorrectionResult? torque,
  ) {
    switch (record.overallOutcome) {
      case ScrutinySessionOutcome.passedClean:
        return 'Rower ${record.riderName} przeszedł kontrolę UCI bez zastrzeżeń.';
      case ScrutinySessionOutcome.passedAfterTorqueCorrection:
        return torque != null &&
                torque.timingWindow == ScrutinyTimingWindow.preStartIttRamp
            ? 'Nerwowe sceny na rampie ITT! Mechanicy korygowali kokpit ${record.riderName} tuż przed startem.'
            : 'Drobna korekta sprzętu ${record.riderName} przed startem — komisarz dopuścił rower.';
      case ScrutinySessionOutcome.relegatedOrTimePenalty:
        return 'Kara regulaminowa UCI dla ${record.riderName} za niezgodność aerodynamiczną.';
      case ScrutinySessionOutcome.disqualifiedDsq:
        return 'SKANDAL TECHNICZNY: ${record.riderName} zdyskwalifikowany (DSQ) po kontroli komisarza UCI!';
      case ScrutinySessionOutcome.impoundedForLabXray:
        return 'PILNE: Rower ${record.riderName} zabezpieczony przez UCI do laboratoryjnego skanu X-Ray!';
    }
  }
}

/// Niemutowalny stan kontrolera kontroli technicznych i obrony reputacji klubu.
class TechnicalScrutinyDefenseState {
  final TechnicalScrutinyAndCasTribunalModel tribunalModel;
  final double clubReputationScore;
  final double sponsorConfidenceScore;
  final double availableClubBudgetChf;
  final List<ScrutinyExecutionOutcome> recentOutcomes;
  final List<ReputationDefenseLogEntry> reputationLogs;
  final String? selectedInspectionId;
  final String? selectedCasCaseId;
  final bool isProcessing;
  final String? lastStatusMessagePl;

  const TechnicalScrutinyDefenseState({
    required this.tribunalModel,
    required this.clubReputationScore,
    required this.sponsorConfidenceScore,
    required this.availableClubBudgetChf,
    required this.recentOutcomes,
    required this.reputationLogs,
    this.selectedInspectionId,
    this.selectedCasCaseId,
    this.isProcessing = false,
    this.lastStatusMessagePl,
  });

  factory TechnicalScrutinyDefenseState.initial({int seasonYear = 2026}) {
    return TechnicalScrutinyDefenseState(
      tribunalModel: TechnicalScrutinyAndCasTribunalModel.initial(
        seasonYear: seasonYear,
      ),
      clubReputationScore: 78.0,
      sponsorConfidenceScore: 82.0,
      availableClubBudgetChf: 250000.0,
      recentOutcomes: const [],
      reputationLogs: const [],
    );
  }

  TechnicalScrutinyInspectionRecord? get selectedInspection {
    if (selectedInspectionId == null) {
      return tribunalModel.inspectionHistory.isEmpty
          ? null
          : tribunalModel.inspectionHistory.last;
    }
    return tribunalModel.inspectionHistory
        .cast<TechnicalScrutinyInspectionRecord?>()
        .firstWhere(
          (r) => r?.inspectionId == selectedInspectionId,
          orElse: () => null,
        );
  }

  CasTribunalAppealCase? get selectedCasCase {
    if (selectedCasCaseId == null) {
      return tribunalModel.casCases.isEmpty ? null : tribunalModel.casCases.last;
    }
    return tribunalModel.casCases.cast<CasTribunalAppealCase?>().firstWhere(
          (c) => c?.caseId == selectedCasCaseId,
          orElse: () => null,
        );
  }

  TechnicalScrutinyDefenseState copyWith({
    TechnicalScrutinyAndCasTribunalModel? tribunalModel,
    double? clubReputationScore,
    double? sponsorConfidenceScore,
    double? availableClubBudgetChf,
    List<ScrutinyExecutionOutcome>? recentOutcomes,
    List<ReputationDefenseLogEntry>? reputationLogs,
    String? selectedInspectionId,
    String? selectedCasCaseId,
    bool? isProcessing,
    String? lastStatusMessagePl,
  }) {
    return TechnicalScrutinyDefenseState(
      tribunalModel: tribunalModel ?? this.tribunalModel,
      clubReputationScore: clubReputationScore ?? this.clubReputationScore,
      sponsorConfidenceScore:
          sponsorConfidenceScore ?? this.sponsorConfidenceScore,
      availableClubBudgetChf:
          availableClubBudgetChf ?? this.availableClubBudgetChf,
      recentOutcomes: recentOutcomes ?? this.recentOutcomes,
      reputationLogs: reputationLogs ?? this.reputationLogs,
      selectedInspectionId: selectedInspectionId ?? this.selectedInspectionId,
      selectedCasCaseId: selectedCasCaseId ?? this.selectedCasCaseId,
      isProcessing: isProcessing ?? this.isProcessing,
      lastStatusMessagePl: lastStatusMessagePl ?? this.lastStatusMessagePl,
    );
  }
}

/// Notifier Riverpod zarządzający inspekcjami UCI, odwołaniami CAS i obroną reputacji.
class TechnicalScrutinyDefenseNotifier
    extends StateNotifier<TechnicalScrutinyDefenseState> {
  final TechnicalScrutinyAndReputationDefenseService _service;

  TechnicalScrutinyDefenseNotifier(this._service)
      : super(TechnicalScrutinyDefenseState.initial());

  /// Przeprowadza kontrolę techniczną UCI i zapisuje wynik w stanie klubu.
  ScrutinyExecutionOutcome runTechnicalScrutiny({
    required String inspectionId,
    required String raceId,
    required int stageNumber,
    required ScrutinyTimingWindow timingWindow,
    required ScrutinySelectionMode selectionMode,
    required RiderEquipmentMeasurements measurements,
    List<XrayAndMagneticScanTelemetry> xrayScans = const [],
    String commissaireName = 'Jean-Luc Moreau (UCI Technical)',
    String? nowIso,
  }) {
    final outcome = _service.executeInspection(
      currentModel: state.tribunalModel,
      inspectionId: inspectionId,
      raceId: raceId,
      stageNumber: stageNumber,
      timingWindow: timingWindow,
      selectionMode: selectionMode,
      measurements: measurements,
      xrayScans: xrayScans,
      commissaireName: commissaireName,
      nowIso: nowIso,
    );

    final updatedModel =
        state.tribunalModel.recordInspection(outcome.inspectionRecord);
    final updatedBudget = math.max(
      0.0,
      state.availableClubBudgetChf - outcome.inspectionRecord.fineChf,
    );

    state = state.copyWith(
      tribunalModel: updatedModel,
      clubReputationScore:
          (state.clubReputationScore + outcome.clubReputationDelta)
              .clamp(0.0, 100.0),
      sponsorConfidenceScore:
          (state.sponsorConfidenceScore + outcome.sponsorConfidenceDelta)
              .clamp(0.0, 100.0),
      availableClubBudgetChf: updatedBudget,
      recentOutcomes: [outcome, ...state.recentOutcomes],
      selectedInspectionId: outcome.inspectionRecord.inspectionId,
      lastStatusMessagePl: outcome.mediaHeadlinePl,
    );

    return outcome;
  }

  /// Składa odwołanie do Trybunału CAS z udziałem wybranej kancelarii prawnej.
  CasAppealFilingResult submitCasAppeal({
    required String caseId,
    required TechnicalScrutinyInspectionRecord inspection,
    required List<CasAppealGround> grounds,
    required CasLegalCounselTier counselTier,
    required bool requestProvisionalStay,
    required String submittedEvidenceSummaryPl,
    String? nowIso,
  }) {
    final filing = _service.fileCasAppeal(
      currentModel: state.tribunalModel,
      availableBudgetChf: state.availableClubBudgetChf,
      caseId: caseId,
      inspection: inspection,
      grounds: grounds,
      counselTier: counselTier,
      requestProvisionalStay: requestProvisionalStay,
      submittedEvidenceSummaryPl: submittedEvidenceSummaryPl,
      nowIso: nowIso,
    );

    if (!filing.accepted || filing.appealCase == null) {
      state = state.copyWith(lastStatusMessagePl: filing.messagePl);
      return filing;
    }

    final updatedModel = state.tribunalModel.fileCasAppeal(
      caseId: caseId,
      inspection: inspection,
      grounds: grounds,
      counselTier: counselTier,
      requestProvisionalStay: requestProvisionalStay,
      submittedEvidenceSummaryPl: submittedEvidenceSummaryPl,
      nowIso: nowIso,
    );

    state = state.copyWith(
      tribunalModel: updatedModel,
      availableClubBudgetChf:
          math.max(0.0, state.availableClubBudgetChf - filing.totalCostChargedChf),
      selectedCasCaseId: filing.appealCase!.caseId,
      lastStatusMessagePl: filing.messagePl,
    );

    return filing;
  }

  /// Rozstrzyga aktywną sprawę przed Trybunałem CAS w Lozannie.
  CasHearingResolutionResult resolveCasAppeal({
    required String caseId,
    int deterministicSeed = 2026,
    CasTribunalStatus? forcedVerdict,
    String? nowIso,
  }) {
    final resolution = _service.resolveCasHearing(
      currentModel: state.tribunalModel,
      caseId: caseId,
      deterministicSeed: deterministicSeed,
      forcedVerdict: forcedVerdict,
      nowIso: nowIso,
    );

    final updatedModel = state.tribunalModel.resolveCasCase(
      caseId: caseId,
      finalStatus: resolution.resolvedCase.status,
      verdictSummaryPl: resolution.officialCommuniquePl,
      fineRefundChf: resolution.fineRefundChf,
      nowIso: nowIso,
    );

    state = state.copyWith(
      tribunalModel: updatedModel,
      clubReputationScore:
          (state.clubReputationScore + resolution.clubReputationDelta)
              .clamp(0.0, 100.0),
      sponsorConfidenceScore:
          (state.sponsorConfidenceScore + resolution.sponsorConfidenceDelta)
              .clamp(0.0, 100.0),
      availableClubBudgetChf:
          state.availableClubBudgetChf + resolution.fineRefundChf,
      lastStatusMessagePl: resolution.officialCommuniquePl,
    );

    return resolution;
  }

  /// Uruchamia akcję PR lub audyt techniczny w celu odbudowy reputacji klubu.
  bool triggerReputationDefenseAction({
    required ReputationDefenseActionType actionType,
    required String entryId,
    required String relatedInspectionId,
    String? nowIso,
  }) {
    if (state.availableClubBudgetChf < actionType.costChf) {
      state = state.copyWith(
        lastStatusMessagePl:
            'Niewystarczający budżet na działanie: ${actionType.displayNamePl}.',
      );
      return false;
    }

    final log = _service.executeReputationDefenseAction(
      actionType: actionType,
      entryId: entryId,
      relatedInspectionId: relatedInspectionId,
      nowIso: nowIso,
    );

    state = state.copyWith(
      availableClubBudgetChf: state.availableClubBudgetChf - log.costChf,
      clubReputationScore:
          (state.clubReputationScore + log.reputationDelta).clamp(0.0, 100.0),
      sponsorConfidenceScore:
          (state.sponsorConfidenceScore + log.sponsorConfidenceDelta)
              .clamp(0.0, 100.0),
      reputationLogs: [log, ...state.reputationLogs],
      lastStatusMessagePl: log.summaryPl,
    );
    return true;
  }

  /// Wybiera konkretną inspekcję w panelu podglądu.
  void selectInspection(String inspectionId) {
    state = state.copyWith(selectedInspectionId: inspectionId);
  }
}

/// Provider czystej logiki serwisu kontroli technicznych i obrony reputacji.
final technicalScrutinyDefenseServiceProvider =
    Provider<TechnicalScrutinyAndReputationDefenseService>(
  (ref) => const TechnicalScrutinyAndReputationDefenseService(),
);

/// Provider stanu kontroli technicznych UCI, spraw CAS i reputacji klubu.
final technicalScrutinyDefenseProvider = StateNotifierProvider<
    TechnicalScrutinyDefenseNotifier, TechnicalScrutinyDefenseState>(
  (ref) => TechnicalScrutinyDefenseNotifier(
    ref.watch(technicalScrutinyDefenseServiceProvider),
  ),
);

/// Produkcyjny panel UI zarządzania kontrolami UCI, korektami na rampie ITT i trybunałem CAS.
class TechnicalScrutinyAndReputationDefensePanel extends ConsumerStatefulWidget {
  const TechnicalScrutinyAndReputationDefensePanel({super.key});

  @override
  ConsumerState<TechnicalScrutinyAndReputationDefensePanel> createState() =>
      _TechnicalScrutinyAndReputationDefensePanelState();
}

class _TechnicalScrutinyAndReputationDefensePanelState
    extends ConsumerState<TechnicalScrutinyAndReputationDefensePanel> {
  CasLegalCounselTier _selectedCounsel =
      CasLegalCounselTier.specialistSportsAttorney;
  CasAppealGround _selectedGround =
      CasAppealGround.forceMajeureMechanicalShift;
  bool _requestProvisionalStay = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicalScrutinyDefenseProvider);
    final notifier = ref.read(technicalScrutinyDefenseProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1120;
          final isTablet =
              constraints.maxWidth >= 680 && constraints.maxWidth < 1120;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBar(state, constraints.maxWidth < 680),
                const SizedBox(height: 16),
                if (state.lastStatusMessagePl != null) ...[
                  _buildStatusBanner(state.lastStatusMessagePl!),
                  const SizedBox(height: 16),
                ],
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildScrutinyActionsCard(state, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _buildCasAndReputationCard(state, notifier),
                      ),
                    ],
                  )
                else if (isTablet)
                  Column(
                    children: [
                      _buildScrutinyActionsCard(state, notifier),
                      const SizedBox(height: 16),
                      _buildCasAndReputationCard(state, notifier),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildScrutinyActionsCard(state, notifier),
                      const SizedBox(height: 12),
                      _buildCasAndReputationCard(state, notifier),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBar(TechnicalScrutinyDefenseState state, bool isCompact) {
    final metrics = [
      _MetricChip(
        label: 'AUDYT UCI',
        value:
            '${state.tribunalModel.teamComplianceAuditScore.toStringAsFixed(0)}%',
        accent: AppColors.accentBlue,
      ),
      _MetricChip(
        label: 'REPUTACJA',
        value: '${state.clubReputationScore.toStringAsFixed(1)}%',
        accent: AppColors.goldAccent,
      ),
      _MetricChip(
        label: 'SPONSORZY',
        value: '${state.sponsorConfidenceScore.toStringAsFixed(1)}%',
        accent: AppColors.statusSuccess,
      ),
      _MetricChip(
        label: 'BUDŻET PRAWNY',
        value: '${state.availableClubBudgetChf.toStringAsFixed(0)} CHF',
        accent: AppColors.textPrimary,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryAccent),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrole Techniczne UCI & Trybunał CAS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Inspekcje rampy ITT, skany X-Ray oraz obrona reputacji klubu w Lozannie',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: isCompact ? metrics : metrics,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String message) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_rounded,
            color: AppColors.goldAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrutinyActionsCard(
    TechnicalScrutinyDefenseState state,
    TechnicalScrutinyDefenseNotifier notifier,
  ) {
    final inspection = state.selectedInspection;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Symulacja Kontroli Komisarza UCI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TacticalActionButton(
                label: 'Kontrola ITT na rampie (-3 min)',
                icon: Icons.build_rounded,
                accent: AppColors.amberWarning,
                onPressed: () {
                  final id =
                      'insp_${state.tribunalModel.inspectionHistory.length + 1}';
                  notifier.runTechnicalScrutiny(
                    inspectionId: id,
                    raceId: 'tour_de_france',
                    stageNumber: 7,
                    timingWindow: ScrutinyTimingWindow.preStartIttRamp,
                    selectionMode: ScrutinySelectionMode.targetedSuspectedAero,
                    measurements: RiderEquipmentMeasurements(
                      riderId: 'rider_leader_1',
                      riderName: 'Jan Kowalski',
                      teamId: 'player_team',
                      frameSerialNumber: 'PPM-TT-2026-01',
                      bikeWeightKg: 7.12,
                      sockHeightCm: 22.5,
                      shinLengthCm: 40.0,
                      brakeLeverTiltDeg: 13.5,
                      ttExtensionReachMm: 816.0,
                      isTimeTrialSetup: true,
                      frameJigCompliant: true,
                      measuredAtIso: DateTime.now().toUtc().toIso8601String(),
                    ),
                  );
                },
              ),
              _TacticalActionButton(
                label: 'Kontrola po mecie (ryzyko DSQ)',
                icon: Icons.warning_amber_rounded,
                accent: AppColors.crimsonAlert,
                onPressed: () {
                  final id =
                      'insp_${state.tribunalModel.inspectionHistory.length + 1}';
                  notifier.runTechnicalScrutiny(
                    inspectionId: id,
                    raceId: 'paris_roubaix',
                    stageNumber: 1,
                    timingWindow: ScrutinyTimingWindow.postFinishLine,
                    selectionMode: ScrutinySelectionMode.targetedStageWinner,
                    measurements: RiderEquipmentMeasurements(
                      riderId: 'rider_sprinter_2',
                      riderName: 'Marek Nowak',
                      teamId: 'player_team',
                      frameSerialNumber: 'PPM-RD-2026-08',
                      bikeWeightKg: 6.72,
                      sockHeightCm: 19.0,
                      shinLengthCm: 40.0,
                      brakeLeverTiltDeg: 14.0,
                      ttExtensionReachMm: 740.0,
                      isTimeTrialSetup: false,
                      frameJigCompliant: true,
                      measuredAtIso: DateTime.now().toUtc().toIso8601String(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (inspection == null)
            const Text(
              'Brak zarejestrowanych kontroli technicznych w bieżącym sezonie.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Text(
              'Protokół: ${inspection.riderName} • ${inspection.overallOutcome.displayNamePl}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            if (inspection.riderStressSpikeDelta > 0)
              Text(
                'Wpływ na rampie: stres +${inspection.riderStressSpikeDelta.toStringAsFixed(0)} | skupienie -${inspection.riderFocusDropDelta.toStringAsFixed(0)} | czas korekty ${inspection.torqueCorrectionSeconds}s',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.amberWarning,
                ),
              ),
            const SizedBox(height: 8),
            for (final z in inspection.zoneResults)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      z.passed
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 16,
                      color: z.passed
                          ? AppColors.statusSuccess
                          : AppColors.crimsonAlert,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${z.zone.displayNamePl}: ${z.measuredValue} ${z.unit} (limit ${z.limitValue} ${z.unit})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCasAndReputationCard(
    TechnicalScrutinyDefenseState state,
    TechnicalScrutinyDefenseNotifier notifier,
  ) {
    final inspection = state.selectedInspection;
    final canAppeal = inspection != null &&
        inspection.isAppealableToCas &&
        !state.tribunalModel.casCases.any(
          (c) => c.inspectionId == inspection.inspectionId,
        );
    final activeCase = state.selectedCasCase;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Odwołanie do Trybunału CAS & Obrona Reputacji',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CasLegalCounselTier.values.map((tier) {
              final selected = _selectedCounsel == tier;
              return _SelectableOptionChip(
                label:
                    '${tier.displayNamePl} (${tier.costChf.toStringAsFixed(0)} CHF)',
                selected: selected,
                onTap: () => setState(() => _selectedCounsel = tier),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CasAppealGround.values.take(3).map((ground) {
              final selected = _selectedGround == ground;
              return _SelectableOptionChip(
                label: ground.displayNamePl,
                selected: selected,
                onTap: () => setState(() => _selectedGround = ground),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _requestProvisionalStay,
                activeColor: AppColors.goldAccent,
                onChanged: (v) =>
                    setState(() => _requestProvisionalStay = v ?? true),
              ),
              const Expanded(
                child: Text(
                  'Wniosek o pilne zawieszenie kary (Provisional Stay)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TacticalActionButton(
                label: 'Złóż odwołanie do CAS',
                icon: Icons.balance_rounded,
                accent: AppColors.goldAccent,
                enabled: canAppeal,
                onPressed: canAppeal
                    ? () {
                        notifier.submitCasAppeal(
                          caseId:
                              'cas_${state.tribunalModel.casCases.length + 1}',
                          inspection: inspection,
                          grounds: [_selectedGround],
                          counselTier: _selectedCounsel,
                          requestProvisionalStay: _requestProvisionalStay,
                          submittedEvidenceSummaryPl:
                              'Dane telemetryczne CAD oraz protokół mechanika z odprawy.',
                        );
                      }
                    : null,
              ),
              _TacticalActionButton(
                label: 'Rozstrzygnij rozprawę CAS',
                icon: Icons.fact_check_rounded,
                accent: AppColors.accentBlue,
                enabled: activeCase != null && !activeCase.isResolved,
                onPressed: activeCase != null && !activeCase.isResolved
                    ? () => notifier.resolveCasAppeal(caseId: activeCase.caseId)
                    : null,
              ),
              _TacticalActionButton(
                label: 'Audyt laboratoryjny PR (-14k CHF)',
                icon: Icons.verified_user_rounded,
                accent: AppColors.statusSuccess,
                enabled: state.availableClubBudgetChf >=
                    ReputationDefenseActionType.independentLabAudit.costChf,
                onPressed: () {
                  notifier.triggerReputationDefenseAction(
                    actionType: ReputationDefenseActionType.independentLabAudit,
                    entryId: 'rep_${state.reputationLogs.length + 1}',
                    relatedInspectionId: inspection?.inspectionId ?? 'general',
                  );
                },
              ),
            ],
          ),
          if (activeCase != null) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sprawa ${activeCase.caseId}: ${activeCase.status.displayNamePl}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Szansa wygranej: ${(activeCase.winProbability * 100).toStringAsFixed(0)}% • Koszt: ${activeCase.totalLegalSpendChf.toStringAsFixed(0)} CHF',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticalActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback? onPressed;

  const _TacticalActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  State<_TacticalActionButton> createState() => _TacticalActionButtonState();
}

class _TacticalActionButtonState extends State<_TacticalActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onPressed != null;
    final bgColor = !active
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _pressed
            ? widget.accent.withValues(alpha: 0.28)
            : _hovered
                ? widget.accent.withValues(alpha: 0.20)
                : widget.accent.withValues(alpha: 0.12);

    final borderColor = !active
        ? AppColors.cardBorder
        : (_focused || _hovered)
            ? widget.accent
            : widget.accent.withValues(alpha: 0.55);

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: active ? (_) => setState(() => _pressed = true) : null,
          onTapUp: active ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: active ? () => setState(() => _pressed = false) : null,
          onTap: active ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: active ? widget.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableOptionChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SelectableOptionChip> createState() => _SelectableOptionChipState();
}

class _SelectableOptionChipState extends State<_SelectableOptionChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.goldAccent.withValues(alpha: 0.18)
                  : _hovered
                      ? AppColors.surfaceLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.selected || _focused
                    ? AppColors.goldAccent
                    : AppColors.cardBorder,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
