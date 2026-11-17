import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/peloton/team_leader_change_on_the_road_logic.dart';

void main() {
  List<TeamRoadRiderProfile> buildStandardSquad({
    bool primaryCrashed = false,
    bool primaryDropped = false,
    double primaryGap = 0.0,
    bool primaryBadLegs = false,
    int primaryCondition = 1,
    bool coLeaderCrashed = false,
    bool coLeaderDropped = false,
  }) {
    return [
      TeamRoadRiderProfile(
        riderId: 'r_1',
        riderName: 'Tadej Lider',
        bibNumber: 1,
        hierarchyRole: TeamHierarchyRole.primaryLeader,
        groupIndex: primaryDropped ? 1 : 0,
        timeGapToGroupSeconds: primaryGap,
        hasCrashed: primaryCrashed,
        reportedBadLegs: primaryBadLegs,
        dayConditionScore: primaryCondition,
        gcPosition: 1,
        currentOrder: TacticalOrder.holdPosition,
      ),
      TeamRoadRiderProfile(
        riderId: 'r_2',
        riderName: 'Adam Wicelider',
        bibNumber: 2,
        hierarchyRole: TeamHierarchyRole.coLeader,
        groupIndex: coLeaderDropped ? 1 : 0,
        hasCrashed: coLeaderCrashed,
        gcPosition: 4,
        currentOrder: TacticalOrder.holdPosition,
      ),
      const TeamRoadRiderProfile(
        riderId: 'r_3',
        riderName: 'Janek Pomocnik',
        bibNumber: 3,
        hierarchyRole: TeamHierarchyRole.domestique,
        groupIndex: 0,
        currentOrder: TacticalOrder.protectLeader,
        protectingRiderId: 'r_1',
      ),
      const TeamRoadRiderProfile(
        riderId: 'r_4',
        riderName: 'Marek Góral',
        bibNumber: 4,
        hierarchyRole: TeamHierarchyRole.protectedDomestique,
        groupIndex: 0,
        gcPosition: 18,
        currentOrder: TacticalOrder.protectLeader,
        protectingRiderId: 'r_1',
      ),
      const TeamRoadRiderProfile(
        riderId: 'r_5',
        riderName: 'Piotr Bidonowy',
        bibNumber: 5,
        hierarchyRole: TeamHierarchyRole.domestique,
        groupIndex: 0,
        currentOrder: TacticalOrder.fetchBidonsFromCar,
      ),
    ];
  }

  group('TeamLeaderChangeOnTheRoadLogic', () {
    test('utrzymuje głównego lidera #1, gdy nie ma problemów', () {
      final decision = TeamLeaderChangeOnTheRoadLogic.evaluate(
        TeamLeaderChangeInput(
          teamId: 'team_uae',
          teamName: 'Emirates Pro',
          stageKilometer: 112.5,
          totalStageKilometers: 180.0,
          riders: buildStandardSquad(),
        ),
      );

      expect(decision.status, LeaderChangeStatus.primaryInCommand);
      expect(decision.triggerReason, LeaderChangeTriggerReason.none);
      expect(decision.didChangeLeader, isFalse);
      expect(decision.activePriorityLeaderId, 'r_1');
      expect(
        decision.activeLeaderPriorityWeight,
        TeamLeaderChangeOnTheRoadLogic.priorityLeaderWeight,
      );
      expect(decision.reassignedDomestiques, isEmpty);
    });

    test('przekazuje ochronę wiceliderowi #2 po kraksie lidera #1', () {
      final decision = TeamLeaderChangeOnTheRoadLogic.evaluate(
        TeamLeaderChangeInput(
          teamId: 'team_uae',
          teamName: 'Emirates Pro',
          stageKilometer: 134.2,
          totalStageKilometers: 180.0,
          riders: buildStandardSquad(primaryCrashed: true),
        ),
      );

      expect(decision.status, LeaderChangeStatus.coLeaderInCommand);
      expect(decision.triggerReason, LeaderChangeTriggerReason.crash);
      expect(decision.didChangeLeader, isTrue);
      expect(decision.activePriorityLeaderId, 'r_2');
      expect(decision.activePriorityLeaderName, 'Adam Wicelider');
      expect(decision.activeLeaderPriorityWeight, 1.0);
      expect(decision.formerLeaderNewOrder, TacticalOrder.saveEnergy);
      expect(decision.reassignedDomestiques.length, 2);
      expect(
        decision.reassignedDomestiques
            .every((d) => d.newProtectedRiderId == 'r_2'),
        isTrue,
      );
      expect(decision.radioCommunique, contains('kraksie'));

      // Pomocnik zwożący bidony nie jest przerywany.
      final bidonFetcher =
          decision.updatedRiders.firstWhere((r) => r.riderId == 'r_5');
      expect(bidonFetcher.currentOrder, TacticalOrder.fetchBidonsFromCar);
    });

    test('przekazuje ochronę wiceliderowi #2 po utracie kontaktu z grupą', () {
      final decision = TeamLeaderChangeOnTheRoadLogic.evaluate(
        TeamLeaderChangeInput(
          teamId: 'team_uae',
          teamName: 'Emirates Pro',
          stageKilometer: 148.0,
          totalStageKilometers: 180.0,
          dropThresholdSeconds: 20.0,
          riders: buildStandardSquad(primaryDropped: true, primaryGap: 28.5),
        ),
      );

      expect(decision.status, LeaderChangeStatus.coLeaderInCommand);
      expect(
        decision.triggerReason,
        LeaderChangeTriggerReason.droppedFromGroup,
      );
      expect(decision.didChangeLeader, isTrue);
      expect(decision.activePriorityLeaderId, 'r_2');
      expect(decision.reassignedDomestiques.length, 2);
    });

    test('przekazuje ochronę wiceliderowi #2 po komunikacie Bad Legs przez radio',
        () {
      final decision = TeamLeaderChangeOnTheRoadLogic.evaluate(
        TeamLeaderChangeInput(
          teamId: 'team_uae',
          teamName: 'Emirates Pro',
          stageKilometer: 155.0,
          totalStageKilometers: 180.0,
          riders: buildStandardSquad(
            primaryBadLegs: true,
            primaryCondition: -4,
          ),
        ),
      );

      expect(decision.status, LeaderChangeStatus.coLeaderInCommand);
      expect(
        decision.triggerReason,
        LeaderChangeTriggerReason.badLegsRadioReport,
      );
      expect(decision.didChangeLeader, isTrue);
      expect(decision.activePriorityLeaderId, 'r_2');
      expect(decision.radioCommunique, contains('Bad Legs'));
    });

    test('applyToRiderRaceStates aktualizuje rozkazy w RiderRaceState', () {
      final decision = TeamLeaderChangeOnTheRoadLogic.evaluate(
        TeamLeaderChangeInput(
          teamId: 'team_uae',
          teamName: 'Emirates Pro',
          stageKilometer: 140.0,
          totalStageKilometers: 180.0,
          riders: buildStandardSquad(primaryBadLegs: true),
        ),
      );

      final initialStates = [
        RiderRaceState.initial(
          riderId: 'r_1',
          teamId: 'team_uae',
          initialWPrimeJoules: 20000,
          initialGlycogenGrams: 400,
          initialOrder: TacticalOrder.holdPosition,
        ),
        RiderRaceState.initial(
          riderId: 'r_2',
          teamId: 'team_uae',
          initialWPrimeJoules: 19000,
          initialGlycogenGrams: 400,
          initialOrder: TacticalOrder.protectLeader,
        ),
        RiderRaceState.initial(
          riderId: 'r_3',
          teamId: 'team_uae',
          initialWPrimeJoules: 17000,
          initialGlycogenGrams: 400,
          initialOrder: TacticalOrder.holdPosition,
        ),
      ];

      final updatedStates =
          TeamLeaderChangeOnTheRoadLogic.applyToRiderRaceStates(
        raceStates: initialStates,
        decision: decision,
      );

      expect(
        updatedStates.firstWhere((s) => s.riderId == 'r_1').activeTacticalOrder,
        TacticalOrder.saveEnergy,
      );
      expect(
        updatedStates.firstWhere((s) => s.riderId == 'r_2').activeTacticalOrder,
        TacticalOrder.followWheels,
      );
      expect(
        updatedStates.firstWhere((s) => s.riderId == 'r_3').activeTacticalOrder,
        TacticalOrder.protectLeader,
      );
    });

    test('przechodzi na rezerwowego kapitana, gdy nr 1 i nr 2 są niedostępni',
        () {
      final decision = TeamLeaderChangeOnTheRoadLogic.evaluate(
        TeamLeaderChangeInput(
          teamId: 'team_uae',
          teamName: 'Emirates Pro',
          stageKilometer: 160.0,
          totalStageKilometers: 180.0,
          riders: buildStandardSquad(
            primaryCrashed: true,
            coLeaderDropped: true,
          ),
        ),
      );

      expect(decision.status, LeaderChangeStatus.fallbackCaptainInCommand);
      expect(decision.activePriorityLeaderId, 'r_4');
      expect(
        decision.activeLeaderPriorityWeight,
        TeamLeaderChangeOnTheRoadLogic.fallbackCaptainWeight,
      );
    });

    test('przywraca lidera #1 po powrocie, gdy allowRestorePrimaryIfRecovered=true',
        () {
      final decision = TeamLeaderChangeOnTheRoadLogic.evaluate(
        TeamLeaderChangeInput(
          teamId: 'team_uae',
          teamName: 'Emirates Pro',
          stageKilometer: 150.0,
          totalStageKilometers: 180.0,
          allowRestorePrimaryIfRecovered: true,
          previousActiveLeaderId: 'r_2',
          previousStatus: LeaderChangeStatus.coLeaderInCommand,
          riders: buildStandardSquad(),
        ),
      );

      expect(decision.status, LeaderChangeStatus.restoredToPrimary);
      expect(decision.didChangeLeader, isTrue);
      expect(decision.activePriorityLeaderId, 'r_1');
    });

    test('obsługuje pustą listę kolarzy i serializację JSON', () {
      final emptyDecision = TeamLeaderChangeOnTheRoadLogic.evaluate(
        const TeamLeaderChangeInput(
          teamId: 'team_empty',
          teamName: 'Empty Team',
          stageKilometer: 10.0,
          totalStageKilometers: 100.0,
          riders: [],
        ),
      );
      expect(emptyDecision.status, LeaderChangeStatus.noViableLeader);
      expect(emptyDecision.activePriorityLeaderId, isNull);

      final profile = buildStandardSquad().first;
      final restored = TeamRoadRiderProfile.fromJson(profile.toJson());
      expect(restored.riderId, profile.riderId);
      expect(restored.hierarchyRole, profile.hierarchyRole);
      expect(restored.bibNumber, profile.bibNumber);
    });
  });

  group('TeamLeaderChangeStatusPanel UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnienia w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          bool overrideTapped = false;

          final decision = TeamLeaderChangeOnTheRoadLogic.evaluate(
            TeamLeaderChangeInput(
              teamId: 'team_uae',
              teamName: 'Emirates Pro',
              stageKilometer: 134.2,
              totalStageKilometers: 180.0,
              riders: buildStandardSquad(primaryCrashed: true),
            ),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF0F1115),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: TeamLeaderChangeStatusPanel(
                    decision: decision,
                    onTriggerBadLegsOverride: () {
                      overrideTapped = true;
                    },
                    onRestorePrimaryLeader: () {
                      overrideTapped = true;
                    },
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('HIERARCHIA NA SZOSIE'), findsOneWidget);
          expect(find.textContaining('Adam Wicelider'), findsWidgets);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Przywróć Lidera #1'));
          await tester.pump(const Duration(milliseconds: 250));
          expect(overrideTapped, isTrue);
        },
      );
    }
  });
}
