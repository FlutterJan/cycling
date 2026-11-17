import 'dart:convert';
import 'dart:math' as math;

/// Format rozgrywek ligi wieloosobowej online.
enum LeagueFormat {
  headToHead,
  seasonPoints,
  grandTourCup,
  weeklyChallenge;

  String toJson() => name;

  String get label {
    switch (this) {
      case LeagueFormat.headToHead:
        return 'Head-to-Head 1v1';
      case LeagueFormat.seasonPoints:
        return 'Liga Sezonowa (Punkty)';
      case LeagueFormat.grandTourCup:
        return 'Puchar Grand Tour (GC)';
      case LeagueFormat.weeklyChallenge:
        return 'Wyzwanie Tygodnia';
    }
  }

  String get shortLabel {
    switch (this) {
      case LeagueFormat.headToHead:
        return 'H2H';
      case LeagueFormat.seasonPoints:
        return 'PTS';
      case LeagueFormat.grandTourCup:
        return 'GT';
      case LeagueFormat.weeklyChallenge:
        return 'WK';
    }
  }

  int get defaultStageCount {
    switch (this) {
      case LeagueFormat.headToHead:
        return 3;
      case LeagueFormat.seasonPoints:
        return 12;
      case LeagueFormat.grandTourCup:
        return 21;
      case LeagueFormat.weeklyChallenge:
        return 1;
    }
  }

  static LeagueFormat fromJson(String value) {
    return LeagueFormat.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LeagueFormat.seasonPoints,
    );
  }
}

/// Poziom prywatności i dostępu do ligi online.
enum LeaguePrivacy {
  publicRanked,
  friendsOnly,
  inviteCode;

  String toJson() => name;

  String get label {
    switch (this) {
      case LeaguePrivacy.publicRanked:
        return 'Publiczna (Ranking ELO)';
      case LeaguePrivacy.friendsOnly:
        return 'Tylko Znajomi';
      case LeaguePrivacy.inviteCode:
        return 'Prywatna (Kod Zaproszenia)';
    }
  }

  static LeaguePrivacy fromJson(String value) {
    return LeaguePrivacy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LeaguePrivacy.publicRanked,
    );
  }
}

/// Aktualny status cyklu życia ligi online.
enum LeagueStatus {
  recruiting,
  drafting,
  active,
  completed,
  archived;

  String toJson() => name;

  String get label {
    switch (this) {
      case LeagueStatus.recruiting:
        return 'Rekrutacja';
      case LeagueStatus.drafting:
        return 'Draft Składów';
      case LeagueStatus.active:
        return 'W Trakcie';
      case LeagueStatus.completed:
        return 'Zakończona';
      case LeagueStatus.archived:
        return 'Zarchiwizowana';
    }
  }

  bool get isJoinable => this == LeagueStatus.recruiting;

  static LeagueStatus fromJson(String value) {
    return LeagueStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LeagueStatus.recruiting,
    );
  }
}

/// Rola uczestnika w lidze wieloosobowej.
enum LeagueMemberRole {
  commissioner,
  coCommissioner,
  participant;

  String toJson() => name;

  String get label {
    switch (this) {
      case LeagueMemberRole.commissioner:
        return 'Komisarz Ligi';
      case LeagueMemberRole.coCommissioner:
        return 'Współkomisarz';
      case LeagueMemberRole.participant:
        return 'Uczestnik';
    }
  }

  bool get canManageLeague =>
      this == LeagueMemberRole.commissioner ||
      this == LeagueMemberRole.coCommissioner;

  static LeagueMemberRole fromJson(String value) {
    return LeagueMemberRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LeagueMemberRole.participant,
    );
  }
}

/// Status draftu kolarzy przed startem ligi.
enum LeagueDraftStatus {
  notStarted,
  inProgress,
  completed;

  String toJson() => name;

  String get label {
    switch (this) {
      case LeagueDraftStatus.notStarted:
        return 'Oczekuje na Draft';
      case LeagueDraftStatus.inProgress:
        return 'Draft w Toku';
      case LeagueDraftStatus.completed:
        return 'Draft Zakończony';
    }
  }

  static LeagueDraftStatus fromJson(String value) {
    return LeagueDraftStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LeagueDraftStatus.notStarted,
    );
  }
}

/// Dywizja rankingowa ELO dla lig i wyzwań online.
enum EloDivisionTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  worldTourElite,
  grandTourLegend;

  String toJson() => name;

  String get label {
    switch (this) {
      case EloDivisionTier.bronze:
        return 'Brązowa';
      case EloDivisionTier.silver:
        return 'Srebrna';
      case EloDivisionTier.gold:
        return 'Złota';
      case EloDivisionTier.platinum:
        return 'Platynowa';
      case EloDivisionTier.diamond:
        return 'Diamentowa';
      case EloDivisionTier.worldTourElite:
        return 'WorldTour Elite';
      case EloDivisionTier.grandTourLegend:
        return 'Grand Tour Legend';
    }
  }

  int get minElo {
    switch (this) {
      case EloDivisionTier.bronze:
        return 0;
      case EloDivisionTier.silver:
        return 1000;
      case EloDivisionTier.gold:
        return 1250;
      case EloDivisionTier.platinum:
        return 1500;
      case EloDivisionTier.diamond:
        return 1750;
      case EloDivisionTier.worldTourElite:
        return 2000;
      case EloDivisionTier.grandTourLegend:
        return 2300;
    }
  }

  int get maxElo {
    switch (this) {
      case EloDivisionTier.bronze:
        return 999;
      case EloDivisionTier.silver:
        return 1249;
      case EloDivisionTier.gold:
        return 1499;
      case EloDivisionTier.platinum:
        return 1749;
      case EloDivisionTier.diamond:
        return 1999;
      case EloDivisionTier.worldTourElite:
        return 2299;
      case EloDivisionTier.grandTourLegend:
        return 9999;
    }
  }

  int get kFactor {
    switch (this) {
      case EloDivisionTier.bronze:
      case EloDivisionTier.silver:
        return 28;
      case EloDivisionTier.gold:
      case EloDivisionTier.platinum:
        return 24;
      case EloDivisionTier.diamond:
        return 20;
      case EloDivisionTier.worldTourElite:
      case EloDivisionTier.grandTourLegend:
        return 16;
    }
  }

  String get badgeColorHex {
    switch (this) {
      case EloDivisionTier.bronze:
        return '#8E4A49';
      case EloDivisionTier.silver:
        return '#9CA3AF';
      case EloDivisionTier.gold:
        return '#D4AF37';
      case EloDivisionTier.platinum:
        return '#38BDF8';
      case EloDivisionTier.diamond:
        return '#00E5FF';
      case EloDivisionTier.worldTourElite:
        return '#10B981';
      case EloDivisionTier.grandTourLegend:
        return '#F59E0B';
    }
  }

  static EloDivisionTier fromElo(int elo) {
    if (elo >= 2300) return EloDivisionTier.grandTourLegend;
    if (elo >= 2000) return EloDivisionTier.worldTourElite;
    if (elo >= 1750) return EloDivisionTier.diamond;
    if (elo >= 1500) return EloDivisionTier.platinum;
    if (elo >= 1250) return EloDivisionTier.gold;
    if (elo >= 1000) return EloDivisionTier.silver;
    return EloDivisionTier.bronze;
  }

  static EloDivisionTier fromJson(String value) {
    return EloDivisionTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EloDivisionTier.silver,
    );
  }
}

/// Poziom trudności asynchronicznego wyzwania ducha.
enum GhostChallengeDifficulty {
  casual,
  competitive,
  proPeloton,
  legendary;

  String toJson() => name;

  String get label {
    switch (this) {
      case GhostChallengeDifficulty.casual:
        return 'Rekreacyjne';
      case GhostChallengeDifficulty.competitive:
        return 'Rywalizacja';
      case GhostChallengeDifficulty.proPeloton:
        return 'Pro Peloton';
      case GhostChallengeDifficulty.legendary:
        return 'Legendarne';
    }
  }

  double get eloMultiplier {
    switch (this) {
      case GhostChallengeDifficulty.casual:
        return 0.75;
      case GhostChallengeDifficulty.competitive:
        return 1.0;
      case GhostChallengeDifficulty.proPeloton:
        return 1.25;
      case GhostChallengeDifficulty.legendary:
        return 1.5;
    }
  }

  static GhostChallengeDifficulty fromJson(String value) {
    return GhostChallengeDifficulty.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GhostChallengeDifficulty.competitive,
    );
  }
}

/// Status asynchronicznego wyzwania ducha.
enum GhostChallengeStatus {
  open,
  accepted,
  completed,
  expired;

  String toJson() => name;

  String get label {
    switch (this) {
      case GhostChallengeStatus.open:
        return 'Otwarte';
      case GhostChallengeStatus.accepted:
        return 'Podjęte';
      case GhostChallengeStatus.completed:
        return 'Ukończone';
      case GhostChallengeStatus.expired:
        return 'Wygasłe';
    }
  }

  static GhostChallengeStatus fromJson(String value) {
    return GhostChallengeStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GhostChallengeStatus.open,
    );
  }
}

/// Zamrożona migawka warunków pogodowych gwarantująca 100% identyczną pogodę
/// dla wszystkich graczy w lidze oraz w asynchronicznych wyzwaniach duchów.
class WeatherConditionSnapshot {
  final int weatherSeed;
  final double temperatureC;
  final double windSpeedKmh;
  final double windDirectionDegrees;
  final double precipitationMmPerHour;
  final double humidityPercent;
  final double roadWetness;
  final double airDensityKgM3;
  final double cloudCoverPercent;
  final String weatherLabel;

  const WeatherConditionSnapshot({
    required this.weatherSeed,
    required this.temperatureC,
    required this.windSpeedKmh,
    required this.windDirectionDegrees,
    required this.precipitationMmPerHour,
    required this.humidityPercent,
    required this.roadWetness,
    this.airDensityKgM3 = 1.225,
    this.cloudCoverPercent = 25.0,
    this.weatherLabel = 'Pogodnie',
  });

  /// Deterministyczny skrót FNV-1a 64-bit weryfikujący identyczność pogody.
  String get weatherHash {
    final canonical = [
      weatherSeed.toString(),
      temperatureC.toStringAsFixed(2),
      windSpeedKmh.toStringAsFixed(2),
      _normalizeDegrees(windDirectionDegrees).toStringAsFixed(2),
      precipitationMmPerHour.toStringAsFixed(2),
      humidityPercent.toStringAsFixed(1),
      roadWetness.clamp(0.0, 1.0).toStringAsFixed(3),
      airDensityKgM3.toStringAsFixed(4),
      cloudCoverPercent.toStringAsFixed(1),
    ].join('|');
    return _fnv1a64Hex(canonical);
  }

  /// Sprawdza, czy warunki pogodowe drugiej próby są identyczne co do ziarna i parametrów.
  bool isIdenticalTo(WeatherConditionSnapshot other) {
    return weatherHash == other.weatherHash;
  }

  bool get isWetRoad => roadWetness >= 0.25 || precipitationMmPerHour >= 0.5;

  bool get isCrosswindAlert => windSpeedKmh >= 28.0;

  WeatherConditionSnapshot copyWith({
    int? weatherSeed,
    double? temperatureC,
    double? windSpeedKmh,
    double? windDirectionDegrees,
    double? precipitationMmPerHour,
    double? humidityPercent,
    double? roadWetness,
    double? airDensityKgM3,
    double? cloudCoverPercent,
    String? weatherLabel,
  }) {
    return WeatherConditionSnapshot(
      weatherSeed: weatherSeed ?? this.weatherSeed,
      temperatureC: temperatureC ?? this.temperatureC,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      windDirectionDegrees: windDirectionDegrees ?? this.windDirectionDegrees,
      precipitationMmPerHour:
          precipitationMmPerHour ?? this.precipitationMmPerHour,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      roadWetness: roadWetness ?? this.roadWetness,
      airDensityKgM3: airDensityKgM3 ?? this.airDensityKgM3,
      cloudCoverPercent: cloudCoverPercent ?? this.cloudCoverPercent,
      weatherLabel: weatherLabel ?? this.weatherLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weatherSeed': weatherSeed,
      'temperatureC': temperatureC,
      'windSpeedKmh': windSpeedKmh,
      'windDirectionDegrees': _normalizeDegrees(windDirectionDegrees),
      'precipitationMmPerHour': precipitationMmPerHour,
      'humidityPercent': humidityPercent,
      'roadWetness': roadWetness.clamp(0.0, 1.0),
      'airDensityKgM3': airDensityKgM3,
      'cloudCoverPercent': cloudCoverPercent,
      'weatherLabel': weatherLabel,
    };
  }

  factory WeatherConditionSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherConditionSnapshot(
      weatherSeed: (json['weatherSeed'] as num?)?.toInt() ?? 42001,
      temperatureC: (json['temperatureC'] as num?)?.toDouble() ?? 18.0,
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 12.0,
      windDirectionDegrees:
          (json['windDirectionDegrees'] as num?)?.toDouble() ?? 180.0,
      precipitationMmPerHour:
          (json['precipitationMmPerHour'] as num?)?.toDouble() ?? 0.0,
      humidityPercent: (json['humidityPercent'] as num?)?.toDouble() ?? 55.0,
      roadWetness:
          ((json['roadWetness'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
      airDensityKgM3: (json['airDensityKgM3'] as num?)?.toDouble() ?? 1.225,
      cloudCoverPercent:
          (json['cloudCoverPercent'] as num?)?.toDouble() ?? 25.0,
      weatherLabel: json['weatherLabel'] as String? ?? 'Pogodnie',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherConditionSnapshot &&
        other.weatherSeed == weatherSeed &&
        other.temperatureC == temperatureC &&
        other.windSpeedKmh == windSpeedKmh &&
        other.windDirectionDegrees == windDirectionDegrees &&
        other.precipitationMmPerHour == precipitationMmPerHour &&
        other.humidityPercent == humidityPercent &&
        other.roadWetness == roadWetness &&
        other.airDensityKgM3 == airDensityKgM3 &&
        other.cloudCoverPercent == cloudCoverPercent &&
        other.weatherLabel == weatherLabel;
  }

  @override
  int get hashCode => Object.hash(
        weatherSeed,
        temperatureC,
        windSpeedKmh,
        windDirectionDegrees,
        precipitationMmPerHour,
        humidityPercent,
        roadWetness,
        airDensityKgM3,
        cloudCoverPercent,
        weatherLabel,
      );
}

/// Pojedynczy wpis historii zmiany rankingu ELO po meczu lub etapie ligowym.
class EloMatchRecord {
  final String matchId;
  final String leagueId;
  final String opponentId;
  final String opponentName;
  final int eloBefore;
  final int eloAfter;
  final int delta;
  final int placement;
  final int fieldSize;
  final DateTime recordedAt;

  const EloMatchRecord({
    required this.matchId,
    required this.leagueId,
    required this.opponentId,
    required this.opponentName,
    required this.eloBefore,
    required this.eloAfter,
    required this.delta,
    required this.placement,
    required this.fieldSize,
    required this.recordedAt,
  });

  bool get isWin => placement == 1;
  bool get isPodium => placement >= 1 && placement <= 3;

  EloMatchRecord copyWith({
    String? matchId,
    String? leagueId,
    String? opponentId,
    String? opponentName,
    int? eloBefore,
    int? eloAfter,
    int? delta,
    int? placement,
    int? fieldSize,
    DateTime? recordedAt,
  }) {
    return EloMatchRecord(
      matchId: matchId ?? this.matchId,
      leagueId: leagueId ?? this.leagueId,
      opponentId: opponentId ?? this.opponentId,
      opponentName: opponentName ?? this.opponentName,
      eloBefore: eloBefore ?? this.eloBefore,
      eloAfter: eloAfter ?? this.eloAfter,
      delta: delta ?? this.delta,
      placement: placement ?? this.placement,
      fieldSize: fieldSize ?? this.fieldSize,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'leagueId': leagueId,
      'opponentId': opponentId,
      'opponentName': opponentName,
      'eloBefore': eloBefore,
      'eloAfter': eloAfter,
      'delta': delta,
      'placement': placement,
      'fieldSize': fieldSize,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory EloMatchRecord.fromJson(Map<String, dynamic> json) {
    return EloMatchRecord(
      matchId: json['matchId'] as String? ?? '',
      leagueId: json['leagueId'] as String? ?? '',
      opponentId: json['opponentId'] as String? ?? 'field',
      opponentName: json['opponentName'] as String? ?? 'Peleton Ligi',
      eloBefore: (json['eloBefore'] as num?)?.toInt() ?? 1200,
      eloAfter: (json['eloAfter'] as num?)?.toInt() ?? 1200,
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      placement: (json['placement'] as num?)?.toInt() ?? 1,
      fieldSize: math.max(2, (json['fieldSize'] as num?)?.toInt() ?? 2),
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EloMatchRecord &&
        other.matchId == matchId &&
        other.leagueId == leagueId &&
        other.opponentId == opponentId &&
        other.opponentName == opponentName &&
        other.eloBefore == eloBefore &&
        other.eloAfter == eloAfter &&
        other.delta == delta &&
        other.placement == placement &&
        other.fieldSize == fieldSize &&
        other.recordedAt == recordedAt;
  }

  @override
  int get hashCode => Object.hash(
        matchId,
        leagueId,
        opponentId,
        opponentName,
        eloBefore,
        eloAfter,
        delta,
        placement,
        fieldSize,
        recordedAt,
      );
}

/// Profil rankingowy ELO menedżera w rozgrywkach wieloosobowych online.
class EloRatingProfile {
  static const int maxHistoryLength = 50;

  final String playerId;
  final String displayName;
  final int currentElo;
  final int peakElo;
  final int matchesPlayed;
  final int wins;
  final int podiums;
  final int winStreak;
  final int bestWinStreak;
  final List<EloMatchRecord> recentHistory;

  const EloRatingProfile({
    required this.playerId,
    required this.displayName,
    this.currentElo = EloCalculator.defaultStartingElo,
    this.peakElo = EloCalculator.defaultStartingElo,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.podiums = 0,
    this.winStreak = 0,
    this.bestWinStreak = 0,
    this.recentHistory = const [],
  });

  EloDivisionTier get divisionTier => EloDivisionTier.fromElo(currentElo);

  double get winRate => matchesPlayed <= 0 ? 0.0 : wins / matchesPlayed;

  /// Postęp (0.0–1.0) do kolejnej dywizji ELO.
  double get progressToNextTier {
    final tier = divisionTier;
    if (tier == EloDivisionTier.grandTourLegend) return 1.0;
    final span = (tier.maxElo - tier.minElo + 1).toDouble();
    if (span <= 0) return 1.0;
    return ((currentElo - tier.minElo) / span).clamp(0.0, 1.0);
  }

  EloRatingProfile applyMatchResult(EloMatchRecord record) {
    final nextElo = math.max(EloCalculator.minEloFloor, record.eloAfter);
    final nextPeak = math.max(peakElo, nextElo);
    final nextWinStreak = record.isWin ? winStreak + 1 : 0;
    final nextBestStreak = math.max(bestWinStreak, nextWinStreak);
    final updatedHistory = [
      record.copyWith(eloAfter: nextElo),
      ...recentHistory,
    ].take(maxHistoryLength).toList(growable: false);

    return copyWith(
      currentElo: nextElo,
      peakElo: nextPeak,
      matchesPlayed: matchesPlayed + 1,
      wins: wins + (record.isWin ? 1 : 0),
      podiums: podiums + (record.isPodium ? 1 : 0),
      winStreak: nextWinStreak,
      bestWinStreak: nextBestStreak,
      recentHistory: updatedHistory,
    );
  }

  EloRatingProfile copyWith({
    String? playerId,
    String? displayName,
    int? currentElo,
    int? peakElo,
    int? matchesPlayed,
    int? wins,
    int? podiums,
    int? winStreak,
    int? bestWinStreak,
    List<EloMatchRecord>? recentHistory,
  }) {
    return EloRatingProfile(
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      currentElo: currentElo ?? this.currentElo,
      peakElo: peakElo ?? this.peakElo,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      podiums: podiums ?? this.podiums,
      winStreak: winStreak ?? this.winStreak,
      bestWinStreak: bestWinStreak ?? this.bestWinStreak,
      recentHistory: recentHistory ?? this.recentHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'displayName': displayName,
      'currentElo': currentElo,
      'peakElo': peakElo,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'podiums': podiums,
      'winStreak': winStreak,
      'bestWinStreak': bestWinStreak,
      'recentHistory': recentHistory.map((e) => e.toJson()).toList(),
    };
  }

  factory EloRatingProfile.fromJson(Map<String, dynamic> json) {
    final currentElo = (json['currentElo'] as num?)?.toInt() ??
        EloCalculator.defaultStartingElo;
    final rawHistory = json['recentHistory'] as List<dynamic>? ?? const [];
    return EloRatingProfile(
      playerId: json['playerId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Menedżer',
      currentElo: currentElo,
      peakElo: math.max(
        currentElo,
        (json['peakElo'] as num?)?.toInt() ?? currentElo,
      ),
      matchesPlayed: math.max(0, (json['matchesPlayed'] as num?)?.toInt() ?? 0),
      wins: math.max(0, (json['wins'] as num?)?.toInt() ?? 0),
      podiums: math.max(0, (json['podiums'] as num?)?.toInt() ?? 0),
      winStreak: math.max(0, (json['winStreak'] as num?)?.toInt() ?? 0),
      bestWinStreak: math.max(0, (json['bestWinStreak'] as num?)?.toInt() ?? 0),
      recentHistory: rawHistory
          .whereType<Map<String, dynamic>>()
          .map(EloMatchRecord.fromJson)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EloRatingProfile &&
        other.playerId == playerId &&
        other.displayName == displayName &&
        other.currentElo == currentElo &&
        other.peakElo == peakElo &&
        other.matchesPlayed == matchesPlayed &&
        other.wins == wins &&
        other.podiums == podiums &&
        other.winStreak == winStreak &&
        other.bestWinStreak == bestWinStreak &&
        _listEquals(other.recentHistory, recentHistory);
  }

  @override
  int get hashCode => Object.hash(
        playerId,
        displayName,
        currentElo,
        peakElo,
        matchesPlayed,
        wins,
        podiums,
        winStreak,
        bestWinStreak,
        Object.hashAll(recentHistory),
      );
}

/// Deterministyczny kalkulator ELO dla pojedynków 1v1 oraz wieloosobowych etapów ligowych.
class EloCalculator {
  static const int defaultStartingElo = 1200;
  static const int minEloFloor = 100;
  static const int provisionalMatchThreshold = 15;
  static const int provisionalKFactor = 40;

  const EloCalculator._();

  /// Oczekiwany wynik gracza A przeciwko graczowi B w przedziale (0.0, 1.0).
  static double expectedScore(int playerElo, int opponentElo) {
    final exponent = (opponentElo - playerElo) / 400.0;
    return 1.0 / (1.0 + math.pow(10.0, exponent));
  }

  /// Dobiera współczynnik K zależnie od dywizji i liczby rozegranych meczów.
  static int resolveKFactor({
    required int currentElo,
    required int matchesPlayed,
  }) {
    if (matchesPlayed < provisionalMatchThreshold) {
      return provisionalKFactor;
    }
    return EloDivisionTier.fromElo(currentElo).kFactor;
  }

  /// Oblicza zmianę ELO dla pojedynku 1v1 (np. wyścigu z duchem lub H2H).
  /// `actualScore`: 1.0 = wygrana, 0.5 = remis, 0.0 = przegrana.
  static int calculateHeadToHeadDelta({
    required int playerElo,
    required int opponentElo,
    required double actualScore,
    required int matchesPlayed,
    double multiplier = 1.0,
  }) {
    final clampedScore = actualScore.clamp(0.0, 1.0);
    final expected = expectedScore(playerElo, opponentElo);
    final k = resolveKFactor(
      currentElo: playerElo,
      matchesPlayed: matchesPlayed,
    );
    final rawDelta = k * multiplier * (clampedScore - expected);
    return rawDelta.round();
  }

  /// Oblicza zmiany ELO dla całej stawki N uczestników posortowanych od 1. do N. miejsca.
  /// Wykorzystuje porównania parami znormalizowane przez (N - 1), co zachowuje stabilność skali.
  static List<int> calculateMultiPlayerStageDeltas({
    required List<int> orderedRatings,
    int? kFactorOverride,
  }) {
    final count = orderedRatings.length;
    if (count <= 1) return List<int>.filled(count, 0);

    final deltas = List<int>.filled(count, 0);
    final pairNormalizer = count - 1;

    for (var i = 0; i < count; i++) {
      final ratingI = orderedRatings[i];
      var expectedSum = 0.0;
      var actualSum = 0.0;

      for (var j = 0; j < count; j++) {
        if (i == j) continue;
        expectedSum += expectedScore(ratingI, orderedRatings[j]);
        if (i < j) {
          actualSum += 1.0;
        }
      }

      final k = kFactorOverride ?? EloDivisionTier.fromElo(ratingI).kFactor;
      final normalizedDelta = k * ((actualSum - expectedSum) / pairNormalizer);
      deltas[i] = normalizedDelta.round();
    }

    return deltas;
  }
}

/// Zasady punktacji, budżetu i weryfikacji ligi wieloosobowej.
class LeagueScoringRules {
  static const List<int> defaultPointsTable = [
    25,
    18,
    15,
    12,
    10,
    8,
    6,
    4,
    2,
    1,
  ];

  final List<int> pointsByPlacement;
  final int komBonusPoints;
  final int sprintBonusPoints;
  final int maxTeamBudgetEur;
  final int maxRosterSize;
  final bool enforceIdenticalWeather;

  const LeagueScoringRules({
    this.pointsByPlacement = defaultPointsTable,
    this.komBonusPoints = 5,
    this.sprintBonusPoints = 5,
    this.maxTeamBudgetEur = 15000000,
    this.maxRosterSize = 8,
    this.enforceIdenticalWeather = true,
  });

  int pointsForPlacement(int placement) {
    if (placement < 1 || placement > pointsByPlacement.length) return 0;
    return pointsByPlacement[placement - 1];
  }

  LeagueScoringRules copyWith({
    List<int>? pointsByPlacement,
    int? komBonusPoints,
    int? sprintBonusPoints,
    int? maxTeamBudgetEur,
    int? maxRosterSize,
    bool? enforceIdenticalWeather,
  }) {
    return LeagueScoringRules(
      pointsByPlacement: pointsByPlacement ?? this.pointsByPlacement,
      komBonusPoints: komBonusPoints ?? this.komBonusPoints,
      sprintBonusPoints: sprintBonusPoints ?? this.sprintBonusPoints,
      maxTeamBudgetEur: maxTeamBudgetEur ?? this.maxTeamBudgetEur,
      maxRosterSize: maxRosterSize ?? this.maxRosterSize,
      enforceIdenticalWeather:
          enforceIdenticalWeather ?? this.enforceIdenticalWeather,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointsByPlacement': pointsByPlacement,
      'komBonusPoints': komBonusPoints,
      'sprintBonusPoints': sprintBonusPoints,
      'maxTeamBudgetEur': maxTeamBudgetEur,
      'maxRosterSize': maxRosterSize,
      'enforceIdenticalWeather': enforceIdenticalWeather,
    };
  }

  factory LeagueScoringRules.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['pointsByPlacement'] as List<dynamic>?;
    return LeagueScoringRules(
      pointsByPlacement: rawPoints != null && rawPoints.isNotEmpty
          ? rawPoints.map((e) => (e as num).toInt()).toList(growable: false)
          : defaultPointsTable,
      komBonusPoints: (json['komBonusPoints'] as num?)?.toInt() ?? 5,
      sprintBonusPoints: (json['sprintBonusPoints'] as num?)?.toInt() ?? 5,
      maxTeamBudgetEur:
          (json['maxTeamBudgetEur'] as num?)?.toInt() ?? 15000000,
      maxRosterSize: math.max(1, (json['maxRosterSize'] as num?)?.toInt() ?? 8),
      enforceIdenticalWeather: json['enforceIdenticalWeather'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeagueScoringRules &&
        _listEquals(other.pointsByPlacement, pointsByPlacement) &&
        other.komBonusPoints == komBonusPoints &&
        other.sprintBonusPoints == sprintBonusPoints &&
        other.maxTeamBudgetEur == maxTeamBudgetEur &&
        other.maxRosterSize == maxRosterSize &&
        other.enforceIdenticalWeather == enforceIdenticalWeather;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(pointsByPlacement),
        komBonusPoints,
        sprintBonusPoints,
        maxTeamBudgetEur,
        maxRosterSize,
        enforceIdenticalWeather,
      );
}

/// Wpis uczestnika (menedżera) w lidze wieloosobowej online.
class LeagueParticipantEntry {
  final String participantId;
  final String displayName;
  final String teamName;
  final String teamBadgeHex;
  final int eloAtJoin;
  final int currentElo;
  final LeagueMemberRole role;
  final int totalPoints;
  final int stageWins;
  final int podiumCount;
  final double totalGcTimeSeconds;
  final List<String> draftedRiderIds;
  final bool isReady;
  final DateTime joinedAt;
  final DateTime? lastSyncedAt;

  const LeagueParticipantEntry({
    required this.participantId,
    required this.displayName,
    required this.teamName,
    this.teamBadgeHex = '#8E4A49',
    this.eloAtJoin = EloCalculator.defaultStartingElo,
    this.currentElo = EloCalculator.defaultStartingElo,
    this.role = LeagueMemberRole.participant,
    this.totalPoints = 0,
    this.stageWins = 0,
    this.podiumCount = 0,
    this.totalGcTimeSeconds = 0.0,
    this.draftedRiderIds = const [],
    this.isReady = false,
    required this.joinedAt,
    this.lastSyncedAt,
  });

  EloDivisionTier get eloTier => EloDivisionTier.fromElo(currentElo);

  LeagueParticipantEntry copyWith({
    String? participantId,
    String? displayName,
    String? teamName,
    String? teamBadgeHex,
    int? eloAtJoin,
    int? currentElo,
    LeagueMemberRole? role,
    int? totalPoints,
    int? stageWins,
    int? podiumCount,
    double? totalGcTimeSeconds,
    List<String>? draftedRiderIds,
    bool? isReady,
    DateTime? joinedAt,
    DateTime? lastSyncedAt,
  }) {
    return LeagueParticipantEntry(
      participantId: participantId ?? this.participantId,
      displayName: displayName ?? this.displayName,
      teamName: teamName ?? this.teamName,
      teamBadgeHex: teamBadgeHex ?? this.teamBadgeHex,
      eloAtJoin: eloAtJoin ?? this.eloAtJoin,
      currentElo: currentElo ?? this.currentElo,
      role: role ?? this.role,
      totalPoints: totalPoints ?? this.totalPoints,
      stageWins: stageWins ?? this.stageWins,
      podiumCount: podiumCount ?? this.podiumCount,
      totalGcTimeSeconds: totalGcTimeSeconds ?? this.totalGcTimeSeconds,
      draftedRiderIds: draftedRiderIds ?? this.draftedRiderIds,
      isReady: isReady ?? this.isReady,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'displayName': displayName,
      'teamName': teamName,
      'teamBadgeHex': teamBadgeHex,
      'eloAtJoin': eloAtJoin,
      'currentElo': currentElo,
      'role': role.toJson(),
      'totalPoints': totalPoints,
      'stageWins': stageWins,
      'podiumCount': podiumCount,
      'totalGcTimeSeconds': totalGcTimeSeconds,
      'draftedRiderIds': draftedRiderIds,
      'isReady': isReady,
      'joinedAt': joinedAt.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  factory LeagueParticipantEntry.fromJson(Map<String, dynamic> json) {
    final rawDrafted = json['draftedRiderIds'] as List<dynamic>? ?? const [];
    return LeagueParticipantEntry(
      participantId: json['participantId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Menedżer',
      teamName: json['teamName'] as String? ?? 'Pro Cycling Team',
      teamBadgeHex: json['teamBadgeHex'] as String? ?? '#8E4A49',
      eloAtJoin: (json['eloAtJoin'] as num?)?.toInt() ??
          EloCalculator.defaultStartingElo,
      currentElo: (json['currentElo'] as num?)?.toInt() ??
          EloCalculator.defaultStartingElo,
      role: LeagueMemberRole.fromJson(json['role'] as String? ?? 'participant'),
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      stageWins: (json['stageWins'] as num?)?.toInt() ?? 0,
      podiumCount: (json['podiumCount'] as num?)?.toInt() ?? 0,
      totalGcTimeSeconds:
          (json['totalGcTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      draftedRiderIds: rawDrafted.map((e) => e.toString()).toList(),
      isReady: json['isReady'] as bool? ?? false,
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeagueParticipantEntry &&
        other.participantId == participantId &&
        other.displayName == displayName &&
        other.teamName == teamName &&
        other.teamBadgeHex == teamBadgeHex &&
        other.eloAtJoin == eloAtJoin &&
        other.currentElo == currentElo &&
        other.role == role &&
        other.totalPoints == totalPoints &&
        other.stageWins == stageWins &&
        other.podiumCount == podiumCount &&
        other.totalGcTimeSeconds == totalGcTimeSeconds &&
        _listEquals(other.draftedRiderIds, draftedRiderIds) &&
        other.isReady == isReady &&
        other.joinedAt == joinedAt &&
        other.lastSyncedAt == lastSyncedAt;
  }

  @override
  int get hashCode => Object.hash(
        participantId,
        displayName,
        teamName,
        teamBadgeHex,
        eloAtJoin,
        currentElo,
        role,
        totalPoints,
        stageWins,
        podiumCount,
        totalGcTimeSeconds,
        Object.hashAll(draftedRiderIds),
        isReady,
        joinedAt,
        lastSyncedAt,
      );
}

/// Wynik pojedynczego menedżera na etapie ligi online.
class LeagueStageResultEntry {
  final String participantId;
  final double finishTimeSeconds;
  final double gapToWinnerSeconds;
  final double averageWatts;
  final double normalizedPower;
  final double averageSpeedKmh;
  final int pointsEarned;
  final String weatherHash;
  final String verificationChecksum;
  final DateTime submittedAt;

  const LeagueStageResultEntry({
    required this.participantId,
    required this.finishTimeSeconds,
    this.gapToWinnerSeconds = 0.0,
    required this.averageWatts,
    required this.normalizedPower,
    required this.averageSpeedKmh,
    this.pointsEarned = 0,
    required this.weatherHash,
    this.verificationChecksum = '',
    required this.submittedAt,
  });

  LeagueStageResultEntry copyWith({
    String? participantId,
    double? finishTimeSeconds,
    double? gapToWinnerSeconds,
    double? averageWatts,
    double? normalizedPower,
    double? averageSpeedKmh,
    int? pointsEarned,
    String? weatherHash,
    String? verificationChecksum,
    DateTime? submittedAt,
  }) {
    return LeagueStageResultEntry(
      participantId: participantId ?? this.participantId,
      finishTimeSeconds: finishTimeSeconds ?? this.finishTimeSeconds,
      gapToWinnerSeconds: gapToWinnerSeconds ?? this.gapToWinnerSeconds,
      averageWatts: averageWatts ?? this.averageWatts,
      normalizedPower: normalizedPower ?? this.normalizedPower,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      weatherHash: weatherHash ?? this.weatherHash,
      verificationChecksum: verificationChecksum ?? this.verificationChecksum,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'finishTimeSeconds': finishTimeSeconds,
      'gapToWinnerSeconds': gapToWinnerSeconds,
      'averageWatts': averageWatts,
      'normalizedPower': normalizedPower,
      'averageSpeedKmh': averageSpeedKmh,
      'pointsEarned': pointsEarned,
      'weatherHash': weatherHash,
      'verificationChecksum': verificationChecksum,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory LeagueStageResultEntry.fromJson(Map<String, dynamic> json) {
    return LeagueStageResultEntry(
      participantId: json['participantId'] as String? ?? '',
      finishTimeSeconds:
          (json['finishTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      gapToWinnerSeconds:
          (json['gapToWinnerSeconds'] as num?)?.toDouble() ?? 0.0,
      averageWatts: (json['averageWatts'] as num?)?.toDouble() ?? 0.0,
      normalizedPower: (json['normalizedPower'] as num?)?.toDouble() ?? 0.0,
      averageSpeedKmh: (json['averageSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      weatherHash: json['weatherHash'] as String? ?? '',
      verificationChecksum: json['verificationChecksum'] as String? ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeagueStageResultEntry &&
        other.participantId == participantId &&
        other.finishTimeSeconds == finishTimeSeconds &&
        other.gapToWinnerSeconds == gapToWinnerSeconds &&
        other.averageWatts == averageWatts &&
        other.normalizedPower == normalizedPower &&
        other.averageSpeedKmh == averageSpeedKmh &&
        other.pointsEarned == pointsEarned &&
        other.weatherHash == weatherHash &&
        other.verificationChecksum == verificationChecksum &&
        other.submittedAt == submittedAt;
  }

  @override
  int get hashCode => Object.hash(
        participantId,
        finishTimeSeconds,
        gapToWinnerSeconds,
        averageWatts,
        normalizedPower,
        averageSpeedKmh,
        pointsEarned,
        weatherHash,
        verificationChecksum,
        submittedAt,
      );
}

/// Harmonogram i zamrożona pogoda pojedynczego etapu w lidze online.
class LeagueStageScheduleEntry {
  final int stageIndex;
  final String stageId;
  final String stageName;
  final double distanceKm;
  final double elevationGainM;
  final WeatherConditionSnapshot lockedWeather;
  final DateTime opensAt;
  final DateTime closesAt;
  final List<LeagueStageResultEntry> results;

  const LeagueStageScheduleEntry({
    required this.stageIndex,
    required this.stageId,
    required this.stageName,
    required this.distanceKm,
    required this.elevationGainM,
    required this.lockedWeather,
    required this.opensAt,
    required this.closesAt,
    this.results = const [],
  });

  List<LeagueStageResultEntry> get sortedResults {
    final sorted = List<LeagueStageResultEntry>.from(results);
    sorted.sort((a, b) => a.finishTimeSeconds.compareTo(b.finishTimeSeconds));
    return sorted;
  }

  bool hasParticipantSubmitted(String participantId) {
    return results.any((r) => r.participantId == participantId);
  }

  bool isAllSubmitted(int expectedParticipantCount) {
    return expectedParticipantCount > 0 &&
        results.length >= expectedParticipantCount;
  }

  /// Zapisuje lub aktualizuje wynik uczestnika i przelicza straty czasowe oraz punkty.
  LeagueStageScheduleEntry submitResult(
    LeagueStageResultEntry entry, {
    required LeagueScoringRules scoringRules,
  }) {
    if (scoringRules.enforceIdenticalWeather &&
        entry.weatherHash.isNotEmpty &&
        entry.weatherHash != lockedWeather.weatherHash) {
      throw ArgumentError(
        'Niezgodność pogody etapu $stageIndex: oczekiwano ${lockedWeather.weatherHash}, otrzymano ${entry.weatherHash}.',
      );
    }

    final filtered = results
        .where((r) => r.participantId != entry.participantId)
        .toList(growable: true)
      ..add(entry);
    filtered.sort((a, b) => a.finishTimeSeconds.compareTo(b.finishTimeSeconds));

    final bestTime = filtered.first.finishTimeSeconds;
    final recalculated = <LeagueStageResultEntry>[];
    for (var i = 0; i < filtered.length; i++) {
      final item = filtered[i];
      recalculated.add(
        item.copyWith(
          gapToWinnerSeconds: math.max(0.0, item.finishTimeSeconds - bestTime),
          pointsEarned: scoringRules.pointsForPlacement(i + 1),
        ),
      );
    }

    return copyWith(results: recalculated);
  }

  LeagueStageScheduleEntry copyWith({
    int? stageIndex,
    String? stageId,
    String? stageName,
    double? distanceKm,
    double? elevationGainM,
    WeatherConditionSnapshot? lockedWeather,
    DateTime? opensAt,
    DateTime? closesAt,
    List<LeagueStageResultEntry>? results,
  }) {
    return LeagueStageScheduleEntry(
      stageIndex: stageIndex ?? this.stageIndex,
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      lockedWeather: lockedWeather ?? this.lockedWeather,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      results: results ?? this.results,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageIndex': stageIndex,
      'stageId': stageId,
      'stageName': stageName,
      'distanceKm': distanceKm,
      'elevationGainM': elevationGainM,
      'lockedWeather': lockedWeather.toJson(),
      'opensAt': opensAt.toIso8601String(),
      'closesAt': closesAt.toIso8601String(),
      'results': results.map((e) => e.toJson()).toList(),
    };
  }

  factory LeagueStageScheduleEntry.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    return LeagueStageScheduleEntry(
      stageIndex: (json['stageIndex'] as num?)?.toInt() ?? 1,
      stageId: json['stageId'] as String? ?? '',
      stageName: json['stageName'] as String? ?? 'Etap Ligowy',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 150.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 1200.0,
      lockedWeather: WeatherConditionSnapshot.fromJson(
        json['lockedWeather'] as Map<String, dynamic>? ?? const {},
      ),
      opensAt: DateTime.tryParse(json['opensAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      closesAt: DateTime.tryParse(json['closesAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      results: rawResults
          .whereType<Map<String, dynamic>>()
          .map(LeagueStageResultEntry.fromJson)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeagueStageScheduleEntry &&
        other.stageIndex == stageIndex &&
        other.stageId == stageId &&
        other.stageName == stageName &&
        other.distanceKm == distanceKm &&
        other.elevationGainM == elevationGainM &&
        other.lockedWeather == lockedWeather &&
        other.opensAt == opensAt &&
        other.closesAt == closesAt &&
        _listEquals(other.results, results);
  }

  @override
  int get hashCode => Object.hash(
        stageIndex,
        stageId,
        stageName,
        distanceKm,
        elevationGainM,
        lockedWeather,
        opensAt,
        closesAt,
        Object.hashAll(results),
      );
}

/// Główny model ligi wieloosobowej Online (`OnlineLeagueModel`).
class OnlineLeagueModel {
  final String leagueId;
  final String name;
  final String description;
  final LeagueFormat format;
  final LeaguePrivacy privacy;
  final LeagueStatus status;
  final String inviteCode;
  final int seasonNumber;
  final int maxParticipants;
  final DateTime createdAt;
  final DateTime startsAt;
  final DateTime endsAt;
  final LeagueScoringRules scoringRules;
  final LeagueDraftStatus draftStatus;
  final List<LeagueParticipantEntry> participants;
  final List<LeagueStageScheduleEntry> schedule;

  const OnlineLeagueModel({
    required this.leagueId,
    required this.name,
    this.description = '',
    this.format = LeagueFormat.seasonPoints,
    this.privacy = LeaguePrivacy.publicRanked,
    this.status = LeagueStatus.recruiting,
    this.inviteCode = '',
    this.seasonNumber = 1,
    this.maxParticipants = 16,
    required this.createdAt,
    required this.startsAt,
    required this.endsAt,
    this.scoringRules = const LeagueScoringRules(),
    this.draftStatus = LeagueDraftStatus.notStarted,
    this.participants = const [],
    this.schedule = const [],
  });

  bool get isFull => participants.length >= maxParticipants;

  bool get canJoin => status.isJoinable && !isFull;

  int get completedStageCount {
    if (participants.isEmpty) return 0;
    return schedule
        .where((stage) => stage.isAllSubmitted(participants.length))
        .length;
  }

  double get completionProgress {
    if (schedule.isEmpty) return 0.0;
    return (completedStageCount / schedule.length).clamp(0.0, 1.0);
  }

  /// Aktualnie otwarty lub pierwszy nieukończony etap ligi.
  LeagueStageScheduleEntry? get activeStage {
    if (schedule.isEmpty) return null;
    for (final stage in schedule) {
      if (!stage.isAllSubmitted(math.max(1, participants.length))) {
        return stage;
      }
    }
    return schedule.last;
  }

  /// Tabela ligowa posortowana wg punktów, zwycięstw etapowych, czasu GC i ELO.
  List<LeagueParticipantEntry> get sortedStandings {
    final sorted = List<LeagueParticipantEntry>.from(participants);
    sorted.sort((a, b) {
      final ptsCmp = b.totalPoints.compareTo(a.totalPoints);
      if (ptsCmp != 0) return ptsCmp;
      final winsCmp = b.stageWins.compareTo(a.stageWins);
      if (winsCmp != 0) return winsCmp;
      if (format == LeagueFormat.grandTourCup &&
          a.totalGcTimeSeconds > 0 &&
          b.totalGcTimeSeconds > 0) {
        final gcCmp = a.totalGcTimeSeconds.compareTo(b.totalGcTimeSeconds);
        if (gcCmp != 0) return gcCmp;
      }
      return b.currentElo.compareTo(a.currentElo);
    });
    return sorted;
  }

  LeagueParticipantEntry? getParticipantById(String participantId) {
    for (final p in participants) {
      if (p.participantId == participantId) return p;
    }
    return null;
  }

  OnlineLeagueModel addParticipant(LeagueParticipantEntry entry) {
    if (isFull) {
      throw StateError('Liga $name osiągnęła limit $maxParticipants graczy.');
    }
    if (getParticipantById(entry.participantId) != null) {
      return this;
    }
    return copyWith(participants: [...participants, entry]);
  }

  /// Rejestruje wynik etapu i przelicza klasyfikację generalną ligi.
  OnlineLeagueModel recordStageResult(
    int stageIndex,
    LeagueStageResultEntry result,
  ) {
    final updatedSchedule = schedule.map((stage) {
      if (stage.stageIndex != stageIndex) return stage;
      return stage.submitResult(result, scoringRules: scoringRules);
    }).toList(growable: false);

    final updatedParticipants = _recalculateStandings(
      participants: participants,
      schedule: updatedSchedule,
    );

    return copyWith(
      schedule: updatedSchedule,
      participants: updatedParticipants,
    );
  }

  List<LeagueParticipantEntry> _recalculateStandings({
    required List<LeagueParticipantEntry> participants,
    required List<LeagueStageScheduleEntry> schedule,
  }) {
    final pointsMap = <String, int>{};
    final winsMap = <String, int>{};
    final podiumsMap = <String, int>{};
    final gcTimeMap = <String, double>{};

    for (final stage in schedule) {
      final sorted = stage.sortedResults;
      for (var i = 0; i < sorted.length; i++) {
        final res = sorted[i];
        final pid = res.participantId;
        pointsMap[pid] = (pointsMap[pid] ?? 0) + res.pointsEarned;
        gcTimeMap[pid] = (gcTimeMap[pid] ?? 0.0) + res.finishTimeSeconds;
        if (i == 0) {
          winsMap[pid] = (winsMap[pid] ?? 0) + 1;
        }
        if (i < 3) {
          podiumsMap[pid] = (podiumsMap[pid] ?? 0) + 1;
        }
      }
    }

    return participants
        .map(
          (p) => p.copyWith(
            totalPoints: pointsMap[p.participantId] ?? 0,
            stageWins: winsMap[p.participantId] ?? 0,
            podiumCount: podiumsMap[p.participantId] ?? 0,
            totalGcTimeSeconds: gcTimeMap[p.participantId] ?? 0.0,
          ),
        )
        .toList(growable: false);
  }

  OnlineLeagueModel copyWith({
    String? leagueId,
    String? name,
    String? description,
    LeagueFormat? format,
    LeaguePrivacy? privacy,
    LeagueStatus? status,
    String? inviteCode,
    int? seasonNumber,
    int? maxParticipants,
    DateTime? createdAt,
    DateTime? startsAt,
    DateTime? endsAt,
    LeagueScoringRules? scoringRules,
    LeagueDraftStatus? draftStatus,
    List<LeagueParticipantEntry>? participants,
    List<LeagueStageScheduleEntry>? schedule,
  }) {
    return OnlineLeagueModel(
      leagueId: leagueId ?? this.leagueId,
      name: name ?? this.name,
      description: description ?? this.description,
      format: format ?? this.format,
      privacy: privacy ?? this.privacy,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      createdAt: createdAt ?? this.createdAt,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      scoringRules: scoringRules ?? this.scoringRules,
      draftStatus: draftStatus ?? this.draftStatus,
      participants: participants ?? this.participants,
      schedule: schedule ?? this.schedule,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leagueId': leagueId,
      'name': name,
      'description': description,
      'format': format.toJson(),
      'privacy': privacy.toJson(),
      'status': status.toJson(),
      'inviteCode': inviteCode,
      'seasonNumber': seasonNumber,
      'maxParticipants': maxParticipants,
      'createdAt': createdAt.toIso8601String(),
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'scoringRules': scoringRules.toJson(),
      'draftStatus': draftStatus.toJson(),
      'participants': participants.map((e) => e.toJson()).toList(),
      'schedule': schedule.map((e) => e.toJson()).toList(),
    };
  }

  factory OnlineLeagueModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List<dynamic>? ?? const [];
    final rawSchedule = json['schedule'] as List<dynamic>? ?? const [];
    return OnlineLeagueModel(
      leagueId: json['leagueId'] as String? ?? '',
      name: json['name'] as String? ?? 'Liga Online',
      description: json['description'] as String? ?? '',
      format: LeagueFormat.fromJson(json['format'] as String? ?? 'seasonPoints'),
      privacy:
          LeaguePrivacy.fromJson(json['privacy'] as String? ?? 'publicRanked'),
      status: LeagueStatus.fromJson(json['status'] as String? ?? 'recruiting'),
      inviteCode: json['inviteCode'] as String? ?? '',
      seasonNumber: math.max(1, (json['seasonNumber'] as num?)?.toInt() ?? 1),
      maxParticipants:
          math.max(2, (json['maxParticipants'] as num?)?.toInt() ?? 16),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      startsAt: DateTime.tryParse(json['startsAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      endsAt: DateTime.tryParse(json['endsAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      scoringRules: LeagueScoringRules.fromJson(
        json['scoringRules'] as Map<String, dynamic>? ?? const {},
      ),
      draftStatus: LeagueDraftStatus.fromJson(
        json['draftStatus'] as String? ?? 'notStarted',
      ),
      participants: rawParticipants
          .whereType<Map<String, dynamic>>()
          .map(LeagueParticipantEntry.fromJson)
          .toList(growable: false),
      schedule: rawSchedule
          .whereType<Map<String, dynamic>>()
          .map(LeagueStageScheduleEntry.fromJson)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnlineLeagueModel &&
        other.leagueId == leagueId &&
        other.name == name &&
        other.description == description &&
        other.format == format &&
        other.privacy == privacy &&
        other.status == status &&
        other.inviteCode == inviteCode &&
        other.seasonNumber == seasonNumber &&
        other.maxParticipants == maxParticipants &&
        other.createdAt == createdAt &&
        other.startsAt == startsAt &&
        other.endsAt == endsAt &&
        other.scoringRules == scoringRules &&
        other.draftStatus == draftStatus &&
        _listEquals(other.participants, participants) &&
        _listEquals(other.schedule, schedule);
  }

  @override
  int get hashCode => Object.hash(
        leagueId,
        name,
        description,
        format,
        privacy,
        status,
        inviteCode,
        seasonNumber,
        maxParticipants,
        createdAt,
        startsAt,
        endsAt,
        scoringRules,
        draftStatus,
        Object.hashAll(participants),
        Object.hashAll(schedule),
      );
}

/// Próbka telemetrii ducha do odtwarzania przejazdu asynchronicznego w 3D i na wykresach.
class GhostTelemetrySample {
  final double elapsedSeconds;
  final double distanceKm;
  final double speedKmh;
  final double powerWatts;
  final int heartRateBpm;
  final int cadenceRpm;
  final double elevationM;
  final double gradientPercent;
  final double lateralOffsetM;

  const GhostTelemetrySample({
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.speedKmh,
    required this.powerWatts,
    this.heartRateBpm = 160,
    this.cadenceRpm = 90,
    this.elevationM = 0.0,
    this.gradientPercent = 0.0,
    this.lateralOffsetM = 0.0,
  });

  GhostTelemetrySample copyWith({
    double? elapsedSeconds,
    double? distanceKm,
    double? speedKmh,
    double? powerWatts,
    int? heartRateBpm,
    int? cadenceRpm,
    double? elevationM,
    double? gradientPercent,
    double? lateralOffsetM,
  }) {
    return GhostTelemetrySample(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      speedKmh: speedKmh ?? this.speedKmh,
      powerWatts: powerWatts ?? this.powerWatts,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      elevationM: elevationM ?? this.elevationM,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      lateralOffsetM: lateralOffsetM ?? this.lateralOffsetM,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'elapsedSeconds': elapsedSeconds,
      'distanceKm': distanceKm,
      'speedKmh': speedKmh,
      'powerWatts': powerWatts,
      'heartRateBpm': heartRateBpm,
      'cadenceRpm': cadenceRpm,
      'elevationM': elevationM,
      'gradientPercent': gradientPercent,
      'lateralOffsetM': lateralOffsetM,
    };
  }

  factory GhostTelemetrySample.fromJson(Map<String, dynamic> json) {
    return GhostTelemetrySample(
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 0.0,
      powerWatts: (json['powerWatts'] as num?)?.toDouble() ?? 0.0,
      heartRateBpm: (json['heartRateBpm'] as num?)?.toInt() ?? 160,
      cadenceRpm: (json['cadenceRpm'] as num?)?.toInt() ?? 90,
      elevationM: (json['elevationM'] as num?)?.toDouble() ?? 0.0,
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      lateralOffsetM: (json['lateralOffsetM'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GhostTelemetrySample &&
        other.elapsedSeconds == elapsedSeconds &&
        other.distanceKm == distanceKm &&
        other.speedKmh == speedKmh &&
        other.powerWatts == powerWatts &&
        other.heartRateBpm == heartRateBpm &&
        other.cadenceRpm == cadenceRpm &&
        other.elevationM == elevationM &&
        other.gradientPercent == gradientPercent &&
        other.lateralOffsetM == lateralOffsetM;
  }

  @override
  int get hashCode => Object.hash(
        elapsedSeconds,
        distanceKm,
        speedKmh,
        powerWatts,
        heartRateBpm,
        cadenceRpm,
        elevationM,
        gradientPercent,
        lateralOffsetM,
      );
}

/// Wynik pojedynczej próby podjęcia asynchronicznego wyzwania ducha.
class GhostAttemptResult {
  final String attemptId;
  final String challengerId;
  final String challengerName;
  final double finishTimeSeconds;
  final double averageWatts;
  final double normalizedPower;
  final double maxSpeedKmh;
  final String weatherHash;
  final List<GhostTelemetrySample> telemetrySamples;
  final double deltaVsTargetSeconds;
  final bool isVictory;
  final DateTime completedAt;

  const GhostAttemptResult({
    required this.attemptId,
    required this.challengerId,
    required this.challengerName,
    required this.finishTimeSeconds,
    required this.averageWatts,
    required this.normalizedPower,
    required this.maxSpeedKmh,
    required this.weatherHash,
    this.telemetrySamples = const [],
    required this.deltaVsTargetSeconds,
    required this.isVictory,
    required this.completedAt,
  });

  GhostAttemptResult copyWith({
    String? attemptId,
    String? challengerId,
    String? challengerName,
    double? finishTimeSeconds,
    double? averageWatts,
    double? normalizedPower,
    double? maxSpeedKmh,
    String? weatherHash,
    List<GhostTelemetrySample>? telemetrySamples,
    double? deltaVsTargetSeconds,
    bool? isVictory,
    DateTime? completedAt,
  }) {
    return GhostAttemptResult(
      attemptId: attemptId ?? this.attemptId,
      challengerId: challengerId ?? this.challengerId,
      challengerName: challengerName ?? this.challengerName,
      finishTimeSeconds: finishTimeSeconds ?? this.finishTimeSeconds,
      averageWatts: averageWatts ?? this.averageWatts,
      normalizedPower: normalizedPower ?? this.normalizedPower,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      weatherHash: weatherHash ?? this.weatherHash,
      telemetrySamples: telemetrySamples ?? this.telemetrySamples,
      deltaVsTargetSeconds: deltaVsTargetSeconds ?? this.deltaVsTargetSeconds,
      isVictory: isVictory ?? this.isVictory,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'challengerId': challengerId,
      'challengerName': challengerName,
      'finishTimeSeconds': finishTimeSeconds,
      'averageWatts': averageWatts,
      'normalizedPower': normalizedPower,
      'maxSpeedKmh': maxSpeedKmh,
      'weatherHash': weatherHash,
      'telemetrySamples': telemetrySamples.map((e) => e.toJson()).toList(),
      'deltaVsTargetSeconds': deltaVsTargetSeconds,
      'isVictory': isVictory,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory GhostAttemptResult.fromJson(Map<String, dynamic> json) {
    final rawSamples = json['telemetrySamples'] as List<dynamic>? ?? const [];
    return GhostAttemptResult(
      attemptId: json['attemptId'] as String? ?? '',
      challengerId: json['challengerId'] as String? ?? '',
      challengerName: json['challengerName'] as String? ?? 'Challenger',
      finishTimeSeconds:
          (json['finishTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      averageWatts: (json['averageWatts'] as num?)?.toDouble() ?? 0.0,
      normalizedPower: (json['normalizedPower'] as num?)?.toDouble() ?? 0.0,
      maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      weatherHash: json['weatherHash'] as String? ?? '',
      telemetrySamples: rawSamples
          .whereType<Map<String, dynamic>>()
          .map(GhostTelemetrySample.fromJson)
          .toList(growable: false),
      deltaVsTargetSeconds:
          (json['deltaVsTargetSeconds'] as num?)?.toDouble() ?? 0.0,
      isVictory: json['isVictory'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GhostAttemptResult &&
        other.attemptId == attemptId &&
        other.challengerId == challengerId &&
        other.challengerName == challengerName &&
        other.finishTimeSeconds == finishTimeSeconds &&
        other.averageWatts == averageWatts &&
        other.normalizedPower == normalizedPower &&
        other.maxSpeedKmh == maxSpeedKmh &&
        other.weatherHash == weatherHash &&
        _listEquals(other.telemetrySamples, telemetrySamples) &&
        other.deltaVsTargetSeconds == deltaVsTargetSeconds &&
        other.isVictory == isVictory &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(
        attemptId,
        challengerId,
        challengerName,
        finishTimeSeconds,
        averageWatts,
        normalizedPower,
        maxSpeedKmh,
        weatherHash,
        Object.hashAll(telemetrySamples),
        deltaVsTargetSeconds,
        isVictory,
        completedAt,
      );
}

/// Asynchroniczne wyzwanie ducha na identycznych warunkach pogodowych (`weatherSnapshot`).
class GhostChallengeModel {
  final String challengeId;
  final String title;
  final String creatorId;
  final String creatorName;
  final String stageId;
  final String stageName;
  final double distanceKm;
  final double elevationGainM;
  final WeatherConditionSnapshot weatherSnapshot;
  final double targetFinishTimeSeconds;
  final double targetAverageWatts;
  final List<GhostTelemetrySample> targetTelemetry;
  final GhostChallengeDifficulty difficulty;
  final GhostChallengeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int eloStake;
  final List<GhostAttemptResult> attempts;

  const GhostChallengeModel({
    required this.challengeId,
    required this.title,
    required this.creatorId,
    required this.creatorName,
    required this.stageId,
    required this.stageName,
    required this.distanceKm,
    required this.elevationGainM,
    required this.weatherSnapshot,
    required this.targetFinishTimeSeconds,
    required this.targetAverageWatts,
    this.targetTelemetry = const [],
    this.difficulty = GhostChallengeDifficulty.competitive,
    this.status = GhostChallengeStatus.open,
    required this.createdAt,
    required this.expiresAt,
    this.eloStake = 24,
    this.attempts = const [],
  });

  bool isExpiredAt(DateTime now) => now.isAfter(expiresAt);

  /// Weryfikuje 100% zgodność warunków pogodowych z wyzwaniem.
  bool verifyWeatherParity(WeatherConditionSnapshot attemptWeather) {
    return weatherSnapshot.isIdenticalTo(attemptWeather);
  }

  /// Najlepsza próba spośród dotychczasowych podejść.
  GhostAttemptResult? get bestAttempt {
    if (attempts.isEmpty) return null;
    var best = attempts.first;
    for (final attempt in attempts.skip(1)) {
      if (attempt.finishTimeSeconds < best.finishTimeSeconds) {
        best = attempt;
      }
    }
    return best;
  }

  /// Interpoluje pozycję i telemetrię ducha dla podanego czasu `elapsedSeconds`.
  GhostTelemetrySample? interpolateGhostAtTime(double elapsedSeconds) {
    if (targetTelemetry.isEmpty) return null;
    if (elapsedSeconds <= targetTelemetry.first.elapsedSeconds) {
      return targetTelemetry.first;
    }
    if (elapsedSeconds >= targetTelemetry.last.elapsedSeconds) {
      return targetTelemetry.last;
    }

    for (var i = 0; i < targetTelemetry.length - 1; i++) {
      final a = targetTelemetry[i];
      final b = targetTelemetry[i + 1];
      if (elapsedSeconds >= a.elapsedSeconds &&
          elapsedSeconds <= b.elapsedSeconds) {
        final span = b.elapsedSeconds - a.elapsedSeconds;
        final t = span <= 0 ? 0.0 : (elapsedSeconds - a.elapsedSeconds) / span;
        return _lerpSample(a, b, t);
      }
    }
    return targetTelemetry.last;
  }

  /// Interpoluje pozycję i telemetrię ducha dla podanego dystansu `distanceKm`.
  GhostTelemetrySample? interpolateGhostAtDistance(double distanceKm) {
    if (targetTelemetry.isEmpty) return null;
    if (distanceKm <= targetTelemetry.first.distanceKm) {
      return targetTelemetry.first;
    }
    if (distanceKm >= targetTelemetry.last.distanceKm) {
      return targetTelemetry.last;
    }

    for (var i = 0; i < targetTelemetry.length - 1; i++) {
      final a = targetTelemetry[i];
      final b = targetTelemetry[i + 1];
      if (distanceKm >= a.distanceKm && distanceKm <= b.distanceKm) {
        final span = b.distanceKm - a.distanceKm;
        final t = span <= 0 ? 0.0 : (distanceKm - a.distanceKm) / span;
        return _lerpSample(a, b, t);
      }
    }
    return targetTelemetry.last;
  }

  /// Rejestruje próbę pobicia ducha, weryfikując identyczny skrót pogody.
  GhostChallengeModel recordAttempt(GhostAttemptResult attempt) {
    if (attempt.weatherHash != weatherSnapshot.weatherHash) {
      throw ArgumentError(
        'Próba odrzucona: warunki pogodowe (${attempt.weatherHash}) różnią się od warunków ducha (${weatherSnapshot.weatherHash}).',
      );
    }
    final nextStatus = attempt.isVictory
        ? GhostChallengeStatus.completed
        : (status == GhostChallengeStatus.open
            ? GhostChallengeStatus.accepted
            : status);
    return copyWith(
      status: nextStatus,
      attempts: [...attempts, attempt],
    );
  }

  GhostChallengeModel copyWith({
    String? challengeId,
    String? title,
    String? creatorId,
    String? creatorName,
    String? stageId,
    String? stageName,
    double? distanceKm,
    double? elevationGainM,
    WeatherConditionSnapshot? weatherSnapshot,
    double? targetFinishTimeSeconds,
    double? targetAverageWatts,
    List<GhostTelemetrySample>? targetTelemetry,
    GhostChallengeDifficulty? difficulty,
    GhostChallengeStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? eloStake,
    List<GhostAttemptResult>? attempts,
  }) {
    return GhostChallengeModel(
      challengeId: challengeId ?? this.challengeId,
      title: title ?? this.title,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      weatherSnapshot: weatherSnapshot ?? this.weatherSnapshot,
      targetFinishTimeSeconds:
          targetFinishTimeSeconds ?? this.targetFinishTimeSeconds,
      targetAverageWatts: targetAverageWatts ?? this.targetAverageWatts,
      targetTelemetry: targetTelemetry ?? this.targetTelemetry,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      eloStake: eloStake ?? this.eloStake,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'title': title,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'stageId': stageId,
      'stageName': stageName,
      'distanceKm': distanceKm,
      'elevationGainM': elevationGainM,
      'weatherSnapshot': weatherSnapshot.toJson(),
      'targetFinishTimeSeconds': targetFinishTimeSeconds,
      'targetAverageWatts': targetAverageWatts,
      'targetTelemetry': targetTelemetry.map((e) => e.toJson()).toList(),
      'difficulty': difficulty.toJson(),
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'eloStake': eloStake,
      'attempts': attempts.map((e) => e.toJson()).toList(),
    };
  }

  factory GhostChallengeModel.fromJson(Map<String, dynamic> json) {
    final rawTelemetry = json['targetTelemetry'] as List<dynamic>? ?? const [];
    final rawAttempts = json['attempts'] as List<dynamic>? ?? const [];
    return GhostChallengeModel(
      challengeId: json['challengeId'] as String? ?? '',
      title: json['title'] as String? ?? 'Wyzwanie Ducha',
      creatorId: json['creatorId'] as String? ?? '',
      creatorName: json['creatorName'] as String? ?? 'Rywal',
      stageId: json['stageId'] as String? ?? '',
      stageName: json['stageName'] as String? ?? 'Etap',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 0.0,
      weatherSnapshot: WeatherConditionSnapshot.fromJson(
        json['weatherSnapshot'] as Map<String, dynamic>? ?? const {},
      ),
      targetFinishTimeSeconds:
          (json['targetFinishTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      targetAverageWatts:
          (json['targetAverageWatts'] as num?)?.toDouble() ?? 0.0,
      targetTelemetry: rawTelemetry
          .whereType<Map<String, dynamic>>()
          .map(GhostTelemetrySample.fromJson)
          .toList(growable: false),
      difficulty: GhostChallengeDifficulty.fromJson(
        json['difficulty'] as String? ?? 'competitive',
      ),
      status: GhostChallengeStatus.fromJson(
        json['status'] as String? ?? 'open',
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      eloStake: (json['eloStake'] as num?)?.toInt() ?? 24,
      attempts: rawAttempts
          .whereType<Map<String, dynamic>>()
          .map(GhostAttemptResult.fromJson)
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GhostChallengeModel &&
        other.challengeId == challengeId &&
        other.title == title &&
        other.creatorId == creatorId &&
        other.creatorName == creatorName &&
        other.stageId == stageId &&
        other.stageName == stageName &&
        other.distanceKm == distanceKm &&
        other.elevationGainM == elevationGainM &&
        other.weatherSnapshot == weatherSnapshot &&
        other.targetFinishTimeSeconds == targetFinishTimeSeconds &&
        other.targetAverageWatts == targetAverageWatts &&
        _listEquals(other.targetTelemetry, targetTelemetry) &&
        other.difficulty == difficulty &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.eloStake == eloStake &&
        _listEquals(other.attempts, attempts);
  }

  @override
  int get hashCode => Object.hash(
        challengeId,
        title,
        creatorId,
        creatorName,
        stageId,
        stageName,
        distanceKm,
        elevationGainM,
        weatherSnapshot,
        targetFinishTimeSeconds,
        targetAverageWatts,
        Object.hashAll(targetTelemetry),
        difficulty,
        status,
        createdAt,
        expiresAt,
        eloStake,
        Object.hashAll(attempts),
      );
}

/// Kontener wymiany danych ligowych i wyzwań duchów (`.ppmleague`) z sumą kontrolną.
class MultiplayerLeaguePackage {
  static const int currentFormatVersion = 1;

  final int formatVersion;
  final DateTime exportedAt;
  final OnlineLeagueModel? league;
  final List<GhostChallengeModel> ghostChallenges;
  final EloRatingProfile? playerEloProfile;
  final String integrityChecksum;

  const MultiplayerLeaguePackage({
    this.formatVersion = currentFormatVersion,
    required this.exportedAt,
    this.league,
    this.ghostChallenges = const [],
    this.playerEloProfile,
    this.integrityChecksum = '',
  });

  String computeChecksum() {
    final payload = jsonEncode({
      'formatVersion': formatVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'league': league?.toJson(),
      'ghostChallenges': ghostChallenges.map((e) => e.toJson()).toList(),
      'playerEloProfile': playerEloProfile?.toJson(),
    });
    return _fnv1a64Hex(payload);
  }

  MultiplayerLeaguePackage withValidChecksum() {
    return MultiplayerLeaguePackage(
      formatVersion: formatVersion,
      exportedAt: exportedAt,
      league: league,
      ghostChallenges: ghostChallenges,
      playerEloProfile: playerEloProfile,
      integrityChecksum: computeChecksum(),
    );
  }

  bool get isChecksumValid =>
      integrityChecksum.isNotEmpty && integrityChecksum == computeChecksum();

  Map<String, dynamic> toJson() {
    final checksum =
        integrityChecksum.isNotEmpty ? integrityChecksum : computeChecksum();
    return {
      'formatVersion': formatVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'league': league?.toJson(),
      'ghostChallenges': ghostChallenges.map((e) => e.toJson()).toList(),
      'playerEloProfile': playerEloProfile?.toJson(),
      'integrityChecksum': checksum,
    };
  }

  factory MultiplayerLeaguePackage.fromJson(Map<String, dynamic> json) {
    final rawChallenges =
        json['ghostChallenges'] as List<dynamic>? ?? const [];
    final rawLeague = json['league'] as Map<String, dynamic>?;
    final rawElo = json['playerEloProfile'] as Map<String, dynamic>?;
    return MultiplayerLeaguePackage(
      formatVersion:
          (json['formatVersion'] as num?)?.toInt() ?? currentFormatVersion,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      league: rawLeague != null ? OnlineLeagueModel.fromJson(rawLeague) : null,
      ghostChallenges: rawChallenges
          .whereType<Map<String, dynamic>>()
          .map(GhostChallengeModel.fromJson)
          .toList(growable: false),
      playerEloProfile:
          rawElo != null ? EloRatingProfile.fromJson(rawElo) : null,
      integrityChecksum: json['integrityChecksum'] as String? ?? '',
    );
  }
}

GhostTelemetrySample _lerpSample(
  GhostTelemetrySample a,
  GhostTelemetrySample b,
  double t,
) {
  final clampedT = t.clamp(0.0, 1.0);
  double lerpDouble(double start, double end) =>
      start + (end - start) * clampedT;
  int lerpInt(int start, int end) =>
      (start + (end - start) * clampedT).round();

  return GhostTelemetrySample(
    elapsedSeconds: lerpDouble(a.elapsedSeconds, b.elapsedSeconds),
    distanceKm: lerpDouble(a.distanceKm, b.distanceKm),
    speedKmh: lerpDouble(a.speedKmh, b.speedKmh),
    powerWatts: lerpDouble(a.powerWatts, b.powerWatts),
    heartRateBpm: lerpInt(a.heartRateBpm, b.heartRateBpm),
    cadenceRpm: lerpInt(a.cadenceRpm, b.cadenceRpm),
    elevationM: lerpDouble(a.elevationM, b.elevationM),
    gradientPercent: lerpDouble(a.gradientPercent, b.gradientPercent),
    lateralOffsetM: lerpDouble(a.lateralOffsetM, b.lateralOffsetM),
  );
}

double _normalizeDegrees(double deg) {
  final mod = deg % 360.0;
  return mod < 0 ? mod + 360.0 : mod;
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

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
