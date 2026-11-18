import 'dart:math' as math;

/// Archetyp osobowości kolarza w systemie Psychologii Szatni 2.0.
enum LockerRoomPersonalityArchetype {
  /// Cichy, lojalny pomocnik stawiający dobro lidera ponad własne ambicje.
  humbleDomestique,

  /// Dominujący lider GC lub sprinter oczekujący pełnego wsparcia zespołu.
  alphaLeader,

  /// Opanowany profesjonalista odporny na dramaty w szatni.
  silentProfessional,

  /// Dusza towarzystwa rozładowująca napięcie przed wielkimi etapami.
  lockerRoomJoker,

  /// Bezkompromisowy rywal napędzany wewnętrzną konkurencją.
  fierceCompetitor,

  /// Doświadczony kapitan szosy mentorujący młodszych zawodników.
  mentorVeteran,

  /// Ambitny talent U23 walczący o szybką pozycję w hierarchii.
  ambitiousWonderkid;

  String toJson() => name;

  static LockerRoomPersonalityArchetype fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return LockerRoomPersonalityArchetype.silentProfessional;
    }
    return LockerRoomPersonalityArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LockerRoomPersonalityArchetype.silentProfessional,
    );
  }

  String get displayNamePl {
    switch (this) {
      case LockerRoomPersonalityArchetype.humbleDomestique:
        return 'Lojalny Pomocnik';
      case LockerRoomPersonalityArchetype.alphaLeader:
        return 'Lider Alfa';
      case LockerRoomPersonalityArchetype.silentProfessional:
        return 'Cichy Profesjonalista';
      case LockerRoomPersonalityArchetype.lockerRoomJoker:
        return 'Dusza Szatni';
      case LockerRoomPersonalityArchetype.fierceCompetitor:
        return 'Zaciekły Rywal';
      case LockerRoomPersonalityArchetype.mentorVeteran:
        return 'Mentor Weteran';
      case LockerRoomPersonalityArchetype.ambitiousWonderkid:
        return 'Ambitny Talent';
    }
  }

  String get displayNameEn {
    switch (this) {
      case LockerRoomPersonalityArchetype.humbleDomestique:
        return 'Humble Domestique';
      case LockerRoomPersonalityArchetype.alphaLeader:
        return 'Alpha Leader';
      case LockerRoomPersonalityArchetype.silentProfessional:
        return 'Silent Professional';
      case LockerRoomPersonalityArchetype.lockerRoomJoker:
        return 'Locker Room Joker';
      case LockerRoomPersonalityArchetype.fierceCompetitor:
        return 'Fierce Competitor';
      case LockerRoomPersonalityArchetype.mentorVeteran:
        return 'Mentor Veteran';
      case LockerRoomPersonalityArchetype.ambitiousWonderkid:
        return 'Ambitious Wonderkid';
    }
  }

  /// Bazowa kompatybilność archetypów podczas pierwszego spotkania w drużynie.
  int baselineCompatibilityWith(LockerRoomPersonalityArchetype other) {
    if (this == LockerRoomPersonalityArchetype.alphaLeader &&
        other == LockerRoomPersonalityArchetype.alphaLeader) {
      return -15;
    }
    if ((this == LockerRoomPersonalityArchetype.alphaLeader &&
            other == LockerRoomPersonalityArchetype.ambitiousWonderkid) ||
        (this == LockerRoomPersonalityArchetype.ambitiousWonderkid &&
            other == LockerRoomPersonalityArchetype.alphaLeader)) {
      return -8;
    }
    if (this == LockerRoomPersonalityArchetype.fierceCompetitor &&
        other == LockerRoomPersonalityArchetype.fierceCompetitor) {
      return -10;
    }
    if ((this == LockerRoomPersonalityArchetype.mentorVeteran &&
            other == LockerRoomPersonalityArchetype.ambitiousWonderkid) ||
        (this == LockerRoomPersonalityArchetype.ambitiousWonderkid &&
            other == LockerRoomPersonalityArchetype.mentorVeteran)) {
      return 18;
    }
    if (this == LockerRoomPersonalityArchetype.lockerRoomJoker ||
        other == LockerRoomPersonalityArchetype.lockerRoomJoker) {
      return 12;
    }
    if ((this == LockerRoomPersonalityArchetype.alphaLeader &&
            other == LockerRoomPersonalityArchetype.humbleDomestique) ||
        (this == LockerRoomPersonalityArchetype.humbleDomestique &&
            other == LockerRoomPersonalityArchetype.alphaLeader)) {
      return 15;
    }
    if (this == LockerRoomPersonalityArchetype.humbleDomestique &&
        other == LockerRoomPersonalityArchetype.humbleDomestique) {
      return 14;
    }
    return 4;
  }
}

/// Poziom relacji między dwoma kolarzami w macierzy `-100` do `+100`.
enum RelationshipTier {
  /// Otwarty konflikt i sabotaż w szatni (`-100` do `-60`).
  toxicFeud,

  /// Wroga rywalizacja i napięcie taktyczne (`-59` do `-25`).
  hostileRivalry,

  /// Chłodny dystans profesjonalny (`-24` do `-1`).
  coldProfessional,

  /// Relacja neutralna (`0` do `24`).
  neutral,

  /// Zaufany sojusznik na szosie (`25` do `59`).
  trustedAlly,

  /// Bliski powiernik i partner taktyczny (`60` do `84`).
  closeConfidant,

  /// Pakt lojalności Blood Brothers (`85` do `100` z aktywnym paktem).
  bloodBrothers;

  String toJson() => name;

  static RelationshipTier fromJson(String? value) {
    if (value == null || value.isEmpty) return RelationshipTier.neutral;
    return RelationshipTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RelationshipTier.neutral,
    );
  }

  /// Wyznacza poziom relacji na podstawie wyniku `-100..+100` i statusu paktu.
  static RelationshipTier fromScore(
    int score, {
    bool hasActiveBloodBrothersPact = false,
  }) {
    final clamped = score.clamp(-100, 100);
    if (hasActiveBloodBrothersPact && clamped >= 70) {
      return RelationshipTier.bloodBrothers;
    }
    if (clamped <= -60) return RelationshipTier.toxicFeud;
    if (clamped <= -25) return RelationshipTier.hostileRivalry;
    if (clamped < 0) return RelationshipTier.coldProfessional;
    if (clamped < 25) return RelationshipTier.neutral;
    if (clamped < 60) return RelationshipTier.trustedAlly;
    if (clamped < 85) return RelationshipTier.closeConfidant;
    return hasActiveBloodBrothersPact
        ? RelationshipTier.bloodBrothers
        : RelationshipTier.closeConfidant;
  }

  String get displayNamePl {
    switch (this) {
      case RelationshipTier.toxicFeud:
        return 'Toksyczny Konflikt';
      case RelationshipTier.hostileRivalry:
        return 'Wroga Rywalizacja';
      case RelationshipTier.coldProfessional:
        return 'Chłodny Dystans';
      case RelationshipTier.neutral:
        return 'Neutralna';
      case RelationshipTier.trustedAlly:
        return 'Zaufany Sojusznik';
      case RelationshipTier.closeConfidant:
        return 'Bliski Powiernik';
      case RelationshipTier.bloodBrothers:
        return 'Blood Brothers';
    }
  }

  String get displayNameEn {
    switch (this) {
      case RelationshipTier.toxicFeud:
        return 'Toxic Feud';
      case RelationshipTier.hostileRivalry:
        return 'Hostile Rivalry';
      case RelationshipTier.coldProfessional:
        return 'Cold Professional';
      case RelationshipTier.neutral:
        return 'Neutral';
      case RelationshipTier.trustedAlly:
        return 'Trusted Ally';
      case RelationshipTier.closeConfidant:
        return 'Close Confidant';
      case RelationshipTier.bloodBrothers:
        return 'Blood Brothers';
    }
  }
}

/// Kolor połączenia w grafie sieci relacji (#618).
enum RelationshipConnectionVisualTone {
  /// Złote połączenie (#D4AF37) — pakt Blood Brothers.
  gold,

  /// Zielone połączenie (#10B981) — pozytywna więź i zaufanie.
  green,

  /// Neutralne połączenie (#6B7280) — brak silnych emocji.
  neutral,

  /// Czerwone połączenie (#EF4444) — konflikt lub wroga rywalizacja.
  red;

  String toJson() => name;

  static RelationshipConnectionVisualTone fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return RelationshipConnectionVisualTone.neutral;
    }
    return RelationshipConnectionVisualTone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RelationshipConnectionVisualTone.neutral,
    );
  }
}

/// Rodzaj zdarzenia wpływającego na relację między dwoma kolarzami.
enum RelationshipEventType {
  /// Oddanie własnego koła lub roweru po defekcie lidera.
  wheelOrBikeSacrifice,

  /// Rozprowadzenie pociągu sprinterskiego zakończone zwycięstwem.
  winningLeadOut,

  /// Wspólna ucieczka lub obrona koszulki lidera w górach.
  heroicMountainDefense,

  /// Udane zgrupowanie wysokościowe lub obóz integracyjny.
  trainingCampBonding,

  /// Zawarcie paktu lojalności Blood Brothers.
  bloodBrothersForged,

  /// Spór o przywództwo (np. kto jest liderem #1 na Grand Tour).
  leadershipClash,

  /// Odmowa pracy na rzecz kolegi lub pogoń za własnym kolegą z ucieczki.
  tacticalBetrayal,

  /// Publiczna krytyka w mediach po etapie.
  mediaCriticism,

  /// Pomyślna mediacja prowadzona przez dyrektora sportowego lub kapitana.
  conflictMediationSuccess,

  /// Zerwanie paktu Blood Brothers.
  bloodBrothersBroken;

  String toJson() => name;

  static RelationshipEventType fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return RelationshipEventType.trainingCampBonding;
    }
    return RelationshipEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RelationshipEventType.trainingCampBonding,
    );
  }
}

/// Status paktu lojalności Blood Brothers.
enum BloodBrothersPactStatus {
  /// Pakt w pełni aktywny, maksymalne premie lojalnościowe.
  active,

  /// Pakt nadwyrężony niedawnym sporem (obniżone premie, wymaga mediacji).
  strained,

  /// Pakt zerwany przez zdradę lub odejście w konflikcie.
  broken;

  String toJson() => name;

  static BloodBrothersPactStatus fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return BloodBrothersPactStatus.active;
    }
    return BloodBrothersPactStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BloodBrothersPactStatus.active,
    );
  }
}

/// Ogólna atmosfera panująca w szatni drużyny.
enum LockerRoomAtmosphere {
  /// Zjednoczony front (wszyscy gotowi do poświęceń).
  unitedFront,

  /// Harmonijna i stabilna atmosfera.
  harmonious,

  /// Chłodny, profesjonalny układ pracy.
  professional,

  /// Odczuwalne napięcia między frakcjami.
  tense,

  /// Poważny rozłam w szatni.
  fractured,

  /// Otwarta wojna domowa w zespole.
  civilWar;

  String toJson() => name;

  static LockerRoomAtmosphere fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return LockerRoomAtmosphere.professional;
    }
    return LockerRoomAtmosphere.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LockerRoomAtmosphere.professional,
    );
  }

  String get displayNamePl {
    switch (this) {
      case LockerRoomAtmosphere.unitedFront:
        return 'Zjednoczony Front';
      case LockerRoomAtmosphere.harmonious:
        return 'Harmonijna';
      case LockerRoomAtmosphere.professional:
        return 'Profesjonalna';
      case LockerRoomAtmosphere.tense:
        return 'Napięta';
      case LockerRoomAtmosphere.fractured:
        return 'Rozłam w Szatni';
      case LockerRoomAtmosphere.civilWar:
        return 'Wojna Domowa';
    }
  }

  String get displayNameEn {
    switch (this) {
      case LockerRoomAtmosphere.unitedFront:
        return 'United Front';
      case LockerRoomAtmosphere.harmonious:
        return 'Harmonious';
      case LockerRoomAtmosphere.professional:
        return 'Professional';
      case LockerRoomAtmosphere.tense:
        return 'Tense';
      case LockerRoomAtmosphere.fractured:
        return 'Fractured';
      case LockerRoomAtmosphere.civilWar:
        return 'Civil War';
    }
  }
}

/// Pojedyncze zdarzenie historyczne w relacji między dwoma kolarzami.
class RelationshipEventRecord {
  final String eventId;
  final String riderAId;
  final String riderBId;
  final RelationshipEventType eventType;
  final int scoreDelta;
  final int resultingScore;
  final String summary;
  final String dateIso;
  final String? raceName;

  const RelationshipEventRecord({
    required this.eventId,
    required this.riderAId,
    required this.riderBId,
    required this.eventType,
    required this.scoreDelta,
    required this.resultingScore,
    required this.summary,
    required this.dateIso,
    this.raceName,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventId': eventId,
      'riderAId': riderAId,
      'riderBId': riderBId,
      'eventType': eventType.toJson(),
      'scoreDelta': scoreDelta,
      'resultingScore': resultingScore,
      'summary': summary,
      'dateIso': dateIso,
      if (raceName != null) 'raceName': raceName,
    };
  }

  factory RelationshipEventRecord.fromJson(Map<String, dynamic> json) {
    return RelationshipEventRecord(
      eventId: (json['eventId'] as String?) ?? '',
      riderAId: (json['riderAId'] as String?) ?? '',
      riderBId: (json['riderBId'] as String?) ?? '',
      eventType: RelationshipEventType.fromJson(json['eventType'] as String?),
      scoreDelta: ((json['scoreDelta'] as num?) ?? 0).toInt(),
      resultingScore:
          ((json['resultingScore'] as num?) ?? 0).toInt().clamp(-100, 100),
      summary: (json['summary'] as String?) ?? '',
      dateIso: (json['dateIso'] as String?) ?? '',
      raceName: json['raceName'] as String?,
    );
  }
}

/// Profil psychologiczny kolarza w szatni drużyny.
class RiderLockerRoomProfile {
  final String riderId;
  final String riderName;
  final LockerRoomPersonalityArchetype archetype;

  /// Wpływ na szatnię i młodych kolarzy (`1..100`).
  final int leadershipWeight;

  /// Poziom ego i oczekiwań względem statusu w drużynie (`1..100`).
  final int egoLevel;

  /// Elastyczność i zdolność łagodzenia sporów (`1..100`).
  final int adaptability;

  /// Aktualne morale kolarza (`0..100`).
  final int currentMorale;

  /// Czy kolarz pełni rolę Kapitana Szosy.
  final bool isTeamCaptain;

  const RiderLockerRoomProfile({
    required this.riderId,
    required this.riderName,
    required this.archetype,
    required this.leadershipWeight,
    required this.egoLevel,
    required this.adaptability,
    required this.currentMorale,
    this.isTeamCaptain = false,
  });

  RiderLockerRoomProfile copyWith({
    String? riderId,
    String? riderName,
    LockerRoomPersonalityArchetype? archetype,
    int? leadershipWeight,
    int? egoLevel,
    int? adaptability,
    int? currentMorale,
    bool? isTeamCaptain,
  }) {
    return RiderLockerRoomProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      archetype: archetype ?? this.archetype,
      leadershipWeight: (leadershipWeight ?? this.leadershipWeight).clamp(1, 100),
      egoLevel: (egoLevel ?? this.egoLevel).clamp(1, 100),
      adaptability: (adaptability ?? this.adaptability).clamp(1, 100),
      currentMorale: (currentMorale ?? this.currentMorale).clamp(0, 100),
      isTeamCaptain: isTeamCaptain ?? this.isTeamCaptain,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'riderId': riderId,
      'riderName': riderName,
      'archetype': archetype.toJson(),
      'leadershipWeight': leadershipWeight,
      'egoLevel': egoLevel,
      'adaptability': adaptability,
      'currentMorale': currentMorale,
      'isTeamCaptain': isTeamCaptain,
    };
  }

  factory RiderLockerRoomProfile.fromJson(Map<String, dynamic> json) {
    return RiderLockerRoomProfile(
      riderId: (json['riderId'] as String?) ?? '',
      riderName: (json['riderName'] as String?) ?? 'Unknown Rider',
      archetype: LockerRoomPersonalityArchetype.fromJson(
        json['archetype'] as String?,
      ),
      leadershipWeight:
          ((json['leadershipWeight'] as num?) ?? 50).toInt().clamp(1, 100),
      egoLevel: ((json['egoLevel'] as num?) ?? 50).toInt().clamp(1, 100),
      adaptability:
          ((json['adaptability'] as num?) ?? 50).toInt().clamp(1, 100),
      currentMorale:
          ((json['currentMorale'] as num?) ?? 70).toInt().clamp(0, 100),
      isTeamCaptain: (json['isTeamCaptain'] as bool?) ?? false,
    );
  }
}

/// Krawędź w macierzy relacji `-100` do `+100` pomiędzy dwoma kolarzami.
class RiderRelationshipEdge {
  final String riderAId;
  final String riderBId;

  /// Główny wskaźnik relacji w skali `-100` (nienawiść) do `+100` (braterstwo).
  final int score;

  /// Zaufanie taktyczne na szosie (`0..100`).
  final int trust;

  /// Wzajemny szacunek sportowy (`0..100`).
  final int respect;

  /// Ukryte lub jawne napięcie w szatni (`0..100`).
  final int tension;

  /// Liczba wspólnie przejechanych wyścigów.
  final int sharedRacesCount;

  /// Liczba dni spędzonych wspólnie na zgrupowaniach.
  final int sharedCampDays;

  /// Powód ostatniej zmiany relacji.
  final String lastInteractionReason;

  /// Data ostatniej aktualizacji (ISO-8601).
  final String lastUpdatedIso;

  /// Identyfikator paktu Blood Brothers, jeśli para ma zawarty pakt.
  final String? bloodBrothersPactId;

  const RiderRelationshipEdge({
    required this.riderAId,
    required this.riderBId,
    required this.score,
    required this.trust,
    required this.respect,
    required this.tension,
    this.sharedRacesCount = 0,
    this.sharedCampDays = 0,
    this.lastInteractionReason = 'Początek współpracy',
    this.lastUpdatedIso = '',
    this.bloodBrothersPactId,
  });

  /// Kanoniczny klucz pary niezależny od kolejności ID.
  static String canonicalPairKey(String firstId, String secondId) {
    if (firstId.compareTo(secondId) <= 0) {
      return '$firstId::$secondId';
    }
    return '$secondId::$firstId';
  }

  String get pairKey => canonicalPairKey(riderAId, riderBId);

  int get clampedScore => score.clamp(-100, 100);

  bool get hasBloodBrothersPact => bloodBrothersPactId != null;

  bool get isPositive => clampedScore >= 25;

  bool get isConflict => clampedScore <= -25;

  bool get isToxicFeud => clampedScore <= -60;

  RelationshipTier tierWithPactStatus({bool activePact = false}) {
    return RelationshipTier.fromScore(
      clampedScore,
      hasActiveBloodBrothersPact: activePact,
    );
  }

  RelationshipConnectionVisualTone visualTone({bool activePact = false}) {
    if (activePact && clampedScore >= 70) {
      return RelationshipConnectionVisualTone.gold;
    }
    if (clampedScore >= 25) {
      return RelationshipConnectionVisualTone.green;
    }
    if (clampedScore <= -25) {
      return RelationshipConnectionVisualTone.red;
    }
    return RelationshipConnectionVisualTone.neutral;
  }

  bool involves(String riderId) => riderAId == riderId || riderBId == riderId;

  String otherRiderId(String riderId) {
    if (riderAId == riderId) return riderBId;
    if (riderBId == riderId) return riderAId;
    return riderBId;
  }

  RiderRelationshipEdge copyWith({
    String? riderAId,
    String? riderBId,
    int? score,
    int? trust,
    int? respect,
    int? tension,
    int? sharedRacesCount,
    int? sharedCampDays,
    String? lastInteractionReason,
    String? lastUpdatedIso,
    String? bloodBrothersPactId,
    bool clearBloodBrothersPactId = false,
  }) {
    return RiderRelationshipEdge(
      riderAId: riderAId ?? this.riderAId,
      riderBId: riderBId ?? this.riderBId,
      score: (score ?? this.score).clamp(-100, 100),
      trust: (trust ?? this.trust).clamp(0, 100),
      respect: (respect ?? this.respect).clamp(0, 100),
      tension: (tension ?? this.tension).clamp(0, 100),
      sharedRacesCount: math.max(0, sharedRacesCount ?? this.sharedRacesCount),
      sharedCampDays: math.max(0, sharedCampDays ?? this.sharedCampDays),
      lastInteractionReason:
          lastInteractionReason ?? this.lastInteractionReason,
      lastUpdatedIso: lastUpdatedIso ?? this.lastUpdatedIso,
      bloodBrothersPactId: clearBloodBrothersPactId
          ? null
          : (bloodBrothersPactId ?? this.bloodBrothersPactId),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'riderAId': riderAId,
      'riderBId': riderBId,
      'score': clampedScore,
      'trust': trust.clamp(0, 100),
      'respect': respect.clamp(0, 100),
      'tension': tension.clamp(0, 100),
      'sharedRacesCount': sharedRacesCount,
      'sharedCampDays': sharedCampDays,
      'lastInteractionReason': lastInteractionReason,
      'lastUpdatedIso': lastUpdatedIso,
      if (bloodBrothersPactId != null)
        'bloodBrothersPactId': bloodBrothersPactId,
    };
  }

  factory RiderRelationshipEdge.fromJson(Map<String, dynamic> json) {
    final rawA = (json['riderAId'] as String?) ?? '';
    final rawB = (json['riderBId'] as String?) ?? '';
    final ordered = rawA.compareTo(rawB) <= 0 ? (rawA, rawB) : (rawB, rawA);
    return RiderRelationshipEdge(
      riderAId: ordered.$1,
      riderBId: ordered.$2,
      score: ((json['score'] as num?) ?? 0).toInt().clamp(-100, 100),
      trust: ((json['trust'] as num?) ?? 50).toInt().clamp(0, 100),
      respect: ((json['respect'] as num?) ?? 50).toInt().clamp(0, 100),
      tension: ((json['tension'] as num?) ?? 10).toInt().clamp(0, 100),
      sharedRacesCount:
          math.max(0, ((json['sharedRacesCount'] as num?) ?? 0).toInt()),
      sharedCampDays:
          math.max(0, ((json['sharedCampDays'] as num?) ?? 0).toInt()),
      lastInteractionReason:
          (json['lastInteractionReason'] as String?) ?? 'Początek współpracy',
      lastUpdatedIso: (json['lastUpdatedIso'] as String?) ?? '',
      bloodBrothersPactId: json['bloodBrothersPactId'] as String?,
    );
  }
}

/// Premia taktyczno-psychologiczna wynikająca z paktu Blood Brothers na etapie.
class BloodBrothersRaceBonus {
  /// Dodatkowa wydajność pracy pomocnika dla brata (%).
  final double domestiqueSacrificeBonusPct;

  /// Odporność morale na kraksy, ranty i defekty (%).
  final double moraleResilienceBonusPct;

  /// Zgranie w pociągu sprinterskim lub na zmianach (%).
  final double leadOutSyncBonusPct;

  /// Mnożnik gotowości do głębszego wejścia w deficyt W' dla partnera.
  final double wPrimeSacrificeMultiplier;

  const BloodBrothersRaceBonus({
    required this.domestiqueSacrificeBonusPct,
    required this.moraleResilienceBonusPct,
    required this.leadOutSyncBonusPct,
    required this.wPrimeSacrificeMultiplier,
  });

  static const BloodBrothersRaceBonus none = BloodBrothersRaceBonus(
    domestiqueSacrificeBonusPct: 0.0,
    moraleResilienceBonusPct: 0.0,
    leadOutSyncBonusPct: 0.0,
    wPrimeSacrificeMultiplier: 1.0,
  );
}

/// Pakt lojalności *Blood Brothers* łączący dwóch kolarzy najwyższą więzią w szatni.
class BloodBrothersPact {
  static const int minScoreToForge = 85;
  static const int minSharedRacesToForge = 5;
  static const int maxActivePactsPerRider = 2;

  final String pactId;
  final String riderAId;
  final String riderBId;
  final String formedDateIso;
  final String formedAtRaceName;
  final BloodBrothersPactStatus status;

  /// Siła paktu (`0..100`) rosnąca po wspólnych sukcesach.
  final int loyaltyStrength;

  /// Liczba wspólnie wygranych etapów/wyścigów lub podiów GT.
  final int sharedTriumphsCount;

  /// Liczba udokumentowanych poświęceń (oddanie koła/roweru, pogoń).
  final int selflessSacrificeCount;

  /// Powód zerwania, jeśli pakt ma status `broken`.
  final String? brokenReason;

  const BloodBrothersPact({
    required this.pactId,
    required this.riderAId,
    required this.riderBId,
    required this.formedDateIso,
    required this.formedAtRaceName,
    required this.status,
    required this.loyaltyStrength,
    this.sharedTriumphsCount = 0,
    this.selflessSacrificeCount = 0,
    this.brokenReason,
  });

  String get pairKey =>
      RiderRelationshipEdge.canonicalPairKey(riderAId, riderBId);

  bool get isActive => status == BloodBrothersPactStatus.active;

  bool involves(String riderId) => riderAId == riderId || riderBId == riderId;

  String otherRiderId(String riderId) =>
      riderAId == riderId ? riderBId : riderAId;

  /// Oblicza realne premie wyścigowe dla pary objętej paktem.
  BloodBrothersRaceBonus calculateRaceBonus() {
    if (status == BloodBrothersPactStatus.broken) {
      return BloodBrothersRaceBonus.none;
    }
    final factor = status == BloodBrothersPactStatus.strained
        ? 0.45
        : (0.75 + (loyaltyStrength.clamp(0, 100) / 100.0) * 0.35);
    return BloodBrothersRaceBonus(
      domestiqueSacrificeBonusPct:
          double.parse((7.5 * factor).toStringAsFixed(2)),
      moraleResilienceBonusPct:
          double.parse((12.0 * factor).toStringAsFixed(2)),
      leadOutSyncBonusPct: double.parse((4.5 * factor).toStringAsFixed(2)),
      wPrimeSacrificeMultiplier:
          double.parse((1.0 + 0.14 * factor).toStringAsFixed(3)),
    );
  }

  BloodBrothersPact copyWith({
    String? pactId,
    String? riderAId,
    String? riderBId,
    String? formedDateIso,
    String? formedAtRaceName,
    BloodBrothersPactStatus? status,
    int? loyaltyStrength,
    int? sharedTriumphsCount,
    int? selflessSacrificeCount,
    String? brokenReason,
  }) {
    return BloodBrothersPact(
      pactId: pactId ?? this.pactId,
      riderAId: riderAId ?? this.riderAId,
      riderBId: riderBId ?? this.riderBId,
      formedDateIso: formedDateIso ?? this.formedDateIso,
      formedAtRaceName: formedAtRaceName ?? this.formedAtRaceName,
      status: status ?? this.status,
      loyaltyStrength: (loyaltyStrength ?? this.loyaltyStrength).clamp(0, 100),
      sharedTriumphsCount:
          math.max(0, sharedTriumphsCount ?? this.sharedTriumphsCount),
      selflessSacrificeCount:
          math.max(0, selflessSacrificeCount ?? this.selflessSacrificeCount),
      brokenReason: brokenReason ?? this.brokenReason,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'pactId': pactId,
      'riderAId': riderAId,
      'riderBId': riderBId,
      'formedDateIso': formedDateIso,
      'formedAtRaceName': formedAtRaceName,
      'status': status.toJson(),
      'loyaltyStrength': loyaltyStrength.clamp(0, 100),
      'sharedTriumphsCount': sharedTriumphsCount,
      'selflessSacrificeCount': selflessSacrificeCount,
      if (brokenReason != null) 'brokenReason': brokenReason,
    };
  }

  factory BloodBrothersPact.fromJson(Map<String, dynamic> json) {
    final rawA = (json['riderAId'] as String?) ?? '';
    final rawB = (json['riderBId'] as String?) ?? '';
    final ordered = rawA.compareTo(rawB) <= 0 ? (rawA, rawB) : (rawB, rawA);
    return BloodBrothersPact(
      pactId: (json['pactId'] as String?) ?? '',
      riderAId: ordered.$1,
      riderBId: ordered.$2,
      formedDateIso: (json['formedDateIso'] as String?) ?? '',
      formedAtRaceName: (json['formedAtRaceName'] as String?) ?? 'Team Camp',
      status: BloodBrothersPactStatus.fromJson(json['status'] as String?),
      loyaltyStrength:
          ((json['loyaltyStrength'] as num?) ?? 80).toInt().clamp(0, 100),
      sharedTriumphsCount:
          math.max(0, ((json['sharedTriumphsCount'] as num?) ?? 0).toInt()),
      selflessSacrificeCount:
          math.max(0, ((json['selflessSacrificeCount'] as num?) ?? 0).toInt()),
      brokenReason: json['brokenReason'] as String?,
    );
  }
}

/// Podsumowanie kondycji psychologicznej całej szatni zespołu.
class TeamChemistrySummary {
  /// Ogólny wskaźnik chemii szatni (`0.0..100.0`).
  final double overallScore;

  /// Średnia wartość macierzy relacji (`-100.0..+100.0`).
  final double averageMatrixScore;

  /// Atmosfera w szatni.
  final LockerRoomAtmosphere atmosphere;

  /// Liczba aktywnych paktów Blood Brothers.
  final int activeBloodBrothersCount;

  /// Liczba połączeń pozytywnych (`>= 25`).
  final int positiveEdgesCount;

  /// Liczba połączeń neutralnych (`-24..24`).
  final int neutralEdgesCount;

  /// Liczba konfliktów (`<= -25`).
  final int conflictEdgesCount;

  /// Liczba toksycznych waśni (`<= -60`).
  final int toxicFeudsCount;

  /// Ryzyko buntu lub konfliktu liderów (`0.0..100.0`).
  final double leadershipConflictRisk;

  /// Mnożnik zgrania na etapie (`0.85..1.15`).
  final double raceDayCohesionMultiplier;

  /// Tygodniowy dryf morale wynikający z atmosfery szatni.
  final double weeklyMoraleDrift;

  const TeamChemistrySummary({
    required this.overallScore,
    required this.averageMatrixScore,
    required this.atmosphere,
    required this.activeBloodBrothersCount,
    required this.positiveEdgesCount,
    required this.neutralEdgesCount,
    required this.conflictEdgesCount,
    required this.toxicFeudsCount,
    required this.leadershipConflictRisk,
    required this.raceDayCohesionMultiplier,
    required this.weeklyMoraleDrift,
  });
}

/// Raport chemii dla konkretnego składu wyścigowego (np. 8 kolarzy na Grand Tour).
class RaceLineupChemistryReport {
  final List<String> selectedRiderIds;
  final double lineupChemistryScore;
  final int activeBloodBrothersPairsCount;
  final int toxicPairsCount;
  final double gcSupportBonusPct;
  final double leadOutCompatibilityBonusPct;
  final double sabotageRiskPct;
  final List<String> conflictWarnings;

  const RaceLineupChemistryReport({
    required this.selectedRiderIds,
    required this.lineupChemistryScore,
    required this.activeBloodBrothersPairsCount,
    required this.toxicPairsCount,
    required this.gcSupportBonusPct,
    required this.leadOutCompatibilityBonusPct,
    required this.sabotageRiskPct,
    required this.conflictWarnings,
  });
}

/// Wynik operacji na modelu Psychologii Szatni 2.0.
class ChemistryOperationResult {
  final bool success;
  final String message;
  final RiderRelationshipChemistryWebModel updatedModel;

  const ChemistryOperationResult({
    required this.success,
    required this.message,
    required this.updatedModel,
  });
}

/// Główny model Psychologii Szatni 2.0, macierzy relacji `-100..+100`
/// oraz paktu lojalności *Blood Brothers*.
class RiderRelationshipChemistryWebModel {
  final String teamId;
  final int seasonYear;
  final Map<String, RiderLockerRoomProfile> profiles;
  final Map<String, RiderRelationshipEdge> edges;
  final List<BloodBrothersPact> bloodBrothersPacts;
  final List<RelationshipEventRecord> recentEvents;

  const RiderRelationshipChemistryWebModel({
    required this.teamId,
    required this.seasonYear,
    required this.profiles,
    required this.edges,
    required this.bloodBrothersPacts,
    this.recentEvents = const <RelationshipEventRecord>[],
  });

  /// Tworzy pusty model szatni dla zespołu.
  factory RiderRelationshipChemistryWebModel.empty({
    required String teamId,
    required int seasonYear,
  }) {
    return RiderRelationshipChemistryWebModel(
      teamId: teamId,
      seasonYear: seasonYear,
      profiles: const <String, RiderLockerRoomProfile>{},
      edges: const <String, RiderRelationshipEdge>{},
      bloodBrothersPacts: const <BloodBrothersPact>[],
      recentEvents: const <RelationshipEventRecord>[],
    );
  }

  /// Buduje początkową sieć relacji na podstawie profili psychologicznych kolarzy.
  factory RiderRelationshipChemistryWebModel.fromRoster({
    required String teamId,
    required int seasonYear,
    required List<RiderLockerRoomProfile> roster,
    String initialDateIso = '2026-01-01',
  }) {
    final profileMap = <String, RiderLockerRoomProfile>{
      for (final profile in roster) profile.riderId: profile,
    };
    final edgeMap = <String, RiderRelationshipEdge>{};

    for (var i = 0; i < roster.length; i++) {
      for (var j = i + 1; j < roster.length; j++) {
        final a = roster[i];
        final b = roster[j];
        final ordered = a.riderId.compareTo(b.riderId) <= 0 ? (a, b) : (b, a);
        final baseScore = ordered.$1.archetype
            .baselineCompatibilityWith(ordered.$2.archetype)
            .clamp(-100, 100);
        final key = RiderRelationshipEdge.canonicalPairKey(
          ordered.$1.riderId,
          ordered.$2.riderId,
        );
        edgeMap[key] = RiderRelationshipEdge(
          riderAId: ordered.$1.riderId,
          riderBId: ordered.$2.riderId,
          score: baseScore,
          trust: (50 + baseScore ~/ 2).clamp(0, 100),
          respect: (55 + baseScore ~/ 3).clamp(0, 100),
          tension: (15 - baseScore ~/ 2).clamp(0, 100),
          lastInteractionReason: 'Otwarcie sezonu drużyny',
          lastUpdatedIso: initialDateIso,
        );
      }
    }

    return RiderRelationshipChemistryWebModel(
      teamId: teamId,
      seasonYear: seasonYear,
      profiles: Map<String, RiderLockerRoomProfile>.unmodifiable(profileMap),
      edges: Map<String, RiderRelationshipEdge>.unmodifiable(edgeMap),
      bloodBrothersPacts: const <BloodBrothersPact>[],
      recentEvents: const <RelationshipEventRecord>[],
    );
  }

  /// Zwraca krawędź relacji między dwoma kolarzami (lub `null` dla tego samego ID).
  RiderRelationshipEdge? getEdge(String riderAId, String riderBId) {
    if (riderAId == riderBId) return null;
    final key = RiderRelationshipEdge.canonicalPairKey(riderAId, riderBId);
    return edges[key];
  }

  /// Zwraca wynik relacji w skali `-100..+100` (`0`, jeśli brak krawędzi lub ten sam kolarz).
  int getScore(String riderAId, String riderBId) {
    if (riderAId == riderBId) return 0;
    return getEdge(riderAId, riderBId)?.clampedScore ?? 0;
  }

  /// Zwraca aktywny lub nadwyrężony pakt Blood Brothers między dwoma kolarzami.
  BloodBrothersPact? getPactBetween(String riderAId, String riderBId) {
    if (riderAId == riderBId) return null;
    final pairKey = RiderRelationshipEdge.canonicalPairKey(riderAId, riderBId);
    for (final pact in bloodBrothersPacts) {
      if (pact.pairKey == pairKey && pact.status != BloodBrothersPactStatus.broken) {
        return pact;
      }
    }
    return null;
  }

  /// Zwraca listę ID partnerów połączonych aktywnym paktem Blood Brothers z danym kolarzem.
  List<String> getBloodBrothersFor(String riderId) {
    return bloodBrothersPacts
        .where((p) => p.isActive && p.involves(riderId))
        .map((p) => p.otherRiderId(riderId))
        .toList(growable: false);
  }

  /// Zwraca wszystkie połączenia danego kolarza posortowane od najsilniejszej więzi.
  List<RiderRelationshipEdge> getConnectionsForRider(String riderId) {
    final result = edges.values
        .where((edge) => edge.involves(riderId))
        .toList(growable: false)
      ..sort((a, b) => b.clampedScore.compareTo(a.clampedScore));
    return result;
  }

  /// Buduje pełną symetryczną macierz relacji `N x N` dla podanej listy ID kolarzy.
  Map<String, Map<String, int>> buildRelationshipMatrix([
    List<String>? riderIds,
  ]) {
    final ids = riderIds ?? profiles.keys.toList(growable: false);
    final matrix = <String, Map<String, int>>{};
    for (final rowId in ids) {
      final row = <String, int>{};
      for (final colId in ids) {
        row[colId] = rowId == colId ? 0 : getScore(rowId, colId);
      }
      matrix[rowId] = Map<String, int>.unmodifiable(row);
    }
    return Map<String, Map<String, int>>.unmodifiable(matrix);
  }

  /// Sprawdza, czy dwaj kolarze spełniają warunki zawarcia paktu Blood Brothers.
  bool canForgeBloodBrothersPact(String riderAId, String riderBId) {
    if (riderAId == riderBId) return false;
    if (!profiles.containsKey(riderAId) || !profiles.containsKey(riderBId)) {
      return false;
    }
    final edge = getEdge(riderAId, riderBId);
    if (edge == null) return false;
    if (edge.clampedScore < BloodBrothersPact.minScoreToForge) return false;
    if (edge.sharedRacesCount < BloodBrothersPact.minSharedRacesToForge) {
      return false;
    }
    if (getPactBetween(riderAId, riderBId) != null) return false;

    final pactsA = getBloodBrothersFor(riderAId).length;
    final pactsB = getBloodBrothersFor(riderBId).length;
    if (pactsA >= BloodBrothersPact.maxActivePactsPerRider ||
        pactsB >= BloodBrothersPact.maxActivePactsPerRider) {
      return false;
    }

    // Jeśli wcześniej doszło do zerwania paktu przez tę samą parę, nie można go odnowić.
    final pairKey = RiderRelationshipEdge.canonicalPairKey(riderAId, riderBId);
    final wasBrokenBefore = bloodBrothersPacts.any(
      (p) => p.pairKey == pairKey && p.status == BloodBrothersPactStatus.broken,
    );
    return !wasBrokenBefore;
  }

  /// Zawiera pakt lojalności *Blood Brothers* między dwoma kolarzami.
  ChemistryOperationResult forgeBloodBrothersPact({
    required String riderAId,
    required String riderBId,
    required String dateIso,
    required String raceName,
    String? customPactId,
  }) {
    if (riderAId == riderBId) {
      return ChemistryOperationResult(
        success: false,
        message: 'Kolarz nie może zawrzeć paktu sam ze sobą.',
        updatedModel: this,
      );
    }
    if (!profiles.containsKey(riderAId) || !profiles.containsKey(riderBId)) {
      return ChemistryOperationResult(
        success: false,
        message: 'Brak profilu jednego z kolarzy w szatni.',
        updatedModel: this,
      );
    }
    final edge = getEdge(riderAId, riderBId);
    if (edge == null || edge.clampedScore < BloodBrothersPact.minScoreToForge) {
      return ChemistryOperationResult(
        success: false,
        message:
            'Relacja musi wynosić co najmniej +${BloodBrothersPact.minScoreToForge}, aby zawrzeć pakt Blood Brothers.',
        updatedModel: this,
      );
    }
    if (edge.sharedRacesCount < BloodBrothersPact.minSharedRacesToForge) {
      return ChemistryOperationResult(
        success: false,
        message:
            'Kolarze muszą przejechać wspólnie co najmniej ${BloodBrothersPact.minSharedRacesToForge} wyścigów.',
        updatedModel: this,
      );
    }
    if (!canForgeBloodBrothersPact(riderAId, riderBId)) {
      return ChemistryOperationResult(
        success: false,
        message:
            'Pakt Blood Brothers nie może zostać zawarty (limit paktów lub wcześniejsze zerwanie).',
        updatedModel: this,
      );
    }

    final ordered =
        riderAId.compareTo(riderBId) <= 0 ? (riderAId, riderBId) : (riderBId, riderAId);
    final pactId = customPactId ?? 'bb_${ordered.$1}_${ordered.$2}_$seasonYear';
    final newPact = BloodBrothersPact(
      pactId: pactId,
      riderAId: ordered.$1,
      riderBId: ordered.$2,
      formedDateIso: dateIso,
      formedAtRaceName: raceName,
      status: BloodBrothersPactStatus.active,
      loyaltyStrength: math.max(85, edge.clampedScore),
    );

    final updatedEdge = edge.copyWith(
      score: math.max(edge.clampedScore, 92),
      trust: math.max(edge.trust, 92),
      respect: math.max(edge.respect, 90),
      tension: math.min(edge.tension, 5),
      bloodBrothersPactId: pactId,
      lastInteractionReason: 'Zawarto pakt Blood Brothers ($raceName)',
      lastUpdatedIso: dateIso,
    );

    final updatedEdges = Map<String, RiderRelationshipEdge>.from(edges)
      ..[updatedEdge.pairKey] = updatedEdge;

    final event = RelationshipEventRecord(
      eventId: 'evt_${pactId}_forged',
      riderAId: ordered.$1,
      riderBId: ordered.$2,
      eventType: RelationshipEventType.bloodBrothersForged,
      scoreDelta: updatedEdge.clampedScore - edge.clampedScore,
      resultingScore: updatedEdge.clampedScore,
      summary: 'Zawarto pakt lojalności Blood Brothers po wyścigu $raceName.',
      dateIso: dateIso,
      raceName: raceName,
    );

    final updatedModel = RiderRelationshipChemistryWebModel(
      teamId: teamId,
      seasonYear: seasonYear,
      profiles: profiles,
      edges: Map<String, RiderRelationshipEdge>.unmodifiable(updatedEdges),
      bloodBrothersPacts: List<BloodBrothersPact>.unmodifiable(
        <BloodBrothersPact>[...bloodBrothersPacts, newPact],
      ),
      recentEvents: List<RelationshipEventRecord>.unmodifiable(
        <RelationshipEventRecord>[event, ...recentEvents].take(50),
      ),
    );

    return ChemistryOperationResult(
      success: true,
      message: 'Pakt Blood Brothers został zawarty.',
      updatedModel: updatedModel,
    );
  }

  /// Zrywa pakt Blood Brothers z powodu zdrady lub konfliktu, powodując głęboki kryzys.
  ChemistryOperationResult breakBloodBrothersPact({
    required String pactId,
    required String reason,
    required String dateIso,
  }) {
    final index = bloodBrothersPacts.indexWhere((p) => p.pactId == pactId);
    if (index == -1) {
      return ChemistryOperationResult(
        success: false,
        message: 'Nie znaleziono wskazanego paktu Blood Brothers.',
        updatedModel: this,
      );
    }

    final target = bloodBrothersPacts[index];
    if (target.status == BloodBrothersPactStatus.broken) {
      return ChemistryOperationResult(
        success: false,
        message: 'Pakt został już wcześniej zerwany.',
        updatedModel: this,
      );
    }

    final updatedPacts = List<BloodBrothersPact>.from(bloodBrothersPacts);
    updatedPacts[index] = target.copyWith(
      status: BloodBrothersPactStatus.broken,
      loyaltyStrength: 0,
      brokenReason: reason,
    );

    final updatedEdges = Map<String, RiderRelationshipEdge>.from(edges);
    final existingEdge = getEdge(target.riderAId, target.riderBId);
    final prevScore = existingEdge?.clampedScore ?? 85;
    const betrayalScore = -75;

    if (existingEdge != null) {
      updatedEdges[existingEdge.pairKey] = existingEdge.copyWith(
        score: betrayalScore,
        trust: 5,
        respect: 15,
        tension: 95,
        clearBloodBrothersPactId: true,
        lastInteractionReason: 'Zerwanie paktu Blood Brothers: $reason',
        lastUpdatedIso: dateIso,
      );
    }

    final event = RelationshipEventRecord(
      eventId: 'evt_${pactId}_broken',
      riderAId: target.riderAId,
      riderBId: target.riderBId,
      eventType: RelationshipEventType.bloodBrothersBroken,
      scoreDelta: betrayalScore - prevScore,
      resultingScore: betrayalScore,
      summary: 'Zdrada! Pakt Blood Brothers zerwany: $reason',
      dateIso: dateIso,
    );

    return ChemistryOperationResult(
      success: true,
      message: 'Pakt Blood Brothers został zerwany.',
      updatedModel: RiderRelationshipChemistryWebModel(
        teamId: teamId,
        seasonYear: seasonYear,
        profiles: profiles,
        edges: Map<String, RiderRelationshipEdge>.unmodifiable(updatedEdges),
        bloodBrothersPacts:
            List<BloodBrothersPact>.unmodifiable(updatedPacts),
        recentEvents: List<RelationshipEventRecord>.unmodifiable(
          <RelationshipEventRecord>[event, ...recentEvents].take(50),
        ),
      ),
    );
  }

  /// Rejestruje zdarzenie między dwoma kolarzami i aktualizuje macierz `-100..+100`.
  ChemistryOperationResult applyInteractionEvent({
    required String riderAId,
    required String riderBId,
    required RelationshipEventType eventType,
    required int scoreDelta,
    required String summary,
    required String dateIso,
    String? raceName,
    int incrementSharedRaces = 0,
    int incrementCampDays = 0,
  }) {
    if (riderAId == riderBId) {
      return ChemistryOperationResult(
        success: false,
        message: 'Nie można zapisać interakcji kolarza z samym sobą.',
        updatedModel: this,
      );
    }
    if (!profiles.containsKey(riderAId) || !profiles.containsKey(riderBId)) {
      return ChemistryOperationResult(
        success: false,
        message: 'Brak jednego z kolarzy w szatni zespołu.',
        updatedModel: this,
      );
    }

    final ordered =
        riderAId.compareTo(riderBId) <= 0 ? (riderAId, riderBId) : (riderBId, riderAId);
    final key = RiderRelationshipEdge.canonicalPairKey(ordered.$1, ordered.$2);
    final currentEdge = edges[key] ??
        RiderRelationshipEdge(
          riderAId: ordered.$1,
          riderBId: ordered.$2,
          score: 0,
          trust: 50,
          respect: 50,
          tension: 15,
        );

    final newScore = (currentEdge.clampedScore + scoreDelta).clamp(-100, 100);
    final trustShift = scoreDelta >= 0 ? (scoreDelta * 0.6).round() : (scoreDelta * 0.8).round();
    final respectShift = (scoreDelta * 0.4).round();
    final tensionShift = scoreDelta >= 0 ? -(scoreDelta * 0.5).round() : (-scoreDelta * 0.75).round();

    var updatedEdge = currentEdge.copyWith(
      score: newScore,
      trust: (currentEdge.trust + trustShift).clamp(0, 100),
      respect: (currentEdge.respect + respectShift).clamp(0, 100),
      tension: (currentEdge.tension + tensionShift).clamp(0, 100),
      sharedRacesCount: currentEdge.sharedRacesCount + incrementSharedRaces,
      sharedCampDays: currentEdge.sharedCampDays + incrementCampDays,
      lastInteractionReason: summary,
      lastUpdatedIso: dateIso,
    );

    var updatedPacts = List<BloodBrothersPact>.from(bloodBrothersPacts);
    final pactIndex = updatedPacts.indexWhere(
      (p) => p.pairKey == key && p.status != BloodBrothersPactStatus.broken,
    );
    if (pactIndex != -1) {
      final pact = updatedPacts[pactIndex];
      if (scoreDelta <= -35 || newScore < 40) {
        updatedPacts[pactIndex] = pact.copyWith(
          status: BloodBrothersPactStatus.broken,
          loyaltyStrength: 0,
          brokenReason: summary,
        );
        updatedEdge = updatedEdge.copyWith(clearBloodBrothersPactId: true);
      } else if (newScore < 70 || scoreDelta <= -15) {
        updatedPacts[pactIndex] = pact.copyWith(
          status: BloodBrothersPactStatus.strained,
          loyaltyStrength: math.max(30, pact.loyaltyStrength + scoreDelta),
        );
      } else {
        final isSacrifice =
            eventType == RelationshipEventType.wheelOrBikeSacrifice ||
                eventType == RelationshipEventType.heroicMountainDefense;
        final isTriumph = eventType == RelationshipEventType.winningLeadOut;
        updatedPacts[pactIndex] = pact.copyWith(
          status: BloodBrothersPactStatus.active,
          loyaltyStrength:
              (pact.loyaltyStrength + math.max(0, scoreDelta ~/ 2))
                  .clamp(0, 100)
                  .toInt(),
          sharedTriumphsCount:
              pact.sharedTriumphsCount + (isTriumph ? 1 : 0),
          selflessSacrificeCount:
              pact.selflessSacrificeCount + (isSacrifice ? 1 : 0),
        );
      }
    }

    final updatedEdges = Map<String, RiderRelationshipEdge>.from(edges)
      ..[key] = updatedEdge;

    final event = RelationshipEventRecord(
      eventId: 'evt_${key}_${recentEvents.length + 1}_$dateIso',
      riderAId: ordered.$1,
      riderBId: ordered.$2,
      eventType: eventType,
      scoreDelta: scoreDelta,
      resultingScore: newScore,
      summary: summary,
      dateIso: dateIso,
      raceName: raceName,
    );

    return ChemistryOperationResult(
      success: true,
      message: 'Zaktualizowano relację na $newScore.',
      updatedModel: RiderRelationshipChemistryWebModel(
        teamId: teamId,
        seasonYear: seasonYear,
        profiles: profiles,
        edges: Map<String, RiderRelationshipEdge>.unmodifiable(updatedEdges),
        bloodBrothersPacts:
            List<BloodBrothersPact>.unmodifiable(updatedPacts),
        recentEvents: List<RelationshipEventRecord>.unmodifiable(
          <RelationshipEventRecord>[event, ...recentEvents].take(50),
        ),
      ),
    );
  }

  /// Dodaje lub aktualizuje profil kolarza w szatni oraz tworzy brakujące krawędzie.
  RiderRelationshipChemistryWebModel registerRiderProfile(
    RiderLockerRoomProfile profile, {
    String dateIso = '2026-01-01',
  }) {
    final updatedProfiles = Map<String, RiderLockerRoomProfile>.from(profiles)
      ..[profile.riderId] = profile;
    final updatedEdges = Map<String, RiderRelationshipEdge>.from(edges);

    for (final other in profiles.values) {
      if (other.riderId == profile.riderId) continue;
      final ordered = profile.riderId.compareTo(other.riderId) <= 0
          ? (profile, other)
          : (other, profile);
      final key = RiderRelationshipEdge.canonicalPairKey(
        ordered.$1.riderId,
        ordered.$2.riderId,
      );
      updatedEdges.putIfAbsent(
        key,
        () {
          final base = ordered.$1.archetype
              .baselineCompatibilityWith(ordered.$2.archetype)
              .clamp(-100, 100);
          return RiderRelationshipEdge(
            riderAId: ordered.$1.riderId,
            riderBId: ordered.$2.riderId,
            score: base,
            trust: (50 + base ~/ 2).clamp(0, 100),
            respect: (55 + base ~/ 3).clamp(0, 100),
            tension: (15 - base ~/ 2).clamp(0, 100),
            lastInteractionReason: 'Dołączenie do zespołu',
            lastUpdatedIso: dateIso,
          );
        },
      );
    }

    return RiderRelationshipChemistryWebModel(
      teamId: teamId,
      seasonYear: seasonYear,
      profiles: Map<String, RiderLockerRoomProfile>.unmodifiable(updatedProfiles),
      edges: Map<String, RiderRelationshipEdge>.unmodifiable(updatedEdges),
      bloodBrothersPacts: bloodBrothersPacts,
      recentEvents: recentEvents,
    );
  }

  /// Usuwa kolarza z szatni (np. po transferze) i zamyka jego krawędzie.
  RiderRelationshipChemistryWebModel removeRiderProfile(String riderId) {
    if (!profiles.containsKey(riderId)) return this;
    final updatedProfiles = Map<String, RiderLockerRoomProfile>.from(profiles)
      ..remove(riderId);
    final updatedEdges = Map<String, RiderRelationshipEdge>.from(edges)
      ..removeWhere((_, edge) => edge.involves(riderId));
    final updatedPacts = bloodBrothersPacts
        .where((pact) => !pact.involves(riderId))
        .toList(growable: false);

    return RiderRelationshipChemistryWebModel(
      teamId: teamId,
      seasonYear: seasonYear,
      profiles: Map<String, RiderLockerRoomProfile>.unmodifiable(updatedProfiles),
      edges: Map<String, RiderRelationshipEdge>.unmodifiable(updatedEdges),
      bloodBrothersPacts: List<BloodBrothersPact>.unmodifiable(updatedPacts),
      recentEvents: recentEvents,
    );
  }

  /// Wylicza całościowe podsumowanie chemii szatni i atmosfery w drużynie.
  TeamChemistrySummary calculateOverallTeamChemistry() {
    if (edges.isEmpty) {
      return const TeamChemistrySummary(
        overallScore: 50.0,
        averageMatrixScore: 0.0,
        atmosphere: LockerRoomAtmosphere.professional,
        activeBloodBrothersCount: 0,
        positiveEdgesCount: 0,
        neutralEdgesCount: 0,
        conflictEdgesCount: 0,
        toxicFeudsCount: 0,
        leadershipConflictRisk: 0.0,
        raceDayCohesionMultiplier: 1.0,
        weeklyMoraleDrift: 0.0,
      );
    }

    var sumScores = 0;
    var positiveCount = 0;
    var neutralCount = 0;
    var conflictCount = 0;
    var toxicCount = 0;
    var alphaClashAccum = 0.0;

    for (final edge in edges.values) {
      final s = edge.clampedScore;
      sumScores += s;
      if (s >= 25) {
        positiveCount++;
      } else if (s <= -60) {
        toxicCount++;
        conflictCount++;
      } else if (s <= -25) {
        conflictCount++;
      } else {
        neutralCount++;
      }

      if (s < 0) {
        final pA = profiles[edge.riderAId];
        final pB = profiles[edge.riderBId];
        if (pA != null && pB != null) {
          final combinedEgo = (pA.egoLevel + pB.egoLevel) / 200.0;
          alphaClashAccum += (-s) * combinedEgo * 0.45;
        }
      }
    }

    final avgScore = sumScores / edges.length;
    final activePacts =
        bloodBrothersPacts.where((p) => p.isActive).length;
    final captainBonus =
        profiles.values.any((p) => p.isTeamCaptain) ? 3.5 : 0.0;

    final rawOverall = 50.0 +
        (avgScore * 0.42) +
        (activePacts * 3.5) -
        (toxicCount * 7.0) +
        captainBonus;
    final overallScore = rawOverall.clamp(0.0, 100.0);

    final LockerRoomAtmosphere atmosphere;
    if (toxicCount >= 3 || overallScore < 22.0) {
      atmosphere = LockerRoomAtmosphere.civilWar;
    } else if (toxicCount >= 1 || overallScore < 38.0) {
      atmosphere = LockerRoomAtmosphere.fractured;
    } else if (conflictCount > positiveCount || overallScore < 50.0) {
      atmosphere = LockerRoomAtmosphere.tense;
    } else if (overallScore >= 82.0 && conflictCount == 0) {
      atmosphere = LockerRoomAtmosphere.unitedFront;
    } else if (overallScore >= 65.0) {
      atmosphere = LockerRoomAtmosphere.harmonious;
    } else {
      atmosphere = LockerRoomAtmosphere.professional;
    }

    final leadershipRisk =
        (alphaClashAccum + toxicCount * 14.0).clamp(0.0, 100.0);
    final cohesionMultiplier =
        (0.85 + (overallScore / 100.0) * 0.30).clamp(0.85, 1.15);
    final weeklyMoraleDrift =
        ((overallScore - 50.0) / 14.0).clamp(-4.0, 4.0);

    return TeamChemistrySummary(
      overallScore: double.parse(overallScore.toStringAsFixed(1)),
      averageMatrixScore: double.parse(avgScore.toStringAsFixed(1)),
      atmosphere: atmosphere,
      activeBloodBrothersCount: activePacts,
      positiveEdgesCount: positiveCount,
      neutralEdgesCount: neutralCount,
      conflictEdgesCount: conflictCount,
      toxicFeudsCount: toxicCount,
      leadershipConflictRisk: double.parse(leadershipRisk.toStringAsFixed(1)),
      raceDayCohesionMultiplier:
          double.parse(cohesionMultiplier.toStringAsFixed(3)),
      weeklyMoraleDrift: double.parse(weeklyMoraleDrift.toStringAsFixed(2)),
    );
  }

  /// Ocenia chemię wybranego składu na konkretny wyścig (np. 8 kolarzy na Tour).
  RaceLineupChemistryReport evaluateLineupChemistry(
    List<String> selectedRiderIds,
  ) {
    final uniqueIds = selectedRiderIds.toSet().toList(growable: false);
    if (uniqueIds.length < 2) {
      return RaceLineupChemistryReport(
        selectedRiderIds: uniqueIds,
        lineupChemistryScore: 50.0,
        activeBloodBrothersPairsCount: 0,
        toxicPairsCount: 0,
        gcSupportBonusPct: 0.0,
        leadOutCompatibilityBonusPct: 0.0,
        sabotageRiskPct: 0.0,
        conflictWarnings: const <String>[],
      );
    }

    var pairSum = 0;
    var pairCount = 0;
    var bbPairs = 0;
    var toxicPairs = 0;
    var gcBonus = 0.0;
    var leadOutBonus = 0.0;
    final warnings = <String>[];

    for (var i = 0; i < uniqueIds.length; i++) {
      for (var j = i + 1; j < uniqueIds.length; j++) {
        final idA = uniqueIds[i];
        final idB = uniqueIds[j];
        final score = getScore(idA, idB);
        pairSum += score;
        pairCount++;

        final pact = getPactBetween(idA, idB);
        if (pact != null && pact.isActive) {
          bbPairs++;
          final bonus = pact.calculateRaceBonus();
          gcBonus += bonus.domestiqueSacrificeBonusPct * 0.5;
          leadOutBonus += bonus.leadOutSyncBonusPct * 0.5;
        } else if (score >= 50) {
          gcBonus += 1.2;
          leadOutBonus += 0.9;
        } else if (score <= -60) {
          toxicPairs++;
          final nameA = profiles[idA]?.riderName ?? idA;
          final nameB = profiles[idB]?.riderName ?? idB;
          warnings.add('Toksyczny konflikt w składzie: $nameA vs $nameB ($score)');
        } else if (score <= -25) {
          final nameA = profiles[idA]?.riderName ?? idA;
          final nameB = profiles[idB]?.riderName ?? idB;
          warnings.add('Napięcie między kolarzami: $nameA i $nameB ($score)');
        }
      }
    }

    final avgPair = pairCount > 0 ? pairSum / pairCount : 0.0;
    final lineupScore = (50.0 + avgPair * 0.45 + bbPairs * 4.0 - toxicPairs * 8.0)
        .clamp(0.0, 100.0);
    final sabotageRisk = (toxicPairs * 18.0 + (warnings.length - toxicPairs) * 4.5)
        .clamp(0.0, 95.0);

    return RaceLineupChemistryReport(
      selectedRiderIds: uniqueIds,
      lineupChemistryScore: double.parse(lineupScore.toStringAsFixed(1)),
      activeBloodBrothersPairsCount: bbPairs,
      toxicPairsCount: toxicPairs,
      gcSupportBonusPct: double.parse(gcBonus.clamp(0.0, 25.0).toStringAsFixed(2)),
      leadOutCompatibilityBonusPct:
          double.parse(leadOutBonus.clamp(0.0, 20.0).toStringAsFixed(2)),
      sabotageRiskPct: double.parse(sabotageRisk.toStringAsFixed(1)),
      conflictWarnings: List<String>.unmodifiable(warnings),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'teamId': teamId,
      'seasonYear': seasonYear,
      'profiles': profiles.map((key, value) => MapEntry(key, value.toJson())),
      'edges': edges.map((key, value) => MapEntry(key, value.toJson())),
      'bloodBrothersPacts':
          bloodBrothersPacts.map((p) => p.toJson()).toList(growable: false),
      'recentEvents':
          recentEvents.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory RiderRelationshipChemistryWebModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawProfiles =
        (json['profiles'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final parsedProfiles = <String, RiderLockerRoomProfile>{};
    for (final entry in rawProfiles.entries) {
      if (entry.value is Map<String, dynamic>) {
        final profile = RiderLockerRoomProfile.fromJson(
          entry.value as Map<String, dynamic>,
        );
        parsedProfiles[entry.key] = profile;
      }
    }

    final rawEdges =
        (json['edges'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final parsedEdges = <String, RiderRelationshipEdge>{};
    for (final entry in rawEdges.entries) {
      if (entry.value is Map<String, dynamic>) {
        final edge = RiderRelationshipEdge.fromJson(
          entry.value as Map<String, dynamic>,
        );
        parsedEdges[edge.pairKey] = edge;
      }
    }

    final rawPacts = (json['bloodBrothersPacts'] as List<dynamic>?) ?? const [];
    final parsedPacts = rawPacts
        .whereType<Map<String, dynamic>>()
        .map(BloodBrothersPact.fromJson)
        .toList(growable: false);

    final rawEvents = (json['recentEvents'] as List<dynamic>?) ?? const [];
    final parsedEvents = rawEvents
        .whereType<Map<String, dynamic>>()
        .map(RelationshipEventRecord.fromJson)
        .toList(growable: false);

    return RiderRelationshipChemistryWebModel(
      teamId: (json['teamId'] as String?) ?? '',
      seasonYear: ((json['seasonYear'] as num?) ?? 2026).toInt(),
      profiles: Map<String, RiderLockerRoomProfile>.unmodifiable(parsedProfiles),
      edges: Map<String, RiderRelationshipEdge>.unmodifiable(parsedEdges),
      bloodBrothersPacts:
          List<BloodBrothersPact>.unmodifiable(parsedPacts),
      recentEvents: List<RelationshipEventRecord>.unmodifiable(parsedEvents),
    );
  }
}
