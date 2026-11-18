// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/retro/golden_era_retro_season_model.dart';

/// Strefa subiektywnego odczucia wysiłku według skali Borga (RPE 6–20).
enum BorgRpeZone {
  /// RPE 6: Brak wysiłku / swobodne toczenie.
  rest(6, 6, 'Rest / Coasting', 'Odpoczynek / Toczenie', AppColors.powerZone1),

  /// RPE 7–8: Bardzo lekki wysiłek regeneracyjny.
  extremelyLight(7, 8, 'Extremely Light', 'Bardzo lekki', AppColors.powerZone1),

  /// RPE 9–10: Lekki wysiłek tlenowy (Z2).
  veryLight(9, 10, 'Very Light', 'Lekki (Baza Z2)', AppColors.powerZone2),

  /// RPE 11–12: Umiarkowany wysiłek (Tempo Z3).
  light(11, 12, 'Light / Tempo', 'Umiarkowany (Tempo)', AppColors.powerZone3),

  /// RPE 13–14: Dość ciężki (Sweet Spot / podprogowy).
  somewhatHard(
    13,
    14,
    'Somewhat Hard',
    'Dość ciężki (Sweet Spot)',
    AppColors.powerZone4,
  ),

  /// RPE 15–16: Ciężki (Próg LT2 / FTP).
  hard(15, 16, 'Hard (Threshold)', 'Ciężki (Próg LT2)', AppColors.powerZone5),

  /// RPE 17–18: Bardzo ciężki (VO2max).
  veryHard(17, 18, 'Very Hard (VO2max)', 'Bardzo ciężki (VO2max)', AppColors.powerZone6),

  /// RPE 19: Skrajnie ciężki (beztlenowy).
  extremelyHard(
    19,
    19,
    'Extremely Hard',
    'Skrajnie ciężki',
    AppColors.crimsonAlert,
  ),

  /// RPE 20: Maksymalny wysiłek (sprint absolutny).
  maximal(20, 20, 'Maximal Effort', 'Wysiłek maksymalny', AppColors.powerZone7);

  final int minScore;
  final int maxScore;
  final String labelEn;
  final String labelPl;
  final Color zoneColor;

  const BorgRpeZone(
    this.minScore,
    this.maxScore,
    this.labelEn,
    this.labelPl,
    this.zoneColor,
  );

  /// Dobiera strefę Borga na podstawie wartości liczbowej `6.0–20.0`.
  static BorgRpeZone fromBorgScore(double score) {
    final rounded = score.round().clamp(6, 20);
    for (final zone in BorgRpeZone.values) {
      if (rounded >= zone.minScore && rounded <= zone.maxScore) {
        return zone;
      }
    }
    return BorgRpeZone.rest;
  }
}

/// Wynik mechaniczny pojedynczej próby zmiany biegu na manetce.
enum RetroShiftOutcome {
  /// Brak aktywnej zmiany biegu w tym kroku.
  idle('Brak zmiany', 'No Shift'),

  /// Czyste, precyzyjne wrzucenie przełożenia.
  cleanShift('Czysta zmiana', 'Clean Shift'),

  /// Lekkie ocieranie łańcucha o wózek przerzutki (wymaga dostrojenia manetką cierną).
  chainRubTrimming('Ocieranie łańcucha (korekta)', 'Chain Rub (Trim Needed)'),

  /// Pudło / nieprecyzyjne zazębienie pod obciążeniem (dodatkowe opóźnienie).
  missedGear('Pudło zmiany biegu', 'Missed Shift'),

  /// Spadnięcie łańcucha na bruku lub przy dużym przekosie.
  droppedChain('Spadnięty łańcuch', 'Dropped Chain');

  final String labelPl;
  final String labelEn;

  const RetroShiftOutcome(this.labelPl, this.labelEn);

  /// Czy zdarzenie oznacza usterkę lub opóźnienie ponad normę.
  bool get isFault =>
      this == RetroShiftOutcome.chainRubTrimming ||
      this == RetroShiftOutcome.missedGear ||
      this == RetroShiftOutcome.droppedChain;
}

/// Stan trwającej lub zakończonej zmiany biegu na dolnej rurze ramy.
@immutable
class DowntubeShiftState {
  /// Aktualna przednia tarcza [liczba zębów].
  final int currentFrontTeeth;

  /// Aktualna tylna koronka [liczba zębów].
  final int currentRearTeeth;

  /// Docelowa przednia tarcza w trakcie zmiany (lub `null`).
  final int? pendingFrontTeeth;

  /// Docelowa tylna koronka w trakcie zmiany (lub `null`).
  final int? pendingRearTeeth;

  /// Pozostały czas do zakończenia zmiany biegu [s].
  final double remainingShiftSeconds;

  /// Całkowity czas trwania bieżącej zmiany biegu [s].
  final double totalShiftDurationSeconds;

  /// Czy kolarz ma aktualnie zdjętą rękę z kierownicy (sięga do dolnej rury).
  final bool isHandOffBar;

  /// Ostatni zarejestrowany wynik zmiany biegu.
  final RetroShiftOutcome lastOutcome;

  /// Liczba wszystkich wykonanych zmian biegów.
  final int totalShiftsCompleted;

  /// Liczba błędów zmiany biegów (ocieranie, pudło, spadnięcie).
  final int totalMisshifts;

  const DowntubeShiftState({
    required this.currentFrontTeeth,
    required this.currentRearTeeth,
    this.pendingFrontTeeth,
    this.pendingRearTeeth,
    this.remainingShiftSeconds = 0.0,
    this.totalShiftDurationSeconds = 0.0,
    this.isHandOffBar = false,
    this.lastOutcome = RetroShiftOutcome.idle,
    this.totalShiftsCompleted = 0,
    this.totalMisshifts = 0,
  });

  /// Domyślny stan startowy klasycznego napędu z lat 70./80. (52x19).
  factory DowntubeShiftState.initial({
    int frontTeeth = 52,
    int rearTeeth = 19,
  }) {
    return DowntubeShiftState(
      currentFrontTeeth: frontTeeth,
      currentRearTeeth: rearTeeth,
    );
  }

  /// Czy trwa obecnie zmiana przełożenia.
  bool get isShifting => remainingShiftSeconds > 0.0001;

  /// Postęp aktualnej zmiany biegu w zakresie `0.0–1.0`.
  double get shiftProgress {
    if (!isShifting || totalShiftDurationSeconds <= 0.0) {
      return 1.0;
    }
    return (1.0 - (remainingShiftSeconds / totalShiftDurationSeconds))
        .clamp(0.0, 1.0);
  }

  /// Aktualne przełożenie jako etykieta tekstowa, np. `52x19`.
  String get gearLabel => '${currentFrontTeeth}x$currentRearTeeth';

  /// Tworzy kopię stanu ze zmodyfikowanymi polami.
  DowntubeShiftState copyWith({
    int? currentFrontTeeth,
    int? currentRearTeeth,
    int? pendingFrontTeeth,
    bool clearPendingFront = false,
    int? pendingRearTeeth,
    bool clearPendingRear = false,
    double? remainingShiftSeconds,
    double? totalShiftDurationSeconds,
    bool? isHandOffBar,
    RetroShiftOutcome? lastOutcome,
    int? totalShiftsCompleted,
    int? totalMisshifts,
  }) {
    return DowntubeShiftState(
      currentFrontTeeth: currentFrontTeeth ?? this.currentFrontTeeth,
      currentRearTeeth: currentRearTeeth ?? this.currentRearTeeth,
      pendingFrontTeeth: clearPendingFront
          ? null
          : (pendingFrontTeeth ?? this.pendingFrontTeeth),
      pendingRearTeeth: clearPendingRear
          ? null
          : (pendingRearTeeth ?? this.pendingRearTeeth),
      remainingShiftSeconds:
          remainingShiftSeconds ?? this.remainingShiftSeconds,
      totalShiftDurationSeconds:
          totalShiftDurationSeconds ?? this.totalShiftDurationSeconds,
      isHandOffBar: isHandOffBar ?? this.isHandOffBar,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      totalShiftsCompleted: totalShiftsCompleted ?? this.totalShiftsCompleted,
      totalMisshifts: totalMisshifts ?? this.totalMisshifts,
    );
  }
}

/// Dane wejściowe pojedynczego kroku symulacji dla [RetroSteelFrameAndNoPowermeterSolver].
@immutable
class RetroPhysicsAndRpeInput {
  /// Materiał ramy historycznej (np. stal Columbus SL).
  final RetroFrameMaterial frameMaterial;

  /// Typ manetek (np. manetki cierne na dolnej rurze).
  final RetroShifterType shifterType;

  /// Materiał stroju (np. gruba wełna merynosowa).
  final RetroJerseyMaterial jerseyMaterial;

  /// Tryb telemetrii (np. `noPowerMeterRpeOnly` — brak watów i pulsu).
  final RetroTelemetryMode telemetryMode;

  /// Funkcjonalny próg mocy kolarza FTP [W].
  final double riderFtpWatts;

  /// Aktualnie zadana docelowa moc [W] (ignorowana, jeśli podano [targetBorgRpe]).
  final double requestedPowerWatts;

  /// Opcjonalny rozkaz jazdy według skali Borga (6–20) zamiast watów.
  final double? targetBorgRpe;

  /// Pozostała rezerwa beztlenowa W' jako ułamek `0.0–1.0`.
  final double wPrimeRemainingFraction;

  /// Skumulowane zmęczenie mięśniowe `0.0–1.0`.
  final double cumulativeFatigue;

  /// Poziom glikogenu `0.0–1.0`.
  final double glycogenFraction;

  /// Temperatura głęboka ciała [°C].
  final double coreTemperatureC;

  /// Intensywność opadów deszczu `0.0–1.0`.
  final double rainIntensity;

  /// Szorstkość nawierzchni / bruk `0.0–1.0` (`0.0` = gładki asfalt, `1.0` = bruk 5★).
  final double surfaceRoughness;

  /// Nachylenie drogi [%].
  final double gradePercent;

  /// Umiejętność wyczucia tempa i obsługi manetek `0.0–1.0`.
  final double riderCraftSkill;

  /// Czy trwa gwałtowny skok tempa lub atak (adrenalina zaniża odczuwane RPE).
  final bool isAdrenalineSurge;

  /// Czy kolarz jedzie na stojąco ("w korbach").
  final bool isOutOfSaddle;

  /// Prędkość liniowa kolarza [m/s].
  final double speedMs;

  /// Czas kroku symulacji [s].
  final double deltaTimeSeconds;

  /// Deterministyczne ziarno losowe do oceny błędu RPE i ryzyka pudła zmiany biegu.
  final int deterministicSeed;

  /// Opcjonalna żądana zmiana przedniej tarczy [liczba zębów].
  final int? requestedFrontTeeth;

  /// Opcjonalna żądana zmiana tylnej koronki [liczba zębów].
  final int? requestedRearTeeth;

  const RetroPhysicsAndRpeInput({
    this.frameMaterial = RetroFrameMaterial.columbusSlSteel,
    this.shifterType = RetroShifterType.downtubeFriction,
    this.jerseyMaterial = RetroJerseyMaterial.heavyMerinoWool,
    this.telemetryMode = RetroTelemetryMode.noPowerMeterRpeOnly,
    this.riderFtpWatts = 380.0,
    this.requestedPowerWatts = 320.0,
    this.targetBorgRpe,
    this.wPrimeRemainingFraction = 0.85,
    this.cumulativeFatigue = 0.20,
    this.glycogenFraction = 0.85,
    this.coreTemperatureC = 37.6,
    this.rainIntensity = 0.0,
    this.surfaceRoughness = 0.0,
    this.gradePercent = 0.0,
    this.riderCraftSkill = 0.72,
    this.isAdrenalineSurge = false,
    this.isOutOfSaddle = false,
    this.speedMs = 10.5,
    this.deltaTimeSeconds = 1.0,
    this.deterministicSeed = 42,
    this.requestedFrontTeeth,
    this.requestedRearTeeth,
  });
}

/// Wynik obliczeń percepcji RPE (Borg 6–20) oraz fizyki ramy stalowej i manetek.
@immutable
class RetroPhysicsAndRpeResult {
  /// Subiektywna ocena wysiłku w skali Borga (`6.0–20.0`).
  final double borgRpeScore;

  /// Zaokrąglony wynik Borga (`6–20`).
  final int borgRpeRounded;

  /// Strefa wysiłku Borga.
  final BorgRpeZone borgZone;

  /// Rzeczywista moc generowana na pedałach po uwzględnieniu błędu RPE i strat [W].
  final double actualPowerWatts;

  /// Moc szacowana przez kolarza (lub `null`, gdy brak miernika mocy).
  final double? visiblePowerWatts;

  /// Szacowane tętno [BPM] (widoczne tylko przy `showsLiveHeartRate`).
  final int? visibleHeartRateBpm;

  /// Względny błąd szacowania wysiłku [%], np. `+9.5` oznacza przeszacowanie mocy.
  final double rpeEstimationErrorPercent;

  /// Ryzyko odcięcia energetycznego ("ściany") w zakresie `0.0–1.0`.
  final double bonkRiskScore;

  /// Całkowita masa roweru + mokrej wełnianej koszulki [kg].
  final double effectiveBikeAndKitWeightKg;

  /// Dodatkowa kara aerodynamiczna CdA z tytułu mokrej wełny i zdjęcia ręki z kierownicy [m^2].
  final double cdaPenaltyM2;

  /// Strata mocy wynikająca z ugięcia ramy stalowej w sprincie / na stojąco [W].
  final double frameFlexPowerLossWatts;

  /// Tłumienie wibracji nawierzchni przez ramę (`0.0–1.0`).
  final double vibrationDampingFactor;

  /// Aktualny mnożnik transferu mocy podczas zmiany biegu (`0.0–1.0`).
  final double shiftPowerTransferFactor;

  /// Sprawność napędu (uwzględniająca ewentualne ocieranie łańcucha przy manetce ciernej).
  final double drivetrainEfficiency;

  /// Zaktualizowany stan manetek na dolnej rurze ramy.
  final DowntubeShiftState shiftState;

  /// Efektywna moc przekazywana na tylne koło [W].
  final double effectiveWheelPowerWatts;

  const RetroPhysicsAndRpeResult({
    required this.borgRpeScore,
    required this.borgRpeRounded,
    required this.borgZone,
    required this.actualPowerWatts,
    required this.visiblePowerWatts,
    required this.visibleHeartRateBpm,
    required this.rpeEstimationErrorPercent,
    required this.bonkRiskScore,
    required this.effectiveBikeAndKitWeightKg,
    required this.cdaPenaltyM2,
    required this.frameFlexPowerLossWatts,
    required this.vibrationDampingFactor,
    required this.shiftPowerTransferFactor,
    required this.drivetrainEfficiency,
    required this.shiftState,
    required this.effectiveWheelPowerWatts,
  });
}

/// Solver percepcji wysiłku RPE (Borg 6–20) bez miernika mocy oraz fizyki
/// historycznych ram stalowych i opóźnień zmiany biegów na dolnej rurze ramy.
class RetroSteelFrameAndNoPowermeterSolver {
  const RetroSteelFrameAndNoPowermeterSolver();

  /// Wykonuje pojedynczy krok symulacji percepcji RPE i fizyki retro roweru.
  RetroPhysicsAndRpeResult stepSimulation({
    required RetroPhysicsAndRpeInput input,
    required DowntubeShiftState shiftState,
  }) {
    final safeFtp = math.max(120.0, input.riderFtpWatts);
    final safeDt = math.max(0.01, input.deltaTimeSeconds);
    final skill = input.riderCraftSkill.clamp(0.0, 1.0);
    final fatigue = input.cumulativeFatigue.clamp(0.0, 1.0);
    final wPrimeFrac = input.wPrimeRemainingFraction.clamp(0.0, 1.0);
    final glycogen = input.glycogenFraction.clamp(0.0, 1.0);
    final rain = input.rainIntensity.clamp(0.0, 1.0);
    final roughness = input.surfaceRoughness.clamp(0.0, 1.0);

    // 1. Rozwiązanie stanu manetek na dolnej rurze ramy.
    final nextShiftState = _advanceDowntubeShiftState(
      input: input,
      currentState: shiftState,
      dt: safeDt,
      skill: skill,
      rain: rain,
      roughness: roughness,
    );

    // 2. Kalkulacja błędu percepcji RPE i mocy docelowej vs rzeczywistej.
    final rpeEval = _solveRpeAndPower(
      input: input,
      safeFtp: safeFtp,
      fatigue: fatigue,
      wPrimeFrac: wPrimeFrac,
      glycogen: glycogen,
      rain: rain,
      skill: skill,
    );

    // 3. Fizyka ramy stalowej (masa + nasiąknięta wełna + ugięcie suportu + tłumienie drgań).
    final waterKg =
        (input.jerseyMaterial.maxWaterAbsorptionGrams * rain) / 1000.0;
    final dryKitKg = input.jerseyMaterial.dryWeightGrams / 1000.0;
    final effectiveBikeAndKitWeightKg =
        input.frameMaterial.defaultCompleteBikeWeightKg + dryKitKg + waterKg;

    final wetJerseyCda = input.jerseyMaterial.maxWetCdaPenalty * rain;
    final handOffBarCda = nextShiftState.isHandOffBar ? 0.025 : 0.0;
    final cdaPenaltyM2 = wetJerseyCda + handOffBarCda;

    // Ugięcie suportu stalowej ramy przy wysokim momencie obrotowym / sprincie.
    final intensityRatio = rpeEval.actualPowerWatts / safeFtp;
    final isHighTorque = input.isOutOfSaddle || intensityRatio > 1.20;
    final stiffnessFactor = input.frameMaterial.sprintStiffnessFactor;
    final flexLossRatio = isHighTorque ? (1.0 - stiffnessFactor) * 0.45 : 0.0;
    final frameFlexPowerLossWatts = rpeEval.actualPowerWatts * flexLossRatio;

    // 4. Przeniesienie mocy podczas zmiany biegów na dolnej rurze ramy.
    double shiftPowerTransferFactor = 1.0;
    if (nextShiftState.isShifting) {
      // Sięgnięcie do dolnej rury wymusza chwilowe odpuszczenie korby,
      // tym większe im bardziej stromy podjazd lub wyboisty bruk.
      final baseDrop = input.shifterType.requiresHandOffBar ? 0.78 : 0.92;
      final gradientPenalty = (input.gradePercent.clamp(0.0, 22.0) / 22.0) * 0.14;
      final cobblePenalty = roughness * 0.08;
      shiftPowerTransferFactor =
          (baseDrop - gradientPenalty - cobblePenalty).clamp(0.55, 0.96);
    }

    // Ocieranie łańcucha przy manetce ciernej obniża sprawność napędu o 4.5%.
    final drivetrainEfficiency =
        nextShiftState.lastOutcome == RetroShiftOutcome.chainRubTrimming
            ? 0.935
            : 0.980;

    final effectiveWheelPowerWatts = math.max(
      0.0,
      (rpeEval.actualPowerWatts - frameFlexPowerLossWatts) *
          shiftPowerTransferFactor *
          drivetrainEfficiency,
    );

    return RetroPhysicsAndRpeResult(
      borgRpeScore: rpeEval.borgRpeScore,
      borgRpeRounded: rpeEval.borgRpeScore.round().clamp(6, 20),
      borgZone: BorgRpeZone.fromBorgScore(rpeEval.borgRpeScore),
      actualPowerWatts: rpeEval.actualPowerWatts,
      visiblePowerWatts: input.telemetryMode.showsLiveWatts
          ? double.parse(rpeEval.actualPowerWatts.toStringAsFixed(1))
          : null,
      visibleHeartRateBpm: input.telemetryMode.showsLiveHeartRate
          ? rpeEval.heartRateBpm
          : null,
      rpeEstimationErrorPercent: rpeEval.estimationErrorPercent,
      bonkRiskScore: rpeEval.bonkRiskScore,
      effectiveBikeAndKitWeightKg: effectiveBikeAndKitWeightKg,
      cdaPenaltyM2: cdaPenaltyM2,
      frameFlexPowerLossWatts: frameFlexPowerLossWatts,
      vibrationDampingFactor: input.frameMaterial.vibrationDamping,
      shiftPowerTransferFactor: shiftPowerTransferFactor,
      drivetrainEfficiency: drivetrainEfficiency,
      shiftState: nextShiftState,
      effectiveWheelPowerWatts: effectiveWheelPowerWatts,
    );
  }

  /// Oblicza fizjologiczną skalę Borga (6–20) z uwzględnieniem zmęczenia,
  /// adrenaliny, wychłodzenia i błędu percepcji przy braku miernika mocy.
  _RpeEvaluation _solveRpeAndPower({
    required RetroPhysicsAndRpeInput input,
    required double safeFtp,
    required double fatigue,
    required double wPrimeFrac,
    required double glycogen,
    required double rain,
    required double skill,
  }) {
    // Dodatkowe obciążenie percepcyjne ze zmęczenia, glikogenu i temperatury.
    final fatigueDrift = fatigue * 2.4 + (1.0 - wPrimeFrac) * 1.6;
    final glycogenDrift = glycogen < 0.35 ? (0.35 - glycogen) * 5.0 : 0.0;
    final thermalStress = input.coreTemperatureC > 38.4
        ? (input.coreTemperatureC - 38.4) * 1.1
        : 0.0;
    final wetChillPenalty =
        rain * input.jerseyMaterial.wetThermalChillFactor * 0.9;
    final adrenalineMasking = input.isAdrenalineSurge ? -0.9 : 0.0;

    final perceptualShift =
        fatigueDrift + glycogenDrift + thermalStress + wetChillPenalty + adrenalineMasking;

    // Deterministyczny szum percepcji skalowany przez tryb telemetrii i doświadczenie.
    final maxErr = input.telemetryMode.rpeEstimationErrorFactor *
        (1.15 - 0.50 * skill);
    final signedNoise = _deterministicSignedUnit(input.deterministicSeed);
    final errorFactor = signedNoise * maxErr;

    double actualPowerWatts;
    double borgScore;

    if (input.targetBorgRpe != null) {
      // Kolarz jedzie "na czucie" według zadanego RPE (np. Borg 15).
      final targetBorg = input.targetBorgRpe!.clamp(6.0, 20.0);
      final adjustedBorg = (targetBorg - perceptualShift).clamp(6.0, 20.0);
      final targetRatio = _borgToIntensityRatio(adjustedBorg);
      actualPowerWatts = math.max(0.0, safeFtp * targetRatio * (1.0 + errorFactor));
      borgScore = targetBorg;
    } else {
      // Kolarz generuje żądaną moc, a system wylicza odczuwalne RPE.
      final baseRatio = math.max(0.0, input.requestedPowerWatts) / safeFtp;
      final baseBorg = _intensityRatioToBorg(baseRatio);
      borgScore = (baseBorg + perceptualShift).clamp(6.0, 20.0);
      actualPowerWatts = math.max(
        0.0,
        input.requestedPowerWatts *
            (input.telemetryMode.showsLiveWatts ? 1.0 : (1.0 + errorFactor * 0.35)),
      );
    }

    final actualRatio = actualPowerWatts / safeFtp;
    final rawHeartRate = 62.0 +
        (actualRatio.clamp(0.0, 1.35) * 112.0) +
        (fatigue * 9.0) +
        (input.coreTemperatureC > 38.5 ? (input.coreTemperatureC - 38.5) * 8.0 : 0.0);
    final heartRateBpm = rawHeartRate.round().clamp(52, 204);

    // Ryzyko "ściany" (bonk): połączenie niskiego glikogenu, jazdy ponad próg
    // i mnożnika braku telemetrii mocy.
    final overThreshold = math.max(0.0, actualRatio - 0.92);
    final rawBonk = ((1.0 - glycogen) * 0.65 + overThreshold * 0.55 + fatigue * 0.25) *
        input.telemetryMode.bonkRiskMultiplier *
        0.75;
    final bonkRiskScore = rawBonk.clamp(0.0, 1.0);

    return _RpeEvaluation(
      borgRpeScore: borgScore,
      actualPowerWatts: actualPowerWatts,
      heartRateBpm: heartRateBpm,
      estimationErrorPercent: errorFactor * 100.0,
      bonkRiskScore: bonkRiskScore,
    );
  }

  DowntubeShiftState _advanceDowntubeShiftState({
    required RetroPhysicsAndRpeInput input,
    required DowntubeShiftState currentState,
    required double dt,
    required double skill,
    required double rain,
    required double roughness,
  }) {
    var state = currentState;

    // Jeśli trwa zmiana biegu, odliczamy czas opóźnienia.
    if (state.isShifting) {
      final remaining = state.remainingShiftSeconds - dt;
      if (remaining > 0.0001) {
        return state.copyWith(
          remainingShiftSeconds: remaining,
          isHandOffBar: input.shifterType.requiresHandOffBar,
        );
      }

      // Zmiana biegu została zakończona w tym kroku.
      return state.copyWith(
        currentFrontTeeth: state.pendingFrontTeeth ?? state.currentFrontTeeth,
        currentRearTeeth: state.pendingRearTeeth ?? state.currentRearTeeth,
        clearPendingFront: true,
        clearPendingRear: true,
        remainingShiftSeconds: 0.0,
        totalShiftDurationSeconds: 0.0,
        isHandOffBar: false,
        totalShiftsCompleted: state.totalShiftsCompleted + 1,
      );
    }

    // Sprawdzenie, czy w tym kroku zlecono nową zmianę przełożenia.
    final targetFront = input.requestedFrontTeeth ?? state.currentFrontTeeth;
    final targetRear = input.requestedRearTeeth ?? state.currentRearTeeth;
    final hasChangeRequest = targetFront != state.currentFrontTeeth ||
        targetRear != state.currentRearTeeth;

    if (!hasChangeRequest) {
      return state.copyWith(
        isHandOffBar: false,
        lastOutcome: state.lastOutcome == RetroShiftOutcome.chainRubTrimming
            ? RetroShiftOutcome.chainRubTrimming
            : RetroShiftOutcome.idle,
      );
    }

    // Obliczenie rzeczywistego opóźnienia zmiany biegu na dolnej rurze.
    final baseDelay = input.shifterType.shiftDelaySeconds;
    final frontShiftBonus =
        targetFront != state.currentFrontTeeth ? 0.35 : 0.0;
    final surfaceAndWeatherMultiplier =
        1.0 + (roughness * 0.35) + (rain * 0.20) - (skill * 0.22);
    var totalDelay =
        (baseDelay + frontShiftBonus) * surfaceAndWeatherMultiplier.clamp(0.72, 1.75);

    // Ocena prawdopodobieństwa pudła lub ocierania łańcucha.
    final baseMisshift = input.shifterType.misshiftProbability;
    final effectiveMisshiftProb = (baseMisshift *
            (1.0 + roughness * 0.8 + rain * 0.35 - skill * 0.45))
        .clamp(0.0, 0.55);

    final roll = _deterministicUnit(input.deterministicSeed + state.totalShiftsCompleted);
    RetroShiftOutcome outcome = RetroShiftOutcome.cleanShift;
    var extraMisshifts = 0;

    if (roll < effectiveMisshiftProb * 0.12 &&
        input.shifterType == RetroShifterType.downtubeFriction &&
        roughness > 0.45) {
      outcome = RetroShiftOutcome.droppedChain;
      totalDelay += 3.2;
      extraMisshifts = 1;
    } else if (roll < effectiveMisshiftProb * 0.45) {
      outcome = RetroShiftOutcome.missedGear;
      totalDelay += 0.95;
      extraMisshifts = 1;
    } else if (roll < effectiveMisshiftProb) {
      outcome = RetroShiftOutcome.chainRubTrimming;
      totalDelay += 0.45;
      extraMisshifts = 1;
    }

    // Jeśli krok dt jest dłuższy niż opóźnienie, zmiana kończy się od razu.
    if (dt >= totalDelay) {
      return state.copyWith(
        currentFrontTeeth: targetFront,
        currentRearTeeth: targetRear,
        clearPendingFront: true,
        clearPendingRear: true,
        remainingShiftSeconds: 0.0,
        totalShiftDurationSeconds: 0.0,
        isHandOffBar: false,
        lastOutcome: outcome,
        totalShiftsCompleted: state.totalShiftsCompleted + 1,
        totalMisshifts: state.totalMisshifts + extraMisshifts,
      );
    }

    return state.copyWith(
      pendingFrontTeeth: targetFront,
      pendingRearTeeth: targetRear,
      remainingShiftSeconds: totalDelay - dt,
      totalShiftDurationSeconds: totalDelay,
      isHandOffBar: input.shifterType.requiresHandOffBar,
      lastOutcome: outcome,
      totalMisshifts: state.totalMisshifts + extraMisshifts,
    );
  }

  /// Mapuje stosunek mocy `P / FTP` na podstawową wartość w skali Borga `6–20`.
  double _intensityRatioToBorg(double ratio) {
    if (ratio <= 0.05) return 6.0;
    if (ratio < 0.55) return 6.0 + (ratio / 0.55) * 3.0; // 6–9
    if (ratio < 0.85) return 9.0 + ((ratio - 0.55) / 0.30) * 3.5; // 9–12.5
    if (ratio < 1.05) return 12.5 + ((ratio - 0.85) / 0.20) * 3.5; // 12.5–16.0
    if (ratio < 1.30) return 16.0 + ((ratio - 1.05) / 0.25) * 2.5; // 16.0–18.5
    return (18.5 + ((ratio - 1.30) / 0.50) * 1.5).clamp(18.5, 20.0);
  }

  /// Odwrotna funkcja mapująca docelowe RPE (Borg 6–20) na stosunek `P / FTP`.
  double _borgToIntensityRatio(double borg) {
    if (borg <= 6.0) return 0.0;
    if (borg < 9.0) return ((borg - 6.0) / 3.0) * 0.55;
    if (borg < 12.5) return 0.55 + ((borg - 9.0) / 3.5) * 0.30;
    if (borg < 16.0) return 0.85 + ((borg - 12.5) / 3.5) * 0.20;
    if (borg < 18.5) return 1.05 + ((borg - 16.0) / 2.5) * 0.25;
    return 1.30 + ((borg - 18.5) / 1.5) * 0.50;
  }

  /// Zwraca deterministyczną wartość z zakresu `0.0..1.0`.
  double _deterministicUnit(int seed) {
    final hash = ((seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
    return hash.clamp(0.0, 1.0);
  }

  /// Zwraca deterministyczną wartość z zakresu `-1.0..1.0`.
  double _deterministicSignedUnit(int seed) {
    return (_deterministicUnit(seed) * 2.0) - 1.0;
  }
}

class _RpeEvaluation {
  final double borgRpeScore;
  final double actualPowerWatts;
  final int heartRateBpm;
  final double estimationErrorPercent;
  final double bonkRiskScore;

  const _RpeEvaluation({
    required this.borgRpeScore,
    required this.actualPowerWatts,
    required this.heartRateBpm,
    required this.estimationErrorPercent,
    required this.bonkRiskScore,
  });
}

/// Responsywny panel HUD dla trybu „Złota Era”: wskaźnik percepcji RPE (Borg 6–20)
/// oraz interaktywna obsługa manetek na dolnej rurze ramy stalowej.
class RetroSteelAndRpeHudPanel extends StatefulWidget {
  /// Bieżący wynik symulacji do wyświetlenia.
  final RetroPhysicsAndRpeResult result;

  /// Aktywny typ manetek.
  final RetroShifterType shifterType;

  /// Aktywny materiał ramy.
  final RetroFrameMaterial frameMaterial;

  /// Wywołane po zmianie docelowego RPE (Borg 6–20).
  final ValueChanged<double>? onTargetRpeChanged;

  /// Wywołane po kliknięciu redukcji (lżejszy bieg).
  final VoidCallback? onShiftEasier;

  /// Wywołane po kliknięciu utwardzenia (twardszy bieg).
  final VoidCallback? onShiftHarder;

  const RetroSteelAndRpeHudPanel({
    super.key,
    required this.result,
    this.shifterType = RetroShifterType.downtubeFriction,
    this.frameMaterial = RetroFrameMaterial.columbusSlSteel,
    this.onTargetRpeChanged,
    this.onShiftEasier,
    this.onShiftHarder,
  });

  @override
  State<RetroSteelAndRpeHudPanel> createState() =>
      _RetroSteelAndRpeHudPanelState();
}

class _RetroSteelAndRpeHudPanelState extends State<RetroSteelAndRpeHudPanel> {
  double _selectedTargetRpe = 14.0;

  @override
  void initState() {
    super.initState();
    _selectedTargetRpe = widget.result.borgRpeScore.clamp(6.0, 20.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final isWide = constraints.maxWidth >= 900;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14.0 : 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 14),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildBorgRpeCard(isCompact)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildDowntubeShifterCard(isCompact)),
                  ],
                )
              else ...[
                _buildBorgRpeCard(isCompact),
                const SizedBox(height: 12),
                _buildDowntubeShifterCard(isCompact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final zoneColor = widget.result.borgZone.zoneColor;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: zoneColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'TELEMETRIA RETRO · RPE & STAL',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
          ),
          child: Text(
            widget.frameMaterial.displayNamePl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBorgRpeCard(bool isCompact) {
    final res = widget.result;
    final zoneColor = res.borgZone.zoneColor;
    final wattsText = res.visiblePowerWatts != null
        ? '${res.visiblePowerWatts!.toStringAsFixed(0)} W'
        : 'BRAK MIERNIKA (RPE)';
    final hrText = res.visibleHeartRateBpm != null
        ? '${res.visibleHeartRateBpm} BPM'
        : 'BRAK PULSOMETRU';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
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
                'Skala Borga (6–20)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: zoneColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: zoneColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  'RPE ${res.borgRpeRounded} · ${res.borgZone.labelPl}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: zoneColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ((res.borgRpeScore - 6.0) / 14.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(zoneColor),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _MetricChip(label: 'MOC', value: wattsText),
              _MetricChip(label: 'TĘTNO', value: hrText),
              _MetricChip(
                label: 'RYZYKO ŚCIANY',
                value: '${(res.bonkRiskScore * 100).round()}%',
                valueColor: res.bonkRiskScore > 0.65
                    ? AppColors.crimsonAlert
                    : AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Cel RPE:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primaryAccent,
                    inactiveTrackColor: AppColors.background,
                    thumbColor: AppColors.goldAccent,
                    overlayColor: AppColors.goldAccent.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _selectedTargetRpe,
                    min: 6.0,
                    max: 20.0,
                    divisions: 14,
                    label: _selectedTargetRpe.round().toString(),
                    onChanged: widget.onTargetRpeChanged == null
                        ? null
                        : (val) {
                            setState(() => _selectedTargetRpe = val);
                            widget.onTargetRpeChanged?.call(val);
                          },
                  ),
                ),
              ),
              Text(
                _selectedTargetRpe.round().toString(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDowntubeShifterCard(bool isCompact) {
    final shift = widget.result.shiftState;
    final isShifting = shift.isShifting;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.shifterType.displayNamePl,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                shift.gearLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isShifting
                  ? AppColors.amberWarning.withValues(alpha: 0.14)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isShifting
                    ? AppColors.amberWarning
                    : AppColors.cardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isShifting
                      ? 'Ręka na dolnej rurze (${shift.remainingShiftSeconds.toStringAsFixed(2)} s)'
                      : 'Status: ${shift.lastOutcome.labelPl}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isShifting
                        ? AppColors.amberWarning
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (isShifting) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: shift.shiftProgress,
                      minHeight: 5,
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.amberWarning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _MetricChip(
                label: 'MASA ZESTAWU',
                value:
                    '${widget.result.effectiveBikeAndKitWeightKg.toStringAsFixed(2)} kg',
              ),
              _MetricChip(
                label: 'UGIĘCIE RAMY',
                value:
                    '-${widget.result.frameFlexPowerLossWatts.toStringAsFixed(1)} W',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InteractiveRetroButton(
                  label: 'Lżejszy bieg',
                  enabled: !isShifting && widget.onShiftEasier != null,
                  onPressed: widget.onShiftEasier,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InteractiveRetroButton(
                  label: 'Twardszy bieg',
                  enabled: !isShifting && widget.onShiftHarder != null,
                  onPressed: widget.onShiftHarder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricChip({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveRetroButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  const _InteractiveRetroButton({
    required this.label,
    required this.enabled,
    this.onPressed,
  });

  @override
  State<_InteractiveRetroButton> createState() =>
      _InteractiveRetroButtonState();
}

class _InteractiveRetroButtonState extends State<_InteractiveRetroButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;
    final bgColor = !active
        ? AppColors.background.withValues(alpha: 0.5)
        : _isPressed
            ? AppColors.primaryAccent
            : _isHovered
                ? AppColors.primaryAccent.withValues(alpha: 0.85)
                : AppColors.primaryAccent.withValues(alpha: 0.65);

    final borderColor = !active
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _isFocused
            ? AppColors.goldAccent
            : _isHovered
                ? AppColors.goldAccent.withValues(alpha: 0.7)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: active ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: active ? () => setState(() => _isPressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
