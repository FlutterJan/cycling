// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/race/stage_segment.dart';

/// Rodzaj osadu zbierającego się na kolarzu i rowerze podczas wyścigu.
enum SplatterMedium {
  /// Ciemne, lepkie błoto z mokrego bruku Paris-Roubaix lub rozmoczonych poboczy.
  mud('Błoto'),

  /// Jasny, kredowy biały pył z szutrów Strade Bianche lub suchego bruku.
  chalkDust('Biały pył'),

  /// Mieszanka wody, gliny i pyłu w zmiennych warunkach pogodowych.
  mixedSlurry('Szlam');

  final String label;
  const SplatterMedium(this.label);
}

/// Strefa ciała lub sprzętu kolarza objęta progresywnym brudzeniem.
enum RiderSplatterZone {
  /// Twarz (policzki, nos, broda wokół okularów).
  face('Twarz', 0.82),

  /// Soczewki i oprawki okularów kolarskich.
  eyewear('Okulary', 0.88),

  /// Łydki i skarpetki (najbliżej kół — najszybsze brudzenie).
  calves('Łydki', 1.38),

  /// Rama roweru, widelec i tylny trójkąt.
  bikeFrame('Rama roweru', 1.28),

  /// Koszulka kolarska (przód od koła poprzednika i plecy od własnego koła).
  jersey('Koszulka', 1.02);

  final String label;
  final double defaultWeight;
  const RiderSplatterZone(this.label, this.defaultWeight);
}

/// Pozycja kolarza w peletonie determinująca intensywność rozbryzgu z kół innych kolarzy.
enum PelotonDraftExposureRole {
  /// Jazda solo lub na samym czele — tylko własny rozbryzg spod kół.
  soloLeader('Solo / Czoło', 0.35),

  /// Jazda z boku grupy lub w wachlarzu — umiarkowany rozbryzg.
  echelonSide('Bok / Wachlarz', 0.85),

  /// Jazda bezpośrednio na kole poprzednika — silny strumień błota/pyłu.
  onWheel('Na kole', 1.78),

  /// Środek gęstego peletonu — maksymalna chmura pyłu i błota ze wszystkich stron.
  deepPeloton('Środek peletonu', 2.35);

  final String label;
  final double exposureMultiplier;
  const PelotonDraftExposureRole(this.label, this.exposureMultiplier);
}

/// Gotowe scenariusze pogodowo-nawierzchniowe dla podglądu i symulacji brudzenia.
enum SplatterConditionPreset {
  parisRoubaixWetCobbles(
    label: 'Paris-Roubaix (Mokry bruk)',
    surfaceType: SegmentSurfaceType.cobblestonesSector5,
    wetness: 0.92,
    rainIntensity: 0.72,
    speedKmh: 41.0,
  ),
  stradeBiancheDryDust(
    label: 'Strade Bianche (Biały pył)',
    surfaceType: SegmentSurfaceType.gravelStrade,
    wetness: 0.04,
    rainIntensity: 0.0,
    speedKmh: 38.0,
  ),
  stradeBiancheMuddyRain(
    label: 'Strade Bianche (Deszcz i glina)',
    surfaceType: SegmentSurfaceType.gravelStrade,
    wetness: 0.88,
    rainIntensity: 0.65,
    speedKmh: 34.0,
  ),
  flandersRainAsphalt(
    label: 'Flandria (Deszcz na asfalcie)',
    surfaceType: SegmentSurfaceType.roughAsphalt,
    wetness: 0.82,
    rainIntensity: 0.58,
    speedKmh: 44.0,
  ),
  cleanDryRoad(
    label: 'Suchy czysty asfalt',
    surfaceType: SegmentSurfaceType.smoothAsphalt,
    wetness: 0.0,
    rainIntensity: 0.0,
    speedKmh: 45.0,
  );

  final String label;
  final SegmentSurfaceType surfaceType;
  final double wetness;
  final double rainIntensity;
  final double speedKmh;

  const SplatterConditionPreset({
    required this.label,
    required this.surfaceType,
    required this.wetness,
    required this.rainIntensity,
    required this.speedKmh,
  });
}

/// Konfiguracja parametrów fizycznych i wizualnych [MudAndDustSplatterAccumulation].
class MudAndDustSplatterConfig {
  final double baseAccumulationRatePerSecond;
  final double soloLeaderMultiplier;
  final double echelonSideMultiplier;
  final double onWheelMultiplier;
  final double deepPelotonMultiplier;
  final double rainWashOffRatePerSecond;
  final double dryingRatePerSecond;
  final double eyewearWipeEfficiency;
  final int maxDropletsPerZone;
  final Map<RiderSplatterZone, double> zoneWeights;

  const MudAndDustSplatterConfig({
    this.baseAccumulationRatePerSecond = 0.011,
    this.soloLeaderMultiplier = 0.35,
    this.echelonSideMultiplier = 0.85,
    this.onWheelMultiplier = 1.78,
    this.deepPelotonMultiplier = 2.35,
    this.rainWashOffRatePerSecond = 0.0045,
    this.dryingRatePerSecond = 0.005,
    this.eyewearWipeEfficiency = 0.45,
    this.maxDropletsPerZone = 48,
    this.zoneWeights = const {
      RiderSplatterZone.face: 0.82,
      RiderSplatterZone.eyewear: 0.88,
      RiderSplatterZone.calves: 1.38,
      RiderSplatterZone.bikeFrame: 1.28,
      RiderSplatterZone.jersey: 1.02,
    },
  });

  double weightForZone(RiderSplatterZone zone) {
    return zoneWeights[zone] ?? zone.defaultWeight;
  }

  MudAndDustSplatterConfig copyWith({
    double? baseAccumulationRatePerSecond,
    double? soloLeaderMultiplier,
    double? echelonSideMultiplier,
    double? onWheelMultiplier,
    double? deepPelotonMultiplier,
    double? rainWashOffRatePerSecond,
    double? dryingRatePerSecond,
    double? eyewearWipeEfficiency,
    int? maxDropletsPerZone,
    Map<RiderSplatterZone, double>? zoneWeights,
  }) {
    return MudAndDustSplatterConfig(
      baseAccumulationRatePerSecond:
          baseAccumulationRatePerSecond ?? this.baseAccumulationRatePerSecond,
      soloLeaderMultiplier: soloLeaderMultiplier ?? this.soloLeaderMultiplier,
      echelonSideMultiplier:
          echelonSideMultiplier ?? this.echelonSideMultiplier,
      onWheelMultiplier: onWheelMultiplier ?? this.onWheelMultiplier,
      deepPelotonMultiplier:
          deepPelotonMultiplier ?? this.deepPelotonMultiplier,
      rainWashOffRatePerSecond:
          rainWashOffRatePerSecond ?? this.rainWashOffRatePerSecond,
      dryingRatePerSecond: dryingRatePerSecond ?? this.dryingRatePerSecond,
      eyewearWipeEfficiency:
          eyewearWipeEfficiency ?? this.eyewearWipeEfficiency,
      maxDropletsPerZone: maxDropletsPerZone ?? this.maxDropletsPerZone,
      zoneWeights: zoneWeights ?? this.zoneWeights,
    );
  }
}

/// Pojedyncza deterministyczna kropka błota lub pyłu przypisana do strefy kolarza.
class SplatterDroplet {
  final int id;
  final RiderSplatterZone zone;
  final SplatterMedium medium;
  final double u;
  final double v;
  final double radiusPx;
  final double opacity;
  final double threshold;
  final double elongation;
  final double angleRadians;

  const SplatterDroplet({
    required this.id,
    required this.zone,
    required this.medium,
    required this.u,
    required this.v,
    required this.radiusPx,
    required this.opacity,
    required this.threshold,
    required this.elongation,
    required this.angleRadians,
  });
}

/// Dane wejściowe pojedynczej klatki symulacji brudzenia dla kolarza.
class RiderSplatterFrameInput {
  final int riderId;
  final SegmentSurfaceType surfaceType;
  final double wetness;
  final double rainIntensity;
  final double speedKmh;
  final double draftingSavingsRatio;
  final double distanceToAheadRiderMeters;
  final int nearbyRidersCount;
  final bool isWipingEyewear;

  const RiderSplatterFrameInput({
    required this.riderId,
    required this.surfaceType,
    required this.wetness,
    required this.rainIntensity,
    required this.speedKmh,
    this.draftingSavingsRatio = 0.0,
    this.distanceToAheadRiderMeters = 25.0,
    this.nearbyRidersCount = 0,
    this.isWipingEyewear = false,
  });
}

/// Skumulowany stan zabrudzenia kolarza oraz jego roweru w poszczególnych strefach.
class RiderSplatterState {
  final int riderId;
  final Map<RiderSplatterZone, double> mudCoverageByZone;
  final Map<RiderSplatterZone, double> dustCoverageByZone;
  final double moistureLevel;
  final PelotonDraftExposureRole exposureRole;
  final double lastAccumulationRate;
  final double totalDistanceSplatteredMeters;

  const RiderSplatterState({
    required this.riderId,
    required this.mudCoverageByZone,
    required this.dustCoverageByZone,
    required this.moistureLevel,
    required this.exposureRole,
    required this.lastAccumulationRate,
    required this.totalDistanceSplatteredMeters,
  });

  factory RiderSplatterState.clean(int riderId) {
    return RiderSplatterState(
      riderId: riderId,
      mudCoverageByZone: {
        for (final zone in RiderSplatterZone.values) zone: 0.0,
      },
      dustCoverageByZone: {
        for (final zone in RiderSplatterZone.values) zone: 0.0,
      },
      moistureLevel: 0.0,
      exposureRole: PelotonDraftExposureRole.soloLeader,
      lastAccumulationRate: 0.0,
      totalDistanceSplatteredMeters: 0.0,
    );
  }

  double mudForZone(RiderSplatterZone zone) =>
      (mudCoverageByZone[zone] ?? 0.0).clamp(0.0, 1.0);

  double dustForZone(RiderSplatterZone zone) =>
      (dustCoverageByZone[zone] ?? 0.0).clamp(0.0, 1.0);

  double totalCoverageForZone(RiderSplatterZone zone) =>
      (mudForZone(zone) + dustForZone(zone)).clamp(0.0, 1.0);

  /// Średnie ogólne zabrudzenie wszystkich 5 stref kolarza i roweru [0.0..1.0].
  double get overallDirtyRatio {
    if (RiderSplatterZone.values.isEmpty) return 0.0;
    double sum = 0.0;
    for (final zone in RiderSplatterZone.values) {
      sum += totalCoverageForZone(zone);
    }
    return (sum / RiderSplatterZone.values.length).clamp(0.0, 1.0);
  }

  /// Średni poziom zabrudzenia błotem [0.0..1.0].
  double get averageMudRatio {
    double sum = 0.0;
    for (final zone in RiderSplatterZone.values) {
      sum += mudForZone(zone);
    }
    return (sum / RiderSplatterZone.values.length).clamp(0.0, 1.0);
  }

  /// Średni poziom pokrycia białym pyłem [0.0..1.0].
  double get averageDustRatio {
    double sum = 0.0;
    for (final zone in RiderSplatterZone.values) {
      sum += dustForZone(zone);
    }
    return (sum / RiderSplatterZone.values.length).clamp(0.0, 1.0);
  }

  /// Dominujący typ osadu na kolarzu.
  SplatterMedium get dominantMedium {
    final mud = averageMudRatio;
    final dust = averageDustRatio;
    if (mud > 0.05 && dust > 0.05 && (mud - dust).abs() < 0.20) {
      return SplatterMedium.mixedSlurry;
    }
    return mud >= dust ? SplatterMedium.mud : SplatterMedium.chalkDust;
  }

  RiderSplatterState copyWith({
    int? riderId,
    Map<RiderSplatterZone, double>? mudCoverageByZone,
    Map<RiderSplatterZone, double>? dustCoverageByZone,
    double? moistureLevel,
    PelotonDraftExposureRole? exposureRole,
    double? lastAccumulationRate,
    double? totalDistanceSplatteredMeters,
  }) {
    return RiderSplatterState(
      riderId: riderId ?? this.riderId,
      mudCoverageByZone: mudCoverageByZone ?? this.mudCoverageByZone,
      dustCoverageByZone: dustCoverageByZone ?? this.dustCoverageByZone,
      moistureLevel: moistureLevel ?? this.moistureLevel,
      exposureRole: exposureRole ?? this.exposureRole,
      lastAccumulationRate: lastAccumulationRate ?? this.lastAccumulationRate,
      totalDistanceSplatteredMeters:
          totalDistanceSplatteredMeters ?? this.totalDistanceSplatteredMeters,
    );
  }
}

/// Silnik progresywnego brudzenia kolarzy i rowerów podczas jazdy w deszczu,
/// po mokrym bruku Paris-Roubaix oraz po białym szutrze Strade Bianche.
class MudAndDustSplatterAccumulation {
  final MudAndDustSplatterConfig config;

  const MudAndDustSplatterAccumulation({
    this.config = const MudAndDustSplatterConfig(),
  });

  /// Klasyfikuje pozycję kolarza w peletonie na podstawie dystansu do poprzednika,
  /// oszczędności draftingu oraz liczby pobliskich kolarzy.
  PelotonDraftExposureRole classifyExposureRole(RiderSplatterFrameInput input) {
    final draft = input.draftingSavingsRatio.clamp(0.0, 1.0);
    if (input.nearbyRidersCount >= 6 && draft >= 0.28) {
      return PelotonDraftExposureRole.deepPeloton;
    }
    if (input.distanceToAheadRiderMeters <= 2.3 &&
        (draft >= 0.14 || input.nearbyRidersCount >= 1)) {
      return PelotonDraftExposureRole.onWheel;
    }
    if (input.nearbyRidersCount >= 2 || draft >= 0.08) {
      return PelotonDraftExposureRole.echelonSide;
    }
    return PelotonDraftExposureRole.soloLeader;
  }

  /// Wylicza mnożnik pozycji w peletonie — jadący na kole brudzą się znacznie szybciej.
  double computePelotonExposureMultiplier(
    PelotonDraftExposureRole role,
    RiderSplatterFrameInput input,
  ) {
    switch (role) {
      case PelotonDraftExposureRole.soloLeader:
        return config.soloLeaderMultiplier;
      case PelotonDraftExposureRole.echelonSide:
        return config.echelonSideMultiplier;
      case PelotonDraftExposureRole.onWheel:
        // Im bliżej tylnego koła poprzednika (<1.2 m), tym silniejszy rozbryzg.
        final closenessBoost =
            (1.0 - (input.distanceToAheadRiderMeters / 2.5)).clamp(0.0, 0.65);
        return config.onWheelMultiplier + closenessBoost * 0.55;
      case PelotonDraftExposureRole.deepPeloton:
        final crowdBoost =
            ((input.nearbyRidersCount - 6) * 0.04).clamp(0.0, 0.45);
        return config.deepPelotonMultiplier + crowdBoost;
    }
  }

  /// Wylicza intensywność powstawania błota [0.0..1.25] dla danej nawierzchni i wilgoci.
  double computeSurfaceMudFactor(
    SegmentSurfaceType surface,
    double wetness,
    double rainIntensity,
  ) {
    final w = wetness.clamp(0.0, 1.0);
    final r = rainIntensity.clamp(0.0, 1.0);
    final moisture = math.max(w, r * 0.85);

    switch (surface) {
      case SegmentSurfaceType.cobblestonesSector5:
        return moisture > 0.12 ? (0.35 + moisture * 0.90).clamp(0.0, 1.25) : 0.0;
      case SegmentSurfaceType.cobblestonesSector4:
        return moisture > 0.14 ? (0.28 + moisture * 0.82).clamp(0.0, 1.15) : 0.0;
      case SegmentSurfaceType.cobblestonesSector3:
        return moisture > 0.16 ? (0.22 + moisture * 0.72).clamp(0.0, 1.05) : 0.0;
      case SegmentSurfaceType.cobblestonesSector2:
      case SegmentSurfaceType.cobblestonesSector1:
        return moisture > 0.18 ? (0.16 + moisture * 0.60).clamp(0.0, 0.90) : 0.0;
      case SegmentSurfaceType.gravelStrade:
        return moisture > 0.22 ? (0.30 + moisture * 0.92).clamp(0.0, 1.22) : 0.0;
      case SegmentSurfaceType.roughAsphalt:
        return moisture > 0.25 ? (moisture * 0.42).clamp(0.0, 0.45) : 0.0;
      case SegmentSurfaceType.smoothAsphalt:
      case SegmentSurfaceType.concrete:
        return moisture > 0.35 ? (moisture * 0.26).clamp(0.0, 0.28) : 0.0;
    }
  }

  /// Wylicza intensywność białego pyłu [0.0..1.2] na suchym szutrze Strade Bianche i bruku.
  double computeSurfaceDustFactor(
    SegmentSurfaceType surface,
    double wetness,
  ) {
    final dryness = (1.0 - wetness.clamp(0.0, 1.0) * 2.4).clamp(0.0, 1.0);
    if (dryness <= 0.0) return 0.0;

    switch (surface) {
      case SegmentSurfaceType.gravelStrade:
        return 1.18 * dryness;
      case SegmentSurfaceType.cobblestonesSector5:
      case SegmentSurfaceType.cobblestonesSector4:
        return 0.56 * dryness;
      case SegmentSurfaceType.cobblestonesSector3:
      case SegmentSurfaceType.cobblestonesSector2:
      case SegmentSurfaceType.cobblestonesSector1:
        return 0.40 * dryness;
      case SegmentSurfaceType.roughAsphalt:
        return 0.08 * dryness;
      case SegmentSurfaceType.smoothAsphalt:
      case SegmentSurfaceType.concrete:
        return 0.0;
    }
  }

  /// Wykonuje pojedynczy krok progresywnego brudzenia dla kolarza w czasie [dtSeconds].
  RiderSplatterState step(
    RiderSplatterState current,
    RiderSplatterFrameInput input,
    double dtSeconds,
  ) {
    if (dtSeconds <= 0.0 || !dtSeconds.isFinite) {
      return current;
    }

    final wetness = input.wetness.clamp(0.0, 1.0);
    final rain = input.rainIntensity.clamp(0.0, 1.0);
    final speedKmh = input.speedKmh.clamp(0.0, 110.0);
    final role = classifyExposureRole(input);
    final roleMultiplier = computePelotonExposureMultiplier(role, input);

    // Poniżej 6 km/h koła prawie nie wyrzucają błota ani pyłu.
    final speedFactor =
        speedKmh < 6.0 ? 0.0 : ((speedKmh - 4.0) / 36.0).clamp(0.05, 1.75);

    final mudFactor =
        computeSurfaceMudFactor(input.surfaceType, wetness, rain);
    final dustFactor = computeSurfaceDustFactor(input.surfaceType, wetness);

    final baseMudGain = config.baseAccumulationRatePerSecond *
        mudFactor *
        roleMultiplier *
        speedFactor *
        dtSeconds;

    final baseDustGain = config.baseAccumulationRatePerSecond *
        dustFactor *
        roleMultiplier *
        speedFactor *
        dtSeconds;

    // Czysty deszcz na asfalcie lekko spłukuje wcześniej zebrany pył (i odrobinę świeżego błota).
    final isCleanRoadRain =
        rain > 0.25 && mudFactor < 0.45 && dustFactor == 0.0;
    final dustWashOff = isCleanRoadRain
        ? config.rainWashOffRatePerSecond * (0.5 + rain) * dtSeconds
        : 0.0;

    final nextMud = <RiderSplatterZone, double>{};
    final nextDust = <RiderSplatterZone, double>{};

    for (final zone in RiderSplatterZone.values) {
      final weight = config.weightForZone(zone);
      double mud = current.mudForZone(zone) + baseMudGain * weight;
      double dust = current.dustForZone(zone) + baseDustGain * weight;

      if (dustWashOff > 0.0) {
        dust = math.max(0.0, dust - dustWashOff * (0.7 + weight * 0.3));
      }

      // Wytarcie okularów rękawicą przez kolarza podczas deszczu/pyłu.
      if (input.isWipingEyewear && zone == RiderSplatterZone.eyewear) {
        final wipeDelta = config.eyewearWipeEfficiency * dtSeconds;
        mud = math.max(0.0, mud - wipeDelta);
        dust = math.max(0.0, dust - wipeDelta * 1.15);
      }

      // Suma błota i pyłu w jednej strefie nie może przekroczyć 1.0;
      // świeże błoto częściowo przykrywa stary pył.
      if (mud + dust > 1.0) {
        if (baseMudGain >= baseDustGain) {
          dust = math.max(0.0, 1.0 - mud);
        } else {
          mud = math.max(0.0, 1.0 - dust);
        }
      }

      nextMud[zone] = mud.clamp(0.0, 1.0);
      nextDust[zone] = dust.clamp(0.0, 1.0);
    }

    final targetMoisture = math.max(wetness, rain * 0.9);
    double nextMoisture = current.moistureLevel;
    if (targetMoisture > nextMoisture) {
      nextMoisture = math.min(
        targetMoisture,
        nextMoisture + dtSeconds * 0.35,
      );
    } else {
      nextMoisture = math.max(
        targetMoisture,
        nextMoisture - config.dryingRatePerSecond * dtSeconds,
      );
    }

    final distanceStepMeters = (speedKmh / 3.6) * dtSeconds;
    final instantRate = (baseMudGain + baseDustGain) / dtSeconds;

    return RiderSplatterState(
      riderId: input.riderId,
      mudCoverageByZone: nextMud,
      dustCoverageByZone: nextDust,
      moistureLevel: nextMoisture.clamp(0.0, 1.0),
      exposureRole: role,
      lastAccumulationRate: instantRate,
      totalDistanceSplatteredMeters:
          current.totalDistanceSplatteredMeters + distanceStepMeters,
    );
  }

  /// Deterministyczna pula kropek błota i białego pyłu dla wybranej strefy kolarza.
  List<SplatterDroplet> buildDropletsForZone({
    required int riderId,
    required RiderSplatterZone zone,
    required RiderSplatterState state,
  }) {
    final mudRatio = state.mudForZone(zone);
    final dustRatio = state.dustForZone(zone);
    final total = (mudRatio + dustRatio).clamp(0.0, 1.0);
    if (total <= 0.005) {
      return const [];
    }

    final count = config.maxDropletsPerZone;
    final droplets = <SplatterDroplet>[];
    final mudShare = total > 0.0 ? mudRatio / total : 0.0;

    // Deterministyczny hash na bazie ID kolarza i indeksu strefy (zero alokacji Random).
    int seed = (riderId * 73856093) ^ ((zone.index + 1) * 19349663);

    int nextRandInt() {
      seed = (seed * 1664525 + 1013904223) & 0x7fffffff;
      return seed;
    }

    double nextRand01() => nextRandInt() / 0x7fffffff;

    for (int i = 0; i < count; i++) {
      final threshold = (i + 0.5) / count;
      final r1 = nextRand01();
      final r2 = nextRand01();
      final r3 = nextRand01();
      final r4 = nextRand01();
      final r5 = nextRand01();

      if (threshold > total) {
        continue;
      }

      final isMud = r4 < mudShare;
      final medium = isMud ? SplatterMedium.mud : SplatterMedium.chalkDust;

      // Charakterystyczny rozkład kropek dla strefy:
      // łydki i rama mają większe, wydłużone chlapnięcia od dołu;
      // twarz i okulary mają drobniejsze kropki z wyraźnym pasem na policzkach.
      final double baseRadius;
      final double elongation;
      switch (zone) {
        case RiderSplatterZone.face:
          baseRadius = 1.1 + r3 * 2.4;
          elongation = 1.05 + r5 * 0.35;
          break;
        case RiderSplatterZone.eyewear:
          baseRadius = 0.9 + r3 * 2.0;
          elongation = 1.0 + r5 * 0.25;
          break;
        case RiderSplatterZone.calves:
          baseRadius = 1.5 + r3 * 3.4;
          elongation = 1.25 + r5 * 0.85;
          break;
        case RiderSplatterZone.bikeFrame:
          baseRadius = 1.6 + r3 * 3.6;
          elongation = 1.30 + r5 * 0.90;
          break;
        case RiderSplatterZone.jersey:
          baseRadius = 1.4 + r3 * 3.1;
          elongation = 1.15 + r5 * 0.65;
          break;
      }

      final visibilityFade =
          ((total - threshold) * 4.0).clamp(0.25, 1.0);
      final opacity = (0.55 + r5 * 0.40) * visibilityFade;

      droplets.add(
        SplatterDroplet(
          id: i,
          zone: zone,
          medium: medium,
          u: r1,
          v: r2,
          radiusPx: baseRadius,
          opacity: opacity.clamp(0.0, 0.96),
          threshold: threshold,
          elongation: elongation,
          angleRadians: (r4 - 0.5) * 0.9,
        ),
      );
    }

    return droplets;
  }

  /// Rysuje warstwę kropek błota i białego pyłu na dowolnym [Canvas] w obszarze [zoneBounds].
  void paintZoneSplatterOverlay(
    Canvas canvas,
    Rect zoneBounds, {
    required int riderId,
    required RiderSplatterZone zone,
    required RiderSplatterState state,
    double scale = 1.0,
  }) {
    if (zoneBounds.isEmpty) return;
    final droplets = buildDropletsForZone(
      riderId: riderId,
      zone: zone,
      state: state,
    );
    if (droplets.isEmpty) return;

    final mudWetness = state.moistureLevel.clamp(0.0, 1.0);
    final mudBaseColor = Color.lerp(
      const Color(0xFF5A4532), // przyschnięte jasnobrązowe błoto
      const Color(0xFF2D1D12), // świeże mokre ciemne błoto
      mudWetness,
    )!;
    final dustBaseColor = Color.lerp(
      const Color(0xFFEDEAE0), // biały toskański pył Strade Bianche
      const Color(0xFFD6D0C4), // lekko wilgotny kredowy osad
      mudWetness,
    )!;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final droplet in droplets) {
      final cx = zoneBounds.left + droplet.u * zoneBounds.width;
      final cy = zoneBounds.top + droplet.v * zoneBounds.height;
      final r = droplet.radiusPx * scale;

      paint.color = (droplet.medium == SplatterMedium.mud
              ? mudBaseColor
              : dustBaseColor)
          .withValues(alpha: droplet.opacity);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(droplet.angleRadians);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: r * 2.0,
          height: r * 2.0 * droplet.elongation,
        ),
        paint,
      );
      canvas.restore();
    }
  }
}

/// CustomPainter prezentujący kolarza i rower wraz z progresywnym narastaniem
/// kropek błota i białego pyłu na twarzy, okularach, łydkach, ramie i koszulce.
class MudAndDustSplatterPainter extends CustomPainter {
  final RiderSplatterState splatterState;
  final MudAndDustSplatterAccumulation engine;
  final Color jerseyPrimaryColor;
  final Color frameColor;
  final double rainIntensity;

  const MudAndDustSplatterPainter({
    required this.splatterState,
    this.engine = const MudAndDustSplatterAccumulation(),
    this.jerseyPrimaryColor = AppColors.primaryAccent,
    this.frameColor = AppColors.goldAccent,
    this.rainIntensity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF13161E),
          Color(0xFF0F1115),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Linia szosy / bruku u dołu podglądu
    final roadTop = size.height * 0.80;
    final roadPaint = Paint()..color = const Color(0xFF1E222B);
    canvas.drawRect(
      Rect.fromLTRB(0, roadTop, size.width, size.height),
      roadPaint,
    );

    final unit = math.min(size.width, size.height);
    final scale = (unit / 260.0).clamp(0.65, 1.8);
    final cx = size.width * 0.5;

    // 1. Rower (koła + rama)
    final rearWheelCenter = Offset(cx - 58 * scale, roadTop - 28 * scale);
    final frontWheelCenter = Offset(cx + 58 * scale, roadTop - 28 * scale);
    final wheelRadius = 27 * scale;

    final tirePaint = Paint()
      ..color = const Color(0xFF0B0D11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * scale;
    final rimPaint = Paint()
      ..color = const Color(0xFF4B5563)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale;

    canvas.drawCircle(rearWheelCenter, wheelRadius, tirePaint);
    canvas.drawCircle(rearWheelCenter, wheelRadius - 3 * scale, rimPaint);
    canvas.drawCircle(frontWheelCenter, wheelRadius, tirePaint);
    canvas.drawCircle(frontWheelCenter, wheelRadius - 3 * scale, rimPaint);

    final bbCenter = Offset(cx - 6 * scale, roadTop - 29 * scale);
    final seatCluster = Offset(cx - 22 * scale, roadTop - 68 * scale);
    final headTubeTop = Offset(cx + 36 * scale, roadTop - 70 * scale);
    final headTubeBottom = Offset(cx + 39 * scale, roadTop - 58 * scale);

    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2 * scale
      ..strokeCap = StrokeCap.round;

    final framePath = Path()
      ..moveTo(rearWheelCenter.dx, rearWheelCenter.dy)
      ..lineTo(bbCenter.dx, bbCenter.dy)
      ..lineTo(headTubeBottom.dx, headTubeBottom.dy)
      ..lineTo(headTubeTop.dx, headTubeTop.dy)
      ..lineTo(seatCluster.dx, seatCluster.dy)
      ..lineTo(bbCenter.dx, bbCenter.dy)
      ..moveTo(rearWheelCenter.dx, rearWheelCenter.dy)
      ..lineTo(seatCluster.dx, seatCluster.dy)
      ..moveTo(headTubeBottom.dx, headTubeBottom.dy)
      ..lineTo(frontWheelCenter.dx, frontWheelCenter.dy);
    canvas.drawPath(framePath, framePaint);

    // Zabrudzenie na ramie roweru
    final frameZoneRect = Rect.fromLTRB(
      rearWheelCenter.dx - 4 * scale,
      headTubeTop.dy - 4 * scale,
      frontWheelCenter.dx + 4 * scale,
      bbCenter.dy + 6 * scale,
    );
    canvas.save();
    canvas.clipRect(frameZoneRect);
    engine.paintZoneSplatterOverlay(
      canvas,
      frameZoneRect,
      riderId: splatterState.riderId,
      zone: RiderSplatterZone.bikeFrame,
      state: splatterState,
      scale: scale,
    );
    canvas.restore();

    // 2. Łydka i noga kolarza
    final calfRect = Rect.fromCenter(
      center: Offset(cx - 12 * scale, roadTop - 44 * scale),
      width: 18 * scale,
      height: 34 * scale,
    );
    final skinPaint = Paint()..color = const Color(0xFFD6A88A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(calfRect, Radius.circular(8 * scale)),
      skinPaint,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(calfRect, Radius.circular(8 * scale)),
    );
    engine.paintZoneSplatterOverlay(
      canvas,
      calfRect,
      riderId: splatterState.riderId,
      zone: RiderSplatterZone.calves,
      state: splatterState,
      scale: scale,
    );
    canvas.restore();

    // 3. Koszulka kolarska
    final jerseyRect = Rect.fromCenter(
      center: Offset(cx + 4 * scale, roadTop - 92 * scale),
      width: 48 * scale,
      height: 36 * scale,
    );
    final jerseyRRect =
        RRect.fromRectAndRadius(jerseyRect, Radius.circular(12 * scale));
    canvas.drawRRect(jerseyRRect, Paint()..color = jerseyPrimaryColor);
    canvas.save();
    canvas.clipRRect(jerseyRRect);
    engine.paintZoneSplatterOverlay(
      canvas,
      jerseyRect,
      riderId: splatterState.riderId,
      zone: RiderSplatterZone.jersey,
      state: splatterState,
      scale: scale,
    );
    canvas.restore();

    // 4. Twarz, kask i okulary
    final faceCenter = Offset(cx + 28 * scale, roadTop - 120 * scale);
    final faceRect = Rect.fromCenter(
      center: faceCenter,
      width: 24 * scale,
      height: 26 * scale,
    );
    final faceRRect =
        RRect.fromRectAndRadius(faceRect, Radius.circular(11 * scale));
    canvas.drawRRect(faceRRect, skinPaint);

    // Kask
    final helmetRect = Rect.fromCenter(
      center: Offset(faceCenter.dx - 1 * scale, faceCenter.dy - 9 * scale),
      width: 28 * scale,
      height: 14 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(helmetRect, Radius.circular(8 * scale)),
      Paint()..color = const Color(0xFF222630),
    );

    // Zabrudzenie twarzy
    canvas.save();
    canvas.clipRRect(faceRRect);
    engine.paintZoneSplatterOverlay(
      canvas,
      faceRect,
      riderId: splatterState.riderId,
      zone: RiderSplatterZone.face,
      state: splatterState,
      scale: scale,
    );
    canvas.restore();

    // Okulary kolarskie
    final eyewearRect = Rect.fromCenter(
      center: Offset(faceCenter.dx + 4 * scale, faceCenter.dy - 1 * scale),
      width: 18 * scale,
      height: 8 * scale,
    );
    final eyewearRRect =
        RRect.fromRectAndRadius(eyewearRect, Radius.circular(3 * scale));
    canvas.drawRRect(
      eyewearRRect,
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawRRect(
      eyewearRRect,
      Paint()
        ..color = AppColors.accentBlue.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );
    canvas.save();
    canvas.clipRRect(eyewearRRect);
    engine.paintZoneSplatterOverlay(
      canvas,
      eyewearRect,
      riderId: splatterState.riderId,
      zone: RiderSplatterZone.eyewear,
      state: splatterState,
      scale: scale * 0.75,
    );
    canvas.restore();

    // Krople deszczu w tle jeśli pada
    if (rainIntensity > 0.05) {
      final rainPaint = Paint()
        ..color = AppColors.accentBlue.withValues(alpha: 0.22 * rainIntensity)
        ..strokeWidth = 1.1;
      final drops = (rainIntensity * 28).round();
      for (int i = 0; i < drops; i++) {
        final rx = ((i * 53 + 17) % 100) / 100.0 * size.width;
        final ry = ((i * 79 + 31) % 100) / 100.0 * roadTop;
        canvas.drawLine(
          Offset(rx, ry),
          Offset(rx - 4, ry + 14),
          rainPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MudAndDustSplatterPainter oldDelegate) {
    return oldDelegate.splatterState != splatterState ||
        oldDelegate.jerseyPrimaryColor != jerseyPrimaryColor ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.rainIntensity != rainIntensity;
  }
}

/// Produkcyjny, responsywny panel diagnostyczny i symulator progresywnego brudzenia
/// z pełnymi stanami hover/active/disabled/focus oraz obsługą LayoutBuilder
/// (390x844, 1024x768, 1600x900).
class MudAndDustSplatterControlPanel extends StatefulWidget {
  final int riderId;
  final String riderName;
  final MudAndDustSplatterAccumulation engine;

  const MudAndDustSplatterControlPanel({
    super.key,
    this.riderId = 7,
    this.riderName = 'M. Kwiatkowski',
    this.engine = const MudAndDustSplatterAccumulation(),
  });

  @override
  State<MudAndDustSplatterControlPanel> createState() =>
      _MudAndDustSplatterControlPanelState();
}

class _MudAndDustSplatterControlPanelState
    extends State<MudAndDustSplatterControlPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _simTicker;
  late RiderSplatterState _state;
  SplatterConditionPreset _preset =
      SplatterConditionPreset.parisRoubaixWetCobbles;
  PelotonDraftExposureRole _selectedRole = PelotonDraftExposureRole.onWheel;
  bool _isSimulating = false;
  bool _isWipingEyewear = false;

  @override
  void initState() {
    super.initState();
    _state = RiderSplatterState.clean(widget.riderId);
    _simTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onSimulationTick);
  }

  void _onSimulationTick() {
    if (!_isSimulating) return;
    final (draftRatio, aheadDist, nearbyCount) = _metricsForRole(_selectedRole);
    final next = widget.engine.step(
      _state,
      RiderSplatterFrameInput(
        riderId: widget.riderId,
        surfaceType: _preset.surfaceType,
        wetness: _preset.wetness,
        rainIntensity: _preset.rainIntensity,
        speedKmh: _preset.speedKmh,
        draftingSavingsRatio: draftRatio,
        distanceToAheadRiderMeters: aheadDist,
        nearbyRidersCount: nearbyCount,
        isWipingEyewear: _isWipingEyewear,
      ),
      0.18,
    );
    if (mounted) {
      setState(() {
        _state = next;
        if (_isWipingEyewear &&
            _state.totalCoverageForZone(RiderSplatterZone.eyewear) <= 0.02) {
          _isWipingEyewear = false;
        }
      });
    }
  }

  (double, double, int) _metricsForRole(PelotonDraftExposureRole role) {
    switch (role) {
      case PelotonDraftExposureRole.soloLeader:
        return (0.0, 28.0, 0);
      case PelotonDraftExposureRole.echelonSide:
        return (0.14, 3.4, 3);
      case PelotonDraftExposureRole.onWheel:
        return (0.26, 0.9, 2);
      case PelotonDraftExposureRole.deepPeloton:
        return (0.38, 0.7, 14);
    }
  }

  void _toggleSimulation() {
    setState(() {
      _isSimulating = !_isSimulating;
      if (_isSimulating) {
        _simTicker.repeat();
      } else {
        _simTicker.stop();
      }
    });
  }

  void _stepFiveSeconds() {
    final (draftRatio, aheadDist, nearbyCount) = _metricsForRole(_selectedRole);
    RiderSplatterState updated = _state;
    for (int i = 0; i < 10; i++) {
      updated = widget.engine.step(
        updated,
        RiderSplatterFrameInput(
          riderId: widget.riderId,
          surfaceType: _preset.surfaceType,
          wetness: _preset.wetness,
          rainIntensity: _preset.rainIntensity,
          speedKmh: _preset.speedKmh,
          draftingSavingsRatio: draftRatio,
          distanceToAheadRiderMeters: aheadDist,
          nearbyRidersCount: nearbyCount,
          isWipingEyewear: _isWipingEyewear,
        ),
        0.5,
      );
    }
    setState(() {
      _state = updated;
    });
  }

  void _wipeEyewearOnce() {
    final (draftRatio, aheadDist, nearbyCount) = _metricsForRole(_selectedRole);
    final updated = widget.engine.step(
      _state,
      RiderSplatterFrameInput(
        riderId: widget.riderId,
        surfaceType: _preset.surfaceType,
        wetness: _preset.wetness,
        rainIntensity: _preset.rainIntensity,
        speedKmh: _preset.speedKmh,
        draftingSavingsRatio: draftRatio,
        distanceToAheadRiderMeters: aheadDist,
        nearbyRidersCount: nearbyCount,
        isWipingEyewear: true,
      ),
      1.0,
    );
    setState(() {
      _state = updated;
    });
  }

  void _resetClean() {
    setState(() {
      _state = RiderSplatterState.clean(widget.riderId);
      _isWipingEyewear = false;
    });
  }

  @override
  void dispose() {
    _simTicker.dispose();
    super.dispose();
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
          final isWide = constraints.maxWidth >= 720;
          final header = _buildHeader();
          final preview = _buildPreviewCard();
          final controls = _buildControlsAndTelemetry();

          if (isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: preview),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: controls),
                  ],
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 12),
                preview,
                const SizedBox(height: 12),
                controls,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final dirtyPct = (_state.overallDirtyRatio * 100).round();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Akumulacja Błota i Pyłu 3D',
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
                '${widget.riderName} • ${_state.exposureRole.label}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: dirtyPct >= 65
                  ? AppColors.amberWarning
                  : AppTheme.borderColor,
            ),
          ),
          child: Text(
            'Brud: $dirtyPct%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: MudAndDustSplatterPainter(
          splatterState: _state,
          engine: widget.engine,
          rainIntensity: _preset.rainIntensity,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildControlsAndTelemetry() {
    final eyewearDirty =
        _state.totalCoverageForZone(RiderSplatterZone.eyewear) > 0.02;
    final hasAnyDirt = _state.overallDirtyRatio > 0.005;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Warunki i nawierzchnia',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SplatterConditionPreset.values.map((preset) {
            return _InteractiveOptionChip(
              label: preset.label,
              selected: _preset == preset,
              onPressed: () {
                setState(() {
                  _preset = preset;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pozycja w peletonie',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PelotonDraftExposureRole.values.map((role) {
            return _InteractiveOptionChip(
              label: '${role.label} (${role.exposureMultiplier}x)',
              selected: _selectedRole == role,
              onPressed: () {
                setState(() {
                  _selectedRole = role;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        ...RiderSplatterZone.values.map(_buildZoneProgressRow),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionButton(
              label: _isSimulating ? 'Pauza symulacji' : 'Uruchom jazdę',
              isPrimary: true,
              onPressed: _toggleSimulation,
            ),
            _ActionButton(
              label: '+5s jazdy',
              onPressed: _stepFiveSeconds,
            ),
            _ActionButton(
              label: 'Przetrzyj okulary',
              onPressed: eyewearDirty ? _wipeEyewearOnce : null,
            ),
            _ActionButton(
              label: 'Umyj kolarza',
              onPressed: hasAnyDirt ? _resetClean : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoneProgressRow(RiderSplatterZone zone) {
    final mud = _state.mudForZone(zone);
    final dust = _state.dustForZone(zone);
    final total = _state.totalCoverageForZone(zone);
    final pct = (total * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                zone.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (context, barConstraints) {
                  final maxW = barConstraints.maxWidth;
                  final mudW = (mud * maxW).clamp(0.0, maxW);
                  final dustW = (dust * maxW).clamp(0.0, maxW - mudW);
                  return Stack(
                    children: [
                      Container(color: AppColors.surfaceLight),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: mudW,
                        color: const Color(0xFF6B482E),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        left: mudW,
                        top: 0,
                        bottom: 0,
                        width: dustW,
                        child: Container(color: const Color(0xFFE5E0D5)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveOptionChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const _InteractiveOptionChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  State<_InteractiveOptionChip> createState() => _InteractiveOptionChipState();
}

class _InteractiveOptionChipState extends State<_InteractiveOptionChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bgColor = !enabled
        ? AppColors.background
        : widget.selected
            ? AppColors.primaryAccent
            : _pressed
                ? AppColors.surfaceLight
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.9)
                    : AppColors.background;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.goldAccent
            : _hovered
                ? AppColors.textSecondary
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: !enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.45)
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : _pressed
            ? baseBg.withValues(alpha: 0.78)
            : _hovered
                ? baseBg.withValues(alpha: 0.92)
                : baseBg;
    final borderColor = _focused
        ? AppColors.goldAccent
        : !enabled
            ? AppTheme.borderColor.withValues(alpha: 0.5)
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.6)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
