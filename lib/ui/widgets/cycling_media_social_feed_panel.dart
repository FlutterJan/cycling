import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/transfer_rumor_mill_and_journalists_service.dart';

/// Filtr wpisów w kanale mediów kolarskich i przecieków transferowych.
enum CyclingMediaFeedFilter {
  all,
  actionable,
  playerTeam,
  smokescreens,
  resolved;

  String get label {
    switch (this) {
      case CyclingMediaFeedFilter.all:
        return 'Wszystkie';
      case CyclingMediaFeedFilter.actionable:
        return 'Do reakcji';
      case CyclingMediaFeedFilter.playerTeam:
        return 'Nasza ekipa';
      case CyclingMediaFeedFilter.smokescreens:
        return 'Zasłona dymna';
      case CyclingMediaFeedFilter.resolved:
        return 'Rozstrzygnięte';
    }
  }
}

/// Kolejność sortowania wpisów w kanale mediów kolarskich.
enum CyclingMediaSortOrder {
  newestFirst,
  highestCredibility,
  highestHeat;

  String get label {
    switch (this) {
      case CyclingMediaSortOrder.newestFirst:
        return 'Najnowsze';
      case CyclingMediaSortOrder.highestCredibility:
        return 'Wiarygodność';
      case CyclingMediaSortOrder.highestHeat:
        return 'Gorące tematy';
    }
  }
}

/// Wpis w mediach społecznościowych i prasie kolarskiej powiązany z plotką transferową.
class CyclingMediaFeedPost {
  final TransferRumor rumor;
  final CyclingJournalist? journalist;
  final JournalistAffiliation affiliation;
  final int likesCount;
  final int repostsCount;
  final int repliesCount;
  final String hashtag;
  final bool isBreaking;

  const CyclingMediaFeedPost({
    required this.rumor,
    this.journalist,
    required this.affiliation,
    required this.likesCount,
    required this.repostsCount,
    required this.repliesCount,
    required this.hashtag,
    required this.isBreaking,
  });

  int get effectiveCredibility =>
      journalist?.credibilityRating ?? rumor.credibilityAtPublish;

  bool get isVerifiedAuthor => journalist?.isVerified ?? true;

  JournalistArchetype get authorArchetype =>
      journalist?.archetype ?? JournalistArchetype.insiderScoop;

  Map<String, dynamic> toJson() {
    return {
      'rumor': rumor.toJson(),
      'journalist': journalist?.toJson(),
      'affiliation': affiliation.toJson(),
      'likesCount': likesCount,
      'repostsCount': repostsCount,
      'repliesCount': repliesCount,
      'hashtag': hashtag,
      'isBreaking': isBreaking,
    };
  }

  factory CyclingMediaFeedPost.fromJson(Map<String, dynamic> json) {
    return CyclingMediaFeedPost(
      rumor: TransferRumor.fromJson(json['rumor'] as Map<String, dynamic>),
      journalist: json['journalist'] != null
          ? CyclingJournalist.fromJson(
              json['journalist'] as Map<String, dynamic>,
            )
          : null,
      affiliation: JournalistAffiliation.fromJson(
        json['affiliation'] as String? ?? 'cyclingnews',
      ),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      repostsCount: (json['repostsCount'] as num?)?.toInt() ?? 0,
      repliesCount: (json['repliesCount'] as num?)?.toInt() ?? 0,
      hashtag: json['hashtag'] as String? ?? '#TransferRumorMill',
      isBreaking: json['isBreaking'] as bool? ?? false,
    );
  }
}

/// Zbiorcze statystyki kanału mediów kolarskich dla paska podsumowania.
class CyclingMediaFeedSummary {
  final int totalPosts;
  final int activeLeaksCount;
  final int actionableCount;
  final int smokescreenCount;
  final int averageCredibility;
  final String pressureLabel;

  const CyclingMediaFeedSummary({
    required this.totalPosts,
    required this.activeLeaksCount,
    required this.actionableCount,
    required this.smokescreenCount,
    required this.averageCredibility,
    required this.pressureLabel,
  });
}

/// Czysty kalkulator i mapper konwertujący stan [TransferRumorMillState]
/// na wpisy [CyclingMediaFeedPost], filtrujący i sortujący feed.
class CyclingMediaSocialFeedCalculator {
  const CyclingMediaSocialFeedCalculator._();

  static List<CyclingMediaFeedPost> buildPosts(TransferRumorMillState state) {
    final journalistById = <String, CyclingJournalist>{
      for (final j in state.journalists) j.id: j,
    };
    final allRumors = <TransferRumor>[
      ...state.activeRumors,
      ...state.archivedRumors,
    ];

    return allRumors.map((rumor) {
      final journalist = journalistById[rumor.journalistId];
      final affiliation =
          journalist?.affiliation ?? _inferAffiliation(rumor.journalistHandle);
      final reach = journalist?.reachScore ?? 70;
      final heat = rumor.marketHeatDelta.abs();
      final isHot = rumor.veracity == RumorVeracityTier.confirmedLeak ||
          rumor.veracity == RumorVeracityTier.credible ||
          heat >= 8;

      final baseEngagement = (reach * 6) + (heat * 28);
      final likes = (baseEngagement * (rumor.isPlayerTeamInvolved ? 1.4 : 1.0))
          .round()
          .clamp(18, 9800);
      final reposts = (likes * 0.28).round().clamp(4, 2400);
      final replies = (likes * 0.16).round().clamp(2, 1200);

      final hashtag = rumor.isSmokescreen
          ? '#Smokescreen'
          : rumor.veracity == RumorVeracityTier.confirmedLeak
              ? '#BreakingLeak'
              : '#PelotonTransfers';

      return CyclingMediaFeedPost(
        rumor: rumor,
        journalist: journalist,
        affiliation: affiliation,
        likesCount: likes,
        repostsCount: reposts,
        repliesCount: replies,
        hashtag: hashtag,
        isBreaking: isHot && rumor.status == RumorStatus.active,
      );
    }).toList(growable: false);
  }

  static List<CyclingMediaFeedPost> filterAndSort({
    required List<CyclingMediaFeedPost> posts,
    required CyclingMediaFeedFilter filter,
    required CyclingMediaSortOrder sortOrder,
    String searchQuery = '',
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();

    final filtered = posts.where((post) {
      final r = post.rumor;
      final matchesFilter = switch (filter) {
        CyclingMediaFeedFilter.all => true,
        CyclingMediaFeedFilter.actionable => r.isActionable,
        CyclingMediaFeedFilter.playerTeam => r.isPlayerTeamInvolved,
        CyclingMediaFeedFilter.smokescreens => r.isSmokescreen,
        CyclingMediaFeedFilter.resolved => r.status != RumorStatus.active,
      };
      if (!matchesFilter) return false;

      if (normalizedQuery.isEmpty) return true;
      return r.headline.toLowerCase().contains(normalizedQuery) ||
          r.body.toLowerCase().contains(normalizedQuery) ||
          r.targetRiderName.toLowerCase().contains(normalizedQuery) ||
          r.journalistName.toLowerCase().contains(normalizedQuery) ||
          r.sourceTeamName.toLowerCase().contains(normalizedQuery) ||
          r.rumoredDestinationTeamName.toLowerCase().contains(normalizedQuery);
    }).toList();

    filtered.sort((a, b) {
      switch (sortOrder) {
        case CyclingMediaSortOrder.newestFirst:
          final dateCmp = b.rumor.createdDate.compareTo(a.rumor.createdDate);
          if (dateCmp != 0) return dateCmp;
          return b.rumor.marketHeatDelta.compareTo(a.rumor.marketHeatDelta);
        case CyclingMediaSortOrder.highestCredibility:
          final credCmp = b.effectiveCredibility.compareTo(
            a.effectiveCredibility,
          );
          if (credCmp != 0) return credCmp;
          return b.rumor.createdDate.compareTo(a.rumor.createdDate);
        case CyclingMediaSortOrder.highestHeat:
          final heatCmp = b.rumor.marketHeatDelta.abs().compareTo(
                a.rumor.marketHeatDelta.abs(),
              );
          if (heatCmp != 0) return heatCmp;
          return b.likesCount.compareTo(a.likesCount);
      }
    });

    return filtered;
  }

  static CyclingMediaFeedSummary summarize(TransferRumorMillState state) {
    final active = state.activeRumors;
    final actionable = active.where((r) => r.isActionable).length;
    final smokescreens = active.where((r) => r.isSmokescreen).length;

    final avgCredibility = active.isEmpty
        ? state.mediaCredibilityScore
        : (active.fold<int>(0, (acc, r) => acc + r.credibilityAtPublish) /
                active.length)
            .round()
            .clamp(0, 100);

    final pressureLabel = state.marketHeatIndex >= 75
        ? 'Burza Medialna'
        : state.marketHeatIndex >= 45
            ? 'Gorący Rynek'
            : 'Spokojny Obieg';

    return CyclingMediaFeedSummary(
      totalPosts: active.length + state.archivedRumors.length,
      activeLeaksCount: active.length,
      actionableCount: actionable,
      smokescreenCount: smokescreens,
      averageCredibility: avgCredibility,
      pressureLabel: pressureLabel,
    );
  }

  static JournalistAffiliation _inferAffiliation(String handle) {
    final lower = handle.toLowerCase();
    if (lower.contains('sporza')) return JournalistAffiliation.sporza;
    if (lower.contains('equipe')) return JournalistAffiliation.lequipe;
    if (lower.contains('gazzetta')) return JournalistAffiliation.gazzetta;
    if (lower.contains('escape')) return JournalistAffiliation.escapeCollective;
    if (lower.contains('wieler')) return JournalistAffiliation.wielerFlits;
    if (lower.contains('lanterne')) return JournalistAffiliation.lanterneRouge;
    return JournalistAffiliation.cyclingnews;
  }
}

/// Panel mediów kolarskich i przecieków transferowych w biurze menedżera
/// z możliwością zdementowania, potwierdzenia lub przemilczenia plotki.
class CyclingMediaSocialFeedPanel extends ConsumerStatefulWidget {
  /// Opcjonalny jawny stan systemu plotek. Jeśli null, widget czyta z
  /// [transferRumorMillProvider].
  final TransferRumorMillState? stateOverride;

  /// Drużyna gracza używana do przeliczania konsekwencji dementi/potwierdzenia.
  final CyclingTeam? playerTeam;

  /// Kadra gracza używana do przeliczania wpływu na morale zawodników.
  final List<Rider> playerSquad;

  /// Aktualna data kariery. Domyślnie `DateTime.now()`.
  final DateTime? currentDate;

  /// Tryb tylko do odczytu (blokuje przyciski reakcji na plotki).
  final bool isReadOnly;

  /// Opcjonalny callback wywoływany po reakcji menedżera na plotkę.
  final void Function(TransferRumor rumor, RumorActionType action)?
      onRumorAction;

  /// Opcjonalny callback odświeżenia feedu (np. symulacja kolejnego dnia).
  final VoidCallback? onRefreshFeed;

  /// Opcjonalny callback kliknięcia na kolarza w poście.
  final void Function(String riderId, String riderName)? onRiderSelected;

  const CyclingMediaSocialFeedPanel({
    super.key,
    this.stateOverride,
    this.playerTeam,
    this.playerSquad = const [],
    this.currentDate,
    this.isReadOnly = false,
    this.onRumorAction,
    this.onRefreshFeed,
    this.onRiderSelected,
  });

  @override
  ConsumerState<CyclingMediaSocialFeedPanel> createState() =>
      _CyclingMediaSocialFeedPanelState();
}

class _CyclingMediaSocialFeedPanelState
    extends ConsumerState<CyclingMediaSocialFeedPanel> {
  CyclingMediaFeedFilter _selectedFilter = CyclingMediaFeedFilter.all;
  CyclingMediaSortOrder _sortOrder = CyclingMediaSortOrder.newestFirst;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _likedPostIds = <String>{};
  final Set<String> _bookmarkedPostIds = <String>{};
  RumorResponseOutcome? _lastOutcome;
  String? _selectedPostId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleRumorAction(TransferRumor rumor, RumorActionType action) {
    if (widget.isReadOnly || !rumor.isActionable) return;

    if (widget.onRumorAction != null) {
      widget.onRumorAction!(rumor, action);
      return;
    }

    if (widget.stateOverride != null) {
      return;
    }

    final team = widget.playerTeam;
    if (team == null) return;
    final date = widget.currentDate ?? DateTime(2026, 7, 15);
    final outcome = ref.read(transferRumorMillProvider.notifier).respond(
          rumorId: rumor.id,
          action: action,
          playerTeam: team,
          playerSquad: widget.playerSquad,
          currentDate: date,
        );

    setState(() {
      _lastOutcome = outcome;
      _selectedPostId = rumor.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final TransferRumorMillState rumorState =
        widget.stateOverride ?? ref.watch(transferRumorMillProvider);
    final allPosts = CyclingMediaSocialFeedCalculator.buildPosts(rumorState);
    final visiblePosts = CyclingMediaSocialFeedCalculator.filterAndSort(
      posts: allPosts,
      filter: _selectedFilter,
      sortOrder: _sortOrder,
      searchQuery: _searchQuery,
    );
    final summary = CyclingMediaSocialFeedCalculator.summarize(rumorState);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 640;
        final isWideDesktop = width >= 1080;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderSection(
                  summary: summary,
                  mediaCredibility: rumorState.mediaCredibilityScore,
                  marketHeat: rumorState.marketHeatIndex,
                  isCompact: isCompact,
                  isReadOnly: widget.isReadOnly,
                  onRefresh: widget.onRefreshFeed,
                ),
                const SizedBox(height: 16),
                if (_lastOutcome != null) ...[
                  _OutcomeFeedbackBanner(
                    outcome: _lastOutcome!,
                    onDismiss: () => setState(() => _lastOutcome = null),
                  ),
                  const SizedBox(height: 16),
                ],
                _BreakingTickerBanner(
                  posts: allPosts,
                  onSelectPost: (postId) {
                    setState(() {
                      _selectedPostId = postId;
                      _selectedFilter = CyclingMediaFeedFilter.all;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _FilterAndSearchBar(
                  selectedFilter: _selectedFilter,
                  sortOrder: _sortOrder,
                  searchController: _searchController,
                  summary: summary,
                  isCompact: isCompact,
                  onFilterChanged: (filter) {
                    setState(() => _selectedFilter = filter);
                  },
                  onSortChanged: (order) {
                    setState(() => _sortOrder = order);
                  },
                  onSearchChanged: (query) {
                    setState(() => _searchQuery = query);
                  },
                ),
                const SizedBox(height: 16),
                if (isWideDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _FeedPostsColumn(
                          posts: visiblePosts,
                          isCompact: false,
                          isReadOnly: widget.isReadOnly,
                          likedPostIds: _likedPostIds,
                          bookmarkedPostIds: _bookmarkedPostIds,
                          selectedPostId: _selectedPostId,
                          onToggleLike: (id) {
                            setState(() {
                              if (!_likedPostIds.add(id)) {
                                _likedPostIds.remove(id);
                              }
                            });
                          },
                          onToggleBookmark: (id) {
                            setState(() {
                              if (!_bookmarkedPostIds.add(id)) {
                                _bookmarkedPostIds.remove(id);
                              }
                            });
                          },
                          onSelectPost: (id) {
                            setState(() => _selectedPostId = id);
                          },
                          onAction: _handleRumorAction,
                          onRiderSelected: widget.onRiderSelected,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: _MediaInsightsSidebar(
                          state: rumorState,
                          summary: summary,
                          bookmarkedCount: _bookmarkedPostIds.length,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _FeedPostsColumn(
                    posts: visiblePosts,
                    isCompact: isCompact,
                    isReadOnly: widget.isReadOnly,
                    likedPostIds: _likedPostIds,
                    bookmarkedPostIds: _bookmarkedPostIds,
                    selectedPostId: _selectedPostId,
                    onToggleLike: (id) {
                      setState(() {
                        if (!_likedPostIds.add(id)) {
                          _likedPostIds.remove(id);
                        }
                      });
                    },
                    onToggleBookmark: (id) {
                      setState(() {
                        if (!_bookmarkedPostIds.add(id)) {
                          _bookmarkedPostIds.remove(id);
                        }
                      });
                    },
                    onSelectPost: (id) {
                      setState(() => _selectedPostId = id);
                    },
                    onAction: _handleRumorAction,
                    onRiderSelected: widget.onRiderSelected,
                  ),
                  const SizedBox(height: 16),
                  _MediaInsightsSidebar(
                    state: rumorState,
                    summary: summary,
                    bookmarkedCount: _bookmarkedPostIds.length,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final CyclingMediaFeedSummary summary;
  final int mediaCredibility;
  final int marketHeat;
  final bool isCompact;
  final bool isReadOnly;
  final VoidCallback? onRefresh;

  const _HeaderSection({
    required this.summary,
    required this.mediaCredibility,
    required this.marketHeat,
    required this.isCompact,
    required this.isReadOnly,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.rss_feed_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Media Kolarskie & Przecieki',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        _StatusBadgePill(
                          label: summary.pressureLabel,
                          color: marketHeat >= 75
                              ? AppColors.crimsonAlert
                              : marketHeat >= 45
                                  ? AppColors.amberWarning
                                  : AppColors.statusSuccess,
                        ),
                        if (isReadOnly)
                          const _StatusBadgePill(
                            label: 'Tylko podgląd',
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Monitoruj doniesienia prasowe, przecieki z peletonu oraz reaguj oficjalnym dementi lub potwierdzeniem.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        letterSpacing: -0.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 8),
                _InteractiveIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Odśwież prasówkę',
                  enabled: !isReadOnly,
                  onPressed: onRefresh!,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _HeaderStatChip(
                icon: Icons.verified_user_outlined,
                label: 'Wiarygodność klubu',
                value: '$mediaCredibility/100',
                accentColor: mediaCredibility >= 65
                    ? AppColors.statusSuccess
                    : mediaCredibility >= 40
                        ? AppColors.amberWarning
                        : AppColors.crimsonAlert,
              ),
              _HeaderStatChip(
                icon: Icons.local_fire_department_outlined,
                label: 'Temperatura rynku',
                value: '$marketHeat/100',
                accentColor: marketHeat >= 70
                    ? AppColors.crimsonAlert
                    : AppColors.goldAccent,
              ),
              _HeaderStatChip(
                icon: Icons.mark_chat_unread_outlined,
                label: 'Wymagają reakcji',
                value: '${summary.actionableCount}',
                accentColor: summary.actionableCount > 0
                    ? AppColors.accentBlue
                    : AppColors.textSecondary,
              ),
              _HeaderStatChip(
                icon: Icons.masks_outlined,
                label: 'Zasłony dymne',
                value: '${summary.smokescreenCount}',
                accentColor: AppColors.goldAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakingTickerBanner extends StatelessWidget {
  final List<CyclingMediaFeedPost> posts;
  final ValueChanged<String> onSelectPost;

  const _BreakingTickerBanner({
    required this.posts,
    required this.onSelectPost,
  });

  @override
  Widget build(BuildContext context) {
    final breaking = posts.where((p) => p.isBreaking).toList(growable: false);
    if (breaking.isEmpty) {
      return const SizedBox.shrink();
    }
    final topPost = breaking.first;

    return _InteractiveSurfaceCard(
      onTap: () => onSelectPost(topPost.rumor.id),
      borderColor: AppColors.crimsonAlert.withValues(alpha: 0.45),
      backgroundColor: AppColors.crimsonAlert.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.crimsonAlert.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.crimsonAlert.withValues(alpha: 0.6),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: AppColors.crimsonAlert,
                ),
                SizedBox(width: 4),
                Text(
                  'PILNE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.crimsonAlert,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${topPost.affiliation.displayName}: ${topPost.rumor.headline}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _OutcomeFeedbackBanner extends StatelessWidget {
  final RumorResponseOutcome outcome;
  final VoidCallback onDismiss;

  const _OutcomeFeedbackBanner({
    required this.outcome,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isPositiveCredibility = outcome.mediaCredibilityDelta >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositiveCredibility
              ? AppColors.statusSuccess.withValues(alpha: 0.55)
              : AppColors.amberWarning.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositiveCredibility
                ? Icons.campaign_rounded
                : Icons.warning_amber_rounded,
            color: isPositiveCredibility
                ? AppColors.statusSuccess
                : AppColors.amberWarning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outcome.summaryMessage,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _DeltaPill(
                      label: 'Relacja z mediami',
                      delta: outcome.journalistRelationshipDelta,
                    ),
                    _DeltaPill(
                      label: 'Wiarygodność',
                      delta: outcome.mediaCredibilityDelta,
                    ),
                    _DeltaPill(
                      label: 'Szum rynkowy',
                      delta: outcome.marketHeatDelta,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Zamknij komunikat',
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterAndSearchBar extends StatelessWidget {
  final CyclingMediaFeedFilter selectedFilter;
  final CyclingMediaSortOrder sortOrder;
  final TextEditingController searchController;
  final CyclingMediaFeedSummary summary;
  final bool isCompact;
  final ValueChanged<CyclingMediaFeedFilter> onFilterChanged;
  final ValueChanged<CyclingMediaSortOrder> onSortChanged;
  final ValueChanged<String> onSearchChanged;

  const _FilterAndSearchBar({
    required this.selectedFilter,
    required this.sortOrder,
    required this.searchController,
    required this.summary,
    required this.isCompact,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filterChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CyclingMediaFeedFilter.values.map((filter) {
        final count = switch (filter) {
          CyclingMediaFeedFilter.all => summary.totalPosts,
          CyclingMediaFeedFilter.actionable => summary.actionableCount,
          CyclingMediaFeedFilter.playerTeam => null,
          CyclingMediaFeedFilter.smokescreens => summary.smokescreenCount,
          CyclingMediaFeedFilter.resolved =>
            summary.totalPosts - summary.activeLeaksCount,
        };
        final label =
            count != null ? '${filter.label} ($count)' : filter.label;
        return _FilterChipButton(
          label: label,
          selected: selectedFilter == filter,
          onTap: () => onFilterChanged(filter),
        );
      }).toList(),
    );

    final searchField = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Szukaj kolarza, dziennikarza lub drużyny...',
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
                  Icons.clear_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.goldAccent),
        ),
      ),
    );

    final sortSelector = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CyclingMediaSortOrder>(
          value: sortOrder,
          dropdownColor: AppColors.surfaceLight,
          iconEnabledColor: AppColors.textSecondary,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          items: CyclingMediaSortOrder.values
              .map(
                (order) => DropdownMenuItem<CyclingMediaSortOrder>(
                  value: order,
                  child: Text('Sortuj: ${order.label}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onSortChanged(value);
          },
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filterChips,
          const SizedBox(height: 12),
          if (isCompact) ...[
            searchField,
            const SizedBox(height: 10),
            sortSelector,
          ] else
            Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                sortSelector,
              ],
            ),
        ],
      ),
    );
  }
}

class _FeedPostsColumn extends StatelessWidget {
  final List<CyclingMediaFeedPost> posts;
  final bool isCompact;
  final bool isReadOnly;
  final Set<String> likedPostIds;
  final Set<String> bookmarkedPostIds;
  final String? selectedPostId;
  final ValueChanged<String> onToggleLike;
  final ValueChanged<String> onToggleBookmark;
  final ValueChanged<String> onSelectPost;
  final void Function(TransferRumor rumor, RumorActionType action) onAction;
  final void Function(String riderId, String riderName)? onRiderSelected;

  const _FeedPostsColumn({
    required this.posts,
    required this.isCompact,
    required this.isReadOnly,
    required this.likedPostIds,
    required this.bookmarkedPostIds,
    required this.selectedPostId,
    required this.onToggleLike,
    required this.onToggleBookmark,
    required this.onSelectPost,
    required this.onAction,
    this.onRiderSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.newspaper_rounded,
              size: 40,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Brak doniesień prasowych dla wybranego filtra',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'W trakcie okna transferowego i przed ważnymi klasykami dziennikarze regularnie publikują nowe przecieki.',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: posts.map((post) {
        final id = post.rumor.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MediaFeedPostCard(
            post: post,
            isCompact: isCompact,
            isReadOnly: isReadOnly,
            isSelected: selectedPostId == id,
            isLiked: likedPostIds.contains(id),
            isBookmarked: bookmarkedPostIds.contains(id),
            onTap: () => onSelectPost(id),
            onToggleLike: () => onToggleLike(id),
            onToggleBookmark: () => onToggleBookmark(id),
            onConfirm: () => onAction(post.rumor, RumorActionType.confirm),
            onDeny: () => onAction(post.rumor, RumorActionType.deny),
            onNoComment: () => onAction(post.rumor, RumorActionType.noComment),
            onRiderSelected: onRiderSelected,
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _MediaFeedPostCard extends StatefulWidget {
  final CyclingMediaFeedPost post;
  final bool isCompact;
  final bool isReadOnly;
  final bool isSelected;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleBookmark;
  final VoidCallback onConfirm;
  final VoidCallback onDeny;
  final VoidCallback onNoComment;
  final void Function(String riderId, String riderName)? onRiderSelected;

  const _MediaFeedPostCard({
    required this.post,
    required this.isCompact,
    required this.isReadOnly,
    required this.isSelected,
    required this.isLiked,
    required this.isBookmarked,
    required this.onTap,
    required this.onToggleLike,
    required this.onToggleBookmark,
    required this.onConfirm,
    required this.onDeny,
    required this.onNoComment,
    this.onRiderSelected,
  });

  @override
  State<_MediaFeedPostCard> createState() => _MediaFeedPostCardState();
}

class _MediaFeedPostCardState extends State<_MediaFeedPostCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final rumor = widget.post.rumor;
    final veracityColor = rumor.veracity.badgeColor;
    final statusColor = _statusColor(rumor.status);

    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_isHovered || _isFocused)
            ? AppColors.accentBlue.withValues(alpha: 0.6)
            : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(widget.isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.surfaceLight : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author & Media outlet row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _JournalistAvatar(
                    name: rumor.journalistName,
                    affiliation: widget.post.affiliation,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              rumor.journalistName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (widget.post.isVerifiedAuthor)
                              const Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: AppColors.accentBlue,
                              ),
                            Text(
                              rumor.journalistHandle,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            _StatusBadgePill(
                              label: widget.post.affiliation.displayName,
                              color: AppColors.accentBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.post.authorArchetype.label} • ${_formatDate(rumor.createdDate)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadgePill(
                        label: rumor.veracity.label,
                        color: veracityColor,
                      ),
                      const SizedBox(height: 4),
                      _StatusBadgePill(
                        label: rumor.status.label,
                        color: statusColor,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Headline & Body
              Text(
                rumor.headline,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                rumor.body,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Transfer context box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: widget.onRiderSelected == null
                          ? null
                          : () => widget.onRiderSelected!(
                                rumor.targetRiderId,
                                rumor.targetRiderName,
                              ),
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_bike_rounded,
                            size: 15,
                            color: AppColors.goldAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            rumor.targetRiderName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.onRiderSelected != null
                                  ? AppColors.goldAccent
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          rumor.sourceTeamName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.goldAccent,
                        ),
                        Text(
                          rumor.rumoredDestinationTeamName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Kontrakt: ${Formatters.formatCurrency(rumor.estimatedSalaryEur.toDouble())}/rok',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.statusSuccess,
                      ),
                    ),
                    Text(
                      'Wiarygodność: ${widget.post.effectiveCredibility}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Official manager response section OR action buttons
              if (rumor.isActionable) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RumorActionButton(
                      key: ValueKey('deny_rumor_${rumor.id}'),
                      label: 'Zdementuj plotkę',
                      icon: Icons.gavel_rounded,
                      accentColor: AppColors.crimsonAlert,
                      enabled: !widget.isReadOnly,
                      onPressed: widget.onDeny,
                    ),
                    _RumorActionButton(
                      key: ValueKey('confirm_rumor_${rumor.id}'),
                      label: 'Potwierdź rozmowy',
                      icon: Icons.verified_outlined,
                      accentColor: AppColors.statusSuccess,
                      enabled: !widget.isReadOnly,
                      onPressed: widget.onConfirm,
                    ),
                    _RumorActionButton(
                      key: ValueKey('nocomment_rumor_${rumor.id}'),
                      label: 'Bez komentarza',
                      icon: Icons.speaker_notes_off_outlined,
                      accentColor: AppColors.textSecondary,
                      enabled: !widget.isReadOnly,
                      isOutlined: true,
                      onPressed: widget.onNoComment,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else if (rumor.playerResponse != RumorActionType.none) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _responseIcon(rumor.playerResponse),
                        size: 16,
                        color: _responseColor(rumor.playerResponse),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stanowisko menedżera: ${_responseLabel(rumor.playerResponse)}',
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
                ),
                const SizedBox(height: 12),
              ],

              // Social engagement footer
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.post.hashtag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _EngagementButton(
                    icon: widget.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    count: widget.post.likesCount + (widget.isLiked ? 1 : 0),
                    active: widget.isLiked,
                    activeColor: AppColors.crimsonAlert,
                    onTap: widget.onToggleLike,
                  ),
                  const SizedBox(width: 10),
                  _EngagementCounter(
                    icon: Icons.repeat_rounded,
                    count: widget.post.repostsCount,
                  ),
                  const SizedBox(width: 10),
                  _EngagementCounter(
                    icon: Icons.chat_bubble_outline_rounded,
                    count: widget.post.repliesCount,
                  ),
                  const SizedBox(width: 8),
                  _InteractiveIconButton(
                    icon: widget.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    tooltip: 'Zapisz w archiwum',
                    enabled: true,
                    activeColor:
                        widget.isBookmarked ? AppColors.goldAccent : null,
                    onPressed: widget.onToggleBookmark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(RumorStatus status) {
    switch (status) {
      case RumorStatus.active:
        return AppColors.accentBlue;
      case RumorStatus.denied:
        return AppColors.crimsonAlert;
      case RumorStatus.confirmed:
        return AppColors.statusSuccess;
      case RumorStatus.expired:
        return AppColors.textSecondary;
      case RumorStatus.smokescreenRevealed:
        return AppColors.goldAccent;
    }
  }

  IconData _responseIcon(RumorActionType action) {
    switch (action) {
      case RumorActionType.deny:
        return Icons.gavel_rounded;
      case RumorActionType.confirm:
        return Icons.verified_rounded;
      case RumorActionType.noComment:
        return Icons.speaker_notes_off_outlined;
      case RumorActionType.plantSmokescreen:
        return Icons.masks_rounded;
      case RumorActionType.none:
        return Icons.info_outline;
    }
  }

  Color _responseColor(RumorActionType action) {
    switch (action) {
      case RumorActionType.deny:
        return AppColors.crimsonAlert;
      case RumorActionType.confirm:
        return AppColors.statusSuccess;
      case RumorActionType.noComment:
        return AppColors.textSecondary;
      case RumorActionType.plantSmokescreen:
        return AppColors.goldAccent;
      case RumorActionType.none:
        return AppColors.textSecondary;
    }
  }

  String _responseLabel(RumorActionType action) {
    switch (action) {
      case RumorActionType.deny:
        return 'Oficjalnie zdementowano';
      case RumorActionType.confirm:
        return 'Potwierdzono zainteresowanie / rozmowy';
      case RumorActionType.noComment:
        return 'Odmówiono komentarza';
      case RumorActionType.plantSmokescreen:
        return 'Wypuszczono jako zasłonę dymną';
      case RumorActionType.none:
        return 'Brak reakcji';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _MediaInsightsSidebar extends StatelessWidget {
  final TransferRumorMillState state;
  final CyclingMediaFeedSummary summary;
  final int bookmarkedCount;

  const _MediaInsightsSidebar({
    required this.state,
    required this.summary,
    required this.bookmarkedCount,
  });

  @override
  Widget build(BuildContext context) {
    final topJournalists = [...state.journalists]
      ..sort((a, b) => b.credibilityRating.compareTo(a.credibilityRating));
    final recentMorale = state.moraleHistory.reversed.take(4).toList();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    size: 18,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Puls Prasy Kolarskiej',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'Zapisane: $bookmarkedCount',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.goldAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ProgressBarRow(
                label: 'Wiarygodność komunikatów',
                value: state.mediaCredibilityScore,
                color: AppColors.statusSuccess,
              ),
              const SizedBox(height: 10),
              _ProgressBarRow(
                label: 'Temperatura rynku transferowego',
                value: state.marketHeatIndex,
                color: AppColors.crimsonAlert,
              ),
              const SizedBox(height: 10),
              _ProgressBarRow(
                label: 'Śr. rzetelność aktywnych przecieków',
                value: summary.averageCredibility,
                color: AppColors.accentBlue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
              const Row(
                children: [
                  Icon(
                    Icons.mic_external_on_rounded,
                    size: 18,
                    color: AppColors.accentBlue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kluczowi Dziennikarze',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (topJournalists.isEmpty)
                const Text(
                  'Brak zarejestrowanych dziennikarzy.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...topJournalists.take(4).map((j) {
                  final relColor = j.relationshipWithPlayer >= 15
                      ? AppColors.statusSuccess
                      : j.relationshipWithPlayer <= -15
                          ? AppColors.crimsonAlert
                          : AppColors.textSecondary;
                  final relPrefix = j.relationshipWithPlayer > 0 ? '+' : '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                j.name,
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
                                '${j.affiliation.displayName} • Wiaryg. ${j.credibilityRating}%',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: relColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$relPrefix${j.relationshipWithPlayer}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: relColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
              const Row(
                children: [
                  Icon(
                    Icons.psychology_alt_rounded,
                    size: 18,
                    color: AppColors.amberWarning,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wpływ plotek na szatnię',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recentMorale.isEmpty)
                const Text(
                  'Obecnie żadna plotka nie wpłynęła jeszcze na morale zawodników.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...recentMorale.map((entry) {
                  final deltaColor = entry.deltaMorale >= 0
                      ? AppColors.statusSuccess
                      : AppColors.crimsonAlert;
                  final sign = entry.deltaMorale > 0 ? '+' : '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.riderName} (${entry.riderRole.label})',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                entry.reason,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$sign${entry.deltaMorale.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: deltaColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _JournalistAvatar extends StatelessWidget {
  final String name;
  final JournalistAffiliation affiliation;

  const _JournalistAvatar({
    required this.name,
    required this.affiliation,
  });

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : '?');

    final color = switch (affiliation) {
      JournalistAffiliation.cyclingnews => AppColors.accentBlue,
      JournalistAffiliation.sporza => AppColors.goldAccent,
      JournalistAffiliation.lequipe => AppColors.crimsonAlert,
      JournalistAffiliation.gazzetta => AppColors.primaryAccent,
      JournalistAffiliation.escapeCollective => AppColors.statusSuccess,
      JournalistAffiliation.wielerFlits => AppColors.amberWarning,
      JournalistAffiliation.lanterneRouge => AppColors.cyanAccent,
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _HeaderStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _HeaderStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label: ',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadgePill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadgePill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final String label;
  final int delta;

  const _DeltaPill({
    required this.label,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final sign = delta > 0 ? '+' : '';
    final color = delta > 0
        ? AppColors.statusSuccess
        : delta < 0
            ? AppColors.crimsonAlert
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $sign$delta',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: color,
        ),
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ProgressBarRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              '$clamped%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped / 100.0,
            minHeight: 6,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
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
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : _isHovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : _isFocused
            ? AppColors.accentBlue
            : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RumorActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final bool isOutlined;
  final VoidCallback onPressed;

  const _RumorActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    this.isOutlined = false,
    required this.onPressed,
  });

  @override
  State<_RumorActionButton> createState() => _RumorActionButtonState();
}

class _RumorActionButtonState extends State<_RumorActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.enabled ? widget.accentColor : AppColors.textSecondary;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isOutlined
            ? (_isHovered ? AppColors.surfaceLight : Colors.transparent)
            : _isPressed
                ? effectiveColor.withValues(alpha: 0.32)
                : _isHovered
                    ? effectiveColor.withValues(alpha: 0.24)
                    : effectiveColor.withValues(alpha: 0.15);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: InkWell(
        onTap: widget.enabled ? widget.onPressed : null,
        onHighlightChanged: (pressed) => setState(() => _isPressed = pressed),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused
                  ? AppColors.goldAccent
                  : effectiveColor.withValues(alpha: widget.enabled ? 0.55 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconSize(15), size: 15, color: effectiveColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData iconSize(double _) => widget.icon;
}

class _EngagementButton extends StatefulWidget {
  final IconData icon;
  final int count;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _EngagementButton({
    required this.icon,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_EngagementButton> createState() => _EngagementButtonState();
}

class _EngagementButtonState extends State<_EngagementButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? widget.activeColor
        : _isHovered
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                '${widget.count}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EngagementCounter extends StatelessWidget {
  final IconData icon;
  final int count;

  const _EngagementCounter({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontFeatures: [FontFeature.tabularFigures()],
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final Color? activeColor;
  final VoidCallback onPressed;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    this.activeColor,
    required this.onPressed,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final color = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : widget.activeColor ??
            (_isHovered ? AppColors.goldAccent : AppColors.textSecondary);

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
        onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.surfaceLight
                  : AppColors.surfaceLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused ? AppColors.goldAccent : AppTheme.borderColor,
              ),
            ),
            child: Icon(widget.icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class _InteractiveSurfaceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color borderColor;
  final Color backgroundColor;

  const _InteractiveSurfaceCard({
    required this.child,
    required this.onTap,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  State<_InteractiveSurfaceCard> createState() =>
      _InteractiveSurfaceCardState();
}

class _InteractiveSurfaceCardState extends State<_InteractiveSurfaceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.backgroundColor.withValues(alpha: 0.16)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
