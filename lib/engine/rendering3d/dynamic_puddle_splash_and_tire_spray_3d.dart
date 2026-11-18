// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Presety warunków mokrej szosy i intensywności opadów dla efektów wodnych 3D.
enum WetRoadRainPreset {
  /// Wysychający asfalt po przelotnym deszczu — kałuże głównie na poboczach.
  dryingAsphalt(
    label: 'Wysychający asfalt',
    rainIntensity: 0.12,
    ambientTempCelsius: 16.5,
    windSpeedMs: 3.2,
    puddleCoverage: 0.35,
    waterFilmDepthMm: 0.4,
  ),

  /// Lekka mżawka — cienki film wodny i umiarkowany pióropusz z kół.
  lightDrizzle(
    label: 'Mżawka',
    rainIntensity: 0.35,
    ambientTempCelsius: 13.0,
    windSpeedMs: 4.5,
    puddleCoverage: 0.55,
    waterFilmDepthMm: 0.9,
  ),

  /// Wiosenny deszcz klasyków — głębsze kałuże na poboczu i wyraźne wychłodzenie.
  steadySpringRain(
    label: 'Deszcz klasyków',
    rainIntensity: 0.65,
    ambientTempCelsius: 9.5,
    windSpeedMs: 6.2,
    puddleCoverage: 0.78,
    waterFilmDepthMm: 1.6,
  ),

  /// Flandryjska ulewa — gęste kałuże, potężne pióropusze i szybki spadek komfortu.
  flemishDownpour(
    label: 'Flandryjska ulewa',
    rainIntensity: 0.92,
    ambientTempCelsius: 7.0,
    windSpeedMs: 8.4,
    puddleCoverage: 0.95,
    waterFilmDepthMm: 2.5,
  ),

  /// Alpejska burza na zjeździe — lodowata woda i ekstremalne wychłodzenie na kole.
  alpineStorm(
    label: 'Burza alpejska',
    rainIntensity: 1.0,
    ambientTempCelsius: 4.0,
    windSpeedMs: 9.5,
    puddleCoverage: 1.0,
    waterFilmDepthMm: 2.9,
  );

  final String label;
  final double rainIntensity;
  final double ambientTempCelsius;
  final double windSpeedMs;
  final double puddleCoverage;
  final double waterFilmDepthMm;

  const WetRoadRainPreset({
    required this.label,
    required this.rainIntensity,
    required this.ambientTempCelsius,
    required this.windSpeedMs,
    required this.puddleCoverage,
    required this.waterFilmDepthMm,
  });
}

/// Położenie kałuży względem przekroju poprzecznego szosy.
enum RoadPuddleSide {
  leftShoulder('Lewe pobocze'),
  rightShoulder('Prawe pobocze'),
  centerRut('Koleina środka');

  final String label;
  const RoadPuddleSide(this.label);
}

/// Poziom intensywności pióropusza wody wzbijanego przez tylne koło.
enum TireSprayIntensityTier {
  none('Brak', AppColors.textSecondary),
  mist('Mgiełka', AppColors.accentBlue),
  roosterTail('Pióropusz', AppColors.cyanAccent),
  heavyPlume('Gejzer z kałuży', AppColors.amberWarning);

  final String label;
  final Color color;
  const TireSprayIntensityTier(this.label, this.color);
}

/// Konfiguracja fizyki kałuż, rozbryzgu kół oraz wychłodzenia termicznego rywali.
class DynamicPuddleSplashConfig {
  final double roadWidthMeters;
  final double shoulderPuddleZoneWidthMeters;
  final double sprayDraftReachMeters;
  final double sprayLateralSpreadMeters;
  final int maxDropletsPerPlume;
  final double coolingRatePerWetness;
  final double dryingRatePerSecond;

  const DynamicPuddleSplashConfig({
    this.roadWidthMeters = 7.5,
    this.shoulderPuddleZoneWidthMeters = 1.9,
    this.sprayDraftReachMeters = 4.4,
    this.sprayLateralSpreadMeters = 0.78,
    this.maxDropletsPerPlume = 140,
    this.coolingRatePerWetness = 4.2,
    this.dryingRatePerSecond = 0.04,
  });
}

/// Kałuża na poboczu lub koleinie asfaltu z głębokością i fazą falowania lustra wody.
class RoadsidePuddle3D {
  final String id;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double lengthMeters;
  final double widthMeters;
  final double depthMm;
  final RoadPuddleSide side;
  final double ripplePhase;

  const RoadsidePuddle3D({
    required this.id,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.lengthMeters,
    required this.widthMeters,
    required this.depthMm,
    required this.side,
    this.ripplePhase = 0.0,
  });

  RoadsidePuddle3D copyWith({
    double? ripplePhase,
    double? depthMm,
  }) {
    return RoadsidePuddle3D(
      id: id,
      distanceMeters: distanceMeters,
      lateralOffsetMeters: lateralOffsetMeters,
      lengthMeters: lengthMeters,
      widthMeters: widthMeters,
      depthMm: depthMm ?? this.depthMm,
      side: side,
      ripplePhase: ripplePhase ?? this.ripplePhase,
    );
  }

  /// Zwraca znormalizowaną głębokość kałuży (0..1) w punkcie `(distanceM, lateralOffsetM)`.
  double depthFactorAt(double distanceM, double lateralOffsetM) {
    final halfL = math.max(0.25, lengthMeters * 0.5);
    final halfW = math.max(0.2, widthMeters * 0.5);
    final dx = (distanceM - distanceMeters) / halfL;
    final dz = (lateralOffsetM - lateralOffsetMeters) / halfW;
    final normSq = dx * dx + dz * dz;
    if (normSq >= 1.0) return 0.0;
    return (1.0 - normSq).clamp(0.0, 1.0);
  }

  bool containsPoint(double distanceM, double lateralOffsetM) =>
      depthFactorAt(distanceM, lateralOffsetM) > 0.0;
}

/// Dane wejściowe kolarza dla kroku symulacji rozbryzgu i komfortu termicznego.
class RiderWetRoadInput {
  final String riderId;
  final String riderName;
  final Color teamColor;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double speedKmh;
  final double ambientTempCelsius;
  final double baseThermalComfort;
  final bool hasFenders;

  const RiderWetRoadInput({
    required this.riderId,
    required this.riderName,
    required this.teamColor,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.speedKmh,
    this.ambientTempCelsius = 10.0,
    this.baseThermalComfort = 88.0,
    this.hasFenders = false,
  });
}

/// Pojedyncza kropla wody 3D w pióropuszu za tylnym kołem kolarza.
class WaterDroplet3D {
  final double lateralOffsetMeters;
  final double heightMeters;
  final double distanceMeters;
  final double vxLateral;
  final double vyHeight;
  final double vzLongitudinal;
  final double radiusPx;
  final double alpha;
  final double lifeSeconds;
  final double maxLifeSeconds;
  final bool isFromPuddle;

  const WaterDroplet3D({
    required this.lateralOffsetMeters,
    required this.heightMeters,
    required this.distanceMeters,
    required this.vxLateral,
    required this.vyHeight,
    required this.vzLongitudinal,
    required this.radiusPx,
    required this.alpha,
    required this.lifeSeconds,
    required this.maxLifeSeconds,
    required this.isFromPuddle,
  });

  double get normalizedLife =>
      maxLifeSeconds > 0 ? (lifeSeconds / maxLifeSeconds).clamp(0.0, 1.0) : 1.0;

  WaterDroplet3D advance(double dt) {
    const gravity = 9.81;
    const drag = 1.65;
    final newVx = vxLateral * math.exp(-drag * dt);
    final newVy = vyHeight - gravity * dt;
    final newVz = vzLongitudinal * math.exp(-drag * 0.8 * dt);
    return WaterDroplet3D(
      lateralOffsetMeters: lateralOffsetMeters + newVx * dt,
      heightMeters: math.max(0.0, heightMeters + newVy * dt),
      distanceMeters: distanceMeters + newVz * dt,
      vxLateral: newVx,
      vyHeight: newVy,
      vzLongitudinal: newVz,
      radiusPx: radiusPx,
      alpha: alpha,
      lifeSeconds: lifeSeconds + dt,
      maxLifeSeconds: maxLifeSeconds,
      isFromPuddle: isFromPuddle,
    );
  }
}

/// Dynamiczny pióropusz kropel wody wzbijany przez koła kolarza.
class TireSprayPlume3D {
  final String sourceRiderId;
  final double originDistanceM;
  final double originLateralM;
  final double plumeHeightM;
  final double plumeLengthM;
  final double intensity;
  final bool isPuddleSplash;
  final List<WaterDroplet3D> droplets;

  const TireSprayPlume3D({
    required this.sourceRiderId,
    required this.originDistanceM,
    required this.originLateralM,
    required this.plumeHeightM,
    required this.plumeLengthM,
    required this.intensity,
    required this.isPuddleSplash,
    required this.droplets,
  });
}

/// Stan zmoczenia i komfortu termicznego pojedynczego kolarza.
class RiderThermalWetnessState {
  final String riderId;
  final String riderName;
  final Color teamColor;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double speedKmh;
  final double wetnessLevel;
  final double splashExposureRate;
  final double thermalComfort;
  final double effectiveSkinTempCelsius;
  final double shiveringPenaltyPct;
  final bool inPuddle;
  final String? drenchedByRiderId;
  final TireSprayIntensityTier sprayTier;

  const RiderThermalWetnessState({
    required this.riderId,
    required this.riderName,
    required this.teamColor,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.speedKmh,
    required this.wetnessLevel,
    required this.splashExposureRate,
    required this.thermalComfort,
    required this.effectiveSkinTempCelsius,
    required this.shiveringPenaltyPct,
    required this.inPuddle,
    required this.drenchedByRiderId,
    required this.sprayTier,
  });
}

/// Pełna migawka klatki symulacji efektów wodnych 3D.
class PuddleSplashFrameSnapshot {
  final double elapsedSeconds;
  final WetRoadRainPreset preset;
  final List<RoadsidePuddle3D> puddles;
  final List<TireSprayPlume3D> plumes;
  final List<RiderThermalWetnessState> riderStates;
  final int activeSplashCount;
  final double averagePelotonWetness;
  final double lowestThermalComfort;
  final int totalActiveDroplets;

  const PuddleSplashFrameSnapshot({
    required this.elapsedSeconds,
    required this.preset,
    required this.puddles,
    required this.plumes,
    required this.riderStates,
    required this.activeSplashCount,
    required this.averagePelotonWetness,
    required this.lowestThermalComfort,
    required this.totalActiveDroplets,
  });
}

/// Silnik fizyki i generowania cząstek 3D dla kałuż na poboczu asfaltu,
/// pióropuszy wody spod kół oraz wychłodzenia termicznego rywali jadących na kole.
class DynamicPuddleSplashAndTireSpray3d {
  final DynamicPuddleSplashConfig config;
  math.Random _rng;

  double _elapsedSeconds = 0.0;
  List<RoadsidePuddle3D> _puddles = <RoadsidePuddle3D>[];
  final Map<String, List<WaterDroplet3D>> _dropletsByRider =
      <String, List<WaterDroplet3D>>{};
  final Map<String, double> _wetnessByRider = <String, double>{};
  final Map<String, double> _comfortByRider = <String, double>{};

  DynamicPuddleSplashAndTireSpray3d({
    this.config = const DynamicPuddleSplashConfig(),
    int seed = 693,
  }) : _rng = math.Random(seed);

  List<RoadsidePuddle3D> get puddles => List<RoadsidePuddle3D>.unmodifiable(_puddles);

  /// Resetuje stan cząstek, zmoczenia i komfortu termicznego kolarzy.
  void reset({int seed = 693}) {
    _rng = math.Random(seed);
    _elapsedSeconds = 0.0;
    _dropletsByRider.clear();
    _wetnessByRider.clear();
    _comfortByRider.clear();
  }

  /// Generuje deterministyczny układ kałuż głównie na prawym i lewym poboczu asfaltu.
  List<RoadsidePuddle3D> generateRoadsidePuddles({
    required double startDistanceM,
    required double endDistanceM,
    required WetRoadRainPreset preset,
    int seed = 693,
  }) {
    final rng = math.Random(seed);
    final span = math.max(10.0, endDistanceM - startDistanceM);
    final halfRoad = config.roadWidthMeters * 0.5;
    final generated = <RoadsidePuddle3D>[];

    final spacing = (14.0 - preset.puddleCoverage * 7.5).clamp(5.2, 16.0);
    final count = (span / spacing).floor().clamp(1, 120);

    for (var i = 0; i < count; i++) {
      if (rng.nextDouble() > preset.puddleCoverage) continue;

      final dist = startDistanceM + (i + 0.25 + rng.nextDouble() * 0.55) * spacing;
      final roll = rng.nextDouble();
      final RoadPuddleSide side;
      final double lateral;

      if (roll < 0.48) {
        side = RoadPuddleSide.rightShoulder;
        lateral = halfRoad - 0.55 - rng.nextDouble() * 1.15;
      } else if (roll < 0.92) {
        side = RoadPuddleSide.leftShoulder;
        lateral = -halfRoad + 0.55 + rng.nextDouble() * 1.15;
      } else {
        side = RoadPuddleSide.centerRut;
        lateral = (rng.nextDouble() - 0.5) * 1.4;
      }

      generated.add(
        RoadsidePuddle3D(
          id: 'puddle_$i',
          distanceMeters: dist,
          lateralOffsetMeters: lateral,
          lengthMeters: 2.6 + rng.nextDouble() * 3.8,
          widthMeters: 0.95 + rng.nextDouble() * 0.95,
          depthMm: (4.5 + rng.nextDouble() * 11.5) *
              (0.45 + 0.55 * preset.puddleCoverage),
          side: side,
          ripplePhase: rng.nextDouble() * math.pi * 2.0,
        ),
      );
    }

    _puddles = generated;
    return puddles;
  }

  /// Umożliwia wstrzyknięcie jawnej listy kałuż (np. ze scenariusza lub testu).
  void setPuddles(List<RoadsidePuddle3D> customPuddles) {
    _puddles = List<RoadsidePuddle3D>.from(customPuddles);
  }

  /// Wykonuje jeden krok symulacji 3D: wykrywanie wjazdu w kałuże, emisję kropel,
  /// oblewanie rywali jadących bezpośrednio na kole oraz spadek ich komfortu termicznego.
  PuddleSplashFrameSnapshot stepSimulation({
    required double dtSeconds,
    required List<RiderWetRoadInput> riders,
    required WetRoadRainPreset preset,
    double? windSpeedMs,
  }) {
    final dt = dtSeconds.clamp(0.001, 0.25);
    _elapsedSeconds += dt;
    final effectiveWind = windSpeedMs ?? preset.windSpeedMs;

    // 1. Aktualizacja fazy falowania kałuż.
    _puddles = _puddles
        .map(
          (p) => p.copyWith(
            ripplePhase: (p.ripplePhase + dt * (3.2 + preset.rainIntensity * 4.0)) %
                (math.pi * 2.0),
          ),
        )
        .toList(growable: false);

    // 2. Wykrycie wjazdu w kałużę oraz wyliczenie intensywności pióropusza dla każdego kolarza.
    final puddleHitByRider = <String, double>{};
    final sprayIntensityByRider = <String, double>{};
    final plumes = <TireSprayPlume3D>[];

    for (final rider in riders) {
      var maxPuddleDepth = 0.0;
      for (final puddle in _puddles) {
        final factor =
            puddle.depthFactorAt(rider.distanceMeters, rider.lateralOffsetMeters);
        if (factor > maxPuddleDepth) {
          maxPuddleDepth = factor * (puddle.depthMm / 14.0).clamp(0.35, 1.25);
        }
      }

      final speedFactor = (rider.speedKmh / 48.0).clamp(0.0, 1.45);
      final fenderAttenuation = rider.hasFenders ? 0.32 : 1.0;
      final baseFilmSpray =
          (preset.waterFilmDepthMm / 2.8).clamp(0.0, 0.65) * speedFactor;
      final puddleBurst = maxPuddleDepth * speedFactor * 1.15;
      final totalSpray =
          ((baseFilmSpray + puddleBurst) * fenderAttenuation).clamp(0.0, 1.0);

      puddleHitByRider[rider.riderId] = maxPuddleDepth;
      sprayIntensityByRider[rider.riderId] = totalSpray;

      // Aktualizacja istniejących kropel wody i emisja nowych.
      final existing = _dropletsByRider[rider.riderId] ?? <WaterDroplet3D>[];
      final updated = <WaterDroplet3D>[];
      for (final drop in existing) {
        final next = drop.advance(dt);
        if (next.lifeSeconds < next.maxLifeSeconds && next.heightMeters > 0.0) {
          updated.add(next);
        }
      }

      final spawnCount = (totalSpray * (maxPuddleDepth > 0.05 ? 26 : 9)).round();
      final speedMs = rider.speedKmh / 3.6;
      for (var i = 0;
          i < spawnCount && updated.length < config.maxDropletsPerPlume;
          i++) {
        final isPuddle = maxPuddleDepth > 0.05;
        final spreadAngle = (_rng.nextDouble() - 0.5) * (isPuddle ? 0.58 : 0.28);
        final upwardVel =
            (isPuddle ? 3.2 : 1.4) + _rng.nextDouble() * (isPuddle ? 2.6 : 1.2) * speedFactor;
        final backVel = -(speedMs * (0.28 + _rng.nextDouble() * 0.25));

        updated.add(
          WaterDroplet3D(
            lateralOffsetMeters:
                rider.lateralOffsetMeters + (_rng.nextDouble() - 0.5) * 0.14,
            heightMeters: 0.18 + _rng.nextDouble() * 0.16,
            distanceMeters: rider.distanceMeters - 0.38,
            vxLateral: math.sin(spreadAngle) * (isPuddle ? 2.2 : 0.85),
            vyHeight: upwardVel,
            vzLongitudinal: backVel,
            radiusPx: isPuddle ? (1.8 + _rng.nextDouble() * 1.9) : (1.1 + _rng.nextDouble() * 1.0),
            alpha: isPuddle ? (0.68 + _rng.nextDouble() * 0.3) : (0.35 + _rng.nextDouble() * 0.25),
            lifeSeconds: 0.0,
            maxLifeSeconds: isPuddle ? (0.48 + _rng.nextDouble() * 0.34) : (0.26 + _rng.nextDouble() * 0.2),
            isFromPuddle: isPuddle,
          ),
        );
      }

      _dropletsByRider[rider.riderId] = updated;

      if (totalSpray > 0.04 || updated.isNotEmpty) {
        plumes.add(
          TireSprayPlume3D(
            sourceRiderId: rider.riderId,
            originDistanceM: rider.distanceMeters - 0.36,
            originLateralM: rider.lateralOffsetMeters,
            plumeHeightM: 0.35 + totalSpray * (maxPuddleDepth > 0.05 ? 1.15 : 0.55),
            plumeLengthM: 1.2 + totalSpray * 3.1,
            intensity: totalSpray,
            isPuddleSplash: maxPuddleDepth > 0.05,
            droplets: List<WaterDroplet3D>.unmodifiable(updated),
          ),
        );
      }
    }

    // 3. Oblewanie rywali jadących bezpośrednio na kole i aktualizacja komfortu termicznego.
    final riderStates = <RiderThermalWetnessState>[];
    var activeSplashCount = 0;
    var totalWetness = 0.0;
    var lowestComfort = 100.0;
    var totalDroplets = 0;

    for (final follower in riders) {
      var exposureFromLeader = 0.0;
      String? drenchingLeaderId;

      for (final leader in riders) {
        if (leader.riderId == follower.riderId) continue;
        final gapM = leader.distanceMeters - follower.distanceMeters;
        if (gapM < 0.35 || gapM > config.sprayDraftReachMeters) continue;

        final lateralGap =
            (leader.lateralOffsetMeters - follower.lateralOffsetMeters).abs();
        if (lateralGap > config.sprayLateralSpreadMeters) continue;

        final leaderSpray = sprayIntensityByRider[leader.riderId] ?? 0.0;
        if (leaderSpray <= 0.02) continue;

        final distAttenuation =
            1.0 - (gapM / config.sprayDraftReachMeters).clamp(0.0, 1.0);
        final latAttenuation =
            1.0 - (lateralGap / config.sprayLateralSpreadMeters).clamp(0.0, 1.0);
        final hitExposure =
            leaderSpray * (0.45 + 0.55 * distAttenuation) * latAttenuation;

        if (hitExposure > exposureFromLeader) {
          exposureFromLeader = hitExposure;
          drenchingLeaderId = leader.riderId;
        }
      }

      final selfPuddle = puddleHitByRider[follower.riderId] ?? 0.0;
      final inPuddle = selfPuddle > 0.05;
      if (inPuddle) activeSplashCount++;

      final prevWetness = _wetnessByRider[follower.riderId] ?? 0.0;
      final rainWetGain = preset.rainIntensity * 0.08 * dt;
      final selfPuddleGain = selfPuddle * 0.35 * dt;
      final wheelSprayGain = exposureFromLeader * 0.92 * dt;
      final drying =
          (1.0 - preset.rainIntensity) * config.dryingRatePerSecond * dt;

      final nextWetness =
          (prevWetness + rainWetGain + selfPuddleGain + wheelSprayGain - drying)
              .clamp(0.0, 1.0);
      _wetnessByRider[follower.riderId] = nextWetness;

      final prevComfort =
          _comfortByRider[follower.riderId] ?? follower.baseThermalComfort;
      final coldGap =
          math.max(0.0, 21.0 - follower.ambientTempCelsius) / 17.0;
      final windChillFactor =
          1.0 + (follower.speedKmh / 45.0) * 0.45 + (effectiveWind / 10.0) * 0.35;

      final coolingDrop =
          (nextWetness * config.coolingRatePerWetness * (0.35 + coldGap) * windChillFactor +
                  exposureFromLeader * 3.4) *
              dt;
      final thermalRecovery =
          (nextWetness < 0.2 && follower.ambientTempCelsius > 14.0)
              ? 1.1 * dt
              : 0.0;

      final nextComfort =
          (prevComfort - coolingDrop + thermalRecovery).clamp(5.0, 100.0);
      _comfortByRider[follower.riderId] = nextComfort;

      final skinTemp = (33.5 -
              nextWetness * 6.8 * (0.4 + 0.6 * coldGap) -
              (1.0 - nextComfort / 100.0) * 3.2)
          .clamp(21.0, 36.8);

      final shiveringPenalty =
          nextComfort < 50.0 ? ((50.0 - nextComfort) / 45.0 * 16.0).clamp(0.0, 16.0) : 0.0;

      final selfSpray = sprayIntensityByRider[follower.riderId] ?? 0.0;
      final TireSprayIntensityTier tier;
      if (selfSpray < 0.06) {
        tier = TireSprayIntensityTier.none;
      } else if (selfSpray < 0.35) {
        tier = TireSprayIntensityTier.mist;
      } else if (selfSpray < 0.68 && !inPuddle) {
        tier = TireSprayIntensityTier.roosterTail;
      } else {
        tier = TireSprayIntensityTier.heavyPlume;
      }

      totalWetness += nextWetness;
      if (nextComfort < lowestComfort) lowestComfort = nextComfort;
      totalDroplets += (_dropletsByRider[follower.riderId]?.length ?? 0);

      riderStates.add(
        RiderThermalWetnessState(
          riderId: follower.riderId,
          riderName: follower.riderName,
          teamColor: follower.teamColor,
          distanceMeters: follower.distanceMeters,
          lateralOffsetMeters: follower.lateralOffsetMeters,
          speedKmh: follower.speedKmh,
          wetnessLevel: nextWetness,
          splashExposureRate: exposureFromLeader,
          thermalComfort: nextComfort,
          effectiveSkinTempCelsius: skinTemp,
          shiveringPenaltyPct: shiveringPenalty,
          inPuddle: inPuddle,
          drenchedByRiderId: drenchingLeaderId,
          sprayTier: tier,
        ),
      );
    }

    final avgWetness =
        riders.isEmpty ? 0.0 : (totalWetness / riders.length).clamp(0.0, 1.0);

    return PuddleSplashFrameSnapshot(
      elapsedSeconds: _elapsedSeconds,
      preset: preset,
      puddles: puddles,
      plumes: List<TireSprayPlume3D>.unmodifiable(plumes),
      riderStates: List<RiderThermalWetnessState>.unmodifiable(riderStates),
      activeSplashCount: activeSplashCount,
      averagePelotonWetness: avgWetness,
      lowestThermalComfort: riders.isEmpty ? 100.0 : lowestComfort,
      totalActiveDroplets: totalDroplets,
    );
  }
}

/// Rzutnik 3D mokrej szosy, kałuż na poboczach, pióropuszy kropel oraz stref zmoczenia rywali.
class DynamicPuddleSplash3dPainter extends CustomPainter {
  final PuddleSplashFrameSnapshot snapshot;
  final double roadWidthMeters;
  final double cameraFocusDistanceM;

  const DynamicPuddleSplash3dPainter({
    required this.snapshot,
    this.roadWidthMeters = 7.5,
    this.cameraFocusDistanceM = 112.0,
  });

  Offset _project(
    Size size,
    double distanceM,
    double lateralM,
    double heightM,
  ) {
    final relZ = (distanceM - (cameraFocusDistanceM - 10.0)).clamp(1.2, 42.0);
    final persp = 1.0 / (0.14 * relZ + 0.55);
    final horizonY = size.height * 0.24;
    final screenY = horizonY + (size.height * 0.72) * persp - heightM * 56.0 * persp;
    final screenX = size.width * 0.5 + lateralM * (size.width * 0.088) * persp;
    return Offset(screenX, screenY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Niebo burzowe i mokry horyzont.
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A0D13),
          Color(0xFF131924),
          Color(0xFF192231),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.26));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.26), skyPaint);

    // 2. Pobocze trawiaste i mokry asfalt z odbiciem nieba.
    final vergePaint = Paint()..color = const Color(0xFF111815);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.24, size.width, size.height * 0.76),
      vergePaint,
    );

    final halfRoad = roadWidthMeters * 0.5;
    final farLeft = _project(size, cameraFocusDistanceM + 26.0, -halfRoad, 0);
    final farRight = _project(size, cameraFocusDistanceM + 26.0, halfRoad, 0);
    final nearRight = _project(size, cameraFocusDistanceM - 8.5, halfRoad, 0);
    final nearLeft = _project(size, cameraFocusDistanceM - 8.5, -halfRoad, 0);

    final roadPath = Path()
      ..moveTo(farLeft.dx, farLeft.dy)
      ..lineTo(farRight.dx, farRight.dy)
      ..lineTo(nearRight.dx, nearRight.dy)
      ..lineTo(nearLeft.dx, nearLeft.dy)
      ..close();

    final asphaltPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A202B),
          Color.lerp(
            const Color(0xFF202734),
            const Color(0xFF263547),
            snapshot.preset.rainIntensity * 0.55,
          )!,
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.24, size.width, size.height * 0.76));
    canvas.drawPath(roadPath, asphaltPaint);

    // Linie pobocza.
    final linePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.42)
      ..strokeWidth = 1.6;
    canvas.drawLine(farLeft, nearLeft, linePaint);
    canvas.drawLine(farRight, nearRight, linePaint);

    // 3. Kałuże na poboczu asfaltu z falowaniem lustra wody.
    for (final puddle in snapshot.puddles) {
      final center = _project(
        size,
        puddle.distanceMeters,
        puddle.lateralOffsetMeters,
        0.0,
      );
      if (center.dy < size.height * 0.24 || center.dy > size.height * 1.05) {
        continue;
      }
      final relZ =
          (puddle.distanceMeters - (cameraFocusDistanceM - 10.0)).clamp(1.2, 42.0);
      final persp = 1.0 / (0.14 * relZ + 0.55);
      final rx = puddle.widthMeters * 22.0 * persp;
      final ry = puddle.lengthMeters * 5.2 * persp;

      final puddleRect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
      final puddlePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.cyanAccent.withValues(alpha: 0.34),
            AppColors.accentBlue.withValues(alpha: 0.22),
            const Color(0xFF0E1B2A).withValues(alpha: 0.45),
          ],
        ).createShader(puddleRect);
      canvas.drawOval(puddleRect, puddlePaint);

      final rippleScale = 0.55 + 0.38 * math.sin(puddle.ripplePhase);
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = AppColors.cyanAccent.withValues(alpha: 0.45 * (1.0 - rippleScale * 0.4));
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: rx * 1.5 * rippleScale,
          height: ry * 1.5 * rippleScale,
        ),
        ripplePaint,
      );
    }

    // 4. Kolarze i pióropusze kropel posortowane od najdalszego do najbliższego.
    final sortedRiders = List<RiderThermalWetnessState>.from(snapshot.riderStates)
      ..sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));

    final plumeByRider = <String, TireSprayPlume3D>{
      for (final p in snapshot.plumes) p.sourceRiderId: p,
    };

    for (final rider in sortedRiders) {
      final base = _project(
        size,
        rider.distanceMeters,
        rider.lateralOffsetMeters,
        0.0,
      );
      final relZ =
          (rider.distanceMeters - (cameraFocusDistanceM - 10.0)).clamp(1.2, 42.0);
      final persp = 1.0 / (0.14 * relZ + 0.55);

      // Pióropusz wody za tylnym kołem.
      final plume = plumeByRider[rider.riderId];
      if (plume != null) {
        final tailEnd = _project(
          size,
          plume.originDistanceM - plume.plumeLengthM,
          plume.originLateralM,
          plume.plumeHeightM * 0.45,
        );
        final conePaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (plume.isPuddleSplash
                      ? AppColors.cyanAccent
                      : AppColors.accentBlue)
                  .withValues(alpha: 0.34 * plume.intensity),
              Colors.transparent,
            ],
          ).createShader(Rect.fromPoints(base, tailEnd));
        final conePath = Path()
          ..moveTo(base.dx, base.dy - 4 * persp)
          ..lineTo(tailEnd.dx - 16 * persp, tailEnd.dy)
          ..lineTo(tailEnd.dx + 16 * persp, tailEnd.dy)
          ..close();
        canvas.drawPath(conePath, conePaint);

        for (final drop in plume.droplets) {
          final dp = _project(
            size,
            drop.distanceMeters,
            drop.lateralOffsetMeters,
            drop.heightMeters,
          );
          final dropPaint = Paint()
            ..color = (drop.isFromPuddle
                    ? AppColors.cyanAccent
                    : AppColors.accentBlue)
                .withValues(
              alpha: (drop.alpha * (1.0 - drop.normalizedLife)).clamp(0.0, 1.0),
            );
          canvas.drawCircle(dp, drop.radiusPx * persp.clamp(0.55, 1.35), dropPaint);
        }
      }

      // Sylwetka kolarza 3D.
      final bikeH = 26.0 * persp;
      final wheelR = 6.5 * persp;
      final framePaint = Paint()
        ..color = rider.teamColor
        ..strokeWidth = (2.6 * persp).clamp(1.2, 4.0)
        ..strokeCap = StrokeCap.round;
      final wheelPaint = Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.8 * persp).clamp(1.0, 3.0);

      canvas.drawCircle(Offset(base.dx, base.dy - wheelR), wheelR, wheelPaint);
      canvas.drawLine(
        Offset(base.dx, base.dy - wheelR),
        Offset(base.dx, base.dy - bikeH * 0.72),
        framePaint,
      );
      // Tułów i kask.
      canvas.drawCircle(
        Offset(base.dx, base.dy - bikeH * 0.88),
        (4.2 * persp).clamp(2.2, 7.0),
        Paint()..color = rider.teamColor,
      );

      // Pierścień zmoczenia / wychłodzenia jeśli kolarz jest oblewany na kole.
      if (rider.drenchedByRiderId != null || rider.wetnessLevel > 0.35) {
        final thermalColor = rider.thermalComfort < 45.0
            ? AppColors.crimsonAlert
            : (rider.drenchedByRiderId != null
                ? AppColors.cyanAccent
                : AppColors.accentBlue);
        final haloPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = thermalColor.withValues(alpha: 0.75);
        canvas.drawCircle(
          Offset(base.dx, base.dy - bikeH * 0.55),
          (11.0 * persp).clamp(5.0, 18.0),
          haloPaint,
        );
      }
    }

    // 5. Diagonalne smugi deszczu na pierwszym planie.
    final rainCount = (snapshot.preset.rainIntensity * 46).round();
    final rainPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.16)
      ..strokeWidth = 1.0;
    final phase = (snapshot.elapsedSeconds * 190.0) % size.height;
    for (var i = 0; i < rainCount; i++) {
      final rx = ((i * 73.0 + snapshot.elapsedSeconds * 42.0) % size.width);
      final ry = ((i * 59.0 + phase) % size.height);
      canvas.drawLine(Offset(rx, ry), Offset(rx - 5.0, ry + 14.0), rainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant DynamicPuddleSplash3dPainter oldDelegate) => true;
}

/// Produkcyjny panel kontrolny i podgląd 3D efektów kałuż oraz pióropuszy wody z kół.
class DynamicPuddleSplashControlPanel extends StatefulWidget {
  final WetRoadRainPreset initialPreset;

  const DynamicPuddleSplashControlPanel({
    super.key,
    this.initialPreset = WetRoadRainPreset.steadySpringRain,
  });

  @override
  State<DynamicPuddleSplashControlPanel> createState() =>
      _DynamicPuddleSplashControlPanelState();
}

class _DynamicPuddleSplashControlPanelState
    extends State<DynamicPuddleSplashControlPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late final DynamicPuddleSplashAndTireSpray3d _engine;
  late WetRoadRainPreset _preset;
  late PuddleSplashFrameSnapshot _snapshot;

  bool _isRunning = true;
  double _leadDistanceM = 112.0;
  double _leadLateralM = 2.45;
  int _lastTickMicros = 0;

  @override
  void initState() {
    super.initState();
    _preset = widget.initialPreset;
    _engine = DynamicPuddleSplashAndTireSpray3d();
    _engine.generateRoadsidePuddles(
      startDistanceM: 90.0,
      endDistanceM: 280.0,
      preset: _preset,
    );
    _snapshot = _engine.stepSimulation(
      dtSeconds: 0.016,
      riders: _buildRiders(),
      preset: _preset,
    );
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_onFrameTick);
    _ticker.repeat();
  }

  @override
  void dispose() {
    _ticker.removeListener(_onFrameTick);
    _ticker.dispose();
    super.dispose();
  }

  List<RiderWetRoadInput> _buildRiders() {
    return <RiderWetRoadInput>[
      RiderWetRoadInput(
        riderId: 'lead',
        riderName: 'V. Campenaerts',
        teamColor: AppColors.goldAccent,
        distanceMeters: _leadDistanceM,
        lateralOffsetMeters: _leadLateralM,
        speedKmh: 49.5,
        ambientTempCelsius: _preset.ambientTempCelsius,
      ),
      RiderWetRoadInput(
        riderId: 'wheel_1',
        riderName: 'M. van der Poel',
        teamColor: AppColors.primaryAccent,
        distanceMeters: _leadDistanceM - 1.35,
        lateralOffsetMeters: _leadLateralM - 0.08,
        speedKmh: 49.5,
        ambientTempCelsius: _preset.ambientTempCelsius,
      ),
      RiderWetRoadInput(
        riderId: 'wheel_2',
        riderName: 'W. van Aert',
        teamColor: AppColors.accentBlue,
        distanceMeters: _leadDistanceM - 2.85,
        lateralOffsetMeters: _leadLateralM + 0.12,
        speedKmh: 49.2,
        ambientTempCelsius: _preset.ambientTempCelsius,
      ),
      RiderWetRoadInput(
        riderId: 'clear_line',
        riderName: 'T. Pogačar',
        teamColor: AppColors.statusSuccess,
        distanceMeters: _leadDistanceM - 1.5,
        lateralOffsetMeters: -1.15,
        speedKmh: 49.4,
        ambientTempCelsius: _preset.ambientTempCelsius,
      ),
    ];
  }

  void _onFrameTick() {
    if (!_isRunning) return;
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    final dt = _lastTickMicros == 0
        ? 0.016
        : ((nowMicros - _lastTickMicros) / 1000000.0).clamp(0.008, 0.05);
    _lastTickMicros = nowMicros;

    setState(() {
      _leadDistanceM += 13.75 * dt;
      if (_leadDistanceM > 250.0) {
        _leadDistanceM = 104.0;
      }
      _snapshot = _engine.stepSimulation(
        dtSeconds: dt,
        riders: _buildRiders(),
        preset: _preset,
      );
    });
  }

  void _selectPreset(WetRoadRainPreset preset) {
    setState(() {
      _preset = preset;
      _engine.generateRoadsidePuddles(
        startDistanceM: 90.0,
        endDistanceM: 280.0,
        preset: _preset,
      );
      _snapshot = _engine.stepSimulation(
        dtSeconds: 0.016,
        riders: _buildRiders(),
        preset: _preset,
      );
    });
  }

  void _triggerShoulderPuddleHit() {
    setState(() {
      _leadLateralM = 2.65;
      _engine.setPuddles(<RoadsidePuddle3D>[
        RoadsidePuddle3D(
          id: 'manual_shoulder_puddle',
          distanceMeters: _leadDistanceM + 0.4,
          lateralOffsetMeters: _leadLateralM,
          lengthMeters: 4.5,
          widthMeters: 1.6,
          depthMm: 14.0,
          side: RoadPuddleSide.rightShoulder,
        ),
        ..._engine.puddles,
      ]);
      _snapshot = _engine.stepSimulation(
        dtSeconds: 0.032,
        riders: _buildRiders(),
        preset: _preset,
      );
    });
  }

  void _resetSimulation() {
    setState(() {
      _leadDistanceM = 112.0;
      _leadLateralM = 2.45;
      _engine.reset();
      _engine.generateRoadsidePuddles(
        startDistanceM: 90.0,
        endDistanceM: 280.0,
        preset: _preset,
      );
      _snapshot = _engine.stepSimulation(
        dtSeconds: 0.016,
        riders: _buildRiders(),
        preset: _preset,
      );
    });
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
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final isCompact = constraints.maxWidth < 520;

          final viewport = Container(
            height: isCompact ? 220 : 280,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor, width: 1.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: DynamicPuddleSplash3dPainter(
                snapshot: _snapshot,
                cameraFocusDistanceM: _leadDistanceM,
              ),
              child: const SizedBox.expand(),
            ),
          );

          final telemetry = _buildTelemetrySection(isCompact);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 12),
                _buildPresetBar(),
                const SizedBox(height: 14),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: viewport),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: telemetry),
                    ],
                  )
                else ...[
                  viewport,
                  const SizedBox(height: 14),
                  telemetry,
                ],
                const SizedBox(height: 14),
                _buildRiderList(isCompact),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InteractiveActionChip(
          label: _isRunning ? 'Pauza' : 'Wznów',
          icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          isActive: _isRunning,
          onPressed: () => setState(() => _isRunning = !_isRunning),
        ),
        _InteractiveActionChip(
          label: 'Kałuża na poboczu',
          icon: Icons.water_drop_rounded,
          isActive: _snapshot.activeSplashCount > 0,
          onPressed: _triggerShoulderPuddleHit,
        ),
        _InteractiveActionChip(
          label: 'Reset',
          icon: Icons.refresh_rounded,
          isActive: false,
          onPressed: _resetSimulation,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rozbryzg z kałuż i wychłodzenie na kole 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          controls,
        ],
      );
    }

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Rozbryzg z kałuż i wychłodzenie na kole 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        controls,
      ],
    );
  }

  Widget _buildPresetBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WetRoadRainPreset.values.map((preset) {
        final selected = preset == _preset;
        return _InteractiveActionChip(
          label: preset.label,
          icon: Icons.grain_rounded,
          isActive: selected,
          onPressed: () => _selectPreset(preset),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildTelemetrySection(bool isCompact) {
    final avgWetPct = (_snapshot.averagePelotonWetness * 100.0).toStringAsFixed(0);
    final minComfort = _snapshot.lowestThermalComfort.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Telemetria mokrej szosy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Wjazdy w kałuże',
                value: '${_snapshot.activeSplashCount}',
                accent: AppColors.cyanAccent,
                width: isCompact ? 130 : 145,
              ),
              _MetricTile(
                label: 'Krople w locie',
                value: '${_snapshot.totalActiveDroplets}',
                accent: AppColors.accentBlue,
                width: isCompact ? 130 : 145,
              ),
              _MetricTile(
                label: 'Śr. zmoczenie',
                value: '$avgWetPct%',
                accent: AppColors.amberWarning,
                width: isCompact ? 130 : 145,
              ),
              _MetricTile(
                label: 'Min. komfort',
                value: '$minComfort / 100',
                accent: _snapshot.lowestThermalComfort < 50.0
                    ? AppColors.crimsonAlert
                    : AppColors.statusSuccess,
                width: isCompact ? 130 : 145,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiderList(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Komfort termiczny i zmoczenie rywali na kole',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        ..._snapshot.riderStates.map((rider) {
          final wetPct = (rider.wetnessLevel * 100.0).toStringAsFixed(0);
          final comfortStr = rider.thermalComfort.toStringAsFixed(1);
          final tempStr = rider.effectiveSkinTempCelsius.toStringAsFixed(1);
          final statusText = rider.drenchedByRiderId != null
              ? 'Oblewany na kole'
              : (rider.inPuddle ? 'W kałuży!' : rider.sprayTier.label);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: rider.drenchedByRiderId != null
                    ? AppColors.cyanAccent.withValues(alpha: 0.45)
                    : AppTheme.borderColor,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: rider.teamColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.riderName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        statusText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: rider.drenchedByRiderId != null
                              ? AppColors.cyanAccent
                              : AppColors.textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCompact) ...[
                  Text(
                    '$tempStr°C',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Text(
                  'Wilg. $wetPct% • Komf. $comfortStr',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: rider.thermalComfort < 50.0
                        ? AppColors.crimsonAlert
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final double width;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
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
  final VoidCallback? onPressed;

  const _InteractiveActionChip({
    required this.label,
    required this.icon,
    required this.isActive,
    this.onPressed,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final bgColor = disabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : (widget.isActive
            ? AppColors.primaryAccent
            : (_isPressed
                ? AppColors.surfaceLight
                : (_isHovered ? const Color(0xFF282D3A) : AppColors.surfaceLight)));

    final borderColor = disabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : (_isFocused
            ? AppColors.goldAccent
            : (widget.isActive ? AppColors.goldAccent : AppTheme.borderColor));

    final fgColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: disabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: MouseRegion(
          cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                    letterSpacing: -0.2,
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
