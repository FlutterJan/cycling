// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';

// =============================================================================
// 1. PRESETY ETAPÓW I FAZY ATMOSFERYCZNE CYKLU NIEBA
// =============================================================================

/// Presety tras wyścigowych definiujące okno czasowe od porannego startu
/// po złotą godzinę na mecie oraz lokalną szerokość geograficzną i przejrzystość.
enum SkyCycleStagePreset {
  grandDepartMorning(
    labelPl: 'Grand Départ • Poranny Start',
    shortTag: 'START 08:30',
    startHourDecimal: 8.5,
    finishHourDecimal: 17.75,
    latitudeDeg: 45.2,
    dayOfYear: 185,
    atmosphericTurbidity: 2.05,
    defaultCloudCoverage: 0.28,
  ),
  alpineQueenStage(
    labelPl: 'Etap Królewski • Alpy',
    shortTag: 'ALPY 10:15',
    startHourDecimal: 10.25,
    finishHourDecimal: 18.4,
    latitudeDeg: 45.1,
    dayOfYear: 198,
    atmosphericTurbidity: 1.55,
    defaultCloudCoverage: 0.22,
  ),
  mediterraneanCoast(
    labelPl: 'Wybrzeże Śródziemnomorskie',
    shortTag: 'MORZE 11:00',
    startHourDecimal: 11.0,
    finishHourDecimal: 17.85,
    latitudeDeg: 43.4,
    dayOfYear: 204,
    atmosphericTurbidity: 2.35,
    defaultCloudCoverage: 0.18,
  ),
  northernClassics(
    labelPl: 'Klasyk Północy • Flandria',
    shortTag: 'PÓŁNOC 09:45',
    startHourDecimal: 9.75,
    finishHourDecimal: 16.9,
    latitudeDeg: 50.8,
    dayOfYear: 96,
    atmosphericTurbidity: 2.75,
    defaultCloudCoverage: 0.45,
  ),
  summitGoldenFinale(
    labelPl: 'Finisz na Szczycie • Golden Hour',
    shortTag: 'SZCZYT 12:00',
    startHourDecimal: 12.0,
    finishHourDecimal: 19.15,
    latitudeDeg: 44.3,
    dayOfYear: 212,
    atmosphericTurbidity: 1.85,
    defaultCloudCoverage: 0.32,
  );

  final String labelPl;
  final String shortTag;
  final double startHourDecimal;
  final double finishHourDecimal;
  final double latitudeDeg;
  final int dayOfYear;
  final double atmosphericTurbidity;
  final double defaultCloudCoverage;

  const SkyCycleStagePreset({
    required this.labelPl,
    required this.shortTag,
    required this.startHourDecimal,
    required this.finishHourDecimal,
    required this.latitudeDeg,
    required this.dayOfYear,
    required this.atmosphericTurbidity,
    required this.defaultCloudCoverage,
  });

  /// Czas trwania etapu w godzinach.
  double get durationHours => finishHourDecimal - startHourDecimal;
}

/// Faza atmosferyczna kopuły nieba wynikająca z wysokości słońca nad horyzontem.
enum SkyDomeAtmosphericPhase {
  earlyMorningMist(
    labelPl: 'Poranny Świt i Mgła',
    badgeColor: Color(0xFFF59E0B),
  ),
  crispMorning(
    labelPl: 'Rześki Poranek',
    badgeColor: Color(0xFF38BDF8),
  ),
  highSolarNoon(
    labelPl: 'Pełne Słońce Południa',
    badgeColor: Color(0xFF00E5FF),
  ),
  warmAfternoon(
    labelPl: 'Popołudniowe Słońce',
    badgeColor: Color(0xFF10B981),
  ),
  goldenHourApproach(
    labelPl: 'Zbliżająca się Złota Godzina',
    badgeColor: Color(0xFFD4AF37),
  ),
  goldenHourFinish(
    labelPl: 'Złota Godzina na Mecie',
    badgeColor: Color(0xFFF97316),
  ),
  duskAfterglow(
    labelPl: 'Poświata Zmierzchu',
    badgeColor: Color(0xFF8E4A49),
  );

  final String labelPl;
  final Color badgeColor;

  const SkyDomeAtmosphericPhase({
    required this.labelPl,
    required this.badgeColor,
  });
}

// =============================================================================
// 2. MODELE DANYCH EFEMERYD SŁONECZNYCH I PALETY KOPUŁY NIEBA
// =============================================================================

/// Wektor pozycji słońca i parametry optyczne atmosfery w danej chwili etapu.
class SolarEphemerisVector {
  /// Wysokość słońca nad horyzontem w stopniach [-15.0, 90.0].
  final double elevationDeg;

  /// Azymut słońca w stopniach [0.0, 360.0), gdzie 0° = N, 90° = E, 180° = S, 270° = W.
  final double azimuthDeg;

  /// Znormalizowany kierunek do słońca w przestrzeni 3D (X: wschód, Y: góra, Z: południe).
  final Vector3 direction3D;

  /// Masa optyczna powietrza (Kasten-Young 1989) w zakresie [1.0, 38.0].
  final double airMass;

  /// Znormalizowana intensywność promieniowania bezpośredniego [0.0, 1.0].
  final double solarIntensity;

  /// Współczynnik wydłużenia cieni rzucanych przez kolarzy [0.25, 8.0].
  final double shadowLengthFactor;

  /// Skorelowana temperatura barwowa światła słonecznego w Kelvinach [2100, 6500].
  final int colorTemperatureKelvin;

  const SolarEphemerisVector({
    required this.elevationDeg,
    required this.azimuthDeg,
    required this.direction3D,
    required this.airMass,
    required this.solarIntensity,
    required this.shadowLengthFactor,
    required this.colorTemperatureKelvin,
  });

  /// Czy tarcza słoneczna znajduje się nad linią horyzontu.
  bool get isAboveHorizon => elevationDeg > -0.83;

  /// Czy słońce znajduje się w oknie złotej godziny (0°..14° wysokości).
  bool get isGoldenHourBand => elevationDeg >= -0.5 && elevationDeg <= 14.5;
}

/// Pełna paleta barw kopuły nieba, oświetlenia 3D i mgły atmosferycznej.
class SkyDomeColorPalette {
  final Color zenithColor;
  final Color midSkyColor;
  final Color horizonColor;
  final Color horizonHazeColor;
  final Color sunDiscColor;
  final Color sunCoronaColor;
  final Color ambientLightColor;
  final Color directionalLightColor;
  final Color rimLightColor;
  final Color groundBounceColor;
  final Color shadowTintColor;
  final Color fogTintColor;
  final Color mountainFarColor;
  final Color mountainNearColor;

  const SkyDomeColorPalette({
    required this.zenithColor,
    required this.midSkyColor,
    required this.horizonColor,
    required this.horizonHazeColor,
    required this.sunDiscColor,
    required this.sunCoronaColor,
    required this.ambientLightColor,
    required this.directionalLightColor,
    required this.rimLightColor,
    required this.groundBounceColor,
    required this.shadowTintColor,
    required this.fogTintColor,
    required this.mountainFarColor,
    required this.mountainNearColor,
  });

  /// Płynnie interpoluje wszystkie kanały palety dla przejść między porami dnia.
  static SkyDomeColorPalette lerp(
    SkyDomeColorPalette a,
    SkyDomeColorPalette b,
    double t,
  ) {
    final double clamped = t.clamp(0.0, 1.0);
    return SkyDomeColorPalette(
      zenithColor: Color.lerp(a.zenithColor, b.zenithColor, clamped)!,
      midSkyColor: Color.lerp(a.midSkyColor, b.midSkyColor, clamped)!,
      horizonColor: Color.lerp(a.horizonColor, b.horizonColor, clamped)!,
      horizonHazeColor:
          Color.lerp(a.horizonHazeColor, b.horizonHazeColor, clamped)!,
      sunDiscColor: Color.lerp(a.sunDiscColor, b.sunDiscColor, clamped)!,
      sunCoronaColor: Color.lerp(a.sunCoronaColor, b.sunCoronaColor, clamped)!,
      ambientLightColor:
          Color.lerp(a.ambientLightColor, b.ambientLightColor, clamped)!,
      directionalLightColor: Color.lerp(
        a.directionalLightColor,
        b.directionalLightColor,
        clamped,
      )!,
      rimLightColor: Color.lerp(a.rimLightColor, b.rimLightColor, clamped)!,
      groundBounceColor:
          Color.lerp(a.groundBounceColor, b.groundBounceColor, clamped)!,
      shadowTintColor:
          Color.lerp(a.shadowTintColor, b.shadowTintColor, clamped)!,
      fogTintColor: Color.lerp(a.fogTintColor, b.fogTintColor, clamped)!,
      mountainFarColor:
          Color.lerp(a.mountainFarColor, b.mountainFarColor, clamped)!,
      mountainNearColor:
          Color.lerp(a.mountainNearColor, b.mountainNearColor, clamped)!,
    );
  }
}

/// Pełny zrzut stanu atmosferycznego kopuły nieba dla danej chwili etapu.
class SkyDomeAtmosphereSnapshot {
  final double stageProgress;
  final double decimalHours;
  final String formattedTime;
  final SkyDomeAtmosphericPhase phase;
  final SolarEphemerisVector solar;
  final SkyDomeColorPalette palette;
  final double cloudScatterWarmth;
  final double crepuscularRayIntensity;
  final double horizonMistDensity;
  final double starVisibility;
  final double goldenHourFactor;

  const SkyDomeAtmosphereSnapshot({
    required this.stageProgress,
    required this.decimalHours,
    required this.formattedTime,
    required this.phase,
    required this.solar,
    required this.palette,
    required this.cloudScatterWarmth,
    required this.crepuscularRayIntensity,
    required this.horizonMistDensity,
    required this.starVisibility,
    required this.goldenHourFactor,
  });
}

/// Konfiguracja warstw renderowania kopuły nieba 3D.
class SkyDomeRenderConfig {
  final bool enableVolumetricSunCorona;
  final bool enableCrepuscularRays;
  final bool enableCirrusCloudLayer;
  final bool enableHorizonMist;
  final bool enableAtmosphericStars;
  final bool enableMountainSilhouette;
  final double cloudCoverage;
  final double windDriftSpeed;
  final double cameraAzimuthDeg;
  final double cameraPitchDeg;

  const SkyDomeRenderConfig({
    this.enableVolumetricSunCorona = true,
    this.enableCrepuscularRays = true,
    this.enableCirrusCloudLayer = true,
    this.enableHorizonMist = true,
    this.enableAtmosphericStars = true,
    this.enableMountainSilhouette = true,
    this.cloudCoverage = 0.28,
    this.windDriftSpeed = 1.0,
    this.cameraAzimuthDeg = 235.0,
    this.cameraPitchDeg = 8.0,
  });

  SkyDomeRenderConfig copyWith({
    bool? enableVolumetricSunCorona,
    bool? enableCrepuscularRays,
    bool? enableCirrusCloudLayer,
    bool? enableHorizonMist,
    bool? enableAtmosphericStars,
    bool? enableMountainSilhouette,
    double? cloudCoverage,
    double? windDriftSpeed,
    double? cameraAzimuthDeg,
    double? cameraPitchDeg,
  }) {
    return SkyDomeRenderConfig(
      enableVolumetricSunCorona:
          enableVolumetricSunCorona ?? this.enableVolumetricSunCorona,
      enableCrepuscularRays:
          enableCrepuscularRays ?? this.enableCrepuscularRays,
      enableCirrusCloudLayer:
          enableCirrusCloudLayer ?? this.enableCirrusCloudLayer,
      enableHorizonMist: enableHorizonMist ?? this.enableHorizonMist,
      enableAtmosphericStars:
          enableAtmosphericStars ?? this.enableAtmosphericStars,
      enableMountainSilhouette:
          enableMountainSilhouette ?? this.enableMountainSilhouette,
      cloudCoverage:
          (cloudCoverage ?? this.cloudCoverage).clamp(0.0, 1.0),
      windDriftSpeed:
          (windDriftSpeed ?? this.windDriftSpeed).clamp(0.0, 3.0),
      cameraAzimuthDeg: cameraAzimuthDeg ?? this.cameraAzimuthDeg,
      cameraPitchDeg:
          (cameraPitchDeg ?? this.cameraPitchDeg).clamp(-15.0, 45.0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkyDomeRenderConfig &&
        other.enableVolumetricSunCorona == enableVolumetricSunCorona &&
        other.enableCrepuscularRays == enableCrepuscularRays &&
        other.enableCirrusCloudLayer == enableCirrusCloudLayer &&
        other.enableHorizonMist == enableHorizonMist &&
        other.enableAtmosphericStars == enableAtmosphericStars &&
        other.enableMountainSilhouette == enableMountainSilhouette &&
        other.cloudCoverage == cloudCoverage &&
        other.windDriftSpeed == windDriftSpeed &&
        other.cameraAzimuthDeg == cameraAzimuthDeg &&
        other.cameraPitchDeg == cameraPitchDeg;
  }

  @override
  int get hashCode => Object.hash(
        enableVolumetricSunCorona,
        enableCrepuscularRays,
        enableCirrusCloudLayer,
        enableHorizonMist,
        enableAtmosphericStars,
        enableMountainSilhouette,
        cloudCoverage,
        windDriftSpeed,
        cameraAzimuthDeg,
        cameraPitchDeg,
      );
}

// =============================================================================
// 3. SILNIK FIZYKI SŁONECZNEJ I ROZPRASZANIA RAYLEIGHA / MIE
// =============================================================================

/// Deterministyczny silnik wyliczania pozycji słońca, masy optycznej powietrza
/// i palety barw kopuły nieba od porannego startu po złotą godzinę na mecie.
class SunriseSunsetSkyDomeEngine {
  const SunriseSunsetSkyDomeEngine();

  static const SkyDomeColorPalette _dawnPalette = SkyDomeColorPalette(
    zenithColor: Color(0xFF17284A),
    midSkyColor: Color(0xFF425A82),
    horizonColor: Color(0xFFF09D6B),
    horizonHazeColor: Color(0xFFF6C28B),
    sunDiscColor: Color(0xFFFFE4B5),
    sunCoronaColor: Color(0xFFFF9E5E),
    ambientLightColor: Color(0xFF8CA4C8),
    directionalLightColor: Color(0xFFFFB57A),
    rimLightColor: Color(0xFFFFD39C),
    groundBounceColor: Color(0xFF3E3834),
    shadowTintColor: Color(0xFF1D273B),
    fogTintColor: Color(0xFFD6A88D),
    mountainFarColor: Color(0xFF535B78),
    mountainNearColor: Color(0xFF232B3D),
  );

  static const SkyDomeColorPalette _morningPalette = SkyDomeColorPalette(
    zenithColor: Color(0xFF1A4E8A),
    midSkyColor: Color(0xFF4785C2),
    horizonColor: Color(0xFFA7D3F0),
    horizonHazeColor: Color(0xFFD7EBF7),
    sunDiscColor: Color(0xFFFFF8E7),
    sunCoronaColor: Color(0xFFFFE6B8),
    ambientLightColor: Color(0xFFB5D2EC),
    directionalLightColor: Color(0xFFFFF2D6),
    rimLightColor: Color(0xFFFFF7E2),
    groundBounceColor: Color(0xFF4B5563),
    shadowTintColor: Color(0xFF1F3047),
    fogTintColor: Color(0xFFC2DDF0),
    mountainFarColor: Color(0xFF567494),
    mountainNearColor: Color(0xFF283A4E),
  );

  static const SkyDomeColorPalette _middayPalette = SkyDomeColorPalette(
    zenithColor: Color(0xFF0E458C),
    midSkyColor: Color(0xFF357EC7),
    horizonColor: Color(0xFF9ACDF2),
    horizonHazeColor: Color(0xFFD9EEF9),
    sunDiscColor: Color(0xFFFFFFF7),
    sunCoronaColor: Color(0xFFFFF6DC),
    ambientLightColor: Color(0xFFC9E2F8),
    directionalLightColor: Color(0xFFFFFCF0),
    rimLightColor: Color(0xFFFFFFFF),
    groundBounceColor: Color(0xFF556070),
    shadowTintColor: Color(0xFF18283E),
    fogTintColor: Color(0xFFCDE5F5),
    mountainFarColor: Color(0xFF5E7D9C),
    mountainNearColor: Color(0xFF2B3D50),
  );

  static const SkyDomeColorPalette _goldenHourPalette = SkyDomeColorPalette(
    zenithColor: Color(0xFF1D315C),
    midSkyColor: Color(0xFF6B536D),
    horizonColor: Color(0xFFE8864A),
    horizonHazeColor: Color(0xFFF6BC6E),
    sunDiscColor: Color(0xFFFFDF94),
    sunCoronaColor: Color(0xFFFF8F3F),
    ambientLightColor: Color(0xFF9B838E),
    directionalLightColor: Color(0xFFFFA84D),
    rimLightColor: Color(0xFFD4AF37),
    groundBounceColor: Color(0xFF4A382B),
    shadowTintColor: Color(0xFF221E33),
    fogTintColor: Color(0xFFE5A169),
    mountainFarColor: Color(0xFF5E4858),
    mountainNearColor: Color(0xFF281F2B),
  );

  static const SkyDomeColorPalette _duskPalette = SkyDomeColorPalette(
    zenithColor: Color(0xFF0C1429),
    midSkyColor: Color(0xFF292B4E),
    horizonColor: Color(0xFF8E4A49),
    horizonHazeColor: Color(0xFFC76E50),
    sunDiscColor: Color(0xFFFF9C5B),
    sunCoronaColor: Color(0xFFCF4E3B),
    ambientLightColor: Color(0xFF4E4F73),
    directionalLightColor: Color(0xFFE86A42),
    rimLightColor: Color(0xFFF59E0B),
    groundBounceColor: Color(0xFF231F26),
    shadowTintColor: Color(0xFF0F111B),
    fogTintColor: Color(0xFF7B484B),
    mountainFarColor: Color(0xFF2C2A3E),
    mountainNearColor: Color(0xFF131520),
  );

  /// Wylicza wektor pozycji słońca dla godziny dziesiętnej [decimalHours],
  /// szerokości geograficznej [latitudeDeg] i dnia roku [dayOfYear].
  SolarEphemerisVector computeSolarEphemeris({
    required double decimalHours,
    double latitudeDeg = 45.1,
    int dayOfYear = 195,
  }) {
    final double clampedHours = decimalHours.clamp(0.0, 23.999);
    final double latRad = latitudeDeg.clamp(-85.0, 85.0) * math.pi / 180.0;

    // Deklinacja słoneczna (wzór Coopera).
    final double declinationDeg =
        23.44 * math.sin((2.0 * math.pi / 365.0) * (dayOfYear - 81));
    final double decRad = declinationDeg * math.pi / 180.0;

    // Kąt godzinny słońca (15° na każdą godzinę od 12:00 południa słonecznego).
    final double hourAngleDeg = (clampedHours - 12.2) * 15.0;
    final double hourAngleRad = hourAngleDeg * math.pi / 180.0;

    final double sinElev = (math.sin(latRad) * math.sin(decRad)) +
        (math.cos(latRad) * math.cos(decRad) * math.cos(hourAngleRad));
    final double elevRad = math.asin(sinElev.clamp(-1.0, 1.0));
    final double elevDeg = elevRad * 180.0 / math.pi;

    // Azymut względem północy (0°=N, 90°=E, 180°=S, 270°=W).
    final double cosElev = math.cos(elevRad).abs().clamp(1e-4, 1.0);
    final double cosAz =
        ((math.sin(decRad) - math.sin(latRad) * sinElev) /
                (math.cos(latRad) * cosElev))
            .clamp(-1.0, 1.0);
    double azDeg = math.acos(cosAz) * 180.0 / math.pi;
    if (hourAngleDeg > 0.0) {
      azDeg = 360.0 - azDeg;
    }
    azDeg = (azDeg % 360.0 + 360.0) % 360.0;

    final double azRad = azDeg * math.pi / 180.0;
    // W układzie 3D: +X = wschód, +Y = góra (zenit), +Z = północ.
    final Vector3 direction = Vector3(
      math.cos(elevRad) * math.sin(azRad),
      math.sin(elevRad),
      math.cos(elevRad) * math.cos(azRad),
    )..normalize();

    // Wzór Kasten-Young (1989) na masę optyczną powietrza.
    final double clampedForAm = elevDeg.clamp(-1.0, 90.0);
    final double airMass = clampedForAm <= -0.5
        ? 38.0
        : (1.0 /
                (math.sin(clampedForAm * math.pi / 180.0) +
                    0.50572 *
                        math.pow((clampedForAm + 6.07995).clamp(0.1, 96.0), -1.6364)))
            .clamp(1.0, 38.0);

    // Intensywność słońca po uwzględnieniu ekstynkcji Rayleigha/Mie.
    final double solarIntensity = elevDeg <= -1.5
        ? 0.04
        : (math.exp(-0.095 * (airMass - 1.0)) *
                ((elevDeg + 2.0) / 14.0).clamp(0.08, 1.0))
            .clamp(0.04, 1.0);

    // Długość rzucanego cienia (im niżej słońce, tym dłuższy dramatyczny cień).
    final double tanElev =
        math.tan(elevDeg.clamp(7.0, 82.0) * math.pi / 180.0);
    final double shadowLengthFactor = (1.0 / tanElev).clamp(0.25, 8.0);

    // Temperatura barwowa: ~2300 K o wschodzie/zachodzie -> ~5850 K w południe.
    final double kelvinNorm = (elevDeg / 48.0).clamp(0.0, 1.0);
    final int kelvin =
        (2250 + (3650 * math.pow(kelvinNorm, 0.72))).round().clamp(2100, 6500);

    return SolarEphemerisVector(
      elevationDeg: elevDeg,
      azimuthDeg: azDeg,
      direction3D: direction,
      airMass: airMass,
      solarIntensity: solarIntensity,
      shadowLengthFactor: shadowLengthFactor,
      colorTemperatureKelvin: kelvin,
    );
  }

  /// Wyznacza pełny stan kopuły nieba na podstawie postępu etapu [stageProgress] (0..1)
  /// i wybranego presetu wyścigu [preset].
  SkyDomeAtmosphereSnapshot evaluateAtStageProgress({
    required SkyCycleStagePreset preset,
    required double stageProgress,
    double? cloudCoverageOverride,
  }) {
    final double p = stageProgress.clamp(0.0, 1.0);
    final double decimalHours =
        preset.startHourDecimal + (preset.durationHours * p);
    return evaluateAtTime(
      decimalHours: decimalHours,
      stageProgress: p,
      latitudeDeg: preset.latitudeDeg,
      dayOfYear: preset.dayOfYear,
      atmosphericTurbidity: preset.atmosphericTurbidity,
      cloudCoverage: cloudCoverageOverride ?? preset.defaultCloudCoverage,
    );
  }

  /// Wyznacza pełny stan kopuły nieba dla zadanej godziny [decimalHours].
  SkyDomeAtmosphereSnapshot evaluateAtTime({
    required double decimalHours,
    double stageProgress = 0.0,
    double latitudeDeg = 45.1,
    int dayOfYear = 195,
    double atmosphericTurbidity = 2.0,
    double cloudCoverage = 0.28,
  }) {
    final double h = decimalHours.clamp(0.0, 23.999);
    final SolarEphemerisVector solar = computeSolarEphemeris(
      decimalHours: h,
      latitudeDeg: latitudeDeg,
      dayOfYear: dayOfYear,
    );

    final SkyDomeAtmosphericPhase phase = _classifyPhase(
      decimalHours: h,
      elevationDeg: solar.elevationDeg,
    );

    final SkyDomeColorPalette palette = _interpolatePalette(
      decimalHours: h,
      elevationDeg: solar.elevationDeg,
      turbidity: atmosphericTurbidity,
    );

    // Złota godzina osiąga maksimum przy niskim słońcu (0°..14°) po południu lub o świcie.
    final double elev = solar.elevationDeg;
    final double goldenHourFactor = elev < -2.0
        ? 0.0
        : elev <= 16.0
            ? (1.0 - ((elev - 5.5).abs() / 11.5)).clamp(0.0, 1.0)
            : (1.0 - ((elev - 16.0) / 14.0)).clamp(0.0, 0.25);

    final double cloudScatterWarmth =
        (goldenHourFactor * 0.92 + (h > 16.5 ? 0.12 : 0.0)).clamp(0.0, 1.0);

    final double crepuscularRayIntensity =
        ((0.25 + goldenHourFactor * 0.75) *
                (0.4 + cloudCoverage.clamp(0.0, 1.0) * 0.6) *
                (solar.isAboveHorizon ? 1.0 : 0.25))
            .clamp(0.0, 1.0);

    final double morningMist =
        h < 10.5 ? ((10.5 - h) / 3.0).clamp(0.0, 0.85) : 0.0;
    final double eveningMist =
        h > 17.0 ? ((h - 17.0) / 3.0).clamp(0.0, 0.55) : 0.0;
    final double horizonMistDensity =
        math.max(morningMist, eveningMist).clamp(0.08, 0.9);

    final double starVisibility = elev >= 6.0
        ? 0.0
        : ((6.0 - elev) / 12.0).clamp(0.0, 1.0);

    return SkyDomeAtmosphereSnapshot(
      stageProgress: stageProgress.clamp(0.0, 1.0),
      decimalHours: h,
      formattedTime: _formatDecimalHours(h),
      phase: phase,
      solar: solar,
      palette: palette,
      cloudScatterWarmth: cloudScatterWarmth,
      crepuscularRayIntensity: crepuscularRayIntensity,
      horizonMistDensity: horizonMistDensity,
      starVisibility: starVisibility,
      goldenHourFactor: goldenHourFactor,
    );
  }

  /// Generuje równomiernie rozłożone próbki cyklu od startu (0%) do mety (100%).
  List<SkyDomeAtmosphereSnapshot> generateTimelineSamples({
    required SkyCycleStagePreset preset,
    int sampleCount = 9,
  }) {
    final int count = sampleCount.clamp(2, 60);
    return List<SkyDomeAtmosphereSnapshot>.generate(count, (int index) {
      final double progress = index / (count - 1);
      return evaluateAtStageProgress(
        preset: preset,
        stageProgress: progress,
      );
    });
  }

  SkyDomeAtmosphericPhase _classifyPhase({
    required double decimalHours,
    required double elevationDeg,
  }) {
    if (decimalHours < 12.0) {
      if (elevationDeg < 14.0) return SkyDomeAtmosphericPhase.earlyMorningMist;
      if (elevationDeg < 34.0) return SkyDomeAtmosphericPhase.crispMorning;
      return SkyDomeAtmosphericPhase.highSolarNoon;
    }
    if (elevationDeg >= 34.0) return SkyDomeAtmosphericPhase.highSolarNoon;
    if (elevationDeg >= 20.0) return SkyDomeAtmosphericPhase.warmAfternoon;
    if (elevationDeg >= 12.0) {
      return SkyDomeAtmosphericPhase.goldenHourApproach;
    }
    if (elevationDeg >= 1.5) return SkyDomeAtmosphericPhase.goldenHourFinish;
    return SkyDomeAtmosphericPhase.duskAfterglow;
  }

  SkyDomeColorPalette _interpolatePalette({
    required double decimalHours,
    required double elevationDeg,
    required double turbidity,
  }) {
    final bool isMorning = decimalHours < 12.2;
    SkyDomeColorPalette base;

    if (elevationDeg <= 2.0) {
      final double t = ((elevationDeg + 6.0) / 8.0).clamp(0.0, 1.0);
      base = isMorning
          ? SkyDomeColorPalette.lerp(_duskPalette, _dawnPalette, t)
          : SkyDomeColorPalette.lerp(_duskPalette, _goldenHourPalette, t);
    } else if (elevationDeg <= 14.0) {
      final double t = ((elevationDeg - 2.0) / 12.0).clamp(0.0, 1.0);
      base = isMorning
          ? SkyDomeColorPalette.lerp(_dawnPalette, _morningPalette, t)
          : SkyDomeColorPalette.lerp(_goldenHourPalette, _morningPalette, t);
    } else if (elevationDeg <= 38.0) {
      final double t = ((elevationDeg - 14.0) / 24.0).clamp(0.0, 1.0);
      base = SkyDomeColorPalette.lerp(_morningPalette, _middayPalette, t);
    } else {
      base = _middayPalette;
    }

    // Mętność atmosferyczna (Mie) lekko ociepla horyzont.
    final double hazeBoost = ((turbidity - 1.5) * 0.14).clamp(0.0, 0.25);
    if (hazeBoost <= 0.001) return base;
    return SkyDomeColorPalette(
      zenithColor: base.zenithColor,
      midSkyColor: base.midSkyColor,
      horizonColor:
          Color.lerp(base.horizonColor, base.horizonHazeColor, hazeBoost)!,
      horizonHazeColor: base.horizonHazeColor,
      sunDiscColor: base.sunDiscColor,
      sunCoronaColor: base.sunCoronaColor,
      ambientLightColor: base.ambientLightColor,
      directionalLightColor: base.directionalLightColor,
      rimLightColor: base.rimLightColor,
      groundBounceColor: base.groundBounceColor,
      shadowTintColor: base.shadowTintColor,
      fogTintColor: base.fogTintColor,
      mountainFarColor: base.mountainFarColor,
      mountainNearColor: base.mountainNearColor,
    );
  }

  static String _formatDecimalHours(double decimalHours) {
    final int totalMinutes = (decimalHours * 60.0).round().clamp(0, 1439);
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// 4. PAINTER KOPUŁY NIEBA 3D, CHMUR CIRRUS, PROMIENI I SZOSY WYŚCIGOWEJ
// =============================================================================

/// Natywny renderer 3D kopuły nieba (`CustomPainter`) rysujący gradient Rayleigha,
/// tarczę słoneczną z koroną Mie, promienie krepuskularne, chmury cirrus,
/// alpejskie grzbiety górskie oraz oświetloną szosę wyścigową z cieniami.
class SunriseSunsetSkyDome3dPainter extends CustomPainter {
  final SkyDomeAtmosphereSnapshot snapshot;
  final SkyDomeRenderConfig config;
  final double animationPhase;

  const SunriseSunsetSkyDome3dPainter({
    required this.snapshot,
    required this.config,
    this.animationPhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final SkyDomeColorPalette palette = snapshot.palette;
    final double horizonY =
        (size.height * (0.64 + (config.cameraPitchDeg / 110.0)))
            .clamp(size.height * 0.35, size.height * 0.85);

    // 1. Kopuła nieba: wielostopniowy gradient od zenitu do horyzontu.
    final Rect skyRect = Rect.fromLTWH(0, 0, size.width, horizonY + 8);
    final Paint skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, horizonY),
        <Color>[
          palette.zenithColor,
          palette.midSkyColor,
          palette.horizonColor,
          palette.horizonHazeColor,
        ],
        const <double>[0.0, 0.44, 0.84, 1.0],
      );
    canvas.drawRect(skyRect, skyPaint);

    // 2. Gwiazdy o zmierzchu / przedświcie.
    if (config.enableAtmosphericStars && snapshot.starVisibility > 0.02) {
      _paintStars(canvas, size, horizonY);
    }

    // Rzutowanie 3D wektora słońca na ekran kamery.
    final Offset? sunScreenPos = _projectSkyDirection(
      direction: snapshot.solar.direction3D,
      size: size,
      horizonY: horizonY,
    );

    // 3. Poświata atmosferyczna horyzontu w kierunku słońca.
    if (sunScreenPos != null) {
      _paintHorizonSolarGlow(canvas, size, horizonY, sunScreenPos);
    }

    // 4. Promienie krepuskularne (God Rays).
    if (config.enableCrepuscularRays &&
        sunScreenPos != null &&
        snapshot.crepuscularRayIntensity > 0.05) {
      _paintCrepuscularRays(canvas, size, horizonY, sunScreenPos);
    }

    // 5. Tarcza słoneczna i wolumetryczna korona Mie.
    if (sunScreenPos != null && snapshot.solar.elevationDeg > -4.0) {
      _paintSunDiscAndCorona(canvas, size, horizonY, sunScreenPos);
    }

    // 6. Warstwa chmur Cirrus podświetlanych od spodu w złotej godzinie.
    if (config.enableCirrusCloudLayer && config.cloudCoverage > 0.02) {
      _paintCirrusClouds(canvas, size, horizonY);
    }

    // 7. Warstwowe sylwetki gór z perspektywą powietrzną.
    if (config.enableMountainSilhouette) {
      _paintMountainRidges(canvas, size, horizonY);
    }

    // 8. Mgła horyzontu (poranna rosa / złota poświata doliny).
    if (config.enableHorizonMist) {
      _paintHorizonMist(canvas, size, horizonY);
    }

    // 9. Płaszczyzna terenu i szosa wyścigowa z rzutem cienia kolarza.
    _paintForegroundRoadAndLighting(canvas, size, horizonY);
  }

  Offset? _projectSkyDirection({
    required Vector3 direction,
    required Size size,
    required double horizonY,
  }) {
    final double sunAzRad = math.atan2(direction.x, direction.z);
    final double camAzRad = config.cameraAzimuthDeg * math.pi / 180.0;
    double deltaAz = sunAzRad - camAzRad;
    while (deltaAz > math.pi) {
      deltaAz -= 2.0 * math.pi;
    }
    while (deltaAz < -math.pi) {
      deltaAz += 2.0 * math.pi;
    }

    // Pole widzenia poziome ~105°.
    if (deltaAz.abs() > 1.35) {
      return null;
    }

    final double xNorm = 0.5 + (deltaAz / 1.85);
    final double elevRad = math.asin(direction.y.clamp(-1.0, 1.0));
    final double pitchFactor = (elevRad / (math.pi * 0.42)).clamp(-0.12, 1.0);
    final double y = horizonY - (pitchFactor * horizonY * 0.92);
    return Offset(xNorm * size.width, y);
  }

  void _paintStars(Canvas canvas, Size size, double horizonY) {
    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    final double alpha = snapshot.starVisibility * 0.78;
    for (int i = 0; i < 42; i++) {
      final double seedX = ((i * 73 + 19) % 100) / 100.0;
      final double seedY = ((i * 41 + 7) % 100) / 100.0;
      final double twinkle =
          0.6 + 0.4 * math.sin(animationPhase * 2 * math.pi + i * 0.9);
      starPaint.color =
          Colors.white.withValues(alpha: (alpha * twinkle * (1.0 - seedY * 0.65)).clamp(0.0, 1.0));
      final double radius = (i % 5 == 0) ? 1.5 : 0.95;
      canvas.drawCircle(
        Offset(seedX * size.width, seedY * horizonY * 0.72),
        radius,
        starPaint,
      );
    }
  }

  void _paintHorizonSolarGlow(
    Canvas canvas,
    Size size,
    double horizonY,
    Offset sunPos,
  ) {
    final double glowRadius = size.width * (0.42 + snapshot.goldenHourFactor * 0.28);
    final Paint glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(sunPos.dx, math.min(sunPos.dy, horizonY)),
        glowRadius,
        <Color>[
          snapshot.palette.sunCoronaColor
              .withValues(alpha: (0.42 + snapshot.goldenHourFactor * 0.25).clamp(0.0, 0.75)),
          snapshot.palette.horizonHazeColor.withValues(alpha: 0.16),
          Colors.transparent,
        ],
        const <double>[0.0, 0.45, 1.0],
      );
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY + 12));
    canvas.drawCircle(
      Offset(sunPos.dx, math.min(sunPos.dy, horizonY)),
      glowRadius,
      glowPaint,
    );
    canvas.restore();
  }

  void _paintCrepuscularRays(
    Canvas canvas,
    Size size,
    double horizonY,
    Offset sunPos,
  ) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY));
    final double rayAlpha =
        (snapshot.crepuscularRayIntensity * 0.16).clamp(0.0, 0.22);
    final Paint rayPaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = ui.Gradient.radial(
        sunPos,
        size.width * 0.75,
        <Color>[
          snapshot.palette.sunCoronaColor.withValues(alpha: rayAlpha),
          Colors.transparent,
        ],
      );

    const int rayCount = 7;
    for (int i = 0; i < rayCount; i++) {
      final double baseAngle = -math.pi * 0.15 + (i * math.pi * 0.22);
      final double spread = 0.045 + (i % 2) * 0.02;
      final double len = size.width * 0.72;
      final Path path = Path()
        ..moveTo(sunPos.dx, sunPos.dy)
        ..lineTo(
          sunPos.dx + math.cos(baseAngle - spread) * len,
          sunPos.dy + math.sin(baseAngle - spread) * len,
        )
        ..lineTo(
          sunPos.dx + math.cos(baseAngle + spread) * len,
          sunPos.dy + math.sin(baseAngle + spread) * len,
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }
    canvas.restore();
  }

  void _paintSunDiscAndCorona(
    Canvas canvas,
    Size size,
    double horizonY,
    Offset sunPos,
  ) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY + 2));

    final double baseRadius = (size.shortestSide * 0.036).clamp(8.0, 18.0);
    if (config.enableVolumetricSunCorona) {
      final double coronaRadius =
          baseRadius * (3.8 + snapshot.goldenHourFactor * 2.2);
      final Paint coronaPaint = Paint()
        ..shader = ui.Gradient.radial(
          sunPos,
          coronaRadius,
          <Color>[
            snapshot.palette.sunDiscColor.withValues(alpha: 0.75),
            snapshot.palette.sunCoronaColor.withValues(alpha: 0.36),
            Colors.transparent,
          ],
          const <double>[0.0, 0.35, 1.0],
        );
      canvas.drawCircle(sunPos, coronaRadius, coronaPaint);
    }

    final Paint discPaint = Paint()
      ..color = snapshot.palette.sunDiscColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(sunPos, baseRadius, discPaint);
    canvas.restore();
  }

  void _paintCirrusClouds(Canvas canvas, Size size, double horizonY) {
    final int cloudCount = (3 + (config.cloudCoverage * 7).round()).clamp(2, 10);
    final double driftOffset =
        animationPhase * size.width * 0.18 * config.windDriftSpeed;

    final Color litCloudColor = Color.lerp(
      Colors.white,
      snapshot.palette.sunCoronaColor,
      snapshot.cloudScatterWarmth * 0.85,
    )!;
    final Color shadowCloudColor = Color.lerp(
      snapshot.palette.midSkyColor,
      snapshot.palette.horizonColor,
      0.35,
    )!;

    for (int i = 0; i < cloudCount; i++) {
      final double rawX =
          ((i * 0.23 + 0.08) * size.width + driftOffset) % (size.width * 1.25) -
              size.width * 0.12;
      final double y = horizonY * (0.16 + ((i * 19) % 48) / 100.0);
      final double w = size.width * (0.18 + (i % 3) * 0.07);
      final double h = 10.0 + (i % 4) * 4.5;

      final Rect cloudRect = Rect.fromCenter(
        center: Offset(rawX, y),
        width: w,
        height: h,
      );
      final Paint cloudPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(rawX, y - h * 0.5),
          Offset(rawX, y + h * 0.5),
          <Color>[
            shadowCloudColor.withValues(alpha: 0.32 * config.cloudCoverage),
            litCloudColor.withValues(alpha: 0.58 * config.cloudCoverage),
          ],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

      canvas.drawRRect(
        RRect.fromRectAndRadius(cloudRect, Radius.circular(h)),
        cloudPaint,
      );
    }
  }

  void _paintMountainRidges(Canvas canvas, Size size, double horizonY) {
    final double camShift = (config.cameraAzimuthDeg / 360.0) * size.width;
    // Daleki łańcuch górski.
    final Path farRidge = Path()..moveTo(0, horizonY + 4);
    const int steps = 18;
    for (int i = 0; i <= steps; i++) {
      final double x = (i / steps) * size.width;
      final double angle = (i / steps) * 6.5 + (camShift / size.width) * 4.0;
      final double peak =
          (math.sin(angle * 1.4) * 0.5 + math.cos(angle * 2.7) * 0.5 + 1.0) *
              0.5;
      final double y = horizonY - (14.0 + peak * size.height * 0.13);
      farRidge.lineTo(x, y);
    }
    farRidge
      ..lineTo(size.width, horizonY + 4)
      ..close();
    canvas.drawPath(
      farRidge,
      Paint()..color = snapshot.palette.mountainFarColor,
    );

    // Bliższy łańcuch górski.
    final Path nearRidge = Path()..moveTo(0, horizonY + 4);
    for (int i = 0; i <= steps; i++) {
      final double x = (i / steps) * size.width;
      final double angle = (i / steps) * 5.2 + (camShift / size.width) * 6.0;
      final double peak =
          (math.sin(angle * 1.8 + 1.1) * 0.55 + math.cos(angle * 3.1) * 0.45 + 1.0) *
              0.5;
      final double y = horizonY - (6.0 + peak * size.height * 0.075);
      nearRidge.lineTo(x, y);
    }
    nearRidge
      ..lineTo(size.width, horizonY + 4)
      ..close();
    canvas.drawPath(
      nearRidge,
      Paint()..color = snapshot.palette.mountainNearColor,
    );
  }

  void _paintHorizonMist(Canvas canvas, Size size, double horizonY) {
    final double mistHeight = size.height * 0.14;
    final Rect mistRect =
        Rect.fromLTWH(0, horizonY - mistHeight * 0.65, size.width, mistHeight);
    final Paint mistPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, mistRect.top),
        Offset(0, mistRect.bottom),
        <Color>[
          Colors.transparent,
          snapshot.palette.fogTintColor
              .withValues(alpha: (snapshot.horizonMistDensity * 0.52).clamp(0.0, 0.55)),
          Colors.transparent,
        ],
        const <double>[0.0, 0.55, 1.0],
      );
    canvas.drawRect(mistRect, mistPaint);
  }

  void _paintForegroundRoadAndLighting(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    // Tło terenu poniżej horyzontu.
    final Rect groundRect =
        Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY);
    final Paint groundPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, horizonY),
        Offset(0, size.height),
        <Color>[
          snapshot.palette.mountainNearColor,
          snapshot.palette.groundBounceColor,
        ],
      );
    canvas.drawRect(groundRect, groundPaint);

    // Wstęga szosy w perspektywie 3D.
    final double roadCenterX = size.width * 0.5;
    final double roadTopWidth = size.width * 0.03;
    final double roadBottomWidth = size.width * 0.56;

    final Path roadPath = Path()
      ..moveTo(roadCenterX - roadTopWidth * 0.5, horizonY)
      ..lineTo(roadCenterX + roadTopWidth * 0.5, horizonY)
      ..lineTo(roadCenterX + roadBottomWidth * 0.5, size.height)
      ..lineTo(roadCenterX - roadBottomWidth * 0.5, size.height)
      ..close();

    final Color asphaltBase = Color.lerp(
      const Color(0xFF1F242D),
      snapshot.palette.directionalLightColor,
      0.16 + snapshot.goldenHourFactor * 0.16,
    )!;
    canvas.drawPath(roadPath, Paint()..color = asphaltBase);

    // Przerywana linia środkowa i cień kierunkowy na asfalcie.
    final Paint centerLinePaint = Paint()
      ..color = snapshot.palette.rimLightColor.withValues(alpha: 0.72)
      ..strokeWidth = 2.0;
    for (int i = 0; i < 6; i++) {
      final double t0 = (i / 6.0);
      final double t1 = t0 + 0.08;
      final double y0 = horizonY + (size.height - horizonY) * (t0 * t0);
      final double y1 = horizonY + (size.height - horizonY) * (t1 * t1);
      canvas.drawLine(
        Offset(roadCenterX, y0),
        Offset(roadCenterX, y1),
        centerLinePaint,
      );
    }

    // Długi dramatyczny cień symbolizujący kierunek słońca na mecie / starcie.
    final double sunAzRad =
        (snapshot.solar.azimuthDeg - config.cameraAzimuthDeg) * math.pi / 180.0;
    final double shadowDirX = -math.sin(sunAzRad);
    final double shadowLen =
        (16.0 + snapshot.solar.shadowLengthFactor * 12.0).clamp(16.0, 95.0);
    final double riderY = horizonY + (size.height - horizonY) * 0.72;
    final Offset riderBase = Offset(roadCenterX, riderY);
    final Offset shadowEnd = Offset(
      roadCenterX + shadowDirX * shadowLen,
      riderY + 8.0,
    );

    canvas.drawLine(
      riderBase,
      shadowEnd,
      Paint()
        ..color = snapshot.palette.shadowTintColor.withValues(alpha: 0.65)
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      riderBase.translate(0, -6),
      5.5,
      Paint()..color = AppColors.goldAccent,
    );
  }

  @override
  bool shouldRepaint(covariant SunriseSunsetSkyDome3dPainter oldDelegate) {
    return oldDelegate.snapshot.decimalHours != snapshot.decimalHours ||
        oldDelegate.snapshot.stageProgress != snapshot.stageProgress ||
        oldDelegate.config != config ||
        oldDelegate.animationPhase != animationPhase;
  }
}

// =============================================================================
// 5. PRODUKCYJNY WIDŻET PODGLĄDU I STEROWANIA CYKLEM NIEBA 3D
// =============================================================================

/// Interaktywny panel podglądu i sterowania dynamicznym cyklem nieba i słońca
/// od porannego startu po złotą godzinę na mecie.
class SunriseSunsetDynamicSkyDome3dPanel extends StatefulWidget {
  final SkyCycleStagePreset initialPreset;
  final double initialProgress;
  final bool isEnabled;
  final ValueChanged<SkyDomeAtmosphereSnapshot>? onSnapshotChanged;

  const SunriseSunsetDynamicSkyDome3dPanel({
    super.key,
    this.initialPreset = SkyCycleStagePreset.alpineQueenStage,
    this.initialProgress = 0.0,
    this.isEnabled = true,
    this.onSnapshotChanged,
  });

  @override
  State<SunriseSunsetDynamicSkyDome3dPanel> createState() =>
      _SunriseSunsetDynamicSkyDome3dPanelState();
}

class _SunriseSunsetDynamicSkyDome3dPanelState
    extends State<SunriseSunsetDynamicSkyDome3dPanel>
    with SingleTickerProviderStateMixin {
  static const SunriseSunsetSkyDomeEngine _engine =
      SunriseSunsetSkyDomeEngine();

  late SkyCycleStagePreset _preset;
  late double _stageProgress;
  late SkyDomeRenderConfig _config;
  late AnimationController _animController;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _preset = widget.initialPreset;
    _stageProgress = widget.initialProgress.clamp(0.0, 1.0);
    _config = SkyDomeRenderConfig(
      cloudCoverage: _preset.defaultCloudCoverage,
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _animController.removeListener(_onAnimationTick);
    _animController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (!_isPlaying || !widget.isEnabled) return;
    setState(() {
      _stageProgress =
          (_stageProgress + 0.0018 * _playbackSpeed) % 1.0;
    });
    _notifySnapshot();
  }

  void _notifySnapshot() {
    final SkyDomeAtmosphereSnapshot snap = _currentSnapshot;
    widget.onSnapshotChanged?.call(snap);
  }

  SkyDomeAtmosphereSnapshot get _currentSnapshot =>
      _engine.evaluateAtStageProgress(
        preset: _preset,
        stageProgress: _stageProgress,
        cloudCoverageOverride: _config.cloudCoverage,
      );

  void _togglePlayback() {
    if (!widget.isEnabled) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
    });
  }

  void _selectPreset(SkyCycleStagePreset preset) {
    if (!widget.isEnabled) return;
    setState(() {
      _preset = preset;
      _config = _config.copyWith(cloudCoverage: preset.defaultCloudCoverage);
    });
    _notifySnapshot();
  }

  void _setProgress(double value) {
    if (!widget.isEnabled) return;
    setState(() {
      _stageProgress = value.clamp(0.0, 1.0);
    });
    _notifySnapshot();
  }

  void _jumpToCameraPhase({
    required double progress,
    required double azimuthDeg,
  }) {
    if (!widget.isEnabled) return;
    setState(() {
      _stageProgress = progress.clamp(0.0, 1.0);
      _config = _config.copyWith(cameraAzimuthDeg: azimuthDeg);
    });
    _notifySnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final SkyDomeAtmosphereSnapshot snapshot = _currentSnapshot;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isDesktopWide = constraints.maxWidth >= 960;
          final bool isCompactMobile = constraints.maxWidth < 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildHeader(snapshot, isCompactMobile),
              const SizedBox(height: 14),
              if (isDesktopWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 13,
                      child: _buildViewportCard(snapshot, height: 360),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 10,
                      child: _buildControlsColumn(snapshot, isCompactMobile),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildViewportCard(
                      snapshot,
                      height: isCompactMobile ? 220 : 280,
                    ),
                    const SizedBox(height: 14),
                    _buildControlsColumn(snapshot, isCompactMobile),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    SkyDomeAtmosphereSnapshot snapshot,
    bool isCompactMobile,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder, width: 1.0),
              ),
              child: const Icon(
                Icons.wb_twilight_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Kopuła Nieba 3D • Cykl Dnia Etapu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompactMobile ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _preset.labelPl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      letterSpacing: -0.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _PhaseStatusChip(phase: snapshot.phase, timeText: snapshot.formattedTime),
      ],
    );
  }

  Widget _buildViewportCard(
    SkyDomeAtmosphereSnapshot snapshot, {
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onPanUpdate: widget.isEnabled
                ? (DragUpdateDetails details) {
                    setState(() {
                      _config = _config.copyWith(
                        cameraAzimuthDeg:
                            (_config.cameraAzimuthDeg + details.delta.dx * 0.45) %
                                360.0,
                        cameraPitchDeg:
                            _config.cameraPitchDeg - details.delta.dy * 0.25,
                      );
                    });
                  }
                : null,
            child: CustomPaint(
              painter: SunriseSunsetSkyDome3dPainter(
                snapshot: snapshot,
                config: _config,
                animationPhase: _animController.value,
              ),
              size: Size.infinite,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                _TelemetryHudPill(
                  label: 'POSTĘP',
                  value: '${(_stageProgress * 100).round()}%',
                ),
                _TelemetryHudPill(
                  label: 'SŁOŃCE',
                  value:
                      '${snapshot.solar.elevationDeg.toStringAsFixed(1)}° • ${snapshot.solar.colorTemperatureKelvin}K',
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _SkyActionButton(
                  label: 'Poranny Start',
                  icon: Icons.wb_sunny_outlined,
                  isActive: _stageProgress < 0.2,
                  isEnabled: widget.isEnabled,
                  onPressed: () =>
                      _jumpToCameraPhase(progress: 0.0, azimuthDeg: 115.0),
                ),
                _SkyActionButton(
                  label: 'Południe',
                  icon: Icons.light_mode_outlined,
                  isActive: _stageProgress >= 0.35 && _stageProgress <= 0.65,
                  isEnabled: widget.isEnabled,
                  onPressed: () =>
                      _jumpToCameraPhase(progress: 0.48, azimuthDeg: 180.0),
                ),
                _SkyActionButton(
                  label: 'Golden Hour Meta',
                  icon: Icons.nights_stay_outlined,
                  isActive: _stageProgress > 0.8,
                  isEnabled: widget.isEnabled,
                  onPressed: () =>
                      _jumpToCameraPhase(progress: 0.96, azimuthDeg: 265.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsColumn(
    SkyDomeAtmosphereSnapshot snapshot,
    bool isCompactMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildPresetSelector(),
        const SizedBox(height: 12),
        _buildTimeScrubberCard(snapshot),
        const SizedBox(height: 12),
        _buildSolarTelemetryGrid(snapshot, isCompactMobile),
        const SizedBox(height: 12),
        _buildLayerTogglesCard(),
      ],
    );
  }

  Widget _buildPresetSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'PRESET ETAPU',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SkyCycleStagePreset.values.map((SkyCycleStagePreset p) {
              return _SkyActionButton(
                label: p.shortTag,
                isActive: _preset == p,
                isEnabled: widget.isEnabled,
                onPressed: () => _selectPreset(p),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeScrubberCard(SkyDomeAtmosphereSnapshot snapshot) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _SkyActionButton(
                label: _isPlaying ? 'Pauza' : 'Symuluj Cykl',
                icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                isActive: _isPlaying,
                isEnabled: widget.isEnabled,
                onPressed: _togglePlayback,
              ),
              const SizedBox(width: 8),
              _SkyActionButton(
                label: '${_playbackSpeed.toStringAsFixed(0)}x',
                isActive: _playbackSpeed > 1.0,
                isEnabled: widget.isEnabled,
                onPressed: () {
                  setState(() {
                    _playbackSpeed = _playbackSpeed == 1.0
                        ? 4.0
                        : (_playbackSpeed == 4.0 ? 12.0 : 1.0);
                  });
                },
              ),
              const Spacer(),
              Text(
                snapshot.formattedTime,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _stageProgress,
              onChanged: widget.isEnabled ? _setProgress : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarTelemetryGrid(
    SkyDomeAtmosphereSnapshot snapshot,
    bool isCompactMobile,
  ) {
    final List<_TelemetryItem> items = <_TelemetryItem>[
      _TelemetryItem(
        label: 'Elewacja',
        value: '${snapshot.solar.elevationDeg.toStringAsFixed(1)}°',
      ),
      _TelemetryItem(
        label: 'Azymut',
        value: '${snapshot.solar.azimuthDeg.toStringAsFixed(0)}°',
      ),
      _TelemetryItem(
        label: 'Barwa',
        value: '${snapshot.solar.colorTemperatureKelvin} K',
      ),
      _TelemetryItem(
        label: 'Cień',
        value: '${snapshot.solar.shadowLengthFactor.toStringAsFixed(2)}x',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((_TelemetryItem item) {
          return SizedBox(
            width: isCompactMobile ? 130 : 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLayerTogglesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'WARSTWY ATMOSFERYCZNE 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _SkyActionButton(
                label: 'Korona',
                isActive: _config.enableVolumetricSunCorona,
                isEnabled: widget.isEnabled,
                onPressed: () => setState(() {
                  _config = _config.copyWith(
                    enableVolumetricSunCorona:
                        !_config.enableVolumetricSunCorona,
                  );
                }),
              ),
              _SkyActionButton(
                label: 'Promienie',
                isActive: _config.enableCrepuscularRays,
                isEnabled: widget.isEnabled,
                onPressed: () => setState(() {
                  _config = _config.copyWith(
                    enableCrepuscularRays: !_config.enableCrepuscularRays,
                  );
                }),
              ),
              _SkyActionButton(
                label: 'Cirrus',
                isActive: _config.enableCirrusCloudLayer,
                isEnabled: widget.isEnabled,
                onPressed: () => setState(() {
                  _config = _config.copyWith(
                    enableCirrusCloudLayer: !_config.enableCirrusCloudLayer,
                  );
                }),
              ),
              _SkyActionButton(
                label: 'Mgła',
                isActive: _config.enableHorizonMist,
                isEnabled: widget.isEnabled,
                onPressed: () => setState(() {
                  _config = _config.copyWith(
                    enableHorizonMist: !_config.enableHorizonMist,
                  );
                }),
              ),
              _SkyActionButton(
                label: 'Góry',
                isActive: _config.enableMountainSilhouette,
                isEnabled: widget.isEnabled,
                onPressed: () => setState(() {
                  _config = _config.copyWith(
                    enableMountainSilhouette: !_config.enableMountainSilhouette,
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelemetryItem {
  final String label;
  final String value;

  const _TelemetryItem({required this.label, required this.value});
}

class _PhaseStatusChip extends StatelessWidget {
  final SkyDomeAtmosphericPhase phase;
  final String timeText;

  const _PhaseStatusChip({
    required this.phase,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: phase.badgeColor.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: phase.badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${phase.labelPl} • $timeText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryHudPill extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryHudPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$label ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Przycisk kontrolny z pełną obsługą stanów hover, active, focus i disabled.
class _SkyActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _SkyActionButton({
    required this.label,
    required this.isActive,
    required this.isEnabled,
    required this.onPressed,
    this.icon,
  });

  @override
  State<_SkyActionButton> createState() => _SkyActionButtonState();
}

class _SkyActionButtonState extends State<_SkyActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.isEnabled;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isActive
            ? AppColors.primaryAccent
            : _isHovered
                ? AppColors.surfaceLight
                : AppColors.background.withValues(alpha: 0.85);

    final Color borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isActive
                ? AppColors.goldAccent
                : _isHovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    final Color fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isActive
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool value) => setState(() => _isHovered = value),
      onShowFocusHighlight: (bool value) => setState(() => _isFocused = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            if (enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon, size: 14, color: fgColor),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight:
                        widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.2,
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
