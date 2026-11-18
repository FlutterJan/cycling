// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Presety scenariuszy hamowania 3D dla wizualizacji nagrzanych tarcz i dymu opony.
enum BrakingScenarioPreset {
  /// Ekstremalne hamowanie przed nawrotem 180° na zjeździe (subtelna czerwona poświata tarcz).
  hairpin180Approach(
    label: 'Nawrót 180°',
    description: 'Mocne dohamowanie z 78 km/h przed ciasnym nawrotem',
    speedKmh: 78.0,
    brakePressureRatio: 0.84,
    roadGradientPercent: -9.5,
    cornerCurvature180Ratio: 0.95,
    asphaltWetness: 0.05,
  ),

  /// Awaryjne hamowanie na stromym zjeździe z blokadą tylnego koła, dymem i piskiem.
  emergencyDescentLockup(
    label: 'Awaryjne na zjeździe',
    description: 'Zblokowana tylna opona, krótki ślad dymu i pisk gumy',
    speedKmh: 84.0,
    brakePressureRatio: 0.96,
    roadGradientPercent: -12.0,
    cornerCurvature180Ratio: 0.72,
    asphaltWetness: 0.0,
  ),

  /// Zjazd w deszczu: wyższe chłodzenie wodą i lekka mgiełka pary zamiast gęstego dymu.
  wetSwitchbackModulation(
    label: 'Mokry serpentyn',
    description: 'Chłodzenie tarcz przez wodę i modulacja na śliskim asfalcie',
    speedKmh: 62.0,
    brakePressureRatio: 0.68,
    roadGradientPercent: -8.0,
    cornerCurvature180Ratio: 0.80,
    asphaltWetness: 0.78,
  ),

  /// Spokojna kontrola prędkości w peletonie bez przegrzewania tarcz.
  pelotonCoastControl(
    label: 'Kontrola w peletonie',
    description: 'Lekkie przyhamowanie bez poświaty i uślizgu opony',
    speedKmh: 46.0,
    brakePressureRatio: 0.24,
    roadGradientPercent: -3.5,
    cornerCurvature180Ratio: 0.15,
    asphaltWetness: 0.0,
  );

  final String label;
  final String description;
  final double speedKmh;
  final double brakePressureRatio;
  final double roadGradientPercent;
  final double cornerCurvature180Ratio;
  final double asphaltWetness;

  const BrakingScenarioPreset({
    required this.label,
    required this.description,
    required this.speedKmh,
    required this.brakePressureRatio,
    required this.roadGradientPercent,
    required this.cornerCurvature180Ratio,
    required this.asphaltWetness,
  });
}

/// Strefa termiczna tarczy hamulcowej.
enum BrakeRotorThermalZone {
  /// Chłodna tarcza (< 180 °C) — czysta stal bez poświaty.
  cool('Chłodna'),

  /// Rozgrzana tarcza (180–320 °C) — lekki odcień cieplny.
  warm('Rozgrzana'),

  /// Gorąca tarcza (320–500 °C) — subtelna wiśniowo-czerwona poświata.
  hot('Gorąca'),

  /// Ekstremalna temperatura (> 500 °C) — wyraźna czerwona poświata i ryzyko fadingu.
  critical('Ekstremalna');

  final String label;

  const BrakeRotorThermalZone(this.label);
}

/// Poziom intensywności pisku zblokowanej tylnej opony.
enum TireScreechIntensity {
  /// Brak pisku.
  none('Brak'),

  /// Krótki pisk przy początkowym uślizgu.
  chirp('Krótki pisk'),

  /// Ciągły pisk poślizgu na asfalcie.
  sustainedSkid('Poślizg ciągły'),

  /// Głośny pisk pełnej blokady tylnego koła.
  emergencyLockup('Blokada awaryjna');

  final String label;

  const TireScreechIntensity(this.label);
}

/// Parametry fizyczne i wizualne efektu nagrzanych tarcz oraz dymu opony.
class BrakeRotorAndTireSmokeConfig {
  /// Temperatura otoczenia [°C].
  final double ambientTempCelsius;

  /// Masa pojedynczej tarczy hamulcowej [kg] (ok. 115 g dla 140/160 mm).
  final double rotorMassKg;

  /// Ciepło właściwe stali nierdzewnej tarczy [J/(kg*K)].
  final double specificHeatJPerKgK;

  /// Współczynnik konwekcyjnego chłodzenia powietrzem.
  final double coolingCoefficient;

  /// Bazowy rozkład siły hamowania na przód `[0.55, 0.80]`.
  final double frontBrakeBias;

  /// Temperatura początku widocznej czerwonej poświaty [°C].
  final double glowStartTempCelsius;

  /// Temperatura pełnej (subtelnej) poświaty tarczy [°C].
  final double glowFullTempCelsius;

  /// Próg poślizgu tylnego koła aktywujący dym i pisk `[0.15, 0.60]`.
  final double rearLockupSlipThreshold;

  /// Maksymalna liczba aktywnych cząsteczek dymu w puli.
  final int maxSmokeParticles;

  /// Maksymalna liczba segmentów śladu opony na asfalcie.
  final int maxSkidMarks;

  /// Mnożnik chłodzenia tarczy na mokrym asfalcie.
  final double wetCoolingMultiplier;

  const BrakeRotorAndTireSmokeConfig({
    this.ambientTempCelsius = 22.0,
    this.rotorMassKg = 0.115,
    this.specificHeatJPerKgK = 490.0,
    this.coolingCoefficient = 0.08,
    this.frontBrakeBias = 0.68,
    this.glowStartTempCelsius = 210.0,
    this.glowFullTempCelsius = 540.0,
    this.rearLockupSlipThreshold = 0.28,
    this.maxSmokeParticles = 48,
    this.maxSkidMarks = 36,
    this.wetCoolingMultiplier = 1.75,
  });

  BrakeRotorAndTireSmokeConfig copyWith({
    double? ambientTempCelsius,
    double? rotorMassKg,
    double? specificHeatJPerKgK,
    double? coolingCoefficient,
    double? frontBrakeBias,
    double? glowStartTempCelsius,
    double? glowFullTempCelsius,
    double? rearLockupSlipThreshold,
    int? maxSmokeParticles,
    int? maxSkidMarks,
    double? wetCoolingMultiplier,
  }) {
    return BrakeRotorAndTireSmokeConfig(
      ambientTempCelsius: ambientTempCelsius ?? this.ambientTempCelsius,
      rotorMassKg: rotorMassKg ?? this.rotorMassKg,
      specificHeatJPerKgK: specificHeatJPerKgK ?? this.specificHeatJPerKgK,
      coolingCoefficient: coolingCoefficient ?? this.coolingCoefficient,
      frontBrakeBias: frontBrakeBias ?? this.frontBrakeBias,
      glowStartTempCelsius: glowStartTempCelsius ?? this.glowStartTempCelsius,
      glowFullTempCelsius: glowFullTempCelsius ?? this.glowFullTempCelsius,
      rearLockupSlipThreshold:
          rearLockupSlipThreshold ?? this.rearLockupSlipThreshold,
      maxSmokeParticles: maxSmokeParticles ?? this.maxSmokeParticles,
      maxSkidMarks: maxSkidMarks ?? this.maxSkidMarks,
      wetCoolingMultiplier: wetCoolingMultiplier ?? this.wetCoolingMultiplier,
    );
  }
}

/// Dane wejściowe pojedynczej klatki dla symulacji hamowania 3D.
class BrakeAndTireTelemetryInput {
  /// Aktualna prędkość jazdy [km/h].
  final double speedKmh;

  /// Nacisk na klamki hamulcowe `[0.0, 1.0]`.
  final double brakePressureRatio;

  /// Nachylenie drogi [%] (wartości ujemne oznaczają zjazd).
  final double roadGradientPercent;

  /// Stopień ostrości zbliżającego się nawrotu 180° `[0.0, 1.0]`.
  final double cornerCurvature180Ratio;

  /// Łączna masa kolarza i roweru [kg].
  final double riderTotalMassKg;

  /// Wilgotność asfaltu `[0.0, 1.0]`.
  final double asphaltWetness;

  /// Aktualny kąt obrotu kół [rad].
  final double wheelAngleRadians;

  /// Pozycja kolarza w świecie 3D [m].
  final double riderWorldX;
  final double riderWorldY;
  final double riderWorldZ;

  /// Kąt kierunku jazdy [rad].
  final double headingRadians;

  /// Krok czasowy klatki [s].
  final double dtSeconds;

  const BrakeAndTireTelemetryInput({
    required this.speedKmh,
    required this.brakePressureRatio,
    required this.roadGradientPercent,
    this.cornerCurvature180Ratio = 0.0,
    this.riderTotalMassKg = 74.0,
    this.asphaltWetness = 0.0,
    this.wheelAngleRadians = 0.0,
    this.riderWorldX = 0.0,
    this.riderWorldY = 0.0,
    this.riderWorldZ = 0.0,
    this.headingRadians = 0.0,
    this.dtSeconds = 1.0 / 60.0,
  });

  BrakeAndTireTelemetryInput copyWith({
    double? speedKmh,
    double? brakePressureRatio,
    double? roadGradientPercent,
    double? cornerCurvature180Ratio,
    double? riderTotalMassKg,
    double? asphaltWetness,
    double? wheelAngleRadians,
    double? riderWorldX,
    double? riderWorldY,
    double? riderWorldZ,
    double? headingRadians,
    double? dtSeconds,
  }) {
    return BrakeAndTireTelemetryInput(
      speedKmh: speedKmh ?? this.speedKmh,
      brakePressureRatio: brakePressureRatio ?? this.brakePressureRatio,
      roadGradientPercent: roadGradientPercent ?? this.roadGradientPercent,
      cornerCurvature180Ratio:
          cornerCurvature180Ratio ?? this.cornerCurvature180Ratio,
      riderTotalMassKg: riderTotalMassKg ?? this.riderTotalMassKg,
      asphaltWetness: asphaltWetness ?? this.asphaltWetness,
      wheelAngleRadians: wheelAngleRadians ?? this.wheelAngleRadians,
      riderWorldX: riderWorldX ?? this.riderWorldX,
      riderWorldY: riderWorldY ?? this.riderWorldY,
      riderWorldZ: riderWorldZ ?? this.riderWorldZ,
      headingRadians: headingRadians ?? this.headingRadians,
      dtSeconds: dtSeconds ?? this.dtSeconds,
    );
  }
}

/// Stan termiczny i wizualny obu tarcz hamulcowych.
class BrakeRotorThermalState {
  final double frontTempCelsius;
  final double rearTempCelsius;

  /// Subtelna intensywność czerwonej poświaty `[0.0, 1.0]`.
  final double frontGlowIntensity;
  final double rearGlowIntensity;

  final BrakeRotorThermalZone frontZone;
  final BrakeRotorThermalZone rearZone;

  /// Łączna moc cieplna wydzielana na tarczach [W].
  final double thermalPowerWatts;

  /// Ryzyko przegrzania / utraty skuteczności (brake fade) `[0.0, 1.0]`.
  final double fadeRiskRatio;

  const BrakeRotorThermalState({
    required this.frontTempCelsius,
    required this.rearTempCelsius,
    required this.frontGlowIntensity,
    required this.rearGlowIntensity,
    required this.frontZone,
    required this.rearZone,
    required this.thermalPowerWatts,
    required this.fadeRiskRatio,
  });
}

/// Pojedyncza cząsteczka krótkiego śladu dymu spod tylnej opony w przestrzeni 3D.
class TireSmokeParticle3D {
  final double x;
  final double y;
  final double z;
  final double vx;
  final double vy;
  final double vz;
  final double ageSeconds;
  final double lifetimeSeconds;
  final double radiusMeters;
  final double opacity;
  final bool isSteam;

  const TireSmokeParticle3D({
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.ageSeconds,
    required this.lifetimeSeconds,
    required this.radiusMeters,
    required this.opacity,
    required this.isSteam,
  });

  double get lifeProgress =>
      lifetimeSeconds <= 0.0 ? 1.0 : (ageSeconds / lifetimeSeconds).clamp(0.0, 1.0);
}

/// Krótki ślad czarnej gumy zostawiany na asfalcie przy blokadzie tylnego koła.
class TireSkidMarkSegment3D {
  final double startX;
  final double startZ;
  final double endX;
  final double endZ;
  final double y;
  final double opacity;
  final double widthMeters;

  const TireSkidMarkSegment3D({
    required this.startX,
    required this.startZ,
    required this.endX,
    required this.endZ,
    required this.y,
    required this.opacity,
    required this.widthMeters,
  });
}

/// Sygnał audio pisku zblokowanej tylnej opony przekazywany do miksera dźwięku.
class TireScreechAudioCue {
  final bool isTriggered;
  final TireScreechIntensity intensity;
  final double volume;
  final double frequencyHz;
  final double slipRatio;

  const TireScreechAudioCue({
    required this.isTriggered,
    required this.intensity,
    required this.volume,
    required this.frequencyHz,
    required this.slipRatio,
  });
}

/// Kompletny wynik pojedynczej klatki efektu nagrzanych tarcz i dymu tylnej opony.
class BrakeRotorAndTireSmokeFrameState {
  final BrakeRotorThermalState rotorState;
  final bool rearTireLocked;
  final double rearSlipRatio;
  final List<TireSmokeParticle3D> smokeParticles;
  final List<TireSkidMarkSegment3D> skidMarks;
  final TireScreechAudioCue screechCue;
  final double speedKmh;
  final double decelerationMs2;

  const BrakeRotorAndTireSmokeFrameState({
    required this.rotorState,
    required this.rearTireLocked,
    required this.rearSlipRatio,
    required this.smokeParticles,
    required this.skidMarks,
    required this.screechCue,
    required this.speedKmh,
    required this.decelerationMs2,
  });
}

/// Silnik fizyczno-wizualny nagrzanych tarcz hamulcowych oraz dymu/pisku tylnej opony 3D.
class GlowingBrakeRotorsAndTireSmokeEngine {
  final BrakeRotorAndTireSmokeConfig config;
  final math.Random _rng;

  double _frontRotorTempCelsius;
  double _rearRotorTempCelsius;
  double _lastSkidX = 0.0;
  double _lastSkidZ = 0.0;
  bool _hasLastSkidAnchor = false;
  double _smokeSpawnAccumulator = 0.0;

  final List<TireSmokeParticle3D> _smokeParticles = <TireSmokeParticle3D>[];
  final List<TireSkidMarkSegment3D> _skidMarks = <TireSkidMarkSegment3D>[];

  GlowingBrakeRotorsAndTireSmokeEngine({
    this.config = const BrakeRotorAndTireSmokeConfig(),
    int randomSeed = 686,
  })  : _rng = math.Random(randomSeed),
        _frontRotorTempCelsius = config.ambientTempCelsius,
        _rearRotorTempCelsius = config.ambientTempCelsius;

  double get frontRotorTempCelsius => _frontRotorTempCelsius;
  double get rearRotorTempCelsius => _rearRotorTempCelsius;

  /// Resetuje temperaturę tarcz do otoczenia i czyści aktywne cząsteczki dymu oraz ślady.
  void reset() {
    _frontRotorTempCelsius = config.ambientTempCelsius;
    _rearRotorTempCelsius = config.ambientTempCelsius;
    _smokeParticles.clear();
    _skidMarks.clear();
    _hasLastSkidAnchor = false;
    _smokeSpawnAccumulator = 0.0;
  }

  /// Wykonuje jeden krok symulacji termicznej tarcz i dynamiki uślizgu tylnej opony.
  BrakeRotorAndTireSmokeFrameState step(BrakeAndTireTelemetryInput input) {
    final double dt = input.dtSeconds.clamp(0.001, 0.1);
    final double speedKmh = input.speedKmh.clamp(0.0, 140.0);
    final double speedMs = speedKmh / 3.6;
    final double brakePressure = input.brakePressureRatio.clamp(0.0, 1.0);
    final double wetness = input.asphaltWetness.clamp(0.0, 1.0);
    final double hairpinFactor = input.cornerCurvature180Ratio.clamp(0.0, 1.0);
    final double massKg = input.riderTotalMassKg.clamp(50.0, 130.0);

    // Nachylenie zjazdu zwiększa obciążenie cieplne i transfer masy na przednie koło.
    final double descentSeverity =
        ((-input.roadGradientPercent).clamp(0.0, 22.0)) / 22.0;

    // Przyczepność spada na mokrym asfalcie, co ułatwia zblokowanie odciążonego tyłu.
    final double surfaceGrip = 1.0 - (wetness * 0.42);
    final double maxDecelMs2 = (8.8 * surfaceGrip).clamp(3.2, 9.5);
    final double decelerationMs2 = brakePressure * maxDecelMs2;

    // Moc hamowania P = m * a * v (z lekkim wzmocnieniem dla ekstremalnego dohamowania przed 180°).
    final double hairpinThermalBoost = 1.0 + (hairpinFactor * 0.28);
    final double totalBrakingWatts =
        massKg * decelerationMs2 * speedMs * hairpinThermalBoost;

    // Dynamiczny rozkład masy na przód na zjeździe.
    final double dynamicFrontBias =
        (config.frontBrakeBias + descentSeverity * 0.12).clamp(0.58, 0.86);
    final double frontWatts = totalBrakingWatts * dynamicFrontBias;
    final double rearWatts = totalBrakingWatts * (1.0 - dynamicFrontBias);

    final double rotorHeatCapacity =
        (config.rotorMassKg * config.specificHeatJPerKgK).clamp(10.0, 200.0);

    // Około 48% energii hamowania zostaje w samej tarczy (reszta w klockach i zacisku).
    const double rotorHeatAbsorptionRatio = 0.48;
    final double frontHeatDelta =
        (frontWatts * rotorHeatAbsorptionRatio * dt) / rotorHeatCapacity;
    final double rearHeatDelta =
        (rearWatts * rotorHeatAbsorptionRatio * dt) / rotorHeatCapacity;

    // Konwekcyjne chłodzenie strumieniem powietrza + ew. wodą na mokrym asfalcie.
    final double airflowFactor = 0.35 + (speedMs / 18.0);
    final double wetFactor =
        1.0 + wetness * (config.wetCoolingMultiplier - 1.0);
    final double coolingRate =
        config.coolingCoefficient * airflowFactor * wetFactor * dt;

    _frontRotorTempCelsius = (_frontRotorTempCelsius +
            frontHeatDelta -
            (_frontRotorTempCelsius - config.ambientTempCelsius) * coolingRate)
        .clamp(config.ambientTempCelsius, 780.0);

    _rearRotorTempCelsius = (_rearRotorTempCelsius +
            rearHeatDelta -
            (_rearRotorTempCelsius - config.ambientTempCelsius) * coolingRate)
        .clamp(config.ambientTempCelsius, 740.0);

    final double frontGlow = _computeSubtleGlowIntensity(_frontRotorTempCelsius);
    final double rearGlow = _computeSubtleGlowIntensity(_rearRotorTempCelsius);

    // Obliczenie poślizgu i blokady tylnej opony przy awaryjnym hamowaniu na zjeździe.
    final double rearUnloadingFactor = 0.72 + descentSeverity * 0.55;
    final double rawSlip = brakePressure *
        rearUnloadingFactor *
        (1.0 + (1.0 - surfaceGrip) * 0.45) *
        (speedKmh > 14.0 ? 1.0 : speedKmh / 14.0);
    final double rearSlipRatio =
        ((rawSlip - 0.58) / 0.65).clamp(0.0, 1.0);
    final bool rearTireLocked =
        speedKmh > 12.0 &&
        brakePressure >= 0.72 &&
        rearSlipRatio >= config.rearLockupSlipThreshold;

    _updateParticlesAndSkids(
      input: input,
      dt: dt,
      speedMs: speedMs,
      wetness: wetness,
      rearTireLocked: rearTireLocked,
      rearSlipRatio: rearSlipRatio,
    );

    final TireScreechAudioCue screechCue = _buildScreechAudioCue(
      rearTireLocked: rearTireLocked,
      rearSlipRatio: rearSlipRatio,
      speedKmh: speedKmh,
      wetness: wetness,
    );

    final double maxTemp =
        math.max(_frontRotorTempCelsius, _rearRotorTempCelsius);
    final double fadeRiskRatio = ((maxTemp - 460.0) / 260.0).clamp(0.0, 1.0);

    return BrakeRotorAndTireSmokeFrameState(
      rotorState: BrakeRotorThermalState(
        frontTempCelsius: _frontRotorTempCelsius,
        rearTempCelsius: _rearRotorTempCelsius,
        frontGlowIntensity: frontGlow,
        rearGlowIntensity: rearGlow,
        frontZone: _classifyThermalZone(_frontRotorTempCelsius),
        rearZone: _classifyThermalZone(_rearRotorTempCelsius),
        thermalPowerWatts: totalBrakingWatts,
        fadeRiskRatio: fadeRiskRatio,
      ),
      rearTireLocked: rearTireLocked,
      rearSlipRatio: rearSlipRatio,
      smokeParticles: List<TireSmokeParticle3D>.unmodifiable(_smokeParticles),
      skidMarks: List<TireSkidMarkSegment3D>.unmodifiable(_skidMarks),
      screechCue: screechCue,
      speedKmh: speedKmh,
      decelerationMs2: decelerationMs2,
    );
  }

  double _computeSubtleGlowIntensity(double tempCelsius) {
    if (tempCelsius <= config.glowStartTempCelsius) {
      return 0.0;
    }
    final double span =
        (config.glowFullTempCelsius - config.glowStartTempCelsius)
            .clamp(20.0, 600.0);
    final double t = ((tempCelsius - config.glowStartTempCelsius) / span)
        .clamp(0.0, 1.0);
    // Smoothstep dla delikatnego, organicznego narastania czerwonej poświaty.
    return t * t * (3.0 - 2.0 * t);
  }

  BrakeRotorThermalZone _classifyThermalZone(double tempCelsius) {
    if (tempCelsius < 180.0) return BrakeRotorThermalZone.cool;
    if (tempCelsius < 320.0) return BrakeRotorThermalZone.warm;
    if (tempCelsius < 500.0) return BrakeRotorThermalZone.hot;
    return BrakeRotorThermalZone.critical;
  }

  void _updateParticlesAndSkids({
    required BrakeAndTireTelemetryInput input,
    required double dt,
    required double speedMs,
    required double wetness,
    required bool rearTireLocked,
    required double rearSlipRatio,
  }) {
    // Starzenie istniejących cząsteczek dymu.
    for (int i = _smokeParticles.length - 1; i >= 0; i--) {
      final TireSmokeParticle3D p = _smokeParticles[i];
      final double nextAge = p.ageSeconds + dt;
      if (nextAge >= p.lifetimeSeconds) {
        _smokeParticles.removeAt(i);
        continue;
      }
      final double progress = (nextAge / p.lifetimeSeconds).clamp(0.0, 1.0);
      final double fade = (1.0 - progress) * (1.0 - progress);
      _smokeParticles[i] = TireSmokeParticle3D(
        x: p.x + p.vx * dt,
        y: p.y + p.vy * dt,
        z: p.z + p.vz * dt,
        vx: p.vx * 0.94,
        vy: p.vy + 0.18 * dt,
        vz: p.vz * 0.94,
        ageSeconds: nextAge,
        lifetimeSeconds: p.lifetimeSeconds,
        radiusMeters: p.radiusMeters + 0.22 * dt,
        opacity: (0.48 * fade).clamp(0.0, 0.52),
        isSteam: p.isSteam,
      );
    }

    // Stopniowe wygaszanie starych śladów gumy na asfalcie.
    for (int i = _skidMarks.length - 1; i >= 0; i--) {
      final TireSkidMarkSegment3D s = _skidMarks[i];
      final double nextOpacity = s.opacity - dt * 0.18;
      if (nextOpacity <= 0.02) {
        _skidMarks.removeAt(i);
        continue;
      }
      _skidMarks[i] = TireSkidMarkSegment3D(
        startX: s.startX,
        startZ: s.startZ,
        endX: s.endX,
        endZ: s.endZ,
        y: s.y,
        opacity: nextOpacity,
        widthMeters: s.widthMeters,
      );
    }

    if (!rearTireLocked) {
      _hasLastSkidAnchor = false;
      _smokeSpawnAccumulator = 0.0;
      return;
    }

    // Pozycja styku tylnej opony ok. 0.52 m za środkiem kolarza.
    final double dirX = math.sin(input.headingRadians);
    final double dirZ = math.cos(input.headingRadians);
    final double rearWheelX = input.riderWorldX - dirX * 0.52;
    final double rearWheelZ = input.riderWorldZ - dirZ * 0.52;
    final double groundY = input.riderWorldY;

    // Krótki ślad dymu (lub mgiełki pary na mokro) emitowany spod tylnej opony.
    _smokeSpawnAccumulator += dt * (28.0 + rearSlipRatio * 24.0);
    while (_smokeSpawnAccumulator >= 1.0) {
      _smokeSpawnAccumulator -= 1.0;
      if (_smokeParticles.length >= config.maxSmokeParticles) {
        _smokeParticles.removeAt(0);
      }
      final double lateralJitter = (_rng.nextDouble() - 0.5) * 0.14;
      final double backSpeed = (speedMs * 0.18).clamp(0.8, 4.5);
      _smokeParticles.add(
        TireSmokeParticle3D(
          x: rearWheelX + lateralJitter,
          y: groundY + 0.04,
          z: rearWheelZ - dirZ * 0.08,
          vx: -dirX * backSpeed + (_rng.nextDouble() - 0.5) * 0.45,
          vy: 0.35 + _rng.nextDouble() * 0.45,
          vz: -dirZ * backSpeed + (_rng.nextDouble() - 0.5) * 0.45,
          ageSeconds: 0.0,
          lifetimeSeconds: 0.45 + _rng.nextDouble() * 0.25,
          radiusMeters: 0.045 + rearSlipRatio * 0.035,
          opacity: 0.42 + rearSlipRatio * 0.10,
          isSteam: wetness >= 0.45,
        ),
      );
    }

    // Ślad gumy na asfalcie (pomijany przy bardzo mokrej nawierzchni).
    if (wetness < 0.65) {
      if (_hasLastSkidAnchor) {
        if (_skidMarks.length >= config.maxSkidMarks) {
          _skidMarks.removeAt(0);
        }
        _skidMarks.add(
          TireSkidMarkSegment3D(
            startX: _lastSkidX,
            startZ: _lastSkidZ,
            endX: rearWheelX,
            endZ: rearWheelZ,
            y: groundY,
            opacity: (0.45 + rearSlipRatio * 0.35).clamp(0.25, 0.82),
            widthMeters: 0.028 + rearSlipRatio * 0.012,
          ),
        );
      }
      _lastSkidX = rearWheelX;
      _lastSkidZ = rearWheelZ;
      _hasLastSkidAnchor = true;
    }
  }

  TireScreechAudioCue _buildScreechAudioCue({
    required bool rearTireLocked,
    required double rearSlipRatio,
    required double speedKmh,
    required double wetness,
  }) {
    if (!rearTireLocked || speedKmh < 12.0) {
      return const TireScreechAudioCue(
        isTriggered: false,
        intensity: TireScreechIntensity.none,
        volume: 0.0,
        frequencyHz: 0.0,
        slipRatio: 0.0,
      );
    }

    // Mokra opona piszczy ciszej (tłumienie wodą).
    final double wetAttenuation = 1.0 - (wetness * 0.72);
    final double volume =
        ((0.28 + rearSlipRatio * 0.65) * wetAttenuation).clamp(0.05, 0.95);
    final double frequencyHz =
        (1450.0 + speedKmh * 9.5 + rearSlipRatio * 340.0).clamp(1400.0, 2750.0);

    final TireScreechIntensity intensity;
    if (rearSlipRatio >= 0.72) {
      intensity = TireScreechIntensity.emergencyLockup;
    } else if (rearSlipRatio >= 0.42) {
      intensity = TireScreechIntensity.sustainedSkid;
    } else {
      intensity = TireScreechIntensity.chirp;
    }

    return TireScreechAudioCue(
      isTriggered: true,
      intensity: intensity,
      volume: volume,
      frequencyHz: frequencyHz,
      slipRatio: rearSlipRatio,
    );
  }
}

/// Rzutnik 3D prezentujący nawrót 180°, subtelnie żarzące się tarcze hamulcowe oraz dym i ślad tylnej opony.
class GlowingBrakeRotorsAndTireSmoke3dPainter extends CustomPainter {
  final BrakeRotorAndTireSmokeFrameState frameState;
  final double wheelAngleRadians;
  final double cornerCurvature180Ratio;
  final double asphaltWetness;

  const GlowingBrakeRotorsAndTireSmoke3dPainter({
    required this.frameState,
    required this.wheelAngleRadians,
    required this.cornerCurvature180Ratio,
    required this.asphaltWetness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // 1. Tło sceny (noc/cień przełęczy górskiej dla czytelności subtelnej poświaty).
    final Rect bgRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF0A0C10),
          AppColors.background,
          Color(0xFF151922),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Wstęga asfaltu z łukiem nawrotu 180°.
    _drawHairpinAsphalt(canvas, size);

    // 3. Ślad zblokowanej tylnej opony na asfalcie.
    final Offset rearHub = Offset(size.width * 0.34, size.height * 0.62);
    final Offset frontHub = Offset(size.width * 0.68, size.height * 0.62);
    final double wheelRadius = math.min(size.width, size.height) * 0.21;
    final Offset rearGroundContact = Offset(rearHub.dx, rearHub.dy + wheelRadius);

    _drawSkidTrail(canvas, size, rearGroundContact);

    // 4. Rama roweru szosowego (uproszczona sylwetka 3D łącząca osie kół).
    _drawBikeFrameSilhouette(canvas, rearHub, frontHub, wheelRadius);

    // 5. Koła i tarcze hamulcowe z subtelną czerwoną poświatą.
    _drawWheelWithGlowingRotor(
      canvas: canvas,
      hub: rearHub,
      wheelRadius: wheelRadius,
      glowIntensity: frameState.rotorState.rearGlowIntensity,
      isLocked: frameState.rearTireLocked,
    );
    _drawWheelWithGlowingRotor(
      canvas: canvas,
      hub: frontHub,
      wheelRadius: wheelRadius,
      glowIntensity: frameState.rotorState.frontGlowIntensity,
      isLocked: false,
    );

    // 6. Cząsteczki krótkiego dymu spod tylnej opony.
    _drawSmokePlume(canvas, size, rearGroundContact);

    // 7. Subtelny znacznik fali pisku audio przy zblokowanej oponie.
    if (frameState.screechCue.isTriggered) {
      _drawScreechWaveIndicator(canvas, rearGroundContact, frameState.screechCue);
    }
  }

  void _drawHairpinAsphalt(Canvas canvas, Size size) {
    final double horizonY = size.height * 0.34;
    final double curveOffset = cornerCurvature180Ratio * size.width * 0.14;

    final Path roadPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..quadraticBezierTo(
        size.width * 0.88 - curveOffset * 0.5,
        size.height * 0.52,
        size.width * 0.62 - curveOffset,
        horizonY,
      )
      ..lineTo(size.width * 0.36 - curveOffset, horizonY)
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.56,
        0,
        size.height * 0.82,
      )
      ..close();

    final Color roadTop = asphaltWetness > 0.35
        ? const Color(0xFF151923)
        : const Color(0xFF1A1E28);
    final Color roadBottom = asphaltWetness > 0.35
        ? const Color(0xFF1D2432)
        : const Color(0xFF232834);

    canvas.drawPath(
      roadPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[roadTop, roadBottom],
        ).createShader(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY)),
    );

    // Krawędź asfaltu i biało-czerwone tarki przed nawrotem 180°.
    if (cornerCurvature180Ratio > 0.25) {
      final Paint curbPaint = Paint()
        ..color = AppColors.crimsonAlert.withValues(
          alpha: 0.25 + cornerCurvature180Ratio * 0.35,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      final Path curbPath = Path()
        ..moveTo(size.width * 0.62 - curveOffset, horizonY)
        ..quadraticBezierTo(
          size.width * 0.88 - curveOffset * 0.5,
          size.height * 0.52,
          size.width * 0.96,
          size.height * 0.86,
        );
      canvas.drawPath(curbPath, curbPaint);
    }
  }

  void _drawSkidTrail(Canvas canvas, Size size, Offset rearContact) {
    if (!frameState.rearTireLocked && frameState.skidMarks.isEmpty) return;

    final int trailCount = math.max(
      frameState.skidMarks.length,
      frameState.rearTireLocked ? 8 : 0,
    );
    if (trailCount == 0) return;

    final double trailLength = size.width * 0.22;
    final Paint skidPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: <Color>[
          Colors.black.withValues(alpha: frameState.rearTireLocked ? 0.72 : 0.35),
          Colors.black.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(
          rearContact.dx - trailLength,
          rearContact.dy - 4,
          trailLength,
          8,
        ),
      );

    canvas.drawLine(
      rearContact,
      Offset(rearContact.dx - trailLength, rearContact.dy + 3.0),
      skidPaint,
    );
  }

  void _drawBikeFrameSilhouette(
    Canvas canvas,
    Offset rearHub,
    Offset frontHub,
    double wheelRadius,
  ) {
    final Offset bb = Offset(
      rearHub.dx + (frontHub.dx - rearHub.dx) * 0.42,
      rearHub.dy + wheelRadius * 0.08,
    );
    final Offset seatCluster = Offset(
      rearHub.dx + (frontHub.dx - rearHub.dx) * 0.32,
      rearHub.dy - wheelRadius * 0.95,
    );
    final Offset headTubeTop = Offset(
      frontHub.dx - wheelRadius * 0.36,
      frontHub.dy - wheelRadius * 0.92,
    );

    final Paint framePaint = Paint()
      ..color = const Color(0xFF2D3342)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(rearHub, bb, framePaint);
    canvas.drawLine(rearHub, seatCluster, framePaint);
    canvas.drawLine(bb, seatCluster, framePaint);
    canvas.drawLine(seatCluster, headTubeTop, framePaint);
    canvas.drawLine(bb, headTubeTop, framePaint);
    canvas.drawLine(headTubeTop, frontHub, framePaint);

    // Zacisk hamulca tarczowego (tylny przy dolnym widelcu, przedni przy widelcu).
    final Paint caliperPaint = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(rearHub.dx + wheelRadius * 0.16, rearHub.dy - wheelRadius * 0.18),
      4.5,
      caliperPaint,
    );
    canvas.drawCircle(
      Offset(frontHub.dx - wheelRadius * 0.16, frontHub.dy - wheelRadius * 0.18),
      4.5,
      caliperPaint,
    );
  }

  void _drawWheelWithGlowingRotor({
    required Canvas canvas,
    required Offset hub,
    required double wheelRadius,
    required double glowIntensity,
    required bool isLocked,
  }) {
    // Opona zewnętrzna.
    canvas.drawCircle(
      hub,
      wheelRadius,
      Paint()
        ..color = isLocked ? const Color(0xFF181A20) : const Color(0xFF101217)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5,
    );

    // Karbonowa obręcz.
    canvas.drawCircle(
      hub,
      wheelRadius - 4.5,
      Paint()
        ..color = AppTheme.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Obracające się szprychy (zatrzymują się przy blokadzie tylnego koła).
    final Paint spokePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1.1;
    const int spokes = 12;
    for (int i = 0; i < spokes; i++) {
      final double angle =
          (isLocked ? 0.0 : wheelAngleRadians) + (i * math.pi * 2.0 / spokes);
      canvas.drawLine(
        hub,
        Offset(
          hub.dx + math.cos(angle) * (wheelRadius - 6.0),
          hub.dy + math.sin(angle) * (wheelRadius - 6.0),
        ),
        spokePaint,
      );
    }

    // Tarcza hamulcowa (promień ~26% koła dla czytelności 3D).
    final double rotorRadius = wheelRadius * 0.27;

    // Subtelna czerwona poświata nagrzanej tarczy (bloom zewnętrzny + pierścień).
    if (glowIntensity > 0.01) {
      final double outerBloomRadius = rotorRadius * (1.55 + glowIntensity * 0.55);
      final Paint outerGlow = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Color.lerp(
              const Color(0xFFB91C1C),
              const Color(0xFFFF4500),
              glowIntensity,
            )!
                .withValues(alpha: 0.42 * glowIntensity),
            AppColors.crimsonAlert.withValues(alpha: 0.16 * glowIntensity),
            Colors.transparent,
          ],
          stops: const <double>[0.25, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: hub, radius: outerBloomRadius));
      canvas.drawCircle(hub, outerBloomRadius, outerGlow);
    }

    // Metaliczna tarcza hamulcowa z subtelnym rozgrzanym rantem.
    final Color rotorBase = Color.lerp(
      const Color(0xFF9CA3AF),
      const Color(0xFFEF4444),
      glowIntensity * 0.75,
    )!;
    canvas.drawCircle(
      hub,
      rotorRadius,
      Paint()
        ..color = rotorBase.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );

    if (glowIntensity > 0.12) {
      canvas.drawCircle(
        hub,
        rotorRadius * 0.86,
        Paint()
          ..color = Color.lerp(
            AppColors.crimsonAlert,
            const Color(0xFFFF8A3D),
            glowIntensity * 0.5,
          )!
              .withValues(alpha: 0.55 * glowIntensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // Piasta.
    canvas.drawCircle(
      hub,
      rotorRadius * 0.26,
      Paint()..color = AppColors.surfaceLight,
    );
  }

  void _drawSmokePlume(Canvas canvas, Size size, Offset rearContact) {
    final List<TireSmokeParticle3D> particles = frameState.smokeParticles;
    if (particles.isEmpty) return;

    final int count = particles.length;
    for (int i = 0; i < count; i++) {
      final TireSmokeParticle3D p = particles[i];
      final double progress = p.lifeProgress;
      // Rzutujemy krótką smugę dymu w lewo i lekko ku górze od styku tylnej opony.
      final double dx = rearContact.dx - 8.0 - progress * size.width * 0.16;
      final double dy =
          rearContact.dy - 4.0 - progress * size.height * 0.10 + (p.y * 8.0);
      final double radius = (5.0 + progress * 14.0) * (0.85 + p.radiusMeters * 3.0);

      final Color smokeColor = p.isSteam
          ? const Color(0xFFD1D5DB).withValues(alpha: p.opacity * 0.65)
          : const Color(0xFFE5E7EB).withValues(alpha: p.opacity * 0.78);

      canvas.drawCircle(
        Offset(dx, dy),
        radius,
        Paint()
          ..color = smokeColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
      );
    }
  }

  void _drawScreechWaveIndicator(
    Canvas canvas,
    Offset rearContact,
    TireScreechAudioCue cue,
  ) {
    final Paint wavePaint = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: 0.35 + cue.volume * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    for (int i = 1; i <= 3; i++) {
      final double r = 10.0 + i * 7.5;
      canvas.drawArc(
        Rect.fromCircle(center: rearContact, radius: r),
        math.pi * 0.85,
        math.pi * 0.45,
        false,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GlowingBrakeRotorsAndTireSmoke3dPainter oldDelegate) {
    return oldDelegate.frameState != frameState ||
        oldDelegate.wheelAngleRadians != wheelAngleRadians ||
        oldDelegate.cornerCurvature180Ratio != cornerCurvature180Ratio ||
        oldDelegate.asphaltWetness != asphaltWetness;
  }
}

/// Produkcyjny panel podglądu i sterowania efektem nagrzanych tarcz oraz dymu opony 3D.
class GlowingBrakeRotorsAndTireSmokePanel extends StatefulWidget {
  final BrakingScenarioPreset initialPreset;

  const GlowingBrakeRotorsAndTireSmokePanel({
    super.key,
    this.initialPreset = BrakingScenarioPreset.hairpin180Approach,
  });

  @override
  State<GlowingBrakeRotorsAndTireSmokePanel> createState() =>
      _GlowingBrakeRotorsAndTireSmokePanelState();
}

class _GlowingBrakeRotorsAndTireSmokePanelState
    extends State<GlowingBrakeRotorsAndTireSmokePanel>
    with SingleTickerProviderStateMixin {
  late final GlowingBrakeRotorsAndTireSmokeEngine _engine;
  late final AnimationController _ticker;

  late BrakingScenarioPreset _selectedPreset;
  late double _speedKmh;
  late double _brakePressureRatio;
  late double _roadGradientPercent;
  late double _cornerCurvature180Ratio;
  late double _asphaltWetness;
  bool _isRunning = true;
  double _wheelAngle = 0.0;

  late BrakeRotorAndTireSmokeFrameState _frameState;

  @override
  void initState() {
    super.initState();
    _engine = GlowingBrakeRotorsAndTireSmokeEngine();
    _selectedPreset = widget.initialPreset;
    _applyPresetValues(_selectedPreset, resetEngine: false);
    _frameState = _engine.step(_currentInput(dtSeconds: 1.0 / 60.0));

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_onTick);
    _ticker.repeat();
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!_isRunning || !mounted) return;
    const double dt = 1.0 / 60.0;
    final double angularVel = (_speedKmh / 3.6) / 0.34;
    _wheelAngle = (_wheelAngle + angularVel * dt) % (math.pi * 2.0);
    setState(() {
      _frameState = _engine.step(_currentInput(dtSeconds: dt));
    });
  }

  BrakeAndTireTelemetryInput _currentInput({required double dtSeconds}) {
    return BrakeAndTireTelemetryInput(
      speedKmh: _speedKmh,
      brakePressureRatio: _brakePressureRatio,
      roadGradientPercent: _roadGradientPercent,
      cornerCurvature180Ratio: _cornerCurvature180Ratio,
      asphaltWetness: _asphaltWetness,
      wheelAngleRadians: _wheelAngle,
      dtSeconds: dtSeconds,
    );
  }

  void _applyPresetValues(
    BrakingScenarioPreset preset, {
    required bool resetEngine,
  }) {
    _selectedPreset = preset;
    _speedKmh = preset.speedKmh;
    _brakePressureRatio = preset.brakePressureRatio;
    _roadGradientPercent = preset.roadGradientPercent;
    _cornerCurvature180Ratio = preset.cornerCurvature180Ratio;
    _asphaltWetness = preset.asphaltWetness;
    if (resetEngine) {
      _engine.reset();
      _frameState = _engine.step(_currentInput(dtSeconds: 1.0 / 60.0));
    }
  }

  bool get _canReset {
    return _frameState.rotorState.frontTempCelsius >
            _engine.config.ambientTempCelsius + 0.5 ||
        _frameState.smokeParticles.isNotEmpty ||
        _frameState.skidMarks.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isDesktopWide = constraints.maxWidth >= 900;
          final bool isCompactMobile = constraints.maxWidth < 520;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(isCompactMobile: isCompactMobile),
                const SizedBox(height: 14),
                _buildPresetChips(),
                const SizedBox(height: 16),
                if (isDesktopWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 6,
                        child: _buildViewportCard(height: 310),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: <Widget>[
                            _buildTelemetryGrid(isCompact: false),
                            const SizedBox(height: 12),
                            _buildSlidersCard(),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  _buildViewportCard(height: isCompactMobile ? 210 : 260),
                  const SizedBox(height: 12),
                  _buildTelemetryGrid(isCompact: isCompactMobile),
                  const SizedBox(height: 12),
                  _buildSlidersCard(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isCompactMobile}) {
    final Widget titleGroup = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Tarcze Hamulcowe & Dym Opony 3D',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _selectedPreset.description,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final Widget actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _InteractiveActionButton(
          label: _isRunning ? 'Pauza' : 'Wznów',
          icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          isActive: _isRunning,
          onPressed: () {
            setState(() {
              _isRunning = !_isRunning;
            });
          },
        ),
        _InteractiveActionButton(
          label: 'Schłódź',
          icon: Icons.ac_unit_rounded,
          isActive: false,
          onPressed: _canReset
              ? () {
                  setState(() {
                    _engine.reset();
                    _frameState = _engine.step(
                      _currentInput(dtSeconds: 1.0 / 60.0),
                    );
                  });
                }
              : null,
        ),
      ],
    );

    if (isCompactMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          titleGroup,
          const SizedBox(height: 10),
          actions,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: titleGroup),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  Widget _buildPresetChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BrakingScenarioPreset.values.map((BrakingScenarioPreset preset) {
        final bool selected = preset == _selectedPreset;
        return _InteractivePresetChip(
          label: preset.label,
          selected: selected,
          onTap: () {
            setState(() {
              _applyPresetValues(preset, resetEngine: true);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildViewportCard({required double height}) {
    final bool locked = _frameState.rearTireLocked;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: locked ? AppColors.crimsonAlert : AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: GlowingBrakeRotorsAndTireSmoke3dPainter(
                frameState: _frameState,
                wheelAngleRadians: _wheelAngle,
                cornerCurvature180Ratio: _cornerCurvature180Ratio,
                asphaltWetness: _asphaltWetness,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            child: _StatusPill(
              text: locked
                  ? 'BLOKADA TYŁU • PISK ${(_frameState.screechCue.frequencyHz).toStringAsFixed(0)} Hz'
                  : 'PRZÓD ${_frameState.rotorState.frontTempCelsius.toStringAsFixed(0)}°C',
              accentColor: locked
                  ? AppColors.crimsonAlert
                  : (_frameState.rotorState.frontGlowIntensity > 0.2
                      ? AppColors.amberWarning
                      : AppColors.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid({required bool isCompact}) {
    final BrakeRotorThermalState rotor = _frameState.rotorState;
    final List<Widget> items = <Widget>[
      _TelemetryTile(
        label: 'Tarcza Przód',
        value: '${rotor.frontTempCelsius.toStringAsFixed(0)} °C',
        subLabel:
            'Poświata ${(rotor.frontGlowIntensity * 100).toStringAsFixed(0)}% • ${rotor.frontZone.label}',
        accent: rotor.frontGlowIntensity > 0.25
            ? AppColors.crimsonAlert
            : AppColors.textPrimary,
      ),
      _TelemetryTile(
        label: 'Tarcza Tył',
        value: '${rotor.rearTempCelsius.toStringAsFixed(0)} °C',
        subLabel:
            'Poświata ${(rotor.rearGlowIntensity * 100).toStringAsFixed(0)}% • ${rotor.rearZone.label}',
        accent: rotor.rearGlowIntensity > 0.25
            ? AppColors.amberWarning
            : AppColors.textPrimary,
      ),
      _TelemetryTile(
        label: 'Poślizg / Dym',
        value: '${(_frameState.rearSlipRatio * 100).toStringAsFixed(0)}%',
        subLabel:
            'Cząsteczki: ${_frameState.smokeParticles.length} • Ślady: ${_frameState.skidMarks.length}',
        accent: _frameState.rearTireLocked
            ? AppColors.crimsonAlert
            : AppColors.statusSuccess,
      ),
      _TelemetryTile(
        label: 'Audio Pisk',
        value: _frameState.screechCue.isTriggered
            ? _frameState.screechCue.intensity.label
            : 'Cisza',
        subLabel: _frameState.screechCue.isTriggered
            ? '${_frameState.screechCue.frequencyHz.toStringAsFixed(0)} Hz • ${(_frameState.screechCue.volume * 100).toStringAsFixed(0)}%'
            : 'Moc cieplna ${rotor.thermalPowerWatts.toStringAsFixed(0)} W',
        accent: _frameState.screechCue.isTriggered
            ? AppColors.goldAccent
            : AppColors.textSecondary,
      ),
    ];

    if (isCompact) {
      return Column(
        children: items
            .map(
              (Widget w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: w,
              ),
            )
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.35,
      children: items,
    );
  }

  Widget _buildSlidersCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: <Widget>[
          _LabeledSliderRow(
            label: 'Hamowanie',
            valueLabel: '${(_brakePressureRatio * 100).toStringAsFixed(0)}%',
            value: _brakePressureRatio,
            min: 0.0,
            max: 1.0,
            activeColor: AppColors.crimsonAlert,
            onChanged: (double v) => setState(() => _brakePressureRatio = v),
          ),
          _LabeledSliderRow(
            label: 'Prędkość',
            valueLabel: '${_speedKmh.toStringAsFixed(0)} km/h',
            value: _speedKmh,
            min: 15.0,
            max: 98.0,
            activeColor: AppColors.accentBlue,
            onChanged: (double v) => setState(() => _speedKmh = v),
          ),
          _LabeledSliderRow(
            label: 'Zjazd',
            valueLabel: '${_roadGradientPercent.toStringAsFixed(1)}%',
            value: -_roadGradientPercent,
            min: 0.0,
            max: 18.0,
            activeColor: AppColors.goldAccent,
            onChanged: (double v) => setState(() => _roadGradientPercent = -v),
          ),
          _LabeledSliderRow(
            label: 'Mokry asfalt',
            valueLabel: '${(_asphaltWetness * 100).toStringAsFixed(0)}%',
            value: _asphaltWetness,
            min: 0.0,
            max: 1.0,
            activeColor: AppColors.cyanAccent,
            onChanged: (double v) => setState(() => _asphaltWetness = v),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color bgColor;
    if (!enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.45);
    } else if (_pressed || widget.isActive) {
      bgColor = AppColors.primaryAccent;
    } else if (_hovered) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.background;
    }

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isActive ? AppColors.primaryAccent : AppTheme.borderColor);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: MouseRegion(
          cursor:
              enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 16,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.45),
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

class _InteractivePresetChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InteractivePresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractivePresetChip> createState() => _InteractivePresetChipState();
}

class _InteractivePresetChipState extends State<_InteractivePresetChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.25)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final Color border = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.primaryAccent : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: -0.2,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _StatusPill({
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.55),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          color: accentColor,
        ),
      ),
    );
  }
}

class _TelemetryTile extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final Color accent;

  const _TelemetryTile({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              letterSpacing: -0.2,
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              letterSpacing: -0.2,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledSliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _LabeledSliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: AppTheme.borderColor,
              thumbColor: AppColors.textPrimary,
              overlayColor: activeColor.withValues(alpha: 0.16),
              trackHeight: 3.0,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
