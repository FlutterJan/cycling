import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/pro_cyclist_career_state.dart';
import 'package:pro_peloton_manager/services/career/ds_team_orders_mission_generator.dart';
import 'package:pro_peloton_manager/ui/widgets/be_a_pro_ds_objective_hud_tracker.dart';

void main() {
  BeAProDsObjectiveHudData buildSampleData({
    BeAProDsObjectiveHudStatus status = BeAProDsObjectiveHudStatus.active,
    double currentValue = 255.0,
    double targetValue = 300.0,
    ProtectedLeaderBeaconData? beacon = const ProtectedLeaderBeaconData(
      leaderName: 'M. Kowalski',
      leaderNumber: 11,
      distanceMeters: 6.4,
      bearingAngleRadians: 0.45,
      elevationDeltaMeters: 1.2,
      protectionRadiusMeters: 8.0,
      groupLabel: 'Główny Peleton',
    ),
  }) {
    return BeAProDsObjectiveHudData(
      missionId: 'mission_318',
      directorName: 'J. Nowak',
      roleStatus: BeAProRoleStatus.trustedDomestique,
      assignmentType: ProCyclistAssignmentType.protectLeader,
      triggerPhase: DsMissionTriggerPhase.crosswindZone,
      objectiveTitle: 'Praca na czele peletonu',
      radioOrderText:
          'Utrzymuj 340 W na czele grupy przez 5 minut i pilnuj koła lidera!',
      progressLabel: 'Czas ciągnięcia peletonu',
      currentValue: currentValue,
      targetValue: targetValue,
      unitLabel: 'min',
      formatAsDuration: true,
      targetPowerWatts: 340,
      currentPowerWatts: 348,
      liveXpEarned: 420,
      bonusXpOnCompletion: 250,
      xpPerMinuteRate: 48.0,
      dsTrustDeltaPreview: 4.5,
      status: status,
      leaderBeacon: beacon,
    );
  }

  group('BeAProDsObjectiveHudData & ProtectedLeaderBeaconData', () {
    test('formats duration progress text and fraction accurately', () {
      final data = buildSampleData(currentValue: 255.0, targetValue: 300.0);

      expect(
        data.formattedProgressText,
        'Czas ciągnięcia peletonu: 4:15 / 5:00 min',
      );
      expect(data.progressFraction, closeTo(0.85, 0.0001));
    });

    test('ProtectedLeaderBeaconData evaluates zone and direction hints', () {
      const aheadBeacon = ProtectedLeaderBeaconData(
        leaderName: 'Lider',
        distanceMeters: 5.0,
        bearingAngleRadians: 0.1,
        protectionRadiusMeters: 8.0,
      );
      expect(aheadBeacon.isInProtectionZone, isTrue);
      expect(aheadBeacon.isCriticallyFar, isFalse);
      expect(aheadBeacon.directionHint, 'Przed Tobą');

      const farRightBeacon = ProtectedLeaderBeaconData(
        leaderName: 'Lider',
        distanceMeters: 24.0,
        bearingAngleRadians: math.pi / 3,
        protectionRadiusMeters: 8.0,
      );
      expect(farRightBeacon.isInProtectionZone, isFalse);
      expect(farRightBeacon.isCriticallyFar, isTrue);
      expect(farRightBeacon.directionHint, 'Z przodu po prawej');
    });

    test('fromMission builds HUD data cleanly', () {
      final mission = DsTeamOrderMission(
        missionId: 'm_1',
        raceId: 'tdf_s5',
        raceName: 'Tour de France',
        stageNumber: 5,
        directorName: 'A. Wiśniewski',
        assignmentType: ProCyclistAssignmentType.pacePeloton,
        triggerPhase: DsMissionTriggerPhase.earlyStage,
        title: 'Kontrola odjazdu',
        radioCallout: 'Jedź równo na czele przez 5 minut.',
        description: 'Kontroluj dystans do ucieczki.',
        targetMetricLabel: 'Czas ciągnięcia peletonu',
        targetValue: 300,
        currentProgress: 120,
        targetPowerWatts: 330,
        rewardTrustDelta: 5.0,
        penaltyTrustDelta: -3.0,
        rewardXp: 300,
        rewardSkillPoints: 1,
        rewardBonusEur: 1500,
        status: ProCyclistAssignmentStatus.inProgress,
        assignedDate: DateTime(2026, 7, 10),
      );

      final hud = BeAProDsObjectiveHudData.fromMission(
        mission: mission,
        roleStatus: BeAProRoleStatus.youngDomestique,
        liveXpEarned: 180,
        formatAsDuration: true,
        unitLabel: 'min',
      );

      expect(hud.missionId, 'm_1');
      expect(hud.formattedProgressText, 'Czas ciągnięcia peletonu: 2:00 / 5:00 min');
      expect(hud.liveXpEarned, 180);
      expect(hud.bonusXpOnCompletion, 300);
      expect(hud.status, BeAProDsObjectiveHudStatus.active);
    });
  });

  group('BeAProDsObjectiveHudTracker widget', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: BeAProDsObjectiveHudTracker(
                      data: buildSampleData(),
                      onAcknowledgeRadioOrder: () {},
                      onLocateLeader: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(BeAProDsObjectiveHudTracker), findsOneWidget);
          expect(
            find.text('Czas ciągnięcia peletonu: 4:15 / 5:00 min'),
            findsOneWidget,
          );
          expect(find.text('6.4 m'), findsOneWidget);
          expect(find.text('+420 XP'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('handles interactions, expand/collapse, and disabled state',
        (tester) async {
      bool radioAcked = false;
      bool leaderLocated = false;
      bool? lastExpanded;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 680,
                child: BeAProDsObjectiveHudTracker(
                  data: buildSampleData(),
                  onAcknowledgeRadioOrder: () => radioAcked = true,
                  onLocateLeader: () => leaderLocated = true,
                  onToggleExpanded: (v) => lastExpanded = v,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Przyjąłem'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(radioAcked, isTrue);

      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump(const Duration(milliseconds: 200));
      expect(leaderLocated, isTrue);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pump(const Duration(milliseconds: 250));
      expect(lastExpanded, isFalse);

      // Disabled state blocks callbacks
      bool disabledAck = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 680,
                child: BeAProDsObjectiveHudTracker(
                  key: const ValueKey('disabled_hud'),
                  data: buildSampleData(
                    status: BeAProDsObjectiveHudStatus.disabled,
                    beacon: null,
                  ),
                  enabled: false,
                  onAcknowledgeRadioOrder: () => disabledAck = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Przyjąłem'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(disabledAck, isFalse);
      expect(
        find.text('Brak przypisanego lidera do ochrony na tym etapie.'),
        findsOneWidget,
      );
    });
  });
}
