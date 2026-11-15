// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../../models/career/staff_member.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';

/// Archetyp psychologiczny kolarza determinujący jego ego, ambicję i zachowania w peletonie.
enum PersonalityArchetype {
  /// Samiec Alfa (Alpha Leader)
  /// Ekstremalna ambicja i wysokie ego. Żąda statusu niekwestionowanego kapitana.
  /// Nie znosi pracy na innych i natychmiast buntuje się przy próbie degradacji (np. Hinault, Armstrong).
  alphaLeader,

  /// Lojalny Porucznik (Loyal Lieutenant / Super-Domestique)
  /// Wybitne umiejętności, lecz wysoka lojalność i skromność. Czerpie dumę z holowania lidera
  /// na szczyty alpejskie, dopóki jest traktowany sprawiedliwie (np. Kuss, Hincapie).
  loyalLieutenant,

  /// Młody Ambitny Wilczek (Young Ambitious Challenger)
  /// Niska cierpliwość, ogromna dynamika. Szybko kwestionuje hierarchię weteranów
  /// i przy pierwszej słabości lidera próbuje przejąć przywództwo (np. młody Pogačar, Evenepoel).
  youngAmbitiousChallenger,

  /// Doświadczony Kapitan Szosowy (Pragmatic Veteran Road Captain)
  /// Opanowany, taktyczny chłodny umysł. Potrafi studzić gorące głowy w zespole,
  /// bezbłędnie egzekwuje polecenia z wozu technicznego i cieszy się szacunkiem peletonu.
  pragmaticVeteran,

  /// Sprinter Primadonna (Prima Donna Sprinter)
  /// Skupiony na sobie, emocjonalny egocentryk. Wymaga dedykowanego pociągu 3 rozprowadzających.
  /// Jeśli pociąg zawiedzie na 500m do mety, głośno krytykuje kolegów w wywiadach telewizyjnych.
  primaDonnaSprinter;

  String toJson() => name;

  static PersonalityArchetype fromJson(String value) {
    return PersonalityArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PersonalityArchetype.alphaLeader,
    );
  }

  String get displayName {
    switch (this) {
      case PersonalityArchetype.alphaLeader:
        return 'Samiec Alfa (Alpha Leader)';
      case PersonalityArchetype.loyalLieutenant:
        return 'Lojalny Porucznik (Super-Domestique)';
      case PersonalityArchetype.youngAmbitiousChallenger:
        return 'Młody Ambitny Wilczek (Challenger)';
      case PersonalityArchetype.pragmaticVeteran:
        return 'Doświadczony Kapitan Szosowy (Veteran)';
      case PersonalityArchetype.primaDonnaSprinter:
        return 'Sprinter Primadonna (Finiszer)';
    }
  }
}

/// Szczegółowy profil psychologiczny kolarza w bazie zespołu.
class RiderPersonalityProfile {
  final String riderId;
  final PersonalityArchetype archetype;

  /// Ambicja sportowa (1-100): determinacja do wygrywania i walki o podium
  final int ambition;

  /// Poziom Ego (1-100): wysokie ego = brak chęci do wożenia bidonów i pracy na kolegów
  final int egoLevel;

  /// Lojalność zespołowa (1-100): skłonność do poświęcenia własnych szans dla dobra ekipy
  final int teamLoyalty;

  /// Skłonność do wywoływania skandali w mediach (1-100): gorące cytaty w strefie wywiadów
  final int mediaDramaProneness;

  /// Cierpliwość taktyczna (1-100): odporność na frustrację w oczekiwaniu na swoją szansę
  final int tacticalPatience;

  const RiderPersonalityProfile({
    required this.riderId,
    required this.archetype,
    required this.ambition,
    required this.egoLevel,
    required this.teamLoyalty,
    required this.mediaDramaProneness,
    required this.tacticalPatience,
  });

  RiderPersonalityProfile copyWith({
    String? riderId,
    PersonalityArchetype? archetype,
    int? ambition,
    int? egoLevel,
    int? teamLoyalty,
    int? mediaDramaProneness,
    int? tacticalPatience,
  }) {
    return RiderPersonalityProfile(
      riderId: riderId ?? this.riderId,
      archetype: archetype ?? this.archetype,
      ambition: ambition ?? this.ambition,
      egoLevel: egoLevel ?? this.egoLevel,
      teamLoyalty: teamLoyalty ?? this.teamLoyalty,
      mediaDramaProneness: mediaDramaProneness ?? this.mediaDramaProneness,
      tacticalPatience: tacticalPatience ?? this.tacticalPatience,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'archetype': archetype.toJson(),
        'ambition': ambition,
        'egoLevel': egoLevel,
        'teamLoyalty': teamLoyalty,
        'mediaDramaProneness': mediaDramaProneness,
        'tacticalPatience': tacticalPatience,
      };

  factory RiderPersonalityProfile.fromJson(Map<String, dynamic> json) {
    return RiderPersonalityProfile(
      riderId: json['riderId'] as String,
      archetype: PersonalityArchetype.fromJson(json['archetype'] as String),
      ambition: (json['ambition'] as num).toInt(),
      egoLevel: (json['egoLevel'] as num).toInt(),
      teamLoyalty: (json['teamLoyalty'] as num).toInt(),
      mediaDramaProneness: (json['mediaDramaProneness'] as num).toInt(),
      tacticalPatience: (json['tacticalPatience'] as num).toInt(),
    );
  }
}

/// Typ obietnicy złożonej kolarzowi podczas podpisywania kontraktu lub odprawy sezonowej.
enum ContractPromiseType {
  /// Obietnica bycia jedynym, niekwestionowanym liderem na wskazany Grand Tour
  soleLeaderGrandTour,

  /// Gwarancja statusu chronionego współlidera (Co-Leader)
  coLeaderProtected,

  /// Gwarancja dedykowanego pociągu sprinterskiego (min. 2 rozprowadzających)
  dedicatedSprintTrain,

  /// Gwarantowane miejsce w składzie na Grand Tour
  guaranteedGrandTourRoster,

  /// Wolna ręka w ucieczkach na etapach pagórkowatych i górskich (Stage Hunter)
  freeRoleStageHunting;

  String toJson() => name;

  static ContractPromiseType fromJson(String value) {
    return ContractPromiseType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ContractPromiseType.soleLeaderGrandTour,
    );
  }

  String get displayName {
    switch (this) {
      case ContractPromiseType.soleLeaderGrandTour:
        return 'Jedyny Lider na Grand Tourze (Sole Leader)';
      case ContractPromiseType.coLeaderProtected:
        return 'Status Chronionego Współlidera (Co-Leader)';
      case ContractPromiseType.dedicatedSprintTrain:
        return 'Dedykowany Pociąg Sprinterski';
      case ContractPromiseType.guaranteedGrandTourRoster:
        return 'Pewne Miejsce w Składzie na Grand Tour';
      case ContractPromiseType.freeRoleStageHunting:
        return 'Wolna Ręka w Ucieczkach (Stage Hunting)';
    }
  }
}

/// Status realizacji obietnicy kontraktowej.
enum ContractPromiseStatus {
  pending,
  fulfilled,
  broken;

  String toJson() => name;

  static ContractPromiseStatus fromJson(String value) {
    return ContractPromiseStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ContractPromiseStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ContractPromiseStatus.pending:
        return 'W trakcie sezonu (Aktywna)';
      case ContractPromiseStatus.fulfilled:
        return 'Dotrzymana (+Morale & Lojalność)';
      case ContractPromiseStatus.broken:
        return 'ZŁAMANA (Kryzys Lojalności & Żądanie Transferu)';
    }
  }
}

/// Obietnica kontraktowa złożona zawodnikowi przez menedżera klubu.
class RiderContractPromise {
  final String id;
  final String riderId;
  final ContractPromiseType type;
  final String? targetRaceId;
  final String? targetRaceName;
  final ContractPromiseStatus status;
  final DateTime promisedDate;
  final DateTime? resolvedDate;
  final bool brokenPenaltyApplied;

  const RiderContractPromise({
    required this.id,
    required this.riderId,
    required this.type,
    this.targetRaceId,
    this.targetRaceName,
    this.status = ContractPromiseStatus.pending,
    required this.promisedDate,
    this.resolvedDate,
    this.brokenPenaltyApplied = false,
  });

  RiderContractPromise copyWith({
    String? id,
    String? riderId,
    ContractPromiseType? type,
    String? targetRaceId,
    String? targetRaceName,
    ContractPromiseStatus? status,
    DateTime? promisedDate,
    DateTime? resolvedDate,
    bool? brokenPenaltyApplied,
  }) {
    return RiderContractPromise(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      type: type ?? this.type,
      targetRaceId: targetRaceId ?? this.targetRaceId,
      targetRaceName: targetRaceName ?? this.targetRaceName,
      status: status ?? this.status,
      promisedDate: promisedDate ?? this.promisedDate,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      brokenPenaltyApplied: brokenPenaltyApplied ?? this.brokenPenaltyApplied,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'type': type.toJson(),
        'targetRaceId': targetRaceId,
        'targetRaceName': targetRaceName,
        'status': status.toJson(),
        'promisedDate': promisedDate.toIso8601String(),
        'resolvedDate': resolvedDate?.toIso8601String(),
        'brokenPenaltyApplied': brokenPenaltyApplied,
      };

  factory RiderContractPromise.fromJson(Map<String, dynamic> json) {
    return RiderContractPromise(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      type: ContractPromiseType.fromJson(json['type'] as String),
      targetRaceId: json['targetRaceId'] as String?,
      targetRaceName: json['targetRaceName'] as String?,
      status: ContractPromiseStatus.fromJson(json['status'] as String),
      promisedDate: DateTime.parse(json['promisedDate'] as String),
      resolvedDate: json['resolvedDate'] != null
          ? DateTime.parse(json['resolvedDate'] as String)
          : null,
      brokenPenaltyApplied: json['brokenPenaltyApplied'] as bool? ?? false,
    );
  }
}

/// Strategia podziału ról i hierarchii przed wyścigiem.
enum RaceHierarchyStrategy {
  /// Bezwzględny, jedyny lider #1. Cała 7-ka jedzie wyłącznie na niego.
  absoluteSoleLeader,

  /// Meritokracja dwóch współliderów: rywalizują na trasie do 9-10. etapu;
  /// kolarz z większą stratą czasową bezdyskusyjnie przechodzi do roli pomocnika.
  dualLeaderMeritocracy,

  /// Równorzędny status dwóch liderów przez cały wyścig (bardzo wysokie ryzyko bratobójczej walki).
  sharedCoLeadership,

  /// Brak jasnych ustaleń menedżera (najbardziej toksyczna sytuacja – natychmiastowe zarzewie buntu).
  undefinedAmbiguity;

  String toJson() => name;

  static RaceHierarchyStrategy fromJson(String value) {
    return RaceHierarchyStrategy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RaceHierarchyStrategy.absoluteSoleLeader,
    );
  }

  String get displayName {
    switch (this) {
      case RaceHierarchyStrategy.absoluteSoleLeader:
        return 'Niekwestionowany Jedyny Lider (Sole Leader)';
      case RaceHierarchyStrategy.dualLeaderMeritocracy:
        return 'Meritokracja Dwóch Liderów (Test do 10. etapu)';
      case RaceHierarchyStrategy.sharedCoLeadership:
        return 'Równorzędne Współliderowanie (Shared Co-Leaders)';
      case RaceHierarchyStrategy.undefinedAmbiguity:
        return 'Brak Jasnej Hierarchii (Chaos Taktyczny)';
    }
  }
}

/// Oficjalna deklaracja hierarchii przedstartowej na dany wyścig.
class RaceHierarchyDeclaration {
  final String raceId;
  final String raceName;
  final String primaryLeaderId;
  final String? secondaryLeaderId;
  final RaceHierarchyStrategy strategy;
  final DateTime declarationDate;
  final List<String> agreedRiderIds;
  final List<String> dissentingRiderIds;

  const RaceHierarchyDeclaration({
    required this.raceId,
    required this.raceName,
    required this.primaryLeaderId,
    this.secondaryLeaderId,
    required this.strategy,
    required this.declarationDate,
    required this.agreedRiderIds,
    required this.dissentingRiderIds,
  });

  Map<String, dynamic> toJson() => {
        'raceId': raceId,
        'raceName': raceName,
        'primaryLeaderId': primaryLeaderId,
        'secondaryLeaderId': secondaryLeaderId,
        'strategy': strategy.toJson(),
        'declarationDate': declarationDate.toIso8601String(),
        'agreedRiderIds': agreedRiderIds,
        'dissentingRiderIds': dissentingRiderIds,
      };

  factory RaceHierarchyDeclaration.fromJson(Map<String, dynamic> json) {
    return RaceHierarchyDeclaration(
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      primaryLeaderId: json['primaryLeaderId'] as String,
      secondaryLeaderId: json['secondaryLeaderId'] as String?,
      strategy: RaceHierarchyStrategy.fromJson(json['strategy'] as String),
      declarationDate: DateTime.parse(json['declarationDate'] as String),
      agreedRiderIds: (json['agreedRiderIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      dissentingRiderIds: (json['dissentingRiderIds'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Typ incydentu konfliktowego w trakcie etapu lub po nim.
enum IntraTeamIncidentType {
  /// Atak w górach na własnego lidera (odjazd pod górę zamiast holowania i osłony)
  mountainAttackOnTeammate,

  /// Jawna odmowa nadawania tempa na czele peletonu po poleceniu z radia
  refusedToPace,

  /// Odmowa zjechania do wozu technicznego po bidony przez kolarza o wybujałym ego
  refusedToFetchBottles,

  /// Sabotaż pociągu sprinterskiego: rozprowadzający nie wystawia lidera lub sam finiszuje
  sprintLeadoutSabotage,

  /// Buntowniczy wywiad w strefie prasowej podważający autorytet lidera lub menedżera
  postStageMediaRant;

  String toJson() => name;

  static IntraTeamIncidentType fromJson(String value) {
    return IntraTeamIncidentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => IntraTeamIncidentType.mountainAttackOnTeammate,
    );
  }

  String get displayName {
    switch (this) {
      case IntraTeamIncidentType.mountainAttackOnTeammate:
        return 'Bratobójczy Atak w Górach na Własnego Lidera';
      case IntraTeamIncidentType.refusedToPace:
        return 'Odmowa Pracy na Czele Peletonu (Bunt w Radiu)';
      case IntraTeamIncidentType.refusedToFetchBottles:
        return 'Odmowa Zjazdu po Bidony do Wozu';
      case IntraTeamIncidentType.sprintLeadoutSabotage:
        return 'Sabotaż Rozprowadzenia Sprinterskiego';
      case IntraTeamIncidentType.postStageMediaRant:
        return 'Skandaliczny Wywiad w Mediach po Etapie';
    }
  }
}

/// Incydent niesubordynacji i konfliktu w trakcie wyścigu.
class TeamConflictIncident {
  final String id;
  final String raceId;
  final int stageNumber;
  final String stageName;
  final String aggressorRiderId;
  final String aggressorRiderName;
  final String victimRiderId;
  final String victimRiderName;
  final IntraTeamIncidentType incidentType;
  final int severity; // 1-100
  final String radioTranscript;
  final String mediaHeadline;
  final double moraleDamage;
  final DateTime incidentDate;

  const TeamConflictIncident({
    required this.id,
    required this.raceId,
    required this.stageNumber,
    required this.stageName,
    required this.aggressorRiderId,
    required this.aggressorRiderName,
    required this.victimRiderId,
    required this.victimRiderName,
    required this.incidentType,
    required this.severity,
    required this.radioTranscript,
    required this.mediaHeadline,
    required this.moraleDamage,
    required this.incidentDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'raceId': raceId,
        'stageNumber': stageNumber,
        'stageName': stageName,
        'aggressorRiderId': aggressorRiderId,
        'aggressorRiderName': aggressorRiderName,
        'victimRiderId': victimRiderId,
        'victimRiderName': victimRiderName,
        'incidentType': incidentType.toJson(),
        'severity': severity,
        'radioTranscript': radioTranscript,
        'mediaHeadline': mediaHeadline,
        'moraleDamage': moraleDamage,
        'incidentDate': incidentDate.toIso8601String(),
      };

  factory TeamConflictIncident.fromJson(Map<String, dynamic> json) {
    return TeamConflictIncident(
      id: json['id'] as String,
      raceId: json['raceId'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      stageName: json['stageName'] as String,
      aggressorRiderId: json['aggressorRiderId'] as String,
      aggressorRiderName: json['aggressorRiderName'] as String,
      victimRiderId: json['victimRiderId'] as String,
      victimRiderName: json['victimRiderName'] as String,
      incidentType: IntraTeamIncidentType.fromJson(json['incidentType'] as String),
      severity: (json['severity'] as num).toInt(),
      radioTranscript: json['radioTranscript'] as String,
      mediaHeadline: json['mediaHeadline'] as String,
      moraleDamage: (json['moraleDamage'] as num).toDouble(),
      incidentDate: DateTime.parse(json['incidentDate'] as String),
    );
  }
}

/// Status aktywnego konfliktu w drużynie (Feud).
enum FeudStatus {
  brewing,
  openWarfare,
  coldWar,
  resolved;

  String toJson() => name;

  static FeudStatus fromJson(String value) {
    return FeudStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FeudStatus.brewing,
    );
  }

  String get displayName {
    switch (this) {
      case FeudStatus.brewing:
        return 'Iskrzenie pod skórą (Napięcie rośnie)';
      case FeudStatus.openWarfare:
        return 'Otwarta Wojna Domowa (Bunt na trasie)';
      case FeudStatus.coldWar:
        return 'Zimna Wojna (Ciche dni & brak współpracy)';
      case FeudStatus.resolved:
        return 'Zażegnany (Pokój w drużynie)';
    }
  }
}

/// Aktywny konflikt personalny pomiędzy dwoma kolarzami w zespole.
class ActiveTeamFeud {
  final String feudId;
  final String riderAId;
  final String riderAName;
  final String riderBId;
  final String riderBName;
  final int hostilityScore; // 0 - 100
  final int publicMediaDramaLevel; // 0 - 100
  final int teamDivisionSeverity; // 0 - 100 (podział ekipy na 2 kliki)
  final FeudStatus status;

  const ActiveTeamFeud({
    required this.feudId,
    required this.riderAId,
    required this.riderAName,
    required this.riderBId,
    required this.riderBName,
    required this.hostilityScore,
    required this.publicMediaDramaLevel,
    required this.teamDivisionSeverity,
    required this.status,
  });

  ActiveTeamFeud copyWith({
    String? feudId,
    String? riderAId,
    String? riderAName,
    String? riderBId,
    String? riderBName,
    int? hostilityScore,
    int? publicMediaDramaLevel,
    int? teamDivisionSeverity,
    FeudStatus? status,
  }) {
    return ActiveTeamFeud(
      feudId: feudId ?? this.feudId,
      riderAId: riderAId ?? this.riderAId,
      riderAName: riderAName ?? this.riderAName,
      riderBId: riderBId ?? this.riderBId,
      riderBName: riderBName ?? this.riderBName,
      hostilityScore: hostilityScore ?? this.hostilityScore,
      publicMediaDramaLevel: publicMediaDramaLevel ?? this.publicMediaDramaLevel,
      teamDivisionSeverity: teamDivisionSeverity ?? this.teamDivisionSeverity,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'feudId': feudId,
        'riderAId': riderAId,
        'riderAName': riderAName,
        'riderBId': riderBId,
        'riderBName': riderBName,
        'hostilityScore': hostilityScore,
        'publicMediaDramaLevel': publicMediaDramaLevel,
        'teamDivisionSeverity': teamDivisionSeverity,
        'status': status.toJson(),
      };

  factory ActiveTeamFeud.fromJson(Map<String, dynamic> json) {
    return ActiveTeamFeud(
      feudId: json['feudId'] as String,
      riderAId: json['riderAId'] as String,
      riderAName: json['riderAName'] as String,
      riderBId: json['riderBId'] as String,
      riderBName: json['riderBName'] as String,
      hostilityScore: (json['hostilityScore'] as num).toInt(),
      publicMediaDramaLevel: (json['publicMediaDramaLevel'] as num).toInt(),
      teamDivisionSeverity: (json['teamDivisionSeverity'] as num).toInt(),
      status: FeudStatus.fromJson(json['status'] as String),
    );
  }
}

/// Temat rozmowy indywidualnej (1-on-1 Private Talk) w hotelu po etapie.
enum PrivateTalkTopic {
  /// Bezwzględne podporządkowanie hierarchii lidera
  clarifyStrictHierarchy,

  /// Obietnica wolnej ręki na etapach w kolejnym tygodniu
  promiseFutureStageFreedom,

  /// Premia finansowa i podział nagród z wyścigu za lojalność
  financialBonusIncentive,

  /// Ostra reprymenda dyscyplinarna pod groźbą odesłania do rezerw
  sternDisciplinaryReprimand,

  /// Odwołanie do wspólnego dobra drużyny i historii kolarstwa
  appealToTeamLegacy;

  String toJson() => name;

  static PrivateTalkTopic fromJson(String value) {
    return PrivateTalkTopic.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PrivateTalkTopic.clarifyStrictHierarchy,
    );
  }

  String get displayName {
    switch (this) {
      case PrivateTalkTopic.clarifyStrictHierarchy:
        return 'Twarde Ustalenie Hierarchii („Od jutra pracujesz dla lidera”)';
      case PrivateTalkTopic.promiseFutureStageFreedom:
        return 'Obietnica Wolnej Ręki („Pomóż jutro, w trzecim tygodniu jedziesz po etap”)';
      case PrivateTalkTopic.financialBonusIncentive:
        return 'Finansowa Premia za Lojalność (Bonus z puli nagród)';
      case PrivateTalkTopic.sternDisciplinaryReprimand:
        return 'Ostra Reprymenda („Kolejny wybryk i lądujesz na ławce”)';
      case PrivateTalkTopic.appealToTeamLegacy:
        return 'Odwołanie do Dobra Drużyny („Razem tworzymy historię”)';
    }
  }
}

/// Wynik rozmowy w 4 oczy z kolarzem.
enum PrivateTalkOutcomeType {
  /// Sukces: zawodnik akceptuje decyzję, spadek wrogości, powrót morale
  peaceRestored,

  /// Częściowy sukces: kolarz podporządkuje się z niechęcią (chwilowy rozejm)
  grudgingCompliance,

  /// Porażka: kolarz unosi się honorem, wrogość rośnie, grozi zerwaniem kontraktu
  rebellionEscalated;

  String toJson() => name;

  static PrivateTalkOutcomeType fromJson(String value) {
    return PrivateTalkOutcomeType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PrivateTalkOutcomeType.grudgingCompliance,
    );
  }
}

/// Raport z przeprowadzonej rozmowy indywidualnej menedżera z zawodnikiem.
class PrivateTalkResult {
  final PrivateTalkTopic topic;
  final PrivateTalkOutcomeType outcome;
  final double riderMoraleChange;
  final int hostilityChange;
  final int managerReputationChange;
  final String dialogueSummary;
  final String riderQuote;

  const PrivateTalkResult({
    required this.topic,
    required this.outcome,
    required this.riderMoraleChange,
    required this.hostilityChange,
    required this.managerReputationChange,
    required this.dialogueSummary,
    required this.riderQuote,
  });
}

/// Raport weryfikacji składu na Grand Tour pod kątem starcia dwóch samców alfa (Dual Leader Clash).
class GrandTourSquadEgoRiskReport {
  final bool hasDualLeaderClash;
  final List<Rider> conflictingLeaders;
  final List<RiderContractPromise> brokenPromises;
  final int estimatedClashRiskPercent;
  final String diagnosisSummary;
  final List<String> tacticalWarnings;

  const GrandTourSquadEgoRiskReport({
    required this.hasDualLeaderClash,
    required this.conflictingLeaders,
    required this.brokenPromises,
    required this.estimatedClashRiskPercent,
    required this.diagnosisSummary,
    required this.tacticalWarnings,
  });
}

/// Główny serwis psychologii kolarzy, ambicji, zarządzania ego i konfliktów wewnątrz zespołu
/// (Rider Ego & Conflicts Service).
class RiderEgoAndConflictsService {
  RiderEgoAndConflictsService._();

  // ---------------------------------------------------------------------------
  // 1. GENEROWANIE I ZARZĄDZANIE PROFILAMI PSYCHOLOGICZNYMI
  // ---------------------------------------------------------------------------

  /// Generuje realistyczny profil psychologiczny kolarza na podstawie roli, wieku i specjalizacji.
  static RiderPersonalityProfile generatePersonalityProfile(Rider rider) {
    final role = rider.contract.role;
    final spec = rider.specialization;
    final age = rider.age;

    final PersonalityArchetype archetype;
    int ambition = 60;
    int ego = 50;
    int loyalty = 70;
    int drama = 40;
    int patience = 60;

    if (role == RiderRole.teamLeader) {
      if (age <= 24) {
        archetype = PersonalityArchetype.youngAmbitiousChallenger;
        ambition = 95;
        ego = 82;
        loyalty = 55;
        drama = 65;
        patience = 40;
      } else {
        archetype = PersonalityArchetype.alphaLeader;
        ambition = 94;
        ego = 90;
        loyalty = 60;
        drama = 70;
        patience = 50;
      }
    } else if (role == RiderRole.coLeader) {
      archetype = PersonalityArchetype.youngAmbitiousChallenger;
      ambition = 88;
      ego = 78;
      loyalty = 65;
      drama = 60;
      patience = 55;
    } else if (role == RiderRole.sprinter || spec == RiderSpecialization.pureSprinter) {
      archetype = PersonalityArchetype.primaDonnaSprinter;
      ambition = 90;
      ego = 88;
      loyalty = 58;
      drama = 75;
      patience = 45;
    } else if (role == RiderRole.superDomestique) {
      archetype = PersonalityArchetype.loyalLieutenant;
      ambition = 72;
      ego = 45;
      loyalty = 92;
      drama = 25;
      patience = 85;
    } else {
      if (age >= 32) {
        archetype = PersonalityArchetype.pragmaticVeteran;
        ambition = 55;
        ego = 35;
        loyalty = 90;
        drama = 20;
        patience = 90;
      } else {
        archetype = PersonalityArchetype.loyalLieutenant;
        ambition = 65;
        ego = 45;
        loyalty = 85;
        drama = 30;
        patience = 75;
      }
    }

    return RiderPersonalityProfile(
      riderId: rider.id,
      archetype: archetype,
      ambition: ambition,
      egoLevel: ego,
      teamLoyalty: loyalty,
      mediaDramaProneness: drama,
      tacticalPatience: patience,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. WERYFIKACJA SKŁADU NA GRAND TOUR & ZŁAMANE OBIETNICE
  // ---------------------------------------------------------------------------

  /// Weryfikuje skład zgłoszony na Grand Tour pod kątem zderzenia dwóch liderów
  /// i złamanych obietnic kontraktowych (np. obietnica bycia jedynym liderem na Tour de France).
  static GrandTourSquadEgoRiskReport validateGrandTourSquadEgoClash({
    required TourRace race,
    required List<Rider> squadRiders,
    required List<RiderContractPromise> activePromises,
  }) {
    final leaders = squadRiders.where(
      (r) => r.contract.role == RiderRole.teamLeader || r.contract.role == RiderRole.coLeader,
    ).toList();

    final hasDualLeaderClash = leaders.length >= 2;
    final brokenPromises = <RiderContractPromise>[];
    final warnings = <String>[];

    // Sprawdzamy obietnice: czy komuś obiecano status JEDYNEGO lidera na ten wyścig
    for (final leader in leaders) {
      final soleLeaderPromise = activePromises.where((p) =>
          p.riderId == leader.id &&
          p.type == ContractPromiseType.soleLeaderGrandTour &&
          p.status == ContractPromiseStatus.pending &&
          (p.targetRaceId == null || p.targetRaceId == race.id)).toList();

      if (soleLeaderPromise.isNotEmpty && leaders.length >= 2) {
        // ZŁAMANIE OBIETNICY!
        brokenPromises.addAll(soleLeaderPromise);
        warnings.add(
          'ZŁAMANA OBIETNICA KONTRAKTOWA dla ${leader.fullName}! Obiecano mu status jedynego lidera na ${race.name}, '
          'podczas gdy do składu powołano drugiego kolarza o statusie lidera.',
        );
      }
    }

    int riskPercent = 0;
    String diagnosis = 'Skład zbalansowany hierarchicznie.';

    if (hasDualLeaderClash) {
      riskPercent = 40 + (brokenPromises.isNotEmpty ? 45 : 20);
      diagnosis = 'ALARM EGO: W składzie na ${race.name} znajduje się ${leaders.length} kolarzy o statusie lidera '
          '(${leaders.map((l) => l.fullName).join(" oraz ")}). '
          'Ryzyko otwartej wojny domowej i buntu w górach wynosi $riskPercent%.';
      warnings.add(
        'Konieczne jest zadeklarowanie jasnej hierarchii przed startem 1. etapu lub przeprowadzenie rozmów indywidualnych.',
      );
    }

    return GrandTourSquadEgoRiskReport(
      hasDualLeaderClash: hasDualLeaderClash,
      conflictingLeaders: leaders,
      brokenPromises: brokenPromises,
      estimatedClashRiskPercent: math.min(99, riskPercent),
      diagnosisSummary: diagnosis,
      tacticalWarnings: warnings,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. ODPRAWA PRZEDSTARTOWA & DEKLARACJA HIERARCHII
  // ---------------------------------------------------------------------------

  /// Ogłasza oficjalną hierarchię przed wyścigiem.
  /// Kolarz zdegradowany do roli pomocnika może zaprotestować, chyba że menedżer i DS mają potężny autorytet.
  static RaceHierarchyDeclaration declareRaceHierarchy({
    required TourRace race,
    required String primaryLeaderId,
    String? secondaryLeaderId,
    required RaceHierarchyStrategy strategy,
    required List<Rider> squadRiders,
    required Map<String, RiderPersonalityProfile> profiles,
    SportsDirector? sportsDirector,
    int managerReputation = 50,
  }) {
    final agreed = <String>[];
    final dissenting = <String>[];

    // Siła autorytetu sztabu: charyzma DS + reputacja menedżera
    final dsCharisma = sportsDirector?.preRaceBriefingCharisma ?? 60;
    final authorityScore = (dsCharisma * 0.6) + (managerReputation * 0.4);

    for (final rider in squadRiders) {
      if (rider.id == primaryLeaderId) {
        agreed.add(rider.id);
        continue;
      }

      final profile = profiles[rider.id] ?? generatePersonalityProfile(rider);

      // Kolarz, który uważa się za lidera, ale został wyznaczony jako pomocnik
      final isDisplacedLeader = rider.contract.role == RiderRole.teamLeader ||
          rider.contract.role == RiderRole.coLeader;

      if (isDisplacedLeader && strategy == RaceHierarchyStrategy.absoluteSoleLeader) {
        // Test sprzeciwu: wysokie ego i ambicja kontra autorytet sztabu
        final resistanceScore = (profile.egoLevel * 0.6) + (profile.ambition * 0.4);
        if (resistanceScore > authorityScore + 15) {
          dissenting.add(rider.id);
        } else {
          agreed.add(rider.id);
        }
      } else {
        agreed.add(rider.id);
      }
    }

    return RaceHierarchyDeclaration(
      raceId: race.id,
      raceName: race.name,
      primaryLeaderId: primaryLeaderId,
      secondaryLeaderId: secondaryLeaderId,
      strategy: strategy,
      declarationDate: DateTime.now(),
      agreedRiderIds: agreed,
      dissentingRiderIds: dissenting,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. SYMULACJA INCYDENTU W TRAKCIE ETAPU (BUNT W GÓRACH / ODMOWA POMOCY)
  // ---------------------------------------------------------------------------

  /// Sprawdza, czy na kluczowym etapie (np. alpejskim) dochodzi do buntu,
  /// ataku na kolegę z zespołu lub odmowy holowania lidera.
  static TeamConflictIncident? evaluateStageInRaceConflictRisk({
    required TourRace race,
    required int stageNumber,
    required String stageName,
    required List<Rider> squadRiders,
    required RaceHierarchyDeclaration? hierarchy,
    required Map<String, RiderPersonalityProfile> profiles,
    required bool isHighMountainStage,
    double primaryLeaderTimeLossSeconds = 0.0,
    math.Random? rng,
  }) {
    if (!isHighMountainStage) return null;

    final random = rng ?? math.Random();
    final leaders = squadRiders.where(
      (r) => r.contract.role == RiderRole.teamLeader || r.contract.role == RiderRole.coLeader,
    ).toList();

    if (leaders.length < 2) return null;

    final leaderA = leaders[0];
    final leaderB = leaders[1];

    final profileB = profiles[leaderB.id] ?? generatePersonalityProfile(leaderB);

    // Czynniki zapalne:
    // 1. Brak jasnej hierarchii lub kolarz B w sprzeciwie
    final isUnsettled = hierarchy == null ||
        hierarchy.strategy == RaceHierarchyStrategy.undefinedAmbiguity ||
        hierarchy.dissentingRiderIds.contains(leaderB.id);

    // 2. Lider A wykazuje słabość w górach (traci sekundy na podjeździe)
    final leaderAIsStruggling = primaryLeaderTimeLossSeconds > 25.0;

    double incidentProbability = 0.08; // bazowe 8%
    if (isUnsettled) incidentProbability += 0.35;
    if (leaderAIsStruggling) incidentProbability += 0.30;
    if (profileB.egoLevel > 80) incidentProbability += 0.20;
    if (profileB.teamLoyalty < 60) incidentProbability += 0.15;

    incidentProbability = incidentProbability.clamp(0.05, 0.90);

    final triggered = random.nextDouble() < incidentProbability;
    if (!triggered) return null;

    // Wybór typu incydentu
    final IntraTeamIncidentType incidentType;
    final String radioTranscript;
    final String mediaHeadline;

    if (leaderAIsStruggling && profileB.ambition > 80) {
      incidentType = IntraTeamIncidentType.mountainAttackOnTeammate;
      radioTranscript = 'DS (Wóz #1): „${leaderB.lastName}, natychmiast zwolnij! Zostań z ${leaderA.lastName}, gubi koło!”\n'
          '${leaderB.lastName} (Radio): „Nie ma mowy! Jadę po etap i podium, on nie ma dzisiaj nóg!” [Kolarz przyspiesza i urywa własnego kapitana]';
      mediaHeadline = 'WOJNA DOMOWA NA SZCZYCIE: ${leaderB.lastName} atakuje i nokautuje własnego lidera ${leaderA.lastName}!';
    } else {
      incidentType = IntraTeamIncidentType.refusedToPace;
      radioTranscript = 'DS (Wóz #1): „${leaderB.lastName}, wyjdź na czoło grupy i kasuj atak rywali!”\n'
          '${leaderB.lastName} (Radio): „Nie moja kolej. Niech sam goni, ja nie jestem niczyim bidonowym.”';
      mediaHeadline = 'BUNT W RADIU: ${leaderB.lastName} jawnie odmawia pracy na rzecz ${leaderA.lastName}!';
    }

    return TeamConflictIncident(
      id: 'incident_${race.id}_st${stageNumber}_${DateTime.now().millisecondsSinceEpoch}',
      raceId: race.id,
      stageNumber: stageNumber,
      stageName: stageName,
      aggressorRiderId: leaderB.id,
      aggressorRiderName: leaderB.fullName,
      victimRiderId: leaderA.id,
      victimRiderName: leaderA.fullName,
      incidentType: incidentType,
      severity: 85,
      radioTranscript: radioTranscript,
      mediaHeadline: mediaHeadline,
      moraleDamage: 18.0,
      incidentDate: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. ROZMOWY INDYWIDUALNE W HOTELU (1-ON-1 PRIVATE TALKS)
  // ---------------------------------------------------------------------------

  /// Przeprowadza rozmowę indywidualną w 4 oczy z buntującym się kolarzem.
  static PrivateTalkResult conductPrivateTalk({
    required Rider rider,
    required PrivateTalkTopic topic,
    required ActiveTeamFeud? feud,
    required RiderPersonalityProfile profile,
    SportsDirector? sportsDirector,
    int managerReputation = 50,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random();
    final dsCharisma = sportsDirector?.preRaceBriefingCharisma ?? 60;
    final totalAuthority = (managerReputation * 0.5) + (dsCharisma * 0.5);

    double successChance = 0.50;
    String dialogue = '';
    String quote = '';

    switch (topic) {
      case PrivateTalkTopic.clarifyStrictHierarchy:
        // Twarda hierarchia: zależy od autorytetu menedżera kontra ego kolarza
        successChance = (totalAuthority - profile.egoLevel + 50) / 100.0;
        dialogue = 'Menedżer stanowczo przypomniał kolarzowi o zapisach w kontrakcie i celach sponsorskich klubu. '
            'Wskazał, że interes drużyny stoi ponad indywidualnymi ambicjami.';
        break;

      case PrivateTalkTopic.promiseFutureStageFreedom:
        // Obietnica wolnej ręki: działa wybitnie na ambitnych kolarzy
        successChance = 0.82;
        dialogue = 'Menedżer zawarł dżentelmeńską umowę: pełne poświęcenie na jutrzejszym etapie alpejskim '
            'w zamian za zielone światło do ucieczki na 18. etapie.';
        break;

      case PrivateTalkTopic.financialBonusIncentive:
        // Premia finansowa: duża skuteczność przy pragmatykach
        successChance = 0.78;
        dialogue = 'Menedżer zaoferował gwarancję równego podziału nagród z klasyfikacji generalnej '
            'oraz dodatkowy bonus finansowy z budżetu klubu.';
        break;

      case PrivateTalkTopic.sternDisciplinaryReprimand:
        // Ostra reprymenda: ryzykowna wobec samców alfa, skuteczna wobec młodych
        if (profile.archetype == PersonalityArchetype.alphaLeader) {
          successChance = 0.25; // Samiec alfa nie daje się zastraszyć
        } else {
          successChance = (totalAuthority * 1.1) / 100.0;
        }
        dialogue = 'Menedżer zagroził natychmiastowym odsunięciem od startów i wstrzymaniem premii kontraktowych '
            'w razie kolejnego aktu niesubordynacji.';
        break;

      case PrivateTalkTopic.appealToTeamLegacy:
        // Odwołanie do dobra drużyny: zależy od lojalności kolarza
        successChance = (profile.teamLoyalty + 30) / 100.0;
        dialogue = 'Menedżer odwołał się do dumy klubowej, pracy mechaników i sztabu, '
            'przypominając, że wielkie triumfy buduje się jednością.';
        break;
    }

    successChance = successChance.clamp(0.10, 0.95);
    final roll = random.nextDouble();

    final PrivateTalkOutcomeType outcome;
    final double moraleChange;
    final int hostilityChange;

    if (roll < successChance * 0.70) {
      // Pełny sukces
      outcome = PrivateTalkOutcomeType.peaceRestored;
      moraleChange = 12.0;
      hostilityChange = -25;
      quote = '„Rozumiem, szefie. Emocje wzięły górę na podjeździe. Od jutra pełny gaz dla drużyny.”';
    } else if (roll < successChance) {
      // Chwilowy rozejm
      outcome = PrivateTalkOutcomeType.grudgingCompliance;
      moraleChange = 0.0;
      hostilityChange = -10;
      quote = '„Dobra, pojadę jak każecie, ale jeśli on znowu osłabnie, nie zamierzam marnować moich nóg.”';
    } else {
      // Eskalacja buntu!
      outcome = PrivateTalkOutcomeType.rebellionEscalated;
      moraleChange = -15.0;
      hostilityChange = 20;
      quote = '„Nie będziecie mną pomiatać! Jeśli nie mam tu szans na wygrywanie, mój agent już szuka nowego zespołu!”';
    }

    return PrivateTalkResult(
      topic: topic,
      outcome: outcome,
      riderMoraleChange: moraleChange,
      hostilityChange: hostilityChange,
      managerReputationChange: outcome == PrivateTalkOutcomeType.peaceRestored ? 2 : (outcome == PrivateTalkOutcomeType.rebellionEscalated ? -2 : 0),
      dialogueSummary: dialogue,
      riderQuote: quote,
    );
  }

  // ---------------------------------------------------------------------------
  // 6. ROZSTRZYGANIE OBIETNIC KONTRAKTOWYCH
  // ---------------------------------------------------------------------------

  /// Aktualizuje stan kolarza po złamaniu obietnicy kontraktowej (załamanie lojalności i morale).
  static Rider applyBrokenPromisePenalty(Rider rider, RiderContractPromise promise) {
    final curContract = rider.contract;
    final newMorale = (curContract.morale - 35.0).clamp(10.0, 100.0);
    final newLoyalty = (curContract.leaderLoyalty - 45.0).clamp(5.0, 100.0);

    return rider.copyWith(
      contract: curContract.copyWith(
        morale: newMorale,
        leaderLoyalty: newLoyalty,
      ),
    );
  }

  /// Aktualizuje stan kolarza po dotrzymaniu obietnicy kontraktowej (wzrost zaufania i lojalności).
  static Rider applyFulfilledPromiseReward(Rider rider, RiderContractPromise promise) {
    final curContract = rider.contract;
    final newMorale = (curContract.morale + 15.0).clamp(10.0, 100.0);
    final newLoyalty = (curContract.leaderLoyalty + 20.0).clamp(5.0, 100.0);

    return rider.copyWith(
      contract: curContract.copyWith(
        morale: newMorale,
        leaderLoyalty: newLoyalty,
      ),
    );
  }
}

