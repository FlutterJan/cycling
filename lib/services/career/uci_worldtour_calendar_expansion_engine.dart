// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/season_calendar.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/race/tour_race.dart';
import '../generators/uci_calendar_generator.dart';

/// Region geograficzny ekspansji kalendarza UCI WorldTour.
enum ExpansionMarketRegion {
  asiaPacific('Azja i Pacyfik', 'APAC'),
  middleEast('Bliski Wschód', 'MENA'),
  americas('Ameryki', 'AMER'),
  africa('Afryka', 'AFR'),
  europeEmerging('Nowa Europa', 'EUR+'),
  oceania('Oceania', 'OCE');

  final String polishLabel;
  final String shortCode;

  const ExpansionMarketRegion(this.polishLabel, this.shortCode);

  String toJson() => name;

  static ExpansionMarketRegion fromJson(String value) {
    return ExpansionMarketRegion.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpansionMarketRegion.europeEmerging,
    );
  }

  Color get accentColor {
    switch (this) {
      case ExpansionMarketRegion.asiaPacific:
        return AppColors.cyanAccent;
      case ExpansionMarketRegion.middleEast:
        return AppColors.goldAccent;
      case ExpansionMarketRegion.americas:
        return AppColors.accentBlue;
      case ExpansionMarketRegion.africa:
        return AppColors.statusSuccess;
      case ExpansionMarketRegion.europeEmerging:
        return AppColors.primaryAccent;
      case ExpansionMarketRegion.oceania:
        return AppColors.amberWarning;
    }
  }
}

/// Rodzaj operacji rozbudowy lub rotacji w kalendarzu UCI WorldTour.
enum CalendarExpansionActionType {
  newWorldTourOneDay('Nowy klasyk WorldTour'),
  newWorldTourStageRace('Nowa etapówka WorldTour'),
  promotionFromProSeries('Awans z ProSeries do WT'),
  biAnnualRotationSwap('Rotacja dwuletnia UCI'),
  grandTourGrandePartenzaAbroad('Zagraniczny Grande Partenza'),
  relegationToProSeries('Spadek do ProSeries');

  final String polishLabel;

  const CalendarExpansionActionType(this.polishLabel);

  String toJson() => name;

  static CalendarExpansionActionType fromJson(String value) {
    return CalendarExpansionActionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CalendarExpansionActionType.newWorldTourOneDay,
    );
  }
}

/// Status kandydata do ekspansji kalendarza WorldTour.
enum CalendarExpansionStatus {
  proposed('Propozycja UCI'),
  approved('Zatwierdzony'),
  activeInCalendar('Aktywny w kalendarzu'),
  rotatedOut('W rotacji poza sezonem'),
  rejected('Odrzucony');

  final String polishLabel;

  const CalendarExpansionStatus(this.polishLabel);

  String toJson() => name;

  static CalendarExpansionStatus fromJson(String value) {
    return CalendarExpansionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CalendarExpansionStatus.proposed,
    );
  }

  Color get badgeColor {
    switch (this) {
      case CalendarExpansionStatus.proposed:
        return AppColors.amberWarning;
      case CalendarExpansionStatus.approved:
        return AppColors.accentBlue;
      case CalendarExpansionStatus.activeInCalendar:
        return AppColors.statusSuccess;
      case CalendarExpansionStatus.rotatedOut:
        return AppColors.textSecondary;
      case CalendarExpansionStatus.rejected:
        return AppColors.crimsonAlert;
    }
  }
}

/// Specyfikacja nowego lub awansowanego wyścigu w procesie ekspansji WorldTour.
class WorldTourExpansionCandidate {
  final String id;
  final String name;
  final String countryIso;
  final String hostCityName;
  final ExpansionMarketRegion region;
  final CalendarExpansionActionType actionType;
  final RaceCategory targetCategory;
  final int startMonth;
  final int startDay;
  final int stageCount;
  final StageType primaryTerrain;
  final int prizePoolEur;
  final double uciPointsWeight;
  final int broadcastAppealScore;
  final int minimumSeasonYear;
  final double travelFatigueFactor;
  final int ridersPerTeam;
  final String description;
  final String? replacesRaceId;

  const WorldTourExpansionCandidate({
    required this.id,
    required this.name,
    required this.countryIso,
    required this.hostCityName,
    required this.region,
    required this.actionType,
    required this.targetCategory,
    required this.startMonth,
    required this.startDay,
    required this.stageCount,
    required this.primaryTerrain,
    required this.prizePoolEur,
    required this.uciPointsWeight,
    required this.broadcastAppealScore,
    required this.minimumSeasonYear,
    required this.travelFatigueFactor,
    required this.ridersPerTeam,
    required this.description,
    this.replacesRaceId,
  });

  /// Buduje pełny obiekt [TourRace] z realistycznymi etapami i segmentami dla danego roku.
  TourRace buildTourRace({
    required int seasonYear,
    List<String> participatingTeamIds = const [],
  }) {
    final List<RaceStage> stages = [];
    final int clampedCount = math.max(1, stageCount);

    for (int i = 0; i < clampedCount; i++) {
      final int stageNumber = i + 1;
      final StageType stageType = _resolveStageTypeForIndex(i, clampedCount);
      final double distanceKm = _resolveStageDistanceKm(stageType, stageNumber);
      final List<StageSegment> segments = _buildSegmentsForStage(
        stageNumber: stageNumber,
        stageType: stageType,
        distanceKm: distanceKm,
        seasonYear: seasonYear,
      );

      stages.add(
        RaceStage(
          id: '${id}_${seasonYear}_s$stageNumber',
          stageNumber: stageNumber,
          name: clampedCount == 1
              ? name
              : '$hostCityName — Etap $stageNumber',
          stageType: stageType,
          segments: segments,
          baseTemperatureCelsius: _resolveBaseTempCelsius(),
          weatherCondition: _resolveWeatherCondition(seasonYear, stageNumber),
          windSpeedKmh: _resolveWindSpeed(seasonYear, stageNumber),
        ),
      );
    }

    final int yearDelta = math.max(0, seasonYear - 2026);
    final int indexedPrizePool =
        (prizePoolEur * (1.0 + yearDelta * 0.025)).round();

    return TourRace(
      id: '${id}_$seasonYear',
      name: name,
      countryIso: countryIso,
      uciCategory: targetCategory,
      startMonth: startMonth,
      startDay: startDay,
      stages: stages,
      prizePoolEur: indexedPrizePool,
      participatingTeamIds: List<String>.from(participatingTeamIds),
      ridersPerTeam: ridersPerTeam,
      classifications: const RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );
  }

  StageType _resolveStageTypeForIndex(int index, int total) {
    if (total == 1) return primaryTerrain;
    if (index == 0 && total >= 5) return StageType.individualTimeTrial;
    if (index == total - 1) return StageType.flat;
    if (index == (total * 0.65).floor()) return primaryTerrain;
    if (index % 2 == 1) return StageType.hilly;
    return primaryTerrain;
  }

  double _resolveStageDistanceKm(StageType type, int stageNumber) {
    switch (type) {
      case StageType.individualTimeTrial:
        return 18.5 + (stageNumber % 3) * 4.0;
      case StageType.teamTimeTrial:
        return 26.0;
      case StageType.cobbleClassic:
        return 218.0;
      case StageType.highMountain:
      case StageType.summitFinish:
        return 162.0 + (stageNumber % 4) * 9.0;
      case StageType.hilly:
        return 178.0 + (stageNumber % 3) * 8.0;
      case StageType.flat:
        return 192.0 + (stageNumber % 4) * 7.0;
    }
  }

  List<StageSegment> _buildSegmentsForStage({
    required int stageNumber,
    required StageType stageType,
    required double distanceKm,
    required int seasonYear,
  }) {
    final int segmentCount = math.max(4, (distanceKm / 30.0).round());
    final double segLen = distanceKm / segmentCount;
    final List<StageSegment> segments = [];
    double currentElev = region == ExpansionMarketRegion.africa ? 1450.0 : 85.0;
    final int seed = seasonYear * 31 + stageNumber * 17 + id.hashCode;

    for (int i = 0; i < segmentCount; i++) {
      final double startKm = i * segLen;
      double elevDelta = 0.0;
      SegmentSurfaceType surface = SegmentSurfaceType.smoothAsphalt;
      SegmentClassification classification = SegmentClassification.none;
      double techDifficulty = 22.0 + ((seed + i * 7) % 28);

      if (stageType == StageType.highMountain ||
          stageType == StageType.summitFinish) {
        if (i >= segmentCount - 2) {
          elevDelta = 420.0 + ((seed + i * 13) % 240);
          classification = i == segmentCount - 1
              ? SegmentClassification.horsCategorie
              : SegmentClassification.cat1;
          techDifficulty = 62.0;
        } else if (i % 2 == 1) {
          elevDelta = 180.0;
          classification = SegmentClassification.cat3;
        } else {
          elevDelta = -95.0;
        }
      } else if (stageType == StageType.hilly) {
        elevDelta = (i % 2 == 0) ? 115.0 : -75.0;
        if (i == segmentCount - 1) {
          classification = SegmentClassification.cat3;
        }
      } else if (stageType == StageType.cobbleClassic) {
        elevDelta = (i % 2 == 0) ? 25.0 : -18.0;
        if (i >= 1 && i <= segmentCount - 2) {
          surface = i % 2 == 0
              ? SegmentSurfaceType.cobblestonesSector4
              : SegmentSurfaceType.cobblestonesSector3;
          techDifficulty = 78.0;
        }
      } else {
        elevDelta = (i % 2 == 0) ? 16.0 : -14.0;
        if (i == (segmentCount / 2).floor()) {
          classification = SegmentClassification.intermediateSprint;
        }
      }

      if (i == segmentCount - 1 &&
          classification == SegmentClassification.none) {
        classification = SegmentClassification.finishLine;
      }

      final double nextElev = math.max(10.0, currentElev + elevDelta);
      segments.add(
        StageSegment(
          index: i,
          startKm: startKm,
          lengthKm: segLen,
          startElevationM: currentElev,
          endElevationM: nextElev,
          surfaceType: surface,
          technicalDifficulty: techDifficulty,
          windDirectionDegrees: ((seed + i * 45) % 360).toDouble(),
          roadBearingDegrees: ((seed + i * 25) % 360).toDouble(),
          sprintOrKomClassification: classification,
        ),
      );
      currentElev = nextElev;
    }
    return segments;
  }

  double _resolveBaseTempCelsius() {
    switch (region) {
      case ExpansionMarketRegion.middleEast:
        return 31.0;
      case ExpansionMarketRegion.asiaPacific:
        return 24.5;
      case ExpansionMarketRegion.africa:
        return 22.0;
      case ExpansionMarketRegion.americas:
        return 21.0;
      case ExpansionMarketRegion.oceania:
        return 26.0;
      case ExpansionMarketRegion.europeEmerging:
        return 17.5;
    }
  }

  WeatherCondition _resolveWeatherCondition(int year, int stageNumber) {
    final int roll = (year + stageNumber + id.length) % 6;
    if (region == ExpansionMarketRegion.middleEast) {
      return roll == 0
          ? WeatherCondition.crosswindGale
          : WeatherCondition.extremeHeat;
    }
    switch (roll) {
      case 0:
        return WeatherCondition.overcast;
      case 1:
        return WeatherCondition.lightRain;
      case 2:
        return WeatherCondition.crosswindGale;
      default:
        return WeatherCondition.sunny;
    }
  }

  double _resolveWindSpeed(int year, int stageNumber) {
    final int base = region == ExpansionMarketRegion.middleEast ? 26 : 14;
    return (base + ((year * 7 + stageNumber * 5) % 18)).toDouble();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'countryIso': countryIso,
        'hostCityName': hostCityName,
        'region': region.toJson(),
        'actionType': actionType.toJson(),
        'targetCategory': targetCategory.toJson(),
        'startMonth': startMonth,
        'startDay': startDay,
        'stageCount': stageCount,
        'primaryTerrain': primaryTerrain.toJson(),
        'prizePoolEur': prizePoolEur,
        'uciPointsWeight': uciPointsWeight,
        'broadcastAppealScore': broadcastAppealScore,
        'minimumSeasonYear': minimumSeasonYear,
        'travelFatigueFactor': travelFatigueFactor,
        'ridersPerTeam': ridersPerTeam,
        'description': description,
        'replacesRaceId': replacesRaceId,
      };

  factory WorldTourExpansionCandidate.fromJson(Map<String, dynamic> json) {
    return WorldTourExpansionCandidate(
      id: json['id'] as String,
      name: json['name'] as String,
      countryIso: json['countryIso'] as String,
      hostCityName: json['hostCityName'] as String,
      region: ExpansionMarketRegion.fromJson(json['region'] as String),
      actionType:
          CalendarExpansionActionType.fromJson(json['actionType'] as String),
      targetCategory:
          RaceCategory.fromJson(json['targetCategory'] as String),
      startMonth: (json['startMonth'] as num).toInt(),
      startDay: (json['startDay'] as num).toInt(),
      stageCount: (json['stageCount'] as num).toInt(),
      primaryTerrain: StageType.fromJson(json['primaryTerrain'] as String),
      prizePoolEur: (json['prizePoolEur'] as num).toInt(),
      uciPointsWeight: (json['uciPointsWeight'] as num).toDouble(),
      broadcastAppealScore: (json['broadcastAppealScore'] as num).toInt(),
      minimumSeasonYear: (json['minimumSeasonYear'] as num).toInt(),
      travelFatigueFactor: (json['travelFatigueFactor'] as num).toDouble(),
      ridersPerTeam: (json['ridersPerTeam'] as num).toInt(),
      description: json['description'] as String,
      replacesRaceId: json['replacesRaceId'] as String?,
    );
  }
}

/// Zapis pojedynczej decyzji UCI o rozbudowie lub rotacji kalendarza w danym sezonie.
class CalendarExpansionDecisionRecord {
  final String candidateId;
  final String raceName;
  final int seasonYear;
  final CalendarExpansionActionType actionType;
  final CalendarExpansionStatus status;
  final ExpansionMarketRegion region;
  final int raceDaysDelta;
  final int prizePoolDeltaEur;
  final String rationale;

  const CalendarExpansionDecisionRecord({
    required this.candidateId,
    required this.raceName,
    required this.seasonYear,
    required this.actionType,
    required this.status,
    required this.region,
    required this.raceDaysDelta,
    required this.prizePoolDeltaEur,
    required this.rationale,
  });

  Map<String, dynamic> toJson() => {
        'candidateId': candidateId,
        'raceName': raceName,
        'seasonYear': seasonYear,
        'actionType': actionType.toJson(),
        'status': status.toJson(),
        'region': region.toJson(),
        'raceDaysDelta': raceDaysDelta,
        'prizePoolDeltaEur': prizePoolDeltaEur,
        'rationale': rationale,
      };

  factory CalendarExpansionDecisionRecord.fromJson(Map<String, dynamic> json) {
    return CalendarExpansionDecisionRecord(
      candidateId: json['candidateId'] as String,
      raceName: json['raceName'] as String,
      seasonYear: (json['seasonYear'] as num).toInt(),
      actionType:
          CalendarExpansionActionType.fromJson(json['actionType'] as String),
      status: CalendarExpansionStatus.fromJson(json['status'] as String),
      region: ExpansionMarketRegion.fromJson(json['region'] as String),
      raceDaysDelta: (json['raceDaysDelta'] as num).toInt(),
      prizePoolDeltaEur: (json['prizePoolDeltaEur'] as num).toInt(),
      rationale: json['rationale'] as String,
    );
  }
}

/// Audyt obciążenia kalendarza (liczba dni wyścigowych w miesiącach oraz wskaźnik zagęszczenia).
class CalendarCongestionAudit {
  final int totalRaceDays;
  final int maxRaceDaysCap;
  final Map<int, int> raceDaysByMonth;
  final int peakMonth;
  final int peakMonthDays;
  final double congestionRatio;
  final bool exceedsCap;

  const CalendarCongestionAudit({
    required this.totalRaceDays,
    required this.maxRaceDaysCap,
    required this.raceDaysByMonth,
    required this.peakMonth,
    required this.peakMonthDays,
    required this.congestionRatio,
    required this.exceedsCap,
  });

  Map<String, dynamic> toJson() => {
        'totalRaceDays': totalRaceDays,
        'maxRaceDaysCap': maxRaceDaysCap,
        'raceDaysByMonth':
            raceDaysByMonth.map((k, v) => MapEntry(k.toString(), v)),
        'peakMonth': peakMonth,
        'peakMonthDays': peakMonthDays,
        'congestionRatio': congestionRatio,
        'exceedsCap': exceedsCap,
      };

  factory CalendarCongestionAudit.fromJson(Map<String, dynamic> json) {
    final rawMap = json['raceDaysByMonth'] as Map<String, dynamic>? ?? {};
    return CalendarCongestionAudit(
      totalRaceDays: (json['totalRaceDays'] as num).toInt(),
      maxRaceDaysCap: (json['maxRaceDaysCap'] as num).toInt(),
      raceDaysByMonth: rawMap.map(
        (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
      ),
      peakMonth: (json['peakMonth'] as num).toInt(),
      peakMonthDays: (json['peakMonthDays'] as num).toInt(),
      congestionRatio: (json['congestionRatio'] as num).toDouble(),
      exceedsCap: json['exceedsCap'] as bool,
    );
  }
}

/// Rotacja zagranicznych startów Wielkich Tourów (Grande Partenza / Grand Départ) w danym roku.
class GrandTourGrandePartenzaSpec {
  final int seasonYear;
  final String giroStartCity;
  final String tourStartCity;
  final String vueltaStartCity;

  const GrandTourGrandePartenzaSpec({
    required this.seasonYear,
    required this.giroStartCity,
    required this.tourStartCity,
    required this.vueltaStartCity,
  });

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'giroStartCity': giroStartCity,
        'tourStartCity': tourStartCity,
        'vueltaStartCity': vueltaStartCity,
      };

  factory GrandTourGrandePartenzaSpec.fromJson(Map<String, dynamic> json) {
    return GrandTourGrandePartenzaSpec(
      seasonYear: (json['seasonYear'] as num).toInt(),
      giroStartCity: json['giroStartCity'] as String,
      tourStartCity: json['tourStartCity'] as String,
      vueltaStartCity: json['vueltaStartCity'] as String,
    );
  }
}

/// Pełne podsumowanie rozbudowy kalendarza WorldTour dla pojedynczego sezonu kariery.
class SeasonCalendarExpansionSummary {
  final int seasonYear;
  final int baseRaceCount;
  final int expandedRaceCount;
  final int totalRaceDays;
  final int totalPrizePoolEur;
  final double globalReachIndex;
  final CalendarCongestionAudit congestionAudit;
  final GrandTourGrandePartenzaSpec grandePartenza;
  final List<WorldTourExpansionCandidate> activeExpansions;
  final List<CalendarExpansionDecisionRecord> decisions;
  final List<TourRace> expandedRaces;

  const SeasonCalendarExpansionSummary({
    required this.seasonYear,
    required this.baseRaceCount,
    required this.expandedRaceCount,
    required this.totalRaceDays,
    required this.totalPrizePoolEur,
    required this.globalReachIndex,
    required this.congestionAudit,
    required this.grandePartenza,
    required this.activeExpansions,
    required this.decisions,
    required this.expandedRaces,
  });

  SeasonCalendar toSeasonCalendar() {
    return SeasonCalendar(
      seasonYear: seasonYear,
      races: expandedRaces,
    );
  }
}

/// Główny silnik dynamicznej rozbudowy kalendarza WorldTour w kolejnych latach kariery.
class UciWorldtourCalendarExpansionEngine {
  UciWorldtourCalendarExpansionEngine._();

  static const int defaultMaxRaceDaysCap = 195;

  static const List<String> _giroPartenzaCities = [
    'Tirana (Albania)',
    'Jerozolima (Izrael)',
    'Budapeszt (Węgry)',
    'Kraków (Polska)',
    'Ateny (Grecja)',
    'Dubaj (ZEA)',
  ];

  static const List<String> _tourDepartCities = [
    'Barcelona (Hiszpania)',
    'Edynburg (Wielka Brytania)',
    'Florencja (Włochy)',
    'Kopenhaga (Dania)',
    'Praga (Czechy)',
    'Bruksela (Belgia)',
  ];

  static const List<String> _vueltaSalidaCities = [
    'Lizbona (Portugalia)',
    'Turyn (Włochy)',
    'Utrecht (Holandia)',
    'Monako (Monako)',
    'Casablanca (Maroko)',
    'Andora (Andora)',
  ];

  /// Pełny katalog kandydatów ekspansji UCI WorldTour na lata 2026–2035+.
  static List<WorldTourExpansionCandidate> fullExpansionCatalog() {
    return const [
      WorldTourExpansionCandidate(
        id: 'wt_exp_saudi_red_sea',
        name: 'Tour of Saudi Red Sea',
        countryIso: 'KSA',
        hostCityName: 'AlUla',
        region: ExpansionMarketRegion.middleEast,
        actionType: CalendarExpansionActionType.promotionFromProSeries,
        targetCategory: RaceCategory.worldTourStageRace,
        startMonth: 2,
        startDay: 11,
        stageCount: 5,
        primaryTerrain: StageType.flat,
        prizePoolEur: 420000,
        uciPointsWeight: 1.0,
        broadcastAppealScore: 76,
        minimumSeasonYear: 2027,
        travelFatigueFactor: 1.15,
        ridersPerTeam: 7,
        description:
            'Awans pustynnego wyścigu w AlUla do rangi WorldTour z echelonami i krótkimi ściankami.',
      ),
      WorldTourExpansionCandidate(
        id: 'wt_exp_colombia_oro',
        name: 'Colombia Oro y Paz WorldTour',
        countryIso: 'COL',
        hostCityName: 'Medellín',
        region: ExpansionMarketRegion.americas,
        actionType: CalendarExpansionActionType.newWorldTourStageRace,
        targetCategory: RaceCategory.worldTourStageRace,
        startMonth: 2,
        startDay: 20,
        stageCount: 6,
        primaryTerrain: StageType.highMountain,
        prizePoolEur: 510000,
        uciPointsWeight: 1.15,
        broadcastAppealScore: 84,
        minimumSeasonYear: 2027,
        travelFatigueFactor: 1.30,
        ridersPerTeam: 7,
        description:
            'Wysokogórska etapówka w Andach (2100–2800 m n.p.m.) przyciągająca liderów GC.',
      ),
      WorldTourExpansionCandidate(
        id: 'wt_exp_norway_arctic',
        name: 'Arctic Race of Norway WT',
        countryIso: 'NOR',
        hostCityName: 'Tromsø',
        region: ExpansionMarketRegion.europeEmerging,
        actionType: CalendarExpansionActionType.promotionFromProSeries,
        targetCategory: RaceCategory.worldTourStageRace,
        startMonth: 8,
        startDay: 14,
        stageCount: 4,
        primaryTerrain: StageType.hilly,
        prizePoolEur: 380000,
        uciPointsWeight: 0.95,
        broadcastAppealScore: 79,
        minimumSeasonYear: 2028,
        travelFatigueFactor: 1.10,
        ridersPerTeam: 7,
        description:
            'Skandynawska etapówka za kołem podbiegunowym z fiordami, wiatrem i technicznymi podjazdami.',
      ),
      WorldTourExpansionCandidate(
        id: 'wt_exp_rwanda_highlands',
        name: 'Tour of Rwanda Highlands',
        countryIso: 'RWA',
        hostCityName: 'Kigali',
        region: ExpansionMarketRegion.africa,
        actionType: CalendarExpansionActionType.newWorldTourStageRace,
        targetCategory: RaceCategory.worldTourStageRace,
        startMonth: 3,
        startDay: 1,
        stageCount: 5,
        primaryTerrain: StageType.hilly,
        prizePoolEur: 360000,
        uciPointsWeight: 1.0,
        broadcastAppealScore: 82,
        minimumSeasonYear: 2028,
        travelFatigueFactor: 1.25,
        ridersPerTeam: 7,
        description:
            'Pierwszy afrykański wyścig WorldTour po mistrzowskich brukach i wzgórzach Kigali.',
      ),
      WorldTourExpansionCandidate(
        id: 'wt_exp_tokyo_imperial',
        name: 'Grand Prix Tokyo Imperial',
        countryIso: 'JPN',
        hostCityName: 'Tokio',
        region: ExpansionMarketRegion.asiaPacific,
        actionType: CalendarExpansionActionType.newWorldTourOneDay,
        targetCategory: RaceCategory.worldTourOneDay,
        startMonth: 10,
        startDay: 18,
        stageCount: 1,
        primaryTerrain: StageType.hilly,
        prizePoolEur: 310000,
        uciPointsWeight: 1.10,
        broadcastAppealScore: 88,
        minimumSeasonYear: 2027,
        travelFatigueFactor: 1.35,
        ridersPerTeam: 7,
        description:
            'Jesienny klasyk kończący azjatycką trasę z podjazdem pod okolice góry Fuji.',
      ),
      WorldTourExpansionCandidate(
        id: 'wt_exp_california_revival',
        name: 'Tour of California Revival',
        countryIso: 'USA',
        hostCityName: 'San Francisco',
        region: ExpansionMarketRegion.americas,
        actionType: CalendarExpansionActionType.newWorldTourStageRace,
        targetCategory: RaceCategory.worldTourStageRace,
        startMonth: 5,
        startDay: 12,
        stageCount: 6,
        primaryTerrain: StageType.summitFinish,
        prizePoolEur: 580000,
        uciPointsWeight: 1.15,
        broadcastAppealScore: 86,
        minimumSeasonYear: 2029,
        travelFatigueFactor: 1.35,
        ridersPerTeam: 7,
        description:
            'Wielki powrót wyścigu przez Mt. Baldy i Big Sur jako alternatywa dla Giro.',
      ),
      WorldTourExpansionCandidate(
        id: 'wt_exp_singapore_marina',
        name: 'Singapore Marina Bay Classic',
        countryIso: 'SGP',
        hostCityName: 'Singapur',
        region: ExpansionMarketRegion.asiaPacific,
        actionType: CalendarExpansionActionType.newWorldTourOneDay,
        targetCategory: RaceCategory.worldTourOneDay,
        startMonth: 10,
        startDay: 24,
        stageCount: 1,
        primaryTerrain: StageType.flat,
        prizePoolEur: 295000,
        uciPointsWeight: 0.90,
        broadcastAppealScore: 81,
        minimumSeasonYear: 2029,
        travelFatigueFactor: 1.30,
        ridersPerTeam: 7,
        description:
            'Nocny wyścig sprinterski przy sztucznym oświetleniu wokół Marina Bay.',
      ),
      WorldTourExpansionCandidate(
        id: 'wt_exp_cape_town',
        name: 'Cape Town Table Mountain Classic',
        countryIso: 'RSA',
        hostCityName: 'Kapsztad',
        region: ExpansionMarketRegion.africa,
        actionType: CalendarExpansionActionType.newWorldTourOneDay,
        targetCategory: RaceCategory.worldTourOneDay,
        startMonth: 1,
        startDay: 28,
        stageCount: 1,
        primaryTerrain: StageType.hilly,
        prizePoolEur: 285000,
        uciPointsWeight: 0.95,
        broadcastAppealScore: 80,
        minimumSeasonYear: 2030,
        travelFatigueFactor: 1.30,
        ridersPerTeam: 7,
        description:
            'Otwarcie sezonu na Przylądku Dobrej Nadziei z wiatrami znad oceanu.',
      ),
      WorldTourExpansionCandidate(
        id: 'wt_exp_cadel_oceania',
        name: 'Great Ocean Road Classic WT',
        countryIso: 'AUS',
        hostCityName: 'Geelong',
        region: ExpansionMarketRegion.oceania,
        actionType: CalendarExpansionActionType.biAnnualRotationSwap,
        targetCategory: RaceCategory.worldTourOneDay,
        startMonth: 1,
        startDay: 25,
        stageCount: 1,
        primaryTerrain: StageType.hilly,
        prizePoolEur: 270000,
        uciPointsWeight: 0.95,
        broadcastAppealScore: 77,
        minimumSeasonYear: 2027,
        travelFatigueFactor: 1.40,
        ridersPerTeam: 7,
        description:
            'Klasyk w Australii po Southern Tour z podjazdem Challambra Crescent.',
      ),
    ];
  }

  /// Zwraca kandydatów dostępnych do rozważenia dla zadanego roku kariery.
  static List<WorldTourExpansionCandidate> catalogForSeason(int seasonYear) {
    return fullExpansionCatalog()
        .where((c) => c.minimumSeasonYear <= seasonYear)
        .toList(growable: false);
  }

  /// Wyznacza miasta startowe Wielkich Tourów dla danego roku kariery.
  static GrandTourGrandePartenzaSpec resolveGrandePartenza(int seasonYear) {
    final int offset = math.max(0, seasonYear - 2026);
    return GrandTourGrandePartenzaSpec(
      seasonYear: seasonYear,
      giroStartCity: _giroPartenzaCities[offset % _giroPartenzaCities.length],
      tourStartCity: _tourDepartCities[offset % _tourDepartCities.length],
      vueltaStartCity:
          _vueltaSalidaCities[offset % _vueltaSalidaCities.length],
    );
  }

  /// Audytuje zagęszczenie dni wyścigowych w przekazanym zestawie wyścigów.
  static CalendarCongestionAudit auditCalendarCongestion(
    List<TourRace> races, {
    int maxRaceDaysCap = defaultMaxRaceDaysCap,
  }) {
    final Map<int, int> byMonth = {
      for (int m = 1; m <= 12; m++) m: 0,
    };
    int totalDays = 0;

    for (final race in races) {
      final int days = math.max(1, race.stages.length);
      totalDays += days;
      final int month = race.startMonth.clamp(1, 12);
      byMonth[month] = (byMonth[month] ?? 0) + days;
    }

    int peakMonth = 1;
    int peakDays = 0;
    byMonth.forEach((month, days) {
      if (days > peakDays) {
        peakDays = days;
        peakMonth = month;
      }
    });

    final int safeCap = math.max(1, maxRaceDaysCap);
    final double ratio = totalDays / safeCap;

    return CalendarCongestionAudit(
      totalRaceDays: totalDays,
      maxRaceDaysCap: safeCap,
      raceDaysByMonth: byMonth,
      peakMonth: peakMonth,
      peakMonthDays: peakDays,
      congestionRatio: ratio,
      exceedsCap: totalDays > safeCap,
    );
  }

  /// Rozbudowuje kalendarz WorldTour dla wskazanego roku kariery z zachowaniem limitu dni i sortowania.
  static SeasonCalendarExpansionSummary expandCalendarForSeason({
    required int seasonYear,
    List<TourRace>? baseRaces,
    List<String> participatingTeamIds = const [],
    int maxRaceDaysCap = defaultMaxRaceDaysCap,
    Set<String> approvedCandidateIds = const {},
    Set<String> rejectedCandidateIds = const {},
    bool autoApproveEligible = true,
  }) {
    final List<TourRace> resolvedBase = List<TourRace>.from(
      baseRaces ??
          UciCalendarGenerator.generateFullSeasonCalendar(
            seasonYear: seasonYear,
            participatingTeamIds: participatingTeamIds,
          ),
    );

    final int baseCount = resolvedBase.length;
    int currentRaceDays = resolvedBase.fold<int>(
      0,
      (sum, r) => sum + math.max(1, r.stages.length),
    );

    final List<WorldTourExpansionCandidate> eligible =
        catalogForSeason(seasonYear);
    final List<WorldTourExpansionCandidate> activeExpansions = [];
    final List<CalendarExpansionDecisionRecord> decisions = [];
    final List<TourRace> expandedRaces = List<TourRace>.from(resolvedBase);

    for (final candidate in eligible) {
      if (rejectedCandidateIds.contains(candidate.id)) {
        decisions.add(
          CalendarExpansionDecisionRecord(
            candidateId: candidate.id,
            raceName: candidate.name,
            seasonYear: seasonYear,
            actionType: candidate.actionType,
            status: CalendarExpansionStatus.rejected,
            region: candidate.region,
            raceDaysDelta: 0,
            prizePoolDeltaEur: 0,
            rationale: 'Odrzucone w głosowaniu Rady UCI / kalendarza.',
          ),
        );
        continue;
      }

      final bool isExplicitlyApproved =
          approvedCandidateIds.contains(candidate.id);
      if (!isExplicitlyApproved && !autoApproveEligible) {
        decisions.add(
          CalendarExpansionDecisionRecord(
            candidateId: candidate.id,
            raceName: candidate.name,
            seasonYear: seasonYear,
            actionType: candidate.actionType,
            status: CalendarExpansionStatus.proposed,
            region: candidate.region,
            raceDaysDelta: candidate.stageCount,
            prizePoolDeltaEur: candidate.prizePoolEur,
            rationale: 'Oczekuje na zatwierdzenie zarządu WorldTour.',
          ),
        );
        continue;
      }

      // Sprawdzenie rotacji dwuletniej (w nieparzystych/parzystych latach)
      if (candidate.actionType ==
              CalendarExpansionActionType.biAnnualRotationSwap &&
          !isExplicitlyApproved &&
          seasonYear % 2 == 0) {
        decisions.add(
          CalendarExpansionDecisionRecord(
            candidateId: candidate.id,
            raceName: candidate.name,
            seasonYear: seasonYear,
            actionType: candidate.actionType,
            status: CalendarExpansionStatus.rotatedOut,
            region: candidate.region,
            raceDaysDelta: 0,
            prizePoolDeltaEur: 0,
            rationale:
                'Pauza w ramach dwuletniej rotacji kalendarza międzykontynentalnego.',
          ),
        );
        continue;
      }

      final int candidateDays = math.max(1, candidate.stageCount);
      if (currentRaceDays + candidateDays > maxRaceDaysCap) {
        // Próba rotacji jednego starszego wyścigu niższej rangi jeśli mieści się w limicie po zamianie
        final int swapIndex = _findRotatableRaceIndex(
          expandedRaces,
          minRemovedDays: (currentRaceDays + candidateDays) - maxRaceDaysCap,
        );
        if (swapIndex != -1 && candidate.broadcastAppealScore >= 82) {
          final TourRace removed = expandedRaces.removeAt(swapIndex);
          currentRaceDays -= math.max(1, removed.stages.length);
          decisions.add(
            CalendarExpansionDecisionRecord(
              candidateId: 'rot_${removed.id}',
              raceName: removed.name,
              seasonYear: seasonYear,
              actionType: CalendarExpansionActionType.relegationToProSeries,
              status: CalendarExpansionStatus.rotatedOut,
              region: ExpansionMarketRegion.europeEmerging,
              raceDaysDelta: -math.max(1, removed.stages.length),
              prizePoolDeltaEur: -removed.prizePoolEur,
              rationale:
                  'Przesunięty do ProSeries, aby zrobić miejsce dla ${candidate.name}.',
            ),
          );
        } else {
          decisions.add(
            CalendarExpansionDecisionRecord(
              candidateId: candidate.id,
              raceName: candidate.name,
              seasonYear: seasonYear,
              actionType: candidate.actionType,
              status: CalendarExpansionStatus.rotatedOut,
              region: candidate.region,
              raceDaysDelta: 0,
              prizePoolDeltaEur: 0,
              rationale:
                  'Limit $maxRaceDaysCap dni wyścigowych osiągnięty — przeniesiono na kolejny sezon.',
            ),
          );
          continue;
        }
      }

      final TourRace builtRace = candidate.buildTourRace(
        seasonYear: seasonYear,
        participatingTeamIds: participatingTeamIds,
      );
      expandedRaces.add(builtRace);
      activeExpansions.add(candidate);
      currentRaceDays += candidateDays;

      decisions.add(
        CalendarExpansionDecisionRecord(
          candidateId: candidate.id,
          raceName: candidate.name,
          seasonYear: seasonYear,
          actionType: candidate.actionType,
          status: CalendarExpansionStatus.activeInCalendar,
          region: candidate.region,
          raceDaysDelta: candidateDays,
          prizePoolDeltaEur: builtRace.prizePoolEur,
          rationale:
              'Włączono do oficjalnego kalendarza WorldTour ($seasonYear).',
        ),
      );
    }

    // Sortowanie chronologiczne po miesiącu i dniu startu
    expandedRaces.sort((a, b) {
      final int monthCmp = a.startMonth.compareTo(b.startMonth);
      if (monthCmp != 0) return monthCmp;
      return a.startDay.compareTo(b.startDay);
    });

    final int totalPrize = expandedRaces.fold<int>(
      0,
      (sum, r) => sum + r.prizePoolEur,
    );

    final Set<String> distinctCountries =
        expandedRaces.map((r) => r.countryIso).toSet();
    final double globalReach =
        (distinctCountries.length * 4.2 + activeExpansions.length * 6.5)
            .clamp(0.0, 100.0);

    final CalendarCongestionAudit audit = auditCalendarCongestion(
      expandedRaces,
      maxRaceDaysCap: maxRaceDaysCap,
    );

    return SeasonCalendarExpansionSummary(
      seasonYear: seasonYear,
      baseRaceCount: baseCount,
      expandedRaceCount: expandedRaces.length,
      totalRaceDays: audit.totalRaceDays,
      totalPrizePoolEur: totalPrize,
      globalReachIndex: globalReach,
      congestionAudit: audit,
      grandePartenza: resolveGrandePartenza(seasonYear),
      activeExpansions: activeExpansions,
      decisions: decisions,
      expandedRaces: expandedRaces,
    );
  }

  /// Zwraca gotowy [SeasonCalendar] po dynamicznej rozbudowie dla zadanego roku.
  static SeasonCalendar buildExpandedSeasonCalendar({
    required int seasonYear,
    List<String> participatingTeamIds = const [],
    int maxRaceDaysCap = defaultMaxRaceDaysCap,
    Set<String> approvedCandidateIds = const {},
    Set<String> rejectedCandidateIds = const {},
  }) {
    final summary = expandCalendarForSeason(
      seasonYear: seasonYear,
      participatingTeamIds: participatingTeamIds,
      maxRaceDaysCap: maxRaceDaysCap,
      approvedCandidateIds: approvedCandidateIds,
      rejectedCandidateIds: rejectedCandidateIds,
    );
    return summary.toSeasonCalendar();
  }

  static int _findRotatableRaceIndex(
    List<TourRace> races, {
    int minRemovedDays = 1,
  }) {
    for (int i = 0; i < races.length; i++) {
      final r = races[i];
      if (!r.isGrandTour &&
          r.uciCategory != RaceCategory.monument &&
          math.max(1, r.stages.length) >= minRemovedDays &&
          (r.uciCategory == RaceCategory.proSeries ||
              r.uciCategory == RaceCategory.class1 ||
              r.uciCategory == RaceCategory.worldTourOneDay)) {
        return i;
      }
    }
    return -1;
  }
}

/// Stan zarządzany przez Riverpod dla ekspansji kalendarza WorldTour.
class WorldTourCalendarExpansionState {
  final int currentSeasonYear;
  final int selectedYear;
  final int maxRaceDaysCap;
  final bool autoApproveUciExpansions;
  final Set<String> approvedCandidateIds;
  final Set<String> rejectedCandidateIds;
  final Map<int, SeasonCalendarExpansionSummary> seasonSummaries;
  final String? lastOperationMessage;

  const WorldTourCalendarExpansionState({
    required this.currentSeasonYear,
    required this.selectedYear,
    required this.maxRaceDaysCap,
    required this.autoApproveUciExpansions,
    required this.approvedCandidateIds,
    required this.rejectedCandidateIds,
    required this.seasonSummaries,
    this.lastOperationMessage,
  });

  factory WorldTourCalendarExpansionState.initial({int startYear = 2026}) {
    final summary = UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
      seasonYear: startYear,
    );
    return WorldTourCalendarExpansionState(
      currentSeasonYear: startYear,
      selectedYear: startYear,
      maxRaceDaysCap: UciWorldtourCalendarExpansionEngine.defaultMaxRaceDaysCap,
      autoApproveUciExpansions: true,
      approvedCandidateIds: const {},
      rejectedCandidateIds: const {},
      seasonSummaries: {startYear: summary},
    );
  }

  SeasonCalendarExpansionSummary get activeSummary =>
      seasonSummaries[selectedYear] ??
      UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
        seasonYear: selectedYear,
        maxRaceDaysCap: maxRaceDaysCap,
        approvedCandidateIds: approvedCandidateIds,
        rejectedCandidateIds: rejectedCandidateIds,
        autoApproveEligible: autoApproveUciExpansions,
      );

  WorldTourCalendarExpansionState copyWith({
    int? currentSeasonYear,
    int? selectedYear,
    int? maxRaceDaysCap,
    bool? autoApproveUciExpansions,
    Set<String>? approvedCandidateIds,
    Set<String>? rejectedCandidateIds,
    Map<int, SeasonCalendarExpansionSummary>? seasonSummaries,
    String? lastOperationMessage,
  }) {
    return WorldTourCalendarExpansionState(
      currentSeasonYear: currentSeasonYear ?? this.currentSeasonYear,
      selectedYear: selectedYear ?? this.selectedYear,
      maxRaceDaysCap: maxRaceDaysCap ?? this.maxRaceDaysCap,
      autoApproveUciExpansions:
          autoApproveUciExpansions ?? this.autoApproveUciExpansions,
      approvedCandidateIds: approvedCandidateIds ?? this.approvedCandidateIds,
      rejectedCandidateIds: rejectedCandidateIds ?? this.rejectedCandidateIds,
      seasonSummaries: seasonSummaries ?? this.seasonSummaries,
      lastOperationMessage: lastOperationMessage,
    );
  }
}

/// Kontroler Riverpod obsługujący symulację kolejnych sezonów i decyzje ekspansji kalendarza.
class UciWorldtourCalendarExpansionNotifier
    extends StateNotifier<WorldTourCalendarExpansionState> {
  UciWorldtourCalendarExpansionNotifier({int startYear = 2026})
      : super(WorldTourCalendarExpansionState.initial(startYear: startYear));

  void selectSeasonYear(int year) {
    final updated = Map<int, SeasonCalendarExpansionSummary>.from(
      state.seasonSummaries,
    );
    updated[year] = _buildSummaryFor(year);
    state = state.copyWith(
      selectedYear: year,
      seasonSummaries: updated,
      lastOperationMessage: 'Wyświetlono kalendarz sezonu $year.',
    );
  }

  void advanceToNextSeason() {
    final int nextYear = state.currentSeasonYear + 1;
    final updated = Map<int, SeasonCalendarExpansionSummary>.from(
      state.seasonSummaries,
    );
    updated[nextYear] = _buildSummaryFor(nextYear);
    state = state.copyWith(
      currentSeasonYear: nextYear,
      selectedYear: nextYear,
      seasonSummaries: updated,
      lastOperationMessage:
          'Wygenerowano dynamiczny kalendarz WorldTour na sezon $nextYear.',
    );
  }

  void approveCandidate(String candidateId) {
    final nextApproved = Set<String>.from(state.approvedCandidateIds)
      ..add(candidateId);
    final nextRejected = Set<String>.from(state.rejectedCandidateIds)
      ..remove(candidateId);
    _recomputeSelectedYear(
      approved: nextApproved,
      rejected: nextRejected,
      message: 'Zatwierdzono kandydata ekspansji ($candidateId).',
    );
  }

  void rejectCandidate(String candidateId) {
    final nextRejected = Set<String>.from(state.rejectedCandidateIds)
      ..add(candidateId);
    final nextApproved = Set<String>.from(state.approvedCandidateIds)
      ..remove(candidateId);
    _recomputeSelectedYear(
      approved: nextApproved,
      rejected: nextRejected,
      message: 'Odrzucono kandydata ekspansji ($candidateId).',
    );
  }

  void toggleAutoApprove(bool enabled) {
    final updated = Map<int, SeasonCalendarExpansionSummary>.from(
      state.seasonSummaries,
    );
    updated[state.selectedYear] =
        UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
      seasonYear: state.selectedYear,
      maxRaceDaysCap: state.maxRaceDaysCap,
      approvedCandidateIds: state.approvedCandidateIds,
      rejectedCandidateIds: state.rejectedCandidateIds,
      autoApproveEligible: enabled,
    );
    state = state.copyWith(
      autoApproveUciExpansions: enabled,
      seasonSummaries: updated,
      lastOperationMessage: enabled
          ? 'Włączono automatyczne zatwierdzanie ekspansji UCI.'
          : 'Przełączono na ręczne głosowanie Rady WorldTour.',
    );
  }

  void setMaxRaceDaysCap(int cap) {
    final int clamped = cap.clamp(160, 240);
    final updated = Map<int, SeasonCalendarExpansionSummary>.from(
      state.seasonSummaries,
    );
    updated[state.selectedYear] =
        UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
      seasonYear: state.selectedYear,
      maxRaceDaysCap: clamped,
      approvedCandidateIds: state.approvedCandidateIds,
      rejectedCandidateIds: state.rejectedCandidateIds,
      autoApproveEligible: state.autoApproveUciExpansions,
    );
    state = state.copyWith(
      maxRaceDaysCap: clamped,
      seasonSummaries: updated,
      lastOperationMessage: 'Ustawiono limit dni wyścigowych na $clamped.',
    );
  }

  void _recomputeSelectedYear({
    required Set<String> approved,
    required Set<String> rejected,
    required String message,
  }) {
    final updated = Map<int, SeasonCalendarExpansionSummary>.from(
      state.seasonSummaries,
    );
    updated[state.selectedYear] =
        UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
      seasonYear: state.selectedYear,
      maxRaceDaysCap: state.maxRaceDaysCap,
      approvedCandidateIds: approved,
      rejectedCandidateIds: rejected,
      autoApproveEligible: state.autoApproveUciExpansions,
    );
    state = state.copyWith(
      approvedCandidateIds: approved,
      rejectedCandidateIds: rejected,
      seasonSummaries: updated,
      lastOperationMessage: message,
    );
  }

  SeasonCalendarExpansionSummary _buildSummaryFor(int year) {
    return UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
      seasonYear: year,
      maxRaceDaysCap: state.maxRaceDaysCap,
      approvedCandidateIds: state.approvedCandidateIds,
      rejectedCandidateIds: state.rejectedCandidateIds,
      autoApproveEligible: state.autoApproveUciExpansions,
    );
  }
}

final uciWorldtourCalendarExpansionProvider = StateNotifierProvider<
    UciWorldtourCalendarExpansionNotifier, WorldTourCalendarExpansionState>(
  (ref) => UciWorldtourCalendarExpansionNotifier(),
);

/// Responsywny panel UI zarządzania i podglądu dynamicznej rozbudowy kalendarza WorldTour.
class UciWorldtourCalendarExpansionPanel extends ConsumerWidget {
  const UciWorldtourCalendarExpansionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uciWorldtourCalendarExpansionProvider);
    final notifier = ref.read(uciWorldtourCalendarExpansionProvider.notifier);
    final summary = state.activeSummary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isCompact = width < 680;
          final bool isWide = width >= 1150;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(
                  state: state,
                  summary: summary,
                  isCompact: isCompact,
                  onSelectYear: notifier.selectSeasonYear,
                  onAdvanceSeason: notifier.advanceToNextSeason,
                  onToggleAutoApprove: notifier.toggleAutoApprove,
                ),
                const SizedBox(height: 16),
                _KpiStrip(
                  summary: summary,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _CongestionCard(
                              audit: summary.congestionAudit,
                              onCapChanged: notifier.setMaxRaceDaysCap,
                            ),
                            const SizedBox(height: 16),
                            _GrandePartenzaCard(
                              partenza: summary.grandePartenza,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _ExpansionCandidatesAndDecisionsCard(
                          seasonYear: summary.seasonYear,
                          decisions: summary.decisions,
                          candidates: UciWorldtourCalendarExpansionEngine
                              .catalogForSeason(summary.seasonYear),
                          approvedIds: state.approvedCandidateIds,
                          rejectedIds: state.rejectedCandidateIds,
                          onApprove: notifier.approveCandidate,
                          onReject: notifier.rejectCandidate,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _CongestionCard(
                    audit: summary.congestionAudit,
                    onCapChanged: notifier.setMaxRaceDaysCap,
                  ),
                  const SizedBox(height: 16),
                  _GrandePartenzaCard(partenza: summary.grandePartenza),
                  const SizedBox(height: 16),
                  _ExpansionCandidatesAndDecisionsCard(
                    seasonYear: summary.seasonYear,
                    decisions: summary.decisions,
                    candidates:
                        UciWorldtourCalendarExpansionEngine.catalogForSeason(
                      summary.seasonYear,
                    ),
                    approvedIds: state.approvedCandidateIds,
                    rejectedIds: state.rejectedCandidateIds,
                    onApprove: notifier.approveCandidate,
                    onReject: notifier.rejectCandidate,
                  ),
                ],
                if (state.lastOperationMessage != null) ...[
                  const SizedBox(height: 12),
                  _StatusBanner(message: state.lastOperationMessage!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final WorldTourCalendarExpansionState state;
  final SeasonCalendarExpansionSummary summary;
  final bool isCompact;
  final ValueChanged<int> onSelectYear;
  final VoidCallback onAdvanceSeason;
  final ValueChanged<bool> onToggleAutoApprove;

  const _HeaderCard({
    required this.state,
    required this.summary,
    required this.isCompact,
    required this.onSelectYear,
    required this.onAdvanceSeason,
    required this.onToggleAutoApprove,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> years = [
      for (int y = 2026; y <= math.max(2030, state.currentSeasonYear + 1); y++)
        y,
    ];

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Text(
                    'EKSPANSJA KALENDARZA UCI WORLDTOUR',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dynamiczna ewolucja wyścigów, rotacje kontynentalne i Grande Partenza (${summary.seasonYear})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InteractiveActionButton(
                    label: 'Kolejny sezon (${state.currentSeasonYear + 1})',
                    icon: Icons.fast_forward_rounded,
                    accentColor: AppColors.goldAccent,
                    onPressed: onAdvanceSeason,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...years.map(
                (y) => _YearChipButton(
                  year: y,
                  isSelected: y == state.selectedYear,
                  isCurrentCareerYear: y == state.currentSeasonYear,
                  onTap: () => onSelectYear(y),
                ),
              ),
              const SizedBox(width: 8),
              _InteractiveToggleChip(
                label: 'Auto-akceptacja UCI',
                value: state.autoApproveUciExpansions,
                onChanged: onToggleAutoApprove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  final SeasonCalendarExpansionSummary summary;
  final bool isCompact;

  const _KpiStrip({
    required this.summary,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(
        label: 'Wyścigi w sezonie',
        value: '${summary.expandedRaceCount}',
        subValue: 'Bazowo ${summary.baseRaceCount}',
        accent: AppColors.accentBlue,
      ),
      _KpiItem(
        label: 'Dni wyścigowe',
        value:
            '${summary.totalRaceDays} / ${summary.congestionAudit.maxRaceDaysCap}',
        subValue: summary.congestionAudit.exceedsCap
            ? 'Przekroczony limit'
            : 'W normie UCI',
        accent: summary.congestionAudit.exceedsCap
            ? AppColors.crimsonAlert
            : AppColors.statusSuccess,
      ),
      _KpiItem(
        label: 'Pula nagród',
        value: Formatters.formatCurrency(summary.totalPrizePoolEur),
        subValue: '+${summary.activeExpansions.length} ekspansji',
        accent: AppColors.goldAccent,
      ),
      _KpiItem(
        label: 'Zasięg globalny',
        value: '${summary.globalReachIndex.toStringAsFixed(0)} / 100',
        subValue: 'Indeks rynków UCI',
        accent: AppColors.cyanAccent,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _KpiCard(item: items[i]),
            if (i < items.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _KpiCard(item: items[i])),
          if (i < items.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final String subValue;
  final Color accent;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.subValue,
    required this.accent,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;

  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: item.accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.subValue,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CongestionCard extends StatelessWidget {
  final CalendarCongestionAudit audit;
  final ValueChanged<int> onCapChanged;

  const _CongestionCard({
    required this.audit,
    required this.onCapChanged,
  });

  static const List<String> _monthNames = [
    'Sty',
    'Lut',
    'Mar',
    'Kwi',
    'Maj',
    'Cze',
    'Lip',
    'Sie',
    'Wrz',
    'Paź',
  ];

  @override
  Widget build(BuildContext context) {
    final int maxMonthVal = math.max(1, audit.peakMonthDays);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'OBCIĄŻENIE KALENDARZA (DNI WYŚCIGOWE)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Limit: ${audit.maxRaceDaysCap} dni',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(10, (idx) {
                final int month = idx + 1;
                final int days = audit.raceDaysByMonth[month] ?? 0;
                final double ratio = days / maxMonthVal;
                final bool isPeak = month == audit.peakMonth;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$days',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          height: math.max(6.0, ratio * 66.0),
                          decoration: BoxDecoration(
                            color: isPeak
                                ? AppColors.primaryAccent
                                : AppColors.accentBlue.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _monthNames[idx],
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionButton(
                label: 'Limit -10',
                icon: Icons.remove_rounded,
                accentColor: AppColors.textSecondary,
                onPressed: audit.maxRaceDaysCap > 165
                    ? () => onCapChanged(audit.maxRaceDaysCap - 10)
                    : null,
              ),
              _InteractiveActionButton(
                label: 'Limit +10',
                icon: Icons.add_rounded,
                accentColor: AppColors.accentBlue,
                onPressed: audit.maxRaceDaysCap < 235
                    ? () => onCapChanged(audit.maxRaceDaysCap + 10)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrandePartenzaCard extends StatelessWidget {
  final GrandTourGrandePartenzaSpec partenza;

  const _GrandePartenzaCard({required this.partenza});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ZAGRANICZNE STARTY WIELKICH TOURÓW (${partenza.seasonYear})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _PartenzaRow(
            tourLabel: 'Corsa Rosa (Giro)',
            city: partenza.giroStartCity,
            accent: AppColors.primaryAccent,
          ),
          const SizedBox(height: 8),
          _PartenzaRow(
            tourLabel: 'La Grande Boucle (Tour)',
            city: partenza.tourStartCity,
            accent: AppColors.goldAccent,
          ),
          const SizedBox(height: 8),
          _PartenzaRow(
            tourLabel: 'La Vuelta Ibérica',
            city: partenza.vueltaStartCity,
            accent: AppColors.crimsonAlert,
          ),
        ],
      ),
    );
  }
}

class _PartenzaRow extends StatelessWidget {
  final String tourLabel;
  final String city;
  final Color accent;

  const _PartenzaRow({
    required this.tourLabel,
    required this.city,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              tourLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            city,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpansionCandidatesAndDecisionsCard extends StatelessWidget {
  final int seasonYear;
  final List<CalendarExpansionDecisionRecord> decisions;
  final List<WorldTourExpansionCandidate> candidates;
  final Set<String> approvedIds;
  final Set<String> rejectedIds;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  const _ExpansionCandidatesAndDecisionsCard({
    required this.seasonYear,
    required this.decisions,
    required this.candidates,
    required this.approvedIds,
    required this.rejectedIds,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OFERTY EKSPANSJI I DECYZJE RADY UCI ($seasonYear)',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (candidates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'W sezonie inauguracyjnym 2026 obowiązuje podstawowy kalendarz UCI. Wybierz rok 2027+ lub przejdź do kolejnego sezonu, aby uruchomić ekspansję.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: candidates.map((candidate) {
                final decision = decisions.firstWhere(
                  (d) => d.candidateId == candidate.id,
                  orElse: () => CalendarExpansionDecisionRecord(
                    candidateId: candidate.id,
                    raceName: candidate.name,
                    seasonYear: seasonYear,
                    actionType: candidate.actionType,
                    status: CalendarExpansionStatus.proposed,
                    region: candidate.region,
                    raceDaysDelta: candidate.stageCount,
                    prizePoolDeltaEur: candidate.prizePoolEur,
                    rationale: candidate.description,
                  ),
                );
                final bool isApproved =
                    decision.status == CalendarExpansionStatus.activeInCalendar ||
                        approvedIds.contains(candidate.id);
                final bool isRejected =
                    decision.status == CalendarExpansionStatus.rejected ||
                        rejectedIds.contains(candidate.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: decision.status.badgeColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${candidate.name} (${candidate.countryIso})',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: decision.status.badgeColor
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                decision.status.polishLabel,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: decision.status.badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${candidate.region.polishLabel} • ${candidate.stageCount} et. • ${Formatters.formatCurrency(candidate.prizePoolEur)} • ${decision.rationale}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InteractiveActionButton(
                              label: 'Zatwierdź',
                              icon: Icons.check_circle_outline_rounded,
                              accentColor: AppColors.statusSuccess,
                              onPressed: isApproved
                                  ? null
                                  : () => onApprove(candidate.id),
                            ),
                            _InteractiveActionButton(
                              label: 'Odrzuć',
                              icon: Icons.cancel_outlined,
                              accentColor: AppColors.crimsonAlert,
                              onPressed: isRejected
                                  ? null
                                  : () => onReject(candidate.id),
                            ),
                          ],
                        ),
                      ],
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

class _StatusBanner extends StatelessWidget {
  final String message;

  const _StatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearChipButton extends StatefulWidget {
  final int year;
  final bool isSelected;
  final bool isCurrentCareerYear;
  final VoidCallback onTap;

  const _YearChipButton({
    required this.year,
    required this.isSelected,
    required this.isCurrentCareerYear,
    required this.onTap,
  });

  @override
  State<_YearChipButton> createState() => _YearChipButtonState();
}

class _YearChipButtonState extends State<_YearChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.textSecondary
                : AppColors.cardBorder;

    final Color bgColor = widget.isSelected
        ? AppColors.goldAccent.withValues(alpha: 0.18)
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.isCurrentCareerYear
                ? '${widget.year} •'
                : '${widget.year}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveToggleChip extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InteractiveToggleChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_InteractiveToggleChip> createState() => _InteractiveToggleChipState();
}

class _InteractiveToggleChipState extends State<_InteractiveToggleChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
        widget.value ? AppColors.statusSuccess : AppColors.textSecondary;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: () => widget.onChanged(!widget.value),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surfaceLight
                : activeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? AppColors.accentBlue : activeColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.value
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                size: 16,
                color: activeColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
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
    final bool disabled = widget.onPressed == null;
    final Color effectiveAccent =
        disabled ? AppColors.textSecondary.withValues(alpha: 0.45) : widget.accentColor;

    final Color bgColor = disabled
        ? AppColors.background.withValues(alpha: 0.4)
        : _pressed
            ? effectiveAccent.withValues(alpha: 0.28)
            : _hovered
                ? effectiveAccent.withValues(alpha: 0.20)
                : effectiveAccent.withValues(alpha: 0.12);

    final Color borderColor = disabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.textPrimary
            : effectiveAccent.withValues(alpha: _hovered ? 0.9 : 0.55);

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: effectiveAccent),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: effectiveAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
