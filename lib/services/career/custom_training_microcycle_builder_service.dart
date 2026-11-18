// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';

/// Dzień tygodnia w 7-dniowym mikrocyklu treningowym.
enum MicrocycleDayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  int get dayIndex => index;

  String get shortLabelPl {
    switch (this) {
      case MicrocycleDayOfWeek.monday:
        return 'Pon';
      case MicrocycleDayOfWeek.tuesday:
        return 'Wt';
      case MicrocycleDayOfWeek.wednesday:
        return 'Śr';
      case MicrocycleDayOfWeek.thursday:
        return 'Czw';
      case MicrocycleDayOfWeek.friday:
        return 'Pt';
      case MicrocycleDayOfWeek.saturday:
        return 'Sob';
      case MicrocycleDayOfWeek.sunday:
        return 'Nd';
    }
  }

  String get labelPl {
    switch (this) {
      case MicrocycleDayOfWeek.monday:
        return 'Poniedziałek';
      case MicrocycleDayOfWeek.tuesday:
        return 'Wtorek';
      case MicrocycleDayOfWeek.wednesday:
        return 'Środa';
      case MicrocycleDayOfWeek.thursday:
        return 'Czwartek';
      case MicrocycleDayOfWeek.friday:
        return 'Piątek';
      case MicrocycleDayOfWeek.saturday:
        return 'Sobota';
      case MicrocycleDayOfWeek.sunday:
        return 'Niedziela';
    }
  }

  String toJson() => name;

  static MicrocycleDayOfWeek fromJson(String value) {
    return MicrocycleDayOfWeek.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MicrocycleDayOfWeek.monday,
    );
  }
}

/// Rodzaj jednostki treningowej w mikrocyklu.
enum TrainingWorkoutType {
  restDay,
  activeRecovery,
  zone2Endurance,
  sweetSpot,
  thresholdOverUnders,
  vo2maxIntervals,
  motorPacing,
  sprintNeuromuscular;

  String get labelPl {
    switch (this) {
      case TrainingWorkoutType.restDay:
        return 'Dzień Wolny (Odnowa)';
      case TrainingWorkoutType.activeRecovery:
        return 'Aktywna Regeneracja (Z1)';
      case TrainingWorkoutType.zone2Endurance:
        return 'Baza Tlenowa (Z2)';
      case TrainingWorkoutType.sweetSpot:
        return 'Sweet Spot (88–94% FTP)';
      case TrainingWorkoutType.thresholdOverUnders:
        return 'Over-Unders LT2 (Z4/Z5)';
      case TrainingWorkoutType.vo2maxIntervals:
        return 'Interwały VO2max (Z5)';
      case TrainingWorkoutType.motorPacing:
        return 'Motor-Pacing za Skuterem';
      case TrainingWorkoutType.sprintNeuromuscular:
        return 'Zrywy Neuromuskularne (Z7)';
    }
  }

  String get shortCode {
    switch (this) {
      case TrainingWorkoutType.restDay:
        return 'REST';
      case TrainingWorkoutType.activeRecovery:
        return 'Z1 REC';
      case TrainingWorkoutType.zone2Endurance:
        return 'Z2 BASE';
      case TrainingWorkoutType.sweetSpot:
        return 'SST';
      case TrainingWorkoutType.thresholdOverUnders:
        return 'LT2 O/U';
      case TrainingWorkoutType.vo2maxIntervals:
        return 'VO2max';
      case TrainingWorkoutType.motorPacing:
        return 'MOTOR';
      case TrainingWorkoutType.sprintNeuromuscular:
        return 'Z7 SPR';
    }
  }

  /// Główna strefa mocy Coggana (1–7) powiązana z jednostką.
  int get primaryPowerZone {
    switch (this) {
      case TrainingWorkoutType.restDay:
      case TrainingWorkoutType.activeRecovery:
        return 1;
      case TrainingWorkoutType.zone2Endurance:
        return 2;
      case TrainingWorkoutType.sweetSpot:
        return 3;
      case TrainingWorkoutType.thresholdOverUnders:
        return 4;
      case TrainingWorkoutType.vo2maxIntervals:
        return 5;
      case TrainingWorkoutType.motorPacing:
        return 6;
      case TrainingWorkoutType.sprintNeuromuscular:
        return 7;
    }
  }

  /// Czy jednostka należy do obciążeń o wysokiej intensywności (HIT).
  bool get isHighIntensity {
    switch (this) {
      case TrainingWorkoutType.sweetSpot:
      case TrainingWorkoutType.thresholdOverUnders:
      case TrainingWorkoutType.vo2maxIntervals:
      case TrainingWorkoutType.motorPacing:
      case TrainingWorkoutType.sprintNeuromuscular:
        return true;
      case TrainingWorkoutType.restDay:
      case TrainingWorkoutType.activeRecovery:
      case TrainingWorkoutType.zone2Endurance:
        return false;
    }
  }

  /// Domyślny czas trwania sesji w minutach.
  int get defaultDurationMinutes {
    switch (this) {
      case TrainingWorkoutType.restDay:
        return 0;
      case TrainingWorkoutType.activeRecovery:
        return 60;
      case TrainingWorkoutType.zone2Endurance:
        return 210;
      case TrainingWorkoutType.sweetSpot:
        return 120;
      case TrainingWorkoutType.thresholdOverUnders:
        return 110;
      case TrainingWorkoutType.vo2maxIntervals:
        return 95;
      case TrainingWorkoutType.motorPacing:
        return 135;
      case TrainingWorkoutType.sprintNeuromuscular:
        return 85;
    }
  }

  /// Domyślny współczynnik intensywności (Intensity Factor - IF).
  double get defaultIntensityFactor {
    switch (this) {
      case TrainingWorkoutType.restDay:
        return 0.0;
      case TrainingWorkoutType.activeRecovery:
        return 0.55;
      case TrainingWorkoutType.zone2Endurance:
        return 0.68;
      case TrainingWorkoutType.sweetSpot:
        return 0.84;
      case TrainingWorkoutType.thresholdOverUnders:
        return 0.91;
      case TrainingWorkoutType.vo2maxIntervals:
        return 0.96;
      case TrainingWorkoutType.motorPacing:
        return 0.89;
      case TrainingWorkoutType.sprintNeuromuscular:
        return 0.82;
    }
  }

  /// Domyślna struktura interwałów do wyświetlenia w planerze.
  String get defaultIntervalStructure {
    switch (this) {
      case TrainingWorkoutType.restDay:
        return 'Masaż + sen 9h + nawodnienie';
      case TrainingWorkoutType.activeRecovery:
        return '60\' @ 50–55% FTP (kadencja 90 rpm)';
      case TrainingWorkoutType.zone2Endurance:
        return '3.5h @ 65–74% FTP (tlenowo, niski mleczan)';
      case TrainingWorkoutType.sweetSpot:
        return '3×20\' @ 90% FTP / 5\' przerwy Z1';
      case TrainingWorkoutType.thresholdOverUnders:
        return '4×12\' (2\' @ 95% / 1\' @ 106% FTP)';
      case TrainingWorkoutType.vo2maxIntervals:
        return '5×4\' @ 115% FTP / 4\' aktywnego odpoczynku';
      case TrainingWorkoutType.motorPacing:
        return '90\' za skuterem (58 km/h, 110 rpm) + 4×90" zrywy';
      case TrainingWorkoutType.sprintNeuromuscular:
        return '8×12" MAX (1100+ W) / 5\' pełnego wypoczynku';
    }
  }

  String toJson() => name;

  static TrainingWorkoutType fromJson(String value) {
    return TrainingWorkoutType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TrainingWorkoutType.zone2Endurance,
    );
  }
}

/// Gotowe szablony celów tygodniowego mikrocyklu.
enum MicrocycleGoalPreset {
  vo2maxPeak,
  sweetSpotBase,
  motorPacingClassics,
  taperingPreRace,
  custom;

  String get labelPl {
    switch (this) {
      case MicrocycleGoalPreset.vo2maxPeak:
        return 'Blok VO2max (Ardeny & Góry)';
      case MicrocycleGoalPreset.sweetSpotBase:
        return 'Blok Sweet Spot (Budowa FTP)';
      case MicrocycleGoalPreset.motorPacingClassics:
        return 'Motor-Pacing (Klasyki & Szybkość)';
      case MicrocycleGoalPreset.taperingPreRace:
        return 'Tapering (Szczyt Świeżości)';
      case MicrocycleGoalPreset.custom:
        return 'Własny Mikrocykl';
    }
  }

  String get subtitlePl {
    switch (this) {
      case MicrocycleGoalPreset.vo2maxPeak:
        return '2× interwały Z5 + podbudowa tlenowa dla maksymalnego pułapu tlenowego.';
      case MicrocycleGoalPreset.sweetSpotBase:
        return 'Wysoka objętość 88–94% FTP podnosząca próg mleczanowy i wytrzymałość GC.';
      case MicrocycleGoalPreset.motorPacingClassics:
        return 'Jazda za skuterem w wysokim rytmie 55–65 km/h oraz zrywy pod bruki.';
      case MicrocycleGoalPreset.taperingPreRace:
        return 'Redukcja objętości o 45% przy utrzymaniu krótkich bodźców pod start.';
      case MicrocycleGoalPreset.custom:
        return 'Dowolna konfiguracja 7 dni zaplanowana przez dyrektora sportowego.';
    }
  }

  String toJson() => name;

  static MicrocycleGoalPreset fromJson(String value) {
    return MicrocycleGoalPreset.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MicrocycleGoalPreset.custom,
    );
  }
}

/// Poziom ryzyka fizjologicznego wyliczony dla mikrocyklu.
enum MicrocycleRiskLevel {
  optimal,
  productiveOverreach,
  highFatigue,
  overtrainingDanger;

  String get labelPl {
    switch (this) {
      case MicrocycleRiskLevel.optimal:
        return 'Optymalna Adaptacja';
      case MicrocycleRiskLevel.productiveOverreach:
        return 'Produktywne Przeciążenie';
      case MicrocycleRiskLevel.highFatigue:
        return 'Wysokie Zmęczenie (Wymagana Regeneracja)';
      case MicrocycleRiskLevel.overtrainingDanger:
        return 'Ryzyko Przetrenowania (Niebezpieczny TSB)';
    }
  }

  Color get statusColor {
    switch (this) {
      case MicrocycleRiskLevel.optimal:
        return AppColors.statusSuccess;
      case MicrocycleRiskLevel.productiveOverreach:
        return AppColors.accentBlue;
      case MicrocycleRiskLevel.highFatigue:
        return AppColors.amberWarning;
      case MicrocycleRiskLevel.overtrainingDanger:
        return AppColors.crimsonAlert;
    }
  }
}

/// Pojedyncza sesja treningowa przypisana do konkretnego dnia tygodnia.
class MicrocycleDaySession {
  final MicrocycleDayOfWeek day;
  final TrainingWorkoutType workoutType;
  final int durationMinutes;
  final double intensityFactor;
  final String intervalStructure;
  final bool behindMotorPacer;
  final String coachNote;

  const MicrocycleDaySession({
    required this.day,
    required this.workoutType,
    required this.durationMinutes,
    required this.intensityFactor,
    required this.intervalStructure,
    this.behindMotorPacer = false,
    this.coachNote = '',
  });

  factory MicrocycleDaySession.fromType({
    required MicrocycleDayOfWeek day,
    required TrainingWorkoutType workoutType,
    int? durationMinutes,
    double? intensityFactor,
    String? intervalStructure,
    String coachNote = '',
  }) {
    final resolvedDuration =
        (durationMinutes ?? workoutType.defaultDurationMinutes).clamp(0, 420);
    final resolvedIf = workoutType == TrainingWorkoutType.restDay
        ? 0.0
        : (intensityFactor ?? workoutType.defaultIntensityFactor)
            .clamp(0.40, 1.25);
    return MicrocycleDaySession(
      day: day,
      workoutType: workoutType,
      durationMinutes: resolvedDuration,
      intensityFactor: resolvedIf,
      intervalStructure:
          intervalStructure ?? workoutType.defaultIntervalStructure,
      behindMotorPacer: workoutType == TrainingWorkoutType.motorPacing,
      coachNote: coachNote,
    );
  }

  /// Szacowany wynik obciążenia treningowego TSS:
  /// TSS = godziny * IF^2 * 100 (+ premia gęstości kadencji dla motor-pacing).
  double get estimatedTss {
    if (workoutType == TrainingWorkoutType.restDay || durationMinutes <= 0) {
      return 0.0;
    }
    final hours = durationMinutes / 60.0;
    final motorFactor = behindMotorPacer ? 1.06 : 1.0;
    return hours * intensityFactor * intensityFactor * 100.0 * motorFactor;
  }

  int get primaryPowerZone => workoutType.primaryPowerZone;

  MicrocycleDaySession copyWith({
    MicrocycleDayOfWeek? day,
    TrainingWorkoutType? workoutType,
    int? durationMinutes,
    double? intensityFactor,
    String? intervalStructure,
    bool? behindMotorPacer,
    String? coachNote,
  }) {
    return MicrocycleDaySession(
      day: day ?? this.day,
      workoutType: workoutType ?? this.workoutType,
      durationMinutes: (durationMinutes ?? this.durationMinutes).clamp(0, 420),
      intensityFactor: (intensityFactor ?? this.intensityFactor).clamp(0.0, 1.25),
      intervalStructure: intervalStructure ?? this.intervalStructure,
      behindMotorPacer: behindMotorPacer ?? this.behindMotorPacer,
      coachNote: coachNote ?? this.coachNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day.toJson(),
      'workoutType': workoutType.toJson(),
      'durationMinutes': durationMinutes,
      'intensityFactor': intensityFactor,
      'intervalStructure': intervalStructure,
      'behindMotorPacer': behindMotorPacer,
      'coachNote': coachNote,
    };
  }

  factory MicrocycleDaySession.fromJson(Map<String, dynamic> json) {
    return MicrocycleDaySession(
      day: MicrocycleDayOfWeek.fromJson((json['day'] as String?) ?? 'monday'),
      workoutType: TrainingWorkoutType.fromJson(
        (json['workoutType'] as String?) ?? 'zone2Endurance',
      ),
      durationMinutes:
          ((json['durationMinutes'] as num?)?.toInt() ?? 0).clamp(0, 420),
      intensityFactor:
          ((json['intensityFactor'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.25),
      intervalStructure: (json['intervalStructure'] as String?) ?? '',
      behindMotorPacer: (json['behindMotorPacer'] as bool?) ?? false,
      coachNote: (json['coachNote'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MicrocycleDaySession &&
        other.day == day &&
        other.workoutType == workoutType &&
        other.durationMinutes == durationMinutes &&
        other.intensityFactor == intensityFactor &&
        other.intervalStructure == intervalStructure &&
        other.behindMotorPacer == behindMotorPacer &&
        other.coachNote == coachNote;
  }

  @override
  int get hashCode => Object.hash(
        day,
        workoutType,
        durationMinutes,
        intensityFactor,
        intervalStructure,
        behindMotorPacer,
        coachNote,
      );
}

/// Kompletny 7-dniowy plan mikrocyklu treningowego.
class WeeklyTrainingMicrocycle {
  final String id;
  final String name;
  final MicrocycleGoalPreset preset;
  final List<MicrocycleDaySession> sessions;
  final RiderSpecialization? targetSpecialization;
  final String notes;
  final DateTime createdAt;

  const WeeklyTrainingMicrocycle({
    required this.id,
    required this.name,
    required this.preset,
    required this.sessions,
    this.targetSpecialization,
    this.notes = '',
    required this.createdAt,
  });

  double get totalWeeklyTss =>
      sessions.fold<double>(0.0, (sum, s) => sum + s.estimatedTss);

  int get totalDurationMinutes =>
      sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

  double get totalHours => totalDurationMinutes / 60.0;

  int get hardDaysCount =>
      sessions.where((s) => s.workoutType.isHighIntensity).length;

  int get recoveryDaysCount => sessions
      .where(
        (s) =>
            s.workoutType == TrainingWorkoutType.restDay ||
            s.workoutType == TrainingWorkoutType.activeRecovery,
      )
      .length;

  bool get hasThreeConsecutiveHardDays {
    int streak = 0;
    for (final session in sessions) {
      if (session.workoutType.isHighIntensity) {
        streak++;
        if (streak >= 3) return true;
      } else {
        streak = 0;
      }
    }
    return false;
  }

  /// Rozkład minut w strefach Z1–Z7.
  Map<int, int> get zoneDistributionMinutes {
    final map = <int, int>{
      for (int z = 1; z <= 7; z++) z: 0,
    };
    for (final session in sessions) {
      if (session.durationMinutes <= 0) continue;
      final zone = session.primaryPowerZone.clamp(1, 7);
      map[zone] = (map[zone] ?? 0) + session.durationMinutes;
    }
    return map;
  }

  /// Rozkład ułamkowy czasu w strefach Z1–Z7 (suma = 1.0 przy czasie > 0).
  Map<int, double> get zoneDistributionFraction {
    final total = totalDurationMinutes;
    if (total <= 0) {
      return {for (int z = 1; z <= 7; z++) z: 0.0};
    }
    final mins = zoneDistributionMinutes;
    return {
      for (int z = 1; z <= 7; z++) z: (mins[z] ?? 0) / total,
    };
  }

  /// Wskaźnik polaryzacji (stosunek sesji lekkich/tlenowych Z1–Z2 do wysokointensywnych).
  double get polarizationScore {
    if (sessions.isEmpty) return 0.0;
    final lowMinutes = sessions
        .where((s) => s.primaryPowerZone <= 2)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final total = totalDurationMinutes;
    if (total == 0) return 0.0;
    final lowRatio = lowMinutes / total;
    // Idealny rozkład spolaryzowany/piramidalny dla kolarza WT to ok. 70-82% Z1/Z2.
    final distanceFromIdeal = (lowRatio - 0.76).abs();
    return (100.0 - distanceFromIdeal * 140.0).clamp(10.0, 100.0);
  }

  WeeklyTrainingMicrocycle copyWith({
    String? id,
    String? name,
    MicrocycleGoalPreset? preset,
    List<MicrocycleDaySession>? sessions,
    RiderSpecialization? targetSpecialization,
    String? notes,
    DateTime? createdAt,
  }) {
    return WeeklyTrainingMicrocycle(
      id: id ?? this.id,
      name: name ?? this.name,
      preset: preset ?? this.preset,
      sessions: sessions ?? this.sessions,
      targetSpecialization: targetSpecialization ?? this.targetSpecialization,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'preset': preset.toJson(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'targetSpecialization': targetSpecialization?.toJson(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeeklyTrainingMicrocycle.fromJson(Map<String, dynamic> json) {
    final rawSessions = (json['sessions'] as List<dynamic>? ?? [])
        .map((e) => MicrocycleDaySession.fromJson(e as Map<String, dynamic>))
        .toList();
    final specStr = json['targetSpecialization'] as String?;
    return WeeklyTrainingMicrocycle(
      id: (json['id'] as String?) ?? 'microcycle_custom',
      name: (json['name'] as String?) ?? 'Mikrocykl Treningowy',
      preset: MicrocycleGoalPreset.fromJson(
        (json['preset'] as String?) ?? 'custom',
      ),
      sessions: rawSessions,
      targetSpecialization:
          specStr != null ? RiderSpecialization.fromJson(specStr) : null,
      notes: (json['notes'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime(2026, 1, 1),
    );
  }
}

/// Dzienny punkt prognozy Banistera/Coggana CTL, ATL i TSB.
class MicrocycleDailyProjectionPoint {
  final MicrocycleDayOfWeek day;
  final double dailyTss;
  final double ctl;
  final double atl;
  final double tsb;
  final int primaryPowerZone;

  const MicrocycleDailyProjectionPoint({
    required this.day,
    required this.dailyTss,
    required this.ctl,
    required this.atl,
    required this.tsb,
    required this.primaryPowerZone,
  });
}

/// Raport prognozy adaptacji fizjologicznej mikrocyklu dla konkretnego kolarza.
class MicrocyclePhysiologicalProjection {
  final String riderId;
  final String riderName;
  final double initialCtl;
  final double initialAtl;
  final double initialTsb;
  final double projectedCtl;
  final double projectedAtl;
  final double projectedTsb;
  final double projectedFtpDeltaWatts;
  final double projectedVo2maxDelta;
  final double projected5mWattsDelta;
  final double projectedSprintWattsDelta;
  final double projectedFlatAndDraftingGain;
  final List<MicrocycleDailyProjectionPoint> dailyProjections;
  final MicrocycleRiskLevel riskLevel;
  final List<String> warnings;
  final int synergyScore;

  const MicrocyclePhysiologicalProjection({
    required this.riderId,
    required this.riderName,
    required this.initialCtl,
    required this.initialAtl,
    required this.initialTsb,
    required this.projectedCtl,
    required this.projectedAtl,
    required this.projectedTsb,
    required this.projectedFtpDeltaWatts,
    required this.projectedVo2maxDelta,
    required this.projected5mWattsDelta,
    required this.projectedSprintWattsDelta,
    required this.projectedFlatAndDraftingGain,
    required this.dailyProjections,
    required this.riskLevel,
    required this.warnings,
    required this.synergyScore,
  });

  double get deltaCtl => projectedCtl - initialCtl;
  double get deltaAtl => projectedAtl - initialAtl;
  double get deltaTsb => projectedTsb - initialTsb;
}

/// Wynik operacji zastosowania mikrocyklu na kolarza.
class MicrocycleApplicationResult {
  final bool success;
  final Rider updatedRider;
  final MicrocyclePhysiologicalProjection projection;
  final String message;

  const MicrocycleApplicationResult({
    required this.success,
    required this.updatedRider,
    required this.projection,
    required this.message,
  });
}

/// Wynik walidacji struktury 7-dniowego mikrocyklu.
class MicrocycleValidationReport {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const MicrocycleValidationReport({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

/// Główny serwis budowania, walidacji i symulacji fizjologicznej
/// tygodniowych mikrocykli treningowych (VO2max, Motor-Pacing, Sweet Spot).
class CustomTrainingMicrocycleBuilderService {
  static const double _ctlTimeConstantDays = 42.0;
  static const double _atlTimeConstantDays = 7.0;

  const CustomTrainingMicrocycleBuilderService();

  /// Tworzy gotowy 7-dniowy szablon mikrocyklu dla wybranego celu.
  WeeklyTrainingMicrocycle buildPresetMicrocycle(
    MicrocycleGoalPreset preset, {
    String? customId,
    String? customName,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime(2026, 3, 1);
    final id = customId ?? 'microcycle_${preset.name}_${now.millisecondsSinceEpoch}';
    final name = customName ?? preset.labelPl;

    switch (preset) {
      case MicrocycleGoalPreset.vo2maxPeak:
        return WeeklyTrainingMicrocycle(
          id: id,
          name: name,
          preset: preset,
          targetSpecialization: RiderSpecialization.puncher,
          notes:
              'Podwójny bodziec VO2max (Wtorek, Czwartek) otoczony regeneracją i długą wytrzymałością weekendową.',
          createdAt: now,
          sessions: [
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.monday,
              workoutType: TrainingWorkoutType.activeRecovery,
              coachNote: 'Rozruch po weekendzie, masaż powięziowy.',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.tuesday,
              workoutType: TrainingWorkoutType.vo2maxIntervals,
              durationMinutes: 100,
              coachNote: 'Główny bodziec Z5 pod krótkie ścianki.',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.wednesday,
              workoutType: TrainingWorkoutType.zone2Endurance,
              durationMinutes: 165,
              coachNote: 'Spokojne kręcenie Z2 bez szarpania tempa.',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.thursday,
              workoutType: TrainingWorkoutType.vo2maxIntervals,
              durationMinutes: 105,
              intervalStructure: '6×3.5\' @ 118% FTP / 3.5\' Z1',
              coachNote: 'Drugi akcent VO2max na wyższej kadencji.',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.friday,
              workoutType: TrainingWorkoutType.restDay,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.saturday,
              workoutType: TrainingWorkoutType.sweetSpot,
              durationMinutes: 150,
              coachNote: 'Podbudowa wytrzymałości pod zmęczeniem.',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.sunday,
              workoutType: TrainingWorkoutType.zone2Endurance,
              durationMinutes: 240,
              coachNote: 'Długa baza tlenowa w terenie pagórkowatym.',
            ),
          ],
        );

      case MicrocycleGoalPreset.sweetSpotBase:
        return WeeklyTrainingMicrocycle(
          id: id,
          name: name,
          preset: preset,
          targetSpecialization: RiderSpecialization.gcClimber,
          notes:
              'Budowanie wysokiej objętości na progu tlenowym i w strefie Sweet Spot (88–94% FTP) dla liderów GC.',
          createdAt: now,
          sessions: [
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.monday,
              workoutType: TrainingWorkoutType.restDay,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.tuesday,
              workoutType: TrainingWorkoutType.sweetSpot,
              durationMinutes: 130,
              intervalStructure: '3×20\' @ 90% FTP / 5\' Z1',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.wednesday,
              workoutType: TrainingWorkoutType.zone2Endurance,
              durationMinutes: 195,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.thursday,
              workoutType: TrainingWorkoutType.thresholdOverUnders,
              durationMinutes: 120,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.friday,
              workoutType: TrainingWorkoutType.activeRecovery,
              durationMinutes: 60,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.saturday,
              workoutType: TrainingWorkoutType.sweetSpot,
              durationMinutes: 165,
              intervalStructure: '2×35\' @ 89% FTP pod górę',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.sunday,
              workoutType: TrainingWorkoutType.zone2Endurance,
              durationMinutes: 255,
            ),
          ],
        );

      case MicrocycleGoalPreset.motorPacingClassics:
        return WeeklyTrainingMicrocycle(
          id: id,
          name: name,
          preset: preset,
          targetSpecialization: RiderSpecialization.classicCobbles,
          notes:
              'Trening za skuterem (Motor-Pacing) symulujący prędkości 55–65 km/h w peletonie oraz zrywy na brukach.',
          createdAt: now,
          sessions: [
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.monday,
              workoutType: TrainingWorkoutType.activeRecovery,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.tuesday,
              workoutType: TrainingWorkoutType.motorPacing,
              durationMinutes: 140,
              coachNote: 'Jazda za motocyklem 58 km/h, wysoka kadencja.',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.wednesday,
              workoutType: TrainingWorkoutType.zone2Endurance,
              durationMinutes: 180,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.thursday,
              workoutType: TrainingWorkoutType.sprintNeuromuscular,
              durationMinutes: 95,
              coachNote: 'Zrywy z koła przy dużej prędkości.',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.friday,
              workoutType: TrainingWorkoutType.restDay,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.saturday,
              workoutType: TrainingWorkoutType.motorPacing,
              durationMinutes: 160,
              intervalStructure: '110\' za skuterem + 5×1\' atak na sektorze',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.sunday,
              workoutType: TrainingWorkoutType.zone2Endurance,
              durationMinutes: 210,
            ),
          ],
        );

      case MicrocycleGoalPreset.taperingPreRace:
        return WeeklyTrainingMicrocycle(
          id: id,
          name: name,
          preset: preset,
          targetSpecialization: RiderSpecialization.versatileSprinter,
          notes:
              'Redukcja objętości przed ważnym startem przy zachowaniu krótkich pobudzeń Z5/Z7.',
          createdAt: now,
          sessions: [
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.monday,
              workoutType: TrainingWorkoutType.restDay,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.tuesday,
              workoutType: TrainingWorkoutType.vo2maxIntervals,
              durationMinutes: 70,
              intervalStructure: '3×3\' @ 112% FTP (podtrzymanie)',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.wednesday,
              workoutType: TrainingWorkoutType.activeRecovery,
              durationMinutes: 55,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.thursday,
              workoutType: TrainingWorkoutType.sprintNeuromuscular,
              durationMinutes: 65,
              intervalStructure: '4×10" otwarcia przedstartowe',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.friday,
              workoutType: TrainingWorkoutType.activeRecovery,
              durationMinutes: 50,
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.saturday,
              workoutType: TrainingWorkoutType.zone2Endurance,
              durationMinutes: 90,
              intervalStructure: '90\' Z2 + 3×30" przyspieszenia',
            ),
            MicrocycleDaySession.fromType(
              day: MicrocycleDayOfWeek.sunday,
              workoutType: TrainingWorkoutType.restDay,
              coachNote: 'Pełna świeżość na dzień wyścigu.',
            ),
          ],
        );

      case MicrocycleGoalPreset.custom:
        return WeeklyTrainingMicrocycle(
          id: id,
          name: name,
          preset: MicrocycleGoalPreset.custom,
          notes: 'Indywidualny mikrocykl treningowy.',
          createdAt: now,
          sessions: MicrocycleDayOfWeek.values
              .map(
                (d) => MicrocycleDaySession.fromType(
                  day: d,
                  workoutType: d == MicrocycleDayOfWeek.monday ||
                          d == MicrocycleDayOfWeek.friday
                      ? TrainingWorkoutType.activeRecovery
                      : TrainingWorkoutType.zone2Endurance,
                ),
              )
              .toList(),
        );
    }
  }

  /// Waliduje strukturę 7-dniowego mikrocyklu treningowego.
  MicrocycleValidationReport validateMicrocycle(
    WeeklyTrainingMicrocycle microcycle,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    if (microcycle.sessions.length != 7) {
      errors.add(
        'Mikrocykl musi zawierać dokładnie 7 dni (obecnie: ${microcycle.sessions.length}).',
      );
    }

    final seenDays = <MicrocycleDayOfWeek>{};
    for (final session in microcycle.sessions) {
      if (!seenDays.add(session.day)) {
        errors.add('Duplikat dnia w mikrocyklu: ${session.day.labelPl}.');
      }
      if (session.workoutType != TrainingWorkoutType.restDay &&
          session.durationMinutes <= 0) {
        errors.add(
          '${session.day.labelPl}: jednostka ${session.workoutType.shortCode} musi trwać > 0 min.',
        );
      }
    }

    if (microcycle.hasThreeConsecutiveHardDays) {
      warnings.add(
        'Wykryto >= 3 dni o wysokiej intensywności z rzędu. Wprowadź dzień Z1/REST dla pełnej superkompensacji.',
      );
    }

    if (microcycle.recoveryDaysCount == 0) {
      warnings.add(
        'Brak dnia regeneracyjnego (Z1 lub Wolny) w tygodniu zwiększa ryzyko przeciążenia.',
      );
    }

    if (microcycle.totalWeeklyTss > 1150) {
      warnings.add(
        'Łączne obciążenie (${microcycle.totalWeeklyTss.round()} TSS) przekracza typowy limit tygodniowy 1150 TSS.',
      );
    }

    return MicrocycleValidationReport(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Symuluje 7-dniową adaptację fizjologiczną kolarza dla zadanego mikrocyklu.
  MicrocyclePhysiologicalProjection simulateMicrocycleForRider({
    required WeeklyTrainingMicrocycle microcycle,
    required Rider rider,
  }) {
    final initialCtl = rider.health.chronicTrainingLoad.clamp(0.0, 150.0);
    final initialAtl = rider.health.acuteTrainingLoad.clamp(0.0, 180.0);
    final initialTsb = initialCtl - initialAtl;

    double currentCtl = initialCtl;
    double currentAtl = initialAtl;
    final dailyPoints = <MicrocycleDailyProjectionPoint>[];

    double vo2maxLoadTss = 0.0;
    double sweetSpotAndThresholdTss = 0.0;
    double motorPacingTss = 0.0;
    double sprintTss = 0.0;

    final sortedSessions = List<MicrocycleDaySession>.from(microcycle.sessions)
      ..sort((a, b) => a.day.dayIndex.compareTo(b.day.dayIndex));

    for (final session in sortedSessions) {
      final tss = session.estimatedTss;
      currentCtl =
          currentCtl + (tss - currentCtl) / _ctlTimeConstantDays;
      currentAtl =
          currentAtl + (tss - currentAtl) / _atlTimeConstantDays;
      final tsb = currentCtl - currentAtl;

      dailyPoints.add(
        MicrocycleDailyProjectionPoint(
          day: session.day,
          dailyTss: tss,
          ctl: currentCtl,
          atl: currentAtl,
          tsb: tsb,
          primaryPowerZone: session.primaryPowerZone,
        ),
      );

      switch (session.workoutType) {
        case TrainingWorkoutType.vo2maxIntervals:
          vo2maxLoadTss += tss;
          break;
        case TrainingWorkoutType.sweetSpot:
        case TrainingWorkoutType.thresholdOverUnders:
          sweetSpotAndThresholdTss += tss;
          break;
        case TrainingWorkoutType.motorPacing:
          motorPacingTss += tss;
          break;
        case TrainingWorkoutType.sprintNeuromuscular:
          sprintTss += tss;
          break;
        case TrainingWorkoutType.restDay:
        case TrainingWorkoutType.activeRecovery:
        case TrainingWorkoutType.zone2Endurance:
          break;
      }
    }

    final projectedTsb = currentCtl - currentAtl;

    // Skala adaptacji zależy od potencjału i poziomu wytrenowania (malejące przychody).
    final potentialFactor = (0.75 + (rider.potential / 100.0) * 0.50);
    final recoveryFactor = rider.physiology.recoveryRate.clamp(0.7, 1.3);
    final fatiguePenalty = projectedTsb < -30.0
        ? 0.55
        : (projectedTsb < -20.0 ? 0.82 : 1.0);

    final ftpDelta = (sweetSpotAndThresholdTss / 140.0) *
            1.8 *
            potentialFactor *
            fatiguePenalty +
        (vo2maxLoadTss / 200.0) * 0.7 * potentialFactor * fatiguePenalty;

    final vo2maxDelta =
        (vo2maxLoadTss / 180.0) * 0.42 * potentialFactor * fatiguePenalty;
    final p5mDelta =
        (vo2maxLoadTss / 150.0) * 4.2 * potentialFactor * fatiguePenalty;
    final sprintDelta =
        ((sprintTss / 100.0) * 14.0 + (motorPacingTss / 180.0) * 6.0) *
            potentialFactor *
            fatiguePenalty;
    final flatAndDraftingGain =
        (motorPacingTss / 140.0) * 1.4 * recoveryFactor;

    final warnings = <String>[
      ...validateMicrocycle(microcycle).warnings,
    ];

    if (!rider.health.canTrain) {
      warnings.insert(
        0,
        'Kolarz ${rider.fullName} ma aktywną kontuzję blokującą trening (${rider.health.currentInjury?.name ?? 'uraz'}).',
      );
    }

    final rampRatio =
        initialCtl > 10.0 ? microcycle.totalWeeklyTss / (initialCtl * 7.0) : 1.0;
    if (rampRatio > 1.45) {
      warnings.add(
        'Gwałtowny skok obciążenia (+${((rampRatio - 1.0) * 100).round()}% względem aktualnego CTL ${initialCtl.toStringAsFixed(0)}).',
      );
    }

    final MicrocycleRiskLevel riskLevel;
    if (projectedTsb < -35.0 ||
        (microcycle.hasThreeConsecutiveHardDays && projectedTsb < -22.0)) {
      riskLevel = MicrocycleRiskLevel.overtrainingDanger;
    } else if (projectedTsb < -22.0 || rampRatio > 1.40) {
      riskLevel = MicrocycleRiskLevel.highFatigue;
    } else if (projectedTsb < -8.0) {
      riskLevel = MicrocycleRiskLevel.productiveOverreach;
    } else {
      riskLevel = MicrocycleRiskLevel.optimal;
    }

    final synergyScore = _computeSynergyScore(
      microcycle: microcycle,
      rider: rider,
      riskLevel: riskLevel,
    );

    return MicrocyclePhysiologicalProjection(
      riderId: rider.id,
      riderName: rider.fullName,
      initialCtl: initialCtl,
      initialAtl: initialAtl,
      initialTsb: initialTsb,
      projectedCtl: currentCtl,
      projectedAtl: currentAtl,
      projectedTsb: projectedTsb,
      projectedFtpDeltaWatts: double.parse(ftpDelta.toStringAsFixed(1)),
      projectedVo2maxDelta: double.parse(vo2maxDelta.toStringAsFixed(2)),
      projected5mWattsDelta: double.parse(p5mDelta.toStringAsFixed(1)),
      projectedSprintWattsDelta: double.parse(sprintDelta.toStringAsFixed(1)),
      projectedFlatAndDraftingGain:
          double.parse(flatAndDraftingGain.toStringAsFixed(1)),
      dailyProjections: dailyPoints,
      riskLevel: riskLevel,
      warnings: warnings,
      synergyScore: synergyScore,
    );
  }

  int _computeSynergyScore({
    required WeeklyTrainingMicrocycle microcycle,
    required Rider rider,
    required MicrocycleRiskLevel riskLevel,
  }) {
    double score = 62.0;

    final hasVo2 = microcycle.sessions
        .any((s) => s.workoutType == TrainingWorkoutType.vo2maxIntervals);
    final hasSweetSpot = microcycle.sessions
        .any((s) => s.workoutType == TrainingWorkoutType.sweetSpot);
    final hasMotorPacing = microcycle.sessions
        .any((s) => s.workoutType == TrainingWorkoutType.motorPacing);

    switch (rider.specialization) {
      case RiderSpecialization.gcClimber:
      case RiderSpecialization.pureClimber:
        if (hasSweetSpot) score += 16;
        if (hasVo2) score += 10;
        break;
      case RiderSpecialization.puncher:
        if (hasVo2) score += 18;
        if (hasMotorPacing) score += 8;
        break;
      case RiderSpecialization.classicCobbles:
      case RiderSpecialization.versatileSprinter:
      case RiderSpecialization.pureSprinter:
        if (hasMotorPacing) score += 18;
        if (hasVo2) score += 6;
        break;
      case RiderSpecialization.timeTrialist:
        if (hasSweetSpot) score += 16;
        if (hasMotorPacing) score += 10;
        break;
      case RiderSpecialization.domestiqueEngine:
      case RiderSpecialization.breakawaySpecialist:
        if (hasSweetSpot) score += 12;
        if (hasMotorPacing) score += 10;
        break;
    }

    score += (microcycle.polarizationScore - 60.0) * 0.25;

    if (riskLevel == MicrocycleRiskLevel.overtrainingDanger) {
      score -= 22;
    } else if (riskLevel == MicrocycleRiskLevel.highFatigue) {
      score -= 8;
    }

    return score.round().clamp(15, 99);
  }

  /// Realizuje tygodniowy mikrocykl treningowy na kolarzu i zwraca zaktualizowany model.
  MicrocycleApplicationResult applyMicrocycleToRider({
    required WeeklyTrainingMicrocycle microcycle,
    required Rider rider,
  }) {
    final projection = simulateMicrocycleForRider(
      microcycle: microcycle,
      rider: rider,
    );

    final validation = validateMicrocycle(microcycle);
    if (!validation.isValid) {
      return MicrocycleApplicationResult(
        success: false,
        updatedRider: rider,
        projection: projection,
        message: validation.errors.first,
      );
    }

    if (!rider.health.canTrain) {
      return MicrocycleApplicationResult(
        success: false,
        updatedRider: rider,
        projection: projection,
        message:
            'Trening zablokowany przez sztab medyczny: ${rider.health.currentInjury?.name ?? 'aktywna kontuzja'}.',
      );
    }

    final ftpGain = projection.projectedFtpDeltaWatts.round();
    final p5mGain = projection.projected5mWattsDelta.round();
    final sprintGain = projection.projectedSprintWattsDelta.round();
    final draftingGain = projection.projectedFlatAndDraftingGain.round();

    final updatedPhysiology = rider.physiology.copyWith(
      ftpWatts: (rider.physiology.ftpWatts + ftpGain).clamp(150, 600),
      vo2Max: double.parse(
        (rider.physiology.vo2Max + projection.projectedVo2maxDelta)
            .clamp(45.0, 96.0)
            .toStringAsFixed(1),
      ),
      form: projection.projectedCtl.clamp(0.0, 150.0),
      fatigue: projection.projectedAtl.clamp(0.0, 180.0),
    );

    final updatedPowerProfile = rider.powerProfile.copyWith(
      watts5s: (rider.powerProfile.watts5s + sprintGain).clamp(400, 2200),
      watts5m: (rider.powerProfile.watts5m + p5mGain).clamp(200, 750),
      watts20m: (rider.powerProfile.watts20m + ftpGain).clamp(180, 650),
      watts60m: (rider.powerProfile.watts60m + ftpGain).clamp(150, 600),
    );

    final updatedSkills = rider.skills.copyWith(
      draftingEfficiency:
          (rider.skills.draftingEfficiency + draftingGain).clamp(1, 99),
      aeroPositioning:
          (rider.skills.aeroPositioning + (draftingGain > 0 ? 1 : 0))
              .clamp(1, 99),
    );

    final updatedHealth = rider.health.copyWith(
      chronicTrainingLoad: projection.projectedCtl,
      acuteTrainingLoad: projection.projectedAtl,
    );

    final updatedRider = rider.copyWith(
      physiology: updatedPhysiology,
      powerProfile: updatedPowerProfile,
      skills: updatedSkills,
      health: updatedHealth,
    );

    return MicrocycleApplicationResult(
      success: true,
      updatedRider: updatedRider,
      projection: projection,
      message:
          'Zastosowano mikrocykl "${microcycle.name}" dla ${rider.fullName} (CTL ${projection.projectedCtl.toStringAsFixed(1)}, TSB ${projection.projectedTsb.toStringAsFixed(1)}).',
    );
  }
}

/// Stan Riverpod dla kreatora tygodniowych mikrocykli treningowych.
class CustomTrainingMicrocycleState {
  final WeeklyTrainingMicrocycle activeMicrocycle;
  final List<WeeklyTrainingMicrocycle> savedTemplates;
  final MicrocycleDayOfWeek selectedDay;
  final Rider selectedRider;
  final MicrocyclePhysiologicalProjection projection;
  final MicrocycleValidationReport validation;
  final String? lastActionFeedback;
  final bool lastActionError;

  const CustomTrainingMicrocycleState({
    required this.activeMicrocycle,
    required this.savedTemplates,
    required this.selectedDay,
    required this.selectedRider,
    required this.projection,
    required this.validation,
    this.lastActionFeedback,
    this.lastActionError = false,
  });

  MicrocycleDaySession get selectedSession =>
      activeMicrocycle.sessions.firstWhere(
        (s) => s.day == selectedDay,
        orElse: () => activeMicrocycle.sessions.first,
      );

  CustomTrainingMicrocycleState copyWith({
    WeeklyTrainingMicrocycle? activeMicrocycle,
    List<WeeklyTrainingMicrocycle>? savedTemplates,
    MicrocycleDayOfWeek? selectedDay,
    Rider? selectedRider,
    MicrocyclePhysiologicalProjection? projection,
    MicrocycleValidationReport? validation,
    String? lastActionFeedback,
    bool clearFeedback = false,
    bool? lastActionError,
  }) {
    return CustomTrainingMicrocycleState(
      activeMicrocycle: activeMicrocycle ?? this.activeMicrocycle,
      savedTemplates: savedTemplates ?? this.savedTemplates,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedRider: selectedRider ?? this.selectedRider,
      projection: projection ?? this.projection,
      validation: validation ?? this.validation,
      lastActionFeedback: clearFeedback
          ? null
          : (lastActionFeedback ?? this.lastActionFeedback),
      lastActionError: lastActionError ?? this.lastActionError,
    );
  }
}

/// Notifier zarządzający kreatorem tygodniowych mikrocykli treningowych.
class CustomTrainingMicrocycleNotifier
    extends StateNotifier<CustomTrainingMicrocycleState> {
  final CustomTrainingMicrocycleBuilderService _service;

  CustomTrainingMicrocycleNotifier({
    CustomTrainingMicrocycleBuilderService? service,
    Rider? initialRider,
  })  : _service = service ?? const CustomTrainingMicrocycleBuilderService(),
        super(_createInitialState(
          service ?? const CustomTrainingMicrocycleBuilderService(),
          initialRider ?? _buildDefaultDemoRider(),
        ));

  static CustomTrainingMicrocycleState _createInitialState(
    CustomTrainingMicrocycleBuilderService service,
    Rider rider,
  ) {
    final vo2 = service.buildPresetMicrocycle(MicrocycleGoalPreset.vo2maxPeak);
    final sweetSpot =
        service.buildPresetMicrocycle(MicrocycleGoalPreset.sweetSpotBase);
    final motor =
        service.buildPresetMicrocycle(MicrocycleGoalPreset.motorPacingClassics);
    final taper =
        service.buildPresetMicrocycle(MicrocycleGoalPreset.taperingPreRace);

    return CustomTrainingMicrocycleState(
      activeMicrocycle: vo2,
      savedTemplates: [vo2, sweetSpot, motor, taper],
      selectedDay: MicrocycleDayOfWeek.tuesday,
      selectedRider: rider,
      projection: service.simulateMicrocycleForRider(
        microcycle: vo2,
        rider: rider,
      ),
      validation: service.validateMicrocycle(vo2),
    );
  }

  static Rider _buildDefaultDemoRider() {
    return Rider(
      id: 'rider_microcycle_demo_01',
      firstName: 'Michał',
      lastName: 'Kowalski',
      nationalityIso: 'PL',
      birthDate: DateTime(1998, 5, 14),
      potential: 89,
      specialization: RiderSpecialization.puncher,
      physiology: const RiderPhysiology(
        heightCm: 179.0,
        weightKg: 67.5,
        bodyFatPercentage: 7.4,
        ftpWatts: 410,
        wPrimeJoules: 24500,
        vo2Max: 81.5,
        maxHr: 194,
        restingHr: 39,
        lactateThresholdHr: 176,
        recoveryRate: 1.08,
        glycogenCapacityGrams: 540.0,
        form: 76.0,
        fatigue: 68.0,
      ),
      powerProfile: const RiderPowerProfile(
        watts5s: 1320,
        watts15s: 1090,
        watts30s: 880,
        watts1m: 690,
        watts3m: 515,
        watts5m: 475,
        watts20m: 432,
        watts60m: 405,
      ),
      skills: const RiderSkills(
        cobbles: 78,
        descending: 82,
        bikeHandling: 84,
        aeroPositioning: 79,
        draftingEfficiency: 81,
        raceIq: 85,
        rainResistance: 77,
        heatTolerance: 74,
        timeTrialPositioning: 76,
      ),
      appearance: const RiderAppearance(
        faceShapeIndex: 1,
        skinToneHex: '#E8C3A9',
        hairStyleIndex: 2,
        hairColorHex: '#3B2F2F',
        facialHairIndex: 0,
        glassesModelId: 'sport_shield',
        glassesLensColorHex: '#D4AF37',
        helmetModelId: 'aero_pro',
        shoeColorHex: '#F3F4F6',
        sockHeightProportion: 0.85,
        bodyBuildType: BodyBuildType.allRounder,
      ),
      contract: const RiderContract(
        teamId: 'team_player',
        role: RiderRole.coLeader,
        monthlySalaryEur: 70000,
        signingBonusEur: 50000,
        winBonusEur: 15000,
        releaseClauseEur: 2500000,
        contractEndYear: 2028,
        morale: 0.85,
        leaderLoyalty: 82.0,
        requiredRacesIds: [],
      ),
      health: const RiderHealth(
        acuteTrainingLoad: 68.0,
        chronicTrainingLoad: 76.0,
      ),
      careerPointsUci: 1420,
    );
  }

  void selectDay(MicrocycleDayOfWeek day) {
    state = state.copyWith(selectedDay: day, clearFeedback: true);
  }

  void selectRider(Rider rider) {
    final projection = _service.simulateMicrocycleForRider(
      microcycle: state.activeMicrocycle,
      rider: rider,
    );
    state = state.copyWith(
      selectedRider: rider,
      projection: projection,
      clearFeedback: true,
    );
  }

  void loadPreset(MicrocycleGoalPreset preset) {
    final microcycle = _service.buildPresetMicrocycle(preset);
    _updateActiveMicrocycle(
      microcycle,
      feedback: 'Załadowano szablon: ${preset.labelPl}.',
    );
  }

  void loadSavedTemplate(WeeklyTrainingMicrocycle template) {
    _updateActiveMicrocycle(
      template,
      feedback: 'Wczytano plan: ${template.name}.',
    );
  }

  void updateDayWorkoutType(
    MicrocycleDayOfWeek day,
    TrainingWorkoutType workoutType,
  ) {
    final updatedSessions = state.activeMicrocycle.sessions.map((s) {
      if (s.day != day) return s;
      return MicrocycleDaySession.fromType(
        day: day,
        workoutType: workoutType,
        coachNote: s.coachNote,
      );
    }).toList();

    final updatedMicrocycle = state.activeMicrocycle.copyWith(
      preset: MicrocycleGoalPreset.custom,
      sessions: updatedSessions,
    );
    _updateActiveMicrocycle(updatedMicrocycle);
  }

  void updateDayDuration(MicrocycleDayOfWeek day, int durationMinutes) {
    final updatedSessions = state.activeMicrocycle.sessions.map((s) {
      if (s.day != day) return s;
      if (s.workoutType == TrainingWorkoutType.restDay) return s;
      return s.copyWith(durationMinutes: durationMinutes.clamp(15, 420));
    }).toList();

    final updatedMicrocycle = state.activeMicrocycle.copyWith(
      preset: MicrocycleGoalPreset.custom,
      sessions: updatedSessions,
    );
    _updateActiveMicrocycle(updatedMicrocycle);
  }

  void updateDayIntensityFactor(MicrocycleDayOfWeek day, double intensityFactor) {
    final updatedSessions = state.activeMicrocycle.sessions.map((s) {
      if (s.day != day) return s;
      if (s.workoutType == TrainingWorkoutType.restDay) return s;
      return s.copyWith(intensityFactor: intensityFactor.clamp(0.45, 1.25));
    }).toList();

    final updatedMicrocycle = state.activeMicrocycle.copyWith(
      preset: MicrocycleGoalPreset.custom,
      sessions: updatedSessions,
    );
    _updateActiveMicrocycle(updatedMicrocycle);
  }

  void swapDays(MicrocycleDayOfWeek first, MicrocycleDayOfWeek second) {
    if (first == second) return;
    final firstSession =
        state.activeMicrocycle.sessions.firstWhere((s) => s.day == first);
    final secondSession =
        state.activeMicrocycle.sessions.firstWhere((s) => s.day == second);

    final updatedSessions = state.activeMicrocycle.sessions.map((s) {
      if (s.day == first) return secondSession.copyWith(day: first);
      if (s.day == second) return firstSession.copyWith(day: second);
      return s;
    }).toList();

    _updateActiveMicrocycle(
      state.activeMicrocycle.copyWith(
        preset: MicrocycleGoalPreset.custom,
        sessions: updatedSessions,
      ),
      feedback: 'Zamieniono ${first.shortLabelPl} z ${second.shortLabelPl}.',
    );
  }

  void updateMicrocycleName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _updateActiveMicrocycle(
      state.activeMicrocycle.copyWith(name: trimmed),
    );
  }

  void saveCurrentAsTemplate() {
    final current = state.activeMicrocycle;
    final cloned = current.copyWith(
      id: 'microcycle_saved_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      savedTemplates: [cloned, ...state.savedTemplates],
      lastActionFeedback: 'Zapisano mikrocykl "${cloned.name}" w bibliotece.',
      lastActionError: false,
    );
  }

  MicrocycleApplicationResult applyActiveMicrocycle() {
    final result = _service.applyMicrocycleToRider(
      microcycle: state.activeMicrocycle,
      rider: state.selectedRider,
    );

    if (result.success) {
      final nextProjection = _service.simulateMicrocycleForRider(
        microcycle: state.activeMicrocycle,
        rider: result.updatedRider,
      );
      state = state.copyWith(
        selectedRider: result.updatedRider,
        projection: nextProjection,
        lastActionFeedback: result.message,
        lastActionError: false,
      );
    } else {
      state = state.copyWith(
        lastActionFeedback: result.message,
        lastActionError: true,
      );
    }
    return result;
  }

  void _updateActiveMicrocycle(
    WeeklyTrainingMicrocycle microcycle, {
    String? feedback,
  }) {
    final projection = _service.simulateMicrocycleForRider(
      microcycle: microcycle,
      rider: state.selectedRider,
    );
    final validation = _service.validateMicrocycle(microcycle);
    state = state.copyWith(
      activeMicrocycle: microcycle,
      projection: projection,
      validation: validation,
      lastActionFeedback: feedback,
      clearFeedback: feedback == null,
      lastActionError: false,
    );
  }
}

/// Globalny provider Riverpod dla kreatora tygodniowych mikrocykli treningowych.
final customTrainingMicrocycleProvider = StateNotifierProvider<
    CustomTrainingMicrocycleNotifier, CustomTrainingMicrocycleState>(
  (ref) => CustomTrainingMicrocycleNotifier(),
);

/// Interaktywny panel UI Kreatora Tygodniowych Mikrocykli Treningowych.
/// Obsługuje responsywnie rozdzielczości `390x844`, `1024x768` oraz `1600x900`.
class CustomTrainingMicrocycleBuilderPanel extends ConsumerStatefulWidget {
  const CustomTrainingMicrocycleBuilderPanel({super.key});

  @override
  ConsumerState<CustomTrainingMicrocycleBuilderPanel> createState() =>
      _CustomTrainingMicrocycleBuilderPanelState();
}

class _CustomTrainingMicrocycleBuilderPanelState
    extends ConsumerState<CustomTrainingMicrocycleBuilderPanel> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final initialName =
        ref.read(customTrainingMicrocycleProvider).activeMicrocycle.name;
    _nameController = TextEditingController(text: initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customTrainingMicrocycleProvider);
    final notifier = ref.read(customTrainingMicrocycleProvider.notifier);

    if (_nameController.text != state.activeMicrocycle.name) {
      _nameController.value = TextEditingValue(
        text: state.activeMicrocycle.name,
        selection:
            TextSelection.collapsed(offset: state.activeMicrocycle.name.length),
      );
    }

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 720;
          final isDesktop = width >= 1220;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, notifier, isMobile),
                const SizedBox(height: 16),
                _buildPresetSelectorRow(state, notifier, isMobile),
                const SizedBox(height: 16),
                if (state.lastActionFeedback != null) ...[
                  _buildFeedbackBanner(
                    state.lastActionFeedback!,
                    isError: state.lastActionError,
                  ),
                  const SizedBox(height: 16),
                ],
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            _buildWeekGrid(state, notifier, columns: 4),
                            const SizedBox(height: 16),
                            _buildProjectionChartCard(state),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildDayEditorCard(state, notifier, isMobile),
                            const SizedBox(height: 16),
                            _buildPhysiologicalSummaryCard(state, notifier),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (!isMobile)
                  Column(
                    children: [
                      _buildWeekGrid(state, notifier, columns: 4),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDayEditorCard(state, notifier, false),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPhysiologicalSummaryCard(
                              state,
                              notifier,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildProjectionChartCard(state),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildWeekGrid(state, notifier, columns: 2),
                      const SizedBox(height: 14),
                      _buildDayEditorCard(state, notifier, true),
                      const SizedBox(height: 14),
                      _buildProjectionChartCard(state),
                      const SizedBox(height: 14),
                      _buildPhysiologicalSummaryCard(state, notifier),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    CustomTrainingMicrocycleState state,
    CustomTrainingMicrocycleNotifier notifier,
    bool isMobile,
  ) {
    final microcycle = state.activeMicrocycle;
    final rider = state.selectedRider;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 340 : 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryAccent),
                      ),
                      child: const Text(
                        'KREATOR MIKROCYKLI',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '${rider.fullName} · FTP ${rider.physiology.ftpWatts} W',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  onSubmitted: notifier.updateMicrocycleName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    hintText: 'Nazwa mikrocyklu treningowego',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.goldAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetricChip(
                label: 'TYGODNIOWY TSS',
                value: microcycle.totalWeeklyTss.round().toString(),
                accent: AppColors.goldAccent,
              ),
              _MetricChip(
                label: 'CZAS',
                value: '${microcycle.totalHours.toStringAsFixed(1)} h',
                accent: AppColors.accentBlue,
              ),
              _MetricChip(
                label: 'SYNERGIA',
                value: '${state.projection.synergyScore}%',
                accent: AppColors.statusSuccess,
              ),
              _InteractiveActionButton(
                label: 'Zapisz Szablon',
                icon: Icons.bookmark_add_outlined,
                onPressed: notifier.saveCurrentAsTemplate,
                isPrimary: false,
              ),
              _InteractiveActionButton(
                label: 'Zastosuj Cykl',
                icon: Icons.play_arrow_rounded,
                onPressed:
                    state.validation.isValid && state.selectedRider.health.canTrain
                        ? notifier.applyActiveMicrocycle
                        : null,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelectorRow(
    CustomTrainingMicrocycleState state,
    CustomTrainingMicrocycleNotifier notifier,
    bool isMobile,
  ) {
    final presets = [
      MicrocycleGoalPreset.vo2maxPeak,
      MicrocycleGoalPreset.sweetSpotBase,
      MicrocycleGoalPreset.motorPacingClassics,
      MicrocycleGoalPreset.taperingPreRace,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SZABLONY MIKROCYKLI (VO2MAX / SWEET SPOT / MOTOR-PACING)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: presets.map((preset) {
              final selected = state.activeMicrocycle.preset == preset;
              return _PresetChipButton(
                label: preset.labelPl,
                selected: selected,
                onTap: () => notifier.loadPreset(preset),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekGrid(
    CustomTrainingMicrocycleState state,
    CustomTrainingMicrocycleNotifier notifier, {
    required int columns,
  }) {
    final sessions = state.activeMicrocycle.sessions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
              const Text(
                'PLAN TYGODNIA (PON – ND)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Polaryzacja: ${state.activeMicrocycle.polarizationScore.round()}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: columns == 2 ? 1.35 : 1.18,
            ),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isSelected = session.day == state.selectedDay;
              return _DaySessionCard(
                session: session,
                isSelected: isSelected,
                onTap: () => notifier.selectDay(session.day),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayEditorCard(
    CustomTrainingMicrocycleState state,
    CustomTrainingMicrocycleNotifier notifier,
    bool isMobile,
  ) {
    final session = state.selectedSession;
    final zoneColor = AppColors.getPowerZoneColor(session.primaryPowerZone);
    final isRest = session.workoutType == TrainingWorkoutType.restDay;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 24,
                decoration: BoxDecoration(
                  color: zoneColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'EDYTOR DNIA: ${session.day.labelPl.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${session.estimatedTss.round()} TSS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: zoneColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Jednostka treningowa',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TrainingWorkoutType>(
                value: session.workoutType,
                isExpanded: true,
                dropdownColor: AppColors.surfaceLight,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: TrainingWorkoutType.values.map((type) {
                  return DropdownMenuItem<TrainingWorkoutType>(
                    value: type,
                    child: Text(type.labelPl),
                  );
                }).toList(),
                onChanged: (nextType) {
                  if (nextType != null) {
                    notifier.updateDayWorkoutType(session.day, nextType);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              session.intervalStructure,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Czas trwania',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${session.durationMinutes} min',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isRest ? AppColors.textSecondary : zoneColor,
              thumbColor: isRest ? AppColors.textSecondary : AppColors.goldAccent,
              inactiveTrackColor: AppColors.cardBorder,
            ),
            child: Slider(
              value: session.durationMinutes.toDouble().clamp(0, 360),
              min: 0,
              max: 360,
              divisions: 24,
              onChanged: isRest
                  ? null
                  : (v) => notifier.updateDayDuration(session.day, v.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Intensywność (IF)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                session.intensityFactor.toStringAsFixed(2),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:
                  isRest ? AppColors.textSecondary : AppColors.primaryAccent,
              thumbColor: isRest ? AppColors.textSecondary : AppColors.goldAccent,
              inactiveTrackColor: AppColors.cardBorder,
            ),
            child: Slider(
              value: session.intensityFactor.clamp(0.45, 1.20),
              min: 0.45,
              max: 1.20,
              divisions: 15,
              onChanged: isRest
                  ? null
                  : (v) => notifier.updateDayIntensityFactor(session.day, v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionChartCard(CustomTrainingMicrocycleState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
              const Text(
                'PROGNOZA KRZYWEJ BANISTERA (CTL / ATL / TSB)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      state.projection.riskLevel.statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: state.projection.riskLevel.statusColor,
                  ),
                ),
                child: Text(
                  state.projection.riskLevel.labelPl,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: state.projection.riskLevel.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: MicrocycleLoadProjectionPainter(
                points: state.projection.dailyProjections,
                selectedDay: state.selectedDay,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysiologicalSummaryCard(
    CustomTrainingMicrocycleState state,
    CustomTrainingMicrocycleNotifier notifier,
  ) {
    final proj = state.projection;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGNOZOWANE ADAPTACJE FIZJOLOGICZNE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _ProjectionStatRow(
            label: 'Forma (CTL)',
            value:
                '${proj.initialCtl.toStringAsFixed(1)} → ${proj.projectedCtl.toStringAsFixed(1)}',
            delta:
                '${proj.deltaCtl >= 0 ? '+' : ''}${proj.deltaCtl.toStringAsFixed(1)}',
            color: AppColors.accentBlue,
          ),
          _ProjectionStatRow(
            label: 'Zmęczenie (ATL)',
            value:
                '${proj.initialAtl.toStringAsFixed(1)} → ${proj.projectedAtl.toStringAsFixed(1)}',
            delta:
                '${proj.deltaAtl >= 0 ? '+' : ''}${proj.deltaAtl.toStringAsFixed(1)}',
            color: AppColors.amberWarning,
          ),
          _ProjectionStatRow(
            label: 'Świeżość (TSB)',
            value:
                '${proj.initialTsb.toStringAsFixed(1)} → ${proj.projectedTsb.toStringAsFixed(1)}',
            delta:
                '${proj.deltaTsb >= 0 ? '+' : ''}${proj.deltaTsb.toStringAsFixed(1)}',
            color: proj.projectedTsb >= -15
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert,
          ),
          const Divider(color: AppColors.cardBorder, height: 20),
          _ProjectionStatRow(
            label: 'Szacowany zysk FTP / 5m',
            value:
                '+${proj.projectedFtpDeltaWatts.toStringAsFixed(1)} W / +${proj.projected5mWattsDelta.toStringAsFixed(1)} W',
            delta: '+${proj.projectedVo2maxDelta.toStringAsFixed(2)} VO2',
            color: AppColors.goldAccent,
          ),
          _ProjectionStatRow(
            label: 'Sprint / Drafting Motor-Pacing',
            value: '+${proj.projectedSprintWattsDelta.toStringAsFixed(1)} W',
            delta: '+${proj.projectedFlatAndDraftingGain.toStringAsFixed(1)} sk.',
            color: AppColors.cyanAccent,
          ),
          if (proj.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...proj.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.amberWarning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.amberWarning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner(String message, {required bool isError}) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
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
    final enabled = widget.onPressed != null;
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? baseColor.withValues(alpha: 0.75)
            : _hovered
                ? baseColor.withValues(alpha: 0.9)
                : baseColor;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.isPrimary
                      ? AppColors.goldAccent.withValues(alpha: 0.65)
                      : AppColors.cardBorder),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      enabled ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PresetChipButton> createState() => _PresetChipButtonState();
}

class _PresetChipButtonState extends State<_PresetChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.32)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected || _focused
                  ? AppColors.goldAccent
                  : AppColors.cardBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySessionCard extends StatefulWidget {
  final MicrocycleDaySession session;
  final bool isSelected;
  final VoidCallback onTap;

  const _DaySessionCard({
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DaySessionCard> createState() => _DaySessionCardState();
}

class _DaySessionCardState extends State<_DaySessionCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final zoneColor = AppColors.getPowerZoneColor(widget.session.primaryPowerZone);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.surfaceLight
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.7)
                    : AppColors.background),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected || _focused
                  ? AppColors.goldAccent
                  : AppColors.cardBorder,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.session.day.shortLabelPl.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: zoneColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.session.workoutType.shortCode,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: zoneColor,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                widget.session.workoutType.labelPl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.session.durationMinutes}\'',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '${widget.session.estimatedTss.round()} TSS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: zoneColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
}

class _ProjectionStatRow extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final Color color;

  const _ProjectionStatRow({
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              delta,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wykres prognozy dziennego TSS (słupki Z1–Z7) oraz krzywej CTL / ATL / TSB.
class MicrocycleLoadProjectionPainter extends CustomPainter {
  final List<MicrocycleDailyProjectionPoint> points;
  final MicrocycleDayOfWeek selectedDay;

  const MicrocycleLoadProjectionPainter({
    required this.points,
    required this.selectedDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const leftPad = 28.0;
    const rightPad = 12.0;
    const topPad = 12.0;
    const bottomPad = 24.0;

    final chartWidth = math.max(10.0, size.width - leftPad - rightPad);
    final chartHeight = math.max(10.0, size.height - topPad - bottomPad);

    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPad + (chartHeight / 3.0) * i;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartWidth, y),
        gridPaint,
      );
    }

    final maxTss = points.fold<double>(
      160.0,
      (prev, p) => math.max(prev, p.dailyTss),
    );
    final slotWidth = chartWidth / points.length;
    final barWidth = math.min(28.0, slotWidth * 0.48);

    // Słupki dziennego TSS w kolorze strefy mocy.
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final barHeight = (p.dailyTss / maxTss) * chartHeight * 0.72;
      final centerX = leftPad + slotWidth * (i + 0.5);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          topPad + chartHeight - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(6),
      );
      final zoneColor = AppColors.getPowerZoneColor(p.primaryPowerZone);
      final barPaint = Paint()
        ..color = zoneColor.withValues(
          alpha: p.day == selectedDay ? 0.85 : 0.45,
        );
      canvas.drawRRect(rect, barPaint);
    }

    // Linie CTL (niebieska) oraz ATL (pomarańczowa).
    double maxLoad = 100.0;
    for (final p in points) {
      maxLoad = math.max(maxLoad, math.max(p.ctl, p.atl));
    }

    final ctlPath = Path();
    final atlPath = Path();
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = leftPad + slotWidth * (i + 0.5);
      final yCtl = topPad + chartHeight - (p.ctl / maxLoad) * chartHeight;
      final yAtl = topPad + chartHeight - (p.atl / maxLoad) * chartHeight;
      if (i == 0) {
        ctlPath.moveTo(x, yCtl);
        atlPath.moveTo(x, yAtl);
      } else {
        ctlPath.lineTo(x, yCtl);
        atlPath.lineTo(x, yAtl);
      }
    }

    canvas.drawPath(
      ctlPath,
      Paint()
        ..color = AppColors.accentBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawPath(
      atlPath,
      Paint()
        ..color = AppColors.amberWarning
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // Etykiety dni tygodnia na osi X.
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final tp = TextPainter(
        text: TextSpan(
          text: p.day.shortLabelPl,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: p.day == selectedDay ? FontWeight.w700 : FontWeight.w500,
            color: p.day == selectedDay
                ? AppColors.goldAccent
                : AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final centerX = leftPad + slotWidth * (i + 0.5);
      tp.paint(
        canvas,
        Offset(centerX - tp.width / 2, topPad + chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MicrocycleLoadProjectionPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedDay != selectedDay;
  }
}
