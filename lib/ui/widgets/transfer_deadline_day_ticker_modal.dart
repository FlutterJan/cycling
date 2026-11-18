// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/career/transfer_deadline_day_live_event.dart';

/// Zakładki prawego panelu studia telewizyjnego Transfer Deadline Day.
enum StudioTabMode {
  liveFeed,
  hotOffers,
  confirmedDeals;

  String get label {
    switch (this) {
      case StudioTabMode.liveFeed:
        return 'Breaking Feed';
      case StudioTabMode.hotOffers:
        return 'Gorące Oferty';
      case StudioTabMode.confirmedDeals:
        return 'Sfinalizowane';
    }
  }

  IconData get icon {
    switch (this) {
      case StudioTabMode.liveFeed:
        return Icons.rss_feed_rounded;
      case StudioTabMode.hotOffers:
        return Icons.local_fire_department_rounded;
      case StudioTabMode.confirmedDeals:
        return Icons.verified_rounded;
    }
  }
}

/// Otwiera modal studia telewizyjnego Transfer Deadline Day z paskiem Breaking News.
Future<void> showTransferDeadlineDayTickerModal(
  BuildContext context, {
  bool autoStartClock = false,
  VoidCallback? onOpenFullNegotiationDesk,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final isCompact = size.width < 700;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 24,
          vertical: isCompact ? 12 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1380,
            maxHeight: 860,
          ),
          child: TransferDeadlineDayTickerModal(
            autoStartClock: autoStartClock,
            onClose: () => Navigator.of(dialogContext).pop(),
            onOpenFullNegotiationDesk: onOpenFullNegotiationDesk,
          ),
        ),
      );
    },
  );
}

/// Studio telewizyjne Transfer Deadline Day z paskiem Breaking News na żywo.
///
/// Łączy się z [transferDeadlineDayProvider], prezentując relację ze studia TV,
/// odliczanie godzinowe z dokładnością co do minuty, analizę ekspertów, gorące
/// oferty last-minute oraz przewijany pasek wiadomości `Breaking News`.
class TransferDeadlineDayTickerModal extends ConsumerStatefulWidget {
  final bool autoStartClock;
  final VoidCallback? onClose;
  final VoidCallback? onOpenFullNegotiationDesk;

  const TransferDeadlineDayTickerModal({
    super.key,
    this.autoStartClock = false,
    this.onClose,
    this.onOpenFullNegotiationDesk,
  });

  @override
  ConsumerState<TransferDeadlineDayTickerModal> createState() =>
      _TransferDeadlineDayTickerModalState();
}

class _TransferDeadlineDayTickerModalState
    extends ConsumerState<TransferDeadlineDayTickerModal>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _marqueeController;
  late final ScrollController _marqueeScrollController;

  StudioTabMode _activeTab = StudioTabMode.liveFeed;
  DeadlineTickerCategory? _selectedCategory;
  String? _highlightedTickerId;
  bool _isTickerPaused = false;
  bool _isTickerHovered = false;
  double _lastMarqueeValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _marqueeScrollController = ScrollController();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )
      ..addListener(_advanceMarqueeScroll)
      ..repeat();

    if (widget.autoStartClock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(transferDeadlineDayProvider.notifier).startLiveClock();
      });
    }
  }

  void _advanceMarqueeScroll() {
    if (!mounted || _isTickerPaused || _isTickerHovered) {
      _lastMarqueeValue = _marqueeController.value;
      return;
    }
    if (!_marqueeScrollController.hasClients) {
      _lastMarqueeValue = _marqueeController.value;
      return;
    }
    final position = _marqueeScrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      _lastMarqueeValue = _marqueeController.value;
      return;
    }

    double delta = _marqueeController.value - _lastMarqueeValue;
    if (delta < 0) {
      delta += 1.0;
    }
    _lastMarqueeValue = _marqueeController.value;

    const double pixelsPerCycle = 960.0;
    final double nextOffset = position.pixels + (delta * pixelsPerCycle);
    if (nextOffset >= position.maxScrollExtent) {
      _marqueeScrollController.jumpTo(0.0);
    } else {
      _marqueeScrollController.jumpTo(nextOffset);
    }
  }

  @override
  void dispose() {
    _marqueeController.removeListener(_advanceMarqueeScroll);
    _marqueeController.dispose();
    _marqueeScrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleTickerPause() {
    setState(() {
      _isTickerPaused = !_isTickerPaused;
    });
  }

  void _cycleNextTickerStory(List<DeadlineTickerItem> items) {
    if (items.isEmpty) return;
    final currentIndex = _highlightedTickerId == null
        ? -1
        : items.indexWhere((e) => e.id == _highlightedTickerId);
    final nextIndex = (currentIndex + 1) % items.length;
    setState(() {
      _highlightedTickerId = items[nextIndex].id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferDeadlineDayProvider);
    final notifier = ref.read(transferDeadlineDayProvider.notifier);

    final filteredFeed = _selectedCategory == null
        ? state.tickerFeed
        : state.tickerFeed
            .where((item) => item.category == _selectedCategory)
            .toList();

    final highlightedItem = _resolveHighlightedItem(
      state.tickerFeed,
      filteredFeed,
    );

    final featuredOffer = _resolveFeaturedOffer(state);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 680;
            final isTablet = width >= 680 && width < 1040;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StudioTopBroadcastBar(
                  state: state,
                  pulseAnimation: _pulseController,
                  isCompact: isMobile,
                  onToggleClock: notifier.toggleLiveClock,
                  onSelectSpeed: notifier.setSpeedMultiplier,
                  onAdvance15m: () => notifier.advanceMinutes(15),
                  onClose: widget.onClose ?? () => Navigator.of(context).maybePop(),
                ),
                _StudioBudgetStrip(
                  state: state,
                  isCompact: isMobile,
                ),
                if (state.lastActionFeedback != null)
                  _StudioFeedbackStrip(
                    message: state.lastActionFeedback!,
                  ),
                Expanded(
                  child: isMobile
                      ? _buildMobileBody(
                          state: state,
                          notifier: notifier,
                          filteredFeed: filteredFeed,
                          highlightedItem: highlightedItem,
                          featuredOffer: featuredOffer,
                        )
                      : _buildWideBody(
                          state: state,
                          notifier: notifier,
                          filteredFeed: filteredFeed,
                          highlightedItem: highlightedItem,
                          featuredOffer: featuredOffer,
                          isTablet: isTablet,
                        ),
                ),
                BreakingNewsTickerBar(
                  items: filteredFeed.isEmpty ? state.tickerFeed : filteredFeed,
                  phase: state.currentPhase,
                  pulseAnimation: _pulseController,
                  scrollController: _marqueeScrollController,
                  isPaused: _isTickerPaused,
                  isCompact: isMobile,
                  highlightedId: highlightedItem?.id,
                  onTogglePause: _toggleTickerPause,
                  onNextStory: () => _cycleNextTickerStory(
                    filteredFeed.isEmpty ? state.tickerFeed : filteredFeed,
                  ),
                  onHoverChanged: (hovered) {
                    if (_isTickerHovered != hovered) {
                      setState(() => _isTickerHovered = hovered);
                    }
                  },
                  onSelectItem: (item) {
                    setState(() {
                      _highlightedTickerId = item.id;
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  DeadlineTickerItem? _resolveHighlightedItem(
    List<DeadlineTickerItem> allItems,
    List<DeadlineTickerItem> filteredItems,
  ) {
    if (_highlightedTickerId != null) {
      for (final item in allItems) {
        if (item.id == _highlightedTickerId) return item;
      }
    }
    if (filteredItems.isNotEmpty) return filteredItems.first;
    if (allItems.isNotEmpty) return allItems.first;
    return null;
  }

  LastMinuteAgentOffer? _resolveFeaturedOffer(TransferDeadlineDayState state) {
    if (state.selectedOffer != null && state.selectedOffer!.isActionable) {
      return state.selectedOffer;
    }
    final actionable = state.offers.where((o) => o.isActionable).toList();
    if (actionable.isEmpty) return null;
    actionable.sort((a, b) {
      final urgencyCmp = b.urgency.index.compareTo(a.urgency.index);
      if (urgencyCmp != 0) return urgencyCmp;
      return a.remainingOfferMinutes.compareTo(b.remainingOfferMinutes);
    });
    return actionable.first;
  }

  Widget _buildWideBody({
    required TransferDeadlineDayState state,
    required TransferDeadlineDayNotifier notifier,
    required List<DeadlineTickerItem> filteredFeed,
    required DeadlineTickerItem? highlightedItem,
    required LastMinuteAgentOffer? featuredOffer,
    required bool isTablet,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: isTablet ? 11 : 13,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _StudioAnchorAndSpotlightSection(
              state: state,
              highlightedItem: highlightedItem,
              featuredOffer: featuredOffer,
              isCompact: false,
              onAcceptOffer: (offerId) => notifier.acceptOffer(offerId),
              onRejectOffer: (offerId) => notifier.rejectOffer(offerId),
              onToggleShortlist: (offerId) => notifier.toggleShortlist(offerId),
              onSelectOfferForTab: (offerId) {
                notifier.selectOffer(offerId);
                setState(() => _activeTab = StudioTabMode.hotOffers);
              },
              onOpenFullNegotiationDesk: widget.onOpenFullNegotiationDesk,
            ),
          ),
        ),
        Container(
          width: 1,
          color: AppTheme.borderColor,
        ),
        Expanded(
          flex: isTablet ? 9 : 10,
          child: _StudioDealBoardSection(
            state: state,
            activeTab: _activeTab,
            selectedCategory: _selectedCategory,
            filteredFeed: filteredFeed,
            highlightedTickerId: highlightedItem?.id,
            isCompact: false,
            onTabChanged: (tab) => setState(() => _activeTab = tab),
            onCategoryChanged: (cat) =>
                setState(() => _selectedCategory = cat),
            onSelectTickerItem: (item) {
              setState(() => _highlightedTickerId = item.id);
            },
            onSelectOffer: notifier.selectOffer,
            onAcceptOffer: notifier.acceptOffer,
            onRejectOffer: notifier.rejectOffer,
            onToggleShortlist: notifier.toggleShortlist,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBody({
    required TransferDeadlineDayState state,
    required TransferDeadlineDayNotifier notifier,
    required List<DeadlineTickerItem> filteredFeed,
    required DeadlineTickerItem? highlightedItem,
    required LastMinuteAgentOffer? featuredOffer,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StudioAnchorAndSpotlightSection(
            state: state,
            highlightedItem: highlightedItem,
            featuredOffer: featuredOffer,
            isCompact: true,
            onAcceptOffer: (offerId) => notifier.acceptOffer(offerId),
            onRejectOffer: (offerId) => notifier.rejectOffer(offerId),
            onToggleShortlist: (offerId) => notifier.toggleShortlist(offerId),
            onSelectOfferForTab: (offerId) {
              notifier.selectOffer(offerId);
              setState(() => _activeTab = StudioTabMode.hotOffers);
            },
            onOpenFullNegotiationDesk: widget.onOpenFullNegotiationDesk,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 380,
            child: _StudioDealBoardSection(
              state: state,
              activeTab: _activeTab,
              selectedCategory: _selectedCategory,
              filteredFeed: filteredFeed,
              highlightedTickerId: highlightedItem?.id,
              isCompact: true,
              onTabChanged: (tab) => setState(() => _activeTab = tab),
              onCategoryChanged: (cat) =>
                  setState(() => _selectedCategory = cat),
              onSelectTickerItem: (item) {
                setState(() => _highlightedTickerId = item.id);
              },
              onSelectOffer: notifier.selectOffer,
              onAcceptOffer: notifier.acceptOffer,
              onRejectOffer: notifier.rejectOffer,
              onToggleShortlist: notifier.toggleShortlist,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rysuje tło studia telewizyjnego z subtelnym oświetleniem scenicznym i liniami transmisji.
class StudioBroadcastBackdropPainter extends CustomPainter {
  final Color phaseAccent;
  final double pulseValue;

  const StudioBroadcastBackdropPainter({
    required this.phaseAccent,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surface,
          AppColors.background,
          AppColors.surfaceLight.withValues(alpha: 0.72),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // Oświetlenie sceniczne (burgund i złoto / akcent fazy).
    final leftSpotlight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.75, -0.8),
        radius: 1.15,
        colors: [
          AppColors.primaryAccent.withValues(alpha: 0.22 + (pulseValue * 0.06)),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, leftSpotlight);

    final rightSpotlight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.65),
        radius: 1.0,
        colors: [
          phaseAccent.withValues(alpha: 0.16 + (pulseValue * 0.05)),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, rightSpotlight);

    // Subtelne linie siatki telewizyjnej (scanlines).
    final scanlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1.0;
    for (double y = 6; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // Dekoracyjna linia horyzontu stołu prezenterskiego.
    final deskLineY = size.height * 0.88;
    final deskLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.goldAccent.withValues(alpha: 0.35),
          phaseAccent.withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, deskLineY, size.width, 2));
    canvas.drawRect(
      Rect.fromLTWH(0, deskLineY, size.width, 1.5),
      deskLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant StudioBroadcastBackdropPainter oldDelegate) {
    return oldDelegate.phaseAccent != phaseAccent ||
        (oldDelegate.pulseValue - pulseValue).abs() > 0.04;
  }
}

class _StudioTopBroadcastBar extends StatelessWidget {
  final TransferDeadlineDayState state;
  final Animation<double> pulseAnimation;
  final bool isCompact;
  final VoidCallback onToggleClock;
  final ValueChanged<int> onSelectSpeed;
  final VoidCallback onAdvance15m;
  final VoidCallback onClose;

  const _StudioTopBroadcastBar({
    required this.state,
    required this.pulseAnimation,
    required this.isCompact,
    required this.onToggleClock,
    required this.onSelectSpeed,
    required this.onAdvance15m,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final phase = state.currentPhase;
    final isClosed = state.isWindowClosed;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 18,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
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
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  final dotAlpha = state.isLiveTicking && !isClosed
                      ? 0.45 + (pulseAnimation.value * 0.55)
                      : 0.85;
                  final badgeColor = isClosed
                      ? AppColors.textSecondary
                      : (state.isLiveTicking
                          ? AppColors.crimsonAlert
                          : AppColors.amberWarning);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.55),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: badgeColor.withValues(alpha: dotAlpha),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isClosed
                              ? 'OFF AIR'
                              : (state.isLiveTicking ? 'ON AIR' : 'PAUZA'),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'PELOTON SPORT TV',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                            color: AppColors.goldAccent,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: phase.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            phase.label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: phase.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompact
                          ? 'Deadline Day Studio'
                          : 'Transfer Deadline Day — Studio Na Żywo (${state.config.teamName})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
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
              // Zegar transmisji TV.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: phase.accentColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: phase.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.formattedCountdown,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: phase.accentColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.currentClockLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              _StudioInteractiveButton(
                label: state.isLiveTicking ? 'Pauza' : 'Start',
                icon: state.isLiveTicking
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                accentColor: state.isLiveTicking
                    ? AppColors.amberWarning
                    : AppColors.statusSuccess,
                isDisabled: isClosed,
                onTap: onToggleClock,
                compact: true,
              ),
              if (!isCompact)
                _StudioSpeedSelector(
                  currentSpeed: state.simulationSpeedMultiplier,
                  isDisabled: isClosed,
                  onSelectSpeed: onSelectSpeed,
                ),
              _StudioInteractiveButton(
                label: '+15m',
                icon: Icons.fast_forward_rounded,
                accentColor: AppColors.accentBlue,
                isDisabled: isClosed,
                onTap: onAdvance15m,
                compact: true,
              ),
              _StudioInteractiveButton(
                label: isCompact ? '' : 'Zamknij',
                icon: Icons.close_rounded,
                accentColor: AppColors.textSecondary,
                onTap: onClose,
                compact: true,
                tooltip: 'Zamknij studio',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudioSpeedSelector extends StatelessWidget {
  final int currentSpeed;
  final bool isDisabled;
  final ValueChanged<int> onSelectSpeed;

  const _StudioSpeedSelector({
    required this.currentSpeed,
    required this.isDisabled,
    required this.onSelectSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [1, 2, 5].map((speed) {
          final isSelected = currentSpeed == speed;
          return _StudioInteractiveChip(
            label: '${speed}x',
            isSelected: isSelected,
            isDisabled: isDisabled,
            accentColor: AppColors.goldAccent,
            onTap: () => onSelectSpeed(speed),
          );
        }).toList(),
      ),
    );
  }
}

class _StudioBudgetStrip extends StatelessWidget {
  final TransferDeadlineDayState state;
  final bool isCompact;

  const _StudioBudgetStrip({
    required this.state,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 18,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: [
          _TelemetryPill(
            label: 'Budżet płac',
            value: _formatEur(state.remainingWageBudgetEur),
            color: AppColors.statusSuccess,
          ),
          _TelemetryPill(
            label: 'Budżet transf.',
            value: _formatEur(state.remainingTransferBudgetEur),
            color: AppColors.accentBlue,
          ),
          _TelemetryPill(
            label: 'Wolne sloty',
            value: '${state.remainingRosterSlots}',
            color: state.remainingRosterSlots > 0
                ? AppColors.goldAccent
                : AppColors.crimsonAlert,
          ),
          _TelemetryPill(
            label: 'Aktywne oferty',
            value: '${state.activeOffersCount}',
            color: AppColors.textPrimary,
          ),
          _TelemetryPill(
            label: 'Pilne (<30m)',
            value: '${state.expiringSoonCount}',
            color: state.expiringSoonCount > 0
                ? AppColors.crimsonAlert
                : AppColors.textSecondary,
          ),
          _TelemetryPill(
            label: 'Podpisane',
            value: '${state.completedDeals.length}',
            color: AppColors.statusSuccess,
          ),
        ],
      ),
    );
  }
}

class _TelemetryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioFeedbackStrip extends StatelessWidget {
  final String message;

  const _StudioFeedbackStrip({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.12),
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_rounded,
            size: 16,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioAnchorAndSpotlightSection extends StatelessWidget {
  final TransferDeadlineDayState state;
  final DeadlineTickerItem? highlightedItem;
  final LastMinuteAgentOffer? featuredOffer;
  final bool isCompact;
  final ValueChanged<String> onAcceptOffer;
  final ValueChanged<String> onRejectOffer;
  final ValueChanged<String> onToggleShortlist;
  final ValueChanged<String> onSelectOfferForTab;
  final VoidCallback? onOpenFullNegotiationDesk;

  const _StudioAnchorAndSpotlightSection({
    required this.state,
    required this.highlightedItem,
    required this.featuredOffer,
    required this.isCompact,
    required this.onAcceptOffer,
    required this.onRejectOffer,
    required this.onToggleShortlist,
    required this.onSelectOfferForTab,
    this.onOpenFullNegotiationDesk,
  });

  @override
  Widget build(BuildContext context) {
    final commentary = _buildStudioCommentary(state);
    final activeHighlight = highlightedItem;
    final activeOffer = featuredOffer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scena studia TV z komentatorami.
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: StudioBroadcastBackdropPainter(
              phaseAccent: state.currentPhase.accentColor,
              pulseValue: state.isLiveTicking ? 0.8 : 0.2,
            ),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.55),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.live_tv_rounded,
                          color: AppColors.goldAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STANOWISKO EKSPERCKIE • STUDIO CENTRALNE',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.goldAccent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              commentary.anchorHeadline,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.mic_rounded,
                              size: 14,
                              color: AppColors.accentBlue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                commentary.punditName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          commentary.punditQuote,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textPrimary,
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
        const SizedBox(height: 14),
        // Karta wyróżnionej wiadomości Breaking News.
        if (activeHighlight != null)
          _HighlightedBreakingNewsCard(item: activeHighlight),
        const SizedBox(height: 14),
        // Karta najgorętszej oferty lub podsumowania po zamknięciu okna.
        if (state.isWindowClosed)
          _StudioWindowClosedCard(state: state)
        else if (activeOffer != null)
          _StudioFeaturedOfferCard(
            offer: activeOffer,
            state: state,
            isCompact: isCompact,
            onAccept: () => onAcceptOffer(activeOffer.id),
            onReject: () => onRejectOffer(activeOffer.id),
            onToggleShortlist: () => onToggleShortlist(activeOffer.id),
            onInspectAll: () => onSelectOfferForTab(activeOffer.id),
            onOpenFullNegotiationDesk: onOpenFullNegotiationDesk,
          )
        else
          _EmptySpotlightCard(
            onOpenFullNegotiationDesk: onOpenFullNegotiationDesk,
          ),
      ],
    );
  }

  _StudioCommentaryData _buildStudioCommentary(TransferDeadlineDayState state) {
    if (state.isWindowClosed) {
      return _StudioCommentaryData(
        anchorHeadline: 'Okno transferowe UCI zostało oficjalnie zamknięte!',
        punditName: 'Marek Zieliński • Ekspert Kolarski',
        punditQuote: state.completedDeals.isEmpty
            ? 'Ekipa ${state.config.teamName} zachowała pełną dyscyplinę budżetową i wchodzi w nowy sezon obecną kadrą.'
            : 'Znakomita końcówka w wykonaniu ${state.config.teamName} — sfinalizowano ${state.completedDeals.length} transfer(y) w ostatnich godzinach okna!',
      );
    }

    switch (state.currentPhase) {
      case DeadlinePhase.openingHours:
        return const _StudioCommentaryData(
          anchorHeadline: 'Spokojne badanie rynku i pierwsze telefony agentów',
          punditName: 'Marek Zieliński • Ekspert Kolarski',
          punditQuote:
              'Agenci zaczynają rozsyłać oferty okazyjne. Warto obserwować wolnych agentów i budować krótką listę przed popołudniowym szczytem.',
        );
      case DeadlinePhase.afternoonRush:
        return _StudioCommentaryData(
          anchorHeadline: 'Gorączka popołudniowa — rywale podbijają stawki!',
          punditName: 'Anna Nowak • Dyrektor ds. Skautingu',
          punditQuote:
              'W tej fazie rywale z WorldTouru często przechwytują niezdecydowanych kolarzy. Masz ${state.activeOffersCount} aktywnych ofert na biurku.',
        );
      case DeadlinePhase.goldenHour:
        return _StudioCommentaryData(
          anchorHeadline: 'Ostatnia godzina! Faksy i umowy rozgrzane do czerwoności',
          punditName: 'Marek Zieliński • Ekspert Kolarski',
          punditQuote:
              'Pozostało ${state.formattedCountdown}. ${state.expiringSoonCount} ofert wygasa lada moment — czas na odważne decyzje kontraktowe!',
        );
      case DeadlinePhase.finalMinutes:
        return _StudioCommentaryData(
          anchorHeadline: 'FINAŁOWE MINUTY! Wyścig z czasem przed północą!',
          punditName: 'Anna Nowak • Dyrektor ds. Skautingu',
          punditQuote:
              'Każda minuta decyduje o rejestracji w systemie UCI! Jeśli masz wolne sloty (${state.remainingRosterSlots}), podpisuj natychmiast!',
        );
      case DeadlinePhase.windowClosed:
        return const _StudioCommentaryData(
          anchorHeadline: 'Okno transferowe zamknięte',
          punditName: 'Studio Peloton Sport TV',
          punditQuote: 'Dziękujemy za śledzenie relacji na żywo.',
        );
    }
  }
}

class _StudioCommentaryData {
  final String anchorHeadline;
  final String punditName;
  final String punditQuote;

  const _StudioCommentaryData({
    required this.anchorHeadline,
    required this.punditName,
    required this.punditQuote,
  });
}

class _HighlightedBreakingNewsCard extends StatelessWidget {
  final DeadlineTickerItem item;

  const _HighlightedBreakingNewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isBreaking ? AppColors.crimsonAlert : item.category.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isBreaking ? 'PILNE • ${item.category.tag}' : item.category.tag,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.timestampLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.newspaper_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.headline,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtext,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioFeaturedOfferCard extends StatelessWidget {
  final LastMinuteAgentOffer offer;
  final TransferDeadlineDayState state;
  final bool isCompact;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onToggleShortlist;
  final VoidCallback onInspectAll;
  final VoidCallback? onOpenFullNegotiationDesk;

  const _StudioFeaturedOfferCard({
    required this.offer,
    required this.state,
    required this.isCompact,
    required this.onAccept,
    required this.onReject,
    required this.onToggleShortlist,
    required this.onInspectAll,
    this.onOpenFullNegotiationDesk,
  });

  @override
  Widget build(BuildContext context) {
    final canAffordWage =
        state.remainingWageBudgetEur >= offer.askingSalaryEur;
    final upFrontCost = offer.signingBonusEur + offer.releaseBuyoutEur;
    final canAffordTransfer = state.remainingTransferBudgetEur >= upFrontCost;
    final hasSlot = state.remainingRosterSlots > 0;
    final canAccept =
        offer.isActionable && !state.isWindowClosed && canAffordWage && canAffordTransfer && hasSlot;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: offer.urgency.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'GORĄCA OFERTA • ${offer.urgency.label.toUpperCase()}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: offer.urgency.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Wygasa za ${offer.remainingOfferMinutes}m',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: offer.isExpiringSoon
                      ? AppColors.crimsonAlert
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldAccent, width: 1),
                ),
                child: Text(
                  '${offer.overallRating}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${offer.riderName} (${offer.nationalityCode}, ${offer.age} l.)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${offer.specialty.label} • Poprzednio: ${offer.previousTeamName}',
                      style: const TextStyle(
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
          const SizedBox(height: 10),
          Text(
            '„${offer.agentPitch}” — ${offer.agent.name}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _TelemetryPill(
                label: 'Pensja/rok',
                value: _formatEur(offer.askingSalaryEur),
                color: canAffordWage
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              _TelemetryPill(
                label: 'Koszt startowy',
                value: _formatEur(upFrontCost),
                color: canAffordTransfer
                    ? AppColors.accentBlue
                    : AppColors.crimsonAlert,
              ),
              _TelemetryPill(
                label: 'Kontrakt',
                value: '${offer.contractYears} lat(a)',
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StudioInteractiveButton(
                label: 'Podpisz teraz',
                icon: Icons.check_circle_outline_rounded,
                accentColor: AppColors.statusSuccess,
                isDisabled: !canAccept,
                onTap: onAccept,
              ),
              _StudioInteractiveButton(
                label: offer.isShortlisted ? 'Obserwowany' : 'Obserwuj',
                icon: offer.isShortlisted
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                accentColor: AppColors.goldAccent,
                onTap: onToggleShortlist,
              ),
              _StudioInteractiveButton(
                label: 'Odrzuć',
                icon: Icons.cancel_outlined,
                accentColor: AppColors.crimsonAlert,
                isDisabled: !offer.isActionable || state.isWindowClosed,
                onTap: onReject,
              ),
              if (onOpenFullNegotiationDesk != null)
                _StudioInteractiveButton(
                  label: 'Stół Negocjacyjny',
                  icon: Icons.gavel_rounded,
                  accentColor: AppColors.accentBlue,
                  onTap: onOpenFullNegotiationDesk!,
                )
              else
                _StudioInteractiveButton(
                  label: 'Lista ofert',
                  icon: Icons.list_alt_rounded,
                  accentColor: AppColors.accentBlue,
                  onTap: onInspectAll,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudioWindowClosedCard extends StatelessWidget {
  final TransferDeadlineDayState state;

  const _StudioWindowClosedCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: AppColors.goldAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'RAPORT KOŃCOWY STUDIA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Podpisane kontrakty: ${state.completedDeals.length} • Pozostały budżet płacowy: ${_formatEur(state.remainingWageBudgetEur)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySpotlightCard extends StatelessWidget {
  final VoidCallback? onOpenFullNegotiationDesk;

  const _EmptySpotlightCard({this.onOpenFullNegotiationDesk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Brak aktywnych ofert na tę chwilę. Przyspiesz zegar lub uruchom transmisję na żywo, aby odebrać nowe telefony od agentów.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (onOpenFullNegotiationDesk != null) ...[
            const SizedBox(width: 10),
            _StudioInteractiveButton(
              label: 'Negocjacje',
              icon: Icons.open_in_new_rounded,
              accentColor: AppColors.accentBlue,
              onTap: onOpenFullNegotiationDesk!,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _StudioDealBoardSection extends StatelessWidget {
  final TransferDeadlineDayState state;
  final StudioTabMode activeTab;
  final DeadlineTickerCategory? selectedCategory;
  final List<DeadlineTickerItem> filteredFeed;
  final String? highlightedTickerId;
  final bool isCompact;
  final ValueChanged<StudioTabMode> onTabChanged;
  final ValueChanged<DeadlineTickerCategory?> onCategoryChanged;
  final ValueChanged<DeadlineTickerItem> onSelectTickerItem;
  final ValueChanged<String> onSelectOffer;
  final ValueChanged<String> onAcceptOffer;
  final ValueChanged<String> onRejectOffer;
  final ValueChanged<String> onToggleShortlist;

  const _StudioDealBoardSection({
    required this.state,
    required this.activeTab,
    required this.selectedCategory,
    required this.filteredFeed,
    required this.highlightedTickerId,
    required this.isCompact,
    required this.onTabChanged,
    required this.onCategoryChanged,
    required this.onSelectTickerItem,
    required this.onSelectOffer,
    required this.onAcceptOffer,
    required this.onRejectOffer,
    required this.onToggleShortlist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isCompact
          ? BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor, width: 1.0),
            )
          : const BoxDecoration(color: AppColors.background),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
              ),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: StudioTabMode.values.map((tab) {
                final count = switch (tab) {
                  StudioTabMode.liveFeed => state.tickerFeed.length,
                  StudioTabMode.hotOffers => state.activeOffersCount,
                  StudioTabMode.confirmedDeals => state.completedDeals.length,
                };
                return _StudioInteractiveChip(
                  label: '${tab.label} ($count)',
                  icon: tab.icon,
                  isSelected: activeTab == tab,
                  accentColor: AppColors.goldAccent,
                  onTap: () => onTabChanged(tab),
                );
              }).toList(),
            ),
          ),
          if (activeTab == StudioTabMode.liveFeed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StudioInteractiveChip(
                      label: 'Wszystkie',
                      isSelected: selectedCategory == null,
                      accentColor: AppColors.accentBlue,
                      onTap: () => onCategoryChanged(null),
                    ),
                    const SizedBox(width: 6),
                    ...DeadlineTickerCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _StudioInteractiveChip(
                          label: cat.tag,
                          isSelected: selectedCategory == cat,
                          accentColor: cat.color,
                          onTap: () => onCategoryChanged(
                            selectedCategory == cat ? null : cat,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          Expanded(
            child: switch (activeTab) {
              StudioTabMode.liveFeed => _buildFeedList(),
              StudioTabMode.hotOffers => _buildOffersList(),
              StudioTabMode.confirmedDeals => _buildDealsList(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList() {
    if (filteredFeed.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Brak wiadomości w wybranej kategorii.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filteredFeed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = filteredFeed[index];
        final isSelected = item.id == highlightedTickerId;
        return _TickerFeedRowCard(
          item: item,
          isSelected: isSelected,
          onTap: () => onSelectTickerItem(item),
        );
      },
    );
  }

  Widget _buildOffersList() {
    final offers = state.offers;
    if (offers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Brak ofert transferowych w kolejce.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final offer = offers[index];
        return _StudioCompactOfferRow(
          offer: offer,
          isSelected: state.selectedOfferId == offer.id,
          isWindowClosed: state.isWindowClosed,
          onSelect: () => onSelectOffer(offer.id),
          onAccept: () => onAcceptOffer(offer.id),
          onToggleShortlist: () => onToggleShortlist(offer.id),
        );
      },
    );
  }

  Widget _buildDealsList() {
    final deals = state.completedDeals;
    if (deals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Nie sfinalizowano jeszcze żadnego transferu w tym oknie.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: deals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final deal = deals[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.statusSuccess.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: AppColors.statusSuccess,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      deal.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    deal.completedAtLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${deal.dealTypeLabel} • ${_formatEur(deal.annualSalaryEur)}/rok • ${deal.contractYears} lat(a)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deal.mediaReaction,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TickerFeedRowCard extends StatefulWidget {
  final DeadlineTickerItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TickerFeedRowCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TickerFeedRowCard> createState() => _TickerFeedRowCardState();
}

class _TickerFeedRowCardState extends State<_TickerFeedRowCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.item.isBreaking
        ? AppColors.crimsonAlert
        : widget.item.category.color;
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isSelected
            ? accent
            : (_hovered ? accent.withValues(alpha: 0.65) : AppTheme.borderColor));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
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
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.99 : 1.0,
              _pressed ? 0.99 : 1.0,
              1.0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected || _hovered
                  ? AppColors.surfaceLight
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        widget.item.category.tag,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.item.timestampLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (widget.item.isBreaking) ...[
                      const Spacer(),
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppColors.crimsonAlert,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.headline,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.subtext,
                  maxLines: 2,
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
        ),
      ),
    );
  }
}

class _StudioCompactOfferRow extends StatefulWidget {
  final LastMinuteAgentOffer offer;
  final bool isSelected;
  final bool isWindowClosed;
  final VoidCallback onSelect;
  final VoidCallback onAccept;
  final VoidCallback onToggleShortlist;

  const _StudioCompactOfferRow({
    required this.offer,
    required this.isSelected,
    required this.isWindowClosed,
    required this.onSelect,
    required this.onAccept,
    required this.onToggleShortlist,
  });

  @override
  State<_StudioCompactOfferRow> createState() => _StudioCompactOfferRowState();
}

class _StudioCompactOfferRowState extends State<_StudioCompactOfferRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected || _hovered
                ? AppColors.surfaceLight
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: offer.urgency.color, width: 1),
                ),
                child: Text(
                  '${offer.overallRating}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: offer.urgency.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.riderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${offer.specialty.label} • ${_formatEur(offer.askingSalaryEur)} • ${offer.status.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: offer.isActionable
                            ? AppColors.textSecondary
                            : offer.status.color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: offer.isShortlisted ? 'Usuń z obserwowanych' : 'Obserwuj',
                onPressed: widget.onToggleShortlist,
                icon: Icon(
                  offer.isShortlisted
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 18,
                  color: offer.isShortlisted
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
              ),
              if (offer.isActionable && !widget.isWindowClosed)
                _StudioInteractiveButton(
                  label: 'Podpisz',
                  icon: Icons.check_rounded,
                  accentColor: AppColors.statusSuccess,
                  onTap: widget.onAccept,
                  compact: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pasek przewijanych wiadomości telewizyjnych Breaking News na dole studia.
class BreakingNewsTickerBar extends StatelessWidget {
  final List<DeadlineTickerItem> items;
  final DeadlinePhase phase;
  final Animation<double> pulseAnimation;
  final ScrollController scrollController;
  final bool isPaused;
  final bool isCompact;
  final String? highlightedId;
  final VoidCallback onTogglePause;
  final VoidCallback onNextStory;
  final ValueChanged<bool> onHoverChanged;
  final ValueChanged<DeadlineTickerItem> onSelectItem;

  const BreakingNewsTickerBar({
    super.key,
    required this.items,
    required this.phase,
    required this.pulseAnimation,
    required this.scrollController,
    required this.isPaused,
    required this.isCompact,
    required this.highlightedId,
    required this.onTogglePause,
    required this.onNextStory,
    required this.onHoverChanged,
    required this.onSelectItem,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = phase == DeadlinePhase.windowClosed
        ? AppColors.textSecondary
        : AppColors.crimsonAlert;

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: Container(
        height: 46,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1.0),
          ),
        ),
        child: Row(
          children: [
            // Zakotwiczona plakietka BREAKING NEWS.
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, _) {
                return Container(
                  height: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 14,
                  ),
                  color: badgeColor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: 0.55 + (pulseAnimation.value * 0.45),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCompact ? 'PILNE' : 'BREAKING NEWS',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Przewijany pasek wiadomości.
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'Oczekiwanie na depesze z rynku transferowego UCI...',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length * 4,
                      itemBuilder: (context, index) {
                        final item = items[index % items.length];
                        final isHighlighted = item.id == highlightedId;
                        return InkWell(
                          onTap: () => onSelectItem(item),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? AppColors.surfaceLight
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.category.color
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.category.tag,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: item.category.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.timestampLabel} • ${item.headline}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  '///',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.goldAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Kontrolki paska wiadomości.
            Container(
              height: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(
                  left: BorderSide(color: AppTheme.borderColor, width: 1.0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isPaused ? 'Wznów pasek' : 'Zatrzymaj pasek',
                    onPressed: onTogglePause,
                    icon: Icon(
                      isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 18,
                      color: isPaused
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Następny news',
                    onPressed: items.isEmpty ? null : onNextStory,
                    icon: Icon(
                      Icons.skip_next_rounded,
                      size: 18,
                      color: items.isEmpty
                          ? AppColors.textSecondary.withValues(alpha: 0.4)
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudioInteractiveButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isDisabled;
  final bool compact;
  final String? tooltip;
  final VoidCallback onTap;

  const _StudioInteractiveButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.isDisabled = false,
    this.compact = false,
    this.tooltip,
  });

  @override
  State<_StudioInteractiveButton> createState() =>
      _StudioInteractiveButtonState();
}

class _StudioInteractiveButtonState extends State<_StudioInteractiveButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.accentColor;
    final bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? effectiveAccent.withValues(alpha: 0.28)
            : (_hovered
                ? effectiveAccent.withValues(alpha: 0.20)
                : effectiveAccent.withValues(alpha: 0.12)));

    final button = FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.isDisabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: widget.isDisabled ? null : () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: MouseRegion(
          cursor: widget.isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.97 : 1.0,
              _pressed ? 0.97 : 1.0,
              1.0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 12,
              vertical: widget.compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : effectiveAccent.withValues(
                        alpha: widget.isDisabled ? 0.2 : 0.55,
                      ),
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: effectiveAccent),
                if (widget.label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: effectiveAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

class _StudioInteractiveChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _StudioInteractiveChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    this.icon,
    this.isDisabled = false,
  });

  @override
  State<_StudioInteractiveChip> createState() => _StudioInteractiveChipState();
}

class _StudioInteractiveChipState extends State<_StudioInteractiveChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : (widget.isSelected ? widget.accentColor : AppColors.textSecondary);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.isDisabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: MouseRegion(
          cursor: widget.isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.accentColor.withValues(alpha: 0.18)
                  : (_hovered
                      ? AppColors.surfaceLight
                      : AppColors.background.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.isSelected
                        ? widget.accentColor.withValues(alpha: 0.65)
                        : AppTheme.borderColor),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 13, color: color),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: color,
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

String _formatEur(int amount) {
  final absAmount = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (absAmount >= 1000000) {
    final m = absAmount / 1000000.0;
    return '$sign€${m.toStringAsFixed(2)}M';
  }
  if (absAmount >= 1000) {
    final k = (absAmount / 1000.0).round();
    return '$sign€${k}k';
  }
  return '$sign€$absAmount';
}
