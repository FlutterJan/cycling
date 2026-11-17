import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../services/career/historic_legend_hall_of_fame_compare.dart';
import '../../services/career/historical_records_and_palmares_service.dart';

const Color _pyramidBorderColor = Color(0xFF2A2F3D);
const Duration _kTransitionDuration = Duration(milliseconds: 260);
const Curve _kTransitionCurve = Curves.easeOutCubic;

/// Filtr pochodzenia kolarzy w Piramidzie Legend Wszech Czasów.
enum GoatPyramidOriginFilter {
  all('Wszyscy'),
  historicLegends('Legendy Historyczne'),
  careerRiders('Kariera Aktywna');

  final String label;
  const GoatPyramidOriginFilter(this.label);
}

/// Wizualna, w pełni interaktywna 5-piętrowa Piramida Legend Wszech Czasów
/// (All-Time G.O.A.T. Pyramid) dla modułu Hall of Fame.
///
/// Prezentuje 5 poziomów chwały z [GoatTier] od szczytu (`immortalApex`)
/// do podstawy (`risingLegend`), wspierając filtrowanie po epoce, przełącznik
/// normalizacji epok, pełne stany `hover`/`active`/`focus`/`disabled` oraz
/// responsywne układy dla `390x844`, `1024x768` i `1600x900`.
class AllTimeGoatPyramidWidget extends StatefulWidget {
  /// Opcjonalna lista wpisów; gdy `null`, generowana jest z [compareService]
  /// oraz [careerRiders].
  final List<AllTimeHallOfFameLeaderboardEntry>? entries;

  /// Palmares aktywnych kolarzy z kariery gracza do połączenia z legendami.
  final List<RiderPalmares> careerRiders;

  /// Serwis obliczający punktację GOAT (domyślnie nowa instancja).
  final HistoricLegendHallOfFameCompareService? compareService;

  /// Początkowy stan normalizacji punktów względem epoki.
  final bool initialUseEraAdjustment;

  /// Zewnętrzne wywołanie przy zmianie trybu korekty epoki.
  final ValueChanged<bool>? onEraAdjustmentChanged;

  /// Callback po wybraniu kolarza z piramidy.
  final ValueChanged<AllTimeHallOfFameLeaderboardEntry>? onRiderSelected;

  /// Callback po wybraniu piętra piramidy.
  final ValueChanged<GoatTier>? onTierSelected;

  /// Identyfikator wstępnie podświetlonego kolarza.
  final String? initialSelectedRiderId;

  /// Czy widget jest aktywny (obsługuje stan `disabled`).
  final bool enabled;

  /// Rok bieżącej kariery używany przy wyliczaniu aktywnych kolarzy.
  final int careerCurrentYear;

  const AllTimeGoatPyramidWidget({
    super.key,
    this.entries,
    this.careerRiders = const [],
    this.compareService,
    this.initialUseEraAdjustment = true,
    this.onEraAdjustmentChanged,
    this.onRiderSelected,
    this.onTierSelected,
    this.initialSelectedRiderId,
    this.enabled = true,
    this.careerCurrentYear = 2026,
  });

  @override
  State<AllTimeGoatPyramidWidget> createState() =>
      _AllTimeGoatPyramidWidgetState();
}

class _AllTimeGoatPyramidWidgetState extends State<AllTimeGoatPyramidWidget> {
  late final HistoricLegendHallOfFameCompareService _service;
  late bool _useEraAdjustment;
  CyclingEra? _selectedEraFilter;
  GoatPyramidOriginFilter _originFilter = GoatPyramidOriginFilter.all;
  GoatTier? _selectedTier;
  String? _selectedRiderId;

  static const List<GoatTier> _pyramidTiersTopToBottom = [
    GoatTier.immortalApex,
    GoatTier.pantheonTitan,
    GoatTier.monumentalIcon,
    GoatTier.eraContender,
    GoatTier.risingLegend,
  ];

  @override
  void initState() {
    super.initState();
    _service =
        widget.compareService ?? const HistoricLegendHallOfFameCompareService();
    _useEraAdjustment = widget.initialUseEraAdjustment;
    _selectedRiderId = widget.initialSelectedRiderId;
  }

  @override
  void didUpdateWidget(covariant AllTimeGoatPyramidWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUseEraAdjustment != widget.initialUseEraAdjustment) {
      _useEraAdjustment = widget.initialUseEraAdjustment;
    }
    if (oldWidget.initialSelectedRiderId != widget.initialSelectedRiderId &&
        widget.initialSelectedRiderId != null) {
      _selectedRiderId = widget.initialSelectedRiderId;
    }
  }

  List<AllTimeHallOfFameLeaderboardEntry> _resolveEntries() {
    final baseList = widget.entries ??
        _service.buildMergedHallOfFame(
          careerRiders: widget.careerRiders,
          includeHistoricLegends: true,
          useEraAdjustment: _useEraAdjustment,
          careerCurrentYear: widget.careerCurrentYear,
        );

    return baseList.where((entry) {
      if (_selectedEraFilter != null && entry.era != _selectedEraFilter) {
        return false;
      }
      switch (_originFilter) {
        case GoatPyramidOriginFilter.all:
          return true;
        case GoatPyramidOriginFilter.historicLegends:
          return !entry.isCareerRider;
        case GoatPyramidOriginFilter.careerRiders:
          return entry.isCareerRider;
      }
    }).toList(growable: false);
  }

  Map<GoatTier, List<AllTimeHallOfFameLeaderboardEntry>> _groupByTier(
    List<AllTimeHallOfFameLeaderboardEntry> entries,
  ) {
    final grouped = <GoatTier, List<AllTimeHallOfFameLeaderboardEntry>>{
      for (final tier in _pyramidTiersTopToBottom) tier: [],
    };
    for (final entry in entries) {
      grouped[entry.breakdown.tier]!.add(entry);
    }
    return grouped;
  }

  AllTimeHallOfFameLeaderboardEntry? _resolveSelectedEntry(
    List<AllTimeHallOfFameLeaderboardEntry> entries,
  ) {
    if (entries.isEmpty) return null;
    if (_selectedRiderId != null) {
      for (final entry in entries) {
        if (entry.riderId == _selectedRiderId) return entry;
      }
    }
    if (_selectedTier != null) {
      for (final entry in entries) {
        if (entry.breakdown.tier == _selectedTier) return entry;
      }
    }
    return entries.first;
  }

  void _handleToggleEraAdjustment() {
    if (!widget.enabled) return;
    setState(() {
      _useEraAdjustment = !_useEraAdjustment;
    });
    widget.onEraAdjustmentChanged?.call(_useEraAdjustment);
  }

  void _handleSelectRider(AllTimeHallOfFameLeaderboardEntry entry) {
    if (!widget.enabled) return;
    setState(() {
      _selectedRiderId = entry.riderId;
      _selectedTier = entry.breakdown.tier;
    });
    widget.onRiderSelected?.call(entry);
  }

  void _handleSelectTier(
    GoatTier tier,
    List<AllTimeHallOfFameLeaderboardEntry> tierEntries,
  ) {
    if (!widget.enabled) return;
    setState(() {
      _selectedTier = tier;
      if (tierEntries.isNotEmpty &&
          !tierEntries.any((e) => e.riderId == _selectedRiderId)) {
        _selectedRiderId = tierEntries.first.riderId;
      }
    });
    widget.onTierSelected?.call(tier);
  }

  void _handleResetFilters() {
    if (!widget.enabled) return;
    setState(() {
      _selectedEraFilter = null;
      _originFilter = GoatPyramidOriginFilter.all;
      _selectedTier = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _resolveEntries();
    final grouped = _groupByTier(entries);
    final selectedEntry = _resolveSelectedEntry(entries);

    return AnimatedOpacity(
      duration: _kTransitionDuration,
      curve: _kTransitionCurve,
      opacity: widget.enabled ? 1.0 : 0.48,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _pyramidBorderColor, width: 1.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 640;
            final isDesktopWide = width >= 1120;

            return Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isMobile: isMobile, entries: entries),
                  const SizedBox(height: 14),
                  _buildFilterBar(isMobile: isMobile),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    _buildEmptyState()
                  else if (isDesktopWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _buildPyramidStack(
                            grouped: grouped,
                            selectedEntry: selectedEntry,
                            isMobile: false,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: selectedEntry != null
                              ? _LegendInspectorCard(
                                  entry: selectedEntry,
                                  useEraAdjustment: _useEraAdjustment,
                                  enabled: widget.enabled,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPyramidStack(
                          grouped: grouped,
                          selectedEntry: selectedEntry,
                          isMobile: isMobile,
                        ),
                        if (selectedEntry != null) ...[
                          const SizedBox(height: 16),
                          _LegendInspectorCard(
                            entry: selectedEntry,
                            useEraAdjustment: _useEraAdjustment,
                            enabled: widget.enabled,
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isMobile,
    required List<AllTimeHallOfFameLeaderboardEntry> entries,
  }) {
    final apexCount = entries
        .where((e) => e.breakdown.tier == GoatTier.immortalApex)
        .length;
    final careerCount = entries.where((e) => e.isCareerRider).length;
    final topScore = entries.isEmpty ? 0 : entries.first.effectiveScore;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Piramida Legend Wszech Czasów',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 16 : 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '5-piętrowy Panteon Hall of Fame • All-Time G.O.A.T. Score',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isMobile ? 12 : 13,
            color: AppColors.textSecondary,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );

    final kpiStrip = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _HeaderKpiPill(
          label: 'Legendy',
          value: '${entries.length}',
          accent: AppColors.textPrimary,
        ),
        _HeaderKpiPill(
          label: 'Szczyt',
          value: '$apexCount',
          accent: AppColors.goldAccent,
        ),
        _HeaderKpiPill(
          label: 'Kariera',
          value: '$careerCount',
          accent: AppColors.cyanAccent,
        ),
        _HeaderKpiPill(
          label: 'Rekord',
          value: _formatScore(topScore),
          accent: AppColors.statusSuccess,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          kpiStrip,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        kpiStrip,
      ],
    );
  }

  Widget _buildFilterBar({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pyramidBorderColor, width: 1),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _InteractiveFilterChip(
            label: 'Wszystkie epoki',
            selected: _selectedEraFilter == null,
            accentColor: AppColors.goldAccent,
            enabled: widget.enabled,
            onTap: () {
              setState(() => _selectedEraFilter = null);
            },
          ),
          for (final era in CyclingEra.values)
            _InteractiveFilterChip(
              label: era.shortLabel,
              selected: _selectedEraFilter == era,
              accentColor: AppColors.accentBlue,
              enabled: widget.enabled,
              onTap: () {
                setState(() {
                  _selectedEraFilter =
                      _selectedEraFilter == era ? null : era;
                });
              },
            ),
          Container(
            width: 1,
            height: 22,
            color: _pyramidBorderColor,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          for (final origin in GoatPyramidOriginFilter.values)
            _InteractiveFilterChip(
              label: origin.label,
              selected: _originFilter == origin,
              accentColor: AppColors.primaryAccent,
              enabled: widget.enabled,
              onTap: () {
                setState(() => _originFilter = origin);
              },
            ),
          _InteractiveFilterChip(
            label: _useEraAdjustment
                ? 'Korekta Epoki: WŁ.'
                : 'Korekta Epoki: WYŁ.',
            selected: _useEraAdjustment,
            accentColor: AppColors.cyanAccent,
            enabled: widget.enabled,
            leadingIcon: Icons.tune_rounded,
            onTap: _handleToggleEraAdjustment,
          ),
        ],
      ),
    );
  }

  Widget _buildPyramidStack({
    required Map<GoatTier, List<AllTimeHallOfFameLeaderboardEntry>> grouped,
    required AllTimeHallOfFameLeaderboardEntry? selectedEntry,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pyramidBorderColor, width: 1),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _GoatPyramidBackdropPainter(
                tiers: _pyramidTiersTopToBottom,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _pyramidTiersTopToBottom.length; i++) ...[
                _buildTierRow(
                  tier: _pyramidTiersTopToBottom[i],
                  tierEntries: grouped[_pyramidTiersTopToBottom[i]] ?? const [],
                  selectedEntry: selectedEntry,
                  isMobile: isMobile,
                ),
                if (i < _pyramidTiersTopToBottom.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow({
    required GoatTier tier,
    required List<AllTimeHallOfFameLeaderboardEntry> tierEntries,
    required AllTimeHallOfFameLeaderboardEntry? selectedEntry,
    required bool isMobile,
  }) {
    final widthFactor = _tierWidthFactor(tier, isMobile: isMobile);
    final isTierSelected = _selectedTier == tier ||
        (selectedEntry != null && selectedEntry.breakdown.tier == tier);

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: _PyramidTierBand(
          tier: tier,
          entries: tierEntries,
          selectedRiderId: selectedEntry?.riderId,
          isTierSelected: isTierSelected,
          isMobile: isMobile,
          enabled: widget.enabled,
          onTierTap: () => _handleSelectTier(tier, tierEntries),
          onRiderTap: _handleSelectRider,
        ),
      ),
    );
  }

  double _tierWidthFactor(GoatTier tier, {required bool isMobile}) {
    if (isMobile) {
      switch (tier) {
        case GoatTier.immortalApex:
          return 0.80;
        case GoatTier.pantheonTitan:
          return 0.85;
        case GoatTier.monumentalIcon:
          return 0.90;
        case GoatTier.eraContender:
          return 0.95;
        case GoatTier.risingLegend:
          return 1.00;
      }
    }
    switch (tier) {
      case GoatTier.immortalApex:
        return 0.56;
      case GoatTier.pantheonTitan:
        return 0.67;
      case GoatTier.monumentalIcon:
        return 0.78;
      case GoatTier.eraContender:
        return 0.89;
      case GoatTier.risingLegend:
        return 1.00;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pyramidBorderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: AppColors.textSecondary,
            size: 36,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak legend spełniających wybrane kryteria',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Zmień filtr epoki lub pochodzenia, aby wyświetlić piętra Piramidy Hall of Fame.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          _InteractiveActionButton(
            label: 'Resetuj filtry',
            icon: Icons.refresh_rounded,
            accentColor: AppColors.goldAccent,
            enabled: widget.enabled,
            onPressed: _handleResetFilters,
          ),
        ],
      ),
    );
  }
}

class _PyramidTierBand extends StatefulWidget {
  final GoatTier tier;
  final List<AllTimeHallOfFameLeaderboardEntry> entries;
  final String? selectedRiderId;
  final bool isTierSelected;
  final bool isMobile;
  final bool enabled;
  final VoidCallback onTierTap;
  final ValueChanged<AllTimeHallOfFameLeaderboardEntry> onRiderTap;

  const _PyramidTierBand({
    required this.tier,
    required this.entries,
    required this.selectedRiderId,
    required this.isTierSelected,
    required this.isMobile,
    required this.enabled,
    required this.onTierTap,
    required this.onRiderTap,
  });

  @override
  State<_PyramidTierBand> createState() => _PyramidTierBandState();
}

class _PyramidTierBandState extends State<_PyramidTierBand> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.tier.accentColor;
    final activeBorder = widget.isTierSelected || _focused
        ? accent
        : (_hovered
            ? accent.withValues(alpha: 0.72)
            : _pyramidBorderColor);

    final bgColor = _pressed
        ? AppColors.surfaceLight
        : (_hovered || widget.isTierSelected
            ? Color.alphaBlend(
                accent.withValues(alpha: 0.11),
                AppColors.surface,
              )
            : AppColors.surface);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onTierTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTierTap : null,
        child: AnimatedContainer(
          duration: _kTransitionDuration,
          curve: _kTransitionCurve,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 10 : 14,
            vertical: widget.isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activeBorder,
              width: widget.isTierSelected || _focused ? 1.5 : 1.0,
            ),
            boxShadow: widget.tier == GoatTier.immortalApex && widget.enabled
                ? [
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.14),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _TierRomanBadge(tier: widget.tier),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.tier.displayName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: widget.isMobile ? 12.5 : 13.5,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.tier.englishName} • ≥ ${_formatScore(widget.tier.minScore)} pkt',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _pyramidBorderColor, width: 1),
                    ),
                    child: Text(
                      '${widget.entries.length}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: widget.entries.isEmpty
                            ? AppColors.textSecondary
                            : accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.entries.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _pyramidBorderColor, width: 1),
                  ),
                  child: const Text(
                    'Piętro oczekuje na kolejną legendę peletonu',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in widget.entries)
                      _PyramidRiderMedallion(
                        entry: entry,
                        tierAccent: accent,
                        selected: entry.riderId == widget.selectedRiderId,
                        enabled: widget.enabled,
                        onTap: () => widget.onRiderTap(entry),
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

class _PyramidRiderMedallion extends StatefulWidget {
  final AllTimeHallOfFameLeaderboardEntry entry;
  final Color tierAccent;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PyramidRiderMedallion({
    required this.entry,
    required this.tierAccent,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PyramidRiderMedallion> createState() => _PyramidRiderMedallionState();
}

class _PyramidRiderMedallionState extends State<_PyramidRiderMedallion> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isTopOne = widget.entry.rank == 1;
    final highlightColor = isTopOne ? AppColors.goldAccent : widget.tierAccent;
    final borderColor = widget.selected || _focused
        ? highlightColor
        : (_hovered
            ? highlightColor.withValues(alpha: 0.75)
            : _pyramidBorderColor);

    final bgColor = _pressed
        ? AppColors.surface
        : (widget.selected
            ? Color.alphaBlend(
                highlightColor.withValues(alpha: 0.20),
                AppColors.surfaceLight,
              )
            : (_hovered
                ? Color.alphaBlend(
                    highlightColor.withValues(alpha: 0.10),
                    AppColors.surfaceLight,
                  )
                : AppColors.surfaceLight));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
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
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.selected || _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#${widget.entry.rank}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: highlightColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _pyramidBorderColor, width: 0.8),
                  ),
                  child: Text(
                    widget.entry.nationalityIso,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.entry.riderName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatScore(widget.entry.effectiveScore),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: highlightColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (widget.entry.breakdown.hasTripleCrownSameYear) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: AppColors.goldAccent,
                  ),
                ] else if (widget.entry.isCareerRider) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.cyanAccent,
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

class _LegendInspectorCard extends StatelessWidget {
  final AllTimeHallOfFameLeaderboardEntry entry;
  final bool useEraAdjustment;
  final bool enabled;

  const _LegendInspectorCard({
    required this.entry,
    required this.useEraAdjustment,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final b = entry.breakdown;
    final tier = b.tier;
    final nextTier = tier.nextTier;
    final currentScore = entry.effectiveScore;

    double progressToNext = 1.0;
    int pointsMissing = 0;
    if (nextTier != null) {
      final span = (nextTier.minScore - tier.minScore).clamp(1, 100000);
      final gained = (currentScore - tier.minScore).clamp(0, span);
      progressToNext = (gained / span).clamp(0.0, 1.0);
      pointsMissing = (nextTier.minScore - currentScore).clamp(0, 100000);
    }

    final categories = <({String label, int value, int maxRef, Color color})>[
      (
        label: 'Grand Tour GC',
        value: b.grandTourGcScore,
        maxRef: 9000,
        color: AppColors.goldAccent,
      ),
      (
        label: 'Monumenty i Klasyki',
        value: b.monumentAndClassicScore,
        maxRef: 8000,
        color: AppColors.primaryAccent,
      ),
      (
        label: 'MŚ i Igrzyska',
        value: b.championshipAndOlympicScore,
        maxRef: 3000,
        color: AppColors.cyanAccent,
      ),
      (
        label: 'Etapy i Koszulki',
        value: b.stageAndJerseyScore,
        maxRef: 5000,
        color: AppColors.accentBlue,
      ),
      (
        label: 'Długowieczność i Dominacja',
        value: b.longevityAndDominanceScore,
        maxRef: 3000,
        color: AppColors.statusSuccess,
      ),
      (
        label: 'Bonusy Historyczne',
        value: b.milestoneBonusScore,
        maxRef: 3000,
        color: AppColors.amberWarning,
      ),
    ];

    return AnimatedContainer(
      duration: _kTransitionDuration,
      curve: _kTransitionCurve,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tier.accentColor.withValues(alpha: 0.55),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _TierRomanBadge(tier: tier),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '„${entry.nickname}” • ${entry.nationalityIso} • ${entry.era.shortLabel}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatScore(currentScore),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: tier.accentColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    useEraAdjustment ? 'Korekta epoki' : 'Wynik surowy',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _pyramidBorderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.specialty,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: tier.accentColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.signatureAchievement,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final cat in categories) ...[
            _CategoryScoreBar(
              label: cat.label,
              value: cat.value,
              maxRef: cat.maxRef,
              color: cat.color,
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _pyramidBorderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        nextTier == null
                            ? 'Absolutny Szczyt Panteonu'
                            : 'Awans do: ${nextTier.displayName}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nextTier == null
                          ? 'MAX TIER'
                          : '-${_formatScore(pointsMissing)} pkt',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: nextTier == null
                            ? AppColors.goldAccent
                            : AppColors.accentBlue,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressToNext,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      nextTier?.accentColor ?? AppColors.goldAccent,
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

class _CategoryScoreBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxRef;
  final Color color;

  const _CategoryScoreBar({
    required this.label,
    required this.value,
    required this.maxRef,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (value / maxRef).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatScore(value),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _TierRomanBadge extends StatelessWidget {
  final GoatTier tier;

  const _TierRomanBadge({required this.tier});

  String get _romanNumeral {
    switch (tier.level) {
      case 5:
        return 'V';
      case 4:
        return 'IV';
      case 3:
        return 'III';
      case 2:
        return 'II';
      default:
        return 'I';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tier.accentColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tier.accentColor.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Text(
        _romanNumeral,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: tier.accentColor,
        ),
      ),
    );
  }
}

class _HeaderKpiPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _HeaderKpiPill({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _pyramidBorderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final bool enabled;
  final IconData? leadingIcon;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.enabled,
    required this.onTap,
    this.leadingIcon,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = _pressed
        ? AppColors.surfaceLight
        : (widget.selected
            ? widget.accentColor.withValues(alpha: 0.20)
            : (_hovered ? AppColors.surfaceLight : AppColors.surface));
    final border = widget.selected || _focused
        ? widget.accentColor
        : (_hovered
            ? widget.accentColor.withValues(alpha: 0.65)
            : _pyramidBorderColor);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
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
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
                width: widget.selected || _focused ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leadingIcon != null) ...[
                  Icon(
                    widget.leadingIcon,
                    size: 14,
                    color: widget.selected
                        ? widget.accentColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.selected
                        ? AppColors.textPrimary
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

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
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
    final bg = _pressed
        ? widget.accentColor.withValues(alpha: 0.30)
        : (_hovered
            ? widget.accentColor.withValues(alpha: 0.22)
            : widget.accentColor.withValues(alpha: 0.14));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.textPrimary
                    : widget.accentColor.withValues(alpha: 0.7),
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: widget.accentColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
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

class _GoatPyramidBackdropPainter extends CustomPainter {
  final List<GoatTier> tiers;

  const _GoatPyramidBackdropPainter({required this.tiers});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final centerX = size.width / 2;
    final topWidth = size.width * 0.24;
    final bottomWidth = size.width * 0.96;

    final pyramidPath = Path()
      ..moveTo(centerX - topWidth / 2, 0)
      ..lineTo(centerX + topWidth / 2, 0)
      ..lineTo(centerX + bottomWidth / 2, size.height)
      ..lineTo(centerX - bottomWidth / 2, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.08),
          AppColors.cyanAccent.withValues(alpha: 0.04),
          AppColors.primaryAccent.withValues(alpha: 0.04),
          AppColors.accentBlue.withValues(alpha: 0.03),
          AppColors.statusSuccess.withValues(alpha: 0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(pyramidPath, fillPaint);

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.goldAccent.withValues(alpha: 0.18);
    canvas.drawPath(pyramidPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _GoatPyramidBackdropPainter oldDelegate) {
    return oldDelegate.tiers != tiers;
  }
}

String _formatScore(int value) {
  final abs = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < abs.length; i++) {
    if (i > 0 && (abs.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(abs[i]);
  }
  return value < 0 ? '-${buffer.toString()}' : buffer.toString();
}
