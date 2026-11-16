import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Kierunek osi dla subtelnych przejść [SharedAxisTransition] w panelach menedżera.
enum SharedAxisDirection {
  horizontal,
  vertical,
  scaled,
}

/// Predefiniowane tryby przejść między ekranami w [AnimatedScreenTransitionRouter].
enum ScreenTransitionPreset {
  managerSharedAxisHorizontal(
    id: 'manager_horizontal',
    label: 'SharedAxis Poziomy (300 ms)',
    shortLabel: 'Poziomy',
    description: 'Przejście między modułami menedżera z krzywą easeOutExpo.',
    duration: AnimatedScreenTransitionRouter.managerTransitionDuration,
  ),
  managerSharedAxisVertical(
    id: 'manager_vertical',
    label: 'SharedAxis Pionowy (300 ms)',
    shortLabel: 'Pionowy',
    description: 'Pionowe przejście dla widoków detali i podmenu.',
    duration: AnimatedScreenTransitionRouter.managerTransitionDuration,
  ),
  managerSharedAxisScaled(
    id: 'manager_scaled',
    label: 'SharedAxis Skalowany (300 ms)',
    shortLabel: 'Skala',
    description: 'Subtelne zbliżenie w głąb dla ekranów analitycznych.',
    duration: AnimatedScreenTransitionRouter.managerTransitionDuration,
  ),
  aerialToRoadDive3d(
    id: 'aerial_dive_3d',
    label: 'Najazd Kamery 3D z Lotu Ptaka',
    shortLabel: 'Lot Ptaka -> 3D',
    description:
        'Kinematograficzny zjazd kamery z helikoptera na szosę z odprawy do wyścigu.',
    duration: AnimatedScreenTransitionRouter.aerialDiveDuration,
  ),
  podiumCeremonyReveal(
    id: 'podium_reveal',
    label: 'Odsłona Podium Mistrzów',
    shortLabel: 'Podium',
    description: 'Złote rozświetlenie i wejście na ceremonię dekoracji.',
    duration: AnimatedScreenTransitionRouter.podiumRevealDuration,
  ),
  instant(
    id: 'instant',
    label: 'Natychmiastowy (Reduced Motion)',
    shortLabel: 'Natychmiastowy',
    description: 'Natychmiastowa zmiana ekranu bez ruchu perspektywicznego.',
    duration: Duration.zero,
  );

  const ScreenTransitionPreset({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.duration,
  });

  final String id;
  final String label;
  final String shortLabel;
  final String description;
  final Duration duration;
}

/// Zestaw płynnych przejść między ekranami dla [GoRouter] w Pro Peloton Manager.
///
/// Zapewnia:
/// - Subtelne przejścia [SharedAxisTransition] (300 ms, [Curves.easeOutExpo])
///   w panelach menedżera wewnątrz `ShellRoute`.
/// - Kinematograficzne przejście z odprawy przedstartowej do wyścigu 3D z efektem
///   najazdu kamery z lotu ptaka na szosę.
/// - Złotą odsłonę podium po etapie oraz pełne wsparcie dla `disableAnimations`.
class AnimatedScreenTransitionRouter {
  AnimatedScreenTransitionRouter._();

  /// Czas trwania przejść w panelach menedżera (300 ms zgodnie ze specyfikacją).
  static const Duration managerTransitionDuration = Duration(milliseconds: 300);

  /// Czas trwania kinematograficznego najazdu kamery z lotu ptaka do wyścigu 3D.
  static const Duration aerialDiveDuration = Duration(milliseconds: 850);

  /// Czas trwania przejścia na ekran podium po etapie.
  static const Duration podiumRevealDuration = Duration(milliseconds: 550);

  /// Domyślna krzywa wygaszania dla przejść paneli menedżera.
  static const Curve defaultCurve = Curves.easeOutExpo;

  /// Buduje stronę [CustomTransitionPage] z przejściem [SharedAxisTransition]
  /// (domyślnie 300 ms, [Curves.easeOutExpo]) dla paneli menedżera.
  static CustomTransitionPage<T> buildManagerPage<T>({
    required GoRouterState state,
    required Widget child,
    SharedAxisDirection axis = SharedAxisDirection.horizontal,
    Duration duration = managerTransitionDuration,
    Curve curve = defaultCurve,
    bool maintainState = true,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: child,
      maintainState: maintainState,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
          return FadeTransition(opacity: animation, child: pageChild);
        }
        return buildSharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          axis: axis,
          curve: curve,
          child: pageChild,
        );
      },
    );
  }

  /// Buduje stronę [CustomTransitionPage] z efektem najazdu kamery z lotu ptaka
  /// na szosę przy przejściu z odprawy przedstartowej do widoku wyścigu 3D.
  static CustomTransitionPage<T> buildRaceDivePage<T>({
    required GoRouterState state,
    required Widget child,
    String? stageLabel,
    String? subtitle,
    Duration duration = aerialDiveDuration,
    bool showTelemetryOverlay = true,
    bool maintainState = true,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: child,
      maintainState: maintainState,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 420),
      transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
          return FadeTransition(opacity: animation, child: pageChild);
        }
        return buildAerialToRoadCameraDiveTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          stageLabel: stageLabel,
          subtitle: subtitle,
          showTelemetryOverlay: showTelemetryOverlay,
          child: pageChild,
        );
      },
    );
  }

  /// Buduje stronę [CustomTransitionPage] dla ceremonii podium po etapie.
  static CustomTransitionPage<T> buildPodiumRevealPage<T>({
    required GoRouterState state,
    required Widget child,
    Duration duration = podiumRevealDuration,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: state.name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
        if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
          return FadeTransition(opacity: animation, child: pageChild);
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutExpo,
          reverseCurve: Curves.easeInCubic,
        );
        final scale = Tween<double>(begin: 0.94, end: 1.0).animate(curved);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved);

        return Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(
                  scale: scale,
                  child: pageChild,
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: curved,
                builder: (context, _) {
                  final flashAlpha =
                      (math.sin(curved.value * math.pi) * 0.22).clamp(0.0, 0.22);
                  if (flashAlpha <= 0.005) return const SizedBox.shrink();
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.35),
                        radius: 1.1,
                        colors: [
                          AppColors.goldAccent.withValues(alpha: flashAlpha),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Uniwersalny dyspozytor tworzący stronę [Page] na podstawie [ScreenTransitionPreset].
  static Page<T> buildPageForPreset<T>({
    required GoRouterState state,
    required Widget child,
    required ScreenTransitionPreset preset,
    String? stageLabel,
    String? subtitle,
  }) {
    switch (preset) {
      case ScreenTransitionPreset.managerSharedAxisHorizontal:
        return buildManagerPage<T>(
          state: state,
          child: child,
          axis: SharedAxisDirection.horizontal,
        );
      case ScreenTransitionPreset.managerSharedAxisVertical:
        return buildManagerPage<T>(
          state: state,
          child: child,
          axis: SharedAxisDirection.vertical,
        );
      case ScreenTransitionPreset.managerSharedAxisScaled:
        return buildManagerPage<T>(
          state: state,
          child: child,
          axis: SharedAxisDirection.scaled,
        );
      case ScreenTransitionPreset.aerialToRoadDive3d:
        return buildRaceDivePage<T>(
          state: state,
          child: child,
          stageLabel: stageLabel,
          subtitle: subtitle,
        );
      case ScreenTransitionPreset.podiumCeremonyReveal:
        return buildPodiumRevealPage<T>(state: state, child: child);
      case ScreenTransitionPreset.instant:
        return NoTransitionPage<T>(key: state.pageKey, child: child);
    }
  }

  /// Implementacja [SharedAxisTransition] bez zewnętrznych zależności,
  /// zsynchronizowana z [Curves.easeOutExpo] (300 ms).
  static Widget buildSharedAxisTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    SharedAxisDirection axis = SharedAxisDirection.horizontal,
    Curve curve = defaultCurve,
  }) {
    final enterCurved = CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: Curves.easeInCubic,
    );
    final exitCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: curve,
      reverseCurve: Curves.easeInCubic,
    );

    final enterOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.08, 0.85, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );
    final exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    Widget transformedChild = child;

    switch (axis) {
      case SharedAxisDirection.horizontal:
        final enterSlide = Tween<Offset>(
          begin: const Offset(0.045, 0.0),
          end: Offset.zero,
        ).animate(enterCurved);
        final exitSlide = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.035, 0.0),
        ).animate(exitCurved);
        transformedChild = SlideTransition(
          position: exitSlide,
          child: SlideTransition(
            position: enterSlide,
            child: child,
          ),
        );
      case SharedAxisDirection.vertical:
        final enterSlide = Tween<Offset>(
          begin: const Offset(0.0, 0.045),
          end: Offset.zero,
        ).animate(enterCurved);
        final exitSlide = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, -0.035),
        ).animate(exitCurved);
        transformedChild = SlideTransition(
          position: exitSlide,
          child: SlideTransition(
            position: enterSlide,
            child: child,
          ),
        );
      case SharedAxisDirection.scaled:
        final enterScale =
            Tween<double>(begin: 0.94, end: 1.0).animate(enterCurved);
        final exitScale =
            Tween<double>(begin: 1.0, end: 1.04).animate(exitCurved);
        transformedChild = ScaleTransition(
          scale: exitScale,
          child: ScaleTransition(
            scale: enterScale,
            child: child,
          ),
        );
    }

    return FadeTransition(
      opacity: exitOpacity,
      child: FadeTransition(
        opacity: enterOpacity,
        child: transformedChild,
      ),
    );
  }

  /// Buduje przejście z efektem najazdu kamery z lotu ptaka (helikopter TV)
  /// prosto na szosę wyścigu 3D.
  static Widget buildAerialToRoadCameraDiveTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    String? stageLabel,
    String? subtitle,
    bool showTelemetryOverlay = true,
  }) {
    final diveCurved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeInCubic,
    );

    final exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: exitFade,
      child: AnimatedBuilder(
        animation: diveCurved,
        builder: (context, staticChild) {
          final t = diveCurved.value.clamp(0.0, 1.0);
          final inv = 1.0 - t;

          // Kamera schodzi z kąta lotu ptaka (~0.52 rad) do poziomu szosy (0.0 rad)
          // oraz z szerokiej wysokości (scale 1.28) na docelowy kadr 1.0.
          final pitchRadians = 0.52 * inv;
          final scale = 1.0 + (0.28 * inv);
          final verticalOffset = -56.0 * inv;
          final contentOpacity = ((t - 0.12) / 0.55).clamp(0.0, 1.0);

          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..translateByDouble(0.0, verticalOffset, 0.0, 1.0)
            ..rotateX(pitchRadians)
            ..scaleByDouble(scale, scale, 1.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Ciemne tło wysokościowe zapobiegające prześwitom krawędzi podczas rotacji 3D
              const ColoredBox(color: AppColors.background),
              Transform(
                alignment: Alignment.center,
                transform: matrix,
                child: Opacity(
                  opacity: contentOpacity,
                  child: staticChild,
                ),
              ),
              if (showTelemetryOverlay && t > 0.01 && t < 0.995)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _AerialRoadDiveOverlayPainter(
                      progress: t,
                      stageLabel: stageLabel ?? 'KM 0.0 — START ETAPU 3D',
                      subtitle: subtitle ?? 'NAJAZD KAMERY TV NA PELETON',
                    ),
                  ),
                ),
            ],
          );
        },
        child: child,
      ),
    );
  }
}

/// Rysuje perspektywiczną szosę z lotu ptaka, smugi powietrza oraz celownik
/// helikoptera telewizyjnego podczas zjazdu kamery na wyścig 3D.
class _AerialRoadDiveOverlayPainter extends CustomPainter {
  const _AerialRoadDiveOverlayPainter({
    required this.progress,
    required this.stageLabel,
    required this.subtitle,
  });

  final double progress;
  final String stageLabel;
  final String subtitle;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Nakładka ma szczytową widoczność na starcie przejścia i płynnie zanika przy t -> 1.0.
    final overlayAlpha = (1.0 - Curves.easeInQuad.transform(progress))
        .clamp(0.0, 1.0);
    if (overlayAlpha <= 0.01) return;

    final centerX = size.width * 0.5;
    final horizonY = size.height * (0.28 + 0.20 * progress);

    // 1. Siatka perspektywiczna szosy schodząca się do punktu zbiegu
    final roadTopHalf = size.width * (0.04 + 0.06 * progress);
    final roadBottomHalf = size.width * (0.22 + 0.18 * progress);

    final roadPath = Path()
      ..moveTo(centerX - roadTopHalf, horizonY)
      ..lineTo(centerX + roadTopHalf, horizonY)
      ..lineTo(centerX + roadBottomHalf, size.height)
      ..lineTo(centerX - roadBottomHalf, size.height)
      ..close();

    final roadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.surfaceLight.withValues(alpha: 0.0),
          AppColors.surfaceLight.withValues(alpha: 0.32 * overlayAlpha),
          AppColors.surface.withValues(alpha: 0.45 * overlayAlpha),
        ],
      ).createShader(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY));

    canvas.drawPath(roadPath, roadPaint);

    // 2. Złote linie krawędziowe szosy i przerywana oś jezdni
    final edgePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.45 * overlayAlpha)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - roadTopHalf, horizonY),
      Offset(centerX - roadBottomHalf, size.height),
      edgePaint,
    );
    canvas.drawLine(
      Offset(centerX + roadTopHalf, horizonY),
      Offset(centerX + roadBottomHalf, size.height),
      edgePaint,
    );

    final centerDashPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.42 * overlayAlpha)
      ..strokeWidth = 1.4;
    const dashCount = 7;
    for (int i = 0; i < dashCount; i++) {
      final t0 = (i / dashCount + progress * 0.6) % 1.0;
      final t1 = (t0 + 0.06).clamp(0.0, 1.0);
      final y0 = horizonY + (size.height - horizonY) * (t0 * t0);
      final y1 = horizonY + (size.height - horizonY) * (t1 * t1);
      canvas.drawLine(Offset(centerX, y0), Offset(centerX, y1), centerDashPaint);
    }

    // 3. Smugi prędkości opadającej kamery helikoptera
    final streakPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.25 * overlayAlpha)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const streakCount = 14;
    for (int i = 0; i < streakCount; i++) {
      final angle = (i / streakCount) * math.pi * 2;
      final rInner = size.shortestSide * (0.18 + 0.14 * progress);
      final rOuter = rInner + size.shortestSide * (0.14 * (1.0 - progress * 0.5));
      final p1 = Offset(
        centerX + math.cos(angle) * rInner,
        size.height * 0.5 + math.sin(angle) * rInner * 0.65,
      );
      final p2 = Offset(
        centerX + math.cos(angle) * rOuter,
        size.height * 0.5 + math.sin(angle) * rOuter * 0.65,
      );
      canvas.drawLine(p1, p2, streakPaint);
    }

    // 4. Celownik kamery Cineflex + telemetria wysokości (420 m -> 12 m)
    final reticleRadius = 34.0 + 28.0 * (1.0 - progress);
    final reticleCenter = Offset(centerX, size.height * 0.5);
    final reticlePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.65 * overlayAlpha)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(reticleCenter, reticleRadius, reticlePaint);

    final altitudeMeters = (420 - (408 * progress)).round();
    final telemetryText =
        '$stageLabel  •  ALT ${altitudeMeters}m  •  $subtitle';

    final textPainter = TextPainter(
      text: TextSpan(
        text: telemetryText,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size.width < 500 ? 10 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: AppColors.textPrimary.withValues(alpha: 0.92 * overlayAlpha),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: size.width - 32);

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, reticleCenter.dy + reticleRadius + 24),
        width: textPainter.width + 24,
        height: 28,
      ),
      const Radius.circular(14),
    );

    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = AppColors.surface.withValues(alpha: 0.86 * overlayAlpha),
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.5 * overlayAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width * 0.5,
        pillRect.center.dy - textPainter.height * 0.5,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _AerialRoadDiveOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.stageLabel != stageLabel ||
        oldDelegate.subtitle != subtitle;
  }
}

/// Interaktywny panel podglądu i konfiguracji przejść ekranowych [AnimatedScreenTransitionRouter].
///
/// Obsługuje pełne stany `hover`, `active`, `disabled` i `focus`, responsywność
/// w rozdzielczościach `390x844`, `1024x768` i `1600x900` oraz paletę [AppColors].
class ScreenTransitionPreviewPanel extends StatefulWidget {
  const ScreenTransitionPreviewPanel({
    super.key,
    this.initialPreset = ScreenTransitionPreset.aerialToRoadDive3d,
    this.onPresetSelected,
    this.onLaunchRacePressed,
  });

  final ScreenTransitionPreset initialPreset;
  final ValueChanged<ScreenTransitionPreset>? onPresetSelected;
  final VoidCallback? onLaunchRacePressed;

  @override
  State<ScreenTransitionPreviewPanel> createState() =>
      _ScreenTransitionPreviewPanelState();
}

class _ScreenTransitionPreviewPanelState
    extends State<ScreenTransitionPreviewPanel>
    with SingleTickerProviderStateMixin {
  late ScreenTransitionPreset _selectedPreset;
  late AnimationController _controller;
  bool _reducedMotion = false;
  bool _isAnimating = false;
  bool _stageHovered = false;
  bool _stageFocused = false;
  bool _replayHovered = false;
  bool _replayPressed = false;
  bool _launchHovered = false;
  bool _launchPressed = false;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    _controller = AnimationController(
      vsync: this,
      duration: _effectiveDuration(_selectedPreset),
      value: 1.0,
    )..addStatusListener((status) {
        if (!mounted) return;
        final active = status == AnimationStatus.forward ||
            status == AnimationStatus.reverse;
        if (active != _isAnimating) {
          setState(() => _isAnimating = active);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _effectiveDuration(ScreenTransitionPreset preset) {
    if (_reducedMotion || preset == ScreenTransitionPreset.instant) {
      return const Duration(milliseconds: 120);
    }
    return preset.duration;
  }

  void _selectPreset(ScreenTransitionPreset preset) {
    setState(() {
      _selectedPreset = preset;
    });
    widget.onPresetSelected?.call(preset);
    _replayTransition();
  }

  void _replayTransition() {
    if (_isAnimating) return;
    _controller.duration = _effectiveDuration(_selectedPreset);
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1100;
        final cardPadding = isCompact ? 14.0 : 20.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 16),
              if (isCompact || isTablet) ...[
                _buildPresetSelector(isCompact: isCompact),
                const SizedBox(height: 16),
                _buildPreviewStage(height: isCompact ? 200 : 240),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildPresetSelector(isCompact: false),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 7,
                      child: _buildPreviewStage(height: 270),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _buildActionFooter(isCompact),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final titleRow = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.movie_filter_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Router Przejść Ekranowych 3D & UI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'GoRouter • SharedAxis (300 ms easeOutExpo) • Kamera z Lotu Ptaka',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 11 : 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final motionChip = _ReducedMotionChip(
      enabled: _reducedMotion,
      onToggle: () {
        setState(() => _reducedMotion = !_reducedMotion);
      },
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          const SizedBox(height: 10),
          motionChip,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleRow),
        const SizedBox(width: 12),
        motionChip,
      ],
    );
  }

  Widget _buildPresetSelector({required bool isCompact}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ScreenTransitionPreset.values.map((preset) {
        final isSelected = preset == _selectedPreset;
        final isDisabled = _isAnimating && !isSelected;
        return _PresetChoiceChip(
          preset: preset,
          isSelected: isSelected,
          isDisabled: isDisabled,
          compact: isCompact,
          onTap: isDisabled ? null : () => _selectPreset(preset),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewStage({required double height}) {
    final screenMockup = _TransitionMockScene(preset: _selectedPreset);
    final transitioned = _buildTransitionPreviewWidget(screenMockup);

    return Focus(
      onFocusChange: (focused) => setState(() => _stageFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _stageHovered = true),
        onExit: (_) => setState(() => _stageHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _stageFocused
                  ? AppColors.cyanAccent
                  : _stageHovered
                      ? AppColors.goldAccent.withValues(alpha: 0.7)
                      : AppColors.cardBorder,
              width: _stageFocused ? 1.8 : 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              transitioned,
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    '${_selectedPreset.shortLabel.toUpperCase()} • '
                    '${_effectiveDuration(_selectedPreset).inMilliseconds} ms',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransitionPreviewWidget(Widget child) {
    if (_reducedMotion || _selectedPreset == ScreenTransitionPreset.instant) {
      return FadeTransition(opacity: _controller, child: child);
    }
    switch (_selectedPreset) {
      case ScreenTransitionPreset.managerSharedAxisHorizontal:
        return AnimatedScreenTransitionRouter.buildSharedAxisTransition(
          animation: _controller,
          secondaryAnimation: kAlwaysDismissedAnimation,
          axis: SharedAxisDirection.horizontal,
          child: child,
        );
      case ScreenTransitionPreset.managerSharedAxisVertical:
        return AnimatedScreenTransitionRouter.buildSharedAxisTransition(
          animation: _controller,
          secondaryAnimation: kAlwaysDismissedAnimation,
          axis: SharedAxisDirection.vertical,
          child: child,
        );
      case ScreenTransitionPreset.managerSharedAxisScaled:
        return AnimatedScreenTransitionRouter.buildSharedAxisTransition(
          animation: _controller,
          secondaryAnimation: kAlwaysDismissedAnimation,
          axis: SharedAxisDirection.scaled,
          child: child,
        );
      case ScreenTransitionPreset.aerialToRoadDive3d:
        return AnimatedScreenTransitionRouter
            .buildAerialToRoadCameraDiveTransition(
          animation: _controller,
          secondaryAnimation: kAlwaysDismissedAnimation,
          stageLabel: 'ETAP 17 • ALPE D\'HUEZ',
          subtitle: 'ODPRAWA -> WYŚCIG 3D',
          child: child,
        );
      case ScreenTransitionPreset.podiumCeremonyReveal:
        final curved = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutExpo,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      case ScreenTransitionPreset.instant:
        return child;
    }
  }

  Widget _buildActionFooter(bool isCompact) {
    final replayButton = MouseRegion(
      onEnter: (_) => setState(() => _replayHovered = true),
      onExit: (_) => setState(() {
        _replayHovered = false;
        _replayPressed = false;
      }),
      child: GestureDetector(
        onTapDown: _isAnimating ? null : (_) => setState(() => _replayPressed = true),
        onTapUp: (_) => setState(() => _replayPressed = false),
        onTapCancel: () => setState(() => _replayPressed = false),
        child: AnimatedScale(
          scale: _replayPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: OutlinedButton.icon(
            onPressed: _isAnimating ? null : _replayTransition,
            icon: Icon(
              _isAnimating ? Icons.hourglass_top_rounded : Icons.replay_rounded,
              size: 18,
            ),
            label: Text(
              _isAnimating ? 'Odtwarzanie...' : 'Odtwórz Przejście',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isAnimating
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              backgroundColor: _replayHovered && !_isAnimating
                  ? AppColors.surfaceLight
                  : AppColors.background,
              side: BorderSide(
                color: _replayHovered && !_isAnimating
                    ? AppColors.goldAccent
                    : AppColors.cardBorder,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );

    final launchButton = MouseRegion(
      onEnter: (_) => setState(() => _launchHovered = true),
      onExit: (_) => setState(() {
        _launchHovered = false;
        _launchPressed = false;
      }),
      child: GestureDetector(
        onTapDown: widget.onLaunchRacePressed == null
            ? null
            : (_) => setState(() => _launchPressed = true),
        onTapUp: (_) => setState(() => _launchPressed = false),
        onTapCancel: () => setState(() => _launchPressed = false),
        child: AnimatedScale(
          scale: _launchPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: ElevatedButton.icon(
            onPressed: widget.onLaunchRacePressed,
            icon: const Icon(Icons.flight_land_rounded, size: 18),
            label: const Text(
              'Start Wyścigu 3D',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.onLaunchRacePressed == null
                  ? AppColors.surfaceLight
                  : _launchHovered
                      ? AppColors.goldAccent
                      : AppColors.primaryAccent,
              foregroundColor: widget.onLaunchRacePressed == null
                  ? AppColors.textSecondary
                  : _launchHovered
                      ? Colors.black
                      : AppColors.textPrimary,
              disabledBackgroundColor: AppColors.surfaceLight,
              disabledForegroundColor: AppColors.textSecondary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _selectedPreset.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          replayButton,
          if (widget.onLaunchRacePressed != null) ...[
            const SizedBox(height: 8),
            launchButton,
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            _selectedPreset.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        replayButton,
        if (widget.onLaunchRacePressed != null) ...[
          const SizedBox(width: 10),
          launchButton,
        ],
      ],
    );
  }
}

class _PresetChoiceChip extends StatefulWidget {
  const _PresetChoiceChip({
    required this.preset,
    required this.isSelected,
    required this.isDisabled,
    required this.compact,
    required this.onTap,
  });

  final ScreenTransitionPreset preset;
  final bool isSelected;
  final bool isDisabled;
  final bool compact;
  final VoidCallback? onTap;

  @override
  State<_PresetChoiceChip> createState() => _PresetChoiceChipState();
}

class _PresetChoiceChipState extends State<_PresetChoiceChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.primaryAccent.withValues(alpha: 0.25)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = widget.isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.cyanAccent
            : widget.isSelected
                ? AppColors.goldAccent
                : _hovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    return Focus(
      canRequestFocus: !widget.isDisabled,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 110),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 10 : 12,
                vertical: widget.compact ? 7 : 8,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: _focused || widget.isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Text(
                widget.preset.shortLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: widget.compact ? 11 : 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : widget.isSelected
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReducedMotionChip extends StatefulWidget {
  const _ReducedMotionChip({
    required this.enabled,
    required this.onToggle,
  });

  final bool enabled;
  final VoidCallback onToggle;

  @override
  State<_ReducedMotionChip> createState() => _ReducedMotionChipState();
}

class _ReducedMotionChipState extends State<_ReducedMotionChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.enabled
                  ? AppColors.amberWarning.withValues(alpha: 0.16)
                  : _hovered
                      ? AppColors.surfaceLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.cyanAccent
                    : widget.enabled
                        ? AppColors.amberWarning
                        : AppColors.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.enabled
                      ? Icons.motion_photos_off_rounded
                      : Icons.animation_rounded,
                  size: 14,
                  color: widget.enabled
                      ? AppColors.amberWarning
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.enabled ? 'Reduced Motion: ON' : 'Animacje: 120 FPS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.enabled
                        ? AppColors.amberWarning
                        : AppColors.textSecondary,
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

class _TransitionMockScene extends StatelessWidget {
  const _TransitionMockScene({required this.preset});

  final ScreenTransitionPreset preset;

  @override
  Widget build(BuildContext context) {
    final isRace = preset == ScreenTransitionPreset.aerialToRoadDive3d;
    final isPodium = preset == ScreenTransitionPreset.podiumCeremonyReveal;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isRace
              ? const [
                  Color(0xFF0E1B2B),
                  Color(0xFF141A23),
                  Color(0xFF0F1115),
                ]
              : isPodium
                  ? const [
                      Color(0xFF231B12),
                      Color(0xFF181B22),
                      Color(0xFF0F1115),
                    ]
                  : const [
                      Color(0xFF181B22),
                      Color(0xFF12151B),
                      Color(0xFF0F1115),
                    ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRace
                    ? Icons.terrain_rounded
                    : isPodium
                        ? Icons.emoji_events_rounded
                        : Icons.dashboard_customize_rounded,
                color: isPodium ? AppColors.goldAccent : AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRace
                      ? 'Widok 3D Wyścigu — Peleton na Szosie'
                      : isPodium
                          ? 'Ceremonia Podium — Żółta Koszulka Lidera'
                          : 'Moduł Menedżera — ${preset.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Klatka docelowa po zakończeniu przejścia GoRouter.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
