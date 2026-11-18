import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/settings/game_settings.dart';
import 'package:pro_peloton_manager/state/game_settings_notifier.dart';
import 'package:pro_peloton_manager/ui/widgets/audio_mixer_advanced_settings_panel.dart';

class _InMemorySettingsStorage implements GameSettingsStorage {
  GameSettings? _saved;

  @override
  Future<GameSettings?> load() async => _saved;

  @override
  Future<void> save(GameSettings settings) async {
    _saved = settings;
  }
}

void main() {
  group('AudioMixerAdvancedSettingsNotifier', () {
    test('has 6 independent channels with valid defaults', () {
      final settingsNotifier = GameSettingsNotifier.withStorage(
        storage: _InMemorySettingsStorage(),
      );
      final notifier = AudioMixerAdvancedSettingsNotifier(settingsNotifier);

      expect(AudioMixerChannelId.values.length, 6);
      expect(notifier.state.channels.length, 6);
      expect(notifier.state.activePreset, AudioMixerPreset.broadcastTv);
    });

    test('adjusting channel volume clamps, sets custom preset, and syncs GameSettings',
        () {
      final settingsNotifier = GameSettingsNotifier.withStorage(
        storage: _InMemorySettingsStorage(),
      );
      final notifier = AudioMixerAdvancedSettingsNotifier(settingsNotifier);

      notifier.setChannelVolume(AudioMixerChannelId.raceRadio, 1.4);
      expect(notifier.state.channel(AudioMixerChannelId.raceRadio).volume, 1.0);
      expect(notifier.state.activePreset, AudioMixerPreset.custom);
      expect(settingsNotifier.state.raceRadioVolume, 1.0);

      notifier.setChannelVolume(AudioMixerChannelId.musicScore, 0.25);
      expect(
        notifier.state.channel(AudioMixerChannelId.musicScore).volume,
        0.25,
      );
      // Other channels remain untouched
      expect(
        notifier.state.channel(AudioMixerChannelId.crowdAtmosphere).volume,
        AudioMixerChannelId.crowdAtmosphere.defaultVolume,
      );
    });

    test('mute, solo, and global mute affect effectiveGain accurately', () {
      final notifier = AudioMixerAdvancedSettingsNotifier();
      notifier.setChannelVolume(AudioMixerChannelId.master, 1.0);
      notifier.setChannelVolume(AudioMixerChannelId.raceEnvironment, 0.8);
      notifier.setChannelVolume(AudioMixerChannelId.crowdAtmosphere, 0.6);

      notifier.toggleChannelSolo(AudioMixerChannelId.raceEnvironment);
      expect(notifier.state.hasAnySolo, isTrue);
      expect(
        notifier.state.effectiveGain(AudioMixerChannelId.raceEnvironment),
        closeTo(0.8, 0.001),
      );
      expect(
        notifier.state.effectiveGain(AudioMixerChannelId.crowdAtmosphere),
        0.0,
      );

      notifier.toggleChannelMute(AudioMixerChannelId.raceEnvironment);
      expect(
        notifier.state.effectiveGain(AudioMixerChannelId.raceEnvironment),
        0.0,
      );

      notifier.toggleChannelMute(AudioMixerChannelId.raceEnvironment);
      notifier.toggleChannelSolo(AudioMixerChannelId.raceEnvironment);
      notifier.toggleAllMute();
      expect(notifier.state.masterOutputMeterLevel, 0.0);
    });

    test('applyPreset and resetToDefaults update all 6 channels', () {
      final notifier = AudioMixerAdvancedSettingsNotifier();
      notifier.applyPreset(AudioMixerPreset.tacticalFocus);

      expect(notifier.state.activePreset, AudioMixerPreset.tacticalFocus);
      expect(notifier.state.channel(AudioMixerChannelId.raceRadio).volume, 1.0);
      expect(notifier.state.spatial3dPanning, isFalse);

      notifier.resetToDefaults();
      expect(notifier.state.activePreset, AudioMixerPreset.broadcastTv);
      expect(notifier.state.spatial3dPanning, isTrue);
    });
  });

  group('AudioMixerAdvancedSettingsPanel Widget', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      bool enabled = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameSettingsProvider.overrideWith(
              (ref) => GameSettingsNotifier.withStorage(
                storage: _InMemorySettingsStorage(),
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: AudioMixerAdvancedSettingsPanel(enabled: enabled),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders 6 sliders without overflow on mobile 390x844',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.byType(Slider), findsNWidgets(6));
      expect(find.text('Mikser Dźwięku Pro (6 Kanałów)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders 6 sliders without overflow on tablet 1024x768',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.byType(Slider), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders 6 sliders without overflow on desktop 1600x900',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.byType(Slider), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports preset switching, mute toggle, and disabled state',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Fokus Taktyczny'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('100%'), findsWidgets);

      await tester.tap(find.text('Wycisz Wszystko'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('WYCISZONO'), findsOneWidget);

      await pumpPanelAtSize(tester, const Size(1024, 768), enabled: false);
      expect(tester.takeException(), isNull);
    });
  });
}
