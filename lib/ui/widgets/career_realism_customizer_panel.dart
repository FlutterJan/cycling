import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_feature_flags_and_presets.dart';
import '../../core/theme/app_colors.dart';

/// Panel wyboru presetu realizmu oraz szczegółowej konfiguracji reguł
/// przy starcie nowej kariery.
///
/// Integruje się bezpośrednio z centralnym rejestrem [appFeatureFlagsProvider],
/// prezentuje 5 predefiniowanych presetów (oraz stan `custom`), wylicza wskaźnik
/// realizmu `0–100`, pokazuje różnice względem bazowego presetu oraz pozwala
/// na ręczne dostrojenie wszystkich flag, trybów i mnożników przed startem.
class CareerRealismCustomizerPanel extends ConsumerStatefulWidget {
  /// Wywoływane po wyborze jednego z presetów realizmu.
  final ValueChanged<GameplayRealismPresetId>? onPresetSelected;

  /// Wywoływane przy każdej zmianie flag realizmu.
  final ValueChanged<GameplayRealismFlags>? onFlagsChanged;

  /// Wywoływane po kliknięciu przycisku zatwierdzającego start kariery.
  final void Function(
    GameplayRealismPresetId presetId,
    GameplayRealismFlags flags,
  )?
  onConfirmStartCareer;

  /// Opcjonalny callback anulowania kreatora nowej kariery.
  final VoidCallback? onCancel;

  /// Etykieta głównego przycisku potwierdzającego.
  final String confirmButtonLabel;

  /// Czy wyświetlać dolny pasek akcji (Anuluj / Zatwierdź).
  final bool showActionFooter;

  /// Czy sekcja zaawansowanej personalizacji ma być rozwinięta na starcie.
  final bool initialExpandedCustomizations;

  const CareerRealismCustomizerPanel({
    super.key,
    this.onPresetSelected,
    this.onFlagsChanged,
    this.onConfirmStartCareer,
    this.onCancel,
    this.confirmButtonLabel = 'Zatwierdź i Rozpocznij Karierę',
    this.showActionFooter = true,
    this.initialExpandedCustomizations = false,
  });

  @override
  ConsumerState<CareerRealismCustomizerPanel> createState() =>
      _CareerRealismCustomizerPanelState();
}

class _CareerRealismCustomizerPanelState
    extends ConsumerState<CareerRealismCustomizerPanel> {
  static const Duration _animDuration = Duration(milliseconds: 240);
  static const Curve _animCurve = Curves.easeOutCubic;

  late bool _isCustomizerExpanded;
  FeatureFlagCategory _selectedCategory =
      FeatureFlagCategory.physicsAndEnvironment;

  @override
  void initState() {
    super.initState();
    _isCustomizerExpanded = widget.initialExpandedCustomizations;
  }

  void _selectPreset(
    AppFeatureFlagsNotifier notifier,
    GameplayRealismPresetId presetId,
  ) {
    final applied = notifier.applyPreset(presetId);
    if (!applied) return;
    final updatedState = ref.read(appFeatureFlagsProvider);
    widget.onPresetSelected?.call(updatedState.activePresetId);
    widget.onFlagsChanged?.call(updatedState.flags);
  }

  void _updateFlags(
    AppFeatureFlagsNotifier notifier,
    GameplayRealismFlags Function(GameplayRealismFlags current) updater,
  ) {
    final applied = notifier.updateFlags(updater);
    if (!applied) return;
    final updatedState = ref.read(appFeatureFlagsProvider);
    widget.onFlagsChanged?.call(updatedState.flags);
  }

  void _toggleFlag(
    AppFeatureFlagsNotifier notifier,
    String key,
    bool value,
  ) {
    final applied = notifier.toggleBooleanFlag(key, value);
    if (!applied) return;
    final updatedState = ref.read(appFeatureFlagsProvider);
    widget.onFlagsChanged?.call(updatedState.flags);
  }

  void _resetToDefaults(AppFeatureFlagsNotifier notifier) {
    final applied = notifier.resetToPresetDefaults();
    if (!applied) return;
    final updatedState = ref.read(appFeatureFlagsProvider);
    widget.onPresetSelected?.call(updatedState.activePresetId);
    widget.onFlagsChanged?.call(updatedState.flags);
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.crimsonAlert;
    if (score >= 58) return AppColors.goldAccent;
    if (score >= 30) return AppColors.statusSuccess;
    return AppColors.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appFeatureFlagsProvider);
    final notifier = ref.read(appFeatureFlagsProvider.notifier);
    final validation = AppFeatureFlagsAndPresets.validateFlags(state.flags);
    final isLocked = state.isLockedInActiveCareer;
    final activePresetDef = AppFeatureFlagsAndPresets.presetById(
      state.activePresetId,
    );
    final baselineForDiff =
        state.activePresetId == GameplayRealismPresetId.custom
        ? GameplayRealismPresetId.balancedWorldTour
        : state.activePresetId;
    final diffs = AppFeatureFlagsAndPresets.diffFromPreset(
      state.flags,
      baselineForDiff,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = maxWidth < 640;
        final isWide = maxWidth >= 1100;
        final crossAxisCount = isWide ? 3 : (isCompact ? 1 : 2);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 14 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(
                  state: state,
                  activePresetDef: activePresetDef,
                  isCompact: isCompact,
                  isLocked: isLocked,
                ),
                if (isLocked) ...<Widget>[
                  const SizedBox(height: 14),
                  _buildLockedBanner(),
                ],
                if (validation.warnings.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 14),
                  _buildValidationBanner(validation.warnings),
                ],
                const SizedBox(height: 18),
                _buildSectionTitle(
                  title: 'Wybierz Preset Realizmu Kariery',
                  subtitle:
                      'Preset określa fizykę peletonu, widoczność telemetrii, mgłę skautingu, surowość sędziów UCI i zasady zapisu.',
                  isCompact: isCompact,
                ),
                const SizedBox(height: 12),
                _buildPresetGrid(
                  state: state,
                  notifier: notifier,
                  crossAxisCount: crossAxisCount,
                  isCompact: isCompact,
                  isLocked: isLocked,
                ),
                const SizedBox(height: 16),
                _buildActiveSummaryBar(
                  state: state,
                  activePresetDef: activePresetDef,
                  diffs: diffs,
                  notifier: notifier,
                  isCompact: isCompact,
                  isLocked: isLocked,
                ),
                const SizedBox(height: 14),
                _buildCustomizerAccordion(
                  state: state,
                  notifier: notifier,
                  isCompact: isCompact,
                  isWide: isWide,
                  isLocked: isLocked,
                ),
                if (widget.showActionFooter) ...<Widget>[
                  const SizedBox(height: 18),
                  _buildActionFooter(
                    state: state,
                    activePresetDef: activePresetDef,
                    isCompact: isCompact,
                    isLocked: isLocked,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required AppFeatureFlagsState state,
    required RealismPresetDefinition activePresetDef,
    required bool isCompact,
    required bool isLocked,
  }) {
    final score = state.flags.realismScore;
    final badgeColor = _scoreColor(score);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Konfigurator Realizmu Nowej Kariery',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Dobierz poziom autentyczności symulacji przed podpisaniem pierwszego kontraktu dyrektora sportowego.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isCompact ? 12.5 : 13.5,
            color: AppColors.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );

    final scoreCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score / 100.0),
            duration: _animDuration,
            curve: _animCurve,
            builder: (context, value, _) {
              return SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(
                      value: value.clamp(0.0, 1.0),
                      strokeWidth: 4,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                    ),
                    Text(
                      '$score',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'INDEKS REALIZMU',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    state.flags.difficultyLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (isLocked) ...<Widget>[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppColors.amberWarning,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          titleBlock,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: scoreCard),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        scoreCard,
      ],
    );
  }

  Widget _buildLockedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.amberWarning.withValues(alpha: 0.45),
        ),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.lock_outline_rounded,
            color: AppColors.amberWarning,
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Konfiguracja realizmu jest zablokowana w aktywnej karierze (np. tryb Ironman). Zmiana presetu możliwa jest tylko przy starcie nowej kariery.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationBanner(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.amberWarning.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.amberWarning,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Uwagi spójności konfiguracji',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amberWarning,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final w in warnings)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '• $w',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isCompact ? 15 : 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            color: AppColors.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetGrid({
    required AppFeatureFlagsState state,
    required AppFeatureFlagsNotifier notifier,
    required int crossAxisCount,
    required bool isCompact,
    required bool isLocked,
  }) {
    final presets = AppFeatureFlagsAndPresets.presets;
    final rows = <Widget>[];
    for (var i = 0; i < presets.length; i += crossAxisCount) {
      final slice = presets.sublist(
        i,
        (i + crossAxisCount).clamp(0, presets.length),
      );
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var j = 0; j < crossAxisCount; j++) ...<Widget>[
                if (j > 0) const SizedBox(width: 12),
                if (j < slice.length)
                  Expanded(
                    child: _InteractivePresetCard(
                      preset: slice[j],
                      isSelected: state.activePresetId == slice[j].id,
                      isDisabled: isLocked,
                      isCompact: isCompact,
                      onTap: () => _selectPreset(notifier, slice[j].id),
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
        ),
      );
      if (i + crossAxisCount < presets.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildActiveSummaryBar({
    required AppFeatureFlagsState state,
    required RealismPresetDefinition activePresetDef,
    required List<RealismFlagDiffEntry> diffs,
    required AppFeatureFlagsNotifier notifier,
    required bool isCompact,
    required bool isLocked,
  }) {
    final isCustom = state.activePresetId == GameplayRealismPresetId.custom;
    final accent = activePresetDef.badgeColor;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(activePresetDef.icon, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Aktywny tryb: ${activePresetDef.name}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              if (isCustom)
                _InteractivePillButton(
                  icon: Icons.restart_alt_rounded,
                  label: 'Przywróć WorldTour Standard',
                  accentColor: AppColors.goldAccent,
                  isDisabled: isLocked,
                  onTap: () => _resetToDefaults(notifier),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _buildMetaChip(
                icon: Icons.speed_rounded,
                label: 'Telemetria: ${state.flags.telemetryVisibility.displayName}',
              ),
              _buildMetaChip(
                icon: Icons.visibility_off_rounded,
                label: 'Skauting: ${state.flags.scoutingFogOfWar.displayName}',
              ),
              _buildMetaChip(
                icon: Icons.gavel_rounded,
                label: 'Sędziowie: ${state.flags.uciStrictness.displayName}',
              ),
              _buildMetaChip(
                icon: Icons.save_rounded,
                label: 'Zapis: ${state.flags.saveIntegrity.displayName}',
                highlightColor:
                    state.flags.saveIntegrity == SaveIntegrityMode.ironmanSingleSlot
                    ? AppColors.crimsonAlert
                    : null,
              ),
            ],
          ),
          if (diffs.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Zmodyfikowane parametry względem bazowego presetu (${diffs.length}):',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.goldAccent,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: diffs.map((diff) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${diff.title}: ${diff.presetValue} → ${diff.currentValue}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    Color? highlightColor,
  }) {
    final color = highlightColor ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlightColor != null
              ? highlightColor.withValues(alpha: 0.45)
              : const Color(0xFF2A2F3D),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: highlightColor ?? AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizerAccordion({
    required AppFeatureFlagsState state,
    required AppFeatureFlagsNotifier notifier,
    required bool isCompact,
    required bool isWide,
    required bool isLocked,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _InteractiveAccordionHeader(
            isExpanded: _isCustomizerExpanded,
            onTap: () {
              setState(() {
                _isCustomizerExpanded = !_isCustomizerExpanded;
              });
            },
          ),
          AnimatedSize(
            duration: _animDuration,
            curve: _animCurve,
            alignment: Alignment.topCenter,
            child: _isCustomizerExpanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 12 : 16,
                      0,
                      isCompact ? 12 : 16,
                      isCompact ? 14 : 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Divider(color: Color(0xFF2A2F3D), height: 1),
                        const SizedBox(height: 14),
                        _buildCategoryTabs(isCompact),
                        const SizedBox(height: 14),
                        _buildCategoryContent(
                          state: state,
                          notifier: notifier,
                          isCompact: isCompact,
                          isWide: isWide,
                          isLocked: isLocked,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FeatureFlagCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return _InteractiveCategoryChip(
          category: category,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategoryContent({
    required AppFeatureFlagsState state,
    required AppFeatureFlagsNotifier notifier,
    required bool isCompact,
    required bool isWide,
    required bool isLocked,
  }) {
    final flagsInCategory = AppFeatureFlagsAndPresets.flagCatalog
        .where((meta) => meta.category == _selectedCategory)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Enumy i mnożniki specyficzne dla kategorii
        if (_selectedCategory == FeatureFlagCategory.physicsAndEnvironment) ...<
          Widget
        >[
          _buildMultiplierSlider(
            title: 'Częstotliwość kraks i defektów',
            subtitle: 'Skaluje bazowe ryzyko kraks w peletonie i na zjazdach.',
            value: state.flags.crashFrequencyMultiplier,
            min: 0.0,
            max: 2.5,
            divisions: 25,
            accentColor: AppColors.accentBlue,
            isDisabled: isLocked,
            onChanged: (v) => _updateFlags(
              notifier,
              (c) => c.copyWith(crashFrequencyMultiplier: v),
            ),
          ),
          const SizedBox(height: 10),
          _buildMultiplierSlider(
            title: 'Surowość warunków pogodowych',
            subtitle: 'Intensywność deszczu, bocznego wiatru i temperatur.',
            value: state.flags.weatherSeverityMultiplier,
            min: 0.25,
            max: 2.0,
            divisions: 14,
            accentColor: AppColors.accentBlue,
            isDisabled: isLocked,
            onChanged: (v) => _updateFlags(
              notifier,
              (c) => c.copyWith(weatherSeverityMultiplier: v),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_selectedCategory == FeatureFlagCategory.physiologyAndTelemetry) ...<
          Widget
        >[
          _buildEnumSelector<TelemetryVisibilityMode>(
            title: 'Widoczność Telemetrii Podczas Etapu',
            values: TelemetryVisibilityMode.values,
            selected: state.flags.telemetryVisibility,
            labelOf: (v) => v.displayName,
            descOf: (v) => v.description,
            pointsOf: (v) => v.realismPoints,
            accentColor: AppColors.statusSuccess,
            isDisabled: isLocked,
            onSelected: (v) => _updateFlags(
              notifier,
              (c) => c.copyWith(telemetryVisibility: v),
            ),
          ),
          const SizedBox(height: 10),
          _buildMultiplierSlider(
            title: 'Akumulacja zmęczenia (ATL / CTL)',
            subtitle: 'Tempo narastania zmęczenia w trakcie wielkich tourów.',
            value: state.flags.fatigueAccumulationMultiplier,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            accentColor: AppColors.statusSuccess,
            isDisabled: isLocked,
            onChanged: (v) => _updateFlags(
              notifier,
              (c) => c.copyWith(fatigueAccumulationMultiplier: v),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_selectedCategory == FeatureFlagCategory.tacticsAndAi) ...<Widget>[
          _buildMultiplierSlider(
            title: 'Agresywność Taktyczna AI',
            subtitle:
                'Skłonność rywali do dalekich ataków, wachlarzy i blokowania.',
            value: state.flags.aiTacticalAggressionMultiplier,
            min: 0.5,
            max: 1.8,
            divisions: 13,
            accentColor: AppColors.goldAccent,
            isDisabled: isLocked,
            onChanged: (v) => _updateFlags(
              notifier,
              (c) => c.copyWith(aiTacticalAggressionMultiplier: v),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_selectedCategory == FeatureFlagCategory.rulesAndLogistics) ...<
          Widget
        >[
          _buildEnumSelector<UciCommissaireStrictness>(
            title: 'Surowość Sędziów UCI i Sprint VAR',
            values: UciCommissaireStrictness.values,
            selected: state.flags.uciStrictness,
            labelOf: (v) => v.displayName,
            descOf: (v) => v.description,
            pointsOf: (v) => v.realismPoints,
            accentColor: AppColors.amberWarning,
            isDisabled: isLocked,
            onSelected: (v) =>
                _updateFlags(notifier, (c) => c.copyWith(uciStrictness: v)),
          ),
          const SizedBox(height: 12),
        ],
        if (_selectedCategory == FeatureFlagCategory.careerAndEconomy) ...<
          Widget
        >[
          _buildEnumSelector<ScoutingFogOfWarMode>(
            title: 'Mgła Wojny Skautingu',
            values: ScoutingFogOfWarMode.values,
            selected: state.flags.scoutingFogOfWar,
            labelOf: (v) => v.displayName,
            descOf: (v) => v.description,
            pointsOf: (v) => v.realismPoints,
            accentColor: AppColors.primaryAccent,
            isDisabled: isLocked,
            onSelected: (v) => _updateFlags(
              notifier,
              (c) => c.copyWith(scoutingFogOfWar: v),
            ),
          ),
          const SizedBox(height: 10),
          _buildEnumSelector<SaveIntegrityMode>(
            title: 'Tryb Zapisu Kariery',
            values: SaveIntegrityMode.values,
            selected: state.flags.saveIntegrity,
            labelOf: (v) => v.displayName,
            descOf: (v) => v.description,
            pointsOf: (v) => v.realismPoints,
            accentColor: AppColors.crimsonAlert,
            isDisabled: isLocked,
            onSelected: (v) =>
                _updateFlags(notifier, (c) => c.copyWith(saveIntegrity: v)),
          ),
          const SizedBox(height: 10),
          _buildMultiplierSlider(
            title: 'Trudność Ekonomii i Kontraktów',
            subtitle: 'Wysokość wymagań sponsorów oraz kosztów pensji.',
            value: state.flags.economyDifficultyMultiplier,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            accentColor: AppColors.primaryAccent,
            isDisabled: isLocked,
            onChanged: (v) => _updateFlags(
              notifier,
              (c) => c.copyWith(economyDifficultyMultiplier: v),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Flagi logiczne kategorii
        for (final meta in flagsInCategory) ...<Widget>[
          _InteractiveFlagSwitchTile(
            meta: meta,
            value: state.flags.getBoolFlag(meta.key) ?? false,
            isDisabled: isLocked,
            onChanged: (val) => _toggleFlag(notifier, meta.key, val),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildEnumSelector<T>({
    required String title,
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required String Function(T) descOf,
    required int Function(T) pointsOf,
    required Color accentColor,
    required bool isDisabled,
    required ValueChanged<T> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: values.map((item) {
              final isSelected = item == selected;
              final pts = pointsOf(item);
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _InteractiveEnumOptionTile(
                  label: labelOf(item),
                  description: descOf(item),
                  points: pts,
                  isSelected: isSelected,
                  isDisabled: isDisabled,
                  accentColor: accentColor,
                  onTap: () => onSelected(item),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierSlider({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color accentColor,
    required bool isDisabled,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  '${value.toStringAsFixed(2)}x',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: AppColors.surface,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.18),
              disabledActiveTrackColor: AppColors.textSecondary.withValues(
                alpha: 0.4,
              ),
              disabledThumbColor: AppColors.textSecondary,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: isDisabled ? null : onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter({
    required AppFeatureFlagsState state,
    required RealismPresetDefinition activePresetDef,
    required bool isCompact,
    required bool isLocked,
  }) {
    final isIronman =
        state.flags.saveIntegrity == SaveIntegrityMode.ironmanSingleSlot;

    final infoWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Wybrano: ${activePresetDef.name} (${state.flags.realismScore}/100 pkt)',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isIronman
              ? 'Uwaga: tryb Ironman blokuje zmianę reguł po starcie kariery.'
              : 'Reguły zostaną zapisane w pliku startowym nowej kariery.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: isIronman
                ? AppColors.crimsonAlert
                : AppColors.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );

    final buttons = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        if (widget.onCancel != null)
          OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: Color(0xFF2A2F3D)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Wstecz',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: isLocked
              ? null
              : () {
                  widget.onConfirmStartCareer?.call(
                    state.activePresetId,
                    state.flags,
                  );
                },
          icon: const Icon(Icons.flag_rounded, size: 18),
          label: Text(
            widget.confirmButtonLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surfaceLight,
            disabledForegroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                infoWidget,
                const SizedBox(height: 12),
                buttons,
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: infoWidget),
                const SizedBox(width: 16),
                buttons,
              ],
            ),
    );
  }
}

/// Karta pojedynczego presetu realizmu z pełnymi stanami hover/active/focus/disabled.
class _InteractivePresetCard extends StatefulWidget {
  final RealismPresetDefinition preset;
  final bool isSelected;
  final bool isDisabled;
  final bool isCompact;
  final VoidCallback onTap;

  const _InteractivePresetCard({
    required this.preset,
    required this.isSelected,
    required this.isDisabled,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_InteractivePresetCard> createState() => _InteractivePresetCardState();
}

class _InteractivePresetCardState extends State<_InteractivePresetCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.preset.badgeColor;
    final score = widget.preset.flags.realismScore;

    final borderColor = widget.isSelected
        ? accent
        : _isFocused
        ? AppColors.goldAccent
        : _isHovered && !widget.isDisabled
        ? accent.withValues(alpha: 0.65)
        : const Color(0xFF2A2F3D);

    final bgColor = widget.isSelected
        ? accent.withValues(alpha: 0.12)
        : _isPressed && !widget.isDisabled
        ? AppColors.surfaceLight
        : _isHovered && !widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.8)
        : AppColors.surface;

    return Opacity(
      opacity: widget.isDisabled ? 0.55 : 1.0,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        mouseCursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (!widget.isDisabled) widget.onTap();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (hovered) =>
            setState(() => _isHovered = hovered),
        onShowFocusHighlight: (focused) =>
            setState(() => _isFocused = focused),
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onTap,
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = true),
          onTapUp: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = false),
          onTapCancel: widget.isDisabled
              ? null
              : () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..scaleByDouble(
                _isPressed && !widget.isDisabled ? 0.985 : 1.0,
                _isPressed && !widget.isDisabled ? 0.985 : 1.0,
                1.0,
                1.0,
              ),
            padding: EdgeInsets.all(widget.isCompact ? 12 : 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _isFocused ? 1.8 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.preset.icon,
                        color: accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.preset.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            widget.preset.subtitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$score pkt',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: accent,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.preset.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Dla: ${widget.preset.recommendedFor}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (widget.isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: accent,
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

/// Nagłówek akordeonu zaawansowanych ustawień z obsługą hover/focus/pressed.
class _InteractiveAccordionHeader extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _InteractiveAccordionHeader({
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_InteractiveAccordionHeader> createState() =>
      _InteractiveAccordionHeaderState();
}

class _InteractiveAccordionHeaderState
    extends State<_InteractiveAccordionHeader> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceLight.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: _isFocused
                ? Border.all(color: AppColors.goldAccent, width: 1.5)
                : null,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.settings_suggest_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Dostosuj Szczegółowe Reguły i Flagi Realizmu',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Przełączaj 14 flag symulacji, tryby telemetrii, sędziów UCI oraz mnożniki trudności.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: widget.isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interaktywny przycisk kategorii flag realizmu.
class _InteractiveCategoryChip extends StatefulWidget {
  final FeatureFlagCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _InteractiveCategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InteractiveCategoryChip> createState() =>
      _InteractiveCategoryChipState();
}

class _InteractiveCategoryChipState extends State<_InteractiveCategoryChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.category.accentColor;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? accent.withValues(alpha: 0.18)
                : _isHovered
                ? AppColors.surfaceLight
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? accent
                  : _isFocused
                  ? AppColors.goldAccent
                  : const Color(0xFF2A2F3D),
              width: widget.isSelected || _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.category.icon,
                size: 15,
                color: widget.isSelected ? accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.category.displayName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interaktywny przycisk pigułkowy (np. Reset).
class _InteractivePillButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isDisabled;
  final VoidCallback onTap;

  const _InteractivePillButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        mouseCursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isHovered && !widget.isDisabled
                  ? widget.accentColor.withValues(alpha: 0.2)
                  : widget.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? AppColors.goldAccent
                    : widget.accentColor.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(widget.icon, size: 15, color: widget.accentColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.accentColor,
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

/// Wiersz wyboru pojedynczej wartości enum (np. widoczność telemetrii).
class _InteractiveEnumOptionTile extends StatefulWidget {
  final String label;
  final String description;
  final int points;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveEnumOptionTile({
    required this.label,
    required this.description,
    required this.points,
    required this.isSelected,
    required this.isDisabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveEnumOptionTile> createState() =>
      _InteractiveEnumOptionTileState();
}

class _InteractiveEnumOptionTileState
    extends State<_InteractiveEnumOptionTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isDisabled ? 0.55 : 1.0,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        mouseCursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.accentColor.withValues(alpha: 0.14)
                  : _isHovered && !widget.isDisabled
                  ? AppColors.surface
                  : AppColors.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? widget.accentColor
                    : _isFocused
                    ? AppColors.goldAccent
                    : const Color(0xFF2A2F3D),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  widget.isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: widget.isSelected
                      ? widget.accentColor
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        widget.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${widget.points} pkt',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: widget.points > 0
                        ? widget.accentColor
                        : AppColors.textSecondary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
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

/// Wiersz przełącznika pojedynczej flagi logicznej z obsługą hover/focus/disabled.
class _InteractiveFlagSwitchTile extends StatefulWidget {
  final FeatureFlagMetadata meta;
  final bool value;
  final bool isDisabled;
  final ValueChanged<bool> onChanged;

  const _InteractiveFlagSwitchTile({
    required this.meta,
    required this.value,
    required this.isDisabled,
    required this.onChanged,
  });

  @override
  State<_InteractiveFlagSwitchTile> createState() =>
      _InteractiveFlagSwitchTileState();
}

class _InteractiveFlagSwitchTileState
    extends State<_InteractiveFlagSwitchTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.meta.category.accentColor;

    return Opacity(
      opacity: widget.isDisabled ? 0.55 : 1.0,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled,
        mouseCursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        child: GestureDetector(
          onTap: widget.isDisabled
              ? null
              : () => widget.onChanged(!widget.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered && !widget.isDisabled
                  ? AppColors.surfaceLight
                  : AppColors.surfaceLight.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? AppColors.goldAccent
                    : widget.value
                    ? accent.withValues(alpha: 0.45)
                    : const Color(0xFF2A2F3D),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            widget.meta.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (widget.meta.realismImpactPoints > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${widget.meta.realismImpactPoints} pkt',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.meta.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: widget.value,
                  activeThumbColor: accent,
                  activeTrackColor: accent.withValues(alpha: 0.35),
                  onChanged: widget.isDisabled ? null : widget.onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
