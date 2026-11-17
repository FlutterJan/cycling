// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'aero_calculator.dart';

/// Strefy aerodynamiczne kolarza i roweru w solverze CFD.
enum CfdAeroZone {
  helmet('Helmet & Head', 'Kask i głowa', 0.046, 0.21),
  forearms('Forearms & Hands', 'Przedramiona i dłonie', 0.068, 0.075),
  textiles('Textiles & Torso', 'Tekstylia i tułów', 0.215, 0.34),
  wheels('Wheels & Tires', 'Koła i opony', 0.064, 0.065),
  frameAndCockpit('Frame & Cockpit', 'Rama i kokpit', 0.052, 0.055),
  legsAndDrivetrain('Legs & Drivetrain', 'Nogi i napęd', 0.095, 0.13);

  final String labelEn;
  final String labelPl;

  /// Wzorcowa powierzchnia czołowa strefy [m²] dla kolarza 70 kg / 178 cm.
  final double referenceAreaM2;

  /// Charakterystyczny wymiar liniowy D [m] dla liczby Reynoldsa i Strouhala.
  final double characteristicLengthM;

  const CfdAeroZone(
    this.labelEn,
    this.labelPl,
    this.referenceAreaM2,
    this.characteristicLengthM,
  );
}

/// Typ kasku kolarskiego wpływający na opór czołowy i oderwanie strugi za potylicą.
enum CfdHelmetType {
  roadVented('Road Vented', 'Szosowy wentylowany', 1.00, 0.205, 0.15),
  aeroRoad('Aero Road', 'Szosowy Aero', 0.84, 0.195, 0.10),
  ttShortTail('TT Short Tail', 'Czasowy krótki ogon', 0.72, 0.185, 0.08),
  ttLongTeardrop('TT Long Teardrop', 'Czasowy kroplowy', 0.64, 0.175, 0.22);

  final String labelEn;
  final String labelPl;
  final double cdMultiplier;
  final double strouhalNumber;
  final double yawSensitivity;

  const CfdHelmetType(
    this.labelEn,
    this.labelPl,
    this.cdMultiplier,
    this.strouhalNumber,
    this.yawSensitivity,
  );
}

/// Pozycja przedramion i dłoni na kokpicie.
enum CfdForearmPosture {
  hoodsWide('Hoods (Wide)', 'Chwyty (szeroko)', 1.00, 1.00, 0.210),
  dropsCompact('Drops (Compact)', 'Dolny chwyt', 0.86, 0.88, 0.198),
  puppyPaws('Puppy Paws', 'Przedramiona na kierownicy', 0.72, 0.76, 0.188),
  ttAeroBars('TT Aero Bars', 'Lemondka TT', 0.56, 0.64, 0.176),
  highHandsMantis('High Hands TT', 'Wysokie dłonie (Mantis)', 0.50, 0.58, 0.170);

  final String labelEn;
  final String labelPl;
  final double areaMultiplier;
  final double cdMultiplier;
  final double strouhalNumber;

  const CfdForearmPosture(
    this.labelEn,
    this.labelPl,
    this.areaMultiplier,
    this.cdMultiplier,
    this.strouhalNumber,
  );
}

/// Rodzaj tekstyliów i dopasowania stroju kolarskiego.
enum CfdTextileSpec {
  rainJacketFlapping('Rain Jacket (Flapping)', 'Peleryna (łopotanie)', 1.38, 0.215, 3.4e5),
  looseClubJersey('Club Fit Jersey', 'Koszulka luźna', 1.14, 0.205, 3.0e5),
  raceFitJersey('Pro Race Jersey', 'Koszulka Race-Fit', 0.96, 0.195, 2.5e5),
  aeroSkinsuitRibbed('Aero Skinsuit (Ribbed)', 'Kombinezon Aero (ryflowany)', 0.81, 0.182, 1.85e5);

  final String labelEn;
  final String labelPl;
  final double cdMultiplier;
  final double strouhalNumber;

  /// Krytyczna liczba Reynoldsa dla przejścia warstwy przyściennej (drag crisis).
  final double criticalReynolds;

  const CfdTextileSpec(
    this.labelEn,
    this.labelPl,
    this.cdMultiplier,
    this.strouhalNumber,
    this.criticalReynolds,
  );
}

/// Kategoria aerodynamiczna zestawu kół w CFD.
enum CfdWheelProfileSpec {
  shallowAlloy24('Shallow 24 mm', 'Niski profil 24 mm', 24, 25, 1.00, 0.04, 0.212),
  allRoundCarbon45('All-Round 45 mm', 'Uniwersalny 45 mm', 45, 28, 0.86, 0.28, 0.198),
  deepCarbon65('Deep Carbon 65 mm', 'Wysoki stożek 65 mm', 65, 28, 0.76, 0.52, 0.186),
  ttDiscRear80Front('TT Disc + 80 mm', 'Dysk + 80 mm TT', 80, 26, 0.63, 0.78, 0.172);

  final String labelEn;
  final String labelPl;
  final int rimDepthMm;
  final int externalRimWidthMm;
  final double cdMultiplier;

  /// Współczynnik efektu żagla (sailing effect) przy wietrze skośnym 5°–15°.
  final double sailingFactor;
  final double strouhalNumber;

  const CfdWheelProfileSpec(
    this.labelEn,
    this.labelPl,
    this.rimDepthMm,
    this.externalRimWidthMm,
    this.cdMultiplier,
    this.sailingFactor,
    this.strouhalNumber,
  );
}

/// Reżim przepływu powietrza w danej strefie CFD.
enum CfdFlowRegime {
  laminarAttached('Laminar Attached', 'Przepływ laminarny'),
  transitionalDragCrisis('Drag Crisis Transition', 'Kryzys oporu (przejście)'),
  turbulentAttached('Turbulent Attached', 'Turbulentny przylegający'),
  separatedWake('Separated Wake', 'Oderwanie strugi'),
  karmanVortexShedding('Kármán Vortex Street', 'Ścieżka wirów Kármána');

  final String labelEn;
  final String labelPl;

  const CfdFlowRegime(this.labelEn, this.labelPl);
}

/// Parametry wejściowe dla solvera strefowej aerodynamiki CFD.
class CfdSolverInput {
  /// Prędkość jazdy względem podłoża [km/h].
  final double groundSpeedKmh;

  /// Prędkość wiatru czołowego wzdłuż osi ruchu [km/h] (>0 w twarz, <0 w plecy).
  final double headwindKmh;

  /// Prędkość wiatru bocznego [km/h].
  final double crosswindKmh;

  /// Wysokość n.p.m. [m].
  final double altitudeMeters;

  /// Temperatura powietrza [°C].
  final double temperatureCelsius;

  /// Wzrost kolarza [cm].
  final double riderHeightCm;

  /// Masa kolarza [kg].
  final double riderWeightKg;

  /// Typ kasku.
  final CfdHelmetType helmetType;

  /// Pochylenie głowy (0.0 = wyprostowana, 1.0 = schowana między barki "turtle").
  final double headTuckFactor;

  /// Pozycja przedramion.
  final CfdForearmPosture forearmPosture;

  /// Specyfikacja odzieży / tekstyliów.
  final CfdTextileSpec textileSpec;

  /// Rozpięcie zamka koszulki (0.0 = zapięty, 1.0 = w pełni rozpięty).
  final double zipperOpenFraction;

  /// Specyfikacja kół.
  final CfdWheelProfileSpec wheelSpec;

  /// Szerokość opony [mm] (weryfikowana względem reguły 105% obręczy).
  final double tireWidthMm;

  /// Poziom integracji ramy/kokpitu (0.0 = okrągłe rury, 1.0 = superbike aero).
  final double frameAeroIntegration;

  /// Współczynnik redukcji ciśnienia dynamicznego w draftingu (0.0 = solo, 0.48 = środek peletonu).
  final double draftingReduction;

  /// Odległość od poprzedzającego kolarza [m] (dla obliczeń interferencji wirów Kármána).
  final double gapToRiderAheadMeters;

  /// Kadencja pedałowania [RPM] (wpływa na pulsację oporu nóg).
  final double cadenceRpm;

  const CfdSolverInput({
    required this.groundSpeedKmh,
    this.headwindKmh = 0.0,
    this.crosswindKmh = 0.0,
    this.altitudeMeters = 0.0,
    this.temperatureCelsius = 20.0,
    this.riderHeightCm = 178.0,
    this.riderWeightKg = 70.0,
    this.helmetType = CfdHelmetType.aeroRoad,
    this.headTuckFactor = 0.5,
    this.forearmPosture = CfdForearmPosture.dropsCompact,
    this.textileSpec = CfdTextileSpec.raceFitJersey,
    this.zipperOpenFraction = 0.0,
    this.wheelSpec = CfdWheelProfileSpec.allRoundCarbon45,
    this.tireWidthMm = 28.0,
    this.frameAeroIntegration = 0.75,
    this.draftingReduction = 0.0,
    this.gapToRiderAheadMeters = 20.0,
    this.cadenceRpm = 92.0,
  });

  CfdSolverInput copyWith({
    double? groundSpeedKmh,
    double? headwindKmh,
    double? crosswindKmh,
    double? altitudeMeters,
    double? temperatureCelsius,
    double? riderHeightCm,
    double? riderWeightKg,
    CfdHelmetType? helmetType,
    double? headTuckFactor,
    CfdForearmPosture? forearmPosture,
    CfdTextileSpec? textileSpec,
    double? zipperOpenFraction,
    CfdWheelProfileSpec? wheelSpec,
    double? tireWidthMm,
    double? frameAeroIntegration,
    double? draftingReduction,
    double? gapToRiderAheadMeters,
    double? cadenceRpm,
  }) {
    return CfdSolverInput(
      groundSpeedKmh: groundSpeedKmh ?? this.groundSpeedKmh,
      headwindKmh: headwindKmh ?? this.headwindKmh,
      crosswindKmh: crosswindKmh ?? this.crosswindKmh,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      riderHeightCm: riderHeightCm ?? this.riderHeightCm,
      riderWeightKg: riderWeightKg ?? this.riderWeightKg,
      helmetType: helmetType ?? this.helmetType,
      headTuckFactor: headTuckFactor ?? this.headTuckFactor,
      forearmPosture: forearmPosture ?? this.forearmPosture,
      textileSpec: textileSpec ?? this.textileSpec,
      zipperOpenFraction: zipperOpenFraction ?? this.zipperOpenFraction,
      wheelSpec: wheelSpec ?? this.wheelSpec,
      tireWidthMm: tireWidthMm ?? this.tireWidthMm,
      frameAeroIntegration: frameAeroIntegration ?? this.frameAeroIntegration,
      draftingReduction: draftingReduction ?? this.draftingReduction,
      gapToRiderAheadMeters: gapToRiderAheadMeters ?? this.gapToRiderAheadMeters,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
    );
  }
}

/// Wynik obliczeń CFD dla pojedynczej strefy ciała/roweru.
class CfdZoneBreakdown {
  final CfdAeroZone zone;
  final double frontalAreaM2;
  final double localCd;
  final double effectiveCdA;
  final double dragForceNewtons;
  final double aeroPowerWatts;
  final double shareOfTotalDrag;
  final double reynoldsNumber;
  final double strouhalNumber;
  final double karmanFrequencyHz;
  final double pressureCoefficientCp;
  final CfdFlowRegime flowRegime;

  const CfdZoneBreakdown({
    required this.zone,
    required this.frontalAreaM2,
    required this.localCd,
    required this.effectiveCdA,
    required this.dragForceNewtons,
    required this.aeroPowerWatts,
    required this.shareOfTotalDrag,
    required this.reynoldsNumber,
    required this.strouhalNumber,
    required this.karmanFrequencyHz,
    required this.pressureCoefficientCp,
    required this.flowRegime,
  });
}

/// Pojedynczy węzeł wiru w ścieżce Kármána za kolarzem (do analizy śladu i wizualizacji).
class KarmanVortexNode {
  /// Odległość za kolarzem w osi podłużnej [m].
  final double downstreamMeters;

  /// Przesunięcie poprzeczne względem osi ruchu [m].
  final double lateralOffsetMeters;

  /// Cyrkulacja / siła wiru (znak + lub - dla naprzemiennego odrywania wirów).
  final double circulationStrength;

  /// Promień rdzenia wiru [m].
  final double coreRadiusMeters;

  /// Współczynnik zaniku energii wiru (0.0 – 1.0).
  final double energyRetention;

  const KarmanVortexNode({
    required this.downstreamMeters,
    required this.lateralOffsetMeters,
    required this.circulationStrength,
    required this.coreRadiusMeters,
    required this.energyRetention,
  });
}

/// Pełny wynik solvera strefowej aerodynamiki CFD.
class CfdSolverResult {
  final List<CfdZoneBreakdown> zones;
  final double totalFrontalAreaM2;
  final double totalCdA;
  final double totalDragForceNewtons;
  final double totalAeroPowerWatts;

  /// Zysk mocy z efektu żagla na kołach i ramie przy wietrze bocznym [W].
  final double sailingEffectWattsGain;

  /// Czy spełniona jest reguła aerodynamiczna 105% (szerokość obręczy >= 1.05 * szerokość opony).
  final bool satisfiesRuleOf105;

  /// Prędkość wiatru pozornego [m/s].
  final double apparentWindSpeedMs;

  /// Prędkość wiatru pozornego [km/h].
  double get apparentWindSpeedKmh => apparentWindSpeedMs * 3.6;

  /// Kąt natarcia wiatru pozornego (yaw) [°].
  final double yawAngleDegrees;

  /// Gęstość powietrza [kg/m³].
  final double airDensityKgM3;

  /// Lepkość kinematyczna powietrza [m²/s].
  final double kinematicViscosityM2S;

  /// Ciśnienie dynamiczne napływu q = 0.5 * rho * v_app^2 [Pa].
  final double dynamicPressurePa;

  /// Dominująca częstotliwość odrywania wirów Kármána [Hz].
  final double karmanDominantFrequencyHz;

  /// Intensywność turbulencji śladu aerodynamicznego za kolarzem (0.0 – 1.0).
  final double karmanWakeTurbulenceIntensity;

  /// Straty mocy generowane bezpośrednio przez periodyczne odrywanie wirów [W].
  final double vortexInducedDragWatts;

  /// Szacowana długość efektywnego tunelu aerodynamicznego za kolarzem [m].
  final double wakeLengthMeters;

  const CfdSolverResult({
    required this.zones,
    required this.totalFrontalAreaM2,
    required this.totalCdA,
    required this.totalDragForceNewtons,
    required this.totalAeroPowerWatts,
    required this.sailingEffectWattsGain,
    required this.satisfiesRuleOf105,
    required this.apparentWindSpeedMs,
    required this.yawAngleDegrees,
    required this.airDensityKgM3,
    required this.kinematicViscosityM2S,
    required this.dynamicPressurePa,
    required this.karmanDominantFrequencyHz,
    required this.karmanWakeTurbulenceIntensity,
    required this.vortexInducedDragWatts,
    required this.wakeLengthMeters,
  });

  /// Zwraca wynik dla wskazanej strefy aerodynamicznej.
  CfdZoneBreakdown zoneOf(CfdAeroZone zone) {
    return zones.firstWhere((z) => z.zone == zone);
  }
}

/// Punkt pomiarowy polarny dla przemiatania kąta yaw.
class CfdYawSweepPoint {
  final double yawDegrees;
  final double totalCdA;
  final double totalAeroPowerWatts;
  final double sailingEffectWattsGain;
  final double karmanDominantFrequencyHz;

  const CfdYawSweepPoint({
    required this.yawDegrees,
    required this.totalCdA,
    required this.totalAeroPowerWatts,
    required this.sailingEffectWattsGain,
    required this.karmanDominantFrequencyHz,
  });
}

/// Porównanie dwóch konfiguracji CFD (np. przed i po tunelu aero).
class CfdComparisonResult {
  final CfdSolverResult baseline;
  final CfdSolverResult upgraded;

  /// Różnica CdA (wartość ujemna oznacza redukcję oporu) [m²].
  final double deltaCdA;

  /// Oszczędność mocy przy zadanej prędkości [W] (>0 = oszczędność).
  final double wattsSaved;

  /// Szacowany zysk czasu na dystansie testowym [s] (>0 = szybciej).
  final double timeSavedSeconds;

  const CfdComparisonResult({
    required this.baseline,
    required this.upgraded,
    required this.deltaCdA,
    required this.wattsSaved,
    required this.timeSavedSeconds,
  });
}

/// Solver strefowej aerodynamiki CFD w czasie rzeczywistym:
/// - Analiza strefowa: kask, przedramiona, tekstylia, koła, rama/kokpit, nogi.
/// - Liczba Reynoldsa i kryzys oporu warstwy przyściennej (Sutherland viscosity).
/// - Liczba Strouhala i ścieżka wirów Kármána (częstotliwość odrywania, turbulencja śladu).
/// - Efekt żagla na wysokich stożkach oraz reguła 105% obręcz/opona.
class RealTimeCfdVortexAndDragSolver {
  RealTimeCfdVortexAndDragSolver._();

  /// Wzorcowa powierzchnia ciała (BSA) dla 178 cm / 70 kg wg wzoru Du Boisa [m²].
  static const double _referenceBsaM2 = 1.869;

  /// Rozwiązuje pełny stan aerodynamiczny CFD dla pojedynczej klatki symulacji.
  static CfdSolverResult solveFrame(CfdSolverInput input) {
    final double speedMs = math.max(0.0, input.groundSpeedKmh) / 3.6;
    final double headwindMs = input.headwindKmh / 3.6;
    final double crosswindMs = input.crosswindKmh / 3.6;

    final double axialAirspeedMs = speedMs + headwindMs;
    final double apparentWindMs = math.sqrt(
      axialAirspeedMs * axialAirspeedMs + crosswindMs * crosswindMs,
    );

    final double yawRadians = apparentWindMs > 0.05
        ? math.atan2(crosswindMs.abs(), axialAirspeedMs.abs().clamp(0.05, 100.0))
        : 0.0;
    final double yawDegrees = (yawRadians * 180.0 / math.pi).clamp(0.0, 90.0);

    final double airDensity = AeroCalculator.calculateAirDensity(
      altitudeMeters: input.altitudeMeters,
      temperatureCelsius: input.temperatureCelsius,
    );
    final double dynamicViscosity = _calculateAirDynamicViscosity(
      input.temperatureCelsius,
    );
    final double kinematicViscosity = dynamicViscosity / airDensity;

    final double draftingClamp = input.draftingReduction.clamp(0.0, 0.52);
    final double dynamicPressure = 0.5 * airDensity * apparentWindMs * apparentWindMs * (1.0 - draftingClamp);

    // Skalowanie antropometryczne powierzchni czołowej (wzór Du Boisa).
    final double h = input.riderHeightCm.clamp(145.0, 210.0);
    final double w = input.riderWeightKg.clamp(45.0, 110.0);
    final double bsa = 0.007184 * math.pow(w, 0.425) * math.pow(h, 0.725);
    final double anthropometryScale = (bsa / _referenceBsaM2).clamp(0.75, 1.35);

    // Interferencja śladu od poprzedzającego kolarza (podnosi turbulencję napływu).
    final double wakeInterferenceFactor = input.gapToRiderAheadMeters < 6.0 && input.draftingReduction > 0.01
        ? (1.0 - (input.gapToRiderAheadMeters.clamp(0.2, 6.0) / 6.0)) * 0.35
        : 0.0;

    final List<CfdZoneBreakdown> rawZones = <CfdZoneBreakdown>[
      _solveHelmetZone(input, apparentWindMs, yawDegrees, kinematicViscosity, dynamicPressure, speedMs, anthropometryScale),
      _solveForearmsZone(input, apparentWindMs, yawDegrees, kinematicViscosity, dynamicPressure, speedMs, anthropometryScale),
      _solveTextilesZone(input, apparentWindMs, yawDegrees, kinematicViscosity, dynamicPressure, speedMs, anthropometryScale, wakeInterferenceFactor),
      _solveWheelsZone(input, apparentWindMs, yawDegrees, kinematicViscosity, dynamicPressure, speedMs),
      _solveFrameZone(input, apparentWindMs, yawDegrees, kinematicViscosity, dynamicPressure, speedMs),
      _solveLegsZone(input, apparentWindMs, yawDegrees, kinematicViscosity, dynamicPressure, speedMs, anthropometryScale),
    ];

    double totalArea = 0.0;
    double totalCdA = 0.0;
    double totalDrag = 0.0;
    double totalPower = 0.0;

    for (final z in rawZones) {
      totalArea += z.frontalAreaM2;
      totalCdA += z.effectiveCdA;
      totalDrag += z.dragForceNewtons;
      totalPower += z.aeroPowerWatts;
    }

    final List<CfdZoneBreakdown> normalizedZones = rawZones
        .map(
          (z) => CfdZoneBreakdown(
            zone: z.zone,
            frontalAreaM2: z.frontalAreaM2,
            localCd: z.localCd,
            effectiveCdA: z.effectiveCdA,
            dragForceNewtons: z.dragForceNewtons,
            aeroPowerWatts: z.aeroPowerWatts,
            shareOfTotalDrag: totalDrag > 1e-6 ? z.dragForceNewtons / totalDrag : 0.0,
            reynoldsNumber: z.reynoldsNumber,
            strouhalNumber: z.strouhalNumber,
            karmanFrequencyHz: z.karmanFrequencyHz,
            pressureCoefficientCp: z.pressureCoefficientCp,
            flowRegime: z.flowRegime,
          ),
        )
        .toList(growable: false);

    // Efekt żagla na kołach i ramie przy wietrze bocznym 4°–18°.
    final double yawBell = math.exp(-math.pow((yawDegrees - 10.5) / 6.0, 2));
    final double sailingWatts = (input.wheelSpec.sailingFactor * 14.0 + input.frameAeroIntegration * 3.5) *
        yawBell *
        (apparentWindMs / 12.5).clamp(0.0, 1.8) *
        (1.0 - draftingClamp * 0.7);

    // Reguła 105%: zewnętrzna szerokość obręczy >= 1.05 * szerokość opony.
    final bool satisfies105 = input.wheelSpec.externalRimWidthMm >= input.tireWidthMm * 1.05;

    // Dominująca częstotliwość wirów Kármána (ważona udziałem oporu stref o silnym oderwaniu).
    final CfdZoneBreakdown torso = normalizedZones[2];
    final CfdZoneBreakdown helmet = normalizedZones[0];
    final double dominantKarmanHz = apparentWindMs > 0.5
        ? (torso.karmanFrequencyHz * 0.55 + helmet.karmanFrequencyHz * 0.45)
        : 0.0;

    // Intensywność turbulencji śladu zależy od prędkości, rozpiętego zamka i łopotania tkanin.
    final double textileTurbulence = (input.textileSpec.cdMultiplier - 0.75).clamp(0.05, 0.70);
    final double zipperTurbulence = input.zipperOpenFraction.clamp(0.0, 1.0) * 0.25;
    final double wakeTurbulence = ((textileTurbulence + zipperTurbulence) * (apparentWindMs / 14.0).clamp(0.2, 1.4))
        .clamp(0.05, 0.95);

    // Straty mocy generowane bezpośrednio przez periodyczne odrywanie wirów (ok. 11–18% oporu całkowitego).
    final double vortexPower = totalPower * (0.11 + wakeTurbulence * 0.08);

    // Długość efektywnego śladu aerodynamicznego za kolarzem [m].
    final double wakeLength = (1.6 + apparentWindMs * 0.24 - (yawDegrees * 0.08)).clamp(1.2, 6.8);

    return CfdSolverResult(
      zones: normalizedZones,
      totalFrontalAreaM2: totalArea,
      totalCdA: totalCdA,
      totalDragForceNewtons: totalDrag,
      totalAeroPowerWatts: totalPower,
      sailingEffectWattsGain: sailingWatts,
      satisfiesRuleOf105: satisfies105,
      apparentWindSpeedMs: apparentWindMs,
      yawAngleDegrees: yawDegrees,
      airDensityKgM3: airDensity,
      kinematicViscosityM2S: kinematicViscosity,
      dynamicPressurePa: dynamicPressure,
      karmanDominantFrequencyHz: dominantKarmanHz,
      karmanWakeTurbulenceIntensity: wakeTurbulence,
      vortexInducedDragWatts: vortexPower,
      wakeLengthMeters: wakeLength,
    );
  }

  /// Przeprowadza przemiatanie kąta wiatru pozornego (Yaw Sweep) od -20° do +20°.
  static List<CfdYawSweepPoint> sweepYawAngles(
    CfdSolverInput baseInput, {
    double minYawDegrees = -20.0,
    double maxYawDegrees = 20.0,
    double stepDegrees = 2.5,
  }) {
    final double step = math.max(0.5, stepDegrees);
    final double speedKmh = math.max(10.0, baseInput.groundSpeedKmh);
    final List<CfdYawSweepPoint> points = <CfdYawSweepPoint>[];

    for (double yaw = minYawDegrees; yaw <= maxYawDegrees + 1e-6; yaw += step) {
      final double clampedYaw = yaw.clamp(-45.0, 45.0);
      final double yawRad = clampedYaw * math.pi / 180.0;
      final double crosswindKmh = speedKmh * math.tan(yawRad);

      final CfdSolverResult res = solveFrame(
        baseInput.copyWith(
          headwindKmh: 0.0,
          crosswindKmh: crosswindKmh,
        ),
      );
      points.add(
        CfdYawSweepPoint(
          yawDegrees: clampedYaw,
          totalCdA: res.totalCdA,
          totalAeroPowerWatts: res.totalAeroPowerWatts,
          sailingEffectWattsGain: res.sailingEffectWattsGain,
          karmanDominantFrequencyHz: res.karmanDominantFrequencyHz,
        ),
      );
    }

    return points;
  }

  /// Porównuje dwie konfiguracje (np. sprzęt bazowy vs po optymalizacji CFD) i liczy zysk czasu.
  static CfdComparisonResult compareConfigurations({
    required CfdSolverInput baselineInput,
    required CfdSolverInput upgradedInput,
    double distanceKm = 40.0,
    double riderPowerWatts = 400.0,
  }) {
    final CfdSolverResult baseline = solveFrame(baselineInput);
    final CfdSolverResult upgraded = solveFrame(upgradedInput);

    final double deltaCdA = upgraded.totalCdA - baseline.totalCdA;
    final double wattsSaved = baseline.totalAeroPowerWatts - upgraded.totalAeroPowerWatts;

    // Przybliżony czas przejazdu dystansu przy zadanej mocy (P_total ~ P_aero + P_roll).
    final double vBase = math.max(
      5.0,
      math.pow(
        (riderPowerWatts * 0.88) / math.max(0.05, 0.5 * baseline.airDensityKgM3 * baseline.totalCdA),
        1.0 / 3.0,
      ).toDouble(),
    );
    final double vUpg = math.max(
      5.0,
      math.pow(
        (riderPowerWatts * 0.88) / math.max(0.05, 0.5 * upgraded.airDensityKgM3 * upgraded.totalCdA),
        1.0 / 3.0,
      ).toDouble(),
    );

    final double distanceM = math.max(100.0, distanceKm * 1000.0);
    final double timeBase = distanceM / vBase;
    final double timeUpg = distanceM / vUpg;

    return CfdComparisonResult(
      baseline: baseline,
      upgraded: upgraded,
      deltaCdA: deltaCdA,
      wattsSaved: wattsSaved,
      timeSavedSeconds: timeBase - timeUpg,
    );
  }

  /// Generuje deterministyczne węzły ścieżki wirów Kármána za kolarzem w chwili [timeSeconds].
  static List<KarmanVortexNode> sampleWakeVortexField({
    required CfdSolverResult solverResult,
    required double timeSeconds,
    int vortexPairCount = 8,
  }) {
    final int count = vortexPairCount.clamp(2, 24);
    final double freq = math.max(0.5, solverResult.karmanDominantFrequencyHz);
    final double wakeLen = solverResult.wakeLengthMeters;
    final double convSpeed = math.max(1.0, solverResult.apparentWindSpeedMs * 0.82);
    final double wavelength = (convSpeed / freq).clamp(0.18, 1.5);
    final double yawOffsetRatio = math.tan(solverResult.yawAngleDegrees * math.pi / 180.0).clamp(-0.6, 0.6);

    final List<KarmanVortexNode> nodes = <KarmanVortexNode>[];
    final double phaseShift = (timeSeconds * freq) % 1.0;

    for (int i = 0; i < count; i++) {
      final double sign = i.isEven ? 1.0 : -1.0;
      final double downstream = ((i * 0.5 + phaseShift) * wavelength).clamp(0.15, wakeLen + 1.0);
      if (downstream > wakeLen) continue;

      final double progress = downstream / wakeLen;
      final double lateralSpread = (0.14 + progress * 0.22) * sign + downstream * yawOffsetRatio * 0.35;
      final double retention = math.exp(-progress * 1.45).clamp(0.08, 1.0);

      nodes.add(
        KarmanVortexNode(
          downstreamMeters: downstream,
          lateralOffsetMeters: lateralSpread,
          circulationStrength: sign * solverResult.karmanWakeTurbulenceIntensity * retention,
          coreRadiusMeters: 0.08 + progress * 0.14,
          energyRetention: retention,
        ),
      );
    }

    return nodes;
  }

  // ---------------------------------------------------------------------------
  // Prywatne solvery poszczególnych stref
  // ---------------------------------------------------------------------------

  static CfdZoneBreakdown _solveHelmetZone(
    CfdSolverInput input,
    double apparentWindMs,
    double yawDeg,
    double nu,
    double dynamicPressure,
    double groundSpeedMs,
    double anthroScale,
  ) {
    final double tuck = input.headTuckFactor.clamp(0.0, 1.0);
    final double area = CfdAeroZone.helmet.referenceAreaM2 * anthroScale * (1.08 - tuck * 0.18);

    // Kask długi kroplowy traci przy dużym kącie yaw, krótki jest stabilniejszy.
    final double yawPenalty = 1.0 + (yawDeg / 20.0) * input.helmetType.yawSensitivity;
    final double re = _reynolds(apparentWindMs, CfdAeroZone.helmet.characteristicLengthM, nu);
    final double reModifier = _dragCrisisModifier(re, 2.2e5, 0.08);
    final double localCd = (0.68 * input.helmetType.cdMultiplier * yawPenalty * reModifier).clamp(0.32, 1.15);

    final double cda = area * localCd;
    final double dragN = cda * dynamicPressure;
    final double powerW = dragN * groundSpeedMs;
    final double st = input.helmetType.strouhalNumber * (1.0 - yawDeg * 0.002);
    final double freq = _karmanFreq(st, apparentWindMs, CfdAeroZone.helmet.characteristicLengthM);

    return CfdZoneBreakdown(
      zone: CfdAeroZone.helmet,
      frontalAreaM2: area,
      localCd: localCd,
      effectiveCdA: cda,
      dragForceNewtons: dragN,
      aeroPowerWatts: powerW,
      shareOfTotalDrag: 0.0,
      reynoldsNumber: re,
      strouhalNumber: st,
      karmanFrequencyHz: freq,
      pressureCoefficientCp: 0.85 - (1.0 - input.helmetType.cdMultiplier) * 0.35,
      flowRegime: input.helmetType == CfdHelmetType.roadVented
          ? CfdFlowRegime.karmanVortexShedding
          : CfdFlowRegime.turbulentAttached,
    );
  }

  static CfdZoneBreakdown _solveForearmsZone(
    CfdSolverInput input,
    double apparentWindMs,
    double yawDeg,
    double nu,
    double dynamicPressure,
    double groundSpeedMs,
    double anthroScale,
  ) {
    final double area = CfdAeroZone.forearms.referenceAreaM2 *
        anthroScale *
        input.forearmPosture.areaMultiplier;
    final double re = _reynolds(apparentWindMs, CfdAeroZone.forearms.characteristicLengthM, nu);
    final double reModifier = _dragCrisisModifier(re, 1.7e5, 0.07);
    final double yawFactor = 1.0 + (yawDeg / 30.0) * 0.14;
    final double localCd = (0.78 * input.forearmPosture.cdMultiplier * reModifier * yawFactor).clamp(0.36, 1.10);

    final double cda = area * localCd;
    final double dragN = cda * dynamicPressure;
    final double powerW = dragN * groundSpeedMs;
    final double st = input.forearmPosture.strouhalNumber;
    final double freq = _karmanFreq(st, apparentWindMs, CfdAeroZone.forearms.characteristicLengthM);

    return CfdZoneBreakdown(
      zone: CfdAeroZone.forearms,
      frontalAreaM2: area,
      localCd: localCd,
      effectiveCdA: cda,
      dragForceNewtons: dragN,
      aeroPowerWatts: powerW,
      shareOfTotalDrag: 0.0,
      reynoldsNumber: re,
      strouhalNumber: st,
      karmanFrequencyHz: freq,
      pressureCoefficientCp: 0.78 * input.forearmPosture.cdMultiplier,
      flowRegime: input.forearmPosture == CfdForearmPosture.hoodsWide
          ? CfdFlowRegime.separatedWake
          : CfdFlowRegime.turbulentAttached,
    );
  }

  static CfdZoneBreakdown _solveTextilesZone(
    CfdSolverInput input,
    double apparentWindMs,
    double yawDeg,
    double nu,
    double dynamicPressure,
    double groundSpeedMs,
    double anthroScale,
    double wakeInterference,
  ) {
    final double postureScale = input.forearmPosture == CfdForearmPosture.ttAeroBars ||
            input.forearmPosture == CfdForearmPosture.highHandsMantis
        ? 0.84
        : input.forearmPosture == CfdForearmPosture.puppyPaws
            ? 0.90
            : 1.00;
    final double area = CfdAeroZone.textiles.referenceAreaM2 * anthroScale * postureScale;

    final double re = _reynolds(apparentWindMs, CfdAeroZone.textiles.characteristicLengthM, nu);
    final double effectiveRe = re * (1.0 + wakeInterference);
    final double reModifier = _dragCrisisModifier(
      effectiveRe,
      input.textileSpec.criticalReynolds,
      0.13,
    );

    // Rozpięty zamek tworzy "spadochron" z tyłu koszulki (+14% lokalnego Cd przy pełnym rozpięciu).
    final double zipperPenalty = 1.0 + input.zipperOpenFraction.clamp(0.0, 1.0) * 0.14;
    final double yawFactor = 1.0 + (yawDeg / 25.0) * 0.11;
    final double localCd = (0.64 * input.textileSpec.cdMultiplier * reModifier * zipperPenalty * yawFactor)
        .clamp(0.38, 1.25);

    final double cda = area * localCd;
    final double dragN = cda * dynamicPressure;
    final double powerW = dragN * groundSpeedMs;
    final double st = input.textileSpec.strouhalNumber;
    final double freq = _karmanFreq(st, apparentWindMs, CfdAeroZone.textiles.characteristicLengthM);

    final CfdFlowRegime regime;
    if (effectiveRe < input.textileSpec.criticalReynolds * 0.85) {
      regime = CfdFlowRegime.laminarAttached;
    } else if (effectiveRe <= input.textileSpec.criticalReynolds * 1.15) {
      regime = CfdFlowRegime.transitionalDragCrisis;
    } else if (input.textileSpec == CfdTextileSpec.rainJacketFlapping ||
        input.zipperOpenFraction > 0.5) {
      regime = CfdFlowRegime.karmanVortexShedding;
    } else {
      regime = CfdFlowRegime.turbulentAttached;
    }

    return CfdZoneBreakdown(
      zone: CfdAeroZone.textiles,
      frontalAreaM2: area,
      localCd: localCd,
      effectiveCdA: cda,
      dragForceNewtons: dragN,
      aeroPowerWatts: powerW,
      shareOfTotalDrag: 0.0,
      reynoldsNumber: re,
      strouhalNumber: st,
      karmanFrequencyHz: freq,
      pressureCoefficientCp: 0.92 * input.textileSpec.cdMultiplier,
      flowRegime: regime,
    );
  }

  static CfdZoneBreakdown _solveWheelsZone(
    CfdSolverInput input,
    double apparentWindMs,
    double yawDeg,
    double nu,
    double dynamicPressure,
    double groundSpeedMs,
  ) {
    final double tireFactor = (input.tireWidthMm.clamp(23.0, 38.0) / 28.0);
    final double area = CfdAeroZone.wheels.referenceAreaM2 * (0.85 + 0.15 * tireFactor);

    // Kara za złamanie reguły 105% (opona szersza niż obręcz powoduje oderwanie strugi).
    final double ratio105 = input.tireWidthMm * 1.05 / input.wheelSpec.externalRimWidthMm;
    final double rule105Penalty = ratio105 > 1.0 ? 1.0 + (ratio105 - 1.0) * 0.35 : 1.0;

    // Efekt żagla zmniejsza efektywne Cd kół w zakresie yaw 5°–15°.
    final double yawBell = math.exp(-math.pow((yawDeg - 10.0) / 6.5, 2));
    final double sailingCdReduction = 1.0 - (input.wheelSpec.sailingFactor * 0.22 * yawBell);

    final double re = _reynolds(apparentWindMs, CfdAeroZone.wheels.characteristicLengthM, nu);
    final double localCd = (0.58 * input.wheelSpec.cdMultiplier * rule105Penalty * sailingCdReduction)
        .clamp(0.24, 0.95);

    final double cda = area * localCd;
    final double dragN = cda * dynamicPressure;
    final double powerW = dragN * groundSpeedMs;
    final double st = input.wheelSpec.strouhalNumber;
    final double freq = _karmanFreq(st, apparentWindMs, CfdAeroZone.wheels.characteristicLengthM);

    return CfdZoneBreakdown(
      zone: CfdAeroZone.wheels,
      frontalAreaM2: area,
      localCd: localCd,
      effectiveCdA: cda,
      dragForceNewtons: dragN,
      aeroPowerWatts: powerW,
      shareOfTotalDrag: 0.0,
      reynoldsNumber: re,
      strouhalNumber: st,
      karmanFrequencyHz: freq,
      pressureCoefficientCp: 0.62 * input.wheelSpec.cdMultiplier,
      flowRegime: ratio105 > 1.05 ? CfdFlowRegime.separatedWake : CfdFlowRegime.turbulentAttached,
    );
  }

  static CfdZoneBreakdown _solveFrameZone(
    CfdSolverInput input,
    double apparentWindMs,
    double yawDeg,
    double nu,
    double dynamicPressure,
    double groundSpeedMs,
  ) {
    final double integration = input.frameAeroIntegration.clamp(0.0, 1.0);
    final double area = CfdAeroZone.frameAndCockpit.referenceAreaM2 * (1.06 - integration * 0.14);
    final double re = _reynolds(apparentWindMs, CfdAeroZone.frameAndCockpit.characteristicLengthM, nu);
    final double yawFactor = 1.0 + (yawDeg / 25.0) * 0.09;
    final double localCd = (0.56 * (1.12 - integration * 0.34) * yawFactor).clamp(0.28, 0.85);

    final double cda = area * localCd;
    final double dragN = cda * dynamicPressure;
    final double powerW = dragN * groundSpeedMs;
    const double st = 0.185;
    final double freq = _karmanFreq(st, apparentWindMs, CfdAeroZone.frameAndCockpit.characteristicLengthM);

    return CfdZoneBreakdown(
      zone: CfdAeroZone.frameAndCockpit,
      frontalAreaM2: area,
      localCd: localCd,
      effectiveCdA: cda,
      dragForceNewtons: dragN,
      aeroPowerWatts: powerW,
      shareOfTotalDrag: 0.0,
      reynoldsNumber: re,
      strouhalNumber: st,
      karmanFrequencyHz: freq,
      pressureCoefficientCp: 0.58 * (1.1 - integration * 0.25),
      flowRegime: integration > 0.65 ? CfdFlowRegime.turbulentAttached : CfdFlowRegime.separatedWake,
    );
  }

  static CfdZoneBreakdown _solveLegsZone(
    CfdSolverInput input,
    double apparentWindMs,
    double yawDeg,
    double nu,
    double dynamicPressure,
    double groundSpeedMs,
    double anthroScale,
  ) {
    final double area = CfdAeroZone.legsAndDrivetrain.referenceAreaM2 * anthroScale;
    final double re = _reynolds(apparentWindMs, CfdAeroZone.legsAndDrivetrain.characteristicLengthM, nu);

    // Wyższa kadencja generuje dodatkowy opór oscylacyjny nóg.
    final double cadencePenalty = 1.0 + ((input.cadenceRpm.clamp(50.0, 130.0) - 85.0) / 100.0) * 0.06;
    final double yawFactor = 1.0 + (yawDeg / 28.0) * 0.08;
    final double localCd = (0.62 * cadencePenalty * yawFactor).clamp(0.45, 0.92);

    final double cda = area * localCd;
    final double dragN = cda * dynamicPressure;
    final double powerW = dragN * groundSpeedMs;
    const double st = 0.205;
    final double freq = _karmanFreq(st, apparentWindMs, CfdAeroZone.legsAndDrivetrain.characteristicLengthM);

    return CfdZoneBreakdown(
      zone: CfdAeroZone.legsAndDrivetrain,
      frontalAreaM2: area,
      localCd: localCd,
      effectiveCdA: cda,
      dragForceNewtons: dragN,
      aeroPowerWatts: powerW,
      shareOfTotalDrag: 0.0,
      reynoldsNumber: re,
      strouhalNumber: st,
      karmanFrequencyHz: freq,
      pressureCoefficientCp: 0.74,
      flowRegime: CfdFlowRegime.karmanVortexShedding,
    );
  }

  /// Prawo Sutherlanda dla lepkości dynamicznej powietrza [Pa*s].
  static double _calculateAirDynamicViscosity(double temperatureCelsius) {
    final double t = (temperatureCelsius + 273.15).clamp(200.0, 340.0);
    const double mu0 = 1.716e-5;
    const double t0 = 273.15;
    const double s = 110.4;
    return mu0 * math.pow(t / t0, 1.5) * ((t0 + s) / (t + s));
  }

  static double _reynolds(double velocityMs, double charLengthM, double nu) {
    if (velocityMs <= 0.0 || charLengthM <= 0.0 || nu <= 0.0) return 0.0;
    return (velocityMs * charLengthM) / nu;
  }

  static double _karmanFreq(double strouhal, double velocityMs, double charLengthM) {
    if (velocityMs <= 0.0 || charLengthM <= 0.0) return 0.0;
    return (strouhal * velocityMs) / charLengthM;
  }

  /// Gładka funkcja sigmoidalna przejścia kryzysu oporu wokół [criticalRe].
  static double _dragCrisisModifier(double re, double criticalRe, double dropMagnitude) {
    if (re <= 0.0 || criticalRe <= 0.0) return 1.0;
    final double normalized = ((re - criticalRe) / (criticalRe * 0.25)).clamp(-10.0, 10.0);
    final double sigmoid = 1.0 / (1.0 + math.exp(-normalized));
    return 1.0 - (dropMagnitude * sigmoid);
  }
}

/// Interaktywny panel inspektora strefowej aerodynamiki CFD i ścieżki wirów Kármána.
class RealTimeCfdVortexAndDragPanel extends StatefulWidget {
  final CfdSolverInput initialInput;
  final bool enabled;
  final ValueChanged<CfdSolverResult>? onSolved;

  const RealTimeCfdVortexAndDragPanel({
    super.key,
    this.initialInput = const CfdSolverInput(groundSpeedKmh: 48.0),
    this.enabled = true,
    this.onSolved,
  });

  @override
  State<RealTimeCfdVortexAndDragPanel> createState() =>
      _RealTimeCfdVortexAndDragPanelState();
}

class _RealTimeCfdVortexAndDragPanelState
    extends State<RealTimeCfdVortexAndDragPanel> {
  late CfdSolverInput _input;
  CfdAeroZone? _hoveredZone;
  CfdAeroZone _selectedZone = CfdAeroZone.textiles;
  bool _presetHovered = false;
  bool _presetFocused = false;

  @override
  void initState() {
    super.initState();
    _input = widget.initialInput;
  }

  void _updateInput(CfdSolverInput next) {
    if (!widget.enabled) return;
    setState(() {
      _input = next;
    });
    widget.onSolved?.call(RealTimeCfdVortexAndDragSolver.solveFrame(next));
  }

  @override
  Widget build(BuildContext context) {
    final CfdSolverResult result = RealTimeCfdVortexAndDragSolver.solveFrame(_input);
    final List<KarmanVortexNode> vortices =
        RealTimeCfdVortexAndDragSolver.sampleWakeVortexField(
      solverResult: result,
      timeSeconds: 0.42,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 600;
        final bool isDesktop = constraints.maxWidth >= 1100;

        return Container(
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(result, isCompact),
                const SizedBox(height: 14),
                _buildPresetBar(isCompact),
                const SizedBox(height: 14),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildZoneBreakdownList(result)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _buildVortexCard(result, vortices)),
                    ],
                  )
                else ...[
                  _buildZoneBreakdownList(result),
                  const SizedBox(height: 14),
                  _buildVortexCard(result, vortices),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(CfdSolverResult result, bool isCompact) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REAL-TIME CFD VORTEX & ZONAL DRAG',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'CdA ${result.totalCdA.toStringAsFixed(4)} m² • ${result.totalAeroPowerWatts.toStringAsFixed(1)} W • Kármán ${result.karmanDominantFrequencyHz.toStringAsFixed(1)} Hz',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.accentBlue,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: result.satisfiesRuleOf105
                ? AppColors.statusSuccess.withValues(alpha: 0.14)
                : AppColors.amberWarning.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: result.satisfiesRuleOf105
                  ? AppColors.statusSuccess
                  : AppColors.amberWarning,
              width: 1.0,
            ),
          ),
          child: Text(
            result.satisfiesRuleOf105 ? '105% RULE OK' : '105% RULE WARN',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: result.satisfiesRuleOf105
                  ? AppColors.statusSuccess
                  : AppColors.amberWarning,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetBar(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          label: 'TT Aero Setup',
          active: _input.forearmPosture == CfdForearmPosture.ttAeroBars,
          onTap: () => _updateInput(
            _input.copyWith(
              groundSpeedKmh: 52.0,
              helmetType: CfdHelmetType.ttLongTeardrop,
              forearmPosture: CfdForearmPosture.ttAeroBars,
              textileSpec: CfdTextileSpec.aeroSkinsuitRibbed,
              wheelSpec: CfdWheelProfileSpec.ttDiscRear80Front,
              tireWidthMm: 25.0,
              headTuckFactor: 0.85,
            ),
          ),
        ),
        _buildActionButton(
          label: 'Road Breakaway',
          active: _input.forearmPosture == CfdForearmPosture.dropsCompact,
          onTap: () => _updateInput(
            _input.copyWith(
              groundSpeedKmh: 45.0,
              helmetType: CfdHelmetType.aeroRoad,
              forearmPosture: CfdForearmPosture.dropsCompact,
              textileSpec: CfdTextileSpec.raceFitJersey,
              wheelSpec: CfdWheelProfileSpec.deepCarbon65,
              tireWidthMm: 28.0,
              headTuckFactor: 0.55,
            ),
          ),
        ),
        _buildActionButton(
          label: 'Rain Crosswind',
          active: _input.textileSpec == CfdTextileSpec.rainJacketFlapping,
          onTap: () => _updateInput(
            _input.copyWith(
              groundSpeedKmh: 40.0,
              crosswindKmh: 22.0,
              helmetType: CfdHelmetType.roadVented,
              forearmPosture: CfdForearmPosture.hoodsWide,
              textileSpec: CfdTextileSpec.rainJacketFlapping,
              wheelSpec: CfdWheelProfileSpec.allRoundCarbon45,
              tireWidthMm: 30.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final bool disabled = !widget.enabled;
    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (hover) => setState(() => _presetHovered = hover),
      onShowFocusHighlight: (focus) => setState(() => _presetFocused = focus),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.surfaceLight.withValues(alpha: 0.4)
                : active
                    ? AppColors.primaryAccent
                    : (_presetHovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _presetFocused
                  ? AppColors.goldAccent
                  : (active ? AppColors.goldAccent : AppColors.cardBorder),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: disabled ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneBreakdownList(CfdSolverResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ZONAL DRAG BREAKDOWN',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          for (final zone in result.zones)
            MouseRegion(
              onEnter: (_) => setState(() => _hoveredZone = zone.zone),
              onExit: (_) => setState(() => _hoveredZone = null),
              child: GestureDetector(
                onTap: widget.enabled
                    ? () => setState(() => _selectedZone = zone.zone)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedZone == zone.zone
                        ? AppColors.primaryAccent.withValues(alpha: 0.25)
                        : (_hoveredZone == zone.zone
                            ? AppColors.surface
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedZone == zone.zone
                          ? AppColors.goldAccent
                          : AppColors.cardBorder.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              zone.zone.labelPl,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${(zone.shareOfTotalDrag * 100).toStringAsFixed(1)}% • ${zone.aeroPowerWatts.toStringAsFixed(1)} W',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: zone.shareOfTotalDrag.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _selectedZone == zone.zone
                                ? AppColors.goldAccent
                                : AppColors.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVortexCard(
    CfdSolverResult result,
    List<KarmanVortexNode> vortices,
  ) {
    final CfdZoneBreakdown selected = result.zoneOf(_selectedZone);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KÁRMÁN VORTEX STREET',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _KarmanVortexMiniPainter(vortices: vortices),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Strefa: ${selected.zone.labelPl} (${selected.flowRegime.labelPl})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Re ${(selected.reynoldsNumber / 1e5).toStringAsFixed(2)}e5 • St ${selected.strouhalNumber.toStringAsFixed(3)} • f ${selected.karmanFrequencyHz.toStringAsFixed(1)} Hz',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Straty wirowe: ${result.vortexInducedDragWatts.toStringAsFixed(1)} W • Efekt żagla: +${result.sailingEffectWattsGain.toStringAsFixed(1)} W',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.statusSuccess,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _KarmanVortexMiniPainter extends CustomPainter {
  final List<KarmanVortexNode> vortices;

  _KarmanVortexMiniPainter({required this.vortices});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()..color = AppColors.background;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bgPaint,
    );

    final double midY = size.height * 0.5;
    final Paint axisPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(16, midY), Offset(size.width - 12, midY), axisPaint);

    // Sylwetka kolarza z przodu (strefa stagnacji).
    final Paint riderPaint = Paint()..color = AppColors.goldAccent;
    canvas.drawCircle(Offset(20, midY), 6, riderPaint);

    for (final node in vortices) {
      final double x = 28.0 + (node.downstreamMeters / 5.5) * (size.width - 42.0);
      final double y = midY + node.lateralOffsetMeters * 75.0;
      if (x < 0 || x > size.width) continue;

      final Color vortexColor = node.circulationStrength >= 0
          ? AppColors.accentBlue
          : AppColors.primaryAccent;
      final Paint vortexPaint = Paint()
        ..color = vortexColor.withValues(alpha: (0.25 + node.energyRetention * 0.65).clamp(0.1, 0.9))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(
        Offset(x.clamp(10.0, size.width - 10.0), y.clamp(10.0, size.height - 10.0)),
        (node.coreRadiusMeters * 65.0).clamp(4.0, 18.0),
        vortexPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KarmanVortexMiniPainter oldDelegate) =>
      oldDelegate.vortices != vortices;
}
