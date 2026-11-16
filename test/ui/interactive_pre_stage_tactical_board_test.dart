import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/ui/widgets/interactive_pre_stage_tactical_board.dart';

void main() {
  RaceStage buildMountainTestStage() {
    return const RaceStage(
      id: 'stage_tactical_test',
      stageNumber: 15,
      name: 'Bourg-d\'Oisans > Alpe d\'Huez',
      stageType: StageType.summitFinish,
      baseTemperatureCelsius: 18.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 12.0,
      segments: [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 140.0,
          startElevationM: 250.0,
          endElevationM: 530.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 20.0,
          windDirectionDegrees: 90.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.intermediateSprint,
        ),
        StageSegment(
          index: 1,
          startKm: 140.0,
          lengthKm: 10.0,
          startElevationM: 530.0,
          endElevationM: 930.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 55.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.cat2,
        ),
        StageSegment(
          index: 2,
          startKm: 150.0,
          lengthKm: 15.0,
          startElevationM: 930.0,
          endElevationM: 2580.0, // 1650m / 15000m = 11.0% gradient
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 85.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.horsCategorie,
        ),
      ],
    );
  }

  List<TacticalBoardRiderEntry> buildTestRiders() {
    return const [
      TacticalBoardRiderEntry(
        riderId: 'r_janek',
        riderName: 'Janek Kowalski',
        shortName: 'Janek',
        roleLabel: 'Ochroniarz',
        jerseyNumber: 2,
        accentColor: AppColors.accentBlue,
      ),
      TacticalBoardRiderEntry(
        riderId: 'r_piotr',
        riderName: 'Piotr Nowak',
        shortName: 'Piotr',
        roleLabel: 'Góral',
        jerseyNumber: 3,
        accentColor: AppColors.cyanAccent,
      ),
      TacticalBoardRiderEntry(
        riderId: 'r_lider',
        riderName: 'Lider Wiśniewski',
        shortName: 'Lider',
        roleLabel: 'Lider GC',
        jerseyNumber: 1,
        accentColor: AppColors.goldAccent,
      ),
    ];
  }

  test('TacticalStageAssignment generates exact Polish tactical descriptions',
      () {
    final stage = buildMountainTestStage();
    final riders = buildTestRiders();

    const protectOrder = TacticalStageAssignment(
      id: 'a1',
      riderId: 'r_janek',
      orderType: TacticalBoardOrderType.protectLeader,
      startKm: 0.0,
      endKm: 140.0,
    );
    const trainOrder = TacticalStageAssignment(
      id: 'a2',
      riderId: 'r_piotr',
      orderType: TacticalBoardOrderType.mountainTrain,
      startKm: 145.0,
    );
    const attackOrder = TacticalStageAssignment(
      id: 'a3',
      riderId: 'r_lider',
      orderType: TacticalBoardOrderType.attack,
      startKm: 158.0,
    );

    expect(
      protectOrder.describeForStage(stage, riders[0]),
      'Janek chroni lidera od km 0 do km 140',
    );
    expect(
      trainOrder.describeForStage(stage, riders[1]),
      'Piotr rozpoczyna pociąg górski na km 145',
    );
    expect(
      attackOrder.describeForStage(stage, riders[2]),
      'Lider atakuje na km 158 (gradient 11%)',
    );
  });

  testWidgets(
      'InteractivePreStageTacticalBoard supports dragging riders onto profile and moving markers',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final stage = buildMountainTestStage();
    final riders = buildTestRiders();
    List<TacticalStageAssignment> latestAssignments = [];

    const initial = [
      TacticalStageAssignment(
        id: 'init_1',
        riderId: 'r_janek',
        orderType: TacticalBoardOrderType.protectLeader,
        startKm: 0.0,
        endKm: 140.0,
      ),
      TacticalStageAssignment(
        id: 'init_2',
        riderId: 'r_piotr',
        orderType: TacticalBoardOrderType.mountainTrain,
        startKm: 145.0,
      ),
      TacticalStageAssignment(
        id: 'init_3',
        riderId: 'r_lider',
        orderType: TacticalBoardOrderType.attack,
        startKm: 158.0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: InteractivePreStageTacticalBoard(
              stage: stage,
              riders: riders,
              initialAssignments: initial,
              onAssignmentsChanged: (list) {
                latestAssignments = list;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Sprawdzenie opisów początkowych
    expect(
      find.text('Janek chroni lidera od km 0 do km 140'),
      findsAtLeastNWidgets(1),
    );
    expect(
      find.text('Piotr rozpoczyna pociąg górski na km 145'),
      findsAtLeastNWidgets(1),
    );
    expect(
      find.text('Lider atakuje na km 158 (gradient 11%)'),
      findsAtLeastNWidgets(1),
    );

    // Przeciągnięcie znacznika ataku Lidera poziomo w lewo na wykresie
    final markerFinder = find.byKey(const ValueKey('marker_init_3'));
    expect(markerFinder, findsOneWidget);
    await tester.drag(markerFinder, const Offset(-140, 0));
    await tester.pump(const Duration(milliseconds: 300));

    expect(latestAssignments.length, 3);
    final movedAttack =
        latestAssignments.firstWhere((a) => a.id == 'init_3');
    expect(movedAttack.startKm, lessThan(158.0));

    // Przeciągnięcie kolarza z doku na wykres profilu (DragTarget)
    await tester.tap(find.text('Bidony i żele'));
    await tester.pump(const Duration(milliseconds: 200));

    final janekDockChip = find.text('Janek').first;
    final chartTarget = find.byType(DragTarget<TacticalBoardRiderEntry>);
    expect(chartTarget, findsOneWidget);

    final Offset chartCenter = tester.getCenter(chartTarget);
    final Offset chipCenter = tester.getCenter(janekDockChip);
    await tester.dragFrom(chipCenter, chartCenter - chipCenter);
    await tester.pump(const Duration(milliseconds: 300));

    expect(latestAssignments.length, 4);
    expect(
      latestAssignments.any(
        (a) => a.orderType == TacticalBoardOrderType.fetchBidons,
      ),
      isTrue,
    );

    // Czyszczenie i Auto-Taktyka
    await tester.tap(find.text('Wyczyść'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(latestAssignments, isEmpty);

    await tester.tap(find.text('Auto-Taktyka'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(latestAssignments.isNotEmpty, isTrue);
  });

  for (final size in const [
    Size(390, 844),
    Size(1024, 768),
    Size(1600, 900),
  ]) {
    testWidgets(
        'InteractivePreStageTacticalBoard renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: InteractivePreStageTacticalBoard(
                  stage: buildMountainTestStage(),
                  riders: buildTestRiders(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InteractivePreStageTacticalBoard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
