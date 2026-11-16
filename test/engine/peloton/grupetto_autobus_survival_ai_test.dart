import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/grupetto_autobus_survival_ai.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

RaceStage _buildHighMountainStage() {
  return const RaceStage(
    id: 'tdf_stage_17',
    stageNumber: 17,
    name: 'Saint-Gervais -> Courchevel (Col de la Loze)',
    stageType: StageType.highMountain,
    baseTemperatureCelsius: 24.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 8.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 25.0,
        startElevationM: 600.0,
        endElevationM: 650.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 25.0,
        lengthKm: 18.0,
        startElevationM: 650.0,
        endElevationM: 1950.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 45.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.cat1,
      ),
      StageSegment(
        index: 2,
        startKm: 43.0,
        lengthKm: 35.0,
        startElevationM: 1950.0,
        endElevationM: 750.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 60.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 3,
        startKm: 78.0,
        lengthKm: 60.0,
        startElevationM: 750.0,
        endElevationM: 820.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 25.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 4,
        startKm: 138.0,
        lengthKm: 28.0,
        startElevationM: 820.0,
        endElevationM: 2304.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 55.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ],
  );
}

List<GrupettoRiderProfile> _buildFortyPlusRiderPool() {
  final List<GrupettoRiderProfile> pool = [];
  for (int i = 0; i < 48; i++) {
    final bool isCaptainCandidate = i == 7;
    final GrupettoRiderArchetype archetype = i < 20
        ? GrupettoRiderArchetype.sprinter
        : i < 34
            ? GrupettoRiderArchetype.heavyClassics
            : GrupettoRiderArchetype.domestique;

    pool.add(
      GrupettoRiderProfile(
        riderId: 'r_$i',
        riderName: isCaptainCandidate ? 'Bernhard Veteran' : 'Rider $i',
        teamId: 'team_${i % 10}',
        archetype: archetype,
        ageYears: isCaptainCandidate ? 35 : 24 + (i % 8),
        experienceYears: isCaptainCandidate ? 15 : 3 + (i % 6),
        raceIq: isCaptainCandidate ? 95 : 65 + (i % 15),
        mountainSkill: 52 + (i % 15),
        flatSkill: isCaptainCandidate ? 86 : 70 + (i % 14),
        weightKg: archetype == GrupettoRiderArchetype.sprinter ? 77.0 : 79.0,
        ftpWatts: 380 + (i % 40),
        fatigueRatio: 0.25 + (i % 5) * 0.05,
        isDroppedFromPeloton: i < 44, // 44 kolarzy odpadło na 1. przełęczy
        isPlayerTeam: i == 0 || i == 25,
      ),
    );
  }
  return pool;
}

void main() {
  group('GrupettoAutobusSurvivalAi', () {
    test('forms a 40-rider Autobus on the first mountain pass and selects veteran captain', () {
      final stage = _buildHighMountainStage();
      final pool = _buildFortyPlusRiderPool();

      final result = GrupettoAutobusSurvivalAi.evaluateAutobus(
        GrupettoAutobusInput(
          stage: stage,
          elapsedStageTimeSeconds: 3600.0, // 1h
          leaderDistanceKm: 42.0,
          leaderCurrentSpeedKmh: 36.0,
          grupettoDistanceKm: 33.0, // na 1. przełęczy
          grupettoCurrentSpeedKmh: 28.5,
          riderPool: pool,
          targetGroupSize: 40,
        ),
      );

      expect(result.formationState, GrupettoFormationState.activeAutobus);
      expect(result.groupSize, 40);
      expect(result.captain, isNotNull);
      expect(result.captain!.riderId, 'r_7');
      expect(result.captain!.riderName, 'Bernhard Veteran');
      expect(result.sprinterCount, 20);
      expect(result.heavyClassicsCount, 14);
      expect(result.domestiqueCount, 6);
      expect(result.activePullerRiderIds, isNotEmpty);
      expect(result.protectedDraftRiderIds.length, greaterThanOrEqualTo(20));
    });

    test('mathematically computes minimum speed to beat OTL with 3-minute (180s) margin', () {
      final stage = _buildHighMountainStage();
      final pool = _buildFortyPlusRiderPool();

      final result = GrupettoAutobusSurvivalAi.evaluateAutobus(
        GrupettoAutobusInput(
          stage: stage,
          elapsedStageTimeSeconds: 7200.0, // 2h
          leaderDistanceKm: 80.0,
          leaderCurrentSpeedKmh: 35.0,
          grupettoDistanceKm: 65.0,
          grupettoCurrentSpeedKmh: 31.0,
          riderPool: pool,
        ),
      );

      final plan = result.pacePlan;
      expect(plan.safetyMarginSeconds, 180.0);
      expect(
        plan.targetGrupettoFinishTimeSeconds,
        closeTo(plan.otlLimitSeconds - 180.0, 0.001),
      );

      // Sprawdzenie matematyki: pokonanie remainingDistanceKm z prędkością requiredMinAverageSpeedKmh
      // powinno dać czas dokładnie równy remainingTimeBudgetSeconds.
      final double timeAtRequiredSpeedSeconds =
          (plan.remainingDistanceKm / plan.requiredMinAverageSpeedKmh) * 3600.0;
      expect(
        timeAtRequiredSpeedSeconds,
        closeTo(plan.remainingTimeBudgetSeconds, 1.0),
      );
      expect(plan.draftPowerSavingsPercent, closeTo(33.0, 0.1));
    });

    test('detects critical OTL danger when grupetto falls severely behind schedule', () {
      final stage = _buildHighMountainStage();
      final pool = _buildFortyPlusRiderPool();

      final result = GrupettoAutobusSurvivalAi.evaluateAutobus(
        GrupettoAutobusInput(
          stage: stage,
          elapsedStageTimeSeconds: 16500.0, // bardzo późny czas na etapie
          leaderDistanceKm: 164.0,
          leaderCurrentSpeedKmh: 36.0,
          grupettoDistanceKm: 120.0,
          grupettoCurrentSpeedKmh: 22.0,
          riderPool: pool,
        ),
      );

      expect(result.survivalStatus, GrupettoSurvivalStatus.criticalOtlDanger);
      expect(result.activePullerRiderIds.length, 8);
      expect(result.pacePlan.projectedOtlMarginSeconds, lessThan(30.0));
    });

    test('does not form mountain grupetto on flat stages', () {
      const flatStage = RaceStage(
        id: 'flat_1',
        stageNumber: 1,
        name: 'Flat Sprint Stage',
        stageType: StageType.flat,
        baseTemperatureCelsius: 22.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 10.0,
        segments: [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 180.0,
            startElevationM: 120.0,
            endElevationM: 145.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 15.0,
            windDirectionDegrees: 90.0,
            roadBearingDegrees: 90.0,
            sprintOrKomClassification: SegmentClassification.finishLine,
          ),
        ],
      );
      final pool = _buildFortyPlusRiderPool();

      final result = GrupettoAutobusSurvivalAi.evaluateAutobus(
        GrupettoAutobusInput(
          stage: flatStage,
          elapsedStageTimeSeconds: 3600.0,
          leaderDistanceKm: 45.0,
          leaderCurrentSpeedKmh: 45.0,
          grupettoDistanceKm: 42.0,
          grupettoCurrentSpeedKmh: 42.0,
          riderPool: pool,
        ),
      );

      expect(result.formationState, GrupettoFormationState.notFormed);
    });
  });

  group('GrupettoAutobusSurvivalPanel responsive widget tests', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final stage = _buildHighMountainStage();
          final eval = GrupettoAutobusSurvivalAi.evaluateAutobus(
            GrupettoAutobusInput(
              stage: stage,
              elapsedStageTimeSeconds: 7200.0,
              leaderDistanceKm: 80.0,
              leaderCurrentSpeedKmh: 35.0,
              grupettoDistanceKm: 65.0,
              grupettoCurrentSpeedKmh: 31.0,
              riderPool: _buildFortyPlusRiderPool(),
            ),
          );

          GrupettoCaptainTacticMode currentMode =
              GrupettoCaptainTacticMode.exactThreeMinuteBuffer;
          bool pulling = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return GrupettoAutobusSurvivalPanel(
                        evaluation: eval,
                        selectedTacticMode: currentMode,
                        isPlayerPulling: pulling,
                        onTacticModeChanged: (mode) {
                          setState(() => currentMode = mode);
                        },
                        onTogglePlayerPull: () {
                          setState(() => pulling = !pulling);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.textContaining('GRUPETTO'), findsOneWidget);
          expect(find.textContaining('Bernhard Veteran'), findsOneWidget);

          await tester.tap(find.text('Bezpieczny Bufor (+5:00)'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(currentMode, GrupettoCaptainTacticMode.proactiveSafetyMargin);

          await tester.tap(find.text('Wyślij pomocnika na zmianę w Grupetto'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(pulling, isTrue);
          expect(
            find.text('Twój kolarz pracuje na czele Autobusu'),
            findsOneWidget,
          );
        },
      );
    }
  });
}
