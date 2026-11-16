import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/commissaire_jury_penalties_engine.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_results_calculator.dart';

void main() {
  const engine = CommissaireJuryPenaltiesEngine();

  group('CommissaireJuryPenaltiesEngine', () {
    test('Sticky Bottle below threshold returns null, >= 3.5s gives +20s and CHF fines', () {
      const minorDrink = CommissaireObservationInput(
        riderId: 'r1',
        riderName: 'Jan Kowalski',
        teamId: 'team_a',
        teamName: 'Team Alpha',
        bibNumber: 12,
        infractionType: UciInfractionType.stickyBottle,
        kilometerMark: 112.5,
        stickyBottleDurationSeconds: 2.8,
      );
      expect(engine.evaluateObservation(minorDrink), isNull);

      const stickyBottle = CommissaireObservationInput(
        riderId: 'r1',
        riderName: 'Jan Kowalski',
        teamId: 'team_a',
        teamName: 'Team Alpha',
        bibNumber: 12,
        infractionType: UciInfractionType.stickyBottle,
        kilometerMark: 112.5,
        stickyBottleDurationSeconds: 5.5,
      );

      final decision = engine.evaluateObservation(stickyBottle, stageNumber: 4);
      expect(decision, isNotNull);
      expect(decision!.timePenaltySeconds, 20);
      expect(decision.relegateToBackOfGroup, isFalse);
      expect(decision.disqualified, isFalse);
      expect(decision.fineChf, 200);
      expect(decision.teamDirectorFineChf, 200);
      expect(decision.totalFineChf, 400);
      expect(decision.fineEurEquivalent, greaterThanOrEqualTo(400));
    });

    test('Irregular Sprint relegates rider to back of group with 500 CHF fine and yellow card', () {
      const irregularSprint = CommissaireObservationInput(
        riderId: 'r2',
        riderName: 'Marco Veloce',
        teamId: 'team_b',
        teamName: 'Team Beta',
        bibNumber: 44,
        infractionType: UciInfractionType.irregularSprint,
        kilometerMark: 185.0,
        sprintDeviationMeters: 2.1,
        isSprintFinish: true,
      );

      final decision = engine.evaluateObservation(irregularSprint, stageNumber: 2);
      expect(decision, isNotNull);
      expect(decision!.timePenaltySeconds, 0);
      expect(decision.relegateToBackOfGroup, isTrue);
      expect(decision.disqualified, isFalse);
      expect(decision.fineChf, 500);
      expect(decision.pointsClassificationPenalty, 15);
      expect(decision.yellowCardIssued, isTrue);
    });

    test('Repeat Irregular Sprint causing crash escalates to DSQ and 1000 CHF', () {
      const dangerousRepeat = CommissaireObservationInput(
        riderId: 'r2',
        riderName: 'Marco Veloce',
        teamId: 'team_b',
        teamName: 'Team Beta',
        bibNumber: 44,
        infractionType: UciInfractionType.irregularSprint,
        kilometerMark: 192.0,
        sprintDeviationMeters: 2.6,
        causedCrashOrNearMiss: true,
        repeatOffenseCount: 1,
        isSprintFinish: true,
      );

      final decision = engine.evaluateObservation(dangerousRepeat, stageNumber: 7);
      expect(decision, isNotNull);
      expect(decision!.disqualified, isTrue);
      expect(decision.severity, PenaltySeverity.disqualification);
      expect(decision.fineChf, 1000);
    });

    test('applyPenaltiesToStageResults relegates sprinter to back of group and applies +20s sticky bottle', () {
      final initialResults = [
        const OfficialRiderStageResult(
          riderId: 'r_sprint',
          riderName: 'Sprinter One',
          teamId: 'team_a',
          rank: 1,
          rawFinishTimeSeconds: 14400.0,
          officialFinishTimeSeconds: 14400.0,
          timeBonusSeconds: 10,
          gapToWinnerSeconds: 0.0,
          pointsGreenJersey: 50,
        ),
        const OfficialRiderStageResult(
          riderId: 'r_two',
          riderName: 'Rider Two',
          teamId: 'team_b',
          rank: 2,
          rawFinishTimeSeconds: 14400.0,
          officialFinishTimeSeconds: 14400.0,
          timeBonusSeconds: 6,
          gapToWinnerSeconds: 0.0,
          pointsGreenJersey: 30,
        ),
        const OfficialRiderStageResult(
          riderId: 'r_three',
          riderName: 'Rider Three',
          teamId: 'team_c',
          rank: 3,
          rawFinishTimeSeconds: 14400.0,
          officialFinishTimeSeconds: 14400.0,
          timeBonusSeconds: 4,
          gapToWinnerSeconds: 0.0,
          pointsGreenJersey: 20,
        ),
        const OfficialRiderStageResult(
          riderId: 'r_sticky',
          riderName: 'Sticky Climber',
          teamId: 'team_d',
          rank: 4,
          rawFinishTimeSeconds: 14430.0,
          officialFinishTimeSeconds: 14430.0,
          gapToWinnerSeconds: 30.0,
        ),
      ];

      final communique = engine.evaluateStageObservations(
        stageNumber: 3,
        stageName: 'Etap 3',
        observations: const [
          CommissaireObservationInput(
            riderId: 'r_sprint',
            riderName: 'Sprinter One',
            teamId: 'team_a',
            teamName: 'Team A',
            bibNumber: 1,
            infractionType: UciInfractionType.irregularSprint,
            kilometerMark: 180.0,
            sprintDeviationMeters: 1.8,
            isSprintFinish: true,
          ),
          CommissaireObservationInput(
            riderId: 'r_sticky',
            riderName: 'Sticky Climber',
            teamId: 'team_d',
            teamName: 'Team D',
            bibNumber: 55,
            infractionType: UciInfractionType.stickyBottle,
            kilometerMark: 145.0,
            stickyBottleDurationSeconds: 6.0,
          ),
        ],
      );

      final updated = engine.applyPenaltiesToStageResults(
        results: initialResults,
        communique: communique,
      );

      expect(updated[0].riderId, 'r_two');
      expect(updated[0].rank, 1);
      expect(updated[1].riderId, 'r_three');
      expect(updated[1].rank, 2);

      // Sprinter One relegated to the back of the 14400s group (rank 3), bonus cleared, -15 pts.
      final relegated = updated.firstWhere((r) => r.riderId == 'r_sprint');
      expect(relegated.rank, 3);
      expect(relegated.officialFinishTimeSeconds, 14400.0);
      expect(relegated.timeBonusSeconds, 0);
      expect(relegated.pointsGreenJersey, 35);

      // Sticky Climber received +20s penalty -> 14450.0s (+50s gap).
      final sticky = updated.firstWhere((r) => r.riderId == 'r_sticky');
      expect(sticky.rank, 4);
      expect(sticky.officialFinishTimeSeconds, 14450.0);
      expect(sticky.gapToWinnerSeconds, 50.0);
    });

    test('CommissaireStageCommunique JSON round-trip preserves all fields', () {
      final communique = engine.evaluateStageObservations(
        stageNumber: 5,
        stageName: 'Pireneje',
        observations: const [
          CommissaireObservationInput(
            riderId: 'r10',
            riderName: 'Test Rider',
            teamId: 't1',
            teamName: 'Team One',
            bibNumber: 101,
            infractionType: UciInfractionType.stickyBottle,
            kilometerMark: 98.4,
            stickyBottleDurationSeconds: 5.0,
          ),
        ],
      );

      final decoded = CommissaireStageCommunique.fromJson(communique.toJson());
      expect(decoded.stageNumber, 5);
      expect(decoded.totalTimePenaltiesSeconds, 20);
      expect(decoded.totalFinesChf, 400);
      expect(decoded.finesByTeamChf['t1'], 400);
      expect(decoded.decisions.length, 1);
    });
  });

  group('CommissaireJuryCommuniquesPanel responsive & interaction', () {
    final communique = engine.evaluateStageObservations(
      stageNumber: 6,
      stageName: 'Champs-Élysées Sprint',
      observations: const [
        CommissaireObservationInput(
          riderId: 'r1',
          riderName: 'Jasper Fast',
          teamId: 'team_a',
          teamName: 'Alpecin Demo',
          bibNumber: 21,
          infractionType: UciInfractionType.irregularSprint,
          kilometerMark: 165.0,
          sprintDeviationMeters: 1.9,
          isSprintFinish: true,
        ),
        CommissaireObservationInput(
          riderId: 'r2',
          riderName: 'Piotr Góral',
          teamId: 'team_b',
          teamName: 'Polonia WT',
          bibNumber: 77,
          infractionType: UciInfractionType.stickyBottle,
          kilometerMark: 110.2,
          stickyBottleDurationSeconds: 5.2,
        ),
      ],
    );

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders cleanly without overflow at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: CommissaireJuryCommuniquesPanel(communique: communique),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('KOMUNIKAT KOLEGIUM SĘDZIÓW UCI'), findsOneWidget);
        expect(find.text('Jasper Fast'), findsOneWidget);
        expect(find.text('Piotr Góral'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('filter tabs and pay fine button update state', (tester) async {
      CommissairePenaltyDecision? paidDecision;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CommissaireJuryCommuniquesPanel(
                communique: communique,
                onAcknowledgeOrPayFine: (d) => paidDecision = d,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Kary czasowe').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Piotr Góral'), findsOneWidget);
      expect(find.text('Jasper Fast'), findsNothing);

      await tester.tap(find.text('Zapłać grzywnę'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(paidDecision, isNotNull);
      expect(paidDecision!.riderId, 'r2');
      expect(find.text('Opłacono (CHF)'), findsOneWidget);
    });
  });
}
