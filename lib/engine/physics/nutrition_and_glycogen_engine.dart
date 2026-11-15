import 'dart:math' as math;
import '../../models/rider/lactate_and_lab_profile.dart';
import '../../models/rider/rider_physiology.dart';

/// Stan metabolizmu energetycznego, zapasów glikogenu i nawodnienia kolarza.
class NutritionState {
  /// Aktualna ilość zmagazynowanego glikogenu mięśniowego i wątrobowego [g]
  final double currentGlycogenGrams;

  /// Maksymalna fizjologiczna pojemność glikogenowa kolarza [g] (np. 500 - 700g)
  final double maxGlycogenGrams;

  /// Poziom nawodnienia organizmu w procentach [0.0% - 100.0%]
  final double hydrationPercent;

  /// Węglowodany znajdujące się aktualnie w żołądku/jelitach oczekujące na wchłonięcie [g]
  final double stomachCarbsGrams;

  /// Płyny znajdujące się w żołądku oczekujące na wchłonięcie [ml]
  final double stomachFluidMl;

  /// Czy kolarz przeżywa kryzys głodowy / odcięcie z braku węglowodanów ("bonk" / głód zjazdowy)
  final bool isBonking;

  /// Czy kolarz doświadczył odcięcia / kryzysu w trakcie etapu
  bool get isBonked => isBonking || bonkCount > 0;

  /// Łączna liczba kryzysów głodowych (bonk) w trakcie etapu
  final int bonkCount;

  /// Łączny czas spędzony w stanie głodu zjazdowego w sekundach [s]
  final double timeInBonkSeconds;

  /// Łączna ilość węglowodanów spożytych w trakcie etapu [g]
  final double totalCarbsConsumedGrams;

  /// Łączna ilość płynów wypitych w trakcie etapu [ml]
  final double totalFluidConsumedMl;

  /// Łączna ilość węglowodanów spalonych w trakcie etapu [g]
  final double totalCarbsBurnedGrams;

  /// Łączna ilość płynów utraconych z potem w trakcie etapu [ml]
  final double totalFluidSweatedMl;

  const NutritionState({
    required this.currentGlycogenGrams,
    required this.maxGlycogenGrams,
    this.hydrationPercent = 100.0,
    this.stomachCarbsGrams = 0.0,
    this.stomachFluidMl = 0.0,
    this.isBonking = false,
    this.bonkCount = 0,
    this.timeInBonkSeconds = 0.0,
    this.totalCarbsConsumedGrams = 0.0,
    this.totalFluidConsumedMl = 0.0,
    this.totalCarbsBurnedGrams = 0.0,
    this.totalFluidSweatedMl = 0.0,
  });

  /// Początkowy stan przedstartowy (pełen glikogen i 100% nawodnienia)
  factory NutritionState.initial(RiderPhysiology physiology) {
    final double capacity = math.max(300.0, physiology.glycogenCapacityGrams);
    return NutritionState(
      currentGlycogenGrams: capacity,
      maxGlycogenGrams: capacity,
      hydrationPercent: 100.0,
      stomachCarbsGrams: 20.0, // Lekki posiłek przedstartowy w żołądku
      stomachFluidMl: 250.0,
      isBonking: false,
      bonkCount: 0,
      timeInBonkSeconds: 0.0,
    );
  }

  /// Procentowe naładowanie magazynów glikogenu (0.0% - 100.0%)
  double get glycogenPercent {
    if (maxGlycogenGrams <= 0.0) return 0.0;
    return ((currentGlycogenGrams / maxGlycogenGrams) * 100.0).clamp(0.0, 100.0);
  }

  /// Czy zapasy glikogenu są na krytycznie niskim poziomie (< 50g)
  bool get isCriticallyDepleted => currentGlycogenGrams < NutritionAndGlycogenEngine.bonkThresholdGrams;

  /// Mnożnik mocy progowej FTP uwzględniający kryzys głodowy (0.65 w stanie bonk, 1.0 w normie)
  double get effectiveFtpMultiplier => isBonking ? (1.0 - NutritionAndGlycogenEngine.bonkFtpPenalty) : 1.0;

  NutritionState copyWith({
    double? currentGlycogenGrams,
    double? maxGlycogenGrams,
    double? hydrationPercent,
    double? stomachCarbsGrams,
    double? stomachFluidMl,
    bool? isBonking,
    int? bonkCount,
    double? timeInBonkSeconds,
    double? totalCarbsConsumedGrams,
    double? totalFluidConsumedMl,
    double? totalCarbsBurnedGrams,
    double? totalFluidSweatedMl,
  }) {
    return NutritionState(
      currentGlycogenGrams: currentGlycogenGrams ?? this.currentGlycogenGrams,
      maxGlycogenGrams: maxGlycogenGrams ?? this.maxGlycogenGrams,
      hydrationPercent: hydrationPercent ?? this.hydrationPercent,
      stomachCarbsGrams: stomachCarbsGrams ?? this.stomachCarbsGrams,
      stomachFluidMl: stomachFluidMl ?? this.stomachFluidMl,
      isBonking: isBonking ?? this.isBonking,
      bonkCount: bonkCount ?? this.bonkCount,
      timeInBonkSeconds: timeInBonkSeconds ?? this.timeInBonkSeconds,
      totalCarbsConsumedGrams: totalCarbsConsumedGrams ?? this.totalCarbsConsumedGrams,
      totalFluidConsumedMl: totalFluidConsumedMl ?? this.totalFluidConsumedMl,
      totalCarbsBurnedGrams: totalCarbsBurnedGrams ?? this.totalCarbsBurnedGrams,
      totalFluidSweatedMl: totalFluidSweatedMl ?? this.totalFluidSweatedMl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentGlycogenGrams': currentGlycogenGrams,
      'maxGlycogenGrams': maxGlycogenGrams,
      'hydrationPercent': hydrationPercent,
      'stomachCarbsGrams': stomachCarbsGrams,
      'stomachFluidMl': stomachFluidMl,
      'isBonking': isBonking,
      'bonkCount': bonkCount,
      'timeInBonkSeconds': timeInBonkSeconds,
      'totalCarbsConsumedGrams': totalCarbsConsumedGrams,
      'totalFluidConsumedMl': totalFluidConsumedMl,
      'totalCarbsBurnedGrams': totalCarbsBurnedGrams,
      'totalFluidSweatedMl': totalFluidSweatedMl,
    };
  }

  factory NutritionState.fromJson(Map<String, dynamic> json) {
    return NutritionState(
      currentGlycogenGrams: (json['currentGlycogenGrams'] as num).toDouble(),
      maxGlycogenGrams: (json['maxGlycogenGrams'] as num).toDouble(),
      hydrationPercent: (json['hydrationPercent'] as num).toDouble(),
      stomachCarbsGrams: (json['stomachCarbsGrams'] as num).toDouble(),
      stomachFluidMl: (json['stomachFluidMl'] as num).toDouble(),
      isBonking: json['isBonking'] as bool? ?? false,
      bonkCount: (json['bonkCount'] as num?)?.toInt() ?? 0,
      timeInBonkSeconds: (json['timeInBonkSeconds'] as num?)?.toDouble() ?? 0.0,
      totalCarbsConsumedGrams: (json['totalCarbsConsumedGrams'] as num?)?.toDouble() ?? 0.0,
      totalFluidConsumedMl: (json['totalFluidConsumedMl'] as num?)?.toDouble() ?? 0.0,
      totalCarbsBurnedGrams: (json['totalCarbsBurnedGrams'] as num?)?.toDouble() ?? 0.0,
      totalFluidSweatedMl: (json['totalFluidSweatedMl'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'NutritionState(glycogen: ${currentGlycogenGrams.toStringAsFixed(1)}/${maxGlycogenGrams.toStringAsFixed(0)}g '
        '(${glycogenPercent.toStringAsFixed(1)}%), '
        'hydration: ${hydrationPercent.toStringAsFixed(1)}%, '
        'stomach: ${stomachCarbsGrams.toStringAsFixed(1)}g carbs / ${stomachFluidMl.toStringAsFixed(0)}ml, '
        'bonking: $isBonking)';
  }
}

/// Wynik kroku symulacji metabolizmu energetycznego kolarza.
class NutritionUpdateResult {
  /// Zaktualizowany stan gospodarki energetycznej
  final NutritionState newState;

  /// Węglowodany spalone w tym kroku [g]
  final double carbsBurnedGrams;

  /// Węglowodany wchłonięte z jelit do krwiobiegu/glikogenu w tym kroku [g]
  final double carbsAbsorbedGrams;

  /// Płyn utracony z potem w tym kroku [ml]
  final double fluidLostMl;

  /// Płyn nawadniający wchłonięty z żołądka w tym kroku [ml]
  final double fluidAbsorbedMl;

  /// Efektywna moc progowa FTP kolarza po uwzględnieniu stanu bonk [W]
  final double effectiveFtpWatts;

  /// Czy w tym kroku kolarz znajdował się w stanie odcięcia glikogenowego (bonk)
  final bool isBonking;

  const NutritionUpdateResult({
    required this.newState,
    required this.carbsBurnedGrams,
    required this.carbsAbsorbedGrams,
    required this.fluidLostMl,
    required this.fluidAbsorbedMl,
    required this.effectiveFtpWatts,
    required this.isBonking,
  });

  @override
  String toString() {
    return 'NutritionUpdateResult(burned: ${carbsBurnedGrams.toStringAsFixed(3)}g, '
        'absorbed: ${carbsAbsorbedGrams.toStringAsFixed(3)}g, '
        'sweat: ${fluidLostMl.toStringAsFixed(1)}ml, '
        'effFTP: ${effectiveFtpWatts.toStringAsFixed(1)}W, '
        'bonk: $isBonking)';
  }
}

/// Silnik energetyczny kolarza modelujący zużycie glikogenu,
/// kinetykę wchłaniania węglowodanów z jelit, nawodnienie oraz kryzys głodowy (bonk).
class NutritionAndGlycogenEngine {
  NutritionAndGlycogenEngine._();

  /// Próg aktywacji stanu głodu zjazdowego (bonk) [g glikogenu]
  static const double bonkThresholdGrams = 50.0;

  /// Próg wyjścia ze stanu bonk po dostarczeniu energii [g glikogenu]
  static const double bonkExitThresholdGrams = 80.0;

  /// Drastyczny spadek FTP w stanie bonk (35%)
  static const double bonkFtpPenalty = 0.35;

  /// Węglowodany w jednym żelu energetycznym [g] (np. Maurten/SiS/Enervit)
  static const double gelCarbsGrams = 30.0;

  /// Węglowodany w jednym batonie energetycznym [g]
  static const double barCarbsGrams = 45.0;

  /// Objętość standardowego bidonu kolarskiego [ml]
  static const double bidonVolumeMl = 500.0;

  /// Węglowodany w standardowym bidonie z izotonikiem [g] (mieszanka węglowodanowa)
  static const double defaultBidonCarbsGrams = 25.0;

  /// Maksymalny fizjologiczny limit wchłaniania jelitowego węglowodanów w gramach na godzinę [g/h]
  /// (Dla transportu dwutorowego glukoza + fruktoza SGLT1 + GLUT5: ok. 90-110 g/h)
  static const double maxGutAbsorptionRateGramsPerHour = 100.0;

  /// Maksymalna szybkość wchłaniania węglowodanów na sekundę [g/s] (~0.0278 g/s)
  static const double maxGutAbsorptionRateGramsPerSecond = maxGutAbsorptionRateGramsPerHour / 3600.0;

  /// Maksymalna szybkość opróżniania żołądka z płynów [ml/h] (~800 - 1000 ml/h)
  static const double maxStomachFluidAbsorptionMlPerHour = 900.0;

  /// Akcja: Spożycie żelu energetycznego (+30g węglowodanów o natychmiastowej biodostępności).
  static NutritionState consumeGel(NutritionState state) {
    return state.copyWith(
      stomachCarbsGrams: state.stomachCarbsGrams + gelCarbsGrams,
      totalCarbsConsumedGrams: state.totalCarbsConsumedGrams + gelCarbsGrams,
    );
  }

  /// Akcja: Spożycie batona energetycznego (+45g węglowodanów o wolniejszym uwalnianiu).
  static NutritionState consumeBar(NutritionState state) {
    return state.copyWith(
      stomachCarbsGrams: state.stomachCarbsGrams + barCarbsGrams,
      totalCarbsConsumedGrams: state.totalCarbsConsumedGrams + barCarbsGrams,
    );
  }

  /// Akcja: Wypicie zawartości bidonu (domyślnie 500ml płynu + opcjonalne węglowodany izotonika).
  static NutritionState drinkBidon(
    NutritionState state, {
    double fluidMl = bidonVolumeMl,
    double carbsGrams = defaultBidonCarbsGrams,
  }) {
    return state.copyWith(
      stomachFluidMl: state.stomachFluidMl + fluidMl,
      stomachCarbsGrams: state.stomachCarbsGrams + carbsGrams,
      totalFluidConsumedMl: state.totalFluidConsumedMl + fluidMl,
      totalCarbsConsumedGrams: state.totalCarbsConsumedGrams + carbsGrams,
    );
  }

  /// Oblicza tempo spalania węglowodanów w gramach na sekundę [g/s].
  ///
  /// Jeśli dostępny jest profil laboratoryjny [labProfile], tempo spalania węglowodanów
  /// jest precyzyjnie modulowane przez kinetykę VLaMax oraz strefy metaboliczne LT1/LT2.
  /// W przeciwnym razie stosowany jest ogólny model wykładniczy wg % FTP:
  /// - Strefa 1 (< 55% FTP): ~0.020 g/s (~70 g/h) - dominacja utleniania kwasów tłuszczowych
  /// - Strefa 2 (55-75% FTP): ~0.035 g/s (~125 g/h)
  /// - Strefa 3 (76-90% FTP): ~0.050 g/s (~180 g/h)
  /// - Strefa 4 (100% FTP): ~0.070 g/s (~250 g/h) - punkt zwrotny (crossover)
  /// - Strefa 5/6 (>115% FTP): ~0.100 - 0.150 g/s (~360 - 540 g/h) - glikoliza beztlenowa
  static double calculateCarbBurnRateGramsPerSecond({
    required double currentPowerWatts,
    required double ftpWatts,
    LactateAndLabProfile? labProfile,
  }) {
    if (currentPowerWatts <= 0.0) {
      // Podstawowy metabolizm spoczynkowy na rowerze (~15 g/h)
      return 0.0042;
    }

    if (labProfile != null) {
      return labProfile.estimateCarbBurnRateGramsPerSecond(currentPowerWatts).clamp(0.0042, 0.200);
    }

    final double safeFtp = math.max(100.0, ftpWatts);
    final double intensityRatio = (currentPowerWatts / safeFtp).clamp(0.0, 2.5);

    // Wykładniczy wzrost utleniania węglowodanów w funkcji względnej intensywności
    // Wzór: burnRate = base * exp(k * (P / FTP))
    const double baseRate = 0.0125; // g/s
    const double exponentFactor = 1.72;

    final double burnRateGramsPerSecond = baseRate * math.exp(exponentFactor * intensityRatio);
    return burnRateGramsPerSecond.clamp(0.0042, 0.200); // Max ~720 g/h w maksymalnym sprincie
  }

  /// Oblicza tempo utraty płynów z potem w mililitrach na sekundę [ml/s].
  ///
  /// Zależy od generowanej mocy mechanicznej (rozpraszanie ciepła), temperatury otoczenia
  /// oraz sprawności mechanicznej (Gross Efficiency - im wyższa sprawność, tym mniej ciepła odpadowego).
  static double calculateSweatRateMlPerSecond({
    required double currentPowerWatts,
    required double temperatureCelsius,
    required double riderWeightKg,
    double grossEfficiencyPercent = 22.0,
  }) {
    // Sprawność kolarza to ok. 20-25%, reszta energii metabolicznej zamienia się w ciepło odpadowe
    final double heatFraction = ((100.0 - grossEfficiencyPercent) / 78.0).clamp(0.85, 1.25);
    final double powerFactor = (currentPowerWatts / 250.0).clamp(0.2, 3.0) * heatFraction;
    final double tempFactor = math.max(0.6, (temperatureCelsius + 5.0) / 25.0);

    // Średnia utrata w ml na godzinę
    final double sweatMlPerHour = 450.0 * powerFactor * tempFactor * (riderWeightKg / 70.0);
    return (sweatMlPerHour / 3600.0).clamp(0.05, 0.65); // 180ml/h do 2340ml/h
  }

  /// Główna metoda aktualizująca metabolizm energetyczny kolarza w kroku czasowym [timeStepSeconds].
  ///
  /// Przebieg:
  /// 1. Wyliczenie zużycia węglowodanów w oparciu o strefę mocy (% FTP).
  /// 2. Opróżnianie żołądka i wchłanianie jelitowe węglowodanów z limitem 90-110 g/h.
  /// 3. Aktualizacja poziomu glikogenu: Glycogen = Glycogen - Burned + Absorbed.
  /// 4. Weryfikacja stanu głodu zjazdowego (bonk < 50g -> spadek FTP o 35%).
  /// 5. Utrata płynów z potem i nawadnianie z żołądka -> aktualizacja `hydrationPercent`.
  static NutritionUpdateResult update({
    required NutritionState state,
    required double currentPowerWatts,
    required RiderPhysiology physiology,
    double temperatureCelsius = 22.0,
    double timeStepSeconds = 1.0,
  }) {
    if (timeStepSeconds <= 0.0) {
      return NutritionUpdateResult(
        newState: state,
        carbsBurnedGrams: 0.0,
        carbsAbsorbedGrams: 0.0,
        fluidLostMl: 0.0,
        fluidAbsorbedMl: 0.0,
        effectiveFtpWatts: physiology.ftpWatts.toDouble() * state.effectiveFtpMultiplier,
        isBonking: state.isBonking,
      );
    }

    final double baseFtp = physiology.ftpWatts.toDouble();

    // 1. Spalanie węglowodanów w oparciu o zadaną moc i profil metaboliczny kolarza
    final double carbBurnRate = calculateCarbBurnRateGramsPerSecond(
      currentPowerWatts: currentPowerWatts,
      ftpWatts: baseFtp,
      labProfile: physiology.labProfile,
    );
    final double carbsBurned = carbBurnRate * timeStepSeconds;

    // 2. Wchłanianie węglowodanów z żołądka z limitem jelitowym (ok. 90-110g/h)
    final double maxAbsorbable = maxGutAbsorptionRateGramsPerSecond * timeStepSeconds;
    final double carbsAbsorbed = math.min(state.stomachCarbsGrams, maxAbsorbable);
    final double newStomachCarbs = math.max(0.0, state.stomachCarbsGrams - carbsAbsorbed);

    // 3. Bilans glikogenu w magazynach kolarza
    final double rawGlycogen = state.currentGlycogenGrams - carbsBurned + carbsAbsorbed;
    final double newGlycogen = rawGlycogen.clamp(0.0, state.maxGlycogenGrams);

    // 4. Weryfikacja stanu kryzysu głodowego (bonk):
    bool isBonking = state.isBonking;
    int bonkCount = state.bonkCount;
    double timeInBonk = state.timeInBonkSeconds;

    if (!isBonking && newGlycogen < bonkThresholdGrams) {
      // Aktywacja odcięcia glikogenowego (bonk) poniżej 50g
      isBonking = true;
      bonkCount++;
    } else if (isBonking) {
      timeInBonk += timeStepSeconds;
      // Wyjście z bonka następuje dopiero po odbudowaniu co najmniej 80g glikogenu
      if (newGlycogen >= bonkExitThresholdGrams) {
        isBonking = false;
      }
    }

    // 5. Gospodarka wodno-elektrolitowa i pot (uwzględniająca sprawność cieplną)
    final double sweatRate = calculateSweatRateMlPerSecond(
      currentPowerWatts: currentPowerWatts,
      temperatureCelsius: temperatureCelsius,
      riderWeightKg: physiology.weightKg,
      grossEfficiencyPercent: physiology.labProfile?.grossEfficiencyPercent ?? 22.0,
    );
    final double fluidLost = sweatRate * timeStepSeconds;

    // Wchłanianie płynów z żołądka
    const double maxFluidAbsorptionPerSecond = maxStomachFluidAbsorptionMlPerHour / 3600.0;
    final double fluidAbsorbed = math.min(
      state.stomachFluidMl,
      maxFluidAbsorptionPerSecond * timeStepSeconds,
    );
    final double newStomachFluid = math.max(0.0, state.stomachFluidMl - fluidAbsorbed);

    // Wpływ na hydrationPercent: utrata 1% masy ciała (ok. 700ml dla 70kg) to spadek nawodnienia o ok. 1.0%
    final double bodyWaterEquivMl = physiology.weightKg * 10.0; // ~700ml = 1%
    final double netFluidChangeMl = fluidAbsorbed - fluidLost;
    final double hydrationDeltaPercent = (netFluidChangeMl / bodyWaterEquivMl);
    final double newHydration = (state.hydrationPercent + hydrationDeltaPercent).clamp(50.0, 100.0);

    // Efektywny FTP po uwzględnieniu stanu bonk (spadek o 35%)
    final double effectiveFtp = isBonking ? (baseFtp * (1.0 - bonkFtpPenalty)) : baseFtp;

    final newState = NutritionState(
      currentGlycogenGrams: newGlycogen,
      maxGlycogenGrams: state.maxGlycogenGrams,
      hydrationPercent: newHydration,
      stomachCarbsGrams: newStomachCarbs,
      stomachFluidMl: newStomachFluid,
      isBonking: isBonking,
      bonkCount: bonkCount,
      timeInBonkSeconds: timeInBonk,
      totalCarbsConsumedGrams: state.totalCarbsConsumedGrams,
      totalFluidConsumedMl: state.totalFluidConsumedMl,
      totalCarbsBurnedGrams: state.totalCarbsBurnedGrams + carbsBurned,
      totalFluidSweatedMl: state.totalFluidSweatedMl + fluidLost,
    );

    return NutritionUpdateResult(
      newState: newState,
      carbsBurnedGrams: carbsBurned,
      carbsAbsorbedGrams: carbsAbsorbed,
      fluidLostMl: fluidLost,
      fluidAbsorbedMl: fluidAbsorbed,
      effectiveFtpWatts: effectiveFtp,
      isBonking: isBonking,
    );
  }
}

