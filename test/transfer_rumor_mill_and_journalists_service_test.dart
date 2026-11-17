import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/services/career/transfer_rumor_mill_and_journalists_service.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

void main() {
  late WorldTourGenerationResult world;
  late TransferRumorMillAndJournalistsService service;

  setUpAll(() {
    world = WorldTeamsGenerator.generateWorldTourSystem(seed: 468);
    service = const TransferRumorMillAndJournalistsService();
  });

  group('TransferRumorMillAndJournalistsService', () {
    test('creates default journalists and serializes state round-trip 1:1', () {
      final initial = TransferRumorMillState.initial();
      expect(initial.journalists.length, 8);
      expect(initial.mediaCredibilityScore, 72);

      final json = initial.toJson();
      final decoded = TransferRumorMillState.fromJson(json);
      expect(decoded.journalists.length, initial.journalists.length);
      expect(decoded.journalists.first.name, initial.journalists.first.name);
      expect(decoded.mediaCredibilityScore, initial.mediaCredibilityScore);
      expect(decoded.marketHeatIndex, initial.marketHeatIndex);
    });

    test('tickDailyRumorMill generates rumors, expires old ones, and impacts morale', () {
      final playerTeam = world.worldTourTeams.first;
      final playerSquad = world.getTeamRoster(playerTeam.id);
      final rivalSquad = world.getTeamRoster(world.worldTourTeams[1].id);
      final now = DateTime(2026, 8, 15);

      // Dodajemy wygasającą plotkę
      final expiredRumor = TransferRumor(
        id: 'old_1',
        targetRiderId: rivalSquad.first.id,
        targetRiderName: rivalSquad.first.fullName,
        targetRiderRole: rivalSquad.first.contract.role,
        sourceTeamId: world.worldTourTeams[1].id,
        sourceTeamName: world.worldTourTeams[1].name,
        rumoredDestinationTeamId: playerTeam.id,
        rumoredDestinationTeamName: playerTeam.name,
        journalistId: 'j_daniel_benson',
        journalistName: 'Daniel Vermeer',
        journalistHandle: '@VermeerCycling',
        credibilityAtPublish: 91,
        veracity: RumorVeracityTier.credible,
        status: RumorStatus.active,
        playerResponse: RumorActionType.none,
        headline: 'Stara plotka',
        body: 'Test',
        createdDate: DateTime(2026, 8, 1),
        expiresDate: DateTime(2026, 8, 10),
        isPlayerTeamInvolved: true,
        estimatedSalaryEur: 500000,
        marketHeatDelta: 5,
      );

      final startState = TransferRumorMillState.initial().copyWith(
        activeRumors: [expiredRumor],
        marketHeatIndex: 85,
      );

      DailyRumorTickResult? tickResult;
      for (var i = 0; i < 6; i++) {
        tickResult = service.tickDailyRumorMill(
          currentState: tickResult?.nextState ?? startState,
          currentDate: now.add(Duration(days: i)),
          playerTeam: playerTeam,
          playerSquad: tickResult?.updatedPlayerSquad ?? playerSquad,
          allTeams: world.teams,
          marketRiders: rivalSquad,
          randomSeed: 100 + i,
        );
      }

      expect(tickResult, isNotNull);
      expect(
        tickResult!.nextState.archivedRumors.any((r) => r.id == 'old_1'),
        isTrue,
      );
      expect(tickResult.nextState.activeRumors, isNotEmpty);
    });

    test('plantSmokescreen creates campaign, decoy rumor, and negotiation bonus', () {
      final playerTeam = world.worldTourTeams.first;
      final playerSquad = world.getTeamRoster(playerTeam.id);
      final rivalRiders = world.getTeamRoster(world.worldTourTeams[2].id);
      final decoy = rivalRiders.first;
      final realTarget = rivalRiders[1];
      final state = TransferRumorMillState.initial();
      final journalist = state.journalists.first;

      final planted = service.plantSmokescreen(
        currentState: state,
        currentDate: DateTime(2026, 8, 20),
        playerTeam: playerTeam,
        playerSquad: playerSquad,
        decoyRider: decoy,
        realTargetRider: realTarget,
        decoyCurrentTeamName: world.worldTourTeams[2].name,
        journalist: journalist,
        objective: SmokescreenObjective.protectRealTarget,
        durationDays: 10,
      );

      expect(planted.plantedRumor.isSmokescreen, isTrue);
      expect(planted.plantedRumor.veracity, RumorVeracityTier.smokescreen);
      expect(planted.campaign.isActive, isTrue);
      expect(planted.nextState.activeSmokescreens.length, 1);

      final bonus = service.calculateSmokescreenNegotiationBonus(
        state: planted.nextState,
        targetRiderId: realTarget.id,
      );
      expect(bonus, greaterThan(0.0));
      expect(bonus, lessThanOrEqualTo(15.0));
    });

    test('respondToRumor deny calms threatened squad morale and archives rumor', () {
      final playerTeam = world.worldTourTeams.first;
      final playerSquad = world.getTeamRoster(playerTeam.id);
      final leader = playerSquad.firstWhere(
        (r) => r.contract.role == RiderRole.teamLeader,
        orElse: () => playerSquad.first,
      );
      final normalizedLeader = leader.copyWith(
        contract: leader.contract.copyWith(
          role: RiderRole.teamLeader,
          morale: 65.0,
        ),
      );
      final squad = [
        normalizedLeader,
        ...playerSquad.where((r) => r.id != leader.id),
      ];

      final rivalLeader = world.getTeamRoster(world.worldTourTeams[3].id).first;
      final incomingLeaderRumor = TransferRumor(
        id: 'rumor_threat_1',
        targetRiderId: rivalLeader.id,
        targetRiderName: rivalLeader.fullName,
        targetRiderRole: RiderRole.teamLeader,
        sourceTeamId: world.worldTourTeams[3].id,
        sourceTeamName: world.worldTourTeams[3].name,
        rumoredDestinationTeamId: playerTeam.id,
        rumoredDestinationTeamName: playerTeam.name,
        journalistId: 'j_marco_gazzetta',
        journalistName: 'Marco Bellini',
        journalistHandle: '@BelliniGazzetta',
        credibilityAtPublish: 52,
        veracity: RumorVeracityTier.baseless,
        status: RumorStatus.active,
        playerResponse: RumorActionType.none,
        headline: 'Nowy lider w drodze?',
        body: 'Sensacyjne doniesienia z Włoch.',
        createdDate: DateTime(2026, 8, 21),
        expiresDate: DateTime(2026, 8, 28),
        isPlayerTeamInvolved: true,
        estimatedSalaryEur: 1200000,
        marketHeatDelta: 8,
      );

      final state = TransferRumorMillState.initial().copyWith(
        activeRumors: [incomingLeaderRumor],
      );

      final res = service.respondToRumor(
        currentState: state,
        rumorId: 'rumor_threat_1',
        action: RumorActionType.deny,
        playerTeam: playerTeam,
        playerSquad: squad,
        currentDate: DateTime(2026, 8, 22),
      );

      expect(res.outcome.updatedRumor.status, RumorStatus.denied);
      expect(res.nextState.activeRumors, isEmpty);
      expect(res.nextState.archivedRumors.length, 1);
      final updatedLeader = res.outcome.updatedSquad
          .firstWhere((r) => r.id == normalizedLeader.id);
      expect(updatedLeader.contract.morale, greaterThan(65.0));
    });
  });

  group('TransferRumorMillPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        final playerTeam = world.worldTourTeams.first;
        final playerSquad = world.getTeamRoster(playerTeam.id);
        final market = world.getTeamRoster(world.worldTourTeams[1].id);

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: TransferRumorMillPanel(
                    playerTeam: playerTeam,
                    playerSquad: playerSquad,
                    marketCandidates: market.take(5).toList(),
                    currentDate: DateTime(2026, 8, 22),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Transfer Rumor Mill'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Zasłona Dymna'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Konfigurator Zasłony Dymnej'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
