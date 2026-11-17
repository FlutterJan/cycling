import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/organizer/race_organizer_empire_model.dart';

/// Filtr roli miasta gospodarza w oknie przetargowym.
enum AuctionRoleFilter {
  all('Wszystkie'),
  grandDepart('Grand Départ'),
  mountainSummitFinish('Meta Górska'),
  otherRoles('Etapy & ITT');

  final String label;

  const AuctionRoleFilter(this.label);

  bool matches(HostBidRole role) {
    switch (this) {
      case AuctionRoleFilter.all:
        return true;
      case AuctionRoleFilter.grandDepart:
        return role == HostBidRole.grandDepart;
      case AuctionRoleFilter.mountainSummitFinish:
        return role == HostBidRole.mountainSummitFinish;
      case AuctionRoleFilter.otherRoles:
        return role != HostBidRole.grandDepart &&
            role != HostBidRole.mountainSummitFinish;
    }
  }
}

/// Tryb sortowania ofert przetargowych miast gospodarzy.
enum AuctionSortMode {
  compositeScore('Ocena'),
  highestFee('Opłata'),
  crowdTurnout('Kibice'),
  deadline('Termin');

  final String label;

  const AuctionSortMode(this.label);
}

/// Wynik sesji przetargowej zwrócony przez [HostCityBiddingAuctionModal].
class HostCityBiddingAuctionResult {
  final RaceOrganizerEmpireModel updatedEmpire;
  final List<String> awardedBidIds;
  final List<String> rejectedBidIds;
  final List<String> counterOfferedBidIds;
  final String? lastActionMessage;

  const HostCityBiddingAuctionResult({
    required this.updatedEmpire,
    this.awardedBidIds = const [],
    this.rejectedBidIds = const [],
    this.counterOfferedBidIds = const [],
    this.lastActionMessage,
  });
}

/// Wyświetla modal przetargów miast gospodarzy ubiegających się o Grand Départ lub metę górską.
Future<HostCityBiddingAuctionResult?> showHostCityBiddingAuctionModal(
  BuildContext context, {
  required RaceOrganizerEmpireModel initialEmpire,
  String? initialRaceId,
  String? initialBidId,
  AuctionRoleFilter initialRoleFilter = AuctionRoleFilter.all,
  bool isReadOnly = false,
}) {
  return showGeneralDialog<HostCityBiddingAuctionResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Zamknij okno przetargów miast gospodarzy',
    barrierColor: Colors.black.withValues(alpha: 0.76),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1140,
                maxHeight: 820,
              ),
              child: Material(
                color: Colors.transparent,
                child: HostCityBiddingAuctionModal(
                  initialEmpire: initialEmpire,
                  initialRaceId: initialRaceId,
                  initialBidId: initialBidId,
                  initialRoleFilter: initialRoleFilter,
                  isReadOnly: isReadOnly,
                ),
              ),
            ),
          ),
        ),
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

/// Okno przetargów miast gospodarzy ubiegających się o *Grand Départ* lub metę górską.
class HostCityBiddingAuctionModal extends StatefulWidget {
  final RaceOrganizerEmpireModel initialEmpire;
  final String? initialRaceId;
  final String? initialBidId;
  final AuctionRoleFilter initialRoleFilter;
  final bool isReadOnly;
  final ValueChanged<HostCityBiddingAuctionResult>? onEmpireChanged;

  const HostCityBiddingAuctionModal({
    super.key,
    required this.initialEmpire,
    this.initialRaceId,
    this.initialBidId,
    this.initialRoleFilter = AuctionRoleFilter.all,
    this.isReadOnly = false,
    this.onEmpireChanged,
  });

  @override
  State<HostCityBiddingAuctionModal> createState() =>
      _HostCityBiddingAuctionModalState();
}

class _HostCityBiddingAuctionModalState
    extends State<HostCityBiddingAuctionModal> {
  late RaceOrganizerEmpireModel _empire;
  late String? _selectedRaceFilterId;
  late AuctionRoleFilter _roleFilter;
  AuctionSortMode _sortMode = AuctionSortMode.compositeScore;
  bool _onlyActiveBids = false;

  String? _selectedBidId;
  int _contractLengthYears = 1;
  int _counterOfferUpliftPercent = 10;
  bool _mobileShowDetails = false;

  String? _bannerMessage;
  bool _bannerIsSuccess = true;

  final List<String> _awardedBidIds = [];
  final List<String> _rejectedBidIds = [];
  final List<String> _counterOfferedBidIds = [];
  final Set<String> _counterOfferedOnce = {};

  @override
  void initState() {
    super.initState();
    _empire = widget.initialEmpire;
    _selectedRaceFilterId = widget.initialRaceId;
    _roleFilter = widget.initialRoleFilter;
    _selectedBidId = widget.initialBidId ??
        (_empire.pendingHostCityBids.isNotEmpty
            ? _empire.pendingHostCityBids.first.bidId
            : null);
  }

  List<HostCityBid> get _filteredBids {
    final list = _empire.pendingHostCityBids.where((bid) {
      if (_selectedRaceFilterId != null && bid.raceId != _selectedRaceFilterId) {
        return false;
      }
      if (!_roleFilter.matches(bid.role)) {
        return false;
      }
      if (_onlyActiveBids && !bid.status.isActiveForDecision) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      switch (_sortMode) {
        case AuctionSortMode.compositeScore:
          return b.compositeBidScore.compareTo(a.compositeBidScore);
        case AuctionSortMode.highestFee:
          return b.totalEconomicValueEur.compareTo(a.totalEconomicValueEur);
        case AuctionSortMode.crowdTurnout:
          return b.crowdTurnoutForecast.compareTo(a.crowdTurnoutForecast);
        case AuctionSortMode.deadline:
          return a.deadlineDay.compareTo(b.deadlineDay);
      }
    });
    return list;
  }

  HostCityBid? get _selectedBid {
    final filtered = _filteredBids;
    if (_selectedBidId != null) {
      for (final bid in filtered) {
        if (bid.bidId == _selectedBidId) return bid;
      }
    }
    return filtered.isNotEmpty ? filtered.first : null;
  }

  ManagedRacePortfolioItem? _raceForBid(HostCityBid bid) {
    for (final race in _empire.managedRaces) {
      if (race.raceId == bid.raceId) return race;
    }
    return null;
  }

  double _calculateCounterOfferAcceptanceChance(
    HostCityBid bid,
    int upliftPercent,
  ) {
    final demandFactor = (bid.tourismExposureDemand / 100.0) * 0.35;
    final stabilityFactor = (bid.politicalStabilityIndex / 100.0) * 0.25;
    final roleFactor = bid.role == HostBidRole.grandDepart ||
            bid.role == HostBidRole.mountainSummitFinish
        ? 0.16
        : 0.08;
    final penalty = (upliftPercent / 25.0) * 0.42;
    return (0.48 + demandFactor + stabilityFactor + roleFactor - penalty)
        .clamp(0.15, 0.96);
  }

  void _emitChange() {
    widget.onEmpireChanged?.call(
      HostCityBiddingAuctionResult(
        updatedEmpire: _empire,
        awardedBidIds: List.unmodifiable(_awardedBidIds),
        rejectedBidIds: List.unmodifiable(_rejectedBidIds),
        counterOfferedBidIds: List.unmodifiable(_counterOfferedBidIds),
        lastActionMessage: _bannerMessage,
      ),
    );
  }

  void _toggleShortlist(HostCityBid bid) {
    if (widget.isReadOnly || !bid.status.isActiveForDecision) return;
    final nextStatus = bid.status == HostBidStatus.shortlisted
        ? HostBidStatus.openForBidding
        : HostBidStatus.shortlisted;
    final updated = bid.copyWith(status: nextStatus);
    setState(() {
      _empire = _empire.submitHostCityBid(updated);
      _bannerIsSuccess = true;
      _bannerMessage = nextStatus == HostBidStatus.shortlisted
          ? 'Dodano miasto ${bid.cityName} do krótkiej listy finałowej.'
          : 'Przywrócono ofertę ${bid.cityName} do puli otwartej.';
    });
    _emitChange();
  }

  void _submitCounterOffer(HostCityBid bid) {
    if (widget.isReadOnly ||
        !bid.status.isActiveForDecision ||
        _counterOfferedOnce.contains(bid.bidId)) {
      return;
    }

    final chance = _calculateCounterOfferAcceptanceChance(
      bid,
      _counterOfferUpliftPercent,
    );
    // Deterministyczna ewaluacja oparta o próg szansy i profil miasta
    final deterministicSeed =
        ((bid.bidId.hashCode.abs() + _counterOfferUpliftPercent * 7) % 100) /
            100.0;
    final accepted = deterministicSeed <= chance;

    if (accepted) {
      final multiplier = 1.0 + (_counterOfferUpliftPercent / 100.0);
      final raisedFee = (bid.bidFeeEur * multiplier).round();
      final raisedGrant =
          (bid.localInfrastructureGrantEur * (1.0 + _counterOfferUpliftPercent / 200.0))
              .round();
      final updatedBid = bid.copyWith(
        bidFeeEur: raisedFee,
        localInfrastructureGrantEur: raisedGrant,
        status: HostBidStatus.shortlisted,
      );
      setState(() {
        _empire = _empire.submitHostCityBid(updatedBid);
        _counterOfferedOnce.add(bid.bidId);
        _counterOfferedBidIds.add(bid.bidId);
        _bannerIsSuccess = true;
        _bannerMessage =
            'Miasto ${bid.cityName} zaakceptowało kontrofertę +$_counterOfferUpliftPercent%! Nowa opłata: ${Formatters.formatCurrency(raisedFee)}.';
      });
    } else {
      final withdrawnBid = bid.copyWith(status: HostBidStatus.withdrawn);
      setState(() {
        _empire = _empire.submitHostCityBid(withdrawnBid);
        _counterOfferedOnce.add(bid.bidId);
        _counterOfferedBidIds.add(bid.bidId);
        _bannerIsSuccess = false;
        _bannerMessage =
            'Władze ${bid.cityName} odrzuciły żądanie +$_counterOfferUpliftPercent% i wycofały ofertę z przetargu.';
      });
    }
    _emitChange();
  }

  void _awardBid(HostCityBid bid) {
    if (widget.isReadOnly || !bid.status.isActiveForDecision) return;
    final result = _empire.awardHostCityBid(
      bid.bidId,
      contractLengthYears: _contractLengthYears,
    );
    setState(() {
      _empire = result.updatedEmpire;
      _bannerIsSuccess = result.success;
      _bannerMessage = result.message;
      if (result.success) {
        _awardedBidIds.add(bid.bidId);
      }
    });
    _emitChange();
  }

  void _rejectBid(HostCityBid bid) {
    if (widget.isReadOnly || !bid.status.isActiveForDecision) return;
    final result = _empire.rejectHostCityBid(bid.bidId);
    setState(() {
      _empire = result.updatedEmpire;
      _bannerIsSuccess = result.success;
      _bannerMessage = result.message;
      if (result.success) {
        _rejectedBidIds.add(bid.bidId);
      }
    });
    _emitChange();
  }

  void _closeModal() {
    Navigator.of(context).pop(
      HostCityBiddingAuctionResult(
        updatedEmpire: _empire,
        awardedBidIds: List.unmodifiable(_awardedBidIds),
        rejectedBidIds: List.unmodifiable(_rejectedBidIds),
        counterOfferedBidIds: List.unmodifiable(_counterOfferedBidIds),
        lastActionMessage: _bannerMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bids = _filteredBids;
    final selected = _selectedBid;
    final activeCount = _empire.pendingHostCityBids
        .where((b) => b.status.isActiveForDecision)
        .length;
    final grandDepartCount = _empire.pendingHostCityBids
        .where((b) => b.role == HostBidRole.grandDepart && b.status.isActiveForDecision)
        .length;
    final mountainCount = _empire.pendingHostCityBids
        .where(
          (b) =>
              b.role == HostBidRole.mountainSummitFinish &&
              b.status.isActiveForDecision,
        )
        .length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildHeader(
              activeCount: activeCount,
              grandDepartCount: grandDepartCount,
              mountainCount: mountainCount,
            ),
            if (_bannerMessage != null) _buildStatusBanner(),
            _buildFilterBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktopOrWideTablet = constraints.maxWidth >= 820;
                  if (isDesktopOrWideTablet) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: math.min(410, constraints.maxWidth * 0.42),
                          child: _buildBidListPane(bids, selected, isMobile: false),
                        ),
                        Container(width: 1, color: AppTheme.borderColor),
                        Expanded(
                          child: _buildBidInspectorPane(selected, isMobile: false),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _buildMobileViewSwitcher(bids.length, selected),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: _mobileShowDetails && selected != null
                              ? KeyedSubtree(
                                  key: ValueKey('mobile_detail_${selected.bidId}'),
                                  child: _buildBidInspectorPane(
                                    selected,
                                    isMobile: true,
                                  ),
                                )
                              : KeyedSubtree(
                                  key: const ValueKey('mobile_list'),
                                  child: _buildBidListPane(
                                    bids,
                                    selected,
                                    isMobile: true,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required int activeCount,
    required int grandDepartCount,
    required int mountainCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          return Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Przetargi Miast Gospodarzy — Grand Départ & Szczyty',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _empire.syndicateName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (!isCompact) ...[
                          _HeaderStatChip(
                            label: 'Otwarte: $activeCount',
                            color: AppColors.accentBlue,
                          ),
                          _HeaderStatChip(
                            label: 'Grand Départ: $grandDepartCount',
                            color: AppColors.goldAccent,
                          ),
                          _HeaderStatChip(
                            label: 'Mety górskie: $mountainCount',
                            color: AppColors.primaryAccent,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _AuctionInteractiveButton(
                onPressed: _closeModal,
                tooltip: 'Zamknij okno przetargów',
                padding: const EdgeInsets.all(8),
                borderRadius: BorderRadius.circular(10),
                backgroundColor: AppColors.surfaceLight,
                hoverColor: AppColors.cardBorder,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner() {
    final accent =
        _bannerIsSuccess ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _bannerIsSuccess
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _bannerMessage ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _AuctionInteractiveButton(
            onPressed: () => setState(() => _bannerMessage = null),
            padding: const EdgeInsets.all(4),
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.transparent,
            hoverColor: accent.withValues(alpha: 0.15),
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final role in AuctionRoleFilter.values) ...[
              _FilterPillButton(
                label: role.label,
                isSelected: _roleFilter == role,
                accentColor: role == AuctionRoleFilter.grandDepart
                    ? AppColors.goldAccent
                    : (role == AuctionRoleFilter.mountainSummitFinish
                        ? AppColors.primaryAccent
                        : AppColors.accentBlue),
                onPressed: () => setState(() {
                  _roleFilter = role;
                  _mobileShowDetails = false;
                }),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: AppTheme.borderColor,
            ),
            if (_empire.managedRaces.isNotEmpty) ...[
              _FilterPillButton(
                label: 'Wszystkie wyścigi',
                isSelected: _selectedRaceFilterId == null,
                accentColor: AppColors.cyanAccent,
                onPressed: () => setState(() => _selectedRaceFilterId = null),
              ),
              const SizedBox(width: 6),
              for (final race in _empire.managedRaces) ...[
                _FilterPillButton(
                  label: race.raceName,
                  isSelected: _selectedRaceFilterId == race.raceId,
                  accentColor: AppColors.cyanAccent,
                  onPressed: () =>
                      setState(() => _selectedRaceFilterId = race.raceId),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: AppTheme.borderColor,
              ),
            ],
            _FilterPillButton(
              label: _onlyActiveBids ? 'Tylko otwarte' : 'Wszystkie statusy',
              isSelected: _onlyActiveBids,
              accentColor: AppColors.statusSuccess,
              onPressed: () =>
                  setState(() => _onlyActiveBids = !_onlyActiveBids),
            ),
            const SizedBox(width: 10),
            const Text(
              'Sortuj:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            for (final mode in AuctionSortMode.values) ...[
              _FilterPillButton(
                label: mode.label,
                isSelected: _sortMode == mode,
                accentColor: AppColors.goldAccent,
                onPressed: () => setState(() => _sortMode = mode),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileViewSwitcher(int bidCount, HostCityBid? selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterPillButton(
              label: 'Kandydaci ($bidCount)',
              isSelected: !_mobileShowDetails,
              accentColor: AppColors.accentBlue,
              onPressed: () => setState(() => _mobileShowDetails = false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterPillButton(
              label: selected != null
                  ? 'Szczegóły: ${selected.cityName}'
                  : 'Szczegóły',
              isSelected: _mobileShowDetails,
              isEnabled: selected != null,
              accentColor: AppColors.goldAccent,
              onPressed: () => setState(() => _mobileShowDetails = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidListPane(
    List<HostCityBid> bids,
    HostCityBid? selected, {
    required bool isMobile,
  }) {
    if (bids.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_city_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Brak ofert miast dla wybranych filtrów.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Zmień filtr roli lub wyścigu, aby zobaczyć pozostałych kandydatów.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _AuctionInteractiveButton(
                onPressed: () => setState(() {
                  _roleFilter = AuctionRoleFilter.all;
                  _selectedRaceFilterId = null;
                  _onlyActiveBids = false;
                }),
                backgroundColor: AppColors.surfaceLight,
                hoverColor: AppColors.cardBorder,
                borderColor: AppTheme.borderColor,
                child: const Text(
                  'Resetuj filtry',
                  style: TextStyle(
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
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: bids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bid = bids[index];
        final isSelected = selected?.bidId == bid.bidId;
        final race = _raceForBid(bid);
        return _BidCandidateCard(
          bid: bid,
          raceName: race?.raceName ?? bid.raceId,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedBidId = bid.bidId;
              if (isMobile) {
                _mobileShowDetails = true;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildBidInspectorPane(
    HostCityBid? bid, {
    required bool isMobile,
  }) {
    if (bid == null) {
      return const Center(
        child: Text(
          'Wybierz miasto z listy przetargowej, aby rozpocząć ocenę.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final race = _raceForBid(bid);
    final isActive = bid.status.isActiveForDecision && !widget.isReadOnly;
    final hasCounterOffered = _counterOfferedOnce.contains(bid.bidId);
    final acceptanceChance = _calculateCounterOfferAcceptanceChance(
      bid,
      _counterOfferUpliftPercent,
    );
    final projectedTotal =
        bid.totalEconomicValueEur * _contractLengthYears;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInspectorHero(bid, race),
          const SizedBox(height: 16),
          _buildFinancialGrid(bid, projectedTotal),
          const SizedBox(height: 16),
          _buildMetricsCard(bid),
          const SizedBox(height: 16),
          _buildNegotiationConsole(
            bid: bid,
            isActive: isActive,
            hasCounterOffered: hasCounterOffered,
            acceptanceChance: acceptanceChance,
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorHero(
    HostCityBid bid,
    ManagedRacePortfolioItem? race,
  ) {
    final roleColor = _roleColor(bid.role);
    final statusColor = _statusColor(bid.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;
          final scoreBadge = _CompositeScoreBadge(score: bid.compositeBidScore);
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _BadgePill(
                    label: bid.countryCode.toUpperCase(),
                    color: AppColors.accentBlue,
                  ),
                  _BadgePill(
                    label: bid.role.displayNameEn,
                    color: roleColor,
                  ),
                  _BadgePill(
                    label: _statusLabel(bid.status),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                bid.cityName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bid.regionName.isNotEmpty ? '${bid.regionName} • ' : ''}'
                '${race?.raceName ?? bid.raceId} • Etap ${bid.targetStageNumber} • '
                'Termin decyzji: ${bid.deadlineDay} dni',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                scoreBadge,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 16),
              scoreBadge,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFinancialGrid(HostCityBid bid, int projectedMultiYearTotal) {
    final cards = [
      _MetricTileData(
        label: 'Opłata przetargowa',
        value: Formatters.formatCurrency(bid.bidFeeEur),
        accent: AppColors.goldAccent,
        icon: Icons.payments_rounded,
      ),
      _MetricTileData(
        label: 'Grant infrastrukturalny',
        value: Formatters.formatCurrency(bid.localInfrastructureGrantEur),
        accent: AppColors.accentBlue,
        icon: Icons.construction_rounded,
      ),
      _MetricTileData(
        label: 'Potencjał VIP & Strefy',
        value: Formatters.formatCurrency(bid.hospitalityRevenuePotentialEur),
        accent: AppColors.cyanAccent,
        icon: Icons.wine_bar_rounded,
      ),
      _MetricTileData(
        label: 'Pakiet (${_contractLengthYears}r)',
        value: Formatters.formatCurrency(projectedMultiYearTotal),
        accent: AppColors.statusSuccess,
        icon: Icons.account_balance_wallet_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final itemWidth = columns == 2
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: card.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(card.icon, color: card.accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                card.value,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: card.accent,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildMetricsCard(HostCityBid bid) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Parametry Strategiczne i Frekwencja',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_formatCrowdCount(bid.crowdTurnoutForecast)} kibiców',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AnimatedProgressMetric(
            label: 'Dopasowanie profilu trasy',
            value: bid.terrainFitScore,
            color: AppColors.statusSuccess,
          ),
          const SizedBox(height: 10),
          _AnimatedProgressMetric(
            label: 'Ekspozycja turystyczna i medialna',
            value: bid.tourismExposureDemand,
            color: AppColors.accentBlue,
          ),
          const SizedBox(height: 10),
          _AnimatedProgressMetric(
            label: 'Stabilność polityczna i logistyczna',
            value: bid.politicalStabilityIndex,
            color: AppColors.goldAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationConsole({
    required HostCityBid bid,
    required bool isActive,
    required bool hasCounterOffered,
    required double acceptanceChance,
  }) {
    final chancePercent = (acceptanceChance * 100).round();
    final chanceColor = chancePercent >= 70
        ? AppColors.statusSuccess
        : (chancePercent >= 45
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konsola Negocjacji i Rozstrzygnięcia Przetargu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Długość umowy:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              for (final years in const [1, 2, 3])
                _FilterPillButton(
                  label: years == 1 ? '1 rok' : '$years lata',
                  isSelected: _contractLengthYears == years,
                  isEnabled: isActive,
                  accentColor: AppColors.goldAccent,
                  onPressed: () =>
                      setState(() => _contractLengthYears = years),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kontroferta promotora (+$_counterOfferUpliftPercent%)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    _BadgePill(
                      label: 'Szansa akceptacji: $chancePercent%',
                      color: chanceColor,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.goldAccent,
                    inactiveTrackColor: AppColors.cardBorder,
                    thumbColor: AppColors.goldAccent,
                    overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: _counterOfferUpliftPercent.toDouble(),
                    min: 5,
                    max: 25,
                    divisions: 4,
                    label: '+$_counterOfferUpliftPercent%',
                    onChanged: isActive && !hasCounterOffered
                        ? (val) => setState(
                              () => _counterOfferUpliftPercent = val.round(),
                            )
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCounterOffered
                      ? 'Runda kontroferty dla tego miasta została już przeprowadzona.'
                      : 'Nowa docelowa opłata: ${Formatters.formatCurrency((bid.bidFeeEur * (1 + _counterOfferUpliftPercent / 100)).round())}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AuctionInteractiveButton(
                onPressed: isActive ? () => _awardBid(bid) : null,
                isEnabled: isActive,
                backgroundColor: AppColors.goldAccent,
                hoverColor: const Color(0xFFE0BE4C),
                borderColor: AppColors.goldAccent,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 17, color: Color(0xFF0F1115)),
                    SizedBox(width: 8),
                    Text(
                      'Przyznaj Przetarg',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F1115),
                      ),
                    ),
                  ],
                ),
              ),
              _AuctionInteractiveButton(
                onPressed: isActive && !hasCounterOffered
                    ? () => _submitCounterOffer(bid)
                    : null,
                isEnabled: isActive && !hasCounterOffered,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.16),
                hoverColor: AppColors.accentBlue.withValues(alpha: 0.28),
                borderColor: AppColors.accentBlue.withValues(alpha: 0.6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 17,
                      color: AppColors.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wyślij Kontrofertę +$_counterOfferUpliftPercent%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
              _AuctionInteractiveButton(
                onPressed: isActive ? () => _toggleShortlist(bid) : null,
                isEnabled: isActive,
                backgroundColor: AppColors.surface,
                hoverColor: AppColors.cardBorder,
                borderColor: AppTheme.borderColor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      bid.status == HostBidStatus.shortlisted
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined,
                      size: 17,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bid.status == HostBidStatus.shortlisted
                          ? 'Usuń z krótkiej listy'
                          : 'Krótka lista',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _AuctionInteractiveButton(
                onPressed: isActive ? () => _rejectBid(bid) : null,
                isEnabled: isActive,
                backgroundColor: AppColors.crimsonAlert.withValues(alpha: 0.12),
                hoverColor: AppColors.crimsonAlert.withValues(alpha: 0.24),
                borderColor: AppColors.crimsonAlert.withValues(alpha: 0.5),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      size: 17,
                      color: AppColors.crimsonAlert,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Odrzuć',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.crimsonAlert,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;
          final cashWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_rounded,
                size: 16,
                color: AppColors.statusSuccess,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Płynność budżetu: ${Formatters.formatCurrency(_empire.budgetLedger.liquidCashEur)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          );

          final closeButton = _AuctionInteractiveButton(
            onPressed: _closeModal,
            backgroundColor: AppColors.primaryAccent,
            hoverColor: const Color(0xFFA25756),
            borderColor: AppColors.primaryAccent,
            child: const Text(
              'Zatwierdź i Zamknij',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          );

          if (isCompact) {
            return Row(
              children: [
                Expanded(child: cashWidget),
                const SizedBox(width: 10),
                closeButton,
              ],
            );
          }

          return Row(
            children: [
              cashWidget,
              const Spacer(),
              closeButton,
            ],
          );
        },
      ),
    );
  }

  static String _formatCrowdCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).round()} tys.';
    }
    return '$count';
  }

  static Color _roleColor(HostBidRole role) {
    switch (role) {
      case HostBidRole.grandDepart:
        return AppColors.goldAccent;
      case HostBidRole.mountainSummitFinish:
        return AppColors.primaryAccent;
      case HostBidRole.finalChampsElyseesFinish:
        return AppColors.cyanAccent;
      case HostBidRole.individualTimeTrialHost:
        return AppColors.accentBlue;
      case HostBidRole.stageStart:
      case HostBidRole.stageFinish:
        return AppColors.textSecondary;
    }
  }

  static Color _statusColor(HostBidStatus status) {
    switch (status) {
      case HostBidStatus.openForBidding:
        return AppColors.accentBlue;
      case HostBidStatus.shortlisted:
        return AppColors.goldAccent;
      case HostBidStatus.awarded:
        return AppColors.statusSuccess;
      case HostBidStatus.rejected:
      case HostBidStatus.withdrawn:
      case HostBidStatus.expired:
        return AppColors.crimsonAlert;
    }
  }

  static String _statusLabel(HostBidStatus status) {
    switch (status) {
      case HostBidStatus.openForBidding:
        return 'Otwarta';
      case HostBidStatus.shortlisted:
        return 'Krótka lista';
      case HostBidStatus.awarded:
        return 'Przyznano';
      case HostBidStatus.rejected:
        return 'Odrzucona';
      case HostBidStatus.expired:
        return 'Wygasła';
      case HostBidStatus.withdrawn:
        return 'Wycofana';
    }
  }
}

class _HeaderStatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _HeaderStatChip({
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
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgePill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
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

class _CompositeScoreBadge extends StatelessWidget {
  final double score;

  const _CompositeScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.statusSuccess
        : (score >= 60 ? AppColors.goldAccent : AppColors.amberWarning);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            'OCENA / 100',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _AnimatedProgressMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = (value.clamp(0.0, 100.0)) / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              '${value.toStringAsFixed(0)}%',
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
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 7,
            width: double.infinity,
            color: AppColors.surfaceLight,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: clamped),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animatedValue,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BidCandidateCard extends StatefulWidget {
  final HostCityBid bid;
  final String raceName;
  final bool isSelected;
  final VoidCallback onTap;

  const _BidCandidateCard({
    required this.bid,
    required this.raceName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BidCandidateCard> createState() => _BidCandidateCardState();
}

class _BidCandidateCardState extends State<_BidCandidateCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bid = widget.bid;
    final roleColor = _HostCityBiddingAuctionModalState._roleColor(bid.role);
    final statusColor =
        _HostCityBiddingAuctionModalState._statusColor(bid.status);

    final bgColor = widget.isSelected
        ? AppColors.surfaceLight
        : (_hovered ? const Color(0xFF1E222B) : AppColors.surface);
    final borderColor = _focused
        ? AppColors.accentBlue
        : (widget.isSelected
            ? AppColors.goldAccent
            : (_hovered ? AppColors.cardBorder : AppTheme.borderColor));

    return FocusableActionDetector(
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      mouseCursor: SystemMouseCursors.click,
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
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _focused ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _BadgePill(
                      label: bid.countryCode.toUpperCase(),
                      color: AppColors.accentBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bid.cityName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bid.compositeBidScore.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _BadgePill(
                      label: bid.role.displayNameEn,
                      color: roleColor,
                    ),
                    _BadgePill(
                      label: _HostCityBiddingAuctionModalState._statusLabel(
                        bid.status,
                      ),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.raceName} • Etap ${bid.targetStageNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.formatCurrency(bid.totalEconomicValueEur),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusSuccess,
                        fontFeatures: [FontFeature.tabularFigures()],
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

class _FilterPillButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _FilterPillButton({
    required this.label,
    required this.isSelected,
    this.isEnabled = true,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_FilterPillButton> createState() => _FilterPillButtonState();
}

class _FilterPillButtonState extends State<_FilterPillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled;
    final bgColor = !enabled
        ? AppColors.surface.withValues(alpha: 0.4)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.2)
            : (_hovered ? AppColors.cardBorder : AppColors.surfaceLight);
    final borderColor = _focused
        ? AppColors.accentBlue
        : (widget.isSelected
            ? widget.accentColor
            : AppTheme.borderColor);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _focused ? 1.3 : 1.0,
              ),
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: !enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : (widget.isSelected
                        ? widget.accentColor
                        : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuctionInteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final Color backgroundColor;
  final Color hoverColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final String? tooltip;

  const _AuctionInteractiveButton({
    required this.child,
    required this.onPressed,
    this.isEnabled = true,
    required this.backgroundColor,
    required this.hoverColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.tooltip,
  });

  @override
  State<_AuctionInteractiveButton> createState() =>
      _AuctionInteractiveButtonState();
}

class _AuctionInteractiveButtonState extends State<_AuctionInteractiveButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isEnabled && widget.onPressed != null;
    final bgColor = !active
        ? AppColors.surface.withValues(alpha: 0.5)
        : (_hovered ? widget.hoverColor : widget.backgroundColor);
    final border = _focused
        ? AppColors.accentBlue
        : (active
            ? (widget.borderColor ?? Colors.transparent)
            : AppTheme.borderColor);

    final button = FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (active) widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: active ? 1.0 : 0.45,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: widget.borderRadius,
                border: Border.all(
                  color: border,
                  width: _focused ? 1.5 : 1.0,
                ),
              ),
              child: widget.child,
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

class _MetricTileData {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _MetricTileData({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });
}
