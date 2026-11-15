// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../engine/events/race_incident_engine.dart';
import '../../models/career/recovery_protocol_system.dart';
import '../../models/race/race_stage.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_health.dart';

/// Modalność diagnostyki medycznej wykonanej po zakończeniu etapu.
enum DiagnosticImagingModality {
  clinicalInspection,
  xRay,
  mri,
  ultrasound,
  concussionScat6;

  String toJson() => name;

  static DiagnosticImagingModality fromJson(String value) {
    return DiagnosticImagingModality.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DiagnosticImagingModality.clinicalInspection,
    );
  }

  String get labelPl {
    switch (this) {
      case DiagnosticImagingModality.clinicalInspection:
        return 'Badanie kliniczne (Autobus / Punkt medyczny)';
      case DiagnosticImagingModality.xRay:
        return 'RTG cyfrowe (Zdjęcie rentgenowskie)';
      case DiagnosticImagingModality.mri:
        return 'MRI (Rezonans magnetyczny)';
      case DiagnosticImagingModality.ultrasound:
        return 'USG mięśniowo-szkieletowe';
      case DiagnosticImagingModality.concussionScat6:
        return 'Protokół neurologiczny SCAT-6';
    }
  }
}

/// Kategoria rozpoznania urazu powypadkowego po kraksie na etapie.
enum TraumaDiagnosisCategory {
  contusionBruising,
  roadRashAbrasion,
  clavicleFracture,
  wristFracture,
  concussion,
  kneeTendinitisOrLigament,
  muscleTear,
  clearedNoStructuralTrauma;

  String toJson() => name;

  static TraumaDiagnosisCategory fromJson(String value) {
    return TraumaDiagnosisCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TraumaDiagnosisCategory.contusionBruising,
    );
  }

  String get labelPl {
    switch (this) {
      case TraumaDiagnosisCategory.contusionBruising:
        return 'Stłuczenia i krwiaki tkanek miękkich (bez złamań)';
      case TraumaDiagnosisCategory.roadRashAbrasion:
        return 'Rozległe szlify naskórka ("Road Rash")';
      case TraumaDiagnosisCategory.clavicleFracture:
        return 'Złamanie obojczyka';
      case TraumaDiagnosisCategory.wristFracture:
        return 'Złamanie kości nadgarstka / łódeczkowatej';
      case TraumaDiagnosisCategory.concussion:
        return 'Wstrząśnienie mózgu (Protokół UCI)';
      case TraumaDiagnosisCategory.kneeTendinitisOrLigament:
        return 'Uraz stawu kolanowego / naciągnięcie więzadeł';
      case TraumaDiagnosisCategory.muscleTear:
        return 'Naderwanie włókien mięśniowych';
      case TraumaDiagnosisCategory.clearedNoStructuralTrauma:
        return 'Brak urazów strukturalnych — pełna zdolność';
    }
  }

  /// Priorytet ciężkości urazu do rozstrzygania wielokrotnych kraks na tym samym etapie.
  int get severityRank {
    switch (this) {
      case TraumaDiagnosisCategory.concussion:
        return 7;
      case TraumaDiagnosisCategory.clavicleFracture:
        return 6;
      case TraumaDiagnosisCategory.wristFracture:
        return 5;
      case TraumaDiagnosisCategory.muscleTear:
        return 4;
      case TraumaDiagnosisCategory.kneeTendinitisOrLigament:
        return 3;
      case TraumaDiagnosisCategory.roadRashAbrasion:
        return 2;
      case TraumaDiagnosisCategory.contusionBruising:
        return 1;
      case TraumaDiagnosisCategory.clearedNoStructuralTrauma:
        return 0;
    }
  }
}

/// Decyzja lekarza wyścigu oraz sztabu medycznego o dopuszczeniu do dalszej jazdy.
enum RaceClearanceDecision {
  fitToContinue,
  fitWithPainAndPenalty,
  medicalWithdrawalDnf,
  medicalExclusionDns;

  String toJson() => name;

  static RaceClearanceDecision fromJson(String value) {
    return RaceClearanceDecision.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RaceClearanceDecision.fitToContinue,
    );
  }

  bool get isExcluded =>
      this == RaceClearanceDecision.medicalWithdrawalDnf ||
      this == RaceClearanceDecision.medicalExclusionDns;

  String get statusCode {
    switch (this) {
      case RaceClearanceDecision.fitToContinue:
        return 'FIT';
      case RaceClearanceDecision.fitWithPainAndPenalty:
        return 'FIT*';
      case RaceClearanceDecision.medicalWithdrawalDnf:
        return 'DNF';
      case RaceClearanceDecision.medicalExclusionDns:
        return 'DNS';
    }
  }

  String get labelPl {
    switch (this) {
      case RaceClearanceDecision.fitToContinue:
        return 'Dopuszczony do dalszej jazdy';
      case RaceClearanceDecision.fitWithPainAndPenalty:
        return 'Dopuszczony warunkowo (obniżona regeneracja nocna)';
      case RaceClearanceDecision.medicalWithdrawalDnf:
        return 'Wycofanie medyczne na trasie (DNF)';
      case RaceClearanceDecision.medicalExclusionDns:
        return 'Wykluczony po diagnostyce po etapie (DNS)';
    }
  }
}

/// Wynik pojedynczego badania obrazowego lub klinicznego (RTG / MRI / USG / SCAT-6).
class DiagnosticImagingResult {
  final DiagnosticImagingModality modality;
  final String anatomicalRegionPl;
  final String findingsPl;
  final bool isFractureConfirmed;
  final bool isSoftTissueDamageConfirmed;
  final bool performedAtHospital;
  final int costEur;

  const DiagnosticImagingResult({
    required this.modality,
    required this.anatomicalRegionPl,
    required this.findingsPl,
    required this.isFractureConfirmed,
    required this.isSoftTissueDamageConfirmed,
    required this.performedAtHospital,
    required this.costEur,
  });

  Map<String, dynamic> toJson() => {
        'modality': modality.toJson(),
        'anatomicalRegionPl': anatomicalRegionPl,
        'findingsPl': findingsPl,
        'isFractureConfirmed': isFractureConfirmed,
        'isSoftTissueDamageConfirmed': isSoftTissueDamageConfirmed,
        'performedAtHospital': performedAtHospital,
        'costEur': costEur,
      };

  factory DiagnosticImagingResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticImagingResult(
      modality: DiagnosticImagingModality.fromJson(json['modality'] as String),
      anatomicalRegionPl: json['anatomicalRegionPl'] as String,
      findingsPl: json['findingsPl'] as String,
      isFractureConfirmed: json['isFractureConfirmed'] as bool,
      isSoftTissueDamageConfirmed: json['isSoftTissueDamageConfirmed'] as bool,
      performedAtHospital: json['performedAtHospital'] as bool,
      costEur: (json['costEur'] as num).toInt(),
    );
  }
}

/// Szczegółowy raport medyczny pojedynczego kolarza po kraksie na etapie.
class RiderTraumaCaseReport {
  final String riderId;
  final String riderName;
  final String teamId;
  final IncidentType incidentType;
  final double kilometerMark;
  final TraumaDiagnosisCategory diagnosisCategory;
  final List<DiagnosticImagingResult> imagingResults;
  final RaceClearanceDecision clearanceDecision;

  /// Redukcja nocnej regeneracji (np. 0.25 = -25% dla rozległych szlifów "road rash").
  final double overnightRecoveryPenaltyRatio;
  final int recommendedRecoveryDays;
  final Injury? assignedInjury;
  final List<RecoveryProtocolType> recommendedProtocols;
  final String medicalSummaryPl;
  final String doctorNotesPl;

  const RiderTraumaCaseReport({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.incidentType,
    required this.kilometerMark,
    required this.diagnosisCategory,
    required this.imagingResults,
    required this.clearanceDecision,
    required this.overnightRecoveryPenaltyRatio,
    required this.recommendedRecoveryDays,
    this.assignedInjury,
    required this.recommendedProtocols,
    required this.medicalSummaryPl,
    required this.doctorNotesPl,
  });

  bool get isExcludedFromRace => clearanceDecision.isExcluded;
  String get statusCode => clearanceDecision.statusCode;

  int get totalImagingCostEur =>
      imagingResults.fold<int>(0, (sum, item) => sum + item.costEur);

  bool get hasConfirmedFracture =>
      imagingResults.any((item) => item.isFractureConfirmed);

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'incidentType': incidentType.toJson(),
        'kilometerMark': kilometerMark,
        'diagnosisCategory': diagnosisCategory.toJson(),
        'imagingResults': imagingResults.map((e) => e.toJson()).toList(),
        'clearanceDecision': clearanceDecision.toJson(),
        'overnightRecoveryPenaltyRatio': overnightRecoveryPenaltyRatio,
        'recommendedRecoveryDays': recommendedRecoveryDays,
        'assignedInjury': assignedInjury?.toJson(),
        'recommendedProtocols':
            recommendedProtocols.map((p) => p.name).toList(),
        'medicalSummaryPl': medicalSummaryPl,
        'doctorNotesPl': doctorNotesPl,
      };

  factory RiderTraumaCaseReport.fromJson(Map<String, dynamic> json) {
    final rawProtocols = (json['recommendedProtocols'] as List<dynamic>? ?? [])
        .map((name) => RecoveryProtocolType.values.firstWhere(
              (p) => p.name == name,
              orElse: () => RecoveryProtocolType.physiotherapyManualTherapy,
            ))
        .toList();

    return RiderTraumaCaseReport(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      incidentType: IncidentType.fromJson(json['incidentType'] as String),
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      diagnosisCategory: TraumaDiagnosisCategory.fromJson(
        json['diagnosisCategory'] as String,
      ),
      imagingResults: (json['imagingResults'] as List<dynamic>)
          .map((e) =>
              DiagnosticImagingResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      clearanceDecision: RaceClearanceDecision.fromJson(
        json['clearanceDecision'] as String,
      ),
      overnightRecoveryPenaltyRatio:
          (json['overnightRecoveryPenaltyRatio'] as num).toDouble(),
      recommendedRecoveryDays:
          (json['recommendedRecoveryDays'] as num).toInt(),
      assignedInjury: json['assignedInjury'] != null
          ? Injury.fromJson(json['assignedInjury'] as Map<String, dynamic>)
          : null,
      recommendedProtocols: rawProtocols,
      medicalSummaryPl: json['medicalSummaryPl'] as String,
      doctorNotesPl: json['doctorNotesPl'] as String,
    );
  }
}

/// Generator i kontener raportów medycznych po kraksach na etapie.
///
/// Obejmuje diagnostykę obrazową RTG/MRI po etapie:
/// - stłuczenia i krwiaki tkanek miękkich (wykluczenie złamań w RTG),
/// - rozległe szlify naskórka ("road rash") obniżające regenerację nocną o 25%,
/// - złamania obojczyka lub nadgarstka wykluczające z dalszej jazdy (DNF/DNS).
class MedicalPostRaceTraumaReport {
  /// Standardowa redukcja nocnej regeneracji przy rozległych szlifach "road rash".
  static const double roadRashOvernightRecoveryPenalty = 0.25;

  /// Redukcja nocnej regeneracji przy głębokich stłuczeniach po upadku.
  static const double contusionOvernightRecoveryPenalty = 0.08;

  final String reportId;
  final String stageId;
  final String stageName;
  final DateTime generatedAt;
  final int doctorSkillLevel;
  final List<RiderTraumaCaseReport> cases;

  const MedicalPostRaceTraumaReport({
    required this.reportId,
    required this.stageId,
    required this.stageName,
    required this.generatedAt,
    required this.doctorSkillLevel,
    required this.cases,
  });

  int get totalCasesCount => cases.length;

  int get dnfCount => cases
      .where((c) =>
          c.clearanceDecision == RaceClearanceDecision.medicalWithdrawalDnf)
      .length;

  int get dnsCount => cases
      .where((c) =>
          c.clearanceDecision == RaceClearanceDecision.medicalExclusionDns)
      .length;

  int get roadRashCount => cases
      .where((c) =>
          c.diagnosisCategory == TraumaDiagnosisCategory.roadRashAbrasion)
      .length;

  int get contusionCount => cases
      .where((c) =>
          c.diagnosisCategory == TraumaDiagnosisCategory.contusionBruising)
      .length;

  int get fractureCount =>
      cases.where((c) => c.hasConfirmedFracture).length;

  int get totalImagingCostEur =>
      cases.fold<int>(0, (sum, c) => sum + c.totalImagingCostEur);

  List<String> get excludedRiderIds =>
      cases.where((c) => c.isExcludedFromRace).map((c) => c.riderId).toList();

  Map<String, double> get recoveryPenaltyByRiderId => {
        for (final item in cases)
          item.riderId: item.overnightRecoveryPenaltyRatio,
      };

  /// Generuje kompletny raport medyczny RTG/MRI na podstawie incydentów etapu.
  factory MedicalPostRaceTraumaReport.generateFromIncidents({
    required RaceStage stage,
    required List<RaceIncidentEvent> incidents,
    Map<String, Rider> ridersById = const {},
    int doctorsLevel = 75,
    String? teamIdFilter,
    math.Random? random,
    DateTime? now,
  }) {
    final rng = random ?? math.Random();
    final timestamp = now ?? DateTime.now();
    final clampedDoctor = doctorsLevel.clamp(1, 100);
    final casesByRiderId = <String, RiderTraumaCaseReport>{};

    for (final incident in incidents) {
      for (final victim in incident.primaryVictims) {
        if (teamIdFilter != null && victim.teamId != teamIdFilter) {
          continue;
        }
        final bool isCrash = incident.type == IncidentType.soloCrash ||
            incident.type == IncidentType.pelotonPileup;
        if (!isCrash && victim.injury == null && !victim.isDnf) {
          continue;
        }

        final caseReport = _evaluateVictimCase(
          victim: victim,
          kilometerMark: incident.kilometerMark,
          rider: ridersById[victim.riderId],
          doctorsLevel: clampedDoctor,
          rng: rng,
        );

        final existing = casesByRiderId[victim.riderId];
        if (existing == null ||
            caseReport.diagnosisCategory.severityRank >
                existing.diagnosisCategory.severityRank) {
          casesByRiderId[victim.riderId] = caseReport;
        }
      }
    }

    final sortedCases = casesByRiderId.values.toList()
      ..sort((a, b) => b.diagnosisCategory.severityRank
          .compareTo(a.diagnosisCategory.severityRank));

    return MedicalPostRaceTraumaReport(
      reportId:
          'med_trauma_${stage.id}_${timestamp.millisecondsSinceEpoch}',
      stageId: stage.id,
      stageName: stage.name,
      generatedAt: timestamp,
      doctorSkillLevel: clampedDoctor,
      cases: sortedCases,
    );
  }

  /// Zwraca zaktualizowany stan [RiderHealth] po wpisaniu diagnozy z raportu.
  static RiderHealth applyCaseToRiderHealth({
    required RiderHealth currentHealth,
    required RiderTraumaCaseReport traumaCase,
  }) {
    if (traumaCase.assignedInjury == null) {
      return currentHealth;
    }
    final current = currentHealth.currentInjury;
    if (current != null &&
        current.daysRemaining > traumaCase.assignedInjury!.daysRemaining &&
        !current.trainingAllowed &&
        traumaCase.assignedInjury!.trainingAllowed) {
      return currentHealth;
    }
    return currentHealth.copyWith(currentInjury: traumaCase.assignedInjury);
  }

  static RiderTraumaCaseReport _evaluateVictimCase({
    required IncidentVictim victim,
    required double kilometerMark,
    required Rider? rider,
    required int doctorsLevel,
    required math.Random rng,
  }) {
    final injury = victim.injury;

    if (injury != null) {
      switch (injury.type) {
        case InjuryType.clavicleFracture:
          return _buildClavicleFractureCase(
            victim: victim,
            kilometerMark: kilometerMark,
            injury: injury,
            rng: rng,
          );
        case InjuryType.wristFracture:
          return _buildWristFractureCase(
            victim: victim,
            kilometerMark: kilometerMark,
            injury: injury,
            rng: rng,
          );
        case InjuryType.roadRash:
          return _buildRoadRashCase(
            victim: victim,
            kilometerMark: kilometerMark,
            injury: injury,
            doctorsLevel: doctorsLevel,
            rng: rng,
          );
        case InjuryType.concussion:
          return _buildConcussionCase(
            victim: victim,
            kilometerMark: kilometerMark,
            injury: injury,
          );
        case InjuryType.kneeTendinitis:
          return _buildKneeTraumaCase(
            victim: victim,
            kilometerMark: kilometerMark,
            injury: injury,
          );
        case InjuryType.muscleTear:
          return _buildMuscleTearCase(
            victim: victim,
            kilometerMark: kilometerMark,
            injury: injury,
          );
      }
    }

    // Kraksa bez zadeklarowanego urazu w zdarzeniu -> weryfikacja RTG i stłuczeń.
    final bool hasContusion = victim.timeLostSeconds >= 20.0 ||
        victim.incidentType == IncidentType.pelotonPileup ||
        rng.nextDouble() < 0.72;

    if (hasContusion) {
      return _buildContusionCase(
        victim: victim,
        kilometerMark: kilometerMark,
        rider: rider,
        doctorsLevel: doctorsLevel,
        rng: rng,
      );
    }

    return RiderTraumaCaseReport(
      riderId: victim.riderId,
      riderName: victim.riderName,
      teamId: victim.teamId,
      incidentType: victim.incidentType,
      kilometerMark: kilometerMark,
      diagnosisCategory: TraumaDiagnosisCategory.clearedNoStructuralTrauma,
      imagingResults: const [
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.clinicalInspection,
          anatomicalRegionPl: 'Ocena ogólnoustrojowa i kończyny',
          findingsPl:
              'Brak obrzęku stawowego, pełny zakres ruchu, brak wskazań do RTG/MRI.',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: false,
          performedAtHospital: false,
          costEur: 0,
        ),
      ],
      clearanceDecision: RaceClearanceDecision.fitToContinue,
      overnightRecoveryPenaltyRatio: 0.0,
      recommendedRecoveryDays: 0,
      assignedInjury: null,
      recommendedProtocols: const [
        RecoveryProtocolType.activeCoolDownRollers,
        RecoveryProtocolType.pneumaticCompressionBoots,
      ],
      medicalSummaryPl:
          '${victim.riderName} przeszedł kontrolę w autobusie po upadku na ${kilometerMark.toStringAsFixed(1)} km — brak urazów.',
      doctorNotesPl: 'Kolarz w pełni zdolny do startu w kolejnym etapie.',
    );
  }

  static RiderTraumaCaseReport _buildClavicleFractureCase({
    required IncidentVictim victim,
    required double kilometerMark,
    required Injury injury,
    required math.Random rng,
  }) {
    final String side = rng.nextBool() ? 'lewy' : 'prawy';
    final RaceClearanceDecision decision = victim.isDnf
        ? RaceClearanceDecision.medicalWithdrawalDnf
        : RaceClearanceDecision.medicalExclusionDns;

    return RiderTraumaCaseReport(
      riderId: victim.riderId,
      riderName: victim.riderName,
      teamId: victim.teamId,
      incidentType: victim.incidentType,
      kilometerMark: kilometerMark,
      diagnosisCategory: TraumaDiagnosisCategory.clavicleFracture,
      imagingResults: [
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.xRay,
          anatomicalRegionPl: 'Obojczyk $side i staw barkowo-obojczykowy',
          findingsPl:
              'RTG potwierdziło złamanie trzonu obojczyka (${side}ego) z przemieszczeniem odłamów.',
          isFractureConfirmed: true,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: true,
          costEur: 320,
        ),
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.mri,
          anatomicalRegionPl: 'Stożek rotatorów i więzadła barku ($side)',
          findingsPl:
              'MRI przedoperacyjne: brak uszkodzenia splotu ramiennego, obrzęk tkanek miękkich.',
          isFractureConfirmed: true,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: true,
          costEur: 580,
        ),
      ],
      clearanceDecision: decision,
      overnightRecoveryPenaltyRatio: 0.45,
      recommendedRecoveryDays: injury.daysRemaining,
      assignedInjury: injury,
      recommendedProtocols: const [
        RecoveryProtocolType.hyperbaricOxygenTherapy,
      ],
      medicalSummaryPl:
          'ALARM MEDYCZNY (${decision.statusCode}): ${victim.riderName} — złamanie obojczyka potwierdzone w RTG/MRI. Wykluczony z dalszej jazdy.',
      doctorNotesPl:
          'Konieczna stabilizacja chirurgiczna (płytka tytanowa) i bezwzględny odpoczynek przez ${injury.daysRemaining} dni.',
    );
  }

  static RiderTraumaCaseReport _buildWristFractureCase({
    required IncidentVictim victim,
    required double kilometerMark,
    required Injury injury,
    required math.Random rng,
  }) {
    final String side = rng.nextBool() ? 'prawy' : 'lewy';
    final RaceClearanceDecision decision = victim.isDnf
        ? RaceClearanceDecision.medicalWithdrawalDnf
        : RaceClearanceDecision.medicalExclusionDns;

    return RiderTraumaCaseReport(
      riderId: victim.riderId,
      riderName: victim.riderName,
      teamId: victim.teamId,
      incidentType: victim.incidentType,
      kilometerMark: kilometerMark,
      diagnosisCategory: TraumaDiagnosisCategory.wristFracture,
      imagingResults: [
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.xRay,
          anatomicalRegionPl: 'Nadgarstek $side i kość promieniowa',
          findingsPl:
              'RTG wykazało szczelinę złamania w obrębie kości łódeczkowatej nadgarstka.',
          isFractureConfirmed: true,
          isSoftTissueDamageConfirmed: false,
          performedAtHospital: true,
          costEur: 290,
        ),
        const DiagnosticImagingResult(
          modality: DiagnosticImagingModality.mri,
          anatomicalRegionPl: 'Chrząstka trójkątna i więzadła nadgarstka',
          findingsPl:
              'MRI potwierdziło niestabilność złamania uniemożliwiającą chwyt kierownicy.',
          isFractureConfirmed: true,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: true,
          costEur: 560,
        ),
      ],
      clearanceDecision: decision,
      overnightRecoveryPenaltyRatio: 0.40,
      recommendedRecoveryDays: injury.daysRemaining,
      assignedInjury: injury,
      recommendedProtocols: const [
        RecoveryProtocolType.hyperbaricOxygenTherapy,
      ],
      medicalSummaryPl:
          'WYKLUCZENIE (${decision.statusCode}): ${victim.riderName} — złamanie nadgarstka potwierdzone w RTG i MRI. Brak zgody na start.',
      doctorNotesPl:
          'Unieruchomienie ortopedyczne na ${injury.daysRemaining} dni; możliwy powrót na trenażer po konsultacji ortopedycznej.',
    );
  }

  static RiderTraumaCaseReport _buildRoadRashCase({
    required IncidentVictim victim,
    required double kilometerMark,
    required Injury injury,
    required int doctorsLevel,
    required math.Random rng,
  }) {
    final String area = rng.nextBool()
        ? 'lewe biodro, udo zewnętrzne i przedramię'
        : 'prawe udo, pośladek i łopatka';

    return RiderTraumaCaseReport(
      riderId: victim.riderId,
      riderName: victim.riderName,
      teamId: victim.teamId,
      incidentType: victim.incidentType,
      kilometerMark: kilometerMark,
      diagnosisCategory: TraumaDiagnosisCategory.roadRashAbrasion,
      imagingResults: [
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.clinicalInspection,
          anatomicalRegionPl: 'Powłoki skórne ($area)',
          findingsPl:
              'Głębokie otarcia naskórka ("road rash") po kontakcie z asfaltem; oczyszczono z żwiru, założono opatrunki hydrokoloidowe.',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: false,
          costEur: 95,
        ),
        const DiagnosticImagingResult(
          modality: DiagnosticImagingModality.xRay,
          anatomicalRegionPl: 'Staw biodrowy i barkowy (wykluczenie pęknięć)',
          findingsPl:
              'RTG mobilne w strefie mety: brak zmian pourazowych kośćca.',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: false,
          performedAtHospital: false,
          costEur: 180,
        ),
      ],
      clearanceDecision: RaceClearanceDecision.fitWithPainAndPenalty,
      overnightRecoveryPenaltyRatio: roadRashOvernightRecoveryPenalty,
      recommendedRecoveryDays: injury.daysRemaining,
      assignedInjury: injury,
      recommendedProtocols: const [
        RecoveryProtocolType.hydrocolloidRoadRashCare,
        RecoveryProtocolType.hyperbaricOxygenTherapy,
      ],
      medicalSummaryPl:
          'SZLIFY NASKÓRKA (${victim.riderName}): brak złamań w RTG, ale rozległe "road rash" obniżają regenerację w nocy o 25%.',
      doctorNotesPl:
          'Poziom lekarzy ($doctorsLevel/100): wdrożono opatrunki hydrokoloidowe i nocne monitorowanie stanu zapalnego.',
    );
  }

  static RiderTraumaCaseReport _buildConcussionCase({
    required IncidentVictim victim,
    required double kilometerMark,
    required Injury injury,
  }) {
    final RaceClearanceDecision decision = victim.isDnf
        ? RaceClearanceDecision.medicalWithdrawalDnf
        : RaceClearanceDecision.medicalExclusionDns;

    return RiderTraumaCaseReport(
      riderId: victim.riderId,
      riderName: victim.riderName,
      teamId: victim.teamId,
      incidentType: victim.incidentType,
      kilometerMark: kilometerMark,
      diagnosisCategory: TraumaDiagnosisCategory.concussion,
      imagingResults: const [
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.concussionScat6,
          anatomicalRegionPl: 'Układ nerwowy i równowaga (SCAT-6)',
          findingsPl:
              'Dodatni test SCAT-6 po uderzeniu kaskiem o asfalt (zaburzenia równowagi i światłowstręt).',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: false,
          costEur: 120,
        ),
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.mri,
          anatomicalRegionPl: 'Mózgowie i odcinek szyjny kręgosłupa',
          findingsPl:
              'MRI wykluczyło krwawienie śródczaszkowe; wymagany protokół wstrząśnieniowy UCI.',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: true,
          costEur: 640,
        ),
      ],
      clearanceDecision: decision,
      overnightRecoveryPenaltyRatio: 0.40,
      recommendedRecoveryDays: injury.daysRemaining,
      assignedInjury: injury,
      recommendedProtocols: const [],
      medicalSummaryPl:
          'PROTOKÓŁ WSTRZĄŚNIENIOWY (${decision.statusCode}): ${victim.riderName} wycofany z wyścigu zgodnie z przepisami UCI.',
      doctorNotesPl:
          'Zakaz wysiłku fizycznego i ekspozycji na ekrany przez minimum ${injury.daysRemaining} dni.',
    );
  }

  static RiderTraumaCaseReport _buildKneeTraumaCase({
    required IncidentVictim victim,
    required double kilometerMark,
    required Injury injury,
  }) {
    final bool excluded = victim.isDnf || !injury.trainingAllowed;
    final RaceClearanceDecision decision = victim.isDnf
        ? RaceClearanceDecision.medicalWithdrawalDnf
        : (excluded
            ? RaceClearanceDecision.medicalExclusionDns
            : RaceClearanceDecision.fitWithPainAndPenalty);

    return RiderTraumaCaseReport(
      riderId: victim.riderId,
      riderName: victim.riderName,
      teamId: victim.teamId,
      incidentType: victim.incidentType,
      kilometerMark: kilometerMark,
      diagnosisCategory: TraumaDiagnosisCategory.kneeTendinitisOrLigament,
      imagingResults: const [
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.xRay,
          anatomicalRegionPl: 'Staw kolanowy i rzepka',
          findingsPl:
              'RTG: kość rzepki i kłykcie kości udowej bez linii złamania.',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: false,
          performedAtHospital: true,
          costEur: 240,
        ),
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.mri,
          anatomicalRegionPl: 'Więzadło rzepki i łąkotka przyśrodkowa',
          findingsPl:
              'MRI wykazało stan zapalny i naciągnięcie troczków rzepki po uderzeniu o kierownicę.',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: true,
          costEur: 550,
        ),
      ],
      clearanceDecision: decision,
      overnightRecoveryPenaltyRatio: excluded ? 0.30 : 0.15,
      recommendedRecoveryDays: injury.daysRemaining,
      assignedInjury: injury,
      recommendedProtocols: const [
        RecoveryProtocolType.wholeBodyCryotherapy,
        RecoveryProtocolType.physiotherapyManualTherapy,
      ],
      medicalSummaryPl:
          'URAZ KOLANA (${decision.statusCode}): ${victim.riderName} — MRI wykazało przeciążenie/naciągnięcie aparatu więzadłowego.',
      doctorNotesPl:
          'Krioterapia miejscowa i terapia manualna fizjoterapeuty; kontrola bólu podczas pedałowania.',
    );
  }

  static RiderTraumaCaseReport _buildMuscleTearCase({
    required IncidentVictim victim,
    required double kilometerMark,
    required Injury injury,
  }) {
    final RaceClearanceDecision decision = victim.isDnf
        ? RaceClearanceDecision.medicalWithdrawalDnf
        : RaceClearanceDecision.medicalExclusionDns;

    return RiderTraumaCaseReport(
      riderId: victim.riderId,
      riderName: victim.riderName,
      teamId: victim.teamId,
      incidentType: victim.incidentType,
      kilometerMark: kilometerMark,
      diagnosisCategory: TraumaDiagnosisCategory.muscleTear,
      imagingResults: const [
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.ultrasound,
          anatomicalRegionPl: 'Mięsień czworogłowy / dwugłowy uda',
          findingsPl:
              'USG wykazało krwiak śródmięśniowy i przerwanie ciągłości części włókien.',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: true,
          costEur: 190,
        ),
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.mri,
          anatomicalRegionPl: 'Udo — ocena stopnia naderwania',
          findingsPl:
              'MRI potwierdziło naderwanie mięśnia II stopnia — kontynuacja wyścigu grozi zerwaniem.',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: true,
          costEur: 540,
        ),
      ],
      clearanceDecision: decision,
      overnightRecoveryPenaltyRatio: 0.35,
      recommendedRecoveryDays: injury.daysRemaining,
      assignedInjury: injury,
      recommendedProtocols: const [
        RecoveryProtocolType.hyperbaricOxygenTherapy,
        RecoveryProtocolType.physiotherapyManualTherapy,
      ],
      medicalSummaryPl:
          'NADERWANIE MIĘŚNIA (${decision.statusCode}): ${victim.riderName} wykluczony po badaniu USG/MRI.',
      doctorNotesPl:
          'Zalecana przerwa ${injury.daysRemaining} dni oraz rehabilitacja w komorze HBOT.',
    );
  }

  static RiderTraumaCaseReport _buildContusionCase({
    required IncidentVictim victim,
    required double kilometerMark,
    required Rider? rider,
    required int doctorsLevel,
    required math.Random rng,
  }) {
    final String region = rng.nextBool()
        ? 'biodro, mięsień czworogłowy i okolica żeber'
        : 'bark, łokieć i mięśnie przykręgosłupowe';
    final bool needsMriCheck = victim.timeLostSeconds >= 45.0;
    final imaging = <DiagnosticImagingResult>[
      DiagnosticImagingResult(
        modality: DiagnosticImagingModality.xRay,
        anatomicalRegionPl: region,
        findingsPl:
            'RTG po etapie wykluczyło złamania kości; widoczny obrzęk pourazowy tkanek miękkich.',
        isFractureConfirmed: false,
        isSoftTissueDamageConfirmed: true,
        performedAtHospital: needsMriCheck,
        costEur: 220,
      ),
      if (needsMriCheck)
        DiagnosticImagingResult(
          modality: DiagnosticImagingModality.mri,
          anatomicalRegionPl: region,
          findingsPl:
              'MRI potwierdziło głębokie stłuczenie i krwiak śródtkankowy bez zerwań więzadeł.',
          isFractureConfirmed: false,
          isSoftTissueDamageConfirmed: true,
          performedAtHospital: true,
          costEur: 490,
        ),
    ];

    final riderAgeNote = rider != null ? ' (wiek ${rider.age} l.)' : '';

    return RiderTraumaCaseReport(
      riderId: victim.riderId,
      riderName: victim.riderName,
      teamId: victim.teamId,
      incidentType: victim.incidentType,
      kilometerMark: kilometerMark,
      diagnosisCategory: TraumaDiagnosisCategory.contusionBruising,
      imagingResults: imaging,
      clearanceDecision: RaceClearanceDecision.fitWithPainAndPenalty,
      overnightRecoveryPenaltyRatio: contusionOvernightRecoveryPenalty,
      recommendedRecoveryDays: 2,
      assignedInjury: null,
      recommendedProtocols: const [
        RecoveryProtocolType.wholeBodyCryotherapy,
        RecoveryProtocolType.physiotherapyManualTherapy,
      ],
      medicalSummaryPl:
          'STŁUCZENIA (${victim.riderName}$riderAgeNote): RTG${needsMriCheck ? '/MRI' : ''} bez złamań — warunkowo dopuszczony.',
      doctorNotesPl:
          'Sztab medyczny ($doctorsLevel/100) zaleca krioterapię (-110°C) i masaż drenażowy przed kolejnym etapem.',
    );
  }

  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'stageId': stageId,
        'stageName': stageName,
        'generatedAt': generatedAt.toIso8601String(),
        'doctorSkillLevel': doctorSkillLevel,
        'cases': cases.map((c) => c.toJson()).toList(),
      };

  factory MedicalPostRaceTraumaReport.fromJson(Map<String, dynamic> json) {
    return MedicalPostRaceTraumaReport(
      reportId: json['reportId'] as String,
      stageId: json['stageId'] as String,
      stageName: json['stageName'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      doctorSkillLevel: (json['doctorSkillLevel'] as num).toInt(),
      cases: (json['cases'] as List<dynamic>)
          .map((e) =>
              RiderTraumaCaseReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
