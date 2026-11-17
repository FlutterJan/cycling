import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/career/career_achievements_and_trophies_engine.dart';

/// Zakładki główne ekranu Osiągnięć i Platynowego Trofeum.
enum AchievementsScreenSection {
  allAchievements,
  platinumShowcase,
  unlockHistory,
}

/// Kolejność sortowania listy 60 osiągnięć.
enum AchievementsSortOrder {
  defaultOrder,
  progressDescending,
  pointsDescending,
  tierDescending,
}

extension AchievementsScreenSectionExt on AchievementsScreenSection {
  String get labelPl {
    switch (this) {
      case AchievementsScreenSection.allAchievements:
        return 'Osiągnięcia (60)';
      case AchievementsScreenSection.platinumShowcase:
        return 'Platynowe Trofeum';
      case AchievementsScreenSection.unlockHistory:
        return 'Historia Odblokowań';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementsScreenSection.allAchievements:
        return Icons.grid_view_rounded;
      case AchievementsScreenSection.platinumShowcase:
        return Icons.military_tech_rounded;
      case AchievementsScreenSection.unlockHistory:
        return Icons.history_rounded;
    }
  }
}

extension AchievementsSortOrderExt on AchievementsSortOrder {
  String get labelPl {
    switch (this) {
      case AchievementsSortOrder.defaultOrder:
        return 'Domyślnie (#)';
      case AchievementsSortOrder.progressDescending:
        return 'Postęp (%)';
      case AchievementsSortOrder.pointsDescending:
        return 'Punkty';
      case AchievementsSortOrder.tierDescending:
        return 'Ranga';
    }
  }
}

/// Wyskakujące powiadomienie o odblokowaniu osiągnięcia lub Platynowego Trofeum.
///
/// Obsługuje pełne stany interakcji (`hover`, `active`, `focus`, `disabled`),
/// płynną animację połysku oraz responsywną szerokość na mobile i desktopie.
class AchievementUnlockedToast extends StatefulWidget {
  final CareerTrophyUnlockEvent event;
  final double shimmerProgress;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AchievementUnlockedToast({
    super.key,
    required this.event,
    this.shimmerProgress = 0.0,
    this.enabled = true,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<AchievementUnlockedToast> createState() =>
      _AchievementUnlockedToastState();
}

class _AchievementUnlockedToastState extends State<AchievementUnlockedToast> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isPlatinum = event.isPlatinumTrophy;
    final accentColor = isPlatinum ? AppColors.cyanAccent : event.tier.color;
    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.45)
        : _focused
            ? AppColors.cyanAccent
            : (_hovered || _pressed)
                ? accentColor
                : accentColor.withValues(alpha: isPlatinum ? 0.9 : 0.65);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (value) {
        if (mounted) setState(() => _hovered = value);
      },
      onShowFocusHighlight: (value) {
        if (mounted) setState(() => _focused = value);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onDismiss?.call();
            return null;
          },
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _pressed = false)
            : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : (_hovered ? 1.01 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPlatinum
                    ? [
                        const Color(0xFF14212E),
                        AppColors.surface,
                        const Color(0xFF231D12),
                      ]
                    : [
                        AppColors.surfaceLight,
                        AppColors.surface,
                      ],
              ),
              border: Border.all(
                color: borderColor,
                width: (_hovered || _focused || isPlatinum) ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(
                    alpha: !widget.enabled
                        ? 0.05
                        : _hovered
                            ? 0.34
                            : 0.22,
                  ),
                  blurRadius: _hovered ? 26 : 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  if (widget.shimmerProgress > 0.0 &&
                      widget.shimmerProgress < 1.0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ToastShimmerPainter(
                            progress: widget.shimmerProgress,
                            accentColor: accentColor,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ToastTrophyMedallion(
                          event: event,
                          accentColor: accentColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      isPlatinum
                                          ? 'PLATYNOWE TROFEUM'
                                          : 'OSIĄGNIĘCIE ODBLOKOWANE',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.9,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          accentColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color:
                                            accentColor.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      '+${event.pointsAwarded} PKT',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: widget.enabled
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.contextNote != null &&
                                        event.contextNote!.trim().isNotEmpty
                                    ? '${event.description} • ${event.contextNote}'
                                    : event.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  height: 1.3,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onDismiss != null) ...[
                          const SizedBox(width: 6),
                          _InteractiveIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Zamknij powiadomienie',
                            enabled: widget.enabled,
                            onPressed: widget.onDismiss,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastTrophyMedallion extends StatelessWidget {
  final CareerTrophyUnlockEvent event;
  final Color accentColor;

  const _ToastTrophyMedallion({
    required this.event,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accentColor.withValues(alpha: 0.34),
            accentColor.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.75),
          width: 1.4,
        ),
      ),
      child: Icon(
        event.isPlatinumTrophy
            ? Icons.military_tech_rounded
            : event.tier.icon,
        color: accentColor,
        size: 24,
      ),
    );
  }
}

class _ToastShimmerPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  const _ToastShimmerPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = -size.width * 0.3 + progress * size.width * 1.6;
    final bandWidth = size.width * 0.36;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          accentColor.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 0.52, 1.0],
      ).createShader(
        Rect.fromLTWH(centerX - bandWidth / 2, 0, bandWidth, size.height),
      );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ToastShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Host nakładki automatycznie kolejkujący i wyświetlający `AchievementUnlockedToast`
/// na podstawie `careerAchievementsProvider.pendingToastQueue` oraz ręcznych wywołań.
class AchievementUnlockedToastHost extends ConsumerStatefulWidget {
  final Widget child;
  final Duration displayDuration;
  final void Function(CareerTrophyUnlockEvent event)? onToastTapped;

  const AchievementUnlockedToastHost({
    super.key,
    required this.child,
    this.displayDuration = const Duration(milliseconds: 4200),
    this.onToastTapped,
  });

  @override
  ConsumerState<AchievementUnlockedToastHost> createState() =>
      AchievementUnlockedToastHostState();
}

class AchievementUnlockedToastHostState
    extends ConsumerState<AchievementUnlockedToastHost>
    with TickerProviderStateMixin {
  final Queue<CareerTrophyUnlockEvent> _localQueue =
      Queue<CareerTrophyUnlockEvent>();
  CareerTrophyUnlockEvent? _activeEvent;
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
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    final curved = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.18),
      end: Offset.zero,
    ).animate(curved);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(curved);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _drainProviderQueue();
    });
  }

  /// Dodaje pojedynczy toast bezpośrednio do kolejki wyświetlania.
  void showToast(CareerTrophyUnlockEvent event) {
    if (!mounted) return;
    _localQueue.addLast(event);
    if (_activeEvent == null) {
      _showNext();
    }
  }

  void _drainProviderQueue() {
    final pending = ref.read(careerAchievementsProvider).pendingToastQueue;
    if (pending.isEmpty) return;
    final notifier = ref.read(careerAchievementsProvider.notifier);
    while (true) {
      final item = notifier.consumeNextToast();
      if (item == null) break;
      _localQueue.addLast(item);
    }
    if (_activeEvent == null && _localQueue.isNotEmpty) {
      _showNext();
    }
  }

  void _showNext() {
    if (!mounted) return;
    if (_localQueue.isEmpty) {
      setState(() => _activeEvent = null);
      return;
    }

    final next = _localQueue.removeFirst();
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
    _entryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<CareerTrophyUnlockEvent>>(
      careerAchievementsProvider.select((s) => s.pendingToastQueue),
      (previous, next) {
        if (next.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _drainProviderQueue();
          });
        }
      },
    );

    final active = _activeEvent;

    return Stack(
      children: [
        widget.child,
        if (active != null)
          Positioned(
            top: 16,
            right: 16,
            left: 16,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          return AchievementUnlockedToast(
                            event: active,
                            shimmerProgress: _shimmerController.value,
                            onTap: () {
                              widget.onToastTapped?.call(active);
                              _dismissCurrent();
                            },
                            onDismiss: _dismissCurrent,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Główny ekran Osiągnięć (60 kamieni milowych), Platynowego Trofeum
/// oraz wyskakujących powiadomień `AchievementUnlockedToast`.
class AchievementsAndPlatinumTrophyScreen extends ConsumerStatefulWidget {
  final bool readOnly;
  final AchievementsScreenSection initialSection;
  final VoidCallback? onBack;

  const AchievementsAndPlatinumTrophyScreen({
    super.key,
    this.readOnly = false,
    this.initialSection = AchievementsScreenSection.allAchievements,
    this.onBack,
  });

  @override
  ConsumerState<AchievementsAndPlatinumTrophyScreen> createState() =>
      _AchievementsAndPlatinumTrophyScreenState();
}

class _AchievementsAndPlatinumTrophyScreenState
    extends ConsumerState<AchievementsAndPlatinumTrophyScreen> {
  final GlobalKey<AchievementUnlockedToastHostState> _toastHostKey =
      GlobalKey<AchievementUnlockedToastHostState>();

  late AchievementsScreenSection _activeSection;
  CareerAchievementCategory? _selectedCategory;
  CareerAchievementTier? _selectedTier;
  CareerAchievementFilterMode _filterMode = CareerAchievementFilterMode.all;
  AchievementsSortOrder _sortOrder = AchievementsSortOrder.defaultOrder;
  String _searchQuery = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerPreviewToast(CareerAchievementsEngineState state) {
    if (widget.readOnly) return;

    final unlockedHistory = state.unlockHistory;
    final CareerTrophyUnlockEvent sampleEvent;
    if (unlockedHistory.isNotEmpty) {
      sampleEvent = unlockedHistory.first;
    } else {
      final firstDef = CareerAchievementsAndTrophiesEngine.catalog.first;
      sampleEvent = CareerTrophyUnlockEvent(
        achievementId: firstDef.id,
        title: firstDef.title,
        description: firstDef.description,
        tier: firstDef.tier,
        category: firstDef.category,
        pointsAwarded: firstDef.points,
        isPlatinumTrophy: false,
        unlockedAt: DateTime.now(),
        seasonYear: 2026,
        contextNote: 'Podgląd powiadomienia',
      );
    }
    _toastHostKey.currentState?.showToast(sampleEvent);
  }

  void _handleToastTap(CareerTrophyUnlockEvent event) {
    if (event.isPlatinumTrophy) {
      setState(
        () => _activeSection = AchievementsScreenSection.platinumShowcase,
      );
      return;
    }

    final def = CareerAchievementsAndTrophiesEngine.catalog.firstWhere(
      (d) => d.id == event.achievementId,
      orElse: () => CareerAchievementsAndTrophiesEngine.catalog.first,
    );
    _openAchievementDetailSheet(def);
  }

  List<CareerAchievementDefinition> _buildSortedCatalog(
    CareerAchievementsEngineState state,
  ) {
    final filtered = CareerAchievementsAndTrophiesEngine.filterCatalog(
      state,
      category: _selectedCategory,
      tier: _selectedTier,
      filterMode: _filterMode,
      searchQuery: _searchQuery,
    );

    final sorted = List<CareerAchievementDefinition>.from(filtered);
    switch (_sortOrder) {
      case AchievementsSortOrder.defaultOrder:
        sorted.sort((a, b) => a.codeNumber.compareTo(b.codeNumber));
      case AchievementsSortOrder.progressDescending:
        sorted.sort((a, b) {
          final pa = state.progressById[a.id]?.progressRatio ?? 0.0;
          final pb = state.progressById[b.id]?.progressRatio ?? 0.0;
          final cmp = pb.compareTo(pa);
          return cmp != 0 ? cmp : a.codeNumber.compareTo(b.codeNumber);
        });
      case AchievementsSortOrder.pointsDescending:
        sorted.sort((a, b) {
          final cmp = b.points.compareTo(a.points);
          return cmp != 0 ? cmp : a.codeNumber.compareTo(b.codeNumber);
        });
      case AchievementsSortOrder.tierDescending:
        sorted.sort((a, b) {
          final cmp = b.tier.index.compareTo(a.tier.index);
          return cmp != 0 ? cmp : a.codeNumber.compareTo(b.codeNumber);
        });
    }
    return sorted;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedTier = null;
      _filterMode = CareerAchievementFilterMode.all;
      _sortOrder = AchievementsSortOrder.defaultOrder;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _openAchievementDetailSheet(CareerAchievementDefinition def) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AchievementDetailSheet(
          definition: def,
          readOnly: widget.readOnly,
          onIncrementProgress: () {
            ref.read(careerAchievementsProvider.notifier).incrementProgress(
                  def.id,
                  delta: 1.0,
                  seasonYear: 2026,
                  contextNote: 'Postęp z ekranu osiągnięć',
                );
          },
          onUnlockNow: () {
            final state = ref.read(careerAchievementsProvider);
            final current = state.progressById[def.id]?.currentValue ?? 0.0;
            final remaining = math.max(1.0, def.targetValue - current);
            ref.read(careerAchievementsProvider.notifier).incrementProgress(
                  def.id,
                  delta: remaining,
                  seasonYear: 2026,
                  contextNote: 'Odblokowano w trybie testowym',
                );
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(careerAchievementsProvider);
    final summary = CareerAchievementsAndTrophiesEngine.summarize(engineState);

    return AchievementUnlockedToastHost(
      key: _toastHostKey,
      onToastTapped: _handleToastTap,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 700;
              final isTablet = width >= 700 && width < 1200;
              final horizontalPadding = isMobile ? 12.0 : (isTablet ? 20.0 : 28.0);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ScreenTopHeader(
                    summary: summary,
                    activeSection: _activeSection,
                    readOnly: widget.readOnly,
                    isMobile: isMobile,
                    canPop: widget.onBack != null ||
                        Navigator.of(context).canPop(),
                    onBack: widget.onBack ??
                        () => Navigator.of(context).maybePop(),
                    onSectionChanged: (section) =>
                        setState(() => _activeSection = section),
                    onPreviewToast: () => _triggerPreviewToast(engineState),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        14,
                        horizontalPadding,
                        28,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1480),
                          child: _buildActiveSectionBody(
                            engineState: engineState,
                            summary: summary,
                            width: width,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSectionBody({
    required CareerAchievementsEngineState engineState,
    required CareerAchievementsSummary summary,
    required double width,
  }) {
    switch (_activeSection) {
      case AchievementsScreenSection.allAchievements:
        final items = _buildSortedCatalog(engineState);
        return _AllAchievementsSection(
          engineState: engineState,
          summary: summary,
          items: items,
          width: width,
          selectedCategory: _selectedCategory,
          selectedTier: _selectedTier,
          filterMode: _filterMode,
          sortOrder: _sortOrder,
          searchController: _searchController,
          onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
          onTierSelected: (tier) => setState(() => _selectedTier = tier),
          onFilterModeSelected: (mode) => setState(() => _filterMode = mode),
          onSortOrderChanged: (order) => setState(() => _sortOrder = order),
          onSearchChanged: (query) => setState(() => _searchQuery = query),
          onClearFilters: _clearFilters,
          onOpenPlatinumShowcase: () => setState(
            () => _activeSection = AchievementsScreenSection.platinumShowcase,
          ),
          onTapAchievement: _openAchievementDetailSheet,
        );
      case AchievementsScreenSection.platinumShowcase:
        return _PlatinumTrophyShowcaseSection(
          engineState: engineState,
          summary: summary,
          width: width,
          onTapAchievement: _openAchievementDetailSheet,
          onFilterByCategory: (cat) {
            setState(() {
              _selectedCategory = cat;
              _activeSection = AchievementsScreenSection.allAchievements;
            });
          },
          onFilterByTier: (tier) {
            setState(() {
              _selectedTier = tier;
              _activeSection = AchievementsScreenSection.allAchievements;
            });
          },
        );
      case AchievementsScreenSection.unlockHistory:
        return _UnlockHistorySection(
          engineState: engineState,
          readOnly: widget.readOnly,
          width: width,
          onReplayToast: (event) =>
              _toastHostKey.currentState?.showToast(event),
          onClearPendingQueue: () =>
              ref.read(careerAchievementsProvider.notifier).clearToastQueue(),
          onInspectAchievement: (achievementId) {
            final match = CareerAchievementsAndTrophiesEngine.catalog
                .where((d) => d.id == achievementId)
                .toList();
            if (match.isNotEmpty) {
              _openAchievementDetailSheet(match.first);
            }
          },
        );
    }
  }
}

class _ScreenTopHeader extends StatelessWidget {
  final CareerAchievementsSummary summary;
  final AchievementsScreenSection activeSection;
  final bool readOnly;
  final bool isMobile;
  final bool canPop;
  final VoidCallback onBack;
  final ValueChanged<AchievementsScreenSection> onSectionChanged;
  final VoidCallback onPreviewToast;

  const _ScreenTopHeader({
    required this.summary,
    required this.activeSection,
    required this.readOnly,
    required this.isMobile,
    required this.canPop,
    required this.onBack,
    required this.onSectionChanged,
    required this.onPreviewToast,
  });

  @override
  Widget build(BuildContext context) {
    final platinum = summary.platinumTrophy;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canPop) ...[
                    _InteractiveIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Wróć',
                      enabled: true,
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.goldAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Osiągnięcia i Platynowe Trofeum',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isMobile ? 16 : 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          '60 wyzwań kariery • System trofeów UCI WorldTour',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HeaderMetricBadge(
                    label: 'ODBLOKOWANE',
                    value: '${summary.unlockedCount}/${summary.totalCount}',
                    accent: AppColors.goldAccent,
                  ),
                  _HeaderMetricBadge(
                    label: 'PUNKTY',
                    value: '${summary.totalPointsEarned} PKT',
                    accent: AppColors.cyanAccent,
                  ),
                  _HeaderMetricBadge(
                    label: 'PLATYNA',
                    value: '${platinum.completionPercent}%',
                    accent: platinum.isUnlocked
                        ? AppColors.statusSuccess
                        : AppColors.textSecondary,
                  ),
                  _InteractiveActionButton(
                    label: 'Podgląd Toastu',
                    icon: Icons.notifications_active_rounded,
                    enabled: !readOnly,
                    accentColor: AppColors.goldAccent,
                    onPressed: onPreviewToast,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AchievementsScreenSection.values.map((section) {
                final selected = section == activeSection;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _InteractivePillButton(
                    label: section.labelPl,
                    icon: section.icon,
                    selected: selected,
                    accentColor: section ==
                            AchievementsScreenSection.platinumShowcase
                        ? AppColors.cyanAccent
                        : AppColors.goldAccent,
                    onPressed: () => onSectionChanged(section),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllAchievementsSection extends StatelessWidget {
  final CareerAchievementsEngineState engineState;
  final CareerAchievementsSummary summary;
  final List<CareerAchievementDefinition> items;
  final double width;
  final CareerAchievementCategory? selectedCategory;
  final CareerAchievementTier? selectedTier;
  final CareerAchievementFilterMode filterMode;
  final AchievementsSortOrder sortOrder;
  final TextEditingController searchController;
  final ValueChanged<CareerAchievementCategory?> onCategorySelected;
  final ValueChanged<CareerAchievementTier?> onTierSelected;
  final ValueChanged<CareerAchievementFilterMode> onFilterModeSelected;
  final ValueChanged<AchievementsSortOrder> onSortOrderChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onOpenPlatinumShowcase;
  final ValueChanged<CareerAchievementDefinition> onTapAchievement;

  const _AllAchievementsSection({
    required this.engineState,
    required this.summary,
    required this.items,
    required this.width,
    required this.selectedCategory,
    required this.selectedTier,
    required this.filterMode,
    required this.sortOrder,
    required this.searchController,
    required this.onCategorySelected,
    required this.onTierSelected,
    required this.onFilterModeSelected,
    required this.onSortOrderChanged,
    required this.onSearchChanged,
    required this.onClearFilters,
    required this.onOpenPlatinumShowcase,
    required this.onTapAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1200;
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlatinumBannerCard(
          summary: summary,
          isMobile: isMobile,
          onOpenShowcase: onOpenPlatinumShowcase,
        ),
        const SizedBox(height: 14),
        _CategoryProgressStrip(
          summary: summary,
          selectedCategory: selectedCategory,
          onSelectCategory: onCategorySelected,
        ),
        const SizedBox(height: 14),
        _FilterAndSearchBar(
          isMobile: isMobile,
          selectedTier: selectedTier,
          filterMode: filterMode,
          sortOrder: sortOrder,
          searchController: searchController,
          onTierSelected: onTierSelected,
          onFilterModeSelected: onFilterModeSelected,
          onSortOrderChanged: onSortOrderChanged,
          onSearchChanged: onSearchChanged,
          onClearFilters: onClearFilters,
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          _EmptyFilterResultsCard(onClearFilters: onClearFilters)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: isMobile ? 168 : 176,
            ),
            itemBuilder: (context, index) {
              final def = items[index];
              final progress = engineState.progressById[def.id] ??
                  CareerAchievementProgress(
                    achievementId: def.id,
                    currentValue: 0,
                    targetValue: def.targetValue,
                    isUnlocked: false,
                  );
              return _AchievementTileCard(
                definition: def,
                progress: progress,
                onTap: () => onTapAchievement(def),
              );
            },
          ),
      ],
    );
  }
}

class _PlatinumBannerCard extends StatefulWidget {
  final CareerAchievementsSummary summary;
  final bool isMobile;
  final VoidCallback onOpenShowcase;

  const _PlatinumBannerCard({
    required this.summary,
    required this.isMobile,
    required this.onOpenShowcase,
  });

  @override
  State<_PlatinumBannerCard> createState() => _PlatinumBannerCardState();
}

class _PlatinumBannerCardState extends State<_PlatinumBannerCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final platinum = widget.summary.platinumTrophy;
    final accent =
        platinum.isUnlocked ? AppColors.cyanAccent : AppColors.goldAccent;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onOpenShowcase();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onOpenShowcase,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(widget.isMobile ? 14 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: platinum.isUnlocked
                  ? const [
                      Color(0xFF13222F),
                      AppColors.surface,
                      Color(0xFF251E10),
                    ]
                  : const [
                      AppColors.surfaceLight,
                      AppColors.surface,
                    ],
            ),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : _hovered
                      ? accent
                      : accent.withValues(alpha: 0.45),
              width: (_hovered || _focused) ? 1.5 : 1.0,
            ),
          ),
          child: widget.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CustomPaint(
                            painter: _PlatinumTrophyEmblemPainter(
                              unlocked: platinum.isUnlocked,
                              progress: platinum.progressRatio,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _PlatinumBannerText(platinum: platinum),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TierSummaryWrap(summary: widget.summary),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: CustomPaint(
                        painter: _PlatinumTrophyEmblemPainter(
                          unlocked: platinum.isUnlocked,
                          progress: platinum.progressRatio,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PlatinumBannerText(platinum: platinum),
                          const SizedBox(height: 10),
                          _TierSummaryWrap(summary: widget.summary),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _InteractiveActionButton(
                      label: 'Gablota Platyny',
                      icon: Icons.arrow_forward_rounded,
                      enabled: true,
                      accentColor: accent,
                      onPressed: widget.onOpenShowcase,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PlatinumBannerText extends StatelessWidget {
  final PlatinumTrophyRecord platinum;

  const _PlatinumBannerText({required this.platinum});

  @override
  Widget build(BuildContext context) {
    final accent =
        platinum.isUnlocked ? AppColors.cyanAccent : AppColors.goldAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Flexible(
              child: Text(
                PlatinumTrophyRecord.platinumTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
              ),
              child: Text(
                platinum.isUnlocked ? 'ODBLOKOWANE' : '${platinum.completionPercent}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          PlatinumTrophyRecord.platinumDescription,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: platinum.progressRatio,
            minHeight: 7,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}

class _TierSummaryWrap extends StatelessWidget {
  final CareerAchievementsSummary summary;

  const _TierSummaryWrap({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: CareerAchievementTier.values.map((tier) {
        final unlocked = summary.unlockedByTier[tier] ?? 0;
        final total = summary.totalByTier[tier] ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tier.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tier.icon, size: 13, color: tier.color),
              const SizedBox(width: 5),
              Text(
                '${tier.labelPl}: $unlocked/$total',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryProgressStrip extends StatelessWidget {
  final CareerAchievementsSummary summary;
  final CareerAchievementCategory? selectedCategory;
  final ValueChanged<CareerAchievementCategory?> onSelectCategory;

  const _CategoryProgressStrip({
    required this.summary,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _InteractivePillButton(
              label: 'Wszystkie (${summary.unlockedCount}/${summary.totalCount})',
              icon: Icons.apps_rounded,
              selected: selectedCategory == null,
              accentColor: AppColors.goldAccent,
              onPressed: () => onSelectCategory(null),
            ),
          ),
          ...CareerAchievementCategory.values.map((category) {
            final unlocked = summary.unlockedByCategory[category] ?? 0;
            final total = summary.totalByCategory[category] ?? 0;
            final selected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _InteractivePillButton(
                label: '${category.labelPl} ($unlocked/$total)',
                icon: category.icon,
                selected: selected,
                accentColor: AppColors.goldAccent,
                onPressed: () =>
                    onSelectCategory(selected ? null : category),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterAndSearchBar extends StatelessWidget {
  final bool isMobile;
  final CareerAchievementTier? selectedTier;
  final CareerAchievementFilterMode filterMode;
  final AchievementsSortOrder sortOrder;
  final TextEditingController searchController;
  final ValueChanged<CareerAchievementTier?> onTierSelected;
  final ValueChanged<CareerAchievementFilterMode> onFilterModeSelected;
  final ValueChanged<AchievementsSortOrder> onSortOrderChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearFilters;

  const _FilterAndSearchBar({
    required this.isMobile,
    required this.selectedTier,
    required this.filterMode,
    required this.sortOrder,
    required this.searchController,
    required this.onTierSelected,
    required this.onFilterModeSelected,
    required this.onSortOrderChanged,
    required this.onSearchChanged,
    required this.onClearFilters,
  });

  String _filterLabel(CareerAchievementFilterMode mode) {
    switch (mode) {
      case CareerAchievementFilterMode.all:
        return 'Wszystkie';
      case CareerAchievementFilterMode.unlocked:
        return 'Odblokowane';
      case CareerAchievementFilterMode.inProgress:
        return 'W trakcie';
      case CareerAchievementFilterMode.locked:
        return 'Zablokowane';
      case CareerAchievementFilterMode.secret:
        return 'Ukryte';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = selectedTier != null ||
        filterMode != CareerAchievementFilterMode.all ||
        sortOrder != AchievementsSortOrder.defaultOrder ||
        searchController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Szukaj osiągnięcia...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.goldAccent,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AchievementsSortOrder>(
                    value: sortOrder,
                    dropdownColor: AppColors.surfaceLight,
                    iconEnabledColor: AppColors.textSecondary,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    items: AchievementsSortOrder.values.map((order) {
                      return DropdownMenuItem<AchievementsSortOrder>(
                        value: order,
                        child: Text('Sortuj: ${order.labelPl}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) onSortOrderChanged(value);
                    },
                  ),
                ),
              ),
              if (hasActiveFilters)
                _InteractiveActionButton(
                  label: 'Wyczyść filtry',
                  icon: Icons.filter_alt_off_rounded,
                  enabled: true,
                  accentColor: AppColors.primaryAccent,
                  onPressed: onClearFilters,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...CareerAchievementFilterMode.values.map((mode) {
                return _InteractivePillButton(
                  label: _filterLabel(mode),
                  selected: filterMode == mode,
                  accentColor: AppColors.primaryAccent,
                  onPressed: () => onFilterModeSelected(mode),
                );
              }),
              const SizedBox(width: 4),
              ...CareerAchievementTier.values.map((tier) {
                final selected = selectedTier == tier;
                return _InteractivePillButton(
                  label: tier.labelPl,
                  icon: tier.icon,
                  selected: selected,
                  accentColor: tier.color,
                  onPressed: () => onTierSelected(selected ? null : tier),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementTileCard extends StatefulWidget {
  final CareerAchievementDefinition definition;
  final CareerAchievementProgress progress;
  final VoidCallback onTap;

  const _AchievementTileCard({
    required this.definition,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_AchievementTileCard> createState() => _AchievementTileCardState();
}

class _AchievementTileCardState extends State<_AchievementTileCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final prog = widget.progress;
    final unlocked = prog.isUnlocked;
    final isHiddenSecret = def.isSecret && !unlocked;
    final tierColor = def.tier.color;

    final borderColor = _focused
        ? AppColors.cyanAccent
        : _hovered
            ? (unlocked ? tierColor : AppColors.goldAccent)
            : unlocked
                ? tierColor.withValues(alpha: 0.55)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unlocked ? AppColors.surfaceLight : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: (_hovered || _focused) ? 1.5 : 1.0,
              ),
              boxShadow: unlocked && _hovered
                  ? [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? tierColor.withValues(alpha: 0.18)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: unlocked
                              ? tierColor.withValues(alpha: 0.65)
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Icon(
                        isHiddenSecret ? Icons.lock_rounded : def.icon,
                        size: 20,
                        color: unlocked ? tierColor : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${def.codeNumber.toString().padLeft(2, '0')} • ${def.category.labelPl}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            isHiddenSecret
                                ? 'Ukryte Osiągnięcie'
                                : def.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: unlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimary.withValues(
                                      alpha: 0.86,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(
                          alpha: unlocked ? 0.18 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        '${def.points} PKT',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: tierColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    isHiddenSecret
                        ? 'Odkryj warunek tego sekretnego osiągnięcia podczas kariery.'
                        : def.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      unlocked
                          ? 'Odblokowane${prog.unlockedSeasonYear != null ? ' • ${prog.unlockedSeasonYear}' : ''}'
                          : 'Postęp: ${prog.currentValue.toInt()} / ${prog.targetValue.toInt()}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: unlocked
                            ? AppColors.statusSuccess
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      def.tier.labelPl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tierColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: prog.progressRatio,
                    minHeight: 5,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      unlocked ? AppColors.statusSuccess : tierColor,
                    ),
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

class _PlatinumTrophyShowcaseSection extends StatelessWidget {
  final CareerAchievementsEngineState engineState;
  final CareerAchievementsSummary summary;
  final double width;
  final ValueChanged<CareerAchievementDefinition> onTapAchievement;
  final ValueChanged<CareerAchievementCategory> onFilterByCategory;
  final ValueChanged<CareerAchievementTier> onFilterByTier;

  const _PlatinumTrophyShowcaseSection({
    required this.engineState,
    required this.summary,
    required this.width,
    required this.onTapAchievement,
    required this.onFilterByCategory,
    required this.onFilterByTier,
  });

  @override
  Widget build(BuildContext context) {
    final platinum = summary.platinumTrophy;
    final isMobile = width < 700;

    final nextTargets = CareerAchievementsAndTrophiesEngine.catalog.where((d) {
      final p = engineState.progressById[d.id];
      return p != null && !p.isUnlocked;
    }).toList()
      ..sort((a, b) {
        final pa = engineState.progressById[a.id]?.progressRatio ?? 0.0;
        final pb = engineState.progressById[b.id]?.progressRatio ?? 0.0;
        final cmp = pb.compareTo(pa);
        return cmp != 0 ? cmp : a.codeNumber.compareTo(b.codeNumber);
      });

    final closest = nextTargets.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: platinum.isUnlocked
                  ? const [
                      Color(0xFF102331),
                      AppColors.surface,
                      Color(0xFF281F0E),
                    ]
                  : const [
                      AppColors.surfaceLight,
                      AppColors.surface,
                    ],
            ),
            border: Border.all(
              color: platinum.isUnlocked
                  ? AppColors.cyanAccent
                  : AppColors.goldAccent.withValues(alpha: 0.45),
              width: 1.4,
            ),
          ),
          child: isMobile
              ? Column(
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: _PlatinumTrophyEmblemPainter(
                          unlocked: platinum.isUnlocked,
                          progress: platinum.progressRatio,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PlatinumShowcaseDetails(platinum: platinum),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 164,
                      height: 164,
                      child: CustomPaint(
                        painter: _PlatinumTrophyEmblemPainter(
                          unlocked: platinum.isUnlocked,
                          progress: platinum.progressRatio,
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: _PlatinumShowcaseDetails(platinum: platinum),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 900;
            final tierPanel = _BreakdownCard(
              title: 'Postęp wg Rangi Trofeów',
              children: CareerAchievementTier.values.map((tier) {
                final unlocked = summary.unlockedByTier[tier] ?? 0;
                final total = summary.totalByTier[tier] ?? 0;
                final ratio = total > 0 ? unlocked / total : 0.0;
                return _BreakdownRow(
                  icon: tier.icon,
                  label: '${tier.labelPl} (+${tier.points} PKT)',
                  countText: '$unlocked / $total',
                  ratio: ratio,
                  color: tier.color,
                  onTap: () => onFilterByTier(tier),
                );
              }).toList(),
            );

            final categoryPanel = _BreakdownCard(
              title: 'Postęp wg Kategorii (6 x 10)',
              children: CareerAchievementCategory.values.map((cat) {
                final unlocked = summary.unlockedByCategory[cat] ?? 0;
                final total = summary.totalByCategory[cat] ?? 0;
                final ratio = total > 0 ? unlocked / total : 0.0;
                return _BreakdownRow(
                  icon: cat.icon,
                  label: cat.labelPl,
                  countText: '$unlocked / $total',
                  ratio: ratio,
                  color: AppColors.goldAccent,
                  onTap: () => onFilterByCategory(cat),
                );
              }).toList(),
            );

            if (!twoColumns) {
              return Column(
                children: [
                  tierPanel,
                  const SizedBox(height: 12),
                  categoryPanel,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tierPanel),
                const SizedBox(width: 14),
                Expanded(child: categoryPanel),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Najbliższe Wyzwania do Odblokowania',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (closest.isEmpty)
                const Text(
                  'Wszystkie 60 osiągnięć zostało ukończonych — Platynowe Trofeum jest Twoje!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.statusSuccess,
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: closest.map((def) {
                    final prog = engineState.progressById[def.id]!;
                    return SizedBox(
                      width: isMobile ? double.infinity : 320,
                      height: 156,
                      child: _AchievementTileCard(
                        definition: def,
                        progress: prog,
                        onTap: () => onTapAchievement(def),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlatinumShowcaseDetails extends StatelessWidget {
  final PlatinumTrophyRecord platinum;

  const _PlatinumShowcaseDetails({required this.platinum});

  @override
  Widget build(BuildContext context) {
    final accent =
        platinum.isUnlocked ? AppColors.cyanAccent : AppColors.goldAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Text(
            platinum.isUnlocked
                ? 'STATUS: PLATYNOWA LEGENDA'
                : 'STATUS: W TRAKCIE ZDOBYWANIA (${platinum.completionPercent}%)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          PlatinumTrophyRecord.platinumTitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          PlatinumTrophyRecord.platinumDescription,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: platinum.progressRatio,
            minHeight: 10,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _HeaderMetricBadge(
              label: 'WYMAGANE',
              value: '${platinum.unlockedCount}/${platinum.requiredCount}',
              accent: accent,
            ),
            const _HeaderMetricBadge(
              label: 'BONUS PLATYNY',
              value: '+${PlatinumTrophyRecord.platinumBonusPoints} PKT',
              accent: AppColors.goldAccent,
            ),
            _HeaderMetricBadge(
              label: 'PUNKTY RAZEM',
              value:
                  '${platinum.totalPointsEarned}/${platinum.maxPossiblePoints}',
              accent: AppColors.statusSuccess,
            ),
          ],
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _BreakdownCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String countText;
  final double ratio;
  final Color color;
  final VoidCallback onTap;

  const _BreakdownRow({
    required this.icon,
    required this.label,
    required this.countText,
    required this.ratio,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    countText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockHistorySection extends StatelessWidget {
  final CareerAchievementsEngineState engineState;
  final bool readOnly;
  final double width;
  final ValueChanged<CareerTrophyUnlockEvent> onReplayToast;
  final VoidCallback onClearPendingQueue;
  final ValueChanged<String> onInspectAchievement;

  const _UnlockHistorySection({
    required this.engineState,
    required this.readOnly,
    required this.width,
    required this.onReplayToast,
    required this.onClearPendingQueue,
    required this.onInspectAchievement,
  });

  @override
  Widget build(BuildContext context) {
    final history = engineState.unlockHistory.reversed.toList();
    final pendingCount = engineState.pendingToastQueue.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dziennik Odblokowanych Trofeów',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Łącznie odblokowanych: ${history.length} • W kolejce powiadomień: $pendingCount',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (pendingCount > 0)
                _InteractiveActionButton(
                  label: 'Wyczyść kolejkę ($pendingCount)',
                  icon: Icons.clear_all_rounded,
                  enabled: !readOnly,
                  accentColor: AppColors.primaryAccent,
                  onPressed: onClearPendingQueue,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 46,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 10),
                Text(
                  'Brak odblokowanych osiągnięć',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Wygrywaj etapy, klasyki i rozwijaj drużynę, aby zdobywać trofea i powiadomienia AchievementUnlockedToast.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final event = history[index];
              final accent = event.isPlatinumTrophy
                  ? AppColors.cyanAccent
                  : event.tier.color;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.45)),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ToastTrophyMedallion(
                          event: event,
                          accentColor: accent,
                        ),
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.max(180, width - 220),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.description,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (event.contextNote != null &&
                                  event.contextNote!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    'Kontekst: ${event.contextNote}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _HeaderMetricBadge(
                          label: event.tier.labelPl.toUpperCase(),
                          value: '+${event.pointsAwarded} PKT',
                          accent: accent,
                        ),
                        _InteractiveActionButton(
                          label: 'Pokaż Toast',
                          icon: Icons.notifications_rounded,
                          enabled: !readOnly,
                          accentColor: accent,
                          onPressed: () => onReplayToast(event),
                        ),
                        if (!event.isPlatinumTrophy)
                          _InteractiveIconButton(
                            icon: Icons.open_in_new_rounded,
                            tooltip: 'Szczegóły osiągnięcia',
                            enabled: true,
                            onPressed: () =>
                                onInspectAchievement(event.achievementId),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _AchievementDetailSheet extends ConsumerWidget {
  final CareerAchievementDefinition definition;
  final bool readOnly;
  final VoidCallback onIncrementProgress;
  final VoidCallback onUnlockNow;

  const _AchievementDetailSheet({
    required this.definition,
    required this.readOnly,
    required this.onIncrementProgress,
    required this.onUnlockNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerAchievementsProvider);
    final prog = state.progressById[definition.id] ??
        CareerAchievementProgress(
          achievementId: definition.id,
          currentValue: 0,
          targetValue: definition.targetValue,
          isUnlocked: false,
        );
    final unlocked = prog.isUnlocked;
    final tierColor = definition.tier.color;
    final isHiddenSecret = definition.isSecret && !unlocked;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked ? tierColor : AppTheme.borderColor,
            width: 1.4,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tierColor.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Icon(
                      isHiddenSecret ? Icons.lock_rounded : definition.icon,
                      color: tierColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${definition.codeNumber.toString().padLeft(2, '0')} • ${definition.category.labelPl} • ${definition.tier.labelPl}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: tierColor,
                          ),
                        ),
                        Text(
                          isHiddenSecret
                              ? 'Ukryte Osiągnięcie'
                              : definition.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _InteractiveIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Zamknij',
                    enabled: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isHiddenSecret
                    ? 'Warunek tego trofeum jest tajny i zostanie ujawniony po jego zdobyciu.'
                    : definition.description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: prog.progressRatio,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    unlocked ? AppColors.statusSuccess : tierColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unlocked
                        ? 'Ukończono (100%)'
                        : 'Postęp: ${prog.currentValue.toInt()} / ${prog.targetValue.toInt()}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: unlocked
                          ? AppColors.statusSuccess
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '+${definition.points} PKT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: tierColor,
                    ),
                  ),
                ],
              ),
              if (prog.contextNote != null &&
                  prog.contextNote!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Ostatni wpis: ${prog.contextNote}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (!readOnly && !unlocked) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _InteractiveActionButton(
                      label: 'Dodaj Postęp (+1)',
                      icon: Icons.add_rounded,
                      enabled: true,
                      accentColor: AppColors.accentBlue,
                      onPressed: onIncrementProgress,
                    ),
                    _InteractiveActionButton(
                      label: 'Odblokuj Trofeum',
                      icon: Icons.emoji_events_rounded,
                      enabled: true,
                      accentColor: AppColors.goldAccent,
                      onPressed: onUnlockNow,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFilterResultsCard extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _EmptyFilterResultsCard({required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak osiągnięć pasujących do filtrów',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Zmień kryteria wyszukiwania lub zresetuj filtry kategorii i rangi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _InteractiveActionButton(
            label: 'Wyczyść filtry',
            icon: Icons.refresh_rounded,
            enabled: true,
            accentColor: AppColors.goldAccent,
            onPressed: onClearFilters,
          ),
        ],
      ),
    );
  }
}

class _HeaderMetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _HeaderMetricBadge({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractivePillButton({
    required this.label,
    this.icon,
    required this.selected,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? widget.accentColor.withValues(alpha: 0.18)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final border = _focused
        ? AppColors.cyanAccent
        : widget.selected
            ? widget.accentColor
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.6)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 14,
                    color: widget.selected
                        ? widget.accentColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w600,
                    color: widget.selected
                        ? widget.accentColor
                        : AppColors.textPrimary,
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

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
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
    final effectiveColor =
        widget.enabled ? widget.accentColor : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: !widget.enabled
                  ? AppColors.background.withValues(alpha: 0.45)
                  : _hovered
                      ? effectiveColor.withValues(alpha: 0.24)
                      : effectiveColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: !widget.enabled
                    ? AppTheme.borderColor.withValues(alpha: 0.5)
                    : _focused
                        ? AppColors.cyanAccent
                        : effectiveColor.withValues(
                            alpha: _hovered ? 0.95 : 0.65,
                          ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.enabled
                      ? effectiveColor
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.enabled
                        ? effectiveColor
                        : AppColors.textSecondary.withValues(alpha: 0.5),
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

class _InteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onPressed;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    this.onPressed,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.enabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.cyanAccent
                      : _hovered
                          ? AppColors.goldAccent.withValues(alpha: 0.65)
                          : AppTheme.borderColor,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wektorowy emblemat Platynowego Trofeum rysowany przez `CustomPainter`.
class _PlatinumTrophyEmblemPainter extends CustomPainter {
  final bool unlocked;
  final double progress;

  const _PlatinumTrophyEmblemPainter({
    required this.unlocked,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.44;
    final primaryColor = unlocked ? AppColors.cyanAccent : AppColors.goldAccent;

    // Zewnętrzny pierścień koła kolarskiego i postępu
    final trackPaint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );

    // Szprychy koła w tle
    final spokePaint = Paint()
      ..color = primaryColor.withValues(alpha: unlocked ? 0.32 : 0.16)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final end = Offset(
        center.dx + math.cos(angle) * (radius - 6),
        center.dy + math.sin(angle) * (radius - 6),
      );
      canvas.drawLine(center, end, spokePaint);
    }

    // Kielich pucharu w środku
    final cupFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: unlocked
            ? [AppColors.cyanAccent, AppColors.goldAccent]
            : [
                AppColors.goldAccent.withValues(alpha: 0.55),
                AppColors.primaryAccent.withValues(alpha: 0.45),
              ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.6));

    final cupPath = Path()
      ..moveTo(center.dx - radius * 0.34, center.dy - radius * 0.32)
      ..lineTo(center.dx + radius * 0.34, center.dy - radius * 0.32)
      ..quadraticBezierTo(
        center.dx + radius * 0.28,
        center.dy + radius * 0.12,
        center.dx,
        center.dy + radius * 0.18,
      )
      ..quadraticBezierTo(
        center.dx - radius * 0.28,
        center.dy + radius * 0.12,
        center.dx - radius * 0.34,
        center.dy - radius * 0.32,
      )
      ..close();
    canvas.drawPath(cupPath, cupFill);

    // Trzon i podstawa pucharu
    final stemRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.28),
      width: radius * 0.14,
      height: radius * 0.22,
    );
    canvas.drawRect(stemRect, cupFill);

    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.42),
        width: radius * 0.46,
        height: radius * 0.13,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(baseRect, cupFill);
  }

  @override
  bool shouldRepaint(covariant _PlatinumTrophyEmblemPainter oldDelegate) {
    return oldDelegate.unlocked != unlocked || oldDelegate.progress != progress;
  }
}
