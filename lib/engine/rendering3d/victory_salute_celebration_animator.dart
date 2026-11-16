// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Zestaw 6 animacji cieszenia się ze zwycięstwa na linii mety.
enum VictorySaluteType {
  /// Klasyczne uniesienie obu rąk w górę w geście triumfu (V-pose).
  bothHandsRaised(
    id: 'both_hands_raised',
    label: 'Uniesienie obu rąk',
    shortLabel: 'Obie ręce',
    description:
        'Triumfalne uniesienie obu ramion nad głowę z wyprostowanym tułowiem i spojrzeniem w niebo.',
    requiresNoHands: true,
    accentColor: AppColors.goldAccent,
    icon: Icons.emoji_events_rounded,
  ),

  /// Zapięcie zamka koszulki przed fotoreporterami tuż przed kreską.
  zipUpJersey(
    id: 'zip_up_jersey',
    label: 'Zapięcie koszulki',
    shortLabel: 'Zamek koszulki',
    description:
        'Profesjonalne zasunięcie suwaka koszulki pod szyję przed obiektywami fotoreporterów.',
    requiresNoHands: true,
    accentColor: AppColors.cyanAccent,
    icon: Icons.checkroom_rounded,
  ),

  /// Wskazanie palcem na logo głównego sponsora na klatce piersiowej.
  pointAtSponsorLogo(
    id: 'point_at_sponsor',
    label: 'Wskazanie na sponsora',
    shortLabel: 'Logo sponsora',
    description:
        'Wyraźne wskazanie palcem na logotyp sponsora tytularnego na froncie koszulki.',
    requiresNoHands: false,
    accentColor: AppColors.accentBlue,
    icon: Icons.ads_click_rounded,
  ),

  /// Emocjonalne uderzenie pięścią w pierś (serce/herb drużyny).
  fistBumpChest(
    id: 'fist_bump_chest',
    label: 'Uderzenie pięścią w pierś',
    shortLabel: 'Pięść w pierś',
    description:
        'Dynamiczne, dwukrotne uderzenie zaciśniętą pięścią w pierś na znak dumy i determinacji.',
    requiresNoHands: false,
    accentColor: AppColors.primaryAccent,
    icon: Icons.favorite_rounded,
  ),

  /// Teatralny ukłon przed kibicami i kamerami na mecie.
  theatricalBow(
    id: 'theatrical_bow',
    label: 'Ukłon przed publiką',
    shortLabel: 'Ukłon',
    description:
        'Elegancki ukłon tułowia z szerokim gestem ramienia w stronę trybun i fotoreporterów.',
    requiresNoHands: true,
    accentColor: AppColors.statusSuccess,
    icon: Icons.celebration_rounded,
  ),

  /// Wyczerpane oparcie się na kierownicy po morderczym finiszu pod górę.
  exhaustedHandlebarLean(
    id: 'exhausted_handlebar_lean',
    label: 'Oparcie na kierownicy',
    shortLabel: 'Finisz pod górę',
    description:
        'Skrajnie wyczerpane oparcie przedramion i głowy na kierownicy po górskim finiszu.',
    requiresNoHands: false,
    accentColor: AppColors.amberWarning,
    icon: Icons.landscape_rounded,
  );

  final String id;
  final String label;
  final String shortLabel;
  final String description;
  final bool requiresNoHands;
  final Color accentColor;
  final IconData icon;

  const VictorySaluteType({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.requiresNoHands,
    required this.accentColor,
    required this.icon,
  });
}

/// Kontekst taktyczno-fizjologiczny finiszu używany do automatycznego doboru animacji.
class VictorySaluteContext {
  /// Identyfikator zwycięzcy etapu.
  final String riderId;

  /// Nachylenie drogi na linii mety [%].
  final double finishGradientPercent;

  /// Poziom wyczerpania kolarza na mecie [0.0..1.0].
  final double fatigueLevel;

  /// Czy zwycięstwo nastąpiło z samotnej ucieczki (dużo czasu przed kreską).
  final bool isSoloBreakaway;

  /// Czy rozstrzygnięcie nastąpiło w ciasnym sprincie grupowym.
  final bool isPhotoFinishSprint;

  /// Waga ekspozycji sponsora tytularnego [0.0..1.0].
  final double sponsorImportance;

  /// Charyzma / skłonność do show kolarza [0.0..1.0].
  final double showmanship;

  /// Liczba zwycięstw etapowych kolarza w sezonie.
  final int seasonVictoryCount;

  /// Opcjonalne ręczne wymuszenie konkretnego typu celebracji.
  final VictorySaluteType? overrideType;

  const VictorySaluteContext({
    required this.riderId,
    this.finishGradientPercent = 0.0,
    this.fatigueLevel = 0.45,
    this.isSoloBreakaway = false,
    this.isPhotoFinishSprint = false,
    this.sponsorImportance = 0.5,
    this.showmanship = 0.5,
    this.seasonVictoryCount = 1,
    this.overrideType,
  });
}

/// Konfiguracja czasowa i kinematyczna animatora celebracji zwycięstwa.
class VictorySaluteConfig {
  /// Całkowity czas trwania sekwencji celebracji na linii mety [s].
  final double durationSeconds;

  /// Czas płynnego wejścia w pozę z chwytu kierownicy [s].
  final double blendInSeconds;

  /// Czas płynnego powrotu rąk na kierownicę po minięciu mety [s].
  final double blendOutSeconds;

  /// Częstotliwość oddechu przy wyczerpaniu [Hz].
  final double exhaustionBreathHz;

  /// Maksymalna szerokość rozstawienia dłoni na kierownicy [m].
  final double handlebarHalfWidthMeters;

  const VictorySaluteConfig({
    this.durationSeconds = 3.2,
    this.blendInSeconds = 0.35,
    this.blendOutSeconds = 0.45,
    this.exhaustionBreathHz = 1.15,
    this.handlebarHalfWidthMeters = 0.19,
  });
}

/// Dane wejściowe pojedynczej klatki animacji celebracji.
class VictorySaluteFrameInput {
  /// Identyfikator kolarza.
  final String riderId;

  /// Wybrany typ animacji zwycięstwa.
  final VictorySaluteType saluteType;

  /// Czas od rozpoczęcia celebracji przed/na linii mety [s].
  final double elapsedSeconds;

  /// Aktualna prędkość roweru [m/s].
  final double speedMs;

  /// Nachylenie drogi na finiszu [%].
  final double gradientPercent;

  /// Poziom zmęczenia [0.0..1.0].
  final double fatigueLevel;

  /// Kąt przechyłu bocznego roweru [stopnie].
  final double bikeRollDegrees;

  const VictorySaluteFrameInput({
    required this.riderId,
    required this.saluteType,
    required this.elapsedSeconds,
    this.speedMs = 15.0,
    this.gradientPercent = 0.0,
    this.fatigueLevel = 0.4,
    this.bikeRollDegrees = 0.0,
  });
}

/// Wynikowa poza 3D kolarza w danej klatce celebracji (w lokalnym układzie roweru, suport = [0,0,0]).
class VictorySalutePose3D {
  final String riderId;
  final VictorySaluteType saluteType;

  /// Znormalizowany postęp animacji [0.0..1.0].
  final double normalizedProgress;

  /// Czytelna etykieta bieżącej fazy animacji.
  final String phaseLabel;

  /// Kąt pochylenia tułowia od poziomu [stopnie] (90° = pełny pion).
  final double torsoInclineDegrees;

  /// Skręt tułowia w osi Y [stopnie] (+ w prawo, - w lewo).
  final double torsoTwistDegrees;

  /// Pochylenie głowy [stopnie] (+ w górę, - w dół).
  final double headPitchDegrees;

  /// Obrót głowy na boki [stopnie].
  final double headYawDegrees;

  final vm.Vector3 hipPosition;
  final vm.Vector3 chestPosition;
  final vm.Vector3 headPosition;
  final vm.Vector3 rightElbowPosition;
  final vm.Vector3 leftElbowPosition;
  final vm.Vector3 rightHandPosition;
  final vm.Vector3 leftHandPosition;

  /// Stopień wskazania palcem wskazującym prawej dłoni [0.0..1.0].
  final double rightFingerPointingFactor;

  /// Stopień zaciśnięcia pięści prawej i lewej dłoni [0.0..1.0].
  final double rightFistClenchFactor;
  final double leftFistClenchFactor;

  /// Postęp zapięcia zamka koszulki [0.0..1.0].
  final double jerseyZipperProgress;

  /// Amplituda unoszenia klatki piersiowej od głębokiego oddechu [0.0..1.0].
  final double breathingAmplitude;

  /// Stabilność kierowania rowerem [0.0..1.0] (1.0 = obie ręce na kierownicy).
  final double steeringStability;

  /// Intensywność błysków fleszy fotoreporterów na linii mety [0.0..1.0].
  final double photographerFlashIntensity;

  /// Wskaźnik ekspozycji logotypu sponsora w kamerze [0.0..1.0].
  final double sponsorLogoVisibilityScore;

  const VictorySalutePose3D({
    required this.riderId,
    required this.saluteType,
    required this.normalizedProgress,
    required this.phaseLabel,
    required this.torsoInclineDegrees,
    required this.torsoTwistDegrees,
    required this.headPitchDegrees,
    required this.headYawDegrees,
    required this.hipPosition,
    required this.chestPosition,
    required this.headPosition,
    required this.rightElbowPosition,
    required this.leftElbowPosition,
    required this.rightHandPosition,
    required this.leftHandPosition,
    required this.rightFingerPointingFactor,
    required this.rightFistClenchFactor,
    required this.leftFistClenchFactor,
    required this.jerseyZipperProgress,
    required this.breathingAmplitude,
    required this.steeringStability,
    required this.photographerFlashIntensity,
    required this.sponsorLogoVisibilityScore,
  });
}

/// Animator zestawu 6 kinematycznych celebracji zwycięstwa na linii mety 3D.
class VictorySaluteCelebrationAnimator {
  final VictorySaluteConfig config;

  // Bazowe punkty odniesienia w lokalnym układzie roweru [m] (suport = [0, 0, 0])
  static final vm.Vector3 _baseHip = vm.Vector3(0.0, 0.72, -0.22);
  static final vm.Vector3 _hoodRight = vm.Vector3(0.19, 0.64, 0.55);
  static final vm.Vector3 _hoodLeft = vm.Vector3(-0.19, 0.64, 0.55);
  static const double _torsoLengthMeters = 0.54;
  static const double _neckToHeadMeters = 0.21;

  const VictorySaluteCelebrationAnimator({
    this.config = const VictorySaluteConfig(),
  });

  /// Dobiera najbardziej realistyczną celebrację na podstawie kontekstu finiszu i cech kolarza.
  VictorySaluteType selectCelebration(
    VictorySaluteContext context, {
    int? seed,
  }) {
    if (context.overrideType != null) {
      return context.overrideType!;
    }

    final double gradient = context.finishGradientPercent;
    final double fatigue = context.fatigueLevel.clamp(0.0, 1.0);
    final double sponsor = context.sponsorImportance.clamp(0.0, 1.0);
    final double show = context.showmanship.clamp(0.0, 1.0);

    // Finisz na stromym podjeździe przy wysokim zmęczeniu -> wyczerpane oparcie na kierownicy
    if (gradient >= 6.5 && fatigue >= 0.68) {
      return VictorySaluteType.exhaustedHandlebarLean;
    }

    // Bardzo ciasny sprint na kresce -> brak czasu na zapięcie koszulki czy ukłon
    if (context.isPhotoFinishSprint) {
      return fatigue > 0.75
          ? VictorySaluteType.exhaustedHandlebarLean
          : VictorySaluteType.bothHandsRaised;
    }

    // Ważona punktacja dla pozostałych wariantów
    final Map<VictorySaluteType, double> weights = <VictorySaluteType, double>{
      VictorySaluteType.bothHandsRaised: 1.35 + (1.0 - fatigue) * 0.4,
      VictorySaluteType.zipUpJersey:
          context.isSoloBreakaway ? 1.45 + sponsor * 0.5 : 0.35,
      VictorySaluteType.pointAtSponsorLogo:
          0.65 + sponsor * 1.4 + (context.isSoloBreakaway ? 0.35 : 0.0),
      VictorySaluteType.fistBumpChest:
          0.75 + show * 0.8 + (context.seasonVictoryCount <= 1 ? 0.4 : 0.0),
      VictorySaluteType.theatricalBow:
          context.isSoloBreakaway ? 0.55 + show * 1.35 : 0.2,
      VictorySaluteType.exhaustedHandlebarLean:
          (gradient > 4.0 ? 0.6 : 0.1) + fatigue * 1.1,
    };

    final int deterministicSeed =
        seed ??
        (context.riderId.hashCode ^
            (context.seasonVictoryCount * 31) ^
            (fatigue * 1000).round());
    final math.Random rng = math.Random(deterministicSeed);

    double totalWeight = 0.0;
    for (final double w in weights.values) {
      totalWeight += math.max(0.0, w);
    }

    if (totalWeight <= 0.0) {
      return VictorySaluteType.bothHandsRaised;
    }

    double roll = rng.nextDouble() * totalWeight;
    for (final MapEntry<VictorySaluteType, double> entry in weights.entries) {
      roll -= math.max(0.0, entry.value);
      if (roll <= 0.0) {
        return entry.key;
      }
    }
    return VictorySaluteType.bothHandsRaised;
  }

  /// Oblicza pełną pozę 3D dla danej klatki celebracji.
  VictorySalutePose3D evaluateFrame(VictorySaluteFrameInput input) {
    final double duration = math.max(0.5, config.durationSeconds);
    final double tSec = input.elapsedSeconds.clamp(0.0, duration);
    final double t = (tSec / duration).clamp(0.0, 1.0);
    final double fatigue = input.fatigueLevel.clamp(0.0, 1.0);

    // Płynny envelope wejścia i wyjścia (0..1..0)
    final double blendInRatio = (config.blendInSeconds / duration).clamp(
      0.05,
      0.4,
    );
    final double blendOutRatio = (config.blendOutSeconds / duration).clamp(
      0.05,
      0.4,
    );
    final double enterBlend = _smoothstep(0.0, blendInRatio, t);
    final double exitBlend = 1.0 - _smoothstep(1.0 - blendOutRatio, 1.0, t);
    final double envelope = (enterBlend * exitBlend).clamp(0.0, 1.0);

    // Błyski fotoreporterów nasilają się w środku strefy mety (0.25 .. 0.80)
    final double flashEnvelope =
        _smoothstep(0.15, 0.35, t) * (1.0 - _smoothstep(0.75, 0.98, t));
    final double flashPulse =
        0.5 + 0.5 * math.sin(t * math.pi * 18.0) * math.cos(t * math.pi * 7.0);
    final double photographerFlash = (flashEnvelope * flashPulse).clamp(
      0.0,
      1.0,
    );

    switch (input.saluteType) {
      case VictorySaluteType.bothHandsRaised:
        return _evaluateBothHandsRaised(
          input: input,
          t: t,
          envelope: envelope,
          flash: photographerFlash,
        );
      case VictorySaluteType.zipUpJersey:
        return _evaluateZipUpJersey(
          input: input,
          t: t,
          envelope: envelope,
          flash: photographerFlash,
        );
      case VictorySaluteType.pointAtSponsorLogo:
        return _evaluatePointAtSponsor(
          input: input,
          t: t,
          envelope: envelope,
          flash: photographerFlash,
        );
      case VictorySaluteType.fistBumpChest:
        return _evaluateFistBumpChest(
          input: input,
          t: t,
          envelope: envelope,
          flash: photographerFlash,
        );
      case VictorySaluteType.theatricalBow:
        return _evaluateTheatricalBow(
          input: input,
          t: t,
          envelope: envelope,
          flash: photographerFlash,
        );
      case VictorySaluteType.exhaustedHandlebarLean:
        return _evaluateExhaustedLean(
          input: input,
          t: t,
          tSec: tSec,
          envelope: envelope,
          fatigue: fatigue,
          flash: photographerFlash,
        );
    }
  }

  VictorySalutePose3D _evaluateBothHandsRaised({
    required VictorySaluteFrameInput input,
    required double t,
    required double envelope,
    required double flash,
  }) {
    final double torsoIncline = _lerp(36.0, 84.0, envelope);
    final double swayDeg = math.sin(t * math.pi * 2.0) * 4.0 * envelope;
    final double headPitch = _lerp(12.0, 32.0, envelope);

    final vm.Vector3 hip = _baseHip.clone();
    final vm.Vector3 chest = _computeChestFromTorso(
      hip: hip,
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: swayDeg,
    );
    final vm.Vector3 head = _computeHeadFromChest(
      chest: chest,
      torsoInclineDegrees: torsoIncline,
      headPitchDegrees: headPitch,
      headYawDegrees: swayDeg * 0.4,
    );

    final double armPulse = math.sin(t * math.pi * 4.0) * 0.03 * envelope;
    final vm.Vector3 targetRight = vm.Vector3(
      0.34 + armPulse,
      chest.y + 0.56,
      chest.z + 0.04,
    );
    final vm.Vector3 targetLeft = vm.Vector3(
      -0.34 - armPulse,
      chest.y + 0.56,
      chest.z + 0.04,
    );

    final vm.Vector3 rightHand = _lerpVec3(_hoodRight, targetRight, envelope);
    final vm.Vector3 leftHand = _lerpVec3(_hoodLeft, targetLeft, envelope);

    return _buildPose(
      input: input,
      t: t,
      phaseLabel: t < 0.2
          ? 'Oderwanie od kierownicy'
          : (t > 0.82 ? 'Powrót na klamki' : 'Pełny triumf (V-Pose)'),
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: swayDeg,
      headPitchDegrees: headPitch,
      headYawDegrees: 0.0,
      hip: hip,
      chest: chest,
      head: head,
      rightHand: rightHand,
      leftHand: leftHand,
      elbowOutwardBias: 0.14,
      rightFingerPointing: 0.0,
      rightFistClench: 0.35 * envelope,
      leftFistClench: 0.35 * envelope,
      jerseyZipper: 1.0,
      breathingAmplitude: 0.25,
      steeringStability: 1.0 - 0.65 * envelope,
      flash: flash,
      sponsorVisibility: 0.72 * envelope,
    );
  }

  VictorySalutePose3D _evaluateZipUpJersey({
    required VictorySaluteFrameInput input,
    required double t,
    required double envelope,
    required double flash,
  }) {
    final double torsoIncline = _lerp(36.0, 76.0, envelope);
    final double headPitch = _lerp(12.0, -6.0 * (1.0 - t) + 14.0 * t, envelope);

    final vm.Vector3 hip = _baseHip.clone();
    final vm.Vector3 chest = _computeChestFromTorso(
      hip: hip,
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: 0.0,
    );
    final vm.Vector3 head = _computeHeadFromChest(
      chest: chest,
      torsoInclineDegrees: torsoIncline,
      headPitchDegrees: headPitch,
      headYawDegrees: 0.0,
    );

    // Postęp zasuwania suwaka od mostka (0.0) pod szyję (1.0)
    final double zipProgress = _smoothstep(0.18, 0.75, t);
    final double releaseSpread = _smoothstep(0.75, 0.92, t);

    final double zipperY = _lerp(hip.y + 0.18, chest.y + 0.05, zipProgress);
    final double zipperZ = _lerp(hip.z + 0.09, chest.z + 0.10, zipProgress);

    final vm.Vector3 rightTarget = vm.Vector3(
      0.03 + releaseSpread * 0.20,
      zipperY + releaseSpread * 0.12,
      zipperZ + releaseSpread * 0.06,
    );
    final vm.Vector3 leftTarget = vm.Vector3(
      -0.05 - releaseSpread * 0.16,
      hip.y + 0.16 + zipProgress * 0.12,
      hip.z + 0.10,
    );

    final vm.Vector3 rightHand = _lerpVec3(_hoodRight, rightTarget, envelope);
    final vm.Vector3 leftHand = _lerpVec3(_hoodLeft, leftTarget, envelope);

    return _buildPose(
      input: input,
      t: t,
      phaseLabel: zipProgress < 0.95
          ? 'Zasuwanie zamka koszulki'
          : 'Prezentacja przed fotoreporterami',
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: 0.0,
      headPitchDegrees: headPitch,
      headYawDegrees: 0.0,
      hip: hip,
      chest: chest,
      head: head,
      rightHand: rightHand,
      leftHand: leftHand,
      elbowOutwardBias: 0.18,
      rightFingerPointing: 0.0,
      rightFistClench: 0.6 * (1.0 - releaseSpread) * envelope,
      leftFistClench: 0.4 * (1.0 - releaseSpread) * envelope,
      jerseyZipper: zipProgress,
      breathingAmplitude: 0.2,
      steeringStability: 1.0 - 0.58 * envelope,
      flash: flash,
      sponsorVisibility: (0.45 + 0.55 * zipProgress) * envelope,
    );
  }

  VictorySalutePose3D _evaluatePointAtSponsor({
    required VictorySaluteFrameInput input,
    required double t,
    required double envelope,
    required double flash,
  }) {
    final double torsoIncline = _lerp(36.0, 74.0, envelope);
    final double torsoTwist = -12.0 * envelope; // Lekki obrót klatki do kamer
    final double headPitch = _lerp(12.0, 14.0, envelope);
    final double headYaw = 8.0 * envelope;

    final vm.Vector3 hip = _baseHip.clone();
    final vm.Vector3 chest = _computeChestFromTorso(
      hip: hip,
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: torsoTwist,
    );
    final vm.Vector3 head = _computeHeadFromChest(
      chest: chest,
      torsoInclineDegrees: torsoIncline,
      headPitchDegrees: headPitch,
      headYawDegrees: headYaw,
    );

    // Prawa dłoń wskazuje palcem bezpośrednio na logo sponsora na środku klatki
    final double tapPulse = math.sin(t * math.pi * 6.0) * 0.025 * envelope;
    final vm.Vector3 rightTarget = vm.Vector3(
      0.04,
      chest.y - 0.05,
      chest.z + 0.12 + tapPulse,
    );
    // Lewa dłoń stabilizuje rower na klamkomanetce
    final vm.Vector3 leftHand = _hoodLeft.clone();
    final vm.Vector3 rightHand = _lerpVec3(_hoodRight, rightTarget, envelope);

    return _buildPose(
      input: input,
      t: t,
      phaseLabel: 'Wskazanie logotypu sponsora',
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: torsoTwist,
      headPitchDegrees: headPitch,
      headYawDegrees: headYaw,
      hip: hip,
      chest: chest,
      head: head,
      rightHand: rightHand,
      leftHand: leftHand,
      elbowOutwardBias: 0.22,
      rightFingerPointing: envelope,
      rightFistClench: 0.2 * envelope,
      leftFistClench: 0.5,
      jerseyZipper: 1.0,
      breathingAmplitude: 0.22,
      steeringStability: 1.0 - 0.22 * envelope,
      flash: flash,
      sponsorVisibility: 1.0 * envelope,
    );
  }

  VictorySalutePose3D _evaluateFistBumpChest({
    required VictorySaluteFrameInput input,
    required double t,
    required double envelope,
    required double flash,
  }) {
    final double torsoIncline = _lerp(36.0, 78.0, envelope);
    final double beatWave = math.max(0.0, math.sin(t * math.pi * 5.0));
    final double headPitch = _lerp(12.0, 22.0, envelope);

    final vm.Vector3 hip = _baseHip.clone();
    final vm.Vector3 chest = _computeChestFromTorso(
      hip: hip,
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: -6.0 * envelope,
    );
    final vm.Vector3 head = _computeHeadFromChest(
      chest: chest,
      torsoInclineDegrees: torsoIncline,
      headPitchDegrees: headPitch,
      headYawDegrees: 0.0,
    );

    // Prawa pięść wykonuje 2–3 dynamiczne uderzenia w mostek
    final vm.Vector3 rightTarget = vm.Vector3(
      0.02 + beatWave * 0.05,
      chest.y - 0.04 + beatWave * 0.03,
      chest.z + 0.07 + beatWave * 0.11,
    );
    // Lewa ręka na kierownicy albo lekko uniesiona przy finiszu
    final vm.Vector3 leftTarget = vm.Vector3(
      -0.22,
      _hoodLeft.y + 0.08 * envelope,
      _hoodLeft.z - 0.05 * envelope,
    );

    final vm.Vector3 rightHand = _lerpVec3(_hoodRight, rightTarget, envelope);
    final vm.Vector3 leftHand = _lerpVec3(_hoodLeft, leftTarget, envelope);

    return _buildPose(
      input: input,
      t: t,
      phaseLabel: beatWave > 0.5
          ? 'Uderzenie pięścią w serce'
          : 'Uniesienie zaciśniętej pięści',
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: -6.0 * envelope,
      headPitchDegrees: headPitch,
      headYawDegrees: 0.0,
      hip: hip,
      chest: chest,
      head: head,
      rightHand: rightHand,
      leftHand: leftHand,
      elbowOutwardBias: 0.24,
      rightFingerPointing: 0.0,
      rightFistClench: 1.0 * envelope,
      leftFistClench: 0.6 * envelope,
      jerseyZipper: 1.0,
      breathingAmplitude: 0.35,
      steeringStability: 1.0 - 0.35 * envelope,
      flash: flash,
      sponsorVisibility: 0.65 * envelope,
    );
  }

  VictorySalutePose3D _evaluateTheatricalBow({
    required VictorySaluteFrameInput input,
    required double t,
    required double envelope,
    required double flash,
  }) {
    // Najpierw wyprost, potem głęboki ukłon do 18° i powrót
    final double bowDepth = math.sin(t * math.pi).clamp(0.0, 1.0);
    final double torsoIncline = _lerp(36.0, 20.0, bowDepth * envelope);
    final double torsoTwist = 14.0 * bowDepth * envelope;
    final double headPitch = _lerp(12.0, -24.0, bowDepth * envelope);

    final vm.Vector3 hip = _baseHip.clone();
    final vm.Vector3 chest = _computeChestFromTorso(
      hip: hip,
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: torsoTwist,
    );
    final vm.Vector3 head = _computeHeadFromChest(
      chest: chest,
      torsoInclineDegrees: torsoIncline,
      headPitchDegrees: headPitch,
      headYawDegrees: 10.0 * bowDepth * envelope,
    );

    // Prawa ręka szeroko rozłożona w geście ukłonu, lewa przy klatce piersiowej
    final vm.Vector3 rightTarget = vm.Vector3(
      0.46,
      chest.y - 0.02,
      chest.z - 0.08,
    );
    final vm.Vector3 leftTarget = vm.Vector3(
      -0.04,
      chest.y - 0.07,
      chest.z + 0.08,
    );

    final vm.Vector3 rightHand = _lerpVec3(_hoodRight, rightTarget, envelope);
    final vm.Vector3 leftHand = _lerpVec3(_hoodLeft, leftTarget, envelope);

    return _buildPose(
      input: input,
      t: t,
      phaseLabel: bowDepth > 0.6
          ? 'Głęboki ukłon dla kibiców'
          : 'Gest zaproszenia na podium',
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: torsoTwist,
      headPitchDegrees: headPitch,
      headYawDegrees: 10.0 * bowDepth * envelope,
      hip: hip,
      chest: chest,
      head: head,
      rightHand: rightHand,
      leftHand: leftHand,
      elbowOutwardBias: 0.16,
      rightFingerPointing: 0.0,
      rightFistClench: 0.0,
      leftFistClench: 0.15 * envelope,
      jerseyZipper: 1.0,
      breathingAmplitude: 0.25,
      steeringStability: 1.0 - 0.62 * envelope,
      flash: flash,
      sponsorVisibility: 0.55 * envelope,
    );
  }

  VictorySalutePose3D _evaluateExhaustedLean({
    required VictorySaluteFrameInput input,
    required double t,
    required double tSec,
    required double envelope,
    required double fatigue,
    required double flash,
  }) {
    final double breathWave =
        0.5 + 0.5 * math.sin(tSec * config.exhaustionBreathHz * 2.0 * math.pi);
    final double breathOffset = breathWave * 0.025 * (0.4 + 0.6 * fatigue);

    // Zjazd głową i tułowiem nisko nad mostek kierownicy
    final double torsoIncline = _lerp(36.0, 14.0, envelope) + breathWave * 2.5;
    final double headPitch = _lerp(12.0, -34.0, envelope);

    final vm.Vector3 hip = vm.Vector3(
      0.0,
      _baseHip.y - 0.03 * envelope,
      _baseHip.z + 0.04 * envelope,
    );
    final vm.Vector3 chest = _computeChestFromTorso(
      hip: hip,
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: 0.0,
    );
    chest.y += breathOffset;

    final vm.Vector3 head = _computeHeadFromChest(
      chest: chest,
      torsoInclineDegrees: torsoIncline,
      headPitchDegrees: headPitch,
      headYawDegrees: 0.0,
    );

    // Dłonie zaciśnięte mocno na kierownicy/klamkach, łokcie szeroko i nisko
    final vm.Vector3 rightTarget = vm.Vector3(
      _hoodRight.x - 0.03,
      _hoodRight.y - 0.04,
      _hoodRight.z - 0.02,
    );
    final vm.Vector3 leftTarget = vm.Vector3(
      _hoodLeft.x + 0.03,
      _hoodLeft.y - 0.04,
      _hoodLeft.z - 0.02,
    );

    final vm.Vector3 rightHand = _lerpVec3(_hoodRight, rightTarget, envelope);
    final vm.Vector3 leftHand = _lerpVec3(_hoodLeft, leftTarget, envelope);

    return _buildPose(
      input: input,
      t: t,
      phaseLabel: 'Skrajne wyczerpanie na kierownicy',
      torsoInclineDegrees: torsoIncline,
      torsoTwistDegrees: 0.0,
      headPitchDegrees: headPitch,
      headYawDegrees: 0.0,
      hip: hip,
      chest: chest,
      head: head,
      rightHand: rightHand,
      leftHand: leftHand,
      elbowOutwardBias: 0.25,
      rightFingerPointing: 0.0,
      rightFistClench: 0.9,
      leftFistClench: 0.9,
      jerseyZipper: 0.4,
      breathingAmplitude: (0.65 + 0.35 * fatigue) * envelope,
      steeringStability: 1.0,
      flash: flash,
      sponsorVisibility: 0.35,
    );
  }

  VictorySalutePose3D _buildPose({
    required VictorySaluteFrameInput input,
    required double t,
    required String phaseLabel,
    required double torsoInclineDegrees,
    required double torsoTwistDegrees,
    required double headPitchDegrees,
    required double headYawDegrees,
    required vm.Vector3 hip,
    required vm.Vector3 chest,
    required vm.Vector3 head,
    required vm.Vector3 rightHand,
    required vm.Vector3 leftHand,
    required double elbowOutwardBias,
    required double rightFingerPointing,
    required double rightFistClench,
    required double leftFistClench,
    required double jerseyZipper,
    required double breathingAmplitude,
    required double steeringStability,
    required double flash,
    required double sponsorVisibility,
  }) {
    final vm.Vector3 rightShoulder = vm.Vector3(
      chest.x + 0.19,
      chest.y + 0.02,
      chest.z,
    );
    final vm.Vector3 leftShoulder = vm.Vector3(
      chest.x - 0.19,
      chest.y + 0.02,
      chest.z,
    );

    final vm.Vector3 rightElbow = _solveElbowPosition(
      shoulder: rightShoulder,
      hand: rightHand,
      outwardSign: 1.0,
      outwardBias: elbowOutwardBias,
    );
    final vm.Vector3 leftElbow = _solveElbowPosition(
      shoulder: leftShoulder,
      hand: leftHand,
      outwardSign: -1.0,
      outwardBias: elbowOutwardBias,
    );

    return VictorySalutePose3D(
      riderId: input.riderId,
      saluteType: input.saluteType,
      normalizedProgress: t,
      phaseLabel: phaseLabel,
      torsoInclineDegrees: torsoInclineDegrees,
      torsoTwistDegrees: torsoTwistDegrees,
      headPitchDegrees: headPitchDegrees,
      headYawDegrees: headYawDegrees,
      hipPosition: hip,
      chestPosition: chest,
      headPosition: head,
      rightElbowPosition: rightElbow,
      leftElbowPosition: leftElbow,
      rightHandPosition: rightHand,
      leftHandPosition: leftHand,
      rightFingerPointingFactor: rightFingerPointing.clamp(0.0, 1.0),
      rightFistClenchFactor: rightFistClench.clamp(0.0, 1.0),
      leftFistClenchFactor: leftFistClench.clamp(0.0, 1.0),
      jerseyZipperProgress: jerseyZipper.clamp(0.0, 1.0),
      breathingAmplitude: breathingAmplitude.clamp(0.0, 1.0),
      steeringStability: steeringStability.clamp(0.0, 1.0),
      photographerFlashIntensity: flash.clamp(0.0, 1.0),
      sponsorLogoVisibilityScore: sponsorVisibility.clamp(0.0, 1.0),
    );
  }

  vm.Vector3 _computeChestFromTorso({
    required vm.Vector3 hip,
    required double torsoInclineDegrees,
    required double torsoTwistDegrees,
  }) {
    final double rad = torsoInclineDegrees * math.pi / 180.0;
    final double twistRad = torsoTwistDegrees * math.pi / 180.0;
    final double forward = _torsoLengthMeters * math.cos(rad);
    final double up = _torsoLengthMeters * math.sin(rad);
    return vm.Vector3(
      hip.x + forward * math.sin(twistRad),
      hip.y + up,
      hip.z + forward * math.cos(twistRad),
    );
  }

  vm.Vector3 _computeHeadFromChest({
    required vm.Vector3 chest,
    required double torsoInclineDegrees,
    required double headPitchDegrees,
    required double headYawDegrees,
  }) {
    final double combinedRad =
        (torsoInclineDegrees + headPitchDegrees * 0.45) * math.pi / 180.0;
    final double yawRad = headYawDegrees * math.pi / 180.0;
    return vm.Vector3(
      chest.x + _neckToHeadMeters * 0.35 * math.sin(yawRad),
      chest.y + _neckToHeadMeters * math.sin(combinedRad).clamp(0.25, 1.0),
      chest.z + _neckToHeadMeters * math.cos(combinedRad) * 0.55,
    );
  }

  vm.Vector3 _solveElbowPosition({
    required vm.Vector3 shoulder,
    required vm.Vector3 hand,
    required double outwardSign,
    required double outwardBias,
  }) {
    final vm.Vector3 mid = (shoulder + hand) * 0.5;
    return vm.Vector3(
      mid.x + outwardSign * outwardBias,
      mid.y - 0.08,
      mid.z - 0.05,
    );
  }

  double _smoothstep(double edge0, double edge1, double x) {
    if (edge1 <= edge0) return x >= edge1 ? 1.0 : 0.0;
    final double t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  vm.Vector3 _lerpVec3(vm.Vector3 a, vm.Vector3 b, double t) => vm.Vector3(
    _lerp(a.x, b.x, t),
    _lerp(a.y, b.y, t),
    _lerp(a.z, b.z, t),
  );
}

/// Rzutnik 2D/3D prezentujący kolarza i rower podczas animacji zwycięstwa na mecie.
class VictorySaluteSilhouettePainter extends CustomPainter {
  final VictorySalutePose3D pose;

  const VictorySaluteSilhouettePainter({required this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Rect bgRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF131720), AppColors.background],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Błysk fleszy fotoreporterów w tle
    if (pose.photographerFlashIntensity > 0.05) {
      final Paint flashPaint = Paint()
        ..color = Colors.white.withValues(
          alpha: pose.photographerFlashIntensity * 0.16,
        );
      canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.25),
        size.width * 0.28,
        flashPaint,
      );
    }

    // Asfalt i linia mety
    final double groundY = size.height * 0.84;
    final Paint roadPaint = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(12, groundY),
      Offset(size.width - 12, groundY),
      roadPaint,
    );

    final Paint finishLinePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.85)
      ..strokeWidth = 3.0;
    canvas.drawLine(
      Offset(size.width * 0.64, groundY - 4),
      Offset(size.width * 0.64, groundY + 6),
      finishLinePaint,
    );

    // Skala i środek suportu roweru w układzie ekranu (Z -> prawo, Y -> góra)
    final double scale = math.min(size.width / 2.2, size.height / 2.05);
    final Offset bbOrigin = Offset(size.width * 0.44, groundY - 0.34 * scale);

    Offset project(vm.Vector3 v) {
      return Offset(
        bbOrigin.dx + (v.z + v.x * 0.28) * scale,
        bbOrigin.dy - v.y * scale,
      );
    }

    // Koła roweru
    final double wheelRadius = 0.34 * scale;
    final Offset rearWheel = Offset(bbOrigin.dx - 0.41 * scale, groundY - wheelRadius);
    final Offset frontWheel = Offset(bbOrigin.dx + 0.59 * scale, groundY - wheelRadius);

    final Paint wheelPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(rearWheel, wheelRadius, wheelPaint);
    canvas.drawCircle(frontWheel, wheelRadius, wheelPaint);

    // Rama roweru
    final Offset seatCluster = project(vm.Vector3(0.0, 0.56, -0.18));
    final Offset headTube = project(vm.Vector3(0.0, 0.58, 0.42));
    final Offset stemHood = project(vm.Vector3(0.0, 0.64, 0.55));
    final Paint framePaint = Paint()
      ..color = AppColors.primaryAccent
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(rearWheel, bbOrigin, framePaint);
    canvas.drawLine(rearWheel, seatCluster, framePaint);
    canvas.drawLine(bbOrigin, seatCluster, framePaint);
    canvas.drawLine(bbOrigin, headTube, framePaint);
    canvas.drawLine(seatCluster, headTube, framePaint);
    canvas.drawLine(headTube, frontWheel, framePaint);
    canvas.drawLine(headTube, stemHood, framePaint);

    // Kolarz — projekcja stawów
    final Offset hip = project(pose.hipPosition);
    final Offset chest = project(pose.chestPosition);
    final Offset head = project(pose.headPosition);
    final Offset rElbow = project(pose.rightElbowPosition);
    final Offset lElbow = project(pose.leftElbowPosition);
    final Offset rHand = project(pose.rightHandPosition);
    final Offset lHand = project(pose.leftHandPosition);

    // Nogi na pedałach
    final Offset rKnee = project(vm.Vector3(0.08, 0.36, 0.08));
    final Offset rPedal = project(vm.Vector3(0.08, 0.08, 0.14));
    final Paint legPaint = Paint()
      ..color = const Color(0xFF4B5563)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hip, rKnee, legPaint);
    canvas.drawLine(rKnee, rPedal, legPaint);

    // Lewa ręka (drugi plan)
    final Paint backArmPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.72)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(chest, lElbow, backArmPaint);
    canvas.drawLine(lElbow, lHand, backArmPaint);

    // Tułów
    final Paint torsoPaint = Paint()
      ..color = pose.saluteType.accentColor
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hip, chest, torsoPaint);

    // Prawa ręka (pierwszy plan)
    final Paint frontArmPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(chest, rElbow, frontArmPaint);
    canvas.drawLine(rElbow, rHand, frontArmPaint);

    // Głowa i kask
    canvas.drawCircle(
      head,
      8.0,
      Paint()..color = AppColors.textPrimary,
    );
    canvas.drawArc(
      Rect.fromCircle(center: head.translate(0, -2), radius: 9.0),
      math.pi,
      math.pi,
      true,
      Paint()..color = AppColors.goldAccent,
    );

    // Akcenty dłoni (pięść lub wskazanie palcem)
    canvas.drawCircle(
      rHand,
      pose.rightFistClenchFactor > 0.7 ? 4.8 : 3.5,
      Paint()
        ..color = pose.rightFingerPointingFactor > 0.5
            ? AppColors.cyanAccent
            : AppColors.goldAccent,
    );
    canvas.drawCircle(
      lHand,
      3.5,
      Paint()..color = AppColors.textSecondary,
    );
  }

  @override
  bool shouldRepaint(covariant VictorySaluteSilhouettePainter oldDelegate) {
    return oldDelegate.pose != pose;
  }
}

/// Interaktywny panel podglądu i sterowania 6 animacjami zwycięstwa na mecie.
class VictorySaluteCelebrationPanel extends StatefulWidget {
  final VictorySaluteType initialSaluteType;
  final ValueChanged<VictorySaluteType>? onSaluteSelected;
  final bool enabled;

  const VictorySaluteCelebrationPanel({
    super.key,
    this.initialSaluteType = VictorySaluteType.bothHandsRaised,
    this.onSaluteSelected,
    this.enabled = true,
  });

  @override
  State<VictorySaluteCelebrationPanel> createState() =>
      _VictorySaluteCelebrationPanelState();
}

class _VictorySaluteCelebrationPanelState
    extends State<VictorySaluteCelebrationPanel>
    with SingleTickerProviderStateMixin {
  final VictorySaluteCelebrationAnimator _animator =
      const VictorySaluteCelebrationAnimator();
  late AnimationController _controller;
  late VictorySaluteType _selectedType;
  bool _isPlaying = true;
  double _fatigueLevel = 0.45;
  double _gradientPercent = 2.0;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSaluteType;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (_animator.config.durationSeconds * 1000).round(),
      ),
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectType(VictorySaluteType type) {
    if (!widget.enabled) return;
    setState(() {
      _selectedType = type;
      if (_isPlaying) {
        _controller.forward(from: 0.0).whenComplete(() {
          if (mounted && _isPlaying && widget.enabled) {
            _controller.repeat();
          }
        });
      }
    });
    widget.onSaluteSelected?.call(type);
  }

  void _togglePlayback() {
    if (!widget.enabled) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _autoSelectFromContext() {
    if (!widget.enabled) return;
    final VictorySaluteType recommended = _animator.selectCelebration(
      VictorySaluteContext(
        riderId: 'preview_leader',
        finishGradientPercent: _gradientPercent,
        fatigueLevel: _fatigueLevel,
        isSoloBreakaway: _gradientPercent < 4.0 && _fatigueLevel < 0.55,
        isPhotoFinishSprint: _gradientPercent < 2.0 && _fatigueLevel >= 0.55,
        sponsorImportance: 0.75,
        showmanship: 0.7,
      ),
      seed: (_fatigueLevel * 100 + _gradientPercent * 10).round(),
    );
    _selectType(recommended);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 560;

        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              final double elapsed =
                  _controller.value * _animator.config.durationSeconds;
              final VictorySalutePose3D pose = _animator.evaluateFrame(
                VictorySaluteFrameInput(
                  riderId: 'preview_leader',
                  saluteType: _selectedType,
                  elapsedSeconds: elapsed,
                  gradientPercent: _gradientPercent,
                  fatigueLevel: _fatigueLevel,
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildHeader(pose, isCompact),
                  const SizedBox(height: 12),
                  if (isCompact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildViewport(pose, height: 185),
                        const SizedBox(height: 12),
                        _buildTelemetryStrip(pose, isCompact: true),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 6,
                          child: _buildViewport(pose, height: 220),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 5,
                          child: _buildTelemetryStrip(pose, isCompact: false),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  _buildPresetSelector(isCompact),
                  const SizedBox(height: 12),
                  _buildControlsRow(isCompact),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(VictorySalutePose3D pose, bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isCompact ? 340 : 420),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                _selectedType.icon,
                color: _selectedType.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Celebracje Zwycięstwa 3D',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: isCompact ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _selectedType.accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selectedType.accentColor.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Text(
            pose.phaseLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _selectedType.accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewport(VictorySalutePose3D pose, {required double height}) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: CustomPaint(
        painter: VictorySaluteSilhouettePainter(pose: pose),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildTelemetryStrip(
    VictorySalutePose3D pose, {
    required bool isCompact,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _selectedType.description,
            maxLines: isCompact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          _TelemetryBarRow(
            label: 'Kąt tułowia',
            valueText: '${pose.torsoInclineDegrees.toStringAsFixed(1)}°',
            progress: (pose.torsoInclineDegrees / 90.0).clamp(0.0, 1.0),
            color: AppColors.goldAccent,
          ),
          const SizedBox(height: 6),
          _TelemetryBarRow(
            label: 'Ekspozycja sponsora',
            valueText:
                '${(pose.sponsorLogoVisibilityScore * 100).round()}%',
            progress: pose.sponsorLogoVisibilityScore,
            color: AppColors.cyanAccent,
          ),
          const SizedBox(height: 6),
          _TelemetryBarRow(
            label: 'Stabilność roweru',
            valueText: '${(pose.steeringStability * 100).round()}%',
            progress: pose.steeringStability,
            color: AppColors.statusSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VictorySaluteType.values.map((VictorySaluteType type) {
        final bool isSelected = type == _selectedType;
        return _InteractiveSaluteChip(
          label: isCompact ? type.shortLabel : type.label,
          icon: type.icon,
          accentColor: type.accentColor,
          isSelected: isSelected,
          enabled: widget.enabled,
          onTap: () => _selectType(type),
        );
      }).toList(),
    );
  }

  Widget _buildControlsRow(bool isCompact) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _InteractiveActionButton(
              icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: _isPlaying ? 'Pauza' : 'Odtwórz',
              enabled: widget.enabled,
              onPressed: _togglePlayback,
            ),
            _InteractiveActionButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Dobierz z kontekstu',
              enabled: widget.enabled,
              isPrimary: true,
              onPressed: _autoSelectFromContext,
            ),
          ],
        ),
        SizedBox(
          width: isCompact ? double.infinity : 260,
          child: Row(
            children: <Widget>[
              const Text(
                'Zmęczenie',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _fatigueLevel,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.goldAccent,
                  inactiveColor: AppTheme.borderColor,
                  onChanged: widget.enabled
                      ? (double v) => setState(() => _fatigueLevel = v)
                      : null,
                ),
              ),
              Text(
                '${(_fatigueLevel * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: isCompact ? double.infinity : 240,
          child: Row(
            children: <Widget>[
              const Text(
                'Nachylenie',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _gradientPercent,
                  min: -2.0,
                  max: 14.0,
                  activeColor: AppColors.primaryAccent,
                  inactiveColor: AppTheme.borderColor,
                  onChanged: widget.enabled
                      ? (double v) => setState(() => _gradientPercent = v)
                      : null,
                ),
              ),
              Text(
                '${_gradientPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TelemetryBarRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double progress;
  final Color color;

  const _TelemetryBarRow({
    required this.label,
    required this.valueText,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _InteractiveSaluteChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _InteractiveSaluteChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_InteractiveSaluteChip> createState() => _InteractiveSaluteChipState();
}

class _InteractiveSaluteChipState extends State<_InteractiveSaluteChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled;
    final Color bgColor = !active
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isSelected
        ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.20)
        : _hovered
        ? AppColors.surfaceLight
        : AppColors.background;

    final Color borderColor = !active
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
        ? AppColors.goldAccent
        : widget.isSelected
        ? widget.accentColor
        : _hovered
        ? widget.accentColor.withValues(alpha: 0.55)
        : AppTheme.borderColor;

    final Color fgColor = !active
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.isSelected
        ? widget.accentColor
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused || widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(widget.icon, size: 15, color: fgColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isPrimary = false,
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
    final bool active = widget.enabled;
    final Color baseAccent =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final Color bgColor = !active
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
        ? baseAccent.withValues(alpha: 0.85)
        : _hovered
        ? (widget.isPrimary
              ? AppColors.primaryAccent.withValues(alpha: 0.92)
              : AppColors.cardBorder)
        : baseAccent;

    final Color borderColor = !active
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
        ? AppColors.goldAccent
        : AppTheme.borderColor;

    final Color fgColor = !active
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
