import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/team_sprint_train_echelon_diagonal_formation.dart';

void main() {
  const baseContext = DiagonalTrainWindContext(
    windSpeedKmh: 36.0,
    windAngleDegrees: 80.0,
    crosswindSide: CrosswindSide.leftToRight,
    roadWidthMeters: 6.2,
    distanceToFinishMeters: 1600.0,
    targetTrainSpeedKmh: 58.0,
  );

  List<EchelonTrainRiderInput> buildTeam() => const [
        EchelonTrainRiderInput(
          riderId: 't1',
          name: 'Lead 1',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: false,
          roleOrder: 0,
          flatSkill: 88,
          sprintSkill: 70,
          bikeHandling: 86,
          raceIq: 85,
          draftingEfficiency: 86,
          ftpWatts: 430,
          wPrimeRemainingJoules: 20000,
          wPrimeMaxJoules: 21000,
        ),
        EchelonTrainRiderInput(
          riderId: 't2',
          name: 'Lead 2',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: false,
          roleOrder: 1,
          flatSkill: 85,
          sprintSkill: 75,
          bikeHandling: 88,
          raceIq: 86,
          draftingEfficiency: 88,
          ftpWatts: 415,
          wPrimeRemainingJoules: 19000,
          wPrimeMaxJoules: 20000,
        ),
        EchelonTrainRiderInput(
          riderId: 't3',
          name: 'Lead 3',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: false,
          roleOrder: 2,
          flatSkill: 83,
          sprintSkill: 82,
          bikeHandling: 89,
          raceIq: 88,
          draftingEfficiency: 90,
          ftpWatts: 410,
          wPrimeRemainingJoules: 19500,
          wPrimeMaxJoules: 20500,
        ),
        EchelonTrainRiderInput(
          riderId: 't4',
          name: 'Lead 4',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: false,
          roleOrder: 3,
          flatSkill: 81,
          sprintSkill: 87,
          bikeHandling: 90,
          raceIq: 90,
          draftingEfficiency: 91,
          ftpWatts: 400,
          wPrimeRemainingJoules: 21000,
          wPrimeMaxJoules: 22000,
        ),
        EchelonTrainRiderInput(
          riderId: 't5',
          name: 'Sprinter',
          teamId: 'player',
          isPlayerTeam: true,
          isSprinter: true,
          roleOrder: 4,
          flatSkill: 78,
          sprintSkill: 96,
          bikeHandling: 92,
          raceIq: 90,
          draftingEfficiency: 94,
          ftpWatts: 390,
          wPrimeRemainingJoules: 24500,
          wPrimeMaxJoules: 25000,
        ),
      ];

  List<EchelonTrainRiderInput> buildRivals() => const [
        EchelonTrainRiderInput(
          riderId: 'r1',
          name: 'Rival A',
          teamId: 'ra',
          isPlayerTeam: false,
          isSprinter: true,
          roleOrder: 0,
          flatSkill: 77,
          sprintSkill: 93,
          bikeHandling: 80,
          raceIq: 79,
          draftingEfficiency: 80,
          ftpWatts: 385,
          wPrimeRemainingJoules: 15000,
          wPrimeMaxJoules: 22000,
        ),
        EchelonTrainRiderInput(
          riderId: 'r2',
          name: 'Rival B',
          teamId: 'rb',
          isPlayerTeam: false,
          isSprinter: true,
          roleOrder: 1,
          flatSkill: 74,
          sprintSkill: 90,
          bikeHandling: 73,
          raceIq: 72,
          draftingEfficiency: 74,
          ftpWatts: 375,
          wPrimeRemainingJoules: 4000,
          wPrimeMaxJoules: 20000,
        ),
      ];

  group('TeamSprintTrainEchelonDiagonalFormation', () {
    test('wylicza składową boczną wiatru i kąt przekątnej wachlarza', () {
      final crosswind =
          TeamSprintTrainEchelonDiagonalFormation.calculateCrosswindComponentKmh(
        windSpeedKmh: 36.0,
        windAngleDegrees: 90.0,
      );
      expect(crosswind, closeTo(36.0, 0.01));

      final angle =
          TeamSprintTrainEchelonDiagonalFormation.calculateDiagonalAngleDegrees(
        crosswindKmh: crosswind,
        trainSpeedKmh: 58.0,
        mode: DiagonalTrainFormationMode.aggressiveGutterPress,
      );
      expect(angle, greaterThan(20.0));
      expect(angle, lessThanOrEqualTo(44.0));
    });

    test('aggressiveGutterPress zamyka krawężnik i spycha rywali In the Gutter', () {
      final eval =
          TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
        context: baseContext,
        mode: DiagonalTrainFormationMode.aggressiveGutterPress,
        teamTrain: buildTeam(),
        rivalContenders: buildRivals(),
      );

      expect(eval.isCrosswindActive, isTrue);
      expect(eval.gutterReport.isGutterClosed, isTrue);
      expect(eval.gutterReport.gutterGapMeters, lessThanOrEqualTo(0.75));
      expect(
        eval.gutterReport.trappedRivalIds.length +
            eval.gutterReport.droppedRivalIds.length,
        equals(2),
      );
      expect(eval.teamSlots.last.draftingSavingsPercent, greaterThan(30.0));
      expect(
        eval.rivalSlots.every(
          (r) =>
              r.gutterStatus == GutterPressureStatus.inTheGutter ||
              r.gutterStatus == GutterPressureStatus.droppedFromEchelon,
        ),
        isTrue,
      );
    });

    test('obsługuje symetrycznie kierunek rightToLeft', () {
      final eval =
          TeamSprintTrainEchelonDiagonalFormation.evaluateDiagonalFormation(
        context: baseContext.copyWith(crosswindSide: CrosswindSide.rightToLeft),
        mode: DiagonalTrainFormationMode.aggressiveGutterPress,
        teamTrain: buildTeam(),
        rivalContenders: buildRivals(),
      );

      expect(eval.teamSlots.first.lateralPositionMeters,
          greaterThan(eval.teamSlots.last.lateralPositionMeters));
      expect(eval.gutterReport.isGutterClosed, isTrue);
    });

    test('stepSimulationTick szybciej drenuje W\' rywali w rynsztoku niż sprintera w wachlarzu', () {
      final team = buildTeam();
      final rivals = buildRivals();
      final step = TeamSprintTrainEchelonDiagonalFormation.stepSimulationTick(
        context: baseContext,
        mode: DiagonalTrainFormationMode.aggressiveGutterPress,
        teamTrain: team,
        rivalContenders: rivals,
        dtSeconds: 5.0,
      );

      final sprinterDrop =
          team.last.wPrimeRemainingJoules - step.updatedTeam.last.wPrimeRemainingJoules;
      final rivalDrop =
          rivals.first.wPrimeRemainingJoules - step.updatedRivals.first.wPrimeRemainingJoules;

      expect(rivalDrop, greaterThan(sprinterDrop));
    });
  });

  group('TeamSprintTrainEchelonDiagonalPanel UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renderuje się bez przepełnień dla ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TeamSprintTrainEchelonDiagonalPanel(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 320));

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Wachlarz Diagonalny'), findsOneWidget);
      });
    }

    testWidgets('reaguje na zmianę trybu oraz kliknięcie Symuluj 5s', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamSprintTrainEchelonDiagonalPanel(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Tarcza Diagonalna'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Symuluj 5s'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
