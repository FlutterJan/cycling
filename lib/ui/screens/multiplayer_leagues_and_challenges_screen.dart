import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/multiplayer/online_league_and_ghost_challenge_model.dart';
import '../../services/network/async_multiplayer_league_sync_service.dart';

/// Zakładki główne Centrum Lig Online i Wyzwań Tygodnia.
enum MultiplayerHubTab {
  leagues,
  weeklyChallenges,
  syncAndDraft,
  eloRanking;

  String get label {
    switch (this) {
      case MultiplayerHubTab.leagues:
        return 'Ligi i Tabele';
      case MultiplayerHubTab.weeklyChallenges:
        return 'Wyzwania Tygodnia';
      case MultiplayerHubTab.syncAndDraft:
        return 'Draft & .ppmleague';
      case MultiplayerHubTab.eloRanking:
        return 'Ranking ELO';
    }
  }

  IconData get icon {
    switch (this) {
      case MultiplayerHubTab.leagues:
        return Icons.emoji_events_outlined;
      case MultiplayerHubTab.weeklyChallenges:
        return Icons.bolt_outlined;
      case MultiplayerHubTab.syncAndDraft:
        return Icons.sync_alt_rounded;
      case MultiplayerHubTab.eloRanking:
        return Icons.leaderboard_outlined;
    }
  }
}

/// Filtr listy lig online.
enum MultiplayerLeagueFilter {
  all,
  friendsOnly,
  publicRanked,
  activeOnly;

  String get label {
    switch (this) {
      case MultiplayerLeagueFilter.all:
        return 'Wszystkie';
      case MultiplayerLeagueFilter.friendsOnly:
        return 'Ze Znajomymi';
      case MultiplayerLeagueFilter.publicRanked:
        return 'Publiczne ELO';
      case MultiplayerLeagueFilter.activeOnly:
        return 'Aktywne';
    }
  }
}

/// Katalog startowych lig, wyzwań tygodnia i profilu ELO do trybu offline/demo oraz testów.
class MultiplayerLeaguesDemoCatalog {
  const MultiplayerLeaguesDemoCatalog._();

  static EloRatingProfile defaultPlayerProfile() {
    final now = DateTime.utc(2026, 7, 14, 18, 30);
    return EloRatingProfile(
      playerId: 'player_local',
      displayName: 'Ty (Dyrektor Sportowy)',
      currentElo: 1584,
      peakElo: 1622,
      matchesPlayed: 24,
      wins: 14,
      podiums: 19,
      winStreak: 3,
      bestWinStreak: 5,
      recentHistory: [
        EloMatchRecord(
          matchId: 'm_01',
          leagueId: 'lg_alpes_friends',
          opponentId: 'fr_marek',
          opponentName: 'Marek K. (Alpejskie Wilki)',
          eloBefore: 1566,
          eloAfter: 1584,
          delta: 18,
          placement: 1,
          fieldSize: 6,
          recordedAt: now.subtract(const Duration(hours: 6)),
        ),
        EloMatchRecord(
          matchId: 'm_02',
          leagueId: 'lg_flanders_h2h',
          opponentId: 'fr_tomasz',
          opponentName: 'Tomasz N. (Flandria Aero)',
          eloBefore: 1551,
          eloAfter: 1566,
          delta: 15,
          placement: 1,
          fieldSize: 2,
          recordedAt: now.subtract(const Duration(days: 1, hours: 3)),
        ),
        EloMatchRecord(
          matchId: 'm_03',
          leagueId: 'lg_wt_ranked',
          opponentId: 'field_wt',
          opponentName: 'Peleton WorldTour Elite',
          eloBefore: 1563,
          eloAfter: 1551,
          delta: -12,
          placement: 5,
          fieldSize: 12,
          recordedAt: now.subtract(const Duration(days: 2, hours: 8)),
        ),
        EloMatchRecord(
          matchId: 'm_04',
          leagueId: 'lg_alpes_friends',
          opponentId: 'fr_kasia',
          opponentName: 'Kasia W. (Dolomity Pro)',
          eloBefore: 1540,
          eloAfter: 1563,
          delta: 23,
          placement: 2,
          fieldSize: 6,
          recordedAt: now.subtract(const Duration(days: 4)),
        ),
      ],
    );
  }

  static List<OnlineLeagueModel> defaultLeagues() {
    final now = DateTime.utc(2026, 7, 14, 12, 0);
    const alpeWeather = WeatherConditionSnapshot(
      weatherSeed: 20260714,
      temperatureC: 21.5,
      windSpeedKmh: 14.0,
      windDirectionDegrees: 225.0,
      precipitationMmPerHour: 0.0,
      humidityPercent: 48.0,
      roadWetness: 0.0,
      airDensityKgM3: 1.06,
      weatherLabel: 'Alpejskie Słońce',
    );
    const galibierWeather = WeatherConditionSnapshot(
      weatherSeed: 20260715,
      temperatureC: 11.0,
      windSpeedKmh: 26.0,
      windDirectionDegrees: 180.0,
      precipitationMmPerHour: 0.4,
      humidityPercent: 68.0,
      roadWetness: 0.15,
      airDensityKgM3: 0.96,
      weatherLabel: 'Chłodny Wiatr Przełęczy',
    );
    const roubaixWeather = WeatherConditionSnapshot(
      weatherSeed: 20260412,
      temperatureC: 14.0,
      windSpeedKmh: 34.0,
      windDirectionDegrees: 290.0,
      precipitationMmPerHour: 2.8,
      humidityPercent: 84.0,
      roadWetness: 0.65,
      airDensityKgM3: 1.22,
      weatherLabel: 'Deszcz i Wiatr Boczny',
    );

    return [
      OnlineLeagueModel(
        leagueId: 'lg_alpes_friends',
        name: 'Liga Przyjaciół: Alpejski Puchar',
        description:
            'Cotygodniowa rywalizacja znajomych na kultowych przełęczach Tour de France z identyczną pogodą.',
        format: LeagueFormat.seasonPoints,
        privacy: LeaguePrivacy.friendsOnly,
        status: LeagueStatus.active,
        inviteCode: 'ALPE-2026',
        seasonNumber: 4,
        maxParticipants: 8,
        createdAt: now.subtract(const Duration(days: 14)),
        startsAt: now.subtract(const Duration(days: 10)),
        endsAt: now.add(const Duration(days: 18)),
        draftStatus: LeagueDraftStatus.completed,
        participants: [
          LeagueParticipantEntry(
            participantId: 'player_local',
            displayName: 'Ty (Dyrektor Sportowy)',
            teamName: 'Vistula Carbon Pro',
            teamBadgeHex: '#D4AF37',
            eloAtJoin: 1540,
            currentElo: 1584,
            role: LeagueMemberRole.commissioner,
            totalPoints: 62,
            stageWins: 2,
            podiumCount: 3,
            totalGcTimeSeconds: 14820.4,
            draftedRiderIds: const ['r_01', 'r_04', 'r_08', 'r_11', 'r_14', 'r_19'],
            isReady: true,
            joinedAt: now.subtract(const Duration(days: 14)),
            lastSyncedAt: now.subtract(const Duration(hours: 1)),
          ),
          LeagueParticipantEntry(
            participantId: 'fr_marek',
            displayName: 'Marek Kowalski',
            teamName: 'Alpejskie Wilki',
            teamBadgeHex: '#38BDF8',
            eloAtJoin: 1610,
            currentElo: 1602,
            role: LeagueMemberRole.coCommissioner,
            totalPoints: 58,
            stageWins: 1,
            podiumCount: 3,
            totalGcTimeSeconds: 14842.9,
            draftedRiderIds: const ['r_02', 'r_05', 'r_09', 'r_12', 'r_15', 'r_20'],
            isReady: true,
            joinedAt: now.subtract(const Duration(days: 13)),
            lastSyncedAt: now.subtract(const Duration(hours: 2)),
          ),
          LeagueParticipantEntry(
            participantId: 'fr_kasia',
            displayName: 'Katarzyna Wiśniewska',
            teamName: 'Dolomity Racing',
            teamBadgeHex: '#10B981',
            eloAtJoin: 1495,
            currentElo: 1528,
            role: LeagueMemberRole.participant,
            totalPoints: 45,
            stageWins: 0,
            podiumCount: 2,
            totalGcTimeSeconds: 14910.2,
            draftedRiderIds: const ['r_03', 'r_06', 'r_10', 'r_13', 'r_16', 'r_21'],
            isReady: true,
            joinedAt: now.subtract(const Duration(days: 12)),
            lastSyncedAt: now.subtract(const Duration(hours: 5)),
          ),
          LeagueParticipantEntry(
            participantId: 'fr_piotr',
            displayName: 'Piotr Zieliński',
            teamName: 'Tatry Cycling Lab',
            teamBadgeHex: '#8E4A49',
            eloAtJoin: 1410,
            currentElo: 1398,
            role: LeagueMemberRole.participant,
            totalPoints: 34,
            stageWins: 0,
            podiumCount: 1,
            totalGcTimeSeconds: 15022.6,
            draftedRiderIds: const ['r_07', 'r_17', 'r_18', 'r_22', 'r_23', 'r_24'],
            isReady: true,
            joinedAt: now.subtract(const Duration(days: 12)),
            lastSyncedAt: now.subtract(const Duration(hours: 9)),
          ),
        ],
        schedule: [
          LeagueStageScheduleEntry(
            stageIndex: 1,
            stageId: 'st_alpe_dhuez',
            stageName: 'Bourg-d\'Oisans — Alpe d\'Huez (21 zakrętów)',
            distanceKm: 138.4,
            elevationGainM: 3820,
            lockedWeather: alpeWeather,
            opensAt: now.subtract(const Duration(days: 10)),
            closesAt: now.subtract(const Duration(days: 3)),
            results: [
              LeagueStageResultEntry(
                participantId: 'player_local',
                finishTimeSeconds: 13140.2,
                gapToWinnerSeconds: 0.0,
                averageWatts: 356,
                normalizedPower: 388,
                averageSpeedKmh: 37.9,
                pointsEarned: 25,
                weatherHash: alpeWeather.weatherHash,
                verificationChecksum: 'CHK_ALPE_01',
                submittedAt: now.subtract(const Duration(days: 4)),
              ),
              LeagueStageResultEntry(
                participantId: 'fr_marek',
                finishTimeSeconds: 13158.7,
                gapToWinnerSeconds: 18.5,
                averageWatts: 351,
                normalizedPower: 382,
                averageSpeedKmh: 37.8,
                pointsEarned: 18,
                weatherHash: alpeWeather.weatherHash,
                verificationChecksum: 'CHK_ALPE_02',
                submittedAt: now.subtract(const Duration(days: 4)),
              ),
              LeagueStageResultEntry(
                participantId: 'fr_kasia',
                finishTimeSeconds: 13205.0,
                gapToWinnerSeconds: 64.8,
                averageWatts: 339,
                normalizedPower: 371,
                averageSpeedKmh: 37.7,
                pointsEarned: 15,
                weatherHash: alpeWeather.weatherHash,
                verificationChecksum: 'CHK_ALPE_03',
                submittedAt: now.subtract(const Duration(days: 3)),
              ),
            ],
          ),
          LeagueStageScheduleEntry(
            stageIndex: 2,
            stageId: 'st_galibier',
            stageName: 'Briançon — Col du Galibier (2642 m)',
            distanceKm: 156.0,
            elevationGainM: 4190,
            lockedWeather: galibierWeather,
            opensAt: now.subtract(const Duration(days: 2)),
            closesAt: now.add(const Duration(days: 5)),
            results: [
              LeagueStageResultEntry(
                participantId: 'fr_marek',
                finishTimeSeconds: 15110.5,
                gapToWinnerSeconds: 0.0,
                averageWatts: 342,
                normalizedPower: 379,
                averageSpeedKmh: 37.1,
                pointsEarned: 25,
                weatherHash: galibierWeather.weatherHash,
                verificationChecksum: 'CHK_GAL_01',
                submittedAt: now.subtract(const Duration(hours: 8)),
              ),
            ],
          ),
        ],
      ),
      OnlineLeagueModel(
        leagueId: 'lg_flanders_h2h',
        name: 'Puchar Bruków Flandrii H2H',
        description:
            'Pojedynki 1v1 na sektorach bruku 5★ przy bocznym wietrze 34 km/h i przelotnym deszczu.',
        format: LeagueFormat.headToHead,
        privacy: LeaguePrivacy.publicRanked,
        status: LeagueStatus.active,
        inviteCode: 'COBBLE-5',
        seasonNumber: 2,
        maxParticipants: 4,
        createdAt: now.subtract(const Duration(days: 7)),
        startsAt: now.subtract(const Duration(days: 5)),
        endsAt: now.add(const Duration(days: 9)),
        draftStatus: LeagueDraftStatus.completed,
        participants: [
          LeagueParticipantEntry(
            participantId: 'player_local',
            displayName: 'Ty (Dyrektor Sportowy)',
            teamName: 'Vistula Carbon Pro',
            teamBadgeHex: '#D4AF37',
            eloAtJoin: 1551,
            currentElo: 1584,
            role: LeagueMemberRole.participant,
            totalPoints: 43,
            stageWins: 1,
            podiumCount: 2,
            totalGcTimeSeconds: 19420.0,
            isReady: true,
            joinedAt: now.subtract(const Duration(days: 7)),
          ),
          LeagueParticipantEntry(
            participantId: 'fr_tomasz',
            displayName: 'Tomasz Nowak',
            teamName: 'Flandria Aero Squad',
            teamBadgeHex: '#00E5FF',
            eloAtJoin: 1640,
            currentElo: 1628,
            role: LeagueMemberRole.commissioner,
            totalPoints: 40,
            stageWins: 1,
            podiumCount: 2,
            totalGcTimeSeconds: 19438.4,
            isReady: true,
            joinedAt: now.subtract(const Duration(days: 7)),
          ),
        ],
        schedule: [
          LeagueStageScheduleEntry(
            stageIndex: 1,
            stageId: 'st_arenberg',
            stageName: 'Compiègne — Trouée d\'Arenberg — Roubaix',
            distanceKm: 257.2,
            elevationGainM: 1420,
            lockedWeather: roubaixWeather,
            opensAt: now.subtract(const Duration(days: 4)),
            closesAt: now.add(const Duration(days: 3)),
          ),
        ],
      ),
      OnlineLeagueModel(
        leagueId: 'lg_gt_open',
        name: 'WorldTour Open: Grand Tour Cup',
        description:
            'Otwarta liga rankingowa ELO w formacie GC. Trwa nabór składów przed startem prologu.',
        format: LeagueFormat.grandTourCup,
        privacy: LeaguePrivacy.publicRanked,
        status: LeagueStatus.recruiting,
        inviteCode: 'WT-GRAND-26',
        seasonNumber: 1,
        maxParticipants: 16,
        createdAt: now.subtract(const Duration(days: 2)),
        startsAt: now.add(const Duration(days: 3)),
        endsAt: now.add(const Duration(days: 31)),
        draftStatus: LeagueDraftStatus.notStarted,
        participants: [
          LeagueParticipantEntry(
            participantId: 'fr_lucas',
            displayName: 'Lucas Moreau',
            teamName: 'Équipe Azur',
            teamBadgeHex: '#38BDF8',
            eloAtJoin: 1820,
            currentElo: 1820,
            role: LeagueMemberRole.commissioner,
            isReady: true,
            joinedAt: now.subtract(const Duration(days: 2)),
          ),
          LeagueParticipantEntry(
            participantId: 'fr_elena',
            displayName: 'Elena Conti',
            teamName: 'Milano Corsa',
            teamBadgeHex: '#10B981',
            eloAtJoin: 1745,
            currentElo: 1745,
            role: LeagueMemberRole.participant,
            isReady: true,
            joinedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        schedule: [
          LeagueStageScheduleEntry(
            stageIndex: 1,
            stageId: 'st_tt_prolog',
            stageName: 'Etap 1: Prolog ITT w Bazylei (14.2 km)',
            distanceKm: 14.2,
            elevationGainM: 115,
            lockedWeather: alpeWeather,
            opensAt: now.add(const Duration(days: 3)),
            closesAt: now.add(const Duration(days: 6)),
          ),
        ],
      ),
    ];
  }

  static List<GhostChallengeModel> defaultWeeklyChallenges() {
    final now = DateTime.utc(2026, 7, 14, 12, 0);
    const alpeWeather = WeatherConditionSnapshot(
      weatherSeed: 20260721,
      temperatureC: 19.0,
      windSpeedKmh: 11.0,
      windDirectionDegrees: 210.0,
      precipitationMmPerHour: 0.0,
      humidityPercent: 50.0,
      roadWetness: 0.0,
      airDensityKgM3: 1.07,
      weatherLabel: 'Czyste Niebo',
    );
    const roubaixWeather = WeatherConditionSnapshot(
      weatherSeed: 20260413,
      temperatureC: 13.5,
      windSpeedKmh: 36.0,
      windDirectionDegrees: 270.0,
      precipitationMmPerHour: 2.2,
      humidityPercent: 82.0,
      roadWetness: 0.55,
      airDensityKgM3: 1.22,
      weatherLabel: 'Mokry Bruk',
    );
    const ittWeather = WeatherConditionSnapshot(
      weatherSeed: 20261018,
      temperatureC: 24.0,
      windSpeedKmh: 8.0,
      windDirectionDegrees: 90.0,
      precipitationMmPerHour: 0.0,
      humidityPercent: 42.0,
      roadWetness: 0.0,
      airDensityKgM3: 1.18,
      weatherLabel: 'Idealne Warunki ITT',
    );

    final alpeTelemetry = List<GhostTelemetrySample>.generate(15, (i) {
      final frac = i / 14.0;
      return GhostTelemetrySample(
        elapsedSeconds: frac * 2318.0,
        distanceKm: frac * 13.8,
        speedKmh: 21.4 + math.sin(frac * math.pi * 3) * 2.1,
        powerWatts: 398 + math.cos(frac * math.pi * 2) * 24.0,
        heartRateBpm: (168 + frac * 19).round(),
        cadenceRpm: 84 + (i % 5),
        elevationM: 740.0 + frac * 1110.0,
        gradientPercent: 7.9 + math.sin(frac * 5) * 1.8,
      );
    });

    final roubaixTelemetry = List<GhostTelemetrySample>.generate(12, (i) {
      final frac = i / 11.0;
      return GhostTelemetrySample(
        elapsedSeconds: frac * 1980.0,
        distanceKm: frac * 24.5,
        speedKmh: 44.5 - (i % 3 == 0 ? 4.8 : 0.0),
        powerWatts: 375 + (i % 3 == 0 ? 65.0 : 0.0),
        heartRateBpm: (162 + frac * 22).round(),
        cadenceRpm: 92 - (i % 3) * 4,
        elevationM: 28.0 + math.sin(frac * 4) * 12.0,
        gradientPercent: (i % 4 == 0) ? 1.5 : 0.2,
      );
    });

    return [
      GhostChallengeModel(
        challengeId: 'wk_alpe_kom',
        title: 'Wyzwanie Tygodnia #29: Wspinaczka na Alpe d\'Huez',
        creatorId: 'ghost_tadej',
        creatorName: 'Duch Tygodnia (WorldTour AI)',
        stageId: 'st_alpe_138',
        stageName: 'Alpe d\'Huez — 21 Zakrętów',
        distanceKm: 13.8,
        elevationGainM: 1110,
        weatherSnapshot: alpeWeather,
        targetFinishTimeSeconds: 2318.4,
        targetAverageWatts: 404.0,
        targetTelemetry: alpeTelemetry,
        difficulty: GhostChallengeDifficulty.proPeloton,
        status: GhostChallengeStatus.open,
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 5)),
        eloStake: 32,
        attempts: [
          GhostAttemptResult(
            attemptId: 'att_01',
            challengerId: 'player_local',
            challengerName: 'Vistula Carbon Pro',
            finishTimeSeconds: 2331.8,
            averageWatts: 396.0,
            normalizedPower: 412.0,
            maxSpeedKmh: 31.2,
            weatherHash: alpeWeather.weatherHash,
            deltaVsTargetSeconds: 13.4,
            isVictory: false,
            completedAt: now.subtract(const Duration(hours: 14)),
          ),
        ],
      ),
      GhostChallengeModel(
        challengeId: 'wk_arenberg_cobbles',
        title: 'Lasek Arenberg w Deszczu — Piekło Północy',
        creatorId: 'fr_tomasz',
        creatorName: 'Tomasz Nowak (Znajomy)',
        stageId: 'st_arenberg_24',
        stageName: 'Wallers-Arenberg (Sektory 5★)',
        distanceKm: 24.5,
        elevationGainM: 145,
        weatherSnapshot: roubaixWeather,
        targetFinishTimeSeconds: 1980.0,
        targetAverageWatts: 389.0,
        targetTelemetry: roubaixTelemetry,
        difficulty: GhostChallengeDifficulty.competitive,
        status: GhostChallengeStatus.accepted,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 6)),
        eloStake: 24,
      ),
      GhostChallengeModel(
        challengeId: 'wk_itt_chrono',
        title: 'Chrono des Nations: 40 km ITT',
        creatorId: 'fr_marek',
        creatorName: 'Marek Kowalski (Znajomy)',
        stageId: 'st_itt_40',
        stageName: 'Les Herbiers — 40 km Płaska Czasówka',
        distanceKm: 40.0,
        elevationGainM: 290,
        weatherSnapshot: ittWeather,
        targetFinishTimeSeconds: 2742.5,
        targetAverageWatts: 418.0,
        targetTelemetry: alpeTelemetry,
        difficulty: GhostChallengeDifficulty.legendary,
        status: GhostChallengeStatus.completed,
        createdAt: now.subtract(const Duration(days: 4)),
        expiresAt: now.add(const Duration(days: 3)),
        eloStake: 40,
        attempts: [
          GhostAttemptResult(
            attemptId: 'att_02',
            challengerId: 'player_local',
            challengerName: 'Vistula Carbon Pro',
            finishTimeSeconds: 2736.1,
            averageWatts: 421.0,
            normalizedPower: 425.0,
            maxSpeedKmh: 58.4,
            weatherHash: ittWeather.weatherHash,
            deltaVsTargetSeconds: -6.4,
            isVictory: true,
            completedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
    ];
  }
}

/// Ekran Centrum Lig Online, tabel ligowych ze znajomymi i wyzwań tygodnia.
class MultiplayerLeaguesAndChallengesScreen extends ConsumerStatefulWidget {
  final List<OnlineLeagueModel>? initialLeagues;
  final List<GhostChallengeModel>? initialChallenges;
  final EloRatingProfile? initialPlayerProfile;
  final MultiplayerHubTab initialTab;
  final bool isReadOnly;
  final ValueChanged<GhostChallengeModel>? onLaunchGhostRace;
  final ValueChanged<OnlineLeagueModel>? onLaunchLeagueStage;
  final VoidCallback? onBack;

  const MultiplayerLeaguesAndChallengesScreen({
    super.key,
    this.initialLeagues,
    this.initialChallenges,
    this.initialPlayerProfile,
    this.initialTab = MultiplayerHubTab.leagues,
    this.isReadOnly = false,
    this.onLaunchGhostRace,
    this.onLaunchLeagueStage,
    this.onBack,
  });

  @override
  ConsumerState<MultiplayerLeaguesAndChallengesScreen> createState() =>
      _MultiplayerLeaguesAndChallengesScreenState();
}

class _MultiplayerLeaguesAndChallengesScreenState
    extends ConsumerState<MultiplayerLeaguesAndChallengesScreen> {
  late MultiplayerHubTab _activeTab;
  MultiplayerLeagueFilter _leagueFilter = MultiplayerLeagueFilter.all;
  GhostChallengeDifficulty? _challengeDifficultyFilter;
  String _searchQuery = '';

  late List<OnlineLeagueModel> _leagues;
  late List<GhostChallengeModel> _challenges;
  late EloRatingProfile _playerProfile;
  String? _selectedLeagueId;
  String? _selectedChallengeId;
  String? _feedbackBanner;
  bool _feedbackIsError = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _importPayloadController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _leagues = List<OnlineLeagueModel>.from(
      widget.initialLeagues ?? MultiplayerLeaguesDemoCatalog.defaultLeagues(),
    );
    _challenges = List<GhostChallengeModel>.from(
      widget.initialChallenges ??
          MultiplayerLeaguesDemoCatalog.defaultWeeklyChallenges(),
    );
    _playerProfile = widget.initialPlayerProfile ??
        MultiplayerLeaguesDemoCatalog.defaultPlayerProfile();
    _selectedLeagueId = _leagues.isNotEmpty ? _leagues.first.leagueId : null;
    _selectedChallengeId =
        _challenges.isNotEmpty ? _challenges.first.challengeId : null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final syncState = ref.read(asyncMultiplayerLeagueSyncProvider);
      if (syncState.activeLeague == null && _leagues.isNotEmpty) {
        ref.read(asyncMultiplayerLeagueSyncProvider.notifier).loadLeague(
              league: _leagues.first,
              ghostChallenges: _challenges,
              playerEloProfile: _playerProfile,
            );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _importPayloadController.dispose();
    super.dispose();
  }

  OnlineLeagueModel? get _selectedLeague {
    if (_leagues.isEmpty) return null;
    for (final league in _leagues) {
      if (league.leagueId == _selectedLeagueId) return league;
    }
    return _leagues.first;
  }

  GhostChallengeModel? get _selectedChallenge {
    if (_challenges.isEmpty) return null;
    for (final challenge in _challenges) {
      if (challenge.challengeId == _selectedChallengeId) return challenge;
    }
    return _challenges.first;
  }

  List<OnlineLeagueModel> get _filteredLeagues {
    final query = _searchQuery.trim().toLowerCase();
    return _leagues.where((league) {
      final matchesFilter = switch (_leagueFilter) {
        MultiplayerLeagueFilter.all => true,
        MultiplayerLeagueFilter.friendsOnly =>
          league.privacy == LeaguePrivacy.friendsOnly ||
              league.privacy == LeaguePrivacy.inviteCode,
        MultiplayerLeagueFilter.publicRanked =>
          league.privacy == LeaguePrivacy.publicRanked,
        MultiplayerLeagueFilter.activeOnly =>
          league.status == LeagueStatus.active ||
              league.status == LeagueStatus.drafting,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return league.name.toLowerCase().contains(query) ||
          league.inviteCode.toLowerCase().contains(query) ||
          league.format.label.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  List<GhostChallengeModel> get _filteredChallenges {
    final filter = _challengeDifficultyFilter;
    if (filter == null) return _challenges;
    return _challenges
        .where((c) => c.difficulty == filter)
        .toList(growable: false);
  }

  void _showFeedback(String message, {bool isError = false}) {
    setState(() {
      _feedbackBanner = message;
      _feedbackIsError = isError;
    });
  }

  void _selectLeague(OnlineLeagueModel league) {
    setState(() {
      _selectedLeagueId = league.leagueId;
    });
    ref.read(asyncMultiplayerLeagueSyncProvider.notifier).loadLeague(
          league: league,
          ghostChallenges: _challenges,
          playerEloProfile: _playerProfile,
        );
  }

  void _joinSelectedLeague(OnlineLeagueModel league) {
    if (widget.isReadOnly || !league.canJoin) return;
    final alreadyJoined = league.getParticipantById(_playerProfile.playerId) !=
        null;
    if (alreadyJoined) {
      _showFeedback('Już uczestniczysz w lidze "${league.name}".');
      return;
    }
    final updated = league.addParticipant(
      LeagueParticipantEntry(
        participantId: _playerProfile.playerId,
        displayName: _playerProfile.displayName,
        teamName: 'Vistula Carbon Pro',
        teamBadgeHex: '#D4AF37',
        eloAtJoin: _playerProfile.currentElo,
        currentElo: _playerProfile.currentElo,
        role: LeagueMemberRole.participant,
        isReady: true,
        joinedAt: DateTime.now().toUtc(),
      ),
    );
    setState(() {
      _leagues = _leagues
          .map((l) => l.leagueId == updated.leagueId ? updated : l)
          .toList(growable: false);
    });
    _selectLeague(updated);
    _showFeedback('Dołączono do ligi "${updated.name}"!');
  }

  void _submitSimulatedStageResult(OnlineLeagueModel league) {
    if (widget.isReadOnly) return;
    final stage = league.activeStage;
    if (stage == null) {
      _showFeedback('Brak aktywnego etapu w wybranej lidze.', isError: true);
      return;
    }
    final entry = LeagueStageResultEntry(
      participantId: _playerProfile.playerId,
      finishTimeSeconds: 13420.0 + (stage.stageIndex * 115.0),
      averageWatts: 362.0,
      normalizedPower: 391.0,
      averageSpeedKmh: 38.4,
      weatherHash: stage.lockedWeather.weatherHash,
      submittedAt: DateTime.now().toUtc(),
    );
    final updated = league.recordStageResult(stage.stageIndex, entry);
    setState(() {
      _leagues = _leagues
          .map((l) => l.leagueId == updated.leagueId ? updated : l)
          .toList(growable: false);
    });
    ref.read(asyncMultiplayerLeagueSyncProvider.notifier).submitStageResult(
          stageIndex: stage.stageIndex,
          entry: entry,
        );
    _showFeedback(
      'Zapisano wynik etapu "${stage.stageName}" (zgodność pogody ${stage.lockedWeather.weatherHash}).',
    );
  }

  void _recordGhostAttempt(GhostChallengeModel challenge) {
    if (widget.isReadOnly) return;
    final bestPrev = challenge.bestAttempt;
    final baseTime = bestPrev?.finishTimeSeconds ??
        (challenge.targetFinishTimeSeconds + 8.0);
    final newTime = math.max(60.0, baseTime - 11.2);
    final delta = newTime - challenge.targetFinishTimeSeconds;
    final isVictory = delta <= 0.0;

    final attempt = GhostAttemptResult(
      attemptId: 'att_${DateTime.now().millisecondsSinceEpoch}',
      challengerId: _playerProfile.playerId,
      challengerName: 'Vistula Carbon Pro',
      finishTimeSeconds: newTime,
      averageWatts: challenge.targetAverageWatts + (isVictory ? 6.0 : -4.0),
      normalizedPower: challenge.targetAverageWatts + 18.0,
      maxSpeedKmh: 56.2,
      weatherHash: challenge.weatherSnapshot.weatherHash,
      deltaVsTargetSeconds: delta,
      isVictory: isVictory,
      completedAt: DateTime.now().toUtc(),
    );

    final updatedChallenge = challenge.recordAttempt(attempt);
    final eloDelta = EloCalculator.calculateHeadToHeadDelta(
      playerElo: _playerProfile.currentElo,
      opponentElo: 1560,
      actualScore: isVictory ? 1.0 : 0.0,
      matchesPlayed: _playerProfile.matchesPlayed,
      multiplier: challenge.difficulty.eloMultiplier,
    );

    final matchRecord = EloMatchRecord(
      matchId: 'gm_${DateTime.now().millisecondsSinceEpoch}',
      leagueId: challenge.challengeId,
      opponentId: challenge.creatorId,
      opponentName: challenge.creatorName,
      eloBefore: _playerProfile.currentElo,
      eloAfter: _playerProfile.currentElo + eloDelta,
      delta: eloDelta,
      placement: isVictory ? 1 : 2,
      fieldSize: 2,
      recordedAt: DateTime.now().toUtc(),
    );

    setState(() {
      _challenges = _challenges
          .map((c) => c.challengeId == updatedChallenge.challengeId
              ? updatedChallenge
              : c)
          .toList(growable: false);
      _playerProfile = _playerProfile.applyMatchResult(matchRecord);
    });

    _showFeedback(
      isVictory
          ? 'Pokonano ducha! Czas ${_formatDuration(newTime)} (${delta.toStringAsFixed(1)} s), ELO ${eloDelta >= 0 ? '+$eloDelta' : '$eloDelta'}.'
          : 'Zapisano próbę ${_formatDuration(newTime)} (+${delta.toStringAsFixed(1)} s do ducha).',
    );
  }

  Future<void> _openCreateLeagueDialog() async {
    if (widget.isReadOnly) return;
    final nameController = TextEditingController(text: 'Puchar Przyjaciół 2026');
    var selectedFormat = LeagueFormat.seasonPoints;
    var selectedPrivacy = LeaguePrivacy.friendsOnly;
    var maxParticipants = 8;
    var enforceWeather = true;

    final created = await showDialog<OnlineLeagueModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder, width: 1),
              ),
              title: const Text(
                'Utwórz Nową Ligę Online',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: nameController,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Nazwa ligi'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LeagueFormat>(
                        initialValue: selectedFormat,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Format rozgrywek'),
                        items: LeagueFormat.values
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(f.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedFormat = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LeaguePrivacy>(
                        initialValue: selectedPrivacy,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration('Prywatność'),
                        items: LeaguePrivacy.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedPrivacy = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Limit graczy',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownButton<int>(
                            value: maxParticipants,
                            dropdownColor: AppColors.surfaceLight,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textPrimary,
                            ),
                            items: const [2, 4, 8, 12, 16]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v graczy'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() => maxParticipants = v);
                              }
                            },
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Wymuszaj identyczną pogodę',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        activeThumbColor: AppColors.goldAccent,
                        value: enforceWeather,
                        onChanged: (v) =>
                            setModalState(() => enforceWeather = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Anuluj',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: AppColors.background,
                  ),
                  onPressed: () {
                    final trimmed = nameController.text.trim();
                    if (trimmed.isEmpty) return;
                    final now = DateTime.now().toUtc();
                    const defaultWeather = WeatherConditionSnapshot(
                      weatherSeed: 20260801,
                      temperatureC: 20.0,
                      windSpeedKmh: 12.0,
                      windDirectionDegrees: 180.0,
                      precipitationMmPerHour: 0.0,
                      humidityPercent: 52.0,
                      roadWetness: 0.0,
                      airDensityKgM3: 1.18,
                      weatherLabel: 'Pogodnie',
                    );
                    final newLeague = OnlineLeagueModel(
                      leagueId: 'lg_${now.millisecondsSinceEpoch}',
                      name: trimmed,
                      description: 'Liga utworzona przez gracza w trybie Online.',
                      format: selectedFormat,
                      privacy: selectedPrivacy,
                      status: LeagueStatus.recruiting,
                      inviteCode:
                          'PPM-${(now.millisecondsSinceEpoch % 9000) + 1000}',
                      maxParticipants: maxParticipants,
                      createdAt: now,
                      startsAt: now,
                      endsAt: now.add(const Duration(days: 21)),
                      scoringRules: LeagueScoringRules(
                        enforceIdenticalWeather: enforceWeather,
                      ),
                      participants: [
                        LeagueParticipantEntry(
                          participantId: _playerProfile.playerId,
                          displayName: _playerProfile.displayName,
                          teamName: 'Vistula Carbon Pro',
                          teamBadgeHex: '#D4AF37',
                          eloAtJoin: _playerProfile.currentElo,
                          currentElo: _playerProfile.currentElo,
                          role: LeagueMemberRole.commissioner,
                          isReady: true,
                          joinedAt: now,
                        ),
                      ],
                      schedule: [
                        LeagueStageScheduleEntry(
                          stageIndex: 1,
                          stageId: 'st_custom_01',
                          stageName: 'Etap 1: Klasyk Otwarcia',
                          distanceKm: 164.0,
                          elevationGainM: 2150,
                          lockedWeather: defaultWeather,
                          opensAt: now,
                          closesAt: now.add(const Duration(days: 7)),
                        ),
                      ],
                    );
                    Navigator.of(dialogContext).pop(newLeague);
                  },
                  child: const Text(
                    'Utwórz Ligę',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    if (created != null && mounted) {
      setState(() {
        _leagues = [created, ..._leagues];
      });
      _selectLeague(created);
      _showFeedback(
        'Utworzono ligę "${created.name}" (kod: ${created.inviteCode}).',
      );
    }
  }

  Future<void> _openJoinByCodeDialog() async {
    if (widget.isReadOnly) return;
    final codeController = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
          title: const Text(
            'Dołącz przez Kod Zaproszenia',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration('np. WT-GRAND-26 lub ALPE-2026'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Anuluj',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: AppColors.background,
              ),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(codeController.text.trim()),
              child: const Text(
                'Dołącz',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    codeController.dispose();

    if (submitted == null || submitted.isEmpty || !mounted) return;
    final upper = submitted.toUpperCase();
    final matchIndex = _leagues.indexWhere(
      (l) => l.inviteCode.toUpperCase() == upper,
    );
    if (matchIndex != -1) {
      final matched = _leagues[matchIndex];
      _selectLeague(matched);
      _joinSelectedLeague(matched);
      return;
    }

    _showFeedback(
      'Nie znaleziono ligi o kodzie "$upper". Zaimportuj paczkę .ppmleague w zakładce Draft & .ppmleague.',
      isError: true,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(asyncMultiplayerLeagueSyncProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 680;
            final isDesktop = width >= 1180;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopHeader(isMobile),
                _buildTabBar(isMobile),
                if (_feedbackBanner != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 12 : 20,
                      10,
                      isMobile ? 12 : 20,
                      0,
                    ),
                    child: _buildFeedbackBanner(),
                  ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: switch (_activeTab) {
                      MultiplayerHubTab.leagues => _buildLeaguesTab(
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                      MultiplayerHubTab.weeklyChallenges =>
                        _buildWeeklyChallengesTab(
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                      MultiplayerHubTab.syncAndDraft => _buildSyncAndDraftTab(
                          syncState: syncState,
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                      MultiplayerHubTab.eloRanking => _buildEloRankingTab(
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isMobile) {
    final tier = _playerProfile.divisionTier;
    final tierColor = _parseHexColor(tier.badgeColorHex, AppColors.goldAccent);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onBack != null) ...[
                _HubActionButton(
                  icon: Icons.arrow_back_rounded,
                  label: isMobile ? '' : 'Powrót',
                  onPressed: widget.onBack,
                  accentColor: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldAccent, width: 1),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Centrum Lig Online & Wyzwań',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ligi ze znajomymi, asynchroniczne duchy i paczki .ppmleague',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tierColor.withValues(alpha: 0.55)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 15, color: tierColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ELO ${_playerProfile.currentElo} • ${tier.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tierColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _HubActionButton(
                icon: Icons.vpn_key_outlined,
                label: 'Kod',
                isDisabled: widget.isReadOnly,
                onPressed: _openJoinByCodeDialog,
                accentColor: AppColors.accentBlue,
              ),
              _HubActionButton(
                icon: Icons.add_circle_outline,
                label: 'Nowa Liga',
                isDisabled: widget.isReadOnly,
                onPressed: _openCreateLeagueDialog,
                accentColor: AppColors.goldAccent,
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: MultiplayerHubTab.values.map((tab) {
            final isSelected = tab == _activeTab;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _HubTabChip(
                label: tab.label,
                icon: tab.icon,
                isSelected: isSelected,
                onTap: () => setState(() => _activeTab = tab),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner() {
    final color =
        _feedbackIsError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(
            _feedbackIsError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _feedbackBanner ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _feedbackBanner = null),
            icon: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaguesTab({
    required bool isMobile,
    required bool isDesktop,
  }) {
    final filtered = _filteredLeagues;
    final selected = _selectedLeague;

    return SingleChildScrollView(
      key: const ValueKey('tab_leagues'),
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLeagueFiltersBar(isMobile),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _buildEmptyStateCard(
              icon: Icons.search_off_rounded,
              title: 'Brak pasujących lig',
              subtitle:
                  'Zmień filtr wyszukiwania lub utwórz własną ligę dla znajomych.',
              actionLabel: 'Resetuj filtry',
              onAction: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _leagueFilter = MultiplayerLeagueFilter.all;
                });
              },
            )
          else if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildLeaguesList(filtered, selected),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: selected != null
                      ? _buildLeagueDetailPanel(selected, isMobile: false)
                      : const SizedBox.shrink(),
                ),
              ],
            )
          else ...[
            _buildLeaguesList(filtered, selected),
            if (selected != null) ...[
              const SizedBox(height: 16),
              _buildLeagueDetailPanel(selected, isMobile: isMobile),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLeagueFiltersBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MultiplayerLeagueFilter.values.map((filter) {
              return _HubTabChip(
                label: filter.label,
                isSelected: _leagueFilter == filter,
                onTap: () => setState(() => _leagueFilter = filter),
              );
            }).toList(),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 260,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Szukaj ligi lub kodu...',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.goldAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaguesList(
    List<OnlineLeagueModel> leagues,
    OnlineLeagueModel? selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: leagues.map((league) {
        final isSelected = selected?.leagueId == league.leagueId;
        final statusColor = _leagueStatusColor(league.status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InteractiveCard(
            isSelected: isSelected,
            onTap: () => _selectLeague(league),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        league.status.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        league.format.shortLabel,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${league.participants.length}/${league.maxParticipants} graczy',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  league.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  league.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      league.privacy == LeaguePrivacy.publicRanked
                          ? Icons.public
                          : Icons.group_outlined,
                      size: 14,
                      color: AppColors.accentBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        league.privacy.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (league.inviteCode.isNotEmpty)
                      Text(
                        'Kod: ${league.inviteCode}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeagueDetailPanel(
    OnlineLeagueModel league, {
    required bool isMobile,
  }) {
    final standings = league.sortedStandings;
    final isJoined = league.getParticipantById(_playerProfile.playerId) != null;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    league.name,
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
                    'Sezon #${league.seasonNumber} • ${league.format.label} • ${league.draftStatus.label}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!isJoined && league.canJoin)
                    _HubActionButton(
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'Dołącz do Ligi',
                      isDisabled: widget.isReadOnly,
                      onPressed: () => _joinSelectedLeague(league),
                      accentColor: AppColors.statusSuccess,
                      filled: true,
                    ),
                  if (isJoined && league.activeStage != null)
                    _HubActionButton(
                      icon: Icons.play_arrow_rounded,
                      label: widget.onLaunchLeagueStage != null
                          ? 'Jedź Etap Ligi'
                          : 'Wyślij Wynik Etapu',
                      isDisabled: widget.isReadOnly,
                      onPressed: () {
                        if (widget.onLaunchLeagueStage != null) {
                          widget.onLaunchLeagueStage!(league);
                        } else {
                          _submitSimulatedStageResult(league);
                        }
                      },
                      accentColor: AppColors.goldAccent,
                      filled: true,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'TABELA LIGOWA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (standings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Brak uczestników w tej lidze.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: List.generate(standings.length, (index) {
                final entry = standings[index];
                final isPlayer = entry.participantId == _playerProfile.playerId;
                final badgeColor = _parseHexColor(
                  entry.teamBadgeHex,
                  AppColors.primaryAccent,
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isPlayer
                        ? AppColors.goldAccent.withValues(alpha: 0.1)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPlayer
                          ? AppColors.goldAccent.withValues(alpha: 0.6)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: index == 0
                                ? AppColors.goldAccent
                                : AppColors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 24,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${entry.teamName} • ELO ${entry.currentElo}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.totalPoints} pkt',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            'W: ${entry.stageWins} • Pod: ${entry.podiumCount}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          const SizedBox(height: 16),
          const Text(
            'HARMONOGRAM ETAPÓW (LOCKED WEATHER)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...league.schedule.map((stage) {
            final submittedCount = stage.results.length;
            final weather = stage.lockedWeather;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Etap ${stage.stageIndex}: ${stage.stageName}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stage.distanceKm.toStringAsFixed(1)} km • +${stage.elevationGainM.toStringAsFixed(0)} m • ${weather.temperatureC.toStringAsFixed(1)}°C / Wiatr ${weather.windSpeedKmh.toStringAsFixed(0)} km/h',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      '$submittedCount/${league.participants.length} wyników',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklyChallengesTab({
    required bool isMobile,
    required bool isDesktop,
  }) {
    final challenges = _filteredChallenges;
    final selected = _selectedChallenge;

    return SingleChildScrollView(
      key: const ValueKey('tab_challenges'),
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Poziom trudności:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                _HubTabChip(
                  label: 'Wszystkie',
                  isSelected: _challengeDifficultyFilter == null,
                  onTap: () =>
                      setState(() => _challengeDifficultyFilter = null),
                ),
                ...GhostChallengeDifficulty.values.map((diff) {
                  return _HubTabChip(
                    label: diff.label,
                    isSelected: _challengeDifficultyFilter == diff,
                    onTap: () =>
                        setState(() => _challengeDifficultyFilter = diff),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (challenges.isEmpty)
            _buildEmptyStateCard(
              icon: Icons.bolt_outlined,
              title: 'Brak wyzwań dla wybranego filtra',
              subtitle:
                  'Wyświetl wszystkie wyzwania tygodnia lub zaimportuj wyzwanie znajomego.',
              actionLabel: 'Pokaż wszystkie',
              onAction: () =>
                  setState(() => _challengeDifficultyFilter = null),
            )
          else if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildChallengesList(challenges, selected),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: selected != null
                      ? _buildChallengeDetailPanel(selected, isMobile: false)
                      : const SizedBox.shrink(),
                ),
              ],
            )
          else ...[
            _buildChallengesList(challenges, selected),
            if (selected != null) ...[
              const SizedBox(height: 16),
              _buildChallengeDetailPanel(selected, isMobile: isMobile),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildChallengesList(
    List<GhostChallengeModel> challenges,
    GhostChallengeModel? selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: challenges.map((challenge) {
        final isSelected = selected?.challengeId == challenge.challengeId;
        final statusColor = switch (challenge.status) {
          GhostChallengeStatus.open => AppColors.accentBlue,
          GhostChallengeStatus.accepted => AppColors.amberWarning,
          GhostChallengeStatus.completed => AppColors.statusSuccess,
          GhostChallengeStatus.expired => AppColors.textSecondary,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _InteractiveCard(
            isSelected: isSelected,
            onTap: () =>
                setState(() => _selectedChallengeId = challenge.challengeId),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        challenge.difficulty.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '+${challenge.eloStake} ELO',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${challenge.stageName} • ${challenge.distanceKm.toStringAsFixed(1)} km • Cel: ${_formatDuration(challenge.targetFinishTimeSeconds)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChallengeDetailPanel(
    GhostChallengeModel challenge, {
    required bool isMobile,
  }) {
    final best = challenge.bestAttempt;
    final weather = challenge.weatherSnapshot;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Twórca: ${challenge.creatorName} • ${challenge.stageName}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _HubActionButton(
                icon: Icons.directions_bike_rounded,
                label: widget.onLaunchGhostRace != null
                    ? 'Ścigaj się w 3D'
                    : 'Podejmij Wyzwanie Ducha',
                isDisabled: widget.isReadOnly,
                onPressed: () {
                  if (widget.onLaunchGhostRace != null) {
                    widget.onLaunchGhostRace!(challenge);
                  } else {
                    _recordGhostAttempt(challenge);
                  }
                },
                accentColor: AppColors.goldAccent,
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Czas Ducha',
                value: _formatDuration(challenge.targetFinishTimeSeconds),
                accent: AppColors.goldAccent,
              ),
              _MetricTile(
                label: 'Śr. Moc Ducha',
                value: '${challenge.targetAverageWatts.toStringAsFixed(0)} W',
                accent: AppColors.cyanAccent,
              ),
              _MetricTile(
                label: 'Dystans / Przewyższenie',
                value:
                    '${challenge.distanceKm.toStringAsFixed(1)} km / +${challenge.elevationGainM.toStringAsFixed(0)} m',
                accent: AppColors.accentBlue,
              ),
              _MetricTile(
                label: 'Warunki Pogodowe',
                value:
                    '${weather.temperatureC.toStringAsFixed(0)}°C • ${weather.windSpeedKmh.toStringAsFixed(0)} km/h',
                accent: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'TELEMETRIA TRASY DUCHA (PROFIL & MOC)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: CustomPaint(
              painter: _GhostTelemetryChartPainter(
                samples: challenge.targetTelemetry,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TWOJE PODEJŚCIA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (challenge.attempts.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak zarejestrowanych prób. Rozpocznij wyzwanie na identycznych warunkach pogodowych!',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: challenge.attempts.reversed.take(4).map((attempt) {
                final isBest = best?.attemptId == attempt.attemptId;
                final deltaStr = attempt.deltaVsTargetSeconds <= 0
                    ? '${attempt.deltaVsTargetSeconds.toStringAsFixed(1)} s'
                    : '+${attempt.deltaVsTargetSeconds.toStringAsFixed(1)} s';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isBest
                          ? AppColors.goldAccent.withValues(alpha: 0.6)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        attempt.isVictory
                            ? Icons.emoji_events
                            : Icons.timer_outlined,
                        size: 16,
                        color: attempt.isVictory
                            ? AppColors.statusSuccess
                            : AppColors.amberWarning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_formatDuration(attempt.finishTimeSeconds)} • ${attempt.averageWatts.toStringAsFixed(0)} W avg',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Text(
                        deltaStr,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: attempt.isVictory
                              ? AppColors.statusSuccess
                              : AppColors.crimsonAlert,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncAndDraftTab({
    required AsyncMultiplayerLeagueSyncState syncState,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final notifier = ref.read(asyncMultiplayerLeagueSyncProvider.notifier);

    return SingleChildScrollView(
      key: const ValueKey('tab_sync_draft'),
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WYMIANA PACZEK LIGOWYCH (.ppmleague)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Eksportuj stan ligi i wyzwań duchów do zaszyfrowanego sumą FNV-1a64 pliku .ppmleague lub wklej paczkę od znajomego.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HubActionButton(
                      icon: Icons.upload_file_outlined,
                      label: 'Generuj paczkę .ppmleague',
                      isDisabled: widget.isReadOnly,
                      onPressed: () {
                        final res = notifier.exportPpmLeaguePayload();
                        if (res != null) {
                          Clipboard.setData(
                            ClipboardData(text: res.encodedPayload),
                          );
                          _showFeedback(
                            'Wygenerowano ${res.fileName} (${res.compressedByteSize} B) i skopiowano do schowka.',
                          );
                        }
                      },
                      accentColor: AppColors.goldAccent,
                      filled: true,
                    ),
                    _HubActionButton(
                      icon: Icons.download_for_offline_outlined,
                      label: 'Scal wklejoną paczkę',
                      isDisabled: widget.isReadOnly,
                      onPressed: () {
                        final raw = _importPayloadController.text.trim();
                        if (raw.isEmpty) {
                          _showFeedback(
                            'Wklej zawartość paczki .ppmleague przed importem.',
                            isError: true,
                          );
                          return;
                        }
                        final report = notifier.importPpmLeaguePayload(raw);
                        if (report != null) {
                          if (report.mergedLeague != null) {
                            setState(() {
                              final merged = report.mergedLeague!;
                              final idx = _leagues.indexWhere(
                                (l) => l.leagueId == merged.leagueId,
                              );
                              if (idx == -1) {
                                _leagues = [merged, ..._leagues];
                              } else {
                                _leagues = [
                                  ..._leagues.sublist(0, idx),
                                  merged,
                                  ..._leagues.sublist(idx + 1),
                                ];
                              }
                              _selectedLeagueId = merged.leagueId;
                              _challenges = report.mergedChallenges;
                            });
                          }
                          _showFeedback(
                            'Scalono paczkę: +${report.addedResultsCount} wyników, +${report.addedChallengesCount} wyzwań.',
                          );
                        }
                      },
                      accentColor: AppColors.accentBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _importPayloadController,
                  maxLines: 3,
                  enabled: !widget.isReadOnly,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  decoration: _inputDecoration(
                    'Wklej payload PPMLEAGUE_GZ_V1:... lub PPMLEAGUE_V1:...',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDraftAndSyncLogSection(
            syncState: syncState,
            notifier: notifier,
            isMobile: isMobile,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildDraftAndSyncLogSection({
    required AsyncMultiplayerLeagueSyncState syncState,
    required AsyncMultiplayerLeagueSyncNotifier notifier,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final draft = syncState.draftSession;
    final draftCard = Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DRAFT KOLARZY (SNAKE DRAFT)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.accentBlue,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LeagueSyncTransportMode.values.map((mode) {
              return _HubTabChip(
                label: mode.label,
                isSelected: syncState.transportMode == mode,
                onTap: widget.isReadOnly
                    ? null
                    : () => notifier.setTransportMode(mode),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            draft == null
                ? 'Brak aktywnej sesji draftu. Rozpocznij draft dla wybranej ligi.'
                : 'Runda ${draft.currentRound} • Wybory: ${draft.picks.length}/${draft.totalRequiredPicks} • Kolej: ${draft.currentParticipantId ?? 'Zakończony'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HubActionButton(
                icon: Icons.play_circle_outline,
                label: draft == null ? 'Rozpocznij Draft' : 'Auto-Pick',
                isDisabled: widget.isReadOnly,
                onPressed: () {
                  if (draft == null) {
                    notifier.startDraft(
                      availableRiderIds: const [
                        'rider_pog',
                        'rider_vin',
                        'rider_rem',
                        'rider_mvdp',
                        'rider_wva',
                        'rider_kwi',
                        'rider_maj',
                        'rider_phi',
                        'rider_mer',
                        'rider_pid',
                        'rider_ayuso',
                        'rider_almeida',
                      ],
                    );
                  } else {
                    notifier.autoPickNext();
                  }
                },
                accentColor: AppColors.accentBlue,
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );

    final logsCard = Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DZIENNIK SYNCHRONIZACJI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          if (syncState.syncLogs.isEmpty)
            const Text(
              'Brak zdarzeń synchronizacji w tej sesji.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...syncState.syncLogs.take(5).map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: log.isError
                        ? AppColors.crimsonAlert.withValues(alpha: 0.6)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: log.isError
                            ? AppColors.crimsonAlert
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              );
            }),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: draftCard),
          const SizedBox(width: 16),
          Expanded(child: logsCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        draftCard,
        const SizedBox(height: 16),
        logsCard,
      ],
    );
  }

  Widget _buildEloRankingTab({
    required bool isMobile,
    required bool isDesktop,
  }) {
    final currentTier = _playerProfile.divisionTier;
    final tierColor =
        _parseHexColor(currentTier.badgeColorHex, AppColors.goldAccent);

    return SingleChildScrollView(
      key: const ValueKey('tab_elo'),
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tierColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium, color: tierColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_playerProfile.displayName} • ${currentTier.label}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Aktualne ELO: ${_playerProfile.currentElo} • Szczytowe: ${_playerProfile.peakElo} • Seria wygranych: ${_playerProfile.winStreak}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _playerProfile.progressToNextTier,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricTile(
                      label: 'Mecze',
                      value: '${_playerProfile.matchesPlayed}',
                      accent: AppColors.accentBlue,
                    ),
                    _MetricTile(
                      label: 'Zwycięstwa',
                      value: '${_playerProfile.wins}',
                      accent: AppColors.statusSuccess,
                    ),
                    _MetricTile(
                      label: 'Win Rate',
                      value:
                          '${(_playerProfile.winRate * 100).toStringAsFixed(1)}%',
                      accent: AppColors.goldAccent,
                    ),
                    _MetricTile(
                      label: 'Najlepsza Seria',
                      value: '${_playerProfile.bestWinStreak}',
                      accent: AppColors.cyanAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDivisionsCard(currentTier)),
                const SizedBox(width: 16),
                Expanded(child: _buildMatchHistoryCard()),
              ],
            )
          else ...[
            _buildDivisionsCard(currentTier),
            const SizedBox(height: 16),
            _buildMatchHistoryCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildDivisionsCard(EloDivisionTier currentTier) {
    return Container(
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
            'DRABINKA DYWIZJI ELO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...EloDivisionTier.values.reversed.map((tier) {
            final isCurrent = tier == currentTier;
            final color = _parseHexColor(tier.badgeColorHex, AppColors.goldAccent);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? color.withValues(alpha: 0.14)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent ? color : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, size: 16, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tier.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    tier == EloDivisionTier.grandTourLegend
                        ? '${tier.minElo}+ ELO'
                        : '${tier.minElo}–${tier.maxElo} ELO',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryCard() {
    final history = _playerProfile.recentHistory;
    return Container(
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
            'OSTATNIE POJEDYNKI ELO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Text(
              'Brak rozegranych pojedynków ELO.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...history.map((record) {
              final isPositive = record.delta >= 0;
              final deltaColor = isPositive
                  ? AppColors.statusSuccess
                  : AppColors.crimsonAlert;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: deltaColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${record.placement}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: deltaColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.opponentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Stawka: ${record.fieldSize} graczy • ${record.eloBefore} → ${record.eloAfter}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${record.delta}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: deltaColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _HubActionButton(
            icon: Icons.refresh_rounded,
            label: actionLabel,
            onPressed: onAction,
            accentColor: AppColors.goldAccent,
          ),
        ],
      ),
    );
  }

  Color _leagueStatusColor(LeagueStatus status) {
    switch (status) {
      case LeagueStatus.recruiting:
        return AppColors.accentBlue;
      case LeagueStatus.drafting:
        return AppColors.amberWarning;
      case LeagueStatus.active:
        return AppColors.statusSuccess;
      case LeagueStatus.completed:
        return AppColors.goldAccent;
      case LeagueStatus.archived:
        return AppColors.textSecondary;
    }
  }

  Color _parseHexColor(String hex, Color fallback) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6 && cleaned.length != 8) return fallback;
    final parsed = int.tryParse(
      cleaned.length == 6 ? 'FF$cleaned' : cleaned,
      radix: 16,
    );
    return parsed != null ? Color(parsed) : fallback;
  }

  String _formatDuration(double totalSeconds) {
    final safe = totalSeconds.isFinite && totalSeconds >= 0 ? totalSeconds : 0.0;
    final mins = (safe ~/ 60);
    final secs = safe % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toStringAsFixed(1).padLeft(4, '0')}';
  }
}

class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;

  const _InteractiveCard({
    required this.child,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.6)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : _hovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.75)
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _HubTabChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _HubTabChip({
    required this.label,
    this.icon,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_HubTabChip> createState() => _HubTabChipState();
}

class _HubTabChipState extends State<_HubTabChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.25)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.surface;
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: widget.isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool isDisabled;
  final bool filled;

  const _HubActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.accentColor,
    this.isDisabled = false,
    this.filled = false,
  });

  @override
  State<_HubActionButton> createState() => _HubActionButtonState();
}

class _HubActionButtonState extends State<_HubActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isDisabled && widget.onPressed != null;
    final effectiveAccent =
        enabled ? widget.accentColor : AppColors.textSecondary;

    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.filled
            ? (_hovered
                ? effectiveAccent
                : effectiveAccent.withValues(alpha: 0.9))
            : (_hovered
                ? effectiveAccent.withValues(alpha: 0.2)
                : effectiveAccent.withValues(alpha: 0.1));

    final fgColor = !enabled
        ? AppColors.textSecondary
        : widget.filled
            ? AppColors.background
            : effectiveAccent;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focused
                      ? AppColors.textPrimary
                      : effectiveAccent.withValues(alpha: enabled ? 0.65 : 0.3),
                  width: _focused ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 16, color: fgColor),
                  if (widget.label.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: fgColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostTelemetryChartPainter extends CustomPainter {
  final List<GhostTelemetrySample> samples;

  const _GhostTelemetryChartPainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (samples.length < 2) return;

    var minElev = samples.first.elevationM;
    var maxElev = samples.first.elevationM;
    var maxWatts = 1.0;
    for (final s in samples) {
      if (s.elevationM < minElev) minElev = s.elevationM;
      if (s.elevationM > maxElev) maxElev = s.elevationM;
      if (s.powerWatts > maxWatts) maxWatts = s.powerWatts;
    }
    final elevSpan = math.max(10.0, maxElev - minElev);

    final elevPath = Path();
    final elevFill = Path()..moveTo(0, size.height);
    final powerPath = Path();

    for (var i = 0; i < samples.length; i++) {
      final t = i / (samples.length - 1);
      final x = t * size.width;
      final elevNorm = (samples[i].elevationM - minElev) / elevSpan;
      final elevY = size.height - (elevNorm * size.height * 0.65) - 8;

      final wattsNorm = (samples[i].powerWatts / maxWatts).clamp(0.0, 1.0);
      final wattsY = size.height - (wattsNorm * size.height * 0.85) - 6;

      if (i == 0) {
        elevPath.moveTo(x, elevY);
        elevFill.lineTo(x, elevY);
        powerPath.moveTo(x, wattsY);
      } else {
        elevPath.lineTo(x, elevY);
        elevFill.lineTo(x, elevY);
        powerPath.lineTo(x, wattsY);
      }
    }
    elevFill.lineTo(size.width, size.height);
    elevFill.close();

    canvas.drawPath(
      elevFill,
      Paint()..color = AppColors.primaryAccent.withValues(alpha: 0.25),
    );
    canvas.drawPath(
      elevPath,
      Paint()
        ..color = AppColors.primaryAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      powerPath,
      Paint()
        ..color = AppColors.goldAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _GhostTelemetryChartPainter oldDelegate) {
    return oldDelegate.samples != samples;
  }
}
