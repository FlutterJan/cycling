import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/services/career/broken_promises_locker_room_revolt.dart';
import 'package:pro_peloton_manager/services/career/rider_ego_and_conflicts_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  late Rider starLeader;
  late Rider domestique;
  late TourRace tourDeFrance;

  setUp(() {
    starLeader = RiderProceduralGenerator.generateRider(
      id: 'star_gc_01',
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: 90,
    ).copyWith(
      firstName: 'Tadej',
      lastName: 'Kowalski',
      contract: const RiderContract(
        teamId: 'team_01',
        role: RiderRole.teamLeader,
        monthlySalaryEur: 200000,
        signingBonusEur: 50000,
        winBonusEur: 120000,
        releaseClauseEur: 6000000,
        contractEndYear: 2028,
        morale: 88.0,
        leaderLoyalty: 75.0,
        requiredRacesIds: ['tdf_2026'],
      ),
    );

    domestique = RiderProceduralGenerator.generateRider(
      id: 'domestique_02',
      specialization: RiderSpecialization.domestiqueEngine,
      targetOverallRating: 78,
    ).copyWith(
      firstName: 'Jan',
      lastName: 'Nowak',
      contract: const RiderContract(
        teamId: 'team_01',
        role: RiderRole.domestique,
        monthlySalaryEur: 35000,
        signingBonusEur: 10000,
        winBonusEur: 15000,
        releaseClauseEur: 800000,
        contractEndYear: 2027,
        morale: 82.0,
        leaderLoyalty: 85.0,
        requiredRacesIds: ['tdf_2026'],
      ),
    );

    tourDeFrance = const TourRace(
      id: 'tdf_2026',
      name: 'Tour de France',
      countryIso: 'FRA',
      uciCategory: RaceCategory.grandTour,
      startMonth: 7,
      startDay: 4,
      stages: [],
      prizePoolEur: 2300000,
      participatingTeamIds: ['team_01'],
      ridersPerTeam: 8,
      classifications: RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );
  });

  RiderContractPromise buildTdfLeaderPromise() {
    return RiderContractPromise(
      id: 'promise_tdf_leader_01',
      riderId: starLeader.id,
      type: ContractPromiseType.soleLeaderGrandTour,
      targetRaceId: tourDeFrance.id,
      targetRaceName: tourDeFrance.name,
      promisedDate: DateTime(2026, 1, 15),
    );
  }

  group('BrokenPromisesLockerRoomRevolt', () {
    test(
      'demoting promised TdF star leader to domestique triggers transfer demand, press interview, and -30 team chemistry',
      () {
        final result =
            BrokenPromisesLockerRoomRevolt.evaluateSquadSelectionConsequences(
          race: tourDeFrance,
          teamRoster: [starLeader, domestique],
          selectedSquadRiderIds: [starLeader.id, domestique.id],
          assignedRolesByRiderId: {
            starLeader.id: AssignedRaceRole.domestique,
            domestique.id: AssignedRaceRole.leader,
          },
          activePromises: [buildTdfLeaderPromise()],
          currentTeamChemistry: 82.0,
          evaluationDate: DateTime(2026, 7, 1),
          teamName: 'Polonia Pro Cycling',
        );

        expect(result.hasRevolt, isTrue);
        expect(result.brokenPromises, hasLength(1));
        expect(
          result.brokenPromises.first.breachReason,
          PromiseBreachReason.demotedToDomestique,
        );
        expect(result.totalChemistryDelta, -30.0);
        expect(result.resultingTeamChemistry, 52.0);
        expect(result.transferRequests, hasLength(1));
        expect(result.transferRequests.first.riderId, starLeader.id);
        expect(result.transferRequests.first.refusesContractRenewal, isTrue);
        expect(result.pressInterviews, hasLength(1));
        expect(
          result.pressInterviews.first.quote,
          contains('Żądam natychmiastowego transferu'),
        );
        expect(
          result.updatedPromises.first.status,
          ContractPromiseStatus.broken,
        );
        expect(result.updatedPromises.first.brokenPenaltyApplied, isTrue);

        final updatedStar =
            result.updatedRiders.firstWhere((r) => r.id == starLeader.id);
        expect(updatedStar.contract.morale, 43.0);
        expect(updatedStar.contract.leaderLoyalty, 20.0);
      },
    );

    test(
      'omitting promised TdF star leader from squad triggers revolt with -30 team chemistry',
      () {
        final result =
            BrokenPromisesLockerRoomRevolt.evaluateSquadSelectionConsequences(
          race: tourDeFrance,
          teamRoster: [starLeader, domestique],
          selectedSquadRiderIds: [domestique.id],
          assignedRolesByRiderId: {
            domestique.id: AssignedRaceRole.leader,
          },
          activePromises: [buildTdfLeaderPromise()],
          currentTeamChemistry: 70.0,
          evaluationDate: DateTime(2026, 7, 1),
          teamName: 'Polonia Pro Cycling',
        );

        expect(result.hasRevolt, isTrue);
        expect(
          result.brokenPromises.first.breachReason,
          PromiseBreachReason.omittedFromSquad,
        );
        expect(result.resultingTeamChemistry, 40.0);
        expect(result.transferRequests, hasLength(1));
        expect(result.pressInterviews, hasLength(1));
        expect(result.pressInterviews.first.headline, contains('pominięty'));
      },
    );

    test(
      'honoring sole leader promise on Tour de France keeps chemistry intact',
      () {
        final result =
            BrokenPromisesLockerRoomRevolt.evaluateSquadSelectionConsequences(
          race: tourDeFrance,
          teamRoster: [starLeader, domestique],
          selectedSquadRiderIds: [starLeader.id, domestique.id],
          assignedRolesByRiderId: {
            starLeader.id: AssignedRaceRole.leader,
            domestique.id: AssignedRaceRole.domestique,
          },
          activePromises: [buildTdfLeaderPromise()],
          currentTeamChemistry: 85.0,
          evaluationDate: DateTime(2026, 7, 1),
        );

        expect(result.hasRevolt, isFalse);
        expect(result.brokenPromises, isEmpty);
        expect(result.resultingTeamChemistry, 85.0);
        expect(result.transferRequests, isEmpty);
        expect(result.pressInterviews, isEmpty);
      },
    );

    test('clamps resulting chemistry at 0.0 and ignores already broken promises', () {
      final alreadyBroken = buildTdfLeaderPromise().copyWith(
        status: ContractPromiseStatus.broken,
        brokenPenaltyApplied: true,
      );

      final ignoredResult =
          BrokenPromisesLockerRoomRevolt.evaluateSquadSelectionConsequences(
        race: tourDeFrance,
        teamRoster: [starLeader, domestique],
        selectedSquadRiderIds: [domestique.id],
        assignedRolesByRiderId: const {},
        activePromises: [alreadyBroken],
        currentTeamChemistry: 50.0,
      );

      expect(ignoredResult.hasRevolt, isFalse);
      expect(ignoredResult.resultingTeamChemistry, 50.0);

      final clampedResult =
          BrokenPromisesLockerRoomRevolt.evaluateSquadSelectionConsequences(
        race: tourDeFrance,
        teamRoster: [starLeader, domestique],
        selectedSquadRiderIds: [domestique.id],
        assignedRolesByRiderId: const {},
        activePromises: [buildTdfLeaderPromise()],
        currentTeamChemistry: 15.0,
      );

      expect(clampedResult.hasRevolt, isTrue);
      expect(clampedResult.resultingTeamChemistry, 0.0);
    });
  });

  group('BrokenPromisesLockerRoomRevoltPanel UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size,
      LockerRoomRevoltEvaluationResult evaluation, {
      void Function(TransferDemandOrder)? onAcceptTransfer,
      VoidCallback? onEmergencyMeeting,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: BrokenPromisesLockerRoomRevoltPanel(
                key: ValueKey(size),
                evaluation: evaluation,
                onAcceptTransferRequest: onAcceptTransfer,
                onCallEmergencyMeeting: onEmergencyMeeting,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
    }

    testWidgets(
      'renders cleanly without overflow on 390x844, 1024x768, and 1600x900',
      (tester) async {
        final evaluation =
            BrokenPromisesLockerRoomRevolt.evaluateSquadSelectionConsequences(
          race: tourDeFrance,
          teamRoster: [starLeader, domestique],
          selectedSquadRiderIds: [starLeader.id, domestique.id],
          assignedRolesByRiderId: {
            starLeader.id: AssignedRaceRole.domestique,
            domestique.id: AssignedRaceRole.leader,
          },
          activePromises: [buildTdfLeaderPromise()],
          currentTeamChemistry: 80.0,
        );

        for (final size in const [
          Size(390, 844),
          Size(1024, 768),
          Size(1600, 900),
        ]) {
          TransferDemandOrder? acceptedDemand;
          bool meetingCalled = false;

          await pumpPanelAtSize(
            tester,
            size,
            evaluation,
            onAcceptTransfer: (demand) => acceptedDemand = demand,
            onEmergencyMeeting: () => meetingCalled = true,
          );

          expect(
            find.text('BUNT W SZATNI — ZŁAMANE OBIETNICE'),
            findsOneWidget,
          );
          expect(find.textContaining('-30 pkt'), findsOneWidget);
          expect(tester.takeException(), isNull);

          final transferButton = find.text('Akceptuj żądanie transferu');
          await tester.ensureVisible(transferButton);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(transferButton);
          await tester.pump(const Duration(milliseconds: 250));
          expect(acceptedDemand?.riderId, starLeader.id);

          final meetingButton = find.text('Odprawa Kryzysowa');
          await tester.ensureVisible(meetingButton);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(meetingButton);
          await tester.pump(const Duration(milliseconds: 250));
          expect(meetingCalled, isTrue);
        }
      },
    );
  });
}
