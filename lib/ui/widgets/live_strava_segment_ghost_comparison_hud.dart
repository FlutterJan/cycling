import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Stan porównania na żywo względem historycznego Rekordu Trasy (KOM Ghost).
enum KomGhostComparisonStatus {
  /// Kolarz zbliża się do bramy startowej pomiaru KOM.
  approachingGate('DOJAZD DO BRAMY KOM', AppColors.accentBlue),

  /// Kolarz ma przewagę czasową nad duchem Rekordu Trasy (`delta < -0.5 s`).
  aheadOfKom('PRZEWAGA NAD KOM', AppColors.statusSuccess),

  /// Kolarz jedzie w niemal identycznym tempie jak Rekord Trasy (`|delta| <= 0.5 s`).
  onPace('TEMPO REKORDU', AppColors.goldAccent),

  /// Kolarz traci sekundy do ducha Rekordu Trasy (`delta > 0.5 s`).
  behindKom('STRATA DO KOM', AppColors.crimsonAlert),

  /// Kolarz minął bramę szczytu z nowym Rekordem Trasy KOM.
  summitCrossedNewKom('NOWY REKORD KOM!', AppColors.goldAccent),

  /// Kolarz minął bramę szczytu ze stratą do historycznego rekordu.
  summitCrossedBehind('UKOŃCZONO SEGMENT', AppColors.textSecondary);

  final String labelPl;
  final Color accentColor;

  const KomGhostComparisonStatus(this.labelPl, this.accentColor);
}

/// Wskazówka taktyczna dotycząca tempa na podjeździe KOM.
enum KomGhostPacingAdvice {
  pushForKom('ATAKUJ KOM', AppColors.goldAccent, Icons.bolt_rounded),
  holdSteady('UTRZYMAJ TEMPO', AppColors.statusSuccess, Icons.speed_rounded),
  redZoneWarning(
    'STREFA CZERWONA',
    AppColors.crimsonAlert,
    Icons.warning_amber_rounded,
  ),
  recoverAndPace(
    'OSZCZĘDZAJ SIŁY',
    AppColors.accentBlue,
    Icons.battery_charging_full_rounded,
  );

  final String labelPl;
  final Color color;
  final IconData icon;

  const KomGhostPacingAdvice(this.labelPl, this.color, this.icon);
}

/// Kompletny zestaw danych telemetrycznych dla widżetu [LiveStravaSegmentGhostComparisonHud].
@immutable
class LiveStravaSegmentGhostData {
  final String segmentId;
  final String segmentName;
  final String classificationLabel;
  final String riderName;
  final String riderTeamCode;
  final String komHolderName;
  final String komHolderTeamCode;
  final int komRecordYear;

  /// Historyczny Rekord Trasy (KOM) w sekundach.
  final double komRecordSeconds;
  final double komRecordWattsPerKg;
  final double komRecordVamMetersPerHour;

  /// Parametry geometryczne segmentu KOM.
  final double segmentLengthKm;
  final double elevationGainM;
  final double averageGradientPercent;
  final double currentGradientPercent;

  /// Czy kolarz wjechał już pod bramę startową pomiaru KOM.
  final bool hasCrossedStartGate;

  /// Czy kolarz minął już bramę szczytową segmentu KOM.
  final bool hasCrossedSummitGate;

  /// Dystans do bramy startowej (m) przed rozpoczęciem pomiaru.
  final double distanceToStartGateMeters;

  /// Dystans pokonany od bramy startowej segmentu (km).
  final double distanceCoveredKm;

  /// Czas gracza od przekroczenia bramy startowej (s).
  final double riderElapsedSeconds;

  /// Czas ducha Rekordu Trasy na dokładnie tym samym dystansie (s).
  /// Gdy `null`, wyliczany liniowo z [komRecordSeconds] i postępu trasy.
  final double? ghostElapsedAtSameDistanceSeconds;

  /// Bieżąca telemetria kolarza.
  final double currentSpeedKmh;
  final double currentPowerWatts;
  final double currentWattsPerKg;
  final double currentVamMetersPerHour;
  final double wPrimeRemainingPercent;

  /// Historia ostatnich różnic czasowych (w sekundach) do wykresu trendu.
  final List<double> deltaHistorySeconds;

  const LiveStravaSegmentGhostData({
    required this.segmentId,
    required this.segmentName,
    required this.classificationLabel,
    required this.riderName,
    required this.riderTeamCode,
    required this.komHolderName,
    required this.komHolderTeamCode,
    required this.komRecordYear,
    required this.komRecordSeconds,
    required this.komRecordWattsPerKg,
    required this.komRecordVamMetersPerHour,
    required this.segmentLengthKm,
    required this.elevationGainM,
    required this.averageGradientPercent,
    required this.currentGradientPercent,
    required this.hasCrossedStartGate,
    this.hasCrossedSummitGate = false,
    this.distanceToStartGateMeters = 0.0,
    required this.distanceCoveredKm,
    required this.riderElapsedSeconds,
    this.ghostElapsedAtSameDistanceSeconds,
    required this.currentSpeedKmh,
    required this.currentPowerWatts,
    required this.currentWattsPerKg,
    required this.currentVamMetersPerHour,
    required this.wPrimeRemainingPercent,
    this.deltaHistorySeconds = const <double>[],
  });

  /// Przykładowy stan na podjeździe Alpe d'Huez (przydatny w testach i podglądzie).
  factory LiveStravaSegmentGhostData.sampleAlpeDhuez({
    bool ahead = true,
    bool hasCrossedStartGate = true,
    bool hasCrossedSummitGate = false,
  }) {
    return LiveStravaSegmentGhostData(
      segmentId: 'kom_alpe_dhuez',
      segmentName: "Alpe d'Huez (21 zakrętów)",
      classificationLabel: 'HC',
      riderName: 'T. Pogačar',
      riderTeamCode: 'UAD',
      komHolderName: 'M. Pantani',
      komHolderTeamCode: 'MER',
      komRecordYear: 1997,
      komRecordSeconds: 2255.0,
      komRecordWattsPerKg: 6.52,
      komRecordVamMetersPerHour: 1790.0,
      segmentLengthKm: 13.8,
      elevationGainM: 1120.0,
      averageGradientPercent: 8.1,
      currentGradientPercent: 9.6,
      hasCrossedStartGate: hasCrossedStartGate,
      hasCrossedSummitGate: hasCrossedSummitGate,
      distanceToStartGateMeters: hasCrossedStartGate ? 0.0 : 240.0,
      distanceCoveredKm: hasCrossedStartGate ? 8.4 : 0.0,
      riderElapsedSeconds: !hasCrossedStartGate
          ? 0.0
          : (ahead ? 1358.4 : 1386.8),
      ghostElapsedAtSameDistanceSeconds: 1372.6,
      currentSpeedKmh: ahead ? 22.8 : 20.9,
      currentPowerWatts: ahead ? 436.0 : 402.0,
      currentWattsPerKg: ahead ? 6.61 : 6.09,
      currentVamMetersPerHour: ahead ? 1824.0 : 1695.0,
      wPrimeRemainingPercent: ahead ? 58.0 : 34.0,
      deltaHistorySeconds: ahead
          ? const <double>[-1.2, -3.5, -6.1, -9.8, -11.4, -14.2]
          : const <double>[-2.0, 1.4, 5.8, 9.2, 12.1, 14.2],
    );
  }

  LiveStravaSegmentGhostData copyWith({
    String? segmentId,
    String? segmentName,
    String? classificationLabel,
    String? riderName,
    String? riderTeamCode,
    String? komHolderName,
    String? komHolderTeamCode,
    int? komRecordYear,
    double? komRecordSeconds,
    double? komRecordWattsPerKg,
    double? komRecordVamMetersPerHour,
    double? segmentLengthKm,
    double? elevationGainM,
    double? averageGradientPercent,
    double? currentGradientPercent,
    bool? hasCrossedStartGate,
    bool? hasCrossedSummitGate,
    double? distanceToStartGateMeters,
    double? distanceCoveredKm,
    double? riderElapsedSeconds,
    double? ghostElapsedAtSameDistanceSeconds,
    double? currentSpeedKmh,
    double? currentPowerWatts,
    double? currentWattsPerKg,
    double? currentVamMetersPerHour,
    double? wPrimeRemainingPercent,
    List<double>? deltaHistorySeconds,
  }) {
    return LiveStravaSegmentGhostData(
      segmentId: segmentId ?? this.segmentId,
      segmentName: segmentName ?? this.segmentName,
      classificationLabel: classificationLabel ?? this.classificationLabel,
      riderName: riderName ?? this.riderName,
      riderTeamCode: riderTeamCode ?? this.riderTeamCode,
      komHolderName: komHolderName ?? this.komHolderName,
      komHolderTeamCode: komHolderTeamCode ?? this.komHolderTeamCode,
      komRecordYear: komRecordYear ?? this.komRecordYear,
      komRecordSeconds: komRecordSeconds ?? this.komRecordSeconds,
      komRecordWattsPerKg: komRecordWattsPerKg ?? this.komRecordWattsPerKg,
      komRecordVamMetersPerHour:
          komRecordVamMetersPerHour ?? this.komRecordVamMetersPerHour,
      segmentLengthKm: segmentLengthKm ?? this.segmentLengthKm,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      averageGradientPercent:
          averageGradientPercent ?? this.averageGradientPercent,
      currentGradientPercent:
          currentGradientPercent ?? this.currentGradientPercent,
      hasCrossedStartGate: hasCrossedStartGate ?? this.hasCrossedStartGate,
      hasCrossedSummitGate: hasCrossedSummitGate ?? this.hasCrossedSummitGate,
      distanceToStartGateMeters:
          distanceToStartGateMeters ?? this.distanceToStartGateMeters,
      distanceCoveredKm: distanceCoveredKm ?? this.distanceCoveredKm,
      riderElapsedSeconds: riderElapsedSeconds ?? this.riderElapsedSeconds,
      ghostElapsedAtSameDistanceSeconds: ghostElapsedAtSameDistanceSeconds ??
          this.ghostElapsedAtSameDistanceSeconds,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentPowerWatts: currentPowerWatts ?? this.currentPowerWatts,
      currentWattsPerKg: currentWattsPerKg ?? this.currentWattsPerKg,
      currentVamMetersPerHour:
          currentVamMetersPerHour ?? this.currentVamMetersPerHour,
      wPrimeRemainingPercent:
          wPrimeRemainingPercent ?? this.wPrimeRemainingPercent,
      deltaHistorySeconds: deltaHistorySeconds ?? this.deltaHistorySeconds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'segmentId': segmentId,
        'segmentName': segmentName,
        'classificationLabel': classificationLabel,
        'riderName': riderName,
        'riderTeamCode': riderTeamCode,
        'komHolderName': komHolderName,
        'komHolderTeamCode': komHolderTeamCode,
        'komRecordYear': komRecordYear,
        'komRecordSeconds': komRecordSeconds,
        'komRecordWattsPerKg': komRecordWattsPerKg,
        'komRecordVamMetersPerHour': komRecordVamMetersPerHour,
        'segmentLengthKm': segmentLengthKm,
        'elevationGainM': elevationGainM,
        'averageGradientPercent': averageGradientPercent,
        'currentGradientPercent': currentGradientPercent,
        'hasCrossedStartGate': hasCrossedStartGate,
        'hasCrossedSummitGate': hasCrossedSummitGate,
        'distanceToStartGateMeters': distanceToStartGateMeters,
        'distanceCoveredKm': distanceCoveredKm,
        'riderElapsedSeconds': riderElapsedSeconds,
        'ghostElapsedAtSameDistanceSeconds': ghostElapsedAtSameDistanceSeconds,
        'currentSpeedKmh': currentSpeedKmh,
        'currentPowerWatts': currentPowerWatts,
        'currentWattsPerKg': currentWattsPerKg,
        'currentVamMetersPerHour': currentVamMetersPerHour,
        'wPrimeRemainingPercent': wPrimeRemainingPercent,
        'deltaHistorySeconds': deltaHistorySeconds,
      };

  factory LiveStravaSegmentGhostData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawHistory =
        json['deltaHistorySeconds'] as List<dynamic>? ?? const <dynamic>[];
    return LiveStravaSegmentGhostData(
      segmentId: json['segmentId'] as String? ?? 'kom_segment',
      segmentName: json['segmentName'] as String? ?? 'KOM Segment',
      classificationLabel: json['classificationLabel'] as String? ?? 'HC',
      riderName: json['riderName'] as String? ?? 'Rider',
      riderTeamCode: json['riderTeamCode'] as String? ?? 'PRO',
      komHolderName: json['komHolderName'] as String? ?? 'KOM Holder',
      komHolderTeamCode: json['komHolderTeamCode'] as String? ?? 'LEG',
      komRecordYear: (json['komRecordYear'] as num?)?.toInt() ?? 2024,
      komRecordSeconds: (json['komRecordSeconds'] as num?)?.toDouble() ?? 1800.0,
      komRecordWattsPerKg:
          (json['komRecordWattsPerKg'] as num?)?.toDouble() ?? 6.2,
      komRecordVamMetersPerHour:
          (json['komRecordVamMetersPerHour'] as num?)?.toDouble() ?? 1650.0,
      segmentLengthKm: (json['segmentLengthKm'] as num?)?.toDouble() ?? 10.0,
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 800.0,
      averageGradientPercent:
          (json['averageGradientPercent'] as num?)?.toDouble() ?? 8.0,
      currentGradientPercent:
          (json['currentGradientPercent'] as num?)?.toDouble() ?? 8.0,
      hasCrossedStartGate: json['hasCrossedStartGate'] as bool? ?? true,
      hasCrossedSummitGate: json['hasCrossedSummitGate'] as bool? ?? false,
      distanceToStartGateMeters:
          (json['distanceToStartGateMeters'] as num?)?.toDouble() ?? 0.0,
      distanceCoveredKm:
          (json['distanceCoveredKm'] as num?)?.toDouble() ?? 0.0,
      riderElapsedSeconds:
          (json['riderElapsedSeconds'] as num?)?.toDouble() ?? 0.0,
      ghostElapsedAtSameDistanceSeconds:
          (json['ghostElapsedAtSameDistanceSeconds'] as num?)?.toDouble(),
      currentSpeedKmh: (json['currentSpeedKmh'] as num?)?.toDouble() ?? 20.0,
      currentPowerWatts:
          (json['currentPowerWatts'] as num?)?.toDouble() ?? 380.0,
      currentWattsPerKg:
          (json['currentWattsPerKg'] as num?)?.toDouble() ?? 5.9,
      currentVamMetersPerHour:
          (json['currentVamMetersPerHour'] as num?)?.toDouble() ?? 1600.0,
      wPrimeRemainingPercent:
          (json['wPrimeRemainingPercent'] as num?)?.toDouble() ?? 50.0,
      deltaHistorySeconds: rawHistory
          .map((dynamic item) => (item as num).toDouble())
          .toList(growable: false),
    );
  }
}

/// Kalkulator fizyki porównania na żywo z duchem Rekordu Trasy (KOM Ghost).
class LiveStravaSegmentGhostCalculator {
  const LiveStravaSegmentGhostCalculator._();

  static double sanitize(double value, {double fallback = 0.0}) {
    if (value.isNaN || value.isInfinite) {
      return fallback;
    }
    return value;
  }

  /// Ułamek ukończenia segmentu w zakresie `[0.0, 1.0]`.
  static double progressFraction(LiveStravaSegmentGhostData data) {
    final double totalKm = math.max(0.05, sanitize(data.segmentLengthKm, fallback: 1.0));
    final double coveredKm = math.max(0.0, sanitize(data.distanceCoveredKm));
    if (data.hasCrossedSummitGate) {
      return 1.0;
    }
    return (coveredKm / totalKm).clamp(0.0, 1.0);
  }

  /// Pozostały dystans do bramy szczytowej w kilometrach.
  static double remainingDistanceKm(LiveStravaSegmentGhostData data) {
    if (data.hasCrossedSummitGate) {
      return 0.0;
    }
    final double totalKm = math.max(0.0, sanitize(data.segmentLengthKm));
    final double coveredKm = math.max(0.0, sanitize(data.distanceCoveredKm));
    return math.max(0.0, totalKm - coveredKm);
  }

  /// Czas ducha KOM w tym samym punkcie segmentu (w sekundach).
  static double effectiveGhostTimeAtPoint(LiveStravaSegmentGhostData data) {
    final double komTotal =
        math.max(1.0, sanitize(data.komRecordSeconds, fallback: 1800.0));
    final double? explicit = data.ghostElapsedAtSameDistanceSeconds;
    if (explicit != null && !explicit.isNaN && !explicit.isInfinite && explicit >= 0.0) {
      return explicit;
    }
    return komTotal * progressFraction(data);
  }

  /// Różnica sekundowa do KOM Ghost (`< 0` = przewaga gracza, `> 0` = strata).
  static double liveDeltaSeconds(LiveStravaSegmentGhostData data) {
    if (!data.hasCrossedStartGate) {
      return 0.0;
    }
    final double riderTime = math.max(0.0, sanitize(data.riderElapsedSeconds));
    final double ghostTime = effectiveGhostTimeAtPoint(data);
    return riderTime - ghostTime;
  }

  /// Szacowana pozycja ducha KOM na segmencie `[0.0, 1.0]` w chwili bieżącego czasu gracza.
  static double ghostProgressFraction(LiveStravaSegmentGhostData data) {
    if (!data.hasCrossedStartGate) {
      return 0.0;
    }
    final double komTotal =
        math.max(1.0, sanitize(data.komRecordSeconds, fallback: 1800.0));
    final double riderTime = math.max(0.0, sanitize(data.riderElapsedSeconds));
    return (riderTime / komTotal).clamp(0.0, 1.0);
  }

  /// Prognozowany czas na szczycie w sekundach na bazie aktualnego czasu i tempa.
  static double projectedSummitTimeSeconds(LiveStravaSegmentGhostData data) {
    final double komTotal =
        math.max(1.0, sanitize(data.komRecordSeconds, fallback: 1800.0));
    final double riderTime = math.max(0.0, sanitize(data.riderElapsedSeconds));
    if (data.hasCrossedSummitGate) {
      return riderTime;
    }
    final double speedKmh = sanitize(data.currentSpeedKmh);
    if (!data.hasCrossedStartGate) {
      final double totalKm = math.max(0.05, sanitize(data.segmentLengthKm, fallback: 1.0));
      if (speedKmh > 3.0) {
        return (totalKm / speedKmh) * 3600.0;
      }
      return komTotal;
    }

    final double remKm = remainingDistanceKm(data);
    if (remKm <= 0.001) {
      return riderTime;
    }

    if (speedKmh > 3.0) {
      final double remainingSeconds = (remKm / speedKmh) * 3600.0;
      return riderTime + remainingSeconds;
    }

    final double progress = progressFraction(data);
    if (progress > 0.02) {
      return riderTime / progress;
    }
    return komTotal;
  }

  /// Prognozowana różnica na szczycie względem Rekordu Trasy (`< 0` = nowy rekord).
  static double projectedSummitDeltaSeconds(LiveStravaSegmentGhostData data) {
    final double komTotal =
        math.max(1.0, sanitize(data.komRecordSeconds, fallback: 1800.0));
    return projectedSummitTimeSeconds(data) - komTotal;
  }

  /// Wymagana średnia prędkość na pozostałym dystansie, aby pobić KOM (km/h).
  static double requiredSpeedKmhForKom(LiveStravaSegmentGhostData data) {
    final double remKm = remainingDistanceKm(data);
    if (remKm <= 0.001) {
      return sanitize(data.currentSpeedKmh);
    }
    final double komTotal =
        math.max(1.0, sanitize(data.komRecordSeconds, fallback: 1800.0));
    final double riderTime = math.max(0.0, sanitize(data.riderElapsedSeconds));
    final double remainingBudgetSec = math.max(1.0, komTotal - riderTime);
    return (remKm / (remainingBudgetSec / 3600.0)).clamp(5.0, 65.0);
  }

  /// Określa status porównania z duchem KOM.
  static KomGhostComparisonStatus resolveStatus(
    LiveStravaSegmentGhostData data,
  ) {
    if (!data.hasCrossedStartGate) {
      return KomGhostComparisonStatus.approachingGate;
    }
    final double delta = liveDeltaSeconds(data);
    if (data.hasCrossedSummitGate) {
      return delta <= 0.0
          ? KomGhostComparisonStatus.summitCrossedNewKom
          : KomGhostComparisonStatus.summitCrossedBehind;
    }
    if (delta < -0.5) {
      return KomGhostComparisonStatus.aheadOfKom;
    }
    if (delta <= 0.5) {
      return KomGhostComparisonStatus.onPace;
    }
    return KomGhostComparisonStatus.behindKom;
  }

  /// Wyznacza wskazówkę taktyczną na podstawie delty i rezerwy beztlenowej W'.
  static KomGhostPacingAdvice resolveAdvice(LiveStravaSegmentGhostData data) {
    final double wPrime = sanitize(data.wPrimeRemainingPercent, fallback: 50.0)
        .clamp(0.0, 100.0);
    final double delta = liveDeltaSeconds(data);
    if (wPrime < 18.0) {
      return KomGhostPacingAdvice.redZoneWarning;
    }
    if (delta <= -1.0 && wPrime >= 35.0) {
      return KomGhostPacingAdvice.holdSteady;
    }
    if (delta > 0.0 && delta <= 18.0 && wPrime >= 30.0) {
      return KomGhostPacingAdvice.pushForKom;
    }
    if (delta > 18.0 && wPrime < 35.0) {
      return KomGhostPacingAdvice.recoverAndPace;
    }
    return KomGhostPacingAdvice.pushForKom;
  }

  /// Formatuje czas wyścigu jako `MM:SS` lub `H:MM:SS`.
  static String formatRaceTime(double totalSeconds) {
    final double clamped = math.max(0.0, sanitize(totalSeconds));
    final int rounded = clamped.round();
    final int hours = rounded ~/ 3600;
    final int minutes = (rounded % 3600) ~/ 60;
    final int seconds = rounded % 60;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Formatuje różnicę czasową z dokładnością do 0.1 s (np. `-12.4 s`, `+8.7 s`).
  static String formatSignedDelta(double deltaSeconds) {
    final double safe = sanitize(deltaSeconds);
    if (safe.abs() < 0.05) {
      return '0.0 s';
    }
    final String sign = safe < 0 ? '-' : '+';
    return '$sign${safe.abs().toStringAsFixed(1)} s';
  }
}

/// Widżet HUD porównania na żywo z historycznym Rekordem Trasy (KOM Ghost)
/// podczas wspinaczki w wyścigu 3D.
class LiveStravaSegmentGhostComparisonHud extends StatefulWidget {
  final LiveStravaSegmentGhostData? data;
  final bool enabled;
  final bool initiallyExpanded;
  final bool showGhostLineOnRoad;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onFocusGhostCamera;
  final VoidCallback? onDismiss;
  final ValueChanged<bool>? onGhostLineVisibilityChanged;

  const LiveStravaSegmentGhostComparisonHud({
    super.key,
    required this.data,
    this.enabled = true,
    this.initiallyExpanded = true,
    this.showGhostLineOnRoad = true,
    this.onToggleExpand,
    this.onFocusGhostCamera,
    this.onDismiss,
    this.onGhostLineVisibilityChanged,
  });

  @override
  State<LiveStravaSegmentGhostComparisonHud> createState() =>
      _LiveStravaSegmentGhostComparisonHudState();
}

class _LiveStravaSegmentGhostComparisonHudState
    extends State<LiveStravaSegmentGhostComparisonHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late bool _expanded;
  late bool _showGhostLine;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _showGhostLine = widget.showGhostLineOnRoad;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(
    covariant LiveStravaSegmentGhostComparisonHud oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showGhostLineOnRoad != widget.showGhostLineOnRoad) {
      _showGhostLine = widget.showGhostLineOnRoad;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleToggleExpand() {
    if (!widget.enabled) return;
    setState(() {
      _expanded = !_expanded;
    });
    widget.onToggleExpand?.call();
  }

  void _handleToggleGhostLine() {
    if (!widget.enabled) return;
    setState(() {
      _showGhostLine = !_showGhostLine;
    });
    widget.onGhostLineVisibilityChanged?.call(_showGhostLine);
  }

  @override
  Widget build(BuildContext context) {
    final LiveStravaSegmentGhostData? data = widget.data;
    if (data == null) {
      return _buildStandbyCard();
    }

    final KomGhostComparisonStatus status =
        LiveStravaSegmentGhostCalculator.resolveStatus(data);
    final Color statusColor = status.accentColor;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 440.0;
        final bool isNarrow = maxWidth < 400.0;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.enabled ? 1.0 : 0.48,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: math.min(maxWidth, 480.0),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.55),
                width: 1.0,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isNarrow ? 12.0 : 14.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildHeader(data, status, isNarrow),
                  const SizedBox(height: 10),
                  if (!data.hasCrossedStartGate)
                    _buildPreGateCountdown(data, isNarrow)
                  else
                    _buildLiveComparisonHero(data, status, isNarrow),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 260),
                    sizeCurve: Curves.easeOutCubic,
                    crossFadeState: _expanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 10),
                        _buildProgressAndSparkline(data, status, isNarrow),
                        const SizedBox(height: 10),
                        _buildTelemetryFooter(data, isNarrow),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStandbyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.emoji_events_outlined,
            size: 18,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Brak aktywnego segmentu KOM na tym odcinku trasy',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    LiveStravaSegmentGhostData data,
    KomGhostComparisonStatus status,
    bool isNarrow,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        AnimatedBuilder(
          animation: _pulseController,
          builder: (BuildContext context, Widget? child) {
            final double glow = data.hasCrossedStartGate
                ? 0.5 + 0.5 * _pulseController.value
                : 0.35;
            return Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: glow),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 17,
                color: AppColors.goldAccent,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.7),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      data.classificationLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data.segmentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isNarrow ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${data.segmentLengthKm.toStringAsFixed(1)} km · '
                'śr. ${data.averageGradientPercent.toStringAsFixed(1)}% · '
                'KOM: ${data.komHolderName} (${data.komRecordYear})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _HudInteractiveIconButton(
          tooltip: _showGhostLine
              ? 'Ukryj linię ducha KOM 3D'
              : 'Pokaż linię ducha KOM 3D',
          icon: _showGhostLine
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          isActive: _showGhostLine,
          enabled: widget.enabled,
          onPressed: _handleToggleGhostLine,
        ),
        if (widget.onFocusGhostCamera != null) ...<Widget>[
          const SizedBox(width: 4),
          _HudInteractiveIconButton(
            tooltip: 'Kamera pojedynku z duchem KOM',
            icon: Icons.videocam_rounded,
            isActive: false,
            enabled: widget.enabled,
            onPressed: widget.onFocusGhostCamera,
          ),
        ],
        const SizedBox(width: 4),
        _HudInteractiveIconButton(
          tooltip: _expanded ? 'Zwiń telemetrię KOM' : 'Rozwiń telemetrię KOM',
          icon: _expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          isActive: false,
          enabled: widget.enabled,
          onPressed: _handleToggleExpand,
        ),
        if (widget.onDismiss != null) ...<Widget>[
          const SizedBox(width: 4),
          _HudInteractiveIconButton(
            tooltip: 'Ukryj widżet KOM',
            icon: Icons.close_rounded,
            isActive: false,
            enabled: widget.enabled,
            onPressed: widget.onDismiss,
          ),
        ],
      ],
    );
  }

  Widget _buildPreGateCountdown(
    LiveStravaSegmentGhostData data,
    bool isNarrow,
  ) {
    final double distM = math.max(
      0.0,
      LiveStravaSegmentGhostCalculator.sanitize(data.distanceToStartGateMeters),
    );
    final String komFormatted =
        LiveStravaSegmentGhostCalculator.formatRaceTime(data.komRecordSeconds);

    return Container(
      padding: EdgeInsets.all(isNarrow ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'BRAMA POMIAROWA KOM ZA',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentBlue,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${distM.round()} m',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isNarrow ? 22 : 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'REKORD TRASY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$komFormatted · ${data.komRecordWattsPerKg.toStringAsFixed(2)} W/kg',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveComparisonHero(
    LiveStravaSegmentGhostData data,
    KomGhostComparisonStatus status,
    bool isNarrow,
  ) {
    final double delta = LiveStravaSegmentGhostCalculator.liveDeltaSeconds(data);
    final String deltaText =
        LiveStravaSegmentGhostCalculator.formatSignedDelta(delta);
    final double projectedSec =
        LiveStravaSegmentGhostCalculator.projectedSummitTimeSeconds(data);
    final double projectedDeltaSec =
        LiveStravaSegmentGhostCalculator.projectedSummitDeltaSeconds(data);
    final String projectedTimeText =
        LiveStravaSegmentGhostCalculator.formatRaceTime(projectedSec);
    final String komTimeText =
        LiveStravaSegmentGhostCalculator.formatRaceTime(data.komRecordSeconds);
    final String projectedDeltaText =
        LiveStravaSegmentGhostCalculator.formatSignedDelta(projectedDeltaSec);

    final Color deltaColor = status.accentColor;
    final Color projectedColor = projectedDeltaSec <= 0.0
        ? AppColors.statusSuccess
        : AppColors.crimsonAlert;

    return Container(
      padding: EdgeInsets.all(isNarrow ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: deltaColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: deltaColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        status.labelPl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: deltaColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  deltaText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isNarrow ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: deltaColor,
                    height: 1.05,
                    letterSpacing: -0.6,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Twój czas: ${LiveStravaSegmentGhostCalculator.formatRaceTime(data.riderElapsedSeconds)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    fontFeatures: <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFF2A2F3D),
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'PROGNOZA NA SZCZYCIE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        projectedTimeText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isNarrow ? 20 : 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($projectedDeltaText)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: projectedColor,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rekord KOM: $komTimeText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldAccent,
                    fontFeatures: <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressAndSparkline(
    LiveStravaSegmentGhostData data,
    KomGhostComparisonStatus status,
    bool isNarrow,
  ) {
    final double playerProgress =
        LiveStravaSegmentGhostCalculator.progressFraction(data);
    final double ghostProgress =
        LiveStravaSegmentGhostCalculator.ghostProgressFraction(data);
    final double remKm =
        LiveStravaSegmentGhostCalculator.remainingDistanceKm(data);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      '${data.distanceCoveredKm.toStringAsFixed(1)} / '
                      '${data.segmentLengthKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    Text(
                      'Do szczytu: ${remKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (data.deltaHistorySeconds.isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                SizedBox(
                  width: isNarrow ? 52 : 70,
                  height: 18,
                  child: CustomPaint(
                    painter: _KomDeltaSparklinePainter(
                      deltas: data.deltaHistorySeconds,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 22,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  painter: _KomGhostTrackPainter(
                    playerProgress: playerProgress,
                    ghostProgress: ghostProgress,
                    playerColor: status.accentColor,
                    pulseFactor: _pulseController.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _LegendDotLabel(
                color: status.accentColor,
                label: '${data.riderName} (${data.riderTeamCode})',
              ),
              _LegendDotLabel(
                color: AppColors.goldAccent,
                label: 'Duch KOM: ${data.komHolderName}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryFooter(
    LiveStravaSegmentGhostData data,
    bool isNarrow,
  ) {
    final KomGhostPacingAdvice advice =
        LiveStravaSegmentGhostCalculator.resolveAdvice(data);
    final double reqSpeed =
        LiveStravaSegmentGhostCalculator.requiredSpeedKmhForKom(data);
    final double wPrime = LiveStravaSegmentGhostCalculator.sanitize(
      data.wPrimeRemainingPercent,
      fallback: 50.0,
    ).clamp(0.0, 100.0);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _TelemetryChip(
          label: 'MOC',
          value:
              '${data.currentPowerWatts.round()} W · ${data.currentWattsPerKg.toStringAsFixed(2)} W/kg',
          valueColor: AppColors.textPrimary,
        ),
        _TelemetryChip(
          label: 'VAM',
          value: '${data.currentVamMetersPerHour.round()} m/h',
          valueColor: data.currentVamMetersPerHour >=
                  data.komRecordVamMetersPerHour
              ? AppColors.statusSuccess
              : AppColors.textPrimary,
        ),
        _TelemetryChip(
          label: 'NACHYLENIE',
          value: '${data.currentGradientPercent.toStringAsFixed(1)}%',
          valueColor: data.currentGradientPercent >= 10.0
              ? AppColors.amberWarning
              : AppColors.textPrimary,
        ),
        _TelemetryChip(
          label: 'CEL KOM',
          value: '${reqSpeed.toStringAsFixed(1)} km/h',
          valueColor: AppColors.goldAccent,
        ),
        _TelemetryChip(
          label: "W' BAL",
          value: '${wPrime.round()}%',
          valueColor: wPrime < 20.0
              ? AppColors.crimsonAlert
              : AppColors.cyanAccent,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: advice.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: advice.color.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(advice.icon, size: 13, color: advice.color),
              const SizedBox(width: 4),
              Text(
                advice.labelPl,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: advice.color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HudInteractiveIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final bool enabled;
  final VoidCallback? onPressed;

  const _HudInteractiveIconButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_HudInteractiveIconButton> createState() =>
      _HudInteractiveIconButtonState();
}

class _HudInteractiveIconButtonState extends State<_HudInteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool canInteract = widget.enabled && widget.onPressed != null;
    final Color bgColor = widget.isActive
        ? AppColors.goldAccent.withValues(alpha: 0.18)
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.85)
                : AppColors.background.withValues(alpha: 0.6)));
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isActive
            ? AppColors.goldAccent.withValues(alpha: 0.65)
            : const Color(0xFF2A2F3D));
    final Color iconColor = !canInteract
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : (widget.isActive ? AppColors.goldAccent : AppColors.textPrimary);

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: canInteract,
        onShowHoverHighlight: (bool value) {
          if (mounted) setState(() => _hovered = value);
        },
        onShowFocusHighlight: (bool value) {
          if (mounted) setState(() => _focused = value);
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: canInteract
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: canInteract
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: canInteract
              ? () => setState(() => _pressed = false)
              : null,
          onTap: canInteract ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: _focused ? 1.5 : 1.0,
                ),
              ),
              child: Icon(widget.icon, size: 16, color: iconColor),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
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

class _LegendDotLabel extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDotLabel({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KomGhostTrackPainter extends CustomPainter {
  final double playerProgress;
  final double ghostProgress;
  final Color playerColor;
  final double pulseFactor;

  const _KomGhostTrackPainter({
    required this.playerProgress,
    required this.ghostProgress,
    required this.playerColor,
    required this.pulseFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double pad = 9.0;
    final double trackWidth = math.max(1.0, size.width - pad * 2);
    final double centerY = size.height / 2;

    final Paint bgPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(pad, centerY),
      Offset(pad + trackWidth, centerY),
      bgPaint,
    );

    final double playerX = pad + trackWidth * playerProgress.clamp(0.0, 1.0);
    final double ghostX = pad + trackWidth * ghostProgress.clamp(0.0, 1.0);

    // Wypełnienie postępu gracza
    final Paint progressPaint = Paint()
      ..color = playerColor.withValues(alpha: 0.75)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(pad, centerY),
      Offset(playerX, centerY),
      progressPaint,
    );

    // Linia łącząca gracza z duchem KOM
    if ((playerX - ghostX).abs() > 2.0) {
      final Paint gapPaint = Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.45)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(math.min(playerX, ghostX), centerY),
        Offset(math.max(playerX, ghostX), centerY),
        gapPaint,
      );
    }

    // Punkt bramy szczytowej KOM
    final Paint summitPaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(Offset(pad + trackWidth, centerY), 4.5, summitPaint);

    // Marker ducha Rekordu Trasy (KOM Ghost)
    final Paint ghostGlow = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.25 + 0.15 * pulseFactor);
    canvas.drawCircle(Offset(ghostX, centerY), 8.0, ghostGlow);

    final Paint ghostFill = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(ghostX, centerY), 4.5, ghostFill);

    // Marker gracza
    final Paint playerRing = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final Paint playerFill = Paint()..color = playerColor;
    canvas.drawCircle(Offset(playerX, centerY), 6.0, playerFill);
    canvas.drawCircle(Offset(playerX, centerY), 6.0, playerRing);
  }

  @override
  bool shouldRepaint(covariant _KomGhostTrackPainter oldDelegate) {
    return oldDelegate.playerProgress != playerProgress ||
        oldDelegate.ghostProgress != ghostProgress ||
        oldDelegate.playerColor != playerColor ||
        oldDelegate.pulseFactor != pulseFactor;
  }
}

class _KomDeltaSparklinePainter extends CustomPainter {
  final List<double> deltas;

  const _KomDeltaSparklinePainter({required this.deltas});

  @override
  void paint(Canvas canvas, Size size) {
    if (deltas.length < 2) return;

    double maxAbs = 5.0;
    for (final double d in deltas) {
      if (!d.isNaN && !d.isInfinite) {
        maxAbs = math.max(maxAbs, d.abs());
      }
    }

    final double midY = size.height / 2;
    final Paint zeroPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), zeroPaint);

    final Path path = Path();
    for (int i = 0; i < deltas.length; i++) {
      final double x = (i / (deltas.length - 1)) * size.width;
      final double d = LiveStravaSegmentGhostCalculator.sanitize(deltas[i]);
      // Ujemna delta (przewaga) rysowana wyżej, dodatnia (strata) niżej
      final double norm = (-d / maxAbs).clamp(-1.0, 1.0);
      final double y = midY - norm * (size.height * 0.42);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final double last = LiveStravaSegmentGhostCalculator.sanitize(deltas.last);
    final Color strokeColor =
        last <= 0.0 ? AppColors.statusSuccess : AppColors.crimsonAlert;
    final Paint linePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _KomDeltaSparklinePainter oldDelegate) {
    return oldDelegate.deltas != deltas;
  }
}
