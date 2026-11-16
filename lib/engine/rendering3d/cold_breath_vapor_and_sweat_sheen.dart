// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Presety warunków termicznych i wysokościowych dla efektów fizjologicznych 3D.
enum ThermalPhysiologyConditionPreset {
  /// Wysoka przełęcz alpejska (np. Galibier / Stelvio, 4.5°C, 2645 m n.p.m.).
  alpineSummitCold(
    label: 'Przełęcz 4.5°C',
    temperatureCelsius: 4.5,
    altitudeMeters: 2645.0,
    relativeHumidity: 0.78,
    powerWatts: 385.0,
    heartRateBpm: 172.0,
    speedKmh: 24.0,
  ),

  /// Mroźny zjazd z przełęczy (1.5°C, duża prędkość 68 km/h).
  freezingDescent(
    label: 'Zjazd 1.5°C',
    temperatureCelsius: 1.5,
    altitudeMeters: 2200.0,
    relativeHumidity: 0.85,
    powerWatts: 130.0,
    heartRateBpm: 122.0,
    speedKmh: 68.0,
  ),

  /// Umiarkowana dolina (18.0°C — brak pary i brak intensywnego potu).
  temperateValley(
    label: 'Dolina 18°C',
    temperatureCelsius: 18.0,
    altitudeMeters: 420.0,
    relativeHumidity: 0.52,
    powerWatts: 265.0,
    heartRateBpm: 144.0,
    speedKmh: 42.0,
  ),

  /// Upalny podjazd w Pirenejach / Mont Ventoux (33.5°C).
  summerHeatClimb(
    label: 'Upał 33.5°C',
    temperatureCelsius: 33.5,
    altitudeMeters: 1450.0,
    relativeHumidity: 0.45,
    powerWatts: 405.0,
    heartRateBpm: 181.0,
    speedKmh: 19.0,
  ),

  /// Ekstremalny upał i wysoki wysiłek (39.0°C, 520 W).
  extremeHeatSprint(
    label: 'Skwar 39°C',
    temperatureCelsius: 39.0,
    altitudeMeters: 180.0,
    relativeHumidity: 0.60,
    powerWatts: 520.0,
    heartRateBpm: 189.0,
    speedKmh: 52.0,
  );

  final String label;
  final double temperatureCelsius;
  final double altitudeMeters;
  final double relativeHumidity;
  final double powerWatts;
  final double heartRateBpm;
  final double speedKmh;

  const ThermalPhysiologyConditionPreset({
    required this.label,
    required this.temperatureCelsius,
    required this.altitudeMeters,
    required this.relativeHumidity,
    required this.powerWatts,
    required this.heartRateBpm,
    required this.speedKmh,
  });
}

/// Faza cyklu oddechowego kolarza.
enum BreathCyclePhase {
  inhale('Wdech'),
  exhalePeak('Wydech szczytowy'),
  exhaleTail('Końcówka wydechu'),
  pause('Pauza');

  final String label;
  const BreathCyclePhase(this.label);
}

/// Strefa skóry kolarza objęta połyskiem potu.
enum LimbSheenZone {
  leftArm('Lewe ramię'),
  rightArm('Prawe ramię'),
  leftLeg('Lewa noga'),
  rightLeg('Prawa noga'),
  faceAndNeck('Twarz i kark');

  final String label;
  const LimbSheenZone(this.label);
}

/// Konfiguracja progów i parametrów fizycznych pary wodnej oraz potu.
class ColdBreathAndSweatConfig {
  /// Próg temperatury poniżej którego pojawia się para wodna z ust [°C].
  final double coldBreathThresholdCelsius;

  /// Próg temperatury powyżej którego pojawia się połysk potu na skórze [°C].
  final double heatSweatThresholdCelsius;

  /// Minimalna częstość oddechów na minutę (jazda regeneracyjna).
  final double minBreathRateBpm;

  /// Maksymalna częstość oddechów na minutę (wysiłek VO2max na wysokości).
  final double maxBreathRateBpm;

  /// Liczba cząsteczek obłoczka pary przypadająca na jeden wydech.
  final int vaporParticlesPerExhale;

  /// Czas życia pojedynczego obłoczka pary [s].
  final double vaporLifetimeSeconds;

  /// Maksymalny wykładnik Blinna-Phonga dla mokrej od potu skóry.
  final double maxSpecularExponent;

  const ColdBreathAndSweatConfig({
    this.coldBreathThresholdCelsius = 10.0,
    this.heatSweatThresholdCelsius = 28.0,
    this.minBreathRateBpm = 16.0,
    this.maxBreathRateBpm = 62.0,
    this.vaporParticlesPerExhale = 10,
    this.vaporLifetimeSeconds = 1.35,
    this.maxSpecularExponent = 48.0,
  });

  ColdBreathAndSweatConfig copyWith({
    double? coldBreathThresholdCelsius,
    double? heatSweatThresholdCelsius,
    double? minBreathRateBpm,
    double? maxBreathRateBpm,
    int? vaporParticlesPerExhale,
    double? vaporLifetimeSeconds,
    double? maxSpecularExponent,
  }) {
    return ColdBreathAndSweatConfig(
      coldBreathThresholdCelsius:
          coldBreathThresholdCelsius ?? this.coldBreathThresholdCelsius,
      heatSweatThresholdCelsius:
          heatSweatThresholdCelsius ?? this.heatSweatThresholdCelsius,
      minBreathRateBpm: minBreathRateBpm ?? this.minBreathRateBpm,
      maxBreathRateBpm: maxBreathRateBpm ?? this.maxBreathRateBpm,
      vaporParticlesPerExhale:
          vaporParticlesPerExhale ?? this.vaporParticlesPerExhale,
      vaporLifetimeSeconds: vaporLifetimeSeconds ?? this.vaporLifetimeSeconds,
      maxSpecularExponent: maxSpecularExponent ?? this.maxSpecularExponent,
    );
  }
}

/// Dane wejściowe pojedynczej klatki dla efektów fizjologicznych na modelu 3D kolarza.
class ColdBreathAndSweatFrameInput {
  /// Temperatura otoczenia [°C].
  final double ambientTemperatureCelsius;

  /// Wysokość n.p.m. [m] (zwiększa wentylację powyżej 1500 m).
  final double altitudeMeters;

  /// Wilgotność względna powietrza `[0.0, 1.0]`.
  final double relativeHumidity;

  /// Aktualna moc generowana przez kolarza [W].
  final double powerWatts;

  /// Próg mocy FTP kolarza [W].
  final double ftpWatts;

  /// Aktualne tętno kolarza [BPM].
  final double heartRateBpm;

  /// Maksymalne tętno kolarza [BPM].
  final double maxHeartRateBpm;

  /// Prędkość jazdy kolarza [m/s].
  final double riderSpeedMs;

  /// Prędkość wiatru czołowego [m/s] (dodatnia = pod wiatr).
  final double headwindMs;

  /// Znormalizowany kierunek padania światła słonecznego w przestrzeni 3D.
  final vm.Vector3 sunDirection;

  /// Znormalizowany kierunek z modelu do kamery w przestrzeni 3D.
  final vm.Vector3 cameraViewDirection;

  /// Natężenie światła słonecznego `[0.0, 1.0]`.
  final double sunlightIntensity;

  /// Czas symulacji [s].
  final double timeSeconds;

  /// Pozycja ust kolarza w przestrzeni 3D [m].
  final vm.Vector3 mouthWorldPosition;

  /// Kąt kursu kolarza [rad].
  final double riderHeadingRadians;

  ColdBreathAndSweatFrameInput({
    this.ambientTemperatureCelsius = 18.0,
    this.altitudeMeters = 400.0,
    this.relativeHumidity = 0.55,
    this.powerWatts = 280.0,
    this.ftpWatts = 380.0,
    this.heartRateBpm = 148.0,
    this.maxHeartRateBpm = 192.0,
    this.riderSpeedMs = 10.5,
    this.headwindMs = 0.0,
    vm.Vector3? sunDirection,
    vm.Vector3? cameraViewDirection,
    this.sunlightIntensity = 0.9,
    this.timeSeconds = 0.0,
    vm.Vector3? mouthWorldPosition,
    this.riderHeadingRadians = 0.0,
  }) : sunDirection =
           sunDirection ?? vm.Vector3(0.45, 0.82, 0.35).normalized(),
       cameraViewDirection =
           cameraViewDirection ?? vm.Vector3(0.75, 0.35, -0.55).normalized(),
       mouthWorldPosition = mouthWorldPosition ?? vm.Vector3(0.0, 1.42, 0.34);

  ColdBreathAndSweatFrameInput copyWith({
    double? ambientTemperatureCelsius,
    double? altitudeMeters,
    double? relativeHumidity,
    double? powerWatts,
    double? ftpWatts,
    double? heartRateBpm,
    double? maxHeartRateBpm,
    double? riderSpeedMs,
    double? headwindMs,
    vm.Vector3? sunDirection,
    vm.Vector3? cameraViewDirection,
    double? sunlightIntensity,
    double? timeSeconds,
    vm.Vector3? mouthWorldPosition,
    double? riderHeadingRadians,
  }) {
    return ColdBreathAndSweatFrameInput(
      ambientTemperatureCelsius:
          ambientTemperatureCelsius ?? this.ambientTemperatureCelsius,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      relativeHumidity: relativeHumidity ?? this.relativeHumidity,
      powerWatts: powerWatts ?? this.powerWatts,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      maxHeartRateBpm: maxHeartRateBpm ?? this.maxHeartRateBpm,
      riderSpeedMs: riderSpeedMs ?? this.riderSpeedMs,
      headwindMs: headwindMs ?? this.headwindMs,
      sunDirection: sunDirection ?? this.sunDirection,
      cameraViewDirection: cameraViewDirection ?? this.cameraViewDirection,
      sunlightIntensity: sunlightIntensity ?? this.sunlightIntensity,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      mouthWorldPosition: mouthWorldPosition ?? this.mouthWorldPosition,
      riderHeadingRadians: riderHeadingRadians ?? this.riderHeadingRadians,
    );
  }
}

/// Pojedyncza cząsteczka obłoczka pary wodnej w przestrzeni 3D.
class BreathVaporParticle3D {
  final vm.Vector3 worldPosition;
  final vm.Vector3 velocity;
  final double radiusMeters;
  final double opacity;
  final double ageNormalized;
  final Color temperatureTint;

  const BreathVaporParticle3D({
    required this.worldPosition,
    required this.velocity,
    required this.radiusMeters,
    required this.opacity,
    required this.ageNormalized,
    required this.temperatureTint,
  });
}

/// Stan efektu pary wodnej wydychanej w niskiej temperaturze (<10°C).
class BreathVaporState {
  /// Czy efekt jest aktywny (temperatura < 10°C).
  final bool isActive;

  /// Częstość oddechu [oddechów/min].
  final double respiratoryRateBpm;

  /// Bieżąca faza cyklu oddechowego.
  final BreathCyclePhase breathCyclePhase;

  /// Postęp bieżącego cyklu `[0.0, 1.0]`.
  final double cycleProgress;

  /// Chwilowa intensywność wydechu `[0.0, 1.0]`.
  final double exhaleIntensity;

  /// Gęstość kondensacji pary `[0.0, 1.0]`.
  final double vaporDensity;

  /// Lista aktywnych cząsteczek obłoczków 3D.
  final List<BreathVaporParticle3D> particles;

  const BreathVaporState({
    required this.isActive,
    required this.respiratoryRateBpm,
    required this.breathCyclePhase,
    required this.cycleProgress,
    required this.exhaleIntensity,
    required this.vaporDensity,
    required this.particles,
  });

  const BreathVaporState.inactive({
    required this.respiratoryRateBpm,
    required this.breathCyclePhase,
    required this.cycleProgress,
  }) : isActive = false,
       exhaleIntensity = 0.0,
       vaporDensity = 0.0,
       particles = const [];
}

/// Parametry połysku potu dla pojedynczej strefy anatomicznej kolarza 3D.
class LimbSweatHighlight {
  final LimbSheenZone zone;

  /// Natężenie odbicia lustrzanego (Blinn-Phong) `[0.0, 1.0]`.
  final double specularIntensity;

  /// Gładkość / połysk powierzchni skóry `[0.0, 1.0]`.
  final double glossiness;

  /// Szacowana grubość filmu potu na skórze [µm].
  final double wetnessFilmThicknessUm;

  /// Liczba widocznych kropelek / strużek potu na tej strefie.
  final int dropletStreakCount;

  /// Znormalizowane przesunięcie plamy odblasku na kończynie.
  final Offset highlightOffsetNormalized;

  /// Kolor odblasku potu.
  final Color highlightColor;

  const LimbSweatHighlight({
    required this.zone,
    required this.specularIntensity,
    required this.glossiness,
    required this.wetnessFilmThicknessUm,
    required this.dropletStreakCount,
    required this.highlightOffsetNormalized,
    required this.highlightColor,
  });
}

/// Stan efektu połysku potu na skórze ramion i nóg podczas upału (>28°C).
class SweatSheenState {
  /// Czy efekt jest aktywny (temperatura > 28°C).
  final bool isActive;

  /// Znormalizowane tempo pocenia `[0.0, 1.0]`.
  final double sweatRateNormalized;

  /// Stopień zwilżenia skóry `[0.0, 1.0]`.
  final double skinWetness;

  /// Szacowana utrata płynów [l/h].
  final double estimatedSweatLossLitersPerHour;

  /// Bazowe wzmocnienie połysku materiału skóry.
  final double skinBaseSpecularBoost;

  /// Lista stref połysku (ramiona, nogi, twarz/kark).
  final List<LimbSweatHighlight> limbHighlights;

  /// Maksymalna intensywność odblasku wśród stref.
  final double peakSpecularIntensity;

  const SweatSheenState({
    required this.isActive,
    required this.sweatRateNormalized,
    required this.skinWetness,
    required this.estimatedSweatLossLitersPerHour,
    required this.skinBaseSpecularBoost,
    required this.limbHighlights,
    required this.peakSpecularIntensity,
  });

  const SweatSheenState.inactive()
    : isActive = false,
      sweatRateNormalized = 0.0,
      skinWetness = 0.0,
      estimatedSweatLossLitersPerHour = 0.0,
      skinBaseSpecularBoost = 0.0,
      limbHighlights = const [],
      peakSpecularIntensity = 0.0;
}

/// Zbiorczy stan fizjologicznych efektów 3D kolarza w danej klatce.
class ColdBreathAndSweatState {
  final double ambientTemperatureCelsius;
  final double altitudeMeters;
  final BreathVaporState breathVapor;
  final SweatSheenState sweatSheen;
  final String thermalComfortLabel;

  const ColdBreathAndSweatState({
    required this.ambientTemperatureCelsius,
    required this.altitudeMeters,
    required this.breathVapor,
    required this.sweatSheen,
    required this.thermalComfortLabel,
  });
}

/// Silnik obliczający efekty fizjologiczne na modelu 3D kolarza:
/// 1. Obłoczki pary wodnej wydychane z ust w rytmie oddechu przy temp. < 10°C.
/// 2. Połysk potu na skórze ramion i nóg w upale > 28°C.
class ColdBreathVaporAndSweatSheen {
  final ColdBreathAndSweatConfig config;

  const ColdBreathVaporAndSweatSheen({
    this.config = const ColdBreathAndSweatConfig(),
  });

  /// Oblicza stan pary oddechowej oraz połysku potu dla pojedynczej klatki 3D.
  ColdBreathAndSweatState evaluateFrame(ColdBreathAndSweatFrameInput input) {
    final double safeTemp = input.ambientTemperatureCelsius.isFinite
        ? input.ambientTemperatureCelsius
        : 18.0;
    final double safeAltitude = input.altitudeMeters.isFinite
        ? math.max(0.0, input.altitudeMeters)
        : 0.0;
    final double safeHumidity = input.relativeHumidity.isFinite
        ? input.relativeHumidity.clamp(0.0, 1.0)
        : 0.5;
    final double safeFtp = input.ftpWatts > 1.0 ? input.ftpWatts : 380.0;
    final double safePower = input.powerWatts.isFinite
        ? math.max(0.0, input.powerWatts)
        : 0.0;
    final double safeMaxHr = input.maxHeartRateBpm > 60.0
        ? input.maxHeartRateBpm
        : 192.0;
    final double safeHr = input.heartRateBpm.isFinite
        ? input.heartRateBpm.clamp(40.0, safeMaxHr)
        : 120.0;
    final double safeSpeedMs = input.riderSpeedMs.isFinite
        ? math.max(0.0, input.riderSpeedMs)
        : 0.0;
    final double safeHeadwindMs = input.headwindMs.isFinite
        ? input.headwindMs
        : 0.0;
    final double safeSun = input.sunlightIntensity.isFinite
        ? input.sunlightIntensity.clamp(0.0, 1.0)
        : 0.8;
    final double safeTime = input.timeSeconds.isFinite
        ? math.max(0.0, input.timeSeconds)
        : 0.0;

    final double powerRatio = (safePower / safeFtp).clamp(0.0, 1.6);
    final double hrRatio = ((safeHr - 55.0) / (safeMaxHr - 55.0)).clamp(
      0.0,
      1.0,
    );
    final double altitudeVentilationBoost = safeAltitude > 1500.0
        ? ((safeAltitude - 1500.0) / 1500.0).clamp(0.0, 1.0) * 0.18
        : 0.0;

    final double effortFactor =
        (0.55 * (powerRatio / 1.25).clamp(0.0, 1.0) +
                0.45 * hrRatio +
                altitudeVentilationBoost)
            .clamp(0.0, 1.0);

    final double breathRateBpm =
        config.minBreathRateBpm +
        (config.maxBreathRateBpm - config.minBreathRateBpm) * effortFactor;
    final double cycleDurationSec = 60.0 / breathRateBpm;
    final double cycleProgress =
        (safeTime % cycleDurationSec) / cycleDurationSec;

    final BreathCyclePhase phase = _resolveBreathPhase(cycleProgress);
    final BreathVaporState breathVapor = _evaluateBreathVapor(
      temperatureCelsius: safeTemp,
      altitudeMeters: safeAltitude,
      humidity: safeHumidity,
      breathRateBpm: breathRateBpm,
      cycleProgress: cycleProgress,
      cycleDurationSec: cycleDurationSec,
      phase: phase,
      effortFactor: effortFactor,
      relativeAirflowMs: math.max(0.5, safeSpeedMs + safeHeadwindMs),
      mouthWorldPosition: input.mouthWorldPosition,
      headingRadians: input.riderHeadingRadians,
    );

    final SweatSheenState sweatSheen = _evaluateSweatSheen(
      temperatureCelsius: safeTemp,
      humidity: safeHumidity,
      powerWatts: safePower,
      effortFactor: effortFactor,
      riderSpeedMs: safeSpeedMs,
      sunDirection: input.sunDirection,
      cameraViewDirection: input.cameraViewDirection,
      sunlightIntensity: safeSun,
      headingRadians: input.riderHeadingRadians,
      timeSeconds: safeTime,
    );

    final String comfortLabel = _buildThermalComfortLabel(
      safeTemp,
      safeAltitude,
      breathVapor,
      sweatSheen,
    );

    return ColdBreathAndSweatState(
      ambientTemperatureCelsius: safeTemp,
      altitudeMeters: safeAltitude,
      breathVapor: breathVapor,
      sweatSheen: sweatSheen,
      thermalComfortLabel: comfortLabel,
    );
  }

  BreathCyclePhase _resolveBreathPhase(double cycleProgress) {
    if (cycleProgress < 0.36) {
      return BreathCyclePhase.inhale;
    }
    if (cycleProgress < 0.66) {
      return BreathCyclePhase.exhalePeak;
    }
    if (cycleProgress < 0.88) {
      return BreathCyclePhase.exhaleTail;
    }
    return BreathCyclePhase.pause;
  }

  BreathVaporState _evaluateBreathVapor({
    required double temperatureCelsius,
    required double altitudeMeters,
    required double humidity,
    required double breathRateBpm,
    required double cycleProgress,
    required double cycleDurationSec,
    required BreathCyclePhase phase,
    required double effortFactor,
    required double relativeAirflowMs,
    required vm.Vector3 mouthWorldPosition,
    required double headingRadians,
  }) {
    if (temperatureCelsius >= config.coldBreathThresholdCelsius) {
      return BreathVaporState.inactive(
        respiratoryRateBpm: breathRateBpm,
        breathCyclePhase: phase,
        cycleProgress: cycleProgress,
      );
    }

    // Im zimniej poniżej 10°C i im wyższa wilgotność/wysokość, tym gęstsza para.
    final double coldSeverity =
        ((config.coldBreathThresholdCelsius - temperatureCelsius) / 14.0).clamp(
          0.08,
          1.0,
        );
    final double altitudeBonus = altitudeMeters > 1500.0
        ? ((altitudeMeters - 1500.0) / 1500.0).clamp(0.0, 1.0) * 0.22
        : 0.0;
    final double vaporDensity =
        (coldSeverity * (0.65 + 0.35 * humidity) + altitudeBonus).clamp(
          0.1,
          1.0,
        );

    // Wydech trwa od 0.36 do 0.88 cyklu.
    double exhaleIntensity = 0.0;
    if (cycleProgress >= 0.36 && cycleProgress <= 0.88) {
      final double u = (cycleProgress - 0.36) / (0.88 - 0.36);
      exhaleIntensity = math.sin(u * math.pi).clamp(0.0, 1.0);
    }

    final double sinH = math.sin(headingRadians);
    final double cosH = math.cos(headingRadians);
    final vm.Vector3 forward = vm.Vector3(sinH, 0.0, cosH);
    final vm.Vector3 right = vm.Vector3(cosH, 0.0, -sinH);

    final int count = math.max(1, config.vaporParticlesPerExhale);
    final List<BreathVaporParticle3D> particles = <BreathVaporParticle3D>[];

    // Czas od początku fazy wydechu (obsługuje również ogon poprzedniego wydechu).
    double timeSinceExhaleStart = (cycleProgress - 0.36) * cycleDurationSec;
    if (timeSinceExhaleStart < 0.0) {
      timeSinceExhaleStart += cycleDurationSec;
    }

    final double lifetime = math.max(0.25, config.vaporLifetimeSeconds);

    for (int i = 0; i < count; i++) {
      final double emitOffsetSec = (i / count) * (0.48 * cycleDurationSec);
      final double ageSec = timeSinceExhaleStart - emitOffsetSec;
      if (ageSec < 0.0 || ageSec > lifetime) {
        continue;
      }

      final double ageNorm = (ageSec / lifetime).clamp(0.0, 1.0);
      // Cząsteczka jest wypychana lekko do przodu i natychmiast znoszona strugą powietrza.
      final double lateralJitter = math.sin(i * 2.37 + effortFactor * 3.1) * 0.08;
      final double verticalJitter = math.cos(i * 1.73) * 0.04;
      final double dragDisplacement =
          relativeAirflowMs * 0.16 * ageSec + 0.22 * ageSec * ageSec;

      final vm.Vector3 pos =
          mouthWorldPosition +
          forward * (0.12 - dragDisplacement) +
          right * (lateralJitter * (0.4 + ageNorm * 1.8)) +
          vm.Vector3(0.0, 0.06 * ageSec + verticalJitter * ageNorm, 0.0);

      final vm.Vector3 vel =
          forward * (-relativeAirflowMs * 0.18) +
          vm.Vector3(lateralJitter * 0.1, 0.24, 0.0);

      final double radius = 0.025 + ageNorm * (0.095 + 0.04 * vaporDensity);
      final double fadeIn = (ageNorm / 0.15).clamp(0.0, 1.0);
      final double fadeOut = math.pow(1.0 - ageNorm, 1.45).toDouble();
      final double opacity = (fadeIn * fadeOut * vaporDensity * 0.85).clamp(
        0.0,
        0.9,
      );

      if (opacity <= 0.01) {
        continue;
      }

      final Color tint = Color.lerp(
        const Color(0xFFE6F4FF),
        Colors.white,
        (1.0 - ageNorm) * 0.7,
      )!;

      particles.add(
        BreathVaporParticle3D(
          worldPosition: pos,
          velocity: vel,
          radiusMeters: radius,
          opacity: opacity,
          ageNormalized: ageNorm,
          temperatureTint: tint,
        ),
      );
    }

    return BreathVaporState(
      isActive: true,
      respiratoryRateBpm: breathRateBpm,
      breathCyclePhase: phase,
      cycleProgress: cycleProgress,
      exhaleIntensity: exhaleIntensity,
      vaporDensity: vaporDensity,
      particles: particles,
    );
  }

  SweatSheenState _evaluateSweatSheen({
    required double temperatureCelsius,
    required double humidity,
    required double powerWatts,
    required double effortFactor,
    required double riderSpeedMs,
    required vm.Vector3 sunDirection,
    required vm.Vector3 cameraViewDirection,
    required double sunlightIntensity,
    required double headingRadians,
    required double timeSeconds,
  }) {
    if (temperatureCelsius <= config.heatSweatThresholdCelsius) {
      return const SweatSheenState.inactive();
    }

    final double heatExcess =
        ((temperatureCelsius - config.heatSweatThresholdCelsius) / 14.0).clamp(
          0.05,
          1.0,
        );
    final double metabolicLoad = (0.35 + 0.65 * effortFactor).clamp(0.2, 1.0);
    // Wyższa prędkość zwiększa chłodzenie konwekcyjne, ale wysoka wilgotność utrudnia parowanie.
    final double convectiveCooling = (riderSpeedMs / 22.0).clamp(0.0, 0.45);
    final double evaporativePenalty = 0.75 + 0.35 * humidity;

    final double sweatRate =
        (heatExcess *
                metabolicLoad *
                evaporativePenalty *
                (1.0 - 0.35 * convectiveCooling))
            .clamp(0.06, 1.0);
    final double skinWetness = math.pow(sweatRate, 0.82).toDouble().clamp(
      0.08,
      1.0,
    );
    final double sweatLossLitersPerHour =
        0.55 + sweatRate * 1.85 + (powerWatts / 600.0) * 0.45;

    final vm.Vector3 sunDir = sunDirection.length2 > 1e-6
        ? sunDirection.normalized()
        : vm.Vector3(0.4, 0.85, 0.3).normalized();
    final vm.Vector3 viewDir = cameraViewDirection.length2 > 1e-6
        ? cameraViewDirection.normalized()
        : vm.Vector3(0.7, 0.35, -0.5).normalized();
    final vm.Vector3 halfVector = (sunDir + viewDir).normalized();

    final double sinH = math.sin(headingRadians);
    final double cosH = math.cos(headingRadians);

    vm.Vector3 rotateY(vm.Vector3 local) {
      return vm.Vector3(
        local.x * cosH + local.z * sinH,
        local.y,
        -local.x * sinH + local.z * cosH,
      ).normalized();
    }

    final Map<LimbSheenZone, vm.Vector3> zoneNormals =
        <LimbSheenZone, vm.Vector3>{
          LimbSheenZone.leftArm: rotateY(vm.Vector3(-0.68, 0.65, 0.34)),
          LimbSheenZone.rightArm: rotateY(vm.Vector3(0.68, 0.65, 0.34)),
          LimbSheenZone.leftLeg: rotateY(vm.Vector3(-0.52, 0.45, 0.72)),
          LimbSheenZone.rightLeg: rotateY(vm.Vector3(0.52, 0.45, 0.72)),
          LimbSheenZone.faceAndNeck: rotateY(vm.Vector3(0.0, 0.82, 0.57)),
        };

    final double shininess = 10.0 + skinWetness * config.maxSpecularExponent;
    final double glossiness = (0.30 + 0.68 * skinWetness).clamp(0.0, 1.0);
    final double filmThicknessUm = 8.0 + skinWetness * 42.0;

    final List<LimbSweatHighlight> highlights = <LimbSweatHighlight>[];
    double peakSpecular = 0.0;

    for (final MapEntry<LimbSheenZone, vm.Vector3> entry in zoneNormals.entries) {
      final double nDotH = math.max(0.0, entry.value.dot(halfVector));
      // Delikatny składnik Fresnela na krawędziach skóry ramion i nóg.
      final double fresnel = math
          .pow(1.0 - math.max(0.0, entry.value.dot(viewDir)), 2.5)
          .toDouble();
      final double rawSpec = math.pow(nDotH, shininess * 0.14).toDouble();
      final double pulse =
          0.92 + 0.08 * math.sin(timeSeconds * 4.0 + entry.key.index * 1.3);

      final double intensity =
          ((0.75 * rawSpec + 0.35 * fresnel) *
                  skinWetness *
                  (0.25 + 0.75 * sunlightIntensity) *
                  pulse)
              .clamp(0.0, 1.0);

      if (intensity > peakSpecular) {
        peakSpecular = intensity;
      }

      final int droplets = (2 + (skinWetness * 8).round()).clamp(2, 12);
      final Offset offset = Offset(
        (entry.value.x * 0.28).clamp(-0.35, 0.35),
        (-entry.value.y * 0.22).clamp(-0.35, 0.35),
      );
      final Color highlightColor = Color.lerp(
        const Color(0xFFFFF4D6),
        Colors.white,
        0.55 + 0.45 * intensity,
      )!;

      highlights.add(
        LimbSweatHighlight(
          zone: entry.key,
          specularIntensity: intensity,
          glossiness: glossiness,
          wetnessFilmThicknessUm: filmThicknessUm,
          dropletStreakCount: droplets,
          highlightOffsetNormalized: offset,
          highlightColor: highlightColor,
        ),
      );
    }

    return SweatSheenState(
      isActive: true,
      sweatRateNormalized: sweatRate,
      skinWetness: skinWetness,
      estimatedSweatLossLitersPerHour: sweatLossLitersPerHour,
      skinBaseSpecularBoost: skinWetness * 0.65,
      limbHighlights: highlights,
      peakSpecularIntensity: peakSpecular,
    );
  }

  String _buildThermalComfortLabel(
    double tempCelsius,
    double altitudeMeters,
    BreathVaporState breath,
    SweatSheenState sweat,
  ) {
    if (breath.isActive) {
      if (altitudeMeters >= 2000.0) {
        return 'Mróz wysokogórski (${tempCelsius.toStringAsFixed(1)}°C • ${altitudeMeters.round()} m)';
      }
      return 'Chłód (<10°C) — para oddechowa aktywna';
    }
    if (sweat.isActive) {
      if (tempCelsius >= 35.0) {
        return 'Ekstremalny skwar (${tempCelsius.toStringAsFixed(1)}°C) — intensywny pot';
      }
      return 'Upał (>28°C) — połysk potu na skórze';
    }
    return 'Strefa komfortu (${tempCelsius.toStringAsFixed(1)}°C)';
  }
}

/// Rzutnik 2D/3D podglądu kolarza z efektami pary oddechowej i połysku potu.
class ColdBreathAndSweatPainter extends CustomPainter {
  final ColdBreathAndSweatState state;
  final double animationTimeSeconds;

  const ColdBreathAndSweatPainter({
    required this.state,
    required this.animationTimeSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final Rect bounds = Offset.zero & size;
    final bool isCold = state.breathVapor.isActive;
    final bool isHot = state.sweatSheen.isActive;

    final Color skyTop = isCold
        ? const Color(0xFF0E1726)
        : isHot
        ? const Color(0xFF231612)
        : AppColors.background;
    final Color skyBottom = isCold
        ? const Color(0xFF1A2538)
        : isHot
        ? const Color(0xFF181414)
        : AppColors.surface;

    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[skyTop, skyBottom],
      ).createShader(bounds);
    canvas.drawRect(bounds, bgPaint);

    // Linia szosy
    final double roadY = size.height * 0.80;
    final Paint roadPaint = Paint()..color = const Color(0xFF252933);
    canvas.drawRect(
      Rect.fromLTWH(0, roadY, size.width, size.height - roadY),
      roadPaint,
    );

    final Paint roadLinePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.35)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, roadY), Offset(size.width, roadY), roadLinePaint);

    final double cx = size.width * 0.44;
    final double scale = math.min(size.width / 320.0, size.height / 210.0);

    // Koła i rama roweru
    final Offset rearWheel = Offset(cx - 56 * scale, roadY - 26 * scale);
    final Offset frontWheel = Offset(cx + 58 * scale, roadY - 26 * scale);
    final double wheelRadius = 26 * scale;

    final Paint wheelPaint = Paint()
      ..color = const Color(0xFF0B0D11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 * scale;
    canvas.drawCircle(rearWheel, wheelRadius, wheelPaint);
    canvas.drawCircle(frontWheel, wheelRadius, wheelPaint);

    final Paint rimPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * scale;
    canvas.drawCircle(rearWheel, wheelRadius - 3 * scale, rimPaint);
    canvas.drawCircle(frontWheel, wheelRadius - 3 * scale, rimPaint);

    final Offset bb = Offset(cx - 8 * scale, roadY - 28 * scale);
    final Offset seatCluster = Offset(cx - 28 * scale, roadY - 68 * scale);
    final Offset headTube = Offset(cx + 38 * scale, roadY - 64 * scale);

    final Paint framePaint = Paint()
      ..color = AppColors.primaryAccent
      ..strokeWidth = 4.2 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path framePath = Path()
      ..moveTo(rearWheel.dx, rearWheel.dy)
      ..lineTo(bb.dx, bb.dy)
      ..lineTo(seatCluster.dx, seatCluster.dy)
      ..close()
      ..moveTo(bb.dx, bb.dy)
      ..lineTo(headTube.dx, headTube.dy)
      ..lineTo(seatCluster.dx, seatCluster.dy)
      ..moveTo(headTube.dx, headTube.dy)
      ..lineTo(frontWheel.dx, frontWheel.dy);
    canvas.drawPath(framePath, framePaint);

    // Sylwetka kolarza (skóra + strój)
    const Color skinTone = Color(0xFFD59B78);
    final Paint skinPaint = Paint()
      ..color = skinTone
      ..strokeWidth = 8.5 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Offset hip = Offset(cx - 24 * scale, roadY - 76 * scale);
    final Offset shoulder = Offset(cx + 22 * scale, roadY - 106 * scale);
    final Offset headCenter = Offset(cx + 40 * scale, roadY - 118 * scale);
    final Offset handlebar = Offset(cx + 46 * scale, roadY - 74 * scale);
    final Offset elbow = Offset(cx + 38 * scale, roadY - 90 * scale);
    final double crankAngle = animationTimeSeconds * 7.0;
    final Offset pedal = Offset(
      bb.dx + math.cos(crankAngle) * 14 * scale,
      bb.dy + math.sin(crankAngle) * 14 * scale,
    );
    final Offset knee = Offset(
      (hip.dx + pedal.dx) * 0.5 + 14 * scale,
      (hip.dy + pedal.dy) * 0.5 - 10 * scale,
    );

    // Noga (skóra łydki/uda)
    final Path legPath = Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(knee.dx, knee.dy)
      ..lineTo(pedal.dx, pedal.dy);
    canvas.drawPath(legPath, skinPaint);

    // Spodenki i koszulka drużynowa
    final Paint jerseyPaint = Paint()
      ..color = const Color(0xFF1E2430)
      ..strokeWidth = 14.0 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hip, shoulder, jerseyPaint);

    // Ramię (skóra przedramienia i ramienia)
    final Path armPath = Path()
      ..moveTo(shoulder.dx, shoulder.dy)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(handlebar.dx, handlebar.dy);
    canvas.drawPath(armPath, skinPaint);

    // Głowa i kask
    canvas.drawCircle(
      headCenter,
      9.5 * scale,
      Paint()..color = skinTone,
    );
    final Paint helmetPaint = Paint()..color = AppColors.goldAccent;
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: 11.2 * scale),
      math.pi * 0.95,
      math.pi * 1.15,
      true,
      helmetPaint,
    );

    // Połysk potu na skórze ramion i nóg (>28°C)
    if (isHot) {
      _paintSweatSheen(
        canvas: canvas,
        scale: scale,
        shoulder: shoulder,
        elbow: elbow,
        handlebar: handlebar,
        hip: hip,
        knee: knee,
        pedal: pedal,
        headCenter: headCenter,
      );
    }

    // Obłoczki pary wodnej z ust (<10°C)
    if (isCold) {
      final Offset mouth2d = Offset(
        headCenter.dx + 8.5 * scale,
        headCenter.dy + 3.5 * scale,
      );
      _paintBreathVapor(canvas: canvas, scale: scale, mouth2d: mouth2d);
    }
  }

  void _paintSweatSheen({
    required Canvas canvas,
    required double scale,
    required Offset shoulder,
    required Offset elbow,
    required Offset handlebar,
    required Offset hip,
    required Offset knee,
    required Offset pedal,
    required Offset headCenter,
  }) {
    final double wetness = state.sweatSheen.skinWetness;
    final List<LimbSweatHighlight> highlights = state.sweatSheen.limbHighlights;
    if (highlights.isEmpty) {
      return;
    }

    double armSpec = 0.0;
    double legSpec = 0.0;
    double faceSpec = 0.0;
    for (final LimbSweatHighlight h in highlights) {
      if (h.zone == LimbSheenZone.leftArm || h.zone == LimbSheenZone.rightArm) {
        armSpec = math.max(armSpec, h.specularIntensity);
      } else if (h.zone == LimbSheenZone.leftLeg ||
          h.zone == LimbSheenZone.rightLeg) {
        legSpec = math.max(legSpec, h.specularIntensity);
      } else {
        faceSpec = math.max(faceSpec, h.specularIntensity);
      }
    }

    // Odblask na ramieniu
    final Paint armSheenPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: (0.25 + 0.65 * armSpec * wetness).clamp(0.0, 0.92),
      )
      ..strokeWidth = 3.4 * scale
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 * scale);
    canvas.drawLine(
      Offset.lerp(shoulder, elbow, 0.25)!,
      Offset.lerp(elbow, handlebar, 0.65)!,
      armSheenPaint,
    );

    // Odblask na udzie i łydce
    final Paint legSheenPaint = Paint()
      ..color = const Color(
        0xFFFFF8E6,
      ).withValues(alpha: (0.25 + 0.65 * legSpec * wetness).clamp(0.0, 0.92))
      ..strokeWidth = 3.8 * scale
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.8 * scale);
    canvas.drawLine(
      Offset.lerp(hip, knee, 0.3)!,
      Offset.lerp(knee, pedal, 0.55)!,
      legSheenPaint,
    );

    // Kropelki potu błyszczące na skórze
    final Paint dropletPaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.55 + 0.4 * faceSpec).clamp(0.0, 0.95));
    for (int i = 0; i < 4; i++) {
      final double t = 0.2 + i * 0.2;
      final Offset legDrop = Offset.lerp(knee, pedal, t)!;
      canvas.drawCircle(
        legDrop + Offset(-2.0 * scale, 1.2 * scale),
        1.3 * scale,
        dropletPaint,
      );
    }
    canvas.drawCircle(
      headCenter + Offset(4.5 * scale, 1.5 * scale),
      1.4 * scale,
      dropletPaint,
    );
  }

  void _paintBreathVapor({
    required Canvas canvas,
    required double scale,
    required Offset mouth2d,
  }) {
    final List<BreathVaporParticle3D> particles = state.breathVapor.particles;
    if (particles.isEmpty) {
      return;
    }

    for (final BreathVaporParticle3D p in particles) {
      // Rzutowanie lokalnego przesunięcia z przestrzeni 3D (Z = wiatr w tył, Y = góra)
      final double dx = (p.worldPosition.z - 0.34) * 95.0 * scale;
      final double dy = -(p.worldPosition.y - 1.42) * 95.0 * scale;
      final Offset screenPos = Offset(mouth2d.dx + dx, mouth2d.dy + dy);
      final double radiusPx = (p.radiusMeters * 130.0 * scale).clamp(3.0, 32.0);

      final Paint puffPaint = Paint()
        ..color = p.temperatureTint.withValues(alpha: p.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radiusPx * 0.45);
      canvas.drawCircle(screenPos, radiusPx, puffPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ColdBreathAndSweatPainter oldDelegate) {
    return oldDelegate.animationTimeSeconds != animationTimeSeconds ||
        oldDelegate.state.ambientTemperatureCelsius !=
            state.ambientTemperatureCelsius ||
        oldDelegate.state.breathVapor.particles.length !=
            state.breathVapor.particles.length ||
        oldDelegate.state.sweatSheen.peakSpecularIntensity !=
            state.sweatSheen.peakSpecularIntensity;
  }
}

/// Interaktywny panel podglądu i kalibracji efektów fizjologicznych 3D
/// (`ColdBreathVaporAndSweatSheen`) z pełnymi stanami interakcji i responsywnością.
class ColdBreathAndSweatControlPanel extends StatefulWidget {
  final ThermalPhysiologyConditionPreset initialPreset;
  final ValueChanged<ColdBreathAndSweatState>? onStateChanged;

  const ColdBreathAndSweatControlPanel({
    super.key,
    this.initialPreset = ThermalPhysiologyConditionPreset.alpineSummitCold,
    this.onStateChanged,
  });

  @override
  State<ColdBreathAndSweatControlPanel> createState() =>
      _ColdBreathAndSweatControlPanelState();
}

class _ColdBreathAndSweatControlPanelState
    extends State<ColdBreathAndSweatControlPanel>
    with SingleTickerProviderStateMixin {
  static const ColdBreathVaporAndSweatSheen _engine =
      ColdBreathVaporAndSweatSheen();

  late final AnimationController _animController;
  late ThermalPhysiologyConditionPreset _selectedPreset;
  ThermalPhysiologyConditionPreset? _hoveredPreset;

  late double _temperatureCelsius;
  late double _altitudeMeters;
  late double _powerWatts;
  late double _speedKmh;
  bool _isPlaying = true;
  double _elapsedSeconds = 0.42;

  @override
  void initState() {
    super.initState();
    _applyPreset(widget.initialPreset, notify: false);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addListener(_onTick);
    if (_isPlaying) {
      _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.removeListener(_onTick);
    _animController.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted || !_isPlaying) {
      return;
    }
    setState(() {
      _elapsedSeconds += 1.0 / 60.0;
    });
  }

  void _applyPreset(
    ThermalPhysiologyConditionPreset preset, {
    bool notify = true,
  }) {
    _selectedPreset = preset;
    _temperatureCelsius = preset.temperatureCelsius;
    _altitudeMeters = preset.altitudeMeters;
    _powerWatts = preset.powerWatts;
    _speedKmh = preset.speedKmh;
    if (notify) {
      setState(() {});
      widget.onStateChanged?.call(_evaluateCurrentState());
    }
  }

  ColdBreathAndSweatState _evaluateCurrentState() {
    final double estimatedHr = (100.0 + (_powerWatts / 550.0) * 90.0).clamp(
      95.0,
      192.0,
    );
    return _engine.evaluateFrame(
      ColdBreathAndSweatFrameInput(
        ambientTemperatureCelsius: _temperatureCelsius,
        altitudeMeters: _altitudeMeters,
        relativeHumidity: _selectedPreset.relativeHumidity,
        powerWatts: _powerWatts,
        heartRateBpm: estimatedHr,
        riderSpeedMs: _speedKmh / 3.6,
        timeSeconds: _elapsedSeconds,
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
    });
  }

  void _resetToPreset() {
    _elapsedSeconds = 0.42;
    _applyPreset(_selectedPreset);
  }

  @override
  Widget build(BuildContext context) {
    final ColdBreathAndSweatState state = _evaluateCurrentState();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 640;
        final bool isWide = constraints.maxWidth >= 980;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(state, isCompact),
                const SizedBox(height: 12),
                _buildPresetSelector(),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 5, child: _buildPreviewViewport(state)),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: _buildControlsAndMetrics(state)),
                    ],
                  )
                else ...<Widget>[
                  _buildPreviewViewport(state),
                  const SizedBox(height: 12),
                  _buildControlsAndMetrics(state),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColdBreathAndSweatState state, bool isCompact) {
    final Color statusColor = state.breathVapor.isActive
        ? AppColors.accentBlue
        : state.sweatSheen.isActive
        ? AppColors.amberWarning
        : AppColors.statusSuccess;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Icon(
                state.breathVapor.isActive
                    ? Icons.ac_unit_rounded
                    : state.sweatSheen.isActive
                    ? Icons.wb_sunny_rounded
                    : Icons.thermostat_rounded,
                color: statusColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Fizjologia 3D: Para Oddechowa i Połysk Potu',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    state.thermalComfortLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ActionIconButton(
              icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              tooltip: _isPlaying ? 'Pauza animacji' : 'Wznów animację',
              onPressed: _togglePlayPause,
            ),
            const SizedBox(width: 8),
            _ActionIconButton(
              icon: Icons.restart_alt_rounded,
              tooltip: 'Resetuj do presetu',
              onPressed: _resetToPreset,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ThermalPhysiologyConditionPreset.values.map((
        ThermalPhysiologyConditionPreset preset,
      ) {
        final bool isSelected = _selectedPreset == preset;
        final bool isHovered = _hoveredPreset == preset;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredPreset = preset),
          onExit: (_) => setState(() => _hoveredPreset = null),
          cursor: SystemMouseCursors.click,
          child: FocusableActionDetector(
            onShowFocusHighlight: (_) {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryAccent
                    : isHovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.goldAccent
                      : isHovered
                      ? AppColors.textSecondary
                      : AppTheme.borderColor,
                  width: 1.0,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _applyPreset(preset),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    preset.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewViewport(ColdBreathAndSweatState state) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: ColdBreathAndSweatPainter(
                state: state,
                animationTimeSeconds: _elapsedSeconds,
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                '${_temperatureCelsius.toStringAsFixed(1)}°C • ${_altitudeMeters.round()} m',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsAndMetrics(ColdBreathAndSweatState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _TelemetrySliderTile(
          label: 'Temperatura otoczenia',
          valueText: '${_temperatureCelsius.toStringAsFixed(1)} °C',
          value: _temperatureCelsius,
          min: -5.0,
          max: 42.0,
          accentColor: _temperatureCelsius < 10.0
              ? AppColors.accentBlue
              : _temperatureCelsius > 28.0
              ? AppColors.amberWarning
              : AppColors.statusSuccess,
          onChanged: (double v) {
            setState(() => _temperatureCelsius = v);
            widget.onStateChanged?.call(_evaluateCurrentState());
          },
        ),
        const SizedBox(height: 8),
        _TelemetrySliderTile(
          label: 'Wysokość przełęczy',
          valueText: '${_altitudeMeters.round()} m n.p.m.',
          value: _altitudeMeters,
          min: 0.0,
          max: 3000.0,
          accentColor: AppColors.cyanAccent,
          onChanged: (double v) {
            setState(() => _altitudeMeters = v);
            widget.onStateChanged?.call(_evaluateCurrentState());
          },
        ),
        const SizedBox(height: 8),
        _TelemetrySliderTile(
          label: 'Moc kolarza',
          valueText: '${_powerWatts.round()} W',
          value: _powerWatts,
          min: 100.0,
          max: 600.0,
          accentColor: AppColors.goldAccent,
          onChanged: (double v) {
            setState(() => _powerWatts = v);
            widget.onStateChanged?.call(_evaluateCurrentState());
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _MetricChip(
              title: 'Oddech',
              value:
                  '${state.breathVapor.respiratoryRateBpm.toStringAsFixed(0)} /min',
              subValue: state.breathVapor.isActive
                  ? state.breathVapor.breathCyclePhase.label
                  : 'Para nieaktywna',
              accent: state.breathVapor.isActive
                  ? AppColors.accentBlue
                  : AppColors.textSecondary,
            ),
            _MetricChip(
              title: 'Gęstość pary',
              value:
                  '${(state.breathVapor.vaporDensity * 100).toStringAsFixed(0)}%',
              subValue: '${state.breathVapor.particles.length} cząst.',
              accent: AppColors.cyanAccent,
            ),
            _MetricChip(
              title: 'Połysk potu',
              value:
                  '${(state.sweatSheen.peakSpecularIntensity * 100).toStringAsFixed(0)}%',
              subValue: state.sweatSheen.isActive
                  ? '${state.sweatSheen.estimatedSweatLossLitersPerHour.toStringAsFixed(1)} L/h'
                  : 'Pot nieaktywny',
              accent: state.sweatSheen.isActive
                  ? AppColors.amberWarning
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: FocusableActionDetector(
          onFocusChange: (bool f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: !enabled
                  ? AppColors.background
                  : _hovered
                  ? AppColors.surfaceLight
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : _hovered && enabled
                    ? AppColors.textSecondary
                    : AppTheme.borderColor,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetrySliderTile extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _TelemetrySliderTile({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valueText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.18),
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String title;
  final String value;
  final String subValue;
  final Color accent;

  const _MetricChip({
    required this.title,
    required this.value,
    required this.subValue,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          Text(
            subValue,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
