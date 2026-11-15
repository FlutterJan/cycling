import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/career_save.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import 'pro_cycling_stats_table_widget.dart';

/// Kategoria wyniku w globalnej wyszukiwarce Spotlight (`Ctrl+K`).
enum SpotlightSearchCategory {
  all,
  rider,
  team,
  race,
  climb;

  String get label {
    switch (this) {
      case SpotlightSearchCategory.all:
        return 'Wszystko';
      case SpotlightSearchCategory.rider:
        return 'Kolarze';
      case SpotlightSearchCategory.team:
        return 'Drużyny';
      case SpotlightSearchCategory.race:
        return 'Wyścigi';
      case SpotlightSearchCategory.climb:
        return 'Podjazdy';
    }
  }

  String get badgeLabel {
    switch (this) {
      case SpotlightSearchCategory.all:
        return 'ALL';
      case SpotlightSearchCategory.rider:
        return 'KOLARZ';
      case SpotlightSearchCategory.team:
        return 'DRUŻYNA';
      case SpotlightSearchCategory.race:
        return 'WYŚCIG';
      case SpotlightSearchCategory.climb:
        return 'PODJAZD';
    }
  }

  IconData get icon {
    switch (this) {
      case SpotlightSearchCategory.all:
        return Icons.manage_search_rounded;
      case SpotlightSearchCategory.rider:
        return Icons.directions_bike_rounded;
      case SpotlightSearchCategory.team:
        return Icons.shield_rounded;
      case SpotlightSearchCategory.race:
        return Icons.flag_rounded;
      case SpotlightSearchCategory.climb:
        return Icons.terrain_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case SpotlightSearchCategory.all:
        return AppColors.goldAccent;
      case SpotlightSearchCategory.rider:
        return AppColors.accentBlue;
      case SpotlightSearchCategory.team:
        return AppColors.goldAccent;
      case SpotlightSearchCategory.race:
        return AppColors.statusSuccess;
      case SpotlightSearchCategory.climb:
        return AppColors.crimsonAlert;
    }
  }
}

/// Model podjazdu (górskiej premii / kultowej wspinaczki) w indeksie Spotlight.
@immutable
class SpotlightClimbEntry {
  final String id;
  final String name;
  final String categoryLabel; // HC, 1, 2, 3, 4
  final String countryIso;
  final double lengthKm;
  final double avgGradientPercent;
  final double maxGradientPercent;
  final double summitElevationM;
  final double elevationGainM;
  final String? linkedRaceId;
  final String? linkedRaceName;
  final int? linkedStageNumber;
  final String? linkedStageName;

  const SpotlightClimbEntry({
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.countryIso,
    required this.lengthKm,
    required this.avgGradientPercent,
    required this.maxGradientPercent,
    required this.summitElevationM,
    required this.elevationGainM,
    this.linkedRaceId,
    this.linkedRaceName,
    this.linkedStageNumber,
    this.linkedStageName,
  });

  Color get categoryColor {
    switch (categoryLabel.toUpperCase()) {
      case 'HC':
        return AppColors.crimsonAlert;
      case '1':
        return AppColors.powerZone5;
      case '2':
        return AppColors.amberWarning;
      case '3':
        return AppColors.accentBlue;
      default:
        return AppColors.statusSuccess;
    }
  }
}

/// Pojedynczy element zindeksowany w globalnej wyszukiwarce Spotlight.
@immutable
class SpotlightSearchItem {
  final String id;
  final SpotlightSearchCategory category;
  final String title;
  final String subtitle;
  final String primaryMetric;
  final String secondaryMetric;
  final String countryIso;
  final String normalizedSearchText;
  final String normalizedTitle;
  final int priorityScore;
  final Rider? rider;
  final CyclingTeam? team;
  final TourRace? race;
  final RaceStage? stage;
  final SpotlightClimbEntry? climb;

  const SpotlightSearchItem({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.primaryMetric,
    required this.secondaryMetric,
    required this.countryIso,
    required this.normalizedSearchText,
    required this.normalizedTitle,
    this.priorityScore = 0,
    this.rider,
    this.team,
    this.race,
    this.stage,
    this.climb,
  });
}

/// Wynik wyboru elementu w modalu (zwracany opcjonalnie lub obsługiwany bezpośrednio).
@immutable
class SpotlightSelectionResult {
  final SpotlightSearchItem item;
  const SpotlightSelectionResult(this.item);
}

/// Szybki, deterministyczny silnik indeksowania i wyszukiwania dla 800+ kolarzy,
/// 53 drużyn, wyścigów i podjazdów.
class SpotlightSearchIndex {
  final List<SpotlightSearchItem> allItems;
  final Map<String, CyclingTeam> teamsById;
  final Map<String, List<Rider>> ridersByTeamId;

  const SpotlightSearchIndex({
    required this.allItems,
    required this.teamsById,
    required this.ridersByTeamId,
  });

  /// Buduje indeks wyszukiwania na podstawie aktualnego zapisu kariery.
  factory SpotlightSearchIndex.fromCareerSave(CareerSave save) {
    final teamsById = <String, CyclingTeam>{};
    final ridersByTeamId = <String, List<Rider>>{};

    for (final team in save.teams) {
      teamsById[team.id] = team;
      ridersByTeamId[team.id] = <Rider>[];
    }

    // Przypisz kolarzy do drużyn po rosterRiderIds
    final riderTeamLookup = <String, CyclingTeam>{};
    for (final team in save.teams) {
      for (final riderId in team.rosterRiderIds) {
        riderTeamLookup[riderId] = team;
      }
    }

    for (final rider in save.riders) {
      final team = riderTeamLookup[rider.id];
      if (team != null) {
        ridersByTeamId[team.id]?.add(rider);
      }
    }

    final items = <SpotlightSearchItem>[];

    // 1. Kolarze (800+)
    for (final rider in save.riders) {
      final team = riderTeamLookup[rider.id];
      final teamName = team?.name ?? 'Wolny Agent';
      final isPlayerRider = team?.id == save.playerTeamId;
      final ovr = rider.overallRating;
      final wKg = rider.physiology.wattsPerKg;
      final title = rider.fullName;
      final subtitle =
          '${rider.specialization.displayName} • $teamName • ${rider.age} lat';
      final searchBlob = _normalizeForSearch(
        '$title $teamName ${rider.nationalityIso} '
        '${rider.specialization.displayName} ${rider.specialization.name} '
        'ovr $ovr ftp ${rider.physiology.ftpWatts}',
      );

      items.add(
        SpotlightSearchItem(
          id: 'rider:${rider.id}',
          category: SpotlightSearchCategory.rider,
          title: title,
          subtitle: subtitle,
          primaryMetric: 'OVR $ovr',
          secondaryMetric: '${wKg.toStringAsFixed(2)} W/kg',
          countryIso: rider.nationalityIso,
          normalizedSearchText: searchBlob,
          normalizedTitle: _normalizeForSearch(title),
          priorityScore: ovr + (isPlayerRider ? 30 : 0),
          rider: rider,
          team: team,
        ),
      );
    }

    // 2. Drużyny (53+)
    for (final team in save.teams) {
      final isPlayerTeam = team.id == save.playerTeamId;
      final rosterCount = team.rosterRiderIds.length;
      final subtitle =
          '${team.division.label} • $rosterCount kolarzy • ${team.bikeDeal.manufacturerName}';
      final searchBlob = _normalizeForSearch(
        '${team.name} ${team.division.label} ${team.countryIso} '
        '${team.bikeDeal.manufacturerName} ${isPlayerTeam ? "moja druzyna" : ""}',
      );

      items.add(
        SpotlightSearchItem(
          id: 'team:${team.id}',
          category: SpotlightSearchCategory.team,
          title: team.name,
          subtitle: subtitle,
          primaryMetric: '${team.uciPointsSeason} pkt UCI',
          secondaryMetric: team.division.label.replaceFirst('UCI ', ''),
          countryIso: team.countryIso,
          normalizedSearchText: searchBlob,
          normalizedTitle: _normalizeForSearch(team.name),
          priorityScore:
              (isPlayerTeam ? 200 : 0) +
              (team.division == TeamDivision.worldTour
                  ? 80
                  : team.division == TeamDivision.proTeam
                  ? 50
                  : 25) +
              (team.uciPointsSeason ~/ 100),
          team: team,
        ),
      );
    }

    // 3. Wyścigi z kalendarza sezonu
    for (final race in save.calendar.races) {
      final categoryLabel = _raceCategoryLabel(race.uciCategory);
      final isCompleted = save.calendar.isRaceCompleted(race.id);
      final isActive = save.calendar.isRaceActive(race.id);
      final dateStr =
          '${race.startDay.toString().padLeft(2, '0')}.${race.startMonth.toString().padLeft(2, '0')}';
      final stageWord = race.isOneDayRace
          ? '1 dzień'
          : '${race.stages.length} etapów';
      final subtitle =
          '$categoryLabel • $dateStr • $stageWord • ${race.totalRaceDistanceKm.round()} km';
      final searchBlob = _normalizeForSearch(
        '${race.name} $categoryLabel ${race.uciCategory.name} ${race.countryIso} '
        '${isActive ? "aktywny dzis" : ""} ${isCompleted ? "ukonczony" : ""}',
      );

      items.add(
        SpotlightSearchItem(
          id: 'race:${race.id}',
          category: SpotlightSearchCategory.race,
          title: race.name,
          subtitle: subtitle,
          primaryMetric: '${race.totalRaceElevationGainM.round()} m ↑',
          secondaryMetric: categoryLabel,
          countryIso: race.countryIso,
          normalizedSearchText: searchBlob,
          normalizedTitle: _normalizeForSearch(race.name),
          priorityScore:
              (isActive ? 150 : 0) +
              (race.uciCategory == RaceCategory.grandTour
                  ? 95
                  : race.uciCategory == RaceCategory.monument
                  ? 90
                  : race.uciCategory == RaceCategory.worldTourStageRace
                  ? 75
                  : 55),
          race: race,
        ),
      );
    }

    // 4. Podjazdy (ekstrakcja z etapów + katalog kultowych przełęczy/podjazdów)
    final climbEntries = _buildClimbCatalog(save.calendar.races);
    for (final entry in climbEntries) {
      final raceInfo = entry.linkedRaceName != null
          ? ' • ${entry.linkedRaceName}${entry.linkedStageNumber != null ? " (Etap ${entry.linkedStageNumber})" : ""}'
          : '';
      final subtitle =
          'Kat. ${entry.categoryLabel} • ${entry.lengthKm.toStringAsFixed(1)} km @ ${entry.avgGradientPercent.toStringAsFixed(1)}%$raceInfo';
      final searchBlob = _normalizeForSearch(
        '${entry.name} kat ${entry.categoryLabel} ${entry.countryIso} '
        '${entry.linkedRaceName ?? ""} ${entry.linkedStageName ?? ""} podjazd gora kom',
      );

      TourRace? matchedRace;
      RaceStage? matchedStage;
      if (entry.linkedRaceId != null) {
        for (final r in save.calendar.races) {
          if (r.id == entry.linkedRaceId) {
            matchedRace = r;
            if (entry.linkedStageNumber != null) {
              for (final s in r.stages) {
                if (s.stageNumber == entry.linkedStageNumber) {
                  matchedStage = s;
                  break;
                }
              }
            }
            break;
          }
        }
      }

      items.add(
        SpotlightSearchItem(
          id: 'climb:${entry.id}',
          category: SpotlightSearchCategory.climb,
          title: entry.name,
          subtitle: subtitle,
          primaryMetric: '${entry.summitElevationM.round()} m n.p.m.',
          secondaryMetric:
              '${entry.avgGradientPercent.toStringAsFixed(1)}% śr.',
          countryIso: entry.countryIso,
          normalizedSearchText: searchBlob,
          normalizedTitle: _normalizeForSearch(entry.name),
          priorityScore: entry.categoryLabel == 'HC'
              ? 88
              : entry.categoryLabel == '1'
              ? 76
              : 62,
          race: matchedRace,
          stage: matchedStage,
          climb: entry,
        ),
      );
    }

    return SpotlightSearchIndex(
      allItems: items,
      teamsById: teamsById,
      ridersByTeamId: ridersByTeamId,
    );
  }

  /// Filtruje i sortuje elementy w czasie rzeczywistym.
  List<SpotlightSearchItem> search({
    required String query,
    required SpotlightSearchCategory category,
    int limit = 60,
  }) {
    final normalizedQuery = _normalizeForSearch(query);
    final tokens = normalizedQuery
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();

    final scored = <_ScoredItem>[];

    for (final item in allItems) {
      if (category != SpotlightSearchCategory.all &&
          item.category != category) {
        continue;
      }

      if (tokens.isEmpty) {
        scored.add(_ScoredItem(item, item.priorityScore));
        continue;
      }

      bool allMatch = true;
      for (final token in tokens) {
        if (!item.normalizedSearchText.contains(token)) {
          allMatch = false;
          break;
        }
      }
      if (!allMatch) continue;

      int score = item.priorityScore;
      if (item.normalizedTitle == normalizedQuery) {
        score += 1000;
      } else if (item.normalizedTitle.startsWith(normalizedQuery)) {
        score += 650;
      } else if (item.normalizedTitle.contains(normalizedQuery)) {
        score += 350;
      } else {
        // Dopasowanie po początku któregoś ze słów w tytule
        final words = item.normalizedTitle.split(' ');
        for (final w in words) {
          if (tokens.any((t) => w.startsWith(t))) {
            score += 220;
            break;
          }
        }
      }

      scored.add(_ScoredItem(item, score));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.item.title.compareTo(b.item.title);
    });

    if (scored.length > limit) {
      return scored.sublist(0, limit).map((e) => e.item).toList();
    }
    return scored.map((e) => e.item).toList();
  }

  /// Zlicza trafienia w podziale na kategorie dla aktualnego zapytania.
  Map<SpotlightSearchCategory, int> countByCategory(String query) {
    final normalizedQuery = _normalizeForSearch(query);
    final tokens = normalizedQuery
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();

    final counts = <SpotlightSearchCategory, int>{
      SpotlightSearchCategory.all: 0,
      SpotlightSearchCategory.rider: 0,
      SpotlightSearchCategory.team: 0,
      SpotlightSearchCategory.race: 0,
      SpotlightSearchCategory.climb: 0,
    };

    for (final item in allItems) {
      if (tokens.isNotEmpty) {
        bool allMatch = true;
        for (final token in tokens) {
          if (!item.normalizedSearchText.contains(token)) {
            allMatch = false;
            break;
          }
        }
        if (!allMatch) continue;
      }
      counts[SpotlightSearchCategory.all] =
          (counts[SpotlightSearchCategory.all] ?? 0) + 1;
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }

    return counts;
  }

  static String _raceCategoryLabel(RaceCategory cat) {
    switch (cat) {
      case RaceCategory.grandTour:
        return 'Grand Tour';
      case RaceCategory.monument:
        return 'Monument';
      case RaceCategory.worldTourStageRace:
        return 'UCI WorldTour';
      case RaceCategory.worldTourOneDay:
        return 'WorldTour Classic';
      case RaceCategory.proSeries:
        return 'UCI ProSeries';
      case RaceCategory.class1:
        return 'UCI 1.1 / 2.1';
    }
  }

  static List<SpotlightClimbEntry> _buildClimbCatalog(List<TourRace> races) {
    final result = <SpotlightClimbEntry>[];
    final usedIds = <String>{};

    // Kultowe podjazdy światowego peletonu powiązane z kalendarzem
    const iconicSeeds = <_IconicClimbSeed>[
      _IconicClimbSeed(
        id: 'alpe_dhuez',
        name: "Alpe d'Huez",
        category: 'HC',
        countryIso: 'FRA',
        lengthKm: 13.8,
        avgGradient: 8.1,
        maxGradient: 13.0,
        summitElevationM: 1850,
        elevationGainM: 1118,
        raceNameHint: 'tour de france',
      ),
      _IconicClimbSeed(
        id: 'col_du_galibier',
        name: 'Col du Galibier',
        category: 'HC',
        countryIso: 'FRA',
        lengthKm: 17.7,
        avgGradient: 6.9,
        maxGradient: 12.1,
        summitElevationM: 2642,
        elevationGainM: 1221,
        raceNameHint: 'tour de france',
      ),
      _IconicClimbSeed(
        id: 'mont_ventoux',
        name: 'Mont Ventoux',
        category: 'HC',
        countryIso: 'FRA',
        lengthKm: 15.7,
        avgGradient: 8.8,
        maxGradient: 12.5,
        summitElevationM: 1910,
        elevationGainM: 1380,
        raceNameHint: 'tour de france',
      ),
      _IconicClimbSeed(
        id: 'col_du_tourmalet',
        name: 'Col du Tourmalet',
        category: 'HC',
        countryIso: 'FRA',
        lengthKm: 17.1,
        avgGradient: 7.3,
        maxGradient: 10.5,
        summitElevationM: 2115,
        elevationGainM: 1248,
        raceNameHint: 'tour de france',
      ),
      _IconicClimbSeed(
        id: 'col_de_la_loze',
        name: 'Col de la Loze',
        category: 'HC',
        countryIso: 'FRA',
        lengthKm: 28.1,
        avgGradient: 6.0,
        maxGradient: 24.0,
        summitElevationM: 2304,
        elevationGainM: 1686,
        raceNameHint: 'tour de france',
      ),
      _IconicClimbSeed(
        id: 'passo_dello_stelvio',
        name: 'Passo dello Stelvio',
        category: 'HC',
        countryIso: 'ITA',
        lengthKm: 24.3,
        avgGradient: 7.4,
        maxGradient: 14.0,
        summitElevationM: 2758,
        elevationGainM: 1798,
        raceNameHint: 'giro',
      ),
      _IconicClimbSeed(
        id: 'passo_del_mortirolo',
        name: 'Passo del Mortirolo',
        category: 'HC',
        countryIso: 'ITA',
        lengthKm: 12.4,
        avgGradient: 10.5,
        maxGradient: 18.0,
        summitElevationM: 1852,
        elevationGainM: 1302,
        raceNameHint: 'giro',
      ),
      _IconicClimbSeed(
        id: 'monte_zoncolan',
        name: 'Monte Zoncolan',
        category: 'HC',
        countryIso: 'ITA',
        lengthKm: 10.1,
        avgGradient: 11.9,
        maxGradient: 22.0,
        summitElevationM: 1730,
        elevationGainM: 1203,
        raceNameHint: 'giro',
      ),
      _IconicClimbSeed(
        id: 'tre_cime_lavaredo',
        name: 'Tre Cime di Lavaredo',
        category: 'HC',
        countryIso: 'ITA',
        lengthKm: 7.2,
        avgGradient: 7.6,
        maxGradient: 18.0,
        summitElevationM: 2320,
        elevationGainM: 548,
        raceNameHint: 'giro',
      ),
      _IconicClimbSeed(
        id: 'alto_de_angliru',
        name: "Alto de l'Angliru",
        category: 'HC',
        countryIso: 'ESP',
        lengthKm: 12.4,
        avgGradient: 9.8,
        maxGradient: 23.5,
        summitElevationM: 1570,
        elevationGainM: 1215,
        raceNameHint: 'vuelta',
      ),
      _IconicClimbSeed(
        id: 'lagos_de_covadonga',
        name: 'Lagos de Covadonga',
        category: 'HC',
        countryIso: 'ESP',
        lengthKm: 12.5,
        avgGradient: 6.9,
        maxGradient: 16.0,
        summitElevationM: 1134,
        elevationGainM: 862,
        raceNameHint: 'vuelta',
      ),
      _IconicClimbSeed(
        id: 'oude_kwaremont',
        name: 'Oude Kwaremont',
        category: '2',
        countryIso: 'BEL',
        lengthKm: 2.2,
        avgGradient: 4.0,
        maxGradient: 11.6,
        summitElevationM: 111,
        elevationGainM: 88,
        raceNameHint: 'flandr',
      ),
      _IconicClimbSeed(
        id: 'paterberg',
        name: 'Paterberg',
        category: '2',
        countryIso: 'BEL',
        lengthKm: 0.4,
        avgGradient: 12.9,
        maxGradient: 20.3,
        summitElevationM: 80,
        elevationGainM: 48,
        raceNameHint: 'flandr',
      ),
      _IconicClimbSeed(
        id: 'koppenberg',
        name: 'Koppenberg',
        category: '2',
        countryIso: 'BEL',
        lengthKm: 0.6,
        avgGradient: 11.6,
        maxGradient: 22.0,
        summitElevationM: 77,
        elevationGainM: 70,
        raceNameHint: 'flandr',
      ),
      _IconicClimbSeed(
        id: 'mur_de_huy',
        name: 'Mur de Huy',
        category: '1',
        countryIso: 'BEL',
        lengthKm: 1.3,
        avgGradient: 9.6,
        maxGradient: 26.0,
        summitElevationM: 204,
        elevationGainM: 125,
        raceNameHint: 'fleche',
      ),
      _IconicClimbSeed(
        id: 'poggio_san_remo',
        name: 'Poggio di San Remo',
        category: '3',
        countryIso: 'ITA',
        lengthKm: 3.7,
        avgGradient: 3.7,
        maxGradient: 8.0,
        summitElevationM: 160,
        elevationGainM: 136,
        raceNameHint: 'san remo',
      ),
      _IconicClimbSeed(
        id: 'madonna_del_ghisallo',
        name: 'Madonna del Ghisallo',
        category: '1',
        countryIso: 'ITA',
        lengthKm: 8.6,
        avgGradient: 6.2,
        maxGradient: 14.0,
        summitElevationM: 754,
        elevationGainM: 532,
        raceNameHint: 'lombardia',
      ),
      _IconicClimbSeed(
        id: 'orlinek_karpacz',
        name: 'Orlinek (Karpacz)',
        category: '1',
        countryIso: 'POL',
        lengthKm: 11.2,
        avgGradient: 5.4,
        maxGradient: 11.5,
        summitElevationM: 810,
        elevationGainM: 605,
        raceNameHint: 'pologne',
      ),
    ];

    for (final seed in iconicSeeds) {
      TourRace? linkedRace;
      RaceStage? linkedStage;
      for (final r in races) {
        if (r.name.toLowerCase().contains(seed.raceNameHint)) {
          linkedRace = r;
          for (final st in r.stages) {
            if (st.stageType == StageType.highMountain ||
                st.stageType == StageType.summitFinish ||
                st.stageType == StageType.hilly ||
                st.stageType == StageType.cobbleClassic) {
              linkedStage = st;
              break;
            }
          }
          linkedStage ??= r.stages.isNotEmpty ? r.stages.first : null;
          break;
        }
      }

      usedIds.add(seed.id);
      result.add(
        SpotlightClimbEntry(
          id: seed.id,
          name: seed.name,
          categoryLabel: seed.category,
          countryIso: seed.countryIso,
          lengthKm: seed.lengthKm,
          avgGradientPercent: seed.avgGradient,
          maxGradientPercent: seed.maxGradient,
          summitElevationM: seed.summitElevationM,
          elevationGainM: seed.elevationGainM,
          linkedRaceId: linkedRace?.id,
          linkedRaceName: linkedRace?.name,
          linkedStageNumber: linkedStage?.stageNumber,
          linkedStageName: linkedStage?.name,
        ),
      );
    }

    // Dynamiczne podjazdy wyodrębnione z etapów kalendarza (premie KOM)
    int dynamicAdded = 0;
    for (final race in races) {
      for (final stage in race.stages) {
        for (final seg in stage.segments) {
          if (!seg.isKom && seg.gradientPercent < 6.0) continue;
          if (seg.lengthKm < 1.2) continue;

          final cat = seg.climbCategory ?? (seg.gradientPercent >= 8.0 ? '1' : '2');
          final climbId = 'seg_${race.id}_${stage.id}_${seg.index}';
          if (usedIds.contains(climbId)) continue;
          usedIds.add(climbId);

          final displayName =
              '${stage.name} • Premia KM ${seg.endKm.toStringAsFixed(0)}';
          result.add(
            SpotlightClimbEntry(
              id: climbId,
              name: displayName,
              categoryLabel: cat,
              countryIso: race.countryIso,
              lengthKm: seg.lengthKm,
              avgGradientPercent: math.max(0.5, seg.gradientPercent),
              maxGradientPercent: math.max(
                seg.gradientPercent + 2.0,
                seg.gradientPercent * 1.35,
              ),
              summitElevationM: seg.endElevationM,
              elevationGainM: seg.elevationGainM,
              linkedRaceId: race.id,
              linkedRaceName: race.name,
              linkedStageNumber: stage.stageNumber,
              linkedStageName: stage.name,
            ),
          );
          dynamicAdded++;
          if (dynamicAdded >= 80) break;
        }
        if (dynamicAdded >= 80) break;
      }
      if (dynamicAdded >= 80) break;
    }

    return result;
  }

  static String _normalizeForSearch(String input) {
    final lower = input.toLowerCase().trim();
    const replacements = <String, String>{
      'ą': 'a',
      'ć': 'c',
      'ę': 'e',
      'ł': 'l',
      'ń': 'n',
      'ó': 'o',
      'ś': 's',
      'ź': 'z',
      'ż': 'z',
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'č': 'c',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ô': 'o',
      'ö': 'o',
      'ø': 'o',
      'ř': 'r',
      'š': 's',
      'ß': 'ss',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ž': 'z',
      'đ': 'd',
      'ğ': 'g',
      'ş': 's',
    };
    final buffer = StringBuffer();
    for (int i = 0; i < lower.length; i++) {
      final ch = lower[i];
      buffer.write(replacements[ch] ?? ch);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _ScoredItem {
  final SpotlightSearchItem item;
  final int score;
  const _ScoredItem(this.item, this.score);
}

class _IconicClimbSeed {
  final String id;
  final String name;
  final String category;
  final String countryIso;
  final double lengthKm;
  final double avgGradient;
  final double maxGradient;
  final double summitElevationM;
  final double elevationGainM;
  final String raceNameHint;

  const _IconicClimbSeed({
    required this.id,
    required this.name,
    required this.category,
    required this.countryIso,
    required this.lengthKm,
    required this.avgGradient,
    required this.maxGradient,
    required this.summitElevationM,
    required this.elevationGainM,
    required this.raceNameHint,
  });
}

/// Globalna wyszukiwarka Spotlight (`Ctrl+K` / ikona lupy) pozwalająca natychmiast
/// wyszukać dowolnego z 800+ kolarzy, 53 drużyn, wyścigów i podjazdów z
/// bezpośrednim przejściem do ich profilu.
class GlobalSearchSpotlightModal extends StatefulWidget {
  final CareerSave careerSave;
  final ValueChanged<Rider>? onNavigateToRider;
  final ValueChanged<CyclingTeam>? onNavigateToTeam;
  final ValueChanged<TourRace>? onNavigateToRace;
  final void Function(SpotlightClimbEntry climb, TourRace? race, RaceStage? stage)?
  onNavigateToClimb;

  const GlobalSearchSpotlightModal({
    super.key,
    required this.careerSave,
    this.onNavigateToRider,
    this.onNavigateToTeam,
    this.onNavigateToRace,
    this.onNavigateToClimb,
  });

  /// Otwiera modal Spotlight jako responsywne okno nakładkowe z animacją wejścia.
  static Future<SpotlightSelectionResult?> show(
    BuildContext context, {
    required CareerSave careerSave,
    ValueChanged<Rider>? onNavigateToRider,
    ValueChanged<CyclingTeam>? onNavigateToTeam,
    ValueChanged<TourRace>? onNavigateToRace,
    void Function(SpotlightClimbEntry climb, TourRace? race, RaceStage? stage)?
    onNavigateToClimb,
  }) {
    return showGeneralDialog<SpotlightSelectionResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Zamknij wyszukiwarkę Spotlight',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return GlobalSearchSpotlightModal(
          careerSave: careerSave,
          onNavigateToRider: onNavigateToRider,
          onNavigateToTeam: onNavigateToTeam,
          onNavigateToRace: onNavigateToRace,
          onNavigateToClimb: onNavigateToClimb,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GlobalSearchSpotlightModal> createState() =>
      _GlobalSearchSpotlightModalState();
}

class _GlobalSearchSpotlightModalState
    extends State<GlobalSearchSpotlightModal> {
  static final List<String> _recentQueries = <String>[];

  late final SpotlightSearchIndex _index;
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _resultsScrollController = ScrollController();

  SpotlightSearchCategory _selectedCategory = SpotlightSearchCategory.all;
  List<SpotlightSearchItem> _results = const [];
  Map<SpotlightSearchCategory, int> _categoryCounts = const {};
  int _highlightedIndex = 0;

  // Wbudowany widok profilu drużyny (dla wszystkich 53 drużyn świata UCI)
  CyclingTeam? _inspectedTeam;

  @override
  void initState() {
    super.initState();
    _index = SpotlightSearchIndex.fromCareerSave(widget.careerSave);
    _recomputeResults();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant GlobalSearchSpotlightModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.careerSave, widget.careerSave)) {
      _index = SpotlightSearchIndex.fromCareerSave(widget.careerSave);
      _recomputeResults();
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _searchFocusNode.dispose();
    _resultsScrollController.dispose();
    super.dispose();
  }

  void _recomputeResults() {
    final query = _queryController.text;
    final filtered = _index.search(
      query: query,
      category: _selectedCategory,
      limit: 65,
    );
    final counts = _index.countByCategory(query);
    setState(() {
      _results = filtered;
      _categoryCounts = counts;
      if (_results.isEmpty) {
        _highlightedIndex = -1;
      } else if (_highlightedIndex < 0 || _highlightedIndex >= _results.length) {
        _highlightedIndex = 0;
      }
    });
  }

  void _onCategorySelected(SpotlightSearchCategory category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _highlightedIndex = 0;
    });
    _recomputeResults();
    _searchFocusNode.requestFocus();
  }

  void _moveSelection(int delta) {
    if (_results.isEmpty) return;
    setState(() {
      final next = (_highlightedIndex + delta).clamp(0, _results.length - 1);
      _highlightedIndex = next;
    });
    _scrollToHighlighted();
  }

  void _scrollToHighlighted() {
    if (!_resultsScrollController.hasClients || _highlightedIndex < 0) return;
    const itemExtent = 66.0;
    final targetOffset = _highlightedIndex * itemExtent;
    final currentOffset = _resultsScrollController.offset;
    final viewportHeight = _resultsScrollController.position.viewportDimension;

    if (targetOffset < currentOffset) {
      _resultsScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } else if (targetOffset + itemExtent > currentOffset + viewportHeight) {
      _resultsScrollController.animateTo(
        targetOffset + itemExtent - viewportHeight,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _recordRecentQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;
    _recentQueries.removeWhere(
      (q) => q.toLowerCase() == trimmed.toLowerCase(),
    );
    _recentQueries.insert(0, trimmed);
    if (_recentQueries.length > 5) {
      _recentQueries.removeRange(5, _recentQueries.length);
    }
  }

  void _activateItem(SpotlightSearchItem item) {
    _recordRecentQuery(_queryController.text);

    switch (item.category) {
      case SpotlightSearchCategory.rider:
        final rider = item.rider;
        if (rider == null) return;
        Navigator.of(context).pop(SpotlightSelectionResult(item));
        if (widget.onNavigateToRider != null) {
          widget.onNavigateToRider!(rider);
        } else {
          _safeGoOrPush(
            AppRoutes.riderDetailPath(rider.id),
            extra: rider,
          );
        }
        break;

      case SpotlightSearchCategory.team:
        final team = item.team;
        if (team == null) return;
        if (widget.onNavigateToTeam != null) {
          Navigator.of(context).pop(SpotlightSelectionResult(item));
          widget.onNavigateToTeam!(team);
        } else {
          // Otwórz pełny profil wybranej drużyny bezpośrednio w oknie Spotlight
          setState(() {
            _inspectedTeam = team;
          });
        }
        break;

      case SpotlightSearchCategory.race:
        final race = item.race;
        if (race == null) return;
        Navigator.of(context).pop(SpotlightSelectionResult(item));
        if (widget.onNavigateToRace != null) {
          widget.onNavigateToRace!(race);
        } else {
          final isTodayActive =
              widget.careerSave.calendar.activeRaceId == race.id;
          _safeGoOrPush(
            isTodayActive ? AppRoutes.raceBriefing : AppRoutes.calendar,
          );
        }
        break;

      case SpotlightSearchCategory.climb:
        final climb = item.climb;
        if (climb == null) return;
        Navigator.of(context).pop(SpotlightSelectionResult(item));
        if (widget.onNavigateToClimb != null) {
          widget.onNavigateToClimb!(climb, item.race, item.stage);
        } else {
          _safeGoOrPush(AppRoutes.calendar);
        }
        break;

      case SpotlightSearchCategory.all:
        break;
    }
  }

  void _safeGoOrPush(String routePath, {Object? extra}) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      if (routePath.startsWith('/career/rider/')) {
        router.push(routePath, extra: extra);
      } else {
        router.go(routePath);
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_inspectedTeam != null) {
        setState(() => _inspectedTeam = null);
        _searchFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    if (_inspectedTeam != null) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _results.length) {
        _activateItem(_results[_highlightedIndex]);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 760;
              final bool showPreviewPane = constraints.maxWidth >= 860;
              final double modalWidth = isCompact
                  ? constraints.maxWidth - 20
                  : math.min(980.0, constraints.maxWidth - 48);
              final double modalMaxHeight = isCompact
                  ? constraints.maxHeight - 24
                  : math.min(680.0, constraints.maxHeight - 56);

              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 24,
                    vertical: isCompact ? 12 : 28,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: modalWidth,
                        constraints: BoxConstraints(
                          maxHeight: modalMaxHeight,
                          minHeight: isCompact ? 340 : 420,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.borderColor,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 36,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: _inspectedTeam != null
                              ? _buildTeamProfileDrilldown(
                                  team: _inspectedTeam!,
                                  isCompact: isCompact,
                                )
                              : _buildSearchWorkspace(
                                  isCompact: isCompact,
                                  showPreviewPane: showPreviewPane,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchWorkspace({
    required bool isCompact,
    required bool showPreviewPane,
  }) {
    final highlightedItem =
        (_highlightedIndex >= 0 && _highlightedIndex < _results.length)
        ? _results[_highlightedIndex]
        : null;

    return Column(
      key: const ValueKey('spotlight_search_workspace'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchInputHeader(isCompact: isCompact),
        _buildFilterBar(isCompact: isCompact),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
        Expanded(
          child: showPreviewPane
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 56,
                      child: _buildResultsList(isCompact: isCompact),
                    ),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppTheme.borderColor,
                    ),
                    Expanded(
                      flex: 44,
                      child: highlightedItem != null
                          ? _buildPreviewPane(highlightedItem)
                          : _buildEmptyPreviewState(),
                    ),
                  ],
                )
              : _buildResultsList(isCompact: isCompact),
        ),
        _buildFooterHints(isCompact: isCompact),
      ],
    );
  }

  Widget _buildSearchInputHeader({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 18,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _queryController,
              focusNode: _searchFocusNode,
              onChanged: (_) => _recomputeResults(),
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              cursorColor: AppColors.goldAccent,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                hintText: isCompact
                    ? 'Szukaj kolarzy, drużyn, wyścigów, podjazdów...'
                    : 'Szukaj kolarzy (800+), 53 drużyn, wyścigów i podjazdów...',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (_queryController.text.isNotEmpty) ...[
            _SpotlightIconAction(
              icon: Icons.close_rounded,
              tooltip: 'Wyczyść zapytanie',
              onTap: () {
                _queryController.clear();
                _recomputeResults();
                _searchFocusNode.requestFocus();
              },
            ),
            const SizedBox(width: 6),
          ],
          _SpotlightIconAction(
            icon: Icons.keyboard_return_rounded,
            label: isCompact ? null : 'ESC',
            tooltip: 'Zamknij (Esc)',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar({required bool isCompact}) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 18,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SpotlightSearchCategory.values.map((cat) {
                final count = _categoryCounts[cat] ?? 0;
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SpotlightCategoryChip(
                    category: cat,
                    count: count,
                    isSelected: isSelected,
                    onTap: () => _onCategorySelected(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_queryController.text.isEmpty && _recentQueries.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Ostatnie:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ..._recentQueries.map(
                    (recent) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _RecentQueryPill(
                        label: recent,
                        onTap: () {
                          _queryController.text = recent;
                          _queryController.selection = TextSelection.collapsed(
                            offset: recent.length,
                          );
                          _recomputeResults();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsList({required bool isCompact}) {
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 44,
                color: AppColors.textSecondary.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 12),
              Text(
                'Brak wyników dla "${_queryController.text}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Spróbuj wpisać nazwisko kolarza, nazwę ekipy WorldTour/ProTeam, wyścigu lub podjazdu (np. Galibier, HC).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _resultsScrollController,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: 8,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        final isHighlighted = index == _highlightedIndex;
        return _SpotlightResultTile(
          item: item,
          isHighlighted: isHighlighted,
          isCompact: isCompact,
          onHover: () {
            if (_highlightedIndex != index) {
              setState(() => _highlightedIndex = index);
            }
          },
          onTap: () => _activateItem(item),
        );
      },
    );
  }

  Widget _buildEmptyPreviewState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Wybierz element z listy po lewej stronie, aby zobaczyć podgląd profilu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPane(SpotlightSearchItem item) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.55),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: switch (item.category) {
                SpotlightSearchCategory.rider => _buildRiderPreview(item),
                SpotlightSearchCategory.team => _buildTeamPreview(item),
                SpotlightSearchCategory.race => _buildRacePreview(item),
                SpotlightSearchCategory.climb => _buildClimbPreview(item),
                SpotlightSearchCategory.all => const SizedBox.shrink(),
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildPreviewActionFooter(item),
        ],
      ),
    );
  }

  Widget _buildPreviewActionFooter(SpotlightSearchItem item) {
    switch (item.category) {
      case SpotlightSearchCategory.rider:
        return _PrimaryActionButton(
          label: 'Otwórz Profil Kolarza',
          icon: Icons.open_in_new_rounded,
          onPressed: () => _activateItem(item),
        );
      case SpotlightSearchCategory.team:
        return _PrimaryActionButton(
          label: 'Otwórz Profil Drużyny',
          icon: Icons.groups_rounded,
          onPressed: () => _activateItem(item),
        );
      case SpotlightSearchCategory.race:
        final race = item.race;
        final isTodayActive =
            race != null && widget.careerSave.calendar.activeRaceId == race.id;
        return _PrimaryActionButton(
          label: isTodayActive
              ? 'Przejdź do Odprawy Startowej'
              : 'Otwórz w Kalendarzu UCI',
          icon: isTodayActive
              ? Icons.play_arrow_rounded
              : Icons.calendar_month_rounded,
          onPressed: () => _activateItem(item),
        );
      case SpotlightSearchCategory.climb:
        return _PrimaryActionButton(
          label: 'Zobacz Wyścig w Kalendarzu',
          icon: Icons.terrain_rounded,
          onPressed: () => _activateItem(item),
        );
      case SpotlightSearchCategory.all:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRiderPreview(SpotlightSearchItem item) {
    final rider = item.rider!;
    final team = item.team;
    final ovr = rider.overallRating;
    final wKg = rider.physiology.wattsPerKg;
    final tsb = rider.health.trainingStressBalance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreviewCategoryHeader(
          category: SpotlightSearchCategory.rider,
          countryIso: rider.nationalityIso,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _OvrBadge(ovr: ovr),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.fullName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    team?.name ?? 'Wolny Agent',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: team?.id == widget.careerSave.playerTeamId
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricBox(
              label: 'Specjalizacja',
              value: rider.specialization.displayName,
            ),
            _MetricBox(
              label: 'FTP / Masa',
              value:
                  '${rider.physiology.ftpWatts} W (${wKg.toStringAsFixed(2)} W/kg)',
            ),
            _MetricBox(
              label: 'Wiek / Potencjał',
              value: '${rider.age} lat • POT ${rider.potential}',
            ),
            _MetricBox(
              label: 'Forma (TSB) / UCI',
              value:
                  '${tsb >= 0 ? "+" : ""}${tsb.toStringAsFixed(0)} • ${rider.careerPointsUci} pkt',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SkillBarRow(label: 'Pozycja Aero', value: rider.skills.aeroPositioning),
        _SkillBarRow(label: 'Pozycja TT', value: rider.skills.timeTrialPositioning),
        _SkillBarRow(label: 'Zjazdy', value: rider.skills.descending),
        _SkillBarRow(label: 'Taktyka (IQ)', value: rider.skills.raceIq),
        _SkillBarRow(label: 'Bruki', value: rider.skills.cobbles),
      ],
    );
  }

  Widget _buildTeamPreview(SpotlightSearchItem item) {
    final team = item.team!;
    final riders = _index.ridersByTeamId[team.id] ?? const <Rider>[];
    final sortedRiders = [...riders]
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
    final topRiders = sortedRiders.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreviewCategoryHeader(
          category: SpotlightSearchCategory.team,
          countryIso: team.countryIso,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _TeamColorShield(team: team, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    team.division.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.goldAccent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricBox(
              label: 'Punkty UCI',
              value: '${team.uciPointsSeason} pkt',
            ),
            _MetricBox(
              label: 'Liczba kolarzy',
              value: '${team.rosterRiderIds.length}',
            ),
            _MetricBox(
              label: 'Sprzęt (Rowery)',
              value: team.bikeDeal.manufacturerName,
            ),
            _MetricBox(
              label: 'Sztab (Śr.)',
              value: '${team.staff.averageStaffLevel.toStringAsFixed(0)} / 100',
            ),
          ],
        ),
        if (topRiders.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'LIDERZY ZESPOŁU',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          ...topRiders.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  PcsCountryFlagBadge(
                    isoCode: r.nationalityIso,
                    width: 18,
                    height: 12,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'OVR ${r.overallRating}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.goldAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRacePreview(SpotlightSearchItem item) {
    final race = item.race!;
    final isPlayerIn = race.participatingTeamIds.contains(
      widget.careerSave.playerTeamId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreviewCategoryHeader(
          category: SpotlightSearchCategory.race,
          countryIso: race.countryIso,
        ),
        const SizedBox(height: 12),
        Text(
          race.name,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${SpotlightSearchIndex._raceCategoryLabel(race.uciCategory)} • '
          '${isPlayerIn ? "Twoja drużyna na liście startowej" : "Poza składem drużyny"}',
          style: TextStyle(
            fontFamily: 'Inter',
            color: isPlayerIn ? AppColors.statusSuccess : AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricBox(
              label: 'Dystans łączny',
              value: '${race.totalRaceDistanceKm.toStringAsFixed(0)} km',
            ),
            _MetricBox(
              label: 'Przewyższenie',
              value: '${race.totalRaceElevationGainM.round()} m',
            ),
            _MetricBox(
              label: 'Etapy',
              value: '${race.stages.length}',
            ),
            _MetricBox(
              label: 'Pula nagród',
              value: Formatters.formatCurrency(race.prizePoolEur),
            ),
          ],
        ),
        if (race.stages.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'WYBRANE ETAPY',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          ...race.stages.take(4).map(
                (st) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        'E${st.stageNumber}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.accentBlue,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          st.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${st.totalDistanceKm.round()} km',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildClimbPreview(SpotlightSearchItem item) {
    final climb = item.climb!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreviewCategoryHeader(
          category: SpotlightSearchCategory.climb,
          countryIso: climb.countryIso,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: climb.categoryColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: climb.categoryColor.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                'KAT. ${climb.categoryLabel}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: climb.categoryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                climb.name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        if (climb.linkedRaceName != null) ...[
          const SizedBox(height: 6),
          Text(
            '${climb.linkedRaceName}${climb.linkedStageNumber != null ? " • Etap ${climb.linkedStageNumber}" : ""}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.goldAccent,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricBox(
              label: 'Długość',
              value: '${climb.lengthKm.toStringAsFixed(1)} km',
            ),
            _MetricBox(
              label: 'Śr. nachylenie',
              value: '${climb.avgGradientPercent.toStringAsFixed(1)}%',
            ),
            _MetricBox(
              label: 'Maks. nachylenie',
              value: '${climb.maxGradientPercent.toStringAsFixed(1)}%',
            ),
            _MetricBox(
              label: 'Szczyt / Przewyższenie',
              value:
                  '${climb.summitElevationM.round()} m • +${climb.elevationGainM.round()} m',
            ),
          ],
        ),
      ],
    );
  }

  /// Wbudowany ekran profilu drużyny dla wszystkich 53 zespołów z możliwością
  /// natychmiastowego przejścia do profilu dowolnego z jej kolarzy.
  Widget _buildTeamProfileDrilldown({
    required CyclingTeam team,
    required bool isCompact,
  }) {
    final riders = [...(_index.ridersByTeamId[team.id] ?? const <Rider>[])]
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));
    final isPlayerTeam = team.id == widget.careerSave.playerTeamId;

    return Column(
      key: ValueKey('team_profile_${team.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 18,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              _SpotlightIconAction(
                icon: Icons.arrow_back_rounded,
                label: isCompact ? null : 'Wróć',
                tooltip: 'Powrót do wyszukiwania (Esc)',
                onTap: () {
                  setState(() => _inspectedTeam = null);
                  _searchFocusNode.requestFocus();
                },
              ),
              const SizedBox(width: 12),
              _TeamColorShield(team: team, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${team.division.label} • ${team.countryIso} • ${riders.length} kolarzy',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPlayerTeam) ...[
                const SizedBox(width: 8),
                _PrimaryActionButton(
                  label: isCompact ? 'Kadra' : 'Przejdź do Kadry',
                  icon: Icons.people_alt_rounded,
                  compact: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _safeGoOrPush(AppRoutes.roster);
                  },
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricBox(
                label: 'Punkty UCI',
                value: '${team.uciPointsSeason} pkt',
              ),
              _MetricBox(
                label: 'Budżet',
                value: Formatters.formatCurrency(team.cashBalanceEur),
              ),
              _MetricBox(
                label: 'Producent Rowerów',
                value: team.bikeDeal.manufacturerName,
              ),
              _MetricBox(
                label: 'Sztab (Śr.)',
                value: '${team.staff.averageStaffLevel.toStringAsFixed(0)} / 100',
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
        Expanded(
          child: riders.isEmpty
              ? const Center(
                  child: Text(
                    'Brak przypisanych kolarzy w kadrze tej drużyny.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  itemCount: riders.length,
                  itemBuilder: (context, idx) {
                    final rider = riders[idx];
                    return _TeamRiderRow(
                      rider: rider,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (widget.onNavigateToRider != null) {
                          widget.onNavigateToRider!(rider);
                        } else {
                          _safeGoOrPush(
                            AppRoutes.riderDetailPath(rider.id),
                            extra: rider,
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFooterHints({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 18,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Indeks: ${widget.careerSave.riders.length} kolarzy • ${widget.careerSave.teams.length} drużyn • ${widget.careerSave.calendar.races.length} wyścigów',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 12),
            const _KeyHintBadge(keys: '↑↓', label: 'Nawigacja'),
            const SizedBox(width: 10),
            const _KeyHintBadge(keys: 'Enter', label: 'Otwórz profil'),
            const SizedBox(width: 10),
            const _KeyHintBadge(keys: 'Esc', label: 'Zamknij'),
          ],
        ],
      ),
    );
  }
}

class _SpotlightCategoryChip extends StatefulWidget {
  final SpotlightSearchCategory category;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpotlightCategoryChip({
    required this.category,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SpotlightCategoryChip> createState() => _SpotlightCategoryChipState();
}

class _SpotlightCategoryChipState extends State<_SpotlightCategoryChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.category.accentColor;
    final bgColor = widget.isSelected
        ? accent.withValues(alpha: 0.18)
        : _pressed
        ? AppColors.surfaceLight
        : _hovered
        ? AppColors.surfaceLight.withValues(alpha: 0.85)
        : AppColors.background.withValues(alpha: 0.65);

    final borderColor = widget.isSelected
        ? accent
        : _focused
        ? AppColors.goldAccent
        : _hovered
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.category.icon,
                size: 14,
                color: widget.isSelected ? accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.category.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? accent.withValues(alpha: 0.24)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.count}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: widget.isSelected ? accent : AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightResultTile extends StatefulWidget {
  final SpotlightSearchItem item;
  final bool isHighlighted;
  final bool isCompact;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _SpotlightResultTile({
    required this.item,
    required this.isHighlighted,
    required this.isCompact,
    required this.onHover,
    required this.onTap,
  });

  @override
  State<_SpotlightResultTile> createState() => _SpotlightResultTileState();
}

class _SpotlightResultTileState extends State<_SpotlightResultTile> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.item.category.accentColor;
    final active = widget.isHighlighted || _hovered;
    final bgColor = _pressed
        ? AppColors.surfaceLight
        : widget.isHighlighted
        ? accent.withValues(alpha: 0.13)
        : _hovered
        ? AppColors.surfaceLight.withValues(alpha: 0.6)
        : Colors.transparent;

    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.isHighlighted
        ? accent.withValues(alpha: 0.55)
        : _hovered
        ? AppTheme.borderColor
        : Colors.transparent;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) {
        setState(() => _hovered = v);
        if (v) widget.onHover();
      },
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 10 : 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            children: [
              _buildLeadingVisual(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            widget.item.category.badgeLabel,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: accent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.item.primaryMetric,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: active ? accent : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.secondaryMetric,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontFeatures: [FontFeature.tabularFigures()],
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

  Widget _buildLeadingVisual() {
    if (widget.item.team != null &&
        widget.item.category == SpotlightSearchCategory.team) {
      return _TeamColorShield(team: widget.item.team!, size: 32);
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: widget.item.countryIso.isNotEmpty
            ? PcsCountryFlagBadge(
                isoCode: widget.item.countryIso,
                width: 20,
                height: 14,
              )
            : Icon(
                widget.item.category.icon,
                size: 16,
                color: widget.item.category.accentColor,
              ),
      ),
    );
  }
}

class _TeamRiderRow extends StatefulWidget {
  final Rider rider;
  final VoidCallback onTap;

  const _TeamRiderRow({required this.rider, required this.onTap});

  @override
  State<_TeamRiderRow> createState() => _TeamRiderRowState();
}

class _TeamRiderRowState extends State<_TeamRiderRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final rider = widget.rider;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surfaceLight
                : AppColors.background.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : _hovered
                  ? AppColors.accentBlue.withValues(alpha: 0.5)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              PcsCountryFlagBadge(
                isoCode: rider.nationalityIso,
                width: 20,
                height: 14,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${rider.specialization.displayName} • ${rider.age} lat',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'OVR ${rider.overallRating}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.goldAccent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightIconAction extends StatefulWidget {
  final IconData icon;
  final String? label;
  final String tooltip;
  final VoidCallback? onTap;

  const _SpotlightIconAction({
    required this.icon,
    required this.tooltip,
    this.label,
    this.onTap,
  });

  @override
  State<_SpotlightIconAction> createState() => _SpotlightIconActionState();
}

class _SpotlightIconActionState extends State<_SpotlightIconAction> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        mouseCursor:
            disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel:
              disabled ? null : () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: disabled
                  ? AppColors.background.withValues(alpha: 0.3)
                  : _pressed
                  ? AppColors.surface
                  : _hovered
                  ? AppColors.background
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : _hovered
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppTheme.borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: disabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : AppColors.textSecondary,
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    widget.label!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

class _PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool compact;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final bgColor = disabled
        ? AppColors.surfaceLight
        : _pressed
        ? AppColors.primaryAccent.withValues(alpha: 0.85)
        : _hovered
        ? AppColors.primaryAccent.withValues(alpha: 0.95)
        : AppColors.primaryAccent;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 16,
            vertical: widget.compact ? 8 : 11,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : AppColors.goldAccent.withValues(alpha: _hovered ? 0.8 : 0.45),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: disabled ? AppColors.textSecondary : AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color:
                      disabled ? AppColors.textSecondary : AppColors.textPrimary,
                  fontSize: widget.compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCategoryHeader extends StatelessWidget {
  final SpotlightSearchCategory category;
  final String countryIso;

  const _PreviewCategoryHeader({
    required this.category,
    required this.countryIso,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: category.accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: category.accentColor.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            category.badgeLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              color: category.accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const Spacer(),
        if (countryIso.isNotEmpty) ...[
          PcsCountryFlagBadge(isoCode: countryIso, width: 22, height: 15),
          const SizedBox(width: 6),
          Text(
            countryIso.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _OvrBadge extends StatelessWidget {
  final int ovr;
  const _OvrBadge({required this.ovr});

  @override
  Widget build(BuildContext context) {
    final Color color = ovr >= 85
        ? AppColors.goldAccent
        : ovr >= 76
        ? AppColors.statusSuccess
        : AppColors.accentBlue;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.65), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$ovr',
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            'OVR',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColorShield extends StatelessWidget {
  final CyclingTeam team;
  final double size;

  const _TeamColorShield({required this.team, required this.size});

  Color _parseHex(String hex, Color fallback) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final parsed = int.tryParse('FF$clean', radix: 16);
      if (parsed != null) return Color(parsed);
    } else if (clean.length == 8) {
      final parsed = int.tryParse(clean, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final primary = _parseHex(team.primaryJerseyColorHex, AppColors.primaryAccent);
    final secondary = _parseHex(
      team.secondaryJerseyColorHex,
      AppColors.goldAccent,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Icon(
        Icons.shield_rounded,
        color: Colors.white.withValues(alpha: 0.92),
        size: size * 0.56,
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 135),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillBarRow extends StatelessWidget {
  final String label;
  final int value;

  const _SkillBarRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    final Color barColor = clamped >= 85
        ? AppColors.goldAccent
        : clamped >= 72
        ? AppColors.statusSuccess
        : AppColors.accentBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: clamped / 100.0,
                minHeight: 6,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 26,
            child: Text(
              '$clamped',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                color: barColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentQueryPill extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _RecentQueryPill({required this.label, required this.onTap});

  @override
  State<_RecentQueryPill> createState() => _RecentQueryPillState();
}

class _RecentQueryPillState extends State<_RecentQueryPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceLight : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyHintBadge extends StatelessWidget {
  final String keys;
  final String label;

  const _KeyHintBadge({required this.keys, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Text(
            keys,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
