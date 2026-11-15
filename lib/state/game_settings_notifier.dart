import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../core/localization/app_localizations_pl_en.dart';
import '../models/settings/game_settings.dart';

/// Interfejs trwałego zapisu preferencji użytkownika (natychmiastowy zapis przy zmianie).
abstract class GameSettingsStorage {
  Future<GameSettings?> load();
  Future<void> save(GameSettings settings);
}

/// Domyślna implementacja zapisująca ustawienia do pliku JSON w katalogu aplikacji.
class FileGameSettingsStorage implements GameSettingsStorage {
  static const String _fileName = 'game_settings.json';

  Future<File?> _resolveFile() async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}${Platform.pathSeparator}$_fileName');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<GameSettings?> load() async {
    try {
      final file = await _resolveFile();
      if (file == null || !await file.exists()) return null;
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return null;
      return GameSettings.fromJsonString(contents);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(GameSettings settings) async {
    try {
      final file = await _resolveFile();
      if (file == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsString(settings.toJsonString(), flush: true);
    } catch (_) {
      // Bezpieczne pominięcie w środowiskach bez dostępu do systemu plików (np. testy jednostkowe).
    }
  }
}

/// Provider zarządzający globalnymi ustawieniami grafiki, dźwięku i symulacji.
final gameSettingsProvider =
    StateNotifierProvider<GameSettingsNotifier, GameSettings>((ref) {
  return GameSettingsNotifier.withStorage(storage: FileGameSettingsStorage())
    ..loadSavedSettings();
});

/// Provider aktywnego języka gry (PL / EN) aktualizowany natychmiastowo.
final appLanguageProvider = Provider<AppLanguage>((ref) {
  return ref.watch(gameSettingsProvider.select((settings) => settings.language));
});

/// Provider aktywnego słownika lokalizacyjnego [AppLocalizationsPlEn].
final appLocalizationsProvider = Provider<AppLocalizationsPlEn>((ref) {
  final language = ref.watch(appLanguageProvider);
  return AppLocalizationsPlEn.ofLanguage(language);
});

class GameSettingsNotifier extends StateNotifier<GameSettings> {
  final GameSettingsStorage? _storage;
  Future<void> _pendingSave = Future.value();

  GameSettingsNotifier([
    GameSettings? initialSettings,
    GameSettingsStorage? storage,
  ])  : _storage = storage,
        super(initialSettings ?? const GameSettings());

  /// Alternatywny konstruktor z nazwanym parametrem storage.
  GameSettingsNotifier.withStorage({
    GameSettings? initialSettings,
    GameSettingsStorage? storage,
  })  : _storage = storage,
        super(initialSettings ?? const GameSettings());

  /// Ostatnia operacja zapisu (przydatne w testach do oczekiwania na zapis dyskowy).
  Future<void> get pendingSave => _pendingSave;

  /// Wczytuje zapisane preferencje z dysku, jeśli istnieją.
  Future<void> loadSavedSettings() async {
    final storage = _storage;
    if (storage == null) return;
    final loaded = await storage.load();
    if (loaded != null && mounted) {
      state = loaded;
    }
  }

  void _updateState(GameSettings next) {
    state = next;
    final storage = _storage;
    if (storage != null) {
      _pendingSave = _pendingSave.then((_) => storage.save(next));
    }
  }

  /// Zmienia jakość cieni.
  void setShadowQuality(ShadowQuality quality) {
    _updateState(state.copyWith(shadowQuality: quality));
  }

  /// Zmienia gęstość kibiców przy trasie.
  void setCrowdDensity(CrowdDensity density) {
    _updateState(state.copyWith(crowdDensity: density));
  }

  /// Zmienia docelowy limit klatek na sekundę (FPS).
  void setTargetFrameRate(TargetFrameRate fps) {
    _updateState(state.copyWith(targetFrameRate: fps));
  }

  /// Włącza lub wyłącza tryb oszczędzania energii.
  void setBatterySaverMode(bool enabled) {
    if (enabled) {
      _updateState(
        state.copyWith(
          batterySaverMode: true,
          targetFrameRate: TargetFrameRate.fps30,
          shadowQuality: ShadowQuality.disabled,
          crowdDensity: CrowdDensity.low,
          particleEffects: false,
          motionBlur: false,
        ),
      );
    } else {
      _updateState(
        state.copyWith(
          batterySaverMode: false,
          targetFrameRate: TargetFrameRate.fps60,
          shadowQuality: ShadowQuality.medium,
          crowdDensity: CrowdDensity.medium,
          particleEffects: true,
        ),
      );
    }
  }

  /// Przełącza rozmycie w ruchu (motion blur).
  void setMotionBlur(bool enabled) {
    _updateState(state.copyWith(motionBlur: enabled));
  }

  /// Przełącza efekty cząsteczkowe (deszcz, kurz, spray z kół).
  void setParticleEffects(bool enabled) {
    _updateState(state.copyWith(particleEffects: enabled));
  }

  /// Przełącza wysoki poziom detali rowerów (LOD).
  void setBikeDetailLOD(bool enabled) {
    _updateState(state.copyWith(bikeDetailLOD: enabled));
  }

  /// Zmienia głośność ogólną (Master) z natychmiastowym zapisem.
  void setMasterVolume(double volume) {
    _updateState(state.copyWith(soundVolume: volume.clamp(0.0, 1.0)));
  }

  /// Alias kompatybilnościowy dla głośności ogólnej (Master).
  void setSoundVolume(double volume) => setMasterVolume(volume);

  /// Zmienia głośność otoczenia wyścigu (Koła, Bębenek, Wiatr) z natychmiastowym zapisem.
  void setRaceEnvironmentVolume(double volume) {
    _updateState(state.copyWith(raceEnvironmentVolume: volume.clamp(0.0, 1.0)));
  }

  /// Zmienia głośność kibiców i atmosfery wyścigu z natychmiastowym zapisem.
  void setCrowdAtmosphereVolume(double volume) {
    _updateState(state.copyWith(crowdAtmosphereVolume: volume.clamp(0.0, 1.0)));
  }

  /// Zmienia głośność radia wyścigowego i alarmów Garmin z natychmiastowym zapisem.
  void setRaceRadioVolume(double volume) {
    _updateState(state.copyWith(raceRadioVolume: volume.clamp(0.0, 1.0)));
  }

  /// Zmienia głośność dźwięków interfejsu (UI Haptics & Audio) z natychmiastowym zapisem.
  void setUiSoundsVolume(double volume) {
    _updateState(state.copyWith(uiSoundsVolume: volume.clamp(0.0, 1.0)));
  }

  /// Przełącza komentarz radiowy / audio.
  void setCommentaryAudio(bool enabled) {
    _updateState(state.copyWith(commentaryAudio: enabled));
  }

  /// Przełącza widoczność licznika FPS.
  void setShowFpsCounter(bool enabled) {
    _updateState(state.copyWith(showFpsCounter: enabled));
  }

  /// Oznacza samouczek wyścigowy (Interactive Race Academy) jako ukończony.
  void completeRaceTutorial() {
    _updateState(state.copyWith(hasCompletedRaceTutorial: true));
  }

  /// Pomija samouczek wyścigowy w dowolnej chwili.
  void skipRaceTutorial() {
    _updateState(state.copyWith(hasCompletedRaceTutorial: true));
  }

  /// Resetuje stan samouczka, aby uruchomić go ponownie podczas kolejnego wyścigu.
  void restartRaceTutorial() {
    _updateState(
      state.copyWith(
        hasCompletedRaceTutorial: false,
        showTutorialHints: true,
      ),
    );
  }

  /// Włącza lub wyłącza podpowiedzi taktyczne dla nowych graczy.
  void setShowTutorialHints(bool enabled) {
    _updateState(state.copyWith(showTutorialHints: enabled));
  }

  /// Zmienia język gry (PL / EN) z natychmiastowym zapisem i odświeżeniem UI.
  void setLanguage(AppLanguage language) {
    if (state.language == language) return;
    _updateState(state.copyWith(language: language));
  }

  /// Przełącza język gry pomiędzy PL a EN.
  void toggleLanguage() {
    setLanguage(
      state.language == AppLanguage.pl ? AppLanguage.en : AppLanguage.pl,
    );
  }

  /// Aplikuje jeden z gotowych profili graficznych, zachowując indywidualne suwaki audio.
  void applyPreset(GraphicsPreset preset) {
    final GameSettings base;
    switch (preset) {
      case GraphicsPreset.batterySaver:
        base = GameSettings.batterySaver();
        break;
      case GraphicsPreset.balanced:
        base = GameSettings.balanced();
        break;
      case GraphicsPreset.highQuality:
        base = GameSettings.highQuality();
        break;
      case GraphicsPreset.ultraMacPc:
        base = GameSettings.ultraMacPc();
        break;
      case GraphicsPreset.custom:
        return;
    }

    _updateState(
      base.copyWith(
        soundVolume: state.soundVolume,
        raceEnvironmentVolume: state.raceEnvironmentVolume,
        crowdAtmosphereVolume: state.crowdAtmosphereVolume,
        raceRadioVolume: state.raceRadioVolume,
        uiSoundsVolume: state.uiSoundsVolume,
        commentaryAudio: state.commentaryAudio,
        language: state.language,
      ),
    );
  }

  /// Przywraca ustawienia fabryczne (domyślne zbalansowane).
  void resetToDefaults() {
    _updateState(const GameSettings());
  }
}
