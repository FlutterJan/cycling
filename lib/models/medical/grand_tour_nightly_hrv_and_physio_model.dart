// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Faza 3-tygodniowego Wielkiego Touru wpływająca na kumulację zmęczenia
/// i odpowiedź układu autonomicznego oraz hormonalnego.
enum GrandTourWeekPhase {
  week1Opening,
  week2Attrition,
  week3Survival,
  restDay;

  String get displayName {
    switch (this) {
      case GrandTourWeekPhase.week1Opening:
        return 'Tydzień 1 (Otwarcie i nerwowość)';
      case GrandTourWeekPhase.week2Attrition:
        return 'Tydzień 2 (Kumulacja zmęczenia)';
      case GrandTourWeekPhase.week3Survival:
        return 'Tydzień 3 (Przetrwanie i głęboki katabolizm)';
      case GrandTourWeekPhase.restDay:
        return 'Dzień Przerwy (Okno regeneracji)';
    }
  }

  static GrandTourWeekPhase fromStageDay(int stageDay, {bool isRestDay = false}) {
    if (isRestDay) return GrandTourWeekPhase.restDay;
    if (stageDay <= 7) return GrandTourWeekPhase.week1Opening;
    if (stageDay <= 14) return GrandTourWeekPhase.week2Attrition;
    return GrandTourWeekPhase.week3Survival;
  }

  String toJson() => name;

  static GrandTourWeekPhase fromJson(String value) {
    return GrandTourWeekPhase.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GrandTourWeekPhase.week1Opening,
    );
  }
}

/// Status gotowości fizjologicznej kolarza na podstawie porannego panelu biomarkerów.
enum BiomarkerReadinessStatus {
  peakSupercompensation,
  optimalRecovery,
  parasympatheticFatigue,
  sympatheticOverreaching,
  criticalOvertrainingRisk;

  String get labelPl {
    switch (this) {
      case BiomarkerReadinessStatus.peakSupercompensation:
        return 'Superkompensacja (Szczyt)';
      case BiomarkerReadinessStatus.optimalRecovery:
        return 'Optymalna regeneracja';
      case BiomarkerReadinessStatus.parasympatheticFatigue:
        return 'Przeciążenie przywspółczulne';
      case BiomarkerReadinessStatus.sympatheticOverreaching:
        return 'Stres współczulny (Kryzys)';
      case BiomarkerReadinessStatus.criticalOvertrainingRisk:
        return 'Alarm Medyczny (Ryzyko DNF)';
    }
  }

  String toJson() => name;

  static BiomarkerReadinessStatus fromJson(String value) {
    return BiomarkerReadinessStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BiomarkerReadinessStatus.optimalRecovery,
    );
  }
}

/// Uciążliwość transferu autokarowego między metą a hotelem w Wielkim Tourze.
enum TransferLogisticsSeverity {
  noTransfer,
  shortTransfer,
  moderateTransfer,
  gruelingBusTransfer;

  String get labelPl {
    switch (this) {
      case TransferLogisticsSeverity.noTransfer:
        return 'Brak transferu (< 20 km)';
      case TransferLogisticsSeverity.shortTransfer:
        return 'Krótki transfer (20–75 km)';
      case TransferLogisticsSeverity.moderateTransfer:
        return 'Średni transfer (75–150 km)';
      case TransferLogisticsSeverity.gruelingBusTransfer:
        return 'Morderczy transfer (150+ km / późna noc)';
    }
  }

  String toJson() => name;

  static TransferLogisticsSeverity fromJson(String value) {
    return TransferLogisticsSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransferLogisticsSeverity.shortTransfer,
    );
  }
}

/// Zalecenie sztabu medycznego przed poranną odprawą etapu.
enum MedicalInterventionRecommendation {
  normalRaceLoad,
  protectedDomestiqueDuty,
  grupettoSurvivalMode,
  aggressiveRecoveryProtocol,
  sleepHygieneAndMelatonin,
  medicalWithdrawalMonitor;

  String get labelPl {
    switch (this) {
      case MedicalInterventionRecommendation.normalRaceLoad:
        return 'Pełne obciążenie wyścigowe';
      case MedicalInterventionRecommendation.protectedDomestiqueDuty:
        return 'Oszczędzanie sił w peletonie (ochrona lidera)';
      case MedicalInterventionRecommendation.grupettoSurvivalMode:
        return 'Tryb przetrwania w grupetto (limit czasu)';
      case MedicalInterventionRecommendation.aggressiveRecoveryProtocol:
        return 'Pilna krioterapia + kompresja + nawodnienie';
      case MedicalInterventionRecommendation.sleepHygieneAndMelatonin:
        return 'Protokół snu (melatonina + zaciemnienie pokoju)';
      case MedicalInterventionRecommendation.medicalWithdrawalMonitor:
        return 'Obserwacja lekarska pod kątem wycofania z wyścigu';
    }
  }

  String toJson() => name;

  static MedicalInterventionRecommendation fromJson(String value) {
    return MedicalInterventionRecommendation.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicalInterventionRecommendation.normalRaceLoad,
    );
  }
}

/// Bazowy profil fizjologiczny kolarza zmierzony przed startem Wielkiego Touru.
class RiderBaselineBiomarkers {
  final String riderId;
  final String riderName;
  final double baselineHrvRmssdMs;
  final int baselineRhrBpm;
  final double baselineCkUL;
  final double baselineCortisolNmolL;
  final double baselineTestosteroneNmolL;
  final double baselineSleepEfficiencyPct;

  const RiderBaselineBiomarkers({
    required this.riderId,
    required this.riderName,
    required this.baselineHrvRmssdMs,
    required this.baselineRhrBpm,
    required this.baselineCkUL,
    required this.baselineCortisolNmolL,
    required this.baselineTestosteroneNmolL,
    required this.baselineSleepEfficiencyPct,
  });

  double get baselineCortisolToTestosteroneRatio =>
      baselineTestosteroneNmolL > 0
          ? baselineCortisolNmolL / baselineTestosteroneNmolL
          : 0.03;

  RiderBaselineBiomarkers copyWith({
    String? riderId,
    String? riderName,
    double? baselineHrvRmssdMs,
    int? baselineRhrBpm,
    double? baselineCkUL,
    double? baselineCortisolNmolL,
    double? baselineTestosteroneNmolL,
    double? baselineSleepEfficiencyPct,
  }) {
    return RiderBaselineBiomarkers(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      baselineHrvRmssdMs: baselineHrvRmssdMs ?? this.baselineHrvRmssdMs,
      baselineRhrBpm: baselineRhrBpm ?? this.baselineRhrBpm,
      baselineCkUL: baselineCkUL ?? this.baselineCkUL,
      baselineCortisolNmolL:
          baselineCortisolNmolL ?? this.baselineCortisolNmolL,
      baselineTestosteroneNmolL:
          baselineTestosteroneNmolL ?? this.baselineTestosteroneNmolL,
      baselineSleepEfficiencyPct:
          baselineSleepEfficiencyPct ?? this.baselineSleepEfficiencyPct,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'baselineHrvRmssdMs': baselineHrvRmssdMs,
      'baselineRhrBpm': baselineRhrBpm,
      'baselineCkUL': baselineCkUL,
      'baselineCortisolNmolL': baselineCortisolNmolL,
      'baselineTestosteroneNmolL': baselineTestosteroneNmolL,
      'baselineSleepEfficiencyPct': baselineSleepEfficiencyPct,
    };
  }

  factory RiderBaselineBiomarkers.fromJson(Map<String, dynamic> json) {
    return RiderBaselineBiomarkers(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      baselineHrvRmssdMs: (json['baselineHrvRmssdMs'] as num).toDouble(),
      baselineRhrBpm: (json['baselineRhrBpm'] as num).toInt(),
      baselineCkUL: (json['baselineCkUL'] as num).toDouble(),
      baselineCortisolNmolL: (json['baselineCortisolNmolL'] as num).toDouble(),
      baselineTestosteroneNmolL:
          (json['baselineTestosteroneNmolL'] as num).toDouble(),
      baselineSleepEfficiencyPct:
          (json['baselineSleepEfficiencyPct'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiderBaselineBiomarkers &&
        other.riderId == riderId &&
        other.riderName == riderName &&
        other.baselineHrvRmssdMs == baselineHrvRmssdMs &&
        other.baselineRhrBpm == baselineRhrBpm &&
        other.baselineCkUL == baselineCkUL &&
        other.baselineCortisolNmolL == baselineCortisolNmolL &&
        other.baselineTestosteroneNmolL == baselineTestosteroneNmolL &&
        other.baselineSleepEfficiencyPct == baselineSleepEfficiencyPct;
  }

  @override
  int get hashCode => Object.hash(
        riderId,
        riderName,
        baselineHrvRmssdMs,
        baselineRhrBpm,
        baselineCkUL,
        baselineCortisolNmolL,
        baselineTestosteroneNmolL,
        baselineSleepEfficiencyPct,
      );
}

/// Wpływ długiego transferu autokarem po etapie na sen, kortyzol i regenerację.
class BusTransferSleepImpact {
  final double transferDistanceKm;
  final int transferDurationMinutes;
  final double hotelArrivalHourDecimal;
  final int dinnerDelayMinutes;
  final double altitudeHotelMeters;
  final double roomNoiseOrHeatDisturbance;

  const BusTransferSleepImpact({
    required this.transferDistanceKm,
    required this.transferDurationMinutes,
    required this.hotelArrivalHourDecimal,
    required this.dinnerDelayMinutes,
    this.altitudeHotelMeters = 450.0,
    this.roomNoiseOrHeatDisturbance = 0.1,
  });

  TransferLogisticsSeverity get severity {
    if (transferDistanceKm < 20.0 && transferDurationMinutes < 30) {
      return TransferLogisticsSeverity.noTransfer;
    }
    if (transferDistanceKm < 75.0 && hotelArrivalHourDecimal <= 20.5) {
      return TransferLogisticsSeverity.shortTransfer;
    }
    if (transferDistanceKm < 150.0 && hotelArrivalHourDecimal <= 21.75) {
      return TransferLogisticsSeverity.moderateTransfer;
    }
    return TransferLogisticsSeverity.gruelingBusTransfer;
  }

  /// Utracone minuty snu z powodu późnego dojazdu i opóźnionej kolacji.
  int get sleepDurationPenaltyMinutes {
    final lateArrivalPenalty =
        math.max(0.0, (hotelArrivalHourDecimal - 20.0) * 28.0);
    final busFatiguePenalty = transferDurationMinutes * 0.14;
    final dinnerPenalty = dinnerDelayMinutes * 0.35;
    return (lateArrivalPenalty + busFatiguePenalty + dinnerPenalty)
        .round()
        .clamp(0, 160);
  }

  /// Redukcja jakości snu (0–38 pkt) uwzględniająca wibracje autokaru, wysokość
  /// hotelu powyżej 1600 m n.p.m. oraz hałas/temperaturę pokoju.
  double get sleepQualityPenaltyPoints {
    final distanceFactor = (transferDistanceKm / 250.0).clamp(0.0, 1.0) * 16.0;
    final lateFactor =
        math.max(0.0, hotelArrivalHourDecimal - 20.0).clamp(0.0, 4.0) * 3.5;
    final altitudeFactor =
        math.max(0.0, altitudeHotelMeters - 1600.0) / 1000.0 * 7.5;
    final roomFactor = roomNoiseOrHeatDisturbance.clamp(0.0, 1.0) * 10.0;
    return (distanceFactor + lateFactor + altitudeFactor + roomFactor)
        .clamp(0.0, 38.0);
  }

  /// Mnożnik nocnego wyrzutu kortyzolu spowodowany stresem logistycznym.
  double get cortisolSpikeMultiplier {
    final base = 1.0 + (sleepQualityPenaltyPoints / 120.0);
    return base.clamp(1.0, 1.32);
  }

  BusTransferSleepImpact copyWith({
    double? transferDistanceKm,
    int? transferDurationMinutes,
    double? hotelArrivalHourDecimal,
    int? dinnerDelayMinutes,
    double? altitudeHotelMeters,
    double? roomNoiseOrHeatDisturbance,
  }) {
    return BusTransferSleepImpact(
      transferDistanceKm: transferDistanceKm ?? this.transferDistanceKm,
      transferDurationMinutes:
          transferDurationMinutes ?? this.transferDurationMinutes,
      hotelArrivalHourDecimal:
          hotelArrivalHourDecimal ?? this.hotelArrivalHourDecimal,
      dinnerDelayMinutes: dinnerDelayMinutes ?? this.dinnerDelayMinutes,
      altitudeHotelMeters: altitudeHotelMeters ?? this.altitudeHotelMeters,
      roomNoiseOrHeatDisturbance:
          roomNoiseOrHeatDisturbance ?? this.roomNoiseOrHeatDisturbance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transferDistanceKm': transferDistanceKm,
      'transferDurationMinutes': transferDurationMinutes,
      'hotelArrivalHourDecimal': hotelArrivalHourDecimal,
      'dinnerDelayMinutes': dinnerDelayMinutes,
      'altitudeHotelMeters': altitudeHotelMeters,
      'roomNoiseOrHeatDisturbance': roomNoiseOrHeatDisturbance,
    };
  }

  factory BusTransferSleepImpact.fromJson(Map<String, dynamic> json) {
    return BusTransferSleepImpact(
      transferDistanceKm: (json['transferDistanceKm'] as num).toDouble(),
      transferDurationMinutes: (json['transferDurationMinutes'] as num).toInt(),
      hotelArrivalHourDecimal:
          (json['hotelArrivalHourDecimal'] as num).toDouble(),
      dinnerDelayMinutes: (json['dinnerDelayMinutes'] as num).toInt(),
      altitudeHotelMeters:
          (json['altitudeHotelMeters'] as num?)?.toDouble() ?? 450.0,
      roomNoiseOrHeatDisturbance:
          (json['roomNoiseOrHeatDisturbance'] as num?)?.toDouble() ?? 0.1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusTransferSleepImpact &&
        other.transferDistanceKm == transferDistanceKm &&
        other.transferDurationMinutes == transferDurationMinutes &&
        other.hotelArrivalHourDecimal == hotelArrivalHourDecimal &&
        other.dinnerDelayMinutes == dinnerDelayMinutes &&
        other.altitudeHotelMeters == altitudeHotelMeters &&
        other.roomNoiseOrHeatDisturbance == roomNoiseOrHeatDisturbance;
  }

  @override
  int get hashCode => Object.hash(
        transferDistanceKm,
        transferDurationMinutes,
        hotelArrivalHourDecimal,
        dinnerDelayMinutes,
        altitudeHotelMeters,
        roomNoiseOrHeatDisturbance,
      );
}

/// Obciążenie kolarza z poprzedniego etapu będące wejściem do nocnej regeneracji.
class StageWorkloadInput {
  final int stageDay;
  final bool isRestDay;
  final double stageDistanceKm;
  final double elevationGainMeters;
  final double kilojoulesExpended;
  final double intensityFactor;
  final bool crashedOnStage;
  final double heatStressIndex;
  final bool recoveryProtocolApplied;
  final double recoveryProtocolEffectiveness;

  const StageWorkloadInput({
    required this.stageDay,
    this.isRestDay = false,
    required this.stageDistanceKm,
    required this.elevationGainMeters,
    required this.kilojoulesExpended,
    required this.intensityFactor,
    this.crashedOnStage = false,
    this.heatStressIndex = 0.2,
    this.recoveryProtocolApplied = false,
    this.recoveryProtocolEffectiveness = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'stageDay': stageDay,
      'isRestDay': isRestDay,
      'stageDistanceKm': stageDistanceKm,
      'elevationGainMeters': elevationGainMeters,
      'kilojoulesExpended': kilojoulesExpended,
      'intensityFactor': intensityFactor,
      'crashedOnStage': crashedOnStage,
      'heatStressIndex': heatStressIndex,
      'recoveryProtocolApplied': recoveryProtocolApplied,
      'recoveryProtocolEffectiveness': recoveryProtocolEffectiveness,
    };
  }

  factory StageWorkloadInput.fromJson(Map<String, dynamic> json) {
    return StageWorkloadInput(
      stageDay: (json['stageDay'] as num).toInt(),
      isRestDay: json['isRestDay'] as bool? ?? false,
      stageDistanceKm: (json['stageDistanceKm'] as num).toDouble(),
      elevationGainMeters: (json['elevationGainMeters'] as num).toDouble(),
      kilojoulesExpended: (json['kilojoulesExpended'] as num).toDouble(),
      intensityFactor: (json['intensityFactor'] as num).toDouble(),
      crashedOnStage: json['crashedOnStage'] as bool? ?? false,
      heatStressIndex: (json['heatStressIndex'] as num?)?.toDouble() ?? 0.2,
      recoveryProtocolApplied:
          json['recoveryProtocolApplied'] as bool? ?? false,
      recoveryProtocolEffectiveness:
          (json['recoveryProtocolEffectiveness'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Poranny pomiar biomarkerów kolarza wykonany przez lekarza drużyny przed etapem.
class MorningBiomarkerSample {
  final String riderId;
  final String riderName;
  final int stageDay;
  final double hrvRmssdMs;
  final double hrvZScore;
  final int restingHeartRateBpm;
  final int rhrDeltaBpm;
  final double creatineKinaseUL;
  final double cortisolNmolL;
  final double testosteroneNmolL;
  final double cortisolToTestosteroneRatio;
  final double sleepQualityScore;
  final int deepAndRemSleepMinutes;
  final double totalSleepHours;
  final BusTransferSleepImpact transferImpact;
  final double readinessScore;
  final BiomarkerReadinessStatus readinessStatus;
  final MedicalInterventionRecommendation recommendation;
  final int dayFormModifier;
  final double maxSustainablePowerFactor;
  final double injuryAndIllnessRiskPct;

  const MorningBiomarkerSample({
    required this.riderId,
    required this.riderName,
    required this.stageDay,
    required this.hrvRmssdMs,
    required this.hrvZScore,
    required this.restingHeartRateBpm,
    required this.rhrDeltaBpm,
    required this.creatineKinaseUL,
    required this.cortisolNmolL,
    required this.testosteroneNmolL,
    required this.cortisolToTestosteroneRatio,
    required this.sleepQualityScore,
    required this.deepAndRemSleepMinutes,
    required this.totalSleepHours,
    required this.transferImpact,
    required this.readinessScore,
    required this.readinessStatus,
    required this.recommendation,
    required this.dayFormModifier,
    required this.maxSustainablePowerFactor,
    required this.injuryAndIllnessRiskPct,
  });

  bool get isElevatedCkAlert => creatineKinaseUL >= 850.0;
  bool get isCatabolicCrisis => cortisolToTestosteroneRatio >= 0.065;
  bool get isSleepDeprived => sleepQualityScore < 60.0 || totalSleepHours < 6.2;

  MorningBiomarkerSample copyWith({
    String? riderId,
    String? riderName,
    int? stageDay,
    double? hrvRmssdMs,
    double? hrvZScore,
    int? restingHeartRateBpm,
    int? rhrDeltaBpm,
    double? creatineKinaseUL,
    double? cortisolNmolL,
    double? testosteroneNmolL,
    double? cortisolToTestosteroneRatio,
    double? sleepQualityScore,
    int? deepAndRemSleepMinutes,
    double? totalSleepHours,
    BusTransferSleepImpact? transferImpact,
    double? readinessScore,
    BiomarkerReadinessStatus? readinessStatus,
    MedicalInterventionRecommendation? recommendation,
    int? dayFormModifier,
    double? maxSustainablePowerFactor,
    double? injuryAndIllnessRiskPct,
  }) {
    return MorningBiomarkerSample(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      stageDay: stageDay ?? this.stageDay,
      hrvRmssdMs: hrvRmssdMs ?? this.hrvRmssdMs,
      hrvZScore: hrvZScore ?? this.hrvZScore,
      restingHeartRateBpm: restingHeartRateBpm ?? this.restingHeartRateBpm,
      rhrDeltaBpm: rhrDeltaBpm ?? this.rhrDeltaBpm,
      creatineKinaseUL: creatineKinaseUL ?? this.creatineKinaseUL,
      cortisolNmolL: cortisolNmolL ?? this.cortisolNmolL,
      testosteroneNmolL: testosteroneNmolL ?? this.testosteroneNmolL,
      cortisolToTestosteroneRatio:
          cortisolToTestosteroneRatio ?? this.cortisolToTestosteroneRatio,
      sleepQualityScore: sleepQualityScore ?? this.sleepQualityScore,
      deepAndRemSleepMinutes:
          deepAndRemSleepMinutes ?? this.deepAndRemSleepMinutes,
      totalSleepHours: totalSleepHours ?? this.totalSleepHours,
      transferImpact: transferImpact ?? this.transferImpact,
      readinessScore: readinessScore ?? this.readinessScore,
      readinessStatus: readinessStatus ?? this.readinessStatus,
      recommendation: recommendation ?? this.recommendation,
      dayFormModifier: dayFormModifier ?? this.dayFormModifier,
      maxSustainablePowerFactor:
          maxSustainablePowerFactor ?? this.maxSustainablePowerFactor,
      injuryAndIllnessRiskPct:
          injuryAndIllnessRiskPct ?? this.injuryAndIllnessRiskPct,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'stageDay': stageDay,
      'hrvRmssdMs': hrvRmssdMs,
      'hrvZScore': hrvZScore,
      'restingHeartRateBpm': restingHeartRateBpm,
      'rhrDeltaBpm': rhrDeltaBpm,
      'creatineKinaseUL': creatineKinaseUL,
      'cortisolNmolL': cortisolNmolL,
      'testosteroneNmolL': testosteroneNmolL,
      'cortisolToTestosteroneRatio': cortisolToTestosteroneRatio,
      'sleepQualityScore': sleepQualityScore,
      'deepAndRemSleepMinutes': deepAndRemSleepMinutes,
      'totalSleepHours': totalSleepHours,
      'transferImpact': transferImpact.toJson(),
      'readinessScore': readinessScore,
      'readinessStatus': readinessStatus.toJson(),
      'recommendation': recommendation.toJson(),
      'dayFormModifier': dayFormModifier,
      'maxSustainablePowerFactor': maxSustainablePowerFactor,
      'injuryAndIllnessRiskPct': injuryAndIllnessRiskPct,
    };
  }

  factory MorningBiomarkerSample.fromJson(Map<String, dynamic> json) {
    return MorningBiomarkerSample(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      stageDay: (json['stageDay'] as num).toInt(),
      hrvRmssdMs: (json['hrvRmssdMs'] as num).toDouble(),
      hrvZScore: (json['hrvZScore'] as num).toDouble(),
      restingHeartRateBpm: (json['restingHeartRateBpm'] as num).toInt(),
      rhrDeltaBpm: (json['rhrDeltaBpm'] as num).toInt(),
      creatineKinaseUL: (json['creatineKinaseUL'] as num).toDouble(),
      cortisolNmolL: (json['cortisolNmolL'] as num).toDouble(),
      testosteroneNmolL: (json['testosteroneNmolL'] as num).toDouble(),
      cortisolToTestosteroneRatio:
          (json['cortisolToTestosteroneRatio'] as num).toDouble(),
      sleepQualityScore: (json['sleepQualityScore'] as num).toDouble(),
      deepAndRemSleepMinutes: (json['deepAndRemSleepMinutes'] as num).toInt(),
      totalSleepHours: (json['totalSleepHours'] as num).toDouble(),
      transferImpact: BusTransferSleepImpact.fromJson(
        json['transferImpact'] as Map<String, dynamic>,
      ),
      readinessScore: (json['readinessScore'] as num).toDouble(),
      readinessStatus: BiomarkerReadinessStatus.fromJson(
        json['readinessStatus'] as String,
      ),
      recommendation: MedicalInterventionRecommendation.fromJson(
        json['recommendation'] as String,
      ),
      dayFormModifier: (json['dayFormModifier'] as num).toInt(),
      maxSustainablePowerFactor:
          (json['maxSustainablePowerFactor'] as num).toDouble(),
      injuryAndIllnessRiskPct:
          (json['injuryAndIllnessRiskPct'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MorningBiomarkerSample &&
        other.riderId == riderId &&
        other.stageDay == stageDay &&
        other.hrvRmssdMs == hrvRmssdMs &&
        other.restingHeartRateBpm == restingHeartRateBpm &&
        other.creatineKinaseUL == creatineKinaseUL &&
        other.cortisolToTestosteroneRatio == cortisolToTestosteroneRatio &&
        other.sleepQualityScore == sleepQualityScore &&
        other.readinessScore == readinessScore;
  }

  @override
  int get hashCode => Object.hash(
        riderId,
        stageDay,
        hrvRmssdMs,
        restingHeartRateBpm,
        creatineKinaseUL,
        cortisolToTestosteroneRatio,
        sleepQualityScore,
        readinessScore,
      );
}

/// Zbiorczy raport poranny dla całej 8-osobowej drużyny na Wielki Tour.
class GrandTourTeamMorningReport {
  final String tourId;
  final String tourName;
  final int stageDay;
  final GrandTourWeekPhase weekPhase;
  final List<MorningBiomarkerSample> rosterSamples;
  final double teamAverageReadiness;
  final double teamAverageHrvMs;
  final double teamAverageCkUL;
  final double teamAverageSleepScore;
  final List<String> criticalAlertRiders;
  final List<String> peakReadyRiders;
  final String medicalDirectorSummary;

  const GrandTourTeamMorningReport({
    required this.tourId,
    required this.tourName,
    required this.stageDay,
    required this.weekPhase,
    required this.rosterSamples,
    required this.teamAverageReadiness,
    required this.teamAverageHrvMs,
    required this.teamAverageCkUL,
    required this.teamAverageSleepScore,
    required this.criticalAlertRiders,
    required this.peakReadyRiders,
    required this.medicalDirectorSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'tourId': tourId,
      'tourName': tourName,
      'stageDay': stageDay,
      'weekPhase': weekPhase.toJson(),
      'rosterSamples': rosterSamples.map((e) => e.toJson()).toList(),
      'teamAverageReadiness': teamAverageReadiness,
      'teamAverageHrvMs': teamAverageHrvMs,
      'teamAverageCkUL': teamAverageCkUL,
      'teamAverageSleepScore': teamAverageSleepScore,
      'criticalAlertRiders': criticalAlertRiders,
      'peakReadyRiders': peakReadyRiders,
      'medicalDirectorSummary': medicalDirectorSummary,
    };
  }

  factory GrandTourTeamMorningReport.fromJson(Map<String, dynamic> json) {
    return GrandTourTeamMorningReport(
      tourId: json['tourId'] as String,
      tourName: json['tourName'] as String,
      stageDay: (json['stageDay'] as num).toInt(),
      weekPhase: GrandTourWeekPhase.fromJson(json['weekPhase'] as String),
      rosterSamples: (json['rosterSamples'] as List<dynamic>)
          .map((e) => MorningBiomarkerSample.fromJson(e as Map<String, dynamic>))
          .toList(),
      teamAverageReadiness: (json['teamAverageReadiness'] as num).toDouble(),
      teamAverageHrvMs: (json['teamAverageHrvMs'] as num).toDouble(),
      teamAverageCkUL: (json['teamAverageCkUL'] as num).toDouble(),
      teamAverageSleepScore: (json['teamAverageSleepScore'] as num).toDouble(),
      criticalAlertRiders: (json['criticalAlertRiders'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      peakReadyRiders: (json['peakReadyRiders'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      medicalDirectorSummary: json['medicalDirectorSummary'] as String,
    );
  }
}

/// Główny model codziennej diagnostyki regeneracyjnej Grand Tour Nightly HRV & Recovery Biomarkers.
///
/// Każdego ranka przed etapem sztab medyczny mierzy u wszystkich 8 kolarzy:
/// - nocną zmienność rytmu zatokowego **HRV (rMSSD w ms)**,
/// - tętno spoczynkowe **RHR (bpm)**,
/// - poziom uszkodzeń mięśniowych **Kinazy Kreatynowej (CK w U/L)**,
/// - wskaźnik stresu hormonalnego **Kortyzol / Testosteron**,
/// - jakość i architekturę snu (uwzględniającą długie transfery autokarem).
class GrandTourNightlyHrvAndPhysioModel {
  static const int grandTourSquadSize = 8;
  static const int maxGrandTourDays = 21;

  final String tourId;
  final String tourName;
  final int currentStageDay;
  final Map<String, RiderBaselineBiomarkers> baselines;
  final Map<int, GrandTourTeamMorningReport> historyByDay;

  const GrandTourNightlyHrvAndPhysioModel({
    required this.tourId,
    required this.tourName,
    required this.currentStageDay,
    required this.baselines,
    this.historyByDay = const {},
  });

  /// Tworzy model dla 8-osobowego składu na Wielki Tour (z zachowaniem limitu 8 kolarzy).
  factory GrandTourNightlyHrvAndPhysioModel.initializeSquad({
    required String tourId,
    required String tourName,
    required List<RiderBaselineBiomarkers> squadBaselines,
  }) {
    final capped = squadBaselines.take(grandTourSquadSize).toList();
    final map = <String, RiderBaselineBiomarkers>{
      for (final b in capped) b.riderId: b,
    };
    return GrandTourNightlyHrvAndPhysioModel(
      tourId: tourId,
      tourName: tourName,
      currentStageDay: 1,
      baselines: Map.unmodifiable(map),
      historyByDay: const {},
    );
  }

  /// Oblicza 7-dniową średnią kroczącą HRV (rMSSD) kolarza jako lokalny punkt odniesienia.
  double getSevenDayHrvRollingAverage(String riderId, int upToDay) {
    final baseline = baselines[riderId];
    if (baseline == null) return 75.0;

    final startDay = math.max(1, upToDay - 6);
    final values = <double>[];
    for (int d = startDay; d <= upToDay; d++) {
      final report = historyByDay[d];
      if (report == null) continue;
      for (final sample in report.rosterSamples) {
        if (sample.riderId == riderId) {
          values.add(sample.hrvRmssdMs);
        }
      }
    }
    if (values.isEmpty) return baseline.baselineHrvRmssdMs;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Zwraca chronologiczną historię porannych pomiarów dla wybranego kolarza.
  List<MorningBiomarkerSample> getRiderTrend(String riderId) {
    final days = historyByDay.keys.toList()..sort();
    final trend = <MorningBiomarkerSample>[];
    for (final day in days) {
      final report = historyByDay[day];
      if (report == null) continue;
      for (final sample in report.rosterSamples) {
        if (sample.riderId == riderId) {
          trend.add(sample);
        }
      }
    }
    return List.unmodifiable(trend);
  }

  /// Sortuje kolarzy w danym dniu według wskaźnika gotowości fizjologicznej.
  List<MorningBiomarkerSample> getSquadReadinessRanking(int stageDay) {
    final report = historyByDay[stageDay];
    if (report == null) return const [];
    final sorted = List<MorningBiomarkerSample>.from(report.rosterSamples)
      ..sort((a, b) => b.readinessScore.compareTo(a.readinessScore));
    return List.unmodifiable(sorted);
  }

  /// Przeprowadza pełną nocną regenerację i poranny pomiar biomarkerów dla wszystkich
  /// kolarzy w składzie, zwracając zaktualizowany model oraz raport poranny.
  ({
    GrandTourNightlyHrvAndPhysioModel updatedModel,
    GrandTourTeamMorningReport report,
  }) evaluateNightlyRecoveryAndMorningCheck({
    required int stageDay,
    required Map<String, StageWorkloadInput> workloadsByRider,
    required BusTransferSleepImpact transferImpact,
    bool isRestDay = false,
    int seed = 42,
  }) {
    final clampedDay = stageDay.clamp(1, maxGrandTourDays);
    final weekPhase = GrandTourWeekPhase.fromStageDay(
      clampedDay,
      isRestDay: isRestDay,
    );
    final rng = math.Random(seed + clampedDay * 97);

    final samples = <MorningBiomarkerSample>[];
    for (final entry in baselines.entries) {
      final riderId = entry.key;
      final baseline = entry.value;
      final previousSample = _findLatestSampleBeforeDay(riderId, clampedDay);
      final workload = workloadsByRider[riderId] ??
          StageWorkloadInput(
            stageDay: clampedDay,
            isRestDay: isRestDay,
            stageDistanceKm: isRestDay ? 45.0 : 175.0,
            elevationGainMeters: isRestDay ? 350.0 : 2100.0,
            kilojoulesExpended: isRestDay ? 950.0 : 3400.0,
            intensityFactor: isRestDay ? 0.52 : 0.78,
          );

      final sample = _computeRiderMorningSample(
        baseline: baseline,
        previousSample: previousSample,
        workload: workload,
        transferImpact: transferImpact,
        stageDay: clampedDay,
        weekPhase: weekPhase,
        rng: rng,
      );
      samples.add(sample);
    }

    final count = samples.isEmpty ? 1 : samples.length;
    final avgReadiness =
        samples.fold<double>(0.0, (sum, s) => sum + s.readinessScore) / count;
    final avgHrv =
        samples.fold<double>(0.0, (sum, s) => sum + s.hrvRmssdMs) / count;
    final avgCk =
        samples.fold<double>(0.0, (sum, s) => sum + s.creatineKinaseUL) / count;
    final avgSleep =
        samples.fold<double>(0.0, (sum, s) => sum + s.sleepQualityScore) /
            count;

    final criticalAlerts = samples
        .where((s) =>
            s.readinessStatus ==
                BiomarkerReadinessStatus.criticalOvertrainingRisk ||
            s.readinessStatus ==
                BiomarkerReadinessStatus.sympatheticOverreaching)
        .map((s) => s.riderName)
        .toList(growable: false);

    final peakReady = samples
        .where((s) =>
            s.readinessStatus == BiomarkerReadinessStatus.peakSupercompensation)
        .map((s) => s.riderName)
        .toList(growable: false);

    final summary = _buildMedicalDirectorSummary(
      stageDay: clampedDay,
      weekPhase: weekPhase,
      avgReadiness: avgReadiness,
      avgSleep: avgSleep,
      transferImpact: transferImpact,
      criticalAlerts: criticalAlerts,
      peakReady: peakReady,
    );

    final report = GrandTourTeamMorningReport(
      tourId: tourId,
      tourName: tourName,
      stageDay: clampedDay,
      weekPhase: weekPhase,
      rosterSamples: List.unmodifiable(samples),
      teamAverageReadiness: double.parse(avgReadiness.toStringAsFixed(1)),
      teamAverageHrvMs: double.parse(avgHrv.toStringAsFixed(1)),
      teamAverageCkUL: double.parse(avgCk.toStringAsFixed(1)),
      teamAverageSleepScore: double.parse(avgSleep.toStringAsFixed(1)),
      criticalAlertRiders: List.unmodifiable(criticalAlerts),
      peakReadyRiders: List.unmodifiable(peakReady),
      medicalDirectorSummary: summary,
    );

    final nextHistory = Map<int, GrandTourTeamMorningReport>.from(historyByDay)
      ..[clampedDay] = report;

    final updatedModel = copyWith(
      currentStageDay: clampedDay,
      historyByDay: Map.unmodifiable(nextHistory),
    );

    return (updatedModel: updatedModel, report: report);
  }

  MorningBiomarkerSample? _findLatestSampleBeforeDay(
    String riderId,
    int stageDay,
  ) {
    final prevDays = historyByDay.keys.where((d) => d < stageDay).toList()
      ..sort();
    if (prevDays.isEmpty) return null;
    final lastReport = historyByDay[prevDays.last];
    if (lastReport == null) return null;
    for (final sample in lastReport.rosterSamples) {
      if (sample.riderId == riderId) return sample;
    }
    return null;
  }

  MorningBiomarkerSample _computeRiderMorningSample({
    required RiderBaselineBiomarkers baseline,
    required MorningBiomarkerSample? previousSample,
    required StageWorkloadInput workload,
    required BusTransferSleepImpact transferImpact,
    required int stageDay,
    required GrandTourWeekPhase weekPhase,
    required math.Random rng,
  }) {
    final recoveryMitigation = workload.recoveryProtocolApplied
        ? workload.recoveryProtocolEffectiveness.clamp(0.0, 1.0) * 0.28
        : 0.0;

    // 1. Jakość i czas snu (silnie modulowane transferem autokarem)
    final baseSleepHours = workload.isRestDay ? 8.8 : 8.1;
    final penaltyHours = transferImpact.sleepDurationPenaltyMinutes / 60.0;
    final noiseHours = (rng.nextDouble() - 0.5) * 0.4;
    final totalSleepHours = (baseSleepHours - penaltyHours + noiseHours)
        .clamp(4.6, 10.0);

    final rawSleepQuality = baseline.baselineSleepEfficiencyPct -
        transferImpact.sleepQualityPenaltyPoints -
        (workload.crashedOnStage ? 14.0 : 0.0) -
        (workload.heatStressIndex * 7.0) +
        (recoveryMitigation * 22.0) +
        ((rng.nextDouble() - 0.5) * 4.0);
    final sleepQualityScore = rawSleepQuality.clamp(22.0, 99.0);
    final deepAndRemMinutes =
        ((totalSleepHours * 60.0) * (0.28 + (sleepQualityScore / 450.0)))
            .round()
            .clamp(75, 290);

    // 2. Kinaza Kreatynowa (CK w U/L) — uszkodzenia włókien mięśniowych + półtrwanie
    final prevCk = previousSample?.creatineKinaseUL ?? baseline.baselineCkUL;
    final ckClearanceRate = workload.isRestDay
        ? (0.48 + recoveryMitigation * 0.4)
        : (0.26 + recoveryMitigation * 0.35);
    final retainedCk = prevCk * (1.0 - ckClearanceRate).clamp(0.2, 0.85);

    final mechanicalLoad = workload.isRestDay
        ? 35.0
        : (workload.kilojoulesExpended * 0.065) +
            (workload.elevationGainMeters * 0.085) +
            (workload.intensityFactor * 140.0);
    final crashSpike = workload.crashedOnStage ? 420.0 : 0.0;
    final rawCk = math.max(
      baseline.baselineCkUL * 0.85,
      retainedCk + mechanicalLoad + crashSpike,
    );
    final creatineKinaseUL = rawCk.clamp(80.0, 3200.0);

    // 3. Hormony: Kortyzol / Testosteron (katabolizm narastający w 2. i 3. tygodniu)
    final prevCortisol =
        previousSample?.cortisolNmolL ?? baseline.baselineCortisolNmolL;
    final prevTesto =
        previousSample?.testosteroneNmolL ?? baseline.baselineTestosteroneNmolL;

    final weekCatabolicFactor = switch (weekPhase) {
      GrandTourWeekPhase.week1Opening => 1.04,
      GrandTourWeekPhase.week2Attrition => 1.14,
      GrandTourWeekPhase.week3Survival => 1.24,
      GrandTourWeekPhase.restDay => 0.88,
    };

    final stageStressFactor = workload.isRestDay
        ? 0.84
        : (0.94 + workload.intensityFactor * 0.25) *
            transferImpact.cortisolSpikeMultiplier;
    final targetCortisol = baseline.baselineCortisolNmolL *
        weekCatabolicFactor *
        stageStressFactor *
        (1.0 - recoveryMitigation * 0.45);
    final cortisolNmolL =
        ((prevCortisol * 0.35) + (targetCortisol * 0.65)).clamp(220.0, 1150.0);

    final testoSuppression = switch (weekPhase) {
      GrandTourWeekPhase.week1Opening => 0.96,
      GrandTourWeekPhase.week2Attrition => 0.85,
      GrandTourWeekPhase.week3Survival => 0.74,
      GrandTourWeekPhase.restDay => 0.94,
    };
    final sleepTestoBoost = ((sleepQualityScore - 75.0) / 300.0);
    final targetTesto = baseline.baselineTestosteroneNmolL *
        (testoSuppression + sleepTestoBoost) *
        (1.0 + recoveryMitigation * 0.15);
    final testosteroneNmolL =
        ((prevTesto * 0.4) + (targetTesto * 0.6)).clamp(5.0, 35.0);
    final ctRatio = cortisolNmolL / testosteroneNmolL;

    // 4. Nocne HRV (rMSSD w ms) oraz Tętno Spoczynkowe (RHR)
    final sevenDayAvgHrv = getSevenDayHrvRollingAverage(
      baseline.riderId,
      stageDay - 1,
    );
    final sleepHrvFactor = 0.78 + (sleepQualityScore / 420.0);
    final ckHrvPenalty = ((creatineKinaseUL - baseline.baselineCkUL) / 2600.0)
        .clamp(0.0, 0.25);
    final hormonalPenalty =
        ((ctRatio - baseline.baselineCortisolToTestosteroneRatio) * 3.2)
            .clamp(-0.08, 0.24);
    final restBounce = workload.isRestDay ? 1.09 : 1.0;

    final hrvRaw = baseline.baselineHrvRmssdMs *
        sleepHrvFactor *
        (1.0 - ckHrvPenalty - hormonalPenalty) *
        restBounce *
        (1.0 + recoveryMitigation * 0.14) *
        (0.97 + rng.nextDouble() * 0.06);
    final hrvRmssdMs = hrvRaw.clamp(18.0, 185.0);

    final estimatedSd = math.max(5.5, sevenDayAvgHrv * 0.085);
    final hrvZScore = (hrvRmssdMs - sevenDayAvgHrv) / estimatedSd;

    final rhrDeltaRaw = ((-hrvZScore * 2.1) +
            ((100.0 - sleepQualityScore) * 0.08) +
            (workload.crashedOnStage ? 4.0 : 0.0))
        .round()
        .clamp(-5, 16);
    final restingHeartRateBpm =
        (baseline.baselineRhrBpm + rhrDeltaRaw).clamp(30, 82);

    // 5. Zbiorcza ocena gotowości (Readiness Score 0–100) i status
    final hrvComponent = (50.0 + hrvZScore * 14.0).clamp(10.0, 100.0) * 0.34;
    final sleepComponent = sleepQualityScore * 0.26;
    final ckComponent =
        (100.0 - ((creatineKinaseUL - 150.0) / 18.0)).clamp(10.0, 100.0) * 0.22;
    final hormoneComponent =
        (100.0 - ((ctRatio - 0.025) * 1450.0)).clamp(10.0, 100.0) * 0.18;

    final readinessScore =
        (hrvComponent + sleepComponent + ckComponent + hormoneComponent)
            .clamp(5.0, 99.0);

    final readinessStatus = _classifyReadiness(
      readinessScore: readinessScore,
      hrvZScore: hrvZScore,
      rhrDelta: rhrDeltaRaw,
      ckUL: creatineKinaseUL,
      ctRatio: ctRatio,
    );

    final recommendation = _recommendIntervention(
      status: readinessStatus,
      sleepQuality: sleepQualityScore,
      ckUL: creatineKinaseUL,
    );

    final dayFormModifier = _mapReadinessToDayForm(readinessScore);
    final maxPowerFactor = (0.87 + (readinessScore / 625.0)).clamp(0.87, 1.03);
    final illnessRisk = (100.0 - readinessScore) *
        (weekPhase == GrandTourWeekPhase.week3Survival ? 0.65 : 0.42);

    return MorningBiomarkerSample(
      riderId: baseline.riderId,
      riderName: baseline.riderName,
      stageDay: stageDay,
      hrvRmssdMs: double.parse(hrvRmssdMs.toStringAsFixed(1)),
      hrvZScore: double.parse(hrvZScore.toStringAsFixed(2)),
      restingHeartRateBpm: restingHeartRateBpm,
      rhrDeltaBpm: rhrDeltaRaw,
      creatineKinaseUL: double.parse(creatineKinaseUL.toStringAsFixed(1)),
      cortisolNmolL: double.parse(cortisolNmolL.toStringAsFixed(1)),
      testosteroneNmolL: double.parse(testosteroneNmolL.toStringAsFixed(2)),
      cortisolToTestosteroneRatio: double.parse(ctRatio.toStringAsFixed(4)),
      sleepQualityScore: double.parse(sleepQualityScore.toStringAsFixed(1)),
      deepAndRemSleepMinutes: deepAndRemMinutes,
      totalSleepHours: double.parse(totalSleepHours.toStringAsFixed(2)),
      transferImpact: transferImpact,
      readinessScore: double.parse(readinessScore.toStringAsFixed(1)),
      readinessStatus: readinessStatus,
      recommendation: recommendation,
      dayFormModifier: dayFormModifier,
      maxSustainablePowerFactor:
          double.parse(maxPowerFactor.toStringAsFixed(3)),
      injuryAndIllnessRiskPct:
          double.parse(illnessRisk.clamp(2.0, 92.0).toStringAsFixed(1)),
    );
  }

  BiomarkerReadinessStatus _classifyReadiness({
    required double readinessScore,
    required double hrvZScore,
    required int rhrDelta,
    required double ckUL,
    required double ctRatio,
  }) {
    if (readinessScore >= 84.0 && hrvZScore >= 0.4) {
      return BiomarkerReadinessStatus.peakSupercompensation;
    }
    if (readinessScore >= 67.0 && ckUL < 1050.0) {
      return BiomarkerReadinessStatus.optimalRecovery;
    }
    if (readinessScore < 42.0 || (ckUL >= 1500.0 && ctRatio >= 0.07)) {
      return BiomarkerReadinessStatus.criticalOvertrainingRisk;
    }
    if (hrvZScore <= -1.2 && rhrDelta >= 5) {
      return BiomarkerReadinessStatus.sympatheticOverreaching;
    }
    return BiomarkerReadinessStatus.parasympatheticFatigue;
  }

  MedicalInterventionRecommendation _recommendIntervention({
    required BiomarkerReadinessStatus status,
    required double sleepQuality,
    required double ckUL,
  }) {
    switch (status) {
      case BiomarkerReadinessStatus.peakSupercompensation:
      case BiomarkerReadinessStatus.optimalRecovery:
        if (sleepQuality < 62.0) {
          return MedicalInterventionRecommendation.sleepHygieneAndMelatonin;
        }
        return MedicalInterventionRecommendation.normalRaceLoad;
      case BiomarkerReadinessStatus.parasympatheticFatigue:
        if (ckUL >= 900.0) {
          return MedicalInterventionRecommendation.aggressiveRecoveryProtocol;
        }
        return MedicalInterventionRecommendation.protectedDomestiqueDuty;
      case BiomarkerReadinessStatus.sympatheticOverreaching:
        return MedicalInterventionRecommendation.grupettoSurvivalMode;
      case BiomarkerReadinessStatus.criticalOvertrainingRisk:
        return MedicalInterventionRecommendation.medicalWithdrawalMonitor;
    }
  }

  int _mapReadinessToDayForm(double readinessScore) {
    if (readinessScore >= 88.0) return 3;
    if (readinessScore >= 78.0) return 2;
    if (readinessScore >= 68.0) return 1;
    if (readinessScore >= 56.0) return 0;
    if (readinessScore >= 46.0) return -1;
    if (readinessScore >= 36.0) return -2;
    return -3;
  }

  String _buildMedicalDirectorSummary({
    required int stageDay,
    required GrandTourWeekPhase weekPhase,
    required double avgReadiness,
    required double avgSleep,
    required BusTransferSleepImpact transferImpact,
    required List<String> criticalAlerts,
    required List<String> peakReady,
  }) {
    final buffer = StringBuffer()
      ..write('Etap $stageDay (${weekPhase.displayName}): ')
      ..write('Średnia gotowość ${avgReadiness.toStringAsFixed(1)}/100, ')
      ..write('sen ${avgSleep.toStringAsFixed(1)}/100 ');
    if (transferImpact.severity ==
        TransferLogisticsSeverity.gruelingBusTransfer) {
      buffer.write('[Ciężki transfer autokarem obniżył regenerację]. ');
    }
    if (criticalAlerts.isNotEmpty) {
      buffer.write('Alarm medyczny: ${criticalAlerts.join(', ')}. ');
    }
    if (peakReady.isNotEmpty) {
      buffer.write('Superkompensacja: ${peakReady.join(', ')}.');
    }
    return buffer.toString().trim();
  }

  GrandTourNightlyHrvAndPhysioModel copyWith({
    String? tourId,
    String? tourName,
    int? currentStageDay,
    Map<String, RiderBaselineBiomarkers>? baselines,
    Map<int, GrandTourTeamMorningReport>? historyByDay,
  }) {
    return GrandTourNightlyHrvAndPhysioModel(
      tourId: tourId ?? this.tourId,
      tourName: tourName ?? this.tourName,
      currentStageDay: currentStageDay ?? this.currentStageDay,
      baselines: baselines ?? this.baselines,
      historyByDay: historyByDay ?? this.historyByDay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tourId': tourId,
      'tourName': tourName,
      'currentStageDay': currentStageDay,
      'baselines': baselines.map((k, v) => MapEntry(k, v.toJson())),
      'historyByDay':
          historyByDay.map((k, v) => MapEntry(k.toString(), v.toJson())),
    };
  }

  factory GrandTourNightlyHrvAndPhysioModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawBaselines = json['baselines'] as Map<String, dynamic>;
    final parsedBaselines = rawBaselines.map(
      (k, v) => MapEntry(
        k,
        RiderBaselineBiomarkers.fromJson(v as Map<String, dynamic>),
      ),
    );

    final rawHistory = json['historyByDay'] as Map<String, dynamic>? ?? {};
    final parsedHistory = rawHistory.map(
      (k, v) => MapEntry(
        int.parse(k),
        GrandTourTeamMorningReport.fromJson(v as Map<String, dynamic>),
      ),
    );

    return GrandTourNightlyHrvAndPhysioModel(
      tourId: json['tourId'] as String,
      tourName: json['tourName'] as String,
      currentStageDay: (json['currentStageDay'] as num).toInt(),
      baselines: Map.unmodifiable(parsedBaselines),
      historyByDay: Map.unmodifiable(parsedHistory),
    );
  }
}
