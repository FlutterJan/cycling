import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';
import 'package:pro_peloton_manager/state/career_state_notifier.dart';
import 'package:pro_peloton_manager/ui/screens/pre_season_team_presentation_screen.dart';
import 'package:pro_peloton_manager/ui/widgets/bike_preview_painter.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_avatar_painter.dart';

class _TestCareerStateNotifier extends CareerStateNotifier {
  _TestCareerStateNotifier() {
    final rng = math.Random(42);
    final r1 = RiderProceduralGenerator.generateRider(
      id: 'r_gc',
      specialization: RiderSpecialization.gcClimber,
      age: 27,
      targetOverallRating: 88,
      teamId: state.playerTeamId,
      role: RiderRole.teamLeader,
      random: rng,
    );
    final r2 = RiderProceduralGenerator.generateRider(
      id: 'r_sprint',
      specialization: RiderSpecialization.pureSprinter,
      age: 26,
      targetOverallRating: 86,
      teamId: state.playerTeamId,
      role: RiderRole.coLeader,
      random: rng,
    );
    final r3 = RiderProceduralGenerator.generateRider(
      id: 'r_classic',
      specialization: RiderSpecialization.classicCobbles,
      age: 28,
      targetOverallRating: 84,
      teamId: state.playerTeamId,
      role: RiderRole.coLeader,
      random: rng,
    );
    final r4 = RiderProceduralGenerator.generateRider(
      id: 'r_u23',
      specialization: RiderSpecialization.puncher,
      age: 21,
      targetOverallRating: 75,
      teamId: state.playerTeamId,
      role: RiderRole.domestique,
      random: rng,
    );

    final roster = [r1, r2, r3, r4];
    state = state.copyWith(
      riders: roster,
      playerTeam: state.playerTeam.copyWith(
        rosterRiderIds: roster.map((r) => r.id).toList(),
      ),
    );
  }
}

void main() {
  Widget buildTestApp({
    VoidCallback? onSeasonStarted,
  }) {
    return ProviderScope(
      overrides: [
        careerStateNotifierProvider.overrideWith(
          (ref) => _TestCareerStateNotifier(),
        ),
      ],
      child: MaterialApp(
        home: PreSeasonTeamPresentationScreen(
          onSeasonStarted: onSeasonStarted,
        ),
      ),
    );
  }

  for (final size in const [
    Size(390, 844),
    Size(1024, 768),
    Size(1600, 900),
  ]) {
    testWidgets(
      'PreSeasonTeamPresentationScreen renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(PreSeasonTeamPresentationScreen), findsOneWidget);
        expect(find.byType(BikePreviewWidget), findsOneWidget);
        expect(find.byType(RiderAvatarWidget), findsWidgets);
        expect(find.text('ROZPOCZNIJ SEZON WYŚCIGOWY'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Confirming numbers & roles enables start button, creates press inbox article and invokes callback',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = _TestCareerStateNotifier();
      var started = false;
      final initialInboxCount = notifier.state.inboxMessages.length;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            careerStateNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: PreSeasonTeamPresentationScreen(
              onSeasonStarted: () => started = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final confirmFinder = find.text('ZATWIERDŹ NUMERY I ROLE');
      await tester.ensureVisible(confirmFinder);
      await tester.tap(confirmFinder);
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('NUMERY I ROLE ZATWIERDZONE'), findsOneWidget);

      final startFinder = find.text('ROZPOCZNIJ SEZON WYŚCIGOWY');
      await tester.ensureVisible(startFinder);
      await tester.tap(startFinder);
      await tester.pump(const Duration(milliseconds: 150));

      expect(started, isTrue);
      final updatedInbox = notifier.state.inboxMessages;
      expect(updatedInbox.length, initialInboxCount + 1);
      expect(
        updatedInbox.first.subject,
        contains('Oficjalna prezentacja'),
      );
    },
  );
}
