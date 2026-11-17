// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';

/// Predefiniowane profile zjazdów alpejskich o dużym przewyższeniu i gradiencie termicznym.
enum AlpineDescentAtmospherePreset {
  galibier(
    id: 'galibier',
    namePl: 'Col du Galibier → Bourg d\'Oisans',
    nameEn: 'Col du Galibier → Bourg d\'Oisans',
    summitAltitudeM: 2642.0,
    valleyAltitudeM: 720.0,
    summitTempC: 4.0,
    valleyTempC: 24.5,
    summitHumidity: 0.42,
    valleyHumidity: 0.58,
    averageGradientPercent: 6.8,
    descentLengthKm: 34.8,
  ),
  stelvio(
    id: 'stelvio',
    namePl: 'Passo dello Stelvio → Bormio',
    nameEn: 'Passo dello Stelvio → Bormio',
    summitAltitudeM: 2758.0,
    valleyAltitudeM: 1225.0,
    summitTempC: 2.5,
    valleyTempC: 19.0,
    summitHumidity: 0.48,
    valleyHumidity: 0.62,
    averageGradientPercent: 7.1,
    descentLengthKm: 21.5,
  ),
  bonette(
    id: 'bonette',
    namePl: 'Cime de la Bonette → Jausiers',
    nameEn: 'Cime de la Bonette → Jausiers',
    summitAltitudeM: 2802.0,
    valleyAltitudeM: 1215.0,
    summitTempC: 1.8,
    valleyTempC: 21.0,
    summitHumidity: 0.35,
    valleyHumidity: 0.50,
    averageGradientPercent: 6.9,
    descentLengthKm: 23.0,
  ),
  ventoux(
    id: 'ventoux',
    namePl: 'Mont Ventoux → Bédoin',
    nameEn: 'Mont Ventoux → Bédoin',
    summitAltitudeM: 1909.0,
    valleyAltitudeM: 300.0,
    summitTempC: 9.5,
    valleyTempC: 31.0,
    summitHumidity: 0.38,
    valleyHumidity: 0.46,
    averageGradientPercent: 7.5,
    descentLengthKm: 21.4,
  ),
  tourmalet(
    id: 'tourmalet',
    namePl: 'Col du Tourmalet → Sainte-Marie',
    nameEn: 'Col du Tourmalet → Sainte-Marie',
    summitAltitudeM: 2115.0,
    valleyAltitudeM: 855.0,
    summitTempC: 7.0,
    valleyTempC: 20.5,
    summitHumidity: 0.65,
    valleyHumidity: 0.72,
    averageGradientPercent: 7.3,
    descentLengthKm: 17.2,
  );

  final String id;
  final String namePl;
  final String nameEn;
  final double summitAltitudeM;
  final double valleyAltitudeM;
  final double summitTempC;
  final double valleyTempC;
  final double summitHumidity;
  final double valleyHumidity;
  final double averageGradientPercent;
  final double descentLengthKm;

  const AlpineDescentAtmospherePreset({
    required this.id,
    required this.namePl,
    required this.nameEn,
    required this.summitAltitudeM,
    required this.valleyAltitudeM,
    required this.summitTempC,
    required this.valleyTempC,
    required this.summitHumidity,
    required this.valleyHumidity,
    required this.averageGradientPercent,
    required this.descentLengthKm,
  });
}

/// Punkt pomiarowy atmosfery na trasie zjazdu (np. szczyt, półka górska, dolina).
class AtmosphereWaypoint {
  /// Wysokość n.p.m. [m]
  final double altitudeMeters;

  /// Temperatura powietrza [°C]
  final double temperatureCelsius;

  /// Wilgotność względna powietrza (0.0 – 1.0)
  final double relativeHumidity;

  const AtmosphereWaypoint({
    required this.altitudeMeters,
    required this.temperatureCelsius,
    this.relativeHumidity = 0.50,
  });

  AtmosphereWaypoint copyWith({
    double? altitudeMeters,
    double? temperatureCelsius,
    double? relativeHumidity,
  }) {
    return AtmosphereWaypoint(
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      relativeHumidity: relativeHumidity ?? this.relativeHumidity,
    );
  }
}

/// Konfiguracja modelu ciągłej interpolacji gęstości powietrza podczas zjazdu.
class AirDensityTransitionConfig {
  /// Uporządkowane punkty atmosferyczne (od najniższej do najwyższej lub dowolnie — sortowane wewnętrznie).
  final List<AtmosphereWaypoint> waypoints;

  /// Ciśnienie odniesienia na poziomie morza QNH [hPa].
  final double seaLevelPressureHpa;

  /// Czy uwzględniać korektę wilgotności (para wodna zmniejsza masę molową powietrza).
  final bool includeHumidityCorrection;

  /// Masa całkowita kolarza + roweru [kg] do wyliczenia prędkości granicznej zjazdu.
  final double systemMassKg;

  /// Współczynnik oporu aerodynamicznego CdA [m²] w pozycji zjazdowej (np. drops/supertuck).
  final double riderCdA;

  /// Współczynnik oporu toczenia opon Crr.
  final double rollingResistanceCrr;

  /// Średnie nachylenie zjazdu [%] (wartość dodatnia oznacza spadek w dół).
  final double descentGradientPercent;

  const AirDensityTransitionConfig({
    required this.waypoints,
    this.seaLevelPressureHpa = 1013.25,
    this.includeHumidityCorrection = true,
    this.systemMassKg = 75.0,
    this.riderCdA = 0.255,
    this.rollingResistanceCrr = 0.0036,
    this.descentGradientPercent = 7.0,
  });

  factory AirDensityTransitionConfig.fromPreset(
    AlpineDescentAtmospherePreset preset, {
    double seaLevelPressureHpa = 1013.25,
    bool includeHumidityCorrection = true,
    double systemMassKg = 75.0,
    double riderCdA = 0.255,
  }) {
    return AirDensityTransitionConfig(
      waypoints: [
        AtmosphereWaypoint(
          altitudeMeters: preset.valleyAltitudeM,
          temperatureCelsius: preset.valleyTempC,
          relativeHumidity: preset.valleyHumidity,
        ),
        AtmosphereWaypoint(
          altitudeMeters: preset.summitAltitudeM,
          temperatureCelsius: preset.summitTempC,
          relativeHumidity: preset.summitHumidity,
        ),
      ],
      seaLevelPressureHpa: seaLevelPressureHpa,
      includeHumidityCorrection: includeHumidityCorrection,
      systemMassKg: systemMassKg,
      riderCdA: riderCdA,
      descentGradientPercent: preset.averageGradientPercent,
    );
  }
}

/// Pojedyncza próbka ciągłej interpolacji $\rho(h, T)$ w danym punkcie zjazdu.
class AirDensitySample {
  /// Wysokość n.p.m. [m]
  final double altitudeMeters;

  /// Zinterpolowana temperatura powietrza [°C]
  final double temperatureCelsius;

  /// Zinterpolowana wilgotność względna [0..1]
  final double relativeHumidity;

  /// Ciśnienie barometryczne [hPa]
  final double pressureHpa;

  /// Gęstość powietrza $\rho(h, T)$ [kg/m³]
  final double airDensityKgM3;

  /// Stosunek gęstości do poziomu morza ($\rho / 1.225$)
  final double densityRatioToSeaLevel;

  /// Gradient zmiany gęstości przy zjeździe [kg/m³ na 100 m spadku wysokości]
  final double densityIncreasePer100mDescent;

  /// Prędkość graniczna zjazdu bez pedałowania [km/h]
  final double terminalVelocityKmh;

  /// Siła oporu aerodynamicznego przy prędkości 70 km/h [N]
  final double dragForceAt70KmhNewtons;

  /// Moc aerodynamiczna potrzebna do utrzymania 70 km/h [W]
  final double aeroPowerAt70KmhWatts;

  const AirDensitySample({
    required this.altitudeMeters,
    required this.temperatureCelsius,
    required this.relativeHumidity,
    required this.pressureHpa,
    required this.airDensityKgM3,
    required this.densityRatioToSeaLevel,
    required this.densityIncreasePer100mDescent,
    required this.terminalVelocityKmh,
    required this.dragForceAt70KmhNewtons,
    required this.aeroPowerAt70KmhWatts,
  });
}

/// Podsumowanie całego profilu zjazdu alpejskiego wraz z weryfikacją ciągłości $C^1$.
class DescentDensityProfileSummary {
  final List<AirDensitySample> samples;
  final AirDensitySample summitSample;
  final AirDensitySample valleySample;

  /// Procentowy wzrost gęstości powietrza między szczytem a doliną [%]
  final double densityIncreasePercent;

  /// Spadek prędkości granicznej zjazdu w gęstszym powietrzu w dolinie [km/h]
  final double terminalSpeedDropKmh;

  /// Maksymalny skok gęstości pomiędzy sąsiednimi próbkami [kg/m³]
  final double maxStepDensityDeltaKgM3;

  /// Czy przejście jest ciągłe i pozbawione skoków międzysegmentowych
  final bool isSmoothContinuous;

  const DescentDensityProfileSummary({
    required this.samples,
    required this.summitSample,
    required this.valleySample,
    required this.densityIncreasePercent,
    required this.terminalSpeedDropKmh,
    required this.maxStepDensityDeltaKgM3,
    required this.isSmoothContinuous,
  });
}

/// Silnik ciągłej interpolacji gęstości powietrza $\rho(h, T)$ podczas zjazdów alpejskich.
///
/// Zapewnia gładką ($C^1$) interpolację temperatury, wilgotności oraz ciśnienia barometrycznego
/// w funkcji wysokości $h$ oraz postępu zjazdu, eliminując skoki oporu aerodynamicznego
/// na granicach segmentów trasy górskiej.
class AltitudeDescentAirDensityTransition {
  AltitudeDescentAirDensityTransition._();

  /// Stała gazowa suchego powietrza [J/(kg·K)]
  static const double gasConstantDryAir = 287.05287;

  /// Stała gazowa pary wodnej [J/(kg·K)]
  static const double gasConstantWaterVapor = 461.495;

  /// Wykładnik barometryczny ISA: (g * M) / (R * L)
  static const double _barometricExponent = 5.2558774;

  /// Bazowa temperatura ISA na poziomie morza [K] (15°C)
  static const double _isaSeaLevelTempKelvin = 288.15;

  /// Oblicza ciśnienie barometryczne [hPa] na wysokości [altitudeMeters]
  /// dla zadanego ciśnienia odniesienia [seaLevelPressureHpa] (domyślnie 1013.25 hPa).
  static double calculateBarometricPressureHpa({
    required double altitudeMeters,
    double seaLevelPressureHpa = 1013.25,
  }) {
    final double h = altitudeMeters.clamp(-400.0, 9000.0);
    final double qnh = seaLevelPressureHpa.clamp(850.0, 1080.0);
    final double tempRatio =
        1.0 - ((PhysicsConstants.temperatureLapseRate * h) / _isaSeaLevelTempKelvin);
    final double safeRatio = math.max(0.05, tempRatio);
    return qnh * math.pow(safeRatio, _barometricExponent).toDouble();
  }

  /// Oblicza ciśnienie nasycenia pary wodnej [hPa] wg równania Tetensa/Magnusa.
  static double calculateSaturationVaporPressureHpa(double temperatureCelsius) {
    final double t = temperatureCelsius.clamp(-50.0, 60.0);
    return 6.1078 * math.exp((17.27 * t) / (t + 237.3));
  }

  /// Oblicza gęstość powietrza $\rho(h, T)$ [kg/m³] z pełnego równania stanu gazu
  /// doskonałego dla powietrza suchego lub wilgotnego.
  static double calculateAirDensity({
    required double altitudeMeters,
    required double temperatureCelsius,
    double relativeHumidity = 0.50,
    double seaLevelPressureHpa = 1013.25,
    bool includeHumidityCorrection = true,
  }) {
    final double tempKelvin = (temperatureCelsius.clamp(-50.0, 60.0)) + 273.15;
    final double totalPressurePa = calculateBarometricPressureHpa(
          altitudeMeters: altitudeMeters,
          seaLevelPressureHpa: seaLevelPressureHpa,
        ) *
        100.0;

    if (!includeHumidityCorrection) {
      final double dryRho = totalPressurePa / (gasConstantDryAir * tempKelvin);
      return dryRho.clamp(0.30, 1.60);
    }

    final double rh = relativeHumidity.clamp(0.0, 1.0);
    final double vaporPressurePa =
        rh * calculateSaturationVaporPressureHpa(temperatureCelsius) * 100.0;
    final double clampedVaporPa = math.min(vaporPressurePa, totalPressurePa * 0.25);
    final double dryAirPressurePa = totalPressurePa - clampedVaporPa;

    final double rho = (dryAirPressurePa / (gasConstantDryAir * tempKelvin)) +
        (clampedVaporPa / (gasConstantWaterVapor * tempKelvin));
    return rho.clamp(0.30, 1.60);
  }

  /// Wygładzona krzywa Hermite'a $3u^2 - 2u^3$ ($C^1$ ciągła w punktach krańcowych).
  static double _smoothstep(double u) {
    final double t = u.clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  /// Zwraca posortowane punkty atmosferyczne (od najniższej wysokości do najwyższej).
  static List<AtmosphereWaypoint> _sortedWaypoints(List<AtmosphereWaypoint> input) {
    if (input.isEmpty) {
      return const [
        AtmosphereWaypoint(altitudeMeters: 0.0, temperatureCelsius: 15.0, relativeHumidity: 0.50),
      ];
    }
    final List<AtmosphereWaypoint> copy = List<AtmosphereWaypoint>.of(input);
    copy.sort((a, b) => a.altitudeMeters.compareTo(b.altitudeMeters));
    return copy;
  }

  /// Ciągła interpolacja temperatury i wilgotności na wysokości [altitudeMeters]
  /// z użyciem gładkiej krzywej Hermite'a między punktami oraz standardowego gradientu
  /// termicznego poza zakresem punktów skrajnych.
  static ({double temperatureCelsius, double relativeHumidity}) interpolateAtmosphereAtAltitude({
    required double altitudeMeters,
    required List<AtmosphereWaypoint> waypoints,
  }) {
    final List<AtmosphereWaypoint> sorted = _sortedWaypoints(waypoints);
    if (sorted.length == 1) {
      final AtmosphereWaypoint single = sorted.first;
      final double deltaH = altitudeMeters - single.altitudeMeters;
      final double extrapolatedTemp =
          single.temperatureCelsius - (deltaH * PhysicsConstants.temperatureLapseRate);
      return (
        temperatureCelsius: extrapolatedTemp.clamp(-40.0, 50.0),
        relativeHumidity: single.relativeHumidity.clamp(0.0, 1.0),
      );
    }

    if (altitudeMeters <= sorted.first.altitudeMeters) {
      final AtmosphereWaypoint lowest = sorted.first;
      final double deltaH = altitudeMeters - lowest.altitudeMeters;
      final double temp =
          lowest.temperatureCelsius - (deltaH * PhysicsConstants.temperatureLapseRate);
      return (
        temperatureCelsius: temp.clamp(-40.0, 50.0),
        relativeHumidity: lowest.relativeHumidity.clamp(0.0, 1.0),
      );
    }

    if (altitudeMeters >= sorted.last.altitudeMeters) {
      final AtmosphereWaypoint highest = sorted.last;
      final double deltaH = altitudeMeters - highest.altitudeMeters;
      final double temp =
          highest.temperatureCelsius - (deltaH * PhysicsConstants.temperatureLapseRate);
      return (
        temperatureCelsius: temp.clamp(-40.0, 50.0),
        relativeHumidity: highest.relativeHumidity.clamp(0.0, 1.0),
      );
    }

    for (int i = 0; i < sorted.length - 1; i++) {
      final AtmosphereWaypoint low = sorted[i];
      final AtmosphereWaypoint high = sorted[i + 1];
      if (altitudeMeters >= low.altitudeMeters && altitudeMeters <= high.altitudeMeters) {
        final double span = high.altitudeMeters - low.altitudeMeters;
        if (span <= 1e-6) {
          return (
            temperatureCelsius: low.temperatureCelsius,
            relativeHumidity: low.relativeHumidity,
          );
        }
        final double linearU = (altitudeMeters - low.altitudeMeters) / span;
        final double smoothU = _smoothstep(linearU);
        final double temp =
            low.temperatureCelsius + (high.temperatureCelsius - low.temperatureCelsius) * smoothU;
        final double rh =
            low.relativeHumidity + (high.relativeHumidity - low.relativeHumidity) * smoothU;
        return (
          temperatureCelsius: temp.clamp(-40.0, 50.0),
          relativeHumidity: rh.clamp(0.0, 1.0),
        );
      }
    }

    return (
      temperatureCelsius: sorted.last.temperatureCelsius,
      relativeHumidity: sorted.last.relativeHumidity,
    );
  }

  /// Oblicza prędkość graniczną zjazdu [m/s] (bez pedałowania) w warunkach równowagi
  /// grawitacji, oporu toczenia oraz oporu aerodynamicznego.
  static double computeTerminalVelocityMs({
    required double airDensityKgM3,
    required double systemMassKg,
    required double riderCdA,
    required double rollingResistanceCrr,
    required double descentGradientPercent,
  }) {
    final double slopeRad = math.atan(descentGradientPercent.clamp(0.5, 30.0) / 100.0);
    final double drivingGravityForce =
        systemMassKg * PhysicsConstants.gravity * math.sin(slopeRad);
    final double rollingForce =
        systemMassKg * PhysicsConstants.gravity * rollingResistanceCrr * math.cos(slopeRad);
    final double netPropulsiveForce = drivingGravityForce - rollingForce;
    if (netPropulsiveForce <= 0.0) {
      return 0.0;
    }
    final double aeroFactor = 0.5 * airDensityKgM3.clamp(0.3, 1.6) * riderCdA.clamp(0.15, 0.60);
    return math.sqrt(netPropulsiveForce / aeroFactor);
  }

  /// Wyznacza pełną próbkę parametrów aerodynamicznych dla wysokości [altitudeMeters].
  static AirDensitySample evaluateAtAltitude({
    required double altitudeMeters,
    required AirDensityTransitionConfig config,
  }) {
    final ({double temperatureCelsius, double relativeHumidity}) atm =
        interpolateAtmosphereAtAltitude(
      altitudeMeters: altitudeMeters,
      waypoints: config.waypoints,
    );

    final double pressureHpa = calculateBarometricPressureHpa(
      altitudeMeters: altitudeMeters,
      seaLevelPressureHpa: config.seaLevelPressureHpa,
    );

    final double rho = calculateAirDensity(
      altitudeMeters: altitudeMeters,
      temperatureCelsius: atm.temperatureCelsius,
      relativeHumidity: atm.relativeHumidity,
      seaLevelPressureHpa: config.seaLevelPressureHpa,
      includeHumidityCorrection: config.includeHumidityCorrection,
    );

    // Numeryczna pochodna gęstości względem spadku wysokości (-dRho / dh * 100 m)
    const double dh = 5.0;
    final ({double temperatureCelsius, double relativeHumidity}) atmLower =
        interpolateAtmosphereAtAltitude(
      altitudeMeters: altitudeMeters - dh,
      waypoints: config.waypoints,
    );
    final double rhoLower = calculateAirDensity(
      altitudeMeters: altitudeMeters - dh,
      temperatureCelsius: atmLower.temperatureCelsius,
      relativeHumidity: atmLower.relativeHumidity,
      seaLevelPressureHpa: config.seaLevelPressureHpa,
      includeHumidityCorrection: config.includeHumidityCorrection,
    );
    final double increasePer100m = ((rhoLower - rho) / dh) * 100.0;

    final double terminalMs = computeTerminalVelocityMs(
      airDensityKgM3: rho,
      systemMassKg: config.systemMassKg,
      riderCdA: config.riderCdA,
      rollingResistanceCrr: config.rollingResistanceCrr,
      descentGradientPercent: config.descentGradientPercent,
    );

    const double refSpeedMs = 70.0 / 3.6;
    final double drag70 = 0.5 * rho * config.riderCdA * refSpeedMs * refSpeedMs;
    final double power70 = drag70 * refSpeedMs;

    return AirDensitySample(
      altitudeMeters: altitudeMeters,
      temperatureCelsius: atm.temperatureCelsius,
      relativeHumidity: atm.relativeHumidity,
      pressureHpa: pressureHpa,
      airDensityKgM3: rho,
      densityRatioToSeaLevel: rho / PhysicsConstants.seaLevelAirDensity,
      densityIncreasePer100mDescent: increasePer100m,
      terminalVelocityKmh: terminalMs * 3.6,
      dragForceAt70KmhNewtons: drag70,
      aeroPowerAt70KmhWatts: power70,
    );
  }

  /// Interpoluje gęstość powietrza na podstawie znormalizowanego postępu zjazdu `t` ∈ [0.0, 1.0],
  /// gdzie 0.0 oznacza szczyt przełęczy, a 1.0 dno doliny.
  static AirDensitySample interpolateAlongDescentProgress({
    required double progress,
    required AirDensityTransitionConfig config,
  }) {
    final List<AtmosphereWaypoint> sorted = _sortedWaypoints(config.waypoints);
    final double valleyAlt = sorted.first.altitudeMeters;
    final double summitAlt = sorted.last.altitudeMeters;
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double altitude = summitAlt - (summitAlt - valleyAlt) * clampedProgress;
    return evaluateAtAltitude(altitudeMeters: altitude, config: config);
  }

  /// Generuje pełny profil zjazdu o [sampleCount] próbkach i weryfikuje ciągłość $C^1$.
  static DescentDensityProfileSummary generateDescentProfile({
    required AirDensityTransitionConfig config,
    int sampleCount = 48,
  }) {
    final int count = math.max(8, sampleCount);
    final List<AirDensitySample> samples = List<AirDensitySample>.generate(
      count,
      (index) {
        final double t = index / (count - 1);
        return interpolateAlongDescentProgress(progress: t, config: config);
      },
      growable: false,
    );

    final AirDensitySample summit = samples.first;
    final AirDensitySample valley = samples.last;

    double maxDelta = 0.0;
    for (int i = 1; i < samples.length; i++) {
      final double delta = (samples[i].airDensityKgM3 - samples[i - 1].airDensityKgM3).abs();
      if (delta > maxDelta) {
        maxDelta = delta;
      }
    }

    final double densityIncreasePct =
        ((valley.airDensityKgM3 - summit.airDensityKgM3) / summit.airDensityKgM3) * 100.0;
    final double speedDropKmh = summit.terminalVelocityKmh - valley.terminalVelocityKmh;

    // Przy płynnym profilu oczekujemy braku nagłych skoków (próg adaptacyjny dla kroku wysokości)
    final double altStepM =
        (summit.altitudeMeters - valley.altitudeMeters).abs() / (count - 1);
    final double maxAllowedStepDelta = math.max(0.008, altStepM * 0.00022);

    return DescentDensityProfileSummary(
      samples: samples,
      summitSample: summit,
      valleySample: valley,
      densityIncreasePercent: densityIncreasePct,
      terminalSpeedDropKmh: speedDropKmh,
      maxStepDensityDeltaKgM3: maxDelta,
      isSmoothContinuous: maxDelta <= maxAllowedStepDelta,
    );
  }
}

/// Interaktywny panel telemetryczny ciągłej interpolacji gęstości powietrza $\rho(h, T)$
/// podczas zjazdów alpejskich.
class AltitudeDescentAirDensityPanel extends StatefulWidget {
  final AlpineDescentAtmospherePreset initialPreset;
  final bool enabled;

  const AltitudeDescentAirDensityPanel({
    super.key,
    this.initialPreset = AlpineDescentAtmospherePreset.galibier,
    this.enabled = true,
  });

  @override
  State<AltitudeDescentAirDensityPanel> createState() =>
      _AltitudeDescentAirDensityPanelState();
}

class _AltitudeDescentAirDensityPanelState extends State<AltitudeDescentAirDensityPanel> {
  late AlpineDescentAtmospherePreset _selectedPreset;
  late double _summitTempC;
  late double _valleyTempC;
  double _descentProgress = 0.35;
  bool _includeHumidity = true;
  bool _showTerminalVelocityCurve = true;

  @override
  void initState() {
    super.initState();
    _applyPreset(widget.initialPreset, notify: false);
  }

  void _applyPreset(AlpineDescentAtmospherePreset preset, {bool notify = true}) {
    void update() {
      _selectedPreset = preset;
      _summitTempC = preset.summitTempC;
      _valleyTempC = preset.valleyTempC;
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  AirDensityTransitionConfig _buildConfig() {
    return AirDensityTransitionConfig(
      waypoints: [
        AtmosphereWaypoint(
          altitudeMeters: _selectedPreset.valleyAltitudeM,
          temperatureCelsius: _valleyTempC,
          relativeHumidity: _selectedPreset.valleyHumidity,
        ),
        AtmosphereWaypoint(
          altitudeMeters: _selectedPreset.summitAltitudeM,
          temperatureCelsius: _summitTempC,
          relativeHumidity: _selectedPreset.summitHumidity,
        ),
      ],
      includeHumidityCorrection: _includeHumidity,
      descentGradientPercent: _selectedPreset.averageGradientPercent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AirDensityTransitionConfig config = _buildConfig();
    final DescentDensityProfileSummary summary =
        AltitudeDescentAirDensityTransition.generateDescentProfile(
      config: config,
      sampleCount: 40,
    );
    final AirDensitySample currentSample =
        AltitudeDescentAirDensityTransition.interpolateAlongDescentProgress(
      progress: _descentProgress,
      config: config,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 600;
        final bool isWide = constraints.maxWidth >= 1000;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact, summary),
              const SizedBox(height: 14),
              _buildPresetSelector(),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildChartCard(summary, currentSample)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildTelemetryAndControls(summary, currentSample)),
                  ],
                )
              else ...[
                _buildChartCard(summary, currentSample),
                const SizedBox(height: 14),
                _buildTelemetryAndControls(summary, currentSample),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact, DescentDensityProfileSummary summary) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INTERPOLACJA GĘSTOŚCI POWIETRZA ρ(h, T)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _selectedPreset.namePl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (summary.isSmoothContinuous
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: summary.isSmoothContinuous
                  ? AppColors.statusSuccess
                  : AppColors.amberWarning,
              width: 1,
            ),
          ),
          child: Text(
            summary.isSmoothContinuous ? 'C¹ CIĄGŁA' : 'KOREKTA GRADIENTU',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: summary.isSmoothContinuous
                  ? AppColors.statusSuccess
                  : AppColors.amberWarning,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AlpineDescentAtmospherePreset.values.map((preset) {
        final bool selected = preset == _selectedPreset;
        return _InteractiveChipButton(
          label: preset.id.toUpperCase(),
          selected: selected,
          enabled: widget.enabled,
          onTap: () => _applyPreset(preset),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildChartCard(
    DescentDensityProfileSummary summary,
    AirDensitySample currentSample,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Profil ρ(h, T) na zjeździe',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              _InteractiveChipButton(
                label: _showTerminalVelocityCurve ? 'V_term: ON' : 'V_term: OFF',
                selected: _showTerminalVelocityCurve,
                enabled: widget.enabled,
                onTap: () {
                  setState(() {
                    _showTerminalVelocityCurve = !_showTerminalVelocityCurve;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _AirDensityCurvePainter(
                samples: summary.samples,
                progress: _descentProgress,
                showTerminalVelocity: _showTerminalVelocityCurve,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Szczyt: ${summary.summitSample.altitudeMeters.toStringAsFixed(0)} m',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Pozycja: ${(_descentProgress * 100).toStringAsFixed(0)}% (${currentSample.altitudeMeters.toStringAsFixed(0)} m)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.accentBlue,
                ),
              ),
              Text(
                'Dolina: ${summary.valleySample.altitudeMeters.toStringAsFixed(0)} m',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryAndControls(
    DescentDensityProfileSummary summary,
    AirDensitySample currentSample,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Gęstość ρ',
                value: '${currentSample.airDensityKgM3.toStringAsFixed(3)} kg/m³',
                accent: AppColors.cyanAccent,
              ),
              _MetricTile(
                label: 'Temperatura',
                value: '${currentSample.temperatureCelsius.toStringAsFixed(1)} °C',
                accent: AppColors.goldAccent,
              ),
              _MetricTile(
                label: 'V graniczna',
                value: '${currentSample.terminalVelocityKmh.toStringAsFixed(1)} km/h',
                accent: AppColors.accentBlue,
              ),
              _MetricTile(
                label: 'Wzrost ρ (dół)',
                value: '+${summary.densityIncreasePercent.toStringAsFixed(1)}%',
                accent: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabeledSlider(
            label: 'Postęp zjazdu',
            valueLabel: '${(_descentProgress * 100).toStringAsFixed(0)}%',
            value: _descentProgress,
            min: 0.0,
            max: 1.0,
            enabled: widget.enabled,
            onChanged: (v) => setState(() => _descentProgress = v),
          ),
          _LabeledSlider(
            label: 'Temp. szczyt',
            valueLabel: '${_summitTempC.toStringAsFixed(1)} °C',
            value: _summitTempC,
            min: -10.0,
            max: 25.0,
            enabled: widget.enabled,
            onChanged: (v) => setState(() => _summitTempC = v),
          ),
          _LabeledSlider(
            label: 'Temp. dolina',
            valueLabel: '${_valleyTempC.toStringAsFixed(1)} °C',
            value: _valleyTempC,
            min: 0.0,
            max: 42.0,
            enabled: widget.enabled,
            onChanged: (v) => setState(() => _valleyTempC = v),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _InteractiveChipButton(
              label: _includeHumidity ? 'Wilgotność: WŁ.' : 'Wilgotność: WYŁ.',
              selected: _includeHumidity,
              enabled: widget.enabled,
              onTap: () => setState(() => _includeHumidity = !_includeHumidity),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _InteractiveChipButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : AppColors.background;
    final Color effectiveBg = !widget.enabled
        ? AppColors.background.withValues(alpha: 0.45)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.42)
            : _hovered
                ? AppColors.surfaceLight
                : baseBg;
    final Color borderColor = !widget.enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : widget.selected
                ? AppColors.primaryAccent
                : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.enabled
                  ? (widget.selected ? AppColors.textPrimary : AppColors.textSecondary)
                  : AppColors.textSecondary.withValues(alpha: 0.45),
            ),
          ),
        ),
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
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
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
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: const Color(0xFF2A2F3D),
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

class _AirDensityCurvePainter extends CustomPainter {
  final List<AirDensitySample> samples;
  final double progress;
  final bool showTerminalVelocity;

  const _AirDensityCurvePainter({
    required this.samples,
    required this.progress,
    required this.showTerminalVelocity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 3; i++) {
      final double y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double minRho = samples.first.airDensityKgM3;
    double maxRho = samples.first.airDensityKgM3;
    double minVel = samples.first.terminalVelocityKmh;
    double maxVel = samples.first.terminalVelocityKmh;

    for (final s in samples) {
      minRho = math.min(minRho, s.airDensityKgM3);
      maxRho = math.max(maxRho, s.airDensityKgM3);
      minVel = math.min(minVel, s.terminalVelocityKmh);
      maxVel = math.max(maxVel, s.terminalVelocityKmh);
    }

    final double rhoSpan = math.max(0.05, maxRho - minRho);
    final double velSpan = math.max(2.0, maxVel - minVel);

    final Path rhoPath = Path();
    final Path velPath = Path();

    for (int i = 0; i < samples.length; i++) {
      final double x = (i / (samples.length - 1)) * size.width;
      final double rhoNorm = (samples[i].airDensityKgM3 - minRho) / rhoSpan;
      final double yRho = size.height - (rhoNorm * (size.height - 16) + 8);
      if (i == 0) {
        rhoPath.moveTo(x, yRho);
      } else {
        rhoPath.lineTo(x, yRho);
      }

      if (showTerminalVelocity) {
        final double velNorm = (samples[i].terminalVelocityKmh - minVel) / velSpan;
        final double yVel = size.height - (velNorm * (size.height - 16) + 8);
        if (i == 0) {
          velPath.moveTo(x, yVel);
        } else {
          velPath.lineTo(x, yVel);
        }
      }
    }

    if (showTerminalVelocity) {
      canvas.drawPath(
        velPath,
        Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    canvas.drawPath(
      rhoPath,
      Paint()
        ..color = AppColors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final double markerX = progress.clamp(0.0, 1.0) * size.width;
    canvas.drawLine(
      Offset(markerX, 0),
      Offset(markerX, size.height),
      Paint()
        ..color = AppColors.primaryAccent
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _AirDensityCurvePainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.progress != progress ||
        oldDelegate.showTerminalVelocity != showTerminalVelocity;
  }
}
