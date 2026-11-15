import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/services/career/historical_records_and_palmares_service.dart';

void main() {
  group('HistoricalRecordsAndPalmaresService - 1. Baza słynnych podjazdów i rekordów KOM', () {
    test('Domyślna baza zawiera słynne podjazdy kolarskie z prawidłowymi danymi VAM', () {
      final service = HistoricalRecordsAndPalmaresService();
      final climbs = service.getClimbRecords();

      expect(climbs.length, greaterThanOrEqualTo(8));

      final alpe = service.getClimbRecordById('climb_alpe_dhuez');
      expect(alpe, isNotNull);
      expect(alpe!.climbName, contains('Alpe d\'Huez'));
      expect(alpe.elevationGainM, 1118.0);
      expect(alpe.averageGradientPct, 8.1);
      expect(alpe.recordHolderRiderName, 'Marco Pantani');
      expect(alpe.recordTimeSeconds, 2210); // 36:50
      expect(alpe.vamMetersPerHour, closeTo(1821.3, 1.0));
      expect(alpe.formattedRecordTime, '36:50');
      expect(alpe.formattedVam, contains('1821 VAM'));

      final ventoux = service.getClimbRecordById('climb_mont_ventoux');
      expect(ventoux, isNotNull);
      expect(ventoux!.elevationGainM, 1600.0);
      expect(ventoux.recordHolderRiderName, 'Iban Mayo');

      final beille = service.getClimbRecordById('climb_plateau_de_beille');
      expect(beille, isNotNull);
      expect(beille!.recordHolderRiderName, 'Tadej Pogačar');
      expect(beille.achievedInSeasonYear, 2024);

      final poggio = service.getClimbRecordById('climb_poggio');
      expect(poggio, isNotNull);
      expect(poggio!.recordHolderRiderName, 'Mathieu van der Poel');
    });

    test('recordClimbAttempt bije rekord KOM i aktualizuje dane podjazdu', () {
      final service = HistoricalRecordsAndPalmaresService();

      // Próba pobicia rekordu Alpe d'Huez przez młodego lidera (np. 35:40 = 2140 s)
      final result = service.recordClimbAttempt(
        climbId: 'climb_alpe_dhuez',
        riderId: 'rider_superstar_01',
        riderName: 'Jan Veloce',
        teamName: 'Veloce Pro Team',
        timeSeconds: 2140, // Lepszy niż 2210 Pantaniego o 70s!
        seasonYear: 2026,
        raceName: 'Tour de France 2026 - Etap 18',
        riderWeightKg: 64.0,
      );

      expect(result.isNewKomRecord, isTrue);
      expect(result.timeDeltaSeconds, 70);
      expect(result.previousRecordTimeSeconds, 2210);
      expect(result.currentVam, greaterThan(1880.0));
      expect(result.estimatedWattsPerKg, greaterThan(6.6));
      expect(result.celebrationMessage, contains('NOWY REKORD WSZECH CZASÓW'));

      final updatedAlpe = service.getClimbRecordById('climb_alpe_dhuez')!;
      expect(updatedAlpe.recordHolderRiderId, 'rider_superstar_01');
      expect(updatedAlpe.recordHolderRiderName, 'Jan Veloce');
      expect(updatedAlpe.recordTimeSeconds, 2140);
      expect(updatedAlpe.achievedInSeasonYear, 2026);
      expect(updatedAlpe.topAttempts.first.riderName, 'Jan Veloce');
      expect(updatedAlpe.topAttempts.first.timeSeconds, 2140);
    });

    test('recordClimbAttempt gorszy od rekordu nie zmienia posiadacza KOM', () {
      final service = HistoricalRecordsAndPalmaresService();

      // Czas 38:00 = 2280 s (gorszy od 2210 s)
      final result = service.recordClimbAttempt(
        climbId: 'climb_alpe_dhuez',
        riderId: 'rider_good_climber',
        riderName: 'Solid Climber',
        teamName: 'Continental Team',
        timeSeconds: 2280,
        seasonYear: 2026,
        raceName: 'Tour de France 2026 - Etap 18',
      );

      expect(result.isNewKomRecord, isFalse);
      expect(result.previousRecordTimeSeconds, 2210);
      expect(result.celebrationMessage, contains('tracąc 70 s do rekordu'));

      final alpe = service.getClimbRecordById('climb_alpe_dhuez')!;
      expect(alpe.recordHolderRiderName, 'Marco Pantani');
      expect(alpe.recordTimeSeconds, 2210);
      expect(alpe.topAttempts.any((a) => a.riderName == 'Solid Climber'), isTrue);
    });

    test('recordClimbAttempt rzuca ArgumentError przy nieznanym ID', () {
      final service = HistoricalRecordsAndPalmaresService();
      expect(
        () => service.recordClimbAttempt(
          climbId: 'climb_non_existent',
          riderId: 'r1',
          riderName: 'Rider',
          teamName: 'Team',
          timeSeconds: 2000,
          seasonYear: 2026,
          raceName: 'Test',
        ),
        throwsArgumentError,
      );
    });
  });

  group('HistoricalRecordsAndPalmaresService - 2. Rejestracja wyścigów i aktualizacja Palmarès', () {
    late TourRace mockTourDeFrance;
    late TourRace mockRondeVanVlaanderen;

    setUp(() {
      final stages = List.generate(
        21,
        (i) => RaceStage(
          id: 'tdf_st_${i + 1}',
          stageNumber: i + 1,
          name: 'Etap ${i + 1}',
          stageType: i % 5 == 0 ? StageType.individualTimeTrial : StageType.highMountain,
          segments: const [
            StageSegment(
              index: 0,
              startKm: 0.0,
              lengthKm: 160.0,
              startElevationM: 100.0,
              endElevationM: 1200.0,
              surfaceType: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 20.0,
              windDirectionDegrees: 90.0,
              roadBearingDegrees: 90.0,
              sprintOrKomClassification: SegmentClassification.horsCategorie,
            ),
          ],
          baseTemperatureCelsius: 24.0,
          weatherCondition: WeatherCondition.sunny,
          windSpeedKmh: 12.0,
        ),
      );

      mockTourDeFrance = TourRace(
        id: 'race_tour_de_france_2026',
        name: 'Tour de France (La Grande Boucle)',
        countryIso: 'FRA',
        uciCategory: RaceCategory.grandTour,
        startMonth: 7,
        startDay: 4,
        stages: stages,
        prizePoolEur: 2500000,
        participatingTeamIds: ['team_wt_01'],
        ridersPerTeam: 8,
        classifications: const RaceClassifications(
          generalClassification: [],
          pointsClassification: [],
          mountainsClassification: [],
          youthClassification: [],
          teamClassification: [],
        ),
      );

      mockRondeVanVlaanderen = const TourRace(
        id: 'race_flanders_monument_2026',
        name: 'Ronde van Vlaanderen Monument',
        countryIso: 'BEL',
        uciCategory: RaceCategory.monument,
        startMonth: 4,
        startDay: 5,
        stages: [
          RaceStage(
            id: 'rvv_st_1',
            stageNumber: 1,
            name: 'Brugge - Oudenaarde',
            stageType: StageType.cobbleClassic,
            segments: [
              StageSegment(
                index: 0,
                startKm: 0.0,
                lengthKm: 270.0,
                startElevationM: 10.0,
                endElevationM: 50.0,
                surfaceType: SegmentSurfaceType.cobblestonesSector4,
                technicalDifficulty: 85.0,
                windDirectionDegrees: 180.0,
                roadBearingDegrees: 180.0,
                sprintOrKomClassification: SegmentClassification.finishLine,
              ),
            ],
            baseTemperatureCelsius: 12.0,
            weatherCondition: WeatherCondition.lightRain,
            windSpeedKmh: 28.0,
          ),
        ],
        prizePoolEur: 150000,
        participatingTeamIds: ['team_wt_01'],
        ridersPerTeam: 7,
        classifications: RaceClassifications(
          generalClassification: [],
          pointsClassification: [],
          mountainsClassification: [],
          youthClassification: [],
          teamClassification: [],
        ),
      );
    });

    test('registerRaceCompletion dla Tour de France aktualizuje archiwum, etapy i koszulki', () {
      final service = HistoricalRecordsAndPalmaresService();

      service.registerRaceCompletion(
        race: mockTourDeFrance,
        seasonYear: 2026,
        winningRiderId: 'pogacar_legend',
        winningRiderName: 'Tadej Pogačar',
        winningTeamId: 'team_uae',
        winningTeamName: 'UAE Team Emirates',
        winningMarginSeconds: 374, // 6m 14s
        podiumRiderNames: ['Tadej Pogačar', 'Jonas Vingegaard', 'Remco Evenepoel'],
        stageWinners: {
          4: (riderId: 'pogacar_legend', riderName: 'Tadej Pogačar', teamId: 'team_uae', teamName: 'UAE Team Emirates'),
          14: (riderId: 'pogacar_legend', riderName: 'Tadej Pogačar', teamId: 'team_uae', teamName: 'UAE Team Emirates'),
          19: (riderId: 'pogacar_legend', riderName: 'Tadej Pogačar', teamId: 'team_uae', teamName: 'UAE Team Emirates'),
          5: (riderId: 'rider_remco', riderName: 'Remco Evenepoel', teamId: 'team_soudal', teamName: 'Soudal Quick-Step'),
          11: (riderId: 'rider_jonas', riderName: 'Jonas Vingegaard', teamId: 'team_visma', teamName: 'Visma Lease a Bike'),
        },
        jerseyWinners: {
          'Maillot Jaune': (riderId: 'pogacar_legend', riderName: 'Tadej Pogačar'),
          'Maillot Vert': (riderId: 'rider_bini', riderName: 'Biniam Girmay'),
          'Maillot à Pois': (riderId: 'rider_carapaz', riderName: 'Richard Carapaz'),
          'Biała': (riderId: 'rider_remco', riderName: 'Remco Evenepoel'),
        },
        daysInLeaderJersey: {
          'pogacar_legend': 18,
          'rider_carapaz': 1,
        },
        notes: 'Historyczny dublet Giro-Tour w jednym sezonie!',
      );

      // Sprawdzenie archiwum wyścigów 2026
      final archives = service.getSeasonWinners(2026);
      expect(archives.length, 1);
      final tdfArchive = archives.first;
      expect(tdfArchive.winnerRiderName, 'Tadej Pogačar');
      expect(tdfArchive.winningMarginSeconds, 374);
      expect(tdfArchive.podiumRiderNames, contains('Jonas Vingegaard'));
      expect(tdfArchive.stageWinners[4], 'Tadej Pogačar');
      expect(tdfArchive.stageWinners[5], 'Remco Evenepoel');

      // Sprawdzenie Palmarès Pogačara
      final pogiPalmares = service.getRiderPalmares('pogacar_legend');
      expect(pogiPalmares, isNotNull);
      // Pogačar w bazie domyślnej miał 3x TdF, po dopisaniu ma 4x TdF
      expect(pogiPalmares!.tourDeFranceGcWins, 4);
      expect(pogiPalmares.grandTourOverallWins, 5); // 4 TdF + 1 Giro
      expect(pogiPalmares.daysInYellowJersey, 35 + 18);
      // Zwycięstwa etapowe (miał 17 w TdF + 3 nowe = 20)
      expect(pogiPalmares.tourDeFranceStageWins, 20);
      expect(pogiPalmares.entries.any((e) => e.achievementType == PalmaresAchievementType.grandTourGeneralClassification), isTrue);

      // Sprawdzenie Palmarès Remco Evenepoela
      final remcoPalmares = service.getRiderPalmares('rider_remco');
      expect(remcoPalmares, isNotNull);
      expect(remcoPalmares!.tourDeFranceStageWins, 1);
      expect(remcoPalmares.youthClassificationsWon, 1);

      // Sprawdzenie Biniama Girmaya (klasyfikacja punktowa)
      final biniPalmares = service.getRiderPalmares('rider_bini');
      expect(biniPalmares, isNotNull);
      expect(biniPalmares!.pointsClassificationsWon, 1);
    });

    test('registerRaceCompletion dla Ronde van Vlaanderen przypisuje triumf w Monumencie', () {
      final service = HistoricalRecordsAndPalmaresService();

      service.registerRaceCompletion(
        race: mockRondeVanVlaanderen,
        seasonYear: 2026,
        winningRiderId: 'rider_mvdp',
        winningRiderName: 'Mathieu van der Poel',
        winningTeamId: 'team_alpecin',
        winningTeamName: 'Alpecin-Deceuninck',
        winningMarginSeconds: 62,
        podiumRiderNames: ['Mathieu van der Poel', 'Luca Mozzato', 'Nils Politt'],
      );

      final mvdp = service.getRiderPalmares('rider_mvdp');
      expect(mvdp, isNotNull);
      expect(mvdp!.monumentWins, 1);
      expect(mvdp.rondeVanVlaanderenWins, 1);
      expect(mvdp.entries.first.achievementType, PalmaresAchievementType.monumentClassic);
    });
  });

  group('HistoricalRecordsAndPalmaresService - 3. Ranking Wszech Czasów i Statystyki Trofeów', () {
    test('getAllTimeHallOfFame zawiera legendy i Eddy Merckx jest liderem wszech czasów', () {
      final service = HistoricalRecordsAndPalmaresService();
      final ranking = service.getAllTimeHallOfFame();

      expect(ranking.length, greaterThanOrEqualTo(5));

      final no1 = ranking.first;
      expect(no1.rank, 1);
      expect(no1.riderName, 'Eddy Merckx');
      expect(no1.grandTourGcWins, 11);
      expect(no1.monumentWins, 19);
      expect(no1.allTimePoints, greaterThan(15000));
      expect(no1.trophySummary, contains('5x TdF'));

      // Bernard Hinault i Tadej Pogačar w czołówce
      expect(ranking.any((r) => r.riderName == 'Bernard Hinault'), isTrue);
      expect(ranking.any((r) => r.riderName == 'Tadej Pogačar'), isTrue);
    });

    test('getGrandTourStageTrifectaClub zwraca kolarzy z wygranymi etapami w 3 GT', () {
      final service = HistoricalRecordsAndPalmaresService();
      final trifectaClub = service.getGrandTourStageTrifectaClub();

      // Merckx, Hinault, Pogačar, Cavendish wygrali etapy we wszystkich trzech GT
      expect(trifectaClub.length, greaterThanOrEqualTo(4));
      expect(trifectaClub.any((r) => r.riderName == 'Mark Cavendish'), isTrue);
      expect(trifectaClub.any((r) => r.riderName == 'Eddy Merckx'), isTrue);
      expect(trifectaClub.any((r) => r.riderName == 'Tadej Pogačar'), isTrue);
    });

    test('getMonumentKings zwraca kolarzy z największą liczbą Monumentów', () {
      final service = HistoricalRecordsAndPalmaresService();
      final kings = service.getMonumentKings();

      expect(kings.first.riderName, 'Eddy Merckx');
      expect(kings.first.monumentWins, 19);
      expect(kings.any((r) => r.riderName == 'Tadej Pogačar' && r.monumentWins == 7), isTrue);
    });
  });

  group('HistoricalRecordsAndPalmaresService - 4. Serializacja i deserializacja JSON', () {
    test('Cały serwis archiwum serializuje i deserializuje się bezstratnie', () {
      final service = HistoricalRecordsAndPalmaresService();

      // Dodajemy próbę na Alpe d'Huez
      service.recordClimbAttempt(
        climbId: 'climb_alpe_dhuez',
        riderId: 'rider_hero',
        riderName: 'Hero Climber',
        teamName: 'Hero Team',
        timeSeconds: 2190,
        seasonYear: 2026,
        raceName: 'Tour de France 2026',
      );

      final json = service.toJson();
      final restored = HistoricalRecordsAndPalmaresService.fromJson(json);

      expect(restored.getClimbRecords().length, service.getClimbRecords().length);
      final alpe = restored.getClimbRecordById('climb_alpe_dhuez');
      expect(alpe?.recordHolderRiderName, 'Hero Climber');
      expect(alpe?.recordTimeSeconds, 2190);

      final ranking = restored.getAllTimeHallOfFame();
      expect(ranking.first.riderName, 'Eddy Merckx');
    });
  });
}
