// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../models/race/race_stage.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_physiology.dart';

/// Minimalne nachylenie terenu [%], od którego odcinek uznawany jest za podjazd
/// na potrzeby odkrywania dyspozycji dnia powyżej progu LT1.
const double kFirstClimbMinGradientPercent = 2.0;

/// Dane wejściowe do algorytmu losowania ważonego dyspozycji dnia kolarza.
class DayConditionDrawInputs {
  /// Aktualna świeżość kolarza (Training Stress Balance = CTL - ATL).
  final double trainingStressBalance;

  /// Jakość snu i regeneracji nocnej przed etapem (0.0 - 1.0).
  final double sleepQuality;

  /// Warunki pogodowe panujące podczas etapu.
  final WeatherCondition weatherCondition;

  /// Temperatura otoczenia w stopniach Celsjusza [°C].
  final double temperatureCelsius;

  /// Odporność kolarza na deszcz i chłód (0 - 100).
  final int rainResistance;

  /// Tolerancja kolarza na wysoką temperaturę i upał (0 - 100).
  final int heatTolerance;

  /// Aktualne morale kolarza (0.0 - 1.0).
  final double morale;

  /// Lojalność wobec lidera zespołu (0.0 - 1.0).
  final double leaderLoyalty;

  /// Czy kolarz należy do drużyny gracza.
  final bool isPlayerRider;

  /// Czy kolarz wykonał rozgrzewkę na trenażerze przed startem etapu.
  final bool didTrainerWarmup;

  const DayConditionDrawInputs({
    required this.trainingStressBalance,
    required this.sleepQuality,
    required this.weatherCondition,
    required this.temperatureCelsius,
    required this.rainResistance,
    required this.heatTolerance,
    required this.morale,
    required this.leaderLoyalty,
    this.isPlayerRider = false,
    this.didTrainerWarmup = false,
  });

  /// Buduje dane wejściowe bezpośrednio z modelu [Rider] i warunków etapu.
  factory DayConditionDrawInputs.fromRider({
    required Rider rider,
    required WeatherCondition weatherCondition,
    double? temperatureCelsius,
    double sleepQuality = 0.75,
    bool isPlayerRider = false,
    bool didTrainerWarmup = false,
  }) {
    final double resolvedTemp =
        temperatureCelsius ?? _defaultTemperatureForWeather(weatherCondition);

    // Łączymy morale kontraktowe i fizjologiczne (zależne od świeżości)
    final double combinedMorale =
        ((rider.contract.morale + rider.health.morale) * 0.5).clamp(0.0, 1.0);

    return DayConditionDrawInputs(
      trainingStressBalance: rider.health.trainingStressBalance,
      sleepQuality: sleepQuality.clamp(0.0, 1.0),
      weatherCondition: weatherCondition,
      temperatureCelsius: resolvedTemp,
      rainResistance: rider.skills.rainResistance,
      heatTolerance: rider.skills.heatTolerance,
      morale: combinedMorale,
      leaderLoyalty: rider.contract.leaderLoyalty.clamp(0.0, 1.0),
      isPlayerRider: isPlayerRider,
      didTrainerWarmup: didTrainerWarmup,
    );
  }

  static double _defaultTemperatureForWeather(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.sunny:
        return 23.0;
      case WeatherCondition.overcast:
        return 17.0;
      case WeatherCondition.lightRain:
        return 13.0;
      case WeatherCondition.heavyStorm:
        return 10.0;
      case WeatherCondition.crosswindGale:
        return 14.0;
      case WeatherCondition.extremeHeat:
        return 35.0;
    }
  }
}

/// Mnożniki fizjologiczne wynikające z wylosowanej dyspozycji dnia (-5 do +5).
class DayConditionModifiers {
  /// Skala dyspozycji dnia od -5 ("Kryzys / Ciężkie nogi") do +5 ("Dzień Konia").
  final int conditionScore;

  /// Mnożnik dostępnego FTP (+1.2% za każdy punkt, analogicznie spadek przy ujemnych).
  final double ftpMultiplier;

  /// Mnożnik pojemności beztlenowej W' (+2.5% za każdy punkt, analogicznie spadek).
  final double wPrimeMultiplier;

  /// Mnożnik szybkości regeneracji między skokami (+3.0% za każdy punkt).
  final double recoverySpeedMultiplier;

  /// Mnożnik pułapu tlenowego VO2max (+1.2% za każdy punkt; wartości ujemne obniżają pułap).
  final double vo2MaxMultiplier;

  const DayConditionModifiers._({
    required this.conditionScore,
    required this.ftpMultiplier,
    required this.wPrimeMultiplier,
    required this.recoverySpeedMultiplier,
    required this.vo2MaxMultiplier,
  });

  /// Wylicza dokładne mnożniki dla danej wartości dyspozycji dnia [-5, +5].
  factory DayConditionModifiers.fromScore(int score) {
    final int clamped = score.clamp(-5, 5);
    return DayConditionModifiers._(
      conditionScore: clamped,
      ftpMultiplier: 1.0 + (clamped * 0.012),
      wPrimeMultiplier: 1.0 + (clamped * 0.025),
      recoverySpeedMultiplier: math.max(0.70, 1.0 + (clamped * 0.030)),
      vo2MaxMultiplier: 1.0 + (clamped * 0.012),
    );
  }

  /// Zwraca skorygowane FTP [W].
  int applyToFtp(int baseFtpWatts) {
    if (baseFtpWatts <= 0) return 0;
    return math.max(50, (baseFtpWatts * ftpMultiplier).round());
  }

  /// Zwraca skorygowaną pojemność beztlenową W' [J].
  int applyToWPrime(int baseWPrimeJoules) {
    if (baseWPrimeJoules <= 0) return 0;
    return math.max(1000, (baseWPrimeJoules * wPrimeMultiplier).round());
  }

  /// Zwraca skorygowaną stałą czasową regeneracji tau [s] (szybsza regeneracja = niższe tau).
  double applyToRecoveryTau(double baseTauSeconds) {
    if (baseTauSeconds <= 0.0) return 1.0;
    return baseTauSeconds / recoverySpeedMultiplier;
  }

  /// Zwraca skorygowany pułap tlenowy VO2max [ml/kg/min].
  double applyToVo2Max(double baseVo2Max) {
    if (baseVo2Max <= 0.0) return 0.0;
    return baseVo2Max * vo2MaxMultiplier;
  }

  /// Tworzy kopię profilu fizjologicznego kolarza ze zmodyfikowanymi parametrami na dany etap.
  RiderPhysiology applyToPhysiology(RiderPhysiology base) {
    return base.copyWith(
      ftpWatts: applyToFtp(base.ftpWatts),
      wPrimeJoules: applyToWPrime(base.wPrimeJoules),
      vo2Max: applyToVo2Max(base.vo2Max),
      recoveryRate: base.recoveryRate * recoverySpeedMultiplier,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayConditionModifiers &&
        other.conditionScore == conditionScore;
  }

  @override
  int get hashCode => conditionScore.hashCode;
}

/// Stan dyspozycji dnia pojedynczego kolarza wraz z mechaniką odkrywania na trasie.
class RiderDayConditionState {
  /// Identyfikator kolarza.
  final String riderId;

  /// Faktyczna wylosowana dyspozycja dnia (-5 do +5).
  final int actualCondition;

  /// Czy dyspozycja została już odkryta dla gracza (false = ukryta pod '?').
  final bool isRevealed;

  /// Czy kolarz należy do drużyny gracza.
  final bool isPlayerRider;

  /// Czy kolarz odbył rozgrzewkę na trenażerze przed startem.
  final bool didTrainerWarmup;

  /// Dystans etapu [m], na którym dyspozycja została odkryta (null jeśli nadal ukryta lub odkryta na starcie).
  final double? revealedAtDistanceMeters;

  /// Tętno [bpm], przy którym nastąpiło odkrycie po przekroczeniu progu LT1.
  final int? revealedAtHeartRateBpm;

  const RiderDayConditionState({
    required this.riderId,
    required this.actualCondition,
    required this.isRevealed,
    required this.isPlayerRider,
    required this.didTrainerWarmup,
    this.revealedAtDistanceMeters,
    this.revealedAtHeartRateBpm,
  });

  /// Mnożniki fizjologiczne wynikające z rzeczywistej dyspozycji kolarza.
  DayConditionModifiers get modifiers =>
      DayConditionModifiers.fromScore(actualCondition);

  /// Znak do wyświetlenia na HUD/liście startowej: `?` przed odkryciem lub np. `+4`, `-2`, `0`.
  String get displayBadge {
    if (!isRevealed) return '?';
    if (actualCondition > 0) return '+$actualCondition';
    return '$actualCondition';
  }

  /// Czytelna nazwa dyspozycji dnia lub informacja o stanie ukrytym.
  String get displayLabel {
    if (!isRevealed) return 'Nieznana (?)';
    return DayConditionAndBiorhythmEngine.describeCondition(actualCondition);
  }

  RiderDayConditionState copyWith({
    String? riderId,
    int? actualCondition,
    bool? isRevealed,
    bool? isPlayerRider,
    bool? didTrainerWarmup,
    double? revealedAtDistanceMeters,
    int? revealedAtHeartRateBpm,
  }) {
    return RiderDayConditionState(
      riderId: riderId ?? this.riderId,
      actualCondition: actualCondition ?? this.actualCondition,
      isRevealed: isRevealed ?? this.isRevealed,
      isPlayerRider: isPlayerRider ?? this.isPlayerRider,
      didTrainerWarmup: didTrainerWarmup ?? this.didTrainerWarmup,
      revealedAtDistanceMeters:
          revealedAtDistanceMeters ?? this.revealedAtDistanceMeters,
      revealedAtHeartRateBpm:
          revealedAtHeartRateBpm ?? this.revealedAtHeartRateBpm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'actualCondition': actualCondition,
      'isRevealed': isRevealed,
      'isPlayerRider': isPlayerRider,
      'didTrainerWarmup': didTrainerWarmup,
      'revealedAtDistanceMeters': revealedAtDistanceMeters,
      'revealedAtHeartRateBpm': revealedAtHeartRateBpm,
    };
  }

  factory RiderDayConditionState.fromJson(Map<String, dynamic> json) {
    return RiderDayConditionState(
      riderId: json['riderId'] as String,
      actualCondition: (json['actualCondition'] as num).toInt().clamp(-5, 5),
      isRevealed: json['isRevealed'] as bool? ?? false,
      isPlayerRider: json['isPlayerRider'] as bool? ?? false,
      didTrainerWarmup: json['didTrainerWarmup'] as bool? ?? false,
      revealedAtDistanceMeters:
          (json['revealedAtDistanceMeters'] as num?)?.toDouble(),
      revealedAtHeartRateBpm:
          (json['revealedAtHeartRateBpm'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderDayConditionState &&
        other.riderId == riderId &&
        other.actualCondition == actualCondition &&
        other.isRevealed == isRevealed &&
        other.isPlayerRider == isPlayerRider &&
        other.didTrainerWarmup == didTrainerWarmup &&
        other.revealedAtDistanceMeters == revealedAtDistanceMeters &&
        other.revealedAtHeartRateBpm == revealedAtHeartRateBpm;
  }

  @override
  int get hashCode => Object.hash(
        riderId,
        actualCondition,
        isRevealed,
        isPlayerRider,
        didTrainerWarmup,
        revealedAtDistanceMeters,
        revealedAtHeartRateBpm,
      );
}

/// Silnik dyspozycji dnia i biorytmu wyścigowego (-5 do +5).
///
/// Odpowiada za:
/// 1. Algorytm losowania ważonego na podstawie świeżości (TSB), jakości snu,
///    dopasowania pogody (`rainResistance`, `heatTolerance`), morale i lojalności.
/// 2. Przeliczanie wpływu dyspozycji na FTP (+1.2%/pkt), W' (+2.5%/pkt),
///    szybkość regeneracji między skokami oraz pułap tlenowy VO2max.
/// 3. Mechanikę odkrywania dyspozycji ukrytej pod `?` dopiero po przekroczeniu
///    progu LT1 na pierwszym podjeździe (chyba że kolarz gracza odbył rozgrzewkę na trenażerze).
class DayConditionAndBiorhythmEngine {
  static const int minScore = -5;
  static const int maxScore = 5;

  final math.Random _random;

  DayConditionAndBiorhythmEngine({math.Random? random, int? seed})
      : _random = random ?? (seed != null ? math.Random(seed) : math.Random());

  /// Zwraca polski opis słowny poziomu dyspozycji dnia [-5, +5].
  static String describeCondition(int score) {
    switch (score.clamp(minScore, maxScore)) {
      case -5:
        return 'Kryzys / Ciężkie nogi';
      case -4:
        return 'Głębokie zmęczenie';
      case -3:
        return 'Słaby dzień';
      case -2:
        return 'Brak świeżości';
      case -1:
        return 'Lekka ociężałość';
      case 0:
        return 'Dyspozycja bazowa';
      case 1:
        return 'Dobra noga';
      case 2:
        return 'Wysoka dyspozycja';
      case 3:
        return 'Znakomita forma';
      case 4:
        return 'Fenomenalna dyspozycja';
      case 5:
        return 'Dzień Konia / Diamentowa noga';
      default:
        return 'Dyspozycja bazowa';
    }
  }

  /// Wylicza skumulowane przesunięcie rozkładu (średnią oczekiwaną przed dyskretyzacją)
  /// na podstawie parametrów fizjologicznych, pogodowych i psychologicznych.
  double computeReadinessBias(DayConditionDrawInputs inputs) {
    // 1. Świeżość TSB (-40 do +30) -> główny czynnik (-1.8 do +1.5)
    final double clampedTsb = inputs.trainingStressBalance.clamp(-40.0, 30.0);
    final double tsbComponent = (clampedTsb / 20.0) * 1.1;

    // 2. Jakość snu i regeneracji nocnej (0.0 - 1.0, neutralne 0.70) -> (-1.2 do +0.6)
    final double sleepDelta = inputs.sleepQuality.clamp(0.0, 1.0) - 0.70;
    final double sleepComponent = sleepDelta * 2.0;

    // 3. Dopasowanie pogody do preferencji kolarza -> (-1.0 do +0.8)
    final double weatherComponent = computeWeatherFitComponent(
      weatherCondition: inputs.weatherCondition,
      temperatureCelsius: inputs.temperatureCelsius,
      rainResistance: inputs.rainResistance,
      heatTolerance: inputs.heatTolerance,
    );

    // 4. Morale (0.0 - 1.0, neutralne 0.70) -> (-0.8 do +0.5)
    final double moraleDelta = inputs.morale.clamp(0.0, 1.0) - 0.70;
    final double moraleComponent = moraleDelta * 1.3;

    // 5. Lojalność wobec lidera (0.0 - 1.0, neutralne 0.70) -> (-0.5 do +0.4)
    final double loyaltyDelta = inputs.leaderLoyalty.clamp(0.0, 1.0) - 0.70;
    final double loyaltyComponent = loyaltyDelta * 0.9;

    final double totalBias = tsbComponent +
        sleepComponent +
        weatherComponent +
        moraleComponent +
        loyaltyComponent;

    return totalBias.clamp(-3.5, 3.5);
  }

  /// Ocenia dopasowanie pogody do atrybutów `rainResistance` i `heatTolerance`.
  double computeWeatherFitComponent({
    required WeatherCondition weatherCondition,
    required double temperatureCelsius,
    required int rainResistance,
    required int heatTolerance,
  }) {
    final double rainNorm = (rainResistance.clamp(0, 100) - 55) / 45.0;
    final double heatNorm = (heatTolerance.clamp(0, 100) - 55) / 45.0;

    switch (weatherCondition) {
      case WeatherCondition.heavyStorm:
        return rainNorm * 0.90;
      case WeatherCondition.lightRain:
        return rainNorm * 0.55;
      case WeatherCondition.crosswindGale:
        // Chłodny wiatr boczny lekko premiuje odpornych na trudne warunki
        return (rainNorm * 0.30) + (temperatureCelsius < 10.0 ? rainNorm * 0.20 : 0.0);
      case WeatherCondition.extremeHeat:
        return heatNorm * 0.90;
      case WeatherCondition.sunny:
        if (temperatureCelsius >= 28.0) {
          return heatNorm * 0.55;
        }
        return 0.15;
      case WeatherCondition.overcast:
        return 0.05;
    }
  }

  /// Wylicza mapę wag prawdopodobieństwa dla każdej oceny od -5 do +5.
  Map<int, double> computeConditionWeights(DayConditionDrawInputs inputs) {
    final double mean = computeReadinessBias(inputs);
    const double sigma = 1.85;
    const double twoSigmaSq = 2.0 * sigma * sigma;

    final Map<int, double> weights = <int, double>{};
    for (int score = minScore; score <= maxScore; score++) {
      final double diff = score - mean;
      final double gaussian = math.exp(-(diff * diff) / twoSigmaSq);
      // Minimalna waga bazowa gwarantuje, że skrajne dni (-5 / +5) są zawsze możliwe, choć rzadkie.
      weights[score] = math.max(0.005, gaussian);
    }
    return weights;
  }

  /// Losuje dyspozycję dnia [-5, +5] metodą koła ruletki ważonej.
  int drawConditionScore(DayConditionDrawInputs inputs) {
    final Map<int, double> weights = computeConditionWeights(inputs);
    double totalWeight = 0.0;
    for (final double w in weights.values) {
      totalWeight += w;
    }

    if (totalWeight <= 0.0) return 0;

    double roll = _random.nextDouble() * totalWeight;
    for (int score = minScore; score <= maxScore; score++) {
      roll -= weights[score] ?? 0.0;
      if (roll <= 0.0) {
        return score;
      }
    }
    return maxScore;
  }

  /// Tworzy początkowy stan dyspozycji dnia przed startem etapu.
  ///
  /// Jeśli kolarz należy do gracza i odbył rozgrzewkę na trenażerze (`didTrainerWarmup`),
  /// jego dyspozycja jest odkryta od razu na starcie. W przeciwnym razie (rywale oraz
  /// kolarze gracza bez rozgrzewki) pozostaje ukryta pod znakiem `?`.
  RiderDayConditionState createInitialStageState({
    required String riderId,
    required DayConditionDrawInputs inputs,
  }) {
    final int score = drawConditionScore(inputs);
    final bool revealedAtStart = inputs.isPlayerRider && inputs.didTrainerWarmup;

    return RiderDayConditionState(
      riderId: riderId,
      actualCondition: score,
      isRevealed: revealedAtStart,
      isPlayerRider: inputs.isPlayerRider,
      didTrainerWarmup: inputs.didTrainerWarmup,
      revealedAtDistanceMeters: revealedAtStart ? 0.0 : null,
      revealedAtHeartRateBpm: null,
    );
  }

  /// Wygodny wrapper tworzący stan startowy bezpośrednio z obiektu [Rider].
  RiderDayConditionState createInitialStageStateForRider({
    required Rider rider,
    required WeatherCondition weatherCondition,
    double? temperatureCelsius,
    double sleepQuality = 0.75,
    bool isPlayerRider = false,
    bool didTrainerWarmup = false,
  }) {
    final DayConditionDrawInputs inputs = DayConditionDrawInputs.fromRider(
      rider: rider,
      weatherCondition: weatherCondition,
      temperatureCelsius: temperatureCelsius,
      sleepQuality: sleepQuality,
      isPlayerRider: isPlayerRider,
      didTrainerWarmup: didTrainerWarmup,
    );
    return createInitialStageState(riderId: rider.id, inputs: inputs);
  }

  /// Aktualizuje stan odkrycia dyspozycji dnia podczas etapu.
  ///
  /// Odkrycie następuje wyłącznie wtedy, gdy kolarz znajduje się na pierwszym podjeździe
  /// (`isOnClimb` lub nachylenie >= [kFirstClimbMinGradientPercent]) i jego aktualne
  /// tętno przekroczy próg tlenowy `lt1HeartRateBpm`.
  RiderDayConditionState evaluateRevealOnClimb({
    required RiderDayConditionState currentState,
    required int currentHeartRateBpm,
    required int lt1HeartRateBpm,
    required double currentGradientPercent,
    required double distanceCoveredMeters,
    bool isOnClimb = false,
  }) {
    if (currentState.isRevealed) {
      return currentState;
    }

    final bool climbingNow =
        isOnClimb || currentGradientPercent >= kFirstClimbMinGradientPercent;
    if (!climbingNow) {
      return currentState;
    }

    if (currentHeartRateBpm > lt1HeartRateBpm) {
      return currentState.copyWith(
        isRevealed: true,
        revealedAtDistanceMeters: distanceCoveredMeters,
        revealedAtHeartRateBpm: currentHeartRateBpm,
      );
    }

    return currentState;
  }

  /// Przeciążenie sprawdzające odkrycie dyspozycji bezpośrednio z progiem LT1 z [Rider.labProfile].
  RiderDayConditionState evaluateRevealForRider({
    required Rider rider,
    required RiderDayConditionState currentState,
    required int currentHeartRateBpm,
    required double currentGradientPercent,
    required double distanceCoveredMeters,
    bool isOnClimb = false,
  }) {
    return evaluateRevealOnClimb(
      currentState: currentState,
      currentHeartRateBpm: currentHeartRateBpm,
      lt1HeartRateBpm: rider.labProfile.lt1HeartRateBpm,
      currentGradientPercent: currentGradientPercent,
      distanceCoveredMeters: distanceCoveredMeters,
      isOnClimb: isOnClimb,
    );
  }
}
