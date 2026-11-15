// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import 'peloton_instanced_renderer.dart';
import 'scene_3d_math_projection.dart';

/// Konfiguracja parametrów symulatora i renderera cząsteczek atmosferycznych 3D.
class WeatherParticlesRendererConfig {
  /// Maksymalna liczba kropel deszczu w buforze rzutni ekranowej.
  final int maxRaindropsCount;

  /// Maksymalna liczba cząsteczek pióropusza wodnego (spray) z kół kolarzy.
  final int maxSprayParticlesCount;

  /// Maksymalna liczba cząsteczek tumanów kurzu i pyłu szutrowego/brukowego.
  final int maxDustParticlesCount;

  /// Czy aktywny jest deszcz i ulewa w etapie mokrym.
  final bool enableRain;

  /// Czy aktywny jest pióropusz wody wyrzucany spod opon w deszczu.
  final bool enableWaterSpray;

  /// Czy aktywna jest mgła wysokogórska na szczytach Hors Categorie.
  final bool enableAlpineFog;

  /// Czy aktywne są chmury kurzu na sektorach szutru (Strade) i bruku.
  final bool enableDustPlumes;

  /// Czy renderować mikrokropelki wody i wilgoci na obiektywie kamery telewizyjnej.
  final bool enableLensMoisture;

  const WeatherParticlesRendererConfig({
    this.maxRaindropsCount = 450,
    this.maxSprayParticlesCount = 220,
    this.maxDustParticlesCount = 220,
    this.enableRain = true,
    this.enableWaterSpray = true,
    this.enableAlpineFog = true,
    this.enableDustPlumes = true,
    this.enableLensMoisture = true,
  });
}

/// Telemetria środowiskowa i atmosferyczna przekazywana w każdej klatce animacji.
class WeatherSystemTelemetry {
  /// Warunki pogodowe etapu (np. słonecznie, ulewa, mżawka, wichura).
  final WeatherCondition weatherCondition;

  /// Prędkość wiatru w km/h.
  final double windSpeedKmh;

  /// Kąt kierunku skąd wieje wiatr [stopnie: 0-360°].
  final double windDirectionDegrees;

  /// Azymut kamery / kierunek obserwacji szosy [radiany].
  final double cameraBearingRadians;

  /// Bieżąca wysokość n.p.m. kolarza lub kamery [m].
  final double currentElevationMeters;

  /// Czy odcinek trasy posiada klasyfikację górską Hors Categorie (HC).
  final bool isHorsCategorie;

  /// Typ nawierzchni aktualnego sektora szosy (asfalt, szuter Strade, bruk).
  final SegmentSurfaceType currentSurfaceType;

  /// Czas trwania klatki w sekundach (dt).
  final double dtSeconds;

  /// Całkowity czas animacji w sekundach.
  final double elapsedSeconds;

  const WeatherSystemTelemetry({
    required this.weatherCondition,
    this.windSpeedKmh = 14.0,
    this.windDirectionDegrees = 180.0,
    this.cameraBearingRadians = 0.0,
    this.currentElevationMeters = 450.0,
    this.isHorsCategorie = false,
    this.currentSurfaceType = SegmentSurfaceType.smoothAsphalt,
    this.dtSeconds = 0.016,
    this.elapsedSeconds = 0.0,
  });

  /// Czy nawierzchnia jest mokra od deszczu lub ulewy.
  bool get isWetWeather =>
      weatherCondition == WeatherCondition.lightRain ||
      weatherCondition == WeatherCondition.heavyStorm;

  /// Czy warunki sprzyjają unoszeniu się kurzu na szutrze i bruku (sucho i wietrznie).
  bool get isDryDustCondition =>
      !isWetWeather &&
      (currentSurfaceType == SegmentSurfaceType.gravelStrade ||
          currentSurfaceType.name.contains('cobble'));
}

/// Pojedyncza kropla deszczu w przestrzeni ekranowej.
class _RaindropParticle {
  double x = 0.0;
  double y = 0.0;
  double length = 20.0;
  double speedY = 600.0;
  double driftX = 0.0;
  double thickness = 1.2;
  double alpha = 0.5;

  void reset(double viewportWidth, double viewportHeight, math.Random random, double windDriftX, bool isHeavy) {
    x = random.nextDouble() * (viewportWidth + 200.0) - 100.0;
    y = -random.nextDouble() * 200.0;
    driftX = windDriftX;

    if (isHeavy) {
      speedY = 850.0 + (random.nextDouble() * 450.0);
      length = 26.0 + (random.nextDouble() * 22.0);
      thickness = 1.6 + (random.nextDouble() * 0.8);
      alpha = 0.45 + (random.nextDouble() * 0.35);
    } else {
      speedY = 550.0 + (random.nextDouble() * 300.0);
      length = 14.0 + (random.nextDouble() * 12.0);
      thickness = 1.0 + (random.nextDouble() * 0.5);
      alpha = 0.25 + (random.nextDouble() * 0.25);
    }
  }
}

/// Pojedyncza cząsteczka pióropusza wody (spray) wyrzucana z opony kolarza w 3D.
class _WaterSprayParticle {
  bool active = false;
  final Vector3 position = Vector3.zero();
  final Vector3 velocity = Vector3.zero();
  double age = 0.0;
  double maxLifetime = 0.38;
  double startRadius = 0.06;
  double endRadius = 0.45;
  double initialAlpha = 0.65;

  void spawn({
    required Vector3 originWorld,
    required Vector3 initialVelocity,
    double lifetime = 0.38,
    double radiusStart = 0.06,
    double radiusEnd = 0.45,
    double alpha = 0.65,
  }) {
    active = true;
    position.setFrom(originWorld);
    velocity.setFrom(initialVelocity);
    age = 0.0;
    maxLifetime = lifetime;
    startRadius = radiusStart;
    endRadius = radiusEnd;
    initialAlpha = alpha;
  }

  void update(double dt) {
    if (!active) return;
    age += dt;
    if (age >= maxLifetime) {
      active = false;
      return;
    }
    // Ruch cząsteczki z tłumieniem oporu powietrza i grawitacją
    position.addScaled(velocity, dt);
    velocity.y -= 3.2 * dt; // Grawitacja na kropelkach
    velocity.scale(1.0 - (1.8 * dt).clamp(0.0, 1.0)); // Opór powietrza
  }

  double get progress => (age / maxLifetime).clamp(0.0, 1.0);
  double get currentRadius => startRadius + (endRadius - startRadius) * progress;
  double get currentAlpha => (initialAlpha * (1.0 - progress)).clamp(0.0, 1.0);
}

/// Pojedynczy obłok kurzu i pyłu szutrowego (dust puff) w przestrzeni 3D.
class _DustPuffParticle {
  bool active = false;
  final Vector3 position = Vector3.zero();
  final Vector3 velocity = Vector3.zero();
  double age = 0.0;
  double maxLifetime = 1.1;
  double startRadius = 0.12;
  double endRadius = 1.35;
  double initialAlpha = 0.45;
  Color baseColor = const Color(0xFFD2C4B0);

  void spawn({
    required Vector3 originWorld,
    required Vector3 initialVelocity,
    required Color color,
    double lifetime = 1.1,
    double radiusStart = 0.12,
    double radiusEnd = 1.35,
    double alpha = 0.45,
  }) {
    active = true;
    position.setFrom(originWorld);
    velocity.setFrom(initialVelocity);
    baseColor = color;
    age = 0.0;
    maxLifetime = lifetime;
    startRadius = radiusStart;
    endRadius = radiusEnd;
    initialAlpha = alpha;
  }

  void update(double dt) {
    if (!active) return;
    age += dt;
    if (age >= maxLifetime) {
      active = false;
      return;
    }
    position.addScaled(velocity, dt);
    velocity.y += 0.4 * dt; // Ciepły pył delikatnie unosi się w górę
    velocity.scale(1.0 - (1.2 * dt).clamp(0.0, 1.0)); // Wyhamowywanie w powietrzu
  }

  double get progress => (age / maxLifetime).clamp(0.0, 1.0);
  double get currentRadius => startRadius + (endRadius - startRadius) * math.pow(progress, 0.65);
  double get currentAlpha => (initialAlpha * (1.0 - progress)).clamp(0.0, 1.0);
}

/// Zaawansowany system i renderer efektów atmosferycznych 3D w wyścigu kolarskim.
///
/// Funkcjonalności:
/// 1. Deszcz i ulewa:
///    - Krople spadające pod kątem wynikającym z prędkości i kierunku wiatru względem kamery,
///    - Aerodynamiczne pióropusze wody (water spray / rooster tails) wyrzucane spod tylnych kół peletonu,
///    - Błyski wyładowań atmosferycznych podczas ulewy (`heavyStorm`).
/// 2. Mgła wysokogórska:
///    - Dynamiczne ograniczenie widoczności na szczytach Hors Categorie i powyżej 1800m n.p.m.,
///    - Welony mgielne i niskie chmury przetaczające się przez szosę i granie skalne,
///    - Subtelna kondensacja i wilgoć na obiektywie kamery telewizyjnej.
/// 3. Kurz i pył szutrowy (Strade Bianche & Bruk):
///    - Kłęby jasnego, kredowego pyłu unoszące się za tylnymi kołami kolarzy na sektorach szutru i bruku.
class WeatherParticlesRenderer {
  final WeatherParticlesRendererConfig config;

  // Pula prealokowanych cząsteczek (Zero-allocation GC protection)
  late final List<_RaindropParticle> _raindrops;
  late final List<_WaterSprayParticle> _sprayPool;
  late final List<_DustPuffParticle> _dustPool;

  int _nextSprayIndex = 0;
  int _nextDustIndex = 0;

  final math.Random _random = math.Random(101);

  // Prealokowane obiekty farb (Paint cache)
  late final Paint _rainPaint;
  late final Paint _sprayPaint;
  late final Paint _dustPaint;
  late final Paint _fogGradientPaint;
  late final Paint _lightningPaint;
  late final Paint _lensDropletPaint;

  // Stan wyładowań atmosferycznych i błysków
  double _lightningTimerSeconds = 0.0;
  double _lightningFlashAlpha = 0.0;

  WeatherParticlesRenderer({
    this.config = const WeatherParticlesRendererConfig(),
  }) {
    _initParticlePools();
    _initPaints();
  }

  void _initParticlePools() {
    _raindrops = List.generate(config.maxRaindropsCount, (_) => _RaindropParticle());
    _sprayPool = List.generate(config.maxSprayParticlesCount, (_) => _WaterSprayParticle());
    _dustPool = List.generate(config.maxDustParticlesCount, (_) => _DustPuffParticle());
  }

  void _initPaints() {
    _rainPaint = Paint()
      ..color = const Color(0xC0E2F1F8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _sprayPaint = Paint()
      ..color = const Color(0x60BCE4F7)
      ..style = PaintingStyle.fill;

    _dustPaint = Paint()..style = PaintingStyle.fill;

    _fogGradientPaint = Paint()..style = PaintingStyle.fill;

    _lightningPaint = Paint()
      ..color = const Color(0x28FFFFFF)
      ..style = PaintingStyle.fill;

    _lensDropletPaint = Paint()
      ..color = const Color(0x35FFFFFF)
      ..style = PaintingStyle.fill;
  }

  // ===========================================================================
  // 1. GŁÓWNA AKTUALIZACJA SYMULACJI CZĄSTECZEK (TICK / UPDATE)
  // ===========================================================================

  /// Aktualizuje stan fizyczny cząsteczek o krok czasowy `dt`.
  void update({
    required WeatherSystemTelemetry telemetry,
    required double viewportWidth,
    required double viewportHeight,
    List<PelotonRenderItem> activeRiders = const [],
  }) {
    final double dt = telemetry.dtSeconds.clamp(0.001, 0.05);

    // 1. Aktualizacja kropel deszczu
    if (config.enableRain && telemetry.isWetWeather) {
      _updateRaindrops(telemetry, viewportWidth, viewportHeight, dt);
    }

    // 2. Aktualizacja pióropuszy wody (spray) spod kół kolarzy
    if (config.enableWaterSpray) {
      _updateWaterSpray(telemetry, activeRiders, dt);
    }

    // 3. Aktualizacja chmur pyłu na szutrze i bruku
    if (config.enableDustPlumes) {
      _updateDustPlumes(telemetry, activeRiders, dt);
    }

    // 4. Błyskawice w trakcie gwałtownej ulewy (heavyStorm)
    if (telemetry.weatherCondition == WeatherCondition.heavyStorm) {
      _updateLightning(dt);
    } else {
      _lightningFlashAlpha = 0.0;
    }
  }

  void _updateRaindrops(
    WeatherSystemTelemetry telemetry,
    double w,
    double h,
    double dt,
  ) {
    final bool isHeavy = telemetry.weatherCondition == WeatherCondition.heavyStorm;

    // Obliczenie składowej bocznej wiatru względem kamery
    final double windAngleRad = telemetry.windDirectionDegrees * math.pi / 180.0;
    final double relWindAngle = windAngleRad - telemetry.cameraBearingRadians;
    final double crosswindMs = math.sin(relWindAngle) * (telemetry.windSpeedKmh / 3.6);
    final double driftX = crosswindMs * 28.0;

    final int activeCount = isHeavy ? config.maxRaindropsCount : (config.maxRaindropsCount * 0.45).round();

    for (int i = 0; i < activeCount; i++) {
      final drop = _raindrops[i];
      drop.x += drop.driftX * dt;
      drop.y += drop.speedY * dt;

      // Zawijanie cząsteczek na krawędziach ekranu
      if (drop.y > h + 50.0 || drop.x < -120.0 || drop.x > w + 120.0) {
        drop.reset(w, h, _random, driftX, isHeavy);
      }
    }
  }

  void _updateWaterSpray(
    WeatherSystemTelemetry telemetry,
    List<PelotonRenderItem> activeRiders,
    double dt,
  ) {
    // Krok 1: Przesunięcie i starzenie istniejących cząsteczek sprayu
    for (final p in _sprayPool) {
      if (p.active) p.update(dt);
    }

    // Krok 2: Emisja nowych cząsteczek sprayu z tylnych kół kolarzy jadących po mokrej nawierzchni
    if (!telemetry.isWetWeather || activeRiders.isEmpty) return;

    for (final rider in activeRiders) {
      // Pióropusz generujemy dla kolarzy w zasięgu widzenia kamery (<55m) i jadących > 14 km/h
      if (rider.cameraDistance > 55.0 || rider.snapshot.speedKmh < 14.0) continue;

      final double speedRatio = (rider.snapshot.speedKmh / 50.0).clamp(0.2, 1.4);

      // Pozycja styku tylnego koła z podłożem (około 0.50m za suportem)
      final rearWheelGround = rider.worldPosition - (rider.tangent * 0.50);

      // Wektor wyrzutu wody: w tył, w górę oraz lekkie rozproszenie na boki
      final sprayVel = (-rider.tangent * (rider.snapshot.speedMs * 0.42 * speedRatio)) +
          (rider.up * (rider.snapshot.speedMs * 0.28 * speedRatio)) +
          (rider.right * ((_random.nextDouble() - 0.5) * 1.8));

      // Emisja z puli cyklicznej
      final p = _sprayPool[_nextSprayIndex];
      _nextSprayIndex = (_nextSprayIndex + 1) % _sprayPool.length;

      p.spawn(
        originWorld: rearWheelGround + Vector3(0.0, 0.05, 0.0),
        initialVelocity: sprayVel,
        lifetime: 0.32 + (_random.nextDouble() * 0.12),
        radiusStart: 0.05 * speedRatio,
        radiusEnd: 0.38 * speedRatio,
        alpha: (0.45 * speedRatio).clamp(0.2, 0.75),
      );
    }
  }

  void _updateDustPlumes(
    WeatherSystemTelemetry telemetry,
    List<PelotonRenderItem> activeRiders,
    double dt,
  ) {
    // Krok 1: Przesunięcie i starzenie istniejących obłoków kurzu
    for (final p in _dustPool) {
      if (p.active) p.update(dt);
    }

    // Krok 2: Emisja pyłu szutrowego / brukowego (gdy jest sucho i kolarze jadą szybko)
    if (!telemetry.isDryDustCondition || activeRiders.isEmpty) return;

    final Color dustColor = (telemetry.currentSurfaceType == SegmentSurfaceType.gravelStrade)
        ? const Color(0xD8E0D4C2) // Jasna toskańska kreda Strade Bianche
        : const Color(0xB5B0A698); // Szary pył suchych bruków Roubaix

    for (final rider in activeRiders) {
      if (rider.cameraDistance > 65.0 || rider.snapshot.speedKmh < 16.0) continue;

      final double speedRatio = (rider.snapshot.speedKmh / 45.0).clamp(0.3, 1.5);
      final rearContact = rider.worldPosition - (rider.tangent * 0.48);

      final dustVel = (-rider.tangent * (rider.snapshot.speedMs * 0.22 * speedRatio)) +
          (rider.up * (0.65 + _random.nextDouble() * 0.45)) +
          (rider.right * ((_random.nextDouble() - 0.5) * 1.4));

      final p = _dustPool[_nextDustIndex];
      _nextDustIndex = (_nextDustIndex + 1) % _dustPool.length;

      p.spawn(
        originWorld: rearContact + Vector3(0.0, 0.04, 0.0),
        initialVelocity: dustVel,
        color: dustColor,
        lifetime: 0.95 + (_random.nextDouble() * 0.4),
        radiusStart: 0.10 * speedRatio,
        radiusEnd: 1.25 * speedRatio,
        alpha: 0.38 * speedRatio,
      );
    }
  }

  void _updateLightning(double dt) {
    _lightningTimerSeconds += dt;
    if (_lightningTimerSeconds > 9.0 + (_random.nextDouble() * 7.0)) {
      _lightningTimerSeconds = 0.0;
      _lightningFlashAlpha = 0.42; // Błysk pioruna
    } else if (_lightningFlashAlpha > 0.0) {
      _lightningFlashAlpha = math.max(0.0, _lightningFlashAlpha - (dt * 4.5));
    }
  }

  // ===========================================================================
  // 2. RENDEROWANIE CZĄSTECZEK 3D (WODY I PYŁU) W PRZESTRZENI ŚWIATA
  // ===========================================================================

  /// Rysuje trójwymiarowe pióropusze wody oraz tumany pyłu rzutowane na ekran.
  void renderWorldParticles({
    required Canvas canvas,
    required Scene3DMathProjection projection,
  }) {
    // 1. Rysowanie obłoków kurzu (rysujemy najpierw, pod wodą)
    if (config.enableDustPlumes) {
      for (final p in _dustPool) {
        if (!p.active) continue;

        final proj = projection.worldToScreen(p.position);
        if (!proj.isInFrontOfCamera || !proj.isInViewport) continue;

        final double screenR = (p.currentRadius * proj.perspectiveScale * 24.0).clamp(2.0, 65.0);
        _dustPaint.color = p.baseColor.withValues(alpha: p.currentAlpha);

        canvas.drawCircle(Offset(proj.screenX, proj.screenY), screenR, _dustPaint);
      }
    }

    // 2. Rysowanie pióropuszy wody spod kół (water spray)
    if (config.enableWaterSpray) {
      for (final p in _sprayPool) {
        if (!p.active) continue;

        final proj = projection.worldToScreen(p.position);
        if (!proj.isInFrontOfCamera || !proj.isInViewport) continue;

        final double screenR = (p.currentRadius * proj.perspectiveScale * 26.0).clamp(1.5, 45.0);
        _sprayPaint.color = const Color(0xFFCBEAF8).withValues(alpha: p.currentAlpha);

        canvas.drawCircle(Offset(proj.screenX, proj.screenY), screenR, _sprayPaint);
      }
    }
  }

  // ===========================================================================
  // 3. MGŁA WYSOKOGÓRSKA I CHMURY NA PRZEŁĘCZACH HC
  // ===========================================================================

  /// Renderuje pasma mgły wysokogórskiej, chmur i ograniczenia widoczności na szczytach.
  void renderAlpineFog({
    required Canvas canvas,
    required Size size,
    required double elevationMeters,
    required bool isHorsCategorie,
    required double elapsedSeconds,
    double horizonY = 320.0,
  }) {
    if (!config.enableAlpineFog) return;

    // Obliczenie współczynnika gęstości mgły na podstawie wysokości n.p.m.
    double fogFactor = 0.0;
    if (elevationMeters >= 1700.0) {
      fogFactor = ((elevationMeters - 1700.0) / 750.0).clamp(0.0, 1.0);
    }
    if (isHorsCategorie) {
      fogFactor = math.max(fogFactor, 0.45);
    }

    if (fogFactor <= 0.05) return;

    final double w = size.width;

    // 1. Atmosferyczna kurtyna mgielna wokół horyzontu (Depth Fog Veil)
    final fogGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        const Color(0xFFE2E8F0).withValues(alpha: 0.35 * fogFactor),
        const Color(0xFFCBD5E1).withValues(alpha: 0.55 * fogFactor),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.35, 0.70, 1.0],
    );

    final fogRect = Rect.fromLTWH(0, horizonY - 120.0, w, 280.0);
    _fogGradientPaint.shader = fogGradient.createShader(fogRect);
    canvas.drawRect(fogRect, _fogGradientPaint);

    // 2. Przetaczające się pasma chmur i welonów mgielnych (Drifting Alpine Cloud Banks)
    final cloudMistPaint = Paint()..color = const Color(0xFFF1F5F9).withValues(alpha: 0.22 * fogFactor);
    final double driftOffset = (elapsedSeconds * 18.0) % (w * 1.5);

    for (int i = 0; i < 3; i++) {
      final double waveY = horizonY - 40.0 + (i * 35.0) + (math.sin(elapsedSeconds * 1.2 + i) * 12.0);
      final double waveX = ((i * 380.0 + driftOffset) % (w + 400.0)) - 200.0;
      final double cloudWidth = 280.0 + (i * 70.0);
      final double cloudHeight = 42.0 + (i * 12.0);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(waveX, waveY), width: cloudWidth, height: cloudHeight),
        cloudMistPaint,
      );
    }
  }

  // ===========================================================================
  // 4. EFEKTY EKRANOWE: DESZCZ, WICHRY, BŁYSKAWICE I KROPLE NA OBIEKTYWIE
  // ===========================================================================

  /// Rysuje dwuwymiarowe smugi deszczu, rozbłyski i wilgoć na obiektywie kamery TV.
  void renderScreenWeather({
    required Canvas canvas,
    required Size size,
    required WeatherSystemTelemetry telemetry,
  }) {
    final double w = size.width;
    final double h = size.height;

    // 1. Smugi kropel deszczu
    if (config.enableRain && telemetry.isWetWeather) {
      final bool isHeavy = telemetry.weatherCondition == WeatherCondition.heavyStorm;
      final int count = isHeavy ? config.maxRaindropsCount : (config.maxRaindropsCount * 0.45).round();

      for (int i = 0; i < count; i++) {
        final drop = _raindrops[i];
        _rainPaint.strokeWidth = drop.thickness;
        _rainPaint.color = const Color(0xC5E6F3FA).withValues(alpha: drop.alpha);

        canvas.drawLine(
          Offset(drop.x, drop.y),
          Offset(drop.x - (drop.driftX * 0.024), drop.y + drop.length),
          _rainPaint,
        );
      }
    }

    // 2. Błysk pioruna podczas nawałnicy (Thunderstorm flash)
    if (_lightningFlashAlpha > 0.01) {
      _lightningPaint.color = Colors.white.withValues(alpha: _lightningFlashAlpha);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _lightningPaint);
    }

    // 3. Rozmyte krople wody na obiektywie kamery TV (Lens Condensation Droplets)
    if (config.enableLensMoisture && telemetry.isWetWeather) {
      _drawLensDroplets(canvas, w, h, telemetry.elapsedSeconds);
    }
  }

  void _drawLensDroplets(Canvas canvas, double w, double h, double elapsedSeconds) {
    // 5 stałych punktów kondensacji na soczewce obiektywu
    final dropletSpots = [
      (w * 0.12, h * 0.18, 14.0),
      (w * 0.88, h * 0.22, 18.0),
      (w * 0.08, h * 0.82, 16.0),
      (w * 0.84, h * 0.78, 20.0),
      (w * 0.48, h * 0.08, 12.0),
    ];

    for (int i = 0; i < dropletSpots.length; i++) {
      final spot = dropletSpots[i];
      final double r = spot.$3;
      final double wobble = math.sin(elapsedSeconds * 1.5 + i) * 1.5;

      // Półprzezroczysty krążek z jaśniejszym refleksem
      _lensDropletPaint.color = Colors.white.withValues(alpha: 0.14);
      canvas.drawCircle(Offset(spot.$1, spot.$2 + wobble), r, _lensDropletPaint);

      final rimPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(spot.$1, spot.$2 + wobble), r, rimPaint);
    }
  }

  // ===========================================================================
  // 5. ZBIORCZA METODA RENDEROWANIA WSZYSTKICH WARSTW POGODOWYCH
  // ===========================================================================

  /// Renderuje kompletny potok efektów atmosferycznych we właściwej kolejności głębokości:
  /// Mgła górska -> Cząsteczki 3D (Spray i Kurz) -> Deszcz i wilgoć na obiektywie.
  void renderAll({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required WeatherSystemTelemetry telemetry,
    List<PelotonRenderItem> activeRiders = const [],
    double horizonY = 320.0,
  }) {
    // 1. Warstwa tła: mgła wysokogórska
    renderAlpineFog(
      canvas: canvas,
      size: size,
      elevationMeters: telemetry.currentElevationMeters,
      isHorsCategorie: telemetry.isHorsCategorie,
      elapsedSeconds: telemetry.elapsedSeconds,
      horizonY: horizonY,
    );

    // 2. Warstwa świata 3D: pióropusze wody z kół i chmury pyłu
    renderWorldParticles(
      canvas: canvas,
      projection: projection,
    );

    // 3. Warstwa pierwszoplanowa: krople deszczu i obiektyw kamery
    renderScreenWeather(
      canvas: canvas,
      size: size,
      telemetry: telemetry,
    );
  }
}

