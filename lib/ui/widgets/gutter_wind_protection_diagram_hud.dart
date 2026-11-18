import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/peloton/team_sprint_train_echelon_diagonal_formation.dart';

/// Wiersz danych pojedynczego stopnia (kolarza) w mini-diagramie schodkowym.
@immutable
class GutterDiagramRiderNode {
  /// Identyfikator kolarza.
  final String riderId;

  /// Nazwa wyświetlana kolarza.
  final String name;

  /// Kod drużyny (np. `PPM`, `JUM`).
  final String teamId;

  /// Czy kolarz należy do drużyny gracza.
  final bool isPlayerTeam;

  /// Czy kolarz jest liderem / sprinterem chronionym w kieszeni.
  final bool isSprinter;

  /// Kolejny indeks w formacji schodkowej (0 = prowadzący na wietrze).
  final int stepIndex;

  /// Znormalizowana pozycja poprzeczna na szerokości drogi `0.0..1.0`
  /// (`0.0` = krawędź nawietrzna, `1.0` = krawężnik zawietrzny / rynsztok).
  final double lateralNormalized;

  /// Oszczędność mocy dzięki osłonie aerodynamicznej w procentach (`0..100`).
  final double draftingSavingsPercent;

  /// Efektywna ekspozycja na wiatr boczny (`0.0..1.0`).
  final double crosswindExposure;

  /// Aktualnie wymagana moc w watach.
  final double requiredPowerWatts;

  /// Status docisku do krawężnika (*In the Gutter*).
  final GutterPressureStatus gutterStatus;

  /// Szacowana strata czasowa na kilometr w sekundach (`0.0` w osłonie).
  final double timeLossPerKmSeconds;

  const GutterDiagramRiderNode({
    required this.riderId,
    required this.name,
    required this.teamId,
    required this.isPlayerTeam,
    required this.isSprinter,
    required this.stepIndex,
    required this.lateralNormalized,
    required this.draftingSavingsPercent,
    required this.crosswindExposure,
    required this.requiredPowerWatts,
    required this.gutterStatus,
    this.timeLossPerKmSeconds = 0.0,
  });

  /// Tworzy węzeł diagramu na podstawie wyliczenia [DiagonalRiderSlot].
  factory GutterDiagramRiderNode.fromSlot(DiagonalRiderSlot slot) {
    return GutterDiagramRiderNode(
      riderId: slot.riderId,
      name: slot.name,
      teamId: slot.teamId,
      isPlayerTeam: slot.isPlayerTeam,
      isSprinter: slot.isSprinter,
      stepIndex: math.max(0, slot.slotIndex),
      lateralNormalized: _clampFinite(slot.lateralNormalized, 0.0, 1.0),
      draftingSavingsPercent:
          _clampFinite(slot.draftingSavingsPercent, 0.0, 100.0),
      crosswindExposure:
          _clampFinite(slot.effectiveCrosswindExposure, 0.0, 1.0),
      requiredPowerWatts: _clampFinite(slot.requiredPowerWatts, 0.0, 2500.0),
      gutterStatus: slot.gutterStatus,
      timeLossPerKmSeconds:
          _clampFinite(slot.estimatedTimeLossPerKmSeconds, 0.0, 120.0),
    );
  }

  /// Bezpieczna znormalizowana pozycja poprzeczna w zakresie `0.0..1.0`.
  double get safeLateralNormalized => _clampFinite(lateralNormalized, 0.0, 1.0);

  /// Bezpieczna wartość oszczędności draftingu w zakresie `0.0..100.0`.
  double get safeDraftingSavingsPercent =>
      _clampFinite(draftingSavingsPercent, 0.0, 100.0);

  /// Bezpieczna wartość ekspozycji na wiatr boczny w zakresie `0.0..1.0`.
  double get safeCrosswindExposure => _clampFinite(crosswindExposure, 0.0, 1.0);

  /// Bezpieczna wymagana moc w watach.
  double get safeRequiredPowerWatts =>
      _clampFinite(requiredPowerWatts, 0.0, 2500.0);

  /// Bezpieczna strata czasowa na kilometr.
  double get safeTimeLossPerKmSeconds =>
      _clampFinite(timeLossPerKmSeconds, 0.0, 120.0);

  /// Zwraca kolor węzła w palecie [AppColors] w zależności od drużyny i statusu.
  Color get statusColor {
    if (isPlayerTeam) {
      if (isSprinter) {
        return AppColors.goldAccent;
      }
      if (gutterStatus == GutterPressureStatus.inTheGutter ||
          gutterStatus == GutterPressureStatus.droppedFromEchelon) {
        return AppColors.amberWarning;
      }
      return AppColors.accentBlue;
    }
    switch (gutterStatus) {
      case GutterPressureStatus.shelteredPocket:
        return AppColors.textSecondary;
      case GutterPressureStatus.fightingForWheel:
        return AppColors.amberWarning;
      case GutterPressureStatus.inTheGutter:
      case GutterPressureStatus.droppedFromEchelon:
        return AppColors.crimsonAlert;
    }
  }

  /// Serializuje węzeł do mapy JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'riderId': riderId,
        'name': name,
        'teamId': teamId,
        'isPlayerTeam': isPlayerTeam,
        'isSprinter': isSprinter,
        'stepIndex': stepIndex,
        'lateralNormalized': safeLateralNormalized,
        'draftingSavingsPercent': safeDraftingSavingsPercent,
        'crosswindExposure': safeCrosswindExposure,
        'requiredPowerWatts': safeRequiredPowerWatts,
        'gutterStatus': gutterStatus.toJson(),
        'timeLossPerKmSeconds': safeTimeLossPerKmSeconds,
      };

  /// Odtwarza węzeł z mapy JSON.
  factory GutterDiagramRiderNode.fromJson(Map<String, dynamic> json) {
    return GutterDiagramRiderNode(
      riderId: (json['riderId'] as String?) ?? 'unknown',
      name: (json['name'] as String?) ?? 'Kolarz',
      teamId: (json['teamId'] as String?) ?? 'TEAM',
      isPlayerTeam: (json['isPlayerTeam'] as bool?) ?? false,
      isSprinter: (json['isSprinter'] as bool?) ?? false,
      stepIndex: math.max(0, (json['stepIndex'] as num?)?.toInt() ?? 0),
      lateralNormalized: _clampFinite(
        (json['lateralNormalized'] as num?)?.toDouble() ?? 0.5,
        0.0,
        1.0,
      ),
      draftingSavingsPercent: _clampFinite(
        (json['draftingSavingsPercent'] as num?)?.toDouble() ?? 0.0,
        0.0,
        100.0,
      ),
      crosswindExposure: _clampFinite(
        (json['crosswindExposure'] as num?)?.toDouble() ?? 0.5,
        0.0,
        1.0,
      ),
      requiredPowerWatts: _clampFinite(
        (json['requiredPowerWatts'] as num?)?.toDouble() ?? 350.0,
        0.0,
        2500.0,
      ),
      gutterStatus: GutterPressureStatus.fromJson(
        (json['gutterStatus'] as String?) ?? 'shelteredPocket',
      ),
      timeLossPerKmSeconds: _clampFinite(
        (json['timeLossPerKmSeconds'] as num?)?.toDouble() ?? 0.0,
        0.0,
        120.0,
      ),
    );
  }
}

/// Kompletny model danych dla mini-diagramu schodkowego ochrony przed wiatrem bocznym.
@immutable
class GutterWindProtectionDiagramData {
  /// Nazwa sektora / strefy wiatru bocznego.
  final String sectorLabel;

  /// Składowa boczna wiatru w km/h.
  final double crosswindKmh;

  /// Kąt natarcia wiatru względem osi drogi w stopniach (`0..180`).
  final double windAngleDegrees;

  /// Kierunek wiatru bocznego (lewy vs prawy krawężnik).
  final CrosswindSide crosswindSide;

  /// Szerokość jezdni w metrach.
  final double roadWidthMeters;

  /// Kąt pochylenia schodkowego wachlarza w stopniach.
  final double diagonalAngleDegrees;

  /// Maksymalna pojemność osłoniętej kieszeni na szerokości jezdni.
  final int maxShelteredCapacity;

  /// Aktualny tryb formacji diagonalnej.
  final DiagonalTrainFormationMode formationMode;

  /// Aktualna faza manewru pociągu.
  final DiagonalTrainPhase phase;

  /// Czy strefa rynsztoka przy krawężniku została zamknięta przez pociąg.
  final bool isGutterClosed;

  /// Odstęp ostatniego kolarza pociągu od krawężnika zawietrznego w metrach.
  final double curbGapMeters;

  /// Węzły kolarzy drużyny gracza w formacji schodkowej.
  final List<GutterDiagramRiderNode> teamNodes;

  /// Węzły rywali walczących o koło lub zepchniętych w rynsztok.
  final List<GutterDiagramRiderNode> rivalNodes;

  const GutterWindProtectionDiagramData({
    required this.sectorLabel,
    required this.crosswindKmh,
    required this.windAngleDegrees,
    required this.crosswindSide,
    required this.roadWidthMeters,
    required this.diagonalAngleDegrees,
    required this.maxShelteredCapacity,
    required this.formationMode,
    required this.phase,
    required this.isGutterClosed,
    required this.curbGapMeters,
    this.teamNodes = const <GutterDiagramRiderNode>[],
    this.rivalNodes = const <GutterDiagramRiderNode>[],
  });

  /// Tworzy dane HUD bezpośrednio z wyniku ewaluacji [DiagonalEchelonEvaluation].
  factory GutterWindProtectionDiagramData.fromEvaluation(
    DiagonalEchelonEvaluation evaluation, {
    String sectorLabel = 'Odcinek Otwarty — Wiatr Boczny',
    CrosswindSide crosswindSide = CrosswindSide.leftToRight,
    double windAngleDegrees = 72.0,
    double roadWidthMeters = 6.5,
  }) {
    final List<GutterDiagramRiderNode> team = evaluation.teamSlots
        .map(GutterDiagramRiderNode.fromSlot)
        .toList(growable: false);
    final List<GutterDiagramRiderNode> rivals = evaluation.rivalSlots
        .map(GutterDiagramRiderNode.fromSlot)
        .toList(growable: false);

    return GutterWindProtectionDiagramData(
      sectorLabel: sectorLabel,
      crosswindKmh: _clampFinite(evaluation.effectiveCrosswindKmh, 0.0, 120.0),
      windAngleDegrees: _clampFinite(windAngleDegrees, 0.0, 180.0),
      crosswindSide: crosswindSide,
      roadWidthMeters: _clampFinite(roadWidthMeters, 2.5, 16.0),
      diagonalAngleDegrees:
          _clampFinite(evaluation.diagonalAngleDegrees, 0.0, 60.0),
      maxShelteredCapacity: math.max(1, evaluation.maxShelteredCapacity),
      formationMode: evaluation.formationMode,
      phase: evaluation.phase,
      isGutterClosed: evaluation.gutterReport.isGutterClosed,
      curbGapMeters:
          _clampFinite(evaluation.gutterReport.gutterGapMeters, 0.0, 10.0),
      teamNodes: team,
      rivalNodes: rivals,
    );
  }

  /// Bezpieczna prędkość wiatru bocznego w km/h.
  double get safeCrosswindKmh => _clampFinite(crosswindKmh, 0.0, 120.0);

  /// Bezpieczny kąt wiatru w stopniach.
  double get safeWindAngleDegrees => _clampFinite(windAngleDegrees, 0.0, 180.0);

  /// Bezpieczna szerokość drogi w metrach.
  double get safeRoadWidthMeters => _clampFinite(roadWidthMeters, 2.5, 16.0);

  /// Bezpieczny kąt schodkowy wachlarza w stopniach.
  double get safeDiagonalAngleDegrees =>
      _clampFinite(diagonalAngleDegrees, 0.0, 60.0);

  /// Bezpieczny odstęp od krawężnika w metrach.
  double get safeCurbGapMeters => _clampFinite(curbGapMeters, 0.0, 10.0);

  /// Liczba wszystkich kolarzy widocznych na diagramie.
  int get totalRiderCount => teamNodes.length + rivalNodes.length;

  /// Czy diagram nie zawiera żadnych aktywnych kolarzy.
  bool get isEmpty => totalRiderCount == 0;

  /// Liczba rywali zepchniętych w rynsztok lub odciętych z rantu.
  int get gutterTrappedCount => rivalNodes
      .where(
        (GutterDiagramRiderNode n) =>
            n.gutterStatus == GutterPressureStatus.inTheGutter ||
            n.gutterStatus == GutterPressureStatus.droppedFromEchelon,
      )
      .length;

  /// Średnia oszczędność aerodynamiczna kolarzy drużyny gracza w procentach.
  double get averageTeamDraftSavingsPercent {
    if (teamNodes.isEmpty) {
      return 0.0;
    }
    final double sum = teamNodes.fold<double>(
      0.0,
      (double acc, GutterDiagramRiderNode n) =>
          acc + n.safeDraftingSavingsPercent,
    );
    return sum / teamNodes.length;
  }

  /// Tworzy kopię danych z nadpisanym trybem formacji lub innymi polami.
  GutterWindProtectionDiagramData copyWith({
    String? sectorLabel,
    double? crosswindKmh,
    double? windAngleDegrees,
    CrosswindSide? crosswindSide,
    double? roadWidthMeters,
    double? diagonalAngleDegrees,
    int? maxShelteredCapacity,
    DiagonalTrainFormationMode? formationMode,
    DiagonalTrainPhase? phase,
    bool? isGutterClosed,
    double? curbGapMeters,
    List<GutterDiagramRiderNode>? teamNodes,
    List<GutterDiagramRiderNode>? rivalNodes,
  }) {
    return GutterWindProtectionDiagramData(
      sectorLabel: sectorLabel ?? this.sectorLabel,
      crosswindKmh: crosswindKmh ?? this.crosswindKmh,
      windAngleDegrees: windAngleDegrees ?? this.windAngleDegrees,
      crosswindSide: crosswindSide ?? this.crosswindSide,
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      diagonalAngleDegrees: diagonalAngleDegrees ?? this.diagonalAngleDegrees,
      maxShelteredCapacity: maxShelteredCapacity ?? this.maxShelteredCapacity,
      formationMode: formationMode ?? this.formationMode,
      phase: phase ?? this.phase,
      isGutterClosed: isGutterClosed ?? this.isGutterClosed,
      curbGapMeters: curbGapMeters ?? this.curbGapMeters,
      teamNodes: teamNodes ?? this.teamNodes,
      rivalNodes: rivalNodes ?? this.rivalNodes,
    );
  }

  /// Przykładowe dane telemetryczne dla podglądu i testów HUD 3D.
  factory GutterWindProtectionDiagramData.sample() {
    return const GutterWindProtectionDiagramData(
      sectorLabel: 'De Moeren — Otwarte Poldery (1.8 km do mety)',
      crosswindKmh: 36.4,
      windAngleDegrees: 74.0,
      crosswindSide: CrosswindSide.leftToRight,
      roadWidthMeters: 6.2,
      diagonalAngleDegrees: 26.5,
      maxShelteredCapacity: 6,
      formationMode: DiagonalTrainFormationMode.aggressiveGutterPress,
      phase: DiagonalTrainPhase.gutterSqueeze,
      isGutterClosed: true,
      curbGapMeters: 0.48,
      teamNodes: <GutterDiagramRiderNode>[
        GutterDiagramRiderNode(
          riderId: 't1',
          name: 'M. Kwiatkowski',
          teamId: 'PPM',
          isPlayerTeam: true,
          isSprinter: false,
          stepIndex: 0,
          lateralNormalized: 0.14,
          draftingSavingsPercent: 4.0,
          crosswindExposure: 0.96,
          requiredPowerWatts: 468.0,
          gutterStatus: GutterPressureStatus.shelteredPocket,
        ),
        GutterDiagramRiderNode(
          riderId: 't2',
          name: 'F. Ganna',
          teamId: 'PPM',
          isPlayerTeam: true,
          isSprinter: false,
          stepIndex: 1,
          lateralNormalized: 0.30,
          draftingSavingsPercent: 34.0,
          crosswindExposure: 0.32,
          requiredPowerWatts: 372.0,
          gutterStatus: GutterPressureStatus.shelteredPocket,
        ),
        GutterDiagramRiderNode(
          riderId: 't3',
          name: 'D. van Poppel',
          teamId: 'PPM',
          isPlayerTeam: true,
          isSprinter: false,
          stepIndex: 2,
          lateralNormalized: 0.47,
          draftingSavingsPercent: 42.0,
          crosswindExposure: 0.24,
          requiredPowerWatts: 344.0,
          gutterStatus: GutterPressureStatus.shelteredPocket,
        ),
        GutterDiagramRiderNode(
          riderId: 't4',
          name: 'O. Kooij',
          teamId: 'PPM',
          isPlayerTeam: true,
          isSprinter: true,
          stepIndex: 3,
          lateralNormalized: 0.65,
          draftingSavingsPercent: 48.0,
          crosswindExposure: 0.16,
          requiredPowerWatts: 318.0,
          gutterStatus: GutterPressureStatus.shelteredPocket,
        ),
        GutterDiagramRiderNode(
          riderId: 't5',
          name: 'L. Asgreen',
          teamId: 'PPM',
          isPlayerTeam: true,
          isSprinter: false,
          stepIndex: 4,
          lateralNormalized: 0.86,
          draftingSavingsPercent: 39.0,
          crosswindExposure: 0.28,
          requiredPowerWatts: 358.0,
          gutterStatus: GutterPressureStatus.shelteredPocket,
        ),
      ],
      rivalNodes: <GutterDiagramRiderNode>[
        GutterDiagramRiderNode(
          riderId: 'r1',
          name: 'J. Philipsen',
          teamId: 'ADC',
          isPlayerTeam: false,
          isSprinter: true,
          stepIndex: 5,
          lateralNormalized: 0.93,
          draftingSavingsPercent: 18.0,
          crosswindExposure: 0.72,
          requiredPowerWatts: 438.0,
          gutterStatus: GutterPressureStatus.fightingForWheel,
          timeLossPerKmSeconds: 1.4,
        ),
        GutterDiagramRiderNode(
          riderId: 'r2',
          name: 'T. Merlier',
          teamId: 'SOQ',
          isPlayerTeam: false,
          isSprinter: true,
          stepIndex: 6,
          lateralNormalized: 0.97,
          draftingSavingsPercent: 6.0,
          crosswindExposure: 0.94,
          requiredPowerWatts: 485.0,
          gutterStatus: GutterPressureStatus.inTheGutter,
          timeLossPerKmSeconds: 4.8,
        ),
        GutterDiagramRiderNode(
          riderId: 'r3',
          name: 'M. Pedersen',
          teamId: 'LTK',
          isPlayerTeam: false,
          isSprinter: false,
          stepIndex: 7,
          lateralNormalized: 0.99,
          draftingSavingsPercent: 0.0,
          crosswindExposure: 1.0,
          requiredPowerWatts: 504.0,
          gutterStatus: GutterPressureStatus.droppedFromEchelon,
          timeLossPerKmSeconds: 8.6,
        ),
      ],
    );
  }

  /// Pusty stan diagramu (brak aktywnego wachlarza).
  factory GutterWindProtectionDiagramData.empty() {
    return const GutterWindProtectionDiagramData(
      sectorLabel: 'Brak aktywnego sektora wiatru bocznego',
      crosswindKmh: 0.0,
      windAngleDegrees: 0.0,
      crosswindSide: CrosswindSide.leftToRight,
      roadWidthMeters: 6.5,
      diagonalAngleDegrees: 0.0,
      maxShelteredCapacity: 6,
      formationMode: DiagonalTrainFormationMode.standardInline,
      phase: DiagonalTrainPhase.positioning,
      isGutterClosed: false,
      curbGapMeters: 2.2,
    );
  }

  /// Serializuje dane diagramu do mapy JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'sectorLabel': sectorLabel,
        'crosswindKmh': safeCrosswindKmh,
        'windAngleDegrees': safeWindAngleDegrees,
        'crosswindSide': crosswindSide.toJson(),
        'roadWidthMeters': safeRoadWidthMeters,
        'diagonalAngleDegrees': safeDiagonalAngleDegrees,
        'maxShelteredCapacity': maxShelteredCapacity,
        'formationMode': formationMode.toJson(),
        'phase': phase.toJson(),
        'isGutterClosed': isGutterClosed,
        'curbGapMeters': safeCurbGapMeters,
        'teamNodes':
            teamNodes.map((GutterDiagramRiderNode n) => n.toJson()).toList(),
        'rivalNodes':
            rivalNodes.map((GutterDiagramRiderNode n) => n.toJson()).toList(),
      };

  /// Odtwarza dane diagramu z mapy JSON.
  factory GutterWindProtectionDiagramData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTeam =
        (json['teamNodes'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> rawRivals =
        (json['rivalNodes'] as List<dynamic>?) ?? const <dynamic>[];

    return GutterWindProtectionDiagramData(
      sectorLabel: (json['sectorLabel'] as String?) ?? 'Sektor Wiatru',
      crosswindKmh: _clampFinite(
        (json['crosswindKmh'] as num?)?.toDouble() ?? 0.0,
        0.0,
        120.0,
      ),
      windAngleDegrees: _clampFinite(
        (json['windAngleDegrees'] as num?)?.toDouble() ?? 0.0,
        0.0,
        180.0,
      ),
      crosswindSide: CrosswindSide.fromJson(
        (json['crosswindSide'] as String?) ?? 'leftToRight',
      ),
      roadWidthMeters: _clampFinite(
        (json['roadWidthMeters'] as num?)?.toDouble() ?? 6.5,
        2.5,
        16.0,
      ),
      diagonalAngleDegrees: _clampFinite(
        (json['diagonalAngleDegrees'] as num?)?.toDouble() ?? 0.0,
        0.0,
        60.0,
      ),
      maxShelteredCapacity: math.max(
        1,
        (json['maxShelteredCapacity'] as num?)?.toInt() ?? 6,
      ),
      formationMode: DiagonalTrainFormationMode.fromJson(
        (json['formationMode'] as String?) ?? 'diagonalShield',
      ),
      phase: DiagonalTrainPhase.fromJson(
        (json['phase'] as String?) ?? 'diagonalLock',
      ),
      isGutterClosed: (json['isGutterClosed'] as bool?) ?? false,
      curbGapMeters: _clampFinite(
        (json['curbGapMeters'] as num?)?.toDouble() ?? 1.5,
        0.0,
        10.0,
      ),
      teamNodes: rawTeam
          .whereType<Map<String, dynamic>>()
          .map(GutterDiagramRiderNode.fromJson)
          .toList(growable: false),
      rivalNodes: rawRivals
          .whereType<Map<String, dynamic>>()
          .map(GutterDiagramRiderNode.fromJson)
          .toList(growable: false),
    );
  }
}

/// Mini-diagram schodkowy ochrony przed wiatrem bocznym w HUD 3D.
///
/// Prezentuje ustawienie diagonalne pociągu sprinterskiego lub wachlarza
/// względem kierunku wiatru bocznego i krawężnika zawietrznego (*In the Gutter*),
/// z animowanymi strugami powietrza, kieszeniami osłony aerodynamicznej,
/// wyborem konkretnego kolarza oraz przełącznikiem trybów formacji.
class GutterWindProtectionDiagramHud extends StatefulWidget {
  /// Dane telemetryczne i pozycyjne diagramu schodkowego.
  final GutterWindProtectionDiagramData data;

  /// Czy widget jest aktywny (w trybie `false` przyjmuje stan `disabled`).
  final bool enabled;

  /// Czy sekcja ze szczegółami schodków i trybami jest domyślnie rozwinięta.
  final bool initiallyExpanded;

  /// Identyfikator aktualnie zaznaczonego kolarza (opcjonalny).
  final String? selectedRiderId;

  /// Wywołanie zwrotne po zmianie trybu formacji diagonalnej.
  final ValueChanged<DiagonalTrainFormationMode>? onFormationModeChanged;

  /// Wywołanie zwrotne po kliknięciu/wybraniu węzła kolarza na diagramie.
  final ValueChanged<GutterDiagramRiderNode>? onRiderSelected;

  const GutterWindProtectionDiagramHud({
    super.key,
    required this.data,
    this.enabled = true,
    this.initiallyExpanded = true,
    this.selectedRiderId,
    this.onFormationModeChanged,
    this.onRiderSelected,
  });

  @override
  State<GutterWindProtectionDiagramHud> createState() =>
      _GutterWindProtectionDiagramHudState();
}

class _GutterWindProtectionDiagramHudState
    extends State<GutterWindProtectionDiagramHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _windPulseController;
  late bool _isExpanded;
  String? _internalSelectedRiderId;
  bool _isHeaderHovered = false;
  bool _isHeaderFocused = false;
  bool _isHeaderPressed = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _internalSelectedRiderId = widget.selectedRiderId;
    _windPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.enabled && !widget.data.isEmpty) {
      _windPulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant GutterWindProtectionDiagramHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRiderId != oldWidget.selectedRiderId) {
      _internalSelectedRiderId = widget.selectedRiderId;
    }
    final bool shouldAnimate = widget.enabled && !widget.data.isEmpty;
    if (shouldAnimate && !_windPulseController.isAnimating) {
      _windPulseController.repeat();
    } else if (!shouldAnimate && _windPulseController.isAnimating) {
      _windPulseController.stop();
    }
  }

  @override
  void dispose() {
    _windPulseController.dispose();
    super.dispose();
  }

  String? get _activeSelectedRiderId {
    if (_internalSelectedRiderId != null) {
      return _internalSelectedRiderId;
    }
    if (widget.data.teamNodes.isNotEmpty) {
      final GutterDiagramRiderNode sprinter =
          widget.data.teamNodes.firstWhere(
        (GutterDiagramRiderNode n) => n.isSprinter,
        orElse: () => widget.data.teamNodes.first,
      );
      return sprinter.riderId;
    }
    if (widget.data.rivalNodes.isNotEmpty) {
      return widget.data.rivalNodes.first.riderId;
    }
    return null;
  }

  GutterDiagramRiderNode? get _selectedNode {
    final String? id = _activeSelectedRiderId;
    if (id == null) {
      return null;
    }
    for (final GutterDiagramRiderNode node in widget.data.teamNodes) {
      if (node.riderId == id) {
        return node;
      }
    }
    for (final GutterDiagramRiderNode node in widget.data.rivalNodes) {
      if (node.riderId == id) {
        return node;
      }
    }
    return null;
  }

  void _toggleExpanded() {
    if (!widget.enabled) {
      return;
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectRider(GutterDiagramRiderNode node) {
    if (!widget.enabled) {
      return;
    }
    setState(() {
      _internalSelectedRiderId = node.riderId;
    });
    widget.onRiderSelected?.call(node);
  }

  @override
  Widget build(BuildContext context) {
    final GutterWindProtectionDiagramData data = widget.data;
    final Color accentColor = _resolveAccentColor(data);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isNarrow = constraints.maxWidth < 460;
        final bool isWide = constraints.maxWidth >= 900;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          opacity: widget.enabled ? 1.0 : 0.56,
          child: Semantics(
            container: true,
            enabled: widget.enabled,
            label:
                'Mini-diagram schodkowy ochrony przed wiatrem bocznym: ${data.sectorLabel}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHeaderFocused
                      ? AppColors.goldAccent
                      : (data.isGutterClosed && widget.enabled
                          ? AppColors.goldAccent.withValues(alpha: 0.55)
                          : AppColors.cardBorder),
                  width: _isHeaderFocused ? 1.5 : 1.0,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildHeader(data, accentColor, isNarrow),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _isExpanded
                          ? Padding(
                              padding: EdgeInsets.fromLTRB(
                                isNarrow ? 12 : 16,
                                0,
                                isNarrow ? 12 : 16,
                                isNarrow ? 12 : 16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.cardBorder,
                                  ),
                                  const SizedBox(height: 12),
                                  if (data.isEmpty)
                                    _buildEmptyState()
                                  else ...<Widget>[
                                    if (isWide)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Expanded(
                                            flex: 3,
                                            child: _buildDiagramCanvas(
                                              data,
                                              isNarrow: false,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            flex: 2,
                                            child: _buildSideInspector(data),
                                          ),
                                        ],
                                      )
                                    else ...<Widget>[
                                      _buildDiagramCanvas(
                                        data,
                                        isNarrow: isNarrow,
                                      ),
                                      const SizedBox(height: 10),
                                      _buildSideInspector(data),
                                    ],
                                    const SizedBox(height: 12),
                                    _buildFormationModeSelector(isNarrow),
                                    const SizedBox(height: 12),
                                    _buildTelemetryStrip(data, isNarrow),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _resolveAccentColor(GutterWindProtectionDiagramData data) {
    if (!widget.enabled) {
      return AppColors.textSecondary;
    }
    if (data.isGutterClosed) {
      return AppColors.goldAccent;
    }
    if (data.safeCrosswindKmh >= 24.0) {
      return AppColors.amberWarning;
    }
    return AppColors.accentBlue;
  }

  Widget _buildHeader(
    GutterWindProtectionDiagramData data,
    Color accentColor,
    bool isNarrow,
  ) {
    final String windArrow =
        data.crosswindSide == CrosswindSide.leftToRight ? '→' : '←';
    final String gutterLabel = data.isEmpty
        ? 'OCZEKIWANIE'
        : (data.isGutterClosed ? 'RYNSZTOK ZAMKNIĘTY' : 'OTWARTA LUKA');
    final Color gutterColor = data.isEmpty
        ? AppColors.textSecondary
        : (data.isGutterClosed
            ? AppColors.goldAccent
            : AppColors.amberWarning);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (bool hovered) {
        if (mounted) {
          setState(() => _isHeaderHovered = hovered);
        }
      },
      onShowFocusHighlight: (bool focused) {
        if (mounted) {
          setState(() => _isHeaderFocused = focused);
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            _toggleExpanded();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _isHeaderPressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _isHeaderPressed = false)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _isHeaderPressed = false)
            : null,
        onTap: widget.enabled ? _toggleExpanded : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 16,
            vertical: 12,
          ),
          color: _isHeaderPressed
              ? AppColors.surfaceLight.withValues(alpha: 0.75)
              : (_isHeaderHovered
                  ? AppColors.surfaceLight.withValues(alpha: 0.45)
                  : Colors.transparent),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  Icons.air_rounded,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'OCHRONA WIATRU BOCZNEGO',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.sectorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isNarrow) ...<Widget>[
                const SizedBox(width: 8),
                _StatusPill(
                  label:
                      '${data.safeCrosswindKmh.toStringAsFixed(0)} km/h $windArrow',
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 6),
                _StatusPill(
                  label: gutterLabel,
                  color: gutterColor,
                ),
              ],
              const SizedBox(width: 8),
              AnimatedRotation(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                turns: _isExpanded ? 0.5 : 0.0,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.shield_outlined,
            size: 28,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'Brak aktywnego wachlarza — formacja w oczekiwaniu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Diagram schodkowy uruchomi się automatycznie po przekroczeniu progu wiatru bocznego.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramCanvas(
    GutterWindProtectionDiagramData data, {
    required bool isNarrow,
  }) {
    final double canvasHeight = isNarrow ? 210.0 : 235.0;
    final List<GutterDiagramRiderNode> allNodes = <GutterDiagramRiderNode>[
      ...data.teamNodes,
      ...data.rivalNodes,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: canvasHeight,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: widget.enabled
                      ? (TapUpDetails details) {
                          final GutterDiagramRiderNode? hit = _hitTestNode(
                            details.localPosition,
                            Size(box.maxWidth, box.maxHeight),
                            data,
                          );
                          if (hit != null) {
                            _selectRider(hit);
                          }
                        }
                      : null,
                  child: AnimatedBuilder(
                    animation: _windPulseController,
                    builder: (BuildContext context, _) {
                      return CustomPaint(
                        size: Size(box.maxWidth, box.maxHeight),
                        painter: GutterSteppedEchelonDiagramPainter(
                          data: data,
                          selectedRiderId: _activeSelectedRiderId,
                          windPulse: _windPulseController.value,
                          enabled: widget.enabled,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: allNodes.map((GutterDiagramRiderNode node) {
            final bool isSelected = node.riderId == _activeSelectedRiderId;
            return _RiderChipButton(
              node: node,
              isSelected: isSelected,
              enabled: widget.enabled,
              onTap: () => _selectRider(node),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  GutterDiagramRiderNode? _hitTestNode(
    Offset localPosition,
    Size size,
    GutterWindProtectionDiagramData data,
  ) {
    final List<GutterDiagramRiderNode> all = <GutterDiagramRiderNode>[
      ...data.teamNodes,
      ...data.rivalNodes,
    ];
    if (all.isEmpty) {
      return null;
    }

    GutterDiagramRiderNode? closest;
    double bestDist = 28.0;
    for (int i = 0; i < all.length; i++) {
      final GutterDiagramRiderNode node = all[i];
      final Offset center = GutterSteppedEchelonDiagramPainter.nodeCenter(
        node: node,
        indexInList: i,
        totalNodes: all.length,
        size: size,
        crosswindSide: data.crosswindSide,
      );
      final double d = (center - localPosition).distance;
      if (d < bestDist) {
        bestDist = d;
        closest = node;
      }
    }
    return closest;
  }

  Widget _buildSideInspector(GutterWindProtectionDiagramData data) {
    final GutterDiagramRiderNode? node = _selectedNode;
    if (node == null) {
      return const SizedBox.shrink();
    }

    final Color badgeColor = node.statusColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
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
                  '${node.name} (${node.teamId})',
                  maxLines: 1,
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
              _StatusPill(
                label: node.gutterStatus.labelPl,
                color: badgeColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              _InspectorMetric(
                label: 'Osłona Draft',
                value:
                    '${node.safeDraftingSavingsPercent.toStringAsFixed(0)}%',
                valueColor: AppColors.statusSuccess,
              ),
              _InspectorMetric(
                label: 'Ekspozycja',
                value:
                    '${(node.safeCrosswindExposure * 100).toStringAsFixed(0)}%',
                valueColor: node.safeCrosswindExposure > 0.65
                    ? AppColors.crimsonAlert
                    : AppColors.accentBlue,
              ),
              _InspectorMetric(
                label: 'Moc Wymagana',
                value: '${node.safeRequiredPowerWatts.toStringAsFixed(0)} W',
                valueColor: AppColors.textPrimary,
              ),
              _InspectorMetric(
                label: 'Strata / km',
                value: node.safeTimeLossPerKmSeconds <= 0.05
                    ? '0.0 s'
                    : '+${node.safeTimeLossPerKmSeconds.toStringAsFixed(1)} s',
                valueColor: node.safeTimeLossPerKmSeconds > 0.05
                    ? AppColors.crimsonAlert
                    : AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormationModeSelector(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'TAKTYKA USTAWIENIA WACHLARZA',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DiagonalTrainFormationMode.values.map((
            DiagonalTrainFormationMode mode,
          ) {
            final bool isActive = widget.data.formationMode == mode;
            return _FormationModeButton(
              mode: mode,
              isActive: isActive,
              enabled: widget.enabled,
              compact: isNarrow,
              onPressed: () => widget.onFormationModeChanged?.call(mode),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildTelemetryStrip(
    GutterWindProtectionDiagramData data,
    bool isNarrow,
  ) {
    final List<Widget> tiles = <Widget>[
      _TelemetryMiniTile(
        label: 'Wiatr Boczny',
        value: '${data.safeCrosswindKmh.toStringAsFixed(1)} km/h',
        accent: AppColors.accentBlue,
      ),
      _TelemetryMiniTile(
        label: 'Kąt Schodkowy',
        value: '${data.safeDiagonalAngleDegrees.toStringAsFixed(1)}°',
        accent: AppColors.cyanAccent,
      ),
      _TelemetryMiniTile(
        label: 'Śr. Osłona',
        value: '${data.averageTeamDraftSavingsPercent.toStringAsFixed(0)}%',
        accent: AppColors.statusSuccess,
      ),
      _TelemetryMiniTile(
        label: 'W Rynsztoku',
        value: '${data.gutterTrappedCount}',
        accent: data.gutterTrappedCount > 0
            ? AppColors.crimsonAlert
            : AppColors.textSecondary,
      ),
    ];

    if (isNarrow) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
        children: tiles,
      );
    }

    return Row(
      children: tiles
          .map(
            (Widget tile) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: tile,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// Rysuje schodkowy mini-diagram ochrony przed wiatrem bocznym oraz strefę rynsztoka.
class GutterSteppedEchelonDiagramPainter extends CustomPainter {
  /// Dane diagramu do wyrenderowania.
  final GutterWindProtectionDiagramData data;

  /// Identyfikator zaznaczonego kolarza.
  final String? selectedRiderId;

  /// Znormalizowana faza animacji strug wiatru (`0.0..1.0`).
  final double windPulse;

  /// Czy diagram jest aktywny.
  final bool enabled;

  const GutterSteppedEchelonDiagramPainter({
    required this.data,
    required this.selectedRiderId,
    required this.windPulse,
    required this.enabled,
  });

  /// Wyznacza środek węzła kolarza w układzie współrzędnych płótna.
  static Offset nodeCenter({
    required GutterDiagramRiderNode node,
    required int indexInList,
    required int totalNodes,
    required Size size,
    required CrosswindSide crosswindSide,
  }) {
    const double padX = 26.0;
    const double padTop = 26.0;
    const double padBottom = 26.0;
    final double usableW = math.max(40.0, size.width - padX * 2);
    final double usableH = math.max(40.0, size.height - padTop - padBottom);

    final double lat = node.safeLateralNormalized;
    final double xFrac =
        crosswindSide == CrosswindSide.leftToRight ? lat : (1.0 - lat);
    final double x = padX + xFrac * usableW;

    final int denom = math.max(1, totalNodes - 1);
    final double yFrac = totalNodes <= 1 ? 0.5 : (indexInList / denom);
    final double y = padTop + yFrac * usableH;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullRect = Offset.zero & size;
    const double gutterBandWidth = 22.0;
    final bool isLeftToRight = data.crosswindSide == CrosswindSide.leftToRight;

    // Tło asfaltu
    final Paint roadPaint = Paint()..color = AppColors.background;
    canvas.drawRect(fullRect, roadPaint);

    // Pas krawężnika zawietrznego (Gutter / Rynsztok)
    final Rect gutterRect = isLeftToRight
        ? Rect.fromLTWH(
            size.width - gutterBandWidth,
            0,
            gutterBandWidth,
            size.height,
          )
        : Rect.fromLTWH(0, 0, gutterBandWidth, size.height);

    final Color gutterBaseColor = data.isGutterClosed
        ? AppColors.crimsonAlert.withValues(alpha: enabled ? 0.22 : 0.10)
        : AppColors.amberWarning.withValues(alpha: enabled ? 0.14 : 0.08);
    canvas.drawRect(gutterRect, Paint()..color = gutterBaseColor);

    // Kreskowanie krawężnika
    final Paint curbLinePaint = Paint()
      ..color = data.isGutterClosed
          ? AppColors.crimsonAlert.withValues(alpha: 0.75)
          : AppColors.amberWarning.withValues(alpha: 0.55)
      ..strokeWidth = 2.0;
    final double curbX =
        isLeftToRight ? size.width - gutterBandWidth : gutterBandWidth;
    canvas.drawLine(
      Offset(curbX, 0),
      Offset(curbX, size.height),
      curbLinePaint,
    );

    // Linie podziału pasów drogi
    final Paint lanePaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    for (int lane = 1; lane <= 3; lane++) {
      final double lx = size.width * (lane / 4.0);
      canvas.drawLine(Offset(lx, 8), Offset(lx, size.height - 8), lanePaint);
    }

    // Animowane strugi wiatru bocznego
    _paintWindStreamlines(canvas, size, isLeftToRight);

    final List<GutterDiagramRiderNode> allNodes = <GutterDiagramRiderNode>[
      ...data.teamNodes,
      ...data.rivalNodes,
    ];
    if (allNodes.isEmpty) {
      return;
    }

    // Schodkowe połączenia między kolarzami + stożki cienia aerodynamicznego
    final List<Offset> centers = List<Offset>.generate(
      allNodes.length,
      (int i) => nodeCenter(
        node: allNodes[i],
        indexInList: i,
        totalNodes: allNodes.length,
        size: size,
        crosswindSide: data.crosswindSide,
      ),
      growable: false,
    );

    // Cień aerodynamiczny (kieszeń osłony) za kolarzami drużyny
    for (int i = 0; i < data.teamNodes.length; i++) {
      final Offset c = centers[i];
      final double dir = isLeftToRight ? 1.0 : -1.0;
      final Path shadowCone = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + dir * 24.0, c.dy + 22.0)
        ..lineTo(c.dx + dir * 6.0, c.dy + 26.0)
        ..close();
      canvas.drawPath(
        shadowCone,
        Paint()
          ..color = AppColors.accentBlue.withValues(alpha: enabled ? 0.14 : 0.06),
      );
    }

    // Schodkowe linie łączące kolejne stopnie wachlarza
    final Paint stepLinePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: enabled ? 0.72 : 0.35)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < centers.length - 1; i++) {
      final Offset a = centers[i];
      final Offset b = centers[i + 1];
      // Rysuj schodek (poziomo -> pionowo)
      final Path stepPath = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, a.dy)
        ..lineTo(b.dx, b.dy);
      canvas.drawPath(stepPath, stepLinePaint);
    }

    // Węzły kolarzy
    for (int i = 0; i < allNodes.length; i++) {
      final GutterDiagramRiderNode node = allNodes[i];
      final Offset c = centers[i];
      final bool isSelected = node.riderId == selectedRiderId;
      final Color nodeColor =
          enabled ? node.statusColor : AppColors.textSecondary;

      if (isSelected) {
        canvas.drawCircle(
          c,
          13.0,
          Paint()..color = nodeColor.withValues(alpha: 0.24),
        );
        canvas.drawCircle(
          c,
          13.0,
          Paint()
            ..color = AppColors.goldAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }

      final double radius = node.isSprinter ? 8.5 : 7.0;
      canvas.drawCircle(c, radius, Paint()..color = nodeColor);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..color = AppColors.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _paintWindStreamlines(
    Canvas canvas,
    Size size,
    bool isLeftToRight,
  ) {
    final double windStrength = (data.safeCrosswindKmh / 50.0).clamp(0.15, 1.0);
    final Paint windPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(
        alpha: enabled ? (0.12 + 0.14 * windStrength) : 0.07,
      )
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    const int lines = 5;
    for (int i = 0; i < lines; i++) {
      final double yBase = (size.height / (lines + 1)) * (i + 1);
      final double phaseOffset = ((windPulse + i * 0.19) % 1.0) * size.width;
      final double startX =
          isLeftToRight ? phaseOffset - 40.0 : size.width - phaseOffset + 40.0;
      final double dx = isLeftToRight ? 36.0 : -36.0;
      const double dy = 11.0;

      canvas.drawLine(
        Offset(startX, yBase),
        Offset(startX + dx, yBase + dy),
        windPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GutterSteppedEchelonDiagramPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.windPulse != windPulse ||
        oldDelegate.enabled != enabled;
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _RiderChipButton extends StatefulWidget {
  final GutterDiagramRiderNode node;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _RiderChipButton({
    required this.node,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_RiderChipButton> createState() => _RiderChipButtonState();
}

class _RiderChipButtonState extends State<_RiderChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color color = widget.node.statusColor;
    final Color bgColor = widget.isSelected
        ? color.withValues(alpha: 0.20)
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.8)
                : AppColors.background));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent _) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.isSelected ? color : AppColors.cardBorder),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.node.stepIndex + 1}. ${widget.node.name}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormationModeButton extends StatefulWidget {
  final DiagonalTrainFormationMode mode;
  final bool isActive;
  final bool enabled;
  final bool compact;
  final VoidCallback onPressed;

  const _FormationModeButton({
    required this.mode,
    required this.isActive,
    required this.enabled,
    required this.compact,
    required this.onPressed,
  });

  @override
  State<_FormationModeButton> createState() => _FormationModeButtonState();
}

class _FormationModeButtonState extends State<_FormationModeButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
        widget.mode == DiagonalTrainFormationMode.aggressiveGutterPress ||
                widget.mode == DiagonalTrainFormationMode.splitAndSnap
            ? AppColors.goldAccent
            : AppColors.accentBlue;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent _) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 9 : 11,
            vertical: widget.compact ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeColor.withValues(alpha: 0.18)
                : (_pressed
                    ? AppColors.surfaceLight
                    : (_hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.75)
                        : AppColors.background)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.isActive ? activeColor : AppColors.cardBorder),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.mode.labelPl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: widget.compact ? 11 : 12,
              fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
              color: widget.isActive ? activeColor : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InspectorMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InspectorMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TelemetryMiniTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryMiniTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

double _clampFinite(double value, double min, double max) {
  if (value.isNaN || value.isInfinite) {
    return min;
  }
  return value.clamp(min, max).toDouble();
}
