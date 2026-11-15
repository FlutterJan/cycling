// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import '../../models/career/career_save.dart';
import '../../models/rider/lactate_and_lab_profile.dart';
import '../../models/rider/rider.dart';
import 'finance_and_budget_service.dart';
import 'training_and_camps_service.dart';

/// Wynik oceny kierunku adaptacji fizjologicznej kolarza na podstawie badań laboratoryjnych.
enum AdaptationVerdict {
  /// Znakomity progres we wszystkich kluczowych wskaźnikach docelowych dla danej specjalizacji
  optimalProgress,

  /// Podniesienie sufitu tlenowego: istotny wzrost VO2max i mocy MAP
  aerobicCeilingExpanded,

  /// Skuteczne stłumienie VLaMax u kolarza górskiego / czasowca – przesunięcie LT2 w górę i ochrona glikogenu
  glycolysisSuppressed,

  /// Wzmocnienie eksplozywności i pojemności glikolitycznej VLaMax u sprintera/punchera
  sprinterExplosivenessEnhanced,

  /// Równomierne przesunięcie całej krzywej mleczanowej w prawo (wyższa moc na LT1 i LT2)
  thresholdShiftedRight,

  /// Poprawa sprawności mechanicznej (Gross Efficiency) – mniejszy koszt energetyczny
  grossEfficiencyImproved,

  /// Brak istotnych zmian adaptacyjnych (plateau treningowe)
  stagnation,

  /// Ostre zmęczenie funkcjonalne (Functional Overreaching) – spadek parametrów szczytowych
  overreachingDetected,

  /// Poważny syndrom przetrenowania (Overtraining Syndrome) – stłumienie układu krążenia i układu wegetatywnego
  overtrainingDetected;

  String toJson() => name;

  static AdaptationVerdict fromJson(String value) {
    return AdaptationVerdict.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AdaptationVerdict.optimalProgress,
    );
  }

  /// Czytelny polski tytuł werdyktu adaptacyjnego
  String get displayName {
    switch (this) {
      case AdaptationVerdict.optimalProgress:
        return 'Optymalna Adaptacja Treningowa';
      case AdaptationVerdict.aerobicCeilingExpanded:
        return 'Powiększenie Pułapu Tlenowego (VO2max ↑)';
      case AdaptationVerdict.glycolysisSuppressed:
        return 'Stłumienie Glikolizy (VLaMax ↓ – Sukces Górala/Czasowca)';
      case AdaptationVerdict.sprinterExplosivenessEnhanced:
        return 'Wzrost Dynamiki Sprinterskiej (VLaMax ↑)';
      case AdaptationVerdict.thresholdShiftedRight:
        return 'Przesunięcie Krzywej Mleczanowej w Prawo (LT1 & LT2 ↑)';
      case AdaptationVerdict.grossEfficiencyImproved:
        return 'Poprawa Ekonomii Ruchu (Gross Efficiency ↑)';
      case AdaptationVerdict.stagnation:
        return 'Plateau Adaptacyjne (Brak Zmian)';
      case AdaptationVerdict.overreachingDetected:
        return 'Przemęczenie / Przeciążenie (Overreaching)';
      case AdaptationVerdict.overtrainingDetected:
        return 'Syndrom Przetrenowania (Overtraining)';
    }
  }

  /// Czy wynik badania wskazuje na pożądany kierunek rozwoju
  bool get isPositive =>
      this == AdaptationVerdict.optimalProgress ||
      this == AdaptationVerdict.aerobicCeilingExpanded ||
      this == AdaptationVerdict.glycolysisSuppressed ||
      this == AdaptationVerdict.sprinterExplosivenessEnhanced ||
      this == AdaptationVerdict.thresholdShiftedRight ||
      this == AdaptationVerdict.grossEfficiencyImproved;
}

/// Szczegółowy pojedynczy pomiar ze stopnia próby stopniowanej (Ramp Test: 100W, +30W co 3 minuty).
class LabTestStepSample {
  /// Numer stopnia (1, 2, 3...)
  final int stepNumber;

  /// Całkowity czas od rozpoczęcia testu w sekundach [s] (np. 180s, 360s, 540s...)
  final int elapsedSeconds;

  /// Obciążenie na trenażerze laboratoryjnym [W]
  final int powerWatts;

  /// Moc w odniesieniu do masy ciała kolarza [W/kg]
  final double wattsPerKg;

  /// Średnia kadencja z danego stopnia [RPM]
  final int cadenceRpm;

  /// Stężenie kwasu mlekowego we krwi włośniczkowej pobranej z opuszka ucha/palca na koniec stopnia [mmol/l]
  final double bloodLactateMmolL;

  /// Ustabilizowane tętno na koniec stopnia [bpm]
  final int heartRateBpm;

  /// Wentylacja minutowa płuc (Minute Ventilation - VE) [l/min]
  final double minuteVentilationVE;

  /// Względny pobór tlenu (VO2) [ml/kg/min]
  final double oxygenUptakeVO2MlKgMin;

  /// Bezwzględny pobór tlenu (VO2) [l/min]
  final double oxygenUptakeVO2LitersMin;

  /// Wydalanie dwutlenku węgla (VCO2) [l/min]
  final double carbonDioxideProductionVCO2LitersMin;

  /// Współczynnik wymiany oddechowej (Respiratory Exchange Ratio - RER = VCO2 / VO2)
  final double respiratoryExchangeRatioRER;

  /// Równoważnik wentylacyjny dla tlenu (VE / VO2)
  final double ventilatoryEquivalentO2;

  /// Równoważnik wentylacyjny dla dwutlenku węgla (VE / VCO2)
  final double ventilatoryEquivalentCO2;

  /// Szacowane tempo utleniania kwasów tłuszczowych [g/h]
  final double fatOxidationGramsPerHour;

  /// Szacowane tempo utleniania węglowodanów [g/h]
  final double carbOxidationGramsPerHour;

  /// Flaga potwierdzająca pobranie próbki krwi włośniczkowej pod koniec stopnia (mikronakłucie)
  final bool isBloodSampleTaken;

  const LabTestStepSample({
    required this.stepNumber,
    required this.elapsedSeconds,
    required this.powerWatts,
    required this.wattsPerKg,
    required this.cadenceRpm,
    required this.bloodLactateMmolL,
    required this.heartRateBpm,
    required this.minuteVentilationVE,
    required this.oxygenUptakeVO2MlKgMin,
    required this.oxygenUptakeVO2LitersMin,
    required this.carbonDioxideProductionVCO2LitersMin,
    required this.respiratoryExchangeRatioRER,
    required this.ventilatoryEquivalentO2,
    required this.ventilatoryEquivalentCO2,
    required this.fatOxidationGramsPerHour,
    required this.carbOxidationGramsPerHour,
    this.isBloodSampleTaken = true,
  });

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'elapsedSeconds': elapsedSeconds,
        'powerWatts': powerWatts,
        'wattsPerKg': wattsPerKg,
        'cadenceRpm': cadenceRpm,
        'bloodLactateMmolL': bloodLactateMmolL,
        'heartRateBpm': heartRateBpm,
        'minuteVentilationVE': minuteVentilationVE,
        'oxygenUptakeVO2MlKgMin': oxygenUptakeVO2MlKgMin,
        'oxygenUptakeVO2LitersMin': oxygenUptakeVO2LitersMin,
        'carbonDioxideProductionVCO2LitersMin': carbonDioxideProductionVCO2LitersMin,
        'respiratoryExchangeRatioRER': respiratoryExchangeRatioRER,
        'ventilatoryEquivalentO2': ventilatoryEquivalentO2,
        'ventilatoryEquivalentCO2': ventilatoryEquivalentCO2,
        'fatOxidationGramsPerHour': fatOxidationGramsPerHour,
        'carbOxidationGramsPerHour': carbOxidationGramsPerHour,
        'isBloodSampleTaken': isBloodSampleTaken,
      };

  factory LabTestStepSample.fromJson(Map<String, dynamic> json) => LabTestStepSample(
        stepNumber: (json['stepNumber'] as num).toInt(),
        elapsedSeconds: (json['elapsedSeconds'] as num).toInt(),
        powerWatts: (json['powerWatts'] as num).toInt(),
        wattsPerKg: (json['wattsPerKg'] as num).toDouble(),
        cadenceRpm: (json['cadenceRpm'] as num).toInt(),
        bloodLactateMmolL: (json['bloodLactateMmolL'] as num).toDouble(),
        heartRateBpm: (json['heartRateBpm'] as num).toInt(),
        minuteVentilationVE: (json['minuteVentilationVE'] as num).toDouble(),
        oxygenUptakeVO2MlKgMin: (json['oxygenUptakeVO2MlKgMin'] as num).toDouble(),
        oxygenUptakeVO2LitersMin: (json['oxygenUptakeVO2LitersMin'] as num).toDouble(),
        carbonDioxideProductionVCO2LitersMin:
            (json['carbonDioxideProductionVCO2LitersMin'] as num).toDouble(),
        respiratoryExchangeRatioRER: (json['respiratoryExchangeRatioRER'] as num).toDouble(),
        ventilatoryEquivalentO2: (json['ventilatoryEquivalentO2'] as num).toDouble(),
        ventilatoryEquivalentCO2: (json['ventilatoryEquivalentCO2'] as num).toDouble(),
        fatOxidationGramsPerHour: (json['fatOxidationGramsPerHour'] as num).toDouble(),
        carbOxidationGramsPerHour: (json['carbOxidationGramsPerHour'] as num).toDouble(),
        isBloodSampleTaken: json['isBloodSampleTaken'] as bool? ?? true,
      );
}

/// Analiza trendu fizjologicznego i porównanie z poprzednim badaniem laboratoryjnym.
class PhysiologicalTrendAnalysis {
  final DateTime? previousTestDate;
  final int daysSincePreviousTest;

  // Zmiany kluczowych parametrów (nowy - poprzedni)
  final double vo2MaxDeltaMlKgMin;
  final double vlaMaxDeltaMmolLPerSec;
  final int lt1WattsDelta;
  final int lt2WattsDelta;
  final double grossEfficiencyDeltaPercent;
  final double weightDeltaKg;

  /// Czy odnotowano pożądane obniżenie VLaMax u kolarza górskiego / czasowca
  final bool isVlaMaxDecreasedForClimber;

  /// Czy odnotowano wzrost pułapu tlenowego VO2max
  final bool isVo2MaxIncreased;

  /// Czy krzywa mleczanowa uległa korzystnemu przesunięciu w prawo (niższy mleczan przy tej samej mocy)
  final bool isLactateCurveShiftedRight;

  /// Czy trening generalnie zmierza w dobrą stronę dla tego profilu kolarza
  final bool isTrainingGoingInRightDirection;

  /// Końcowy werdykt adaptacyjny
  final AdaptationVerdict verdict;

  /// Podsumowanie werdyktu
  final String verdictSummary;

  /// Wskaźnik punktowy adaptacji fizjologicznej (0 - 100 pkt)
  final int adaptationScore;

  const PhysiologicalTrendAnalysis({
    this.previousTestDate,
    required this.daysSincePreviousTest,
    required this.vo2MaxDeltaMlKgMin,
    required this.vlaMaxDeltaMmolLPerSec,
    required this.lt1WattsDelta,
    required this.lt2WattsDelta,
    required this.grossEfficiencyDeltaPercent,
    required this.weightDeltaKg,
    required this.isVlaMaxDecreasedForClimber,
    required this.isVo2MaxIncreased,
    required this.isLactateCurveShiftedRight,
    required this.isTrainingGoingInRightDirection,
    required this.verdict,
    required this.verdictSummary,
    required this.adaptationScore,
  });

  Map<String, dynamic> toJson() => {
        'previousTestDate': previousTestDate?.toIso8601String(),
        'daysSincePreviousTest': daysSincePreviousTest,
        'vo2MaxDeltaMlKgMin': vo2MaxDeltaMlKgMin,
        'vlaMaxDeltaMmolLPerSec': vlaMaxDeltaMmolLPerSec,
        'lt1WattsDelta': lt1WattsDelta,
        'lt2WattsDelta': lt2WattsDelta,
        'grossEfficiencyDeltaPercent': grossEfficiencyDeltaPercent,
        'weightDeltaKg': weightDeltaKg,
        'isVlaMaxDecreasedForClimber': isVlaMaxDecreasedForClimber,
        'isVo2MaxIncreased': isVo2MaxIncreased,
        'isLactateCurveShiftedRight': isLactateCurveShiftedRight,
        'isTrainingGoingInRightDirection': isTrainingGoingInRightDirection,
        'verdict': verdict.toJson(),
        'verdictSummary': verdictSummary,
        'adaptationScore': adaptationScore,
      };

  factory PhysiologicalTrendAnalysis.fromJson(Map<String, dynamic> json) =>
      PhysiologicalTrendAnalysis(
        previousTestDate: json['previousTestDate'] != null
            ? DateTime.parse(json['previousTestDate'] as String)
            : null,
        daysSincePreviousTest: (json['daysSincePreviousTest'] as num).toInt(),
        vo2MaxDeltaMlKgMin: (json['vo2MaxDeltaMlKgMin'] as num).toDouble(),
        vlaMaxDeltaMmolLPerSec: (json['vlaMaxDeltaMmolLPerSec'] as num).toDouble(),
        lt1WattsDelta: (json['lt1WattsDelta'] as num).toInt(),
        lt2WattsDelta: (json['lt2WattsDelta'] as num).toInt(),
        grossEfficiencyDeltaPercent:
            (json['grossEfficiencyDeltaPercent'] as num).toDouble(),
        weightDeltaKg: (json['weightDeltaKg'] as num).toDouble(),
        isVlaMaxDecreasedForClimber: json['isVlaMaxDecreasedForClimber'] as bool,
        isVo2MaxIncreased: json['isVo2MaxIncreased'] as bool,
        isLactateCurveShiftedRight: json['isLactateCurveShiftedRight'] as bool,
        isTrainingGoingInRightDirection: json['isTrainingGoingInRightDirection'] as bool,
        verdict: AdaptationVerdict.fromJson(json['verdict'] as String),
        verdictSummary: json['verdictSummary'] as String,
        adaptationScore: (json['adaptationScore'] as num).toInt(),
      );
}

/// Pełny raport z przeprowadzonego badania laboratoryjnego w centrum wydolnościowym.
class PhysiologyLabTestReport {
  final String riderId;
  final String riderName;
  final int riderAge;
  final RiderSpecialization riderSpecialization;
  final DateTime testDate;
  final double weightKg;
  final double testDurationMinutes;
  final String exhaustionReason;

  // --- ZMIERZONE PROGI FIZJOLOGICZNE ---
  final int measuredLt1Watts;
  final double measuredLt1WattsPerKg;
  final double measuredLt1Lactate;
  final int measuredLt1Hr;
  final double measuredLt1Ventilation;

  final int measuredLt2Watts;
  final double measuredLt2WattsPerKg;
  final double measuredLt2Lactate;
  final int measuredLt2Hr;
  final double measuredLt2Ventilation;

  final double measuredVo2MaxMlKgMin;
  final double measuredVo2MaxLitersMin;
  final int measuredMaxAerobicPowerWatts;
  final int measuredMaxHeartRate;
  final double measuredMaxVentilation;

  final double measuredVlaMax;
  final double measuredGrossEfficiencyPercent;
  final double measuredDeltaEfficiencyPercent;

  final int fatMaxWatts;
  final double fatMaxOxidationGramsPerHour;

  /// Wszystkie stopnie pomiarowe protokołu stopniowanego (100W, +30W / 3 min)
  final List<LabTestStepSample> steps;

  /// Zaktualizowane i spersonalizowane strefy treningowe
  final List<LabTrainingZone> trainingZones;

  /// Nowy, skalibrowany profil laboratoryjny kolarza
  final LactateAndLabProfile newLabProfile;

  /// Ocena kierunku adaptacji fizjologicznej i porównanie z historią
  final PhysiologicalTrendAnalysis trendAnalysis;

  /// Diagnoza szefa fizjologii zespołu
  final String diagnosticSummary;

  /// Konkretne rekomendacje treningowe i żywieniowe dla trenera
  final List<String> coachRecommendations;

  const PhysiologyLabTestReport({
    required this.riderId,
    required this.riderName,
    required this.riderAge,
    required this.riderSpecialization,
    required this.testDate,
    required this.weightKg,
    required this.testDurationMinutes,
    required this.exhaustionReason,
    required this.measuredLt1Watts,
    required this.measuredLt1WattsPerKg,
    required this.measuredLt1Lactate,
    required this.measuredLt1Hr,
    required this.measuredLt1Ventilation,
    required this.measuredLt2Watts,
    required this.measuredLt2WattsPerKg,
    required this.measuredLt2Lactate,
    required this.measuredLt2Hr,
    required this.measuredLt2Ventilation,
    required this.measuredVo2MaxMlKgMin,
    required this.measuredVo2MaxLitersMin,
    required this.measuredMaxAerobicPowerWatts,
    required this.measuredMaxHeartRate,
    required this.measuredMaxVentilation,
    required this.measuredVlaMax,
    required this.measuredGrossEfficiencyPercent,
    required this.measuredDeltaEfficiencyPercent,
    required this.fatMaxWatts,
    required this.fatMaxOxidationGramsPerHour,
    required this.steps,
    required this.trainingZones,
    required this.newLabProfile,
    required this.trendAnalysis,
    required this.diagnosticSummary,
    required this.coachRecommendations,
  });

  /// Konwertuje raport do formatu [PhysiologicalTestResult] dla modułu finansów i kariery.
  PhysiologicalTestResult toPhysiologicalTestResult() {
    return PhysiologicalTestResult(
      riderId: riderId,
      riderName: riderName,
      testType: PhysiologicalTestType.fullPhysiologicalAudit,
      testDate: testDate,
      measuredFtpWatts: measuredLt2Watts.toDouble(),
      measuredVo2Max: measuredVo2MaxMlKgMin,
      measuredMaxHeartRate: measuredMaxHeartRate,
      lactateThresholdWatts: measuredLt2Watts.toDouble(),
      fatigueIndexPercent: (100.0 - trendAnalysis.adaptationScore).clamp(0.0, 100.0),
      isOvertrained: trendAnalysis.verdict == AdaptationVerdict.overtrainingDetected ||
          trendAnalysis.verdict == AdaptationVerdict.overreachingDetected,
      summary: diagnosticSummary,
      recommendation: coachRecommendations.join(' '),
      labProfile: newLabProfile,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'riderAge': riderAge,
        'riderSpecialization': riderSpecialization.toJson(),
        'testDate': testDate.toIso8601String(),
        'weightKg': weightKg,
        'testDurationMinutes': testDurationMinutes,
        'exhaustionReason': exhaustionReason,
        'measuredLt1Watts': measuredLt1Watts,
        'measuredLt1WattsPerKg': measuredLt1WattsPerKg,
        'measuredLt1Lactate': measuredLt1Lactate,
        'measuredLt1Hr': measuredLt1Hr,
        'measuredLt1Ventilation': measuredLt1Ventilation,
        'measuredLt2Watts': measuredLt2Watts,
        'measuredLt2WattsPerKg': measuredLt2WattsPerKg,
        'measuredLt2Lactate': measuredLt2Lactate,
        'measuredLt2Hr': measuredLt2Hr,
        'measuredLt2Ventilation': measuredLt2Ventilation,
        'measuredVo2MaxMlKgMin': measuredVo2MaxMlKgMin,
        'measuredVo2MaxLitersMin': measuredVo2MaxLitersMin,
        'measuredMaxAerobicPowerWatts': measuredMaxAerobicPowerWatts,
        'measuredMaxHeartRate': measuredMaxHeartRate,
        'measuredMaxVentilation': measuredMaxVentilation,
        'measuredVlaMax': measuredVlaMax,
        'measuredGrossEfficiencyPercent': measuredGrossEfficiencyPercent,
        'measuredDeltaEfficiencyPercent': measuredDeltaEfficiencyPercent,
        'fatMaxWatts': fatMaxWatts,
        'fatMaxOxidationGramsPerHour': fatMaxOxidationGramsPerHour,
        'steps': steps.map((s) => s.toJson()).toList(),
        'trainingZones': trainingZones.map((z) => z.toJson()).toList(),
        'newLabProfile': newLabProfile.toJson(),
        'trendAnalysis': trendAnalysis.toJson(),
        'diagnosticSummary': diagnosticSummary,
        'coachRecommendations': coachRecommendations,
      };

  factory PhysiologyLabTestReport.fromJson(Map<String, dynamic> json) =>
      PhysiologyLabTestReport(
        riderId: json['riderId'] as String,
        riderName: json['riderName'] as String,
        riderAge: (json['riderAge'] as num).toInt(),
        riderSpecialization:
            RiderSpecialization.fromJson(json['riderSpecialization'] as String),
        testDate: DateTime.parse(json['testDate'] as String),
        weightKg: (json['weightKg'] as num).toDouble(),
        testDurationMinutes: (json['testDurationMinutes'] as num).toDouble(),
        exhaustionReason: json['exhaustionReason'] as String,
        measuredLt1Watts: (json['measuredLt1Watts'] as num).toInt(),
        measuredLt1WattsPerKg: (json['measuredLt1WattsPerKg'] as num).toDouble(),
        measuredLt1Lactate: (json['measuredLt1Lactate'] as num).toDouble(),
        measuredLt1Hr: (json['measuredLt1Hr'] as num).toInt(),
        measuredLt1Ventilation: (json['measuredLt1Ventilation'] as num).toDouble(),
        measuredLt2Watts: (json['measuredLt2Watts'] as num).toInt(),
        measuredLt2WattsPerKg: (json['measuredLt2WattsPerKg'] as num).toDouble(),
        measuredLt2Lactate: (json['measuredLt2Lactate'] as num).toDouble(),
        measuredLt2Hr: (json['measuredLt2Hr'] as num).toInt(),
        measuredLt2Ventilation: (json['measuredLt2Ventilation'] as num).toDouble(),
        measuredVo2MaxMlKgMin: (json['measuredVo2MaxMlKgMin'] as num).toDouble(),
        measuredVo2MaxLitersMin: (json['measuredVo2MaxLitersMin'] as num).toDouble(),
        measuredMaxAerobicPowerWatts:
            (json['measuredMaxAerobicPowerWatts'] as num).toInt(),
        measuredMaxHeartRate: (json['measuredMaxHeartRate'] as num).toInt(),
        measuredMaxVentilation: (json['measuredMaxVentilation'] as num).toDouble(),
        measuredVlaMax: (json['measuredVlaMax'] as num).toDouble(),
        measuredGrossEfficiencyPercent:
            (json['measuredGrossEfficiencyPercent'] as num).toDouble(),
        measuredDeltaEfficiencyPercent:
            (json['measuredDeltaEfficiencyPercent'] as num).toDouble(),
        fatMaxWatts: (json['fatMaxWatts'] as num).toInt(),
        fatMaxOxidationGramsPerHour:
            (json['fatMaxOxidationGramsPerHour'] as num).toDouble(),
        steps: (json['steps'] as List)
            .map((s) => LabTestStepSample.fromJson(s as Map<String, dynamic>))
            .toList(),
        trainingZones: (json['trainingZones'] as List)
            .map((z) => LabTrainingZone.fromJson(z as Map<String, dynamic>))
            .toList(),
        newLabProfile: LactateAndLabProfile.fromJson(
            json['newLabProfile'] as Map<String, dynamic>),
        trendAnalysis: PhysiologicalTrendAnalysis.fromJson(
            json['trendAnalysis'] as Map<String, dynamic>),
        diagnosticSummary: json['diagnosticSummary'] as String,
        coachRecommendations:
            (json['coachRecommendations'] as List).map((e) => e.toString()).toList(),
      );
}

/// Serwis przeprowadzania kompleksowych badań wydolnościowych w laboratorium drużyny.
///
/// Łączy:
/// 1. Ergospirometrię w masce oddechowej (pobór tlenu VO2, VCO2, wentylacja minutowa VE, RER).
/// 2. Próbę stopniowaną z analizą kinetyki mleczanu we krwi (mikronakłucia ucha/palca co stopień).
/// 3. Protokół laboratoryjny: start od 100W, wzrost o +30W co 3 minuty aż do odmowy.
/// 4. Precyzyjne wyznaczenie progów LT1/VT1 (tlenowy/FatMax) oraz LT2/VT2/MLSS (beztlenowy).
/// 5. Wyznaczenie 7 spersonalizowanych stref treningowych.
/// 6. Analizę kierunku adaptacji: wykrywanie obniżenia VLaMax u górali lub wzrostu VO2max.
class PhysiologyLabTestingService {
  PhysiologyLabTestingService._();

  /// Startowe obciążenie protokołu stopniowanego [W]
  static const int protocolStartWatts = 100;

  /// Krok obciążenia w Watach (+30W)
  static const int protocolStepWatts = 30;

  /// Czas trwania pojedynczego stopnia [s] (3 minuty = 180 sekund dla ustabilizowania mleczanu)
  static const int protocolStepDurationSeconds = 180;

  /// Przeprowadza pełną procedurę badania laboratoryjnego dla zadanego kolarza [Rider].
  ///
  /// - [rider]: badany kolarz drużyny
  /// - [testDate]: data badania (domyślnie bieżąca)
  /// - [recentFocus]: realizowany w ostatnim okresie fokus treningowy
  /// - [previousProfile]: poprzedni profil laboratoryjny do analizy trendu (opcjonalny)
  /// - [previousTestDate]: data poprzedniego badania (opcjonalna)
  /// - [simulateOvertraining]: czy zasymulować syndrom przemęczenia (np. po Grand Tourze)
  static PhysiologyLabTestReport conductRampTest({
    required Rider rider,
    DateTime? testDate,
    RiderTrainingFocus? recentFocus,
    LactateAndLabProfile? previousProfile,
    DateTime? previousTestDate,
    bool simulateOvertraining = false,
  }) {
    final effectiveDate = testDate ?? DateTime.now();
    final phys = rider.physiology;
    final weight = phys.weightKg > 0 ? phys.weightKg : 70.0;
    final baseProfile = previousProfile ?? rider.labProfile;

    // 1. Wyznaczenie aktualnego stanu adaptacji fizjologicznej
    final adaptation = _evaluatePhysiologicalAdaptation(
      rider: rider,
      baseProfile: baseProfile,
      recentFocus: recentFocus,
      simulateOvertraining: simulateOvertraining,
    );

    final calibratedProfile = adaptation.calibratedProfile;

    // 2. Generowanie sekwencji stopni pomiarowych próby stopniowanej (start 100W, +30W co 3 min)
    final stepResults = _simulateRampProtocol(
      rider: rider,
      profile: calibratedProfile,
      weightKg: weight,
      isOvertrained: adaptation.isOvertrained,
    );

    // 3. Wyznaczenie zaktualizowanych stref treningowych
    final zones = calibratedProfile.getTrainingZones();

    // 4. Analiza trendu fizjologicznego i ocena kierunku adaptacji
    final trend = _analyzeTrend(
      rider: rider,
      previousProfile: baseProfile,
      currentProfile: calibratedProfile,
      previousTestDate: previousTestDate,
      currentTestDate: effectiveDate,
      isOvertrained: adaptation.isOvertrained,
      recentFocus: recentFocus,
    );

    // 5. Diagnoza szefa wydolności i rekomendacje treningowe
    final diagnostic = _generateDiagnosticSummary(rider, calibratedProfile, trend);
    final recommendations = _generateCoachRecommendations(rider, calibratedProfile, trend);

    final lastStep = stepResults.steps.last;
    final totalDurationMinutes = (lastStep.elapsedSeconds / 60.0);

    return PhysiologyLabTestReport(
      riderId: rider.id,
      riderName: rider.fullName,
      riderAge: rider.age,
      riderSpecialization: rider.specialization,
      testDate: effectiveDate,
      weightKg: weight,
      testDurationMinutes: double.parse(totalDurationMinutes.toStringAsFixed(1)),
      exhaustionReason: stepResults.exhaustionReason,
      measuredLt1Watts: calibratedProfile.lt1Watts,
      measuredLt1WattsPerKg: calibratedProfile.lt1WattsPerKg,
      measuredLt1Lactate: calibratedProfile.lt1LactateMmolL,
      measuredLt1Hr: calibratedProfile.lt1HeartRateBpm,
      measuredLt1Ventilation: stepResults.lt1Ventilation,
      measuredLt2Watts: calibratedProfile.lt2Watts,
      measuredLt2WattsPerKg: calibratedProfile.lt2WattsPerKg,
      measuredLt2Lactate: calibratedProfile.lt2LactateMmolL,
      measuredLt2Hr: calibratedProfile.lt2HeartRateBpm,
      measuredLt2Ventilation: stepResults.lt2Ventilation,
      measuredVo2MaxMlKgMin: calibratedProfile.vo2MaxMlKgMin,
      measuredVo2MaxLitersMin: calibratedProfile.vo2MaxAbsoluteLitersMin,
      measuredMaxAerobicPowerWatts: calibratedProfile.powerAtVo2MaxWatts,
      measuredMaxHeartRate: stepResults.peakHeartRate,
      measuredMaxVentilation: stepResults.peakVentilation,
      measuredVlaMax: calibratedProfile.vlaMaxMmolLPerSec,
      measuredGrossEfficiencyPercent: calibratedProfile.grossEfficiencyPercent,
      measuredDeltaEfficiencyPercent: calibratedProfile.deltaEfficiencyPercent,
      fatMaxWatts: calibratedProfile.fatMaxWatts,
      fatMaxOxidationGramsPerHour: calibratedProfile.fatMaxOxidationRateGramsPerHour,
      steps: stepResults.steps,
      trainingZones: zones,
      newLabProfile: calibratedProfile,
      trendAnalysis: trend,
      diagnosticSummary: diagnostic,
      coachRecommendations: recommendations,
    );
  }

  /// Przeprowadza badanie dla całej kadry zespołu (Team Fleet Screening).
  static List<PhysiologyLabTestReport> conductTeamFleetScreening({
    required List<Rider> riders,
    DateTime? testDate,
  }) {
    final effectiveDate = testDate ?? DateTime.now();
    return riders
        .map((r) => conductRampTest(
              rider: r,
              testDate: effectiveDate,
            ))
        .toList();
  }

  /// Aplikuje wyniki badań do profilu zawodnika [Rider], aktualizując jego stan fizjologiczny i FTP.
  static Rider applyReportToRider(Rider rider, PhysiologyLabTestReport report) {
    final updatedPhysiology = rider.physiology.copyWith(
      ftpWatts: report.measuredLt2Watts,
      criticalPowerWatts: report.measuredLt2Watts,
      vo2Max: report.measuredVo2MaxMlKgMin,
      lactateThresholdHr: report.measuredLt2Hr,
      labProfile: report.newLabProfile,
    );

    final updatedPower = rider.powerProfile.copyWith(
      watts60m: report.measuredLt2Watts,
      watts5m: report.measuredMaxAerobicPowerWatts,
    );

    return rider.copyWith(
      physiology: updatedPhysiology,
      powerProfile: updatedPower,
    );
  }

  /// Aplikuje raport z badań do stanu zapisu kariery [CareerSave].
  static CareerSave applyReportToSave(CareerSave save, PhysiologyLabTestReport report) {
    final riderIndex = save.riders.indexWhere((r) => r.id == report.riderId);
    if (riderIndex < 0) return save;

    final rider = save.riders[riderIndex];
    final updatedRider = applyReportToRider(rider, report);

    final updatedRiders = List<Rider>.from(save.riders);
    updatedRiders[riderIndex] = updatedRider;

    return save.copyWith(riders: updatedRiders);
  }

  // =========================================================================
  // LOGIKA MODELOWANIA PROTOKOŁU STOPNIOWANEGO (100W, +30W / 3 MIN)
  // =========================================================================

  static _RampProtocolResult _simulateRampProtocol({
    required Rider rider,
    required LactateAndLabProfile profile,
    required double weightKg,
    required bool isOvertrained,
  }) {
    final List<LabTestStepSample> steps = [];
    int currentPower = protocolStartWatts;
    int stepIndex = 1;
    int elapsedSeconds = 0;

    // Próg odmowy kolarza (Volitional Exhaustion):
    // Zazwyczaj kolarz dochodzi do stopnia przewyższającego MAP o ok. 20-40W,
    // gdzie zakwaszenie i zadyszka uniemożliwiają kontynuację.
    final int maxTolerablePower = isOvertrained
        ? (profile.powerAtVo2MaxWatts * 0.94).round()
        : (profile.powerAtVo2MaxWatts + 30);

    double lt1Ve = 62.0;
    double lt2Ve = 108.0;
    double peakVe = 165.0;
    int peakHr = 185;

    final maxHr = isOvertrained
        ? (rider.physiology.maxHr - 10) // Stłumienie tętna przy przetrenowaniu!
        : rider.physiology.maxHr;

    while (currentPower <= maxTolerablePower + protocolStepWatts) {
      elapsedSeconds += protocolStepDurationSeconds;
      final double wKg = currentPower / weightKg;

      // 1. Stężenie mleczanu we krwi włośniczkowej
      double lactate = profile.estimateLactateAtPower(currentPower.toDouble());
      if (isOvertrained && currentPower <= profile.lt2Watts) {
        lactate += 0.4; // Podwyższony mleczan spoczynkowy/podprogowy
      }

      // 2. Tętno z ergometru
      int hr = profile.estimateHeartRateAtPower(
        currentPower.toDouble(),
        restingHr: rider.physiology.restingHr,
        maxHr: maxHr,
      );

      // 3. Wentylacja minutowa płuc VE [l/min] (Ergospirometria)
      // Fizjologia:
      // - Do VT1: wentylacja rośnie liniowo z poborem tlenu (~30-65 l/min)
      // - VT1 do VT2: hiperwentylacja kompensacyjna w celu usuwania nadmiaru CO2
      // - Powyżej VT2/MLSS: lawinowy skok wentylacji (kwasica metaboliczna, VE osiąga 150-210 l/min)
      double ve;
      if (currentPower <= profile.lt1Watts) {
        ve = 32.0 + (currentPower / profile.lt1Watts) * 30.0;
      } else if (currentPower <= profile.lt2Watts) {
        final double fraction = (currentPower - profile.lt1Watts) /
            math.max(1.0, (profile.lt2Watts - profile.lt1Watts).toDouble());
        ve = 62.0 + fraction * 48.0;
      } else {
        // Powyżej LT2 / VT2 – stroma krzywa hiperwentylacji
        final double overPower = (currentPower - profile.lt2Watts).toDouble();
        final double excessRatio = overPower / 60.0;
        final double acidosisFactor = math.pow(excessRatio, 1.45) * 45.0;
        ve = 110.0 + acidosisFactor;
      }
      ve = ve.clamp(28.0, 220.0);

      // 4. Pobór tlenu VO2 i wydalanie dwutlenku węgla VCO2
      final combustion = profile.estimateSubstrateOxidation(currentPower.toDouble());
      final double vo2MlKg = (profile.vo2MaxMlKgMin *
              (currentPower / math.max(1.0, profile.powerAtVo2MaxWatts.toDouble())))
          .clamp(14.0, profile.vo2MaxMlKgMin * 1.05);

      final double vo2Liters = (vo2MlKg * weightKg) / 1000.0;
      final double rer = combustion.respiratoryExchangeRatioRer;
      final double vco2Liters = vo2Liters * rer;

      // 5. Równoważniki wentylacyjne
      final double eqO2 = vo2Liters > 0 ? ve / vo2Liters : 25.0;
      final double eqCO2 = vco2Liters > 0 ? ve / vco2Liters : 28.0;

      // 6. Kadencja: spada przy skrajnym zmęczeniu
      int cadence = 92;
      if (currentPower >= profile.powerAtVo2MaxWatts) {
        cadence = 82;
      }
      if (currentPower >= maxTolerablePower) {
        cadence = 71; // Zbliżanie się do odmowy
      }

      steps.add(
        LabTestStepSample(
          stepNumber: stepIndex,
          elapsedSeconds: elapsedSeconds,
          powerWatts: currentPower,
          wattsPerKg: double.parse(wKg.toStringAsFixed(2)),
          cadenceRpm: cadence,
          bloodLactateMmolL: double.parse(lactate.toStringAsFixed(2)),
          heartRateBpm: hr,
          minuteVentilationVE: double.parse(ve.toStringAsFixed(1)),
          oxygenUptakeVO2MlKgMin: double.parse(vo2MlKg.toStringAsFixed(1)),
          oxygenUptakeVO2LitersMin: double.parse(vo2Liters.toStringAsFixed(2)),
          carbonDioxideProductionVCO2LitersMin: double.parse(vco2Liters.toStringAsFixed(2)),
          respiratoryExchangeRatioRER: double.parse(rer.toStringAsFixed(2)),
          ventilatoryEquivalentO2: double.parse(eqO2.toStringAsFixed(1)),
          ventilatoryEquivalentCO2: double.parse(eqCO2.toStringAsFixed(1)),
          fatOxidationGramsPerHour: combustion.fatOxidationRateGramsPerHour,
          carbOxidationGramsPerHour: combustion.carbOxidationRateGramsPerHour,
          isBloodSampleTaken: true,
        ),
      );

      if (currentPower == profile.lt1Watts ||
          (currentPower < profile.lt1Watts && currentPower + protocolStepWatts > profile.lt1Watts)) {
        lt1Ve = ve;
      }
      if (currentPower == profile.lt2Watts ||
          (currentPower < profile.lt2Watts && currentPower + protocolStepWatts > profile.lt2Watts)) {
        lt2Ve = ve;
      }

      peakVe = math.max(peakVe, ve);
      peakHr = math.max(peakHr, hr);

      if (currentPower >= maxTolerablePower) {
        break;
      }

      currentPower += protocolStepWatts;
      stepIndex++;
    }

    String exhaustionReason;
    if (isOvertrained) {
      exhaustionReason =
          'Odmowa z powodu ostrego przemęczenia ośrodkowego. Spadek kadencji poniżej 70 RPM, brak możliwości osiągnięcia tętna maksymalnego.';
    } else {
      exhaustionReason =
          'Osiągnięcie plateau VO2max (pułap tlenowy) oraz skrajna kwasica mleczanowa (> 10 mmol/l). Spadek kadencji z 92 do 70 RPM.';
    }

    return _RampProtocolResult(
      steps: steps,
      lt1Ventilation: double.parse(lt1Ve.toStringAsFixed(1)),
      lt2Ventilation: double.parse(lt2Ve.toStringAsFixed(1)),
      peakVentilation: double.parse(peakVe.toStringAsFixed(1)),
      peakHeartRate: peakHr,
      exhaustionReason: exhaustionReason,
    );
  }

  // =========================================================================
  // ANALIZA KIERUNKU ADAPTACJI FIZJOLOGICZNEJ
  // =========================================================================

  static _AdaptationEvaluation _evaluatePhysiologicalAdaptation({
    required Rider rider,
    required LactateAndLabProfile baseProfile,
    required RiderTrainingFocus? recentFocus,
    required bool simulateOvertraining,
  }) {
    final health = rider.health;
    final isOvertrained = simulateOvertraining ||
        health.acuteTrainingLoad > 115.0 ||
        health.trainingStressBalance < -25.0;

    int newLt1 = baseProfile.lt1Watts;
    int newLt2 = baseProfile.lt2Watts;
    double newVlaMax = baseProfile.vlaMaxMmolLPerSec;
    double newVo2Max = baseProfile.vo2MaxMlKgMin;
    double newEfficiency = baseProfile.grossEfficiencyPercent;
    int newMap = baseProfile.powerAtVo2MaxWatts;

    if (isOvertrained) {
      // Syndrom przeciążenia/przetrenowania: spadek VO2max, spadek mocy progowej, gorsza ekonomia
      newLt1 -= 12;
      newLt2 -= 16;
      newVo2Max = (newVo2Max - 2.2).clamp(45.0, 95.0);
      newEfficiency = (newEfficiency - 0.8).clamp(18.0, 26.0);
      newMap -= 20;
    } else if (recentFocus != null) {
      switch (recentFocus) {
        case RiderTrainingFocus.baseBuilding:
          // Baza tlenowa: przesunięcie LT1 w górę, obniżenie VLaMax, wzrost utleniania tłuszczu
          newLt1 += 8;
          newLt2 += 4;
          newVlaMax = (newVlaMax - 0.04).clamp(0.20, 0.95);
          newEfficiency = (newEfficiency + 0.3).clamp(19.0, 25.0);
          break;

        case RiderTrainingFocus.ftpDevelopment:
          // Praca na progu: przesunięcie LT2 w górę, lekkie obniżenie VLaMax
          newLt1 += 5;
          newLt2 += 12;
          newVlaMax = (newVlaMax - 0.03).clamp(0.20, 0.95);
          newMap += 8;
          break;

        case RiderTrainingFocus.vo2maxIntervals:
          // Interwały tlenowe: powiększenie pułapu VO2max i MAP
          newVo2Max = (newVo2Max + 1.8).clamp(50.0, 95.0);
          newMap += 18;
          newLt2 += 6;
          // Może lekko podbić VLaMax przez wysoką intensywność
          newVlaMax = (newVlaMax + 0.02).clamp(0.20, 0.95);
          break;

        case RiderTrainingFocus.sprintNeuromuscular:
          // Trening sprinterski: wyraźny wzrost VLaMax i mocy beztlenowej
          newVlaMax = (newVlaMax + 0.07).clamp(0.20, 0.98);
          // Może nieznacznie obniżyć LT2 z powodu szybszej glikolizy
          newLt2 -= 4;
          break;

        case RiderTrainingFocus.timeTrialAero:
          // Trening czasowy: obniżenie VLaMax, wzrost LT2 i ekonomii jazdy
          newVlaMax = (newVlaMax - 0.05).clamp(0.20, 0.95);
          newLt2 += 10;
          newEfficiency = (newEfficiency + 0.5).clamp(19.0, 25.5);
          break;

        case RiderTrainingFocus.activeRecovery:
          // Tapering: optymalizacja sprawności układu nerwowego
          newEfficiency = (newEfficiency + 0.2).clamp(19.0, 25.0);
          break;
      }
    }

    final updatedProfile = baseProfile.copyWith(
      lt1Watts: newLt1,
      lt2Watts: newLt2,
      vlaMaxMmolLPerSec: double.parse(newVlaMax.toStringAsFixed(2)),
      vo2MaxMlKgMin: double.parse(newVo2Max.toStringAsFixed(1)),
      powerAtVo2MaxWatts: newMap,
      grossEfficiencyPercent: double.parse(newEfficiency.toStringAsFixed(1)),
    );

    return _AdaptationEvaluation(
      calibratedProfile: updatedProfile,
      isOvertrained: isOvertrained,
    );
  }

  static PhysiologicalTrendAnalysis _analyzeTrend({
    required Rider rider,
    required LactateAndLabProfile previousProfile,
    required LactateAndLabProfile currentProfile,
    required DateTime? previousTestDate,
    required DateTime currentTestDate,
    required bool isOvertrained,
    required RiderTrainingFocus? recentFocus,
  }) {
    final int days = previousTestDate != null
        ? currentTestDate.difference(previousTestDate).inDays.abs()
        : 45;

    final double vo2Delta = currentProfile.vo2MaxMlKgMin - previousProfile.vo2MaxMlKgMin;
    final double vlaDelta = currentProfile.vlaMaxMmolLPerSec - previousProfile.vlaMaxMmolLPerSec;
    final int lt1Delta = currentProfile.lt1Watts - previousProfile.lt1Watts;
    final int lt2Delta = currentProfile.lt2Watts - previousProfile.lt2Watts;
    final double effDelta =
        currentProfile.grossEfficiencyPercent - previousProfile.grossEfficiencyPercent;
    final double weightDelta = currentProfile.referenceWeightKg - previousProfile.referenceWeightKg;

    final spec = rider.specialization;
    final isClimberOrTt = spec == RiderSpecialization.gcClimber ||
        spec == RiderSpecialization.pureClimber ||
        spec == RiderSpecialization.timeTrialist;
    final isSprinter = spec == RiderSpecialization.pureSprinter ||
        spec == RiderSpecialization.versatileSprinter;

    final bool isVlaMaxDecreasedForClimber = isClimberOrTt && vlaDelta < -0.01;
    final bool isVo2MaxIncreased = vo2Delta >= 0.5;
    final bool isLactateCurveShiftedRight = lt1Delta > 0 && lt2Delta >= 0;

    AdaptationVerdict verdict;
    String verdictSummary;
    int score = 75;

    if (isOvertrained) {
      verdict = AdaptationVerdict.overreachingDetected;
      verdictSummary =
          'Wykryto syndrom ostrego przemęczenia / przeciążenia (Overreaching). Spadek mocy progowej (-${lt2Delta.abs()}W) i stłumienie rezerwy tętna. Wymagany natychmiastowy odpoczynek.';
      score = 35;
    } else if (isClimberOrTt && isVlaMaxDecreasedForClimber && isVo2MaxIncreased) {
      verdict = AdaptationVerdict.optimalProgress;
      verdictSummary =
          'Idealna adaptacja dla kolarza górskiego / czasowca! Jednoczesne powiększenie pułapu tlenowego (+${vo2Delta.toStringAsFixed(1)} ml/kg/min) oraz stłumienie VLaMax (${vlaDelta.toStringAsFixed(2)} mmol/l/s). Próg LT2 wzrósł o +${lt2Delta}W.';
      score = 96;
    } else if (isClimberOrTt && isVlaMaxDecreasedForClimber) {
      verdict = AdaptationVerdict.glycolysisSuppressed;
      verdictSummary =
          'Sukces taktyczny: skuteczne obniżenie VLaMax o ${vlaDelta.abs().toStringAsFixed(2)} mmol/l/s. Tłumienie glikolizy przesuwa próg LT2 bliżej VO2max i drastycznie redukuje spalanie glikogenu na podjazdach.';
      score = 90;
    } else if (isSprinter && vlaDelta > 0.02) {
      verdict = AdaptationVerdict.sprinterExplosivenessEnhanced;
      verdictSummary =
          'Wzmocnienie potencjału finiszu sprinterskiego: VLaMax wzrósł o +${vlaDelta.toStringAsFixed(2)} mmol/l/s. Wyższa produkcja energii beztlenowej na ostatnich 200 metrach etapu.';
      score = 92;
    } else if (isVo2MaxIncreased) {
      verdict = AdaptationVerdict.aerobicCeilingExpanded;
      verdictSummary =
          'Zwiększenie pojemności silnika tlenowego: VO2max wzrosło o +${vo2Delta.toStringAsFixed(1)} ml/kg/min, podnosząc moc MAP do ${currentProfile.powerAtVo2MaxWatts}W.';
      score = 88;
    } else if (isLactateCurveShiftedRight) {
      verdict = AdaptationVerdict.thresholdShiftedRight;
      verdictSummary =
          'Korzystne przesunięcie krzywej kwasu mlekowego w prawo: wzrost mocy na LT1 (+${lt1Delta}W) i LT2 (+${lt2Delta}W). Kolarz produkuje mniej kwasu mlekowego przy prędkościach peletonu.';
      score = 85;
    } else if (effDelta > 0.3) {
      verdict = AdaptationVerdict.grossEfficiencyImproved;
      verdictSummary =
          'Poprawa ekonomii jazdy (Gross Efficiency wzrosła o +${effDelta.toStringAsFixed(1)}%). Kolarz zużywa mniej kilokalorii na wyprodukowanie każdego kilodżula pracy.';
      score = 82;
    } else {
      verdict = AdaptationVerdict.stagnation;
      verdictSummary =
          'Brak istotnych zmian parametrów metabolicznych. Organizm kolarza zaadaptował się do bieżących obciążeń – wskazane wprowadzenie nowych bodźców treningowych.';
      score = 65;
    }

    final bool isTrainingGoingInRightDirection =
        verdict.isPositive || (score >= 75 && !isOvertrained);

    return PhysiologicalTrendAnalysis(
      previousTestDate: previousTestDate,
      daysSincePreviousTest: days,
      vo2MaxDeltaMlKgMin: double.parse(vo2Delta.toStringAsFixed(1)),
      vlaMaxDeltaMmolLPerSec: double.parse(vlaDelta.toStringAsFixed(2)),
      lt1WattsDelta: lt1Delta,
      lt2WattsDelta: lt2Delta,
      grossEfficiencyDeltaPercent: double.parse(effDelta.toStringAsFixed(1)),
      weightDeltaKg: double.parse(weightDelta.toStringAsFixed(1)),
      isVlaMaxDecreasedForClimber: isVlaMaxDecreasedForClimber,
      isVo2MaxIncreased: isVo2MaxIncreased,
      isLactateCurveShiftedRight: isLactateCurveShiftedRight,
      isTrainingGoingInRightDirection: isTrainingGoingInRightDirection,
      verdict: verdict,
      verdictSummary: verdictSummary,
      adaptationScore: score,
    );
  }

  // =========================================================================
  // DIAGNOSTYKA I REKOMENDACJE TRENERA
  // =========================================================================

  static String _generateDiagnosticSummary(
    Rider rider,
    LactateAndLabProfile profile,
    PhysiologicalTrendAnalysis trend,
  ) {
    final spec = rider.specialization;
    final wPerKg = profile.lt2WattsPerKg.toStringAsFixed(2);
    final vla = profile.vlaMaxMmolLPerSec.toStringAsFixed(2);
    final vo2 = profile.vo2MaxMlKgMin.toStringAsFixed(1);

    if (trend.verdict == AdaptationVerdict.overreachingDetected ||
        trend.verdict == AdaptationVerdict.overtrainingDetected) {
      return 'UWAGA MEDYCZNA: U zawodnika stwierdzono objawy przemęczenia układu krążeniowo-oddechowego. Spadek tętna maksymalnego i obniżona zdolność do generowania mocy powyżej progu MLSS wskazują na potrzebę 5-7 dni aktywnej regeneracji.';
    }

    if (spec == RiderSpecialization.gcClimber || spec == RiderSpecialization.pureClimber) {
      return 'DIAGNOZA GÓRSKA: Kolarz dysponuje parametrami $wPerKg W/kg na progu beztlenowym LT2 oraz pułapem VO2max $vo2 ml/kg/min. VLaMax na poziomie $vla mmol/l/s gwarantuje optymalną oszczędność glikogenu w wysokich partiach górskich.';
    } else if (spec == RiderSpecialization.timeTrialist) {
      return 'DIAGNOZA CZASOWA: Płaska kinetyka mleczanu do poziomu ${profile.lt2Watts}W. Skrajnie niski VLaMax ($vla mmol/l/s) pozwala na jazdę na lemondce na 86% VO2max bez gwałtownego zakwaszenia mięśni.';
    } else if (spec == RiderSpecialization.pureSprinter) {
      return 'DIAGNOZA SPRINTERSKA: Wysokie VLaMax ($vla mmol/l/s) zapewnia eksplozywną glikolizę i gotowość do wygenerowania ponad 1600W na finiszu. Próg tlenowy LT1 na poziomie ${profile.lt1Watts}W zabezpiecza przetrwanie etapów płaskich.';
    }

    return 'DIAGNOZA OGÓLNA: Zbalansowany profil wydolnościowy ($wPerKg W/kg, VO2max: $vo2 ml/kg/min, VLaMax: $vla mmol/l/s). Zawodnik wykazuje stabilną adaptację do obciążeń startowych.';
  }

  static List<String> _generateCoachRecommendations(
    Rider rider,
    LactateAndLabProfile profile,
    PhysiologicalTrendAnalysis trend,
  ) {
    final List<String> recs = [];
    final spec = rider.specialization;

    if (trend.verdict == AdaptationVerdict.overreachingDetected) {
      recs.add('Wdrożyć 5-7 dni mikrocyklu regeneracyjnego Z1 (< 55% LT2) oraz zabiegi odnowy biologicznej.');
      recs.add('Zredukować tygodniowy TSS o co najmniej 40% do czasu normalizacji tętna spoczynkowego.');
      return recs;
    }

    if (spec == RiderSpecialization.gcClimber || spec == RiderSpecialization.pureClimber) {
      if (profile.vlaMaxMmolLPerSec > 0.40) {
        recs.add('Skupić się na dalszym obniżaniu VLaMax: długie jednostki w strefie FatMax (Z2: ${profile.lt1Watts}W) z ograniczeniem sprintów.');
      } else {
        recs.add('VLaMax na optymalnym poziomie ($profile.vlaMaxMmolLPerSec mmol/l/s). Utrzymać 2 jednostki SweetSpot tygodniowo.');
      }
      recs.add('Kalibracja żywienia: na podjazdach docelowych zaplanować dowóz 90-110 g węglowodanów na godzinę.');
    } else if (spec == RiderSpecialization.timeTrialist) {
      recs.add('Kontynuować trening pozycji aero na poziomie LT2 (${profile.lt2Watts}W) w seriach 3x15 minut.');
      recs.add('Utrzymać niskie VLaMax poprzez unikanie krótkich, beztlenowych zrywów w blokach bazowych.');
    } else if (spec == RiderSpecialization.pureSprinter) {
      recs.add('Utrzymać wysoki VLaMax: 2 razy w tygodniu seria maksymalnych zrywów z zatrzymania (6x10s all-out).');
      recs.add('Pilnować bazy tlenowej (Z2 do ${profile.lt1Watts}W), aby nie tracić kontaktu z peletonem na pagórkach.');
    } else {
      recs.add('Trening zrównoważony: 80% objętości w Z2 (${profile.lt1Watts}W), 20% w Z4/Z5 wokół LT2 (${profile.lt2Watts}W).');
    }

    return recs;
  }
}

class _AdaptationEvaluation {
  final LactateAndLabProfile calibratedProfile;
  final bool isOvertrained;

  const _AdaptationEvaluation({
    required this.calibratedProfile,
    required this.isOvertrained,
  });
}

class _RampProtocolResult {
  final List<LabTestStepSample> steps;
  final double lt1Ventilation;
  final double lt2Ventilation;
  final double peakVentilation;
  final int peakHeartRate;
  final String exhaustionReason;

  const _RampProtocolResult({
    required this.steps,
    required this.lt1Ventilation,
    required this.lt2Ventilation,
    required this.peakVentilation,
    required this.peakHeartRate,
    required this.exhaustionReason,
  });
}
