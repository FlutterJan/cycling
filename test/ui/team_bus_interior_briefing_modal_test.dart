import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/team_bus_pre_race_speech_buffs.dart';
import 'package:pro_peloton_manager/ui/widgets/team_bus_interior_briefing_modal.dart';

void main() {
  group('TeamBusInteriorBriefingData & Logic', () {
    test('serializes and deserializes to/from JSON cleanly', () {
      final original = TeamBusInteriorBriefingData.demo();
      final json = original.toJson();
      final decoded = TeamBusInteriorBriefingData.fromJson(json);

      expect(decoded.teamName, original.teamName);
      expect(decoded.raceName, original.raceName);
      expect(decoded.stageName, original.stageName);
      expect(decoded.distanceKm, original.distanceKm);
      expect(decoded.elevationGainM, original.elevationGainM);
      expect(decoded.elevationSamplesM.length, original.elevationSamplesM.length);
      expect(decoded.keyMarkers.length, original.keyMarkers.length);
      expect(decoded.squad.length, original.squad.length);
      expect(decoded.initialTone, original.initialTone);
    });

    test('resolveExpression maps tones and rider deltas accurately', () {
      final buffsCalm = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.calmTacticalAnalysis,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );
      expect(
        TeamBusInteriorBriefingModal.resolveExpression(
          buff: buffsCalm.riderBuffs.first,
          tone: ManagerSpeechTone.calmTacticalAnalysis,
        ),
        BusRiderFacialExpression.calmFocused,
      );

      final buffsEmotional = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.emotionalAllInMobilization,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );
      final youngBuff = buffsEmotional.riderBuffs.firstWhere(
        (b) => b.role == BusRiderRole.youngTalent,
      );
      expect(
        TeamBusInteriorBriefingModal.resolveExpression(
          buff: youngBuff,
          tone: ManagerSpeechTone.emotionalAllInMobilization,
        ),
        BusRiderFacialExpression.tenseNervous,
      );

      final buffsYouth = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.relieveYouthPressure,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );
      final relievedYoung = buffsYouth.riderBuffs.firstWhere(
        (b) => b.role == BusRiderRole.youngTalent,
      );
      expect(
        TeamBusInteriorBriefingModal.resolveExpression(
          buff: relievedYoung,
          tone: ManagerSpeechTone.relieveYouthPressure,
        ),
        BusRiderFacialExpression.relievedSmiling,
      );

      final buffsSacrifice = TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: ManagerSpeechTone.demandFullSacrificeForLeader,
        squad: TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
      );
      final leaderBuff = buffsSacrifice.riderBuffs.firstWhere(
        (b) => b.role == BusRiderRole.leader,
      );
      expect(
        TeamBusInteriorBriefingModal.resolveExpression(
          buff: leaderBuff,
          tone: ManagerSpeechTone.demandFullSacrificeForLeader,
        ),
        BusRiderFacialExpression.determinedCaptain,
      );
    });
  });

  group('TeamBusInteriorBriefingModal Widget Tests', () {
    Future<void> pumpModal(
      WidgetTester tester, {
      required Size size,
      TeamBusInteriorBriefingData? data,
      bool isDisabled = false,
      ValueChanged<TeamBusSpeechBuffSummary>? onConfirm,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: TeamBusInteriorBriefingModal(
              data: data ?? TeamBusInteriorBriefingData.demo(),
              isDisabled: isDisabled,
              onConfirm: onConfirm,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders responsively without overflow at 390x844, 1024x768, 1600x900',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpModal(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(
          find.text('AUTOBUS DRUŻYNY • ODPRAWA PRZEDSTARTOWA'),
          findsOneWidget,
        );
        expect(find.text('M. Kowalski'), findsOneWidget);
      }
    });

    testWidgets('selecting speech tone and leader topic updates UI and confirms',
        (tester) async {
      TeamBusSpeechBuffSummary? confirmedSummary;
      await pumpModal(
        tester,
        size: const Size(1600, 900),
        onConfirm: (summary) => confirmedSummary = summary,
      );

      await tester.tap(find.text(ManagerSpeechTone.relieveYouthPressure.labelPl));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ulga i uśmiech'), findsWidgets);

      await tester.tap(
        find.text(LeaderOneOnOneTopic.manageHeartRateAndNerves.labelPl),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Odpowiedź lidera:'),
        findsOneWidget,
      );

      await tester.tap(find.text('Wyjdź na linię startu'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmedSummary, isNotNull);
      expect(
        confirmedSummary!.selectedTone,
        ManagerSpeechTone.relieveYouthPressure,
      );
      expect(
        confirmedSummary!.leaderTopic,
        LeaderOneOnOneTopic.manageHeartRateAndNerves,
      );
      expect(confirmedSummary!.isBriefingLocked, isTrue);
      expect(find.text('GOTOWI DO STARTU'), findsOneWidget);
    });

    testWidgets('handles empty squad and disabled state gracefully',
        (tester) async {
      TeamBusSpeechBuffSummary? confirmedSummary;
      const emptySquadData = TeamBusInteriorBriefingData(
        teamName: 'Empty Squad FC',
        raceName: 'Test Race',
        stageName: 'Start → Meta',
        stageTypeLabel: 'Płaski',
        distanceKm: 140.0,
        elevationGainM: 450,
        weatherLabel: 'Bezchmurnie',
        temperatureC: 20,
        elevationSamplesM: [100, 120, 110],
        keyMarkers: [],
        squad: [],
      );

      await pumpModal(
        tester,
        size: const Size(1024, 768),
        data: emptySquadData,
        isDisabled: true,
        onConfirm: (summary) => confirmedSummary = summary,
      );

      expect(
        find.text('Brak kolarzy przypisanych do autobusu na ten etap.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Wyjdź na linię startu'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(confirmedSummary, isNull);
    });
  });
}
