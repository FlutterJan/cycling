import 'dart:math' as math;
import '../../models/race/race_stage.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Stan fazy formowania i życia ucieczki dnia.
enum BreakawayFormationStage {
  /// Od startu ostrogo (km 0 - 10): pierwsze ataki po opuszczeniu flagi sędziego
  flagDropAttacks,

  /// Faza selekcji ucieczki (km 10 - 40): formowanie właściwego odjazdu dnia
  forming,

  /// Ucieczka uformowana i odjechana (peleton odpuścił pościg, zablokował szosę)
  established,

  /// Ucieczka skasowana przez peleton
  caught;

  String toJson() => name;

  static BreakawayFormationStage fromJson(String value) {
    return BreakawayFormationStage.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BreakawayFormationStage.forming,
    );
  }
}

/// Rola kolarza we współpracy wewnątrz ucieczki.
enum BreakawayRiderRole {
  /// Kolarz daje równe, solidne zmiany w formacji (Relay / Rotating Paceline)
  cooperativeRelay,

  /// Kolarz wiezie się na kole (wheelsucker), odmawia pracy na czele
  wheelsucker,

  /// Kolarz sfrustrowany brakiem współpracy wykonuje skoki i ataki z ucieczki
  attacker;

  String toJson() => name;

  static BreakawayRiderRole fromJson(String value) {
    return BreakawayRiderRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BreakawayRiderRole.cooperativeRelay,
    );
  }
}

/// Szczegółowy status pojedynczego uciekiniera w formacji ucieczki.
class BreakawayRiderStatus {
  final String riderId;
  final BreakawayRiderRole role;

  /// Stopień wkładu w dawanie zmian [0.0 = brak zmian, 1.0 = pełny udział w rotacji]
  final double pullContributionRatio;

  /// Liczba zmian danych na czele od uformowania ucieczki
  final int turnsTaken;

  /// Łączny czas spędzony na czele ucieczki tnąc wiatr [s]
  final double secondsAtFront;

  /// Motywacja taktyczna zachowania (np. "Lider w peletonie - zakaz zmian", "Równe zmiany")
  final String tacticalMotive;

  const BreakawayRiderStatus({
    required this.riderId,
    required this.role,
    required this.pullContributionRatio,
    this.turnsTaken = 0,
    this.secondsAtFront = 0.0,
    required this.tacticalMotive,
  });

  bool get isWorking => role == BreakawayRiderRole.cooperativeRelay;
  bool get isWheelsucking => role == BreakawayRiderRole.wheelsucker;

  BreakawayRiderStatus copyWith({
    String? riderId,
    BreakawayRiderRole? role,
    double? pullContributionRatio,
    int? turnsTaken,
    double? secondsAtFront,
    String? tacticalMotive,
  }) {
    return BreakawayRiderStatus(
      riderId: riderId ?? this.riderId,
      role: role ?? this.role,
      pullContributionRatio: pullContributionRatio ?? this.pullContributionRatio,
      turnsTaken: turnsTaken ?? this.turnsTaken,
      secondsAtFront: secondsAtFront ?? this.secondsAtFront,
      tacticalMotive: tacticalMotive ?? this.tacticalMotive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'role': role.toJson(),
      'pullContributionRatio': pullContributionRatio,
      'turnsTaken': turnsTaken,
      'secondsAtFront': secondsAtFront,
      'tacticalMotive': tacticalMotive,
    };
  }

  factory BreakawayRiderStatus.fromJson(Map<String, dynamic> json) {
    return BreakawayRiderStatus(
      riderId: json['riderId'] as String,
      role: BreakawayRiderRole.fromJson(json['role'] as String),
      pullContributionRatio: (json['pullContributionRatio'] as num).toDouble(),
      turnsTaken: (json['turnsTaken'] as num?)?.toInt() ?? 0,
      secondsAtFront: (json['secondsAtFront'] as num?)?.toDouble() ?? 0.0,
      tacticalMotive: json['tacticalMotive'] as String? ?? 'Współpraca w ucieczce',
    );
  }

  @override
  String toString() {
    return 'BreakawayRiderStatus($riderId, ${role.name}, pull: ${(pullContributionRatio * 100).toStringAsFixed(0)}%, '
        'turns: $turnsTaken, motive: "$tacticalMotive")';
  }
}

/// Pełny stan ucieczki dnia i jakości jej współpracy.
class BreakawayGroupStatus {
  final String groupId;
  final BreakawayFormationStage stage;
  final List<BreakawayRiderStatus> riderStatuses;

  /// Wskaźnik jakości współpracy ucieczki [0.0 - 1.0] (1.0 = idealna karuzela, < 0.65 = kryzys i skoki)
  final double cooperationScore;

  /// Czy współpraca w ucieczce uległa załamaniu (zaczynają się skoki i kłótnie)
  bool get isCooperationBroken => cooperationScore < 0.65;

  /// Czy w grupie znajduje się co najmniej jeden kolarz wiozący się na kole
  bool get hasWheelsuckers => riderStatuses.any((r) => r.isWheelsucking);

  /// Identyfikatory kolarzy wiozących się na kole
  List<String> get wheelsuckerIds =>
      riderStatuses.where((r) => r.isWheelsucking).map((r) => r.riderId).toList();

  /// Czy w ucieczce trwają aktualnie wewnętrzne ataki i skoki
  final bool isUnderAttack;

  /// Aktualna przewaga czasowa nad peletonem w sekundach [s]
  final double currentGapSeconds;

  /// Dystans pokonany przez ucieczkę na etapie w km
  final double distanceCoveredKm;

  /// Efekt prędkości współpracy: bonus do prędkości przy idealnej zmianie lub kara przy kłótniach [km/h]
  double get speedModifierKmh {
    if (isCooperationBroken) {
      // Przy kłótniach i wożeniu się prędkość ucieczki drastycznie spada (-3.5 do -5.0 km/h)
      return -4.2;
    }
    // Przy idealnych, zgranych zmianach ucieczka zyskuje aerodynamicznie (+2.0 km/h)
    return (cooperationScore - 0.70) * 6.5;
  }

  const BreakawayGroupStatus({
    required this.groupId,
    required this.stage,
    required this.riderStatuses,
    required this.cooperationScore,
    required this.isUnderAttack,
    required this.currentGapSeconds,
    required this.distanceCoveredKm,
  });

  int get riderCount => riderStatuses.length;

  BreakawayGroupStatus copyWith({
    String? groupId,
    BreakawayFormationStage? stage,
    List<BreakawayRiderStatus>? riderStatuses,
    double? cooperationScore,
    bool? isUnderAttack,
    double? currentGapSeconds,
    double? distanceCoveredKm,
  }) {
    return BreakawayGroupStatus(
      groupId: groupId ?? this.groupId,
      stage: stage ?? this.stage,
      riderStatuses: riderStatuses ?? this.riderStatuses,
      cooperationScore: cooperationScore ?? this.cooperationScore,
      isUnderAttack: isUnderAttack ?? this.isUnderAttack,
      currentGapSeconds: currentGapSeconds ?? this.currentGapSeconds,
      distanceCoveredKm: distanceCoveredKm ?? this.distanceCoveredKm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'stage': stage.toJson(),
      'riderStatuses': riderStatuses.map((r) => r.toJson()).toList(),
      'cooperationScore': cooperationScore,
      'isUnderAttack': isUnderAttack,
      'currentGapSeconds': currentGapSeconds,
      'distanceCoveredKm': distanceCoveredKm,
    };
  }

  factory BreakawayGroupStatus.fromJson(Map<String, dynamic> json) {
    return BreakawayGroupStatus(
      groupId: json['groupId'] as String,
      stage: BreakawayFormationStage.fromJson(json['stage'] as String),
      riderStatuses: (json['riderStatuses'] as List<dynamic>)
          .map((e) => BreakawayRiderStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
      cooperationScore: (json['cooperationScore'] as num).toDouble(),
      isUnderAttack: json['isUnderAttack'] as bool? ?? false,
      currentGapSeconds: (json['currentGapSeconds'] as num).toDouble(),
      distanceCoveredKm: (json['distanceCoveredKm'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'BreakawayGroupStatus(riders: $riderCount, stage: ${stage.name}, '
        'cooperation: ${(cooperationScore * 100).toStringAsFixed(0)}%, '
        'broken: $isCooperationBroken, underAttack: $isUnderAttack, '
        'gap: ${currentGapSeconds.toStringAsFixed(1)}s)';
  }
}

/// Kontroler sztucznej inteligencji zarządzający powstawaniem i współpracą ucieczki dnia.
class BreakawayAiController {
  BreakawayAiController._();

  /// Ocenia, czy dany kolarz podejmie próbę ataku do ucieczki na pierwszych 10-40 km etapu.
  ///
  /// Analizuje:
  /// 1. Profil etapu ([RaceStage.stageType]): pagórkowate i górskie etapy faworyzują ucieczki.
  /// 2. Sytuację w klasyfikacji generalnej ([gcTimeGapSeconds]): kolarze ze stratą > 15-20 min mają zielone światło.
  /// 3. Dywizję zespołu ([TeamDivision]): ekipy ProTeam i Continental są pod presją sponsorów do ataków.
  /// 4. Specjalizację ([RiderSpecialization.breakawaySpecialist], puncher, classicCobbles, pureClimber).
  static bool shouldRiderAttackEarlyStage({
    required Rider rider,
    required TeamDivision teamDivision,
    required StageType stageType,
    required double currentKm,
    required double gcTimeGapSeconds,
    bool isStageFirstDay = false,
  }) {
    // Na czasówkach nie ma ucieczek
    if (stageType == StageType.individualTimeTrial || stageType == StageType.teamTimeTrial) {
      return false;
    }

    // Ucieczka formuje się w oknie 0 - 45 km etapu
    if (currentKm > 45.0) {
      return false;
    }

    // 1. Filtr zagrożenia w klasyfikacji generalnej (GC):
    // Jeśli to nie 1. etap, a kolarz ma małą stratę (< 3.5 minuty), peleton go zablokuje,
    // więc inteligentny kolarz nie marnuje sił.
    if (!isStageFirstDay && gcTimeGapSeconds < 210.0) {
      return false;
    }

    // 2. Bazowa chęć do ataku w zależności od specjalizacji:
    double desireScore = 0.0;
    switch (rider.specialization) {
      case RiderSpecialization.breakawaySpecialist:
        desireScore += 55.0; // Główna misja życiowa
        break;
      case RiderSpecialization.puncher:
        desireScore += (stageType == StageType.hilly || stageType == StageType.cobbleClassic) ? 45.0 : 25.0;
        break;
      case RiderSpecialization.classicCobbles:
        desireScore += (stageType == StageType.cobbleClassic || stageType == StageType.flat) ? 40.0 : 15.0;
        break;
      case RiderSpecialization.pureClimber:
        desireScore += (stageType == StageType.highMountain || stageType == StageType.summitFinish) ? 50.0 : 10.0;
        break;
      case RiderSpecialization.domestiqueEngine:
        desireScore += 20.0; // Może jechać jako stacja przekaźnikowa (satellite rider)
        break;
      case RiderSpecialization.timeTrialist:
        desireScore += 25.0; // Dobry motor na płaskie harce
        break;
      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.versatileSprinter:
        desireScore -= 60.0; // Czekają na finisz z peletonu
        break;
      case RiderSpecialization.gcClimber:
        desireScore -= 80.0; // Oszczędza siły na decydującą wspinaczkę faworytów
        break;
    }

    // 3. Wpływ dywizji zespołu (wymóg ekspozycji telewizyjnej dla sponsorów):
    if (teamDivision == TeamDivision.proTeam) {
      desireScore += 35.0; // Dzika karta / ProTeam musi atakować
    } else if (teamDivision == TeamDivision.continental) {
      desireScore += 45.0;
    } else {
      desireScore += 10.0; // WorldTour
    }

    // 4. Bezpieczeństwo w GC: im większa strata, tym większa wolność od dyrektora
    if (gcTimeGapSeconds > 1200.0) {
      desireScore += 25.0; // Ponad 20 minut straty
    } else if (gcTimeGapSeconds > 600.0) {
      desireScore += 15.0;
    }

    // 5. Morale i cechy charakteru (Race IQ)
    desireScore += (rider.skills.raceIq - 50) * 0.25;

    // Próg decyzji o ataku (wymagane > 65 punktów chęci)
    return desireScore >= 65.0;
  }

  /// Ocenia, czy peleton "odpuści" ucieczkę (da jej odjechać), czy natychmiast ją skasuje.
  ///
  /// Peleton kasuje ucieczkę, gdy:
  /// - Znajduje się w niej jakikolwiek kolarz zagrażający liderowi GC (< 3-4 min straty).
  /// - Grupa jest zbyt liczna (np. > 20 kolarzy na płaskim etapie).
  /// - Drużyny sprinterskie na płaskim etapie nie chcą oddać etapu zbyt silnej grupie.
  static bool shouldPelotonLetBreakawayGo({
    required List<Rider> breakawayRiders,
    required Map<String, double> gcTimeGapsSeconds,
    required StageType stageType,
    bool isStageFirstDay = false,
  }) {
    if (breakawayRiders.isEmpty) return false;

    // 1. Weryfikacja zagrożenia w GC:
    if (!isStageFirstDay) {
      for (final rider in breakawayRiders) {
        final double gap = gcTimeGapsSeconds[rider.id] ?? 9999.0;
        // Jeśli choć jeden kolarz traci mniej niż 3 minuty i 30 sekund, peleton goni bez litości
        if (gap < 210.0) {
          return false;
        }
      }
    } else {
      // Na pierwszym etapie peleton nie puści faworytów GC
      for (final rider in breakawayRiders) {
        if (rider.specialization == RiderSpecialization.gcClimber) {
          return false;
        }
      }
    }

    // 2. Liczebność ucieczki:
    final int count = breakawayRiders.length;
    if (stageType == StageType.flat && count > 7) {
      return false; // Na płaskim peleton woli małą ucieczkę (2-5 kolarzy)
    }
    if (count > 22) {
      return false; // Zbyt wielka grupa, brak kontroli
    }

    return true;
  }

  /// Aktualizuje stan współpracy wewnątrz ucieczki w danej sekundzie wyścigu.
  ///
  /// Analizuje:
  /// - Czy kolarze dają równe zmiany (`Relay`), czy ktoś wiezie się na kole (`wheelsucking`).
  /// - Kolarz wiezie się na kole, jeśli:
  ///   a) Ma kolegę/lidera z zespołu w peletonie, który jedzie po zwycięstwo.
  ///   b) Jest skrajnie wyczerpany ($W' \le 0$ lub glikogen krytycznie niski).
  ///   c) Taktycznie żeruje na rywalach.
  /// - Jeśli ktoś się wiezie: `cooperationScore` spada, średnia prędkość ucieczki siada,
  ///   a rywale zaczynają rwać tempo skokami.
  static BreakawayGroupStatus updateBreakawayCooperation({
    required BreakawayGroupStatus currentStatus,
    required Map<String, Rider> ridersMap,
    required Map<String, String> riderTeamMap,
    required Map<String, double> riderWPrimeMap,
    required Set<String> teamsWithLeaderInPeloton,
    double timeStepSeconds = 1.0,
  }) {
    final List<BreakawayRiderStatus> updatedRiders = [];
    int cooperativeCount = 0;

    for (final riderStatus in currentStatus.riderStatuses) {
      final String rId = riderStatus.riderId;
      final rider = ridersMap[rId];
      final teamId = riderTeamMap[rId] ?? '';
      final double wPrime = riderWPrimeMap[rId] ?? 20000.0;

      BreakawayRiderRole role = BreakawayRiderRole.cooperativeRelay;
      double pullRatio = 1.0;
      String motive = 'Równe zmiany (Relay)';

      // 1. Powód taktyczny: zespół kolarza ma lidera w peletonie (zakaz dawania zmian)
      if (teamsWithLeaderInPeloton.contains(teamId)) {
        role = BreakawayRiderRole.wheelsucker;
        pullRatio = 0.0;
        motive = 'Lider zespołu w peletonie – zakaz współpracy';
      }
      // 2. Powód fizjologiczny: odcięcie beztlenowe lub skrajne wyczerpanie
      else if (wPrime < 2000.0) {
        role = BreakawayRiderRole.wheelsucker;
        pullRatio = 0.15;
        motive = 'Wyczerpany fizycznie (puste W\') – wisi na rzęsach';
      }
      // 3. Cecha charakteru: niektórzy sprytni puncherzy żerują na innych
      else if (rider != null && rider.skills.raceIq > 85 && currentStatus.currentGapSeconds < 60.0) {
        // Gdy przewaga jest krucha, kalkulują
        if (riderStatus.turnsTaken > 8 && currentStatus.riderCount > 3) {
          role = BreakawayRiderRole.wheelsucker;
          pullRatio = 0.35;
          motive = 'Oszczędza siły na skok przed metą';
        }
      }

      if (role == BreakawayRiderRole.cooperativeRelay) {
        cooperativeCount++;
      }

      // Aktualizacja statystyk czasu na czele
      final double newSeconds = role == BreakawayRiderRole.cooperativeRelay
          ? riderStatus.secondsAtFront + (timeStepSeconds / math.max(1, currentStatus.riderCount))
          : riderStatus.secondsAtFront;

      updatedRiders.add(
        riderStatus.copyWith(
          role: role,
          pullContributionRatio: pullRatio,
          secondsAtFront: newSeconds,
          tacticalMotive: motive,
        ),
      );
    }

    // Wyliczenie wskaźnika współpracy [0.0 - 1.0]
    final int totalRiders = updatedRiders.length;
    double rawCooperation;
    if (totalRiders <= 1) {
      rawCooperation = 1.0;
    } else {
      // Każdy pasożyt (wheelsucker) obniża współpracę o 30-40%
      final double cooperativeFraction = cooperativeCount / totalRiders;
      rawCooperation = cooperativeFraction;
    }

    final double clampedCooperation = rawCooperation.clamp(0.20, 1.0);
    final bool isBroken = clampedCooperation < 0.65;

    // Jeśli współpraca siada, kolarze w ucieczce zaczynają skakać i atakować się nawzajem
    bool isUnderAttack = false;
    if (isBroken && totalRiders >= 3) {
      isUnderAttack = true;
    }

    return currentStatus.copyWith(
      riderStatuses: updatedRiders,
      cooperationScore: clampedCooperation,
      isUnderAttack: isUnderAttack,
    );
  }
}

