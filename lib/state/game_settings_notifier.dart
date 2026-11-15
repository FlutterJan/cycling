import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings/game_settings.dart';

/// Provider zarządzający globalnymi ustawieniami grafiki, dźwięku i symulacji
final gameSettingsProvider =
    StateNotifierProvider<GameSettingsNotifier, GameSettings>((ref) {
  return GameSettingsNotifier();
});

class GameSettingsNotifier extends StateNotifier<GameSettings> {
  GameSettingsNotifier([GameSettings? initialSettings])
      : super(initialSettings ?? const GameSettings());

  /// Zmienia jakość cieni
  void setShadowQuality(ShadowQuality quality) {
    state = state.copyWith(shadowQuality: quality);
  }

  /// Zmienia gęstość kibiców przy trasie
  void setCrowdDensity(CrowdDensity density) {
    state = state.copyWith(crowdDensity: density);
  }

  /// Zmienia docelowy limit klatek na sekundę (FPS)
  void setTargetFrameRate(TargetFrameRate fps) {
    state = state.copyWith(targetFrameRate: fps);
  }

  /// Włącza lub wyłącza tryb oszczędzania energii
  void setBatterySaverMode(bool enabled) {
    if (enabled) {
      state = state.copyWith(
        batterySaverMode: true,
        targetFrameRate: TargetFrameRate.fps30,
        shadowQuality: ShadowQuality.disabled,
        crowdDensity: CrowdDensity.low,
        particleEffects: false,
        motionBlur: false,
      );
    } else {
      state = state.copyWith(
        batterySaverMode: false,
        targetFrameRate: TargetFrameRate.fps60,
        shadowQuality: ShadowQuality.medium,
        crowdDensity: CrowdDensity.medium,
        particleEffects: true,
      );
    }
  }

  /// Przełącza rozmycie w ruchu (motion blur)
  void setMotionBlur(bool enabled) {
    state = state.copyWith(motionBlur: enabled);
  }

  /// Przełącza efekty cząsteczkowe (deszcz, kurz, spray z kół)
  void setParticleEffects(bool enabled) {
    state = state.copyWith(particleEffects: enabled);
  }

  /// Przełącza wysoki poziom detali rowerów (LOD)
  void setBikeDetailLOD(bool enabled) {
    state = state.copyWith(bikeDetailLOD: enabled);
  }

  /// Zmienia głośność dźwięków
  void setSoundVolume(double volume) {
    state = state.copyWith(soundVolume: volume.clamp(0.0, 1.0));
  }

  /// Przełącza komentarz radiowy / audio
  void setCommentaryAudio(bool enabled) {
    state = state.copyWith(commentaryAudio: enabled);
  }

  /// Przełącza widoczność licznika FPS
  void setShowFpsCounter(bool enabled) {
    state = state.copyWith(showFpsCounter: enabled);
  }

  /// Aplikuje jeden z gotowych profili graficznych
  void applyPreset(GraphicsPreset preset) {
    switch (preset) {
      case GraphicsPreset.batterySaver:
        state = GameSettings.batterySaver();
        break;
      case GraphicsPreset.balanced:
        state = GameSettings.balanced();
        break;
      case GraphicsPreset.highQuality:
        state = GameSettings.highQuality();
        break;
      case GraphicsPreset.ultraMacPc:
        state = GameSettings.ultraMacPc();
        break;
      case GraphicsPreset.custom:
        break;
    }
  }

  /// Przywraca ustawienia fabryczne (domyślne zbalansowane)
  void resetToDefaults() {
    state = const GameSettings();
  }
}

