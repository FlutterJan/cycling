import 'dart:math' as math;

import '../../models/career/career_save.dart';
import '../../models/career/season_calendar.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import 'ai_team_transfer_simulation_service.dart';

/// Typ wpisu w strumieniu mediów kolarskich i mediów społecznościowych.
enum CyclingNewsItemType {
  stagePreview,
  raceReport,
  crashAnalysis,
  transferRumor,
  wattAndVamAnalysis,
  riderSocialPost;

  String toJson() => name;

  static CyclingNewsItemType fromJson(String value) {
    return CyclingNewsItemType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CyclingNewsItemType.raceReport,
    );
  }

  String get label {
    switch (this) {
      case CyclingNewsItemType.stagePreview:
        return 'Zapowiedź (5★)';
      case CyclingNewsItemType.raceReport:
        return 'Relacja z trasy';
      case CyclingNewsItemType.crashAnalysis:
        return 'Kraksa / Incydent';
      case CyclingNewsItemType.transferRumor:
        return 'Plotki transferowe';
      case CyclingNewsItemType.wattAndVamAnalysis:
        return 'Analiza W/kg & VAM';
      case CyclingNewsItemType.riderSocialPost:
        return 'Social Kolarza';
    }
  }
}

/// Źródło medialne wzorowane na czołowych portalach kolarskich i sieciach społecznościowych.
enum CyclingNewsPortalSource {
  cyclingnews,
  proCyclingStats,
  velonews,
  wattLabAnalytics,
  pelotonSocial;

  String toJson() => name;

  static CyclingNewsPortalSource fromJson(String value) {
    return CyclingNewsPortalSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CyclingNewsPortalSource.cyclingnews,
    );
  }

  String get displayName {
    switch (this) {
      case CyclingNewsPortalSource.cyclingnews:
        return 'Cyclingnews';
      case CyclingNewsPortalSource.proCyclingStats:
        return 'ProCyclingStats';
      case CyclingNewsPortalSource.velonews:
        return 'VeloNews';
      case CyclingNewsPortalSource.wattLabAnalytics:
        return 'WattLab Analytics';
      case CyclingNewsPortalSource.pelotonSocial:
        return 'PelotonSocial';
    }
  }

  String get defaultHandle {
    switch (this) {
      case CyclingNewsPortalSource.cyclingnews:
        return '@cyclingnews_pl';
      case CyclingNewsPortalSource.proCyclingStats:
        return '@ProCyclingStats';
      case CyclingNewsPortalSource.velonews:
        return '@velonews';
      case CyclingNewsPortalSource.wattLabAnalytics:
        return '@WattLabPro';
      case CyclingNewsPortalSource.pelotonSocial:
        return '@PelotonFeed';
    }
  }
}

/// Zrzut telemetrii z komputera rowerowego (Garmin / Wahoo) dołączony do wpisu kolarza.
class BikeComputerRideSnapshot {
  final int durationMinutes;
  final double distanceKm;
  final int elevationGainM;
  final int normalizedPowerW;
  final int averagePowerW;
  final double wPerKg;
  final double averageSpeedKmh;
  final int maxHeartRateBpm;
  final int tss;
  final int? vamMetersPerHour;
  final String? climbName;

  const BikeComputerRideSnapshot({
    required this.durationMinutes,
    required this.distanceKm,
    required this.elevationGainM,
    required this.normalizedPowerW,
    required this.averagePowerW,
    required this.wPerKg,
    required this.averageSpeedKmh,
    required this.maxHeartRateBpm,
    required this.tss,
    this.vamMetersPerHour,
    this.climbName,
  });

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  Map<String, dynamic> toJson() => {
        'durationMinutes': durationMinutes,
        'distanceKm': distanceKm,
        'elevationGainM': elevationGainM,
        'normalizedPowerW': normalizedPowerW,
        'averagePowerW': averagePowerW,
        'wPerKg': wPerKg,
        'averageSpeedKmh': averageSpeedKmh,
        'maxHeartRateBpm': maxHeartRateBpm,
        'tss': tss,
        if (vamMetersPerHour != null) 'vamMetersPerHour': vamMetersPerHour,
        if (climbName != null) 'climbName': climbName,
      };

  factory BikeComputerRideSnapshot.fromJson(Map<String, dynamic> json) {
    return BikeComputerRideSnapshot(
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      elevationGainM: (json['elevationGainM'] as num).toInt(),
      normalizedPowerW: (json['normalizedPowerW'] as num).toInt(),
      averagePowerW: (json['averagePowerW'] as num).toInt(),
      wPerKg: (json['wPerKg'] as num).toDouble(),
      averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
      maxHeartRateBpm: (json['maxHeartRateBpm'] as num).toInt(),
      tss: (json['tss'] as num).toInt(),
      vamMetersPerHour: (json['vamMetersPerHour'] as num?)?.toInt(),
      climbName: json['climbName'] as String?,
    );
  }
}

/// Typ faworytów przed etapem w systemie gwiazdkowym ("5 gwiazdek dla...").
class CyclingNewsStarPick {
  final String riderId;
  final String riderName;
  final String teamName;
  final int stars; // 1 - 5
  final String reason;

  const CyclingNewsStarPick({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.stars,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamName': teamName,
        'stars': stars,
        'reason': reason,
      };

  factory CyclingNewsStarPick.fromJson(Map<String, dynamic> json) {
    return CyclingNewsStarPick(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamName: json['teamName'] as String,
      stars: (json['stars'] as num).toInt().clamp(1, 5),
      reason: json['reason'] as String,
    );
  }
}

/// Pojedynczy artykuł prasowy lub wpis społecznościowy w strumieniu wiadomości kolarskich.
class CyclingNewsItem {
  final String id;
  final DateTime date;
  final CyclingNewsItemType type;
  final CyclingNewsPortalSource source;
  final String authorName;
  final String authorHandle;
  final String? authorTeamName;
  final String? authorNationalityIso;
  final String headline;
  final String body;
  final List<String> tags;
  final int likesCount;
  final int repostsCount;
  final int commentsCount;
  final bool isLikedByPlayer;
  final bool isBookmarked;
  final bool isPlayerTeamRelated;
  final String? raceId;
  final String? riderId;
  final BikeComputerRideSnapshot? rideSnapshot;
  final List<CyclingNewsStarPick> starPicks;

  const CyclingNewsItem({
    required this.id,
    required this.date,
    required this.type,
    required this.source,
    required this.authorName,
    required this.authorHandle,
    this.authorTeamName,
    this.authorNationalityIso,
    required this.headline,
    required this.body,
    this.tags = const [],
    this.likesCount = 0,
    this.repostsCount = 0,
    this.commentsCount = 0,
    this.isLikedByPlayer = false,
    this.isBookmarked = false,
    this.isPlayerTeamRelated = false,
    this.raceId,
    this.riderId,
    this.rideSnapshot,
    this.starPicks = const [],
  });

  CyclingNewsItem copyWith({
    String? id,
    DateTime? date,
    CyclingNewsItemType? type,
    CyclingNewsPortalSource? source,
    String? authorName,
    String? authorHandle,
    String? authorTeamName,
    String? authorNationalityIso,
    String? headline,
    String? body,
    List<String>? tags,
    int? likesCount,
    int? repostsCount,
    int? commentsCount,
    bool? isLikedByPlayer,
    bool? isBookmarked,
    bool? isPlayerTeamRelated,
    String? raceId,
    String? riderId,
    BikeComputerRideSnapshot? rideSnapshot,
    List<CyclingNewsStarPick>? starPicks,
  }) {
    return CyclingNewsItem(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      source: source ?? this.source,
      authorName: authorName ?? this.authorName,
      authorHandle: authorHandle ?? this.authorHandle,
      authorTeamName: authorTeamName ?? this.authorTeamName,
      authorNationalityIso: authorNationalityIso ?? this.authorNationalityIso,
      headline: headline ?? this.headline,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByPlayer: isLikedByPlayer ?? this.isLikedByPlayer,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isPlayerTeamRelated: isPlayerTeamRelated ?? this.isPlayerTeamRelated,
      raceId: raceId ?? this.raceId,
      riderId: riderId ?? this.riderId,
      rideSnapshot: rideSnapshot ?? this.rideSnapshot,
      starPicks: starPicks ?? this.starPicks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'type': type.toJson(),
        'source': source.toJson(),
        'authorName': authorName,
        'authorHandle': authorHandle,
        if (authorTeamName != null) 'authorTeamName': authorTeamName,
        if (authorNationalityIso != null)
          'authorNationalityIso': authorNationalityIso,
        'headline': headline,
        'body': body,
        'tags': tags,
        'likesCount': likesCount,
        'repostsCount': repostsCount,
        'commentsCount': commentsCount,
        'isLikedByPlayer': isLikedByPlayer,
        'isBookmarked': isBookmarked,
        'isPlayerTeamRelated': isPlayerTeamRelated,
        if (raceId != null) 'raceId': raceId,
        if (riderId != null) 'riderId': riderId,
        if (rideSnapshot != null) 'rideSnapshot': rideSnapshot!.toJson(),
        if (starPicks.isNotEmpty)
          'starPicks': starPicks.map((p) => p.toJson()).toList(),
      };

  factory CyclingNewsItem.fromJson(Map<String, dynamic> json) {
    return CyclingNewsItem(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: CyclingNewsItemType.fromJson(json['type'] as String),
      source: CyclingNewsPortalSource.fromJson(json['source'] as String),
      authorName: json['authorName'] as String,
      authorHandle: json['authorHandle'] as String,
      authorTeamName: json['authorTeamName'] as String?,
      authorNationalityIso: json['authorNationalityIso'] as String?,
      headline: json['headline'] as String,
      body: json['body'] as String,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      repostsCount: (json['repostsCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      isLikedByPlayer: json['isLikedByPlayer'] as bool? ?? false,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      isPlayerTeamRelated: json['isPlayerTeamRelated'] as bool? ?? false,
      raceId: json['raceId'] as String?,
      riderId: json['riderId'] as String?,
      rideSnapshot: json['rideSnapshot'] != null
          ? BikeComputerRideSnapshot.fromJson(
              json['rideSnapshot'] as Map<String, dynamic>,
            )
          : null,
      starPicks: (json['starPicks'] as List<dynamic>? ?? [])
          .map((e) => CyclingNewsStarPick.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Serwis generujący codzienny strumień mediów kolarskich (Cyclingnews, ProCyclingStats,
/// VeloNews, WattLab) oraz wpisy społecznościowe zawodników z telemetrią z liczników.
class SocialMediaAndCyclingNewsService {
  const SocialMediaAndCyclingNewsService();

  static const List<String> _famousClimbs = [
    'Col du Galibier',
    'Alpe d’Huez',
    'Mont Ventoux',
    'Col du Tourmalet',
    'Passo dello Stelvio',
    'Passo Giau',
    'Alto de l’Angliru',
    'Monte Zoncolan',
    'Oude Kwaremont',
    'Koppenberg',
  ];

  /// Generuje bogaty pakiet startowy wiadomości po wczytaniu lub rozpoczęciu kariery,
  /// tak aby ekran HQ od razu tętnił życiem.
  List<CyclingNewsItem> generateInitialFeed(
    CareerSave save, {
    int? seed,
  }) {
    final rng = math.Random(
      seed ?? (save.currentDate.millisecondsSinceEpoch ^ save.teams.length),
    );
    final List<CyclingNewsItem> items = [];

    // 1. Zapowiedź najbliższego wyścigu / etapu ("5 gwiazdek dla...")
    final preview = _buildStagePreviewItem(
      currentDate: save.currentDate,
      calendar: save.calendar,
      teams: save.teams,
      riders: save.riders,
      playerTeamId: save.playerTeamId,
      rng: rng,
    );
    if (preview != null) items.add(preview);

    // 2. Relacja z wyścigu / ucieczki
    final report = _buildBreakawayOrRaceReportItem(
      currentDate: save.currentDate.subtract(const Duration(hours: 4)),
      calendar: save.calendar,
      teams: save.teams,
      riders: save.riders,
      playerTeamId: save.playerTeamId,
      rng: rng,
    );
    if (report != null) items.add(report);

    // 3. Analiza watów i rekordów VAM na podjazdach
    final wattAnalysis = _buildWattAndVamAnalysisItem(
      currentDate: save.currentDate.subtract(const Duration(hours: 7)),
      calendar: save.calendar,
      teams: save.teams,
      riders: save.riders,
      playerTeamId: save.playerTeamId,
      rng: rng,
    );
    if (wattAnalysis != null) items.add(wattAnalysis);

    // 4. Plotka transferowa
    final rumor = _buildTransferRumorItem(
      currentDate: save.currentDate.subtract(const Duration(hours: 11)),
      teams: save.teams,
      riders: save.riders,
      playerTeamId: save.playerTeamId,
      recentTransfers: const [],
      rng: rng,
    );
    if (rumor != null) items.add(rumor);

    // 5. Komentarz po kraksie / incydencie
    final crashItem = _buildCrashCommentaryItem(
      currentDate: save.currentDate.subtract(const Duration(days: 1)),
      calendar: save.calendar,
      teams: save.teams,
      riders: save.riders,
      playerTeamId: save.playerTeamId,
      rng: rng,
    );
    if (crashItem != null) items.add(crashItem);

    // 6. Dwa wpisy społecznościowe kolarzy z danymi z komputerów rowerowych
    for (int i = 0; i < 2; i++) {
      final post = _buildRiderSocialPostItem(
        currentDate: save.currentDate.subtract(Duration(hours: 3 + i * 9)),
        calendar: save.calendar,
        teams: save.teams,
        riders: save.riders,
        playerTeamId: save.playerTeamId,
        preferPlayerTeam: i == 0,
        rng: rng,
      );
      if (post != null) items.add(post);
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  /// Generuje codzienne artykuły i wpisy społecznościowe podczas przewijania kalendarza (`advanceDay`).
  List<CyclingNewsItem> generateDailyFeed({
    required DateTime currentDate,
    required SeasonCalendar calendar,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required String playerTeamId,
    List<TransferNewsItem> recentTransfers = const [],
    List<RaceHistoryEntry> newlyCompletedRaces = const [],
    int? seed,
  }) {
    if (teams.isEmpty || riders.isEmpty) return const [];

    final rng = math.Random(
      seed ??
          (currentDate.year * 10000 +
              currentDate.month * 100 +
              currentDate.day +
              riders.length),
    );
    final List<CyclingNewsItem> daily = [];

    // A) Jeśli dziś lub jutro jest wyścig/etap -> zapowiedź "5 gwiazdek dla..."
    final preview = _buildStagePreviewItem(
      currentDate: currentDate,
      calendar: calendar,
      teams: teams,
      riders: riders,
      playerTeamId: playerTeamId,
      rng: rng,
      onlyIfImminent: true,
    );
    if (preview != null) daily.add(preview);

    // B) Jeśli ukończono wyścig na świecie -> pełny pakiet pomeczowy (relacja + waty/VAM + social)
    if (newlyCompletedRaces.isNotEmpty) {
      final completed = newlyCompletedRaces.first;
      final postRace = generatePostRaceBundle(
        date: currentDate,
        raceName: completed.raceName,
        raceId: completed.raceId,
        winnerRiderName: completed.winnerRiderName,
        winnerTeamName: completed.winnerTeamName,
        teams: teams,
        riders: riders,
        playerTeamId: playerTeamId,
        stage: calendar.activeStage,
        seed: rng.nextInt(1 << 30),
      );
      daily.addAll(postRace);
    } else {
      // C) Codzienny rytm świata kolarskiego (rotacja typów wiadomości)
      final roll = rng.nextInt(100);
      if (roll < 38) {
        final report = _buildBreakawayOrRaceReportItem(
          currentDate: currentDate,
          calendar: calendar,
          teams: teams,
          riders: riders,
          playerTeamId: playerTeamId,
          rng: rng,
        );
        if (report != null) daily.add(report);
      } else if (roll < 65) {
        final wattItem = _buildWattAndVamAnalysisItem(
          currentDate: currentDate,
          calendar: calendar,
          teams: teams,
          riders: riders,
          playerTeamId: playerTeamId,
          rng: rng,
        );
        if (wattItem != null) daily.add(wattItem);
      } else if (roll < 84) {
        final rumor = _buildTransferRumorItem(
          currentDate: currentDate,
          teams: teams,
          riders: riders,
          playerTeamId: playerTeamId,
          recentTransfers: recentTransfers,
          rng: rng,
        );
        if (rumor != null) daily.add(rumor);
      } else {
        final crash = _buildCrashCommentaryItem(
          currentDate: currentDate,
          calendar: calendar,
          teams: teams,
          riders: riders,
          playerTeamId: playerTeamId,
          rng: rng,
        );
        if (crash != null) daily.add(crash);
      }

      // Prawie każdego dnia pojawia się przynajmniej 1 wpis kolarza z treningu lub wyścigu
      if (rng.nextDouble() < 0.78) {
        final social = _buildRiderSocialPostItem(
          currentDate: currentDate,
          calendar: calendar,
          teams: teams,
          riders: riders,
          playerTeamId: playerTeamId,
          preferPlayerTeam: rng.nextDouble() < 0.45,
          rng: rng,
        );
        if (social != null) daily.add(social);
      }
    }

    return daily;
  }

  /// Generuje pakiet artykułów i wpisów kolarzy natychmiast po zakończeniu etapu/wyścigu.
  List<CyclingNewsItem> generatePostRaceBundle({
    required DateTime date,
    required String raceName,
    required String raceId,
    required String winnerRiderName,
    required String winnerTeamName,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required String playerTeamId,
    RaceStage? stage,
    bool hadMajorCrash = false,
    int? seed,
  }) {
    final rng = math.Random(
      seed ?? (date.millisecondsSinceEpoch ^ raceId.hashCode),
    );
    final List<CyclingNewsItem> bundle = [];
    final playerTeam = _findTeamById(teams, playerTeamId);
    final bool playerWon =
        playerTeam != null && winnerTeamName == playerTeam.name;

    // 1. Relacja z ucieczki i końcówki wyścigu
    final breakawayRider = _pickRider(
      riders,
      rng,
      preferredSpec: RiderSpecialization.breakawaySpecialist,
    );
    final breakawayTeam = breakawayRider != null
        ? _findTeamForRider(teams, breakawayRider.id)
        : null;
    final breakawayDist = 115 + rng.nextInt(55);
    final catchKm = 4 + rng.nextInt(18);

    bundle.add(
      CyclingNewsItem(
        id: 'news_report_${date.millisecondsSinceEpoch}_${rng.nextInt(9999)}',
        date: date,
        type: CyclingNewsItemType.raceReport,
        source: CyclingNewsPortalSource.cyclingnews,
        authorName: 'Redakcja Cyclingnews',
        authorHandle: '@cyclingnews_pl',
        headline: '$winnerRiderName ($winnerTeamName) triumfuje w $raceName!',
        body:
            'Dramatyczna końcówka w $raceName. ${breakawayRider?.fullName ?? 'Uciekinier dnia'} '
            '(${breakawayTeam?.name ?? 'ProTeam'}) spędził w odjeździe aż $breakawayDist km, '
            'zanim peleton skasował ucieczkę na $catchKm km przed metą. W decydującym momencie '
            'najwięcej zimnej krwi zachował $winnerRiderName, dając ekipie $winnerTeamName '
            'cenne zwycięstwo i punkty UCI.',
        tags: ['Wyścig', 'Relacja', raceName.split(' ').first],
        likesCount: 420 + rng.nextInt(1400),
        repostsCount: 85 + rng.nextInt(320),
        commentsCount: 24 + rng.nextInt(110),
        isPlayerTeamRelated: playerWon,
        raceId: raceId,
      ),
    );

    // 2. Analiza watów i VAM na kluczowym podjeździe
    final climbName = _famousClimbs[rng.nextInt(_famousClimbs.length)];
    final climbingRider = _pickRider(
      riders,
      rng,
      preferredSpec: RiderSpecialization.gcClimber,
    );
    final double weight = climbingRider?.physiology.weightKg ?? 63.0;
    final double watts20m =
        climbingRider?.powerProfile.watts20m.toDouble() ?? 415.0;
    final double wPerKg =
        double.parse((watts20m / math.max(50.0, weight)).toStringAsFixed(2));
    final int vam = (1580 + (wPerKg - 5.5) * 260 + rng.nextInt(95))
        .round()
        .clamp(1350, 2050);
    final int effortMins = 22 + rng.nextInt(18);

    bundle.add(
      CyclingNewsItem(
        id: 'news_watt_${date.millisecondsSinceEpoch}_${rng.nextInt(9999)}',
        date: date.subtract(const Duration(minutes: 25)),
        type: CyclingNewsItemType.wattAndVamAnalysis,
        source: CyclingNewsPortalSource.wattLabAnalytics,
        authorName: 'WattLab Analytics',
        authorHandle: '@WattLabPro',
        headline:
            'Rekordowe $vam m/h VAM na $climbName! ${wPerKg.toStringAsFixed(2)} W/kg przez $effortMins minut',
        body:
            'Dane z mierników mocy po $raceName nie pozostawiają złudzeń. '
            '${climbingRider?.fullName ?? winnerRiderName} wygenerował średnio '
            '${watts20m.round()} W (${wPerKg.toStringAsFixed(2)} W/kg) przy szacowanym VAM $vam m/h. '
            'To jeden z najszybszych wjazdów w tym sezonie — wyższy o ~${3 + rng.nextInt(5)}% od średniej z ostatnich pięciu lat.',
        tags: ['Waty', 'VAM', 'Telemetria'],
        likesCount: 610 + rng.nextInt(1900),
        repostsCount: 140 + rng.nextInt(450),
        commentsCount: 45 + rng.nextInt(140),
        isPlayerTeamRelated: playerWon ||
            (climbingRider != null &&
                playerTeam?.rosterRiderIds.contains(climbingRider.id) == true),
        raceId: raceId,
        riderId: climbingRider?.id,
      ),
    );

    // 3. Opcjonalnie komentarz po kraksie
    if (hadMajorCrash || rng.nextDouble() < 0.35) {
      final crash = _buildCrashCommentaryItem(
        currentDate: date.subtract(const Duration(minutes: 45)),
        calendar: SeasonCalendar(
          seasonYear: date.year,
          races: const [],
        ),
        teams: teams,
        riders: riders,
        playerTeamId: playerTeamId,
        rng: rng,
        overrideRaceName: raceName,
      );
      if (crash != null) bundle.add(crash);
    }

    // 4. Wpis społecznościowy kolarza z załączonym plikiem z komputera rowerowego
    final social = _buildRiderSocialPostItem(
      currentDate: date.subtract(const Duration(minutes: 10)),
      calendar: SeasonCalendar(seasonYear: date.year, races: const []),
      teams: teams,
      riders: riders,
      playerTeamId: playerTeamId,
      preferPlayerTeam: true,
      rng: rng,
      overrideRaceName: raceName,
      overrideStage: stage,
    );
    if (social != null) bundle.add(social);

    return bundle;
  }

  // ===========================================================================
  // WEWNĘTRZNE GENERATORY POSZCZEGÓLNYCH TYPÓW TREŚCI
  // ===========================================================================

  CyclingNewsItem? _buildStagePreviewItem({
    required DateTime currentDate,
    required SeasonCalendar calendar,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required String playerTeamId,
    required math.Random rng,
    bool onlyIfImminent = false,
  }) {
    final TourRace? targetRace =
        calendar.activeRace ?? calendar.nextUpcomingRace;
    if (targetRace == null) return null;

    if (onlyIfImminent) {
      final daysUntil = targetRace.startDate.difference(currentDate).inDays;
      if (daysUntil > 1 && calendar.activeRace == null) return null;
    }

    final RaceStage? stage = calendar.activeStage ??
        (targetRace.stages.isNotEmpty ? targetRace.stages.first : null);
    final StageType stageType = stage?.stageType ?? StageType.hilly;

    final candidates = List<Rider>.from(riders);
    candidates.sort((a, b) =>
        _scoreRiderForStage(b, stageType).compareTo(_scoreRiderForStage(a, stageType)));

    final top3 = candidates.take(3).toList();
    if (top3.isEmpty) return null;

    final List<CyclingNewsStarPick> picks = [];
    for (int i = 0; i < top3.length; i++) {
      final r = top3[i];
      final team = _findTeamForRider(teams, r.id);
      final stars = i == 0 ? 5 : (i == 1 ? 4 : 3);
      picks.add(
        CyclingNewsStarPick(
          riderId: r.id,
          riderName: r.fullName,
          teamName: _teamTag(team),
          stars: stars,
          reason: _buildStarReason(r, stageType),
        ),
      );
    }

    final playerTeam = _findTeamById(teams, playerTeamId);
    final bool isPlayerInvolved =
        targetRace.participatingTeamIds.contains(playerTeamId) ||
            top3.any((r) =>
                playerTeam?.rosterRiderIds.contains(r.id) ?? false);

    final String stageTitle = stage != null
        ? '${targetRace.name} (Etap ${stage.stageNumber}: ${stage.name})'
        : targetRace.name;

    return CyclingNewsItem(
      id: 'news_preview_${currentDate.millisecondsSinceEpoch}_${rng.nextInt(9999)}',
      date: currentDate,
      type: CyclingNewsItemType.stagePreview,
      source: CyclingNewsPortalSource.proCyclingStats,
      authorName: 'ProCyclingStats Preview',
      authorHandle: '@ProCyclingStats',
      headline: '5 gwiazdek dla ${top3.first.fullName}! Kto faworytem $stageTitle?',
      body:
          'Eksperci ProCyclingStats przeanalizowali profil trasy (${stage?.distanceKm.toStringAsFixed(0) ?? '175'} km, '
          '${stage?.elevationGainMeters ?? 1850} m przewyższenia). Głównym faworytem z oceną 5★ jest '
          '${top3.first.fullName} (${picks.first.teamName}), ale groźni będą też '
          '${top3.length > 1 ? top3[1].fullName : 'rywale z WorldTour'}.',
      tags: ['Zapowiedź', '5 Gwiazdek', targetRace.name.split(' ').first],
      likesCount: 310 + rng.nextInt(890),
      repostsCount: 64 + rng.nextInt(210),
      commentsCount: 19 + rng.nextInt(75),
      isPlayerTeamRelated: isPlayerInvolved,
      raceId: targetRace.id,
      riderId: top3.first.id,
      starPicks: picks,
    );
  }

  CyclingNewsItem? _buildBreakawayOrRaceReportItem({
    required DateTime currentDate,
    required SeasonCalendar calendar,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required String playerTeamId,
    required math.Random rng,
  }) {
    if (riders.isEmpty || teams.isEmpty) return null;

    final history = calendar.raceHistory.values;
    final RaceHistoryEntry? recentRace =
        history.isNotEmpty ? history.last : null;

    final attacker = _pickRider(
      riders,
      rng,
      preferredSpec: RiderSpecialization.breakawaySpecialist,
    );
    final attackerTeam =
        attacker != null ? _findTeamForRider(teams, attacker.id) : null;
    final playerTeam = _findTeamById(teams, playerTeamId);

    final String raceTitle = recentRace?.raceName ??
        calendar.nextUpcomingRace?.name ??
        'Tour de Romandie';
    final int soloKm = 32 + rng.nextInt(48);
    final int avgSpeed = 42 + rng.nextInt(6);

    final bool playerRelated = (recentRace?.winnerTeamId == playerTeamId) ||
        (attacker != null &&
            playerTeam?.rosterRiderIds.contains(attacker.id) == true);

    return CyclingNewsItem(
      id: 'news_brk_${currentDate.millisecondsSinceEpoch}_${rng.nextInt(9999)}',
      date: currentDate,
      type: CyclingNewsItemType.raceReport,
      source: CyclingNewsPortalSource.velonews,
      authorName: 'VeloNews Live',
      authorHandle: '@velonews',
      headline: recentRace != null
          ? '${recentRace.winnerRiderName} bezkonkurencyjny w $raceTitle po szalonej ucieczce'
          : 'Heroiczna akcja ${attacker?.fullName ?? 'harce'}! $soloKm km samotnie przed peletonem',
      body: recentRace != null
          ? 'Po niezwykle szybkim wyścigu (średnia $avgSpeed km/h) ${recentRace.winnerRiderName} '
              '(${recentRace.winnerTeamName}) sięgnął po zwycięstwo w $raceTitle. '
              'Wcześniej przez ponad $soloKm km tempo dyktowała 5-osobowa ucieczka dnia z aktywnym '
              '${attacker?.fullName ?? 'kolarzem ProTeam'}.'
          : 'Na szosach Europy trwa zacięta walka o punkty UCI. ${attacker?.fullName ?? 'Lider odjazdu'} '
              '(${attackerTeam?.name ?? 'WorldTour'}) zaprezentował znakomitą dyspozycję w odjeździe, '
              'utrzymując ponad 3 minuty przewagi przy średniej prędkości $avgSpeed km/h.',
      tags: ['Ucieczka', 'Peleton', 'VeloNews'],
      likesCount: 245 + rng.nextInt(760),
      repostsCount: 41 + rng.nextInt(180),
      commentsCount: 15 + rng.nextInt(60),
      isPlayerTeamRelated: playerRelated,
      raceId: recentRace?.raceId,
      riderId: attacker?.id,
    );
  }

  CyclingNewsItem? _buildWattAndVamAnalysisItem({
    required DateTime currentDate,
    required SeasonCalendar calendar,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required String playerTeamId,
    required math.Random rng,
  }) {
    if (riders.isEmpty) return null;

    final climber = _pickRider(
      riders,
      rng,
      preferredSpec: RiderSpecialization.gcClimber,
    );
    if (climber == null) return null;

    final team = _findTeamForRider(teams, climber.id);
    final playerTeam = _findTeamById(teams, playerTeamId);
    final climb = _famousClimbs[rng.nextInt(_famousClimbs.length)];

    final double weight = math.max(52.0, climber.physiology.weightKg);
    final double w20 = climber.powerProfile.watts20m.toDouble();
    final double wPerKg = double.parse((w20 / weight).toStringAsFixed(2));
    final int vam = (1540 + (wPerKg - 5.4) * 240 + rng.nextInt(80))
        .round()
        .clamp(1380, 2020);
    final int durationMin = 24 + rng.nextInt(14);

    return CyclingNewsItem(
      id: 'news_vam_${currentDate.millisecondsSinceEpoch}_${rng.nextInt(9999)}',
      date: currentDate,
      type: CyclingNewsItemType.wattAndVamAnalysis,
      source: CyclingNewsPortalSource.wattLabAnalytics,
      authorName: 'WattLab Analytics',
      authorHandle: '@WattLabPro',
      headline:
          'Analiza WattLab: ${climber.fullName} z wynikiem ${wPerKg.toStringAsFixed(2)} W/kg i $vam m/h VAM',
      body:
          'Nasz zespół analityków przyjrzał się plikom mocy ${climber.fullName} (${_teamTag(team)}). '
          'Podczas kluczowej selekcji na $climb kolarz generował ${w20.round()} W przez $durationMin minut '
          '(${wPerKg.toStringAsFixed(2)} W/kg). Przy nachyleniu 8.4% przekłada się to na VAM $vam m/h — '
          'poziom gwarantujący walkę o podium Wielkiego Touru.',
      tags: ['W/kg', 'VAM', 'WattLab'],
      likesCount: 530 + rng.nextInt(1250),
      repostsCount: 112 + rng.nextInt(310),
      commentsCount: 38 + rng.nextInt(95),
      isPlayerTeamRelated:
          playerTeam?.rosterRiderIds.contains(climber.id) ?? false,
      riderId: climber.id,
    );
  }

  CyclingNewsItem? _buildCrashCommentaryItem({
    required DateTime currentDate,
    required SeasonCalendar calendar,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required String playerTeamId,
    required math.Random rng,
    String? overrideRaceName,
  }) {
    if (riders.isEmpty) return null;

    final injured = riders.where((r) => r.health.currentInjury != null).toList();
    final Rider subject = injured.isNotEmpty
        ? injured[rng.nextInt(injured.length)]
        : riders[rng.nextInt(riders.length)];
    final team = _findTeamForRider(teams, subject.id);
    final playerTeam = _findTeamById(teams, playerTeamId);
    final raceName = overrideRaceName ??
        calendar.nextUpcomingRace?.name ??
        'etapu WorldTour';

    final String injuryNote = subject.health.currentInjury != null
        ? 'Lekarze zdiagnozowali ${subject.health.currentInjury!.name} (${subject.health.currentInjury!.daysRemaining} dni przerwy).'
        : 'Na szczęście skończyło się na powierzchownych otarciach i wymianie roweru zapasowego.';

    return CyclingNewsItem(
      id: 'news_crash_${currentDate.millisecondsSinceEpoch}_${rng.nextInt(9999)}',
      date: currentDate,
      type: CyclingNewsItemType.crashAnalysis,
      source: CyclingNewsPortalSource.cyclingnews,
      authorName: 'Cyclingnews Medical & Safety',
      authorHandle: '@cyclingnews_pl',
      headline:
          'Nerwowa kraksa w końcówce $raceName! Ucierpiał ${subject.fullName}',
      body:
          'Wysoka prędkość na zjeździe i zwężenie drogi na 18 km przed metą $raceName doprowadziły do '
          'groźnego upadku w środku peletonu. Jednym z poszkodowanych był ${subject.fullName} '
          '(${team?.name ?? 'ProTeam'}). $injuryNote Organizatorzy zapowiedzieli analizę zabezpieczenia trasy.',
      tags: ['Kraksa', 'Bezpieczeństwo', 'Peleton'],
      likesCount: 190 + rng.nextInt(540),
      repostsCount: 48 + rng.nextInt(150),
      commentsCount: 34 + rng.nextInt(120),
      isPlayerTeamRelated:
          playerTeam?.rosterRiderIds.contains(subject.id) ?? false,
      riderId: subject.id,
    );
  }

  CyclingNewsItem? _buildTransferRumorItem({
    required DateTime currentDate,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required String playerTeamId,
    required List<TransferNewsItem> recentTransfers,
    required math.Random rng,
  }) {
    if (teams.length < 2 || riders.isEmpty) return null;

    if (recentTransfers.isNotEmpty && rng.nextBool()) {
      final t = recentTransfers.first;
      return CyclingNewsItem(
        id: 'news_trf_${currentDate.millisecondsSinceEpoch}_${rng.nextInt(9999)}',
        date: currentDate,
        type: CyclingNewsItemType.transferRumor,
        source: CyclingNewsPortalSource.velonews,
        authorName: 'Daniel Benson • Transfer Insider',
        authorHandle: '@dnlbenson_sim',
        headline: 'OFICJALNIE / KULISY: ${t.riderName} wzmacnia ${t.toTeamName}!',
        body:
            'Głośny ruch na rynku kolarskim stał się faktem. ${t.riderName} opuszcza '
            '${t.fromTeamName} i podpisuje ${t.contractYears}-letni kontrakt z '
            '${t.toTeamName} wart €${(t.contractAmountEur / 1000).round()}k rocznie. Dyrektorzy sportowi '
            'liczą na natychmiastowy skok jakości w wyścigach WorldTour.',
        tags: ['Transfery', 'Rynek', 'WorldTour'],
        likesCount: 480 + rng.nextInt(1100),
        repostsCount: 120 + rng.nextInt(380),
        commentsCount: 55 + rng.nextInt(160),
        isPlayerTeamRelated: t.toTeamId == playerTeamId || t.fromTeamId == playerTeamId,
        riderId: t.riderId,
      );
    }

    final expiring = riders
        .where((r) => r.contract.contractEndYear <= currentDate.year + 1)
        .toList();
    final Rider target = expiring.isNotEmpty
        ? expiring[rng.nextInt(expiring.length)]
        : riders[rng.nextInt(riders.length)];
    final currentTeam = _findTeamForRider(teams, target.id);
    final interestedTeams =
        teams.where((t) => t.id != currentTeam?.id).toList();
    if (interestedTeams.isEmpty) return null;
    final suitor = interestedTeams[rng.nextInt(interestedTeams.length)];
    final playerTeam = _findTeamById(teams, playerTeamId);

    final int estimatedSalaryK =
        ((target.contract.annualSalaryEur * (1.05 + rng.nextDouble() * 0.25)) /
                1000)
            .round()
            .clamp(60, 4500);

    return CyclingNewsItem(
      id: 'news_rumor_${currentDate.millisecondsSinceEpoch}_${rng.nextInt(9999)}',
      date: currentDate,
      type: CyclingNewsItemType.transferRumor,
      source: CyclingNewsPortalSource.cyclingnews,
      authorName: 'Transfer Rumors Desk',
      authorHandle: '@cyclingnews_pl',
      headline:
          'Plotki z peletonu: ${suitor.name} kusi ${target.fullName} kontraktem €${estimatedSalaryK}k/rok',
      body:
          'Według nieoficjalnych doniesień z padoku, agent ${target.fullName} '
          '(${currentTeam?.name ?? 'Wolny Agent'}) prowadzi zaawansowane rozmowy z ekipą '
          '${suitor.name}. W grze ma być rola lidera na wyścigi etapowe oraz umowa na poziomie '
          '€${estimatedSalaryK}k za sezon.',
      tags: ['Plotki', 'Transfery', _teamTag(suitor)],
      likesCount: 290 + rng.nextInt(780),
      repostsCount: 72 + rng.nextInt(240),
      commentsCount: 41 + rng.nextInt(130),
      isPlayerTeamRelated: suitor.id == playerTeamId ||
          (playerTeam?.rosterRiderIds.contains(target.id) ?? false),
      riderId: target.id,
    );
  }

  CyclingNewsItem? _buildRiderSocialPostItem({
    required DateTime currentDate,
    required SeasonCalendar calendar,
    required List<CyclingTeam> teams,
    required List<Rider> riders,
    required String playerTeamId,
    required bool preferPlayerTeam,
    required math.Random rng,
    String? overrideRaceName,
    RaceStage? overrideStage,
  }) {
    final playerTeam = _findTeamById(teams, playerTeamId);
    Rider? rider;
    if (preferPlayerTeam &&
        playerTeam != null &&
        playerTeam.rosterRiderIds.isNotEmpty) {
      final playerRiders = riders
          .where((r) => playerTeam.rosterRiderIds.contains(r.id))
          .toList();
      if (playerRiders.isNotEmpty) {
        rider = playerRiders[rng.nextInt(playerRiders.length)];
      }
    }
    rider ??= riders[rng.nextInt(riders.length)];

    final team = _findTeamForRider(teams, rider.id);
    final bool isPlayerRider =
        playerTeam?.rosterRiderIds.contains(rider.id) ?? false;

    final int ftp = rider.physiology.ftpWatts;
    final double weight = math.max(52.0, rider.physiology.weightKg);
    final StageType stageType = overrideStage?.stageType ??
        StageType.values[rng.nextInt(StageType.values.length)];
    final WeatherCondition weather = overrideStage?.weatherCondition ??
        WeatherCondition.values[rng.nextInt(WeatherCondition.values.length)];

    final int durationMins = 210 + rng.nextInt(135); // 3h30 - 5h45
    final double intensityFactor = 0.76 + rng.nextDouble() * 0.14;
    final int npWatts = (ftp * intensityFactor).round().clamp(240, 440);
    final int avgWatts = (npWatts * (0.86 + rng.nextDouble() * 0.06)).round();
    final double wPerKg =
        double.parse((npWatts / weight).toStringAsFixed(2));
    final double avgSpeed = double.parse(
      (stageType == StageType.highMountain ||
                  stageType == StageType.summitFinish
              ? 35.5 + rng.nextDouble() * 4.5
              : 41.0 + rng.nextDouble() * 5.8)
          .toStringAsFixed(1),
    );
    final double distanceKm = double.parse(
      ((durationMins / 60.0) * avgSpeed).toStringAsFixed(1),
    );
    final int elevGain = stageType == StageType.highMountain ||
            stageType == StageType.summitFinish
        ? 3100 + rng.nextInt(1400)
        : (stageType == StageType.flat ? 650 + rng.nextInt(550) : 1750 + rng.nextInt(900));
    final int tss =
        ((durationMins / 60.0) * intensityFactor * intensityFactor * 100)
            .round();
    final int? vam = (stageType == StageType.highMountain ||
            stageType == StageType.summitFinish)
        ? (1520 + rng.nextInt(360))
        : null;

    final snapshot = BikeComputerRideSnapshot(
      durationMinutes: durationMins,
      distanceKm: distanceKm,
      elevationGainM: elevGain,
      normalizedPowerW: npWatts,
      averagePowerW: avgWatts,
      wPerKg: wPerKg,
      averageSpeedKmh: avgSpeed,
      maxHeartRateBpm: 178 + rng.nextInt(19),
      tss: tss,
      vamMetersPerHour: vam,
      climbName: vam != null
          ? _famousClimbs[rng.nextInt(_famousClimbs.length)]
          : null,
    );

    final String postText = _buildRiderSocialCopy(
      rider: rider,
      snapshot: snapshot,
      stageType: stageType,
      weather: weather,
      raceName: overrideRaceName,
    );

    final String handle =
        '@${rider.firstName.toLowerCase()}_${rider.lastName.toLowerCase().replaceAll(' ', '')}';

    return CyclingNewsItem(
      id: 'news_social_${currentDate.millisecondsSinceEpoch}_${rng.nextInt(9999)}',
      date: currentDate,
      type: CyclingNewsItemType.riderSocialPost,
      source: CyclingNewsPortalSource.pelotonSocial,
      authorName: rider.fullName,
      authorHandle: handle,
      authorTeamName: team?.name ?? 'Pro Peloton',
      authorNationalityIso: rider.nationalityIso,
      headline: '${rider.fullName} udostępnił plik z licznika (${snapshot.normalizedPowerW}W NP)',
      body: postText,
      tags: ['Garmin', 'StravaData', _teamTag(team)],
      likesCount: 840 + rng.nextInt(3400),
      repostsCount: 65 + rng.nextInt(410),
      commentsCount: 28 + rng.nextInt(180),
      isPlayerTeamRelated: isPlayerRider,
      riderId: rider.id,
      rideSnapshot: snapshot,
    );
  }

  String _buildRiderSocialCopy({
    required Rider rider,
    required BikeComputerRideSnapshot snapshot,
    required StageType stageType,
    required WeatherCondition weather,
    String? raceName,
  }) {
    final hours = (snapshot.durationMinutes / 60.0).toStringAsFixed(1);
    final raceSuffix = raceName != null ? ' na trasie $raceName' : '';

    if (stageType == StageType.cobbleClassic ||
        weather == WeatherCondition.lightRain ||
        weather == WeatherCondition.heavyStorm) {
      return 'Ciężki dzień w deszczu na bruku$raceSuffix. ${snapshot.normalizedPowerW}W Normalized Power '
          'przez $hours godziny, ale lider dowieziony bezpiecznie do mety! Teraz czas na regenerację. 🚴‍♂️🌧️';
    }
    if (stageType == StageType.highMountain ||
        stageType == StageType.summitFinish) {
      return 'Prawdziwa próba charakteru w górach$raceSuffix! ${snapshot.elevationGainM} m w pionie, '
          '${snapshot.wPerKg.toStringAsFixed(2)} W/kg i ${snapshot.vamMetersPerHour ?? 1680} m/h VAM na finałowej ścianie. '
          'Nogi pieką, ale forma rośnie! ⛰️🔥';
    }
    if (rider.specialization == RiderSpecialization.pureSprinter ||
        stageType == StageType.flat) {
      return 'Szybki pociąg i walka o każdy centymetr asfaltu$raceSuffix! '
          '${snapshot.averageSpeedKmh.toStringAsFixed(1)} km/h średniej przez ${snapshot.distanceKm.toStringAsFixed(0)} km, '
          'a w końcówce pełny gaz na kole rozprowadzającego. ⚡💨';
    }
    return 'Solidna robota wykonana$raceSuffix — ${snapshot.distanceKm.toStringAsFixed(0)} km w siodle, '
        '${snapshot.normalizedPowerW}W NP (${snapshot.tss} TSS). Dziękuję chłopakom z ekipy za wsparcie na rantach! 🙌🚴';
  }

  double _scoreRiderForStage(Rider rider, StageType stageType) {
    final w = math.max(50.0, rider.physiology.weightKg);
    switch (stageType) {
      case StageType.flat:
        return rider.powerProfile.watts5s / 15.0 +
            rider.skills.draftingEfficiency * 0.4;
      case StageType.cobbleClassic:
        return rider.skills.cobbles * 1.1 +
            rider.physiology.ftpWatts / w * 8.0;
      case StageType.highMountain:
      case StageType.summitFinish:
        return (rider.powerProfile.watts20m / w) * 16.0 +
            rider.physiology.vo2Max * 0.4;
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        return rider.physiology.ftpWatts / 4.0 +
            rider.skills.timeTrialPositioning * 0.9;
      case StageType.hilly:
        return (rider.powerProfile.watts5m / w) * 12.0 +
            rider.skills.punch * 0.5;
    }
  }

  String _buildStarReason(Rider rider, StageType stageType) {
    final w = math.max(50.0, rider.physiology.weightKg);
    switch (stageType) {
      case StageType.flat:
        return 'Szczyt sprintu ${rider.powerProfile.watts5s.round()} W';
      case StageType.cobbleClassic:
        return 'Technika na bruku ${rider.skills.cobbles}/99';
      case StageType.highMountain:
      case StageType.summitFinish:
        return '${(rider.powerProfile.watts20m / w).toStringAsFixed(2)} W/kg (20 min)';
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        return 'FTP ${rider.physiology.ftpWatts} W & aero';
      case StageType.hilly:
        return 'Dynamika 5-min ${(rider.powerProfile.watts5m / w).toStringAsFixed(1)} W/kg';
    }
  }

  Rider? _pickRider(
    List<Rider> riders,
    math.Random rng, {
    RiderSpecialization? preferredSpec,
  }) {
    if (riders.isEmpty) return null;
    if (preferredSpec != null) {
      final matching =
          riders.where((r) => r.specialization == preferredSpec).toList();
      if (matching.isNotEmpty) {
        return matching[rng.nextInt(matching.length)];
      }
    }
    return riders[rng.nextInt(riders.length)];
  }

  CyclingTeam? _findTeamById(List<CyclingTeam> teams, String id) {
    for (final t in teams) {
      if (t.id == id) return t;
    }
    return null;
  }

  CyclingTeam? _findTeamForRider(List<CyclingTeam> teams, String riderId) {
    for (final t in teams) {
      if (t.rosterRiderIds.contains(riderId)) return t;
    }
    return null;
  }

  String _teamTag(CyclingTeam? team) {
    if (team == null || team.name.trim().isEmpty) return 'PRO';
    final words = team.name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return words
          .take(3)
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
          .join();
    }
    final clean = team.name.trim().toUpperCase();
    return clean.length > 4 ? clean.substring(0, 4) : clean;
  }
}
