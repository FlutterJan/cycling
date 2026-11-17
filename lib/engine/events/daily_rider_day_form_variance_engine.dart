// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'race_radio_generator.dart';

/// Dystans pierwszych kilometrów etapu [km], na przestrzeni których
/// stopniowo odkrywana jest dyspozycja dnia ("The Legs").
const double kDayFormDiscoveryMaxKm = 30.0;

/// Minimalny dystans [km], od którego kolarz zaczyna wyczuwać pierwsze sygnały z nóg.
const double kDayFormSensingStartKm = 8.0;

/// Minimalny wynik w skali diamentów dyspozycji dnia.
const int kMinDayFormDiamonds = -3;

/// Maksymalny wynik w skali diamentów dyspozycji dnia.
const int kMaxDayFormDiamonds = 3;

/// Faza odkrywania dyspozycji dnia w trakcie pierwszych 30 km etapu.
enum DayFormDiscoveryPhase {
  /// Przed osiągnięciem progu wyczucia (0–8 km): dyspozycja ukryta (`?`).
  hidden,

  /// Częściowe wyczucie tendencji (8–20 km): kolarz czuje kierunek (+ / 0 / -).
  sensing,

  /// Pełne odkrycie (do 30 km): znana dokładna liczba diamentów (-3..+3) i nadany komunikat radia.
  revealed;

  String toJson() => name;

  static DayFormDiscoveryPhase fromJson(String value) {
    return DayFormDiscoveryPhase.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DayFormDiscoveryPhase.hidden,
    );
  }

  String get labelPl {
    switch (this) {
      case DayFormDiscoveryPhase.hidden:
        return 'Nierozpoznana';
      case DayFormDiscoveryPhase.sensing:
        return 'Pierwsze odczucia';
      case DayFormDiscoveryPhase.revealed:
        return 'Potwierdzona';
    }
  }
}

/// Kierunek wstępnego wyczucia dyspozycji przed pełnym odkryciem.
enum DayFormSensingTrend {
  negative,
  neutral,
  positive;

  String toJson() => name;

  static DayFormSensingTrend fromJson(String value) {
    return DayFormSensingTrend.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DayFormSensingTrend.neutral,
    );
  }

  String get labelPl {
    switch (this) {
      case DayFormSensingTrend.negative:
        return 'Nogi ciężkawe (-?)';
      case DayFormSensingTrend.neutral:
        return 'Równy rytm (~0?)';
      case DayFormSensingTrend.positive:
        return 'Świeża noga (+?)';
    }
  }
}

/// Dane wejściowe do losowania dziennej wariancji dyspozycji ("The Legs").
class DailyRiderDayFormInput {
  final String riderId;
  final String riderName;
  final String teamName;

  /// Aktualna świeżość kolarza (TSB = CTL - ATL), typowo od -40 do +30.
  final double trainingStressBalance;

  /// Jakość snu przed etapem w skali 0.0 - 1.0.
  final double sleepQuality;

  /// Morale kolarza w skali 0.0 - 1.0 (czynnik uzupełniający).
  final double morale;

  /// Czy kolarz wykonał pełną rozgrzewkę na trenażerze przed startem.
  final bool didWarmup;

  const DailyRiderDayFormInput({
    required this.riderId,
    required this.riderName,
    this.teamName = 'Team',
    required this.trainingStressBalance,
    required this.sleepQuality,
    this.morale = 0.70,
    this.didWarmup = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamName': teamName,
      'trainingStressBalance': trainingStressBalance,
      'sleepQuality': sleepQuality,
      'morale': morale,
      'didWarmup': didWarmup,
    };
  }

  factory DailyRiderDayFormInput.fromJson(Map<String, dynamic> json) {
    return DailyRiderDayFormInput(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? 'Kolarz',
      teamName: json['teamName'] as String? ?? 'Team',
      trainingStressBalance:
          (json['trainingStressBalance'] as num?)?.toDouble() ?? 0.0,
      sleepQuality: (json['sleepQuality'] as num?)?.toDouble() ?? 0.75,
      morale: (json['morale'] as num?)?.toDouble() ?? 0.70,
      didWarmup: json['didWarmup'] as bool? ?? false,
    );
  }
}

/// Mnożniki wydolności wynikające ze skali dyspozycji dnia (-3..+3 diamentów).
class DayFormPerformanceModifiers {
  final int diamondScore;
  final double ftpMultiplier;
  final double wPrimeMultiplier;
  final double recoveryMultiplier;
  final double perceivedEffortOffset;

  const DayFormPerformanceModifiers._({
    required this.diamondScore,
    required this.ftpMultiplier,
    required this.wPrimeMultiplier,
    required this.recoveryMultiplier,
    required this.perceivedEffortOffset,
  });

  factory DayFormPerformanceModifiers.fromDiamonds(int diamonds) {
    final int clamped = diamonds.clamp(
      kMinDayFormDiamonds,
      kMaxDayFormDiamonds,
    );
    return DayFormPerformanceModifiers._(
      diamondScore: clamped,
      ftpMultiplier: 1.0 + (clamped * 0.018),
      wPrimeMultiplier: 1.0 + (clamped * 0.035),
      recoveryMultiplier: (1.0 + (clamped * 0.040)).clamp(0.80, 1.15),
      perceivedEffortOffset: -clamped * 0.5,
    );
  }

  /// Zwraca skorygowane FTP [W] z zabezpieczeniem dolnej granicy.
  int applyToFtp(int baseFtpWatts) {
    if (baseFtpWatts <= 0) return 0;
    return math.max(60, (baseFtpWatts * ftpMultiplier).round());
  }

  /// Zwraca skorygowaną pojemność beztlenową W' [J].
  double applyToWPrime(double baseWPrimeJoules) {
    if (baseWPrimeJoules <= 0) return 0.0;
    return math.max(1000.0, baseWPrimeJoules * wPrimeMultiplier);
  }

  String get formattedDeltaPercent {
    final double pct = (ftpMultiplier - 1.0) * 100.0;
    final String sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% FTP';
  }
}

/// Pełny stan dyspozycji dnia kolarza i postępu jej odkrywania na pierwszych 30 km.
class RiderDayFormState {
  final String riderId;
  final String riderName;
  final String teamName;

  /// Rzeczywista wylosowana wartość dyspozycji (-3..+3 diamentów).
  final int actualDiamonds;

  /// Wartość oczekiwana (średnia przed losowaniem) wyliczona z TSB i jakości snu.
  final double expectedMeanDiamonds;

  /// Wpływ składowej TSB na średnią oczekiwaną.
  final double tsbContribution;

  /// Wpływ jakości snu na średnią oczekiwaną.
  final double sleepContribution;

  /// Osobisty kilometr pełnego odkrycia (między 18.0 a 30.0 km).
  final double revealThresholdKm;

  /// Aktualna faza odkrywania.
  final DayFormDiscoveryPhase discoveryPhase;

  /// Postęp odkrywania w zakresie 0.0 - 1.0.
  final double discoveryProgress;

  /// Ostatni przejechany kilometr etapu [km].
  final double lastObservedKm;

  /// Wstępna tendencja widoczna w fazie [DayFormDiscoveryPhase.sensing].
  final DayFormSensingTrend? sensingTrend;

  /// Czy wyemitowano już komunikat radiowy o odkryciu dyspozycji.
  final bool hasEmittedRadioMessage;

  /// Wyemitowany komunikat radiowy (po osiągnięciu fazy `revealed`).
  final RaceRadioMessage? radioMessage;

  const RiderDayFormState({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.actualDiamonds,
    required this.expectedMeanDiamonds,
    required this.tsbContribution,
    required this.sleepContribution,
    required this.revealThresholdKm,
    required this.discoveryPhase,
    required this.discoveryProgress,
    required this.lastObservedKm,
    required this.sensingTrend,
    required this.hasEmittedRadioMessage,
    this.radioMessage,
  });

  bool get isFullyRevealed => discoveryPhase == DayFormDiscoveryPhase.revealed;

  /// Zwraca odkrytą liczbę diamentów lub `null`, jeśli kolarz jeszcze jej nie rozpoznał.
  int? get visibleDiamonds => isFullyRevealed ? actualDiamonds : null;

  /// Zwraca aktywne mnożniki fizjologiczne (w symulacji działają od 0 km, niezależnie od wiedzy gracza).
  DayFormPerformanceModifiers get actualModifiers =>
      DayFormPerformanceModifiers.fromDiamonds(actualDiamonds);

  /// Sformatowany wynik diamentowy, np. `+2`, `-2`, `0`, lub `?` przed odkryciem.
  String get formattedVisibleScore {
    if (!isFullyRevealed) {
      if (discoveryPhase == DayFormDiscoveryPhase.sensing &&
          sensingTrend != null) {
        switch (sensingTrend!) {
          case DayFormSensingTrend.positive:
            return '+?';
          case DayFormSensingTrend.negative:
            return '-?';
          case DayFormSensingTrend.neutral:
            return '~0';
        }
      }
      return '?';
    }
    return formatDiamondScore(actualDiamonds);
  }

  static String formatDiamondScore(int score) {
    final int clamped = score.clamp(kMinDayFormDiamonds, kMaxDayFormDiamonds);
    if (clamped > 0) return '+$clamped';
    return '$clamped';
  }

  RiderDayFormState copyWith({
    DayFormDiscoveryPhase? discoveryPhase,
    double? discoveryProgress,
    double? lastObservedKm,
    DayFormSensingTrend? sensingTrend,
    bool? hasEmittedRadioMessage,
    RaceRadioMessage? radioMessage,
  }) {
    return RiderDayFormState(
      riderId: riderId,
      riderName: riderName,
      teamName: teamName,
      actualDiamonds: actualDiamonds,
      expectedMeanDiamonds: expectedMeanDiamonds,
      tsbContribution: tsbContribution,
      sleepContribution: sleepContribution,
      revealThresholdKm: revealThresholdKm,
      discoveryPhase: discoveryPhase ?? this.discoveryPhase,
      discoveryProgress: discoveryProgress ?? this.discoveryProgress,
      lastObservedKm: lastObservedKm ?? this.lastObservedKm,
      sensingTrend: sensingTrend ?? this.sensingTrend,
      hasEmittedRadioMessage:
          hasEmittedRadioMessage ?? this.hasEmittedRadioMessage,
      radioMessage: radioMessage ?? this.radioMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamName': teamName,
      'actualDiamonds': actualDiamonds,
      'expectedMeanDiamonds': expectedMeanDiamonds,
      'tsbContribution': tsbContribution,
      'sleepContribution': sleepContribution,
      'revealThresholdKm': revealThresholdKm,
      'discoveryPhase': discoveryPhase.toJson(),
      'discoveryProgress': discoveryProgress,
      'lastObservedKm': lastObservedKm,
      'sensingTrend': sensingTrend?.toJson(),
      'hasEmittedRadioMessage': hasEmittedRadioMessage,
      'radioMessage': radioMessage?.toJson(),
    };
  }

  factory RiderDayFormState.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? radioJson =
        json['radioMessage'] as Map<String, dynamic>?;
    return RiderDayFormState(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? 'Kolarz',
      teamName: json['teamName'] as String? ?? 'Team',
      actualDiamonds: (json['actualDiamonds'] as num?)?.toInt() ?? 0,
      expectedMeanDiamonds:
          (json['expectedMeanDiamonds'] as num?)?.toDouble() ?? 0.0,
      tsbContribution: (json['tsbContribution'] as num?)?.toDouble() ?? 0.0,
      sleepContribution: (json['sleepContribution'] as num?)?.toDouble() ?? 0.0,
      revealThresholdKm:
          (json['revealThresholdKm'] as num?)?.toDouble() ?? 26.0,
      discoveryPhase: DayFormDiscoveryPhase.fromJson(
        json['discoveryPhase'] as String? ?? 'hidden',
      ),
      discoveryProgress:
          (json['discoveryProgress'] as num?)?.toDouble() ?? 0.0,
      lastObservedKm: (json['lastObservedKm'] as num?)?.toDouble() ?? 0.0,
      sensingTrend: json['sensingTrend'] != null
          ? DayFormSensingTrend.fromJson(json['sensingTrend'] as String)
          : null,
      hasEmittedRadioMessage: json['hasEmittedRadioMessage'] as bool? ?? false,
      radioMessage:
          radioJson != null ? RaceRadioMessage.fromJson(radioJson) : null,
    );
  }
}

/// Wynik pojedynczego kroku aktualizacji odkrywania dyspozycji dnia.
class DayFormDiscoveryStepResult {
  final RiderDayFormState state;
  final bool newlyRevealed;
  final RaceRadioMessage? emittedRadioMessage;

  const DayFormDiscoveryStepResult({
    required this.state,
    required this.newlyRevealed,
    this.emittedRadioMessage,
  });
}

/// Silnik systemu dyspozycji dnia (`Daily Form / "The Legs"`) w skali od -3 do +3 diamentów.
///
/// Generuje losową wariancję dzienną silnie skorelowaną z formą TSB
/// (Training Stress Balance) i jakością snu, a następnie stopniowo odkrywa
/// ją podczas pierwszych 30 kilometrów etapu z komunikatem radiowym.
class DailyRiderDayFormVarianceEngine {
  final math.Random _random;

  DailyRiderDayFormVarianceEngine({int? seed, math.Random? random})
      : _random = random ?? (seed != null ? math.Random(seed) : math.Random());

  /// Oblicza wkład TSB [-1.65 .. +1.65] oraz jakości snu [-1.45 .. +1.45]
  /// do oczekiwanej średniej wartości diamentów.
  static ({double expectedMean, double tsbContribution, double sleepContribution})
      computeExpectedMean(DailyRiderDayFormInput input) {
    final double clampedTsb = input.trainingStressBalance.clamp(-40.0, 30.0);
    // Nieliniowe wysycenie TSB: świeżość +15..+25 daje wyraźny pik formy,
    // a głębokie zmęczenie poniżej -20 mocno ciąży w dół.
    final double normalizedTsb = clampedTsb >= 0
        ? math.min(1.0, clampedTsb / 22.0)
        : math.max(-1.0, clampedTsb / 26.0);
    final double tsbContribution = normalizedTsb * 1.55;

    // Jakość snu 0.72 jest punktem neutralnym; <0.45 mocno obniża dyspozycję, >0.85 podnosi.
    final double clampedSleep = input.sleepQuality.clamp(0.0, 1.0);
    final double sleepDelta = (clampedSleep - 0.72) / 0.28;
    final double sleepContribution = (sleepDelta * 1.35).clamp(-1.85, 1.35);

    // Morale i rozgrzewka jako drobne korekty wspomagające.
    final double moraleContribution =
        ((input.morale.clamp(0.0, 1.0) - 0.65) * 0.65).clamp(-0.35, 0.35);
    final double warmupBonus = input.didWarmup ? 0.15 : 0.0;

    final double expectedMean = (tsbContribution +
            sleepContribution +
            moraleContribution +
            warmupBonus)
        .clamp(-2.85, 2.85);

    return (
      expectedMean: expectedMean,
      tsbContribution: tsbContribution,
      sleepContribution: sleepContribution,
    );
  }

  /// Zwraca rozkład prawdopodobieństwa dla każdej oceny od -3 do +3 diamentów
  /// dla podanych parametrów wejściowych (silna korelacja z TSB i snem).
  static Map<int, double> computeProbabilityDistribution(
    DailyRiderDayFormInput input,
  ) {
    final ({
      double expectedMean,
      double tsbContribution,
      double sleepContribution,
    }) meanData = computeExpectedMean(input);

    // Wąskie odchylenie standardowe (sigma ~ 0.85) gwarantuje silną korelację
    // z TSB i snem przy zachowaniu emocjonującej, realistycznej wariancji dziennej.
    const double sigma = 0.85;
    final Map<int, double> rawWeights = <int, double>{};
    double totalWeight = 0.0;

    for (int score = kMinDayFormDiamonds;
        score <= kMaxDayFormDiamonds;
        score++) {
      final double diff = score - meanData.expectedMean;
      final double weight = math.exp(-(diff * diff) / (2.0 * sigma * sigma));
      rawWeights[score] = weight;
      totalWeight += weight;
    }

    if (totalWeight <= 0) {
      return <int, double>{
        for (int s = kMinDayFormDiamonds; s <= kMaxDayFormDiamonds; s++)
          s: 1.0 / 7.0,
      };
    }

    return <int, double>{
      for (final MapEntry<int, double> entry in rawWeights.entries)
        entry.key: entry.value / totalWeight,
    };
  }

  /// Losuje początkowy stan dyspozycji dnia dla pojedynczego kolarza przed startem etapu.
  RiderDayFormState drawInitialDayForm(DailyRiderDayFormInput input) {
    final ({
      double expectedMean,
      double tsbContribution,
      double sleepContribution,
    }) meanData = computeExpectedMean(input);

    final Map<int, double> distribution = computeProbabilityDistribution(input);
    final double roll = _random.nextDouble();
    double cumulative = 0.0;
    int drawnDiamonds = 0;

    for (int score = kMinDayFormDiamonds;
        score <= kMaxDayFormDiamonds;
        score++) {
      cumulative += distribution[score] ?? 0.0;
      if (roll <= cumulative) {
        drawnDiamonds = score;
        break;
      }
    }

    // Skrajne dyspozycje (+3 / -3) są wyczuwane nieco szybciej (ok. 18–24 km),
    // natomiast subtelne różnice potrzebują pełniejszych 24–30 km rozjechania.
    final double extremityFactor = drawnDiamonds.abs() / 3.0;
    final double baseMinKm = 24.0 - (extremityFactor * 6.0);
    final double spanKm = kDayFormDiscoveryMaxKm - baseMinKm;
    final double revealThresholdKm =
        (baseMinKm + _random.nextDouble() * spanKm).clamp(
      18.0,
      kDayFormDiscoveryMaxKm,
    );

    return RiderDayFormState(
      riderId: input.riderId,
      riderName: input.riderName,
      teamName: input.teamName,
      actualDiamonds: drawnDiamonds,
      expectedMeanDiamonds: meanData.expectedMean,
      tsbContribution: meanData.tsbContribution,
      sleepContribution: meanData.sleepContribution,
      revealThresholdKm: revealThresholdKm,
      discoveryPhase: DayFormDiscoveryPhase.hidden,
      discoveryProgress: 0.0,
      lastObservedKm: 0.0,
      sensingTrend: null,
      hasEmittedRadioMessage: false,
      radioMessage: null,
    );
  }

  /// Losuje początkowe dyspozycje dnia dla całego składu drużyny.
  List<RiderDayFormState> drawForRoster(List<DailyRiderDayFormInput> roster) {
    return roster.map(drawInitialDayForm).toList(growable: false);
  }

  /// Aktualizuje postęp odkrywania dyspozycji dnia wraz z przejechanymi kilometrami etapu.
  ///
  /// Podczas pierwszych 30 km kolarz przechodzi z fazy `hidden` -> `sensing` -> `revealed`.
  /// W chwili osiągnięcia fazy `revealed` generowany jest komunikat radiowy DS.
  DayFormDiscoveryStepResult stepDiscovery({
    required RiderDayFormState currentState,
    required double distanceCoveredKm,
    required double elapsedSeconds,
    double currentIntensityFactor = 0.75,
  }) {
    final double safeKm = math.max(
      currentState.lastObservedKm,
      distanceCoveredKm.clamp(0.0, double.infinity),
    );

    // Wyższe tempo na starcie (np. walka o ucieczkę) przyspiesza wyczucie nóg,
    // jednak pełne odkrycie zawsze mieści się w pierwszych 30 km.
    final double effectiveThresholdKm = currentIntensityFactor >= 0.95
        ? math.max(15.0, currentState.revealThresholdKm - 3.0)
        : currentState.revealThresholdKm;

    final double progress = (safeKm / effectiveThresholdKm).clamp(0.0, 1.0);

    if (currentState.isFullyRevealed) {
      return DayFormDiscoveryStepResult(
        state: currentState.copyWith(
          lastObservedKm: safeKm,
          discoveryProgress: 1.0,
        ),
        newlyRevealed: false,
      );
    }

    if (safeKm >= effectiveThresholdKm || safeKm >= kDayFormDiscoveryMaxKm) {
      final RaceRadioMessage radio = buildRadioMessageForDayForm(
        riderId: currentState.riderId,
        riderName: currentState.riderName,
        teamName: currentState.teamName,
        diamonds: currentState.actualDiamonds,
        kilometerMark: safeKm,
        elapsedSeconds: elapsedSeconds,
      );

      final RiderDayFormState revealedState = currentState.copyWith(
        discoveryPhase: DayFormDiscoveryPhase.revealed,
        discoveryProgress: 1.0,
        lastObservedKm: safeKm,
        sensingTrend: _trendForScore(currentState.actualDiamonds),
        hasEmittedRadioMessage: true,
        radioMessage: radio,
      );

      return DayFormDiscoveryStepResult(
        state: revealedState,
        newlyRevealed: true,
        emittedRadioMessage: radio,
      );
    }

    if (safeKm >= kDayFormSensingStartKm) {
      final DayFormSensingTrend trend = _trendForScore(
        currentState.actualDiamonds,
      );
      return DayFormDiscoveryStepResult(
        state: currentState.copyWith(
          discoveryPhase: DayFormDiscoveryPhase.sensing,
          discoveryProgress: progress,
          lastObservedKm: safeKm,
          sensingTrend: trend,
        ),
        newlyRevealed: false,
      );
    }

    return DayFormDiscoveryStepResult(
      state: currentState.copyWith(
        discoveryPhase: DayFormDiscoveryPhase.hidden,
        discoveryProgress: progress,
        lastObservedKm: safeKm,
      ),
      newlyRevealed: false,
    );
  }

  /// Aktualizuje postęp odkrywania dla wszystkich kolarzy z listy.
  List<DayFormDiscoveryStepResult> stepRosterDiscovery({
    required List<RiderDayFormState> states,
    required double distanceCoveredKm,
    required double elapsedSeconds,
    double currentIntensityFactor = 0.75,
  }) {
    return states
        .map(
          (state) => stepDiscovery(
            currentState: state,
            distanceCoveredKm: distanceCoveredKm,
            elapsedSeconds: elapsedSeconds,
            currentIntensityFactor: currentIntensityFactor,
          ),
        )
        .toList(growable: false);
  }

  static DayFormSensingTrend _trendForScore(int diamonds) {
    if (diamonds > 0) return DayFormSensingTrend.positive;
    if (diamonds < 0) return DayFormSensingTrend.negative;
    return DayFormSensingTrend.neutral;
  }

  /// Zwraca autentyczny komunikat kolarza przez radio drużynowe dla danej oceny (-3..+3).
  static String radioQuoteForDiamonds(int diamonds) {
    switch (diamonds.clamp(kMinDayFormDiamonds, kMaxDayFormDiamonds)) {
      case 3:
        return 'Nogi dzisiaj są absolutnie kosmiczne, czuję dzień konia! (+3)';
      case 2:
        return 'Czuję dzisiaj niesamowity gaz w nogach! (+2)';
      case 1:
        return 'Nogi kręcą bardzo lekko, mam dziś dobrą dyspozycję (+1)';
      case 0:
        return 'Standardowe nogi, czuję się normalnie na dzisiejszym etapie (0)';
      case -1:
        return 'Nogi są dzisiaj trochę ospałe, brakuje świeżości (-1)';
      case -2:
        return 'Mam dziś ciężkie nogi (-2)';
      case -3:
      default:
        return 'Totalny beton w nogach od samego startu, będzie ciężka walka (-3)';
    }
  }

  /// Buduje pełny obiekt [RaceRadioMessage] dla odkrytej dyspozycji dnia.
  static RaceRadioMessage buildRadioMessageForDayForm({
    required String riderId,
    required String riderName,
    required String teamName,
    required int diamonds,
    required double kilometerMark,
    required double elapsedSeconds,
  }) {
    final int clamped = diamonds.clamp(
      kMinDayFormDiamonds,
      kMaxDayFormDiamonds,
    );
    final RadioPriority priority;
    if (clamped >= 2) {
      priority = RadioPriority.tactical;
    } else if (clamped == -2) {
      priority = RadioPriority.warning;
    } else if (clamped <= -3) {
      priority = RadioPriority.urgent;
    } else {
      priority = RadioPriority.info;
    }

    final String quote = radioQuoteForDiamonds(clamped);

    return RaceRadioMessage(
      id: 'day_form_${riderId}_${kilometerMark.toStringAsFixed(1)}',
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.directeurSportif,
      priority: priority,
      senderName: '$riderName ($teamName)',
      message: quote,
      highlightedRiderName: riderName,
      highlightedTeamName: teamName,
    );
  }
}

/// Produkcyjny panel HUD/zarządzania dla systemu dyspozycji dnia ("The Legs").
///
/// Obsługuje responsywne układy dla 390x844, 1024x768 oraz 1600x900,
/// pełną paletę [AppColors], czcionkę `Inter` oraz stany hover/active/disabled/focus.
class DailyRiderDayFormVariancePanel extends StatefulWidget {
  final List<RiderDayFormState> initialStates;
  final double currentDistanceKm;
  final ValueChanged<RiderDayFormState>? onRiderSelected;
  final VoidCallback? onAdvance5Km;
  final VoidCallback? onRedrawForm;

  const DailyRiderDayFormVariancePanel({
    super.key,
    required this.initialStates,
    this.currentDistanceKm = 0.0,
    this.onRiderSelected,
    this.onAdvance5Km,
    this.onRedrawForm,
  });

  @override
  State<DailyRiderDayFormVariancePanel> createState() =>
      _DailyRiderDayFormVariancePanelState();
}

class _DailyRiderDayFormVariancePanelState
    extends State<DailyRiderDayFormVariancePanel> {
  String? _selectedRiderId;
  DayFormDiscoveryPhase? _phaseFilter;

  @override
  void initState() {
    super.initState();
    if (widget.initialStates.isNotEmpty) {
      _selectedRiderId = widget.initialStates.first.riderId;
    }
  }

  @override
  void didUpdateWidget(covariant DailyRiderDayFormVariancePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStates.isNotEmpty &&
        !widget.initialStates.any((s) => s.riderId == _selectedRiderId)) {
      _selectedRiderId = widget.initialStates.first.riderId;
    }
  }

  List<RiderDayFormState> get _filteredStates {
    if (_phaseFilter == null) return widget.initialStates;
    return widget.initialStates
        .where((s) => s.discoveryPhase == _phaseFilter)
        .toList(growable: false);
  }

  RiderDayFormState? get _selectedState {
    if (widget.initialStates.isEmpty) return null;
    for (final RiderDayFormState s in widget.initialStates) {
      if (s.riderId == _selectedRiderId) return s;
    }
    return widget.initialStates.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 680;
          final bool isWideDesktop = constraints.maxWidth >= 1100;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 14),
                _buildDiscoveryProgressBar(),
                const SizedBox(height: 14),
                _buildFilterBar(isCompact),
                const SizedBox(height: 14),
                if (isWideDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildRiderList(isCompact)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildSelectedInspector()),
                    ],
                  )
                else ...[
                  _buildRiderList(isCompact),
                  const SizedBox(height: 14),
                  _buildSelectedInspector(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final int revealedCount =
        widget.initialStates.where((s) => s.isFullyRevealed).length;
    final int totalCount = widget.initialStates.length;

    final Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.diamond_outlined,
              color: AppColors.goldAccent,
              size: 20,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Dyspozycja Dnia ("The Legs")',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Skala -3..+3 diamentów • Odkryte: $revealedCount/$totalCount',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    final Widget actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionPillButton(
          label: '+5 km etapu',
          icon: Icons.fast_forward_rounded,
          onPressed: widget.currentDistanceKm < kDayFormDiscoveryMaxKm
              ? widget.onAdvance5Km
              : null,
          accentColor: AppColors.accentBlue,
        ),
        _ActionPillButton(
          label: 'Losuj dzień',
          icon: Icons.casino_outlined,
          onPressed: widget.onRedrawForm,
          accentColor: AppColors.goldAccent,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  Widget _buildDiscoveryProgressBar() {
    final double clampedKm = widget.currentDistanceKm.clamp(
      0.0,
      kDayFormDiscoveryMaxKm,
    );
    final double ratio = (clampedKm / kDayFormDiscoveryMaxKm).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Okno rozpoznania dyspozycji (pierwsze 30 km)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${clampedKm.toStringAsFixed(1)} / 30.0 km',
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
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: ratio),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ratio >= 1.0
                        ? AppColors.statusSuccess
                        : AppColors.accentBlue,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          label: 'Wszyscy (${widget.initialStates.length})',
          selected: _phaseFilter == null,
          onTap: () => setState(() => _phaseFilter = null),
        ),
        for (final DayFormDiscoveryPhase phase in DayFormDiscoveryPhase.values)
          _FilterChipButton(
            label:
                '${phase.labelPl} (${widget.initialStates.where((s) => s.discoveryPhase == phase).length})',
            selected: _phaseFilter == phase,
            onTap: () => setState(() => _phaseFilter = phase),
          ),
      ],
    );
  }

  Widget _buildRiderList(bool isCompact) {
    final List<RiderDayFormState> items = _filteredStates;
    if (items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
        ),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'Brak kolarzy spełniających wybrane kryterium fazy odkrycia.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _RiderDayFormRowCard(
            state: items[i],
            selected: items[i].riderId == _selectedRiderId,
            isCompact: isCompact,
            onTap: () {
              setState(() => _selectedRiderId = items[i].riderId);
              widget.onRiderSelected?.call(items[i]);
            },
          ),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSelectedInspector() {
    final RiderDayFormState? state = _selectedState;
    if (state == null) {
      return const SizedBox.shrink();
    }

    final Color badgeColor = _colorForState(state);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      child: Container(
        key: ValueKey<String>('${state.riderId}_${state.discoveryPhase.name}'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
        ),
        padding: const EdgeInsets.all(16),
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
                        state.riderName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.teamName} • ${state.discoveryPhase.labelPl}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    state.formattedVisibleScore,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DiamondScaleBar(
              revealedScore: state.visibleDiamonds,
              accentColor: badgeColor,
            ),
            const SizedBox(height: 14),
            _MetricRow(
              label: 'Korelacja TSB + Sen (średnia)',
              value: state.expectedMeanDiamonds.toStringAsFixed(2),
            ),
            const SizedBox(height: 6),
            _MetricRow(
              label: 'Próg odkrycia kolarza',
              value: '${state.revealThresholdKm.toStringAsFixed(1)} km',
            ),
            if (state.isFullyRevealed) ...[
              const SizedBox(height: 6),
              _MetricRow(
                label: 'Wpływ na wydolność',
                value: state.actualModifiers.formattedDeltaPercent,
              ),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.headset_mic_outlined,
                    size: 16,
                    color: state.radioMessage != null
                        ? badgeColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.radioMessage != null
                          ? '"${state.radioMessage!.message}"'
                          : state.discoveryPhase == DayFormDiscoveryPhase.sensing
                              ? 'Radio DS: Kolarz rozkręca nogi (${state.sensingTrend?.labelPl ?? "..."}).'
                              : 'Radio DS: Oczekiwanie na pierwsze odczucia po starcie.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorForState(RiderDayFormState state) {
    if (!state.isFullyRevealed) {
      if (state.discoveryPhase == DayFormDiscoveryPhase.sensing) {
        return AppColors.accentBlue;
      }
      return AppColors.textSecondary;
    }
    if (state.actualDiamonds >= 2) return AppColors.statusSuccess;
    if (state.actualDiamonds == 1) return AppColors.accentBlue;
    if (state.actualDiamonds == 0) return AppColors.goldAccent;
    if (state.actualDiamonds == -1) return AppColors.amberWarning;
    return AppColors.crimsonAlert;
  }
}

class _RiderDayFormRowCard extends StatefulWidget {
  final RiderDayFormState state;
  final bool selected;
  final bool isCompact;
  final VoidCallback onTap;

  const _RiderDayFormRowCard({
    required this.state,
    required this.selected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_RiderDayFormRowCard> createState() => _RiderDayFormRowCardState();
}

class _RiderDayFormRowCardState extends State<_RiderDayFormRowCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        _DailyRiderDayFormVariancePanelState._colorForState(widget.state);

    final Color bgColor;
    if (_pressed) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.9);
    } else if (widget.selected || _hovered) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.surface;
    }

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? accent.withValues(alpha: 0.75)
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.state.riderName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.state.discoveryPhase.labelPl,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (!widget.isCompact) ...[
                SizedBox(
                  width: 84,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: widget.state.discoveryProgress,
                      minHeight: 5,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                constraints: const BoxConstraints(minWidth: 44),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.state.formattedVisibleScore,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiamondScaleBar extends StatelessWidget {
  final int? revealedScore;
  final Color accentColor;

  const _DiamondScaleBar({
    required this.revealedScore,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int score = kMinDayFormDiamonds;
            score <= kMaxDayFormDiamonds;
            score++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: revealedScore == score
                      ? accentColor.withValues(alpha: 0.22)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: revealedScore == score
                        ? accentColor
                        : AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  RiderDayFormState.formatDiamondScore(score),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: revealedScore == score
                        ? accentColor
                        : AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
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
      ],
    );
  }
}

class _ActionPillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color accentColor;

  const _ActionPillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.accentColor,
  });

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color bg = !enabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.28)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.18)
                : AppColors.surfaceLight;

    final Color fg = enabled ? AppColors.textPrimary : AppColors.textSecondary;
    final Color border = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.accentColor.withValues(alpha: _hovered ? 0.8 : 0.45);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: enabled ? widget.accentColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.25)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.surface;
    final Color border = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.primaryAccent
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
