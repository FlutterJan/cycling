import 'dart:math' as math;
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/race/tour_race.dart';

/// Zaawansowany generator pełnego, oficjalnego kalendarza sezonu kolarskiego (od stycznia do października).
///
/// Zawiera:
/// - Styczeń/Luty: wyścigi w Australii (Southern Tour), Hiszpanii (Mallorca, Valencia) oraz ZEA (Desert Emirates),
/// - Marzec/Kwiecień: Wiosenne Klasyki i 4 pierwsze Monumenty kolarstwa (Primavera, Flandria, Piekło Północy / Roubaix, Ardeny),
/// - Maj: Grand Tour 1 – Corsa Rosa d'Italia (21 pełnych etapów z przełęczami alpejskimi i czasówkami),
/// - Czerwiec: Próby generalne przed Tourem (Critérium des Alpes, Tour de Suisse) oraz Mistrzostwa Krajowe,
/// - Lipiec: Grand Tour 2 – La Grande Boucle de France (21 pełnych etapów: Alpy, Pireneje, wiatry i Pola Elizejskie),
/// - Sierpień/Wrzesień: Klasyki letnie, Tour de Pologne (7 etapów), Grand Tour 3 – La Vuelta Ibérica (21 etapów),
///   wyścigi w Kanadzie i Mistrzostwa Świata,
/// - Październik: Monument 5 – Il Lombardia (Wyścig Spadających Liści).
class UciCalendarGenerator {
  UciCalendarGenerator._();

  /// Główna metoda generująca kompletny kalendarz sezonu wyścigowego.
  static List<TourRace> generateFullSeasonCalendar({
    int seasonYear = 2026,
    List<String>? participatingTeamIds,
  }) {
    final teamIds = participatingTeamIds ?? const [];

    return [
      // =======================================================================
      // STYCZEŃ / LUTY: POCZĄTEK SEZONU (AUSTRALIA, HISZPANIA, ZEA)
      // =======================================================================
      _buildSouthernTour(seasonYear, teamIds),
      _buildMallorcaClassic(seasonYear, teamIds),
      _buildValenciaTour(seasonYear, teamIds),
      _buildDesertEmiratesTour(seasonYear, teamIds),

      // =======================================================================
      // MARZEC: WIOSENNE KLASYKI, PARYŻ-NICEA, TIRRENO & PRIMAVERA (MONUMENT 1)
      // =======================================================================
      _buildStradeToscana(seasonYear, teamIds),
      _buildRaceToTheSun(seasonYear, teamIds),
      _buildRaceOfTwoSeas(seasonYear, teamIds),
      _buildPrimaveraClassic(seasonYear, teamIds), // Monument 1 (Mediolan-San Remo)
      _buildCatalunyaTour(seasonYear, teamIds),
      _buildE3FlemishClassic(seasonYear, teamIds),
      _buildGentWevelgemClassic(seasonYear, teamIds),
      _buildRondeVanVlaanderen(seasonYear, teamIds), // Monument 2 (Flandria)

      // =======================================================================
      // KWIECIEŃ: KRAINA BRUKU & ARDENY
      // =======================================================================
      _buildBasqueCountryTour(seasonYear, teamIds),
      _buildHellOfTheNorthRoubaix(seasonYear, teamIds), // Monument 3 (Paryż-Roubaix)
      _buildAmstelHillClassic(seasonYear, teamIds),
      _buildFlecheWallonne(seasonYear, teamIds),
      _buildLiegeBastogneLiege(seasonYear, teamIds), // Monument 4 (La Doyenne)
      _buildTourDeRomandie(seasonYear, teamIds),

      // =======================================================================
      // MAJ: GIRO (CORSA ROSA D'ITALIA) – 21 ETAPÓW
      // =======================================================================
      _buildCorsaRosaGiro(seasonYear, teamIds),

      // =======================================================================
      // CZERWIEC: DELFINAT, SZWAJCARIA & MISTRZOSTWA KRAJOWE
      // =======================================================================
      _buildCriteriumDesAlpes(seasonYear, teamIds),
      _buildTourDeSuisse(seasonYear, teamIds),
      _buildNationalChampionships(seasonYear, teamIds),

      // =======================================================================
      // LIPIEC: TOUR (LA GRANDE BOUCLE DE FRANCE) – 21 ETAPÓW
      // =======================================================================
      _buildLaGrandeBoucleTour(seasonYear, teamIds),

      // =======================================================================
      // SIERPIEŃ: SAN SEBASTIÁN, TOUR DE POLOGNE & VUELTA – 21 ETAPÓW
      // =======================================================================
      _buildClasicaSanSebastian(seasonYear, teamIds),
      _buildTourDePologne(seasonYear, teamIds),
      _buildLaVueltaIberica(seasonYear, teamIds),
      _buildBretagneClassic(seasonYear, teamIds),
      _buildBeneluxWindTour(seasonYear, teamIds),

      // =======================================================================
      // WRZESIEŃ: GP KANADY & MISTRZOSTWA ŚWIATA
      // =======================================================================
      _buildGrandPrixQuebec(seasonYear, teamIds),
      _buildGrandPrixMontreal(seasonYear, teamIds),
      _buildWorldIttChampionship(seasonYear, teamIds),
      _buildWorldRoadRaceChampionship(seasonYear, teamIds),

      // =======================================================================
      // PAŹDZIERNIK: MONUMENT 5 (IL LOMBARDIA – SPADAJĄCE LIŚCIE)
      // =======================================================================
      _buildIlLombardiaClassic(seasonYear, teamIds),
    ];
  }

  /// Pobiera wyścig po unikalnym identyfikatorze
  static TourRace? getRaceById(String id, {int seasonYear = 2026}) {
    final calendar = generateFullSeasonCalendar(seasonYear: seasonYear);
    for (final r in calendar) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Filtruje wyścigi odbywające się w zadanym miesiącu (1-12)
  static List<TourRace> getRacesForMonth(int month, {int seasonYear = 2026}) {
    return generateFullSeasonCalendar(seasonYear: seasonYear)
        .where((r) => r.startMonth == month)
        .toList();
  }

  /// Wszystkie 3 Grand Toury (Giro, Tour de France, Vuelta)
  static List<TourRace> getGrandTours({int seasonYear = 2026}) {
    return generateFullSeasonCalendar(seasonYear: seasonYear)
        .where((r) => r.isGrandTour)
        .toList();
  }

  /// Wszystkie 5 Monumentów kolarstwa
  static List<TourRace> getMonuments({int seasonYear = 2026}) {
    return generateFullSeasonCalendar(seasonYear: seasonYear)
        .where((r) => r.uciCategory == RaceCategory.monument)
        .toList();
  }

  // ===========================================================================
  // BUDOWNICZOWIE ETAPÓW (SEGMENTY I PROFIL WYSOKOŚCIOWY)
  // ===========================================================================

  static RaceStage _createFlatStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
    double startElevation = 30.0,
    double windSpeedKmh = 18.0,
    WeatherCondition weather = WeatherCondition.sunny,
    double roadBearingDegrees = 90.0,
  }) {
    final int segmentCount = math.max(4, (distanceKm / 35.0).round());
    final double segLen = distanceKm / segmentCount;
    final List<StageSegment> segments = [];

    double currentElev = startElevation;
    for (int i = 0; i < segmentCount; i++) {
      final double startK = i * segLen;
      // Lekkie falowanie terenu na płaskim etapie (±20m)
      final double endElev = math.max(10.0, currentElev + (i % 2 == 0 ? 18.0 : -14.0));

      SegmentClassification classification = SegmentClassification.none;
      if (i == (segmentCount ~/ 2)) {
        classification = SegmentClassification.intermediateSprint;
      } else if (i == segmentCount - 1) {
        classification = SegmentClassification.finishLine;
      }

      segments.add(
        StageSegment(
          index: i,
          startKm: double.parse(startK.toStringAsFixed(1)),
          lengthKm: double.parse(segLen.toStringAsFixed(1)),
          startElevationM: double.parse(currentElev.toStringAsFixed(1)),
          endElevationM: double.parse(endElev.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: i == segmentCount - 1 ? 55.0 : 25.0, // Wyższa nerwowość na finiszu
          windDirectionDegrees: 270.0,
          roadBearingDegrees: roadBearingDegrees,
          sprintOrKomClassification: classification,
        ),
      );
      currentElev = endElev;
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: StageType.flat,
      segments: segments,
      baseTemperatureCelsius: 22.0,
      weatherCondition: weather,
      windSpeedKmh: windSpeedKmh,
    );
  }

  static RaceStage _createHillyStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
    double startElevation = 100.0,
    double windSpeedKmh = 20.0,
    WeatherCondition weather = WeatherCondition.sunny,
  }) {
    final int segmentCount = math.max(6, (distanceKm / 28.0).round());
    final double segLen = distanceKm / segmentCount;
    final List<StageSegment> segments = [];

    double currentElev = startElevation;
    for (int i = 0; i < segmentCount; i++) {
      final double startK = i * segLen;
      // Wyraźne podjazdy pagórkowate (np. 150m - 400m przewyższenia)
      final bool isClimbSegment = i % 2 == 1;
      final double endElev = isClimbSegment
          ? currentElev + 220.0 + (i * 15.0)
          : math.max(80.0, currentElev - 180.0);

      SegmentClassification classification = SegmentClassification.none;
      if (isClimbSegment) {
        classification = i > 4 ? SegmentClassification.cat2 : SegmentClassification.cat3;
      } else if (i == 2) {
        classification = SegmentClassification.intermediateSprint;
      } else if (i == segmentCount - 1) {
        classification = SegmentClassification.finishLine;
      }

      segments.add(
        StageSegment(
          index: i,
          startKm: double.parse(startK.toStringAsFixed(1)),
          lengthKm: double.parse(segLen.toStringAsFixed(1)),
          startElevationM: double.parse(currentElev.toStringAsFixed(1)),
          endElevationM: double.parse(endElev.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: isClimbSegment ? 40.0 : 60.0, // Zjazdy techniczne
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 45.0,
          sprintOrKomClassification: classification,
        ),
      );
      currentElev = endElev;
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: StageType.hilly,
      segments: segments,
      baseTemperatureCelsius: 20.0,
      weatherCondition: weather,
      windSpeedKmh: windSpeedKmh,
    );
  }

  static RaceStage _createMountainStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
    required bool isSummitFinish,
    double valleyElevation = 450.0,
    double summitElevation = 2150.0,
    WeatherCondition weather = WeatherCondition.sunny,
  }) {
    final int segmentCount = math.max(6, (distanceKm / 24.0).round());
    final double segLen = distanceKm / segmentCount;
    final List<StageSegment> segments = [];

    double currentElev = valleyElevation;
    for (int i = 0; i < segmentCount; i++) {
      final double startK = i * segLen;
      double endElev;
      SegmentClassification classification = SegmentClassification.none;

      if (i == segmentCount - 1 && isSummitFinish) {
        // Finałowa wspinaczka poza kategorią (HC)
        endElev = summitElevation;
        classification = SegmentClassification.horsCategorie;
      } else if (i % 2 == 1) {
        // Przełęcz górska Cat 1
        endElev = currentElev + (summitElevation - valleyElevation) * 0.75;
        classification = SegmentClassification.cat1;
      } else {
        // Zjazd w dolinę
        endElev = valleyElevation + 50.0;
        if (i == 2) classification = SegmentClassification.intermediateSprint;
      }

      segments.add(
        StageSegment(
          index: i,
          startKm: double.parse(startK.toStringAsFixed(1)),
          lengthKm: double.parse(segLen.toStringAsFixed(1)),
          startElevationM: double.parse(currentElev.toStringAsFixed(1)),
          endElevationM: double.parse(endElev.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: i % 2 == 0 ? 70.0 : 45.0, // Zjazdy z przełęczy są bardzo techniczne
          windDirectionDegrees: 315.0,
          roadBearingDegrees: 120.0,
          sprintOrKomClassification: classification,
        ),
      );
      currentElev = endElev;
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: isSummitFinish ? StageType.summitFinish : StageType.highMountain,
      segments: segments,
      baseTemperatureCelsius: 16.0, // Chłodniej w wysokich górach
      weatherCondition: weather,
      windSpeedKmh: 24.0,
    );
  }

  static RaceStage _createTimeTrialStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
    double startElevation = 50.0,
  }) {
    const int segmentCount = 4;
    final double segLen = distanceKm / segmentCount;
    final List<StageSegment> segments = [];

    double currentElev = startElevation;
    for (int i = 0; i < segmentCount; i++) {
      final double startK = i * segLen;
      final double endElev = currentElev + (i == 1 ? 40.0 : -10.0);

      segments.add(
        StageSegment(
          index: i,
          startKm: double.parse(startK.toStringAsFixed(1)),
          lengthKm: double.parse(segLen.toStringAsFixed(1)),
          startElevationM: double.parse(currentElev.toStringAsFixed(1)),
          endElevationM: double.parse(endElev.toStringAsFixed(1)),
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 45.0,
          windDirectionDegrees: 90.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: i == segmentCount - 1
              ? SegmentClassification.finishLine
              : SegmentClassification.none,
        ),
      );
      currentElev = endElev;
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: StageType.individualTimeTrial,
      segments: segments,
      baseTemperatureCelsius: 21.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 15.0,
    );
  }

  static RaceStage _createCobbleStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
  }) {
    const int segmentCount = 8;
    final double segLen = distanceKm / segmentCount;
    final List<StageSegment> segments = [];

    for (int i = 0; i < segmentCount; i++) {
      final double startK = i * segLen;
      // Sektory bruku na co drugim segmencie (w tym sektory 3, 4 i 5 gwiazdek)
      SegmentSurfaceType surface = SegmentSurfaceType.smoothAsphalt;
      if (i == 3) surface = SegmentSurfaceType.cobblestonesSector3;
      if (i == 5) surface = SegmentSurfaceType.cobblestonesSector5; // Trouée d'Arenberg style
      if (i == 7) surface = SegmentSurfaceType.cobblestonesSector4; // Carrefour de l'Arbre style

      segments.add(
        StageSegment(
          index: i,
          startKm: double.parse(startK.toStringAsFixed(1)),
          lengthKm: double.parse(segLen.toStringAsFixed(1)),
          startElevationM: 40.0,
          endElevationM: 45.0,
          surfaceType: surface,
          technicalDifficulty: surface != SegmentSurfaceType.smoothAsphalt ? 85.0 : 35.0,
          windDirectionDegrees: 330.0,
          roadBearingDegrees: 40.0,
          sprintOrKomClassification: i == segmentCount - 1
              ? SegmentClassification.finishLine
              : SegmentClassification.none,
        ),
      );
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: StageType.cobbleClassic,
      segments: segments,
      baseTemperatureCelsius: 14.0,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 28.0,
    );
  }

  static RaceStage _createStradeGravelStage({
    required String id,
    required int stageNumber,
    required String name,
    required double distanceKm,
  }) {
    const int segmentCount = 7;
    final double segLen = distanceKm / segmentCount;
    final List<StageSegment> segments = [];

    double currentElev = 200.0;
    for (int i = 0; i < segmentCount; i++) {
      final double startK = i * segLen;
      final bool isGravel = i % 2 == 1;
      final double endElev = currentElev + (isGravel ? 120.0 : -80.0);

      segments.add(
        StageSegment(
          index: i,
          startKm: double.parse(startK.toStringAsFixed(1)),
          lengthKm: double.parse(segLen.toStringAsFixed(1)),
          startElevationM: double.parse(currentElev.toStringAsFixed(1)),
          endElevationM: double.parse(endElev.toStringAsFixed(1)),
          surfaceType: isGravel ? SegmentSurfaceType.gravelStrade : SegmentSurfaceType.roughAsphalt,
          technicalDifficulty: isGravel ? 75.0 : 40.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: i == segmentCount - 1
              ? SegmentClassification.finishLine
              : SegmentClassification.none,
        ),
      );
      currentElev = endElev;
    }

    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: StageType.hilly,
      segments: segments,
      baseTemperatureCelsius: 18.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 20.0,
    );
  }

  // ===========================================================================
  // KALENDARZ WYŚCIGÓW (OD STYCZNIA DO PAŹDZIERNIKA)
  // ===========================================================================

  static TourRace _buildSouthernTour(int year, List<String> teams) {
    return TourRace(
      id: 'race_southern_tour_$year',
      name: 'Southern Tour of Australia',
      countryIso: 'AUS',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 1,
      startDay: 16,
      prizePoolEur: 420000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createFlatStage(id: 'st_st_1', stageNumber: 1, name: 'Adelaide Coastal Loop', distanceKm: 145.0),
        _createFlatStage(id: 'st_st_2', stageNumber: 2, name: 'Barossa Wine Sprint', distanceKm: 152.0),
        _createHillyStage(id: 'st_st_3', stageNumber: 3, name: 'Adelaide Hills Punch', distanceKm: 148.0),
        _createFlatStage(id: 'st_st_4', stageNumber: 4, name: 'Victor Harbor Crosswinds', distanceKm: 160.0),
        _createMountainStage(id: 'st_st_5', stageNumber: 5, name: 'Willunga Hill Summit', distanceKm: 155.0, isSummitFinish: true, summitElevation: 380.0),
        _createFlatStage(id: 'st_st_6', stageNumber: 6, name: 'Adelaide City Criterium', distanceKm: 112.0),
      ],
    );
  }

  static TourRace _buildMallorcaClassic(int year, List<String> teams) {
    return TourRace(
      id: 'race_mallorca_$year',
      name: 'Challenge Mallorca Trophy',
      countryIso: 'ESP',
      uciCategory: RaceCategory.class1,
      startMonth: 1,
      startDay: 28,
      prizePoolEur: 95000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_mal_1', stageNumber: 1, name: 'Trofeo Serra de Tramuntana', distanceKm: 168.0),
      ],
    );
  }

  static TourRace _buildValenciaTour(int year, List<String> teams) {
    return TourRace(
      id: 'race_valencia_$year',
      name: 'Volta a la Comunitat Valenciana',
      countryIso: 'ESP',
      uciCategory: RaceCategory.proSeries,
      startMonth: 2,
      startDay: 2,
      prizePoolEur: 180000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createTimeTrialStage(id: 'st_val_1', stageNumber: 1, name: 'Valencia Coastal ITT', distanceKm: 18.5),
        _createFlatStage(id: 'st_val_2', stageNumber: 2, name: 'Castellón Fast Sprint', distanceKm: 166.0),
        _createHillyStage(id: 'st_val_3', stageNumber: 3, name: 'Alicante Puncheur Climb', distanceKm: 162.0),
        _createMountainStage(id: 'st_val_4', stageNumber: 4, name: 'Alto del Miserat Queen Stage', distanceKm: 175.0, isSummitFinish: true, summitElevation: 980.0),
        _createFlatStage(id: 'st_val_5', stageNumber: 5, name: 'Valencia Paseo Promenade', distanceKm: 98.0),
      ],
    );
  }

  static TourRace _buildDesertEmiratesTour(int year, List<String> teams) {
    return TourRace(
      id: 'race_emirates_$year',
      name: 'Desert Emirates Tour',
      countryIso: 'UAE',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 2,
      startDay: 19,
      prizePoolEur: 480000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createFlatStage(id: 'st_uae_1', stageNumber: 1, name: 'Al Dhafra Echelon Sands', distanceKm: 143.0, windSpeedKmh: 35.0, weather: WeatherCondition.crosswindGale),
        _createTimeTrialStage(id: 'st_uae_2', stageNumber: 2, name: 'Al Hudayriyat Island ITT', distanceKm: 12.1),
        _createMountainStage(id: 'st_uae_3', stageNumber: 3, name: 'Jebel Jais Mountain Highway', distanceKm: 176.0, isSummitFinish: true, summitElevation: 1490.0),
        _createFlatStage(id: 'st_uae_4', stageNumber: 4, name: 'Dubai Harbour Sprint', distanceKm: 173.0),
        _createFlatStage(id: 'st_uae_5', stageNumber: 5, name: 'Al Aqah Oasis Flat', distanceKm: 182.0),
        _createFlatStage(id: 'st_uae_6', stageNumber: 6, name: 'Abu Dhabi Corniche Finale', distanceKm: 166.0),
        _createMountainStage(id: 'st_uae_7', stageNumber: 7, name: 'Jebel Hafeet Mountain Crown', distanceKm: 161.0, isSummitFinish: true, summitElevation: 1025.0),
      ],
    );
  }

  static TourRace _buildStradeToscana(int year, List<String> teams) {
    return TourRace(
      id: 'race_strade_$year',
      name: 'Strade di Toscana White Gravel',
      countryIso: 'ITA',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 3,
      startDay: 2,
      prizePoolEur: 175000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createStradeGravelStage(id: 'st_strade_1', stageNumber: 1, name: 'Siena Piazza del Campo', distanceKm: 215.0),
      ],
    );
  }

  static TourRace _buildRaceToTheSun(int year, List<String> teams) {
    return TourRace(
      id: 'race_paris_nice_$year',
      name: 'Race to the Sun Classic',
      countryIso: 'FRA',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 3,
      startDay: 3,
      prizePoolEur: 490000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createFlatStage(id: 'st_pn_1', stageNumber: 1, name: 'Yvelines Crosswinds', distanceKm: 158.0),
        _createFlatStage(id: 'st_pn_2', stageNumber: 2, name: 'Fontainebleau Fast Track', distanceKm: 179.0),
        _createTimeTrialStage(id: 'st_pn_3', stageNumber: 3, name: 'Auxerre Rolling ITT', distanceKm: 26.9),
        _createHillyStage(id: 'st_pn_4', stageNumber: 4, name: 'Mont Brouilly Wall', distanceKm: 183.0),
        _createFlatStage(id: 'st_pn_5', stageNumber: 5, name: 'Sisteron Gorges Sprint', distanceKm: 193.0),
        _createHillyStage(id: 'st_pn_6', stageNumber: 6, name: 'La Colle-sur-Loup Traps', distanceKm: 198.0),
        _createMountainStage(id: 'st_pn_7', stageNumber: 7, name: 'Col de la Couillole Summit', distanceKm: 173.0, isSummitFinish: true, summitElevation: 1678.0),
        _createHillyStage(id: 'st_pn_8', stageNumber: 8, name: 'Promenade des Anglais Col d\'Eze', distanceKm: 109.0),
      ],
    );
  }

  static TourRace _buildRaceOfTwoSeas(int year, List<String> teams) {
    return TourRace(
      id: 'race_tirreno_$year',
      name: 'Race of the Two Seas',
      countryIso: 'ITA',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 3,
      startDay: 4,
      prizePoolEur: 470000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createTimeTrialStage(id: 'st_tir_1', stageNumber: 1, name: 'Lido di Camaiore ITT', distanceKm: 11.5),
        _createFlatStage(id: 'st_tir_2', stageNumber: 2, name: 'Follonica Coastal Sprint', distanceKm: 198.0),
        _createHillyStage(id: 'st_tir_3', stageNumber: 3, name: 'Gualdo Tadino Muri', distanceKm: 225.0),
        _createHillyStage(id: 'st_tir_4', stageNumber: 4, name: 'Giulianova Adriatic Punch', distanceKm: 207.0),
        _createMountainStage(id: 'st_tir_5', stageNumber: 5, name: 'Sassotetto Queen Stage', distanceKm: 168.0, isSummitFinish: true, summitElevation: 1455.0),
        _createHillyStage(id: 'st_tir_6', stageNumber: 6, name: 'Cagli Muro Sprint', distanceKm: 180.0),
        _createFlatStage(id: 'st_tir_7', stageNumber: 7, name: 'San Benedetto del Tronto Pier', distanceKm: 154.0),
      ],
    );
  }

  static TourRace _buildPrimaveraClassic(int year, List<String> teams) {
    return TourRace(
      id: 'race_primavera_monument_$year',
      name: 'La Classicissima di Primavera',
      countryIso: 'ITA',
      uciCategory: RaceCategory.monument,
      startMonth: 3,
      startDay: 16,
      prizePoolEur: 220000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(
          id: 'st_prim_1',
          stageNumber: 1,
          name: 'Milano-Sanremo via Cipressa & Poggio',
          distanceKm: 298.0, // Najdłuższy klasyk w kalendarzu
        ),
      ],
    );
  }

  static TourRace _buildCatalunyaTour(int year, List<String> teams) {
    return TourRace(
      id: 'race_catalunya_$year',
      name: 'Volta Ciclista a Catalunya',
      countryIso: 'ESP',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 3,
      startDay: 18,
      prizePoolEur: 410000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_cat_1', stageNumber: 1, name: 'Sant Feliu Coastal', distanceKm: 173.0),
        _createMountainStage(id: 'st_cat_2', stageNumber: 2, name: 'Vallter 2000 Pyrenees', distanceKm: 186.0, isSummitFinish: true, summitElevation: 2150.0),
        _createMountainStage(id: 'st_cat_3', stageNumber: 3, name: 'Port Ainé High Altitude', distanceKm: 176.0, isSummitFinish: true, summitElevation: 1960.0),
        _createFlatStage(id: 'st_cat_4', stageNumber: 4, name: 'Lleida Fast Sprint', distanceKm: 169.0),
        _createHillyStage(id: 'st_cat_5', stageNumber: 5, name: 'Viladecans Puncheur', distanceKm: 167.0),
        _createMountainStage(id: 'st_cat_6', stageNumber: 6, name: 'Queralt Sanctuary', distanceKm: 154.0, isSummitFinish: true, summitElevation: 1200.0),
        _createHillyStage(id: 'st_cat_7', stageNumber: 7, name: 'Barcelona Montjuïc Circuit', distanceKm: 145.0),
      ],
    );
  }

  static TourRace _buildE3FlemishClassic(int year, List<String> teams) {
    return TourRace(
      id: 'race_e3_flemish_$year',
      name: 'E3 Flemish Classic Harelbeke',
      countryIso: 'BEL',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 3,
      startDay: 22,
      prizePoolEur: 160000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createCobbleStage(id: 'st_e3_1', stageNumber: 1, name: 'Paterberg & Oude Kwaremont Loop', distanceKm: 207.0),
      ],
    );
  }

  static TourRace _buildGentWevelgemClassic(int year, List<String> teams) {
    return TourRace(
      id: 'race_gent_wevelgem_$year',
      name: 'Gent-Wevelgem in Flanders Fields',
      countryIso: 'BEL',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 3,
      startDay: 24,
      prizePoolEur: 165000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_gw_1', stageNumber: 1, name: 'Kemmelberg Steep Cobbles', distanceKm: 253.0),
      ],
    );
  }

  static TourRace _buildRondeVanVlaanderen(int year, List<String> teams) {
    return TourRace(
      id: 'race_flanders_monument_$year',
      name: 'Ronde van Vlaanderen Monument',
      countryIso: 'BEL',
      uciCategory: RaceCategory.monument,
      startMonth: 3,
      startDay: 31,
      prizePoolEur: 230000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createCobbleStage(
          id: 'st_rvv_1',
          stageNumber: 1,
          name: 'Koppenberg, Taaienberg & Oude Kwaremont',
          distanceKm: 270.0,
        ),
      ],
    );
  }

  static TourRace _buildBasqueCountryTour(int year, List<String> teams) {
    return TourRace(
      id: 'race_itzulia_$year',
      name: 'Itzulia Basque Country Tour',
      countryIso: 'ESP',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 4,
      startDay: 1,
      prizePoolEur: 380000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createTimeTrialStage(id: 'st_itz_1', stageNumber: 1, name: 'Irun Steep Ramp ITT', distanceKm: 10.0),
        _createHillyStage(id: 'st_itz_2', stageNumber: 2, name: 'Kanbo Basque Hills', distanceKm: 160.0),
        _createHillyStage(id: 'st_itz_3', stageNumber: 3, name: 'Altsasu Wall Climbing', distanceKm: 190.0),
        _createHillyStage(id: 'st_itz_4', stageNumber: 4, name: 'Legutio Technical Circuit', distanceKm: 159.0),
        _createMountainStage(id: 'st_itz_5', stageNumber: 5, name: 'Amorebieta Queen Stage', distanceKm: 175.0, isSummitFinish: false),
        _createHillyStage(id: 'st_itz_6', stageNumber: 6, name: 'Eibar Arrate Walls Finale', distanceKm: 137.0),
      ],
    );
  }

  static TourRace _buildHellOfTheNorthRoubaix(int year, List<String> teams) {
    return TourRace(
      id: 'race_roubaix_monument_$year',
      name: 'Hell of the North Pavé Monument',
      countryIso: 'FRA',
      uciCategory: RaceCategory.monument,
      startMonth: 4,
      startDay: 7,
      prizePoolEur: 240000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createCobbleStage(
          id: 'st_roubaix_1',
          stageNumber: 1,
          name: 'Trouée d\'Arenberg to Roubaix Vélodrome',
          distanceKm: 259.0,
        ),
      ],
    );
  }

  static TourRace _buildAmstelHillClassic(int year, List<String> teams) {
    return TourRace(
      id: 'race_amstel_$year',
      name: 'Amstel Dutch Hill Classic',
      countryIso: 'NED',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 4,
      startDay: 14,
      prizePoolEur: 160000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_amstel_1', stageNumber: 1, name: 'Valkenburg Cauberg Circuits', distanceKm: 253.0),
      ],
    );
  }

  static TourRace _buildFlecheWallonne(int year, List<String> teams) {
    return TourRace(
      id: 'race_fleche_$year',
      name: 'La Flèche de Wallonie',
      countryIso: 'BEL',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 4,
      startDay: 17,
      prizePoolEur: 155000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_fleche_1', stageNumber: 1, name: 'Mur de Huy 26% Wall Summit', distanceKm: 198.0),
      ],
    );
  }

  static TourRace _buildLiegeBastogneLiege(int year, List<String> teams) {
    return TourRace(
      id: 'race_liege_monument_$year',
      name: 'La Doyenne Ardennaise Monument',
      countryIso: 'BEL',
      uciCategory: RaceCategory.monument,
      startMonth: 4,
      startDay: 21,
      prizePoolEur: 235000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(
          id: 'st_lbl_1',
          stageNumber: 1,
          name: 'Côte de La Redoute & Roche-aux-Faucons',
          distanceKm: 257.0,
        ),
      ],
    );
  }

  static TourRace _buildTourDeRomandie(int year, List<String> teams) {
    return TourRace(
      id: 'race_romandie_$year',
      name: 'Tour de Romandie Alpine',
      countryIso: 'SUI',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 4,
      startDay: 23,
      prizePoolEur: 390000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createTimeTrialStage(id: 'st_rom_prologue', stageNumber: 1, name: 'Payerne Prologue ITT', distanceKm: 2.2),
        _createHillyStage(id: 'st_rom_2', stageNumber: 2, name: 'Fribourg Jura Hills', distanceKm: 165.0),
        _createMountainStage(id: 'st_rom_3', stageNumber: 3, name: 'Les Marécottes Summit', distanceKm: 171.0, isSummitFinish: true, summitElevation: 1050.0),
        _createTimeTrialStage(id: 'st_rom_4', stageNumber: 4, name: 'Oron Individual Time Trial', distanceKm: 15.5),
        _createMountainStage(id: 'st_rom_5', stageNumber: 5, name: 'Thyon 2000 Queen Stage', distanceKm: 159.0, isSummitFinish: true, summitElevation: 2090.0),
        _createFlatStage(id: 'st_rom_6', stageNumber: 6, name: 'Vernier Lake Geneva Finale', distanceKm: 150.0),
      ],
    );
  }

  // ===========================================================================
  // GRAND TOUR 1: CORSA ROSA D'ITALIA (21 ETAPÓW)
  // ===========================================================================
  static TourRace _buildCorsaRosaGiro(int year, List<String> teams) {
    final List<RaceStage> stages = [];

    // Tydzień 1: Piemont, Liguria, Toskania i Apeniny
    stages.add(_createTimeTrialStage(id: 'st_giro_1', stageNumber: 1, name: 'Torino Grande Partenza ITT', distanceKm: 19.6));
    stages.add(_createMountainStage(id: 'st_giro_2', stageNumber: 2, name: 'Santuario di Oropa Summit', distanceKm: 161.0, isSummitFinish: true, summitElevation: 1180.0));
    stages.add(_createFlatStage(id: 'st_giro_3', stageNumber: 3, name: 'Novara Po Valley Sprint', distanceKm: 166.0));
    stages.add(_createHillyStage(id: 'st_giro_4', stageNumber: 4, name: 'Andora Ligurian Coast', distanceKm: 190.0));
    stages.add(_createFlatStage(id: 'st_giro_5', stageNumber: 5, name: 'Lucca Tuscan Fast Finish', distanceKm: 178.0));
    stages.add(_createStradeGravelStage(id: 'st_giro_6', stageNumber: 6, name: 'Rapolano Terme White Roads', distanceKm: 180.0));
    stages.add(_createTimeTrialStage(id: 'st_giro_7', stageNumber: 7, name: 'Perugia Hilltop ITT', distanceKm: 40.6));
    stages.add(_createMountainStage(id: 'st_giro_8', stageNumber: 8, name: 'Prati di Tivo Queen Summit', distanceKm: 152.0, isSummitFinish: true, summitElevation: 1450.0));
    stages.add(_createFlatStage(id: 'st_giro_9', stageNumber: 9, name: 'Napoli Coastline Classic', distanceKm: 214.0));

    // Tydzień 2: Apeniny i Dolomity
    stages.add(_createHillyStage(id: 'st_giro_10', stageNumber: 10, name: 'Bocca della Selva Climb', distanceKm: 142.0));
    stages.add(_createFlatStage(id: 'st_giro_11', stageNumber: 11, name: 'Francavilla al Mare Sprint', distanceKm: 193.0));
    stages.add(_createHillyStage(id: 'st_giro_12', stageNumber: 12, name: 'Fano Muri Marchigiani', distanceKm: 193.0));
    stages.add(_createFlatStage(id: 'st_giro_13', stageNumber: 13, name: 'Cento Emilia Romagna Flat', distanceKm: 179.0));
    stages.add(_createTimeTrialStage(id: 'st_giro_14', stageNumber: 14, name: 'Desenzano del Garda ITT', distanceKm: 31.2));
    stages.add(_createMountainStage(id: 'st_giro_15', stageNumber: 15, name: 'Mottolino Livigno Alpine Hell', distanceKm: 222.0, isSummitFinish: true, summitElevation: 2385.0));

    // Tydzień 3: Dolomity, Passo dello Stelvio i Finał w Rzymie
    stages.add(_createMountainStage(id: 'st_giro_16', stageNumber: 16, name: 'Passo dello Stelvio Cima Coppi', distanceKm: 206.0, isSummitFinish: false, summitElevation: 2758.0));
    stages.add(_createMountainStage(id: 'st_giro_17', stageNumber: 17, name: 'Passo Brocon Double Ascent', distanceKm: 159.0, isSummitFinish: true, summitElevation: 1610.0));
    stages.add(_createFlatStage(id: 'st_giro_18', stageNumber: 18, name: 'Padova Sprinters Sanctuary', distanceKm: 178.0));
    stages.add(_createHillyStage(id: 'st_giro_19', stageNumber: 19, name: 'Sappada Friuli Escape', distanceKm: 157.0));
    stages.add(_createMountainStage(id: 'st_giro_20', stageNumber: 20, name: 'Monte Grappa Double Terror', distanceKm: 184.0, isSummitFinish: false, summitElevation: 1775.0));
    stages.add(_createFlatStage(id: 'st_giro_21', stageNumber: 21, name: 'Roma Colosseo Grand Finale', distanceKm: 125.0));

    return TourRace(
      id: 'race_giro_corsa_rosa_$year',
      name: 'Corsa Rosa d\'Italia Grand Tour',
      countryIso: 'ITA',
      uciCategory: RaceCategory.grandTour,
      startMonth: 5,
      startDay: 4,
      prizePoolEur: 1600000,
      participatingTeamIds: teams,
      ridersPerTeam: 8,
      classifications: _emptyClassifications(),
      stages: stages,
    );
  }

  // ===========================================================================
  // CZERWIEC: DAUPHINÉ, SZWAJCARIA & MISTRZOSTWA KRAJOWE
  // ===========================================================================
  static TourRace _buildCriteriumDesAlpes(int year, List<String> teams) {
    return TourRace(
      id: 'race_dauphine_$year',
      name: 'Critérium des Alpes',
      countryIso: 'FRA',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 6,
      startDay: 2,
      prizePoolEur: 520000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createFlatStage(id: 'st_dau_1', stageNumber: 1, name: 'Saint-Étienne Valley', distanceKm: 172.0),
        _createHillyStage(id: 'st_dau_2', stageNumber: 2, name: 'Col de la Loge Punch', distanceKm: 142.0),
        _createHillyStage(id: 'st_dau_3', stageNumber: 3, name: 'Les Échelles Rolling', distanceKm: 181.0),
        _createTimeTrialStage(id: 'st_dau_4', stageNumber: 4, name: 'Neulise Long Rolling ITT', distanceKm: 34.4),
        _createFlatStage(id: 'st_dau_5', stageNumber: 5, name: 'Saint-Priest Sprint', distanceKm: 167.0),
        _createMountainStage(id: 'st_dau_6', stageNumber: 6, name: 'Collet d\'Allevard Summit', distanceKm: 174.0, isSummitFinish: true, summitElevation: 1420.0),
        _createMountainStage(id: 'st_dau_7', stageNumber: 7, name: 'Samoëns 1600 Queen Stage', distanceKm: 155.0, isSummitFinish: true, summitElevation: 1610.0),
        _createMountainStage(id: 'st_dau_8', stageNumber: 8, name: 'Plateau des Glières Finale', distanceKm: 160.0, isSummitFinish: true, summitElevation: 1440.0),
      ],
    );
  }

  static TourRace _buildTourDeSuisse(int year, List<String> teams) {
    return TourRace(
      id: 'race_suisse_$year',
      name: 'Tour de Suisse National',
      countryIso: 'SUI',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 6,
      startDay: 9,
      prizePoolEur: 490000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createTimeTrialStage(id: 'st_sui_1', stageNumber: 1, name: 'Vaduz Prologue ITT', distanceKm: 4.8),
        _createHillyStage(id: 'st_sui_2', stageNumber: 2, name: 'Regensdorf Jura Slopes', distanceKm: 177.0),
        _createHillyStage(id: 'st_sui_3', stageNumber: 3, name: 'Rüschlikon Puncheur Finish', distanceKm: 161.0),
        _createMountainStage(id: 'st_sui_4', stageNumber: 4, name: 'Gotthardpass High Alpine', distanceKm: 171.0, isSummitFinish: true, summitElevation: 2091.0),
        _createMountainStage(id: 'st_sui_5', stageNumber: 5, name: 'Carì Wall Summit', distanceKm: 148.0, isSummitFinish: true, summitElevation: 1620.0),
        _createMountainStage(id: 'st_sui_6', stageNumber: 6, name: 'Blatten-Belalp Climb', distanceKm: 151.0, isSummitFinish: true, summitElevation: 1520.0),
        _createMountainStage(id: 'st_sui_7', stageNumber: 7, name: 'Villars-sur-Ollon Queen Climb', distanceKm: 118.0, isSummitFinish: true, summitElevation: 1255.0),
        _createTimeTrialStage(id: 'st_sui_8', stageNumber: 8, name: 'Aigle Mountain Time Trial', distanceKm: 15.7),
      ],
    );
  }

  static TourRace _buildNationalChampionships(int year, List<String> teams) {
    return TourRace(
      id: 'race_national_champs_$year',
      name: 'National Road Race Championships',
      countryIso: 'FRA',
      uciCategory: RaceCategory.class1,
      startMonth: 6,
      startDay: 23,
      prizePoolEur: 110000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_nat_1', stageNumber: 1, name: 'National Circuit Title Decider', distanceKm: 242.0),
      ],
    );
  }

  // ===========================================================================
  // GRAND TOUR 2: LA GRANDE BOUCLE DE FRANCE (21 ETAPÓW)
  // ===========================================================================
  static TourRace _buildLaGrandeBoucleTour(int year, List<String> teams) {
    final List<RaceStage> stages = [];

    // Tydzień 1: Grand Départ, Północ, Bruki, Szampania
    stages.add(_createHillyStage(id: 'st_tdf_1', stageNumber: 1, name: 'Florence to Rimini Apennines', distanceKm: 206.0));
    stages.add(_createHillyStage(id: 'st_tdf_2', stageNumber: 2, name: 'Cesenatico San Luca Wall', distanceKm: 199.0));
    stages.add(_createFlatStage(id: 'st_tdf_3', stageNumber: 3, name: 'Piacenza to Torino Fast Sprint', distanceKm: 230.0));
    stages.add(_createMountainStage(id: 'st_tdf_4', stageNumber: 4, name: 'Col du Galibier Alpine Colossus', distanceKm: 139.0, isSummitFinish: false, summitElevation: 2642.0));
    stages.add(_createFlatStage(id: 'st_tdf_5', stageNumber: 5, name: 'Saint-Vulbas Rhone Valley', distanceKm: 177.0));
    stages.add(_createFlatStage(id: 'st_tdf_6', stageNumber: 6, name: 'Dijon Burgundy Wine Sprint', distanceKm: 163.0));
    stages.add(_createTimeTrialStage(id: 'st_tdf_7', stageNumber: 7, name: 'Nuits-Saint-Georges Vineyards ITT', distanceKm: 25.3));
    stages.add(_createHillyStage(id: 'st_tdf_8', stageNumber: 8, name: 'Colombey-les-Deux-Églises', distanceKm: 183.0));
    stages.add(_createStradeGravelStage(id: 'st_tdf_9', stageNumber: 9, name: 'Troyes Champagne White Gravel', distanceKm: 199.0));

    // Tydzień 2: Masyw Centralny i Pireneje
    stages.add(_createFlatStage(id: 'st_tdf_10', stageNumber: 10, name: 'Saint-Amand Echelons Crosswinds', distanceKm: 187.0, windSpeedKmh: 32.0, weather: WeatherCondition.crosswindGale));
    stages.add(_createHillyStage(id: 'st_tdf_11', stageNumber: 11, name: 'Le Lioran Massif Central Traps', distanceKm: 211.0));
    stages.add(_createFlatStage(id: 'st_tdf_12', stageNumber: 12, name: 'Villeneuve-sur-Lot Sprint', distanceKm: 203.0));
    stages.add(_createFlatStage(id: 'st_tdf_13', stageNumber: 13, name: 'Pau Gateway to Pyrenees', distanceKm: 165.0));
    stages.add(_createMountainStage(id: 'st_tdf_14', stageNumber: 14, name: 'Col du Tourmalet to Pla d\'Adet', distanceKm: 151.0, isSummitFinish: true, summitElevation: 1669.0));
    stages.add(_createMountainStage(id: 'st_tdf_15', stageNumber: 15, name: 'Plateau de Beille Pyrenean Terror', distanceKm: 197.0, isSummitFinish: true, summitElevation: 1780.0));

    // Tydzień 3: Alpy, Alpe d'Huez, Cime de la Bonette & Nicea
    stages.add(_createFlatStage(id: 'st_tdf_16', stageNumber: 16, name: 'Nîmes Mistral Gutter Echelons', distanceKm: 188.0, windSpeedKmh: 38.0, weather: WeatherCondition.crosswindGale));
    stages.add(_createMountainStage(id: 'st_tdf_17', stageNumber: 17, name: 'Superdévoluy Alpine Escalation', distanceKm: 177.0, isSummitFinish: true, summitElevation: 1500.0));
    stages.add(_createHillyStage(id: 'st_tdf_18', stageNumber: 18, name: 'Barcelonnette Breakaway Day', distanceKm: 179.0));
    stages.add(_createMountainStage(id: 'st_tdf_19', stageNumber: 19, name: 'Cime de la Bonette Roof of Tour', distanceKm: 144.0, isSummitFinish: true, summitElevation: 2802.0));
    stages.add(_createMountainStage(id: 'st_tdf_20', stageNumber: 20, name: 'Col de la Couillole Battle', distanceKm: 132.0, isSummitFinish: true, summitElevation: 1678.0));
    stages.add(_createTimeTrialStage(id: 'st_tdf_21', stageNumber: 21, name: 'Monaco to Nice Promenade ITT', distanceKm: 33.7));

    return TourRace(
      id: 'race_tour_de_france_$year',
      name: 'La Grande Boucle de France Grand Tour',
      countryIso: 'FRA',
      uciCategory: RaceCategory.grandTour,
      startMonth: 6,
      startDay: 29,
      prizePoolEur: 2500000,
      participatingTeamIds: teams,
      ridersPerTeam: 8,
      classifications: _emptyClassifications(),
      stages: stages,
    );
  }

  // ===========================================================================
  // SIERPIEŃ: SAN SEBASTIÁN, TOUR DE POLOGNE, VUELTA (21 ETAPÓW)
  // ===========================================================================
  static TourRace _buildClasicaSanSebastian(int year, List<String> teams) {
    return TourRace(
      id: 'race_san_sebastian_$year',
      name: 'Clásica San Sebastián Klasikoa',
      countryIso: 'ESP',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 8,
      startDay: 3,
      prizePoolEur: 180000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_ss_1', stageNumber: 1, name: 'Murgil Tontorra Basque Steep Wall', distanceKm: 230.0),
      ],
    );
  }

  static TourRace _buildTourDePologne(int year, List<String> teams) {
    return TourRace(
      id: 'race_tour_de_pologne_$year',
      name: 'Tour de Pologne UCI WorldTour',
      countryIso: 'POL',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 8,
      startDay: 5,
      prizePoolEur: 450000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_tdp_1', stageNumber: 1, name: 'Wrocław do Karpacza Orlinek', distanceKm: 156.0),
        _createTimeTrialStage(id: 'st_tdp_2', stageNumber: 2, name: 'Karpacz Górski Chrono ITT', distanceKm: 15.4),
        _createHillyStage(id: 'st_tdp_3', stageNumber: 3, name: 'Wałbrzych Kotlina Kłodzka', distanceKm: 162.0),
        _createFlatStage(id: 'st_tdp_4', stageNumber: 4, name: 'Kudowa-Zdrój do Opola', distanceKm: 195.0),
        _createFlatStage(id: 'st_tdp_5', stageNumber: 5, name: 'Katowice aleja Korfantego Sprint', distanceKm: 187.0),
        _createMountainStage(id: 'st_tdp_6', stageNumber: 6, name: 'Bukowina Tatrzańska Królewski Etap', distanceKm: 183.0, isSummitFinish: true, summitElevation: 1010.0),
        _createFlatStage(id: 'st_tdp_7', stageNumber: 7, name: 'Kraków Błonia Finałowy Finisz', distanceKm: 142.0),
      ],
    );
  }

  // ===========================================================================
  // GRAND TOUR 3: LA VUELTA IBÉRICA (21 ETAPÓW)
  // ===========================================================================
  static TourRace _buildLaVueltaIberica(int year, List<String> teams) {
    final List<RaceStage> stages = [];

    // Tydzień 1: Portugalia, Andaluzja i Extremadura
    stages.add(_createTimeTrialStage(id: 'st_vue_1', stageNumber: 1, name: 'Lisboa Belém Tower ITT', distanceKm: 12.0));
    stages.add(_createHillyStage(id: 'st_vue_2', stageNumber: 2, name: 'Cascais to Ourém Punch', distanceKm: 194.0));
    stages.add(_createFlatStage(id: 'st_vue_3', stageNumber: 3, name: 'Lousã to Castelo Branco Sprint', distanceKm: 191.0));
    stages.add(_createMountainStage(id: 'st_vue_4', stageNumber: 4, name: 'Pico Villuercas Extremadura Ramp', distanceKm: 170.0, isSummitFinish: true, summitElevation: 1580.0));
    stages.add(_createFlatStage(id: 'st_vue_5', stageNumber: 5, name: 'Sevilla Guadalquivir Sprint', distanceKm: 177.0));
    stages.add(_createMountainStage(id: 'st_vue_6', stageNumber: 6, name: 'Sierra de Grazalema Cloud Climb', distanceKm: 185.0, isSummitFinish: true, summitElevation: 1320.0));
    stages.add(_createHillyStage(id: 'st_vue_7', stageNumber: 7, name: 'Córdoba Alto del 14% Finish', distanceKm: 180.0));
    stages.add(_createMountainStage(id: 'st_vue_8', stageNumber: 8, name: 'Sierra de Cazorla Wall Summit', distanceKm: 158.0, isSummitFinish: true, summitElevation: 1230.0));
    stages.add(_createMountainStage(id: 'st_vue_9', stageNumber: 9, name: 'Sierra Nevada Hazallanas Hell', distanceKm: 178.0, isSummitFinish: true, summitElevation: 2510.0));

    // Tydzień 2: Galicja, Asturia i Picos de Europa
    stages.add(_createHillyStage(id: 'st_vue_10', stageNumber: 10, name: 'Pontevedra Rías Baixas', distanceKm: 160.0));
    stages.add(_createHillyStage(id: 'st_vue_11', stageNumber: 11, name: 'Padrón Cortizo Circuit', distanceKm: 166.0));
    stages.add(_createMountainStage(id: 'st_vue_12', stageNumber: 12, name: 'Manzaneda Ski Resort Summit', distanceKm: 137.0, isSummitFinish: true, summitElevation: 1750.0));
    stages.add(_createMountainStage(id: 'st_vue_13', stageNumber: 13, name: 'Puerto de Ancares 18% Horror', distanceKm: 176.0, isSummitFinish: true, summitElevation: 1670.0));
    stages.add(_createHillyStage(id: 'st_vue_14', stageNumber: 14, name: 'Villablino Cantabrian Descent', distanceKm: 200.0));
    stages.add(_createMountainStage(id: 'st_vue_15', stageNumber: 15, name: 'Cuitu Negru 24% Monster Wall', distanceKm: 143.0, isSummitFinish: true, summitElevation: 1845.0));

    // Tydzień 3: Asturia, Kastylia, Angliru i Madryt
    stages.add(_createMountainStage(id: 'st_vue_16', stageNumber: 16, name: 'Lagos de Covadonga Legendary Lakes', distanceKm: 181.0, isSummitFinish: true, summitElevation: 1134.0));
    stages.add(_createFlatStage(id: 'st_vue_17', stageNumber: 17, name: 'Santander Bay Fast Sprint', distanceKm: 141.0));
    stages.add(_createHillyStage(id: 'st_vue_18', stageNumber: 18, name: 'Vitoria-Gasteiz Basque Trap', distanceKm: 179.0));
    stages.add(_createMountainStage(id: 'st_vue_19', stageNumber: 19, name: 'Alto de Moncalvillo Vine Summit', distanceKm: 173.0, isSummitFinish: true, summitElevation: 1490.0));
    stages.add(_createMountainStage(id: 'st_vue_20', stageNumber: 20, name: 'Picón Blanco Brutal Decider', distanceKm: 172.0, isSummitFinish: true, summitElevation: 1520.0));
    stages.add(_createTimeTrialStage(id: 'st_vue_21', stageNumber: 21, name: 'Madrid Gran Vía Sunset ITT', distanceKm: 24.6));

    return TourRace(
      id: 'race_vuelta_espana_$year',
      name: 'La Vuelta Ibérica Grand Tour',
      countryIso: 'ESP',
      uciCategory: RaceCategory.grandTour,
      startMonth: 8,
      startDay: 17,
      prizePoolEur: 1300000,
      participatingTeamIds: teams,
      ridersPerTeam: 8,
      classifications: _emptyClassifications(),
      stages: stages,
    );
  }

  static TourRace _buildBretagneClassic(int year, List<String> teams) {
    return TourRace(
      id: 'race_bretagne_$year',
      name: 'Bretagne Classic Ouest-France',
      countryIso: 'FRA',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 8,
      startDay: 25,
      prizePoolEur: 150000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_bret_1', stageNumber: 1, name: 'Plouay Circuit Ribinoù', distanceKm: 258.0),
      ],
    );
  }

  static TourRace _buildBeneluxWindTour(int year, List<String> teams) {
    return TourRace(
      id: 'race_benelux_$year',
      name: 'Benelux Wind Tour',
      countryIso: 'BEL',
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 8,
      startDay: 28,
      prizePoolEur: 320000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createFlatStage(id: 'st_ben_1', stageNumber: 1, name: 'Bredene Coastal Echelons', distanceKm: 176.0, windSpeedKmh: 35.0, weather: WeatherCondition.crosswindGale),
        _createTimeTrialStage(id: 'st_ben_2', stageNumber: 2, name: 'Sluis Dutch Dike ITT', distanceKm: 13.8),
        _createFlatStage(id: 'st_ben_3', stageNumber: 3, name: 'Ardooie Sprinters Paradise', distanceKm: 168.0),
        _createHillyStage(id: 'st_ben_4', stageNumber: 4, name: 'Limburg Hills Cauberg', distanceKm: 178.0),
        _createCobbleStage(id: 'st_ben_5', stageNumber: 5, name: 'Geraardsbergen Muur Finale', distanceKm: 187.0),
      ],
    );
  }

  static TourRace _buildGrandPrixQuebec(int year, List<String> teams) {
    return TourRace(
      id: 'race_quebec_$year',
      name: 'Grand Prix Cycliste de Québec',
      countryIso: 'CAN',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 9,
      startDay: 13,
      prizePoolEur: 170000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_quebec_1', stageNumber: 1, name: 'Old Québec Citadel 16 Laps', distanceKm: 201.6),
      ],
    );
  }

  static TourRace _buildGrandPrixMontreal(int year, List<String> teams) {
    return TourRace(
      id: 'race_montreal_$year',
      name: 'Grand Prix Cycliste de Montréal',
      countryIso: 'CAN',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 9,
      startDay: 15,
      prizePoolEur: 170000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(id: 'st_montreal_1', stageNumber: 1, name: 'Mont-Royal Summit 18 Laps', distanceKm: 221.4),
      ],
    );
  }

  static TourRace _buildWorldIttChampionship(int year, List<String> teams) {
    return TourRace(
      id: 'race_world_itt_$year',
      name: 'UCI World Time Trial Championship',
      countryIso: 'SUI',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 9,
      startDay: 22,
      prizePoolEur: 200000,
      participatingTeamIds: teams,
      ridersPerTeam: 3,
      classifications: _emptyClassifications(),
      stages: [
        _createTimeTrialStage(id: 'st_wc_itt', stageNumber: 1, name: 'Rainbow Jersey Flat & Fast ITT', distanceKm: 46.1),
      ],
    );
  }

  static TourRace _buildWorldRoadRaceChampionship(int year, List<String> teams) {
    return TourRace(
      id: 'race_world_rr_$year',
      name: 'UCI World Road Race Championship',
      countryIso: 'SUI',
      uciCategory: RaceCategory.worldTourOneDay,
      startMonth: 9,
      startDay: 29,
      prizePoolEur: 300000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createHillyStage(
          id: 'st_wc_rr',
          stageNumber: 1,
          name: 'Rainbow Jersey Road Race Decider',
          distanceKm: 273.9,
        ),
      ],
    );
  }

  static TourRace _buildIlLombardiaClassic(int year, List<String> teams) {
    return TourRace(
      id: 'race_lombardia_monument_$year',
      name: 'Il Lombardia Falling Leaves Monument',
      countryIso: 'ITA',
      uciCategory: RaceCategory.monument,
      startMonth: 10,
      startDay: 12,
      prizePoolEur: 245000,
      participatingTeamIds: teams,
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
      stages: [
        _createMountainStage(
          id: 'st_lombardia_1',
          stageNumber: 1,
          name: 'Madonna del Ghisallo & Bergamo Walls',
          distanceKm: 252.0,
          isSummitFinish: false,
          summitElevation: 1100.0,
        ),
      ],
    );
  }

  static RaceClassifications _emptyClassifications() {
    return const RaceClassifications(
      generalClassification: [],
      pointsClassification: [],
      mountainsClassification: [],
      youthClassification: [],
      teamClassification: [],
    );
  }
}

