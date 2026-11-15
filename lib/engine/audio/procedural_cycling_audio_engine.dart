// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';

/// Telemetria stanu kolarza i wyścigu przekazywana do syntezatora dźwięku proceduralnego.
class CyclingAudioTelemetry {
  /// Prędkość chwilowa kolarza w km/h.
  final double speedKmh;

  /// Kadencja pedałowania w obrotach na minutę (RPM).
  final double cadenceRpm;

  /// Chwilowa moc kolarza w Watach [W].
  final double powerWatts;

  /// Nachylenie drogi w procentach [%] (dodatnie = podjazd, ujemne = zjazd).
  final double gradientPercent;

  /// Rodzaj nawierzchni szosy (asfalt, bruk sektory 1-5, szuter Strade).
  final SegmentSurfaceType surfaceType;

  /// Aktualne warunki atmosferyczne (słońce, deszcz, ulewa, wiatr).
  final WeatherCondition weatherCondition;

  /// Dystans pozostały do linii mety w metrach [m].
  final double distanceRemainingMeters;

  /// Czy dźwięk dotyczy bezpośrednio zawodnika gracza (kamera FPV / Chase).
  final bool isPlayerRider;

  /// Wysokość profilu stożka kół karbonowych w milimetrach [mm] (np. 35, 50, 60, 80).
  final double rimDepthMm;

  /// Liczba zębów w pierścieniu zapadek bębenka piasty (np. DT Swiss Ratchet 36T / 54T).
  final int freehubTeethCount;

  /// Liczba kolarzy w bezpośrednim otoczeniu (dla odgłosów peletonu).
  final int riderCountNearby;

  /// Pozycja boczna na szosie [-3.5m do +3.5m] (dla panoramy stereo).
  final double lateralRoadOffsetMeters;

  const CyclingAudioTelemetry({
    this.speedKmh = 0.0,
    this.cadenceRpm = 0.0,
    this.powerWatts = 0.0,
    this.gradientPercent = 0.0,
    this.surfaceType = SegmentSurfaceType.smoothAsphalt,
    this.weatherCondition = WeatherCondition.sunny,
    this.distanceRemainingMeters = 5000.0,
    this.isPlayerRider = true,
    this.rimDepthMm = 55.0,
    this.freehubTeethCount = 54,
    this.riderCountNearby = 1,
    this.lateralRoadOffsetMeters = 0.0,
  });

  /// Czy kolarz przestaje pedałować i jedzie z biegu jałowego (freewheeling / coasting).
  bool get isCoasting => (cadenceRpm < 15.0 || powerWatts < 20.0) && speedKmh > 3.5;

  /// Częstotliwość obrotu kół 700c (obwód ~2.13m) w Hz.
  double get wheelRotationalFrequencyHz {
    if (speedKmh <= 0.1) return 0.0;
    final speedMs = speedKmh / 3.6;
    return speedMs / 2.13;
  }

  /// Prędkość kolarza w metrach na sekundę [m/s].
  double get speedMs => speedKmh / 3.6;

  CyclingAudioTelemetry copyWith({
    double? speedKmh,
    double? cadenceRpm,
    double? powerWatts,
    double? gradientPercent,
    SegmentSurfaceType? surfaceType,
    WeatherCondition? weatherCondition,
    double? distanceRemainingMeters,
    bool? isPlayerRider,
    double? rimDepthMm,
    int? freehubTeethCount,
    int? riderCountNearby,
    double? lateralRoadOffsetMeters,
  }) {
    return CyclingAudioTelemetry(
      speedKmh: speedKmh ?? this.speedKmh,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      powerWatts: powerWatts ?? this.powerWatts,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      surfaceType: surfaceType ?? this.surfaceType,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      distanceRemainingMeters: distanceRemainingMeters ?? this.distanceRemainingMeters,
      isPlayerRider: isPlayerRider ?? this.isPlayerRider,
      rimDepthMm: rimDepthMm ?? this.rimDepthMm,
      freehubTeethCount: freehubTeethCount ?? this.freehubTeethCount,
      riderCountNearby: riderCountNearby ?? this.riderCountNearby,
      lateralRoadOffsetMeters: lateralRoadOffsetMeters ?? this.lateralRoadOffsetMeters,
    );
  }

  /// Fabryka demonstracyjna do testów i podglądu.
  factory CyclingAudioTelemetry.demoSprint({double speedKmh = 64.5}) {
    return CyclingAudioTelemetry(
      speedKmh: speedKmh,
      cadenceRpm: 112.0,
      powerWatts: 1150.0,
      gradientPercent: -1.0,
      surfaceType: SegmentSurfaceType.smoothAsphalt,
      weatherCondition: WeatherCondition.sunny,
      distanceRemainingMeters: 220.0,
      isPlayerRider: true,
      rimDepthMm: 65.0,
    );
  }

  factory CyclingAudioTelemetry.demoDescentCoasting({double speedKmh = 72.0}) {
    return CyclingAudioTelemetry(
      speedKmh: speedKmh,
      cadenceRpm: 0.0,
      powerWatts: 0.0,
      gradientPercent: -8.5,
      surfaceType: SegmentSurfaceType.smoothAsphalt,
      weatherCondition: WeatherCondition.sunny,
      distanceRemainingMeters: 14200.0,
      isPlayerRider: true,
      rimDepthMm: 60.0,
    );
  }

  factory CyclingAudioTelemetry.demoCobblestones({double speedKmh = 46.0}) {
    return CyclingAudioTelemetry(
      speedKmh: speedKmh,
      cadenceRpm: 92.0,
      powerWatts: 440.0,
      gradientPercent: 0.2,
      surfaceType: SegmentSurfaceType.cobblestonesSector5,
      weatherCondition: WeatherCondition.sunny,
      distanceRemainingMeters: 85000.0,
      isPlayerRider: true,
      rimDepthMm: 45.0,
    );
  }

  factory CyclingAudioTelemetry.demoRainStorm({double speedKmh = 42.0}) {
    return CyclingAudioTelemetry(
      speedKmh: speedKmh,
      cadenceRpm: 88.0,
      powerWatts: 340.0,
      gradientPercent: 1.5,
      surfaceType: SegmentSurfaceType.smoothAsphalt,
      weatherCondition: WeatherCondition.heavyStorm,
      distanceRemainingMeters: 45000.0,
      isPlayerRider: true,
    );
  }
}

/// Pojedyncza ramka stereo próbek audio [-1.0, 1.0].
class AudioStereoFrame {
  final double left;
  final double right;

  const AudioStereoFrame(this.left, this.right);

  static const AudioStereoFrame zero = AudioStereoFrame(0.0, 0.0);
}

/// Bufor zsyntetyzowanych próbek stereo audio z eksportem do PCM16, WAV i WebAudio Data URI.
class AudioStereoBuffer {
  /// Lewy kanał audio (próbki znormalizowane 32-bit float [-1.0, 1.0]).
  final Float32List left;

  /// Prawy kanał audio (próbki znormalizowane 32-bit float [-1.0, 1.0]).
  final Float32List right;

  /// Częstotliwość próbkowania w Hz (np. 44100).
  final int sampleRate;

  AudioStereoBuffer({
    required this.left,
    required this.right,
    this.sampleRate = 44100,
  }) : assert(left.length == right.length, 'Kanały stereo muszą mieć identyczną długość');

  /// Liczba ramek (próbek na kanał).
  int get frameCount => left.length;

  /// Czas trwania bufora w sekundach.
  double get durationSeconds => frameCount / sampleRate;

  /// Generuje bufor z przeplotem 16-bitowych próbek ze znakiem (L, R, L, R...).
  Int16List toInterleavedPcm16() {
    final count = frameCount;
    final pcm = Int16List(count * 2);
    for (int i = 0; i < count; i++) {
      final l = (left[i].clamp(-1.0, 1.0) * 32767.0).round();
      final r = (right[i].clamp(-1.0, 1.0) * 32767.0).round();
      pcm[i * 2] = l;
      pcm[i * 2 + 1] = r;
    }
    return pcm;
  }

  /// Generuje binarny kontener WAV zgodny ze specyfikacją RIFF (44-bajtowy nagłówek + PCM16 stereo).
  Uint8List toWavBytes() {
    final pcm16 = toInterleavedPcm16();
    final dataSize = pcm16.lengthInBytes;
    final totalSize = 44 + dataSize;
    final bytes = Uint8List(totalSize);
    final bdata = ByteData.view(bytes.buffer);

    // 1. RIFF Chunk Descriptor
    bytes.setRange(0, 4, 'RIFF'.codeUnits);
    bdata.setUint32(4, 36 + dataSize, Endian.little);
    bytes.setRange(8, 12, 'WAVE'.codeUnits);

    // 2. "fmt " Sub-chunk
    bytes.setRange(12, 16, 'fmt '.codeUnits);
    bdata.setUint32(16, 16, Endian.little); // Rozmiar nagłówka fmt (16 dla PCM)
    bdata.setUint16(20, 1, Endian.little); // Format 1 = PCM (nieskompresowany)
    bdata.setUint16(22, 2, Endian.little); // Liczba kanałów = 2 (stereo)
    bdata.setUint32(24, sampleRate, Endian.little); // Częstotliwość próbkowania
    bdata.setUint32(28, sampleRate * 2 * 2, Endian.little); // Byte rate (SampleRate * NumChannels * BitsPerSample/8)
    bdata.setUint16(32, 2 * 2, Endian.little); // Block align (NumChannels * BitsPerSample/8)
    bdata.setUint16(34, 16, Endian.little); // Bity na próbkę (16-bit)

    // 3. "data" Sub-chunk
    bytes.setRange(36, 40, 'data'.codeUnits);
    bdata.setUint32(40, dataSize, Endian.little);

    // Kopiowanie danych próbek PCM
    final pcmBytes = Uint8List.view(pcm16.buffer);
    bytes.setRange(44, totalSize, pcmBytes);

    return bytes;
  }

  /// Generuje URI danych Base64 ('data:audio/wav;base64,...') kompatybilne z HTML5 Audio / WebAudio.
  String toDataUri() {
    final wavBytes = toWavBytes();
    final base64String = base64Encode(wavBytes);
    return 'data:audio/wav;base64,$base64String';
  }
}

// ============================================================================
// 1. GENERATOR SZUMU KÓŁ KARBONOWYCH (AERO WHOOSH)
// ============================================================================

/// Syntezator aerodynamicznego szumu kół z wysokim stożkiem karbonowym (Aero Whoosh).
///
/// Przy prędkościach powyżej 38-40 km/h powietrze opływające wirujące koła
/// i widelec roweru generuje charakterystyczny, pulsujący dźwięk ("whoosh-whoosh-whoosh")
/// o częstotliwości modulacji równej obrotom koła oraz szum turbulencji rosnący z kwadratem prędkości.
class CarbonWheelAeroGenerator {
  double _phaseRotation = 0.0;
  double _phaseResonance = 0.0;
  double _noiseState = 0.0;
  double _filterBandpassState1 = 0.0;
  double _filterBandpassState2 = 0.0;

  /// Generuje pojedynczą próbkę szumu aerodynamicznego dla podanej telemetrii.
  AudioStereoFrame processSample({
    required CyclingAudioTelemetry telemetry,
    required double dt,
  }) {
    final speed = telemetry.speedKmh;
    // Poniżej 35 km/h dźwięk stożków karbonowych jest praktycznie niesłyszalny
    if (speed < 35.0) {
      _advancePhase(speed, dt);
      return AudioStereoFrame.zero;
    }

    // Współczynnik narastania powyżej 40 km/h (funkcja płynnego startu)
    final speedOver40 = math.max(0.0, speed - 38.0);
    final aeroIntensity = math.pow((speedOver40 / 35.0).clamp(0.0, 1.8), 1.6).toDouble();

    // Wpływ wysokości stożka obręczy (35mm -> łagodny, 60mm -> wyraźny, 80mm -> głębokie dudnienie)
    final rimFactor = math.pow((telemetry.rimDepthMm / 55.0).clamp(0.5, 1.6), 1.3).toDouble();

    // 1. Częstotliwość obrotu koła w Hz (dla modulacji amplitudy)
    final rotFreqHz = telemetry.wheelRotationalFrequencyHz;
    _phaseRotation = (_phaseRotation + (2.0 * math.pi * rotFreqHz * dt)) % (2.0 * math.pi);

    // 2. Głęboka modulacja AM wywołana przejściem wentyla, szprych i naklejki przez widelec
    final pulseEnvelope = 0.65 + (0.35 * math.sin(_phaseRotation));

    // 3. Częstotliwość rezonansowa pudła karbonowego obręczy (220 Hz przy 40 km/h do 580 Hz przy 80 km/h)
    final resonanceFreqHz = (220.0 + (speedOver40 * 7.5)).clamp(180.0, 750.0);
    _phaseResonance = (_phaseResonance + (2.0 * math.pi * resonanceFreqHz * dt)) % (2.0 * math.pi);

    // 4. Szum różowy/turbulentny opływu powietrza
    final whiteNoise = (math.Random().nextDouble() * 2.0) - 1.0;
    _noiseState = (_noiseState * 0.94) + (whiteNoise * 0.06);

    // Prosty cyfrowy filtr pasmowo-przepustowy (IIR Bandpass) dla rezonansu obręczy
    final f = (2.0 * math.sin(math.pi * resonanceFreqHz * dt)).clamp(0.01, 0.45);
    const q = 0.42;
    _filterBandpassState1 += f * _filterBandpassState2;
    _filterBandpassState2 += f * (_noiseState - _filterBandpassState1 - (q * _filterBandpassState2));
    final rimResonanceSample = _filterBandpassState2;

    // 5. Czysta fala sinusoidalna pudła rezonansowego
    final subTone = math.sin(_phaseResonance) * 0.28;

    // 6. Szum wysokoczęstotliwościowy rozcinania powietrza przez szprychy aero (aerodynamic hiss)
    final aeroHiss = whiteNoise * 0.25 * math.pow((speed / 45.0).clamp(0.0, 2.0), 2.2);

    final rawAero = ((rimResonanceSample * 0.85) + subTone + aeroHiss) * pulseEnvelope * aeroIntensity * rimFactor;

    // Lekka panorama stereo zróżnicowana poprzecznym położeniem roweru
    final pan = (telemetry.lateralRoadOffsetMeters / 4.0).clamp(-0.4, 0.4);
    final leftGain = 0.5 - (pan * 0.4);
    final rightGain = 0.5 + (pan * 0.4);

    return AudioStereoFrame(rawAero * leftGain, rawAero * rightGain);
  }

  void _advancePhase(double speedKmh, double dt) {
    final rotFreqHz = speedKmh > 0 ? (speedKmh / 3.6) / 2.13 : 0.0;
    _phaseRotation = (_phaseRotation + (2.0 * math.pi * rotFreqHz * dt)) % (2.0 * math.pi);
  }

  void reset() {
    _phaseRotation = 0.0;
    _phaseResonance = 0.0;
    _noiseState = 0.0;
    _filterBandpassState1 = 0.0;
    _filterBandpassState2 = 0.0;
  }
}

// ============================================================================
// 2. GENERATOR TERKOTU BĘBENKA PIASTY (FREEHUB RATCHET)
// ============================================================================

/// Syntezator metalicznego dźwięku zapadek bębenka piasty (Freehub Ratchet Buzz).
///
/// Aktywowany wyłącznie, gdy kolarz przestaje pedałować (coasting) na zjazdach,
/// przed zakrętami lub w ucieczce. Częstotliwość klików jest ściśle powiązana
/// z prędkością kolarza i liczbą zębów w pierścieniu zapadek (np. 54T).
class FreehubRatchetGenerator {
  double _clickTimer = 0.0;
  double _toothImpulsePhase = 0.0;
  double _activeImpulseAmplitude = 0.0;
  double _coastingEnvelope = 0.0; // Płynne włączanie/wyłączanie terkotu

  /// Częstotliwość rezonansowa uderzenia metalowych zapadek o pierścień [Hz] (~3400 Hz).
  final double pawlResonanceFreqHz = 3450.0;

  AudioStereoFrame processSample({
    required CyclingAudioTelemetry telemetry,
    required double dt,
  }) {
    final bool coasting = telemetry.isCoasting;

    // Płynna obwiednia ataku i zaniku (zapobiega trzaskom audio przy natychmiastowym wciśnięciu pedałów)
    if (coasting) {
      _coastingEnvelope = math.min(1.0, _coastingEnvelope + (dt * 18.0));
    } else {
      _coastingEnvelope = math.max(0.0, _coastingEnvelope - (dt * 25.0));
    }

    if (_coastingEnvelope <= 0.001) {
      _toothImpulsePhase = 0.0;
      _activeImpulseAmplitude = 0.0;
      return AudioStereoFrame.zero;
    }

    // 1. Częstotliwość klikania zapadek: f_clicks = f_rot * liczba_zębów
    final rotFreqHz = telemetry.wheelRotationalFrequencyHz;
    final ratchetFreqHz = (rotFreqHz * telemetry.freehubTeethCount).clamp(10.0, 1100.0);
    final secondsPerClick = 1.0 / ratchetFreqHz;

    _clickTimer += dt;
    if (_clickTimer >= secondsPerClick) {
      _clickTimer -= secondsPerClick;
      // Inicjalizacja nowego uderzenia zapadki (ostry mechaniczny impuls z rezonansem)
      _activeImpulseAmplitude = 1.0;
      _toothImpulsePhase = 0.0;
    }

    double sample = 0.0;
    if (_activeImpulseAmplitude > 0.001) {
      // Wykładniczy zanik impulsu uderzenia ząbka (czas zaniku ~1.2 ms)
      _activeImpulseAmplitude *= math.exp(-dt * 850.0);
      _toothImpulsePhase += 2.0 * math.pi * pawlResonanceFreqHz * dt;

      // Złożenie podstawowego tonu rezonansu zapadki z podharmoniczną korpusu piasty
      final primaryClick = math.sin(_toothImpulsePhase);
      final bodyResonance = math.sin(_toothImpulsePhase * 0.45) * 0.4;
      sample = (primaryClick + bodyResonance) * _activeImpulseAmplitude;
    }

    final out = sample * _coastingEnvelope * 0.88;
    // Bębenek znajduje się po prawej stronie osi tylnego koła (napęd)
    return AudioStereoFrame(out * 0.42, out * 0.58);
  }

  void reset() {
    _clickTimer = 0.0;
    _toothImpulsePhase = 0.0;
    _activeImpulseAmplitude = 0.0;
    _coastingEnvelope = 0.0;
  }
}

// ============================================================================
// 3. GENERATOR JAZDY PO BRUKU I SZUTERZE (COBBLESTONE RUMBLE & CHATTER)
// ============================================================================

/// Syntezator wstrząsów, uderzeń o kostkę brukową i drgań łańcucha (Cobblestone Pavé & Gravel).
///
/// Odzwierciedla jazdę po sektorach brukowych (Paris-Roubaix) oraz szutrach (Strade Bianche).
/// Generuje potężne niskie dudnienie ramy oraz metaliczne odgłosy podskakującego łańcucha (chain slap).
class CobblestoneRumbleGenerator {
  double _rumbleFilterState = 0.0;
  double _chainSlapTimer = 0.0;
  double _chainSlapAmplitude = 0.0;
  double _chainSlapPhase = 0.0;

  AudioStereoFrame processSample({
    required CyclingAudioTelemetry telemetry,
    required double dt,
  }) {
    final surfaceSeverity = _getSurfaceSeverity(telemetry.surfaceType);
    if (surfaceSeverity <= 0.01 || telemetry.speedKmh < 3.0) {
      return AudioStereoFrame.zero;
    }

    final speedFactor = (telemetry.speedKmh / 42.0).clamp(0.2, 1.8);
    final intensity = surfaceSeverity * speedFactor;

    // 1. Niskoczęstotliwościowe dudnienie szosy i ramy (45 Hz - 85 Hz)
    final rawNoise = (math.Random().nextDouble() * 2.0) - 1.0;
    // IIR Lowpass
    _rumbleFilterState += (rawNoise - _rumbleFilterState) * (dt * 360.0);
    final lowRumble = _rumbleFilterState * 1.35;

    // 2. Nieregularne uderzenia w krawędzie kostki brukowej (impulsy perkusyjne)
    // Szansa na uderzenie w pojedynczej próbce rośnie z prędkością
    final hitChance = (telemetry.speedMs / 0.14) * dt * surfaceSeverity;
    double bumpHit = 0.0;
    if (math.Random().nextDouble() < hitChance) {
      bumpHit = ((math.Random().nextDouble() * 2.0) - 1.0) * 0.85;
    }

    // 3. Szum i chrzęst drobnego szutru (specjalnie dla Strade Bianche)
    double gravelCrunch = 0.0;
    if (telemetry.surfaceType == SegmentSurfaceType.gravelStrade) {
      gravelCrunch = rawNoise * 0.45 * speedFactor;
    }

    // 4. Brzęczenie łańcucha i wózków przerzutki (Chain Slap)
    _chainSlapTimer += dt;
    if (_chainSlapTimer > (0.045 / surfaceSeverity) && math.Random().nextDouble() < 0.28) {
      _chainSlapTimer = 0.0;
      _chainSlapAmplitude = 0.75 * surfaceSeverity;
      _chainSlapPhase = 0.0;
    }

    double chainSlapSample = 0.0;
    if (_chainSlapAmplitude > 0.01) {
      _chainSlapAmplitude *= math.exp(-dt * 320.0);
      _chainSlapPhase += 2.0 * math.pi * 1850.0 * dt;
      chainSlapSample = math.sin(_chainSlapPhase) * _chainSlapAmplitude;
    }

    final out = (lowRumble + bumpHit + gravelCrunch + chainSlapSample) * intensity * 0.75;
    return AudioStereoFrame(out, out);
  }

  double _getSurfaceSeverity(SegmentSurfaceType surface) {
    switch (surface) {
      case SegmentSurfaceType.smoothAsphalt:
        return 0.0;
      case SegmentSurfaceType.roughAsphalt:
        return 0.18;
      case SegmentSurfaceType.concrete:
        return 0.12;
      case SegmentSurfaceType.gravelStrade:
        return 0.65;
      case SegmentSurfaceType.cobblestonesSector1:
        return 0.45;
      case SegmentSurfaceType.cobblestonesSector2:
        return 0.60;
      case SegmentSurfaceType.cobblestonesSector3:
        return 0.78;
      case SegmentSurfaceType.cobblestonesSector4:
        return 0.90;
      case SegmentSurfaceType.cobblestonesSector5:
        return 1.15; // Arenberg Forest - maksymalne wstrząsy
    }
  }

  void reset() {
    _rumbleFilterState = 0.0;
    _chainSlapTimer = 0.0;
    _chainSlapAmplitude = 0.0;
    _chainSlapPhase = 0.0;
  }
}

// ============================================================================
// 4. GENERATOR DESZCZU I PRYSKAJĄCEJ WODY (RAIN & TIRE SPRAY)
// ============================================================================

/// Syntezator odgłosów deszczu oraz syczącego strumienia wody spod kół na mokrej jezdni.
class RainAndWaterSprayGenerator {
  double _rainFilterState = 0.0;
  double _sprayFilterState = 0.0;

  AudioStereoFrame processSample({
    required CyclingAudioTelemetry telemetry,
    required double dt,
  }) {
    final rainIntensity = _getRainIntensity(telemetry.weatherCondition);
    if (rainIntensity <= 0.001) {
      return AudioStereoFrame.zero;
    }

    final whiteNoise = (math.Random().nextDouble() * 2.0) - 1.0;

    // 1. Spadający deszcz (filtrowany szum różowy o miękkiej charakterystyce)
    _rainFilterState += (whiteNoise - _rainFilterState) * (dt * 1200.0);
    final rainDropSound = _rainFilterState * 0.42 * rainIntensity;

    // 2. Szum wody rozcinanej i wyrzucanej przez opony (Wet Tire Spray)
    // Natężenie rośnie gwałtownie z prędkością kolarza na mokrym asfalcie
    final speedFactor = (telemetry.speedKmh / 38.0).clamp(0.0, 2.2);
    _sprayFilterState += (whiteNoise - _sprayFilterState) * (dt * 4800.0);
    final spraySound = (_sprayFilterState - _rainFilterState) * 0.65 * speedFactor * rainIntensity;

    final out = (rainDropSound + spraySound) * 0.75;
    return AudioStereoFrame(out, out);
  }

  double _getRainIntensity(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.lightRain:
        return 0.45;
      case WeatherCondition.heavyStorm:
        return 1.0;
      case WeatherCondition.sunny:
      case WeatherCondition.overcast:
      case WeatherCondition.crosswindGale:
      case WeatherCondition.extremeHeat:
        return 0.0;
    }
  }

  void reset() {
    _rainFilterState = 0.0;
    _sprayFilterState = 0.0;
  }
}

// ============================================================================
// 5. GENERATOR WRZAWY KIBICÓW I FINISZU (CROWD ROAR & BARRIER BANGING)
// ============================================================================

/// Syntezator atmosfery kibiców przy trasie, eksplodującej w ostatnich 500 metrach do mety.
///
/// Generuje:
/// - Narastający ryk widowni (human crowd roar) o charakterystycznych formantach wokalnych.
/// - Rytmiczne uderzanie rękami w barierki reklamowe (hoardings banging: "BAM-BAM-BAM").
/// - Alpejskie dzwonki pasterskie (cowbells: typowy kolarski folklor).
class CrowdRoarGenerator {
  double _formantPhase1 = 0.0;
  double _formantPhase2 = 0.0;
  double _barrierTimer = 0.0;
  double _barrierAmplitude = 0.0;
  double _barrierPhase = 0.0;

  double _cowbellTimer = 0.0;
  double _cowbellAmplitude = 0.0;
  double _cowbellPhase1 = 0.0;
  double _cowbellPhase2 = 0.0;

  AudioStereoFrame processSample({
    required CyclingAudioTelemetry telemetry,
    required double dt,
  }) {
    final dist = telemetry.distanceRemainingMeters;
    // Poza strefą mety (> 1500m) kibice tworzą jedynie subtelne tło lub milkną
    if (dist > 1500.0) {
      return AudioStereoFrame.zero;
    }

    // Intensywność dopingu narasta gwałtownie w miarę zbliżania się do kreski (zwłaszcza < 500m)
    final double crowdIntensity;
    if (dist <= 500.0) {
      // Ostatnie 500 metrów: kulminacja wrzawy
      crowdIntensity = 0.45 + (0.55 * (1.0 - (dist / 500.0)).clamp(0.0, 1.0));
    } else {
      // 500m - 1500m: narastające brawa i okrzyki
      crowdIntensity = 0.45 * (1.0 - ((dist - 500.0) / 1000.0)).clamp(0.0, 1.0);
    }

    if (crowdIntensity <= 0.005) {
      return AudioStereoFrame.zero;
    }

    // 1. Wrzawa tłumu (formantowy szum harmoniczny imitujący ludzkie okrzyki)
    final noise = (math.Random().nextDouble() * 2.0) - 1.0;
    _formantPhase1 += 2.0 * math.pi * 420.0 * dt;
    _formantPhase2 += 2.0 * math.pi * 920.0 * dt;
    final vocalRoar = noise * (0.5 + (0.25 * math.sin(_formantPhase1)) + (0.25 * math.sin(_formantPhase2)));

    // 2. Uderzanie w barierki reklamowe (aktywne wyłącznie na ostatnich 500 metrach)
    double barrierSample = 0.0;
    if (dist <= 500.0) {
      _barrierTimer += dt;
      // Rytm uderzeń w barierki: ~2.8 Hz (kibice uderzają w rytm finiszującego sprintu)
      if (_barrierTimer >= 0.35) {
        _barrierTimer = 0.0;
        _barrierAmplitude = 0.9 * crowdIntensity;
        _barrierPhase = 0.0;
      }

      if (_barrierAmplitude > 0.01) {
        _barrierAmplitude *= math.exp(-dt * 45.0);
        _barrierPhase += 2.0 * math.pi * 145.0 * dt; // Metaliczne echo blachy barierki
        barrierSample = math.sin(_barrierPhase) * _barrierAmplitude;
      }
    }

    // 3. Kolarskie dzwonki (Cowbells)
    _cowbellTimer += dt;
    if (_cowbellTimer >= 0.55 && math.Random().nextDouble() < 0.4) {
      _cowbellTimer = 0.0;
      _cowbellAmplitude = 0.45 * crowdIntensity;
      _cowbellPhase1 = 0.0;
      _cowbellPhase2 = 0.0;
    }

    double cowbellSample = 0.0;
    if (_cowbellAmplitude > 0.01) {
      _cowbellAmplitude *= math.exp(-dt * 30.0);
      _cowbellPhase1 += 2.0 * math.pi * 1250.0 * dt;
      _cowbellPhase2 += 2.0 * math.pi * 1780.0 * dt;
      cowbellSample = ((math.sin(_cowbellPhase1) * 0.6) + (math.sin(_cowbellPhase2) * 0.4)) * _cowbellAmplitude;
    }

    final out = ((vocalRoar * 0.55) + (barrierSample * 0.65) + (cowbellSample * 0.4)) * crowdIntensity;
    return AudioStereoFrame(out, out);
  }

  void reset() {
    _formantPhase1 = 0.0;
    _formantPhase2 = 0.0;
    _barrierTimer = 0.0;
    _barrierAmplitude = 0.0;
    _barrierPhase = 0.0;
    _cowbellTimer = 0.0;
    _cowbellAmplitude = 0.0;
    _cowbellPhase1 = 0.0;
    _cowbellPhase2 = 0.0;
  }
}

// ============================================================================
// 6. GŁÓWNY SILNIK AUDIO I MIKSER WYŚCIGU (MASTER AUDIO ENGINE)
// ============================================================================

/// Kompleksowy syntezator i mikser dźwięku proceduralnego dla wyścigu kolarskiego.
///
/// Generuje fale audio w czasie rzeczywistym w pamięci bez jakichkolwiek zewnętrznych
/// plików audio MP3/WAV.
class ProceduralCyclingAudioEngine {
  /// Częstotliwość próbkowania w Hz (standard studyjny 44100 Hz).
  final int sampleRate;

  // Moduły syntezy dźwięku
  final CarbonWheelAeroGenerator aeroGenerator = CarbonWheelAeroGenerator();
  final FreehubRatchetGenerator freehubGenerator = FreehubRatchetGenerator();
  final CobblestoneRumbleGenerator cobbleGenerator = CobblestoneRumbleGenerator();
  final RainAndWaterSprayGenerator rainGenerator = RainAndWaterSprayGenerator();
  final CrowdRoarGenerator crowdGenerator = CrowdRoarGenerator();

  // Głośności poszczególnych ścieżek miksera (0.0 - 1.0)
  double masterVolume = 0.90;
  double aeroWhooshVolume = 0.85;
  double freehubVolume = 0.80;
  double cobbleVolume = 0.85;
  double rainVolume = 0.75;
  double crowdVolume = 0.95;

  /// Czy dźwięk jest całkowicie wyciszony.
  bool isMuted = false;

  /// Bieżąca telemetria audio
  CyclingAudioTelemetry _currentTelemetry = const CyclingAudioTelemetry();

  ProceduralCyclingAudioEngine({
    this.sampleRate = 44100,
  });

  /// Aktualna telemetria wyścigu.
  CyclingAudioTelemetry get telemetry => _currentTelemetry;

  /// Aktualizuje stan telemetrii napędzającej syntezator dźwięku.
  void updateTelemetry(CyclingAudioTelemetry telemetry) {
    _currentTelemetry = telemetry;
  }

  /// Resetuje oscylatory i filtry wszystkich generatorów dźwięku.
  void reset() {
    aeroGenerator.reset();
    freehubGenerator.reset();
    cobbleGenerator.reset();
    rainGenerator.reset();
    crowdGenerator.reset();
  }

  /// Syntetyzuje ciągły blok próbek stereo audio o zadanym czasie trwania.
  AudioStereoBuffer generateAudioBuffer({
    required Duration duration,
    CyclingAudioTelemetry? telemetry,
  }) {
    final activeTelemetry = telemetry ?? _currentTelemetry;
    final int totalFrames = (duration.inMicroseconds * sampleRate / 1000000.0).round();
    final leftChannel = Float32List(totalFrames);
    final rightChannel = Float32List(totalFrames);

    final double dt = 1.0 / sampleRate;

    for (int i = 0; i < totalFrames; i++) {
      final frame = processFrame(activeTelemetry, dt);
      leftChannel[i] = frame.left;
      rightChannel[i] = frame.right;
    }

    return AudioStereoBuffer(
      left: leftChannel,
      right: rightChannel,
      sampleRate: sampleRate,
    );
  }

  /// Syntetyzuje pojedynczą ramkę stereo, sumując i miksując wszystkie 5 generatorów.
  AudioStereoFrame processFrame(CyclingAudioTelemetry tel, double dt) {
    if (isMuted || masterVolume <= 0.0) {
      return AudioStereoFrame.zero;
    }

    // 1. Szum kół karbonowych (Aero Whoosh)
    final aero = aeroGenerator.processSample(telemetry: tel, dt: dt);

    // 2. Terkot zapadek piasty (Freehub Ratchet)
    final freehub = freehubGenerator.processSample(telemetry: tel, dt: dt);

    // 3. Bruk i szuter (Cobble Rumble & Chain Slap)
    final cobble = cobbleGenerator.processSample(telemetry: tel, dt: dt);

    // 4. Deszcz i woda z kół (Rain & Wet Spray)
    final rain = rainGenerator.processSample(telemetry: tel, dt: dt);

    // 5. Wrzawa kibiców i barierki (Crowd Roar)
    final crowd = crowdGenerator.processSample(telemetry: tel, dt: dt);

    // Miksowanie wielościeżkowe
    double mixLeft = (aero.left * aeroWhooshVolume) +
        (freehub.left * freehubVolume) +
        (cobble.left * cobbleVolume) +
        (rain.left * rainVolume) +
        (crowd.left * crowdVolume);

    double mixRight = (aero.right * aeroWhooshVolume) +
        (freehub.right * freehubVolume) +
        (cobble.right * cobbleVolume) +
        (rain.right * rainVolume) +
        (crowd.right * crowdVolume);

    mixLeft *= masterVolume;
    mixRight *= masterVolume;

    // Master Limiter / Soft-Clipping (nieliniowa funkcja tanh zapobiegająca przesterom cyfrowym)
    final limitedLeft = _softClip(mixLeft);
    final limitedRight = _softClip(mixRight);

    return AudioStereoFrame(limitedLeft, limitedRight);
  }

  /// Szybki algorytm miękkiego limitera (Soft-Clipping Tanh approximation).
  double _softClip(double x) {
    if (x < -1.5) return -1.0;
    if (x > 1.5) return 1.0;
    // Równanie Padé approximation dla tanh(x)
    return x * (27.0 + (x * x)) / (27.0 + (9.0 * x * x));
  }

  /// Generuje gotowy do odtworzenia lub zapisu plik WAV w postaci bajtów [Uint8List].
  Uint8List generateWavBytes({
    Duration duration = const Duration(seconds: 1),
    CyclingAudioTelemetry? telemetry,
  }) {
    final buffer = generateAudioBuffer(duration: duration, telemetry: telemetry);
    return buffer.toWavBytes();
  }

  /// Generuje URI danych Base64 ('data:audio/wav;base64,...') dla odtwarzaczy HTML5/WebAudio.
  String generateDataUri({
    Duration duration = const Duration(seconds: 1),
    CyclingAudioTelemetry? telemetry,
  }) {
    final buffer = generateAudioBuffer(duration: duration, telemetry: telemetry);
    return buffer.toDataUri();
  }
}
