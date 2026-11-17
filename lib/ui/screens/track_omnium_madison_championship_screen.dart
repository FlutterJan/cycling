// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/physics/velodrome_keirin_and_madison_sling_solver.dart';
import '../../engine/rendering3d/velodrome_madison_hand_sling_3d_renderer.dart';
import '../../models/race/velodrome_track_and_hour_record_model.dart';

// =============================================================================
// 1. MODELE DYSCYPLIN, ZAWODNIKÓW I WYNIKÓW MISTRZOSTW TOROWYCH
// =============================================================================

/// Dyscyplina Mistrzostw Torowych UCI obsługiwana na ekranie.
enum TrackChampionshipDiscipline {
  keirin(
    titlePl: 'Keirin',
    subtitlePl: '1500 m (6 okrążeń) • Derny do 50 km/h',
    badgeTag: 'KEIRIN',
    icon: Icons.two_wheeler_rounded,
  ),
  madison(
    titlePl: 'Madison',
    subtitlePl: 'Wyścig Amerykański • Pary & Hand Sling',
    badgeTag: 'MADISON',
    icon: Icons.handshake_rounded,
  ),
  omnium(
    titlePl: 'Omnium',
    subtitlePl: '4 konkurencje: Scratch, Tempo, Eliminacja, Punktowy',
    badgeTag: 'OMNIUM',
    icon: Icons.emoji_events_rounded,
  ),
  pointsRace(
    titlePl: 'Wyścig Punktowy',
    subtitlePl: '40 km (160 okrążeń) • Sprinty co 10 okrążeń • ±20 pkt',
    badgeTag: 'POINTS',
    icon: Icons.scoreboard_rounded,
  );

  final String titlePl;
  final String subtitlePl;
  final String badgeTag;
  final IconData icon;

  const TrackChampionshipDiscipline({
    required this.titlePl,
    required this.subtitlePl,
    required this.badgeTag,
    required this.icon,
  });
}

/// Profil zawodnika torowego startującego w Mistrzostwach Świata UCI.
class TrackChampionshipAthlete {
  final String id;
  final String name;
  final String nationCode;
  final String teamName;
  final Color jerseyColor;
  final double massKg;
  final double peakSprintWatts;
  final double criticalPowerWatts;
  final double wPrimeJoules;
  final double trackTacticsSkill;
  final double slingSkill;
  final double enduranceRating;
  final int preferredChainring;
  final int preferredCog;

  const TrackChampionshipAthlete({
    required this.id,
    required this.name,
    required this.nationCode,
    required this.teamName,
    required this.jerseyColor,
    required this.massKg,
    required this.peakSprintWatts,
    required this.criticalPowerWatts,
    required this.wPrimeJoules,
    required this.trackTacticsSkill,
    required this.slingSkill,
    required this.enduranceRating,
    this.preferredChainring = 62,
    this.preferredCog = 14,
  });

  KeirinRiderProfile toKeirinProfile({
    required FixedGearTrackBike bike,
    required int startingSlot,
  }) {
    return KeirinRiderProfile(
      riderId: id,
      name: '$name ($nationCode)',
      riderMassKg: massKg,
      bike: bike,
      peakSprintPowerWatts: peakSprintWatts,
      criticalPowerWatts: criticalPowerWatts,
      wPrimeJoules: wPrimeJoules,
      trackTacticsSkill: trackTacticsSkill,
      startingSlot: startingSlot,
    );
  }

  static const List<TrackChampionshipAthlete> defaultRoster = [
    TrackChampionshipAthlete(
      id: 'trk_pol_rud',
      name: 'Kacper Rudnicki',
      nationCode: 'POL',
      teamName: 'Polska Torowa',
      jerseyColor: Color(0xFFDC2626),
      massKg: 84.0,
      peakSprintWatts: 2240.0,
      criticalPowerWatts: 415.0,
      wPrimeJoules: 32500.0,
      trackTacticsSkill: 92.0,
      slingSkill: 88.0,
      enduranceRating: 82.0,
      preferredChainring: 64,
      preferredCog: 14,
    ),
    TrackChampionshipAthlete(
      id: 'trk_ned_lav',
      name: 'Harrie Van Der Berg',
      nationCode: 'NED',
      teamName: 'Oranje Track',
      jerseyColor: Color(0xFFF97316),
      massKg: 88.0,
      peakSprintWatts: 2380.0,
      criticalPowerWatts: 430.0,
      wPrimeJoules: 34000.0,
      trackTacticsSkill: 95.0,
      slingSkill: 91.0,
      enduranceRating: 85.0,
      preferredChainring: 64,
      preferredCog: 13,
    ),
    TrackChampionshipAthlete(
      id: 'trk_gbr_hay',
      name: 'Ethan Hayter-Wright',
      nationCode: 'GBR',
      teamName: 'British Cycling',
      jerseyColor: Color(0xFF2563EB),
      massKg: 73.0,
      peakSprintWatts: 1780.0,
      criticalPowerWatts: 452.0,
      wPrimeJoules: 28200.0,
      trackTacticsSkill: 93.0,
      slingSkill: 95.0,
      enduranceRating: 96.0,
      preferredChainring: 60,
      preferredCog: 14,
    ),
    TrackChampionshipAthlete(
      id: 'trk_ita_viv',
      name: 'Matteo Viviani',
      nationCode: 'ITA',
      teamName: 'Azzurri Pista',
      jerseyColor: Color(0xFF0EA5E9),
      massKg: 74.0,
      peakSprintWatts: 1860.0,
      criticalPowerWatts: 444.0,
      wPrimeJoules: 29400.0,
      trackTacticsSkill: 94.0,
      slingSkill: 94.0,
      enduranceRating: 94.0,
      preferredChainring: 61,
      preferredCog: 14,
    ),
    TrackChampionshipAthlete(
      id: 'trk_fra_tho',
      name: 'Julien Thomas',
      nationCode: 'FRA',
      teamName: 'Équipe de France',
      jerseyColor: Color(0xFF3B82F6),
      massKg: 75.0,
      peakSprintWatts: 1820.0,
      criticalPowerWatts: 448.0,
      wPrimeJoules: 28800.0,
      trackTacticsSkill: 91.0,
      slingSkill: 92.0,
      enduranceRating: 95.0,
      preferredChainring: 60,
      preferredCog: 14,
    ),
    TrackChampionshipAthlete(
      id: 'trk_bel_dek',
      name: 'Fabio De Vylder',
      nationCode: 'BEL',
      teamName: 'Belgian Track',
      jerseyColor: Color(0xFFEAB308),
      massKg: 72.0,
      peakSprintWatts: 1740.0,
      criticalPowerWatts: 455.0,
      wPrimeJoules: 27900.0,
      trackTacticsSkill: 90.0,
      slingSkill: 96.0,
      enduranceRating: 96.0,
      preferredChainring: 59,
      preferredCog: 14,
    ),
    TrackChampionshipAthlete(
      id: 'trk_jpn_ota',
      name: 'Kenji Ota',
      nationCode: 'JPN',
      teamName: 'Team Japan Keirin',
      jerseyColor: Color(0xFFEC4899),
      massKg: 81.0,
      peakSprintWatts: 2190.0,
      criticalPowerWatts: 410.0,
      wPrimeJoules: 31800.0,
      trackTacticsSkill: 92.0,
      slingSkill: 87.0,
      enduranceRating: 83.0,
      preferredChainring: 63,
      preferredCog: 14,
    ),
    TrackChampionshipAthlete(
      id: 'trk_den_han',
      name: 'Niklas Hansen',
      nationCode: 'DEN',
      teamName: 'Danmark Track',
      jerseyColor: Color(0xFFEF4444),
      massKg: 76.0,
      peakSprintWatts: 1790.0,
      criticalPowerWatts: 460.0,
      wPrimeJoules: 28500.0,
      trackTacticsSkill: 91.0,
      slingSkill: 93.0,
      enduranceRating: 95.0,
      preferredChainring: 61,
      preferredCog: 14,
    ),
  ];
}

/// Wynik pojedynczego zawodnika w 4-konkurencyjnym Omnium UCI.
class OmniumEventStanding {
  final TrackChampionshipAthlete athlete;
  final int rank;
  final int scratchRank;
  final int scratchPoints;
  final int tempoRank;
  final int tempoPoints;
  final int eliminationRank;
  final int eliminationPoints;
  final int pointsRaceDelta;
  final int lapBalance;
  final int totalOmniumPoints;

  const OmniumEventStanding({
    required this.athlete,
    required this.rank,
    required this.scratchRank,
    required this.scratchPoints,
    required this.tempoRank,
    required this.tempoPoints,
    required this.eliminationRank,
    required this.eliminationPoints,
    required this.pointsRaceDelta,
    required this.lapBalance,
    required this.totalOmniumPoints,
  });
}

/// Pełny raport z rozegranych Mistrzostw w Omnium.
class OmniumSimulationResult {
  final VelodromeFacilitySpec facility;
  final List<OmniumEventStanding> standings;

  const OmniumSimulationResult({
    required this.facility,
    required this.standings,
  });
}

/// Wynik zawodnika w Wyścigu Punktowym UCI.
class PointsRaceStanding {
  final TrackChampionshipAthlete athlete;
  final int rank;
  final int sprintPoints;
  final int lapBalance;
  final int totalPoints;
  final int sprintsWon;
  final double avgSpeedKmh;

  const PointsRaceStanding({
    required this.athlete,
    required this.rank,
    required this.sprintPoints,
    required this.lapBalance,
    required this.totalPoints,
    required this.sprintsWon,
    required this.avgSpeedKmh,
  });
}

/// Zapis punktowanego sprintu pośredniego w Wyścigu Punktowym.
class PointsRaceSprintLog {
  final int lapNumber;
  final bool isFinalDouble;
  final String winnerName;
  final String winnerNation;
  final int awardedTopPoints;

  const PointsRaceSprintLog({
    required this.lapNumber,
    required this.isFinalDouble,
    required this.winnerName,
    required this.winnerNation,
    required this.awardedTopPoints,
  });
}

/// Pełny wynik symulacji Wyścigu Punktowego UCI.
class PointsRaceSimulationResult {
  final VelodromeFacilitySpec facility;
  final int totalLaps;
  final int sprintIntervalLaps;
  final List<PointsRaceStanding> standings;
  final List<PointsRaceSprintLog> sprintLogs;

  const PointsRaceSimulationResult({
    required this.facility,
    required this.totalLaps,
    required this.sprintIntervalLaps,
    required this.standings,
    required this.sprintLogs,
  });
}

// =============================================================================
// 2. SILNIK SYMULACJI MISTRZOSTW TOROWYCH (KEIRIN / MADISON / OMNIUM / PUNKTY)
// =============================================================================

/// Deterministyczny i powiązany z fizyką silnik symulacji 4 dyscyplin torowych.
class TrackChampionshipSimulationEngine {
  TrackChampionshipSimulationEngine._();

  static const List<int> uciOmniumEventPoints = [
    40,
    38,
    36,
    34,
    32,
    30,
    28,
    26,
  ];

  /// Symuluje finał Keirin (1500 m / 6 okrążeń) przy użyciu fizyki Derny i draftu.
  static KeirinRaceSimulationResult simulateKeirin({
    required VelodromeFacilitySpec facility,
    required FixedGearTrackBike playerBike,
    required TrackChampionshipAthlete playerAthlete,
    required int playerStartingSlot,
    required double dernyTargetSpeedKmh,
  }) {
    final List<TrackChampionshipAthlete> field = List.of(
      TrackChampionshipAthlete.defaultRoster,
    );
    field.removeWhere((a) => a.id == playerAthlete.id);
    final List<TrackChampionshipAthlete> selected = [
      playerAthlete,
      ...field.take(5),
    ];

    final List<int> availableSlots = [1, 2, 3, 4, 5, 6]
      ..remove(playerStartingSlot.clamp(1, 6));
    int slotIdx = 0;

    final List<KeirinRiderProfile> profiles = [];
    for (final athlete in selected) {
      final bool isPlayer = athlete.id == playerAthlete.id;
      final int slot =
          isPlayer ? playerStartingSlot.clamp(1, 6) : availableSlots[slotIdx++];
      final FixedGearTrackBike bike = isPlayer
          ? playerBike
          : VelodromeTrackAndHourRecordModel.defaultTrackBike.copyWith(
              chainringTeeth: athlete.preferredChainring,
              cogTeeth: athlete.preferredCog,
            );
      profiles.add(athlete.toKeirinProfile(bike: bike, startingSlot: slot));
    }

    return VelodromeKeirinAndMadisonSlingSolver.simulateKeirinRace(
      config: KeirinRaceConfig(
        facility: facility,
        derny: KeirinDernySpec(
          startSpeedKmh: 30.0,
          targetPullOffSpeedKmh: dernyTargetSpeedKmh,
          pacedLaps: 3,
        ),
        totalLaps: 6,
      ),
      riders: profiles,
    );
  }

  /// Symuluje wyścig Madison (Wyścig Amerykański) z fizyką Hand Sling.
  static MadisonRaceSimulationResult simulateMadison({
    required VelodromeFacilitySpec facility,
    required FixedGearTrackBike playerBike,
    required int totalLaps,
    required int exchangeIntervalLaps,
    required double teamChemistry,
  }) {
    const roster = TrackChampionshipAthlete.defaultRoster;
    final List<MadisonTeamRiderPair> pairs = [
      MadisonTeamRiderPair(
        teamId: 'pair_pol',
        teamName: 'Polska (POL)',
        riderA: roster[0].toKeirinProfile(bike: playerBike, startingSlot: 1),
        riderB: roster[2].toKeirinProfile(bike: playerBike, startingSlot: 2),
        riderASlingSkill: roster[0].slingSkill,
        riderBSlingSkill: roster[2].slingSkill,
        teamChemistry: teamChemistry,
        exchangeIntervalLaps: exchangeIntervalLaps,
      ),
      MadisonTeamRiderPair(
        teamId: 'pair_ita',
        teamName: 'Włochy (ITA)',
        riderA: roster[3].toKeirinProfile(
          bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
          startingSlot: 1,
        ),
        riderB: roster[5].toKeirinProfile(
          bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
          startingSlot: 2,
        ),
        riderASlingSkill: roster[3].slingSkill,
        riderBSlingSkill: roster[5].slingSkill,
        teamChemistry: 88.0,
        exchangeIntervalLaps: 3,
      ),
      MadisonTeamRiderPair(
        teamId: 'pair_ned',
        teamName: 'Holandia (NED)',
        riderA: roster[1].toKeirinProfile(
          bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
          startingSlot: 1,
        ),
        riderB: roster[7].toKeirinProfile(
          bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
          startingSlot: 2,
        ),
        riderASlingSkill: roster[1].slingSkill,
        riderBSlingSkill: roster[7].slingSkill,
        teamChemistry: 86.0,
        exchangeIntervalLaps: 3,
      ),
      MadisonTeamRiderPair(
        teamId: 'pair_fra',
        teamName: 'Francja (FRA)',
        riderA: roster[4].toKeirinProfile(
          bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
          startingSlot: 1,
        ),
        riderB: roster[6].toKeirinProfile(
          bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
          startingSlot: 2,
        ),
        riderASlingSkill: roster[4].slingSkill,
        riderBSlingSkill: roster[6].slingSkill,
        teamChemistry: 84.0,
        exchangeIntervalLaps: 4,
      ),
    ];

    return VelodromeKeirinAndMadisonSlingSolver.simulateMadisonRace(
      config: MadisonRaceConfig(
        facility: facility,
        totalLaps: totalLaps,
        sprintIntervalLaps: 10,
      ),
      teams: pairs,
    );
  }

  /// Symuluje 4-etapowe Omnium UCI: Scratch, Tempo, Eliminacja i Wyścig Punktowy.
  static OmniumSimulationResult simulateOmnium({
    required VelodromeFacilitySpec facility,
    required FixedGearTrackBike playerBike,
    required TrackChampionshipAthlete focusAthlete,
    required int seed,
  }) {
    final math.Random rng = math.Random(seed);
    final List<TrackChampionshipAthlete> roster =
        List.of(TrackChampionshipAthlete.defaultRoster);

    // 1. Scratch Race (przewaga taktyki, sprintu i wytrzymałości).
    final List<TrackChampionshipAthlete> scratchOrder = List.of(roster)
      ..sort((a, b) {
        final double scoreA = a.enduranceRating * 0.40 +
            a.trackTacticsSkill * 0.35 +
            (a.peakSprintWatts / 25.0) * 0.25 +
            (a.id == focusAthlete.id ? (100 - playerBike.cogTeeth) * 0.15 : 0) +
            rng.nextDouble() * 6.0;
        final double scoreB = b.enduranceRating * 0.40 +
            b.trackTacticsSkill * 0.35 +
            (b.peakSprintWatts / 25.0) * 0.25 +
            (b.id == focusAthlete.id ? (100 - playerBike.cogTeeth) * 0.15 : 0) +
            rng.nextDouble() * 6.0;
        return scoreB.compareTo(scoreA);
      });

    // 2. Tempo Race (przewaga CP / FTP i W').
    final List<TrackChampionshipAthlete> tempoOrder = List.of(roster)
      ..sort((a, b) {
        final double scoreA = (a.criticalPowerWatts / 5.0) * 0.50 +
            (a.wPrimeJoules / 400.0) * 0.25 +
            a.enduranceRating * 0.25 +
            rng.nextDouble() * 6.5;
        final double scoreB = (b.criticalPowerWatts / 5.0) * 0.50 +
            (b.wPrimeJoules / 400.0) * 0.25 +
            b.enduranceRating * 0.25 +
            rng.nextDouble() * 6.5;
        return scoreB.compareTo(scoreA);
      });

    // 3. Elimination Race (przewaga taktyki torowej i powtarzalnego sprintu).
    final List<TrackChampionshipAthlete> eliminationOrder = List.of(roster)
      ..sort((a, b) {
        final double scoreA = a.trackTacticsSkill * 0.45 +
            (a.peakSprintWatts / 24.0) * 0.35 +
            (a.wPrimeJoules / 380.0) * 0.20 +
            rng.nextDouble() * 6.5;
        final double scoreB = b.trackTacticsSkill * 0.45 +
            (b.peakSprintWatts / 24.0) * 0.35 +
            (b.wPrimeJoules / 380.0) * 0.20 +
            rng.nextDouble() * 6.5;
        return scoreB.compareTo(scoreA);
      });

    // 4. Finałowy Wyścig Punktowy (100 okrążeń) dodawany bezpośrednio do sumy.
    final PointsRaceSimulationResult finalPoints = simulatePointsRace(
      facility: facility,
      totalLaps: 100,
      sprintIntervalLaps: 10,
      aggressionLevel: 0.72,
      seed: seed + 41,
    );

    final Map<String, PointsRaceStanding> pointsMap = {
      for (final s in finalPoints.standings) s.athlete.id: s,
    };

    final List<OmniumEventStanding> combined = [];
    for (final athlete in roster) {
      final int sRank = scratchOrder.indexWhere((r) => r.id == athlete.id) + 1;
      final int tRank = tempoOrder.indexWhere((r) => r.id == athlete.id) + 1;
      final int eRank =
          eliminationOrder.indexWhere((r) => r.id == athlete.id) + 1;

      final int sPts = uciOmniumEventPoints[(sRank - 1).clamp(0, 7)];
      final int tPts = uciOmniumEventPoints[(tRank - 1).clamp(0, 7)];
      final int ePts = uciOmniumEventPoints[(eRank - 1).clamp(0, 7)];

      final PointsRaceStanding? pr = pointsMap[athlete.id];
      final int prDelta = pr?.totalPoints ?? 0;
      final int lapBal = pr?.lapBalance ?? 0;

      combined.add(
        OmniumEventStanding(
          athlete: athlete,
          rank: 1,
          scratchRank: sRank,
          scratchPoints: sPts,
          tempoRank: tRank,
          tempoPoints: tPts,
          eliminationRank: eRank,
          eliminationPoints: ePts,
          pointsRaceDelta: prDelta,
          lapBalance: lapBal,
          totalOmniumPoints: sPts + tPts + ePts + prDelta,
        ),
      );
    }

    combined.sort((a, b) {
      final int cmp = b.totalOmniumPoints.compareTo(a.totalOmniumPoints);
      if (cmp != 0) return cmp;
      return a.eliminationRank.compareTo(b.eliminationRank);
    });

    final List<OmniumEventStanding> ranked = [
      for (int i = 0; i < combined.length; i++)
        OmniumEventStanding(
          athlete: combined[i].athlete,
          rank: i + 1,
          scratchRank: combined[i].scratchRank,
          scratchPoints: combined[i].scratchPoints,
          tempoRank: combined[i].tempoRank,
          tempoPoints: combined[i].tempoPoints,
          eliminationRank: combined[i].eliminationRank,
          eliminationPoints: combined[i].eliminationPoints,
          pointsRaceDelta: combined[i].pointsRaceDelta,
          lapBalance: combined[i].lapBalance,
          totalOmniumPoints: combined[i].totalOmniumPoints,
        ),
    ];

    return OmniumSimulationResult(facility: facility, standings: ranked);
  }

  /// Symuluje Wyścig Punktowy UCI (np. 160 okrążeń = 40 km) ze sprintami co 10 okrążeń.
  static PointsRaceSimulationResult simulatePointsRace({
    required VelodromeFacilitySpec facility,
    required int totalLaps,
    required int sprintIntervalLaps,
    required double aggressionLevel,
    required int seed,
  }) {
    final math.Random rng = math.Random(seed);
    final List<TrackChampionshipAthlete> roster =
        List.of(TrackChampionshipAthlete.defaultRoster);
    final int count = roster.length;

    final List<int> sprintPts = List<int>.filled(count, 0);
    final List<int> sprintsWon = List<int>.filled(count, 0);
    final List<int> lapBalance = List<int>.filled(count, 0);
    final List<PointsRaceSprintLog> logs = [];

    const List<int> baseSprintScores = [5, 3, 2, 1];

    for (int lap = sprintIntervalLaps;
        lap <= totalLaps;
        lap += sprintIntervalLaps) {
      final bool isFinalDouble = lap >= totalLaps;
      final int multiplier = isFinalDouble ? 2 : 1;

      final List<int> order = List<int>.generate(count, (i) => i)
        ..sort((a, b) {
          final TrackChampionshipAthlete ra = roster[a];
          final TrackChampionshipAthlete rb = roster[b];
          final double scoreA = (ra.peakSprintWatts / 25.0) * 0.35 +
              (ra.criticalPowerWatts / 5.0) * 0.30 +
              ra.trackTacticsSkill * 0.25 +
              rng.nextDouble() * (12.0 + aggressionLevel * 8.0);
          final double scoreB = (rb.peakSprintWatts / 25.0) * 0.35 +
              (rb.criticalPowerWatts / 5.0) * 0.30 +
              rb.trackTacticsSkill * 0.25 +
              rng.nextDouble() * (12.0 + aggressionLevel * 8.0);
          return scoreB.compareTo(scoreA);
        });

      for (int p = 0; p < baseSprintScores.length && p < order.length; p++) {
        final int idx = order[p];
        final int pts = baseSprintScores[p] * multiplier;
        sprintPts[idx] += pts;
        if (p == 0) sprintsWon[idx]++;
      }

      final TrackChampionshipAthlete winner = roster[order.first];
      logs.add(
        PointsRaceSprintLog(
          lapNumber: lap,
          isFinalDouble: isFinalDouble,
          winnerName: winner.name,
          winnerNation: winner.nationCode,
          awardedTopPoints: baseSprintScores.first * multiplier,
        ),
      );
    }

    // Nadrobione okrążenia (+20 pkt) w zależności od wytrzymałości i agresji.
    for (int i = 0; i < count; i++) {
      final TrackChampionshipAthlete r = roster[i];
      final double lapGainProb = ((r.enduranceRating - 82.0) / 30.0) *
          (0.45 + aggressionLevel * 0.55);
      if (rng.nextDouble() < lapGainProb.clamp(0.05, 0.70)) {
        lapBalance[i] += 1;
      } else if (r.enduranceRating < 84.0 && rng.nextDouble() < 0.25) {
        lapBalance[i] -= 1;
      }
    }

    final double altitudeBonus =
        facility.aeroDragReductionPercentVsSeaLevel * 0.08;
    final List<PointsRaceStanding> standings = [];
    for (int i = 0; i < count; i++) {
      final TrackChampionshipAthlete r = roster[i];
      final int totalPts = sprintPts[i] + lapBalance[i] * 20;
      final double speedKmh = 52.8 +
          (r.criticalPowerWatts - 420.0) * 0.03 +
          altitudeBonus +
          (lapBalance[i] * 0.6);
      standings.add(
        PointsRaceStanding(
          athlete: r,
          rank: 1,
          sprintPoints: sprintPts[i],
          lapBalance: lapBalance[i],
          totalPoints: totalPts,
          sprintsWon: sprintsWon[i],
          avgSpeedKmh: speedKmh,
        ),
      );
    }

    standings.sort((a, b) {
      final int cmp = b.totalPoints.compareTo(a.totalPoints);
      if (cmp != 0) return cmp;
      return b.sprintsWon.compareTo(a.sprintsWon);
    });

    final List<PointsRaceStanding> ranked = [
      for (int i = 0; i < standings.length; i++)
        PointsRaceStanding(
          athlete: standings[i].athlete,
          rank: i + 1,
          sprintPoints: standings[i].sprintPoints,
          lapBalance: standings[i].lapBalance,
          totalPoints: standings[i].totalPoints,
          sprintsWon: standings[i].sprintsWon,
          avgSpeedKmh: standings[i].avgSpeedKmh,
        ),
    ];

    return PointsRaceSimulationResult(
      facility: facility,
      totalLaps: totalLaps,
      sprintIntervalLaps: sprintIntervalLaps,
      standings: ranked,
      sprintLogs: logs,
    );
  }
}

// =============================================================================
// 3. GŁÓWNY EKRAN MISTRZOSTW TOROWYCH (KEIRIN, MADISON, OMNIUM, PUNKTOWY)
// =============================================================================

/// Ekran Mistrzostw Torowych UCI (Keirin, Madison, Omnium, Wyścig Punktowy).
class TrackOmniumMadisonChampionshipScreen extends StatefulWidget {
  final TrackChampionshipDiscipline initialDiscipline;
  final String initialVelodromeId;
  final VoidCallback? onBack;

  const TrackOmniumMadisonChampionshipScreen({
    super.key,
    this.initialDiscipline = TrackChampionshipDiscipline.keirin,
    this.initialVelodromeId = 'grenchen_tissot',
    this.onBack,
  });

  @override
  State<TrackOmniumMadisonChampionshipScreen> createState() =>
      _TrackOmniumMadisonChampionshipScreenState();
}

class _TrackOmniumMadisonChampionshipScreenState
    extends State<TrackOmniumMadisonChampionshipScreen> {
  late TrackChampionshipDiscipline _discipline;
  late VelodromeFacilitySpec _selectedVelodrome;
  late TrackChampionshipAthlete _selectedAthlete;

  // Konfiguracja roweru ostrokołowego (58T-64T x 13T-15T)
  int _chainringTeeth = 62;
  int _cogTeeth = 14;

  // Parametry Keirin
  int _keirinStartingSlot = 2;
  double _dernyTargetSpeedKmh = 50.0;
  KeirinRaceSimulationResult? _keirinResult;

  // Parametry Madison & Laboratorium Hand Sling
  int _madisonLaps = 120;
  int _madisonExchangeInterval = 3;
  double _madisonTeamChemistry = 88.0;
  double _slingIncomingSpeedKmh = 55.8;
  double _slingOutgoingSpeedKmh = 34.2;
  double _slingLongitudinalGapM = 0.25;
  double _slingLateralGapM = 0.70;
  MadisonRaceSimulationResult? _madisonResult;

  // Parametry Omnium
  int _omniumSeed = 2026;
  OmniumSimulationResult? _omniumResult;

  // Parametry Wyścigu Punktowego
  int _pointsRaceLaps = 160;
  double _pointsAggression = 0.70;
  int _pointsSeed = 467;
  PointsRaceSimulationResult? _pointsResult;

  @override
  void initState() {
    super.initState();
    _discipline = widget.initialDiscipline;
    const velodromes = VelodromeTrackAndHourRecordModel.defaultVelodromes;
    _selectedVelodrome = velodromes.firstWhere(
      (v) => v.id == widget.initialVelodromeId,
      orElse: () => velodromes.first,
    );
    _selectedAthlete = TrackChampionshipAthlete.defaultRoster.first;
    _runInitialSimulations();
  }

  FixedGearTrackBike get _currentBike =>
      VelodromeTrackAndHourRecordModel.defaultTrackBike.copyWith(
        chainringTeeth: _chainringTeeth,
        cogTeeth: _cogTeeth,
      );

  void _runInitialSimulations() {
    _keirinResult = TrackChampionshipSimulationEngine.simulateKeirin(
      facility: _selectedVelodrome,
      playerBike: _currentBike,
      playerAthlete: _selectedAthlete,
      playerStartingSlot: _keirinStartingSlot,
      dernyTargetSpeedKmh: _dernyTargetSpeedKmh,
    );
    _madisonResult = TrackChampionshipSimulationEngine.simulateMadison(
      facility: _selectedVelodrome,
      playerBike: _currentBike,
      totalLaps: _madisonLaps,
      exchangeIntervalLaps: _madisonExchangeInterval,
      teamChemistry: _madisonTeamChemistry,
    );
    _omniumResult = TrackChampionshipSimulationEngine.simulateOmnium(
      facility: _selectedVelodrome,
      playerBike: _currentBike,
      focusAthlete: _selectedAthlete,
      seed: _omniumSeed,
    );
    _pointsResult = TrackChampionshipSimulationEngine.simulatePointsRace(
      facility: _selectedVelodrome,
      totalLaps: _pointsRaceLaps,
      sprintIntervalLaps: 10,
      aggressionLevel: _pointsAggression,
      seed: _pointsSeed,
    );
  }

  void _runCurrentDisciplineSimulation() {
    setState(() {
      switch (_discipline) {
        case TrackChampionshipDiscipline.keirin:
          _keirinResult = TrackChampionshipSimulationEngine.simulateKeirin(
            facility: _selectedVelodrome,
            playerBike: _currentBike,
            playerAthlete: _selectedAthlete,
            playerStartingSlot: _keirinStartingSlot,
            dernyTargetSpeedKmh: _dernyTargetSpeedKmh,
          );
        case TrackChampionshipDiscipline.madison:
          _madisonResult = TrackChampionshipSimulationEngine.simulateMadison(
            facility: _selectedVelodrome,
            playerBike: _currentBike,
            totalLaps: _madisonLaps,
            exchangeIntervalLaps: _madisonExchangeInterval,
            teamChemistry: _madisonTeamChemistry,
          );
        case TrackChampionshipDiscipline.omnium:
          _omniumSeed += 17;
          _omniumResult = TrackChampionshipSimulationEngine.simulateOmnium(
            facility: _selectedVelodrome,
            playerBike: _currentBike,
            focusAthlete: _selectedAthlete,
            seed: _omniumSeed,
          );
        case TrackChampionshipDiscipline.pointsRace:
          _pointsSeed += 23;
          _pointsResult = TrackChampionshipSimulationEngine.simulatePointsRace(
            facility: _selectedVelodrome,
            totalLaps: _pointsRaceLaps,
            sprintIntervalLaps: 10,
            aggressionLevel: _pointsAggression,
            seed: _pointsSeed,
          );
      }
    });
  }

  MadisonHandSlingResult get _liveSlingPreview {
    return VelodromeKeirinAndMadisonSlingSolver.solveMadisonHandSling(
      MadisonHandSlingInput(
        facility: _selectedVelodrome,
        incomingRiderMassKg: _selectedAthlete.massKg,
        incomingBike: _currentBike,
        incomingSpeedMs: _slingIncomingSpeedKmh / 3.6,
        outgoingRiderMassKg: 73.0,
        outgoingBike: _currentBike,
        outgoingSpeedMs: _slingOutgoingSpeedKmh / 3.6,
        incomingSlingSkill: _selectedAthlete.slingSkill,
        outgoingSlingSkill: 94.0,
        teamChemistry: _madisonTeamChemistry,
        longitudinalGapMeters: _slingLongitudinalGapM,
        lateralGapMeters: _slingLateralGapM,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isMobile = width < 640;
            final bool isDesktop = width >= 1120;

            return Column(
              children: [
                _buildTopHeader(isMobile: isMobile),
                _buildDisciplineTabs(isMobile: isMobile),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 20),
                    child: isDesktop
                        ? _buildDesktopBentoGrid()
                        : _buildStackedLayout(isMobile: isMobile),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NAGŁÓWEK I PASEK DYSCYPLIN
  // ---------------------------------------------------------------------------

  Widget _buildTopHeader({required bool isMobile}) {
    final double aeroRed =
        _selectedVelodrome.aeroDragReductionPercentVsSeaLevel;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
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
                _InteractiveActionButton(
                  tooltip: 'Powrót',
                  icon: Icons.arrow_back_rounded,
                  onPressed: widget.onBack,
                  compact: true,
                ),
                const SizedBox(width: 10),
              ],
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
                  Icons.stadium_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mistrzostwa Torowe UCI',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_selectedVelodrome.name} • ${_selectedVelodrome.turnBankingDegrees.toStringAsFixed(0)}° wiraż',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
              _MetricPillBadge(
                label: 'Aero',
                value:
                    '${aeroRed >= 0 ? '-' : '+'}${aeroRed.abs().toStringAsFixed(1)}% CdA',
                accentColor: AppColors.cyanAccent,
              ),
              _MetricPillBadge(
                label: 'Napęd',
                value: _currentBike.gearingLabel,
                accentColor: AppColors.goldAccent,
              ),
              _InteractiveActionButton(
                label: isMobile ? 'Symuluj' : 'Symuluj ${_discipline.titlePl}',
                icon: Icons.play_arrow_rounded,
                isPrimary: true,
                onPressed: _runCurrentDisciplineSimulation,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineTabs({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: TrackChampionshipDiscipline.values.map((disc) {
          final bool selected = disc == _discipline;
          return _InteractiveDisciplineTab(
            discipline: disc,
            selected: selected,
            onTap: () => setState(() => _discipline = disc),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UKŁADY RESPONSYWNE (DESKTOP BENTO VS TABLET/MOBILE STACK)
  // ---------------------------------------------------------------------------

  Widget _buildDesktopBentoGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildArenaAndSetupCard(isMobile: false),
              const SizedBox(height: 16),
              _build3dOrInteractiveModule(isDesktop: true),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: _buildResultsAndTelemetryPanel(isMobile: false),
        ),
      ],
    );
  }

  Widget _buildStackedLayout({required bool isMobile}) {
    return Column(
      children: [
        _buildArenaAndSetupCard(isMobile: isMobile),
        const SizedBox(height: 14),
        _build3dOrInteractiveModule(isDesktop: false),
        const SizedBox(height: 14),
        _buildResultsAndTelemetryPanel(isMobile: isMobile),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PANEL KONFIGURACJI WELODROMU, PRZEŁOŻENIA I ZAWODNIKA
  // ---------------------------------------------------------------------------

  Widget _buildArenaAndSetupCard({required bool isMobile}) {
    const velodromes = VelodromeTrackAndHourRecordModel.defaultVelodromes;
    const roster = TrackChampionshipAthlete.defaultRoster;

    return _SectionCard(
      title: 'Welodrom i Przygotowanie Sprzętu',
      subtitle: _discipline.subtitlePl,
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SubLabel('Wybierz Welodrom 250 m'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: velodromes.map((v) {
              final bool isSelected = v.id == _selectedVelodrome.id;
              return _InteractiveChip(
                label: '${v.city} (${v.countryCode})',
                sublabel: '${v.altitudeMeters.toStringAsFixed(0)} m',
                selected: isSelected,
                onTap: () {
                  setState(() => _selectedVelodrome = v);
                  _runCurrentDisciplineSimulation();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const _SubLabel('Zawodnik / Lider Reprezentacji'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roster.take(6).map((athlete) {
              final bool isSelected = athlete.id == _selectedAthlete.id;
              return _InteractiveChip(
                label: athlete.name,
                sublabel: athlete.nationCode,
                selected: isSelected,
                accentColor: athlete.jerseyColor,
                onTap: () {
                  setState(() {
                    _selectedAthlete = athlete;
                    _chainringTeeth = athlete.preferredChainring;
                    _cogTeeth = athlete.preferredCog;
                  });
                  _runCurrentDisciplineSimulation();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _buildFixedGearSelector(isMobile: isMobile),
          const SizedBox(height: 14),
          _buildDisciplineSpecificControls(isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildFixedGearSelector({required bool isMobile}) {
    final FixedGearTrackBike bike = _currentBike;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Ostre Koło (Fixed Gear UCI)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bike.isUciTrackLegal
                      ? AppColors.statusSuccess.withValues(alpha: 0.16)
                      : AppColors.crimsonAlert.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bike.isUciTrackLegal ? 'UCI LEGAL' : 'NIELEGALNY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: bike.isUciTrackLegal
                        ? AppColors.statusSuccess
                        : AppColors.crimsonAlert,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _StepperControl(
                label: 'Tarcza (T)',
                valueText: '${_chainringTeeth}T',
                canDecrement:
                    _chainringTeeth > FixedGearTrackBike.minChainringTeeth,
                canIncrement:
                    _chainringTeeth < FixedGearTrackBike.maxChainringTeeth,
                onDecrement: () => setState(() => _chainringTeeth--),
                onIncrement: () => setState(() => _chainringTeeth++),
              ),
              _StepperControl(
                label: 'Zębatka (T)',
                valueText: '${_cogTeeth}T',
                canDecrement: _cogTeeth > FixedGearTrackBike.minCogTeeth,
                canIncrement: _cogTeeth < FixedGearTrackBike.maxCogTeeth,
                onDecrement: () => setState(() => _cogTeeth--),
                onIncrement: () => setState(() => _cogTeeth++),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _InlineStat(
                label: 'Przełożenie',
                value: bike.gearRatio.toStringAsFixed(2),
              ),
              _InlineStat(
                label: 'Rozwinięcie',
                value: '${bike.developmentMeters.toStringAsFixed(2)} m',
              ),
              _InlineStat(
                label: 'Gear Inches',
                value: '${bike.gearInches.toStringAsFixed(1)}"',
              ),
              _InlineStat(
                label: '130 RPM',
                value:
                    '${bike.speedKmhFromCadence(130).toStringAsFixed(1)} km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineSpecificControls({required bool isMobile}) {
    switch (_discipline) {
      case TrackChampionshipDiscipline.keirin:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SubLabel('Pozycja Startowa za Motocyklem Derny (1–6)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(6, (idx) {
                final int slot = idx + 1;
                return _InteractiveChip(
                  label: 'Tor #$slot',
                  selected: _keirinStartingSlot == slot,
                  onTap: () => setState(() => _keirinStartingSlot = slot),
                );
              }),
            ),
            const SizedBox(height: 10),
            _LabeledSlider(
              label: 'Prędkość zjazdu Derny',
              valueLabel: '${_dernyTargetSpeedKmh.toStringAsFixed(1)} km/h',
              value: _dernyTargetSpeedKmh,
              min: 45.0,
              max: 52.0,
              divisions: 14,
              onChanged: (v) => setState(() => _dernyTargetSpeedKmh = v),
            ),
          ],
        );

      case TrackChampionshipDiscipline.madison:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SubLabel('Dystans Wyścigu Madison'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InteractiveChip(
                  label: '30 km (120 okr.)',
                  selected: _madisonLaps == 120,
                  onTap: () => setState(() => _madisonLaps = 120),
                ),
                _InteractiveChip(
                  label: '50 km (200 okr.)',
                  selected: _madisonLaps == 200,
                  onTap: () => setState(() => _madisonLaps = 200),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _LabeledSlider(
              label: 'Interwał zmian Hand Sling',
              valueLabel: 'co $_madisonExchangeInterval okr.',
              value: _madisonExchangeInterval.toDouble(),
              min: 2.0,
              max: 5.0,
              divisions: 3,
              onChanged: (v) =>
                  setState(() => _madisonExchangeInterval = v.round()),
            ),
            _LabeledSlider(
              label: 'Zgranie pary (Team Chemistry)',
              valueLabel: '${_madisonTeamChemistry.toStringAsFixed(0)}%',
              value: _madisonTeamChemistry,
              min: 60.0,
              max: 100.0,
              divisions: 40,
              onChanged: (v) => setState(() => _madisonTeamChemistry = v),
            ),
          ],
        );

      case TrackChampionshipDiscipline.omnium:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Text(
            'Format Olimpijski Omnium: 4 konkurencje w jeden dzień '
            '(Scratch 10 km, Tempo 10 km, Eliminacja, Wyścig Punktowy 25 km). '
            'Punkty z pierwszych 3 konkurencji (40–38–36...) sumują się z bilansem finałowego Wyścigu Punktowego.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        );

      case TrackChampionshipDiscipline.pointsRace:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SubLabel('Dystans Wyścigu Punktowego'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InteractiveChip(
                  label: '25 km (100 okr.)',
                  selected: _pointsRaceLaps == 100,
                  onTap: () => setState(() => _pointsRaceLaps = 100),
                ),
                _InteractiveChip(
                  label: '40 km (160 okr.)',
                  selected: _pointsRaceLaps == 160,
                  onTap: () => setState(() => _pointsRaceLaps = 160),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _LabeledSlider(
              label: 'Agresywność ataków po okrążenie (+20 pkt)',
              valueLabel: '${(_pointsAggression * 100).toStringAsFixed(0)}%',
              value: _pointsAggression,
              min: 0.2,
              max: 1.0,
              divisions: 16,
              onChanged: (v) => setState(() => _pointsAggression = v),
            ),
          ],
        );
    }
  }

  // ---------------------------------------------------------------------------
  // MODUŁ 3D WELODROMU & INTERAKTYWNE LABORATORIUM HAND SLING
  // ---------------------------------------------------------------------------

  Widget _build3dOrInteractiveModule({required bool isDesktop}) {
    final VelodromeTrackDisciplineMode mode3d =
        _discipline == TrackChampionshipDiscipline.keirin
            ? VelodromeTrackDisciplineMode.keirin
            : VelodromeTrackDisciplineMode.madison;

    return Column(
      children: [
        _SectionCard(
          title: 'Podgląd 3D Welodromu (${mode3d.shortTag})',
          subtitle: '${_selectedVelodrome.city} • Drewniany tor 250 m',
          icon: Icons.view_in_ar_rounded,
          child: SizedBox(
            height: isDesktop ? 390 : 340,
            child: VelodromeMadisonHandSlingViewportWidget(
              key: ValueKey('${_selectedVelodrome.id}_${mode3d.name}'),
              initialConfig: VelodromeMadisonKeirinConfig(
                facility: _selectedVelodrome,
                discipline: mode3d,
                cameraMode: mode3d == VelodromeTrackDisciplineMode.keirin
                    ? MadisonKeirinCameraMode.dernyMoto
                    : MadisonKeirinCameraMode.chaseSling,
              ),
            ),
          ),
        ),
        if (_discipline == TrackChampionshipDiscipline.madison) ...[
          const SizedBox(height: 16),
          _buildHandSlingPhysicsLab(),
        ],
      ],
    );
  }

  Widget _buildHandSlingPhysicsLab() {
    final MadisonHandSlingResult sling = _liveSlingPreview;
    final Color qualityColor = switch (sling.quality) {
      MadisonSlingQuality.textbookSlingshot => AppColors.goldAccent,
      MadisonSlingQuality.cleanExchange => AppColors.statusSuccess,
      MadisonSlingQuality.awkwardFumble => AppColors.amberWarning,
      MadisonSlingQuality.missedHandTouch ||
      MadisonSlingQuality.illegalPushOrCrash =>
        AppColors.crimsonAlert,
    };

    return _SectionCard(
      title: 'Laboratorium Fizyki Hand Sling',
      subtitle: 'Zasada zachowania pędu pary i impuls mięśniowy ramion',
      icon: Icons.science_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: qualityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: qualityColor.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: qualityColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sling.quality.labelPl,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: qualityColor,
                        ),
                      ),
                      Text(
                        'Sprawność ${(sling.transferEfficiency * 100).toStringAsFixed(0)}% • '
                        'Zysk +${sling.outgoingSpeedGainKmh.toStringAsFixed(1)} km/h • '
                        'Impuls ${sling.transferredImpulseNs.toStringAsFixed(0)} N·s',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _LabeledSlider(
            label: 'Prędkość nadjeżdżającego',
            valueLabel: '${_slingIncomingSpeedKmh.toStringAsFixed(1)} km/h',
            value: _slingIncomingSpeedKmh,
            min: 44.0,
            max: 64.0,
            divisions: 40,
            onChanged: (v) => setState(() => _slingIncomingSpeedKmh = v),
          ),
          _LabeledSlider(
            label: 'Prędkość odbierającego (góra toru)',
            valueLabel: '${_slingOutgoingSpeedKmh.toStringAsFixed(1)} km/h',
            value: _slingOutgoingSpeedKmh,
            min: 28.0,
            max: 45.0,
            divisions: 34,
            onChanged: (v) => setState(() => _slingOutgoingSpeedKmh = v),
          ),
          _LabeledSlider(
            label: 'Odstęp wzdłużny w chwili chwytu',
            valueLabel: '${_slingLongitudinalGapM.toStringAsFixed(2)} m',
            value: _slingLongitudinalGapM,
            min: 0.0,
            max: 1.5,
            divisions: 30,
            onChanged: (v) => setState(() => _slingLongitudinalGapM = v),
          ),
          _LabeledSlider(
            label: 'Odstęp poprzeczny (ramię)',
            valueLabel: '${_slingLateralGapM.toStringAsFixed(2)} m',
            value: _slingLateralGapM,
            min: 0.3,
            max: 1.6,
            divisions: 26,
            onChanged: (v) => setState(() => _slingLateralGapM = v),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WYNIKI, PODIUM I TELEMETRIA WYŚCIGÓW
  // ---------------------------------------------------------------------------

  Widget _buildResultsAndTelemetryPanel({required bool isMobile}) {
    switch (_discipline) {
      case TrackChampionshipDiscipline.keirin:
        return _buildKeirinResultsPanel(isMobile: isMobile);
      case TrackChampionshipDiscipline.madison:
        return _buildMadisonResultsPanel(isMobile: isMobile);
      case TrackChampionshipDiscipline.omnium:
        return _buildOmniumResultsPanel(isMobile: isMobile);
      case TrackChampionshipDiscipline.pointsRace:
        return _buildPointsRaceResultsPanel(isMobile: isMobile);
    }
  }

  Widget _buildKeirinResultsPanel({required bool isMobile}) {
    final KeirinRaceSimulationResult? result = _keirinResult;
    if (result == null || result.standings.isEmpty) {
      return const _EmptyStateCard(message: 'Brak wyników symulacji Keirin.');
    }
    final KeirinRiderRaceOutcome winner = result.standings.first;

    return _SectionCard(
      title: 'Klasyfikacja Finału Keirin (1500 m)',
      subtitle:
          'Zjazd Derny przy ${result.dernyPullOffSpeedKmh.toStringAsFixed(1)} km/h',
      icon: Icons.leaderboard_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChampionBanner(
            title: 'Mistrz Świata Keirin',
            championName: winner.name,
            metricHighlight:
                '${winner.finishTimeSeconds.toStringAsFixed(2)} s • Szczyt ${winner.peakSpeedKmh.toStringAsFixed(1)} km/h',
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.surfaceLight.withValues(alpha: 0.5);
                }
                return Colors.transparent;
              }),
              columnSpacing: isMobile ? 14 : 22,
              columns: const [
                DataColumn(label: _TableHeader('#')),
                DataColumn(label: _TableHeader('Zawodnik')),
                DataColumn(label: _TableHeader('Czas'), numeric: true),
                DataColumn(label: _TableHeader('Vmax'), numeric: true),
                DataColumn(label: _TableHeader('Derny'), numeric: true),
                DataColumn(label: _TableHeader('W\' res'), numeric: true),
              ],
              rows: result.standings.map((row) {
                final bool isFocus = row.riderId == _selectedAthlete.id;
                return DataRow(
                  color: isFocus
                      ? WidgetStateProperty.all(
                          AppColors.goldAccent.withValues(alpha: 0.12),
                        )
                      : null,
                  cells: [
                    DataCell(_RankBadge(rank: row.finishingPosition)),
                    DataCell(
                      Text(
                        row.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight:
                              isFocus ? FontWeight.w700 : FontWeight.w500,
                          color: isFocus
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    DataCell(_TabularText(
                        '${row.finishTimeSeconds.toStringAsFixed(2)} s')),
                    DataCell(_TabularText(
                        '${row.peakSpeedKmh.toStringAsFixed(1)} km/h')),
                    DataCell(_TabularText(
                        '${row.speedAtDernyPullOffKmh.toStringAsFixed(1)} km/h')),
                    DataCell(_TabularText(
                        '${(row.remainingWPrimeJoules / 1000.0).toStringAsFixed(1)} kJ')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMadisonResultsPanel({required bool isMobile}) {
    final MadisonRaceSimulationResult? result = _madisonResult;
    if (result == null || result.standings.isEmpty) {
      return const _EmptyStateCard(message: 'Brak wyników symulacji Madison.');
    }
    final MadisonTeamStanding winner = result.standings.first;

    return _SectionCard(
      title: 'Klasyfikacja Madison (${result.config.totalLaps} okrążeń)',
      subtitle: 'Sprinty co ${result.config.sprintIntervalLaps} okrążeń • ±20 pkt za okrążenie',
      icon: Icons.leaderboard_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChampionBanner(
            title: 'Mistrzowie Świata Madison',
            championName: winner.teamName,
            metricHighlight:
                '${winner.totalPoints} pkt • Śr. ${winner.averageSpeedKmh.toStringAsFixed(1)} km/h',
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight),
              columnSpacing: isMobile ? 14 : 20,
              columns: const [
                DataColumn(label: _TableHeader('#')),
                DataColumn(label: _TableHeader('Para')),
                DataColumn(label: _TableHeader('Suma'), numeric: true),
                DataColumn(label: _TableHeader('Sprinty'), numeric: true),
                DataColumn(label: _TableHeader('Okr.'), numeric: true),
                DataColumn(label: _TableHeader('Slingi'), numeric: true),
                DataColumn(label: _TableHeader('+km/h'), numeric: true),
              ],
              rows: result.standings.map((row) {
                final bool isPol = row.teamId == 'pair_pol';
                return DataRow(
                  color: isPol
                      ? WidgetStateProperty.all(
                          AppColors.goldAccent.withValues(alpha: 0.12),
                        )
                      : null,
                  cells: [
                    DataCell(_RankBadge(rank: row.rank)),
                    DataCell(
                      Text(
                        row.teamName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight:
                              isPol ? FontWeight.w700 : FontWeight.w500,
                          color: isPol
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    DataCell(_TabularText('${row.totalPoints} pkt', bold: true)),
                    DataCell(_TabularText('${row.sprintPoints}')),
                    DataCell(_TabularText(
                      row.lapBalance >= 0
                          ? '+${row.lapBalance}'
                          : '${row.lapBalance}',
                    )),
                    DataCell(_TabularText(
                        '${row.successfulHandSlings}/${row.totalHandSlings}')),
                    DataCell(_TabularText(
                        '+${row.averageSlingBoostKmh.toStringAsFixed(1)}')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOmniumResultsPanel({required bool isMobile}) {
    final OmniumSimulationResult? result = _omniumResult;
    if (result == null || result.standings.isEmpty) {
      return const _EmptyStateCard(message: 'Brak wyników symulacji Omnium.');
    }
    final OmniumEventStanding winner = result.standings.first;

    return _SectionCard(
      title: 'Tabela Generalna Omnium (4 Konkurencje)',
      subtitle: 'Scratch + Tempo + Eliminacja + Finał Punktowy',
      icon: Icons.emoji_events_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChampionBanner(
            title: 'Mistrz Świata Omnium',
            championName: '${winner.athlete.name} (${winner.athlete.nationCode})',
            metricHighlight: '${winner.totalOmniumPoints} pkt łącznych',
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight),
              columnSpacing: isMobile ? 12 : 18,
              columns: const [
                DataColumn(label: _TableHeader('#')),
                DataColumn(label: _TableHeader('Zawodnik')),
                DataColumn(label: _TableHeader('Scratch'), numeric: true),
                DataColumn(label: _TableHeader('Tempo'), numeric: true),
                DataColumn(label: _TableHeader('Elim.'), numeric: true),
                DataColumn(label: _TableHeader('Punktowy'), numeric: true),
                DataColumn(label: _TableHeader('SUMA'), numeric: true),
              ],
              rows: result.standings.map((row) {
                final bool isFocus = row.athlete.id == _selectedAthlete.id;
                return DataRow(
                  color: isFocus
                      ? WidgetStateProperty.all(
                          AppColors.goldAccent.withValues(alpha: 0.12),
                        )
                      : null,
                  cells: [
                    DataCell(_RankBadge(rank: row.rank)),
                    DataCell(
                      Text(
                        '${row.athlete.name} (${row.athlete.nationCode})',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight:
                              isFocus ? FontWeight.w700 : FontWeight.w500,
                          color: isFocus
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    DataCell(_TabularText(
                        '${row.scratchPoints} (${row.scratchRank}.)')),
                    DataCell(
                        _TabularText('${row.tempoPoints} (${row.tempoRank}.)')),
                    DataCell(_TabularText(
                        '${row.eliminationPoints} (${row.eliminationRank}.)')),
                    DataCell(_TabularText(
                      row.pointsRaceDelta >= 0
                          ? '+${row.pointsRaceDelta}'
                          : '${row.pointsRaceDelta}',
                    )),
                    DataCell(
                        _TabularText('${row.totalOmniumPoints}', bold: true)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsRaceResultsPanel({required bool isMobile}) {
    final PointsRaceSimulationResult? result = _pointsResult;
    if (result == null || result.standings.isEmpty) {
      return const _EmptyStateCard(
          message: 'Brak wyników symulacji Wyścigu Punktowego.');
    }
    final PointsRaceStanding winner = result.standings.first;

    return _SectionCard(
      title: 'Wyścig Punktowy (${result.totalLaps} okrążeń)',
      subtitle:
          'Sprinty co ${result.sprintIntervalLaps} okrążeń • Finał podwójnie punktowany',
      icon: Icons.scoreboard_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChampionBanner(
            title: 'Mistrz Świata Wyścigu Punktowego',
            championName:
                '${winner.athlete.name} (${winner.athlete.nationCode})',
            metricHighlight:
                '${winner.totalPoints} pkt • ${winner.avgSpeedKmh.toStringAsFixed(1)} km/h',
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight),
              columnSpacing: isMobile ? 12 : 18,
              columns: const [
                DataColumn(label: _TableHeader('#')),
                DataColumn(label: _TableHeader('Zawodnik')),
                DataColumn(label: _TableHeader('Suma'), numeric: true),
                DataColumn(label: _TableHeader('Sprinty'), numeric: true),
                DataColumn(label: _TableHeader('Okr.'), numeric: true),
                DataColumn(label: _TableHeader('Wyg. spr.'), numeric: true),
                DataColumn(label: _TableHeader('Śr. km/h'), numeric: true),
              ],
              rows: result.standings.map((row) {
                final bool isFocus = row.athlete.id == _selectedAthlete.id;
                return DataRow(
                  color: isFocus
                      ? WidgetStateProperty.all(
                          AppColors.goldAccent.withValues(alpha: 0.12),
                        )
                      : null,
                  cells: [
                    DataCell(_RankBadge(rank: row.rank)),
                    DataCell(
                      Text(
                        '${row.athlete.name} (${row.athlete.nationCode})',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight:
                              isFocus ? FontWeight.w700 : FontWeight.w500,
                          color: isFocus
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    DataCell(_TabularText('${row.totalPoints} pkt', bold: true)),
                    DataCell(_TabularText('${row.sprintPoints}')),
                    DataCell(_TabularText(
                      row.lapBalance >= 0
                          ? '+${row.lapBalance}'
                          : '${row.lapBalance}',
                    )),
                    DataCell(_TabularText('${row.sprintsWon}')),
                    DataCell(_TabularText(row.avgSpeedKmh.toStringAsFixed(1))),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          const _SubLabel('Przebieg Sprintów Pośrednich'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.sprintLogs.map((log) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: log.isFinalDouble
                      ? AppColors.goldAccent.withValues(alpha: 0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: log.isFinalDouble
                        ? AppColors.goldAccent
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  'Okr. ${log.lapNumber}${log.isFinalDouble ? " (x2)" : ""}: '
                  '${log.winnerNation} (+${log.awardedTopPoints})',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight:
                        log.isFinalDouble ? FontWeight.w700 : FontWeight.w500,
                    color: log.isFinalDouble
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. KOMPONENTY UI Z PEŁNYMI STANAMI HOVER / ACTIVE / DISABLED / FOCUS
// =============================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.goldAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InteractiveDisciplineTab extends StatefulWidget {
  final TrackChampionshipDiscipline discipline;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveDisciplineTab({
    required this.discipline,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveDisciplineTab> createState() =>
      _InteractiveDisciplineTabState();
}

class _InteractiveDisciplineTabState extends State<_InteractiveDisciplineTab> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.surface;
    final Color border = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
                width: widget.selected || _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.discipline.icon,
                  size: 18,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.discipline.titlePl,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

class _InteractiveChip extends StatefulWidget {
  final String label;
  final String? sublabel;
  final bool selected;
  final Color? accentColor;
  final VoidCallback? onTap;

  const _InteractiveChip({
    required this.label,
    this.sublabel,
    required this.selected,
    this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onTap == null;
    final Color activeColor = widget.accentColor ?? AppColors.goldAccent;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: disabled
                  ? AppColors.surface.withValues(alpha: 0.4)
                  : widget.selected
                      ? activeColor.withValues(alpha: 0.18)
                      : _hovered
                          ? AppColors.surfaceLight
                          : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: disabled
                    ? AppColors.cardBorder.withValues(alpha: 0.4)
                    : widget.selected
                        ? activeColor
                        : _focused
                            ? AppColors.accentBlue
                            : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                      color: disabled
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (widget.sublabel != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.sublabel!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.selected
                          ? activeColor
                          : AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String? label;
  final String? tooltip;
  final IconData icon;
  final bool isPrimary;
  final bool compact;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    this.label,
    this.tooltip,
    required this.icon,
    this.isPrimary = false,
    this.compact = false,
    required this.onPressed,
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
    final bool disabled = widget.onPressed == null;
    final Color bg = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isPrimary
            ? (_hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.9)
                : AppColors.primaryAccent)
            : (_hovered ? AppColors.surfaceLight : AppColors.background);

    final Widget button = FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 9 : 14,
              vertical: widget.compact ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.accentBlue
                    : widget.isPrimary
                        ? AppColors.goldAccent.withValues(alpha: 0.7)
                        : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: disabled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: disabled
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

class _StepperControl extends StatelessWidget {
  final String label;
  final String valueText;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperControl({
    required this.label,
    required this.valueText,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        _InteractiveActionButton(
          icon: Icons.remove_rounded,
          compact: true,
          onPressed: canDecrement ? onDecrement : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            valueText,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _InteractiveActionButton(
          icon: Icons.add_rounded,
          compact: true,
          onPressed: canIncrement ? onIncrement : null,
        ),
      ],
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ChampionBanner extends StatelessWidget {
  final String title;
  final String championName;
  final String metricHighlight;

  const _ChampionBanner({
    required this.title,
    required this.championName,
    required this.metricHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.goldAccent.withValues(alpha: 0.22),
            AppColors.primaryAccent.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.goldAccent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.goldAccent,
                  ),
                ),
                Text(
                  championName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  metricHighlight,
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
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (rank) {
      1 => AppColors.goldAccent,
      2 => const Color(0xFFD1D5DB),
      3 => const Color(0xFFD97706),
      _ => AppColors.textSecondary,
    };
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: rank <= 3 ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MetricPillBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _MetricPillBadge({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String label;
  final String value;

  const _InlineStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String text;

  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _TabularText extends StatelessWidget {
  final String text;
  final bool bold;

  const _TabularText(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12.5,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: bold ? AppColors.goldAccent : AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;

  const _EmptyStateCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Brak danych',
      subtitle: 'Uruchom symulację',
      icon: Icons.info_outline_rounded,
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
