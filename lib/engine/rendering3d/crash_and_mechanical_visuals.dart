// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../engine/events/race_incident_engine.dart';
import '../../models/race/stage_segment.dart';
import '../../state/race_simulation_notifier.dart';
import 'peloton_instanced_renderer.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. ENUMERACJE I STANY FAZ AWARII ORAZ KRAKS
// =============================================================================

/// Fazy animacji awarii mechanicznej / przebicia opony (Puncture & Mechanical Swap).
enum MechanicalIncidentPhase {
  /// Kolarz sygnalizuje defekt: unosi rękę w górę, zaczyna zjeżdżać w stronę pobocza.
  signalingAndDriftingToVerge(2.8),

  /// Kolarz zatrzymuje się na poboczu, wypina buta z pedału i oczekuje na wóz techniczny.
  awaitingServiceAtVerge(3.5),

  /// Wóz techniczny hamuje za kolarzem, z auta wyskakuje mechanik z kołem zapasowym.
  mechanicRunningWithWheel(2.2),

  /// Mechanik klęka przy rowerze i wykonuje ekspresową wymianę koła (Thru-Axle Swap).
  mechanicReplacingWheel(4.5),

  /// Mechanik daje kolarzowi potężne pchnięcie (Push-off), kolarz wpina bloki i przyspiesza.
  pushOffAndAcceleration(3.0),

  /// Zakończenie obsługi serwisowej – powrót do normalnej jazdy w peletonie/pościgu.
  resolved(0.0);

  final double defaultDurationSeconds;
  const MechanicalIncidentPhase(this.defaultDurationSeconds);

  bool get isOngoing => this != MechanicalIncidentPhase.resolved;

  bool get isMechanicActive =>
      this == MechanicalIncidentPhase.mechanicRunningWithWheel ||
      this == MechanicalIncidentPhase.mechanicReplacingWheel ||
      this == MechanicalIncidentPhase.pushOffAndAcceleration;
}

/// Fazy animacji kraksy kolarza lub karambolu w peletonie (Crash & Recovery).
enum CrashIncidentPhase {
  /// Moment upadku: poślizg kolarza i roweru po asfalcie z rotacją.
  tumbleAndSlide(1.8),

  /// Kolarz leży na asfalcie, dochodzi do siebie po wstrząsie, bidony toczą się po szosie.
  lyingOnTarmac(3.5),

  /// Kolarz podnosi się na kolana, wstaje i podchodzi do leżącego roweru.
  standingAndInspectingBike(3.2),

  /// Kolarz prostuje klamkomanetkę, zakłada spadnięty łańcuch na tarczę korby.
  adjustingHandlebarAndChain(2.8),

  /// Wsiadanie na rower (przełożenie nogi przez siodełko) i pierwsze powolne obroty korby.
  remountingAndStartingSlow(2.5),

  /// Powolne rozpędzanie się po wznowieniu jazdy (rozmasowywanie barku, pościg za grupą).
  slowAcceleration(4.5),

  /// Kolarz osiągnął prędkość roboczą i kontynuuje wyścig.
  resolved(0.0);

  final double defaultDurationSeconds;
  const CrashIncidentPhase(this.defaultDurationSeconds);

  bool get isOngoing => this != CrashIncidentPhase.resolved;

  bool get isDownOnTarmac =>
      this == CrashIncidentPhase.tumbleAndSlide ||
      this == CrashIncidentPhase.lyingOnTarmac;

  bool get isRecovering =>
      this == CrashIncidentPhase.standingAndInspectingBike ||
      this == CrashIncidentPhase.adjustingHandlebarAndChain ||
      this == CrashIncidentPhase.remountingAndStartingSlow;
}

// =============================================================================
// 2. MODELE AKTYWNYCH INCYDENTÓW W CZASIE RZECZYWISTYM
// =============================================================================

/// Aktywny incydent defektu kolarza (przebita dętka, zerwany łańcuch).
class ActiveMechanicalIncident {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String teamId;
  final String teamName;
  final String teamColorHex;
  final IncidentType defectType;

  MechanicalIncidentPhase phase;
  double phaseElapsedSeconds;
  double totalProgress; // 0.0 - 1.0

  /// Koordynaty miejsca wystąpienia defektu na trasie
  double incidentDistanceMeters;
  double currentLateralOffsetMeters;
  double targetVergeLateralOffset; // -3.6m (lewe pobocze) lub +3.6m (prawe)
  double currentSpeedMs;

  ActiveMechanicalIncident({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.teamId,
    required this.teamName,
    required this.teamColorHex,
    required this.defectType,
    this.phase = MechanicalIncidentPhase.signalingAndDriftingToVerge,
    this.phaseElapsedSeconds = 0.0,
    this.totalProgress = 0.0,
    required this.incidentDistanceMeters,
    required this.currentLateralOffsetMeters,
    this.targetVergeLateralOffset = 3.6,
    this.currentSpeedMs = 12.0,
  });
}

/// Aktywny incydent kraksy kolarza lub zwału w peletonie.
class ActiveCrashIncident {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String teamId;
  final String teamName;
  final String teamColorHex;
  final IncidentType crashType;

  CrashIncidentPhase phase;
  double phaseElapsedSeconds;
  double totalProgress; // 0.0 - 1.0

  /// Koordynaty miejsca kraksy na trasie
  double crashDistanceMeters;
  double lateralOffsetMeters;
  double slideDistanceMeters;
  double currentSpeedMs;
  double bikeRotationAngle; // Kąt obrotu leżącego roweru [rad]

  ActiveCrashIncident({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.teamId,
    required this.teamName,
    required this.teamColorHex,
    required this.crashType,
    this.phase = CrashIncidentPhase.tumbleAndSlide,
    this.phaseElapsedSeconds = 0.0,
    this.totalProgress = 0.0,
    required this.crashDistanceMeters,
    required this.lateralOffsetMeters,
    this.slideDistanceMeters = 0.0,
    this.currentSpeedMs = 12.5,
    this.bikeRotationAngle = 0.85,
  });
}

// =============================================================================
// 3. KONFIGURACJA MODUŁU WIZUALIZACJI ZDARZEŃ LOSOWYCH
// =============================================================================

/// Konfiguracja parametrów wizualizacji kraks i defektów w 3D.
class CrashAndMechanicalConfig {
  /// Czy wizualizacja zdarzeń losowych w 3D jest włączona.
  final bool enabled;

  /// Czy włączać podjazd wozu technicznego i animację mechanika z kołem.
  final bool enableTeamCarAndMechanic;

  /// Czy renderować toczące się bidony po asfalcie podczas kraksy.
  final bool enableRollingBidons;

  /// Czy renderować żółte flagi ostrzegawcze sędziów w strefie kraksy.
  final bool enableWarningFlags;

  /// Mnożnik tempa trwania animacji wymiany koła (1.0 = standardowe ok. 15s).
  final double animationSpeedMultiplier;

  /// Szerokość zjazdu na pobocze w metrach [m].
  final double roadVergeOffsetMeters;

  const CrashAndMechanicalConfig({
    this.enabled = true,
    this.enableTeamCarAndMechanic = true,
    this.enableRollingBidons = true,
    this.enableWarningFlags = true,
    this.animationSpeedMultiplier = 1.0,
    this.roadVergeOffsetMeters = 3.6,
  });
}

// =============================================================================
// 4. GŁÓWNY MODUŁ WIZUALIZUJĄCY KRAKSY I DEFEKTY (120 FPS ZERO-GC)
// =============================================================================

/// Zaawansowany silnik wizualizujący w przestrzeni trójwymiarowej zdarzenia losowe:
/// 1. **Defekt i przebicie opony**:
///    - Kolarz zjeżdża na bok szosy, unosi rękę w górę w geście wezwania pomocy,
///    - Zatrzymuje się na poboczu, wypina nogę z bloku pedału,
///    - Zza peletonu nadjeżdża wóz techniczny z migającymi kogutami i gwałtownie hamuje,
///    - Mechanik z zapasowym kołem karbonowym wyskakuje z auta, klęka przy widelcu,
///      wymienia koło, po czym daje kolarzowi potężne pchnięcie (Push-off).
/// 2. **Kraksa kolarza i kraksa zbiorowa**:
///    - Efekt poślizgu roweru i kolarza po asfalcie,
///    - Zwolnienie kolarzy jadących z tyłu (spowolnienie peletonu),
///    - Kolarze leżący na asfalcie, zbierający się z kolan, podnoszący rowery,
///    - Nastawianie wygiętej klamkomanetki i nakładanie łańcucha,
///    - Powolne rozpędzanie się po wznowieniu jazdy i pogoń za peletonem,
///    - Rozrzucone bidony toczące się po szosie i żółte flagi ostrzegawcze sędziów.
class CrashAndMechanicalVisualsRenderer {
  final CrashAndMechanicalConfig config;

  // Aktywne incydenty śledzone w symulacji
  final Map<String, ActiveMechanicalIncident> _activeMechanicals = {};
  final Map<String, ActiveCrashIncident> _activeCrashes = {};

  // Prealokowany cache farb malarskich dla gwarancji 120 FPS Zero-GC
  late final Paint _riderSkinPaint;
  late final Paint _riderJerseyPaint;
  late final Paint _riderShortsPaint;
  late final Paint _riderHelmetPaint;
  late final Paint _bikeFramePaint;
  late final Paint _bikeWheelPaint;
  late final Paint _serviceCarBodyPaint;
  late final Paint _serviceCarShadowPaint;
  late final Paint _mechanicShirtPaint;
  late final Paint _warningFlagPaint;
  late final Paint _rollingBidonPaint;
  late final Paint _skidMarkPaint;
  late final Paint _beaconFlashPaint;

  CrashAndMechanicalVisualsRenderer({
    this.config = const CrashAndMechanicalConfig(),
  }) {
    _initPaintCache();
  }

  void _initPaintCache() {
    _riderSkinPaint = Paint()
      ..color = const Color(0xFFDEB887)
      ..style = PaintingStyle.fill;

    _riderJerseyPaint = Paint()..style = PaintingStyle.fill;

    _riderShortsPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    _riderHelmetPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;

    _bikeFramePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    _bikeWheelPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _serviceCarBodyPaint = Paint()..style = PaintingStyle.fill;

    _serviceCarShadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    _mechanicShirtPaint = Paint()
      ..color = const Color(0xFF3B82F6) // Niebieskie polo mechanika WorldTour
      ..style = PaintingStyle.fill;

    _warningFlagPaint = Paint()
      ..color = const Color(0xFFFACC15) // Żółta flaga ostrzegawcza
      ..style = PaintingStyle.fill;

    _rollingBidonPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    _skidMarkPaint = Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    _beaconFlashPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
  }

  // ===========================================================================
  // 5. SYNCHRONIZACJA I AKTUALIZACJA INCYDENTÓW W KLATCE (UPDATE PIPELINE)
  // ===========================================================================

  /// Aktualizuje stan maszyn stanów awarii i kraks na podstawie telemetrii kolarzy.
  void updateIncidents({
    List<RiderPositionSnapshot>? snapshots,
    List<PelotonRenderItem>? activeRiders,
    required double dtSeconds,
    required List<StageSegment> segments,
  }) {
    if (!config.enabled) return;

    final effectiveSnapshots = snapshots ??
        activeRiders?.map((r) => r.snapshot).toList(growable: false) ??
        const <RiderPositionSnapshot>[];

    final double effectiveDt = dtSeconds * config.animationSpeedMultiplier;

    // Krok 1: Wykrywanie nowych awarii i kraks w bieżącej klatce
    for (final s in effectiveSnapshots) {
      // A. Awarie mechaniczne i kapcie (hasDefect == true && nie kraksa)
      if (s.hasDefect && !s.isCrashed) {
        if (!_activeMechanicals.containsKey(s.riderId)) {
          final sideSign = (s.lateralOffsetRoadMeters >= 0.0) ? 1.0 : -1.0;
          _activeMechanicals[s.riderId] = ActiveMechanicalIncident(
            riderId: s.riderId,
            riderName: s.riderName,
            bibNumber: s.bibNumber,
            teamId: s.teamId,
            teamName: s.teamName,
            teamColorHex: s.teamJerseyHexColor,
            defectType: s.defectType ?? IncidentType.punctureFlatTire,
            incidentDistanceMeters: s.distanceCoveredMeters,
            currentLateralOffsetMeters: s.lateralOffsetRoadMeters,
            targetVergeLateralOffset: sideSign * config.roadVergeOffsetMeters,
            currentSpeedMs: s.speedMs,
          );
        }
      }

      // B. Kraksy (isCrashed == true)
      if (s.isCrashed) {
        if (!_activeCrashes.containsKey(s.riderId)) {
          _activeCrashes[s.riderId] = ActiveCrashIncident(
            riderId: s.riderId,
            riderName: s.riderName,
            bibNumber: s.bibNumber,
            teamId: s.teamId,
            teamName: s.teamName,
            teamColorHex: s.teamJerseyHexColor,
            crashType: s.defectType ?? IncidentType.soloCrash,
            crashDistanceMeters: s.distanceCoveredMeters,
            lateralOffsetMeters: s.lateralOffsetRoadMeters,
            currentSpeedMs: s.speedMs,
          );
        }
      }
    }

    // Krok 2: Krok symulacji dla aktywnych awarii mechanicznych
    final finishedMechanicals = <String>[];
    for (final entry in _activeMechanicals.entries) {
      final inc = entry.value;
      inc.phaseElapsedSeconds += effectiveDt;

      switch (inc.phase) {
        case MechanicalIncidentPhase.signalingAndDriftingToVerge:
          // Płynny zjazd na pobocze i wyhamowanie do 0 m/s
          final t = (inc.phaseElapsedSeconds / inc.phase.defaultDurationSeconds).clamp(0.0, 1.0);
          inc.currentLateralOffsetMeters += (inc.targetVergeLateralOffset - inc.currentLateralOffsetMeters) * (effectiveDt * 2.5);
          inc.currentSpeedMs = math.max(0.0, inc.currentSpeedMs - (effectiveDt * 4.2));
          inc.incidentDistanceMeters += inc.currentSpeedMs * effectiveDt;
          inc.totalProgress = t * 0.20;

          if (inc.phaseElapsedSeconds >= inc.phase.defaultDurationSeconds) {
            inc.phase = MechanicalIncidentPhase.awaitingServiceAtVerge;
            inc.phaseElapsedSeconds = 0.0;
            inc.currentSpeedMs = 0.0;
          }
          break;

        case MechanicalIncidentPhase.awaitingServiceAtVerge:
          inc.totalProgress = 0.20 + (inc.phaseElapsedSeconds / inc.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.20;
          if (inc.phaseElapsedSeconds >= inc.phase.defaultDurationSeconds) {
            inc.phase = MechanicalIncidentPhase.mechanicRunningWithWheel;
            inc.phaseElapsedSeconds = 0.0;
          }
          break;

        case MechanicalIncidentPhase.mechanicRunningWithWheel:
          inc.totalProgress = 0.40 + (inc.phaseElapsedSeconds / inc.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.15;
          if (inc.phaseElapsedSeconds >= inc.phase.defaultDurationSeconds) {
            inc.phase = MechanicalIncidentPhase.mechanicReplacingWheel;
            inc.phaseElapsedSeconds = 0.0;
          }
          break;

        case MechanicalIncidentPhase.mechanicReplacingWheel:
          inc.totalProgress = 0.55 + (inc.phaseElapsedSeconds / inc.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.25;
          if (inc.phaseElapsedSeconds >= inc.phase.defaultDurationSeconds) {
            inc.phase = MechanicalIncidentPhase.pushOffAndAcceleration;
            inc.phaseElapsedSeconds = 0.0;
          }
          break;

        case MechanicalIncidentPhase.pushOffAndAcceleration:
          // Pchnięcie przez mechanika: gwałtowny skok prędkości do 10 m/s
          inc.currentSpeedMs = math.min(11.5, inc.currentSpeedMs + (effectiveDt * 4.5));
          inc.incidentDistanceMeters += inc.currentSpeedMs * effectiveDt;
          // Powolny powrót z pobocza na asfalt
          inc.currentLateralOffsetMeters += (0.0 - inc.currentLateralOffsetMeters) * (effectiveDt * 1.5);
          inc.totalProgress = 0.80 + (inc.phaseElapsedSeconds / inc.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.20;

          if (inc.phaseElapsedSeconds >= inc.phase.defaultDurationSeconds) {
            inc.phase = MechanicalIncidentPhase.resolved;
            finishedMechanicals.add(entry.key);
          }
          break;

        case MechanicalIncidentPhase.resolved:
          finishedMechanicals.add(entry.key);
          break;
      }
    }

    for (final id in finishedMechanicals) {
      _activeMechanicals.remove(id);
    }

    // Krok 3: Krok symulacji dla aktywnych kraks
    final finishedCrashes = <String>[];
    for (final entry in _activeCrashes.entries) {
      final crash = entry.value;
      crash.phaseElapsedSeconds += effectiveDt;

      switch (crash.phase) {
        case CrashIncidentPhase.tumbleAndSlide:
          // Poślizg po asfalcie i gwałtowne wyhamowanie
          crash.slideDistanceMeters += crash.currentSpeedMs * effectiveDt;
          crash.currentSpeedMs = math.max(0.0, crash.currentSpeedMs - (effectiveDt * 7.5));
          crash.crashDistanceMeters += crash.currentSpeedMs * effectiveDt;
          crash.bikeRotationAngle += effectiveDt * 3.2;
          crash.totalProgress = (crash.phaseElapsedSeconds / crash.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.20;

          if (crash.phaseElapsedSeconds >= crash.phase.defaultDurationSeconds) {
            crash.phase = CrashIncidentPhase.lyingOnTarmac;
            crash.phaseElapsedSeconds = 0.0;
            crash.currentSpeedMs = 0.0;
          }
          break;

        case CrashIncidentPhase.lyingOnTarmac:
          crash.totalProgress = 0.20 + (crash.phaseElapsedSeconds / crash.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.20;
          if (crash.phaseElapsedSeconds >= crash.phase.defaultDurationSeconds) {
            crash.phase = CrashIncidentPhase.standingAndInspectingBike;
            crash.phaseElapsedSeconds = 0.0;
          }
          break;

        case CrashIncidentPhase.standingAndInspectingBike:
          crash.totalProgress = 0.40 + (crash.phaseElapsedSeconds / crash.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.20;
          if (crash.phaseElapsedSeconds >= crash.phase.defaultDurationSeconds) {
            crash.phase = CrashIncidentPhase.adjustingHandlebarAndChain;
            crash.phaseElapsedSeconds = 0.0;
          }
          break;

        case CrashIncidentPhase.adjustingHandlebarAndChain:
          crash.totalProgress = 0.60 + (crash.phaseElapsedSeconds / crash.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.15;
          if (crash.phaseElapsedSeconds >= crash.phase.defaultDurationSeconds) {
            crash.phase = CrashIncidentPhase.remountingAndStartingSlow;
            crash.phaseElapsedSeconds = 0.0;
          }
          break;

        case CrashIncidentPhase.remountingAndStartingSlow:
          crash.currentSpeedMs = math.min(5.5, crash.currentSpeedMs + (effectiveDt * 2.2));
          crash.crashDistanceMeters += crash.currentSpeedMs * effectiveDt;
          crash.totalProgress = 0.75 + (crash.phaseElapsedSeconds / crash.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.10;
          if (crash.phaseElapsedSeconds >= crash.phase.defaultDurationSeconds) {
            crash.phase = CrashIncidentPhase.slowAcceleration;
            crash.phaseElapsedSeconds = 0.0;
          }
          break;

        case CrashIncidentPhase.slowAcceleration:
          // Powolne rozpędzanie się do tempa wyścigowego (do 12 m/s)
          crash.currentSpeedMs = math.min(12.0, crash.currentSpeedMs + (effectiveDt * 2.8));
          crash.crashDistanceMeters += crash.currentSpeedMs * effectiveDt;
          crash.totalProgress = 0.85 + (crash.phaseElapsedSeconds / crash.phase.defaultDurationSeconds).clamp(0.0, 1.0) * 0.15;
          if (crash.phaseElapsedSeconds >= crash.phase.defaultDurationSeconds) {
            crash.phase = CrashIncidentPhase.resolved;
            finishedCrashes.add(entry.key);
          }
          break;

        case CrashIncidentPhase.resolved:
          finishedCrashes.add(entry.key);
          break;
      }
    }

    for (final id in finishedCrashes) {
      _activeCrashes.remove(id);
    }
  }

  // ===========================================================================
  // 6. GŁÓWNA METODA RENDEROWANIA ZDARZEŃ NA CANVAS 3D
  // ===========================================================================

  /// Renderuje na Canvasie wszystkie aktywne zdarzenia losowe (wymiany kół, kraksy, mechaników).
  void renderIncidentVisuals({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    double elapsedAnimSeconds = 0.0,
    double? animSeconds,
  }) {
    if (!config.enabled) return;
    if (_activeMechanicals.isEmpty && _activeCrashes.isEmpty) return;

    final double animTime = animSeconds ?? elapsedAnimSeconds;

    // 1. Rysowanie aktywnych awarii mechanicznych (kolarz z uniesioną ręką, wóz, mechanik)
    for (final inc in _activeMechanicals.values) {
      _drawMechanicalIncident(canvas, projection, inc, animTime);
    }

    // 2. Rysowanie aktywnych kraks (leżący kolarze, rowery, bidony, flagi sędziów)
    for (final crash in _activeCrashes.values) {
      _drawCrashIncident(canvas, projection, crash, animTime);
    }
  }

  // ===========================================================================
  // 7. RYSOWANIE AWARII MECHANICZNEJ I WYMIANY KOŁA (WHEEL SWAP VISUALS)
  // ===========================================================================

  void _drawMechanicalIncident(
    Canvas canvas,
    Scene3DMathProjection projection,
    ActiveMechanicalIncident inc,
    double animSeconds,
  ) {
    // A. Rzutowanie pozycji kolarza na ekran
    final riderWorld = Scene3DMathProjection.courseToWorld3D(
      distanceMeters: inc.incidentDistanceMeters,
      lateralOffsetMeters: inc.currentLateralOffsetMeters,
      elevationMeters: 0.0,
      turningRadiusMeters: double.infinity,
      gradientPercent: 0.0,
    );

    final riderProj = projection.worldToScreen(riderWorld);
    if (!riderProj.isInFrontOfCamera) return;

    final riderScale = (riderProj.perspectiveScale * 14.5).clamp(0.25, 4.5);
    final riderPos = Offset(riderProj.screenX, riderProj.screenY);

    final Color teamColor = _parseHexColor(inc.teamColorHex, AppColors.primaryGold);

    // 1. Rower kolarza na poboczu (stojący)
    _drawStationaryBike(canvas, riderPos, riderScale, teamColor);

    // 2. Sylwetka kolarza z uniesioną ręką w górę (sygnalizacja awarii)
    _drawRiderSignalingAtVerge(canvas, riderPos, riderScale, teamColor, inc);

    // 3. Wóz techniczny drużyny zatrzymany za kolarzem (jeśli faza serwisowa)
    if (config.enableTeamCarAndMechanic && inc.phase.isMechanicActive) {
      final carDistance = inc.incidentDistanceMeters - 5.5; // 5.5m za kolarzem
      final carWorld = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: carDistance,
        lateralOffsetMeters: inc.currentLateralOffsetMeters,
        elevationMeters: 0.0,
        turningRadiusMeters: double.infinity,
        gradientPercent: 0.0,
      );

      final carProj = projection.worldToScreen(carWorld);
      if (carProj.isInFrontOfCamera) {
        final carScale = (carProj.perspectiveScale * 14.5).clamp(0.25, 4.5);
        final carPos = Offset(carProj.screenX, carProj.screenY);

        _drawStoppedServiceCar(canvas, carPos, carScale, teamColor, animSeconds);

        // 4. Mechanik z kołem zapasowym (biegnący, klęczący lub pchający)
        _drawMechanicServicing(canvas, riderPos, carPos, riderScale, teamColor, inc);
      }
    }
  }

  /// Kolarz stojący na poboczu z uniesioną wysoko ręką (gest wezwania wozu)
  void _drawRiderSignalingAtVerge(
    Canvas canvas,
    Offset pos,
    double scale,
    Color teamColor,
    ActiveMechanicalIncident inc,
  ) {
    _riderJerseyPaint.color = teamColor;

    // Tułów kolarza (stojący obok ramy)
    final torsoW = 5.0 * scale;
    final torsoH = 12.0 * scale;
    final torsoRect = Rect.fromLTWH(pos.dx - torsoW * 0.5, pos.dy - torsoH - 10.0 * scale, torsoW, torsoH);
    canvas.drawRRect(RRect.fromRectAndRadius(torsoRect, Radius.circular(1.5 * scale)), _riderJerseyPaint);

    // Kask i głowa
    canvas.drawCircle(Offset(pos.dx, torsoRect.top - 3.5 * scale), 3.2 * scale, _riderHelmetPaint);

    // Spodenki kolarskie
    canvas.drawRect(Rect.fromLTWH(pos.dx - torsoW * 0.5, torsoRect.bottom, torsoW, 6.0 * scale), _riderShortsPaint);

    // Nogi (wypięty but na podłożu)
    canvas.drawLine(Offset(pos.dx - 1.5 * scale, torsoRect.bottom + 6.0 * scale), Offset(pos.dx - 2.5 * scale, pos.dy), _riderSkinPaint..strokeWidth = 2.0 * scale);
    canvas.drawLine(Offset(pos.dx + 1.5 * scale, torsoRect.bottom + 6.0 * scale), Offset(pos.dx + 2.5 * scale, pos.dy), _riderSkinPaint..strokeWidth = 2.0 * scale);

    // Prawa ręka wyciągnięta WYSOKO W GÓRĘ (ikoniczny gest kolarza z defektem)
    if (inc.phase == MechanicalIncidentPhase.signalingAndDriftingToVerge ||
        inc.phase == MechanicalIncidentPhase.awaitingServiceAtVerge) {
      canvas.drawLine(
        Offset(torsoRect.right, torsoRect.top + 2.0 * scale),
        Offset(torsoRect.right + 2.0 * scale, torsoRect.top - 14.0 * scale),
        _riderSkinPaint..strokeWidth = 2.0 * scale..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Zatrzymany rower na poboczu
  void _drawStationaryBike(Canvas canvas, Offset pos, double scale, Color teamColor) {
    final double bikeW = 18.0 * scale;
    final double halfW = bikeW * 0.5;

    // Koła (stojące)
    canvas.drawCircle(Offset(pos.dx - halfW, pos.dy - 5.0 * scale), 5.0 * scale, _bikeWheelPaint);
    canvas.drawCircle(Offset(pos.dx + halfW, pos.dy - 5.0 * scale), 5.0 * scale, _bikeWheelPaint);

    // Trójkąt ramy w kolorze zespołu
    _bikeFramePaint.color = teamColor;
    final framePath = Path()
      ..moveTo(pos.dx - halfW, pos.dy - 5.0 * scale)
      ..lineTo(pos.dx, pos.dy - 5.0 * scale) // Suport
      ..lineTo(pos.dx + 4.0 * scale, pos.dy - 12.0 * scale) // Główka
      ..lineTo(pos.dx - 3.0 * scale, pos.dy - 12.0 * scale) // Siodełko
      ..close();
    canvas.drawPath(framePath, _bikeFramePaint);
  }

  /// Zatrzymany wóz techniczny z migającymi kogutami ostrzegawczymi
  void _drawStoppedServiceCar(
    Canvas canvas,
    Offset pos,
    double scale,
    Color teamColor,
    double animSeconds,
  ) {
    final double carW = 34.0 * scale;
    final double carH = 20.0 * scale;
    final double halfW = carW * 0.5;

    // Cień wozu
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx, pos.dy + 1.5 * scale), width: carW * 1.1, height: 7.0 * scale), _serviceCarShadowPaint);

    // Karoseria
    final bodyRect = Rect.fromLTRB(pos.dx - halfW, pos.dy - carH, pos.dx + halfW, pos.dy - 2.0 * scale);
    _serviceCarBodyPaint.color = teamColor;
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(3.5 * scale)), _serviceCarBodyPaint);

    // Błyskający kogut ostrzegawczy na dachu wozu
    final double flash = 0.5 + 0.5 * math.sin(animSeconds * 16.0);
    final beaconCenter = Offset(pos.dx, bodyRect.top - 2.0 * scale);
    canvas.drawRect(Rect.fromCenter(center: beaconCenter, width: 7.0 * scale, height: 3.0 * scale), Paint()..color = const Color(0xFFF59E0B));
    if (flash > 0.4) {
      canvas.drawCircle(beaconCenter, 7.0 * scale * flash, _beaconFlashPaint);
    }
  }

  /// Mechanik biegnący, wymieniający koło lub dający pchnięcie
  void _drawMechanicServicing(
    Canvas canvas,
    Offset riderPos,
    Offset carPos,
    double scale,
    Color teamColor,
    ActiveMechanicalIncident inc,
  ) {
    switch (inc.phase) {
      case MechanicalIncidentPhase.mechanicRunningWithWheel:
        // Mechanik biegnie od wozu do kolarza
        final double progress = (inc.phaseElapsedSeconds / inc.phase.defaultDurationSeconds).clamp(0.0, 1.0);
        final currentX = carPos.dx + (riderPos.dx - carPos.dx) * progress;
        final currentY = carPos.dy + (riderPos.dy - carPos.dy) * progress;

        // Mechanik w niebieskiej koszulce serwisowej
        canvas.drawCircle(Offset(currentX, currentY - 12.0 * scale), 3.0 * scale, _riderSkinPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(currentX, currentY - 6.0 * scale), width: 5.0 * scale, height: 8.0 * scale), _mechanicShirtPaint);
        // Koło karbonowe w dłoni mechanika
        canvas.drawCircle(Offset(currentX + 3.5 * scale, currentY - 4.5 * scale), 4.5 * scale, _bikeWheelPaint);
        break;

      case MechanicalIncidentPhase.mechanicReplacingWheel:
        // Mechanik klęczy przy przednim/tylnym kole roweru kolarza
        final mechX = riderPos.dx + 4.5 * scale;
        final mechY = riderPos.dy - 3.0 * scale;

        canvas.drawCircle(Offset(mechX, mechY - 8.0 * scale), 2.8 * scale, _riderSkinPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(mechX, mechY - 4.0 * scale), width: 6.0 * scale, height: 6.0 * scale), Radius.circular(1.5 * scale)), _mechanicShirtPaint);
        // Świeże koło montowane w widelcu
        canvas.drawCircle(Offset(mechX - 4.0 * scale, riderPos.dy - 5.0 * scale), 5.0 * scale, _bikeWheelPaint);
        break;

      case MechanicalIncidentPhase.pushOffAndAcceleration:
        // Mechanik chwyta kolarza za biodro i siodełko dając potężne pchnięcie w przód
        final mechX = riderPos.dx - 6.0 * scale;
        final mechY = riderPos.dy - 5.0 * scale;

        canvas.drawCircle(Offset(mechX, mechY - 10.0 * scale), 2.8 * scale, _riderSkinPaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(mechX, mechY - 5.0 * scale), width: 5.5 * scale, height: 7.5 * scale), _mechanicShirtPaint);
        // Ręce wyciągnięte do przodu na biodrach kolarza
        canvas.drawLine(Offset(mechX + 2.5 * scale, mechY - 7.0 * scale), Offset(riderPos.dx, riderPos.dy - 8.0 * scale), _riderSkinPaint..strokeWidth = 2.0 * scale);
        break;

      default:
        break;
    }
  }

  // ===========================================================================
  // 8. RYSOWANIE KRAKSY I ZBIERANIA SIĘ Z ASFALTU (CRASH VISUALS)
  // ===========================================================================

  void _drawCrashIncident(
    Canvas canvas,
    Scene3DMathProjection projection,
    ActiveCrashIncident crash,
    double animSeconds,
  ) {
    final worldPos = Scene3DMathProjection.courseToWorld3D(
      distanceMeters: crash.crashDistanceMeters,
      lateralOffsetMeters: crash.lateralOffsetMeters,
      elevationMeters: 0.0,
      turningRadiusMeters: double.infinity,
      gradientPercent: 0.0,
    );

    final proj = projection.worldToScreen(worldPos);
    if (!proj.isInFrontOfCamera) return;

    final scale = (proj.perspectiveScale * 14.5).clamp(0.25, 4.5);
    final pos = Offset(proj.screenX, proj.screenY);
    final Color teamColor = _parseHexColor(crash.teamColorHex, AppColors.crimsonAlert);

    // 1. Ślad poślizgu na asfalcie (Skid Mark)
    canvas.drawLine(
      Offset(pos.dx - 12.0 * scale, pos.dy),
      Offset(pos.dx + 4.0 * scale, pos.dy),
      _skidMarkPaint..strokeWidth = 2.2 * scale,
    );

    // 2. Leżący lub podnoszony rower
    _drawFallenBike(canvas, pos, scale, teamColor, crash);

    // 3. Kolarz w odpowiedniej pozie (leżący, zbierający się, prostujący kierownicę)
    _drawCrashedRiderBody(canvas, pos, scale, teamColor, crash);

    // 4. Rozsypane bidony toczące się po szosie
    if (config.enableRollingBidons) {
      _drawRollingBidon(canvas, Offset(pos.dx + 14.0 * scale, pos.dy + 3.0 * scale), scale, animSeconds);
    }

    // 5. Żółta flaga ostrzegawcza sędziego na poboczu (Danger Crash Zone)
    if (config.enableWarningFlags) {
      _drawCrashWarningFlag(canvas, Offset(pos.dx - 18.0 * scale, pos.dy - 8.0 * scale), scale, animSeconds);
    }
  }

  /// Leżący rower na asfalcie z obróconą kierownicą
  void _drawFallenBike(
    Canvas canvas,
    Offset pos,
    double scale,
    Color teamColor,
    ActiveCrashIncident crash,
  ) {
    final bikeCenter = Offset(pos.dx + 6.0 * scale, pos.dy - 2.0 * scale);

    canvas.save();
    canvas.translate(bikeCenter.dx, bikeCenter.dy);
    // Podczas upadku rower leży płasko na szosie
    canvas.rotate(crash.phase.isDownOnTarmac ? crash.bikeRotationAngle : 0.0);

    final bikeW = 16.0 * scale;
    final halfW = bikeW * 0.5;

    // Koła leżące
    canvas.drawOval(Rect.fromCenter(center: Offset(-halfW, 0), width: 9.0 * scale, height: 3.5 * scale), _bikeWheelPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(halfW, 0), width: 9.0 * scale, height: 3.5 * scale), _bikeWheelPaint);

    // Rama leżąca
    _bikeFramePaint.color = teamColor;
    canvas.drawLine(Offset(-halfW, 0), Offset.zero, _bikeFramePaint);
    canvas.drawLine(Offset.zero, Offset(halfW, 0), _bikeFramePaint);

    canvas.restore();
  }

  /// Kolarz po kraksie w różnych fazach (leżący, podnoszący się, prostujący klamkomanetki)
  void _drawCrashedRiderBody(
    Canvas canvas,
    Offset pos,
    double scale,
    Color teamColor,
    ActiveCrashIncident crash,
  ) {
    _riderJerseyPaint.color = teamColor;

    switch (crash.phase) {
      case CrashIncidentPhase.tumbleAndSlide:
      case CrashIncidentPhase.lyingOnTarmac:
        // Pozycja leżąca na asfalcie
        final bodyRect = Rect.fromCenter(center: Offset(pos.dx - 4.0 * scale, pos.dy - 2.5 * scale), width: 14.0 * scale, height: 4.5 * scale);
        canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(2.0 * scale)), _riderJerseyPaint);
        // Głowa w kasku na asfalcie
        canvas.drawCircle(Offset(pos.dx - 12.0 * scale, pos.dy - 2.5 * scale), 2.8 * scale, _riderHelmetPaint);
        // Nogi
        canvas.drawLine(Offset(bodyRect.right, pos.dy - 2.5 * scale), Offset(pos.dx + 8.0 * scale, pos.dy), _riderSkinPaint..strokeWidth = 2.0 * scale);
        break;

      case CrashIncidentPhase.standingAndInspectingBike:
        // Kolarz na kolanach podnoszący się z asfaltu
        final torsoCenter = Offset(pos.dx - 2.0 * scale, pos.dy - 7.0 * scale);
        canvas.drawCircle(Offset(torsoCenter.dx, torsoCenter.dy - 5.0 * scale), 3.0 * scale, _riderHelmetPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: torsoCenter, width: 6.0 * scale, height: 8.0 * scale), Radius.circular(1.5 * scale)), _riderJerseyPaint);
        // Ręce opierające się o podłoże
        canvas.drawLine(torsoCenter, Offset(pos.dx + 2.0 * scale, pos.dy), _riderSkinPaint..strokeWidth = 1.8 * scale);
        break;

      case CrashIncidentPhase.adjustingHandlebarAndChain:
        // Kolarz stoi pochylony nad kierownicą roweru, nastawia klamkomanetkę
        final standX = pos.dx - 2.0 * scale;
        canvas.drawCircle(Offset(standX, pos.dy - 16.0 * scale), 3.0 * scale, _riderHelmetPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(standX - 2.5 * scale, pos.dy - 13.0 * scale, 5.0 * scale, 9.0 * scale), Radius.circular(1.5 * scale)), _riderJerseyPaint);
        // Ręce na kierownicy roweru
        canvas.drawLine(Offset(standX, pos.dy - 8.0 * scale), Offset(pos.dx + 4.0 * scale, pos.dy - 8.0 * scale), _riderSkinPaint..strokeWidth = 1.8 * scale);
        break;

      case CrashIncidentPhase.remountingAndStartingSlow:
      case CrashIncidentPhase.slowAcceleration:
        // Kolarz na rowerze, powoli rozpędzający się
        canvas.drawCircle(Offset(pos.dx, pos.dy - 17.0 * scale), 3.0 * scale, _riderHelmetPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(pos.dx, pos.dy - 11.0 * scale), width: 5.0 * scale, height: 9.0 * scale), Radius.circular(1.5 * scale)), _riderJerseyPaint);
        break;

      case CrashIncidentPhase.resolved:
        break;
    }
  }

  /// Rozsypany bidon toczący się po szosie
  void _drawRollingBidon(Canvas canvas, Offset pos, double scale, double animSeconds) {
    final double rollAngle = (animSeconds * 8.0) % (2.0 * math.pi);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rollAngle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 2.4 * scale, height: 5.0 * scale), Radius.circular(1.0 * scale)),
      _rollingBidonPaint,
    );
    canvas.restore();
  }

  /// Żółta flaga ostrzegawcza sędziego na poboczu
  void _drawCrashWarningFlag(Canvas canvas, Offset pos, double scale, double animSeconds) {
    final double wave = math.sin(animSeconds * 9.0) * (2.0 * scale);
    final poleH = 22.0 * scale;

    // Drążek flagi
    canvas.drawLine(pos, Offset(pos.dx, pos.dy - poleH), Paint()..color = const Color(0xFF64748B)..strokeWidth = 1.5 * scale);

    // Żółta trójkątna flaga ostrzegawcza
    final flagPath = Path()
      ..moveTo(pos.dx, pos.dy - poleH)
      ..lineTo(pos.dx + 12.0 * scale + wave, pos.dy - poleH + 4.5 * scale)
      ..lineTo(pos.dx, pos.dy - poleH + 9.0 * scale)
      ..close();
    canvas.drawPath(flagPath, _warningFlagPaint);
  }

  // ===========================================================================
  // 9. METODY POMOCNICZE
  // ===========================================================================

  Color _parseHexColor(String hexString, Color fallback) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  /// Liczba aktualnie przetwarzanych incydentów
  int get activeMechanicalsCount => _activeMechanicals.length;
  int get activeCrashesCount => _activeCrashes.length;

  ActiveMechanicalIncident? getMechanicalIncident(String riderId) => _activeMechanicals[riderId];
  ActiveCrashIncident? getCrashIncident(String riderId) => _activeCrashes[riderId];

  void clearIncidents() {
    _activeMechanicals.clear();
    _activeCrashes.clear();
  }
}
