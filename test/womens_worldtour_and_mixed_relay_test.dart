import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/season_calendar.dart';
import 'package:pro_peloton_manager/models/career/womens_worldtour_and_mixed_relay_model.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/generators/womens_worldtour_teams_and_riders_seeder.dart';
import 'package:pro_peloton_manager/ui/screens/mixed_relay_ttt_handover_hud_widget.dart';

MixedRelayRiderSlot _makeSlot({
  required String id,
  required String name,
  required bool isFemale,
  required double distanceMeters,
  double ftpWatts = 420.0,
  double weightKg = 74.0,
  double currentSpeedKmh = 52.0,
  bool isPulling = false,
  bool isDropped = false,
}) {
  return MixedRelayRiderSlot(
    riderId: id,
    fullName: name,
    nationalityIso: 'POL',
    isFemale: isFemale,
    ftpWatts: ftpWatts,
    weightKg: weightKg,
    aerodynamicsCda: 0.200,
    timeTrialSkill: 88,
    distanceMeters: distanceMeters,
    currentSpeedKmh: currentSpeedKmh,
    currentPowerWatts: ftpWatts,
    wPrimeRemainingPct: 0.75,
    isPulling: isPulling,
    isDropped: isDropped,
  );
}

List<MixedRelayRiderSlot> _makeMensTrio({
  double d1 = 14004.0,
  double d2 = 14000.0,
  double d3 = 13992.0,
  double speedKmh = 54.0,
}) {
  return [
    _makeSlot(
      id: 'm1',
      name: 'Michał Kwiatkowski',
      isFemale: false,
      distanceMeters: d1,
      ftpWatts: 430.0,
      weightKg: 68.0,
      currentSpeedKmh: speedKmh,
      isPulling: true,
    ),
    _makeSlot(
      id: 'm2',
      name: 'Filip Maciejuk',
      isFemale: false,
      distanceMeters: d2,
      ftpWatts: 445.0,
      weightKg: 76.0,
      currentSpeedKmh: speedKmh,
    ),
    _makeSlot(
      id: 'm3',
      name: 'Maciej Bodnar',
      isFemale: false,
      distanceMeters: d3,
      ftpWatts: 440.0,
      weightKg: 78.0,
      currentSpeedKmh: speedKmh,
    ),
  ];
}

List<MixedRelayRiderSlot> _makeWomensTrio({
  double d1 = 0.0,
  double d2 = 0.0,
  double d3 = 0.0,
  double speedKmh = 48.0,
}) {
  return [
    _makeSlot(
      id: 'w1',
      name: 'Katarzyna Niewiadoma',
      isFemale: true,
      distanceMeters: d1,
      ftpWatts: 305.0,
      weightKg: 52.0,
      currentSpeedKmh: speedKmh,
      isPulling: true,
    ),
    _makeSlot(
      id: 'w2',
      name: 'Agnieszka Skalniak-Sójka',
      isFemale: true,
      distanceMeters: d2,
      ftpWatts: 315.0,
      weightKg: 58.0,
      currentSpeedKmh: speedKmh,
    ),
    _makeSlot(
      id: 'w3',
      name: 'Marta Lach',
      isFemale: true,
      distanceMeters: d3,
      ftpWatts: 295.0,
      weightKg: 56.0,
      currentSpeedKmh: speedKmh,
    ),
  ];
}

MixedRelayCourseSpec _makeCourse() {
  return const MixedRelayCourseSpec(
    eventId: 'uci_wc_mixed_relay_2026',
    eventName: 'UCI World Championships Mixed Relay TTT',
    locationCity: 'Montreal',
    countryIso: 'CAN',
    totalDistanceMeters: 28000.0,
    handoverDistanceMeters: 14000.0,
    handoverApproachZoneMeters: 500.0,
    elevationGainM: 280,
    windSpeedKmh: 14.0,
    temperatureCelsius: 18.0,
    intermediateSplitMeters: [7000.0, 14000.0, 21000.0],
  );
}

void main() {
  group('WomensWorldtourTeamsAndRidersSeeder', () {
    test('seeds 24 teams (15 WWT, 6 ProTeam, 3 Continental) and 360 riders', () {
      final result = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
        seasonYear: 2026,
        seed: 20260404,
        freeAgentsCount: 30,
      );

      expect(result.teams.length, 24);
      expect(result.worldTourTeams.length, 15);
      expect(result.proTeams.length, 6);
      expect(result.continentalTeams.length, 3);
      expect(result.seededRiders.length, 360);
      expect(result.allRiders.length, 360);
      expect(result.physiologyByRiderId.length, 360);

      for (final team in result.teams) {
        expect(team.rosterSize, 15);
        expect(team.isRosterCompliant, isTrue);
        expect(
          team.hasMandatoryWwtEntry,
          team.division == WomensDivision.womensWorldTour,
        );
        expect(result.getTeamRoster(team.teamId).length, 15);
      }

      final uniqueIds = result.seededRiders.map((r) => r.id).toSet();
      final uniqueNames = result.seededRiders.map((r) => r.fullName).toSet();
      expect(uniqueIds.length, 360);
      expect(uniqueNames.length, 360);
    });

    test('calibrates women physiology for climbers vs sprinters', () {
      final result = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
        seasonYear: 2026,
        seed: 9911,
      );

      final climbers = result.seededRiders
          .where(
            (r) =>
                r.rider.specialization == RiderSpecialization.pureClimber ||
                r.rider.specialization == RiderSpecialization.gcClimber,
          )
          .toList();
      final sprinters = result.seededRiders
          .where(
            (r) => r.rider.specialization == RiderSpecialization.pureSprinter,
          )
          .toList();

      expect(climbers, isNotEmpty);
      expect(sprinters, isNotEmpty);

      final avgClimberWeight =
          climbers.map((r) => r.womensPhysiology.weightKg).reduce((a, b) => a + b) /
              climbers.length;
      final avgSprinterWeight =
          sprinters.map((r) => r.womensPhysiology.weightKg).reduce((a, b) => a + b) /
              sprinters.length;

      final avgClimber5s =
          climbers.map((r) => r.womensPhysiology.watts5s).reduce((a, b) => a + b) /
              climbers.length;
      final avgSprinter5s =
          sprinters.map((r) => r.womensPhysiology.watts5s).reduce((a, b) => a + b) /
              sprinters.length;

      final avgClimberWkg =
          climbers.map((r) => r.womensPhysiology.wPerKg).reduce((a, b) => a + b) /
              climbers.length;
      final avgSprinterWkg =
          sprinters.map((r) => r.womensPhysiology.wPerKg).reduce((a, b) => a + b) /
              sprinters.length;

      expect(avgClimberWeight, lessThan(avgSprinterWeight));
      expect(avgSprinter5s, greaterThan(avgClimber5s));
      expect(avgClimberWkg, greaterThan(avgSprinterWkg));

      for (final seeded in result.seededRiders) {
        final phys = seeded.womensPhysiology;
        expect(phys.weightKg, inInclusiveRange(47.0, 68.5));
        expect(phys.ftpWatts, inInclusiveRange(195.0, 385.0));
        expect(phys.overallRating, inInclusiveRange(40, 99));
      }
    });

    test('populates transfer market sorted by OVR and deterministic seeding', () {
      final a = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
        seasonYear: 2026,
        seed: 777,
        freeAgentsCount: 25,
      );
      final b = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
        seasonYear: 2026,
        seed: 777,
        freeAgentsCount: 25,
      );
      final c = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
        seasonYear: 2026,
        seed: 888,
        freeAgentsCount: 25,
      );

      expect(a.freeAgentListings.length, 25);
      expect(a.contractedTransferListings, isNotEmpty);
      expect(a.calendarEvents, isNotEmpty);

      for (int i = 1; i < a.transferMarket.length; i++) {
        expect(
          a.transferMarket[i - 1].overallRating,
          greaterThanOrEqualTo(a.transferMarket[i].overallRating),
        );
      }

      expect(a.seededRiders.first.fullName, b.seededRiders.first.fullName);
      expect(a.seededRiders.first.fullName, isNot(c.seededRiders.first.fullName));
    });
  });

  group('WomensWorldTourSeasonState & JSON', () {
    test('records race completion, awards UCI/youth points and sorts teams', () {
      final result = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
        seasonYear: 2026,
        seed: 42,
      );
      final state = result.seasonState;
      final upcoming = state.upcomingEvents();
      expect(upcoming, isNotEmpty);

      final monument = upcoming.firstWhere(
        (e) => e.tier == WomensRaceTier.wwtMonument,
        orElse: () => upcoming.first,
      );
      final targetTeam = state.teams.last;
      final initialTeamPts = targetTeam.uciPoints;
      final winnerRiderId = targetTeam.rosterRiderIds.first;

      final updated = state.recordRaceCompletion(
        raceId: monument.raceId,
        winnerRiderId: winnerRiderId,
        winnerRiderName: 'Agnieszka Kowalska',
        winnerTeamId: targetTeam.teamId,
        isYouthEligible: true,
      );

      final expectedPts = monument.tier.winnerUciPoints;
      expect(updated.individualUciStandings[winnerRiderId], expectedPts);
      expect(updated.youthUciStandings[winnerRiderId], expectedPts);

      final updatedTeam =
          updated.teams.firstWhere((t) => t.teamId == targetTeam.teamId);
      expect(updatedTeam.uciPoints, initialTeamPts + expectedPts);
      expect(updatedTeam.seasonWins, 1);

      final completedEvent =
          updated.calendarEvents.firstWhere((e) => e.raceId == monument.raceId);
      expect(completedEvent.status, RaceCompletionStatus.completed);
      expect(completedEvent.winnerRiderId, winnerRiderId);

      // Unknown raceId should leave state unchanged
      final unchanged = updated.recordRaceCompletion(
        raceId: 'non_existent_race',
        winnerRiderId: winnerRiderId,
        winnerRiderName: 'X',
        winnerTeamId: targetTeam.teamId,
      );
      expect(unchanged.individualUciStandings[winnerRiderId], expectedPts);

      // Sorted teams descending by UCI points
      final sorted = updated.teamsSortedByUciPoints;
      for (int i = 1; i < sorted.length; i++) {
        expect(
          sorted[i - 1].uciPoints,
          greaterThanOrEqualTo(sorted[i].uciPoints),
        );
      }

      // JSON round-trip
      final decoded = WomensWorldTourSeasonState.fromJson(updated.toJson());
      expect(decoded.seasonYear, updated.seasonYear);
      expect(decoded.teams.length, updated.teams.length);
      expect(decoded.calendarEvents.length, updated.calendarEvents.length);
      expect(decoded.individualUciStandings[winnerRiderId], expectedPts);
      expect(decoded.youthUciStandings[winnerRiderId], expectedPts);
    });
  });

  group('MixedRelayTTT Model & Logic', () {
    test('validates 3+3 gender lineup and second rider distance rule', () {
      final validTeam = MixedRelayTeamEntry(
        teamId: 'pol',
        nationOrClubName: 'Polska',
        countryIso: 'POL',
        primaryColorHex: '#DC2626',
        mensTrio: _makeMensTrio(d1: 14120.0, d2: 13980.0, d3: 13850.0),
        womensTrio: _makeWomensTrio(d1: 5200.0, d2: 5190.0, d3: 5100.0),
        phase: MixedRelayPhase.mensLegActive,
      );

      expect(validTeam.isLineupValid, isTrue);
      expect(validTeam.mensSecondRiderDistanceMeters, 13980.0);
      expect(validTeam.womensSecondRiderDistanceMeters, 5190.0);
      expect(validTeam.canCompleteActiveLeg, isTrue);

      // Dropping 2 men makes mens leg unable to complete (<2 active)
      final twoDropped = validTeam.copyWith(
        mensTrio: [
          validTeam.mensTrio[0],
          validTeam.mensTrio[1].copyWith(isDropped: true),
          validTeam.mensTrio[2].copyWith(isDropped: true),
        ],
      );
      expect(twoDropped.mensActiveCount, 1);
      expect(twoDropped.canCompleteActiveLeg, isFalse);

      // Invalid lineup if a female rider is placed in mensTrio
      final invalidGender = validTeam.copyWith(
        mensTrio: [
          validTeam.mensTrio[0],
          validTeam.mensTrio[1],
          validTeam.womensTrio[0],
        ],
      );
      expect(invalidGender.isLineupValid, isFalse);
    });

    test('evaluates handover quality, false start penalty and leaderboard sort',
        () {
      final course = _makeCourse();
      final mens = _makeMensTrio(d1: 14010.0, d2: 14002.0, d3: 13980.0);

      final perfect = MixedRelayRaceState.evaluateHandover(
        teamId: 'pol',
        secondMaleRider: mens[1],
        handoverElapsedSeconds: 942.5,
        reactionDelaySeconds: 0.12,
        handoverDistanceMeters: course.handoverDistanceMeters,
      );
      expect(perfect.falseStartPenaltySeconds, 0.0);
      expect(perfect.handoverQualityScore, 100.0);
      expect(perfect.qualityRatingLabel, 'Perfekcyjna zmiana');

      final falseStart = MixedRelayRaceState.evaluateHandover(
        teamId: 'fra',
        secondMaleRider: mens[1],
        handoverElapsedSeconds: 940.0,
        reactionDelaySeconds: 0.05,
        handoverDistanceMeters: course.handoverDistanceMeters,
        isFalseStart: true,
      );
      expect(falseStart.falseStartPenaltySeconds, 15.0);
      expect(falseStart.handoverQualityScore, 15.0);
      expect(falseStart.qualityRatingLabel, 'Falstart (+kara)');

      final finishedFast = MixedRelayTeamEntry(
        teamId: 'ned',
        nationOrClubName: 'Holandia',
        countryIso: 'NED',
        primaryColorHex: '#F97316',
        mensTrio: mens,
        womensTrio: _makeWomensTrio(d1: 14005.0, d2: 14001.0, d3: 13990.0),
        phase: MixedRelayPhase.finished,
        totalElapsedSeconds: 1900.0,
        penaltySeconds: 0.0,
      );
      final finishedWithPenalty = finishedFast.copyWith(
        teamId: 'fra',
        nationOrClubName: 'Francja',
        totalElapsedSeconds: 1895.0,
        penaltySeconds: 15.0,
        handoverEvent: falseStart,
      );
      final onCourse = finishedFast.copyWith(
        teamId: 'pol',
        nationOrClubName: 'Polska',
        phase: MixedRelayPhase.womensLegActive,
        womensTrio: _makeWomensTrio(d1: 8000.0, d2: 7990.0, d3: 7950.0),
      );
      final dsq = finishedFast.copyWith(
        teamId: 'ger',
        nationOrClubName: 'Niemcy',
        phase: MixedRelayPhase.disqualified,
      );

      final raceState = MixedRelayRaceState(
        course: course,
        teams: [dsq, onCourse, finishedWithPenalty, finishedFast],
        raceClockSeconds: 1950.0,
      );

      final sorted = raceState.leaderboardSorted;
      expect(sorted.map((t) => t.teamId).toList(), ['ned', 'fra', 'pol', 'ger']);
      expect(raceState.handoverProgressPct(onCourse), 1.0);
      expect(
        raceState.totalCourseProgressPct(onCourse),
        closeTo((14000.0 + 7990.0) / 28000.0, 1e-6),
      );

      // JSON round-trip
      final decoded = MixedRelayRaceState.fromJson(raceState.toJson());
      expect(decoded.course.eventId, course.eventId);
      expect(decoded.teams.length, 4);
      expect(decoded.teams[2].handoverEvent?.falseStartPenaltySeconds, 15.0);
    });
  });

  group('MixedRelayTttHandoverHudWidget & Calculator', () {
    test('calculates clock, remaining distance, second rider and ETA', () {
      expect(MixedRelayHandoverHudCalculator.formatRaceClock(75.42), '01:15.42');
      expect(
        MixedRelayHandoverHudCalculator.formatRemainingDistance(450.0),
        '450 m',
      );
      expect(
        MixedRelayHandoverHudCalculator.formatRemainingDistance(3250.0),
        '3.25 km',
      );

      final mens = _makeMensTrio(d1: 13600.0, d2: 13500.0, d3: 13450.0);
      expect(MixedRelayHandoverHudCalculator.findSecondRiderId(mens), 'm2');

      final team = MixedRelayTeamEntry(
        teamId: 'pol',
        nationOrClubName: 'Polska',
        countryIso: 'POL',
        primaryColorHex: '#DC2626',
        mensTrio: mens,
        womensTrio: _makeWomensTrio(),
        phase: MixedRelayPhase.handoverApproaching,
      );
      final eta = MixedRelayHandoverHudCalculator.estimateSecondsToHandover(
        team,
        _makeCourse(),
      );
      // 500 m at 54 km/h (15 m/s) => 33.33 s
      expect(eta, closeTo(500.0 / 15.0, 0.05));
    });

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

          final team = MixedRelayTeamEntry(
            teamId: 'pol',
            nationOrClubName: 'Polska',
            countryIso: 'POL',
            primaryColorHex: '#DC2626',
            mensTrio: _makeMensTrio(d1: 14002.0, d2: 14000.0, d3: 13995.0),
            womensTrio: _makeWomensTrio(),
            phase: MixedRelayPhase.handoverWindowOpen,
            totalElapsedSeconds: 940.0,
          );
          final raceState = MixedRelayRaceState(
            course: _makeCourse(),
            teams: [team],
            raceClockSeconds: 940.0,
          );

          bool launchTriggered = false;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: MixedRelayTttHandoverHudWidget(
                    raceState: raceState,
                    onTriggerWomenLaunch: (_) => launchTriggered = true,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          // Uncaught RenderFlex overflow errors automatically fail testWidgets with full details.
          expect(find.text('UCI MIXED RELAY'), findsOneWidget);
          expect(find.text('Michał Kwiatkowski'), findsOneWidget);
          expect(find.text('Katarzyna Niewiadoma'), findsOneWidget);

          final launchBtn = find.text('WYPUŚĆ TRÓJKĘ KOBIECĄ');
          if (launchBtn.evaluate().isNotEmpty) {
            await tester.ensureVisible(launchBtn);
            await tester.pump(const Duration(milliseconds: 200));
            await tester.tap(launchBtn);
            await tester.pump(const Duration(milliseconds: 200));
            expect(launchTriggered, isTrue);
          }
        },
      );
    }
  });
}
