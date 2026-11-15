// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/stage_segment.dart';
import '../peloton/rider_race_state.dart';
import 'peloton_instanced_renderer.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. TYPY POJAZDÓW TOWARZYSZĄCYCH I STANY OBSŁUGI BIDONOWEJ
// =============================================================================

/// Typ pojazdu towarzyszącego w kolumnie wyścigu kolarskiego.
enum SupportVehicleType {
  /// Samochód techniczny drużyny (Team Car) dyrektora sportowego z rowerami na dachu.
  teamCar('Wóz Techniczny Drużyny', 4.8, 1.85),

  /// Motocykl telewizyjny (Moto TV) z operatorem kamery filmującym wstecz.
  motoTv('Motocykl Transmisji TV', 2.3, 0.95),

  /// Motocykl sędziowski / informacyjny z tablicą różnic czasowych (Moto Info / Ardoisier).
  motoCommissaire('Motocykl Sędziowski (Tablica Różnic)', 2.3, 0.95),

  /// Neutralny wóz serwisowy (np. żółty Mavic / błękitny Shimano Service Course) z kołami na dachu.
  neutralServiceCar('Neutralny Wóz Serwisowy', 4.8, 1.85);

  final String label;
  final double lengthMeters;
  final double widthMeters;

  const SupportVehicleType(this.label, this.lengthMeters, this.widthMeters);

  bool get isMotorbike =>
      this == SupportVehicleType.motoTv ||
      this == SupportVehicleType.motoCommissaire;

  bool get isCar =>
      this == SupportVehicleType.teamCar ||
      this == SupportVehicleType.neutralServiceCar;
}

/// Fazy animacji interakcji kolarza z wozem technicznym dyrektora sportowego (Sticky Bottle Feed).
enum BidonFeedPhase {
  /// Brak aktywnej interakcji (jazda w kolumnie).
  none,

  /// Wóz przyspiesza wzdłuż peletonu lub kolarz cofa się na tył grupy w stronę wozu.
  approaching,

  /// Kolarz jedzie tuż przy oknie wozu, dyrektor podaje bidony ("sticky bottle").
  feedingStickyBottle,

  /// Kolarz chowa bidony do koszyków i za koszulkę, wóz wraca na swoje miejsce w kolumnie.
  returningToPeloton;

  bool get isActivelyServicing =>
      this == BidonFeedPhase.approaching ||
      this == BidonFeedPhase.feedingStickyBottle ||
      this == BidonFeedPhase.returningToPeloton;
}

/// Stan pojedynczej aktywnej interakcji podjazdu kolarza po bidony lub serwis techniczny.
class ActiveBidonFeedSession {
  final String riderId;
  final String teamId;
  final String teamName;
  final String teamColorHex;

  BidonFeedPhase phase;
  double phaseElapsedSeconds;
  double totalProgress; // 0.0 - 1.0

  /// Strona jezdni, po której odbywa się podjazd (-1.0 = lewa, 1.0 = prawa).
  final double sideSign;

  ActiveBidonFeedSession({
    required this.riderId,
    required this.teamId,
    required this.teamName,
    required this.teamColorHex,
    this.phase = BidonFeedPhase.approaching,
    this.phaseElapsedSeconds = 0.0,
    this.totalProgress = 0.0,
    this.sideSign = 1.0,
  });
}

// =============================================================================
// 2. MODEL POJEDYNCZEGO POJAZDU W PRZESTRZENI 3D
// =============================================================================

/// Instancja pojazdu towarzyszącego w przestrzeni trójwymiarowej wyścigu.
class SupportVehicleInstance3D {
  final String id;
  final SupportVehicleType type;
  final String teamId;
  final String teamName;
  final Color primaryColor;
  final Color accentColor;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 surfaceNormal;
  final double distanceAlongCourseMeters;
  final double lateralOffsetMeters;
  final double speedKmh;
  final int convoyIndex;
  final bool isBeaconFlashing;
  final ActiveBidonFeedSession? activeFeedSession;

  const SupportVehicleInstance3D({
    required this.id,
    required this.type,
    this.teamId = '',
    this.teamName = '',
    required this.primaryColor,
    this.accentColor = Colors.white,
    required this.worldPosition,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.distanceAlongCourseMeters,
    required this.lateralOffsetMeters,
    required this.speedKmh,
    this.convoyIndex = 0,
    this.isBeaconFlashing = false,
    this.activeFeedSession,
  });
}

// =============================================================================
// 3. KONFIGURACJA MODUŁU POJAZDÓW TOWARZYSZĄCYCH
// =============================================================================

/// Konfiguracja parametrów symulacji i renderowania pojazdów towarzyszących.
class SupportVehiclesConfig {
  /// Czy moduł renderera jest włączony.
  final bool enabled;

  /// Liczba wozów technicznych drużyn renderowanych w kolumnie za peletonem.
  final int maxTeamCarsInConvoy;

  /// Czy renderować motocykle telewizyjne przed ucieczką lub peletonem.
  final bool enableTvMotorbikes;

  /// Czy renderować neutralny wóz serwisowy z zapasowymi kołami na dachu.
  final bool enableNeutralServiceCar;

  /// Czy włączona jest dynamiczna animacja podjazdu kolarza po bidony (Sticky Bottle).
  final bool enableBidonFeedAnimation;

  /// Odległość pierwszego wozu technicznego za ogonem peletonu [m].
  final double convoyFollowDistanceMeters;

  /// Odstęp wzdłużny pomiędzy kolejnymi wozami technicznymi w kolumnie [m].
  final double teamCarSpacingMeters;

  /// Odległość motocykla TV przed czołowym kolarzem [m].
  final double tvMotoLeadDistanceMeters;

  /// Czas trwania pełnego cyklu podjazdu po bidon i powrotu do peletonu [s].
  final double bidonFeedCycleDurationSeconds;

  const SupportVehiclesConfig({
    this.enabled = true,
    this.maxTeamCarsInConvoy = 6,
    this.enableTvMotorbikes = true,
    this.enableNeutralServiceCar = true,
    this.enableBidonFeedAnimation = true,
    this.convoyFollowDistanceMeters = 22.0,
    this.teamCarSpacingMeters = 14.0,
    this.tvMotoLeadDistanceMeters = 10.0,
    this.bidonFeedCycleDurationSeconds = 12.0,
  });
}

// =============================================================================
// 4. GŁÓWNY MODUŁ RENDERUJĄCY POJAZDY TOWARZYSZĄCE 3D
// =============================================================================

/// Zaawansowany moduł symulujący i renderujący w czasie rzeczywistym (120 FPS Zero-GC)
/// pojazdy towarzyszące peletonowi:
/// 1. Wozy techniczne dyrektorów sportowych (Team Cars) jadące w kolumnie z rowerami na dachu,
/// 2. Animację podjazdu kolarza do okna samochodu dyrektora sportowego po bidony (Sticky Bottle),
/// 3. Motocykle telewizyjne filmujące wstecz z kamerą naramienną,
/// 4. Neutralny wóz serwisowy z zapasowymi kołami karbonowymi jadący przed ucieczką.
class SupportVehicles3DRenderer {
  final SupportVehiclesConfig config;

  // Aktywne sesje karmienia kolarzy (Sticky Bottle Feed)
  final Map<String, ActiveBidonFeedSession> _activeFeedSessions = {};

  // Prealokowane obiekty farb malarskich dla gwarancji 120 FPS Zero-GC
  late final Paint _carBodyPaint;
  late final Paint _carShadowPaint;
  late final Paint _carGlassPaint;
  late final Paint _carWheelPaint;
  late final Paint _carTaillightPaint;
  late final Paint _roofRackPaint;
  late final Paint _roofBikeFramePaint;
  late final Paint _roofBikeWheelPaint;
  late final Paint _beaconAmberPaint;
  late final Paint _beaconGlowPaint;
  late final Paint _motoBodyPaint;
  late final Paint _motoHelmetPaint;
  late final Paint _motoJacketPaint;
  late final Paint _tvCameraBodyPaint;
  late final Paint _tvTallyLightPaint;
  late final Paint _bidonArmPaint;
  late final Paint _bidonBottlePaint;

  SupportVehicles3DRenderer({
    this.config = const SupportVehiclesConfig(),
  }) {
    _initPaintCache();
  }

  void _initPaintCache() {
    _carBodyPaint = Paint()..style = PaintingStyle.fill;

    _carShadowPaint = Paint()
      ..color = const Color(0x77000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    _carGlassPaint = Paint()
      ..color = const Color(0xC00F172A)
      ..style = PaintingStyle.fill;

    _carWheelPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    _carTaillightPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    _roofRackPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    _roofBikeFramePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _roofBikeWheelPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _beaconAmberPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;

    _beaconGlowPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    _motoBodyPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    _motoHelmetPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    _motoJacketPaint = Paint()
      ..color = const Color(0xFFFACC15) // Odblaskowa kamizelka akredytacyjna TV
      ..style = PaintingStyle.fill;

    _tvCameraBodyPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    _tvTallyLightPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    _bidonArmPaint = Paint()
      ..color = const Color(0xFFDEB887)
      ..style = PaintingStyle.fill;

    _bidonBottlePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
  }

  // ===========================================================================
  // 5. AKTUALIZACJA I BUDOWA INSTANCJI POJAZDÓW (UPDATE VEHICLES PIPELINE)
  // ===========================================================================

  /// Aktualizuje stan pojazdów, zarządza animacjami podjazdu po bidon i tworzy
  /// listę gotowych instancji trójwymiarowych pojazdów w bieżącej klatce animacji.
  List<SupportVehicleInstance3D> updateAndBuildVehicles({
    required List<PelotonRenderItem> activeRiders,
    required List<StageSegment> segments,
    required double dtSeconds,
    required double elapsedAnimSeconds,
  }) {
    if (!config.enabled || activeRiders.isEmpty) return const [];

    // Krok 1: Analiza rozkładu kolarzy na trasie (czoło, ogon, ucieczki)
    double frontDistance = -1.0;
    double backDistance = 999999.0;
    PelotonRenderItem? frontLeader;
    PelotonRenderItem? rearDomestique;

    // Mapa kolarzy pobierających bidony (TacticalOrder.fetchBidonsFromCar)
    final ridersRequestingFeed = <PelotonRenderItem>[];

    for (final item in activeRiders) {
      final dist = item.snapshot.distanceCoveredMeters;
      if (dist > frontDistance) {
        frontDistance = dist;
        frontLeader = item;
      }
      if (dist < backDistance) {
        backDistance = dist;
        rearDomestique = item;
      }

      if (item.snapshot.activeTacticalOrder ==
          TacticalOrder.fetchBidonsFromCar) {
        ridersRequestingFeed.add(item);
      }
    }

    if (frontLeader == null || rearDomestique == null) return const [];

    // Krok 2: Aktualizacja aktywnych sesji karmienia (Sticky Bottle)
    _updateBidonFeedSessions(ridersRequestingFeed, dtSeconds);

    final vehicles = <SupportVehicleInstance3D>[];
    int vehicleCounter = 0;

    // -------------------------------------------------------------------------
    // A. POJAZDY PRZED CZOŁEM GRUPY (MOTO TV & NEUTRALNY WÓZ SERWISOWY)
    // -------------------------------------------------------------------------

    // A1. Motocykl telewizyjny (Moto TV 1) jadący przed liderem/ucieczką
    if (config.enableTvMotorbikes) {
      final double motoDist = frontDistance + config.tvMotoLeadDistanceMeters;
      final double motoElev = _calculateElevationAt(motoDist, segments);
      final double motoGrad = _calculateGradientAt(motoDist, segments);
      const double motoLateral = 1.6; // Lekko na prawej flance szosy

      final motoPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: motoDist,
        lateralOffsetMeters: motoLateral,
        elevationMeters: motoElev,
        turningRadiusMeters: double.infinity,
        gradientPercent: motoGrad,
      );

      vehicles.add(SupportVehicleInstance3D(
        id: 'moto_tv_${vehicleCounter++}',
        type: SupportVehicleType.motoTv,
        primaryColor: const Color(0xFF1E293B),
        accentColor: const Color(0xFFFACC15),
        worldPosition: motoPos,
        tangent: frontLeader.tangent,
        lateralRight: frontLeader.right,
        surfaceNormal: frontLeader.up,
        distanceAlongCourseMeters: motoDist,
        lateralOffsetMeters: motoLateral,
        speedKmh: frontLeader.snapshot.speedKmh,
      ));

      // A2. Motocykl sędziowski z tablicą różnic (Moto Info)
      final double commDist =
          frontDistance + (config.tvMotoLeadDistanceMeters * 2.2);
      final double commElev = _calculateElevationAt(commDist, segments);
      final double commGrad = _calculateGradientAt(commDist, segments);
      const double commLateral = -1.5; // Na lewej flance szosy

      final commPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: commDist,
        lateralOffsetMeters: commLateral,
        elevationMeters: commElev,
        turningRadiusMeters: double.infinity,
        gradientPercent: commGrad,
      );

      vehicles.add(SupportVehicleInstance3D(
        id: 'moto_comm_${vehicleCounter++}',
        type: SupportVehicleType.motoCommissaire,
        primaryColor: const Color(0xFF0F172A),
        accentColor: Colors.white,
        worldPosition: commPos,
        tangent: frontLeader.tangent,
        lateralRight: frontLeader.right,
        surfaceNormal: frontLeader.up,
        distanceAlongCourseMeters: commDist,
        lateralOffsetMeters: commLateral,
        speedKmh: frontLeader.snapshot.speedKmh,
      ));
    }

    // A3. Neutralny wóz serwisowy (Mavic Yellow / Shimano Blue Service Course)
    if (config.enableNeutralServiceCar) {
      final double neutralDist =
          frontDistance + (config.tvMotoLeadDistanceMeters * 3.4);
      final double neutralElev = _calculateElevationAt(neutralDist, segments);
      final double neutralGrad = _calculateGradientAt(neutralDist, segments);
      const double neutralLateral = 1.8;

      final neutralPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: neutralDist,
        lateralOffsetMeters: neutralLateral,
        elevationMeters: neutralElev,
        turningRadiusMeters: double.infinity,
        gradientPercent: neutralGrad,
      );

      vehicles.add(SupportVehicleInstance3D(
        id: 'neutral_car_${vehicleCounter++}',
        type: SupportVehicleType.neutralServiceCar,
        teamName: 'SERVICE COURSE',
        primaryColor: const Color(0xFFFFCC00), // Żółć Mavic
        accentColor: const Color(0xFF0F172A),
        worldPosition: neutralPos,
        tangent: frontLeader.tangent,
        lateralRight: frontLeader.right,
        surfaceNormal: frontLeader.up,
        distanceAlongCourseMeters: neutralDist,
        lateralOffsetMeters: neutralLateral,
        speedKmh: frontLeader.snapshot.speedKmh,
      ));
    }

    // -------------------------------------------------------------------------
    // B. KOLUMNA WOZÓW TECHNICZNYCH DRUŻYN ZA PELETONEM (TEAM CARS CAVALCADE)
    // -------------------------------------------------------------------------
    final uniqueTeams = <String, (String name, String hex)>{};
    for (final item in activeRiders) {
      if (!uniqueTeams.containsKey(item.snapshot.teamId)) {
        uniqueTeams[item.snapshot.teamId] = (
          item.snapshot.teamName,
          item.snapshot.teamJerseyHexColor,
        );
      }
    }

    final teamList = uniqueTeams.entries.toList();
    final int carCount = math.min(config.maxTeamCarsInConvoy, teamList.length);

    double currentConvoyDist = backDistance - config.convoyFollowDistanceMeters;

    for (int i = 0; i < carCount; i++) {
      final teamEntry = teamList[i];
      final teamId = teamEntry.key;
      final teamName = teamEntry.value.$1;
      final teamHex = teamEntry.value.$2;

      final Color teamColor = _parseHexColor(teamHex, AppColors.primaryGold);

      // Sprawdzamy czy ten zespół ma aktywną sesję karmienia
      final activeSession = _activeFeedSessions[teamId];
      final bool isFeeding =
          activeSession != null && activeSession.phase.isActivelyServicing;

      double carDistance = currentConvoyDist;
      double carLateral = (i % 2 == 0) ? -1.85 : 1.85; // Schodkowy szyk kolumny
      bool beaconActive = false;

      // Jeżeli wóz podjeżdża do kolarza (Sticky Bottle animation)
      if (isFeeding) {
        beaconActive = true;
        // Wóz wysuwa się z kolumny i zrównuje z kolarzem
        final rider = activeRiders.firstWhere(
          (r) => r.snapshot.riderId == activeSession.riderId,
          orElse: () => rearDomestique!,
        );

        switch (activeSession.phase) {
          case BidonFeedPhase.approaching:
            final t = activeSession.phaseElapsedSeconds / 3.0;
            carDistance = math.max(
                currentConvoyDist,
                currentConvoyDist +
                    (rider.snapshot.distanceCoveredMeters - currentConvoyDist) *
                        t.clamp(0.0, 1.0));
            carLateral = activeSession.sideSign * 2.3;
            break;

          case BidonFeedPhase.feedingStickyBottle:
            // Wóz jedzie idealnie obok kolarza (odstęp 1.1m)
            carDistance = rider.snapshot.distanceCoveredMeters;
            carLateral = rider.snapshot.lateralOffsetRoadMeters +
                (activeSession.sideSign * 1.1);
            break;

          case BidonFeedPhase.returningToPeloton:
            final t = (activeSession.phaseElapsedSeconds / 3.0).clamp(0.0, 1.0);
            carDistance = math.max(
                currentConvoyDist,
                rider.snapshot.distanceCoveredMeters -
                    (rider.snapshot.distanceCoveredMeters - currentConvoyDist) *
                        t);
            carLateral = (i % 2 == 0) ? -1.85 : 1.85;
            break;

          case BidonFeedPhase.none:
            break;
        }
      }

      final carElev = _calculateElevationAt(carDistance, segments);
      final carGrad = _calculateGradientAt(carDistance, segments);

      final carPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: carDistance,
        lateralOffsetMeters: carLateral,
        elevationMeters: carElev,
        turningRadiusMeters: double.infinity,
        gradientPercent: carGrad,
      );

      vehicles.add(SupportVehicleInstance3D(
        id: 'team_car_${teamId}_$i',
        type: SupportVehicleType.teamCar,
        teamId: teamId,
        teamName: teamName,
        primaryColor: teamColor,
        accentColor: Colors.white,
        worldPosition: carPos,
        tangent: rearDomestique.tangent,
        lateralRight: rearDomestique.right,
        surfaceNormal: rearDomestique.up,
        distanceAlongCourseMeters: carDistance,
        lateralOffsetMeters: carLateral,
        speedKmh: rearDomestique.snapshot.speedKmh,
        convoyIndex: i + 1,
        isBeaconFlashing: beaconActive,
        activeFeedSession: isFeeding ? activeSession : null,
      ));

      currentConvoyDist -= config.teamCarSpacingMeters;
    }

    return vehicles;
  }

  // ===========================================================================
  // 6. OBSŁUGA MASZYNY STANÓW KARMIENIA KOLARZY (STICKY BOTTLE LOGIC)
  // ===========================================================================

  void _updateBidonFeedSessions(
      List<PelotonRenderItem> requestingRiders, double dtSeconds) {
    if (!config.enableBidonFeedAnimation) return;

    // Dodawanie nowych sesji dla kolarzy z poleceniem fetchBidonsFromCar
    for (final item in requestingRiders) {
      final teamId = item.snapshot.teamId;
      if (!_activeFeedSessions.containsKey(teamId)) {
        _activeFeedSessions[teamId] = ActiveBidonFeedSession(
          riderId: item.snapshot.riderId,
          teamId: teamId,
          teamName: item.snapshot.teamName,
          teamColorHex: item.snapshot.teamJerseyHexColor,
          phase: BidonFeedPhase.approaching,
          sideSign: item.snapshot.lateralOffsetRoadMeters >= 0.0 ? 1.0 : -1.0,
        );
      }
    }

    // Aktualizacja istniejących sesji
    final finishedTeams = <String>[];
    for (final entry in _activeFeedSessions.entries) {
      final session = entry.value;
      session.phaseElapsedSeconds += dtSeconds;

      switch (session.phase) {
        case BidonFeedPhase.approaching:
          session.totalProgress =
              (session.phaseElapsedSeconds / 3.0).clamp(0.0, 0.33);
          if (session.phaseElapsedSeconds >= 3.0) {
            session.phase = BidonFeedPhase.feedingStickyBottle;
            session.phaseElapsedSeconds = 0.0;
          }
          break;

        case BidonFeedPhase.feedingStickyBottle:
          session.totalProgress =
              0.33 + (session.phaseElapsedSeconds / 5.0).clamp(0.0, 0.34);
          if (session.phaseElapsedSeconds >= 5.0) {
            session.phase = BidonFeedPhase.returningToPeloton;
            session.phaseElapsedSeconds = 0.0;
          }
          break;

        case BidonFeedPhase.returningToPeloton:
          session.totalProgress =
              0.67 + (session.phaseElapsedSeconds / 3.5).clamp(0.0, 0.33);
          if (session.phaseElapsedSeconds >= 3.5) {
            finishedTeams.add(entry.key);
          }
          break;

        case BidonFeedPhase.none:
          finishedTeams.add(entry.key);
          break;
      }
    }

    for (final teamId in finishedTeams) {
      _activeFeedSessions.remove(teamId);
    }
  }

  // ===========================================================================
  // 7. GŁÓWNA METODA RENDEROWANIA POJAZDÓW NA CANVAS (120 FPS ZERO-GC)
  // ===========================================================================

  /// Rysuje wszystkie widoczne pojazdy towarzyszące na obiekcie [Canvas] z sortowaniem głębokości.
  void renderSupportVehicles({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required List<SupportVehicleInstance3D> vehicles,
    double elapsedAnimSeconds = 0.0,
  }) {
    if (!config.enabled || vehicles.isEmpty) return;

    final eyePos = projection.cameraPosition;
    final visibleItems =
        <(SupportVehicleInstance3D, ProjectedPoint3D, double)>[];

    // Krok 1: Frustum Culling i rzutowanie 3D
    for (final vehicle in vehicles) {
      final dist = (vehicle.worldPosition - eyePos).length;
      if (dist > 350.0) continue;

      final proj = projection.worldToScreen(vehicle.worldPosition);
      if (!proj.isInFrontOfCamera) continue;

      // Margines ekranowy dla samochodów
      const double screenMargin = 120.0;
      if (proj.screenX < -screenMargin ||
          proj.screenX > projection.viewportWidth + screenMargin ||
          proj.screenY < -screenMargin ||
          proj.screenY > projection.viewportHeight + screenMargin) {
        continue;
      }

      visibleItems.add((vehicle, proj, dist));
    }

    if (visibleItems.isEmpty) return;

    // Krok 2: Painter's Algorithm - sortowanie Back-to-Front (najdalsze najpierw)
    visibleItems.sort((a, b) => b.$3.compareTo(a.$3));

    // Krok 3: Rysowanie poszczególnych pojazdów
    for (final (vehicle, proj, _) in visibleItems) {
      final double scale = (proj.perspectiveScale * 14.5).clamp(0.2, 5.0);
      final center = Offset(proj.screenX, proj.screenY);

      switch (vehicle.type) {
        case SupportVehicleType.teamCar:
          _drawTeamCar3D(canvas, center, scale, vehicle, elapsedAnimSeconds);
          break;

        case SupportVehicleType.neutralServiceCar:
          _drawNeutralServiceCar3D(canvas, center, scale, vehicle);
          break;

        case SupportVehicleType.motoTv:
          _drawMotoTv3D(canvas, center, scale, vehicle, elapsedAnimSeconds);
          break;

        case SupportVehicleType.motoCommissaire:
          _drawMotoCommissaire3D(canvas, center, scale, vehicle);
          break;
      }
    }
  }

  // ===========================================================================
  // 8. RENDERERY GEOMETRII POSZCZEGÓLNYCH POJAZDÓW 3D
  // ===========================================================================

  /// A. Wóz techniczny drużyny (Team Car Kombi z rowerami na dachu)
  void _drawTeamCar3D(
    Canvas canvas,
    Offset pos,
    double scale,
    SupportVehicleInstance3D vehicle,
    double animSeconds,
  ) {
    final double carW = 38.0 * scale;
    final double carH = 22.0 * scale;
    final double halfW = carW * 0.5;

    // 1. Cień kontaktowy samochodu na asfalcie
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(pos.dx, pos.dy + 2.0 * scale),
          width: carW * 1.15,
          height: 8.0 * scale),
      _carShadowPaint,
    );

    // 2. Koła samochodu (czarne opony + felgi aluminiowe)
    final wheelW = 5.5 * scale;
    final wheelH = 9.0 * scale;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                pos.dx - halfW, pos.dy - wheelH + 2.0 * scale, wheelW, wheelH),
            Radius.circular(2.0 * scale)),
        _carWheelPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(pos.dx + halfW - wheelW,
                pos.dy - wheelH + 2.0 * scale, wheelW, wheelH),
            Radius.circular(2.0 * scale)),
        _carWheelPaint);

    // 3. Karoseria kombi w barwach zespołu
    final bodyRect = Rect.fromLTRB(pos.dx - halfW + 1.5 * scale, pos.dy - carH,
        pos.dx + halfW - 1.5 * scale, pos.dy - 2.0 * scale);
    _carBodyPaint.color = vehicle.primaryColor;
    canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, Radius.circular(4.0 * scale)),
        _carBodyPaint);

    // 4. Szyby (przednia, tylna i boczne)
    final glassRect = Rect.fromLTRB(
        bodyRect.left + 3.0 * scale,
        bodyRect.top + 2.0 * scale,
        bodyRect.right - 3.0 * scale,
        bodyRect.top + (carH * 0.48));
    canvas.drawRRect(
        RRect.fromRectAndRadius(glassRect, Radius.circular(2.5 * scale)),
        _carGlassPaint);

    // 5. Światła LED (reflektory przednie lub tylne lampy zależnie od perspektywy)
    canvas.drawCircle(
        Offset(bodyRect.left + 3.5 * scale, bodyRect.bottom - 4.0 * scale),
        2.0 * scale,
        _carTaillightPaint);
    canvas.drawCircle(
        Offset(bodyRect.right - 3.5 * scale, bodyRect.bottom - 4.0 * scale),
        2.0 * scale,
        _carTaillightPaint);

    // 6. Relingi i bagażnik dachowy z zapasowymi rowerami
    _drawRoofRackWithBikes(
        canvas, Offset(pos.dx, bodyRect.top), scale, vehicle.primaryColor);

    // 7. Belka koguta ostrzegawczego (Amber Beacon) na dachu
    if (vehicle.isBeaconFlashing) {
      final double pulse = 0.5 + 0.5 * math.sin(animSeconds * 14.0);
      final beaconRect = Rect.fromCenter(
          center: Offset(pos.dx, bodyRect.top - 1.5 * scale),
          width: 8.0 * scale,
          height: 3.0 * scale);
      canvas.drawRect(beaconRect, _beaconAmberPaint);
      if (pulse > 0.4) {
        canvas.drawCircle(
            beaconRect.center, 6.0 * scale * pulse, _beaconGlowPaint);
      }
    }

    // 8. Animacja wysuniętej ręki dyrektora sportowego z bidonem (Sticky Bottle Feed)
    if (vehicle.activeFeedSession?.phase ==
        BidonFeedPhase.feedingStickyBottle) {
      _drawStickyBottleHandout(
          canvas, pos, scale, vehicle.activeFeedSession!.sideSign);
    }
  }

  /// B. Neutralny wóz serwisowy (Mavic Yellow z kołami na dachu)
  void _drawNeutralServiceCar3D(
    Canvas canvas,
    Offset pos,
    double scale,
    SupportVehicleInstance3D vehicle,
  ) {
    final double carW = 38.0 * scale;
    final double carH = 22.0 * scale;
    final double halfW = carW * 0.5;

    // Cień
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(pos.dx, pos.dy + 2.0 * scale),
          width: carW * 1.15,
          height: 8.0 * scale),
      _carShadowPaint,
    );

    // Koła
    final wheelW = 5.5 * scale;
    final wheelH = 9.0 * scale;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                pos.dx - halfW, pos.dy - wheelH + 2.0 * scale, wheelW, wheelH),
            Radius.circular(2.0 * scale)),
        _carWheelPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(pos.dx + halfW - wheelW,
                pos.dy - wheelH + 2.0 * scale, wheelW, wheelH),
            Radius.circular(2.0 * scale)),
        _carWheelPaint);

    // Żółta karoseria Mavic
    final bodyRect = Rect.fromLTRB(pos.dx - halfW + 1.5 * scale, pos.dy - carH,
        pos.dx + halfW - 1.5 * scale, pos.dy - 2.0 * scale);
    _carBodyPaint.color = vehicle.primaryColor;
    canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, Radius.circular(4.0 * scale)),
        _carBodyPaint);

    // Szyby
    final glassRect = Rect.fromLTRB(
        bodyRect.left + 3.0 * scale,
        bodyRect.top + 2.0 * scale,
        bodyRect.right - 3.0 * scale,
        bodyRect.top + (carH * 0.48));
    canvas.drawRRect(
        RRect.fromRectAndRadius(glassRect, Radius.circular(2.5 * scale)),
        _carGlassPaint);

    // Napis SERVICE COURSE na boku
    if (scale >= 0.45) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'SERVICE',
          style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 7.0,
              fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
          canvas, Offset(pos.dx - textPainter.width * 0.5, bodyRect.center.dy));
    }

    // Bagażnik dachowy z zapasowymi kołami szosowymi w uchwytach
    _drawRoofRackWithSpareWheels(canvas, Offset(pos.dx, bodyRect.top), scale);
  }

  /// C. Motocykl telewizyjny (Moto TV z kamerzystą tyłem)
  void _drawMotoTv3D(
    Canvas canvas,
    Offset pos,
    double scale,
    SupportVehicleInstance3D vehicle,
    double animSeconds,
  ) {
    final double motoW = 16.0 * scale;

    // 1. Cień motocykla
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(pos.dx, pos.dy + 1.5 * scale),
          width: motoW * 1.2,
          height: 6.0 * scale),
      _carShadowPaint,
    );

    // 2. Koło motocykla
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(pos.dx, pos.dy - 4.5 * scale),
              width: 4.5 * scale,
              height: 9.0 * scale),
          Radius.circular(2.0 * scale)),
      _carWheelPaint,
    );

    // 3. Karoseria motocykla turystycznego
    final bodyRect = Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 12.0 * scale),
        width: motoW,
        height: 10.0 * scale);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, Radius.circular(3.0 * scale)),
        _motoBodyPaint);

    // 4. Kufry boczne
    canvas.drawRect(
        Rect.fromLTWH(bodyRect.left - 2.5 * scale, bodyRect.top + 2.0 * scale,
            3.0 * scale, 6.0 * scale),
        _carWheelPaint);
    canvas.drawRect(
        Rect.fromLTWH(bodyRect.right - 0.5 * scale, bodyRect.top + 2.0 * scale,
            3.0 * scale, 6.0 * scale),
        _carWheelPaint);

    // 5. Kierowca motocykla (w kasku i kurtce)
    final driverY = pos.dy - 17.0 * scale;
    canvas.drawCircle(Offset(pos.dx, driverY), 3.5 * scale, _motoJacketPaint);
    canvas.drawCircle(
        Offset(pos.dx, driverY - 4.5 * scale), 3.0 * scale, _motoHelmetPaint);

    // 6. Operator kamery TV siedzący tyłem z kamerą na ramieniu
    final cameramanY = pos.dy - 19.5 * scale;
    canvas.drawCircle(
        Offset(pos.dx, cameramanY), 3.8 * scale, _motoJacketPaint);
    canvas.drawCircle(Offset(pos.dx, cameramanY - 4.5 * scale), 3.2 * scale,
        _motoHelmetPaint);

    // Profesjonalna kamera telewizyjna na ramieniu operatora
    final cameraRect = Rect.fromLTWH(pos.dx + 2.0 * scale,
        cameramanY - 6.5 * scale, 7.5 * scale, 4.5 * scale);
    canvas.drawRect(cameraRect, _tvCameraBodyPaint);
    // Czerwona dioda Tally Light (nagrywanie na żywo)
    canvas.drawCircle(
        Offset(cameraRect.left + 1.2 * scale, cameraRect.top + 1.2 * scale),
        0.8 * scale,
        _tvTallyLightPaint);
  }

  /// D. Motocykl sędziowski z tablicą różnic (Moto Info)
  void _drawMotoCommissaire3D(
    Canvas canvas,
    Offset pos,
    double scale,
    SupportVehicleInstance3D vehicle,
  ) {
    final double motoW = 16.0 * scale;

    // Cień
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(pos.dx, pos.dy + 1.5 * scale),
          width: motoW * 1.2,
          height: 6.0 * scale),
      _carShadowPaint,
    );

    // Koło
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(pos.dx, pos.dy - 4.5 * scale),
              width: 4.5 * scale,
              height: 9.0 * scale),
          Radius.circular(2.0 * scale)),
      _carWheelPaint,
    );

    // Karoseria
    final bodyRect = Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 12.0 * scale),
        width: motoW,
        height: 10.0 * scale);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, Radius.circular(3.0 * scale)),
        _motoBodyPaint);

    // Kierowca i sędzia
    canvas.drawCircle(Offset(pos.dx, pos.dy - 17.0 * scale), 3.5 * scale,
        Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(
        Offset(pos.dx, pos.dy - 21.5 * scale), 3.0 * scale, _motoHelmetPaint);

    // Tablica różnic czasowych (Ardoisier)
    final boardRect = Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 26.0 * scale),
        width: 14.0 * scale,
        height: 8.0 * scale);
    canvas.drawRect(boardRect, Paint()..color = const Color(0xFF0F172A));
    canvas.drawRect(
        boardRect,
        Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    if (scale >= 0.4) {
      final timePainter = TextPainter(
        text: const TextSpan(
          text: '+1\'25"',
          style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 6.0,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      timePainter.paint(
          canvas,
          Offset(pos.dx - timePainter.width * 0.5,
              boardRect.center.dy - timePainter.height * 0.5));
    }
  }

  // ===========================================================================
  // 9. POMOCNICZE DETALE DACHU I AKCJI BIDONU
  // ===========================================================================

  /// Bagażnik dachowy z 3 zapasowymi rowerami w kolorach drużyny
  void _drawRoofRackWithBikes(
      Canvas canvas, Offset roofCenter, double scale, Color teamColor) {
    final double rackW = 28.0 * scale;
    final double rackH = 15.0 * scale;
    final double halfW = rackW * 0.5;

    // Belki poprzeczne bagażnika dachowego
    canvas.drawLine(Offset(roofCenter.dx - halfW, roofCenter.dy),
        Offset(roofCenter.dx + halfW, roofCenter.dy), _roofRackPaint);
    canvas.drawLine(
        Offset(roofCenter.dx - halfW, roofCenter.dy - 2.5 * scale),
        Offset(roofCenter.dx + halfW, roofCenter.dy - 2.5 * scale),
        _roofRackPaint);

    // 3 rowery zamontowane pionowo obok siebie w uchwytach
    _roofBikeFramePaint.color = teamColor;
    for (int b = -1; b <= 1; b++) {
      final bx = roofCenter.dx + (b * 8.5 * scale);
      final by = roofCenter.dy - 2.5 * scale;

      // Trójkąt ramy roweru
      final framePath = Path()
        ..moveTo(bx - 3.5 * scale, by)
        ..lineTo(bx, by - (rackH * 0.75))
        ..lineTo(bx + 3.5 * scale, by)
        ..close();
      canvas.drawPath(framePath, _roofBikeFramePaint);

      // Koła rowerów
      canvas.drawCircle(Offset(bx - 3.5 * scale, by - 3.0 * scale), 2.5 * scale,
          _roofBikeWheelPaint);
      canvas.drawCircle(Offset(bx + 3.5 * scale, by - 3.0 * scale), 2.5 * scale,
          _roofBikeWheelPaint);

      // Kierownica i siodełko
      canvas.drawLine(Offset(bx - 0.5 * scale, by - (rackH * 0.8)),
          Offset(bx + 1.5 * scale, by - (rackH * 0.8)), _roofRackPaint);
    }
  }

  /// Bagażnik dachowy z zapasowymi kołami szosowymi w wozie neutralnym
  void _drawRoofRackWithSpareWheels(
      Canvas canvas, Offset roofCenter, double scale) {
    final double rackW = 26.0 * scale;
    final double halfW = rackW * 0.5;

    canvas.drawLine(Offset(roofCenter.dx - halfW, roofCenter.dy),
        Offset(roofCenter.dx + halfW, roofCenter.dy), _roofRackPaint);

    // 4 koła zapasowe (czarne karbonowe stożki ze srebrnymi szprychami)
    for (int w = -2; w <= 1; w++) {
      final wx = roofCenter.dx + (w * 5.8 * scale) + (2.9 * scale);
      final wy = roofCenter.dy - 7.5 * scale;
      canvas.drawCircle(Offset(wx, wy), 4.5 * scale, _roofBikeWheelPaint);
      canvas.drawCircle(
          Offset(wx, wy),
          3.5 * scale,
          Paint()
            ..color = const Color(0xFF334155)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
    }
  }

  /// Animacja wysuniętej ręki dyrektora sportowego przez okno podającego bidon (Sticky Bottle)
  void _drawStickyBottleHandout(
      Canvas canvas, Offset pos, double scale, double sideSign) {
    final armStartX = pos.dx + (sideSign * 16.0 * scale);
    final armStartY = pos.dy - 12.0 * scale;
    final armEndX = armStartX + (sideSign * 8.0 * scale);

    // Ramię dyrektora sportowego
    canvas.drawLine(
      Offset(armStartX, armStartY),
      Offset(armEndX, armStartY + 1.5 * scale),
      _bidonArmPaint
        ..strokeWidth = 2.4 * scale
        ..strokeCap = StrokeCap.round,
    );

    // Bidon w dłoni
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(
                  armEndX + (sideSign * 2.0 * scale), armStartY + 1.5 * scale),
              width: 3.0 * scale,
              height: 6.0 * scale),
          Radius.circular(1.2 * scale)),
      _bidonBottlePaint,
    );
  }

  // ===========================================================================
  // 10. POMOCNICZE METODY TELEMETRII I KOLORÓW
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

  double _calculateElevationAt(double distMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return 450.0;
    final km = distMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        final len = math.max(0.001, seg.endKm - seg.startKm);
        final t = ((km - seg.startKm) / len).clamp(0.0, 1.0);
        return seg.startElevationM +
            (seg.endElevationM - seg.startElevationM) * t;
      }
    }
    return segments.last.endElevationM;
  }

  double _calculateGradientAt(double distMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return 3.5;
    final km = distMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        return seg.gradientPercent;
      }
    }
    return segments.last.gradientPercent;
  }
}
