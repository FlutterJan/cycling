import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/multiplayer/online_league_and_ghost_challenge_model.dart';

void main() {
  group('WeatherConditionSnapshot', () {
    test('generates deterministic weatherHash and detects identical weather', () {
      const w1 = WeatherConditionSnapshot(
        weatherSeed: 987654,
        temperatureC: 14.5,
        windSpeedKmh: 32.0,
        windDirectionDegrees: 245.0,
        precipitationMmPerHour: 1.2,
        humidityPercent: 78.0,
        roadWetness: 0.45,
        weatherLabel: 'Wiatr boczny i przelotny deszcz',
      );
      final w2 = WeatherConditionSnapshot.fromJson(w1.toJson());
      final w3 = w1.copyWith(windSpeedKmh: 33.0);

      expect(w1.weatherHash, w2.weatherHash);
      expect(w1.isIdenticalTo(w2), isTrue);
      expect(w1.isIdenticalTo(w3), isFalse);
      expect(w1.isWetRoad, isTrue);
      expect(w1.isCrosswindAlert, isTrue);
    });
  });

  group('EloCalculator & EloRatingProfile', () {
    test('resolves divisions and calculates 1v1 and multi-player ELO deltas', () {
      expect(EloDivisionTier.fromElo(950), EloDivisionTier.bronze);
      expect(EloDivisionTier.fromElo(1200), EloDivisionTier.silver);
      expect(EloDivisionTier.fromElo(1400), EloDivisionTier.gold);
      expect(EloDivisionTier.fromElo(1650), EloDivisionTier.platinum);
      expect(EloDivisionTier.fromElo(1850), EloDivisionTier.diamond);
      expect(EloDivisionTier.fromElo(2100), EloDivisionTier.worldTourElite);
      expect(EloDivisionTier.fromElo(2400), EloDivisionTier.grandTourLegend);

      final upsetWinDelta = EloCalculator.calculateHeadToHeadDelta(
        playerElo: 1200,
        opponentElo: 1600,
        actualScore: 1.0,
        matchesPlayed: 5,
      );
      expect(upsetWinDelta, greaterThan(30));

      final stageDeltas = EloCalculator.calculateMultiPlayerStageDeltas(
        orderedRatings: [1200, 1500, 1400, 1300],
      );
      expect(stageDeltas.length, 4);
      expect(stageDeltas.first, greaterThan(0));
      expect(stageDeltas.last, lessThan(0));
    });

    test('applies match results, updates streaks, peakElo and JSON round-trip', () {
      var profile = const EloRatingProfile(
        playerId: 'mgr-1',
        displayName: 'Jan Kowalski',
        currentElo: 1200,
        peakElo: 1200,
      );

      final now = DateTime.utc(2026, 11, 17, 19, 0);
      profile = profile.applyMatchResult(
        EloMatchRecord(
          matchId: 'm1',
          leagueId: 'l1',
          opponentId: 'mgr-2',
          opponentName: 'Rival',
          eloBefore: 1200,
          eloAfter: 1228,
          delta: 28,
          placement: 1,
          fieldSize: 2,
          recordedAt: now,
        ),
      );

      expect(profile.currentElo, 1228);
      expect(profile.peakElo, 1228);
      expect(profile.wins, 1);
      expect(profile.winStreak, 1);
      expect(profile.recentHistory.length, 1);

      final restored = EloRatingProfile.fromJson(profile.toJson());
      expect(restored, profile);
    });
  });

  group('OnlineLeagueModel', () {
    test('records stage results, enforces weather parity and sorts standings', () {
      final now = DateTime.utc(2026, 11, 17, 18, 0);
      const lockedWeather = WeatherConditionSnapshot(
        weatherSeed: 551122,
        temperatureC: 11.0,
        windSpeedKmh: 24.0,
        windDirectionDegrees: 90.0,
        precipitationMmPerHour: 0.0,
        humidityPercent: 60.0,
        roadWetness: 0.0,
      );

      var league = OnlineLeagueModel(
        leagueId: 'league-wt-1',
        name: 'Liga Mistrzów WorldTour',
        format: LeagueFormat.seasonPoints,
        privacy: LeaguePrivacy.friendsOnly,
        status: LeagueStatus.active,
        maxParticipants: 4,
        createdAt: now,
        startsAt: now,
        endsAt: now.add(const Duration(days: 14)),
        schedule: [
          LeagueStageScheduleEntry(
            stageIndex: 1,
            stageId: 'alpe-dhuez',
            stageName: "Alpe d'Huez",
            distanceKm: 138.0,
            elevationGainM: 3400.0,
            lockedWeather: lockedWeather,
            opensAt: now,
            closesAt: now.add(const Duration(days: 2)),
          ),
        ],
      );

      league = league.addParticipant(
        LeagueParticipantEntry(
          participantId: 'p1',
          displayName: 'Anna',
          teamName: 'Veloce',
          joinedAt: now,
        ),
      );
      league = league.addParticipant(
        LeagueParticipantEntry(
          participantId: 'p2',
          displayName: 'Marek',
          teamName: 'Polonia Pro',
          joinedAt: now,
        ),
      );

      expect(
        () => league.recordStageResult(
          1,
          LeagueStageResultEntry(
            participantId: 'p1',
            finishTimeSeconds: 12450.0,
            averageWatts: 345.0,
            normalizedPower: 362.0,
            averageSpeedKmh: 39.9,
            weatherHash: 'invalid-hash',
            submittedAt: now,
          ),
        ),
        throwsArgumentError,
      );

      league = league.recordStageResult(
        1,
        LeagueStageResultEntry(
          participantId: 'p1',
          finishTimeSeconds: 12450.0,
          averageWatts: 345.0,
          normalizedPower: 362.0,
          averageSpeedKmh: 39.9,
          weatherHash: lockedWeather.weatherHash,
          submittedAt: now,
        ),
      );
      league = league.recordStageResult(
        1,
        LeagueStageResultEntry(
          participantId: 'p2',
          finishTimeSeconds: 12410.0,
          averageWatts: 352.0,
          normalizedPower: 368.0,
          averageSpeedKmh: 40.03,
          weatherHash: lockedWeather.weatherHash,
          submittedAt: now,
        ),
      );

      final standings = league.sortedStandings;
      expect(standings.first.participantId, 'p2');
      expect(standings.first.totalPoints, 25);
      expect(standings.first.stageWins, 1);
      expect(standings.last.participantId, 'p1');
      expect(standings.last.totalPoints, 18);
      expect(league.completionProgress, 1.0);

      final decoded = OnlineLeagueModel.fromJson(league.toJson());
      expect(decoded, league);
    });
  });

  group('GhostChallengeModel & MultiplayerLeaguePackage', () {
    test('interpolates ghost telemetry and verifies weather + package checksum', () {
      final now = DateTime.utc(2026, 11, 17, 18, 0);
      const weather = WeatherConditionSnapshot(
        weatherSeed: 778899,
        temperatureC: 19.0,
        windSpeedKmh: 15.0,
        windDirectionDegrees: 180.0,
        precipitationMmPerHour: 0.0,
        humidityPercent: 50.0,
        roadWetness: 0.0,
      );

      var challenge = GhostChallengeModel(
        challengeId: 'ghost-1',
        title: 'Pojedynek na Ventoux',
        creatorId: 'p1',
        creatorName: 'Michał',
        stageId: 'mont-ventoux',
        stageName: 'Mont Ventoux ITT',
        distanceKm: 21.5,
        elevationGainM: 1610.0,
        weatherSnapshot: weather,
        targetFinishTimeSeconds: 3420.0,
        targetAverageWatts: 385.0,
        targetTelemetry: const [
          GhostTelemetrySample(
            elapsedSeconds: 0.0,
            distanceKm: 0.0,
            speedKmh: 24.0,
            powerWatts: 400.0,
          ),
          GhostTelemetrySample(
            elapsedSeconds: 100.0,
            distanceKm: 0.6,
            speedKmh: 20.0,
            powerWatts: 380.0,
          ),
        ],
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
      );

      final midTime = challenge.interpolateGhostAtTime(50.0);
      expect(midTime, isNotNull);
      expect(midTime!.distanceKm, closeTo(0.3, 1e-6));
      expect(midTime.powerWatts, closeTo(390.0, 1e-6));

      final midDist = challenge.interpolateGhostAtDistance(0.3);
      expect(midDist, isNotNull);
      expect(midDist!.elapsedSeconds, closeTo(50.0, 1e-6));

      challenge = challenge.recordAttempt(
        GhostAttemptResult(
          attemptId: 'att-1',
          challengerId: 'p2',
          challengerName: 'Kasia',
          finishTimeSeconds: 3405.0,
          averageWatts: 389.0,
          normalizedPower: 394.0,
          maxSpeedKmh: 36.2,
          weatherHash: weather.weatherHash,
          deltaVsTargetSeconds: -15.0,
          isVictory: true,
          completedAt: now.add(const Duration(hours: 2)),
        ),
      );

      expect(challenge.status, GhostChallengeStatus.completed);
      expect(challenge.bestAttempt?.attemptId, 'att-1');

      final pkg = MultiplayerLeaguePackage(
        exportedAt: now,
        ghostChallenges: [challenge],
      ).withValidChecksum();

      expect(pkg.isChecksumValid, isTrue);
      final restoredPkg = MultiplayerLeaguePackage.fromJson(pkg.toJson());
      expect(restoredPkg.isChecksumValid, isTrue);
      expect(restoredPkg.ghostChallenges.first, challenge);
    });
  });
}
