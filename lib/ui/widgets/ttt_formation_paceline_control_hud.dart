import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/peloton/team_time_trial_rider_drop_strategy.dart';

/// Typ formacji pociągu w Drużynowej Jeździe na Czas (TTT).
enum TttPacelineFormationType {
  singleFile('Pojedynczy sznur', 'SINGLE'),
  leftEchelon('Wachlarz lewy', 'ECHELON L'),
  rightEchelon('Wachlarz prawy', 'ECHELON R'),
  doublePaceline('Podwójny wachlarz', 'DOUBLE');

  final String labelPl;
  final String shortCode;

  const TttPacelineFormationType(this.labelPl, this.shortCode);

  String toJson() => name;

  static TttPacelineFormationType fromJson(String? value) {
    if (value == null) return TttPacelineFormationType.singleFile;
    return TttPacelineFormationType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TttPacelineFormationType.singleFile,
    );
  }
}

/// Preset tempa pracy pociągu TTT w % FTP.
enum TttPacelineTempoPreset {
  conservative('Oszczędnie', 92, AppColors.accentBlue),
  threshold('Próg / Równo', 104, AppColors.statusSuccess),
  allOut('Finał All-Out', 118, AppColors.crimsonAlert);

  final String labelPl;
  final int targetEffortPercent;
  final Color accentColor;

  const TttPacelineTempoPreset(
    this.labelPl,
    this.targetEffortPercent,
    this.accentColor,
  );

  String toJson() => name;

  static TttPacelineTempoPreset fromJson(String? value) {
    if (value == null) return TttPacelineTempoPreset.threshold;
    return TttPacelineTempoPreset.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TttPacelineTempoPreset.threshold,
    );
  }
}

/// Rola kolarza w aktualnej rotacji pociągu TTT.
enum TttRiderPullRole {
  pulling('Na czele', AppColors.crimsonAlert),
  drafting('Na kole', AppColors.accentBlue),
  skippingPull('Pomiń zmianę', AppColors.goldAccent),
  gapped('Luka', AppColors.amberWarning),
  dropped('Odpadł', AppColors.textSecondary);

  final String labelPl;
  final Color color;

  const TttRiderPullRole(this.labelPl, this.color);

  String toJson() => name;

  static TttRiderPullRole fromJson(String? value) {
    if (value == null) return TttRiderPullRole.drafting;
    return TttRiderPullRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TttRiderPullRole.drafting,
    );
  }
}

/// Status bezpieczeństwa 5. kolarza, na którym mierzony jest oficjalny czas drużyny.
enum TttFifthRiderStatus {
  lockedIn('W pociągu', AppColors.statusSuccess),
  stretched('Rozciągnięty', AppColors.amberWarning),
  gappedAlert('Zagrożony czas 5.!', AppColors.crimsonAlert),
  insufficientRiders('Brak 5. kolarza', AppColors.crimsonAlert);

  final String labelPl;
  final Color color;

  const TttFifthRiderStatus(this.labelPl, this.color);
}

/// Stan pojedynczego kolarza w formacji pociągu TTT.
@immutable
class TttPacelineRiderState {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final int orderInPaceline;
  final TttRiderPullRole role;
  final double currentWatts;
  final double ftpWatts;
  final double wPrimeFraction;
  final double fatigueFraction;
  final double gapToLeaderSeconds;
  final bool isGcLeader;
  final bool isTimeTrialSpecialist;
  final bool skipPullEnabled;

  const TttPacelineRiderState({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.orderInPaceline,
    required this.role,
    required this.currentWatts,
    required this.ftpWatts,
    required this.wPrimeFraction,
    this.fatigueFraction = 0.0,
    this.gapToLeaderSeconds = 0.0,
    this.isGcLeader = false,
    this.isTimeTrialSpecialist = false,
    this.skipPullEnabled = false,
  });

  double get safeWatts => _sanitizeNonNeg(currentWatts);
  double get safeFtpWatts => math.max(1.0, _sanitizeNonNeg(ftpWatts));
  double get safeWPrimeFraction => _sanitizeUnit(wPrimeFraction);
  double get safeFatigueFraction => _sanitizeUnit(fatigueFraction);
  double get safeGapToLeaderSeconds => _sanitizeNonNeg(gapToLeaderSeconds);

  int get effortPercent => ((safeWatts / safeFtpWatts) * 100.0).round().clamp(0, 250);

  bool get isActiveInPaceline => role != TttRiderPullRole.dropped;

  TttPacelineRiderState copyWith({
    String? riderId,
    String? riderName,
    int? bibNumber,
    int? orderInPaceline,
    TttRiderPullRole? role,
    double? currentWatts,
    double? ftpWatts,
    double? wPrimeFraction,
    double? fatigueFraction,
    double? gapToLeaderSeconds,
    bool? isGcLeader,
    bool? isTimeTrialSpecialist,
    bool? skipPullEnabled,
  }) {
    return TttPacelineRiderState(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      bibNumber: bibNumber ?? this.bibNumber,
      orderInPaceline: orderInPaceline ?? this.orderInPaceline,
      role: role ?? this.role,
      currentWatts: currentWatts ?? this.currentWatts,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      wPrimeFraction: wPrimeFraction ?? this.wPrimeFraction,
      fatigueFraction: fatigueFraction ?? this.fatigueFraction,
      gapToLeaderSeconds: gapToLeaderSeconds ?? this.gapToLeaderSeconds,
      isGcLeader: isGcLeader ?? this.isGcLeader,
      isTimeTrialSpecialist: isTimeTrialSpecialist ?? this.isTimeTrialSpecialist,
      skipPullEnabled: skipPullEnabled ?? this.skipPullEnabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'riderId': riderId,
        'riderName': riderName,
        'bibNumber': bibNumber,
        'orderInPaceline': orderInPaceline,
        'role': role.toJson(),
        'currentWatts': currentWatts,
        'ftpWatts': ftpWatts,
        'wPrimeFraction': wPrimeFraction,
        'fatigueFraction': fatigueFraction,
        'gapToLeaderSeconds': gapToLeaderSeconds,
        'isGcLeader': isGcLeader,
        'isTimeTrialSpecialist': isTimeTrialSpecialist,
        'skipPullEnabled': skipPullEnabled,
      };

  factory TttPacelineRiderState.fromJson(Map<String, dynamic> json) {
    return TttPacelineRiderState(
      riderId: json['riderId'] as String? ?? 'rider_unknown',
      riderName: json['riderName'] as String? ?? 'Kolarz',
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 1,
      orderInPaceline: (json['orderInPaceline'] as num?)?.toInt() ?? 1,
      role: TttRiderPullRole.fromJson(json['role'] as String?),
      currentWatts: (json['currentWatts'] as num?)?.toDouble() ?? 350.0,
      ftpWatts: (json['ftpWatts'] as num?)?.toDouble() ?? 380.0,
      wPrimeFraction: (json['wPrimeFraction'] as num?)?.toDouble() ?? 0.85,
      fatigueFraction: (json['fatigueFraction'] as num?)?.toDouble() ?? 0.2,
      gapToLeaderSeconds: (json['gapToLeaderSeconds'] as num?)?.toDouble() ?? 0.0,
      isGcLeader: json['isGcLeader'] as bool? ?? false,
      isTimeTrialSpecialist: json['isTimeTrialSpecialist'] as bool? ?? false,
      skipPullEnabled: json['skipPullEnabled'] as bool? ?? false,
    );
  }

  static double _sanitizeNonNeg(double value) {
    if (value.isNaN || value.isInfinite || value < 0.0) return 0.0;
    return value;
  }

  static double _sanitizeUnit(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return value.clamp(0.0, 1.0);
  }
}

/// Kompletna telemetria i konfiguracja panelu HUD sterowania pociągiem TTT.
@immutable
class TttFormationPacelineHudData {
  final String teamName;
  final String teamCode;
  final String stageName;
  final double stageDistanceKm;
  final double distanceRemainingKm;
  final double elapsedSeconds;
  final double splitDeltaSeconds;
  final double pacelineSpeedKmh;
  final double windSpeedKmh;
  final double crosswindAngleDeg;
  final int countingRiderRank;
  final int pullDurationSeconds;
  final double pullElapsedSeconds;
  final int targetEffortPercent;
  final TttPacelineFormationType formationType;
  final TttPacelineTempoPreset tempoPreset;
  final bool waitForFifthActive;
  final KamikazePullDropPhase kamikazePhase;
  final List<TttPacelineRiderState> riders;

  const TttFormationPacelineHudData({
    required this.teamName,
    required this.teamCode,
    required this.stageName,
    required this.stageDistanceKm,
    required this.distanceRemainingKm,
    required this.elapsedSeconds,
    required this.splitDeltaSeconds,
    required this.pacelineSpeedKmh,
    this.windSpeedKmh = 18.0,
    this.crosswindAngleDeg = 45.0,
    this.countingRiderRank = 5,
    this.pullDurationSeconds = 25,
    this.pullElapsedSeconds = 11.0,
    this.targetEffortPercent = 104,
    this.formationType = TttPacelineFormationType.leftEchelon,
    this.tempoPreset = TttPacelineTempoPreset.threshold,
    this.waitForFifthActive = false,
    this.kamikazePhase = KamikazePullDropPhase.standby,
    this.riders = const <TttPacelineRiderState>[],
  });

  double get safeStageDistanceKm => math.max(0.1, _nonNeg(stageDistanceKm));
  double get safeDistanceRemainingKm =>
      _nonNeg(distanceRemainingKm).clamp(0.0, safeStageDistanceKm);
  double get safeElapsedSeconds => _nonNeg(elapsedSeconds);
  double get safeSplitDeltaSeconds =>
      (splitDeltaSeconds.isNaN || splitDeltaSeconds.isInfinite)
          ? 0.0
          : splitDeltaSeconds;
  double get safePacelineSpeedKmh => _nonNeg(pacelineSpeedKmh);
  double get safeWindSpeedKmh => _nonNeg(windSpeedKmh);
  double get safeCrosswindAngleDeg =>
      (crosswindAngleDeg.isNaN || crosswindAngleDeg.isInfinite)
          ? 0.0
          : crosswindAngleDeg % 360.0;
  int get safeCountingRiderRank => countingRiderRank.clamp(1, 8);
  int get safePullDurationSeconds => pullDurationSeconds.clamp(10, 90);
  double get safePullElapsedSeconds =>
      _nonNeg(pullElapsedSeconds).clamp(0.0, safePullDurationSeconds.toDouble());
  int get safeTargetEffortPercent => targetEffortPercent.clamp(80, 135);

  double get pullProgressFraction =>
      (safePullElapsedSeconds / safePullDurationSeconds).clamp(0.0, 1.0);

  TttFormationPacelineHudData copyWith({
    String? teamName,
    String? teamCode,
    String? stageName,
    double? stageDistanceKm,
    double? distanceRemainingKm,
    double? elapsedSeconds,
    double? splitDeltaSeconds,
    double? pacelineSpeedKmh,
    double? windSpeedKmh,
    double? crosswindAngleDeg,
    int? countingRiderRank,
    int? pullDurationSeconds,
    double? pullElapsedSeconds,
    int? targetEffortPercent,
    TttPacelineFormationType? formationType,
    TttPacelineTempoPreset? tempoPreset,
    bool? waitForFifthActive,
    KamikazePullDropPhase? kamikazePhase,
    List<TttPacelineRiderState>? riders,
  }) {
    return TttFormationPacelineHudData(
      teamName: teamName ?? this.teamName,
      teamCode: teamCode ?? this.teamCode,
      stageName: stageName ?? this.stageName,
      stageDistanceKm: stageDistanceKm ?? this.stageDistanceKm,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      splitDeltaSeconds: splitDeltaSeconds ?? this.splitDeltaSeconds,
      pacelineSpeedKmh: pacelineSpeedKmh ?? this.pacelineSpeedKmh,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      crosswindAngleDeg: crosswindAngleDeg ?? this.crosswindAngleDeg,
      countingRiderRank: countingRiderRank ?? this.countingRiderRank,
      pullDurationSeconds: pullDurationSeconds ?? this.pullDurationSeconds,
      pullElapsedSeconds: pullElapsedSeconds ?? this.pullElapsedSeconds,
      targetEffortPercent: targetEffortPercent ?? this.targetEffortPercent,
      formationType: formationType ?? this.formationType,
      tempoPreset: tempoPreset ?? this.tempoPreset,
      waitForFifthActive: waitForFifthActive ?? this.waitForFifthActive,
      kamikazePhase: kamikazePhase ?? this.kamikazePhase,
      riders: riders ?? this.riders,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'teamName': teamName,
        'teamCode': teamCode,
        'stageName': stageName,
        'stageDistanceKm': stageDistanceKm,
        'distanceRemainingKm': distanceRemainingKm,
        'elapsedSeconds': elapsedSeconds,
        'splitDeltaSeconds': splitDeltaSeconds,
        'pacelineSpeedKmh': pacelineSpeedKmh,
        'windSpeedKmh': windSpeedKmh,
        'crosswindAngleDeg': crosswindAngleDeg,
        'countingRiderRank': countingRiderRank,
        'pullDurationSeconds': pullDurationSeconds,
        'pullElapsedSeconds': pullElapsedSeconds,
        'targetEffortPercent': targetEffortPercent,
        'formationType': formationType.toJson(),
        'tempoPreset': tempoPreset.toJson(),
        'waitForFifthActive': waitForFifthActive,
        'kamikazePhase': kamikazePhase.toJson(),
        'riders': riders.map((r) => r.toJson()).toList(),
      };

  factory TttFormationPacelineHudData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawRiders = json['riders'] as List<dynamic>? ?? const <dynamic>[];
    return TttFormationPacelineHudData(
      teamName: json['teamName'] as String? ?? 'Drużyna',
      teamCode: json['teamCode'] as String? ?? 'PPM',
      stageName: json['stageName'] as String? ?? 'Etap TTT',
      stageDistanceKm: (json['stageDistanceKm'] as num?)?.toDouble() ?? 28.0,
      distanceRemainingKm: (json['distanceRemainingKm'] as num?)?.toDouble() ?? 14.0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toDouble() ?? 0.0,
      splitDeltaSeconds: (json['splitDeltaSeconds'] as num?)?.toDouble() ?? 0.0,
      pacelineSpeedKmh: (json['pacelineSpeedKmh'] as num?)?.toDouble() ?? 52.0,
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 18.0,
      crosswindAngleDeg: (json['crosswindAngleDeg'] as num?)?.toDouble() ?? 45.0,
      countingRiderRank: (json['countingRiderRank'] as num?)?.toInt() ?? 5,
      pullDurationSeconds: (json['pullDurationSeconds'] as num?)?.toInt() ?? 25,
      pullElapsedSeconds: (json['pullElapsedSeconds'] as num?)?.toDouble() ?? 10.0,
      targetEffortPercent: (json['targetEffortPercent'] as num?)?.toInt() ?? 104,
      formationType: TttPacelineFormationType.fromJson(json['formationType'] as String?),
      tempoPreset: TttPacelineTempoPreset.fromJson(json['tempoPreset'] as String?),
      waitForFifthActive: json['waitForFifthActive'] as bool? ?? false,
      kamikazePhase: KamikazePullDropPhase.fromJson(json['kamikazePhase'] as String? ?? 'standby'),
      riders: rawRiders
          .whereType<Map<String, dynamic>>()
          .map(TttPacelineRiderState.fromJson)
          .toList(),
    );
  }

  /// Przykładowe dane telemetryczne dla podglądu i testów (7 kolarzy: 6 aktywnych, 1 odpadł).
  factory TttFormationPacelineHudData.sample() {
    return const TttFormationPacelineHudData(
      teamName: 'Velo Vistula Pro',
      teamCode: 'VVP',
      stageName: 'Etap 3 • Cholet — Cholet TTT',
      stageDistanceKm: 35.5,
      distanceRemainingKm: 11.4,
      elapsedSeconds: 1624.4,
      splitDeltaSeconds: -4.23,
      pacelineSpeedKmh: 56.8,
      windSpeedKmh: 24.0,
      crosswindAngleDeg: 52.0,
      countingRiderRank: 5,
      pullDurationSeconds: 25,
      pullElapsedSeconds: 16.5,
      targetEffortPercent: 106,
      formationType: TttPacelineFormationType.leftEchelon,
      tempoPreset: TttPacelineTempoPreset.threshold,
      waitForFifthActive: false,
      kamikazePhase: KamikazePullDropPhase.standby,
      riders: <TttPacelineRiderState>[
        TttPacelineRiderState(
          riderId: 'r1',
          riderName: 'M. Kwiatkowski',
          bibNumber: 11,
          orderInPaceline: 1,
          role: TttRiderPullRole.pulling,
          currentWatts: 465,
          ftpWatts: 415,
          wPrimeFraction: 0.72,
          fatigueFraction: 0.28,
          gapToLeaderSeconds: 0.0,
          isTimeTrialSpecialist: true,
        ),
        TttPacelineRiderState(
          riderId: 'r2',
          riderName: 'F. Maciejuk',
          bibNumber: 12,
          orderInPaceline: 2,
          role: TttRiderPullRole.drafting,
          currentWatts: 318,
          ftpWatts: 405,
          wPrimeFraction: 0.88,
          fatigueFraction: 0.22,
          gapToLeaderSeconds: 0.1,
          isTimeTrialSpecialist: true,
        ),
        TttPacelineRiderState(
          riderId: 'r3',
          riderName: 'R. Majka',
          bibNumber: 13,
          orderInPaceline: 3,
          role: TttRiderPullRole.skippingPull,
          currentWatts: 285,
          ftpWatts: 390,
          wPrimeFraction: 0.91,
          fatigueFraction: 0.19,
          gapToLeaderSeconds: 0.2,
          isGcLeader: true,
          skipPullEnabled: true,
        ),
        TttPacelineRiderState(
          riderId: 'r4',
          riderName: 'Ł. Wiśniowski',
          bibNumber: 14,
          orderInPaceline: 4,
          role: TttRiderPullRole.drafting,
          currentWatts: 325,
          ftpWatts: 395,
          wPrimeFraction: 0.79,
          fatigueFraction: 0.31,
          gapToLeaderSeconds: 0.3,
        ),
        TttPacelineRiderState(
          riderId: 'r5',
          riderName: 'K. Gradek',
          bibNumber: 15,
          orderInPaceline: 5,
          role: TttRiderPullRole.gapped,
          currentWatts: 378,
          ftpWatts: 385,
          wPrimeFraction: 0.34,
          fatigueFraction: 0.46,
          gapToLeaderSeconds: 1.9,
        ),
        TttPacelineRiderState(
          riderId: 'r6',
          riderName: 'S. Aniołkowski',
          bibNumber: 16,
          orderInPaceline: 6,
          role: TttRiderPullRole.drafting,
          currentWatts: 310,
          ftpWatts: 370,
          wPrimeFraction: 0.48,
          fatigueFraction: 0.42,
          gapToLeaderSeconds: 2.1,
        ),
        TttPacelineRiderState(
          riderId: 'r7',
          riderName: 'P. Brożyna',
          bibNumber: 17,
          orderInPaceline: 7,
          role: TttRiderPullRole.dropped,
          currentWatts: 245,
          ftpWatts: 360,
          wPrimeFraction: 0.06,
          fatigueFraction: 0.78,
          gapToLeaderSeconds: 28.5,
        ),
      ],
    );
  }

  static double _nonNeg(double value) {
    if (value.isNaN || value.isInfinite || value < 0.0) return 0.0;
    return value;
  }
}

/// Kalkulator logiki zmian, bufora bezpieczeństwa i czasu 5. kolarza w TTT.
class TttFormationPacelineCalculator {
  const TttFormationPacelineCalculator._();

  /// Zwraca posortowanych aktywnych kolarzy (bez tych, którzy odpadli).
  static List<TttPacelineRiderState> activeRiders(
    List<TttPacelineRiderState> riders,
  ) {
    final List<TttPacelineRiderState> active = riders
        .where((r) => r.isActiveInPaceline)
        .toList()
      ..sort((a, b) => a.orderInPaceline.compareTo(b.orderInPaceline));
    return active;
  }

  /// Zwraca kolarzy, którzy już odpadli z pociągu.
  static List<TttPacelineRiderState> droppedRiders(
    List<TttPacelineRiderState> riders,
  ) {
    return riders
        .where((r) => !r.isActiveInPaceline)
        .toList()
      ..sort((a, b) => a.orderInPaceline.compareTo(b.orderInPaceline));
  }

  /// Zwraca N-tego (domyślnie 5.) aktywnego kolarza, na którym mierzony jest czas drużyny.
  static TttPacelineRiderState? countingRider(TttFormationPacelineHudData data) {
    final List<TttPacelineRiderState> active = activeRiders(data.riders);
    final int rankIndex = data.safeCountingRiderRank - 1;
    if (rankIndex < 0 || rankIndex >= active.length) {
      return null;
    }
    return active[rankIndex];
  }

  /// Różnica czasowa 5. kolarza względem czoła pociągu (w sekundach).
  static double? fifthRiderGapSeconds(TttFormationPacelineHudData data) {
    final TttPacelineRiderState? fifth = countingRider(data);
    return fifth?.safeGapToLeaderSeconds;
  }

  /// Ocena statusu bezpieczeństwa 5. kolarza.
  static TttFifthRiderStatus fifthRiderStatus(TttFormationPacelineHudData data) {
    final TttPacelineRiderState? fifth = countingRider(data);
    if (fifth == null) {
      return TttFifthRiderStatus.insufficientRiders;
    }
    final double gap = fifth.safeGapToLeaderSeconds;
    if (gap >= 1.8 || fifth.role == TttRiderPullRole.gapped) {
      return TttFifthRiderStatus.gappedAlert;
    }
    if (gap >= 0.7) {
      return TttFifthRiderStatus.stretched;
    }
    return TttFifthRiderStatus.lockedIn;
  }

  /// Liczba kolarzy buforowych ponad wymagany limit (np. 6 aktywnych przy limicie 5 -> bufor +1).
  static int safetyBufferCount(TttFormationPacelineHudData data) {
    final int activeCount = activeRiders(data.riders).length;
    return math.max(0, activeCount - data.safeCountingRiderRank);
  }

  /// Czy można bezpiecznie poświęcić kolejnego kolarza bez zejścia poniżej limitu 5. kolarza.
  static bool canDropAnotherRider(TttFormationPacelineHudData data) {
    return activeRiders(data.riders).length > data.safeCountingRiderRank;
  }

  /// Kolejny kolarz wyznaczony do zmiany na czele (pomija kolarzy z `skipPullEnabled`).
  static TttPacelineRiderState? nextPullingRider(TttFormationPacelineHudData data) {
    final List<TttPacelineRiderState> active = activeRiders(data.riders);
    if (active.length <= 1) return null;
    for (int i = 1; i < active.length; i++) {
      if (!active[i].skipPullEnabled &&
          active[i].role != TttRiderPullRole.skippingPull) {
        return active[i];
      }
    }
    return active[1];
  }

  /// Przewidywany oficjalny czas drużyny (czas czoła + opóźnienie 5. kolarza).
  static double estimatedOfficialTeamTimeSeconds(
    TttFormationPacelineHudData data,
  ) {
    final double gap = fifthRiderGapSeconds(data) ?? 0.0;
    return data.safeElapsedSeconds + gap;
  }

  /// Formatuje stoper wyścigowy (`MM:SS.d` lub `H:MM:SS.d`).
  static String formatRaceClock(double totalSeconds) {
    final double safe =
        (totalSeconds.isNaN || totalSeconds.isInfinite || totalSeconds < 0.0)
            ? 0.0
            : totalSeconds;
    final int tenths = (safe * 10.0).round();
    final int totalWholeSeconds = tenths ~/ 10;
    final int remTenths = tenths % 10;
    final int hours = totalWholeSeconds ~/ 3600;
    final int minutes = (totalWholeSeconds % 3600) ~/ 60;
    final int seconds = totalWholeSeconds % 60;

    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss.$remTenths';
    }
    return '$mm:$ss.$remTenths';
  }

  /// Formatuje deltę czasową na pomiarze (`-4.23 s`, `+1.85 s`, `0.00 s`).
  static String formatGapDelta(double deltaSeconds) {
    final double safe =
        (deltaSeconds.isNaN || deltaSeconds.isInfinite) ? 0.0 : deltaSeconds;
    if (safe.abs() < 0.005) {
      return '0.00 s';
    }
    final String sign = safe < 0 ? '-' : '+';
    return '$sign${safe.abs().toStringAsFixed(2)} s';
  }
}

/// Główny panel HUD sterowania zmianami, formacją wachlarza i czasem 5. kolarza w TTT.
class TttFormationPacelineControlHud extends StatefulWidget {
  final TttFormationPacelineHudData data;
  final bool enabled;
  final bool initiallyExpanded;
  final ValueChanged<TttPacelineFormationType>? onFormationChanged;
  final ValueChanged<TttPacelineTempoPreset>? onTempoPresetChanged;
  final ValueChanged<int>? onPullDurationChanged;
  final ValueChanged<int>? onTargetEffortChanged;
  final VoidCallback? onForceRotationNow;
  final ValueChanged<bool>? onToggleWaitForFifth;
  final ValueChanged<String>? onToggleRiderSkipPull;
  final ValueChanged<String>? onSendRiderToFront;
  final ValueChanged<String>? onDropRider;
  final VoidCallback? onTriggerKamikazePull;

  const TttFormationPacelineControlHud({
    super.key,
    required this.data,
    this.enabled = true,
    this.initiallyExpanded = true,
    this.onFormationChanged,
    this.onTempoPresetChanged,
    this.onPullDurationChanged,
    this.onTargetEffortChanged,
    this.onForceRotationNow,
    this.onToggleWaitForFifth,
    this.onToggleRiderSkipPull,
    this.onSendRiderToFront,
    this.onDropRider,
    this.onTriggerKamikazePull,
  });

  @override
  State<TttFormationPacelineControlHud> createState() =>
      _TttFormationPacelineControlHudState();
}

class _TttFormationPacelineControlHudState
    extends State<TttFormationPacelineControlHud> {
  late bool _expanded;
  String? _selectedRiderId;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    final List<TttPacelineRiderState> active =
        TttFormationPacelineCalculator.activeRiders(widget.data.riders);
    if (active.isNotEmpty) {
      _selectedRiderId = active.first.riderId;
    }
  }

  @override
  void didUpdateWidget(covariant TttFormationPacelineControlHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<TttPacelineRiderState> active =
        TttFormationPacelineCalculator.activeRiders(widget.data.riders);
    if (active.isEmpty) {
      _selectedRiderId = null;
    } else if (_selectedRiderId == null ||
        !widget.data.riders.any((r) => r.riderId == _selectedRiderId)) {
      _selectedRiderId = active.first.riderId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TttFifthRiderStatus fifthStatus =
        TttFormationPacelineCalculator.fifthRiderStatus(widget.data);
    final Color borderHighlight = fifthStatus == TttFifthRiderStatus.gappedAlert ||
            fifthStatus == TttFifthRiderStatus.insufficientRiders
        ? AppColors.crimsonAlert.withValues(alpha: 0.75)
        : fifthStatus == TttFifthRiderStatus.stretched
            ? AppColors.amberWarning.withValues(alpha: 0.65)
            : AppColors.cardBorder;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderHighlight, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final bool isCompact = width < 520;
          final bool isDesktop = width >= 980;

          return Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(context, isCompact: isCompact, fifthStatus: fifthStatus),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 240),
                  sizeCurve: Curves.easeOutCubic,
                  crossFadeState: _expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: 12),
                      _buildFifthRiderBanner(context, isCompact: isCompact, fifthStatus: fifthStatus),
                      const SizedBox(height: 12),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              flex: 6,
                              child: _buildFormationAndRidersSection(isCompact: false),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 5,
                              child: _buildControlsSection(isCompact: false),
                            ),
                          ],
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _buildFormationAndRidersSection(isCompact: isCompact),
                            const SizedBox(height: 12),
                            _buildControlsSection(isCompact: isCompact),
                          ],
                        ),
                    ],
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required bool isCompact,
    required TttFifthRiderStatus fifthStatus,
  }) {
    final double officialTime =
        TttFormationPacelineCalculator.estimatedOfficialTeamTimeSeconds(widget.data);
    final double delta = widget.data.safeSplitDeltaSeconds;
    final Color deltaColor = delta < -0.005
        ? AppColors.statusSuccess
        : delta > 0.005
            ? AppColors.crimsonAlert
            : AppColors.textSecondary;

    final Widget titleGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.7),
            ),
          ),
          child: const Text(
            'TTT HUD',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'STEROWANIE POCIĄGIEM I CZASEM ${widget.data.safeCountingRiderRank}. KOLARZA',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${widget.data.teamName} (${widget.data.teamCode}) • ${widget.data.stageName}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget telemetryStrip = Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _TelemetryChip(
          label: 'CZAS ${widget.data.safeCountingRiderRank}.',
          value: TttFormationPacelineCalculator.formatRaceClock(officialTime),
          valueColor: AppColors.goldAccent,
        ),
        _TelemetryChip(
          label: 'DELTA',
          value: TttFormationPacelineCalculator.formatGapDelta(delta),
          valueColor: deltaColor,
        ),
        _TelemetryChip(
          label: 'PRĘDKOŚĆ',
          value: '${widget.data.safePacelineSpeedKmh.toStringAsFixed(1)} km/h',
          valueColor: AppColors.cyanAccent,
        ),
        _HudIconToggleButton(
          icon: _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          tooltip: _expanded ? 'Zwiń panel TTT' : 'Rozwiń panel TTT',
          enabled: true,
          onPressed: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: titleGroup),
              _HudIconToggleButton(
                icon: _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                tooltip: _expanded ? 'Zwiń panel TTT' : 'Rozwiń panel TTT',
                enabled: true,
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _TelemetryChip(
                label: 'CZAS ${widget.data.safeCountingRiderRank}.',
                value: TttFormationPacelineCalculator.formatRaceClock(officialTime),
                valueColor: AppColors.goldAccent,
              ),
              _TelemetryChip(
                label: 'DELTA',
                value: TttFormationPacelineCalculator.formatGapDelta(delta),
                valueColor: deltaColor,
              ),
              _TelemetryChip(
                label: 'META',
                value: '${widget.data.safeDistanceRemainingKm.toStringAsFixed(1)} km',
                valueColor: AppColors.textPrimary,
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(child: titleGroup),
        const SizedBox(width: 12),
        telemetryStrip,
      ],
    );
  }

  Widget _buildFifthRiderBanner(
    BuildContext context, {
    required bool isCompact,
    required TttFifthRiderStatus fifthStatus,
  }) {
    final TttPacelineRiderState? fifth =
        TttFormationPacelineCalculator.countingRider(widget.data);
    final int activeCount =
        TttFormationPacelineCalculator.activeRiders(widget.data.riders).length;
    final int buffer = TttFormationPacelineCalculator.safetyBufferCount(widget.data);
    final double? gap = TttFormationPacelineCalculator.fifthRiderGapSeconds(widget.data);

    final String statusHeadline = fifth == null
        ? 'Krytyczny brak ${widget.data.safeCountingRiderRank}. kolarza w pociągu ($activeCount aktywnych)!'
        : '${widget.data.safeCountingRiderRank}. kolarz (czas drużyny): #${fifth.bibNumber} ${fifth.riderName} • Luka: +${(gap ?? 0.0).toStringAsFixed(1)} s';

    final String bufferText =
        'Aktywnych: $activeCount • Bufor bezpieczeństwa: ${buffer > 0 ? '+$buffer' : 'BRAK'}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: fifthStatus.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fifthStatus.color.withValues(alpha: 0.55)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                fifthStatus == TttFifthRiderStatus.lockedIn
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
                size: 18,
                color: fifthStatus.color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      statusHeadline,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bufferText,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _HudActionButton(
            label: widget.data.waitForFifthActive
                ? 'Czekam na ${widget.data.safeCountingRiderRank}. (AKTYWNE)'
                : 'Czekaj na ${widget.data.safeCountingRiderRank}. kolarza',
            icon: Icons.hourglass_bottom_rounded,
            accentColor: AppColors.goldAccent,
            isActive: widget.data.waitForFifthActive,
            enabled: widget.enabled && fifth != null,
            onPressed: () {
              widget.onToggleWaitForFifth?.call(!widget.data.waitForFifthActive);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormationAndRidersSection({required bool isCompact}) {
    final List<TttPacelineRiderState> active =
        TttFormationPacelineCalculator.activeRiders(widget.data.riders);
    final List<TttPacelineRiderState> dropped =
        TttFormationPacelineCalculator.droppedRiders(widget.data.riders);

    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.air_rounded, size: 15, color: AppColors.cyanAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SZYK POCIĄGU (${widget.data.formationType.labelPl.toUpperCase()})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                'Wiatr ${widget.data.safeWindSpeedKmh.toStringAsFixed(0)} km/h',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyanAccent,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: isCompact ? 96 : 112,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                painter: TttPacelineFormationPainter(
                  data: widget.data,
                  selectedRiderId: _selectedRiderId,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (active.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak aktywnych kolarzy w pociągu TTT.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < active.length; i++) ...<Widget>[
                  _RiderPacelineRow(
                    rider: active[i],
                    positionIndex: i + 1,
                    isCountingRank: i + 1 == widget.data.safeCountingRiderRank,
                    isSelected: active[i].riderId == _selectedRiderId,
                    enabled: widget.enabled,
                    canDrop: TttFormationPacelineCalculator.canDropAnotherRider(
                      widget.data,
                    ),
                    onSelect: () {
                      setState(() {
                        _selectedRiderId = active[i].riderId;
                      });
                    },
                    onToggleSkipPull: () {
                      widget.onToggleRiderSkipPull?.call(active[i].riderId);
                    },
                    onSendToFront: () {
                      widget.onSendRiderToFront?.call(active[i].riderId);
                    },
                    onDropRider: () {
                      widget.onDropRider?.call(active[i].riderId);
                    },
                  ),
                  if (i < active.length - 1) const SizedBox(height: 6),
                ],
              ],
            ),
          if (dropped.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: dropped
                  .map(
                    (r) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        'Odpadł: #${r.bibNumber} ${r.riderName} (+${r.safeGapToLeaderSeconds.toStringAsFixed(1)}s)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlsSection({required bool isCompact}) {
    final TttPacelineRiderState? nextPuller =
        TttFormationPacelineCalculator.nextPullingRider(widget.data);
    final bool canDrop =
        TttFormationPacelineCalculator.canDropAnotherRider(widget.data);
    final int remainingSec = math.max(
      0,
      (widget.data.safePullDurationSeconds - widget.data.safePullElapsedSeconds)
          .round(),
    );

    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Zegar bieżącej zmiany + przycisk natychmiastowej rotacji
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'ROTACJA ZMIAN (${widget.data.safePullDurationSeconds}s)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nextPuller != null
                          ? 'Następny na czele: #${nextPuller.bibNumber} ${nextPuller.riderName} (za ${remainingSec}s)'
                          : 'Brak zmiennika w pociągu',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _HudActionButton(
                label: 'Zmiana Teraz',
                icon: Icons.swap_horiz_rounded,
                accentColor: AppColors.primaryAccent,
                isActive: false,
                enabled: widget.enabled && nextPuller != null,
                onPressed: widget.onForceRotationNow,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: widget.data.pullProgressFraction,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.data.pullProgressFraction > 0.8
                    ? AppColors.amberWarning
                    : AppColors.accentBlue,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Wybór długości zmiany (15s / 20s / 30s / 45s / 60s)
          const Text(
            'CZAS ZMIANY NA CZELE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const <int>[15, 20, 30, 45, 60].map((int sec) {
              return sec;
            }).map((int sec) {
              final bool selected = widget.data.safePullDurationSeconds == sec;
              return _HudSelectablePill(
                label: '${sec}s',
                selected: selected,
                enabled: widget.enabled,
                accentColor: AppColors.accentBlue,
                onTap: () => widget.onPullDurationChanged?.call(sec),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Wybór formacji / wachlarza
          const Text(
            'USTAWIENIE WACHLARZA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TttPacelineFormationType.values.map((type) {
              return _HudSelectablePill(
                label: type.labelPl,
                selected: widget.data.formationType == type,
                enabled: widget.enabled,
                accentColor: AppColors.cyanAccent,
                onTap: () => widget.onFormationChanged?.call(type),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Docelowa moc zmiany (% FTP) + presety tempa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'TEMPO ZMIANY (% FTP)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${widget.data.safeTargetEffortPercent}% FTP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.data.safeTargetEffortPercent >= 115
                      ? AppColors.crimsonAlert
                      : AppColors.goldAccent,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryAccent,
              inactiveTrackColor: AppColors.background,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: widget.data.safeTargetEffortPercent.toDouble(),
              min: 80,
              max: 135,
              divisions: 55,
              onChanged: widget.enabled
                  ? (double val) =>
                      widget.onTargetEffortChanged?.call(val.round())
                  : null,
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TttPacelineTempoPreset.values.map((preset) {
              return _HudSelectablePill(
                label: '${preset.labelPl} (${preset.targetEffortPercent}%)',
                selected: widget.data.tempoPreset == preset,
                enabled: widget.enabled,
                accentColor: preset.accentColor,
                onTap: () => widget.onTempoPresetChanged?.call(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Integracja z Kamikaze Pull & Drop (#392) z ochroną 5. kolarza
          _HudActionButton(
            label: canDrop
                ? 'Kamikaze Pull & Drop (${widget.data.kamikazePhase.labelPl})'
                : 'Kamikaze zablokowane (limit ${widget.data.safeCountingRiderRank} kolarzy)',
            icon: Icons.bolt_rounded,
            accentColor: AppColors.crimsonAlert,
            isActive: widget.data.kamikazePhase ==
                KamikazePullDropPhase.kamikazePullActive,
            enabled: widget.enabled && canDrop,
            onPressed: widget.onTriggerKamikazePull,
          ),
        ],
      ),
    );
  }
}

/// Wektorowy wizualizator szyku pociągu TTT (sznur / wachlarz / podwójny wachlarz + linia 5. kolarza).
class TttPacelineFormationPainter extends CustomPainter {
  final TttFormationPacelineHudData data;
  final String? selectedRiderId;

  TttPacelineFormationPainter({
    required this.data,
    this.selectedRiderId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tło asfaltu
    final Paint bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Pasy drogi
    final Paint lanePaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.16),
      Offset(size.width, size.height * 0.16),
      lanePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.84),
      Offset(size.width, size.height * 0.84),
      lanePaint,
    );

    // Wektor wiatru w lewym górnym rogu
    _drawWindIndicator(canvas, size);

    final List<TttPacelineRiderState> active =
        TttFormationPacelineCalculator.activeRiders(data.riders);
    if (active.isEmpty) return;

    final int count = active.length;
    final double rightLeadX = size.width * 0.88;
    final double leftTailX = size.width * 0.14;
    final double spanX = math.max(40.0, rightLeadX - leftTailX);
    final double stepX = count > 1 ? spanX / (count - 1) : 0.0;

    final List<Offset> positions = <Offset>[];
    for (int i = 0; i < count; i++) {
      final TttPacelineRiderState rider = active[i];
      final double extraGapOffset =
          math.min(28.0, rider.safeGapToLeaderSeconds * 7.5);
      final double x =
          (rightLeadX - (i * stepX) - extraGapOffset).clamp(18.0, size.width - 18.0);

      double y;
      switch (data.formationType) {
        case TttPacelineFormationType.singleFile:
          y = size.height * 0.50;
          break;
        case TttPacelineFormationType.leftEchelon:
          final double t = count > 1 ? i / (count - 1) : 0.0;
          y = size.height * (0.28 + t * 0.44);
          break;
        case TttPacelineFormationType.rightEchelon:
          final double t = count > 1 ? i / (count - 1) : 0.0;
          y = size.height * (0.72 - t * 0.44);
          break;
        case TttPacelineFormationType.doublePaceline:
          y = i.isEven ? size.height * 0.36 : size.height * 0.64;
          break;
      }
      positions.add(Offset(x, y));
    }

    // Linia łącząca pociąg (struga aero)
    final Paint wakePaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < positions.length - 1; i++) {
      canvas.drawLine(positions[i], positions[i + 1], wakePaint);
    }

    // Pionowa złota linia graniczna na 5. kolarzu (czas drużyny)
    final int countingIdx = data.safeCountingRiderRank - 1;
    if (countingIdx >= 0 && countingIdx < positions.length) {
      final Offset fifthPos = positions[countingIdx];
      final Paint fifthLinePaint = Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.75)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(fifthPos.dx, 8),
        Offset(fifthPos.dx, size.height - 8),
        fifthLinePaint,
      );
    }

    // Rysowanie kolarzy
    for (int i = 0; i < positions.length; i++) {
      final TttPacelineRiderState rider = active[i];
      final Offset pos = positions[i];
      final bool isCounting = i == countingIdx;
      final bool isSelected = rider.riderId == selectedRiderId;

      final Color dotColor = i == 0
          ? AppColors.crimsonAlert
          : isCounting
              ? AppColors.goldAccent
              : rider.skipPullEnabled
                  ? AppColors.amberWarning
                  : AppColors.accentBlue;

      if (isSelected) {
        canvas.drawCircle(
          pos,
          12.0,
          Paint()..color = dotColor.withValues(alpha: 0.25),
        );
      }

      canvas.drawCircle(pos, isCounting ? 7.5 : 6.0, Paint()..color = dotColor);
      canvas.drawCircle(
        pos,
        isCounting ? 7.5 : 6.0,
        Paint()
          ..color = AppColors.textPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCounting ? 1.8 : 1.0,
      );

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: AppColors.background,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  void _drawWindIndicator(Canvas canvas, Size size) {
    const Offset center = Offset(22, 20);
    final double rad = (data.safeCrosswindAngleDeg * math.pi) / 180.0;
    final Offset tip = center + Offset(math.cos(rad) * 10, math.sin(rad) * 10);
    final Paint windPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center - (tip - center) * 0.5, tip, windPaint);
    canvas.drawCircle(tip, 2.2, Paint()..color = AppColors.cyanAccent);
  }

  @override
  bool shouldRepaint(covariant TttPacelineFormationPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedRiderId != selectedRiderId;
  }
}

class _RiderPacelineRow extends StatefulWidget {
  final TttPacelineRiderState rider;
  final int positionIndex;
  final bool isCountingRank;
  final bool isSelected;
  final bool enabled;
  final bool canDrop;
  final VoidCallback onSelect;
  final VoidCallback onToggleSkipPull;
  final VoidCallback onSendToFront;
  final VoidCallback onDropRider;

  const _RiderPacelineRow({
    required this.rider,
    required this.positionIndex,
    required this.isCountingRank,
    required this.isSelected,
    required this.enabled,
    required this.canDrop,
    required this.onSelect,
    required this.onToggleSkipPull,
    required this.onSendToFront,
    required this.onDropRider,
  });

  @override
  State<_RiderPacelineRow> createState() => _RiderPacelineRowState();
}

class _RiderPacelineRowState extends State<_RiderPacelineRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool isPulling = widget.positionIndex == 1;
    final Color accent = widget.isCountingRank
        ? AppColors.goldAccent
        : isPulling
            ? AppColors.crimsonAlert
            : AppColors.accentBlue;

    final Color bgColor = widget.isSelected
        ? accent.withValues(alpha: 0.14)
        : _hovered
            ? AppColors.surface.withValues(alpha: 0.95)
            : AppColors.background.withValues(alpha: 0.65);

    final Color borderColor = _focused
        ? AppColors.cyanAccent
        : widget.isCountingRank
            ? AppColors.goldAccent.withValues(alpha: 0.85)
            : widget.isSelected
                ? accent.withValues(alpha: 0.7)
                : _hovered
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
      onShowFocusHighlight: (bool value) => setState(() => _focused = value),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onSelect : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: widget.isCountingRank ? 1.3 : 1.0),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '${widget.positionIndex}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            '#${widget.rider.bibNumber} ${widget.rider.riderName}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (widget.isCountingRank) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CZAS #5',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.goldAccent,
                              ),
                            ),
                          ),
                        ],
                        if (widget.rider.isGcLeader) ...<Widget>[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: AppColors.goldAccent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          '${widget.rider.safeWatts.round()} W (${widget.rider.effortPercent}%)',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: widget.rider.safeWPrimeFraction,
                              minHeight: 4,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.rider.safeWPrimeFraction < 0.25
                                    ? AppColors.crimsonAlert
                                    : widget.rider.safeWPrimeFraction < 0.5
                                        ? AppColors.amberWarning
                                        : AppColors.statusSuccess,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          "W' ${(widget.rider.safeWPrimeFraction * 100).round()}%",
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Akcje dla kolarza: Pomiń zmianę / Na czoło / Odpuść
              _MiniRiderActionButton(
                icon: widget.rider.skipPullEnabled
                    ? Icons.shield_rounded
                    : Icons.shield_outlined,
                tooltip: widget.rider.skipPullEnabled
                    ? 'Oszczędzany (omija zmiany)'
                    : 'Pomiń zmianę kolarza',
                active: widget.rider.skipPullEnabled,
                activeColor: AppColors.goldAccent,
                enabled: widget.enabled && !isPulling,
                onPressed: widget.onToggleSkipPull,
              ),
              const SizedBox(width: 4),
              _MiniRiderActionButton(
                icon: Icons.north_rounded,
                tooltip: 'Wyślij na czoło',
                active: isPulling,
                activeColor: AppColors.accentBlue,
                enabled: widget.enabled && !isPulling,
                onPressed: widget.onSendToFront,
              ),
              const SizedBox(width: 4),
              _MiniRiderActionButton(
                icon: Icons.person_remove_outlined,
                tooltip: widget.canDrop
                    ? 'Odpuść koło (poświęć)'
                    : 'Zablokowane przez limit 5. kolarza',
                active: false,
                activeColor: AppColors.crimsonAlert,
                enabled: widget.enabled && widget.canDrop && !isPulling,
                onPressed: widget.onDropRider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TelemetryChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$label ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HudActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isActive;
  final bool enabled;
  final VoidCallback? onPressed;

  const _HudActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isActive,
    required this.enabled,
    this.onPressed,
  });

  @override
  State<_HudActionButton> createState() => _HudActionButtonState();
}

class _HudActionButtonState extends State<_HudActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool canInteract = widget.enabled && widget.onPressed != null;
    final Color bg = !canInteract
        ? AppColors.background.withValues(alpha: 0.45)
        : widget.isActive
            ? widget.accentColor.withValues(alpha: 0.28)
            : _pressed
                ? widget.accentColor.withValues(alpha: 0.32)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.2)
                    : AppColors.background.withValues(alpha: 0.85);

    final Color border = !canInteract
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.cyanAccent
            : widget.isActive || _hovered
                ? widget.accentColor
                : widget.accentColor.withValues(alpha: 0.6);

    final Color fg = canInteract ? AppColors.textPrimary : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: canInteract,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: canInteract ? (_) => setState(() => _pressed = true) : null,
        onTapUp: canInteract ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: canInteract ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 15,
                color: canInteract ? widget.accentColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudSelectablePill extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _HudSelectablePill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_HudSelectablePill> createState() => _HudSelectablePillState();
}

class _HudSelectablePillState extends State<_HudSelectablePill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.background.withValues(alpha: 0.4)
        : widget.selected
            ? widget.accentColor.withValues(alpha: 0.24)
            : _hovered
                ? AppColors.surface
                : AppColors.background.withValues(alpha: 0.75);

    final Color border = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused
            ? AppColors.cyanAccent
            : widget.selected
                ? widget.accentColor
                : _hovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.enabled
                  ? (widget.selected ? AppColors.textPrimary : AppColors.textSecondary)
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniRiderActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final Color activeColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _MiniRiderActionButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.activeColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_MiniRiderActionButton> createState() => _MiniRiderActionButtonState();
}

class _MiniRiderActionButtonState extends State<_MiniRiderActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? Colors.transparent
        : widget.active
            ? widget.activeColor.withValues(alpha: 0.24)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.surface.withValues(alpha: 0.7);

    final Color iconColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : widget.active
            ? widget.activeColor
            : AppColors.textPrimary;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.active && widget.enabled
                    ? widget.activeColor.withValues(alpha: 0.7)
                    : AppColors.cardBorder,
              ),
            ),
            child: Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _HudIconToggleButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _HudIconToggleButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_HudIconToggleButton> createState() => _HudIconToggleButtonState();
}

class _HudIconToggleButtonState extends State<_HudIconToggleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(widget.icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
