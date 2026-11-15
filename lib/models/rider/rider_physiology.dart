import 'dart:math' as math;
import 'lactate_and_lab_profile.dart';

class RiderPhysiology {
  final double heightCm;
  final double weightKg;
  final double bodyFatPercentage;
  final int ftpWatts;
  final int wPrimeJoules;
  final double vo2Max;
  final int maxHr;
  final int restingHr;
  final int lactateThresholdHr;
  final double recoveryRate;
  final double glycogenCapacityGrams;
  final double form; // Forma kolarza (CTL - Chronic Training Load) (0.0 - 100.0)
  final double fatigue; // Zmęczenie kolarza (ATL - Acute Training Load) (0.0 - 100.0)
  final LactateAndLabProfile? labProfile;

  const RiderPhysiology({
    required this.heightCm,
    required this.weightKg,
    required this.bodyFatPercentage,
    required this.ftpWatts,
    required this.wPrimeJoules,
    required this.vo2Max,
    required this.maxHr,
    required this.restingHr,
    required this.lactateThresholdHr,
    required this.recoveryRate,
    required this.glycogenCapacityGrams,
    this.form = 75.0,
    this.fatigue = 25.0,
    this.labProfile,
  });

  /// Stosunek mocy progowej do masy ciała [W/kg]
  double get wattsPerKg {
    if (weightKg <= 0.0) return 0.0;
    return ftpWatts / weightKg;
  }

  /// Moc krytyczna (Critical Power / FTP) [W]
  int get criticalPowerWatts => ftpWatts;

  /// Całkowita powierzchnia ciała kolarza (BSA) ze wzoru DuBois [m^2]
  /// BSA = 0.007184 * (masa^0.425) * (wzrost^0.725)
  double get bodySurfaceAreaM2 {
    if (weightKg <= 0.0 || heightCm <= 0.0) return 0.0;
    return 0.007184 * math.pow(weightKg, 0.425) * math.pow(heightCm, 0.725);
  }

  /// Bazowa powierzchnia rzutu czołowego kolarza na rowerze (frontal area) [m^2]
  /// Szacowana jako ~26.8% całkowitego BSA kolarza w pozycji szosowej
  double get frontalAreaM2 {
    return bodySurfaceAreaM2 * 0.268;
  }

  /// Rezerwa tętna (Heart Rate Reserve) [bpm]
  int get heartRateReserve => maxHr - restingHr;

  /// Pełny profil laboratoryjny i mleczanowy (LT1, LT2/MLSS, VLaMax, VO2max, Gross Efficiency)
  LactateAndLabProfile get laboratoryProfile =>
      labProfile ?? LactateAndLabProfile.fromPhysiology(this);

  /// Aliasy dla parametrów Performance Management Chart (PMC)
  double get chronicTrainingLoadCtl => form;
  double get acuteFatigueAtl => fatigue;
  double get trainingStressBalanceTsb => form - fatigue;

  RiderPhysiology copyWith({
    double? heightCm,
    double? weightKg,
    double? bodyFatPercentage,
    int? ftpWatts,
    int? criticalPowerWatts,
    int? wPrimeJoules,
    double? vo2Max,
    int? maxHr,
    int? restingHr,
    int? lactateThresholdHr,
    double? recoveryRate,
    double? glycogenCapacityGrams,
    double? form,
    double? fatigue,
    double? chronicTrainingLoadCtl,
    double? acuteFatigueAtl,
    LactateAndLabProfile? labProfile,
  }) {
    return RiderPhysiology(
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      ftpWatts: criticalPowerWatts ?? ftpWatts ?? this.ftpWatts,
      wPrimeJoules: wPrimeJoules ?? this.wPrimeJoules,
      vo2Max: vo2Max ?? this.vo2Max,
      maxHr: maxHr ?? this.maxHr,
      restingHr: restingHr ?? this.restingHr,
      lactateThresholdHr: lactateThresholdHr ?? this.lactateThresholdHr,
      recoveryRate: recoveryRate ?? this.recoveryRate,
      glycogenCapacityGrams: glycogenCapacityGrams ?? this.glycogenCapacityGrams,
      form: chronicTrainingLoadCtl ?? form ?? this.form,
      fatigue: acuteFatigueAtl ?? fatigue ?? this.fatigue,
      labProfile: labProfile ?? this.labProfile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bodyFatPercentage': bodyFatPercentage,
      'ftpWatts': ftpWatts,
      'wPrimeJoules': wPrimeJoules,
      'vo2Max': vo2Max,
      'maxHr': maxHr,
      'restingHr': restingHr,
      'lactateThresholdHr': lactateThresholdHr,
      'recoveryRate': recoveryRate,
      'glycogenCapacityGrams': glycogenCapacityGrams,
      'form': form,
      'fatigue': fatigue,
      'labProfile': labProfile?.toJson(),
    };
  }

  factory RiderPhysiology.fromJson(Map<String, dynamic> json) {
    return RiderPhysiology(
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num).toDouble(),
      ftpWatts: (json['ftpWatts'] as num).toInt(),
      wPrimeJoules: (json['wPrimeJoules'] as num).toInt(),
      vo2Max: (json['vo2Max'] as num).toDouble(),
      maxHr: (json['maxHr'] as num).toInt(),
      restingHr: (json['restingHr'] as num).toInt(),
      lactateThresholdHr: (json['lactateThresholdHr'] as num).toInt(),
      recoveryRate: (json['recoveryRate'] as num).toDouble(),
      glycogenCapacityGrams: (json['glycogenCapacityGrams'] as num).toDouble(),
      form: (json['form'] as num?)?.toDouble() ?? 75.0,
      fatigue: (json['fatigue'] as num?)?.toDouble() ?? 25.0,
      labProfile: json['labProfile'] != null
          ? LactateAndLabProfile.fromJson(json['labProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderPhysiology &&
        other.heightCm == heightCm &&
        other.weightKg == weightKg &&
        other.bodyFatPercentage == bodyFatPercentage &&
        other.ftpWatts == ftpWatts &&
        other.wPrimeJoules == wPrimeJoules &&
        other.vo2Max == vo2Max &&
        other.maxHr == maxHr &&
        other.restingHr == restingHr &&
        other.lactateThresholdHr == lactateThresholdHr &&
        other.recoveryRate == recoveryRate &&
        other.glycogenCapacityGrams == glycogenCapacityGrams &&
        other.form == form &&
        other.fatigue == fatigue &&
        other.labProfile == labProfile;
  }

  @override
  int get hashCode {
    return Object.hash(
      heightCm,
      weightKg,
      bodyFatPercentage,
      ftpWatts,
      wPrimeJoules,
      vo2Max,
      maxHr,
      restingHr,
      lactateThresholdHr,
      recoveryRate,
      glycogenCapacityGrams,
      labProfile,
    );
  }

  @override
  String toString() {
    return 'RiderPhysiology(heightCm: $heightCm, weightKg: $weightKg, FTP: ${ftpWatts}W (${wattsPerKg.toStringAsFixed(2)} W/kg), W\': ${wPrimeJoules}J, VO2Max: $vo2Max, maxHr: $maxHr, VLaMax: ${laboratoryProfile.vlaMaxMmolLPerSec}mmol/l/s)';
  }
}
