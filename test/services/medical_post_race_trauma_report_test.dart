import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/race_incident_engine.dart';
import 'package:pro_peloton_manager/models/career/recovery_protocol_system.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/services/career/medical_post_race_trauma_report.dart';

RaceStage _buildTestStage() {
  return const RaceStage(
    id: 'stage_tdf_05',
    stageNumber: 5,
    name: 'Etap 5: Pau – Laruns',
    stageType: StageType.highMountain,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 20.0,
        startElevationM: 200.0,
        endElevationM: 500.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 25.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
    ],
    baseTemperatureCelsius: 24.0,
    weatherCondition: WeatherCondition.lightRain,
    windSpeedKmh: 14.0,
  );
}

void main() {
  group('MedicalPostRaceTraumaReport', () {
    test('diagnozuje złamanie obojczyka i nadgarstka jako DNF/DNS z RTG/MRI', () {
      final stage = _buildTestStage();
      const clavicleVictim = IncidentVictim(
        riderId: 'r_1',
        riderName: 'Jan Kowalski',
        teamId: 'team_a',
        incidentType: IncidentType.pelotonPileup,
        timeLostSeconds: 0.0,
        injury: Injury(
          name: 'Złamanie obojczyka',
          type: InjuryType.clavicleFracture,
          daysRemaining: 28,
          trainingAllowed: false,
        ),
        isDnf: true,
        assistanceMethod: AssistanceMethod.teamCarService,
        description: 'Poważny upadek na zjeździe',
      );
      const wristVictim = IncidentVictim(
        riderId: 'r_2',
        riderName: 'Piotr Nowak',
        teamId: 'team_a',
        incidentType: IncidentType.soloCrash,
        timeLostSeconds: 65.0,
        injury: Injury(
          name: 'Złamanie nadgarstka',
          type: InjuryType.wristFracture,
          daysRemaining: 21,
          trainingAllowed: true,
        ),
        isDnf: false,
        assistanceMethod: AssistanceMethod.neutralService,
        description: 'Ukończył etap z bólem nadgarstka',
      );

      final report = MedicalPostRaceTraumaReport.generateFromIncidents(
        stage: stage,
        incidents: const [
          RaceIncidentEvent(
            id: 'inc_1',
            kilometerMark: 112.4,
            type: IncidentType.pelotonPileup,
            primaryVictims: [clavicleVictim, wristVictim],
            heldUpRiderIds: [],
            isRoadBlocked: false,
            radioReport: 'Kraksa w peletonie!',
          ),
        ],
        random: math.Random(42),
      );

      expect(report.totalCasesCount, 2);
      expect(report.fractureCount, 2);
      expect(report.dnfCount, 1);
      expect(report.dnsCount, 1);
      expect(report.excludedRiderIds, containsAll(['r_1', 'r_2']));

      final clavicleCase = report.cases.firstWhere((c) => c.riderId == 'r_1');
      expect(clavicleCase.statusCode, 'DNF');
      expect(clavicleCase.isExcludedFromRace, isTrue);
      expect(clavicleCase.hasConfirmedFracture, isTrue);
      expect(
        clavicleCase.imagingResults.map((r) => r.modality),
        containsAll([
          DiagnosticImagingModality.xRay,
          DiagnosticImagingModality.mri,
        ]),
      );

      final wristCase = report.cases.firstWhere((c) => c.riderId == 'r_2');
      expect(wristCase.statusCode, 'DNS');
      expect(wristCase.isExcludedFromRace, isTrue);
      expect(wristCase.hasConfirmedFracture, isTrue);
    });

    test('szlify road rash obniżają regenerację w nocy dokładnie o 25%', () {
      final stage = _buildTestStage();
      const roadRashVictim = IncidentVictim(
        riderId: 'r_3',
        riderName: 'Adam Zieliński',
        teamId: 'team_a',
        incidentType: IncidentType.soloCrash,
        timeLostSeconds: 32.0,
        injury: Injury(
          name: 'Rozległe szlify naskórka',
          type: InjuryType.roadRash,
          daysRemaining: 4,
          trainingAllowed: true,
        ),
        isDnf: false,
        assistanceMethod: AssistanceMethod.selfRemount,
        description: 'Szlif na mokrym zakręcie',
      );

      final report = MedicalPostRaceTraumaReport.generateFromIncidents(
        stage: stage,
        incidents: const [
          RaceIncidentEvent(
            id: 'inc_rr',
            kilometerMark: 74.0,
            type: IncidentType.soloCrash,
            primaryVictims: [roadRashVictim],
            heldUpRiderIds: [],
            isRoadBlocked: false,
            radioReport: 'Poślizg na rondzie',
          ),
        ],
        random: math.Random(7),
      );

      expect(report.roadRashCount, 1);
      final rrCase = report.cases.single;
      expect(rrCase.diagnosisCategory, TraumaDiagnosisCategory.roadRashAbrasion);
      expect(rrCase.overnightRecoveryPenaltyRatio, closeTo(0.25, 1e-9));
      expect(report.recoveryPenaltyByRiderId['r_3'], closeTo(0.25, 1e-9));
      expect(rrCase.isExcludedFromRace, isFalse);
      expect(
        rrCase.recommendedProtocols,
        contains(RecoveryProtocolType.hydrocolloidRoadRashCare),
      );
    });

    test('rozpoznaje stłuczenia po kraksie bez złamań oraz ignoruje zwykłe defekty', () {
      final stage = _buildTestStage();
      const contusionVictim = IncidentVictim(
        riderId: 'r_4',
        riderName: 'Marek Wiśniewski',
        teamId: 'team_a',
        incidentType: IncidentType.pelotonPileup,
        timeLostSeconds: 50.0,
        injury: null,
        isDnf: false,
        assistanceMethod: AssistanceMethod.teamCarService,
        description: 'Upadek w peletonie',
      );
      const flatTireVictim = IncidentVictim(
        riderId: 'r_5',
        riderName: 'Kamil Lis',
        teamId: 'team_a',
        incidentType: IncidentType.punctureFlatTire,
        timeLostSeconds: 25.0,
        injury: null,
        isDnf: false,
        assistanceMethod: AssistanceMethod.neutralService,
        description: 'Przebicie tylnej opony',
      );

      final report = MedicalPostRaceTraumaReport.generateFromIncidents(
        stage: stage,
        incidents: const [
          RaceIncidentEvent(
            id: 'inc_c',
            kilometerMark: 138.0,
            type: IncidentType.pelotonPileup,
            primaryVictims: [contusionVictim],
            heldUpRiderIds: [],
            isRoadBlocked: false,
            radioReport: 'Kraksa!',
          ),
          RaceIncidentEvent(
            id: 'inc_f',
            kilometerMark: 145.0,
            type: IncidentType.punctureFlatTire,
            primaryVictims: [flatTireVictim],
            heldUpRiderIds: [],
            isRoadBlocked: false,
            radioReport: 'Defekt opony',
          ),
        ],
        random: math.Random(1),
      );

      expect(report.totalCasesCount, 1);
      expect(report.contusionCount, 1);
      final contusionCase = report.cases.single;
      expect(contusionCase.riderId, 'r_4');
      expect(contusionCase.hasConfirmedFracture, isFalse);
      expect(contusionCase.isExcludedFromRace, isFalse);
      expect(
        contusionCase.imagingResults.map((e) => e.modality),
        containsAll([
          DiagnosticImagingModality.xRay,
          DiagnosticImagingModality.mri,
        ]),
      );
    });

    test('serializacja JSON zachowuje pełny raport medyczny i aktualizuje RiderHealth', () {
      final stage = _buildTestStage();
      const victim = IncidentVictim(
        riderId: 'r_6',
        riderName: 'Tomasz Kaczmarek',
        teamId: 'team_b',
        incidentType: IncidentType.soloCrash,
        timeLostSeconds: 18.0,
        injury: Injury(
          name: 'Szlif kolana i biodra',
          type: InjuryType.roadRash,
          daysRemaining: 5,
          trainingAllowed: true,
        ),
        isDnf: false,
        assistanceMethod: AssistanceMethod.selfRemount,
        description: 'Upadek na mokrym bruku',
      );

      final original = MedicalPostRaceTraumaReport.generateFromIncidents(
        stage: stage,
        incidents: const [
          RaceIncidentEvent(
            id: 'inc_json',
            kilometerMark: 90.0,
            type: IncidentType.soloCrash,
            primaryVictims: [victim],
            heldUpRiderIds: [],
            isRoadBlocked: false,
            radioReport: 'Upadek!',
          ),
        ],
        now: DateTime.utc(2026, 7, 8, 17, 30),
        random: math.Random(9),
      );

      final decoded = MedicalPostRaceTraumaReport.fromJson(original.toJson());
      expect(decoded.reportId, original.reportId);
      expect(decoded.stageId, original.stageId);
      expect(decoded.totalCasesCount, 1);
      expect(decoded.cases.single.overnightRecoveryPenaltyRatio, 0.25);
      expect(decoded.totalImagingCostEur, original.totalImagingCostEur);

      const baseHealth = RiderHealth(
        acuteTrainingLoad: 95.0,
        chronicTrainingLoad: 110.0,
      );
      final updatedHealth = MedicalPostRaceTraumaReport.applyCaseToRiderHealth(
        currentHealth: baseHealth,
        traumaCase: decoded.cases.single,
      );
      expect(updatedHealth.currentInjury?.type, InjuryType.roadRash);
      expect(updatedHealth.currentInjury?.daysRemaining, 5);
    });
  });
}
