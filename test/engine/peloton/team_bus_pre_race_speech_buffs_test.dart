import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/team_bus_pre_race_speech_buffs.dart';

void main() {
  group('TeamBusPreRaceSpeechBuffs engine', () {
    test('calmTacticalAnalysis lowers resting HR and boosts stress resilience',
        () {
      final summary = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.calmTacticalAnalysis,
        leaderTopic: null,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );

      expect(summary.riderBuffs.length, 5);
      expect(summary.avgRestingHrDeltaBpm, lessThan(0.0));
      expect(summary.avgStressResilienceDelta, greaterThan(0.10));
      expect(summary.avgInitialMoraleDelta, closeTo(6.0, 0.01));

      final leader = summary.riderBuffs
          .firstWhere((b) => b.role == BusRiderRole.leader);
      expect(leader.restingHeartRateDeltaBpm, -4);
      expect(leader.pelotonStressResilienceDelta, closeTo(0.16, 0.001));
    });

    test('emotionalAllInMobilization boosts morale but raises HR & lowers resilience',
        () {
      final summary = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.emotionalAllInMobilization,
        leaderTopic: null,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );

      expect(summary.avgInitialMoraleDelta, greaterThan(13.0));
      expect(summary.avgRestingHrDeltaBpm, greaterThan(2.5));
      expect(summary.avgStressResilienceDelta, lessThan(0.0));
    });

    test('relieveYouthPressure gives strongest buff to U23 / youngTalent riders',
        () {
      final summary = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.relieveYouthPressure,
        leaderTopic: null,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );

      final young = summary.riderBuffs
          .firstWhere((b) => b.role == BusRiderRole.youngTalent);
      final vet = summary.riderBuffs
          .firstWhere((b) => b.role == BusRiderRole.domestique);

      expect(young.restingHeartRateDeltaBpm, -4);
      expect(young.pelotonStressResilienceDelta, closeTo(0.18, 0.001));
      expect(young.initialMoraleDelta, closeTo(15.0, 0.01));
      expect(young.initialMoraleDelta, greaterThan(vet.initialMoraleDelta));
    });

    test('demandFullSacrificeForLeader boosts domestiques & leader, tensions freeRole',
        () {
      final summary = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.demandFullSacrificeForLeader,
        leaderTopic: null,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );

      final leader = summary.riderBuffs
          .firstWhere((b) => b.role == BusRiderRole.leader);
      final domestique = summary.riderBuffs
          .firstWhere((b) => b.role == BusRiderRole.domestique);
      final freeRole = summary.riderBuffs
          .firstWhere((b) => b.role == BusRiderRole.freeRole);

      expect(leader.initialMoraleDelta, closeTo(12.0, 0.01));
      expect(domestique.pelotonStressResilienceDelta, closeTo(0.15, 0.001));
      expect(domestique.initialMoraleDelta, closeTo(10.0, 0.01));
      expect(freeRole.initialMoraleDelta, closeTo(-2.0, 0.01));
    });

    test('leader one-on-one topics apply targeted modifiers and team ripple',
        () {
      final calmPlusNerves = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.calmTacticalAnalysis,
        leaderTopic: LeaderOneOnOneTopic.manageHeartRateAndNerves,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );
      expect(calmPlusNerves.leaderRestingHrDeltaBpm, -7);
      expect(calmPlusNerves.leaderStressResilienceDelta, closeTo(0.24, 0.001));

      final leadByExample = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.calmTacticalAnalysis,
        leaderTopic: LeaderOneOnOneTopic.leadByExampleForTeam,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );
      final domestique = leadByExample.riderBuffs
          .firstWhere((b) => b.role == BusRiderRole.domestique);
      expect(domestique.initialMoraleDelta, closeTo(8.0, 0.01));
    });

    test('handles empty squad and clamps extreme baseline values safely', () {
      final emptySummary = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.calmTacticalAnalysis,
        squad: const [],
      );
      expect(emptySummary.riderBuffs, isEmpty);
      expect(emptySummary.avgRestingHrDeltaBpm, 0.0);

      const extremeRider = PreRaceBusRiderProfile(
        riderId: 'ext',
        name: 'Extreme',
        age: 20,
        role: BusRiderRole.youngTalent,
        baselineRestingHrBpm: 33,
        baselineStressResilience: 0.96,
        baselineMorale: 96.0,
      );
      final buff = TeamBusPreRaceSpeechBuffs.evaluateRiderBuff(
        rider: extremeRider,
        tone: ManagerSpeechTone.relieveYouthPressure,
      );
      expect(buff.effectiveRestingHrBpm, 32);
      expect(buff.effectiveStressResilience, 1.0);
      expect(buff.effectiveInitialMorale, 100.0);
    });
  });

  group('TeamBusPreRaceSpeechPanel widget', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      ValueChanged<TeamBusSpeechBuffSummary>? onConfirmed,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamBusPreRaceSpeechPanel(
              onBriefingConfirmed: onConfirmed,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844, 1024x768, and 1600x900 without overflow',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size);
        expect(find.text('Odprawa w autobusie drużyny'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('allows selecting tone, leader topic, confirming, and reopening',
        (tester) async {
      TeamBusSpeechBuffSummary? confirmedSummary;
      await pumpPanelAtSize(
        tester,
        const Size(1280, 900),
        onConfirmed: (summary) => confirmedSummary = summary,
      );

      final allInCard = find.byKey(
        const ValueKey('speech_tone_emotionalAllInMobilization'),
      );
      await tester.ensureVisible(allInCard);
      await tester.tap(allInCard);
      await tester.pump(const Duration(milliseconds: 300));

      final topicCard = find.byKey(
        const ValueKey('leader_topic_leadByExampleForTeam'),
      );
      await tester.ensureVisible(topicCard);
      await tester.tap(topicCard);
      await tester.pump(const Duration(milliseconds: 300));

      final confirmBtn = find.byKey(const ValueKey('confirm_bus_briefing_btn'));
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmedSummary, isNotNull);
      expect(
        confirmedSummary!.selectedTone,
        ManagerSpeechTone.emotionalAllInMobilization,
      );
      expect(
        confirmedSummary!.leaderTopic,
        LeaderOneOnOneTopic.leadByExampleForTeam,
      );
      expect(confirmedSummary!.isBriefingLocked, isTrue);
      expect(find.text('ODPRAWA ZATWIERDZONA'), findsOneWidget);

      final reopenBtn = find.byKey(const ValueKey('reopen_bus_briefing_btn'));
      await tester.ensureVisible(reopenBtn);
      await tester.tap(reopenBtn);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('PRZED STARTEM'), findsOneWidget);
    });
  });
}
