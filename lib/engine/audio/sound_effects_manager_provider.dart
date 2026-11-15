// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/race/stage_segment.dart';
import '../../models/settings/game_settings.dart';
import '../../state/game_settings_notifier.dart';
import '../events/race_radio_generator.dart';
import 'procedural_cycling_audio_engine.dart';
import 'race_radio_tts_and_beeps.dart';

/// Katalog dźwięków interfejsu użytkownika (UI Haptics & Audio Feedback).
enum UiSoundEffect {
  /// Ciche kliknięcie przy przełączaniu zakładek i elementów nawigacji.
  tabClick('Kliknięcie zakładki'),

  /// Dźwięk podpisania kontraktu (pióro + pieczęć sukcesu).
  contractSigned('Podpisanie kontraktu'),

  /// Sygnał nowej wiadomości w skrzynce menedżera.
  inboxMessage('Nowa wiadomość w skrzynce'),

  /// Dźwięk klucza dynamometrycznego w garażu rowerowym.
  torqueWrenchClick('Klucz dynamometryczny'),

  /// Pojedynczy sygnał odliczania na rampie startowej TT ("Beep...").
  ttCountdownBeep('Odliczanie TT (Beep)'),

  /// Sygnał startu na rampie TT ("BEEP!").
  ttCountdownGo('Start TT (BEEP!)');

  final String label;
  const UiSoundEffect(this.label);
}

/// Wpis w dzienniku odtworzonych dźwięków (do diagnostyki i testów).
class SoundPlaybackRecord {
  final DateTime timestamp;
  final String category;
  final String label;
  final double effectiveVolume;
  final int frameCount;

  const SoundPlaybackRecord({
    required this.timestamp,
    required this.category,
    required this.label,
    required this.effectiveVolume,
    required this.frameCount,
  });
}

/// Syntezator subtelnych dźwięków interfejsu użytkownika (UI) i rampy startowej TT.
///
/// Generuje próbki audio proceduralnie w pamięci jako [AudioStereoBuffer] (44.1 kHz),
/// bez konieczności dołączania zewnętrznych plików dźwiękowych.
class UiSoundSynthesizer {
  final int sampleRate;

  const UiSoundSynthesizer({
    this.sampleRate = 44100,
  });

  /// Syntetyzuje wybrany dźwięk UI z uwzględnieniem głośności [0.0, 1.0].
  AudioStereoBuffer synthesize(
    UiSoundEffect effect, {
    double volume = 0.75,
  }) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    switch (effect) {
      case UiSoundEffect.tabClick:
        return generateTabClick(volume: clampedVolume);
      case UiSoundEffect.contractSigned:
        return generateContractSigned(volume: clampedVolume);
      case UiSoundEffect.inboxMessage:
        return generateInboxMessage(volume: clampedVolume);
      case UiSoundEffect.torqueWrenchClick:
        return generateTorqueWrenchClick(volume: clampedVolume);
      case UiSoundEffect.ttCountdownBeep:
        return generateTtCountdownBeep(volume: clampedVolume, isGoSignal: false);
      case UiSoundEffect.ttCountdownGo:
        return generateTtCountdownBeep(volume: clampedVolume, isGoSignal: true);
    }
  }

  /// 1. Ciche kliknięcie przy przełączaniu zakładek (~16 ms, miękki impuls karbonowy).
  AudioStereoBuffer generateTabClick({double volume = 0.75}) {
    final int totalFrames = (0.016 * sampleRate).round();
    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;

    for (int i = 0; i < totalFrames; i++) {
      final progress = i / totalFrames;
      final t = i * dt;
      final freq = 920.0 - (570.0 * progress);
      final env = math.exp(-progress * 11.0) * math.sin(math.min(1.0, progress * 10.0) * math.pi * 0.5);
      final sample = (math.sin(2.0 * math.pi * freq * t) * 0.65 +
              math.sin(2.0 * math.pi * (freq * 1.5) * t) * 0.15) *
          env *
          volume *
          0.45;
      left[i] = sample;
      right[i] = sample;
    }

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// 2. Dźwięk podpisania kontraktu (szelest pióra na papierze + ciepły akord C5/E5/G5).
  AudioStereoBuffer generateContractSigned({double volume = 0.75}) {
    final int penFrames = (0.055 * sampleRate).round();
    final int gapFrames = (0.015 * sampleRate).round();
    final int chimeFrames = (0.210 * sampleRate).round();
    final int totalFrames = penFrames + gapFrames + chimeFrames;

    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;
    final rng = math.Random(2026);

    double lpState = 0.0;
    for (int i = 0; i < penFrames; i++) {
      final progress = i / penFrames;
      final noise = (rng.nextDouble() * 2.0) - 1.0;
      lpState += (noise - lpState) * (dt * 9500.0);
      final bp = noise - lpState;
      final env = math.sin(progress * math.pi);
      final sample = bp * env * volume * 0.35;
      left[i] = sample * 0.95;
      right[i] = sample * 1.05;
    }

    final int chimeStart = penFrames + gapFrames;
    for (int i = 0; i < chimeFrames; i++) {
      final progress = i / chimeFrames;
      final t = i * dt;
      final attack = progress < 0.04 ? (progress / 0.04) : 1.0;
      final decay = math.exp(-progress * 4.5);
      final env = attack * decay;

      // Akord C-dur (C5 + E5 + G5)
      final c5 = math.sin(2.0 * math.pi * 523.25 * t) * 0.45;
      final e5 = math.sin(2.0 * math.pi * 659.25 * t) * 0.30;
      final g5 = math.sin(2.0 * math.pi * 783.99 * t) * 0.35;

      final sample = (c5 + e5 + g5) * env * volume * 0.55;
      left[chimeStart + i] = sample;
      right[chimeStart + i] = sample;
    }

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// 3. Sygnał nowej wiadomości w skrzynce (subtelny dwutonowy dzwonek E5 -> B5).
  AudioStereoBuffer generateInboxMessage({double volume = 0.75}) {
    final int note1Frames = (0.065 * sampleRate).round();
    final int gapFrames = (0.012 * sampleRate).round();
    final int note2Frames = (0.110 * sampleRate).round();
    final int totalFrames = note1Frames + gapFrames + note2Frames;

    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;

    void writeBellNote(int startOffset, int frames, double freqHz) {
      for (int i = 0; i < frames; i++) {
        final progress = i / frames;
        final t = i * dt;
        final attack = progress < 0.05 ? (progress / 0.05) : 1.0;
        final env = attack * math.exp(-progress * 5.2);
        final tone = math.sin(2.0 * math.pi * freqHz * t) * 0.8 +
            math.sin(2.0 * math.pi * (freqHz * 2.0) * t) * 0.12;
        final sample = tone * env * volume * 0.50;
        left[startOffset + i] = sample;
        right[startOffset + i] = sample;
      }
    }

    writeBellNote(0, note1Frames, 659.25); // E5
    writeBellNote(note1Frames + gapFrames, note2Frames, 987.77); // B5

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// 4. Dźwięk klucza dynamometrycznego w garażu rowerowym (metaliczne "klik-klak!" zapadki).
  AudioStereoBuffer generateTorqueWrenchClick({double volume = 0.75}) {
    final int click1Frames = (0.022 * sampleRate).round();
    final int pauseFrames = (0.014 * sampleRate).round();
    final int click2Frames = (0.018 * sampleRate).round();
    final int totalFrames = click1Frames + pauseFrames + click2Frames;

    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;
    final rng = math.Random(9001);

    void writeMetallicSnap(int offset, int frames, double baseFreq, double gain) {
      for (int i = 0; i < frames; i++) {
        final progress = i / frames;
        final t = i * dt;
        final env = math.exp(-progress * 14.0);
        final metallic = math.sin(2.0 * math.pi * baseFreq * t) * 0.55 +
            math.sin(2.0 * math.pi * (baseFreq * 1.52) * t) * 0.30 +
            (((rng.nextDouble() * 2.0) - 1.0) * 0.15);
        final sample = metallic * env * volume * gain;
        left[offset + i] = sample;
        right[offset + i] = sample;
      }
    }

    writeMetallicSnap(0, click1Frames, 2850.0, 0.70);
    writeMetallicSnap(click1Frames + pauseFrames, click2Frames, 2180.0, 0.52);

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// 5. Dźwięk odliczania na rampie startowej TT ("Beep..." lub finałowy "BEEP!").
  AudioStereoBuffer generateTtCountdownBeep({
    double volume = 0.75,
    bool isGoSignal = false,
  }) {
    final double durationSec = isGoSignal ? 0.360 : 0.140;
    final int totalFrames = (durationSec * sampleRate).round();
    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    final dt = 1.0 / sampleRate;
    final double freq = isGoSignal ? 1760.0 : 880.0;

    for (int i = 0; i < totalFrames; i++) {
      final progress = i / totalFrames;
      final t = i * dt;

      double env;
      if (progress < 0.04) {
        env = progress / 0.04;
      } else if (progress > 0.82) {
        env = (1.0 - progress) / 0.18;
      } else {
        env = 1.0;
      }

      final wave = isGoSignal
          ? (math.sin(2.0 * math.pi * freq * t) * 0.75 +
              math.sin(2.0 * math.pi * (freq * 0.5) * t) * 0.25)
          : math.sin(2.0 * math.pi * freq * t);

      final sample = wave * env * volume * (isGoSignal ? 0.72 : 0.58);
      left[i] = sample;
      right[i] = sample;
    }

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// Generuje pełną sekwencję odliczania na rampie TT ("Beep... Beep... BEEP!").
  AudioStereoBuffer generateTtFullCountdownSequence({double volume = 0.75}) {
    final beep = generateTtCountdownBeep(volume: volume, isGoSignal: false);
    final go = generateTtCountdownBeep(volume: volume, isGoSignal: true);
    final int gapFrames = (0.280 * sampleRate).round();

    final int totalFrames = (beep.frameCount * 2) + (gapFrames * 2) + go.frameCount;
    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);

    int cursor = 0;
    void append(AudioStereoBuffer src) {
      for (int i = 0; i < src.frameCount; i++) {
        left[cursor + i] = src.left[i];
        right[cursor + i] = src.right[i];
      }
      cursor += src.frameCount;
    }

    append(beep);
    cursor += gapFrames;
    append(beep);
    cursor += gapFrames;
    append(go);

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }
}

/// Stan centralnego menedżera dźwięku i miksera UI/3D.
class SoundEffectsState {
  final double masterVolume;
  final double raceEnvironmentVolume;
  final double crowdAtmosphereVolume;
  final double raceRadioVolume;
  final double uiSoundsVolume;
  final bool isMuted;
  final bool isCommentaryEnabled;
  final AudioStereoBuffer? lastBuffer;
  final List<SoundPlaybackRecord> history;

  const SoundEffectsState({
    this.masterVolume = 0.85,
    this.raceEnvironmentVolume = 0.85,
    this.crowdAtmosphereVolume = 0.80,
    this.raceRadioVolume = 0.90,
    this.uiSoundsVolume = 0.75,
    this.isMuted = false,
    this.isCommentaryEnabled = true,
    this.lastBuffer,
    this.history = const [],
  });

  factory SoundEffectsState.fromGameSettings(GameSettings settings) {
    return SoundEffectsState(
      masterVolume: settings.soundVolume,
      raceEnvironmentVolume: settings.raceEnvironmentVolume,
      crowdAtmosphereVolume: settings.crowdAtmosphereVolume,
      raceRadioVolume: settings.raceRadioVolume,
      uiSoundsVolume: settings.uiSoundsVolume,
      isCommentaryEnabled: settings.commentaryAudio,
    );
  }

  bool get isAudible => !isMuted && masterVolume > 0.0;

  double get effectiveEnvironmentVolume =>
      isMuted ? 0.0 : (masterVolume * raceEnvironmentVolume).clamp(0.0, 1.0);

  double get effectiveCrowdVolume =>
      isMuted ? 0.0 : (masterVolume * crowdAtmosphereVolume).clamp(0.0, 1.0);

  double get effectiveRadioVolume =>
      isMuted ? 0.0 : (masterVolume * raceRadioVolume).clamp(0.0, 1.0);

  double get effectiveUiVolume =>
      isMuted ? 0.0 : (masterVolume * uiSoundsVolume).clamp(0.0, 1.0);

  SoundEffectsState copyWith({
    double? masterVolume,
    double? raceEnvironmentVolume,
    double? crowdAtmosphereVolume,
    double? raceRadioVolume,
    double? uiSoundsVolume,
    bool? isMuted,
    bool? isCommentaryEnabled,
    AudioStereoBuffer? lastBuffer,
    List<SoundPlaybackRecord>? history,
  }) {
    return SoundEffectsState(
      masterVolume: masterVolume ?? this.masterVolume,
      raceEnvironmentVolume: raceEnvironmentVolume ?? this.raceEnvironmentVolume,
      crowdAtmosphereVolume: crowdAtmosphereVolume ?? this.crowdAtmosphereVolume,
      raceRadioVolume: raceRadioVolume ?? this.raceRadioVolume,
      uiSoundsVolume: uiSoundsVolume ?? this.uiSoundsVolume,
      isMuted: isMuted ?? this.isMuted,
      isCommentaryEnabled: isCommentaryEnabled ?? this.isCommentaryEnabled,
      lastBuffer: lastBuffer ?? this.lastBuffer,
      history: history ?? this.history,
    );
  }
}

/// Centralny Provider Riverpod dla dźwięku i udźwiękowienia UI/3D w całej aplikacji.
final soundEffectsManagerProvider =
    StateNotifierProvider<SoundEffectsManagerProvider, SoundEffectsState>((ref) {
  final initialSettings = ref.read(gameSettingsProvider);
  final manager = SoundEffectsManagerProvider(initialSettings: initialSettings);

  ref.listen<GameSettings>(gameSettingsProvider, (_, next) {
    manager.syncWithSettings(next);
  });

  return manager;
});

/// Centralny menedżer dźwięku łączący [ProceduralCyclingAudioEngine] (#117),
/// [RaceRadioAudioController] (#118) oraz [UiSoundSynthesizer] (UI Haptics & Audio Feedback).
class SoundEffectsManagerProvider extends StateNotifier<SoundEffectsState> {
  static const int _maxHistoryEntries = 64;

  final ProceduralCyclingAudioEngine cyclingEngine;
  final RaceRadioAudioController raceRadioController;
  final UiSoundSynthesizer uiSynthesizer;

  /// Opcjonalny callback wyjściowy dla warstwy natywnego odtwarzacza audio.
  void Function(AudioStereoBuffer buffer, String tag)? onAudioBufferReady;

  /// Opcjonalny callback dla syntezy mowy dyrektora sportowego (TTS).
  void Function(String speechText)? onTtsRequested;

  /// Opcjonalny handler haptyki (domyślnie bezpieczne wywołanie [HapticFeedback]).
  Future<void> Function(UiSoundEffect effect)? onHapticTrigger;

  SoundEffectsManagerProvider({
    GameSettings? initialSettings,
    ProceduralCyclingAudioEngine? cyclingEngine,
    RaceRadioAudioController? raceRadioController,
    UiSoundSynthesizer? uiSynthesizer,
    this.onAudioBufferReady,
    this.onTtsRequested,
    this.onHapticTrigger,
  })  : cyclingEngine = cyclingEngine ?? ProceduralCyclingAudioEngine(),
        raceRadioController = raceRadioController ?? RaceRadioAudioController(),
        uiSynthesizer = uiSynthesizer ?? const UiSoundSynthesizer(),
        super(
          SoundEffectsState.fromGameSettings(
            initialSettings ?? const GameSettings(),
          ),
        ) {
    _wireSubEngines();
    _applyVolumesToEngines();
  }

  void _wireSubEngines() {
    raceRadioController.onAudioBufferGenerated = (buffer, soundType) {
      onAudioBufferReady?.call(buffer, 'radio_${soundType.name}');
    };
    raceRadioController.onTtsRequested = (speechText) {
      onTtsRequested?.call(speechText);
    };
  }

  /// Synchronizuje wszystkie kanały miksera z aktualnym stanem [GameSettings].
  void syncWithSettings(GameSettings settings) {
    state = state.copyWith(
      masterVolume: settings.soundVolume.clamp(0.0, 1.0),
      raceEnvironmentVolume: settings.raceEnvironmentVolume.clamp(0.0, 1.0),
      crowdAtmosphereVolume: settings.crowdAtmosphereVolume.clamp(0.0, 1.0),
      raceRadioVolume: settings.raceRadioVolume.clamp(0.0, 1.0),
      uiSoundsVolume: settings.uiSoundsVolume.clamp(0.0, 1.0),
      isCommentaryEnabled: settings.commentaryAudio,
    );
    _applyVolumesToEngines();
  }

  /// Globalnie wycisza lub przywraca dźwięk w całym menedżerze.
  void setMuted(bool muted) {
    state = state.copyWith(isMuted: muted);
    _applyVolumesToEngines();
  }

  void _applyVolumesToEngines() {
    cyclingEngine.isMuted = state.isMuted;
    cyclingEngine.masterVolume = state.masterVolume;

    final env = state.raceEnvironmentVolume;
    cyclingEngine.aeroWhooshVolume = 0.85 * env;
    cyclingEngine.freehubVolume = 0.80 * env;
    cyclingEngine.cobbleVolume = 0.85 * env;
    cyclingEngine.rainVolume = 0.75 * env;
    cyclingEngine.crowdVolume = 0.95 * state.crowdAtmosphereVolume;

    final effRadio = state.effectiveRadioVolume;
    raceRadioController.radioVolume = effRadio;
    raceRadioController.computerBeepVolume = effRadio;
    raceRadioController.isRadioBeepEnabled =
        state.isCommentaryEnabled && effRadio > 0.0;
    raceRadioController.isBikeComputerBeepEnabled = effRadio > 0.0;
    raceRadioController.isTtsVoiceEnabled =
        state.isCommentaryEnabled && effRadio > 0.0;
  }

  // ===========================================================================
  // 1. DŹWIĘKI INTERFEJSU (UI HAPTICS & AUDIO FEEDBACK)
  // ===========================================================================

  /// Odtwarza wybrany efekt dźwiękowy UI wraz z dopasowaną haptyką.
  AudioStereoBuffer? playUiSound(UiSoundEffect effect) {
    _triggerHaptic(effect);
    final effectiveVol = state.effectiveUiVolume;
    if (effectiveVol <= 0.0) return null;

    final buffer = uiSynthesizer.synthesize(effect, volume: effectiveVol);
    _recordPlayback(
      category: 'ui',
      label: effect.label,
      effectiveVolume: effectiveVol,
      buffer: buffer,
    );
    onAudioBufferReady?.call(buffer, 'ui_${effect.name}');
    return buffer;
  }

  /// Ciche kliknięcie przy przełączaniu zakładek.
  AudioStereoBuffer? playTabClick() => playUiSound(UiSoundEffect.tabClick);

  /// Dźwięk podpisania kontraktu.
  AudioStereoBuffer? playContractSigned() =>
      playUiSound(UiSoundEffect.contractSigned);

  /// Sygnał nowej wiadomości w skrzynce menedżera.
  AudioStereoBuffer? playInboxMessage() =>
      playUiSound(UiSoundEffect.inboxMessage);

  /// Dźwięk klucza dynamometrycznego w garażu rowerowym.
  AudioStereoBuffer? playTorqueWrenchClick() =>
      playUiSound(UiSoundEffect.torqueWrenchClick);

  /// Dźwięk odliczania na rampie startowej TT ("Beep..." lub "BEEP!").
  AudioStereoBuffer? playTtCountdownBeep({required bool isGoSignal}) {
    return playUiSound(
      isGoSignal ? UiSoundEffect.ttCountdownGo : UiSoundEffect.ttCountdownBeep,
    );
  }

  /// Obsługuje krok odliczania na rampie TT (np. 3, 2, 1 -> "Beep...", 0 -> "BEEP!").
  AudioStereoBuffer? playTtCountdownStep(int secondsRemaining) {
    if (secondsRemaining < 0 || secondsRemaining > 3) return null;
    return playTtCountdownBeep(isGoSignal: secondsRemaining == 0);
  }

  void _triggerHaptic(UiSoundEffect effect) {
    final customTrigger = onHapticTrigger;
    if (customTrigger != null) {
      customTrigger(effect);
      return;
    }
    try {
      switch (effect) {
        case UiSoundEffect.tabClick:
          HapticFeedback.selectionClick();
          break;
        case UiSoundEffect.contractSigned:
        case UiSoundEffect.ttCountdownGo:
          HapticFeedback.heavyImpact();
          break;
        case UiSoundEffect.torqueWrenchClick:
          HapticFeedback.mediumImpact();
          break;
        case UiSoundEffect.inboxMessage:
        case UiSoundEffect.ttCountdownBeep:
          HapticFeedback.lightImpact();
          break;
      }
    } catch (_) {
      // Bezpieczne pominięcie w środowisku bez natywnego kanału haptyki.
    }
  }

  // ===========================================================================
  // 2. RADIO WYŚCIGOWE, ALARMY GARMIN ORAZ OTOCZENIE WYŚCIGU 3D
  // ===========================================================================

  /// Odtwarza dźwięk radia wyścigowego ("Krrr-beep!") i opcjonalnie TTS dla komunikatu.
  AudioStereoBuffer? playRadioMessage(RaceRadioMessage message) {
    final buffer = raceRadioController.handleRadioMessage(message);
    if (buffer != null) {
      _recordPlayback(
        category: 'radio',
        label: message.message,
        effectiveVolume: state.effectiveRadioVolume,
        buffer: buffer,
      );
    }
    return buffer;
  }

  /// Przetwarza telemetrię wyścigową 3D: aktualizuje silnik otoczenia (#117)
  /// oraz wyzwala alerty komputera rowerowego Garmin/ClimbPro (#118).
  List<AudioStereoBuffer> processRaceTelemetry({
    required CyclingAudioTelemetry telemetry,
    required double currentKm,
    required double wPrimePercent,
    required List<StageSegment> segments,
    double dtSeconds = 0.5,
  }) {
    cyclingEngine.updateTelemetry(telemetry);

    final alerts = raceRadioController.handleBikeComputerTelemetry(
      currentKm: currentKm,
      wPrimePercent: wPrimePercent,
      segments: segments,
      dtSeconds: dtSeconds,
    );

    for (final buffer in alerts) {
      _recordPlayback(
        category: 'garmin',
        label: 'Alert Garmin / ClimbPro (${currentKm.toStringAsFixed(1)} km)',
        effectiveVolume: state.effectiveRadioVolume,
        buffer: buffer,
      );
    }

    return alerts;
  }

  /// Syntetyzuje bufor audio otoczenia wyścigu (koła, bębenek, wiatr, bruk, kibice).
  AudioStereoBuffer generateEnvironmentAudioFrame({
    Duration duration = const Duration(milliseconds: 250),
    CyclingAudioTelemetry? telemetry,
  }) {
    final buffer = cyclingEngine.generateAudioBuffer(
      duration: duration,
      telemetry: telemetry,
    );
    if (state.isAudible) {
      _recordPlayback(
        category: 'ambient',
        label: 'Otoczenie wyścigu (${duration.inMilliseconds} ms)',
        effectiveVolume: state.effectiveEnvironmentVolume,
        buffer: buffer,
      );
      onAudioBufferReady?.call(buffer, 'ambient_race');
    }
    return buffer;
  }

  /// Resetuje stan generatorów wyścigowych i detektorów przed nowym etapem.
  void resetRaceAudio() {
    cyclingEngine.reset();
    raceRadioController.reset();
  }

  void _recordPlayback({
    required String category,
    required String label,
    required double effectiveVolume,
    required AudioStereoBuffer buffer,
  }) {
    final entry = SoundPlaybackRecord(
      timestamp: DateTime.now(),
      category: category,
      label: label,
      effectiveVolume: effectiveVolume,
      frameCount: buffer.frameCount,
    );
    final updated = [...state.history, entry];
    if (updated.length > _maxHistoryEntries) {
      updated.removeRange(0, updated.length - _maxHistoryEntries);
    }
    state = state.copyWith(
      lastBuffer: buffer,
      history: List.unmodifiable(updated),
    );
  }
}
