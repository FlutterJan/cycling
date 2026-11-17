// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/sponsor_custom_color_rebrand_events.dart';

/// Akcja podjęta przez menedżera w modalu prezentacji okazjonalnego malowania.
enum SpecialEditionLiveryModalAction {
  approved,
  customizedAndApproved,
  declined,
  dismissed;

  String toJson() => name;

  static SpecialEditionLiveryModalAction fromJson(String value) {
    return SpecialEditionLiveryModalAction.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SpecialEditionLiveryModalAction.dismissed,
    );
  }
}

/// Tryb podglądu na scenie prezentacji malowania.
enum LiveryPreviewDisplayMode {
  specialEdition,
  compareWithBase;

  String get label {
    switch (this) {
      case LiveryPreviewDisplayMode.specialEdition:
        return 'Edycja Specjalna';
      case LiveryPreviewDisplayMode.compareWithBase:
        return 'Porównaj z Bazowym';
    }
  }
}

/// Wynik interakcji z modalem prezentacji okazjonalnego malowania zespołu.
class SpecialEditionLiveryModalOutcome {
  final SpecialEditionLiveryModalAction action;
  final String proposalId;
  final LiveryColorPalette selectedPalette;
  final BikePaintFinish selectedBikeFinish;
  final bool includeMerchDrop;
  final double uciColorDistance;
  final DateTime decidedAt;

  const SpecialEditionLiveryModalOutcome({
    required this.action,
    required this.proposalId,
    required this.selectedPalette,
    required this.selectedBikeFinish,
    required this.includeMerchDrop,
    required this.uciColorDistance,
    required this.decidedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action.toJson(),
      'proposalId': proposalId,
      'selectedPalette': selectedPalette.toJson(),
      'selectedBikeFinish': selectedBikeFinish.toJson(),
      'includeMerchDrop': includeMerchDrop,
      'uciColorDistance': uciColorDistance,
      'decidedAt': decidedAt.toIso8601String(),
    };
  }

  factory SpecialEditionLiveryModalOutcome.fromJson(Map<String, dynamic> json) {
    return SpecialEditionLiveryModalOutcome(
      action: SpecialEditionLiveryModalAction.fromJson(
        (json['action'] as String?) ?? 'dismissed',
      ),
      proposalId: (json['proposalId'] as String?) ?? '',
      selectedPalette: LiveryColorPalette.fromJson(
        (json['selectedPalette'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
      selectedBikeFinish: BikePaintFinish.fromJson(
        (json['selectedBikeFinish'] as String?) ?? 'metallicFlake',
      ),
      includeMerchDrop: (json['includeMerchDrop'] as bool?) ?? true,
      uciColorDistance: (json['uciColorDistance'] as num?)?.toDouble() ?? 1.0,
      decidedAt: DateTime.tryParse((json['decidedAt'] as String?) ?? '') ??
          DateTime(2026, 7, 1),
    );
  }
}

/// Pomocnicze obliczenia zgodności UCI, zysku netto i oceny medialnej malowania.
class SpecialEditionLiveryPreviewCalculator {
  SpecialEditionLiveryPreviewCalculator._();

  static const double uciSafeDistanceThreshold = 0.28;

  /// Zwraca znormalizowaną odległość euklidesową w przestrzeni RGB [0.0, 1.0].
  static double computeColorDistance(Color a, Color b) {
    final dr = a.r - b.r;
    final dg = a.g - b.g;
    final db = a.b - b.b;
    return math.sqrt((dr * dr + dg * dg + db * db) / 3.0);
  }

  /// Sprawdza, czy główny kolor koszulki nie koliduje z koszulką lidera Wielkiego Touru.
  static bool isUciCompliant({
    required LiveryColorPalette palette,
    required GrandTourLiveryEvent grandTour,
  }) {
    final distance = computeColorDistance(
      palette.primaryJerseyColor,
      grandTour.uciProtectedColor,
    );
    return distance >= uciSafeDistanceThreshold;
  }

  /// Oblicza prognozowany zysk netto z uwzględnieniem opcjonalnej kolekcji kibicowskiej.
  static int computeNetProfitEur({
    required SpecialEditionLiveryProposal proposal,
    required bool includeMerchDrop,
  }) {
    final revenue = includeMerchDrop
        ? proposal.merchandiseRevenueBonusEur
        : (proposal.merchandiseRevenueBonusEur * 0.45).round();
    final cost = includeMerchDrop
        ? proposal.productionCostEur
        : (proposal.productionCostEur * 0.55).round();
    return revenue - cost;
  }
}

/// Wyświetla modal prezentacji okazjonalnego malowania zespołu.
Future<SpecialEditionLiveryModalOutcome?> showSpecialEditionLiveryPreviewModal(
  BuildContext context, {
  required SpecialEditionLiveryProposal proposal,
  LiveryColorPalette? baseTeamPalette,
  UciJerseyClashResult? uciClashResult,
  String teamName = 'Pro Peloton Team',
  bool isReadOnly = false,
}) {
  return showDialog<SpecialEditionLiveryModalOutcome>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (dialogContext) {
      return SpecialEditionLiveryPreviewModal(
        proposal: proposal,
        baseTeamPalette: baseTeamPalette,
        uciClashResult: uciClashResult,
        teamName: teamName,
        isReadOnly: isReadOnly,
        onOutcome: (outcome) => Navigator.of(dialogContext).pop(outcome),
      );
    },
  );
}

/// Modal prezentacji okazjonalnego malowania zespołu (koszulka + rower + telemetria).
class SpecialEditionLiveryPreviewModal extends StatefulWidget {
  final SpecialEditionLiveryProposal proposal;
  final LiveryColorPalette? baseTeamPalette;
  final UciJerseyClashResult? uciClashResult;
  final String teamName;
  final bool isReadOnly;
  final ValueChanged<SpecialEditionLiveryModalOutcome>? onOutcome;

  const SpecialEditionLiveryPreviewModal({
    super.key,
    required this.proposal,
    this.baseTeamPalette,
    this.uciClashResult,
    this.teamName = 'Pro Peloton Team',
    this.isReadOnly = false,
    this.onOutcome,
  });

  @override
  State<SpecialEditionLiveryPreviewModal> createState() =>
      _SpecialEditionLiveryPreviewModalState();
}

class _SpecialEditionLiveryPreviewModalState
    extends State<SpecialEditionLiveryPreviewModal> {
  late LiveryColorPalette _activePalette;
  late BikePaintFinish _activeFinish;
  LiveryPreviewDisplayMode _displayMode =
      LiveryPreviewDisplayMode.specialEdition;
  bool _includeMerchDrop = true;
  int _selectedSwatchIndex = 0;

  static const List<String> _curatedAccentHexes = <String>[
    '#D4AF37',
    '#38BDF8',
    '#10B981',
    '#8E4A49',
    '#F3F4F6',
    '#F59E0B',
  ];

  @override
  void initState() {
    super.initState();
    _activePalette = widget.proposal.palette;
    _activeFinish = widget.proposal.bikeFinish;
  }

  @override
  void didUpdateWidget(covariant SpecialEditionLiveryPreviewModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposal.id != widget.proposal.id) {
      _activePalette = widget.proposal.palette;
      _activeFinish = widget.proposal.bikeFinish;
      _displayMode = LiveryPreviewDisplayMode.specialEdition;
      _includeMerchDrop = true;
      _selectedSwatchIndex = 0;
    }
  }

  LiveryColorPalette get _effectiveBasePalette {
    return widget.baseTeamPalette ??
        const LiveryColorPalette(
          primaryJerseyHex: '#181B22',
          secondaryJerseyHex: '#0F1115',
          accentJerseyHex: '#8E4A49',
          bikeFrameHex: '#222630',
          wheelDecalHex: '#9CA3AF',
          helmetHex: '#F3F4F6',
        );
  }

  bool get _hasCustomEdits {
    return _activePalette != widget.proposal.palette ||
        _activeFinish != widget.proposal.bikeFinish;
  }

  void _applyAccentColor(String hex) {
    if (widget.isReadOnly) return;
    setState(() {
      switch (_selectedSwatchIndex) {
        case 0:
          _activePalette = _activePalette.copyWith(primaryJerseyHex: hex);
          break;
        case 1:
          _activePalette = _activePalette.copyWith(secondaryJerseyHex: hex);
          break;
        case 2:
          _activePalette = _activePalette.copyWith(accentJerseyHex: hex);
          break;
        case 3:
          _activePalette = _activePalette.copyWith(bikeFrameHex: hex);
          break;
        case 4:
          _activePalette = _activePalette.copyWith(wheelDecalHex: hex);
          break;
        case 5:
          _activePalette = _activePalette.copyWith(helmetHex: hex);
          break;
      }
    });
  }

  void _resetCustomizations() {
    if (widget.isReadOnly) return;
    setState(() {
      _activePalette = widget.proposal.palette;
      _activeFinish = widget.proposal.bikeFinish;
    });
  }

  void _submitOutcome(SpecialEditionLiveryModalAction action) {
    final distance = SpecialEditionLiveryPreviewCalculator.computeColorDistance(
      _activePalette.primaryJerseyColor,
      widget.proposal.grandTour.uciProtectedColor,
    );
    widget.onOutcome?.call(
      SpecialEditionLiveryModalOutcome(
        action: action,
        proposalId: widget.proposal.id,
        selectedPalette: _activePalette,
        selectedBikeFinish: _activeFinish,
        includeMerchDrop: _includeMerchDrop,
        uciColorDistance: distance,
        decidedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 680;
          final isTablet =
              constraints.maxWidth >= 680 && constraints.maxWidth < 1100;
          final maxDialogWidth = isMobile
              ? constraints.maxWidth
              : (isTablet ? 880.0 : 1080.0);
          final maxDialogHeight =
              math.min(constraints.maxHeight, isMobile ? 790.0 : 760.0);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxDialogWidth,
                maxHeight: maxDialogHeight,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, width: 1.0),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildHeader(isMobile),
                      const Divider(height: 1, color: AppColors.cardBorder),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 14 : 20),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    _buildShowcasePanel(isMobile: true),
                                    const SizedBox(height: 16),
                                    _buildTelemetryAndControls(isMobile: true),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 5,
                                      child: _buildShowcasePanel(
                                        isMobile: false,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 6,
                                      child: _buildTelemetryAndControls(
                                        isMobile: false,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.cardBorder),
                      _buildFooter(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final proposal = widget.proposal;
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 12 : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
            child: Icon(
              proposal.theme.icon,
              color: AppColors.goldAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _TagBadge(
                      label: proposal.grandTour.displayName.toUpperCase(),
                      color: AppColors.goldAccent,
                    ),
                    _TagBadge(
                      label: proposal.theme.label,
                      color: AppColors.accentBlue,
                    ),
                    if (widget.isReadOnly)
                      const _TagBadge(
                        label: 'TYLKO PODGLĄD',
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  proposal.editionTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.teamName}  •  ${proposal.sponsorName} × ${proposal.bikeManufacturerName} ${proposal.bikeModelName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _InteractiveIconButton(
            tooltip: 'Zamknij podgląd',
            icon: Icons.close_rounded,
            onTap: () =>
                _submitOutcome(SpecialEditionLiveryModalAction.dismissed),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcasePanel({required bool isMobile}) {
    final displayedPalette =
        _displayMode == LiveryPreviewDisplayMode.specialEdition
            ? _activePalette
            : _effectiveBasePalette;

    final swatchItems = <({String label, String hex})>[
      (label: 'Koszulka', hex: _activePalette.primaryJerseyHex),
      (label: 'Spodenki', hex: _activePalette.secondaryJerseyHex),
      (label: 'Akcent', hex: _activePalette.accentJerseyHex),
      (label: 'Rama', hex: _activePalette.bikeFrameHex),
      (label: 'Obręcze', hex: _activePalette.wheelDecalHex),
      (label: 'Kask', hex: _activePalette.helmetHex),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LiveryPreviewDisplayMode.values.map((mode) {
                    final selected = _displayMode == mode;
                    return _InteractiveChipButton(
                      label: mode.label,
                      isSelected: selected,
                      onTap: () => setState(() => _displayMode = mode),
                    );
                  }).toList(),
                ),
              ),
              if (_hasCustomEdits && !widget.isReadOnly)
                _InteractiveTextAction(
                  label: 'Resetuj',
                  icon: Icons.refresh_rounded,
                  onTap: _resetCustomizations,
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            height: isMobile ? 210 : 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _displayMode == LiveryPreviewDisplayMode.specialEdition
                    ? AppColors.goldAccent.withValues(alpha: 0.45)
                    : AppColors.cardBorder,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.background,
                  displayedPalette.primaryJerseyColor.withValues(alpha: 0.14),
                  AppColors.background,
                ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomPaint(
                      painter: SpecialEditionKitAndBikePainter(
                        palette: displayedPalette,
                        bikeFinish: _activeFinish,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      _displayMode == LiveryPreviewDisplayMode.specialEdition
                          ? _activeFinish.label
                          : 'Malowanie standardowe',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'PALETA ELEMENTÓW ZESTAWU',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(swatchItems.length, (index) {
              final item = swatchItems[index];
              final isSelected = _selectedSwatchIndex == index;
              return _ColorSwatchButton(
                label: item.label,
                hex: item.hex,
                isSelected: isSelected,
                isDisabled: widget.isReadOnly,
                onTap: () => setState(() => _selectedSwatchIndex = index),
              );
            }),
          ),
          if (!widget.isReadOnly) ...<Widget>[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Korekta koloru (${swatchItems[_selectedSwatchIndex].label}):',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _curatedAccentHexes.map((hex) {
                    return _PresetColorDot(
                      color: LiveryColorUtils.parseHex(hex),
                      isSelected: swatchItems[_selectedSwatchIndex]
                              .hex
                              .toUpperCase() ==
                          hex.toUpperCase(),
                      onTap: () => _applyAccentColor(hex),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'WYKOŃCZENIE LAKIERU RAMY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BikePaintFinish.values.map((finish) {
              return _InteractiveChipButton(
                label: finish.label,
                isSelected: _activeFinish == finish,
                isDisabled: widget.isReadOnly,
                onTap: () => setState(() => _activeFinish = finish),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryAndControls({required bool isMobile}) {
    final proposal = widget.proposal;
    final uciCompliant = SpecialEditionLiveryPreviewCalculator.isUciCompliant(
      palette: _activePalette,
      grandTour: proposal.grandTour,
    );
    final netProfit =
        SpecialEditionLiveryPreviewCalculator.computeNetProfitEur(
      proposal: proposal,
      includeMerchDrop: _includeMerchDrop,
    );
    final weightDelta = _activeFinish.weightDeltaGrams;
    final weightLabel =
        weightDelta <= 0 ? '$weightDelta g' : '+$weightDelta g';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildUciComplianceBanner(uciCompliant),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.format_quote_rounded,
                    size: 18,
                    color: AppColors.goldAccent,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'KOMUNIKAT SPONSORA TYTULARNEGO',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                proposal.sponsorPitch,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, gridConstraints) {
            final columns = gridConstraints.maxWidth < 360 ? 2 : 3;
            const spacing = 10.0;
            final tileWidth =
                (gridConstraints.maxWidth - spacing * (columns - 1)) / columns;

            final metrics = <({
              String label,
              String value,
              Color accent,
              IconData icon,
            })>[
              (
                label: 'Zysk Netto',
                value: Formatters.formatCurrency(netProfit),
                accent: netProfit >= 0
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
                icon: Icons.payments_rounded,
              ),
              (
                label: 'Ekspozycja TV',
                value: '×${proposal.mediaExposureMultiplier.toStringAsFixed(2)}',
                accent: AppColors.accentBlue,
                icon: Icons.live_tv_rounded,
              ),
              (
                label: 'Masa Lakieru',
                value: weightLabel,
                accent: weightDelta <= 0
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
                icon: Icons.scale_rounded,
              ),
              (
                label: 'Relacja Sponsora',
                value: '+${proposal.sponsorSatisfactionDelta} pkt',
                accent: AppColors.goldAccent,
                icon: Icons.handshake_rounded,
              ),
              (
                label: 'Morale Ekipy',
                value: '+${proposal.teamMoraleBonus}',
                accent: AppColors.cyanAccent,
                icon: Icons.groups_rounded,
              ),
              (
                label: 'Koszt Produkcji',
                value: Formatters.formatCurrency(
                  _includeMerchDrop
                      ? proposal.productionCostEur
                      : (proposal.productionCostEur * 0.55).round(),
                ),
                accent: AppColors.textSecondary,
                icon: Icons.precision_manufacturing_rounded,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: metrics.map((m) {
                return SizedBox(
                  width: tileWidth,
                  child: _MetricTile(
                    label: m.label,
                    value: m.value,
                    accent: m.accent,
                    icon: m.icon,
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        _MerchDropToggleCard(
          isEnabled: _includeMerchDrop,
          isReadOnly: widget.isReadOnly,
          revenueBonusEur: proposal.merchandiseRevenueBonusEur,
          onChanged: (value) {
            if (widget.isReadOnly) return;
            setState(() => _includeMerchDrop = value);
          },
        ),
      ],
    );
  }

  Widget _buildUciComplianceBanner(bool isCompliant) {
    final grandTour = widget.proposal.grandTour;
    final clashInfo = widget.uciClashResult;
    final statusColor =
        isCompliant ? AppColors.statusSuccess : AppColors.amberWarning;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isCompliant
                ? Icons.verified_rounded
                : Icons.warning_amber_rounded,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isCompliant
                      ? 'Zgodność UCI — brak kolizji z ${grandTour.leaderJerseyName}'
                      : 'Ostrzeżenie UCI — odcień zbliżony do ${grandTour.leaderJerseyName}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  clashInfo?.reason.isNotEmpty == true
                      ? clashInfo!.reason
                      : (isCompliant
                          ? 'Kontrast względem chronionej koszulki lidera spełnia wymogi sędziowskie.'
                          : 'Wybierz inny odcień koszulki głównej przed zatwierdzeniem malowania.'),
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
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: grandTour.uciProtectedColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textPrimary, width: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    final uciCompliant = SpecialEditionLiveryPreviewCalculator.isUciCompliant(
      palette: _activePalette,
      grandTour: widget.proposal.grandTour,
    );
    final canApprove = !widget.isReadOnly && uciCompliant;
    final approveLabel =
        _hasCustomEdits ? 'Zatwierdź własną edycję' : 'Zatwierdź malowanie';
    final approveAction = _hasCustomEdits
        ? SpecialEditionLiveryModalAction.customizedAndApproved
        : SpecialEditionLiveryModalAction.approved;

    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: 12,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ActionButton(
                  label: approveLabel,
                  icon: Icons.check_circle_rounded,
                  isPrimary: true,
                  isDisabled: !canApprove,
                  onTap: () => _submitOutcome(approveAction),
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  label: 'Odrzuć propozycję',
                  icon: Icons.block_rounded,
                  isPrimary: false,
                  isDisabled: widget.isReadOnly,
                  onTap: () =>
                      _submitOutcome(SpecialEditionLiveryModalAction.declined),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                _ActionButton(
                  label: 'Odrzuć propozycję',
                  icon: Icons.block_rounded,
                  isPrimary: false,
                  isDisabled: widget.isReadOnly,
                  onTap: () =>
                      _submitOutcome(SpecialEditionLiveryModalAction.declined),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  label: approveLabel,
                  icon: Icons.check_circle_rounded,
                  isPrimary: true,
                  isDisabled: !canApprove,
                  onTap: () => _submitOutcome(approveAction),
                ),
              ],
            ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TagBadge({required this.label, required this.color});

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
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchDropToggleCard extends StatefulWidget {
  final bool isEnabled;
  final bool isReadOnly;
  final int revenueBonusEur;
  final ValueChanged<bool> onChanged;

  const _MerchDropToggleCard({
    required this.isEnabled,
    required this.isReadOnly,
    required this.revenueBonusEur,
    required this.onChanged,
  });

  @override
  State<_MerchDropToggleCard> createState() => _MerchDropToggleCardState();
}

class _MerchDropToggleCardState extends State<_MerchDropToggleCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? AppColors.goldAccent
        : (_hovered ? AppColors.textSecondary : AppColors.cardBorder);

    return Focus(
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor: widget.isReadOnly
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.isReadOnly
              ? null
              : () => widget.onChanged(!widget.isEnabled),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isEnabled
                  ? AppColors.goldAccent.withValues(alpha: 0.08)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.storefront_rounded,
                  size: 20,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Limitowana kolekcja kibicowska (Merch Drop)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Potencjał sprzedaży: ${Formatters.formatCurrency(widget.revenueBonusEur)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: widget.isEnabled,
                  activeTrackColor: AppColors.goldAccent,
                  onChanged: widget.isReadOnly ? null : widget.onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchButton extends StatefulWidget {
  final String label;
  final String hex;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ColorSwatchButton({
    required this.label,
    required this.hex,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_ColorSwatchButton> createState() => _ColorSwatchButtonState();
}

class _ColorSwatchButtonState extends State<_ColorSwatchButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected || _focused
        ? AppColors.goldAccent
        : (_hovered ? AppColors.textSecondary : AppColors.cardBorder);

    return Focus(
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) {
            if (!widget.isDisabled) setState(() => _pressed = true);
          },
          onTapUp: (_) {
            if (!widget.isDisabled) setState(() => _pressed = false);
          },
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.goldAccent.withValues(alpha: 0.14)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: LiveryColorUtils.parseHex(widget.hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: widget.isDisabled
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
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

class _PresetColorDot extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PresetColorDot> createState() => _PresetColorDotState();
}

class _PresetColorDotState extends State<_PresetColorDot> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isSelected || _focused
                    ? AppColors.goldAccent
                    : (_hovered ? AppColors.textPrimary : AppColors.cardBorder),
                width: widget.isSelected ? 2.2 : 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveChipButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _InteractiveChipButton({
    required this.label,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : (_hovered ? AppColors.surface : AppColors.background);
    final borderColor = widget.isSelected || _focused
        ? AppColors.goldAccent
        : (_hovered ? AppColors.textSecondary : AppColors.cardBorder);

    return Opacity(
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: Focus(
        onFocusChange: (val) => setState(() => _focused = val),
        child: MouseRegion(
          cursor: widget.isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) {
              if (!widget.isDisabled) setState(() => _pressed = true);
            },
            onTapUp: (_) {
              if (!widget.isDisabled) setState(() => _pressed = false);
            },
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.isDisabled ? null : widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveTextAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _InteractiveTextAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_InteractiveTextAction> createState() => _InteractiveTextActionState();
}

class _InteractiveTextActionState extends State<_InteractiveTextAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 14,
                color:
                    _hovered ? AppColors.goldAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      _hovered ? AppColors.goldAccent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _InteractiveIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
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
      child: Focus(
        onFocusChange: (val) => setState(() => _focused = val),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: _hovered
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary
        ? (_hovered
            ? AppColors.primaryAccent.withValues(alpha: 0.92)
            : AppColors.primaryAccent)
        : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isPrimary ? AppColors.goldAccent : AppColors.cardBorder);

    return Opacity(
      opacity: widget.isDisabled ? 0.45 : 1.0,
      child: Focus(
        onFocusChange: (val) => setState(() => _focused = val),
        child: MouseRegion(
          cursor: widget.isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: (_) {
              if (!widget.isDisabled) setState(() => _pressed = true);
            },
            onTapUp: (_) {
              if (!widget.isDisabled) setState(() => _pressed = false);
            },
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.isDisabled ? null : widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
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
            ),
          ),
        ),
      ),
    );
  }
}
