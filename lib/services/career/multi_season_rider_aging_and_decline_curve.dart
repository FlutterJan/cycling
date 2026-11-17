import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/lactate_and_lab_profile.dart';
import '../../models/rider/rider.dart';

/// Faza biologiczno-taktyczna w 15-letnim cyklu kariery kolarza WorldTour.
enum CareerLifecyclePhase {
  /// 18–23 lat: szybki przyrost VO2max, mocy beztlenowej (5s/1m) i W'.
  youthExplosiveDevelopment,

  /// 24–29 lat: szczyt FTP (LT2) i wytrzymałości wielodniowej.
  primePeakPerformance,

  /// 30–31 lat: płaskowyż wydolnościowy i optymalizacja ekonomii jazdy.
  consolidationTransition,

  /// 32+ lat (po 31. r.ż.): powolny spadek 5s/1m przy wzroście ekonomii pedałowania,
  /// raceIq oraz odporności na zmęczenie w 3. tygodniu Wielkich Tourów.
  veteranEfficiencyAndResilience;

  String toJson() => name;

  static CareerLifecyclePhase fromJson(String value) {
    return CareerLifecyclePhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CareerLifecyclePhase.primePeakPerformance,
    );
  }

  String get displayName {
    switch (this) {
      case CareerLifecyclePhase.youthExplosiveDevelopment:
        return 'Rozwój VO2max i Wybuchowości';
      case CareerLifecyclePhase.primePeakPerformance:
        return 'Szczyt FTP i Wytrzymałości Wielodniowej';
      case CareerLifecyclePhase.consolidationTransition:
        return 'Konsolidacja i Dojrzałość Taktyczna';
      case CareerLifecyclePhase.veteranEfficiencyAndResilience:
        return 'Ekonomia Weterana i Odporność 3. Tygodnia';
    }
  }

  String get ageRangeLabel {
    switch (this) {
      case CareerLifecyclePhase.youthExplosiveDevelopment:
        return '18–23 lat';
      case CareerLifecyclePhase.primePeakPerformance:
        return '24–29 lat';
      case CareerLifecyclePhase.consolidationTransition:
        return '30–31 lat';
      case CareerLifecyclePhase.veteranEfficiencyAndResilience:
        return '32+ lat';
    }
  }

  String get physiologicalSummary {
    switch (this) {
      case CareerLifecyclePhase.youthExplosiveDevelopment:
        return 'Szybki przyrost VO2max, dynamiki 5s/1m oraz rezerwy W\'.';
      case CareerLifecyclePhase.primePeakPerformance:
        return 'Maksymalne FTP (20m/60m), pojemność glikogenu i regeneracja międzyetapowa.';
      case CareerLifecyclePhase.consolidationTransition:
        return 'Utrzymanie wysokiego progu LT2 przy rosnącej ekonomii pedałowania.';
      case CareerLifecyclePhase.veteranEfficiencyAndResilience:
        return 'Powolny spadek szczytu 5s/1m kompensowany ekonomią, raceIq i odpornością w 3. tygodniu GT.';
    }
  }

  Color get accentColor {
    switch (this) {
      case CareerLifecyclePhase.youthExplosiveDevelopment:
        return AppColors.cyanAccent;
      case CareerLifecyclePhase.primePeakPerformance:
        return AppColors.goldAccent;
      case CareerLifecyclePhase.consolidationTransition:
        return AppColors.accentBlue;
      case CareerLifecyclePhase.veteranEfficiencyAndResilience:
        return AppColors.statusSuccess;
    }
  }
}

/// Roczne modyfikatory fizjologiczne i taktyczne wynikające z krzywej starzenia.
class RiderAgingCurveModifiers {
  final int age;
  final CareerLifecyclePhase phase;
  final double vo2MaxDelta;
  final double explosivePower5sFactor;
  final double explosivePower1mFactor;
  final int wPrimeDeltaJoules;
  final double ftpFactor;
  final double multiDayEnduranceDelta;
  final double pedalingEconomyDeltaPercent;
  final int raceIqDelta;
  final double thirdWeekFatigueResilienceScore;
  final int draftingEfficiencyDelta;
  final double glycogenCapacityDeltaGrams;

  const RiderAgingCurveModifiers({
    required this.age,
    required this.phase,
    required this.vo2MaxDelta,
    required this.explosivePower5sFactor,
    required this.explosivePower1mFactor,
    required this.wPrimeDeltaJoules,
    required this.ftpFactor,
    required this.multiDayEnduranceDelta,
    required this.pedalingEconomyDeltaPercent,
    required this.raceIqDelta,
    required this.thirdWeekFatigueResilienceScore,
    required this.draftingEfficiencyDelta,
    required this.glycogenCapacityDeltaGrams,
  });

  Map<String, dynamic> toJson() => {
        'age': age,
        'phase': phase.toJson(),
        'vo2MaxDelta': vo2MaxDelta,
        'explosivePower5sFactor': explosivePower5sFactor,
        'explosivePower1mFactor': explosivePower1mFactor,
        'wPrimeDeltaJoules': wPrimeDeltaJoules,
        'ftpFactor': ftpFactor,
        'multiDayEnduranceDelta': multiDayEnduranceDelta,
        'pedalingEconomyDeltaPercent': pedalingEconomyDeltaPercent,
        'raceIqDelta': raceIqDelta,
        'thirdWeekFatigueResilienceScore': thirdWeekFatigueResilienceScore,
        'draftingEfficiencyDelta': draftingEfficiencyDelta,
        'glycogenCapacityDeltaGrams': glycogenCapacityDeltaGrams,
      };

  factory RiderAgingCurveModifiers.fromJson(Map<String, dynamic> json) {
    return RiderAgingCurveModifiers(
      age: (json['age'] as num).toInt(),
      phase: CareerLifecyclePhase.fromJson(json['phase'] as String),
      vo2MaxDelta: (json['vo2MaxDelta'] as num).toDouble(),
      explosivePower5sFactor: (json['explosivePower5sFactor'] as num).toDouble(),
      explosivePower1mFactor: (json['explosivePower1mFactor'] as num).toDouble(),
      wPrimeDeltaJoules: (json['wPrimeDeltaJoules'] as num).toInt(),
      ftpFactor: (json['ftpFactor'] as num).toDouble(),
      multiDayEnduranceDelta: (json['multiDayEnduranceDelta'] as num).toDouble(),
      pedalingEconomyDeltaPercent:
          (json['pedalingEconomyDeltaPercent'] as num).toDouble(),
      raceIqDelta: (json['raceIqDelta'] as num).toInt(),
      thirdWeekFatigueResilienceScore:
          (json['thirdWeekFatigueResilienceScore'] as num).toDouble(),
      draftingEfficiencyDelta: (json['draftingEfficiencyDelta'] as num).toInt(),
      glycogenCapacityDeltaGrams:
          (json['glycogenCapacityDeltaGrams'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderAgingCurveModifiers &&
        other.age == age &&
        other.phase == phase &&
        other.vo2MaxDelta == vo2MaxDelta &&
        other.explosivePower5sFactor == explosivePower5sFactor &&
        other.explosivePower1mFactor == explosivePower1mFactor &&
        other.wPrimeDeltaJoules == wPrimeDeltaJoules &&
        other.ftpFactor == ftpFactor &&
        other.multiDayEnduranceDelta == multiDayEnduranceDelta &&
        other.pedalingEconomyDeltaPercent == pedalingEconomyDeltaPercent &&
        other.raceIqDelta == raceIqDelta &&
        other.thirdWeekFatigueResilienceScore ==
            thirdWeekFatigueResilienceScore &&
        other.draftingEfficiencyDelta == draftingEfficiencyDelta &&
        other.glycogenCapacityDeltaGrams == glycogenCapacityDeltaGrams;
  }

  @override
  int get hashCode => Object.hash(
        age,
        phase,
        vo2MaxDelta,
        explosivePower5sFactor,
        explosivePower1mFactor,
        wPrimeDeltaJoules,
        ftpFactor,
        multiDayEnduranceDelta,
        pedalingEconomyDeltaPercent,
        raceIqDelta,
        thirdWeekFatigueResilienceScore,
        draftingEfficiencyDelta,
        glycogenCapacityDeltaGrams,
      );
}

/// Migawka pojedynczego sezonu w 15-letniej projekcji rozwoju i starzenia kolarza.
class RiderSeasonEvolutionSnapshot {
  final int seasonIndex;
  final int seasonYear;
  final int age;
  final CareerLifecyclePhase phase;
  final int overallRating;
  final int ftpWatts;
  final double wattsPerKg;
  final double vo2Max;
  final int watts5s;
  final int watts1m;
  final int watts5m;
  final int watts20m;
  final int watts60m;
  final int wPrimeJoules;
  final double recoveryRate;
  final double pedalingEconomyPercent;
  final int raceIq;
  final double thirdWeekFatigueResilience;
  final RiderAgingCurveModifiers? deltasFromPrevious;

  const RiderSeasonEvolutionSnapshot({
    required this.seasonIndex,
    required this.seasonYear,
    required this.age,
    required this.phase,
    required this.overallRating,
    required this.ftpWatts,
    required this.wattsPerKg,
    required this.vo2Max,
    required this.watts5s,
    required this.watts1m,
    required this.watts5m,
    required this.watts20m,
    required this.watts60m,
    required this.wPrimeJoules,
    required this.recoveryRate,
    required this.pedalingEconomyPercent,
    required this.raceIq,
    required this.thirdWeekFatigueResilience,
    this.deltasFromPrevious,
  });

  Map<String, dynamic> toJson() => {
        'seasonIndex': seasonIndex,
        'seasonYear': seasonYear,
        'age': age,
        'phase': phase.toJson(),
        'overallRating': overallRating,
        'ftpWatts': ftpWatts,
        'wattsPerKg': wattsPerKg,
        'vo2Max': vo2Max,
        'watts5s': watts5s,
        'watts1m': watts1m,
        'watts5m': watts5m,
        'watts20m': watts20m,
        'watts60m': watts60m,
        'wPrimeJoules': wPrimeJoules,
        'recoveryRate': recoveryRate,
        'pedalingEconomyPercent': pedalingEconomyPercent,
        'raceIq': raceIq,
        'thirdWeekFatigueResilience': thirdWeekFatigueResilience,
        'deltasFromPrevious': deltasFromPrevious?.toJson(),
      };

  factory RiderSeasonEvolutionSnapshot.fromJson(Map<String, dynamic> json) {
    return RiderSeasonEvolutionSnapshot(
      seasonIndex: (json['seasonIndex'] as num).toInt(),
      seasonYear: (json['seasonYear'] as num).toInt(),
      age: (json['age'] as num).toInt(),
      phase: CareerLifecyclePhase.fromJson(json['phase'] as String),
      overallRating: (json['overallRating'] as num).toInt(),
      ftpWatts: (json['ftpWatts'] as num).toInt(),
      wattsPerKg: (json['wattsPerKg'] as num).toDouble(),
      vo2Max: (json['vo2Max'] as num).toDouble(),
      watts5s: (json['watts5s'] as num).toInt(),
      watts1m: (json['watts1m'] as num).toInt(),
      watts5m: (json['watts5m'] as num).toInt(),
      watts20m: (json['watts20m'] as num).toInt(),
      watts60m: (json['watts60m'] as num).toInt(),
      wPrimeJoules: (json['wPrimeJoules'] as num).toInt(),
      recoveryRate: (json['recoveryRate'] as num).toDouble(),
      pedalingEconomyPercent:
          (json['pedalingEconomyPercent'] as num).toDouble(),
      raceIq: (json['raceIq'] as num).toInt(),
      thirdWeekFatigueResilience:
          (json['thirdWeekFatigueResilience'] as num).toDouble(),
      deltasFromPrevious: json['deltasFromPrevious'] != null
          ? RiderAgingCurveModifiers.fromJson(
              json['deltasFromPrevious'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderSeasonEvolutionSnapshot &&
        other.seasonIndex == seasonIndex &&
        other.seasonYear == seasonYear &&
        other.age == age &&
        other.phase == phase &&
        other.overallRating == overallRating &&
        other.ftpWatts == ftpWatts &&
        other.vo2Max == vo2Max &&
        other.watts5s == watts5s &&
        other.watts1m == watts1m &&
        other.pedalingEconomyPercent == pedalingEconomyPercent &&
        other.raceIq == raceIq &&
        other.thirdWeekFatigueResilience == thirdWeekFatigueResilience;
  }

  @override
  int get hashCode => Object.hash(
        seasonIndex,
        seasonYear,
        age,
        phase,
        overallRating,
        ftpWatts,
        vo2Max,
        watts5s,
        watts1m,
        pedalingEconomyPercent,
        raceIq,
        thirdWeekFatigueResilience,
      );
}

/// Pełny raport projekcji 15 sezonów kariery kolarza wraz z punktami szczytowymi.
class MultiSeasonCareerTrajectoryReport {
  final String riderId;
  final String riderName;
  final RiderSpecialization specialization;
  final int startingAge;
  final int seasonsSimulated;
  final List<RiderSeasonEvolutionSnapshot> snapshots;
  final RiderSeasonEvolutionSnapshot peakFtpSeason;
  final RiderSeasonEvolutionSnapshot peakOvrSeason;
  final RiderSeasonEvolutionSnapshot peakExplosive5sSeason;
  final RiderSeasonEvolutionSnapshot peakEconomyAndIqSeason;

  const MultiSeasonCareerTrajectoryReport({
    required this.riderId,
    required this.riderName,
    required this.specialization,
    required this.startingAge,
    required this.seasonsSimulated,
    required this.snapshots,
    required this.peakFtpSeason,
    required this.peakOvrSeason,
    required this.peakExplosive5sSeason,
    required this.peakEconomyAndIqSeason,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'specialization': specialization.toJson(),
        'startingAge': startingAge,
        'seasonsSimulated': seasonsSimulated,
        'snapshots': snapshots.map((s) => s.toJson()).toList(),
        'peakFtpSeason': peakFtpSeason.toJson(),
        'peakOvrSeason': peakOvrSeason.toJson(),
        'peakExplosive5sSeason': peakExplosive5sSeason.toJson(),
        'peakEconomyAndIqSeason': peakEconomyAndIqSeason.toJson(),
      };
}

/// Model starzenia się i ewolucji profilu kolarza przez 15 sezonów kariery.
///
/// Odwzorowuje fizjologię kolarstwa zawodowego WorldTour:
/// - **18–23 lat**: szybki przyrost $\text{VO}_2\text{max}$ i wybuchowości (`5s/1m`, $W'$),
/// - **24–29 lat**: szczyt FTP (20m/60m) oraz wytrzymałości wielodniowej (`recoveryRate`, glikogen),
/// - **30–31 lat**: faza konsolidacji i utrzymania progu mleczanowego,
/// - **>31 lat (32+)**: powolny spadek mocy szczytowej `5s/1m` przy jednoczesnym wzroście
///   ekonomii pedałowania (`grossEfficiencyPercent`), `raceIq` oraz odporności na zmęczenie
///   w 3. tygodniu Wielkich Tourów.
class MultiSeasonRiderAgingAndDeclineCurve {
  MultiSeasonRiderAgingAndDeclineCurve._();

  static const int defaultCareerHorizonSeasons = 15;

  /// Zwraca fazę kariery odpowiadającą podanemu wiekowi.
  static CareerLifecyclePhase phaseForAge(int age) {
    if (age <= 23) {
      return CareerLifecyclePhase.youthExplosiveDevelopment;
    }
    if (age <= 29) {
      return CareerLifecyclePhase.primePeakPerformance;
    }
    if (age <= 31) {
      return CareerLifecyclePhase.consolidationTransition;
    }
    return CareerLifecyclePhase.veteranEfficiencyAndResilience;
  }

  /// Oblicza znormalizowany wskaźnik odporności na zmęczenie w 3. tygodniu Grand Touru (0.0–1.0).
  ///
  /// Kolarze po 31. roku życia zyskują premię doświadczenia metabolicznego i ekonomii ruchu,
  /// co łagodzi spadek mocy w dniach 14–21.
  static double computeThirdWeekResilienceScore({
    required int age,
    required double recoveryRate,
    required double grossEfficiencyPercent,
    required int raceIq,
  }) {
    final double recNorm = ((recoveryRate - 0.70) / 0.55).clamp(0.0, 1.0);
    final double econNorm =
        ((grossEfficiencyPercent - 20.0) / 4.8).clamp(0.0, 1.0);
    final double iqNorm = ((raceIq - 45) / 54.0).clamp(0.0, 1.0);

    double ageAdaptationBonus;
    if (age <= 23) {
      ageAdaptationBonus = 0.04 * ((age - 18).clamp(0, 5) / 5.0);
    } else if (age <= 29) {
      ageAdaptationBonus = 0.04 + 0.08 * ((age - 23) / 6.0);
    } else if (age <= 31) {
      ageAdaptationBonus = 0.12 + 0.03 * ((age - 29) / 2.0);
    } else {
      final int veteranYears = (age - 31).clamp(0, 8);
      ageAdaptationBonus = 0.15 + 0.11 * (veteranYears / 8.0);
    }

    final double raw =
        (recNorm * 0.42) + (econNorm * 0.24) + (iqNorm * 0.14) + ageAdaptationBonus;
    return double.parse(raw.clamp(0.10, 0.99).toStringAsFixed(3));
  }

  /// Oblicza deterministyczne lub zasianych ziarnem roczne modyfikatory ewolucji kolarza.
  static RiderAgingCurveModifiers computeAnnualModifiers({
    required Rider rider,
    required int ageAtSeasonStart,
    int? randomSeed,
  }) {
    final int clampedAge = ageAtSeasonStart.clamp(17, 45);
    final CareerLifecyclePhase phase = phaseForAge(clampedAge);
    final math.Random rng = math.Random(
      randomSeed ?? (rider.id.hashCode ^ (clampedAge * 7919)),
    );
    final double jitter = (rng.nextDouble() - 0.5) * 0.18;

    final int potentialGap = math.max(0, rider.potential - rider.overallRating);
    final double potentialFactor = (potentialGap / 24.0).clamp(0.20, 1.35);

    final bool isSprinterOrPuncher =
        rider.specialization == RiderSpecialization.pureSprinter ||
            rider.specialization == RiderSpecialization.versatileSprinter ||
            rider.specialization == RiderSpecialization.puncher;
    final bool isGrandTourOrDiesel =
        rider.specialization == RiderSpecialization.gcClimber ||
            rider.specialization == RiderSpecialization.pureClimber ||
            rider.specialization == RiderSpecialization.timeTrialist ||
            rider.specialization == RiderSpecialization.domestiqueEngine;

    final double currentEconomy = rider.labProfile.grossEfficiencyPercent;

    double vo2Delta = 0.0;
    double power5sFactor = 1.0;
    double power1mFactor = 1.0;
    int wPrimeDelta = 0;
    double ftpFactor = 1.0;
    double enduranceDelta = 0.0;
    double economyDelta = 0.0;
    int raceIqDelta = 0;
    int draftingDelta = 0;
    double glycogenDelta = 0.0;

    if (clampedAge <= 23) {
      // 18–23 lat: szybki przyrost VO2max i wybuchowości
      final double youthIntensity =
          1.0 - ((clampedAge - 18).clamp(0, 5) * 0.06);
      vo2Delta = ((0.95 + potentialFactor * 1.05) * youthIntensity + jitter)
          .clamp(0.45, 2.40);

      final double explosiveSpecMult = isSprinterOrPuncher ? 1.18 : 0.94;
      power5sFactor = 1.0 +
          ((0.022 + potentialFactor * 0.015) * explosiveSpecMult +
                  jitter * 0.02)
              .clamp(0.012, 0.045);
      power1mFactor = 1.0 +
          ((0.019 + potentialFactor * 0.013) * explosiveSpecMult +
                  jitter * 0.02)
              .clamp(0.010, 0.040);
      wPrimeDelta =
          ((420 + potentialFactor * 460) * explosiveSpecMult).round();

      ftpFactor = 1.0 +
          ((0.015 + potentialFactor * 0.014) *
                  (isGrandTourOrDiesel ? 1.10 : 0.96))
              .clamp(0.008, 0.036);
      enduranceDelta =
          (0.012 + potentialFactor * 0.012).clamp(0.006, 0.030);
      economyDelta = (0.10 + potentialFactor * 0.06).clamp(0.06, 0.22);
      raceIqDelta = (2 + (potentialFactor >= 0.85 ? 1 : 0));
      draftingDelta = 2;
      glycogenDelta = 10.0 + potentialFactor * 8.0;
    } else if (clampedAge <= 29) {
      // 24–29 lat: szczyt FTP i wytrzymałości wielodniowej
      final double primeBell = clampedAge <= 26
          ? 1.0
          : (clampedAge == 27 ? 0.65 : (clampedAge == 28 ? 0.30 : 0.10));
      final double gtMult = isGrandTourOrDiesel ? 1.15 : 0.95;

      vo2Delta = (clampedAge <= 25 ? 0.22 : 0.05) + (jitter * 0.15);
      power5sFactor = isSprinterOrPuncher
          ? (clampedAge <= 26 ? 1.006 : 0.998)
          : (clampedAge <= 27 ? 1.003 : 0.997);
      power1mFactor = clampedAge <= 27 ? 1.007 : 1.001;
      wPrimeDelta = clampedAge <= 26 ? 160 : 40;

      ftpFactor = 1.0 +
          ((0.006 + potentialFactor * 0.009) * primeBell * gtMult +
                  jitter * 0.006)
              .clamp(-0.002, 0.022);
      enduranceDelta =
          ((0.018 + potentialFactor * 0.010) * (0.65 + primeBell * 0.45) * gtMult)
              .clamp(0.008, 0.034);
      economyDelta = (0.14 + (clampedAge - 24) * 0.015).clamp(0.10, 0.24);
      raceIqDelta = 2;
      draftingDelta = 1;
      glycogenDelta = 12.0 * (0.5 + primeBell * 0.5);
    } else if (clampedAge <= 31) {
      // 30–31 lat: faza przejściowa / konsolidacja
      vo2Delta = -0.18 + jitter * 0.12;
      power5sFactor = isSprinterOrPuncher ? 0.992 : 0.995;
      power1mFactor = 0.995;
      wPrimeDelta = -120;
      ftpFactor = 1.0 + (jitter * 0.012).clamp(-0.005, 0.005);
      enduranceDelta = 0.008;
      economyDelta = 0.18;
      raceIqDelta = 2;
      draftingDelta = 1;
      glycogenDelta = 4.0;
    } else {
      // >31 lat (32+): powolny spadek mocy szczytowej 5s/1m,
      // jednoczesny wzrost ekonomii pedałowania, raceIq i odporności w 3. tygodniu
      final int yearsOver31 = clampedAge - 31;
      final double declineSlope = (1.0 + (yearsOver31 - 1) * 0.16).clamp(1.0, 2.2);

      vo2Delta = (-0.35 - (yearsOver31 * 0.09) + jitter * 0.10)
          .clamp(-1.35, -0.20);
      power5sFactor =
          (1.0 - (0.014 * declineSlope * (isSprinterOrPuncher ? 1.15 : 0.95)))
              .clamp(0.945, 0.988);
      power1mFactor =
          (1.0 - (0.010 * declineSlope)).clamp(0.958, 0.992);
      wPrimeDelta = (-260 * declineSlope).round();

      // FTP w 32–33 r.ż. spada minimalnie, wyraźniej dopiero od 35+
      final double ftpDropRate = yearsOver31 <= 2
          ? 0.004 * yearsOver31
          : 0.008 + (yearsOver31 - 2) * 0.0065;
      ftpFactor = (1.0 - ftpDropRate + jitter * 0.008).clamp(0.940, 0.998);

      // Odporność wielodniowa utrzymuje się lub lekko rośnie w 32–34 r.ż.,
      // spada bardzo powoli dopiero u weteranów 36+
      enduranceDelta = yearsOver31 <= 3
          ? 0.006
          : (yearsOver31 <= 5 ? -0.002 : -0.008);
      economyDelta = yearsOver31 <= 6 ? 0.22 : 0.12;
      raceIqDelta = yearsOver31 <= 5 ? 2 : 1;
      draftingDelta = yearsOver31 <= 4 ? 1 : 0;
      glycogenDelta = yearsOver31 <= 3 ? 2.5 : -2.0;
    }

    final double projectedRecovery =
        (rider.physiology.recoveryRate + enduranceDelta).clamp(0.55, 1.35);
    final double projectedEconomy =
        (currentEconomy + economyDelta).clamp(19.5, 25.0);
    final int projectedRaceIq = (rider.skills.raceIq + raceIqDelta).clamp(1, 99);

    final double thirdWeekScore = computeThirdWeekResilienceScore(
      age: clampedAge,
      recoveryRate: projectedRecovery,
      grossEfficiencyPercent: projectedEconomy,
      raceIq: projectedRaceIq,
    );

    return RiderAgingCurveModifiers(
      age: clampedAge,
      phase: phase,
      vo2MaxDelta: double.parse(vo2Delta.toStringAsFixed(3)),
      explosivePower5sFactor: double.parse(power5sFactor.toStringAsFixed(4)),
      explosivePower1mFactor: double.parse(power1mFactor.toStringAsFixed(4)),
      wPrimeDeltaJoules: wPrimeDelta,
      ftpFactor: double.parse(ftpFactor.toStringAsFixed(4)),
      multiDayEnduranceDelta: double.parse(enduranceDelta.toStringAsFixed(4)),
      pedalingEconomyDeltaPercent:
          double.parse(economyDelta.toStringAsFixed(3)),
      raceIqDelta: raceIqDelta,
      thirdWeekFatigueResilienceScore: thirdWeekScore,
      draftingEfficiencyDelta: draftingDelta,
      glycogenCapacityDeltaGrams: double.parse(glycogenDelta.toStringAsFixed(1)),
    );
  }

  /// Aplikuje jeden pełny sezon starzenia/rozwoju do obiektu [Rider].
  static Rider applyAnnualEvolution({
    required Rider rider,
    required int newSeasonYear,
    int? randomSeed,
  }) {
    final int ageAtSeason = newSeasonYear - rider.birthDate.year;
    final RiderAgingCurveModifiers mod = computeAnnualModifiers(
      rider: rider,
      ageAtSeasonStart: ageAtSeason,
      randomSeed: randomSeed,
    );

    final int newFtp = math.max(
      200,
      (rider.physiology.ftpWatts * mod.ftpFactor).round(),
    );
    final double newVo2 =
        (rider.physiology.vo2Max + mod.vo2MaxDelta).clamp(48.0, 92.0);
    final int newWPrime =
        (rider.physiology.wPrimeJoules + mod.wPrimeDeltaJoules).clamp(9000, 36000);
    final double newRecovery =
        (rider.physiology.recoveryRate + mod.multiDayEnduranceDelta)
            .clamp(0.55, 1.35);
    final double newGlycogen =
        (rider.physiology.glycogenCapacityGrams + mod.glycogenCapacityDeltaGrams)
            .clamp(320.0, 680.0);

    // Skalowanie profilu mocy z zachowaniem monotoniczności krzywej MMP
    final int raw5s =
        (rider.powerProfile.watts5s * mod.explosivePower5sFactor).round();
    final int raw1m =
        (rider.powerProfile.watts1m * mod.explosivePower1mFactor).round();
    final double midFactor = (mod.explosivePower5sFactor + mod.explosivePower1mFactor) * 0.5;
    final int raw15s = (rider.powerProfile.watts15s * midFactor).round();
    final int raw30s = (rider.powerProfile.watts30s *
            (mod.explosivePower5sFactor * 0.35 + mod.explosivePower1mFactor * 0.65))
        .round();

    final double aerobicBridge = (mod.explosivePower1mFactor * 0.35 + mod.ftpFactor * 0.65);
    final int raw3m = (rider.powerProfile.watts3m * aerobicBridge).round();
    final int raw5m = (rider.powerProfile.watts5m *
            (mod.ftpFactor * 0.72 + (newVo2 / math.max(48.0, rider.physiology.vo2Max)) * 0.28))
        .round();
    final int raw20m = (rider.powerProfile.watts20m * mod.ftpFactor).round();

    final int new60m = newFtp;
    final int new20m = math.max(new60m + 10, raw20m);
    final int new5m = math.max(new20m + 15, raw5m);
    final int new3m = math.max(new5m + 15, raw3m);
    final int new1m = math.max(new3m + 35, raw1m);
    final int new30s = math.max(new1m + 45, raw30s);
    final int new15s = math.max(new30s + 60, raw15s);
    final int new5s = math.max(new15s + 70, raw5s);

    final newPowerProfile = rider.powerProfile.copyWith(
      watts5s: new5s,
      watts15s: new15s,
      watts30s: new30s,
      watts1m: new1m,
      watts3m: new3m,
      watts5m: new5m,
      watts20m: new20m,
      watts60m: new60m,
    );

    final LactateAndLabProfile currentLab = rider.labProfile;
    final double newEconomy = (currentLab.grossEfficiencyPercent +
            mod.pedalingEconomyDeltaPercent)
        .clamp(19.5, 25.0);
    final int newLt1 = (newFtp * currentLab.lt1PercentOfLt2 / 100.0).round();
    final int newMap = math.max(newFtp + 45, new5m);

    final LactateAndLabProfile updatedLab = currentLab.copyWith(
      lt1Watts: newLt1,
      lt2Watts: newFtp,
      vo2MaxMlKgMin: double.parse(newVo2.toStringAsFixed(1)),
      powerAtVo2MaxWatts: newMap,
      grossEfficiencyPercent: double.parse(newEconomy.toStringAsFixed(2)),
    );

    final newPhysiology = rider.physiology.copyWith(
      ftpWatts: newFtp,
      vo2Max: double.parse(newVo2.toStringAsFixed(1)),
      wPrimeJoules: newWPrime,
      recoveryRate: double.parse(newRecovery.toStringAsFixed(3)),
      glycogenCapacityGrams: double.parse(newGlycogen.toStringAsFixed(1)),
      labProfile: updatedLab,
    );

    final newSkills = rider.skills.copyWith(
      raceIq: (rider.skills.raceIq + mod.raceIqDelta).clamp(1, 99),
      draftingEfficiency:
          (rider.skills.draftingEfficiency + mod.draftingEfficiencyDelta)
              .clamp(1, 99),
      bikeHandling:
          (rider.skills.bikeHandling + (ageAtSeason <= 28 ? 1 : 0)).clamp(1, 99),
      aeroPositioning:
          (rider.skills.aeroPositioning + (ageAtSeason <= 27 ? 1 : 0))
              .clamp(1, 99),
      timeTrialPositioning:
          (rider.skills.timeTrialPositioning + (ageAtSeason <= 28 ? 1 : 0))
              .clamp(1, 99),
    );

    return rider.copyWith(
      physiology: newPhysiology,
      powerProfile: newPowerProfile,
      skills: newSkills,
    );
  }

  /// Symuluje pełną trajektorię ewolucji kolarza przez [seasons] sezonów (domyślnie 15).
  static MultiSeasonCareerTrajectoryReport projectTrajectory({
    required Rider rider,
    required int startSeasonYear,
    int seasons = defaultCareerHorizonSeasons,
    int? randomSeed,
  }) {
    final int clampedSeasons = seasons.clamp(1, 25);
    final int startAge = startSeasonYear - rider.birthDate.year;

    final List<RiderSeasonEvolutionSnapshot> snapshots = [];
    Rider current = rider;

    snapshots.add(
      _buildSnapshot(
        rider: current,
        seasonIndex: 0,
        seasonYear: startSeasonYear,
        age: startAge,
        deltas: null,
      ),
    );

    for (int i = 1; i <= clampedSeasons; i++) {
      final int year = startSeasonYear + i;
      final int age = year - current.birthDate.year;
      final RiderAgingCurveModifiers mod = computeAnnualModifiers(
        rider: current,
        ageAtSeasonStart: age,
        randomSeed: randomSeed != null ? randomSeed + i : null,
      );
      current = applyAnnualEvolution(
        rider: current,
        newSeasonYear: year,
        randomSeed: randomSeed != null ? randomSeed + i : null,
      );
      snapshots.add(
        _buildSnapshot(
          rider: current,
          seasonIndex: i,
          seasonYear: year,
          age: age,
          deltas: mod,
        ),
      );
    }

    RiderSeasonEvolutionSnapshot peakFtp = snapshots.first;
    RiderSeasonEvolutionSnapshot peakOvr = snapshots.first;
    RiderSeasonEvolutionSnapshot peak5s = snapshots.first;
    RiderSeasonEvolutionSnapshot peakEconIq = snapshots.first;

    for (final s in snapshots) {
      if (s.ftpWatts > peakFtp.ftpWatts) peakFtp = s;
      if (s.overallRating > peakOvr.overallRating) peakOvr = s;
      if (s.watts5s > peak5s.watts5s) peak5s = s;
      final double econIqScore =
          s.pedalingEconomyPercent * 4.0 + s.raceIq * 0.5 + s.thirdWeekFatigueResilience * 20.0;
      final double bestEconIqScore = peakEconIq.pedalingEconomyPercent * 4.0 +
          peakEconIq.raceIq * 0.5 +
          peakEconIq.thirdWeekFatigueResilience * 20.0;
      if (econIqScore > bestEconIqScore) peakEconIq = s;
    }

    return MultiSeasonCareerTrajectoryReport(
      riderId: rider.id,
      riderName: rider.fullName,
      specialization: rider.specialization,
      startingAge: startAge,
      seasonsSimulated: clampedSeasons,
      snapshots: snapshots,
      peakFtpSeason: peakFtp,
      peakOvrSeason: peakOvr,
      peakExplosive5sSeason: peak5s,
      peakEconomyAndIqSeason: peakEconIq,
    );
  }

  static RiderSeasonEvolutionSnapshot _buildSnapshot({
    required Rider rider,
    required int seasonIndex,
    required int seasonYear,
    required int age,
    required RiderAgingCurveModifiers? deltas,
  }) {
    final double economy = rider.labProfile.grossEfficiencyPercent;
    final double thirdWeek = computeThirdWeekResilienceScore(
      age: age,
      recoveryRate: rider.physiology.recoveryRate,
      grossEfficiencyPercent: economy,
      raceIq: rider.skills.raceIq,
    );

    return RiderSeasonEvolutionSnapshot(
      seasonIndex: seasonIndex,
      seasonYear: seasonYear,
      age: age,
      phase: phaseForAge(age),
      overallRating: rider.overallRating,
      ftpWatts: rider.physiology.ftpWatts,
      wattsPerKg: double.parse(rider.physiology.wattsPerKg.toStringAsFixed(2)),
      vo2Max: double.parse(rider.physiology.vo2Max.toStringAsFixed(1)),
      watts5s: rider.powerProfile.watts5s,
      watts1m: rider.powerProfile.watts1m,
      watts5m: rider.powerProfile.watts5m,
      watts20m: rider.powerProfile.watts20m,
      watts60m: rider.powerProfile.watts60m,
      wPrimeJoules: rider.physiology.wPrimeJoules,
      recoveryRate:
          double.parse(rider.physiology.recoveryRate.toStringAsFixed(3)),
      pedalingEconomyPercent: double.parse(economy.toStringAsFixed(2)),
      raceIq: rider.skills.raceIq,
      thirdWeekFatigueResilience: thirdWeek,
      deltasFromPrevious: deltas,
    );
  }
}

/// Kategoria metryk wyświetlana na interaktywnym wykresie 15-letniej krzywej kariery.
enum AgingCurveChartMetricGroup {
  ftpAndVo2,
  explosivePower,
  veteranEfficiency;

  String get label {
    switch (this) {
      case AgingCurveChartMetricGroup.ftpAndVo2:
        return 'FTP & VO2max';
      case AgingCurveChartMetricGroup.explosivePower:
        return 'Wybuchowość 5s / 1m';
      case AgingCurveChartMetricGroup.veteranEfficiency:
        return 'Ekonomia, IQ & 3. Tydzień';
    }
  }
}

/// Responsywny panel wizualizacji 15-sezonowej krzywej starzenia się i rozwoju kolarza.
class MultiSeasonRiderAgingCurvePanel extends StatefulWidget {
  final Rider rider;
  final int startSeasonYear;
  final int horizonSeasons;
  final ValueChanged<RiderSeasonEvolutionSnapshot>? onSeasonSelected;

  const MultiSeasonRiderAgingCurvePanel({
    super.key,
    required this.rider,
    this.startSeasonYear = 2026,
    this.horizonSeasons =
        MultiSeasonRiderAgingAndDeclineCurve.defaultCareerHorizonSeasons,
    this.onSeasonSelected,
  });

  @override
  State<MultiSeasonRiderAgingCurvePanel> createState() =>
      _MultiSeasonRiderAgingCurvePanelState();
}

class _MultiSeasonRiderAgingCurvePanelState
    extends State<MultiSeasonRiderAgingCurvePanel> {
  late MultiSeasonCareerTrajectoryReport _report;
  AgingCurveChartMetricGroup _selectedGroup =
      AgingCurveChartMetricGroup.ftpAndVo2;
  int _selectedSeasonIndex = 0;

  @override
  void initState() {
    super.initState();
    _recomputeReport();
  }

  @override
  void didUpdateWidget(covariant MultiSeasonRiderAgingCurvePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rider.id != widget.rider.id ||
        oldWidget.startSeasonYear != widget.startSeasonYear ||
        oldWidget.horizonSeasons != widget.horizonSeasons) {
      _recomputeReport();
    }
  }

  void _recomputeReport() {
    _report = MultiSeasonRiderAgingAndDeclineCurve.projectTrajectory(
      rider: widget.rider,
      startSeasonYear: widget.startSeasonYear,
      seasons: widget.horizonSeasons,
      randomSeed: 42,
    );
    _selectedSeasonIndex =
        _selectedSeasonIndex.clamp(0, _report.snapshots.length - 1);
  }

  void _selectSeason(int index) {
    final clamped = index.clamp(0, _report.snapshots.length - 1);
    setState(() {
      _selectedSeasonIndex = clamped;
    });
    widget.onSeasonSelected?.call(_report.snapshots[clamped]);
  }

  @override
  Widget build(BuildContext context) {
    final RiderSeasonEvolutionSnapshot active =
        _report.snapshots[_selectedSeasonIndex];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 640;
          final bool isWide = constraints.maxWidth >= 1024;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(active, isCompact),
                const SizedBox(height: 14),
                _buildMetricTabs(isCompact),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  child: Container(
                    key: ValueKey(_selectedGroup),
                    height: isCompact ? 190 : 220,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: CustomPaint(
                      painter: _AgingTrajectoryPainter(
                        snapshots: _report.snapshots,
                        metricGroup: _selectedGroup,
                        selectedIndex: _selectedSeasonIndex,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSeasonNavigator(active),
                const SizedBox(height: 14),
                _buildPhaseAndMetricsGrid(active, isCompact, isWide),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(RiderSeasonEvolutionSnapshot active, bool isCompact) {
    final Color phaseColor = active.phase.accentColor;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Krzywa Kariery (${_report.seasonsSimulated} Sezonów)',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_report.riderName} • ${_report.specialization.displayName}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: phaseColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: phaseColor.withValues(alpha: 0.45)),
          ),
          child: Text(
            '${active.age} lat • ${active.phase.displayName}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: phaseColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTabs(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AgingCurveChartMetricGroup.values.map((group) {
        final bool isSelected = _selectedGroup == group;
        return _InteractiveCurveChip(
          label: group.label,
          isSelected: isSelected,
          onPressed: () {
            setState(() => _selectedGroup = group);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSeasonNavigator(RiderSeasonEvolutionSnapshot active) {
    final bool canPrev = _selectedSeasonIndex > 0;
    final bool canNext = _selectedSeasonIndex < _report.snapshots.length - 1;

    return Row(
      children: [
        _InteractiveIconButton(
          icon: Icons.chevron_left,
          tooltip: 'Poprzedni sezon',
          enabled: canPrev,
          onPressed: canPrev ? () => _selectSeason(_selectedSeasonIndex - 1) : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _selectedSeasonIndex.toDouble(),
              min: 0,
              max: (_report.snapshots.length - 1).toDouble(),
              divisions: math.max(1, _report.snapshots.length - 1),
              label: '${active.seasonYear} (${active.age} lat)',
              onChanged: (val) => _selectSeason(val.round()),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _InteractiveIconButton(
          icon: Icons.chevron_right,
          tooltip: 'Następny sezon',
          enabled: canNext,
          onPressed: canNext ? () => _selectSeason(_selectedSeasonIndex + 1) : null,
        ),
      ],
    );
  }

  Widget _buildPhaseAndMetricsGrid(
    RiderSeasonEvolutionSnapshot active,
    bool isCompact,
    bool isWide,
  ) {
    final cards = [
      _MetricTile(
        label: 'FTP / W/kg',
        value: '${active.ftpWatts} W (${active.wattsPerKg.toStringAsFixed(2)})',
        accent: AppColors.goldAccent,
      ),
      _MetricTile(
        label: 'VO2max',
        value: '${active.vo2Max.toStringAsFixed(1)} ml/kg',
        accent: AppColors.cyanAccent,
      ),
      _MetricTile(
        label: 'Moc 5s / 1m',
        value: '${active.watts5s} W / ${active.watts1m} W',
        accent: AppColors.primaryAccent,
      ),
      _MetricTile(
        label: 'Ekonomia / Race IQ',
        value:
            '${active.pedalingEconomyPercent.toStringAsFixed(2)}% • IQ ${active.raceIq}',
        accent: AppColors.statusSuccess,
      ),
      _MetricTile(
        label: 'Odporność 3. Tydzień GT',
        value: '${(active.thirdWeekFatigueResilience * 100).round()}%',
        accent: AppColors.accentBlue,
      ),
      _MetricTile(
        label: 'Szczyt FTP / OVR',
        value:
            '${_report.peakFtpSeason.age} lat (${_report.peakFtpSeason.ftpWatts}W) • OVR ${_report.peakOvrSeason.overallRating}',
        accent: AppColors.amberWarning,
      ),
    ];

    final int crossAxisCount = isWide ? 3 : (isCompact ? 1 : 2);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isCompact ? 4.2 : 2.9,
      ),
      itemBuilder: (_, index) => cards[index],
    );
  }
}

class _InteractiveCurveChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _InteractiveCurveChip({
    required this.label,
    required this.isSelected,
    this.onPressed,
  });

  @override
  State<_InteractiveCurveChip> createState() => _InteractiveCurveChipState();
}

class _InteractiveCurveChipState extends State<_InteractiveCurveChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color bg = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.primaryAccent
            : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final Color border = _focused
        ? AppColors.goldAccent
        : (widget.isSelected ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onPressed;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    this.onPressed,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : (_pressed
            ? AppColors.primaryAccent
            : (_hovered ? AppColors.surfaceLight : AppColors.background));

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              widget.enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : AppColors.cardBorder,
                width: 1,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
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

class _AgingTrajectoryPainter extends CustomPainter {
  final List<RiderSeasonEvolutionSnapshot> snapshots;
  final AgingCurveChartMetricGroup metricGroup;
  final int selectedIndex;

  const _AgingTrajectoryPainter({
    required this.snapshots,
    required this.metricGroup,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final double y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final List<double> primarySeries;
    final List<double> secondarySeries;
    final Color primaryColor;
    final Color secondaryColor;

    switch (metricGroup) {
      case AgingCurveChartMetricGroup.ftpAndVo2:
        primarySeries = snapshots.map((s) => s.ftpWatts.toDouble()).toList();
        secondarySeries = snapshots.map((s) => s.vo2Max).toList();
        primaryColor = AppColors.goldAccent;
        secondaryColor = AppColors.cyanAccent;
        break;
      case AgingCurveChartMetricGroup.explosivePower:
        primarySeries = snapshots.map((s) => s.watts5s.toDouble()).toList();
        secondarySeries = snapshots.map((s) => s.watts1m.toDouble()).toList();
        primaryColor = AppColors.primaryAccent;
        secondaryColor = AppColors.amberWarning;
        break;
      case AgingCurveChartMetricGroup.veteranEfficiency:
        primarySeries =
            snapshots.map((s) => s.pedalingEconomyPercent).toList();
        secondarySeries = snapshots
            .map((s) => s.thirdWeekFatigueResilience * 100.0)
            .toList();
        primaryColor = AppColors.statusSuccess;
        secondaryColor = AppColors.accentBlue;
        break;
    }

    _drawNormalizedSeries(canvas, size, primarySeries, primaryColor);
    _drawNormalizedSeries(canvas, size, secondarySeries, secondaryColor);

    final double selectedX =
        (selectedIndex / (snapshots.length - 1)) * size.width;
    final Paint markerPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.85)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(selectedX, 0),
      Offset(selectedX, size.height),
      markerPaint,
    );
  }

  void _drawNormalizedSeries(
    Canvas canvas,
    Size size,
    List<double> values,
    Color color,
  ) {
    final double minVal = values.reduce(math.min);
    final double maxVal = values.reduce(math.max);
    final double span = math.max(1e-6, maxVal - minVal);

    final Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final double x = (i / (values.length - 1)) * size.width;
      final double normY = (values[i] - minVal) / span;
      final double y = size.height - (normY * (size.height - 12)) - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final int idx = selectedIndex.clamp(0, values.length - 1);
    final double dotX = (idx / (values.length - 1)) * size.width;
    final double dotNormY = (values[idx] - minVal) / span;
    final double dotY = size.height - (dotNormY * (size.height - 12)) - 6;
    canvas.drawCircle(
      Offset(dotX, dotY),
      4.5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _AgingTrajectoryPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.metricGroup != metricGroup ||
        oldDelegate.snapshots != snapshots;
  }
}
