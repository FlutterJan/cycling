import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';

/// 4 globalne lokalizacje Akademii Satelickich klubu WorldTour.
enum SatelliteAcademyRegionId {
  colombiaBoyaca,
  eastAfricaRiftValley,
  flandersKortrijk,
  sierraNevadaGranada;

  String toJson() => name;

  static SatelliteAcademyRegionId fromJson(String value) {
    return SatelliteAcademyRegionId.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SatelliteAcademyRegionId.sierraNevadaGranada,
    );
  }

  String get label {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return 'Kolumbia — Boyacá / Andy';
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return 'Afryka Wschodnia — Rift Valley';
      case SatelliteAcademyRegionId.flandersKortrijk:
        return 'Flandria — Kortrijk / Oudenaarde';
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return 'Sierra Nevada — CAR Granada';
    }
  }

  String get shortLabel {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return 'Kolumbia';
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return 'Afryka Wsch.';
      case SatelliteAcademyRegionId.flandersKortrijk:
        return 'Flandria';
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return 'Sierra Nevada';
    }
  }

  String get countryCode {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return 'COL';
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return 'KEN';
      case SatelliteAcademyRegionId.flandersKortrijk:
        return 'BEL';
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return 'ESP';
    }
  }

  String get cityLabel {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return 'Tunja / Paipa (Boyacá)';
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return 'Iten / Kigali (Rift Valley)';
      case SatelliteAcademyRegionId.flandersKortrijk:
        return 'Kortrijk / Oudenaarde';
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return 'Pradollano (Granada)';
    }
  }

  int get altitudeMeters {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return 2680;
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return 2400;
      case SatelliteAcademyRegionId.flandersKortrijk:
        return 20;
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return 2320;
    }
  }

  double get latitude {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return 5.5353;
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return 0.6703;
      case SatelliteAcademyRegionId.flandersKortrijk:
        return 50.8279;
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return 37.0956;
    }
  }

  double get longitude {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return -73.3678;
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return 35.5081;
      case SatelliteAcademyRegionId.flandersKortrijk:
        return 3.2649;
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return -3.3982;
    }
  }

  String get specialtyTitle {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return 'Hipoksja Andów & Lekcy Górale (<58 kg)';
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return 'Wydolność Tlenowa VO2max & Niski Mleczan';
      case SatelliteAcademyRegionId.flandersKortrijk:
        return 'Bruk (Kasseien), Wiatry Boczne & Aero';
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return 'Obozy Wysokogórskie GT & Szczyt Formy FTP';
    }
  }

  String get specialtyDescription {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return 'Ekstremalna baza na 2680 m n.p.m. w Boyacá. Przyspiesza adaptację do hipoksji i szkoli czystych górali z Kolumbii oraz Ekwadoru.';
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return 'Centrum wytrzymałościowe w Dolinie Wielkich Rowów. Buduje elitarny pułap tlenowy VO2max i odkrywa talenty z Kenii, Erytrei, Rwandy i Etiopii.';
      case SatelliteAcademyRegionId.flandersKortrijk:
        return 'Laboratorium klasyków północnych w sercu Flandrii. Szlifuje technikę jazdy po bruku, formowanie wachlarzy na wietrze oraz moc progową na krótkich ściankach.';
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return 'Ośrodek przygotowań przed Wielkimi Tourami (Live High – Train Low). Maksymalizuje superkompensację FTP, odporność na upał i regenerację w 3. tygodniu GT.';
    }
  }

  List<String> get primaryNationalities {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return const ['COL', 'ECU'];
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return const ['ERI', 'KEN', 'RWA', 'ETH'];
      case SatelliteAcademyRegionId.flandersKortrijk:
        return const ['BEL', 'NED'];
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return const ['ESP', 'POR', 'FRA'];
    }
  }

  List<RiderSpecialization> get primarySpecializations {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return const [
          RiderSpecialization.pureClimber,
          RiderSpecialization.gcClimber,
        ];
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return const [
          RiderSpecialization.pureClimber,
          RiderSpecialization.breakawaySpecialist,
          RiderSpecialization.puncher,
        ];
      case SatelliteAcademyRegionId.flandersKortrijk:
        return const [
          RiderSpecialization.classicCobbles,
          RiderSpecialization.timeTrialist,
          RiderSpecialization.versatileSprinter,
        ];
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return const [
          RiderSpecialization.gcClimber,
          RiderSpecialization.timeTrialist,
          RiderSpecialization.domestiqueEngine,
        ];
    }
  }

  Color get accentColor {
    switch (this) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        return AppColors.amberWarning;
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        return AppColors.statusSuccess;
      case SatelliteAcademyRegionId.flandersKortrijk:
        return AppColors.goldAccent;
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        return AppColors.accentBlue;
    }
  }
}

/// Status operacyjny pojedynczej Akademii Satelickiej.
enum SatelliteAcademyStatus {
  locked,
  establishing,
  operational,
  eliteFlagship;

  String toJson() => name;

  static SatelliteAcademyStatus fromJson(String value) {
    return SatelliteAcademyStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SatelliteAcademyStatus.locked,
    );
  }

  String get label {
    switch (this) {
      case SatelliteAcademyStatus.locked:
        return 'Niezbudowana';
      case SatelliteAcademyStatus.establishing:
        return 'W budowie';
      case SatelliteAcademyStatus.operational:
        return 'Operacyjna';
      case SatelliteAcademyStatus.eliteFlagship:
        return 'Elitarna Baza';
    }
  }

  Color get color {
    switch (this) {
      case SatelliteAcademyStatus.locked:
        return AppColors.textSecondary;
      case SatelliteAcademyStatus.establishing:
        return AppColors.amberWarning;
      case SatelliteAcademyStatus.operational:
        return AppColors.statusSuccess;
      case SatelliteAcademyStatus.eliteFlagship:
        return AppColors.goldAccent;
    }
  }
}

/// Tryb pracy i priorytet szkoleniowy akademii.
enum SatelliteAcademyFocusMode {
  talentScouting,
  altitudeCamp,
  skillMastery,
  balancedHybrid;

  String toJson() => name;

  static SatelliteAcademyFocusMode fromJson(String value) {
    return SatelliteAcademyFocusMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SatelliteAcademyFocusMode.balancedHybrid,
    );
  }

  String get label {
    switch (this) {
      case SatelliteAcademyFocusMode.talentScouting:
        return 'Skauting Talentów U19/U23';
      case SatelliteAcademyFocusMode.altitudeCamp:
        return 'Obozy Wysokogórskie Pro';
      case SatelliteAcademyFocusMode.skillMastery:
        return 'Szlifowanie Specjalizacji';
      case SatelliteAcademyFocusMode.balancedHybrid:
        return 'Tryb Zbalansowany';
    }
  }

  String get description {
    switch (this) {
      case SatelliteAcademyFocusMode.talentScouting:
        return '+45% tempa odkrywania lokalnych juniorów, standardowe obozy.';
      case SatelliteAcademyFocusMode.altitudeCamp:
        return '+35% zysku aklimatyzacji wysokościowej i VO2max dla kolarzy Pro.';
      case SatelliteAcademyFocusMode.skillMastery:
        return '+40% przyrostu umiejętności technicznych (bruk, zjazdy, TT).';
      case SatelliteAcademyFocusMode.balancedHybrid:
        return 'Równomierny rozwój skautingu regionalnego i obozów kadry.';
    }
  }
}

/// Intensywność bloku treningowego na zgrupowaniu w akademii.
enum AcademyCampIntensity {
  recoveryAcclimatization,
  standardBlock,
  peakSupercompensation;

  String toJson() => name;

  static AcademyCampIntensity fromJson(String value) {
    return AcademyCampIntensity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AcademyCampIntensity.standardBlock,
    );
  }

  String get label {
    switch (this) {
      case AcademyCampIntensity.recoveryAcclimatization:
        return 'Adaptacja / Lekki';
      case AcademyCampIntensity.standardBlock:
        return 'Blok Podstawowy';
      case AcademyCampIntensity.peakSupercompensation:
        return 'Szczytowy GT (Max)';
    }
  }

  double get gainMultiplier {
    switch (this) {
      case AcademyCampIntensity.recoveryAcclimatization:
        return 0.72;
      case AcademyCampIntensity.standardBlock:
        return 1.00;
      case AcademyCampIntensity.peakSupercompensation:
        return 1.38;
    }
  }

  double get fatiguePerDay {
    switch (this) {
      case AcademyCampIntensity.recoveryAcclimatization:
        return 0.6;
      case AcademyCampIntensity.standardBlock:
        return 1.4;
      case AcademyCampIntensity.peakSupercompensation:
        return 2.5;
    }
  }
}

/// Statyczna specyfikacja kosztowa i infrastrukturalna danej akademii.
class SatelliteAcademyBlueprint {
  final SatelliteAcademyRegionId regionId;
  final double setupCostEur;
  final double baseAnnualUpkeepEur;
  final List<double> upgradeCostsByTier; // index 0 -> tier 1->2, 1 -> 2->3, 2 -> 3->4
  final int baseProspectSlots;
  final int baseCampCapacity;
  final String climateProfile;
  final List<String> keyFacilities;

  const SatelliteAcademyBlueprint({
    required this.regionId,
    required this.setupCostEur,
    required this.baseAnnualUpkeepEur,
    required this.upgradeCostsByTier,
    required this.baseProspectSlots,
    required this.baseCampCapacity,
    required this.climateProfile,
    required this.keyFacilities,
  });

  double upgradeCostForNextTier(int currentTier) {
    if (currentTier <= 0) return setupCostEur;
    if (currentTier >= 4) return 0;
    return upgradeCostsByTier[currentTier - 1];
  }

  static const Map<SatelliteAcademyRegionId, SatelliteAcademyBlueprint> catalog = {
    SatelliteAcademyRegionId.colombiaBoyaca: SatelliteAcademyBlueprint(
      regionId: SatelliteAcademyRegionId.colombiaBoyaca,
      setupCostEur: 320000,
      baseAnnualUpkeepEur: 145000,
      upgradeCostsByTier: [260000, 420000, 680000],
      baseProspectSlots: 3,
      baseCampCapacity: 4,
      climateProfile: 'Chłodne Andy 12–18°C • 2680 m n.p.m.',
      keyFacilities: [
        'Baza wysokościowa Paipa',
        'Testy mleczanowe na podjazdach HC',
        'Siatka skautingowa Boyacá & Antioquia',
      ],
    ),
    SatelliteAcademyRegionId.eastAfricaRiftValley: SatelliteAcademyBlueprint(
      regionId: SatelliteAcademyRegionId.eastAfricaRiftValley,
      setupCostEur: 280000,
      baseAnnualUpkeepEur: 120000,
      upgradeCostsByTier: [220000, 380000, 620000],
      baseProspectSlots: 4,
      baseCampCapacity: 4,
      climateProfile: 'Równikowa wysokość 16–22°C • 2400 m n.p.m.',
      keyFacilities: [
        'Ośrodek wydolnościowy Iten–Kigali',
        'Laboratorium VO2max i VLaMax',
        'Program stypendialny U19 Rift Valley',
      ],
    ),
    SatelliteAcademyRegionId.flandersKortrijk: SatelliteAcademyBlueprint(
      regionId: SatelliteAcademyRegionId.flandersKortrijk,
      setupCostEur: 380000,
      baseAnnualUpkeepEur: 175000,
      upgradeCostsByTier: [310000, 490000, 760000],
      baseProspectSlots: 3,
      baseCampCapacity: 5,
      climateProfile: 'Wietrzny Atlantyk 4–14°C • Deszcz i bruk',
      keyFacilities: [
        'Tor brukowany & symulator wiatru bocznego',
        'Warsztat niskiego ciśnienia opon i wosku',
        'Skauting klasyków Beneluksu U19/U23',
      ],
    ),
    SatelliteAcademyRegionId.sierraNevadaGranada: SatelliteAcademyBlueprint(
      regionId: SatelliteAcademyRegionId.sierraNevadaGranada,
      setupCostEur: 420000,
      baseAnnualUpkeepEur: 195000,
      upgradeCostsByTier: [350000, 540000, 840000],
      baseProspectSlots: 3,
      baseCampCapacity: 6,
      climateProfile: 'Suchy klimat górski • 2320 m n.p.m.',
      keyFacilities: [
        'Komory hipoksyjne Live High – Train Low',
        'Komora termiczna +36°C przed TdF/Vueltą',
        'Centrum regeneracji i fizjologii GT',
      ],
    ),
  };
}

/// Młody talent wychowywany lub odkryty w lokalnej Akademii Satelickiej.
class SatelliteAcademyProspect {
  final String id;
  final String fullName;
  final String nationalityIso;
  final int age;
  final SatelliteAcademyRegionId regionId;
  final RiderSpecialization specialization;
  final int potential; // 50-99
  final int currentOvr; // 48-85
  final double weightKg;
  final int ftpWatts;
  final double vo2Max;
  final int cobblesRating;
  final int climbingRating;
  final int timeTrialRating;
  final int trainingWeeksCompleted;
  final int scoutingConfidence; // 40-100
  final bool isSignedToProRoster;
  final DateTime discoveredOn;

  const SatelliteAcademyProspect({
    required this.id,
    required this.fullName,
    required this.nationalityIso,
    required this.age,
    required this.regionId,
    required this.specialization,
    required this.potential,
    required this.currentOvr,
    required this.weightKg,
    required this.ftpWatts,
    required this.vo2Max,
    required this.cobblesRating,
    required this.climbingRating,
    required this.timeTrialRating,
    required this.trainingWeeksCompleted,
    required this.scoutingConfidence,
    required this.isSignedToProRoster,
    required this.discoveredOn,
  });

  double get wPerKg => weightKg > 0 ? ftpWatts / weightKg : 0.0;

  SatelliteAcademyProspect copyWith({
    String? id,
    String? fullName,
    String? nationalityIso,
    int? age,
    SatelliteAcademyRegionId? regionId,
    RiderSpecialization? specialization,
    int? potential,
    int? currentOvr,
    double? weightKg,
    int? ftpWatts,
    double? vo2Max,
    int? cobblesRating,
    int? climbingRating,
    int? timeTrialRating,
    int? trainingWeeksCompleted,
    int? scoutingConfidence,
    bool? isSignedToProRoster,
    DateTime? discoveredOn,
  }) {
    return SatelliteAcademyProspect(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      age: age ?? this.age,
      regionId: regionId ?? this.regionId,
      specialization: specialization ?? this.specialization,
      potential: potential ?? this.potential,
      currentOvr: currentOvr ?? this.currentOvr,
      weightKg: weightKg ?? this.weightKg,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      vo2Max: vo2Max ?? this.vo2Max,
      cobblesRating: cobblesRating ?? this.cobblesRating,
      climbingRating: climbingRating ?? this.climbingRating,
      timeTrialRating: timeTrialRating ?? this.timeTrialRating,
      trainingWeeksCompleted: trainingWeeksCompleted ?? this.trainingWeeksCompleted,
      scoutingConfidence: scoutingConfidence ?? this.scoutingConfidence,
      isSignedToProRoster: isSignedToProRoster ?? this.isSignedToProRoster,
      discoveredOn: discoveredOn ?? this.discoveredOn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'nationalityIso': nationalityIso,
        'age': age,
        'regionId': regionId.toJson(),
        'specialization': specialization.toJson(),
        'potential': potential,
        'currentOvr': currentOvr,
        'weightKg': weightKg,
        'ftpWatts': ftpWatts,
        'vo2Max': vo2Max,
        'cobblesRating': cobblesRating,
        'climbingRating': climbingRating,
        'timeTrialRating': timeTrialRating,
        'trainingWeeksCompleted': trainingWeeksCompleted,
        'scoutingConfidence': scoutingConfidence,
        'isSignedToProRoster': isSignedToProRoster,
        'discoveredOn': discoveredOn.toIso8601String(),
      };

  factory SatelliteAcademyProspect.fromJson(Map<String, dynamic> json) {
    return SatelliteAcademyProspect(
      id: (json['id'] as String?) ?? 'prospect_unknown',
      fullName: (json['fullName'] as String?) ?? 'Nieznany Junior',
      nationalityIso: (json['nationalityIso'] as String?) ?? 'COL',
      age: (json['age'] as num?)?.toInt() ?? 18,
      regionId: SatelliteAcademyRegionId.fromJson(
        (json['regionId'] as String?) ?? 'colombiaBoyaca',
      ),
      specialization: RiderSpecialization.fromJson(
        (json['specialization'] as String?) ?? 'pureClimber',
      ),
      potential: (json['potential'] as num?)?.toInt() ?? 78,
      currentOvr: (json['currentOvr'] as num?)?.toInt() ?? 62,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 62.0,
      ftpWatts: (json['ftpWatts'] as num?)?.toInt() ?? 340,
      vo2Max: (json['vo2Max'] as num?)?.toDouble() ?? 78.0,
      cobblesRating: (json['cobblesRating'] as num?)?.toInt() ?? 55,
      climbingRating: (json['climbingRating'] as num?)?.toInt() ?? 68,
      timeTrialRating: (json['timeTrialRating'] as num?)?.toInt() ?? 58,
      trainingWeeksCompleted: (json['trainingWeeksCompleted'] as num?)?.toInt() ?? 0,
      scoutingConfidence: (json['scoutingConfidence'] as num?)?.toInt() ?? 70,
      isSignedToProRoster: (json['isSignedToProRoster'] as bool?) ?? false,
      discoveredOn: DateTime.tryParse((json['discoveredOn'] as String?) ?? '') ??
          DateTime(2026, 1, 15),
    );
  }
}

/// Aktywny pobyt treningowy kolarza z kadry Pro w Akademii Satelickiej.
class ActiveAcademyTrainingStint {
  final String stintId;
  final String riderId;
  final String riderName;
  final SatelliteAcademyRegionId regionId;
  final SatelliteAcademyFocusMode focusMode;
  final AcademyCampIntensity intensity;
  final int durationDays;
  final int daysCompleted;
  final double altitudeGainPercent;
  final double ftpGainWatts;
  final double vo2MaxGain;
  final double cobblesGain;
  final double staminaGain;
  final double fatigueAccumulated;
  final bool isCompleted;

  const ActiveAcademyTrainingStint({
    required this.stintId,
    required this.riderId,
    required this.riderName,
    required this.regionId,
    required this.focusMode,
    required this.intensity,
    required this.durationDays,
    required this.daysCompleted,
    required this.altitudeGainPercent,
    required this.ftpGainWatts,
    required this.vo2MaxGain,
    required this.cobblesGain,
    required this.staminaGain,
    required this.fatigueAccumulated,
    required this.isCompleted,
  });

  double get progressRatio =>
      durationDays > 0 ? (daysCompleted / durationDays).clamp(0.0, 1.0) : 1.0;

  ActiveAcademyTrainingStint copyWith({
    String? stintId,
    String? riderId,
    String? riderName,
    SatelliteAcademyRegionId? regionId,
    SatelliteAcademyFocusMode? focusMode,
    AcademyCampIntensity? intensity,
    int? durationDays,
    int? daysCompleted,
    double? altitudeGainPercent,
    double? ftpGainWatts,
    double? vo2MaxGain,
    double? cobblesGain,
    double? staminaGain,
    double? fatigueAccumulated,
    bool? isCompleted,
  }) {
    return ActiveAcademyTrainingStint(
      stintId: stintId ?? this.stintId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      regionId: regionId ?? this.regionId,
      focusMode: focusMode ?? this.focusMode,
      intensity: intensity ?? this.intensity,
      durationDays: durationDays ?? this.durationDays,
      daysCompleted: daysCompleted ?? this.daysCompleted,
      altitudeGainPercent: altitudeGainPercent ?? this.altitudeGainPercent,
      ftpGainWatts: ftpGainWatts ?? this.ftpGainWatts,
      vo2MaxGain: vo2MaxGain ?? this.vo2MaxGain,
      cobblesGain: cobblesGain ?? this.cobblesGain,
      staminaGain: staminaGain ?? this.staminaGain,
      fatigueAccumulated: fatigueAccumulated ?? this.fatigueAccumulated,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'stintId': stintId,
        'riderId': riderId,
        'riderName': riderName,
        'regionId': regionId.toJson(),
        'focusMode': focusMode.toJson(),
        'intensity': intensity.toJson(),
        'durationDays': durationDays,
        'daysCompleted': daysCompleted,
        'altitudeGainPercent': altitudeGainPercent,
        'ftpGainWatts': ftpGainWatts,
        'vo2MaxGain': vo2MaxGain,
        'cobblesGain': cobblesGain,
        'staminaGain': staminaGain,
        'fatigueAccumulated': fatigueAccumulated,
        'isCompleted': isCompleted,
      };

  factory ActiveAcademyTrainingStint.fromJson(Map<String, dynamic> json) {
    return ActiveAcademyTrainingStint(
      stintId: (json['stintId'] as String?) ?? 'stint_unknown',
      riderId: (json['riderId'] as String?) ?? 'rider_unknown',
      riderName: (json['riderName'] as String?) ?? 'Kolarz Pro',
      regionId: SatelliteAcademyRegionId.fromJson(
        (json['regionId'] as String?) ?? 'sierraNevadaGranada',
      ),
      focusMode: SatelliteAcademyFocusMode.fromJson(
        (json['focusMode'] as String?) ?? 'altitudeCamp',
      ),
      intensity: AcademyCampIntensity.fromJson(
        (json['intensity'] as String?) ?? 'standardBlock',
      ),
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 14,
      daysCompleted: (json['daysCompleted'] as num?)?.toInt() ?? 0,
      altitudeGainPercent: (json['altitudeGainPercent'] as num?)?.toDouble() ?? 0.0,
      ftpGainWatts: (json['ftpGainWatts'] as num?)?.toDouble() ?? 0.0,
      vo2MaxGain: (json['vo2MaxGain'] as num?)?.toDouble() ?? 0.0,
      cobblesGain: (json['cobblesGain'] as num?)?.toDouble() ?? 0.0,
      staminaGain: (json['staminaGain'] as num?)?.toDouble() ?? 0.0,
      fatigueAccumulated: (json['fatigueAccumulated'] as num?)?.toDouble() ?? 0.0,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }
}

/// Stan operacyjny pojedynczej Akademii Satelickiej w sieci klubu.
class SatelliteAcademyNode {
  final SatelliteAcademyRegionId regionId;
  final int tier; // 0 = niezbudowana, 1..4 = poziomy rozwoju
  final SatelliteAcademyStatus status;
  final SatelliteAcademyFocusMode focusMode;
  final double annualBudgetEur;
  final String headCoachName;
  final int headCoachRating; // 65..99
  final double facilityCondition; // 0..100
  final double reputationScore; // 0..100
  final List<SatelliteAcademyProspect> prospects;
  final List<ActiveAcademyTrainingStint> activeStints;
  final int totalGraduatesPromoted;
  final DateTime lastUpdatedAt;

  const SatelliteAcademyNode({
    required this.regionId,
    required this.tier,
    required this.status,
    required this.focusMode,
    required this.annualBudgetEur,
    required this.headCoachName,
    required this.headCoachRating,
    required this.facilityCondition,
    required this.reputationScore,
    required this.prospects,
    required this.activeStints,
    required this.totalGraduatesPromoted,
    required this.lastUpdatedAt,
  });

  SatelliteAcademyBlueprint get blueprint =>
      SatelliteAcademyBlueprint.catalog[regionId]!;

  bool get isBuilt => tier > 0 && status != SatelliteAcademyStatus.locked;

  int get maxProspectSlots =>
      tier <= 0 ? 0 : blueprint.baseProspectSlots + (tier - 1) * 2;

  int get maxCampCapacity =>
      tier <= 0 ? 0 : blueprint.baseCampCapacity + (tier - 1) * 2;

  double get nextUpgradeCostEur => blueprint.upgradeCostForNextTier(tier);

  int get activeCampRiderCount =>
      activeStints.where((s) => !s.isCompleted).length;

  int get availableProspectCount =>
      prospects.where((p) => !p.isSignedToProRoster).length;

  double get efficiencyMultiplier {
    if (!isBuilt) return 0.0;
    final tierBonus = 0.75 + tier * 0.18;
    final coachFactor = 0.80 + (headCoachRating / 100.0) * 0.35;
    final conditionFactor = 0.65 + (facilityCondition / 100.0) * 0.35;
    return (tierBonus * coachFactor * conditionFactor).clamp(0.5, 1.85);
  }

  SatelliteAcademyNode copyWith({
    SatelliteAcademyRegionId? regionId,
    int? tier,
    SatelliteAcademyStatus? status,
    SatelliteAcademyFocusMode? focusMode,
    double? annualBudgetEur,
    String? headCoachName,
    int? headCoachRating,
    double? facilityCondition,
    double? reputationScore,
    List<SatelliteAcademyProspect>? prospects,
    List<ActiveAcademyTrainingStint>? activeStints,
    int? totalGraduatesPromoted,
    DateTime? lastUpdatedAt,
  }) {
    return SatelliteAcademyNode(
      regionId: regionId ?? this.regionId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      focusMode: focusMode ?? this.focusMode,
      annualBudgetEur: annualBudgetEur ?? this.annualBudgetEur,
      headCoachName: headCoachName ?? this.headCoachName,
      headCoachRating: headCoachRating ?? this.headCoachRating,
      facilityCondition: facilityCondition ?? this.facilityCondition,
      reputationScore: reputationScore ?? this.reputationScore,
      prospects: prospects ?? this.prospects,
      activeStints: activeStints ?? this.activeStints,
      totalGraduatesPromoted:
          totalGraduatesPromoted ?? this.totalGraduatesPromoted,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'regionId': regionId.toJson(),
        'tier': tier,
        'status': status.toJson(),
        'focusMode': focusMode.toJson(),
        'annualBudgetEur': annualBudgetEur,
        'headCoachName': headCoachName,
        'headCoachRating': headCoachRating,
        'facilityCondition': facilityCondition,
        'reputationScore': reputationScore,
        'prospects': prospects.map((e) => e.toJson()).toList(),
        'activeStints': activeStints.map((e) => e.toJson()).toList(),
        'totalGraduatesPromoted': totalGraduatesPromoted,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory SatelliteAcademyNode.fromJson(Map<String, dynamic> json) {
    final rawProspects = json['prospects'] as List<dynamic>? ?? const [];
    final rawStints = json['activeStints'] as List<dynamic>? ?? const [];
    return SatelliteAcademyNode(
      regionId: SatelliteAcademyRegionId.fromJson(
        (json['regionId'] as String?) ?? 'sierraNevadaGranada',
      ),
      tier: (json['tier'] as num?)?.toInt() ?? 0,
      status: SatelliteAcademyStatus.fromJson(
        (json['status'] as String?) ?? 'locked',
      ),
      focusMode: SatelliteAcademyFocusMode.fromJson(
        (json['focusMode'] as String?) ?? 'balancedHybrid',
      ),
      annualBudgetEur: (json['annualBudgetEur'] as num?)?.toDouble() ?? 0.0,
      headCoachName: (json['headCoachName'] as String?) ?? 'Dyrektor Akademii',
      headCoachRating: (json['headCoachRating'] as num?)?.toInt() ?? 75,
      facilityCondition:
          (json['facilityCondition'] as num?)?.toDouble() ?? 100.0,
      reputationScore: (json['reputationScore'] as num?)?.toDouble() ?? 35.0,
      prospects: rawProspects
          .whereType<Map<String, dynamic>>()
          .map(SatelliteAcademyProspect.fromJson)
          .toList(),
      activeStints: rawStints
          .whereType<Map<String, dynamic>>()
          .map(ActiveAcademyTrainingStint.fromJson)
          .toList(),
      totalGraduatesPromoted:
          (json['totalGraduatesPromoted'] as num?)?.toInt() ?? 0,
      lastUpdatedAt: DateTime.tryParse((json['lastUpdatedAt'] as String?) ?? '') ??
          DateTime(2026, 1, 1),
    );
  }
}

/// Wynik operacji wykonanej na sieci Akademii Satelickich.
class AcademyNetworkOperationResult {
  final bool success;
  final String message;
  final double costEur;
  final SatelliteAcademyNode? updatedNode;
  final SatelliteAcademyProspect? newProspect;
  final List<ActiveAcademyTrainingStint> completedStints;

  const AcademyNetworkOperationResult({
    required this.success,
    required this.message,
    this.costEur = 0.0,
    this.updatedNode,
    this.newProspect,
    this.completedStints = const [],
  });
}

/// Zbiorcze statystyki i KPI całej sieci Globalnych Akademii Satelickich.
class GlobalSatelliteAcademyNetworkSummary {
  final int totalCenters;
  final int activeCenters;
  final int eliteCenters;
  final double totalAnnualUpkeepEur;
  final int totalProspectsInPipeline;
  final int totalActiveCampRiders;
  final int totalGraduatesPromoted;
  final double averageTier;
  final double networkPrestigeScore;
  final double altitudeCoverageScore;

  const GlobalSatelliteAcademyNetworkSummary({
    required this.totalCenters,
    required this.activeCenters,
    required this.eliteCenters,
    required this.totalAnnualUpkeepEur,
    required this.totalProspectsInPipeline,
    required this.totalActiveCampRiders,
    required this.totalGraduatesPromoted,
    required this.averageTier,
    required this.networkPrestigeScore,
    required this.altitudeCoverageScore,
  });
}

/// Silnik domenowy zarządzania Systemem Globalnych Akademii Satelickich.
class GlobalSatelliteTrainingCentersService {
  const GlobalSatelliteTrainingCentersService();

  static const double maintenanceCostPerPointEur = 1200.0;
  static const double manualScoutingCostEur = 28000.0;

  static const Map<SatelliteAcademyRegionId, List<String>> _firstNamesByRegion = {
    SatelliteAcademyRegionId.colombiaBoyaca: [
      'Santiago',
      'Mateo',
      'Esteban',
      'Jhonatan',
      'Camilo',
      'Cristian',
      'Daniel',
      'Nairo',
    ],
    SatelliteAcademyRegionId.eastAfricaRiftValley: [
      'Biniam',
      'Natnael',
      'Samuel',
      'Kiprop',
      'Henok',
      'Moise',
      'Amanuel',
      'Joseph',
    ],
    SatelliteAcademyRegionId.flandersKortrijk: [
      'Wout',
      'Jasper',
      'Tiesj',
      'Arno',
      'Thibau',
      'Sander',
      'Dries',
      'Kobe',
    ],
    SatelliteAcademyRegionId.sierraNevadaGranada: [
      'Pablo',
      'Juan',
      'Carlos',
      'Iker',
      'Raúl',
      'Mikel',
      'Afonso',
      'Hugo',
    ],
  };

  static const Map<SatelliteAcademyRegionId, List<String>> _lastNamesByRegion = {
    SatelliteAcademyRegionId.colombiaBoyaca: [
      'Buitrago',
      'Martínez',
      'Chaves',
      'Rubio',
      'Higuita',
      'Sosa',
      'Cepeda',
      'Rivera',
    ],
    SatelliteAcademyRegionId.eastAfricaRiftValley: [
      'Girmay',
      'Tesfazion',
      'Kudus',
      'Mugisha',
      'Kiptoo',
      'Berhane',
      'Niyonkuru',
      'Gebremariam',
    ],
    SatelliteAcademyRegionId.flandersKortrijk: [
      'Van Wilder',
      'De Lie',
      'Vermeersch',
      'Vandenbergh',
      'Van Gestel',
      'Campaenaerts',
      'De Plus',
      'Boonen',
    ],
    SatelliteAcademyRegionId.sierraNevadaGranada: [
      'Rodríguez',
      'Ayuso',
      'Romeo',
      'Landa',
      'Morgado',
      'Aranburu',
      'Lazkano',
      'Castrillo',
    ],
  };

  static const Map<SatelliteAcademyRegionId, String> _defaultCoaches = {
    SatelliteAcademyRegionId.colombiaBoyaca: 'Luis Alberto Herrera',
    SatelliteAcademyRegionId.eastAfricaRiftValley: 'Tsegay Berhane',
    SatelliteAcademyRegionId.flandersKortrijk: 'Johan Museeuw-De Smet',
    SatelliteAcademyRegionId.sierraNevadaGranada: 'Iñigo San Millán',
  };

  /// Tworzy początkową mapę 4 Akademii Satelickich (Sierra Nevada startuje na Poziomie 1).
  Map<SatelliteAcademyRegionId, SatelliteAcademyNode> createInitialNetwork({
    DateTime? currentDate,
    bool unlockStarterSierraNevada = true,
  }) {
    final now = currentDate ?? DateTime(2026, 1, 15);
    final result = <SatelliteAcademyRegionId, SatelliteAcademyNode>{};

    for (final region in SatelliteAcademyRegionId.values) {
      final blueprint = SatelliteAcademyBlueprint.catalog[region]!;
      final isStarter =
          unlockStarterSierraNevada &&
          region == SatelliteAcademyRegionId.sierraNevadaGranada;

      result[region] = SatelliteAcademyNode(
        regionId: region,
        tier: isStarter ? 1 : 0,
        status: isStarter
            ? SatelliteAcademyStatus.operational
            : SatelliteAcademyStatus.locked,
        focusMode: isStarter
            ? SatelliteAcademyFocusMode.altitudeCamp
            : SatelliteAcademyFocusMode.balancedHybrid,
        annualBudgetEur: isStarter ? blueprint.baseAnnualUpkeepEur : 0.0,
        headCoachName: _defaultCoaches[region] ?? 'Dyrektor Lokalny',
        headCoachRating: isStarter ? 82 : 76,
        facilityCondition: 100.0,
        reputationScore: isStarter ? 58.0 : 25.0,
        prospects: isStarter
            ? [
                generateRegionalProspect(
                  regionId: region,
                  academyTier: 1,
                  currentDate: now,
                  seed: 202601,
                ),
              ]
            : const [],
        activeStints: const [],
        totalGraduatesPromoted: 0,
        lastUpdatedAt: now,
      );
    }

    return result;
  }

  /// Odblokowuje nową akademię (Poziom 0 -> 1) lub rozbudowuje ją do wyższego poziomu (max 4).
  AcademyNetworkOperationResult unlockOrUpgradeAcademy({
    required SatelliteAcademyNode node,
    required double availableBudgetEur,
    required DateTime currentDate,
    int seed = 42,
  }) {
    if (node.tier >= 4) {
      return AcademyNetworkOperationResult(
        success: false,
        message:
            '${node.regionId.shortLabel} osiągnęła już maksymalny Poziom 4 (Elitarna Baza).',
      );
    }

    final cost = node.nextUpgradeCostEur;
    if (availableBudgetEur < cost) {
      return AcademyNetworkOperationResult(
        success: false,
        message:
            'Niewystarczający budżet: wymagane ${Formatters.formatCurrency(cost)} (dostępne ${Formatters.formatCurrency(availableBudgetEur)}).',
      );
    }

    final nextTier = node.tier + 1;
    final blueprint = node.blueprint;
    final nextUpkeep = blueprint.baseAnnualUpkeepEur * (1.0 + (nextTier - 1) * 0.35);
    final nextStatus = nextTier >= 4
        ? SatelliteAcademyStatus.eliteFlagship
        : SatelliteAcademyStatus.operational;

    final updatedProspects = List<SatelliteAcademyProspect>.from(node.prospects);
    SatelliteAcademyProspect? bonusProspect;
    if (nextTier == 1 && updatedProspects.isEmpty) {
      bonusProspect = generateRegionalProspect(
        regionId: node.regionId,
        academyTier: nextTier,
        currentDate: currentDate,
        seed: seed + node.regionId.index * 97,
      );
      updatedProspects.add(bonusProspect);
    }

    final updated = node.copyWith(
      tier: nextTier,
      status: nextStatus,
      annualBudgetEur: nextUpkeep,
      headCoachRating: math.min(99, node.headCoachRating + 4),
      facilityCondition: 100.0,
      reputationScore: (node.reputationScore + 12.0).clamp(0.0, 100.0),
      prospects: updatedProspects,
      lastUpdatedAt: currentDate,
    );

    final actionLabel = node.tier == 0 ? 'Otwarto akademię' : 'Rozbudowano akademię';
    return AcademyNetworkOperationResult(
      success: true,
      message:
          '$actionLabel ${node.regionId.shortLabel} do Poziomu $nextTier (${nextStatus.label}).',
      costEur: cost,
      updatedNode: updated,
      newProspect: bonusProspect,
    );
  }

  /// Zmienia priorytet szkoleniowo-skautingowy akademii.
  AcademyNetworkOperationResult changeFocusMode({
    required SatelliteAcademyNode node,
    required SatelliteAcademyFocusMode focusMode,
    required DateTime currentDate,
  }) {
    if (!node.isBuilt) {
      return AcademyNetworkOperationResult(
        success: false,
        message:
            'Najpierw otwórz akademię ${node.regionId.shortLabel}, aby zmienić jej priorytet.',
      );
    }

    final updated = node.copyWith(
      focusMode: focusMode,
      lastUpdatedAt: currentDate,
    );

    return AcademyNetworkOperationResult(
      success: true,
      message:
          'Ustawiono tryb "${focusMode.label}" w ${node.regionId.shortLabel}.',
      updatedNode: updated,
    );
  }

  /// Wysyła kolarza kadry Pro na obóz wysokogórski / specjalistyczny do wybranej akademii.
  AcademyNetworkOperationResult enrollRiderInCamp({
    required SatelliteAcademyNode node,
    required String riderId,
    required String riderName,
    required int durationDays,
    required AcademyCampIntensity intensity,
    required DateTime currentDate,
  }) {
    if (!node.isBuilt) {
      return AcademyNetworkOperationResult(
        success: false,
        message:
            'Akademia ${node.regionId.shortLabel} nie jest jeszcze zbudowana.',
      );
    }
    if (riderId.trim().isEmpty || riderName.trim().isEmpty) {
      return const AcademyNetworkOperationResult(
        success: false,
        message: 'Nieprawidłowe dane kolarza do wysłania na obóz.',
      );
    }
    if (durationDays < 7 || durationDays > 28) {
      return const AcademyNetworkOperationResult(
        success: false,
        message: 'Długość obozu musi mieścić się w przedziale 7–28 dni.',
      );
    }

    final alreadyInCamp = node.activeStints.any(
      (s) => !s.isCompleted && s.riderId == riderId,
    );
    if (alreadyInCamp) {
      return AcademyNetworkOperationResult(
        success: false,
        message: '$riderName przebywa już na obozie w ${node.regionId.shortLabel}.',
      );
    }

    if (node.activeCampRiderCount >= node.maxCampCapacity) {
      return AcademyNetworkOperationResult(
        success: false,
        message:
            'Brak wolnych miejsc w ośrodku ${node.regionId.shortLabel} (${node.activeCampRiderCount}/${node.maxCampCapacity}). Rozbuduj akademię.',
      );
    }

    final stint = ActiveAcademyTrainingStint(
      stintId: 'stint_${node.regionId.name}_${riderId}_${currentDate.millisecondsSinceEpoch}',
      riderId: riderId,
      riderName: riderName,
      regionId: node.regionId,
      focusMode: node.focusMode,
      intensity: intensity,
      durationDays: durationDays,
      daysCompleted: 0,
      altitudeGainPercent: 0.0,
      ftpGainWatts: 0.0,
      vo2MaxGain: 0.0,
      cobblesGain: 0.0,
      staminaGain: 0.0,
      fatigueAccumulated: 0.0,
      isCompleted: false,
    );

    final updated = node.copyWith(
      activeStints: [...node.activeStints, stint],
      lastUpdatedAt: currentDate,
    );

    return AcademyNetworkOperationResult(
      success: true,
      message:
          'Wysłano $riderName na $durationDays-dniowy obóz (${intensity.label}) do ${node.regionId.shortLabel}.',
      updatedNode: updated,
    );
  }

  /// Przeprowadza celowaną akcję skautingową w regionie akademii.
  AcademyNetworkOperationResult scoutLocalProspect({
    required SatelliteAcademyNode node,
    required double availableBudgetEur,
    required DateTime currentDate,
    int seed = 101,
  }) {
    if (!node.isBuilt) {
      return AcademyNetworkOperationResult(
        success: false,
        message: 'Akademia ${node.regionId.shortLabel} jest niezbudowana.',
      );
    }
    if (node.availableProspectCount >= node.maxProspectSlots) {
      return AcademyNetworkOperationResult(
        success: false,
        message:
            'Brak wolnych miejsc dla juniorów w ${node.regionId.shortLabel} (${node.availableProspectCount}/${node.maxProspectSlots}).',
      );
    }
    if (availableBudgetEur < manualScoutingCostEur) {
      return AcademyNetworkOperationResult(
        success: false,
        message:
            'Koszt misji skautingowej to ${Formatters.formatCurrency(manualScoutingCostEur)}.',
      );
    }

    final prospect = generateRegionalProspect(
      regionId: node.regionId,
      academyTier: node.tier,
      currentDate: currentDate,
      seed: seed + node.prospects.length * 31 + currentDate.day,
      scoutingFocusBonus: node.focusMode == SatelliteAcademyFocusMode.talentScouting,
    );

    final updated = node.copyWith(
      prospects: [...node.prospects, prospect],
      reputationScore: (node.reputationScore + 1.5).clamp(0.0, 100.0),
      lastUpdatedAt: currentDate,
    );

    return AcademyNetworkOperationResult(
      success: true,
      message:
          'Odkryto talent: ${prospect.fullName} (${prospect.nationalityIso}, ${prospect.age} l., POT ${prospect.potential}).',
      costEur: manualScoutingCostEur,
      updatedNode: updated,
      newProspect: prospect,
    );
  }

  /// Podpisuje kontrakt zawodowy z wychowankiem akademii.
  AcademyNetworkOperationResult promoteProspectToProRoster({
    required SatelliteAcademyNode node,
    required String prospectId,
    required DateTime currentDate,
  }) {
    final idx = node.prospects.indexWhere((p) => p.id == prospectId);
    if (idx < 0) {
      return const AcademyNetworkOperationResult(
        success: false,
        message: 'Nie znaleziono wskazanego wychowanka w akademii.',
      );
    }

    final target = node.prospects[idx];
    if (target.isSignedToProRoster) {
      return AcademyNetworkOperationResult(
        success: false,
        message: '${target.fullName} został już awansowany do kadry Pro.',
      );
    }

    final updatedProspects = List<SatelliteAcademyProspect>.from(node.prospects);
    updatedProspects[idx] = target.copyWith(isSignedToProRoster: true);

    final updated = node.copyWith(
      prospects: updatedProspects,
      totalGraduatesPromoted: node.totalGraduatesPromoted + 1,
      reputationScore: (node.reputationScore + 4.0).clamp(0.0, 100.0),
      lastUpdatedAt: currentDate,
    );

    return AcademyNetworkOperationResult(
      success: true,
      message:
          'Awansowano wychowanka ${target.fullName} (${target.wPerKg.toStringAsFixed(2)} W/kg) do drużyny!',
      updatedNode: updated,
    );
  }

  /// Konserwacja i odnowienie sprzętu/infrastruktury akademii do 100%.
  AcademyNetworkOperationResult maintainFacilities({
    required SatelliteAcademyNode node,
    required double availableBudgetEur,
    required DateTime currentDate,
  }) {
    if (!node.isBuilt) {
      return const AcademyNetworkOperationResult(
        success: false,
        message: 'Nie można serwisować niezbudowanej akademii.',
      );
    }
    final missingCondition = (100.0 - node.facilityCondition).clamp(0.0, 100.0);
    if (missingCondition < 1.0) {
      return AcademyNetworkOperationResult(
        success: false,
        message: 'Infrastruktura ${node.regionId.shortLabel} jest w idealnym stanie.',
      );
    }

    final cost = missingCondition * maintenanceCostPerPointEur;
    if (availableBudgetEur < cost) {
      return AcademyNetworkOperationResult(
        success: false,
        message:
            'Brak środków na konserwację (${Formatters.formatCurrency(cost)}).',
      );
    }

    final updated = node.copyWith(
      facilityCondition: 100.0,
      lastUpdatedAt: currentDate,
    );

    return AcademyNetworkOperationResult(
      success: true,
      message:
          'Odnowiono infrastrukturę ${node.regionId.shortLabel} do 100%.',
      costEur: cost,
      updatedNode: updated,
    );
  }

  /// Przesuwa symulację całej sieci o [days] dni: trenuje kolarzy na obozach i rozwija juniorów.
  Map<SatelliteAcademyRegionId, SatelliteAcademyNode> advanceNetworkDays({
    required Map<SatelliteAcademyRegionId, SatelliteAcademyNode> network,
    required int days,
    required DateTime newCurrentDate,
    int seed = 777,
  }) {
    if (days <= 0) return network;

    final updatedMap = <SatelliteAcademyRegionId, SatelliteAcademyNode>{};

    for (final entry in network.entries) {
      final node = entry.value;
      if (!node.isBuilt) {
        updatedMap[entry.key] = node;
        continue;
      }

      final eff = node.efficiencyMultiplier;
      final isAltitudeSite = node.regionId.altitudeMeters >= 2000;
      final altitudeCampBonus =
          node.focusMode == SatelliteAcademyFocusMode.altitudeCamp ? 1.35 : 1.0;
      final skillMasteryBonus =
          node.focusMode == SatelliteAcademyFocusMode.skillMastery ? 1.40 : 1.0;

      // 1. Aktualizacja aktywnych obozów kolarzy Pro
      final updatedStints = <ActiveAcademyTrainingStint>[];
      for (final stint in node.activeStints) {
        if (stint.isCompleted) {
          updatedStints.add(stint);
          continue;
        }

        final remainingDays = math.max(0, stint.durationDays - stint.daysCompleted);
        final appliedDays = math.min(days, remainingDays);
        final nextDaysCompleted = stint.daysCompleted + appliedDays;
        final done = nextDaysCompleted >= stint.durationDays;

        final dayFactor =
            appliedDays * eff * stint.intensity.gainMultiplier * 0.1;

        final altDelta = isAltitudeSite
            ? dayFactor * 0.42 * altitudeCampBonus
            : dayFactor * 0.05;

        double ftpDelta = dayFactor * 0.55;
        double vo2Delta = dayFactor * 0.09;
        double cobblesDelta = 0.0;
        double staminaDelta = dayFactor * 0.08;

        switch (node.regionId) {
          case SatelliteAcademyRegionId.colombiaBoyaca:
            ftpDelta *= 1.10;
            vo2Delta *= 1.25;
            staminaDelta *= 1.15;
            break;
          case SatelliteAcademyRegionId.eastAfricaRiftValley:
            vo2Delta *= 1.45;
            staminaDelta *= 1.30;
            break;
          case SatelliteAcademyRegionId.flandersKortrijk:
            cobblesDelta = dayFactor * 0.48 * skillMasteryBonus;
            ftpDelta *= 1.05;
            break;
          case SatelliteAcademyRegionId.sierraNevadaGranada:
            ftpDelta *= 1.30 * altitudeCampBonus;
            vo2Delta *= 1.18;
            staminaDelta *= 1.25;
            break;
        }

        updatedStints.add(
          stint.copyWith(
            daysCompleted: nextDaysCompleted,
            altitudeGainPercent:
                (stint.altitudeGainPercent + altDelta).clamp(0.0, 10.0),
            ftpGainWatts: (stint.ftpGainWatts + ftpDelta).clamp(0.0, 28.0),
            vo2MaxGain: (stint.vo2MaxGain + vo2Delta).clamp(0.0, 4.5),
            cobblesGain: (stint.cobblesGain + cobblesDelta).clamp(0.0, 8.0),
            staminaGain: (stint.staminaGain + staminaDelta).clamp(0.0, 6.0),
            fatigueAccumulated:
                stint.fatigueAccumulated + appliedDays * stint.intensity.fatiguePerDay,
            isCompleted: done,
          ),
        );
      }

      // 2. Rozwój juniorów w akademii (co pełny tydzień lub proporcjonalnie)
      final weeksGained = math.max(1, (days / 7).floor());
      final updatedProspects = node.prospects.map((prospect) {
        if (prospect.isSignedToProRoster) return prospect;
        final room = math.max(0, prospect.potential - prospect.currentOvr);
        final growth = room > 0 && days >= 5
            ? math.min(room, (eff * (days / 14.0)).round())
            : 0;
        final ftpBoost = (growth * 3.5).round();
        return prospect.copyWith(
          currentOvr: prospect.currentOvr + growth,
          ftpWatts: prospect.ftpWatts + ftpBoost,
          climbingRating: node.regionId == SatelliteAcademyRegionId.colombiaBoyaca ||
                  node.regionId == SatelliteAcademyRegionId.sierraNevadaGranada
              ? math.min(95, prospect.climbingRating + growth)
              : prospect.climbingRating,
          cobblesRating: node.regionId == SatelliteAcademyRegionId.flandersKortrijk
              ? math.min(95, prospect.cobblesRating + growth)
              : prospect.cobblesRating,
          trainingWeeksCompleted: prospect.trainingWeeksCompleted + weeksGained,
          scoutingConfidence:
              math.min(100, prospect.scoutingConfidence + math.min(6, days)),
        );
      }).toList();

      // 3. Zużycie infrastruktury
      final conditionWear = days * (0.22 + node.activeCampRiderCount * 0.06);
      final nextCondition = (node.facilityCondition - conditionWear).clamp(25.0, 100.0);

      updatedMap[entry.key] = node.copyWith(
        prospects: updatedProspects,
        activeStints: updatedStints,
        facilityCondition: nextCondition,
        lastUpdatedAt: newCurrentDate,
      );
    }

    return updatedMap;
  }

  /// Generuje autentycznego wychowanka zgodnego z profilem fizjologicznym regionu.
  SatelliteAcademyProspect generateRegionalProspect({
    required SatelliteAcademyRegionId regionId,
    required int academyTier,
    required DateTime currentDate,
    int seed = 1,
    bool scoutingFocusBonus = false,
  }) {
    final rng = math.Random(seed + regionId.index * 997);
    final firstNames = _firstNamesByRegion[regionId]!;
    final lastNames = _lastNamesByRegion[regionId]!;
    final fullName =
        '${firstNames[rng.nextInt(firstNames.length)]} ${lastNames[rng.nextInt(lastNames.length)]}';

    final nationalities = regionId.primaryNationalities;
    final nat = nationalities[rng.nextInt(nationalities.length)];
    final specs = regionId.primarySpecializations;
    final spec = specs[rng.nextInt(specs.length)];

    final tierBoost = (academyTier - 1) * 3 + (scoutingFocusBonus ? 2 : 0);
    final potential = (74 + tierBoost + rng.nextInt(17)).clamp(68, 97);
    final currentOvr = (56 + tierBoost + rng.nextInt(10)).clamp(52, potential - 4);
    final age = 17 + rng.nextInt(3);

    double weightKg;
    int ftpWatts;
    double vo2Max;
    int cobbles;
    int climbing;
    int tt;

    switch (regionId) {
      case SatelliteAcademyRegionId.colombiaBoyaca:
        weightKg = 52.5 + rng.nextDouble() * 5.2; // < 58 kg czyści górale
        ftpWatts = (weightKg * (5.5 + rng.nextDouble() * 0.6)).round();
        vo2Max = 80.5 + rng.nextDouble() * 7.5;
        cobbles = 44 + rng.nextInt(14);
        climbing = 72 + tierBoost + rng.nextInt(10);
        tt = 56 + rng.nextInt(14);
        break;
      case SatelliteAcademyRegionId.eastAfricaRiftValley:
        weightKg = 57.0 + rng.nextDouble() * 7.0;
        ftpWatts = (weightKg * (5.4 + rng.nextDouble() * 0.65)).round();
        vo2Max = 82.0 + rng.nextDouble() * 8.0;
        cobbles = 50 + rng.nextInt(16);
        climbing = 69 + tierBoost + rng.nextInt(11);
        tt = 60 + rng.nextInt(15);
        break;
      case SatelliteAcademyRegionId.flandersKortrijk:
        weightKg = 68.5 + rng.nextDouble() * 8.5;
        ftpWatts = (weightKg * (5.1 + rng.nextDouble() * 0.55)).round();
        vo2Max = 75.5 + rng.nextDouble() * 6.5;
        cobbles = 73 + tierBoost + rng.nextInt(11);
        climbing = 58 + rng.nextInt(14);
        tt = 68 + tierBoost + rng.nextInt(10);
        break;
      case SatelliteAcademyRegionId.sierraNevadaGranada:
        weightKg = 61.5 + rng.nextDouble() * 6.5;
        ftpWatts = (weightKg * (5.45 + rng.nextDouble() * 0.6)).round();
        vo2Max = 78.5 + rng.nextDouble() * 7.0;
        cobbles = 56 + rng.nextInt(14);
        climbing = 70 + tierBoost + rng.nextInt(10);
        tt = 67 + tierBoost + rng.nextInt(11);
        break;
    }

    return SatelliteAcademyProspect(
      id: 'pros_${regionId.countryCode.toLowerCase()}_${seed}_${rng.nextInt(9999)}',
      fullName: fullName,
      nationalityIso: nat,
      age: age,
      regionId: regionId,
      specialization: spec,
      potential: potential,
      currentOvr: currentOvr,
      weightKg: double.parse(weightKg.toStringAsFixed(1)),
      ftpWatts: ftpWatts,
      vo2Max: double.parse(vo2Max.toStringAsFixed(1)),
      cobblesRating: cobbles.clamp(40, 95),
      climbingRating: climbing.clamp(45, 95),
      timeTrialRating: tt.clamp(45, 95),
      trainingWeeksCompleted: 0,
      scoutingConfidence: (72 + academyTier * 5).clamp(65, 98),
      isSignedToProRoster: false,
      discoveredOn: currentDate,
    );
  }

  /// Oblicza zbiorcze KPI całej globalnej sieci akademii.
  GlobalSatelliteAcademyNetworkSummary computeNetworkSummary(
    Map<SatelliteAcademyRegionId, SatelliteAcademyNode> network,
  ) {
    final nodes = network.values.toList();
    final activeNodes = nodes.where((n) => n.isBuilt).toList();
    final eliteNodes = nodes
        .where((n) => n.status == SatelliteAcademyStatus.eliteFlagship)
        .length;

    final upkeep = activeNodes.fold<double>(0.0, (s, n) => s + n.annualBudgetEur);
    final prospects = activeNodes.fold<int>(
      0,
      (s, n) => s + n.availableProspectCount,
    );
    final campRiders = activeNodes.fold<int>(
      0,
      (s, n) => s + n.activeCampRiderCount,
    );
    final graduates = nodes.fold<int>(
      0,
      (s, n) => s + n.totalGraduatesPromoted,
    );
    final avgTier = activeNodes.isEmpty
        ? 0.0
        : activeNodes.fold<int>(0, (s, n) => s + n.tier) / activeNodes.length;

    final prestige = activeNodes.isEmpty
        ? 0.0
        : activeNodes.fold<double>(0.0, (s, n) => s + n.reputationScore) /
            nodes.length;

    final altitudeNodes = activeNodes
        .where((n) => n.regionId.altitudeMeters >= 2000)
        .length;
    final altitudeCoverage = (altitudeNodes / 3.0 * 100.0).clamp(0.0, 100.0);

    return GlobalSatelliteAcademyNetworkSummary(
      totalCenters: nodes.length,
      activeCenters: activeNodes.length,
      eliteCenters: eliteNodes,
      totalAnnualUpkeepEur: upkeep,
      totalProspectsInPipeline: prospects,
      totalActiveCampRiders: campRiders,
      totalGraduatesPromoted: graduates,
      averageTier: avgTier,
      networkPrestigeScore: prestige,
      altitudeCoverageScore: altitudeCoverage,
    );
  }
}

/// Stan Riverpod dla Systemu Globalnych Akademii Satelickich.
class GlobalSatelliteTrainingCentersState {
  final Map<SatelliteAcademyRegionId, SatelliteAcademyNode> nodes;
  final SatelliteAcademyRegionId selectedRegion;
  final double teamBudgetEur;
  final DateTime currentDate;
  final double totalInvestedEur;
  final String? lastFeedbackMessage;
  final bool isFeedbackError;

  const GlobalSatelliteTrainingCentersState({
    required this.nodes,
    required this.selectedRegion,
    required this.teamBudgetEur,
    required this.currentDate,
    required this.totalInvestedEur,
    this.lastFeedbackMessage,
    this.isFeedbackError = false,
  });

  SatelliteAcademyNode get selectedNode => nodes[selectedRegion]!;

  GlobalSatelliteTrainingCentersState copyWith({
    Map<SatelliteAcademyRegionId, SatelliteAcademyNode>? nodes,
    SatelliteAcademyRegionId? selectedRegion,
    double? teamBudgetEur,
    DateTime? currentDate,
    double? totalInvestedEur,
    String? lastFeedbackMessage,
    bool? isFeedbackError,
  }) {
    return GlobalSatelliteTrainingCentersState(
      nodes: nodes ?? this.nodes,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      teamBudgetEur: teamBudgetEur ?? this.teamBudgetEur,
      currentDate: currentDate ?? this.currentDate,
      totalInvestedEur: totalInvestedEur ?? this.totalInvestedEur,
      lastFeedbackMessage: lastFeedbackMessage,
      isFeedbackError: isFeedbackError ?? this.isFeedbackError,
    );
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((k, v) => MapEntry(k.toJson(), v.toJson())),
        'selectedRegion': selectedRegion.toJson(),
        'teamBudgetEur': teamBudgetEur,
        'currentDate': currentDate.toIso8601String(),
        'totalInvestedEur': totalInvestedEur,
        'lastFeedbackMessage': lastFeedbackMessage,
        'isFeedbackError': isFeedbackError,
      };

  factory GlobalSatelliteTrainingCentersState.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawNodes = json['nodes'] as Map<String, dynamic>? ?? const {};
    final parsedNodes = <SatelliteAcademyRegionId, SatelliteAcademyNode>{};
    for (final entry in rawNodes.entries) {
      if (entry.value is Map<String, dynamic>) {
        final region = SatelliteAcademyRegionId.fromJson(entry.key);
        parsedNodes[region] =
            SatelliteAcademyNode.fromJson(entry.value as Map<String, dynamic>);
      }
    }
    const service = GlobalSatelliteTrainingCentersService();
    final fallback = service.createInitialNetwork();
    for (final region in SatelliteAcademyRegionId.values) {
      parsedNodes.putIfAbsent(region, () => fallback[region]!);
    }

    return GlobalSatelliteTrainingCentersState(
      nodes: parsedNodes,
      selectedRegion: SatelliteAcademyRegionId.fromJson(
        (json['selectedRegion'] as String?) ?? 'sierraNevadaGranada',
      ),
      teamBudgetEur: (json['teamBudgetEur'] as num?)?.toDouble() ?? 1850000.0,
      currentDate: DateTime.tryParse((json['currentDate'] as String?) ?? '') ??
          DateTime(2026, 1, 15),
      totalInvestedEur: (json['totalInvestedEur'] as num?)?.toDouble() ?? 0.0,
      lastFeedbackMessage: json['lastFeedbackMessage'] as String?,
      isFeedbackError: (json['isFeedbackError'] as bool?) ?? false,
    );
  }
}

/// Kontroler stanu sieci Globalnych Akademii Satelickich.
class GlobalSatelliteTrainingCentersNotifier
    extends StateNotifier<GlobalSatelliteTrainingCentersState> {
  final GlobalSatelliteTrainingCentersService _service;

  GlobalSatelliteTrainingCentersNotifier({
    GlobalSatelliteTrainingCentersService service =
        const GlobalSatelliteTrainingCentersService(),
    double initialBudgetEur = 1850000.0,
    DateTime? initialDate,
  })  : _service = service,
        super(
          GlobalSatelliteTrainingCentersState(
            nodes: service.createInitialNetwork(
              currentDate: initialDate ?? DateTime(2026, 1, 15),
            ),
            selectedRegion: SatelliteAcademyRegionId.sierraNevadaGranada,
            teamBudgetEur: initialBudgetEur,
            currentDate: initialDate ?? DateTime(2026, 1, 15),
            totalInvestedEur: 420000.0,
          ),
        );

  GlobalSatelliteAcademyNetworkSummary get summary =>
      _service.computeNetworkSummary(state.nodes);

  void selectRegion(SatelliteAcademyRegionId region) {
    state = state.copyWith(selectedRegion: region);
  }

  void setTeamBudget(double budgetEur) {
    state = state.copyWith(teamBudgetEur: math.max(0.0, budgetEur));
  }

  void unlockOrUpgradeRegion(SatelliteAcademyRegionId region) {
    final node = state.nodes[region];
    if (node == null) return;

    final result = _service.unlockOrUpgradeAcademy(
      node: node,
      availableBudgetEur: state.teamBudgetEur,
      currentDate: state.currentDate,
    );

    _applyOperationResult(region, result);
  }

  void setFocusMode(
    SatelliteAcademyRegionId region,
    SatelliteAcademyFocusMode mode,
  ) {
    final node = state.nodes[region];
    if (node == null) return;

    final result = _service.changeFocusMode(
      node: node,
      focusMode: mode,
      currentDate: state.currentDate,
    );
    _applyOperationResult(region, result);
  }

  void enrollRiderInCamp({
    required SatelliteAcademyRegionId region,
    required String riderId,
    required String riderName,
    int durationDays = 14,
    AcademyCampIntensity intensity = AcademyCampIntensity.standardBlock,
  }) {
    final node = state.nodes[region];
    if (node == null) return;

    final result = _service.enrollRiderInCamp(
      node: node,
      riderId: riderId,
      riderName: riderName,
      durationDays: durationDays,
      intensity: intensity,
      currentDate: state.currentDate,
    );
    _applyOperationResult(region, result);
  }

  void scoutProspect(SatelliteAcademyRegionId region) {
    final node = state.nodes[region];
    if (node == null) return;

    final result = _service.scoutLocalProspect(
      node: node,
      availableBudgetEur: state.teamBudgetEur,
      currentDate: state.currentDate,
    );
    _applyOperationResult(region, result);
  }

  void promoteProspect(SatelliteAcademyRegionId region, String prospectId) {
    final node = state.nodes[region];
    if (node == null) return;

    final result = _service.promoteProspectToProRoster(
      node: node,
      prospectId: prospectId,
      currentDate: state.currentDate,
    );
    _applyOperationResult(region, result);
  }

  void maintainAcademy(SatelliteAcademyRegionId region) {
    final node = state.nodes[region];
    if (node == null) return;

    final result = _service.maintainFacilities(
      node: node,
      availableBudgetEur: state.teamBudgetEur,
      currentDate: state.currentDate,
    );
    _applyOperationResult(region, result);
  }

  void advanceDays(int days) {
    if (days <= 0) return;
    final nextDate = state.currentDate.add(Duration(days: days));
    final nextNodes = _service.advanceNetworkDays(
      network: state.nodes,
      days: days,
      newCurrentDate: nextDate,
    );
    state = state.copyWith(
      nodes: nextNodes,
      currentDate: nextDate,
      lastFeedbackMessage: 'Zasymulowano $days dni pracy sieci akademii.',
      isFeedbackError: false,
    );
  }

  void _applyOperationResult(
    SatelliteAcademyRegionId region,
    AcademyNetworkOperationResult result,
  ) {
    if (!result.success || result.updatedNode == null) {
      state = state.copyWith(
        lastFeedbackMessage: result.message,
        isFeedbackError: true,
      );
      return;
    }

    final nextNodes = Map<SatelliteAcademyRegionId, SatelliteAcademyNode>.from(
      state.nodes,
    );
    nextNodes[region] = result.updatedNode!;

    state = state.copyWith(
      nodes: nextNodes,
      teamBudgetEur: math.max(0.0, state.teamBudgetEur - result.costEur),
      totalInvestedEur: state.totalInvestedEur + result.costEur,
      lastFeedbackMessage: result.message,
      isFeedbackError: false,
    );
  }
}

final globalSatelliteTrainingCentersProvider = StateNotifierProvider<
    GlobalSatelliteTrainingCentersNotifier,
    GlobalSatelliteTrainingCentersState>(
  (ref) => GlobalSatelliteTrainingCentersNotifier(),
);

/// Produkcyjny panel zarządzania Systemem Globalnych Akademii Satelickich.
/// Responsywny dla 390x844, 1024x768 i 1600x900 z pełnymi stanami interakcji.
class GlobalSatelliteTrainingCentersPanel extends ConsumerWidget {
  const GlobalSatelliteTrainingCentersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(globalSatelliteTrainingCentersProvider);
    final notifier = ref.read(globalSatelliteTrainingCentersProvider.notifier);
    final summary = notifier.summary;

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1150;
          final isTablet =
              constraints.maxWidth >= 700 && constraints.maxWidth < 1150;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(state, summary, notifier, isDesktop),
                if (state.lastFeedbackMessage != null) ...[
                  const SizedBox(height: 12),
                  _FeedbackBanner(
                    message: state.lastFeedbackMessage!,
                    isError: state.isFeedbackError,
                  ),
                ],
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildAcademyGrid(
                          state: state,
                          onSelect: notifier.selectRegion,
                          crossAxisCount: 2,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 6,
                        child: _AcademyDetailCard(
                          node: state.selectedNode,
                          teamBudgetEur: state.teamBudgetEur,
                          notifier: notifier,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildAcademyGrid(
                    state: state,
                    onSelect: notifier.selectRegion,
                    crossAxisCount: isTablet ? 2 : 1,
                  ),
                  const SizedBox(height: 16),
                  _AcademyDetailCard(
                    node: state.selectedNode,
                    teamBudgetEur: state.teamBudgetEur,
                    notifier: notifier,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    GlobalSatelliteTrainingCentersState state,
    GlobalSatelliteAcademyNetworkSummary summary,
    GlobalSatelliteTrainingCentersNotifier notifier,
    bool isDesktop,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public_rounded,
                        color: AppColors.goldAccent,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Globalne Akademie Satelickie',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kolumbia • Afryka Wschodnia • Flandria • Sierra Nevada',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _AcademyActionButton(
                label: '+7 dni symulacji',
                icon: Icons.fast_forward_rounded,
                accentColor: AppColors.accentBlue,
                onPressed: () => notifier.advanceDays(7),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _KpiChip(
                label: 'Budżet Klubu',
                value: Formatters.formatCurrency(state.teamBudgetEur),
                color: AppColors.goldAccent,
              ),
              _KpiChip(
                label: 'Aktywne Bazy',
                value: '${summary.activeCenters}/${summary.totalCenters}',
                color: AppColors.statusSuccess,
              ),
              _KpiChip(
                label: 'Talenty U19/U23',
                value: '${summary.totalProspectsInPipeline}',
                color: AppColors.accentBlue,
              ),
              _KpiChip(
                label: 'Na Obozach Pro',
                value: '${summary.totalActiveCampRiders}',
                color: AppColors.cyanAccent,
              ),
              _KpiChip(
                label: 'Roczne Utrzymanie',
                value: Formatters.formatCurrency(summary.totalAnnualUpkeepEur),
                color: AppColors.amberWarning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcademyGrid({
    required GlobalSatelliteTrainingCentersState state,
    required ValueChanged<SatelliteAcademyRegionId> onSelect,
    required int crossAxisCount,
  }) {
    const regions = SatelliteAcademyRegionId.values;
    if (crossAxisCount == 1) {
      return Column(
        children: [
          for (int i = 0; i < regions.length; i++) ...[
            _AcademyRegionCard(
              node: state.nodes[regions[i]]!,
              isSelected: state.selectedRegion == regions[i],
              onTap: () => onSelect(regions[i]),
            ),
            if (i < regions.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _AcademyRegionCard(
                node: state.nodes[regions[0]]!,
                isSelected: state.selectedRegion == regions[0],
                onTap: () => onSelect(regions[0]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AcademyRegionCard(
                node: state.nodes[regions[1]]!,
                isSelected: state.selectedRegion == regions[1],
                onTap: () => onSelect(regions[1]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _AcademyRegionCard(
                node: state.nodes[regions[2]]!,
                isSelected: state.selectedRegion == regions[2],
                onTap: () => onSelect(regions[2]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AcademyRegionCard(
                node: state.nodes[regions[3]]!,
                isSelected: state.selectedRegion == regions[3],
                onTap: () => onSelect(regions[3]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AcademyRegionCard extends StatefulWidget {
  final SatelliteAcademyNode node;
  final bool isSelected;
  final VoidCallback onTap;

  const _AcademyRegionCard({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AcademyRegionCard> createState() => _AcademyRegionCardState();
}

class _AcademyRegionCardState extends State<_AcademyRegionCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final region = widget.node.regionId;
    final accent = region.accentColor;

    final borderColor = widget.isSelected
        ? accent
        : (_isFocused || _isHovered)
            ? accent.withValues(alpha: 0.65)
            : AppColors.cardBorder;

    final bgColor = _isPressed
        ? AppColors.surfaceLight
        : widget.isSelected
            ? AppColors.surfaceLight
            : AppColors.surface;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        region.countryCode,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        region.shortLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      label: widget.node.isBuilt
                          ? 'Poz. ${widget.node.tier}'
                          : 'Zamknięta',
                      color: widget.node.status.color,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  region.specialtyTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        '${region.altitudeMeters} m n.p.m.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        widget.node.isBuilt
                            ? 'Talenty: ${widget.node.availableProspectCount}/${widget.node.maxProspectSlots}'
                            : 'Koszt: ${Formatters.formatCurrency(widget.node.nextUpgradeCostEur)}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.node.isBuilt
                              ? AppColors.accentBlue
                              : AppColors.goldAccent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
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

class _AcademyDetailCard extends StatelessWidget {
  final SatelliteAcademyNode node;
  final double teamBudgetEur;
  final GlobalSatelliteTrainingCentersNotifier notifier;

  const _AcademyDetailCard({
    required this.node,
    required this.teamBudgetEur,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final region = node.regionId;
    final blueprint = node.blueprint;
    final upgradeCost = node.nextUpgradeCostEur;
    final canUpgrade = node.tier < 4 && teamBudgetEur >= upgradeCost;
    final canScout = node.isBuilt &&
        node.availableProspectCount < node.maxProspectSlots &&
        teamBudgetEur >= GlobalSatelliteTrainingCentersService.manualScoutingCostEur;
    final canMaintain = node.isBuilt && node.facilityCondition < 99.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${region.cityLabel} • ${blueprint.climateProfile}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: node.status.label,
                color: node.status.color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            region.specialtyDescription,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AcademyActionButton(
                label: node.tier == 0
                    ? 'Otwórz Bazę (${Formatters.formatCurrency(upgradeCost)})'
                    : node.tier >= 4
                        ? 'Maksymalny Poziom 4'
                        : 'Rozbuduj Poz. ${node.tier + 1} (${Formatters.formatCurrency(upgradeCost)})',
                icon: node.tier == 0
                    ? Icons.add_business_rounded
                    : Icons.upgrade_rounded,
                accentColor: AppColors.goldAccent,
                onPressed: canUpgrade
                    ? () => notifier.unlockOrUpgradeRegion(region)
                    : null,
              ),
              _AcademyActionButton(
                label: 'Skautuj Talent',
                icon: Icons.person_search_rounded,
                accentColor: AppColors.accentBlue,
                onPressed:
                    canScout ? () => notifier.scoutProspect(region) : null,
              ),
              _AcademyActionButton(
                label: 'Wyślij Kolarza Pro (14d)',
                icon: Icons.directions_bike_rounded,
                accentColor: AppColors.statusSuccess,
                onPressed: node.isBuilt &&
                        node.activeCampRiderCount < node.maxCampCapacity
                    ? () => notifier.enrollRiderInCamp(
                          region: region,
                          riderId: 'pro_leader_${node.activeStints.length + 1}',
                          riderName:
                              'Kolarz Kadry #${node.activeStints.length + 1}',
                          durationDays: 14,
                          intensity: AcademyCampIntensity.peakSupercompensation,
                        )
                    : null,
              ),
              if (canMaintain)
                _AcademyActionButton(
                  label: 'Serwis (${node.facilityCondition.toStringAsFixed(0)}%)',
                  icon: Icons.build_rounded,
                  accentColor: AppColors.amberWarning,
                  onPressed: () => notifier.maintainAcademy(region),
                ),
            ],
          ),
          if (node.isBuilt) ...[
            const SizedBox(height: 18),
            const Text(
              'Priorytet Operacyjny Akademii',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SatelliteAcademyFocusMode.values.map((mode) {
                final selected = node.focusMode == mode;
                return _AcademyActionButton(
                  label: mode.label,
                  icon: selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  accentColor:
                      selected ? region.accentColor : AppColors.textSecondary,
                  onPressed: () => notifier.setFocusMode(region, mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text(
              'Aktywne Obozy Pro (${node.activeCampRiderCount}/${node.maxCampCapacity})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (node.activeStints.isEmpty)
              const Text(
                'Brak kolarzy na obozie w tym ośrodku.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            else
              Column(
                children: node.activeStints.map((stint) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stint.riderName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${stint.daysCompleted}/${stint.durationDays} dni • +${stint.ftpGainWatts.toStringAsFixed(1)} W • +${stint.altitudeGainPercent.toStringAsFixed(1)}% hipoksja',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(
                          label: stint.isCompleted ? 'Ukończono' : 'W trakcie',
                          color: stint.isCompleted
                              ? AppColors.statusSuccess
                              : AppColors.accentBlue,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            Text(
              'Wychowankowie & Talenty (${node.availableProspectCount}/${node.maxProspectSlots})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (node.prospects.isEmpty)
              const Text(
                'Brak odkrytych juniorów. Uruchom misję skautingową.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            else
              Column(
                children: node.prospects.map((prospect) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${prospect.fullName} (${prospect.nationalityIso}, ${prospect.age} l.)',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${prospect.specialization.displayName} • OVR ${prospect.currentOvr}/POT ${prospect.potential} • ${prospect.wPerKg.toStringAsFixed(2)} W/kg • VO2 ${prospect.vo2Max}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        _AcademyActionButton(
                          label: prospect.isSignedToProRoster
                              ? 'W kadrze Pro'
                              : 'Awansuj do Pro',
                          icon: prospect.isSignedToProRoster
                              ? Icons.check_circle_rounded
                              : Icons.arrow_upward_rounded,
                          accentColor: AppColors.goldAccent,
                          onPressed: prospect.isSignedToProRoster
                              ? null
                              : () =>
                                  notifier.promoteProspect(region, prospect.id),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}

class _AcademyActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _AcademyActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_AcademyActionButton> createState() => _AcademyActionButtonState();
}

class _AcademyActionButtonState extends State<_AcademyActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final bgColor = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _isPressed
            ? widget.accentColor.withValues(alpha: 0.28)
            : _isHovered
                ? widget.accentColor.withValues(alpha: 0.20)
                : widget.accentColor.withValues(alpha: 0.12);

    final borderColor = disabled
        ? AppColors.cardBorder
        : _isFocused
            ? widget.accentColor
            : widget.accentColor.withValues(alpha: _isHovered ? 0.85 : 0.45);

    final fgColor = disabled ? AppColors.textSecondary : widget.accentColor;

    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: MouseRegion(
        cursor:
            disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: disabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel:
              disabled ? null : () => setState(() => _isPressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: fgColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: disabled ? AppColors.textSecondary : AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
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
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _FeedbackBanner({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
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
}
