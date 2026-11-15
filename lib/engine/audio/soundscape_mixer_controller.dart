// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/race/stage_segment.dart';
import '../../models/settings/game_settings.dart';
import '../../state/game_settings_notifier.dart';
import 'procedural_cycling_audio_engine.dart';

/// Identyfikatory pięciu warstw pejzażu dźwiękowego miksera [SoundscapeMixerController].
enum SoundscapeChannel {
  /// Szum wiatru opływowego zależny od kwadratu prędkości ($v^2$).
  wind('Szum wiatru (v²)'),

  /// Terkot zapadek bębenka wolnobiegu aktywowany przy $P = 0\text{ W}$.
  freehub('Bębenek wolnobiegu (P=0W)'),

  /// Oddech kolarza narastający powyżej progu mleczanowego $LT_2$.
  breathing('Oddech kolarza (>LT2)'),

  /// Dzwonki krów przy górskich podjazdach i premiach KOM.
  cowbells('Dzwonki krów'),

  /// Wrzawa tłumu narastająca na ostatnich 500 m przed premią KOM i metą.
  crowd('Wrzawa tłumu (500 m)');

  final String label;
  const SoundscapeChannel(this.label);
}

/// Telemetria wejściowa dla miksera pejzażu dźwiękowego [SoundscapeMixerController].
class SoundscapeTelemetry {
  /// Prędkość kolarza w km/h.
  final double speedKmh;

  /// Prędkość wiatru czołowego w m/s (dodatnia = wiatr w twarz, ujemna = wiatr w plecy).
  final double headwindMs;

  /// Chwilowa moc generowana na pedałach w Watach [W].
  final double powerWatts;

  /// Kadencja pedałowania w obrotach na minutę [RPM].
  final double cadenceRpm;

  /// Próg mleczanowy $LT_2$ kolarza w Watach [W].
  final double lt2PowerWatts;

  /// Aktualne tętno kolarza [BPM] (opcjonalne, wspiera modulację tempa oddechu).
  final double heartRateBpm;

  /// Nachylenie terenu w procentach [%].
  final double gradientPercent;

  /// Wysokość nad poziomem morza w metrach [m].
  final double altitudeMeters;

  /// Pozostały dystans do linii mety w metrach [m].
  final double distanceToFinishMeters;

  /// Dystans do najbliższej premii górskiej KOM przed kolarzem w metrach [m] (`null` jeśli brak).
  final double? distanceToNextKomMeters;

  /// Liczba zębów w pierścieniu zapadek bębenka piasty (np. 36T / 54T).
  final int freehubTeethCount;

  /// Pozycja boczna na szosie [-3.5 m, +3.5 m] dla panoramy stereo.
  final double lateralRoadOffsetMeters;

  const SoundscapeTelemetry({
    this.speedKmh = 0.0,
    this.headwindMs = 0.0,
    this.powerWatts = 0.0,
    this.cadenceRpm = 0.0,
    this.lt2PowerWatts = 350.0,
    this.heartRateBpm = 140.0,
    this.gradientPercent = 0.0,
    this.altitudeMeters = 200.0,
    this.distanceToFinishMeters = 5000.0,
    this.distanceToNextKomMeters,
    this.freehubTeethCount = 54,
    this.lateralRoadOffsetMeters = 0.0,
  });

  /// Prędkość kolarza względem gruntu w m/s.
  double get speedMs => math.max(0.0, speedKmh) / 3.6;

  /// Prędkość względna opływu powietrza w m/s ($v + v_{\text{headwind}}$).
  double get apparentAirSpeedMs => math.max(0.0, speedMs + headwindMs);

  /// Czy kolarz jedzie na wolnobiegu bez generowania mocy ($P = 0\text{ W}$ przy ruchu).
  bool get isFreewheeling => powerWatts <= 0.0 && speedKmh > 2.0;

  /// Czy kolarz jedzie powyżej progu mleczanowego $LT_2$.
  bool get isAboveLt2 => lt2PowerWatts > 0.0 && powerWatts > lt2PowerWatts;

  /// Najbliższy dystans do kluczowego punktu (KOM lub meta) w metrach [m].
  double get nearestLandmarkDistanceMeters {
    final komDist = distanceToNextKomMeters;
    if (komDist == null || komDist < 0.0) {
      return math.max(0.0, distanceToFinishMeters);
    }
    return math.min(
      math.max(0.0, distanceToFinishMeters),
      komDist,
    );
  }

  /// Wylicza telemetrię dystansu do mety oraz najbliższej premii KOM na podstawie segmentów trasy.
  factory SoundscapeTelemetry.fromStageProgress({
    required double currentKm,
    required double totalStageKm,
    required List<StageSegment> segments,
    double speedKmh = 0.0,
    double headwindMs = 0.0,
    double powerWatts = 0.0,
    double cadenceRpm = 0.0,
    double lt2PowerWatts = 350.0,
    double heartRateBpm = 140.0,
    double gradientPercent = 0.0,
    double altitudeMeters = 200.0,
    int freehubTeethCount = 54,
    double lateralRoadOffsetMeters = 0.0,
  }) {
    final finishDistM = math.max(0.0, (totalStageKm - currentKm) * 1000.0);
    double? nearestKomM;

    for (final seg in segments) {
      final isKom = seg.sprintOrKomClassification == SegmentClassification.cat4 ||
          seg.sprintOrKomClassification == SegmentClassification.cat3 ||
          seg.sprintOrKomClassification == SegmentClassification.cat2 ||
          seg.sprintOrKomClassification == SegmentClassification.cat1 ||
          seg.sprintOrKomClassification == SegmentClassification.horsCategorie;
      if (!isKom) continue;

      final komKm = seg.endKm;
      if (komKm >= currentKm) {
        final distM = (komKm - currentKm) * 1000.0;
        if (nearestKomM == null || distM < nearestKomM) {
          nearestKomM = distM;
        }
      }
    }

    return SoundscapeTelemetry(
      speedKmh: speedKmh,
      headwindMs: headwindMs,
      powerWatts: powerWatts,
      cadenceRpm: cadenceRpm,
      lt2PowerWatts: lt2PowerWatts,
      heartRateBpm: heartRateBpm,
      gradientPercent: gradientPercent,
      altitudeMeters: altitudeMeters,
      distanceToFinishMeters: finishDistM,
      distanceToNextKomMeters: nearestKomM,
      freehubTeethCount: freehubTeethCount,
      lateralRoadOffsetMeters: lateralRoadOffsetMeters,
    );
  }

  SoundscapeTelemetry copyWith({
    double? speedKmh,
    double? headwindMs,
    double? powerWatts,
    double? cadenceRpm,
    double? lt2PowerWatts,
    double? heartRateBpm,
    double? gradientPercent,
    double? altitudeMeters,
    double? distanceToFinishMeters,
    double? distanceToNextKomMeters,
    bool clearNextKom = false,
    int? freehubTeethCount,
    double? lateralRoadOffsetMeters,
  }) {
    return SoundscapeTelemetry(
      speedKmh: speedKmh ?? this.speedKmh,
      headwindMs: headwindMs ?? this.headwindMs,
      powerWatts: powerWatts ?? this.powerWatts,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      lt2PowerWatts: lt2PowerWatts ?? this.lt2PowerWatts,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      distanceToFinishMeters: distanceToFinishMeters ?? this.distanceToFinishMeters,
      distanceToNextKomMeters:
          clearNextKom ? null : (distanceToNextKomMeters ?? this.distanceToNextKomMeters),
      freehubTeethCount: freehubTeethCount ?? this.freehubTeethCount,
      lateralRoadOffsetMeters: lateralRoadOffsetMeters ?? this.lateralRoadOffsetMeters,
    );
  }
}

/// Znormalizowane poziomy aktywności pięciu warstw pejzażu dźwiękowego [0.0, 1.0].
class SoundscapeLayerIntensities {
  final double wind;
  final double freehub;
  final double breathing;
  final double cowbells;
  final double crowd;

  const SoundscapeLayerIntensities({
    this.wind = 0.0,
    this.freehub = 0.0,
    this.breathing = 0.0,
    this.cowbells = 0.0,
    this.crowd = 0.0,
  });

  static const SoundscapeLayerIntensities zero = SoundscapeLayerIntensities();
}

// ============================================================================
// 1. GENERATOR SZUMU WIATRU ZALEŻNEGO OD v^2
// ============================================================================

/// Syntezator opływowego szumu wiatru, którego energia i wzmocnienie rosną z $v^2$.
class WindNoiseV2Generator {
  /// Prędkość referencyjna [m/s] (~72 km/h), przy której znormalizowane wzmocnienie osiąga 1.0.
  static const double referenceAirSpeedMs = 20.0;

  final math.Random _rng;
  double _pinkB0 = 0.0;
  double _pinkB1 = 0.0;
  double _pinkB2 = 0.0;
  double _gustPhase = 0.0;
  double _whistleBandpass1 = 0.0;
  double _whistleBandpass2 = 0.0;

  WindNoiseV2Generator({int seed = 17201}) : _rng = math.Random(seed);

  /// Oblicza wzmocnienie szumu wiatru proporcjonalne do kwadratu prędkości ($v^2$).
  static double computeQuadraticGain(double apparentAirSpeedMs) {
    if (apparentAirSpeedMs <= 0.0) return 0.0;
    final ratio = apparentAirSpeedMs / referenceAirSpeedMs;
    return (ratio * ratio).clamp(0.0, 1.5);
  }

  AudioStereoFrame processSample({
    required SoundscapeTelemetry telemetry,
    required double dt,
  }) {
    final gain = computeQuadraticGain(telemetry.apparentAirSpeedMs);
    if (gain <= 0.0005) {
      return AudioStereoFrame.zero;
    }

    final white = (_rng.nextDouble() * 2.0) - 1.0;

    // Filtr różowy (szum aerodynamiczny wokół kasku i uszu)
    _pinkB0 = (0.99765 * _pinkB0) + (white * 0.0990460);
    _pinkB1 = (0.96300 * _pinkB1) + (white * 0.2965164);
    _pinkB2 = (0.57000 * _pinkB2) + (white * 1.0526913);
    final pink = (_pinkB0 + _pinkB1 + _pinkB2 + (white * 0.1848)) * 0.18;

    // Pasmowy świst wiatru przy kasku (częstotliwość rośnie z prędkością)
    final whistleFreqHz =
        (260.0 + (telemetry.apparentAirSpeedMs * 24.0)).clamp(240.0, 950.0);
    final f = (2.0 * math.sin(math.pi * whistleFreqHz * dt)).clamp(0.01, 0.45);
    const q = 0.35;
    _whistleBandpass1 += f * _whistleBandpass2;
    _whistleBandpass2 +=
        f * (white - _whistleBandpass1 - (q * _whistleBandpass2));

    // Powolne podmuchy i delikatna modulacja stereo L/R
    _gustPhase = (_gustPhase + (2.0 * math.pi * 0.42 * dt)) % (2.0 * math.pi);
    final gustL = 0.88 + (0.12 * math.sin(_gustPhase));
    final gustR = 0.88 + (0.12 * math.cos(_gustPhase * 0.85));

    final coreWind = (pink * 0.78) + (_whistleBandpass2 * 0.28);
    final outL = (coreWind * gain * gustL).clamp(-1.0, 1.0);
    final outR = (coreWind * gain * gustR).clamp(-1.0, 1.0);

    return AudioStereoFrame(outL, outR);
  }

  void reset() {
    _pinkB0 = 0.0;
    _pinkB1 = 0.0;
    _pinkB2 = 0.0;
    _gustPhase = 0.0;
    _whistleBandpass1 = 0.0;
    _whistleBandpass2 = 0.0;
  }
}

// ============================================================================
// 2. GENERATOR TERKOTU BĘBENKA PRZY P = 0 W
// ============================================================================

/// Adapter generatora zapadek bębenka [FreehubRatchetGenerator] aktywowany ściśle przy $P = 0\text{ W}$.
class FreehubCoastingGenerator {
  final FreehubRatchetGenerator _inner = FreehubRatchetGenerator();

  /// Zwraca znormalizowaną intensywność pracy bębenka [0.0, 1.0].
  static double computeIntensity(SoundscapeTelemetry telemetry) {
    if (!telemetry.isFreewheeling) return 0.0;
    return (telemetry.speedKmh / 55.0).clamp(0.15, 1.0);
  }

  AudioStereoFrame processSample({
    required SoundscapeTelemetry telemetry,
    required double dt,
  }) {
    final bool freewheeling = telemetry.isFreewheeling;
    final adaptedTelemetry = CyclingAudioTelemetry(
      speedKmh: telemetry.speedKmh,
      cadenceRpm: freewheeling ? 0.0 : math.max(70.0, telemetry.cadenceRpm),
      powerWatts: freewheeling ? 0.0 : math.max(25.0, telemetry.powerWatts),
      freehubTeethCount: telemetry.freehubTeethCount,
      lateralRoadOffsetMeters: telemetry.lateralRoadOffsetMeters,
    );

    return _inner.processSample(telemetry: adaptedTelemetry, dt: dt);
  }

  void reset() {
    _inner.reset();
  }
}

// ============================================================================
// 3. GENERATOR ODDECHU KOLARZA POWYŻEJ PROGU LT2
// ============================================================================

/// Syntezator głębokiego oddechu kolarza aktywowany powyżej progu mleczanowego $LT_2$.
class RiderBreathingGenerator {
  final math.Random _rng;
  double _breathCyclePhase = 0.0;
  double _envelope = 0.0;
  double _inhaleLpState = 0.0;
  double _exhaleLpState = 0.0;
  double _throatPhase = 0.0;

  RiderBreathingGenerator({int seed = 17203}) : _rng = math.Random(seed);

  /// Oblicza docelową intensywność ciężkiego oddechu powyżej $LT_2$ w zakresie [0.0, 1.0].
  static double computeTargetIntensity(SoundscapeTelemetry telemetry) {
    if (!telemetry.isAboveLt2 || telemetry.lt2PowerWatts <= 0.0) {
      return 0.0;
    }
    final excessRatio =
        (telemetry.powerWatts - telemetry.lt2PowerWatts) /
            (telemetry.lt2PowerWatts * 0.45);
    return excessRatio.clamp(0.08, 1.0);
  }

  AudioStereoFrame processSample({
    required SoundscapeTelemetry telemetry,
    required double dt,
  }) {
    final target = computeTargetIntensity(telemetry);

    if (target > _envelope) {
      _envelope = math.min(target, _envelope + (dt * 1.4));
    } else {
      _envelope = math.max(target, _envelope - (dt * 0.9));
    }

    if (_envelope <= 0.002) {
      return AudioStereoFrame.zero;
    }

    // Częstotliwość oddechów: od ~0.62 Hz (37/min) tuż nad LT2 do ~1.05 Hz (63/min) przy wysiłku max
    final hrBoost = ((telemetry.heartRateBpm - 165.0) / 35.0).clamp(0.0, 0.2);
    final breathFreqHz = (0.62 + (_envelope * 0.36) + hrBoost).clamp(0.55, 1.15);

    _breathCyclePhase = (_breathCyclePhase + (breathFreqHz * dt)) % 1.0;

    final white = (_rng.nextDouble() * 2.0) - 1.0;
    double sample;

    if (_breathCyclePhase < 0.42) {
      // Wdech (krótszy, wyższy szum nosowo-ustny)
      final p = _breathCyclePhase / 0.42;
      final shape = math.sin(p * math.pi);
      _inhaleLpState += (white - _inhaleLpState) * (dt * 4200.0);
      final bp = _inhaleLpState * 0.65 + (white - _inhaleLpState) * 0.35;
      sample = bp * shape * 0.62;
    } else {
      // Wydech (dłuższy, głębszy szum gardłowy)
      final p = (_breathCyclePhase - 0.42) / 0.58;
      final shape = math.sin(p * math.pi) * (1.0 - (0.25 * p));
      _exhaleLpState += (white - _exhaleLpState) * (dt * 1650.0);
      _throatPhase = (_throatPhase + (2.0 * math.pi * 195.0 * dt)) % (2.0 * math.pi);
      final throatTone = math.sin(_throatPhase) * 0.14;
      sample = (_exhaleLpState * 0.85 + throatTone) * shape * 0.82;
    }

    final out = (sample * _envelope * 0.68).clamp(-1.0, 1.0);
    return AudioStereoFrame(out, out);
  }

  void reset() {
    _breathCyclePhase = 0.0;
    _envelope = 0.0;
    _inhaleLpState = 0.0;
    _exhaleLpState = 0.0;
    _throatPhase = 0.0;
  }
}

// ============================================================================
// 4. GENERATOR DZWONKÓW KRÓW (ALPINE COWBELLS)
// ============================================================================

/// Syntezator alpejskich dzwonków krów słyszalnych na podjazdach i przed premiami KOM.
class CowbellAtmosphereGenerator {
  final math.Random _rng;
  double _triggerTimer = 0.0;
  double _nextInterval = 0.38;
  double _bellAmp = 0.0;
  double _phase1 = 0.0;
  double _phase2 = 0.0;
  double _phase3 = 0.0;
  double _bellFreq1 = 920.0;
  double _bellFreq2 = 1380.0;
  double _pan = 0.0;

  CowbellAtmosphereGenerator({int seed = 17204}) : _rng = math.Random(seed);

  /// Oblicza intensywność dzwonków krów [0.0, 1.0] zależnie od bliskości KOM i terenu górskiego.
  static double computeIntensity(SoundscapeTelemetry telemetry) {
    final komDist = telemetry.distanceToNextKomMeters;
    double komFactor = 0.0;
    if (komDist != null && komDist >= 0.0 && komDist <= 1500.0) {
      komFactor = (1.0 - (komDist / 1500.0)).clamp(0.0, 1.0);
      if (komDist <= 500.0) {
        komFactor = 0.55 + (0.45 * (1.0 - (komDist / 500.0)));
      }
    }

    final mountainFactor =
        (telemetry.gradientPercent >= 4.0 || telemetry.altitudeMeters >= 1100.0)
            ? 0.45
            : 0.0;

    return math.max(komFactor, mountainFactor).clamp(0.0, 1.0);
  }

  AudioStereoFrame processSample({
    required SoundscapeTelemetry telemetry,
    required double dt,
  }) {
    final intensity = computeIntensity(telemetry);
    if (intensity <= 0.01 && _bellAmp <= 0.002) {
      return AudioStereoFrame.zero;
    }

    if (intensity > 0.01) {
      _triggerTimer += dt;
      if (_triggerTimer >= _nextInterval) {
        _triggerTimer = 0.0;
        // Im bliżej szczytu KOM, tym gęstsze uderzenia dzwonków
        _nextInterval = (0.48 - (intensity * 0.26)) + (_rng.nextDouble() * 0.24);
        _bellAmp = (0.45 + (0.55 * intensity)) * (0.75 + _rng.nextDouble() * 0.25);

        // Różne rozmiary dzwonków alpejskich (od niskiego 680 Hz po wysoki 1180 Hz)
        final base = 680.0 + (_rng.nextDouble() * 480.0);
        _bellFreq1 = base;
        _bellFreq2 = base * 1.48; // Nieharmoniczny alikwot blachy dzwonka
        _phase1 = 0.0;
        _phase2 = 0.0;
        _phase3 = 0.0;
        _pan = (_rng.nextDouble() * 1.2) - 0.6;
      }
    }

    if (_bellAmp <= 0.002) {
      return AudioStereoFrame.zero;
    }

    _bellAmp *= math.exp(-dt * 18.0);
    _phase1 = (_phase1 + (2.0 * math.pi * _bellFreq1 * dt)) % (2.0 * math.pi);
    _phase2 = (_phase2 + (2.0 * math.pi * _bellFreq2 * dt)) % (2.0 * math.pi);
    _phase3 = (_phase3 + (2.0 * math.pi * (_bellFreq1 * 2.15) * dt)) % (2.0 * math.pi);

    final metallic = (math.sin(_phase1) * 0.55) +
        (math.sin(_phase2) * 0.32) +
        (math.sin(_phase3) * 0.13);
    final raw = metallic * _bellAmp * 0.58;

    final gainL = (0.5 - (_pan * 0.4)).clamp(0.1, 0.9);
    final gainR = (0.5 + (_pan * 0.4)).clamp(0.1, 0.9);

    return AudioStereoFrame(raw * gainL, raw * gainR);
  }

  void reset() {
    _triggerTimer = 0.0;
    _nextInterval = 0.38;
    _bellAmp = 0.0;
    _phase1 = 0.0;
    _phase2 = 0.0;
    _phase3 = 0.0;
    _pan = 0.0;
  }
}

// ============================================================================
// 5. GENERATOR WRZAWY TŁUMU NA OSTATNICH 500 M PRZED KOM I METĄ
// ============================================================================

/// Syntezator wrzawy tłumu narastającej na ostatnich 500 m przed premią KOM i metą.
class CrowdSurgeGenerator {
  static const double surgeZoneMeters = 500.0;

  final math.Random _rng;
  double _formantPhase1 = 0.0;
  double _formantPhase2 = 0.0;
  double _barrierTimer = 0.0;
  double _barrierAmp = 0.0;
  double _barrierPhase = 0.0;
  double _lpL = 0.0;
  double _lpR = 0.0;

  CrowdSurgeGenerator({int seed = 17205}) : _rng = math.Random(seed);

  /// Oblicza narastającą intensywność tłumu [0.0, 1.0] na ostatnich 500 m przed KOM lub metą.
  static double computeSurgeIntensity(SoundscapeTelemetry telemetry) {
    final dist = telemetry.nearestLandmarkDistanceMeters;
    if (dist > surgeZoneMeters) {
      // Poza strefą 500 m delikatny szmer oddalający się do 1200 m
      if (dist >= 1200.0) return 0.0;
      final farProgress = 1.0 - ((dist - surgeZoneMeters) / 700.0);
      return (farProgress * 0.14).clamp(0.0, 0.14);
    }

    // Ostatnie 500 m: płynne, wyraźne narastanie od 0.22 aż do 1.00 na linii KOM/mety
    final progress = (1.0 - (dist / surgeZoneMeters)).clamp(0.0, 1.0);
    return (0.22 + (0.78 * math.pow(progress, 1.15))).clamp(0.0, 1.0);
  }

  AudioStereoFrame processSample({
    required SoundscapeTelemetry telemetry,
    required double dt,
  }) {
    final intensity = computeSurgeIntensity(telemetry);
    if (intensity <= 0.005) {
      return AudioStereoFrame.zero;
    }

    final noiseL = (_rng.nextDouble() * 2.0) - 1.0;
    final noiseR = (_rng.nextDouble() * 2.0) - 1.0;

    _formantPhase1 = (_formantPhase1 + (2.0 * math.pi * 430.0 * dt)) % (2.0 * math.pi);
    _formantPhase2 = (_formantPhase2 + (2.0 * math.pi * 890.0 * dt)) % (2.0 * math.pi);

    final formantMod =
        0.55 + (0.25 * math.sin(_formantPhase1)) + (0.20 * math.sin(_formantPhase2));

    _lpL += (noiseL - _lpL) * (dt * 3200.0);
    _lpR += (noiseR - _lpR) * (dt * 3200.0);

    final roarL = _lpL * formantMod;
    final roarR = _lpR * formantMod;

    // Uderzenia w barierki reklamowe w strefie <= 500 m
    double barrierSample = 0.0;
    if (telemetry.nearestLandmarkDistanceMeters <= surgeZoneMeters) {
      _barrierTimer += dt;
      if (_barrierTimer >= 0.34) {
        _barrierTimer = 0.0;
        _barrierAmp = 0.65 * intensity;
        _barrierPhase = 0.0;
      }
      if (_barrierAmp > 0.005) {
        _barrierAmp *= math.exp(-dt * 42.0);
        _barrierPhase =
            (_barrierPhase + (2.0 * math.pi * 148.0 * dt)) % (2.0 * math.pi);
        barrierSample = math.sin(_barrierPhase) * _barrierAmp;
      }
    }

    final outL = ((roarL * 0.72 + barrierSample * 0.45) * intensity).clamp(-1.0, 1.0);
    final outR = ((roarR * 0.72 + barrierSample * 0.45) * intensity).clamp(-1.0, 1.0);

    return AudioStereoFrame(outL, outR);
  }

  void reset() {
    _formantPhase1 = 0.0;
    _formantPhase2 = 0.0;
    _barrierTimer = 0.0;
    _barrierAmp = 0.0;
    _barrierPhase = 0.0;
    _lpL = 0.0;
    _lpR = 0.0;
  }
}

// ============================================================================
// 6. STAN I KONTROLER MIKSERA (SOUNDSCAPE MIXER CONTROLLER)
// ============================================================================

/// Niemutowalny stan miksera pejzażu dźwiękowego [SoundscapeMixerController].
class SoundscapeMixerState {
  final double masterVolume;
  final double windVolume;
  final double freehubVolume;
  final double breathingVolume;
  final double cowbellsVolume;
  final double crowdVolume;
  final bool isMuted;
  final SoundscapeTelemetry lastTelemetry;
  final SoundscapeLayerIntensities layerIntensities;
  final AudioStereoBuffer? lastBuffer;

  const SoundscapeMixerState({
    this.masterVolume = 0.90,
    this.windVolume = 0.85,
    this.freehubVolume = 0.85,
    this.breathingVolume = 0.80,
    this.cowbellsVolume = 0.75,
    this.crowdVolume = 0.95,
    this.isMuted = false,
    this.lastTelemetry = const SoundscapeTelemetry(),
    this.layerIntensities = SoundscapeLayerIntensities.zero,
    this.lastBuffer,
  });

  bool get isAudible => !isMuted && masterVolume > 0.0;

  double channelVolume(SoundscapeChannel channel) {
    switch (channel) {
      case SoundscapeChannel.wind:
        return windVolume;
      case SoundscapeChannel.freehub:
        return freehubVolume;
      case SoundscapeChannel.breathing:
        return breathingVolume;
      case SoundscapeChannel.cowbells:
        return cowbellsVolume;
      case SoundscapeChannel.crowd:
        return crowdVolume;
    }
  }

  SoundscapeMixerState copyWith({
    double? masterVolume,
    double? windVolume,
    double? freehubVolume,
    double? breathingVolume,
    double? cowbellsVolume,
    double? crowdVolume,
    bool? isMuted,
    SoundscapeTelemetry? lastTelemetry,
    SoundscapeLayerIntensities? layerIntensities,
    AudioStereoBuffer? lastBuffer,
  }) {
    return SoundscapeMixerState(
      masterVolume: masterVolume ?? this.masterVolume,
      windVolume: windVolume ?? this.windVolume,
      freehubVolume: freehubVolume ?? this.freehubVolume,
      breathingVolume: breathingVolume ?? this.breathingVolume,
      cowbellsVolume: cowbellsVolume ?? this.cowbellsVolume,
      crowdVolume: crowdVolume ?? this.crowdVolume,
      isMuted: isMuted ?? this.isMuted,
      lastTelemetry: lastTelemetry ?? this.lastTelemetry,
      layerIntensities: layerIntensities ?? this.layerIntensities,
      lastBuffer: lastBuffer ?? this.lastBuffer,
    );
  }
}

/// Provider Riverpod dla [SoundscapeMixerController] zsynchronizowany z [gameSettingsProvider].
final soundscapeMixerProvider =
    StateNotifierProvider<SoundscapeMixerController, SoundscapeMixerState>((ref) {
  final initialSettings = ref.read(gameSettingsProvider);
  final controller = SoundscapeMixerController(initialSettings: initialSettings);

  ref.listen<GameSettings>(gameSettingsProvider, (_, next) {
    controller.syncWithSettings(next);
  });

  return controller;
});

/// Kontroler wielokanałowego miksera pejzażu dźwiękowego wyścigu kolarskiego.
///
/// Łączy 5 warstw proceduralnych:
/// 1. Szum wiatru zależny od kwadratu prędkości ($v^2$).
/// 2. Terkot bębenka wolnobiegu aktywny przy $P = 0\text{ W}$.
/// 3. Oddech kolarza powyżej progu mleczanowego $LT_2$.
/// 4. Dzwonki krów przy podjazdach i premiach górskich KOM.
/// 5. Wrzawę tłumu narastającą na ostatnich 500 m przed premią KOM i metą.
class SoundscapeMixerController extends StateNotifier<SoundscapeMixerState> {
  final int sampleRate;

  final WindNoiseV2Generator windGenerator;
  final FreehubCoastingGenerator freehubGenerator;
  final RiderBreathingGenerator breathingGenerator;
  final CowbellAtmosphereGenerator cowbellGenerator;
  final CrowdSurgeGenerator crowdGenerator;

  /// Opcjonalny callback otrzymujący zsyntetyzowane bufory audio.
  void Function(AudioStereoBuffer buffer)? onBufferReady;

  SoundscapeMixerController({
    this.sampleRate = 44100,
    GameSettings? initialSettings,
    WindNoiseV2Generator? windGenerator,
    FreehubCoastingGenerator? freehubGenerator,
    RiderBreathingGenerator? breathingGenerator,
    CowbellAtmosphereGenerator? cowbellGenerator,
    CrowdSurgeGenerator? crowdGenerator,
    this.onBufferReady,
  })  : windGenerator = windGenerator ?? WindNoiseV2Generator(),
        freehubGenerator = freehubGenerator ?? FreehubCoastingGenerator(),
        breathingGenerator = breathingGenerator ?? RiderBreathingGenerator(),
        cowbellGenerator = cowbellGenerator ?? CowbellAtmosphereGenerator(),
        crowdGenerator = crowdGenerator ?? CrowdSurgeGenerator(),
        super(
          initialSettings == null
              ? const SoundscapeMixerState()
              : SoundscapeMixerState(
                  masterVolume: initialSettings.soundVolume.clamp(0.0, 1.0),
                  windVolume:
                      (0.85 * initialSettings.raceEnvironmentVolume).clamp(0.0, 1.0),
                  freehubVolume:
                      (0.85 * initialSettings.raceEnvironmentVolume).clamp(0.0, 1.0),
                  breathingVolume:
                      (0.80 * initialSettings.raceEnvironmentVolume).clamp(0.0, 1.0),
                  cowbellsVolume:
                      (0.75 * initialSettings.crowdAtmosphereVolume).clamp(0.0, 1.0),
                  crowdVolume:
                      (0.95 * initialSettings.crowdAtmosphereVolume).clamp(0.0, 1.0),
                ),
        );

  /// Synchronizuje głośności miksera z ustawieniami gry [GameSettings].
  void syncWithSettings(GameSettings settings) {
    state = state.copyWith(
      masterVolume: settings.soundVolume.clamp(0.0, 1.0),
      windVolume: (0.85 * settings.raceEnvironmentVolume).clamp(0.0, 1.0),
      freehubVolume: (0.85 * settings.raceEnvironmentVolume).clamp(0.0, 1.0),
      breathingVolume: (0.80 * settings.raceEnvironmentVolume).clamp(0.0, 1.0),
      cowbellsVolume: (0.75 * settings.crowdAtmosphereVolume).clamp(0.0, 1.0),
      crowdVolume: (0.95 * settings.crowdAtmosphereVolume).clamp(0.0, 1.0),
    );
  }

  /// Aktualizuje bieżącą telemetrię i przelicza natężenie warstw pejzażu.
  void updateTelemetry(SoundscapeTelemetry telemetry) {
    state = state.copyWith(
      lastTelemetry: telemetry,
      layerIntensities: computeLayerIntensities(telemetry),
    );
  }

  /// Wylicza bieżące znormalizowane intensywności wszystkich 5 warstw dla telemetrii.
  SoundscapeLayerIntensities computeLayerIntensities(SoundscapeTelemetry telemetry) {
    return SoundscapeLayerIntensities(
      wind: (WindNoiseV2Generator.computeQuadraticGain(telemetry.apparentAirSpeedMs) /
              1.5)
          .clamp(0.0, 1.0),
      freehub: FreehubCoastingGenerator.computeIntensity(telemetry),
      breathing: RiderBreathingGenerator.computeTargetIntensity(telemetry),
      cowbells: CowbellAtmosphereGenerator.computeIntensity(telemetry),
      crowd: CrowdSurgeGenerator.computeSurgeIntensity(telemetry),
    );
  }

  void setMasterVolume(double volume) {
    state = state.copyWith(masterVolume: volume.clamp(0.0, 1.0));
  }

  void setMuted(bool muted) {
    state = state.copyWith(isMuted: muted);
  }

  void setChannelVolume(SoundscapeChannel channel, double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    switch (channel) {
      case SoundscapeChannel.wind:
        state = state.copyWith(windVolume: clamped);
        break;
      case SoundscapeChannel.freehub:
        state = state.copyWith(freehubVolume: clamped);
        break;
      case SoundscapeChannel.breathing:
        state = state.copyWith(breathingVolume: clamped);
        break;
      case SoundscapeChannel.cowbells:
        state = state.copyWith(cowbellsVolume: clamped);
        break;
      case SoundscapeChannel.crowd:
        state = state.copyWith(crowdVolume: clamped);
        break;
    }
  }

  /// Przetwarza pojedynczą ramkę stereo dla podanej (lub aktualnej) telemetrii.
  AudioStereoFrame processFrame(
    double dt, {
    SoundscapeTelemetry? telemetry,
  }) {
    if (!state.isAudible) {
      return AudioStereoFrame.zero;
    }

    final tel = telemetry ?? state.lastTelemetry;

    final wind = windGenerator.processSample(telemetry: tel, dt: dt);
    final freehub = freehubGenerator.processSample(telemetry: tel, dt: dt);
    final breathing = breathingGenerator.processSample(telemetry: tel, dt: dt);
    final cowbells = cowbellGenerator.processSample(telemetry: tel, dt: dt);
    final crowd = crowdGenerator.processSample(telemetry: tel, dt: dt);

    final mixL = ((wind.left * state.windVolume) +
            (freehub.left * state.freehubVolume) +
            (breathing.left * state.breathingVolume) +
            (cowbells.left * state.cowbellsVolume) +
            (crowd.left * state.crowdVolume)) *
        state.masterVolume;

    final mixR = ((wind.right * state.windVolume) +
            (freehub.right * state.freehubVolume) +
            (breathing.right * state.breathingVolume) +
            (cowbells.right * state.cowbellsVolume) +
            (crowd.right * state.crowdVolume)) *
        state.masterVolume;

    return AudioStereoFrame(_softClip(mixL), _softClip(mixR));
  }

  /// Syntetyzuje ciągły bufor stereo PCM float dla zadanego czasu trwania.
  AudioStereoBuffer generateAudioBuffer({
    Duration duration = const Duration(milliseconds: 250),
    SoundscapeTelemetry? telemetry,
  }) {
    final activeTelemetry = telemetry ?? state.lastTelemetry;
    if (telemetry != null) {
      updateTelemetry(telemetry);
    }

    final int totalFrames =
        math.max(1, (duration.inMicroseconds * sampleRate / 1000000.0).round());
    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final double dt = 1.0 / sampleRate;

    for (int i = 0; i < totalFrames; i++) {
      final frame = processFrame(dt, telemetry: activeTelemetry);
      left[i] = frame.left;
      right[i] = frame.right;
    }

    final buffer = AudioStereoBuffer(
      left: left,
      right: right,
      sampleRate: sampleRate,
    );
    state = state.copyWith(lastBuffer: buffer);
    onBufferReady?.call(buffer);
    return buffer;
  }

  /// Generuje plik WAV (44-bajtowy nagłówek RIFF + PCM16 stereo).
  Uint8List generateWavBytes({
    Duration duration = const Duration(milliseconds: 250),
    SoundscapeTelemetry? telemetry,
  }) {
    return generateAudioBuffer(duration: duration, telemetry: telemetry)
        .toWavBytes();
  }

  /// Generuje Data URI Base64 dla HTML5 / WebAudio.
  String generateDataUri({
    Duration duration = const Duration(milliseconds: 250),
    SoundscapeTelemetry? telemetry,
  }) {
    return generateAudioBuffer(duration: duration, telemetry: telemetry)
        .toDataUri();
  }

  /// Resetuje oscylatory i filtry wszystkich pięciu warstw pejzażu dźwiękowego.
  void reset() {
    windGenerator.reset();
    freehubGenerator.reset();
    breathingGenerator.reset();
    cowbellGenerator.reset();
    crowdGenerator.reset();
  }

  double _softClip(double x) {
    if (x < -1.5) return -1.0;
    if (x > 1.5) return 1.0;
    return x * (27.0 + (x * x)) / (27.0 + (9.0 * x * x));
  }
}
