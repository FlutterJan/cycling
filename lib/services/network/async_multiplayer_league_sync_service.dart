// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/multiplayer/online_league_and_ghost_challenge_model.dart';

/// Rozszerzenie pliku paczki ligi i wyzwań Pro Peloton Manager.
const String kPpmLeagueFileExtension = '.ppmleague';

/// Nagłówek nieskompresowanego formatu `.ppmleague`.
const String kPpmLeagueFormatMagic = 'PPMLEAGUE_V1:';

/// Nagłówek skompresowanego formatu GZip Base64 `.ppmleague`.
const String kPpmLeagueGzipPrefix = 'PPMLEAGUE_GZ_V1:';

/// Bieżąca wersja schematu `.ppmleague`.
const int kPpmLeagueSchemaVersion = 1;

/// Tryb transportu synchronizacji asynchronicznej ligi.
enum LeagueSyncTransportMode {
  localFileExchange,
  lanRelayHttp,
  cloudRelay;

  String get label {
    switch (this) {
      case LeagueSyncTransportMode.localFileExchange:
        return 'Wymiana plików .ppmleague';
      case LeagueSyncTransportMode.lanRelayHttp:
        return 'Lokalny przekaźnik LAN';
      case LeagueSyncTransportMode.cloudRelay:
        return 'Asynchroniczna chmura ligowa';
    }
  }
}

/// Faza pracy serwisu synchronizacji.
enum LeagueSyncPhase {
  idle,
  validating,
  drafting,
  syncingResults,
  packagingFile,
  importingFile,
  error;

  String get label {
    switch (this) {
      case LeagueSyncPhase.idle:
        return 'Gotowy do synchronizacji';
      case LeagueSyncPhase.validating:
        return 'Walidacja danych ligowych';
      case LeagueSyncPhase.drafting:
        return 'Draft kolarzy w toku';
      case LeagueSyncPhase.syncingResults:
        return 'Synchronizacja wyników i ELO';
      case LeagueSyncPhase.packagingFile:
        return 'Pakowanie pliku .ppmleague';
      case LeagueSyncPhase.importingFile:
        return 'Import i scalanie .ppmleague';
      case LeagueSyncPhase.error:
        return 'Błąd synchronizacji';
    }
  }
}

/// Strategia kolejności wyborów w drafcie ligowym.
enum DraftOrderStrategy {
  snake,
  linear,
  eloReverse;

  String toJson() => name;

  String get label {
    switch (this) {
      case DraftOrderStrategy.snake:
        return 'Snake (Wężyk)';
      case DraftOrderStrategy.linear:
        return 'Liniowy';
      case DraftOrderStrategy.eloReverse:
        return 'Odwrócone ELO';
    }
  }

  static DraftOrderStrategy fromJson(String value) {
    return DraftOrderStrategy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DraftOrderStrategy.snake,
    );
  }
}

/// Pojedynczy wybór kolarza w drafcie ligowym.
class DraftPickRecord {
  final int pickNumber;
  final int roundNumber;
  final String participantId;
  final String riderId;
  final String riderName;
  final DateTime pickedAt;
  final bool isAutoPick;

  const DraftPickRecord({
    required this.pickNumber,
    required this.roundNumber,
    required this.participantId,
    required this.riderId,
    required this.riderName,
    required this.pickedAt,
    this.isAutoPick = false,
  });

  Map<String, dynamic> toJson() => {
        'pickNumber': pickNumber,
        'roundNumber': roundNumber,
        'participantId': participantId,
        'riderId': riderId,
        'riderName': riderName,
        'pickedAt': pickedAt.toIso8601String(),
        'isAutoPick': isAutoPick,
      };

  factory DraftPickRecord.fromJson(Map<String, dynamic> json) {
    return DraftPickRecord(
      pickNumber: (json['pickNumber'] as num?)?.toInt() ?? 1,
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      participantId: json['participantId'] as String? ?? '',
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      pickedAt: DateTime.tryParse(json['pickedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      isAutoPick: json['isAutoPick'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DraftPickRecord &&
        other.pickNumber == pickNumber &&
        other.roundNumber == roundNumber &&
        other.participantId == participantId &&
        other.riderId == riderId &&
        other.riderName == riderName &&
        other.pickedAt == pickedAt &&
        other.isAutoPick == isAutoPick;
  }

  @override
  int get hashCode => Object.hash(
        pickNumber,
        roundNumber,
        participantId,
        riderId,
        riderName,
        pickedAt,
        isAutoPick,
      );
}

/// Stan asynchronicznej sesji draftu kolarzy dla ligi.
class LeagueDraftSessionState {
  final String leagueId;
  final DraftOrderStrategy strategy;
  final int ridersPerTeam;
  final List<String> availableRiderIds;
  final List<String> turnOrderParticipantIds;
  final int currentTurnIndex;
  final List<DraftPickRecord> picks;
  final LeagueDraftStatus status;
  final int turnDeadlineSeconds;

  const LeagueDraftSessionState({
    required this.leagueId,
    this.strategy = DraftOrderStrategy.snake,
    this.ridersPerTeam = 6,
    this.availableRiderIds = const [],
    this.turnOrderParticipantIds = const [],
    this.currentTurnIndex = 0,
    this.picks = const [],
    this.status = LeagueDraftStatus.notStarted,
    this.turnDeadlineSeconds = 60,
  });

  int get totalRequiredPicks =>
      turnOrderParticipantIds.length * math.max(1, ridersPerTeam);

  bool get isDraftComplete =>
      status == LeagueDraftStatus.completed ||
      (totalRequiredPicks > 0 && picks.length >= totalRequiredPicks) ||
      availableRiderIds.isEmpty;

  int get currentRound {
    if (turnOrderParticipantIds.isEmpty) return 1;
    return (currentTurnIndex ~/ turnOrderParticipantIds.length) + 1;
  }

  String? get currentParticipantId {
    if (isDraftComplete || turnOrderParticipantIds.isEmpty) return null;
    final n = turnOrderParticipantIds.length;
    final roundIndex = currentTurnIndex ~/ n;
    final posInRound = currentTurnIndex % n;
    if (strategy == DraftOrderStrategy.snake && roundIndex.isOdd) {
      return turnOrderParticipantIds[n - 1 - posInRound];
    }
    return turnOrderParticipantIds[posInRound];
  }

  int picksMadeBy(String participantId) {
    return picks.where((p) => p.participantId == participantId).length;
  }

  int remainingPicksFor(String participantId) {
    return math.max(0, ridersPerTeam - picksMadeBy(participantId));
  }

  LeagueDraftSessionState copyWith({
    String? leagueId,
    DraftOrderStrategy? strategy,
    int? ridersPerTeam,
    List<String>? availableRiderIds,
    List<String>? turnOrderParticipantIds,
    int? currentTurnIndex,
    List<DraftPickRecord>? picks,
    LeagueDraftStatus? status,
    int? turnDeadlineSeconds,
  }) {
    return LeagueDraftSessionState(
      leagueId: leagueId ?? this.leagueId,
      strategy: strategy ?? this.strategy,
      ridersPerTeam: ridersPerTeam ?? this.ridersPerTeam,
      availableRiderIds: availableRiderIds ?? this.availableRiderIds,
      turnOrderParticipantIds:
          turnOrderParticipantIds ?? this.turnOrderParticipantIds,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      picks: picks ?? this.picks,
      status: status ?? this.status,
      turnDeadlineSeconds: turnDeadlineSeconds ?? this.turnDeadlineSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'leagueId': leagueId,
        'strategy': strategy.toJson(),
        'ridersPerTeam': ridersPerTeam,
        'availableRiderIds': availableRiderIds,
        'turnOrderParticipantIds': turnOrderParticipantIds,
        'currentTurnIndex': currentTurnIndex,
        'picks': picks.map((e) => e.toJson()).toList(),
        'status': status.toJson(),
        'turnDeadlineSeconds': turnDeadlineSeconds,
      };

  factory LeagueDraftSessionState.fromJson(Map<String, dynamic> json) {
    final rawAvailable = json['availableRiderIds'] as List<dynamic>? ?? const [];
    final rawOrder =
        json['turnOrderParticipantIds'] as List<dynamic>? ?? const [];
    final rawPicks = json['picks'] as List<dynamic>? ?? const [];
    return LeagueDraftSessionState(
      leagueId: json['leagueId'] as String? ?? '',
      strategy: DraftOrderStrategy.fromJson(
        json['strategy'] as String? ?? 'snake',
      ),
      ridersPerTeam: math.max(1, (json['ridersPerTeam'] as num?)?.toInt() ?? 6),
      availableRiderIds: rawAvailable.map((e) => e.toString()).toList(),
      turnOrderParticipantIds: rawOrder.map((e) => e.toString()).toList(),
      currentTurnIndex: (json['currentTurnIndex'] as num?)?.toInt() ?? 0,
      picks: rawPicks
          .whereType<Map<String, dynamic>>()
          .map(DraftPickRecord.fromJson)
          .toList(growable: false),
      status: LeagueDraftStatus.fromJson(
        json['status'] as String? ?? 'notStarted',
      ),
      turnDeadlineSeconds:
          math.max(10, (json['turnDeadlineSeconds'] as num?)?.toInt() ?? 60),
    );
  }
}

/// Wynik walidacji zgłoszenia wyniku etapu ligowego.
class StageResultSubmissionValidation {
  final bool isValid;
  final List<String> issues;
  final String computedChecksum;

  const StageResultSubmissionValidation({
    required this.isValid,
    required this.issues,
    required this.computedChecksum,
  });
}

/// Opis konfliktu rozwiązanego podczas scalania paczki `.ppmleague`.
class LeagueSyncMergeConflict {
  final String category;
  final String identifier;
  final String resolution;
  final String details;

  const LeagueSyncMergeConflict({
    required this.category,
    required this.identifier,
    required this.resolution,
    required this.details,
  });
}

/// Raport z asynchronicznego scalania paczki `.ppmleague`.
class LeagueSyncMergeReport {
  final OnlineLeagueModel? mergedLeague;
  final List<GhostChallengeModel> mergedChallenges;
  final int addedResultsCount;
  final int updatedResultsCount;
  final int addedChallengesCount;
  final int updatedEloCount;
  final List<LeagueSyncMergeConflict> conflicts;
  final DateTime syncedAt;

  const LeagueSyncMergeReport({
    required this.mergedLeague,
    required this.mergedChallenges,
    required this.addedResultsCount,
    required this.updatedResultsCount,
    required this.addedChallengesCount,
    required this.updatedEloCount,
    required this.conflicts,
    required this.syncedAt,
  });
}

/// Wynik walidacji paczki `.ppmleague`.
class PpmLeaguePackageValidationReport {
  final bool isValid;
  final bool hasLeague;
  final int challengeCount;
  final int participantCount;
  final int stageResultCount;
  final bool checksumValid;
  final List<String> issues;

  const PpmLeaguePackageValidationReport({
    required this.isValid,
    required this.hasLeague,
    required this.challengeCount,
    required this.participantCount,
    required this.stageResultCount,
    required this.checksumValid,
    required this.issues,
  });
}

/// Rezultat spakowania i zapisu pliku `.ppmleague`.
class PpmLeagueFileExportResult {
  final String fileName;
  final String encodedPayload;
  final int uncompressedByteSize;
  final int compressedByteSize;
  final String checksum;
  final DateTime exportedAt;

  const PpmLeagueFileExportResult({
    required this.fileName,
    required this.encodedPayload,
    required this.uncompressedByteSize,
    required this.compressedByteSize,
    required this.checksum,
    required this.exportedAt,
  });

  double get compressionRatio {
    if (uncompressedByteSize <= 0) return 1.0;
    return compressedByteSize / uncompressedByteSize;
  }
}

/// Wpis dziennika synchronizacji ligowej.
class LeagueSyncLogEntry {
  final DateTime timestamp;
  final String title;
  final String detail;
  final bool isError;

  const LeagueSyncLogEntry({
    required this.timestamp,
    required this.title,
    required this.detail,
    this.isError = false,
  });
}

/// Główny serwis synchronizacji wyników etapów ligowych, draftu kolarzy
/// oraz wymiany plików wyzwań `.ppmleague`.
class AsyncMultiplayerLeagueSyncService {
  const AsyncMultiplayerLeagueSyncService();

  /// Tworzy nową sesję draftu kolarzy dla uczestników ligi.
  ({OnlineLeagueModel league, LeagueDraftSessionState draftState})
      createDraftSession(
    OnlineLeagueModel league, {
    required List<String> availableRiderIds,
    DraftOrderStrategy strategy = DraftOrderStrategy.snake,
    int ridersPerTeam = 6,
    int turnDeadlineSeconds = 60,
  }) {
    if (league.participants.isEmpty) {
      throw StateError('Nie można rozpocząć draftu bez uczestników w lidze.');
    }
    final sanitizedRiders = availableRiderIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (sanitizedRiders.isEmpty) {
      throw ArgumentError('Pula kolarzy do draftu nie może być pusta.');
    }

    final sortedParticipants = List<LeagueParticipantEntry>.from(
      league.participants,
    );
    if (strategy == DraftOrderStrategy.eloReverse) {
      sortedParticipants.sort((a, b) => a.currentElo.compareTo(b.currentElo));
    } else {
      sortedParticipants.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    }

    final turnOrder = sortedParticipants
        .map((p) => p.participantId)
        .toList(growable: false);

    final draftState = LeagueDraftSessionState(
      leagueId: league.leagueId,
      strategy: strategy,
      ridersPerTeam: math.max(1, ridersPerTeam),
      availableRiderIds: sanitizedRiders,
      turnOrderParticipantIds: turnOrder,
      currentTurnIndex: 0,
      picks: const [],
      status: LeagueDraftStatus.inProgress,
      turnDeadlineSeconds: math.max(10, turnDeadlineSeconds),
    );

    final updatedLeague = league.copyWith(
      status: LeagueStatus.drafting,
      draftStatus: LeagueDraftStatus.inProgress,
    );

    return (league: updatedLeague, draftState: draftState);
  }

  /// Rejestruje wybór kolarza w drafcie ligowym i aktualizuje składy uczestników.
  ({
    OnlineLeagueModel league,
    LeagueDraftSessionState draftState,
    DraftPickRecord pick,
  }) submitDraftPick({
    required OnlineLeagueModel league,
    required LeagueDraftSessionState draftState,
    required String participantId,
    required String riderId,
    String riderName = '',
    bool isAutoPick = false,
    DateTime? now,
  }) {
    if (draftState.isDraftComplete) {
      throw StateError('Draft ligi ${league.name} został już zakończony.');
    }

    final expectedId = draftState.currentParticipantId;
    if (expectedId == null || expectedId != participantId) {
      throw StateError(
        'Kolej wyboru należy do uczestnika $expectedId, a nie $participantId.',
      );
    }

    if (!draftState.availableRiderIds.contains(riderId)) {
      throw ArgumentError(
        'Kolarz $riderId nie jest dostępny w puli draftu.',
      );
    }

    final participant = league.getParticipantById(participantId);
    if (participant == null) {
      throw ArgumentError(
        'Uczestnik $participantId nie należy do ligi ${league.leagueId}.',
      );
    }
    if (participant.draftedRiderIds.contains(riderId)) {
      throw StateError('Uczestnik $participantId ma już kolarza $riderId.');
    }

    final timestamp = (now ?? DateTime.now()).toUtc();
    final pick = DraftPickRecord(
      pickNumber: draftState.picks.length + 1,
      roundNumber: draftState.currentRound,
      participantId: participantId,
      riderId: riderId,
      riderName: riderName.isNotEmpty ? riderName : riderId,
      pickedAt: timestamp,
      isAutoPick: isAutoPick,
    );

    final remainingRiders = draftState.availableRiderIds
        .where((id) => id != riderId)
        .toList(growable: false);
    final updatedPicks = [...draftState.picks, pick];
    final nextTurnIndex = draftState.currentTurnIndex + 1;

    final draftFinished =
        updatedPicks.length >= draftState.totalRequiredPicks ||
            remainingRiders.isEmpty;

    final updatedDraft = draftState.copyWith(
      availableRiderIds: remainingRiders,
      picks: updatedPicks,
      currentTurnIndex: nextTurnIndex,
      status: draftFinished
          ? LeagueDraftStatus.completed
          : LeagueDraftStatus.inProgress,
    );

    final updatedParticipants = league.participants.map((p) {
      if (p.participantId != participantId) return p;
      return p.copyWith(
        draftedRiderIds: [...p.draftedRiderIds, riderId],
        isReady: draftFinished ? true : p.isReady,
        lastSyncedAt: timestamp,
      );
    }).toList(growable: false);

    final updatedLeague = league.copyWith(
      participants: updatedParticipants,
      draftStatus: updatedDraft.status,
      status: draftFinished ? LeagueStatus.active : LeagueStatus.drafting,
    );

    return (league: updatedLeague, draftState: updatedDraft, pick: pick);
  }

  /// Wykonuje automatyczny wybór pierwszego dostępnego kolarza dla bieżącej tury.
  ({
    OnlineLeagueModel league,
    LeagueDraftSessionState draftState,
    DraftPickRecord pick,
  }) autoPickForCurrentTurn({
    required OnlineLeagueModel league,
    required LeagueDraftSessionState draftState,
    DateTime? now,
  }) {
    final currentId = draftState.currentParticipantId;
    if (currentId == null || draftState.availableRiderIds.isEmpty) {
      throw StateError('Brak aktywnej tury lub wolnych kolarzy do auto-picku.');
    }
    final nextRiderId = draftState.availableRiderIds.first;
    return submitDraftPick(
      league: league,
      draftState: draftState,
      participantId: currentId,
      riderId: nextRiderId,
      riderName: nextRiderId,
      isAutoPick: true,
      now: now,
    );
  }

  /// Oblicza deterministyczną sumę kontrolną FNV-1a64 dla wyniku etapu ligowego.
  String computeStageResultChecksum(
    LeagueStageResultEntry entry, {
    required String leagueId,
    required int stageIndex,
  }) {
    final canonical = [
      leagueId,
      stageIndex.toString(),
      entry.participantId,
      entry.finishTimeSeconds.toStringAsFixed(3),
      entry.averageWatts.toStringAsFixed(2),
      entry.normalizedPower.toStringAsFixed(2),
      entry.averageSpeedKmh.toStringAsFixed(2),
      entry.weatherHash,
    ].join('|');
    return _fnv1a64Hex(canonical);
  }

  /// Waliduje wynik etapu ligowego pod kątem spójności pogody, fizyki i sumy kontrolnej.
  StageResultSubmissionValidation validateStageResultSubmission({
    required OnlineLeagueModel league,
    required int stageIndex,
    required LeagueStageResultEntry entry,
    bool requireValidChecksum = false,
  }) {
    final issues = <String>[];
    final participant = league.getParticipantById(entry.participantId);
    if (participant == null) {
      issues.add('Nieznany uczestnik ligi: ${entry.participantId}.');
    }

    LeagueStageScheduleEntry? stage;
    for (final s in league.schedule) {
      if (s.stageIndex == stageIndex) {
        stage = s;
        break;
      }
    }
    if (stage == null) {
      issues.add('Etap o indeksie $stageIndex nie istnieje w harmonogramie.');
    } else {
      if (league.scoringRules.enforceIdenticalWeather &&
          entry.weatherHash != stage.lockedWeather.weatherHash) {
        issues.add(
          'Niezgodność pogody etapu $stageIndex: oczekiwano ${stage.lockedWeather.weatherHash}, otrzymano ${entry.weatherHash}.',
        );
      }
    }

    if (entry.finishTimeSeconds <= 0) {
      issues.add('Czas ukończenia etapu musi być dodatni.');
    }
    if (entry.averageWatts < 50 || entry.averageWatts > 650) {
      issues.add(
        'Średnia moc (${entry.averageWatts.toStringAsFixed(1)} W) poza zakresem fizjologicznym (50–650 W).',
      );
    }
    if (entry.normalizedPower < entry.averageWatts * 0.85 ||
        entry.normalizedPower > 750) {
      issues.add(
        'Moc znormalizowana NP (${entry.normalizedPower.toStringAsFixed(1)} W) niespójna ze średnią mocą.',
      );
    }
    if (entry.averageSpeedKmh <= 5 || entry.averageSpeedKmh > 68) {
      issues.add(
        'Średnia prędkość (${entry.averageSpeedKmh.toStringAsFixed(1)} km/h) poza realistycznym zakresem.',
      );
    }

    final expectedChecksum = computeStageResultChecksum(
      entry,
      leagueId: league.leagueId,
      stageIndex: stageIndex,
    );
    if (requireValidChecksum &&
        entry.verificationChecksum != expectedChecksum) {
      issues.add('Nieprawidłowa suma kontrolna wyniku etapu.');
    }

    return StageResultSubmissionValidation(
      isValid: issues.isEmpty,
      issues: issues,
      computedChecksum: expectedChecksum,
    );
  }

  /// Zapisuje wynik etapu ligowego, nadaje sumę kontrolną oraz przelicza ELO,
  /// jeśli wszyscy uczestnicy ukończyli etap.
  ({OnlineLeagueModel league, bool stageCompleted, int eloUpdatedCount})
      submitAndSyncStageResult({
    required OnlineLeagueModel league,
    required int stageIndex,
    required LeagueStageResultEntry entry,
    DateTime? now,
  }) {
    final validation = validateStageResultSubmission(
      league: league,
      stageIndex: stageIndex,
      entry: entry,
    );
    if (!validation.isValid) {
      throw ArgumentError(validation.issues.join(' '));
    }

    final timestamp = (now ?? DateTime.now()).toUtc();
    final stampedEntry = entry.copyWith(
      verificationChecksum: validation.computedChecksum,
      submittedAt: entry.submittedAt,
    );

    var updatedLeague = league.recordStageResult(stageIndex, stampedEntry);

    LeagueStageScheduleEntry? updatedStage;
    for (final s in updatedLeague.schedule) {
      if (s.stageIndex == stageIndex) {
        updatedStage = s;
        break;
      }
    }

    var eloUpdatedCount = 0;
    final stageCompleted = updatedStage != null &&
        updatedStage.isAllSubmitted(updatedLeague.participants.length);

    if (stageCompleted) {
      final sortedResults = updatedStage.sortedResults;
      final orderedRatings = <int>[];
      final orderedParticipantIds = <String>[];

      for (final result in sortedResults) {
        final participant =
            updatedLeague.getParticipantById(result.participantId);
        if (participant != null) {
          orderedRatings.add(participant.currentElo);
          orderedParticipantIds.add(participant.participantId);
        }
      }

      if (orderedRatings.length >= 2) {
        final deltas = EloCalculator.calculateMultiPlayerStageDeltas(
          orderedRatings: orderedRatings,
        );
        final deltaByParticipant = <String, int>{};
        for (var i = 0; i < orderedParticipantIds.length; i++) {
          deltaByParticipant[orderedParticipantIds[i]] = deltas[i];
        }

        final eloUpdatedParticipants = updatedLeague.participants.map((p) {
          final delta = deltaByParticipant[p.participantId];
          if (delta == null) {
            return p.copyWith(lastSyncedAt: timestamp);
          }
          eloUpdatedCount++;
          return p.copyWith(
            currentElo: math.max(
              EloCalculator.minEloFloor,
              p.currentElo + delta,
            ),
            lastSyncedAt: timestamp,
          );
        }).toList(growable: false);

        final allStagesComplete = updatedLeague.schedule.isNotEmpty &&
            updatedLeague.completedStageCount >= updatedLeague.schedule.length;

        updatedLeague = updatedLeague.copyWith(
          participants: eloUpdatedParticipants,
          status: allStagesComplete
              ? LeagueStatus.completed
              : updatedLeague.status,
        );
      }
    } else {
      final syncedParticipants = updatedLeague.participants.map((p) {
        if (p.participantId != entry.participantId) return p;
        return p.copyWith(lastSyncedAt: timestamp);
      }).toList(growable: false);
      updatedLeague = updatedLeague.copyWith(participants: syncedParticipants);
    }

    return (
      league: updatedLeague,
      stageCompleted: stageCompleted,
      eloUpdatedCount: eloUpdatedCount,
    );
  }

  /// Pakuje stan ligi i wyzwań duchów do formatu tekstowego `.ppmleague`
  /// z sumą kontrolną FNV-1a64 i opcjonalną kompresją GZip.
  PpmLeagueFileExportResult encodePackageToPpmLeague(
    MultiplayerLeaguePackage package, {
    String? fileName,
    bool compress = true,
  }) {
    final signedPackage = package.withValidChecksum();
    final jsonString = jsonEncode(signedPackage.toJson());
    final utf8Bytes = utf8.encode(jsonString);

    final String encodedPayload;
    final int compressedSize;
    if (compress) {
      final gzipped = gzip.encode(utf8Bytes);
      encodedPayload = '$kPpmLeagueGzipPrefix${base64Encode(gzipped)}';
      compressedSize = encodedPayload.length;
    } else {
      encodedPayload = '$kPpmLeagueFormatMagic$jsonString';
      compressedSize = encodedPayload.length;
    }

    final resolvedFileName = _normalizePpmLeagueFileName(
      fileName ??
          signedPackage.league?.leagueId ??
          (signedPackage.ghostChallenges.isNotEmpty
              ? signedPackage.ghostChallenges.first.challengeId
              : 'league_sync'),
    );

    return PpmLeagueFileExportResult(
      fileName: resolvedFileName,
      encodedPayload: encodedPayload,
      uncompressedByteSize: utf8Bytes.length,
      compressedByteSize: compressedSize,
      checksum: signedPackage.integrityChecksum,
      exportedAt: signedPackage.exportedAt,
    );
  }

  /// Dekoduje plik `.ppmleague` (skompresowany lub jawny JSON) i weryfikuje sumę kontrolną.
  MultiplayerLeaguePackage decodePackageFromPpmLeague(String rawContent) {
    final trimmed = rawContent.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Zawartość pliku .ppmleague jest pusta.');
    }

    String jsonPayload;
    if (trimmed.startsWith(kPpmLeagueGzipPrefix)) {
      final b64 = trimmed.substring(kPpmLeagueGzipPrefix.length).trim();
      final compressedBytes = base64Decode(b64);
      final decompressedBytes = gzip.decode(compressedBytes);
      jsonPayload = utf8.decode(decompressedBytes);
    } else if (trimmed.startsWith(kPpmLeagueFormatMagic)) {
      jsonPayload = trimmed.substring(kPpmLeagueFormatMagic.length).trim();
    } else if (trimmed.startsWith('{')) {
      jsonPayload = trimmed;
    } else {
      throw const FormatException(
        'Nieznany nagłówek pliku .ppmleague (oczekiwano PPMLEAGUE_GZ_V1 lub PPMLEAGUE_V1).',
      );
    }

    final decoded = jsonDecode(jsonPayload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Nieprawidłowa struktura JSON wewnątrz pliku .ppmleague.',
      );
    }

    final package = MultiplayerLeaguePackage.fromJson(decoded);
    if (!package.isChecksumValid) {
      throw const FormatException(
        'Suma kontrolna paczki .ppmleague jest nieprawidłowa — plik mógł zostać uszkodzony lub zmodyfikowany.',
      );
    }
    return package;
  }

  /// Przeprowadza pełną walidację zawartości paczki `.ppmleague`.
  PpmLeaguePackageValidationReport validatePpmLeaguePackage(
    MultiplayerLeaguePackage package,
  ) {
    final issues = <String>[];
    final checksumValid = package.isChecksumValid;
    if (!checksumValid) {
      issues.add('Nieprawidłowa suma kontrolna paczki.');
    }
    if (package.formatVersion > MultiplayerLeaguePackage.currentFormatVersion) {
      issues.add(
        'Nowsza wersja formatu paczki (${package.formatVersion}) niż obsługiwana (${MultiplayerLeaguePackage.currentFormatVersion}).',
      );
    }
    if (package.league == null && package.ghostChallenges.isEmpty) {
      issues.add('Paczka nie zawiera ani ligi, ani wyzwań duchów.');
    }

    var resultCount = 0;
    final league = package.league;
    if (league != null) {
      if (league.leagueId.trim().isEmpty) {
        issues.add('Liga w paczce nie posiada identyfikatora leagueId.');
      }
      for (final stage in league.schedule) {
        resultCount += stage.results.length;
      }
    }

    for (final challenge in package.ghostChallenges) {
      if (challenge.challengeId.trim().isEmpty) {
        issues.add('Wyzwanie ducha nie posiada identyfikatora challengeId.');
      }
      if (challenge.targetFinishTimeSeconds <= 0) {
        issues.add(
          'Wyzwanie ${challenge.challengeId} ma nieprawidłowy czas docelowy.',
        );
      }
    }

    return PpmLeaguePackageValidationReport(
      isValid: issues.isEmpty,
      hasLeague: league != null,
      challengeCount: package.ghostChallenges.length,
      participantCount: league?.participants.length ?? 0,
      stageResultCount: resultCount,
      checksumValid: checksumValid,
      issues: issues,
    );
  }

  /// Atomowo zapisuje paczkę `.ppmleague` na dysk (przez plik `.tmp` i rename).
  Future<File> exportPackageToFile(
    MultiplayerLeaguePackage package,
    Directory targetDir, {
    String? fileName,
    bool compress = true,
  }) async {
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final encoded = encodePackageToPpmLeague(
      package,
      fileName: fileName,
      compress: compress,
    );
    final sep = Platform.pathSeparator;
    final finalPath = '${targetDir.path}$sep${encoded.fileName}';
    final tempFile = File('$finalPath.tmp');
    await tempFile.writeAsString(encoded.encodedPayload, flush: true);
    return tempFile.rename(finalPath);
  }

  /// Wczytuje i dekoduje plik `.ppmleague` z dysku.
  Future<MultiplayerLeaguePackage> importPackageFromFile(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('Plik .ppmleague nie istnieje', file.path);
    }
    final raw = await file.readAsString();
    return decodePackageFromPpmLeague(raw);
  }

  /// Scala zdalną paczkę `.ppmleague` z lokalnym stanem ligi i wyzwań duchów,
  /// wykrywając i rozwiązując konflikty według znaczników czasu oraz sum kontrolnych.
  LeagueSyncMergeReport mergeRemotePackage({
    required OnlineLeagueModel? localLeague,
    required List<GhostChallengeModel> localChallenges,
    required MultiplayerLeaguePackage remotePackage,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    final conflicts = <LeagueSyncMergeConflict>[];
    var addedResults = 0;
    var updatedResults = 0;
    var updatedEloCount = 0;

    OnlineLeagueModel? mergedLeague = localLeague;
    final remoteLeague = remotePackage.league;

    if (remoteLeague != null) {
      if (localLeague == null) {
        mergedLeague = remoteLeague;
        for (final stage in remoteLeague.schedule) {
          addedResults += stage.results.length;
        }
      } else if (localLeague.leagueId != remoteLeague.leagueId) {
        conflicts.add(
          LeagueSyncMergeConflict(
            category: 'leagueId',
            identifier: remoteLeague.leagueId,
            resolution: 'kept_local',
            details:
                'Zdalna paczka dotyczy innej ligi (${remoteLeague.leagueId}) niż aktywna (${localLeague.leagueId}).',
          ),
        );
      } else {
        final mergedParticipantsMap = <String, LeagueParticipantEntry>{
          for (final p in localLeague.participants) p.participantId: p,
        };

        for (final remoteP in remoteLeague.participants) {
          final existing = mergedParticipantsMap[remoteP.participantId];
          if (existing == null) {
            mergedParticipantsMap[remoteP.participantId] = remoteP;
          } else {
            final remoteNewer = remoteP.lastSyncedAt != null &&
                (existing.lastSyncedAt == null ||
                    remoteP.lastSyncedAt!.isAfter(existing.lastSyncedAt!));
            final mergedDrafted = remoteP.draftedRiderIds.length >
                    existing.draftedRiderIds.length
                ? remoteP.draftedRiderIds
                : existing.draftedRiderIds;
            if (remoteNewer) {
              if (existing.currentElo != remoteP.currentElo) {
                updatedEloCount++;
              }
              mergedParticipantsMap[remoteP.participantId] = remoteP.copyWith(
                draftedRiderIds: mergedDrafted,
              );
            } else {
              mergedParticipantsMap[remoteP.participantId] = existing.copyWith(
                draftedRiderIds: mergedDrafted,
              );
            }
          }
        }

        var workingLeague = localLeague.copyWith(
          participants: mergedParticipantsMap.values.toList(growable: false),
          draftStatus: remoteLeague.draftStatus.index >
                  localLeague.draftStatus.index
              ? remoteLeague.draftStatus
              : localLeague.draftStatus,
          status: remoteLeague.status.index > localLeague.status.index
              ? remoteLeague.status
              : localLeague.status,
        );

        for (final remoteStage in remoteLeague.schedule) {
          final localStageIndex = workingLeague.schedule.indexWhere(
            (s) => s.stageIndex == remoteStage.stageIndex,
          );
          if (localStageIndex == -1) continue;
          final localStage = workingLeague.schedule[localStageIndex];

          for (final remoteResult in remoteStage.results) {
            if (workingLeague.scoringRules.enforceIdenticalWeather &&
                remoteResult.weatherHash !=
                    localStage.lockedWeather.weatherHash) {
              conflicts.add(
                LeagueSyncMergeConflict(
                  category: 'weatherHash',
                  identifier:
                      'stage_${remoteStage.stageIndex}_${remoteResult.participantId}',
                  resolution: 'rejected_remote',
                  details:
                      'Niezgodność pogody (${remoteResult.weatherHash} != ${localStage.lockedWeather.weatherHash}).',
                ),
              );
              continue;
            }

            final existingIdx = localStage.results.indexWhere(
              (r) => r.participantId == remoteResult.participantId,
            );
            if (existingIdx == -1) {
              workingLeague = workingLeague.recordStageResult(
                remoteStage.stageIndex,
                remoteResult,
              );
              addedResults++;
            } else {
              final existingResult = localStage.results[existingIdx];
              if (remoteResult.submittedAt.isAfter(existingResult.submittedAt)) {
                workingLeague = workingLeague.recordStageResult(
                  remoteStage.stageIndex,
                  remoteResult,
                );
                updatedResults++;
                conflicts.add(
                  LeagueSyncMergeConflict(
                    category: 'stageResult',
                    identifier:
                        'stage_${remoteStage.stageIndex}_${remoteResult.participantId}',
                    resolution: 'accepted_newer_remote',
                    details: 'Zaktualizowano wynik nowszym zgłoszeniem.',
                  ),
                );
              }
            }
          }
        }

        mergedLeague = workingLeague;
      }
    }

    final challengeMap = <String, GhostChallengeModel>{
      for (final c in localChallenges) c.challengeId: c,
    };
    var addedChallenges = 0;

    for (final remoteChallenge in remotePackage.ghostChallenges) {
      final existing = challengeMap[remoteChallenge.challengeId];
      if (existing == null) {
        challengeMap[remoteChallenge.challengeId] = remoteChallenge;
        addedChallenges++;
      } else {
        final mergedAttempts = <String, GhostAttemptResult>{
          for (final a in existing.attempts) a.attemptId: a,
        };
        for (final a in remoteChallenge.attempts) {
          mergedAttempts.putIfAbsent(a.attemptId, () => a);
        }
        final sortedAttempts = mergedAttempts.values.toList(growable: false)
          ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
        challengeMap[remoteChallenge.challengeId] = existing.copyWith(
          attempts: sortedAttempts,
          status: remoteChallenge.status.index > existing.status.index
              ? remoteChallenge.status
              : existing.status,
        );
      }
    }

    return LeagueSyncMergeReport(
      mergedLeague: mergedLeague,
      mergedChallenges: challengeMap.values.toList(growable: false),
      addedResultsCount: addedResults,
      updatedResultsCount: updatedResults,
      addedChallengesCount: addedChallenges,
      updatedEloCount: updatedEloCount,
      conflicts: conflicts,
      syncedAt: timestamp,
    );
  }

  /// Skanuje folder wymiany plików `.ppmleague` i scala wszystkie poprawne paczki.
  Future<LeagueSyncMergeReport> syncDirectoryInbox({
    required Directory exchangeDir,
    required OnlineLeagueModel? localLeague,
    required List<GhostChallengeModel> localChallenges,
  }) async {
    var currentLeague = localLeague;
    var currentChallenges = List<GhostChallengeModel>.from(localChallenges);
    var totalAddedResults = 0;
    var totalUpdatedResults = 0;
    var totalAddedChallenges = 0;
    var totalUpdatedElo = 0;
    final allConflicts = <LeagueSyncMergeConflict>[];

    if (await exchangeDir.exists()) {
      final entities = await exchangeDir.list().toList();
      final leagueFiles = entities
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith(kPpmLeagueFileExtension))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      for (final file in leagueFiles) {
        try {
          final package = await importPackageFromFile(file);
          final report = mergeRemotePackage(
            localLeague: currentLeague,
            localChallenges: currentChallenges,
            remotePackage: package,
          );
          currentLeague = report.mergedLeague;
          currentChallenges = report.mergedChallenges;
          totalAddedResults += report.addedResultsCount;
          totalUpdatedResults += report.updatedResultsCount;
          totalAddedChallenges += report.addedChallengesCount;
          totalUpdatedElo += report.updatedEloCount;
          allConflicts.addAll(report.conflicts);
        } catch (e) {
          allConflicts.add(
            LeagueSyncMergeConflict(
              category: 'fileReadError',
              identifier: file.path,
              resolution: 'skipped',
              details: e.toString(),
            ),
          );
        }
      }
    }

    return LeagueSyncMergeReport(
      mergedLeague: currentLeague,
      mergedChallenges: currentChallenges,
      addedResultsCount: totalAddedResults,
      updatedResultsCount: totalUpdatedResults,
      addedChallengesCount: totalAddedChallenges,
      updatedEloCount: totalUpdatedElo,
      conflicts: allConflicts,
      syncedAt: DateTime.now().toUtc(),
    );
  }

  String _normalizePpmLeagueFileName(String rawBase) {
    final sanitized = rawBase
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final base = sanitized.isEmpty ? 'league_sync' : sanitized;
    if (base.toLowerCase().endsWith(kPpmLeagueFileExtension)) {
      return base;
    }
    return '$base$kPpmLeagueFileExtension';
  }
}

/// Stan kontrolera Riverpod dla asynchronicznej synchronizacji ligi.
class AsyncMultiplayerLeagueSyncState {
  final OnlineLeagueModel? activeLeague;
  final LeagueDraftSessionState? draftSession;
  final List<GhostChallengeModel> ghostChallenges;
  final EloRatingProfile? playerEloProfile;
  final LeagueSyncPhase phase;
  final LeagueSyncTransportMode transportMode;
  final PpmLeagueFileExportResult? lastExportResult;
  final LeagueSyncMergeReport? lastMergeReport;
  final List<LeagueSyncLogEntry> syncLogs;
  final String? lastError;

  const AsyncMultiplayerLeagueSyncState({
    this.activeLeague,
    this.draftSession,
    this.ghostChallenges = const [],
    this.playerEloProfile,
    this.phase = LeagueSyncPhase.idle,
    this.transportMode = LeagueSyncTransportMode.localFileExchange,
    this.lastExportResult,
    this.lastMergeReport,
    this.syncLogs = const [],
    this.lastError,
  });

  AsyncMultiplayerLeagueSyncState copyWith({
    OnlineLeagueModel? activeLeague,
    bool clearActiveLeague = false,
    LeagueDraftSessionState? draftSession,
    bool clearDraftSession = false,
    List<GhostChallengeModel>? ghostChallenges,
    EloRatingProfile? playerEloProfile,
    LeagueSyncPhase? phase,
    LeagueSyncTransportMode? transportMode,
    PpmLeagueFileExportResult? lastExportResult,
    LeagueSyncMergeReport? lastMergeReport,
    List<LeagueSyncLogEntry>? syncLogs,
    String? lastError,
    bool clearLastError = false,
  }) {
    return AsyncMultiplayerLeagueSyncState(
      activeLeague:
          clearActiveLeague ? null : (activeLeague ?? this.activeLeague),
      draftSession:
          clearDraftSession ? null : (draftSession ?? this.draftSession),
      ghostChallenges: ghostChallenges ?? this.ghostChallenges,
      playerEloProfile: playerEloProfile ?? this.playerEloProfile,
      phase: phase ?? this.phase,
      transportMode: transportMode ?? this.transportMode,
      lastExportResult: lastExportResult ?? this.lastExportResult,
      lastMergeReport: lastMergeReport ?? this.lastMergeReport,
      syncLogs: syncLogs ?? this.syncLogs,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Notifier zarządzający stanem synchronizacji ligi, draftu i paczek `.ppmleague`.
class AsyncMultiplayerLeagueSyncNotifier
    extends StateNotifier<AsyncMultiplayerLeagueSyncState> {
  final AsyncMultiplayerLeagueSyncService _service;

  AsyncMultiplayerLeagueSyncNotifier({
    AsyncMultiplayerLeagueSyncService service =
        const AsyncMultiplayerLeagueSyncService(),
    AsyncMultiplayerLeagueSyncState? initialState,
  })  : _service = service,
        super(initialState ?? const AsyncMultiplayerLeagueSyncState());

  void loadLeague({
    required OnlineLeagueModel league,
    List<GhostChallengeModel>? ghostChallenges,
    EloRatingProfile? playerEloProfile,
  }) {
    state = state.copyWith(
      activeLeague: league,
      ghostChallenges: ghostChallenges ?? state.ghostChallenges,
      playerEloProfile: playerEloProfile ?? state.playerEloProfile,
      phase: LeagueSyncPhase.idle,
      clearLastError: true,
      syncLogs: _appendLog(
        title: 'Załadowano ligę ${league.name}',
        detail:
            '${league.participants.length} uczestników, ${league.schedule.length} etapów.',
      ),
    );
  }

  void setTransportMode(LeagueSyncTransportMode mode) {
    state = state.copyWith(transportMode: mode);
  }

  void startDraft({
    required List<String> availableRiderIds,
    DraftOrderStrategy strategy = DraftOrderStrategy.snake,
    int ridersPerTeam = 6,
  }) {
    final league = state.activeLeague;
    if (league == null) {
      _setError('Brak aktywnej ligi do rozpoczęcia draftu.');
      return;
    }
    try {
      final result = _service.createDraftSession(
        league,
        availableRiderIds: availableRiderIds,
        strategy: strategy,
        ridersPerTeam: ridersPerTeam,
      );
      state = state.copyWith(
        activeLeague: result.league,
        draftSession: result.draftState,
        phase: LeagueSyncPhase.drafting,
        clearLastError: true,
        syncLogs: _appendLog(
          title: 'Rozpoczęto draft (${strategy.label})',
          detail: 'Pula ${availableRiderIds.length} kolarzy.',
        ),
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  void makeDraftPick({
    required String participantId,
    required String riderId,
    String riderName = '',
  }) {
    final league = state.activeLeague;
    final draft = state.draftSession;
    if (league == null || draft == null) {
      _setError('Sesja draftu nie jest aktywna.');
      return;
    }
    try {
      final result = _service.submitDraftPick(
        league: league,
        draftState: draft,
        participantId: participantId,
        riderId: riderId,
        riderName: riderName,
      );
      state = state.copyWith(
        activeLeague: result.league,
        draftSession: result.draftState,
        phase: result.draftState.isDraftComplete
            ? LeagueSyncPhase.idle
            : LeagueSyncPhase.drafting,
        clearLastError: true,
        syncLogs: _appendLog(
          title: 'Wybór #${result.pick.pickNumber}: ${result.pick.riderName}',
          detail: 'Dla $participantId (Runda ${result.pick.roundNumber}).',
        ),
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  void autoPickNext() {
    final league = state.activeLeague;
    final draft = state.draftSession;
    if (league == null || draft == null) {
      _setError('Sesja draftu nie jest aktywna.');
      return;
    }
    try {
      final result = _service.autoPickForCurrentTurn(
        league: league,
        draftState: draft,
      );
      state = state.copyWith(
        activeLeague: result.league,
        draftSession: result.draftState,
        phase: result.draftState.isDraftComplete
            ? LeagueSyncPhase.idle
            : LeagueSyncPhase.drafting,
        clearLastError: true,
        syncLogs: _appendLog(
          title: 'Auto-Pick #${result.pick.pickNumber}',
          detail: '${result.pick.riderId} -> ${result.pick.participantId}',
        ),
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  void submitStageResult({
    required int stageIndex,
    required LeagueStageResultEntry entry,
  }) {
    final league = state.activeLeague;
    if (league == null) {
      _setError('Brak aktywnej ligi do zapisu wyniku.');
      return;
    }
    try {
      final result = _service.submitAndSyncStageResult(
        league: league,
        stageIndex: stageIndex,
        entry: entry,
      );
      state = state.copyWith(
        activeLeague: result.league,
        phase: LeagueSyncPhase.idle,
        clearLastError: true,
        syncLogs: _appendLog(
          title: 'Zsynchronizowano etap #$stageIndex',
          detail: result.stageCompleted
              ? 'Etap kompletny — zaktualizowano ELO (${result.eloUpdatedCount} graczy).'
              : 'Zapisano wynik ${entry.participantId}.',
        ),
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  PpmLeagueFileExportResult? exportPpmLeaguePayload({bool compress = true}) {
    if (state.activeLeague == null && state.ghostChallenges.isEmpty) {
      _setError('Brak danych ligowych ani wyzwań do eksportu.');
      return null;
    }
    try {
      final package = MultiplayerLeaguePackage(
        exportedAt: DateTime.now().toUtc(),
        league: state.activeLeague,
        ghostChallenges: state.ghostChallenges,
        playerEloProfile: state.playerEloProfile,
      );
      final exportResult = _service.encodePackageToPpmLeague(
        package,
        compress: compress,
      );
      state = state.copyWith(
        lastExportResult: exportResult,
        phase: LeagueSyncPhase.idle,
        clearLastError: true,
        syncLogs: _appendLog(
          title: 'Wygenerowano ${exportResult.fileName}',
          detail:
              'Rozmiar ${exportResult.compressedByteSize} B, suma ${exportResult.checksum.substring(0, 8)}...',
        ),
      );
      return exportResult;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  LeagueSyncMergeReport? importPpmLeaguePayload(String rawPayload) {
    try {
      final package = _service.decodePackageFromPpmLeague(rawPayload);
      final report = _service.mergeRemotePackage(
        localLeague: state.activeLeague,
        localChallenges: state.ghostChallenges,
        remotePackage: package,
      );
      state = state.copyWith(
        activeLeague: report.mergedLeague,
        ghostChallenges: report.mergedChallenges,
        lastMergeReport: report,
        phase: LeagueSyncPhase.idle,
        clearLastError: true,
        syncLogs: _appendLog(
          title: 'Zaimportowano paczkę .ppmleague',
          detail:
              '+${report.addedResultsCount} wyników, +${report.addedChallengesCount} wyzwań, konflikty: ${report.conflicts.length}.',
        ),
      );
      return report;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  void addGhostChallenge(GhostChallengeModel challenge) {
    final exists = state.ghostChallenges.any(
      (c) => c.challengeId == challenge.challengeId,
    );
    if (exists) return;
    state = state.copyWith(
      ghostChallenges: [...state.ghostChallenges, challenge],
      syncLogs: _appendLog(
        title: 'Dodano wyzwanie ducha',
        detail: challenge.title,
      ),
    );
  }

  void clearError() {
    state = state.copyWith(
      phase: LeagueSyncPhase.idle,
      clearLastError: true,
    );
  }

  void _setError(String message) {
    state = state.copyWith(
      phase: LeagueSyncPhase.error,
      lastError: message,
      syncLogs: _appendLog(
        title: 'Błąd synchronizacji',
        detail: message,
        isError: true,
      ),
    );
  }

  List<LeagueSyncLogEntry> _appendLog({
    required String title,
    required String detail,
    bool isError = false,
  }) {
    final entry = LeagueSyncLogEntry(
      timestamp: DateTime.now().toUtc(),
      title: title,
      detail: detail,
      isError: isError,
    );
    return [entry, ...state.syncLogs].take(20).toList(growable: false);
  }
}

/// Provider serwisu synchronizacji ligi asynchronicznej.
final asyncMultiplayerLeagueSyncServiceProvider =
    Provider<AsyncMultiplayerLeagueSyncService>((ref) {
  return const AsyncMultiplayerLeagueSyncService();
});

/// Provider stanu synchronizacji ligi i paczek `.ppmleague`.
final asyncMultiplayerLeagueSyncProvider = StateNotifierProvider<
    AsyncMultiplayerLeagueSyncNotifier, AsyncMultiplayerLeagueSyncState>((ref) {
  return AsyncMultiplayerLeagueSyncNotifier(
    service: ref.watch(asyncMultiplayerLeagueSyncServiceProvider),
  );
});

/// Panel UI synchronizacji wyników ligowych, draftu kolarzy oraz wymiany plików `.ppmleague`.
class AsyncMultiplayerLeagueSyncPanel extends ConsumerWidget {
  final VoidCallback? onExportPressed;
  final VoidCallback? onImportPressed;
  final VoidCallback? onAutoPickPressed;

  const AsyncMultiplayerLeagueSyncPanel({
    super.key,
    this.onExportPressed,
    this.onImportPressed,
    this.onAutoPickPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(asyncMultiplayerLeagueSyncProvider);
    final notifier = ref.read(asyncMultiplayerLeagueSyncProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final isWide = constraints.maxWidth >= 1180;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(syncState, isCompact),
              if (syncState.lastError != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(syncState.lastError!, notifier.clearError),
              ],
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildDraftAndStandingsColumn(
                        syncState,
                        notifier,
                        isCompact,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _buildExchangeAndLogsColumn(
                        syncState,
                        notifier,
                      ),
                    ),
                  ],
                )
              else ...[
                _buildDraftAndStandingsColumn(
                  syncState,
                  notifier,
                  isCompact,
                ),
                const SizedBox(height: 16),
                _buildExchangeAndLogsColumn(syncState, notifier),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    AsyncMultiplayerLeagueSyncState syncState,
    bool isCompact,
  ) {
    final league = syncState.activeLeague;
    final phaseColor = syncState.phase == LeagueSyncPhase.error
        ? AppColors.crimsonAlert
        : syncState.phase == LeagueSyncPhase.drafting
            ? AppColors.goldAccent
            : AppColors.statusSuccess;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                league?.name ?? 'Asynchroniczna Liga Online',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                league != null
                    ? '${league.format.label} • ${league.participants.length}/${league.maxParticipants} graczy • Etapy ${league.completedStageCount}/${league.schedule.length}'
                    : 'Brak załadowanej ligi — zaimportuj plik .ppmleague',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: phaseColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              syncState.phase.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: phaseColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message, VoidCallback onDismiss) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.crimsonAlert),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.crimsonAlert,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _SyncActionButton(
            label: 'Zamknij',
            onPressed: onDismiss,
            accentColor: AppColors.crimsonAlert,
          ),
        ],
      ),
    );
  }

  Widget _buildDraftAndStandingsColumn(
    AsyncMultiplayerLeagueSyncState syncState,
    AsyncMultiplayerLeagueSyncNotifier notifier,
    bool isCompact,
  ) {
    final league = syncState.activeLeague;
    final draft = syncState.draftSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (draft != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Draft Kolarzy',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Runda ${draft.currentRound} • ${draft.picks.length}/${draft.totalRequiredPicks}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  draft.isDraftComplete
                      ? 'Draft zakończony — składy są gotowe.'
                      : 'Tura wyboru: ${draft.currentParticipantId ?? "-"}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _SyncActionButton(
                  label: 'Auto-Pick dla bieżącej tury',
                  icon: Icons.bolt_rounded,
                  accentColor: AppColors.goldAccent,
                  enabled: !draft.isDraftComplete,
                  onPressed: onAutoPickPressed ?? notifier.autoPickNext,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Klasyfikacja Ligi i ELO',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (league == null || league.participants.isEmpty)
                const Text(
                  'Brak uczestników w lidze.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...league.sortedStandings.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final p = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 10 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: rank == 1
                                  ? AppColors.goldAccent
                                  : AppColors.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                p.teamName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${p.totalPoints} pkt • ${p.currentElo} ELO',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentBlue,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeAndLogsColumn(
    AsyncMultiplayerLeagueSyncState syncState,
    AsyncMultiplayerLeagueSyncNotifier notifier,
  ) {
    final exportInfo = syncState.lastExportResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wymiana Plików .ppmleague',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Wyzwania duchów: ${syncState.ghostChallenges.length} • Tryb: ${syncState.transportMode.label}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SyncActionButton(
                    label: 'Eksportuj .ppmleague',
                    icon: Icons.upload_file_rounded,
                    accentColor: AppColors.primaryAccent,
                    enabled: syncState.activeLeague != null ||
                        syncState.ghostChallenges.isNotEmpty,
                    onPressed: onExportPressed ??
                        () => notifier.exportPpmLeaguePayload(),
                  ),
                  _SyncActionButton(
                    label: 'Importuj .ppmleague',
                    icon: Icons.download_rounded,
                    accentColor: AppColors.accentBlue,
                    enabled: onImportPressed != null || exportInfo != null,
                    onPressed: onImportPressed ??
                        () {
                          if (exportInfo != null) {
                            notifier.importPpmLeaguePayload(
                              exportInfo.encodedPayload,
                            );
                          }
                        },
                  ),
                ],
              ),
              if (exportInfo != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    'Ostatni eksport: ${exportInfo.fileName} (${exportInfo.compressedByteSize} B, FNV-1a64: ${exportInfo.checksum.substring(0, 8)}...)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dziennik Synchronizacji',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (syncState.syncLogs.isEmpty)
                const Text(
                  'Brak zdarzeń synchronizacji.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...syncState.syncLogs.take(6).map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              log.isError
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 16,
                              color: log.isError
                                  ? AppColors.crimsonAlert
                                  : AppColors.statusSuccess,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.title,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    log.detail,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _SyncActionButton({
    required this.label,
    this.icon,
    required this.accentColor,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  State<_SyncActionButton> createState() => _SyncActionButtonState();
}

class _SyncActionButtonState extends State<_SyncActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled;
    final bgColor = !isEnabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.32)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.24)
                : widget.accentColor.withValues(alpha: 0.16);

    final borderColor = !isEnabled
        ? AppColors.cardBorder
        : _focused
            ? AppColors.goldAccent
            : widget.accentColor.withValues(alpha: _hovered ? 0.9 : 0.6);

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: isEnabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fnv1a64Hex(String input) {
  const int fnvOffsetBasis = 0xcbf29ce484222325;
  const int fnvPrime = 0x100000001b3;
  const int mask64 = 0xFFFFFFFFFFFFFFFF;

  var hash = fnvOffsetBasis;
  final bytes = utf8.encode(input);
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * fnvPrime) & mask64;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
