import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/multiplayer/online_league_and_ghost_challenge_model.dart';
import 'package:pro_peloton_manager/services/network/async_multiplayer_league_sync_service.dart';

WeatherConditionSnapshot _sampleWeather() {
  return const WeatherConditionSnapshot(
    weatherSeed: 4242,
    temperatureC: 19.5,
    windSpeedKmh: 14.0,
    windDirectionDegrees: 220.0,
    precipitationMmPerHour: 0.0,
    humidityPercent: 55.0,
    roadWetness: 0.0,
  );
}

OnlineLeagueModel _sampleLeague() {
  final now = DateTime.utc(2026, 7, 1, 10, 0);
  final weather = _sampleWeather();
  return OnlineLeagueModel(
    leagueId: 'league_wt_2026',
    name: 'WorldTour Async Cup',
    format: LeagueFormat.seasonPoints,
    status: LeagueStatus.recruiting,
    createdAt: now,
    startsAt: now,
    endsAt: now.add(const Duration(days: 14)),
    participants: [
      LeagueParticipantEntry(
        participantId: 'p1',
        displayName: 'Jan Kowalski',
        teamName: 'Polska Pro Cycling',
        currentElo: 1200,
        joinedAt: now,
      ),
      LeagueParticipantEntry(
        participantId: 'p2',
        displayName: 'Pierre Moreau',
        teamName: 'Equipe Alpine',
        currentElo: 1250,
        joinedAt: now.add(const Duration(minutes: 5)),
      ),
    ],
    schedule: [
      LeagueStageScheduleEntry(
        stageIndex: 1,
        stageId: 'stage_alpe',
        stageName: 'Alpe d\'Huez ITT',
        distanceKm: 18.5,
        elevationGainM: 1120,
        lockedWeather: weather,
        opensAt: now,
        closesAt: now.add(const Duration(days: 3)),
      ),
    ],
  );
}

GhostChallengeModel _sampleChallenge() {
  final now = DateTime.utc(2026, 7, 1, 10, 0);
  return GhostChallengeModel(
    challengeId: 'ghost_ventoux_01',
    title: 'Mont Ventoux Challenge',
    creatorId: 'p1',
    creatorName: 'Jan Kowalski',
    stageId: 'stage_ventoux',
    stageName: 'Bédoin - Mont Ventoux',
    distanceKm: 21.4,
    elevationGainM: 1610,
    weatherSnapshot: _sampleWeather(),
    targetFinishTimeSeconds: 3480.0,
    targetAverageWatts: 385.0,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 7)),
  );
}

void main() {
  const service = AsyncMultiplayerLeagueSyncService();

  group('Draft session & snake order', () {
    test('executes snake draft order and completes draft into active league',
        () {
      final league = _sampleLeague();
      final started = service.createDraftSession(
        league,
        availableRiderIds: const ['r1', 'r2', 'r3', 'r4', 'r5'],
        strategy: DraftOrderStrategy.snake,
        ridersPerTeam: 2,
      );

      expect(started.league.status, LeagueStatus.drafting);
      expect(started.draftState.currentParticipantId, 'p1');

      final pick1 = service.submitDraftPick(
        league: started.league,
        draftState: started.draftState,
        participantId: 'p1',
        riderId: 'r1',
        riderName: 'Tadej',
      );
      expect(pick1.draftState.currentParticipantId, 'p2');

      final pick2 = service.submitDraftPick(
        league: pick1.league,
        draftState: pick1.draftState,
        participantId: 'p2',
        riderId: 'r2',
      );
      // Snake round 2 reverses: p2 picks again before p1
      expect(pick2.draftState.currentRound, 2);
      expect(pick2.draftState.currentParticipantId, 'p2');

      final pick3 = service.submitDraftPick(
        league: pick2.league,
        draftState: pick2.draftState,
        participantId: 'p2',
        riderId: 'r3',
      );
      expect(pick3.draftState.currentParticipantId, 'p1');

      final pick4 = service.autoPickForCurrentTurn(
        league: pick3.league,
        draftState: pick3.draftState,
      );
      expect(pick4.draftState.isDraftComplete, isTrue);
      expect(pick4.league.draftStatus, LeagueDraftStatus.completed);
      expect(pick4.league.status, LeagueStatus.active);
      expect(
        pick4.league.getParticipantById('p1')!.draftedRiderIds,
        ['r1', 'r4'],
      );
      expect(
        pick4.league.getParticipantById('p2')!.draftedRiderIds,
        ['r2', 'r3'],
      );
    });
  });

  group('Stage result validation & ELO sync', () {
    test('validates weather parity, checksum and updates ELO on completion',
        () {
      final league = _sampleLeague();
      final weatherHash = league.schedule.first.lockedWeather.weatherHash;
      final now = DateTime.utc(2026, 7, 2, 12, 0);

      final badWeatherEntry = LeagueStageResultEntry(
        participantId: 'p1',
        finishTimeSeconds: 2400.0,
        averageWatts: 380.0,
        normalizedPower: 392.0,
        averageSpeedKmh: 28.5,
        weatherHash: 'WRONG_HASH',
        submittedAt: now,
      );
      final badValidation = service.validateStageResultSubmission(
        league: league,
        stageIndex: 1,
        entry: badWeatherEntry,
      );
      expect(badValidation.isValid, isFalse);

      final res1 = service.submitAndSyncStageResult(
        league: league,
        stageIndex: 1,
        entry: badWeatherEntry.copyWith(weatherHash: weatherHash),
        now: now,
      );
      expect(res1.stageCompleted, isFalse);
      expect(res1.eloUpdatedCount, 0);

      final res2 = service.submitAndSyncStageResult(
        league: res1.league,
        stageIndex: 1,
        entry: LeagueStageResultEntry(
          participantId: 'p2',
          finishTimeSeconds: 2450.0,
          averageWatts: 365.0,
          normalizedPower: 375.0,
          averageSpeedKmh: 27.8,
          weatherHash: weatherHash,
          submittedAt: now.add(const Duration(minutes: 10)),
        ),
        now: now.add(const Duration(minutes: 10)),
      );
      expect(res2.stageCompleted, isTrue);
      expect(res2.eloUpdatedCount, 2);
      expect(res2.league.status, LeagueStatus.completed);
      expect(res2.league.getParticipantById('p1')!.currentElo, greaterThan(1200));
      expect(res2.league.getParticipantById('p2')!.currentElo, lessThan(1250));
    });
  });

  group('.ppmleague file exchange & merge', () {
    test('encodes, decodes, validates and merges remote .ppmleague packages',
        () async {
      final league = _sampleLeague();
      final weatherHash = league.schedule.first.lockedWeather.weatherHash;
      final now = DateTime.utc(2026, 7, 2, 14, 0);

      final remoteLeague = service
          .submitAndSyncStageResult(
            league: league,
            stageIndex: 1,
            entry: LeagueStageResultEntry(
              participantId: 'p2',
              finishTimeSeconds: 2410.0,
              averageWatts: 370.0,
              normalizedPower: 380.0,
              averageSpeedKmh: 28.0,
              weatherHash: weatherHash,
              submittedAt: now,
            ),
            now: now,
          )
          .league;

      final package = MultiplayerLeaguePackage(
        exportedAt: now,
        league: remoteLeague,
        ghostChallenges: [_sampleChallenge()],
      );

      final exported = service.encodePackageToPpmLeague(package, compress: true);
      expect(exported.fileName, endsWith(kPpmLeagueFileExtension));
      expect(exported.encodedPayload, startsWith(kPpmLeagueGzipPrefix));

      final decoded = service.decodePackageFromPpmLeague(exported.encodedPayload);
      final report = service.validatePpmLeaguePackage(decoded);
      expect(report.isValid, isTrue);
      expect(report.checksumValid, isTrue);
      expect(report.challengeCount, 1);

      final tempDir = await Directory.systemTemp.createTemp('ppmleague_test_');
      try {
        final file = await service.exportPackageToFile(package, tempDir);
        expect(await file.exists(), isTrue);

        final inboxReport = await service.syncDirectoryInbox(
          exchangeDir: tempDir,
          localLeague: league,
          localChallenges: const [],
        );
        expect(inboxReport.addedResultsCount, 1);
        expect(inboxReport.addedChallengesCount, 1);
        expect(inboxReport.mergedLeague?.schedule.first.results.length, 1);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('rejects tampered .ppmleague checksum', () {
      final package = MultiplayerLeaguePackage(
        exportedAt: DateTime.utc(2026, 7, 2),
        ghostChallenges: [_sampleChallenge()],
      );
      final exported =
          service.encodePackageToPpmLeague(package, compress: false);
      final tampered = exported.encodedPayload.replaceFirst(
        'Mont Ventoux Challenge',
        'Tampered Challenge',
      );

      expect(
        () => service.decodePackageFromPpmLeague(tampered),
        throwsFormatException,
      );
    });
  });

  group('AsyncMultiplayerLeagueSyncPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(asyncMultiplayerLeagueSyncProvider.notifier).loadLeague(
              league: _sampleLeague(),
              ghostChallenges: [_sampleChallenge()],
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: AsyncMultiplayerLeagueSyncPanel(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('WorldTour Async Cup'), findsOneWidget);
        expect(find.text('Eksportuj .ppmleague'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
