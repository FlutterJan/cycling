// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../audio/race_radio_tts_and_beeps.dart';
import '../events/race_radio_generator.dart';

/// Kontekstowy scenariusz dialogu lub inicjatywy kolarza w Radiu Wyścigowym.
enum RadioChatterScenario {
  badLegsWarning('Ciężkie nogi'),
  attackInitiative('Inicjatywa ataku'),
  crosswindAlert('Wiatr boczny / Wachlarze'),
  mechanicalOrPuncture('Defekt / Przebicie'),
  nutritionAndHydrationRequest('Żywienie i bidony'),
  paceAndRelayRequest('Tempo i zmiany'),
  descentAndPositioningAlert('Zjazd i pozycja'),
  finalKmSprintCallout('Pociąg sprinterski'),
  breakawayCooperationChatter('Współpraca w ucieczce'),
  moraleAndEncouragement('Wsparcie zespołu');

  final String label;
  const RadioChatterScenario(this.label);

  String toJson() => name;

  static RadioChatterScenario fromJson(String value) {
    return RadioChatterScenario.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RadioChatterScenario.moraleAndEncouragement,
    );
  }
}

/// Poziom pilności komunikatu głosowego z szosy.
enum RadioChatterUrgency {
  low('Informacyjny'),
  normal('Taktyczny'),
  high('Ostrzeżenie'),
  critical('Alarm');

  final String label;
  const RadioChatterUrgency(this.label);

  Color get color {
    switch (this) {
      case RadioChatterUrgency.low:
        return AppColors.textSecondary;
      case RadioChatterUrgency.normal:
        return AppColors.accentBlue;
      case RadioChatterUrgency.high:
        return AppColors.amberWarning;
      case RadioChatterUrgency.critical:
        return AppColors.crimsonAlert;
    }
  }

  RadioPriority toRadioPriority() {
    switch (this) {
      case RadioChatterUrgency.low:
        return RadioPriority.info;
      case RadioChatterUrgency.normal:
        return RadioPriority.tactical;
      case RadioChatterUrgency.high:
        return RadioPriority.warning;
      case RadioChatterUrgency.critical:
        return RadioPriority.urgent;
    }
  }

  String toJson() => name;

  static RadioChatterUrgency fromJson(String value) {
    return RadioChatterUrgency.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RadioChatterUrgency.normal,
    );
  }
}

/// Ton głosu kolarza w syntezie mowy (zależny od tętna, zmęczenia i stresu).
enum RadioVoiceTone {
  calm('Spokojny'),
  focused('Skupiony'),
  strained('Zmęczony'),
  breathless('Zadyszany'),
  urgent('Pilny'),
  triumphant('Zmotywowany');

  final String label;
  const RadioVoiceTone(this.label);

  String toJson() => name;

  static RadioVoiceTone fromJson(String value) {
    return RadioVoiceTone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RadioVoiceTone.focused,
    );
  }
}

/// Typ decyzji Dyrektora Sportowego w odpowiedzi na inicjatywę kolarza.
enum RadioInitiativeDecisionType {
  approveInitiative('Zatwierdź inicjatywę'),
  holdPosition('Wstrzymaj / Trzymaj koło'),
  counterOrder('Zmień zadanie'),
  acknowledge('Przyjęto');

  final String label;
  const RadioInitiativeDecisionType(this.label);

  String toJson() => name;

  static RadioInitiativeDecisionType fromJson(String value) {
    return RadioInitiativeDecisionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RadioInitiativeDecisionType.acknowledge,
    );
  }
}

/// Opcja szybkiej decyzji Dyrektora Sportowego dla aktywnej inicjatywy radiowej.
class RadioInitiativeOption {
  final String id;
  final RadioInitiativeDecisionType decisionType;
  final String label;
  final String dsResponseText;
  final String tacticalSummary;
  final int moraleDelta;
  final String staminaCostHint;
  final bool isRecommended;

  const RadioInitiativeOption({
    required this.id,
    required this.decisionType,
    required this.label,
    required this.dsResponseText,
    required this.tacticalSummary,
    this.moraleDelta = 0,
    this.staminaCostHint = 'Neutralny',
    this.isRecommended = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'decisionType': decisionType.toJson(),
        'label': label,
        'dsResponseText': dsResponseText,
        'tacticalSummary': tacticalSummary,
        'moraleDelta': moraleDelta,
        'staminaCostHint': staminaCostHint,
        'isRecommended': isRecommended,
      };

  factory RadioInitiativeOption.fromJson(Map<String, dynamic> json) {
    return RadioInitiativeOption(
      id: (json['id'] as String?) ?? 'opt_ack',
      decisionType: RadioInitiativeDecisionType.fromJson(
        (json['decisionType'] as String?) ?? 'acknowledge',
      ),
      label: (json['label'] as String?) ?? 'Przyjęto',
      dsResponseText: (json['dsResponseText'] as String?) ?? 'Przyjąłem, jedź dalej.',
      tacticalSummary: (json['tacticalSummary'] as String?) ?? '',
      moraleDelta: (json['moraleDelta'] as num?)?.toInt() ?? 0,
      staminaCostHint: (json['staminaCostHint'] as String?) ?? 'Neutralny',
      isRecommended: (json['isRecommended'] as bool?) ?? false,
    );
  }
}

/// Parametry syntezy głosu i wizualizacji fali radiowej dla konkretnego kolarza.
class VoiceSynthesisProfile {
  final String riderId;
  final double pitchHz;
  final double speechRateMultiplier;
  final double breathiness;
  final double rfStaticLevel;
  final List<double> waveformBars;

  const VoiceSynthesisProfile({
    required this.riderId,
    required this.pitchHz,
    required this.speechRateMultiplier,
    required this.breathiness,
    required this.rfStaticLevel,
    required this.waveformBars,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'pitchHz': pitchHz,
        'speechRateMultiplier': speechRateMultiplier,
        'breathiness': breathiness,
        'rfStaticLevel': rfStaticLevel,
        'waveformBars': waveformBars,
      };

  factory VoiceSynthesisProfile.fromJson(Map<String, dynamic> json) {
    final rawBars = (json['waveformBars'] as List<dynamic>?) ?? const [];
    return VoiceSynthesisProfile(
      riderId: (json['riderId'] as String?) ?? 'unknown',
      pitchHz: ((json['pitchHz'] as num?)?.toDouble() ?? 125.0).clamp(80.0, 240.0),
      speechRateMultiplier:
          ((json['speechRateMultiplier'] as num?)?.toDouble() ?? 1.0).clamp(0.75, 1.45),
      breathiness: ((json['breathiness'] as num?)?.toDouble() ?? 0.25).clamp(0.0, 1.0),
      rfStaticLevel: ((json['rfStaticLevel'] as num?)?.toDouble() ?? 0.15).clamp(0.0, 1.0),
      waveformBars: rawBars
          .map((e) => ((e as num?)?.toDouble() ?? 0.2).clamp(0.05, 1.0))
          .toList(growable: false),
    );
  }
}

/// Migawka telemetrii i sytuacji wyścigowej kolarza przekazywana do generatora radia.
class RiderRadioChatterContext {
  final String riderId;
  final String riderName;
  final String teamName;
  final String roleLabel;
  final double heartRateBpm;
  final double maxHeartRateBpm;
  final double wPrimePercent;
  final double glycogenPercent;
  final double hydrationPercent;
  final double morale;
  final int dayFormDelta;
  final double gradientPercent;
  final double crosswindKmh;
  final double distanceToFinishKm;
  final double gapToLeaderSeconds;
  final bool isInBreakaway;
  final bool hasMechanicalIssue;
  final bool hasPuncture;
  final bool isCobblesSector;
  final bool isDescent;
  final double teamCarDistanceMeters;
  final double elapsedSeconds;
  final double kilometerMark;
  final String language;

  const RiderRadioChatterContext({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    this.roleLabel = 'Lider',
    this.heartRateBpm = 148.0,
    this.maxHeartRateBpm = 192.0,
    this.wPrimePercent = 82.0,
    this.glycogenPercent = 76.0,
    this.hydrationPercent = 74.0,
    this.morale = 75.0,
    this.dayFormDelta = 0,
    this.gradientPercent = 1.0,
    this.crosswindKmh = 12.0,
    this.distanceToFinishKm = 45.0,
    this.gapToLeaderSeconds = 0.0,
    this.isInBreakaway = false,
    this.hasMechanicalIssue = false,
    this.hasPuncture = false,
    this.isCobblesSector = false,
    this.isDescent = false,
    this.teamCarDistanceMeters = 180.0,
    this.elapsedSeconds = 5400.0,
    this.kilometerMark = 112.0,
    this.language = 'pl',
  });

  double get heartRateRatio =>
      maxHeartRateBpm <= 0 ? 0.7 : (heartRateBpm / maxHeartRateBpm).clamp(0.35, 1.05);
}

/// Wygenerowane zdarzenie dialogu / inicjatywy kolarza w Radiu Wyścigowym.
class TeamRadioChatterEvent {
  final String id;
  final String riderId;
  final String riderName;
  final String teamName;
  final RadioChatterScenario scenario;
  final RadioChatterUrgency urgency;
  final RadioVoiceTone tone;
  final String headline;
  final String dialogueText;
  final String? dsPromptQuestion;
  final bool requiresDecision;
  final double? decisionExpiresAtSeconds;
  final List<RadioInitiativeOption> options;
  final String? selectedOptionId;
  final VoiceSynthesisProfile voiceProfile;
  final double kilometerMark;
  final double elapsedSeconds;

  const TeamRadioChatterEvent({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.scenario,
    required this.urgency,
    required this.tone,
    required this.headline,
    required this.dialogueText,
    this.dsPromptQuestion,
    this.requiresDecision = false,
    this.decisionExpiresAtSeconds,
    this.options = const [],
    this.selectedOptionId,
    required this.voiceProfile,
    required this.kilometerMark,
    required this.elapsedSeconds,
  });

  bool get isResolved => selectedOptionId != null;

  RadioInitiativeOption? get selectedOption {
    if (selectedOptionId == null) return null;
    for (final opt in options) {
      if (opt.id == selectedOptionId) return opt;
    }
    return null;
  }

  String get formattedKm => 'KM ${kilometerMark.toStringAsFixed(1)}';

  String get formattedTime {
    final int totalSec = math.max(0, elapsedSeconds.round());
    final int hours = totalSec ~/ 3600;
    final int minutes = (totalSec % 3600) ~/ 60;
    final int seconds = totalSec % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  RaceRadioMessage toRaceRadioMessage() {
    return RaceRadioMessage(
      id: id,
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      channel: RadioChannel.directeurSportif,
      priority: urgency.toRadioPriority(),
      senderName: '$riderName ($teamName)',
      message: dialogueText,
      highlightedRiderName: riderName,
      highlightedTeamName: teamName,
    );
  }

  TeamRadioChatterEvent copyWith({
    String? id,
    String? riderId,
    String? riderName,
    String? teamName,
    RadioChatterScenario? scenario,
    RadioChatterUrgency? urgency,
    RadioVoiceTone? tone,
    String? headline,
    String? dialogueText,
    String? dsPromptQuestion,
    bool? requiresDecision,
    double? decisionExpiresAtSeconds,
    List<RadioInitiativeOption>? options,
    String? selectedOptionId,
    VoiceSynthesisProfile? voiceProfile,
    double? kilometerMark,
    double? elapsedSeconds,
  }) {
    return TeamRadioChatterEvent(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamName: teamName ?? this.teamName,
      scenario: scenario ?? this.scenario,
      urgency: urgency ?? this.urgency,
      tone: tone ?? this.tone,
      headline: headline ?? this.headline,
      dialogueText: dialogueText ?? this.dialogueText,
      dsPromptQuestion: dsPromptQuestion ?? this.dsPromptQuestion,
      requiresDecision: requiresDecision ?? this.requiresDecision,
      decisionExpiresAtSeconds: decisionExpiresAtSeconds ?? this.decisionExpiresAtSeconds,
      options: options ?? this.options,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      voiceProfile: voiceProfile ?? this.voiceProfile,
      kilometerMark: kilometerMark ?? this.kilometerMark,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'riderId': riderId,
        'riderName': riderName,
        'teamName': teamName,
        'scenario': scenario.toJson(),
        'urgency': urgency.toJson(),
        'tone': tone.toJson(),
        'headline': headline,
        'dialogueText': dialogueText,
        'dsPromptQuestion': dsPromptQuestion,
        'requiresDecision': requiresDecision,
        'decisionExpiresAtSeconds': decisionExpiresAtSeconds,
        'options': options.map((e) => e.toJson()).toList(growable: false),
        'selectedOptionId': selectedOptionId,
        'voiceProfile': voiceProfile.toJson(),
        'kilometerMark': kilometerMark,
        'elapsedSeconds': elapsedSeconds,
      };

  factory TeamRadioChatterEvent.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>?) ?? const [];
    return TeamRadioChatterEvent(
      id: (json['id'] as String?) ?? 'chatter_0',
      riderId: (json['riderId'] as String?) ?? 'rider_0',
      riderName: (json['riderName'] as String?) ?? 'Kolarz',
      teamName: (json['teamName'] as String?) ?? 'Team',
      scenario: RadioChatterScenario.fromJson(
        (json['scenario'] as String?) ?? 'moraleAndEncouragement',
      ),
      urgency: RadioChatterUrgency.fromJson((json['urgency'] as String?) ?? 'normal'),
      tone: RadioVoiceTone.fromJson((json['tone'] as String?) ?? 'focused'),
      headline: (json['headline'] as String?) ?? 'Komunikat radiowy',
      dialogueText: (json['dialogueText'] as String?) ?? '',
      dsPromptQuestion: json['dsPromptQuestion'] as String?,
      requiresDecision: (json['requiresDecision'] as bool?) ?? false,
      decisionExpiresAtSeconds: (json['decisionExpiresAtSeconds'] as num?)?.toDouble(),
      options: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(RadioInitiativeOption.fromJson)
          .toList(growable: false),
      selectedOptionId: json['selectedOptionId'] as String?,
      voiceProfile: json['voiceProfile'] is Map<String, dynamic>
          ? VoiceSynthesisProfile.fromJson(json['voiceProfile'] as Map<String, dynamic>)
          : const VoiceSynthesisProfile(
              riderId: 'rider_0',
              pitchHz: 125.0,
              speechRateMultiplier: 1.0,
              breathiness: 0.25,
              rfStaticLevel: 0.15,
              waveformBars: [0.3, 0.6, 0.8, 0.5, 0.7, 0.4],
            ),
      kilometerMark: (json['kilometerMark'] as num?)?.toDouble() ?? 0.0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Wynik rozstrzygnięcia inicjatywy kolarza przez Dyrektora Sportowego.
class RadioDecisionResolution {
  final String eventId;
  final RadioInitiativeOption chosenOption;
  final RaceRadioMessage dsReplyMessage;
  final int moraleDelta;
  final String tacticalOrderHint;
  final double resolvedAtSeconds;

  const RadioDecisionResolution({
    required this.eventId,
    required this.chosenOption,
    required this.dsReplyMessage,
    required this.moraleDelta,
    required this.tacticalOrderHint,
    required this.resolvedAtSeconds,
  });
}

/// Stan silnika kontekstowych dialogów i inicjatyw w Radiu Wyścigowym.
class TeamRadioChatterState {
  final TeamRadioChatterEvent? activeInitiative;
  final List<TeamRadioChatterEvent> history;
  final Map<RadioChatterScenario, double> lastCooldownByScenario;
  final bool isMuted;
  final bool radioStaticReductionEnabled;
  final RadioChatterScenario? selectedFilter;
  final int totalInitiativesTriggered;
  final int totalDecisionsMade;

  const TeamRadioChatterState({
    this.activeInitiative,
    this.history = const [],
    this.lastCooldownByScenario = const {},
    this.isMuted = false,
    this.radioStaticReductionEnabled = true,
    this.selectedFilter,
    this.totalInitiativesTriggered = 0,
    this.totalDecisionsMade = 0,
  });

  List<TeamRadioChatterEvent> get filteredHistory {
    if (selectedFilter == null) return history;
    return history.where((e) => e.scenario == selectedFilter).toList(growable: false);
  }

  TeamRadioChatterState copyWith({
    TeamRadioChatterEvent? activeInitiative,
    bool clearActiveInitiative = false,
    List<TeamRadioChatterEvent>? history,
    Map<RadioChatterScenario, double>? lastCooldownByScenario,
    bool? isMuted,
    bool? radioStaticReductionEnabled,
    RadioChatterScenario? selectedFilter,
    bool clearFilter = false,
    int? totalInitiativesTriggered,
    int? totalDecisionsMade,
  }) {
    return TeamRadioChatterState(
      activeInitiative:
          clearActiveInitiative ? null : (activeInitiative ?? this.activeInitiative),
      history: history ?? this.history,
      lastCooldownByScenario: lastCooldownByScenario ?? this.lastCooldownByScenario,
      isMuted: isMuted ?? this.isMuted,
      radioStaticReductionEnabled:
          radioStaticReductionEnabled ?? this.radioStaticReductionEnabled,
      selectedFilter: clearFilter ? null : (selectedFilter ?? this.selectedFilter),
      totalInitiativesTriggered:
          totalInitiativesTriggered ?? this.totalInitiativesTriggered,
      totalDecisionsMade: totalDecisionsMade ?? this.totalDecisionsMade,
    );
  }
}

/// Główny silnik generowania kontekstowych dialogów, inicjatyw i syntezy głosu kolarzy.
class TeamRadioVoiceSynthesisAndChatterEngine {
  final RaceRadioAudioSynthesizer audioSynthesizer;

  const TeamRadioVoiceSynthesisAndChatterEngine({
    this.audioSynthesizer = const RaceRadioAudioSynthesizer(),
  });

  static const double defaultScenarioCooldownSeconds = 180.0;

  /// Ocenia kontekst wyścigowy kolarza i generuje adekwatny dialog lub inicjatywę taktyczną.
  /// Zwraca `null`, jeśli scenariusz jest na cooldownie lub brak istotnego bodźca.
  TeamRadioChatterEvent? evaluateContext(
    RiderRadioChatterContext context, {
    Map<RadioChatterScenario, double> lastTriggeredAt = const {},
    double cooldownSeconds = defaultScenarioCooldownSeconds,
    bool forceTrigger = false,
    int seedOffset = 0,
  }) {
    final scenario = _detectPrimaryScenario(context);
    if (scenario == null) return null;

    if (!forceTrigger) {
      final lastTime = lastTriggeredAt[scenario];
      if (lastTime != null && (context.elapsedSeconds - lastTime) < cooldownSeconds) {
        return null;
      }
    }

    final tone = _computeVoiceTone(context, scenario);
    final urgency = _computeUrgency(context, scenario);
    final voiceProfile = synthesizeVoiceProfile(
      context,
      tone: tone,
      seedOffset: seedOffset,
    );

    final template = _buildLocalizedDialogue(
      context,
      scenario: scenario,
      tone: tone,
      seedOffset: seedOffset,
    );

    final options = _buildInitiativeOptions(context, scenario);
    final requiresDecision = options.isNotEmpty;

    return TeamRadioChatterEvent(
      id: 'chatter_${scenario.name}_${context.riderId}_${context.elapsedSeconds.round()}',
      riderId: context.riderId,
      riderName: context.riderName,
      teamName: context.teamName,
      scenario: scenario,
      urgency: urgency,
      tone: tone,
      headline: template.headline,
      dialogueText: template.dialogue,
      dsPromptQuestion: template.question,
      requiresDecision: requiresDecision,
      decisionExpiresAtSeconds:
          requiresDecision ? context.elapsedSeconds + 25.0 : null,
      options: options,
      voiceProfile: voiceProfile,
      kilometerMark: context.kilometerMark,
      elapsedSeconds: context.elapsedSeconds,
    );
  }

  /// Tworzy profil syntezy głosu (wysokość, tempo, zadyszka, szum RF oraz próbki fali).
  VoiceSynthesisProfile synthesizeVoiceProfile(
    RiderRadioChatterContext context, {
    required RadioVoiceTone tone,
    bool staticReductionEnabled = true,
    int seedOffset = 0,
  }) {
    final idHash = context.riderId.codeUnits.fold<int>(17, (acc, c) => acc * 31 + c);
    final rng = math.Random(idHash + context.elapsedSeconds.round() + seedOffset);

    // Bazowa wysokość głosu zależna od ID kolarza (95..155 Hz) + napięcie w stresie
    final basePitch = 98.0 + (idHash.abs() % 52);
    final stressLift = (tone == RadioVoiceTone.urgent || tone == RadioVoiceTone.breathless)
        ? 18.0
        : (tone == RadioVoiceTone.strained ? 10.0 : 0.0);
    final pitchHz = (basePitch + stressLift).clamp(85.0, 210.0);

    final breathiness = ((context.heartRateRatio - 0.55) * 1.45 +
            ((100.0 - context.wPrimePercent.clamp(0.0, 100.0)) / 220.0))
        .clamp(0.08, 0.96);

    final speechRate = switch (tone) {
      RadioVoiceTone.urgent => 1.24,
      RadioVoiceTone.breathless => 1.15,
      RadioVoiceTone.triumphant => 1.08,
      RadioVoiceTone.strained => 0.92,
      RadioVoiceTone.calm => 0.96,
      RadioVoiceTone.focused => 1.02,
    };

    final rawStatic = (context.teamCarDistanceMeters / 1600.0).clamp(0.05, 0.78) +
        (context.gradientPercent > 9.0 ? 0.08 : 0.0);
    final rfStaticLevel =
        (staticReductionEnabled ? rawStatic * 0.55 : rawStatic).clamp(0.03, 0.92);

    // 24 słupki obwiedni fali mowy (symulacja sylab i pauz oddechowych)
    final bars = List<double>.generate(24, (index) {
      final syllableWave = 0.45 + 0.45 * math.sin((index * 0.65) + rng.nextDouble() * 0.8);
      final breathDip = (tone == RadioVoiceTone.breathless && index % 6 == 5) ? 0.22 : 1.0;
      final energyScale = tone == RadioVoiceTone.urgent ? 1.12 : 0.95;
      return (syllableWave * breathDip * energyScale).clamp(0.10, 1.0);
    }, growable: false);

    return VoiceSynthesisProfile(
      riderId: context.riderId,
      pitchHz: pitchHz,
      speechRateMultiplier: speechRate,
      breathiness: breathiness,
      rfStaticLevel: rfStaticLevel,
      waveformBars: bars,
    );
  }

  /// Syntetyzuje krótki bufor audio PCM stereo (otwarcie PTT + zmodulowany impuls wokalny + zamknięcie RF).
  AudioStereoBuffer synthesizeChatterAudioCue(
    TeamRadioChatterEvent event, {
    double volume = 0.85,
  }) {
    final openCue = audioSynthesizer.generateRadioSquelchBeep(volume: volume);
    final closeCue = audioSynthesizer.generateRadioCloseSquelch(volume: volume * 0.85);

    final sampleRate = audioSynthesizer.sampleRate;
    final bars = event.voiceProfile.waveformBars.isEmpty
        ? const [0.4, 0.7, 0.5, 0.8]
        : event.voiceProfile.waveformBars;

    // 22 ms na każdy segment sylaby fali głosowej -> ~528 ms zmodulowanego sygnału radiowego
    final segmentFrames = (0.022 * sampleRate).round();
    final voiceFrames = bars.length * segmentFrames;
    final totalFrames = openCue.frameCount + voiceFrames + closeCue.frameCount;

    final left = Float32List(totalFrames);
    final right = Float32List(totalFrames);

    for (int i = 0; i < openCue.frameCount; i++) {
      left[i] = openCue.left[i];
      right[i] = openCue.right[i];
    }

    final dt = 1.0 / sampleRate;
    final rng = math.Random(event.id.hashCode);
    final pitch = event.voiceProfile.pitchHz;
    final staticGain = event.voiceProfile.rfStaticLevel * 0.22;
    final breathGain = event.voiceProfile.breathiness * 0.14;

    for (int b = 0; b < bars.length; b++) {
      final amp = bars[b] * 0.34 * volume;
      final startIdx = openCue.frameCount + b * segmentFrames;
      for (int j = 0; j < segmentFrames; j++) {
        final t = (b * segmentFrames + j) * dt;
        final fundamental = math.sin(2.0 * math.pi * pitch * t);
        final formant = 0.45 * math.sin(2.0 * math.pi * (pitch * 2.4) * t);
        final noise = (rng.nextDouble() * 2.0 - 1.0) * (staticGain + breathGain);
        final env = math.sin((j / segmentFrames) * math.pi);
        final sample = ((fundamental + formant) * amp * env) + (noise * volume);

        final idx = startIdx + j;
        left[idx] = sample.clamp(-0.98, 0.98);
        right[idx] = sample.clamp(-0.98, 0.98);
      }
    }

    final closeOffset = openCue.frameCount + voiceFrames;
    for (int i = 0; i < closeCue.frameCount; i++) {
      left[closeOffset + i] = closeCue.left[i];
      right[closeOffset + i] = closeCue.right[i];
    }

    return AudioStereoBuffer(left: left, right: right, sampleRate: sampleRate);
  }

  /// Rozstrzyga wybraną przez Dyrektora Sportowego odpowiedź na inicjatywę kolarza.
  RadioDecisionResolution resolveInitiative(
    TeamRadioChatterEvent event,
    RadioInitiativeOption option, {
    required double resolvedAtSeconds,
  }) {
    final dsReply = RaceRadioMessage(
      id: 'ds_reply_${event.id}_${option.id}',
      kilometerMark: event.kilometerMark,
      elapsedSeconds: resolvedAtSeconds,
      channel: RadioChannel.directeurSportif,
      priority: RadioPriority.tactical,
      senderName: 'DS ${event.teamName}',
      message: option.dsResponseText,
      highlightedRiderName: event.riderName,
      highlightedTeamName: event.teamName,
    );

    return RadioDecisionResolution(
      eventId: event.id,
      chosenOption: option,
      dsReplyMessage: dsReply,
      moraleDelta: option.moraleDelta,
      tacticalOrderHint: option.tacticalSummary,
      resolvedAtSeconds: resolvedAtSeconds,
    );
  }

  RadioChatterScenario? _detectPrimaryScenario(RiderRadioChatterContext ctx) {
    if (ctx.hasPuncture || ctx.hasMechanicalIssue) {
      return RadioChatterScenario.mechanicalOrPuncture;
    }
    if (ctx.dayFormDelta <= -2 && (ctx.gradientPercent >= 5.0 || ctx.wPrimePercent < 45.0)) {
      return RadioChatterScenario.badLegsWarning;
    }
    if (ctx.glycogenPercent < 32.0 || ctx.hydrationPercent < 35.0) {
      return RadioChatterScenario.nutritionAndHydrationRequest;
    }
    if (ctx.crosswindKmh >= 28.0 && !ctx.isDescent) {
      return RadioChatterScenario.crosswindAlert;
    }
    if (ctx.distanceToFinishKm <= 3.5 && !ctx.isInBreakaway && ctx.gradientPercent < 3.5) {
      return RadioChatterScenario.finalKmSprintCallout;
    }
    if (ctx.isInBreakaway && ctx.gapToLeaderSeconds.abs() < 5.0 && ctx.distanceToFinishKm > 8.0) {
      return RadioChatterScenario.breakawayCooperationChatter;
    }
    if ((ctx.dayFormDelta >= 2 || ctx.morale >= 80.0) &&
        ctx.wPrimePercent >= 70.0 &&
        ctx.distanceToFinishKm <= 35.0 &&
        ctx.gradientPercent >= 4.0) {
      return RadioChatterScenario.attackInitiative;
    }
    if (ctx.isDescent || ctx.isCobblesSector) {
      return RadioChatterScenario.descentAndPositioningAlert;
    }
    if (ctx.heartRateRatio >= 0.90 && ctx.gradientPercent >= 6.0) {
      return RadioChatterScenario.paceAndRelayRequest;
    }
    return RadioChatterScenario.moraleAndEncouragement;
  }

  RadioVoiceTone _computeVoiceTone(
    RiderRadioChatterContext ctx,
    RadioChatterScenario scenario,
  ) {
    if (scenario == RadioChatterScenario.mechanicalOrPuncture) {
      return RadioVoiceTone.urgent;
    }
    if (ctx.heartRateRatio >= 0.92 || ctx.wPrimePercent < 25.0) {
      return RadioVoiceTone.breathless;
    }
    if (scenario == RadioChatterScenario.badLegsWarning || ctx.glycogenPercent < 30.0) {
      return RadioVoiceTone.strained;
    }
    if (scenario == RadioChatterScenario.attackInitiative ||
        scenario == RadioChatterScenario.moraleAndEncouragement) {
      return ctx.morale >= 75.0 ? RadioVoiceTone.triumphant : RadioVoiceTone.focused;
    }
    if (ctx.heartRateRatio < 0.72) {
      return RadioVoiceTone.calm;
    }
    return RadioVoiceTone.focused;
  }

  RadioChatterUrgency _computeUrgency(
    RiderRadioChatterContext ctx,
    RadioChatterScenario scenario,
  ) {
    switch (scenario) {
      case RadioChatterScenario.mechanicalOrPuncture:
        return RadioChatterUrgency.critical;
      case RadioChatterScenario.badLegsWarning:
      case RadioChatterScenario.crosswindAlert:
      case RadioChatterScenario.nutritionAndHydrationRequest:
        return ctx.glycogenPercent < 22.0 || ctx.crosswindKmh >= 38.0
            ? RadioChatterUrgency.critical
            : RadioChatterUrgency.high;
      case RadioChatterScenario.attackInitiative:
      case RadioChatterScenario.finalKmSprintCallout:
      case RadioChatterScenario.paceAndRelayRequest:
      case RadioChatterScenario.descentAndPositioningAlert:
      case RadioChatterScenario.breakawayCooperationChatter:
        return RadioChatterUrgency.normal;
      case RadioChatterScenario.moraleAndEncouragement:
        return RadioChatterUrgency.low;
    }
  }

  _DialogueTemplate _buildLocalizedDialogue(
    RiderRadioChatterContext ctx, {
    required RadioChatterScenario scenario,
    required RadioVoiceTone tone,
    int seedOffset = 0,
  }) {
    final isEn = ctx.language.toLowerCase().startsWith('en');
    final variant = (ctx.elapsedSeconds.round() + seedOffset) % 2;

    if (isEn) {
      return _buildEnglishTemplate(ctx, scenario, variant);
    }

    switch (scenario) {
      case RadioChatterScenario.badLegsWarning:
        return _DialogueTemplate(
          headline: 'Raport dyspozycji: ciężkie nogi',
          dialogue: variant == 0
              ? 'Szefie, nogi dziś jak z ołowiu... Na tym nachyleniu ${ctx.gradientPercent.toStringAsFixed(1)}% jadę już pod progiem, nie wiem czy utrzymam koło przy kolejnym skoku.'
              : 'Radio, tutaj ${ctx.riderName}. Odczuwam wyraźny spadek mocy, tętno ${ctx.heartRateBpm.round()} BPM przy ${ctx.wPrimePercent.round()}% W\'. Potrzebuję osłony.',
          question: 'Czy przełączyć ochronę drużyny na wicelidera i oszczędzać siły?',
        );
      case RadioChatterScenario.attackInitiative:
        return _DialogueTemplate(
          headline: 'Inicjatywa ataku z grupy!',
          dialogue: variant == 0
              ? 'Czuję świetną nogę! Rywale patrzą po sobie na ${ctx.gradientPercent.toStringAsFixed(1)}%, mogę teraz poprawić z kontry i urwać im 20 sekund!'
              : 'DS, mam jeszcze ${ctx.wPrimePercent.round()}% zapasu W\'. Do mety ${ctx.distanceToFinishKm.toStringAsFixed(1)} km — daj zielone światło, to odpalę!',
          question: 'Zezwolić na atak czy utrzymać dyscyplinę taktyczną?',
        );
      case RadioChatterScenario.crosswindAlert:
        return _DialogueTemplate(
          headline: 'Alarm wiatrowy: formują się wachlarze',
          dialogue: variant == 0
              ? 'Uwaga, na otwartym terenie wieje ${ctx.crosswindKmh.round()} km/h z boku! Z przodu już rwią peleton na echelony, musimy natychmiast przesunąć się na rant!'
              : 'Mocny boczny wiatr! Jeśli nie ustawimy pociągu przy prawej krawędzi, za chwilę peleton pęknie na pół!',
          question: 'Rzucić pomocników do ustawienia wachlarza na czele?',
        );
      case RadioChatterScenario.mechanicalOrPuncture:
        return _DialogueTemplate(
          headline: ctx.hasPuncture ? 'Przebita opona! Potrzebne koło' : 'Awaria napędu / defekt!',
          dialogue: ctx.hasPuncture
              ? 'Kapeć z tyłu! Zjeżdżam na prawą stronę szosy, wóz techniczny musi podać nowe koło natychmiast!'
              : 'Spadł łańcuch i zablokował przerzutkę! Zatrzymuję się po prawej, niech mechanik szykuje zapasowy rower!',
          question: 'Wysłać pomocnika z kołem czy czekać na wóz techniczny?',
        );
      case RadioChatterScenario.nutritionAndHydrationRequest:
        return _DialogueTemplate(
          headline: 'Niski poziom glikogenu / puste bidony',
          dialogue: variant == 0
              ? 'Bidony są puste, a zostało jeszcze ${ctx.distanceToFinishKm.toStringAsFixed(1)} km. Glikogen spada do ${ctx.glycogenPercent.round()}% — muszę zjechać do wozu po żele!'
              : 'Zaczyna brakować paliwa, czuję nadchodzącą ścianę. Wyślijcie kogoś po bidony z izotonikiem i żele kofeinowe!',
          question: 'Zlecić zjazd do wozu technicznego po zaopatrzenie?',
        );
      case RadioChatterScenario.paceAndRelayRequest:
        return _DialogueTemplate(
          headline: 'Prośba o zmianę tempa na czele',
          dialogue:
              'Tempo grupy jest nierówne, tętno skacze na ${ctx.heartRateBpm.round()} BPM. Potrzebujemy dwóch pomocników na czele, żeby ustabilizować waty pod górę.',
          question: 'Podkręcić tempo pomocników czy zachować rezerwy?',
        );
      case RadioChatterScenario.descentAndPositioningAlert:
        return _DialogueTemplate(
          headline: ctx.isCobblesSector ? 'Walka o pozycję przed brukiem' : 'Techniczny zjazd — wysokie ryzyko',
          dialogue: ctx.isCobblesSector
              ? 'Zbliżamy się do sektora bruku, jest straszny ścisk w czubie! Musimy wejść w pierwszą dziesiątkę, bo z tyłu będą kraksy.'
              : 'Asfalt na zakrętach jest śliski, prędkość rośnie. Wchodzę w agresywną linię zjazdu, trzymajcie mnie na oku.',
          question: null,
        );
      case RadioChatterScenario.finalKmSprintCallout:
        return _DialogueTemplate(
          headline: 'Finałowy pociąg sprinterski!',
          dialogue:
              'Zostało ${ctx.distanceToFinishKm.toStringAsFixed(1)} km do kreski! Pociąg jest ustawiony, potrzebujemy ostatniego rozprowadzenia na 300 metrów przed metą!',
          question: 'Rozpocząć pełne rozprowadzenie pociągu?',
        );
      case RadioChatterScenario.breakawayCooperationChatter:
        return const _DialogueTemplate(
          headline: 'Tarcia w ucieczce — brak zmian',
          dialogue:
              'Ten gość z nami w odjeździe tylko siedzi na kole i odmawia zmian! Czy mam dalej ciągnąć, czy zacząć skakać i go zgubić?',
          question: 'Ciągnąć ucieczkę dalej czy pozorować zmęczenie (Sit On)?',
        );
      case RadioChatterScenario.moraleAndEncouragement:
        return const _DialogueTemplate(
          headline: 'Melduję pełną gotowość',
          dialogue:
              'W grupie wszystko pod kontrolą, nogi kręcą równo. Jedziemy dokładnie według planu przedstartowego, bez odbioru!',
          question: null,
        );
    }
  }

  _DialogueTemplate _buildEnglishTemplate(
    RiderRadioChatterContext ctx,
    RadioChatterScenario scenario,
    int variant,
  ) {
    switch (scenario) {
      case RadioChatterScenario.badLegsWarning:
        return _DialogueTemplate(
          headline: 'Rider report: Heavy legs',
          dialogue:
              'Boss, my legs feel completely flat on this ${ctx.gradientPercent.toStringAsFixed(1)}% slope. HR is ${ctx.heartRateBpm.round()} BPM — I might crack if pace rises.',
          question: 'Shift team protection to co-leader and conserve energy?',
        );
      case RadioChatterScenario.attackInitiative:
        return _DialogueTemplate(
          headline: 'Attack initiative requested!',
          dialogue:
              'I have ${ctx.wPrimePercent.round()}% W\' left and rivals are hesitating with ${ctx.distanceToFinishKm.toStringAsFixed(1)} km to go. Give me the green light to launch!',
          question: 'Approve attack or hold tactical discipline?',
        );
      case RadioChatterScenario.crosswindAlert:
        return _DialogueTemplate(
          headline: 'Crosswind echelon warning',
          dialogue:
              'Crosswind is hitting ${ctx.crosswindKmh.round()} km/h! The peloton is splitting into echelons — we need to move to the gutter right now!',
          question: 'Send domestiques to the front for echelon positioning?',
        );
      case RadioChatterScenario.mechanicalOrPuncture:
        return _DialogueTemplate(
          headline: ctx.hasPuncture ? 'Rear puncture!' : 'Mechanical issue!',
          dialogue: ctx.hasPuncture
              ? 'Flat rear tire! Pulling over to the right, need a wheel change immediately!'
              : 'Dropped chain and jammed derailleur! Waiting on the right for the team car!',
          question: 'Swap wheel with domestique or wait for team car?',
        );
      case RadioChatterScenario.nutritionAndHydrationRequest:
        return _DialogueTemplate(
          headline: 'Low glycogen / Empty bidons',
          dialogue:
              'Bidons are dry and glycogen is down to ${ctx.glycogenPercent.round()}%. Requesting permission to drop back to the car for gels!',
          question: 'Allow rider to drop back to team car for nutrition?',
        );
      case RadioChatterScenario.paceAndRelayRequest:
        return _DialogueTemplate(
          headline: 'Pace stabilization request',
          dialogue:
              'Surges in the group are spiking my HR to ${ctx.heartRateBpm.round()} BPM. Need two domestiques on the front to set a steady tempo.',
          question: 'Increase domestique pace or save legs?',
        );
      case RadioChatterScenario.descentAndPositioningAlert:
        return _DialogueTemplate(
          headline: ctx.isCobblesSector ? 'Cobbles positioning fight' : 'Technical descent alert',
          dialogue: ctx.isCobblesSector
              ? 'Approaching the cobble sector, fighting for top-10 wheel before the entry!'
              : 'Fast technical descent ahead, keeping aero tuck and watching the apexes.',
          question: null,
        );
      case RadioChatterScenario.finalKmSprintCallout:
        return _DialogueTemplate(
          headline: 'Final km sprint leadout!',
          dialogue:
              '${ctx.distanceToFinishKm.toStringAsFixed(1)} km to the line! Leadout train is locked in, ready to launch at 300m!',
          question: 'Commit full sprint leadout train?',
        );
      case RadioChatterScenario.breakawayCooperationChatter:
        return const _DialogueTemplate(
          headline: 'Breakaway wheelsucking dispute',
          dialogue:
              'This rider is sitting on my wheel and skipping every pull! Should I keep driving or sit on and bluff?',
          question: 'Keep pulling or sit on and conserve?',
        );
      case RadioChatterScenario.moraleAndEncouragement:
        return const _DialogueTemplate(
          headline: 'Status check: All clear',
          dialogue:
              'Feeling smooth in the bunch, holding position according to the race plan. Over and out!',
          question: null,
        );
    }
  }

  List<RadioInitiativeOption> _buildInitiativeOptions(
    RiderRadioChatterContext ctx,
    RadioChatterScenario scenario,
  ) {
    switch (scenario) {
      case RadioChatterScenario.attackInitiative:
        return [
          RadioInitiativeOption(
            id: 'opt_attack_go',
            decisionType: RadioInitiativeDecisionType.approveInitiative,
            label: 'Zgoda — Atakuj teraz!',
            dsResponseText: 'Zielone światło ${ctx.riderName}! Jedź pełnym gazem i nie oglądaj się za siebie!',
            tacticalSummary: 'Aktywuje natychmiastowy atak z użyciem zapasu W\'',
            moraleDelta: 6,
            staminaCostHint: 'Wysoki koszt W\'',
            isRecommended: ctx.wPrimePercent >= 75.0,
          ),
          RadioInitiativeOption(
            id: 'opt_attack_hold',
            decisionType: RadioInitiativeDecisionType.holdPosition,
            label: 'Czekaj na ostatni kilometr',
            dsResponseText: 'Spokojnie ${ctx.riderName}, nie pal zapałek za wcześnie. Zostań na kole do finału.',
            tacticalSummary: 'Oszczędza energię beztlenową na decydujący moment',
            moraleDelta: -1,
            staminaCostHint: 'Oszczędny',
            isRecommended: ctx.wPrimePercent < 75.0,
          ),
        ];
      case RadioChatterScenario.badLegsWarning:
        return const [
          RadioInitiativeOption(
            id: 'opt_badlegs_protect',
            decisionType: RadioInitiativeDecisionType.counterOrder,
            label: 'Przekaż ochronę wiceliderowi',
            dsResponseText: 'Przyjąłem, jedziesz swoim rytmem na koło pomocnika. Wicelider przejmuje rolę numer jeden.',
            tacticalSummary: 'Zmniejsza presję na lidera i chroni przed stratą czasu',
            moraleDelta: 2,
            staminaCostHint: 'Ochrona sił',
            isRecommended: true,
          ),
          RadioInitiativeOption(
            id: 'opt_badlegs_push',
            decisionType: RadioInitiativeDecisionType.holdPosition,
            label: 'Walcz i zostań w grupie',
            dsResponseText: 'Dasz radę, trzymaj koło za wszelką cenę — kryzys minie za szczytem!',
            tacticalSummary: 'Utrzymuje pozycję kosztem szybkiego zużycia glikogenu',
            moraleDelta: -3,
            staminaCostHint: 'Ryzyko odcięcia',
          ),
        ];
      case RadioChatterScenario.mechanicalOrPuncture:
        return const [
          RadioInitiativeOption(
            id: 'opt_mech_wheel',
            decisionType: RadioInitiativeDecisionType.approveInitiative,
            label: 'Weź koło od pomocnika',
            dsResponseText: 'Pomocnik oddaje koło natychmiast! Wóz techniczny wraca do wsparcia za 40 sekund.',
            tacticalSummary: 'Szybka naprawa (8–12 s), pomocnik zostaje z tyłu',
            moraleDelta: 4,
            staminaCostHint: 'Szybki powrót',
            isRecommended: true,
          ),
          RadioInitiativeOption(
            id: 'opt_mech_car',
            decisionType: RadioInitiativeDecisionType.counterOrder,
            label: 'Czekaj na wóz techniczny',
            dsResponseText: 'Zostań po prawej, wóz techniczny już jedzie z kompletnym rowerem!',
            tacticalSummary: 'Pełna wymiana sprzętu, strata ok. 22–30 sekund',
            moraleDelta: 0,
            staminaCostHint: 'Bez utraty pomocnika',
          ),
        ];
      case RadioChatterScenario.crosswindAlert:
        return const [
          RadioInitiativeOption(
            id: 'opt_wind_echelon',
            decisionType: RadioInitiativeDecisionType.approveInitiative,
            label: 'Cała ekipa na rant!',
            dsResponseText: 'Pełna mobilizacja! Wszyscy na czoło i formujemy wachlarz po prawej stronie!',
            tacticalSummary: 'Zabezpiecza lidera w 1. grupie na wietrze bocznym',
            moraleDelta: 4,
            staminaCostHint: 'Średni koszt',
            isRecommended: true,
          ),
          RadioInitiativeOption(
            id: 'opt_wind_hide',
            decisionType: RadioInitiativeDecisionType.holdPosition,
            label: 'Szukaj osłony w grupie',
            dsResponseText: 'Zostań schowany za wysokimi kolarzami i nie wychylaj nosa na wiatr.',
            tacticalSummary: 'Niższy wydatek W\', ale ryzyko pęknięcia peletonu',
            moraleDelta: 0,
            staminaCostHint: 'Niski koszt',
          ),
        ];
      case RadioChatterScenario.nutritionAndHydrationRequest:
        return const [
          RadioInitiativeOption(
            id: 'opt_feed_car',
            decisionType: RadioInitiativeDecisionType.approveInitiative,
            label: 'Zjedź do wozu po żele',
            dsResponseText: 'Zjeżdżaj do wozu po dwa bidony i pakiet żeli — czekamy na Ciebie!',
            tacticalSummary: 'Uzupełnia glikogen i nawodnienie (+25% zapasów)',
            moraleDelta: 3,
            staminaCostHint: 'Regeneracja',
            isRecommended: true,
          ),
          RadioInitiativeOption(
            id: 'opt_feed_wait',
            decisionType: RadioInitiativeDecisionType.holdPosition,
            label: 'Wytrzymaj do strefy bufetu',
            dsResponseText: 'Nie trać pozycji teraz, pomocnik przywiezie Ci bidony za kilka minut.',
            tacticalSummary: 'Brak utraty pozycji, dalszy spadek glikogenu',
            moraleDelta: -2,
            staminaCostHint: 'Ryzyko głodu',
          ),
        ];
      case RadioChatterScenario.breakawayCooperationChatter:
        return const [
          RadioInitiativeOption(
            id: 'opt_brk_siton',
            decisionType: RadioInitiativeDecisionType.counterOrder,
            label: 'Przestań dawać zmiany (Sit On)',
            dsResponseText: 'Koniec pracy za darmo! Usiądź mu na kole i zmuś go do roboty.',
            tacticalSummary: 'Oszczędza energię w ucieczce i wywiera presję psychologiczną',
            moraleDelta: 2,
            staminaCostHint: 'Oszczędny',
            isRecommended: true,
          ),
          RadioInitiativeOption(
            id: 'opt_brk_pull',
            decisionType: RadioInitiativeDecisionType.approveInitiative,
            label: 'Ciągnij dalej dla przewagi',
            dsResponseText: 'Nieważne co robią inni — potrzebujemy tej przewagi nad peletonem, dawaj pełne zmiany!',
            tacticalSummary: 'Zwiększa szansę dojechania ucieczki do mety',
            moraleDelta: 1,
            staminaCostHint: 'Wysoki koszt',
          ),
        ];
      case RadioChatterScenario.paceAndRelayRequest:
      case RadioChatterScenario.finalKmSprintCallout:
        return const [
          RadioInitiativeOption(
            id: 'opt_pace_commit',
            decisionType: RadioInitiativeDecisionType.approveInitiative,
            label: 'Wykonaj manewr drużynowy',
            dsResponseText: 'Zrozumiałem! Pomocnicy przejmują kontrolę nad tempem grupy.',
            tacticalSummary: 'Ustawia formację drużyny na czole grupy',
            moraleDelta: 3,
            staminaCostHint: 'Kontrolowany',
            isRecommended: true,
          ),
          RadioInitiativeOption(
            id: 'opt_pace_ack',
            decisionType: RadioInitiativeDecisionType.acknowledge,
            label: 'Przyjęto, bez zmian',
            dsResponseText: 'Przyjąłem meldunek, utrzymuj aktualną pozycję.',
            tacticalSummary: 'Brak ingerencji w bieżący rozkaz',
            moraleDelta: 0,
            staminaCostHint: 'Neutralny',
          ),
        ];
      case RadioChatterScenario.descentAndPositioningAlert:
      case RadioChatterScenario.moraleAndEncouragement:
        return const [];
    }
  }
}

class _DialogueTemplate {
  final String headline;
  final String dialogue;
  final String? question;

  const _DialogueTemplate({
    required this.headline,
    required this.dialogue,
    this.question,
  });
}

/// Kontroler stanu Riverpod dla Radia Wyścigowego i kontekstowych inicjatyw kolarzy.
class TeamRadioChatterNotifier extends StateNotifier<TeamRadioChatterState> {
  final TeamRadioVoiceSynthesisAndChatterEngine _engine;

  TeamRadioChatterNotifier({
    TeamRadioVoiceSynthesisAndChatterEngine? engine,
  })  : _engine = engine ?? const TeamRadioVoiceSynthesisAndChatterEngine(),
        super(const TeamRadioChatterState());

  TeamRadioChatterEvent? processRiderContext(
    RiderRadioChatterContext context, {
    bool forceTrigger = false,
  }) {
    final event = _engine.evaluateContext(
      context,
      lastTriggeredAt: state.lastCooldownByScenario,
      forceTrigger: forceTrigger,
    );
    if (event == null) return null;

    final updatedCooldowns = Map<RadioChatterScenario, double>.from(
      state.lastCooldownByScenario,
    )..[event.scenario] = event.elapsedSeconds;

    final updatedHistory = [event, ...state.history].take(40).toList(growable: false);

    state = state.copyWith(
      activeInitiative: event.requiresDecision ? event : state.activeInitiative,
      history: updatedHistory,
      lastCooldownByScenario: updatedCooldowns,
      totalInitiativesTriggered:
          state.totalInitiativesTriggered + (event.requiresDecision ? 1 : 0),
    );
    return event;
  }

  RadioDecisionResolution? decideActiveInitiative(
    String optionId, {
    required double currentElapsedSeconds,
  }) {
    final active = state.activeInitiative;
    if (active == null) return null;

    final option = active.options.cast<RadioInitiativeOption?>().firstWhere(
          (o) => o?.id == optionId,
          orElse: () => null,
        );
    if (option == null) return null;

    final resolution = _engine.resolveInitiative(
      active,
      option,
      resolvedAtSeconds: currentElapsedSeconds,
    );

    final resolvedEvent = active.copyWith(selectedOptionId: option.id);
    final updatedHistory = state.history
        .map((item) => item.id == resolvedEvent.id ? resolvedEvent : item)
        .toList(growable: false);

    state = state.copyWith(
      clearActiveInitiative: true,
      history: updatedHistory,
      totalDecisionsMade: state.totalDecisionsMade + 1,
    );
    return resolution;
  }

  void dismissActiveInitiative() {
    if (state.activeInitiative == null) return;
    state = state.copyWith(clearActiveInitiative: true);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleStaticReduction() {
    state = state.copyWith(
      radioStaticReductionEnabled: !state.radioStaticReductionEnabled,
    );
  }

  void setScenarioFilter(RadioChatterScenario? scenario) {
    if (scenario == null || scenario == state.selectedFilter) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(selectedFilter: scenario);
    }
  }

  void clearHistory() {
    state = state.copyWith(
      clearActiveInitiative: true,
      history: const [],
      lastCooldownByScenario: const {},
    );
  }
}

final teamRadioChatterProvider =
    StateNotifierProvider<TeamRadioChatterNotifier, TeamRadioChatterState>((ref) {
  return TeamRadioChatterNotifier();
});

/// Produkcyjny panel diagnostyczno-taktyczny Radia Wyścigowego z syntezą głosu i inicjatywami kolarzy.
class TeamRadioChatterConsolePanel extends ConsumerWidget {
  final ValueChanged<RadioDecisionResolution>? onDecisionResolved;
  final double currentElapsedSeconds;

  const TeamRadioChatterConsolePanel({
    super.key,
    this.onDecisionResolved,
    this.currentElapsedSeconds = 5420.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamRadioChatterProvider);
    final notifier = ref.read(teamRadioChatterProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 1024.0;
        final isCompact = width < 600;
        final isDesktop = width >= 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(state, notifier, isCompact),
              const SizedBox(height: 12),
              _buildFilterStrip(state, notifier),
              const SizedBox(height: 12),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildActiveInitiativeCard(state, notifier),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 6,
                      child: _buildHistoryList(state),
                    ),
                  ],
                )
              else ...[
                _buildActiveInitiativeCard(state, notifier),
                const SizedBox(height: 12),
                _buildHistoryList(state),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    TeamRadioChatterState state,
    TeamRadioChatterNotifier notifier,
    bool isCompact,
  ) {
    final statsBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Text(
        'Decyzje: ${state.totalDecisionsMade}/${state.totalInitiativesTriggered}',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.goldAccent,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );

    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        statsBadge,
        _InteractiveRadioButton(
          label: state.radioStaticReductionEnabled ? 'DSP Filtr: ON' : 'DSP Filtr: OFF',
          icon: Icons.graphic_eq_rounded,
          isActive: state.radioStaticReductionEnabled,
          accentColor: AppColors.accentBlue,
          onPressed: notifier.toggleStaticReduction,
        ),
        _InteractiveRadioButton(
          label: state.isMuted ? 'Wyciszone' : 'Radio Live',
          icon: state.isMuted ? Icons.volume_off_rounded : Icons.headset_mic_rounded,
          isActive: !state.isMuted,
          accentColor: state.isMuted ? AppColors.crimsonAlert : AppColors.statusSuccess,
          onPressed: notifier.toggleMute,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(),
          const SizedBox(height: 10),
          controls,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildTitleRow()),
        const SizedBox(width: 12),
        controls,
      ],
    );
  }

  Widget _buildTitleRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryAccent, width: 1),
          ),
          child: const Icon(
            Icons.radio_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Radio Wyścigowe — Inicjatywy Kolarzy',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Kontekstowe dialogi DS, synteza głosu PTT i decyzje na szosie',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
  }

  Widget _buildFilterStrip(
    TeamRadioChatterState state,
    TeamRadioChatterNotifier notifier,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ScenarioFilterChip(
            label: 'Wszystkie',
            selected: state.selectedFilter == null,
            onTap: () => notifier.setScenarioFilter(null),
          ),
          const SizedBox(width: 6),
          for (final scenario in RadioChatterScenario.values) ...[
            _ScenarioFilterChip(
              label: scenario.label,
              selected: state.selectedFilter == scenario,
              onTap: () => notifier.setScenarioFilter(scenario),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveInitiativeCard(
    TeamRadioChatterState state,
    TeamRadioChatterNotifier notifier,
  ) {
    final active = state.activeInitiative;
    if (active == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors_rounded, color: AppColors.textSecondary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nasłuch kanału drużynowego aktywny',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Brak oczekujących inicjatyw wymagających decyzji Dyrektora Sportowego.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active.urgency.color, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: active.urgency.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  active.urgency.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: active.urgency.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${active.riderName} • ${active.tone.label}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                active.formattedKm,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _VoiceWaveformStrip(profile: active.voiceProfile, accent: active.urgency.color),
          const SizedBox(height: 10),
          Text(
            '„${active.dialogueText}”',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          if (active.dsPromptQuestion != null) ...[
            const SizedBox(height: 8),
            Text(
              active.dsPromptQuestion!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accentBlue,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in active.options)
                _InteractiveRadioButton(
                  label: option.label,
                  icon: option.isRecommended
                      ? Icons.star_rounded
                      : Icons.check_circle_outline_rounded,
                  isActive: option.isRecommended,
                  accentColor:
                      option.isRecommended ? AppColors.goldAccent : AppColors.accentBlue,
                  onPressed: state.isMuted
                      ? null
                      : () {
                          final res = notifier.decideActiveInitiative(
                            option.id,
                            currentElapsedSeconds: currentElapsedSeconds,
                          );
                          if (res != null) {
                            onDecisionResolved?.call(res);
                          }
                        },
                ),
              _InteractiveRadioButton(
                label: 'Ignoruj',
                icon: Icons.close_rounded,
                isActive: false,
                accentColor: AppColors.textSecondary,
                onPressed: notifier.dismissActiveInitiative,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(TeamRadioChatterState state) {
    final items = state.filteredHistory;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 1),
        ),
        child: const Text(
          'Brak zarejestrowanych transmisji radiowych w bieżącym filtrze.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(10),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.urgency.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.riderName} — ${item.headline}',
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
                      '${item.formattedKm} • ${item.formattedTime}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.dialogueText,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.selectedOption != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'DS: ${item.selectedOption!.label}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VoiceWaveformStrip extends StatelessWidget {
  final VoiceSynthesisProfile profile;
  final Color accent;

  const _VoiceWaveformStrip({
    required this.profile,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (final bar in profile.waveformBars)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: FractionallySizedBox(
                          heightFactor: bar.clamp(0.12, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${profile.pitchHz.round()} Hz • RF ${(profile.rfStaticLevel * 100).round()}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveRadioButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _InteractiveRadioButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractiveRadioButton> createState() => _InteractiveRadioButtonState();
}

class _InteractiveRadioButtonState extends State<_InteractiveRadioButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final bgColor = isDisabled
        ? AppColors.background
        : _isPressed
            ? widget.accentColor.withValues(alpha: 0.28)
            : _isHovered
                ? widget.accentColor.withValues(alpha: 0.18)
                : widget.isActive
                    ? widget.accentColor.withValues(alpha: 0.12)
                    : AppColors.surfaceLight;

    final borderColor = isDisabled
        ? AppTheme.borderColor
        : _isFocused
            ? AppColors.goldAccent
            : (_isHovered || widget.isActive)
                ? widget.accentColor
                : AppColors.cardBorder;

    final fgColor = isDisabled ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: MouseRegion(
          cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: isDisabled ? fgColor : widget.accentColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

class _ScenarioFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScenarioFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ScenarioFilterChip> createState() => _ScenarioFilterChipState();
}

class _ScenarioFilterChipState extends State<_ScenarioFilterChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : _isHovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.primaryAccent
            : _isHovered
                ? AppColors.cardBorder
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
