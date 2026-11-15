import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/career/social_media_and_cycling_news_service.dart';

/// Filtr kategorii dla strumienia mediów kolarskich.
enum CyclingNewsFilter {
  all,
  racesAndPreviews,
  wattAndVam,
  transfers,
  riderSocial;

  String get label {
    switch (this) {
      case CyclingNewsFilter.all:
        return 'Wszystkie';
      case CyclingNewsFilter.racesAndPreviews:
        return 'Wyścigi & 5★';
      case CyclingNewsFilter.wattAndVam:
        return 'Waty & VAM';
      case CyclingNewsFilter.transfers:
        return 'Transfery';
      case CyclingNewsFilter.riderSocial:
        return 'Social Kolarzy';
    }
  }

  bool matches(CyclingNewsItem item) {
    switch (this) {
      case CyclingNewsFilter.all:
        return true;
      case CyclingNewsFilter.racesAndPreviews:
        return item.type == CyclingNewsItemType.stagePreview ||
            item.type == CyclingNewsItemType.raceReport ||
            item.type == CyclingNewsItemType.crashAnalysis;
      case CyclingNewsFilter.wattAndVam:
        return item.type == CyclingNewsItemType.wattAndVamAnalysis;
      case CyclingNewsFilter.transfers:
        return item.type == CyclingNewsItemType.transferRumor;
      case CyclingNewsFilter.riderSocial:
        return item.type == CyclingNewsItemType.riderSocialPost;
    }
  }
}

/// Dedykowany widget strumienia mediów kolarskich (*Cyclingnews / ProCyclingStats / VeloNews*)
/// oraz wpisów społecznościowych kolarzy z danymi z ich komputerów rowerowych.
class CyclingNewsFeedWidget extends StatefulWidget {
  final List<CyclingNewsItem> items;
  final ValueChanged<String>? onToggleLike;
  final ValueChanged<String>? onToggleBookmark;
  final VoidCallback? onRefresh;
  final int maxVisibleItems;

  const CyclingNewsFeedWidget({
    super.key,
    required this.items,
    this.onToggleLike,
    this.onToggleBookmark,
    this.onRefresh,
    this.maxVisibleItems = 6,
  });

  @override
  State<CyclingNewsFeedWidget> createState() => _CyclingNewsFeedWidgetState();
}

class _CyclingNewsFeedWidgetState extends State<CyclingNewsFeedWidget> {
  CyclingNewsFilter _activeFilter = CyclingNewsFilter.all;
  bool _onlyPlayerTeam = false;
  bool _onlyBookmarked = false;
  bool _isRefreshHovered = false;

  List<CyclingNewsItem> get _filteredItems {
    return widget.items.where((item) {
      if (!_activeFilter.matches(item)) return false;
      if (_onlyPlayerTeam && !item.isPlayerTeamRelated) return false;
      if (_onlyBookmarked && !item.isBookmarked) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final visible = filtered.take(widget.maxVisibleItems).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 520;
        final bool isWideDesktop = constraints.maxWidth >= 960;

        return Container(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isCompact, filtered.length),
              const SizedBox(height: 12),
              _buildFilterBar(isCompact),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                _buildEmptyState()
              else if (isWideDesktop)
                _buildDesktopTwoColumnFeed(visible)
              else
                Column(
                  children: [
                    for (int i = 0; i < visible.length; i++) ...[
                      _NewsFeedCard(
                        item: visible[i],
                        isCompact: isCompact,
                        onToggleLike: widget.onToggleLike,
                        onToggleBookmark: widget.onToggleBookmark,
                        onOpenDetail: () => _openArticleModal(context, visible[i]),
                      ),
                      if (i < visible.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact, int totalCount) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.newspaper_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'MEDIA KOLARSKIE & PELOTON SOCIAL',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.goldAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.statusSuccess.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          '$totalCount WPISÓW',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.statusSuccess,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompact
                        ? 'Cyclingnews • PCS • VeloNews • Liczniki'
                        : 'Cyclingnews • ProCyclingStats • VeloNews • Dane z liczników zawodników',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
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
            _buildTogglePill(
              label: 'Moja ekipa',
              icon: Icons.shield_rounded,
              active: _onlyPlayerTeam,
              activeColor: AppColors.goldAccent,
              onTap: () => setState(() => _onlyPlayerTeam = !_onlyPlayerTeam),
            ),
            _buildTogglePill(
              label: 'Zapisane',
              icon: Icons.bookmark_rounded,
              active: _onlyBookmarked,
              activeColor: AppColors.cyanAccent,
              onTap: () => setState(() => _onlyBookmarked = !_onlyBookmarked),
            ),
            MouseRegion(
              onEnter: (_) => setState(() => _isRefreshHovered = true),
              onExit: (_) => setState(() => _isRefreshHovered = false),
              child: InkWell(
                onTap: widget.onRefresh,
                borderRadius: BorderRadius.circular(10),
                focusColor: AppColors.goldAccent.withValues(alpha: 0.2),
                hoverColor: AppColors.surfaceLight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: widget.onRefresh == null
                        ? AppColors.surfaceLight.withValues(alpha: 0.45)
                        : (_isRefreshHovered
                            ? AppColors.primaryAccent.withValues(alpha: 0.35)
                            : AppColors.surfaceLight),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.onRefresh == null
                          ? AppTheme.borderColor.withValues(alpha: 0.5)
                          : (_isRefreshHovered
                              ? AppColors.goldAccent
                              : AppTheme.borderColor),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 15,
                        color: widget.onRefresh == null
                            ? AppColors.textSecondary.withValues(alpha: 0.4)
                            : AppColors.goldAccent,
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 5),
                        Text(
                          'Odśwież',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: widget.onRefresh == null
                                ? AppColors.textSecondary.withValues(alpha: 0.4)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTogglePill({
    required String label,
    required IconData icon,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      focusColor: activeColor.withValues(alpha: 0.2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.16)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? activeColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? activeColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CyclingNewsFilter.values.map((filter) {
        final bool isSelected = _activeFilter == filter;
        return InkWell(
          onTap: () => setState(() => _activeFilter = filter),
          borderRadius: BorderRadius.circular(20),
          focusColor: AppColors.goldAccent.withValues(alpha: 0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 11 : 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryAccent
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.goldAccent.withValues(alpha: 0.8)
                    : AppTheme.borderColor,
              ),
            ),
            child: Text(
              filter.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopTwoColumnFeed(List<CyclingNewsItem> items) {
    final left = <CyclingNewsItem>[];
    final right = <CyclingNewsItem>[];
    for (int i = 0; i < items.length; i++) {
      if (i.isEven) {
        left.add(items[i]);
      } else {
        right.add(items[i]);
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < left.length; i++) ...[
                _NewsFeedCard(
                  item: left[i],
                  isCompact: false,
                  onToggleLike: widget.onToggleLike,
                  onToggleBookmark: widget.onToggleBookmark,
                  onOpenDetail: () => _openArticleModal(context, left[i]),
                ),
                if (i < left.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < right.length; i++) ...[
                _NewsFeedCard(
                  item: right[i],
                  isCompact: false,
                  onToggleLike: widget.onToggleLike,
                  onToggleBookmark: widget.onToggleBookmark,
                  onOpenDetail: () => _openArticleModal(context, right[i]),
                ),
                if (i < right.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.feed_outlined,
            size: 34,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          const Text(
            'Brak artykułów spełniających wybrane filtry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Zmień kategorię lub wyłącz filtr „Moja ekipa / Zapisane”, aby zobaczyć pełny strumień świata kolarskiego.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _activeFilter = CyclingNewsFilter.all;
                _onlyPlayerTeam = false;
                _onlyBookmarked = false;
              });
            },
            child: const Text(
              'Resetuj filtry',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.goldAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openArticleModal(BuildContext context, CyclingNewsItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _SourceBadge(source: item.source),
                      const SizedBox(width: 8),
                      _TypeBadge(type: item.type),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.headline,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.authorName} (${item.authorHandle}) • ${_formatNewsDate(item.date)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.body,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      height: 1.55,
                    ),
                  ),
                  if (item.starPicks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _StarPicksPanel(picks: item.starPicks),
                  ],
                  if (item.rideSnapshot != null) ...[
                    const SizedBox(height: 16),
                    _BikeComputerSnapshotCard(snapshot: item.rideSnapshot!),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Zamknij',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NewsFeedCard extends StatefulWidget {
  final CyclingNewsItem item;
  final bool isCompact;
  final ValueChanged<String>? onToggleLike;
  final ValueChanged<String>? onToggleBookmark;
  final VoidCallback onOpenDetail;

  const _NewsFeedCard({
    required this.item,
    required this.isCompact,
    required this.onToggleLike,
    required this.onToggleBookmark,
    required this.onOpenDetail,
  });

  @override
  State<_NewsFeedCard> createState() => _NewsFeedCardState();
}

class _NewsFeedCardState extends State<_NewsFeedCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final Color borderColor = item.isPlayerTeamRelated
        ? AppColors.goldAccent.withValues(alpha: _isHovered ? 0.85 : 0.45)
        : (_isHovered || _isFocused
            ? AppColors.accentBlue.withValues(alpha: 0.7)
            : AppTheme.borderColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: InkWell(
          onTap: widget.onOpenDetail,
          borderRadius: BorderRadius.circular(14),
          focusColor: AppColors.goldAccent.withValues(alpha: 0.12),
          hoverColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(widget.isCompact ? 12 : 14),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.surfaceLight.withValues(alpha: 0.92)
                  : AppColors.surfaceLight.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SourceBadge(source: item.source),
                    _TypeBadge(type: item.type),
                    if (item.isPlayerTeamRelated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'EKIPA',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.goldAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Text(
                      _formatNewsDate(item.date),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (item.type == CyclingNewsItemType.riderSocialPost) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.primaryAccent,
                        child: Text(
                          item.authorName.isNotEmpty
                              ? item.authorName[0].toUpperCase()
                              : 'R',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${item.authorHandle}${item.authorTeamName != null ? ' • ${item.authorTeamName}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  Text(
                    item.headline,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  item.body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 12.2,
                    height: 1.45,
                  ),
                ),
                if (item.starPicks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _StarPicksPanel(picks: item.starPicks),
                ],
                if (item.rideSnapshot != null) ...[
                  const SizedBox(height: 10),
                  _BikeComputerSnapshotCard(snapshot: item.rideSnapshot!),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ActionMetricButton(
                      icon: item.isLikedByPlayer
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '${item.likesCount}',
                      active: item.isLikedByPlayer,
                      activeColor: AppColors.crimsonAlert,
                      onTap: widget.onToggleLike != null
                          ? () => widget.onToggleLike!(item.id)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    _ActionMetricButton(
                      icon: Icons.repeat_rounded,
                      label: '${item.repostsCount}',
                      active: false,
                      activeColor: AppColors.statusSuccess,
                      onTap: widget.onOpenDetail,
                    ),
                    const SizedBox(width: 10),
                    _ActionMetricButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${item.commentsCount}',
                      active: false,
                      activeColor: AppColors.accentBlue,
                      onTap: widget.onOpenDetail,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onToggleBookmark != null
                          ? () => widget.onToggleBookmark!(item.id)
                          : null,
                      tooltip: 'Zapisz wpis',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        item.isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 18,
                        color: item.isBookmarked
                            ? AppColors.cyanAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final CyclingNewsPortalSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (source) {
      CyclingNewsPortalSource.cyclingnews => AppColors.amberWarning,
      CyclingNewsPortalSource.proCyclingStats => AppColors.cyanAccent,
      CyclingNewsPortalSource.velonews => AppColors.primaryAccent,
      CyclingNewsPortalSource.wattLabAnalytics => AppColors.statusSuccess,
      CyclingNewsPortalSource.pelotonSocial => AppColors.accentBlue,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        source.displayName.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final CyclingNewsItemType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        type.label,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textSecondary,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StarPicksPanel extends StatelessWidget {
  final List<CyclingNewsStarPick> picks;

  const _StarPicksPanel({required this.picks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TYPY EKSPERTÓW (GWIAZDKI)',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.goldAccent,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          for (final pick in picks)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (idx) => Icon(
                        idx < pick.stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 13,
                        color: idx < pick.stars
                            ? AppColors.goldAccent
                            : AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pick.riderName} (${pick.teamName}) — ${pick.reason}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BikeComputerSnapshotCard extends StatelessWidget {
  final BikeComputerRideSnapshot snapshot;

  const _BikeComputerSnapshotCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.watch_rounded,
                size: 13,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'TELEMETRIA KOMPUTERA ROWEROWEGO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.accentBlue,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (snapshot.climbName != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    snapshot.climbName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.goldAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _TelemetryMetric(
                label: 'NP',
                value: '${snapshot.normalizedPowerW} W',
                highlight: true,
              ),
              _TelemetryMetric(
                label: 'W/kg',
                value: snapshot.wPerKg.toStringAsFixed(2),
              ),
              _TelemetryMetric(
                label: 'Dystans',
                value: '${snapshot.distanceKm.toStringAsFixed(1)} km',
              ),
              _TelemetryMetric(
                label: 'Czas',
                value: snapshot.formattedDuration,
              ),
              _TelemetryMetric(
                label: 'Przewyższ.',
                value: '${snapshot.elevationGainM} m',
              ),
              _TelemetryMetric(
                label: 'TSS',
                value: '${snapshot.tss}',
              ),
              if (snapshot.vamMetersPerHour != null)
                _TelemetryMetric(
                  label: 'VAM',
                  value: '${snapshot.vamMetersPerHour} m/h',
                  highlight: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelemetryMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _TelemetryMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            color: highlight ? AppColors.cyanAccent : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ActionMetricButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ActionMetricButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = active ? activeColor : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      focusColor: activeColor.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNewsDate(DateTime dt) {
  const months = [
    'sty',
    'lut',
    'mar',
    'kwi',
    'maj',
    'cze',
    'lip',
    'sie',
    'wrz',
    'paź',
    'lis',
    'gru',
  ];
  return '${dt.day} ${months[dt.month - 1]}';
}
