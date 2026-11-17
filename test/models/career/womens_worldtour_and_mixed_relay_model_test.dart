import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/season_calendar.dart';
import 'package:pro_peloton_manager/models/career/womens_worldtour_and_mixed_relay_model.dart';

void main() {
  group('UCI Womens WorldTour Model', () {
    test('WomensPhysiologyProfile computes W/kg, OVR and round-trips JSON', () {
      const profile = WomensPhysiologyProfile(
        weightKg: 54.0,
        heightCm: 168.0,
        ftpWatts: 305.0,
        vo2Max: 76.0,
        wPrimeJoules: 16500.0,
        watts5s: 960.0,
        watts1m: 510.0,
        watts5m: 365.0,
        watts20m: 315.0,
        recoveryRate: 1.12,
        aerodynamicsCda: 0.205,
      );

      expect(profile.wPerKg, closeTo(5.648, 0.01));
      expect(profile.wPerKg20m, closeTo(5.833, 0.01));
      expect(profile.overallRating, inInclusiveRange(80, 99));

      final restored = WomensPhysiologyProfile.fromJson(profile.toJson());
      expect(restored, equals(profile));
      expect(restored.wPrimeJoules, 16500.0);
    });

    test('WomensWorldTourSeasonState records race completion and sorts teams', () {
      final teams = [
        WomensTeamProfile(
          teamId: 'sdw',
          name: 'Team SD Worx-Protime',
          shortCode: 'SDW',
          countryIso: 'NLD',
          division: WomensDivision.womensWorldTour,
          primaryColorHex: '#5B2C6F',
          secondaryColorHex: '#E74C3C',
          annualBudgetEur: 4500000,
          uciPoints: 1200,
          rosterRiderIds: List.generate(16, (i) => 'sdw_$i'),
        ),
        WomensTeamProfile(
          teamId: 'fdj',
          name: 'FDJ-SUEZ',
          shortCode: 'FST',
          countryIso: 'FRA',
          division: WomensDivision.womensWorldTour,
          primaryColorHex: '#1B4F72',
          secondaryColorHex: '#E74C3C',
          annualBudgetEur: 3800000,
          uciPoints: 950,
          rosterRiderIds: List.generate(15, (i) => 'fdj_$i'),
        ),
      ];

      final events = [
        WomensRaceEvent(
          raceId: 'tdff_2026',
          name: 'Tour de France Femmes',
          countryIso: 'FRA',
          tier: WomensRaceTier.wwtGrandTour,
          startDate: DateTime(2026, 8, 1),
          stageCount: 8,
          totalDistanceKm: 985.5,
          elevationGainM: 14200,
          prizePoolEur: 250000,
        ),
      ];

      final state = WomensWorldTourSeasonState(
        seasonYear: 2026,
        teams: teams,
        calendarEvents: events,
      );

      expect(teams.first.isRosterCompliant, isTrue);
      expect(teams.first.hasMandatoryWwtEntry, isTrue);
      expect(state.upcomingEvents().length, 1);

      final updated = state.recordRaceCompletion(
        raceId: 'tdff_2026',
        winnerRiderId: 'fdj_1',
        winnerRiderName: 'Katarzyna Niewiadoma',
        winnerTeamId: 'fdj',
      );

      expect(updated.upcomingEvents(), isEmpty);
      expect(
        updated.calendarEvents.first.status,
        RaceCompletionStatus.completed,
      );
      expect(updated.individualUciStandings['fdj_1'], 800);
      expect(updated.teamsSortedByUciPoints.first.teamId, 'fdj');
      expect(updated.teamsSortedByUciPoints.first.uciPoints, 1750);

      final restored = WomensWorldTourSeasonState.fromJson(updated.toJson());
      expect(restored.seasonYear, 2026);
      expect(restored.teamsSortedByUciPoints.first.teamId, 'fdj');
    });
  });

  group('Mixed Relay TTT Model', () {
    List<MixedRelayRiderSlot> makeTrio({
      required String prefix,
      required bool isFemale,
      required List<double> distances,
    }) {
      return List.generate(3, (i) {
        return MixedRelayRiderSlot(
          riderId: '${prefix}_$i',
          fullName: '$prefix Rider $i',
          nationalityIso: 'POL',
          isFemale: isFemale,
          ftpWatts: isFemale ? 310.0 : 410.0,
          weightKg: isFemale ? 56.0 : 72.0,
          aerodynamicsCda: isFemale ? 0.205 : 0.220,
          timeTrialSkill: 85,
          distanceMeters: distances[i],
        );
      });
    }

    test('computes 2nd rider distance and handover progress accurately', () {
      const course = MixedRelayCourseSpec(
        eventId: 'wc_mixed_relay',
        eventName: 'UCI World Championships Mixed Relay TTT',
        locationCity: 'Montreal',
        countryIso: 'CAN',
        totalDistanceMeters: 28000.0,
        handoverDistanceMeters: 14000.0,
        elevationGainM: 220,
      );

      final teamA = MixedRelayTeamEntry(
        teamId: 'pol',
        nationOrClubName: 'Poland',
        countryIso: 'POL',
        primaryColorHex: '#DC143C',
        mensTrio: makeTrio(
          prefix: 'pol_m',
          isFemale: false,
          distances: [14050.0, 13980.0, 11200.0],
        ),
        womensTrio: makeTrio(
          prefix: 'pol_w',
          isFemale: true,
          distances: [0.0, 0.0, 0.0],
        ),
        phase: MixedRelayPhase.handoverApproaching,
      );

      expect(teamA.isLineupValid, isTrue);
      // 2nd rider distance must be 13980.0 (not 14050.0 or 11200.0)
      expect(teamA.mensSecondRiderDistanceMeters, 13980.0);

      final race = MixedRelayRaceState(course: course, teams: [teamA]);
      expect(race.handoverProgressPct(teamA), closeTo(13980.0 / 14000.0, 0.001));
    });

    test('evaluates handover quality, false start penalty and leaderboard sort', () {
      const course = MixedRelayCourseSpec(
        eventId: 'wc_mixed_relay',
        eventName: 'UCI World Championships Mixed Relay TTT',
        locationCity: 'Montreal',
        countryIso: 'CAN',
        totalDistanceMeters: 28000.0,
        handoverDistanceMeters: 14000.0,
        elevationGainM: 220,
      );

      final teamFast = MixedRelayTeamEntry(
        teamId: 'ned',
        nationOrClubName: 'Netherlands',
        countryIso: 'NLD',
        primaryColorHex: '#FF6600',
        mensTrio: makeTrio(
          prefix: 'ned_m',
          isFemale: false,
          distances: [14000.0, 14000.0, 13500.0],
        ),
        womensTrio: makeTrio(
          prefix: 'ned_w',
          isFemale: true,
          distances: [14000.0, 14000.0, 13800.0],
        ),
        phase: MixedRelayPhase.finished,
        totalElapsedSeconds: 1985.4,
        penaltySeconds: 0.0,
      );

      final handoverFalseStart = MixedRelayRaceState.evaluateHandover(
        teamId: 'aus',
        secondMaleRider: teamFast.mensTrio[1],
        handoverElapsedSeconds: 980.0,
        reactionDelaySeconds: 0.0,
        handoverDistanceMeters: 14000.0,
        isFalseStart: true,
      );
      expect(handoverFalseStart.falseStartPenaltySeconds, 15.0);
      expect(handoverFalseStart.handoverQualityScore, 15.0);

      final teamPenalized = teamFast.copyWith(
        teamId: 'aus',
        nationOrClubName: 'Australia',
        countryIso: 'AUS',
        totalElapsedSeconds: 1980.0,
        penaltySeconds: handoverFalseStart.falseStartPenaltySeconds,
        handoverEvent: handoverFalseStart,
      );

      final race = MixedRelayRaceState(
        course: course,
        teams: [teamPenalized, teamFast],
      );

      final leaderboard = race.leaderboardSorted;
      expect(leaderboard.first.teamId, 'ned');
      expect(leaderboard.last.teamId, 'aus');
      expect(leaderboard.last.effectiveTotalTimeSeconds, 1995.0);

      final restored = MixedRelayRaceState.fromJson(race.toJson());
      expect(restored.leaderboardSorted.first.teamId, 'ned');
      expect(restored.teams.first.handoverEvent?.falseStartPenaltySeconds, 15.0);
    });
  });
}
