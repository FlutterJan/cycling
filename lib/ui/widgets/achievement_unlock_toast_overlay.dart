import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/career/achievement_and_milestones_service.dart';

/// Globalna nakładka wyświetlająca animowany baner odblokowania osiągnięcia
/// w stylu trofeów PlayStation / Steam ze złotym blaskiem `#D4AF37`.
class AchievementUnlockToastOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final Duration displayDuration;

  const AchievementUnlockToastOverlay({
    super.key,
    required this.child,
    this.displayDuration = const Duration(milliseconds: 4600),
  });

  @override
  ConsumerState<AchievementUnlockToastOverlay> createState() =>
      _AchievementUnlockToastOverlayState();
}

class _AchievementUnlockToastOverlayState
    extends ConsumerState<AchievementUnlockToastOverlay>
    with TickerProviderStateMixin {
  final Queue<AchievementUnlockEvent> _queue = Queue<AchievementUnlockEvent>();
  StreamSubscription<AchievementUnlockEvent>? _subscription;
  AchievementUnlockEvent? _activeEvent;
  Timer? _dismissTimer;

  late final AnimationController _entryController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );

    final curved = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.18, -0.15),
      end: Offset.zero,
    ).animate(curved);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(curved);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    final service = ref.read(achievementServiceProvider);
    _subscription = service.unlockStream.listen(_enqueueEvent);
  }

  void _enqueueEvent(AchievementUnlockEvent event) {
    if (!mounted) return;
    _queue.addLast(event);
    if (_activeEvent == null) {
      _showNext();
    }
  }

  void _showNext() {
    if (!mounted) return;
    if (_queue.isEmpty) {
      setState(() => _activeEvent = null);
      return;
    }

    final next = _queue.removeFirst();
    setState(() => _activeEvent = next);

    _entryController.forward(from: 0.0);
    _shimmerController.forward(from: 0.0);

    _dismissTimer?.cancel();
    _dismissTimer = Timer(widget.displayDuration, _dismissCurrent);
  }

  Future<void> _dismissCurrent() async {
    _dismissTimer?.cancel();
    if (!mounted || _activeEvent == null) return;
    await _entryController.reverse();
    if (!mounted) return;
    _showNext();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _subscription?.cancel();
    _entryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeEvent;

    return Stack(
      children: [
        widget.child,
        if (active != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompactMobile = constraints.maxWidth < 600;
                    return Align(
                      alignment: isCompactMobile
                          ? Alignment.topCenter
                          : Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompactMobile ? 14 : 24,
                          vertical: isCompactMobile ? 12 : 20,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isCompactMobile
                                ? constraints.maxWidth - 28
                                : 420,
                          ),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: AchievementTrophyToastBanner(
                                  event: active,
                                  shimmerAnimation: _shimmerController,
                                  isCompact: isCompactMobile,
                                  onDismiss: _dismissCurrent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Elegancki baner trofeum w stylu PlayStation / Steam ze złotym blaskiem `#D4AF37`.
class AchievementTrophyToastBanner extends StatefulWidget {
  final AchievementUnlockEvent event;
  final Animation<double>? shimmerAnimation;
  final bool isCompact;
  final VoidCallback? onDismiss;

  const AchievementTrophyToastBanner({
    super.key,
    required this.event,
    this.shimmerAnimation,
    this.isCompact = false,
    this.onDismiss,
  });

  @override
  State<AchievementTrophyToastBanner> createState() =>
      _AchievementTrophyToastBannerState();
}

class _AchievementTrophyToastBannerState
    extends State<AchievementTrophyToastBanner> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;
  bool _isCloseHovered = false;
  bool _isCloseFocused = false;

  @override
  Widget build(BuildContext context) {
    final def = widget.event.achievement;
    final tierColor = def.tier.badgeColor;
    final canDismiss = widget.onDismiss != null;

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: canDismiss ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: canDismiss
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onDismiss?.call();
                }
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.985 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _isHovered
                        ? AppColors.surfaceLight
                        : AppColors.surface,
                    const Color(0xFF14171E),
                  ],
                ),
                border: Border.all(
                  color: _isFocused
                      ? AppColors.goldAccent
                      : AppColors.goldAccent.withValues(
                          alpha: _isHovered ? 0.95 : 0.72,
                        ),
                  width: _isFocused ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldAccent.withValues(
                      alpha: _isHovered ? 0.48 : 0.34,
                    ),
                    blurRadius: _isHovered ? 28 : 22,
                    spreadRadius: _isHovered ? 2 : 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    if (widget.shimmerAnimation != null)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: widget.shimmerAnimation!,
                          builder: (context, _) {
                            final t = widget.shimmerAnimation!.value;
                            if (t <= 0.0 || t >= 1.0) {
                              return const SizedBox.shrink();
                            }
                            return FractionalTranslation(
                              translation: Offset(-1.2 + (t * 2.4), 0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.transparent,
                                      AppColors.goldAccent
                                          .withValues(alpha: 0.14),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.25, 0.5, 0.75],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _TrophyMedallionBadge(
                            icon: def.icon,
                            tierColor: tierColor,
                            size: widget.isCompact ? 46 : 54,
                          ),
                          SizedBox(width: widget.isCompact ? 12 : 14),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.goldAccent
                                              .withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.goldAccent
                                                .withValues(alpha: 0.55),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              def.tier.tierIcon,
                                              size: 12,
                                              color: tierColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'OSIĄGNIĘCIE • ${def.tier.label.toUpperCase()}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  color: tierColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+${def.points} PKT',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: AppColors.goldAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  def.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  def.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.35,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Focus(
                            onFocusChange: (f) =>
                                setState(() => _isCloseFocused = f),
                            child: MouseRegion(
                              onEnter: (_) =>
                                  setState(() => _isCloseHovered = true),
                              onExit: (_) =>
                                  setState(() => _isCloseHovered = false),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.onDismiss,
                                  borderRadius: BorderRadius.circular(8),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _isCloseHovered
                                          ? AppColors.surfaceLight
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _isCloseFocused
                                            ? AppColors.goldAccent
                                            : AppTheme.borderColor
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: canDismiss
                                          ? (_isCloseHovered
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary)
                                          : AppColors.textSecondary
                                              .withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrophyMedallionBadge extends StatelessWidget {
  final IconData icon;
  final Color tierColor;
  final double size;

  const _TrophyMedallionBadge({
    required this.icon,
    required this.tierColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.goldAccent.withValues(alpha: 0.28),
            AppColors.surfaceLight,
          ],
        ),
        border: Border.all(
          color: AppColors.goldAccent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.42),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: tierColor,
          size: size * 0.48,
        ),
      ),
    );
  }
}
