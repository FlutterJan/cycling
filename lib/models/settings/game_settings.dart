import 'dart:convert';

import '../../core/localization/app_localizations_pl_en.dart';

/// Poziom jakości renderowania cieni w widoku 3D wyścigu
enum ShadowQuality {
  disabled('Wyłączone', 'Brak cieni - maksymalna oszczędność baterii', 0),
  low('Niskie', 'Uproszczone cienie owalne pod kolarzami', 1),
  medium('Średnie', 'Dynamiczne cienie geometrii kolarza i roweru', 2),
  high('Wysokie (Ultra Soft)', 'Miękkie cienie Gaussa z uwzględnieniem słońca', 3);

  final String label;
  final String description;
  final int level;

  const ShadowQuality(this.label, this.description, this.level);

  String toJson() => name;

  static ShadowQuality fromJson(String value) {
    return ShadowQuality.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ShadowQuality.medium,
    );
  }
}

/// Gęstość tłumu kibiców przy trasie i barierkach
enum CrowdDensity {
  low('Niska (30%)', 'Pojedynczy widzowie - niska utrata klatek', 0.3),
  medium('Średnia (65%)', 'Zrównoważona atmosfera wyścigu', 0.65),
  high('Wysoka (100%)', 'Pełne szpalery kibiców na premiach i finiszu', 1.0),
  ultra('Ultra (Alpe d\'Huez)', 'Gęste tłumy, flagi, race dymne i transparenty', 1.5);

  final String label;
  final String description;
  final double multiplier;

  const CrowdDensity(this.label, this.description, this.multiplier);

  String toJson() => name;

  static CrowdDensity fromJson(String value) {
    return CrowdDensity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CrowdDensity.medium,
    );
  }
}

/// Docelowy limit klatek na sekundę (FPS)
enum TargetFrameRate {
  fps30(30, '30 FPS (Eco)', 'Minimalny drenaż baterii na smartfonie'),
  fps60(60, '60 FPS (Standard)', 'Płynna rozgrywka na większości urządzeń'),
  fps120(120, '120 FPS (ProMotion / PC)', 'Maksymalna responsywność dla ekranów 120Hz/144Hz'),
  unlimited(0, 'Bez Limitu (Maks. wydajność)', 'Brak ogranicznika klatek dla potężnych GPU');

  final int fps;
  final String label;
  final String description;

  const TargetFrameRate(this.fps, this.label, this.description);

  String toJson() => name;

  static TargetFrameRate fromJson(String value) {
    return TargetFrameRate.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TargetFrameRate.fps60,
    );
  }
}

/// Gotowe predefiniowane profile graficzne
enum GraphicsPreset {
  batterySaver('Oszczędzanie Baterii', '30 FPS, brak cieni, niska gęstość kibiców'),
  balanced('Zrównoważony (Telefon)', '60 FPS, średnie cienie, standardowi kibice'),
  highQuality('Wysoka Jakość (Tablet / Mac)', '60 FPS, wysokie cienie, pełny tłum, cząsteczki'),
  ultraMacPc('Ultra PC / Apple Silicon', '120 FPS, cienie ultra, tłum Alpe d\'Huez, pełne efekty'),
  custom('Własny', 'Ręcznie dostosowane parametry graficzne');

  final String label;
  final String description;

  const GraphicsPreset(this.label, this.description);
}

/// Globalna konfiguracja ustawień graficznych, audio, wydajności oraz interfejsu gry.
class GameSettings {
  final ShadowQuality shadowQuality;
  final CrowdDensity crowdDensity;
  final TargetFrameRate targetFrameRate;
  final bool batterySaverMode;
  final bool motionBlur;
  final bool particleEffects;
  final bool bikeDetailLOD;
  final double soundVolume;
  final double raceEnvironmentVolume;
  final double crowdAtmosphereVolume;
  final double raceRadioVolume;
  final double uiSoundsVolume;
  final bool commentaryAudio;
  final int autoSaveIntervalMinutes;
  final bool showFpsCounter;
  final double uiScale;
  final bool hasCompletedRaceTutorial;
  final bool showTutorialHints;
  final AppLanguage language;

  const GameSettings({
    this.shadowQuality = ShadowQuality.medium,
    this.crowdDensity = CrowdDensity.medium,
    this.targetFrameRate = TargetFrameRate.fps60,
    this.batterySaverMode = false,
    this.motionBlur = false,
    this.particleEffects = true,
    this.bikeDetailLOD = true,
    this.soundVolume = 0.85,
    this.raceEnvironmentVolume = 0.85,
    this.crowdAtmosphereVolume = 0.80,
    this.raceRadioVolume = 0.90,
    this.uiSoundsVolume = 0.75,
    this.commentaryAudio = true,
    this.autoSaveIntervalMinutes = 15,
    this.showFpsCounter = false,
    this.uiScale = 1.0,
    this.hasCompletedRaceTutorial = false,
    this.showTutorialHints = true,
    this.language = AppLanguage.pl,
  });

  /// Alias dla głośności ogólnej (Master)
  double get masterVolume => soundVolume;

  /// Szacowany wskaźnik obciążenia baterii / GPU (1.0 = b. niskie, 5.0 = maksymalne)
  double get estimatedLoadScore {
    double score = 1.0;
    if (targetFrameRate == TargetFrameRate.fps120) {
      score += 1.8;
    } else if (targetFrameRate == TargetFrameRate.unlimited) {
      score += 2.4;
    } else if (targetFrameRate == TargetFrameRate.fps60) {
      score += 0.9;
    }

    score += shadowQuality.level * 0.5;
    score += crowdDensity.multiplier * 0.6;
    if (particleEffects) score += 0.3;
    if (motionBlur) score += 0.4;
    if (batterySaverMode) score *= 0.6;

    return score.clamp(1.0, 5.0);
  }

  /// Etykieta szacowanego zużycia energii
  String get batteryDrainLabel {
    final load = estimatedLoadScore;
    if (load <= 1.8) return 'Bardzo niskie (Bateria Eco)';
    if (load <= 2.8) return 'Umiarkowane (Zbalansowane)';
    if (load <= 3.8) return 'Wysokie (Zalecane zasilanie)';
    return 'Ekstremalne (Gorący telefon / Tylko PC)';
  }

  /// Rozpoznanie aktywnego presetu
  GraphicsPreset get currentPreset {
    if (batterySaverMode &&
        targetFrameRate == TargetFrameRate.fps30 &&
        shadowQuality == ShadowQuality.disabled &&
        crowdDensity == CrowdDensity.low) {
      return GraphicsPreset.batterySaver;
    }
    if (!batterySaverMode &&
        targetFrameRate == TargetFrameRate.fps60 &&
        shadowQuality == ShadowQuality.medium &&
        crowdDensity == CrowdDensity.medium &&
        !motionBlur) {
      return GraphicsPreset.balanced;
    }
    if (!batterySaverMode &&
        targetFrameRate == TargetFrameRate.fps60 &&
        shadowQuality == ShadowQuality.high &&
        crowdDensity == CrowdDensity.high) {
      return GraphicsPreset.highQuality;
    }
    if (!batterySaverMode &&
        (targetFrameRate == TargetFrameRate.fps120 || targetFrameRate == TargetFrameRate.unlimited) &&
        shadowQuality == ShadowQuality.high &&
        crowdDensity == CrowdDensity.ultra) {
      return GraphicsPreset.ultraMacPc;
    }
    return GraphicsPreset.custom;
  }

  /// Fabryka presetu Oszczędzanie Baterii
  factory GameSettings.batterySaver() {
    return const GameSettings(
      shadowQuality: ShadowQuality.disabled,
      crowdDensity: CrowdDensity.low,
      targetFrameRate: TargetFrameRate.fps30,
      batterySaverMode: true,
      motionBlur: false,
      particleEffects: false,
      bikeDetailLOD: false,
      soundVolume: 0.7,
      commentaryAudio: true,
      showFpsCounter: false,
    );
  }

  /// Fabryka presetu Zbalansowanego (domyślnego na telefon)
  factory GameSettings.balanced() {
    return const GameSettings(
      shadowQuality: ShadowQuality.medium,
      crowdDensity: CrowdDensity.medium,
      targetFrameRate: TargetFrameRate.fps60,
      batterySaverMode: false,
      motionBlur: false,
      particleEffects: true,
      bikeDetailLOD: true,
      soundVolume: 0.8,
      commentaryAudio: true,
      showFpsCounter: false,
    );
  }

  /// Fabryka presetu Wysokiej Jakości (Tablet / Mac / PC)
  factory GameSettings.highQuality() {
    return const GameSettings(
      shadowQuality: ShadowQuality.high,
      crowdDensity: CrowdDensity.high,
      targetFrameRate: TargetFrameRate.fps60,
      batterySaverMode: false,
      motionBlur: false,
      particleEffects: true,
      bikeDetailLOD: true,
      soundVolume: 0.9,
      commentaryAudio: true,
      showFpsCounter: false,
    );
  }

  /// Fabryka presetu Ultra (Mac z Apple Silicon / PC Gaming)
  factory GameSettings.ultraMacPc() {
    return const GameSettings(
      shadowQuality: ShadowQuality.high,
      crowdDensity: CrowdDensity.ultra,
      targetFrameRate: TargetFrameRate.fps120,
      batterySaverMode: false,
      motionBlur: true,
      particleEffects: true,
      bikeDetailLOD: true,
      soundVolume: 1.0,
      commentaryAudio: true,
      showFpsCounter: true,
    );
  }

  GameSettings copyWith({
    ShadowQuality? shadowQuality,
    CrowdDensity? crowdDensity,
    TargetFrameRate? targetFrameRate,
    bool? batterySaverMode,
    bool? motionBlur,
    bool? particleEffects,
    bool? bikeDetailLOD,
    double? soundVolume,
    double? raceEnvironmentVolume,
    double? crowdAtmosphereVolume,
    double? raceRadioVolume,
    double? uiSoundsVolume,
    bool? commentaryAudio,
    int? autoSaveIntervalMinutes,
    bool? showFpsCounter,
    double? uiScale,
    bool? hasCompletedRaceTutorial,
    bool? showTutorialHints,
    AppLanguage? language,
  }) {
    return GameSettings(
      shadowQuality: shadowQuality ?? this.shadowQuality,
      crowdDensity: crowdDensity ?? this.crowdDensity,
      targetFrameRate: targetFrameRate ?? this.targetFrameRate,
      batterySaverMode: batterySaverMode ?? this.batterySaverMode,
      motionBlur: motionBlur ?? this.motionBlur,
      particleEffects: particleEffects ?? this.particleEffects,
      bikeDetailLOD: bikeDetailLOD ?? this.bikeDetailLOD,
      soundVolume: soundVolume ?? this.soundVolume,
      raceEnvironmentVolume: raceEnvironmentVolume ?? this.raceEnvironmentVolume,
      crowdAtmosphereVolume: crowdAtmosphereVolume ?? this.crowdAtmosphereVolume,
      raceRadioVolume: raceRadioVolume ?? this.raceRadioVolume,
      uiSoundsVolume: uiSoundsVolume ?? this.uiSoundsVolume,
      commentaryAudio: commentaryAudio ?? this.commentaryAudio,
      autoSaveIntervalMinutes: autoSaveIntervalMinutes ?? this.autoSaveIntervalMinutes,
      showFpsCounter: showFpsCounter ?? this.showFpsCounter,
      uiScale: uiScale ?? this.uiScale,
      hasCompletedRaceTutorial: hasCompletedRaceTutorial ?? this.hasCompletedRaceTutorial,
      showTutorialHints: showTutorialHints ?? this.showTutorialHints,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shadowQuality': shadowQuality.toJson(),
      'crowdDensity': crowdDensity.toJson(),
      'targetFrameRate': targetFrameRate.toJson(),
      'batterySaverMode': batterySaverMode,
      'motionBlur': motionBlur,
      'particleEffects': particleEffects,
      'bikeDetailLOD': bikeDetailLOD,
      'soundVolume': soundVolume,
      'raceEnvironmentVolume': raceEnvironmentVolume,
      'crowdAtmosphereVolume': crowdAtmosphereVolume,
      'raceRadioVolume': raceRadioVolume,
      'uiSoundsVolume': uiSoundsVolume,
      'commentaryAudio': commentaryAudio,
      'autoSaveIntervalMinutes': autoSaveIntervalMinutes,
      'showFpsCounter': showFpsCounter,
      'uiScale': uiScale,
      'hasCompletedRaceTutorial': hasCompletedRaceTutorial,
      'showTutorialHints': showTutorialHints,
      'language': language.toJson(),
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      shadowQuality: json['shadowQuality'] != null
          ? ShadowQuality.fromJson(json['shadowQuality'] as String)
          : ShadowQuality.medium,
      crowdDensity: json['crowdDensity'] != null
          ? CrowdDensity.fromJson(json['crowdDensity'] as String)
          : CrowdDensity.medium,
      targetFrameRate: json['targetFrameRate'] != null
          ? TargetFrameRate.fromJson(json['targetFrameRate'] as String)
          : TargetFrameRate.fps60,
      batterySaverMode: json['batterySaverMode'] as bool? ?? false,
      motionBlur: json['motionBlur'] as bool? ?? false,
      particleEffects: json['particleEffects'] as bool? ?? true,
      bikeDetailLOD: json['bikeDetailLOD'] as bool? ?? true,
      soundVolume: ((json['soundVolume'] as num?)?.toDouble() ?? 0.85).clamp(0.0, 1.0),
      raceEnvironmentVolume:
          ((json['raceEnvironmentVolume'] as num?)?.toDouble() ?? 0.85).clamp(0.0, 1.0),
      crowdAtmosphereVolume:
          ((json['crowdAtmosphereVolume'] as num?)?.toDouble() ?? 0.80).clamp(0.0, 1.0),
      raceRadioVolume:
          ((json['raceRadioVolume'] as num?)?.toDouble() ?? 0.90).clamp(0.0, 1.0),
      uiSoundsVolume:
          ((json['uiSoundsVolume'] as num?)?.toDouble() ?? 0.75).clamp(0.0, 1.0),
      commentaryAudio: json['commentaryAudio'] as bool? ?? true,
      autoSaveIntervalMinutes: (json['autoSaveIntervalMinutes'] as num?)?.toInt() ?? 15,
      showFpsCounter: json['showFpsCounter'] as bool? ?? false,
      uiScale: (json['uiScale'] as num?)?.toDouble() ?? 1.0,
      hasCompletedRaceTutorial: json['hasCompletedRaceTutorial'] as bool? ?? false,
      showTutorialHints: json['showTutorialHints'] as bool? ?? true,
      language: json['language'] != null
          ? AppLanguage.fromJson(json['language'] as String)
          : AppLanguage.pl,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameSettings.fromJsonString(String jsonString) {
    return GameSettings.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
