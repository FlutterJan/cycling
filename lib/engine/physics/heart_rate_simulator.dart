import 'dart:math' as math;
import '../../models/rider/rider_physiology.dart';

/// Strefy tętna (Heart Rate Zones) oparte na progu mleczanowym LTHR / rezerwie tętna.
enum HeartRateZone {
  /// Strefa 1: Regeneracja aktywna (< 68% LTHR)
  zone1Recovery,

  /// Strefa 2: Wytrzymałość tlenowa (69% - 83% LTHR)
  zone2Aerobic,

  /// Strefa 3: Tempo (84% - 94% LTHR)
  zone3Tempo,

  /// Strefa 4: Próg beztlenowy / LTHR (95% - 105% LTHR)
  zone4Threshold,

  /// Strefa 5: Pułap tlenowy VO2max i beztlenowa (> 105% LTHR do Max HR)
  zone5Anaerobic;

  /// Numer strefy tętna (1 - 5)
  int get zoneNumber {
    switch (this) {
      case HeartRateZone.zone1Recovery:
        return 1;
      case HeartRateZone.zone2Aerobic:
        return 2;
      case HeartRateZone.zone3Tempo:
        return 3;
      case HeartRateZone.zone4Threshold:
        return 4;
      case HeartRateZone.zone5Anaerobic:
        return 5;
    }
  }

  /// Skrócona nazwa strefy (np. "Z4 Próg")
  String get shortName {
    switch (this) {
      case HeartRateZone.zone1Recovery:
        return 'Z1';
      case HeartRateZone.zone2Aerobic:
        return 'Z2';
      case HeartRateZone.zone3Tempo:
        return 'Z3';
      case HeartRateZone.zone4Threshold:
        return 'Z4';
      case HeartRateZone.zone5Anaerobic:
        return 'Z5';
    }
  }

  /// Czytelna etykieta strefy
  String get label {
    switch (this) {
      case HeartRateZone.zone1Recovery:
        return 'Regeneracja';
      case HeartRateZone.zone2Aerobic:
        return 'Tlenowa';
      case HeartRateZone.zone3Tempo:
        return 'Tempo';
      case HeartRateZone.zone4Threshold:
        return 'Próg LTHR';
      case HeartRateZone.zone5Anaerobic:
        return 'Beztlenowa / VO2';
    }
  }
}

/// Stan tętna kolarza w danym ułamku sekundy symulacji.
class HeartRateState {
  /// Aktualne tętno kolarza z uwzględnieniem inercji i opóźnienia fizjologicznego [bpm]
  final double currentHr;

  /// Teoretyczne tętno docelowe wynikające ze stałej mocy w stanie ustalonym [bpm]
  final double targetHr;

  /// Wartość składowej dryfu tętna (cardiac drift) z powodu odwodnienia i zmęczenia [bpm]
  final double cardiacDriftBpm;

  /// Skumulowana praca mechaniczna wykonana przez kolarza [kJ]
  final double accumulatedWorkKj;

  /// Ostatnio rejestrowana moc mechaniczna [W]
  final double lastPowerWatts;

  /// Zastosowana w ostatnim kroku stała czasowa inercji tau [s]
  final double lastTauSeconds;

  const HeartRateState({
    required this.currentHr,
    required this.targetHr,
    this.cardiacDriftBpm = 0.0,
    this.accumulatedWorkKj = 0.0,
    this.lastPowerWatts = 0.0,
    this.lastTauSeconds = 20.0,
  });

  /// Początkowy stan przedstartowy na linii startu (spokojne tętno spoczynkowe)
  factory HeartRateState.initial(RiderPhysiology physiology) {
    final double rest = math.max(35.0, physiology.restingHr.toDouble());
    return HeartRateState(
      currentHr: rest + 10.0, // Lekkie pobudzenie przedstartowe (+10 bpm)
      targetHr: rest + 10.0,
      cardiacDriftBpm: 0.0,
      accumulatedWorkKj: 0.0,
      lastPowerWatts: 0.0,
      lastTauSeconds: 20.0,
    );
  }

  /// Zaokrąglone tętno w uderzeniach na minutę [bpm] do prezentacji na liczniku HUD
  int get currentHrBpm => currentHr.round();

  /// Zaokrąglone tętno docelowe [bpm]
  int get targetHrBpm => targetHr.round();

  /// Wylicza procent tętna maksymalnego (% HRmax)
  double getHrPercentage(RiderPhysiology physiology) {
    if (physiology.maxHr <= 0) return 0.0;
    return ((currentHr / physiology.maxHr) * 100.0).clamp(0.0, 105.0);
  }

  /// Wylicza wskaźnik rezerwy tętna Karvonena (% HRR = (HR - HRrest) / (HRmax - HRrest))
  double getHrReservePercent(RiderPhysiology physiology) {
    final double reserve = (physiology.maxHr - physiology.restingHr).toDouble();
    if (reserve <= 0.0) return 0.0;
    return (((currentHr - physiology.restingHr) / reserve) * 100.0).clamp(0.0, 100.0);
  }

  /// Wyznacza aktualną strefę tętna w oparciu o LTHR kolarza
  HeartRateZone getZone(RiderPhysiology physiology) {
    final double lthr = physiology.lactateThresholdHr.toDouble();
    final double ratio = currentHr / lthr;

    if (ratio < 0.69) {
      return HeartRateZone.zone1Recovery;
    } else if (ratio < 0.84) {
      return HeartRateZone.zone2Aerobic;
    } else if (ratio < 0.95) {
      return HeartRateZone.zone3Tempo;
    } else if (ratio <= 1.05) {
      return HeartRateZone.zone4Threshold;
    } else {
      return HeartRateZone.zone5Anaerobic;
    }
  }

  HeartRateState copyWith({
    double? currentHr,
    double? targetHr,
    double? cardiacDriftBpm,
    double? accumulatedWorkKj,
    double? lastPowerWatts,
    double? lastTauSeconds,
  }) {
    return HeartRateState(
      currentHr: currentHr ?? this.currentHr,
      targetHr: targetHr ?? this.targetHr,
      cardiacDriftBpm: cardiacDriftBpm ?? this.cardiacDriftBpm,
      accumulatedWorkKj: accumulatedWorkKj ?? this.accumulatedWorkKj,
      lastPowerWatts: lastPowerWatts ?? this.lastPowerWatts,
      lastTauSeconds: lastTauSeconds ?? this.lastTauSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentHr': currentHr,
      'targetHr': targetHr,
      'cardiacDriftBpm': cardiacDriftBpm,
      'accumulatedWorkKj': accumulatedWorkKj,
      'lastPowerWatts': lastPowerWatts,
      'lastTauSeconds': lastTauSeconds,
    };
  }

  factory HeartRateState.fromJson(Map<String, dynamic> json) {
    return HeartRateState(
      currentHr: (json['currentHr'] as num).toDouble(),
      targetHr: (json['targetHr'] as num).toDouble(),
      cardiacDriftBpm: (json['cardiacDriftBpm'] as num?)?.toDouble() ?? 0.0,
      accumulatedWorkKj: (json['accumulatedWorkKj'] as num?)?.toDouble() ?? 0.0,
      lastPowerWatts: (json['lastPowerWatts'] as num?)?.toDouble() ?? 0.0,
      lastTauSeconds: (json['lastTauSeconds'] as num?)?.toDouble() ?? 20.0,
    );
  }

  @override
  String toString() {
    return 'HeartRateState(HR: ${currentHrBpm}bpm (target: ${targetHrBpm}bpm), '
        'drift: +${cardiacDriftBpm.toStringAsFixed(1)}bpm, '
        'tau: ${lastTauSeconds.toStringAsFixed(1)}s, '
        'work: ${accumulatedWorkKj.toStringAsFixed(0)}kJ)';
  }
}

/// Symulator fizjologii układu krążenia i tętna kolarza w czasie rzeczywistym.
///
/// Modeluje:
/// 1. Inercję układu krążenia (asymetryczne opóźnienie reakcji tętna 15-25s na wzrost i 25-35s na spadek).
/// 2. Gwałtowny skok tętna podczas zrywów beztlenowych i ataków w stronę `maxHr`.
/// 3. Dryf tętna (cardiac drift) wywołany odwodnieniem, wzrostem temperatury rdzenia ciała i zmęczeniem.
class HeartRateSimulator {
  HeartRateSimulator._();

  /// Podstawowa stała czasowa wzrostu tętna przy zwiększeniu mocy [s] (~18 sekund)
  static const double baseTauRiseSeconds = 18.0;

  /// Skrócona stała czasowa przy gwałtownych atakach beztlenowych (wyrzut adrenaliny) [s] (~12 sekund)
  static const double attackTauRiseSeconds = 12.0;

  /// Podstawowa stała czasowa spadku tętna przy zwalnianiu/regeneracji [s] (~30 sekund)
  static const double baseTauFallSeconds = 30.0;

  /// Maksymalny dopuszczalny dryf tętna w trakcie wyścigu [bpm]
  static const double maxCardiacDriftBpm = 22.0;

  /// Oblicza składową dryfu tętna (cardiac drift) w uderzeniach na minutę [bpm].
  ///
  /// Dryf tętna wynika z:
  /// - Spadku objętości wyrzutowej serca (SV) przy odwodnieniu organizmu (krew gęstnieje),
  /// - Wzrostu temperatury głębokiej ciała i rozszerzenia naczyń skórnych,
  /// - Długotrwałego zmęczenia układu sercowo-naczyniowego i wyczerpania glikogenu.
  static double calculateCardiacDriftBpm({
    required double hydrationPercent,
    required double accumulatedWorkKj,
    double ambientTemperatureCelsius = 22.0,
  }) {
    // 1. Wpływ odwodnienia: każdy 1% ubytku nawodnienia poniżej 100% podnosi tętno o ok. 2.5 - 3.5 bpm
    final double dehydrationDeficit = math.max(0.0, 100.0 - hydrationPercent);
    final double dehydrationDrift = dehydrationDeficit * 2.8;

    // 2. Wpływ skumulowanego zmęczenia (co 1000 kJ wykonanej pracy tętno dryfuje o ok. 1.8 bpm)
    final double fatigueDrift = (accumulatedWorkKj / 1000.0) * 1.8;

    // 3. Wpływ upału (temperatura otoczenia powyżej 24°C potęguje dryf termoregulacyjny)
    final double heatFactor = math.max(0.0, (ambientTemperatureCelsius - 24.0) * 0.45);

    final double totalDrift = dehydrationDrift + fatigueDrift + heatFactor;
    return totalDrift.clamp(0.0, maxCardiacDriftBpm);
  }

  /// Wylicza teoretyczne tętno docelowe w stanie ustalonym [HR_target] w bpm
  /// dla zadanej mocy [powerWatts] i profilu fizjologicznego [physiology].
  ///
  /// Zależność tętna od mocy:
  /// - Przy P = 0 W: tętno zbliża się do tętna spoczynkowego [restingHr].
  /// - W strefach tlenowych (P <= FTP): tętno rośnie liniowo do progu mleczanowego [lactateThresholdHr].
  /// - W strefach beztlenowych (P > FTP): tętno gwałtownie zbliża się asymptotycznie do [maxHr].
  static double calculateTargetHr({
    required double powerWatts,
    required RiderPhysiology physiology,
    double cardiacDriftBpm = 0.0,
  }) {
    final double restHr = physiology.restingHr.toDouble();
    final double lthr = physiology.lactateThresholdHr.toDouble();
    final double maxHr = physiology.maxHr.toDouble();
    final double ftp = math.max(100.0, physiology.ftpWatts.toDouble());

    if (powerWatts <= 0.0) {
      // Jazda na luzie / zjazd z wybiegu - tętno dąży do spoczynkowego + lekki bufor czujności
      return math.min(maxHr, restHr + 12.0 + cardiacDriftBpm);
    }

    final double intensityRatio = powerWatts / ftp;
    double baseHr;

    if (intensityRatio <= 1.0) {
      // Strefy 1-4 (P <= FTP): relacja liniowo-proporcjonalna między restHr a LTHR
      baseHr = restHr + (intensityRatio * (lthr - restHr));
    } else {
      // Strefy 5-7 (P > FTP): gwałtowny nieliniowy skok w stronę tętna maksymalnego (VO2max / beztlen)
      final double excessRatio = intensityRatio - 1.0;
      // Wzrost asymptotyczny: 1 - exp(-k * excess)
      final double sprintFactor = 1.0 - math.exp(-1.45 * excessRatio);
      baseHr = lthr + (sprintFactor * (maxHr - lthr));
    }

    // Dodanie dryfu tętna z ograniczeniem do Max HR
    final double targetWithDrift = baseHr + cardiacDriftBpm;
    return targetWithDrift.clamp(restHr, maxHr);
  }

  /// Główna metoda aktualizująca symulację tętna kolarza w czasie rzeczywistym.
  ///
  /// Parametry:
  /// - [state]: aktualny stan [HeartRateState]
  /// - [powerWatts]: moc generowana na korbie w tej sekundzie [W]
  /// - [physiology]: profil fizjologiczny kolarza ([RiderPhysiology])
  /// - [hydrationPercent]: aktualny poziom nawodnienia organizmu (domyślnie 100%)
  /// - [ambientTemperatureCelsius]: temperatura otoczenia (domyślnie 22°C)
  /// - [timeStepSeconds]: krok symulacji (domyślnie 1.0 sekunda)
  ///
  /// Zwraca zaktualizowany obiekt [HeartRateState] idealny do rysowania wykresów
  /// oraz wyświetlania na kolarzowym liczniku HUD w grze.
  static HeartRateState update({
    required HeartRateState state,
    required double powerWatts,
    required RiderPhysiology physiology,
    double hydrationPercent = 100.0,
    double ambientTemperatureCelsius = 22.0,
    double timeStepSeconds = 1.0,
  }) {
    if (timeStepSeconds <= 0.0) {
      return state;
    }

    // 1. Zwiększenie skumulowanej pracy mechanicznej: W = P * dt [kJ]
    final double workInStepKj = (powerWatts * timeStepSeconds) / 1000.0;
    final double newAccumulatedWork = state.accumulatedWorkKj + workInStepKj;

    // 2. Obliczenie dryfu tętna w oparciu o stan nawodnienia i zmęczenie
    final double driftBpm = calculateCardiacDriftBpm(
      hydrationPercent: hydrationPercent,
      accumulatedWorkKj: newAccumulatedWork,
      ambientTemperatureCelsius: ambientTemperatureCelsius,
    );

    // 3. Wyznaczenie tętna docelowego dla zadanej mocy
    final double targetHr = calculateTargetHr(
      powerWatts: powerWatts,
      physiology: physiology,
      cardiacDriftBpm: driftBpm,
    );

    // 4. Asymetryczna inercja układu krążenia (różne tau dla przyspieszenia i zwalniania):
    final double currentHr = state.currentHr;
    final double hrError = targetHr - currentHr;
    double tau;

    if (hrError >= 0.0) {
      // Tętno rośnie:
      // Jeśli kolarz wykonuje ostry atak (>125% FTP), wyrzut katecholamin przyspiesza reakcję tętna
      final bool isViolentAttack = powerWatts > (physiology.ftpWatts * 1.25);
      if (isViolentAttack) {
        tau = attackTauRiseSeconds;
      } else {
        tau = baseTauRiseSeconds;
      }
    } else {
      // Tętno spada (regeneracja / zwalnianie):
      // Kolarze o wybitnym recoveryRate obniżają tętno szybciej
      final double recoveryFactor = physiology.recoveryRate.clamp(0.6, 1.6);
      tau = baseTauFallSeconds / recoveryFactor;
    }

    // 5. Rozwiązanie analityczne filtra inercyjnego 1. rzędu:
    // HR(t + dt) = HR(t) + (1 - exp(-dt / tau)) * (HR_target - HR(t))
    final double decayFactor = 1.0 - math.exp(-timeStepSeconds / tau);
    final double rawNewHr = currentHr + (decayFactor * hrError);

    // Bezpieczne ograniczenie do przedziału fizjologicznego [restingHr, maxHr]
    final double maxHr = physiology.maxHr.toDouble();
    final double restHr = physiology.restingHr.toDouble();
    final double clampedHr = rawNewHr.clamp(restHr, maxHr);

    return HeartRateState(
      currentHr: clampedHr,
      targetHr: targetHr,
      cardiacDriftBpm: driftBpm,
      accumulatedWorkKj: newAccumulatedWork,
      lastPowerWatts: powerWatts,
      lastTauSeconds: tau,
    );
  }
}

