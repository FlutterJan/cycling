import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Status operacji szybkiego schowania się na koło najbliższego kolarza ("Snap to Wheel").
enum SnapToWheelStatus {
  /// Brak aktywnego przyciągania do koła.
  idle('Swobodny tor'),

  /// Aktywne dojeżdżanie i utrzymywanie tunelu za wybranym kolarzem.
  locked('Na kole'),

  /// Próba aktywacji nie powiodła się — brak kolarza w zasięgu draftu.
  noTargetInRange('Brak koła w zasięgu');

  final String label;
  const SnapToWheelStatus(this.label);
}

/// Aktywny kierunek ruchu poprzecznego po szosie.
enum LateralSteeringDirection {
  center('Środek'),
  left('Lewo'),
  right('Prawo');

  final String label;
  const LateralSteeringDirection(this.label);
}

/// Konfiguracja fizyki i czułości bezpośredniego sterowania pojedynczym kolarzem 3D.
@immutable
class DirectPlayerSteeringConfig {
  /// Szerokość jezdni w metrach (np. 7.0 m szosa, 3.2 m wąski bruk).
  final double roadWidthMeters;

  /// Szerokość bezpiecznego obrysu kolarza w metrach.
  final double riderWidthMeters;

  /// Długość bezpiecznego obrysu kolarza w metrach.
  final double riderLengthMeters;

  /// Prędkość zmiany intensywności pedałowania [% FTP / s] przy trzymaniu W/S.
  final double effortRampRatePerSecond;

  /// Minimalna intensywność pedałowania [% FTP] podczas jazdy z grupy.
  final double minEffortPercent;

  /// Maksymalna intensywność pedałowania na siedząco [% FTP].
  final double maxSeatedEffortPercent;

  /// Docelowa intensywność podczas maksymalnego sprintu na stojąco [% FTP].
  final double sprintEffortPercent;

  /// Prędkość przesuwu poprzecznego [znormalizowane jednostki szosy / s].
  final double lateralSteeringSpeedNormalized;

  /// Maksymalny kąt wychylenia roweru przy zmianie pasa [rad].
  final double maxLeanAngleRad;

  /// Maksymalny dystans w przód [m], na którym działa funkcja Snap to Wheel.
  final double snapToWheelMaxDistanceMeters;

  /// Minimalny bezpieczny dystans w przód [m] za kołem poprzedzającego kolarza.
  final double snapToWheelMinDistanceMeters;

  /// Liczba dostępnych przełożeń napędu (np. 24 dla układu 2x12).
  final int totalGears;

  const DirectPlayerSteeringConfig({
    this.roadWidthMeters = 7.0,
    this.riderWidthMeters = 0.65,
    this.riderLengthMeters = 1.85,
    this.effortRampRatePerSecond = 0.42,
    this.minEffortPercent = 0.30,
    this.maxSeatedEffortPercent = 1.35,
    this.sprintEffortPercent = 1.95,
    this.lateralSteeringSpeedNormalized = 1.35,
    this.maxLeanAngleRad = 0.28,
    this.snapToWheelMaxDistanceMeters = 14.0,
    this.snapToWheelMinDistanceMeters = 0.85,
    this.totalGears = 24,
  });

  DirectPlayerSteeringConfig copyWith({
    double? roadWidthMeters,
    double? riderWidthMeters,
    double? riderLengthMeters,
    double? effortRampRatePerSecond,
    double? minEffortPercent,
    double? maxSeatedEffortPercent,
    double? sprintEffortPercent,
    double? lateralSteeringSpeedNormalized,
    double? maxLeanAngleRad,
    double? snapToWheelMaxDistanceMeters,
    double? snapToWheelMinDistanceMeters,
    int? totalGears,
  }) {
    return DirectPlayerSteeringConfig(
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      riderWidthMeters: riderWidthMeters ?? this.riderWidthMeters,
      riderLengthMeters: riderLengthMeters ?? this.riderLengthMeters,
      effortRampRatePerSecond:
          effortRampRatePerSecond ?? this.effortRampRatePerSecond,
      minEffortPercent: minEffortPercent ?? this.minEffortPercent,
      maxSeatedEffortPercent:
          maxSeatedEffortPercent ?? this.maxSeatedEffortPercent,
      sprintEffortPercent: sprintEffortPercent ?? this.sprintEffortPercent,
      lateralSteeringSpeedNormalized:
          lateralSteeringSpeedNormalized ?? this.lateralSteeringSpeedNormalized,
      maxLeanAngleRad: maxLeanAngleRad ?? this.maxLeanAngleRad,
      snapToWheelMaxDistanceMeters:
          snapToWheelMaxDistanceMeters ?? this.snapToWheelMaxDistanceMeters,
      snapToWheelMinDistanceMeters:
          snapToWheelMinDistanceMeters ?? this.snapToWheelMinDistanceMeters,
      totalGears: totalGears ?? this.totalGears,
    );
  }
}

/// Sąsiedni kolarz w peletonie używany do wykrywania luk oraz Snap to Wheel.
@immutable
class SteeringPelotonNeighbor {
  final String riderId;
  final String riderName;
  final String teamCode;

  /// Dystans wzdłuż trasy względem gracza [m] (>0 przed graczem, <0 za graczem).
  final double distanceAheadMeters;

  /// Pozycja poprzeczna na szosie [-1.0 .. +1.0].
  final double lateralPositionRoad;

  /// Aktualna prędkość sąsiada [m/s].
  final double speedMs;

  const SteeringPelotonNeighbor({
    required this.riderId,
    required this.riderName,
    required this.teamCode,
    required this.distanceAheadMeters,
    required this.lateralPositionRoad,
    required this.speedMs,
  });
}

/// Wynik skanowania wolnych korytarzy i luk w peletonie po lewej i prawej stronie.
@immutable
class PelotonGapScanResult {
  final bool isLeftLaneOpen;
  final bool isRightLaneOpen;
  final double leftGapWidthMeters;
  final double rightGapWidthMeters;
  final String? nearestAheadRiderId;
  final double? nearestAheadDistanceMeters;
  final double? recommendedGapLateralOffset;

  const PelotonGapScanResult({
    required this.isLeftLaneOpen,
    required this.isRightLaneOpen,
    required this.leftGapWidthMeters,
    required this.rightGapWidthMeters,
    this.nearestAheadRiderId,
    this.nearestAheadDistanceMeters,
    this.recommendedGapLateralOffset,
  });

  static const empty = PelotonGapScanResult(
    isLeftLaneOpen: true,
    isRightLaneOpen: true,
    leftGapWidthMeters: 3.5,
    rightGapWidthMeters: 3.5,
  );
}

/// Wybrany cel funkcji Snap to Wheel.
@immutable
class SnapToWheelTarget {
  final String riderId;
  final String riderName;
  final String teamCode;
  final double distanceMeters;
  final double lateralPositionRoad;
  final double speedMs;
  final double estimatedDraftSavingsPercent;

  const SnapToWheelTarget({
    required this.riderId,
    required this.riderName,
    required this.teamCode,
    required this.distanceMeters,
    required this.lateralPositionRoad,
    required this.speedMs,
    required this.estimatedDraftSavingsPercent,
  });
}

/// Migawka aktualnie wciśniętych klawiszy sterujących graczem.
@immutable
class DirectPlayerInputSnapshot {
  final bool effortUpPressed;
  final bool effortDownPressed;
  final bool steerLeftPressed;
  final bool steerRightPressed;
  final bool sprintShiftPressed;
  final bool snapSpacePressed;

  const DirectPlayerInputSnapshot({
    this.effortUpPressed = false,
    this.effortDownPressed = false,
    this.steerLeftPressed = false,
    this.steerRightPressed = false,
    this.sprintShiftPressed = false,
    this.snapSpacePressed = false,
  });

  DirectPlayerInputSnapshot copyWith({
    bool? effortUpPressed,
    bool? effortDownPressed,
    bool? steerLeftPressed,
    bool? steerRightPressed,
    bool? sprintShiftPressed,
    bool? snapSpacePressed,
  }) {
    return DirectPlayerInputSnapshot(
      effortUpPressed: effortUpPressed ?? this.effortUpPressed,
      effortDownPressed: effortDownPressed ?? this.effortDownPressed,
      steerLeftPressed: steerLeftPressed ?? this.steerLeftPressed,
      steerRightPressed: steerRightPressed ?? this.steerRightPressed,
      sprintShiftPressed: sprintShiftPressed ?? this.sprintShiftPressed,
      snapSpacePressed: snapSpacePressed ?? this.snapSpacePressed,
    );
  }
}

/// Wyjściowy rozkaz sterowania przekazywany do silnika fizyki i renderera 3D.
@immutable
class DirectPlayerSteeringCommand {
  final double targetEffortPercent;
  final int targetWatts;
  final int gearIndex;
  final String gearLabel;
  final double targetLateralPositionRoad;
  final double lateralVelocityNormalized;
  final double leanAngleRad;
  final bool isStandingOnPedals;
  final bool isSprinting;
  final bool isSnappingToWheel;
  final String? snapTargetRiderId;
  final double estimatedDraftSavingsPercent;
  final int powerZone;

  const DirectPlayerSteeringCommand({
    required this.targetEffortPercent,
    required this.targetWatts,
    required this.gearIndex,
    required this.gearLabel,
    required this.targetLateralPositionRoad,
    required this.lateralVelocityNormalized,
    required this.leanAngleRad,
    required this.isStandingOnPedals,
    required this.isSprinting,
    required this.isSnappingToWheel,
    required this.snapTargetRiderId,
    required this.estimatedDraftSavingsPercent,
    required this.powerZone,
  });
}

/// Pełny, niezmienny stan kontrolera bezpośredniego sterowania kolarzem 3D.
@immutable
class DirectPlayerSteeringState {
  final String controlledRiderId;
  final String controlledRiderName;
  final bool isControlEnabled;
  final int riderFtpWatts;
  final double wPrimeRemainingJ;
  final double wPrimeMaxJ;
  final double currentSpeedMs;
  final double currentEffortPercent;
  final double preSprintEffortPercent;
  final int currentGearIndex;
  final double lateralPositionRoad;
  final double lateralVelocityNormalized;
  final double leanAngleRad;
  final bool isStandingOnPedals;
  final bool isSprinting;
  final SnapToWheelStatus snapToWheelStatus;
  final SnapToWheelTarget? snapTarget;
  final PelotonGapScanResult gapScan;
  final DirectPlayerInputSnapshot inputSnapshot;
  final DirectPlayerSteeringConfig config;
  final String statusFeedback;

  const DirectPlayerSteeringState({
    this.controlledRiderId = 'player_leader',
    this.controlledRiderName = 'Lider Drużyny',
    this.isControlEnabled = true,
    this.riderFtpWatts = 410,
    this.wPrimeRemainingJ = 22000.0,
    this.wPrimeMaxJ = 22000.0,
    this.currentSpeedMs = 12.2,
    this.currentEffortPercent = 0.78,
    this.preSprintEffortPercent = 0.78,
    this.currentGearIndex = 16,
    this.lateralPositionRoad = 0.0,
    this.lateralVelocityNormalized = 0.0,
    this.leanAngleRad = 0.0,
    this.isStandingOnPedals = false,
    this.isSprinting = false,
    this.snapToWheelStatus = SnapToWheelStatus.idle,
    this.snapTarget,
    this.gapScan = PelotonGapScanResult.empty,
    this.inputSnapshot = const DirectPlayerInputSnapshot(),
    this.config = const DirectPlayerSteeringConfig(),
    this.statusFeedback = 'Gotowy do jazdy w peletonie',
  });

  /// Aktualna moc docelowa w watach [W].
  int get targetWatts {
    final double effectiveEffort = isWPrimeDepleted && currentEffortPercent > 1.0
        ? 1.0
        : currentEffortPercent;
    return (riderFtpWatts * effectiveEffort).round().clamp(60, 1800);
  }

  /// Czy zapas beztlenowy W' został wyczerpany.
  bool get isWPrimeDepleted => wPrimeRemainingJ <= 150.0;

  /// Strefa mocy Coggana (Z1–Z7) wyliczona z aktualnej intensywności.
  int get powerZone {
    if (currentEffortPercent < 0.56) return 1;
    if (currentEffortPercent < 0.76) return 2;
    if (currentEffortPercent < 0.91) return 3;
    if (currentEffortPercent < 1.06) return 4;
    if (currentEffortPercent < 1.21) return 5;
    if (currentEffortPercent < 1.51) return 6;
    return 7;
  }

  /// Czytelna etykieta bieżącego przełożenia (układ 54/39T x 12s 11-30T).
  String get gearLabel => gearLabelForIndex(currentGearIndex);

  /// Aktualna szacowana oszczędność aerodynamiczna [%].
  double get estimatedDraftSavingsPercent =>
      snapTarget?.estimatedDraftSavingsPercent ?? 0.0;

  /// Kierunek aktywnego manewru poprzecznego.
  LateralSteeringDirection get lateralDirection {
    if (lateralVelocityNormalized < -0.05) return LateralSteeringDirection.left;
    if (lateralVelocityNormalized > 0.05) return LateralSteeringDirection.right;
    return LateralSteeringDirection.center;
  }

  /// Eksportuje czysty rozkaz sterowania dla pętli fizyki i renderera 3D.
  DirectPlayerSteeringCommand toCommand() {
    return DirectPlayerSteeringCommand(
      targetEffortPercent: currentEffortPercent,
      targetWatts: targetWatts,
      gearIndex: currentGearIndex,
      gearLabel: gearLabel,
      targetLateralPositionRoad: lateralPositionRoad,
      lateralVelocityNormalized: lateralVelocityNormalized,
      leanAngleRad: leanAngleRad,
      isStandingOnPedals: isStandingOnPedals,
      isSprinting: isSprinting,
      isSnappingToWheel: snapToWheelStatus == SnapToWheelStatus.locked,
      snapTargetRiderId: snapTarget?.riderId,
      estimatedDraftSavingsPercent: estimatedDraftSavingsPercent,
      powerZone: powerZone,
    );
  }

  DirectPlayerSteeringState copyWith({
    String? controlledRiderId,
    String? controlledRiderName,
    bool? isControlEnabled,
    int? riderFtpWatts,
    double? wPrimeRemainingJ,
    double? wPrimeMaxJ,
    double? currentSpeedMs,
    double? currentEffortPercent,
    double? preSprintEffortPercent,
    int? currentGearIndex,
    double? lateralPositionRoad,
    double? lateralVelocityNormalized,
    double? leanAngleRad,
    bool? isStandingOnPedals,
    bool? isSprinting,
    SnapToWheelStatus? snapToWheelStatus,
    SnapToWheelTarget? snapTarget,
    bool clearSnapTarget = false,
    PelotonGapScanResult? gapScan,
    DirectPlayerInputSnapshot? inputSnapshot,
    DirectPlayerSteeringConfig? config,
    String? statusFeedback,
  }) {
    return DirectPlayerSteeringState(
      controlledRiderId: controlledRiderId ?? this.controlledRiderId,
      controlledRiderName: controlledRiderName ?? this.controlledRiderName,
      isControlEnabled: isControlEnabled ?? this.isControlEnabled,
      riderFtpWatts: riderFtpWatts ?? this.riderFtpWatts,
      wPrimeRemainingJ: wPrimeRemainingJ ?? this.wPrimeRemainingJ,
      wPrimeMaxJ: wPrimeMaxJ ?? this.wPrimeMaxJ,
      currentSpeedMs: currentSpeedMs ?? this.currentSpeedMs,
      currentEffortPercent: currentEffortPercent ?? this.currentEffortPercent,
      preSprintEffortPercent:
          preSprintEffortPercent ?? this.preSprintEffortPercent,
      currentGearIndex: currentGearIndex ?? this.currentGearIndex,
      lateralPositionRoad: lateralPositionRoad ?? this.lateralPositionRoad,
      lateralVelocityNormalized:
          lateralVelocityNormalized ?? this.lateralVelocityNormalized,
      leanAngleRad: leanAngleRad ?? this.leanAngleRad,
      isStandingOnPedals: isStandingOnPedals ?? this.isStandingOnPedals,
      isSprinting: isSprinting ?? this.isSprinting,
      snapToWheelStatus: snapToWheelStatus ?? this.snapToWheelStatus,
      snapTarget: clearSnapTarget ? null : (snapTarget ?? this.snapTarget),
      gapScan: gapScan ?? this.gapScan,
      inputSnapshot: inputSnapshot ?? this.inputSnapshot,
      config: config ?? this.config,
      statusFeedback: statusFeedback ?? this.statusFeedback,
    );
  }

  /// Mapuje indeks biegu 1..24 na realistyczną kombinację tarcz 39/54T i kasety 11-30T.
  static String gearLabelForIndex(int gearIndex) {
    const List<int> cassette12s = <int>[
      30,
      27,
      24,
      21,
      19,
      17,
      16,
      15,
      14,
      13,
      12,
      11,
    ];
    final int clamped = gearIndex.clamp(1, 24);
    if (clamped <= 12) {
      return '39×${cassette12s[clamped - 1]}';
    }
    return '54×${cassette12s[clamped - 13]}';
  }
}

/// Kontroler bezpośredniego sterowania pojedynczym kolarzem w wyścigu 3D.
///
/// Obsługuje klawiaturę:
/// - `W` / `ArrowUp`: zwiększenie intensywności pedałowania i twardsze przełożenie,
/// - `S` / `ArrowDown`: zmniejszenie intensywności pedałowania i lżejsze przełożenie,
/// - `A` / `ArrowLeft` oraz `D` / `ArrowRight`: przesuwanie w poprzek szosy i szukanie luki,
/// - `ShiftLeft` / `ShiftRight`: wstanie w pedały i maksymalny sprint,
/// - `Space`: szybkie schowanie się na koło najbliższego kolarza (`Snap to Wheel`).
class DirectPlayerRiderSteeringController
    extends StateNotifier<DirectPlayerSteeringState> {
  List<SteeringPelotonNeighbor> _latestNeighbors = const [];

  DirectPlayerRiderSteeringController([
    DirectPlayerSteeringState? initialState,
  ]) : super(initialState ?? const DirectPlayerSteeringState());

  /// Aktualizuje telemetrię kontrolowanego kolarza z pętli symulacji.
  void syncRiderTelemetry({
    String? riderId,
    String? riderName,
    int? ftpWatts,
    double? wPrimeRemainingJ,
    double? wPrimeMaxJ,
    double? currentSpeedMs,
    List<SteeringPelotonNeighbor>? nearbyRiders,
  }) {
    if (nearbyRiders != null) {
      _latestNeighbors = List<SteeringPelotonNeighbor>.unmodifiable(nearbyRiders);
    }

    final PelotonGapScanResult gapScan = scanPelotonGaps(
      lateralPositionRoad: state.lateralPositionRoad,
      neighbors: _latestNeighbors,
      config: state.config,
    );

    SnapToWheelTarget? updatedTarget = state.snapTarget;
    SnapToWheelStatus updatedSnapStatus = state.snapToWheelStatus;
    if (updatedSnapStatus == SnapToWheelStatus.locked && updatedTarget != null) {
      final SteeringPelotonNeighbor? refreshed = _findNeighborById(
        _latestNeighbors,
        updatedTarget.riderId,
      );
      if (refreshed != null &&
          refreshed.distanceAheadMeters >= 0.4 &&
          refreshed.distanceAheadMeters <=
              state.config.snapToWheelMaxDistanceMeters + 4.0) {
        updatedTarget = _buildSnapTarget(refreshed);
      } else {
        updatedTarget = null;
        updatedSnapStatus = SnapToWheelStatus.idle;
      }
    }

    state = state.copyWith(
      controlledRiderId: riderId,
      controlledRiderName: riderName,
      riderFtpWatts: ftpWatts,
      wPrimeRemainingJ: wPrimeRemainingJ,
      wPrimeMaxJ: wPrimeMaxJ,
      currentSpeedMs: currentSpeedMs,
      gapScan: gapScan,
      snapTarget: updatedTarget,
      clearSnapTarget: updatedTarget == null,
      snapToWheelStatus: updatedSnapStatus,
    );
  }

  /// Włącza lub wyłącza ręczne sterowanie kolarzem.
  void setControlEnabled(bool enabled) {
    if (state.isControlEnabled == enabled) return;
    if (!enabled) {
      state = state.copyWith(
        isControlEnabled: false,
        inputSnapshot: const DirectPlayerInputSnapshot(),
        lateralVelocityNormalized: 0.0,
        leanAngleRad: 0.0,
        isStandingOnPedals: false,
        isSprinting: false,
        snapToWheelStatus: SnapToWheelStatus.idle,
        clearSnapTarget: true,
        statusFeedback: 'Sterowanie ręczne wyłączone (Autopilot)',
      );
      return;
    }
    state = state.copyWith(
      isControlEnabled: true,
      statusFeedback: 'Sterowanie ręczne aktywne',
    );
  }

  /// Przetwarza zdarzenie klawiatury Fluttera (`KeyDownEvent` / `KeyUpEvent` / `KeyRepeatEvent`).
  ///
  /// Zwraca `true`, jeśli klawisz został obsłużony przez kontroler.
  bool handleKeyEvent(KeyEvent event) {
    if (!state.isControlEnabled) {
      return false;
    }

    final LogicalKeyboardKey key = event.logicalKey;
    final bool isDown = event is KeyDownEvent;
    final bool isUp = event is KeyUpEvent;
    final bool isRepeat = event is KeyRepeatEvent;

    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.arrowUp) {
      if (isDown) {
        _onEffortUpPressed();
      } else if (isUp) {
        state = state.copyWith(
          inputSnapshot: state.inputSnapshot.copyWith(effortUpPressed: false),
        );
      } else if (isRepeat) {
        stepFrame(0.05);
      }
      return true;
    }

    if (key == LogicalKeyboardKey.keyS || key == LogicalKeyboardKey.arrowDown) {
      if (isDown) {
        _onEffortDownPressed();
      } else if (isUp) {
        state = state.copyWith(
          inputSnapshot: state.inputSnapshot.copyWith(effortDownPressed: false),
        );
      } else if (isRepeat) {
        stepFrame(0.05);
      }
      return true;
    }

    if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.arrowLeft) {
      if (isDown) {
        _onSteerLeftPressed();
      } else if (isUp) {
        state = state.copyWith(
          inputSnapshot: state.inputSnapshot.copyWith(steerLeftPressed: false),
        );
      }
      return true;
    }

    if (key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.arrowRight) {
      if (isDown) {
        _onSteerRightPressed();
      } else if (isUp) {
        state = state.copyWith(
          inputSnapshot: state.inputSnapshot.copyWith(steerRightPressed: false),
        );
      }
      return true;
    }

    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      if (isDown) {
        setSprintEngaged(true);
      } else if (isUp) {
        setSprintEngaged(false);
      }
      return true;
    }

    if (key == LogicalKeyboardKey.space) {
      if (isDown) {
        triggerSnapToWheel(_latestNeighbors);
      } else if (isUp) {
        state = state.copyWith(
          inputSnapshot: state.inputSnapshot.copyWith(snapSpacePressed: false),
        );
      }
      return true;
    }

    return false;
  }

  /// Ręczne podbicie intensywności o jeden krok (np. kliknięcie przycisku HUD `+`).
  void stepEffortUp({double deltaPercent = 0.05}) {
    if (!state.isControlEnabled) return;
    final double nextEffort = (state.currentEffortPercent + deltaPercent).clamp(
      state.config.minEffortPercent,
      state.isSprinting
          ? state.config.sprintEffortPercent
          : state.config.maxSeatedEffortPercent,
    );
    final int nextGear = _gearForEffortAndSpeed(
      effortPercent: nextEffort,
      speedMs: state.currentSpeedMs,
      totalGears: state.config.totalGears,
      currentGear: math.min(state.config.totalGears, state.currentGearIndex + 1),
    );
    state = state.copyWith(
      currentEffortPercent: nextEffort,
      preSprintEffortPercent:
          state.isSprinting ? state.preSprintEffortPercent : nextEffort,
      currentGearIndex: nextGear,
      statusFeedback:
          'Zwiększono moc: ${(nextEffort * 100).round()}% FTP (${DirectPlayerSteeringState.gearLabelForIndex(nextGear)})',
    );
  }

  /// Ręczne obniżenie intensywności o jeden krok (np. kliknięcie przycisku HUD `-`).
  void stepEffortDown({double deltaPercent = 0.05}) {
    if (!state.isControlEnabled) return;
    final double nextEffort = (state.currentEffortPercent - deltaPercent).clamp(
      state.config.minEffortPercent,
      state.isSprinting
          ? state.config.sprintEffortPercent
          : state.config.maxSeatedEffortPercent,
    );
    final int nextGear = _gearForEffortAndSpeed(
      effortPercent: nextEffort,
      speedMs: state.currentSpeedMs,
      totalGears: state.config.totalGears,
      currentGear: math.max(1, state.currentGearIndex - 1),
    );
    state = state.copyWith(
      currentEffortPercent: nextEffort,
      preSprintEffortPercent:
          state.isSprinting ? state.preSprintEffortPercent : nextEffort,
      currentGearIndex: nextGear,
      statusFeedback:
          'Zmniejszono moc: ${(nextEffort * 100).round()}% FTP (${DirectPlayerSteeringState.gearLabelForIndex(nextGear)})',
    );
  }

  /// Bezpośrednie ustawienie przełożenia napędu w górę lub w dół.
  void shiftGear(int delta) {
    if (!state.isControlEnabled) return;
    final int nextGear =
        (state.currentGearIndex + delta).clamp(1, state.config.totalGears);
    if (nextGear == state.currentGearIndex) return;
    state = state.copyWith(
      currentGearIndex: nextGear,
      statusFeedback:
          'Zmiana biegu: ${DirectPlayerSteeringState.gearLabelForIndex(nextGear)}',
    );
  }

  /// Ręczny impuls przesunięcia w poprzek szosy (`-1.0` lewo, `+1.0` prawo).
  void nudgeLateral(double deltaNormalized) {
    if (!state.isControlEnabled) return;
    final double target =
        (state.lateralPositionRoad + deltaNormalized).clamp(-1.0, 1.0);
    final PelotonGapScanResult gapScan = scanPelotonGaps(
      lateralPositionRoad: target,
      neighbors: _latestNeighbors,
      config: state.config,
    );
    state = state.copyWith(
      lateralPositionRoad: target,
      lateralVelocityNormalized: deltaNormalized.sign * 0.85,
      leanAngleRad:
          (deltaNormalized.sign * state.config.maxLeanAngleRad * 0.65)
              .clamp(-state.config.maxLeanAngleRad, state.config.maxLeanAngleRad),
      snapToWheelStatus: SnapToWheelStatus.idle,
      clearSnapTarget: true,
      gapScan: gapScan,
      statusFeedback: deltaNormalized < 0
          ? 'Przesunięcie w lewo (szukanie luki)'
          : 'Przesunięcie w prawo (szukanie luki)',
    );
  }

  /// Wstanie w pedały i uruchomienie maksymalnego sprintu (`Shift`).
  void setSprintEngaged(bool engaged) {
    if (!state.isControlEnabled) return;
    if (engaged) {
      if (state.isWPrimeDepleted) {
        state = state.copyWith(
          inputSnapshot:
              state.inputSnapshot.copyWith(sprintShiftPressed: true),
          isStandingOnPedals: true,
          isSprinting: false,
          currentEffortPercent: 1.0,
          statusFeedback: 'Brak W\' — jazda na progu na stojąco',
        );
        return;
      }

      final double savedEffort = state.isSprinting
          ? state.preSprintEffortPercent
          : state.currentEffortPercent;
      final int sprintGear = math.max(
        state.currentGearIndex,
        (state.config.totalGears - 2).clamp(1, state.config.totalGears),
      );
      state = state.copyWith(
        inputSnapshot: state.inputSnapshot.copyWith(sprintShiftPressed: true),
        isStandingOnPedals: true,
        isSprinting: true,
        preSprintEffortPercent: savedEffort,
        currentEffortPercent: state.config.sprintEffortPercent,
        currentGearIndex: sprintGear,
        snapToWheelStatus: SnapToWheelStatus.idle,
        clearSnapTarget: true,
        statusFeedback: 'SPRINT MAKSYMALNY na stojąco!',
      );
    } else {
      final double restoredEffort = state.preSprintEffortPercent.clamp(
        state.config.minEffortPercent,
        state.config.maxSeatedEffortPercent,
      );
      state = state.copyWith(
        inputSnapshot: state.inputSnapshot.copyWith(sprintShiftPressed: false),
        isStandingOnPedals: false,
        isSprinting: false,
        currentEffortPercent: restoredEffort,
        statusFeedback: 'Powrót do pozycji siedzącej',
      );
    }
  }

  /// Szybkie schowanie się na koło najbliższego kolarza przed graczem (`Spacja`).
  SnapToWheelTarget? triggerSnapToWheel([
    List<SteeringPelotonNeighbor>? overrideNeighbors,
  ]) {
    if (!state.isControlEnabled) return null;
    final List<SteeringPelotonNeighbor> neighbors =
        overrideNeighbors ?? _latestNeighbors;
    if (overrideNeighbors != null) {
      _latestNeighbors =
          List<SteeringPelotonNeighbor>.unmodifiable(overrideNeighbors);
    }

    final SnapToWheelTarget? bestTarget = findNearestWheelTarget(
      playerLateralPositionRoad: state.lateralPositionRoad,
      neighbors: neighbors,
      config: state.config,
    );

    if (bestTarget == null) {
      state = state.copyWith(
        inputSnapshot: state.inputSnapshot.copyWith(snapSpacePressed: true),
        snapToWheelStatus: SnapToWheelStatus.noTargetInRange,
        clearSnapTarget: true,
        statusFeedback: 'Brak kolarza w zasięgu Snap to Wheel',
      );
      return null;
    }

    state = state.copyWith(
      inputSnapshot: state.inputSnapshot.copyWith(snapSpacePressed: true),
      snapToWheelStatus: SnapToWheelStatus.locked,
      snapTarget: bestTarget,
      statusFeedback:
          'Snap to Wheel: na kole ${bestTarget.riderName} (-${bestTarget.estimatedDraftSavingsPercent.round()}% oporu)',
    );
    return bestTarget;
  }

  /// Anuluje aktywne przyciąganie do koła.
  void releaseSnapToWheel() {
    if (state.snapToWheelStatus == SnapToWheelStatus.idle &&
        state.snapTarget == null) {
      return;
    }
    state = state.copyWith(
      snapToWheelStatus: SnapToWheelStatus.idle,
      clearSnapTarget: true,
      statusFeedback: 'Opuszczono koło rywala',
    );
  }

  /// Wykonuje krok symulacji sterowania dla pojedynczej klatki (`dtSeconds`, np. 1/60 s).
  DirectPlayerSteeringCommand stepFrame(
    double dtSeconds, {
    List<SteeringPelotonNeighbor>? neighbors,
  }) {
    if (!state.isControlEnabled || dtSeconds <= 0.0) {
      return state.toCommand();
    }

    if (neighbors != null) {
      _latestNeighbors = List<SteeringPelotonNeighbor>.unmodifiable(neighbors);
    }

    final double dt = dtSeconds.clamp(0.001, 0.25);
    final DirectPlayerInputSnapshot input = state.inputSnapshot;
    final DirectPlayerSteeringConfig cfg = state.config;

    // 1. Intensywność pedałowania i przełożenia (W/S lub strzałki góra/dół)
    double nextEffort = state.currentEffortPercent;
    int nextGear = state.currentGearIndex;
    double nextPreSprintEffort = state.preSprintEffortPercent;
    bool nextStanding = state.isStandingOnPedals;
    bool nextSprinting = state.isSprinting;

    if (input.sprintShiftPressed && !state.isWPrimeDepleted) {
      nextStanding = true;
      nextSprinting = true;
      nextEffort = cfg.sprintEffortPercent;
    } else {
      if (input.effortUpPressed && !input.effortDownPressed) {
        nextEffort += cfg.effortRampRatePerSecond * dt;
      } else if (input.effortDownPressed && !input.effortUpPressed) {
        nextEffort -= cfg.effortRampRatePerSecond * dt;
      }
      final double maxEffort =
          nextSprinting ? cfg.sprintEffortPercent : cfg.maxSeatedEffortPercent;
      nextEffort = nextEffort.clamp(cfg.minEffortPercent, maxEffort);
      if (!nextSprinting) {
        nextPreSprintEffort = nextEffort;
      }
    }

    nextGear = _gearForEffortAndSpeed(
      effortPercent: nextEffort,
      speedMs: state.currentSpeedMs,
      totalGears: cfg.totalGears,
      currentGear: nextGear,
    );

    // 2. Skanowanie luk w peletonie i sterowanie poprzeczne (A/D lub lewo/prawo)
    final PelotonGapScanResult gapScan = scanPelotonGaps(
      lateralPositionRoad: state.lateralPositionRoad,
      neighbors: _latestNeighbors,
      config: cfg,
    );

    double nextLateral = state.lateralPositionRoad;
    double nextLateralVel = 0.0;
    SnapToWheelStatus nextSnapStatus = state.snapToWheelStatus;
    SnapToWheelTarget? nextSnapTarget = state.snapTarget;

    final int manualLateralAxis =
        (input.steerRightPressed ? 1 : 0) - (input.steerLeftPressed ? 1 : 0);

    if (manualLateralAxis != 0) {
      // Ręczne sterowanie A/D przerywa Snap to Wheel
      nextSnapStatus = SnapToWheelStatus.idle;
      nextSnapTarget = null;
      nextLateralVel = manualLateralAxis * cfg.lateralSteeringSpeedNormalized;

      // Jeśli sąsiednia luka jest blisko i tor jest lekko przysłonięty, subtelne wspomaganie szukania luki
      double candidateLateral = nextLateral + nextLateralVel * dt;
      if (gapScan.recommendedGapLateralOffset != null &&
          ((manualLateralAxis < 0 && !gapScan.isLeftLaneOpen) ||
              (manualLateralAxis > 0 && !gapScan.isRightLaneOpen))) {
        final double nudge =
            (gapScan.recommendedGapLateralOffset! - candidateLateral) * 0.25;
        candidateLateral += nudge * dt * 4.0;
      }
      nextLateral = candidateLateral.clamp(-1.0, 1.0);
    } else if (nextSnapStatus == SnapToWheelStatus.locked &&
        nextSnapTarget != null) {
      final SteeringPelotonNeighbor? liveTarget = _findNeighborById(
        _latestNeighbors,
        nextSnapTarget.riderId,
      );
      if (liveTarget != null) {
        nextSnapTarget = _buildSnapTarget(liveTarget);
      }
      final double lateralError =
          nextSnapTarget.lateralPositionRoad - nextLateral;
      final double maxStep = cfg.lateralSteeringSpeedNormalized * 1.45 * dt;
      final double step = lateralError.clamp(-maxStep, maxStep);
      nextLateral = (nextLateral + step).clamp(-1.0, 1.0);
      nextLateralVel = step / dt;
    }

    final double targetLean = (nextLateralVel /
            math.max(0.1, cfg.lateralSteeringSpeedNormalized)) *
        cfg.maxLeanAngleRad;
    final double nextLean = (state.leanAngleRad +
            (targetLean - state.leanAngleRad) * math.min(1.0, dt * 12.0))
        .clamp(-cfg.maxLeanAngleRad, cfg.maxLeanAngleRad);

    state = state.copyWith(
      currentEffortPercent: nextEffort,
      preSprintEffortPercent: nextPreSprintEffort,
      currentGearIndex: nextGear,
      lateralPositionRoad: nextLateral,
      lateralVelocityNormalized: nextLateralVel,
      leanAngleRad: nextLean,
      isStandingOnPedals: nextStanding,
      isSprinting: nextSprinting,
      snapToWheelStatus: nextSnapStatus,
      snapTarget: nextSnapTarget,
      clearSnapTarget: nextSnapTarget == null,
      gapScan: gapScan,
    );

    return state.toCommand();
  }

  /// Skanuje luki po lewej i prawej stronie kolarza w peletonie.
  static PelotonGapScanResult scanPelotonGaps({
    required double lateralPositionRoad,
    required List<SteeringPelotonNeighbor> neighbors,
    required DirectPlayerSteeringConfig config,
  }) {
    if (neighbors.isEmpty) {
      return PelotonGapScanResult(
        isLeftLaneOpen: lateralPositionRoad > -0.92,
        isRightLaneOpen: lateralPositionRoad < 0.92,
        leftGapWidthMeters: config.roadWidthMeters * 0.5,
        rightGapWidthMeters: config.roadWidthMeters * 0.5,
      );
    }

    final double halfRoad = config.roadWidthMeters * 0.5;
    final double playerX = lateralPositionRoad * halfRoad;
    final double minClearanceWidth = config.riderWidthMeters * 1.35;

    bool leftBlocked = lateralPositionRoad <= -0.95;
    bool rightBlocked = lateralPositionRoad >= 0.95;
    double leftGap = math.max(0.0, playerX + halfRoad);
    double rightGap = math.max(0.0, halfRoad - playerX);

    String? nearestAheadId;
    double? nearestAheadDist;

    for (final SteeringPelotonNeighbor neighbor in neighbors) {
      final double dx = neighbor.distanceAheadMeters;
      final double neighborX = neighbor.lateralPositionRoad * halfRoad;
      final double dy = neighborX - playerX;

      if (dx > 0.0 && dy.abs() < config.riderWidthMeters * 1.4) {
        if (nearestAheadDist == null || dx < nearestAheadDist) {
          nearestAheadDist = dx;
          nearestAheadId = neighbor.riderId;
        }
      }

      // Kolarz w sąsiednim pasie w strefie wyprzedzania [-1.5 m .. +4.5 m]
      if (dx >= -1.5 && dx <= 4.5) {
        if (dy < 0.0) {
          final double distToLeftRider = (-dy) - config.riderWidthMeters;
          if (distToLeftRider < leftGap) {
            leftGap = math.max(0.0, distToLeftRider);
          }
          if (distToLeftRider < minClearanceWidth &&
              dy.abs() < config.riderWidthMeters * 2.2) {
            leftBlocked = true;
          }
        } else if (dy > 0.0) {
          final double distToRightRider = dy - config.riderWidthMeters;
          if (distToRightRider < rightGap) {
            rightGap = math.max(0.0, distToRightRider);
          }
          if (distToRightRider < minClearanceWidth &&
              dy.abs() < config.riderWidthMeters * 2.2) {
            rightBlocked = true;
          }
        }
      }
    }

    double? recommendedOffset;
    if (!leftBlocked && (rightBlocked || leftGap >= rightGap)) {
      recommendedOffset = (lateralPositionRoad - 0.35).clamp(-1.0, 1.0);
    } else if (!rightBlocked) {
      recommendedOffset = (lateralPositionRoad + 0.35).clamp(-1.0, 1.0);
    }

    return PelotonGapScanResult(
      isLeftLaneOpen: !leftBlocked,
      isRightLaneOpen: !rightBlocked,
      leftGapWidthMeters: leftGap,
      rightGapWidthMeters: rightGap,
      nearestAheadRiderId: nearestAheadId,
      nearestAheadDistanceMeters: nearestAheadDist,
      recommendedGapLateralOffset: recommendedOffset,
    );
  }

  /// Wyszukuje najlepszego kolarza przed graczem do schowania się na jego kole (`Snap to Wheel`).
  static SnapToWheelTarget? findNearestWheelTarget({
    required double playerLateralPositionRoad,
    required List<SteeringPelotonNeighbor> neighbors,
    required DirectPlayerSteeringConfig config,
  }) {
    SteeringPelotonNeighbor? bestNeighbor;
    double bestScore = double.infinity;

    for (final SteeringPelotonNeighbor neighbor in neighbors) {
      if (neighbor.distanceAheadMeters < config.snapToWheelMinDistanceMeters ||
          neighbor.distanceAheadMeters > config.snapToWheelMaxDistanceMeters) {
        continue;
      }
      final double lateralDelta =
          (neighbor.lateralPositionRoad - playerLateralPositionRoad).abs();
      final double score =
          neighbor.distanceAheadMeters + (lateralDelta * 3.5);
      if (score < bestScore) {
        bestScore = score;
        bestNeighbor = neighbor;
      }
    }

    if (bestNeighbor == null) {
      return null;
    }

    return _buildSnapTarget(bestNeighbor);
  }

  static SnapToWheelTarget _buildSnapTarget(SteeringPelotonNeighbor neighbor) {
    final double distFactor =
        (1.0 - (neighbor.distanceAheadMeters / 14.0)).clamp(0.15, 1.0);
    final double draftSavings = (16.0 + distFactor * 26.0).clamp(16.0, 42.0);
    return SnapToWheelTarget(
      riderId: neighbor.riderId,
      riderName: neighbor.riderName,
      teamCode: neighbor.teamCode,
      distanceMeters: neighbor.distanceAheadMeters,
      lateralPositionRoad: neighbor.lateralPositionRoad,
      speedMs: neighbor.speedMs,
      estimatedDraftSavingsPercent: draftSavings,
    );
  }

  static SteeringPelotonNeighbor? _findNeighborById(
    List<SteeringPelotonNeighbor> neighbors,
    String riderId,
  ) {
    for (final SteeringPelotonNeighbor n in neighbors) {
      if (n.riderId == riderId) return n;
    }
    return null;
  }

  void _onEffortUpPressed() {
    final double nextEffort = (state.currentEffortPercent + 0.04).clamp(
      state.config.minEffortPercent,
      state.isSprinting
          ? state.config.sprintEffortPercent
          : state.config.maxSeatedEffortPercent,
    );
    final int nextGear = _gearForEffortAndSpeed(
      effortPercent: nextEffort,
      speedMs: state.currentSpeedMs,
      totalGears: state.config.totalGears,
      currentGear: math.min(state.config.totalGears, state.currentGearIndex + 1),
    );
    state = state.copyWith(
      inputSnapshot: state.inputSnapshot.copyWith(effortUpPressed: true),
      currentEffortPercent: nextEffort,
      preSprintEffortPercent:
          state.isSprinting ? state.preSprintEffortPercent : nextEffort,
      currentGearIndex: nextGear,
      statusFeedback:
          'Moc w górę: ${(nextEffort * 100).round()}% FTP (${DirectPlayerSteeringState.gearLabelForIndex(nextGear)})',
    );
  }

  void _onEffortDownPressed() {
    final double nextEffort = (state.currentEffortPercent - 0.04).clamp(
      state.config.minEffortPercent,
      state.isSprinting
          ? state.config.sprintEffortPercent
          : state.config.maxSeatedEffortPercent,
    );
    final int nextGear = _gearForEffortAndSpeed(
      effortPercent: nextEffort,
      speedMs: state.currentSpeedMs,
      totalGears: state.config.totalGears,
      currentGear: math.max(1, state.currentGearIndex - 1),
    );
    state = state.copyWith(
      inputSnapshot: state.inputSnapshot.copyWith(effortDownPressed: true),
      currentEffortPercent: nextEffort,
      preSprintEffortPercent:
          state.isSprinting ? state.preSprintEffortPercent : nextEffort,
      currentGearIndex: nextGear,
      statusFeedback:
          'Moc w dół: ${(nextEffort * 100).round()}% FTP (${DirectPlayerSteeringState.gearLabelForIndex(nextGear)})',
    );
  }

  void _onSteerLeftPressed() {
    state = state.copyWith(
      inputSnapshot: state.inputSnapshot.copyWith(steerLeftPressed: true),
      snapToWheelStatus: SnapToWheelStatus.idle,
      clearSnapTarget: true,
      statusFeedback: 'Szukanie luki po lewej stronie szosy',
    );
  }

  void _onSteerRightPressed() {
    state = state.copyWith(
      inputSnapshot: state.inputSnapshot.copyWith(steerRightPressed: true),
      snapToWheelStatus: SnapToWheelStatus.idle,
      clearSnapTarget: true,
      statusFeedback: 'Szukanie luki po prawej stronie szosy',
    );
  }

  static int _gearForEffortAndSpeed({
    required double effortPercent,
    required double speedMs,
    required int totalGears,
    required int currentGear,
  }) {
    final double speedNorm = ((speedMs - 4.0) / 14.0).clamp(0.0, 1.0);
    final double effortNorm = ((effortPercent - 0.30) / 1.30).clamp(0.0, 1.0);
    final int idealGear =
        (1 + ((speedNorm * 0.65 + effortNorm * 0.35) * (totalGears - 1)).round())
            .clamp(1, totalGears);
    if ((idealGear - currentGear).abs() <= 1) {
      return idealGear;
    }
    return (currentGear + (idealGear > currentGear ? 1 : -1))
        .clamp(1, totalGears);
  }
}

/// Globalny provider Riverpod dla bezpośredniego sterowania kolarzem w wyścigu 3D.
final directPlayerRiderSteeringProvider = StateNotifierProvider<
    DirectPlayerRiderSteeringController, DirectPlayerSteeringState>(
  (ref) => DirectPlayerRiderSteeringController(),
);

/// Produkcyjny panel HUD bezpośredniego sterowania pojedynczym kolarzem w wyścigu 3D.
///
/// Obsługuje skróty klawiszowe (`W/S` lub strzałki góra/dół, `A/D` lub lewo/prawo,
/// `Shift`, `Spacja`) oraz pełną responsywność `LayoutBuilder` (`390x844`, `1024x768`, `1600x900`)
/// wraz ze stanami `hover`, `active`, `disabled` i `focus`.
class DirectPlayerRiderSteeringHudPanel extends ConsumerStatefulWidget {
  final FocusNode? focusNode;
  final bool autofocus;

  const DirectPlayerRiderSteeringHudPanel({
    super.key,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  ConsumerState<DirectPlayerRiderSteeringHudPanel> createState() =>
      _DirectPlayerRiderSteeringHudPanelState();
}

class _DirectPlayerRiderSteeringHudPanelState
    extends ConsumerState<DirectPlayerRiderSteeringHudPanel> {
  late final FocusNode _internalFocusNode;
  bool _hasKeyboardFocus = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode(debugLabel: 'DirectPlayerSteeringFocus');
  }

  @override
  void dispose() {
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DirectPlayerSteeringState steering =
        ref.watch(directPlayerRiderSteeringProvider);
    final DirectPlayerRiderSteeringController controller =
        ref.read(directPlayerRiderSteeringProvider.notifier);

    return Focus(
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() {
          _hasKeyboardFocus = hasFocus;
        });
      },
      onKeyEvent: (node, event) {
        final bool handled = controller.handleKeyEvent(event);
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isCompactMobile = width < 600;
          final bool isTablet = width >= 600 && width < 1200;

          return GestureDetector(
            onTap: () => _effectiveFocusNode.requestFocus(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(isCompactMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasKeyboardFocus
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
                  width: _hasKeyboardFocus ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderRow(
                    steering: steering,
                    controller: controller,
                    isCompact: isCompactMobile,
                  ),
                  const SizedBox(height: 12),
                  _buildTelemetrySummary(
                    steering: steering,
                    isCompact: isCompactMobile,
                  ),
                  const SizedBox(height: 12),
                  _buildLateralLaneBar(steering: steering),
                  const SizedBox(height: 12),
                  if (isCompactMobile)
                    _buildCompactControls(steering, controller)
                  else
                    _buildDesktopTabletControls(
                      steering,
                      controller,
                      isTablet: isTablet,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow({
    required DirectPlayerSteeringState steering,
    required DirectPlayerRiderSteeringController controller,
    required bool isCompact,
  }) {
    final Color zoneColor = AppColors.getPowerZoneColor(steering.powerZone);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: steering.isControlEnabled
                    ? zoneColor
                    : AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isCompact
                    ? steering.controlledRiderName
                    : 'Sterowanie 3D • ${steering.controlledRiderName}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        _SteeringActionChipButton(
          label: steering.isControlEnabled ? 'Aktywne' : 'Wyłączone',
          icon: steering.isControlEnabled
              ? Icons.sports_motorsports_rounded
              : Icons.pause_circle_outline_rounded,
          isActive: steering.isControlEnabled,
          isDisabled: false,
          activeAccentColor: AppColors.statusSuccess,
          onPressed: () =>
              controller.setControlEnabled(!steering.isControlEnabled),
        ),
      ],
    );
  }

  Widget _buildTelemetrySummary({
    required DirectPlayerSteeringState steering,
    required bool isCompact,
  }) {
    final Color zoneColor = AppColors.getPowerZoneColor(steering.powerZone);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TelemetryBadge(
          label: 'MOC',
          value: '${steering.targetWatts} W',
          subValue:
              'Z${steering.powerZone} • ${(steering.currentEffortPercent * 100).round()}%',
          accentColor: zoneColor,
          compact: isCompact,
        ),
        _TelemetryBadge(
          label: 'BIEG',
          value: steering.gearLabel,
          subValue: steering.isStandingOnPedals ? 'Na stojąco' : 'Siedząc',
          accentColor: AppColors.goldAccent,
          compact: isCompact,
        ),
        _TelemetryBadge(
          label: 'SNAP',
          value: steering.snapToWheelStatus == SnapToWheelStatus.locked
              ? '-${steering.estimatedDraftSavingsPercent.round()}%'
              : steering.snapToWheelStatus.label,
          subValue: steering.snapTarget?.riderName ?? 'Brak celu',
          accentColor: AppColors.accentBlue,
          compact: isCompact,
        ),
      ],
    );
  }

  Widget _buildLateralLaneBar({required DirectPlayerSteeringState steering}) {
    final double normalized01 =
        ((steering.lateralPositionRoad + 1.0) * 0.5).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                steering.gapScan.isLeftLaneOpen
                    ? 'Luka L: ${steering.gapScan.leftGapWidthMeters.toStringAsFixed(1)}m'
                    : 'Lewo zablokowane',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: steering.gapScan.isLeftLaneOpen
                      ? AppColors.statusSuccess
                      : AppColors.crimsonAlert,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    steering.statusFeedback,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              Text(
                steering.gapScan.isRightLaneOpen
                    ? 'Luka P: ${steering.gapScan.rightGapWidthMeters.toStringAsFixed(1)}m'
                    : 'Prawo zablokowane',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: steering.gapScan.isRightLaneOpen
                      ? AppColors.statusSuccess
                      : AppColors.crimsonAlert,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, trackConstraints) {
              final double markerX =
                  (trackConstraints.maxWidth - 18) * normalized01;
              return Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      left: markerX,
                      top: 1,
                      child: Container(
                        width: 18,
                        height: 10,
                        decoration: BoxDecoration(
                          color: steering.isSprinting
                              ? AppColors.crimsonAlert
                              : AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactControls(
    DirectPlayerSteeringState steering,
    DirectPlayerRiderSteeringController controller,
  ) {
    final bool disabled = !steering.isControlEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _SteeringActionChipButton(
                label: 'A • Lewo',
                icon: Icons.arrow_back_rounded,
                isActive: steering.inputSnapshot.steerLeftPressed,
                isDisabled: disabled,
                onPressed: () => controller.nudgeLateral(-0.22),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SteeringActionChipButton(
                label: 'D • Prawo',
                icon: Icons.arrow_forward_rounded,
                isActive: steering.inputSnapshot.steerRightPressed,
                isDisabled: disabled,
                onPressed: () => controller.nudgeLateral(0.22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SteeringActionChipButton(
                label: 'S • Lżej',
                icon: Icons.arrow_downward_rounded,
                isActive: steering.inputSnapshot.effortDownPressed,
                isDisabled: disabled,
                onPressed: () => controller.stepEffortDown(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SteeringActionChipButton(
                label: 'W • Mocniej',
                icon: Icons.arrow_upward_rounded,
                isActive: steering.inputSnapshot.effortUpPressed,
                isDisabled: disabled,
                onPressed: () => controller.stepEffortUp(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SteeringActionChipButton(
                label: 'Shift • Sprint',
                icon: Icons.flash_on_rounded,
                isActive: steering.isSprinting,
                isDisabled: disabled,
                activeAccentColor: AppColors.crimsonAlert,
                onPressed: () =>
                    controller.setSprintEngaged(!steering.isSprinting),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SteeringActionChipButton(
                label: 'Spacja • Na koło',
                icon: Icons.my_location_rounded,
                isActive:
                    steering.snapToWheelStatus == SnapToWheelStatus.locked,
                isDisabled: disabled,
                activeAccentColor: AppColors.accentBlue,
                onPressed: () => controller.triggerSnapToWheel(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopTabletControls(
    DirectPlayerSteeringState steering,
    DirectPlayerRiderSteeringController controller, {
    required bool isTablet,
  }) {
    final bool disabled = !steering.isControlEnabled;
    return Wrap(
      spacing: isTablet ? 8 : 10,
      runSpacing: 8,
      children: [
        _SteeringActionChipButton(
          label: 'W / ↑ Moc+',
          icon: Icons.arrow_upward_rounded,
          isActive: steering.inputSnapshot.effortUpPressed,
          isDisabled: disabled,
          onPressed: () => controller.stepEffortUp(),
        ),
        _SteeringActionChipButton(
          label: 'S / ↓ Moc-',
          icon: Icons.arrow_downward_rounded,
          isActive: steering.inputSnapshot.effortDownPressed,
          isDisabled: disabled,
          onPressed: () => controller.stepEffortDown(),
        ),
        _SteeringActionChipButton(
          label: 'A / ← Lewo',
          icon: Icons.arrow_back_rounded,
          isActive: steering.inputSnapshot.steerLeftPressed,
          isDisabled: disabled,
          onPressed: () => controller.nudgeLateral(-0.22),
        ),
        _SteeringActionChipButton(
          label: 'D / → Prawo',
          icon: Icons.arrow_forward_rounded,
          isActive: steering.inputSnapshot.steerRightPressed,
          isDisabled: disabled,
          onPressed: () => controller.nudgeLateral(0.22),
        ),
        _SteeringActionChipButton(
          label: 'Shift • Sprint',
          icon: Icons.flash_on_rounded,
          isActive: steering.isSprinting,
          isDisabled: disabled,
          activeAccentColor: AppColors.crimsonAlert,
          onPressed: () => controller.setSprintEngaged(!steering.isSprinting),
        ),
        _SteeringActionChipButton(
          label: 'Spacja • Snap to Wheel',
          icon: Icons.my_location_rounded,
          isActive: steering.snapToWheelStatus == SnapToWheelStatus.locked,
          isDisabled: disabled,
          activeAccentColor: AppColors.accentBlue,
          onPressed: () => controller.triggerSnapToWheel(),
        ),
      ],
    );
  }
}

class _TelemetryBadge extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color accentColor;
  final bool compact;

  const _TelemetryBadge({
    required this.label,
    required this.value,
    required this.subValue,
    required this.accentColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 102 : 136),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            subValue,
            overflow: TextOverflow.ellipsis,
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

class _SteeringActionChipButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDisabled;
  final Color activeAccentColor;
  final VoidCallback onPressed;

  const _SteeringActionChipButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDisabled,
    required this.onPressed,
    this.activeAccentColor = AppColors.goldAccent,
  });

  @override
  State<_SteeringActionChipButton> createState() =>
      _SteeringActionChipButtonState();
}

class _SteeringActionChipButtonState extends State<_SteeringActionChipButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.isDisabled;
    final Color borderColor = disabled
        ? AppColors.cardBorder.withValues(alpha: 0.45)
        : widget.isActive
            ? widget.activeAccentColor
            : _isFocused
                ? AppColors.goldAccent
                : _isHovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    final Color backgroundColor = disabled
        ? AppColors.background.withValues(alpha: 0.6)
        : widget.isActive
            ? widget.activeAccentColor.withValues(alpha: 0.18)
            : _isPressed
                ? AppColors.primaryAccent.withValues(alpha: 0.25)
                : _isHovered
                    ? AppColors.surfaceLight
                    : AppColors.background;

    final Color foregroundColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isActive
            ? widget.activeAccentColor
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      mouseCursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel:
            disabled ? null : () => setState(() => _isPressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed && !disabled ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _isFocused || widget.isActive ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 16, color: foregroundColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                      letterSpacing: -0.2,
                    ),
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
