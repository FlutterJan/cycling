import 'dart:math' as math;

/// Klasa autokaru drużynowego w paddocku przed startem etapu.
enum TeamBusTier {
  /// Skromny bus/van drużyny kontynentalnej (2 trenażery, brak zaplecza).
  continentalMinibus,

  /// Standardowy autokar ProTeam (4 trenażery, podstawowe chłodzenie i kuchnia).
  proTeamTourBus,

  /// Flagowy autokar WorldTour (8 trenażerów direct-drive, fizjo, zamrażarka na kamizelki).
  worldTourFlagshipBus,

  /// Mobilne Centrum Dowodzenia Grand Tour (9 trenażerów Pro ERG, pełna krioterapia i kuchnia).
  grandTourCommandCenter;

  String toJson() => name;

  static TeamBusTier fromJson(String value) {
    return TeamBusTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TeamBusTier.worldTourFlagshipBus,
    );
  }

  String get displayNamePl {
    switch (this) {
      case TeamBusTier.continentalMinibus:
        return 'Bus Continental (2 stanowiska)';
      case TeamBusTier.proTeamTourBus:
        return 'Autokar ProTeam (4 stanowiska)';
      case TeamBusTier.worldTourFlagshipBus:
        return 'Flagowy Autokar WorldTour (8 stanowisk)';
      case TeamBusTier.grandTourCommandCenter:
        return 'Centrum Dowodzenia Grand Tour (9 stanowisk)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case TeamBusTier.continentalMinibus:
        return 'Continental Team Van (2 stations)';
      case TeamBusTier.proTeamTourBus:
        return 'ProTeam Tour Bus (4 stations)';
      case TeamBusTier.worldTourFlagshipBus:
        return 'WorldTour Flagship Bus (8 stations)';
      case TeamBusTier.grandTourCommandCenter:
        return 'Grand Tour Command Center (9 stations)';
    }
  }

  int get defaultTrainerSlots {
    switch (this) {
      case TeamBusTier.continentalMinibus:
        return 2;
      case TeamBusTier.proTeamTourBus:
        return 4;
      case TeamBusTier.worldTourFlagshipBus:
        return 8;
      case TeamBusTier.grandTourCommandCenter:
        return 9;
    }
  }

  int get prestigeStars {
    switch (this) {
      case TeamBusTier.continentalMinibus:
        return 1;
      case TeamBusTier.proTeamTourBus:
        return 3;
      case TeamBusTier.worldTourFlagshipBus:
        return 4;
      case TeamBusTier.grandTourCommandCenter:
        return 5;
    }
  }
}

/// Typ trenażera używanego pod markizą autokaru w paddocku.
enum SmartTrainerType {
  /// Rolki treningowe (brak trybu ERG, niski opór maksymalny).
  rollers,

  /// Trenażer direct-drive klasy standardowej (±1.5% dokładności).
  directDriveStandard,

  /// Trenażer Pro ERG Smart z precyzyjną symulacją profilu startu ITT (±0.5%).
  directDriveProErg;

  String toJson() => name;

  static SmartTrainerType fromJson(String value) {
    return SmartTrainerType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SmartTrainerType.directDriveProErg,
    );
  }

  String get displayNamePl {
    switch (this) {
      case SmartTrainerType.rollers:
        return 'Rolki treningowe';
      case SmartTrainerType.directDriveStandard:
        return 'Trenażer Direct-Drive';
      case SmartTrainerType.directDriveProErg:
        return 'Trenażer Smart Pro ERG';
    }
  }

  String get displayNameEn {
    switch (this) {
      case SmartTrainerType.rollers:
        return 'Training Rollers';
      case SmartTrainerType.directDriveStandard:
        return 'Direct-Drive Trainer';
      case SmartTrainerType.directDriveProErg:
        return 'Smart Pro ERG Trainer';
    }
  }

  /// Mnożnik jakości wykonania interwałów VO2 Priming na trenażerze.
  double get primingExecutionMultiplier {
    switch (this) {
      case SmartTrainerType.rollers:
        return 0.72;
      case SmartTrainerType.directDriveStandard:
        return 0.94;
      case SmartTrainerType.directDriveProErg:
        return 1.0;
    }
  }
}

/// Protokół rozgrzewki przedstartowej na trenażerze pod autobusem drużyny.
enum WarmupProtocolType {
  /// Brak rozgrzewki — zimny start, sztywność mięśni na pierwszych kilometrach.
  none,

  /// Lekka aktywacja 15 min Z1/Z2 na długie etapy płaskie ze startu wspólnego.
  lightSpinActivation,

  /// Progresywna rampa 25 min Z1–Z3 + 2 krótkie przyspieszenia (klasyki/pagórki).
  progressiveRamp,

  /// Protokół VO2 Priming (32 min) pod ITT/Prolog: +4.5% mocy na starcie ITT.
  vo2PrimingItt,

  /// Otwarcie pod ostry podjazd od kilometra 0 (20 min z blokiem progowym).
  mountainStartOpener,

  /// Aktywacja nerwowo-mięśniowa pod krótki prolog lub kryterium.
  sprintNeuromuscularPriming;

  String toJson() => name;

  static WarmupProtocolType fromJson(String value) {
    return WarmupProtocolType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WarmupProtocolType.progressiveRamp,
    );
  }

  String get displayNamePl {
    switch (this) {
      case WarmupProtocolType.none:
        return 'Brak rozgrzewki (Zimny start)';
      case WarmupProtocolType.lightSpinActivation:
        return 'Lekka aktywacja Z1–Z2 (15 min)';
      case WarmupProtocolType.progressiveRamp:
        return 'Progresywna rampa Z1–Z3 (25 min)';
      case WarmupProtocolType.vo2PrimingItt:
        return 'VO2 Priming ITT (+4.5% mocy na starcie)';
      case WarmupProtocolType.mountainStartOpener:
        return 'Otwarcie górskie KM 0 (20 min)';
      case WarmupProtocolType.sprintNeuromuscularPriming:
        return 'Aktywacja nerwowo-mięśniowa (18 min)';
    }
  }

  String get displayNameEn {
    switch (this) {
      case WarmupProtocolType.none:
        return 'No Warm-Up (Cold Start)';
      case WarmupProtocolType.lightSpinActivation:
        return 'Light Z1–Z2 Spin (15 min)';
      case WarmupProtocolType.progressiveRamp:
        return 'Progressive Ramp Z1–Z3 (25 min)';
      case WarmupProtocolType.vo2PrimingItt:
        return 'VO2 Priming ITT (+4.5% Start Power)';
      case WarmupProtocolType.mountainStartOpener:
        return 'Mountain KM 0 Opener (20 min)';
      case WarmupProtocolType.sprintNeuromuscularPriming:
        return 'Neuromuscular Sprint Priming (18 min)';
    }
  }
}

/// Strategia chłodzenia przedstartowego podczas rozgrzewki w paddocku.
enum CoolingStrategyType {
  /// Brak aktywnego chłodzenia.
  none,

  /// Wentylator stacjonarny i zimne ręczniki na kark.
  fanAndColdTowels,

  /// Kamizelka chłodząca Pre-Cooling Ice Vest + napój lodowy (slushie).
  preCoolingIceVest;

  String toJson() => name;

  static CoolingStrategyType fromJson(String value) {
    return CoolingStrategyType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CoolingStrategyType.fanAndColdTowels,
    );
  }

  String get displayNamePl {
    switch (this) {
      case CoolingStrategyType.none:
        return 'Brak chłodzenia';
      case CoolingStrategyType.fanAndColdTowels:
        return 'Wentylator + zimne ręczniki';
      case CoolingStrategyType.preCoolingIceVest:
        return 'Pre-Cooling Ice Vest + Slushie';
    }
  }

  String get displayNameEn {
    switch (this) {
      case CoolingStrategyType.none:
        return 'No Cooling';
      case CoolingStrategyType.fanAndColdTowels:
        return 'Fan + Cold Towels';
      case CoolingStrategyType.preCoolingIceVest:
        return 'Pre-Cooling Ice Vest + Slushie';
    }
  }

  /// Redukcja przyrostu temperatury głębokiej ciała (°C) przed startem.
  double get coreTempReductionCelsius {
    switch (this) {
      case CoolingStrategyType.none:
        return 0.0;
      case CoolingStrategyType.fanAndColdTowels:
        return 0.22;
      case CoolingStrategyType.preCoolingIceVest:
        return 0.55;
    }
  }
}

/// Status wykonania protokołu rozgrzewki przez kolarza.
enum WarmupCompletionStatus {
  pending,
  inProgress,
  completedOptimal,
  completedOverheated,
  abortedLateToStart;

  String toJson() => name;

  static WarmupCompletionStatus fromJson(String value) {
    return WarmupCompletionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WarmupCompletionStatus.pending,
    );
  }
}

/// Pojedynczy blok interwałowy w protokole rozgrzewki na trenażerze.
class WarmupIntervalStep {
  final int stepIndex;
  final String labelPl;
  final String labelEn;
  final int durationMinutes;
  final double targetFtpPercentMin;
  final double targetFtpPercentMax;
  final int targetCadenceRpm;
  final String zoneName;

  const WarmupIntervalStep({
    required this.stepIndex,
    required this.labelPl,
    required this.labelEn,
    required this.durationMinutes,
    required this.targetFtpPercentMin,
    required this.targetFtpPercentMax,
    required this.targetCadenceRpm,
    required this.zoneName,
  });

  double get averageFtpPercent =>
      (targetFtpPercentMin + targetFtpPercentMax) / 2.0;

  WarmupIntervalStep copyWith({
    int? stepIndex,
    String? labelPl,
    String? labelEn,
    int? durationMinutes,
    double? targetFtpPercentMin,
    double? targetFtpPercentMax,
    int? targetCadenceRpm,
    String? zoneName,
  }) {
    return WarmupIntervalStep(
      stepIndex: stepIndex ?? this.stepIndex,
      labelPl: labelPl ?? this.labelPl,
      labelEn: labelEn ?? this.labelEn,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      targetFtpPercentMin: targetFtpPercentMin ?? this.targetFtpPercentMin,
      targetFtpPercentMax: targetFtpPercentMax ?? this.targetFtpPercentMax,
      targetCadenceRpm: targetCadenceRpm ?? this.targetCadenceRpm,
      zoneName: zoneName ?? this.zoneName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepIndex': stepIndex,
      'labelPl': labelPl,
      'labelEn': labelEn,
      'durationMinutes': durationMinutes,
      'targetFtpPercentMin': targetFtpPercentMin,
      'targetFtpPercentMax': targetFtpPercentMax,
      'targetCadenceRpm': targetCadenceRpm,
      'zoneName': zoneName,
    };
  }

  factory WarmupIntervalStep.fromJson(Map<String, dynamic> json) {
    return WarmupIntervalStep(
      stepIndex: (json['stepIndex'] as num).toInt(),
      labelPl: json['labelPl'] as String,
      labelEn: json['labelEn'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      targetFtpPercentMin: (json['targetFtpPercentMin'] as num).toDouble(),
      targetFtpPercentMax: (json['targetFtpPercentMax'] as num).toDouble(),
      targetCadenceRpm: (json['targetCadenceRpm'] as num).toInt(),
      zoneName: json['zoneName'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WarmupIntervalStep &&
        other.stepIndex == stepIndex &&
        other.labelPl == labelPl &&
        other.labelEn == labelEn &&
        other.durationMinutes == durationMinutes &&
        other.targetFtpPercentMin == targetFtpPercentMin &&
        other.targetFtpPercentMax == targetFtpPercentMax &&
        other.targetCadenceRpm == targetCadenceRpm &&
        other.zoneName == zoneName;
  }

  @override
  int get hashCode => Object.hash(
        stepIndex,
        labelPl,
        labelEn,
        durationMinutes,
        targetFtpPercentMin,
        targetFtpPercentMax,
        targetCadenceRpm,
        zoneName,
      );
}

/// Pełna specyfikacja gotowego protokołu rozgrzewki na trenażerze.
class WarmupProtocolPreset {
  final WarmupProtocolType protocolType;
  final String namePl;
  final String nameEn;
  final String descriptionPl;
  final String descriptionEn;
  final int totalDurationMinutes;

  /// Premia mocy na starcie ITT (w %, np. 4.5 oznacza +4.5% mocy).
  final double ittStartPowerBonusPercent;

  /// Przyspieszenie kinetyki poboru tlenu (VO2 kinetics) w pierwszych 10 min (%).
  final double firstTenMinVo2KineticsBonusPercent;

  /// Premia reaktywności nerwowo-mięśniowej w pierwszym przyspieszeniu (%).
  final double neuromuscularSnapBonusPercent;

  /// Szacowany koszt glikogenu mięśniowego podczas rozgrzewki (g).
  final double glycogenCostGrams;

  /// Bazowy wzrost temperatury głębokiej ciała bez chłodzenia (°C).
  final double coreTempRiseCelsius;

  /// Procent W' zużyty tuż przed zjazdem z trenażera (0.0–15.0).
  final double wPrimePreSpendPercent;

  final List<WarmupIntervalStep> steps;

  const WarmupProtocolPreset({
    required this.protocolType,
    required this.namePl,
    required this.nameEn,
    required this.descriptionPl,
    required this.descriptionEn,
    required this.totalDurationMinutes,
    required this.ittStartPowerBonusPercent,
    required this.firstTenMinVo2KineticsBonusPercent,
    required this.neuromuscularSnapBonusPercent,
    required this.glycogenCostGrams,
    required this.coreTempRiseCelsius,
    required this.wPrimePreSpendPercent,
    required this.steps,
  });

  static const double vo2PrimingIttBonusPercent = 4.5;

  static List<WarmupProtocolPreset> get allPresets => [
        WarmupProtocolPreset.fromType(WarmupProtocolType.none),
        WarmupProtocolPreset.fromType(WarmupProtocolType.lightSpinActivation),
        WarmupProtocolPreset.fromType(WarmupProtocolType.progressiveRamp),
        WarmupProtocolPreset.fromType(WarmupProtocolType.vo2PrimingItt),
        WarmupProtocolPreset.fromType(WarmupProtocolType.mountainStartOpener),
        WarmupProtocolPreset.fromType(
          WarmupProtocolType.sprintNeuromuscularPriming,
        ),
      ];

  factory WarmupProtocolPreset.fromType(WarmupProtocolType type) {
    switch (type) {
      case WarmupProtocolType.none:
        return const WarmupProtocolPreset(
          protocolType: WarmupProtocolType.none,
          namePl: 'Brak rozgrzewki',
          nameEn: 'No Warm-Up',
          descriptionPl:
              'Zimny start bez trenażera. Oszczędza 100% glikogenu, ale obniża moc startową na ITT i pierwszych podjazdach.',
          descriptionEn:
              'Cold start without trainer. Preserves 100% glycogen, but penalizes initial ITT and early-climb power.',
          totalDurationMinutes: 0,
          ittStartPowerBonusPercent: -2.5,
          firstTenMinVo2KineticsBonusPercent: -3.0,
          neuromuscularSnapBonusPercent: -2.0,
          glycogenCostGrams: 0.0,
          coreTempRiseCelsius: 0.0,
          wPrimePreSpendPercent: 0.0,
          steps: [],
        );

      case WarmupProtocolType.lightSpinActivation:
        return const WarmupProtocolPreset(
          protocolType: WarmupProtocolType.lightSpinActivation,
          namePl: 'Lekka aktywacja Z1–Z2',
          nameEn: 'Light Z1–Z2 Activation',
          descriptionPl:
              '15 minut spokojnego kręcenia pod długie etapy płaskie ze startu wspólnego. Minimalny koszt energetyczny.',
          descriptionEn:
              '15 minutes of easy spinning before long flat mass-start stages. Minimal energy cost.',
          totalDurationMinutes: 15,
          ittStartPowerBonusPercent: 1.0,
          firstTenMinVo2KineticsBonusPercent: 1.2,
          neuromuscularSnapBonusPercent: 0.8,
          glycogenCostGrams: 12.0,
          coreTempRiseCelsius: 0.25,
          wPrimePreSpendPercent: 0.0,
          steps: [
            WarmupIntervalStep(
              stepIndex: 0,
              labelPl: 'Rozjazd tlenowy Z1',
              labelEn: 'Easy Aerobic Spin Z1',
              durationMinutes: 10,
              targetFtpPercentMin: 50,
              targetFtpPercentMax: 60,
              targetCadenceRpm: 92,
              zoneName: 'Z1',
            ),
            WarmupIntervalStep(
              stepIndex: 1,
              labelPl: 'Stabilizacja Z2 + wysoka kadencja',
              labelEn: 'Steady Z2 + High Cadence',
              durationMinutes: 5,
              targetFtpPercentMin: 65,
              targetFtpPercentMax: 74,
              targetCadenceRpm: 100,
              zoneName: 'Z2',
            ),
          ],
        );

      case WarmupProtocolType.progressiveRamp:
        return const WarmupProtocolPreset(
          protocolType: WarmupProtocolType.progressiveRamp,
          namePl: 'Progresywna rampa Z1–Z3',
          nameEn: 'Progressive Ramp Z1–Z3',
          descriptionPl:
              'Uniwersalna rozgrzewka 25 min pod klasyki i etapy pagórkowate z dwoma krótkimi otwarciami podprogowo-sprintowymi.',
          descriptionEn:
              'All-round 25 min warm-up for classics and hilly stages with two short sub-threshold openers.',
          totalDurationMinutes: 25,
          ittStartPowerBonusPercent: 2.6,
          firstTenMinVo2KineticsBonusPercent: 2.8,
          neuromuscularSnapBonusPercent: 2.5,
          glycogenCostGrams: 26.0,
          coreTempRiseCelsius: 0.50,
          wPrimePreSpendPercent: 2.5,
          steps: [
            WarmupIntervalStep(
              stepIndex: 0,
              labelPl: 'Rozgrzewka Z1–Z2',
              labelEn: 'Aerobic Ramp Z1–Z2',
              durationMinutes: 12,
              targetFtpPercentMin: 55,
              targetFtpPercentMax: 72,
              targetCadenceRpm: 94,
              zoneName: 'Z1-Z2',
            ),
            WarmupIntervalStep(
              stepIndex: 1,
              labelPl: 'Blok Tempo Z3',
              labelEn: 'Tempo Block Z3',
              durationMinutes: 6,
              targetFtpPercentMin: 80,
              targetFtpPercentMax: 88,
              targetCadenceRpm: 96,
              zoneName: 'Z3',
            ),
            WarmupIntervalStep(
              stepIndex: 2,
              labelPl: '2x30s Otwarcie Z5',
              labelEn: '2x30s Z5 Openers',
              durationMinutes: 2,
              targetFtpPercentMin: 108,
              targetFtpPercentMax: 118,
              targetCadenceRpm: 106,
              zoneName: 'Z5',
            ),
            WarmupIntervalStep(
              stepIndex: 3,
              labelPl: 'Wyciszenie Z1',
              labelEn: 'Cool-Down Z1',
              durationMinutes: 5,
              targetFtpPercentMin: 50,
              targetFtpPercentMax: 58,
              targetCadenceRpm: 90,
              zoneName: 'Z1',
            ),
          ],
        );

      case WarmupProtocolType.vo2PrimingItt:
        return const WarmupProtocolPreset(
          protocolType: WarmupProtocolType.vo2PrimingItt,
          namePl: 'VO2 Priming ITT',
          nameEn: 'VO2 Priming ITT',
          descriptionPl:
              'Złoty standard jazdy na czas (32 min): trzy 2-minutowe interwały 105% FTP podnoszą kinetykę VO2 i dają +4.5% mocy na starcie ITT.',
          descriptionEn:
              'Gold-standard TT protocol (32 min): three 2-min 105% FTP priming efforts accelerate VO2 kinetics for +4.5% power at ITT start.',
          totalDurationMinutes: 32,
          ittStartPowerBonusPercent: vo2PrimingIttBonusPercent,
          firstTenMinVo2KineticsBonusPercent: 4.5,
          neuromuscularSnapBonusPercent: 3.2,
          glycogenCostGrams: 42.0,
          coreTempRiseCelsius: 0.85,
          wPrimePreSpendPercent: 4.0,
          steps: [
            WarmupIntervalStep(
              stepIndex: 0,
              labelPl: 'Progresywne wprowadzenie Z1–Z2',
              labelEn: 'Progressive Intro Z1–Z2',
              durationMinutes: 10,
              targetFtpPercentMin: 55,
              targetFtpPercentMax: 74,
              targetCadenceRpm: 95,
              zoneName: 'Z1-Z2',
            ),
            WarmupIntervalStep(
              stepIndex: 1,
              labelPl: '3x2 min VO2 Priming (105% FTP)',
              labelEn: '3x2 min VO2 Priming (105% FTP)',
              durationMinutes: 12,
              targetFtpPercentMin: 102,
              targetFtpPercentMax: 108,
              targetCadenceRpm: 100,
              zoneName: 'Z5 VO2max',
            ),
            WarmupIntervalStep(
              stepIndex: 2,
              labelPl: '4x10s Akceleracje kadencyjne',
              labelEn: '4x10s Cadence Accelerations',
              durationMinutes: 4,
              targetFtpPercentMin: 125,
              targetFtpPercentMax: 145,
              targetCadenceRpm: 112,
              zoneName: 'Z6',
            ),
            WarmupIntervalStep(
              stepIndex: 3,
              labelPl: 'Schłodzenie przed rampą Z1',
              labelEn: 'Pre-Ramp Cool-Down Z1',
              durationMinutes: 6,
              targetFtpPercentMin: 50,
              targetFtpPercentMax: 58,
              targetCadenceRpm: 92,
              zoneName: 'Z1',
            ),
          ],
        );

      case WarmupProtocolType.mountainStartOpener:
        return const WarmupProtocolPreset(
          protocolType: WarmupProtocolType.mountainStartOpener,
          namePl: 'Otwarcie górskie KM 0',
          nameEn: 'Mountain KM 0 Opener',
          descriptionPl:
              '20-minutowe otwarcie pod etap zaczynający się bezpośrednio od podjazdu. Chroni przed zakwaszeniem na pierwszych serpentynach.',
          descriptionEn:
              '20-minute opener for stages starting directly onto a climb. Prevents early lactate spike on opening switchbacks.',
          totalDurationMinutes: 20,
          ittStartPowerBonusPercent: 2.8,
          firstTenMinVo2KineticsBonusPercent: 3.4,
          neuromuscularSnapBonusPercent: 1.8,
          glycogenCostGrams: 28.0,
          coreTempRiseCelsius: 0.60,
          wPrimePreSpendPercent: 2.0,
          steps: [
            WarmupIntervalStep(
              stepIndex: 0,
              labelPl: 'Rozgrzewka Z1–Z2',
              labelEn: 'Warm-Up Z1–Z2',
              durationMinutes: 9,
              targetFtpPercentMin: 56,
              targetFtpPercentMax: 72,
              targetCadenceRpm: 90,
              zoneName: 'Z1-Z2',
            ),
            WarmupIntervalStep(
              stepIndex: 1,
              labelPl: 'Blok progowy Z4 (96% FTP)',
              labelEn: 'Threshold Block Z4 (96% FTP)',
              durationMinutes: 6,
              targetFtpPercentMin: 92,
              targetFtpPercentMax: 98,
              targetCadenceRpm: 88,
              zoneName: 'Z4',
            ),
            WarmupIntervalStep(
              stepIndex: 2,
              labelPl: 'Wyciszenie Z1',
              labelEn: 'Easy Spin Z1',
              durationMinutes: 5,
              targetFtpPercentMin: 50,
              targetFtpPercentMax: 58,
              targetCadenceRpm: 92,
              zoneName: 'Z1',
            ),
          ],
        );

      case WarmupProtocolType.sprintNeuromuscularPriming:
        return const WarmupProtocolPreset(
          protocolType: WarmupProtocolType.sprintNeuromuscularPriming,
          namePl: 'Aktywacja nerwowo-mięśniowa',
          nameEn: 'Neuromuscular Sprint Priming',
          descriptionPl:
              '18-minutowy protokół z trzema 6-sekundowymi eksplozjami mocy pod krótki prolog lub techniczne kryterium.',
          descriptionEn:
              '18-minute protocol featuring three 6-second maximal bursts for short prologues or technical criteriums.',
          totalDurationMinutes: 18,
          ittStartPowerBonusPercent: 3.4,
          firstTenMinVo2KineticsBonusPercent: 2.5,
          neuromuscularSnapBonusPercent: 5.0,
          glycogenCostGrams: 22.0,
          coreTempRiseCelsius: 0.45,
          wPrimePreSpendPercent: 3.5,
          steps: [
            WarmupIntervalStep(
              stepIndex: 0,
              labelPl: 'Rozjazd Z1–Z2',
              labelEn: 'Spin Z1–Z2',
              durationMinutes: 10,
              targetFtpPercentMin: 55,
              targetFtpPercentMax: 70,
              targetCadenceRpm: 95,
              zoneName: 'Z1-Z2',
            ),
            WarmupIntervalStep(
              stepIndex: 1,
              labelPl: '3x6s Eksplozja Z7',
              labelEn: '3x6s Z7 Maximal Bursts',
              durationMinutes: 4,
              targetFtpPercentMin: 180,
              targetFtpPercentMax: 240,
              targetCadenceRpm: 116,
              zoneName: 'Z7',
            ),
            WarmupIntervalStep(
              stepIndex: 2,
              labelPl: 'Swobodne kręcenie Z1',
              labelEn: 'Easy Spin Z1',
              durationMinutes: 4,
              targetFtpPercentMin: 48,
              targetFtpPercentMax: 55,
              targetCadenceRpm: 90,
              zoneName: 'Z1',
            ),
          ],
        );
    }
  }
}

/// Specyfikacja autokaru drużynowego i strefy trenażerów w paddocku.
class TeamBusSpecification {
  final String busId;
  final String teamName;
  final TeamBusTier tier;
  final int trainerStationCount;
  final SmartTrainerType trainerType;
  final bool hasKitchenAndNutritionBar;
  final bool hasPhysioMassageRoom;
  final bool hasIceVestFreezer;
  final bool hasAcclimatizedClimateCabin;
  final double ambientCabinTempCelsius;
  final int aerodynamicAwningSetupMinutes;
  final int busPrestigeRating;

  const TeamBusSpecification({
    required this.busId,
    required this.teamName,
    required this.tier,
    required this.trainerStationCount,
    required this.trainerType,
    required this.hasKitchenAndNutritionBar,
    required this.hasPhysioMassageRoom,
    required this.hasIceVestFreezer,
    required this.hasAcclimatizedClimateCabin,
    required this.ambientCabinTempCelsius,
    required this.aerodynamicAwningSetupMinutes,
    required this.busPrestigeRating,
  });

  factory TeamBusSpecification.forTier(
    TeamBusTier tier, {
    String busId = 'team_bus_primary',
    String teamName = 'Pro Peloton Team',
  }) {
    switch (tier) {
      case TeamBusTier.continentalMinibus:
        return TeamBusSpecification(
          busId: busId,
          teamName: teamName,
          tier: tier,
          trainerStationCount: 2,
          trainerType: SmartTrainerType.rollers,
          hasKitchenAndNutritionBar: false,
          hasPhysioMassageRoom: false,
          hasIceVestFreezer: false,
          hasAcclimatizedClimateCabin: false,
          ambientCabinTempCelsius: 23.0,
          aerodynamicAwningSetupMinutes: 10,
          busPrestigeRating: 1,
        );
      case TeamBusTier.proTeamTourBus:
        return TeamBusSpecification(
          busId: busId,
          teamName: teamName,
          tier: tier,
          trainerStationCount: 4,
          trainerType: SmartTrainerType.directDriveStandard,
          hasKitchenAndNutritionBar: true,
          hasPhysioMassageRoom: false,
          hasIceVestFreezer: false,
          hasAcclimatizedClimateCabin: true,
          ambientCabinTempCelsius: 20.5,
          aerodynamicAwningSetupMinutes: 18,
          busPrestigeRating: 3,
        );
      case TeamBusTier.worldTourFlagshipBus:
        return TeamBusSpecification(
          busId: busId,
          teamName: teamName,
          tier: tier,
          trainerStationCount: 8,
          trainerType: SmartTrainerType.directDriveProErg,
          hasKitchenAndNutritionBar: true,
          hasPhysioMassageRoom: true,
          hasIceVestFreezer: true,
          hasAcclimatizedClimateCabin: true,
          ambientCabinTempCelsius: 19.0,
          aerodynamicAwningSetupMinutes: 25,
          busPrestigeRating: 4,
        );
      case TeamBusTier.grandTourCommandCenter:
        return TeamBusSpecification(
          busId: busId,
          teamName: teamName,
          tier: tier,
          trainerStationCount: 9,
          trainerType: SmartTrainerType.directDriveProErg,
          hasKitchenAndNutritionBar: true,
          hasPhysioMassageRoom: true,
          hasIceVestFreezer: true,
          hasAcclimatizedClimateCabin: true,
          ambientCabinTempCelsius: 18.0,
          aerodynamicAwningSetupMinutes: 30,
          busPrestigeRating: 5,
        );
    }
  }

  TeamBusSpecification copyWith({
    String? busId,
    String? teamName,
    TeamBusTier? tier,
    int? trainerStationCount,
    SmartTrainerType? trainerType,
    bool? hasKitchenAndNutritionBar,
    bool? hasPhysioMassageRoom,
    bool? hasIceVestFreezer,
    bool? hasAcclimatizedClimateCabin,
    double? ambientCabinTempCelsius,
    int? aerodynamicAwningSetupMinutes,
    int? busPrestigeRating,
  }) {
    return TeamBusSpecification(
      busId: busId ?? this.busId,
      teamName: teamName ?? this.teamName,
      tier: tier ?? this.tier,
      trainerStationCount: trainerStationCount ?? this.trainerStationCount,
      trainerType: trainerType ?? this.trainerType,
      hasKitchenAndNutritionBar:
          hasKitchenAndNutritionBar ?? this.hasKitchenAndNutritionBar,
      hasPhysioMassageRoom: hasPhysioMassageRoom ?? this.hasPhysioMassageRoom,
      hasIceVestFreezer: hasIceVestFreezer ?? this.hasIceVestFreezer,
      hasAcclimatizedClimateCabin:
          hasAcclimatizedClimateCabin ?? this.hasAcclimatizedClimateCabin,
      ambientCabinTempCelsius:
          ambientCabinTempCelsius ?? this.ambientCabinTempCelsius,
      aerodynamicAwningSetupMinutes:
          aerodynamicAwningSetupMinutes ?? this.aerodynamicAwningSetupMinutes,
      busPrestigeRating: busPrestigeRating ?? this.busPrestigeRating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'teamName': teamName,
      'tier': tier.toJson(),
      'trainerStationCount': trainerStationCount,
      'trainerType': trainerType.toJson(),
      'hasKitchenAndNutritionBar': hasKitchenAndNutritionBar,
      'hasPhysioMassageRoom': hasPhysioMassageRoom,
      'hasIceVestFreezer': hasIceVestFreezer,
      'hasAcclimatizedClimateCabin': hasAcclimatizedClimateCabin,
      'ambientCabinTempCelsius': ambientCabinTempCelsius,
      'aerodynamicAwningSetupMinutes': aerodynamicAwningSetupMinutes,
      'busPrestigeRating': busPrestigeRating,
    };
  }

  factory TeamBusSpecification.fromJson(Map<String, dynamic> json) {
    return TeamBusSpecification(
      busId: json['busId'] as String,
      teamName: json['teamName'] as String,
      tier: TeamBusTier.fromJson(json['tier'] as String),
      trainerStationCount: (json['trainerStationCount'] as num).toInt(),
      trainerType: SmartTrainerType.fromJson(json['trainerType'] as String),
      hasKitchenAndNutritionBar: json['hasKitchenAndNutritionBar'] as bool,
      hasPhysioMassageRoom: json['hasPhysioMassageRoom'] as bool,
      hasIceVestFreezer: json['hasIceVestFreezer'] as bool,
      hasAcclimatizedClimateCabin: json['hasAcclimatizedClimateCabin'] as bool,
      ambientCabinTempCelsius:
          (json['ambientCabinTempCelsius'] as num).toDouble(),
      aerodynamicAwningSetupMinutes:
          (json['aerodynamicAwningSetupMinutes'] as num).toInt(),
      busPrestigeRating: (json['busPrestigeRating'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamBusSpecification &&
        other.busId == busId &&
        other.teamName == teamName &&
        other.tier == tier &&
        other.trainerStationCount == trainerStationCount &&
        other.trainerType == trainerType &&
        other.hasKitchenAndNutritionBar == hasKitchenAndNutritionBar &&
        other.hasPhysioMassageRoom == hasPhysioMassageRoom &&
        other.hasIceVestFreezer == hasIceVestFreezer &&
        other.hasAcclimatizedClimateCabin == hasAcclimatizedClimateCabin &&
        other.ambientCabinTempCelsius == ambientCabinTempCelsius &&
        other.aerodynamicAwningSetupMinutes == aerodynamicAwningSetupMinutes &&
        other.busPrestigeRating == busPrestigeRating;
  }

  @override
  int get hashCode => Object.hash(
        busId,
        teamName,
        tier,
        trainerStationCount,
        trainerType,
        hasKitchenAndNutritionBar,
        hasPhysioMassageRoom,
        hasIceVestFreezer,
        hasAcclimatizedClimateCabin,
        ambientCabinTempCelsius,
        aerodynamicAwningSetupMinutes,
        busPrestigeRating,
      );
}

/// Przypisanie konkretnego kolarza do stanowiska trenażera przed startem etapu.
class RiderWarmupAssignment {
  final String riderId;
  final String riderName;
  final int trainerSlotIndex;
  final WarmupProtocolType protocolType;
  final CoolingStrategyType coolingStrategy;

  /// Ile minut przed startem kolarz kończy rozgrzewkę (optymalnie 10–15 min).
  final int minutesBeforeStart;
  final int riderFtpWatts;
  final double riderWeightKg;
  final double ambientTempCelsius;
  final bool isIttOrPrologue;
  final WarmupCompletionStatus status;

  const RiderWarmupAssignment({
    required this.riderId,
    required this.riderName,
    required this.trainerSlotIndex,
    required this.protocolType,
    required this.coolingStrategy,
    required this.minutesBeforeStart,
    required this.riderFtpWatts,
    required this.riderWeightKg,
    required this.ambientTempCelsius,
    required this.isIttOrPrologue,
    this.status = WarmupCompletionStatus.pending,
  });

  RiderWarmupAssignment copyWith({
    String? riderId,
    String? riderName,
    int? trainerSlotIndex,
    WarmupProtocolType? protocolType,
    CoolingStrategyType? coolingStrategy,
    int? minutesBeforeStart,
    int? riderFtpWatts,
    double? riderWeightKg,
    double? ambientTempCelsius,
    bool? isIttOrPrologue,
    WarmupCompletionStatus? status,
  }) {
    return RiderWarmupAssignment(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      trainerSlotIndex: trainerSlotIndex ?? this.trainerSlotIndex,
      protocolType: protocolType ?? this.protocolType,
      coolingStrategy: coolingStrategy ?? this.coolingStrategy,
      minutesBeforeStart: minutesBeforeStart ?? this.minutesBeforeStart,
      riderFtpWatts: riderFtpWatts ?? this.riderFtpWatts,
      riderWeightKg: riderWeightKg ?? this.riderWeightKg,
      ambientTempCelsius: ambientTempCelsius ?? this.ambientTempCelsius,
      isIttOrPrologue: isIttOrPrologue ?? this.isIttOrPrologue,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'trainerSlotIndex': trainerSlotIndex,
      'protocolType': protocolType.toJson(),
      'coolingStrategy': coolingStrategy.toJson(),
      'minutesBeforeStart': minutesBeforeStart,
      'riderFtpWatts': riderFtpWatts,
      'riderWeightKg': riderWeightKg,
      'ambientTempCelsius': ambientTempCelsius,
      'isIttOrPrologue': isIttOrPrologue,
      'status': status.toJson(),
    };
  }

  factory RiderWarmupAssignment.fromJson(Map<String, dynamic> json) {
    return RiderWarmupAssignment(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      trainerSlotIndex: (json['trainerSlotIndex'] as num).toInt(),
      protocolType: WarmupProtocolType.fromJson(json['protocolType'] as String),
      coolingStrategy:
          CoolingStrategyType.fromJson(json['coolingStrategy'] as String),
      minutesBeforeStart: (json['minutesBeforeStart'] as num).toInt(),
      riderFtpWatts: (json['riderFtpWatts'] as num).toInt(),
      riderWeightKg: (json['riderWeightKg'] as num).toDouble(),
      ambientTempCelsius: (json['ambientTempCelsius'] as num).toDouble(),
      isIttOrPrologue: json['isIttOrPrologue'] as bool,
      status: WarmupCompletionStatus.fromJson(
        json['status'] as String? ?? WarmupCompletionStatus.pending.name,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderWarmupAssignment &&
        other.riderId == riderId &&
        other.riderName == riderName &&
        other.trainerSlotIndex == trainerSlotIndex &&
        other.protocolType == protocolType &&
        other.coolingStrategy == coolingStrategy &&
        other.minutesBeforeStart == minutesBeforeStart &&
        other.riderFtpWatts == riderFtpWatts &&
        other.riderWeightKg == riderWeightKg &&
        other.ambientTempCelsius == ambientTempCelsius &&
        other.isIttOrPrologue == isIttOrPrologue &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
        riderId,
        riderName,
        trainerSlotIndex,
        protocolType,
        coolingStrategy,
        minutesBeforeStart,
        riderFtpWatts,
        riderWeightKg,
        ambientTempCelsius,
        isIttOrPrologue,
        status,
      );
}

/// Wynik fizjologiczny rozgrzewki przed startem etapu dla pojedynczego kolarza.
class WarmupPhysiologicalOutcome {
  final String riderId;
  final double effectiveStartPowerBonusPercent;
  final double startPowerMultiplier;
  final double effectiveStartPowerWatts;
  final double coreTempDeltaCelsius;
  final double estimatedStartCoreTempCelsius;
  final double glycogenSpentGrams;
  final double wPrimeRecoveryReadinessRatio;
  final double timingEfficiencyFactor;
  final bool isOverheatedRisk;
  final String summaryNotePl;
  final String summaryNoteEn;

  const WarmupPhysiologicalOutcome({
    required this.riderId,
    required this.effectiveStartPowerBonusPercent,
    required this.startPowerMultiplier,
    required this.effectiveStartPowerWatts,
    required this.coreTempDeltaCelsius,
    required this.estimatedStartCoreTempCelsius,
    required this.glycogenSpentGrams,
    required this.wPrimeRecoveryReadinessRatio,
    required this.timingEfficiencyFactor,
    required this.isOverheatedRisk,
    required this.summaryNotePl,
    required this.summaryNoteEn,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'effectiveStartPowerBonusPercent': effectiveStartPowerBonusPercent,
      'startPowerMultiplier': startPowerMultiplier,
      'effectiveStartPowerWatts': effectiveStartPowerWatts,
      'coreTempDeltaCelsius': coreTempDeltaCelsius,
      'estimatedStartCoreTempCelsius': estimatedStartCoreTempCelsius,
      'glycogenSpentGrams': glycogenSpentGrams,
      'wPrimeRecoveryReadinessRatio': wPrimeRecoveryReadinessRatio,
      'timingEfficiencyFactor': timingEfficiencyFactor,
      'isOverheatedRisk': isOverheatedRisk,
      'summaryNotePl': summaryNotePl,
      'summaryNoteEn': summaryNoteEn,
    };
  }

  factory WarmupPhysiologicalOutcome.fromJson(Map<String, dynamic> json) {
    return WarmupPhysiologicalOutcome(
      riderId: json['riderId'] as String,
      effectiveStartPowerBonusPercent:
          (json['effectiveStartPowerBonusPercent'] as num).toDouble(),
      startPowerMultiplier: (json['startPowerMultiplier'] as num).toDouble(),
      effectiveStartPowerWatts:
          (json['effectiveStartPowerWatts'] as num).toDouble(),
      coreTempDeltaCelsius: (json['coreTempDeltaCelsius'] as num).toDouble(),
      estimatedStartCoreTempCelsius:
          (json['estimatedStartCoreTempCelsius'] as num).toDouble(),
      glycogenSpentGrams: (json['glycogenSpentGrams'] as num).toDouble(),
      wPrimeRecoveryReadinessRatio:
          (json['wPrimeRecoveryReadinessRatio'] as num).toDouble(),
      timingEfficiencyFactor:
          (json['timingEfficiencyFactor'] as num).toDouble(),
      isOverheatedRisk: json['isOverheatedRisk'] as bool,
      summaryNotePl: json['summaryNotePl'] as String,
      summaryNoteEn: json['summaryNoteEn'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WarmupPhysiologicalOutcome &&
        other.riderId == riderId &&
        other.effectiveStartPowerBonusPercent ==
            effectiveStartPowerBonusPercent &&
        other.startPowerMultiplier == startPowerMultiplier &&
        other.effectiveStartPowerWatts == effectiveStartPowerWatts &&
        other.coreTempDeltaCelsius == coreTempDeltaCelsius &&
        other.estimatedStartCoreTempCelsius == estimatedStartCoreTempCelsius &&
        other.glycogenSpentGrams == glycogenSpentGrams &&
        other.wPrimeRecoveryReadinessRatio == wPrimeRecoveryReadinessRatio &&
        other.timingEfficiencyFactor == timingEfficiencyFactor &&
        other.isOverheatedRisk == isOverheatedRisk &&
        other.summaryNotePl == summaryNotePl &&
        other.summaryNoteEn == summaryNoteEn;
  }

  @override
  int get hashCode => Object.hash(
        riderId,
        effectiveStartPowerBonusPercent,
        startPowerMultiplier,
        effectiveStartPowerWatts,
        coreTempDeltaCelsius,
        estimatedStartCoreTempCelsius,
        glycogenSpentGrams,
        wPrimeRecoveryReadinessRatio,
        timingEfficiencyFactor,
        isOverheatedRisk,
        summaryNotePl,
        summaryNoteEn,
      );
}

/// Główny model Autobusu Drużyny i Protokołu Rozgrzewki na trenażerze w paddocku.
class TeamBusAndWarmupProtocolModel {
  final String stageId;
  final String stageName;
  final bool isIndividualTimeTrial;
  final bool isTeamTimeTrial;
  final double ambientTempCelsius;
  final bool hasSteepEarlyClimb;
  final TeamBusSpecification teamBus;
  final List<RiderWarmupAssignment> assignments;

  const TeamBusAndWarmupProtocolModel({
    required this.stageId,
    required this.stageName,
    required this.isIndividualTimeTrial,
    required this.isTeamTimeTrial,
    required this.ambientTempCelsius,
    required this.hasSteepEarlyClimb,
    required this.teamBus,
    this.assignments = const [],
  });

  int get assignedRidersCount => assignments.length;

  int get freeTrainerSlotsCount =>
      math.max(0, teamBus.trainerStationCount - assignments.length);

  bool get isPaddockFull => assignments.length >= teamBus.trainerStationCount;

  /// Średnia premia mocy startowej (%) dla przypisanych kolarzy.
  double get averageStartPowerBonusPercent {
    if (assignments.isEmpty) return 0.0;
    final outcomes = evaluateAllAssignments();
    final total = outcomes.fold<double>(
      0.0,
      (sum, item) => sum + item.effectiveStartPowerBonusPercent,
    );
    return total / outcomes.length;
  }

  /// Oblicza fizjologiczny efekt rozgrzewki dla pojedynczego kolarza.
  WarmupPhysiologicalOutcome evaluateRiderWarmup(
    RiderWarmupAssignment assignment,
  ) {
    final preset = WarmupProtocolPreset.fromType(assignment.protocolType);
    final safeMinutesBeforeStart = assignment.minutesBeforeStart.clamp(0, 60);

    // Optymalne okno zejścia z trenażera to 8–15 minut przed startem.
    final double timingFactor;
    if (assignment.protocolType == WarmupProtocolType.none) {
      timingFactor = 1.0;
    } else if (safeMinutesBeforeStart >= 8 && safeMinutesBeforeStart <= 15) {
      timingFactor = 1.0;
    } else if (safeMinutesBeforeStart < 8) {
      // Zbyt późne zejście z trenażera: niepełna resynteza W'.
      timingFactor = (0.82 + (safeMinutesBeforeStart / 8.0) * 0.18).clamp(0.75, 1.0);
    } else {
      // Wychłodzenie po długim oczekiwaniu w strefie startowej (>15 min).
      final decay = (safeMinutesBeforeStart - 15) * 0.025;
      timingFactor = (1.0 - decay).clamp(0.45, 1.0);
    }

    // Wpływ chłodzenia i temperatury otoczenia na temperaturę głęboką ciała.
    final heatLoadFromAmbient =
        math.max(0.0, (assignment.ambientTempCelsius - 21.0) * 0.032);
    final effectiveCooling = assignment.coolingStrategy ==
                CoolingStrategyType.preCoolingIceVest &&
            !teamBus.hasIceVestFreezer
        ? CoolingStrategyType.fanAndColdTowels.coreTempReductionCelsius
        : assignment.coolingStrategy.coreTempReductionCelsius;

    final rawCoreDelta =
        preset.coreTempRiseCelsius + heatLoadFromAmbient - effectiveCooling;
    final netCoreDelta = rawCoreDelta.clamp(-0.65, 1.80);
    final startCoreTemp = 37.0 + netCoreDelta;
    final overheated = startCoreTemp >= 38.05;

    final double trainerFactor = assignment.protocolType == WarmupProtocolType.none
        ? 1.0
        : teamBus.trainerType.primingExecutionMultiplier;

    double bonusPercent;
    if (assignment.protocolType == WarmupProtocolType.none) {
      bonusPercent = preset.ittStartPowerBonusPercent;
    } else if (assignment.protocolType == WarmupProtocolType.vo2PrimingItt) {
      // VO2 Priming daje pełne +4.5% na starcie ITT przy optymalnym oknie i trenażerze Pro ERG.
      final disciplineMultiplier =
          (assignment.isIttOrPrologue || isIndividualTimeTrial || isTeamTimeTrial)
              ? 1.0
              : 0.72;
      bonusPercent = preset.ittStartPowerBonusPercent *
          timingFactor *
          trainerFactor *
          disciplineMultiplier;
    } else {
      bonusPercent =
          preset.ittStartPowerBonusPercent * timingFactor * trainerFactor;
    }

    if (overheated) {
      // Przegrzanie przed startem (>38.05°C) ogranicza zysk z rozgrzewki.
      bonusPercent -= (startCoreTemp - 38.0) * 2.4;
    }

    final roundedBonus = double.parse(bonusPercent.toStringAsFixed(2));
    final multiplier = 1.0 + (roundedBonus / 100.0);
    final effectiveWatts =
        double.parse((assignment.riderFtpWatts * multiplier).toStringAsFixed(1));

    final wPrimeReadiness = assignment.protocolType == WarmupProtocolType.none
        ? 1.0
        : (1.0 -
                (preset.wPrimePreSpendPercent / 100.0) *
                    (safeMinutesBeforeStart < 6 ? 1.0 : 0.25))
            .clamp(0.85, 1.0);

    final notePl = _buildSummaryNotePl(
      assignment: assignment,
      bonusPercent: roundedBonus,
      overheated: overheated,
      timingFactor: timingFactor,
    );
    final noteEn = _buildSummaryNoteEn(
      assignment: assignment,
      bonusPercent: roundedBonus,
      overheated: overheated,
      timingFactor: timingFactor,
    );

    return WarmupPhysiologicalOutcome(
      riderId: assignment.riderId,
      effectiveStartPowerBonusPercent: roundedBonus,
      startPowerMultiplier: multiplier,
      effectiveStartPowerWatts: effectiveWatts,
      coreTempDeltaCelsius: double.parse(netCoreDelta.toStringAsFixed(2)),
      estimatedStartCoreTempCelsius:
          double.parse(startCoreTemp.toStringAsFixed(2)),
      glycogenSpentGrams: preset.glycogenCostGrams,
      wPrimeRecoveryReadinessRatio:
          double.parse(wPrimeReadiness.toStringAsFixed(3)),
      timingEfficiencyFactor: double.parse(timingFactor.toStringAsFixed(3)),
      isOverheatedRisk: overheated,
      summaryNotePl: notePl,
      summaryNoteEn: noteEn,
    );
  }

  List<WarmupPhysiologicalOutcome> evaluateAllAssignments() {
    return assignments.map(evaluateRiderWarmup).toList(growable: false);
  }

  /// Rekomenduje optymalny protokół rozgrzewki dla danego typu etapu i profilu kolarza.
  WarmupProtocolType recommendProtocolForStage({
    required bool isItt,
    required bool isTtt,
    required bool hasSteepEarlyClimb,
    required bool isShortPrologueOrCrit,
  }) {
    if (isItt || isTtt) {
      return WarmupProtocolType.vo2PrimingItt;
    }
    if (isShortPrologueOrCrit) {
      return WarmupProtocolType.sprintNeuromuscularPriming;
    }
    if (hasSteepEarlyClimb) {
      return WarmupProtocolType.mountainStartOpener;
    }
    if (ambientTempCelsius >= 30.0) {
      return WarmupProtocolType.lightSpinActivation;
    }
    return WarmupProtocolType.progressiveRamp;
  }

  /// Rekomenduje strategię chłodzenia na bazie temperatury i wyposażenia autokaru.
  CoolingStrategyType recommendCoolingForProtocol(
    WarmupProtocolType protocol,
  ) {
    if (protocol == WarmupProtocolType.none) {
      return CoolingStrategyType.none;
    }
    if ((ambientTempCelsius >= 24.0 ||
            protocol == WarmupProtocolType.vo2PrimingItt) &&
        teamBus.hasIceVestFreezer) {
      return CoolingStrategyType.preCoolingIceVest;
    }
    return CoolingStrategyType.fanAndColdTowels;
  }

  /// Przypisuje lub aktualizuje kolarza na stanowisku trenażera w paddocku.
  TeamBusAndWarmupProtocolModel assignRiderToTrainer({
    required String riderId,
    required String riderName,
    required int riderFtpWatts,
    required double riderWeightKg,
    required WarmupProtocolType protocolType,
    CoolingStrategyType? coolingStrategy,
    int minutesBeforeStart = 12,
    int? preferredSlotIndex,
  }) {
    final effectiveCooling = coolingStrategy ??
        recommendCoolingForProtocol(protocolType);
    final sanitizedCooling =
        effectiveCooling == CoolingStrategyType.preCoolingIceVest &&
                !teamBus.hasIceVestFreezer
            ? CoolingStrategyType.fanAndColdTowels
            : effectiveCooling;

    final existingIndex =
        assignments.indexWhere((element) => element.riderId == riderId);

    if (existingIndex >= 0) {
      final existing = assignments[existingIndex];
      final updated = existing.copyWith(
        riderName: riderName,
        protocolType: protocolType,
        coolingStrategy: sanitizedCooling,
        minutesBeforeStart: minutesBeforeStart.clamp(0, 60),
        riderFtpWatts: riderFtpWatts,
        riderWeightKg: riderWeightKg,
        ambientTempCelsius: ambientTempCelsius,
        isIttOrPrologue: isIndividualTimeTrial || isTeamTimeTrial,
      );
      final nextList = List<RiderWarmupAssignment>.from(assignments);
      nextList[existingIndex] = updated;
      return copyWith(assignments: nextList);
    }

    if (isPaddockFull) {
      return this;
    }

    final occupiedSlots =
        assignments.map((a) => a.trainerSlotIndex).toSet();
    int chosenSlot = preferredSlotIndex ?? 0;
    if (preferredSlotIndex == null ||
        preferredSlotIndex < 0 ||
        preferredSlotIndex >= teamBus.trainerStationCount ||
        occupiedSlots.contains(preferredSlotIndex)) {
      chosenSlot = List<int>.generate(teamBus.trainerStationCount, (i) => i)
          .firstWhere((slot) => !occupiedSlots.contains(slot), orElse: () => 0);
    }

    final created = RiderWarmupAssignment(
      riderId: riderId,
      riderName: riderName,
      trainerSlotIndex: chosenSlot,
      protocolType: protocolType,
      coolingStrategy: sanitizedCooling,
      minutesBeforeStart: minutesBeforeStart.clamp(0, 60),
      riderFtpWatts: riderFtpWatts,
      riderWeightKg: riderWeightKg,
      ambientTempCelsius: ambientTempCelsius,
      isIttOrPrologue: isIndividualTimeTrial || isTeamTimeTrial,
    );

    return copyWith(
      assignments: [...assignments, created],
    );
  }

  /// Usuwa kolarza ze stanowiska trenażera w paddocku.
  TeamBusAndWarmupProtocolModel removeRiderFromTrainer(String riderId) {
    final next = assignments
        .where((element) => element.riderId != riderId)
        .toList(growable: false);
    return copyWith(assignments: next);
  }

  String _buildSummaryNotePl({
    required RiderWarmupAssignment assignment,
    required double bonusPercent,
    required bool overheated,
    required double timingFactor,
  }) {
    if (assignment.protocolType == WarmupProtocolType.none) {
      return 'Zimny start bez trenażera (${bonusPercent.toStringAsFixed(1)}% mocy startowej).';
    }
    if (overheated) {
      return 'Ryzyko przegrzania przed startem! Rozważ Pre-Cooling Ice Vest (+${bonusPercent.toStringAsFixed(1)}% mocy).';
    }
    if (timingFactor < 0.85) {
      return 'Nieoptymalny czas zejścia z trenażera (${assignment.minutesBeforeStart} min przed startem): +${bonusPercent.toStringAsFixed(1)}% mocy.';
    }
    return 'Optymalna aktywacja: +${bonusPercent.toStringAsFixed(1)}% mocy na starcie.';
  }

  String _buildSummaryNoteEn({
    required RiderWarmupAssignment assignment,
    required double bonusPercent,
    required bool overheated,
    required double timingFactor,
  }) {
    if (assignment.protocolType == WarmupProtocolType.none) {
      return 'Cold start without trainer (${bonusPercent.toStringAsFixed(1)}% start power).';
    }
    if (overheated) {
      return 'Pre-start overheating risk! Consider Pre-Cooling Ice Vest (+${bonusPercent.toStringAsFixed(1)}% power).';
    }
    if (timingFactor < 0.85) {
      return 'Suboptimal trainer finish window (${assignment.minutesBeforeStart} min before start): +${bonusPercent.toStringAsFixed(1)}% power.';
    }
    return 'Optimal activation: +${bonusPercent.toStringAsFixed(1)}% start power.';
  }

  TeamBusAndWarmupProtocolModel copyWith({
    String? stageId,
    String? stageName,
    bool? isIndividualTimeTrial,
    bool? isTeamTimeTrial,
    double? ambientTempCelsius,
    bool? hasSteepEarlyClimb,
    TeamBusSpecification? teamBus,
    List<RiderWarmupAssignment>? assignments,
  }) {
    return TeamBusAndWarmupProtocolModel(
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      isIndividualTimeTrial:
          isIndividualTimeTrial ?? this.isIndividualTimeTrial,
      isTeamTimeTrial: isTeamTimeTrial ?? this.isTeamTimeTrial,
      ambientTempCelsius: ambientTempCelsius ?? this.ambientTempCelsius,
      hasSteepEarlyClimb: hasSteepEarlyClimb ?? this.hasSteepEarlyClimb,
      teamBus: teamBus ?? this.teamBus,
      assignments: assignments != null
          ? List<RiderWarmupAssignment>.unmodifiable(assignments)
          : this.assignments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'stageName': stageName,
      'isIndividualTimeTrial': isIndividualTimeTrial,
      'isTeamTimeTrial': isTeamTimeTrial,
      'ambientTempCelsius': ambientTempCelsius,
      'hasSteepEarlyClimb': hasSteepEarlyClimb,
      'teamBus': teamBus.toJson(),
      'assignments': assignments.map((e) => e.toJson()).toList(),
    };
  }

  factory TeamBusAndWarmupProtocolModel.fromJson(Map<String, dynamic> json) {
    return TeamBusAndWarmupProtocolModel(
      stageId: json['stageId'] as String,
      stageName: json['stageName'] as String,
      isIndividualTimeTrial: json['isIndividualTimeTrial'] as bool,
      isTeamTimeTrial: json['isTeamTimeTrial'] as bool,
      ambientTempCelsius: (json['ambientTempCelsius'] as num).toDouble(),
      hasSteepEarlyClimb: json['hasSteepEarlyClimb'] as bool,
      teamBus:
          TeamBusSpecification.fromJson(json['teamBus'] as Map<String, dynamic>),
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map(
                (e) =>
                    RiderWarmupAssignment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TeamBusAndWarmupProtocolModel) return false;
    if (other.stageId != stageId ||
        other.stageName != stageName ||
        other.isIndividualTimeTrial != isIndividualTimeTrial ||
        other.isTeamTimeTrial != isTeamTimeTrial ||
        other.ambientTempCelsius != ambientTempCelsius ||
        other.hasSteepEarlyClimb != hasSteepEarlyClimb ||
        other.teamBus != teamBus ||
        other.assignments.length != assignments.length) {
      return false;
    }
    for (int i = 0; i < assignments.length; i++) {
      if (other.assignments[i] != assignments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        stageId,
        stageName,
        isIndividualTimeTrial,
        isTeamTimeTrial,
        ambientTempCelsius,
        hasSteepEarlyClimb,
        teamBus,
        Object.hashAll(assignments),
      );
}
