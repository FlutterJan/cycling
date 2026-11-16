// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';

/// Archetyp kolarza w kontekście formowania Grupetto (Autobusu) na etapach górskich.
enum GrupettoRiderArchetype {
  /// Czysty sprinter szukający przetrwania limitu czasu na górskich przełęczach.
  sprinter,

  /// Ciężki klasykowiec / specjalista od bruków i wiatru (wysoka masa, duża moc bezwzględna na płaskim).
  heavyClassics,

  /// Pomocnik (domestique) zużyty po wcześniejszej pracy dla lidera na płaskim lub pierwszej górze.
  domestique,

  /// Góral / faworyt GC (zazwyczaj nie odpada na pierwszej przełęczy, chyba że po kraksie lub chorobie).
  climberGc;

  String toJson() => name;

  static GrupettoRiderArchetype fromJson(String value) {
    return GrupettoRiderArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GrupettoRiderArchetype.domestique,
    );
  }

  String get labelPl {
    switch (this) {
      case GrupettoRiderArchetype.sprinter:
        return 'Sprinter';
      case GrupettoRiderArchetype.heavyClassics:
        return 'Ciężki klasykowiec';
      case GrupettoRiderArchetype.domestique:
        return 'Pomocnik';
      case GrupettoRiderArchetype.climberGc:
        return 'Góral / GC';
    }
  }
}

/// Faza formowania i jazdy Grupetto na etapie górskim.
enum GrupettoFormationState {
  /// Etap nie wymaga Autobusu lub nikt jeszcze nie odpadł na pierwszej przełęczy.
  notFormed,

  /// Kolarze odpadają na pierwszej przełęczy i łączą się w grupę pościgową.
  formingOnFirstPass,

  /// Grupetto uformowane, jedzie zwartym szykiem pod kontrolą Kapitana.
  activeAutobus,

  /// Rozwiązanie grupy na ostatnich kilometrach przed metą (np. walka o uniknięcie OTL).
  finalSurvivalPush;

  String toJson() => name;

  static GrupettoFormationState fromJson(String value) {
    return GrupettoFormationState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GrupettoFormationState.notFormed,
    );
  }

  String get labelPl {
    switch (this) {
      case GrupettoFormationState.notFormed:
        return 'Nieutworzone';
      case GrupettoFormationState.formingOnFirstPass:
        return 'Formowanie na 1. przełęczy';
      case GrupettoFormationState.activeAutobus:
        return 'Aktywny Autobus';
      case GrupettoFormationState.finalSurvivalPush:
        return 'Finałowa walka o limit';
    }
  }
}

/// Status bezpieczeństwa czasowego Grupetto względem limitu OTL (Hors Délais).
enum GrupettoSurvivalStatus {
  /// Grupa ma komfortowy zapas (> 5 minut poniżej limitu OTL).
  cruisingSafe,

  /// Tempo wyliczone przez Kapitana gwarantuje zmieszczenie się w OTL z zapasem ok. 3 minut.
  captainControlled,

  /// Zapas spadł poniżej 3 minut — Kapitan podkręca zmiany na czele.
  pushingForTimeCut,

  /// Zagrożenie eliminacją OTL (prognozowany czas przekracza limit lub zapas < 30 s).
  criticalOtlDanger;

  String toJson() => name;

  static GrupettoSurvivalStatus fromJson(String value) {
    return GrupettoSurvivalStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GrupettoSurvivalStatus.captainControlled,
    );
  }

  String get labelPl {
    switch (this) {
      case GrupettoSurvivalStatus.cruisingSafe:
        return 'Bezpieczny zapas';
      case GrupettoSurvivalStatus.captainControlled:
        return 'Kontrola Kapitana (+3m)';
      case GrupettoSurvivalStatus.pushingForTimeCut:
        return 'Pogoń za limitem OTL';
      case GrupettoSurvivalStatus.criticalOtlDanger:
        return 'ALARM OTL (Hors Délais)';
    }
  }

  Color get statusColor {
    switch (this) {
      case GrupettoSurvivalStatus.cruisingSafe:
        return AppColors.statusSuccess;
      case GrupettoSurvivalStatus.captainControlled:
        return AppColors.accentBlue;
      case GrupettoSurvivalStatus.pushingForTimeCut:
        return AppColors.amberWarning;
      case GrupettoSurvivalStatus.criticalOtlDanger:
        return AppColors.crimsonAlert;
    }
  }
}

/// Tryb taktyczny narzucony przez Kapitana Grupetto lub dyrektora sportowego.
enum GrupettoCaptainTacticMode {
  /// Standardowy reżim przetrwania: minimalne tempo gwarantujące zapas 3 minut (180 s) do OTL.
  exactThreeMinuteBuffer,

  /// Konserwatywny: głębsze oszczędzanie sił sprinterów (zapas 2 min 30 s przy niskim ryzyku).
  conserveSprinters,

  /// Zapobiegawczy: szybsza rotacja w dolinach dla większego bufora bezpieczeństwa (zapas 5 min).
  proactiveSafetyMargin;

  String toJson() => name;

  static GrupettoCaptainTacticMode fromJson(String value) {
    return GrupettoCaptainTacticMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GrupettoCaptainTacticMode.exactThreeMinuteBuffer,
    );
  }

  String get labelPl {
    switch (this) {
      case GrupettoCaptainTacticMode.exactThreeMinuteBuffer:
        return 'Reguła Kapitana (+3:00 OTL)';
      case GrupettoCaptainTacticMode.conserveSprinters:
        return 'Ochrona Sprinterów (+2:30)';
      case GrupettoCaptainTacticMode.proactiveSafetyMargin:
        return 'Bezpieczny Bufor (+5:00)';
    }
  }

  double get targetMarginSeconds {
    switch (this) {
      case GrupettoCaptainTacticMode.exactThreeMinuteBuffer:
        return 180.0;
      case GrupettoCaptainTacticMode.conserveSprinters:
        return 150.0;
      case GrupettoCaptainTacticMode.proactiveSafetyMargin:
        return 300.0;
    }
  }
}

/// Profil kolarza kandydującego lub jadącego w Grupetto.
class GrupettoRiderProfile {
  final String riderId;
  final String riderName;
  final String teamId;
  final GrupettoRiderArchetype archetype;
  final int ageYears;
  final int experienceYears;

  /// Inteligencja wyścigowa (1–100) kluczowa dla wyboru Kapitana Grupetto.
  final int raceIq;

  /// Umiejętność jazdy w górach (1–100).
  final int mountainSkill;

  /// Umiejętność jazdy na płaskim / wytrzymałość (1–100).
  final int flatSkill;

  /// Masa ciała kolarza [kg] (ciężsi kolarze > 74 kg odpadają wcześniej na stromych przełęczach).
  final double weightKg;

  /// FTP kolarza [W].
  final int ftpWatts;

  /// Aktualny poziom zmęczenia (0.0 = świeży, 1.0 = skrajnie wyczerpany).
  final double fatigueRatio;

  /// Czy kolarz odpadł już od głównego peletonu na trasie.
  final bool isDroppedFromPeloton;

  /// Czy kolarz należy do drużyny gracza.
  final bool isPlayerTeam;

  /// Czy kolarz wycofał się z wyścigu (DNF).
  final bool isDnf;

  const GrupettoRiderProfile({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.archetype,
    required this.ageYears,
    required this.experienceYears,
    required this.raceIq,
    required this.mountainSkill,
    required this.flatSkill,
    required this.weightKg,
    required this.ftpWatts,
    this.fatigueRatio = 0.25,
    this.isDroppedFromPeloton = false,
    this.isPlayerTeam = false,
    this.isDnf = false,
  });

  /// Wskaźnik W/kg przy FTP.
  double get ftpWattsPerKg => weightKg > 0.0 ? ftpWatts / weightKg : 0.0;

  /// Czy kolarz ma profil klasycznego pasażera Autobusu (sprinter lub ciężki klasykowiec).
  bool get isNaturalAutobusPassenger =>
      archetype == GrupettoRiderArchetype.sprinter ||
      archetype == GrupettoRiderArchetype.heavyClassics ||
      (weightKg >= 74.0 && mountainSkill <= 68);

  GrupettoRiderProfile copyWith({
    String? riderId,
    String? riderName,
    String? teamId,
    GrupettoRiderArchetype? archetype,
    int? ageYears,
    int? experienceYears,
    int? raceIq,
    int? mountainSkill,
    int? flatSkill,
    double? weightKg,
    int? ftpWatts,
    double? fatigueRatio,
    bool? isDroppedFromPeloton,
    bool? isPlayerTeam,
    bool? isDnf,
  }) {
    return GrupettoRiderProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamId: teamId ?? this.teamId,
      archetype: archetype ?? this.archetype,
      ageYears: ageYears ?? this.ageYears,
      experienceYears: experienceYears ?? this.experienceYears,
      raceIq: raceIq ?? this.raceIq,
      mountainSkill: mountainSkill ?? this.mountainSkill,
      flatSkill: flatSkill ?? this.flatSkill,
      weightKg: weightKg ?? this.weightKg,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      fatigueRatio: fatigueRatio ?? this.fatigueRatio,
      isDroppedFromPeloton: isDroppedFromPeloton ?? this.isDroppedFromPeloton,
      isPlayerTeam: isPlayerTeam ?? this.isPlayerTeam,
      isDnf: isDnf ?? this.isDnf,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'archetype': archetype.toJson(),
        'ageYears': ageYears,
        'experienceYears': experienceYears,
        'raceIq': raceIq,
        'mountainSkill': mountainSkill,
        'flatSkill': flatSkill,
        'weightKg': weightKg,
        'ftpWatts': ftpWatts,
        'fatigueRatio': fatigueRatio,
        'isDroppedFromPeloton': isDroppedFromPeloton,
        'isPlayerTeam': isPlayerTeam,
        'isDnf': isDnf,
      };

  factory GrupettoRiderProfile.fromJson(Map<String, dynamic> json) {
    return GrupettoRiderProfile(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      archetype: GrupettoRiderArchetype.fromJson(json['archetype'] as String),
      ageYears: (json['ageYears'] as num).toInt(),
      experienceYears: (json['experienceYears'] as num).toInt(),
      raceIq: (json['raceIq'] as num).toInt(),
      mountainSkill: (json['mountainSkill'] as num).toInt(),
      flatSkill: (json['flatSkill'] as num).toInt(),
      weightKg: (json['weightKg'] as num).toDouble(),
      ftpWatts: (json['ftpWatts'] as num).toInt(),
      fatigueRatio: (json['fatigueRatio'] as num?)?.toDouble() ?? 0.25,
      isDroppedFromPeloton: json['isDroppedFromPeloton'] as bool? ?? false,
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      isDnf: json['isDnf'] as bool? ?? false,
    );
  }
}

/// Wybrany Kapitan Grupetto zarządzający tempem, zmianami i dyscypliną w Autobusie.
class GrupettoCaptain {
  final String riderId;
  final String riderName;
  final String teamId;
  final int ageYears;
  final int experienceYears;
  final int raceIq;

  /// Złożony indeks autorytetu Kapitana (0.0 – 100.0).
  final double captaincyAuthorityScore;

  /// Krótki komunikat taktyczny Kapitana dla grupy.
  final String tacticalCallout;

  const GrupettoCaptain({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.ageYears,
    required this.experienceYears,
    required this.raceIq,
    required this.captaincyAuthorityScore,
    required this.tacticalCallout,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'ageYears': ageYears,
        'experienceYears': experienceYears,
        'raceIq': raceIq,
        'captaincyAuthorityScore': captaincyAuthorityScore,
        'tacticalCallout': tacticalCallout,
      };

  factory GrupettoCaptain.fromJson(Map<String, dynamic> json) {
    return GrupettoCaptain(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      ageYears: (json['ageYears'] as num).toInt(),
      experienceYears: (json['experienceYears'] as num).toInt(),
      raceIq: (json['raceIq'] as num).toInt(),
      captaincyAuthorityScore: (json['captaincyAuthorityScore'] as num).toDouble(),
      tacticalCallout: json['tacticalCallout'] as String,
    );
  }
}

/// Matematyczny plan tempa Grupetto wyliczony przez Kapitana.
class GrupettoPacePlan {
  /// Szacowany czas ukończenia etapu przez zwycięzcę [s].
  final double estimatedWinnerFinishTimeSeconds;

  /// Procent limitu czasu OTL wynikający z profilu i prędkości zwycięzcy [%].
  final double otlTimeCutPercent;

  /// Bezwzględny limit czasu OTL (Hors Délais) [s].
  final double otlLimitSeconds;

  /// Docelowy czas przyjazdu Grupetto (OTL - zapas bezpieczeństwa, domyślnie -180 s) [s].
  final double targetGrupettoFinishTimeSeconds;

  /// Założony bufor bezpieczeństwa względem OTL [s] (domyślnie 180.0 s = 3 minuty).
  final double safetyMarginSeconds;

  /// Pozostały budżet czasu dla Grupetto do docelowego przyjazdu [s].
  final double remainingTimeBudgetSeconds;

  /// Pozostały dystans dla Grupetto do linii mety [km].
  final double remainingDistanceKm;

  /// Minimalna średnia prędkość na pozostałym dystansie gwarantująca zmieszczenie się w celu [km/h].
  final double requiredMinAverageSpeedKmh;

  /// Docelowa intensywność wysiłku na czele zmian [% FTP, np. 0.72 = 72% FTP].
  final double frontPullFtpFraction;

  /// Oszczędność aerodynamiczna kolarzy schowanych w środku 40-osobowego Autobusu [%].
  final double draftPowerSavingsPercent;

  /// Docelowe VAM na podjazdach wyliczone z budżetu czasu [m/h].
  final double targetClimbVamMetersPerHour;

  /// Prognozowany zapas czasowy przed limitem OTL przy utrzymaniu bieżącego tempa [s].
  final double projectedOtlMarginSeconds;

  const GrupettoPacePlan({
    required this.estimatedWinnerFinishTimeSeconds,
    required this.otlTimeCutPercent,
    required this.otlLimitSeconds,
    required this.targetGrupettoFinishTimeSeconds,
    required this.safetyMarginSeconds,
    required this.remainingTimeBudgetSeconds,
    required this.remainingDistanceKm,
    required this.requiredMinAverageSpeedKmh,
    required this.frontPullFtpFraction,
    required this.draftPowerSavingsPercent,
    required this.targetClimbVamMetersPerHour,
    required this.projectedOtlMarginSeconds,
  });

  Map<String, dynamic> toJson() => {
        'estimatedWinnerFinishTimeSeconds': estimatedWinnerFinishTimeSeconds,
        'otlTimeCutPercent': otlTimeCutPercent,
        'otlLimitSeconds': otlLimitSeconds,
        'targetGrupettoFinishTimeSeconds': targetGrupettoFinishTimeSeconds,
        'safetyMarginSeconds': safetyMarginSeconds,
        'remainingTimeBudgetSeconds': remainingTimeBudgetSeconds,
        'remainingDistanceKm': remainingDistanceKm,
        'requiredMinAverageSpeedKmh': requiredMinAverageSpeedKmh,
        'frontPullFtpFraction': frontPullFtpFraction,
        'draftPowerSavingsPercent': draftPowerSavingsPercent,
        'targetClimbVamMetersPerHour': targetClimbVamMetersPerHour,
        'projectedOtlMarginSeconds': projectedOtlMarginSeconds,
      };

  factory GrupettoPacePlan.fromJson(Map<String, dynamic> json) {
    return GrupettoPacePlan(
      estimatedWinnerFinishTimeSeconds:
          (json['estimatedWinnerFinishTimeSeconds'] as num).toDouble(),
      otlTimeCutPercent: (json['otlTimeCutPercent'] as num).toDouble(),
      otlLimitSeconds: (json['otlLimitSeconds'] as num).toDouble(),
      targetGrupettoFinishTimeSeconds:
          (json['targetGrupettoFinishTimeSeconds'] as num).toDouble(),
      safetyMarginSeconds: (json['safetyMarginSeconds'] as num).toDouble(),
      remainingTimeBudgetSeconds:
          (json['remainingTimeBudgetSeconds'] as num).toDouble(),
      remainingDistanceKm: (json['remainingDistanceKm'] as num).toDouble(),
      requiredMinAverageSpeedKmh:
          (json['requiredMinAverageSpeedKmh'] as num).toDouble(),
      frontPullFtpFraction: (json['frontPullFtpFraction'] as num).toDouble(),
      draftPowerSavingsPercent:
          (json['draftPowerSavingsPercent'] as num).toDouble(),
      targetClimbVamMetersPerHour:
          (json['targetClimbVamMetersPerHour'] as num).toDouble(),
      projectedOtlMarginSeconds:
          (json['projectedOtlMarginSeconds'] as num).toDouble(),
    );
  }
}

/// Dane wejściowe dla oceny i aktualizacji stanu Grupetto w danej sekundzie etapu.
class GrupettoAutobusInput {
  final RaceStage stage;

  /// Aktualny czas trwania etapu od startu ostrego [s].
  final double elapsedStageTimeSeconds;

  /// Kilometraż aktualnego lidera wyścigu [km].
  final double leaderDistanceKm;

  /// Prędkość aktualnego lidera wyścigu [km/h].
  final double leaderCurrentSpeedKmh;

  /// Kilometraż Grupetto na trasie [km] (jeśli jeszcze nie powstało, kilometraż pierwszego odpanego).
  final double grupettoDistanceKm;

  /// Aktualna prędkość Grupetto [km/h].
  final double grupettoCurrentSpeedKmh;

  /// Lista wszystkich kolarzy rozpatrywanych do sformowania lub zasilenia Grupetto.
  final List<GrupettoRiderProfile> riderPool;

  /// Docelowy rozmiar Autobusu (domyślnie 40 kolarzy na etapach górskich).
  final int targetGroupSize;

  /// Tryb taktyczny Kapitana.
  final GrupettoCaptainTacticMode tacticMode;

  /// Opcjonalny ID kolarza, który ma pełnić funkcję lidera zmian gracza w Autobusie.
  final String? forcedPlayerPullerId;

  const GrupettoAutobusInput({
    required this.stage,
    required this.elapsedStageTimeSeconds,
    required this.leaderDistanceKm,
    required this.leaderCurrentSpeedKmh,
    required this.grupettoDistanceKm,
    required this.grupettoCurrentSpeedKmh,
    required this.riderPool,
    this.targetGroupSize = 40,
    this.tacticMode = GrupettoCaptainTacticMode.exactThreeMinuteBuffer,
    this.forcedPlayerPullerId,
  });
}

/// Kompletny wynik symulacji i decyzji AI Grupetto (Autobusu).
class GrupettoEvaluationResult {
  final GrupettoFormationState formationState;
  final GrupettoSurvivalStatus survivalStatus;
  final GrupettoCaptain? captain;
  final GrupettoPacePlan pacePlan;

  /// Kolarze jadący aktualnie w Grupetto (posortowani wg roli: Kapitan, pracujący, sprinterzy w środku).
  final List<GrupettoRiderProfile> members;

  /// ID kolarzy aktualnie dających zmiany na czele Autobusu.
  final List<String> activePullerRiderIds;

  /// ID kolarzy chronionych w głębokim drafcie (sprinterzy / wyczerpani).
  final List<String> protectedDraftRiderIds;

  /// Indeks aktualnego segmentu trasy, na którym znajduje się Grupetto.
  final int currentSegmentIndex;

  /// Liczba sprinterów w grupie.
  final int sprinterCount;

  /// Liczba ciężkich klasykowców w grupie.
  final int heavyClassicsCount;

  /// Liczba pomocników i pozostałych kolarzy w grupie.
  final int domestiqueCount;

  /// Komunikat do dziennika / radia wyścigowego.
  final String radioMessage;

  const GrupettoEvaluationResult({
    required this.formationState,
    required this.survivalStatus,
    required this.captain,
    required this.pacePlan,
    required this.members,
    required this.activePullerRiderIds,
    required this.protectedDraftRiderIds,
    required this.currentSegmentIndex,
    required this.sprinterCount,
    required this.heavyClassicsCount,
    required this.domestiqueCount,
    required this.radioMessage,
  });

  int get groupSize => members.length;
}

/// Silnik AI autentycznego **Grupetto (Autobusu)** na etapach górskich.
///
/// Odtwarza mechanikę znaną z Wielkich Tourów:
/// 1. Sprinterzy i ciężcy klasykowcy odpadający na pierwszej przełęczy łączą się w dużą,
///    zazwyczaj ~40-osobową grupę pościgową.
/// 2. Grupa wybiera najbardziej doświadczonego "Kapitana Grupetto" (wysoki wiek, staż, RaceIQ).
/// 3. Kapitan matematycznie wylicza minimalne tempo gwarantujące zmieszczenie się w limicie OTL
///    (Hors Délais) z zapasem dokładnie 3 minut (180 s), oszczędzając sprinterów w drafcie.
class GrupettoAutobusSurvivalAi {
  GrupettoAutobusSurvivalAi._();

  /// Domyślny zapas czasowy Kapitana Grupetto względem limitu OTL: 3 minuty (180 sekund).
  static const double defaultSafetyMarginSeconds = 180.0;

  /// Domyślny docelowy rozmiar Autobusu w Wielkich Tourach.
  static const int defaultTargetAutobusSize = 40;

  /// Sprawdza, czy dany etap kwalifikuje się do formowania górskiego Grupetto.
  static bool isMountainAutobusStage(RaceStage stage) {
    if (stage.isTimeTrial) return false;
    if (stage.stageType == StageType.highMountain ||
        stage.stageType == StageType.summitFinish) {
      return true;
    }
    // Etap pagórkowaty o wysokim przewyższeniu (> 2200 m) również może wywołać Grupetto.
    return stage.totalElevationGainM >= 2200.0;
  }

  /// Identyfikuje indeks segmentu odpowiadającego pierwszej istotnej przełęczy na etapie.
  static int findFirstMajorClimbSegmentIndex(RaceStage stage) {
    for (int i = 0; i < stage.segments.length; i++) {
      final seg = stage.segments[i];
      final bool hasClimbCategory = seg.climbCategory != null;
      if (hasClimbCategory || (seg.isClimb && seg.gradientPercent >= 4.0)) {
        return i;
      }
    }
    return stage.segments.isNotEmpty ? 0 : -1;
  }

  /// Znajduje indeks segmentu na trasie dla podanego kilometrażu [km].
  static int findSegmentIndexAtDistance(RaceStage stage, double distanceKm) {
    if (stage.segments.isEmpty) return -1;
    final double clampedKm = distanceKm.clamp(0.0, stage.totalDistanceKm);
    for (int i = 0; i < stage.segments.length; i++) {
      final seg = stage.segments[i];
      if (clampedKm >= seg.startKm && clampedKm <= seg.endKm) {
        return i;
      }
    }
    return stage.segments.length - 1;
  }

  /// Główna metoda ewaluacji stanu Grupetto, wyboru Kapitana i wyliczenia tempa przetrwania OTL.
  static GrupettoEvaluationResult evaluateAutobus(GrupettoAutobusInput input) {
    final RaceStage stage = input.stage;
    final int currentSegIdx =
        findSegmentIndexAtDistance(stage, input.grupettoDistanceKm);
    final int firstClimbIdx = findFirstMajorClimbSegmentIndex(stage);

    final bool mountainStage = isMountainAutobusStage(stage);
    final bool reachedFirstPass =
        firstClimbIdx >= 0 && currentSegIdx >= firstClimbIdx;

    // 1. Zbieramy kwalifikujących się kolarzy, którzy odpadli na trasie (z wyłączeniem DNF)
    final List<GrupettoRiderProfile> eligibleDropped = input.riderPool
        .where((r) => !r.isDnf && r.isDroppedFromPeloton)
        .toList();

    // Sortujemy tak, aby sprinterzy, ciężcy klasykowcy i zużyci pomocnicy trafiali do Autobusu
    eligibleDropped.sort((a, b) {
      final int priorityA = _autobusJoinPriority(a);
      final int priorityB = _autobusJoinPriority(b);
      if (priorityA != priorityB) return priorityB.compareTo(priorityA);
      return a.mountainSkill.compareTo(b.mountainSkill);
    });

    final int maxSize = math.max(1, input.targetGroupSize);
    final List<GrupettoRiderProfile> members =
        eligibleDropped.take(maxSize).toList();

    // 2. Określamy fazę formowania Grupetto
    final GrupettoFormationState formationState;
    if (!mountainStage || members.isEmpty) {
      formationState = GrupettoFormationState.notFormed;
    } else if (!reachedFirstPass || members.length < math.min(12, maxSize)) {
      formationState = GrupettoFormationState.formingOnFirstPass;
    } else if (stage.totalDistanceKm - input.grupettoDistanceKm <= 25.0) {
      formationState = GrupettoFormationState.finalSurvivalPush;
    } else {
      formationState = GrupettoFormationState.activeAutobus;
    }

    // 3. Wyliczamy matematyczny plan tempa dla limitu czasu OTL z zapasem 3 minut
    final GrupettoPacePlan pacePlan = calculateSurvivalPacePlan(
      stage: stage,
      elapsedStageTimeSeconds: input.elapsedStageTimeSeconds,
      leaderDistanceKm: input.leaderDistanceKm,
      leaderCurrentSpeedKmh: input.leaderCurrentSpeedKmh,
      grupettoDistanceKm: input.grupettoDistanceKm,
      grupettoCurrentSpeedKmh: input.grupettoCurrentSpeedKmh,
      groupSize: members.length,
      currentSegmentIndex: currentSegIdx,
      safetyMarginSeconds: input.tacticMode.targetMarginSeconds,
    );

    // 4. Określamy status bezpieczeństwa OTL
    final GrupettoSurvivalStatus survivalStatus = _resolveSurvivalStatus(
      pacePlan: pacePlan,
      safetyMarginSeconds: input.tacticMode.targetMarginSeconds,
    );

    // 5. Wybieramy doświadczonego Kapitana Grupetto
    final GrupettoCaptain? captain = members.isEmpty
        ? null
        : selectGrupettoCaptain(
            members: members,
            survivalStatus: survivalStatus,
            pacePlan: pacePlan,
          );

    // 6. Przydzielamy role w zmianach na czele oraz w osłoniętym drafcie
    final List<String> activePullers = <String>[];
    final List<String> protectedDraft = <String>[];

    if (members.isNotEmpty) {
      final int desiredPullers = math.min(
        members.length,
        survivalStatus == GrupettoSurvivalStatus.criticalOtlDanger
            ? 8
            : survivalStatus == GrupettoSurvivalStatus.pushingForTimeCut
                ? 6
                : 4,
      );

      final List<GrupettoRiderProfile> pullCandidates =
          List<GrupettoRiderProfile>.from(members)
            ..sort((a, b) {
              if (input.forcedPlayerPullerId != null) {
                if (a.riderId == input.forcedPlayerPullerId) return -1;
                if (b.riderId == input.forcedPlayerPullerId) return 1;
              }
              return _pullSuitabilityScore(b).compareTo(_pullSuitabilityScore(a));
            });

      for (final rider in pullCandidates) {
        if (activePullers.length < desiredPullers &&
            rider.archetype != GrupettoRiderArchetype.sprinter) {
          activePullers.add(rider.riderId);
        } else {
          protectedDraft.add(rider.riderId);
        }
      }

      // Jeśli cała grupa składa się ze sprinterów, najmocniejsi z nich dają zmiany
      if (activePullers.isEmpty) {
        for (int i = 0; i < desiredPullers && i < pullCandidates.length; i++) {
          final id = pullCandidates[i].riderId;
          activePullers.add(id);
          protectedDraft.remove(id);
        }
      }
    }

    int sprinters = 0;
    int classics = 0;
    int domestiques = 0;
    for (final m in members) {
      switch (m.archetype) {
        case GrupettoRiderArchetype.sprinter:
          sprinters++;
          break;
        case GrupettoRiderArchetype.heavyClassics:
          classics++;
          break;
        case GrupettoRiderArchetype.domestique:
        case GrupettoRiderArchetype.climberGc:
          domestiques++;
          break;
      }
    }

    final String radioMessage = _buildRadioMessage(
      formationState: formationState,
      survivalStatus: survivalStatus,
      captain: captain,
      pacePlan: pacePlan,
      groupSize: members.length,
    );

    return GrupettoEvaluationResult(
      formationState: formationState,
      survivalStatus: survivalStatus,
      captain: captain,
      pacePlan: pacePlan,
      members: List<GrupettoRiderProfile>.unmodifiable(members),
      activePullerRiderIds: List<String>.unmodifiable(activePullers),
      protectedDraftRiderIds: List<String>.unmodifiable(protectedDraft),
      currentSegmentIndex: currentSegIdx,
      sprinterCount: sprinters,
      heavyClassicsCount: classics,
      domestiqueCount: domestiques,
      radioMessage: radioMessage,
    );
  }

  /// Wybiera najbardziej doświadczonego Kapitana Grupetto spośród członków grupy.
  static GrupettoCaptain selectGrupettoCaptain({
    required List<GrupettoRiderProfile> members,
    required GrupettoSurvivalStatus survivalStatus,
    required GrupettoPacePlan pacePlan,
  }) {
    GrupettoRiderProfile best = members.first;
    double bestScore = -1.0;

    for (final rider in members) {
      final double score = computeCaptaincyAuthorityScore(rider);
      if (score > bestScore) {
        bestScore = score;
        best = rider;
      }
    }

    final String callout;
    switch (survivalStatus) {
      case GrupettoSurvivalStatus.cruisingSafe:
        callout =
            'Spokojne koło, sprinterzy do środka. Mamy ponad ${(pacePlan.projectedOtlMarginSeconds / 60).toStringAsFixed(1)} min zapasu do OTL.';
        break;
      case GrupettoSurvivalStatus.captainControlled:
        callout =
            'Trzymamy równe ${pacePlan.requiredMinAverageSpeedKmh.toStringAsFixed(1)} km/h. Zapas 3:00 do limitu OTL pod pełną kontrolą.';
        break;
      case GrupettoSurvivalStatus.pushingForTimeCut:
        callout =
            'Uwaga! Zapas spada poniżej 3 min — świeże zmiany na przód, celujemy w ${pacePlan.requiredMinAverageSpeedKmh.toStringAsFixed(1)} km/h!';
        break;
      case GrupettoSurvivalStatus.criticalOtlDanger:
        callout =
            'ALARM OTL! Wszyscy na zmianę! Musimy utrzymać min. ${pacePlan.requiredMinAverageSpeedKmh.toStringAsFixed(1)} km/h do mety!';
        break;
    }

    return GrupettoCaptain(
      riderId: best.riderId,
      riderName: best.riderName,
      teamId: best.teamId,
      ageYears: best.ageYears,
      experienceYears: best.experienceYears,
      raceIq: best.raceIq,
      captaincyAuthorityScore: bestScore,
      tacticalCallout: callout,
    );
  }

  /// Oblicza autorytet kolarza do objęcia roli Kapitana Grupetto (0.0 – 100.0).
  static double computeCaptaincyAuthorityScore(GrupettoRiderProfile rider) {
    final double expNorm = (rider.experienceYears / 16.0).clamp(0.0, 1.0);
    final double ageBonus = rider.ageYears >= 31 ? 1.0 : (rider.ageYears / 31.0);
    final double iqNorm = (rider.raceIq / 100.0).clamp(0.0, 1.0);
    final double flatNorm = (rider.flatSkill / 100.0).clamp(0.0, 1.0);
    final double archetypeBonus =
        rider.archetype == GrupettoRiderArchetype.domestique ||
                rider.archetype == GrupettoRiderArchetype.heavyClassics
            ? 0.08
            : 0.0;

    final double raw = (iqNorm * 0.42 +
            expNorm * 0.30 +
            ageBonus * 0.15 +
            flatNorm * 0.13 +
            archetypeBonus) *
        100.0;
    return raw.clamp(0.0, 100.0);
  }

  /// Matematycznie wylicza minimalne tempo gwarantujące zmieszczenie się w OTL z zapasem 3 minut.
  static GrupettoPacePlan calculateSurvivalPacePlan({
    required RaceStage stage,
    required double elapsedStageTimeSeconds,
    required double leaderDistanceKm,
    required double leaderCurrentSpeedKmh,
    required double grupettoDistanceKm,
    required double grupettoCurrentSpeedKmh,
    required int groupSize,
    required int currentSegmentIndex,
    double safetyMarginSeconds = defaultSafetyMarginSeconds,
  }) {
    final double totalDistKm = math.max(1.0, stage.totalDistanceKm);
    final double clampedLeaderKm = leaderDistanceKm.clamp(0.0, totalDistKm);
    final double clampedGrupettoKm = grupettoDistanceKm.clamp(0.0, totalDistKm);

    final double safeLeaderSpeedKmh = math.max(18.0, leaderCurrentSpeedKmh);
    final double remainingLeaderKm = math.max(0.0, totalDistKm - clampedLeaderKm);
    final double remainingLeaderTimeSeconds =
        (remainingLeaderKm / safeLeaderSpeedKmh) * 3600.0;
    final double estimatedWinnerFinishTimeSeconds = math.max(
      1.0,
      elapsedStageTimeSeconds + remainingLeaderTimeSeconds,
    );

    final double otlPercent = calculateOtlTimeCutPercent(
      stage: stage,
      estimatedWinnerFinishTimeSeconds: estimatedWinnerFinishTimeSeconds,
    );

    final double otlLimitSeconds =
        estimatedWinnerFinishTimeSeconds * (1.0 + otlPercent / 100.0);
    final double targetFinishTimeSeconds =
        math.max(1.0, otlLimitSeconds - safetyMarginSeconds);

    final double remainingDistanceKm =
        math.max(0.0, totalDistKm - clampedGrupettoKm);
    final double remainingBudgetSeconds =
        targetFinishTimeSeconds - elapsedStageTimeSeconds;

    double requiredMinAvgSpeedKmh;
    if (remainingDistanceKm <= 0.0) {
      requiredMinAvgSpeedKmh = 0.0;
    } else if (remainingBudgetSeconds <= 1.0) {
      // Budżet czasu niemal wyczerpany — wymagana maksymalna pogoń.
      requiredMinAvgSpeedKmh = 52.0;
    } else {
      requiredMinAvgSpeedKmh =
          ((remainingDistanceKm / remainingBudgetSeconds) * 3600.0)
              .clamp(12.0, 52.0);
    }

    // Prognozowany czas przyjazdu Grupetto przy obecnej prędkości
    final double safeCurrentSpeedKmh = math.max(12.0, grupettoCurrentSpeedKmh);
    final double projectedRemainingSeconds = remainingDistanceKm > 0.0
        ? (remainingDistanceKm / safeCurrentSpeedKmh) * 3600.0
        : 0.0;
    final double projectedFinishTimeSeconds =
        elapsedStageTimeSeconds + projectedRemainingSeconds;
    final double projectedOtlMarginSeconds =
        otlLimitSeconds - projectedFinishTimeSeconds;

    // Ocena intensywności zmian na czele (% FTP) w zależności od wymaganej prędkości
    final double speedPressureRatio =
        (requiredMinAvgSpeedKmh / math.max(20.0, safeCurrentSpeedKmh))
            .clamp(0.75, 1.35);

    double baseFrontFtp = 0.72;
    if (currentSegmentIndex >= 0 && currentSegmentIndex < stage.segments.length) {
      final seg = stage.segments[currentSegmentIndex];
      if (seg.isClimb) {
        baseFrontFtp = 0.76;
      } else if (seg.isDescent) {
        baseFrontFtp = 0.55;
      }
    }
    final double frontPullFtpFraction =
        (baseFrontFtp * speedPressureRatio).clamp(0.55, 0.94);

    // Oszczędność aerodynamiczna w 40-osobowym Autobusie (do ~33% przy pełnej grupie)
    final double draftFactor = (groupSize / defaultTargetAutobusSize).clamp(0.0, 1.0);
    final double draftPowerSavingsPercent = (12.0 + 21.0 * draftFactor).clamp(12.0, 33.0);

    // Docelowe VAM na podjazdach wyliczone proporcjonalnie do wymaganego tempa
    final double targetVam = (980.0 * speedPressureRatio).clamp(850.0, 1420.0);

    return GrupettoPacePlan(
      estimatedWinnerFinishTimeSeconds: estimatedWinnerFinishTimeSeconds,
      otlTimeCutPercent: otlPercent,
      otlLimitSeconds: otlLimitSeconds,
      targetGrupettoFinishTimeSeconds: targetFinishTimeSeconds,
      safetyMarginSeconds: safetyMarginSeconds,
      remainingTimeBudgetSeconds: remainingBudgetSeconds,
      remainingDistanceKm: remainingDistanceKm,
      requiredMinAverageSpeedKmh: requiredMinAvgSpeedKmh,
      frontPullFtpFraction: frontPullFtpFraction,
      draftPowerSavingsPercent: draftPowerSavingsPercent,
      targetClimbVamMetersPerHour: targetVam,
      projectedOtlMarginSeconds: projectedOtlMarginSeconds,
    );
  }

  /// Wylicza procent limitu czasu (Time Cut / OTL) zgodnie z tabelą UCI i `StageResultsCalculator`.
  static double calculateOtlTimeCutPercent({
    required RaceStage stage,
    required double estimatedWinnerFinishTimeSeconds,
  }) {
    if (estimatedWinnerFinishTimeSeconds <= 0.0) return 12.0;
    final double winnerSpeedKmh =
        stage.totalDistanceKm / (estimatedWinnerFinishTimeSeconds / 3600.0);

    switch (stage.stageType) {
      case StageType.flat:
        if (winnerSpeedKmh > 48.0) return 11.0;
        if (winnerSpeedKmh > 44.0) return 9.0;
        return 6.0;
      case StageType.cobbleClassic:
      case StageType.hilly:
        if (winnerSpeedKmh > 42.0) return 14.0;
        if (winnerSpeedKmh > 38.0) return 12.0;
        return 10.0;
      case StageType.highMountain:
      case StageType.summitFinish:
        if (winnerSpeedKmh > 38.0) return 18.0;
        if (winnerSpeedKmh > 34.0) return 16.0;
        return 13.0;
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        return 25.0;
    }
  }

  static GrupettoSurvivalStatus _resolveSurvivalStatus({
    required GrupettoPacePlan pacePlan,
    required double safetyMarginSeconds,
  }) {
    final double margin = pacePlan.projectedOtlMarginSeconds;
    if (margin < 30.0) {
      return GrupettoSurvivalStatus.criticalOtlDanger;
    }
    if (margin < safetyMarginSeconds - 15.0) {
      return GrupettoSurvivalStatus.pushingForTimeCut;
    }
    if (margin <= safetyMarginSeconds + 120.0) {
      return GrupettoSurvivalStatus.captainControlled;
    }
    return GrupettoSurvivalStatus.cruisingSafe;
  }

  static int _autobusJoinPriority(GrupettoRiderProfile rider) {
    switch (rider.archetype) {
      case GrupettoRiderArchetype.sprinter:
        return 4;
      case GrupettoRiderArchetype.heavyClassics:
        return 3;
      case GrupettoRiderArchetype.domestique:
        return 2;
      case GrupettoRiderArchetype.climberGc:
        return 1;
    }
  }

  static double _pullSuitabilityScore(GrupettoRiderProfile rider) {
    final double freshness = (1.0 - rider.fatigueRatio).clamp(0.0, 1.0);
    final double roleWeight =
        rider.archetype == GrupettoRiderArchetype.domestique ||
                rider.archetype == GrupettoRiderArchetype.heavyClassics
            ? 1.15
            : 0.75;
    return (rider.flatSkill * 0.6 + rider.ftpWatts * 0.08) *
        freshness *
        roleWeight;
  }

  static String _buildRadioMessage({
    required GrupettoFormationState formationState,
    required GrupettoSurvivalStatus survivalStatus,
    required GrupettoCaptain? captain,
    required GrupettoPacePlan pacePlan,
    required int groupSize,
  }) {
    if (formationState == GrupettoFormationState.notFormed || captain == null) {
      return 'Brak uformowanego Grupetto na tym etapie.';
    }
    final String marginStr =
        _formatSignedDuration(pacePlan.projectedOtlMarginSeconds);
    return '[Autobus $groupSize kol. • Kpt. ${captain.riderName}] '
        'Cel: ${pacePlan.requiredMinAverageSpeedKmh.toStringAsFixed(1)} km/h '
        '(${(pacePlan.frontPullFtpFraction * 100).round()}% FTP na zmianach) | '
        'Prognozowany zapas OTL: $marginStr (${survivalStatus.labelPl}).';
  }

  static String _formatSignedDuration(double seconds) {
    final bool negative = seconds < 0;
    final int absSec = seconds.abs().round();
    final int mins = absSec ~/ 60;
    final int secs = absSec % 60;
    final String sign = negative ? '-' : '+';
    return '$sign${mins}m ${secs.toString().padLeft(2, '0')}s';
  }
}

/// Produkcyjny panel taktyczny Grupetto (Autobusu) zgodny z systemem projektowym AppColors & Inter.
class GrupettoAutobusSurvivalPanel extends StatefulWidget {
  final GrupettoEvaluationResult evaluation;
  final GrupettoCaptainTacticMode selectedTacticMode;
  final ValueChanged<GrupettoCaptainTacticMode>? onTacticModeChanged;
  final VoidCallback? onTogglePlayerPull;
  final bool isPlayerPulling;
  final bool canPlayerPull;

  const GrupettoAutobusSurvivalPanel({
    super.key,
    required this.evaluation,
    required this.selectedTacticMode,
    this.onTacticModeChanged,
    this.onTogglePlayerPull,
    this.isPlayerPulling = false,
    this.canPlayerPull = true,
  });

  @override
  State<GrupettoAutobusSurvivalPanel> createState() =>
      _GrupettoAutobusSurvivalPanelState();
}

class _GrupettoAutobusSurvivalPanelState
    extends State<GrupettoAutobusSurvivalPanel> {
  GrupettoCaptainTacticMode? _hoveredMode;
  GrupettoCaptainTacticMode? _focusedMode;
  bool _isPullBtnHovered = false;
  bool _isPullBtnFocused = false;
  bool _isPullBtnPressed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 520;
        final bool isDesktopWide = constraints.maxWidth >= 1000;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 14),
              if (isDesktopWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildCaptainAndMetrics(isCompact)),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _buildTacticAndComposition(isCompact)),
                  ],
                )
              else ...[
                _buildCaptainAndMetrics(isCompact),
                const SizedBox(height: 14),
                _buildTacticAndComposition(isCompact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final status = widget.evaluation.survivalStatus;
    final formation = widget.evaluation.formationState;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GRUPETTO • AUTOBUS (${widget.evaluation.groupSize} kol.)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    formation.labelPl,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: status.statusColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: status.statusColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            status.labelPl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptainAndMetrics(bool isCompact) {
    final captain = widget.evaluation.captain;
    final plan = widget.evaluation.pacePlan;

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
            children: [
              const Icon(Icons.military_tech_rounded,
                  color: AppColors.goldAccent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  captain != null
                      ? 'Kapitan: ${captain.riderName} (${captain.ageYears} l., IQ ${captain.raceIq})'
                      : 'Kapitan: Oczekiwanie na sformowanie grupy',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (captain != null) ...[
            const SizedBox(height: 6),
            Text(
              '„${captain.tacticalCallout}”',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metricTile(
                label: 'Min. tempo OTL',
                value:
                    '${plan.requiredMinAverageSpeedKmh.toStringAsFixed(1)} km/h',
                accent: AppColors.cyanAccent,
              ),
              _metricTile(
                label: 'Zapas do OTL',
                value: GrupettoAutobusSurvivalAi._formatSignedDuration(
                    plan.projectedOtlMarginSeconds),
                accent: widget.evaluation.survivalStatus.statusColor,
              ),
              _metricTile(
                label: 'Zmiany na czele',
                value: '${(plan.frontPullFtpFraction * 100).round()}% FTP',
                accent: AppColors.amberWarning,
              ),
              _metricTile(
                label: 'Oszczędność draftu',
                value: '-${plan.draftPowerSavingsPercent.round()}% W',
                accent: AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticAndComposition(bool isCompact) {
    final eval = widget.evaluation;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Strategia Kapitana Grupetto',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GrupettoCaptainTacticMode.values.map((mode) {
              final bool isSelected = widget.selectedTacticMode == mode;
              final bool isHovered = _hoveredMode == mode;
              final bool isFocused = _focusedMode == mode;
              final bool isEnabled = widget.onTacticModeChanged != null;

              return FocusableActionDetector(
                enabled: isEnabled,
                onShowHoverHighlight: (hovering) {
                  setState(() => _hoveredMode = hovering ? mode : null);
                },
                onShowFocusHighlight: (focused) {
                  setState(() => _focusedMode = focused ? mode : null);
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: isEnabled
                      ? () => widget.onTacticModeChanged?.call(mode)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: !isEnabled
                          ? AppColors.background.withValues(alpha: 0.45)
                          : isSelected
                              ? AppColors.primaryAccent
                              : isHovered
                                  ? AppColors.surface
                                  : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFocused
                            ? AppColors.goldAccent
                            : isSelected
                                ? AppColors.goldAccent.withValues(alpha: 0.8)
                                : const Color(0xFF2A2F3D),
                        width: isFocused ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      mode.labelPl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Skład: ${eval.sprinterCount} sprinterów • '
            '${eval.heavyClassicsCount} klasykowców • '
            '${eval.domestiqueCount} pomocników',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _buildPullActionButton(),
        ],
      ),
    );
  }

  Widget _buildPullActionButton() {
    final bool isEnabled =
        widget.canPlayerPull && widget.onTogglePlayerPull != null;
    final bool active = widget.isPlayerPulling;

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowHoverHighlight: (v) => setState(() => _isPullBtnHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isPullBtnFocused = v),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPullBtnPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPullBtnPressed = false) : null,
        onTapCancel:
            isEnabled ? () => setState(() => _isPullBtnPressed = false) : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isEnabled ? widget.onTogglePlayerPull : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: !isEnabled
                  ? AppColors.background.withValues(alpha: 0.4)
                  : _isPullBtnPressed
                      ? AppColors.goldAccent.withValues(alpha: 0.28)
                      : active
                          ? AppColors.goldAccent.withValues(alpha: 0.18)
                          : _isPullBtnHovered
                              ? AppColors.primaryAccent.withValues(alpha: 0.35)
                              : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isPullBtnFocused
                    ? AppColors.cyanAccent
                    : active
                        ? AppColors.goldAccent
                        : const Color(0xFF2A2F3D),
                width: _isPullBtnFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active
                      ? Icons.shield_rounded
                      : Icons.bolt_rounded,
                  size: 16,
                  color: !isEnabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : active
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    active
                        ? 'Twój kolarz pracuje na czele Autobusu'
                        : 'Wyślij pomocnika na zmianę w Grupetto',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: !isEnabled
                          ? AppColors.textSecondary.withValues(alpha: 0.45)
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
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
