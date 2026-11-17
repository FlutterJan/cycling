// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'key_moments_detector.dart';

// ============================================================================
// 1. ENUMERACJE I KATEGORIE ALBUMU ZDJĘĆ ETAPOWYCH
// ============================================================================

/// Cztery główne rozdziały narracyjne etapu, do których przypisywane są zdjęcia.
enum StagePhotoSlotCategory {
  /// Rozdział 1: Start ostry, formowanie ucieczki dnia lub pierwsze ranty.
  earlyBreakawayOrRollout,

  /// Rozdział 2: Kluczowa trudność terenowa (podjazd HC/Cat 1, sektor brukowy).
  crucialClimbOrCobbles,

  /// Rozdział 3: Dramat na trasie (atak faworyta GC, kraksa, defekt, wiatr).
  dramaOrIncident,

  /// Rozdział 4: Finałowe kilometry, sprint na kreskę i ceremonia na mecie.
  finaleAndFinishLine;

  String toJson() => name;

  static StagePhotoSlotCategory fromJson(String value) {
    return StagePhotoSlotCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StagePhotoSlotCategory.finaleAndFinishLine,
    );
  }

  String get label {
    switch (this) {
      case StagePhotoSlotCategory.earlyBreakawayOrRollout:
        return 'Ucieczka dnia';
      case StagePhotoSlotCategory.crucialClimbOrCobbles:
        return 'Kluczowy teren';
      case StagePhotoSlotCategory.dramaOrIncident:
        return 'Dramat na trasie';
      case StagePhotoSlotCategory.finaleAndFinishLine:
        return 'Finał i meta';
    }
  }
}

/// Szczegółowy typ uwiecznionego zdarzenia fotograficznego.
enum StagePhotoMomentKind {
  breakawayAttack,
  cobbleSectorBattle,
  crosswindEchelon,
  gcSummitAttack,
  decisiveMountainClimb,
  crashOrMechanicalDrama,
  final5KmChase,
  sprintPhotoFinish,
  soloStageVictory;

  String toJson() => name;

  static StagePhotoMomentKind fromJson(String value) {
    return StagePhotoMomentKind.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StagePhotoMomentKind.soloStageVictory,
    );
  }

  String get badgeLabel {
    switch (this) {
      case StagePhotoMomentKind.breakawayAttack:
        return 'ODJAZD';
      case StagePhotoMomentKind.cobbleSectorBattle:
        return 'BRUK';
      case StagePhotoMomentKind.crosswindEchelon:
        return 'RANTY';
      case StagePhotoMomentKind.gcSummitAttack:
        return 'ATAK GC';
      case StagePhotoMomentKind.decisiveMountainClimb:
        return 'PODJAZD';
      case StagePhotoMomentKind.crashOrMechanicalDrama:
        return 'INCYDENT';
      case StagePhotoMomentKind.final5KmChase:
        return 'FINAŁ 5 KM';
      case StagePhotoMomentKind.sprintPhotoFinish:
        return 'FOTOFINISZ';
      case StagePhotoMomentKind.soloStageVictory:
        return 'ZWYCIĘSTWO';
    }
  }

  StagePhotoSlotCategory get defaultSlot {
    switch (this) {
      case StagePhotoMomentKind.breakawayAttack:
        return StagePhotoSlotCategory.earlyBreakawayOrRollout;
      case StagePhotoMomentKind.cobbleSectorBattle:
      case StagePhotoMomentKind.decisiveMountainClimb:
        return StagePhotoSlotCategory.crucialClimbOrCobbles;
      case StagePhotoMomentKind.crosswindEchelon:
      case StagePhotoMomentKind.gcSummitAttack:
      case StagePhotoMomentKind.crashOrMechanicalDrama:
        return StagePhotoSlotCategory.dramaOrIncident;
      case StagePhotoMomentKind.final5KmChase:
      case StagePhotoMomentKind.sprintPhotoFinish:
      case StagePhotoMomentKind.soloStageVictory:
        return StagePhotoSlotCategory.finaleAndFinishLine;
    }
  }
}

/// Preset kamery wyścigowej wykorzystanej do wykonania zdjęcia.
enum StagePhotoCameraPreset {
  helicopterWide,
  motoFollowLow,
  staticClimbCorner,
  finishLineTelephoto,
  cobbleRoadsidePan,
  pelotonCockpit;

  String toJson() => name;

  static StagePhotoCameraPreset fromJson(String value) {
    return StagePhotoCameraPreset.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StagePhotoCameraPreset.motoFollowLow,
    );
  }

  String get photographerCredit {
    switch (this) {
      case StagePhotoCameraPreset.helicopterWide:
        return 'Helikopter Cineflex';
      case StagePhotoCameraPreset.motoFollowLow:
        return 'Motocykl TV #1';
      case StagePhotoCameraPreset.staticClimbCorner:
        return 'Fotoreporter Przełęczy';
      case StagePhotoCameraPreset.finishLineTelephoto:
        return 'Boks Fotoreporterów Mety';
      case StagePhotoCameraPreset.cobbleRoadsidePan:
        return 'Kamera Pobocza Bruku';
      case StagePhotoCameraPreset.pelotonCockpit:
        return 'Kamera Pokładowa';
    }
  }
}

/// Pora dnia / oświetlenie sceny na zdjęciu.
enum StagePhotoLightingMood {
  morningMist,
  crispDaylight,
  overcastStorm,
  goldenHour,
  twilightFloodlights;

  String toJson() => name;

  static StagePhotoLightingMood fromJson(String value) {
    return StagePhotoLightingMood.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StagePhotoLightingMood.crispDaylight,
    );
  }
}

// ============================================================================
// 2. MODELE DANYCH ZDJĘCIA, TELEMETRII I ALBUMU
// ============================================================================

/// Dane kolarza uchwyconego w kadrze zdjęcia.
class StagePhotoRiderSubject {
  final String riderId;
  final String riderName;
  final String teamName;
  final int jerseyColorArgb;
  final bool isPlayerTeam;
  final int powerWatts;
  final double speedKmh;
  final int heartRateBpm;
  final int positionInStage;
  final double gapSeconds;

  const StagePhotoRiderSubject({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.jerseyColorArgb,
    required this.isPlayerTeam,
    required this.powerWatts,
    required this.speedKmh,
    required this.heartRateBpm,
    required this.positionInStage,
    required this.gapSeconds,
  });

  Color get jerseyColor => Color(jerseyColorArgb);

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamName': teamName,
        'jerseyColorArgb': jerseyColorArgb,
        'isPlayerTeam': isPlayerTeam,
        'powerWatts': powerWatts,
        'speedKmh': speedKmh,
        'heartRateBpm': heartRateBpm,
        'positionInStage': positionInStage,
        'gapSeconds': gapSeconds,
      };

  factory StagePhotoRiderSubject.fromJson(Map<String, dynamic> json) {
    return StagePhotoRiderSubject(
      riderId: json['riderId'] as String? ?? 'unknown',
      riderName: json['riderName'] as String? ?? 'Nieznany Kolarz',
      teamName: json['teamName'] as String? ?? 'Peleton',
      jerseyColorArgb: (json['jerseyColorArgb'] as num?)?.toInt() ?? 0xFF38BDF8,
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      powerWatts: (json['powerWatts'] as num?)?.toInt() ?? 0,
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 0.0,
      heartRateBpm: (json['heartRateBpm'] as num?)?.toInt() ?? 0,
      positionInStage: (json['positionInStage'] as num?)?.toInt() ?? 1,
      gapSeconds: (json['gapSeconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Kontekst środowiskowy i terenowy w momencie wykonania zdjęcia.
class StagePhotoEnvironmentContext {
  final double gradientPercent;
  final double elevationMeters;
  final double temperatureCelsius;
  final double windSpeedKmh;
  final String precipitationLabel;
  final String roadSurfaceLabel;
  final StagePhotoLightingMood lightingMood;
  final bool hasCobbles;
  final bool hasRain;

  const StagePhotoEnvironmentContext({
    this.gradientPercent = 0.0,
    this.elevationMeters = 120.0,
    this.temperatureCelsius = 21.0,
    this.windSpeedKmh = 12.0,
    this.precipitationLabel = 'Bez opadów',
    this.roadSurfaceLabel = 'Suchy asfalt',
    this.lightingMood = StagePhotoLightingMood.crispDaylight,
    this.hasCobbles = false,
    this.hasRain = false,
  });

  Map<String, dynamic> toJson() => {
        'gradientPercent': gradientPercent,
        'elevationMeters': elevationMeters,
        'temperatureCelsius': temperatureCelsius,
        'windSpeedKmh': windSpeedKmh,
        'precipitationLabel': precipitationLabel,
        'roadSurfaceLabel': roadSurfaceLabel,
        'lightingMood': lightingMood.toJson(),
        'hasCobbles': hasCobbles,
        'hasRain': hasRain,
      };

  factory StagePhotoEnvironmentContext.fromJson(Map<String, dynamic> json) {
    return StagePhotoEnvironmentContext(
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      elevationMeters: (json['elevationMeters'] as num?)?.toDouble() ?? 120.0,
      temperatureCelsius:
          (json['temperatureCelsius'] as num?)?.toDouble() ?? 21.0,
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 12.0,
      precipitationLabel:
          json['precipitationLabel'] as String? ?? 'Bez opadów',
      roadSurfaceLabel: json['roadSurfaceLabel'] as String? ?? 'Suchy asfalt',
      lightingMood: StagePhotoLightingMood.fromJson(
        json['lightingMood'] as String? ?? 'crispDaylight',
      ),
      hasCobbles: json['hasCobbles'] as bool? ?? false,
      hasRain: json['hasRain'] as bool? ?? false,
    );
  }
}

/// Parametry optyczne i ustawienie kamery (EXIF) dla ujęcia.
class StagePhotoCameraSpec {
  final StagePhotoCameraPreset preset;
  final int focalLengthMm;
  final String shutterSpeedLabel;
  final String apertureLabel;
  final int isoValue;
  final double cameraYawDeg;
  final double cameraPitchDeg;

  const StagePhotoCameraSpec({
    required this.preset,
    required this.focalLengthMm,
    required this.shutterSpeedLabel,
    required this.apertureLabel,
    required this.isoValue,
    required this.cameraYawDeg,
    required this.cameraPitchDeg,
  });

  String get exifSummary =>
      '${focalLengthMm}mm • $apertureLabel • $shutterSpeedLabel • ISO $isoValue';

  Map<String, dynamic> toJson() => {
        'preset': preset.toJson(),
        'focalLengthMm': focalLengthMm,
        'shutterSpeedLabel': shutterSpeedLabel,
        'apertureLabel': apertureLabel,
        'isoValue': isoValue,
        'cameraYawDeg': cameraYawDeg,
        'cameraPitchDeg': cameraPitchDeg,
      };

  factory StagePhotoCameraSpec.fromJson(Map<String, dynamic> json) {
    return StagePhotoCameraSpec(
      preset: StagePhotoCameraPreset.fromJson(
        json['preset'] as String? ?? 'motoFollowLow',
      ),
      focalLengthMm: (json['focalLengthMm'] as num?)?.toInt() ?? 50,
      shutterSpeedLabel: json['shutterSpeedLabel'] as String? ?? '1/1600s',
      apertureLabel: json['apertureLabel'] as String? ?? 'f/2.8',
      isoValue: (json['isoValue'] as num?)?.toInt() ?? 400,
      cameraYawDeg: (json['cameraYawDeg'] as num?)?.toDouble() ?? 15.0,
      cameraPitchDeg: (json['cameraPitchDeg'] as num?)?.toDouble() ?? -6.0,
    );
  }
}

/// Pojedyncze automatycznie zapisane zdjęcie z kluczowego momentu etapu.
class StagePhotoSnapshot {
  final String photoId;
  final String stageId;
  final int stageNumber;
  final StagePhotoSlotCategory slotCategory;
  final StagePhotoMomentKind momentKind;
  final KeyMomentType? sourceKeyMomentType;
  final double kilometerMark;
  final double remainingKm;
  final double elapsedSeconds;
  final String title;
  final String editorialCaption;
  final double dramaScore;
  final bool isFeaturedCover;
  final int visualSeed;
  final StagePhotoCameraSpec cameraSpec;
  final StagePhotoEnvironmentContext environment;
  final List<StagePhotoRiderSubject> subjects;

  const StagePhotoSnapshot({
    required this.photoId,
    required this.stageId,
    required this.stageNumber,
    required this.slotCategory,
    required this.momentKind,
    this.sourceKeyMomentType,
    required this.kilometerMark,
    required this.remainingKm,
    required this.elapsedSeconds,
    required this.title,
    required this.editorialCaption,
    required this.dramaScore,
    this.isFeaturedCover = false,
    required this.visualSeed,
    required this.cameraSpec,
    required this.environment,
    this.subjects = const [],
  });

  StagePhotoSnapshot copyWith({
    bool? isFeaturedCover,
    StagePhotoSlotCategory? slotCategory,
    double? dramaScore,
  }) {
    return StagePhotoSnapshot(
      photoId: photoId,
      stageId: stageId,
      stageNumber: stageNumber,
      slotCategory: slotCategory ?? this.slotCategory,
      momentKind: momentKind,
      sourceKeyMomentType: sourceKeyMomentType,
      kilometerMark: kilometerMark,
      remainingKm: remainingKm,
      elapsedSeconds: elapsedSeconds,
      title: title,
      editorialCaption: editorialCaption,
      dramaScore: dramaScore ?? this.dramaScore,
      isFeaturedCover: isFeaturedCover ?? this.isFeaturedCover,
      visualSeed: visualSeed,
      cameraSpec: cameraSpec,
      environment: environment,
      subjects: subjects,
    );
  }

  String get formattedClockTime {
    final total = elapsedSeconds.round().clamp(0, 86400);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  Map<String, dynamic> toJson() => {
        'photoId': photoId,
        'stageId': stageId,
        'stageNumber': stageNumber,
        'slotCategory': slotCategory.toJson(),
        'momentKind': momentKind.toJson(),
        'sourceKeyMomentType': sourceKeyMomentType?.toJson(),
        'kilometerMark': kilometerMark,
        'remainingKm': remainingKm,
        'elapsedSeconds': elapsedSeconds,
        'title': title,
        'editorialCaption': editorialCaption,
        'dramaScore': dramaScore,
        'isFeaturedCover': isFeaturedCover,
        'visualSeed': visualSeed,
        'cameraSpec': cameraSpec.toJson(),
        'environment': environment.toJson(),
        'subjects': subjects.map((s) => s.toJson()).toList(),
      };

  factory StagePhotoSnapshot.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'] as List<dynamic>? ?? const [];
    final rawKeyMoment = json['sourceKeyMomentType'] as String?;
    return StagePhotoSnapshot(
      photoId: json['photoId'] as String? ?? 'photo_0',
      stageId: json['stageId'] as String? ?? 'stage_1',
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      slotCategory: StagePhotoSlotCategory.fromJson(
        json['slotCategory'] as String? ?? 'finaleAndFinishLine',
      ),
      momentKind: StagePhotoMomentKind.fromJson(
        json['momentKind'] as String? ?? 'soloStageVictory',
      ),
      sourceKeyMomentType: rawKeyMoment != null
          ? KeyMomentType.fromJson(rawKeyMoment)
          : null,
      kilometerMark: (json['kilometerMark'] as num?)?.toDouble() ?? 0.0,
      remainingKm: (json['remainingKm'] as num?)?.toDouble() ?? 0.0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toDouble() ?? 0.0,
      title: json['title'] as String? ?? 'Kadr z etapu',
      editorialCaption: json['editorialCaption'] as String? ?? '',
      dramaScore: (json['dramaScore'] as num?)?.toDouble() ?? 50.0,
      isFeaturedCover: json['isFeaturedCover'] as bool? ?? false,
      visualSeed: (json['visualSeed'] as num?)?.toInt() ?? 1,
      cameraSpec: StagePhotoCameraSpec.fromJson(
        json['cameraSpec'] as Map<String, dynamic>? ?? const {},
      ),
      environment: StagePhotoEnvironmentContext.fromJson(
        json['environment'] as Map<String, dynamic>? ?? const {},
      ),
      subjects: rawSubjects
          .whereType<Map<String, dynamic>>()
          .map(StagePhotoRiderSubject.fromJson)
          .toList(),
    );
  }
}

/// Gotowy album maksymalnie 4 kluczowych zdjęć z pojedynczego etapu.
class StagePhotoAlbum {
  final String stageId;
  final String stageName;
  final int stageNumber;
  final double totalDistanceKm;
  final int maxPhotos;
  final List<StagePhotoSnapshot> photos;
  final int totalMomentsEvaluated;
  final bool isFinalized;

  const StagePhotoAlbum({
    required this.stageId,
    required this.stageName,
    required this.stageNumber,
    required this.totalDistanceKm,
    this.maxPhotos = 4,
    required this.photos,
    this.totalMomentsEvaluated = 0,
    this.isFinalized = false,
  });

  StagePhotoSnapshot? get coverPhoto {
    if (photos.isEmpty) return null;
    for (final p in photos) {
      if (p.isFeaturedCover) return p;
    }
    return photos.first;
  }

  Map<String, dynamic> toJson() => {
        'stageId': stageId,
        'stageName': stageName,
        'stageNumber': stageNumber,
        'totalDistanceKm': totalDistanceKm,
        'maxPhotos': maxPhotos,
        'photos': photos.map((p) => p.toJson()).toList(),
        'totalMomentsEvaluated': totalMomentsEvaluated,
        'isFinalized': isFinalized,
      };

  factory StagePhotoAlbum.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List<dynamic>? ?? const [];
    return StagePhotoAlbum(
      stageId: json['stageId'] as String? ?? 'stage_1',
      stageName: json['stageName'] as String? ?? 'Etap 1',
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 150.0,
      maxPhotos: (json['maxPhotos'] as num?)?.toInt() ?? 4,
      photos: rawPhotos
          .whereType<Map<String, dynamic>>()
          .map(StagePhotoSnapshot.fromJson)
          .toList(),
      totalMomentsEvaluated:
          (json['totalMomentsEvaluated'] as num?)?.toInt() ?? 0,
      isFinalized: json['isFinalized'] as bool? ?? false,
    );
  }
}

// ============================================================================
// 3. SILNIK AUTOMATYCZNEGO PRZECHWYTYWANIA ALBUMU ZDJĘĆ
// ============================================================================

/// Silnik automatycznie wykrywający, punktujący i selekcjonujący 4 najlepsze
/// zdjęcia z kluczowych momentów każdego etapu.
class StagePhotoAlbumAutoCapturer {
  static const int defaultMaxPhotosPerStage = 4;
  static const double _dedupeDistanceWindowKm = 2.5;
  static const double _dedupeTimeWindowSeconds = 90.0;

  String _stageId = 'stage_1';
  String _stageName = 'Etap 1';
  int _stageNumber = 1;
  double _totalDistanceKm = 180.0;
  int _maxPhotos = defaultMaxPhotosPerStage;
  bool _isFinalized = false;
  int _sequenceCounter = 0;

  final List<StagePhotoSnapshot> _candidates = [];

  bool get isFinalized => _isFinalized;
  List<StagePhotoSnapshot> get candidatePhotos =>
      List<StagePhotoSnapshot>.unmodifiable(_candidates);

  /// Rozpoczyna nową sesję przechwytywania zdjęć dla etapu.
  void startStageCapture({
    required String stageId,
    required String stageName,
    required int stageNumber,
    required double totalDistanceKm,
    int maxPhotos = defaultMaxPhotosPerStage,
  }) {
    _stageId = stageId;
    _stageName = stageName;
    _stageNumber = stageNumber;
    _totalDistanceKm = totalDistanceKm.clamp(1.0, 500.0);
    _maxPhotos = maxPhotos.clamp(1, 12);
    _isFinalized = false;
    _sequenceCounter = 0;
    _candidates.clear();
  }

  /// Przechwytuje zdarzenie z [KeyMomentsDetector] i ocenia je jako kandydata do albumu.
  StagePhotoSnapshot? evaluateKeyMomentTrigger(
    KeyMomentTrigger trigger, {
    required double elapsedSeconds,
    required StagePhotoEnvironmentContext context,
    List<StagePhotoRiderSubject> subjects = const [],
  }) {
    final kind = _mapKeyMomentToPhotoKind(trigger.type);
    final slot = _mapKeyMomentToSlot(trigger.type);
    return _recordCandidate(
      kind: kind,
      slot: slot,
      sourceKeyMomentType: trigger.type,
      kilometerMark: trigger.kilometerMark,
      elapsedSeconds: elapsedSeconds,
      title: trigger.title,
      caption: trigger.description,
      context: context,
      subjects: subjects,
      recommendedCamera: trigger.recommendedCameraMode,
    );
  }

  /// Ręczne lub zdarzeniowe zgłoszenie momentu (np. fotofinisz, samotny wjazd na metę).
  StagePhotoSnapshot? captureCustomMoment({
    required StagePhotoMomentKind kind,
    required double kilometerMark,
    required double elapsedSeconds,
    required String title,
    required String caption,
    required StagePhotoEnvironmentContext context,
    List<StagePhotoRiderSubject> subjects = const [],
    StagePhotoSlotCategory? slotOverride,
    double? customDramaScore,
  }) {
    return _recordCandidate(
      kind: kind,
      slot: slotOverride ?? kind.defaultSlot,
      sourceKeyMomentType: null,
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      title: title,
      caption: caption,
      context: context,
      subjects: subjects,
      customDramaScore: customDramaScore,
    );
  }

  StagePhotoSnapshot? _recordCandidate({
    required StagePhotoMomentKind kind,
    required StagePhotoSlotCategory slot,
    required KeyMomentType? sourceKeyMomentType,
    required double kilometerMark,
    required double elapsedSeconds,
    required String title,
    required String caption,
    required StagePhotoEnvironmentContext context,
    required List<StagePhotoRiderSubject> subjects,
    String? recommendedCamera,
    double? customDramaScore,
  }) {
    if (_isFinalized) return null;

    final clampedKm = kilometerMark.clamp(0.0, _totalDistanceKm);
    final remainingKm = math.max(0.0, _totalDistanceKm - clampedKm);
    final drama = (customDramaScore ??
            _computeDramaScore(
              kind: kind,
              remainingKm: remainingKm,
              context: context,
              subjects: subjects,
            ))
        .clamp(0.0, 100.0);

    // Zapobiegaj dublowaniu kadrów w tym samym oknie dystansu i czasu,
    // chyba że nowy moment ma wyraźnie wyższą dramaturgię.
    final duplicateIndex = _candidates.indexWhere(
      (existing) =>
          existing.momentKind == kind &&
          (existing.kilometerMark - clampedKm).abs() <
              _dedupeDistanceWindowKm &&
          (existing.elapsedSeconds - elapsedSeconds).abs() <
              _dedupeTimeWindowSeconds,
    );

    if (duplicateIndex >= 0) {
      if (_candidates[duplicateIndex].dramaScore >= drama) {
        return null;
      }
      _candidates.removeAt(duplicateIndex);
    }

    _sequenceCounter++;
    final cameraSpec = _buildCameraSpec(
      kind: kind,
      recommendedCamera: recommendedCamera,
      context: context,
      seed: _sequenceCounter,
    );

    final snapshot = StagePhotoSnapshot(
      photoId: '${_stageId}_photo_$_sequenceCounter',
      stageId: _stageId,
      stageNumber: _stageNumber,
      slotCategory: slot,
      momentKind: kind,
      sourceKeyMomentType: sourceKeyMomentType,
      kilometerMark: clampedKm,
      remainingKm: remainingKm,
      elapsedSeconds: math.max(0.0, elapsedSeconds),
      title: title,
      editorialCaption: caption,
      dramaScore: drama,
      visualSeed: _computeVisualSeed(_stageId, _sequenceCounter, clampedKm),
      cameraSpec: cameraSpec,
      environment: context,
      subjects: List<StagePhotoRiderSubject>.unmodifiable(subjects),
    );

    _candidates.add(snapshot);
    return snapshot;
  }

  /// Zwraca aktualny podgląd wybranych do tej pory 4 najlepszych zdjęć.
  StagePhotoAlbum buildCurrentAlbumPreview() {
    final curated = _selectCuratedPhotos();
    return StagePhotoAlbum(
      stageId: _stageId,
      stageName: _stageName,
      stageNumber: _stageNumber,
      totalDistanceKm: _totalDistanceKm,
      maxPhotos: _maxPhotos,
      photos: curated,
      totalMomentsEvaluated: _candidates.length,
      isFinalized: _isFinalized,
    );
  }

  /// Finalizuje album po przekroczeniu linii mety, gwarantując kadr finałowy
  /// oraz wybierając 4 najbardziej ikoniczne ujęcia w porządku chronologicznym.
  StagePhotoAlbum finalizeStageAlbum({
    StagePhotoRiderSubject? stageWinner,
    StagePhotoEnvironmentContext? finishContext,
    double? finishElapsedSeconds,
    bool isPhotoFinishSprint = false,
  }) {
    if (!_isFinalized) {
      final hasFinishPhoto = _candidates.any(
        (p) =>
            p.momentKind == StagePhotoMomentKind.sprintPhotoFinish ||
            p.momentKind == StagePhotoMomentKind.soloStageVictory,
      );

      if (!hasFinishPhoto && (stageWinner != null || finishContext != null)) {
        final ctx = finishContext ?? const StagePhotoEnvironmentContext();
        final winnerName = stageWinner?.riderName ?? 'Zwycięzca etapu';
        final kind = isPhotoFinishSprint
            ? StagePhotoMomentKind.sprintPhotoFinish
            : StagePhotoMomentKind.soloStageVictory;
        _recordCandidate(
          kind: kind,
          slot: StagePhotoSlotCategory.finaleAndFinishLine,
          sourceKeyMomentType: KeyMomentType.finaleFinal5Km,
          kilometerMark: _totalDistanceKm,
          elapsedSeconds: finishElapsedSeconds ?? (_totalDistanceKm * 84.0),
          title: isPhotoFinishSprint
              ? 'Fotofinisz na mecie: $winnerName'
              : 'Triumf na mecie: $winnerName',
          caption: isPhotoFinishSprint
              ? 'Rozstrzygnięcie na milimetry na linii mety etapu $_stageNumber ($_stageName).'
              : '$winnerName przekracza linię mety jako pierwszy po $_totalDistanceKm km rywalizacji.',
          context: ctx,
          subjects: stageWinner != null ? [stageWinner] : const [],
          recommendedCamera: 'finishLine',
          customDramaScore: isPhotoFinishSprint ? 98.0 : 94.0,
        );
      }
      _isFinalized = true;
    }

    return buildCurrentAlbumPreview();
  }

  List<StagePhotoSnapshot> _selectCuratedPhotos() {
    if (_candidates.isEmpty) return const [];

    final selected = <StagePhotoSnapshot>[];
    final usedIds = <String>{};

    // Krok 1: Zadbaj o reprezentację każdego z 4 rozdziałów narracyjnych etapu.
    for (final slot in StagePhotoSlotCategory.values) {
      if (selected.length >= _maxPhotos) break;
      final slotCandidates = _candidates
          .where((p) => p.slotCategory == slot && !usedIds.contains(p.photoId))
          .toList()
        ..sort((a, b) => b.dramaScore.compareTo(a.dramaScore));

      if (slotCandidates.isNotEmpty) {
        final best = slotCandidates.first;
        selected.add(best);
        usedIds.add(best.photoId);
      }
    }

    // Krok 2: Jeśli któryś rozdział był pusty, dobierz brakujące kadry wg dramaScore.
    if (selected.length < _maxPhotos) {
      final remaining = _candidates
          .where((p) => !usedIds.contains(p.photoId))
          .toList()
        ..sort((a, b) => b.dramaScore.compareTo(a.dramaScore));

      for (final candidate in remaining) {
        if (selected.length >= _maxPhotos) break;
        selected.add(candidate);
        usedIds.add(candidate.photoId);
      }
    }

    // Krok 3: Posortuj chronologicznie po kilometrażu etapu.
    selected.sort((a, b) {
      final kmCmp = a.kilometerMark.compareTo(b.kilometerMark);
      if (kmCmp != 0) return kmCmp;
      return a.elapsedSeconds.compareTo(b.elapsedSeconds);
    });

    // Krok 4: Oznacz zdjęcie o najwyższym dramaScore jako okładkę albumu.
    var coverIndex = 0;
    var bestDrama = -1.0;
    for (var i = 0; i < selected.length; i++) {
      if (selected[i].dramaScore > bestDrama) {
        bestDrama = selected[i].dramaScore;
        coverIndex = i;
      }
    }

    return List<StagePhotoSnapshot>.generate(
      selected.length,
      (i) => selected[i].copyWith(isFeaturedCover: i == coverIndex),
      growable: false,
    );
  }

  double _computeDramaScore({
    required StagePhotoMomentKind kind,
    required double remainingKm,
    required StagePhotoEnvironmentContext context,
    required List<StagePhotoRiderSubject> subjects,
  }) {
    var score = 55.0;
    switch (kind) {
      case StagePhotoMomentKind.breakawayAttack:
        score = 62.0;
        break;
      case StagePhotoMomentKind.cobbleSectorBattle:
        score = 76.0;
        break;
      case StagePhotoMomentKind.crosswindEchelon:
        score = 74.0;
        break;
      case StagePhotoMomentKind.decisiveMountainClimb:
        score = 80.0;
        break;
      case StagePhotoMomentKind.gcSummitAttack:
        score = 87.0;
        break;
      case StagePhotoMomentKind.crashOrMechanicalDrama:
        score = 83.0;
        break;
      case StagePhotoMomentKind.final5KmChase:
        score = 85.0;
        break;
      case StagePhotoMomentKind.sprintPhotoFinish:
        score = 96.0;
        break;
      case StagePhotoMomentKind.soloStageVictory:
        score = 94.0;
        break;
    }

    if (remainingKm <= 10.0) {
      score += 7.0;
    } else if (remainingKm <= 25.0) {
      score += 3.5;
    }

    if (context.gradientPercent >= 8.0) {
      score += 4.5;
    }
    if (context.hasRain || context.windSpeedKmh >= 28.0) {
      score += 4.0;
    }
    if (subjects.any((s) => s.isPlayerTeam)) {
      score += 6.0;
    }
    if (subjects.any((s) => s.powerWatts >= 600)) {
      score += 3.0;
    }

    return score.clamp(0.0, 100.0);
  }

  StagePhotoMomentKind _mapKeyMomentToPhotoKind(KeyMomentType type) {
    switch (type) {
      case KeyMomentType.breakawayFormation:
        return StagePhotoMomentKind.breakawayAttack;
      case KeyMomentType.challengingCobbles:
        return StagePhotoMomentKind.cobbleSectorBattle;
      case KeyMomentType.severeCrosswindEchelon:
        return StagePhotoMomentKind.crosswindEchelon;
      case KeyMomentType.gcLeaderAttack:
        return StagePhotoMomentKind.gcSummitAttack;
      case KeyMomentType.decisiveClimb:
        return StagePhotoMomentKind.decisiveMountainClimb;
      case KeyMomentType.playerRiderIncident:
        return StagePhotoMomentKind.crashOrMechanicalDrama;
      case KeyMomentType.finaleFinal5Km:
        return StagePhotoMomentKind.final5KmChase;
    }
  }

  StagePhotoSlotCategory _mapKeyMomentToSlot(KeyMomentType type) {
    switch (type) {
      case KeyMomentType.breakawayFormation:
        return StagePhotoSlotCategory.earlyBreakawayOrRollout;
      case KeyMomentType.challengingCobbles:
      case KeyMomentType.decisiveClimb:
        return StagePhotoSlotCategory.crucialClimbOrCobbles;
      case KeyMomentType.severeCrosswindEchelon:
      case KeyMomentType.gcLeaderAttack:
      case KeyMomentType.playerRiderIncident:
        return StagePhotoSlotCategory.dramaOrIncident;
      case KeyMomentType.finaleFinal5Km:
        return StagePhotoSlotCategory.finaleAndFinishLine;
    }
  }

  StagePhotoCameraSpec _buildCameraSpec({
    required StagePhotoMomentKind kind,
    required String? recommendedCamera,
    required StagePhotoEnvironmentContext context,
    required int seed,
  }) {
    final StagePhotoCameraPreset preset;
    if (recommendedCamera == 'helicopter') {
      preset = StagePhotoCameraPreset.helicopterWide;
    } else if (recommendedCamera == 'cockpit') {
      preset = StagePhotoCameraPreset.pelotonCockpit;
    } else if (recommendedCamera == 'finishLine') {
      preset = StagePhotoCameraPreset.finishLineTelephoto;
    } else {
      switch (kind) {
        case StagePhotoMomentKind.crosswindEchelon:
          preset = StagePhotoCameraPreset.helicopterWide;
          break;
        case StagePhotoMomentKind.cobbleSectorBattle:
          preset = StagePhotoCameraPreset.cobbleRoadsidePan;
          break;
        case StagePhotoMomentKind.decisiveMountainClimb:
        case StagePhotoMomentKind.gcSummitAttack:
          preset = StagePhotoCameraPreset.staticClimbCorner;
          break;
        case StagePhotoMomentKind.sprintPhotoFinish:
        case StagePhotoMomentKind.soloStageVictory:
          preset = StagePhotoCameraPreset.finishLineTelephoto;
          break;
        case StagePhotoMomentKind.breakawayAttack:
        case StagePhotoMomentKind.crashOrMechanicalDrama:
        case StagePhotoMomentKind.final5KmChase:
          preset = StagePhotoCameraPreset.motoFollowLow;
          break;
      }
    }

    final isPanning = preset == StagePhotoCameraPreset.cobbleRoadsidePan;
    final isTele = preset == StagePhotoCameraPreset.finishLineTelephoto;
    final isHeli = preset == StagePhotoCameraPreset.helicopterWide;

    final focal = isTele
        ? 400
        : isHeli
            ? 135
            : isPanning
                ? 70
                : 35;
    final shutter = isPanning
        ? '1/160s'
        : isTele
            ? '1/3200s'
            : '1/1600s';
    final aperture = isTele ? 'f/2.8' : isHeli ? 'f/4.0' : 'f/2.0';
    final iso = context.hasRain ||
            context.lightingMood == StagePhotoLightingMood.overcastStorm
        ? 1250
        : context.lightingMood == StagePhotoLightingMood.twilightFloodlights
            ? 2500
            : 250;

    final yaw = ((seed * 37) % 50) - 25.0;
    final pitch = isHeli ? -38.0 : isTele ? -2.0 : -8.0;

    return StagePhotoCameraSpec(
      preset: preset,
      focalLengthMm: focal,
      shutterSpeedLabel: shutter,
      apertureLabel: aperture,
      isoValue: iso,
      cameraYawDeg: yaw,
      cameraPitchDeg: pitch,
    );
  }

  int _computeVisualSeed(String stageId, int seq, double km) {
    var hash = 2166136261;
    for (final code in stageId.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    hash ^= (seq * 397) ^ km.round();
    return hash.abs();
  }
}

// ============================================================================
// 4. ZARZĄDZANIE STANEM RIVERPOD
// ============================================================================

class StagePhotoAlbumState {
  final StagePhotoAlbum? activeAlbum;
  final List<StagePhotoAlbum> archivedAlbums;
  final int selectedPhotoIndex;
  final StagePhotoSlotCategory? activeSlotFilter;

  const StagePhotoAlbumState({
    this.activeAlbum,
    this.archivedAlbums = const [],
    this.selectedPhotoIndex = 0,
    this.activeSlotFilter,
  });

  StagePhotoAlbumState copyWith({
    StagePhotoAlbum? activeAlbum,
    List<StagePhotoAlbum>? archivedAlbums,
    int? selectedPhotoIndex,
    StagePhotoSlotCategory? activeSlotFilter,
    bool clearSlotFilter = false,
  }) {
    return StagePhotoAlbumState(
      activeAlbum: activeAlbum ?? this.activeAlbum,
      archivedAlbums: archivedAlbums ?? this.archivedAlbums,
      selectedPhotoIndex: selectedPhotoIndex ?? this.selectedPhotoIndex,
      activeSlotFilter:
          clearSlotFilter ? null : (activeSlotFilter ?? this.activeSlotFilter),
    );
  }
}

class StagePhotoAlbumNotifier extends StateNotifier<StagePhotoAlbumState> {
  final StagePhotoAlbumAutoCapturer _capturer = StagePhotoAlbumAutoCapturer();

  StagePhotoAlbumNotifier() : super(const StagePhotoAlbumState());

  void startStage({
    required String stageId,
    required String stageName,
    required int stageNumber,
    required double totalDistanceKm,
  }) {
    _capturer.startStageCapture(
      stageId: stageId,
      stageName: stageName,
      stageNumber: stageNumber,
      totalDistanceKm: totalDistanceKm,
    );
    state = state.copyWith(
      activeAlbum: _capturer.buildCurrentAlbumPreview(),
      selectedPhotoIndex: 0,
      clearSlotFilter: true,
    );
  }

  void recordKeyMoment(
    KeyMomentTrigger trigger, {
    required double elapsedSeconds,
    required StagePhotoEnvironmentContext context,
    List<StagePhotoRiderSubject> subjects = const [],
  }) {
    final added = _capturer.evaluateKeyMomentTrigger(
      trigger,
      elapsedSeconds: elapsedSeconds,
      context: context,
      subjects: subjects,
    );
    if (added != null) {
      state = state.copyWith(activeAlbum: _capturer.buildCurrentAlbumPreview());
    }
  }

  void recordCustomMoment({
    required StagePhotoMomentKind kind,
    required double kilometerMark,
    required double elapsedSeconds,
    required String title,
    required String caption,
    required StagePhotoEnvironmentContext context,
    List<StagePhotoRiderSubject> subjects = const [],
    double? customDramaScore,
  }) {
    final added = _capturer.captureCustomMoment(
      kind: kind,
      kilometerMark: kilometerMark,
      elapsedSeconds: elapsedSeconds,
      title: title,
      caption: caption,
      context: context,
      subjects: subjects,
      customDramaScore: customDramaScore,
    );
    if (added != null) {
      state = state.copyWith(activeAlbum: _capturer.buildCurrentAlbumPreview());
    }
  }

  void finalizeStage({
    StagePhotoRiderSubject? stageWinner,
    StagePhotoEnvironmentContext? finishContext,
    double? finishElapsedSeconds,
    bool isPhotoFinishSprint = false,
  }) {
    final album = _capturer.finalizeStageAlbum(
      stageWinner: stageWinner,
      finishContext: finishContext,
      finishElapsedSeconds: finishElapsedSeconds,
      isPhotoFinishSprint: isPhotoFinishSprint,
    );
    final updatedArchive = [
      ...state.archivedAlbums.where((a) => a.stageId != album.stageId),
      album,
    ];
    state = state.copyWith(
      activeAlbum: album,
      archivedAlbums: updatedArchive,
      selectedPhotoIndex: 0,
    );
  }

  void loadAlbum(StagePhotoAlbum album) {
    state = state.copyWith(
      activeAlbum: album,
      selectedPhotoIndex: 0,
      clearSlotFilter: true,
    );
  }

  void selectPhoto(int index) {
    final count = state.activeAlbum?.photos.length ?? 0;
    if (count == 0) return;
    state = state.copyWith(
      selectedPhotoIndex: index.clamp(0, count - 1),
    );
  }

  void setSlotFilter(StagePhotoSlotCategory? slot) {
    if (slot == state.activeSlotFilter) {
      state = state.copyWith(clearSlotFilter: true);
    } else {
      state = state.copyWith(activeSlotFilter: slot);
    }
  }
}

final stagePhotoAlbumProvider =
    StateNotifierProvider<StagePhotoAlbumNotifier, StagePhotoAlbumState>(
  (ref) => StagePhotoAlbumNotifier(),
);

// ============================================================================
// 5. WIDŻET GALERII ALBUMU ZDJĘĆ ETAPOWYCH + RENDERER MINIATUR
// ============================================================================

/// Interaktywny panel albumu 4 zdjęć z kluczowych momentów etapu.
class StagePhotoAlbumGalleryPanel extends StatefulWidget {
  final StagePhotoAlbum? albumOverride;
  final ValueChanged<StagePhotoSnapshot>? onPhotoSelected;
  final VoidCallback? onExportAlbumPressed;

  const StagePhotoAlbumGalleryPanel({
    super.key,
    this.albumOverride,
    this.onPhotoSelected,
    this.onExportAlbumPressed,
  });

  @override
  State<StagePhotoAlbumGalleryPanel> createState() =>
      _StagePhotoAlbumGalleryPanelState();
}

class _StagePhotoAlbumGalleryPanelState
    extends State<StagePhotoAlbumGalleryPanel> {
  int _selectedIndex = 0;
  int? _hoveredIndex;
  int? _focusedIndex;
  StagePhotoSlotCategory? _slotFilter;

  @override
  Widget build(BuildContext context) {
    final album = widget.albumOverride;
    if (album == null || album.photos.isEmpty) {
      return _buildEmptyState();
    }

    final filteredPhotos = _slotFilter == null
        ? album.photos
        : album.photos.where((p) => p.slotCategory == _slotFilter).toList();
    final safeIndex = filteredPhotos.isEmpty
        ? 0
        : _selectedIndex.clamp(0, filteredPhotos.length - 1);
    final selectedPhoto =
        filteredPhotos.isNotEmpty ? filteredPhotos[safeIndex] : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 640;
          final isTablet = width >= 640 && width < 1100;
          final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(album, isMobile),
              const SizedBox(height: 12),
              _buildSlotFilterChips(album),
              const SizedBox(height: 14),
              if (filteredPhotos.isEmpty)
                _buildEmptyFilterBanner()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPhotos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isMobile ? 1.55 : 1.28,
                  ),
                  itemBuilder: (context, index) {
                    final photo = filteredPhotos[index];
                    return _StagePhotoCard(
                      photo: photo,
                      isSelected: index == safeIndex,
                      isHovered: _hoveredIndex == index,
                      isFocused: _focusedIndex == index,
                      onHoverChanged: (hover) => setState(
                        () => _hoveredIndex = hover ? index : null,
                      ),
                      onFocusChanged: (focused) => setState(
                        () => _focusedIndex = focused ? index : null,
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        widget.onPhotoSelected?.call(photo);
                      },
                    );
                  },
                ),
              if (selectedPhoto != null) ...[
                const SizedBox(height: 14),
                _buildInspectorPanel(selectedPhoto, isMobile),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(StagePhotoAlbum album, bool isMobile) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: album.isFinalized
              ? AppColors.goldAccent.withValues(alpha: 0.6)
              : AppColors.accentBlue.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '${album.photos.length}/${album.maxPhotos} KADRÓW',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: album.isFinalized ? AppColors.goldAccent : AppColors.accentBlue,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    final exportBtn = _AlbumActionButton(
      label: 'Eksportuj album',
      icon: Icons.photo_library_outlined,
      enabled: widget.onExportAlbumPressed != null && album.photos.isNotEmpty,
      onPressed: widget.onExportAlbumPressed,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Album Etapu ${album.stageNumber}: ${album.stageName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              badge,
              exportBtn,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(
          Icons.camera_alt_outlined,
          color: AppColors.goldAccent,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Album Etapu ${album.stageNumber}: ${album.stageName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        badge,
        const SizedBox(width: 10),
        exportBtn,
      ],
    );
  }

  Widget _buildSlotFilterChips(StagePhotoAlbum album) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChipButton(
          label: 'Wszystkie (${album.photos.length})',
          selected: _slotFilter == null,
          onTap: () => setState(() {
            _slotFilter = null;
            _selectedIndex = 0;
          }),
        ),
        for (final slot in StagePhotoSlotCategory.values)
          _FilterChipButton(
            label: slot.label,
            selected: _slotFilter == slot,
            onTap: () => setState(() {
              _slotFilter = _slotFilter == slot ? null : slot;
              _selectedIndex = 0;
            }),
          ),
      ],
    );
  }

  Widget _buildInspectorPanel(StagePhotoSnapshot photo, bool isMobile) {
    final leadSubject = photo.subjects.isNotEmpty ? photo.subjects.first : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryAccent),
                ),
                child: Text(
                  photo.momentKind.badgeLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  photo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Dramaturgia ${photo.dramaScore.toStringAsFixed(0)}/100',
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
          const SizedBox(height: 6),
          Text(
            photo.editorialCaption,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _TelemetryTag(
                icon: Icons.route_outlined,
                text:
                    '${photo.kilometerMark.toStringAsFixed(1)} km (do mety ${photo.remainingKm.toStringAsFixed(1)} km)',
              ),
              _TelemetryTag(
                icon: Icons.timer_outlined,
                text: photo.formattedClockTime,
              ),
              _TelemetryTag(
                icon: Icons.camera_outlined,
                text:
                    '${photo.cameraSpec.preset.photographerCredit} • ${photo.cameraSpec.exifSummary}',
              ),
              if (leadSubject != null)
                _TelemetryTag(
                  icon: Icons.flash_on_outlined,
                  text:
                      '${leadSubject.riderName}: ${leadSubject.powerWatts} W • ${leadSubject.speedKmh.toStringAsFixed(1)} km/h',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: const Text(
        'Brak zapisanych ujęć w wybranym rozdziale etapu.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera_back_outlined,
            color: AppColors.textSecondary,
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            'Album etapu oczekuje na kluczowe momenty wyścigu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePhotoCard extends StatelessWidget {
  final StagePhotoSnapshot photo;
  final bool isSelected;
  final bool isHovered;
  final bool isFocused;
  final ValueChanged<bool> onHoverChanged;
  final ValueChanged<bool> onFocusChanged;
  final VoidCallback onTap;

  const _StagePhotoCard({
    required this.photo,
    required this.isSelected,
    required this.isHovered,
    required this.isFocused,
    required this.onHoverChanged,
    required this.onFocusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.goldAccent
        : isFocused
            ? AppColors.accentBlue
            : isHovered
                ? AppColors.primaryAccent
                : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      onShowHoverHighlight: onHoverChanged,
      onShowFocusHighlight: onFocusChanged,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isSelected || isFocused ? 1.5 : 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: StagePhotoSceneThumbnailPainter(photo: photo),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF2A2F3D)),
                        ),
                        child: Text(
                          photo.momentKind.badgeLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (photo.isFeaturedCover)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OKŁADKA',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 6,
                      right: 8,
                      child: Text(
                        '${photo.kilometerMark.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      photo.slotCategory.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.accentBlue
                  : widget.selected
                      ? AppColors.goldAccent
                      : const Color(0xFF2A2F3D),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
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

class _AlbumActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _AlbumActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_AlbumActionButton> createState() => _AlbumActionButtonState();
}

class _AlbumActionButtonState extends State<_AlbumActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? AppColors.primaryAccent
            : _hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.85)
                : AppColors.surfaceLight;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.accentBlue
                  : const Color(0xFF2A2F3D),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TelemetryTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.accentBlue),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// Deterministyczny malarz miniatury sceny fotograficznej etapu.
class StagePhotoSceneThumbnailPainter extends CustomPainter {
  final StagePhotoSnapshot photo;

  const StagePhotoSceneThumbnailPainter({required this.photo});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final skyColors = _skyColors(photo.environment.lightingMood);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: skyColors,
        ).createShader(rect),
    );

    // Sylwetki gór / horyzontu zależne od nachylenia i seeda
    final horizonY = size.height * 0.56;
    final mountainPaint = Paint()
      ..color = const Color(0xFF181B22).withValues(alpha: 0.85);
    final mountainPath = Path()..moveTo(0, horizonY);
    final peakAmp = (photo.environment.gradientPercent.abs() * 3.5 + 14.0)
        .clamp(12.0, size.height * 0.32);
    final rng = math.Random(photo.visualSeed);
    for (var i = 1; i <= 4; i++) {
      final x = size.width * (i / 4.0);
      final y = horizonY - (i.isOdd ? peakAmp * (0.6 + rng.nextDouble() * 0.4) : peakAmp * 0.25);
      mountainPath.lineTo(x, y);
    }
    mountainPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(mountainPath, mountainPaint);

    // Szosa / bruk w perspektywie
    final roadPaint = Paint()
      ..color = photo.environment.hasCobbles
          ? const Color(0xFF2E3440)
          : const Color(0xFF1E232D);
    final roadPath = Path()
      ..moveTo(size.width * 0.42, horizonY)
      ..lineTo(size.width * 0.58, horizonY)
      ..lineTo(size.width * 0.95, size.height)
      ..lineTo(size.width * 0.05, size.height)
      ..close();
    canvas.drawPath(roadPath, roadPaint);

    // Sylwetki kolarzy z kolorami koszulek
    final riderCount = math.max(1, math.min(5, photo.subjects.length));
    for (var i = 0; i < riderCount; i++) {
      final subject =
          i < photo.subjects.length ? photo.subjects[i] : null;
      final rx = size.width * (0.34 + i * 0.09);
      final ry = size.height * (0.74 - (i % 2) * 0.05);
      final jerseyColor = subject?.jerseyColor ?? AppColors.goldAccent;
      canvas.drawCircle(
        Offset(rx, ry),
        6.0,
        Paint()..color = jerseyColor,
      );
      canvas.drawCircle(
        Offset(rx, ry - 7.5),
        3.0,
        Paint()..color = AppColors.textPrimary,
      );
    }

    // Subtelny celownik wizjera aparatu
    final framePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect.deflate(6), framePaint);
  }

  List<Color> _skyColors(StagePhotoLightingMood mood) {
    switch (mood) {
      case StagePhotoLightingMood.morningMist:
        return const [Color(0xFF1F2A38), Color(0xFF475569)];
      case StagePhotoLightingMood.crispDaylight:
        return const [Color(0xFF0F2942), Color(0xFF38BDF8)];
      case StagePhotoLightingMood.overcastStorm:
        return const [Color(0xFF0F1115), Color(0xFF334155)];
      case StagePhotoLightingMood.goldenHour:
        return const [Color(0xFF3B1D2A), Color(0xFFD4AF37)];
      case StagePhotoLightingMood.twilightFloodlights:
        return const [Color(0xFF090B10), Color(0xFF1E293B)];
    }
  }

  @override
  bool shouldRepaint(covariant StagePhotoSceneThumbnailPainter oldDelegate) {
    return oldDelegate.photo.photoId != photo.photoId ||
        oldDelegate.photo.isFeaturedCover != photo.isFeaturedCover;
  }
}
