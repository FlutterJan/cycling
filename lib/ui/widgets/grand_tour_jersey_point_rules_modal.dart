import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/race/race_stage.dart';

/// Identyfikator wyścigu Grand Tour dla prezentacji zasad koszulek i punktacji.
enum GrandTourRuleEdition {
  tourDeFrance,
  giroDItalia,
  vueltaAEspana,
}

/// Zakładki modalnego okna zasad punktacji Grand Tour.
enum GrandTourRulesTab {
  pointsClassification,
  komClassification,
  timeBonuses,
  timeLimitOtl,
}

/// Definicja nazw koszulek i akcentów dla danego Wielkiego Touru.
class GrandTourJerseyTheme {
  final GrandTourRuleEdition edition;
  final String raceName;
  final String organizerBadge;
  final String gcJerseyName;
  final Color gcJerseyColor;
  final String pointsJerseyName;
  final Color pointsJerseyColor;
  final String komJerseyName;
  final Color komJerseyColor;
  final String youthJerseyName;
  final Color youthJerseyColor;

  const GrandTourJerseyTheme({
    required this.edition,
    required this.raceName,
    required this.organizerBadge,
    required this.gcJerseyName,
    required this.gcJerseyColor,
    required this.pointsJerseyName,
    required this.pointsJerseyColor,
    required this.komJerseyName,
    required this.komJerseyColor,
    required this.youthJerseyName,
    required this.youthJerseyColor,
  });

  static const List<GrandTourJerseyTheme> presets = [
    GrandTourJerseyTheme(
      edition: GrandTourRuleEdition.tourDeFrance,
      raceName: 'Tour de France',
      organizerBadge: 'ASO • 21 ETAPÓW',
      gcJerseyName: 'Maillot Jaune (GC)',
      gcJerseyColor: Color(0xFFFACC15),
      pointsJerseyName: 'Maillot Vert (Punkty)',
      pointsJerseyColor: AppColors.emeraldGreen,
      komJerseyName: 'Maillot à Pois (Góry)',
      komJerseyColor: AppColors.crimsonAlert,
      youthJerseyName: 'Maillot Blanc (U25)',
      youthJerseyColor: Color(0xFFF3F4F6),
    ),
    GrandTourJerseyTheme(
      edition: GrandTourRuleEdition.giroDItalia,
      raceName: "Giro d'Italia",
      organizerBadge: 'RCS • 21 ETAPÓW',
      gcJerseyName: 'Maglia Rosa (GC)',
      gcJerseyColor: Color(0xFFF472B6),
      pointsJerseyName: 'Maglia Ciclamino (Punkty)',
      pointsJerseyColor: Color(0xFFC026D3),
      komJerseyName: 'Maglia Azzurra (Góry)',
      komJerseyColor: AppColors.accentBlue,
      youthJerseyName: 'Maglia Bianca (U25)',
      youthJerseyColor: Color(0xFFF3F4F6),
    ),
    GrandTourJerseyTheme(
      edition: GrandTourRuleEdition.vueltaAEspana,
      raceName: 'Vuelta a España',
      organizerBadge: 'UNIPUBLIC • 21 ETAPÓW',
      gcJerseyName: 'La Roja (GC)',
      gcJerseyColor: AppColors.crimsonAlert,
      pointsJerseyName: 'Maillot Verde (Punkty)',
      pointsJerseyColor: AppColors.emeraldGreen,
      komJerseyName: 'Maillot de Lunares (Góry)',
      komJerseyColor: Color(0xFF38BDF8),
      youthJerseyName: 'Maillot Blanco (U25)',
      youthJerseyColor: Color(0xFFF3F4F6),
    ),
  ];

  static GrandTourJerseyTheme forEdition(GrandTourRuleEdition edition) {
    return presets.firstWhere(
      (item) => item.edition == edition,
      orElse: () => presets.first,
    );
  }
}

/// Wiersz tabeli punktacji etapowej lub górskiej.
class GrandTourPointScaleRow {
  final String categoryLabel;
  final String subtitle;
  final Color accentColor;
  final List<int> pointsByRank;
  final bool isHighlighted;

  const GrandTourPointScaleRow({
    required this.categoryLabel,
    required this.subtitle,
    required this.accentColor,
    required this.pointsByRank,
    this.isHighlighted = false,
  });
}

/// Wynik kalkulatora limitu czasu OTL zgodny z `StageResultsCalculator`.
class OtlCalculationPreview {
  final double winnerSpeedKmh;
  final double distanceKm;
  final double winnerTimeSeconds;
  final double timeCutPercent;
  final double maxGapSeconds;
  final double totalCutoffSeconds;

  const OtlCalculationPreview({
    required this.winnerSpeedKmh,
    required this.distanceKm,
    required this.winnerTimeSeconds,
    required this.timeCutPercent,
    required this.maxGapSeconds,
    required this.totalCutoffSeconds,
  });
}

/// Kalkulator reguł punktacji, bonifikat i limitu czasu OTL dla Grand Tourów.
class GrandTourPointRulesCatalog {
  GrandTourPointRulesCatalog._();

  static const List<int> flatStagePoints = [
    50, 30, 20, 18, 16, 14, 12, 10, 8, 7, 6, 5, 4, 3, 2,
  ];

  static const List<int> hillyStagePoints = [
    30, 25, 22, 19, 17, 15, 13, 11, 9, 7, 6, 5, 4, 3, 2,
  ];

  static const List<int> mountainAndTtStagePoints = [
    20, 17, 15, 13, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
  ];

  static const List<int> intermediateSprintPoints = [
    20, 17, 15, 13, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
  ];

  static const List<int> komHcSummitPoints = [40, 30, 24, 20, 16, 12, 8, 4];
  static const List<int> komHcPassPoints = [20, 15, 12, 10, 8, 6, 4, 2];
  static const List<int> komCat1Points = [20, 16, 12, 8, 4, 2];
  static const List<int> komCat2Points = [10, 6, 4, 2];
  static const List<int> komCat3Points = [4, 2];
  static const List<int> komCat4Points = [2];

  static const List<int> stageFinishBonusSeconds = [10, 6, 4];
  static const List<int> bonusSprintSeconds = [8, 5, 2];

  /// Zwraca procent limitu czasu OTL identyczny z silnikiem `StageResultsCalculator`.
  static double calculateTimeCutPercent({
    required StageType stageType,
    required double winnerSpeedKmh,
  }) {
    if (winnerSpeedKmh <= 0) return 12.0;

    switch (stageType) {
      case StageType.flat:
        if (winnerSpeedKmh > 48.0) return 11.0;
        if (winnerSpeedKmh > 44.0) return 9.0;
        return 6.0;
      case StageType.cobbleClassic:
      case StageType.hilly:
        if (winnerSpeedKmh > 42.0) return 14.0;
        if (winnerSpeedKmh > 38.0) return 12.0;
        return 10.0;
      case StageType.highMountain:
      case StageType.summitFinish:
        if (winnerSpeedKmh > 38.0) return 18.0;
        if (winnerSpeedKmh > 34.0) return 16.0;
        return 13.0;
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        return 25.0;
    }
  }

  /// Wylicza podgląd limitu czasu OTL dla zadanych parametrów etapu.
  static OtlCalculationPreview computeOtlPreview({
    required StageType stageType,
    required double distanceKm,
    required double winnerSpeedKmh,
  }) {
    final double safeDistance = distanceKm.clamp(10.0, 280.0);
    final double safeSpeed = winnerSpeedKmh.clamp(22.0, 58.0);
    final double winnerTimeSeconds = (safeDistance / safeSpeed) * 3600.0;
    final double percent = calculateTimeCutPercent(
      stageType: stageType,
      winnerSpeedKmh: safeSpeed,
    );
    final double maxGapSeconds = winnerTimeSeconds * (percent / 100.0);
    return OtlCalculationPreview(
      winnerSpeedKmh: safeSpeed,
      distanceKm: safeDistance,
      winnerTimeSeconds: winnerTimeSeconds,
      timeCutPercent: percent,
      maxGapSeconds: maxGapSeconds,
      totalCutoffSeconds: winnerTimeSeconds + maxGapSeconds,
    );
  }

  static String formatDurationHms(double totalSeconds) {
    final int rounded = totalSeconds.round().clamp(0, 86400 * 2);
    final int h = rounded ~/ 3600;
    final int m = (rounded % 3600) ~/ 60;
    final int s = rounded % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// Przejrzyste okno modalne zasad punktacji, bonifikat czasowych i limitu OTL wyścigu Grand Tour.
class GrandTourJerseyPointRulesModal extends StatefulWidget {
  final GrandTourRuleEdition initialEdition;
  final GrandTourRulesTab initialTab;
  final StageType? highlightedStageType;
  final VoidCallback? onClose;

  const GrandTourJerseyPointRulesModal({
    super.key,
    this.initialEdition = GrandTourRuleEdition.tourDeFrance,
    this.initialTab = GrandTourRulesTab.pointsClassification,
    this.highlightedStageType,
    this.onClose,
  });

  /// Otwiera modal jako okno dialogowe dopasowane do ekranu.
  static Future<void> show(
    BuildContext context, {
    GrandTourRuleEdition initialEdition = GrandTourRuleEdition.tourDeFrance,
    GrandTourRulesTab initialTab = GrandTourRulesTab.pointsClassification,
    StageType? highlightedStageType,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 780),
            child: GrandTourJerseyPointRulesModal(
              initialEdition: initialEdition,
              initialTab: initialTab,
              highlightedStageType: highlightedStageType,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  @override
  State<GrandTourJerseyPointRulesModal> createState() =>
      _GrandTourJerseyPointRulesModalState();
}

class _GrandTourJerseyPointRulesModalState
    extends State<GrandTourJerseyPointRulesModal> {
  late GrandTourRuleEdition _selectedEdition;
  late GrandTourRulesTab _selectedTab;
  late StageType _otlStageType;
  double _otlDistanceKm = 185.0;
  double _otlWinnerSpeedKmh = 43.5;

  @override
  void initState() {
    super.initState();
    _selectedEdition = widget.initialEdition;
    _selectedTab = widget.initialTab;
    _otlStageType = widget.highlightedStageType ?? StageType.highMountain;
    if (_otlStageType == StageType.individualTimeTrial ||
        _otlStageType == StageType.teamTimeTrial) {
      _otlDistanceKm = 38.0;
      _otlWinnerSpeedKmh = 51.0;
    } else if (_otlStageType == StageType.flat) {
      _otlDistanceKm = 195.0;
      _otlWinnerSpeedKmh = 46.0;
    }
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final GrandTourJerseyTheme theme =
        GrandTourJerseyTheme.forEdition(_selectedEdition);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handleClose,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompact = constraints.maxWidth < 600;
            final bool isWide = constraints.maxWidth >= 900;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(theme: theme, isCompact: isCompact),
                  _buildEditionAndTabBar(theme: theme, isCompact: isCompact),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: SingleChildScrollView(
                        key: ValueKey('${_selectedEdition.name}_${_selectedTab.name}'),
                        padding: EdgeInsets.all(isCompact ? 14 : 20),
                        child: _buildActiveTabContent(
                          theme: theme,
                          isCompact: isCompact,
                          isWide: isWide,
                        ),
                      ),
                    ),
                  ),
                  _buildFooter(theme: theme, isCompact: isCompact),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required GrandTourJerseyTheme theme,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 38 : 44,
            height: isCompact ? 38 : 44,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
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
                    Text(
                      'Regulamin Punktacji & OTL',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                        fontSize: isCompact ? 16 : 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryAccent.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        theme.organizerBadge,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${theme.raceName} — Oficjalne tabele punktów UCI, bonifikaty czasowe i wzór limitu czasu',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _InteractiveActionButton(
            tooltip: 'Zamknij (Esc)',
            onPressed: _handleClose,
            icon: Icons.close_rounded,
            isCompact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEditionAndTabBar({
    required GrandTourJerseyTheme theme,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GrandTourJerseyTheme.presets.map((preset) {
                final bool isSelected = preset.edition == _selectedEdition;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _InteractiveFilterPill(
                    label: preset.raceName,
                    leadingColor: preset.gcJerseyColor,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedEdition = preset.edition);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton(
                  tab: GrandTourRulesTab.pointsClassification,
                  icon: Icons.flash_on_rounded,
                  label: 'Punktacja Etapowa',
                  accent: theme.pointsJerseyColor,
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  tab: GrandTourRulesTab.komClassification,
                  icon: Icons.terrain_rounded,
                  label: 'Klasyfikacja Górska',
                  accent: theme.komJerseyColor,
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  tab: GrandTourRulesTab.timeBonuses,
                  icon: Icons.timer_outlined,
                  label: 'Bonifikaty Czasowe',
                  accent: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  tab: GrandTourRulesTab.timeLimitOtl,
                  icon: Icons.calculate_outlined,
                  label: 'Limit Czasu (OTL)',
                  accent: AppColors.accentBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required GrandTourRulesTab tab,
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    final bool isSelected = _selectedTab == tab;
    return _InteractiveFilterPill(
      label: label,
      icon: icon,
      accentColor: accent,
      isSelected: isSelected,
      onTap: () => setState(() => _selectedTab = tab),
    );
  }

  Widget _buildActiveTabContent({
    required GrandTourJerseyTheme theme,
    required bool isCompact,
    required bool isWide,
  }) {
    switch (_selectedTab) {
      case GrandTourRulesTab.pointsClassification:
        return _buildPointsClassificationTab(
          theme: theme,
          isCompact: isCompact,
        );
      case GrandTourRulesTab.komClassification:
        return _buildKomClassificationTab(
          theme: theme,
          isCompact: isCompact,
        );
      case GrandTourRulesTab.timeBonuses:
        return _buildTimeBonusesTab(
          theme: theme,
          isCompact: isCompact,
          isWide: isWide,
        );
      case GrandTourRulesTab.timeLimitOtl:
        return _buildTimeLimitOtlTab(
          isCompact: isCompact,
          isWide: isWide,
        );
    }
  }

  Widget _buildPointsClassificationTab({
    required GrandTourJerseyTheme theme,
    required bool isCompact,
  }) {
    final StageType? activeType = widget.highlightedStageType;
    final List<GrandTourPointScaleRow> rows = [
      GrandTourPointScaleRow(
        categoryLabel: 'Etap Płaski (Sprinterski)',
        subtitle: 'Współczynnik 1 — finisz peletonu (Top 15)',
        accentColor: theme.pointsJerseyColor,
        pointsByRank: GrandTourPointRulesCatalog.flatStagePoints,
        isHighlighted: activeType == StageType.flat,
      ),
      GrandTourPointScaleRow(
        categoryLabel: 'Etap Pagórkowaty / Bruk',
        subtitle: 'Współczynnik 2 — trudne końcówki i klasyki (Top 15)',
        accentColor: AppColors.amberWarning,
        pointsByRank: GrandTourPointRulesCatalog.hillyStagePoints,
        isHighlighted:
            activeType == StageType.hilly || activeType == StageType.cobbleClassic,
      ),
      GrandTourPointScaleRow(
        categoryLabel: 'Etap Górski / Szczyt / ITT',
        subtitle: 'Współczynnik 3 — wysokie góry i jazda na czas (Top 15)',
        accentColor: AppColors.crimsonAlert,
        pointsByRank: GrandTourPointRulesCatalog.mountainAndTtStagePoints,
        isHighlighted: activeType == StageType.highMountain ||
            activeType == StageType.summitFinish ||
            activeType == StageType.individualTimeTrial ||
            activeType == StageType.teamTimeTrial,
      ),
      const GrandTourPointScaleRow(
        categoryLabel: 'Premia Lotna (Sprint Pośredni)',
        subtitle: 'Każdy etap ze startu wspólnego (Top 15)',
        accentColor: AppColors.accentBlue,
        pointsByRank: GrandTourPointRulesCatalog.intermediateSprintPoints,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildJerseyStrip(theme: theme, isCompact: isCompact),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Tabela Punktów — ${theme.pointsJerseyName}',
          subtitle:
              'Punkty przyznawane na mecie etapu w zależności od profilu trasy oraz na premii lotnej.',
          accentColor: theme.pointsJerseyColor,
          child: _buildPointsMatrixTable(
            rows: rows,
            maxColumns: 15,
            isCompact: isCompact,
          ),
        ),
        const SizedBox(height: 14),
        _buildInfoBanner(
          icon: Icons.info_outline_rounded,
          color: theme.pointsJerseyColor,
          text:
              'W przypadku remisu punktowego o kolejności w klasyfikacji decyduje: '
              '(1) liczba zwycięstw etapowych, (2) liczba wygranych premii lotnych, (3) wyższa pozycja w klasyfikacji generalnej GC.',
        ),
      ],
    );
  }

  Widget _buildKomClassificationTab({
    required GrandTourJerseyTheme theme,
    required bool isCompact,
  }) {
    final List<GrandTourPointScaleRow> komRows = [
      GrandTourPointScaleRow(
        categoryLabel: 'HC — Finisz na Szczycie (x2)',
        subtitle: 'Podwójna punktacja na mecie szczytowej Hors Catégorie',
        accentColor: AppColors.goldAccent,
        pointsByRank: GrandTourPointRulesCatalog.komHcSummitPoints,
        isHighlighted: widget.highlightedStageType == StageType.summitFinish,
      ),
      GrandTourPointScaleRow(
        categoryLabel: 'Hors Catégorie (HC)',
        subtitle: 'Przełęcz najwyższej kategorii na trasie etapu',
        accentColor: theme.komJerseyColor,
        pointsByRank: GrandTourPointRulesCatalog.komHcPassPoints,
      ),
      const GrandTourPointScaleRow(
        categoryLabel: '1. Kategoria (Cat 1)',
        subtitle: 'Trudne podjazdy alpejskie i pirenejskie (Top 6)',
        accentColor: AppColors.amberWarning,
        pointsByRank: GrandTourPointRulesCatalog.komCat1Points,
      ),
      const GrandTourPointScaleRow(
        categoryLabel: '2. Kategoria (Cat 2)',
        subtitle: 'Średnie góry i długie wspinaczki (Top 4)',
        accentColor: AppColors.accentBlue,
        pointsByRank: GrandTourPointRulesCatalog.komCat2Points,
      ),
      const GrandTourPointScaleRow(
        categoryLabel: '3. Kategoria (Cat 3)',
        subtitle: 'Krótsze podjazdy selektywne (Top 2)',
        accentColor: AppColors.emeraldGreen,
        pointsByRank: GrandTourPointRulesCatalog.komCat3Points,
      ),
      const GrandTourPointScaleRow(
        categoryLabel: '4. Kategoria (Cat 4)',
        subtitle: 'Krótkie premie górskie — punktuje tylko 1. kolarz',
        accentColor: AppColors.textSecondary,
        pointsByRank: GrandTourPointRulesCatalog.komCat4Points,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          title: 'Tabela Punktów — ${theme.komJerseyName}',
          subtitle:
              'Punktacja na szczytach premii górskich Cat 4 – HC zgodnie z silnikiem symulacji.',
          accentColor: theme.komJerseyColor,
          child: _buildPointsMatrixTable(
            rows: komRows,
            maxColumns: 8,
            isCompact: isCompact,
          ),
        ),
        const SizedBox(height: 14),
        _buildInfoBanner(
          icon: Icons.landscape_rounded,
          color: AppColors.goldAccent,
          text:
              'Premia na mecie szczytowej Hors Catégorie (np. Alpe d\'Huez, Col du Tourmalet, Angliru) '
              'przyznaje podwójne punkty (40-30-24-20-16-12-8-4 pkt) i może zadecydować o losach koszulki.',
        ),
      ],
    );
  }

  Widget _buildTimeBonusesTab({
    required GrandTourJerseyTheme theme,
    required bool isCompact,
    required bool isWide,
  }) {
    final Widget finishBonusCard = _buildSectionCard(
      title: 'Bonifikaty na Mecie Etapu',
      subtitle: 'Wszystkie etapy ze startu wspólnego (z wyłączeniem ITT / TTT)',
      accentColor: AppColors.goldAccent,
      child: _buildBonusPodiumList(
        secondsList: GrandTourPointRulesCatalog.stageFinishBonusSeconds,
        accentColor: AppColors.goldAccent,
        badgeLabel: 'META ETAPU',
      ),
    );

    final Widget sprintBonusCard = _buildSectionCard(
      title: 'Bonifikaty na Premii Bonusowej',
      subtitle: 'Wyznaczone przełęcze lub punkty Point Bonus przed finałem',
      accentColor: AppColors.cyanAccent,
      child: _buildBonusPodiumList(
        secondsList: GrandTourPointRulesCatalog.bonusSprintSeconds,
        accentColor: AppColors.cyanAccent,
        badgeLabel: 'PREMIA BONUSOWA',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: finishBonusCard),
              const SizedBox(width: 14),
              Expanded(child: sprintBonusCard),
            ],
          )
        else ...[
          finishBonusCard,
          const SizedBox(height: 14),
          sprintBonusCard,
        ],
        const SizedBox(height: 14),
        _buildSectionCard(
          title: 'Ochrona Czasowa w Strefie Finałowej (Zasady UCI)',
          subtitle: 'Automatycznie stosowane w klasyfikacji generalnej ${theme.gcJerseyName}',
          accentColor: AppColors.primaryAccent,
          child: Column(
            children: [
              _buildRuleBullet(
                title: 'Reguła 3 Kilometrów (Strefa Bezpieczeństwa)',
                description:
                    'Kraksa lub defekt mechaniczny w ostatnich 3 km etapu płaskiego bądź pagórkowatego daje czas grupy, '
                    'w której kolarz jechał przed incydentem. Nie obowiązuje na finiszach szczytowych (Summit Finish) i czasówkach.',
                color: AppColors.emeraldGreen,
              ),
              const SizedBox(height: 10),
              _buildRuleBullet(
                title: 'Reguła 3 Sekund na Etapach Sprinterskich',
                description:
                    'Na etapach płaskich różnica mniejsza niż 3 sekundy między kolejnymi kolarzami w peletonie jest traktowana '
                    'jako ten sam czas grupy (brak sztucznych strat w GC przy finiszu z dużej grupy).',
                color: AppColors.accentBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLimitOtlTab({
    required bool isCompact,
    required bool isWide,
  }) {
    final OtlCalculationPreview preview =
        GrandTourPointRulesCatalog.computeOtlPreview(
      stageType: _otlStageType,
      distanceKm: _otlDistanceKm,
      winnerSpeedKmh: _otlWinnerSpeedKmh,
    );

    final Widget formulaAndTable = _buildSectionCard(
      title: 'Wzór Wyliczania Limitu Czasu (OTL / Hors Délais)',
      subtitle:
          'Kolarz przekraczający limit zostaje zdyskwalifikowany z wyścigu (OTL).',
      accentColor: AppColors.accentBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WZÓR OFICJALNY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.accentBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Limit OTL = Czas Zwycięzcy × (1 + Współczynnik Limitu %)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: isCompact ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Maksymalna dopuszczalna strata = Czas Zwycięzcy × (Współczynnik Limitu % / 100)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildOtlMatrixTable(isCompact: isCompact),
        ],
      ),
    );

    final Widget calculatorCard = _buildSectionCard(
      title: 'Kalkulator Limitu OTL Na Żywo',
      subtitle:
          'Sprawdź maksymalną stratę w grupetto dla konkretnego profilu i tempa.',
      accentColor: AppColors.goldAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStageTypeChip(StageType.flat, 'Płaski'),
              _buildStageTypeChip(StageType.hilly, 'Pagórkowaty'),
              _buildStageTypeChip(StageType.highMountain, 'Górski'),
              _buildStageTypeChip(StageType.individualTimeTrial, 'ITT / TTT'),
            ],
          ),
          const SizedBox(height: 14),
          _buildSliderControl(
            label: 'Dystans etapu',
            valueText: '${_otlDistanceKm.toStringAsFixed(0)} km',
            value: _otlDistanceKm,
            min: 15,
            max: 250,
            divisions: 47,
            onChanged: (v) => setState(() => _otlDistanceKm = v),
          ),
          const SizedBox(height: 8),
          _buildSliderControl(
            label: 'Średnia prędkość zwycięzcy',
            valueText: '${_otlWinnerSpeedKmh.toStringAsFixed(1)} km/h',
            value: _otlWinnerSpeedKmh,
            min: 28.0,
            max: 55.0,
            divisions: 54,
            onChanged: (v) => setState(() => _otlWinnerSpeedKmh = v),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildOtlMetricRow(
                  label: 'Czas zwycięzcy',
                  value: GrandTourPointRulesCatalog.formatDurationHms(
                    preview.winnerTimeSeconds,
                  ),
                  valueColor: AppColors.textPrimary,
                ),
                const SizedBox(height: 8),
                _buildOtlMetricRow(
                  label: 'Współczynnik limitu OTL',
                  value: '+${preview.timeCutPercent.toStringAsFixed(0)}%',
                  valueColor: AppColors.accentBlue,
                ),
                const SizedBox(height: 8),
                _buildOtlMetricRow(
                  label: 'Maks. strata grupetto',
                  value:
                      '+${GrandTourPointRulesCatalog.formatDurationHms(preview.maxGapSeconds)}',
                  valueColor: AppColors.amberWarning,
                ),
                const Divider(color: AppTheme.borderColor, height: 18),
                _buildOtlMetricRow(
                  label: 'Godzina zamknięcia mety (OTL)',
                  value: GrandTourPointRulesCatalog.formatDurationHms(
                    preview.totalCutoffSeconds,
                  ),
                  valueColor: AppColors.crimsonAlert,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: formulaAndTable),
          const SizedBox(width: 14),
          Expanded(flex: 5, child: calculatorCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        formulaAndTable,
        const SizedBox(height: 14),
        calculatorCard,
      ],
    );
  }

  Widget _buildJerseyStrip({
    required GrandTourJerseyTheme theme,
    required bool isCompact,
  }) {
    final items = [
      (label: theme.gcJerseyName, color: theme.gcJerseyColor),
      (label: theme.pointsJerseyName, color: theme.pointsJerseyColor),
      (label: theme.komJerseyName, color: theme.komJerseyColor),
      (label: theme.youthJerseyName, color: theme.youthJerseyColor),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.color.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checkroom_rounded, color: item.color, size: 17),
              const SizedBox(width: 7),
              Text(
                item.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPointsMatrixTable({
    required List<GrandTourPointScaleRow> rows,
    required int maxColumns,
    required bool isCompact,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isCompact ? 620 : 880),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 220,
                    child: Text(
                      'KATEGORIA / PROFIL',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  ...List.generate(maxColumns, (index) {
                    return SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          '${index + 1}.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: index < 3
                                ? AppColors.goldAccent
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...rows.map((row) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: row.isHighlighted
                      ? row.accentColor.withValues(alpha: 0.12)
                      : AppColors.surfaceLight.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: row.isHighlighted
                        ? row.accentColor.withValues(alpha: 0.7)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: row.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  row.categoryLabel,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.subtitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...List.generate(maxColumns, (index) {
                      final int? pts = index < row.pointsByRank.length
                          ? row.pointsByRank[index]
                          : null;
                      return SizedBox(
                        width: 40,
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: pts != null && index == 0
                                  ? row.accentColor.withValues(alpha: 0.22)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pts != null ? '$pts' : '—',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: pts == null
                                    ? AppColors.textSecondary
                                        .withValues(alpha: 0.4)
                                    : (index == 0
                                        ? row.accentColor
                                        : AppColors.textPrimary),
                                fontSize: 12,
                                fontWeight: index < 3
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBonusPodiumList({
    required List<int> secondsList,
    required Color accentColor,
    required String badgeLabel,
  }) {
    const List<String> medals = ['1. miejsce', '2. miejsce', '3. miejsce'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          child: Text(
            '$badgeLabel: ${secondsList.join('-')} s',
            style: TextStyle(
              fontFamily: 'Inter',
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(secondsList.length, (index) {
          final int sec = secondsList[index];
          return Container(
            margin: EdgeInsets.only(bottom: index < secondsList.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: index == 0
                    ? accentColor.withValues(alpha: 0.55)
                    : AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: index == 0 ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: index == 0 ? accentColor : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    medals[index],
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '-$sec s',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: accentColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOtlMatrixTable({required bool isCompact}) {
    const List<({String type, String slow, String mid, String fast})> rows = [
      (
        type: 'Etap Płaski',
        slow: '6% (≤ 44 km/h)',
        mid: '9% (44–48 km/h)',
        fast: '11% (> 48 km/h)',
      ),
      (
        type: 'Pagórkowaty / Bruk',
        slow: '10% (≤ 38 km/h)',
        mid: '12% (38–42 km/h)',
        fast: '14% (> 42 km/h)',
      ),
      (
        type: 'Górski / Szczytowy',
        slow: '13% (≤ 34 km/h)',
        mid: '16% (34–38 km/h)',
        fast: '18% (> 38 km/h)',
      ),
      (
        type: 'Jazda na Czas (ITT / TTT)',
        slow: '25% (stały)',
        mid: '25% (stały)',
        fast: '25% (stały)',
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isCompact ? 480 : 520),
        child: Column(
          children: [
            ...rows.map((row) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(
                        row.type,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 112,
                      child: Text(
                        row.slow,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.emeraldGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 112,
                      child: Text(
                        row.mid,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.amberWarning,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 112,
                      child: Text(
                        row.fast,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.crimsonAlert,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
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
    );
  }

  Widget _buildStageTypeChip(StageType type, String label) {
    final bool isSelected = _otlStageType == type;
    return _InteractiveFilterPill(
      label: label,
      accentColor: AppColors.goldAccent,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _otlStageType = type;
          if (type == StageType.individualTimeTrial ||
              type == StageType.teamTimeTrial) {
            _otlDistanceKm = 38.0;
            _otlWinnerSpeedKmh = 51.0;
          } else if (type == StageType.flat) {
            _otlDistanceKm = 195.0;
            _otlWinnerSpeedKmh = 46.0;
          } else if (type == StageType.hilly) {
            _otlDistanceKm = 180.0;
            _otlWinnerSpeedKmh = 41.0;
          } else {
            _otlDistanceKm = 165.0;
            _otlWinnerSpeedKmh = 35.5;
          }
        });
      },
    );
  }

  Widget _buildSliderControl({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.goldAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildOtlMetricRow({
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            color: valueColor,
            fontSize: isBold ? 15 : 13,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoBanner({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBullet({
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter({
    required GrandTourJerseyTheme theme,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Przepisy UCI WorldTour • ${theme.raceName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _InteractiveActionButton(
            label: 'Rozumiem',
            icon: Icons.check_rounded,
            onPressed: _handleClose,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _InteractiveFilterPill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? leadingColor;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const _InteractiveFilterPill({
    required this.label,
    this.icon,
    this.leadingColor,
    this.accentColor = AppColors.goldAccent,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_InteractiveFilterPill> createState() => _InteractiveFilterPillState();
}

class _InteractiveFilterPillState extends State<_InteractiveFilterPill> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onTap != null;
    final Color bgColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: 0.20)
        : (_isPressed
            ? AppColors.surfaceLight
            : (_isHovered ? AppColors.surface : AppColors.background));
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : (widget.isSelected
            ? widget.accentColor
            : (_isHovered ? AppColors.textSecondary : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor:
            isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              isEnabled ? () => setState(() => _isPressed = false) : null,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.leadingColor != null) ...[
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: widget.leadingColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ] else if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 15,
                      color: widget.isSelected
                          ? widget.accentColor
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      color: widget.isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
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

class _InteractiveActionButton extends StatefulWidget {
  final String? label;
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isCompact;

  const _InteractiveActionButton({
    this.label,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.isPrimary = false,
    this.isCompact = false,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final Color baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final Color bgColor = !isEnabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (_isPressed
            ? baseColor.withValues(alpha: 0.85)
            : (_isHovered
                ? (widget.isPrimary
                    ? AppColors.primaryAccent.withValues(alpha: 0.9)
                    : AppColors.cardBorder)
                : baseColor));

    final Widget button = FocusableActionDetector(
      enabled: isEnabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor:
            isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              isEnabled ? () => setState(() => _isPressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 9 : 14,
              vertical: widget.isCompact ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? AppColors.goldAccent
                    : (widget.isPrimary
                        ? AppColors.goldAccent.withValues(alpha: 0.5)
                        : AppColors.cardBorder),
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 17, color: AppColors.textPrimary),
                  if (widget.label != null) ...[
                    const SizedBox(width: 7),
                    Text(
                      widget.label!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
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
