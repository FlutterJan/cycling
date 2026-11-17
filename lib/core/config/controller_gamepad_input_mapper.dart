import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';

/// Sprzętowy profil kontrolera rozpoznawany przez silnik wejścia.
enum GamepadHardwareProfile {
  xboxSeries(
    id: 'xbox_series',
    displayName: 'Xbox Series X|S / One',
    shortName: 'Xbox',
    vendorId: 0x045E,
    hasAdaptiveTriggers: false,
    hasBackPaddles: false,
    hasTrackpads: false,
    supportsGyro: false,
    accentColor: AppColors.statusSuccess,
  ),
  playStationDualSense(
    id: 'playstation_dualsense',
    displayName: 'PlayStation DualSense (PS5)',
    shortName: 'DualSense',
    vendorId: 0x054C,
    hasAdaptiveTriggers: true,
    hasBackPaddles: false,
    hasTrackpads: true,
    supportsGyro: true,
    accentColor: AppColors.accentBlue,
  ),
  steamDeck(
    id: 'steam_deck',
    displayName: 'Valve Steam Deck',
    shortName: 'Steam Deck',
    vendorId: 0x28DE,
    hasAdaptiveTriggers: false,
    hasBackPaddles: true,
    hasTrackpads: true,
    supportsGyro: true,
    accentColor: AppColors.goldAccent,
  ),
  genericXInput(
    id: 'generic_xinput',
    displayName: 'Kontroler Standardowy XInput',
    shortName: 'Standard',
    vendorId: 0x0000,
    hasAdaptiveTriggers: false,
    hasBackPaddles: false,
    hasTrackpads: false,
    supportsGyro: false,
    accentColor: AppColors.textSecondary,
  );

  final String id;
  final String displayName;
  final String shortName;
  final int vendorId;
  final bool hasAdaptiveTriggers;
  final bool hasBackPaddles;
  final bool hasTrackpads;
  final bool supportsGyro;
  final Color accentColor;

  const GamepadHardwareProfile({
    required this.id,
    required this.displayName,
    required this.shortName,
    required this.vendorId,
    required this.hasAdaptiveTriggers,
    required this.hasBackPaddles,
    required this.hasTrackpads,
    required this.supportsGyro,
    required this.accentColor,
  });

  /// Automatycznie wykrywa profil sprzętowy na podstawie nazwy urządzenia lub Vendor ID.
  static GamepadHardwareProfile detectFromDeviceName(
    String deviceName, {
    int? vendorId,
  }) {
    if (vendorId != null) {
      if (vendorId == 0x054C) {
        return GamepadHardwareProfile.playStationDualSense;
      }
      if (vendorId == 0x28DE) {
        return GamepadHardwareProfile.steamDeck;
      }
      if (vendorId == 0x045E) {
        return GamepadHardwareProfile.xboxSeries;
      }
    }

    final normalized = deviceName.toLowerCase();
    if (normalized.contains('dualsense') ||
        normalized.contains('dualshock') ||
        normalized.contains('playstation') ||
        normalized.contains('ps5') ||
        normalized.contains('ps4') ||
        normalized.contains('sony')) {
      return GamepadHardwareProfile.playStationDualSense;
    }
    if (normalized.contains('steam deck') ||
        normalized.contains('steamdeck') ||
        normalized.contains('neptune') ||
        normalized.contains('valve')) {
      return GamepadHardwareProfile.steamDeck;
    }
    if (normalized.contains('xbox') ||
        normalized.contains('xinput') ||
        normalized.contains('microsoft')) {
      return GamepadHardwareProfile.xboxSeries;
    }
    return GamepadHardwareProfile.genericXInput;
  }

  static GamepadHardwareProfile fromId(String id) {
    return GamepadHardwareProfile.values.firstWhere(
      (profile) => profile.id == id,
      orElse: () => GamepadHardwareProfile.genericXInput,
    );
  }
}

/// Reprezentacja wizualnego glifu przycisku dla konkretnego kontrolera.
@immutable
class GamepadButtonGlyph {
  final String symbol;
  final String fullLabel;
  final Color badgeColor;

  const GamepadButtonGlyph({
    required this.symbol,
    required this.fullLabel,
    required this.badgeColor,
  });
}

/// Ujednolicona lista fizycznych przycisków kontrolera.
enum GamepadLogicalButton {
  south('Dolny przycisk główny'),
  east('Prawy przycisk główny'),
  west('Lewy przycisk główny'),
  north('Górny przycisk główny'),
  leftBumper('Lewy bumper'),
  rightBumper('Prawy bumper'),
  leftTriggerClick('Lewy spust (pełne wciśnięcie)'),
  rightTriggerClick('Prawy spust (pełne wciśnięcie)'),
  dpadUp('Krzyżak Góra'),
  dpadDown('Krzyżak Dół'),
  dpadLeft('Krzyżak Lewo'),
  dpadRight('Krzyżak Prawo'),
  leftStickPress('Wciśnięcie lewego drążka'),
  rightStickPress('Wciśnięcie prawego drążka'),
  viewSelect('Przycisk Widok / Select'),
  menuStart('Przycisk Menu / Start'),
  paddleL4('Tylna łopatka L4'),
  paddleR4('Tylna łopatka R4'),
  paddleL5('Tylna łopatka L5'),
  paddleR5('Tylna łopatka R5'),
  touchpadClick('Kliknięcie panelu dotykowego');

  final String description;
  const GamepadLogicalButton(this.description);

  /// Zwraca autentyczny glif i kolor przycisku dla wybranego kontrolera.
  GamepadButtonGlyph glyphFor(GamepadHardwareProfile profile) {
    switch (profile) {
      case GamepadHardwareProfile.playStationDualSense:
        return _dualSenseGlyph();
      case GamepadHardwareProfile.steamDeck:
        return _steamDeckGlyph();
      case GamepadHardwareProfile.xboxSeries:
      case GamepadHardwareProfile.genericXInput:
        return _xboxGlyph();
    }
  }

  GamepadButtonGlyph _xboxGlyph() {
    switch (this) {
      case GamepadLogicalButton.south:
        return const GamepadButtonGlyph(
          symbol: 'A',
          fullLabel: 'Przycisk A',
          badgeColor: Color(0xFF10B981),
        );
      case GamepadLogicalButton.east:
        return const GamepadButtonGlyph(
          symbol: 'B',
          fullLabel: 'Przycisk B',
          badgeColor: Color(0xFFEF4444),
        );
      case GamepadLogicalButton.west:
        return const GamepadButtonGlyph(
          symbol: 'X',
          fullLabel: 'Przycisk X',
          badgeColor: Color(0xFF38BDF8),
        );
      case GamepadLogicalButton.north:
        return const GamepadButtonGlyph(
          symbol: 'Y',
          fullLabel: 'Przycisk Y',
          badgeColor: Color(0xFFF59E0B),
        );
      case GamepadLogicalButton.leftBumper:
        return const GamepadButtonGlyph(
          symbol: 'LB',
          fullLabel: 'Lewy Bumper LB',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.rightBumper:
        return const GamepadButtonGlyph(
          symbol: 'RB',
          fullLabel: 'Prawy Bumper RB',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.leftTriggerClick:
        return const GamepadButtonGlyph(
          symbol: 'LT',
          fullLabel: 'Lewy Spust LT',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.rightTriggerClick:
        return const GamepadButtonGlyph(
          symbol: 'RT',
          fullLabel: 'Prawy Spust RT',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.leftStickPress:
        return const GamepadButtonGlyph(
          symbol: 'LS',
          fullLabel: 'Lewy Drążek LS',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.rightStickPress:
        return const GamepadButtonGlyph(
          symbol: 'RS',
          fullLabel: 'Prawy Drążek RS',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.viewSelect:
        return const GamepadButtonGlyph(
          symbol: 'VIEW',
          fullLabel: 'View',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.menuStart:
        return const GamepadButtonGlyph(
          symbol: 'MENU',
          fullLabel: 'Menu',
          badgeColor: AppColors.surfaceLight,
        );
      default:
        return _sharedDirectionalGlyph();
    }
  }

  GamepadButtonGlyph _dualSenseGlyph() {
    switch (this) {
      case GamepadLogicalButton.south:
        return const GamepadButtonGlyph(
          symbol: '✕',
          fullLabel: 'Krzyżyk (Cross)',
          badgeColor: Color(0xFF38BDF8),
        );
      case GamepadLogicalButton.east:
        return const GamepadButtonGlyph(
          symbol: '◯',
          fullLabel: 'Kółko (Circle)',
          badgeColor: Color(0xFFEF4444),
        );
      case GamepadLogicalButton.west:
        return const GamepadButtonGlyph(
          symbol: '☐',
          fullLabel: 'Kwadrat (Square)',
          badgeColor: Color(0xFFF472B6),
        );
      case GamepadLogicalButton.north:
        return const GamepadButtonGlyph(
          symbol: '△',
          fullLabel: 'Trójkąt (Triangle)',
          badgeColor: Color(0xFF10B981),
        );
      case GamepadLogicalButton.leftBumper:
        return const GamepadButtonGlyph(
          symbol: 'L1',
          fullLabel: 'Przycisk L1',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.rightBumper:
        return const GamepadButtonGlyph(
          symbol: 'R1',
          fullLabel: 'Przycisk R1',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.leftTriggerClick:
        return const GamepadButtonGlyph(
          symbol: 'L2',
          fullLabel: 'Adaptacyjny Spust L2',
          badgeColor: AppColors.accentBlue,
        );
      case GamepadLogicalButton.rightTriggerClick:
        return const GamepadButtonGlyph(
          symbol: 'R2',
          fullLabel: 'Adaptacyjny Spust R2',
          badgeColor: AppColors.accentBlue,
        );
      case GamepadLogicalButton.leftStickPress:
        return const GamepadButtonGlyph(
          symbol: 'L3',
          fullLabel: 'Przycisk L3',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.rightStickPress:
        return const GamepadButtonGlyph(
          symbol: 'R3',
          fullLabel: 'Przycisk R3',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.viewSelect:
        return const GamepadButtonGlyph(
          symbol: 'CREATE',
          fullLabel: 'Create',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.menuStart:
        return const GamepadButtonGlyph(
          symbol: 'OPT',
          fullLabel: 'Options',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.touchpadClick:
        return const GamepadButtonGlyph(
          symbol: 'TOUCH',
          fullLabel: 'Panel Dotykowy DualSense',
          badgeColor: AppColors.accentBlue,
        );
      default:
        return _sharedDirectionalGlyph();
    }
  }

  GamepadButtonGlyph _steamDeckGlyph() {
    switch (this) {
      case GamepadLogicalButton.south:
        return const GamepadButtonGlyph(
          symbol: 'A',
          fullLabel: 'Przycisk A (Steam Deck)',
          badgeColor: AppColors.goldAccent,
        );
      case GamepadLogicalButton.east:
        return const GamepadButtonGlyph(
          symbol: 'B',
          fullLabel: 'Przycisk B (Steam Deck)',
          badgeColor: AppColors.goldAccent,
        );
      case GamepadLogicalButton.west:
        return const GamepadButtonGlyph(
          symbol: 'X',
          fullLabel: 'Przycisk X (Steam Deck)',
          badgeColor: AppColors.goldAccent,
        );
      case GamepadLogicalButton.north:
        return const GamepadButtonGlyph(
          symbol: 'Y',
          fullLabel: 'Przycisk Y (Steam Deck)',
          badgeColor: AppColors.goldAccent,
        );
      case GamepadLogicalButton.leftBumper:
        return const GamepadButtonGlyph(
          symbol: 'L1',
          fullLabel: 'Bumper L1',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.rightBumper:
        return const GamepadButtonGlyph(
          symbol: 'R1',
          fullLabel: 'Bumper R1',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.leftTriggerClick:
        return const GamepadButtonGlyph(
          symbol: 'L2',
          fullLabel: 'Spust L2',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.rightTriggerClick:
        return const GamepadButtonGlyph(
          symbol: 'R2',
          fullLabel: 'Spust R2',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.paddleL4:
        return const GamepadButtonGlyph(
          symbol: 'L4',
          fullLabel: 'Łopatka tylna L4',
          badgeColor: AppColors.goldAccent,
        );
      case GamepadLogicalButton.paddleR4:
        return const GamepadButtonGlyph(
          symbol: 'R4',
          fullLabel: 'Łopatka tylna R4',
          badgeColor: AppColors.goldAccent,
        );
      case GamepadLogicalButton.paddleL5:
        return const GamepadButtonGlyph(
          symbol: 'L5',
          fullLabel: 'Łopatka tylna L5',
          badgeColor: AppColors.goldAccent,
        );
      case GamepadLogicalButton.paddleR5:
        return const GamepadButtonGlyph(
          symbol: 'R5',
          fullLabel: 'Łopatka tylna R5',
          badgeColor: AppColors.goldAccent,
        );
      case GamepadLogicalButton.touchpadClick:
        return const GamepadButtonGlyph(
          symbol: 'PAD',
          fullLabel: 'Trackpad Steam Deck',
          badgeColor: AppColors.goldAccent,
        );
      default:
        return _sharedDirectionalGlyph();
    }
  }

  GamepadButtonGlyph _sharedDirectionalGlyph() {
    switch (this) {
      case GamepadLogicalButton.dpadUp:
        return const GamepadButtonGlyph(
          symbol: '▲',
          fullLabel: 'Krzyżak Góra',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.dpadDown:
        return const GamepadButtonGlyph(
          symbol: '▼',
          fullLabel: 'Krzyżak Dół',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.dpadLeft:
        return const GamepadButtonGlyph(
          symbol: '◀',
          fullLabel: 'Krzyżak Lewo',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.dpadRight:
        return const GamepadButtonGlyph(
          symbol: '▶',
          fullLabel: 'Krzyżak Prawo',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.paddleL4:
        return const GamepadButtonGlyph(
          symbol: 'L4',
          fullLabel: 'Łopatka L4',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.paddleR4:
        return const GamepadButtonGlyph(
          symbol: 'R4',
          fullLabel: 'Łopatka R4',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.paddleL5:
        return const GamepadButtonGlyph(
          symbol: 'L5',
          fullLabel: 'Łopatka L5',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.paddleR5:
        return const GamepadButtonGlyph(
          symbol: 'R5',
          fullLabel: 'Łopatka R5',
          badgeColor: AppColors.surfaceLight,
        );
      case GamepadLogicalButton.touchpadClick:
        return const GamepadButtonGlyph(
          symbol: 'TOUCH',
          fullLabel: 'Touchpad',
          badgeColor: AppColors.surfaceLight,
        );
      default:
        return GamepadButtonGlyph(
          symbol: name.toUpperCase(),
          fullLabel: description,
          badgeColor: AppColors.surfaceLight,
        );
    }
  }
}

/// Akcje logiczne w symulacji kolarskiej i interfejsie menedżera.
enum CyclingGamepadAction {
  snapToWheel('Schowaj się na koło (Draft)', 'Sterowanie'),
  sprintWattBomb('Atak / Sprint Watt Bomb', 'Sterowanie'),
  bikeThrowFinish('Rzut rowerem na kreskę', 'Sterowanie'),
  supertuckAero('Pozycja Supertuck (Zjazd)', 'Sterowanie'),
  gearShiftUp('Przerzutka w górę (+)', 'Napęd'),
  gearShiftDown('Przerzutka w dół (-)', 'Napęd'),
  tacticalOrderAttack('Rozkaz: Atak drużyny', 'Taktyka DS'),
  tacticalOrderProtect('Rozkaz: Ochrona lidera', 'Taktyka DS'),
  tacticalOrderFeedGel('Rozkaz: Bidon i żel', 'Taktyka DS'),
  tacticalOrderPaceControl('Rozkaz: Dyktuj tempo', 'Taktyka DS'),
  tacticalRadialWheel('Koło rozkazów taktycznych', 'Taktyka DS'),
  cameraCyclePreset('Zmiana kamery 3D', 'Kamera'),
  nextRiderFocus('Następny kolarz drużyny', 'Kamera'),
  prevRiderFocus('Poprzedni kolarz drużyny', 'Kamera'),
  pauseSimulation('Pauza / Menu wyścigu', 'System'),
  openRaceRadio('Radio wyścigowe DS', 'System');

  final String label;
  final String category;
  const CyclingGamepadAction(this.label, this.category);
}

/// Presety sterowania dopasowane do trybu gry i sprzętu.
enum GamepadControlPreset {
  proPelotonDirector(
    id: 'pro_peloton_director',
    label: 'Dyrektor Sportowy (Pro)',
    description:
        'Pełna kontrola taktyki drużyny, przełączanie kolarzy, koło rozkazów oraz swobodna kamera 3D.',
  ),
  directRiderArcade(
    id: 'direct_rider_arcade',
    label: 'Bezpośredni Kolarz 3D',
    description:
        'Sterowanie własnym zawodnikiem: lewy drążek tor jazdy, spusty moc/hamulec, bumpery przerzutki.',
  ),
  steamDeckHandheld(
    id: 'steam_deck_handheld',
    label: 'Steam Deck Pro (Łopatki L4/R4)',
    description:
        'Wykorzystuje tylne łopatki L4/R4 do zmiany przełożeń oraz L5/R5 do żywienia i ataku Watt Bomb.',
  );

  final String id;
  final String label;
  final String description;

  const GamepadControlPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  static GamepadControlPreset fromId(String id) {
    return GamepadControlPreset.values.firstWhere(
      (preset) => preset.id == id,
      orElse: () => GamepadControlPreset.proPelotonDirector,
    );
  }
}

/// Tryb oporu adaptacyjnych spustów PS5 DualSense.
enum DualSenseTriggerResistanceMode {
  off('Wyłączony', 0.0, 0.0),
  cobbleFeedback('Wibracje bruku 5★', 0.45, 0.72),
  steepClimbResistance('Opór podjazdu >12%', 0.78, 0.35),
  aeroSprintSnap('Próg ataku Watt Bomb', 0.62, 0.85),
  wetDescentBrake('Pulsowanie hamulca (deszcz)', 0.55, 0.90);

  final String label;
  final double resistanceForce;
  final double vibrationFrequencyNormalized;

  const DualSenseTriggerResistanceMode(
    this.label,
    this.resistanceForce,
    this.vibrationFrequencyNormalized,
  );
}

/// Parametry martwej strefy i krzywej czułości analogowej.
@immutable
class GamepadDeadzoneAndCurveConfig {
  final double leftStickDeadzone;
  final double rightStickDeadzone;
  final double triggerDeadzone;
  final double responseCurveExponent;
  final bool invertCameraY;
  final bool enableGyroDescentSteering;
  final bool enableAdaptiveTriggers;
  final double vibrationIntensity;

  const GamepadDeadzoneAndCurveConfig({
    this.leftStickDeadzone = 0.12,
    this.rightStickDeadzone = 0.14,
    this.triggerDeadzone = 0.05,
    this.responseCurveExponent = 1.45,
    this.invertCameraY = false,
    this.enableGyroDescentSteering = true,
    this.enableAdaptiveTriggers = true,
    this.vibrationIntensity = 0.85,
  });

  GamepadDeadzoneAndCurveConfig copyWith({
    double? leftStickDeadzone,
    double? rightStickDeadzone,
    double? triggerDeadzone,
    double? responseCurveExponent,
    bool? invertCameraY,
    bool? enableGyroDescentSteering,
    bool? enableAdaptiveTriggers,
    double? vibrationIntensity,
  }) {
    return GamepadDeadzoneAndCurveConfig(
      leftStickDeadzone:
          (leftStickDeadzone ?? this.leftStickDeadzone).clamp(0.02, 0.40),
      rightStickDeadzone:
          (rightStickDeadzone ?? this.rightStickDeadzone).clamp(0.02, 0.40),
      triggerDeadzone:
          (triggerDeadzone ?? this.triggerDeadzone).clamp(0.0, 0.25),
      responseCurveExponent:
          (responseCurveExponent ?? this.responseCurveExponent).clamp(1.0, 2.5),
      invertCameraY: invertCameraY ?? this.invertCameraY,
      enableGyroDescentSteering:
          enableGyroDescentSteering ?? this.enableGyroDescentSteering,
      enableAdaptiveTriggers:
          enableAdaptiveTriggers ?? this.enableAdaptiveTriggers,
      vibrationIntensity:
          (vibrationIntensity ?? this.vibrationIntensity).clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leftStickDeadzone': leftStickDeadzone,
      'rightStickDeadzone': rightStickDeadzone,
      'triggerDeadzone': triggerDeadzone,
      'responseCurveExponent': responseCurveExponent,
      'invertCameraY': invertCameraY,
      'enableGyroDescentSteering': enableGyroDescentSteering,
      'enableAdaptiveTriggers': enableAdaptiveTriggers,
      'vibrationIntensity': vibrationIntensity,
    };
  }

  factory GamepadDeadzoneAndCurveConfig.fromJson(Map<String, dynamic> json) {
    return GamepadDeadzoneAndCurveConfig(
      leftStickDeadzone:
          ((json['leftStickDeadzone'] as num?)?.toDouble() ?? 0.12)
              .clamp(0.02, 0.40),
      rightStickDeadzone:
          ((json['rightStickDeadzone'] as num?)?.toDouble() ?? 0.14)
              .clamp(0.02, 0.40),
      triggerDeadzone:
          ((json['triggerDeadzone'] as num?)?.toDouble() ?? 0.05)
              .clamp(0.0, 0.25),
      responseCurveExponent:
          ((json['responseCurveExponent'] as num?)?.toDouble() ?? 1.45)
              .clamp(1.0, 2.5),
      invertCameraY: json['invertCameraY'] as bool? ?? false,
      enableGyroDescentSteering:
          json['enableGyroDescentSteering'] as bool? ?? true,
      enableAdaptiveTriggers: json['enableAdaptiveTriggers'] as bool? ?? true,
      vibrationIntensity:
          ((json['vibrationIntensity'] as num?)?.toDouble() ?? 0.85)
              .clamp(0.0, 1.0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GamepadDeadzoneAndCurveConfig &&
        other.leftStickDeadzone == leftStickDeadzone &&
        other.rightStickDeadzone == rightStickDeadzone &&
        other.triggerDeadzone == triggerDeadzone &&
        other.responseCurveExponent == responseCurveExponent &&
        other.invertCameraY == invertCameraY &&
        other.enableGyroDescentSteering == enableGyroDescentSteering &&
        other.enableAdaptiveTriggers == enableAdaptiveTriggers &&
        other.vibrationIntensity == vibrationIntensity;
  }

  @override
  int get hashCode => Object.hash(
        leftStickDeadzone,
        rightStickDeadzone,
        triggerDeadzone,
        responseCurveExponent,
        invertCameraY,
        enableGyroDescentSteering,
        enableAdaptiveTriggers,
        vibrationIntensity,
      );
}

/// Informacja o podłączonym fizycznym kontrolerze.
@immutable
class ConnectedGamepadDevice {
  final String deviceId;
  final String name;
  final int vendorId;
  final GamepadHardwareProfile profile;
  final int batteryPercent;
  final bool isWireless;
  final DateTime connectedAt;

  const ConnectedGamepadDevice({
    required this.deviceId,
    required this.name,
    required this.vendorId,
    required this.profile,
    this.batteryPercent = 100,
    this.isWireless = true,
    required this.connectedAt,
  });
}

/// Surowa ramka odczytu sprzętowego kontrolera w pojedynczej klatce.
@immutable
class GamepadRawInputFrame {
  final double leftStickX;
  final double leftStickY;
  final double rightStickX;
  final double rightStickY;
  final double leftTrigger;
  final double rightTrigger;
  final double gyroRollRad;
  final Set<GamepadLogicalButton> pressedButtons;

  const GamepadRawInputFrame({
    this.leftStickX = 0.0,
    this.leftStickY = 0.0,
    this.rightStickX = 0.0,
    this.rightStickY = 0.0,
    this.leftTrigger = 0.0,
    this.rightTrigger = 0.0,
    this.gyroRollRad = 0.0,
    this.pressedButtons = const <GamepadLogicalButton>{},
  });
}

/// Przetworzone wyjście sterowania po nałożeniu martwych stref, krzywych i mapowań.
@immutable
class GamepadMappedFrameOutput {
  final double lateralSteerNormalized;
  final double longitudinalEffortNormalized;
  final double cameraOrbitX;
  final double cameraOrbitY;
  final double throttlePower;
  final double brakeIntensity;
  final Set<CyclingGamepadAction> activeActions;
  final Set<CyclingGamepadAction> justTriggeredActions;
  final Set<CyclingGamepadAction> justReleasedActions;
  final DualSenseTriggerResistanceMode leftTriggerMode;
  final DualSenseTriggerResistanceMode rightTriggerMode;

  const GamepadMappedFrameOutput({
    this.lateralSteerNormalized = 0.0,
    this.longitudinalEffortNormalized = 0.0,
    this.cameraOrbitX = 0.0,
    this.cameraOrbitY = 0.0,
    this.throttlePower = 0.0,
    this.brakeIntensity = 0.0,
    this.activeActions = const <CyclingGamepadAction>{},
    this.justTriggeredActions = const <CyclingGamepadAction>{},
    this.justReleasedActions = const <CyclingGamepadAction>{},
    this.leftTriggerMode = DualSenseTriggerResistanceMode.off,
    this.rightTriggerMode = DualSenseTriggerResistanceMode.off,
  });
}

/// Silnik mapowania i przetwarzania wejścia kontrolerów Xbox / DualSense / Steam Deck.
class ControllerGamepadInputMapper {
  const ControllerGamepadInputMapper();

  /// Zwraca domyślną tablicę mapowań przycisków dla wskazanego presetu.
  static Map<GamepadLogicalButton, CyclingGamepadAction> defaultBindingsFor(
    GamepadControlPreset preset,
  ) {
    switch (preset) {
      case GamepadControlPreset.proPelotonDirector:
        return {
          GamepadLogicalButton.south: CyclingGamepadAction.snapToWheel,
          GamepadLogicalButton.east: CyclingGamepadAction.tacticalRadialWheel,
          GamepadLogicalButton.west: CyclingGamepadAction.openRaceRadio,
          GamepadLogicalButton.north: CyclingGamepadAction.cameraCyclePreset,
          GamepadLogicalButton.leftBumper:
              CyclingGamepadAction.prevRiderFocus,
          GamepadLogicalButton.rightBumper:
              CyclingGamepadAction.nextRiderFocus,
          GamepadLogicalButton.dpadUp:
              CyclingGamepadAction.tacticalOrderAttack,
          GamepadLogicalButton.dpadDown:
              CyclingGamepadAction.tacticalOrderProtect,
          GamepadLogicalButton.dpadLeft:
              CyclingGamepadAction.tacticalOrderFeedGel,
          GamepadLogicalButton.dpadRight:
              CyclingGamepadAction.tacticalOrderPaceControl,
          GamepadLogicalButton.menuStart:
              CyclingGamepadAction.pauseSimulation,
          GamepadLogicalButton.rightTriggerClick:
              CyclingGamepadAction.sprintWattBomb,
        };
      case GamepadControlPreset.directRiderArcade:
        return {
          GamepadLogicalButton.south: CyclingGamepadAction.snapToWheel,
          GamepadLogicalButton.east: CyclingGamepadAction.supertuckAero,
          GamepadLogicalButton.west: CyclingGamepadAction.tacticalOrderFeedGel,
          GamepadLogicalButton.north: CyclingGamepadAction.bikeThrowFinish,
          GamepadLogicalButton.leftBumper: CyclingGamepadAction.gearShiftDown,
          GamepadLogicalButton.rightBumper: CyclingGamepadAction.gearShiftUp,
          GamepadLogicalButton.dpadUp:
              CyclingGamepadAction.tacticalOrderAttack,
          GamepadLogicalButton.dpadDown:
              CyclingGamepadAction.tacticalOrderProtect,
          GamepadLogicalButton.dpadLeft:
              CyclingGamepadAction.prevRiderFocus,
          GamepadLogicalButton.dpadRight:
              CyclingGamepadAction.nextRiderFocus,
          GamepadLogicalButton.viewSelect:
              CyclingGamepadAction.cameraCyclePreset,
          GamepadLogicalButton.menuStart:
              CyclingGamepadAction.pauseSimulation,
          GamepadLogicalButton.rightTriggerClick:
              CyclingGamepadAction.sprintWattBomb,
        };
      case GamepadControlPreset.steamDeckHandheld:
        return {
          GamepadLogicalButton.south: CyclingGamepadAction.snapToWheel,
          GamepadLogicalButton.east: CyclingGamepadAction.supertuckAero,
          GamepadLogicalButton.west: CyclingGamepadAction.openRaceRadio,
          GamepadLogicalButton.north: CyclingGamepadAction.bikeThrowFinish,
          GamepadLogicalButton.leftBumper:
              CyclingGamepadAction.prevRiderFocus,
          GamepadLogicalButton.rightBumper:
              CyclingGamepadAction.nextRiderFocus,
          GamepadLogicalButton.paddleL4: CyclingGamepadAction.gearShiftDown,
          GamepadLogicalButton.paddleR4: CyclingGamepadAction.gearShiftUp,
          GamepadLogicalButton.paddleL5:
              CyclingGamepadAction.tacticalOrderFeedGel,
          GamepadLogicalButton.paddleR5: CyclingGamepadAction.sprintWattBomb,
          GamepadLogicalButton.dpadUp:
              CyclingGamepadAction.tacticalOrderAttack,
          GamepadLogicalButton.dpadDown:
              CyclingGamepadAction.tacticalOrderProtect,
          GamepadLogicalButton.dpadLeft:
              CyclingGamepadAction.tacticalOrderPaceControl,
          GamepadLogicalButton.dpadRight:
              CyclingGamepadAction.cameraCyclePreset,
          GamepadLogicalButton.menuStart:
              CyclingGamepadAction.pauseSimulation,
        };
    }
  }

  /// Nakłada radialną martwą strefę oraz wykładniczą krzywą czułości na wektor 2D drążka.
  static Offset applyRadialDeadzoneAndCurve({
    required double rawX,
    required double rawY,
    required double deadzone,
    required double curveExponent,
  }) {
    final clampedX = rawX.clamp(-1.0, 1.0);
    final clampedY = rawY.clamp(-1.0, 1.0);
    final magnitude = math.sqrt(clampedX * clampedX + clampedY * clampedY);
    if (magnitude <= deadzone || magnitude == 0.0) {
      return Offset.zero;
    }

    final normalizedMag =
        ((magnitude - deadzone) / (1.0 - deadzone)).clamp(0.0, 1.0);
    final curvedMag = math.pow(normalizedMag, curveExponent).toDouble();
    final scale = curvedMag / magnitude;
    return Offset(
      (clampedX * scale).clamp(-1.0, 1.0),
      (clampedY * scale).clamp(-1.0, 1.0),
    );
  }

  /// Nakłada martwą strefę na pojedynczy spust analogowy `[0.0..1.0]`.
  static double applyTriggerDeadzone({
    required double rawValue,
    required double deadzone,
  }) {
    final clamped = rawValue.clamp(0.0, 1.0);
    if (clamped <= deadzone) return 0.0;
    return ((clamped - deadzone) / (1.0 - deadzone)).clamp(0.0, 1.0);
  }

  /// Wylicza docelowy opór adaptacyjnych spustów PS5 DualSense z telemetrii etapu.
  static ({
    DualSenseTriggerResistanceMode left,
    DualSenseTriggerResistanceMode right,
  }) computeDualSenseTriggerModes({
    required GamepadHardwareProfile profile,
    required bool adaptiveTriggersEnabled,
    required int cobbleStars,
    required double gradientPercent,
    required bool isWetRoad,
    required double riderFatiguePercent,
  }) {
    if (!profile.hasAdaptiveTriggers || !adaptiveTriggersEnabled) {
      return (
        left: DualSenseTriggerResistanceMode.off,
        right: DualSenseTriggerResistanceMode.off,
      );
    }

    final DualSenseTriggerResistanceMode leftMode;
    if (isWetRoad && gradientPercent < -4.0) {
      leftMode = DualSenseTriggerResistanceMode.wetDescentBrake;
    } else if (cobbleStars >= 3) {
      leftMode = DualSenseTriggerResistanceMode.cobbleFeedback;
    } else {
      leftMode = DualSenseTriggerResistanceMode.off;
    }

    final DualSenseTriggerResistanceMode rightMode;
    if (gradientPercent >= 10.0 || riderFatiguePercent >= 80.0) {
      rightMode = DualSenseTriggerResistanceMode.steepClimbResistance;
    } else if (cobbleStars >= 4) {
      rightMode = DualSenseTriggerResistanceMode.cobbleFeedback;
    } else {
      rightMode = DualSenseTriggerResistanceMode.aeroSprintSnap;
    }

    return (left: leftMode, right: rightMode);
  }

  /// Przetwarza surową ramkę kontrolera na gotowe polecenia dla silnika wyścigu 3D.
  GamepadMappedFrameOutput processFrame({
    required GamepadRawInputFrame rawFrame,
    required GamepadRawInputFrame previousFrame,
    required GamepadHardwareProfile profile,
    required GamepadDeadzoneAndCurveConfig config,
    required Map<GamepadLogicalButton, CyclingGamepadAction> bindings,
    int cobbleStars = 0,
    double gradientPercent = 0.0,
    bool isWetRoad = false,
    double riderFatiguePercent = 0.0,
  }) {
    final leftStick = applyRadialDeadzoneAndCurve(
      rawX: rawFrame.leftStickX,
      rawY: rawFrame.leftStickY,
      deadzone: config.leftStickDeadzone,
      curveExponent: config.responseCurveExponent,
    );
    final rightStick = applyRadialDeadzoneAndCurve(
      rawX: rawFrame.rightStickX,
      rawY: rawFrame.rightStickY,
      deadzone: config.rightStickDeadzone,
      curveExponent: config.responseCurveExponent,
    );

    final throttle = applyTriggerDeadzone(
      rawValue: rawFrame.rightTrigger,
      deadzone: config.triggerDeadzone,
    );
    final brake = applyTriggerDeadzone(
      rawValue: rawFrame.leftTrigger,
      deadzone: config.triggerDeadzone,
    );

    double lateralSteer = leftStick.dx;
    if (profile.supportsGyro &&
        config.enableGyroDescentSteering &&
        rawFrame.gyroRollRad.abs() > 0.05) {
      final gyroContribution = (rawFrame.gyroRollRad * 0.45).clamp(-0.5, 0.5);
      lateralSteer = (lateralSteer + gyroContribution).clamp(-1.0, 1.0);
    }

    final cameraY = config.invertCameraY ? -rightStick.dy : rightStick.dy;

    final activeActions = <CyclingGamepadAction>{};
    for (final button in rawFrame.pressedButtons) {
      final action = bindings[button];
      if (action != null) {
        activeActions.add(action);
      }
    }

    final previousActions = <CyclingGamepadAction>{};
    for (final button in previousFrame.pressedButtons) {
      final action = bindings[button];
      if (action != null) {
        previousActions.add(action);
      }
    }

    final justTriggered = activeActions.difference(previousActions);
    final justReleased = previousActions.difference(activeActions);

    final triggerModes = computeDualSenseTriggerModes(
      profile: profile,
      adaptiveTriggersEnabled: config.enableAdaptiveTriggers,
      cobbleStars: cobbleStars,
      gradientPercent: gradientPercent,
      isWetRoad: isWetRoad,
      riderFatiguePercent: riderFatiguePercent,
    );

    return GamepadMappedFrameOutput(
      lateralSteerNormalized: lateralSteer,
      longitudinalEffortNormalized: (-leftStick.dy).clamp(-1.0, 1.0),
      cameraOrbitX: rightStick.dx,
      cameraOrbitY: cameraY,
      throttlePower: throttle,
      brakeIntensity: brake,
      activeActions: activeActions,
      justTriggeredActions: justTriggered,
      justReleasedActions: justReleased,
      leftTriggerMode: triggerModes.left,
      rightTriggerMode: triggerModes.right,
    );
  }
}

/// Wpis historii zdarzeń diagnostycznych kontrolera.
@immutable
class GamepadInputEventLog {
  final DateTime timestamp;
  final String message;
  final GamepadHardwareProfile profile;

  const GamepadInputEventLog({
    required this.timestamp,
    required this.message,
    required this.profile,
  });
}

/// Pełny stan podsystemu kontrolerów w Riverpod.
@immutable
class ControllerGamepadState {
  final List<ConnectedGamepadDevice> connectedDevices;
  final String? activeDeviceId;
  final GamepadHardwareProfile activeProfile;
  final GamepadControlPreset activePreset;
  final GamepadDeadzoneAndCurveConfig config;
  final Map<GamepadLogicalButton, CyclingGamepadAction> bindings;
  final GamepadRawInputFrame latestRawFrame;
  final GamepadMappedFrameOutput latestMappedOutput;
  final GamepadLogicalButton? buttonAwaitingRemap;
  final List<GamepadInputEventLog> eventLog;

  const ControllerGamepadState({
    this.connectedDevices = const <ConnectedGamepadDevice>[],
    this.activeDeviceId,
    this.activeProfile = GamepadHardwareProfile.xboxSeries,
    this.activePreset = GamepadControlPreset.proPelotonDirector,
    this.config = const GamepadDeadzoneAndCurveConfig(),
    this.bindings = const <GamepadLogicalButton, CyclingGamepadAction>{},
    this.latestRawFrame = const GamepadRawInputFrame(),
    this.latestMappedOutput = const GamepadMappedFrameOutput(),
    this.buttonAwaitingRemap,
    this.eventLog = const <GamepadInputEventLog>[],
  });

  ConnectedGamepadDevice? get activeDevice {
    if (activeDeviceId == null) return null;
    for (final device in connectedDevices) {
      if (device.deviceId == activeDeviceId) return device;
    }
    return null;
  }

  ControllerGamepadState copyWith({
    List<ConnectedGamepadDevice>? connectedDevices,
    String? activeDeviceId,
    bool clearActiveDevice = false,
    GamepadHardwareProfile? activeProfile,
    GamepadControlPreset? activePreset,
    GamepadDeadzoneAndCurveConfig? config,
    Map<GamepadLogicalButton, CyclingGamepadAction>? bindings,
    GamepadRawInputFrame? latestRawFrame,
    GamepadMappedFrameOutput? latestMappedOutput,
    GamepadLogicalButton? buttonAwaitingRemap,
    bool clearButtonAwaitingRemap = false,
    List<GamepadInputEventLog>? eventLog,
  }) {
    return ControllerGamepadState(
      connectedDevices: connectedDevices ?? this.connectedDevices,
      activeDeviceId:
          clearActiveDevice ? null : (activeDeviceId ?? this.activeDeviceId),
      activeProfile: activeProfile ?? this.activeProfile,
      activePreset: activePreset ?? this.activePreset,
      config: config ?? this.config,
      bindings: bindings ?? this.bindings,
      latestRawFrame: latestRawFrame ?? this.latestRawFrame,
      latestMappedOutput: latestMappedOutput ?? this.latestMappedOutput,
      buttonAwaitingRemap: clearButtonAwaitingRemap
          ? null
          : (buttonAwaitingRemap ?? this.buttonAwaitingRemap),
      eventLog: eventLog ?? this.eventLog,
    );
  }
}

/// Kontroler Riverpod zarządzający mapowaniem wejścia Xbox / DualSense / Steam Deck.
class ControllerGamepadMapperNotifier
    extends StateNotifier<ControllerGamepadState> {
  final ControllerGamepadInputMapper _mapper;

  ControllerGamepadMapperNotifier({
    ControllerGamepadInputMapper mapper = const ControllerGamepadInputMapper(),
  })  : _mapper = mapper,
        super(
          ControllerGamepadState(
            connectedDevices: [
              ConnectedGamepadDevice(
                deviceId: 'pad-xbox-01',
                name: 'Xbox Wireless Controller',
                vendorId: 0x045E,
                profile: GamepadHardwareProfile.xboxSeries,
                batteryPercent: 92,
                isWireless: true,
                connectedAt: DateTime(2026, 11, 17, 20, 0),
              ),
              ConnectedGamepadDevice(
                deviceId: 'pad-ps5-02',
                name: 'DualSense Wireless Controller',
                vendorId: 0x054C,
                profile: GamepadHardwareProfile.playStationDualSense,
                batteryPercent: 78,
                isWireless: true,
                connectedAt: DateTime(2026, 11, 17, 20, 1),
              ),
              ConnectedGamepadDevice(
                deviceId: 'pad-deck-03',
                name: 'Steam Deck Virtual Gamepad (Neptune)',
                vendorId: 0x28DE,
                profile: GamepadHardwareProfile.steamDeck,
                batteryPercent: 100,
                isWireless: false,
                connectedAt: DateTime(2026, 11, 17, 20, 2),
              ),
            ],
            activeDeviceId: 'pad-xbox-01',
            activeProfile: GamepadHardwareProfile.xboxSeries,
            activePreset: GamepadControlPreset.proPelotonDirector,
            bindings: ControllerGamepadInputMapper.defaultBindingsFor(
              GamepadControlPreset.proPelotonDirector,
            ),
          ),
        );

  /// Rejestruje nowo podłączony kontroler i automatycznie dobiera jego profil sprzętowy.
  void registerConnectedDevice({
    required String deviceId,
    required String deviceName,
    int? vendorId,
    int batteryPercent = 100,
    bool isWireless = true,
  }) {
    final profile = GamepadHardwareProfile.detectFromDeviceName(
      deviceName,
      vendorId: vendorId,
    );
    final device = ConnectedGamepadDevice(
      deviceId: deviceId,
      name: deviceName,
      vendorId: vendorId ?? profile.vendorId,
      profile: profile,
      batteryPercent: batteryPercent.clamp(0, 100),
      isWireless: isWireless,
      connectedAt: DateTime.now(),
    );

    final updatedList = [
      ...state.connectedDevices.where((d) => d.deviceId != deviceId),
      device,
    ];
    final nextPreset = profile == GamepadHardwareProfile.steamDeck
        ? GamepadControlPreset.steamDeckHandheld
        : state.activePreset;

    state = state.copyWith(
      connectedDevices: updatedList,
      activeDeviceId: device.deviceId,
      activeProfile: profile,
      activePreset: nextPreset,
      bindings: profile == GamepadHardwareProfile.steamDeck
          ? ControllerGamepadInputMapper.defaultBindingsFor(nextPreset)
          : state.bindings,
      eventLog: _appendLog(
        'Podłączono ${profile.shortName}: $deviceName',
        profile,
      ),
    );
  }

  /// Odłącza kontroler o podanym identyfikatorze.
  void disconnectDevice(String deviceId) {
    final updated =
        state.connectedDevices.where((d) => d.deviceId != deviceId).toList();
    final nextActive = state.activeDeviceId == deviceId
        ? (updated.isNotEmpty ? updated.first : null)
        : state.activeDevice;
    state = state.copyWith(
      connectedDevices: updated,
      activeDeviceId: nextActive?.deviceId,
      clearActiveDevice: nextActive == null,
      activeProfile: nextActive?.profile ?? state.activeProfile,
      eventLog: _appendLog(
        'Odłączono kontroler $deviceId',
        state.activeProfile,
      ),
    );
  }

  /// Przełącza aktywny profil kontrolera (np. Xbox <-> DualSense <-> Steam Deck).
  void selectHardwareProfile(GamepadHardwareProfile profile) {
    ConnectedGamepadDevice? matchingDevice;
    for (final device in state.connectedDevices) {
      if (device.profile == profile) {
        matchingDevice = device;
        break;
      }
    }

    final shouldSwitchPreset = profile == GamepadHardwareProfile.steamDeck &&
        state.activePreset != GamepadControlPreset.steamDeckHandheld;
    final nextPreset = shouldSwitchPreset
        ? GamepadControlPreset.steamDeckHandheld
        : state.activePreset;

    state = state.copyWith(
      activeProfile: profile,
      activeDeviceId: matchingDevice?.deviceId ?? state.activeDeviceId,
      activePreset: nextPreset,
      bindings: shouldSwitchPreset
          ? ControllerGamepadInputMapper.defaultBindingsFor(nextPreset)
          : state.bindings,
      eventLog: _appendLog(
        'Aktywny profil: ${profile.displayName}',
        profile,
      ),
    );
  }

  /// Zmienia aktywny preset sterowania i przywraca jego domyślne mapowania.
  void applyPreset(GamepadControlPreset preset) {
    state = state.copyWith(
      activePreset: preset,
      bindings: ControllerGamepadInputMapper.defaultBindingsFor(preset),
      clearButtonAwaitingRemap: true,
      eventLog: _appendLog(
        'Załadowano preset: ${preset.label}',
        state.activeProfile,
      ),
    );
  }

  /// Aktualizuje konfigurację martwych stref i krzywej czułości.
  void updateConfig(GamepadDeadzoneAndCurveConfig nextConfig) {
    state = state.copyWith(config: nextConfig);
  }

  /// Rozpoczyna lub anuluje tryb przypisywania nowego działania do przycisku.
  void setButtonAwaitingRemap(GamepadLogicalButton? button) {
    if (button == null) {
      state = state.copyWith(clearButtonAwaitingRemap: true);
    } else {
      state = state.copyWith(buttonAwaitingRemap: button);
    }
  }

  /// Przypisuje wybraną akcję do przycisku fizycznego (z automatycznym rozwiązaniem konfliktu).
  void remapButton(
    GamepadLogicalButton button,
    CyclingGamepadAction action,
  ) {
    final updated = Map<GamepadLogicalButton, CyclingGamepadAction>.from(
      state.bindings,
    );
    final previousAction = updated[button];
    GamepadLogicalButton? conflictingButton;
    for (final entry in updated.entries) {
      if (entry.key != button && entry.value == action) {
        conflictingButton = entry.key;
        break;
      }
    }

    if (conflictingButton != null) {
      if (previousAction != null) {
        updated[conflictingButton] = previousAction;
      } else {
        updated.remove(conflictingButton);
      }
    }
    updated[button] = action;

    final glyph = button.glyphFor(state.activeProfile).symbol;
    state = state.copyWith(
      bindings: updated,
      clearButtonAwaitingRemap: true,
      eventLog: _appendLog(
        'Przypisano [$glyph] -> ${action.label}',
        state.activeProfile,
      ),
    );
  }

  /// Przetwarza nową ramkę wejściową (z kontrolera fizycznego lub symulatora diagnostycznego).
  GamepadMappedFrameOutput submitRawInputFrame(
    GamepadRawInputFrame rawFrame, {
    int cobbleStars = 0,
    double gradientPercent = 0.0,
    bool isWetRoad = false,
    double riderFatiguePercent = 0.0,
  }) {
    final mapped = _mapper.processFrame(
      rawFrame: rawFrame,
      previousFrame: state.latestRawFrame,
      profile: state.activeProfile,
      config: state.config,
      bindings: state.bindings,
      cobbleStars: cobbleStars,
      gradientPercent: gradientPercent,
      isWetRoad: isWetRoad,
      riderFatiguePercent: riderFatiguePercent,
    );

    final newLogs = List<GamepadInputEventLog>.from(state.eventLog);
    for (final triggered in mapped.justTriggeredActions) {
      newLogs.insert(
        0,
        GamepadInputEventLog(
          timestamp: DateTime.now(),
          message: 'Akcja: ${triggered.label}',
          profile: state.activeProfile,
        ),
      );
    }
    if (newLogs.length > 20) {
      newLogs.removeRange(20, newLogs.length);
    }

    state = state.copyWith(
      latestRawFrame: rawFrame,
      latestMappedOutput: mapped,
      eventLog: newLogs,
    );

    if (mapped.justTriggeredActions.isNotEmpty &&
        state.config.vibrationIntensity > 0.0) {
      HapticFeedback.selectionClick();
    }
    return mapped;
  }

  /// Wyzwala testowy impuls haptyczny / adaptacyjnych spustów.
  Future<void> triggerCalibrationPulse() async {
    if (state.config.vibrationIntensity > 0.5) {
      await HapticFeedback.mediumImpact();
    } else if (state.config.vibrationIntensity > 0.0) {
      await HapticFeedback.lightImpact();
    }
    state = state.copyWith(
      eventLog: _appendLog(
        'Test haptyki (${(state.config.vibrationIntensity * 100).round()}%)',
        state.activeProfile,
      ),
    );
  }

  List<GamepadInputEventLog> _appendLog(
    String message,
    GamepadHardwareProfile profile,
  ) {
    final next = [
      GamepadInputEventLog(
        timestamp: DateTime.now(),
        message: message,
        profile: profile,
      ),
      ...state.eventLog,
    ];
    if (next.length > 20) {
      return next.sublist(0, 20);
    }
    return next;
  }
}

/// Główny provider Riverpod dla systemu mapowania kontrolerów.
final controllerGamepadMapperProvider = StateNotifierProvider<
    ControllerGamepadMapperNotifier, ControllerGamepadState>(
  (ref) => ControllerGamepadMapperNotifier(),
);

/// Produkcyjny panel konfiguracji i diagnostyki kontrolerów Xbox / DualSense / Steam Deck.
class ControllerGamepadMapperPanel extends ConsumerWidget {
  const ControllerGamepadMapperPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(controllerGamepadMapperProvider);
    final notifier = ref.read(controllerGamepadMapperProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompact = width < 680;
          final isWideDesktop = width >= 1120;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderBanner(
                  state: state,
                  isCompact: isCompact,
                  onTestPulse: notifier.triggerCalibrationPulse,
                ),
                const SizedBox(height: 16),
                _HardwareProfileSelector(
                  activeProfile: state.activeProfile,
                  connectedDevices: state.connectedDevices,
                  onSelectProfile: notifier.selectHardwareProfile,
                ),
                const SizedBox(height: 16),
                if (isWideDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _PresetAndCalibrationCard(
                              state: state,
                              onSelectPreset: notifier.applyPreset,
                              onUpdateConfig: notifier.updateConfig,
                            ),
                            const SizedBox(height: 16),
                            _StickTelemetryTesterCard(
                              state: state,
                              onSubmitRawFrame: notifier.submitRawInputFrame,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _ButtonBindingsGridCard(
                          state: state,
                          onStartRemap: notifier.setButtonAwaitingRemap,
                          onRemap: notifier.remapButton,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _PresetAndCalibrationCard(
                    state: state,
                    onSelectPreset: notifier.applyPreset,
                    onUpdateConfig: notifier.updateConfig,
                  ),
                  const SizedBox(height: 16),
                  _StickTelemetryTesterCard(
                    state: state,
                    onSubmitRawFrame: notifier.submitRawInputFrame,
                  ),
                  const SizedBox(height: 16),
                  _ButtonBindingsGridCard(
                    state: state,
                    onStartRemap: notifier.setButtonAwaitingRemap,
                    onRemap: notifier.remapButton,
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

class _HeaderBanner extends StatelessWidget {
  final ControllerGamepadState state;
  final bool isCompact;
  final VoidCallback onTestPulse;

  const _HeaderBanner({
    required this.state,
    required this.isCompact,
    required this.onTestPulse,
  });

  @override
  Widget build(BuildContext context) {
    final activeDevice = state.activeDevice;
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: state.activeProfile.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        state.activeProfile.accentColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
                  color: state.activeProfile.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kontrolery i Mapowanie Wejścia',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activeDevice != null
                          ? '${activeDevice.name} • Bateria ${activeDevice.batteryPercent}%'
                          : 'Aktywny profil: ${state.activeProfile.displayName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _InteractiveActionButton(
            label: 'Test Haptyki',
            icon: Icons.vibration_rounded,
            accentColor: AppColors.goldAccent,
            onPressed: state.config.vibrationIntensity > 0 ? onTestPulse : null,
          ),
        ],
      ),
    );
  }
}

class _HardwareProfileSelector extends StatelessWidget {
  final GamepadHardwareProfile activeProfile;
  final List<ConnectedGamepadDevice> connectedDevices;
  final ValueChanged<GamepadHardwareProfile> onSelectProfile;

  const _HardwareProfileSelector({
    required this.activeProfile,
    required this.connectedDevices,
    required this.onSelectProfile,
  });

  @override
  Widget build(BuildContext context) {
    final profiles = [
      GamepadHardwareProfile.xboxSeries,
      GamepadHardwareProfile.playStationDualSense,
      GamepadHardwareProfile.steamDeck,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil Sprzętowy Kontrolera',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 600;
              if (isStacked) {
                return Column(
                  children: [
                    for (var i = 0; i < profiles.length; i++) ...[
                      _ProfileCardButton(
                        profile: profiles[i],
                        isSelected: activeProfile == profiles[i],
                        isConnected: connectedDevices
                            .any((d) => d.profile == profiles[i]),
                        onTap: () => onSelectProfile(profiles[i]),
                      ),
                      if (i < profiles.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < profiles.length; i++) ...[
                    Expanded(
                      child: _ProfileCardButton(
                        profile: profiles[i],
                        isSelected: activeProfile == profiles[i],
                        isConnected: connectedDevices
                            .any((d) => d.profile == profiles[i]),
                        onTap: () => onSelectProfile(profiles[i]),
                      ),
                    ),
                    if (i < profiles.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileCardButton extends StatefulWidget {
  final GamepadHardwareProfile profile;
  final bool isSelected;
  final bool isConnected;
  final VoidCallback onTap;

  const _ProfileCardButton({
    required this.profile,
    required this.isSelected,
    required this.isConnected,
    required this.onTap,
  });

  @override
  State<_ProfileCardButton> createState() => _ProfileCardButtonState();
}

class _ProfileCardButtonState extends State<_ProfileCardButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.profile.accentColor;
    final borderColor = widget.isSelected
        ? accent
        : _focused
            ? AppColors.goldAccent
            : _hovered
                ? accent.withValues(alpha: 0.6)
                : const Color(0xFF2A2F3D);

    final capabilities = <String>[
      if (widget.profile.hasAdaptiveTriggers) 'Adaptacyjne spusty',
      if (widget.profile.hasBackPaddles) 'Łopatki L4/R4/L5/R5',
      if (widget.profile.supportsGyro) 'Żyroskop',
      if (!widget.profile.hasAdaptiveTriggers && !widget.profile.hasBackPaddles)
        'Natywny XInput',
    ].join(' • ');

    return FocusableActionDetector(
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
            _pressed ? 0.985 : 1.0,
            _pressed ? 0.985 : 1.0,
            1.0,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.surfaceLight
                : _hovered
                    ? const Color(0xFF1E222B)
                    : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.profile.shortName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.isSelected
                            ? accent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isConnected
                          ? AppColors.statusSuccess.withValues(alpha: 0.16)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.isConnected ? 'Wykryty' : 'Symulacja',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.isConnected
                            ? AppColors.statusSuccess
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                capabilities,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetAndCalibrationCard extends StatelessWidget {
  final ControllerGamepadState state;
  final ValueChanged<GamepadControlPreset> onSelectPreset;
  final ValueChanged<GamepadDeadzoneAndCurveConfig> onUpdateConfig;

  const _PresetAndCalibrationCard({
    required this.state,
    required this.onSelectPreset,
    required this.onUpdateConfig,
  });

  @override
  Widget build(BuildContext context) {
    final config = state.config;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preset Sterowania i Kalibracja Osi',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GamepadControlPreset.values.map((preset) {
              final selected = preset == state.activePreset;
              return _PresetChipButton(
                label: preset.label,
                selected: selected,
                onTap: () => onSelectPreset(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            state.activePreset.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _CalibrationSliderRow(
            label: 'Deadzone Lewy Drążek',
            valueText: '${(config.leftStickDeadzone * 100).round()}%',
            value: config.leftStickDeadzone,
            min: 0.02,
            max: 0.40,
            onChanged: (val) => onUpdateConfig(
              config.copyWith(leftStickDeadzone: val),
            ),
          ),
          _CalibrationSliderRow(
            label: 'Deadzone Prawy Drążek',
            valueText: '${(config.rightStickDeadzone * 100).round()}%',
            value: config.rightStickDeadzone,
            min: 0.02,
            max: 0.40,
            onChanged: (val) => onUpdateConfig(
              config.copyWith(rightStickDeadzone: val),
            ),
          ),
          _CalibrationSliderRow(
            label: 'Krzywa Czułości',
            valueText: config.responseCurveExponent.toStringAsFixed(2),
            value: config.responseCurveExponent,
            min: 1.0,
            max: 2.5,
            onChanged: (val) => onUpdateConfig(
              config.copyWith(responseCurveExponent: val),
            ),
          ),
          _CalibrationSliderRow(
            label: 'Intensywność Wibracji',
            valueText: '${(config.vibrationIntensity * 100).round()}%',
            value: config.vibrationIntensity,
            min: 0.0,
            max: 1.0,
            onChanged: (val) => onUpdateConfig(
              config.copyWith(vibrationIntensity: val),
            ),
          ),
          const SizedBox(height: 8),
          _FeatureToggleRow(
            label: 'Odwróć oś Y kamery 3D',
            value: config.invertCameraY,
            enabled: true,
            onChanged: (v) =>
                onUpdateConfig(config.copyWith(invertCameraY: v)),
          ),
          _FeatureToggleRow(
            label: 'Adaptacyjne spusty DualSense (L2/R2)',
            value: config.enableAdaptiveTriggers,
            enabled: state.activeProfile.hasAdaptiveTriggers,
            onChanged: (v) =>
                onUpdateConfig(config.copyWith(enableAdaptiveTriggers: v)),
          ),
          _FeatureToggleRow(
            label: 'Żyroskop w zjazdach Supertuck',
            value: config.enableGyroDescentSteering,
            enabled: state.activeProfile.supportsGyro,
            onChanged: (v) =>
                onUpdateConfig(config.copyWith(enableGyroDescentSteering: v)),
          ),
        ],
      ),
    );
  }
}

class _StickTelemetryTesterCard extends StatelessWidget {
  final ControllerGamepadState state;
  final GamepadMappedFrameOutput Function(
    GamepadRawInputFrame rawFrame, {
    int cobbleStars,
    double gradientPercent,
    bool isWetRoad,
    double riderFatiguePercent,
  }) onSubmitRawFrame;

  const _StickTelemetryTesterCard({
    required this.state,
    required this.onSubmitRawFrame,
  });

  @override
  Widget build(BuildContext context) {
    final mapped = state.latestMappedOutput;
    final raw = state.latestRawFrame;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Telemetria Analogowa Na Żywo',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _InteractiveActionButton(
                label: 'Test Bruk 5★',
                icon: Icons.bolt_rounded,
                accentColor: AppColors.primaryAccent,
                onPressed: () {
                  onSubmitRawFrame(
                    const GamepadRawInputFrame(
                      leftStickX: 0.42,
                      leftStickY: -0.78,
                      rightTrigger: 0.88,
                      pressedButtons: {GamepadLogicalButton.south},
                    ),
                    cobbleStars: 5,
                    gradientPercent: 11.5,
                    isWetRoad: true,
                    riderFatiguePercent: 72.0,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final stickWidget = SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _AnalogStickVisualizerPainter(
                    rawX: raw.leftStickX,
                    rawY: raw.leftStickY,
                    deadzone: state.config.leftStickDeadzone,
                    accentColor: state.activeProfile.accentColor,
                  ),
                ),
              );

              final metrics = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TelemetryMetricLine(
                    label: 'Tor jazdy (X)',
                    value: mapped.lateralSteerNormalized.toStringAsFixed(2),
                  ),
                  _TelemetryMetricLine(
                    label: 'Moc spustu RT/R2',
                    value: '${(mapped.throttlePower * 100).round()}%',
                  ),
                  _TelemetryMetricLine(
                    label: 'Hamulec LT/L2',
                    value: '${(mapped.brakeIntensity * 100).round()}%',
                  ),
                  _TelemetryMetricLine(
                    label: 'Tryb spustu R2',
                    value: mapped.rightTriggerMode.label,
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: stickWidget),
                    const SizedBox(height: 12),
                    metrics,
                  ],
                );
              }
              return Row(
                children: [
                  stickWidget,
                  const SizedBox(width: 16),
                  Expanded(child: metrics),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalogStickVisualizerPainter extends CustomPainter {
  final double rawX;
  final double rawY;
  final double deadzone;
  final Color accentColor;

  _AnalogStickVisualizerPainter({
    required this.rawX,
    required this.rawY,
    required this.deadzone,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final deadzonePaint = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * deadzone, deadzonePaint);

    final crossPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crossPaint,
    );

    final dotOffset = Offset(
      center.dx + rawX.clamp(-1.0, 1.0) * radius,
      center.dy + rawY.clamp(-1.0, 1.0) * radius,
    );
    final dotPaint = Paint()..color = accentColor;
    canvas.drawCircle(dotOffset, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogStickVisualizerPainter oldDelegate) {
    return oldDelegate.rawX != rawX ||
        oldDelegate.rawY != rawY ||
        oldDelegate.deadzone != deadzone ||
        oldDelegate.accentColor != accentColor;
  }
}

class _ButtonBindingsGridCard extends StatelessWidget {
  final ControllerGamepadState state;
  final ValueChanged<GamepadLogicalButton?> onStartRemap;
  final void Function(
    GamepadLogicalButton button,
    CyclingGamepadAction action,
  ) onRemap;

  const _ButtonBindingsGridCard({
    required this.state,
    required this.onStartRemap,
    required this.onRemap,
  });

  @override
  Widget build(BuildContext context) {
    final entries = state.bindings.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Mapa Przycisków i Akcji Kolarskich',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (state.buttonAwaitingRemap != null)
                TextButton(
                  onPressed: () => onStartRemap(null),
                  child: const Text(
                    'Anuluj',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.amberWarning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Brak przypisanych przycisków w tym presecie.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final glyph = entry.key.glyphFor(state.activeProfile);
                final isEditing = state.buttonAwaitingRemap == entry.key;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isEditing
                        ? AppColors.surfaceLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEditing
                          ? AppColors.goldAccent
                          : const Color(0xFF2A2F3D),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(minWidth: 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: glyph.badgeColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: glyph.badgeColor.withValues(alpha: 0.5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          glyph.symbol,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: glyph.badgeColor == AppColors.surfaceLight
                                ? AppColors.textPrimary
                                : glyph.badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${glyph.fullLabel} • ${entry.value.category}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<CyclingGamepadAction>(
                        tooltip: 'Zmień przypisaną akcję',
                        color: AppColors.surfaceLight,
                        onSelected: (nextAction) =>
                            onRemap(entry.key, nextAction),
                        onOpened: () => onStartRemap(entry.key),
                        onCanceled: () => onStartRemap(null),
                        itemBuilder: (context) => CyclingGamepadAction.values
                            .map(
                              (action) => PopupMenuItem<CyclingGamepadAction>(
                                value: action,
                                child: Text(
                                  action.label,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2A2F3D)),
                          ),
                          child: const Text(
                            'Zmień',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.28)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.20)
                : widget.accentColor.withValues(alpha: 0.14);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: !enabled
                  ? const Color(0xFF2A2F3D)
                  : _focused
                      ? AppColors.goldAccent
                      : widget.accentColor.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: enabled ? widget.accentColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
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
  final VoidCallback onTap;

  const _PresetChipButton({
    required this.label,
    required this.selected,
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
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected
                  ? AppColors.primaryAccent
                  : _focused
                      ? AppColors.goldAccent
                      : const Color(0xFF2A2F3D),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalibrationSliderRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _CalibrationSliderRow({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.goldAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
            trackHeight: 3.0,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _FeatureToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _FeatureToggleRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Switch(
              value: enabled && value,
              activeThumbColor: AppColors.goldAccent,
              activeTrackColor: AppColors.primaryAccent,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryMetricLine extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryMetricLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
