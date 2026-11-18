// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Rodzaj tytułu mistrzowskiego uprawniającego do spersonalizowanego sprzętu 3D.
enum ChampionTitleKind {
  /// Aktualny Mistrz Świata UCI ze startu wspólnego.
  uciWorldChampionRoad(
    polishLabel: 'Mistrz Świata UCI (Start Wspólny)',
    englishLabel: 'UCI World Champion (Road)',
    shortBadge: 'WC ROAD',
    validityYears: 1,
  ),

  /// Aktualny Mistrz Świata UCI w jeździe indywidualnej na czas.
  uciWorldChampionItt(
    polishLabel: 'Mistrz Świata UCI (ITT)',
    englishLabel: 'UCI World Champion (ITT)',
    shortBadge: 'WC ITT',
    validityYears: 1,
  ),

  /// Aktualny Mistrz Olimpijski ze startu wspólnego (sprzęt ważny 4 lata).
  olympicChampionRoad(
    polishLabel: 'Mistrz Olimpijski (Start Wspólny)',
    englishLabel: 'Olympic Champion (Road)',
    shortBadge: 'OG ROAD',
    validityYears: 4,
  ),

  /// Aktualny Mistrz Olimpijski w jeździe indywidualnej na czas (sprzęt ważny 4 lata).
  olympicChampionItt(
    polishLabel: 'Mistrz Olimpijski (ITT)',
    englishLabel: 'Olympic Champion (ITT)',
    shortBadge: 'OG ITT',
    validityYears: 4,
  );

  final String polishLabel;
  final String englishLabel;
  final String shortBadge;
  final int validityYears;

  const ChampionTitleKind({
    required this.polishLabel,
    required this.englishLabel,
    required this.shortBadge,
    required this.validityYears,
  });

  bool get isOlympic =>
      this == ChampionTitleKind.olympicChampionRoad ||
      this == ChampionTitleKind.olympicChampionItt;

  bool get isWorldChampion =>
      this == ChampionTitleKind.uciWorldChampionRoad ||
      this == ChampionTitleKind.uciWorldChampionItt;

  String toJson() => name;

  static ChampionTitleKind fromJson(String value) {
    return ChampionTitleKind.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionTitleKind.uciWorldChampionRoad,
    );
  }
}

/// Dyscyplina wyścigu stosowana przy dopasowywaniu sprzętu 3D.
enum ChampionGearRaceDiscipline {
  roadRace('Start wspólny', 'Road Race'),
  individualTimeTrial('Jazda na czas (ITT)', 'Individual Time Trial'),
  allRaces('Wszystkie wyścigi', 'All Races');

  final String polishLabel;
  final String englishLabel;

  const ChampionGearRaceDiscipline(this.polishLabel, this.englishLabel);

  String toJson() => name;

  static ChampionGearRaceDiscipline fromJson(String value) {
    return ChampionGearRaceDiscipline.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionGearRaceDiscipline.allRaces,
    );
  }
}

/// Styl malowania ramy roweru w silniku 3D.
enum ChampionFrameLivery {
  standardTeamFrame('Standardowa rama drużyny'),
  worldChampionWhiteRainbowSeatTube(
    'Biała rama z tęczowymi pasami na rurze podsiodłowej',
  ),
  olympicChampionGoldAccents('Rama ze złotymi detalami mistrza olimpijskiego'),
  dualWorldAndOlympicLivery(
    'Biała rama WC z tęczą i złotymi detalami olimpijskimi',
  );

  final String polishDescription;

  const ChampionFrameLivery(this.polishDescription);

  String toJson() => name;

  static ChampionFrameLivery fromJson(String value) {
    return ChampionFrameLivery.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionFrameLivery.standardTeamFrame,
    );
  }
}

/// Styl kasku kolarza w silniku 3D.
enum ChampionHelmetLivery {
  standardTeamHelmet('Standardowy kask drużyny'),
  worldChampionWhiteRainbow('Biały kask z tęczowym paskiem UCI'),
  olympicGoldHelmet('Złoty Kask Olimpijski (Gold Olympic Helmet)');

  final String polishDescription;

  const ChampionHelmetLivery(this.polishDescription);

  String toJson() => name;

  static ChampionHelmetLivery fromJson(String value) {
    return ChampionHelmetLivery.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionHelmetLivery.standardTeamHelmet,
    );
  }
}

/// Styl owijki kierownicy w silniku 3D.
enum ChampionHandlebarTapeLivery {
  standardDarkTape('Standardowa czarna owijka'),
  worldChampionWhiteTape('Biała owijka Mistrza Świata'),
  olympicGoldTape('Złota owijka kierownicy Mistrza Olimpijskiego');

  final String polishDescription;

  const ChampionHandlebarTapeLivery(this.polishDescription);

  String toJson() => name;

  static ChampionHandlebarTapeLivery fromJson(String value) {
    return ChampionHandlebarTapeLivery.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionHandlebarTapeLivery.standardDarkTape,
    );
  }
}

/// Styl butów kolarskich w silniku 3D.
enum ChampionShoesLivery {
  standardDarkShoes('Standardowe buty drużynowe'),
  worldChampionWhiteShoes('Białe buty Mistrza Świata UCI'),
  olympicGoldDetailShoes('Buty ze złotymi detalami olimpijskimi');

  final String polishDescription;

  const ChampionShoesLivery(this.polishDescription);

  String toJson() => name;

  static ChampionShoesLivery fromJson(String value) {
    return ChampionShoesLivery.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionShoesLivery.standardDarkShoes,
    );
  }
}

/// Nadanie spersonalizowanego sprzętu mistrzowskiego dla konkretnego kolarza.
class ChampionCustomGearGrant {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final String teamName;
  final ChampionTitleKind titleKind;
  final ChampionGearRaceDiscipline discipline;
  final int yearWon;
  final int validUntilYear;
  final bool visibleInAllRaces;
  final int moraleBonus;
  final int prestigeBonus;
  final double sponsorMediaMultiplier;

  const ChampionCustomGearGrant({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.teamName,
    required this.titleKind,
    required this.discipline,
    required this.yearWon,
    required this.validUntilYear,
    required this.visibleInAllRaces,
    this.moraleBonus = 8,
    this.prestigeBonus = 15,
    this.sponsorMediaMultiplier = 1.30,
  });

  /// Czy przywilej sprzętu mistrzowskiego jest aktywny w danym roku sezonu.
  bool isActiveInYear(int year) => year >= yearWon && year < validUntilYear;

  /// Pozostałe lata ważności sprzętu (np. 4 lata dla Mistrza Olimpijskiego).
  int remainingYears(int currentYear) {
    if (!isActiveInYear(currentYear)) return 0;
    return validUntilYear - currentYear;
  }

  /// Czy sprzęt powinien być widoczny w konkretnym wyścigu danego roku.
  bool appliesToRace({
    required int year,
    required ChampionGearRaceDiscipline raceDiscipline,
  }) {
    if (!isActiveInYear(year)) return false;
    if (visibleInAllRaces || titleKind.isOlympic) {
      return true;
    }
    if (raceDiscipline == ChampionGearRaceDiscipline.allRaces) {
      return true;
    }
    return discipline == raceDiscipline;
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'nationalityIso': nationalityIso,
        'teamName': teamName,
        'titleKind': titleKind.toJson(),
        'discipline': discipline.toJson(),
        'yearWon': yearWon,
        'validUntilYear': validUntilYear,
        'visibleInAllRaces': visibleInAllRaces,
        'moraleBonus': moraleBonus,
        'prestigeBonus': prestigeBonus,
        'sponsorMediaMultiplier': sponsorMediaMultiplier,
      };

  factory ChampionCustomGearGrant.fromJson(Map<String, dynamic> json) {
    return ChampionCustomGearGrant(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      nationalityIso: json['nationalityIso'] as String? ?? 'INT',
      teamName: json['teamName'] as String? ?? 'Pro Team',
      titleKind: ChampionTitleKind.fromJson(json['titleKind'] as String),
      discipline: ChampionGearRaceDiscipline.fromJson(
        json['discipline'] as String? ?? 'allRaces',
      ),
      yearWon: (json['yearWon'] as num).toInt(),
      validUntilYear: (json['validUntilYear'] as num).toInt(),
      visibleInAllRaces: json['visibleInAllRaces'] as bool? ?? true,
      moraleBonus: (json['moraleBonus'] as num?)?.toInt() ?? 8,
      prestigeBonus: (json['prestigeBonus'] as num?)?.toInt() ?? 15,
      sponsorMediaMultiplier:
          (json['sponsorMediaMultiplier'] as num?)?.toDouble() ?? 1.30,
    );
  }
}

/// Rozwiązana specyfikacja wizualna 3D sprzętu mistrzowskiego dla renderera peletonu.
class ChampionGear3dVisualSpec {
  static const List<String> uciRainbowBandHexes = [
    '#0085C7', // Niebieski
    '#F4C300', // Żółty
    '#111827', // Czarny
    '#009F3D', // Zielony
    '#DF0024', // Czerwony
  ];

  final String riderId;
  final bool hasCustomGear;
  final ChampionFrameLivery frameLivery;
  final ChampionHelmetLivery helmetLivery;
  final ChampionHandlebarTapeLivery handlebarTapeLivery;
  final ChampionShoesLivery shoesLivery;
  final String framePrimaryHex;
  final String frameAccentHex;
  final bool hasSeatTubeRainbowBands;
  final bool hasGoldFrameDetails;
  final String helmetPrimaryHex;
  final bool hasHelmetRainbowBand;
  final bool isGoldOlympicHelmet;
  final String handlebarTapeHex;
  final String shoesHex;
  final List<ChampionTitleKind> activeTitles;
  final int? validUntilYear;
  final double sponsorMediaMultiplier;

  const ChampionGear3dVisualSpec({
    required this.riderId,
    required this.hasCustomGear,
    required this.frameLivery,
    required this.helmetLivery,
    required this.handlebarTapeLivery,
    required this.shoesLivery,
    required this.framePrimaryHex,
    required this.frameAccentHex,
    required this.hasSeatTubeRainbowBands,
    required this.hasGoldFrameDetails,
    required this.helmetPrimaryHex,
    required this.hasHelmetRainbowBand,
    required this.isGoldOlympicHelmet,
    required this.handlebarTapeHex,
    required this.shoesHex,
    required this.activeTitles,
    this.validUntilYear,
    this.sponsorMediaMultiplier = 1.0,
  });

  factory ChampionGear3dVisualSpec.standard(String riderId) {
    return ChampionGear3dVisualSpec(
      riderId: riderId,
      hasCustomGear: false,
      frameLivery: ChampionFrameLivery.standardTeamFrame,
      helmetLivery: ChampionHelmetLivery.standardTeamHelmet,
      handlebarTapeLivery: ChampionHandlebarTapeLivery.standardDarkTape,
      shoesLivery: ChampionShoesLivery.standardDarkShoes,
      framePrimaryHex: '#1E293B',
      frameAccentHex: '#334155',
      hasSeatTubeRainbowBands: false,
      hasGoldFrameDetails: false,
      helmetPrimaryHex: '#181B22',
      hasHelmetRainbowBand: false,
      isGoldOlympicHelmet: false,
      handlebarTapeHex: '#111827',
      shoesHex: '#111827',
      activeTitles: const [],
      validUntilYear: null,
      sponsorMediaMultiplier: 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'hasCustomGear': hasCustomGear,
        'frameLivery': frameLivery.toJson(),
        'helmetLivery': helmetLivery.toJson(),
        'handlebarTapeLivery': handlebarTapeLivery.toJson(),
        'shoesLivery': shoesLivery.toJson(),
        'framePrimaryHex': framePrimaryHex,
        'frameAccentHex': frameAccentHex,
        'hasSeatTubeRainbowBands': hasSeatTubeRainbowBands,
        'hasGoldFrameDetails': hasGoldFrameDetails,
        'helmetPrimaryHex': helmetPrimaryHex,
        'hasHelmetRainbowBand': hasHelmetRainbowBand,
        'isGoldOlympicHelmet': isGoldOlympicHelmet,
        'handlebarTapeHex': handlebarTapeHex,
        'shoesHex': shoesHex,
        'activeTitles': activeTitles.map((e) => e.toJson()).toList(),
        'validUntilYear': validUntilYear,
        'sponsorMediaMultiplier': sponsorMediaMultiplier,
      };

  factory ChampionGear3dVisualSpec.fromJson(Map<String, dynamic> json) {
    return ChampionGear3dVisualSpec(
      riderId: json['riderId'] as String,
      hasCustomGear: json['hasCustomGear'] as bool? ?? false,
      frameLivery: ChampionFrameLivery.fromJson(
        json['frameLivery'] as String? ?? 'standardTeamFrame',
      ),
      helmetLivery: ChampionHelmetLivery.fromJson(
        json['helmetLivery'] as String? ?? 'standardTeamHelmet',
      ),
      handlebarTapeLivery: ChampionHandlebarTapeLivery.fromJson(
        json['handlebarTapeLivery'] as String? ?? 'standardDarkTape',
      ),
      shoesLivery: ChampionShoesLivery.fromJson(
        json['shoesLivery'] as String? ?? 'standardDarkShoes',
      ),
      framePrimaryHex: json['framePrimaryHex'] as String? ?? '#1E293B',
      frameAccentHex: json['frameAccentHex'] as String? ?? '#334155',
      hasSeatTubeRainbowBands:
          json['hasSeatTubeRainbowBands'] as bool? ?? false,
      hasGoldFrameDetails: json['hasGoldFrameDetails'] as bool? ?? false,
      helmetPrimaryHex: json['helmetPrimaryHex'] as String? ?? '#181B22',
      hasHelmetRainbowBand: json['hasHelmetRainbowBand'] as bool? ?? false,
      isGoldOlympicHelmet: json['isGoldOlympicHelmet'] as bool? ?? false,
      handlebarTapeHex: json['handlebarTapeHex'] as String? ?? '#111827',
      shoesHex: json['shoesHex'] as String? ?? '#111827',
      activeTitles: (json['activeTitles'] as List<dynamic>? ?? const [])
          .map((e) => ChampionTitleKind.fromJson(e as String))
          .toList(),
      validUntilYear: (json['validUntilYear'] as num?)?.toInt(),
      sponsorMediaMultiplier:
          (json['sponsorMediaMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Raport oceny sprzętu mistrzowskiego w danym sezonie.
class ChampionCustomGearEvaluationReport {
  final int seasonYear;
  final int totalGrants;
  final int activeWorldChampionsCount;
  final int activeOlympicChampionsCount;
  final double averageSponsorMediaMultiplier;
  final Map<String, ChampionGear3dVisualSpec> activeSpecsByRiderId;

  const ChampionCustomGearEvaluationReport({
    required this.seasonYear,
    required this.totalGrants,
    required this.activeWorldChampionsCount,
    required this.activeOlympicChampionsCount,
    required this.averageSponsorMediaMultiplier,
    required this.activeSpecsByRiderId,
  });
}

/// Główny serwis personalizacji sprzętu mistrzowskiego w 3D:
/// - Mistrz Świata UCI: biała rama z tęczowymi pasami na rurze podsiodłowej,
///   biały kask z tęczą oraz białe buty.
/// - Mistrz Olimpijski: Złoty Kask Olimpijski (`Gold Olympic Helmet`),
///   złota owijka kierownicy oraz złote detale na ramie, widoczne we wszystkich
///   wyścigach przez kolejne 4 lata.
class CyclistOlympicAndWorldChampionCustomGear {
  const CyclistOlympicAndWorldChampionCustomGear();

  static const String uciWhiteHex = '#FFFFFF';
  static const String olympicGoldHex = '#D4AF37';
  static const String carbonFrameDarkHex = '#1E293B';

  /// Tworzy nadanie sprzętu Mistrza Świata UCI (ważne 1 rok do kolejnych MŚ).
  ChampionCustomGearGrant grantWorldChampionGear({
    required String riderId,
    required String riderName,
    required String nationalityIso,
    required String teamName,
    required int yearWon,
    ChampionGearRaceDiscipline discipline = ChampionGearRaceDiscipline.roadRace,
  }) {
    final titleKind = discipline == ChampionGearRaceDiscipline.individualTimeTrial
        ? ChampionTitleKind.uciWorldChampionItt
        : ChampionTitleKind.uciWorldChampionRoad;
    return ChampionCustomGearGrant(
      riderId: riderId,
      riderName: riderName,
      nationalityIso: nationalityIso,
      teamName: teamName,
      titleKind: titleKind,
      discipline: discipline,
      yearWon: yearWon,
      validUntilYear: yearWon + titleKind.validityYears,
      visibleInAllRaces: false,
      moraleBonus: 10,
      prestigeBonus: 22,
      sponsorMediaMultiplier: 1.40,
    );
  }

  /// Tworzy nadanie sprzętu Mistrza Olimpijskiego (widoczne we wszystkich wyścigach przez 4 lata).
  ChampionCustomGearGrant grantOlympicChampionGear({
    required String riderId,
    required String riderName,
    required String nationalityIso,
    required String teamName,
    required int olympicYearWon,
    ChampionGearRaceDiscipline discipline = ChampionGearRaceDiscipline.roadRace,
  }) {
    final titleKind = discipline == ChampionGearRaceDiscipline.individualTimeTrial
        ? ChampionTitleKind.olympicChampionItt
        : ChampionTitleKind.olympicChampionRoad;
    return ChampionCustomGearGrant(
      riderId: riderId,
      riderName: riderName,
      nationalityIso: nationalityIso,
      teamName: teamName,
      titleKind: titleKind,
      discipline: discipline,
      yearWon: olympicYearWon,
      validUntilYear: olympicYearWon + 4,
      visibleInAllRaces: true,
      moraleBonus: 12,
      prestigeBonus: 28,
      sponsorMediaMultiplier: 1.45,
    );
  }

  /// Wyznacza finalną specyfikację wizualną 3D dla wybranego kolarza w danym sezonie i wyścigu.
  ChampionGear3dVisualSpec resolveVisualSpecForRider({
    required String riderId,
    required List<ChampionCustomGearGrant> grants,
    required int currentYear,
    ChampionGearRaceDiscipline raceDiscipline =
        ChampionGearRaceDiscipline.roadRace,
    bool preferGoldHelmetWhenDualChampion = true,
  }) {
    final activeGrants = grants
        .where(
          (g) =>
              g.riderId == riderId &&
              g.appliesToRace(year: currentYear, raceDiscipline: raceDiscipline),
        )
        .toList();

    if (activeGrants.isEmpty) {
      return ChampionGear3dVisualSpec.standard(riderId);
    }

    final bool hasWorld = activeGrants.any((g) => g.titleKind.isWorldChampion);
    final bool hasOlympic = activeGrants.any((g) => g.titleKind.isOlympic);

    final ChampionFrameLivery frameLivery;
    final String framePrimaryHex;
    final String frameAccentHex;

    if (hasWorld && hasOlympic) {
      frameLivery = ChampionFrameLivery.dualWorldAndOlympicLivery;
      framePrimaryHex = uciWhiteHex;
      frameAccentHex = olympicGoldHex;
    } else if (hasWorld) {
      frameLivery = ChampionFrameLivery.worldChampionWhiteRainbowSeatTube;
      framePrimaryHex = uciWhiteHex;
      frameAccentHex = uciWhiteHex;
    } else {
      frameLivery = ChampionFrameLivery.olympicChampionGoldAccents;
      framePrimaryHex = carbonFrameDarkHex;
      frameAccentHex = olympicGoldHex;
    }

    final ChampionHelmetLivery helmetLivery;
    final String helmetPrimaryHex;
    final bool hasHelmetRainbowBand;
    final bool isGoldOlympicHelmet;

    if (hasOlympic && (!hasWorld || preferGoldHelmetWhenDualChampion)) {
      helmetLivery = ChampionHelmetLivery.olympicGoldHelmet;
      helmetPrimaryHex = olympicGoldHex;
      hasHelmetRainbowBand = false;
      isGoldOlympicHelmet = true;
    } else {
      helmetLivery = ChampionHelmetLivery.worldChampionWhiteRainbow;
      helmetPrimaryHex = uciWhiteHex;
      hasHelmetRainbowBand = true;
      isGoldOlympicHelmet = false;
    }

    final ChampionHandlebarTapeLivery tapeLivery;
    final String handlebarTapeHex;
    if (hasOlympic) {
      tapeLivery = ChampionHandlebarTapeLivery.olympicGoldTape;
      handlebarTapeHex = olympicGoldHex;
    } else {
      tapeLivery = ChampionHandlebarTapeLivery.worldChampionWhiteTape;
      handlebarTapeHex = uciWhiteHex;
    }

    final ChampionShoesLivery shoesLivery;
    final String shoesHex;
    if (hasWorld) {
      shoesLivery = ChampionShoesLivery.worldChampionWhiteShoes;
      shoesHex = uciWhiteHex;
    } else {
      shoesLivery = ChampionShoesLivery.olympicGoldDetailShoes;
      shoesHex = '#111827';
    }

    int maxValidUntil = activeGrants.first.validUntilYear;
    double bestMultiplier = 1.0;
    for (final grant in activeGrants) {
      if (grant.validUntilYear > maxValidUntil) {
        maxValidUntil = grant.validUntilYear;
      }
      if (grant.sponsorMediaMultiplier > bestMultiplier) {
        bestMultiplier = grant.sponsorMediaMultiplier;
      }
    }

    return ChampionGear3dVisualSpec(
      riderId: riderId,
      hasCustomGear: true,
      frameLivery: frameLivery,
      helmetLivery: helmetLivery,
      handlebarTapeLivery: tapeLivery,
      shoesLivery: shoesLivery,
      framePrimaryHex: framePrimaryHex,
      frameAccentHex: frameAccentHex,
      hasSeatTubeRainbowBands: hasWorld,
      hasGoldFrameDetails: hasOlympic,
      helmetPrimaryHex: helmetPrimaryHex,
      hasHelmetRainbowBand: hasHelmetRainbowBand,
      isGoldOlympicHelmet: isGoldOlympicHelmet,
      handlebarTapeHex: handlebarTapeHex,
      shoesHex: shoesHex,
      activeTitles: activeGrants.map((g) => g.titleKind).toList(),
      validUntilYear: maxValidUntil,
      sponsorMediaMultiplier: bestMultiplier,
    );
  }

  /// Tworzy mapę specyfikacji 3D dla całego peletonu wyścigowego.
  Map<String, ChampionGear3dVisualSpec> resolvePelotonVisualSpecs({
    required List<String> riderIds,
    required List<ChampionCustomGearGrant> grants,
    required int currentYear,
    ChampionGearRaceDiscipline raceDiscipline =
        ChampionGearRaceDiscipline.roadRace,
    bool preferGoldHelmetWhenDualChampion = true,
  }) {
    final result = <String, ChampionGear3dVisualSpec>{};
    for (final id in riderIds) {
      final spec = resolveVisualSpecForRider(
        riderId: id,
        grants: grants,
        currentYear: currentYear,
        raceDiscipline: raceDiscipline,
        preferGoldHelmetWhenDualChampion: preferGoldHelmetWhenDualChampion,
      );
      if (spec.hasCustomGear) {
        result[id] = spec;
      }
    }
    return result;
  }

  /// Generuje zbiorczy raport sprzętu mistrzowskiego w bieżącym sezonie.
  ChampionCustomGearEvaluationReport evaluateSeasonRosterGear({
    required List<ChampionCustomGearGrant> grants,
    required int seasonYear,
    ChampionGearRaceDiscipline raceDiscipline =
        ChampionGearRaceDiscipline.allRaces,
  }) {
    final uniqueRiderIds = grants.map((g) => g.riderId).toSet().toList();
    final activeSpecs = resolvePelotonVisualSpecs(
      riderIds: uniqueRiderIds,
      grants: grants,
      currentYear: seasonYear,
      raceDiscipline: raceDiscipline,
    );

    final activeGrants = grants.where((g) => g.isActiveInYear(seasonYear));
    final worldCount =
        activeGrants.where((g) => g.titleKind.isWorldChampion).length;
    final olympicCount =
        activeGrants.where((g) => g.titleKind.isOlympic).length;

    double avgMult = 1.0;
    if (activeSpecs.isNotEmpty) {
      final sum = activeSpecs.values.fold<double>(
        0.0,
        (prev, s) => prev + s.sponsorMediaMultiplier,
      );
      avgMult = sum / activeSpecs.length;
    }

    return ChampionCustomGearEvaluationReport(
      seasonYear: seasonYear,
      totalGrants: grants.length,
      activeWorldChampionsCount: worldCount,
      activeOlympicChampionsCount: olympicCount,
      averageSponsorMediaMultiplier: avgMult,
      activeSpecsByRiderId: activeSpecs,
    );
  }

  /// Zwraca domyślny zestaw mistrzów do podglądu i testów integracyjnych.
  List<ChampionCustomGearGrant> buildDefaultDemoGrants(int currentYear) {
    return [
      grantWorldChampionGear(
        riderId: 'wc_road_01',
        riderName: 'Tadej Pogačar',
        nationalityIso: 'SLO',
        teamName: 'UAE Team Emirates',
        yearWon: currentYear,
        discipline: ChampionGearRaceDiscipline.roadRace,
      ),
      grantOlympicChampionGear(
        riderId: 'og_road_01',
        riderName: 'Remco Evenepoel',
        nationalityIso: 'BEL',
        teamName: 'Soudal Quick-Step',
        olympicYearWon: currentYear,
        discipline: ChampionGearRaceDiscipline.roadRace,
      ),
      grantWorldChampionGear(
        riderId: 'wc_itt_01',
        riderName: 'Filippo Ganna',
        nationalityIso: 'ITA',
        teamName: 'INEOS Grenadiers',
        yearWon: currentYear,
        discipline: ChampionGearRaceDiscipline.individualTimeTrial,
      ),
    ];
  }
}

/// Stan Riverpod dla systemu personalizacji sprzętu mistrzowskiego.
class ChampionCustomGearState {
  final List<ChampionCustomGearGrant> grants;
  final String? selectedRiderId;
  final int currentSeasonYear;
  final ChampionGearRaceDiscipline activeRaceDiscipline;
  final bool preferGoldHelmetWhenDualChampion;
  final ChampionCustomGearEvaluationReport report;
  final bool isReadOnly;

  const ChampionCustomGearState({
    required this.grants,
    required this.selectedRiderId,
    required this.currentSeasonYear,
    required this.activeRaceDiscipline,
    required this.preferGoldHelmetWhenDualChampion,
    required this.report,
    this.isReadOnly = false,
  });

  ChampionCustomGearState copyWith({
    List<ChampionCustomGearGrant>? grants,
    String? selectedRiderId,
    int? currentSeasonYear,
    ChampionGearRaceDiscipline? activeRaceDiscipline,
    bool? preferGoldHelmetWhenDualChampion,
    ChampionCustomGearEvaluationReport? report,
    bool? isReadOnly,
  }) {
    return ChampionCustomGearState(
      grants: grants ?? this.grants,
      selectedRiderId: selectedRiderId ?? this.selectedRiderId,
      currentSeasonYear: currentSeasonYear ?? this.currentSeasonYear,
      activeRaceDiscipline: activeRaceDiscipline ?? this.activeRaceDiscipline,
      preferGoldHelmetWhenDualChampion: preferGoldHelmetWhenDualChampion ??
          this.preferGoldHelmetWhenDualChampion,
      report: report ?? this.report,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}

/// Notifier zarządzający personalizacją sprzętu Mistrza Świata i Mistrza Olimpijskiego.
class ChampionCustomGearNotifier
    extends StateNotifier<ChampionCustomGearState> {
  final CyclistOlympicAndWorldChampionCustomGear _service;

  ChampionCustomGearNotifier(this._service, {int initialYear = 2026})
      : super(_buildInitialState(_service, initialYear));

  static ChampionCustomGearState _buildInitialState(
    CyclistOlympicAndWorldChampionCustomGear service,
    int initialYear,
  ) {
    final demoGrants = service.buildDefaultDemoGrants(initialYear);
    final report = service.evaluateSeasonRosterGear(
      grants: demoGrants,
      seasonYear: initialYear,
      raceDiscipline: ChampionGearRaceDiscipline.allRaces,
    );
    return ChampionCustomGearState(
      grants: demoGrants,
      selectedRiderId: demoGrants.first.riderId,
      currentSeasonYear: initialYear,
      activeRaceDiscipline: ChampionGearRaceDiscipline.allRaces,
      preferGoldHelmetWhenDualChampion: true,
      report: report,
    );
  }

  void selectRider(String riderId) {
    state = state.copyWith(selectedRiderId: riderId);
  }

  void setSeasonYear(int year) {
    final clamped = year.clamp(2020, 2060);
    final report = _service.evaluateSeasonRosterGear(
      grants: state.grants,
      seasonYear: clamped,
      raceDiscipline: state.activeRaceDiscipline,
    );
    state = state.copyWith(
      currentSeasonYear: clamped,
      report: report,
    );
  }

  void setRaceDiscipline(ChampionGearRaceDiscipline discipline) {
    final report = _service.evaluateSeasonRosterGear(
      grants: state.grants,
      seasonYear: state.currentSeasonYear,
      raceDiscipline: discipline,
    );
    state = state.copyWith(
      activeRaceDiscipline: discipline,
      report: report,
    );
  }

  void togglePreferGoldHelmetWhenDual(bool preferGold) {
    state = state.copyWith(preferGoldHelmetWhenDualChampion: preferGold);
  }

  void setReadOnly(bool readOnly) {
    state = state.copyWith(isReadOnly: readOnly);
  }

  void assignWorldChampionTitle({
    required String riderId,
    required String riderName,
    required String nationalityIso,
    required String teamName,
    ChampionGearRaceDiscipline discipline = ChampionGearRaceDiscipline.roadRace,
  }) {
    if (state.isReadOnly) return;
    final grant = _service.grantWorldChampionGear(
      riderId: riderId,
      riderName: riderName,
      nationalityIso: nationalityIso,
      teamName: teamName,
      yearWon: state.currentSeasonYear,
      discipline: discipline,
    );
    final updated = [
      ...state.grants.where(
        (g) => !(g.riderId == riderId && g.titleKind == grant.titleKind),
      ),
      grant,
    ];
    final report = _service.evaluateSeasonRosterGear(
      grants: updated,
      seasonYear: state.currentSeasonYear,
      raceDiscipline: state.activeRaceDiscipline,
    );
    state = state.copyWith(
      grants: updated,
      selectedRiderId: riderId,
      report: report,
    );
  }

  void assignOlympicChampionTitle({
    required String riderId,
    required String riderName,
    required String nationalityIso,
    required String teamName,
    ChampionGearRaceDiscipline discipline = ChampionGearRaceDiscipline.roadRace,
  }) {
    if (state.isReadOnly) return;
    final grant = _service.grantOlympicChampionGear(
      riderId: riderId,
      riderName: riderName,
      nationalityIso: nationalityIso,
      teamName: teamName,
      olympicYearWon: state.currentSeasonYear,
      discipline: discipline,
    );
    final updated = [
      ...state.grants.where(
        (g) => !(g.riderId == riderId && g.titleKind == grant.titleKind),
      ),
      grant,
    ];
    final report = _service.evaluateSeasonRosterGear(
      grants: updated,
      seasonYear: state.currentSeasonYear,
      raceDiscipline: state.activeRaceDiscipline,
    );
    state = state.copyWith(
      grants: updated,
      selectedRiderId: riderId,
      report: report,
    );
  }

  void revokeGrant(String riderId, ChampionTitleKind titleKind) {
    if (state.isReadOnly) return;
    final updated = state.grants
        .where((g) => !(g.riderId == riderId && g.titleKind == titleKind))
        .toList();
    final report = _service.evaluateSeasonRosterGear(
      grants: updated,
      seasonYear: state.currentSeasonYear,
      raceDiscipline: state.activeRaceDiscipline,
    );
    state = state.copyWith(
      grants: updated,
      selectedRiderId: updated.isNotEmpty ? updated.first.riderId : null,
      report: report,
    );
  }

  ChampionGear3dVisualSpec resolveSelectedSpec() {
    final id = state.selectedRiderId ?? '';
    return _service.resolveVisualSpecForRider(
      riderId: id,
      grants: state.grants,
      currentYear: state.currentSeasonYear,
      raceDiscipline: state.activeRaceDiscipline,
      preferGoldHelmetWhenDualChampion: state.preferGoldHelmetWhenDualChampion,
    );
  }
}

final championCustomGearServiceProvider =
    Provider<CyclistOlympicAndWorldChampionCustomGear>(
  (ref) => const CyclistOlympicAndWorldChampionCustomGear(),
);

final championCustomGearProvider = StateNotifierProvider<
    ChampionCustomGearNotifier, ChampionCustomGearState>((ref) {
  final service = ref.watch(championCustomGearServiceProvider);
  return ChampionCustomGearNotifier(service);
});

/// Konwerter kolorów szesnastkowych dla renderera 3D i podglądu.
Color _parseHexColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  if (cleaned.length == 8) {
    return Color(int.parse(cleaned, radix: 16));
  }
  return AppColors.surfaceLight;
}

/// Dedykowany malarz podglądu 3D roweru, kasku, owijki i butów mistrzowskich.
class ChampionCustomGear3dBikePainter extends CustomPainter {
  final ChampionGear3dVisualSpec spec;
  final double shimmerPhase;

  const ChampionCustomGear3dBikePainter({
    required this.spec,
    this.shimmerPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final groundY = h * 0.80;

    // Tło sceny 3D z subtelnym gradientem podłogi showroomu
    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.surfaceLight.withValues(alpha: 0.0),
          AppColors.surfaceLight.withValues(alpha: 0.45),
        ],
      ).createShader(Rect.fromLTWH(0, groundY - 24, w, h - groundY + 24));
    canvas.drawRect(
      Rect.fromLTWH(0, groundY - 24, w, h - groundY + 24),
      floorPaint,
    );

    // Cień pod kołami
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY + 4),
        width: w * 0.64,
        height: 14,
      ),
      shadowPaint,
    );

    final wheelRadius = math.min(w * 0.14, h * 0.23);
    final wheelBase = wheelRadius * 3.15;
    final rearHub = Offset(cx - wheelBase * 0.48, groundY - wheelRadius);
    final frontHub = Offset(cx + wheelBase * 0.48, groundY - wheelRadius);

    // Koła i szprychy
    final tirePaint = Paint()
      ..color = const Color(0xFF0B0E14)
      ..strokeWidth = 6.5
      ..style = PaintingStyle.stroke;
    final rimPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final spokePaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.55)
      ..strokeWidth = 1.0;

    for (final hub in [rearHub, frontHub]) {
      canvas.drawCircle(hub, wheelRadius, tirePaint);
      canvas.drawCircle(hub, wheelRadius - 3.5, rimPaint);
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4.0;
        canvas.drawLine(
          hub,
          hub +
              Offset(
                math.cos(angle) * (wheelRadius - 4),
                math.sin(angle) * (wheelRadius - 4),
              ),
          spokePaint,
        );
      }
    }

    // Geometria ramy karbonowej
    final bb = Offset(cx - wheelBase * 0.08, groundY - wheelRadius + 6);
    final seatCluster = Offset(
      cx - wheelBase * 0.22,
      groundY - wheelRadius * 2.15,
    );
    final headCluster = Offset(
      cx + wheelBase * 0.26,
      groundY - wheelRadius * 2.08,
    );

    final frameColor = _parseHexColor(spec.framePrimaryHex);
    final framePaint = Paint()
      ..color = frameColor
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Trójkąt główny ramy i tylne widełki
    canvas.drawLine(rearHub, bb, framePaint);
    canvas.drawLine(rearHub, seatCluster, framePaint);
    canvas.drawLine(bb, seatCluster, framePaint);
    canvas.drawLine(bb, headCluster, framePaint);
    canvas.drawLine(seatCluster, headCluster, framePaint);
    canvas.drawLine(headCluster, frontHub, framePaint);

    // Tęczowe pasy UCI na rurze podsiodłowej dla Mistrza Świata
    if (spec.hasSeatTubeRainbowBands) {
      const bands = ChampionGear3dVisualSpec.uciRainbowBandHexes;
      for (int i = 0; i < bands.length; i++) {
        final t0 = 0.34 + i * 0.065;
        final t1 = t0 + 0.055;
        final p0 = Offset.lerp(bb, seatCluster, t0)!;
        final p1 = Offset.lerp(bb, seatCluster, t1)!;
        final bandPaint = Paint()
          ..color = _parseHexColor(bands[i])
          ..strokeWidth = 6.2
          ..strokeCap = StrokeCap.butt;
        canvas.drawLine(p0, p1, bandPaint);
      }
    }

    // Złote detale ramy Mistrza Olimpijskiego (#D4AF37)
    if (spec.hasGoldFrameDetails) {
      final goldPaint = Paint()
        ..color = AppColors.goldAccent
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      // Złote akcenty na górnej rurze, widelcu i tylnym trójkącie
      canvas.drawLine(
        Offset.lerp(seatCluster, headCluster, 0.15)!,
        Offset.lerp(seatCluster, headCluster, 0.85)!,
        goldPaint,
      );
      canvas.drawLine(
        Offset.lerp(headCluster, frontHub, 0.20)!,
        Offset.lerp(headCluster, frontHub, 0.75)!,
        goldPaint,
      );
      canvas.drawLine(
        Offset.lerp(rearHub, seatCluster, 0.25)!,
        Offset.lerp(rearHub, seatCluster, 0.70)!,
        goldPaint,
      );
    }

    // Siodełko
    final saddleTop = seatCluster + const Offset(-4, -12);
    final seatPostPaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 3.5;
    canvas.drawLine(seatCluster, saddleTop, seatPostPaint);
    canvas.drawLine(
      saddleTop + const Offset(-12, 0),
      saddleTop + const Offset(10, 0),
      Paint()
        ..color = const Color(0xFF0F172A)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    // Kierownica i owijka kierownicy (Złota dla Mistrza Olimpijskiego)
    final stemEnd = headCluster + const Offset(14, -10);
    canvas.drawLine(
      headCluster,
      stemEnd,
      Paint()
        ..color = const Color(0xFF1F2937)
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round,
    );
    final dropPath = Path()
      ..moveTo(stemEnd.dx, stemEnd.dy)
      ..quadraticBezierTo(
        stemEnd.dx + 18,
        stemEnd.dy + 2,
        stemEnd.dx + 14,
        stemEnd.dy + 16,
      )
      ..quadraticBezierTo(
        stemEnd.dx + 10,
        stemEnd.dy + 24,
        stemEnd.dx - 2,
        stemEnd.dy + 22,
      );
    canvas.drawPath(
      dropPath,
      Paint()
        ..color = _parseHexColor(spec.handlebarTapeHex)
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Prezentacja Kasku Mistrzowskiego (prawy górny róg podglądu)
    final helmetCenter = Offset(cx + wheelBase * 0.22, h * 0.22);
    final helmetRect = Rect.fromCenter(
      center: helmetCenter,
      width: 58,
      height: 32,
    );
    final helmetPaint = Paint()
      ..color = _parseHexColor(spec.helmetPrimaryHex)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        helmetRect,
        topLeft: const Radius.circular(22),
        topRight: const Radius.circular(26),
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(10),
      ),
      helmetPaint,
    );

    // Połysk na Złotym Kasku Olimpijskim
    if (spec.isGoldOlympicHelmet) {
      final sheenX =
          helmetRect.left + (helmetRect.width * (0.2 + 0.6 * shimmerPhase));
      final sheenPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(sheenX - 6, helmetRect.top + 6),
        Offset(sheenX + 4, helmetRect.bottom - 8),
        sheenPaint,
      );
    }

    // Tęczowy pasek na białym kasku Mistrza Świata UCI
    if (spec.hasHelmetRainbowBand) {
      const bands = ChampionGear3dVisualSpec.uciRainbowBandHexes;
      final segWidth = (helmetRect.width - 12) / bands.length;
      for (int i = 0; i < bands.length; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            helmetRect.left + 6 + i * segWidth,
            helmetRect.bottom - 9,
            segWidth,
            4.5,
          ),
          Paint()..color = _parseHexColor(bands[i]),
        );
      }
    }

    // Prezentacja Buta Kolarskiego przy korbie / w lewym górnym rogu
    final shoeCenter = Offset(cx - wheelBase * 0.28, h * 0.24);
    final shoePath = Path()
      ..moveTo(shoeCenter.dx - 22, shoeCenter.dy + 8)
      ..lineTo(shoeCenter.dx + 22, shoeCenter.dy + 8)
      ..quadraticBezierTo(
        shoeCenter.dx + 26,
        shoeCenter.dy - 4,
        shoeCenter.dx + 10,
        shoeCenter.dy - 8,
      )
      ..lineTo(shoeCenter.dx - 16, shoeCenter.dy - 12)
      ..close();
    canvas.drawPath(
      shoePath,
      Paint()
        ..color = _parseHexColor(spec.shoesHex)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      shoePath,
      Paint()
        ..color = spec.hasGoldFrameDetails
            ? AppColors.goldAccent
            : AppColors.cardBorder
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant ChampionCustomGear3dBikePainter oldDelegate) {
    return oldDelegate.spec.framePrimaryHex != spec.framePrimaryHex ||
        oldDelegate.spec.helmetPrimaryHex != spec.helmetPrimaryHex ||
        oldDelegate.spec.handlebarTapeHex != spec.handlebarTapeHex ||
        oldDelegate.spec.shoesHex != spec.shoesHex ||
        oldDelegate.spec.hasSeatTubeRainbowBands !=
            spec.hasSeatTubeRainbowBands ||
        oldDelegate.spec.hasGoldFrameDetails != spec.hasGoldFrameDetails ||
        oldDelegate.shimmerPhase != shimmerPhase;
  }
}

/// Responsywny panel zarządzania i podglądu sprzętu mistrzowskiego 3D.
class CyclistOlympicAndWorldChampionCustomGearPanel
    extends ConsumerStatefulWidget {
  final bool isReadOnly;

  const CyclistOlympicAndWorldChampionCustomGearPanel({
    super.key,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<CyclistOlympicAndWorldChampionCustomGearPanel> createState() =>
      _CyclistOlympicAndWorldChampionCustomGearPanelState();
}

class _CyclistOlympicAndWorldChampionCustomGearPanelState
    extends ConsumerState<CyclistOlympicAndWorldChampionCustomGearPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(championCustomGearProvider);
    final notifier = ref.read(championCustomGearProvider.notifier);
    final effectiveReadOnly = widget.isReadOnly || state.isReadOnly;
    final selectedSpec = notifier.resolveSelectedSpec();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, notifier, effectiveReadOnly, isCompact),
                const SizedBox(height: 16),
                if (isCompact) ...[
                  _buildPreviewCard(selectedSpec),
                  const SizedBox(height: 16),
                  _buildRosterGrantsCard(state, notifier, effectiveReadOnly),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildRosterGrantsCard(
                          state,
                          notifier,
                          effectiveReadOnly,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _buildPreviewCard(selectedSpec),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    ChampionCustomGearState state,
    ChampionCustomGearNotifier notifier,
    bool readOnly,
    bool isCompact,
  ) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sprzęt Mistrzowski 3D — MŚ UCI & Igrzyska Olimpijskie',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sezon ${state.currentSeasonYear} • Aktywni mistrzowie: '
          '${state.report.activeWorldChampionsCount} MŚ / '
          '${state.report.activeOlympicChampionsCount} IO (4-letni cykl)',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    final yearControls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _InteractiveActionPill(
          label: '${state.currentSeasonYear - 1}',
          icon: Icons.chevron_left,
          isDisabled: readOnly,
          onTap: () => notifier.setSeasonYear(state.currentSeasonYear - 1),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            'ROK ${state.currentSeasonYear}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _InteractiveActionPill(
          label: '${state.currentSeasonYear + 1}',
          icon: Icons.chevron_right,
          isDisabled: readOnly,
          onTap: () => notifier.setSeasonYear(state.currentSeasonYear + 1),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                yearControls,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 12),
                yearControls,
              ],
            ),
    );
  }

  Widget _buildRosterGrantsCard(
    ChampionCustomGearState state,
    ChampionCustomGearNotifier notifier,
    bool readOnly,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Aktywne Tytuły i Nadania Sprzętu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ChampionGearRaceDiscipline.values.map((disc) {
              final selected = state.activeRaceDiscipline == disc;
              return _InteractiveActionPill(
                label: disc.polishLabel,
                isActive: selected,
                isDisabled: false,
                onTap: () => notifier.setRaceDiscipline(disc),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (state.grants.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Brak przypisanych tytułów mistrzowskich w aktualnym sezonie.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...state.grants.map((grant) {
              final isSelected = state.selectedRiderId == grant.riderId;
              final isActive = grant.appliesToRace(
                year: state.currentSeasonYear,
                raceDiscipline: state.activeRaceDiscipline,
              );
              final remaining = grant.remainingYears(state.currentSeasonYear);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GrantSelectionTile(
                  grant: grant,
                  isSelected: isSelected,
                  isActive: isActive,
                  remainingYears: remaining,
                  isReadOnly: readOnly,
                  onSelect: () => notifier.selectRider(grant.riderId),
                  onRevoke: () =>
                      notifier.revokeGrant(grant.riderId, grant.titleKind),
                ),
              );
            }),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InteractiveActionPill(
                label: '+ Mistrz Świata UCI',
                icon: Icons.emoji_events,
                isDisabled: readOnly,
                onTap: () => notifier.assignWorldChampionTitle(
                  riderId: 'custom_wc_${state.currentSeasonYear}',
                  riderName: 'Mistrz Świata (${state.currentSeasonYear})',
                  nationalityIso: 'POL',
                  teamName: 'Pro Peloton Team',
                ),
              ),
              _InteractiveActionPill(
                label: '+ Mistrz Olimpijski (4 lata)',
                icon: Icons.workspace_premium,
                isActive: true,
                isDisabled: readOnly,
                onTap: () => notifier.assignOlympicChampionTitle(
                  riderId: 'custom_og_${state.currentSeasonYear}',
                  riderName: 'Mistrz Olimpijski (${state.currentSeasonYear})',
                  nationalityIso: 'POL',
                  teamName: 'Reprezentacja Narodowa',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ChampionGear3dVisualSpec spec) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Podgląd 3D Sprzętu Mistrzowskiego',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (spec.validUntilYear != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.goldAccent),
                  ),
                  child: Text(
                    'Do ${spec.validUntilYear! - 1}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) {
                return CustomPaint(
                  painter: ChampionCustomGear3dBikePainter(
                    spec: spec,
                    shimmerPhase: _shimmerController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _SpecDetailRow(
            label: 'Rama 3D',
            value: spec.frameLivery.polishDescription,
            accentHex: spec.framePrimaryHex,
          ),
          const SizedBox(height: 6),
          _SpecDetailRow(
            label: 'Kask 3D',
            value: spec.helmetLivery.polishDescription,
            accentHex: spec.helmetPrimaryHex,
          ),
          const SizedBox(height: 6),
          _SpecDetailRow(
            label: 'Owijka kierownicy',
            value: spec.handlebarTapeLivery.polishDescription,
            accentHex: spec.handlebarTapeHex,
          ),
          const SizedBox(height: 6),
          _SpecDetailRow(
            label: 'Buty kolarskie',
            value: spec.shoesLivery.polishDescription,
            accentHex: spec.shoesHex,
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionPill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;

  const _InteractiveActionPill({
    required this.label,
    this.icon,
    this.isActive = false,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  State<_InteractiveActionPill> createState() => _InteractiveActionPillState();
}

class _InteractiveActionPillState extends State<_InteractiveActionPill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isActive
            ? AppColors.primaryAccent
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.isActive
            ? AppColors.goldAccent
            : AppColors.cardBorder;
    final textColor = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
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
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 15, color: textColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
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

class _GrantSelectionTile extends StatefulWidget {
  final ChampionCustomGearGrant grant;
  final bool isSelected;
  final bool isActive;
  final int remainingYears;
  final bool isReadOnly;
  final VoidCallback onSelect;
  final VoidCallback onRevoke;

  const _GrantSelectionTile({
    required this.grant,
    required this.isSelected,
    required this.isActive,
    required this.remainingYears,
    required this.isReadOnly,
    required this.onSelect,
    required this.onRevoke,
  });

  @override
  State<_GrantSelectionTile> createState() => _GrantSelectionTileState();
}

class _GrantSelectionTileState extends State<_GrantSelectionTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : AppColors.cardBorder;
    final bgColor = widget.isSelected
        ? AppColors.surfaceLight
        : _hovered
            ? AppColors.surfaceLight.withValues(alpha: 0.7)
            : AppColors.background;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.grant.titleKind.isOlympic
                      ? AppColors.goldAccent
                      : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.grant.riderName} (${widget.grant.nationalityIso})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.grant.titleKind.polishLabel} • '
                      '${widget.isActive ? 'Aktywny (${widget.remainingYears} lata)' : 'Wygasł'}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: widget.isActive
                            ? AppColors.statusSuccess
                            : AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isReadOnly)
                IconButton(
                  tooltip: 'Usuń nadanie',
                  onPressed: widget.onRevoke,
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String accentHex;

  const _SpecDetailRow({
    required this.label,
    required this.value,
    required this.accentHex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _parseHexColor(accentHex),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
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
