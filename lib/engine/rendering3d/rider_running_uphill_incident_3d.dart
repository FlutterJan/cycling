// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../core/theme/app_colors.dart';

// =============================================================================
// 1. ENUMERACJE I KONFIGURACJA INCYDENTU BIEGU POD GÓRĘ 3D
// =============================================================================

/// Przyczyna dramatycznego incydentu zmuszającego kolarza do biegu pod górę.
enum UphillRunningIncidentTrigger {
  /// Wóz telewizyjny lub motocykl TV zablokował wąski górski podjazd.
  tvVehicleBlocked(
    id: 'tv_vehicle_blocked',
    labelPl: 'Blokada wozu TV na podjeździe',
    shortLabelPl: 'Blokada TV',
    badgeCode: 'TV-BLOCK',
    accentColor: AppColors.amberWarning,
    icon: Icons.live_tv_rounded,
  ),

  /// Poważna kraksa na stromym podjeździe bez wolnego roweru technicznego w pobliżu.
  uphillCrashNoSpareBike(
    id: 'uphill_crash_no_spare_bike',
    labelPl: 'Kraksa na podjeździe (brak roweru)',
    shortLabelPl: 'Kraksa / brak roweru',
    badgeCode: 'NO-BIKE',
    accentColor: AppColors.crimsonAlert,
    icon: Icons.warning_amber_rounded,
  );

  final String id;
  final String labelPl;
  final String shortLabelPl;
  final String badgeCode;
  final Color accentColor;
  final IconData icon;

  const UphillRunningIncidentTrigger({
    required this.id,
    required this.labelPl,
    required this.shortLabelPl,
    required this.badgeCode,
    required this.accentColor,
    required this.icon,
  });

  String toJson() => name;

  static UphillRunningIncidentTrigger fromJson(String value) {
    return UphillRunningIncidentTrigger.values.firstWhere(
      (UphillRunningIncidentTrigger e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.id.toLowerCase() == value.toLowerCase(),
      orElse: () => UphillRunningIncidentTrigger.tvVehicleBlocked,
    );
  }
}

/// Fazy dramatycznej animacji biegu kolarza pod górę w butach kolarskich.
enum UphillRunningPhase {
  /// Gwałtowne hamowanie, wypięcie bloków i zeskoczenie z roweru na stromym asfalcie.
  emergencyStopAndDismount(
    durationSeconds: 1.6,
    labelPl: 'Zeskoczenie z roweru',
    radioCallPl: 'Uwaga! Blokada na podjeździe — kolarz wypina bloki i zeskakuje!',
    accentColor: AppColors.crimsonAlert,
  ),

  /// Porzucenie uszkodzonego roweru na poboczu i rozpaczliwy gest w stronę radia.
  abandonDamagedBike(
    durationSeconds: 1.2,
    labelPl: 'Porzucenie uszkodzonego roweru',
    radioCallPl: 'Rower uszkodzony! Zostawia maszynę na asfalcie i rusza biegiem!',
    accentColor: AppColors.amberWarning,
  ),

  /// Dramatyczny bieg pod górę w sztywnych karbonowych butach kolarskich.
  runningUphillInCleats(
    durationSeconds: 6.5,
    labelPl: 'Bieg pod górę w butach kolarskich',
    radioCallPl: 'Biegnie w sztywnych blokach po stromiźnie! Gdzie jest wóz drużynowy?!',
    accentColor: AppColors.goldAccent,
  ),

  /// Wóz drużynowy przebija się pod górę, mechanik zdejmuje zapasowy rower z dachu.
  teamCarApproachingWithRoofBike(
    durationSeconds: 2.8,
    labelPl: 'Zdejmowanie roweru z dachu wozu',
    radioCallPl: 'Wóz drużynowy nadjeżdża! Mechanik odpina zapasowy rower z dachu!',
    accentColor: AppColors.accentBlue,
  ),

  /// Przekazanie roweru zapasowego, wskoczenie w locie i potężne pchnięcie mechanika.
  spareBikeHandoverAndPushOff(
    durationSeconds: 2.2,
    labelPl: 'Przekazanie roweru i pchnięcie',
    radioCallPl: 'Zapasowy rower przekazany! Mocne pchnięcie i wraca w pościg!',
    accentColor: AppColors.statusSuccess,
  ),

  /// Incydent zakończony — kolarz wrócił na rower i kontynuuje wspinaczkę.
  resolved(
    durationSeconds: 0.0,
    labelPl: 'Powrót na trasę',
    radioCallPl: 'Kryzys zażegnany — kolarz ponownie jedzie na zapasowym rowerze.',
    accentColor: AppColors.statusSuccess,
  );

  final double durationSeconds;
  final String labelPl;
  final String radioCallPl;
  final Color accentColor;

  const UphillRunningPhase({
    required this.durationSeconds,
    required this.labelPl,
    required this.radioCallPl,
    required this.accentColor,
  });

  bool get isOngoing => this != UphillRunningPhase.resolved;

  bool get isOnFoot =>
      this == UphillRunningPhase.abandonDamagedBike ||
      this == UphillRunningPhase.runningUphillInCleats ||
      this == UphillRunningPhase.teamCarApproachingWithRoofBike;

  UphillRunningPhase get nextPhase {
    switch (this) {
      case UphillRunningPhase.emergencyStopAndDismount:
        return UphillRunningPhase.abandonDamagedBike;
      case UphillRunningPhase.abandonDamagedBike:
        return UphillRunningPhase.runningUphillInCleats;
      case UphillRunningPhase.runningUphillInCleats:
        return UphillRunningPhase.teamCarApproachingWithRoofBike;
      case UphillRunningPhase.teamCarApproachingWithRoofBike:
        return UphillRunningPhase.spareBikeHandoverAndPushOff;
      case UphillRunningPhase.spareBikeHandoverAndPushOff:
        return UphillRunningPhase.resolved;
      case UphillRunningPhase.resolved:
        return UphillRunningPhase.resolved;
    }
  }
}

/// Konfiguracja fizyczno-wizualna incydentu biegu pod górę.
@immutable
class RiderRunningUphillConfig {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String teamName;
  final Color jerseyColor;
  final Color helmetColor;
  final UphillRunningIncidentTrigger trigger;
  final double gradientPercent;
  final double initialDistanceMeters;
  final double initialTeamCarGapMeters;

  const RiderRunningUphillConfig({
    this.riderId = 'leader_01',
    this.riderName = 'C. FROOME',
    this.bibNumber = 1,
    this.teamName = 'TEAM SKYLINE',
    this.jerseyColor = AppColors.goldAccent,
    this.helmetColor = AppColors.textPrimary,
    this.trigger = UphillRunningIncidentTrigger.tvVehicleBlocked,
    this.gradientPercent = 10.5,
    this.initialDistanceMeters = 148200.0,
    this.initialTeamCarGapMeters = 46.0,
  });

  RiderRunningUphillConfig copyWith({
    String? riderId,
    String? riderName,
    int? bibNumber,
    String? teamName,
    Color? jerseyColor,
    Color? helmetColor,
    UphillRunningIncidentTrigger? trigger,
    double? gradientPercent,
    double? initialDistanceMeters,
    double? initialTeamCarGapMeters,
  }) {
    return RiderRunningUphillConfig(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      bibNumber: bibNumber ?? this.bibNumber,
      teamName: teamName ?? this.teamName,
      jerseyColor: jerseyColor ?? this.jerseyColor,
      helmetColor: helmetColor ?? this.helmetColor,
      trigger: trigger ?? this.trigger,
      gradientPercent: (gradientPercent ?? this.gradientPercent).clamp(4.0, 22.0),
      initialDistanceMeters: initialDistanceMeters ?? this.initialDistanceMeters,
      initialTeamCarGapMeters:
          (initialTeamCarGapMeters ?? this.initialTeamCarGapMeters).clamp(15.0, 120.0),
    );
  }
}

// =============================================================================
// 2. MODELE POZY 3D, ROWERU, WOZU TV ORAZ WOZU DRUŻYNOWEGO
// =============================================================================

/// Poza szkieletowa 3D kolarza biegnącego pod górę w sztywnych butach kolarskich.
@immutable
class RiderRunningPose3d {
  /// Środek miednicy względem lokalnego punktu styku z asfaltem [m].
  final vm.Vector3 pelvisOffset;

  /// Pochylenie tułowia do przodu [radiany] (większe na stromym podjeździe).
  final double torsoForwardLeanRad;

  /// Skręt barków i bioder w osi pionowej podczas biegu [radiany].
  final double torsoTwistRad;

  /// Kąt obrotu głowy w tył (oglądanie się za wozem technicznym) [0.0..1.0].
  final double glanceBackIntensity;

  /// Kąt zgięcia lewego/prawego biodra [radiany].
  final double leftHipPitchRad;
  final double rightHipPitchRad;

  /// Kąt zgięcia lewego/prawego kolana [radiany].
  final double leftKneeBendRad;
  final double rightKneeBendRad;

  /// Sztywne ustawienie stawu skokowego przez karbonową podeszwę buta [radiany].
  final double leftAnkleStiffnessRad;
  final double rightAnkleStiffnessRad;

  /// Kąt wymachu lewego/prawego ramienia [radiany].
  final double leftArmSwingRad;
  final double rightArmSwingRad;

  /// Uniesienie prawej dłoni do słuchawki radia wyścigowego / gest w stronę wozu [0.0..1.0].
  final double radioGestureIntensity;

  /// Chwilowy poślizg karbonowego bloku na asfalcie [0.0..1.0].
  final double cleatSlipIntensity;

  const RiderRunningPose3d({
    required this.pelvisOffset,
    required this.torsoForwardLeanRad,
    required this.torsoTwistRad,
    required this.glanceBackIntensity,
    required this.leftHipPitchRad,
    required this.rightHipPitchRad,
    required this.leftKneeBendRad,
    required this.rightKneeBendRad,
    required this.leftAnkleStiffnessRad,
    required this.rightAnkleStiffnessRad,
    required this.leftArmSwingRad,
    required this.rightArmSwingRad,
    required this.radioGestureIntensity,
    required this.cleatSlipIntensity,
  });
}

/// Stan porzuconego / uszkodzonego roweru na asfalcie.
@immutable
class DamagedBikeState3d {
  /// Pozycja 3D porzuconego roweru (x = poprzecznie, y = w górę, z = wzdłuż trasy).
  final vm.Vector3 worldPosition;

  /// Kąt położenia roweru na boku [radiany] (0 = stoi pionowo, ~1.42 = leży na asfalcie).
  final double tiltAngleRad;

  /// Obrót tylnego koła po upadku/zatrzymaniu [radiany].
  final double residualWheelSpinRad;

  /// Czy rower ma uszkodzone tylne koło / przekrzywiony widelec.
  final bool hasVisibleDamage;

  const DamagedBikeState3d({
    required this.worldPosition,
    required this.tiltAngleRad,
    required this.residualWheelSpinRad,
    required this.hasVisibleDamage,
  });
}

/// Stan wozu lub motocykla TV blokującego wąski podjazd.
@immutable
class TvBlockadeVehicleState3d {
  final bool isVisible;
  final vm.Vector3 worldPosition;
  final bool hazardLightsOn;
  final double cameraBoomYawRad;

  const TvBlockadeVehicleState3d({
    required this.isVisible,
    required this.worldPosition,
    required this.hazardLightsOn,
    required this.cameraBoomYawRad,
  });
}

/// Stan wozu drużynowego z zapasowym rowerem na dachu i mechanikiem.
@immutable
class TeamCarRoofRackState3d {
  final vm.Vector3 worldPosition;

  /// Dystans dzielący wóz od biegnącego kolarza [m].
  final double distanceBehindRunnerMeters;

  /// Postęp zdejmowania zapasowego roweru z dachu [0.0..1.0].
  final double roofBikeUnstrapProgress;

  /// Postęp przekazania roweru kolarzowi [0.0..1.0].
  final double handoverProgress;

  /// Czy świeci ostrzegawczy kogut na dachu wozu technicznego.
  final bool beaconActive;

  const TeamCarRoofRackState3d({
    required this.worldPosition,
    required this.distanceBehindRunnerMeters,
    required this.roofBikeUnstrapProgress,
    required this.handoverProgress,
    required this.beaconActive,
  });
}

/// Kompletna klatka symulacji 3D pojedynczego kroku incydentu.
@immutable
class RiderRunningUphillFrame3d {
  final UphillRunningIncidentTrigger trigger;
  final UphillRunningPhase phase;
  final double phaseProgress;
  final double totalProgress;
  final double elapsedSeconds;

  /// Prędkość biegu lub jazdy w tej klatce [m/s].
  final double currentSpeedMs;

  /// Kadencja kroków biegu [kroki/min] (0 jeśli jeszcze na rowerze).
  final double runningCadenceSpm;

  /// Przebyty dystans pieszo od momentu zeskoczenia z roweru [m].
  final double distanceRunMeters;

  /// Szacowana strata czasowa względem rywali jadących tempem podjazdowym [s].
  final double estimatedTimeLostSeconds;

  /// Szacowany czas dojazdu wozu drużynowego [s].
  final double teamCarEtaSeconds;

  /// Liczba wykrytych poślizgów karbonowych bloków na asfalcie.
  final int cleatSlipCount;

  final RiderRunningPose3d riderPose;
  final DamagedBikeState3d damagedBike;
  final TvBlockadeVehicleState3d tvBlockade;
  final TeamCarRoofRackState3d teamCar;

  const RiderRunningUphillFrame3d({
    required this.trigger,
    required this.phase,
    required this.phaseProgress,
    required this.totalProgress,
    required this.elapsedSeconds,
    required this.currentSpeedMs,
    required this.runningCadenceSpm,
    required this.distanceRunMeters,
    required this.estimatedTimeLostSeconds,
    required this.teamCarEtaSeconds,
    required this.cleatSlipCount,
    required this.riderPose,
    required this.damagedBike,
    required this.tvBlockade,
    required this.teamCar,
  });

  double get currentSpeedKmh => currentSpeedMs * 3.6;
}

// =============================================================================
// 3. SILNIK KINEMATYCZNY 3D: RiderRunningUphillIncident3d
// =============================================================================

/// Silnik 3D dramatycznej animacji awaryjnej biegu kolarza pod górę w butach kolarskich.
///
/// Obsługuje dwie sytuacje awaryjne:
/// - zablokowanie wąskiej drogi przez wóz/motocykl TV na podjeździe (styl Mont Ventoux),
/// - poważną kraksę na podjeździe przy braku wolnego roweru technicznego.
///
/// Generuje kinematykę 3D sztywnego biegu w karbonowych blokach, poślizgi podeszwy,
/// pozycję porzuconego roweru na asfalcie oraz animację nadjeżdżającego wozu drużynowego
/// ze zdejmowaniem zapasowego roweru z dachu.
class RiderRunningUphillIncident3d {
  RiderRunningUphillConfig _config;
  UphillRunningPhase _phase = UphillRunningPhase.emergencyStopAndDismount;
  double _phaseElapsedSeconds = 0.0;
  double _totalElapsedSeconds = 0.0;
  double _strideCycleRad = 0.0;
  double _distanceRunMeters = 0.0;
  double _timeLostSeconds = 0.0;
  double _teamCarGapMeters;
  int _cleatSlipCount = 0;
  bool _wasSlippingLastStep = false;

  static const double _totalAnimationDurationSeconds = 1.6 + 1.2 + 6.5 + 2.8 + 2.2;

  RiderRunningUphillIncident3d({
    RiderRunningUphillConfig config = const RiderRunningUphillConfig(),
  })  : _config = config,
        _teamCarGapMeters = config.initialTeamCarGapMeters;

  RiderRunningUphillConfig get config => _config;
  UphillRunningPhase get currentPhase => _phase;
  double get phaseElapsedSeconds => _phaseElapsedSeconds;
  double get totalElapsedSeconds => _totalElapsedSeconds;
  double get distanceRunMeters => _distanceRunMeters;
  double get estimatedTimeLostSeconds => _timeLostSeconds;
  int get cleatSlipCount => _cleatSlipCount;
  bool get isCompleted => _phase == UphillRunningPhase.resolved;

  /// Resetuje lub rozpoczyna nowy incydent z opcjonalną konfiguracją.
  void startIncident({RiderRunningUphillConfig? config}) {
    if (config != null) {
      _config = config;
    }
    _phase = UphillRunningPhase.emergencyStopAndDismount;
    _phaseElapsedSeconds = 0.0;
    _totalElapsedSeconds = 0.0;
    _strideCycleRad = 0.0;
    _distanceRunMeters = 0.0;
    _timeLostSeconds = 0.0;
    _teamCarGapMeters = _config.initialTeamCarGapMeters;
    _cleatSlipCount = 0;
    _wasSlippingLastStep = false;
  }

  /// Aktualizuje nachylenie podjazdu w locie [%].
  void setGradientPercent(double gradientPercent) {
    _config = _config.copyWith(gradientPercent: gradientPercent);
  }

  /// Zmienia typ przyczyny incydentu.
  void setTrigger(UphillRunningIncidentTrigger trigger) {
    _config = _config.copyWith(trigger: trigger);
  }

  /// Przeskakuje bezpośrednio do wskazanej fazy (przydatne do podglądu i testów).
  void jumpToPhase(UphillRunningPhase targetPhase) {
    _phase = targetPhase;
    _phaseElapsedSeconds = 0.0;

    switch (targetPhase) {
      case UphillRunningPhase.emergencyStopAndDismount:
        _totalElapsedSeconds = 0.0;
        _distanceRunMeters = 0.0;
        _teamCarGapMeters = _config.initialTeamCarGapMeters;
        break;
      case UphillRunningPhase.abandonDamagedBike:
        _totalElapsedSeconds = 1.6;
        _distanceRunMeters = 1.2;
        _teamCarGapMeters = _config.initialTeamCarGapMeters * 0.88;
        break;
      case UphillRunningPhase.runningUphillInCleats:
        _totalElapsedSeconds = 2.8;
        _distanceRunMeters = 4.0;
        _teamCarGapMeters = _config.initialTeamCarGapMeters * 0.72;
        break;
      case UphillRunningPhase.teamCarApproachingWithRoofBike:
        _totalElapsedSeconds = 9.3;
        _distanceRunMeters = 21.5;
        _teamCarGapMeters = 14.0;
        break;
      case UphillRunningPhase.spareBikeHandoverAndPushOff:
        _totalElapsedSeconds = 12.1;
        _distanceRunMeters = 26.5;
        _teamCarGapMeters = 2.4;
        break;
      case UphillRunningPhase.resolved:
        _totalElapsedSeconds = _totalAnimationDurationSeconds;
        _distanceRunMeters = 29.0;
        _teamCarGapMeters = 1.8;
        break;
    }
  }

  /// Wykonuje krok symulacji 3D o przyrost czasu [dtSeconds].
  RiderRunningUphillFrame3d step(double dtSeconds) {
    final double dt = dtSeconds.clamp(0.0, 0.25);
    if (dt > 0.0 && _phase.isOngoing) {
      _phaseElapsedSeconds += dt;
      _totalElapsedSeconds += dt;

      final double speedMs = _computeCurrentSpeedMs();
      if (_phase.isOnFoot) {
        _distanceRunMeters += speedMs * dt;
      }

      // Strata czasowa względem rywala wspinającego się ok. 5.6 m/s (~20 km/h)
      final double rivalClimbSpeedMs =
          (6.4 - (_config.gradientPercent - 8.0) * 0.14).clamp(3.8, 7.2);
      final double lostDelta =
          ((rivalClimbSpeedMs - speedMs) / rivalClimbSpeedMs).clamp(0.0, 1.0) * dt;
      _timeLostSeconds += lostDelta;

      // Wóz drużynowy nadrabia dystans podczas biegu
      if (_phase == UphillRunningPhase.emergencyStopAndDismount ||
          _phase == UphillRunningPhase.abandonDamagedBike) {
        _teamCarGapMeters = math.max(18.0, _teamCarGapMeters - 3.6 * dt);
      } else if (_phase == UphillRunningPhase.runningUphillInCleats) {
        _teamCarGapMeters = math.max(10.0, _teamCarGapMeters - 4.8 * dt);
      } else if (_phase == UphillRunningPhase.teamCarApproachingWithRoofBike) {
        _teamCarGapMeters = math.max(2.2, _teamCarGapMeters - 4.2 * dt);
      } else if (_phase == UphillRunningPhase.spareBikeHandoverAndPushOff) {
        _teamCarGapMeters = math.max(1.5, _teamCarGapMeters - 0.8 * dt);
      }

      // Cykl kroków biegu w butach kolarskich
      final double cadenceHz = _computeCadenceSpm() / 60.0;
      _strideCycleRad += cadenceHz * 2.0 * math.pi * dt;

      // Detekcja poślizgu karbonowych bloków
      final double slipValue = _computeCleatSlipIntensity();
      final bool isSlippingNow = slipValue > 0.65;
      if (isSlippingNow && !_wasSlippingLastStep) {
        _cleatSlipCount += 1;
      }
      _wasSlippingLastStep = isSlippingNow;

      // Przejście do kolejnej fazy po zakończeniu czasu fazy
      final double phaseDur = _phase.durationSeconds;
      if (phaseDur > 0.0 && _phaseElapsedSeconds >= phaseDur) {
        _phaseElapsedSeconds = 0.0;
        _phase = _phase.nextPhase;
      }
    }

    return computeFrame();
  }

  /// Oblicza aktualną klatkę 3D bez modyfikowania stanu wewnętrznego.
  RiderRunningUphillFrame3d computeFrame() {
    final double phaseDuration = _phase.durationSeconds;
    final double phaseProgress = phaseDuration > 0.0
        ? (_phaseElapsedSeconds / phaseDuration).clamp(0.0, 1.0)
        : 1.0;
    final double totalProgress =
        (_totalElapsedSeconds / _totalAnimationDurationSeconds).clamp(0.0, 1.0);

    final double speedMs = _computeCurrentSpeedMs();
    final double cadenceSpm = _computeCadenceSpm();
    final double slipIntensity = _computeCleatSlipIntensity();

    final RiderRunningPose3d pose = _buildPose3d(
      phaseProgress: phaseProgress,
      slipIntensity: slipIntensity,
    );

    final DamagedBikeState3d damagedBike = _buildDamagedBike3d(phaseProgress);
    final TvBlockadeVehicleState3d tvBlockade = _buildTvBlockade3d();
    final TeamCarRoofRackState3d teamCar = _buildTeamCar3d(phaseProgress);

    final double carEta = _phase == UphillRunningPhase.spareBikeHandoverAndPushOff ||
            _phase == UphillRunningPhase.resolved
        ? 0.0
        : (_teamCarGapMeters / 5.2).clamp(0.0, 25.0);

    return RiderRunningUphillFrame3d(
      trigger: _config.trigger,
      phase: _phase,
      phaseProgress: phaseProgress,
      totalProgress: totalProgress,
      elapsedSeconds: _totalElapsedSeconds,
      currentSpeedMs: speedMs,
      runningCadenceSpm: cadenceSpm,
      distanceRunMeters: _distanceRunMeters,
      estimatedTimeLostSeconds: _timeLostSeconds,
      teamCarEtaSeconds: carEta,
      cleatSlipCount: _cleatSlipCount,
      riderPose: pose,
      damagedBike: damagedBike,
      tvBlockade: tvBlockade,
      teamCar: teamCar,
    );
  }

  double _computeCurrentSpeedMs() {
    final double slopePenalty = ((_config.gradientPercent - 6.0) * 0.07).clamp(0.0, 0.9);
    switch (_phase) {
      case UphillRunningPhase.emergencyStopAndDismount:
        final double p =
            (_phaseElapsedSeconds / _phase.durationSeconds).clamp(0.0, 1.0);
        return (4.4 * (1.0 - p)).clamp(0.4, 4.4);
      case UphillRunningPhase.abandonDamagedBike:
        return (2.1 - slopePenalty * 0.4).clamp(1.4, 2.5);
      case UphillRunningPhase.runningUphillInCleats:
        // Bieg w karbonowych butach pod górę: ~2.6–3.3 m/s (9.3–11.8 km/h)
        final double surge = 0.22 * math.sin(_strideCycleRad * 0.5);
        return (3.15 - slopePenalty + surge).clamp(1.8, 3.5);
      case UphillRunningPhase.teamCarApproachingWithRoofBike:
        final double p =
            (_phaseElapsedSeconds / _phase.durationSeconds).clamp(0.0, 1.0);
        return (2.7 * (1.0 - p * 0.65) - slopePenalty * 0.4).clamp(0.9, 2.8);
      case UphillRunningPhase.spareBikeHandoverAndPushOff:
        final double p =
            (_phaseElapsedSeconds / _phase.durationSeconds).clamp(0.0, 1.0);
        return (1.2 + p * 4.4).clamp(1.2, 5.6);
      case UphillRunningPhase.resolved:
        return (5.8 - slopePenalty * 0.5).clamp(4.2, 6.2);
    }
  }

  double _computeCadenceSpm() {
    switch (_phase) {
      case UphillRunningPhase.emergencyStopAndDismount:
        return 42.0;
      case UphillRunningPhase.abandonDamagedBike:
        return 118.0;
      case UphillRunningPhase.runningUphillInCleats:
        return (152.0 - (_config.gradientPercent - 8.0) * 1.4).clamp(124.0, 162.0);
      case UphillRunningPhase.teamCarApproachingWithRoofBike:
        return 126.0;
      case UphillRunningPhase.spareBikeHandoverAndPushOff:
        return 68.0;
      case UphillRunningPhase.resolved:
        return 82.0;
    }
  }

  double _computeCleatSlipIntensity() {
    if (!_phase.isOnFoot) return 0.0;
    // Okresowe mikro-poślizgi sztywnej podeszwy na stromym asfalcie
    final double wave = math.sin(_strideCycleRad * 1.5 + 0.7);
    final double slopeFactor = (_config.gradientPercent / 14.0).clamp(0.5, 1.2);
    final double raw = (wave * slopeFactor - 0.35) / 0.65;
    return raw.clamp(0.0, 1.0);
  }

  RiderRunningPose3d _buildPose3d({
    required double phaseProgress,
    required double slipIntensity,
  }) {
    final double slopeRad = math.atan(_config.gradientPercent / 100.0);
    final double s = math.sin(_strideCycleRad);
    final double c = math.cos(_strideCycleRad);

    if (_phase == UphillRunningPhase.emergencyStopAndDismount) {
      final double dismountLean = 0.25 + phaseProgress * 0.32;
      return RiderRunningPose3d(
        pelvisOffset: vm.Vector3(phaseProgress * 0.22, 0.92 - phaseProgress * 0.08, 0.0),
        torsoForwardLeanRad: dismountLean + slopeRad * 0.4,
        torsoTwistRad: -0.22 * phaseProgress,
        glanceBackIntensity: 0.15,
        leftHipPitchRad: 0.45 - phaseProgress * 0.6,
        rightHipPitchRad: -0.25 + phaseProgress * 0.45,
        leftKneeBendRad: 0.75,
        rightKneeBendRad: 0.55,
        leftAnkleStiffnessRad: 0.18,
        rightAnkleStiffnessRad: 0.22,
        leftArmSwingRad: -0.45,
        rightArmSwingRad: -0.40,
        radioGestureIntensity: 0.0,
        cleatSlipIntensity: 0.1,
      );
    }

    if (_phase == UphillRunningPhase.spareBikeHandoverAndPushOff ||
        _phase == UphillRunningPhase.resolved) {
      final double remount = _phase == UphillRunningPhase.resolved ? 1.0 : phaseProgress;
      return RiderRunningPose3d(
        pelvisOffset: vm.Vector3(0.0, 0.94 + math.sin(remount * math.pi) * 0.05, 0.0),
        torsoForwardLeanRad: 0.42 + slopeRad * 0.5,
        torsoTwistRad: 0.05 * math.sin(remount * math.pi * 2.0),
        glanceBackIntensity: (1.0 - remount) * 0.2,
        leftHipPitchRad: 0.55 * math.sin(remount * math.pi * 2.0),
        rightHipPitchRad: -0.55 * math.sin(remount * math.pi * 2.0),
        leftKneeBendRad: 0.85,
        rightKneeBendRad: 0.65,
        leftAnkleStiffnessRad: 0.12,
        rightAnkleStiffnessRad: 0.12,
        leftArmSwingRad: -0.52,
        rightArmSwingRad: -0.52,
        radioGestureIntensity: 0.0,
        cleatSlipIntensity: 0.0,
      );
    }

    // Faza biegu w sztywnych butach kolarskich (sztywny chód na blokach + wymach ramion)
    final double bobY = 0.88 + 0.065 * c.abs() - slipIntensity * 0.04;
    final double waddleX = 0.045 * s;
    final double glanceBack = _phase == UphillRunningPhase.teamCarApproachingWithRoofBike
        ? 0.85
        : (0.5 + 0.5 * math.sin(_totalElapsedSeconds * 1.4)).clamp(0.0, 1.0) * 0.55;
    final double radioGesture = _phase == UphillRunningPhase.abandonDamagedBike
        ? 0.95
        : (_phase == UphillRunningPhase.runningUphillInCleats
            ? (0.5 + 0.5 * math.cos(_totalElapsedSeconds * 1.1)) * 0.65
            : 0.3);

    return RiderRunningPose3d(
      pelvisOffset: vm.Vector3(waddleX, bobY, 0.0),
      torsoForwardLeanRad: 0.34 + slopeRad * 0.75 + slipIntensity * 0.09,
      torsoTwistRad: 0.18 * s,
      glanceBackIntensity: glanceBack,
      leftHipPitchRad: 0.56 * s,
      rightHipPitchRad: -0.56 * s,
      leftKneeBendRad: (0.48 + 0.44 * math.max(0.0, -s)).clamp(0.2, 1.15),
      rightKneeBendRad: (0.48 + 0.44 * math.max(0.0, s)).clamp(0.2, 1.15),
      // Karbonowe podeszwy ograniczają zgięcie stopy!
      leftAnkleStiffnessRad: 0.24 + 0.08 * s,
      rightAnkleStiffnessRad: 0.24 - 0.08 * s,
      leftArmSwingRad: -0.75 * s,
      rightArmSwingRad: 0.75 * s * (1.0 - radioGesture * 0.6),
      radioGestureIntensity: radioGesture,
      cleatSlipIntensity: slipIntensity,
    );
  }

  DamagedBikeState3d _buildDamagedBike3d(double phaseProgress) {
    final double zBehindRunner = -_distanceRunMeters;
    double tilt = 0.15;
    if (_phase == UphillRunningPhase.emergencyStopAndDismount) {
      tilt = 0.15 + phaseProgress * 1.25;
    } else if (_phase != UphillRunningPhase.resolved) {
      tilt = 1.40; // Leży na asfalcie
    }

    final double wheelSpin = math.max(0.0, 18.0 - _totalElapsedSeconds * 4.5);

    return DamagedBikeState3d(
      worldPosition: vm.Vector3(-0.75, 0.0, zBehindRunner),
      tiltAngleRad: tilt,
      residualWheelSpinRad: wheelSpin,
      hasVisibleDamage: _config.trigger == UphillRunningIncidentTrigger.uphillCrashNoSpareBike ||
          _phase != UphillRunningPhase.emergencyStopAndDismount,
    );
  }

  TvBlockadeVehicleState3d _buildTvBlockade3d() {
    final bool isTv = _config.trigger == UphillRunningIncidentTrigger.tvVehicleBlocked;
    final double zAhead = math.max(2.5, 16.0 - _distanceRunMeters);
    return TvBlockadeVehicleState3d(
      isVisible: isTv,
      worldPosition: vm.Vector3(-0.35, 0.0, zAhead),
      hazardLightsOn: ((_totalElapsedSeconds * 2.5).floor() % 2) == 0,
      cameraBoomYawRad: 0.35 * math.sin(_totalElapsedSeconds * 1.3),
    );
  }

  TeamCarRoofRackState3d _buildTeamCar3d(double phaseProgress) {
    double unstrap = 0.0;
    double handover = 0.0;
    if (_phase == UphillRunningPhase.teamCarApproachingWithRoofBike) {
      unstrap = phaseProgress;
    } else if (_phase == UphillRunningPhase.spareBikeHandoverAndPushOff) {
      unstrap = 1.0;
      handover = phaseProgress;
    } else if (_phase == UphillRunningPhase.resolved) {
      unstrap = 1.0;
      handover = 1.0;
    }

    return TeamCarRoofRackState3d(
      worldPosition: vm.Vector3(0.85, 0.0, -_teamCarGapMeters),
      distanceBehindRunnerMeters: _teamCarGapMeters,
      roofBikeUnstrapProgress: unstrap,
      handoverProgress: handover,
      beaconActive: _phase.isOngoing,
    );
  }
}

// =============================================================================
// 4. STAN RIVERPOD DLA INCYDENTU BIEGU POD GÓRĘ 3D
// =============================================================================

@immutable
class RiderRunningUphillState {
  final RiderRunningUphillFrame3d frame;
  final RiderRunningUphillConfig config;
  final bool isPlaying;
  final double playbackSpeed;

  const RiderRunningUphillState({
    required this.frame,
    required this.config,
    required this.isPlaying,
    required this.playbackSpeed,
  });

  RiderRunningUphillState copyWith({
    RiderRunningUphillFrame3d? frame,
    RiderRunningUphillConfig? config,
    bool? isPlaying,
    double? playbackSpeed,
  }) {
    return RiderRunningUphillState(
      frame: frame ?? this.frame,
      config: config ?? this.config,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class RiderRunningUphillNotifier extends StateNotifier<RiderRunningUphillState> {
  final RiderRunningUphillIncident3d _engine;

  RiderRunningUphillNotifier({RiderRunningUphillIncident3d? engine})
      : _engine = engine ?? RiderRunningUphillIncident3d(),
        super(
          RiderRunningUphillState(
            frame: (engine ?? RiderRunningUphillIncident3d()).computeFrame(),
            config: (engine ?? RiderRunningUphillIncident3d()).config,
            isPlaying: true,
            playbackSpeed: 1.0,
          ),
        );

  void tick(double dtSeconds) {
    if (!state.isPlaying || _engine.isCompleted) return;
    final RiderRunningUphillFrame3d nextFrame =
        _engine.step(dtSeconds * state.playbackSpeed);
    state = state.copyWith(frame: nextFrame);
  }

  void togglePlaying() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void setPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed.clamp(0.25, 3.0));
  }

  void setTrigger(UphillRunningIncidentTrigger trigger) {
    _engine.setTrigger(trigger);
    _engine.startIncident(config: _engine.config);
    state = state.copyWith(
      config: _engine.config,
      frame: _engine.computeFrame(),
      isPlaying: true,
    );
  }

  void setGradientPercent(double gradientPercent) {
    _engine.setGradientPercent(gradientPercent);
    state = state.copyWith(
      config: _engine.config,
      frame: _engine.computeFrame(),
    );
  }

  void jumpToPhase(UphillRunningPhase phase) {
    _engine.jumpToPhase(phase);
    state = state.copyWith(frame: _engine.computeFrame());
  }

  void restartIncident() {
    _engine.startIncident();
    state = state.copyWith(
      frame: _engine.computeFrame(),
      isPlaying: true,
    );
  }
}

final riderRunningUphillIncidentProvider = StateNotifierProvider.autoDispose<
    RiderRunningUphillNotifier, RiderRunningUphillState>(
  (Ref ref) => RiderRunningUphillNotifier(),
);

// =============================================================================
// 5. RENDERER 3D NA CANVASIE (CustomPainter)
// =============================================================================

/// Rzutnik 3D renderujący dramatyczną scenę biegu kolarza pod górę na stromym podjeździe.
class RiderRunningUphill3dPainter extends CustomPainter {
  final RiderRunningUphillFrame3d frame;
  final RiderRunningUphillConfig config;

  const RiderRunningUphill3dPainter({
    required this.frame,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 4 || size.height <= 4) return;

    final double horizonY = size.height * 0.24;
    final double roadCenterX = size.width * 0.50;

    _paintSkyAndMountainRidge(canvas, size, horizonY);
    _paintUphillRoadAndChalkGraffiti(canvas, size, horizonY, roadCenterX);
    _paintSpectatorCorridor(canvas, size, horizonY, roadCenterX);

    if (frame.tvBlockade.isVisible) {
      _paintTvBlockadeVehicle(canvas, size, horizonY, roadCenterX);
    }

    _paintDamagedBikeOnTarmac(canvas, size, horizonY, roadCenterX);
    _paintTeamCarWithRoofRack(canvas, size, horizonY, roadCenterX);
    _paintArticulatedRunningRider(canvas, size, horizonY, roadCenterX);
    _paintBroadcastTelemetryHud(canvas, size);
  }

  Offset _projectRoadPoint(
    Size size,
    double horizonY,
    double roadCenterX,
    double xMeters,
    double yMeters,
    double zRelMeters,
  ) {
    // Rzut perspektywiczny podjazdu: dodatnie Z biegnie pod górę (ku horyzontowi)
    final double clampedZ = zRelMeters.clamp(-14.0, 28.0);
    final double depth = (12.0 + clampedZ).clamp(2.5, 40.0);
    final double perspective = 11.5 / depth;

    final double slopeLift = clampedZ * (config.gradientPercent * 0.008);
    final double screenX = roadCenterX + xMeters * perspective * (size.width * 0.055);
    final double baseRoadY =
        horizonY + (size.height - horizonY) * (0.68 - slopeLift * 0.35 + (1.0 - perspective) * -0.18);
    final double screenY =
        baseRoadY - yMeters * perspective * (size.height * 0.16);

    return Offset(screenX, screenY);
  }

  void _paintSkyAndMountainRidge(Canvas canvas, Size size, double horizonY) {
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF0A0D14),
          Color(0xFF151C28),
          Color(0xFF1F2636),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY + 30));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY + 30), skyPaint);

    // Księżycowy grzbiet górski w stylu Mont Ventoux
    final Path mountainPath = Path()
      ..moveTo(0, horizonY + 26)
      ..lineTo(size.width * 0.18, horizonY - 22)
      ..lineTo(size.width * 0.38, horizonY - 8)
      ..lineTo(size.width * 0.56, horizonY - 34)
      ..lineTo(size.width * 0.78, horizonY - 12)
      ..lineTo(size.width, horizonY + 18)
      ..lineTo(size.width, horizonY + 40)
      ..lineTo(0, horizonY + 40)
      ..close();

    canvas.drawPath(
      mountainPath,
      Paint()..color = const Color(0xFF232938),
    );
  }

  void _paintUphillRoadAndChalkGraffiti(
    Canvas canvas,
    Size size,
    double horizonY,
    double roadCenterX,
  ) {
    final Paint terrainPaint = Paint()..color = const Color(0xFF141820);
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      terrainPaint,
    );

    final Offset topLeft =
        _projectRoadPoint(size, horizonY, roadCenterX, -3.4, 0, 24.0);
    final Offset topRight =
        _projectRoadPoint(size, horizonY, roadCenterX, 3.4, 0, 24.0);
    final Offset botRight =
        _projectRoadPoint(size, horizonY, roadCenterX, 3.8, 0, -10.0);
    final Offset botLeft =
        _projectRoadPoint(size, horizonY, roadCenterX, -3.8, 0, -10.0);

    final Path roadPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(botRight.dx, botRight.dy)
      ..lineTo(botLeft.dx, botLeft.dy)
      ..close();

    canvas.drawPath(
      roadPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF242936), Color(0xFF1A1E28)],
        ).createShader(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY)),
    );

    // Przerywana oś jezdni przewijająca się z biegiem kolarza
    final double scroll = (frame.distanceRunMeters % 4.0);
    final Paint dashPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.45)
      ..strokeWidth = 2.0;

    for (double z = -8.0 - scroll; z < 22.0; z += 4.0) {
      final Offset p1 = _projectRoadPoint(size, horizonY, roadCenterX, 0.0, 0.0, z);
      final Offset p2 =
          _projectRoadPoint(size, horizonY, roadCenterX, 0.0, 0.0, z + 1.8);
      canvas.drawLine(p1, p2, dashPaint);
    }

    // Napis kredą na asfalcie ("ALLEZ!")
    final Offset chalkPos = _projectRoadPoint(
      size,
      horizonY,
      roadCenterX,
      -0.8,
      0.0,
      4.5 - (frame.distanceRunMeters % 10.0),
    );
    if (chalkPos.dy > horizonY && chalkPos.dy < size.height - 16) {
      final TextPainter chalkPainter = TextPainter(
        text: TextSpan(
          text: 'ALLEZ!',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: AppColors.textPrimary.withValues(alpha: 0.25),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      chalkPainter.paint(canvas, chalkPos);
    }
  }

  void _paintSpectatorCorridor(
    Canvas canvas,
    Size size,
    double horizonY,
    double roadCenterX,
  ) {
    final double scroll = frame.distanceRunMeters % 3.2;
    for (int i = 0; i < 8; i++) {
      final double z = -4.0 + i * 3.2 - scroll;
      for (final double side in <double>[-3.3, 3.3]) {
        final Offset p = _projectRoadPoint(size, horizonY, roadCenterX, side, 0, z);
        final double scale = (11.5 / (12.0 + z).clamp(3.0, 36.0)).clamp(0.35, 1.4);
        final Color fanColor = i.isEven ? AppColors.accentBlue : AppColors.primaryAccent;
        canvas.drawCircle(
          Offset(p.dx, p.dy - 14 * scale),
          4.2 * scale,
          Paint()..color = AppColors.textSecondary.withValues(alpha: 0.7),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(p.dx, p.dy - 6 * scale),
              width: 9 * scale,
              height: 14 * scale,
            ),
            Radius.circular(3 * scale),
          ),
          Paint()..color = fanColor.withValues(alpha: 0.55),
        );
      }
    }
  }

  void _paintTvBlockadeVehicle(
    Canvas canvas,
    Size size,
    double horizonY,
    double roadCenterX,
  ) {
    final vm.Vector3 pos = frame.tvBlockade.worldPosition;
    final Offset base =
        _projectRoadPoint(size, horizonY, roadCenterX, pos.x, pos.y, pos.z);
    final double scale =
        (11.5 / (12.0 + pos.z).clamp(4.0, 36.0)).clamp(0.45, 1.35);

    final Rect bodyRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - 22 * scale),
      width: 68 * scale,
      height: 36 * scale,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(6 * scale)),
      Paint()..color = const Color(0xFF2B3140),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(6 * scale)),
      Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Napis TV + migające światła awaryjne
    final TextPainter tvText = TextPainter(
      text: TextSpan(
        text: 'TV LIVE',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: (9 * scale).clamp(6.0, 12.0),
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tvText.paint(
      canvas,
      Offset(bodyRect.center.dx - tvText.width / 2, bodyRect.center.dy - 6 * scale),
    );

    if (frame.tvBlockade.hazardLightsOn) {
      final Paint hazardPaint = Paint()..color = AppColors.amberWarning;
      canvas.drawCircle(
        Offset(bodyRect.left + 8 * scale, bodyRect.bottom - 7 * scale),
        4 * scale,
        hazardPaint,
      );
      canvas.drawCircle(
        Offset(bodyRect.right - 8 * scale, bodyRect.bottom - 7 * scale),
        4 * scale,
        hazardPaint,
      );
    }
  }

  void _paintDamagedBikeOnTarmac(
    Canvas canvas,
    Size size,
    double horizonY,
    double roadCenterX,
  ) {
    final vm.Vector3 pos = frame.damagedBike.worldPosition;
    final Offset bikePos =
        _projectRoadPoint(size, horizonY, roadCenterX, pos.x, pos.y, pos.z);
    if (bikePos.dy > size.height + 24) return;

    final double scale =
        (11.5 / (12.0 + pos.z).clamp(3.0, 36.0)).clamp(0.4, 1.35);

    canvas.save();
    canvas.translate(bikePos.dx, bikePos.dy);
    canvas.rotate(frame.damagedBike.tiltAngleRad * 0.45);

    final Paint framePaint = Paint()
      ..color = config.jerseyColor
      ..strokeWidth = 2.6 * scale
      ..strokeCap = StrokeCap.round;

    final Paint wheelPaint = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;

    canvas.drawCircle(Offset(-14 * scale, -8 * scale), 8 * scale, wheelPaint);
    canvas.drawCircle(Offset(14 * scale, -8 * scale), 8 * scale, wheelPaint);
    canvas.drawLine(
      Offset(-14 * scale, -8 * scale),
      Offset(2 * scale, -18 * scale),
      framePaint,
    );
    canvas.drawLine(
      Offset(2 * scale, -18 * scale),
      Offset(14 * scale, -8 * scale),
      framePaint,
    );
    canvas.restore();
  }

  void _paintTeamCarWithRoofRack(
    Canvas canvas,
    Size size,
    double horizonY,
    double roadCenterX,
  ) {
    final TeamCarRoofRackState3d car = frame.teamCar;
    // Jeśli wóz jest daleko za plecami, rysujemy kompaktowy wskaźnik najazdu u dołu prawego pasa
    final double clampedZ = car.worldPosition.z.clamp(-10.5, 4.0);
    final Offset base = _projectRoadPoint(
      size,
      horizonY,
      roadCenterX,
      car.worldPosition.x,
      0.0,
      clampedZ,
    );

    final double scale =
        (11.5 / (12.0 + clampedZ).clamp(3.0, 36.0)).clamp(0.55, 1.25);

    final Rect carRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - 14 * scale),
      width: 56 * scale,
      height: 26 * scale,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(carRect, Radius.circular(6 * scale)),
      Paint()..color = AppColors.surfaceLight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(carRect, Radius.circular(6 * scale)),
      Paint()
        ..color = AppColors.accentBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Zapasowy rower na dachu wozu (podnoszony w miarę zdejmowania z dachu)
    final double roofLift = car.roofBikeUnstrapProgress * 10 * scale;
    final Paint spareBikePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 2.0 * scale;
    canvas.drawLine(
      Offset(carRect.left + 10 * scale, carRect.top - 4 * scale - roofLift),
      Offset(carRect.right - 10 * scale, carRect.top - 4 * scale - roofLift),
      spareBikePaint,
    );

    if (car.beaconActive) {
      canvas.drawCircle(
        Offset(carRect.center.dx, carRect.top - 2 * scale),
        3.5 * scale,
        Paint()..color = AppColors.amberWarning,
      );
    }
  }

  void _paintArticulatedRunningRider(
    Canvas canvas,
    Size size,
    double horizonY,
    double roadCenterX,
  ) {
    final RiderRunningPose3d pose = frame.riderPose;
    final Offset footBase = _projectRoadPoint(
      size,
      horizonY,
      roadCenterX,
      pose.pelvisOffset.x,
      0.0,
      0.0,
    );

    const double scale = 1.15;
    final Offset pelvis = Offset(
      footBase.dx,
      footBase.dy - pose.pelvisOffset.y * 54.0 * scale,
    );

    // Cień na asfalcie
    canvas.drawOval(
      Rect.fromCenter(center: footBase, width: 34 * scale, height: 10 * scale),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Tułów pochylony pod górę
    final Offset shoulder = Offset(
      pelvis.dx + math.sin(pose.torsoForwardLeanRad) * 28 * scale,
      pelvis.dy - math.cos(pose.torsoForwardLeanRad) * 28 * scale,
    );

    // Nogi i sztywne buty kolarskie (lewa i prawa)
    _paintLegAndCleatShoe(
      canvas,
      pelvis,
      pose.leftHipPitchRad,
      pose.leftKneeBendRad,
      pose.leftAnkleStiffnessRad,
      scale,
      AppColors.surfaceLight,
    );
    _paintLegAndCleatShoe(
      canvas,
      pelvis,
      pose.rightHipPitchRad,
      pose.rightKneeBendRad,
      pose.rightAnkleStiffnessRad,
      scale,
      AppColors.textPrimary,
    );

    // Koszulka lidera / drużyny
    final Paint torsoPaint = Paint()
      ..color = config.jerseyColor
      ..strokeWidth = 9.5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pelvis, shoulder, torsoPaint);

    // Ramiona (wymach + gest do radia)
    final Paint armPaint = Paint()
      ..color = config.jerseyColor.withValues(alpha: 0.9)
      ..strokeWidth = 4.5 * scale
      ..strokeCap = StrokeCap.round;

    final Offset leftHand = Offset(
      shoulder.dx + math.sin(pose.leftArmSwingRad) * 20 * scale,
      shoulder.dy + math.cos(pose.leftArmSwingRad) * 20 * scale,
    );
    final Offset rightHand = pose.radioGestureIntensity > 0.6
        ? Offset(shoulder.dx + 6 * scale, shoulder.dy - 10 * scale)
        : Offset(
            shoulder.dx + math.sin(pose.rightArmSwingRad) * 20 * scale,
            shoulder.dy + math.cos(pose.rightArmSwingRad) * 20 * scale,
          );
    canvas.drawLine(shoulder, leftHand, armPaint);
    canvas.drawLine(shoulder, rightHand, armPaint);

    // Kask kolarski + gogle
    final Offset headCenter = Offset(
      shoulder.dx + 4 * scale - pose.glanceBackIntensity * 3 * scale,
      shoulder.dy - 11 * scale,
    );
    canvas.drawCircle(
      headCenter,
      7.5 * scale,
      Paint()..color = config.helmetColor,
    );
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: 7.5 * scale),
      -0.2,
      1.1,
      false,
      Paint()
        ..color = AppColors.cyanAccent
        ..strokeWidth = 2.2 * scale
        ..style = PaintingStyle.stroke,
    );

    // Efekt poślizgu karbonowych bloków na asfalcie
    if (pose.cleatSlipIntensity > 0.55) {
      canvas.drawCircle(
        Offset(footBase.dx - 10, footBase.dy - 3),
        3.5 * pose.cleatSlipIntensity,
        Paint()..color = AppColors.amberWarning.withValues(alpha: 0.75),
      );
    }
  }

  void _paintLegAndCleatShoe(
    Canvas canvas,
    Offset pelvis,
    double hipPitch,
    double kneeBend,
    double ankleStiffness,
    double scale,
    Color shoeColor,
  ) {
    final Offset knee = Offset(
      pelvis.dx + math.sin(hipPitch) * 24 * scale,
      pelvis.dy + math.cos(hipPitch) * 24 * scale,
    );
    final Offset ankle = Offset(
      knee.dx + math.sin(hipPitch - kneeBend) * 22 * scale,
      knee.dy + math.cos(hipPitch - kneeBend) * 22 * scale,
    );
    final Offset shoeTip = Offset(
      ankle.dx + math.cos(ankleStiffness) * 10 * scale,
      ankle.dy + math.sin(ankleStiffness) * 5 * scale,
    );

    canvas.drawLine(
      pelvis,
      knee,
      Paint()
        ..color = const Color(0xFF1E222D)
        ..strokeWidth = 5.5 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      knee,
      ankle,
      Paint()
        ..color = const Color(0xFFD6A88D)
        ..strokeWidth = 4.2 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      ankle,
      shoeTip,
      Paint()
        ..color = shoeColor
        ..strokeWidth = 5.0 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintBroadcastTelemetryHud(Canvas canvas, Size size) {
    final TextPainter badgePainter = TextPainter(
      text: TextSpan(
        text:
            '${frame.trigger.badgeCode}  •  ${frame.phase.labelPl.toUpperCase()}  •  ${config.gradientPercent.toStringAsFixed(1)}%',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: frame.phase.accentColor,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);

    final RRect pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, badgePainter.width + 18, 26),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      pill,
      Paint()..color = AppColors.background.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      pill,
      Paint()
        ..color = frame.phase.accentColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    badgePainter.paint(canvas, const Offset(21, 18));
  }

  @override
  bool shouldRepaint(covariant RiderRunningUphill3dPainter oldDelegate) {
    return oldDelegate.frame != frame || oldDelegate.config != config;
  }
}

// =============================================================================
// 6. PRODUKCYJNY WIDGET PANELU STEROWANIA I PODGLĄDU 3D
// =============================================================================

/// Interaktywny panel podglądu i sterowania dramatyczną animacją 3D `RiderRunningUphillIncident3d`.
///
/// W pełni responsywny (`LayoutBuilder`: 390x844, 1024x768, 1600x900), zgodny z paletą
/// `AppColors` i typografią `Inter`, z kompletnymi stanami `hover` / `active` / `disabled` / `focus`.
class RiderRunningUphillIncident3dPanel extends ConsumerStatefulWidget {
  /// Czy automatycznie uruchamiać tykanie klatki po zamontowaniu widgetu.
  final bool autoPlay;

  const RiderRunningUphillIncident3dPanel({
    super.key,
    this.autoPlay = true,
  });

  @override
  ConsumerState<RiderRunningUphillIncident3dPanel> createState() =>
      _RiderRunningUphillIncident3dPanelState();
}

class _RiderRunningUphillIncident3dPanelState
    extends ConsumerState<RiderRunningUphillIncident3dPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickerController;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onAnimationTick);

    if (widget.autoPlay) {
      _tickerController.repeat();
    }
  }

  void _onAnimationTick() {
    final Duration? current = _tickerController.lastElapsedDuration;
    if (current == null) return;
    final double dt =
        (current - _lastElapsed).inMicroseconds / Duration.microsecondsPerSecond;
    _lastElapsed = current;
    if (dt > 0.0 && dt < 0.5) {
      ref.read(riderRunningUphillIncidentProvider.notifier).tick(dt);
    }
  }

  @override
  void dispose() {
    _tickerController.removeListener(_onAnimationTick);
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RiderRunningUphillState simState =
        ref.watch(riderRunningUphillIncidentProvider);
    final RiderRunningUphillNotifier notifier =
        ref.read(riderRunningUphillIncidentProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isCompact = constraints.maxWidth < 680;
          final bool isWide = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(simState, isCompact),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: _buildViewportCard(simState, height: 320),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: <Widget>[
                            _buildTelemetryCard(simState),
                            const SizedBox(height: 12),
                            _buildControlsCard(simState, notifier, isCompact),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  _buildViewportCard(simState, height: isCompact ? 220 : 280),
                  const SizedBox(height: 12),
                  _buildTelemetryCard(simState),
                  const SizedBox(height: 12),
                  _buildControlsCard(simState, notifier, isCompact),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(RiderRunningUphillState simState, bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: simState.frame.phase.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: simState.frame.phase.accentColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  simState.frame.trigger.icon,
                  color: simState.frame.phase.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'INCYDENT 3D: BIEG POD GÓRĘ (${simState.config.riderName})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      simState.frame.phase.radioCallPl,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2F3D)),
            ),
            child: Text(
              'ETAP ${(simState.frame.totalProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewportCard(
    RiderRunningUphillState simState, {
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: RiderRunningUphill3dPainter(
          frame: simState.frame,
          config: simState.config,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildTelemetryCard(RiderRunningUphillState simState) {
    final RiderRunningUphillFrame3d f = simState.frame;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          _MetricTile(
            label: 'Prędkość',
            value: '${f.currentSpeedKmh.toStringAsFixed(1)} km/h',
            accent: AppColors.cyanAccent,
          ),
          _MetricTile(
            label: 'Kadencja biegu',
            value: '${f.runningCadenceSpm.toStringAsFixed(0)} spm',
            accent: AppColors.goldAccent,
          ),
          _MetricTile(
            label: 'Dystans pieszo',
            value: '${f.distanceRunMeters.toStringAsFixed(1)} m',
            accent: AppColors.accentBlue,
          ),
          _MetricTile(
            label: 'Strata czasowa',
            value: '+${f.estimatedTimeLostSeconds.toStringAsFixed(1)} s',
            accent: AppColors.crimsonAlert,
          ),
          _MetricTile(
            label: 'ETA wozu tech.',
            value: '${f.teamCarEtaSeconds.toStringAsFixed(1)} s',
            accent: AppColors.statusSuccess,
          ),
          _MetricTile(
            label: 'Poślizgi bloków',
            value: '${f.cleatSlipCount}',
            accent: AppColors.amberWarning,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsCard(
    RiderRunningUphillState simState,
    RiderRunningUphillNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'SCENARIUSZ I STEROWANIE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UphillRunningIncidentTrigger.values
                .map((UphillRunningIncidentTrigger trigger) {
              return _InteractiveActionChip(
                label: trigger.shortLabelPl,
                icon: trigger.icon,
                isActive: simState.config.trigger == trigger,
                accentColor: trigger.accentColor,
                onPressed: () => notifier.setTrigger(trigger),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InteractiveActionChip(
                label: simState.isPlaying ? 'Pauza' : 'Odtwarzaj',
                icon: simState.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                isActive: simState.isPlaying,
                isDisabled: simState.frame.phase == UphillRunningPhase.resolved,
                accentColor: AppColors.statusSuccess,
                onPressed: notifier.togglePlaying,
              ),
              _InteractiveActionChip(
                label: 'Restart',
                icon: Icons.replay_rounded,
                isActive: false,
                accentColor: AppColors.goldAccent,
                onPressed: notifier.restartIncident,
              ),
              _InteractiveActionChip(
                label: 'Następna faza',
                icon: Icons.skip_next_rounded,
                isActive: false,
                isDisabled: simState.frame.phase == UphillRunningPhase.resolved,
                accentColor: AppColors.accentBlue,
                onPressed: () =>
                    notifier.jumpToPhase(simState.frame.phase.nextPhase),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Text(
                'Nachylenie:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: simState.config.gradientPercent,
                  min: 4.0,
                  max: 20.0,
                  divisions: 16,
                  activeColor: AppColors.primaryAccent,
                  inactiveColor: AppColors.surfaceLight,
                  onChanged: notifier.setGradientPercent,
                ),
              ),
              Text(
                '${simState.config.gradientPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
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
              color: accent,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractiveActionChip({
    required this.label,
    required this.icon,
    required this.isActive,
    this.isDisabled = false,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.isDisabled;
    final Color borderColor = !enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.45)
        : (widget.isActive || _isFocused
            ? widget.accentColor
            : (_isHovered
                ? widget.accentColor.withValues(alpha: 0.65)
                : const Color(0xFF2A2F3D)));

    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (widget.isActive
            ? widget.accentColor.withValues(alpha: 0.18)
            : (_isHovered ? AppColors.surfaceLight : AppColors.background));

    final Color fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : (widget.isActive ? widget.accentColor : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool hovered) {
        if (mounted) setState(() => _isHovered = hovered);
      },
      onShowFocusHighlight: (bool focused) {
        if (mounted) setState(() => _isFocused = focused);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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
