import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_health.dart';

/// Typ rzadkiego, dramatycznego zdarzenia losowego na trasie wyścigu.
enum ObstructionEventType {
  /// Wtargnięcie psa kibica na szosę wymagające gwałtownego ominięcia.
  spectatorDogIntrusion,

  /// Zablokowanie wąskiej górskiej drogi przez wóz/motocykl TV na stromym podjeździe.
  tvVehicleClimbObstruction;

  String toJson() => name;

  static ObstructionEventType fromJson(String value) {
    return ObstructionEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ObstructionEventType.spectatorDogIntrusion,
    );
  }

  String get labelPl {
    switch (this) {
      case ObstructionEventType.spectatorDogIntrusion:
        return 'Wtargnięcie psa kibica na szosę';
      case ObstructionEventType.tvVehicleClimbObstruction:
        return 'Blokada wozu TV na podjeździe (Mont Ventoux)';
    }
  }

  String get badgeCode {
    switch (this) {
      case ObstructionEventType.spectatorDogIntrusion:
        return 'DOG';
      case ObstructionEventType.tvVehicleClimbObstruction:
        return 'TV-VENTOUX';
    }
  }
}

/// Wynik reakcji kolarza na zdarzenie na szosie.
enum RiderObstructionOutcome {
  /// Czyste, refleksem wyratowane ominięcie przeszkody.
  agileEvasion,

  /// Gwałtowne hamowanie i utrata pędu bez upadku.
  emergencyBraking,

  /// Upadek lub kolizja po nieudanym ominięciu.
  crashOrCollision,

  /// Wypięcie buta z pedału i bieg pod górę z rowerem lub bez (incydent Mont Ventoux).
  unclippedRunningUphill;

  String toJson() => name;

  static RiderObstructionOutcome fromJson(String value) {
    return RiderObstructionOutcome.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RiderObstructionOutcome.emergencyBraking,
    );
  }

  String get labelPl {
    switch (this) {
      case RiderObstructionOutcome.agileEvasion:
        return 'Błyskawiczne ominięcie';
      case RiderObstructionOutcome.emergencyBraking:
        return 'Gwałtowne hamowanie';
      case RiderObstructionOutcome.crashOrCollision:
        return 'Kraksa / kolizja';
      case RiderObstructionOutcome.unclippedRunningUphill:
        return 'Bieg pod górę (wypięte pedały)';
    }
  }
}

/// Decyzja Kolegium Sędziów UCI w sprawie neutralizacji straty czasowej.
enum NeutralizationVerdictStatus {
  /// Pełna neutralizacja — przywrócenie czasu grupy sprzed incydentu.
  fullNeutralization,

  /// Częściowa korekta czasu (np. odliczenie samego postoju za pojazdem).
  partialTimeCredit,

  /// Brak neutralizacji — incydent traktowany jako zdarzenie wyścigowe.
  noNeutralization;

  String toJson() => name;

  static NeutralizationVerdictStatus fromJson(String value) {
    return NeutralizationVerdictStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NeutralizationVerdictStatus.noNeutralization,
    );
  }

  String get labelPl {
    switch (this) {
      case NeutralizationVerdictStatus.fullNeutralization:
        return 'Pełna neutralizacja straty GC';
      case NeutralizationVerdictStatus.partialTimeCredit:
        return 'Częściowa korekta czasu';
      case NeutralizationVerdictStatus.noNeutralization:
        return 'Brak neutralizacji (incydent wyścigowy)';
    }
  }
}

/// Dane kolarza wchodzącego w strefę dramatycznego zdarzenia na trasie.
class ObstructionRiderInput {
  final String riderId;
  final String riderName;
  final String teamId;
  final int bikeHandling;
  final int raceIq;
  final double currentSpeedKmh;
  final bool isRaceLeader;
  final bool isGcContender;
  final double gapBeforeIncidentSeconds;

  const ObstructionRiderInput({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.bikeHandling,
    required this.raceIq,
    required this.currentSpeedKmh,
    this.isRaceLeader = false,
    this.isGcContender = false,
    this.gapBeforeIncidentSeconds = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'bikeHandling': bikeHandling,
        'raceIq': raceIq,
        'currentSpeedKmh': currentSpeedKmh,
        'isRaceLeader': isRaceLeader,
        'isGcContender': isGcContender,
        'gapBeforeIncidentSeconds': gapBeforeIncidentSeconds,
      };

  factory ObstructionRiderInput.fromJson(Map<String, dynamic> json) {
    return ObstructionRiderInput(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      bikeHandling: (json['bikeHandling'] as num?)?.toInt() ?? 65,
      raceIq: (json['raceIq'] as num?)?.toInt() ?? 65,
      currentSpeedKmh: (json['currentSpeedKmh'] as num?)?.toDouble() ?? 35.0,
      isRaceLeader: json['isRaceLeader'] as bool? ?? false,
      isGcContender: json['isGcContender'] as bool? ?? false,
      gapBeforeIncidentSeconds:
          (json['gapBeforeIncidentSeconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Skutek incydentu dla pojedynczego kolarza.
class RiderObstructionImpact {
  final String riderId;
  final String riderName;
  final String teamId;
  final bool isRaceLeader;
  final RiderObstructionOutcome outcome;
  final double rawTimeLossSeconds;
  final double neutralizedTimeCreditSeconds;
  final double netGcTimeLossSeconds;
  final double wPrimePenaltyJoules;
  final double runningDistanceMeters;
  final bool bikeDamaged;
  final InjuryType? injuryType;
  final String notePl;

  const RiderObstructionImpact({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.isRaceLeader,
    required this.outcome,
    required this.rawTimeLossSeconds,
    required this.neutralizedTimeCreditSeconds,
    required this.netGcTimeLossSeconds,
    required this.wPrimePenaltyJoules,
    this.runningDistanceMeters = 0.0,
    this.bikeDamaged = false,
    this.injuryType,
    required this.notePl,
  });

  RiderObstructionImpact copyWith({
    double? neutralizedTimeCreditSeconds,
    double? netGcTimeLossSeconds,
    String? notePl,
  }) {
    return RiderObstructionImpact(
      riderId: riderId,
      riderName: riderName,
      teamId: teamId,
      isRaceLeader: isRaceLeader,
      outcome: outcome,
      rawTimeLossSeconds: rawTimeLossSeconds,
      neutralizedTimeCreditSeconds:
          neutralizedTimeCreditSeconds ?? this.neutralizedTimeCreditSeconds,
      netGcTimeLossSeconds: netGcTimeLossSeconds ?? this.netGcTimeLossSeconds,
      wPrimePenaltyJoules: wPrimePenaltyJoules,
      runningDistanceMeters: runningDistanceMeters,
      bikeDamaged: bikeDamaged,
      injuryType: injuryType,
      notePl: notePl ?? this.notePl,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'isRaceLeader': isRaceLeader,
        'outcome': outcome.toJson(),
        'rawTimeLossSeconds': rawTimeLossSeconds,
        'neutralizedTimeCreditSeconds': neutralizedTimeCreditSeconds,
        'netGcTimeLossSeconds': netGcTimeLossSeconds,
        'wPrimePenaltyJoules': wPrimePenaltyJoules,
        'runningDistanceMeters': runningDistanceMeters,
        'bikeDamaged': bikeDamaged,
        'injuryType': injuryType?.toJson(),
        'notePl': notePl,
      };

  factory RiderObstructionImpact.fromJson(Map<String, dynamic> json) {
    final injuryRaw = json['injuryType'] as String?;
    return RiderObstructionImpact(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      isRaceLeader: json['isRaceLeader'] as bool? ?? false,
      outcome: RiderObstructionOutcome.fromJson(
        json['outcome'] as String? ?? '',
      ),
      rawTimeLossSeconds:
          (json['rawTimeLossSeconds'] as num?)?.toDouble() ?? 0.0,
      neutralizedTimeCreditSeconds:
          (json['neutralizedTimeCreditSeconds'] as num?)?.toDouble() ?? 0.0,
      netGcTimeLossSeconds:
          (json['netGcTimeLossSeconds'] as num?)?.toDouble() ?? 0.0,
      wPrimePenaltyJoules:
          (json['wPrimePenaltyJoules'] as num?)?.toDouble() ?? 0.0,
      runningDistanceMeters:
          (json['runningDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      bikeDamaged: json['bikeDamaged'] as bool? ?? false,
      injuryType: injuryRaw != null ? InjuryType.fromJson(injuryRaw) : null,
      notePl: json['notePl'] as String? ?? '',
    );
  }
}

/// Formalna decyzja Kolegium Sędziów UCI o neutralizacji straty czasowej.
class CommissaireNeutralizationDecision {
  final String decisionId;
  final NeutralizationVerdictStatus status;
  final String uciArticleReference;
  final double totalTimeCreditedSeconds;
  final bool organizerVehicleFault;
  final String rationalePl;
  final DateTime issuedAt;

  const CommissaireNeutralizationDecision({
    required this.decisionId,
    required this.status,
    required this.uciArticleReference,
    required this.totalTimeCreditedSeconds,
    required this.organizerVehicleFault,
    required this.rationalePl,
    required this.issuedAt,
  });

  Map<String, dynamic> toJson() => {
        'decisionId': decisionId,
        'status': status.toJson(),
        'uciArticleReference': uciArticleReference,
        'totalTimeCreditedSeconds': totalTimeCreditedSeconds,
        'organizerVehicleFault': organizerVehicleFault,
        'rationalePl': rationalePl,
        'issuedAt': issuedAt.toIso8601String(),
      };

  factory CommissaireNeutralizationDecision.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommissaireNeutralizationDecision(
      decisionId: json['decisionId'] as String? ?? '',
      status: NeutralizationVerdictStatus.fromJson(
        json['status'] as String? ?? '',
      ),
      uciArticleReference:
          json['uciArticleReference'] as String? ?? 'UCI Art. 2.2.029',
      totalTimeCreditedSeconds:
          (json['totalTimeCreditedSeconds'] as num?)?.toDouble() ?? 0.0,
      organizerVehicleFault: json['organizerVehicleFault'] as bool? ?? false,
      rationalePl: json['rationalePl'] as String? ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Pełny raport dramatycznego zdarzenia losowego na trasie.
class DramaticObstructionEventReport {
  final String id;
  final ObstructionEventType eventType;
  final double kilometerMark;
  final double distanceToFinishKm;
  final double gradientPercent;
  final double roadWidthMeters;
  final List<RiderObstructionImpact> riderImpacts;
  final CommissaireNeutralizationDecision commissaireDecision;
  final String radioTourHeadlinePl;
  final String dramaticCommentaryPl;

  const DramaticObstructionEventReport({
    required this.id,
    required this.eventType,
    required this.kilometerMark,
    required this.distanceToFinishKm,
    required this.gradientPercent,
    required this.roadWidthMeters,
    required this.riderImpacts,
    required this.commissaireDecision,
    required this.radioTourHeadlinePl,
    required this.dramaticCommentaryPl,
  });

  bool get isNeutralized =>
      commissaireDecision.status != NeutralizationVerdictStatus.noNeutralization;

  bool get hasLeaderRunning => riderImpacts.any(
        (r) =>
            r.isRaceLeader &&
            r.outcome == RiderObstructionOutcome.unclippedRunningUphill,
      );

  double get maxRawLossSeconds {
    if (riderImpacts.isEmpty) return 0.0;
    return riderImpacts
        .map((r) => r.rawTimeLossSeconds)
        .reduce((a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventType': eventType.toJson(),
        'kilometerMark': kilometerMark,
        'distanceToFinishKm': distanceToFinishKm,
        'gradientPercent': gradientPercent,
        'roadWidthMeters': roadWidthMeters,
        'riderImpacts': riderImpacts.map((e) => e.toJson()).toList(),
        'commissaireDecision': commissaireDecision.toJson(),
        'radioTourHeadlinePl': radioTourHeadlinePl,
        'dramaticCommentaryPl': dramaticCommentaryPl,
      };

  factory DramaticObstructionEventReport.fromJson(Map<String, dynamic> json) {
    return DramaticObstructionEventReport(
      id: json['id'] as String? ?? '',
      eventType: ObstructionEventType.fromJson(
        json['eventType'] as String? ?? '',
      ),
      kilometerMark: (json['kilometerMark'] as num?)?.toDouble() ?? 0.0,
      distanceToFinishKm:
          (json['distanceToFinishKm'] as num?)?.toDouble() ?? 0.0,
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      roadWidthMeters: (json['roadWidthMeters'] as num?)?.toDouble() ?? 4.5,
      riderImpacts: (json['riderImpacts'] as List<dynamic>? ?? const [])
          .map(
            (e) => RiderObstructionImpact.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      commissaireDecision: CommissaireNeutralizationDecision.fromJson(
        json['commissaireDecision'] as Map<String, dynamic>? ?? const {},
      ),
      radioTourHeadlinePl: json['radioTourHeadlinePl'] as String? ?? '',
      dramaticCommentaryPl: json['dramaticCommentaryPl'] as String? ?? '',
    );
  }
}

/// Silnik rzadkich, dramatycznych zdarzeń losowych na trasie:
/// 1) Wtargnięcie psa kibica na szosę (test `bikeHandling`),
/// 2) Zablokowanie wąskiej górskiej drogi przez wóz TV na stromym podjeździe
///    (bieg lidera pod górę w stylu Mont Ventoux),
/// 3) Decyzja Kolegium Sędziów UCI o neutralizacji straty czasowej.
class SpectatorDogAndVehicleObstructionEvents {
  const SpectatorDogAndVehicleObstructionEvents();

  /// Bazowa szansa na wtargnięcie psa kibica na pojedynczym segmencie (rzadkie: ~1.8%).
  static const double baseDogIntrusionProbability = 0.018;

  /// Bazowa szansa na zablokowanie wąskiej drogi przez wóz TV na stromym podjeździe (~2.4%).
  static const double baseTvVehicleObstructionProbability = 0.024;

  /// Sprawdza, czy na danym segmencie etapu dochodzi do rzadkiego zdarzenia losowego.
  /// Zwraca `null`, jeśli przejazd przebiega bez zakłóceń.
  DramaticObstructionEventReport? rollRareSegmentEvent({
    required RaceStage stage,
    required StageSegment segment,
    required List<ObstructionRiderInput> riders,
    required int seed,
    double crowdDensityFactor = 1.0,
  }) {
    if (riders.isEmpty) return null;
    if (stage.stageType == StageType.individualTimeTrial ||
        stage.stageType == StageType.teamTimeTrial) {
      return null;
    }

    final rng = math.Random(seed ^ segment.index ^ stage.stageNumber * 31);
    final distanceToFinishKm = math.max(
      0.2,
      stage.totalDistanceKm - (segment.startKm + segment.lengthKm * 0.5),
    );
    final kmMark = _round1(segment.startKm + segment.lengthKm * 0.5);
    final gradient = segment.gradientPercent;
    final density = crowdDensityFactor.clamp(0.4, 2.2);

    // 1. Wąski, stromy podjazd górski -> szansa na blokadę wozu TV (styl Mont Ventoux)
    final isSteepClimb = gradient >= 6.5 && segment.isClimb;
    if (isSteepClimb) {
      final tvProb =
          (baseTvVehicleObstructionProbability * density).clamp(0.005, 0.09);
      if (rng.nextDouble() < tvProb) {
        return evaluateTvVehicleClimbObstruction(
          riders: riders,
          kilometerMark: kmMark,
          distanceToFinishKm: _round1(distanceToFinishKm),
          gradientPercent: _round1(gradient),
          roadWidthMeters: 3.4,
          seed: seed + 101,
        );
      }
    }

    // 2. Teren płaski / pagórkowaty / miasteczko -> szansa na wtargnięcie psa kibica
    if (gradient < 7.0) {
      final dogProb =
          (baseDogIntrusionProbability * density).clamp(0.004, 0.06);
      if (rng.nextDouble() < dogProb) {
        return evaluateSpectatorDogIntrusion(
          riders: riders,
          kilometerMark: kmMark,
          distanceToFinishKm: _round1(distanceToFinishKm),
          gradientPercent: _round1(gradient),
          roadWidthMeters: 6.2,
          seed: seed + 202,
        );
      }
    }

    return null;
  }

  /// Symuluje wtargnięcie psa kibica na szosę.
  /// Kolarze z wysokim `bikeHandling` (>= 82) wykonują gwałtowne ominięcie niemal bez straty.
  DramaticObstructionEventReport evaluateSpectatorDogIntrusion({
    required List<ObstructionRiderInput> riders,
    required double kilometerMark,
    required double distanceToFinishKm,
    double gradientPercent = 0.5,
    double roadWidthMeters = 6.2,
    int seed = 42,
  }) {
    final rng = math.Random(seed);
    final rawImpacts = <RiderObstructionImpact>[];

    for (final rider in riders) {
      final handling = rider.bikeHandling.clamp(1, 99);
      final iq = rider.raceIq.clamp(1, 99);
      final evasionScore =
          (handling * 0.78 + iq * 0.22) + (rng.nextDouble() * 14.0 - 7.0);

      if (evasionScore >= 76.0) {
        final microLoss = handling >= 88 ? 0.0 : _round1(0.4 + rng.nextDouble() * 1.1);
        rawImpacts.add(
          RiderObstructionImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            isRaceLeader: rider.isRaceLeader,
            outcome: RiderObstructionOutcome.agileEvasion,
            rawTimeLossSeconds: microLoss,
            neutralizedTimeCreditSeconds: 0.0,
            netGcTimeLossSeconds: microLoss,
            wPrimePenaltyJoules: 450.0,
            notePl:
                'Błyskawiczny unik i przeskok obok psa (bikeHandling $handling) — utrzymana równowaga!',
          ),
        );
      } else if (evasionScore >= 56.0) {
        final loss = _round1(3.0 + rng.nextDouble() * 5.0);
        rawImpacts.add(
          RiderObstructionImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            isRaceLeader: rider.isRaceLeader,
            outcome: RiderObstructionOutcome.emergencyBraking,
            rawTimeLossSeconds: loss,
            neutralizedTimeCreditSeconds: 0.0,
            netGcTimeLossSeconds: loss,
            wPrimePenaltyJoules: 1100.0,
            notePl:
                'Gwałtowne hamowanie przed psem kibica — pisk opon i utrata ${loss.toStringAsFixed(1)} s.',
          ),
        );
      } else {
        final crashLoss = _round1(22.0 + rng.nextDouble() * 24.0);
        final injured = rng.nextDouble() < 0.45;
        rawImpacts.add(
          RiderObstructionImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            isRaceLeader: rider.isRaceLeader,
            outcome: RiderObstructionOutcome.crashOrCollision,
            rawTimeLossSeconds: crashLoss,
            neutralizedTimeCreditSeconds: 0.0,
            netGcTimeLossSeconds: crashLoss,
            wPrimePenaltyJoules: 2400.0,
            bikeDamaged: rng.nextDouble() < 0.65,
            injuryType: injured ? InjuryType.roadRash : null,
            notePl:
                'Brak miejsca na ominięcie psa — upadek na asfalt i strata ${crashLoss.toStringAsFixed(1)} s!',
          ),
        );
      }
    }

    final decision = _evaluateCommissaireNeutralization(
      eventType: ObstructionEventType.spectatorDogIntrusion,
      impacts: rawImpacts,
      distanceToFinishKm: distanceToFinishKm,
      seed: seed,
    );

    final finalImpacts = _applyNeutralizationToImpacts(rawImpacts, decision);
    final crashCount = finalImpacts
        .where((i) => i.outcome == RiderObstructionOutcome.crashOrCollision)
        .length;

    return DramaticObstructionEventReport(
      id: 'dog_${kilometerMark.toStringAsFixed(1)}_$seed',
      eventType: ObstructionEventType.spectatorDogIntrusion,
      kilometerMark: kilometerMark,
      distanceToFinishKm: distanceToFinishKm,
      gradientPercent: gradientPercent,
      roadWidthMeters: roadWidthMeters,
      riderImpacts: finalImpacts,
      commissaireDecision: decision,
      radioTourHeadlinePl: crashCount > 0
          ? 'ALARM! Pies kibica wbiegł przed peleton na $kilometerMark km — $crashCount kraks!'
          : 'Pies na szosie ($kilometerMark km) — kolarze z wysokim bikeHandling uniknęli kraksy!',
      dramaticCommentaryPl:
          'Niesforny pies kibica zerwał się ze smyczy i wtargnął prosto pod koła jadącej grupy przy ${riders.isNotEmpty ? riders.first.currentSpeedKmh.toStringAsFixed(0) : "45"} km/h. '
          '${decision.rationalePl}',
    );
  }

  /// Symuluje zablokowanie wąskiej górskiej drogi przez wóz/motocykl TV na stromym podjeździe.
  /// Zmusza lidera do wypięcia buta z pedału i biegu pod górę (incydent w stylu Mont Ventoux!).
  DramaticObstructionEventReport evaluateTvVehicleClimbObstruction({
    required List<ObstructionRiderInput> riders,
    required double kilometerMark,
    required double distanceToFinishKm,
    double gradientPercent = 9.5,
    double roadWidthMeters = 3.4,
    int seed = 2016,
  }) {
    final rng = math.Random(seed);
    final rawImpacts = <RiderObstructionImpact>[];

    for (final rider in riders) {
      final isFrontAffected = rider.isRaceLeader ||
          rider.isGcContender ||
          rider.gapBeforeIncidentSeconds <= 8.0;

      if (isFrontAffected) {
        final runDist = _round1(85.0 + rng.nextDouble() * 95.0);
        final rawLoss = _round1(36.0 + rng.nextDouble() * 34.0);
        rawImpacts.add(
          RiderObstructionImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            isRaceLeader: rider.isRaceLeader,
            outcome: RiderObstructionOutcome.unclippedRunningUphill,
            rawTimeLossSeconds: rawLoss,
            neutralizedTimeCreditSeconds: 0.0,
            netGcTimeLossSeconds: rawLoss,
            wPrimePenaltyJoules: 3200.0,
            runningDistanceMeters: runDist,
            bikeDamaged: rider.isRaceLeader || rng.nextDouble() < 0.55,
            notePl:
                'Wóz TV zatarasował przejazd na ${gradientPercent.toStringAsFixed(1)}% — wypiął but z pedału i pobiegł pod górę ${runDist.toStringAsFixed(0)} m w stylu Mont Ventoux!',
          ),
        );
      } else {
        final delayLoss = _round1(12.0 + rng.nextDouble() * 14.0);
        rawImpacts.add(
          RiderObstructionImpact(
            riderId: rider.riderId,
            riderName: rider.riderName,
            teamId: rider.teamId,
            isRaceLeader: rider.isRaceLeader,
            outcome: RiderObstructionOutcome.emergencyBraking,
            rawTimeLossSeconds: delayLoss,
            neutralizedTimeCreditSeconds: 0.0,
            netGcTimeLossSeconds: delayLoss,
            wPrimePenaltyJoules: 1300.0,
            notePl:
                'Zator za zatrzymanym wozem transmisyjnym — chwilowy postój i strata ${delayLoss.toStringAsFixed(1)} s.',
          ),
        );
      }
    }

    final decision = _evaluateCommissaireNeutralization(
      eventType: ObstructionEventType.tvVehicleClimbObstruction,
      impacts: rawImpacts,
      distanceToFinishKm: distanceToFinishKm,
      seed: seed,
    );

    final finalImpacts = _applyNeutralizationToImpacts(rawImpacts, decision);
    final leaderName = riders
        .firstWhere(
          (r) => r.isRaceLeader,
          orElse: () => riders.first,
        )
        .riderName;

    return DramaticObstructionEventReport(
      id: 'tv_ventoux_${kilometerMark.toStringAsFixed(1)}_$seed',
      eventType: ObstructionEventType.tvVehicleClimbObstruction,
      kilometerMark: kilometerMark,
      distanceToFinishKm: distanceToFinishKm,
      gradientPercent: gradientPercent,
      roadWidthMeters: roadWidthMeters,
      riderImpacts: finalImpacts,
      commissaireDecision: decision,
      radioTourHeadlinePl:
          'SCENY JAK Z MONT VENTOUX! Wóz TV zablokował podjazd ($kilometerMark km) — $leaderName biegnie pod górę!',
      dramaticCommentaryPl:
          'Wąski górski szlak (${roadWidthMeters.toStringAsFixed(1)} m, nachylenie ${gradientPercent.toStringAsFixed(1)}%) całkowicie zablokowany przez wóz telewizyjny otoczony tłumem kibiców. '
          'Lider musiał wypiąć but z pedału i biec pod górę w blokach kolarskich! ${decision.rationalePl}',
    );
  }

  /// Ocenia wniosek zespołu / sytuację na trasie pod kątem neutralizacji czasu przez sędziów UCI.
  CommissaireNeutralizationDecision _evaluateCommissaireNeutralization({
    required ObstructionEventType eventType,
    required List<RiderObstructionImpact> impacts,
    required double distanceToFinishKm,
    required int seed,
  }) {
    final now = DateTime.now();

    if (eventType == ObstructionEventType.tvVehicleClimbObstruction) {
      final leaderBlocked = impacts.any((r) => r.isRaceLeader);
      final maxLoss = impacts.isEmpty
          ? 0.0
          : impacts
              .map((e) => e.rawTimeLossSeconds)
              .reduce((a, b) => a > b ? a : b);

      // Wóz organizatora/TV zablokował trasę — niemal pewna pełna neutralizacja (precedens Ventoux 2016)
      if (leaderBlocked || distanceToFinishKm <= 12.0) {
        return CommissaireNeutralizationDecision(
          decisionId: 'uci_neut_$seed',
          status: NeutralizationVerdictStatus.fullNeutralization,
          uciArticleReference: 'UCI Art. 2.2.029 / Precedens Mont Ventoux',
          totalTimeCreditedSeconds: _round1(maxLoss),
          organizerVehicleFault: true,
          rationalePl:
              'Kolegium Sędziów UCI orzekło PEŁNĄ NEUTRALIZACJĘ straty czasowej (wina pojazdu transmisji TV na wąskim podjeździe). Przywrócono czasy sprzed incydentu!',
          issuedAt: now,
        );
      }

      return CommissaireNeutralizationDecision(
        decisionId: 'uci_neut_$seed',
        status: NeutralizationVerdictStatus.partialTimeCredit,
        uciArticleReference: 'UCI Art. 2.2.029bis',
        totalTimeCreditedSeconds: _round1(maxLoss * 0.75),
        organizerVehicleFault: true,
        rationalePl:
            'Sędziowie UCI przyznali częściową korektę czasu (75% straty wywołanej przez wóz TV).',
        issuedAt: now,
      );
    }

    // Dla wtargnięcia psa kibica: zazwyczaj incydent wyścigowy, chyba że w ostatnich 3 km.
    if (distanceToFinishKm <= 3.0) {
      final maxLoss = impacts.isEmpty
          ? 0.0
          : impacts
              .map((e) => e.rawTimeLossSeconds)
              .reduce((a, b) => a > b ? a : b);
      return CommissaireNeutralizationDecision(
        decisionId: 'uci_neut_$seed',
        status: NeutralizationVerdictStatus.fullNeutralization,
        uciArticleReference: 'UCI Art. 2.6.027 (Reguła ostatnich 3 km)',
        totalTimeCreditedSeconds: _round1(maxLoss),
        organizerVehicleFault: false,
        rationalePl:
            'Incydent w strefie ochronnej ostatnich 3 km — sędziowie przyznali czas grupy sprzed zdarzenia.',
        issuedAt: now,
      );
    }

    return CommissaireNeutralizationDecision(
      decisionId: 'uci_neut_$seed',
      status: NeutralizationVerdictStatus.noNeutralization,
      uciArticleReference: 'UCI Art. 2.2.028',
      totalTimeCreditedSeconds: 0.0,
      organizerVehicleFault: false,
      rationalePl:
          'Wtargnięcie zwierzęcia kibica uznane za incydent wyścigowy — bez neutralizacji czasu.',
      issuedAt: now,
    );
  }

  List<RiderObstructionImpact> _applyNeutralizationToImpacts(
    List<RiderObstructionImpact> rawImpacts,
    CommissaireNeutralizationDecision decision,
  ) {
    if (decision.status == NeutralizationVerdictStatus.noNeutralization) {
      return rawImpacts;
    }

    return rawImpacts.map((impact) {
      if (decision.status == NeutralizationVerdictStatus.fullNeutralization) {
        return impact.copyWith(
          neutralizedTimeCreditSeconds: impact.rawTimeLossSeconds,
          netGcTimeLossSeconds: 0.0,
        );
      }
      final credit = _round1(impact.rawTimeLossSeconds * 0.75);
      final net = _round1(math.max(0.0, impact.rawTimeLossSeconds - credit));
      return impact.copyWith(
        neutralizedTimeCreditSeconds: credit,
        netGcTimeLossSeconds: net,
      );
    }).toList();
  }

  double _round1(double value) => (value * 10.0).round() / 10.0;
}

/// Stan Riverpod dla dramatycznych zdarzeń drogowych (pies kibica / wóz TV).
class SpectatorObstructionState {
  final List<DramaticObstructionEventReport> reports;
  final ObstructionEventType? activeFilter;
  final String? selectedReportId;
  final bool isSimulating;

  const SpectatorObstructionState({
    this.reports = const [],
    this.activeFilter,
    this.selectedReportId,
    this.isSimulating = false,
  });

  List<DramaticObstructionEventReport> get filteredReports {
    if (activeFilter == null) return reports;
    return reports.where((r) => r.eventType == activeFilter).toList();
  }

  DramaticObstructionEventReport? get selectedReport {
    final list = filteredReports;
    if (list.isEmpty) return null;
    if (selectedReportId == null) return list.first;
    return list.firstWhere(
      (r) => r.id == selectedReportId,
      orElse: () => list.first,
    );
  }

  SpectatorObstructionState copyWith({
    List<DramaticObstructionEventReport>? reports,
    ObstructionEventType? activeFilter,
    bool clearFilter = false,
    String? selectedReportId,
    bool? isSimulating,
  }) {
    return SpectatorObstructionState(
      reports: reports ?? this.reports,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      selectedReportId: selectedReportId ?? this.selectedReportId,
      isSimulating: isSimulating ?? this.isSimulating,
    );
  }
}

/// Notifier zarządzający symulacją i podglądem incydentów na trasie.
class SpectatorObstructionNotifier
    extends StateNotifier<SpectatorObstructionState> {
  final SpectatorDogAndVehicleObstructionEvents _engine;
  int _seedCounter = 100;

  SpectatorObstructionNotifier({
    SpectatorDogAndVehicleObstructionEvents? engine,
  })  : _engine = engine ?? const SpectatorDogAndVehicleObstructionEvents(),
        super(const SpectatorObstructionState());

  void setFilter(ObstructionEventType? filter) {
    state = state.copyWith(
      activeFilter: filter,
      clearFilter: filter == null,
    );
  }

  void selectReport(String reportId) {
    state = state.copyWith(selectedReportId: reportId);
  }

  void triggerDogIntrusionDemo(List<ObstructionRiderInput> riders) {
    if (riders.isEmpty || state.isSimulating) return;
    state = state.copyWith(isSimulating: true);
    _seedCounter += 17;
    final report = _engine.evaluateSpectatorDogIntrusion(
      riders: riders,
      kilometerMark: 118.4,
      distanceToFinishKm: 24.6,
      seed: _seedCounter,
    );
    state = state.copyWith(
      reports: [report, ...state.reports],
      selectedReportId: report.id,
      isSimulating: false,
    );
  }

  void triggerTvVehicleVentouxDemo(List<ObstructionRiderInput> riders) {
    if (riders.isEmpty || state.isSimulating) return;
    state = state.copyWith(isSimulating: true);
    _seedCounter += 29;
    final report = _engine.evaluateTvVehicleClimbObstruction(
      riders: riders,
      kilometerMark: 171.2,
      distanceToFinishKm: 1.4,
      gradientPercent: 10.2,
      roadWidthMeters: 3.3,
      seed: _seedCounter,
    );
    state = state.copyWith(
      reports: [report, ...state.reports],
      selectedReportId: report.id,
      isSimulating: false,
    );
  }
}

final spectatorObstructionProvider = StateNotifierProvider<
    SpectatorObstructionNotifier, SpectatorObstructionState>(
  (ref) => SpectatorObstructionNotifier(),
);

/// Produkcyjny panel UI prezentujący rzadkie zdarzenia losowe (pies kibica,
/// blokada wozu TV w stylu Mont Ventoux oraz decyzję sędziów o neutralizacji).
class SpectatorDogAndVehicleObstructionPanel extends ConsumerWidget {
  final List<ObstructionRiderInput> sampleRiders;

  const SpectatorDogAndVehicleObstructionPanel({
    super.key,
    this.sampleRiders = _defaultRiders,
  });

  static const List<ObstructionRiderInput> _defaultRiders = [
    ObstructionRiderInput(
      riderId: 'r_leader',
      riderName: 'T. Pogačar-AI',
      teamId: 'UAD',
      bikeHandling: 91,
      raceIq: 94,
      currentSpeedKmh: 19.5,
      isRaceLeader: true,
      isGcContender: true,
    ),
    ObstructionRiderInput(
      riderId: 'r_dom',
      riderName: 'K. Majka-AI',
      teamId: 'UAD',
      bikeHandling: 79,
      raceIq: 85,
      currentSpeedKmh: 19.2,
      isGcContender: true,
      gapBeforeIncidentSeconds: 2.0,
    ),
    ObstructionRiderInput(
      riderId: 'r_sprinter',
      riderName: 'M. Kwiatkowski-AI',
      teamId: 'IGD',
      bikeHandling: 54,
      raceIq: 82,
      currentSpeedKmh: 46.0,
      gapBeforeIncidentSeconds: 12.0,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obsState = ref.watch(spectatorObstructionProvider);
    final notifier = ref.read(spectatorObstructionProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isWide = constraints.maxWidth >= 1000;
        final selected = obsState.selectedReport;

        return Container(
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isCompact, obsState, notifier),
                const SizedBox(height: 14),
                _buildFilterBar(obsState, notifier),
                const SizedBox(height: 16),
                if (selected == null)
                  _buildEmptyState()
                else if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildReportList(obsState, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _buildReportDetails(selected),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportList(obsState, notifier),
                      const SizedBox(height: 14),
                      _buildReportDetails(selected),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    bool isCompact,
    SpectatorObstructionState state,
    SpectatorObstructionNotifier notifier,
  ) {
    final actions = Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _InteractiveActionButton(
          label: 'Symuluj: Pies kibica',
          icon: Icons.pets_rounded,
          accentColor: AppColors.amberWarning,
          enabled: !state.isSimulating && sampleRiders.isNotEmpty,
          onPressed: () => notifier.triggerDogIntrusionDemo(sampleRiders),
        ),
        _InteractiveActionButton(
          label: 'Symuluj: Wóz TV (Ventoux)',
          icon: Icons.live_tv_rounded,
          accentColor: AppColors.primaryAccent,
          enabled: !state.isSimulating && sampleRiders.isNotEmpty,
          onPressed: () => notifier.triggerTvVehicleVentouxDemo(sampleRiders),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleBlock(),
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _titleBlock()),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  Widget _titleBlock() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ZDARZENIA EKSTREMALNE NA TRASIE',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Wtargnięcia psów (bikeHandling), blokady wozu TV na podjazdach oraz decyzje sędziów UCI o neutralizacji.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    SpectatorObstructionState state,
    SpectatorObstructionNotifier notifier,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          label: 'Wszystkie (${state.reports.length})',
          selected: state.activeFilter == null,
          onPressed: () => notifier.setFilter(null),
        ),
        _FilterChipButton(
          label: 'Pies kibica',
          selected:
              state.activeFilter == ObstructionEventType.spectatorDogIntrusion,
          onPressed: () =>
              notifier.setFilter(ObstructionEventType.spectatorDogIntrusion),
        ),
        _FilterChipButton(
          label: 'Wóz TV / Mont Ventoux',
          selected: state.activeFilter ==
              ObstructionEventType.tvVehicleClimbObstruction,
          onPressed: () => notifier
              .setFilter(ObstructionEventType.tvVehicleClimbObstruction),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Text(
        'Brak aktywnych incydentów. Użyj przycisków symulacji powyżej, aby przetestować wtargnięcie psa lub blokadę wozu TV.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildReportList(
    SpectatorObstructionState state,
    SpectatorObstructionNotifier notifier,
  ) {
    final items = state.filteredReports;
    return Column(
      children: items.map((report) {
        final isSelected = state.selectedReport?.id == report.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ReportListTile(
            report: report,
            selected: isSelected,
            onTap: () => notifier.selectReport(report.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportDetails(DramaticObstructionEventReport report) {
    final decision = report.commissaireDecision;
    final statusColor = decision.status ==
            NeutralizationVerdictStatus.fullNeutralization
        ? AppColors.statusSuccess
        : (decision.status == NeutralizationVerdictStatus.partialTimeCredit
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      child: Container(
        key: ValueKey(report.id),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryAccent),
                  ),
                  child: Text(
                    report.eventType.badgeCode,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.radioTourHeadlinePl,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.dramaticCommentaryPl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TelemetryTag(
                  label: 'KM',
                  value: '${report.kilometerMark.toStringAsFixed(1)} km',
                ),
                _TelemetryTag(
                  label: 'Do mety',
                  value: '${report.distanceToFinishKm.toStringAsFixed(1)} km',
                ),
                _TelemetryTag(
                  label: 'Nachylenie',
                  value: '${report.gradientPercent.toStringAsFixed(1)}%',
                ),
                _TelemetryTag(
                  label: 'Szerokość',
                  value: '${report.roadWidthMeters.toStringAsFixed(1)} m',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UCI COMMISSAIRE: ${decision.status.labelPl}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${decision.uciArticleReference} • Przywrócono do ${decision.totalTimeCreditedSeconds.toStringAsFixed(1)} s',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.goldAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...report.riderImpacts.map(
              (impact) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RiderImpactRow(impact: impact),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryTag extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryTag({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _RiderImpactRow extends StatelessWidget {
  final RiderObstructionImpact impact;

  const _RiderImpactRow({required this.impact});

  @override
  Widget build(BuildContext context) {
    final badgeColor = impact.outcome == RiderObstructionOutcome.agileEvasion
        ? AppColors.statusSuccess
        : (impact.outcome == RiderObstructionOutcome.emergencyBraking
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${impact.riderName} (${impact.teamId})${impact.isRaceLeader ? " [LIDER]" : ""}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Strata: ${impact.rawTimeLossSeconds.toStringAsFixed(1)}s → Netto: ${impact.netGcTimeLossSeconds.toStringAsFixed(1)}s',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: badgeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            impact.notePl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportListTile extends StatefulWidget {
  final DramaticObstructionEventReport report;
  final bool selected;
  final VoidCallback onTap;

  const _ReportListTile({
    required this.report,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ReportListTile> createState() => _ReportListTileState();
}

class _ReportListTileState extends State<_ReportListTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.22)
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered ? AppColors.surfaceLight : AppColors.background));
    final border = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.report.eventType.labelPl,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.report.kilometerMark.toStringAsFixed(1)} km • ${widget.report.commissaireDecision.status.labelPl}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
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
  final VoidCallback onPressed;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered ? AppColors.surfaceLight : AppColors.background));
    final border = _focused || widget.selected
        ? AppColors.goldAccent
        : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (_pressed
            ? widget.accentColor.withValues(alpha: 0.35)
            : (_hovered
                ? widget.accentColor.withValues(alpha: 0.25)
                : AppColors.surfaceLight));
    final border = !widget.enabled
        ? AppColors.cardBorder
        : (_focused ? AppColors.goldAccent : widget.accentColor);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
