// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/constants/physics_constants.dart';
import 'package:pro_peloton_manager/engine/peloton/grupetto_autobus_survival_ai.dart';
import 'package:pro_peloton_manager/engine/physics/wet_cornering_grip_and_braking_solver.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

RaceStage _buildHighMountainStage() {
  return const RaceStage(
    id: 'stage_alpe_test',
    stageNumber: 14,
    name: 'Saint-Jean-de-Maurienne — Alpe d\'Huez',
    stageType: StageType.highMountain,
    baseTemperatureCelsius: 22.0,
    weatherCondition: WeatherCondition.overcast,
    windSpeedKmh: 12.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 30.0,
        startElevationM: 540.0,
        endElevationM: 720.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 18.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 30.0,
        lengthKm: 20.0,
        startElevationM: 720.0,
        endElevationM: 2000.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 45.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
      StageSegment(
        index: 2,
        startKm: 50.0,
        lengthKm: 25.0,
        startElevationM: 2000.0,
        endElevationM: 800.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 68.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 3,
        startKm: 75.0,
        lengthKm: 55.0,
        startElevationM: 800.0,
        endElevationM: 720.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 22.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      StageSegment(
        index: 4,
        startKm: 130.0,
        lengthKm: 20.0,
        startElevationM: 720.0,
        endElevationM: 1860.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 55.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ],
  );
}

List<GrupettoRiderProfile> _buildAutobusRiderPool({int count = 42}) {
  final List<GrupettoRiderProfile> pool = <GrupettoRiderProfile>[];
  for (int i = 0; i < count; i++) {
    final GrupettoRiderArchetype archetype;
    if (i < 16) {
      archetype = GrupettoRiderArchetype.sprinter;
    } else if (i < 26) {
      archetype = GrupettoRiderArchetype.heavyClassics;
    } else {
      archetype = GrupettoRiderArchetype.domestique;
    }

    final bool isVeteranCaptainCandidate = i == 26;
    pool.add(
      GrupettoRiderProfile(
        riderId: 'rider_$i',
        riderName: isVeteranCaptainCandidate ? 'Capt. Veteranski' : 'Rider $i',
        teamId: 'team_${i % 10}',
        archetype: archetype,
        ageYears: isVeteranCaptainCandidate ? 35 : 24 + (i % 9),
        experienceYears: isVeteranCaptainCandidate ? 15 : 3 + (i % 8),
        raceIq: isVeteranCaptainCandidate ? 94 : 65 + (i % 20),
        mountainSkill: archetype == GrupettoRiderArchetype.sprinter ? 48 : 62,
        flatSkill: archetype == GrupettoRiderArchetype.sprinter ? 78 : 82,
        weightKg: archetype == GrupettoRiderArchetype.sprinter ? 79.0 : 73.0,
        ftpWatts: archetype == GrupettoRiderArchetype.sprinter ? 385 : 405,
        fatigueRatio: 0.30 + (i % 5) * 0.05,
        isDroppedFromPeloton: true,
        isPlayerTeam: i == 0 || i == 27,
        isDnf: false,
      ),
    );
  }
  return pool;
}

void main() {
  group('WetCorneringGripAndBrakingSolver — redukcja prędkości w mokrych zakrętach', () {
    test('bazowy współczynnik tarcia spada zgodnie z fizyką na mokrym asfalcie i bruku', () {
      final double dryAsphaltMu =
          WetCorneringGripAndBrakingSolver.calculateBaseSurfaceFriction(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        surfaceWetness: 0.0,
      );
      final double wetAsphaltMu =
          WetCorneringGripAndBrakingSolver.calculateBaseSurfaceFriction(
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        surfaceWetness: 1.0,
      );
      final double dryCobbleMu =
          WetCorneringGripAndBrakingSolver.calculateBaseSurfaceFriction(
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        surfaceWetness: 0.0,
      );
      final double wetCobbleMu =
          WetCorneringGripAndBrakingSolver.calculateBaseSurfaceFriction(
        surfaceType: SegmentSurfaceType.cobblestonesSector3,
        surfaceWetness: 1.0,
      );

      expect(dryAsphaltMu, closeTo(0.85, 1e-6));
      expect(wetAsphaltMu, closeTo(0.55, 1e-6));
      expect(dryCobbleMu, closeTo(0.68, 1e-6));
      expect(wetCobbleMu, closeTo(0.40, 1e-6));
      expect(wetAsphaltMu, lessThan(dryAsphaltMu));
      expect(wetCobbleMu, lessThan(wetAsphaltMu));
    });

    test('maksymalna prędkość w zakręcie v_max = sqrt(mu * g * R) wyraźnie spada na mokrej nawierzchni', () {
      const double radiusM = 25.0;
      const double entrySpeedMs = 13.0; // 46.8 km/h

      final WetCorneringResult dryResult = WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: radiusM,
          currentSpeedMs: entrySpeedMs,
          distanceToCornerMeters: 60.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          surfaceWetness: 0.0,
          tirePressureBar: 5.5,
          descendingSkill: 85,
          bikeHandlingSkill: 85,
        ),
      );

      final WetCorneringResult wetResult = WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: radiusM,
          currentSpeedMs: entrySpeedMs,
          distanceToCornerMeters: 60.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          surfaceWetness: 1.0,
          tirePressureBar: 5.5,
          descendingSkill: 85,
          bikeHandlingSkill: 85,
        ),
      );

      final WetCorneringResult wetCobbleResult =
          WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: radiusM,
          currentSpeedMs: entrySpeedMs,
          distanceToCornerMeters: 60.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector3,
          surfaceWetness: 1.0,
          tirePressureBar: 5.5,
          descendingSkill: 85,
          bikeHandlingSkill: 85,
        ),
      );

      expect(
        wetResult.effectiveFrictionMu,
        lessThan(dryResult.effectiveFrictionMu),
      );
      expect(
        wetResult.maxCorneringSpeedMs,
        lessThan(dryResult.maxCorneringSpeedMs),
      );
      expect(
        wetResult.maxCorneringSpeedKmh,
        lessThan(dryResult.maxCorneringSpeedKmh),
      );
      expect(
        wetResult.targetEntrySpeedMs,
        lessThan(dryResult.targetEntrySpeedMs),
      );
      expect(
        wetCobbleResult.maxCorneringSpeedMs,
        lessThan(wetResult.maxCorneringSpeedMs),
      );

      // Weryfikacja bezpośredniej zgodności ze wzorem v_max = sqrt(mu * g * R)
      final double expectedDryVmax =
          WetCorneringGripAndBrakingSolver.calculateMaxCorneringSpeedMs(
        frictionMu: dryResult.effectiveFrictionMu,
        cornerRadiusMeters: radiusM,
      );
      final double expectedWetVmax =
          WetCorneringGripAndBrakingSolver.calculateMaxCorneringSpeedMs(
        frictionMu: wetResult.effectiveFrictionMu,
        cornerRadiusMeters: radiusM,
      );
      expect(dryResult.maxCorneringSpeedMs, closeTo(expectedDryVmax, 1e-6));
      expect(wetResult.maxCorneringSpeedMs, closeTo(expectedWetVmax, 1e-6));

      // Na tym samym ostrym zakręcie przy 54 km/h na sucho może być bezpiecznie,
      // a w ulewie wymagane jest hamowanie i rośnie wykorzystanie tarcia.
      expect(dryResult.needsBraking, isFalse);
      expect(wetResult.needsBraking, isTrue);
      expect(wetResult.brakingDistanceMeters, greaterThan(0.0));
      expect(wetCobbleResult.gripUtilization, greaterThan(dryResult.gripUtilization));
    });

    test('mieszanka deszczowa i niższe ciśnienie poprawiają przyczepność w ulewie względem twardej TT', () {
      const TireModel rainTire = TireModel(
        id: 'tire_wet_30',
        brandId: 'brand_a',
        name: 'All-Season Wet 30mm',
        widthMm: 30,
        weightGrams: 270,
        rollingResistanceCrr: 0.0042,
        punctureResistanceIndex: 4.5,
        wetGripIndex: 4.8,
        isTubeless: true,
        priceEur: 85,
      );

      final WetCorneringResult wetOptimized =
          WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: 22.0,
          currentSpeedMs: 14.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          surfaceWetness: 1.0,
          tirePressureBar: 4.8,
          tireModel: rainTire,
          tireCompound: TireCompoundType.allSeasonWet,
          brakeSystem: BrakeSystemType.hydraulicDisc,
        ),
      );

      final WetCorneringResult hardOverinflated =
          WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: 22.0,
          currentSpeedMs: 14.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          surfaceWetness: 1.0,
          tirePressureBar: 7.5,
          tireCompound: TireCompoundType.hardTimeTrial,
          brakeSystem: BrakeSystemType.carbonRim,
        ),
      );

      expect(
        wetOptimized.effectiveFrictionMu,
        greaterThan(hardOverinflated.effectiveFrictionMu),
      );
      expect(
        wetOptimized.maxCorneringSpeedKmh,
        greaterThan(hardOverinflated.maxCorneringSpeedKmh),
      );
      expect(
        wetOptimized.maxBrakingDecelerationMs2,
        greaterThan(hardOverinflated.maxBrakingDecelerationMs2),
      );
    });

    test('zbyt szybki najazd na mokry zakręt bez dystansu hamowania skutkuje criticalSlip i ryzykiem kraksy', () {
      final WetCorneringResult crashRisk = WetCorneringGripAndBrakingSolver.solve(
        const WetCorneringInput(
          cornerRadiusMeters: 15.0,
          currentSpeedMs: 18.0, // 64.8 km/h w ostry nawrót
          distanceToCornerMeters: 5.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          surfaceWetness: 1.0,
          roadGradientPercent: -10.0,
          brakeSystem: BrakeSystemType.carbonRim,
          descendingSkill: 60,
          bikeHandlingSkill: 60,
        ),
      );

      expect(crashRisk.needsBraking, isTrue);
      expect(crashRisk.canBrakeInTime, isFalse);
      expect(crashRisk.gripUtilization, greaterThan(1.0));
      expect(crashRisk.riskLevel, CorneringRiskLevel.criticalSlip);
      expect(crashRisk.slipProbability, greaterThan(0.0));
      expect(
        crashRisk.maxCorneringSpeedMs,
        lessThan(PhysicsConstants.gravity * 2.0),
      );
    });

    test('profilowany zakręt (banking > 0) zwiększa maksymalną prędkość pokonania zakrętu', () {
      final double flatCorner =
          WetCorneringGripAndBrakingSolver.calculateMaxCorneringSpeedMs(
        frictionMu: 0.55,
        cornerRadiusMeters: 30.0,
        roadCamberDegrees: 0.0,
      );
      final double bankedCorner =
          WetCorneringGripAndBrakingSolver.calculateMaxCorneringSpeedMs(
        frictionMu: 0.55,
        cornerRadiusMeters: 30.0,
        roadCamberDegrees: 8.0,
      );

      expect(bankedCorner, greaterThan(flatCorner));
    });
  });

  group('GrupettoAutobusSurvivalAi — formowanie Autobusu i dojazd przed limitem OTL', () {
    test('identyfikuje etap wysokogórski, pierwszą przełęcz i formuje 40-osobowe Grupetto z Kapitanem', () {
      final RaceStage stage = _buildHighMountainStage();
      final List<GrupettoRiderProfile> pool = _buildAutobusRiderPool(count: 45);

      expect(GrupettoAutobusSurvivalAi.isMountainAutobusStage(stage), isTrue);
      expect(
        GrupettoAutobusSurvivalAi.findFirstMajorClimbSegmentIndex(stage),
        1,
      );

      final GrupettoEvaluationResult result =
          GrupettoAutobusSurvivalAi.evaluateAutobus(
        GrupettoAutobusInput(
          stage: stage,
          elapsedStageTimeSeconds: 7200.0, // 2h jazdy
          leaderDistanceKm: 75.0,
          leaderCurrentSpeedKmh: 38.0,
          grupettoDistanceKm: 55.0,
          grupettoCurrentSpeedKmh: 32.0,
          riderPool: pool,
          targetGroupSize: GrupettoAutobusSurvivalAi.defaultTargetAutobusSize,
        ),
      );

      expect(result.formationState, GrupettoFormationState.activeAutobus);
      expect(result.groupSize, 40);
      expect(result.captain, isNotNull);
      expect(result.captain!.riderId, 'rider_26');
      expect(result.sprinterCount, 16);
      expect(result.heavyClassicsCount, 10);
      expect(result.domestiqueCount, 14);
      // Sprinterzy powinni być chronieni w drafcie, a pomocnicy/klasykowcy na czele
      expect(result.activePullerRiderIds, isNotEmpty);
      expect(result.protectedDraftRiderIds, contains('rider_0'));
      expect(result.pacePlan.draftPowerSavingsPercent, closeTo(33.0, 0.5));
    });

    test('Kapitan wylicza plan tempa OTL z 3-minutowym buforem i prowadzi Grupetto do mety przed limitem', () {
      final RaceStage stage = _buildHighMountainStage(); // 150 km
      final List<GrupettoRiderProfile> pool = _buildAutobusRiderPool(count: 40);

      // Symulacja pościgu od 55 km do mety (150 km) z tempem narzuconym przez Kapitana.
      double elapsedTimeSec = 6800.0;
      double grupettoDistKm = 55.0;
      double leaderDistKm = 72.0;
      const double leaderSpeedKmh = 36.0;
      const double stepSec = 60.0;

      late GrupettoEvaluationResult latestEval;
      double currentSpeedKmh = 28.0;

      // Iterujemy w krokach co 60 s aż Grupetto minie linię mety (150 km).
      int guardSteps = 0;
      while (grupettoDistKm < stage.totalDistanceKm && guardSteps < 600) {
        guardSteps++;
        latestEval = GrupettoAutobusSurvivalAi.evaluateAutobus(
          GrupettoAutobusInput(
            stage: stage,
            elapsedStageTimeSeconds: elapsedTimeSec,
            leaderDistanceKm: leaderDistKm,
            leaderCurrentSpeedKmh: leaderSpeedKmh,
            grupettoDistanceKm: grupettoDistKm,
            grupettoCurrentSpeedKmh: currentSpeedKmh,
            riderPool: pool,
            tacticMode: GrupettoCaptainTacticMode.exactThreeMinuteBuffer,
          ),
        );

        // Kapitan utrzymuje co najmniej minimalną wymaganą prędkość przetrwania OTL.
        currentSpeedKmh = latestEval.pacePlan.requiredMinAverageSpeedKmh;
        grupettoDistKm = (grupettoDistKm + currentSpeedKmh * (stepSec / 3600.0))
            .clamp(0.0, stage.totalDistanceKm);
        leaderDistKm = (leaderDistKm + leaderSpeedKmh * (stepSec / 3600.0))
            .clamp(0.0, stage.totalDistanceKm);
        elapsedTimeSec += stepSec;
      }

      // Lider dojechał do mety i ustalono ostateczny limit OTL
      expect(leaderDistKm, closeTo(stage.totalDistanceKm, 1e-6));
      expect(grupettoDistKm, closeTo(stage.totalDistanceKm, 1e-6));

      final double otlLimitSeconds = latestEval.pacePlan.otlLimitSeconds;
      final double otlMarginAtFinishSeconds = otlLimitSeconds - elapsedTimeSec;

      // Grupetto dojechało do mety przed limitem czasu OTL (z zapasem ok. 3 minut = 180 s).
      expect(elapsedTimeSec, lessThan(otlLimitSeconds));
      expect(otlMarginAtFinishSeconds, greaterThan(60.0));
      expect(
        latestEval.pacePlan.targetGrupettoFinishTimeSeconds,
        closeTo(otlLimitSeconds - 180.0, 1.0),
      );
      expect(
        latestEval.survivalStatus,
        isNot(GrupettoSurvivalStatus.criticalOtlDanger),
      );
    });

    test('spadek tempa poniżej wymaganego minimum uruchamia status pushingForTimeCut lub criticalOtlDanger', () {
      final RaceStage stage = _buildHighMountainStage();
      final List<GrupettoRiderProfile> pool = _buildAutobusRiderPool(count: 35);

      final GrupettoEvaluationResult dangerEval =
          GrupettoAutobusSurvivalAi.evaluateAutobus(
        GrupettoAutobusInput(
          stage: stage,
          elapsedStageTimeSeconds: 14500.0,
          leaderDistanceKm: 148.0,
          leaderCurrentSpeedKmh: 36.0,
          grupettoDistanceKm: 120.0,
          grupettoCurrentSpeedKmh: 16.0, // Zbyt wolno na końcówce -> zagrożenie OTL
          riderPool: pool,
        ),
      );

      expect(
        dangerEval.survivalStatus == GrupettoSurvivalStatus.pushingForTimeCut ||
            dangerEval.survivalStatus == GrupettoSurvivalStatus.criticalOtlDanger,
        isTrue,
      );
      expect(dangerEval.pacePlan.projectedOtlMarginSeconds, lessThan(180.0));
      expect(dangerEval.activePullerRiderIds.length, greaterThanOrEqualTo(6));
    });

    test('brak odpadniętych kolarzy lub etap płaski nie tworzy Autobusu', () {
      final RaceStage stage = _buildHighMountainStage();
      final GrupettoEvaluationResult emptyEval =
          GrupettoAutobusSurvivalAi.evaluateAutobus(
        GrupettoAutobusInput(
          stage: stage,
          elapsedStageTimeSeconds: 1800.0,
          leaderDistanceKm: 20.0,
          leaderCurrentSpeedKmh: 44.0,
          grupettoDistanceKm: 20.0,
          grupettoCurrentSpeedKmh: 44.0,
          riderPool: const [],
        ),
      );

      expect(emptyEval.formationState, GrupettoFormationState.notFormed);
      expect(emptyEval.captain, isNull);
      expect(emptyEval.groupSize, 0);
    });
  });
}
