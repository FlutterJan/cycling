import 'dart:math' as math;
import '../../models/rider/rider_physiology.dart';

/// Stan zapasu energii beztlenowej kolarza (W' Balance) w trakcie wyścigu.
class WPrimeState {
  /// Aktualny dostępny zapas pracy beztlenowej w dżulach [J] (0.0 do [maxWPrimeJoules])
  final double currentWPrimeJoules;

  /// Maksymalna pojemność beztlenowa kolarza w dżulach [J] (z profilu fizjologicznego)
  final double maxWPrimeJoules;

  /// Czy kolarz złapał "odcięcie beztlenowe" (W' wyczerpane do 0)
  final bool isExhausted;

  /// Licznik ile razy w trakcie wyścigu/etapu kolarz całkowicie wyzerował W'
  final int exhaustionCount;

  /// Czas spędzony w stanie całkowitego odcięcia beztlenowego w sekundach [s]
  final double timeInExhaustionSeconds;

  /// Ostatnia wyliczona stała czasowa regeneracji tau [s]
  final double lastTauSeconds;

  const WPrimeState({
    required this.currentWPrimeJoules,
    required this.maxWPrimeJoules,
    this.isExhausted = false,
    this.exhaustionCount = 0,
    this.timeInExhaustionSeconds = 0.0,
    this.lastTauSeconds = 300.0,
  });

  /// Początkowy stan z pełnym zapasem W'
  factory WPrimeState.initial(RiderPhysiology physiology) {
    final double maxW = math.max(1000.0, physiology.wPrimeJoules.toDouble());
    return WPrimeState(
      currentWPrimeJoules: maxW,
      maxWPrimeJoules: maxW,
      isExhausted: false,
      exhaustionCount: 0,
      timeInExhaustionSeconds: 0.0,
      lastTauSeconds: 300.0,
    );
  }

  /// Procentowe naładowanie baterii beztlenowej (0.0% - 100.0%)
  double get wPrimePercentage {
    if (maxWPrimeJoules <= 0.0) return 0.0;
    return ((currentWPrimeJoules / maxWPrimeJoules) * 100.0).clamp(0.0, 100.0);
  }

  /// Ułamek naładowania baterii beztlenowej (0.0 do 1.0)
  double get wPrimeRatio {
    if (maxWPrimeJoules <= 0.0) return 0.0;
    return (currentWPrimeJoules / maxWPrimeJoules).clamp(0.0, 1.0);
  }

  /// Zużyta dotychczas energia beztlenowa w dżulach [J]
  double get depletedJoules => math.max(0.0, maxWPrimeJoules - currentWPrimeJoules);

  /// Czy zapas W' jest w pełni naładowany (>= 99.9%)
  bool get isFullyCharged => currentWPrimeJoules >= (maxWPrimeJoules - 1.0);

  WPrimeState copyWith({
    double? currentWPrimeJoules,
    double? maxWPrimeJoules,
    bool? isExhausted,
    int? exhaustionCount,
    double? timeInExhaustionSeconds,
    double? lastTauSeconds,
  }) {
    return WPrimeState(
      currentWPrimeJoules: currentWPrimeJoules ?? this.currentWPrimeJoules,
      maxWPrimeJoules: maxWPrimeJoules ?? this.maxWPrimeJoules,
      isExhausted: isExhausted ?? this.isExhausted,
      exhaustionCount: exhaustionCount ?? this.exhaustionCount,
      timeInExhaustionSeconds: timeInExhaustionSeconds ?? this.timeInExhaustionSeconds,
      lastTauSeconds: lastTauSeconds ?? this.lastTauSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentWPrimeJoules': currentWPrimeJoules,
      'maxWPrimeJoules': maxWPrimeJoules,
      'isExhausted': isExhausted,
      'exhaustionCount': exhaustionCount,
      'timeInExhaustionSeconds': timeInExhaustionSeconds,
      'lastTauSeconds': lastTauSeconds,
    };
  }

  factory WPrimeState.fromJson(Map<String, dynamic> json) {
    return WPrimeState(
      currentWPrimeJoules: (json['currentWPrimeJoules'] as num).toDouble(),
      maxWPrimeJoules: (json['maxWPrimeJoules'] as num).toDouble(),
      isExhausted: json['isExhausted'] as bool? ?? false,
      exhaustionCount: (json['exhaustionCount'] as num?)?.toInt() ?? 0,
      timeInExhaustionSeconds: (json['timeInExhaustionSeconds'] as num?)?.toDouble() ?? 0.0,
      lastTauSeconds: (json['lastTauSeconds'] as num?)?.toDouble() ?? 300.0,
    );
  }

  @override
  String toString() {
    return 'WPrimeState(${currentWPrimeJoules.toStringAsFixed(0)}/${maxWPrimeJoules.toStringAsFixed(0)}J '
        '(${wPrimePercentage.toStringAsFixed(1)}%), '
        'exhausted: $isExhausted, count: $exhaustionCount)';
  }
}

/// Wynik aktualizacji stanu W' w danym kroku symulacji.
class WPrimeUpdateResult {
  /// Zaktualizowany stan baterii beztlenowej
  final WPrimeState newState;

  /// Rzeczywista moc wyjściowa kolarza po uwzględnieniu ewentualnego limitu odcięcia beztlenowego [W]
  final double actualPowerWatts;

  /// Zmiana zasobu W' w danym kroku [J] (ujemna = zużycie, dodatnia = regeneracja)
  final double deltaWPrimeJoules;

  /// Wartość stałej czasowej regeneracji tau zastosowanej w tym kroku [s] (null jeśli trwał wydatek)
  final double? tauSeconds;

  /// Czy kolarz w tym kroku doznał przymusowego obcięcia mocy z powodu odcięcia beztlenowego
  final bool wasPowerCapped;

  const WPrimeUpdateResult({
    required this.newState,
    required this.actualPowerWatts,
    required this.deltaWPrimeJoules,
    required this.tauSeconds,
    required this.wasPowerCapped,
  });

  @override
  String toString() {
    return 'WPrimeUpdateResult(actualP: ${actualPowerWatts.toStringAsFixed(1)}W, '
        'deltaW\': ${deltaWPrimeJoules.toStringAsFixed(1)}J, '
        'capped: $wasPowerCapped, '
        '${newState.toString()})';
  }
}

/// Zaawansowany silnik bilansu beztlenowego W' kolarza (W' Balance).
///
/// Implementuje model Skiba et al. (2012, 2015):
/// 1. Gdy P > CP (FTP):
///    Zużycie beztlenowe zachodzi liniowo: dW'/dt = -(P - CP)
/// 2. Gdy P < CP (FTP):
///    Regeneracja zachodzi wykładniczo:
///    W'(t + dt) = W'_max - (W'_max - W'(t)) * exp(-dt / tau)
///    gdzie stała czasowa tau zależy od deficytu (CP - P) oraz parametrów fizjologicznych kolarza
///    (VO2max i recoveryRate).
/// 3. Gdy W' <= 0:
///    Kolarz łapie "odcięcie beztlenowe" (anaerobic blow-up), a jego moc maksymalna zostaje
///    przymusowo zredukowana poniżej FTP do momentu zregenerowania bufora bezpieczeństwa.
class WPrimeBalanceEngine {
  WPrimeBalanceEngine._();

  /// Ułamek FTP, do którego przymusowo redukowana jest maksymalna moc w stanie odcięcia beztlenowego (85% FTP)
  static const double exhaustionPowerCapRatio = 0.85;

  /// Próg regeneracji W' wymagany do wyjścia ze stanu odcięcia beztlenowego (10% pojemności W'_max)
  static const double exhaustionExitThresholdRatio = 0.10;

  /// Oblicza stałą czasową regeneracji tau [s] wg modelu Skiba et al.,
  /// ze skalowaniem fizjologicznym w oparciu o VO2max i recoveryRate kolarza.
  ///
  /// Oryginalny wzór empiryczny Skiby (2012):
  /// tau_base = 546 * exp(-0.01 * (CP - P)) + 316
  ///
  /// Kolarze światowej klasy o wybitnym pułapie tlenowym (VO2max > 80 ml/kg/min)
  /// oraz wysokim wskaźniku regeneracji resyntezują fosfokreatynę (PCr) znacznie szybciej.
  static double calculateTauSeconds({
    required double cpWatts,
    required double currentPowerWatts,
    required double vo2Max,
    required double recoveryRate,
  }) {
    // Różnica między mocą progową a aktualną mocą kolarza
    final double powerDeficit = math.max(0.0, cpWatts - currentPowerWatts);

    // Bazowa stała Skiby (2012)
    final double tauBase = (546.0 * math.exp(-0.01 * powerDeficit)) + 316.0;

    // Współczynnik sprawności tlenowej kolarza (odniesienie: VO2max 70.0 ml/kg/min, recoveryRate 1.0)
    final double safeVo2 = math.max(45.0, vo2Max);
    final double safeRecoveryRate = math.max(0.5, recoveryRate);

    final double vo2Factor = math.pow(safeVo2 / 70.0, 0.75).toDouble();
    final double recoveryEfficiency = vo2Factor * safeRecoveryRate;

    // Efektywna stała czasowa (im wyższa sprawność, tym mniejsze tau = szybsza regeneracja)
    final double tauEffective = tauBase / math.max(0.5, recoveryEfficiency);

    // Realistyczne ograniczenia fizjologiczne: tau od 160s (~2.7 min) do 1200s (20 min)
    return tauEffective.clamp(160.0, 1200.0);
  }

  /// Główna metoda aktualizująca stan baterii beztlenowej kolarza w kroku czasowym [timeStepSeconds].
  ///
  /// Parametry:
  /// - [state]: aktualny stan [WPrimeState]
  /// - [targetPowerWatts]: planowana moc generowana przez kolarza [W]
  /// - [physiology]: profil fizjologiczny kolarza ([RiderPhysiology])
  /// - [timeStepSeconds]: czas trwania kroku symulacji (domyślnie 1.0 sekunda)
  ///
  /// Zwraca [WPrimeUpdateResult] z nowym stanem i rzeczywistą dopuszczalną mocą.
  static WPrimeUpdateResult update({
    required WPrimeState state,
    required double targetPowerWatts,
    required RiderPhysiology physiology,
    double timeStepSeconds = 1.0,
  }) {
    if (timeStepSeconds <= 0.0) {
      return WPrimeUpdateResult(
        newState: state,
        actualPowerWatts: targetPowerWatts,
        deltaWPrimeJoules: 0.0,
        tauSeconds: null,
        wasPowerCapped: false,
      );
    }

    final double cpWatts = math.max(50.0, physiology.ftpWatts.toDouble());
    final double maxWPrime = math.max(1000.0, physiology.wPrimeJoules.toDouble());

    bool isExhausted = state.isExhausted;
    int exhaustionCount = state.exhaustionCount;
    double timeInExhaustion = state.timeInExhaustionSeconds;
    bool wasPowerCapped = false;
    double actualPower = math.max(0.0, targetPowerWatts);

    // 1. Obsługa stanu odcięcia beztlenowego (exhaustion):
    // Jeśli kolarz jest w stanie odcięcia, jego moc maksymalna zostaje ścięta poniżej FTP (85% CP)
    final double exhaustionCapWatts = cpWatts * exhaustionPowerCapRatio;
    if (isExhausted) {
      timeInExhaustion += timeStepSeconds;
      if (actualPower > exhaustionCapWatts) {
        actualPower = exhaustionCapWatts;
        wasPowerCapped = true;
      }
    }

    double currentW = state.currentWPrimeJoules.clamp(0.0, maxWPrime);
    double deltaW = 0.0;
    double? tauApplied;

    // 2. Dynamika bilansu W':
    if (actualPower > cpWatts) {
      // --- FAZA WYDATKU BEZTLENOWEGO (P > CP) ---
      // Liniowe zużycie energii ponadprogowej: deltaW = -(P - CP) * dt
      final double excessPower = actualPower - cpWatts;
      final double joulesExpended = excessPower * timeStepSeconds;
      deltaW = -joulesExpended;

      currentW = math.max(0.0, currentW - joulesExpended);

      // Sprawdzenie czy nastąpiło nowe odcięcie beztlenowe
      if (currentW <= 0.0 && !isExhausted) {
        isExhausted = true;
        exhaustionCount++;
        wasPowerCapped = true;
        // Natychmiastowe obcięcie mocy w momencie wyczerpania
        actualPower = math.min(actualPower, exhaustionCapWatts);
      }
    } else if (actualPower < cpWatts) {
      // --- FAZA REGENERACJI BEZTLENOWEGO (P < CP) ---
      // Wykładnicza resynteza: W'(t + dt) = W'_max - (W'_max - W'(t)) * exp(-dt / tau)
      final double tau = calculateTauSeconds(
        cpWatts: cpWatts,
        currentPowerWatts: actualPower,
        vo2Max: physiology.vo2Max,
        recoveryRate: physiology.recoveryRate,
      );
      tauApplied = tau;

      final double depletedCurrent = maxWPrime - currentW;
      if (depletedCurrent > 0.0) {
        final double decayFactor = math.exp(-timeStepSeconds / tau);
        final double depletedNext = depletedCurrent * decayFactor;
        final double newW = (maxWPrime - depletedNext).clamp(0.0, maxWPrime);
        deltaW = newW - currentW;
        currentW = newW;
      }

      // Weryfikacja warunku wyjścia ze stanu odcięcia beztlenowego:
      // Kolarz musi odbudować co najmniej 10% zapasu W'max, aby znów móc przyspieszać
      if (isExhausted) {
        final double recoveryThreshold = maxWPrime * exhaustionExitThresholdRatio;
        if (currentW >= recoveryThreshold) {
          isExhausted = false;
        }
      }
    } else {
      // P == CP: stan zrównoważony (brak zużycia i brak regeneracji)
      deltaW = 0.0;
    }

    final newState = WPrimeState(
      currentWPrimeJoules: currentW,
      maxWPrimeJoules: maxWPrime,
      isExhausted: isExhausted,
      exhaustionCount: exhaustionCount,
      timeInExhaustionSeconds: timeInExhaustion,
      lastTauSeconds: tauApplied ?? state.lastTauSeconds,
    );

    return WPrimeUpdateResult(
      newState: newState,
      actualPowerWatts: actualPower,
      deltaWPrimeJoules: deltaW,
      tauSeconds: tauApplied,
      wasPowerCapped: wasPowerCapped,
    );
  }

  /// Wylicza maksymalną dopuszczalną moc, jaką kolarz może wygenerować w danym stanie W'.
  ///
  /// Jeśli kolarz jest w stanie odcięcia beztlenowego, zwraca moc zredukowaną poniżej FTP ([exhaustionPowerCapRatio] * CP).
  /// W przeciwnym razie zwraca maksymalną moc zadaną lub szczytową kolarza.
  static double getEffectiveMaxPower({
    required WPrimeState state,
    required RiderPhysiology physiology,
    double requestedMaxPowerWatts = 1500.0,
  }) {
    final double cpWatts = physiology.ftpWatts.toDouble();
    if (state.isExhausted || state.currentWPrimeJoules <= 0.0) {
      return cpWatts * exhaustionPowerCapRatio;
    }
    return requestedMaxPowerWatts;
  }
}

