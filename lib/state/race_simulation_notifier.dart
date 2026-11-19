import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/events/race_incident_engine.dart';
import '../engine/events/race_radio_generator.dart';
import '../engine/peloton/drafting_grid_system.dart';
import '../engine/peloton/rider_race_state.dart';
import '../engine/simulation/key_moments_detector.dart';
import '../engine/simulation/stage_results_calculator.dart';
import '../engine/simulation/stage_simulation_loop.dart';
import '../models/equipment/complete_bike.dart';
import '../models/race/race_stage.dart';
import '../models/race/stage_segment.dart';
import '../models/rider/rider.dart';
import '../models/team/cycling_team.dart';

/// Błyskawiczny snapshot telemetryczny i przestrzenny kolarza emitowany co sekundę.
/// Wykorzystywany jednocześnie przez widok trójwymiarowy szosy (3D) oraz profil wysokościowy (2.5D/2D).
class RiderPositionSnapshot {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String teamId;
  final String teamName;
  final String teamJerseyHexColor;
  final bool isPlayerRider;

  // Koordynaty wzdłużne i wysokościowe trasy (2D / Profil)
  final double distanceCoveredMeters;
  final double kilometerMark;
  final double elevationMeters;
  final double currentGradientPercent;
  final int currentSegmentIndex;

  // Dynamika i fizyka kolarza (3D / Telemetria)
  final double speedMs;
  final double speedKmh;
  final int powerWatts;
  final double wattsPerKg;
  final int cadenceRpm;
  final int heartRateBpm;

  // Fizjologia i zapasy energetyczne
  final double wPrimePercentage;
  final double wPrimeJoules;
  final double glycogenPercentage;
  final double glycogenGrams;
  final double hydrationPercent;
  final int bidonsLeft;
  final int gelsLeft;

  // Taktyka i pozycja w formacji peletonu (3D Grid & Wachlarz)
  final TacticalOrder activeTacticalOrder;
  final int groupIndex;
  final GroupType groupType;
  final double timeGapToLeaderSeconds;
  final double lateralPositionRoad; // [-1.0: lewa krawędź, 0.0: środek, 1.0: prawa]
  final double lateralOffsetRoadMeters; // Odchylenie w metrach od osi jezdni [-3.5m do +3.5m]
  final bool isDrafting;
  final double draftingSavingsPercent;
  final bool isPulling;

  // Status incydentów i mety
  final bool hasDefect;
  final IncidentType? defectType;
  final bool isCrashed;
  final bool isDnf;
  final int? finishRank;

  const RiderPositionSnapshot({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.teamId,
    required this.teamName,
    required this.teamJerseyHexColor,
    required this.isPlayerRider,
    required this.distanceCoveredMeters,
    required this.kilometerMark,
    required this.elevationMeters,
    required this.currentGradientPercent,
    required this.currentSegmentIndex,
    required this.speedMs,
    required this.speedKmh,
    required this.powerWatts,
    required this.wattsPerKg,
    required this.cadenceRpm,
    required this.heartRateBpm,
    required this.wPrimePercentage,
    required this.wPrimeJoules,
    required this.glycogenPercentage,
    required this.glycogenGrams,
    required this.hydrationPercent,
    required this.bidonsLeft,
    required this.gelsLeft,
    required this.activeTacticalOrder,
    required this.groupIndex,
    required this.groupType,
    required this.timeGapToLeaderSeconds,
    required this.lateralPositionRoad,
    required this.lateralOffsetRoadMeters,
    required this.isDrafting,
    required this.draftingSavingsPercent,
    required this.isPulling,
    this.hasDefect = false,
    this.defectType,
    this.isCrashed = false,
    this.isDnf = false,
    this.finishRank,
  });

  RiderPositionSnapshot copyWith({
    String? riderId,
    String? riderName,
    int? bibNumber,
    String? teamId,
    String? teamName,
    String? teamJerseyHexColor,
    bool? isPlayerRider,
    double? distanceCoveredMeters,
    double? kilometerMark,
    double? elevationMeters,
    double? currentGradientPercent,
    int? currentSegmentIndex,
    double? speedMs,
    double? speedKmh,
    int? powerWatts,
    double? wattsPerKg,
    int? cadenceRpm,
    int? heartRateBpm,
    double? wPrimePercentage,
    double? wPrimeJoules,
    double? glycogenPercentage,
    double? glycogenGrams,
    double? hydrationPercent,
    int? bidonsLeft,
    int? gelsLeft,
    TacticalOrder? activeTacticalOrder,
    int? groupIndex,
    GroupType? groupType,
    double? timeGapToLeaderSeconds,
    double? lateralPositionRoad,
    double? lateralOffsetRoadMeters,
    bool? isDrafting,
    double? draftingSavingsPercent,
    bool? isPulling,
    bool? hasDefect,
    IncidentType? defectType,
    bool? isCrashed,
    bool? isDnf,
    int? finishRank,
  }) {
    return RiderPositionSnapshot(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      bibNumber: bibNumber ?? this.bibNumber,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamJerseyHexColor: teamJerseyHexColor ?? this.teamJerseyHexColor,
      isPlayerRider: isPlayerRider ?? this.isPlayerRider,
      distanceCoveredMeters: distanceCoveredMeters ?? this.distanceCoveredMeters,
      kilometerMark: kilometerMark ?? this.kilometerMark,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      currentGradientPercent: currentGradientPercent ?? this.currentGradientPercent,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      speedMs: speedMs ?? this.speedMs,
      speedKmh: speedKmh ?? this.speedKmh,
      powerWatts: powerWatts ?? this.powerWatts,
      wattsPerKg: wattsPerKg ?? this.wattsPerKg,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      wPrimePercentage: wPrimePercentage ?? this.wPrimePercentage,
      wPrimeJoules: wPrimeJoules ?? this.wPrimeJoules,
      glycogenPercentage: glycogenPercentage ?? this.glycogenPercentage,
      glycogenGrams: glycogenGrams ?? this.glycogenGrams,
      hydrationPercent: hydrationPercent ?? this.hydrationPercent,
      bidonsLeft: bidonsLeft ?? this.bidonsLeft,
      gelsLeft: gelsLeft ?? this.gelsLeft,
      activeTacticalOrder: activeTacticalOrder ?? this.activeTacticalOrder,
      groupIndex: groupIndex ?? this.groupIndex,
      groupType: groupType ?? this.groupType,
      timeGapToLeaderSeconds: timeGapToLeaderSeconds ?? this.timeGapToLeaderSeconds,
      lateralPositionRoad: lateralPositionRoad ?? this.lateralPositionRoad,
      lateralOffsetRoadMeters: lateralOffsetRoadMeters ?? this.lateralOffsetRoadMeters,
      isDrafting: isDrafting ?? this.isDrafting,
      draftingSavingsPercent: draftingSavingsPercent ?? this.draftingSavingsPercent,
      isPulling: isPulling ?? this.isPulling,
      hasDefect: hasDefect ?? this.hasDefect,
      defectType: defectType ?? this.defectType,
      isCrashed: isCrashed ?? this.isCrashed,
      isDnf: isDnf ?? this.isDnf,
      finishRank: finishRank ?? this.finishRank,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'bibNumber': bibNumber,
      'teamId': teamId,
      'teamName': teamName,
      'teamJerseyHexColor': teamJerseyHexColor,
      'isPlayerRider': isPlayerRider,
      'distanceCoveredMeters': distanceCoveredMeters,
      'kilometerMark': kilometerMark,
      'elevationMeters': elevationMeters,
      'currentGradientPercent': currentGradientPercent,
      'currentSegmentIndex': currentSegmentIndex,
      'speedMs': speedMs,
      'speedKmh': speedKmh,
      'powerWatts': powerWatts,
      'wattsPerKg': wattsPerKg,
      'cadenceRpm': cadenceRpm,
      'heartRateBpm': heartRateBpm,
      'wPrimePercentage': wPrimePercentage,
      'wPrimeJoules': wPrimeJoules,
      'glycogenPercentage': glycogenPercentage,
      'glycogenGrams': glycogenGrams,
      'hydrationPercent': hydrationPercent,
      'bidonsLeft': bidonsLeft,
      'gelsLeft': gelsLeft,
      'activeTacticalOrder': activeTacticalOrder.toJson(),
      'groupIndex': groupIndex,
      'groupType': groupType.toJson(),
      'timeGapToLeaderSeconds': timeGapToLeaderSeconds,
      'lateralPositionRoad': lateralPositionRoad,
      'lateralOffsetRoadMeters': lateralOffsetRoadMeters,
      'isDrafting': isDrafting,
      'draftingSavingsPercent': draftingSavingsPercent,
      'isPulling': isPulling,
      'hasDefect': hasDefect,
      'defectType': defectType?.toJson(),
      'isCrashed': isCrashed,
      'isDnf': isDnf,
      'finishRank': finishRank,
    };
  }

  factory RiderPositionSnapshot.fromJson(Map<String, dynamic> json) {
    return RiderPositionSnapshot(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      bibNumber: (json['bibNumber'] as num).toInt(),
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      teamJerseyHexColor: json['teamJerseyHexColor'] as String,
      isPlayerRider: json['isPlayerRider'] as bool,
      distanceCoveredMeters: (json['distanceCoveredMeters'] as num).toDouble(),
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      elevationMeters: (json['elevationMeters'] as num).toDouble(),
      currentGradientPercent: (json['currentGradientPercent'] as num).toDouble(),
      currentSegmentIndex: (json['currentSegmentIndex'] as num).toInt(),
      speedMs: (json['speedMs'] as num).toDouble(),
      speedKmh: (json['speedKmh'] as num).toDouble(),
      powerWatts: (json['powerWatts'] as num).toInt(),
      wattsPerKg: (json['wattsPerKg'] as num).toDouble(),
      cadenceRpm: (json['cadenceRpm'] as num).toInt(),
      heartRateBpm: (json['heartRateBpm'] as num).toInt(),
      wPrimePercentage: (json['wPrimePercentage'] as num).toDouble(),
      wPrimeJoules: (json['wPrimeJoules'] as num).toDouble(),
      glycogenPercentage: (json['glycogenPercentage'] as num).toDouble(),
      glycogenGrams: (json['glycogenGrams'] as num).toDouble(),
      hydrationPercent: (json['hydrationPercent'] as num).toDouble(),
      bidonsLeft: (json['bidonsLeft'] as num).toInt(),
      gelsLeft: (json['gelsLeft'] as num).toInt(),
      activeTacticalOrder: TacticalOrder.fromJson(json['activeTacticalOrder'] as String),
      groupIndex: (json['groupIndex'] as num).toInt(),
      groupType: GroupType.fromJson(json['groupType'] as String),
      timeGapToLeaderSeconds: (json['timeGapToLeaderSeconds'] as num).toDouble(),
      lateralPositionRoad: (json['lateralPositionRoad'] as num).toDouble(),
      lateralOffsetRoadMeters: (json['lateralOffsetRoadMeters'] as num).toDouble(),
      isDrafting: json['isDrafting'] as bool,
      draftingSavingsPercent: (json['draftingSavingsPercent'] as num).toDouble(),
      isPulling: json['isPulling'] as bool,
      hasDefect: json['hasDefect'] as bool? ?? false,
      defectType: json['defectType'] != null ? IncidentType.fromJson(json['defectType'] as String) : null,
      isCrashed: json['isCrashed'] as bool? ?? false,
      isDnf: json['isDnf'] as bool? ?? false,
      finishRank: json['finishRank'] as int?,
    );
  }
}

/// Alert o defekcie technicznym, przebiciu koła lub kraksie kolarza na trasie.
class RaceDefectAlert {
  final String id;
  final String victimRiderId;
  final String victimRiderName;
  final String teamId;
  final String teamName;
  final bool isPlayerTeam;
  final IncidentType incidentType;
  final double timeLostSeconds;
  final double timestampSeconds;
  final double kilometerMark;
  final bool isResolved;
  final AssistanceMethod? resolutionMethod;
  final String? helperRiderId;
  final String? helperRiderName;
  final String description;

  const RaceDefectAlert({
    required this.id,
    required this.victimRiderId,
    required this.victimRiderName,
    required this.teamId,
    required this.teamName,
    required this.isPlayerTeam,
    required this.incidentType,
    required this.timeLostSeconds,
    required this.timestampSeconds,
    required this.kilometerMark,
    required this.isResolved,
    this.resolutionMethod,
    this.helperRiderId,
    this.helperRiderName,
    required this.description,
  });

  RaceDefectAlert copyWith({
    String? id,
    String? victimRiderId,
    String? victimRiderName,
    String? teamId,
    String? teamName,
    bool? isPlayerTeam,
    IncidentType? incidentType,
    double? timeLostSeconds,
    double? timestampSeconds,
    double? kilometerMark,
    bool? isResolved,
    AssistanceMethod? resolutionMethod,
    String? helperRiderId,
    String? helperRiderName,
    String? description,
  }) {
    return RaceDefectAlert(
      id: id ?? this.id,
      victimRiderId: victimRiderId ?? this.victimRiderId,
      victimRiderName: victimRiderName ?? this.victimRiderName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      isPlayerTeam: isPlayerTeam ?? this.isPlayerTeam,
      incidentType: incidentType ?? this.incidentType,
      timeLostSeconds: timeLostSeconds ?? this.timeLostSeconds,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      kilometerMark: kilometerMark ?? this.kilometerMark,
      isResolved: isResolved ?? this.isResolved,
      resolutionMethod: resolutionMethod ?? this.resolutionMethod,
      helperRiderId: helperRiderId ?? this.helperRiderId,
      helperRiderName: helperRiderName ?? this.helperRiderName,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'victimRiderId': victimRiderId,
      'victimRiderName': victimRiderName,
      'teamId': teamId,
      'teamName': teamName,
      'isPlayerTeam': isPlayerTeam,
      'incidentType': incidentType.toJson(),
      'timeLostSeconds': timeLostSeconds,
      'timestampSeconds': timestampSeconds,
      'kilometerMark': kilometerMark,
      'isResolved': isResolved,
      'resolutionMethod': resolutionMethod?.toJson(),
      'helperRiderId': helperRiderId,
      'helperRiderName': helperRiderName,
      'description': description,
    };
  }

  factory RaceDefectAlert.fromJson(Map<String, dynamic> json) {
    return RaceDefectAlert(
      id: json['id'] as String,
      victimRiderId: json['victimRiderId'] as String,
      victimRiderName: json['victimRiderName'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      isPlayerTeam: json['isPlayerTeam'] as bool,
      incidentType: IncidentType.fromJson(json['incidentType'] as String),
      timeLostSeconds: (json['timeLostSeconds'] as num).toDouble(),
      timestampSeconds: (json['timestampSeconds'] as num).toDouble(),
      kilometerMark: (json['kilometerMark'] as num).toDouble(),
      isResolved: json['isResolved'] as bool,
      resolutionMethod: json['resolutionMethod'] != null
          ? AssistanceMethod.fromJson(json['resolutionMethod'] as String)
          : null,
      helperRiderId: json['helperRiderId'] as String?,
      helperRiderName: json['helperRiderName'] as String?,
      description: json['description'] as String,
    );
  }
}

/// Stan aktywny symulacji etapu dla Riverpod i interfejsu graficznego.
class ActiveRaceSimulationState {
  final StageSimulationState? simulationState;
  final bool isPaused;
  final SimulationTimeSpeed timeSpeed;
  final String? selectedRiderId;
  final List<RiderPositionSnapshot> riderPositions;
  final List<RiderPositionSnapshot> playerRidersPositions;
  final List<RaceDefectAlert> activeDefectAlerts;
  final double leadDistanceKm;
  final double distanceRemainingKm;
  final double breakawayGapSeconds;
  final double pelotonSpeedKmh;
  final KeyMomentTrigger? activeKeyMoment;
  final List<RaceRadioMessage> radioMessages;
  final StageSummaryReport? stageSummaryReport;
  final bool isStageFinished;

  const ActiveRaceSimulationState({
    this.simulationState,
    this.isPaused = false,
    this.timeSpeed = SimulationTimeSpeed.x1,
    this.selectedRiderId,
    this.riderPositions = const [],
    this.playerRidersPositions = const [],
    this.activeDefectAlerts = const [],
    this.leadDistanceKm = 0.0,
    this.distanceRemainingKm = 0.0,
    this.breakawayGapSeconds = 0.0,
    this.pelotonSpeedKmh = 42.0,
    this.activeKeyMoment,
    this.radioMessages = const [],
    this.stageSummaryReport,
    this.isStageFinished = false,
  });

  /// Czy etap jest zainicjalizowany
  bool get hasActiveStage => simulationState != null;

  /// Czy etap został zakończony
  bool get isFinished => simulationState?.isStageFinished ?? isStageFinished;

  /// Aktualny etap wyścigu
  RaceStage? get stage => simulationState?.stage;

  /// Aktualny segment trasy
  StageSegment? get currentSegment {
    final sim = simulationState;
    if (sim == null || sim.stage.segments.isEmpty) return null;
    final idx = sim.currentSegmentIndex.clamp(0, sim.stage.segments.length - 1);
    return sim.stage.segments[idx];
  }

  /// Wybrany kolarz (stan surowy)
  RiderRaceState? get selectedRiderState {
    if (selectedRiderId == null || simulationState == null) return null;
    return simulationState!.riderStates[selectedRiderId];
  }

  /// Kolarze gracza (stany surowe)
  List<RiderRaceState> get playerRiderStates {
    final sim = simulationState;
    if (sim == null) return const [];
    return sim.playerRiderIds
        .map((id) => sim.riderStates[id])
        .whereType<RiderRaceState>()
        .toList();
  }

  /// Snapshot aktualnie wybranego kolarza
  RiderPositionSnapshot? get selectedRider {
    if (selectedRiderId == null || riderPositions.isEmpty) return null;
    for (final p in riderPositions) {
      if (p.riderId == selectedRiderId) return p;
    }
    return null;
  }

  /// Lider drużyny gracza (pierwszy na liście lub najlepiej ustawiony)
  RiderPositionSnapshot? get playerTeamLeader {
    if (playerRidersPositions.isEmpty) return null;
    return playerRidersPositions.first;
  }

  /// Nierozwiązane defekty na trasie
  List<RaceDefectAlert> get unresolvedDefects =>
      activeDefectAlerts.where((d) => !d.isResolved).toList();

  /// Aktywny defekt w zespole gracza
  RaceDefectAlert? get activePlayerDefect {
    for (final d in activeDefectAlerts) {
      if (d.isPlayerTeam && !d.isResolved) return d;
    }
    return null;
  }

  /// Alias dla powiadomienia o kluczowym momencie (dla kompatybilności wstecznej)
  KeyMomentTrigger? get activeNotification => activeKeyMoment;

  ActiveRaceSimulationState copyWith({
    StageSimulationState? simulationState,
    bool? isPaused,
    SimulationTimeSpeed? timeSpeed,
    String? selectedRiderId,
    List<RiderPositionSnapshot>? riderPositions,
    List<RiderPositionSnapshot>? playerRidersPositions,
    List<RaceDefectAlert>? activeDefectAlerts,
    double? leadDistanceKm,
    double? distanceRemainingKm,
    double? breakawayGapSeconds,
    double? pelotonSpeedKmh,
    KeyMomentTrigger? activeKeyMoment,
    bool clearKeyMoment = false,
    List<RaceRadioMessage>? radioMessages,
    StageSummaryReport? stageSummaryReport,
    bool? isStageFinished,
  }) {
    return ActiveRaceSimulationState(
      simulationState: simulationState ?? this.simulationState,
      isPaused: isPaused ?? this.isPaused,
      timeSpeed: timeSpeed ?? this.timeSpeed,
      selectedRiderId: selectedRiderId ?? this.selectedRiderId,
      riderPositions: riderPositions ?? this.riderPositions,
      playerRidersPositions: playerRidersPositions ?? this.playerRidersPositions,
      activeDefectAlerts: activeDefectAlerts ?? this.activeDefectAlerts,
      leadDistanceKm: leadDistanceKm ?? this.leadDistanceKm,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      breakawayGapSeconds: breakawayGapSeconds ?? this.breakawayGapSeconds,
      pelotonSpeedKmh: pelotonSpeedKmh ?? this.pelotonSpeedKmh,
      activeKeyMoment: clearKeyMoment ? null : (activeKeyMoment ?? this.activeKeyMoment),
      radioMessages: radioMessages ?? this.radioMessages,
      stageSummaryReport: stageSummaryReport ?? this.stageSummaryReport,
      isStageFinished: isStageFinished ?? this.isStageFinished,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPaused': isPaused,
      'timeSpeed': timeSpeed.toJson(),
      'selectedRiderId': selectedRiderId,
      'riderPositions': riderPositions.map((e) => e.toJson()).toList(),
      'playerRidersPositions': playerRidersPositions.map((e) => e.toJson()).toList(),
      'activeDefectAlerts': activeDefectAlerts.map((e) => e.toJson()).toList(),
      'leadDistanceKm': leadDistanceKm,
      'distanceRemainingKm': distanceRemainingKm,
      'breakawayGapSeconds': breakawayGapSeconds,
      'pelotonSpeedKmh': pelotonSpeedKmh,
      'activeKeyMoment': activeKeyMoment?.toJson(),
      'stageSummaryReport': stageSummaryReport?.toJson(),
      'isStageFinished': isStageFinished,
    };
  }

  factory ActiveRaceSimulationState.fromJson(Map<String, dynamic> json) {
    return ActiveRaceSimulationState(
      isPaused: json['isPaused'] as bool? ?? false,
      timeSpeed: json['timeSpeed'] != null
          ? SimulationTimeSpeed.values.firstWhere(
              (s) => s.name == json['timeSpeed'],
              orElse: () => SimulationTimeSpeed.x1,
            )
          : SimulationTimeSpeed.x1,
      selectedRiderId: json['selectedRiderId'] as String?,
      riderPositions: (json['riderPositions'] as List<dynamic>? ?? [])
          .map((e) => RiderPositionSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      playerRidersPositions: (json['playerRidersPositions'] as List<dynamic>? ?? [])
          .map((e) => RiderPositionSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeDefectAlerts: (json['activeDefectAlerts'] as List<dynamic>? ?? [])
          .map((e) => RaceDefectAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
      leadDistanceKm: (json['leadDistanceKm'] as num?)?.toDouble() ?? 0.0,
      distanceRemainingKm: (json['distanceRemainingKm'] as num?)?.toDouble() ?? 0.0,
      breakawayGapSeconds: (json['breakawayGapSeconds'] as num?)?.toDouble() ?? 0.0,
      pelotonSpeedKmh: (json['pelotonSpeedKmh'] as num?)?.toDouble() ?? 42.0,
      activeKeyMoment: json['activeKeyMoment'] != null
          ? KeyMomentTrigger.fromJson(json['activeKeyMoment'] as Map<String, dynamic>)
          : null,
      stageSummaryReport: json['stageSummaryReport'] != null
          ? StageSummaryReport.fromJson(json['stageSummaryReport'] as Map<String, dynamic>)
          : null,
      isStageFinished: json['isStageFinished'] as bool? ?? false,
    );
  }
}

/// Główny kontroler stanu aktywnego wyścigu kolarskiego (Riverpod).
/// Zarządza instancją [StageSimulationLoop], udostępnia strumień pozycji co sekundę
/// dla widoku 3D oraz profilu 2D, pozwala wydawać rozkazy taktyczne, zarządzać żywieniem
/// oraz reagować na defekty mechaniczne i kraksy.
class RaceSimulationNotifier extends StateNotifier<ActiveRaceSimulationState> {
  RaceSimulationNotifier() : super(const ActiveRaceSimulationState());

  StageSimulationLoop? _loop;
  Timer? _tickerTimer;

  // Strumień pozycji kolarzy (1 Hz lub per-tick) dla silników renderingu 3D i wykresów 2D
  final StreamController<List<RiderPositionSnapshot>> _positionStreamController =
      StreamController<List<RiderPositionSnapshot>>.broadcast();

  Map<String, Rider> _allRidersMap = const {};
  Map<String, CompleteBike> _allBikesMap = const {};
  Map<String, CyclingTeam> _allTeamsMap = const {};
  final List<RaceDefectAlert> _defectAlerts = [];
  final Set<String> _processedIncidentIds = {};

  /// Dostęp do strumienia pozycji kolarzy
  Stream<List<RiderPositionSnapshot>> get positionStream => _positionStreamController.stream;

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _positionStreamController.close();
    super.dispose();
  }

  /// Inicjalizuje nowo rozpoczęty etap wyścigu z kompletną obsadą peletonu
  void initializeStage({
    required RaceStage stage,
    required String playerTeamId,
    required Map<String, Rider> allRidersMap,
    required Map<String, CompleteBike> allBikesMap,
    required Map<String, CyclingTeam> allTeamsMap,
  }) {
    _tickerTimer?.cancel();
    _defectAlerts.clear();
    _processedIncidentIds.clear();

    _allRidersMap = Map<String, Rider>.from(allRidersMap);
    _allBikesMap = Map<String, CompleteBike>.from(allBikesMap);
    _allTeamsMap = Map<String, CyclingTeam>.from(allTeamsMap);

    _loop = StageSimulationLoop.initializeStage(
      stage: stage,
      playerTeamId: playerTeamId,
      allRidersMap: _allRidersMap,
      allBikesMap: _allBikesMap,
      allTeamsMap: _allTeamsMap,
    );

    final playerTeam = _allTeamsMap[playerTeamId];
    final defaultSelectedRider = (playerTeam?.rosterRiderIds.isNotEmpty ?? false)
        ? playerTeam!.rosterRiderIds.first
        : (allRidersMap.keys.isNotEmpty ? allRidersMap.keys.first : null);

    final initialSnapshots = _computeSnapshots(_loop!.state);
    final playerSnapshots = initialSnapshots.where((s) => s.isPlayerRider).toList();

    state = ActiveRaceSimulationState(
      simulationState: _loop!.state,
      isPaused: false,
      timeSpeed: SimulationTimeSpeed.x1,
      selectedRiderId: defaultSelectedRider,
      riderPositions: initialSnapshots,
      playerRidersPositions: playerSnapshots,
      activeDefectAlerts: const [],
      leadDistanceKm: 0.0,
      distanceRemainingKm: stage.totalDistanceKm,
      breakawayGapSeconds: 0.0,
      pelotonSpeedKmh: 42.0,
      activeKeyMoment: null,
      radioMessages: _loop!.state.radioLog,
      stageSummaryReport: null,
      isStageFinished: false,
    );

    _positionStreamController.add(initialSnapshots);
    _startTicker();
  }

  /// Uruchamia pętlę zegara symulacji (10 Hz dla płynności obliczeń fizycznych i HUD)
  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!state.isPaused && _loop != null && !_loop!.state.isStageFinished) {
        stepSimulation(0.1);
      }
    });
  }

  /// Wykonuje pojedynczy krok symulacji fizyki i aktualizuje stan
  void stepSimulation(double realDeltaSeconds) {
    if (_loop == null || state.isPaused) return;

    final multiplier = _loop!.state.timeSpeed.multiplier;
    final dt = realDeltaSeconds * multiplier;

    final newState = _loop!.step(dt: dt);

    // Wykrywanie nowych incydentów z silnika zdarzeń
    _detectNewIncidents(newState);

    // Przeliczenie pozycji dla widoku 3D i 2D
    final snapshots = _computeSnapshots(newState);
    final playerSnapshots = snapshots.where((s) => s.isPlayerRider).toList();

    // Wyliczenie różnicy ucieczki i peletonu
    double breakawayGap = 0.0;
    double pelotonSpeed = 42.0;
    if (newState.groups.isNotEmpty) {
      final leadGroup = newState.groups.first;
      if (newState.groups.length > 1) {
        final mainPeloton = newState.groups.firstWhere(
          (g) => g.type == GroupType.peloton,
          orElse: () => newState.groups[1],
        );
        breakawayGap = mainPeloton.gapToRaceLeaderSeconds;
        pelotonSpeed = mainPeloton.averageSpeedKmh;
      } else {
        pelotonSpeed = leadGroup.averageSpeedKmh;
      }
    }

    state = state.copyWith(
      simulationState: newState,
      riderPositions: snapshots,
      playerRidersPositions: playerSnapshots,
      activeDefectAlerts: List<RaceDefectAlert>.from(_defectAlerts),
      leadDistanceKm: newState.leadKilometerMark,
      distanceRemainingKm: newState.leadDistanceToFinishKm,
      breakawayGapSeconds: breakawayGap,
      pelotonSpeedKmh: pelotonSpeed,
      activeKeyMoment: newState.activeKeyMoment ?? state.activeKeyMoment,
      radioMessages: newState.radioLog,
      isStageFinished: newState.isStageFinished,
    );

    // Emisja aktualizacji do strumienia pozycji
    _positionStreamController.add(snapshots);

    // Jeśli etap dobiegł końca, automatycznie podliczamy oficjalne wyniki UCI
    if (newState.isStageFinished && state.stageSummaryReport == null) {
      _concludeStage();
    }
  }

  /// Błyskawiczne przeliczenie do następnego kluczowego momentu lub mety
  void simulateToNextKeyMoment({int maxSteps = 20000, double stepDt = 2.0}) {
    if (_loop == null) return;

    final updatedState = _loop!.simulateToNextKeyMoment(maxSteps: maxSteps, stepDt: stepDt);
    _detectNewIncidents(updatedState);

    final snapshots = _computeSnapshots(updatedState);
    final playerSnapshots = snapshots.where((s) => s.isPlayerRider).toList();

    state = state.copyWith(
      simulationState: updatedState,
      riderPositions: snapshots,
      playerRidersPositions: playerSnapshots,
      activeDefectAlerts: List<RaceDefectAlert>.from(_defectAlerts),
      leadDistanceKm: updatedState.leadKilometerMark,
      distanceRemainingKm: updatedState.leadDistanceToFinishKm,
      activeKeyMoment: updatedState.activeKeyMoment,
      radioMessages: updatedState.radioLog,
      isStageFinished: updatedState.isStageFinished,
    );

    _positionStreamController.add(snapshots);

    if (updatedState.isStageFinished && state.stageSummaryReport == null) {
      _concludeStage();
    }
  }

  /// Ustawia mnożnik prędkości symulacji
  void setSimulationSpeed(SimulationTimeSpeed speed) {
    if (_loop == null) return;
    _loop!.setSpeed(speed);
    state = state.copyWith(timeSpeed: speed, simulationState: _loop!.state);

    if (speed == SimulationTimeSpeed.instantToKeyMoment) {
      simulateToNextKeyMoment();
    }
  }

  /// Zatrzymuje symulację (Pauza)
  void pause() {
    state = state.copyWith(isPaused: true);
  }

  /// Wznawia symulację
  void resume() {
    state = state.copyWith(isPaused: false);
  }

  /// Przełącza pauzę
  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  /// Wybiera kolarza do śledzenia w kamerze HUD
  void selectRider(String riderId) {
    state = state.copyWith(selectedRiderId: riderId);
  }

  /// Zamyka aktywne powiadomienie o kluczowym momencie
  void dismissActiveKeyMoment() {
    if (_loop != null) {
      _loop!.dismissActiveKeyMoment();
    }
    state = state.copyWith(clearKeyMoment: true);
  }

  /// Alias powiadomienia dla kompatybilności wstecznej
  void dismissNotification() => dismissActiveKeyMoment();

  // ==========================================
  // POLECENIA TAKTYCZNE DLA KOLARZY (7-8 ZAWODNIKÓW)
  // ==========================================

  /// Wydaje rozkaz taktyczny wybranemu kolarzowi gracza
  void setRiderTacticalOrder(String riderId, TacticalOrder newOrder) {
    if (_loop == null) return;
    _loop!.setRiderTacticalOrder(riderId, newOrder);

    // Odświeżenie stanu
    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
  }

  /// Alias polecenia taktycznego dla kompatybilności wstecznej
  void issueTacticalOrder(String riderId, TacticalOrder order) =>
      setRiderTacticalOrder(riderId, order);

  /// Rozkaz: Atakuj / Skacz z grupy
  void orderRiderAttack(String riderId) =>
      setRiderTacticalOrder(riderId, TacticalOrder.attack);

  /// Rozkaz: Chroń lidera zespołu
  void orderRiderProtectLeader(String helperId, {String? leaderId}) =>
      setRiderTacticalOrder(helperId, TacticalOrder.protectLeader);

  /// Rozkaz: Dawaj mocne zmiany na czele grupy
  void orderRiderPullGroup(String riderId) =>
      setRiderTacticalOrder(riderId, TacticalOrder.pullGroup);

  /// Rozkaz: Maksymalnie oszczędzaj energię
  void orderRiderSaveEnergy(String riderId) =>
      setRiderTacticalOrder(riderId, TacticalOrder.saveEnergy);

  /// Rozkaz: Utrzymuj stałą pozycję w szyku
  void orderRiderHoldPosition(String riderId) =>
      setRiderTacticalOrder(riderId, TacticalOrder.holdPosition);

  /// Rozkaz: Pilnuj koła bezpośrednich rywali
  void orderRiderFollowWheels(String riderId) =>
      setRiderTacticalOrder(riderId, TacticalOrder.followWheels);

  /// Wydaje polecenie całej formacji drużyny gracza
  void orderTeamTactics({required TacticalOrder order, List<String>? riderIds}) {
    if (_loop == null) return;
    final targets = riderIds ?? _loop!.state.playerRiderIds;
    for (final id in targets) {
      _loop!.setRiderTacticalOrder(id, order);
    }
    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
  }

  // ==========================================
  // ŻYWIENIE I NAWADNIANIE (GELS & BIDONS)
  // ==========================================

  /// Podaje żel energetyczny kolarzowi (+30g węglowodanów)
  bool feedGelToRider(String riderId) {
    if (_loop == null) return false;
    final rState = _loop!.state.riderStates[riderId];
    if (rState == null || rState.gelsLeft <= 0) return false;

    _loop!.consumeGelForRider(riderId);

    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
    return true;
  }

  /// Podaje bidon z izotonikiem/wodą kolarzowi (+500ml nawodnienia)
  bool giveBidonToRider(String riderId) {
    if (_loop == null) return false;
    final rState = _loop!.state.riderStates[riderId];
    if (rState == null || rState.bidonsLeft <= 0) return false;

    _loop!.drinkBidonForRider(riderId);

    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
    return true;
  }

  /// Wysyła pomocnika do wozu technicznego po zestaw bidonów i żeli dla całej drużyny
  bool sendDomestiqueForBidons(String domestiqueId) {
    if (_loop == null) return false;
    final dom = _allRidersMap[domestiqueId];
    if (dom == null) return false;

    _loop!.setRiderTacticalOrder(domestiqueId, TacticalOrder.fetchBidonsFromCar);
    _loop!.distributeBidonsFromDomestique(domestiqueId, totalBidons: 6);

    // Zapewniamy także uzupełnienie żeli kolegom
    for (final id in _loop!.state.playerRiderIds) {
      if (id != domestiqueId) {
        _loop!.refillGelsForRider(id, count: 2);
      }
    }

    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
    return true;
  }

  /// Dostarcza zaopatrzenie z wozu technicznego bezpośrednio do kolarza
  bool orderCarFeed(String riderId) {
    if (_loop == null) return false;
    _loop!.refillBidonsForRider(riderId, count: 2);
    _loop!.refillGelsForRider(riderId, count: 2);

    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
    return true;
  }

  // ==========================================
  // REAKCJA NA DEFEKTY I INCYDENTY
  // ==========================================

  /// Błyskawiczna wymiana roweru: pomocnik oddaje swoją maszynę liderowi (~14s)
  bool resolveDefectWithTeammateBikeSwap(String victimId, String helperId) {
    if (_loop == null) return false;

    _loop!.applyIncidentResolution(
      victimId: victimId,
      timeLostSeconds: 14.0,
      method: AssistanceMethod.teammateBikeSwap,
      helperId: helperId,
    );

    // Oznaczamy alert jako rozwiązany
    final idx = _defectAlerts.indexWhere((a) => a.victimRiderId == victimId && !a.isResolved);
    if (idx != -1) {
      final helper = _allRidersMap[helperId];
      _defectAlerts[idx] = _defectAlerts[idx].copyWith(
        isResolved: true,
        resolutionMethod: AssistanceMethod.teammateBikeSwap,
        helperRiderId: helperId,
        helperRiderName: helper?.fullName ?? 'Pomocnik',
        description: 'Błyskawiczna wymiana roweru! ${helper?.fullName ?? 'Pomocnik'} oddał rower liderowi.',
      );
    }

    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      activeDefectAlerts: List<RaceDefectAlert>.from(_defectAlerts),
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
    return true;
  }

  /// Wymiana koła / roweru przez wóz techniczny drużyny (~40s)
  bool resolveDefectWithTeamCar(String victimId) {
    if (_loop == null) return false;

    _loop!.applyIncidentResolution(
      victimId: victimId,
      timeLostSeconds: 40.0,
      method: AssistanceMethod.teamCarService,
    );

    final idx = _defectAlerts.indexWhere((a) => a.victimRiderId == victimId && !a.isResolved);
    if (idx != -1) {
      _defectAlerts[idx] = _defectAlerts[idx].copyWith(
        isResolved: true,
        resolutionMethod: AssistanceMethod.teamCarService,
        description: 'Serwis wozu technicznego zakończony. Kolarz wraca do walki.',
      );
    }

    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      activeDefectAlerts: List<RaceDefectAlert>.from(_defectAlerts),
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
    return true;
  }

  /// Pomoc techniczna neutralnego wozu Shimano / Mavic (~30s)
  bool resolveDefectWithNeutralService(String victimId) {
    if (_loop == null) return false;

    _loop!.applyIncidentResolution(
      victimId: victimId,
      timeLostSeconds: 30.0,
      method: AssistanceMethod.neutralService,
    );

    final idx = _defectAlerts.indexWhere((a) => a.victimRiderId == victimId && !a.isResolved);
    if (idx != -1) {
      _defectAlerts[idx] = _defectAlerts[idx].copyWith(
        isResolved: true,
        resolutionMethod: AssistanceMethod.neutralService,
        description: 'Neutralny serwis Shimano wymienił koło. Kolarz goni peleton.',
      );
    }

    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      activeDefectAlerts: List<RaceDefectAlert>.from(_defectAlerts),
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
    return true;
  }

  /// Rozkazuje wybranym pomocnikom cofnąć się i holować poszkodowanego kolarza
  void orderTeammatesToPaceBack(String victimId, List<String> helperIds) {
    if (_loop == null) return;
    for (final hId in helperIds) {
      if (hId == victimId) continue;
      // Pomocnik przechodzi na nadawanie ostrego tempa
      _loop!.setRiderTacticalOrder(hId, TacticalOrder.pullGroup);
    }
    // Poszkodowany chowa się za ich kołami
    _loop!.setRiderTacticalOrder(victimId, TacticalOrder.followWheels);

    final snapshots = _computeSnapshots(_loop!.state);
    state = state.copyWith(
      simulationState: _loop!.state,
      riderPositions: snapshots,
      playerRidersPositions: snapshots.where((s) => s.isPlayerRider).toList(),
    );
  }

  // ==========================================
  // OBLICZENIA I KONWERSJA TELEMETRII (3D / 2D)
  // ==========================================

  void _detectNewIncidents(StageSimulationState simState) {
    for (final inc in simState.incidentHistory) {
      if (_processedIncidentIds.contains(inc.id)) continue;
      _processedIncidentIds.add(inc.id);

      for (final victim in inc.primaryVictims) {
        final rider = _allRidersMap[victim.riderId];
        final team = _allTeamsMap[victim.teamId];
        final isPlayer = victim.teamId == simState.playerTeamId;

        final alert = RaceDefectAlert(
          id: '${inc.id}_${victim.riderId}',
          victimRiderId: victim.riderId,
          victimRiderName: rider?.fullName ?? victim.riderName,
          teamId: victim.teamId,
          teamName: team?.name ?? victim.teamId,
          isPlayerTeam: isPlayer,
          incidentType: victim.incidentType,
          timeLostSeconds: victim.timeLostSeconds,
          timestampSeconds: simState.elapsedSeconds,
          kilometerMark: inc.kilometerMark,
          isResolved: false,
          description: victim.description,
        );

        _defectAlerts.insert(0, alert);
      }
    }
  }

  List<RiderPositionSnapshot> _computeSnapshots(StageSimulationState simState) {
    final List<RiderPositionSnapshot> results = [];
    final stage = simState.stage;

    // Mapa pozycji w siatce draftingowej dla poszczególnych kolarzy
    final Map<String, GridRiderPosition> gridPositionsMap = {};
    final Map<String, GroupType> groupTypeMap = {};
    for (final group in simState.groups) {
      for (final pos in group.positions) {
        gridPositionsMap[pos.riderId] = pos;
        groupTypeMap[pos.riderId] = group.type;
      }
    }

    // Mapa wyników na mecie
    final Map<String, int> finishRanksMap = {};
    for (final fin in simState.finishResults) {
      finishRanksMap[fin.riderId] = fin.finishRank;
    }

    for (final entry in simState.riderStates.entries) {
      final riderId = entry.key;
      final rState = entry.value;
      final rider = _allRidersMap[riderId];
      final team = _allTeamsMap[rState.teamId];

      final isPlayer = rState.teamId == simState.playerTeamId;
      final teamJerseyColor = team?.primaryJerseyColorHex ?? '#0055AA';

      // Przypisanie numeru startowego bibNumber
      final rosterIdx = team?.rosterRiderIds.indexOf(riderId) ?? 0;
      final teamIdx = _allTeamsMap.keys.toList().indexOf(rState.teamId);
      final bibNumber = (teamIdx >= 0 ? (teamIdx + 1) * 10 : 10) + (rosterIdx >= 0 ? rosterIdx + 1 : 1);

      // Profil wysokościowy i nachylenie dla obecnego kilometrażu
      final elevationData = _calculateElevationAndGradient(stage, rState.distanceCoveredMeters);

      // W' Balance i Glikogen
      final wPrime = simState.wPrimeStates[riderId];
      final nutrition = simState.nutritionStates[riderId];
      final weightKg = (rider?.physiology.weightKg ?? 70.0).clamp(50.0, 95.0);

      // Pozycja w siatce aerodynamicznej
      final gridPos = gridPositionsMap[riderId];
      final grpType = groupTypeMap[riderId] ?? GroupType.peloton;

      final isPulling = gridPos?.isPulling ?? (rState.activeTacticalOrder == TacticalOrder.pullGroup);
      final draftingSavings = gridPos?.draftingSavingsPercent ?? (rState.groupIndex > 0 ? 30.0 : 0.0);
      final isDrafting = draftingSavings > 5.0 && !isPulling;

      // Koordynaty boczne szosy (-1.0 do 1.0 -> -3.5m do +3.5m)
      final lateralOffsetMeters = gridPos?.lateralOffsetMeters ?? (rState.lateralPositionRoad * 3.5);

      // Sprawdzenie czy kolarz ma aktywny defekt
      final activeDefect = _defectAlerts.firstWhere(
        (a) => a.victimRiderId == riderId && !a.isResolved,
        orElse: () => const RaceDefectAlert(
          id: '',
          victimRiderId: '',
          victimRiderName: '',
          teamId: '',
          teamName: '',
          isPlayerTeam: false,
          incidentType: IncidentType.punctureFlatTire,
          timeLostSeconds: 0,
          timestampSeconds: 0,
          kilometerMark: 0,
          isResolved: true,
          description: '',
        ),
      );
      final hasActiveDefect = activeDefect.id.isNotEmpty && !activeDefect.isResolved;

      final snapshot = RiderPositionSnapshot(
        riderId: riderId,
        riderName: rider?.fullName ?? 'Kolarz #$bibNumber',
        bibNumber: bibNumber,
        teamId: rState.teamId,
        teamName: team?.name ?? 'Team',
        teamJerseyHexColor: teamJerseyColor,
        isPlayerRider: isPlayer,
        distanceCoveredMeters: rState.distanceCoveredMeters,
        kilometerMark: rState.distanceCoveredKm,
        elevationMeters: elevationData.elevationMeters,
        currentGradientPercent: elevationData.gradientPercent,
        currentSegmentIndex: elevationData.segmentIndex,
        speedMs: rState.currentSpeedMs,
        speedKmh: rState.currentSpeedKmh,
        powerWatts: rState.currentWatts,
        wattsPerKg: rState.currentWatts / weightKg,
        cadenceRpm: rState.currentCadenceRpm,
        heartRateBpm: rState.currentHeartRate,
        wPrimePercentage: wPrime?.wPrimePercentage ?? 100.0,
        wPrimeJoules: wPrime?.currentWPrimeJoules ?? 20000.0,
        glycogenPercentage: nutrition != null
            ? ((nutrition.currentGlycogenGrams / math.max(1.0, nutrition.maxGlycogenGrams)) * 100.0).clamp(0.0, 100.0)
            : 100.0,
        glycogenGrams: nutrition?.currentGlycogenGrams ?? 500.0,
        hydrationPercent: nutrition?.hydrationPercent ?? 100.0,
        bidonsLeft: rState.bidonsLeft,
        gelsLeft: rState.gelsLeft,
        activeTacticalOrder: rState.activeTacticalOrder,
        groupIndex: rState.groupIndex,
        groupType: grpType,
        timeGapToLeaderSeconds: rState.timeGapToLeaderSeconds,
        lateralPositionRoad: rState.lateralPositionRoad,
        lateralOffsetRoadMeters: lateralOffsetMeters,
        isDrafting: isDrafting,
        draftingSavingsPercent: draftingSavings,
        isPulling: isPulling,
        hasDefect: hasActiveDefect,
        defectType: hasActiveDefect ? activeDefect.incidentType : null,
        isCrashed: hasActiveDefect && (activeDefect.incidentType == IncidentType.soloCrash || activeDefect.incidentType == IncidentType.pelotonPileup),
        isDnf: false,
        finishRank: finishRanksMap[riderId],
      );

      results.add(snapshot);
    }

    // Sortowanie kolarzy wg pokonanego dystansu malejąco (lider wyścigu na początku)
    results.sort((a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters));
    return results;
  }

  ({double elevationMeters, double gradientPercent, int segmentIndex}) _calculateElevationAndGradient(
    RaceStage stage,
    double distanceMeters,
  ) {
    if (stage.segments.isEmpty) {
      return (elevationMeters: 50.0, gradientPercent: 0.0, segmentIndex: 0);
    }

    final double kmMark = distanceMeters / 1000.0;

    for (int i = 0; i < stage.segments.length; i++) {
      final seg = stage.segments[i];
      if (kmMark >= seg.startKm && kmMark <= seg.endKm) {
        final segLengthKm = math.max(0.01, seg.lengthKm);
        final progress = ((kmMark - seg.startKm) / segLengthKm).clamp(0.0, 1.0);
        final elev = seg.startElevationM + progress * (seg.endElevationM - seg.startElevationM);
        return (
          elevationMeters: elev,
          gradientPercent: seg.gradientPercent,
          segmentIndex: i,
        );
      }
    }

    final last = stage.segments.last;
    return (
      elevationMeters: last.endElevationM,
      gradientPercent: last.gradientPercent,
      segmentIndex: stage.segments.length - 1,
    );
  }

  /// Kończy etap i wylicza oficjalne wyniki UCI
  void _concludeStage() {
    if (_loop == null) return;
    final simState = _loop!.state;

    final summaryReport = StageResultsCalculator.calculateOfficialStageResults(
      stage: simState.stage,
      finishResults: simState.finishResults,
      allRidersMap: _allRidersMap,
      incidents: simState.incidentHistory,
      playerTeamId: simState.playerTeamId,
    );

    state = state.copyWith(stageSummaryReport: summaryReport);
  }
}

// ==========================================
// DOSTAWCY GLOBALNI (RIVERPOD PROVIDERS)
// ==========================================

/// Główny kontroler aktywnej symulacji wyścigu
final raceSimulationNotifierProvider =
    StateNotifierProvider<RaceSimulationNotifier, ActiveRaceSimulationState>((ref) {
  return RaceSimulationNotifier();
});

/// Alias dla kompatybilności wstecznej z dotychczasowym raceSimulationProvider
final raceSimulationProvider = raceSimulationNotifierProvider;

/// Strumień pozycji kolarzy (3D i 2D) emitowany co sekundę
final riderPositionStreamProvider =
    StreamProvider<List<RiderPositionSnapshot>>((ref) {
  final notifier = ref.watch(raceSimulationNotifierProvider.notifier);
  return notifier.positionStream;
});

/// Pozycje kolarzy z drużyny gracza
final playerRiderPositionsProvider =
    Provider<List<RiderPositionSnapshot>>((ref) {
  return ref.watch(raceSimulationNotifierProvider).playerRidersPositions;
});

/// Aktywne nierozwiązane alerty o defektach na trasie
final activeDefectsProvider = Provider<List<RaceDefectAlert>>((ref) {
  return ref.watch(raceSimulationNotifierProvider).unresolvedDefects;
});

/// Aktywne powiadomienie o kluczowym momencie
final activeKeyMomentProvider = Provider<KeyMomentTrigger?>((ref) {
  return ref.watch(raceSimulationNotifierProvider).activeKeyMoment;
});

