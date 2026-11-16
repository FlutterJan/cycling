import 'dart:math' as math;

import '../../models/rider/rider_physiology.dart';

/// Klasyfikacja odporności kolarza na kumulację zmęczenia w 3. tygodniu Grand Touru.
enum GrandTourFatigueResilienceTier {
  /// Specjalista od 3-tygodniowych Grand Tourów (spadek FTP 2–3% do etapu 21).
  grandTourSpecialist,

  /// Kolarz etapowy / uniwersalny (spadek FTP ~3.5–8.5% do etapu 21).
  stageRaceAllRounder,

  /// Specjalista od wyścigów 1-dniowych / klasyków (spadek FTP 9–14% do etapu 21).
  oneDayClassicSpecialist,
}

/// Wynik modelu kumulacji zmęczenia w 3. tygodniu Grand Touru (etapy 14–21).
class GrandTourThirdWeekFatigueResult {
  /// Numer etapu w Grand Tourze (1–21).
  final int stageNumber;

  /// Współczynnik regeneracji fizjologicznej kolarza (`RiderPhysiology.recoveryRate`).
  final double recoveryRate;

  /// Postęp w 3. tygodniu (0.0 dla etapów <= 14, 1.0 dla etapu >= 21).
  final double thirdWeekProgress;

  /// Spadek mocy progowej FTP / MLSS jako ułamek (np. 0.025 = 2.5%).
  final double thresholdPowerDecayRatio;

  /// Spadek maksymalnego pułapu tlenowego VO2max jako ułamek (np. 0.022 = 2.2%).
  final double vo2MaxDecayRatio;

  /// Spadek pojemności i resyntezy glikogenu wątrobowego jako ułamek (np. 0.032 = 3.2%).
  final double hepaticGlycogenDecayRatio;

  /// Kategoria odporności na zmęczenie 3. tygodnia.
  final GrandTourFatigueResilienceTier resilienceTier;

  const GrandTourThirdWeekFatigueResult({
    required this.stageNumber,
    required this.recoveryRate,
    required this.thirdWeekProgress,
    required this.thresholdPowerDecayRatio,
    required this.vo2MaxDecayRatio,
    required this.hepaticGlycogenDecayRatio,
    required this.resilienceTier,
  });

  /// Mnożnik zachowanej mocy progowej FTP (np. 0.975 dla spadku 2.5%).
  double get thresholdPowerRetentionFactor =>
      (1.0 - thresholdPowerDecayRatio).clamp(0.75, 1.0);

  /// Mnożnik zachowanego pułapu tlenowego VO2max.
  double get vo2MaxRetentionFactor =>
      (1.0 - vo2MaxDecayRatio).clamp(0.75, 1.0);

  /// Mnożnik zachowanego glikogenu wątrobowego.
  double get hepaticGlycogenRetentionFactor =>
      (1.0 - hepaticGlycogenDecayRatio).clamp(0.70, 1.0);

  /// Procentowy spadek mocy progowej FTP [0.0 - 100.0%].
  double get thresholdPowerDecayPercent => thresholdPowerDecayRatio * 100.0;

  /// Procentowy spadek VO2max [0.0 - 100.0%].
  double get vo2MaxDecayPercent => vo2MaxDecayRatio * 100.0;

  /// Procentowy spadek glikogenu wątrobowego [0.0 - 100.0%].
  double get hepaticGlycogenDecayPercent => hepaticGlycogenDecayRatio * 100.0;

  /// Zwraca skorygowaną moc progową FTP [W].
  int applyToFtpWatts(int baseFtpWatts) {
    if (baseFtpWatts <= 0) return 0;
    return math.max(1, (baseFtpWatts * thresholdPowerRetentionFactor).round());
  }

  /// Zwraca skorygowany pułap tlenowy VO2max [ml/kg/min].
  double applyToVo2Max(double baseVo2Max) {
    if (baseVo2Max <= 0.0) return 0.0;
    return baseVo2Max * vo2MaxRetentionFactor;
  }

  /// Zwraca skorygowaną pojemność glikogenu [g] przy uwzględnieniu udziału
  /// glikogenu wątrobowego (~18–22% całkowitego zapasu) oraz ogólnej degradacji resyntezy.
  double applyToGlycogenCapacity(double baseGlycogenCapacityGrams) {
    if (baseGlycogenCapacityGrams <= 0.0) return 0.0;
    // Glikogen wątrobowy stanowi ~20% puli ustrojowej, ale w 3. tygodniu ogranicza też
    // dostępność glukozy dla pracy mięśniowej i układu nerwowego.
    final double effectiveRetention =
        1.0 - (hepaticGlycogenDecayRatio * 0.72);
    return baseGlycogenCapacityGrams * effectiveRetention.clamp(0.75, 1.0);
  }

  /// Zwraca zmodyfikowaną kopię `RiderPhysiology` z nałożonym zmęczeniem 3. tygodnia.
  RiderPhysiology applyToPhysiology(RiderPhysiology physiology) {
    return physiology.copyWith(
      ftpWatts: applyToFtpWatts(physiology.ftpWatts),
      vo2Max: double.parse(
        applyToVo2Max(physiology.vo2Max).toStringAsFixed(2),
      ),
      glycogenCapacityGrams: double.parse(
        applyToGlycogenCapacity(physiology.glycogenCapacityGrams)
            .toStringAsFixed(1),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageNumber': stageNumber,
      'recoveryRate': recoveryRate,
      'thirdWeekProgress': thirdWeekProgress,
      'thresholdPowerDecayRatio': thresholdPowerDecayRatio,
      'vo2MaxDecayRatio': vo2MaxDecayRatio,
      'hepaticGlycogenDecayRatio': hepaticGlycogenDecayRatio,
      'resilienceTier': resilienceTier.name,
    };
  }

  factory GrandTourThirdWeekFatigueResult.fromJson(Map<String, dynamic> json) {
    return GrandTourThirdWeekFatigueResult(
      stageNumber: (json['stageNumber'] as num).toInt(),
      recoveryRate: (json['recoveryRate'] as num).toDouble(),
      thirdWeekProgress: (json['thirdWeekProgress'] as num).toDouble(),
      thresholdPowerDecayRatio:
          (json['thresholdPowerDecayRatio'] as num).toDouble(),
      vo2MaxDecayRatio: (json['vo2MaxDecayRatio'] as num).toDouble(),
      hepaticGlycogenDecayRatio:
          (json['hepaticGlycogenDecayRatio'] as num).toDouble(),
      resilienceTier: GrandTourFatigueResilienceTier.values.firstWhere(
        (e) => e.name == json['resilienceTier'],
        orElse: () => GrandTourFatigueResilienceTier.stageRaceAllRounder,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GrandTourThirdWeekFatigueResult &&
        other.stageNumber == stageNumber &&
        other.recoveryRate == recoveryRate &&
        other.thirdWeekProgress == thirdWeekProgress &&
        other.thresholdPowerDecayRatio == thresholdPowerDecayRatio &&
        other.vo2MaxDecayRatio == vo2MaxDecayRatio &&
        other.hepaticGlycogenDecayRatio == hepaticGlycogenDecayRatio &&
        other.resilienceTier == resilienceTier;
  }

  @override
  int get hashCode => Object.hash(
        stageNumber,
        recoveryRate,
        thirdWeekProgress,
        thresholdPowerDecayRatio,
        vo2MaxDecayRatio,
        hepaticGlycogenDecayRatio,
        resilienceTier,
      );
}

/// Model kumulacji zmęczenia w 3-tygodniowym Grand Tourze (etapy 14–21).
///
/// Odwzorowuje fizjologiczną degradację maksymalnego pułapu tlenowego (VO2max),
/// mocy progowej (FTP) oraz zapasów glikogenu wątrobowego między etapem 14 a 21
/// w zależności od indywidualnego parametru `recoveryRate` kolarza:
/// - Specjaliści od Grand Tourów (`recoveryRate >= 1.25`): tracą jedynie 2–3% mocy progowej.
/// - Kolarze etapowi / uniwersalni (`0.96 <= recoveryRate < 1.25`): tracą ~3.3–8.9%.
/// - Kolarze 1-dniowi / klasykowcy (`recoveryRate <= 0.95`): tracą 9–14% mocy progowej.
class GrandTourThirdWeekFatigueDecay {
  /// Etap graniczny początku 3. tygodnia (brak spadku z tytułu 3. tygodnia dla <= 14).
  static const int thirdWeekStartStage = 14;

  /// Etap finałowy Grand Touru (maksymalna kumulacja zmęczenia).
  static const int thirdWeekEndStage = 21;

  /// Dolna granica fizjologiczna `recoveryRate` w modelu.
  static const double minRecoveryRate = 0.80;

  /// Górna granica fizjologiczna `recoveryRate` w modelu.
  static const double maxRecoveryRate = 1.40;

  /// Minimalny spadek mocy progowej dla elitarnego specjalisty GT na etapie 21 (2.0%).
  static const double minThresholdDecayAtStage21 = 0.020;

  /// Maksymalny spadek mocy progowej dla kolarza 1-dniowego na etapie 21 (14.0%).
  static const double maxThresholdDecayAtStage21 = 0.140;

  const GrandTourThirdWeekFatigueDecay();

  /// Klasyfikuje kolarza do kategorii odporności na 3. tydzień Grand Touru.
  static GrandTourFatigueResilienceTier classifyResilience(double recoveryRate) {
    if (recoveryRate >= 1.25) {
      return GrandTourFatigueResilienceTier.grandTourSpecialist;
    }
    if (recoveryRate <= 0.95) {
      return GrandTourFatigueResilienceTier.oneDayClassicSpecialist;
    }
    return GrandTourFatigueResilienceTier.stageRaceAllRounder;
  }

  /// Wylicza docelowy spadek mocy progowej na etapie 21 w funkcji `recoveryRate`.
  static double maxThresholdDecayForRecoveryRate(double recoveryRate) {
    final double clamped =
        recoveryRate.clamp(minRecoveryRate, maxRecoveryRate);
    final double normalized =
        (clamped - minRecoveryRate) / (maxRecoveryRate - minRecoveryRate);
    // Krzywa potęgowa (wykładnik 1.8) odwzorowuje nieliniową odporność metaboliczną:
    // - recoveryRate 1.25..1.40 -> 2.0%..2.99%
    // - recoveryRate 0.80..0.95 -> 9.15%..14.0%
    final double vulnerability = math.pow(1.0 - normalized, 1.8).toDouble();
    return minThresholdDecayAtStage21 +
        (maxThresholdDecayAtStage21 - minThresholdDecayAtStage21) *
            vulnerability;
  }

  /// Oblicza skumulowane zmęczenie 3. tygodnia dla zadanego etapu i `recoveryRate`.
  ///
  /// [stageNumber] - numer etapu (1..21). Dla etapów <= 14 spadek wynosi 0%.
  /// [recoveryRate] - parametr regeneracji z `RiderPhysiology.recoveryRate`.
  /// [cumulativeStressMultiplier] - opcjonalny mnożnik intensywności wyścigu (domyślnie 1.0,
  ///   zakres 0.85..1.15 odzwierciedlający wyjątkowo ciężkie lub spokojne etapy alpejskie).
  static GrandTourThirdWeekFatigueResult evaluate({
    required int stageNumber,
    required double recoveryRate,
    double cumulativeStressMultiplier = 1.0,
  }) {
    final int safeStage = stageNumber.clamp(1, thirdWeekEndStage);
    final double safeStress = cumulativeStressMultiplier.clamp(0.85, 1.15);
    final GrandTourFatigueResilienceTier tier =
        classifyResilience(recoveryRate);

    if (safeStage <= thirdWeekStartStage) {
      return GrandTourThirdWeekFatigueResult(
        stageNumber: safeStage,
        recoveryRate: recoveryRate,
        thirdWeekProgress: 0.0,
        thresholdPowerDecayRatio: 0.0,
        vo2MaxDecayRatio: 0.0,
        hepaticGlycogenDecayRatio: 0.0,
        resilienceTier: tier,
      );
    }

    final double linearProgress = (safeStage - thirdWeekStartStage) /
        (thirdWeekEndStage - thirdWeekStartStage);
    // Lekkie przyspieszenie kumulacji w ostatnich dniach (etapy 18–21).
    final double progressCurve =
        math.pow(linearProgress.clamp(0.0, 1.0), 1.15).toDouble();

    final double stage21ThresholdDecay =
        maxThresholdDecayForRecoveryRate(recoveryRate) * safeStress;
    final double thresholdDecay =
        (stage21ThresholdDecay * progressCurve).clamp(0.0, 0.20);

    // VO2max spada proporcjonalnie do degradacji pułapu tlenowego i objętości osocza (~0.88x FTP).
    final double vo2MaxDecay = (thresholdDecay * 0.88).clamp(0.0, 0.18);

    // Glikogen wątrobowy ulega silniejszej degradacji przez chroniczny kortyzol i deficyt nocny (~1.22x FTP).
    final double hepaticGlycogenDecay =
        (thresholdDecay * 1.22).clamp(0.0, 0.25);

    return GrandTourThirdWeekFatigueResult(
      stageNumber: safeStage,
      recoveryRate: recoveryRate,
      thirdWeekProgress: progressCurve,
      thresholdPowerDecayRatio: thresholdDecay,
      vo2MaxDecayRatio: vo2MaxDecay,
      hepaticGlycogenDecayRatio: hepaticGlycogenDecay,
      resilienceTier: tier,
    );
  }

  /// Wygodna metoda oceniająca zmęczenie bezpośrednio na podstawie `RiderPhysiology`.
  static GrandTourThirdWeekFatigueResult evaluateForPhysiology({
    required RiderPhysiology physiology,
    required int stageNumber,
    double cumulativeStressMultiplier = 1.0,
  }) {
    return evaluate(
      stageNumber: stageNumber,
      recoveryRate: physiology.recoveryRate,
      cumulativeStressMultiplier: cumulativeStressMultiplier,
    );
  }

  /// Zwraca serię odczytów etap po etapie (domyślnie etapy 14..21) do wykresów i symulacji.
  static List<GrandTourThirdWeekFatigueResult> simulateStageProgression({
    required double recoveryRate,
    int startStage = thirdWeekStartStage,
    int endStage = thirdWeekEndStage,
    double cumulativeStressMultiplier = 1.0,
  }) {
    final int clampedStart = startStage.clamp(1, thirdWeekEndStage);
    final int clampedEnd = endStage.clamp(clampedStart, thirdWeekEndStage);
    return List<GrandTourThirdWeekFatigueResult>.generate(
      clampedEnd - clampedStart + 1,
      (index) => evaluate(
        stageNumber: clampedStart + index,
        recoveryRate: recoveryRate,
        cumulativeStressMultiplier: cumulativeStressMultiplier,
      ),
    );
  }
}
