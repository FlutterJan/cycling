// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import '../../models/race/stage_segment.dart';
import '../events/race_radio_generator.dart';
import 'procedural_cycling_audio_engine.dart';

export 'procedural_cycling_audio_engine.dart' show AudioStereoBuffer, AudioStereoFrame;

/// Typ syntetyzowanego sygnału dźwiękowego (Radio Wyścigowe lub Komputer Rowerowy).
enum RadioSoundType {
  /// Otwarcie kanału radiowego ("Krrr-beep!" - squelch burst + roger tone).
  squelchRogerBeep,

  /// Zamknięcie nadawania radiowego ("Krrr-click" - squelch tail).
  squelchClose,

  /// Wjazd na kategoryzowany podjazd (ClimbPro / KOM Ascent Start Beep - wznoszące arpeggio piezo).
  climbProAlert,

  /// Spadek zapasu energii beztlenowej W' poniżej 15% (Critical W' Depletion Alarm - podwójny pisk alarmowy).
  wPrimeCriticalAlarm,

  /// Zdobycie szczytu premii górskiej lub lotnej (KOM Summit Chime).
  komSummitChime,
}

/// Syntezator sygnałów dźwiękowych Radia Wyścigowego i Komputera Rowerowego.
///
/// Generuje fale dźwiękowe bezpośrednio w pamięci jako [AudioStereoBuffer] (oraz pliki WAV):
/// - Dźwięk otwarcia krótkofalówki ("Krrr-beep!"): szum bramki RF + jednotonowy/dwutonowy Roger Beep.
/// - Sygnały piezo komputera rowerowego (Garmin/Wahoo style): trójtonowy ClimbPro oraz alarm pustego W'.
class RaceRadioAudioSynthesizer {
  /// Częstotliwość próbkowania w Hz (standard 44100 Hz).
  final int sampleRate;

  const RaceRadioAudioSynthesizer({
    this.sampleRate = 44100,
  });

  /// 1. Dźwięk krótkofalówki ("Krrr-beep!")
  ///
  /// Składa się z:
  /// - Szum otwarcia bramki radiowej (RF Squelch Burst, ~55 ms) z lekkim przesterowaniem analogowym.
  /// - Dwutonowy "Roger Beep" (1750 Hz + 2150 Hz, ~95 ms) o czystej charakterystyce radiowej.
  AudioStereoBuffer generateRadioSquelchBeep({double volume = 0.9}) {
    final int squelchFrames = (0.055 * sampleRate).round();
    final int beeperFrames = (0.095 * sampleRate).round();
    final int pauseFrames = (0.010 * sampleRate).round();
    final int totalFrames = squelchFrames + pauseFrames + beeperFrames;

    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;

    final rng = math.Random(1337); // Deterministyczny generator szumu radiowego
    double filterState = 0.0;

    // Faza 1: Szum otwarcia krótkofalówki ("Krrr" / "Khhh")
    for (int i = 0; i < squelchFrames; i++) {
      final t = i * dt;
      final whiteNoise = (rng.nextDouble() * 2.0) - 1.0;
      // Filtr pasmowy IIR skupiony wokół 3.2 kHz
      filterState += (whiteNoise - filterState) * (dt * 18000.0);
      final bandpassNoise = (whiteNoise - filterState);

      // Modulacja przydźwiękiem nośnej 115 Hz (vintage analog RF flutter)
      final flutter = 0.75 + (0.25 * math.sin(2.0 * math.pi * 115.0 * t));
      // Lekkie analogowe nasycenie (overdrive)
      final saturatedNoise = _softSaturate(bandpassNoise * 1.8 * flutter);

      // Obwiednia wejściowa i wyjściowa squelcha
      final envelope = math.sin((i / squelchFrames) * math.pi);
      final sample = saturatedNoise * envelope * volume * 0.85;

      left[i] = sample;
      right[i] = sample;
    }

    // Faza 2: Pauza między szumem a tonem (10 ms)
    for (int i = 0; i < pauseFrames; i++) {
      final idx = squelchFrames + i;
      left[idx] = 0.0;
      right[idx] = 0.0;
    }

    // Faza 3: Roger Beep ("Beep!") - klasyczny ton PTT (1750 Hz z podharmoniczną 2150 Hz)
    final startBeepIdx = squelchFrames + pauseFrames;
    const toneFreq1 = 1750.0;
    const toneFreq2 = 2150.0;

    for (int i = 0; i < beeperFrames; i++) {
      final t = i * dt;
      final idx = startBeepIdx + i;

      // Obwiednia tonu (szybki atak 4ms, wykładniczy zanik na końcu)
      double envelope;
      final progress = i / beeperFrames;
      if (progress < 0.05) {
        envelope = progress / 0.05;
      } else if (progress > 0.8) {
        envelope = (1.0 - progress) / 0.2;
      } else {
        envelope = 1.0;
      }

      final tone = (math.sin(2.0 * math.pi * toneFreq1 * t) * 0.7) +
          (math.sin(2.0 * math.pi * toneFreq2 * t) * 0.3);

      final sample = tone * envelope * volume * 0.80;
      left[idx] = sample;
      right[idx] = sample;
    }

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// 2. Zamknięcie kanału radiowego ("Krrr-click" - Squelch Tail)
  ///
  /// Krótki trzask rozłączenia przycisku nadawania PTT (~35 ms).
  AudioStereoBuffer generateRadioCloseSquelch({double volume = 0.7}) {
    final int totalFrames = (0.035 * sampleRate).round();
    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;

    final rng = math.Random(42);
    for (int i = 0; i < totalFrames; i++) {
      final progress = i / totalFrames;
      final whiteNoise = (rng.nextDouble() * 2.0) - 1.0;
      final clickImpulse = math.sin(2.0 * math.pi * 820.0 * (i * dt));

      final envelope = math.exp(-progress * 8.0);
      final sample = ((whiteNoise * 0.6) + (clickImpulse * 0.4)) * envelope * volume;

      left[i] = sample;
      right[i] = sample;
    }

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// 3. Sygnał komputera rowerowego: Wjazd na kategoryzowany podjazd (ClimbPro Ascent Start Beep)
  ///
  /// Charakterystyczny trójtonowy wznoszący sygnał piezo-buzzera (Garmin/Wahoo style):
  /// - Ton 1: 1568 Hz (G6) przez 55 ms
  /// - Ton 2: 2093 Hz (C7) przez 55 ms
  /// - Ton 3: 2637 Hz (E7) przez 85 ms
  AudioStereoBuffer generateClimbProAlertBeep({double volume = 0.85}) {
    final int tone1Frames = (0.055 * sampleRate).round();
    final int tone2Frames = (0.055 * sampleRate).round();
    final int tone3Frames = (0.085 * sampleRate).round();
    final int gapFrames = (0.008 * sampleRate).round();

    final int totalFrames = tone1Frames + gapFrames + tone2Frames + gapFrames + tone3Frames;
    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;

    int writeIdx = 0;

    void synthesizePiezoTone(double freqHz, int frames) {
      for (int i = 0; i < frames; i++) {
        final t = i * dt;
        final progress = i / frames;

        // Obwiednia piezo buzzer (zaokrąglone krawędzie zapobiegające trzaskom)
        double env;
        if (progress < 0.08) {
          env = progress / 0.08;
        } else if (progress > 0.85) {
          env = (1.0 - progress) / 0.15;
        } else {
          env = 1.0;
        }

        // Kształt fali piezo: sinusoida domieszkowana 20% trzeciej harmonicznej (3*f)
        final wave = (math.sin(2.0 * math.pi * freqHz * t) * 0.8) +
            (math.sin(2.0 * math.pi * (freqHz * 3.0) * t) * 0.2);

        final sample = wave * env * volume * 0.9;
        left[writeIdx] = sample;
        right[writeIdx] = sample;
        writeIdx++;
      }
    }

    void synthesizeGap(int frames) {
      for (int i = 0; i < frames; i++) {
        left[writeIdx] = 0.0;
        right[writeIdx] = 0.0;
        writeIdx++;
      }
    }

    // Wznoszące arpeggio: G6 -> C7 -> E7
    synthesizePiezoTone(1567.98, tone1Frames);
    synthesizeGap(gapFrames);
    synthesizePiezoTone(2093.00, tone2Frames);
    synthesizeGap(gapFrames);
    synthesizePiezoTone(2637.02, tone3Frames);

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// 4. Sygnał komputera rowerowego: Spadek energii W' poniżej 15% (Critical W' Depletion Alarm)
  ///
  /// Ostrzegawczy, pulsujący podwójny pisk alarmowy (dwa opadające ćwierknięcia 2550 Hz -> 1900 Hz).
  AudioStereoBuffer generateWPrimeCriticalAlarmBeep({double volume = 0.95}) {
    final int chirpFrames = (0.065 * sampleRate).round();
    final int gapFrames = (0.040 * sampleRate).round();
    final int totalFrames = (chirpFrames * 2) + gapFrames;

    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;

    int writeIdx = 0;

    void synthesizeChirp() {
      double phase = 0.0;
      for (int i = 0; i < chirpFrames; i++) {
        final progress = i / chirpFrames;
        // Opadająca częstotliwość alarmowa (2550 Hz -> 1900 Hz)
        final currentFreq = 2550.0 - (progress * 650.0);
        phase += 2.0 * math.pi * currentFreq * dt;

        // Ostry, przerywany ton alarmowy
        double env;
        if (progress < 0.1) {
          env = progress / 0.1;
        } else {
          env = math.exp(-progress * 3.5);
        }

        // Kwadratowa domieszka dla ostrości alarmu
        final rawTone = math.sin(phase);
        final buzzTone = rawTone > 0.0 ? 0.85 : -0.85;
        final mixedTone = (rawTone * 0.7) + (buzzTone * 0.3);

        final sample = mixedTone * env * volume;
        left[writeIdx] = sample;
        right[writeIdx] = sample;
        writeIdx++;
      }
    }

    synthesizeChirp();
    // Przerwa między piskami
    for (int i = 0; i < gapFrames; i++) {
      left[writeIdx] = 0.0;
      right[writeIdx] = 0.0;
      writeIdx++;
    }
    synthesizeChirp();

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// 5. Sygnał zdobycia szczytu premii górskiej lub lotnej (KOM Summit Chime)
  ///
  /// Dwutonowy dzwonek akordu C7 -> G7 (2093 Hz -> 3136 Hz).
  AudioStereoBuffer generateKomSummitChime({double volume = 0.85}) {
    final int tone1Frames = (0.070 * sampleRate).round();
    final int tone2Frames = (0.130 * sampleRate).round();
    final int totalFrames = tone1Frames + tone2Frames;

    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;

    int writeIdx = 0;

    void synthesizeTone(double freqHz, int frames) {
      for (int i = 0; i < frames; i++) {
        final t = i * dt;
        final progress = i / frames;
        final env = math.exp(-progress * 4.0);
        final sample = math.sin(2.0 * math.pi * freqHz * t) * env * volume * 0.85;

        left[writeIdx] = sample;
        right[writeIdx] = sample;
        writeIdx++;
      }
    }

    synthesizeTone(2093.0, tone1Frames);
    synthesizeTone(3135.96, tone2Frames);

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  double _softSaturate(double x) {
    if (x < -1.0) return -1.0;
    if (x > 1.0) return 1.0;
    return x - (0.33 * x * x * x);
  }
}

// ============================================================================
// FORMATOWANIE TEKSTU DLA SYNTEZATORA MOWY (TTS FORMATTER)
// ============================================================================

/// Formater komunikatów Radia Wyścigowego przygotowujący autentyczną treść dla silników Text-To-Speech (TTS).
class RadioSpeechFormat {
  RadioSpeechFormat._();

  /// Formatuje treść komunikatu dla lektora TTS w stylu Radio Tour lub DS Comms.
  static String formatForTts(RaceRadioMessage message) {
    final cleanMsg = cleanTextForTts(message.message);

    switch (message.channel) {
      case RadioChannel.radioTour:
        return 'Radio Tour. $cleanMsg';
      case RadioChannel.directeurSportif:
        return 'Dyrektor sportowy. $cleanMsg';
      case RadioChannel.motoTimekeeper:
        return 'Motocykl sędziowski. $cleanMsg';
      case RadioChannel.serviceNeutral:
        return 'Serwis neutralny. $cleanMsg';
    }
  }

  /// Oczyszcza tekst z nawiasów, skrótów i przygotowuje wymowę dla polskiego i francuskiego lektora TTS.
  static String cleanTextForTts(String rawText) {
    var text = rawText;

    // Rozwinięcie nawiasów i oznaczeń kolarzy
    text = text.replaceAll('[', '').replaceAll(']', '');

    // Rozwinięcie popularnych skrótów kolarskich
    text = text.replaceAll(RegExp(r'\bkm\b', caseSensitive: false), 'kilometrów');
    text = text.replaceAll(RegExp(r'\bKOM\b', caseSensitive: false), 'premia górska');
    text = text.replaceAll(RegExp(r'\bHC\b', caseSensitive: false), 'kategoria poza klasyfikacją');
    text = text.replaceAll(RegExp(r'\bDS\b', caseSensitive: false), 'dyrektor sportowy');
    text = text.replaceAll(RegExp(r'\bDNF\b', caseSensitive: false), 'wycofanie z wyścigu');
    text = text.replaceAll(RegExp(r'\bW\b'), 'Wat');

    // Usunięcie wielokrotnych spacji i wykrzykników
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }
}

// ============================================================================
// DETEKTOR I DYSPOZYTOR ZDARZEŃ RADIOWYCH I KOMPUTERA ROWEROWEGO
// ============================================================================

/// Sprawdza, czy dany komunikat radiowy jest priorytetowy i wymaga dźwięku krótkofalówki ("Krrr-beep!").
class RaceRadioEventDetector {
  RaceRadioEventDetector._();

  /// Zwraca true, jeśli komunikat to:
  /// - Atak rywala
  /// - Kraksa na trasie
  /// - 1 km do mety (Flamme Rouge)
  /// - Poważny defekt mechaniczny
  /// - Priorytet urgent lub warning
  static bool shouldTriggerRadioBeep(RaceRadioMessage message) {
    if (message.priority == RadioPriority.urgent || message.priority == RadioPriority.warning) {
      return true;
    }

    final lower = message.message.toLowerCase();

    // 1. Atak rywala / faworyta
    if (lower.contains('atak') || lower.contains('zaatakował') || lower.contains('odjazd')) {
      return true;
    }

    // 2. Kraksa / upadek
    if (lower.contains('kraksa') || lower.contains('chute') || lower.contains('upadek') || lower.contains('leży')) {
      return true;
    }

    // 3. 1 km do mety / Flamme Rouge
    if (lower.contains('flamme rouge') || lower.contains('1 km do mety') || lower.contains('ostatni kilometr')) {
      return true;
    }

    // 4. Defekt sprzętowy
    if (lower.contains('defekt') || lower.contains('przebita') || lower.contains('guma')) {
      return true;
    }

    return false;
  }
}

/// Śledzi stan telemetryczny kolarza i generuje powiadomienia komputera rowerowego (ClimbPro i W' < 15%).
class BikeComputerAlertTracker {
  int _lastSegmentIndex = -1;
  double _lastWPrimePercent = 1.0;
  double _wPrimeAlarmCooldownSeconds = 0.0;

  /// Czas odnowienia alarmu W' w sekundach (zapobiega nieustannemu piszczeniu przy pustej baterii).
  static const double wPrimeAlarmCooldownInterval = 18.0;

  /// Przetwarza bieżącą telemetrię i zwraca listę sygnałów dźwiękowych komputera do odegrania.
  List<RadioSoundType> processTelemetry({
    required double currentKm,
    required double wPrimePercent,
    required List<StageSegment> segments,
    double dtSeconds = 0.5,
  }) {
    final alerts = <RadioSoundType>[];

    // Aktualizacja zegara cooldown
    if (_wPrimeAlarmCooldownSeconds > 0.0) {
      _wPrimeAlarmCooldownSeconds = math.max(0.0, _wPrimeAlarmCooldownSeconds - dtSeconds);
    }

    // 1. Sprawdzenie wjazdu na kategoryzowany podjazd (ClimbPro / KOM Ascent Start)
    if (segments.isNotEmpty) {
      StageSegment? currentSeg;
      for (final seg in segments) {
        if (currentKm >= seg.startKm && currentKm <= seg.endKm) {
          currentSeg = seg;
          break;
        }
      }

      if (currentSeg != null && currentSeg.index != _lastSegmentIndex) {
        final bool isClimb = _isCategorizedClimb(currentSeg.sprintOrKomClassification);
        if (isClimb) {
          alerts.add(RadioSoundType.climbProAlert);
        }
        _lastSegmentIndex = currentSeg.index;
      }
    }

    // 2. Sprawdzenie spadku zapasu energii beztlenowej W' poniżej 15% (Critical W' Depletion)
    final bool enteredCriticalZone = _lastWPrimePercent >= 0.15 && wPrimePercent < 0.15;
    final bool stayedInCriticalZoneAfterCooldown = wPrimePercent < 0.15 && _wPrimeAlarmCooldownSeconds <= 0.0;

    if (enteredCriticalZone || stayedInCriticalZoneAfterCooldown) {
      alerts.add(RadioSoundType.wPrimeCriticalAlarm);
      _wPrimeAlarmCooldownSeconds = wPrimeAlarmCooldownInterval;
    }

    _lastWPrimePercent = wPrimePercent;
    return alerts;
  }

  bool _isCategorizedClimb(SegmentClassification classification) {
    return classification == SegmentClassification.cat4 ||
        classification == SegmentClassification.cat3 ||
        classification == SegmentClassification.cat2 ||
        classification == SegmentClassification.cat1 ||
        classification == SegmentClassification.horsCategorie;
  }

  void reset() {
    _lastSegmentIndex = -1;
    _lastWPrimePercent = 1.0;
    _wPrimeAlarmCooldownSeconds = 0.0;
  }
}

// ============================================================================
// KONTROLER GŁÓWNY RADIA I POWIADOMIEŃ AUDIO (RACE RADIO CONTROLLER)
// ============================================================================

/// Wpis w historii odtworzonych powiadomień audio wyścigu.
class PlayedAudioAlertRecord {
  final DateTime timestamp;
  final RadioSoundType soundType;
  final String description;
  final String? spokenTtsText;

  const PlayedAudioAlertRecord({
    required this.timestamp,
    required this.soundType,
    required this.description,
    this.spokenTtsText,
  });
}

/// Główny kontroler dźwięków Radia Wyścigowego i Komputera Rowerowego.
///
/// Zarządza odtwarzaniem syntetyzowanych sygnałów audio ("Krrr-beep!", ClimbPro, W' Alert)
/// oraz integruje się z systemem komunikatów wyścigowych i syntezą mowy TTS.
class RaceRadioAudioController {
  final RaceRadioAudioSynthesizer synthesizer;
  final BikeComputerAlertTracker bikeComputerTracker = BikeComputerAlertTracker();

  // Flagi konfiguracyjne
  bool isRadioBeepEnabled = true;
  bool isBikeComputerBeepEnabled = true;
  bool isTtsVoiceEnabled = true;
  double radioVolume = 0.90;
  double computerBeepVolume = 0.85;

  // Historia odtworzonych komunikatów
  final List<PlayedAudioAlertRecord> _history = [];

  // Opcjonalne callbacki zewnętrzne (np. odtwarzacz audio w Flutter / Web Speech API)
  void Function(AudioStereoBuffer buffer, RadioSoundType soundType)? onAudioBufferGenerated;
  void Function(String speechText)? onTtsRequested;

  RaceRadioAudioController({
    RaceRadioAudioSynthesizer? synthesizer,
  }) : synthesizer = synthesizer ?? const RaceRadioAudioSynthesizer();

  List<PlayedAudioAlertRecord> get history => List.unmodifiable(_history);

  /// Przetwarza nowy komunikat z Radia Wyścigowego.
  ///
  /// Jeśli komunikat dotyczy ataku, kraksy, bramy Flamme Rouge (1 km) lub defektu,
  /// generuje i odtwarza dźwięk krótkofalówki ("Krrr-beep!") oraz opcjonalnie wywołuje lektora TTS.
  AudioStereoBuffer? handleRadioMessage(RaceRadioMessage message) {
    if (!isRadioBeepEnabled) return null;

    final shouldBeep = RaceRadioEventDetector.shouldTriggerRadioBeep(message);
    if (!shouldBeep) return null;

    // 1. Generowanie charakterystycznego dźwięku "Krrr-beep!"
    final squelchBeep = synthesizer.generateRadioSquelchBeep(volume: radioVolume);
    onAudioBufferGenerated?.call(squelchBeep, RadioSoundType.squelchRogerBeep);

    // 2. Formatowanie i dyspozycja tekstu dla syntezatora mowy (TTS)
    String? ttsText;
    if (isTtsVoiceEnabled) {
      ttsText = RadioSpeechFormat.formatForTts(message);
      onTtsRequested?.call(ttsText);
    }

    _history.add(PlayedAudioAlertRecord(
      timestamp: DateTime.now(),
      soundType: RadioSoundType.squelchRogerBeep,
      description: message.message,
      spokenTtsText: ttsText,
    ));

    return squelchBeep;
  }

  /// Przetwarza telemetrię kolarza i generuje sygnały komputera rowerowego (ClimbPro, W' < 15%).
  List<AudioStereoBuffer> handleBikeComputerTelemetry({
    required double currentKm,
    required double wPrimePercent,
    required List<StageSegment> segments,
    double dtSeconds = 0.5,
  }) {
    if (!isBikeComputerBeepEnabled) return const [];

    final triggeredAlerts = bikeComputerTracker.processTelemetry(
      currentKm: currentKm,
      wPrimePercent: wPrimePercent,
      segments: segments,
      dtSeconds: dtSeconds,
    );

    final buffers = <AudioStereoBuffer>[];

    for (final alertType in triggeredAlerts) {
      AudioStereoBuffer buffer;
      String desc;

      switch (alertType) {
        case RadioSoundType.climbProAlert:
          buffer = synthesizer.generateClimbProAlertBeep(volume: computerBeepVolume);
          desc = 'Wjazd na podjazd kategoryzowany (ClimbPro Alert)';
          break;
        case RadioSoundType.wPrimeCriticalAlarm:
          buffer = synthesizer.generateWPrimeCriticalAlarmBeep(volume: computerBeepVolume);
          desc = 'Krytyczny spadek energii beztlenowej W\' ponizej 15%';
          break;
        case RadioSoundType.komSummitChime:
          buffer = synthesizer.generateKomSummitChime(volume: computerBeepVolume);
          desc = 'Zdobycie szczytu premii gorskiej';
          break;
        case RadioSoundType.squelchRogerBeep:
        case RadioSoundType.squelchClose:
          buffer = synthesizer.generateRadioCloseSquelch(volume: computerBeepVolume);
          desc = 'Sygnal radiowy';
          break;
      }

      onAudioBufferGenerated?.call(buffer, alertType);
      buffers.add(buffer);

      _history.add(PlayedAudioAlertRecord(
        timestamp: DateTime.now(),
        soundType: alertType,
        description: desc,
      ));
    }

    return buffers;
  }

  /// Resetuje filtry, stan detektorów i historię komunikatów.
  void reset() {
    bikeComputerTracker.reset();
    _history.clear();
  }
}
