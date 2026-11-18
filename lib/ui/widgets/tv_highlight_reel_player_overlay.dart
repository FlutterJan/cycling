// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/simulation/instant_highlight_clip_generator.dart';

/// Prędkość odtwarzania skrótu telewizyjnego.
enum TvHighlightPlayerPlaybackSpeed {
  x05(0.5, '0.5x'),
  x10(1.0, '1.0x'),
  x15(1.5, '1.5x'),
  x20(2.0, '2.0x');

  final double multiplier;
  final String label;

  const TvHighlightPlayerPlaybackSpeed(this.multiplier, this.label);

  TvHighlightPlayerPlaybackSpeed get next {
    final nextIndex = (index + 1) % TvHighlightPlayerPlaybackSpeed.values.length;
    return TvHighlightPlayerPlaybackSpeed.values[nextIndex];
  }
}

/// Motyw kolorystyczny oprawy graficznej transmisji TV.
enum TvBroadcastGraphicsTheme {
  worldFeedGold('World Feed', AppColors.goldAccent, AppColors.background),
  grandTourBurgundy('Grand Tour', AppColors.primaryAccent, AppColors.surface),
  nightStudioCyan('Studio Live', AppColors.cyanAccent, AppColors.background);

  final String label;
  final Color accentColor;
  final Color badgeBackground;

  const TvBroadcastGraphicsTheme(
    this.label,
    this.accentColor,
    this.badgeBackground,
  );

  TvBroadcastGraphicsTheme get next {
    final nextIndex = (index + 1) % TvBroadcastGraphicsTheme.values.length;
    return TvBroadcastGraphicsTheme.values[nextIndex];
  }
}

/// Stan aktywnego przejścia telewizyjnego między dwoma segmentami skrótu.
@immutable
class TvTransitionOverlayState {
  final bool isActive;
  final HighlightTransitionType transitionType;
  final double progress;
  final HighlightClipSegment? incomingSegment;
  final HighlightClipSegment? outgoingSegment;

  const TvTransitionOverlayState({
    required this.isActive,
    required this.transitionType,
    required this.progress,
    this.incomingSegment,
    this.outgoingSegment,
  });

  const TvTransitionOverlayState.idle()
      : isActive = false,
        transitionType = HighlightTransitionType.whooshCut,
        progress = 0.0,
        incomingSegment = null,
        outgoingSegment = null;
}

/// Kalkulator logiki przejść TV oraz pozycji na osi czasu 45-sekundowego skrótu.
class TvHighlightTransitionCalculator {
  TvHighlightTransitionCalculator._();

  /// Czas trwania automatycznej grafiki przejścia TV na początku segmentu.
  static const double transitionWindowSeconds = 0.55;

  /// Wylicza stan grafiki przejścia TV dla podanej sekundy na osi czasu.
  static TvTransitionOverlayState evaluateAtTimeline({
    required InstantHighlightReel reel,
    required double timelineSeconds,
  }) {
    if (reel.segments.isEmpty) {
      return const TvTransitionOverlayState.idle();
    }

    final clamped = timelineSeconds.clamp(0.0, reel.totalDurationSeconds);
    final activeIndex = segmentIndexAt(reel: reel, timelineSeconds: clamped);
    final activeSegment = reel.segments[activeIndex];
    final localOffset = clamped - activeSegment.startTimelineSecond;

    if (localOffset >= 0.0 && localOffset <= transitionWindowSeconds) {
      final rawProgress = (localOffset / transitionWindowSeconds).clamp(0.0, 1.0);
      final outgoing = activeIndex > 0 ? reel.segments[activeIndex - 1] : null;
      return TvTransitionOverlayState(
        isActive: true,
        transitionType: activeSegment.transitionIn,
        progress: rawProgress,
        incomingSegment: activeSegment,
        outgoingSegment: outgoing,
      );
    }

    return const TvTransitionOverlayState.idle();
  }

  /// Zwraca indeks aktywnego segmentu w [reel] dla danej sekundy odtwarzania.
  static int segmentIndexAt({
    required InstantHighlightReel reel,
    required double timelineSeconds,
  }) {
    if (reel.segments.isEmpty) return 0;
    final clamped = timelineSeconds.clamp(0.0, reel.totalDurationSeconds);
    for (var i = 0; i < reel.segments.length; i++) {
      final seg = reel.segments[i];
      final isLast = i == reel.segments.length - 1;
      if (clamped >= seg.startTimelineSecond &&
          (isLast ? clamped <= seg.endTimelineSecond : clamped < seg.endTimelineSecond)) {
        return i;
      }
    }
    return reel.segments.length - 1;
  }

  /// Formatuje czas osi w formacie `MM:SS`.
  static String formatTimestamp(double seconds) {
    final safe = seconds.isNaN || seconds.isInfinite ? 0.0 : seconds;
    final total = safe.round().clamp(0, 3599);
    final minutes = total ~/ 60;
    final secs = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Zwraca intensywność emocjonalną (0..1) w danej sekundzie z krzywej [pacingCurve].
  static double excitementAt({
    required InstantHighlightReel reel,
    required double timelineSeconds,
  }) {
    if (reel.pacingCurve.isEmpty) {
      return (reel.averageDramaScore / 100.0).clamp(0.2, 1.0);
    }
    final sorted = [...reel.pacingCurve]
      ..sort((a, b) => a.timelineSecond.compareTo(b.timelineSecond));
    if (timelineSeconds <= sorted.first.timelineSecond) {
      return sorted.first.excitementLevel.clamp(0.0, 1.0);
    }
    if (timelineSeconds >= sorted.last.timelineSecond) {
      return sorted.last.excitementLevel.clamp(0.0, 1.0);
    }
    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      if (timelineSeconds >= a.timelineSecond &&
          timelineSeconds <= b.timelineSecond) {
        final span = b.timelineSecond - a.timelineSecond;
        if (span <= 0.0001) return a.excitementLevel.clamp(0.0, 1.0);
        final t = (timelineSeconds - a.timelineSecond) / span;
        return (a.excitementLevel + (b.excitementLevel - a.excitementLevel) * t)
            .clamp(0.0, 1.0);
      }
    }
    return 0.5;
  }
}

/// Rysuje telewizyjne grafiki przejść między ujęciami (Whoosh Cut, Cross Dissolve, Gold Wipe, Slam Zoom).
class TvBroadcastTransitionPainter extends CustomPainter {
  final TvTransitionOverlayState transition;
  final TvBroadcastGraphicsTheme theme;

  const TvBroadcastTransitionPainter({
    required this.transition,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!transition.isActive || size.isEmpty) return;

    final p = transition.progress.clamp(0.0, 1.0);
    final envelope = math.sin(p * math.pi).clamp(0.0, 1.0);
    final accent = transition.incomingSegment?.role.accentColor ?? theme.accentColor;

    switch (transition.transitionType) {
      case HighlightTransitionType.whooshCut:
        _paintWhooshCut(canvas, size, p, envelope, accent);
      case HighlightTransitionType.crossDissolve:
        _paintCrossDissolve(canvas, size, p, envelope, accent);
      case HighlightTransitionType.wipeGoldBar:
        _paintWipeGoldBar(canvas, size, p, envelope, accent);
      case HighlightTransitionType.slamZoom:
        _paintSlamZoom(canvas, size, p, envelope, accent);
    }
  }

  void _paintWhooshCut(
    Canvas canvas,
    Size size,
    double p,
    double envelope,
    Color accent,
  ) {
    final sweepX = -size.width * 0.35 + p * (size.width * 1.7);
    final skewOffset = size.height * 0.24;

    // Pasy prędkości (motion-blur slash).
    for (var i = 0; i < 4; i++) {
      final widthFactor = 0.07 + i * 0.035;
      final barW = size.width * widthFactor;
      final x = sweepX - i * (barW * 0.9);
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + barW, 0)
        ..lineTo(x + barW - skewOffset, size.height)
        ..lineTo(x - skewOffset, size.height)
        ..close();

      final color = i == 0
          ? Colors.white.withValues(alpha: 0.42 * envelope)
          : i == 1
              ? accent.withValues(alpha: 0.72 * envelope)
              : AppColors.surface.withValues(alpha: 0.65 * envelope);
      canvas.drawPath(path, Paint()..color = color);
    }

    // Poziome smugi ruchu.
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.55 * envelope)
      ..strokeWidth = 2.0;
    for (var row = 1; row <= 5; row++) {
      final y = size.height * (row / 6.0);
      canvas.drawLine(
        Offset((sweepX - 180).clamp(0.0, size.width), y),
        Offset((sweepX + 40).clamp(0.0, size.width), y),
        linePaint,
      );
    }
  }

  void _paintCrossDissolve(
    Canvas canvas,
    Size size,
    double p,
    double envelope,
    Color accent,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = math.max(size.width, size.height) * (0.45 + p * 0.4);
    final shader = RadialGradient(
      colors: [
        accent.withValues(alpha: 0.28 * envelope),
        AppColors.background.withValues(alpha: 0.62 * envelope),
        AppColors.background.withValues(alpha: 0.85 * envelope),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _paintWipeGoldBar(
    Canvas canvas,
    Size size,
    double p,
    double envelope,
    Color accent,
  ) {
    final leadingX = -size.width * 0.25 + p * (size.width * 1.55);
    final skew = size.height * 0.18;

    // Ciemna kurtyna za złotą belką.
    final curtainPath = Path()
      ..moveTo(leadingX - size.width * 0.22, 0)
      ..lineTo(leadingX, 0)
      ..lineTo(leadingX - skew, size.height)
      ..lineTo(leadingX - size.width * 0.22 - skew, size.height)
      ..close();
    canvas.drawPath(
      curtainPath,
      Paint()..color = AppColors.background.withValues(alpha: 0.88 * envelope),
    );

    // Bordowy pas pomocniczy.
    final burgundyW = size.width * 0.055;
    final burgundyPath = Path()
      ..moveTo(leadingX - burgundyW, 0)
      ..lineTo(leadingX, 0)
      ..lineTo(leadingX - skew, size.height)
      ..lineTo(leadingX - burgundyW - skew, size.height)
      ..close();
    canvas.drawPath(
      burgundyPath,
      Paint()..color = AppColors.primaryAccent.withValues(alpha: 0.92 * envelope),
    );

    // Główna złota belka ASO / Tour de France.
    final goldW = size.width * 0.032;
    final goldPath = Path()
      ..moveTo(leadingX, 0)
      ..lineTo(leadingX + goldW, 0)
      ..lineTo(leadingX + goldW - skew, size.height)
      ..lineTo(leadingX - skew, size.height)
      ..close();
    canvas.drawPath(
      goldPath,
      Paint()..color = AppColors.goldAccent.withValues(alpha: 0.96 * envelope),
    );
  }

  void _paintSlamZoom(
    Canvas canvas,
    Size size,
    double p,
    double envelope,
    Color accent,
  ) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height) * 0.55;

    // Winieta uderzenia.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background.withValues(alpha: 0.36 * envelope),
    );

    // Koncentryczne pierścienie celownika kamery.
    for (var i = 0; i < 3; i++) {
      final ringProgress = ((p + i * 0.16) % 1.0);
      final r = maxR * (1.0 - ringProgress * 0.72);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 - i * 0.5
          ..color = accent.withValues(alpha: 0.65 * envelope),
      );
    }

    // Narożniki kadru wizjera kamery.
    final bracketLen = math.min(size.width, size.height) * 0.08;
    final inset = 18.0 + (1.0 - p) * 26.0;
    final bracketPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.9 * envelope)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Lewy górny
    canvas.drawPath(
      Path()
        ..moveTo(inset, inset + bracketLen)
        ..lineTo(inset, inset)
        ..lineTo(inset + bracketLen, inset),
      bracketPaint,
    );
    // Prawy górny
    canvas.drawPath(
      Path()
        ..moveTo(size.width - inset - bracketLen, inset)
        ..lineTo(size.width - inset, inset)
        ..lineTo(size.width - inset, inset + bracketLen),
      bracketPaint,
    );
    // Lewy dolny
    canvas.drawPath(
      Path()
        ..moveTo(inset, size.height - inset - bracketLen)
        ..lineTo(inset, size.height - inset)
        ..lineTo(inset + bracketLen, size.height - inset),
      bracketPaint,
    );
    // Prawy dolny
    canvas.drawPath(
      Path()
        ..moveTo(size.width - inset - bracketLen, size.height - inset)
        ..lineTo(size.width - inset, size.height - inset)
        ..lineTo(size.width - inset, size.height - inset - bracketLen),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TvBroadcastTransitionPainter oldDelegate) {
    return oldDelegate.transition.isActive != transition.isActive ||
        oldDelegate.transition.progress != transition.progress ||
        oldDelegate.transition.transitionType != transition.transitionType ||
        oldDelegate.theme != theme;
  }
}

/// Rysuje interaktywną oś czasu 45s z krzywą napięcia (pacing curve) i znacznikami segmentów.
class TvPacingCurveTimelinePainter extends CustomPainter {
  final InstantHighlightReel reel;
  final double playbackPositionSeconds;
  final double? hoverTimelineSeconds;
  final TvBroadcastGraphicsTheme theme;

  const TvPacingCurveTimelinePainter({
    required this.reel,
    required this.playbackPositionSeconds,
    required this.hoverTimelineSeconds,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final total = math.max(1.0, reel.totalDurationSeconds);
    const trackHeight = 8.0;
    final trackTop = size.height - trackHeight - 4.0;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackTop, size.width, trackHeight),
      const Radius.circular(4),
    );

    // Tło osi czasu.
    canvas.drawRRect(
      trackRect,
      Paint()..color = AppColors.surfaceLight,
    );

    // Wykres napięcia (pacingCurve) nad osią.
    final curveHeight = (trackTop - 6.0).clamp(8.0, 28.0);
    if (reel.pacingCurve.length >= 2) {
      final sorted = [...reel.pacingCurve]
        ..sort((a, b) => a.timelineSecond.compareTo(b.timelineSecond));
      final areaPath = Path()..moveTo(0, trackTop - 2.0);
      final linePath = Path();
      for (var i = 0; i < sorted.length; i++) {
        final cue = sorted[i];
        final x = (cue.timelineSecond / total).clamp(0.0, 1.0) * size.width;
        final y = (trackTop - 2.0) - cue.excitementLevel.clamp(0.0, 1.0) * curveHeight;
        areaPath.lineTo(x, y);
        if (i == 0) {
          linePath.moveTo(x, y);
        } else {
          linePath.lineTo(x, y);
        }
      }
      areaPath
        ..lineTo(size.width, trackTop - 2.0)
        ..close();

      canvas.drawPath(
        areaPath,
        Paint()..color = theme.accentColor.withValues(alpha: 0.16),
      );
      canvas.drawPath(
        linePath,
        Paint()
          ..color = theme.accentColor.withValues(alpha: 0.65)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    // Pasek postępu odtwarzania.
    final progressRatio = (playbackPositionSeconds / total).clamp(0.0, 1.0);
    final progressWidth = size.width * progressRatio;
    if (progressWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, trackTop, progressWidth, trackHeight),
          const Radius.circular(4),
        ),
        Paint()..color = theme.accentColor,
      );
    }

    // Znaczniki granic segmentów na osi.
    for (var i = 0; i < reel.segments.length; i++) {
      final seg = reel.segments[i];
      final x = (seg.startTimelineSecond / total).clamp(0.0, 1.0) * size.width;
      if (i > 0) {
        canvas.drawLine(
          Offset(x, trackTop - 3.0),
          Offset(x, trackTop + trackHeight + 2.0),
          Paint()
            ..color = AppColors.background
            ..strokeWidth = 2.0,
        );
      }
      canvas.drawCircle(
        Offset(x.clamp(4.0, size.width - 4.0), trackTop + trackHeight * 0.5),
        2.5,
        Paint()..color = seg.role.accentColor,
      );
    }

    // Wskaźnik hover na osi czasu.
    if (hoverTimelineSeconds != null) {
      final hx = (hoverTimelineSeconds! / total).clamp(0.0, 1.0) * size.width;
      canvas.drawLine(
        Offset(hx, 2.0),
        Offset(hx, trackTop + trackHeight),
        Paint()
          ..color = AppColors.textPrimary.withValues(alpha: 0.45)
          ..strokeWidth = 1.0,
      );
    }

    // Głowica odtwarzania (playhead).
    final double headX =
        progressWidth.clamp(6.0, math.max(6.0, size.width - 6.0)).toDouble();
    canvas.drawCircle(
      Offset(headX, trackTop + trackHeight * 0.5),
      6.5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(headX, trackTop + trackHeight * 0.5),
      4.0,
      Paint()..color = theme.accentColor,
    );
  }

  @override
  bool shouldRepaint(covariant TvPacingCurveTimelinePainter oldDelegate) {
    return oldDelegate.playbackPositionSeconds != playbackPositionSeconds ||
        oldDelegate.hoverTimelineSeconds != hoverTimelineSeconds ||
        oldDelegate.theme != theme ||
        oldDelegate.reel.reelId != reel.reelId;
  }
}

/// Pełnoekranowy odtwarzacz 45-sekundowego skrótu telewizyjnego z grafikami przejść TV.
class TvHighlightReelPlayerOverlay extends StatefulWidget {
  final InstantHighlightReel? reel;
  final bool isEnabled;
  final bool autoPlay;
  final bool initialShowBroadcastHud;
  final TvBroadcastGraphicsTheme initialTheme;
  final VoidCallback? onClose;
  final VoidCallback? onGenerateReelRequested;
  final ValueChanged<HighlightClipSegment>? onSegmentChanged;
  final VoidCallback? onExportScriptRequested;

  const TvHighlightReelPlayerOverlay({
    super.key,
    required this.reel,
    this.isEnabled = true,
    this.autoPlay = false,
    this.initialShowBroadcastHud = true,
    this.initialTheme = TvBroadcastGraphicsTheme.worldFeedGold,
    this.onClose,
    this.onGenerateReelRequested,
    this.onSegmentChanged,
    this.onExportScriptRequested,
  });

  @override
  State<TvHighlightReelPlayerOverlay> createState() =>
      _TvHighlightReelPlayerOverlayState();
}

class _TvHighlightReelPlayerOverlayState
    extends State<TvHighlightReelPlayerOverlay> with SingleTickerProviderStateMixin {
  Timer? _playbackTimer;
  late final AnimationController _manualTransitionController;
  late final FocusNode _keyboardFocusNode;

  double _playbackPositionSeconds = 0.0;
  bool _isPlaying = false;
  bool _isLooping = true;
  bool _isMuted = false;
  late bool _showBroadcastHud;
  TvHighlightPlayerPlaybackSpeed _speed = TvHighlightPlayerPlaybackSpeed.x10;
  late TvBroadcastGraphicsTheme _theme;
  int _lastSegmentIndex = -1;
  double? _hoverTimelineSeconds;
  String? _statusFeedback;
  HighlightTransitionType _manualTransitionType =
      HighlightTransitionType.wipeGoldBar;
  HighlightClipSegment? _manualIncomingSegment;

  @override
  void initState() {
    super.initState();
    _showBroadcastHud = widget.initialShowBroadcastHud;
    _theme = widget.initialTheme;
    _keyboardFocusNode = FocusNode();
    _manualTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    if (widget.autoPlay && widget.isEnabled && _hasPlayableReel) {
      _startPlayback();
    }
  }

  @override
  void didUpdateWidget(covariant TvHighlightReelPlayerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reel?.reelId != widget.reel?.reelId) {
      _stopPlayback();
      _playbackPositionSeconds = 0.0;
      _lastSegmentIndex = -1;
      if (widget.autoPlay && widget.isEnabled && _hasPlayableReel) {
        _startPlayback();
      }
    }
    if (!widget.isEnabled && _isPlaying) {
      _stopPlayback();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _manualTransitionController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  bool get _hasPlayableReel =>
      widget.reel != null && !widget.reel!.isEmpty && widget.reel!.segments.isNotEmpty;

  void _startPlayback() {
    if (!widget.isEnabled || !_hasPlayableReel) return;
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = true;
      if (_playbackPositionSeconds >= widget.reel!.totalDurationSeconds) {
        _playbackPositionSeconds = 0.0;
      }
    });
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _onTick(0.05),
    );
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (mounted && _isPlaying) {
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayPause() {
    if (!widget.isEnabled || !_hasPlayableReel) return;
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _onTick(double deltaSeconds) {
    if (!mounted || !_hasPlayableReel) return;
    final reel = widget.reel!;
    final nextPos = _playbackPositionSeconds + deltaSeconds * _speed.multiplier;

    if (nextPos >= reel.totalDurationSeconds) {
      if (_isLooping) {
        _seekTo(0.0, triggerTransition: true);
      } else {
        setState(() {
          _playbackPositionSeconds = reel.totalDurationSeconds;
          _isPlaying = false;
        });
        _playbackTimer?.cancel();
        _playbackTimer = null;
      }
      return;
    }

    final nextIndex = TvHighlightTransitionCalculator.segmentIndexAt(
      reel: reel,
      timelineSeconds: nextPos,
    );
    setState(() {
      _playbackPositionSeconds = nextPos;
      if (nextIndex != _lastSegmentIndex) {
        _lastSegmentIndex = nextIndex;
        widget.onSegmentChanged?.call(reel.segments[nextIndex]);
      }
    });
  }

  void _seekTo(double seconds, {bool triggerTransition = false}) {
    if (!widget.isEnabled || !_hasPlayableReel) return;
    final reel = widget.reel!;
    final clamped = seconds.clamp(0.0, reel.totalDurationSeconds);
    final newIndex = TvHighlightTransitionCalculator.segmentIndexAt(
      reel: reel,
      timelineSeconds: clamped,
    );
    final targetSeg = reel.segments[newIndex];

    setState(() {
      _playbackPositionSeconds = clamped;
      if (newIndex != _lastSegmentIndex) {
        _lastSegmentIndex = newIndex;
        widget.onSegmentChanged?.call(targetSeg);
      }
      if (triggerTransition) {
        _manualTransitionType = targetSeg.transitionIn;
        _manualIncomingSegment = targetSeg;
      }
    });

    if (triggerTransition) {
      _manualTransitionController.forward(from: 0.0);
    }
  }

  void _jumpToSegmentIndex(int index) {
    if (!widget.isEnabled || !_hasPlayableReel) return;
    final segments = widget.reel!.segments;
    final safeIndex = index.clamp(0, segments.length - 1);
    final target = segments[safeIndex];
    _seekTo(target.startTimelineSecond, triggerTransition: true);
  }

  void _previousSegment() {
    if (!widget.isEnabled || !_hasPlayableReel) return;
    final current = TvHighlightTransitionCalculator.segmentIndexAt(
      reel: widget.reel!,
      timelineSeconds: _playbackPositionSeconds,
    );
    _jumpToSegmentIndex(math.max(0, current - 1));
  }

  void _nextSegment() {
    if (!widget.isEnabled || !_hasPlayableReel) return;
    final reel = widget.reel!;
    final current = TvHighlightTransitionCalculator.segmentIndexAt(
      reel: reel,
      timelineSeconds: _playbackPositionSeconds,
    );
    final next = (current + 1) >= reel.segments.length ? 0 : current + 1;
    _jumpToSegmentIndex(next);
  }

  Future<void> _copyScriptToClipboard() async {
    if (!widget.isEnabled || !_hasPlayableReel) return;
    final summary = widget.reel!.exportBroadcastScriptSummary();
    await Clipboard.setData(ClipboardData(text: summary));
    widget.onExportScriptRequested?.call();
    if (!mounted) return;
    setState(() {
      _statusFeedback = 'Scenariusz TV skopiowany do schowka';
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose?.call();
      return KeyEventResult.handled;
    }
    if (!widget.isEnabled) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _previousSegment();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _nextSegment();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyH) {
      setState(() => _showBroadcastHud = !_showBroadcastHud);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyM) {
      setState(() => _isMuted = !_isMuted);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  TvTransitionOverlayState _resolveTransitionState(InstantHighlightReel reel) {
    if (_manualTransitionController.isAnimating) {
      return TvTransitionOverlayState(
        isActive: true,
        transitionType: _manualTransitionType,
        progress: Curves.easeOutCubic.transform(_manualTransitionController.value),
        incomingSegment: _manualIncomingSegment,
      );
    }
    return TvHighlightTransitionCalculator.evaluateAtTimeline(
      reel: reel,
      timelineSeconds: _playbackPositionSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        color: AppColors.background.withValues(alpha: 0.94),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactMobile = constraints.maxWidth < 680;
              final isTablet =
                  constraints.maxWidth >= 680 && constraints.maxWidth < 1150;
              final outerPadding = isCompactMobile ? 12.0 : 20.0;

              return Padding(
                padding: EdgeInsets.all(outerPadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopHeader(isCompactMobile),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      Expanded(
                        child: !_hasPlayableReel
                            ? _buildEmptyState(isCompactMobile)
                            : _buildPlayerBody(
                                isCompactMobile: isCompactMobile,
                                isTablet: isTablet,
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isCompact) {
    final reel = widget.reel;
    final titleText = reel != null
        ? 'ETAP ${reel.stageNumber} • ${reel.stageName}'
        : 'STUDIO SKRÓTÓW TELEWIZYJNYCH';
    final subtitleText = reel != null
        ? '${reel.raceName} • ${reel.stageDistanceKm.toStringAsFixed(1)} km • ${reel.broadcastNetworkName}'
        : 'Brak aktywnego skrótu 45s do odtworzenia';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 18,
        vertical: isCompact ? 10 : 12,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _theme.accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _theme.accentColor.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.live_tv_rounded,
                  size: 15,
                  color: _theme.accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'TV REEL 45s',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: _theme.accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isCompact && _statusFeedback != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusSuccess.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.statusSuccess.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _statusFeedback!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusSuccess,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _TvInteractivePillButton(
            tooltip: _showBroadcastHud ? 'Ukryj grafikę TV (H)' : 'Pokaż grafikę TV (H)',
            icon: _showBroadcastHud
                ? Icons.subtitles_rounded
                : Icons.subtitles_off_rounded,
            label: isCompact ? null : (_showBroadcastHud ? 'HUD ON' : 'HUD OFF'),
            isActive: _showBroadcastHud,
            isEnabled: widget.isEnabled && _hasPlayableReel,
            accentColor: _theme.accentColor,
            onPressed: () {
              setState(() => _showBroadcastHud = !_showBroadcastHud);
            },
          ),
          const SizedBox(width: 8),
          _TvInteractivePillButton(
            tooltip: 'Zamknij odtwarzacz (Esc)',
            icon: Icons.close_rounded,
            label: isCompact ? null : 'Zamknij',
            isActive: false,
            isEnabled: widget.onClose != null,
            accentColor: AppColors.crimsonAlert,
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isCompact) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isCompact ? 20 : 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(
                    Icons.videocam_off_rounded,
                    color: AppColors.goldAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Brak skrótu telewizyjnego z etapu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ukończ etap lub uruchom montaż automatycznego 45-sekundowego skrótu TV, aby obejrzeć ujęcia z przejściami transmisji.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.onGenerateReelRequested != null) ...[
                  const SizedBox(height: 18),
                  _TvInteractivePillButton(
                    tooltip: 'Wygeneruj skrót 45s',
                    icon: Icons.auto_awesome_rounded,
                    label: 'Zmontuj skrót 45s',
                    isActive: true,
                    isEnabled: widget.isEnabled,
                    accentColor: AppColors.goldAccent,
                    onPressed: widget.onGenerateReelRequested,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerBody({
    required bool isCompactMobile,
    required bool isTablet,
  }) {
    final reel = widget.reel!;
    final activeIndex = TvHighlightTransitionCalculator.segmentIndexAt(
      reel: reel,
      timelineSeconds: _playbackPositionSeconds,
    );
    final activeSegment = reel.segments[activeIndex];

    if (isCompactMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBroadcastViewport(
              reel: reel,
              activeSegment: activeSegment,
              activeIndex: activeIndex,
              isCompact: true,
            ),
            const SizedBox(height: 10),
            _buildTimelineAndControls(
              reel: reel,
              activeSegment: activeSegment,
              isCompact: true,
            ),
            const SizedBox(height: 12),
            _buildChapterRail(
              reel: reel,
              activeIndex: activeIndex,
              isVerticalList: false,
            ),
          ],
        ),
      );
    }

    final sidebarWidth = isTablet ? 276.0 : 332.0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildBroadcastViewport(
                    reel: reel,
                    activeSegment: activeSegment,
                    activeIndex: activeIndex,
                    isCompact: false,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTimelineAndControls(
                  reel: reel,
                  activeSegment: activeSegment,
                  isCompact: false,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: sidebarWidth,
            child: _buildChapterRail(
              reel: reel,
              activeIndex: activeIndex,
              isVerticalList: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastViewport({
    required InstantHighlightReel reel,
    required HighlightClipSegment activeSegment,
    required int activeIndex,
    required bool isCompact,
  }) {
    final viewportContent = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 1.0),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Warstwa bazowa sceny wyścigu z #636.
            CustomPaint(
              painter: BroadcastHighlightViewportPainter(
                reel: reel,
                activeSegment: activeSegment,
                playbackPositionSeconds: _playbackPositionSeconds,
              ),
            ),
            // Nakładki transmisji TV (bug stacji, kamera, lower-third).
            if (_showBroadcastHud)
              _buildBroadcastHudOverlay(
                reel: reel,
                activeSegment: activeSegment,
                activeIndex: activeIndex,
                isCompact: isCompact,
              ),
            // Grafika przejścia TV (Whoosh / Dissolve / Gold Wipe / Slam Zoom).
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _manualTransitionController,
                builder: (context, _) {
                  final currentTransition = _resolveTransitionState(reel);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: TvBroadcastTransitionPainter(
                          transition: currentTransition,
                          theme: _theme,
                        ),
                      ),
                      if (currentTransition.isActive)
                        _buildTransitionStingerBadge(currentTransition, isCompact),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (isCompact) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: viewportContent,
      );
    }
    return viewportContent;
  }

  Widget _buildTransitionStingerBadge(
    TvTransitionOverlayState transition,
    bool isCompact,
  ) {
    final seg = transition.incomingSegment;
    if (seg == null) return const SizedBox.shrink();
    final opacity = math.sin(transition.progress.clamp(0.0, 1.0) * math.pi).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 18,
            vertical: isCompact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _theme.accentColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.movie_filter_rounded,
                size: isCompact ? 14 : 18,
                color: _theme.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${seg.transitionIn.label.toUpperCase()} • ${seg.cameraAngle.hudTag}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 10 : 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBroadcastHudOverlay({
    required InstantHighlightReel reel,
    required HighlightClipSegment activeSegment,
    required int activeIndex,
    required bool isCompact,
  }) {
    final lt = activeSegment.lowerThird;
    final accent = activeSegment.role.accentColor;

    return Padding(
      padding: EdgeInsets.all(isCompact ? 8 : 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Górny pasek transmisji (bug stacji + kamera + km).
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _theme.accentColor.withValues(alpha: 0.65),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isPlaying
                            ? AppColors.crimsonAlert
                            : _theme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeSegment.cameraAngle.hudTag,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    isCompact
                        ? 'KM ${activeSegment.kilometerMark.toStringAsFixed(1)} • -${activeSegment.remainingKm.toStringAsFixed(1)} KM'
                        : 'KM ${activeSegment.kilometerMark.toStringAsFixed(1)} • DO METY ${activeSegment.remainingKm.toStringAsFixed(1)} KM',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Dolna belka telewizyjna (Lower-Third + Komentarz lektora).
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 14,
                  vertical: isCompact ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.75),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${activeIndex + 1}/${reel.segments.length} ${lt.badgeText}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lt.primaryTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: isCompact ? 12 : 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!isCompact) ..._buildLowerThirdMetrics(activeSegment),
                      ],
                    ),
                    if (lt.secondarySubtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        lt.secondarySubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompact ? 10 : 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (!isCompact && activeSegment.commentaryLine.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        '"${activeSegment.commentaryLine}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLowerThirdMetrics(HighlightClipSegment segment) {
    final lt = segment.lowerThird;
    final widgets = <Widget>[];
    if (lt.riderSpeedKmh != null) {
      widgets.add(_metricChip('${lt.riderSpeedKmh!.toStringAsFixed(1)} km/h', AppColors.accentBlue));
    }
    if (lt.riderPowerWatts != null) {
      widgets.add(const SizedBox(width: 6));
      widgets.add(_metricChip('${lt.riderPowerWatts} W', AppColors.goldAccent));
    }
    if (lt.gradientPercent != null && lt.gradientPercent!.abs() >= 1.0) {
      widgets.add(const SizedBox(width: 6));
      widgets.add(_metricChip('${lt.gradientPercent!.toStringAsFixed(1)}%', AppColors.amberWarning));
    }
    return widgets;
  }

  Widget _metricChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: color,
        ),
      ),
    );
  }

  Widget _buildTimelineAndControls({
    required InstantHighlightReel reel,
    required HighlightClipSegment activeSegment,
    required bool isCompact,
  }) {
    final total = math.max(1.0, reel.totalDurationSeconds);
    final currentText =
        TvHighlightTransitionCalculator.formatTimestamp(_playbackPositionSeconds);
    final totalText = TvHighlightTransitionCalculator.formatTimestamp(total);

    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Interaktywna oś czasu z krzywą napięcia.
          Row(
            children: [
              Text(
                currentText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    return MouseRegion(
                      onHover: widget.isEnabled
                          ? (event) {
                              final ratio = (event.localPosition.dx /
                                      math.max(1.0, box.maxWidth))
                                  .clamp(0.0, 1.0);
                              setState(() {
                                _hoverTimelineSeconds = ratio * total;
                              });
                            }
                          : null,
                      onExit: (_) {
                        if (_hoverTimelineSeconds != null) {
                          setState(() => _hoverTimelineSeconds = null);
                        }
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: widget.isEnabled
                            ? (details) {
                                final ratio = (details.localPosition.dx /
                                        math.max(1.0, box.maxWidth))
                                    .clamp(0.0, 1.0);
                                _seekTo(ratio * total, triggerTransition: true);
                              }
                            : null,
                        onHorizontalDragUpdate: widget.isEnabled
                            ? (details) {
                                final ratio = (details.localPosition.dx /
                                        math.max(1.0, box.maxWidth))
                                    .clamp(0.0, 1.0);
                                _seekTo(ratio * total);
                              }
                            : null,
                        child: SizedBox(
                          height: 38,
                          child: CustomPaint(
                            painter: TvPacingCurveTimelinePainter(
                              reel: reel,
                              playbackPositionSeconds: _playbackPositionSeconds,
                              hoverTimelineSeconds: _hoverTimelineSeconds,
                              theme: _theme,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                totalText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Pasek przycisków sterowania odtwarzaczem.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TvInteractivePillButton(
                    tooltip: 'Poprzednie ujęcie (Strzałka w lewo)',
                    icon: Icons.skip_previous_rounded,
                    isActive: false,
                    isEnabled: widget.isEnabled,
                    accentColor: _theme.accentColor,
                    onPressed: _previousSegment,
                  ),
                  _TvInteractivePillButton(
                    tooltip: _isPlaying ? 'Pauza (Spacja)' : 'Odtwórz (Spacja)',
                    icon: _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: _isPlaying ? 'Pauza' : 'Odtwórz',
                    isActive: true,
                    isEnabled: widget.isEnabled,
                    accentColor: _theme.accentColor,
                    onPressed: _togglePlayPause,
                  ),
                  _TvInteractivePillButton(
                    tooltip: 'Następne ujęcie (Strzałka w prawo)',
                    icon: Icons.skip_next_rounded,
                    isActive: false,
                    isEnabled: widget.isEnabled,
                    accentColor: _theme.accentColor,
                    onPressed: _nextSegment,
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TvInteractivePillButton(
                    tooltip: 'Zmień prędkość odtwarzania',
                    icon: Icons.speed_rounded,
                    label: _speed.label,
                    isActive: _speed != TvHighlightPlayerPlaybackSpeed.x10,
                    isEnabled: widget.isEnabled,
                    accentColor: AppColors.accentBlue,
                    onPressed: () {
                      setState(() => _speed = _speed.next);
                    },
                  ),
                  _TvInteractivePillButton(
                    tooltip: 'Zmień styl grafik TV',
                    icon: Icons.palette_rounded,
                    label: isCompact ? null : _theme.label,
                    isActive: true,
                    isEnabled: widget.isEnabled,
                    accentColor: _theme.accentColor,
                    onPressed: () {
                      setState(() => _theme = _theme.next);
                    },
                  ),
                  _TvInteractivePillButton(
                    tooltip: _isLooping ? 'Zapętlanie włączone' : 'Zapętlanie wyłączone',
                    icon: Icons.repeat_rounded,
                    isActive: _isLooping,
                    isEnabled: widget.isEnabled,
                    accentColor: AppColors.statusSuccess,
                    onPressed: () {
                      setState(() => _isLooping = !_isLooping);
                    },
                  ),
                  _TvInteractivePillButton(
                    tooltip: _isMuted ? 'Włącz dźwięk TV (M)' : 'Wycisz dźwięk TV (M)',
                    icon: _isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    isActive: !_isMuted,
                    isEnabled: widget.isEnabled,
                    accentColor: AppColors.textPrimary,
                    onPressed: () {
                      setState(() => _isMuted = !_isMuted);
                    },
                  ),
                  _TvInteractivePillButton(
                    tooltip: 'Kopiuj scenariusz montażowy TV',
                    icon: Icons.copy_all_rounded,
                    label: isCompact ? null : 'Skrypt',
                    isActive: false,
                    isEnabled: widget.isEnabled,
                    accentColor: AppColors.goldAccent,
                    onPressed: _copyScriptToClipboard,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterRail({
    required InstantHighlightReel reel,
    required int activeIndex,
    required bool isVerticalList,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: isVerticalList ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.view_timeline_rounded, size: 16, color: _theme.accentColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'LISTA UJĘĆ I PRZEJŚĆ TV',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${reel.segments.length} klipy',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isVerticalList)
            Expanded(
              child: ListView.separated(
                itemCount: reel.segments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _TvChapterSegmentTile(
                    segment: reel.segments[index],
                    index: index,
                    isSelected: index == activeIndex,
                    isEnabled: widget.isEnabled,
                    accentColor: _theme.accentColor,
                    onTap: () => _jumpToSegmentIndex(index),
                  );
                },
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < reel.segments.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _TvChapterSegmentTile(
                    segment: reel.segments[i],
                    index: i,
                    isSelected: i == activeIndex,
                    isEnabled: widget.isEnabled,
                    accentColor: _theme.accentColor,
                    onTap: () => _jumpToSegmentIndex(i),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TvChapterSegmentTile extends StatefulWidget {
  final HighlightClipSegment segment;
  final int index;
  final bool isSelected;
  final bool isEnabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _TvChapterSegmentTile({
    required this.segment,
    required this.index,
    required this.isSelected,
    required this.isEnabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_TvChapterSegmentTile> createState() => _TvChapterSegmentTileState();
}

class _TvChapterSegmentTileState extends State<_TvChapterSegmentTile> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final seg = widget.segment;
    final roleColor = seg.role.accentColor;

    final Color bgColor;
    if (!widget.isEnabled) {
      bgColor = AppColors.surface.withValues(alpha: 0.45);
    } else if (widget.isSelected) {
      bgColor = widget.accentColor.withValues(alpha: 0.14);
    } else if (_isPressed) {
      bgColor = AppColors.background;
    } else if (_isHovered) {
      bgColor = AppColors.surface.withValues(alpha: 0.95);
    } else {
      bgColor = AppColors.surface;
    }

    final borderColor = !widget.isEnabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : widget.isSelected
            ? widget.accentColor
            : _isFocused
                ? AppColors.accentBlue
                : _isHovered
                    ? roleColor.withValues(alpha: 0.65)
                    : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected || _isFocused ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '#${widget.index + 1} ${seg.role.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    seg.formattedTimelineWindow,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                seg.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.isEnabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.auto_fix_high_rounded,
                    size: 12,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${seg.transitionIn.label} • ${seg.cameraAngle.hudTag}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'KM ${seg.kilometerMark.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TvInteractivePillButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final String? label;
  final bool isActive;
  final bool isEnabled;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _TvInteractivePillButton({
    required this.tooltip,
    required this.icon,
    this.label,
    required this.isActive,
    required this.isEnabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_TvInteractivePillButton> createState() =>
      _TvInteractivePillButtonState();
}

class _TvInteractivePillButtonState extends State<_TvInteractivePillButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeEnabled = widget.isEnabled && widget.onPressed != null;

    final Color bg;
    if (!activeEnabled) {
      bg = AppColors.surface.withValues(alpha: 0.4);
    } else if (_isPressed) {
      bg = widget.accentColor.withValues(alpha: 0.28);
    } else if (widget.isActive) {
      bg = widget.accentColor.withValues(alpha: _isHovered ? 0.24 : 0.16);
    } else {
      bg = _isHovered ? AppColors.surface : AppColors.background;
    }

    final border = !activeEnabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.accentBlue
            : widget.isActive || _isHovered
                ? widget.accentColor.withValues(alpha: 0.85)
                : AppTheme.borderColor;

    final fg = !activeEnabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.isActive
            ? widget.accentColor
            : AppColors.textPrimary;

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: activeEnabled,
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        child: GestureDetector(
          onTapDown: activeEnabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: activeEnabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: activeEnabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.label != null ? 11 : 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: fg),
                if (widget.label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Otwiera pełnoekranową nakładkę odtwarzacza skrótu telewizyjnego 45s z animacją przejścia.
Future<void> showTvHighlightReelPlayerOverlay(
  BuildContext context, {
  required InstantHighlightReel? reel,
  bool autoPlay = true,
  bool isEnabled = true,
  TvBroadcastGraphicsTheme initialTheme = TvBroadcastGraphicsTheme.worldFeedGold,
  VoidCallback? onGenerateReelRequested,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Zamknij odtwarzacz skrótu TV',
    barrierColor: AppColors.background.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return TvHighlightReelPlayerOverlay(
        reel: reel,
        autoPlay: autoPlay,
        isEnabled: isEnabled,
        initialTheme: initialTheme,
        onGenerateReelRequested: onGenerateReelRequested,
        onClose: () => Navigator.of(dialogContext).pop(),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
