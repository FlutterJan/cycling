// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/race/stage_segment.dart';

/// Kategoria wirtualnego segmentu KOM / sektora brukowego w tabeli wszech czasów.
enum KomSegmentCategory {
  alpineHcClimb('Alpy / HC', 'Alpine / HC', Icons.landscape_rounded),
  puncheurWall('Ścianki / Klasyki', 'Puncheur Walls', Icons.trending_up_rounded),
  cobbleSector('Sektory Bruku', 'Cobble Sectors', Icons.grid_view_rounded),
  gravelSector('Szutry', 'Gravel Sectors', Icons.terrain_rounded);

  final String polishLabel;
  final String englishLabel;
  final IconData icon;

  const KomSegmentCategory(this.polishLabel, this.englishLabel, this.icon);

  String toJson() => name;

  static KomSegmentCategory fromJson(String value) {
    return KomSegmentCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => KomSegmentCategory.alpineHcClimb,
    );
  }
}

/// Definicja wirtualnego segmentu KOM (podjazd lub sektor bruku/szutru).
class KomSegmentDefinition {
  final String segmentId;
  final String name;
  final String regionOrCountry;
  final String iconicRaceName;
  final KomSegmentCategory category;
  final double lengthKm;
  final double elevationGainM;
  final double averageGradientPercent;
  final double maxGradientPercent;
  final SegmentSurfaceType surfaceType;
  final SegmentClassification classification;
  final int cobbleDifficultyStars;

  const KomSegmentDefinition({
    required this.segmentId,
    required this.name,
    required this.regionOrCountry,
    required this.iconicRaceName,
    required this.category,
    required this.lengthKm,
    required this.elevationGainM,
    required this.averageGradientPercent,
    required this.maxGradientPercent,
    required this.surfaceType,
    required this.classification,
    this.cobbleDifficultyStars = 0,
  });

  bool get isCobble =>
      category == KomSegmentCategory.cobbleSector ||
      surfaceType == SegmentSurfaceType.cobblestonesSector1 ||
      surfaceType == SegmentSurfaceType.cobblestonesSector2 ||
      surfaceType == SegmentSurfaceType.cobblestonesSector3 ||
      surfaceType == SegmentSurfaceType.cobblestonesSector4 ||
      surfaceType == SegmentSurfaceType.cobblestonesSector5;

  Map<String, dynamic> toJson() => {
        'segmentId': segmentId,
        'name': name,
        'regionOrCountry': regionOrCountry,
        'iconicRaceName': iconicRaceName,
        'category': category.toJson(),
        'lengthKm': lengthKm,
        'elevationGainM': elevationGainM,
        'averageGradientPercent': averageGradientPercent,
        'maxGradientPercent': maxGradientPercent,
        'surfaceType': surfaceType.toJson(),
        'classification': classification.toJson(),
        'cobbleDifficultyStars': cobbleDifficultyStars,
      };

  factory KomSegmentDefinition.fromJson(Map<String, dynamic> json) {
    return KomSegmentDefinition(
      segmentId: json['segmentId'] as String,
      name: json['name'] as String,
      regionOrCountry: json['regionOrCountry'] as String? ?? 'EUR',
      iconicRaceName: json['iconicRaceName'] as String? ?? 'WorldTour',
      category: KomSegmentCategory.fromJson(
        json['category'] as String? ?? 'alpineHcClimb',
      ),
      lengthKm: (json['lengthKm'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toDouble(),
      averageGradientPercent:
          (json['averageGradientPercent'] as num).toDouble(),
      maxGradientPercent: (json['maxGradientPercent'] as num).toDouble(),
      surfaceType: SegmentSurfaceType.fromJson(
        json['surfaceType'] as String? ?? 'smoothAsphalt',
      ),
      classification: SegmentClassification.fromJson(
        json['classification'] as String? ?? 'cat1',
      ),
      cobbleDifficultyStars:
          (json['cobbleDifficultyStars'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KomSegmentDefinition && other.segmentId == segmentId;
  }

  @override
  int get hashCode => segmentId.hashCode;
}

/// Pojedynczy zmierzony przejazd kolarza przez wirtualny segment KOM.
class KomSegmentEffort {
  final String effortId;
  final String segmentId;
  final String riderId;
  final String riderName;
  final String riderNationality;
  final String teamId;
  final String teamName;
  final bool isPlayerTeam;
  final int seasonYear;
  final String raceName;
  final int? stageNumber;
  final DateTime recordedAt;

  /// Czas przejazdu mierzony automatycznie co do sekundy.
  final int elapsedSeconds;

  /// Dokładny czas w sekundach do rozstrzygania remisów (np. 2314.42 s).
  final double exactSeconds;
  final double averageSpeedKmh;
  final double averagePowerWatts;
  final double averageWattsPerKg;
  final double vamMetersPerHour;
  final bool isHistoricBenchmark;

  const KomSegmentEffort({
    required this.effortId,
    required this.segmentId,
    required this.riderId,
    required this.riderName,
    required this.riderNationality,
    required this.teamId,
    required this.teamName,
    required this.isPlayerTeam,
    required this.seasonYear,
    required this.raceName,
    this.stageNumber,
    required this.recordedAt,
    required this.elapsedSeconds,
    required this.exactSeconds,
    required this.averageSpeedKmh,
    required this.averagePowerWatts,
    required this.averageWattsPerKg,
    required this.vamMetersPerHour,
    this.isHistoricBenchmark = false,
  });

  String get formattedTime => KomTimeFormatter.formatSeconds(elapsedSeconds);

  Map<String, dynamic> toJson() => {
        'effortId': effortId,
        'segmentId': segmentId,
        'riderId': riderId,
        'riderName': riderName,
        'riderNationality': riderNationality,
        'teamId': teamId,
        'teamName': teamName,
        'isPlayerTeam': isPlayerTeam,
        'seasonYear': seasonYear,
        'raceName': raceName,
        'stageNumber': stageNumber,
        'recordedAt': recordedAt.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        'exactSeconds': exactSeconds,
        'averageSpeedKmh': averageSpeedKmh,
        'averagePowerWatts': averagePowerWatts,
        'averageWattsPerKg': averageWattsPerKg,
        'vamMetersPerHour': vamMetersPerHour,
        'isHistoricBenchmark': isHistoricBenchmark,
      };

  factory KomSegmentEffort.fromJson(Map<String, dynamic> json) {
    return KomSegmentEffort(
      effortId: json['effortId'] as String,
      segmentId: json['segmentId'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      riderNationality: json['riderNationality'] as String? ?? 'INT',
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      seasonYear: (json['seasonYear'] as num).toInt(),
      raceName: json['raceName'] as String,
      stageNumber: (json['stageNumber'] as num?)?.toInt(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      elapsedSeconds: (json['elapsedSeconds'] as num).toInt(),
      exactSeconds: (json['exactSeconds'] as num).toDouble(),
      averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
      averagePowerWatts: (json['averagePowerWatts'] as num).toDouble(),
      averageWattsPerKg: (json['averageWattsPerKg'] as num).toDouble(),
      vamMetersPerHour: (json['vamMetersPerHour'] as num).toDouble(),
      isHistoricBenchmark: json['isHistoricBenchmark'] as bool? ?? false,
    );
  }
}

/// Wiersz rankingu wszech czasów z wyliczonym miejscem, stratą i oznaczeniem Korony KOM.
class KomLeaderboardEntry {
  final int rank;
  final KomSegmentEffort effort;
  final int deltaSecondsToKom;
  final bool isCurrentKomCrownHolder;
  final bool isRiderPersonalBest;

  const KomLeaderboardEntry({
    required this.rank,
    required this.effort,
    required this.deltaSecondsToKom,
    required this.isCurrentKomCrownHolder,
    required this.isRiderPersonalBest,
  });

  String get formattedDelta => deltaSecondsToKom <= 0
      ? 'KOM'
      : '+${KomTimeFormatter.formatDelta(deltaSecondsToKom)}';
}

/// Zdarzenie pobicia rekordu wszech czasów i przejęcia Korony KOM.
class KomRecordBrokenEvent {
  final String segmentId;
  final String segmentName;
  final KomSegmentEffort newKomEffort;
  final KomSegmentEffort? previousKomEffort;
  final int secondsImproved;
  final DateTime brokenAt;

  const KomRecordBrokenEvent({
    required this.segmentId,
    required this.segmentName,
    required this.newKomEffort,
    this.previousKomEffort,
    required this.secondsImproved,
    required this.brokenAt,
  });

  Map<String, dynamic> toJson() => {
        'segmentId': segmentId,
        'segmentName': segmentName,
        'newKomEffort': newKomEffort.toJson(),
        'previousKomEffort': previousKomEffort?.toJson(),
        'secondsImproved': secondsImproved,
        'brokenAt': brokenAt.toIso8601String(),
      };

  factory KomRecordBrokenEvent.fromJson(Map<String, dynamic> json) {
    return KomRecordBrokenEvent(
      segmentId: json['segmentId'] as String,
      segmentName: json['segmentName'] as String,
      newKomEffort: KomSegmentEffort.fromJson(
        Map<String, dynamic>.from(json['newKomEffort'] as Map),
      ),
      previousKomEffort: json['previousKomEffort'] != null
          ? KomSegmentEffort.fromJson(
              Map<String, dynamic>.from(json['previousKomEffort'] as Map),
            )
          : null,
      secondsImproved: (json['secondsImproved'] as num).toInt(),
      brokenAt: DateTime.parse(json['brokenAt'] as String),
    );
  }
}

/// Surowe dane wejściowe automatycznego pomiaru przejazdu przez podjazd lub sektor bruku.
class KomPassageInput {
  final String segmentId;
  final String riderId;
  final String riderName;
  final String riderNationality;
  final String teamId;
  final String teamName;
  final bool isPlayerTeam;
  final int seasonYear;
  final String raceName;
  final int? stageNumber;
  final DateTime recordedAt;

  /// Czas przejazdu w sekundach (może pochodzić z zegara symulacji co do 1 s lub precyzyjniej).
  final double rawDurationSeconds;
  final double averagePowerWatts;
  final double riderWeightKg;

  const KomPassageInput({
    required this.segmentId,
    required this.riderId,
    required this.riderName,
    this.riderNationality = 'INT',
    required this.teamId,
    required this.teamName,
    this.isPlayerTeam = false,
    required this.seasonYear,
    required this.raceName,
    this.stageNumber,
    required this.recordedAt,
    required this.rawDurationSeconds,
    required this.averagePowerWatts,
    required this.riderWeightKg,
  });
}

/// Wynik rejestracji jednego lub wielu przejazdów przez segment.
class KomPassageRecordResult {
  final KomSegmentEffort effort;
  final int assignedRank;
  final bool isNewKomCrown;
  final bool isPersonalBest;
  final KomRecordBrokenEvent? brokenEvent;

  const KomPassageRecordResult({
    required this.effort,
    required this.assignedRank,
    required this.isNewKomCrown,
    required this.isPersonalBest,
    this.brokenEvent,
  });
}

/// Formater czasów segmentów KOM z zachowaniem czytelności co do sekundy.
class KomTimeFormatter {
  KomTimeFormatter._();

  static String formatSeconds(int totalSeconds) {
    final safe = math.max(0, totalSeconds);
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDelta(int deltaSeconds) {
    final safe = math.max(0, deltaSeconds);
    if (safe < 60) {
      return '${safe}s';
    }
    final minutes = safe ~/ 60;
    final seconds = safe % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Główny silnik i baza wszech czasów wirtualnych segmentów KOM oraz sektorów bruku.
class WorldRecordsAndStravaKomSegments {
  final Map<String, KomSegmentDefinition> _segments = {};
  final Map<String, List<KomSegmentEffort>> _effortsBySegment = {};
  final List<KomRecordBrokenEvent> _recentBrokenEvents = [];
  int _effortSequence = 0;

  WorldRecordsAndStravaKomSegments({bool seedIconicSegments = true}) {
    if (seedIconicSegments) {
      _seedIconicWorldSegments();
    }
  }

  List<KomSegmentDefinition> get allSegments {
    final list = _segments.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(list);
  }

  List<KomRecordBrokenEvent> get recentBrokenEvents =>
      List.unmodifiable(_recentBrokenEvents);

  int get totalSegmentsCount => _segments.length;

  int get totalEffortsCount =>
      _effortsBySegment.values.fold(0, (sum, list) => sum + list.length);

  KomSegmentDefinition? getSegment(String segmentId) => _segments[segmentId];

  /// Rejestruje nowy segment lub aktualizuje definicję istniejącego.
  void registerSegment(KomSegmentDefinition definition) {
    _segments[definition.segmentId] = definition;
    _effortsBySegment.putIfAbsent(definition.segmentId, () => []);
  }

  /// Automatycznie wykrywa i rejestruje segmenty KOM z listy odcinków etapu (`StageSegment`).
  List<KomSegmentDefinition> registerFromStageSegments({
    required String raceId,
    required String raceName,
    required String countryCode,
    required List<StageSegment> segments,
  }) {
    final registered = <KomSegmentDefinition>[];
    for (final seg in segments) {
      final isEligible = seg.isClimb ||
          seg.isKom ||
          seg.isCobblestone ||
          seg.surfaceType == SegmentSurfaceType.gravelStrade;
      if (!isEligible || seg.lengthKm <= 0.0) continue;

      final category = _resolveCategory(seg);
      final segmentId =
          '${raceId}_seg_${seg.index}_${seg.startKm.toStringAsFixed(1)}';
      final labelPrefix = seg.isCobblestone
          ? 'Sektor Bruku'
          : seg.surfaceType == SegmentSurfaceType.gravelStrade
              ? 'Sektor Szutrowy'
              : 'Podjazd';
      final def = KomSegmentDefinition(
        segmentId: segmentId,
        name: '$raceName — $labelPrefix #${seg.index + 1}',
        regionOrCountry: countryCode,
        iconicRaceName: raceName,
        category: category,
        lengthKm: double.parse(seg.lengthKm.toStringAsFixed(2)),
        elevationGainM: double.parse(seg.elevationGainM.toStringAsFixed(1)),
        averageGradientPercent:
            double.parse(seg.gradientPercent.toStringAsFixed(1)),
        maxGradientPercent: double.parse(
          (seg.gradientPercent * 1.35).clamp(0.0, 28.0).toStringAsFixed(1),
        ),
        surfaceType: seg.surfaceType,
        classification: seg.sprintOrKomClassification,
        cobbleDifficultyStars: _cobbleStars(seg.surfaceType),
      );
      registerSegment(def);
      registered.add(def);
    }
    return registered;
  }

  /// Rejestruje przejazd przez podjazd lub sektor bruku, mierząc czas co do sekundy
  /// i aktualizując globalną tabelę wszech czasów oraz Koronę KOM.
  KomPassageRecordResult recordPassage(KomPassageInput input) {
    final segment = _segments[input.segmentId];
    if (segment == null) {
      throw ArgumentError.value(
        input.segmentId,
        'segmentId',
        'Nieznany segment KOM: ${input.segmentId}',
      );
    }

    final safeExactSeconds =
        math.max(1.0, input.rawDurationSeconds.isFinite ? input.rawDurationSeconds : 1.0);
    final elapsedSeconds = math.max(1, safeExactSeconds.round());
    final safeWeight = math.max(40.0, input.riderWeightKg);
    final safePower = math.max(0.0, input.averagePowerWatts);

    final hours = safeExactSeconds / 3600.0;
    final avgSpeedKmh = hours > 0 ? (segment.lengthKm / hours) : 0.0;
    final vamMetersPerHour =
        (hours > 0 && segment.elevationGainM > 0) ? (segment.elevationGainM / hours) : 0.0;
    final wattsPerKg = safePower / safeWeight;

    final list = _effortsBySegment.putIfAbsent(input.segmentId, () => []);
    final previousKom = list.isNotEmpty ? _sortedEfforts(list).first : null;

    _effortSequence++;
    final effort = KomSegmentEffort(
      effortId: 'kom_eff_${input.segmentId}_$_effortSequence',
      segmentId: input.segmentId,
      riderId: input.riderId,
      riderName: input.riderName,
      riderNationality: input.riderNationality,
      teamId: input.teamId,
      teamName: input.teamName,
      isPlayerTeam: input.isPlayerTeam,
      seasonYear: input.seasonYear,
      raceName: input.raceName,
      stageNumber: input.stageNumber,
      recordedAt: input.recordedAt,
      elapsedSeconds: elapsedSeconds,
      exactSeconds: double.parse(safeExactSeconds.toStringAsFixed(2)),
      averageSpeedKmh: double.parse(avgSpeedKmh.toStringAsFixed(2)),
      averagePowerWatts: double.parse(safePower.toStringAsFixed(1)),
      averageWattsPerKg: double.parse(wattsPerKg.toStringAsFixed(2)),
      vamMetersPerHour: double.parse(vamMetersPerHour.toStringAsFixed(0)),
    );

    final previousRiderBest = list
        .where((e) => e.riderId == input.riderId)
        .fold<KomSegmentEffort?>(
          null,
          (best, e) => best == null || _compareEfforts(e, best) < 0 ? e : best,
        );

    list.add(effort);
    final sorted = _sortedEfforts(list);
    _effortsBySegment[input.segmentId] = sorted;

    final rank = sorted.indexWhere((e) => e.effortId == effort.effortId) + 1;
    final isNewKom = rank == 1 &&
        (previousKom == null || _compareEfforts(effort, previousKom) < 0);
    final isPersonalBest = previousRiderBest == null ||
        _compareEfforts(effort, previousRiderBest) < 0;

    KomRecordBrokenEvent? brokenEvent;
    if (isNewKom) {
      final improved = previousKom != null
          ? math.max(0, previousKom.elapsedSeconds - effort.elapsedSeconds)
          : 0;
      brokenEvent = KomRecordBrokenEvent(
        segmentId: segment.segmentId,
        segmentName: segment.name,
        newKomEffort: effort,
        previousKomEffort: previousKom,
        secondsImproved: improved,
        brokenAt: input.recordedAt,
      );
      _recentBrokenEvents.insert(0, brokenEvent);
      if (_recentBrokenEvents.length > 50) {
        _recentBrokenEvents.removeLast();
      }
    }

    return KomPassageRecordResult(
      effort: effort,
      assignedRank: rank,
      isNewKomCrown: isNewKom,
      isPersonalBest: isPersonalBest,
      brokenEvent: brokenEvent,
    );
  }

  /// Masowo rejestruje przejazdy grupy kolarzy po zakończeniu etapu lub segmentu.
  List<KomPassageRecordResult> recordBatchPassages(
    List<KomPassageInput> inputs,
  ) {
    final results = <KomPassageRecordResult>[];
    for (final input in inputs) {
      if (_segments.containsKey(input.segmentId)) {
        results.add(recordPassage(input));
      }
    }
    return results;
  }

  /// Zwraca pełną tabelę wszech czasów dla segmentu z oznaczeniem Korony KOM dla lidera.
  List<KomLeaderboardEntry> getLeaderboard(
    String segmentId, {
    int? limit,
    bool onlyPlayerTeam = false,
  }) {
    final rawList = _effortsBySegment[segmentId];
    if (rawList == null || rawList.isEmpty) return const [];

    final sorted = _sortedEfforts(rawList);
    final komSeconds = sorted.first.elapsedSeconds;
    final seenRiderIds = <String>{};
    final entries = <KomLeaderboardEntry>[];

    for (var i = 0; i < sorted.length; i++) {
      final effort = sorted[i];
      final isPb = seenRiderIds.add(effort.riderId);
      if (onlyPlayerTeam && !effort.isPlayerTeam) {
        continue;
      }
      entries.add(
        KomLeaderboardEntry(
          rank: i + 1,
          effort: effort,
          deltaSecondsToKom: math.max(0, effort.elapsedSeconds - komSeconds),
          isCurrentKomCrownHolder: i == 0,
          isRiderPersonalBest: isPb,
        ),
      );
      if (limit != null && entries.length >= limit) {
        break;
      }
    }
    return List.unmodifiable(entries);
  }

  /// Zwraca aktualnego rekordzistę (posiadacza Korony KOM) danego segmentu.
  KomSegmentEffort? getCurrentKomCrownHolder(String segmentId) {
    final list = _effortsBySegment[segmentId];
    if (list == null || list.isEmpty) return null;
    return _sortedEfforts(list).first;
  }

  /// Zwraca liczbę Koron KOM aktualnie posiadanych przez drużynę gracza.
  int countPlayerTeamKomCrowns() {
    var count = 0;
    for (final segmentId in _segments.keys) {
      final holder = getCurrentKomCrownHolder(segmentId);
      if (holder != null && holder.isPlayerTeam) {
        count++;
      }
    }
    return count;
  }

  /// Zwraca wszystkie Korony KOM zdobyte przez konkretnego kolarza.
  List<KomSegmentDefinition> getSegmentsWithKomCrownForRider(String riderId) {
    final crowned = <KomSegmentDefinition>[];
    for (final entry in _segments.entries) {
      final holder = getCurrentKomCrownHolder(entry.key);
      if (holder != null && holder.riderId == riderId) {
        crowned.add(entry.value);
      }
    }
    crowned.sort((a, b) => a.name.compareTo(b.name));
    return crowned;
  }

  Map<String, dynamic> toJson() => {
        'effortSequence': _effortSequence,
        'segments': _segments.values.map((s) => s.toJson()).toList(),
        'effortsBySegment': _effortsBySegment.map(
          (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
        ),
        'recentBrokenEvents':
            _recentBrokenEvents.map((e) => e.toJson()).toList(),
      };

  factory WorldRecordsAndStravaKomSegments.fromJson(Map<String, dynamic> json) {
    final instance = WorldRecordsAndStravaKomSegments(seedIconicSegments: false);
    instance._effortSequence = (json['effortSequence'] as num?)?.toInt() ?? 0;

    final rawSegments = json['segments'] as List<dynamic>? ?? const [];
    for (final item in rawSegments) {
      final def = KomSegmentDefinition.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      instance.registerSegment(def);
    }

    final rawEfforts =
        json['effortsBySegment'] as Map<String, dynamic>? ?? const {};
    for (final entry in rawEfforts.entries) {
      final list = (entry.value as List<dynamic>)
          .map(
            (e) => KomSegmentEffort.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      instance._effortsBySegment[entry.key] = instance._sortedEfforts(list);
    }

    final rawEvents =
        json['recentBrokenEvents'] as List<dynamic>? ?? const [];
    for (final item in rawEvents) {
      instance._recentBrokenEvents.add(
        KomRecordBrokenEvent.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      );
    }

    return instance;
  }

  List<KomSegmentEffort> _sortedEfforts(List<KomSegmentEffort> efforts) {
    final copy = List<KomSegmentEffort>.from(efforts);
    copy.sort(_compareEfforts);
    return copy;
  }

  int _compareEfforts(KomSegmentEffort a, KomSegmentEffort b) {
    final bySec = a.elapsedSeconds.compareTo(b.elapsedSeconds);
    if (bySec != 0) return bySec;
    final byExact = a.exactSeconds.compareTo(b.exactSeconds);
    if (byExact != 0) return byExact;
    return a.recordedAt.compareTo(b.recordedAt);
  }

  KomSegmentCategory _resolveCategory(StageSegment seg) {
    if (seg.isCobblestone) return KomSegmentCategory.cobbleSector;
    if (seg.surfaceType == SegmentSurfaceType.gravelStrade) {
      return KomSegmentCategory.gravelSector;
    }
    if (seg.lengthKm >= 5.0 ||
        seg.sprintOrKomClassification == SegmentClassification.horsCategorie ||
        seg.sprintOrKomClassification == SegmentClassification.cat1) {
      return KomSegmentCategory.alpineHcClimb;
    }
    return KomSegmentCategory.puncheurWall;
  }

  int _cobbleStars(SegmentSurfaceType surface) {
    switch (surface) {
      case SegmentSurfaceType.cobblestonesSector1:
        return 1;
      case SegmentSurfaceType.cobblestonesSector2:
        return 2;
      case SegmentSurfaceType.cobblestonesSector3:
        return 3;
      case SegmentSurfaceType.cobblestonesSector4:
        return 4;
      case SegmentSurfaceType.cobblestonesSector5:
        return 5;
      default:
        return 0;
    }
  }

  void _seedIconicWorldSegments() {
    const iconicSpecs = <_IconicSeedSpec>[
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'poggio_di_sanremo',
          name: 'Poggio di Sanremo',
          regionOrCountry: 'ITA',
          iconicRaceName: 'Milano-Sanremo',
          category: KomSegmentCategory.puncheurWall,
          lengthKm: 3.7,
          elevationGainM: 136.0,
          averageGradientPercent: 3.7,
          maxGradientPercent: 8.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.cat4,
        ),
        komRiderId: 'hist_mvdp_sanremo',
        komRiderName: 'Mathieu van der Poel',
        komNat: 'NED',
        komTeam: 'Alpecin-Deceuninck',
        komSeconds: 328, // 5:28
        komWatts: 465.0,
        komWeight: 75.0,
        komYear: 2023,
        runnerUpName: 'Filippo Ganna',
        runnerUpNat: 'ITA',
        runnerUpTeam: 'INEOS Grenadiers',
        runnerUpSeconds: 331,
        runnerUpWatts: 495.0,
        runnerUpWeight: 82.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'mur_de_huy',
          name: 'Mur de Huy',
          regionOrCountry: 'BEL',
          iconicRaceName: 'La Flèche Wallonne',
          category: KomSegmentCategory.puncheurWall,
          lengthKm: 1.3,
          elevationGainM: 128.0,
          averageGradientPercent: 9.8,
          maxGradientPercent: 19.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.cat2,
        ),
        komRiderId: 'hist_pogacar_huy',
        komRiderName: 'Tadej Pogačar',
        komNat: 'SLO',
        komTeam: 'UAE Team Emirates',
        komSeconds: 162, // 2:42
        komWatts: 482.0,
        komWeight: 66.0,
        komYear: 2023,
        runnerUpName: 'Julian Alaphilippe',
        runnerUpNat: 'FRA',
        runnerUpTeam: 'Soudal Quick-Step',
        runnerUpSeconds: 165,
        runnerUpWatts: 458.0,
        runnerUpWeight: 62.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'alpe_d_huez',
          name: "Alpe d'Huez (21 Virages)",
          regionOrCountry: 'FRA',
          iconicRaceName: 'Tour de France',
          category: KomSegmentCategory.alpineHcClimb,
          lengthKm: 13.8,
          elevationGainM: 1120.0,
          averageGradientPercent: 8.1,
          maxGradientPercent: 11.5,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.horsCategorie,
        ),
        komRiderId: 'hist_pantani_alpe',
        komRiderName: 'Marco Pantani',
        komNat: 'ITA',
        komTeam: 'Mercatone Uno',
        komSeconds: 2255, // 37:35
        komWatts: 412.0,
        komWeight: 57.0,
        komYear: 1997,
        runnerUpName: 'Sepp Kuss',
        runnerUpNat: 'USA',
        runnerUpTeam: 'Visma | Lease a Bike',
        runnerUpSeconds: 2348,
        runnerUpWatts: 405.0,
        runnerUpWeight: 61.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'col_du_tourmalet',
          name: 'Col du Tourmalet (Luz-Saint-Sauveur)',
          regionOrCountry: 'FRA',
          iconicRaceName: 'Tour de France',
          category: KomSegmentCategory.alpineHcClimb,
          lengthKm: 19.0,
          elevationGainM: 1404.0,
          averageGradientPercent: 7.4,
          maxGradientPercent: 10.2,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.horsCategorie,
        ),
        komRiderId: 'hist_vingegaard_tourmalet',
        komRiderName: 'Jonas Vingegaard',
        komNat: 'DEN',
        komTeam: 'Visma | Lease a Bike',
        komSeconds: 2812, // 46:52
        komWatts: 398.0,
        komWeight: 60.0,
        komYear: 2023,
        runnerUpName: 'Tadej Pogačar',
        runnerUpNat: 'SLO',
        runnerUpTeam: 'UAE Team Emirates',
        runnerUpSeconds: 2826,
        runnerUpWatts: 425.0,
        runnerUpWeight: 66.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'mont_ventoux',
          name: 'Mont Ventoux (Bédoin)',
          regionOrCountry: 'FRA',
          iconicRaceName: 'Tour de France',
          category: KomSegmentCategory.alpineHcClimb,
          lengthKm: 21.5,
          elevationGainM: 1617.0,
          averageGradientPercent: 7.5,
          maxGradientPercent: 12.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.horsCategorie,
        ),
        komRiderId: 'hist_mayo_ventoux',
        komRiderName: 'Iban Mayo',
        komNat: 'ESP',
        komTeam: 'Euskaltel-Euskadi',
        komSeconds: 3351, // 55:51
        komWatts: 392.0,
        komWeight: 60.0,
        komYear: 2004,
        runnerUpName: 'Chris Froome',
        runnerUpNat: 'GBR',
        runnerUpTeam: 'Team Sky',
        runnerUpSeconds: 3425,
        runnerUpWatts: 416.0,
        runnerUpWeight: 67.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'passo_dello_stelvio',
          name: 'Passo dello Stelvio (Prato)',
          regionOrCountry: 'ITA',
          iconicRaceName: "Giro d'Italia",
          category: KomSegmentCategory.alpineHcClimb,
          lengthKm: 24.3,
          elevationGainM: 1808.0,
          averageGradientPercent: 7.4,
          maxGradientPercent: 12.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          classification: SegmentClassification.horsCategorie,
        ),
        komRiderId: 'hist_hindley_stelvio',
        komRiderName: 'Jai Hindley',
        komNat: 'AUS',
        komTeam: 'Team Sunweb',
        komSeconds: 4215, // 1:10:15
        komWatts: 368.0,
        komWeight: 60.0,
        komYear: 2020,
        runnerUpName: 'Tao Geoghegan Hart',
        runnerUpNat: 'GBR',
        runnerUpTeam: 'INEOS Grenadiers',
        runnerUpSeconds: 4216,
        runnerUpWatts: 382.0,
        runnerUpWeight: 63.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'alto_de_l_angliru',
          name: "Alto de l'Angliru",
          regionOrCountry: 'ESP',
          iconicRaceName: 'La Vuelta a España',
          category: KomSegmentCategory.alpineHcClimb,
          lengthKm: 12.4,
          elevationGainM: 1266.0,
          averageGradientPercent: 10.2,
          maxGradientPercent: 23.5,
          surfaceType: SegmentSurfaceType.roughAsphalt,
          classification: SegmentClassification.horsCategorie,
        ),
        komRiderId: 'hist_heras_angliru',
        komRiderName: 'Roberto Heras',
        komNat: 'ESP',
        komTeam: 'US Postal',
        komSeconds: 2515, // 41:55
        komWatts: 386.0,
        komWeight: 59.0,
        komYear: 2000,
        runnerUpName: 'Primož Roglič',
        runnerUpNat: 'SLO',
        runnerUpTeam: 'Jumbo-Visma',
        runnerUpSeconds: 2544,
        runnerUpWatts: 408.0,
        runnerUpWeight: 65.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'trouee_d_arenberg',
          name: "Trouée d'Arenberg",
          regionOrCountry: 'FRA',
          iconicRaceName: 'Paris-Roubaix',
          category: KomSegmentCategory.cobbleSector,
          lengthKm: 2.3,
          elevationGainM: 4.0,
          averageGradientPercent: 0.2,
          maxGradientPercent: 1.5,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          classification: SegmentClassification.none,
          cobbleDifficultyStars: 5,
        ),
        komRiderId: 'hist_wva_arenberg',
        komRiderName: 'Wout van Aert',
        komNat: 'BEL',
        komTeam: 'Visma | Lease a Bike',
        komSeconds: 184, // 3:04
        komWatts: 540.0,
        komWeight: 78.0,
        komYear: 2023,
        runnerUpName: 'Mathieu van der Poel',
        runnerUpNat: 'NED',
        runnerUpTeam: 'Alpecin-Deceuninck',
        runnerUpSeconds: 185,
        runnerUpWatts: 528.0,
        runnerUpWeight: 75.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'carrefour_de_l_arbre',
          name: "Carrefour de l'Arbre",
          regionOrCountry: 'FRA',
          iconicRaceName: 'Paris-Roubaix',
          category: KomSegmentCategory.cobbleSector,
          lengthKm: 2.1,
          elevationGainM: 6.0,
          averageGradientPercent: 0.3,
          maxGradientPercent: 1.8,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          classification: SegmentClassification.none,
          cobbleDifficultyStars: 5,
        ),
        komRiderId: 'hist_mvdp_carrefour',
        komRiderName: 'Mathieu van der Poel',
        komNat: 'NED',
        komTeam: 'Alpecin-Deceuninck',
        komSeconds: 171, // 2:51
        komWatts: 518.0,
        komWeight: 75.0,
        komYear: 2024,
        runnerUpName: 'Mads Pedersen',
        runnerUpNat: 'DEN',
        runnerUpTeam: 'Lidl-Trek',
        runnerUpSeconds: 176,
        runnerUpWatts: 530.0,
        runnerUpWeight: 80.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'oude_kwaremont',
          name: 'Oude Kwaremont',
          regionOrCountry: 'BEL',
          iconicRaceName: 'Ronde van Vlaanderen',
          category: KomSegmentCategory.cobbleSector,
          lengthKm: 2.2,
          elevationGainM: 93.0,
          averageGradientPercent: 4.2,
          maxGradientPercent: 11.6,
          surfaceType: SegmentSurfaceType.cobblestonesSector4,
          classification: SegmentClassification.cat3,
          cobbleDifficultyStars: 4,
        ),
        komRiderId: 'hist_pogacar_kwaremont',
        komRiderName: 'Tadej Pogačar',
        komNat: 'SLO',
        komTeam: 'UAE Team Emirates',
        komSeconds: 204, // 3:24
        komWatts: 492.0,
        komWeight: 66.0,
        komYear: 2023,
        runnerUpName: 'Mathieu van der Poel',
        runnerUpNat: 'NED',
        runnerUpTeam: 'Alpecin-Deceuninck',
        runnerUpSeconds: 209,
        runnerUpWatts: 525.0,
        runnerUpWeight: 75.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'koppenberg',
          name: 'Koppenberg',
          regionOrCountry: 'BEL',
          iconicRaceName: 'Ronde van Vlaanderen',
          category: KomSegmentCategory.cobbleSector,
          lengthKm: 0.6,
          elevationGainM: 64.0,
          averageGradientPercent: 11.6,
          maxGradientPercent: 22.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          classification: SegmentClassification.cat2,
          cobbleDifficultyStars: 5,
        ),
        komRiderId: 'hist_cancellara_koppenberg',
        komRiderName: 'Fabian Cancellara',
        komNat: 'SUI',
        komTeam: 'Team Saxo Bank',
        komSeconds: 88, // 1:28
        komWatts: 585.0,
        komWeight: 80.0,
        komYear: 2010,
        runnerUpName: 'Mathieu van der Poel',
        runnerUpNat: 'NED',
        runnerUpTeam: 'Alpecin-Deceuninck',
        runnerUpSeconds: 90,
        runnerUpWatts: 550.0,
        runnerUpWeight: 75.0,
      ),
      _IconicSeedSpec(
        definition: KomSegmentDefinition(
          segmentId: 'monte_sante_marie',
          name: 'Settore Monte Sante Marie',
          regionOrCountry: 'ITA',
          iconicRaceName: 'Strade Bianche',
          category: KomSegmentCategory.gravelSector,
          lengthKm: 11.5,
          elevationGainM: 315.0,
          averageGradientPercent: 2.7,
          maxGradientPercent: 18.0,
          surfaceType: SegmentSurfaceType.gravelStrade,
          classification: SegmentClassification.cat2,
          cobbleDifficultyStars: 4,
        ),
        komRiderId: 'hist_pogacar_sante_marie',
        komRiderName: 'Tadej Pogačar',
        komNat: 'SLO',
        komTeam: 'UAE Team Emirates',
        komSeconds: 1068, // 17:48
        komWatts: 432.0,
        komWeight: 66.0,
        komYear: 2024,
        runnerUpName: 'Tom Pidcock',
        runnerUpNat: 'GBR',
        runnerUpTeam: 'INEOS Grenadiers',
        runnerUpSeconds: 1102,
        runnerUpWatts: 392.0,
        runnerUpWeight: 58.0,
      ),
    ];

    for (final spec in iconicSpecs) {
      registerSegment(spec.definition);
      final baseDate = DateTime.utc(spec.komYear, 7, 14, 15, 30);
      _insertHistoricSeed(
        segment: spec.definition,
        riderId: spec.komRiderId,
        riderName: spec.komRiderName,
        nationality: spec.komNat,
        teamName: spec.komTeam,
        year: spec.komYear,
        seconds: spec.komSeconds,
        watts: spec.komWatts,
        weightKg: spec.komWeight,
        recordedAt: baseDate,
      );
      _insertHistoricSeed(
        segment: spec.definition,
        riderId: '${spec.komRiderId}_2nd',
        riderName: spec.runnerUpName,
        nationality: spec.runnerUpNat,
        teamName: spec.runnerUpTeam,
        year: spec.komYear,
        seconds: spec.runnerUpSeconds,
        watts: spec.runnerUpWatts,
        weightKg: spec.runnerUpWeight,
        recordedAt: baseDate.add(const Duration(seconds: 2)),
      );
    }
  }

  void _insertHistoricSeed({
    required KomSegmentDefinition segment,
    required String riderId,
    required String riderName,
    required String nationality,
    required String teamName,
    required int year,
    required int seconds,
    required double watts,
    required double weightKg,
    required DateTime recordedAt,
  }) {
    _effortSequence++;
    final hours = seconds / 3600.0;
    final speedKmh = hours > 0 ? segment.lengthKm / hours : 0.0;
    final vam =
        (hours > 0 && segment.elevationGainM > 0) ? segment.elevationGainM / hours : 0.0;

    final effort = KomSegmentEffort(
      effortId: 'hist_${segment.segmentId}_$_effortSequence',
      segmentId: segment.segmentId,
      riderId: riderId,
      riderName: riderName,
      riderNationality: nationality,
      teamId: 'hist_${teamName.toLowerCase().replaceAll(' ', '_')}',
      teamName: teamName,
      isPlayerTeam: false,
      seasonYear: year,
      raceName: segment.iconicRaceName,
      recordedAt: recordedAt,
      elapsedSeconds: seconds,
      exactSeconds: seconds.toDouble(),
      averageSpeedKmh: double.parse(speedKmh.toStringAsFixed(2)),
      averagePowerWatts: watts,
      averageWattsPerKg: double.parse((watts / weightKg).toStringAsFixed(2)),
      vamMetersPerHour: double.parse(vam.toStringAsFixed(0)),
      isHistoricBenchmark: true,
    );

    final list = _effortsBySegment.putIfAbsent(segment.segmentId, () => []);
    list.add(effort);
    _effortsBySegment[segment.segmentId] = _sortedEfforts(list);
  }
}

class _IconicSeedSpec {
  final KomSegmentDefinition definition;
  final String komRiderId;
  final String komRiderName;
  final String komNat;
  final String komTeam;
  final int komSeconds;
  final double komWatts;
  final double komWeight;
  final int komYear;
  final String runnerUpName;
  final String runnerUpNat;
  final String runnerUpTeam;
  final int runnerUpSeconds;
  final double runnerUpWatts;
  final double runnerUpWeight;

  const _IconicSeedSpec({
    required this.definition,
    required this.komRiderId,
    required this.komRiderName,
    required this.komNat,
    required this.komTeam,
    required this.komSeconds,
    required this.komWatts,
    required this.komWeight,
    required this.komYear,
    required this.runnerUpName,
    required this.runnerUpNat,
    required this.runnerUpTeam,
    required this.runnerUpSeconds,
    required this.runnerUpWatts,
    required this.runnerUpWeight,
  });
}

/// Stan Riverpod dla wirtualnych segmentów KOM i rekordów kariery.
class WorldRecordsAndStravaKomState {
  final WorldRecordsAndStravaKomSegments registry;
  final String? selectedSegmentId;
  final KomSegmentCategory? categoryFilter;
  final bool onlyPlayerTeam;
  final String searchQuery;
  final KomRecordBrokenEvent? latestBrokenBanner;

  const WorldRecordsAndStravaKomState({
    required this.registry,
    this.selectedSegmentId,
    this.categoryFilter,
    this.onlyPlayerTeam = false,
    this.searchQuery = '',
    this.latestBrokenBanner,
  });

  List<KomSegmentDefinition> get filteredSegments {
    final q = searchQuery.trim().toLowerCase();
    return registry.allSegments.where((seg) {
      if (categoryFilter != null && seg.category != categoryFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final holder = registry.getCurrentKomCrownHolder(seg.segmentId);
        final matchesSeg = seg.name.toLowerCase().contains(q) ||
            seg.iconicRaceName.toLowerCase().contains(q) ||
            seg.regionOrCountry.toLowerCase().contains(q);
        final matchesHolder =
            holder != null && holder.riderName.toLowerCase().contains(q);
        if (!matchesSeg && !matchesHolder) return false;
      }
      return true;
    }).toList();
  }

  String? get effectiveSelectedSegmentId {
    final filtered = filteredSegments;
    if (filtered.isEmpty) return null;
    if (selectedSegmentId != null &&
        filtered.any((s) => s.segmentId == selectedSegmentId)) {
      return selectedSegmentId;
    }
    return filtered.first.segmentId;
  }

  WorldRecordsAndStravaKomState copyWith({
    WorldRecordsAndStravaKomSegments? registry,
    String? selectedSegmentId,
    KomSegmentCategory? categoryFilter,
    bool clearCategoryFilter = false,
    bool? onlyPlayerTeam,
    String? searchQuery,
    KomRecordBrokenEvent? latestBrokenBanner,
    bool clearBanner = false,
  }) {
    return WorldRecordsAndStravaKomState(
      registry: registry ?? this.registry,
      selectedSegmentId: selectedSegmentId ?? this.selectedSegmentId,
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      onlyPlayerTeam: onlyPlayerTeam ?? this.onlyPlayerTeam,
      searchQuery: searchQuery ?? this.searchQuery,
      latestBrokenBanner:
          clearBanner ? null : (latestBrokenBanner ?? this.latestBrokenBanner),
    );
  }
}

/// Notifier Riverpod zarządzający segmentami KOM w czasie rzeczywistym.
class WorldRecordsAndStravaKomNotifier
    extends StateNotifier<WorldRecordsAndStravaKomState> {
  WorldRecordsAndStravaKomNotifier([WorldRecordsAndStravaKomSegments? initial])
      : super(
          WorldRecordsAndStravaKomState(
            registry: initial ?? WorldRecordsAndStravaKomSegments(),
            selectedSegmentId: 'alpe_d_huez',
          ),
        );

  void selectSegment(String segmentId) {
    state = state.copyWith(selectedSegmentId: segmentId);
  }

  void setCategoryFilter(KomSegmentCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(categoryFilter: category);
    }
  }

  void setOnlyPlayerTeam(bool value) {
    state = state.copyWith(onlyPlayerTeam: value);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void dismissBanner() {
    state = state.copyWith(clearBanner: true);
  }

  KomPassageRecordResult recordPassage(KomPassageInput input) {
    final result = state.registry.recordPassage(input);
    state = state.copyWith(
      selectedSegmentId: input.segmentId,
      latestBrokenBanner: result.brokenEvent,
    );
    return result;
  }

  List<KomPassageRecordResult> recordBatchPassages(
    List<KomPassageInput> inputs,
  ) {
    final results = state.registry.recordBatchPassages(inputs);
    KomRecordBrokenEvent? newestCrown;
    for (final r in results) {
      if (r.brokenEvent != null) {
        newestCrown = r.brokenEvent;
      }
    }
    state = state.copyWith(
      latestBrokenBanner: newestCrown,
    );
    return results;
  }

  void registerFromStageSegments({
    required String raceId,
    required String raceName,
    required String countryCode,
    required List<StageSegment> segments,
  }) {
    state.registry.registerFromStageSegments(
      raceId: raceId,
      raceName: raceName,
      countryCode: countryCode,
      segments: segments,
    );
    state = state.copyWith();
  }

  void loadFromJson(Map<String, dynamic> json) {
    final loaded = WorldRecordsAndStravaKomSegments.fromJson(json);
    state = WorldRecordsAndStravaKomState(
      registry: loaded,
      selectedSegmentId:
          loaded.allSegments.isNotEmpty ? loaded.allSegments.first.segmentId : null,
    );
  }
}

final worldRecordsAndStravaKomProvider = StateNotifierProvider<
    WorldRecordsAndStravaKomNotifier, WorldRecordsAndStravaKomState>((ref) {
  return WorldRecordsAndStravaKomNotifier();
});

/// Panel UI wirtualnych segmentów KOM i globalnej tabeli wszech czasów kariery.
class WorldRecordsAndStravaKomPanel extends ConsumerStatefulWidget {
  final bool isEnabled;
  final VoidCallback? onClose;

  const WorldRecordsAndStravaKomPanel({
    super.key,
    this.isEnabled = true,
    this.onClose,
  });

  @override
  ConsumerState<WorldRecordsAndStravaKomPanel> createState() =>
      _WorldRecordsAndStravaKomPanelState();
}

class _WorldRecordsAndStravaKomPanelState
    extends ConsumerState<WorldRecordsAndStravaKomPanel> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final komState = ref.watch(worldRecordsAndStravaKomProvider);
    final notifier = ref.read(worldRecordsAndStravaKomProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 1024.0;
        final isCompact = width < 720;
        final isWide = width >= 1120;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(komState, isCompact),
              if (komState.latestBrokenBanner != null) ...[
                const SizedBox(height: 12),
                _buildBrokenCrownBanner(
                  komState.latestBrokenBanner!,
                  notifier,
                  isCompact,
                ),
              ],
              const SizedBox(height: 12),
              _buildFilterToolbar(komState, notifier, isCompact),
              const SizedBox(height: 14),
              Expanded(
                child: isWide
                    ? _buildDesktopSplitBody(komState, notifier)
                    : _buildStackedBody(komState, notifier, isCompact),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(WorldRecordsAndStravaKomState komState, bool isCompact) {
    final playerCrowns = komState.registry.countPlayerTeamKomCrowns();
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEGMENTY KOM & REKORDY WSZECH CZASÓW',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Automatyczny pomiar przejazdów co do sekundy i Korona KOM',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 11 : 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricPill(
              icon: Icons.flag_rounded,
              label: 'Segmenty',
              value: '${komState.registry.totalSegmentsCount}',
              accentColor: AppColors.accentBlue,
            ),
            _MetricPill(
              icon: Icons.timer_rounded,
              label: 'Przejazdy',
              value: '${komState.registry.totalEffortsCount}',
              accentColor: AppColors.statusSuccess,
            ),
            _MetricPill(
              icon: Icons.emoji_events_rounded,
              label: 'Korony Ekipy',
              value: '$playerCrowns',
              accentColor: AppColors.goldAccent,
            ),
            if (widget.onClose != null)
              _InteractiveActionButton(
                label: 'Zamknij',
                icon: Icons.close_rounded,
                enabled: widget.isEnabled,
                onTap: widget.onClose!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrokenCrownBanner(
    KomRecordBrokenEvent event,
    WorldRecordsAndStravaKomNotifier notifier,
    bool isCompact,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'NOWA KORONA KOM! ${event.newKomEffort.riderName} (${event.newKomEffort.teamName}) '
              'pobił rekord na ${event.segmentName} o ${event.secondsImproved}s '
              '— ${event.newKomEffort.formattedTime}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _InteractiveActionButton(
            label: 'OK',
            icon: Icons.check_rounded,
            enabled: widget.isEnabled,
            onTap: notifier.dismissBanner,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(
    WorldRecordsAndStravaKomState komState,
    WorldRecordsAndStravaKomNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  enabled: widget.isEnabled,
                  onChanged: notifier.setSearchQuery,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    hintText: 'Szukaj podjazdu, sektora bruku lub rekordzisty...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: widget.isEnabled
                                ? () {
                                    _searchController.clear();
                                    notifier.setSearchQuery('');
                                  }
                                : null,
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.goldAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                _InteractiveFilterChip(
                  label: 'Tylko Moja Ekipa',
                  icon: Icons.shield_rounded,
                  selected: komState.onlyPlayerTeam,
                  enabled: widget.isEnabled,
                  accentColor: AppColors.goldAccent,
                  onTap: () =>
                      notifier.setOnlyPlayerTeam(!komState.onlyPlayerTeam),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _InteractiveFilterChip(
                  label: 'Wszystkie',
                  icon: Icons.public_rounded,
                  selected: komState.categoryFilter == null,
                  enabled: widget.isEnabled,
                  onTap: () => notifier.setCategoryFilter(null),
                ),
                const SizedBox(width: 8),
                for (final cat in KomSegmentCategory.values) ...[
                  _InteractiveFilterChip(
                    label: cat.polishLabel,
                    icon: cat.icon,
                    selected: komState.categoryFilter == cat,
                    enabled: widget.isEnabled,
                    onTap: () => notifier.setCategoryFilter(
                      komState.categoryFilter == cat ? null : cat,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isCompact)
                  _InteractiveFilterChip(
                    label: 'Moja Ekipa',
                    icon: Icons.shield_rounded,
                    selected: komState.onlyPlayerTeam,
                    enabled: widget.isEnabled,
                    accentColor: AppColors.goldAccent,
                    onTap: () =>
                        notifier.setOnlyPlayerTeam(!komState.onlyPlayerTeam),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSplitBody(
    WorldRecordsAndStravaKomState komState,
    WorldRecordsAndStravaKomNotifier notifier,
  ) {
    final segments = komState.filteredSegments;
    final selectedId = komState.effectiveSelectedSegmentId;
    if (segments.isEmpty || selectedId == null) {
      return _buildEmptyState();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: ListView.separated(
            itemCount: segments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final seg = segments[index];
              final holder =
                  komState.registry.getCurrentKomCrownHolder(seg.segmentId);
              return _SegmentSelectorCard(
                segment: seg,
                crownHolder: holder,
                isSelected: seg.segmentId == selectedId,
                isEnabled: widget.isEnabled,
                onTap: () => notifier.selectSegment(seg.segmentId),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildLeaderboardDetail(
            komState,
            selectedId,
            isCompact: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStackedBody(
    WorldRecordsAndStravaKomState komState,
    WorldRecordsAndStravaKomNotifier notifier,
    bool isCompact,
  ) {
    final segments = komState.filteredSegments;
    final selectedId = komState.effectiveSelectedSegmentId;
    if (segments.isEmpty || selectedId == null) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: isCompact ? 116 : 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: segments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final seg = segments[index];
              final holder =
                  komState.registry.getCurrentKomCrownHolder(seg.segmentId);
              return SizedBox(
                width: isCompact ? 248 : 280,
                child: _SegmentSelectorCard(
                  segment: seg,
                  crownHolder: holder,
                  isSelected: seg.segmentId == selectedId,
                  isEnabled: widget.isEnabled,
                  onTap: () => notifier.selectSegment(seg.segmentId),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildLeaderboardDetail(
            komState,
            selectedId,
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardDetail(
    WorldRecordsAndStravaKomState komState,
    String segmentId, {
    required bool isCompact,
  }) {
    final segment = komState.registry.getSegment(segmentId);
    if (segment == null) return _buildEmptyState();

    final entries = komState.registry.getLeaderboard(
      segmentId,
      onlyPlayerTeam: komState.onlyPlayerTeam,
    );
    final crownHolder = komState.registry.getCurrentKomCrownHolder(segmentId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSegmentHero(segment, crownHolder, isCompact),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 10),
          Expanded(
            child: entries.isEmpty
                ? _buildEmptyLeaderboard()
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      return _KomLeaderboardRowTile(
                        entry: entries[index],
                        isCompact: isCompact,
                        isEnabled: widget.isEnabled,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentHero(
    KomSegmentDefinition segment,
    KomSegmentEffort? crownHolder,
    bool isCompact,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  segment.category.icon,
                  color: AppColors.goldAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    segment.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _SpecText('${segment.iconicRaceName} (${segment.regionOrCountry})'),
                _SpecText('${segment.lengthKm.toStringAsFixed(1)} km'),
                _SpecText('+${segment.elevationGainM.toStringAsFixed(0)} m'),
                _SpecText(
                  'śr. ${segment.averageGradientPercent.toStringAsFixed(1)}% / max ${segment.maxGradientPercent.toStringAsFixed(1)}%',
                ),
                if (segment.cobbleDifficultyStars > 0)
                  _SpecText('Bruk ${'★' * segment.cobbleDifficultyStars}'),
              ],
            ),
          ],
        ),
        if (crownHolder != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KORONA KOM • ${crownHolder.riderName}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                        ),
                      ),
                      Text(
                        '${crownHolder.formattedTime}  •  ${crownHolder.averageSpeedKmh.toStringAsFixed(1)} km/h  •  ${crownHolder.averageWattsPerKg.toStringAsFixed(2)} W/kg',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'Brak segmentów KOM spełniających wybrane kryteria.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLeaderboard() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Brak zarejestrowanych przejazdów dla wybranych filtrów.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SpecText extends StatelessWidget {
  final String text;
  const _SpecText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11.5,
        fontFeatures: [FontFeature.tabularFigures()],
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;
    final bg = !active
        ? AppColors.surface.withValues(alpha: 0.5)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.surface;

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: active
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active
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

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    this.accentColor = AppColors.primaryAccent,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;
    final bgColor = !active
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.selected
            ? widget.accentColor.withValues(alpha: _pressed ? 0.35 : 0.22)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? widget.accentColor
            : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: !active
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : widget.selected
                        ? widget.accentColor
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: !active
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentSelectorCard extends StatefulWidget {
  final KomSegmentDefinition segment;
  final KomSegmentEffort? crownHolder;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _SegmentSelectorCard({
    required this.segment,
    this.crownHolder,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_SegmentSelectorCard> createState() => _SegmentSelectorCardState();
}

class _SegmentSelectorCardState extends State<_SegmentSelectorCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isEnabled;
    final bg = !active
        ? AppColors.surface.withValues(alpha: 0.45)
        : widget.isSelected
            ? AppColors.surfaceLight
            : _pressed
                ? AppColors.surfaceLight.withValues(alpha: 0.8)
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.6)
                    : AppColors.surface;

    final border = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.goldAccent.withValues(alpha: 0.85)
            : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: border,
              width: widget.isSelected || _focused ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.segment.category.icon,
                    size: 16,
                    color: widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.segment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.segment.lengthKm.toStringAsFixed(1)} km • '
                '${widget.segment.averageGradientPercent.toStringAsFixed(1)}% • '
                '${widget.segment.iconicRaceName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.crownHolder != null)
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.crownHolder!.riderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.crownHolder!.formattedTime,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KomLeaderboardRowTile extends StatefulWidget {
  final KomLeaderboardEntry entry;
  final bool isCompact;
  final bool isEnabled;

  const _KomLeaderboardRowTile({
    required this.entry,
    required this.isCompact,
    required this.isEnabled,
  });

  @override
  State<_KomLeaderboardRowTile> createState() => _KomLeaderboardRowTileState();
}

class _KomLeaderboardRowTileState extends State<_KomLeaderboardRowTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry.effort;
    final isKom = widget.entry.isCurrentKomCrownHolder;
    final bgColor = isKom
        ? AppColors.goldAccent.withValues(alpha: _hovered ? 0.16 : 0.10)
        : e.isPlayerTeam
            ? AppColors.primaryAccent.withValues(alpha: _hovered ? 0.18 : 0.11)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = isKom
        ? AppColors.goldAccent.withValues(alpha: 0.55)
        : e.isPlayerTeam
            ? AppColors.primaryAccent.withValues(alpha: 0.5)
            : AppTheme.borderColor;

    return MouseRegion(
      onEnter: widget.isEnabled ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.isEnabled ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 10 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: isKom
                  ? const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.goldAccent,
                      size: 20,
                    )
                  : Text(
                      '#${widget.entry.rank}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          e.riderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isKom
                                ? AppColors.goldAccent
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (e.isPlayerTeam) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'EKIPA',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e.teamName} • ${e.raceName} ${e.seasonYear}',
                    maxLines: 1,
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
            if (!widget.isCompact) ...[
              const SizedBox(width: 10),
              Text(
                '${e.averagePowerWatts.toStringAsFixed(0)} W (${e.averageWattsPerKg.toStringAsFixed(2)} W/kg)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
              if (e.vamMetersPerHour > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '${e.vamMetersPerHour.toStringAsFixed(0)} m/h',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.accentBlue,
                  ),
                ),
              ],
            ],
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  e.formattedTime,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color:
                        isKom ? AppColors.goldAccent : AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.entry.formattedDelta,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isKom
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
