// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/audio/procedural_cycling_audio_engine.dart';
import '../theme/app_colors.dart';

/// Dramaturgiczny akt muzyczny dopasowany do sytuacji taktycznej na szosie.
enum MusicScoreAct {
  pelotonCruise(
    'Peloton Cruise',
    'Spokojny puls w peletonie',
    96.0,
    AppColors.accentBlue,
  ),
  breakawayTension(
    'Breakaway Tension',
    'Narastające napięcie odjazdu',
    114.0,
    AppColors.amberWarning,
  ),
  mountainAscent(
    'Mountain Ascent',
    'Orkiestrowa wspinaczka HC/Cat 1',
    120.0,
    AppColors.primaryAccent,
  ),
  crosswindEchelon(
    'Crosswind Echelon',
    'Wachlarze i walka na wietrze',
    128.0,
    AppColors.cyanAccent,
  ),
  finalSprintClimax(
    'Final Sprint Climax',
    'Finałowe kilometry i sprint',
    140.0,
    AppColors.crimsonAlert,
  ),
  podiumVictory(
    'Podium Victory',
    'Fanfary triumfu na mecie',
    122.0,
    AppColors.goldAccent,
  );

  final String label;
  final String subtitle;
  final double baseBpm;
  final Color accentColor;

  const MusicScoreAct(
    this.label,
    this.subtitle,
    this.baseBpm,
    this.accentColor,
  );
}

/// Niezależne ścieżki (stemy) hybrydowego miksu elektroniczno-orkiestrowego.
enum MusicStemChannel {
  subBassSynth('Sub-Bass & Pulse', 'Syntezatorowy sub-bas i sidechain', AppColors.accentBlue),
  electronicArp('Electronic Arp', 'Arpeggio modulowane filtrem LP', AppColors.cyanAccent),
  orchestralStrings('Orchestral Strings', 'Sekcja smyczkowa i ostinato', AppColors.primaryAccent),
  cinematicBrass('Cinematic Brass', 'Waltornie i dęte blaszane', AppColors.goldAccent),
  percussionDrive('Percussion & Taiko', 'Bębny taiko, werbel i puls', AppColors.crimsonAlert);

  final String label;
  final String description;
  final Color accentColor;

  const MusicStemChannel(this.label, this.description, this.accentColor);
}

/// Skala harmoniczna wykorzystywana przez generator akordów i arpeggia.
enum HarmonicScaleMode {
  dMinorDorian('D Dorian — Heroic', 62, <int>[0, 2, 3, 5, 7, 9, 10]),
  aMinorAeolian('A Aeolian — Dramatic', 57, <int>[0, 2, 3, 5, 7, 8, 10]),
  fSharpPhrygian('F# Phrygian — Tension', 54, <int>[0, 1, 3, 5, 7, 8, 10]),
  cMajorLydian('C Lydian — Victory', 60, <int>[0, 2, 4, 6, 7, 9, 11]);

  final String label;
  final int rootMidi;
  final List<int> semitoneIntervals;

  const HarmonicScaleMode(this.label, this.rootMidi, this.semitoneIntervals);
}

/// Preset dynamiki i głośności ścieżki muzycznej.
enum MusicIntensityPreset {
  muted('Wyciszona', 0.0),
  ambientFocus('Tło Taktyczne', 0.45),
  balancedBroadcast('Transmisja TV', 0.78),
  cinematicMax('Pełne Kino', 1.0);

  final String label;
  final double scale;

  const MusicIntensityPreset(this.label, this.scale);
}

/// Telemetria akcji na szosie sterująca adaptacyjną partyturą muzyczną.
@immutable
class RoadActionMusicTelemetry {
  final double speedKmh;
  final double gradientPercent;
  final double distanceRemainingMeters;
  final double pelotonTension;
  final bool isBreakawayActive;
  final bool isCrosswindEchelon;
  final bool isAttackHappening;
  final bool isCrashAlert;
  final bool isSprintFinish;
  final bool isStageFinished;
  final int playerHeartRateZone;
  final int riderCountNearby;

  const RoadActionMusicTelemetry({
    this.speedKmh = 42.0,
    this.gradientPercent = 0.5,
    this.distanceRemainingMeters = 45000.0,
    this.pelotonTension = 0.25,
    this.isBreakawayActive = false,
    this.isCrosswindEchelon = false,
    this.isAttackHappening = false,
    this.isCrashAlert = false,
    this.isSprintFinish = false,
    this.isStageFinished = false,
    this.playerHeartRateZone = 2,
    this.riderCountNearby = 45,
  });

  /// Zwraca bezpiecznie znormalizowaną kopię telemetrii w granicach fizycznych wyścigu.
  RoadActionMusicTelemetry clamped() {
    return RoadActionMusicTelemetry(
      speedKmh: speedKmh.isFinite ? speedKmh.clamp(0.0, 120.0) : 0.0,
      gradientPercent: gradientPercent.isFinite ? gradientPercent.clamp(-25.0, 30.0) : 0.0,
      distanceRemainingMeters:
          distanceRemainingMeters.isFinite ? distanceRemainingMeters.clamp(0.0, 350000.0) : 0.0,
      pelotonTension: pelotonTension.isFinite ? pelotonTension.clamp(0.0, 1.0) : 0.0,
      isBreakawayActive: isBreakawayActive,
      isCrosswindEchelon: isCrosswindEchelon,
      isAttackHappening: isAttackHappening,
      isCrashAlert: isCrashAlert,
      isSprintFinish: isSprintFinish,
      isStageFinished: isStageFinished,
      playerHeartRateZone: playerHeartRateZone.clamp(1, 5),
      riderCountNearby: riderCountNearby.clamp(0, 200),
    );
  }

  RoadActionMusicTelemetry copyWith({
    double? speedKmh,
    double? gradientPercent,
    double? distanceRemainingMeters,
    double? pelotonTension,
    bool? isBreakawayActive,
    bool? isCrosswindEchelon,
    bool? isAttackHappening,
    bool? isCrashAlert,
    bool? isSprintFinish,
    bool? isStageFinished,
    int? playerHeartRateZone,
    int? riderCountNearby,
  }) {
    return RoadActionMusicTelemetry(
      speedKmh: speedKmh ?? this.speedKmh,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      distanceRemainingMeters: distanceRemainingMeters ?? this.distanceRemainingMeters,
      pelotonTension: pelotonTension ?? this.pelotonTension,
      isBreakawayActive: isBreakawayActive ?? this.isBreakawayActive,
      isCrosswindEchelon: isCrosswindEchelon ?? this.isCrosswindEchelon,
      isAttackHappening: isAttackHappening ?? this.isAttackHappening,
      isCrashAlert: isCrashAlert ?? this.isCrashAlert,
      isSprintFinish: isSprintFinish ?? this.isSprintFinish,
      isStageFinished: isStageFinished ?? this.isStageFinished,
      playerHeartRateZone: playerHeartRateZone ?? this.playerHeartRateZone,
      riderCountNearby: riderCountNearby ?? this.riderCountNearby,
    );
  }

  factory RoadActionMusicTelemetry.pelotonCruise() => const RoadActionMusicTelemetry(
        speedKmh: 43.0,
        gradientPercent: 0.4,
        distanceRemainingMeters: 85000.0,
        pelotonTension: 0.22,
        playerHeartRateZone: 2,
        riderCountNearby: 80,
      );

  factory RoadActionMusicTelemetry.breakawayChase() => const RoadActionMusicTelemetry(
        speedKmh: 48.5,
        gradientPercent: 1.8,
        distanceRemainingMeters: 28000.0,
        pelotonTension: 0.62,
        isBreakawayActive: true,
        playerHeartRateZone: 4,
        riderCountNearby: 6,
      );

  factory RoadActionMusicTelemetry.mountainClimb() => const RoadActionMusicTelemetry(
        speedKmh: 19.5,
        gradientPercent: 9.8,
        distanceRemainingMeters: 6200.0,
        pelotonTension: 0.78,
        isAttackHappening: true,
        playerHeartRateZone: 5,
        riderCountNearby: 9,
      );

  factory RoadActionMusicTelemetry.crosswindEchelon() => const RoadActionMusicTelemetry(
        speedKmh: 53.0,
        gradientPercent: 0.0,
        distanceRemainingMeters: 34000.0,
        pelotonTension: 0.82,
        isCrosswindEchelon: true,
        playerHeartRateZone: 4,
        riderCountNearby: 18,
      );

  factory RoadActionMusicTelemetry.finalSprint() => const RoadActionMusicTelemetry(
        speedKmh: 68.5,
        gradientPercent: -0.5,
        distanceRemainingMeters: 850.0,
        pelotonTension: 0.98,
        isAttackHappening: true,
        isSprintFinish: true,
        playerHeartRateZone: 5,
        riderCountNearby: 24,
      );

  factory RoadActionMusicTelemetry.podiumVictory() => const RoadActionMusicTelemetry(
        speedKmh: 18.0,
        gradientPercent: 0.0,
        distanceRemainingMeters: 0.0,
        pelotonTension: 0.15,
        isStageFinished: true,
        playerHeartRateZone: 2,
        riderCountNearby: 3,
      );
}

/// Poziomy poszczególnych stemów i parametry obróbki DSP miksu muzycznego.
@immutable
class MusicStemMixLevels {
  final double subBassSynth;
  final double electronicArp;
  final double orchestralStrings;
  final double cinematicBrass;
  final double percussionDrive;
  final double filterCutoffHz;
  final double reverbWetMix;
  final double sidechainDepth;

  const MusicStemMixLevels({
    this.subBassSynth = 0.50,
    this.electronicArp = 0.35,
    this.orchestralStrings = 0.45,
    this.cinematicBrass = 0.20,
    this.percussionDrive = 0.25,
    this.filterCutoffHz = 1800.0,
    this.reverbWetMix = 0.28,
    this.sidechainDepth = 0.30,
  });

  double levelFor(MusicStemChannel channel) {
    switch (channel) {
      case MusicStemChannel.subBassSynth:
        return subBassSynth;
      case MusicStemChannel.electronicArp:
        return electronicArp;
      case MusicStemChannel.orchestralStrings:
        return orchestralStrings;
      case MusicStemChannel.cinematicBrass:
        return cinematicBrass;
      case MusicStemChannel.percussionDrive:
        return percussionDrive;
    }
  }

  double get averageEnergy =>
      (subBassSynth + electronicArp + orchestralStrings + cinematicBrass + percussionDrive) / 5.0;

  /// Płynnie interpoluje dwa stany miksu dla płynnych przejść bez skoków głośności.
  MusicStemMixLevels lerpTo(MusicStemMixLevels target, double t) {
    final k = t.clamp(0.0, 1.0);
    double lerp(double a, double b) => a + (b - a) * k;
    return MusicStemMixLevels(
      subBassSynth: lerp(subBassSynth, target.subBassSynth).clamp(0.0, 1.0),
      electronicArp: lerp(electronicArp, target.electronicArp).clamp(0.0, 1.0),
      orchestralStrings: lerp(orchestralStrings, target.orchestralStrings).clamp(0.0, 1.0),
      cinematicBrass: lerp(cinematicBrass, target.cinematicBrass).clamp(0.0, 1.0),
      percussionDrive: lerp(percussionDrive, target.percussionDrive).clamp(0.0, 1.0),
      filterCutoffHz: lerp(filterCutoffHz, target.filterCutoffHz).clamp(220.0, 12000.0),
      reverbWetMix: lerp(reverbWetMix, target.reverbWetMix).clamp(0.0, 0.85),
      sidechainDepth: lerp(sidechainDepth, target.sidechainDepth).clamp(0.0, 0.90),
    );
  }
}

/// Migawka przejścia lub wygenerowanej frazy adaptacyjnej partytury.
@immutable
class AdaptiveMusicCueSnapshot {
  final MusicScoreAct act;
  final HarmonicScaleMode scale;
  final double bpm;
  final double tension;
  final MusicStemMixLevels mix;
  final List<int> chordProgressionMidi;
  final DateTime timestamp;
  final String reason;

  const AdaptiveMusicCueSnapshot({
    required this.act,
    required this.scale,
    required this.bpm,
    required this.tension,
    required this.mix,
    required this.chordProgressionMidi,
    required this.timestamp,
    required this.reason,
  });
}

/// Niezmienny stan silnika adaptacyjnej muzyki elektroniczno-orkiestrowej.
@immutable
class AdaptiveMusicScoreState {
  final bool isEnabled;
  final MusicIntensityPreset intensityPreset;
  final double masterVolume;
  final bool autoAdaptToTelemetry;
  final MusicScoreAct? manualOverrideAct;
  final MusicScoreAct currentAct;
  final HarmonicScaleMode currentScale;
  final double currentBpm;
  final double currentTension;
  final MusicStemMixLevels stemMix;
  final Map<MusicStemChannel, bool> stemMuteFlags;
  final RoadActionMusicTelemetry lastTelemetry;
  final List<AdaptiveMusicCueSnapshot> cueHistory;
  final int totalFramesSynthesized;
  final double lastSynthesizedPeakDb;

  const AdaptiveMusicScoreState({
    this.isEnabled = true,
    this.intensityPreset = MusicIntensityPreset.balancedBroadcast,
    this.masterVolume = 0.82,
    this.autoAdaptToTelemetry = true,
    this.manualOverrideAct,
    this.currentAct = MusicScoreAct.pelotonCruise,
    this.currentScale = HarmonicScaleMode.dMinorDorian,
    this.currentBpm = 98.0,
    this.currentTension = 0.25,
    this.stemMix = const MusicStemMixLevels(),
    this.stemMuteFlags = const <MusicStemChannel, bool>{
      MusicStemChannel.subBassSynth: false,
      MusicStemChannel.electronicArp: false,
      MusicStemChannel.orchestralStrings: false,
      MusicStemChannel.cinematicBrass: false,
      MusicStemChannel.percussionDrive: false,
    },
    this.lastTelemetry = const RoadActionMusicTelemetry(),
    this.cueHistory = const <AdaptiveMusicCueSnapshot>[],
    this.totalFramesSynthesized = 0,
    this.lastSynthesizedPeakDb = -12.0,
  });

  bool get isEffectivelyActive =>
      isEnabled && intensityPreset != MusicIntensityPreset.muted && masterVolume > 0.001;

  double get effectiveOutputGain =>
      isEffectivelyActive ? (masterVolume * intensityPreset.scale).clamp(0.0, 1.0) : 0.0;

  bool isStemMuted(MusicStemChannel channel) => stemMuteFlags[channel] ?? false;

  AdaptiveMusicScoreState copyWith({
    bool? isEnabled,
    MusicIntensityPreset? intensityPreset,
    double? masterVolume,
    bool? autoAdaptToTelemetry,
    MusicScoreAct? manualOverrideAct,
    bool clearManualOverrideAct = false,
    MusicScoreAct? currentAct,
    HarmonicScaleMode? currentScale,
    double? currentBpm,
    double? currentTension,
    MusicStemMixLevels? stemMix,
    Map<MusicStemChannel, bool>? stemMuteFlags,
    RoadActionMusicTelemetry? lastTelemetry,
    List<AdaptiveMusicCueSnapshot>? cueHistory,
    int? totalFramesSynthesized,
    double? lastSynthesizedPeakDb,
  }) {
    return AdaptiveMusicScoreState(
      isEnabled: isEnabled ?? this.isEnabled,
      intensityPreset: intensityPreset ?? this.intensityPreset,
      masterVolume: masterVolume ?? this.masterVolume,
      autoAdaptToTelemetry: autoAdaptToTelemetry ?? this.autoAdaptToTelemetry,
      manualOverrideAct:
          clearManualOverrideAct ? null : (manualOverrideAct ?? this.manualOverrideAct),
      currentAct: currentAct ?? this.currentAct,
      currentScale: currentScale ?? this.currentScale,
      currentBpm: currentBpm ?? this.currentBpm,
      currentTension: currentTension ?? this.currentTension,
      stemMix: stemMix ?? this.stemMix,
      stemMuteFlags: stemMuteFlags ?? this.stemMuteFlags,
      lastTelemetry: lastTelemetry ?? this.lastTelemetry,
      cueHistory: cueHistory ?? this.cueHistory,
      totalFramesSynthesized: totalFramesSynthesized ?? this.totalFramesSynthesized,
      lastSynthesizedPeakDb: lastSynthesizedPeakDb ?? this.lastSynthesizedPeakDb,
    );
  }
}

/// Proceduralny, adaptacyjny silnik muzyki elektroniczno-orkiestrowej reagującej na akcję na szosie.
///
/// Analizuje telemetrię wyścigu (prędkość, nachylenie, dystans do mety, ucieczki,
/// wachlarze na wietrze, ataki i kraksy), wyznacza dramaturgiczny akt muzyczny,
/// skalę harmoniczną, tempo BPM oraz proporcje 5 ścieżek (sub-bas, arp, smyczki,
/// dęte blaszane, perkusja taiko) i syntetyzuje bufor stereo PCM 44.1 kHz w pamięci.
class AdaptiveDynamicMusicScoreEngine {
  final int sampleRate;

  const AdaptiveDynamicMusicScoreEngine({
    this.sampleRate = 44100,
  });

  /// Konwertuje numer nuty MIDI na częstotliwość w Hz (A4 = 440 Hz).
  static double midiToHz(int midiNote) {
    final clamped = midiNote.clamp(0, 127);
    return 440.0 * math.pow(2.0, (clamped - 69) / 12.0).toDouble();
  }

  /// Zwraca nutę MIDI ze skali dla podanego stopnia (0-based, z obsługą oktaw).
  static int scaleNote(HarmonicScaleMode scale, int degree, {int octaveOffset = 0}) {
    final intervals = scale.semitoneIntervals;
    final len = intervals.length;
    final normalizedDegree = ((degree % len) + len) % len;
    final extraOctaves = degree >= 0 ? (degree ~/ len) : -(((-degree - 1) ~/ len) + 1);
    return (scale.rootMidi + intervals[normalizedDegree] + (octaveOffset + extraOctaves) * 12)
        .clamp(24, 108);
  }

  /// Buduje progresję 4-akordową dla wybranego aktu i skali.
  static List<int> buildChordRoots(MusicScoreAct act, HarmonicScaleMode scale) {
    switch (act) {
      case MusicScoreAct.pelotonCruise:
        return <int>[
          scaleNote(scale, 0, octaveOffset: -1),
          scaleNote(scale, 5, octaveOffset: -1),
          scaleNote(scale, 3, octaveOffset: -1),
          scaleNote(scale, 4, octaveOffset: -1),
        ];
      case MusicScoreAct.breakawayTension:
        return <int>[
          scaleNote(scale, 0, octaveOffset: -1),
          scaleNote(scale, 2, octaveOffset: -1),
          scaleNote(scale, 6, octaveOffset: -1),
          scaleNote(scale, 4, octaveOffset: -1),
        ];
      case MusicScoreAct.mountainAscent:
        return <int>[
          scaleNote(scale, 0, octaveOffset: -1),
          scaleNote(scale, 3, octaveOffset: -1),
          scaleNote(scale, 4, octaveOffset: -1),
          scaleNote(scale, 5, octaveOffset: -1),
        ];
      case MusicScoreAct.crosswindEchelon:
        return <int>[
          scaleNote(scale, 0, octaveOffset: -1),
          scaleNote(scale, 1, octaveOffset: -1),
          scaleNote(scale, 4, octaveOffset: -1),
          scaleNote(scale, 0, octaveOffset: -1),
        ];
      case MusicScoreAct.finalSprintClimax:
        return <int>[
          scaleNote(scale, 0, octaveOffset: -1),
          scaleNote(scale, 6, octaveOffset: -1),
          scaleNote(scale, 5, octaveOffset: -1),
          scaleNote(scale, 4, octaveOffset: -1),
        ];
      case MusicScoreAct.podiumVictory:
        return <int>[
          scaleNote(scale, 0, octaveOffset: -1),
          scaleNote(scale, 4, octaveOffset: -1),
          scaleNote(scale, 5, octaveOffset: -1),
          scaleNote(scale, 3, octaveOffset: -1),
        ];
    }
  }

  /// Wylicza docelową migawkę partytury na podstawie telemetrii wyścigu.
  AdaptiveMusicCueSnapshot evaluateTelemetry({
    required RoadActionMusicTelemetry rawTelemetry,
    MusicScoreAct? forcedAct,
    MusicStemMixLevels? previousMix,
    double? previousBpm,
    double smoothingAlpha = 0.35,
    DateTime? timestamp,
  }) {
    final telemetry = rawTelemetry.clamped();
    final actResult = forcedAct != null
        ? _ActDecision(forcedAct, 'Tryb ręczny: ${forcedAct.label}')
        : _resolveActFromTelemetry(telemetry);
    final act = actResult.act;
    final scale = _resolveScaleForAct(act, telemetry);
    final tension = _computeNormalizedTension(act, telemetry);
    final targetBpm = _computeTargetBpm(act, telemetry, tension);
    final targetMix = _computeTargetStemMix(act, telemetry, tension);

    final alpha = smoothingAlpha.clamp(0.05, 1.0);
    final smoothedMix =
        previousMix != null ? previousMix.lerpTo(targetMix, alpha) : targetMix;
    final smoothedBpm = previousBpm != null
        ? (previousBpm + (targetBpm - previousBpm) * alpha).clamp(72.0, 165.0)
        : targetBpm;

    return AdaptiveMusicCueSnapshot(
      act: act,
      scale: scale,
      bpm: smoothedBpm,
      tension: tension,
      mix: smoothedMix,
      chordProgressionMidi: buildChordRoots(act, scale),
      timestamp: timestamp ?? DateTime.now(),
      reason: actResult.reason,
    );
  }

  _ActDecision _resolveActFromTelemetry(RoadActionMusicTelemetry t) {
    if (t.isStageFinished) {
      return const _ActDecision(
        MusicScoreAct.podiumVictory,
        'Meta osiągnięta — fanfary podium',
      );
    }
    if (t.isSprintFinish || t.distanceRemainingMeters <= 3000.0) {
      return const _ActDecision(
        MusicScoreAct.finalSprintClimax,
        'Ostatnie 3 km / finisz sprinterski',
      );
    }
    if (t.isCrashAlert || t.isCrosswindEchelon) {
      return _ActDecision(
        MusicScoreAct.crosswindEchelon,
        t.isCrashAlert ? 'Alert kraksy w peletonie' : 'Wachlarze na bocznym wietrze',
      );
    }
    if (t.gradientPercent >= 5.0 || (t.gradientPercent >= 3.5 && t.isAttackHappening)) {
      return _ActDecision(
        MusicScoreAct.mountainAscent,
        'Podjazd ${t.gradientPercent.toStringAsFixed(1)}%${t.isAttackHappening ? " + atak" : ""}',
      );
    }
    if (t.isBreakawayActive || t.isAttackHappening || t.pelotonTension >= 0.55) {
      return _ActDecision(
        MusicScoreAct.breakawayTension,
        t.isAttackHappening ? 'Atak na szosie' : 'Aktywny odjazd i pogoń',
      );
    }
    return const _ActDecision(
      MusicScoreAct.pelotonCruise,
      'Kontrolowana jazda w grupie',
    );
  }

  HarmonicScaleMode _resolveScaleForAct(MusicScoreAct act, RoadActionMusicTelemetry t) {
    switch (act) {
      case MusicScoreAct.podiumVictory:
        return HarmonicScaleMode.cMajorLydian;
      case MusicScoreAct.crosswindEchelon:
      case MusicScoreAct.finalSprintClimax:
        return t.isCrashAlert || t.pelotonTension > 0.85
            ? HarmonicScaleMode.fSharpPhrygian
            : HarmonicScaleMode.aMinorAeolian;
      case MusicScoreAct.mountainAscent:
        return HarmonicScaleMode.aMinorAeolian;
      case MusicScoreAct.breakawayTension:
      case MusicScoreAct.pelotonCruise:
        return HarmonicScaleMode.dMinorDorian;
    }
  }

  double _computeNormalizedTension(MusicScoreAct act, RoadActionMusicTelemetry t) {
    double score = t.pelotonTension * 0.45;
    score += ((t.playerHeartRateZone - 1) / 4.0) * 0.20;
    score += (t.speedKmh / 75.0).clamp(0.0, 1.0) * 0.10;
    if (t.gradientPercent > 0.0) {
      score += (t.gradientPercent / 14.0).clamp(0.0, 1.0) * 0.15;
    }
    if (t.isAttackHappening) score += 0.18;
    if (t.isCrosswindEchelon) score += 0.14;
    if (t.isCrashAlert) score += 0.22;
    if (t.distanceRemainingMeters <= 5000.0 && !t.isStageFinished) {
      score += (1.0 - (t.distanceRemainingMeters / 5000.0)) * 0.25;
    }
    if (act == MusicScoreAct.podiumVictory) {
      return 0.42;
    }
    return score.clamp(0.08, 1.0);
  }

  double _computeTargetBpm(
    MusicScoreAct act,
    RoadActionMusicTelemetry t,
    double tension,
  ) {
    final speedDelta = ((t.speedKmh - 40.0) * 0.18).clamp(-6.0, 10.0);
    final tensionBoost = tension * 12.0;
    final raw = act.baseBpm + tensionBoost + speedDelta;
    return raw.clamp(84.0, 152.0);
  }

  MusicStemMixLevels _computeTargetStemMix(
    MusicScoreAct act,
    RoadActionMusicTelemetry t,
    double tension,
  ) {
    switch (act) {
      case MusicScoreAct.pelotonCruise:
        return MusicStemMixLevels(
          subBassSynth: 0.42 + tension * 0.15,
          electronicArp: 0.28 + tension * 0.18,
          orchestralStrings: 0.50,
          cinematicBrass: 0.10,
          percussionDrive: 0.18 + tension * 0.15,
          filterCutoffHz: 1100.0 + tension * 1400.0,
          reverbWetMix: 0.38,
          sidechainDepth: 0.20,
        );
      case MusicScoreAct.breakawayTension:
        return MusicStemMixLevels(
          subBassSynth: 0.62,
          electronicArp: 0.72 + tension * 0.18,
          orchestralStrings: 0.58,
          cinematicBrass: 0.34,
          percussionDrive: 0.52 + tension * 0.20,
          filterCutoffHz: 2400.0 + tension * 2600.0,
          reverbWetMix: 0.28,
          sidechainDepth: 0.42,
        );
      case MusicScoreAct.mountainAscent:
        return MusicStemMixLevels(
          subBassSynth: 0.54,
          electronicArp: 0.40,
          orchestralStrings: 0.88,
          cinematicBrass: 0.76 + (t.isAttackHappening ? 0.18 : 0.0),
          percussionDrive: 0.60,
          filterCutoffHz: 2200.0 + tension * 2200.0,
          reverbWetMix: 0.44,
          sidechainDepth: 0.32,
        );
      case MusicScoreAct.crosswindEchelon:
        return MusicStemMixLevels(
          subBassSynth: 0.82,
          electronicArp: 0.78,
          orchestralStrings: 0.48,
          cinematicBrass: 0.52,
          percussionDrive: 0.88,
          filterCutoffHz: 3200.0 + tension * 3400.0,
          reverbWetMix: 0.22,
          sidechainDepth: 0.58,
        );
      case MusicScoreAct.finalSprintClimax:
        return MusicStemMixLevels(
          subBassSynth: 0.90,
          electronicArp: 0.92,
          orchestralStrings: 0.84,
          cinematicBrass: 0.88,
          percussionDrive: 0.96,
          filterCutoffHz: 5200.0 + tension * 4200.0,
          reverbWetMix: 0.25,
          sidechainDepth: 0.72,
        );
      case MusicScoreAct.podiumVictory:
        return const MusicStemMixLevels(
          subBassSynth: 0.48,
          electronicArp: 0.45,
          orchestralStrings: 0.92,
          cinematicBrass: 0.96,
          percussionDrive: 0.42,
          filterCutoffHz: 6500.0,
          reverbWetMix: 0.52,
          sidechainDepth: 0.18,
        );
    }
  }

  /// Syntetyzuje frazę muzyczną stereo PCM 44.1 kHz dla bieżącej migawki i stanu wyciszeń.
  AudioStereoBuffer synthesizePhraseBuffer({
    required AdaptiveMusicCueSnapshot cue,
    Map<MusicStemChannel, bool> mutedStems = const <MusicStemChannel, bool>{},
    double masterGain = 0.80,
    int beats = 4,
  }) {
    final safeBeats = beats.clamp(1, 16);
    final clampedGain = masterGain.isFinite ? masterGain.clamp(0.0, 1.0) : 0.0;
    final secondsPerBeat = 60.0 / cue.bpm.clamp(60.0, 180.0);
    final totalSeconds = secondsPerBeat * safeBeats;
    final totalFrames = math.max(1, (totalSeconds * sampleRate).round());

    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);
    if (clampedGain <= 0.0001) {
      return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
    }

    final subGain =
        (mutedStems[MusicStemChannel.subBassSynth] ?? false) ? 0.0 : cue.mix.subBassSynth;
    final arpGain =
        (mutedStems[MusicStemChannel.electronicArp] ?? false) ? 0.0 : cue.mix.electronicArp;
    final strGain =
        (mutedStems[MusicStemChannel.orchestralStrings] ?? false) ? 0.0 : cue.mix.orchestralStrings;
    final brassGain =
        (mutedStems[MusicStemChannel.cinematicBrass] ?? false) ? 0.0 : cue.mix.cinematicBrass;
    final percGain =
        (mutedStems[MusicStemChannel.percussionDrive] ?? false) ? 0.0 : cue.mix.percussionDrive;

    final chords = cue.chordProgressionMidi.isNotEmpty
        ? cue.chordProgressionMidi
        : <int>[cue.scale.rootMidi - 12];
    final dt = 1.0 / sampleRate;
    final arpBrightness = ((cue.mix.filterCutoffHz - 300.0) / 9000.0).clamp(0.08, 1.0);

    // Stan prostego filtra dolnoprzepustowego 1-biegunowego dla arpeggia
    double lpStateL = 0.0;
    double lpStateR = 0.0;
    final lpAlpha = (0.06 + arpBrightness * 0.45).clamp(0.05, 0.75);

    for (int i = 0; i < totalFrames; i++) {
      final t = i * dt;
      final beatPos = t / secondsPerBeat;
      final beatIndex = beatPos.floor();
      final beatFrac = beatPos - beatIndex;
      final chordRootMidi = chords[beatIndex % chords.length];

      // Sidechain ducking na początku każdego uderzenia (efekt pompowania EDM/Hybryda)
      final sidechainEnv = 1.0 - cue.mix.sidechainDepth * math.exp(-beatFrac * 7.5);

      // 1. Sub-Bass Synth (ciepły sinus + delikatna 2. harmoniczna)
      double bassSample = 0.0;
      if (subGain > 0.001) {
        final bassHz = midiToHz(chordRootMidi - 12);
        final phase = 2.0 * math.pi * bassHz * t;
        bassSample = (math.sin(phase) * 0.85 + math.sin(phase * 2.0) * 0.15) *
            subGain *
            sidechainEnv *
            0.34;
      }

      // 2. Electronic Arp (16-tki w obrębie skali + panorama stereo)
      double arpL = 0.0;
      double arpR = 0.0;
      if (arpGain > 0.001) {
        final step16 = (beatPos * 4.0).floor();
        final stepFrac = (beatPos * 4.0) - step16;
        final arpMidi = scaleNote(cue.scale, (step16 * 2) % 7, octaveOffset: 1);
        final arpHz = midiToHz(arpMidi);
        final arpEnv = math.exp(-stepFrac * 5.2) * math.sin(math.min(1.0, stepFrac * 14.0) * math.pi * 0.5);
        final rawWave = math.sin(2.0 * math.pi * arpHz * t) * 0.65 +
            math.sin(4.0 * math.pi * arpHz * t) * 0.25 +
            math.sin(6.0 * math.pi * arpHz * t) * 0.10;
        final pan = 0.5 + 0.35 * math.sin(step16 * 0.9);
        final rawL = rawWave * arpEnv * arpGain * (1.0 - pan * 0.5) * 0.24;
        final rawR = rawWave * arpEnv * arpGain * (0.5 + pan * 0.5) * 0.24;
        lpStateL += lpAlpha * (rawL - lpStateL);
        lpStateR += lpAlpha * (rawR - lpStateR);
        arpL = lpStateL;
        arpR = lpStateR;
      }

      // 3. Orchestral Strings (3 głosy z lekkim rozstrojeniem chorus i wolną obwiednią)
      double strL = 0.0;
      double strR = 0.0;
      if (strGain > 0.001) {
        final fRoot = midiToHz(chordRootMidi + 12);
        final fFifth = midiToHz(chordRootMidi + 19);
        final padEnv = math.sin((i / totalFrames) * math.pi).clamp(0.15, 1.0);
        final v1 = math.sin(2.0 * math.pi * fRoot * 0.997 * t);
        final v2 = math.sin(2.0 * math.pi * fRoot * 1.003 * t);
        final v3 = math.sin(2.0 * math.pi * fFifth * t) * 0.65;
        strL = (v1 * 0.6 + v3 * 0.4) * padEnv * strGain * sidechainEnv * 0.20;
        strR = (v2 * 0.6 + v3 * 0.4) * padEnv * strGain * sidechainEnv * 0.20;
      }

      // 4. Cinematic Brass (formant dętych blaszanych narastający na frazie)
      double brassSample = 0.0;
      if (brassGain > 0.001) {
        final brassHz = midiToHz(chordRootMidi + 7);
        final phraseProgress = i / totalFrames;
        final swell = math.sin(phraseProgress * math.pi);
        final phase = 2.0 * math.pi * brassHz * t;
        final harmonicStack = math.sin(phase) * 0.55 +
            math.sin(phase * 2.0) * 0.30 +
            math.sin(phase * 3.0) * 0.15;
        brassSample = harmonicStack * swell * brassGain * 0.22;
      }

      // 5. Percussion & Taiko (uderzenie bębna na raz + puls ósemkowy)
      double percSample = 0.0;
      if (percGain > 0.001) {
        final kickEnv = math.exp(-beatFrac * 14.0);
        final kickHz = 48.0 + 95.0 * math.exp(-beatFrac * 24.0);
        final taiko = math.sin(2.0 * math.pi * kickHz * t) * kickEnv * 0.42;

        final eighthFrac = (beatPos * 2.0) - (beatPos * 2.0).floor();
        final transientEnv = math.exp(-eighthFrac * 28.0);
        final pseudoNoise = math.sin(i * 12.9898) * math.cos(i * 78.233);
        final shaker = pseudoNoise * transientEnv * 0.09 * cue.tension;
        percSample = (taiko + shaker) * percGain;
      }

      final mixL = (bassSample + arpL + strL + brassSample + percSample) * clampedGain;
      final mixR = (bassSample + arpR + strR + brassSample + percSample) * clampedGain;

      // Miękki limiter zapobiegający przesterowaniu powyżej [-1.0, 1.0]
      left[i] = _softClip(mixL);
      right[i] = _softClip(mixR);
    }

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// Oblicza szczytowy poziom głośności w dBFS dla zsyntetyzowanego bufora.
  static double computePeakDb(AudioStereoBuffer buffer) {
    if (buffer.frameCount == 0) return -96.0;
    double peak = 0.0;
    for (int i = 0; i < buffer.frameCount; i++) {
      final absL = buffer.left[i].abs();
      final absR = buffer.right[i].abs();
      if (absL > peak) peak = absL;
      if (absR > peak) peak = absR;
    }
    if (peak <= 1e-6) return -96.0;
    return (20.0 * (math.log(peak) / math.ln10)).clamp(-96.0, 0.0);
  }

  static double _softClip(double x) {
    if (x.abs() <= 0.75) return x;
    return x / (1.0 + 0.35 * x.abs());
  }
}

class _ActDecision {
  final MusicScoreAct act;
  final String reason;
  const _ActDecision(this.act, this.reason);
}

/// Kontroler stanu Riverpod dla [AdaptiveDynamicMusicScoreEngine].
class AdaptiveDynamicMusicScoreNotifier extends StateNotifier<AdaptiveMusicScoreState> {
  final AdaptiveDynamicMusicScoreEngine _engine;

  AdaptiveDynamicMusicScoreNotifier({
    AdaptiveDynamicMusicScoreEngine? engine,
  })  : _engine = engine ?? const AdaptiveDynamicMusicScoreEngine(),
        super(const AdaptiveMusicScoreState());

  void setEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  void setIntensityPreset(MusicIntensityPreset preset) {
    state = state.copyWith(
      intensityPreset: preset,
      isEnabled: preset != MusicIntensityPreset.muted ? true : state.isEnabled,
    );
  }

  void setMasterVolume(double volume) {
    final clamped = volume.isFinite ? volume.clamp(0.0, 1.0) : 0.0;
    state = state.copyWith(masterVolume: clamped);
  }

  void setAutoAdapt(bool autoAdapt) {
    state = state.copyWith(
      autoAdaptToTelemetry: autoAdapt,
      clearManualOverrideAct: autoAdapt,
    );
    if (autoAdapt) {
      updateFromTelemetry(state.lastTelemetry);
    }
  }

  void selectManualAct(MusicScoreAct? act) {
    if (act == null) {
      setAutoAdapt(true);
      return;
    }
    final cue = _engine.evaluateTelemetry(
      rawTelemetry: state.lastTelemetry,
      forcedAct: act,
      previousMix: state.stemMix,
      previousBpm: state.currentBpm,
      smoothingAlpha: 1.0,
    );
    _applyCueSnapshot(cue, state.lastTelemetry, autoAdapt: false, manualAct: act);
  }

  void toggleStemMute(MusicStemChannel channel) {
    final updated = Map<MusicStemChannel, bool>.from(state.stemMuteFlags);
    updated[channel] = !(updated[channel] ?? false);
    state = state.copyWith(stemMuteFlags: updated);
  }

  void updateFromTelemetry(RoadActionMusicTelemetry telemetry) {
    final clamped = telemetry.clamped();
    final cue = _engine.evaluateTelemetry(
      rawTelemetry: clamped,
      forcedAct: state.autoAdaptToTelemetry ? null : state.manualOverrideAct,
      previousMix: state.stemMix,
      previousBpm: state.currentBpm,
      smoothingAlpha: 0.45,
    );
    _applyCueSnapshot(
      cue,
      clamped,
      autoAdapt: state.autoAdaptToTelemetry,
      manualAct: state.manualOverrideAct,
    );
  }

  void triggerPresetScenario(MusicScoreAct act) {
    final RoadActionMusicTelemetry telemetry;
    switch (act) {
      case MusicScoreAct.pelotonCruise:
        telemetry = RoadActionMusicTelemetry.pelotonCruise();
      case MusicScoreAct.breakawayTension:
        telemetry = RoadActionMusicTelemetry.breakawayChase();
      case MusicScoreAct.mountainAscent:
        telemetry = RoadActionMusicTelemetry.mountainClimb();
      case MusicScoreAct.crosswindEchelon:
        telemetry = RoadActionMusicTelemetry.crosswindEchelon();
      case MusicScoreAct.finalSprintClimax:
        telemetry = RoadActionMusicTelemetry.finalSprint();
      case MusicScoreAct.podiumVictory:
        telemetry = RoadActionMusicTelemetry.podiumVictory();
    }
    final cue = _engine.evaluateTelemetry(
      rawTelemetry: telemetry,
      forcedAct: act,
      previousMix: state.stemMix,
      previousBpm: state.currentBpm,
      smoothingAlpha: 1.0,
    );
    _applyCueSnapshot(
      cue,
      telemetry,
      autoAdapt: state.autoAdaptToTelemetry,
      manualAct: state.autoAdaptToTelemetry ? null : act,
    );
  }

  AudioStereoBuffer synthesizePreviewPhrase({int beats = 4}) {
    final cue = AdaptiveMusicCueSnapshot(
      act: state.currentAct,
      scale: state.currentScale,
      bpm: state.currentBpm,
      tension: state.currentTension,
      mix: state.stemMix,
      chordProgressionMidi: AdaptiveDynamicMusicScoreEngine.buildChordRoots(
        state.currentAct,
        state.currentScale,
      ),
      timestamp: DateTime.now(),
      reason: 'Podgląd frazy (${state.currentAct.label})',
    );
    final buffer = _engine.synthesizePhraseBuffer(
      cue: cue,
      mutedStems: state.stemMuteFlags,
      masterGain: state.effectiveOutputGain,
      beats: beats,
    );
    final peakDb = AdaptiveDynamicMusicScoreEngine.computePeakDb(buffer);
    state = state.copyWith(
      totalFramesSynthesized: state.totalFramesSynthesized + buffer.frameCount,
      lastSynthesizedPeakDb: peakDb,
    );
    return buffer;
  }

  void resetToDefaults() {
    state = const AdaptiveMusicScoreState();
  }

  void _applyCueSnapshot(
    AdaptiveMusicCueSnapshot cue,
    RoadActionMusicTelemetry telemetry, {
    required bool autoAdapt,
    required MusicScoreAct? manualAct,
  }) {
    final updatedHistory = <AdaptiveMusicCueSnapshot>[
      cue,
      ...state.cueHistory,
    ];
    if (updatedHistory.length > 24) {
      updatedHistory.removeRange(24, updatedHistory.length);
    }
    state = state.copyWith(
      autoAdaptToTelemetry: autoAdapt,
      manualOverrideAct: manualAct,
      clearManualOverrideAct: manualAct == null,
      currentAct: cue.act,
      currentScale: cue.scale,
      currentBpm: cue.bpm,
      currentTension: cue.tension,
      stemMix: cue.mix,
      lastTelemetry: telemetry,
      cueHistory: updatedHistory,
    );
  }
}

/// Globalny provider Riverpod dla adaptacyjnego silnika muzyki wyścigowej.
final adaptiveDynamicMusicScoreProvider = StateNotifierProvider<
    AdaptiveDynamicMusicScoreNotifier, AdaptiveMusicScoreState>(
  (ref) => AdaptiveDynamicMusicScoreNotifier(),
);

/// Produkcyjny panel sterowania i telemetrii silnika [AdaptiveDynamicMusicScoreEngine].
class AdaptiveDynamicMusicScorePanel extends ConsumerWidget {
  const AdaptiveDynamicMusicScorePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreState = ref.watch(adaptiveDynamicMusicScoreProvider);
    final notifier = ref.read(adaptiveDynamicMusicScoreProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 680;
        final isWide = width >= 1120;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeaderBar(
                  state: scoreState,
                  isCompact: isCompact,
                  onToggleEnabled: notifier.setEnabled,
                  onReset: notifier.resetToDefaults,
                ),
                const SizedBox(height: 16),
                _TelemetrySummaryStrip(
                  state: scoreState,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: _ControlsAndActsCard(
                          state: scoreState,
                          notifier: notifier,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _StemMixerAndHistoryCard(
                          state: scoreState,
                          notifier: notifier,
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  _ControlsAndActsCard(
                    state: scoreState,
                    notifier: notifier,
                  ),
                  const SizedBox(height: 16),
                  _StemMixerAndHistoryCard(
                    state: scoreState,
                    notifier: notifier,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final AdaptiveMusicScoreState state;
  final bool isCompact;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onReset;

  const _HeaderBar({
    required this.state,
    required this.isCompact,
    required this.onToggleEnabled,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final titleGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: state.currentAct.accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.currentAct.accentColor.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(
            Icons.graphic_eq_rounded,
            color: state.isEffectivelyActive
                ? state.currentAct.accentColor
                : AppColors.textSecondary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Silnik Muzyki Elektroniczno-Orkiestrowej',
                overflow: TextOverflow.ellipsis,
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
                state.isEffectivelyActive
                    ? 'Aktywny: ${state.currentAct.label} • ${state.currentScale.label}'
                    : 'Silnik wyciszony lub wstrzymany',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _InteractiveActionChip(
          label: 'Reset',
          icon: Icons.restart_alt_rounded,
          isActive: false,
          isDisabled: false,
          accentColor: AppColors.textSecondary,
          onTap: onReset,
        ),
        _InteractiveActionChip(
          label: state.isEnabled ? 'Audio ON' : 'Audio OFF',
          icon: state.isEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          isActive: state.isEnabled,
          isDisabled: false,
          accentColor: state.isEnabled ? AppColors.statusSuccess : AppColors.crimsonAlert,
          onTap: () => onToggleEnabled(!state.isEnabled),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          titleGroup,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(child: titleGroup),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }
}

class _TelemetrySummaryStrip extends StatelessWidget {
  final AdaptiveMusicScoreState state;
  final bool isCompact;

  const _TelemetrySummaryStrip({
    required this.state,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _MetricBox(
        label: 'TEMPO',
        value: '${state.currentBpm.toStringAsFixed(1)} BPM',
        accent: state.currentAct.accentColor,
      ),
      _MetricBox(
        label: 'NAPIĘCIE SZOSY',
        value: '${(state.currentTension * 100).round()}%',
        accent: AppColors.amberWarning,
      ),
      _MetricBox(
        label: 'FILTR LP',
        value: '${state.stemMix.filterCutoffHz.round()} Hz',
        accent: AppColors.cyanAccent,
      ),
      _MetricBox(
        label: 'SZCZYT PCM',
        value: '${state.lastSynthesizedPeakDb.toStringAsFixed(1)} dB',
        accent: AppColors.goldAccent,
      ),
    ];

    if (isCompact) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: cards
            .map((c) => SizedBox(width: 158, child: c))
            .toList(growable: false),
      );
    }

    return Row(
      children: <Widget>[
        for (int i = 0; i < cards.length; i++) ...<Widget>[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsAndActsCard extends StatelessWidget {
  final AdaptiveMusicScoreState state;
  final AdaptiveDynamicMusicScoreNotifier notifier;

  const _ControlsAndActsCard({
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !state.isEnabled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Dynamika i Głośność',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MusicIntensityPreset.values.map((preset) {
              return _InteractiveActionChip(
                label: preset.label,
                isActive: state.intensityPreset == preset,
                isDisabled: isDisabled && preset != MusicIntensityPreset.muted,
                accentColor: AppColors.goldAccent,
                onTap: () => notifier.setIntensityPreset(preset),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Text(
                'Master',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: state.masterVolume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.goldAccent,
                  inactiveColor: AppColors.cardBorder,
                  onChanged: isDisabled ? null : notifier.setMasterVolume,
                ),
              ),
              Text(
                '${(state.masterVolume * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const Text(
                'Akty Partytury (Auto / Ręczny)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              _InteractiveActionChip(
                label: state.autoAdaptToTelemetry ? 'Auto-Adaptacja' : 'Tryb Ręczny',
                icon: state.autoAdaptToTelemetry ? Icons.auto_awesome_rounded : Icons.tune_rounded,
                isActive: state.autoAdaptToTelemetry,
                isDisabled: isDisabled,
                accentColor: AppColors.accentBlue,
                onTap: () => notifier.setAutoAdapt(!state.autoAdaptToTelemetry),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MusicScoreAct.values.map((act) {
              final selected = state.currentAct == act;
              return _InteractiveActionChip(
                label: act.label,
                isActive: selected,
                isDisabled: isDisabled,
                accentColor: act.accentColor,
                onTap: () {
                  if (state.autoAdaptToTelemetry) {
                    notifier.triggerPresetScenario(act);
                  } else {
                    notifier.selectManualAct(act);
                  }
                },
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 14),
          _InteractiveActionChip(
            label: 'Syntetyzuj Frazę PCM (4 takty)',
            icon: Icons.audiotrack_rounded,
            isActive: false,
            isDisabled: !state.isEffectivelyActive,
            accentColor: AppColors.primaryAccent,
            onTap: () => notifier.synthesizePreviewPhrase(beats: 4),
          ),
        ],
      ),
    );
  }
}

class _StemMixerAndHistoryCard extends StatelessWidget {
  final AdaptiveMusicScoreState state;
  final AdaptiveDynamicMusicScoreNotifier notifier;

  const _StemMixerAndHistoryCard({
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Mikser 5 Ścieżek (Stems)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final channel in MusicStemChannel.values) ...<Widget>[
            _StemRow(
              channel: channel,
              level: state.stemMix.levelFor(channel),
              isMuted: state.isStemMuted(channel),
              isEngineDisabled: !state.isEffectivelyActive,
              onToggleMute: () => notifier.toggleStemMute(channel),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          const Text(
            'Ostatnie Przejścia Partytury',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (state.cueHistory.isEmpty)
            const Text(
              'Brak zarejestrowanych przejść — użyj symulacji aktu lub podaj telemetrię wyścigu.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: state.cueHistory.take(4).map((cue) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder, width: 1.0),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cue.act.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${cue.act.label} — ${cue.reason}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${cue.bpm.round()} BPM',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _StemRow extends StatelessWidget {
  final MusicStemChannel channel;
  final double level;
  final bool isMuted;
  final bool isEngineDisabled;
  final VoidCallback onToggleMute;

  const _StemRow({
    required this.channel,
    required this.level,
    required this.isMuted,
    required this.isEngineDisabled,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLevel = (isMuted || isEngineDisabled) ? 0.0 : level.clamp(0.0, 1.0);
    return Row(
      children: <Widget>[
        SizedBox(
          width: 132,
          child: Text(
            channel.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMuted ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              color: AppColors.surfaceLight,
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                widthFactor: effectiveLevel,
                child: Container(
                  decoration: BoxDecoration(
                    color: channel.accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 38,
          child: Text(
            '${(effectiveLevel * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _InteractiveActionChip(
          label: isMuted ? 'MUTE' : 'ON',
          isActive: !isMuted,
          isDisabled: isEngineDisabled,
          accentColor: isMuted ? AppColors.crimsonAlert : channel.accentColor,
          onTap: onToggleMute,
        ),
      ],
    );
  }
}

class _InteractiveActionChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveActionChip({
    required this.label,
    this.icon,
    required this.isActive,
    required this.isDisabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isDisabled;
    final bgColor = disabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : widget.isActive
            ? widget.accentColor.withValues(alpha: _isHovered ? 0.28 : 0.20)
            : _isPressed
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.9)
                    : AppColors.surfaceLight.withValues(alpha: 0.65);

    final borderColor = disabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.cyanAccent
            : widget.isActive
                ? widget.accentColor
                : _isHovered
                    ? widget.accentColor.withValues(alpha: 0.6)
                    : AppColors.cardBorder;

    final fgColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.isActive
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (hovered) {
        if (mounted) setState(() => _isHovered = hovered);
      },
      onShowFocusHighlight: (focused) {
        if (mounted) setState(() => _isFocused = focused);
      },
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _isPressed = true),
        onTapCancel: disabled ? null : () => setState(() => _isPressed = false),
        onTapUp: disabled ? null : (_) => setState(() => _isPressed = false),
        onTap: disabled ? null : widget.onTap,
        child: MouseRegion(
          cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(
                    widget.icon,
                    size: 14,
                    color: disabled ? fgColor : (widget.isActive ? widget.accentColor : fgColor),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: fgColor,
                    ),
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
