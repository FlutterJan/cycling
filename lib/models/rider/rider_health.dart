enum InjuryType {
  clavicleFracture,
  wristFracture,
  kneeTendinitis,
  roadRash,
  concussion,
  muscleTear;

  String toJson() => name;

  static InjuryType fromJson(String value) {
    return InjuryType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => InjuryType.roadRash,
    );
  }
}

class Injury {
  final String name;
  final InjuryType type;
  final int daysRemaining;
  final bool trainingAllowed;

  const Injury({
    required this.name,
    required this.type,
    required this.daysRemaining,
    required this.trainingAllowed,
  });

  Injury copyWith({
    String? name,
    InjuryType? type,
    int? daysRemaining,
    bool? trainingAllowed,
  }) {
    return Injury(
      name: name ?? this.name,
      type: type ?? this.type,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      trainingAllowed: trainingAllowed ?? this.trainingAllowed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.toJson(),
      'daysRemaining': daysRemaining,
      'trainingAllowed': trainingAllowed,
    };
  }

  factory Injury.fromJson(Map<String, dynamic> json) {
    return Injury(
      name: json['name'] as String,
      type: InjuryType.fromJson(json['type'] as String),
      daysRemaining: (json['daysRemaining'] as num).toInt(),
      trainingAllowed: json['trainingAllowed'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Injury &&
        other.name == name &&
        other.type == type &&
        other.daysRemaining == daysRemaining &&
        other.trainingAllowed == trainingAllowed;
  }

  @override
  int get hashCode {
    return Object.hash(name, type, daysRemaining, trainingAllowed);
  }

  @override
  String toString() {
    return 'Injury($name, ${type.name}, remaining: ${daysRemaining}d, canTrain: $trainingAllowed)';
  }
}

class RiderHealth {
  final double acuteTrainingLoad; // ATL (Zmęczenie, np. okno 7-dniowe)
  final double chronicTrainingLoad; // CTL (Fitness / baza, np. okno 42-dniowe)
  final Injury? currentInjury;
  final String? currentIllness;

  const RiderHealth({
    required this.acuteTrainingLoad,
    required this.chronicTrainingLoad,
    this.currentInjury,
    this.currentIllness,
  });

  /// Wskaźnik świeżości i dyspozycji startowej (Training Stress Balance)
  /// TSB = CTL - ATL (+25 do +10: szczyt formy, -10 do -30: duże zmęczenie)
  double get trainingStressBalance => chronicTrainingLoad - acuteTrainingLoad;

  /// Ostre zmęczenie (synonim acuteTrainingLoad / ATL)
  double get acuteFatigueAtl => acuteTrainingLoad;

  /// Chroniczna forma bazowa (synonim chronicTrainingLoad / CTL)
  double get chronicFitnessCtl => chronicTrainingLoad;
  double get chronicTrainingLoadCtl => chronicTrainingLoad;

  /// Poziom morale i motywacji kolarza (0.0 - 1.0)
  double get morale {
    final tsb = trainingStressBalance;
    if (tsb > 15) return 0.95;
    if (tsb >= 0) return 0.85;
    if (tsb >= -20) return 0.72;
    return 0.55;
  }

  /// Liczba dni do zakończenia rekonwalescencji po kontuzji
  int get recoveryDaysRemaining => currentInjury?.daysRemaining ?? 0;

  /// Czy kolarz jest dopuszczony do rywalizacji w wyścigu
  bool get isFitToRace {
    if (currentIllness != null) return false;
    if (currentInjury != null && currentInjury!.daysRemaining > 0) return false;
    return true;
  }

  /// Czy kolarz może wykonywać treningi na trenażerze lub szosie
  bool get canTrain {
    if (currentInjury != null && !currentInjury!.trainingAllowed) return false;
    return true;
  }

  RiderHealth copyWith({
    double? acuteTrainingLoad,
    double? chronicTrainingLoad,
    Injury? currentInjury,
    bool clearInjury = false,
    String? currentIllness,
    bool clearIllness = false,
    double? chronicTrainingLoadCtl,
    double? acuteTrainingLoadAtl,
    double? morale,
  }) {
    return RiderHealth(
      acuteTrainingLoad: acuteTrainingLoadAtl ?? acuteTrainingLoad ?? this.acuteTrainingLoad,
      chronicTrainingLoad: chronicTrainingLoadCtl ?? chronicTrainingLoad ?? this.chronicTrainingLoad,
      currentInjury: clearInjury ? null : (currentInjury ?? this.currentInjury),
      currentIllness: clearIllness ? null : (currentIllness ?? this.currentIllness),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acuteTrainingLoad': acuteTrainingLoad,
      'chronicTrainingLoad': chronicTrainingLoad,
      'currentInjury': currentInjury?.toJson(),
      'currentIllness': currentIllness,
    };
  }

  factory RiderHealth.fromJson(Map<String, dynamic> json) {
    return RiderHealth(
      acuteTrainingLoad: (json['acuteTrainingLoad'] as num).toDouble(),
      chronicTrainingLoad: (json['chronicTrainingLoad'] as num).toDouble(),
      currentInjury: json['currentInjury'] != null
          ? Injury.fromJson(json['currentInjury'] as Map<String, dynamic>)
          : null,
      currentIllness: json['currentIllness'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderHealth &&
        other.acuteTrainingLoad == acuteTrainingLoad &&
        other.chronicTrainingLoad == chronicTrainingLoad &&
        other.currentInjury == currentInjury &&
        other.currentIllness == currentIllness;
  }

  @override
  int get hashCode {
    return Object.hash(
      acuteTrainingLoad,
      chronicTrainingLoad,
      currentInjury,
      currentIllness,
    );
  }

  @override
  String toString() {
    return 'RiderHealth(CTL: ${chronicTrainingLoad.toStringAsFixed(1)}, ATL: ${acuteTrainingLoad.toStringAsFixed(1)}, TSB: ${trainingStressBalance.toStringAsFixed(1)}, injury: ${currentInjury?.name}, illness: $currentIllness)';
  }
}

