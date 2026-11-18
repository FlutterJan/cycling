// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/race/tour_race.dart';

/// Kraj Europy Środkowej reprezentowany w pakiecie wyścigów.
enum CentralEuropeCountry {
  poland('POL', 'Polska', 'PL', AppColors.crimsonAlert),
  czechia('CZE', 'Czechy', 'CZ', AppColors.accentBlue),
  slovakia('SVK', 'Słowacja', 'SK', AppColors.cyanAccent),
  hungary('HUN', 'Węgry', 'HU', AppColors.statusSuccess);

  final String isoCode;
  final String polishName;
  final String shortCode;
  final Color accentColor;

  const CentralEuropeCountry(
    this.isoCode,
    this.polishName,
    this.shortCode,
    this.accentColor,
  );

  String toJson() => name;

  static CentralEuropeCountry fromJson(String value) {
    return CentralEuropeCountry.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CentralEuropeCountry.poland,
    );
  }
}

/// Identyfikator wyścigu w pakiecie Europy Środkowej.
enum CentralEuropeRaceId {
  tourDePologne('race_central_eu_tour_de_pologne', 'Tour de Pologne'),
  tourDeHongrie('race_central_eu_tour_de_hongrie', 'Tour de Hongrie'),
  czechTour('race_central_eu_czech_tour', 'Czech Tour'),
  okoloSlovenska('race_central_eu_okolo_slovenska', 'Okolo Slovenska'),
  silesiaBeskidyClassic(
    'race_central_eu_silesia_beskidy_classic',
    'Silesia & Beskidy Classic',
  );

  final String baseId;
  final String displayName;

  const CentralEuropeRaceId(this.baseId, this.displayName);

  String toJson() => name;

  static CentralEuropeRaceId fromJson(String value) {
    return CentralEuropeRaceId.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CentralEuropeRaceId.tourDePologne,
    );
  }
}

/// Charakterystyczny podjazd, finisz lub sektor regionu Europy Środkowej.
class CentralEuropeLandmark {
  final String id;
  final String name;
  final CentralEuropeCountry country;
  final int elevationM;
  final double lengthKm;
  final double avgGradientPercent;
  final double maxGradientPercent;
  final String tacticalNote;

  const CentralEuropeLandmark({
    required this.id,
    required this.name,
    required this.country,
    required this.elevationM,
    required this.lengthKm,
    required this.avgGradientPercent,
    required this.maxGradientPercent,
    required this.tacticalNote,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country.toJson(),
        'elevationM': elevationM,
        'lengthKm': lengthKm,
        'avgGradientPercent': avgGradientPercent,
        'maxGradientPercent': maxGradientPercent,
        'tacticalNote': tacticalNote,
      };

  factory CentralEuropeLandmark.fromJson(Map<String, dynamic> json) {
    return CentralEuropeLandmark(
      id: json['id'] as String,
      name: json['name'] as String,
      country: CentralEuropeCountry.fromJson(json['country'] as String),
      elevationM: (json['elevationM'] as num).toInt(),
      lengthKm: (json['lengthKm'] as num).toDouble(),
      avgGradientPercent: (json['avgGradientPercent'] as num).toDouble(),
      maxGradientPercent: (json['maxGradientPercent'] as num).toDouble(),
      tacticalNote: json['tacticalNote'] as String,
    );
  }
}

/// Specyfikacja wyścigu w pakiecie Europy Środkowej.
class CentralEuropeRaceSpec {
  final CentralEuropeRaceId raceId;
  final String officialName;
  final CentralEuropeCountry country;
  final RaceCategory uciCategory;
  final int startMonth;
  final int startDay;
  final int stageCount;
  final int prizePoolEur;
  final int uciWinnerPoints;
  final int ridersPerTeam;
  final double prestigeRating;
  final String summary;
  final List<CentralEuropeLandmark> landmarks;

  const CentralEuropeRaceSpec({
    required this.raceId,
    required this.officialName,
    required this.country,
    required this.uciCategory,
    required this.startMonth,
    required this.startDay,
    required this.stageCount,
    required this.prizePoolEur,
    required this.uciWinnerPoints,
    required this.ridersPerTeam,
    required this.prestigeRating,
    required this.summary,
    required this.landmarks,
  });

  String get categoryBadge {
    switch (uciCategory) {
      case RaceCategory.worldTourStageRace:
        return '2.UWT';
      case RaceCategory.proSeries:
        return '2.Pro';
      case RaceCategory.class1:
        return stageCount == 1 ? '1.1' : '2.1';
      case RaceCategory.grandTour:
        return 'GT';
      case RaceCategory.monument:
        return '1.UWT-M';
      case RaceCategory.worldTourOneDay:
        return '1.UWT';
    }
  }
}

/// Pakiet wyścigów Europy Środkowej wraz z pełnym 7-etapowym Tour de Pologne.
class TourDePologneAndCentralEuropePack {
  TourDePologneAndCentralEuropePack._();

  static const List<CentralEuropeLandmark> tourDePologneLandmarks = [
    CentralEuropeLandmark(
      id: 'lm_tdp_karpacz_orlinek',
      name: 'Karpacz Orlinek',
      country: CentralEuropeCountry.poland,
      elevationM: 835,
      lengthKm: 11.4,
      avgGradientPercent: 4.8,
      maxGradientPercent: 12.2,
      tacticalNote:
          'Sztywny podjazd pod skocznię Orlinek – kluczowa selekcja GC na 1. etapie i górskim ITT.',
    ),
    CentralEuropeLandmark(
      id: 'lm_tdp_gliczarow',
      name: 'Gliczarów (Ściana Bukovina)',
      country: CentralEuropeCountry.poland,
      elevationM: 985,
      lengthKm: 5.5,
      avgGradientPercent: 8.6,
      maxGradientPercent: 22.0,
      tacticalNote:
          'Ikoniczna podhalańska ściana do 22% nachylenia na królewskim etapie do Bukowiny Tatrzańskiej.',
    ),
    CentralEuropeLandmark(
      id: 'lm_tdp_krakow_blonia',
      name: 'Kraków Błonia',
      country: CentralEuropeCountry.poland,
      elevationM: 215,
      lengthKm: 4.0,
      avgGradientPercent: 0.2,
      maxGradientPercent: 1.5,
      tacticalNote:
          'Superszybkie rundy finałowe wokół Błoń w Krakowie z walką pociągów sprinterskich o zwycięstwo.',
    ),
  ];

  static const List<CentralEuropeLandmark> centralEuropeLandmarks = [
    ...tourDePologneLandmarks,
    CentralEuropeLandmark(
      id: 'lm_hun_kekesteto',
      name: 'Kékestető (Mátra)',
      country: CentralEuropeCountry.hungary,
      elevationM: 1014,
      lengthKm: 12.1,
      avgGradientPercent: 5.7,
      maxGradientPercent: 10.5,
      tacticalNote:
          'Najwyższy szczyt Węgier i królewski finisz Tour de Hongrie.',
    ),
    CentralEuropeLandmark(
      id: 'lm_cze_dlouhe_strane',
      name: 'Dlouhé Stráně (Jesioniki)',
      country: CentralEuropeCountry.czechia,
      elevationM: 1350,
      lengthKm: 13.8,
      avgGradientPercent: 7.4,
      maxGradientPercent: 12.8,
      tacticalNote:
          'Alpejska wspinaczka w Jesionikach ponad górny zbiornik elektrowni szczytowo-pompowej.',
    ),
    CentralEuropeLandmark(
      id: 'lm_svk_strbske_pleso',
      name: 'Štrbské Pleso (Tatry Wysokie)',
      country: CentralEuropeCountry.slovakia,
      elevationM: 1346,
      lengthKm: 11.2,
      avgGradientPercent: 5.4,
      maxGradientPercent: 9.0,
      tacticalNote:
          'Wysokogórski finisz w słowackich Tatrach decydujący o losach Okolo Slovenska.',
    ),
    CentralEuropeLandmark(
      id: 'lm_pol_salmopol',
      name: 'Przełęcz Salmopolska (Biały Krzyż)',
      country: CentralEuropeCountry.poland,
      elevationM: 934,
      lengthKm: 8.6,
      avgGradientPercent: 5.9,
      maxGradientPercent: 11.0,
      tacticalNote:
          'Klasyczny beskidzki podjazd rozrywający peleton na Silesia & Beskidy Classic.',
    ),
  ];

  static const List<CentralEuropeRaceSpec> allRaceSpecs = [
    CentralEuropeRaceSpec(
      raceId: CentralEuropeRaceId.tourDePologne,
      officialName: 'Tour de Pologne UCI WorldTour',
      country: CentralEuropeCountry.poland,
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 8,
      startDay: 5,
      stageCount: 7,
      prizePoolEur: 480000,
      uciWinnerPoints: 400,
      ridersPerTeam: 7,
      prestigeRating: 92.0,
      summary:
          '7-etapowy wyścig UCI WorldTour przez Karkonosze, Górny Śląsk i Podhale: Karpacz Orlinek, górska czasówka, Gliczarów oraz finisz na Błoniach w Krakowie.',
      landmarks: tourDePologneLandmarks,
    ),
    CentralEuropeRaceSpec(
      raceId: CentralEuropeRaceId.tourDeHongrie,
      officialName: 'Tour de Hongrie',
      country: CentralEuropeCountry.hungary,
      uciCategory: RaceCategory.proSeries,
      startMonth: 5,
      startDay: 14,
      stageCount: 5,
      prizePoolEur: 210000,
      uciWinnerPoints: 200,
      ridersPerTeam: 6,
      prestigeRating: 78.0,
      summary:
          '5-etapowy wyścig UCI ProSeries wokół Balatonu i Budapesztu z królewskim podjazdem na Kékestető (1014 m) oraz finiszowym wzgórzem w Pécs.',
      landmarks: [
        CentralEuropeLandmark(
          id: 'lm_hun_kekesteto_ref',
          name: 'Kékestető (Mátra)',
          country: CentralEuropeCountry.hungary,
          elevationM: 1014,
          lengthKm: 12.1,
          avgGradientPercent: 5.7,
          maxGradientPercent: 10.5,
          tacticalNote: 'Królewski podjazd w górach Mátra.',
        ),
      ],
    ),
    CentralEuropeRaceSpec(
      raceId: CentralEuropeRaceId.czechTour,
      officialName: 'Czech Tour',
      country: CentralEuropeCountry.czechia,
      uciCategory: RaceCategory.class1,
      startMonth: 7,
      startDay: 25,
      stageCount: 4,
      prizePoolEur: 145000,
      uciWinnerPoints: 125,
      ridersPerTeam: 6,
      prestigeRating: 74.0,
      summary:
          '4-etapowa morawska klasyka etapowa przez Beskidy i Jesioniki z finałami na Pustevny oraz Dlouhé Stráně.',
      landmarks: [
        CentralEuropeLandmark(
          id: 'lm_cze_dlouhe_strane_ref',
          name: 'Dlouhé Stráně (Jesioniki)',
          country: CentralEuropeCountry.czechia,
          elevationM: 1350,
          lengthKm: 13.8,
          avgGradientPercent: 7.4,
          maxGradientPercent: 12.8,
          tacticalNote: 'Najwyższa meta wyścigu w Republice Czeskiej.',
        ),
      ],
    ),
    CentralEuropeRaceSpec(
      raceId: CentralEuropeRaceId.okoloSlovenska,
      officialName: 'Okolo Slovenska',
      country: CentralEuropeCountry.slovakia,
      uciCategory: RaceCategory.class1,
      startMonth: 6,
      startDay: 26,
      stageCount: 5,
      prizePoolEur: 135000,
      uciWinnerPoints: 125,
      ridersPerTeam: 6,
      prestigeRating: 72.0,
      summary:
          '5-etapowy wyścig dookoła Słowacji z drużynową czasówką na otwarcie, wspinaczką na Štrbské Pleso i pagórkowatym finałem w Kohútce.',
      landmarks: [
        CentralEuropeLandmark(
          id: 'lm_svk_strbske_pleso_ref',
          name: 'Štrbské Pleso (Tatry Wysokie)',
          country: CentralEuropeCountry.slovakia,
          elevationM: 1346,
          lengthKm: 11.2,
          avgGradientPercent: 5.4,
          maxGradientPercent: 9.0,
          tacticalNote: 'Tatrzańska wspinaczka rozstrzygająca klasyfikację GC.',
        ),
      ],
    ),
    CentralEuropeRaceSpec(
      raceId: CentralEuropeRaceId.silesiaBeskidyClassic,
      officialName: 'Silesia & Beskidy Classic',
      country: CentralEuropeCountry.poland,
      uciCategory: RaceCategory.class1,
      startMonth: 6,
      startDay: 15,
      stageCount: 1,
      prizePoolEur: 65000,
      uciWinnerPoints: 125,
      ridersPerTeam: 6,
      prestigeRating: 69.0,
      summary:
          'Jednodniowy górski klasyk w Beskidzie Śląskim przez Przełęcz Kubalonkę i Przełęcz Salmopolską z finiszem w Szczyrku.',
      landmarks: [
        CentralEuropeLandmark(
          id: 'lm_pol_salmopol_ref',
          name: 'Przełęcz Salmopolska (Biały Krzyż)',
          country: CentralEuropeCountry.poland,
          elevationM: 934,
          lengthKm: 8.6,
          avgGradientPercent: 5.9,
          maxGradientPercent: 11.0,
          tacticalNote: 'Decydująca selekcja w Beskidzie Śląskim.',
        ),
      ],
    ),
  ];

  /// Buduje kompletny pakiet wyścigów Europy Środkowej gotowy do wpięcia w kalendarz.
  static List<TourRace> buildPack({
    required int seasonYear,
    required List<String> participatingTeamIds,
    bool includeWorldTour = true,
    bool includeProSeries = true,
    bool includeClass1 = true,
  }) {
    final List<TourRace> races = [];
    for (final spec in allRaceSpecs) {
      if (spec.uciCategory == RaceCategory.worldTourStageRace &&
          !includeWorldTour) {
        continue;
      }
      if (spec.uciCategory == RaceCategory.proSeries && !includeProSeries) {
        continue;
      }
      if (spec.uciCategory == RaceCategory.class1 && !includeClass1) {
        continue;
      }
      races.add(
        buildRaceById(
          spec.raceId,
          seasonYear: seasonYear,
          participatingTeamIds: participatingTeamIds,
        ),
      );
    }
    return List<TourRace>.unmodifiable(races);
  }

  /// Buduje konkretny wyścig pakietu na podstawie jego identyfikatora.
  static TourRace buildRaceById(
    CentralEuropeRaceId id, {
    required int seasonYear,
    required List<String> participatingTeamIds,
  }) {
    switch (id) {
      case CentralEuropeRaceId.tourDePologne:
        return buildTourDePologne(
          seasonYear: seasonYear,
          participatingTeamIds: participatingTeamIds,
        );
      case CentralEuropeRaceId.tourDeHongrie:
        return _buildTourDeHongrie(seasonYear, participatingTeamIds);
      case CentralEuropeRaceId.czechTour:
        return _buildCzechTour(seasonYear, participatingTeamIds);
      case CentralEuropeRaceId.okoloSlovenska:
        return _buildOkoloSlovenska(seasonYear, participatingTeamIds);
      case CentralEuropeRaceId.silesiaBeskidyClassic:
        return _buildSilesiaBeskidyClassic(seasonYear, participatingTeamIds);
    }
  }

  /// Buduje pełny 7-etapowy Tour de Pologne UCI WorldTour (Karpacz Orlinek, Gliczarów, Kraków).
  static TourRace buildTourDePologne({
    required int seasonYear,
    required List<String> participatingTeamIds,
  }) {
    final stages = <RaceStage>[
      // Etap 1: Wrocław – Karpacz Orlinek (156.1 km)
      RaceStage(
        id: 'st_tdp_ce_1_$seasonYear',
        stageNumber: 1,
        name: 'Wrocław – Karpacz Orlinek',
        stageType: StageType.summitFinish,
        baseTemperatureCelsius: 23.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 12.0,
        segments: _buildContinuousSegments(
          specs: const [
            _SegSpec(
              lengthKm: 42.0,
              endElevationM: 175.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 18.0,
              windBearing: 270.0,
              roadBearing: 235.0,
              classification: SegmentClassification.intermediateSprint,
            ),
            _SegSpec(
              lengthKm: 44.0,
              endElevationM: 390.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 32.0,
              windBearing: 270.0,
              roadBearing: 225.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 18.0,
              endElevationM: 727.0,
              surface: SegmentSurfaceType.roughAsphalt,
              technicalDifficulty: 58.0,
              windBearing: 260.0,
              roadBearing: 245.0,
              classification: SegmentClassification.cat2,
            ),
            _SegSpec(
              lengthKm: 24.0,
              endElevationM: 430.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 54.0,
              windBearing: 255.0,
              roadBearing: 280.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 16.7,
              endElevationM: 545.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 42.0,
              windBearing: 250.0,
              roadBearing: 210.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 11.4,
              endElevationM: 835.0,
              surface: SegmentSurfaceType.roughAsphalt,
              technicalDifficulty: 72.0,
              windBearing: 240.0,
              roadBearing: 205.0,
              classification: SegmentClassification.finishLine,
            ),
          ],
          initialElevationM: 120.0,
        ),
      ),

      // Etap 2: Mysłakowice – Karpacz Orlinek ITT (15.4 km)
      RaceStage(
        id: 'st_tdp_ce_2_$seasonYear',
        stageNumber: 2,
        name: 'Mysłakowice – Karpacz Orlinek ITT',
        stageType: StageType.individualTimeTrial,
        baseTemperatureCelsius: 21.0,
        weatherCondition: WeatherCondition.overcast,
        windSpeedKmh: 15.0,
        segments: _buildContinuousSegments(
          specs: const [
            _SegSpec(
              lengthKm: 4.5,
              endElevationM: 435.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 36.0,
              windBearing: 250.0,
              roadBearing: 195.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 5.5,
              endElevationM: 615.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 54.0,
              windBearing: 250.0,
              roadBearing: 200.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 5.4,
              endElevationM: 835.0,
              surface: SegmentSurfaceType.roughAsphalt,
              technicalDifficulty: 68.0,
              windBearing: 240.0,
              roadBearing: 210.0,
              classification: SegmentClassification.finishLine,
            ),
          ],
          initialElevationM: 375.0,
        ),
      ),

      // Etap 3: Wałbrzych – Duszniki-Zdrój (161.5 km)
      RaceStage(
        id: 'st_tdp_ce_3_$seasonYear',
        stageNumber: 3,
        name: 'Wałbrzych – Duszniki-Zdrój (Kotlina Kłodzka)',
        stageType: StageType.hilly,
        baseTemperatureCelsius: 20.0,
        weatherCondition: WeatherCondition.overcast,
        windSpeedKmh: 16.0,
        segments: _buildContinuousSegments(
          specs: const [
            _SegSpec(
              lengthKm: 34.0,
              endElevationM: 750.0,
              surface: SegmentSurfaceType.roughAsphalt,
              technicalDifficulty: 55.0,
              windBearing: 230.0,
              roadBearing: 155.0,
              classification: SegmentClassification.cat2,
            ),
            _SegSpec(
              lengthKm: 32.0,
              endElevationM: 420.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 45.0,
              windBearing: 230.0,
              roadBearing: 170.0,
              classification: SegmentClassification.intermediateSprint,
            ),
            _SegSpec(
              lengthKm: 36.0,
              endElevationM: 680.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 48.0,
              windBearing: 225.0,
              roadBearing: 195.0,
              classification: SegmentClassification.cat3,
            ),
            _SegSpec(
              lengthKm: 41.5,
              endElevationM: 480.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 40.0,
              windBearing: 225.0,
              roadBearing: 240.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 18.0,
              endElevationM: 615.0,
              surface: SegmentSurfaceType.roughAsphalt,
              technicalDifficulty: 62.0,
              windBearing: 220.0,
              roadBearing: 225.0,
              classification: SegmentClassification.finishLine,
            ),
          ],
          initialElevationM: 445.0,
        ),
      ),

      // Etap 4: Kudowa-Zdrój – Prudnik (195.3 km)
      RaceStage(
        id: 'st_tdp_ce_4_$seasonYear',
        stageNumber: 4,
        name: 'Kudowa-Zdrój – Prudnik',
        stageType: StageType.flat,
        baseTemperatureCelsius: 25.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 18.0,
        segments: _buildContinuousSegments(
          specs: const [
            _SegSpec(
              lengthKm: 35.0,
              endElevationM: 585.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 35.0,
              windBearing: 260.0,
              roadBearing: 95.0,
              classification: SegmentClassification.cat3,
            ),
            _SegSpec(
              lengthKm: 58.0,
              endElevationM: 295.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 22.0,
              windBearing: 260.0,
              roadBearing: 90.0,
              classification: SegmentClassification.intermediateSprint,
            ),
            _SegSpec(
              lengthKm: 64.0,
              endElevationM: 250.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 18.0,
              windBearing: 265.0,
              roadBearing: 85.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 38.3,
              endElevationM: 265.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 26.0,
              windBearing: 265.0,
              roadBearing: 95.0,
              classification: SegmentClassification.finishLine,
            ),
          ],
          initialElevationM: 390.0,
        ),
      ),

      // Etap 5: Katowice – Katowice (Aleja Korfantego) (187.6 km)
      RaceStage(
        id: 'st_tdp_ce_5_$seasonYear',
        stageNumber: 5,
        name: 'Katowice – Katowice (Aleja Korfantego)',
        stageType: StageType.flat,
        baseTemperatureCelsius: 26.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 11.0,
        segments: _buildContinuousSegments(
          specs: const [
            _SegSpec(
              lengthKm: 55.0,
              endElevationM: 305.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 22.0,
              windBearing: 210.0,
              roadBearing: 125.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 54.0,
              endElevationM: 280.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 25.0,
              windBearing: 210.0,
              roadBearing: 315.0,
              classification: SegmentClassification.intermediateSprint,
            ),
            _SegSpec(
              lengthKm: 48.0,
              endElevationM: 295.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 28.0,
              windBearing: 210.0,
              roadBearing: 180.0,
              classification: SegmentClassification.cat4,
            ),
            _SegSpec(
              lengthKm: 30.6,
              endElevationM: 265.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 32.0,
              windBearing: 210.0,
              roadBearing: 175.0,
              classification: SegmentClassification.finishLine,
            ),
          ],
          initialElevationM: 268.0,
        ),
      ),

      // Etap 6: Wadowice – Bukowina Tatrzańska (Gliczarów Królewski Etap) (183.2 km)
      RaceStage(
        id: 'st_tdp_ce_6_$seasonYear',
        stageNumber: 6,
        name: 'Wadowice – Bukowina Tatrzańska (Gliczarów)',
        stageType: StageType.summitFinish,
        baseTemperatureCelsius: 19.0,
        weatherCondition: WeatherCondition.lightRain,
        windSpeedKmh: 19.0,
        segments: _buildContinuousSegments(
          specs: const [
            _SegSpec(
              lengthKm: 54.0,
              endElevationM: 610.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 38.0,
              windBearing: 195.0,
              roadBearing: 155.0,
              classification: SegmentClassification.intermediateSprint,
            ),
            _SegSpec(
              lengthKm: 42.0,
              endElevationM: 790.0,
              surface: SegmentSurfaceType.roughAsphalt,
              technicalDifficulty: 58.0,
              windBearing: 195.0,
              roadBearing: 165.0,
              classification: SegmentClassification.cat2,
            ),
            _SegSpec(
              lengthKm: 32.0,
              endElevationM: 640.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 52.0,
              windBearing: 200.0,
              roadBearing: 170.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 24.0,
              endElevationM: 945.0,
              surface: SegmentSurfaceType.roughAsphalt,
              technicalDifficulty: 72.0,
              windBearing: 200.0,
              roadBearing: 150.0,
              classification: SegmentClassification.cat1,
            ),
            // Ściana Bukovina / Gliczarów
            _SegSpec(
              lengthKm: 5.5,
              endElevationM: 985.0,
              surface: SegmentSurfaceType.roughAsphalt,
              technicalDifficulty: 88.0,
              windBearing: 205.0,
              roadBearing: 145.0,
              classification: SegmentClassification.cat1,
            ),
            _SegSpec(
              lengthKm: 13.5,
              endElevationM: 760.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 64.0,
              windBearing: 205.0,
              roadBearing: 160.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 12.2,
              endElevationM: 995.0,
              surface: SegmentSurfaceType.roughAsphalt,
              technicalDifficulty: 75.0,
              windBearing: 205.0,
              roadBearing: 175.0,
              classification: SegmentClassification.finishLine,
            ),
          ],
          initialElevationM: 270.0,
        ),
      ),

      // Etap 7: Wieliczka – Kraków Błonia (142.1 km)
      RaceStage(
        id: 'st_tdp_ce_7_$seasonYear',
        stageNumber: 7,
        name: 'Wieliczka – Kraków (Błonia)',
        stageType: StageType.flat,
        baseTemperatureCelsius: 24.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 10.0,
        segments: _buildContinuousSegments(
          specs: const [
            _SegSpec(
              lengthKm: 36.0,
              endElevationM: 345.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 28.0,
              windBearing: 255.0,
              roadBearing: 295.0,
              classification: SegmentClassification.cat3,
            ),
            _SegSpec(
              lengthKm: 48.0,
              endElevationM: 222.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 24.0,
              windBearing: 255.0,
              roadBearing: 325.0,
              classification: SegmentClassification.intermediateSprint,
            ),
            _SegSpec(
              lengthKm: 34.0,
              endElevationM: 215.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 30.0,
              windBearing: 255.0,
              roadBearing: 275.0,
              classification: SegmentClassification.none,
            ),
            _SegSpec(
              lengthKm: 24.1,
              endElevationM: 215.0,
              surface: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 34.0,
              windBearing: 255.0,
              roadBearing: 265.0,
              classification: SegmentClassification.finishLine,
            ),
          ],
          initialElevationM: 240.0,
        ),
      ),
    ];

    return TourRace(
      id: '${CentralEuropeRaceId.tourDePologne.baseId}_$seasonYear',
      name: 'Tour de Pologne UCI WorldTour',
      countryIso: CentralEuropeCountry.poland.isoCode,
      uciCategory: RaceCategory.worldTourStageRace,
      startMonth: 8,
      startDay: 5,
      stages: List<RaceStage>.unmodifiable(stages),
      prizePoolEur: 480000,
      participatingTeamIds: List<String>.unmodifiable(participatingTeamIds),
      ridersPerTeam: 7,
      classifications: _emptyClassifications(),
    );
  }

  static TourRace _buildTourDeHongrie(
    int seasonYear,
    List<String> teams,
  ) {
    final stages = <RaceStage>[
      _simpleStage(
        id: 'st_hun_1_$seasonYear',
        stageNumber: 1,
        name: 'Siófok – Kaposvár',
        stageType: StageType.flat,
        distanceKm: 173.0,
        startElevationM: 112.0,
        peakElevationM: 215.0,
        finishElevationM: 153.0,
        weather: WeatherCondition.sunny,
      ),
      _simpleStage(
        id: 'st_hun_2_$seasonYear',
        stageNumber: 2,
        name: 'Balatonfüred – Győr',
        stageType: StageType.flat,
        distanceKm: 164.0,
        startElevationM: 115.0,
        peakElevationM: 290.0,
        finishElevationM: 108.0,
        weather: WeatherCondition.crosswindGale,
      ),
      _simpleStage(
        id: 'st_hun_3_$seasonYear',
        stageNumber: 3,
        name: 'Kazincbarcika – Gyöngyös (Kékestető)',
        stageType: StageType.summitFinish,
        distanceKm: 182.0,
        startElevationM: 145.0,
        peakElevationM: 1014.0,
        finishElevationM: 1014.0,
        weather: WeatherCondition.overcast,
        finishClassification: SegmentClassification.finishLine,
      ),
      _simpleStage(
        id: 'st_hun_4_$seasonYear',
        stageNumber: 4,
        name: 'Budapest – Etyek',
        stageType: StageType.hilly,
        distanceKm: 165.0,
        startElevationM: 105.0,
        peakElevationM: 345.0,
        finishElevationM: 210.0,
        weather: WeatherCondition.sunny,
      ),
      _simpleStage(
        id: 'st_hun_5_$seasonYear',
        stageNumber: 5,
        name: 'Siófok – Pécs (Bárány út)',
        stageType: StageType.hilly,
        distanceKm: 173.0,
        startElevationM: 112.0,
        peakElevationM: 485.0,
        finishElevationM: 280.0,
        weather: WeatherCondition.sunny,
      ),
    ];

    return TourRace(
      id: '${CentralEuropeRaceId.tourDeHongrie.baseId}_$seasonYear',
      name: 'Tour de Hongrie',
      countryIso: CentralEuropeCountry.hungary.isoCode,
      uciCategory: RaceCategory.proSeries,
      startMonth: 5,
      startDay: 14,
      stages: List<RaceStage>.unmodifiable(stages),
      prizePoolEur: 210000,
      participatingTeamIds: List<String>.unmodifiable(teams),
      ridersPerTeam: 6,
      classifications: _emptyClassifications(),
    );
  }

  static TourRace _buildCzechTour(
    int seasonYear,
    List<String> teams,
  ) {
    final stages = <RaceStage>[
      _simpleStage(
        id: 'st_cze_1_$seasonYear',
        stageNumber: 1,
        name: 'Prostějov – Ostrava',
        stageType: StageType.flat,
        distanceKm: 151.0,
        startElevationM: 225.0,
        peakElevationM: 360.0,
        finishElevationM: 215.0,
        weather: WeatherCondition.sunny,
      ),
      _simpleStage(
        id: 'st_cze_2_$seasonYear',
        stageNumber: 2,
        name: 'Zlín – Pustevny',
        stageType: StageType.summitFinish,
        distanceKm: 172.0,
        startElevationM: 230.0,
        peakElevationM: 1018.0,
        finishElevationM: 1018.0,
        weather: WeatherCondition.overcast,
      ),
      _simpleStage(
        id: 'st_cze_3_$seasonYear',
        stageNumber: 3,
        name: 'Moravská Třebová – Dlouhé Stráně',
        stageType: StageType.summitFinish,
        distanceKm: 134.0,
        startElevationM: 345.0,
        peakElevationM: 1350.0,
        finishElevationM: 1350.0,
        weather: WeatherCondition.lightRain,
      ),
      _simpleStage(
        id: 'st_cze_4_$seasonYear',
        stageNumber: 4,
        name: 'Šumperk – Šternberk',
        stageType: StageType.hilly,
        distanceKm: 129.0,
        startElevationM: 315.0,
        peakElevationM: 760.0,
        finishElevationM: 270.0,
        weather: WeatherCondition.sunny,
      ),
    ];

    return TourRace(
      id: '${CentralEuropeRaceId.czechTour.baseId}_$seasonYear',
      name: 'Czech Tour',
      countryIso: CentralEuropeCountry.czechia.isoCode,
      uciCategory: RaceCategory.class1,
      startMonth: 7,
      startDay: 25,
      stages: List<RaceStage>.unmodifiable(stages),
      prizePoolEur: 145000,
      participatingTeamIds: List<String>.unmodifiable(teams),
      ridersPerTeam: 6,
      classifications: _emptyClassifications(),
    );
  }

  static TourRace _buildOkoloSlovenska(
    int seasonYear,
    List<String> teams,
  ) {
    final stages = <RaceStage>[
      _simpleStage(
        id: 'st_svk_1_$seasonYear',
        stageNumber: 1,
        name: 'Dunajská Streda TTT',
        stageType: StageType.teamTimeTrial,
        distanceKm: 28.8,
        startElevationM: 118.0,
        peakElevationM: 124.0,
        finishElevationM: 118.0,
        weather: WeatherCondition.sunny,
      ),
      _simpleStage(
        id: 'st_svk_2_$seasonYear',
        stageNumber: 2,
        name: 'Nitra – Hlohovec',
        stageType: StageType.hilly,
        distanceKm: 192.0,
        startElevationM: 145.0,
        peakElevationM: 465.0,
        finishElevationM: 156.0,
        weather: WeatherCondition.sunny,
      ),
      _simpleStage(
        id: 'st_svk_3_$seasonYear',
        stageNumber: 3,
        name: 'Piešťany – Dubnica nad Váhom',
        stageType: StageType.hilly,
        distanceKm: 161.0,
        startElevationM: 162.0,
        peakElevationM: 630.0,
        finishElevationM: 242.0,
        weather: WeatherCondition.overcast,
      ),
      _simpleStage(
        id: 'st_svk_4_$seasonYear',
        stageNumber: 4,
        name: 'Partizánske – Štrbské Pleso',
        stageType: StageType.summitFinish,
        distanceKm: 184.0,
        startElevationM: 195.0,
        peakElevationM: 1346.0,
        finishElevationM: 1346.0,
        weather: WeatherCondition.lightRain,
      ),
      _simpleStage(
        id: 'st_svk_5_$seasonYear',
        stageNumber: 5,
        name: 'Liptovský Mikuláš – Kohútka',
        stageType: StageType.summitFinish,
        distanceKm: 145.0,
        startElevationM: 577.0,
        peakElevationM: 913.0,
        finishElevationM: 913.0,
        weather: WeatherCondition.overcast,
      ),
    ];

    return TourRace(
      id: '${CentralEuropeRaceId.okoloSlovenska.baseId}_$seasonYear',
      name: 'Okolo Slovenska',
      countryIso: CentralEuropeCountry.slovakia.isoCode,
      uciCategory: RaceCategory.class1,
      startMonth: 6,
      startDay: 26,
      stages: List<RaceStage>.unmodifiable(stages),
      prizePoolEur: 135000,
      participatingTeamIds: List<String>.unmodifiable(teams),
      ridersPerTeam: 6,
      classifications: _emptyClassifications(),
    );
  }

  static TourRace _buildSilesiaBeskidyClassic(
    int seasonYear,
    List<String> teams,
  ) {
    final stage = RaceStage(
      id: 'st_silesia_classic_$seasonYear',
      stageNumber: 1,
      name: 'Bielsko-Biała – Szczyrk (Przełęcz Salmopolska)',
      stageType: StageType.hilly,
      baseTemperatureCelsius: 21.0,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 15.0,
      segments: _buildContinuousSegments(
        specs: const [
          _SegSpec(
            lengthKm: 42.0,
            endElevationM: 480.0,
            surface: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 36.0,
            windBearing: 240.0,
            roadBearing: 205.0,
            classification: SegmentClassification.intermediateSprint,
          ),
          _SegSpec(
            lengthKm: 34.0,
            endElevationM: 761.0,
            surface: SegmentSurfaceType.roughAsphalt,
            technicalDifficulty: 58.0,
            windBearing: 240.0,
            roadBearing: 135.0,
            classification: SegmentClassification.cat2,
          ),
          _SegSpec(
            lengthKm: 44.0,
            endElevationM: 520.0,
            surface: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 45.0,
            windBearing: 240.0,
            roadBearing: 75.0,
            classification: SegmentClassification.none,
          ),
          _SegSpec(
            lengthKm: 28.0,
            endElevationM: 934.0,
            surface: SegmentSurfaceType.roughAsphalt,
            technicalDifficulty: 70.0,
            windBearing: 240.0,
            roadBearing: 55.0,
            classification: SegmentClassification.cat1,
          ),
          _SegSpec(
            lengthKm: 24.5,
            endElevationM: 545.0,
            surface: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 55.0,
            windBearing: 240.0,
            roadBearing: 35.0,
            classification: SegmentClassification.finishLine,
          ),
        ],
        initialElevationM: 315.0,
      ),
    );

    return TourRace(
      id: '${CentralEuropeRaceId.silesiaBeskidyClassic.baseId}_$seasonYear',
      name: 'Silesia & Beskidy Classic',
      countryIso: CentralEuropeCountry.poland.isoCode,
      uciCategory: RaceCategory.class1,
      startMonth: 6,
      startDay: 15,
      stages: List<RaceStage>.unmodifiable([stage]),
      prizePoolEur: 65000,
      participatingTeamIds: List<String>.unmodifiable(teams),
      ridersPerTeam: 6,
      classifications: _emptyClassifications(),
    );
  }

  static RaceStage _simpleStage({
    required String id,
    required int stageNumber,
    required String name,
    required StageType stageType,
    required double distanceKm,
    required double startElevationM,
    required double peakElevationM,
    required double finishElevationM,
    required WeatherCondition weather,
    SegmentClassification finishClassification =
        SegmentClassification.finishLine,
  }) {
    final s1 = distanceKm * 0.35;
    final s2 = distanceKm * 0.35;
    final s3 = distanceKm - s1 - s2;
    return RaceStage(
      id: id,
      stageNumber: stageNumber,
      name: name,
      stageType: stageType,
      baseTemperatureCelsius: 22.0,
      weatherCondition: weather,
      windSpeedKmh: weather == WeatherCondition.crosswindGale ? 32.0 : 13.0,
      segments: _buildContinuousSegments(
        initialElevationM: startElevationM,
        specs: [
          _SegSpec(
            lengthKm: s1,
            endElevationM: (startElevationM + peakElevationM) * 0.5,
            surface: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 28.0,
            windBearing: 240.0,
            roadBearing: 110.0,
            classification: stageType == StageType.teamTimeTrial ||
                    stageType == StageType.individualTimeTrial
                ? SegmentClassification.none
                : SegmentClassification.intermediateSprint,
          ),
          _SegSpec(
            lengthKm: s2,
            endElevationM: peakElevationM,
            surface: peakElevationM > 900.0
                ? SegmentSurfaceType.roughAsphalt
                : SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: peakElevationM > 900.0 ? 60.0 : 35.0,
            windBearing: 240.0,
            roadBearing: 140.0,
            classification: peakElevationM > 900.0
                ? SegmentClassification.cat1
                : (peakElevationM > 400.0
                    ? SegmentClassification.cat3
                    : SegmentClassification.none),
          ),
          _SegSpec(
            lengthKm: s3,
            endElevationM: finishElevationM,
            surface: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty:
                stageType == StageType.summitFinish ? 64.0 : 32.0,
            windBearing: 240.0,
            roadBearing: 165.0,
            classification: finishClassification,
          ),
        ],
      ),
    );
  }

  static List<StageSegment> _buildContinuousSegments({
    required List<_SegSpec> specs,
    required double initialElevationM,
  }) {
    final List<StageSegment> result = [];
    double currentKm = 0.0;
    double currentAlt = initialElevationM;
    for (int i = 0; i < specs.length; i++) {
      final s = specs[i];
      result.add(
        StageSegment(
          index: i,
          startKm: currentKm,
          lengthKm: s.lengthKm,
          startElevationM: currentAlt,
          endElevationM: s.endElevationM,
          surfaceType: s.surface,
          technicalDifficulty: s.technicalDifficulty,
          windDirectionDegrees: s.windBearing,
          roadBearingDegrees: s.roadBearing,
          sprintOrKomClassification: s.classification,
        ),
      );
      currentKm += s.lengthKm;
      currentAlt = s.endElevationM;
    }
    return List<StageSegment>.unmodifiable(result);
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

  /// Filtruje specyfikacje wyścigów według kraju i zapytania tekstowego.
  static List<CentralEuropeRaceSpec> filterSpecs({
    CentralEuropeCountry? countryFilter,
    String query = '',
  }) {
    final trimmed = query.trim().toLowerCase();
    return allRaceSpecs.where((spec) {
      if (countryFilter != null && spec.country != countryFilter) {
        return false;
      }
      if (trimmed.isEmpty) return true;
      return spec.officialName.toLowerCase().contains(trimmed) ||
          spec.summary.toLowerCase().contains(trimmed) ||
          spec.country.polishName.toLowerCase().contains(trimmed) ||
          spec.landmarks.any((l) => l.name.toLowerCase().contains(trimmed));
    }).toList(growable: false);
  }
}

class _SegSpec {
  final double lengthKm;
  final double endElevationM;
  final SegmentSurfaceType surface;
  final double technicalDifficulty;
  final double windBearing;
  final double roadBearing;
  final SegmentClassification classification;

  const _SegSpec({
    required this.lengthKm,
    required this.endElevationM,
    required this.surface,
    required this.technicalDifficulty,
    required this.windBearing,
    required this.roadBearing,
    required this.classification,
  });
}

/// Stan widoku i aktywacji pakietu wyścigów Europy Środkowej w karierze.
class CentralEuropePackState {
  final int seasonYear;
  final CentralEuropeRaceId selectedRaceId;
  final int selectedStageIndex;
  final CentralEuropeCountry? countryFilter;
  final String searchQuery;
  final bool packEnabledInCareer;
  final List<TourRace> generatedRaces;
  final String statusMessage;

  const CentralEuropePackState({
    required this.seasonYear,
    required this.selectedRaceId,
    required this.selectedStageIndex,
    required this.countryFilter,
    required this.searchQuery,
    required this.packEnabledInCareer,
    required this.generatedRaces,
    required this.statusMessage,
  });

  factory CentralEuropePackState.initial({
    int seasonYear = 2026,
    List<String> defaultTeamIds = const [
      'team_player',
      'team_visma',
      'team_uae',
      'team_ineos',
      'team_bora',
      'team_alpecin',
      'team_lidl',
      'team_quickstep',
    ],
  }) {
    final races = TourDePologneAndCentralEuropePack.buildPack(
      seasonYear: seasonYear,
      participatingTeamIds: defaultTeamIds,
    );
    return CentralEuropePackState(
      seasonYear: seasonYear,
      selectedRaceId: CentralEuropeRaceId.tourDePologne,
      selectedStageIndex: 0,
      countryFilter: null,
      searchQuery: '',
      packEnabledInCareer: true,
      generatedRaces: races,
      statusMessage:
          'Pakiet Europy Środkowej aktywny (5 wyścigów, 7-etapowy Tour de Pologne).',
    );
  }

  CentralEuropeRaceSpec get selectedSpec =>
      TourDePologneAndCentralEuropePack.allRaceSpecs.firstWhere(
        (s) => s.raceId == selectedRaceId,
        orElse: () => TourDePologneAndCentralEuropePack.allRaceSpecs.first,
      );

  TourRace get selectedRace {
    return generatedRaces.firstWhere(
      (r) => r.id.startsWith(selectedRaceId.baseId),
      orElse: () => generatedRaces.first,
    );
  }

  RaceStage get selectedStage {
    final stages = selectedRace.stages;
    if (stages.isEmpty) {
      return const RaceStage(
        id: 'fallback',
        stageNumber: 1,
        name: 'Brak etapu',
        stageType: StageType.flat,
        segments: [],
        baseTemperatureCelsius: 20.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 10.0,
      );
    }
    final safeIdx = selectedStageIndex.clamp(0, stages.length - 1);
    return stages[safeIdx];
  }

  double get totalDistanceKm =>
      generatedRaces.fold<double>(0.0, (sum, r) => sum + r.totalRaceDistanceKm);

  int get totalStagesCount =>
      generatedRaces.fold<int>(0, (sum, r) => sum + r.stages.length);

  int get totalPrizePoolEur =>
      generatedRaces.fold<int>(0, (sum, r) => sum + r.prizePoolEur);

  CentralEuropePackState copyWith({
    int? seasonYear,
    CentralEuropeRaceId? selectedRaceId,
    int? selectedStageIndex,
    CentralEuropeCountry? countryFilter,
    bool clearCountryFilter = false,
    String? searchQuery,
    bool? packEnabledInCareer,
    List<TourRace>? generatedRaces,
    String? statusMessage,
  }) {
    return CentralEuropePackState(
      seasonYear: seasonYear ?? this.seasonYear,
      selectedRaceId: selectedRaceId ?? this.selectedRaceId,
      selectedStageIndex: selectedStageIndex ?? this.selectedStageIndex,
      countryFilter:
          clearCountryFilter ? null : (countryFilter ?? this.countryFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      packEnabledInCareer: packEnabledInCareer ?? this.packEnabledInCareer,
      generatedRaces: generatedRaces ?? this.generatedRaces,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

/// Kontroler Riverpod zarządzający pakietem wyścigów Europy Środkowej.
class CentralEuropePackNotifier extends StateNotifier<CentralEuropePackState> {
  CentralEuropePackNotifier() : super(CentralEuropePackState.initial());

  void selectRace(CentralEuropeRaceId id) {
    state = state.copyWith(
      selectedRaceId: id,
      selectedStageIndex: 0,
      statusMessage: 'Wybrano wyścig: ${id.displayName}.',
    );
  }

  void selectStage(int index) {
    final maxIdx = math.max(0, state.selectedRace.stages.length - 1);
    final clamped = index.clamp(0, maxIdx);
    state = state.copyWith(selectedStageIndex: clamped);
  }

  void setCountryFilter(CentralEuropeCountry? country) {
    if (country == null) {
      state = state.copyWith(clearCountryFilter: true);
    } else {
      state = state.copyWith(countryFilter: country);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void togglePackInCareer() {
    final next = !state.packEnabledInCareer;
    state = state.copyWith(
      packEnabledInCareer: next,
      statusMessage: next
          ? 'Pakiet Europy Środkowej włączony do kalendarza sezonu ${state.seasonYear}.'
          : 'Pakiet Europy Środkowej wyłączony z kalendarza sezonu ${state.seasonYear}.',
    );
  }

  void rebuildForSeason(
    int seasonYear, {
    List<String> participatingTeamIds = const [
      'team_player',
      'team_visma',
      'team_uae',
      'team_ineos',
      'team_bora',
      'team_alpecin',
      'team_lidl',
      'team_quickstep',
    ],
  }) {
    final races = TourDePologneAndCentralEuropePack.buildPack(
      seasonYear: seasonYear,
      participatingTeamIds: participatingTeamIds,
    );
    state = state.copyWith(
      seasonYear: seasonYear,
      generatedRaces: races,
      selectedStageIndex: 0,
      statusMessage: 'Wygenerowano pakiet Europy Środkowej na sezon $seasonYear.',
    );
  }
}

final centralEuropePackProvider = StateNotifierProvider<
    CentralEuropePackNotifier, CentralEuropePackState>(
  (ref) => CentralEuropePackNotifier(),
);

/// Responsywny panel prezentujący Pakiet Wyścigów Europy Środkowej i 7-etapowy Tour de Pologne.
class TourDePologneAndCentralEuropePackPanel extends ConsumerWidget {
  const TourDePologneAndCentralEuropePackPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(centralEuropePackProvider);
    final notifier = ref.read(centralEuropePackProvider.notifier);

    final filteredSpecs = TourDePologneAndCentralEuropePack.filterSpecs(
      countryFilter: state.countryFilter,
      query: state.searchQuery,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 1024.0;
        final isCompact = width < 720.0;
        final isWide = width >= 1150.0;

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(
                  state: state,
                  isCompact: isCompact,
                  onTogglePack: notifier.togglePackInCareer,
                ),
                const SizedBox(height: 16.0),
                _FilterBar(
                  countryFilter: state.countryFilter,
                  onSelectCountry: notifier.setCountryFilter,
                  onSearchChanged: notifier.setSearchQuery,
                ),
                const SizedBox(height: 16.0),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _RaceListSection(
                          specs: filteredSpecs,
                          selectedRaceId: state.selectedRaceId,
                          onSelectRace: notifier.selectRace,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        flex: 7,
                        child: _RaceDetailSection(
                          spec: state.selectedSpec,
                          race: state.selectedRace,
                          selectedStageIndex: state.selectedStageIndex,
                          selectedStage: state.selectedStage,
                          onSelectStage: notifier.selectStage,
                          isCompact: false,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _RaceListSection(
                    specs: filteredSpecs,
                    selectedRaceId: state.selectedRaceId,
                    onSelectRace: notifier.selectRace,
                  ),
                  const SizedBox(height: 16.0),
                  _RaceDetailSection(
                    spec: state.selectedSpec,
                    race: state.selectedRace,
                    selectedStageIndex: state.selectedStageIndex,
                    selectedStage: state.selectedStage,
                    onSelectStage: notifier.selectStage,
                    isCompact: isCompact,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final CentralEuropePackState state;
  final bool isCompact;
  final VoidCallback onTogglePack;

  const _HeaderCard({
    required this.state,
    required this.isCompact,
    required this.onTogglePack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact) ...[
            _HeaderTitleBlock(seasonYear: state.seasonYear),
            const SizedBox(height: 12.0),
            _InteractiveActionButton(
              label: state.packEnabledInCareer
                  ? 'Aktywny w kalendarzu'
                  : 'Włącz w kalendarzu',
              icon: state.packEnabledInCareer
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              isActive: state.packEnabledInCareer,
              accentColor: state.packEnabledInCareer
                  ? AppColors.statusSuccess
                  : AppColors.primaryAccent,
              onPressed: onTogglePack,
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _HeaderTitleBlock(seasonYear: state.seasonYear),
                ),
                const SizedBox(width: 12.0),
                _InteractiveActionButton(
                  label: state.packEnabledInCareer
                      ? 'Aktywny w kalendarzu'
                      : 'Włącz w kalendarzu',
                  icon: state.packEnabledInCareer
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  isActive: state.packEnabledInCareer,
                  accentColor: state.packEnabledInCareer
                      ? AppColors.statusSuccess
                      : AppColors.primaryAccent,
                  onPressed: onTogglePack,
                ),
              ],
            ),
          const SizedBox(height: 14.0),
          Wrap(
            spacing: 12.0,
            runSpacing: 10.0,
            children: [
              _KpiChip(
                label: 'Wyścigi',
                value: '${state.generatedRaces.length}',
                color: AppColors.goldAccent,
              ),
              _KpiChip(
                label: 'Etapy łącznie',
                value: '${state.totalStagesCount}',
                color: AppColors.accentBlue,
              ),
              _KpiChip(
                label: 'Dystans pakietu',
                value: '${state.totalDistanceKm.toStringAsFixed(1)} km',
                color: AppColors.cyanAccent,
              ),
              _KpiChip(
                label: 'Pula nagród',
                value: Formatters.formatCurrency(state.totalPrizePoolEur),
                color: AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderTitleBlock extends StatelessWidget {
  final int seasonYear;

  const _HeaderTitleBlock({required this.seasonYear});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flag_rounded,
              color: AppColors.goldAccent,
              size: 20.0,
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Text(
                'PAKIET EUROPY ŚRODKOWEJ • SEZON $seasonYear',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.goldAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        const Text(
          'Tour de Pologne & Central Europe Pack',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final CentralEuropeCountry? countryFilter;
  final ValueChanged<CentralEuropeCountry?> onSelectCountry;
  final ValueChanged<String> onSearchChanged;

  const _FilterBar({
    required this.countryFilter,
    required this.onSelectCountry,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterPill(
            label: 'Wszystkie kraje',
            selected: countryFilter == null,
            accentColor: AppColors.goldAccent,
            onTap: () => onSelectCountry(null),
          ),
          for (final country in CentralEuropeCountry.values)
            _FilterPill(
              label: '${country.shortCode} • ${country.polishName}',
              selected: countryFilter == country,
              accentColor: country.accentColor,
              onTap: () => onSelectCountry(country),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200.0, maxWidth: 280.0),
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.0,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Szukaj wyścigu lub podjazdu...',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18.0,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.goldAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaceListSection extends StatelessWidget {
  final List<CentralEuropeRaceSpec> specs;
  final CentralEuropeRaceId selectedRaceId;
  final ValueChanged<CentralEuropeRaceId> onSelectRace;

  const _RaceListSection({
    required this.specs,
    required this.selectedRaceId,
    required this.onSelectRace,
  });

  @override
  Widget build(BuildContext context) {
    if (specs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Text(
          'Brak wyścigów spełniających wybrane kryteria filtrowania.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.0,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < specs.length; i++) ...[
          _RaceSpecCard(
            spec: specs[i],
            isSelected: specs[i].raceId == selectedRaceId,
            onTap: () => onSelectRace(specs[i].raceId),
          ),
          if (i < specs.length - 1) const SizedBox(height: 10.0),
        ],
      ],
    );
  }
}

class _RaceSpecCard extends StatefulWidget {
  final CentralEuropeRaceSpec spec;
  final bool isSelected;
  final VoidCallback onTap;

  const _RaceSpecCard({
    required this.spec,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RaceSpecCard> createState() => _RaceSpecCardState();
}

class _RaceSpecCardState extends State<_RaceSpecCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.primaryAccent : AppColors.cardBorder));

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.99 : 1.0,
              _pressed ? 0.99 : 1.0,
              1.0,
            ),
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : (_hovered ? const Color(0xFF1D212A) : AppColors.surface),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: widget.spec.country.accentColor
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: widget.spec.country.accentColor
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        widget.spec.country.isoCode,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: widget.spec.country.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        widget.spec.categoryBadge,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.spec.stageCount} ${widget.spec.stageCount == 1 ? 'etap' : 'etapów'}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Text(
                  widget.spec.officialName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  widget.spec.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
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

class _RaceDetailSection extends StatelessWidget {
  final CentralEuropeRaceSpec spec;
  final TourRace race;
  final int selectedStageIndex;
  final RaceStage selectedStage;
  final ValueChanged<int> onSelectStage;
  final bool isCompact;

  const _RaceDetailSection({
    required this.spec,
    required this.race,
    required this.selectedStageIndex,
    required this.selectedStage,
    required this.onSelectStage,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14.0 : 18.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                race.name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${race.totalRaceDistanceKm.toStringAsFixed(1)} km • +${race.totalRaceElevationGainM.round()} m',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            spec.summary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14.0),
          const Text(
            'Kluczowe miejsca trasy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final landmark in spec.landmarks)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    '${landmark.name} (${landmark.elevationM} m • max ${landmark.maxGradientPercent.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Etapy wyścigu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (int i = 0; i < race.stages.length; i++)
                _FilterPill(
                  label: 'Etap ${race.stages[i].stageNumber}',
                  selected: i == selectedStageIndex,
                  accentColor: AppColors.primaryAccent,
                  onTap: () => onSelectStage(i),
                ),
            ],
          ),
          const SizedBox(height: 14.0),
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Etap ${selectedStage.stageNumber}: ${selectedStage.name}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6.0),
                Wrap(
                  spacing: 14.0,
                  runSpacing: 6.0,
                  children: [
                    Text(
                      'Dystans: ${selectedStage.totalDistanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Przewyższenie: +${selectedStage.totalElevationGainM.round()} m',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Szczyt: ${selectedStage.maxElevationM.round()} m n.p.m.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.0,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                SizedBox(
                  height: 96.0,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _StageElevationProfilePainter(
                      segments: selectedStage.segments,
                    ),
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

class _StageElevationProfilePainter extends CustomPainter {
  final List<StageSegment> segments;

  const _StageElevationProfilePainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || size.width <= 0 || size.height <= 0) return;

    double totalKm = 0.0;
    double minAlt = segments.first.startElevationM;
    double maxAlt = segments.first.startElevationM;
    for (final s in segments) {
      totalKm += s.lengthKm;
      minAlt = math.min(minAlt, math.min(s.startElevationM, s.endElevationM));
      maxAlt = math.max(maxAlt, math.max(s.startElevationM, s.endElevationM));
    }
    if (totalKm <= 0) return;
    final altSpan = math.max(50.0, maxAlt - minAlt);

    final path = Path();
    final fillPath = Path();

    double xOf(double km) => (km / totalKm) * size.width;
    double yOf(double alt) =>
        size.height - (((alt - minAlt) / altSpan) * (size.height - 16.0)) - 8.0;

    final startX = xOf(0.0);
    final startY = yOf(segments.first.startElevationM);
    path.moveTo(startX, startY);
    fillPath.moveTo(startX, size.height);
    fillPath.lineTo(startX, startY);

    double accKm = 0.0;
    for (final s in segments) {
      accKm += s.lengthKm;
      final px = xOf(accKm);
      final py = yOf(s.endElevationM);
      path.lineTo(px, py);
      fillPath.lineTo(px, py);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.35),
          AppColors.primaryAccent.withValues(alpha: 0.05),
        ],
      ).createShader(Offset.zero & size);

    final strokePaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _StageElevationProfilePainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
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
              fontSize: 11.0,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accentColor.withValues(alpha: 0.20)
                  : (_hovered ? AppColors.surfaceLight : AppColors.background),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: widget.selected
                    ? widget.accentColor
                    : (_focused ? AppColors.accentBlue : AppColors.cardBorder),
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: widget.selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.accentColor,
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
    final isDisabled = widget.onPressed == null;
    final bgColor = isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : widget.accentColor.withValues(
            alpha: _pressed ? 0.30 : (_hovered ? 0.24 : 0.16),
          );
    final borderColor = isDisabled
        ? AppColors.cardBorder
        : (_focused ? AppColors.accentBlue : widget.accentColor);

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor:
            isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: isDisabled
              ? null
              : (_) {
                  setState(() => _pressed = false);
                  widget.onPressed?.call();
                },
          onTapCancel:
              isDisabled ? null : () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16.0,
                  color: isDisabled
                      ? AppColors.textSecondary
                      : widget.accentColor,
                ),
                const SizedBox(width: 8.0),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
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
