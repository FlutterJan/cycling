import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/live_team_car_gap_indicator_hud.dart';

void main() {
  group('TeamCarGapTelemetryData', () {
    test('activates Barrage Active when leader group gap is below 60s', () {
      const TeamCarGapTelemetryData data = TeamCarGapTelemetryData(
        riderName: 'Tadej Kowalski',
        teamShortCode: 'PLM',
        dsCarNumber: 2,
        leaderGroupGapToPelotonSeconds: 42.5,
        teamCarDistanceMeters: 380.0,
        teamCarGapSeconds: 26.0,
      );

      expect(data.barrageStatus, TeamCarBarrageStatus.barrageActive);
      expect(data.isBarrageActive, isTrue);
      expect(data.secondsToLiftBarrage, closeTo(17.5, 0.001));
      expect(data.barrageThresholdProgress, closeTo(42.5 / 60.0, 0.001));

      final double wheelEta =
          data.estimateServiceEtaSeconds(TeamCarServiceRequestType.wheelChange);
      final double bidonEta =
          data.estimateServiceEtaSeconds(TeamCarServiceRequestType.bidonFeed);

      expect(
        wheelEta,
        greaterThan(
          data
              .copyWith(leaderGroupGapToPelotonSeconds: 65.0)
              .estimateServiceEtaSeconds(TeamCarServiceRequestType.wheelChange),
        ),
      );
      expect(
        bidonEta,
        greaterThan(
          data
              .copyWith(leaderGroupGapToPelotonSeconds: 65.0)
              .estimateServiceEtaSeconds(TeamCarServiceRequestType.bidonFeed),
        ),
      );
    });

    test('opens convoy when leader group gap is at or above 60s', () {
      const TeamCarGapTelemetryData data = TeamCarGapTelemetryData(
        riderName: 'Jan Nowak',
        teamShortCode: 'POL',
        dsCarNumber: 1,
        leaderGroupGapToPelotonSeconds: 60.0,
        teamCarDistanceMeters: 22.0,
        teamCarGapSeconds: 1.5,
      );

      expect(data.barrageStatus, TeamCarBarrageStatus.cleared);
      expect(data.isBarrageActive, isFalse);
      expect(data.secondsToLiftBarrage, 0.0);
      expect(data.barrageThresholdProgress, 1.0);
    });

    test('handles peloton, disabled, and invalid numeric edge cases safely',
        () {
      const TeamCarGapTelemetryData pelotonData = TeamCarGapTelemetryData(
        riderName: 'Marek Zielinski',
        teamShortCode: 'VLA',
        dsCarNumber: 0,
        leaderGroupGapToPelotonSeconds: double.nan,
        teamCarDistanceMeters: double.infinity,
        teamCarGapSeconds: -12.0,
        isRiderAheadOfPeloton: false,
      );

      expect(pelotonData.barrageStatus, TeamCarBarrageStatus.convoyBehindPeloton);
      expect(pelotonData.safeDsCarNumber, 1);
      expect(pelotonData.safeLeaderGapSeconds, 0.0);
      expect(pelotonData.safeCarDistanceMeters, 0.0);
      expect(pelotonData.safeCarGapSeconds, 0.0);

      final TeamCarGapTelemetryData disabledData =
          pelotonData.copyWith(isEnabled: false);
      expect(disabledData.barrageStatus, TeamCarBarrageStatus.disabled);
    });
  });

  group('LiveTeamCarGapIndicatorHud', () {
    testWidgets('displays BARRAGE ACTIVE and handles service requests',
        (WidgetTester tester) async {
      TeamCarServiceRequestType? requested;
      bool cancelled = false;

      const TeamCarGapTelemetryData barrageData = TeamCarGapTelemetryData(
        riderName: 'Michał Kwiatkowski',
        teamShortCode: 'IGD',
        dsCarNumber: 3,
        leaderGroupGapToPelotonSeconds: 38.0,
        teamCarDistanceMeters: 410.0,
        teamCarGapSeconds: 28.0,
        activeRequest: TeamCarServiceRequestType.wheelChange,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: LiveTeamCarGapIndicatorHud(
                data: barrageData,
                onRequestService: (TeamCarServiceRequestType type) {
                  requested = type;
                },
                onCancelRequest: () {
                  cancelled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('BARRAGE ACTIVE'), findsOneWidget);
      expect(find.text('Michał Kwiatkowski'), findsOneWidget);
      expect(find.text('WÓZ TECHNICZNY #3'), findsOneWidget);
      expect(find.textContaining('Wezwano: Wymiana koła'), findsOneWidget);

      await tester.tap(find.text('Bidony / Żele'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(requested, TeamCarServiceRequestType.bidonFeed);

      await tester.tap(find.text('Anuluj'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(cancelled, isTrue);
    });

    testWidgets('ignores interactions when disabled and toggles collapse',
        (WidgetTester tester) async {
      TeamCarServiceRequestType? requested;

      const TeamCarGapTelemetryData openData = TeamCarGapTelemetryData(
        riderName: 'Rafał Majka',
        teamShortCode: 'UAD',
        dsCarNumber: 1,
        leaderGroupGapToPelotonSeconds: 85.0,
        teamCarDistanceMeters: 18.0,
        teamCarGapSeconds: 1.2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: LiveTeamCarGapIndicatorHud(
                data: openData,
                enabled: false,
                onRequestService: (TeamCarServiceRequestType type) {
                  requested = type;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CONVOY OPEN'), findsOneWidget);
      await tester.tap(find.text('Wymiana koła'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(requested, isNull);
    });

    for (final Size viewportSize in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          const TeamCarGapTelemetryData data = TeamCarGapTelemetryData(
            riderName: 'Bartosz Huzarski',
            teamShortCode: 'BORA',
            dsCarNumber: 4,
            leaderGroupGapToPelotonSeconds: 51.0,
            teamCarDistanceMeters: 310.0,
            teamCarGapSeconds: 21.5,
          );

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: LiveTeamCarGapIndicatorHud(data: data),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(LiveTeamCarGapIndicatorHud), findsOneWidget);
        },
      );
    }
  });
}
