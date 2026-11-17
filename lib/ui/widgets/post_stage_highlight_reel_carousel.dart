// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/simulation/stage_photo_album_auto_capturer.dart';

/// Typ elementu w karuzeli skrótów po etapie.
enum HighlightMediaType {
  videoClip,
  stagePhoto;

  String toJson() => name;

  static HighlightMediaType fromJson(String value) {
    return HighlightMediaType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HighlightMediaType.stagePhoto,
    );
  }

  String get label {
    switch (this) {
      case HighlightMediaType.videoClip:
        return 'WIDEO';
      case HighlightMediaType.stagePhoto:
        return 'ZDJĘCIE';
    }
  }

  IconData get icon {
    switch (this) {
      case HighlightMediaType.videoClip:
        return Icons.videocam_rounded;
      case HighlightMediaType.stagePhoto:
        return Icons.photo_camera_rounded;
    }
  }
}

/// Filtr typów mediów w karuzeli skrótów.
enum HighlightReelFilter {
  all,
  videoOnly,
  photosOnly;

  String get label {
    switch (this) {
      case HighlightReelFilter.all:
        return 'Wszystkie';
      case HighlightReelFilter.videoOnly:
        return 'Skróty wideo';
      case HighlightReelFilter.photosOnly:
        return 'Zdjęcia';
    }
  }
}

/// Pojedynczy element karuzeli skrótów wideo lub zdjęć z etapu.
class StageHighlightReelItem {
  final String id;
  final HighlightMediaType mediaType;
  final String title;
  final String editorialCaption;
  final int stageNumber;
  final double kilometerMark;
  final double remainingKm;
  final double elapsedSeconds;
  final double dramaScore;
  final String cameraCredit;
  final StagePhotoMomentKind momentKind;
  final StagePhotoLightingMood lightingMood;
  final int visualSeed;
  final double gradientPercent;
  final bool hasCobbles;
  final bool isFeaturedCover;
  final Duration? clipDuration;
  final String? exifSummary;
  final List<StagePhotoRiderSubject> subjects;
  final StagePhotoSnapshot? sourcePhoto;

  const StageHighlightReelItem({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.editorialCaption,
    required this.stageNumber,
    required this.kilometerMark,
    required this.remainingKm,
    required this.elapsedSeconds,
    required this.dramaScore,
    required this.cameraCredit,
    required this.momentKind,
    required this.lightingMood,
    required this.visualSeed,
    this.gradientPercent = 0.0,
    this.hasCobbles = false,
    this.isFeaturedCover = false,
    this.clipDuration,
    this.exifSummary,
    this.subjects = const [],
    this.sourcePhoto,
  });

  StageHighlightReelItem copyWith({
    bool? isFeaturedCover,
    double? dramaScore,
  }) {
    return StageHighlightReelItem(
      id: id,
      mediaType: mediaType,
      title: title,
      editorialCaption: editorialCaption,
      stageNumber: stageNumber,
      kilometerMark: kilometerMark,
      remainingKm: remainingKm,
      elapsedSeconds: elapsedSeconds,
      dramaScore: dramaScore ?? this.dramaScore,
      cameraCredit: cameraCredit,
      momentKind: momentKind,
      lightingMood: lightingMood,
      visualSeed: visualSeed,
      gradientPercent: gradientPercent,
      hasCobbles: hasCobbles,
      isFeaturedCover: isFeaturedCover ?? this.isFeaturedCover,
      clipDuration: clipDuration,
      exifSummary: exifSummary,
      subjects: subjects,
      sourcePhoto: sourcePhoto,
    );
  }

  String get formattedClockTime {
    final total = elapsedSeconds.round().clamp(0, 86400);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  String get formattedClipDuration {
    final secs = (clipDuration?.inSeconds ?? 14).clamp(1, 3600);
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  StagePhotoSnapshot toPhotoSnapshot() {
    if (sourcePhoto != null) return sourcePhoto!;
    return StagePhotoSnapshot(
      photoId: id,
      stageId: 'stage_$stageNumber',
      stageNumber: stageNumber,
      slotCategory: momentKind.defaultSlot,
      momentKind: momentKind,
      kilometerMark: kilometerMark,
      remainingKm: remainingKm,
      elapsedSeconds: elapsedSeconds,
      title: title,
      editorialCaption: editorialCaption,
      dramaScore: dramaScore,
      isFeaturedCover: isFeaturedCover,
      visualSeed: visualSeed,
      cameraSpec: const StagePhotoCameraSpec(
        preset: StagePhotoCameraPreset.motoFollowLow,
        focalLengthMm: 70,
        shutterSpeedLabel: '1/2000s',
        apertureLabel: 'f/2.8',
        isoValue: 400,
        cameraYawDeg: 15.0,
        cameraPitchDeg: -6.0,
      ),
      environment: StagePhotoEnvironmentContext(
        lightingMood: lightingMood,
        gradientPercent: gradientPercent,
        windSpeedKmh: 12.0,
        hasCobbles: hasCobbles,
        elevationMeters: 420.0,
      ),
      subjects: subjects,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaType': mediaType.toJson(),
        'title': title,
        'editorialCaption': editorialCaption,
        'stageNumber': stageNumber,
        'kilometerMark': kilometerMark,
        'remainingKm': remainingKm,
        'elapsedSeconds': elapsedSeconds,
        'dramaScore': dramaScore,
        'cameraCredit': cameraCredit,
        'momentKind': momentKind.toJson(),
        'lightingMood': lightingMood.toJson(),
        'visualSeed': visualSeed,
        'gradientPercent': gradientPercent,
        'hasCobbles': hasCobbles,
        'isFeaturedCover': isFeaturedCover,
        'clipDurationSeconds': clipDuration?.inSeconds,
        'exifSummary': exifSummary,
        'subjects': subjects.map((s) => s.toJson()).toList(),
      };

  factory StageHighlightReelItem.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'] as List<dynamic>? ?? const [];
    final clipSecs = (json['clipDurationSeconds'] as num?)?.toInt();
    return StageHighlightReelItem(
      id: json['id'] as String? ?? 'highlight_0',
      mediaType: HighlightMediaType.fromJson(
        json['mediaType'] as String? ?? 'stagePhoto',
      ),
      title: json['title'] as String? ?? 'Skrót z etapu',
      editorialCaption: json['editorialCaption'] as String? ?? '',
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      kilometerMark: (json['kilometerMark'] as num?)?.toDouble() ?? 0.0,
      remainingKm: (json['remainingKm'] as num?)?.toDouble() ?? 0.0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toDouble() ?? 0.0,
      dramaScore: (json['dramaScore'] as num?)?.toDouble() ?? 50.0,
      cameraCredit: json['cameraCredit'] as String? ?? 'Motocykl TV #1',
      momentKind: StagePhotoMomentKind.fromJson(
        json['momentKind'] as String? ?? 'soloStageVictory',
      ),
      lightingMood: StagePhotoLightingMood.fromJson(
        json['lightingMood'] as String? ?? 'crispDaylight',
      ),
      visualSeed: (json['visualSeed'] as num?)?.toInt() ?? 1,
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      hasCobbles: json['hasCobbles'] as bool? ?? false,
      isFeaturedCover: json['isFeaturedCover'] as bool? ?? false,
      clipDuration: clipSecs != null ? Duration(seconds: clipSecs) : null,
      exifSummary: json['exifSummary'] as String?,
      subjects: rawSubjects
          .whereType<Map<String, dynamic>>()
          .map(StagePhotoRiderSubject.fromJson)
          .toList(),
    );
  }
}

/// Budowniczy listy skrótów wideo i zdjęć na podstawie albumu etapu.
class PostStageHighlightReelBuilder {
  PostStageHighlightReelBuilder._();

  static List<StageHighlightReelItem> fromStagePhotoAlbum(
    StagePhotoAlbum album, {
    bool includeGeneratedVideoClips = true,
  }) {
    if (album.photos.isEmpty) return const [];

    final items = <StageHighlightReelItem>[];
    for (var i = 0; i < album.photos.length; i++) {
      final photo = album.photos[i];
      if (includeGeneratedVideoClips && (i == 0 || photo.dramaScore >= 65.0)) {
        final clipSeconds = 12 + (photo.dramaScore ~/ 12).clamp(2, 10);
        items.add(
          StageHighlightReelItem(
            id: 'clip_${photo.photoId}',
            mediaType: HighlightMediaType.videoClip,
            title: 'Powtórka TV: ${photo.title}',
            editorialCaption: photo.editorialCaption,
            stageNumber: photo.stageNumber,
            kilometerMark: photo.kilometerMark,
            remainingKm: photo.remainingKm,
            elapsedSeconds: photo.elapsedSeconds,
            dramaScore: photo.dramaScore,
            cameraCredit: photo.cameraSpec.preset.photographerCredit,
            momentKind: photo.momentKind,
            lightingMood: photo.environment.lightingMood,
            visualSeed: photo.visualSeed + 17,
            gradientPercent: photo.environment.gradientPercent,
            hasCobbles: photo.environment.hasCobbles,
            isFeaturedCover: photo.isFeaturedCover,
            clipDuration: Duration(seconds: clipSeconds),
            subjects: photo.subjects,
            sourcePhoto: photo,
          ),
        );
      }

      items.add(
        StageHighlightReelItem(
          id: photo.photoId,
          mediaType: HighlightMediaType.stagePhoto,
          title: photo.title,
          editorialCaption: photo.editorialCaption,
          stageNumber: photo.stageNumber,
          kilometerMark: photo.kilometerMark,
          remainingKm: photo.remainingKm,
          elapsedSeconds: photo.elapsedSeconds,
          dramaScore: photo.dramaScore,
          cameraCredit: photo.cameraSpec.preset.photographerCredit,
          momentKind: photo.momentKind,
          lightingMood: photo.environment.lightingMood,
          visualSeed: photo.visualSeed,
          gradientPercent: photo.environment.gradientPercent,
          hasCobbles: photo.environment.hasCobbles,
          isFeaturedCover: photo.isFeaturedCover,
          exifSummary: photo.cameraSpec.exifSummary,
          subjects: photo.subjects,
          sourcePhoto: photo,
        ),
      );
    }

    items.sort((a, b) => a.kilometerMark.compareTo(b.kilometerMark));
    return items;
  }

  static List<StageHighlightReelItem> buildDefaultSampleReel({
    int stageNumber = 1,
    String stageName = 'Etap Królewski',
  }) {
    const leadSubject = StagePhotoRiderSubject(
      riderId: 'r_1',
      riderName: 'T. Pogačar',
      teamName: 'Team UAE',
      jerseyColorArgb: 0xFFD4AF37,
      isPlayerTeam: true,
      powerWatts: 468,
      speedKmh: 28.4,
      heartRateBpm: 186,
      positionInStage: 1,
      gapSeconds: 0.0,
    );
    const chaseSubject = StagePhotoRiderSubject(
      riderId: 'r_2',
      riderName: 'J. Vingegaard',
      teamName: 'Visma Lease',
      jerseyColorArgb: 0xFF38BDF8,
      isPlayerTeam: false,
      powerWatts: 452,
      speedKmh: 27.9,
      heartRateBpm: 183,
      positionInStage: 2,
      gapSeconds: 14.0,
    );

    return [
      StageHighlightReelItem(
        id: 'sample_clip_1',
        mediaType: HighlightMediaType.videoClip,
        title: 'Uformowanie ucieczki dnia ($stageName)',
        editorialCaption:
            'Dynamiczne przyspieszenie sześciu harcowników na początku etapu przy bocznym wietrze.',
        stageNumber: stageNumber,
        kilometerMark: 18.4,
        remainingKm: 146.6,
        elapsedSeconds: 1580,
        dramaScore: 76.0,
        cameraCredit: 'Helikopter Cineflex',
        momentKind: StagePhotoMomentKind.breakawayAttack,
        lightingMood: StagePhotoLightingMood.morningMist,
        visualSeed: 101,
        gradientPercent: 1.5,
        clipDuration: const Duration(seconds: 14),
        subjects: const [leadSubject, chaseSubject],
      ),
      StageHighlightReelItem(
        id: 'sample_photo_1',
        mediaType: HighlightMediaType.stagePhoto,
        title: 'Walka na decydującym podjeździe',
        editorialCaption:
            'Wysokie tempo selekcji w peletonie faworytów na nachyleniu 9.4%.',
        stageNumber: stageNumber,
        kilometerMark: 132.0,
        remainingKm: 33.0,
        elapsedSeconds: 11240,
        dramaScore: 88.0,
        cameraCredit: 'Fotoreporter Przełęczy',
        momentKind: StagePhotoMomentKind.decisiveMountainClimb,
        lightingMood: StagePhotoLightingMood.crispDaylight,
        visualSeed: 204,
        gradientPercent: 9.4,
        exifSummary: '70-200mm f/2.8 • 1/1600s • ISO 320',
        subjects: const [leadSubject, chaseSubject],
      ),
      StageHighlightReelItem(
        id: 'sample_clip_2',
        mediaType: HighlightMediaType.videoClip,
        title: 'Decydujący atak na ostatnich 2 km',
        editorialCaption:
            'Pełny gaz na finałowym kilometrze — rzut rowerem na kreskę przed goniącą grupą.',
        stageNumber: stageNumber,
        kilometerMark: 164.2,
        remainingKm: 0.8,
        elapsedSeconds: 14120,
        dramaScore: 96.0,
        cameraCredit: 'Boks Fotoreporterów Mety',
        momentKind: StagePhotoMomentKind.sprintPhotoFinish,
        lightingMood: StagePhotoLightingMood.goldenHour,
        visualSeed: 309,
        gradientPercent: 2.2,
        isFeaturedCover: true,
        clipDuration: const Duration(seconds: 18),
        subjects: const [leadSubject, chaseSubject],
      ),
      StageHighlightReelItem(
        id: 'sample_photo_2',
        mediaType: HighlightMediaType.stagePhoto,
        title: 'Triumf na linii mety',
        editorialCaption:
            'Zwycięski gest na mecie po wyczerpującej batalii o każdą sekundę w klasyfikacji.',
        stageNumber: stageNumber,
        kilometerMark: 165.0,
        remainingKm: 0.0,
        elapsedSeconds: 14195,
        dramaScore: 94.0,
        cameraCredit: 'Boks Fotoreporterów Mety',
        momentKind: StagePhotoMomentKind.soloStageVictory,
        lightingMood: StagePhotoLightingMood.goldenHour,
        visualSeed: 412,
        gradientPercent: 0.5,
        isFeaturedCover: true,
        exifSummary: '400mm f/2.8 • 1/2500s • ISO 400',
        subjects: const [leadSubject],
      ),
    ];
  }
}

/// Karuzela skrótów wideo i zdjęć z etapu przeznaczona na ekran podium.
class PostStageHighlightReelCarousel extends StatefulWidget {
  final List<StageHighlightReelItem> items;
  final String stageTitle;
  final int stageNumber;
  final bool isDisabled;
  final bool autoPlayInitial;
  final ValueChanged<StageHighlightReelItem>? onOpenInReplayTheater;
  final ValueChanged<StageHighlightReelItem>? onToggleFavorite;
  final ValueChanged<StageHighlightReelItem>? onItemSelected;

  const PostStageHighlightReelCarousel({
    super.key,
    required this.items,
    required this.stageTitle,
    required this.stageNumber,
    this.isDisabled = false,
    this.autoPlayInitial = false,
    this.onOpenInReplayTheater,
    this.onToggleFavorite,
    this.onItemSelected,
  });

  @override
  State<PostStageHighlightReelCarousel> createState() =>
      _PostStageHighlightReelCarouselState();
}

class _PostStageHighlightReelCarouselState
    extends State<PostStageHighlightReelCarousel>
    with SingleTickerProviderStateMixin {
  late AnimationController _videoController;
  late FocusNode _carouselFocusNode;
  Timer? _autoPlayTimer;

  HighlightReelFilter _activeFilter = HighlightReelFilter.all;
  int _currentIndex = 0;
  bool _isVideoPlaying = false;
  bool _isAutoPlayEnabled = false;
  double _playbackSpeed = 1.0;
  final Set<String> _favoriteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _carouselFocusNode = FocusNode(debugLabel: 'HighlightReelCarouselFocus');
    _isAutoPlayEnabled = widget.autoPlayInitial && !widget.isDisabled;
    _videoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    for (final item in widget.items) {
      if (item.isFeaturedCover) {
        _favoriteIds.add(item.id);
      }
    }

    _syncVideoControllerForCurrentItem(autoStart: true);
    _configureAutoPlayTimer();
  }

  @override
  void didUpdateWidget(covariant PostStageHighlightReelCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDisabled && _isVideoPlaying) {
      _videoController.stop();
      _isVideoPlaying = false;
    }
    if (widget.isDisabled && _isAutoPlayEnabled) {
      _isAutoPlayEnabled = false;
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
    }
    final filtered = _filteredItems;
    if (_currentIndex >= filtered.length && filtered.isNotEmpty) {
      _currentIndex = filtered.length - 1;
    } else if (filtered.isEmpty) {
      _currentIndex = 0;
    }
    if (oldWidget.items != widget.items) {
      _syncVideoControllerForCurrentItem(autoStart: !widget.isDisabled);
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    _videoController.dispose();
    _carouselFocusNode.dispose();
    super.dispose();
  }

  List<StageHighlightReelItem> get _filteredItems {
    switch (_activeFilter) {
      case HighlightReelFilter.all:
        return widget.items;
      case HighlightReelFilter.videoOnly:
        return widget.items
            .where((e) => e.mediaType == HighlightMediaType.videoClip)
            .toList();
      case HighlightReelFilter.photosOnly:
        return widget.items
            .where((e) => e.mediaType == HighlightMediaType.stagePhoto)
            .toList();
    }
  }

  StageHighlightReelItem? get _currentItem {
    final list = _filteredItems;
    if (list.isEmpty) return null;
    final safeIdx = _currentIndex.clamp(0, list.length - 1);
    return list[safeIdx];
  }

  void _configureAutoPlayTimer() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    if (!_isAutoPlayEnabled || widget.isDisabled || _filteredItems.length <= 1) {
      return;
    }
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.isDisabled) return;
      final list = _filteredItems;
      if (list.length <= 1) return;
      _selectIndex((_currentIndex + 1) % list.length);
    });
  }

  void _syncVideoControllerForCurrentItem({bool autoStart = false}) {
    final current = _currentItem;
    _videoController.stop();
    _videoController.value = 0.0;
    if (current == null ||
        current.mediaType != HighlightMediaType.videoClip) {
      _isVideoPlaying = false;
      return;
    }
    final baseSecs = (current.clipDuration?.inSeconds ?? 12).clamp(4, 60);
    final scaledMs = ((baseSecs * 1000) / _playbackSpeed).round();
    _videoController.duration = Duration(milliseconds: scaledMs);
    if (autoStart && !widget.isDisabled) {
      _videoController.repeat();
      _isVideoPlaying = true;
    } else {
      _isVideoPlaying = false;
    }
  }

  void _selectIndex(int index) {
    final list = _filteredItems;
    if (list.isEmpty || widget.isDisabled) return;
    final clamped = index.clamp(0, list.length - 1);
    if (clamped == _currentIndex) return;
    setState(() {
      _currentIndex = clamped;
    });
    _syncVideoControllerForCurrentItem(autoStart: true);
    widget.onItemSelected?.call(list[clamped]);
  }

  void _setFilter(HighlightReelFilter filter) {
    if (widget.isDisabled || filter == _activeFilter) return;
    setState(() {
      _activeFilter = filter;
      _currentIndex = 0;
    });
    _syncVideoControllerForCurrentItem(autoStart: true);
    _configureAutoPlayTimer();
  }

  void _togglePlayPause() {
    if (widget.isDisabled) return;
    final item = _currentItem;
    if (item == null || item.mediaType != HighlightMediaType.videoClip) return;
    setState(() {
      if (_isVideoPlaying) {
        _videoController.stop();
        _isVideoPlaying = false;
      } else {
        _videoController.repeat();
        _isVideoPlaying = true;
      }
    });
  }

  void _cyclePlaybackSpeed() {
    if (widget.isDisabled) return;
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 2.0;
      } else if (_playbackSpeed == 2.0) {
        _playbackSpeed = 0.5;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    final wasPlaying = _isVideoPlaying;
    final currentProgress = _videoController.value;
    final current = _currentItem;
    if (current != null && current.mediaType == HighlightMediaType.videoClip) {
      final baseSecs = (current.clipDuration?.inSeconds ?? 12).clamp(4, 60);
      _videoController.duration =
          Duration(milliseconds: ((baseSecs * 1000) / _playbackSpeed).round());
      _videoController.value = currentProgress;
      if (wasPlaying) {
        _videoController.repeat();
      }
    }
  }

  void _toggleAutoPlay() {
    if (widget.isDisabled) return;
    setState(() {
      _isAutoPlayEnabled = !_isAutoPlayEnabled;
    });
    _configureAutoPlayTimer();
  }

  void _toggleFavorite(StageHighlightReelItem item) {
    if (widget.isDisabled) return;
    setState(() {
      if (_favoriteIds.contains(item.id)) {
        _favoriteIds.remove(item.id);
      } else {
        _favoriteIds.add(item.id);
      }
    });
    widget.onToggleFavorite?.call(item);
  }

  void _openFullScreenDialog(StageHighlightReelItem item) {
    if (widget.isDisabled) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _MediaTypeBadge(mediaType: item.mediaType),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zamknij podgląd',
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildMediaVisual(item, interactiveScrub: false),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.editorialCaption,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.isDisabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final list = _filteredItems;
    if (list.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_currentIndex < list.length - 1) {
        _selectIndex(_currentIndex + 1);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_currentIndex > 0) {
        _selectIndex(_currentIndex - 1);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.space) {
      final current = _currentItem;
      if (current != null && current.mediaType == HighlightMediaType.videoClip) {
        _togglePlayPause();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final current = _currentItem;

    return Focus(
      focusNode: _carouselFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Opacity(
        opacity: widget.isDisabled ? 0.55 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              final isWideDesktop = constraints.maxWidth >= 920;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isCompact: isCompact, filteredCount: filtered.length),
                  const SizedBox(height: 14),
                  if (current == null)
                    _buildEmptyState()
                  else if (isWideDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildViewportSection(current, filtered.length),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: _buildEditorialDetailsPanel(current),
                        ),
                      ],
                    )
                  else ...[
                    _buildViewportSection(current, filtered.length),
                    const SizedBox(height: 14),
                    _buildEditorialDetailsPanel(current),
                  ],
                  if (filtered.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildThumbnailFilmstrip(filtered),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isCompact,
    required int filteredCount,
  }) {
    final titleGroup = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Text(
                'SKRÓTY & GALERIA ETAPU',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Text(
              'Etap #${widget.stageNumber} • ${widget.stageTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          filteredCount == 0
              ? 'Brak materiałów dla wybranego filtra'
              : 'Kadr ${_currentIndex + 1} z $filteredCount • Najważniejsze momenty transmisji i obiektywów',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    final controlsGroup = Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final filter in HighlightReelFilter.values)
          _ReelFilterChip(
            label: filter.label,
            isSelected: _activeFilter == filter,
            isDisabled: widget.isDisabled,
            onTap: () => _setFilter(filter),
          ),
        _ReelActionButton(
          icon: _isAutoPlayEnabled
              ? Icons.pause_circle_outline_rounded
              : Icons.play_circle_outline_rounded,
          label: _isAutoPlayEnabled ? 'Auto: WŁ' : 'Auto: WYŁ',
          isActive: _isAutoPlayEnabled,
          isDisabled: widget.isDisabled || filteredCount <= 1,
          onTap: _toggleAutoPlay,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleGroup,
          const SizedBox(height: 10),
          controlsGroup,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleGroup),
        const SizedBox(width: 12),
        Flexible(child: Align(alignment: Alignment.topRight, child: controlsGroup)),
      ],
    );
  }

  Widget _buildViewportSection(
    StageHighlightReelItem item,
    int totalCount,
  ) {
    final canGoPrev = !widget.isDisabled && _currentIndex > 0;
    final canGoNext = !widget.isDisabled && _currentIndex < totalCount - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: KeyedSubtree(
                    key: ValueKey<String>(item.id),
                    child: _buildMediaVisual(item, interactiveScrub: true),
                  ),
                ),
                // Górny pasek nakładki transmisji / aparatu
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _MediaTypeBadge(mediaType: item.mediaType),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Text(
                              item.momentKind.badgeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'DRAMA ${item.dramaScore.round()}/100',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.goldAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Przyciski nawigacji Lewo / Prawo
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ReelNavArrowButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Poprzedni materiał',
                      isDisabled: !canGoPrev,
                      onTap: () => _selectIndex(_currentIndex - 1),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ReelNavArrowButton(
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'Następny materiał',
                      isDisabled: !canGoNext,
                      onTap: () => _selectIndex(_currentIndex + 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (item.mediaType == HighlightMediaType.videoClip) ...[
          const SizedBox(height: 8),
          _buildVideoTransportBar(item),
        ],
      ],
    );
  }

  Widget _buildMediaVisual(
    StageHighlightReelItem item, {
    required bool interactiveScrub,
  }) {
    if (item.mediaType == HighlightMediaType.videoClip) {
      return GestureDetector(
        onTap: interactiveScrub && !widget.isDisabled ? _togglePlayPause : null,
        child: AnimatedBuilder(
          animation: _videoController,
          builder: (context, _) {
            return CustomPaint(
              painter: HighlightVideoClipPainter(
                item: item,
                progress: _videoController.value,
                isPlaying: _isVideoPlaying,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      );
    }

    return CustomPaint(
      painter: StagePhotoSceneThumbnailPainter(photo: item.toPhotoSnapshot()),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildVideoTransportBar(StageHighlightReelItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: AnimatedBuilder(
        animation: _videoController,
        builder: (context, _) {
          final totalSeconds = (item.clipDuration?.inSeconds ?? 12).clamp(1, 600);
          final currentSeconds =
              (_videoController.value * totalSeconds).round().clamp(0, totalSeconds);
          final currentLabel =
              '${(currentSeconds ~/ 60).toString().padLeft(2, '0')}:${(currentSeconds % 60).toString().padLeft(2, '0')}';

          return LayoutBuilder(
            builder: (context, barConstraints) {
              final sliderWidget = SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: AppColors.goldAccent,
                  inactiveTrackColor: AppColors.cardBorder,
                  thumbColor: AppColors.goldAccent,
                  overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _videoController.value.clamp(0.0, 1.0),
                  onChanged: widget.isDisabled
                      ? null
                      : (v) {
                          _videoController.value = v;
                        },
                ),
              );

              final playButton = _ReelActionButton(
                icon: _isVideoPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: _isVideoPlaying ? 'Pauza' : 'Odtwórz',
                isActive: _isVideoPlaying,
                isDisabled: widget.isDisabled,
                onTap: _togglePlayPause,
              );

              final timeText = Text(
                '$currentLabel / ${item.formattedClipDuration}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              );

              final speedButton = _ReelActionButton(
                icon: Icons.speed_rounded,
                label: '${_playbackSpeed}x',
                isActive: _playbackSpeed != 1.0,
                isDisabled: widget.isDisabled,
                onTap: _cyclePlaybackSpeed,
              );

              if (barConstraints.maxWidth < 440) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(child: playButton),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: timeText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        speedButton,
                      ],
                    ),
                    const SizedBox(height: 4),
                    sliderWidget,
                  ],
                );
              }

              return Row(
                children: [
                  playButton,
                  const SizedBox(width: 10),
                  Expanded(child: sliderWidget),
                  const SizedBox(width: 8),
                  timeText,
                  const SizedBox(width: 8),
                  speedButton,
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEditorialDetailsPanel(StageHighlightReelItem item) {
    final isFavorite = _favoriteIds.contains(item.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.editorialCaption,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetadataPill(
                icon: Icons.route_rounded,
                text:
                    'km ${item.kilometerMark.toStringAsFixed(1)} (${item.remainingKm.toStringAsFixed(1)} km do mety)',
              ),
              _MetadataPill(
                icon: Icons.schedule_rounded,
                text: item.formattedClockTime,
              ),
              _MetadataPill(
                icon: Icons.camera_alt_outlined,
                text: item.cameraCredit,
              ),
              if (item.exifSummary != null)
                _MetadataPill(
                  icon: Icons.tune_rounded,
                  text: item.exifSummary!,
                ),
            ],
          ),
          if (item.subjects.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'KOLARZE W KADRZE',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 6),
            for (final subject in item.subjects.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _RiderSubjectTelemetryRow(subject: subject),
              ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ReelActionButton(
                icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                label: isFavorite ? 'Wyróżniono' : 'Wyróżnij',
                isActive: isFavorite,
                isDisabled: widget.isDisabled,
                onTap: () => _toggleFavorite(item),
              ),
              _ReelActionButton(
                icon: Icons.fullscreen_rounded,
                label: 'Powiększ',
                isActive: false,
                isDisabled: widget.isDisabled,
                onTap: () => _openFullScreenDialog(item),
              ),
              if (widget.onOpenInReplayTheater != null)
                _ReelActionButton(
                  icon: Icons.movie_creation_outlined,
                  label: 'Kino Powtórek',
                  isActive: false,
                  isDisabled: widget.isDisabled,
                  onTap: () => widget.onOpenInReplayTheater?.call(item),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailFilmstrip(List<StageHighlightReelItem> items) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = index == _currentIndex;
          return _FilmstripThumbnailTile(
            item: item,
            isSelected: isSelected,
            isDisabled: widget.isDisabled,
            onTap: () => _selectIndex(index),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak skrótów i zdjęć z tego etapu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Przełącz filtr lub rozegraj etap w trybie 3D, aby zapisać kluczowe ujęcia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (_activeFilter != HighlightReelFilter.all && !widget.isDisabled) ...[
            const SizedBox(height: 12),
            _ReelActionButton(
              icon: Icons.filter_alt_off_rounded,
              label: 'Pokaż wszystkie materiały',
              isActive: true,
              isDisabled: false,
              onTap: () => _setFilter(HighlightReelFilter.all),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaTypeBadge extends StatelessWidget {
  final HighlightMediaType mediaType;

  const _MediaTypeBadge({required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final isVideo = mediaType == HighlightMediaType.videoClip;
    final badgeColor = isVideo ? AppColors.primaryAccent : AppColors.accentBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mediaType.icon, size: 12, color: AppColors.textPrimary),
          const SizedBox(width: 4),
          Text(
            mediaType.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetadataPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accentBlue),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderSubjectTelemetryRow extends StatelessWidget {
  final StagePhotoRiderSubject subject;

  const _RiderSubjectTelemetryRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: subject.isPlayerTeam
              ? AppColors.goldAccent.withValues(alpha: 0.45)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: subject.jerseyColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${subject.riderName} (${subject.teamName})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${subject.powerWatts}W • ${subject.speedKmh.toStringAsFixed(1)} km/h',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.cyanAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ReelFilterChip({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_ReelFilterChip> createState() => _ReelFilterChipState();
}

class _ReelFilterChipState extends State<_ReelFilterChip> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: _isHovered ? 0.4 : 0.28)
        : (_isPressed
            ? AppColors.surfaceLight
            : (_isHovered
                ? AppColors.surfaceLight.withValues(alpha: 0.85)
                : AppColors.background));

    final borderColor = _isFocused
        ? AppColors.cyanAccent
        : (widget.isSelected
            ? AppColors.goldAccent
            : (_isHovered ? AppColors.textSecondary : AppTheme.borderColor));

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
              fontSize: 11.5,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReelActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_ReelActionButton> createState() => _ReelActionButtonState();
}

class _ReelActionButtonState extends State<_ReelActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : (widget.isActive
            ? AppColors.goldAccent.withValues(alpha: _isHovered ? 0.28 : 0.18)
            : (_isPressed
                ? AppColors.background
                : (_isHovered ? AppColors.surface : AppColors.surfaceLight)));

    final borderColor = _isFocused
        ? AppColors.cyanAccent
        : (widget.isActive
            ? AppColors.goldAccent
            : (_isHovered ? AppColors.textSecondary : AppTheme.borderColor));

    final fgColor = widget.isDisabled
        ? AppColors.textSecondary
        : (widget.isActive ? AppColors.goldAccent : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedScale(
          scale: _isPressed && !widget.isDisabled ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: fgColor),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: fgColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

class _ReelNavArrowButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ReelNavArrowButton({
    required this.icon,
    required this.tooltip,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_ReelNavArrowButton> createState() => _ReelNavArrowButtonState();
}

class _ReelNavArrowButtonState extends State<_ReelNavArrowButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        onShowHoverHighlight: (h) => setState(() => _isHovered = h),
        onShowFocusHighlight: (f) => setState(() => _isFocused = f),
        mouseCursor: widget.isDisabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: widget.isDisabled ? null : () => setState(() => _isPressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.isDisabled
                  ? AppColors.background.withValues(alpha: 0.35)
                  : (_isPressed
                      ? AppColors.primaryAccent.withValues(alpha: 0.85)
                      : (_isHovered
                          ? AppColors.surfaceLight.withValues(alpha: 0.92)
                          : AppColors.background.withValues(alpha: 0.72))),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isFocused
                    ? AppColors.cyanAccent
                    : (widget.isDisabled
                        ? AppTheme.borderColor.withValues(alpha: 0.4)
                        : (_isHovered
                            ? AppColors.goldAccent
                            : AppTheme.borderColor)),
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 22,
              color: widget.isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilmstripThumbnailTile extends StatefulWidget {
  final StageHighlightReelItem item;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _FilmstripThumbnailTile({
    required this.item,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_FilmstripThumbnailTile> createState() =>
      _FilmstripThumbnailTileState();
}

class _FilmstripThumbnailTileState extends State<_FilmstripThumbnailTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused
        ? AppColors.cyanAccent
        : (widget.isSelected
            ? AppColors.goldAccent
            : (_isHovered ? AppColors.textSecondary : AppTheme.borderColor));

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 124,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected || _isFocused ? 2.0 : 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: widget.item.mediaType == HighlightMediaType.videoClip
                    ? HighlightVideoClipPainter(
                        item: widget.item,
                        progress: 0.35,
                        isPlaying: false,
                      )
                    : StagePhotoSceneThumbnailPainter(
                        photo: widget.item.toPhotoSnapshot(),
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 5,
                left: 5,
                child: Icon(
                  widget.item.mediaType.icon,
                  size: 13,
                  color: widget.item.mediaType == HighlightMediaType.videoClip
                      ? AppColors.goldAccent
                      : AppColors.accentBlue,
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 5,
                child: Text(
                  widget.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Malarz animowanej sceny wideo skrótu z etapu.
class HighlightVideoClipPainter extends CustomPainter {
  final StageHighlightReelItem item;
  final double progress;
  final bool isPlaying;

  const HighlightVideoClipPainter({
    required this.item,
    required this.progress,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final skyColors = _skyColors(item.lightingMood);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: skyColors,
        ).createShader(rect),
    );

    // Przesuwająca się panorama gór/horyzontu
    final horizonY = size.height * 0.54;
    final parallaxShift = progress * size.width * 0.22;
    final mountainPath = Path()..moveTo(0, horizonY);
    final peakAmp = (item.gradientPercent.abs() * 3.2 + 16.0)
        .clamp(14.0, size.height * 0.30);
    final rng = math.Random(item.visualSeed);
    for (var i = 0; i <= 5; i++) {
      final x = (size.width * (i / 4.0)) - (parallaxShift % (size.width * 0.25));
      final y = horizonY -
          (i.isOdd ? peakAmp * (0.65 + rng.nextDouble() * 0.35) : peakAmp * 0.28);
      mountainPath.lineTo(x, y);
    }
    mountainPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      mountainPath,
      Paint()..color = AppColors.surface.withValues(alpha: 0.88),
    );

    // Szosa z pasami ruchu
    final roadPaint = Paint()
      ..color = item.hasCobbles
          ? AppColors.cardBorder
          : const Color(0xFF1E232D);
    final roadPath = Path()
      ..moveTo(size.width * 0.38, horizonY)
      ..lineTo(size.width * 0.62, horizonY)
      ..lineTo(size.width * 0.96, size.height)
      ..lineTo(size.width * 0.04, size.height)
      ..close();
    canvas.drawPath(roadPath, roadPaint);

    // Przerywana linia środkowa poruszająca się z postępem klipu
    final dashPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 2.0;
    for (var i = 0; i < 6; i++) {
      final t0 = ((i / 6.0) + progress * 1.5) % 1.0;
      final t1 = (t0 + 0.07).clamp(0.0, 1.0);
      final y0 = horizonY + (size.height - horizonY) * t0;
      final y1 = horizonY + (size.height - horizonY) * t1;
      canvas.drawLine(
        Offset(size.width * 0.5, y0),
        Offset(size.width * 0.5, y1),
        dashPaint,
      );
    }

    // Animowani kolarze w kadrze
    final riderCount = math.max(1, math.min(4, item.subjects.length));
    for (var i = 0; i < riderCount; i++) {
      final subject = i < item.subjects.length ? item.subjects[i] : null;
      final bob = math.sin(progress * math.pi * 8 + i) * 2.5;
      final xAdvance = (progress - 0.5) * size.width * 0.14;
      final rx = (size.width * (0.36 + i * 0.09) + xAdvance)
          .clamp(size.width * 0.18, size.width * 0.82);
      final ry = size.height * (0.74 - (i % 2) * 0.04) + bob;
      final jerseyColor = subject?.jerseyColor ?? AppColors.goldAccent;

      // Koła
      final wheelPaint = Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(Offset(rx - 7, ry + 7), 4.5, wheelPaint);
      canvas.drawCircle(Offset(rx + 7, ry + 7), 4.5, wheelPaint);

      // Tułów i kask
      canvas.drawCircle(Offset(rx, ry), 6.0, Paint()..color = jerseyColor);
      canvas.drawCircle(
        Offset(rx + 2, ry - 7.5),
        3.0,
        Paint()..color = AppColors.textPrimary,
      );
    }

    // Narożniki kamery broadcastowej
    final cornerPaint = Paint()
      ..color = (isPlaying ? AppColors.goldAccent : AppColors.textSecondary)
          .withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const len = 14.0;
    const m = 10.0;
    canvas.drawLine(const Offset(m, m), const Offset(m + len, m), cornerPaint);
    canvas.drawLine(const Offset(m, m), const Offset(m, m + len), cornerPaint);
    canvas.drawLine(
      Offset(size.width - m, m),
      Offset(size.width - m - len, m),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - m, m),
      Offset(size.width - m, m + len),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(m, size.height - m),
      Offset(m + len, size.height - m),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(m, size.height - m),
      Offset(m, size.height - m - len),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - m, size.height - m),
      Offset(size.width - m - len, size.height - m),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - m, size.height - m),
      Offset(size.width - m, size.height - m - len),
      cornerPaint,
    );
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
  bool shouldRepaint(covariant HighlightVideoClipPainter oldDelegate) {
    return oldDelegate.item.id != item.id ||
        oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}
