// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../../models/career/staff_member.dart';
import '../../models/rider/rider.dart';

/// Miesiąc zimowego okresu przygotowawczego (Off-Season & Winter Base).
enum WinterMonth {
  november,
  december;

  String get displayName {
    switch (this) {
      case WinterMonth.november:
        return 'Listopad (Adaptacja Anatomiczna & Roztrenowanie)';
      case WinterMonth.december:
        return 'Grudzień (Siła Maksymalna & Testy Przedzgrupowaniowe)';
    }
  }

  String get phaseName {
    switch (this) {
      case WinterMonth.november:
        return 'Faza I: Roztrenowanie, Cross-Training & Wzorce Ruchowe';
      case WinterMonth.december:
        return 'Faza II: Siła Maksymalna (1RM), Moc 5s-1m & Testy Wydolnościowe';
    }
  }

  String toJson() => name;

  static WinterMonth fromJson(String value) {
    return WinterMonth.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WinterMonth.november,
    );
  }
}

/// Kolarskie ćwiczenia siłowe w okresie zimowym (Off-Season Gym Exercises).
enum GymExerciseType {
  /// Przysiady bułgarskie (Bulgarian Split Squats)
  /// Praca jednostronna (unilateral), wyrównanie dysbalansu lewa/prawa noga,
  /// stabilizacja miednicy i pasma biodrowo-piszczelowego bez obciążania osiowego kręgosłupa.
  bulgarianSplitSquats,

  /// Rumuński martwy ciąg (Romanian Deadlift - RDL)
  /// Wzmocnienie tylnej taśmy (hamstrings, pośladki, prostowniki grzbietu),
  /// ochrona odcinka lędźwiowego przed przeciążeniem i transfer mocy z biodra na korbę.
  romanianDeadlift,

  /// Przysiady ze sztangą z przodu (Front Squats)
  /// Mięśnie czworogłowe ud, mięśnie głębokie brzucha (core stability),
  /// pionowa sylwetka tułowia, budowa siły maksymalnej 1RM i mocy 5s-1m.
  frontSquats;

  String get displayName {
    switch (this) {
      case GymExerciseType.bulgarianSplitSquats:
        return 'Przysiady bułgarskie (Bulgarian Split Squats)';
      case GymExerciseType.romanianDeadlift:
        return 'Rumuński martwy ciąg (Romanian Deadlift - RDL)';
      case GymExerciseType.frontSquats:
        return 'Przysiady ze sztangą z przodu (Front Squats)';
    }
  }

  String get primaryMuscles {
    switch (this) {
      case GymExerciseType.bulgarianSplitSquats:
        return 'Czworogłowy uda, pośladkowy wielki i średni, pasmo ITB';
      case GymExerciseType.romanianDeadlift:
        return 'Kulszowo-goleniowe (hamstrings), pośladkowy wielki, prostowniki grzbietu';
      case GymExerciseType.frontSquats:
        return 'Czworogłowy uda, mięśnie głębokie brzucha (core), gorset tułowia';
    }
  }

  String get biomechanicalBenefits {
    switch (this) {
      case GymExerciseType.bulgarianSplitSquats:
        return 'Eliminacja asymetrii lewa/prawa noga, stabilizacja rzepki i miednicy, zero ucisku osiowego na kręgosłup.';
      case GymExerciseType.romanianDeadlift:
        return 'Transfer wyprostu biodra na korbę w kątach 12:00-17:00, ochrona przed bólami lędźwi i naderwaniami.';
      case GymExerciseType.frontSquats:
        return 'Rekrutacja wysokoprogowych jednostek motorycznych (włókna IIx), potężny transfer na waty 5s-1m i sprint.';
    }
  }

  /// Współczynnik redukcji ryzyka kontuzji (0.15 - 0.25)
  double get injuryPreventionBonus {
    switch (this) {
      case GymExerciseType.bulgarianSplitSquats:
        return 0.25;
      case GymExerciseType.romanianDeadlift:
        return 0.22;
      case GymExerciseType.frontSquats:
        return 0.18;
    }
  }

  String toJson() => name;

  static GymExerciseType fromJson(String value) {
    return GymExerciseType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GymExerciseType.frontSquats,
    );
  }
}

/// Dyscyplina treningu przekrojowego (Cross-Training) w okresie zimowym.
enum CrossTrainingType {
  /// Ergometr wioślarski (Rowing Ergometer - Concept2)
  rowingErgometer,

  /// Bieganie tempowe (Tempo Running)
  tempoRunning,

  /// Narty biegowe (Cross-Country Skiing / XC Skiing)
  crossCountrySkiing;

  String get displayName {
    switch (this) {
      case CrossTrainingType.rowingErgometer:
        return 'Ergometr wioślarski (Rowing Ergometer)';
      case CrossTrainingType.tempoRunning:
        return 'Bieganie tempowe w terenie (Tempo Running)';
      case CrossTrainingType.crossCountrySkiing:
        return 'Narty biegowe (Cross-Country Skiing / XC Skiing)';
    }
  }

  String get description {
    switch (this) {
      case CrossTrainingType.rowingErgometer:
        return 'Angażuje 85% masy mięśniowej ciała bez obciążeń udarowych. Buduje siłę obręczy barkowej i tlenową wydolność centralną.';
      case CrossTrainingType.tempoRunning:
        return 'Zwiększa mineralizację kości (BMD) przeciwdziałając osteopenii kolarskiej. Poprawia ekonomię biegu i wydolność układu krążenia.';
      case CrossTrainingType.crossCountrySkiing:
        return 'Kultowy bodziec mistrzów WorldTour. Maksymalny wyrzut VO2max, harmonijna praca całego ciała w strefie tlenowej bez uderzeń w stawy.';
    }
  }

  /// Mnożnik stymulacji pułapu tlenowego VO2max (0.80 - 1.00)
  double get vo2maxStimulusFactor {
    switch (this) {
      case CrossTrainingType.rowingErgometer:
        return 0.85;
      case CrossTrainingType.tempoRunning:
        return 0.90;
      case CrossTrainingType.crossCountrySkiing:
        return 1.00;
    }
  }

  /// Stopień wzmocnienia gęstości mineralnej kości (BMD)
  double get boneDensityBoostFactor {
    switch (this) {
      case CrossTrainingType.rowingErgometer:
        return 0.40;
      case CrossTrainingType.tempoRunning:
        return 0.95;
      case CrossTrainingType.crossCountrySkiing:
        return 0.65;
    }
  }

  String toJson() => name;

  static CrossTrainingType fromJson(String value) {
    return CrossTrainingType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CrossTrainingType.crossCountrySkiing,
    );
  }
}

/// Faza periodyzacji siłowej na siłowni (Gym Periodization Phase).
enum GymLoadPhase {
  /// Adaptacja Anatomiczna (AA - Listopad): 12-15 powtórzeń, 55-65% 1RM
  anatomicalAdaptation,

  /// Siła Maksymalna (MS - Grudzień): 3-5 powtórzeń, 80-90% 1RM
  maximumStrength,

  /// Hipertrofia Funkcjonalna (Sprinterzy): 6-8 powtórzeń, 70-78% 1RM
  functionalHypertrophy,

  /// Transfer Mocy i Szybkość Rozwijania Siły (RFD - Koniec Grudnia)
  powerTransferRfd;

  String get displayName {
    switch (this) {
      case GymLoadPhase.anatomicalAdaptation:
        return 'Adaptacja Anatomiczna (12-15 powt., 55-65% 1RM)';
      case GymLoadPhase.maximumStrength:
        return 'Siła Maksymalna (3-5 powt., 80-90% 1RM)';
      case GymLoadPhase.functionalHypertrophy:
        return 'Hipertrofia Funkcjonalna (6-8 powt., 70-78% 1RM)';
      case GymLoadPhase.powerTransferRfd:
        return 'Transfer Mocy & Szybkość RFD (4-6 powt. z max prędkością)';
    }
  }

  String toJson() => name;

  static GymLoadPhase fromJson(String value) {
    return GymLoadPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GymLoadPhase.anatomicalAdaptation,
    );
  }
}

/// Lokalizacja hiszpańskiego zimowego zgrupowania szosowego (Spanish Winter Camp).
enum SpanishCampLocation {
  calpeCostaBlanca,
  alteaAlicante,
  gironaCatalonia,
  mallorcaAlcudia,
  sierraNevadaGranada;

  String get displayName {
    switch (this) {
      case SpanishCampLocation.calpeCostaBlanca:
        return 'Calpe / Costa Blanca (Hiszpania)';
      case SpanishCampLocation.alteaAlicante:
        return 'Altea / Alicante (Hiszpania)';
      case SpanishCampLocation.gironaCatalonia:
        return 'Girona / Katalonia (Hiszpania)';
      case SpanishCampLocation.mallorcaAlcudia:
        return 'Majorka / Alcúdia & Palma (Hiszpania)';
      case SpanishCampLocation.sierraNevadaGranada:
        return 'Sierra Nevada / Andaluzja (Hiszpania)';
    }
  }

  double get averageJanuaryTempC {
    switch (this) {
      case SpanishCampLocation.calpeCostaBlanca:
        return 17.5;
      case SpanishCampLocation.alteaAlicante:
        return 18.0;
      case SpanishCampLocation.gironaCatalonia:
        return 14.5;
      case SpanishCampLocation.mallorcaAlcudia:
        return 16.0;
      case SpanishCampLocation.sierraNevadaGranada:
        return 10.5;
    }
  }

  List<String> get iconicClimbs {
    switch (this) {
      case SpanishCampLocation.calpeCostaBlanca:
        return ['Coll de Rates (6.5 km, 5.2%)', 'Cumbre del Sol (4.0 km, 10.1%)', 'Val d\'Ebo'];
      case SpanishCampLocation.alteaAlicante:
        return ['Puerto de Tudons (15 km, 5.0%)', 'Guadalest', 'Sierra Helada (22%)'];
      case SpanishCampLocation.gironaCatalonia:
        return ['Els Àngels (10 km, 3.8%)', 'Rocacorba (9.9 km, 7.4%)', 'Sant Grau'];
      case SpanishCampLocation.mallorcaAlcudia:
        return ['Sa Calobra / Coll dels Reis (9.4 km, 7.1%)', 'Puig Major (14.2 km, 6.0%)', 'Coll de Femenia'];
      case SpanishCampLocation.sierraNevadaGranada:
        return ['Alto de Monachil / El Purche (10 km, 8.5%)', 'Pico Veleta (do 2200m)', 'Hazallanas'];
    }
  }

  String get terrainDescription {
    switch (this) {
      case SpanishCampLocation.calpeCostaBlanca:
        return 'Złoty standard WorldTour: idealne asfaltowe wzniesienia, łagodna bryza, podjazdy progowe.';
      case SpanishCampLocation.alteaAlicante:
        return 'Świetna baza dla sprinterów i czasowców: płaskie odcinki przybrzeżne oraz strome ścianki Alicante.';
      case SpanishCampLocation.gironaCatalonia:
        return 'Kolebka kolarstwa zawodowego: wąskie techniczne asfalty, zróżnicowane pagórki i legendarna Rocacorba.';
      case SpanishCampLocation.mallorcaAlcudia:
        return 'Wzorcowe gładkie szosy, kultowa Sa Calobra i stabilna bezdeszczowa aura.';
      case SpanishCampLocation.sierraNevadaGranada:
        return 'Trening wczesnej adaptacji wysokościowej na wzniesieniach powyżej 1500m n.p.m.';
    }
  }

  String toJson() => name;

  static SpanishCampLocation fromJson(String value) {
    return SpanishCampLocation.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SpanishCampLocation.calpeCostaBlanca,
    );
  }
}

/// Ocena gotowości kolarza do wejścia w hiszpańskie zgrupowanie szosowe.
enum PreCampReadinessVerdict {
  readyForSpanishCamp,
  optimalPowerBoost,
  minorFatigueDeloadNeeded,
  highInjuryRiskNeedsAttention;

  String get displayName {
    switch (this) {
      case PreCampReadinessVerdict.readyForSpanishCamp:
        return 'Gotowy do Obrotu Szosowego (Forma Optymalna)';
      case PreCampReadinessVerdict.optimalPowerBoost:
        return 'Znakomity Wzrost Mocy i Stabilności';
      case PreCampReadinessVerdict.minorFatigueDeloadNeeded:
        return 'Wymagany Tapering (Lekkie Przemęczenie OUN)';
      case PreCampReadinessVerdict.highInjuryRiskNeedsAttention:
        return 'Wymagana Kontrola Fizjoterapeuty (Ryzyko Urazu)';
    }
  }

  bool get isApprovedToFly =>
      this == PreCampReadinessVerdict.readyForSpanishCamp ||
      this == PreCampReadinessVerdict.optimalPowerBoost ||
      this == PreCampReadinessVerdict.minorFatigueDeloadNeeded;

  String toJson() => name;

  static PreCampReadinessVerdict fromJson(String value) {
    return PreCampReadinessVerdict.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PreCampReadinessVerdict.readyForSpanishCamp,
    );
  }
}

/// Pojedyncze ćwiczenie siłowe w sesji treningowej.
class ScheduledGymExercise {
  final GymExerciseType exerciseType;
  final int sets;
  final int reps;
  final double intensityPct1Rm;
  final int restBetweenSetsSeconds;

  const ScheduledGymExercise({
    required this.exerciseType,
    required this.sets,
    required this.reps,
    required this.intensityPct1Rm,
    this.restBetweenSetsSeconds = 120,
  });

  Map<String, dynamic> toJson() => {
        'exerciseType': exerciseType.toJson(),
        'sets': sets,
        'reps': reps,
        'intensityPct1Rm': intensityPct1Rm,
        'restBetweenSetsSeconds': restBetweenSetsSeconds,
      };

  factory ScheduledGymExercise.fromJson(Map<String, dynamic> json) {
    return ScheduledGymExercise(
      exerciseType: GymExerciseType.fromJson(json['exerciseType'] as String),
      sets: (json['sets'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      intensityPct1Rm: (json['intensityPct1Rm'] as num).toDouble(),
      restBetweenSetsSeconds:
          (json['restBetweenSetsSeconds'] as num?)?.toInt() ?? 120,
    );
  }
}

/// Plan zimowego przygotowania kolarza (Off-Season Plan).
class WinterOffSeasonPlan {
  final String riderId;
  final WinterMonth month;
  final int gymSessionsPerWeek; // 1 - 3 sesje w tygodniu
  final int crossTrainingSessionsPerWeek; // 1 - 3 sesje w tygodniu
  final double indoorCyclingZ2HoursPerWeek; // 4.0 - 15.0 godzin w tlenie
  final GymLoadPhase gymPhase;
  final List<GymExerciseType> primaryGymExercises;
  final CrossTrainingType selectedCrossTrainingDiscipline;
  final SpanishCampLocation targetSpanishCamp;
  final bool focusOnCoreStability;

  const WinterOffSeasonPlan({
    required this.riderId,
    required this.month,
    this.gymSessionsPerWeek = 2,
    this.crossTrainingSessionsPerWeek = 2,
    this.indoorCyclingZ2HoursPerWeek = 8.0,
    required this.gymPhase,
    required this.primaryGymExercises,
    required this.selectedCrossTrainingDiscipline,
    this.targetSpanishCamp = SpanishCampLocation.calpeCostaBlanca,
    this.focusOnCoreStability = true,
  });

  WinterOffSeasonPlan copyWith({
    String? riderId,
    WinterMonth? month,
    int? gymSessionsPerWeek,
    int? crossTrainingSessionsPerWeek,
    double? indoorCyclingZ2HoursPerWeek,
    GymLoadPhase? gymPhase,
    List<GymExerciseType>? primaryGymExercises,
    CrossTrainingType? selectedCrossTrainingDiscipline,
    SpanishCampLocation? targetSpanishCamp,
    bool? focusOnCoreStability,
  }) {
    return WinterOffSeasonPlan(
      riderId: riderId ?? this.riderId,
      month: month ?? this.month,
      gymSessionsPerWeek: gymSessionsPerWeek ?? this.gymSessionsPerWeek,
      crossTrainingSessionsPerWeek:
          crossTrainingSessionsPerWeek ?? this.crossTrainingSessionsPerWeek,
      indoorCyclingZ2HoursPerWeek:
          indoorCyclingZ2HoursPerWeek ?? this.indoorCyclingZ2HoursPerWeek,
      gymPhase: gymPhase ?? this.gymPhase,
      primaryGymExercises: primaryGymExercises ?? this.primaryGymExercises,
      selectedCrossTrainingDiscipline:
          selectedCrossTrainingDiscipline ?? this.selectedCrossTrainingDiscipline,
      targetSpanishCamp: targetSpanishCamp ?? this.targetSpanishCamp,
      focusOnCoreStability: focusOnCoreStability ?? this.focusOnCoreStability,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'month': month.toJson(),
        'gymSessionsPerWeek': gymSessionsPerWeek,
        'crossTrainingSessionsPerWeek': crossTrainingSessionsPerWeek,
        'indoorCyclingZ2HoursPerWeek': indoorCyclingZ2HoursPerWeek,
        'gymPhase': gymPhase.toJson(),
        'primaryGymExercises':
            primaryGymExercises.map((e) => e.toJson()).toList(),
        'selectedCrossTrainingDiscipline':
            selectedCrossTrainingDiscipline.toJson(),
        'targetSpanishCamp': targetSpanishCamp.toJson(),
        'focusOnCoreStability': focusOnCoreStability,
      };

  factory WinterOffSeasonPlan.fromJson(Map<String, dynamic> json) {
    return WinterOffSeasonPlan(
      riderId: json['riderId'] as String,
      month: WinterMonth.fromJson(json['month'] as String),
      gymSessionsPerWeek: (json['gymSessionsPerWeek'] as num).toInt(),
      crossTrainingSessionsPerWeek:
          (json['crossTrainingSessionsPerWeek'] as num).toInt(),
      indoorCyclingZ2HoursPerWeek:
          (json['indoorCyclingZ2HoursPerWeek'] as num).toDouble(),
      gymPhase: GymLoadPhase.fromJson(json['gymPhase'] as String),
      primaryGymExercises: (json['primaryGymExercises'] as List<dynamic>)
          .map((e) => GymExerciseType.fromJson(e as String))
          .toList(),
      selectedCrossTrainingDiscipline: CrossTrainingType.fromJson(
          json['selectedCrossTrainingDiscipline'] as String),
      targetSpanishCamp:
          SpanishCampLocation.fromJson(json['targetSpanishCamp'] as String),
      focusOnCoreStability: json['focusOnCoreStability'] as bool? ?? true,
    );
  }
}

/// Wynik kompleksowych testów laboratoryjno-biomechanicznych przed zgrupowaniem szosowym.
class PreCampTestingResult {
  final String riderId;
  final String riderName;
  final DateTime testDate;
  final double estimated1rmFrontSquatKg;
  final double estimated1rmRdlKg;
  final double leftLegPowerPct;
  final double rightLegPowerPct;
  final bool isLeftRightSymmetrical;
  final int watts5s;
  final int watts15s;
  final int watts1m;
  final int watts5m;
  final int ftpWatts;
  final int watts5sDelta;
  final int watts1mDelta;
  final int ftpDelta;
  final double vo2Max;
  final double vo2MaxDelta;
  final double vlaMax;
  final double injuryRiskIndex; // 0.00 (stalowe ścięgna) - 1.00 (krytyczne przeciążenie)
  final int campReadinessScore; // 1 - 100
  final PreCampReadinessVerdict verdict;
  final SpanishCampLocation recommendedCampLocation;
  final String coachNotes;
  final String doctorClearanceNotes;

  const PreCampTestingResult({
    required this.riderId,
    required this.riderName,
    required this.testDate,
    required this.estimated1rmFrontSquatKg,
    required this.estimated1rmRdlKg,
    required this.leftLegPowerPct,
    required this.rightLegPowerPct,
    required this.isLeftRightSymmetrical,
    required this.watts5s,
    required this.watts15s,
    required this.watts1m,
    required this.watts5m,
    required this.ftpWatts,
    required this.watts5sDelta,
    required this.watts1mDelta,
    required this.ftpDelta,
    required this.vo2Max,
    required this.vo2MaxDelta,
    required this.vlaMax,
    required this.injuryRiskIndex,
    required this.campReadinessScore,
    required this.verdict,
    required this.recommendedCampLocation,
    required this.coachNotes,
    required this.doctorClearanceNotes,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'testDate': testDate.toIso8601String(),
        'estimated1rmFrontSquatKg': estimated1rmFrontSquatKg,
        'estimated1rmRdlKg': estimated1rmRdlKg,
        'leftLegPowerPct': leftLegPowerPct,
        'rightLegPowerPct': rightLegPowerPct,
        'isLeftRightSymmetrical': isLeftRightSymmetrical,
        'watts5s': watts5s,
        'watts15s': watts15s,
        'watts1m': watts1m,
        'watts5m': watts5m,
        'ftpWatts': ftpWatts,
        'watts5sDelta': watts5sDelta,
        'watts1mDelta': watts1mDelta,
        'ftpDelta': ftpDelta,
        'vo2Max': vo2Max,
        'vo2MaxDelta': vo2MaxDelta,
        'vlaMax': vlaMax,
        'injuryRiskIndex': injuryRiskIndex,
        'campReadinessScore': campReadinessScore,
        'verdict': verdict.toJson(),
        'recommendedCampLocation': recommendedCampLocation.toJson(),
        'coachNotes': coachNotes,
        'doctorClearanceNotes': doctorClearanceNotes,
      };

  factory PreCampTestingResult.fromJson(Map<String, dynamic> json) {
    return PreCampTestingResult(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      testDate: DateTime.parse(json['testDate'] as String),
      estimated1rmFrontSquatKg:
          (json['estimated1rmFrontSquatKg'] as num).toDouble(),
      estimated1rmRdlKg: (json['estimated1rmRdlKg'] as num).toDouble(),
      leftLegPowerPct: (json['leftLegPowerPct'] as num).toDouble(),
      rightLegPowerPct: (json['rightLegPowerPct'] as num).toDouble(),
      isLeftRightSymmetrical: json['isLeftRightSymmetrical'] as bool,
      watts5s: (json['watts5s'] as num).toInt(),
      watts15s: (json['watts15s'] as num).toInt(),
      watts1m: (json['watts1m'] as num).toInt(),
      watts5m: (json['watts5m'] as num).toInt(),
      ftpWatts: (json['ftpWatts'] as num).toInt(),
      watts5sDelta: (json['watts5sDelta'] as num).toInt(),
      watts1mDelta: (json['watts1mDelta'] as num).toInt(),
      ftpDelta: (json['ftpDelta'] as num).toInt(),
      vo2Max: (json['vo2Max'] as num).toDouble(),
      vo2MaxDelta: (json['vo2MaxDelta'] as num).toDouble(),
      vlaMax: (json['vlaMax'] as num).toDouble(),
      injuryRiskIndex: (json['injuryRiskIndex'] as num).toDouble(),
      campReadinessScore: (json['campReadinessScore'] as num).toInt(),
      verdict: PreCampReadinessVerdict.fromJson(json['verdict'] as String),
      recommendedCampLocation:
          SpanishCampLocation.fromJson(json['recommendedCampLocation'] as String),
      coachNotes: json['coachNotes'] as String,
      doctorClearanceNotes: json['doctorClearanceNotes'] as String,
    );
  }
}

/// Raport końcowy z okresu przygotowawczego kolarza (Winter Off-Season Report).
class WinterOffSeasonReport {
  final Rider updatedRider;
  final int weeksSimulated;
  final int watts5sGained;
  final int watts15sGained;
  final int watts1mGained;
  final int ftpWattsGained;
  final double vo2maxDelta;
  final double injuryResistanceBoostPct;
  final double leftRightBalanceImprovementPct;
  final double acuteFatigueAtl;
  final double chronicFitnessCtl;
  final double freshnessTsb;
  final PreCampTestingResult? testingResult;
  final List<String> trainingLog;

  const WinterOffSeasonReport({
    required this.updatedRider,
    required this.weeksSimulated,
    required this.watts5sGained,
    required this.watts15sGained,
    required this.watts1mGained,
    required this.ftpWattsGained,
    required this.vo2maxDelta,
    required this.injuryResistanceBoostPct,
    required this.leftRightBalanceImprovementPct,
    required this.acuteFatigueAtl,
    required this.chronicFitnessCtl,
    required this.freshnessTsb,
    this.testingResult,
    required this.trainingLog,
  });
}

/// Główny silnik i usługa okresu przygotowawczego w listopadzie i grudniu
/// (Winter Off-Season Training Service).
class WinterOffSeasonTrainingService {
  WinterOffSeasonTrainingService._();

  /// Tworzy spersonalizowany plan zimowy dobrany do specjalizacji kolarza i wskazówek trenera.
  static WinterOffSeasonPlan generateRecommendedPlan({
    required Rider rider,
    PerformanceCoach? coach,
    required WinterMonth month,
  }) {
    final spec = rider.specialization;
    final exercises = <GymExerciseType>[];

    // Dobór ćwiczeń siłowych wg potrzeb biomechanicznych specjalizacji:
    switch (spec) {
      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.versatileSprinter:
        exercises.addAll([
          GymExerciseType.frontSquats,
          GymExerciseType.bulgarianSplitSquats,
          GymExerciseType.romanianDeadlift,
        ]);
        break;
      case RiderSpecialization.gcClimber:
      case RiderSpecialization.pureClimber:
        exercises.addAll([
          GymExerciseType.bulgarianSplitSquats,
          GymExerciseType.romanianDeadlift,
        ]);
        break;
      case RiderSpecialization.timeTrialist:
        exercises.addAll([
          GymExerciseType.romanianDeadlift,
          GymExerciseType.frontSquats,
          GymExerciseType.bulgarianSplitSquats,
        ]);
        break;
      case RiderSpecialization.classicCobbles:
      case RiderSpecialization.puncher:
      case RiderSpecialization.domestiqueEngine:
      case RiderSpecialization.breakawaySpecialist:
        exercises.addAll([
          GymExerciseType.frontSquats,
          GymExerciseType.bulgarianSplitSquats,
          GymExerciseType.romanianDeadlift,
        ]);
        break;
    }

    // Dobór dyscypliny cross-training
    final CrossTrainingType crossTraining;
    if (spec == RiderSpecialization.pureSprinter ||
        spec == RiderSpecialization.versatileSprinter) {
      crossTraining = CrossTrainingType.rowingErgometer;
    } else if (spec == RiderSpecialization.gcClimber ||
        spec == RiderSpecialization.pureClimber) {
      crossTraining = CrossTrainingType.crossCountrySkiing;
    } else {
      crossTraining = CrossTrainingType.tempoRunning;
    }

    // Faza siłowa wg miesiąca
    final GymLoadPhase phase;
    if (month == WinterMonth.november) {
      phase = GymLoadPhase.anatomicalAdaptation;
    } else {
      phase = (spec == RiderSpecialization.pureSprinter)
          ? GymLoadPhase.functionalHypertrophy
          : GymLoadPhase.maximumStrength;
    }

    // Dobór lokalizacji zgrupowania hiszpańskiego
    final SpanishCampLocation campLoc;
    if (spec == RiderSpecialization.gcClimber || spec == RiderSpecialization.pureClimber) {
      campLoc = SpanishCampLocation.calpeCostaBlanca;
    } else if (spec == RiderSpecialization.pureSprinter) {
      campLoc = SpanishCampLocation.alteaAlicante;
    } else if (spec == RiderSpecialization.classicCobbles) {
      campLoc = SpanishCampLocation.gironaCatalonia;
    } else {
      campLoc = SpanishCampLocation.mallorcaAlcudia;
    }

    return WinterOffSeasonPlan(
      riderId: rider.id,
      month: month,
      gymSessionsPerWeek: (month == WinterMonth.november) ? 2 : 3,
      crossTrainingSessionsPerWeek: (month == WinterMonth.november) ? 3 : 2,
      indoorCyclingZ2HoursPerWeek: (month == WinterMonth.november) ? 6.0 : 10.0,
      gymPhase: phase,
      primaryGymExercises: exercises,
      selectedCrossTrainingDiscipline: crossTraining,
      targetSpanishCamp: campLoc,
      focusOnCoreStability: true,
    );
  }

  /// Symuluje 1 tydzień zimowego okresu przygotowawczego kolarza.
  static WinterOffSeasonReport simulateWeek({
    required Rider rider,
    required WinterOffSeasonPlan plan,
    PerformanceCoach? coach,
    TeamDoctor? doctor,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random(42 + rider.id.hashCode);
    final logs = <String>[];

    // 1. Wpływ wiedzy trenera przygotowania motorycznego (PerformanceCoach)
    final double coachGymSkillMultiplier;
    if (coach != null) {
      // Wyższa wiedza trenera to lepszy transfer siły na rower bez niepożądanej masy mięśniowej
      coachGymSkillMultiplier = 0.85 + (coach.winterGymPeriodizationSkill / 100.0) * 0.40;
    } else {
      coachGymSkillMultiplier = 1.0;
    }

    // 2. Obliczenie bodźców siłowych z poszczególnych ćwiczeń
    int watts5sGain = 0;
    int watts15sGain = 0;
    int watts1mGain = 0;
    int ftpGain = 0;
    double injuryResistanceDelta = 0.0;
    double leftRightBalanceDelta = 0.0;

    for (final exercise in plan.primaryGymExercises) {
      switch (exercise) {
        case GymExerciseType.frontSquats:
          // Front Squats budują moc maksymalną 5s i 15s oraz siłę tułowia
          final boost5s = (plan.gymPhase == GymLoadPhase.maximumStrength) ? 8 : 4;
          final boost15s = (plan.gymPhase == GymLoadPhase.maximumStrength) ? 6 : 3;
          const boost1m = 2;
          watts5sGain += (boost5s * coachGymSkillMultiplier).round();
          watts15sGain += (boost15s * coachGymSkillMultiplier).round();
          watts1mGain += (boost1m * coachGymSkillMultiplier).round();
          injuryResistanceDelta += 0.04;
          logs.add('Front Squats: aktywacja czwórogłowych ud i core (+${boost5s}W na 5s).');
          break;

        case GymExerciseType.romanianDeadlift:
          // RDL rozwija wyprost biodra i chroni odcinek lędźwiowy
          const boost15s = 4;
          const boost1m = 4;
          watts15sGain += (boost15s * coachGymSkillMultiplier).round();
          watts1mGain += (boost1m * coachGymSkillMultiplier).round();
          ftpGain += 1; // Stabilizacja biodra przenosi się na efektywność progową
          injuryResistanceDelta += 0.06;
          logs.add('Romanian Deadlift: wzmocnienie kulszowo-goleniowych i ochrona lędźwi (+${boost1m}W na 1m).');
          break;

        case GymExerciseType.bulgarianSplitSquats:
          // Przysiady bułgarskie niwelują asymetrię lewa/prawa noga i stabilizują pasmo ITB
          const boost5s = 3;
          const boost15s = 4;
          watts5sGain += (boost5s * coachGymSkillMultiplier).round();
          watts15sGain += (boost15s * coachGymSkillMultiplier).round();
          injuryResistanceDelta += 0.08;
          leftRightBalanceDelta += 0.40; // Progres w stronę idealnych 50.0% / 50.0%
          logs.add('Bulgarian Split Squats: praca jednostronna i stabilizacja miednicy (+0.4% symetrii).');
          break;
      }
    }

    // 3. Wpływ cross-trainingu
    double vo2maxDelta = 0.0;
    final crossType = plan.selectedCrossTrainingDiscipline;
    switch (crossType) {
      case CrossTrainingType.crossCountrySkiing:
        // Narty biegowe dają potężny impuls pułapowi tlenowemu VO2max
        vo2maxDelta = 0.20 + (random.nextDouble() * 0.15);
        ftpGain += 1;
        logs.add('Narty biegowe: praca w tlenie w strefie sub-maksymalnej (+${vo2maxDelta.toStringAsFixed(2)} ml/kg/min VO2max).');
        break;
      case CrossTrainingType.rowingErgometer:
        // Ergometr wioślarski wzmacnia siłę grzbietu i stabilność ramion na lemondce
        vo2maxDelta = 0.12 + (random.nextDouble() * 0.10);
        injuryResistanceDelta += 0.03;
        logs.add('Ergometr wioślarski: wzmocnienie obręczy barkowej i wytrzymałości tułowia.');
        break;
      case CrossTrainingType.tempoRunning:
        // Bieganie tempowe stymuluje gęstość mineralną kości (BMD)
        vo2maxDelta = 0.10 + (random.nextDouble() * 0.08);
        injuryResistanceDelta += 0.05;
        logs.add('Bieganie tempowe: stymulacja osteogenezy i mineralizacji kości.');
        break;
    }

    // 4. Jazda na trenażerze / szosie w strefie Z2
    final z2Hours = plan.indoorCyclingZ2HoursPerWeek;
    final ctlGain = z2Hours * 0.95; // Wzrost bazy CTL
    final atlGain = (plan.gymSessionsPerWeek * 14.0) + (plan.crossTrainingSessionsPerWeek * 12.0) + (z2Hours * 4.0);

    // 5. Aktualizacja mocy kolarza w profilu
    final curPower = rider.powerProfile;
    final updatedPower = curPower.copyWith(
      watts5s: curPower.watts5s + watts5sGain,
      watts15s: curPower.watts15s + watts15sGain,
      watts1m: curPower.watts1m + watts1mGain,
      watts60m: curPower.watts60m + ftpGain,
      watts20m: curPower.watts20m + ftpGain,
    );

    // 6. Aktualizacja fizjologii kolarza
    final curPhysio = rider.physiology;
    final updatedVo2max = (curPhysio.vo2Max + vo2maxDelta).clamp(65.0, 94.0);
    final updatedFtp = curPhysio.ftpWatts + ftpGain;
    final updatedPhysio = curPhysio.copyWith(
      vo2Max: updatedVo2max,
      ftpWatts: updatedFtp,
      form: (curPhysio.form + ctlGain * 0.25).clamp(40.0, 100.0),
      fatigue: (curPhysio.fatigue + atlGain * 0.15).clamp(10.0, 100.0),
    );

    // 7. Aktualizacja stanu zdrowia (Health & TSB)
    final curHealth = rider.health;
    final newCtl = (curHealth.chronicTrainingLoad + (ctlGain * 0.25)).clamp(40.0, 115.0);
    final newAtl = (curHealth.acuteTrainingLoad + (atlGain * 0.20)).clamp(20.0, 125.0);
    final updatedHealth = curHealth.copyWith(
      acuteTrainingLoad: newAtl,
      chronicTrainingLoad: newCtl,
    );

    // 8. Zwrócenie zaktualizowanego obiektu kolarza
    final updatedRider = rider.copyWith(
      powerProfile: updatedPower,
      physiology: updatedPhysio,
      health: updatedHealth,
    );

    return WinterOffSeasonReport(
      updatedRider: updatedRider,
      weeksSimulated: 1,
      watts5sGained: watts5sGain,
      watts15sGained: watts15sGain,
      watts1mGained: watts1mGain,
      ftpWattsGained: ftpGain,
      vo2maxDelta: vo2maxDelta,
      injuryResistanceBoostPct: injuryResistanceDelta * 100.0,
      leftRightBalanceImprovementPct: leftRightBalanceDelta,
      acuteFatigueAtl: newAtl,
      chronicFitnessCtl: newCtl,
      freshnessTsb: newCtl - newAtl,
      trainingLog: logs,
    );
  }

  /// Symuluje pełny 8-tygodniowy okres zimowy (listopad + grudzień) i przeprowadza testy laboratoryjne.
  static WinterOffSeasonReport simulateFullWinterOffSeason({
    required Rider rider,
    PerformanceCoach? coach,
    TeamDoctor? doctor,
    SpanishCampLocation? plannedCamp,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random(12345 + rider.id.hashCode);
    Rider currentRider = rider;
    final allLogs = <String>[];
    int total5sGain = 0;
    int total15sGain = 0;
    int total1mGain = 0;
    int totalFtpGain = 0;
    double totalVo2maxDelta = 0.0;
    double totalInjuryBoost = 0.0;
    double totalBalanceBoost = 0.0;

    final targetCamp = plannedCamp ?? SpanishCampLocation.calpeCostaBlanca;

    // Faza 1: Listopad (Tygodnie 1-4) – Adaptacja Anatomiczna & Roztrenowanie
    final novPlan = generateRecommendedPlan(
      rider: currentRider,
      coach: coach,
      month: WinterMonth.november,
    ).copyWith(targetSpanishCamp: targetCamp);

    allLogs.add('=== ROZPOCZĘCIE FAZY I: LISTOPAD (ADAPTACJA ANATOMICZNA & CROSS-TRAINING) ===');
    for (int w = 1; w <= 4; w++) {
      final rep = simulateWeek(
        rider: currentRider,
        plan: novPlan,
        coach: coach,
        doctor: doctor,
        rng: random,
      );
      currentRider = rep.updatedRider;
      total5sGain += rep.watts5sGained;
      total15sGain += rep.watts15sGained;
      total1mGain += rep.watts1mGained;
      totalFtpGain += rep.ftpWattsGained;
      totalVo2maxDelta += rep.vo2maxDelta;
      totalInjuryBoost += rep.injuryResistanceBoostPct;
      totalBalanceBoost += rep.leftRightBalanceImprovementPct;
      allLogs.add('Listopad Tydzień $w: +${rep.watts5sGained}W (5s), +${rep.watts15sGained}W (15s), TSB: ${rep.freshnessTsb.toStringAsFixed(1)}');
    }

    // Faza 2: Grudzień (Tygodnie 5-8) – Siła Maksymalna & Przygotowanie Szosowe
    final decPlan = generateRecommendedPlan(
      rider: currentRider,
      coach: coach,
      month: WinterMonth.december,
    ).copyWith(targetSpanishCamp: targetCamp);

    allLogs.add('=== ROZPOCZĘCIE FAZY II: GRUDZIEŃ (SIŁA MAKSYMALNA 1RM & RFD) ===');
    for (int w = 5; w <= 7; w++) {
      final rep = simulateWeek(
        rider: currentRider,
        plan: decPlan,
        coach: coach,
        doctor: doctor,
        rng: random,
      );
      currentRider = rep.updatedRider;
      total5sGain += rep.watts5sGained;
      total15sGain += rep.watts15sGained;
      total1mGain += rep.watts1mGained;
      totalFtpGain += rep.ftpWattsGained;
      totalVo2maxDelta += rep.vo2maxDelta;
      totalInjuryBoost += rep.injuryResistanceBoostPct;
      totalBalanceBoost += rep.leftRightBalanceImprovementPct;
      allLogs.add('Grudzień Tydzień $w: +${rep.watts5sGained}W (5s), +${rep.watts1mGained}W (1m), TSB: ${rep.freshnessTsb.toStringAsFixed(1)}');
    }

    // Tydzień 8: Tapering, testy laboratoryjne i biomechaniczne przed wylotem do Hiszpanii
    allLogs.add('=== TYDZIEŃ 8: TESTY WYDOLNOŚCIOWE I GOTOWOŚĆ PRZED ZGRUPOWANIEM W HISZPANII ===');
    final testingResult = conductPreCampFitnessTesting(
      rider: currentRider,
      coach: coach,
      doctor: doctor,
      initialWatts5s: rider.powerProfile.watts5s,
      initialWatts1m: rider.powerProfile.watts1m,
      initialFtp: rider.physiology.ftpWatts,
      initialVo2max: rider.physiology.vo2Max,
      plannedCamp: targetCamp,
    );

    allLogs.add('Test ergospirometryczny: VO2max = ${testingResult.vo2Max.toStringAsFixed(1)} ml/kg/min (+${testingResult.vo2MaxDelta.toStringAsFixed(1)})');
    allLogs.add('Test siły 1RM: Front Squats: ${testingResult.estimated1rmFrontSquatKg.toStringAsFixed(0)} kg, RDL: ${testingResult.estimated1rmRdlKg.toStringAsFixed(0)} kg');
    allLogs.add('Symetria pedałowania: L: ${testingResult.leftLegPowerPct.toStringAsFixed(1)}% / P: ${testingResult.rightLegPowerPct.toStringAsFixed(1)}%');
    allLogs.add('Ocena gotowości do obozu: ${testingResult.campReadinessScore}/100 – ${testingResult.verdict.displayName}');

    final finalHealth = currentRider.health;

    return WinterOffSeasonReport(
      updatedRider: currentRider,
      weeksSimulated: 8,
      watts5sGained: total5sGain,
      watts15sGained: total15sGain,
      watts1mGained: total1mGain,
      ftpWattsGained: totalFtpGain,
      vo2maxDelta: totalVo2maxDelta,
      injuryResistanceBoostPct: totalInjuryBoost,
      leftRightBalanceImprovementPct: totalBalanceBoost,
      acuteFatigueAtl: finalHealth.acuteTrainingLoad,
      chronicFitnessCtl: finalHealth.chronicTrainingLoad,
      freshnessTsb: finalHealth.trainingStressBalance,
      testingResult: testingResult,
      trainingLog: allLogs,
    );
  }

  /// Przeprowadza oficjalne testy wydolnościowe, siłowe i biomechaniczne przed wylotem do Hiszpanii.
  static PreCampTestingResult conductPreCampFitnessTesting({
    required Rider rider,
    PerformanceCoach? coach,
    TeamDoctor? doctor,
    int? initialWatts5s,
    int? initialWatts1m,
    int? initialFtp,
    double? initialVo2max,
    SpanishCampLocation? plannedCamp,
  }) {
    final weight = rider.physiology.weightKg;
    final coachSkill = coach?.experienceLevel ?? 75;
    final doctorSkill = doctor?.experienceLevel ?? 75;
    final camp = plannedCamp ?? SpanishCampLocation.calpeCostaBlanca;

    // 1. Estymacja siły maksymalnej 1RM na podstawie wagi i poziomu kolarza
    final squatMultiplier = (rider.specialization == RiderSpecialization.pureSprinter)
        ? 1.75
        : (rider.specialization == RiderSpecialization.classicCobbles ? 1.55 : 1.35);
    final est1rmFrontSquat = weight * squatMultiplier + (coachSkill * 0.15);
    final est1rmRdl = weight * (squatMultiplier * 1.15) + (coachSkill * 0.18);

    // 2. Symetria wyjściowa pedałowania (Left / Right balance)
    // Po solidnym bloku przysiadów bułgarskich asymetria spada do <1%
    final baseSkew = (rider.id.hashCode % 10) / 10.0 * 0.8; // 0.0 - 0.8% odchyłki
    final leftPct = 50.0 + baseSkew;
    final rightPct = 100.0 - leftPct;
    final isSymmetrical = (leftPct - 50.0).abs() <= 1.2;

    // 3. Pomiary mocy
    final currentPower = rider.powerProfile;
    final w5s = currentPower.watts5s;
    final w15s = currentPower.watts15s;
    final w1m = currentPower.watts1m;
    final w5m = currentPower.watts5m;
    final ftp = rider.physiology.ftpWatts;

    final w5sDelta = w5s - (initialWatts5s ?? (w5s - 45));
    final w1mDelta = w1m - (initialWatts1m ?? (w1m - 25));
    final ftpDelta = ftp - (initialFtp ?? (ftp - 8));

    // 4. Badanie ergospirometryczne
    final currentVo2 = rider.physiology.vo2Max;
    final vo2Delta = currentVo2 - (initialVo2max ?? (currentVo2 - 1.2));
    final vlaMax = rider.physiology.laboratoryProfile.vlaMaxMmolLPerSec;

    // 5. Indeks ryzyka kontuzji (Injury Risk Index)
    // Rumuński martwy ciąg i bułgary obniżają ryzyko urazu o 70-85%
    final baseRisk = 0.35 - (coachSkill / 100.0 * 0.15) - (doctorSkill / 100.0 * 0.10);
    final injuryRisk = baseRisk.clamp(0.05, 0.45);

    // 6. Punktacja gotowości (Camp Readiness Score 1-100)
    int readinessScore = 78;
    if (w5sDelta > 20) readinessScore += 6;
    if (vo2Delta > 0.8) readinessScore += 6;
    if (isSymmetrical) readinessScore += 5;
    if (rider.health.trainingStressBalance >= -5.0) readinessScore += 5;
    readinessScore = readinessScore.clamp(50, 99);

    // 7. Werdykt sztabu
    final PreCampReadinessVerdict verdict;
    if (readinessScore >= 88) {
      verdict = PreCampReadinessVerdict.optimalPowerBoost;
    } else if (readinessScore >= 75) {
      verdict = PreCampReadinessVerdict.readyForSpanishCamp;
    } else if (rider.health.trainingStressBalance < -15.0) {
      verdict = PreCampReadinessVerdict.minorFatigueDeloadNeeded;
    } else {
      verdict = PreCampReadinessVerdict.highInjuryRiskNeedsAttention;
    }

    // 8. Notatki trenera i lekarza
    final coachNotes = 'Kolarz zbudował znakomitą rekrutację włókien IIx (+${w5sDelta}W na 5s, +${w1mDelta}W na 1m). '
        'Wysoka stabilność miednicy po Bulgarian Split Squats. Rekomendowane wejście w obóz w ${camp.displayName} '
        'z obciążeniem do ${camp.averageJanuaryTempC.toStringAsFixed(0)}°C.';

    const doctorNotes = 'Wskaźnik kinazy kreatynowej w normie, aparat więzadłowy kolan i ścięgna Achillesa '
        'doskonale zaadaptowane. Gęstość mineralna kości optymalna. Brak przeciwwskazań medycznych do wylotu do Hiszpanii.';

    return PreCampTestingResult(
      riderId: rider.id,
      riderName: rider.fullName,
      testDate: DateTime(2026, 12, 30),
      estimated1rmFrontSquatKg: est1rmFrontSquat,
      estimated1rmRdlKg: est1rmRdl,
      leftLegPowerPct: leftPct,
      rightLegPowerPct: rightPct,
      isLeftRightSymmetrical: isSymmetrical,
      watts5s: w5s,
      watts15s: w15s,
      watts1m: w1m,
      watts5m: w5m,
      ftpWatts: ftp,
      watts5sDelta: w5sDelta,
      watts1mDelta: w1mDelta,
      ftpDelta: ftpDelta,
      vo2Max: currentVo2,
      vo2MaxDelta: vo2Delta,
      vlaMax: vlaMax,
      injuryRiskIndex: injuryRisk,
      campReadinessScore: readinessScore,
      verdict: verdict,
      recommendedCampLocation: camp,
      coachNotes: coachNotes,
      doctorClearanceNotes: doctorNotes,
    );
  }

  /// Zwraca listę wszystkich 5 hiszpańskich baz zgrupowaniowych ze szczegółową charakterystyką.
  static List<SpanishCampLocation> getAllSpanishCampLocations() {
    return SpanishCampLocation.values;
  }
}
