import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/audio/procedural_cycling_audio_engine.dart';
import 'package:pro_peloton_manager/engine/audio/sound_effects_manager_provider.dart';
import 'package:pro_peloton_manager/engine/events/race_radio_generator.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/settings/game_settings.dart';
import 'package:pro_peloton_manager/state/game_settings_notifier.dart';
import 'package:pro_peloton_manager/ui/screens/settings_and_mod_screen.dart';

class _InMemoryGameSettingsStorage implements GameSettingsStorage {
  GameSettings? saved;
  int saveCount = 0;

  @override
  Future<GameSettings?> load() async => saved;

  @override
  Future<void> save(GameSettings settings) async {
    saved = settings;
    saveCount++;
  }
}

void main() {
  group('UiSoundSynthesizer & SoundEffectsManagerProvider', () {
    test('synthesizes all 5 UI sound effects with valid normalized stereo frames', () {
      const synth = UiSoundSynthesizer();

      for (final effect in UiSoundEffect.values) {
        final buffer = synth.synthesize(effect, volume: 0.8);
        expect(buffer.frameCount, greaterThan(100), reason: 'Empty buffer for ${effect.name}');
        expect(buffer.left.length, equals(buffer.right.length));
        for (int i = 0; i < buffer.frameCount; i++) {
          expect(buffer.left[i].abs(), lessThanOrEqualTo(1.0));
          expect(buffer.right[i].abs(), lessThanOrEqualTo(1.0));
        }
      }

      final fullTt = synth.generateTtFullCountdownSequence(volume: 0.9);
      expect(fullTt.frameCount, greaterThan(40000));
    });

    test('triggers UI sounds, haptics, and records playback history', () {
      final haptics = <UiSoundEffect>[];
      final tags = <String>[];

      final manager = SoundEffectsManagerProvider(
        initialSettings: const GameSettings(soundVolume: 0.9, uiSoundsVolume: 0.8),
        onAudioBufferReady: (_, tag) => tags.add(tag),
        onHapticTrigger: (effect) async => haptics.add(effect),
      );

      expect(manager.playTabClick(), isNotNull);
      expect(manager.playContractSigned(), isNotNull);
      expect(manager.playInboxMessage(), isNotNull);
      expect(manager.playTorqueWrenchClick(), isNotNull);
      expect(manager.playTtCountdownStep(3), isNotNull);
      expect(manager.playTtCountdownStep(0), isNotNull);
      expect(manager.playTtCountdownStep(5), isNull);

      expect(haptics, [
        UiSoundEffect.tabClick,
        UiSoundEffect.contractSigned,
        UiSoundEffect.inboxMessage,
        UiSoundEffect.torqueWrenchClick,
        UiSoundEffect.ttCountdownBeep,
        UiSoundEffect.ttCountdownGo,
      ]);
      expect(tags, [
        'ui_tabClick',
        'ui_contractSigned',
        'ui_inboxMessage',
        'ui_torqueWrenchClick',
        'ui_ttCountdownBeep',
        'ui_ttCountdownGo',
      ]);
      expect(manager.state.history.length, 6);
    });

    test('integrates ProceduralCyclingAudioEngine (#117) and RaceRadioAudioController (#118)', () {
      final manager = SoundEffectsManagerProvider(
        initialSettings: const GameSettings(
          soundVolume: 0.5,
          raceEnvironmentVolume: 0.6,
          crowdAtmosphereVolume: 0.4,
          raceRadioVolume: 0.8,
          uiSoundsVolume: 0.7,
          commentaryAudio: true,
        ),
      );

      expect(manager.cyclingEngine.masterVolume, closeTo(0.5, 1e-6));
      expect(manager.cyclingEngine.aeroWhooshVolume, closeTo(0.85 * 0.6, 1e-6));
      expect(manager.cyclingEngine.crowdVolume, closeTo(0.95 * 0.4, 1e-6));
      expect(manager.raceRadioController.radioVolume, closeTo(0.4, 1e-6));

      final ambient = manager.generateEnvironmentAudioFrame(
        duration: const Duration(milliseconds: 50),
        telemetry: CyclingAudioTelemetry.demoSprint(),
      );
      expect(ambient.frameCount, greaterThan(0));

      const radioMsg = RaceRadioMessage(
        id: 'msg-1',
        kilometerMark: 12.0,
        elapsedSeconds: 1120.0,
        channel: RadioChannel.directeurSportif,
        priority: RadioPriority.urgent,
        senderName: 'Dyrektor Sportowy',
        message: 'Atak w peletonie! Przesuwaj lidera do przodu!',
      );
      final radioBuf = manager.playRadioMessage(radioMsg);
      expect(radioBuf, isNotNull);

      final alerts = manager.processRaceTelemetry(
        telemetry: CyclingAudioTelemetry.demoCobblestones(),
        currentKm: 1.0,
        wPrimePercent: 10.0,
        segments: const [
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 5.0,
            startElevationM: 200.0,
            endElevationM: 575.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 90.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.cat2,
          ),
        ],
      );
      expect(alerts, isNotEmpty);

      manager.setMuted(true);
      expect(manager.cyclingEngine.isMuted, isTrue);
      expect(manager.playTabClick(), isNull);
    });
  });

  group('GameSettings & Immediate Persistence', () {
    test('persists all 5 audio sliders immediately and roundtrips JSON', () async {
      final storage = _InMemoryGameSettingsStorage();
      final notifier = GameSettingsNotifier.withStorage(storage: storage);

      notifier.setMasterVolume(0.65);
      notifier.setRaceEnvironmentVolume(0.55);
      notifier.setCrowdAtmosphereVolume(0.45);
      notifier.setRaceRadioVolume(0.95);
      notifier.setUiSoundsVolume(0.35);

      await notifier.pendingSave;

      expect(storage.saveCount, 5);
      expect(storage.saved, isNotNull);
      expect(storage.saved!.soundVolume, closeTo(0.65, 1e-6));
      expect(storage.saved!.raceEnvironmentVolume, closeTo(0.55, 1e-6));
      expect(storage.saved!.crowdAtmosphereVolume, closeTo(0.45, 1e-6));
      expect(storage.saved!.raceRadioVolume, closeTo(0.95, 1e-6));
      expect(storage.saved!.uiSoundsVolume, closeTo(0.35, 1e-6));

      final restored = GameSettings.fromJsonString(storage.saved!.toJsonString());
      expect(restored.masterVolume, closeTo(0.65, 1e-6));
      expect(restored.raceEnvironmentVolume, closeTo(0.55, 1e-6));
      expect(restored.crowdAtmosphereVolume, closeTo(0.45, 1e-6));
      expect(restored.raceRadioVolume, closeTo(0.95, 1e-6));
      expect(restored.uiSoundsVolume, closeTo(0.35, 1e-6));
    });

    test('soundEffectsManagerProvider automatically syncs with gameSettingsProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(gameSettingsProvider.notifier).setUiSoundsVolume(0.25);
      container.read(gameSettingsProvider.notifier).setMasterVolume(0.8);

      final soundState = container.read(soundEffectsManagerProvider);
      expect(soundState.uiSoundsVolume, closeTo(0.25, 1e-6));
      expect(soundState.masterVolume, closeTo(0.8, 1e-6));
      expect(soundState.effectiveUiVolume, closeTo(0.2, 1e-6));
    });
  });

  group('SettingsAndModScreen Audio Mixer Responsive UI', () {
    for (final size in [
      const Size(390, 844),
      const Size(1024, 768),
      const Size(1600, 900),
    ]) {
      testWidgets('renders all 5 audio sliders without overflow at ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SettingsAndModScreen(initialTabIndex: 0),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Głośność Ogólna (Master)'), findsOneWidget);
        expect(find.text('Otoczenie Wyścigu (Koła, Bębenek, Wiatr)'), findsOneWidget);
        expect(find.text('Kibice i Atmosfera'), findsOneWidget);
        expect(find.text('Radio Wyścigowe i Alarmy Garmin'), findsOneWidget);
        expect(find.text('Dźwięki Interfejsu'), findsOneWidget);
      });
    }
  });
}
