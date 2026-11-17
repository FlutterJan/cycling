// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../rendering3d/photo_finish_replay_widget.dart';

/// Faza manewru Rzutu Rowerem na Kreskę (Bike Throw) na ostatnich 10 m sprintu.
enum BikeThrowPhase {
  /// Kolarz znajduje się przed strefą 10 m lub jeszcze nie zainicjował rzutu.
  approaching('Dojazd do strefy 10 m'),

  /// Gwałtowne wypchnięcie kierownicy do przodu i cofnięcie bioder za siodło.
  lunging('Wypchnięcie roweru'),

  /// Maksymalne wysunięcie przedniego koła (+18–28 cm).
  peakExtension('Szczytowe wysunięcie'),

  /// Powrót z pozycji rzutu przy zbyt wczesnej aktywacji (strata prędkości).
  retracting('Wytracenie pędu'),

  /// Przecięcie linii mety zarejestrowane przez kamerę szczelinową.
  crossedFinish('Linia mety');

  final String label;

  const BikeThrowPhase(this.label);
}

/// Ocena wyczucia czasu (timing) wykonania rzutu rowerem przed linią mety.
enum BikeThrowTimingQuality {
  /// Brak rzutu przed linią mety (0 mm zysku).
  notTriggered(
    label: 'Brak rzutu',
    color: AppColors.textSecondary,
    efficiencyFactor: 0.0,
  ),

  /// Rzut wykonany znacznie za wcześnie (>6.5 m) — rower wraca przed kreską.
  tooEarly(
    label: 'Za wcześnie',
    color: AppColors.crimsonAlert,
    efficiencyFactor: 0.35,
  ),

  /// Rzut nieco za wcześnie (3.8–6.5 m) — niepełne utrzymanie wysunięcia.
  early(
    label: 'Nieco za wcześnie',
    color: AppColors.amberWarning,
    efficiencyFactor: 0.72,
  ),

  /// Idealne wyczucie momentu — szczyt wysunięcia dokładnie na białej linii.
  perfect(
    label: 'PERFEKCYJNY RZUT',
    color: AppColors.statusSuccess,
    efficiencyFactor: 1.0,
  ),

  /// Rzut nieco spóźniony — koło nie osiągnęło pełnego zasięgu na kresce.
  late(
    label: 'Spóźniony',
    color: AppColors.amberWarning,
    efficiencyFactor: 0.68,
  ),

  /// Rzut wykonany ułamek sekundy za późno lub po minięciu mety.
  tooLate(
    label: 'Za późno',
    color: AppColors.crimsonAlert,
    efficiencyFactor: 0.15,
  );

  final String label;
  final Color color;
  final double efficiencyFactor;

  const BikeThrowTimingQuality({
    required this.label,
    required this.color,
    required this.efficiencyFactor,
  });
}

/// Profil fizjologiczno-techniczny kolarza wpływający na zasięg i dynamikę Bike Throw.
class BikeThrowRiderProfile {
  final String riderId;
  final String riderName;
  final String teamName;
  final int bibNumber;
  final String countryIso;

  /// Umiejętność sprintu (1–100) — determinuje szybkość i precyzję wyrzutu.
  final int sprintSkill;

  /// Prowadzenie roweru (1–100) — wpływa na stabilność i maksymalny zasięg.
  final int bikeHandling;

  /// Wzrost kolarza [cm] (165–198 cm) — dłuższe ramiona zwiększają zasięg rzutu.
  final double riderHeightCm;

  /// Pozostała rezerwa beztlenowa W' (0.0–1.0) w momencie wjazdu na ostatnie 10 m.
  final double wPrimeRemainingFraction;

  /// Czas bazowy dojazdu do strefy 10 m przed metą [s] (do rozstrzygnięcia Photo-Finish).
  final double entryTimestampSeconds;

  final Color primaryJerseyColor;
  final Color secondaryJerseyColor;
  final Color bikeColor;
  final double trackLaneY;

  const BikeThrowRiderProfile({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.bibNumber,
    required this.countryIso,
    this.sprintSkill = 88,
    this.bikeHandling = 85,
    this.riderHeightCm = 181.0,
    this.wPrimeRemainingFraction = 0.45,
    this.entryTimestampSeconds = 14227.780,
    this.primaryJerseyColor = AppColors.goldAccent,
    this.secondaryJerseyColor = AppColors.surface,
    this.bikeColor = AppColors.background,
    this.trackLaneY = 0.45,
  });
}

/// Dane wejściowe dla symulacji rzutu rowerem w strefie ostatnich 10 m.
class BikeThrowAttemptInput {
  final BikeThrowRiderProfile profile;

  /// Prędkość wejścia na ostatnie 10 m [km/h].
  final double entrySpeedKmh;

  /// Dystans do linii mety, na którym gracz (lub AI) wcisnął rzut rowerem [m].
  /// Wartość `null` lub `<= 0` oznacza brak wykonania rzutu przed linią mety.
  final double? triggerDistanceToFinishMeters;

  /// Czy próba należy do gracza w trybie ręcznym / Be a Pro.
  final bool isManualPlayer;

  const BikeThrowAttemptInput({
    required this.profile,
    required this.entrySpeedKmh,
    this.triggerDistanceToFinishMeters,
    this.isManualPlayer = false,
  });
}

/// Pojedynczy krok kinematyczny w strefie ostatnich 10 m przed metą.
class BikeThrowSimulationStep {
  final double elapsedZoneSeconds;
  final double distanceToFinishMeters;
  final double frontWheelExtensionMm;
  final double effectiveSpeedKmh;
  final BikeThrowPhase phase;

  const BikeThrowSimulationStep({
    required this.elapsedZoneSeconds,
    required this.distanceToFinishMeters,
    required this.frontWheelExtensionMm,
    required this.effectiveSpeedKmh,
    required this.phase,
  });
}

/// Wynik fizyczny pojedynczego kolarza na linii fotokomórki (z dokładnością do 0.001 s).
class BikeThrowOutcome {
  final BikeThrowRiderProfile profile;
  final bool isManualPlayer;

  /// Maksymalny potencjalny zasięg rzutu tego kolarza [mm] (180–280 mm).
  final double maxPotentialGainMm;

  /// Faktyczne wysunięcie przedniego koła w ułamku sekundy przecięcia linii mety [mm].
  final double actualGainAtLineMm;

  /// Czas przecięcia mety bez rzutu rowerem [s].
  final double rawFinishTimeWithoutThrowSeconds;

  /// Oficjalny czas przecięcia mety z uwzględnieniem rzutu rowerem [s].
  final double finalFinishTimeSeconds;

  /// Zysk czasowy wywalczony rzutem rowerem [s] (np. 0.013 s).
  final double timeSavedSeconds;

  /// Prędkość na linii mety [km/h].
  final double speedAtLineKmh;

  /// Dystans od mety, na którym nastąpiła aktywacja rzutu [m].
  final double? triggerDistanceMeters;

  /// Optymalny dystans aktywacji dla aktualnej prędkości i dynamiki kolarza [m].
  final double optimalTriggerDistanceMeters;

  /// Błąd wyczucia czasu względem szczytu wysunięcia [ms] (0 ms = ideał).
  final double timingErrorMs;

  final BikeThrowTimingQuality timingQuality;

  const BikeThrowOutcome({
    required this.profile,
    required this.isManualPlayer,
    required this.maxPotentialGainMm,
    required this.actualGainAtLineMm,
    required this.rawFinishTimeWithoutThrowSeconds,
    required this.finalFinishTimeSeconds,
    required this.timeSavedSeconds,
    required this.speedAtLineKmh,
    required this.triggerDistanceMeters,
    required this.optimalTriggerDistanceMeters,
    required this.timingErrorMs,
    required this.timingQuality,
  });

  bool get isPerfectTiming => timingQuality == BikeThrowTimingQuality.perfect;
}

/// Zbiorczy werdykt wszystkich sprinterów na linii mety gotowy dla `PhotoFinishReplayWidget`.
class PhotoFinishResolutionResult {
  /// Wyniki posortowane od zwycięzcy (najniższy czas `finalFinishTimeSeconds`).
  final List<BikeThrowOutcome> rankedOutcomes;

  /// Różnica między 1. a 2. kolarzem w sekundach (zaokrąglona/dokładna do 0.001 s).
  final double winnerGapSeconds;

  /// Czy do rozstrzygnięcia wymagana była kamera szczelinowa (<0.150 s).
  final bool requiredPhotoFinish;

  /// Gotowy model danych dla `PhotoFinishReplayWidget`.
  final PhotoFinishData photoFinishData;

  const PhotoFinishResolutionResult({
    required this.rankedOutcomes,
    required this.winnerGapSeconds,
    required this.requiredPhotoFinish,
    required this.photoFinishData,
  });

  BikeThrowOutcome get winner => rankedOutcomes.first;
}

/// Fizyka **Rzutu Rowerem na Kreskę (Bike Throw)** na ostatnich 10 m sprintu.
///
/// Modeluje gwałtowne wypchnięcie kierownicy do przodu z jednoczesnym cofnięciem
/// bioder za siodło, co przesuwa przednie koło o dodatkowe **18–28 cm** (`180–280 mm`)
/// w ułamku sekundy. Zbyt wczesny rzut powoduje powrót roweru i wytracenie pędu
/// przez przerwanie pedałowania, a zbyt późny nie osiąga pełnego zasięgu na kresce.
class FinishLineBikeThrowPhysics {
  FinishLineBikeThrowPhysics._();

  /// Długość strefy końcowej sprintu, w której dostępny jest Bike Throw [m].
  static const double activationZoneMeters = 10.0;

  /// Minimalny fizyczny zasięg rzutu rowerem [cm].
  static const double minThrowGainCm = 18.0;

  /// Maksymalny fizyczny zasięg rzutu rowerem [cm].
  static const double maxThrowGainCm = 28.0;

  /// Minimalny zasięg w milimetrach [mm].
  static const double minThrowGainMm = minThrowGainCm * 10.0;

  /// Maksymalny zasięg w milimetrach [mm].
  static const double maxThrowGainMm = maxThrowGainCm * 10.0;

  /// Minimalny czas narastania rzutu do pełnego wysunięcia [s].
  static const double minLungeDurationSeconds = 0.135;

  /// Maksymalny czas narastania rzutu do pełnego wysunięcia [s].
  static const double maxLungeDurationSeconds = 0.185;

  /// Czas utrzymania szczytowego wysunięcia przed powrotem [s].
  static const double peakHoldDurationSeconds = 0.045;

  /// Czas cofania się roweru i wytracania przewagi przy zbyt wczesnym rzucie [s].
  static const double retractionDurationSeconds = 0.240;

  /// Krok czasowy symulacji wysokiej rozdzielczości (1000 Hz = 0.001 s).
  static const double highResDtSeconds = 0.001;

  /// Oblicza maksymalny potencjalny zasięg rzutu rowerem dla danego kolarza [mm]
  /// w zakresie **180–280 mm** (18–28 cm) na podstawie:
  /// - umiejętności sprintu i panowania nad rowerem,
  /// - wzrostu kolarza (długość ramion i tułowia),
  /// - pozostałej energii beztlenowej W'.
  static double computeMaxThrowGainMm(BikeThrowRiderProfile profile) {
    final skillNorm = ((profile.sprintSkill.clamp(1, 100) * 0.60 +
                profile.bikeHandling.clamp(1, 100) * 0.40) /
            100.0)
        .clamp(0.0, 1.0);
    final heightNorm =
        ((profile.riderHeightCm.clamp(165.0, 198.0) - 165.0) / 33.0)
            .clamp(0.0, 1.0);
    final wPrimeNorm = profile.wPrimeRemainingFraction.clamp(0.0, 1.0);

    final composite =
        (skillNorm * 0.55) + (heightNorm * 0.30) + (wPrimeNorm * 0.15);
    return minThrowGainMm +
        (maxThrowGainMm - minThrowGainMm) * composite.clamp(0.0, 1.0);
  }

  /// Oblicza czas potrzebny na osiągnięcie pełnego wysunięcia roweru [s].
  static double computeLungeDurationSeconds(BikeThrowRiderProfile profile) {
    final skillNorm = ((profile.sprintSkill.clamp(1, 100) * 0.65 +
                profile.bikeHandling.clamp(1, 100) * 0.35) /
            100.0)
        .clamp(0.0, 1.0);
    // Wyższy skill = szybszy, bardziej eksplozywny wyrzut kierownicy.
    return maxLungeDurationSeconds -
        (maxLungeDurationSeconds - minLungeDurationSeconds) * skillNorm;
  }

  /// Wyznacza optymalny dystans przed metą [m] na wykonanie rzutu rowerem,
  /// aby przednie koło osiągnęło szczyt wysunięcia dokładnie na linii mety.
  static double computeOptimalTriggerDistanceMeters({
    required BikeThrowRiderProfile profile,
    required double speedKmh,
  }) {
    final speedMs = (speedKmh.clamp(25.0, 95.0)) / 3.6;
    final lungeSeconds = computeLungeDurationSeconds(profile);
    final maxGainMeters = computeMaxThrowGainMm(profile) / 1000.0;
    // W momencie szczytu środek masy jest oddalony o (speedMs * lungeSeconds),
    // a przednie koło zyskuje dodatkowo maxGainMeters.
    final optimal = (speedMs * lungeSeconds) + maxGainMeters * 0.85;
    return optimal.clamp(1.2, 4.8);
  }

  /// Oblicza krzywą wysunięcia przedniego koła [mm] w zależności od czasu od aktywacji.
  static double evaluateExtensionAtElapsedSeconds({
    required double elapsedSinceTriggerSeconds,
    required double maxGainMm,
    required double lungeDurationSeconds,
  }) {
    if (elapsedSinceTriggerSeconds <= 0.0) {
      return 0.0;
    }
    if (elapsedSinceTriggerSeconds <= lungeDurationSeconds) {
      final t = (elapsedSinceTriggerSeconds / lungeDurationSeconds).clamp(0.0, 1.0);
      // Gwałtowne wypchnięcie (ease-out cubic) w ułamku sekundy.
      final eased = 1.0 - math.pow(1.0 - t, 3).toDouble();
      return maxGainMm * eased;
    }
    final holdEnd = lungeDurationSeconds + peakHoldDurationSeconds;
    if (elapsedSinceTriggerSeconds <= holdEnd) {
      return maxGainMm;
    }
    final retractElapsed = elapsedSinceTriggerSeconds - holdEnd;
    final retractT =
        (retractElapsed / retractionDurationSeconds).clamp(0.0, 1.0);
    // Przy zbyt wczesnym rzucie kolarz musi wrócić nad suport, tracąc wysunięcie.
    final remainingFraction =
        1.0 - (0.72 * (1.0 - math.pow(1.0 - retractT, 2).toDouble()));
    return (maxGainMm * remainingFraction).clamp(0.0, maxGainMm);
  }

  /// Ocenia jakość timingu na podstawie różnicy względem idealnego momentu [ms].
  static BikeThrowTimingQuality classifyTiming({
    required double? triggerDistanceMeters,
    required double optimalTriggerDistanceMeters,
    required double speedMs,
  }) {
    if (triggerDistanceMeters == null || triggerDistanceMeters <= 0.0) {
      return BikeThrowTimingQuality.notTriggered;
    }
    final deltaMeters = triggerDistanceMeters - optimalTriggerDistanceMeters;
    final deltaSeconds = deltaMeters / math.max(1.0, speedMs);
    final deltaMs = deltaSeconds * 1000.0;

    if (deltaMs.abs() <= 28.0) {
      return BikeThrowTimingQuality.perfect;
    }
    if (deltaMs > 28.0) {
      // Pozytywna delta = większy dystans do mety = rzut wykonany wcześniej.
      return deltaMs > 165.0
          ? BikeThrowTimingQuality.tooEarly
          : BikeThrowTimingQuality.early;
    }
    // Negatywna delta = mniejszy dystans do mety = rzut spóźniony.
    return deltaMs < -75.0
        ? BikeThrowTimingQuality.tooLate
        : BikeThrowTimingQuality.late;
  }

  /// Symuluje pełny przejazd przez strefę ostatnich 10 m z krokiem `0.001 s`
  /// i wylicza dokładny czas przecięcia linii mety przez przednie koło.
  static BikeThrowOutcome simulateFinal10Meters(BikeThrowAttemptInput input) {
    final profile = input.profile;
    final baseSpeedKmh = input.entrySpeedKmh.clamp(25.0, 95.0);
    final baseSpeedMs = baseSpeedKmh / 3.6;

    final maxGainMm = computeMaxThrowGainMm(profile);
    final lungeDuration = computeLungeDurationSeconds(profile);
    final optimalTriggerDist = computeOptimalTriggerDistanceMeters(
      profile: profile,
      speedKmh: baseSpeedKmh,
    );

    final rawTrigger = input.triggerDistanceToFinishMeters;
    final double? effectiveTrigger = (rawTrigger != null &&
            rawTrigger > 0.0 &&
            rawTrigger <= activationZoneMeters)
        ? rawTrigger
        : null;

    // Czas przejazdu 10 m bez rzutu rowerem.
    final timeWithoutThrow = activationZoneMeters / baseSpeedMs;
    final rawFinishWithoutThrow =
        profile.entryTimestampSeconds + timeWithoutThrow;

    double comDistanceCovered = 0.0;
    double elapsedZone = 0.0;
    double? triggerElapsedTimestamp;
    double currentSpeedMs = baseSpeedMs;
    double wheelExtensionMmAtFinish = 0.0;

    // Pętla wysokiej rozdzielczości (1 ms) aż przednie koło przetnie linię 10.0 m.
    const maxSimulationSeconds = 3.0;
    while (elapsedZone < maxSimulationSeconds) {
      final remainingComMeters = activationZoneMeters - comDistanceCovered;

      if (effectiveTrigger != null &&
          triggerElapsedTimestamp == null &&
          remainingComMeters <= effectiveTrigger) {
        triggerElapsedTimestamp = elapsedZone;
      }

      double extensionMm = 0.0;
      if (triggerElapsedTimestamp != null) {
        final sinceTrigger = elapsedZone - triggerElapsedTimestamp;
        extensionMm = evaluateExtensionAtElapsedSeconds(
          elapsedSinceTriggerSeconds: sinceTrigger,
          maxGainMm: maxGainMm,
          lungeDurationSeconds: lungeDuration,
        );

        // Po fazie wypchnięcia (gdy przerwane zostaje pedałowanie) prędkość spada o ~3.5%.
        if (sinceTrigger > lungeDuration + peakHoldDurationSeconds) {
          currentSpeedMs = math.max(
            baseSpeedMs * 0.94,
            currentSpeedMs - (0.85 * highResDtSeconds),
          );
        }
      }

      final frontWheelCoveredMeters =
          comDistanceCovered + (extensionMm / 1000.0);

      if (frontWheelCoveredMeters >= activationZoneMeters) {
        wheelExtensionMmAtFinish = extensionMm;
        break;
      }

      comDistanceCovered += currentSpeedMs * highResDtSeconds;
      elapsedZone += highResDtSeconds;
    }

    final finalFinishTime = profile.entryTimestampSeconds + elapsedZone;
    final timeSaved =
        math.max(0.0, rawFinishWithoutThrow - finalFinishTime);

    final timingQuality = classifyTiming(
      triggerDistanceMeters: effectiveTrigger,
      optimalTriggerDistanceMeters: optimalTriggerDist,
      speedMs: baseSpeedMs,
    );

    final timingErrorMs = effectiveTrigger == null
        ? 0.0
        : ((effectiveTrigger - optimalTriggerDist) / baseSpeedMs) * 1000.0;

    return BikeThrowOutcome(
      profile: profile,
      isManualPlayer: input.isManualPlayer,
      maxPotentialGainMm: maxGainMm,
      actualGainAtLineMm: wheelExtensionMmAtFinish,
      rawFinishTimeWithoutThrowSeconds: rawFinishWithoutThrow,
      finalFinishTimeSeconds: finalFinishTime,
      timeSavedSeconds: timeSaved,
      speedAtLineKmh: currentSpeedMs * 3.6,
      triggerDistanceMeters: effectiveTrigger,
      optimalTriggerDistanceMeters: optimalTriggerDist,
      timingErrorMs: timingErrorMs,
      timingQuality: timingQuality,
    );
  }

  /// Generuje ślad kroków symulacji do wizualizacji na wykresie / kamerze.
  static List<BikeThrowSimulationStep> buildTrajectoryTrace(
    BikeThrowAttemptInput input, {
    double stepDtSeconds = 0.01,
  }) {
    final profile = input.profile;
    final baseSpeedKmh = input.entrySpeedKmh.clamp(25.0, 95.0);
    final baseSpeedMs = baseSpeedKmh / 3.6;
    final maxGainMm = computeMaxThrowGainMm(profile);
    final lungeDuration = computeLungeDurationSeconds(profile);
    final rawTrigger = input.triggerDistanceToFinishMeters;
    final double? effectiveTrigger = (rawTrigger != null &&
            rawTrigger > 0.0 &&
            rawTrigger <= activationZoneMeters)
        ? rawTrigger
        : null;

    final steps = <BikeThrowSimulationStep>[];
    double comCovered = 0.0;
    double elapsed = 0.0;
    double? triggerAt;
    double currentSpeedMs = baseSpeedMs;

    while (elapsed < 2.5) {
      final remaining = math.max(0.0, activationZoneMeters - comCovered);
      if (effectiveTrigger != null &&
          triggerAt == null &&
          remaining <= effectiveTrigger) {
        triggerAt = elapsed;
      }

      double extensionMm = 0.0;
      var phase = BikeThrowPhase.approaching;

      if (triggerAt != null) {
        final sinceTrigger = elapsed - triggerAt;
        extensionMm = evaluateExtensionAtElapsedSeconds(
          elapsedSinceTriggerSeconds: sinceTrigger,
          maxGainMm: maxGainMm,
          lungeDurationSeconds: lungeDuration,
        );
        if (sinceTrigger <= lungeDuration) {
          phase = BikeThrowPhase.lunging;
        } else if (sinceTrigger <= lungeDuration + peakHoldDurationSeconds) {
          phase = BikeThrowPhase.peakExtension;
        } else {
          phase = BikeThrowPhase.retracting;
          currentSpeedMs = math.max(
            baseSpeedMs * 0.94,
            currentSpeedMs - (0.85 * stepDtSeconds),
          );
        }
      }

      final frontWheelDistToFinish = math.max(
        0.0,
        activationZoneMeters - (comCovered + extensionMm / 1000.0),
      );

      if (frontWheelDistToFinish <= 0.0) {
        steps.add(
          BikeThrowSimulationStep(
            elapsedZoneSeconds: elapsed,
            distanceToFinishMeters: 0.0,
            frontWheelExtensionMm: extensionMm,
            effectiveSpeedKmh: currentSpeedMs * 3.6,
            phase: BikeThrowPhase.crossedFinish,
          ),
        );
        break;
      }

      steps.add(
        BikeThrowSimulationStep(
          elapsedZoneSeconds: elapsed,
          distanceToFinishMeters: frontWheelDistToFinish,
          frontWheelExtensionMm: extensionMm,
          effectiveSpeedKmh: currentSpeedMs * 3.6,
          phase: phase,
        ),
      );

      comCovered += currentSpeedMs * stepDtSeconds;
      elapsed += stepDtSeconds;
    }

    return steps;
  }

  /// Wyznacza automatyczny moment rzutu AI na podstawie umiejętności sprintera.
  static double computeAiTriggerDistanceMeters({
    required BikeThrowRiderProfile profile,
    required double speedKmh,
    int deterministicSeed = 0,
  }) {
    final optimal = computeOptimalTriggerDistanceMeters(
      profile: profile,
      speedKmh: speedKmh,
    );
    final skillNorm = (profile.sprintSkill.clamp(1, 100) / 100.0);
    // Słabsi sprinterzy mają większy rozrzut błędu timingu.
    final maxJitterMeters = (1.0 - skillNorm) * 1.15 + 0.08;
    final rng = math.Random(
      profile.riderId.hashCode ^ profile.bibNumber ^ deterministicSeed,
    );
    final offset = (rng.nextDouble() * 2.0 - 1.0) * maxJitterMeters;
    return (optimal + offset).clamp(0.4, activationZoneMeters - 0.5);
  }

  /// Rozstrzyga finisz wielu kolarzy co do `0.001 s` i buduje obiekt [PhotoFinishData]
  /// gotowy do bezpośredniego wyświetlenia w [PhotoFinishReplayWidget].
  static PhotoFinishResolutionResult resolveToPhotoFinishData({
    required List<BikeThrowAttemptInput> attempts,
    String stageName = 'Finał Sprintu — Ostatnie 10 m',
    int stageNumber = 1,
    String finishLocation = 'Linia Mety',
    int deterministicSeed = 42,
  }) {
    if (attempts.isEmpty) {
      final demoData = PhotoFinishData.demoSprintFinish(
        stageName: stageName,
        stageNumber: stageNumber,
        finishLocation: finishLocation,
      );
      return PhotoFinishResolutionResult(
        rankedOutcomes: const [],
        winnerGapSeconds: demoData.gapSecondsToSecondPlace,
        requiredPhotoFinish: true,
        photoFinishData: demoData,
      );
    }

    final outcomes = attempts.map((attempt) {
      if (!attempt.isManualPlayer &&
          attempt.triggerDistanceToFinishMeters == null) {
        final aiTrigger = computeAiTriggerDistanceMeters(
          profile: attempt.profile,
          speedKmh: attempt.entrySpeedKmh,
          deterministicSeed: deterministicSeed,
        );
        return simulateFinal10Meters(
          BikeThrowAttemptInput(
            profile: attempt.profile,
            entrySpeedKmh: attempt.entrySpeedKmh,
            triggerDistanceToFinishMeters: aiTrigger,
            isManualPlayer: false,
          ),
        );
      }
      return simulateFinal10Meters(attempt);
    }).toList()
      ..sort(
        (a, b) =>
            a.finalFinishTimeSeconds.compareTo(b.finalFinishTimeSeconds),
      );

    final winner = outcomes.first;
    final secondGap = outcomes.length > 1
        ? _roundToMillisecond(
            outcomes[1].finalFinishTimeSeconds - winner.finalFinishTimeSeconds,
          )
        : 0.0;
    final needsPhotoFinish = PhotoFinishData.isPhotoFinishRequired(secondGap);

    final photoRiders = <PhotoFinishRider>[];
    for (int i = 0; i < outcomes.length; i++) {
      final o = outcomes[i];
      final gapSec = i == 0
          ? 0.0
          : _roundToMillisecond(
              o.finalFinishTimeSeconds - winner.finalFinishTimeSeconds,
            );
      photoRiders.add(
        PhotoFinishRider(
          rank: i + 1,
          riderId: o.profile.riderId,
          riderName: o.profile.riderName,
          teamName: o.profile.teamName,
          bibNumber: o.profile.bibNumber,
          countryIso: o.profile.countryIso,
          finishTimeSeconds: _roundToMillisecond(o.finalFinishTimeSeconds),
          gapToWinnerSeconds: gapSec,
          speedKmh: o.speedAtLineKmh,
          primaryJerseyColor: o.profile.primaryJerseyColor,
          secondaryJerseyColor: o.profile.secondaryJerseyColor,
          bikeColor: o.profile.bikeColor,
          bikeThrowGainMm: o.actualGainAtLineMm,
          trackLaneY: o.profile.trackLaneY,
        ),
      );
    }

    final ruling = _buildCommissairesRuling(outcomes, secondGap);

    final photoData = PhotoFinishData(
      stageName: stageName,
      stageNumber: stageNumber,
      finishLocation: finishLocation,
      finishSpeedKmh: winner.speedAtLineKmh,
      cameraSamplingRateHz: 10000,
      status: PhotoFinishStatus.officialConfirmed,
      riders: photoRiders,
      commissairesRuling: ruling,
    );

    return PhotoFinishResolutionResult(
      rankedOutcomes: outcomes,
      winnerGapSeconds: secondGap,
      requiredPhotoFinish: needsPhotoFinish,
      photoFinishData: photoData,
    );
  }

  static double _roundToMillisecond(double seconds) {
    return (seconds * 1000.0).roundToDouble() / 1000.0;
  }

  static String _buildCommissairesRuling(
    List<BikeThrowOutcome> outcomes,
    double secondGapSeconds,
  ) {
    final winner = outcomes.first;
    final gainCm = (winner.actualGainAtLineMm / 10.0).toStringAsFixed(1);
    if (outcomes.length < 2) {
      return 'Rzut rowerem ${winner.profile.riderName}: +$gainCm cm na linii mety.';
    }
    final gapMm = (winner.speedAtLineKmh / 3.6) * secondGapSeconds * 1000.0;
    if (secondGapSeconds <= 0.0005) {
      return 'Dead-heat / tysięczne sekundy: ${winner.profile.riderName} (+$gainCm cm) wygrywa na fotokomórce.';
    }
    return 'Kamera szczelinowa (10 000 FPS): ${winner.profile.riderName} (+$gainCm cm rzutu) wygrywa o ${gapMm.toStringAsFixed(1)} mm (+${secondGapSeconds.toStringAsFixed(3)}s).';
  }
}

// =============================================================================
// PANEL INTERAKTYWNY TRYBU RĘCZNEGO / BE A PRO + WIZUALIZACJA PHOTO-FINISH
// =============================================================================

/// Interaktywny panel HUD trybu ręcznego / Be a Pro do wykonania **Rzutu Rowerem
/// na Kreskę** na ostatnich 10 m sprintu z natychmiastowym werdyktem
/// [PhotoFinishReplayWidget] z dokładnością do `0.001 s`.
class FinishLineBikeThrowPanel extends StatefulWidget {
  final BikeThrowRiderProfile playerProfile;
  final List<BikeThrowRiderProfile> rivalProfiles;
  final double approachSpeedKmh;
  final ValueChanged<PhotoFinishResolutionResult>? onResolved;

  const FinishLineBikeThrowPanel({
    super.key,
    required this.playerProfile,
    this.rivalProfiles = const [],
    this.approachSpeedKmh = 68.4,
    this.onResolved,
  });

  @override
  State<FinishLineBikeThrowPanel> createState() =>
      _FinishLineBikeThrowPanelState();
}

class _FinishLineBikeThrowPanelState extends State<FinishLineBikeThrowPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _approachController;
  final FocusNode _throwButtonFocusNode = FocusNode();

  bool _isRunning = false;
  bool _isHoveredThrow = false;
  bool _isHoveredReset = false;
  double? _playerTriggerDistanceMeters;
  PhotoFinishResolutionResult? _resolutionResult;

  @override
  void initState() {
    super.initState();
    _approachController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(_onTick)
      ..addStatusListener(_onAnimationStatus);
  }

  @override
  void dispose() {
    _approachController.dispose();
    _throwButtonFocusNode.dispose();
    super.dispose();
  }

  double get _currentDistanceToFinishMeters {
    return FinishLineBikeThrowPhysics.activationZoneMeters *
        (1.0 - _approachController.value);
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isRunning) {
      _finalizeSprint();
    }
  }

  void _startSprint() {
    setState(() {
      _isRunning = true;
      _playerTriggerDistanceMeters = null;
      _resolutionResult = null;
    });
    _approachController.forward(from: 0.0);
    _throwButtonFocusNode.requestFocus();
  }

  void _triggerPlayerBikeThrow() {
    if (!_isRunning || _playerTriggerDistanceMeters != null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _playerTriggerDistanceMeters =
          _currentDistanceToFinishMeters.clamp(0.05, 10.0);
    });
  }

  void _finalizeSprint() {
    final attempts = <BikeThrowAttemptInput>[
      BikeThrowAttemptInput(
        profile: widget.playerProfile,
        entrySpeedKmh: widget.approachSpeedKmh,
        triggerDistanceToFinishMeters: _playerTriggerDistanceMeters,
        isManualPlayer: true,
      ),
      ...widget.rivalProfiles.map(
        (rival) => BikeThrowAttemptInput(
          profile: rival,
          entrySpeedKmh: widget.approachSpeedKmh - 0.15,
          isManualPlayer: false,
        ),
      ),
    ];

    final result = FinishLineBikeThrowPhysics.resolveToPhotoFinishData(
      attempts: attempts,
    );

    setState(() {
      _isRunning = false;
      _resolutionResult = result;
    });
    widget.onResolved?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final optimalDist =
        FinishLineBikeThrowPhysics.computeOptimalTriggerDistanceMeters(
      profile: widget.playerProfile,
      speedKmh: widget.approachSpeedKmh,
    );
    final maxGainMm =
        FinishLineBikeThrowPhysics.computeMaxThrowGainMm(widget.playerProfile);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact, maxGainMm),
                const SizedBox(height: 14),
                _buildDistanceGauge(optimalDist),
                const SizedBox(height: 14),
                _buildActionControls(isCompact),
                if (_resolutionResult != null) ...[
                  const SizedBox(height: 16),
                  _buildOutcomeSummary(_resolutionResult!, isCompact),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact, double maxGainMm) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryAccent, width: 1),
          ),
          child: const Icon(
            Icons.sports_motorsports_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RZUT ROWEREM NA KRESKĘ (BIKE THROW)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ostatnie 10 m • Zasięg maks. +${(maxGainMm / 10).toStringAsFixed(1)} cm • ${widget.approachSpeedKmh.toStringAsFixed(1)} km/h',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isCompact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              '${_currentDistanceToFinishMeters.toStringAsFixed(2)} m',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.cyanAccent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDistanceGauge(double optimalDistanceMeters) {
    final progress = _approachController.value.clamp(0.0, 1.0);
    final optimalNorm = 1.0 -
        (optimalDistanceMeters /
            FinishLineBikeThrowPhysics.activationZoneMeters);
    final triggerNorm = _playerTriggerDistanceMeters == null
        ? null
        : 1.0 -
            (_playerTriggerDistanceMeters! /
                FinishLineBikeThrowPhysics.activationZoneMeters);

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: CustomPaint(
        painter: _BikeThrowGaugePainter(
          progress: progress,
          optimalNormalized: optimalNorm.clamp(0.05, 0.95),
          triggerNormalized: triggerNorm?.clamp(0.0, 1.0),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildActionControls(bool isCompact) {
    final canTrigger = _isRunning && _playerTriggerDistanceMeters == null;
    final buttonText = !_isRunning
        ? 'START FINISZU (10 m)'
        : (_playerTriggerDistanceMeters == null
            ? 'WYKONAJ BIKE THROW!'
            : 'RZUT ZAREJESTROWANY (${_playerTriggerDistanceMeters!.toStringAsFixed(2)} m)');

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveredThrow = true),
          onExit: (_) => setState(() => _isHoveredThrow = false),
          child: Focus(
            focusNode: _throwButtonFocusNode,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.space) {
                if (!_isRunning) {
                  _startSprint();
                } else {
                  _triggerPlayerBikeThrow();
                }
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: ElevatedButton.icon(
                onPressed: !_isRunning
                    ? _startSprint
                    : (canTrigger ? _triggerPlayerBikeThrow : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canTrigger
                      ? (_isHoveredThrow
                          ? AppColors.goldAccent
                          : AppColors.primaryAccent)
                      : (_isHoveredThrow && !_isRunning
                          ? AppColors.surfaceLight
                          : AppColors.surfaceLight),
                  foregroundColor: AppColors.textPrimary,
                  disabledBackgroundColor:
                      AppColors.surfaceLight.withValues(alpha: 0.45),
                  disabledForegroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 14 : 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: canTrigger
                          ? AppColors.goldAccent
                          : AppColors.cardBorder,
                    ),
                  ),
                ),
                icon: Icon(
                  !_isRunning
                      ? Icons.play_arrow_rounded
                      : Icons.flash_on_rounded,
                  size: 18,
                ),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveredReset = true),
          onExit: (_) => setState(() => _isHoveredReset = false),
          child: OutlinedButton.icon(
            onPressed: _isRunning
                ? null
                : () {
                    setState(() {
                      _approachController.reset();
                      _playerTriggerDistanceMeters = null;
                      _resolutionResult = null;
                    });
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: _isHoveredReset
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              side: BorderSide(
                color: _isHoveredReset
                    ? AppColors.accentBlue
                    : AppColors.cardBorder,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'Reset',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutcomeSummary(
    PhotoFinishResolutionResult result,
    bool isCompact,
  ) {
    final playerOutcome = result.rankedOutcomes.firstWhere(
      (o) => o.isManualPlayer,
      orElse: () => result.rankedOutcomes.first,
    );
    final playerRank = result.rankedOutcomes.indexOf(playerOutcome) + 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: playerOutcome.timingQuality.color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: playerOutcome.timingQuality.color
                      .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  playerOutcome.timingQuality.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: playerOutcome.timingQuality.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pozycja: #$playerRank • Zysk koła: +${(playerOutcome.actualGainAtLineMm / 10).toStringAsFixed(1)} cm (${(playerOutcome.timeSavedSeconds * 1000).toStringAsFixed(1)} ms)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.photoFinishData.commissairesRuling,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BikeThrowGaugePainter extends CustomPainter {
  final double progress;
  final double optimalNormalized;
  final double? triggerNormalized;

  const _BikeThrowGaugePainter({
    required this.progress,
    required this.optimalNormalized,
    required this.triggerNormalized,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height * 0.52;
    final trackPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(8, trackY),
      Offset(size.width - 8, trackY),
      trackPaint,
    );

    final usableWidth = size.width - 16;
    final optCenterX = 8 + usableWidth * optimalNormalized;
    final optHalfWidth = usableWidth * 0.055;

    final optimalPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: 0.45)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset((optCenterX - optHalfWidth).clamp(8, size.width - 8), trackY),
      Offset((optCenterX + optHalfWidth).clamp(8, size.width - 8), trackY),
      optimalPaint,
    );

    // Linia mety na prawym końcu paska.
    final finishPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(size.width - 8, 6),
      Offset(size.width - 8, size.height - 6),
      finishPaint,
    );

    if (triggerNormalized != null) {
      final trigX = 8 + usableWidth * triggerNormalized!;
      final trigPaint = Paint()..color = AppColors.goldAccent;
      canvas.drawCircle(Offset(trigX, trackY), 6, trigPaint);
    }

    final riderX = 8 + usableWidth * progress;
    final riderPaint = Paint()..color = AppColors.cyanAccent;
    canvas.drawCircle(Offset(riderX, trackY), 7, riderPaint);
  }

  @override
  bool shouldRepaint(covariant _BikeThrowGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.optimalNormalized != optimalNormalized ||
        oldDelegate.triggerNormalized != triggerNormalized;
  }
}
