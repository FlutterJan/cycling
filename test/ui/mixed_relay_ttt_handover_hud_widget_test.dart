import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/womens_worldtour_and_mixed_relay_model.dart';
import 'package:pro_peloton_manager/ui/screens/mixed_relay_ttt_handover_hud_widget.dart';

MixedRelayCourseSpec _buildCourse() {
  return const MixedRelayCourseSpec(
    eventId: 'uci_wc_mixed_relay_2026',
    eventName: 'UCI World Championships Mixed Relay TTT',
    locationCity: 'Zurich',
    countryIso: 'SUI',
    totalDistanceMeters: 28400.0,
    handoverDistanceMeters: 14200.0,
    handoverApproachZoneMeters: 500.0,
    elevationGainM: 320,
    windSpeedKmh: 16.0,
    temperatureCelsius: 19.5,
  );
}

List<MixedRelayRiderSlot> _buildMensTrio({double baseDist = 13950.0}) {
  return [
    MixedRelayRiderSlot(
      riderId: 'm1',
      fullName: 'Filippo Ganna',
      nationalityIso: 'ITA',
      isFemale: false,
      ftpWatts: 465.0,
      weightKg: 82.0,
      aerodynamicsCda: 0.195,
      timeTrialSkill: 98,
      distanceMeters: baseDist + 4.0,
      currentSpeedKmh: 54.0,
      currentPowerWatts: 495.0,
      wPrimeRemainingPct: 0.62,
      isPulling: true,
    ),
    MixedRelayRiderSlot(
      riderId: 'm2',
      fullName: 'Edoardo Affini',
      nationalityIso: 'ITA',
      isFemale: false,
      ftpWatts: 440.0,
      weightKg: 79.0,
      aerodynamicsCda: 0.201,
      timeTrialSkill: 92,
      distanceMeters: baseDist,
      currentSpeedKmh: 54.0,
      currentPowerWatts: 410.0,
      wPrimeRemainingPct: 0.74,
    ),
    MixedRelayRiderSlot(
      riderId: 'm3',
      fullName: 'Mattia Cattaneo',
      nationalityIso: 'ITA',
      isFemale: false,
      ftpWatts: 415.0,
      weightKg: 71.0,
      aerodynamicsCda: 0.208,
      timeTrialSkill: 87,
      distanceMeters: baseDist - 6.0,
      currentSpeedKmh: 53.8,
      currentPowerWatts: 385.0,
      wPrimeRemainingPct: 0.45,
    ),
  ];
}

List<MixedRelayRiderSlot> _buildWomensTrio({double baseDist = 0.0}) {
  return [
    MixedRelayRiderSlot(
      riderId: 'w1',
      fullName: 'Elisa Longo Borghini',
      nationalityIso: 'ITA',
      isFemale: true,
      ftpWatts: 315.0,
      weightKg: 57.0,
      aerodynamicsCda: 0.192,
      timeTrialSkill: 91,
      distanceMeters: baseDist,
      currentSpeedKmh: baseDist > 0 ? 46.2 : 0.0,
      currentPowerWatts: baseDist > 0 ? 330.0 : 0.0,
      wPrimeRemainingPct: 0.96,
      isPulling: baseDist > 0,
    ),
    MixedRelayRiderSlot(
      riderId: 'w2',
      fullName: 'Vittoria Guazzini',
      nationalityIso: 'ITA',
      isFemale: true,
      ftpWatts: 305.0,
      weightKg: 59.0,
      aerodynamicsCda: 0.194,
      timeTrialSkill: 90,
      distanceMeters: baseDist > 0 ? baseDist - 2.0 : 0.0,
      currentSpeedKmh: baseDist > 0 ? 46.2 : 0.0,
      currentPowerWatts: baseDist > 0 ? 285.0 : 0.0,
      wPrimeRemainingPct: 0.98,
    ),
    MixedRelayRiderSlot(
      riderId: 'w3',
      fullName: 'Gaia Realini',
      nationalityIso: 'ITA',
      isFemale: true,
      ftpWatts: 268.0,
      weightKg: 46.0,
      aerodynamicsCda: 0.188,
      timeTrialSkill: 81,
      distanceMeters: baseDist > 0 ? baseDist - 5.0 : 0.0,
      currentSpeedKmh: baseDist > 0 ? 46.0 : 0.0,
      currentPowerWatts: baseDist > 0 ? 245.0 : 0.0,
      wPrimeRemainingPct: 0.94,
    ),
  ];
}

MixedRelayTeamEntry _buildTeam({
  String teamId = 'ita',
  String name = 'Italia',
  String iso = 'ITA',
  MixedRelayPhase phase = MixedRelayPhase.handoverApproaching,
  double mensBaseDist = 13950.0,
  double womensBaseDist = 0.0,
  MixedRelayHandoverEvent? handoverEvent,
}) {
  return MixedRelayTeamEntry(
    teamId: teamId,
    nationOrClubName: name,
    countryIso: iso,
    primaryColorHex: '#38BDF8',
    mensTrio: _buildMensTrio(baseDist: mensBaseDist),
    womensTrio: _buildWomensTrio(baseDist: womensBaseDist),
    phase: phase,
    totalElapsedSeconds: 948.42,
    mensLegSplitSeconds: phase == MixedRelayPhase.womensLegActive ? 964.15 : null,
    handoverEvent: handoverEvent,
  );
}

void main() {
  group('MixedRelayHandoverHudCalculator', () {
    test('formatRaceClock formats MM:SS.cc and HH:MM:SS.cc accurately', () {
      expect(MixedRelayHandoverHudCalculator.formatRaceClock(0.0), '00:00.00');
      expect(
        MixedRelayHandoverHudCalculator.formatRaceClock(948.42),
        '15:48.42',
      );
      expect(
        MixedRelayHandoverHudCalculator.formatRaceClock(3665.05),
        '1:01:05.05',
      );
    });

    test('formatRemainingDistance formats meters and kilometers', () {
      expect(
        MixedRelayHandoverHudCalculator.formatRemainingDistance(250.4),
        '250 m',
      );
      expect(
        MixedRelayHandoverHudCalculator.formatRemainingDistance(1420.0),
        '1.42 km',
      );
    });

    test('findSecondRiderId returns the second furthest rider', () {
      final trio = _buildMensTrio(baseDist: 13950.0);
      expect(MixedRelayHandoverHudCalculator.findSecondRiderId(trio), 'm2');
    });

    test('estimateSecondsToHandover computes ETA based on 2nd rider speed', () {
      final course = _buildCourse();
      final team = _buildTeam(mensBaseDist: 14050.0); // 150m left @ 54 km/h = 15 m/s -> 10.0s
      final eta = MixedRelayHandoverHudCalculator.estimateSecondsToHandover(
        team,
        course,
      );
      expect(eta, closeTo(10.0, 0.05));
    });
  });

  group('MixedRelayTttHandoverHudWidget', () {
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
          addTearDown(() => tester.view.resetPhysicalSize());

          final state = MixedRelayRaceState(
            course: _buildCourse(),
            teams: [
              _buildTeam(),
              _buildTeam(
                teamId: 'ned',
                name: 'Netherlands',
                iso: 'NED',
                phase: MixedRelayPhase.handoverWindowOpen,
                mensBaseDist: 14200.0,
              ),
            ],
            raceClockSeconds: 948.42,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MixedRelayTttHandoverHudWidget(
                  raceState: state,
                  onSelectTeam: (_) {},
                  onToggleRiderPull: (_) {},
                  onTriggerWomenLaunch: (_) {},
                  onMensPaceChanged: (_) {},
                  onWomensPaceChanged: (_) {},
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.text('STREFA PRZEKAZANIA'), findsOneWidget);
          expect(find.text('Filippo Ganna'), findsOneWidget);
          expect(find.text('Elisa Longo Borghini'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'triggers launch callback with falseStart=false when handoverWindowOpen',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        bool? capturedFalseStart;
        final state = MixedRelayRaceState(
          course: _buildCourse(),
          teams: [
            _buildTeam(
              phase: MixedRelayPhase.handoverWindowOpen,
              mensBaseDist: 14200.0,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MixedRelayTttHandoverHudWidget(
                raceState: state,
                onTriggerWomenLaunch: (isFalseStart) {
                  capturedFalseStart = isFalseStart;
                },
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('WYPUŚĆ TRÓJKĘ KOBIECĄ!'));
        await tester.pump(const Duration(milliseconds: 200));

        expect(capturedFalseStart, isFalse);
      },
    );

    testWidgets(
      'triggers launch callback with falseStart=true when launched early',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        bool? capturedFalseStart;
        final state = MixedRelayRaceState(
          course: _buildCourse(),
          teams: [
            _buildTeam(phase: MixedRelayPhase.handoverApproaching),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MixedRelayTttHandoverHudWidget(
                raceState: state,
                onTriggerWomenLaunch: (isFalseStart) {
                  capturedFalseStart = isFalseStart;
                },
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('WCZESNY START (RYZYKO FALSTARTU +15s)'));
        await tester.pump(const Duration(milliseconds: 200));

        expect(capturedFalseStart, isTrue);
      },
    );

    testWidgets(
      'displays handover evaluation card and supports team/pace callbacks',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        String? selectedTeam;
        MixedRelayTrioPaceMode? mensPace;
        final state = MixedRelayRaceState(
          course: _buildCourse(),
          teams: [
            _buildTeam(
              phase: MixedRelayPhase.womensLegActive,
              mensBaseDist: 14200.0,
              womensBaseDist: 2100.0,
              handoverEvent: const MixedRelayHandoverEvent(
                teamId: 'ita',
                mensSecondRiderId: 'm2',
                mensSecondRiderName: 'Edoardo Affini',
                handoverElapsedSeconds: 964.15,
                gateReactionDelaySeconds: 0.18,
                handoverDistanceMeters: 14200.0,
              ),
            ),
            _buildTeam(teamId: 'sui', name: 'Switzerland', iso: 'SUI'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MixedRelayTttHandoverHudWidget(
                raceState: state,
                onSelectTeam: (id) => selectedTeam = id,
                onMensPaceChanged: (mode) => mensPace = mode,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Perfekcyjna zmiana'), findsOneWidget);

        await tester.tap(find.text('SUI • Switzerland'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(selectedTeam, 'sui');

        await tester.tap(find.text('108%').first);
        await tester.pump(const Duration(milliseconds: 200));
        expect(mensPace, MixedRelayTrioPaceMode.allOut);
      },
    );

    testWidgets('handles empty teams and isReadOnly gracefully', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final emptyState = MixedRelayRaceState(
        course: _buildCourse(),
        teams: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MixedRelayTttHandoverHudWidget(
              raceState: emptyState,
              isReadOnly: true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Brak drużyn zgłoszonych do Sztafety Mieszanej TTT.'),
        findsOneWidget,
      );
    });
  });
}
