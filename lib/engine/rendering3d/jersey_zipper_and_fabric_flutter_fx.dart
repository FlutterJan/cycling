// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Typ wierzchniej warstwy odzieży kolarskiej wpływający na łopotanie materiału.
enum GarmentOuterLayerType {
  raceAeroJersey(
    label: 'Aero Race',
    loosenessFactor: 0.24,
    sleeveLengthRatio: 0.82,
    stiffnessFactor: 0.88,
    supportsZipperUnzip: true,
  ),
  standardClubJersey(
    label: 'Klasyczna',
    loosenessFactor: 0.45,
    sleeveLengthRatio: 0.72,
    stiffnessFactor: 0.72,
    supportsZipperUnzip: true,
  ),
  thermalGilet(
    label: 'Kamizelka',
    loosenessFactor: 0.62,
    sleeveLengthRatio: 0.70,
    stiffnessFactor: 0.60,
    supportsZipperUnzip: true,
  ),
  rainShellJacket(
    label: 'Kurtka Deszcz.',
    loosenessFactor: 1.00,
    sleeveLengthRatio: 1.00,
    stiffnessFactor: 0.32,
    supportsZipperUnzip: false,
  );

  final String label;
  final double loosenessFactor;
  final double sleeveLengthRatio;
  final double stiffnessFactor;
  final bool supportsZipperUnzip;

  const GarmentOuterLayerType({
    required this.label,
    required this.loosenessFactor,
    required this.sleeveLengthRatio,
    required this.stiffnessFactor,
    required this.supportsZipperUnzip,
  });
}

/// Strefa odzieży objęta animacją drgań i łopotania na wietrze.
enum FabricFlutterZone {
  leftSleeve('Lewy rękawek'),
  rightSleeve('Prawy rękawek'),
  chestZipperLapel('Klapy zamka'),
  rainJacketCape('Peleryna kurtki'),
  rearHemTail('Dolny brzeg');

  final String label;
  const FabricFlutterZone(this.label);
}

/// Presety scenariuszy aerodynamicznych i termicznych dla łopotania oraz zamka.
enum FabricFlutterConditionPreset {
  alpineHeatClimb(
    label: 'Wspinaczka w upale',
    speedKmh: 18.5,
    headwindKmh: 4.0,
    crosswindAngleDeg: 18.0,
    temperatureCelsius: 33.5,
    gradientPercent: 9.8,
    powerWatts: 405.0,
    cadenceRpm: 76.0,
    garmentType: GarmentOuterLayerType.raceAeroJersey,
    isWearingRainJacket: false,
    isStandingOutOfSaddle: true,
  ),
  pelotonFlat45Kmh(
    label: 'Peleton 45 km/h',
    speedKmh: 45.5,
    headwindKmh: 8.0,
    crosswindAngleDeg: 12.0,
    temperatureCelsius: 21.0,
    gradientPercent: 0.4,
    powerWatts: 285.0,
    cadenceRpm: 94.0,
    garmentType: GarmentOuterLayerType.raceAeroJersey,
    isWearingRainJacket: false,
    isStandingOutOfSaddle: false,
  ),
  crosswindEchelon(
    label: 'Wachlarz boczny',
    speedKmh: 48.0,
    headwindKmh: 14.0,
    crosswindAngleDeg: 68.0,
    temperatureCelsius: 17.5,
    gradientPercent: 0.0,
    powerWatts: 360.0,
    cadenceRpm: 96.0,
    garmentType: GarmentOuterLayerType.standardClubJersey,
    isWearingRainJacket: false,
    isStandingOutOfSaddle: false,
  ),
  rainDescent65Kmh(
    label: 'Zjazd w deszczu',
    speedKmh: 66.0,
    headwindKmh: 10.0,
    crosswindAngleDeg: -32.0,
    temperatureCelsius: 9.5,
    gradientPercent: -7.5,
    powerWatts: 115.0,
    cadenceRpm: 62.0,
    garmentType: GarmentOuterLayerType.rainShellJacket,
    isWearingRainJacket: true,
    isStandingOutOfSaddle: false,
  ),
  sprintFinish72Kmh(
    label: 'Finisz 72 km/h',
    speedKmh: 72.0,
    headwindKmh: 5.0,
    crosswindAngleDeg: 8.0,
    temperatureCelsius: 26.0,
    gradientPercent: 0.5,
    powerWatts: 1180.0,
    cadenceRpm: 112.0,
    garmentType: GarmentOuterLayerType.raceAeroJersey,
    isWearingRainJacket: false,
    isStandingOutOfSaddle: true,
  );

  final String label;
  final double speedKmh;
  final double headwindKmh;
  final double crosswindAngleDeg;
  final double temperatureCelsius;
  final double gradientPercent;
  final double powerWatts;
  final double cadenceRpm;
  final GarmentOuterLayerType garmentType;
  final bool isWearingRainJacket;
  final bool isStandingOutOfSaddle;

  const FabricFlutterConditionPreset({
    required this.label,
    required this.speedKmh,
    required this.headwindKmh,
    required this.crosswindAngleDeg,
    required this.temperatureCelsius,
    required this.gradientPercent,
    required this.powerWatts,
    required this.cadenceRpm,
    required this.garmentType,
    required this.isWearingRainJacket,
    required this.isStandingOutOfSaddle,
  });
}

/// Parametry fizyczne i progi animacji łopotania materiału oraz zamka koszulki.
class JerseyFabricFlutterConfig {
  /// Temperatura początkowa automatycznego rozpinania zamka podczas podjazdu [°C].
  final double heatUnzipStartCelsius;

  /// Temperatura pełnego rozpięcia zamka koszulki na piersi [°C].
  final double heatUnzipFullCelsius;

  /// Minimalne nachylenie podjazdu ułatwiające decyzję o rozpięciu zamka [%].
  final double climbGradientUnzipThresholdPercent;

  /// Prędkość powyżej której kolarz dopina zamek dla poprawy aerodynamiki [km/h].
  final double speedCloseZipperThresholdKmh;

  /// Minimalna częstotliwość drgań materiału na niskim wietrze [Hz].
  final double flutterBaseFrequencyHz;

  /// Maksymalna częstotliwość drgań materiału przy zjazdach i sprintach [Hz].
  final double flutterMaxFrequencyHz;

  /// Maksymalna amplituda drgań rękawków obcisłej koszulki [mm].
  final double maxJerseySleeveAmplitudeMm;

  /// Maksymalna amplituda łopotania luźnej kurtki przeciwdeszczowej [mm].
  final double maxRainJacketAmplitudeMm;

  /// Czy dodawać wyższe harmoniczne fali materiału (mikro-zmarszczki).
  final bool enableMicroHarmonics;

  /// Czy animować podskakiwanie suwaka zamka błyskawicznego na nierównościach i przy wietrze.
  final bool enableZipperPullBounce;

  const JerseyFabricFlutterConfig({
    this.heatUnzipStartCelsius = 24.5,
    this.heatUnzipFullCelsius = 33.5,
    this.climbGradientUnzipThresholdPercent = 5.0,
    this.speedCloseZipperThresholdKmh = 46.0,
    this.flutterBaseFrequencyHz = 7.5,
    this.flutterMaxFrequencyHz = 34.0,
    this.maxJerseySleeveAmplitudeMm = 6.5,
    this.maxRainJacketAmplitudeMm = 26.0,
    this.enableMicroHarmonics = true,
    this.enableZipperPullBounce = true,
  });
}

/// Dane wejściowe pojedynczej klatki 3D dla efektu odzieży i zamka kolarza.
class JerseyFabricFlutterFrameInput {
  final String riderId;
  final double speedKmh;
  final double headwindKmh;
  final double crosswindAngleRad;
  final double temperatureCelsius;
  final double gradientPercent;
  final double powerWatts;
  final double cadenceRpm;
  final GarmentOuterLayerType garmentType;
  final bool isWearingRainJacket;
  final bool isStandingOutOfSaddle;
  final double? manualZipperOverride;
  final Color teamPrimaryColor;
  final Color teamSecondaryColor;
  final Color skinToneColor;

  const JerseyFabricFlutterFrameInput({
    required this.riderId,
    required this.speedKmh,
    this.headwindKmh = 0.0,
    this.crosswindAngleRad = 0.0,
    required this.temperatureCelsius,
    required this.gradientPercent,
    required this.powerWatts,
    this.cadenceRpm = 88.0,
    this.garmentType = GarmentOuterLayerType.raceAeroJersey,
    this.isWearingRainJacket = false,
    this.isStandingOutOfSaddle = false,
    this.manualZipperOverride,
    this.teamPrimaryColor = AppColors.primaryAccent,
    this.teamSecondaryColor = AppColors.goldAccent,
    this.skinToneColor = const Color(0xFFD9A684),
  });

  factory JerseyFabricFlutterFrameInput.fromPreset(
    FabricFlutterConditionPreset preset, {
    String riderId = 'rider_01',
    double? manualZipperOverride,
  }) {
    return JerseyFabricFlutterFrameInput(
      riderId: riderId,
      speedKmh: preset.speedKmh,
      headwindKmh: preset.headwindKmh,
      crosswindAngleRad: preset.crosswindAngleDeg * math.pi / 180.0,
      temperatureCelsius: preset.temperatureCelsius,
      gradientPercent: preset.gradientPercent,
      powerWatts: preset.powerWatts,
      cadenceRpm: preset.cadenceRpm,
      garmentType: preset.garmentType,
      isWearingRainJacket: preset.isWearingRainJacket,
      isStandingOutOfSaddle: preset.isStandingOutOfSaddle,
      manualZipperOverride: manualZipperOverride,
    );
  }
}

/// Próbka fali łopotania dla pojedynczej strefy odzieży (rękawek, peleryna, brzeg).
class SleeveFlutterSample {
  final FabricFlutterZone zone;
  final double amplitudeMm;
  final double frequencyHz;
  final double phaseRad;

  /// Przesunięcia fali dla 4 węzłów wzdłuż krawędzi materiału [mm].
  final List<double> crestOffsetsMm;

  /// Znormalizowana intensywność łopotania (0.0 .. 1.0).
  final double flutterIntensity;

  const SleeveFlutterSample({
    required this.zone,
    required this.amplitudeMm,
    required this.frequencyHz,
    required this.phaseRad,
    required this.crestOffsetsMm,
    required this.flutterIntensity,
  });
}

/// Stan rozpięcia zamka koszulki na piersi kolarza.
class ZipperOpeningState {
  /// Stopień rozpięcia zamka: 0.0 (zapięty pod szyję) .. 1.0 (rozpięty do mostka/brzucha).
  final double unzippedRatio;

  /// Długość pionowego rozpięcia [cm].
  final double openingLengthCm;

  /// Szerokość rozchylenia klap na wysokości klatki piersiowej [cm].
  final double openingWidthCm;

  /// Widoczność odsłoniętej skóry / potówki pod koszulką (0.0 .. 1.0).
  final double chestSkinExposureRatio;

  /// Kąt odchylenia lewej i prawej klapy rozpiętej koszulki na wietrze [stopnie].
  final double leftLapelFlapAngleDeg;
  final double rightLapelFlapAngleDeg;

  /// Pionowe i poziome drganie suwaka zamka [mm].
  final double zipperPullOscillationMm;

  /// Czy zamek został automatycznie rozpięty z powodu upalnej wspinaczki.
  final bool isAutoUnzippedForHeatClimb;

  /// Czytelny opis przyczyny aktualnego stanu zamka.
  final String reasonLabel;

  const ZipperOpeningState({
    required this.unzippedRatio,
    required this.openingLengthCm,
    required this.openingWidthCm,
    required this.chestSkinExposureRatio,
    required this.leftLapelFlapAngleDeg,
    required this.rightLapelFlapAngleDeg,
    required this.zipperPullOscillationMm,
    required this.isAutoUnzippedForHeatClimb,
    required this.reasonLabel,
  });
}

/// Zbiorczy stan efektów odzieży i zamka kolarza dla danej klatki 3D.
class JerseyFabricFlutterState {
  final String riderId;
  final GarmentOuterLayerType effectiveGarmentType;
  final double apparentAirspeedKmh;
  final double dynamicPressurePa;
  final SleeveFlutterSample leftSleeve;
  final SleeveFlutterSample rightSleeve;
  final SleeveFlutterSample rainJacketCape;
  final SleeveFlutterSample rearHem;
  final ZipperOpeningState zipperState;
  final double overallFlutterScore;
  final double aeroDragPenaltyWatts;
  final double elapsedSeconds;

  const JerseyFabricFlutterState({
    required this.riderId,
    required this.effectiveGarmentType,
    required this.apparentAirspeedKmh,
    required this.dynamicPressurePa,
    required this.leftSleeve,
    required this.rightSleeve,
    required this.rainJacketCape,
    required this.rearHem,
    required this.zipperState,
    required this.overallFlutterScore,
    required this.aeroDragPenaltyWatts,
    required this.elapsedSeconds,
  });
}

/// Silnik fizyki i animacji 3D łopotania rękawków, kurtki przeciwdeszczowej oraz zamka koszulki.
class JerseyZipperAndFabricFlutterFx {
  final JerseyFabricFlutterConfig config;

  final Map<String, double> _smoothedZipperByRider = <String, double>{};
  final Map<String, double> _smoothedFlutterByRider = <String, double>{};

  JerseyZipperAndFabricFlutterFx({
    this.config = const JerseyFabricFlutterConfig(),
  });

  /// Resetuje wygładzone stany czasowe (np. przy starcie nowego etapu).
  void reset() {
    _smoothedZipperByRider.clear();
    _smoothedFlutterByRider.clear();
  }

  /// Oblicza deterministyczny stan klatki bez mutacji buforów (przydatne w testach i podglądzie).
  JerseyFabricFlutterState evaluateFrame({
    required JerseyFabricFlutterFrameInput input,
    required double elapsedSeconds,
  }) {
    final double speedMs = math.max(0.0, input.speedKmh) / 3.6;
    final double headwindMs = input.headwindKmh / 3.6;
    final double crosswindFactor = math.sin(input.crosswindAngleRad);
    final double apparentAirspeedMs = math.max(
      0.0,
      math.sqrt(
        math.pow(speedMs + headwindMs * math.cos(input.crosswindAngleRad), 2) +
            math.pow(headwindMs * crosswindFactor, 2),
      ),
    );
    final double apparentAirspeedKmh = apparentAirspeedMs * 3.6;

    // Ciśnienie dynamiczne q = 0.5 * rho * v^2 (rho = 1.225 kg/m^3).
    final double dynamicPressurePa = 0.5 * 1.225 * apparentAirspeedMs * apparentAirspeedMs;

    final GarmentOuterLayerType effectiveGarment = input.isWearingRainJacket
        ? GarmentOuterLayerType.rainShellJacket
        : input.garmentType;

    final double targetZipper = _computeTargetZipperRatio(
      input: input,
      effectiveGarment: effectiveGarment,
    );

    final double seedPhase = _riderPhaseSeed(input.riderId);

    return _buildState(
      input: input,
      effectiveGarment: effectiveGarment,
      apparentAirspeedKmh: apparentAirspeedKmh,
      dynamicPressurePa: dynamicPressurePa,
      zipperRatio: targetZipper,
      elapsedSeconds: elapsedSeconds,
      seedPhase: seedPhase,
      smoothingFactor: 1.0,
    );
  }

  /// Aktualizuje stan kolarza w pętli symulacji 60–120 FPS z płynnym wygładzaniem zamka i materiału.
  JerseyFabricFlutterState step({
    required JerseyFabricFlutterFrameInput input,
    required double dtSeconds,
    required double elapsedSeconds,
  }) {
    final double clampedDt = dtSeconds.clamp(0.0, 0.25);
    final double speedMs = math.max(0.0, input.speedKmh) / 3.6;
    final double headwindMs = input.headwindKmh / 3.6;
    final double crosswindFactor = math.sin(input.crosswindAngleRad);
    final double apparentAirspeedMs = math.max(
      0.0,
      math.sqrt(
        math.pow(speedMs + headwindMs * math.cos(input.crosswindAngleRad), 2) +
            math.pow(headwindMs * crosswindFactor, 2),
      ),
    );
    final double apparentAirspeedKmh = apparentAirspeedMs * 3.6;
    final double dynamicPressurePa = 0.5 * 1.225 * apparentAirspeedMs * apparentAirspeedMs;

    final GarmentOuterLayerType effectiveGarment = input.isWearingRainJacket
        ? GarmentOuterLayerType.rainShellJacket
        : input.garmentType;

    final double targetZipper = _computeTargetZipperRatio(
      input: input,
      effectiveGarment: effectiveGarment,
    );

    final double prevZipper = _smoothedZipperByRider[input.riderId] ?? targetZipper;
    final double zipperAlpha = 1.0 - math.exp(-clampedDt * 3.2);
    final double smoothedZipper = (prevZipper + (targetZipper - prevZipper) * zipperAlpha).clamp(0.0, 1.0);
    _smoothedZipperByRider[input.riderId] = smoothedZipper;

    final double airNorm = (apparentAirspeedKmh / 75.0).clamp(0.0, 1.0);
    final double prevFlutter = _smoothedFlutterByRider[input.riderId] ?? airNorm;
    final double flutterAlpha = 1.0 - math.exp(-clampedDt * 8.0);
    final double smoothedFlutter = (prevFlutter + (airNorm - prevFlutter) * flutterAlpha).clamp(0.0, 1.0);
    _smoothedFlutterByRider[input.riderId] = smoothedFlutter;

    return _buildState(
      input: input,
      effectiveGarment: effectiveGarment,
      apparentAirspeedKmh: apparentAirspeedKmh,
      dynamicPressurePa: dynamicPressurePa,
      zipperRatio: smoothedZipper,
      elapsedSeconds: elapsedSeconds,
      seedPhase: _riderPhaseSeed(input.riderId),
      smoothingFactor: (0.4 + 0.6 * (smoothedFlutter / math.max(0.001, airNorm))).clamp(0.5, 1.2),
    );
  }

  double _computeTargetZipperRatio({
    required JerseyFabricFlutterFrameInput input,
    required GarmentOuterLayerType effectiveGarment,
  }) {
    if (!effectiveGarment.supportsZipperUnzip || input.isWearingRainJacket) {
      return 0.0;
    }
    if (input.manualZipperOverride != null) {
      return input.manualZipperOverride!.clamp(0.0, 1.0);
    }

    // Na szybkich zjazdach lub sprintach kolarze zapinają koszulkę ze względu na aerodynamikę.
    if (input.speedKmh >= config.speedCloseZipperThresholdKmh) {
      return 0.0;
    }

    final double tempSpan = math.max(
      1.0,
      config.heatUnzipFullCelsius - config.heatUnzipStartCelsius,
    );
    final double heatFactor =
        ((input.temperatureCelsius - config.heatUnzipStartCelsius) / tempSpan).clamp(0.0, 1.0);

    if (heatFactor <= 0.0) {
      return 0.0;
    }

    // Wspinaczka przy niskiej prędkości i wysokiej mocy mocno podnosi potrzebę chłodzenia.
    final double gradientBonus = input.gradientPercent >= config.climbGradientUnzipThresholdPercent
        ? ((input.gradientPercent - config.climbGradientUnzipThresholdPercent) / 7.0).clamp(0.0, 0.35)
        : 0.0;
    final double lowSpeedCoolingNeed = input.speedKmh < 26.0
        ? ((26.0 - input.speedKmh) / 14.0).clamp(0.0, 0.25)
        : 0.0;
    final double effortBonus = input.powerWatts > 330.0
        ? ((input.powerWatts - 330.0) / 220.0).clamp(0.0, 0.20)
        : 0.0;

    // Jeżeli jedzie na płaskim w umiarkowanym upale (>40 km/h), rozpięcie jest mniejsze niż na podjeździe.
    final double speedSuppression = input.speedKmh > 34.0
        ? ((input.speedKmh - 34.0) / (config.speedCloseZipperThresholdKmh - 34.0)).clamp(0.0, 0.85)
        : 0.0;

    final double rawOpen =
        (heatFactor * 0.72 + gradientBonus + lowSpeedCoolingNeed + effortBonus) *
            (1.0 - speedSuppression);

    return rawOpen.clamp(0.0, 1.0);
  }

  JerseyFabricFlutterState _buildState({
    required JerseyFabricFlutterFrameInput input,
    required GarmentOuterLayerType effectiveGarment,
    required double apparentAirspeedKmh,
    required double dynamicPressurePa,
    required double zipperRatio,
    required double elapsedSeconds,
    required double seedPhase,
    required double smoothingFactor,
  }) {
    final double airFactor = (apparentAirspeedKmh / 65.0).clamp(0.0, 1.25);
    final double baseFreq = (config.flutterBaseFrequencyHz + apparentAirspeedKmh * 0.34)
        .clamp(config.flutterBaseFrequencyHz, config.flutterMaxFrequencyHz);

    final double crosswindSin = math.sin(input.crosswindAngleRad);
    // Wiatr z lewej strony mocniej wzbudza lewy rękawek (i odwrotnie).
    final double leftWindGain = (1.0 + math.max(0.0, crosswindSin) * 0.42).clamp(0.75, 1.45);
    final double rightWindGain = (1.0 + math.max(0.0, -crosswindSin) * 0.42).clamp(0.75, 1.45);

    final double baseSleeveAmp = effectiveGarment == GarmentOuterLayerType.rainShellJacket
        ? config.maxRainJacketAmplitudeMm * 0.72
        : config.maxJerseySleeveAmplitudeMm * (0.45 + 0.85 * effectiveGarment.loosenessFactor);

    final double cadenceMicroPump =
        1.0 + 0.06 * math.sin(elapsedSeconds * (input.cadenceRpm / 60.0) * 2.0 * math.pi);

    final SleeveFlutterSample leftSleeve = _buildWaveSample(
      zone: FabricFlutterZone.leftSleeve,
      baseAmplitudeMm: baseSleeveAmp * airFactor * leftWindGain * cadenceMicroPump * smoothingFactor,
      frequencyHz: baseFreq * (1.0 + 0.08 * crosswindSin),
      elapsedSeconds: elapsedSeconds,
      phaseOffset: seedPhase + 0.4,
      maxRefMm: config.maxRainJacketAmplitudeMm,
    );

    final SleeveFlutterSample rightSleeve = _buildWaveSample(
      zone: FabricFlutterZone.rightSleeve,
      baseAmplitudeMm: baseSleeveAmp * airFactor * rightWindGain * cadenceMicroPump * smoothingFactor,
      frequencyHz: baseFreq * (1.0 - 0.08 * crosswindSin),
      elapsedSeconds: elapsedSeconds,
      phaseOffset: seedPhase + 2.15,
      maxRefMm: config.maxRainJacketAmplitudeMm,
    );

    final double capeBaseAmp = effectiveGarment == GarmentOuterLayerType.rainShellJacket
        ? config.maxRainJacketAmplitudeMm * airFactor * (1.0 + 0.25 * crosswindSin.abs())
        : config.maxJerseySleeveAmplitudeMm * 0.28 * effectiveGarment.loosenessFactor * airFactor;

    final SleeveFlutterSample rainJacketCape = _buildWaveSample(
      zone: FabricFlutterZone.rainJacketCape,
      baseAmplitudeMm: capeBaseAmp * smoothingFactor,
      frequencyHz: baseFreq * 0.78,
      elapsedSeconds: elapsedSeconds,
      phaseOffset: seedPhase + 3.7,
      maxRefMm: config.maxRainJacketAmplitudeMm,
    );

    final double rearHemAmp =
        (effectiveGarment == GarmentOuterLayerType.rainShellJacket ? 16.0 : 4.2) *
            effectiveGarment.loosenessFactor *
            airFactor;

    final SleeveFlutterSample rearHem = _buildWaveSample(
      zone: FabricFlutterZone.rearHemTail,
      baseAmplitudeMm: rearHemAmp * smoothingFactor,
      frequencyHz: baseFreq * 0.90,
      elapsedSeconds: elapsedSeconds,
      phaseOffset: seedPhase + 5.05,
      maxRefMm: config.maxRainJacketAmplitudeMm,
    );

    final ZipperOpeningState zipperState = _buildZipperState(
      input: input,
      effectiveGarment: effectiveGarment,
      zipperRatio: zipperRatio,
      apparentAirspeedKmh: apparentAirspeedKmh,
      baseFreq: baseFreq,
      elapsedSeconds: elapsedSeconds,
      seedPhase: seedPhase,
      crosswindSin: crosswindSin,
    );

    final double overallFlutterScore = ((leftSleeve.flutterIntensity +
                rightSleeve.flutterIntensity +
                rainJacketCape.flutterIntensity * 1.35) /
            3.35)
        .clamp(0.0, 1.0);

    // Realistyczna kara aerodynamiczna w watach: luźna kurtka i rozpięty zamek zwiększają CdA.
    final double speedCubedFactor = math.pow(math.max(0.0, apparentAirspeedKmh) / 40.0, 3).toDouble();
    final double rainJacketDragW = effectiveGarment == GarmentOuterLayerType.rainShellJacket
        ? 19.5 * speedCubedFactor
        : 2.2 * effectiveGarment.loosenessFactor * speedCubedFactor;
    final double openZipperDragW = zipperRatio * 11.5 * speedCubedFactor;
    final double aeroDragPenaltyWatts = rainJacketDragW + openZipperDragW;

    return JerseyFabricFlutterState(
      riderId: input.riderId,
      effectiveGarmentType: effectiveGarment,
      apparentAirspeedKmh: apparentAirspeedKmh,
      dynamicPressurePa: dynamicPressurePa,
      leftSleeve: leftSleeve,
      rightSleeve: rightSleeve,
      rainJacketCape: rainJacketCape,
      rearHem: rearHem,
      zipperState: zipperState,
      overallFlutterScore: overallFlutterScore,
      aeroDragPenaltyWatts: aeroDragPenaltyWatts,
      elapsedSeconds: elapsedSeconds,
    );
  }

  SleeveFlutterSample _buildWaveSample({
    required FabricFlutterZone zone,
    required double baseAmplitudeMm,
    required double frequencyHz,
    required double elapsedSeconds,
    required double phaseOffset,
    required double maxRefMm,
  }) {
    final double safeAmp = math.max(0.0, baseAmplitudeMm);
    final double omega = 2.0 * math.pi * frequencyHz;
    final double phase = omega * elapsedSeconds + phaseOffset;

    final List<double> crests = List<double>.generate(4, (int i) {
      final double nodeDelay = i * 0.85;
      final double primary = math.sin(phase - nodeDelay);
      final double harmonic = config.enableMicroHarmonics
          ? 0.34 * math.sin(phase * 2.15 - nodeDelay * 1.45 + 0.7)
          : 0.0;
      final double taper = 0.45 + 0.18 * i;
      return safeAmp * taper * (primary + harmonic) / 1.34;
    }, growable: false);

    final double intensity = (safeAmp / math.max(1.0, maxRefMm)).clamp(0.0, 1.0);

    return SleeveFlutterSample(
      zone: zone,
      amplitudeMm: safeAmp,
      frequencyHz: frequencyHz,
      phaseRad: phase % (2.0 * math.pi),
      crestOffsetsMm: crests,
      flutterIntensity: intensity,
    );
  }

  ZipperOpeningState _buildZipperState({
    required JerseyFabricFlutterFrameInput input,
    required GarmentOuterLayerType effectiveGarment,
    required double zipperRatio,
    required double apparentAirspeedKmh,
    required double baseFreq,
    required double elapsedSeconds,
    required double seedPhase,
    required double crosswindSin,
  }) {
    final double openingLengthCm = zipperRatio * 28.0;
    final double airSpreadFactor = 1.0 + (apparentAirspeedKmh / 60.0).clamp(0.0, 0.45);
    final double openingWidthCm = zipperRatio * 8.4 * airSpreadFactor;
    final double chestSkinExposureRatio = (zipperRatio * 0.92).clamp(0.0, 1.0);

    final double lapelFlutterWave =
        math.sin(2.0 * math.pi * (baseFreq * 0.85) * elapsedSeconds + seedPhase + 1.1);
    final double baseLapelAngle = zipperRatio * (14.0 + (apparentAirspeedKmh * 0.42).clamp(0.0, 24.0));
    final double leftLapelAngle =
        (baseLapelAngle * (1.0 + 0.25 * lapelFlutterWave + 0.15 * crosswindSin)).clamp(0.0, 62.0);
    final double rightLapelAngle =
        (baseLapelAngle * (1.0 - 0.25 * lapelFlutterWave - 0.15 * crosswindSin)).clamp(0.0, 62.0);

    final double pullBounce = config.enableZipperPullBounce && zipperRatio > 0.04
        ? math.sin(2.0 * math.pi * (baseFreq * 1.35) * elapsedSeconds + seedPhase) *
            (1.2 + 3.4 * (apparentAirspeedKmh / 50.0).clamp(0.0, 1.0)) *
            (0.4 + 0.6 * zipperRatio)
        : 0.0;

    final bool isAutoHeatClimb = !input.isWearingRainJacket &&
        input.manualZipperOverride == null &&
        zipperRatio > 0.12 &&
        input.temperatureCelsius >= config.heatUnzipStartCelsius;

    final String reasonLabel;
    if (input.isWearingRainJacket || !effectiveGarment.supportsZipperUnzip) {
      reasonLabel = 'Kurtka przeciwdeszczowa — zamek szczelnie zamknięty';
    } else if (input.manualZipperOverride != null) {
      reasonLabel = zipperRatio > 0.05
          ? 'Ręczne rozpięcie (${(zipperRatio * 100).round()}%)'
          : 'Ręcznie dopięta pod szyję';
    } else if (input.speedKmh >= config.speedCloseZipperThresholdKmh) {
      reasonLabel = 'Pozycja aero (> ${config.speedCloseZipperThresholdKmh.round()} km/h) — dopięta';
    } else if (isAutoHeatClimb) {
      reasonLabel =
          'Wspinaczka w upale (${input.temperatureCelsius.toStringAsFixed(1)}°C) — chłodzenie klatki';
    } else {
      reasonLabel = 'Standardowe zapięcie';
    }

    return ZipperOpeningState(
      unzippedRatio: zipperRatio,
      openingLengthCm: openingLengthCm,
      openingWidthCm: openingWidthCm,
      chestSkinExposureRatio: chestSkinExposureRatio,
      leftLapelFlapAngleDeg: leftLapelAngle,
      rightLapelFlapAngleDeg: rightLapelAngle,
      zipperPullOscillationMm: pullBounce,
      isAutoUnzippedForHeatClimb: isAutoHeatClimb,
      reasonLabel: reasonLabel,
    );
  }

  double _riderPhaseSeed(String riderId) {
    int hash = 0;
    for (int i = 0; i < riderId.length; i++) {
      hash = (hash * 31 + riderId.codeUnitAt(i)) & 0x7fffffff;
    }
    return (hash % 628) / 100.0;
  }
}

/// Painter 2D/3D prezentujący kolarza z falującymi rękawkami, kurtką przeciwdeszczową i zamkiem na piersi.
class JerseyZipperAndFabricFlutterPainter extends CustomPainter {
  final JerseyFabricFlutterState state;
  final Color teamPrimaryColor;
  final Color teamSecondaryColor;
  final Color skinToneColor;
  final double crosswindAngleRad;

  const JerseyZipperAndFabricFlutterPainter({
    required this.state,
    this.teamPrimaryColor = AppColors.primaryAccent,
    this.teamSecondaryColor = AppColors.goldAccent,
    this.skinToneColor = const Color(0xFFD9A684),
    this.crosswindAngleRad = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final Rect bounds = Offset.zero & size;
    _drawBackdrop(canvas, bounds);
    _drawWindStreamlines(canvas, size);

    final double cx = size.width * 0.50;
    final double cy = size.height * 0.55;
    final double scale = math.min(size.width / 260.0, size.height / 240.0);

    final bool isRainJacket =
        state.effectiveGarmentType == GarmentOuterLayerType.rainShellJacket;

    final Color garmentBaseColor = isRainJacket
        ? const Color(0xFF1F2937)
        : teamPrimaryColor;
    final Color garmentHighlightColor = isRainJacket
        ? const Color(0xFF4B5563)
        : Color.lerp(teamPrimaryColor, Colors.white, 0.18)!;

    // 1. Peleryna kurtki przeciwdeszczowej za plecami / ramionami (gdy założona).
    if (isRainJacket) {
      _drawRainJacketCape(canvas, cx, cy, scale);
    }

    // 2. Rękawki koszulki lub długie rękawy kurtki z animowanym łopotaniem krawędzi.
    _drawFlutteringSleeve(
      canvas: canvas,
      cx: cx,
      cy: cy,
      scale: scale,
      isLeft: true,
      sample: state.leftSleeve,
      garmentColor: garmentBaseColor,
      accentColor: teamSecondaryColor,
      isRainJacket: isRainJacket,
    );
    _drawFlutteringSleeve(
      canvas: canvas,
      cx: cx,
      cy: cy,
      scale: scale,
      isLeft: false,
      sample: state.rightSleeve,
      garmentColor: garmentBaseColor,
      accentColor: teamSecondaryColor,
      isRainJacket: isRainJacket,
    );

    // 3. Korpus koszulki / kurtki + pasy drużynowe + łopoczący dolny brzeg.
    _drawTorsoShell(
      canvas: canvas,
      cx: cx,
      cy: cy,
      scale: scale,
      garmentColor: garmentBaseColor,
      highlightColor: garmentHighlightColor,
      accentColor: teamSecondaryColor,
      isRainJacket: isRainJacket,
    );

    // 4. Widoczne rozpięcie zamka na piersi (V-neck, skóra/potówka, klapy i suwak).
    _drawChestZipper(
      canvas: canvas,
      cx: cx,
      cy: cy,
      scale: scale,
      garmentColor: garmentBaseColor,
      accentColor: teamSecondaryColor,
      isRainJacket: isRainJacket,
    );

    // 5. Szyja, głowa i kask aero dla kontekstu sylwetki kolarza.
    _drawHeadAndHelmet(canvas, cx, cy, scale, teamSecondaryColor);
  }

  void _drawBackdrop(Canvas canvas, Rect bounds) {
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF131720),
          Color(0xFF0F1115),
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, bgPaint);

    // Subtelna siatka telemetryczna w tle.
    final Paint gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    const double step = 28.0;
    for (double x = step; x < bounds.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, bounds.height), gridPaint);
    }
    for (double y = step; y < bounds.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(bounds.width, y), gridPaint);
    }
  }

  void _drawWindStreamlines(Canvas canvas, Size size) {
    final double speedNorm = (state.apparentAirspeedKmh / 70.0).clamp(0.15, 1.0);
    final Paint linePaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.14 + 0.22 * speedNorm)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double flowTravel = (state.elapsedSeconds * (60.0 + state.apparentAirspeedKmh * 3.2)) %
        (size.width + 120.0);
    final double crossTilt = math.sin(crosswindAngleRad) * 18.0;

    for (int i = 0; i < 6; i++) {
      final double yBase = size.height * (0.14 + i * 0.14);
      final double xStart = ((flowTravel + i * 73.0) % (size.width + 100.0)) - 60.0;
      final double len = 34.0 + 36.0 * speedNorm;
      final Path p = Path()
        ..moveTo(xStart, yBase)
        ..quadraticBezierTo(
          xStart + len * 0.5,
          yBase + crossTilt * 0.5 + math.sin(state.elapsedSeconds * 5.0 + i) * 3.5,
          xStart + len,
          yBase + crossTilt,
        );
      canvas.drawPath(p, linePaint);
    }
  }

  void _drawRainJacketCape(Canvas canvas, double cx, double cy, double scale) {
    final List<double> c = state.rainJacketCape.crestOffsetsMm;
    final double flutterPx = scale * 0.65;

    final Path capePath = Path()
      ..moveTo(cx - 56 * scale, cy - 34 * scale)
      ..quadraticBezierTo(
        cx - 72 * scale + c[0] * flutterPx,
        cy + 4 * scale,
        cx - 62 * scale + c[1] * flutterPx,
        cy + 58 * scale + c[2] * 0.35 * flutterPx,
      )
      ..quadraticBezierTo(
        cx,
        cy + 66 * scale + c[2] * 0.5 * flutterPx,
        cx + 62 * scale + c[3] * flutterPx,
        cy + 58 * scale + c[1] * 0.35 * flutterPx,
      )
      ..quadraticBezierTo(
        cx + 72 * scale + c[2] * flutterPx,
        cy + 4 * scale,
        cx + 56 * scale,
        cy - 34 * scale,
      )
      ..close();

    final Paint capePaint = Paint()
      ..color = const Color(0xFF111827).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    final Paint capeBorder = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.45)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    canvas.drawPath(capePath, capePaint);
    canvas.drawPath(capePath, capeBorder);
  }

  void _drawFlutteringSleeve({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double scale,
    required bool isLeft,
    required SleeveFlutterSample sample,
    required Color garmentColor,
    required Color accentColor,
    required bool isRainJacket,
  }) {
    final double dir = isLeft ? -1.0 : 1.0;
    final double sleeveLen = (isRainJacket ? 78.0 : 48.0) * scale;
    final double flutterPx = scale * 0.58;
    final List<double> c = sample.crestOffsetsMm;

    final Offset shoulderTop = Offset(cx + dir * 42 * scale, cy - 42 * scale);
    final Offset shoulderBot = Offset(cx + dir * 36 * scale, cy - 12 * scale);
    final Offset cuffTop = Offset(
      cx + dir * (42 * scale + sleeveLen * 0.78) + c[0] * 0.45 * flutterPx,
      cy - 18 * scale + (isRainJacket ? 28.0 * scale : 10.0 * scale) + c[1] * flutterPx,
    );
    final Offset cuffBot = Offset(
      cx + dir * (36 * scale + sleeveLen * 0.62) + c[2] * 0.45 * flutterPx,
      cy + 8 * scale + (isRainJacket ? 32.0 * scale : 12.0 * scale) + c[3] * flutterPx,
    );

    // Ramię (skóra), jeśli to krótki rękawek koszulki.
    if (!isRainJacket) {
      final Paint armPaint = Paint()
        ..color = skinToneColor
        ..strokeWidth = 15.0 * scale
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        cuffTop.translate(-dir * 4 * scale, 6 * scale),
        Offset(cx + dir * 82 * scale, cy + 44 * scale),
        armPaint,
      );
    }

    final Path sleevePath = Path()
      ..moveTo(shoulderTop.dx, shoulderTop.dy)
      ..quadraticBezierTo(
        (shoulderTop.dx + cuffTop.dx) * 0.5 + c[0] * 0.4 * flutterPx,
        (shoulderTop.dy + cuffTop.dy) * 0.5 + c[1] * 0.7 * flutterPx,
        cuffTop.dx,
        cuffTop.dy,
      )
      ..quadraticBezierTo(
        (cuffTop.dx + cuffBot.dx) * 0.5 + c[2] * 0.5 * flutterPx,
        (cuffTop.dy + cuffBot.dy) * 0.5,
        cuffBot.dx,
        cuffBot.dy,
      )
      ..quadraticBezierTo(
        (shoulderBot.dx + cuffBot.dx) * 0.5 + c[3] * 0.55 * flutterPx,
        (shoulderBot.dy + cuffBot.dy) * 0.5 + c[2] * 0.85 * flutterPx,
        shoulderBot.dx,
        shoulderBot.dy,
      )
      ..close();

    final Paint sleevePaint = Paint()
      ..color = Color.lerp(garmentColor, Colors.black, 0.12)!
      ..style = PaintingStyle.fill;
    canvas.drawPath(sleevePath, sleevePaint);

    // Ściągacz / pasek akcentowy na końcu rękawka.
    final Paint cuffBand = Paint()
      ..color = isRainJacket ? AppColors.accentBlue : accentColor
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(cuffTop, cuffBot, cuffBand);

    // Subtelne fałdy falowania materiału wewnątrz rękawka.
    if (sample.flutterIntensity > 0.18) {
      final Paint foldPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16 * sample.flutterIntensity)
        ..strokeWidth = 1.2 * scale
        ..style = PaintingStyle.stroke;
      final Offset midShoulder = Offset.lerp(shoulderTop, shoulderBot, 0.5)!;
      final Offset midCuff = Offset.lerp(cuffTop, cuffBot, 0.5)!;
      canvas.drawLine(midShoulder, midCuff, foldPaint);
    }
  }

  void _drawTorsoShell({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double scale,
    required Color garmentColor,
    required Color highlightColor,
    required Color accentColor,
    required bool isRainJacket,
  }) {
    final List<double> hemCrests = state.rearHem.crestOffsetsMm;
    final double hemFlutterPx = scale * 0.45;

    final Path torsoPath = Path()
      ..moveTo(cx - 43 * scale, cy - 42 * scale)
      ..lineTo(cx + 43 * scale, cy - 42 * scale)
      ..quadraticBezierTo(
        cx + 44 * scale,
        cy + 8 * scale,
        cx + 35 * scale + hemCrests[0] * 0.2 * hemFlutterPx,
        cy + 62 * scale + hemCrests[1] * 0.4 * hemFlutterPx,
      )
      ..quadraticBezierTo(
        cx,
        cy + 67 * scale + hemCrests[2] * 0.5 * hemFlutterPx,
        cx - 35 * scale + hemCrests[3] * 0.2 * hemFlutterPx,
        cy + 62 * scale + hemCrests[0] * 0.4 * hemFlutterPx,
      )
      ..quadraticBezierTo(
        cx - 44 * scale,
        cy + 8 * scale,
        cx - 43 * scale,
        cy - 42 * scale,
      )
      ..close();

    final Paint torsoPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[highlightColor, garmentColor],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 96 * scale, height: 112 * scale));

    canvas.drawPath(torsoPath, torsoPaint);

    // Pasek drużynowy w poprzek klatki piersiowej.
    final Paint stripePaint = Paint()
      ..color = isRainJacket
          ? AppColors.accentBlue.withValues(alpha: 0.72)
          : accentColor.withValues(alpha: 0.90);
    canvas.drawRect(
      Rect.fromLTWH(cx - 39 * scale, cy + 4 * scale, 78 * scale, 13 * scale),
      stripePaint,
    );

    // Pasek odblaskowy / obrys.
    final Paint borderPaint = Paint()
      ..color = isRainJacket
          ? AppColors.accentBlue.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(torsoPath, borderPaint);
  }

  void _drawChestZipper({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double scale,
    required Color garmentColor,
    required Color accentColor,
    required bool isRainJacket,
  }) {
    final ZipperOpeningState z = state.zipperState;
    final double topY = cy - 42 * scale;
    final double fullZipEndY = cy + 54 * scale;
    final double openEndY = topY + z.unzippedRatio * (fullZipEndY - topY);

    // Zamknięty dolny odcinek zamka.
    final Paint closedZipPaint = Paint()
      ..color = isRainJacket ? AppColors.accentBlue : const Color(0xFFD1D5DB)
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, openEndY),
      Offset(cx, fullZipEndY),
      closedZipPaint,
    );

    // Rozpięte V na piersi kolarza.
    if (z.unzippedRatio > 0.03) {
      final double halfWidth = (2.0 + 18.0 * z.unzippedRatio) * scale;
      final double leftSpread = halfWidth * (1.0 + z.leftLapelFlapAngleDeg / 90.0);
      final double rightSpread = halfWidth * (1.0 + z.rightLapelFlapAngleDeg / 90.0);

      // Odsłonięta klatka piersiowa (skóra + lekka biała siateczka potówki na brzegach).
      final Path chestSkinPath = Path()
        ..moveTo(cx - leftSpread, topY)
        ..lineTo(cx + rightSpread, topY)
        ..lineTo(cx, openEndY)
        ..close();

      final Paint skinPaint = Paint()..color = skinToneColor;
      canvas.drawPath(chestSkinPath, skinPaint);

      // Subtelny cień mostka wewnątrz rozpięcia.
      final Paint sternumShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..strokeWidth = 1.4 * scale;
      canvas.drawLine(
        Offset(cx, topY + 6 * scale),
        Offset(cx, math.max(topY + 6 * scale, openEndY - 6 * scale)),
        sternumShadow,
      );

      // Wywinięte klapy materiału łopoczące po bokach rozpięcia.
      final Paint lapelPaint = Paint()
        ..color = Color.lerp(garmentColor, Colors.white, 0.28)!
        ..style = PaintingStyle.fill;

      final Path leftLapel = Path()
        ..moveTo(cx - leftSpread, topY)
        ..lineTo(cx - leftSpread - (4.5 + z.leftLapelFlapAngleDeg * 0.12) * scale, topY + 7 * scale)
        ..lineTo(cx, openEndY)
        ..close();
      final Path rightLapel = Path()
        ..moveTo(cx + rightSpread, topY)
        ..lineTo(cx + rightSpread + (4.5 + z.rightLapelFlapAngleDeg * 0.12) * scale, topY + 7 * scale)
        ..lineTo(cx, openEndY)
        ..close();

      canvas.drawPath(leftLapel, lapelPaint);
      canvas.drawPath(rightLapel, lapelPaint);

      // Ząbki rozpiętego zamka na krawędziach.
      final Paint teethPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.85)
        ..strokeWidth = 1.3 * scale
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx - leftSpread, topY), Offset(cx, openEndY), teethPaint);
      canvas.drawLine(Offset(cx + rightSpread, topY), Offset(cx, openEndY), teethPaint);
    }

    // Suwak zamka (zipper puller) z podskakiwaniem na wietrze.
    final double pullX = cx + z.zipperPullOscillationMm * 0.35 * scale;
    final double pullY = openEndY + z.zipperPullOscillationMm.abs() * 0.25 * scale;
    final Paint pullPaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pullX, pullY + 3.5 * scale), width: 4.4 * scale, height: 7.0 * scale),
        Radius.circular(1.5 * scale),
      ),
      pullPaint,
    );
  }

  void _drawHeadAndHelmet(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    Color accentColor,
  ) {
    // Szyja
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - 49 * scale), width: 18 * scale, height: 16 * scale),
      Paint()..color = skinToneColor,
    );

    // Głowa
    canvas.drawCircle(
      Offset(cx, cy - 68 * scale),
      17 * scale,
      Paint()..color = skinToneColor,
    );

    // Okulary kolarskie
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 68 * scale), width: 28 * scale, height: 9 * scale),
        Radius.circular(3.5 * scale),
      ),
      Paint()..color = const Color(0xFF111827),
    );

    // Kask aero
    final Path helmetPath = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(cx, cy - 73 * scale), width: 38 * scale, height: 30 * scale),
        math.pi,
        math.pi,
      )
      ..close();
    canvas.drawPath(helmetPath, Paint()..color = AppColors.textPrimary);
    canvas.drawPath(
      helmetPath,
      Paint()
        ..color = accentColor
        ..strokeWidth = 2.0 * scale
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant JerseyZipperAndFabricFlutterPainter oldDelegate) {
    return oldDelegate.state.elapsedSeconds != state.elapsedSeconds ||
        oldDelegate.state.apparentAirspeedKmh != state.apparentAirspeedKmh ||
        oldDelegate.state.zipperState.unzippedRatio != state.zipperState.unzippedRatio ||
        oldDelegate.state.effectiveGarmentType != state.effectiveGarmentType ||
        oldDelegate.teamPrimaryColor != teamPrimaryColor;
  }
}

/// Responsywny panel podglądu i sterowania efektami łopotania odzieży oraz zamka koszulki.
class JerseyZipperAndFabricFlutterPanel extends StatefulWidget {
  final FabricFlutterConditionPreset initialPreset;
  final JerseyFabricFlutterConfig config;
  final ValueChanged<JerseyFabricFlutterState>? onStateChanged;

  const JerseyZipperAndFabricFlutterPanel({
    super.key,
    this.initialPreset = FabricFlutterConditionPreset.alpineHeatClimb,
    this.config = const JerseyFabricFlutterConfig(),
    this.onStateChanged,
  });

  @override
  State<JerseyZipperAndFabricFlutterPanel> createState() =>
      _JerseyZipperAndFabricFlutterPanelState();
}

class _JerseyZipperAndFabricFlutterPanelState
    extends State<JerseyZipperAndFabricFlutterPanel>
    with SingleTickerProviderStateMixin {
  late final JerseyZipperAndFabricFlutterFx _fx;
  late final AnimationController _ticker;

  late FabricFlutterConditionPreset _preset;
  late GarmentOuterLayerType _garmentType;
  late double _speedKmh;
  late double _temperatureCelsius;
  late double _gradientPercent;
  late double _crosswindAngleDeg;
  late bool _isWearingRainJacket;
  bool _manualZipperEnabled = false;
  double _manualZipperValue = 0.75;
  bool _isPlaying = true;
  double _elapsedSeconds = 0.0;
  DateTime _lastTickTime = DateTime.now();
  late JerseyFabricFlutterState _currentState;

  @override
  void initState() {
    super.initState();
    _fx = JerseyZipperAndFabricFlutterFx(config: widget.config);
    _applyPreset(widget.initialPreset, notify: false);
    _currentState = _evaluateNow();

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onAnimationTick);
    _ticker.repeat();
  }

  @override
  void dispose() {
    _ticker.removeListener(_onAnimationTick);
    _ticker.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (!_isPlaying) {
      _lastTickTime = DateTime.now();
      return;
    }
    final DateTime now = DateTime.now();
    final double dt = (now.difference(_lastTickTime).inMicroseconds / 1000000.0).clamp(0.001, 0.05);
    _lastTickTime = now;
    _elapsedSeconds += dt;

    final JerseyFabricFlutterState next = _fx.step(
      input: _buildInput(),
      dtSeconds: dt,
      elapsedSeconds: _elapsedSeconds,
    );

    if (mounted) {
      setState(() {
        _currentState = next;
      });
      widget.onStateChanged?.call(next);
    }
  }

  void _applyPreset(FabricFlutterConditionPreset preset, {bool notify = true}) {
    _preset = preset;
    _garmentType = preset.garmentType;
    _speedKmh = preset.speedKmh;
    _temperatureCelsius = preset.temperatureCelsius;
    _gradientPercent = preset.gradientPercent;
    _crosswindAngleDeg = preset.crosswindAngleDeg;
    _isWearingRainJacket = preset.isWearingRainJacket;
    if (notify && mounted) {
      setState(() {
        _currentState = _evaluateNow();
      });
      widget.onStateChanged?.call(_currentState);
    }
  }

  JerseyFabricFlutterFrameInput _buildInput() {
    return JerseyFabricFlutterFrameInput(
      riderId: 'peloton_captain',
      speedKmh: _speedKmh,
      headwindKmh: _preset.headwindKmh,
      crosswindAngleRad: _crosswindAngleDeg * math.pi / 180.0,
      temperatureCelsius: _temperatureCelsius,
      gradientPercent: _gradientPercent,
      powerWatts: _preset.powerWatts,
      cadenceRpm: _preset.cadenceRpm,
      garmentType: _garmentType,
      isWearingRainJacket: _isWearingRainJacket,
      isStandingOutOfSaddle: _preset.isStandingOutOfSaddle,
      manualZipperOverride: _manualZipperEnabled ? _manualZipperValue : null,
    );
  }

  JerseyFabricFlutterState _evaluateNow() {
    return _fx.evaluateFrame(
      input: _buildInput(),
      elapsedSeconds: _elapsedSeconds,
    );
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
          final bool isCompactMobile = constraints.maxWidth < 680;
          final Widget previewCard = _buildPreviewViewport(isCompactMobile);
          final Widget controlsCard = _buildControlsColumn();

          if (isCompactMobile) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildHeaderRow(),
                  const SizedBox(height: 12),
                  previewCard,
                  const SizedBox(height: 12),
                  controlsCard,
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeaderRow(),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 5, child: previewCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: controlsCard),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.6)),
          ),
          child: const Icon(Icons.air_rounded, color: AppColors.goldAccent, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Aerodynamika Odzieży i Zamka 3D',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Łopotanie rękawków, kurtki przeciwdeszczowej oraz rozpięcie zamka',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _InteractiveActionButton(
          label: _isPlaying ? 'Pauza' : 'Start',
          icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          isActive: _isPlaying,
          onPressed: () {
            setState(() {
              _isPlaying = !_isPlaying;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreviewViewport(bool isCompactMobile) {
    final double previewHeight = isCompactMobile ? 230 : 300;
    final ZipperOpeningState z = _currentState.zipperState;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: previewHeight,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: JerseyZipperAndFabricFlutterPainter(
                      state: _currentState,
                      crosswindAngleRad: _crosswindAngleDeg * math.pi / 180.0,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _TelemetryBadge(
                    label: '${_currentState.apparentAirspeedKmh.toStringAsFixed(1)} km/h wiatr',
                    color: AppColors.accentBlue,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _TelemetryBadge(
                    label: 'Kara aero: -${_currentState.aeroDragPenaltyWatts.toStringAsFixed(1)} W',
                    color: _currentState.aeroDragPenaltyWatts > 14.0
                        ? AppColors.amberWarning
                        : AppColors.statusSuccess,
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      z.reasonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                _MetricReadout(
                  label: 'Lewy rękaw',
                  value: '${_currentState.leftSleeve.amplitudeMm.toStringAsFixed(1)} mm',
                  subValue: '${_currentState.leftSleeve.frequencyHz.toStringAsFixed(0)} Hz',
                ),
                _MetricReadout(
                  label: 'Prawy rękaw',
                  value: '${_currentState.rightSleeve.amplitudeMm.toStringAsFixed(1)} mm',
                  subValue: '${_currentState.rightSleeve.frequencyHz.toStringAsFixed(0)} Hz',
                ),
                _MetricReadout(
                  label: 'Zamek piersiowy',
                  value: '${(z.unzippedRatio * 100).round()}%',
                  subValue: '${z.openingLengthCm.toStringAsFixed(1)} cm',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsColumn() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'SCENARIUSZ WYŚCIGOWY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FabricFlutterConditionPreset.values.map((FabricFlutterConditionPreset p) {
              return _InteractiveActionButton(
                label: p.label,
                isActive: _preset == p,
                onPressed: () => _applyPreset(p),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'WARSTWA ODZIEŻY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GarmentOuterLayerType.values.map((GarmentOuterLayerType g) {
              final bool isSelected =
                  (_isWearingRainJacket ? GarmentOuterLayerType.rainShellJacket : _garmentType) == g;
              return _InteractiveActionButton(
                label: g.label,
                isActive: isSelected,
                onPressed: () {
                  setState(() {
                    _garmentType = g;
                    _isWearingRainJacket = g == GarmentOuterLayerType.rainShellJacket;
                    _currentState = _evaluateNow();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _SliderRow(
            label: 'Prędkość jazdy',
            valueLabel: '${_speedKmh.toStringAsFixed(0)} km/h',
            value: _speedKmh,
            min: 8.0,
            max: 85.0,
            onChanged: (double v) {
              setState(() {
                _speedKmh = v;
                _currentState = _evaluateNow();
              });
            },
          ),
          _SliderRow(
            label: 'Temperatura',
            valueLabel: '${_temperatureCelsius.toStringAsFixed(1)} °C',
            value: _temperatureCelsius,
            min: 2.0,
            max: 42.0,
            onChanged: (double v) {
              setState(() {
                _temperatureCelsius = v;
                _currentState = _evaluateNow();
              });
            },
          ),
          _SliderRow(
            label: 'Nachylenie',
            valueLabel: '${_gradientPercent.toStringAsFixed(1)} %',
            value: _gradientPercent,
            min: -12.0,
            max: 20.0,
            onChanged: (double v) {
              setState(() {
                _gradientPercent = v;
                _currentState = _evaluateNow();
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _InteractiveActionButton(
                  label: _manualZipperEnabled
                      ? 'Zamek: Ręczny (${(_manualZipperValue * 100).round()}%)'
                      : 'Zamek: Auto (Upał/Aero)',
                  icon: _manualZipperEnabled ? Icons.tune_rounded : Icons.auto_awesome_rounded,
                  isActive: _manualZipperEnabled,
                  isDisabled: _isWearingRainJacket,
                  onPressed: () {
                    setState(() {
                      _manualZipperEnabled = !_manualZipperEnabled;
                      _currentState = _evaluateNow();
                    });
                  },
                ),
              ),
            ],
          ),
          if (_manualZipperEnabled && !_isWearingRainJacket) ...<Widget>[
            const SizedBox(height: 6),
            _SliderRow(
              label: 'Rozpięcie zamka',
              valueLabel: '${(_manualZipperValue * 100).round()} %',
              value: _manualZipperValue,
              min: 0.0,
              max: 1.0,
              onChanged: (double v) {
                setState(() {
                  _manualZipperValue = v;
                  _currentState = _evaluateNow();
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    this.icon,
    required this.isActive,
    this.isDisabled = false,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() => _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.isDisabled;
    final Color bgColor;
    if (!enabled) {
      bgColor = AppColors.surface.withValues(alpha: 0.45);
    } else if (widget.isActive) {
      bgColor = _isPressed
          ? AppColors.primaryAccent
          : (_isHovered ? AppColors.primaryAccent.withValues(alpha: 0.92) : AppColors.primaryAccent.withValues(alpha: 0.78));
    } else {
      bgColor = _isPressed
          ? AppColors.surfaceLight
          : (_isHovered ? AppColors.cardBorder : AppColors.surface);
    }

    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : (_isFocused
            ? AppColors.goldAccent
            : (widget.isActive ? AppColors.goldAccent.withValues(alpha: 0.85) : AppTheme.borderColor));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(
                  widget.icon,
                  size: 14,
                  color: enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.2,
                    color: enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TelemetryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          color: color,
        ),
      ),
    );
  }
}

class _MetricReadout extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;

  const _MetricReadout({
    required this.label,
    required this.value,
    required this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subValue,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: AppTheme.borderColor,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
            trackHeight: 3.0,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
