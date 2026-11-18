// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/team_merchandise_and_fan_club_revenue.dart';

/// Zakładki wewnętrzne karty bazy kibiców i sprzedaży gadżetów klubowych.
enum FanBaseCardTab {
  overview('Przegląd & Regiony', Icons.public_rounded),
  bestsellers('Bestsellery Sklepu', Icons.storefront_rounded),
  starRiders('Gwiazdy & Repliki', Icons.star_rounded),
  fanZones('Strefy Kibica', Icons.stadium_rounded);

  const FanBaseCardTab(this.labelPl, this.icon);

  final String labelPl;
  final IconData icon;
}

/// Udział regionalny bazy kibiców obliczony przez [FanBaseAndMerchandiseAnalytics].
class RegionalFanShare {
  const RegionalFanShare({
    required this.regionCode,
    required this.supportersCount,
    required this.sharePercent,
  });

  final String regionCode;
  final int supportersCount;
  final double sharePercent;
}

/// Pomocniczy kalkulator analityczny dla karty [FanBaseAndMerchandiseCard].
class FanBaseAndMerchandiseAnalytics {
  const FanBaseAndMerchandiseAnalytics._();

  /// Formatuje liczbę kibiców w czytelnym formacie (np. `148.5 tys.`, `1.24 mln`).
  static String formatFanCount(int count) {
    if (count <= 0) return '0';
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(2)} mln';
    }
    if (count >= 1000) {
      final k = count / 1000;
      return k >= 100
          ? '${k.round()} tys.'
          : '${k.toStringAsFixed(1)} tys.';
    }
    return count.toString();
  }

  /// Zwraca posortowaną malejąco listę regionów z udziałem procentowym.
  static List<RegionalFanShare> computeRegionalShares(
    Map<String, int> regionalSupporters,
  ) {
    if (regionalSupporters.isEmpty) return const [];
    final total = regionalSupporters.values.fold<int>(
      0,
      (sum, value) => sum + math.max(0, value),
    );
    final entries = regionalSupporters.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((entry) {
      final count = math.max(0, entry.value);
      final pct = total > 0 ? (count / total) * 100.0 : 0.0;
      return RegionalFanShare(
        regionCode: entry.key,
        supportersCount: count,
        sharePercent: pct,
      );
    }).toList(growable: false);
  }

  /// Zwraca produkty sklepu posortowane według przychodu sezonowego (lub sprzedaży).
  static List<MerchandiseProductSpec> sortProductsByPerformance(
    List<MerchandiseProductSpec> catalog,
  ) {
    final sorted = List<MerchandiseProductSpec>.from(catalog);
    sorted.sort((a, b) {
      final revCmp = b.grossRevenueEur.compareTo(a.grossRevenueEur);
      if (revCmp != 0) return revCmp;
      return b.unitsSoldSeason.compareTo(a.unitsSoldSeason);
    });
    return sorted;
  }

  /// Oblicza marżę procentową produktu z zabezpieczeniem przed dzieleniem przez zero.
  static double productMarginPercent(MerchandiseProductSpec product) {
    if (product.retailPriceEur <= 0) return 0.0;
    return ((product.retailPriceEur - product.unitProductionCostEur) /
            product.retailPriceEur) *
        100.0;
  }

  /// Zwraca maksymalną wartość przychodu brutto w księdze miesięcznej (minimum 1.0).
  static double maxLedgerGrossRevenue(List<MonthlyMerchandiseLedgerEntry> ledger) {
    if (ledger.isEmpty) return 1.0;
    double maxVal = 0.0;
    for (final entry in ledger) {
      if (entry.grossRevenueEur > maxVal) {
        maxVal = entry.grossRevenueEur;
      }
    }
    return maxVal <= 0.0 ? 1.0 : maxVal;
  }
}

/// Karta bazy kibiców i sprzedaży gadżetów klubowych z pełną interaktywnością,
/// stanami `hover` / `active` / `disabled` / `focus` i responsywnością
/// `390x844`, `1024x768` oraz `1600x900`.
class FanBaseAndMerchandiseCard extends ConsumerStatefulWidget {
  const FanBaseAndMerchandiseCard({
    super.key,
    this.stateOverride,
    this.initialTab = FanBaseCardTab.overview,
    this.enabled = true,
    this.onOpenFullStore,
    this.onSimulateMonth,
    this.onRestockProduct,
    this.onToggleProductActive,
    this.onLaunchSpecialEditionDrop,
    this.onExecuteFanZone,
    this.onMembershipFeeChanged,
  });

  /// Opcjonalne nadpisanie stanu (przydatne w podglądach i testach bez mutacji globalnej).
  final TeamMerchandiseAndFanClubState? stateOverride;

  /// Domyślna aktywna zakładka karty.
  final FanBaseCardTab initialTab;

  /// Flaga globalnego włączenia/wyłączenia interakcji na karcie.
  final bool enabled;

  /// Opcjonalny callback otwarcia pełnego panelu sklepu klubowego.
  final VoidCallback? onOpenFullStore;

  /// Opcjonalny callback rozliczenia miesiąca.
  final VoidCallback? onSimulateMonth;

  /// Opcjonalny callback domówienia partii produktu (`productId`, `quantity`).
  final void Function(String productId, int quantity)? onRestockProduct;

  /// Opcjonalny callback przełączenia aktywności produktu.
  final void Function(String productId)? onToggleProductActive;

  /// Opcjonalny callback wydania limitowanej edycji koszulki dla kolarza.
  final void Function(StarRiderJerseyDemand rider)? onLaunchSpecialEditionDrop;

  /// Opcjonalny callback realizacji zaplanowanej strefy kibica.
  final void Function(String fanZoneId)? onExecuteFanZone;

  /// Opcjonalny callback zmiany rocznej składki fanklubu.
  final ValueChanged<double>? onMembershipFeeChanged;

  @override
  ConsumerState<FanBaseAndMerchandiseCard> createState() =>
      _FanBaseAndMerchandiseCardState();
}

class _FanBaseAndMerchandiseCardState
    extends ConsumerState<FanBaseAndMerchandiseCard> {
  late FanBaseCardTab _activeTab;
  String? _selectedRegionCode;
  int? _hoveredMonthIndex;
  int? _selectedMonthIndex;
  double? _pendingFeePreview;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  TeamMerchandiseAndFanClubState _resolveState() {
    return widget.stateOverride ?? ref.watch(teamMerchandiseAndFanClubProvider);
  }

  void _handleSimulateMonth() {
    if (!widget.enabled) return;
    if (widget.onSimulateMonth != null) {
      widget.onSimulateMonth!();
      return;
    }
    ref.read(teamMerchandiseAndFanClubProvider.notifier).runMonthlyStoreCycle();
  }

  void _handleRestockProduct(String productId, int quantity) {
    if (!widget.enabled) return;
    if (widget.onRestockProduct != null) {
      widget.onRestockProduct!(productId, quantity);
      return;
    }
    ref
        .read(teamMerchandiseAndFanClubProvider.notifier)
        .restockProduct(productId, quantity);
  }

  void _handleToggleProductActive(String productId) {
    if (!widget.enabled) return;
    if (widget.onToggleProductActive != null) {
      widget.onToggleProductActive!(productId);
      return;
    }
    ref
        .read(teamMerchandiseAndFanClubProvider.notifier)
        .toggleProductActive(productId);
  }

  void _handleLaunchDrop(StarRiderJerseyDemand rider) {
    if (!widget.enabled) return;
    if (widget.onLaunchSpecialEditionDrop != null) {
      widget.onLaunchSpecialEditionDrop!(rider);
      return;
    }
    ref.read(teamMerchandiseAndFanClubProvider.notifier).launchSpecialEditionDrop(
          editionTitle: '${rider.riderName} Victory Edition',
          riderId: rider.riderId,
          riderName: rider.riderName,
        );
  }

  void _handleExecuteFanZone(String fanZoneId) {
    if (!widget.enabled) return;
    if (widget.onExecuteFanZone != null) {
      widget.onExecuteFanZone!(fanZoneId);
      return;
    }
    ref
        .read(teamMerchandiseAndFanClubProvider.notifier)
        .executeFanZone(fanZoneId);
  }

  void _handleMembershipFeeCommit(double value) {
    if (!widget.enabled) return;
    setState(() => _pendingFeePreview = null);
    if (widget.onMembershipFeeChanged != null) {
      widget.onMembershipFeeChanged!(value);
      return;
    }
    ref
        .read(teamMerchandiseAndFanClubProvider.notifier)
        .updateMembershipFee(value);
  }

  void _handleOpenFullStore() {
    if (!widget.enabled) return;
    if (widget.onOpenFullStore != null) {
      widget.onOpenFullStore!();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.background,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor, width: 1.0),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 780),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.goldAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Oficjalny Sklep Klubowy & Fan Zones',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zamknij',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: TeamMerchandiseAndFanClubPanel(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _resolveState();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = width < 600;
        final isTablet = width >= 600 && width < 1050;
        final horizontalPadding = isCompact ? 14.0 : 20.0;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.enabled ? 1.0 : 0.62,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderColor,
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(state, isCompact: isCompact),
                  if (state.lastNotification != null &&
                      state.lastNotification!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildNotificationBanner(state.lastNotification!),
                  ],
                  const SizedBox(height: 16),
                  _buildKpiGrid(
                    state,
                    isCompact: isCompact,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 16),
                  _buildTabBar(isCompact: isCompact),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_activeTab),
                      child: _buildActiveTabBody(
                        state,
                        isCompact: isCompact,
                        isTablet: isTablet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFooterMembershipControl(state, isCompact: isCompact),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    TeamMerchandiseAndFanClubState state, {
    required bool isCompact,
  }) {
    final tier = state.fanClub.tier;
    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isCompact ? 40 : 44,
          height: isCompact ? 40 : 44,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.65),
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.groups_rounded,
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
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Baza Kibiców & Gadżety Klubowe',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tier.badgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: tier.badgeColor.withValues(alpha: 0.55),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      tier.displayNamePl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tier.badgeColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${state.teamName} • Sezon ${state.seasonYear} (Miesiąc ${state.currentMonth}/12) • Prestiż ${state.teamPrestige.round()}/100',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CardInteractiveButton(
          label: 'Rozlicz miesiąc',
          icon: Icons.autorenew_rounded,
          isPrimary: true,
          enabled: widget.enabled,
          onPressed: _handleSimulateMonth,
        ),
        _CardInteractiveButton(
          label: 'Pełny sklep',
          icon: Icons.open_in_new_rounded,
          isPrimary: false,
          enabled: widget.enabled,
          onPressed: _handleOpenFullStore,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  Widget _buildNotificationBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusSuccess.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppColors.statusSuccess,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    TeamMerchandiseAndFanClubState state, {
    required bool isCompact,
    required bool isTablet,
  }) {
    final executedZones = state.fanZones.where((z) => z.executed).length;
    final activeProducts = state.catalog.where((p) => p.active).length;

    final cards = [
      _CardKpiTile(
        title: 'Baza Kibiców',
        value: FanBaseAndMerchandiseAnalytics.formatFanCount(
          state.fanClub.totalFanBase,
        ),
        subtitle:
            'Członkowie: ${state.fanClub.paidClubMembers} (${state.fanClub.conversionRatePercent.toStringAsFixed(1)}%)',
        badgeText:
            'Zaang. ${state.fanClub.fanEngagementIndex.toStringAsFixed(0)}/100',
        accentColor: AppColors.accentBlue,
        icon: Icons.favorite_rounded,
      ),
      _CardKpiTile(
        title: 'Przychód Sezonu',
        value: Formatters.formatCompactCurrency(
          state.report.totalGrossRevenueEur,
        ),
        subtitle:
            'Zysk netto: ${Formatters.formatCompactCurrency(state.report.totalNetProfitEur)}',
        badgeText:
            'Marża ${state.report.averageMarginPercent.toStringAsFixed(1)}%',
        accentColor: AppColors.statusSuccess,
        icon: Icons.trending_up_rounded,
      ),
      _CardKpiTile(
        title: 'Sprzedane Gadżety',
        value: '${state.report.totalUnitsSold} szt.',
        subtitle:
            'Top: ${state.report.topSellingCategory.displayNamePl}',
        badgeText: '$activeProducts/${state.catalog.length} aktywne',
        accentColor: AppColors.goldAccent,
        icon: Icons.shopping_bag_rounded,
      ),
      _CardKpiTile(
        title: 'Fanklub & Strefy',
        value:
            '${Formatters.formatCurrency(state.fanClub.annualMembershipFeeEur)}/rok',
        subtitle:
            'Fan Zones: $executedZones/${state.fanZones.length} zrealiz.',
        badgeText: state.report.topSellingRiderName,
        accentColor: AppColors.primaryAccent,
        icon: Icons.stadium_rounded,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildTabBar({required bool isCompact}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FanBaseCardTab.values.map((tab) {
          final isSelected = _activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CardTabChip(
              label: tab.labelPl,
              icon: tab.icon,
              selected: isSelected,
              enabled: widget.enabled,
              compact: isCompact,
              onTap: () => setState(() => _activeTab = tab),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildActiveTabBody(
    TeamMerchandiseAndFanClubState state, {
    required bool isCompact,
    required bool isTablet,
  }) {
    switch (_activeTab) {
      case FanBaseCardTab.overview:
        return _buildOverviewTab(state, isCompact: isCompact, isTablet: isTablet);
      case FanBaseCardTab.bestsellers:
        return _buildBestsellersTab(state, isCompact: isCompact);
      case FanBaseCardTab.starRiders:
        return _buildStarRidersTab(state, isCompact: isCompact);
      case FanBaseCardTab.fanZones:
        return _buildFanZonesTab(state, isCompact: isCompact);
    }
  }

  Widget _buildOverviewTab(
    TeamMerchandiseAndFanClubState state, {
    required bool isCompact,
    required bool isTablet,
  }) {
    final regionalShares = FanBaseAndMerchandiseAnalytics.computeRegionalShares(
      state.fanClub.regionalSupporters,
    );

    final regionalPanel = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public_rounded,
                size: 16,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Geografia Bazy Kibiców',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (_selectedRegionCode != null)
                TextButton(
                  onPressed: widget.enabled
                      ? () => setState(() => _selectedRegionCode = null)
                      : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Wszystkie',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (regionalShares.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Brak danych regionalnych o kibicach.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: regionalShares.map((region) {
                final isSelected = _selectedRegionCode == region.regionCode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RegionProgressRow(
                    region: region,
                    selected: isSelected,
                    enabled: widget.enabled,
                    onTap: () {
                      setState(() {
                        _selectedRegionCode =
                            isSelected ? null : region.regionCode;
                      });
                    },
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );

    final ledgerPanel = _buildMonthlyRevenueChartPanel(state);

    if (isCompact || isTablet) {
      return Column(
        children: [
          regionalPanel,
          const SizedBox(height: 12),
          ledgerPanel,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: regionalPanel),
        const SizedBox(width: 12),
        Expanded(flex: 6, child: ledgerPanel),
      ],
    );
  }

  Widget _buildMonthlyRevenueChartPanel(TeamMerchandiseAndFanClubState state) {
    final ledger = state.monthlyLedger;
    final activeIdx = _hoveredMonthIndex ??
        _selectedMonthIndex ??
        (ledger.isNotEmpty ? ledger.length - 1 : null);
    final activeEntry =
        (activeIdx != null && activeIdx >= 0 && activeIdx < ledger.length)
            ? ledger[activeIdx]
            : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 16,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Przychody Miesięczne (Brutto vs Netto)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (activeEntry != null)
                Text(
                  '${activeEntry.monthLabel}: ${Formatters.formatCompactCurrency(activeEntry.grossRevenueEur)}',
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
          const SizedBox(height: 12),
          if (ledger.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'Rozlicz pierwszy miesiąc, aby zobaczyć wykres sprzedaży.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 152,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, chartConstraints) {
                  return MouseRegion(
                    onHover: widget.enabled
                        ? (event) {
                            final idx = _hitTestMonthIndex(
                              event.localPosition.dx,
                              chartConstraints.maxWidth,
                              ledger.length,
                            );
                            if (idx != _hoveredMonthIndex) {
                              setState(() => _hoveredMonthIndex = idx);
                            }
                          }
                        : null,
                    onExit: (_) => setState(() => _hoveredMonthIndex = null),
                    child: GestureDetector(
                      onTapDown: widget.enabled
                          ? (details) {
                              final idx = _hitTestMonthIndex(
                                details.localPosition.dx,
                                chartConstraints.maxWidth,
                                ledger.length,
                              );
                              setState(() => _selectedMonthIndex = idx);
                            }
                          : null,
                      child: CustomPaint(
                        painter: MonthlyMerchandiseRevenuePainter(
                          entries: ledger,
                          activeIndex: activeIdx,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (activeEntry != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _MiniLegendMetric(
                    color: AppColors.accentBlue,
                    label: 'Sklep',
                    value: Formatters.formatCurrency(activeEntry.storeRevenueEur),
                  ),
                  _MiniLegendMetric(
                    color: AppColors.goldAccent,
                    label: 'Fanklub',
                    value: Formatters.formatCurrency(activeEntry.fanClubRevenueEur),
                  ),
                  _MiniLegendMetric(
                    color: AppColors.statusSuccess,
                    label: 'Zysk netto',
                    value: Formatters.formatCurrency(activeEntry.netProfitEur),
                  ),
                  _MiniLegendMetric(
                    color: AppColors.textSecondary,
                    label: 'Wolumen',
                    value: '${activeEntry.unitsSold} szt.',
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  int? _hitTestMonthIndex(double dx, double width, int count) {
    if (count <= 0 || width <= 0) return null;
    final slotWidth = width / count;
    final index = (dx / slotWidth).floor().clamp(0, count - 1);
    return index;
  }

  Widget _buildBestsellersTab(
    TeamMerchandiseAndFanClubState state, {
    required bool isCompact,
  }) {
    final sorted = FanBaseAndMerchandiseAnalytics.sortProductsByPerformance(
      state.catalog,
    );
    if (sorted.isEmpty) {
      return _buildEmptyStateBox(
        icon: Icons.inventory_2_outlined,
        message: 'Brak produktów w katalogu sklepu klubowego.',
      );
    }

    final topItems = sorted.take(5).toList(growable: false);
    return Column(
      children: topItems.map((product) {
        final marginPct =
            FanBaseAndMerchandiseAnalytics.productMarginPercent(product);
        final isLowStock = product.stockUnits < 100;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ProductCompactTile(
            product: product,
            marginPercent: marginPct,
            isLowStock: isLowStock,
            isCompact: isCompact,
            enabled: widget.enabled,
            onRestock: () => _handleRestockProduct(product.id, 250),
            onToggleActive: () => _handleToggleProductActive(product.id),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildStarRidersTab(
    TeamMerchandiseAndFanClubState state, {
    required bool isCompact,
  }) {
    final riders = state.starRiders;
    if (riders.isEmpty) {
      return _buildEmptyStateBox(
        icon: Icons.directions_bike_rounded,
        message: 'Brak kolarzy przypisanych do sprzedaży replik koszulek.',
      );
    }

    return Column(
      children: riders.map((rider) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _StarRiderDemandRow(
            rider: rider,
            isCompact: isCompact,
            enabled: widget.enabled,
            onLaunchDrop: () => _handleLaunchDrop(rider),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildFanZonesTab(
    TeamMerchandiseAndFanClubState state, {
    required bool isCompact,
  }) {
    final zones = state.fanZones;
    if (zones.isEmpty) {
      return _buildEmptyStateBox(
        icon: Icons.stadium_outlined,
        message: 'Brak zaplanowanych stref kibica (Fan Zones).',
      );
    }

    return Column(
      children: zones.map((zone) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _FanZoneCompactRow(
            zone: zone,
            isCompact: isCompact,
            enabled: widget.enabled,
            onExecute: () => _handleExecuteFanZone(zone.id),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildFooterMembershipControl(
    TeamMerchandiseAndFanClubState state, {
    required bool isCompact,
  }) {
    final currentFee = _pendingFeePreview ?? state.fanClub.annualMembershipFeeEur;
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.goldAccent,
        inactiveTrackColor: AppColors.cardBorder,
        thumbColor: AppColors.goldAccent,
        overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
        trackHeight: 4,
      ),
      child: Slider(
        value: currentFee.clamp(19.0, 149.0),
        min: 19.0,
        max: 149.0,
        divisions: 26,
        onChanged: widget.enabled
            ? (val) => setState(() => _pendingFeePreview = val)
            : null,
        onChangeEnd: widget.enabled ? _handleMembershipFeeCommit : null,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Roczna składka fanklubu',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${Formatters.formatCurrency(currentFee)} / rok',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                slider,
              ],
            )
          : Row(
              children: [
                const Icon(
                  Icons.card_membership_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Składka fanklubu:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: slider),
                const SizedBox(width: 12),
                Text(
                  '${Formatters.formatCurrency(currentFee)} / rok',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyStateBox({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wykres słupkowy miesięcznych przychodów brutto i zysku netto sklepu klubowego.
class MonthlyMerchandiseRevenuePainter extends CustomPainter {
  const MonthlyMerchandiseRevenuePainter({
    required this.entries,
    this.activeIndex,
  });

  final List<MonthlyMerchandiseLedgerEntry> entries;
  final int? activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || size.width <= 0 || size.height <= 0) return;

    const bottomLabelHeight = 20.0;
    const topPadding = 8.0;
    final chartHeight = math.max(12.0, size.height - bottomLabelHeight - topPadding);
    final maxRevenue = FanBaseAndMerchandiseAnalytics.maxLedgerGrossRevenue(entries);

    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 2; i++) {
      final y = topPadding + chartHeight * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final slotWidth = size.width / entries.length;
    final barWidth = math.min(26.0, math.max(8.0, slotWidth * 0.36));

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isActive = i == activeIndex;
      final centerX = slotWidth * i + slotWidth / 2;

      final grossRatio = (entry.grossRevenueEur / maxRevenue).clamp(0.0, 1.0);
      final netRatio =
          (math.max(0.0, entry.netProfitEur) / maxRevenue).clamp(0.0, 1.0);

      final grossHeight = math.max(4.0, chartHeight * grossRatio);
      final netHeight = math.max(3.0, chartHeight * netRatio);

      final grossRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth - 1.5,
          topPadding + chartHeight - grossHeight,
          barWidth,
          grossHeight,
        ),
        const Radius.circular(4),
      );
      final netRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + 1.5,
          topPadding + chartHeight - netHeight,
          barWidth,
          netHeight,
        ),
        const Radius.circular(4),
      );

      final grossPaint = Paint()
        ..color = isActive
            ? AppColors.accentBlue
            : AppColors.accentBlue.withValues(alpha: 0.65);
      final netPaint = Paint()
        ..color = isActive
            ? AppColors.statusSuccess
            : AppColors.statusSuccess.withValues(alpha: 0.65);

      canvas.drawRRect(grossRect, grossPaint);
      canvas.drawRRect(netRect, netPaint);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: entry.monthLabel,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.goldAccent : AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slotWidth);

      labelPainter.paint(
        canvas,
        Offset(
          centerX - labelPainter.width / 2,
          topPadding + chartHeight + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MonthlyMerchandiseRevenuePainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.activeIndex != activeIndex;
  }
}

class _CardKpiTile extends StatefulWidget {
  const _CardKpiTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.badgeText,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final String badgeText;
  final Color accentColor;
  final IconData icon;

  @override
  State<_CardKpiTile> createState() => _CardKpiTileState();
}

class _CardKpiTileState extends State<_CardKpiTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? widget.accentColor.withValues(alpha: 0.65)
                : AppColors.cardBorder,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 15, color: widget.accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.badgeText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: widget.accentColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTabChip extends StatefulWidget {
  const _CardTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_CardTabChip> createState() => _CardTabChipState();
}

class _CardTabChipState extends State<_CardTabChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? AppColors.primaryAccent
            : (_hovered ? AppColors.textSecondary : AppTheme.borderColor));
    final fgColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.selected ? AppColors.goldAccent : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _pressed ? 0.97 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: fgColor,
                    letterSpacing: -0.2,
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

class _CardInteractiveButton extends StatefulWidget {
  const _CardInteractiveButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_CardInteractiveButton> createState() => _CardInteractiveButtonState();
}

class _CardInteractiveButtonState extends State<_CardInteractiveButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseBg =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : (_hovered ? baseBg.withValues(alpha: 0.88) : baseBg);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isPrimary ? AppColors.primaryAccent : AppTheme.borderColor);
    final fgColor = !widget.enabled
        ? AppColors.textSecondary
        : (widget.isPrimary ? Colors.white : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
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
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _pressed ? 0.97 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                    letterSpacing: -0.2,
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

class _RegionProgressRow extends StatefulWidget {
  const _RegionProgressRow({
    required this.region,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final RegionalFanShare region;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_RegionProgressRow> createState() => _RegionProgressRowState();
}

class _RegionProgressRowState extends State<_RegionProgressRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final barFraction = (widget.region.sharePercent / 100.0).clamp(0.0, 1.0);
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent.withValues(alpha: 0.18)
                : (_hovered
                    ? AppColors.background.withValues(alpha: 0.7)
                    : AppColors.background.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.selected
                      ? AppColors.primaryAccent
                      : AppTheme.borderColor),
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      widget.region.regionCode,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.selected
                            ? AppColors.goldAccent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: barFraction,
                        minHeight: 7,
                        backgroundColor: AppColors.cardBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.selected
                              ? AppColors.goldAccent
                              : AppColors.accentBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${FanBaseAndMerchandiseAnalytics.formatFanCount(widget.region.supportersCount)} (${widget.region.sharePercent.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
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

class _ProductCompactTile extends StatelessWidget {
  const _ProductCompactTile({
    required this.product,
    required this.marginPercent,
    required this.isLowStock,
    required this.isCompact,
    required this.enabled,
    required this.onRestock,
    required this.onToggleActive,
  });

  final MerchandiseProductSpec product;
  final double marginPercent;
  final bool isLowStock;
  final bool isCompact;
  final bool enabled;
  final VoidCallback onRestock;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final stockColor =
        isLowStock ? AppColors.amberWarning : AppColors.statusSuccess;

    final infoBlock = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          child: Icon(
            product.category.icon,
            size: 18,
            color:
                product.active ? AppColors.goldAccent : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: product.active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${product.qualityTier.displayNamePl} • ${Formatters.formatCurrency(product.retailPriceEur)} • Marża ${marginPercent.toStringAsFixed(0)}% • Sprzedano: ${product.unitsSoldSeason} szt.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final controls = Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: stockColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Stan: ${product.stockUnits} szt.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: stockColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _CardInteractiveButton(
          label: '+250 szt.',
          icon: Icons.add_box_outlined,
          isPrimary: false,
          enabled: enabled,
          onPressed: onRestock,
        ),
        _CardInteractiveButton(
          label: product.active ? 'Wstrzymaj' : 'Aktywuj',
          icon: product.active
              ? Icons.pause_circle_outline_rounded
              : Icons.play_circle_outline_rounded,
          isPrimary: false,
          enabled: enabled,
          onPressed: onToggleActive,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoBlock,
                const SizedBox(height: 10),
                controls,
              ],
            )
          : Row(
              children: [
                Expanded(child: infoBlock),
                const SizedBox(width: 12),
                controls,
              ],
            ),
    );
  }
}

class _StarRiderDemandRow extends StatelessWidget {
  const _StarRiderDemandRow({
    required this.rider,
    required this.isCompact,
    required this.enabled,
    required this.onLaunchDrop,
  });

  final StarRiderJerseyDemand rider;
  final bool isCompact;
  final bool enabled;
  final VoidCallback onLaunchDrop;

  @override
  Widget build(BuildContext context) {
    final riderInfo = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: rider.isWearingLeaderJersey
                ? AppColors.goldAccent.withValues(alpha: 0.2)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: rider.isWearingLeaderJersey
                  ? AppColors.goldAccent
                  : AppTheme.borderColor,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            rider.nationality,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: rider.isWearingLeaderJersey
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      rider.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rider.isWearingLeaderJersey) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 14,
                      color: AppColors.goldAccent,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Popularność ${rider.popularityScore.toStringAsFixed(0)} • Udział replik ${rider.estimatedReplicaSharePercent.toStringAsFixed(0)}% • ${rider.seasonUnitsSold} szt. (${Formatters.formatCompactCurrency(rider.seasonRevenueEur)})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final actionButton = _CardInteractiveButton(
      label: 'Edycja Limitowana',
      icon: Icons.auto_awesome_rounded,
      isPrimary: false,
      enabled: enabled,
      onPressed: onLaunchDrop,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                riderInfo,
                const SizedBox(height: 10),
                actionButton,
              ],
            )
          : Row(
              children: [
                Expanded(child: riderInfo),
                const SizedBox(width: 12),
                actionButton,
              ],
            ),
    );
  }
}

class _FanZoneCompactRow extends StatelessWidget {
  const _FanZoneCompactRow({
    required this.zone,
    required this.isCompact,
    required this.enabled,
    required this.onExecute,
  });

  final FanZoneActivation zone;
  final bool isCompact;
  final bool enabled;
  final VoidCallback onExecute;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        zone.executed ? AppColors.statusSuccess : AppColors.accentBlue;

    final info = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            zone.countryCode,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${zone.raceName} — ${zone.stageOrLocation}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                zone.executed
                    ? '${zone.eventTier.displayNamePl} • ${zone.actualAttendance} kibiców • Zysk netto ${Formatters.formatCurrency(zone.netProfitEur)}'
                    : '${zone.eventTier.displayNamePl} • Koszt ${Formatters.formatCurrency(zone.setupCostEur)} • Boost x${zone.merchandiseBoostMultiplier.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final trailing = zone.executed
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.statusSuccess.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '+${zone.newFansGained} fanów',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.statusSuccess,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          )
        : _CardInteractiveButton(
            label: 'Realizuj Fan Zone',
            icon: Icons.play_arrow_rounded,
            isPrimary: true,
            enabled: enabled,
            onPressed: onExecute,
          );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 10),
                trailing,
              ],
            )
          : Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 12),
                trailing,
              ],
            ),
    );
  }
}

class _MiniLegendMetric extends StatelessWidget {
  const _MiniLegendMetric({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
