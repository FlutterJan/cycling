import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import 'rider_race_state.dart';

/// Faza zaawansowanej taktyki "Stacji Przekaźnikowych" (Satellite Rider Relay).
enum SatelliteRelayPhase {
  /// Brak aktywnej operacji stacji przekaźnikowej
  inactive,

  /// Silny pomocnik wysłany do porannej ucieczki (oszczędza siły na przełęcze)
  inMorningBreakaway,

  /// Rozkaz `Wait for GC Leader` na przedostatniej przełęczy — pomocnik zwalnia i czeka
  waitingOnPenultimatePass,

  /// Połączenie z atakującym liderem GC i maksymalne ciągnięcie w dolinie
  rendezvousAndValleyPull,

  /// Rozprowadzenie lidera na początku finałowego podjazdu przed solowym atakiem
  finalClimbLeadout,

  /// Zadanie zakończone: pomocnik wykonał pracę i odczepił się
  completed,

  /// Operacja anulowana przez dyrektora sportowego lub z powodu utraty okna taktycznego
  aborted;

  String toJson() => name;

  static SatelliteRelayPhase fromJson(String value) {
    return SatelliteRelayPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SatelliteRelayPhase.inactive,
    );
  }

  String get label {
    switch (this) {
      case SatelliteRelayPhase.inactive:
        return 'Nieaktywna';
      case SatelliteRelayPhase.inMorningBreakaway:
        return 'Poranna ucieczka';
      case SatelliteRelayPhase.waitingOnPenultimatePass:
        return 'Wait for GC Leader';
      case SatelliteRelayPhase.rendezvousAndValleyPull:
        return 'Ciągnięcie w dolinie';
      case SatelliteRelayPhase.finalClimbLeadout:
        return 'Początek finałowego podjazdu';
      case SatelliteRelayPhase.completed:
        return 'Misja ukończona';
      case SatelliteRelayPhase.aborted:
        return 'Misja przerwana';
    }
  }
}

/// Rozkaz dyrektora sportowego dla stacji przekaźnikowej.
enum SatelliteRelayOrder {
  none,
  sendToMorningBreakaway,
  waitForGcLeader,
  pullGcLeaderInValley,
  leadoutFinalClimb,
  abortRelay;

  String toJson() => name;

  static SatelliteRelayOrder fromJson(String value) {
    return SatelliteRelayOrder.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SatelliteRelayOrder.none,
    );
  }

  String get commandLabel {
    switch (this) {
      case SatelliteRelayOrder.none:
        return 'Brak rozkazu';
      case SatelliteRelayOrder.sendToMorningBreakaway:
        return 'Wyślij do ucieczki';
      case SatelliteRelayOrder.waitForGcLeader:
        return 'Wait for GC Leader';
      case SatelliteRelayOrder.pullGcLeaderInValley:
        return 'Ciągnij w dolinie';
      case SatelliteRelayOrder.leadoutFinalClimb:
        return 'Rozprowadź podjazd';
      case SatelliteRelayOrder.abortRelay:
        return 'Anuluj przekaźnik';
    }
  }
}

/// Wykryty punkt kontrolny przedostatniej przełęczy, doliny i finałowego podjazdu.
class PenultimatePassCheckpoint {
  final bool hasValidSatelliteTerrain;
  final double penultimatePassStartKm;
  final double penultimatePassSummitKm;
  final double valleyStartKm;
  final double valleyEndKm;
  final double finalClimbStartKm;
  final double finalClimbSummitKm;
  final String penultimateClimbName;
  final String finalClimbName;

  const PenultimatePassCheckpoint({
    required this.hasValidSatelliteTerrain,
    required this.penultimatePassStartKm,
    required this.penultimatePassSummitKm,
    required this.valleyStartKm,
    required this.valleyEndKm,
    required this.finalClimbStartKm,
    required this.finalClimbSummitKm,
    required this.penultimateClimbName,
    required this.finalClimbName,
  });

  factory PenultimatePassCheckpoint.empty() {
    return const PenultimatePassCheckpoint(
      hasValidSatelliteTerrain: false,
      penultimatePassStartKm: 0.0,
      penultimatePassSummitKm: 0.0,
      valleyStartKm: 0.0,
      valleyEndKm: 0.0,
      finalClimbStartKm: 0.0,
      finalClimbSummitKm: 0.0,
      penultimateClimbName: 'Brak',
      finalClimbName: 'Brak',
    );
  }

  double get valleyLengthKm => math.max(0.0, valleyEndKm - valleyStartKm);

  double get finalClimbLengthKm =>
      math.max(0.0, finalClimbSummitKm - finalClimbStartKm);

  Map<String, dynamic> toJson() {
    return {
      'hasValidSatelliteTerrain': hasValidSatelliteTerrain,
      'penultimatePassStartKm': penultimatePassStartKm,
      'penultimatePassSummitKm': penultimatePassSummitKm,
      'valleyStartKm': valleyStartKm,
      'valleyEndKm': valleyEndKm,
      'finalClimbStartKm': finalClimbStartKm,
      'finalClimbSummitKm': finalClimbSummitKm,
      'penultimateClimbName': penultimateClimbName,
      'finalClimbName': finalClimbName,
    };
  }

  factory PenultimatePassCheckpoint.fromJson(Map<String, dynamic> json) {
    return PenultimatePassCheckpoint(
      hasValidSatelliteTerrain:
          json['hasValidSatelliteTerrain'] as bool? ?? false,
      penultimatePassStartKm:
          (json['penultimatePassStartKm'] as num?)?.toDouble() ?? 0.0,
      penultimatePassSummitKm:
          (json['penultimatePassSummitKm'] as num?)?.toDouble() ?? 0.0,
      valleyStartKm: (json['valleyStartKm'] as num?)?.toDouble() ?? 0.0,
      valleyEndKm: (json['valleyEndKm'] as num?)?.toDouble() ?? 0.0,
      finalClimbStartKm: (json['finalClimbStartKm'] as num?)?.toDouble() ?? 0.0,
      finalClimbSummitKm:
          (json['finalClimbSummitKm'] as num?)?.toDouble() ?? 0.0,
      penultimateClimbName:
          json['penultimateClimbName'] as String? ?? 'Przedostatnia przełęcz',
      finalClimbName: json['finalClimbName'] as String? ?? 'Finałowy podjazd',
    );
  }
}

/// Ocena kolarza jako kandydata na stację przekaźnikową.
class SatelliteDomestiqueCandidate {
  final String riderId;
  final String fullName;
  final RiderSpecialization specialization;
  final double wattsPerKg;
  final int ftpWatts;
  final double suitabilityScore; // 0.0 - 100.0
  final String tacticalNote;

  const SatelliteDomestiqueCandidate({
    required this.riderId,
    required this.fullName,
    required this.specialization,
    required this.wattsPerKg,
    required this.ftpWatts,
    required this.suitabilityScore,
    required this.tacticalNote,
  });
}

/// Pełny stan aktywnej misji stacji przekaźnikowej.
class SatelliteRelayMissionState {
  final String satelliteRiderId;
  final String satelliteRiderName;
  final String gcLeaderId;
  final String gcLeaderName;
  final SatelliteRelayPhase phase;
  final SatelliteRelayOrder activeOrder;
  final PenultimatePassCheckpoint checkpoint;
  final double gapToGcLeaderMeters;
  final double gapToGcLeaderSeconds;
  final double waitDurationSeconds;
  final double valleyPullDurationSeconds;
  final double valleyPullMeters;
  final double finalClimbLeadoutDurationSeconds;
  final double finalClimbLeadoutMeters;
  final double leaderEnergySavedJoules;
  final double lastLeaderWattsSaved;
  final List<String> radioLog;

  const SatelliteRelayMissionState({
    required this.satelliteRiderId,
    required this.satelliteRiderName,
    required this.gcLeaderId,
    required this.gcLeaderName,
    required this.phase,
    required this.activeOrder,
    required this.checkpoint,
    this.gapToGcLeaderMeters = 0.0,
    this.gapToGcLeaderSeconds = 0.0,
    this.waitDurationSeconds = 0.0,
    this.valleyPullDurationSeconds = 0.0,
    this.valleyPullMeters = 0.0,
    this.finalClimbLeadoutDurationSeconds = 0.0,
    this.finalClimbLeadoutMeters = 0.0,
    this.leaderEnergySavedJoules = 0.0,
    this.lastLeaderWattsSaved = 0.0,
    this.radioLog = const <String>[],
  });

  bool get isActive =>
      phase != SatelliteRelayPhase.inactive &&
      phase != SatelliteRelayPhase.completed &&
      phase != SatelliteRelayPhase.aborted;

  bool get isWaitingForLeader =>
      phase == SatelliteRelayPhase.waitingOnPenultimatePass;

  bool get isPullingLeader =>
      phase == SatelliteRelayPhase.rendezvousAndValleyPull ||
      phase == SatelliteRelayPhase.finalClimbLeadout;

  SatelliteRelayMissionState copyWith({
    String? satelliteRiderId,
    String? satelliteRiderName,
    String? gcLeaderId,
    String? gcLeaderName,
    SatelliteRelayPhase? phase,
    SatelliteRelayOrder? activeOrder,
    PenultimatePassCheckpoint? checkpoint,
    double? gapToGcLeaderMeters,
    double? gapToGcLeaderSeconds,
    double? waitDurationSeconds,
    double? valleyPullDurationSeconds,
    double? valleyPullMeters,
    double? finalClimbLeadoutDurationSeconds,
    double? finalClimbLeadoutMeters,
    double? leaderEnergySavedJoules,
    double? lastLeaderWattsSaved,
    List<String>? radioLog,
  }) {
    return SatelliteRelayMissionState(
      satelliteRiderId: satelliteRiderId ?? this.satelliteRiderId,
      satelliteRiderName: satelliteRiderName ?? this.satelliteRiderName,
      gcLeaderId: gcLeaderId ?? this.gcLeaderId,
      gcLeaderName: gcLeaderName ?? this.gcLeaderName,
      phase: phase ?? this.phase,
      activeOrder: activeOrder ?? this.activeOrder,
      checkpoint: checkpoint ?? this.checkpoint,
      gapToGcLeaderMeters: gapToGcLeaderMeters ?? this.gapToGcLeaderMeters,
      gapToGcLeaderSeconds: gapToGcLeaderSeconds ?? this.gapToGcLeaderSeconds,
      waitDurationSeconds: waitDurationSeconds ?? this.waitDurationSeconds,
      valleyPullDurationSeconds:
          valleyPullDurationSeconds ?? this.valleyPullDurationSeconds,
      valleyPullMeters: valleyPullMeters ?? this.valleyPullMeters,
      finalClimbLeadoutDurationSeconds: finalClimbLeadoutDurationSeconds ??
          this.finalClimbLeadoutDurationSeconds,
      finalClimbLeadoutMeters:
          finalClimbLeadoutMeters ?? this.finalClimbLeadoutMeters,
      leaderEnergySavedJoules:
          leaderEnergySavedJoules ?? this.leaderEnergySavedJoules,
      lastLeaderWattsSaved: lastLeaderWattsSaved ?? this.lastLeaderWattsSaved,
      radioLog: radioLog ?? this.radioLog,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'satelliteRiderId': satelliteRiderId,
      'satelliteRiderName': satelliteRiderName,
      'gcLeaderId': gcLeaderId,
      'gcLeaderName': gcLeaderName,
      'phase': phase.toJson(),
      'activeOrder': activeOrder.toJson(),
      'checkpoint': checkpoint.toJson(),
      'gapToGcLeaderMeters': gapToGcLeaderMeters,
      'gapToGcLeaderSeconds': gapToGcLeaderSeconds,
      'waitDurationSeconds': waitDurationSeconds,
      'valleyPullDurationSeconds': valleyPullDurationSeconds,
      'valleyPullMeters': valleyPullMeters,
      'finalClimbLeadoutDurationSeconds': finalClimbLeadoutDurationSeconds,
      'finalClimbLeadoutMeters': finalClimbLeadoutMeters,
      'leaderEnergySavedJoules': leaderEnergySavedJoules,
      'lastLeaderWattsSaved': lastLeaderWattsSaved,
      'radioLog': radioLog,
    };
  }

  factory SatelliteRelayMissionState.fromJson(Map<String, dynamic> json) {
    return SatelliteRelayMissionState(
      satelliteRiderId: json['satelliteRiderId'] as String? ?? '',
      satelliteRiderName: json['satelliteRiderName'] as String? ?? '',
      gcLeaderId: json['gcLeaderId'] as String? ?? '',
      gcLeaderName: json['gcLeaderName'] as String? ?? '',
      phase: SatelliteRelayPhase.fromJson(json['phase'] as String? ?? ''),
      activeOrder:
          SatelliteRelayOrder.fromJson(json['activeOrder'] as String? ?? ''),
      checkpoint: json['checkpoint'] is Map<String, dynamic>
          ? PenultimatePassCheckpoint.fromJson(
              json['checkpoint'] as Map<String, dynamic>,
            )
          : PenultimatePassCheckpoint.empty(),
      gapToGcLeaderMeters:
          (json['gapToGcLeaderMeters'] as num?)?.toDouble() ?? 0.0,
      gapToGcLeaderSeconds:
          (json['gapToGcLeaderSeconds'] as num?)?.toDouble() ?? 0.0,
      waitDurationSeconds:
          (json['waitDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      valleyPullDurationSeconds:
          (json['valleyPullDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      valleyPullMeters: (json['valleyPullMeters'] as num?)?.toDouble() ?? 0.0,
      finalClimbLeadoutDurationSeconds:
          (json['finalClimbLeadoutDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      finalClimbLeadoutMeters:
          (json['finalClimbLeadoutMeters'] as num?)?.toDouble() ?? 0.0,
      leaderEnergySavedJoules:
          (json['leaderEnergySavedJoules'] as num?)?.toDouble() ?? 0.0,
      lastLeaderWattsSaved:
          (json['lastLeaderWattsSaved'] as num?)?.toDouble() ?? 0.0,
      radioLog: (json['radioLog'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
    );
  }
}

/// Dane wejściowe dla pojedynczego kroku symulacji stacji przekaźnikowej.
class SatelliteRelayStepInput {
  final double dtSeconds;
  final double gradientPercent;
  final double headwindMs;
  final RiderRaceState satelliteState;
  final RiderRaceState gcLeaderState;
  final int satelliteFtpWatts;
  final double satelliteMassKg;
  final double satelliteMaxWPrimeJoules;
  final int satelliteAeroPositioning;
  final int gcLeaderFtpWatts;
  final double gcLeaderMassKg;
  final bool isGcLeaderAttacking;
  final double climbLeadoutCutoffKm;

  const SatelliteRelayStepInput({
    required this.dtSeconds,
    required this.gradientPercent,
    this.headwindMs = 0.0,
    required this.satelliteState,
    required this.gcLeaderState,
    required this.satelliteFtpWatts,
    required this.satelliteMassKg,
    required this.satelliteMaxWPrimeJoules,
    this.satelliteAeroPositioning = 65,
    required this.gcLeaderFtpWatts,
    required this.gcLeaderMassKg,
    this.isGcLeaderAttacking = false,
    this.climbLeadoutCutoffKm = 3.5,
  });
}

/// Wynik pojedynczego kroku symulacji stacji przekaźnikowej.
class SatelliteRelayStepResult {
  final SatelliteRelayMissionState updatedMissionState;
  final RiderRaceState updatedSatelliteState;
  final int satelliteTargetWatts;
  final double satelliteDraftingBonus;
  final double gcLeaderDraftingReduction;
  final double gcLeaderWattsSaved;
  final String? radioMessage;

  const SatelliteRelayStepResult({
    required this.updatedMissionState,
    required this.updatedSatelliteState,
    required this.satelliteTargetWatts,
    required this.satelliteDraftingBonus,
    required this.gcLeaderDraftingReduction,
    required this.gcLeaderWattsSaved,
    this.radioMessage,
  });
}

/// Podsumowanie wykonanej taktyki stacji przekaźnikowej.
class SatelliteRelaySimulationSummary {
  final SatelliteRelayPhase finalPhase;
  final double waitDurationSeconds;
  final double valleyPullKm;
  final double finalClimbLeadoutKm;
  final double leaderEnergySavedKj;
  final double tacticalEfficiencyScore; // 0 - 100

  const SatelliteRelaySimulationSummary({
    required this.finalPhase,
    required this.waitDurationSeconds,
    required this.valleyPullKm,
    required this.finalClimbLeadoutKm,
    required this.leaderEnergySavedKj,
    required this.tacticalEfficiencyScore,
  });
}

/// Silnik taktyki "Stacji Przekaźnikowych" (Satellite Rider Relay).
///
/// Pozwala wysłać silnego pomocnika do porannej ucieczki, wydać mu rozkaz
/// `Wait for GC Leader` na przedostatniej przełęczy, połączyć się z atakującym
/// liderem GC oraz ciągnąć go w dolinie i na początku finałowego podjazdu.
class SatelliteRiderRelayTacticsEngine {
  SatelliteRiderRelayTacticsEngine._();

  static const double rendezvousDistanceMeters = 25.0;
  static const double rendezvousTimeSeconds = 2.0;
  static const double penultimatePassTriggerWindowKm = 2.0;

  /// Analizuje profil etapu i wyznacza przedostatnią przełęcz, dolinę oraz finałowy podjazd.
  static PenultimatePassCheckpoint analyzeStageTerrain(RaceStage stage) {
    if (stage.segments.isEmpty) {
      return PenultimatePassCheckpoint.empty();
    }

    final List<_ClimbBlock> climbs = <_ClimbBlock>[];
    _ClimbBlock? current;

    for (final StageSegment seg in stage.segments) {
      final bool isCategorizedClimb = seg.sprintOrKomClassification ==
              SegmentClassification.cat3 ||
          seg.sprintOrKomClassification == SegmentClassification.cat2 ||
          seg.sprintOrKomClassification == SegmentClassification.cat1 ||
          seg.sprintOrKomClassification == SegmentClassification.horsCategorie;
      final bool climbing = seg.isClimb || isCategorizedClimb;

      if (climbing) {
        if (current == null) {
          current = _ClimbBlock(
            startKm: seg.startKm,
            endKm: seg.endKm,
            gainM: seg.elevationGainM,
            categoryLabel: seg.climbCategory ?? 'Podjazd',
          );
        } else {
          current = _ClimbBlock(
            startKm: current.startKm,
            endKm: seg.endKm,
            gainM: current.gainM + seg.elevationGainM,
            categoryLabel: seg.climbCategory ?? current.categoryLabel,
          );
        }
      } else if (current != null) {
        if (current.endKm - current.startKm >= 1.5 || current.gainM >= 80.0) {
          climbs.add(current);
        }
        current = null;
      }
    }

    if (current != null &&
        (current.endKm - current.startKm >= 1.5 || current.gainM >= 80.0)) {
      climbs.add(current);
    }

    if (climbs.length < 2) {
      return PenultimatePassCheckpoint.empty();
    }

    final _ClimbBlock penultimate = climbs[climbs.length - 2];
    final _ClimbBlock finalClimb = climbs[climbs.length - 1];

    return PenultimatePassCheckpoint(
      hasValidSatelliteTerrain: true,
      penultimatePassStartKm: penultimate.startKm,
      penultimatePassSummitKm: penultimate.endKm,
      valleyStartKm: penultimate.endKm,
      valleyEndKm: finalClimb.startKm,
      finalClimbStartKm: finalClimb.startKm,
      finalClimbSummitKm: finalClimb.endKm,
      penultimateClimbName:
          'Przełęcz (${penultimate.categoryLabel}) km ${penultimate.endKm.toStringAsFixed(1)}',
      finalClimbName:
          'Finałowy podjazd (${finalClimb.categoryLabel}) km ${finalClimb.startKm.toStringAsFixed(1)}',
    );
  }

  /// Ocenia i sortuje kandydatów z drużyny na stację przekaźnikową.
  static List<SatelliteDomestiqueCandidate> evaluateCandidates({
    required List<Rider> teamRoster,
    required String gcLeaderId,
  }) {
    final List<SatelliteDomestiqueCandidate> candidates =
        <SatelliteDomestiqueCandidate>[];

    for (final Rider rider in teamRoster) {
      if (rider.id == gcLeaderId) continue;

      final double wKg = rider.physiology.wattsPerKg;
      final int ftp = rider.physiology.ftpWatts;
      final double aeroScore = rider.skills.aeroPositioning.toDouble();
      final double descScore = rider.skills.descending.toDouble();
      final double iqScore = rider.skills.raceIq.toDouble();

      double roleBonus = 0.0;
      String note = 'Silnik do pracy w dolinie i w górach';
      switch (rider.specialization) {
        case RiderSpecialization.domestiqueEngine:
          roleBonus = 12.0;
          note = 'Idealny super-pomocnik (wysokie FTP + praca w dolinie)';
          break;
        case RiderSpecialization.breakawaySpecialist:
          roleBonus = 10.0;
          note = 'Łatwo zabiera się do porannej ucieczki';
          break;
        case RiderSpecialization.pureClimber:
        case RiderSpecialization.gcClimber:
          roleBonus = 9.0;
          note = 'Długie wsparcie na początku finałowego podjazdu';
          break;
        case RiderSpecialization.timeTrialist:
          roleBonus = 8.0;
          note = 'Ogromna moc w dolinie i ochrona przed wiatrem';
          break;
        case RiderSpecialization.puncher:
          roleBonus = 5.0;
          note = 'Dynamiczny przeskok do odjazdu dnia';
          break;
        case RiderSpecialization.classicCobbles:
        case RiderSpecialization.versatileSprinter:
        case RiderSpecialization.pureSprinter:
          roleBonus = -8.0;
          note = 'Ograniczona wytrzymałość w wysokich górach';
          break;
      }

      final double rawScore = (wKg * 11.5) +
          ((ftp / 450.0) * 18.0) +
          (aeroScore * 0.10) +
          (descScore * 0.08) +
          (iqScore * 0.08) +
          roleBonus;

      candidates.add(
        SatelliteDomestiqueCandidate(
          riderId: rider.id,
          fullName: '${rider.firstName} ${rider.lastName}',
          specialization: rider.specialization,
          wattsPerKg: wKg,
          ftpWatts: ftp,
          suitabilityScore: rawScore.clamp(0.0, 100.0),
          tacticalNote: note,
        ),
      );
    }

    candidates.sort(
      (a, b) => b.suitabilityScore.compareTo(a.suitabilityScore),
    );
    return candidates;
  }

  /// Tworzy nową misję stacji przekaźnikowej i wysyła pomocnika do porannej ucieczki.
  static SatelliteRelayMissionState createMission({
    required String satelliteRiderId,
    required String satelliteRiderName,
    required String gcLeaderId,
    required String gcLeaderName,
    required RaceStage stage,
    bool startInBreakawayImmediately = true,
  }) {
    final PenultimatePassCheckpoint checkpoint = analyzeStageTerrain(stage);
    final SatelliteRelayPhase initialPhase = startInBreakawayImmediately
        ? SatelliteRelayPhase.inMorningBreakaway
        : SatelliteRelayPhase.inactive;
    final SatelliteRelayOrder initialOrder = startInBreakawayImmediately
        ? SatelliteRelayOrder.sendToMorningBreakaway
        : SatelliteRelayOrder.none;

    final List<String> log = <String>[
      if (startInBreakawayImmediately)
        '[$satelliteRiderName] Wysłany do porannej ucieczki jako stacja przekaźnikowa dla $gcLeaderName.'
      else
        'Zaplanowano stację przekaźnikową: $satelliteRiderName -> $gcLeaderName.',
    ];

    return SatelliteRelayMissionState(
      satelliteRiderId: satelliteRiderId,
      satelliteRiderName: satelliteRiderName,
      gcLeaderId: gcLeaderId,
      gcLeaderName: gcLeaderName,
      phase: initialPhase,
      activeOrder: initialOrder,
      checkpoint: checkpoint,
      radioLog: log,
    );
  }

  /// Wydaje rozkaz taktyczny dla stacji przekaźnikowej (w tym `Wait for GC Leader`).
  static SatelliteRelayMissionState issueOrder({
    required SatelliteRelayMissionState currentState,
    required SatelliteRelayOrder order,
    required double currentStageKm,
  }) {
    final List<String> updatedLog = List<String>.from(currentState.radioLog);

    switch (order) {
      case SatelliteRelayOrder.sendToMorningBreakaway:
        updatedLog.add(
          'km ${currentStageKm.toStringAsFixed(1)}: ${currentState.satelliteRiderName} atakuje do porannej ucieczki.',
        );
        return currentState.copyWith(
          phase: SatelliteRelayPhase.inMorningBreakaway,
          activeOrder: order,
          radioLog: updatedLog,
        );

      case SatelliteRelayOrder.waitForGcLeader:
        if (!currentState.isActive &&
            currentState.phase != SatelliteRelayPhase.inactive) {
          return currentState;
        }
        updatedLog.add(
          'km ${currentStageKm.toStringAsFixed(1)}: ROZKAZ "Wait for GC Leader" — ${currentState.satelliteRiderName} zwalnia na przełęczy i czeka na ${currentState.gcLeaderName}!',
        );
        return currentState.copyWith(
          phase: SatelliteRelayPhase.waitingOnPenultimatePass,
          activeOrder: order,
          radioLog: updatedLog,
        );

      case SatelliteRelayOrder.pullGcLeaderInValley:
        updatedLog.add(
          'km ${currentStageKm.toStringAsFixed(1)}: ${currentState.satelliteRiderName} rozpoczyna pełną zmianę w dolinie dla ${currentState.gcLeaderName}.',
        );
        return currentState.copyWith(
          phase: SatelliteRelayPhase.rendezvousAndValleyPull,
          activeOrder: order,
          radioLog: updatedLog,
        );

      case SatelliteRelayOrder.leadoutFinalClimb:
        updatedLog.add(
          'km ${currentStageKm.toStringAsFixed(1)}: ${currentState.satelliteRiderName} rozprowadza ${currentState.gcLeaderName} na początku finałowego podjazdu.',
        );
        return currentState.copyWith(
          phase: SatelliteRelayPhase.finalClimbLeadout,
          activeOrder: order,
          radioLog: updatedLog,
        );

      case SatelliteRelayOrder.abortRelay:
        updatedLog.add(
          'km ${currentStageKm.toStringAsFixed(1)}: Taktyka stacji przekaźnikowej anulowana.',
        );
        return currentState.copyWith(
          phase: SatelliteRelayPhase.aborted,
          activeOrder: order,
          lastLeaderWattsSaved: 0.0,
          radioLog: updatedLog,
        );

      case SatelliteRelayOrder.none:
        return currentState;
    }
  }

  /// Wykonuje jeden krok symulacji stacji przekaźnikowej w czasie `dtSeconds`.
  static SatelliteRelayStepResult step({
    required SatelliteRelayMissionState missionState,
    required SatelliteRelayStepInput input,
  }) {
    final double dt = math.max(0.0, input.dtSeconds);
    final double satDistM = input.satelliteState.distanceCoveredMeters;
    final double leaderDistM = input.gcLeaderState.distanceCoveredMeters;
    final double currentSatKm = satDistM / 1000.0;

    final double gapMeters = satDistM - leaderDistM;
    final double refSpeed = math.max(
      3.5,
      math.max(input.gcLeaderState.currentSpeedMs,
          input.satelliteState.currentSpeedMs),
    );
    final double gapSeconds = gapMeters / refSpeed;

    SatelliteRelayPhase nextPhase = missionState.phase;
    SatelliteRelayOrder nextOrder = missionState.activeOrder;
    String? radioMessage;
    final List<String> nextLog = List<String>.from(missionState.radioLog);

    double waitDuration = missionState.waitDurationSeconds;
    double valleyPullDuration = missionState.valleyPullDurationSeconds;
    double valleyPullMeters = missionState.valleyPullMeters;
    double climbLeadoutDuration = missionState.finalClimbLeadoutDurationSeconds;
    double climbLeadoutMeters = missionState.finalClimbLeadoutMeters;
    double energySavedJoules = missionState.leaderEnergySavedJoules;
    double leaderWattsSaved = 0.0;
    double leaderDraftingReduction = 0.0;
    double satelliteDraftingBonus = 0.0;
    int targetWatts = (input.satelliteFtpWatts * 0.65).round();
    TacticalOrder riderOrder = input.satelliteState.activeTacticalOrder;

    switch (missionState.phase) {
      case SatelliteRelayPhase.inactive:
      case SatelliteRelayPhase.completed:
      case SatelliteRelayPhase.aborted:
        targetWatts = (input.satelliteFtpWatts * 0.55).round();
        break;

      case SatelliteRelayPhase.inMorningBreakaway:
        // W porannej ucieczce kolarz jedzie ekonomicznie (~84% FTP), zbierając przewagę przed górami.
        satelliteDraftingBonus = 0.24;
        targetWatts = (input.satelliteFtpWatts * 0.84).round();
        riderOrder = TacticalOrder.pullGroup;

        // Automatyczne przypomnienie radiowe przy zbliżaniu się do przedostatniej przełęczy
        if (missionState.checkpoint.hasValidSatelliteTerrain &&
            currentSatKm >=
                missionState.checkpoint.penultimatePassSummitKm -
                    penultimatePassTriggerWindowKm &&
            currentSatKm <= missionState.checkpoint.penultimatePassSummitKm &&
            missionState.activeOrder ==
                SatelliteRelayOrder.waitForGcLeader) {
          nextPhase = SatelliteRelayPhase.waitingOnPenultimatePass;
          radioMessage =
              '${missionState.satelliteRiderName} dociera na przedostatnią przełęcz i wykonuje rozkaz Wait for GC Leader!';
          nextLog.add(radioMessage);
        }
        break;

      case SatelliteRelayPhase.waitingOnPenultimatePass:
        waitDuration += dt;
        riderOrder = TacticalOrder.saveEnergy;

        // Jeśli lider wyprzedził już pomocnika lub zbliżył się na odległość połączenia -> Rendezvous!
        if (gapMeters <= rendezvousDistanceMeters ||
            gapSeconds <= rendezvousTimeSeconds) {
          final bool alreadyOnFinalClimb =
              missionState.checkpoint.hasValidSatelliteTerrain &&
                  currentSatKm >= missionState.checkpoint.finalClimbStartKm;

          if (alreadyOnFinalClimb) {
            nextPhase = SatelliteRelayPhase.finalClimbLeadout;
            nextOrder = SatelliteRelayOrder.leadoutFinalClimb;
            radioMessage =
                'Połączenie z ${missionState.gcLeaderName}! ${missionState.satelliteRiderName} od razu rozprowadza na finałowym podjeździe!';
          } else {
            nextPhase = SatelliteRelayPhase.rendezvousAndValleyPull;
            nextOrder = SatelliteRelayOrder.pullGcLeaderInValley;
            radioMessage =
                'Rendezvous! ${missionState.satelliteRiderName} złapał koło ${missionState.gcLeaderName} i ciągnie w dolinie!';
          }
          nextLog.add(radioMessage);
          targetWatts = (input.satelliteFtpWatts * 0.98).round();
        } else if (gapMeters > 6500.0 &&
            missionState.checkpoint.hasValidSatelliteTerrain &&
            currentSatKm > missionState.checkpoint.finalClimbStartKm + 1.5) {
          // Okno taktyczne minęło — lider za daleko
          nextPhase = SatelliteRelayPhase.aborted;
          nextOrder = SatelliteRelayOrder.abortRelay;
          radioMessage =
              'Lider GC nie zdołał dołączyć przed finałowym podjazdem — przekaźnik odwołany.';
          nextLog.add(radioMessage);
          targetWatts = (input.satelliteFtpWatts * 0.55).round();
        } else {
          // Tempo oczekiwania (Z1/Z2) zależne od luki i terenu
          final double waitIntensity = gapMeters > 400.0 ? 0.38 : 0.58;
          targetWatts = (input.satelliteFtpWatts * waitIntensity)
              .round()
              .clamp(110, input.satelliteFtpWatts);
        }
        break;

      case SatelliteRelayPhase.rendezvousAndValleyPull:
        valleyPullDuration += dt;
        valleyPullMeters += input.satelliteState.currentSpeedMs * dt;
        riderOrder = TacticalOrder.protectLeader;

        // Mocne tempo w dolinie (próg / ponad próg, z uwzględnieniem wiatru czołowego)
        final double windFactor =
            (1.0 + math.max(0.0, input.headwindMs) * 0.015).clamp(1.0, 1.12);
        targetWatts = (input.satelliteFtpWatts * 1.02 * windFactor).round();

        // Oblicz oszczędność aerodynamiczną dla lidera GC jadącego na kole stacji przekaźnikowej
        final double aeroSkillNorm =
            (input.satelliteAeroPositioning.clamp(30, 99) - 30) / 69.0;
        leaderDraftingReduction = 0.34 + (aeroSkillNorm * 0.07); // 34% - 41%
        leaderWattsSaved = _computeDraftingWattsSaved(
          speedMs: refSpeed,
          draftingReduction: leaderDraftingReduction,
          headwindMs: input.headwindMs,
        );
        energySavedJoules += leaderWattsSaved * dt;

        // Przejście na finałowy podjazd
        if (missionState.checkpoint.hasValidSatelliteTerrain &&
            currentSatKm >= missionState.checkpoint.finalClimbStartKm) {
          nextPhase = SatelliteRelayPhase.finalClimbLeadout;
          nextOrder = SatelliteRelayOrder.leadoutFinalClimb;
          radioMessage =
              'Początek finałowego podjazdu! ${missionState.satelliteRiderName} podkręca tempo dla ${missionState.gcLeaderName}!';
          nextLog.add(radioMessage);
        } else if (input.satelliteState.currentWPrime <
                input.satelliteMaxWPrimeJoules * 0.04 ||
            input.satelliteState.currentGlycogen < 20.0) {
          nextPhase = SatelliteRelayPhase.completed;
          radioMessage =
              '${missionState.satelliteRiderName} wyczerpał rezerwy w dolinie — ${missionState.gcLeaderName} przejmuje prowadzenie.';
          nextLog.add(radioMessage);
        }
        break;

      case SatelliteRelayPhase.finalClimbLeadout:
        climbLeadoutDuration += dt;
        climbLeadoutMeters += input.satelliteState.currentSpeedMs * dt;
        riderOrder = TacticalOrder.pullGroup;

        // Tempo wspinaczkowe na początku finałowego podjazdu (104% - 110% FTP)
        final double climbFactor = input.isGcLeaderAttacking ? 1.10 : 1.05;
        targetWatts = (input.satelliteFtpWatts * climbFactor).round();

        // Na podjeździe drafting jest mniejszy niż w dolinie, ale przy wyższych prędkościach nadal kluczowy
        final double climbSpeedRatio = (refSpeed / 11.0).clamp(0.35, 1.0);
        leaderDraftingReduction = 0.28 * climbSpeedRatio;
        leaderWattsSaved = _computeDraftingWattsSaved(
          speedMs: refSpeed,
          draftingReduction: leaderDraftingReduction,
          headwindMs: input.headwindMs,
        );
        energySavedJoules += leaderWattsSaved * dt;

        final bool reachedLeadoutCutoff =
            (climbLeadoutMeters / 1000.0) >= input.climbLeadoutCutoffKm;
        final bool exhaustedWPrime = input.satelliteState.currentWPrime <=
            input.satelliteMaxWPrimeJoules * 0.06;
        final bool lowGlycogen = input.satelliteState.currentGlycogen <= 25.0;

        if (reachedLeadoutCutoff || exhaustedWPrime || lowGlycogen) {
          nextPhase = SatelliteRelayPhase.completed;
          radioMessage =
              'Stacja przekaźnikowa ${missionState.satelliteRiderName} wykonała zadanie na finałowym podjeździe! ${missionState.gcLeaderName} gotowy do ataku!';
          nextLog.add(radioMessage);
        }
        break;
    }

    final double updatedWPrime = _updateWPrimeBalance(
      currentWPrime: input.satelliteState.currentWPrime,
      maxWPrime: input.satelliteMaxWPrimeJoules,
      powerWatts: targetWatts.toDouble(),
      ftpWatts: input.satelliteFtpWatts.toDouble(),
      dtSeconds: dt,
    );

    final RiderRaceState updatedSatellite = input.satelliteState.copyWith(
      currentWatts: targetWatts,
      currentWPrime: updatedWPrime,
      activeTacticalOrder: riderOrder,
      groupIndex: nextPhase == SatelliteRelayPhase.inMorningBreakaway
          ? 0
          : input.gcLeaderState.groupIndex,
    );

    final SatelliteRelayMissionState updatedMission = missionState.copyWith(
      phase: nextPhase,
      activeOrder: nextOrder,
      gapToGcLeaderMeters: gapMeters,
      gapToGcLeaderSeconds: gapSeconds,
      waitDurationSeconds: waitDuration,
      valleyPullDurationSeconds: valleyPullDuration,
      valleyPullMeters: valleyPullMeters,
      finalClimbLeadoutDurationSeconds: climbLeadoutDuration,
      finalClimbLeadoutMeters: climbLeadoutMeters,
      leaderEnergySavedJoules: energySavedJoules,
      lastLeaderWattsSaved: leaderWattsSaved,
      radioLog: nextLog,
    );

    return SatelliteRelayStepResult(
      updatedMissionState: updatedMission,
      updatedSatelliteState: updatedSatellite,
      satelliteTargetWatts: targetWatts,
      satelliteDraftingBonus: satelliteDraftingBonus,
      gcLeaderDraftingReduction: leaderDraftingReduction,
      gcLeaderWattsSaved: leaderWattsSaved,
      radioMessage: radioMessage,
    );
  }

  /// Tworzy podsumowanie efektywności taktyki stacji przekaźnikowej.
  static SatelliteRelaySimulationSummary buildSummary(
    SatelliteRelayMissionState state,
  ) {
    final double valleyKm = state.valleyPullMeters / 1000.0;
    final double climbKm = state.finalClimbLeadoutMeters / 1000.0;
    final double savedKj = state.leaderEnergySavedJoules / 1000.0;

    double score = 0.0;
    if (state.phase == SatelliteRelayPhase.completed) {
      score += 35.0;
    } else if (state.isPullingLeader) {
      score += 20.0;
    }
    score += math.min(35.0, (savedKj / 80.0) * 35.0);
    score += math.min(20.0, valleyKm * 1.5);
    score += math.min(10.0, climbKm * 3.0);

    return SatelliteRelaySimulationSummary(
      finalPhase: state.phase,
      waitDurationSeconds: state.waitDurationSeconds,
      valleyPullKm: valleyKm,
      finalClimbLeadoutKm: climbKm,
      leaderEnergySavedKj: savedKj,
      tacticalEfficiencyScore: score.clamp(0.0, 100.0),
    );
  }

  static double _computeDraftingWattsSaved({
    required double speedMs,
    required double draftingReduction,
    required double headwindMs,
  }) {
    final double airSpeed = math.max(1.0, speedMs + headwindMs);
    const double baseCdA = 0.315;
    final double deltaCdA = baseCdA * draftingReduction.clamp(0.0, 0.45);
    final double fAeroSaved =
        0.5 * PhysicsConstants.seaLevelAirDensity * deltaCdA * airSpeed * airSpeed;
    return math.max(0.0, fAeroSaved * speedMs);
  }

  static double _updateWPrimeBalance({
    required double currentWPrime,
    required double maxWPrime,
    required double powerWatts,
    required double ftpWatts,
    required double dtSeconds,
  }) {
    if (dtSeconds <= 0.0) return currentWPrime;
    if (powerWatts > ftpWatts) {
      final double drained = (powerWatts - ftpWatts) * dtSeconds;
      return math.max(0.0, currentWPrime - drained);
    } else {
      final double dCp = math.max(10.0, ftpWatts - powerWatts);
      final double tau = 546.0 * math.exp(-0.01 * dCp) + 316.0;
      final double recovered =
          (maxWPrime - currentWPrime) * (1.0 - math.exp(-dtSeconds / tau));
      return math.min(maxWPrime, currentWPrime + recovered);
    }
  }
}

class _ClimbBlock {
  final double startKm;
  final double endKm;
  final double gainM;
  final String categoryLabel;

  const _ClimbBlock({
    required this.startKm,
    required this.endKm,
    required this.gainM,
    required this.categoryLabel,
  });
}

/// Responsywny panel HUD/taktyki Stacji Przekaźnikowych (`SatelliteRiderRelayTacticsEngine`).
///
/// Obsługuje pełne stany `hover`, `active`, `disabled`, `focus`, paletę [AppColors],
/// czcionkę `Inter` oraz adaptacyjny układ `LayoutBuilder` (390x844 / 1024x768 / 1600x900).
class SatelliteRelayTacticsPanel extends StatelessWidget {
  final SatelliteRelayMissionState missionState;
  final double currentStageKm;
  final VoidCallback? onSendToBreakaway;
  final VoidCallback? onWaitForGcLeader;
  final VoidCallback? onAbortRelay;

  const SatelliteRelayTacticsPanel({
    super.key,
    required this.missionState,
    required this.currentStageKm,
    this.onSendToBreakaway,
    this.onWaitForGcLeader,
    this.onAbortRelay,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 520;
        final bool isDesktopWide = constraints.maxWidth >= 900;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: missionState.isWaitingForLeader
                  ? AppColors.goldAccent
                  : missionState.isPullingLeader
                      ? AppColors.statusSuccess
                      : AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildHeader(isCompact),
              const SizedBox(height: 12),
              _buildPhaseStepper(isCompact),
              const SizedBox(height: 12),
              if (isDesktopWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: _buildTelemetryGrid(isCompact)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _buildActionControls(isCompact)),
                  ],
                )
              else ...<Widget>[
                _buildTelemetryGrid(isCompact),
                const SizedBox(height: 12),
                _buildActionControls(isCompact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final Color badgeColor = _phaseBadgeColor(missionState.phase);
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'STACJA PRZEKAŹNIKOWA: ${missionState.satelliteRiderName} → ${missionState.gcLeaderName}',
            maxLines: isCompact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: badgeColor.withValues(alpha: 0.55)),
          ),
          child: Text(
            missionState.phase.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseStepper(bool isCompact) {
    final int activeStep = _phaseStepIndex(missionState.phase);
    final List<String> steps = isCompact
        ? const <String>['Ucieczka', 'Wait GC', 'Dolina', 'Podjazd']
        : const <String>[
            '1. Poranna ucieczka',
            '2. Wait for GC Leader',
            '3. Dolina',
            '4. Finałowy podjazd',
          ];

    return Row(
      children: List<Widget>.generate(steps.length, (int i) {
        final bool isDone = activeStep > i;
        final bool isCurrent = activeStep == i;
        final Color fill = isCurrent
            ? AppColors.goldAccent
            : isDone
                ? AppColors.statusSuccess
                : AppColors.surfaceLight;
        final Color textColor = isCurrent || isDone
            ? AppColors.textPrimary
            : AppColors.textSecondary;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.goldAccent
                      : isDone
                          ? AppColors.statusSuccess.withValues(alpha: 0.6)
                          : AppColors.cardBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: fill,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      steps[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 10 : 11,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTelemetryGrid(bool isCompact) {
    final String gapLabel =
        '${missionState.gapToGcLeaderSeconds.toStringAsFixed(1)} s (${missionState.gapToGcLeaderMeters.round()} m)';
    final String valleyKm =
        '${(missionState.valleyPullMeters / 1000.0).toStringAsFixed(1)} km';
    final String savedEnergy =
        '${(missionState.leaderEnergySavedJoules / 1000.0).toStringAsFixed(1)} kJ (${missionState.lastLeaderWattsSaved.round()} W)';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _TelemetryChip(
          label: 'Luka do Lidera GC',
          value: gapLabel,
          accentColor: AppColors.accentBlue,
          compact: isCompact,
        ),
        _TelemetryChip(
          label: 'Praca w dolinie',
          value: valleyKm,
          accentColor: AppColors.statusSuccess,
          compact: isCompact,
        ),
        _TelemetryChip(
          label: 'Oszczędność Lidera',
          value: savedEnergy,
          accentColor: AppColors.goldAccent,
          compact: isCompact,
        ),
      ],
    );
  }

  Widget _buildActionControls(bool isCompact) {
    final bool canSendBreakaway =
        missionState.phase == SatelliteRelayPhase.inactive &&
            onSendToBreakaway != null;
    final bool canWaitForLeader =
        missionState.phase == SatelliteRelayPhase.inMorningBreakaway &&
            onWaitForGcLeader != null;
    final bool canAbort = missionState.isActive && onAbortRelay != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _TacticalRelayButton(
          label: 'Wyślij do ucieczki',
          icon: Icons.directions_bike_rounded,
          accentColor: AppColors.accentBlue,
          enabled: canSendBreakaway,
          onPressed: onSendToBreakaway,
        ),
        _TacticalRelayButton(
          label: 'Wait for GC Leader',
          icon: Icons.hourglass_bottom_rounded,
          accentColor: AppColors.goldAccent,
          enabled: canWaitForLeader,
          onPressed: onWaitForGcLeader,
        ),
        _TacticalRelayButton(
          label: 'Anuluj',
          icon: Icons.close_rounded,
          accentColor: AppColors.crimsonAlert,
          enabled: canAbort,
          onPressed: onAbortRelay,
        ),
      ],
    );
  }

  Color _phaseBadgeColor(SatelliteRelayPhase phase) {
    switch (phase) {
      case SatelliteRelayPhase.inactive:
        return AppColors.textSecondary;
      case SatelliteRelayPhase.inMorningBreakaway:
        return AppColors.accentBlue;
      case SatelliteRelayPhase.waitingOnPenultimatePass:
        return AppColors.goldAccent;
      case SatelliteRelayPhase.rendezvousAndValleyPull:
      case SatelliteRelayPhase.finalClimbLeadout:
        return AppColors.statusSuccess;
      case SatelliteRelayPhase.completed:
        return AppColors.cyanAccent;
      case SatelliteRelayPhase.aborted:
        return AppColors.crimsonAlert;
    }
  }

  int _phaseStepIndex(SatelliteRelayPhase phase) {
    switch (phase) {
      case SatelliteRelayPhase.inactive:
        return -1;
      case SatelliteRelayPhase.inMorningBreakaway:
        return 0;
      case SatelliteRelayPhase.waitingOnPenultimatePass:
        return 1;
      case SatelliteRelayPhase.rendezvousAndValleyPull:
        return 2;
      case SatelliteRelayPhase.finalClimbLeadout:
      case SatelliteRelayPhase.completed:
        return 3;
      case SatelliteRelayPhase.aborted:
        return -1;
    }
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final bool compact;

  const _TelemetryChip({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticalRelayButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final VoidCallback? onPressed;

  const _TacticalRelayButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    this.onPressed,
  });

  @override
  State<_TacticalRelayButton> createState() => _TacticalRelayButtonState();
}

class _TacticalRelayButtonState extends State<_TacticalRelayButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.enabled && widget.onPressed != null;
    final Color bg = !interactive
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _isPressed
            ? widget.accentColor.withValues(alpha: 0.28)
            : _isHovered
                ? widget.accentColor.withValues(alpha: 0.20)
                : AppColors.surfaceLight;

    final Color border = !interactive
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.goldAccent
            : _isHovered || _isPressed
                ? widget.accentColor
                : AppColors.cardBorder;

    final Color fg = !interactive
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.accentColor;

    return FocusableActionDetector(
      enabled: interactive,
      onShowFocusHighlight: (bool focused) {
        setState(() => _isFocused = focused);
      },
      onShowHoverHighlight: (bool hovered) {
        setState(() => _isHovered = hovered);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            if (interactive) widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: interactive ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: interactive ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            interactive ? () => setState(() => _isPressed = false) : null,
        onTap: interactive ? widget.onPressed : null,
        child: MouseRegion(
          cursor:
              interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(widget.icon, size: 15, color: fg),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: !interactive ? fg : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
