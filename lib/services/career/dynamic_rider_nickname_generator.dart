// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';

/// Źródło pochodzenia przydomka kolarskiego.
enum NicknameOriginSource {
  sportsMedia,
  fanPeloton,
  roadSideUltras,
  teammatesLockerRoom,
  rivalDs,
  cyclingPodcast;

  String toJson() => name;

  static NicknameOriginSource fromJson(String value) {
    return NicknameOriginSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NicknameOriginSource.sportsMedia,
    );
  }

  String get label {
    switch (this) {
      case NicknameOriginSource.sportsMedia:
        return 'Prasa Kolarska';
      case NicknameOriginSource.fanPeloton:
        return 'Kibice i Fora';
      case NicknameOriginSource.roadSideUltras:
        return 'Ultras na Przełęczach';
      case NicknameOriginSource.teammatesLockerRoom:
        return 'Szatnia Drużyny';
      case NicknameOriginSource.rivalDs:
        return 'Dyrektorzy Rywali';
      case NicknameOriginSource.cyclingPodcast:
        return 'Podcasty i TV';
    }
  }

  String get shortLabel {
    switch (this) {
      case NicknameOriginSource.sportsMedia:
        return 'Media';
      case NicknameOriginSource.fanPeloton:
        return 'Kibice';
      case NicknameOriginSource.roadSideUltras:
        return 'Ultras';
      case NicknameOriginSource.teammatesLockerRoom:
        return 'Szatnia';
      case NicknameOriginSource.rivalDs:
        return 'Rywale';
      case NicknameOriginSource.cyclingPodcast:
        return 'TV/Audio';
    }
  }

  Color get accentColor {
    switch (this) {
      case NicknameOriginSource.sportsMedia:
        return AppColors.accentBlue;
      case NicknameOriginSource.fanPeloton:
        return AppColors.goldAccent;
      case NicknameOriginSource.roadSideUltras:
        return AppColors.crimsonAlert;
      case NicknameOriginSource.teammatesLockerRoom:
        return AppColors.statusSuccess;
      case NicknameOriginSource.rivalDs:
        return AppColors.amberWarning;
      case NicknameOriginSource.cyclingPodcast:
        return AppColors.cyanAccent;
    }
  }

  IconData get icon {
    switch (this) {
      case NicknameOriginSource.sportsMedia:
        return Icons.newspaper_rounded;
      case NicknameOriginSource.fanPeloton:
        return Icons.groups_rounded;
      case NicknameOriginSource.roadSideUltras:
        return Icons.local_fire_department_rounded;
      case NicknameOriginSource.teammatesLockerRoom:
        return Icons.shield_rounded;
      case NicknameOriginSource.rivalDs:
        return Icons.headset_mic_rounded;
      case NicknameOriginSource.cyclingPodcast:
        return Icons.podcasts_rounded;
    }
  }
}

/// Archetyp kolarski determinujący styl przydomka.
enum NicknameArchetype {
  mountainGoat,
  sprintRocket,
  timeTrialMachine,
  cobbleGladiator,
  breakawayPhantom,
  descentDaredevil,
  domestiqueGuardian,
  ironSurvivor,
  tacticalProfessor,
  cultFanFavorite;

  String toJson() => name;

  static NicknameArchetype fromJson(String value) {
    return NicknameArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NicknameArchetype.cultFanFavorite,
    );
  }

  String get label {
    switch (this) {
      case NicknameArchetype.mountainGoat:
        return 'Król Szczytów';
      case NicknameArchetype.sprintRocket:
        return 'Rakieta Finiszowa';
      case NicknameArchetype.timeTrialMachine:
        return 'Maszyna Czasowa';
      case NicknameArchetype.cobbleGladiator:
        return 'Gladiator Bruku';
      case NicknameArchetype.breakawayPhantom:
        return 'Duch Ucieczki';
      case NicknameArchetype.descentDaredevil:
        return 'Sokół Zjazdów';
      case NicknameArchetype.domestiqueGuardian:
        return 'Żelazny Pomocnik';
      case NicknameArchetype.ironSurvivor:
        return 'Niezniszczalny';
      case NicknameArchetype.tacticalProfessor:
        return 'Profesor Taktyki';
      case NicknameArchetype.cultFanFavorite:
        return 'Ikona Kibiców';
    }
  }

  IconData get icon {
    switch (this) {
      case NicknameArchetype.mountainGoat:
        return Icons.terrain_rounded;
      case NicknameArchetype.sprintRocket:
        return Icons.bolt_rounded;
      case NicknameArchetype.timeTrialMachine:
        return Icons.timer_rounded;
      case NicknameArchetype.cobbleGladiator:
        return Icons.grid_view_rounded;
      case NicknameArchetype.breakawayPhantom:
        return Icons.air_rounded;
      case NicknameArchetype.descentDaredevil:
        return Icons.trending_down_rounded;
      case NicknameArchetype.domestiqueGuardian:
        return Icons.handshake_rounded;
      case NicknameArchetype.ironSurvivor:
        return Icons.health_and_safety_rounded;
      case NicknameArchetype.tacticalProfessor:
        return Icons.psychology_rounded;
      case NicknameArchetype.cultFanFavorite:
        return Icons.auto_awesome_rounded;
    }
  }
}

/// Rzadkość i rozpoznawalność przydomka w świecie kolarskim.
enum NicknameRarityTier {
  local,
  national,
  worldTour,
  monumental,
  legendary;

  String toJson() => name;

  static NicknameRarityTier fromJson(String value) {
    return NicknameRarityTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NicknameRarityTier.local,
    );
  }

  String get label {
    switch (this) {
      case NicknameRarityTier.local:
        return 'Lokalny';
      case NicknameRarityTier.national:
        return 'Krajowy';
      case NicknameRarityTier.worldTour:
        return 'WorldTour';
      case NicknameRarityTier.monumental:
        return 'Monumentalny';
      case NicknameRarityTier.legendary:
        return 'Legendarny';
    }
  }

  Color get accentColor {
    switch (this) {
      case NicknameRarityTier.local:
        return AppColors.textSecondary;
      case NicknameRarityTier.national:
        return AppColors.statusSuccess;
      case NicknameRarityTier.worldTour:
        return AppColors.accentBlue;
      case NicknameRarityTier.monumental:
        return AppColors.primaryAccent;
      case NicknameRarityTier.legendary:
        return AppColors.goldAccent;
    }
  }

  double get prestigeMultiplier {
    switch (this) {
      case NicknameRarityTier.local:
        return 1.0;
      case NicknameRarityTier.national:
        return 1.25;
      case NicknameRarityTier.worldTour:
        return 1.6;
      case NicknameRarityTier.monumental:
        return 2.0;
      case NicknameRarityTier.legendary:
        return 2.5;
    }
  }
}

/// Dane wejściowe kolarza i kontekstu kariery potrzebne do wygenerowania przydomków.
class RiderNicknameInput {
  final String riderId;
  final String firstName;
  final String lastName;
  final String nationalityIso;
  final int age;
  final RiderSpecialization specialization;
  final double ftpWatts;
  final double weightKg;
  final double watts5s;
  final double watts20m;
  final int cobbles;
  final int descending;
  final int raceIq;
  final int rainResistance;
  final int heatTolerance;
  final int timeTrialPositioning;
  final int careerWins;
  final int monumentWins;
  final int grandTourStages;
  final int combativityAwards;
  final int crashesSurvived;
  final int breakawayKm;
  final int fanPopularity;
  final int mediaHype;
  final int seasonYear;
  final String? notableRaceName;
  final String? notableLocation;

  const RiderNicknameInput({
    required this.riderId,
    required this.firstName,
    required this.lastName,
    required this.nationalityIso,
    required this.age,
    required this.specialization,
    required this.ftpWatts,
    required this.weightKg,
    required this.watts5s,
    required this.watts20m,
    required this.cobbles,
    required this.descending,
    required this.raceIq,
    required this.rainResistance,
    required this.heatTolerance,
    required this.timeTrialPositioning,
    this.careerWins = 0,
    this.monumentWins = 0,
    this.grandTourStages = 0,
    this.combativityAwards = 0,
    this.crashesSurvived = 0,
    this.breakawayKm = 0,
    this.fanPopularity = 50,
    this.mediaHype = 50,
    this.seasonYear = 2026,
    this.notableRaceName,
    this.notableLocation,
  });

  String get fullName => '$firstName $lastName'.trim();

  double get wPerKg => weightKg > 0 ? ftpWatts / weightKg : 5.0;

  double get wPerKg20m => weightKg > 0 ? watts20m / weightKg : 5.2;

  /// Tworzy wejście generatora bezpośrednio z modelu [Rider].
  factory RiderNicknameInput.fromRider(
    Rider rider, {
    int careerWins = 0,
    int monumentWins = 0,
    int grandTourStages = 0,
    int combativityAwards = 0,
    int crashesSurvived = 0,
    int breakawayKm = 0,
    int fanPopularity = 55,
    int mediaHype = 55,
    int seasonYear = 2026,
    String? notableRaceName,
    String? notableLocation,
  }) {
    return RiderNicknameInput(
      riderId: rider.id,
      firstName: rider.firstName,
      lastName: rider.lastName,
      nationalityIso: rider.nationalityIso,
      age: rider.age,
      specialization: rider.specialization,
      ftpWatts: rider.physiology.ftpWatts.toDouble(),
      weightKg: rider.physiology.weightKg,
      watts5s: rider.powerProfile.watts5s.toDouble(),
      watts20m: rider.powerProfile.watts20m.toDouble(),
      cobbles: rider.skills.cobbles,
      descending: rider.skills.descending,
      raceIq: rider.skills.raceIq,
      rainResistance: rider.skills.rainResistance,
      heatTolerance: rider.skills.heatTolerance,
      timeTrialPositioning: rider.skills.timeTrialPositioning,
      careerWins: careerWins,
      monumentWins: monumentWins,
      grandTourStages: grandTourStages,
      combativityAwards: combativityAwards,
      crashesSurvived: crashesSurvived,
      breakawayKm: breakawayKm,
      fanPopularity: fanPopularity,
      mediaHype: mediaHype,
      seasonYear: seasonYear,
      notableRaceName: notableRaceName,
      notableLocation: notableLocation,
    );
  }
}

/// Kandydat przydomka wygenerowany przez algorytm przed nadaniem kolarzowi.
class NicknameGenerationCandidate {
  final String nickname;
  final NicknameArchetype archetype;
  final NicknameOriginSource originSource;
  final NicknameRarityTier rarityTier;
  final int fitScore;
  final String loreReason;
  final String mediaHeadline;
  final List<String> tags;

  const NicknameGenerationCandidate({
    required this.nickname,
    required this.archetype,
    required this.originSource,
    required this.rarityTier,
    required this.fitScore,
    required this.loreReason,
    required this.mediaHeadline,
    required this.tags,
  });
}

/// Zapisany przydomek przypisany do konkretnego kolarza w karierze.
class RiderNicknameRecord {
  final String id;
  final String riderId;
  final String nickname;
  final String loreReason;
  final String mediaHeadline;
  final NicknameOriginSource originSource;
  final NicknameArchetype archetype;
  final NicknameRarityTier rarityTier;
  final int popularityScore;
  final bool jerseyFlockApproved;
  final bool isActivePrimary;
  final int awardedSeason;
  final String awardedRaceName;
  final String awardedAtIso;
  final List<String> tags;

  const RiderNicknameRecord({
    required this.id,
    required this.riderId,
    required this.nickname,
    required this.loreReason,
    required this.mediaHeadline,
    required this.originSource,
    required this.archetype,
    required this.rarityTier,
    required this.popularityScore,
    required this.jerseyFlockApproved,
    required this.isActivePrimary,
    required this.awardedSeason,
    required this.awardedRaceName,
    required this.awardedAtIso,
    required this.tags,
  });

  RiderNicknameRecord copyWith({
    String? id,
    String? riderId,
    String? nickname,
    String? loreReason,
    String? mediaHeadline,
    NicknameOriginSource? originSource,
    NicknameArchetype? archetype,
    NicknameRarityTier? rarityTier,
    int? popularityScore,
    bool? jerseyFlockApproved,
    bool? isActivePrimary,
    int? awardedSeason,
    String? awardedRaceName,
    String? awardedAtIso,
    List<String>? tags,
  }) {
    return RiderNicknameRecord(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      nickname: nickname ?? this.nickname,
      loreReason: loreReason ?? this.loreReason,
      mediaHeadline: mediaHeadline ?? this.mediaHeadline,
      originSource: originSource ?? this.originSource,
      archetype: archetype ?? this.archetype,
      rarityTier: rarityTier ?? this.rarityTier,
      popularityScore: popularityScore ?? this.popularityScore,
      jerseyFlockApproved: jerseyFlockApproved ?? this.jerseyFlockApproved,
      isActivePrimary: isActivePrimary ?? this.isActivePrimary,
      awardedSeason: awardedSeason ?? this.awardedSeason,
      awardedRaceName: awardedRaceName ?? this.awardedRaceName,
      awardedAtIso: awardedAtIso ?? this.awardedAtIso,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'nickname': nickname,
      'loreReason': loreReason,
      'mediaHeadline': mediaHeadline,
      'originSource': originSource.toJson(),
      'archetype': archetype.toJson(),
      'rarityTier': rarityTier.toJson(),
      'popularityScore': popularityScore,
      'jerseyFlockApproved': jerseyFlockApproved,
      'isActivePrimary': isActivePrimary,
      'awardedSeason': awardedSeason,
      'awardedRaceName': awardedRaceName,
      'awardedAtIso': awardedAtIso,
      'tags': tags,
    };
  }

  factory RiderNicknameRecord.fromJson(Map<String, dynamic> json) {
    return RiderNicknameRecord(
      id: (json['id'] ?? '').toString(),
      riderId: (json['riderId'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      loreReason: (json['loreReason'] ?? '').toString(),
      mediaHeadline: (json['mediaHeadline'] ?? '').toString(),
      originSource: NicknameOriginSource.fromJson(
        (json['originSource'] ?? 'sportsMedia').toString(),
      ),
      archetype: NicknameArchetype.fromJson(
        (json['archetype'] ?? 'cultFanFavorite').toString(),
      ),
      rarityTier: NicknameRarityTier.fromJson(
        (json['rarityTier'] ?? 'local').toString(),
      ),
      popularityScore: (json['popularityScore'] as num?)?.toInt() ?? 50,
      jerseyFlockApproved: json['jerseyFlockApproved'] == true,
      isActivePrimary: json['isActivePrimary'] == true,
      awardedSeason: (json['awardedSeason'] as num?)?.toInt() ?? 2026,
      awardedRaceName: (json['awardedRaceName'] ?? 'Sezon WorldTour').toString(),
      awardedAtIso: (json['awardedAtIso'] ?? '').toString(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Wpływ marketingowy i mentalny aktywnego przydomka.
class NicknameMarketingImpact {
  final int moraleBonus;
  final double fanMerchandiseMultiplier;
  final double sponsorAppealBonusPct;

  const NicknameMarketingImpact({
    required this.moraleBonus,
    required this.fanMerchandiseMultiplier,
    required this.sponsorAppealBonusPct,
  });

  static const NicknameMarketingImpact zero = NicknameMarketingImpact(
    moraleBonus: 0,
    fanMerchandiseMultiplier: 1.0,
    sponsorAppealBonusPct: 0.0,
  );
}

/// Wynik operacji nadania, zmiany lub walidacji przydomka.
class NicknameAdoptionOutcome {
  final bool success;
  final String message;
  final NicknameMarketingImpact impact;
  final RiderNicknameRecord? activeNickname;

  const NicknameAdoptionOutcome({
    required this.success,
    required this.message,
    required this.impact,
    this.activeNickname,
  });
}

class _NationalityFlavor {
  final String adjectiveMasc;
  final String regionLabel;
  final String eagleTitle;
  final String lionTitle;

  const _NationalityFlavor({
    required this.adjectiveMasc,
    required this.regionLabel,
    required this.eagleTitle,
    required this.lionTitle,
  });
}

class _NicknameTemplate {
  final String pattern;
  final NicknameOriginSource source;
  final String reasonTemplate;
  final List<String> tags;

  const _NicknameTemplate({
    required this.pattern,
    required this.source,
    required this.reasonTemplate,
    required this.tags,
  });
}

/// Główny serwis generujący przydomki kolarskie nadawane przez media i kibiców.
class DynamicRiderNicknameGenerator {
  const DynamicRiderNicknameGenerator();

  static const Map<String, _NationalityFlavor> _nationalityFlavors = {
    'POL': _NationalityFlavor(
      adjectiveMasc: 'Polski',
      regionLabel: 'Tatr',
      eagleTitle: 'Biały Orzeł',
      lionTitle: 'Lew z Polski',
    ),
    'BEL': _NationalityFlavor(
      adjectiveMasc: 'Flamandzki',
      regionLabel: 'Flandrii',
      eagleTitle: 'Jastrząb z Brugii',
      lionTitle: 'De Leeuw',
    ),
    'FRA': _NationalityFlavor(
      adjectiveMasc: 'Francuski',
      regionLabel: 'Pirenejów',
      eagleTitle: 'L’Aigle',
      lionTitle: 'Le Blaireau',
    ),
    'ITA': _NationalityFlavor(
      adjectiveMasc: 'Włoski',
      regionLabel: 'Dolomitów',
      eagleTitle: 'Il Falco',
      lionTitle: 'Il Leone',
    ),
    'ESP': _NationalityFlavor(
      adjectiveMasc: 'Hiszpański',
      regionLabel: 'Asturii',
      eagleTitle: 'El Águila',
      lionTitle: 'El Pistolero',
    ),
    'NED': _NationalityFlavor(
      adjectiveMasc: 'Holenderski',
      regionLabel: 'Nizin',
      eagleTitle: 'Latający Holender',
      lionTitle: 'Oranje Express',
    ),
    'SLO': _NationalityFlavor(
      adjectiveMasc: 'Słoweński',
      regionLabel: 'Alp Julijskich',
      eagleTitle: 'Smok z Lublany',
      lionTitle: 'Alpejski Fenomen',
    ),
    'COL': _NationalityFlavor(
      adjectiveMasc: 'Kolumbijski',
      regionLabel: 'Andów',
      eagleTitle: 'El Cóndor',
      lionTitle: 'Escarabajo',
    ),
    'GBR': _NationalityFlavor(
      adjectiveMasc: 'Brytyjski',
      regionLabel: 'Yorkshire',
      eagleTitle: 'Manx Missile',
      lionTitle: 'Rycerz Szosy',
    ),
    'DEN': _NationalityFlavor(
      adjectiveMasc: 'Duński',
      regionLabel: 'Jutlandii',
      eagleTitle: 'Wiking z Północy',
      lionTitle: 'Król Roweru',
    ),
    'USA': _NationalityFlavor(
      adjectiveMasc: 'Amerykański',
      regionLabel: 'Kolorado',
      eagleTitle: 'Orzeł z Boulder',
      lionTitle: 'Kapitan Ameryka',
    ),
    'GER': _NationalityFlavor(
      adjectiveMasc: 'Niemiecki',
      regionLabel: 'Schwarzwaldu',
      eagleTitle: 'Panzer-Sprinter',
      lionTitle: 'Der Gorilla',
    ),
    'SUI': _NationalityFlavor(
      adjectiveMasc: 'Szwajcarski',
      regionLabel: 'Bernese Alps',
      eagleTitle: 'Spartakus',
      lionTitle: 'Szwajcarski Zegarek',
    ),
    'AUS': _NationalityFlavor(
      adjectiveMasc: 'Australijski',
      regionLabel: 'Outbacku',
      eagleTitle: 'Tasmanian Devil',
      lionTitle: 'Kangur Szosy',
    ),
    'NOR': _NationalityFlavor(
      adjectiveMasc: 'Norweski',
      regionLabel: 'Fiordów',
      eagleTitle: 'Bóg Północy',
      lionTitle: 'Thor na Dwóch Kołach',
    ),
  };

  static const _NationalityFlavor _defaultFlavor = _NationalityFlavor(
    adjectiveMasc: 'Nieustępliwy',
    regionLabel: 'Wielkich Szczytów',
    eagleTitle: 'Orzeł Peletonu',
    lionTitle: 'Lew Szosy',
  );

  static const Map<NicknameArchetype, List<_NicknameTemplate>> _templates = {
    NicknameArchetype.mountainGoat: [
      _NicknameTemplate(
        pattern: '{eagle} z {region}',
        source: NicknameOriginSource.sportsMedia,
        reasonTemplate:
            'Efekt imponującego stosunku mocy {wkg} W/kg na długich podjazdach.',
        tags: ['Góry', 'Wspinaczka', 'HC'],
      ),
      _NicknameTemplate(
        pattern: 'Kozica {region}',
        source: NicknameOriginSource.roadSideUltras,
        reasonTemplate:
            'Kibice na przełęczach podziwiają lekkość ataków w stromych partiach.',
        tags: ['Kibice', 'Przełęcze', 'Kadencja'],
      ),
      _NicknameTemplate(
        pattern: 'Władca Chmur',
        source: NicknameOriginSource.cyclingPodcast,
        reasonTemplate:
            'Komentatorzy podkreślają dominację powyżej 2000 m n.p.m.',
        tags: ['Wysokość', 'Grand Tour', 'GC'],
      ),
      _NicknameTemplate(
        pattern: '{adjective} Eskarabajo',
        source: NicknameOriginSource.fanPeloton,
        reasonTemplate:
            'Fani doceniają czyste przyspieszenia na 12-procentowych ściankach.',
        tags: ['Atak', 'Wspinacz', 'Styl'],
      ),
    ],
    NicknameArchetype.sprintRocket: [
      _NicknameTemplate(
        pattern: 'Biała Błyskawica',
        source: NicknameOriginSource.sportsMedia,
        reasonTemplate:
            'Szczytowa moc {watts5s} W na ostatnich 200 metrach zdeklasowała rywali.',
        tags: ['Sprint', 'Watt Bomb', 'Finisz'],
      ),
      _NicknameTemplate(
        pattern: 'Torpeda z {region}',
        source: NicknameOriginSource.fanPeloton,
        reasonTemplate:
            'Kibice nadali ten przydomek po serii błyskawicznych finiszów z pociągu.',
        tags: ['Pociąg', 'Prędkość', 'Kreska'],
      ),
      _NicknameTemplate(
        pattern: 'Książę Ostatnich 150 Metrów',
        source: NicknameOriginSource.cyclingPodcast,
        reasonTemplate:
            'Eksperci TV zwracają uwagę na perfekcyjne wyczucie rzutu rowerem.',
        tags: ['Bike Throw', 'Fotofinisz', 'Zwycięstwa'],
      ),
      _NicknameTemplate(
        pattern: 'Naddźwiękowy {last}',
        source: NicknameOriginSource.rivalDs,
        reasonTemplate:
            'Dyrektorzy rywali ostrzegają swoje ekipy przed jego finiszem z koła.',
        tags: ['Surfing', 'Aero', 'Moc'],
      ),
    ],
    NicknameArchetype.timeTrialMachine: [
      _NicknameTemplate(
        pattern: 'Metronom {last}',
        source: NicknameOriginSource.sportsMedia,
        reasonTemplate:
            'Utrzymuje równe {ftp} W w pozycji czasowej bez sekundy zawahania.',
        tags: ['ITT', 'Rytm', 'Aero'],
      ),
      _NicknameTemplate(
        pattern: 'Ludzki Tunel Aero',
        source: NicknameOriginSource.cyclingPodcast,
        reasonTemplate:
            'Nienaganna sylwetka TT (ocena {tt}/100) tnie powietrze jak nóż.',
        tags: ['CdA', 'Czasówka', 'Technologia'],
      ),
      _NicknameTemplate(
        pattern: '{lion} z Czasówki',
        source: NicknameOriginSource.fanPeloton,
        reasonTemplate:
            'Fani doceniają samotną walkę z wiatrem i zegarem na płaskich trasach.',
        tags: ['Solo', 'FTP', 'Zegar'],
      ),
      _NicknameTemplate(
        pattern: 'Cichy Generator Watów',
        source: NicknameOriginSource.teammatesLockerRoom,
        reasonTemplate:
            'Koledzy z zespołu wiedzą, że na jego kole można przejechać cały dzień.',
        tags: ['Silnik', 'Tempo', 'TT'],
      ),
    ],
    NicknameArchetype.cobbleGladiator: [
      _NicknameTemplate(
        pattern: '{lion} Piekła Północy',
        source: NicknameOriginSource.sportsMedia,
        reasonTemplate:
            'Ocena jazdy po bruku {cobbles}/100 i odporność na deszcz budzą respekt.',
        tags: ['Bruk', 'Monumenty', 'Roubaix'],
      ),
      _NicknameTemplate(
        pattern: 'Żelazny Brukarz',
        source: NicknameOriginSource.roadSideUltras,
        reasonTemplate:
            'Belgijskie sektory 5★ pokonuje bez zwalniania na śliskich kamieniach.',
        tags: ['Flandria', 'Sektory', 'Klasyki'],
      ),
      _NicknameTemplate(
        pattern: 'Gladiator z Arenbergu',
        source: NicknameOriginSource.fanPeloton,
        reasonTemplate:
            'Kibice uwielbiają jego bezkompromisową walkę w błocie i wietrze.',
        tags: ['Błoto', 'Wachlarze', 'Waleczność'],
      ),
      _NicknameTemplate(
        pattern: '{adjective} Młot na Wiatr',
        source: NicknameOriginSource.rivalDs,
        reasonTemplate:
            'Rywale obawiają się, gdy wchodzi na czoło na bocznych rantach.',
        tags: ['Echelon', 'Siła', 'Wiatr'],
      ),
    ],
    NicknameArchetype.breakawayPhantom: [
      _NicknameTemplate(
        pattern: 'Duch Odjazdu',
        source: NicknameOriginSource.sportsMedia,
        reasonTemplate:
            'Przejechał {breakKm} km w ucieczkach, regularnie zgarniając czerwony numer.',
        tags: ['Ucieczka', 'Aktywność', 'Odwaga'],
      ),
      _NicknameTemplate(
        pattern: 'Wilk Samotnik',
        source: NicknameOriginSource.fanPeloton,
        reasonTemplate:
            'Nigdy nie kalkuluje i atakuje od pierwszego kilometra po starcie ostrym.',
        tags: ['Solo', 'Atak', 'Serce'],
      ),
      _NicknameTemplate(
        pattern: 'Kolekcjoner Czerwonych Numerów',
        source: NicknameOriginSource.cyclingPodcast,
        reasonTemplate:
            'Jury wyścigów nie nadąża z przyznawaniem mu nagród dla najaktywniejszego.',
        tags: ['Combativity', 'Show', 'Peleton'],
      ),
      _NicknameTemplate(
        pattern: 'Niewidzialny Szablozębny',
        source: NicknameOriginSource.rivalDs,
        reasonTemplate:
            'Peleton zawsze orientuje się za późno, że znów odjechał na 4 minuty.',
        tags: ['Taktyka', 'Odjazd', 'Zaskoczenie'],
      ),
    ],
    NicknameArchetype.descentDaredevil: [
      _NicknameTemplate(
        pattern: 'Sokół Zjazdów',
        source: NicknameOriginSource.sportsMedia,
        reasonTemplate:
            'Umiejętności zjazdowe ({desc}/100) pozwalają mu nadrabiać dziesiątki sekund.',
        tags: ['Zjazdy', 'Serpentyny', 'Prędkość'],
      ),
      _NicknameTemplate(
        pattern: 'Mistrz Wiraży',
        source: NicknameOriginSource.roadSideUltras,
        reasonTemplate:
            'Wchodzi w alpejskie agrafki z precyzją kierowcy rajdowego.',
        tags: ['Alpy', 'Agrafki', 'Odwaga'],
      ),
      _NicknameTemplate(
        pattern: 'Cień na Ramie',
        source: NicknameOriginSource.cyclingPodcast,
        reasonTemplate:
            'Aerodynamiczna sylwetka na zjazdach przyprawia widzów o dreszcze.',
        tags: ['Aero', 'Supertuck', 'Adrenalina'],
      ),
    ],
    NicknameArchetype.domestiqueGuardian: [
      _NicknameTemplate(
        pattern: 'Anioł Stróż Lidera',
        source: NicknameOriginSource.teammatesLockerRoom,
        reasonTemplate:
            'Zawsze dowozi bidony, osłania od wiatru i oddaje własne koło w kryzysie.',
        tags: ['Lojalność', 'Pomocnik', 'Drużyna'],
      ),
      _NicknameTemplate(
        pattern: 'El Tractor z {region}',
        source: NicknameOriginSource.fanPeloton,
        reasonTemplate:
            'Kibice pokochali jego tytaniczną pracę na czele peletonu przez 150 km.',
        tags: ['Silnik', 'Praca', 'Szacunek'],
      ),
      _NicknameTemplate(
        pattern: 'Żelazny Kapitan Szosy',
        source: NicknameOriginSource.sportsMedia,
        reasonTemplate:
            'Dyryguje taktyką drużyny na trasie i gasi każdy pożar w grupie.',
        tags: ['Kapitan', 'Radio', 'Spokój'],
      ),
    ],
    NicknameArchetype.ironSurvivor: [
      _NicknameTemplate(
        pattern: 'Niezniszczalny {last}',
        source: NicknameOriginSource.sportsMedia,
        reasonTemplate:
            'Po przetrwanych kraksach ({crashes}) i ekstremalnych warunkach wciąż walczy.',
        tags: ['Charakter', 'Odporność', 'Wola'],
      ),
      _NicknameTemplate(
        pattern: 'Feniks Szosy',
        source: NicknameOriginSource.fanPeloton,
        reasonTemplate:
            'Im cięższy etap i gorsza pogoda, tym mocniej błyszczy w końcówce.',
        tags: ['Deszcz', 'Upał', 'Powrót'],
      ),
      _NicknameTemplate(
        pattern: 'Człowiek ze Stali',
        source: NicknameOriginSource.teammatesLockerRoom,
        reasonTemplate:
            'W trzecim tygodniu Wielkiego Touru wygląda tak świeżo jak na prologu.',
        tags: ['Wytrzymałość', '3. Tydzień', 'GT'],
      ),
    ],
    NicknameArchetype.tacticalProfessor: [
      _NicknameTemplate(
        pattern: 'Profesor Peletonu',
        source: NicknameOriginSource.cyclingPodcast,
        reasonTemplate:
            'Wyścigowe IQ ({iq}/100) sprawia, że zawsze jest o dwa ruchy przed rywalami.',
        tags: ['Race IQ', 'Szachy', 'Strategia'],
      ),
      _NicknameTemplate(
        pattern: 'Szachista Szosy',
        source: NicknameOriginSource.sportsMedia,
        reasonTemplate:
            'Wybiera dokładnie ten moment do ataku, w którym rywale nie mają już sił.',
        tags: ['Timing', 'Inteligencja', 'Finał'],
      ),
      _NicknameTemplate(
        pattern: 'Maestro {last}',
        source: NicknameOriginSource.rivalDs,
        reasonTemplate:
            'Czyta wiatr i ustawienie peletonu lepiej niż niejeden dyrektor sportowy.',
        tags: ['Pozycjonowanie', 'Doświadczenie', 'Klasa'],
      ),
    ],
    NicknameArchetype.cultFanFavorite: [
      _NicknameTemplate(
        pattern: 'Pan Piękna Jazda',
        source: NicknameOriginSource.fanPeloton,
        reasonTemplate:
            'Charyzma i widowiskowy styl jazdy przyciągają tłumy pod autobus ekipy.',
        tags: ['Charyzma', 'Fani', 'Show'],
      ),
      _NicknameTemplate(
        pattern: 'Król Bidonów',
        source: NicknameOriginSource.roadSideUltras,
        reasonTemplate:
            'Kibice na poboczach czekają na jego gesty i pamiątkowe bidony.',
        tags: ['Kibice', 'Relacje', 'Kult'],
      ),
      _NicknameTemplate(
        pattern: '{adjective} Showman',
        source: NicknameOriginSource.cyclingPodcast,
        reasonTemplate:
            'Każdy jego wywiad i atak w końcówce generuje tysiące udostępnień.',
        tags: ['Media', 'Popularność', 'Ikona'],
      ),
    ],
  };

  /// Ocenia dopasowanie wszystkich archetypów do profilu kolarza (malejąco).
  List<MapEntry<NicknameArchetype, int>> evaluateArchetypes(
    RiderNicknameInput input,
  ) {
    final wkg = input.wPerKg20m;
    final scores = <NicknameArchetype, double>{
      NicknameArchetype.mountainGoat:
          ((wkg - 4.5) * 32.0) +
          (input.specialization == RiderSpecialization.pureClimber ? 25.0 : 0) +
          (input.specialization == RiderSpecialization.gcClimber ? 18.0 : 0) +
          input.grandTourStages * 4.0,
      NicknameArchetype.sprintRocket:
          ((input.watts5s - 950.0) / 14.0) +
          (input.specialization == RiderSpecialization.pureSprinter
              ? 28.0
              : 0) +
          (input.specialization == RiderSpecialization.versatileSprinter
              ? 18.0
              : 0) +
          input.careerWins * 1.5,
      NicknameArchetype.timeTrialMachine:
          (input.timeTrialPositioning * 0.85) +
          ((input.ftpWatts - 340.0) / 3.5) +
          (input.specialization == RiderSpecialization.timeTrialist
              ? 26.0
              : 0),
      NicknameArchetype.cobbleGladiator:
          (input.cobbles * 0.8) +
          (input.rainResistance * 0.25) +
          (input.specialization == RiderSpecialization.classicCobbles
              ? 24.0
              : 0) +
          input.monumentWins * 10.0,
      NicknameArchetype.breakawayPhantom:
          (input.combativityAwards * 12.0) +
          (input.breakawayKm / 35.0) +
          (input.specialization == RiderSpecialization.breakawaySpecialist
              ? 28.0
              : 0) +
          35.0,
      NicknameArchetype.descentDaredevil:
          (input.descending * 0.92) + (input.raceIq * 0.12),
      NicknameArchetype.domestiqueGuardian:
          (input.specialization == RiderSpecialization.domestiqueEngine
              ? 42.0
              : 15.0) +
          (input.age >= 28 ? 14.0 : 0.0) +
          (input.raceIq * 0.3),
      NicknameArchetype.ironSurvivor:
          (input.crashesSurvived * 14.0) +
          ((input.rainResistance + input.heatTolerance) * 0.35) +
          (input.age >= 30 ? 12.0 : 0.0),
      NicknameArchetype.tacticalProfessor:
          (input.raceIq * 0.88) + (input.age >= 27 ? 14.0 : 0.0),
      NicknameArchetype.cultFanFavorite:
          (input.fanPopularity * 0.72) + (input.mediaHype * 0.32),
    };

    final normalized = scores.entries.map((entry) {
      final clamped = entry.value.round().clamp(15, 99);
      return MapEntry(entry.key, clamped);
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    return normalized;
  }

  /// Wyznacza poziom rzadkości przydomka na podstawie osiągnięć i rozgłosu.
  NicknameRarityTier evaluateRarityTier(RiderNicknameInput input) {
    final achievementScore =
        input.monumentWins * 28 +
        input.grandTourStages * 12 +
        input.careerWins * 3 +
        (input.mediaHype * 0.35).round() +
        (input.fanPopularity * 0.35).round();

    if (achievementScore >= 115 || input.monumentWins >= 2) {
      return NicknameRarityTier.legendary;
    }
    if (achievementScore >= 85 || input.monumentWins >= 1) {
      return NicknameRarityTier.monumental;
    }
    if (achievementScore >= 58 || input.grandTourStages >= 2) {
      return NicknameRarityTier.worldTour;
    }
    if (achievementScore >= 36 || input.careerWins >= 3) {
      return NicknameRarityTier.national;
    }
    return NicknameRarityTier.local;
  }

  /// Generuje unikalną listę kandydatów przydomków dla danego kolarza.
  List<NicknameGenerationCandidate> generateCandidates(
    RiderNicknameInput input, {
    int count = 4,
    Set<String> existingNicknames = const {},
    int? seed,
  }) {
    if (count <= 0) return const [];

    final random = math.Random(
      seed ??
          (input.riderId.hashCode ^
              input.seasonYear ^
              input.careerWins ^
              input.fanPopularity),
    );
    final rankedArchetypes = evaluateArchetypes(input);
    final rarity = evaluateRarityTier(input);
    final flavor =
        _nationalityFlavors[input.nationalityIso.toUpperCase()] ??
        _defaultFlavor;
    final existingNormalized = existingNicknames
        .map((e) => e.trim().toLowerCase())
        .toSet();

    final candidates = <NicknameGenerationCandidate>[];
    final seenNames = <String>{...existingNormalized};

    // Przejdź przez topowe archetypy, losując warianty z każdego z nich.
    for (var round = 0; round < 3 && candidates.length < count; round++) {
      for (final entry in rankedArchetypes) {
        if (candidates.length >= count) break;
        final archetype = entry.key;
        final templates = List<_NicknameTemplate>.from(
          _templates[archetype] ?? const [],
        )..shuffle(random);

        for (final tpl in templates) {
          final rendered = _renderPattern(tpl.pattern, input, flavor);
          final key = rendered.toLowerCase();
          if (seenNames.contains(key)) continue;

          seenNames.add(key);
          final reason = _renderReason(tpl.reasonTemplate, input);
          final headline = generateMediaHeadline(
            riderFullName: input.fullName,
            nickname: rendered,
            source: tpl.source,
            raceName: input.notableRaceName,
          );
          final fitBoost = (entry.value - round * 4).clamp(20, 99);

          candidates.add(
            NicknameGenerationCandidate(
              nickname: rendered,
              archetype: archetype,
              originSource: tpl.source,
              rarityTier: rarity,
              fitScore: fitBoost,
              loreReason: reason,
              mediaHeadline: headline,
              tags: tpl.tags,
            ),
          );
          break;
        }
      }
    }

    return candidates;
  }

  /// Tworzy autentyczny nagłówek prasowy lub komentarz kibicowski.
  String generateMediaHeadline({
    required String riderFullName,
    required String nickname,
    required NicknameOriginSource source,
    String? raceName,
  }) {
    final race = (raceName != null && raceName.trim().isNotEmpty)
        ? raceName.trim()
        : 'WorldTour';
    final name = riderFullName.isNotEmpty ? riderFullName : 'Kolarz';

    switch (source) {
      case NicknameOriginSource.sportsMedia:
        return 'PRASA ($race): „$nickname” — $name zachwyca kolarski świat!';
      case NicknameOriginSource.fanPeloton:
        return 'FORA KIBICÓW: Flagi z napisem „$nickname” zalewają trasę $race.';
      case NicknameOriginSource.roadSideUltras:
        return 'PRZEŁĘCZ: Kibice wymalowali na asfalcie „$nickname” przed przyjazdem $name!';
      case NicknameOriginSource.teammatesLockerRoom:
        return 'AUTOBUS EKIPY: Koledzy mówią na niego „$nickname” po występie w $race.';
      case NicknameOriginSource.rivalDs:
        return 'RADIO RYWALI: „Uważajcie na $nickname, znów szykuje akcję!”';
      case NicknameOriginSource.cyclingPodcast:
        return 'PODCAST KOLARSKI: Czy „$nickname” to nowy fenomen w $race?';
    }
  }

  /// Oblicza bonusy marketingowe i mentalne płynące z aktywnego przydomka.
  NicknameMarketingImpact computeMarketingImpact(RiderNicknameRecord? active) {
    if (active == null) return NicknameMarketingImpact.zero;
    final mult = active.rarityTier.prestigeMultiplier;
    final popFactor = (active.popularityScore / 100.0).clamp(0.2, 1.0);
    final flockBonus = active.jerseyFlockApproved ? 0.12 : 0.0;

    final morale = (2 + (mult * 2.5 * popFactor)).round().clamp(1, 10);
    final merch = double.parse(
      (1.0 + (0.14 * mult * popFactor) + flockBonus).toStringAsFixed(2),
    );
    final sponsorPct = double.parse(
      (3.5 * mult * popFactor + (active.jerseyFlockApproved ? 2.5 : 0.0))
          .toStringAsFixed(1),
    );

    return NicknameMarketingImpact(
      moraleBonus: morale,
      fanMerchandiseMultiplier: merch,
      sponsorAppealBonusPct: sponsorPct,
    );
  }

  /// Waliduje własny przydomek wpisany przez gracza lub kibiców.
  ({bool isValid, String? error, String sanitized}) validateCustomNickname(
    String raw,
  ) {
    final sanitized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (sanitized.length < 3) {
      return (
        isValid: false,
        error: 'Przydomek musi mieć co najmniej 3 znaki.',
        sanitized: sanitized,
      );
    }
    if (sanitized.length > 32) {
      return (
        isValid: false,
        error: 'Przydomek może mieć maksymalnie 32 znaki.',
        sanitized: sanitized,
      );
    }
    if (RegExp(r'[<>{}\[\]\\\/]').hasMatch(sanitized)) {
      return (
        isValid: false,
        error: 'Niedozwolone znaki specjalne w przydomku.',
        sanitized: sanitized,
      );
    }
    return (isValid: true, error: null, sanitized: sanitized);
  }

  String _renderPattern(
    String pattern,
    RiderNicknameInput input,
    _NationalityFlavor flavor,
  ) {
    final region = (input.notableLocation != null &&
            input.notableLocation!.trim().isNotEmpty)
        ? input.notableLocation!.trim()
        : flavor.regionLabel;
    final last = input.lastName.trim().isNotEmpty
        ? input.lastName.trim()
        : input.firstName.trim();

    return pattern
        .replaceAll('{eagle}', flavor.eagleTitle)
        .replaceAll('{lion}', flavor.lionTitle)
        .replaceAll('{adjective}', flavor.adjectiveMasc)
        .replaceAll('{region}', region)
        .replaceAll('{last}', last.isNotEmpty ? last : 'Mistrz');
  }

  String _renderReason(String template, RiderNicknameInput input) {
    return template
        .replaceAll('{wkg}', input.wPerKg20m.toStringAsFixed(2))
        .replaceAll('{watts5s}', input.watts5s.round().toString())
        .replaceAll('{ftp}', input.ftpWatts.round().toString())
        .replaceAll('{tt}', input.timeTrialPositioning.toString())
        .replaceAll('{cobbles}', input.cobbles.toString())
        .replaceAll('{breakKm}', input.breakawayKm.toString())
        .replaceAll('{desc}', input.descending.toString())
        .replaceAll('{crashes}', input.crashesSurvived.toString())
        .replaceAll('{iq}', input.raceIq.toString());
  }
}

/// Stan modułu generatora przydomków kolarskich w Riverpod.
class DynamicRiderNicknameState {
  final RiderNicknameInput? currentInput;
  final Map<String, List<RiderNicknameRecord>> nicknamesByRider;
  final List<NicknameGenerationCandidate> candidates;
  final NicknameOriginSource? filterSource;
  final String searchQuery;
  final String? statusBanner;
  final bool isErrorBanner;

  const DynamicRiderNicknameState({
    this.currentInput,
    this.nicknamesByRider = const {},
    this.candidates = const [],
    this.filterSource,
    this.searchQuery = '',
    this.statusBanner,
    this.isErrorBanner = false,
  });

  List<RiderNicknameRecord> get activeRiderNicknames {
    final input = currentInput;
    if (input == null) return const [];
    return nicknamesByRider[input.riderId] ?? const [];
  }

  RiderNicknameRecord? get primaryNickname {
    for (final rec in activeRiderNicknames) {
      if (rec.isActivePrimary) return rec;
    }
    return null;
  }

  List<RiderNicknameRecord> get filteredRiderNicknames {
    final query = searchQuery.trim().toLowerCase();
    return activeRiderNicknames.where((rec) {
      if (filterSource != null && rec.originSource != filterSource) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchName = rec.nickname.toLowerCase().contains(query);
        final matchArchetype = rec.archetype.label.toLowerCase().contains(
          query,
        );
        final matchTags = rec.tags.any((t) => t.toLowerCase().contains(query));
        if (!matchName && !matchArchetype && !matchTags) return false;
      }
      return true;
    }).toList();
  }

  DynamicRiderNicknameState copyWith({
    RiderNicknameInput? currentInput,
    Map<String, List<RiderNicknameRecord>>? nicknamesByRider,
    List<NicknameGenerationCandidate>? candidates,
    NicknameOriginSource? filterSource,
    bool clearFilterSource = false,
    String? searchQuery,
    String? statusBanner,
    bool clearStatusBanner = false,
    bool? isErrorBanner,
  }) {
    return DynamicRiderNicknameState(
      currentInput: currentInput ?? this.currentInput,
      nicknamesByRider: nicknamesByRider ?? this.nicknamesByRider,
      candidates: candidates ?? this.candidates,
      filterSource: clearFilterSource
          ? null
          : (filterSource ?? this.filterSource),
      searchQuery: searchQuery ?? this.searchQuery,
      statusBanner: clearStatusBanner
          ? null
          : (statusBanner ?? this.statusBanner),
      isErrorBanner: isErrorBanner ?? this.isErrorBanner,
    );
  }
}

/// Notifier zarządzający cyklem życia przydomków kolarzy w karierze.
class DynamicRiderNicknameNotifier
    extends StateNotifier<DynamicRiderNicknameState> {
  final DynamicRiderNicknameGenerator _generator;
  int _generationCounter = 0;

  DynamicRiderNicknameNotifier({
    DynamicRiderNicknameGenerator generator =
        const DynamicRiderNicknameGenerator(),
    RiderNicknameInput? initialInput,
  }) : _generator = generator,
       super(const DynamicRiderNicknameState()) {
    if (initialInput != null) {
      selectRider(initialInput);
    }
  }

  void selectRider(RiderNicknameInput input) {
    final existing = state.nicknamesByRider[input.riderId] ?? const [];
    final existingNames = existing.map((e) => e.nickname).toSet();
    final candidates = _generator.generateCandidates(
      input,
      count: 4,
      existingNicknames: existingNames,
      seed: input.riderId.hashCode ^ _generationCounter,
    );
    state = state.copyWith(
      currentInput: input,
      candidates: candidates,
      clearStatusBanner: true,
      isErrorBanner: false,
    );
  }

  void regenerateCandidates({int? seed}) {
    final input = state.currentInput;
    if (input == null) return;
    _generationCounter++;
    final existing = state.nicknamesByRider[input.riderId] ?? const [];
    final existingNames = existing.map((e) => e.nickname).toSet();
    final candidates = _generator.generateCandidates(
      input,
      count: 4,
      existingNicknames: existingNames,
      seed: seed ?? (input.riderId.hashCode + _generationCounter * 97),
    );
    state = state.copyWith(
      candidates: candidates,
      statusBanner:
          'Wygenerowano ${candidates.length} nowe propozycje od mediów i kibiców.',
      isErrorBanner: false,
    );
  }

  NicknameAdoptionOutcome adoptCandidate(
    NicknameGenerationCandidate candidate, {
    bool setAsPrimary = true,
  }) {
    final input = state.currentInput;
    if (input == null) {
      return const NicknameAdoptionOutcome(
        success: false,
        message: 'Brak wybranego kolarza.',
        impact: NicknameMarketingImpact.zero,
      );
    }

    final currentList = List<RiderNicknameRecord>.from(
      state.nicknamesByRider[input.riderId] ?? const [],
    );
    final duplicate = currentList.any(
      (r) => r.nickname.toLowerCase() == candidate.nickname.toLowerCase(),
    );
    if (duplicate) {
      state = state.copyWith(
        statusBanner: 'Kolarz posiada już przydomek „${candidate.nickname}”.',
        isErrorBanner: true,
      );
      return NicknameAdoptionOutcome(
        success: false,
        message: 'Przydomek już istnieje w archiwum kolarza.',
        impact: _generator.computeMarketingImpact(state.primaryNickname),
      );
    }

    final updatedList = currentList
        .map(
          (r) => setAsPrimary ? r.copyWith(isActivePrimary: false) : r,
        )
        .toList();

    final record = RiderNicknameRecord(
      id: 'nick_${input.riderId}_${DateTime.now().microsecondsSinceEpoch}',
      riderId: input.riderId,
      nickname: candidate.nickname,
      loreReason: candidate.loreReason,
      mediaHeadline: candidate.mediaHeadline,
      originSource: candidate.originSource,
      archetype: candidate.archetype,
      rarityTier: candidate.rarityTier,
      popularityScore: ((candidate.fitScore + input.fanPopularity) / 2)
          .round()
          .clamp(25, 99),
      jerseyFlockApproved: setAsPrimary,
      isActivePrimary: setAsPrimary,
      awardedSeason: input.seasonYear,
      awardedRaceName: input.notableRaceName ?? 'Sezon ${input.seasonYear}',
      awardedAtIso: DateTime.now().toIso8601String(),
      tags: candidate.tags,
    );

    updatedList.insert(0, record);
    final nextMap = Map<String, List<RiderNicknameRecord>>.from(
      state.nicknamesByRider,
    )..[input.riderId] = updatedList;

    final remainingCandidates = state.candidates
        .where((c) => c.nickname != candidate.nickname)
        .toList();

    final impact = _generator.computeMarketingImpact(
      setAsPrimary ? record : state.primaryNickname,
    );

    state = state.copyWith(
      nicknamesByRider: nextMap,
      candidates: remainingCandidates,
      statusBanner: 'Nadano przydomek „${record.nickname}” (${record.originSource.label}).',
      isErrorBanner: false,
    );

    return NicknameAdoptionOutcome(
      success: true,
      message: 'Nadano przydomek „${record.nickname}”.',
      impact: impact,
      activeNickname: setAsPrimary ? record : state.primaryNickname,
    );
  }

  NicknameAdoptionOutcome addCustomNickname({
    required String rawNickname,
    required NicknameOriginSource source,
    required NicknameArchetype archetype,
  }) {
    final input = state.currentInput;
    if (input == null) {
      return const NicknameAdoptionOutcome(
        success: false,
        message: 'Brak wybranego kolarza.',
        impact: NicknameMarketingImpact.zero,
      );
    }

    final validation = _generator.validateCustomNickname(rawNickname);
    if (!validation.isValid) {
      state = state.copyWith(
        statusBanner: validation.error,
        isErrorBanner: true,
      );
      return NicknameAdoptionOutcome(
        success: false,
        message: validation.error ?? 'Nieprawidłowy przydomek.',
        impact: _generator.computeMarketingImpact(state.primaryNickname),
      );
    }

    final rarity = _generator.evaluateRarityTier(input);
    final candidate = NicknameGenerationCandidate(
      nickname: validation.sanitized,
      archetype: archetype,
      originSource: source,
      rarityTier: rarity,
      fitScore: 85,
      loreReason: 'Własny przydomek nadany w trakcie kariery menedżerskiej.',
      mediaHeadline: _generator.generateMediaHeadline(
        riderFullName: input.fullName,
        nickname: validation.sanitized,
        source: source,
        raceName: input.notableRaceName,
      ),
      tags: ['Własny', archetype.label, source.shortLabel],
    );

    return adoptCandidate(candidate, setAsPrimary: true);
  }

  void setPrimaryNickname(String riderId, String nicknameId) {
    final list = state.nicknamesByRider[riderId];
    if (list == null) return;

    final updated = list
        .map((r) => r.copyWith(isActivePrimary: r.id == nicknameId))
        .toList();
    final nextMap = Map<String, List<RiderNicknameRecord>>.from(
      state.nicknamesByRider,
    )..[riderId] = updated;

    final primary = updated.where((r) => r.isActivePrimary).firstOrNull;
    state = state.copyWith(
      nicknamesByRider: nextMap,
      statusBanner: primary != null
          ? 'Aktywny przydomek ustawiony na „${primary.nickname}”.'
          : null,
      isErrorBanner: false,
    );
  }

  void toggleJerseyFlock(String riderId, String nicknameId) {
    final list = state.nicknamesByRider[riderId];
    if (list == null) return;

    final updated = list
        .map(
          (r) => r.id == nicknameId
              ? r.copyWith(jerseyFlockApproved: !r.jerseyFlockApproved)
              : r,
        )
        .toList();
    final nextMap = Map<String, List<RiderNicknameRecord>>.from(
      state.nicknamesByRider,
    )..[riderId] = updated;

    state = state.copyWith(
      nicknamesByRider: nextMap,
      statusBanner: 'Zaktualizowano nadruk przydomka na koszulce kibicowskiej.',
      isErrorBanner: false,
    );
  }

  void retireNickname(String riderId, String nicknameId) {
    final list = state.nicknamesByRider[riderId];
    if (list == null) return;

    final updated = list.where((r) => r.id != nicknameId).toList();
    if (updated.isNotEmpty && !updated.any((r) => r.isActivePrimary)) {
      updated[0] = updated[0].copyWith(isActivePrimary: true);
    }

    final nextMap = Map<String, List<RiderNicknameRecord>>.from(
      state.nicknamesByRider,
    )..[riderId] = updated;

    state = state.copyWith(
      nicknamesByRider: nextMap,
      statusBanner: 'Usunięto przydomek z aktywnego profilu kolarza.',
      isErrorBanner: false,
    );
  }

  void setFilterSource(NicknameOriginSource? source) {
    if (source == null || source == state.filterSource) {
      state = state.copyWith(clearFilterSource: true);
    } else {
      state = state.copyWith(filterSource: source);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Map<String, dynamic> toJson() {
    return {
      'nicknamesByRider': state.nicknamesByRider.map(
        (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
      ),
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    final raw = json['nicknamesByRider'] as Map<String, dynamic>? ?? const {};
    final parsed = <String, List<RiderNicknameRecord>>{};
    for (final entry in raw.entries) {
      final list = (entry.value as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RiderNicknameRecord.fromJson)
          .toList();
      parsed[entry.key] = list;
    }
    state = state.copyWith(nicknamesByRider: parsed);
  }
}

/// Domyślny profil demo używany przy samodzielnym otwarciu panelu.
const RiderNicknameInput _defaultDemoRiderInput = RiderNicknameInput(
  riderId: 'demo_rider_01',
  firstName: 'Michał',
  lastName: 'Kowalski',
  nationalityIso: 'POL',
  age: 26,
  specialization: RiderSpecialization.gcClimber,
  ftpWatts: 418,
  weightKg: 65.5,
  watts5s: 1240,
  watts20m: 432,
  cobbles: 72,
  descending: 84,
  raceIq: 88,
  rainResistance: 79,
  heatTolerance: 75,
  timeTrialPositioning: 81,
  careerWins: 14,
  monumentWins: 1,
  grandTourStages: 3,
  combativityAwards: 4,
  crashesSurvived: 2,
  breakawayKm: 420,
  fanPopularity: 78,
  mediaHype: 82,
  seasonYear: 2026,
  notableRaceName: 'Tour de France',
  notableLocation: 'Alpe d’Huez',
);

final dynamicRiderNicknameProvider =
    StateNotifierProvider<
      DynamicRiderNicknameNotifier,
      DynamicRiderNicknameState
    >((ref) {
      return DynamicRiderNicknameNotifier(
        initialInput: _defaultDemoRiderInput,
      );
    });

/// Produkcyjny, responsywny panel zarządzania przydomkami kolarskimi (390x844, 1024x768, 1600x900).
class DynamicRiderNicknamePanel extends ConsumerStatefulWidget {
  final RiderNicknameInput? riderInput;

  const DynamicRiderNicknamePanel({super.key, this.riderInput});

  @override
  ConsumerState<DynamicRiderNicknamePanel> createState() =>
      _DynamicRiderNicknamePanelState();
}

class _DynamicRiderNicknamePanelState
    extends ConsumerState<DynamicRiderNicknamePanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customNickController = TextEditingController();
  NicknameOriginSource _customSource = NicknameOriginSource.fanPeloton;
  NicknameArchetype _customArchetype = NicknameArchetype.cultFanFavorite;

  @override
  void initState() {
    super.initState();
    if (widget.riderInput != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(dynamicRiderNicknameProvider.notifier)
              .selectRider(widget.riderInput!);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DynamicRiderNicknamePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.riderInput != null &&
        widget.riderInput?.riderId != oldWidget.riderInput?.riderId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(dynamicRiderNicknameProvider.notifier)
              .selectRider(widget.riderInput!);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customNickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dynamicRiderNicknameProvider);
    final notifier = ref.read(dynamicRiderNicknameProvider.notifier);
    final impact = const DynamicRiderNicknameGenerator().computeMarketingImpact(
      state.primaryNickname,
    );

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1180;
          final isTablet =
              constraints.maxWidth >= 720 && constraints.maxWidth < 1180;
          final padding = constraints.maxWidth < 600 ? 12.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(
                  state: state,
                  impact: impact,
                  onRegenerate: notifier.regenerateCandidates,
                  compact: constraints.maxWidth < 640,
                ),
                if (state.statusBanner != null) ...[
                  const SizedBox(height: 12),
                  _buildStatusBanner(
                    message: state.statusBanner!,
                    isError: state.isErrorBanner,
                  ),
                ],
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildCandidatesSection(state, notifier),
                            const SizedBox(height: 16),
                            _buildCustomCreatorCard(notifier),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _buildArchiveSection(state, notifier),
                      ),
                    ],
                  )
                else if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildCandidatesSection(state, notifier),
                            const SizedBox(height: 16),
                            _buildCustomCreatorCard(notifier),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildArchiveSection(state, notifier)),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCandidatesSection(state, notifier),
                      const SizedBox(height: 16),
                      _buildArchiveSection(state, notifier),
                      const SizedBox(height: 16),
                      _buildCustomCreatorCard(notifier),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard({
    required DynamicRiderNicknameState state,
    required NicknameMarketingImpact impact,
    required VoidCallback onRegenerate,
    required bool compact,
  }) {
    final input = state.currentInput;
    final primary = state.primaryNickname;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppColors.goldAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      input != null ? input.fullName : 'Generator Przydomków',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      primary != null
                          ? 'Aktywny przydomek: „${primary.nickname}”'
                          : 'Brak oficjalnego przydomka — wygeneruj lub nadaj własny',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: primary != null
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                _TactileActionButton(
                  label: 'Generuj Nowe',
                  icon: Icons.auto_awesome_rounded,
                  accentColor: AppColors.goldAccent,
                  filled: true,
                  enabled: input != null,
                  onPressed: onRegenerate,
                ),
              ],
            ],
          ),
          if (compact) ...[
            const SizedBox(height: 12),
            _TactileActionButton(
              label: 'Generuj Nowe',
              icon: Icons.auto_awesome_rounded,
              accentColor: AppColors.goldAccent,
              filled: true,
              enabled: input != null,
              onPressed: onRegenerate,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricPill(
                label: 'Morale Kolarza',
                value: '+${impact.moraleBonus}',
                color: AppColors.statusSuccess,
              ),
              _buildMetricPill(
                label: 'Sprzedaż Koszulek',
                value: '${impact.fanMerchandiseMultiplier.toStringAsFixed(2)}x',
                color: AppColors.accentBlue,
              ),
              _buildMetricPill(
                label: 'Atrakcyjność Sponsorów',
                value: '+${impact.sponsorAppealBonusPct.toStringAsFixed(1)}%',
                color: AppColors.goldAccent,
              ),
              if (input != null)
                _buildMetricPill(
                  label: 'W/kg (20 min)',
                  value: input.wPerKg20m.toStringAsFixed(2),
                  color: AppColors.cyanAccent,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '$label: ',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({required String message, required bool isError}) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesSection(
    DynamicRiderNicknameState state,
    DynamicRiderNicknameNotifier notifier,
  ) {
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
            children: [
              const Icon(
                Icons.mic_external_on_rounded,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Propozycje Mediów i Kibiców',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${state.candidates.length} szt.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.candidates.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Wszystkie bieżące propozycje zostały wykorzystane. Kliknij „Generuj Nowe”, aby wywołać nową falę medialną.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...state.candidates.map(
              (candidate) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCandidateCard(candidate, notifier),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(
    NicknameGenerationCandidate candidate,
    DynamicRiderNicknameNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                candidate.archetype.icon,
                color: candidate.originSource.accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '„${candidate.nickname}”',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildBadge(
                label: candidate.rarityTier.label,
                color: candidate.rarityTier.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            candidate.mediaHeadline,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            candidate.loreReason,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildBadge(
                    label: candidate.originSource.label,
                    color: candidate.originSource.accentColor,
                  ),
                  _buildBadge(
                    label: 'Dopasowanie ${candidate.fitScore}%',
                    color: AppColors.statusSuccess,
                  ),
                ],
              ),
              _TactileActionButton(
                label: 'Nadaj Przydomek',
                icon: Icons.check_rounded,
                accentColor: AppColors.primaryAccent,
                filled: true,
                onPressed: () => notifier.adoptCandidate(candidate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveSection(
    DynamicRiderNicknameState state,
    DynamicRiderNicknameNotifier notifier,
  ) {
    final records = state.filteredRiderNicknames;

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
          const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Historia i Aktywne Przydomki',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: notifier.setSearchQuery,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Szukaj przydomka, tagu lub archetypu...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
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
                borderSide: const BorderSide(color: AppColors.accentBlue),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FilterChipButton(
                label: 'Wszystkie',
                selected: state.filterSource == null,
                accentColor: AppColors.goldAccent,
                onTap: () => notifier.setFilterSource(null),
              ),
              ...NicknameOriginSource.values.map(
                (src) => _FilterChipButton(
                  label: src.shortLabel,
                  selected: state.filterSource == src,
                  accentColor: src.accentColor,
                  onTap: () => notifier.setFilterSource(src),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak zapisanych przydomków dla bieżących filtrów. Wybierz propozycję z listy obok lub utwórz własny.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...records.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildArchiveRecordCard(rec, notifier),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArchiveRecordCard(
    RiderNicknameRecord rec,
    DynamicRiderNicknameNotifier notifier,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rec.isActivePrimary
              ? AppColors.goldAccent
              : AppColors.cardBorder,
          width: rec.isActivePrimary ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                rec.isActivePrimary ? Icons.star_rounded : rec.archetype.icon,
                color: rec.isActivePrimary
                    ? AppColors.goldAccent
                    : rec.originSource.accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '„${rec.nickname}”',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: [
                  if (rec.isActivePrimary)
                    _buildBadge(label: 'GŁÓWNY', color: AppColors.goldAccent),
                  _buildBadge(
                    label: 'Popularność ${rec.popularityScore}',
                    color: AppColors.accentBlue,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${rec.awardedRaceName} (${rec.awardedSeason}) • ${rec.originSource.label}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rec.mediaHeadline,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TactileActionButton(
                label: rec.isActivePrimary ? 'Aktywny' : 'Ustaw Główny',
                icon: Icons.star_outline_rounded,
                accentColor: AppColors.goldAccent,
                enabled: !rec.isActivePrimary,
                onPressed: () =>
                    notifier.setPrimaryNickname(rec.riderId, rec.id),
              ),
              _TactileActionButton(
                label: rec.jerseyFlockApproved
                    ? 'Koszulka: TAK'
                    : 'Koszulka: NIE',
                icon: Icons.checkroom_rounded,
                accentColor: rec.jerseyFlockApproved
                    ? AppColors.statusSuccess
                    : AppColors.textSecondary,
                onPressed: () =>
                    notifier.toggleJerseyFlock(rec.riderId, rec.id),
              ),
              _TactileActionButton(
                label: 'Wycofaj',
                icon: Icons.delete_outline_rounded,
                accentColor: AppColors.crimsonAlert,
                onPressed: () => notifier.retireNickname(rec.riderId, rec.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCreatorCard(DynamicRiderNicknameNotifier notifier) {
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
          const Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: AppColors.cyanAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Własny Przydomek Kibicowski',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customNickController,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Np. El Tractor, Biały Orzeł...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
                borderSide: const BorderSide(color: AppColors.cyanAccent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<NicknameOriginSource>(
                value: _customSource,
                dropdownColor: AppColors.surfaceLight,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                items: NicknameOriginSource.values
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _customSource = val);
                },
              ),
              DropdownButton<NicknameArchetype>(
                value: _customArchetype,
                dropdownColor: AppColors.surfaceLight,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                items: NicknameArchetype.values
                    .map(
                      (a) => DropdownMenuItem(value: a, child: Text(a.label)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _customArchetype = val);
                },
              ),
              _TactileActionButton(
                label: 'Zapisz Własny',
                icon: Icons.add_rounded,
                accentColor: AppColors.cyanAccent,
                filled: true,
                onPressed: () {
                  final outcome = notifier.addCustomNickname(
                    rawNickname: _customNickController.text,
                    source: _customSource,
                    archetype: _customArchetype,
                  );
                  if (outcome.success) {
                    _customNickController.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Przycisk interaktywny z pełnymi stanami hover, active (pressed), focus i disabled.
class _TactileActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool filled;
  final bool enabled;
  final VoidCallback onPressed;

  const _TactileActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
    this.filled = false,
    this.enabled = true,
  });

  @override
  State<_TactileActionButton> createState() => _TactileActionButtonState();
}

class _TactileActionButtonState extends State<_TactileActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final baseColor = enabled ? widget.accentColor : AppColors.textSecondary;
    final bgColor = widget.filled
        ? (enabled
              ? baseColor.withValues(
                  alpha: _pressed ? 0.95 : (_hovered ? 0.35 : 0.22),
                )
              : AppColors.surfaceLight)
        : (_hovered && enabled
              ? baseColor.withValues(alpha: 0.14)
              : Colors.transparent);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
            _pressed ? 0.97 : 1.0,
            _pressed ? 0.97 : 1.0,
            1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.textPrimary
                  : baseColor.withValues(alpha: enabled ? 0.65 : 0.25),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: enabled
                    ? baseColor
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.accentColor.withValues(alpha: 0.22)
                : (_hovered
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.textPrimary
                  : (widget.selected
                        ? widget.accentColor
                        : AppColors.cardBorder),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
