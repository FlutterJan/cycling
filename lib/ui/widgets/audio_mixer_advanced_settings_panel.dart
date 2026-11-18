// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../state/game_settings_notifier.dart';

/// Identyfikatory 6 niezależnych kanałów rozbudowanego miksera dźwięku.
enum AudioMixerChannelId {
  master(
    'Master',
    'Główna szyna wyjściowa',
    Icons.tune_rounded,
    AppColors.goldAccent,
    0.85,
  ),
  raceEnvironment(
    'Otoczenie Wyścigu',
    'Wiatr (v²), bębenek i szosa',
    Icons.air_rounded,
    AppColors.accentBlue,
    0.85,
  ),
  crowdAtmosphere(
    'Atmosfera i Kibice',
    'Wrzawa tłumu i dzwonki KOM',
    Icons.groups_rounded,
    AppColors.statusSuccess,
    0.80,
  ),
  raceRadio(
    'Radio Wyścigowe',
    'Komunikaty DS i alarmy GPS',
    Icons.headset_mic_rounded,
    AppColors.amberWarning,
    0.90,
  ),
  musicScore(
    'Muzyka Adaptacyjna',
    'Dynamiczna ścieżka orkiestrowa',
    Icons.music_note_rounded,
    AppColors.primaryAccent,
    0.70,
  ),
  uiHaptics(
    'Interfejs UI',
    'Kliknięcia, pieczęcie i garaż',
    Icons.touch_app_rounded,
    AppColors.cyanAccent,
    0.75,
  );

  final String label;
  final String description;
  final IconData icon;
  final Color accentColor;
  final double defaultVolume;

  const AudioMixerChannelId(
    this.label,
    this.description,
    this.icon,
    this.accentColor,
    this.defaultVolume,
  );
}

/// Gotowe profile brzmieniowe miksera 6-kanałowego.
enum AudioMixerPreset {
  broadcastTv(
    'Transmisja TV',
    'Zbalansowany miks z wyraźnym radiem DS i tłumem na finiszu',
  ),
  pelotonImmersion(
    'Pełne Zanurzenie',
    'Maksymalny realizm szosy, wiatru i bębenka bez muzyki w tle',
  ),
  tacticalFocus(
    'Fokus Taktyczny',
    'Priorytet dla radia wyścigowego, alarmów i czystego UI',
  ),
  nightQuiet(
    'Tryb Nocny',
    'Łagodny poziom wyjściowy z aktywnym limiterem dynamiki',
  ),
  custom(
    'Własny',
    'Indywidualne ustawienia kanałów skonfigurowane przez gracza',
  );

  final String label;
  final String description;

  const AudioMixerPreset(this.label, this.description);
}

/// Stan pojedynczego kanału w 6-kanałowym mikserze audio.
@immutable
class AudioMixerChannelState {
  final AudioMixerChannelId id;
  final double volume;
  final bool isMuted;
  final bool isSolo;
  final double peakLevel;

  const AudioMixerChannelState({
    required this.id,
    required this.volume,
    this.isMuted = false,
    this.isSolo = false,
    this.peakLevel = 0.0,
  });

  AudioMixerChannelState copyWith({
    double? volume,
    bool? isMuted,
    bool? isSolo,
    double? peakLevel,
  }) {
    return AudioMixerChannelState(
      id: id,
      volume: (volume ?? this.volume).clamp(0.0, 1.0),
      isMuted: isMuted ?? this.isMuted,
      isSolo: isSolo ?? this.isSolo,
      peakLevel: (peakLevel ?? this.peakLevel).clamp(0.0, 1.0),
    );
  }

  /// Wartość w decybelach [dB] dla aktualnego poziomu suwaka.
  String get formattedDb {
    if (isMuted || volume <= 0.001) {
      return '-∞ dB';
    }
    final db = 20.0 * (math.log(volume) / math.ln10);
    return '${db >= 0 ? '+' : ''}${db.toStringAsFixed(1)} dB';
  }

  /// Wartość procentowa 0–100%.
  int get percentage => (volume * 100).round();
}

/// Kompletny stan rozbudowanego 6-kanałowego miksera dźwięku.
@immutable
class AudioMixerAdvancedSettingsState {
  final Map<AudioMixerChannelId, AudioMixerChannelState> channels;
  final AudioMixerPreset activePreset;
  final bool radioAutoDucking;
  final bool spatial3dPanning;
  final bool dynamicRangeLimiter;
  final bool isAllMuted;
  final AudioMixerChannelId? lastTestedChannel;

  const AudioMixerAdvancedSettingsState({
    required this.channels,
    this.activePreset = AudioMixerPreset.broadcastTv,
    this.radioAutoDucking = true,
    this.spatial3dPanning = true,
    this.dynamicRangeLimiter = true,
    this.isAllMuted = false,
    this.lastTestedChannel,
  });

  factory AudioMixerAdvancedSettingsState.defaults() {
    return AudioMixerAdvancedSettingsState(
      channels: {
        for (final id in AudioMixerChannelId.values)
          id: AudioMixerChannelState(
            id: id,
            volume: id.defaultVolume,
            peakLevel: id.defaultVolume * 0.72,
          ),
      },
      activePreset: AudioMixerPreset.broadcastTv,
    );
  }

  AudioMixerChannelState channel(AudioMixerChannelId id) {
    return channels[id] ??
        AudioMixerChannelState(id: id, volume: id.defaultVolume);
  }

  bool get hasAnySolo =>
      channels.values.any((c) => c.id != AudioMixerChannelId.master && c.isSolo);

  /// Efektywna głośność kanału uwzględniająca Master, Mute, Solo oraz Ducking.
  double effectiveGain(AudioMixerChannelId id) {
    if (isAllMuted) return 0.0;
    final master = channel(AudioMixerChannelId.master);
    if (master.isMuted || master.volume <= 0.0) return 0.0;

    final ch = channel(id);
    if (ch.isMuted) return 0.0;

    if (id == AudioMixerChannelId.master) {
      return master.volume;
    }

    if (hasAnySolo && !ch.isSolo) {
      return 0.0;
    }

    double gain = ch.volume * master.volume;
    if (dynamicRangeLimiter && gain > 0.92) {
      gain = 0.92 + (gain - 0.92) * 0.5;
    }
    return gain.clamp(0.0, 1.0);
  }

  /// Szacowany poziom wyjściowy szyny Master L/R w zakresie [0.0, 1.0].
  double get masterOutputMeterLevel {
    if (isAllMuted) return 0.0;
    final master = channel(AudioMixerChannelId.master);
    if (master.isMuted) return 0.0;

    double sum = 0.0;
    int count = 0;
    for (final id in AudioMixerChannelId.values) {
      if (id == AudioMixerChannelId.master) continue;
      final g = effectiveGain(id);
      if (g > 0.0) {
        sum += g;
        count++;
      }
    }
    if (count == 0) return 0.0;
    final avg = (sum / count) * 1.15;
    return avg.clamp(0.0, 1.0);
  }

  AudioMixerAdvancedSettingsState copyWith({
    Map<AudioMixerChannelId, AudioMixerChannelState>? channels,
    AudioMixerPreset? activePreset,
    bool? radioAutoDucking,
    bool? spatial3dPanning,
    bool? dynamicRangeLimiter,
    bool? isAllMuted,
    AudioMixerChannelId? lastTestedChannel,
    bool clearLastTested = false,
  }) {
    return AudioMixerAdvancedSettingsState(
      channels: channels ?? this.channels,
      activePreset: activePreset ?? this.activePreset,
      radioAutoDucking: radioAutoDucking ?? this.radioAutoDucking,
      spatial3dPanning: spatial3dPanning ?? this.spatial3dPanning,
      dynamicRangeLimiter: dynamicRangeLimiter ?? this.dynamicRangeLimiter,
      isAllMuted: isAllMuted ?? this.isAllMuted,
      lastTestedChannel:
          clearLastTested ? null : (lastTestedChannel ?? this.lastTestedChannel),
    );
  }
}

/// Kontroler stanu 6-kanałowego miksera audio zsynchronizowany z [GameSettingsNotifier].
class AudioMixerAdvancedSettingsNotifier
    extends StateNotifier<AudioMixerAdvancedSettingsState> {
  final GameSettingsNotifier? _settingsNotifier;

  AudioMixerAdvancedSettingsNotifier([this._settingsNotifier])
      : super(AudioMixerAdvancedSettingsState.defaults());

  /// Ustawia głośność wybranego kanału [0.0, 1.0] i synchronizuje z globalnymi ustawieniami.
  void setChannelVolume(AudioMixerChannelId id, double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    final updated = Map<AudioMixerChannelId, AudioMixerChannelState>.from(
      state.channels,
    );
    final current = state.channel(id);
    updated[id] = current.copyWith(
      volume: clamped,
      peakLevel: current.isMuted ? 0.0 : clamped * 0.78,
    );

    state = state.copyWith(
      channels: updated,
      activePreset: AudioMixerPreset.custom,
    );
    _syncChannelToSettings(id, clamped);
  }

  /// Przełącza wyciszenie (Mute) wybranego kanału.
  void toggleChannelMute(AudioMixerChannelId id) {
    final updated = Map<AudioMixerChannelId, AudioMixerChannelState>.from(
      state.channels,
    );
    final current = state.channel(id);
    final nextMuted = !current.isMuted;
    updated[id] = current.copyWith(
      isMuted: nextMuted,
      peakLevel: nextMuted ? 0.0 : current.volume * 0.72,
    );
    state = state.copyWith(channels: updated);
  }

  /// Przełącza tryb Solo dla wybranego kanału (z wyłączeniem szyny Master).
  void toggleChannelSolo(AudioMixerChannelId id) {
    if (id == AudioMixerChannelId.master) return;
    final updated = Map<AudioMixerChannelId, AudioMixerChannelState>.from(
      state.channels,
    );
    final current = state.channel(id);
    updated[id] = current.copyWith(isSolo: !current.isSolo);
    state = state.copyWith(channels: updated);
  }

  /// Wyzwala testowy impuls audio/wizualny na wybranym kanale.
  void triggerChannelTest(AudioMixerChannelId id) {
    final updated = Map<AudioMixerChannelId, AudioMixerChannelState>.from(
      state.channels,
    );
    final current = state.channel(id);
    final gain = state.effectiveGain(id);
    updated[id] = current.copyWith(
      peakLevel: gain > 0.0 ? math.min(1.0, gain * 1.08) : 0.0,
    );
    state = state.copyWith(
      channels: updated,
      lastTestedChannel: id,
    );
  }

  /// Włącza lub wyłącza globalne wyciszenie wszystkich kanałów.
  void toggleAllMute() {
    state = state.copyWith(isAllMuted: !state.isAllMuted);
  }

  void setRadioAutoDucking(bool enabled) {
    state = state.copyWith(
      radioAutoDucking: enabled,
      activePreset: AudioMixerPreset.custom,
    );
  }

  void setSpatial3dPanning(bool enabled) {
    state = state.copyWith(
      spatial3dPanning: enabled,
      activePreset: AudioMixerPreset.custom,
    );
  }

  void setDynamicRangeLimiter(bool enabled) {
    state = state.copyWith(
      dynamicRangeLimiter: enabled,
      activePreset: AudioMixerPreset.custom,
    );
  }

  /// Aplikuje jeden z gotowych profili miksera audio.
  void applyPreset(AudioMixerPreset preset) {
    if (preset == AudioMixerPreset.custom) return;

    final Map<AudioMixerChannelId, double> volumes;
    final bool ducking;
    final bool spatial;
    final bool limiter;

    switch (preset) {
      case AudioMixerPreset.broadcastTv:
        volumes = const {
          AudioMixerChannelId.master: 0.85,
          AudioMixerChannelId.raceEnvironment: 0.78,
          AudioMixerChannelId.crowdAtmosphere: 0.85,
          AudioMixerChannelId.raceRadio: 0.92,
          AudioMixerChannelId.musicScore: 0.70,
          AudioMixerChannelId.uiHaptics: 0.75,
        };
        ducking = true;
        spatial = true;
        limiter = true;
      case AudioMixerPreset.pelotonImmersion:
        volumes = const {
          AudioMixerChannelId.master: 0.90,
          AudioMixerChannelId.raceEnvironment: 1.00,
          AudioMixerChannelId.crowdAtmosphere: 0.95,
          AudioMixerChannelId.raceRadio: 0.80,
          AudioMixerChannelId.musicScore: 0.15,
          AudioMixerChannelId.uiHaptics: 0.60,
        };
        ducking = true;
        spatial = true;
        limiter = true;
      case AudioMixerPreset.tacticalFocus:
        volumes = const {
          AudioMixerChannelId.master: 0.85,
          AudioMixerChannelId.raceEnvironment: 0.45,
          AudioMixerChannelId.crowdAtmosphere: 0.35,
          AudioMixerChannelId.raceRadio: 1.00,
          AudioMixerChannelId.musicScore: 0.30,
          AudioMixerChannelId.uiHaptics: 0.85,
        };
        ducking = true;
        spatial = false;
        limiter = true;
      case AudioMixerPreset.nightQuiet:
        volumes = const {
          AudioMixerChannelId.master: 0.55,
          AudioMixerChannelId.raceEnvironment: 0.60,
          AudioMixerChannelId.crowdAtmosphere: 0.50,
          AudioMixerChannelId.raceRadio: 0.78,
          AudioMixerChannelId.musicScore: 0.45,
          AudioMixerChannelId.uiHaptics: 0.55,
        };
        ducking = true;
        spatial = true;
        limiter = true;
      case AudioMixerPreset.custom:
        return;
    }

    final updated = <AudioMixerChannelId, AudioMixerChannelState>{};
    for (final id in AudioMixerChannelId.values) {
      final v = volumes[id] ?? id.defaultVolume;
      updated[id] = AudioMixerChannelState(
        id: id,
        volume: v,
        isMuted: false,
        isSolo: false,
        peakLevel: v * 0.74,
      );
      _syncChannelToSettings(id, v);
    }

    state = state.copyWith(
      channels: updated,
      activePreset: preset,
      radioAutoDucking: ducking,
      spatial3dPanning: spatial,
      dynamicRangeLimiter: limiter,
      isAllMuted: false,
      clearLastTested: true,
    );
  }

  /// Przywraca ustawienia fabryczne miksera.
  void resetToDefaults() {
    applyPreset(AudioMixerPreset.broadcastTv);
  }

  void _syncChannelToSettings(AudioMixerChannelId id, double volume) {
    final notifier = _settingsNotifier;
    if (notifier == null) return;
    switch (id) {
      case AudioMixerChannelId.master:
        notifier.setMasterVolume(volume);
      case AudioMixerChannelId.raceEnvironment:
        notifier.setRaceEnvironmentVolume(volume);
      case AudioMixerChannelId.crowdAtmosphere:
        notifier.setCrowdAtmosphereVolume(volume);
      case AudioMixerChannelId.raceRadio:
        notifier.setRaceRadioVolume(volume);
      case AudioMixerChannelId.uiHaptics:
        notifier.setUiSoundsVolume(volume);
      case AudioMixerChannelId.musicScore:
        // Muzyka adaptacyjna zarządzana lokalnie w mikserze 6-kanałowym.
        break;
    }
  }
}

/// Provider zaawansowanego 6-kanałowego miksera dźwięku.
final audioMixerAdvancedSettingsProvider = StateNotifierProvider<
    AudioMixerAdvancedSettingsNotifier, AudioMixerAdvancedSettingsState>((ref) {
  final settingsNotifier = ref.watch(gameSettingsProvider.notifier);
  return AudioMixerAdvancedSettingsNotifier(settingsNotifier);
});

/// Rozbudowany panel miksera dźwięku z 6 niezależnymi suwakami głośności,
/// obsługą Mute/Solo, presetami brzmieniowymi, miernikami VU i pełną responsywnością.
class AudioMixerAdvancedSettingsPanel extends ConsumerStatefulWidget {
  /// Czy panel jest aktywny i interaktywny (stan disabled blokuje obsługę).
  final bool enabled;

  /// Opcjonalny callback wywoływany przy zmianie poziomu kanału.
  final void Function(AudioMixerChannelId channel, double volume)?
      onChannelVolumeChanged;

  /// Opcjonalny callback wywoływany przy teście kanału.
  final void Function(AudioMixerChannelId channel)? onChannelTest;

  const AudioMixerAdvancedSettingsPanel({
    super.key,
    this.enabled = true,
    this.onChannelVolumeChanged,
    this.onChannelTest,
  });

  @override
  ConsumerState<AudioMixerAdvancedSettingsPanel> createState() =>
      _AudioMixerAdvancedSettingsPanelState();
}

class _AudioMixerAdvancedSettingsPanelState
    extends ConsumerState<AudioMixerAdvancedSettingsPanel> {
  static const Duration _animDuration = Duration(milliseconds: 240);
  static const Curve _animCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final mixerState = ref.watch(audioMixerAdvancedSettingsProvider);
    final notifier = ref.read(audioMixerAdvancedSettingsProvider.notifier);

    return AnimatedOpacity(
      duration: _animDuration,
      curve: _animCurve,
      opacity: widget.enabled ? 1.0 : 0.48,
      child: AbsorbPointer(
        absorbing: !widget.enabled,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final bool isMobile = width < 600;
              final bool isDesktop = width >= 1100;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(mixerState, notifier, isMobile),
                  const SizedBox(height: 14),
                  _buildPresetStrip(mixerState, notifier),
                  const SizedBox(height: 16),
                  if (isDesktop)
                    _buildDesktopConsoleLayout(mixerState, notifier)
                  else if (isMobile)
                    _buildMobileChannelList(mixerState, notifier)
                  else
                    _buildTabletGridLayout(mixerState, notifier),
                  const SizedBox(height: 16),
                  _buildMasterOutputAndProcessingFooter(
                    mixerState,
                    notifier,
                    isMobile: isMobile,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    AudioMixerAdvancedSettingsState mixerState,
    AudioMixerAdvancedSettingsNotifier notifier,
    bool isMobile,
  ) {
    final titleBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.equalizer_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mikser Dźwięku Pro (6 Kanałów)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                mixerState.activePreset.description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final actionButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MixerActionButton(
          label: mixerState.isAllMuted ? 'Odmutuj Wszystko' : 'Wycisz Wszystko',
          icon: mixerState.isAllMuted
              ? Icons.volume_off_rounded
              : Icons.volume_up_rounded,
          isActive: mixerState.isAllMuted,
          activeColor: AppColors.crimsonAlert,
          enabled: widget.enabled,
          onPressed: notifier.toggleAllMute,
        ),
        _MixerActionButton(
          label: 'Resetuj',
          icon: Icons.restart_alt_rounded,
          isActive: false,
          activeColor: AppColors.goldAccent,
          enabled: widget.enabled,
          onPressed: notifier.resetToDefaults,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          actionButtons,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        actionButtons,
      ],
    );
  }

  Widget _buildPresetStrip(
    AudioMixerAdvancedSettingsState mixerState,
    AudioMixerAdvancedSettingsNotifier notifier,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AudioMixerPreset.values.map((preset) {
        final isSelected = mixerState.activePreset == preset;
        final isCustom = preset == AudioMixerPreset.custom;
        return _PresetChipButton(
          label: preset.label,
          selected: isSelected,
          enabled: widget.enabled && !isCustom,
          onTap: isCustom ? null : () => notifier.applyPreset(preset),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopConsoleLayout(
    AudioMixerAdvancedSettingsState mixerState,
    AudioMixerAdvancedSettingsNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < AudioMixerChannelId.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _VerticalChannelFaderStrip(
              channel: mixerState.channel(AudioMixerChannelId.values[i]),
              effectiveGain:
                  mixerState.effectiveGain(AudioMixerChannelId.values[i]),
              isSoloDimmed: mixerState.hasAnySolo &&
                  AudioMixerChannelId.values[i] != AudioMixerChannelId.master &&
                  !mixerState.channel(AudioMixerChannelId.values[i]).isSolo,
              isAllMuted: mixerState.isAllMuted,
              isRecentlyTested: mixerState.lastTestedChannel ==
                  AudioMixerChannelId.values[i],
              enabled: widget.enabled,
              onVolumeChanged: (v) {
                notifier.setChannelVolume(AudioMixerChannelId.values[i], v);
                widget.onChannelVolumeChanged
                    ?.call(AudioMixerChannelId.values[i], v);
              },
              onToggleMute: () =>
                  notifier.toggleChannelMute(AudioMixerChannelId.values[i]),
              onToggleSolo: () =>
                  notifier.toggleChannelSolo(AudioMixerChannelId.values[i]),
              onTest: () {
                notifier.triggerChannelTest(AudioMixerChannelId.values[i]);
                widget.onChannelTest?.call(AudioMixerChannelId.values[i]);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabletGridLayout(
    AudioMixerAdvancedSettingsState mixerState,
    AudioMixerAdvancedSettingsNotifier notifier,
  ) {
    const channels = AudioMixerChannelId.values;
    return Column(
      children: [
        for (int row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HorizontalChannelCard(
                  channel: mixerState.channel(channels[row * 2]),
                  effectiveGain: mixerState.effectiveGain(channels[row * 2]),
                  isSoloDimmed: mixerState.hasAnySolo &&
                      channels[row * 2] != AudioMixerChannelId.master &&
                      !mixerState.channel(channels[row * 2]).isSolo,
                  isAllMuted: mixerState.isAllMuted,
                  isRecentlyTested:
                      mixerState.lastTestedChannel == channels[row * 2],
                  enabled: widget.enabled,
                  onVolumeChanged: (v) {
                    notifier.setChannelVolume(channels[row * 2], v);
                    widget.onChannelVolumeChanged?.call(channels[row * 2], v);
                  },
                  onToggleMute: () =>
                      notifier.toggleChannelMute(channels[row * 2]),
                  onToggleSolo: () =>
                      notifier.toggleChannelSolo(channels[row * 2]),
                  onTest: () {
                    notifier.triggerChannelTest(channels[row * 2]);
                    widget.onChannelTest?.call(channels[row * 2]);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HorizontalChannelCard(
                  channel: mixerState.channel(channels[row * 2 + 1]),
                  effectiveGain:
                      mixerState.effectiveGain(channels[row * 2 + 1]),
                  isSoloDimmed: mixerState.hasAnySolo &&
                      channels[row * 2 + 1] != AudioMixerChannelId.master &&
                      !mixerState.channel(channels[row * 2 + 1]).isSolo,
                  isAllMuted: mixerState.isAllMuted,
                  isRecentlyTested:
                      mixerState.lastTestedChannel == channels[row * 2 + 1],
                  enabled: widget.enabled,
                  onVolumeChanged: (v) {
                    notifier.setChannelVolume(channels[row * 2 + 1], v);
                    widget.onChannelVolumeChanged
                        ?.call(channels[row * 2 + 1], v);
                  },
                  onToggleMute: () =>
                      notifier.toggleChannelMute(channels[row * 2 + 1]),
                  onToggleSolo: () =>
                      notifier.toggleChannelSolo(channels[row * 2 + 1]),
                  onTest: () {
                    notifier.triggerChannelTest(channels[row * 2 + 1]);
                    widget.onChannelTest?.call(channels[row * 2 + 1]);
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMobileChannelList(
    AudioMixerAdvancedSettingsState mixerState,
    AudioMixerAdvancedSettingsNotifier notifier,
  ) {
    return Column(
      children: [
        for (int i = 0; i < AudioMixerChannelId.values.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _HorizontalChannelCard(
            channel: mixerState.channel(AudioMixerChannelId.values[i]),
            effectiveGain:
                mixerState.effectiveGain(AudioMixerChannelId.values[i]),
            isSoloDimmed: mixerState.hasAnySolo &&
                AudioMixerChannelId.values[i] != AudioMixerChannelId.master &&
                !mixerState.channel(AudioMixerChannelId.values[i]).isSolo,
            isAllMuted: mixerState.isAllMuted,
            isRecentlyTested:
                mixerState.lastTestedChannel == AudioMixerChannelId.values[i],
            enabled: widget.enabled,
            onVolumeChanged: (v) {
              notifier.setChannelVolume(AudioMixerChannelId.values[i], v);
              widget.onChannelVolumeChanged
                  ?.call(AudioMixerChannelId.values[i], v);
            },
            onToggleMute: () =>
                notifier.toggleChannelMute(AudioMixerChannelId.values[i]),
            onToggleSolo: () =>
                notifier.toggleChannelSolo(AudioMixerChannelId.values[i]),
            onTest: () {
              notifier.triggerChannelTest(AudioMixerChannelId.values[i]);
              widget.onChannelTest?.call(AudioMixerChannelId.values[i]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMasterOutputAndProcessingFooter(
    AudioMixerAdvancedSettingsState mixerState,
    AudioMixerAdvancedSettingsNotifier notifier, {
    required bool isMobile,
  }) {
    final meterWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Szyna Wyjściowa Master L/R',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                mixerState.isAllMuted
                    ? 'WYCISZONO'
                    : '${(mixerState.masterOutputMeterLevel * 100).round()}% RMS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: mixerState.isAllMuted
                      ? AppColors.crimsonAlert
                      : AppColors.goldAccent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StereoVuMeterBar(
            level: mixerState.masterOutputMeterLevel,
            isMuted: mixerState.isAllMuted,
          ),
        ],
      ),
    );

    final togglesWidget = Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _ProcessingTogglePill(
          label: 'Auto-Ducking Radia (-6 dB)',
          icon: Icons.record_voice_over_rounded,
          value: mixerState.radioAutoDucking,
          enabled: widget.enabled,
          onChanged: notifier.setRadioAutoDucking,
        ),
        _ProcessingTogglePill(
          label: 'Panorama 3D Stereo',
          icon: Icons.surround_sound_rounded,
          value: mixerState.spatial3dPanning,
          enabled: widget.enabled,
          onChanged: notifier.setSpatial3dPanning,
        ),
        _ProcessingTogglePill(
          label: 'Limiter Dynamiki',
          icon: Icons.shield_rounded,
          value: mixerState.dynamicRangeLimiter,
          enabled: widget.enabled,
          onChanged: notifier.setDynamicRangeLimiter,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          meterWidget,
          const SizedBox(height: 10),
          togglesWidget,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        meterWidget,
        const SizedBox(height: 10),
        togglesWidget,
      ],
    );
  }
}

/// Pionowy pasek kanału studyjnego dla widoku Desktop (`>= 1100 px`).
class _VerticalChannelFaderStrip extends StatefulWidget {
  final AudioMixerChannelState channel;
  final double effectiveGain;
  final bool isSoloDimmed;
  final bool isAllMuted;
  final bool isRecentlyTested;
  final bool enabled;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSolo;
  final VoidCallback onTest;

  const _VerticalChannelFaderStrip({
    required this.channel,
    required this.effectiveGain,
    required this.isSoloDimmed,
    required this.isAllMuted,
    required this.isRecentlyTested,
    required this.enabled,
    required this.onVolumeChanged,
    required this.onToggleMute,
    required this.onToggleSolo,
    required this.onTest,
  });

  @override
  State<_VerticalChannelFaderStrip> createState() =>
      _VerticalChannelFaderStripState();
}

class _VerticalChannelFaderStripState
    extends State<_VerticalChannelFaderStrip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final id = widget.channel.id;
    final bool isMaster = id == AudioMixerChannelId.master;
    final bool isEffectivelySilent =
        widget.isAllMuted || widget.channel.isMuted || widget.isSoloDimmed;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowUp):
            _AdjustVolumeIntent(0.05),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _AdjustVolumeIntent(-0.05),
      },
      actions: {
        _AdjustVolumeIntent: CallbackAction<_AdjustVolumeIntent>(
          onInvoke: (intent) {
            widget.onVolumeChanged(
              (widget.channel.volume + intent.delta).clamp(0.0, 1.0),
            );
            return null;
          },
        ),
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surfaceLight : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isFocused
                ? AppColors.goldAccent
                : (isMaster
                    ? AppColors.goldAccent.withValues(alpha: 0.45)
                    : (_isHovered
                        ? id.accentColor.withValues(alpha: 0.55)
                        : const Color(0xFF2A2F3D))),
            width: _isFocused ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              id.icon,
              size: 18,
              color: isEffectivelySilent
                  ? AppColors.textSecondary
                  : id.accentColor,
            ),
            const SizedBox(height: 6),
            Text(
              id.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.channel.formattedDb,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isEffectivelySilent
                    ? AppColors.textSecondary
                    : id.accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 165,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: _buildSliderTheme(context, id.accentColor),
                      child: Slider(
                        value: widget.channel.volume,
                        onChanged:
                            widget.enabled ? widget.onVolumeChanged : null,
                        semanticFormatterCallback: (val) =>
                            '${id.label}: ${(val * 100).round()}%',
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _VerticalChannelVuBar(
                    level: isEffectivelySilent ? 0.0 : widget.effectiveGain,
                    color: id.accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.channel.percentage}%',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniChannelFlagButton(
                  label: 'M',
                  tooltip: 'Wycisz kanał',
                  isActive: widget.channel.isMuted,
                  activeColor: AppColors.crimsonAlert,
                  enabled: widget.enabled,
                  onPressed: widget.onToggleMute,
                ),
                if (!isMaster) ...[
                  const SizedBox(width: 6),
                  _MiniChannelFlagButton(
                    label: 'S',
                    tooltip: 'Tryb Solo',
                    isActive: widget.channel.isSolo,
                    activeColor: AppColors.goldAccent,
                    enabled: widget.enabled,
                    onPressed: widget.onToggleSolo,
                  ),
                ],
                const SizedBox(width: 6),
                _MiniChannelFlagButton(
                  label: '▶',
                  tooltip: 'Testuj kanał',
                  isActive: widget.isRecentlyTested,
                  activeColor: id.accentColor,
                  enabled: widget.enabled,
                  onPressed: widget.onTest,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pozioma karta kanału dla układów Mobile (`390x844`) oraz Tablet (`1024x768`).
class _HorizontalChannelCard extends StatefulWidget {
  final AudioMixerChannelState channel;
  final double effectiveGain;
  final bool isSoloDimmed;
  final bool isAllMuted;
  final bool isRecentlyTested;
  final bool enabled;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSolo;
  final VoidCallback onTest;

  const _HorizontalChannelCard({
    required this.channel,
    required this.effectiveGain,
    required this.isSoloDimmed,
    required this.isAllMuted,
    required this.isRecentlyTested,
    required this.enabled,
    required this.onVolumeChanged,
    required this.onToggleMute,
    required this.onToggleSolo,
    required this.onTest,
  });

  @override
  State<_HorizontalChannelCard> createState() => _HorizontalChannelCardState();
}

class _HorizontalChannelCardState extends State<_HorizontalChannelCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final id = widget.channel.id;
    final bool isMaster = id == AudioMixerChannelId.master;
    final bool isEffectivelySilent =
        widget.isAllMuted || widget.channel.isMuted || widget.isSoloDimmed;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surfaceLight : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isFocused
                ? AppColors.goldAccent
                : (isMaster
                    ? AppColors.goldAccent.withValues(alpha: 0.45)
                    : (_isHovered
                        ? id.accentColor.withValues(alpha: 0.55)
                        : const Color(0xFF2A2F3D))),
            width: _isFocused ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  id.icon,
                  size: 18,
                  color: isEffectivelySilent
                      ? AppColors.textSecondary
                      : id.accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        id.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.channel.percentage}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      widget.channel.formattedDb,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isEffectivelySilent
                            ? AppColors.textSecondary
                            : id.accentColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: _buildSliderTheme(context, id.accentColor),
                    child: Slider(
                      value: widget.channel.volume,
                      onChanged: widget.enabled ? widget.onVolumeChanged : null,
                      semanticFormatterCallback: (val) =>
                          '${id.label}: ${(val * 100).round()}%',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _MiniChannelFlagButton(
                  label: 'M',
                  tooltip: 'Wycisz kanał',
                  isActive: widget.channel.isMuted,
                  activeColor: AppColors.crimsonAlert,
                  enabled: widget.enabled,
                  onPressed: widget.onToggleMute,
                ),
                if (!isMaster) ...[
                  const SizedBox(width: 4),
                  _MiniChannelFlagButton(
                    label: 'S',
                    tooltip: 'Tryb Solo',
                    isActive: widget.channel.isSolo,
                    activeColor: AppColors.goldAccent,
                    enabled: widget.enabled,
                    onPressed: widget.onToggleSolo,
                  ),
                ],
                const SizedBox(width: 4),
                _MiniChannelFlagButton(
                  label: '▶',
                  tooltip: 'Testuj kanał',
                  isActive: widget.isRecentlyTested,
                  activeColor: id.accentColor,
                  enabled: widget.enabled,
                  onPressed: widget.onTest,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: isEffectivelySilent ? 0.0 : widget.effectiveGain,
                minHeight: 3,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isEffectivelySilent
                      ? AppColors.textSecondary
                      : id.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

SliderThemeData _buildSliderTheme(BuildContext context, Color accentColor) {
  return SliderTheme.of(context).copyWith(
    activeTrackColor: accentColor,
    inactiveTrackColor: AppColors.surfaceLight,
    disabledActiveTrackColor: AppColors.textSecondary.withValues(alpha: 0.4),
    disabledInactiveTrackColor: AppColors.surfaceLight,
    thumbColor: AppColors.textPrimary,
    disabledThumbColor: AppColors.textSecondary,
    overlayColor: accentColor.withValues(alpha: 0.2),
    trackHeight: 4,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
  );
}

class _AdjustVolumeIntent extends Intent {
  final double delta;
  const _AdjustVolumeIntent(this.delta);
}

class _VerticalChannelVuBar extends StatelessWidget {
  final double level;
  final Color color;

  const _VerticalChannelVuBar({
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 142,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 6,
        height: 142 * level.clamp(0.0, 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              color,
              level > 0.85 ? AppColors.amberWarning : color,
            ],
          ),
        ),
      ),
    );
  }
}

class _StereoVuMeterBar extends StatelessWidget {
  final double level;
  final bool isMuted;

  const _StereoVuMeterBar({
    required this.level,
    required this.isMuted,
  });

  @override
  Widget build(BuildContext context) {
    final effective = isMuted ? 0.0 : level.clamp(0.0, 1.0);
    return Column(
      children: [
        _buildSingleBar('L', effective),
        const SizedBox(height: 4),
        _buildSingleBar('R', (effective * 0.96).clamp(0.0, 1.0)),
      ],
    );
  }

  Widget _buildSingleBar(String channelTag, double value) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            channelTag,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                value > 0.88
                    ? AppColors.crimsonAlert
                    : (value > 0.72
                        ? AppColors.amberWarning
                        : AppColors.statusSuccess),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniChannelFlagButton extends StatefulWidget {
  final String label;
  final String tooltip;
  final bool isActive;
  final Color activeColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _MiniChannelFlagButton({
    required this.label,
    required this.tooltip,
    required this.isActive,
    required this.activeColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_MiniChannelFlagButton> createState() => _MiniChannelFlagButtonState();
}

class _MiniChannelFlagButtonState extends State<_MiniChannelFlagButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isActive
        ? widget.activeColor.withValues(alpha: 0.24)
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered ? AppColors.surfaceLight : AppColors.surface));

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 28,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.isActive
                        ? widget.activeColor
                        : const Color(0xFF2A2F3D)),
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.isActive
                    ? widget.activeColor
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MixerActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _MixerActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_MixerActionButton> createState() => _MixerActionButtonState();
}

class _MixerActionButtonState extends State<_MixerActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.activeColor.withValues(alpha: 0.2)
                : (_pressed || _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.isActive
                      ? widget.activeColor
                      : const Color(0xFF2A2F3D)),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive
                    ? widget.activeColor
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isActive
                      ? widget.activeColor
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _PresetChipButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PresetChipButton> createState() => _PresetChipButtonState();
}

class _PresetChipButtonState extends State<_PresetChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent.withValues(alpha: 0.28)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.selected
                      ? AppColors.goldAccent
                      : const Color(0xFF2A2F3D)),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.goldAccent
                  : (widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingTogglePill extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ProcessingTogglePill({
    required this.label,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_ProcessingTogglePill> createState() => _ProcessingTogglePillState();
}

class _ProcessingTogglePillState extends State<_ProcessingTogglePill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.value
                ? AppColors.accentBlue.withValues(alpha: 0.14)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.value
                      ? AppColors.accentBlue.withValues(alpha: 0.65)
                      : const Color(0xFF2A2F3D)),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.value
                    ? AppColors.accentBlue
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.value
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
