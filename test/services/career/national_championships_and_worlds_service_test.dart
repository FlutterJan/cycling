// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/services/career/national_championships_and_worlds_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  group('NationalChampionshipsAndWorldsService & Models Tests', () {
    Rider createTestRider({
      required String id,
      required String firstName,
      required String lastName,
      required String nationalityIso,
      int watts20m = 420,
      int watts5s = 1300,
      int timeTrialPositioning = 80,
      int punch = 80,
      int raceIq = 80,
      double weightKg = 68.0,
    }) {
      final base = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        targetOverallRating: 88,
      );
      return base.copyWith(
        id: id,
        firstName: firstName,
        lastName: lastName,
        nationalityIso: nationalityIso,
        powerProfile: RiderPowerProfile(
          watts5s: watts5s,
          watts15s: 1100,
          watts30s: 900,
          watts1m: 680,
          watts3m: 540,
          watts5m: 480,
          watts20m: watts20m,
          watts60m: (watts20m * 0.95).round(),
        ),
        skills: base.skills.copyWith(
          bikeHandling: punch,
          raceIq: raceIq,
          timeTrialPositioning: timeTrialPositioning,
        ),
        physiology: base.physiology.copyWith(
          weightKg: weightKg,
        ),
      );
    }

    test('ChampionshipDiscipline enum serialization and labels', () {
      expect(ChampionshipDiscipline.roadRace.polishLabel, 'Wyścig ze startu wspólnego');
      expect(ChampionshipDiscipline.roadRace.englishLabel, 'Road Race');
      expect(ChampionshipDiscipline.roadRace.toJson(), 'roadRace');
      expect(ChampionshipDiscipline.fromJson('roadRace'), ChampionshipDiscipline.roadRace);
      expect(ChampionshipDiscipline.fromJson('individualTimeTrial'), ChampionshipDiscipline.individualTimeTrial);
      expect(ChampionshipDiscipline.fromJson('unknown'), ChampionshipDiscipline.roadRace);
    });

    test('ChampionshipLevel enum serialization and calendar month', () {
      expect(ChampionshipLevel.national.calendarMonth, 6);
      expect(ChampionshipLevel.world.calendarMonth, 9);
      expect(ChampionshipLevel.national.toJson(), 'national');
      expect(ChampionshipLevel.fromJson('national'), ChampionshipLevel.national);
      expect(ChampionshipLevel.fromJson('world'), ChampionshipLevel.world);
      expect(ChampionshipLevel.fromJson('invalid'), ChampionshipLevel.national);
    });

    test('SpecialJerseyDesignation enum serialization', () {
      expect(SpecialJerseyDesignation.rainbowJersey.toJson(), 'rainbowJersey');
      expect(SpecialJerseyDesignation.fromJson('rainbowJersey'), SpecialJerseyDesignation.rainbowJersey);
      expect(SpecialJerseyDesignation.fromJson('nationalChampionJersey'), SpecialJerseyDesignation.nationalChampionJersey);
      expect(SpecialJerseyDesignation.fromJson('formerWorldChampionRainbowBands'), SpecialJerseyDesignation.formerWorldChampionRainbowBands);
      expect(SpecialJerseyDesignation.fromJson('standardTeamJersey'), SpecialJerseyDesignation.standardTeamJersey);
      expect(SpecialJerseyDesignation.fromJson('unknown'), SpecialJerseyDesignation.standardTeamJersey);
    });

    test('ChampionshipTitle toJson and fromJson roundtrip', () {
      final title = ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.world,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: 'WORLD',
        winnerRiderId: 'tadej-1',
        winnerRiderName: 'Tadej Pogačar',
        winningTradeTeamName: 'UAE Team Emirates',
        dateAwarded: DateTime(2026, 9, 27),
        uciPointsAwarded: 900,
      );

      final json = title.toJson();
      final revived = ChampionshipTitle.fromJson(json);

      expect(revived.year, 2026);
      expect(revived.level, ChampionshipLevel.world);
      expect(revived.discipline, ChampionshipDiscipline.roadRace);
      expect(revived.winnerRiderId, 'tadej-1');
      expect(revived.winnerRiderName, 'Tadej Pogačar');
      expect(revived.uciPointsAwarded, 900);
    });

    test('ChampionshipPodiumResult ranking badges and JSON roundtrip', () {
      const r1 = ChampionshipPodiumResult(
        rank: 1,
        riderId: 'r-1',
        riderName: 'Remco Evenepoel',
        nationalityIso: 'BEL',
        tradeTeamName: 'Soudal Quick-Step',
        finishTime: Duration(hours: 5, minutes: 42, seconds: 10),
        timeGapToWinner: Duration.zero,
        uciPoints: 900,
      );
      const r2 = ChampionshipPodiumResult(
        rank: 2,
        riderId: 'r-2',
        riderName: 'Wout van Aert',
        nationalityIso: 'BEL',
        tradeTeamName: 'Visma-Lease a Bike',
        finishTime: Duration(hours: 5, minutes: 42, seconds: 12),
        timeGapToWinner: Duration(seconds: 2),
        uciPoints: 600,
      );
      const r3 = ChampionshipPodiumResult(
        rank: 3,
        riderId: 'r-3',
        riderName: 'Mathieu van der Poel',
        nationalityIso: 'NED',
        tradeTeamName: 'Alpecin-Deceuninck',
        finishTime: Duration(hours: 5, minutes: 42, seconds: 15),
        timeGapToWinner: Duration(seconds: 5),
        uciPoints: 450,
      );

      expect(r1.isGold, isTrue);
      expect(r1.isSilver, isFalse);
      expect(r1.isBronze, isFalse);

      expect(r2.isGold, isFalse);
      expect(r2.isSilver, isTrue);
      expect(r2.isBronze, isFalse);

      expect(r3.isGold, isFalse);
      expect(r3.isSilver, isFalse);
      expect(r3.isBronze, isTrue);

      final revived = ChampionshipPodiumResult.fromJson(r2.toJson());
      expect(revived.rank, 2);
      expect(revived.riderId, 'r-2');
      expect(revived.timeGapToWinner.inSeconds, 2);
    });

    test('ChampionshipRaceResult toJson and fromJson roundtrip', () {
      const raceResult = ChampionshipRaceResult(
        raceId: 'champ_world_roadRace_world_2026',
        year: 2026,
        level: ChampionshipLevel.world,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: 'WORLD',
        raceName: 'UCI Road World Championships • Montreal 2026',
        hostCity: 'Montreal',
        distanceKm: 268.0,
        results: [
          ChampionshipPodiumResult(
            rank: 1,
            riderId: 'r-1',
            riderName: 'Tadej Pogačar',
            nationalityIso: 'SLO',
            tradeTeamName: 'UAE Team Emirates',
            finishTime: Duration(hours: 6, minutes: 12),
            timeGapToWinner: Duration.zero,
            uciPoints: 900,
          ),
        ],
      );

      expect(raceResult.winner.riderId, 'r-1');
      final json = raceResult.toJson();
      final revived = ChampionshipRaceResult.fromJson(json);

      expect(revived.raceId, raceResult.raceId);
      expect(revived.distanceKm, 268.0);
      expect(revived.results.length, 1);
      expect(revived.winner.riderName, 'Tadej Pogačar');
    });

    test('ReigningChampionsRegistry records titles and serializes correctly', () {
      final registry = ReigningChampionsRegistry();

      final polandRoadTitle = ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.national,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: 'POL',
        winnerRiderId: 'michal-k',
        winnerRiderName: 'Michał Kwiatkowski',
        winningTradeTeamName: 'Ineos Grenadiers',
        dateAwarded: DateTime(2026, 6, 28),
        uciPointsAwarded: 100,
      );

      final polandIttTitle = ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.national,
        discipline: ChampionshipDiscipline.individualTimeTrial,
        countryIso: 'POL',
        winnerRiderId: 'maciej-b',
        winnerRiderName: 'Maciej Bodnar',
        winningTradeTeamName: 'TotalEnergies',
        dateAwarded: DateTime(2026, 6, 25),
        uciPointsAwarded: 70,
      );

      final worldRoadTitle = ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.world,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: 'WORLD',
        winnerRiderId: 'mvdp-1',
        winnerRiderName: 'Mathieu van der Poel',
        winningTradeTeamName: 'Alpecin-Deceuninck',
        dateAwarded: DateTime(2026, 9, 27),
        uciPointsAwarded: 900,
      );

      final worldIttTitle = ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.world,
        discipline: ChampionshipDiscipline.individualTimeTrial,
        countryIso: 'WORLD',
        winnerRiderId: 'remco-1',
        winnerRiderName: 'Remco Evenepoel',
        winningTradeTeamName: 'Soudal Quick-Step',
        dateAwarded: DateTime(2026, 9, 23),
        uciPointsAwarded: 600,
      );

      registry.registerNationalChampion(polandRoadTitle);
      registry.registerNationalChampion(polandIttTitle);
      registry.registerWorldChampion(worldRoadTitle);
      registry.registerWorldChampion(worldIttTitle);

      expect(registry.isReigningNationalChampion('michal-k', 'POL', isTimeTrial: false), isTrue);
      expect(registry.isReigningNationalChampion('maciej-b', 'POL', isTimeTrial: true), isTrue);
      expect(registry.isReigningNationalChampion('michal-k', 'POL', isTimeTrial: true), isFalse);

      expect(registry.isReigningWorldChampion('mvdp-1', isTimeTrial: false), isTrue);
      expect(registry.isReigningWorldChampion('remco-1', isTimeTrial: true), isTrue);
      expect(registry.isFormerWorldChampion('mvdp-1'), isTrue);
      expect(registry.isFormerWorldChampion('remco-1'), isTrue);
      expect(registry.isFormerWorldChampion('random-rider'), isFalse);

      // JSON serialization & revival
      final json = registry.toJson();
      final revivedRegistry = ReigningChampionsRegistry.fromJson(json);

      expect(revivedRegistry.isReigningNationalChampion('michal-k', 'POL'), isTrue);
      expect(revivedRegistry.isReigningNationalChampion('maciej-b', 'POL', isTimeTrial: true), isTrue);
      expect(revivedRegistry.isReigningWorldChampion('mvdp-1'), isTrue);
      expect(revivedRegistry.isReigningWorldChampion('remco-1', isTimeTrial: true), isTrue);
      expect(revivedRegistry.lifetimeWorldChampionRiderIds.contains('mvdp-1'), isTrue);
      expect(revivedRegistry.historicalTitlesArchive.length, 4);
    });

    test('National quota allocation and country names', () {
      expect(NationalChampionshipsAndWorldsService.getNationQuota('BEL'), 8);
      expect(NationalChampionshipsAndWorldsService.getNationQuota('FRA'), 8);
      expect(NationalChampionshipsAndWorldsService.getNationQuota('SLO'), 8);
      expect(NationalChampionshipsAndWorldsService.getNationQuota('POL'), 6);
      expect(NationalChampionshipsAndWorldsService.getNationQuota('USA'), 6);
      expect(NationalChampionshipsAndWorldsService.getNationQuota('POR'), 4);
      expect(NationalChampionshipsAndWorldsService.getNationQuota('JPN'), 2);

      expect(NationalChampionshipsAndWorldsService.getCountryName('POL'), 'Polska');
      expect(NationalChampionshipsAndWorldsService.getCountryName('FRA'), 'Francja');
      expect(NationalChampionshipsAndWorldsService.getCountryName('SLO'), 'Słowenia');
      expect(NationalChampionshipsAndWorldsService.getCountryName('XYZ'), 'XYZ');
    });

    test('draftNationalTeamsForWorldChampionships drafts squads with discipline specifics', () {
      final service = NationalChampionshipsAndWorldsService();
      final riders = [
        createTestRider(id: 'pol-1', firstName: 'Kamil', lastName: 'Gradek', nationalityIso: 'POL', timeTrialPositioning: 90, punch: 60),
        createTestRider(id: 'pol-2', firstName: 'Michał', lastName: 'Kwiatkowski', nationalityIso: 'POL', timeTrialPositioning: 75, punch: 92),
        createTestRider(id: 'pol-3', firstName: 'Rafał', lastName: 'Majka', nationalityIso: 'POL', timeTrialPositioning: 60, punch: 85),
        createTestRider(id: 'slo-1', firstName: 'Tadej', lastName: 'Pogačar', nationalityIso: 'SLO', timeTrialPositioning: 88, punch: 98, watts20m: 460),
        createTestRider(id: 'slo-2', firstName: 'Primož', lastName: 'Roglič', nationalityIso: 'SLO', timeTrialPositioning: 92, punch: 94, watts20m: 450),
      ];

      // Test Road Race draft
      final rrTeams = service.draftNationalTeamsForWorldChampionships(
        worldPool: riders,
        discipline: ChampionshipDiscipline.roadRace,
      );

      expect(rrTeams.length, 2);
      final polandRR = rrTeams.firstWhere((t) => t.countryIso == 'POL');
      // In RR, Kwiatkowski has higher punch, so he should be selected as leader
      expect(polandRR.leader.id, 'pol-2');
      expect(polandRR.selectedRiders.length, 3); // 3 available out of 6 quota

      // Test ITT draft (max 2 riders per country)
      final ittTeams = service.draftNationalTeamsForWorldChampionships(
        worldPool: riders,
        discipline: ChampionshipDiscipline.individualTimeTrial,
      );

      final polandITT = ittTeams.firstWhere((t) => t.countryIso == 'POL');
      expect(polandITT.selectedRiders.length, 2); // Capped at 2 riders for ITT
      expect(polandITT.leader.id, 'pol-1'); // Gradek has higher timeTrialPositioning (90)
    });

    test('simulateAllNationalChampionships executes RR and ITT and saves champions', () {
      final registry = ReigningChampionsRegistry();
      final service = NationalChampionshipsAndWorldsService(registry: registry);

      final riders = [
        createTestRider(id: 'pol-1', firstName: 'Stanisław', lastName: 'Aniołkowski', nationalityIso: 'POL', watts20m: 390, watts5s: 1500, punch: 75),
        createTestRider(id: 'pol-2', firstName: 'Michał', lastName: 'Kwiatkowski', nationalityIso: 'POL', watts20m: 430, watts5s: 1350, punch: 95),
        createTestRider(id: 'fra-1', firstName: 'Julian', lastName: 'Alaphilippe', nationalityIso: 'FRA', watts20m: 425, watts5s: 1380, punch: 96),
        createTestRider(id: 'fra-2', firstName: 'Rémi', lastName: 'Cavagna', nationalityIso: 'FRA', watts20m: 440, timeTrialPositioning: 92, punch: 70),
      ];

      final results = service.simulateAllNationalChampionships(
        year: 2026,
        worldPool: riders,
        targetCountries: ['POL', 'FRA'],
        randomSeed: 42,
      );

      // 2 countries * 2 disciplines = 4 races
      expect(results.length, 4);

      // Check Poland Road Race
      final polRoad = results.firstWhere((r) => r.countryIso == 'POL' && r.discipline == ChampionshipDiscipline.roadRace);
      expect(polRoad.distanceKm, 228.0);
      expect(polRoad.results.length, 2);
      expect(polRoad.winner.rank, 1);
      expect(polRoad.winner.uciPoints, 100);

      // Check Poland ITT
      final polItt = results.firstWhere((r) => r.countryIso == 'POL' && r.discipline == ChampionshipDiscipline.individualTimeTrial);
      expect(polItt.distanceKm, 38.0);
      expect(polItt.results.length, 2);
      expect(polItt.winner.uciPoints, 70);

      // Verify that champions got registered in the registry
      expect(registry.nationalRoadChampions.containsKey('POL'), isTrue);
      expect(registry.nationalIttChampions.containsKey('POL'), isTrue);
      expect(registry.nationalRoadChampions.containsKey('FRA'), isTrue);
      expect(registry.nationalIttChampions.containsKey('FRA'), isTrue);
    });

    test('simulateWorldChampionships crowns Rainbow Jersey and updates lifetime roster', () {
      final registry = ReigningChampionsRegistry();
      final service = NationalChampionshipsAndWorldsService(registry: registry);

      final riders = [
        createTestRider(id: 'slo-1', firstName: 'Tadej', lastName: 'Pogačar', nationalityIso: 'SLO', watts20m: 460, punch: 98),
        createTestRider(id: 'bel-1', firstName: 'Remco', lastName: 'Evenepoel', nationalityIso: 'BEL', watts20m: 450, punch: 92),
        createTestRider(id: 'ned-1', firstName: 'Mathieu', lastName: 'van der Poel', nationalityIso: 'NED', watts20m: 445, punch: 97),
      ];

      final worldRR = service.simulateWorldChampionships(
        year: 2026,
        worldPool: riders,
        discipline: ChampionshipDiscipline.roadRace,
        randomSeed: 99,
      );

      expect(worldRR.level, ChampionshipLevel.world);
      expect(worldRR.distanceKm, 268.0);
      expect(worldRR.hostCity, contains('Montreal'));
      expect(worldRR.results.length, 3);
      expect(worldRR.winner.uciPoints, 900);

      // Rainbow jersey check
      final rainbowChampId = worldRR.winner.riderId;
      expect(registry.isReigningWorldChampion(rainbowChampId, isTimeTrial: false), isTrue);
      expect(registry.isFormerWorldChampion(rainbowChampId), isTrue);
    });

    test('getRiderJerseyDesignation respects UCI jersey hierarchy', () {
      final registry = ReigningChampionsRegistry();
      final service = NationalChampionshipsAndWorldsService(registry: registry);

      // Setup: Rider A is both National Champion and World Champion!
      final worldTitle = ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.world,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: 'WORLD',
        winnerRiderId: 'rider-a',
        winnerRiderName: 'Rider A',
        winningTradeTeamName: 'Super Team',
        dateAwarded: DateTime(2026, 9, 27),
        uciPointsAwarded: 900,
      );
      final nationalTitle = ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.national,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: 'POL',
        winnerRiderId: 'rider-a',
        winnerRiderName: 'Rider A',
        winningTradeTeamName: 'Super Team',
        dateAwarded: DateTime(2026, 6, 28),
        uciPointsAwarded: 100,
      );

      registry.registerWorldChampion(worldTitle);
      registry.registerNationalChampion(nationalTitle);

      // Rider A should wear RAINBOW jersey (World > National)
      expect(
        service.getRiderJerseyDesignation(riderId: 'rider-a', nationalityIso: 'POL'),
        SpecialJerseyDesignation.rainbowJersey,
      );

      // Rider B is only National Champion of France
      final fraTitle = ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.national,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: 'FRA',
        winnerRiderId: 'rider-b',
        winnerRiderName: 'Rider B',
        winningTradeTeamName: 'Super Team',
        dateAwarded: DateTime(2026, 6, 28),
        uciPointsAwarded: 100,
      );
      registry.registerNationalChampion(fraTitle);

      expect(
        service.getRiderJerseyDesignation(riderId: 'rider-b', nationalityIso: 'FRA'),
        SpecialJerseyDesignation.nationalChampionJersey,
      );

      // Rider C is a former world champion whose 1-year rainbow tenure expired
      registry.lifetimeWorldChampionRiderIds.add('rider-c');
      expect(
        service.getRiderJerseyDesignation(riderId: 'rider-c', nationalityIso: 'ITA'),
        SpecialJerseyDesignation.formerWorldChampionRainbowBands,
      );

      // Rider D has won nothing -> standard trade team kit
      expect(
        service.getRiderJerseyDesignation(riderId: 'rider-d', nationalityIso: 'ESP'),
        SpecialJerseyDesignation.standardTeamJersey,
      );
    });

    test('getNationalJerseyColorTheme returns iconic national colors and descriptions', () {
      final poland = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme('POL');
      expect(poland['country'], 'Polska');
      expect(poland['description'], contains('orłem'));
      expect(poland['pattern'], 'nationalChampion');

      final france = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme('FRA');
      expect(france['description'], contains('Bleu-Blanc-Rouge'));

      final belgium = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme('BEL');
      expect(belgium['primaryHex'], '#4FA8E0'); // Belgian sky blue

      final slovenia = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme('SLO');
      expect(slovenia['description'], contains('Triglav'));

      final defaultTheme = NationalChampionshipsAndWorldsService.getNationalJerseyColorTheme('ZWE');
      expect(defaultTheme['country'], 'ZWE');
    });

    test('getJerseyDescription provides descriptive text for all designations', () {
      final service = NationalChampionshipsAndWorldsService();

      expect(
        service.getJerseyDescription(SpecialJerseyDesignation.rainbowJersey, 'FRA'),
        contains('Tęczowa Koszulka Mistrza Świata'),
      );
      expect(
        service.getJerseyDescription(SpecialJerseyDesignation.nationalChampionJersey, 'POL'),
        contains('Biało-czerwona z orłem'),
      );
      expect(
        service.getJerseyDescription(SpecialJerseyDesignation.formerWorldChampionRainbowBands, 'ITA'),
        contains('Tęczowe paski mistrza świata na mankietach'),
      );
      expect(
        service.getJerseyDescription(SpecialJerseyDesignation.standardTeamJersey, 'ESP'),
        contains('Standardowy strój drużynowy'),
      );
    });
  });
}
