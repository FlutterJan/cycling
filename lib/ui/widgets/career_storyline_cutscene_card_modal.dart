// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/custom_team_sponsor_storyline_generator.dart';

/// Typ sceny wektorowej renderowanej na filmowej karcie wydarzenia fabularnego.
enum CutsceneIllustrationScene {
  alpineDuel,
  pressStorm,
  medicalComeback,
  dynastyTrophy,
  sponsorBoardroom,
  cobbleClassic;

  String toJson() => name;

  static CutsceneIllustrationScene fromJson(String value) {
    return CutsceneIllustrationScene.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CutsceneIllustrationScene.alpineDuel,
    );
  }

  static CutsceneIllustrationScene fromArchetype(StorylineArchetype archetype) {
    switch (archetype) {
      case StorylineArchetype.billionaireRivalry:
        return CutsceneIllustrationScene.sponsorBoardroom;
      case StorylineArchetype.nationalHomeRacePressure:
        return CutsceneIllustrationScene.pressStorm;
      case StorylineArchetype.fallenChampionComeback:
        return CutsceneIllustrationScene.medicalComeback;
      case StorylineArchetype.historicDynastyBuilder:
        return CutsceneIllustrationScene.dynastyTrophy;
    }
  }
}

/// Kompletny model danych pojedynczej filmowej karty wydarzenia fabularnego.
class CareerStorylineCutsceneCardData {
  final String id;
  final StorylineArchetype archetype;
  final StorylineTone tone;
  final CutsceneIllustrationScene sceneType;
  final int seasonYear;
  final int chapterNumber;
  final int totalChapters;
  final String title;
  final String subtitle;
  final String narrativeBody;
  final String pressQuote;
  final String pressSource;
  final String pressHeadline;
  final String longTermGoalTitle;
  final double longTermGoalProgress;
  final int currentBudgetEur;
  final List<StorylineDecisionOption> options;
  final String? preselectedOptionId;

  const CareerStorylineCutsceneCardData({
    required this.id,
    required this.archetype,
    this.tone = StorylineTone.dramatic,
    required this.sceneType,
    required this.seasonYear,
    required this.chapterNumber,
    required this.totalChapters,
    required this.title,
    required this.subtitle,
    required this.narrativeBody,
    required this.pressQuote,
    required this.pressSource,
    required this.pressHeadline,
    required this.longTermGoalTitle,
    this.longTermGoalProgress = 0.0,
    required this.currentBudgetEur,
    required this.options,
    this.preselectedOptionId,
  });

  double get clampedGoalProgress =>
      longTermGoalProgress.isNaN ? 0.0 : longTermGoalProgress.clamp(0.0, 1.0);

  String get chapterBadge =>
      'ROZDZIAŁ $chapterNumber/${math.max(1, totalChapters)} • SEZON $seasonYear';

  /// Tworzy kartę filmową bezpośrednio z rozdziału wygenerowanego przez
  /// [CustomTeamSponsorStorylineGenerator].
  factory CareerStorylineCutsceneCardData.fromStorylineChapter({
    required CareerStorylineArc arc,
    required StorylineChapter chapter,
    required int currentBudgetEur,
    CutsceneIllustrationScene? overrideScene,
  }) {
    final total = math.max(1, arc.chapters.length);
    return CareerStorylineCutsceneCardData(
      id: '${arc.id}_ch_${chapter.chapterIndex}',
      archetype: arc.archetype,
      tone: arc.tone,
      sceneType:
          overrideScene ?? CutsceneIllustrationScene.fromArchetype(arc.archetype),
      seasonYear: arc.seasonStart + chapter.seasonYearOffset,
      chapterNumber: chapter.chapterIndex,
      totalChapters: total,
      title: chapter.title,
      subtitle: '${chapter.targetRaceName} • ${chapter.targetMilestone}',
      narrativeBody: chapter.narrativeBody,
      pressQuote: chapter.pressQuote,
      pressSource: chapter.pressSource,
      pressHeadline: chapter.headline,
      longTermGoalTitle: arc.subtitle.isNotEmpty ? arc.subtitle : arc.title,
      longTermGoalProgress: arc.completionRatio,
      currentBudgetEur: currentBudgetEur,
      options: chapter.options,
      preselectedOptionId: chapter.selectedOptionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'archetype': archetype.toJson(),
      'tone': tone.toJson(),
      'sceneType': sceneType.toJson(),
      'seasonYear': seasonYear,
      'chapterNumber': chapterNumber,
      'totalChapters': totalChapters,
      'title': title,
      'subtitle': subtitle,
      'narrativeBody': narrativeBody,
      'pressQuote': pressQuote,
      'pressSource': pressSource,
      'pressHeadline': pressHeadline,
      'longTermGoalTitle': longTermGoalTitle,
      'longTermGoalProgress': longTermGoalProgress,
      'currentBudgetEur': currentBudgetEur,
      'options': options.map((o) => o.toJson()).toList(),
      'preselectedOptionId': preselectedOptionId,
    };
  }

  factory CareerStorylineCutsceneCardData.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>?) ?? const [];
    return CareerStorylineCutsceneCardData(
      id: (json['id'] as String?) ?? '',
      archetype: StorylineArchetype.fromJson(
        (json['archetype'] as String?) ?? 'billionaireRivalry',
      ),
      tone: StorylineTone.fromJson((json['tone'] as String?) ?? 'dramatic'),
      sceneType: CutsceneIllustrationScene.fromJson(
        (json['sceneType'] as String?) ?? 'alpineDuel',
      ),
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      chapterNumber: (json['chapterNumber'] as num?)?.toInt() ?? 1,
      totalChapters: (json['totalChapters'] as num?)?.toInt() ?? 3,
      title: (json['title'] as String?) ?? '',
      subtitle: (json['subtitle'] as String?) ?? '',
      narrativeBody: (json['narrativeBody'] as String?) ?? '',
      pressQuote: (json['pressQuote'] as String?) ?? '',
      pressSource: (json['pressSource'] as String?) ?? '',
      pressHeadline: (json['pressHeadline'] as String?) ?? '',
      longTermGoalTitle: (json['longTermGoalTitle'] as String?) ?? '',
      longTermGoalProgress:
          (json['longTermGoalProgress'] as num?)?.toDouble() ?? 0.0,
      currentBudgetEur: (json['currentBudgetEur'] as num?)?.toInt() ?? 0,
      options: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(StorylineDecisionOption.fromJson)
          .toList(),
      preselectedOptionId: json['preselectedOptionId'] as String?,
    );
  }
}

/// Wynik wyboru strategicznego podjętego na karcie wydarzenia fabularnego.
class CareerStorylineCutsceneResult {
  final String cardId;
  final StorylineDecisionOption selectedOption;
  final int previousBudgetEur;
  final int updatedBudgetEur;
  final DateTime decidedAt;

  const CareerStorylineCutsceneResult({
    required this.cardId,
    required this.selectedOption,
    required this.previousBudgetEur,
    required this.updatedBudgetEur,
    required this.decidedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'selectedOption': selectedOption.toJson(),
      'previousBudgetEur': previousBudgetEur,
      'updatedBudgetEur': updatedBudgetEur,
      'decidedAt': decidedAt.toIso8601String(),
    };
  }

  factory CareerStorylineCutsceneResult.fromJson(Map<String, dynamic> json) {
    final prev = (json['previousBudgetEur'] as num?)?.toInt() ?? 0;
    final option = StorylineDecisionOption.fromJson(
      (json['selectedOption'] as Map<String, dynamic>?) ?? const {},
    );
    return CareerStorylineCutsceneResult(
      cardId: (json['cardId'] as String?) ?? '',
      selectedOption: option,
      previousBudgetEur: prev,
      updatedBudgetEur: (json['updatedBudgetEur'] as num?)?.toInt() ??
          (prev + option.effect.budgetDeltaEur),
      decidedAt: DateTime.tryParse((json['decidedAt'] as String?) ?? '') ??
          DateTime(2026),
    );
  }
}

/// Zestaw gotowych scenek fabularnych do podglądu i szybkiego testowania.
class CareerStorylineCutsceneCatalog {
  CareerStorylineCutsceneCatalog._();

  static CareerStorylineCutsceneCardData billionaireRivalrySample({
    int currentBudgetEur = 2400000,
  }) {
    return CareerStorylineCutsceneCardData(
      id: 'story_billionaire_ch1',
      archetype: StorylineArchetype.billionaireRivalry,
      tone: StorylineTone.dramatic,
      sceneType: CutsceneIllustrationScene.alpineDuel,
      seasonYear: 2026,
      chapterNumber: 1,
      totalChapters: 3,
      title: 'Rękawica Rzucona w Alpach',
      subtitle: 'Critérium du Dauphiné • Top 3 Klasyfikacji Generalnej',
      narrativeBody:
          'Właściciel konkurencyjnej ekipy Apex Energy publicznie zakwestionował nasz projekt aero na konferencji w Grenoble. Sponsor tytularny oczekuje zdecydowanej odpowiedzi na trasie lub przy stole negocjacyjnym przed lipcowym Tour de France.',
      pressQuote:
          '„Jeśli ich dyrektor sportowy myśli, że kupi żółtą koszulkę samymi wykresami z tunelu, to na Col de la Loze zderzy się ze ścianą.”',
      pressSource: "L'ÉQUIPE",
      pressHeadline: 'WOJNA O DOMINACJĘ W WORLDTOUR ROZPOCZĘTA',
      longTermGoalTitle: 'Pokonać Apex Energy w Tour de France 2026–2028',
      longTermGoalProgress: 0.34,
      currentBudgetEur: currentBudgetEur,
      options: const [
        StorylineDecisionOption(
          id: 'opt_aero_blitz',
          title: 'Ekspresowy pakiet R&D i obóz na Teneryfie',
          description:
              'Zainwestuj rezerwę finansową w natychmiastowe testy tunelowe nowej kierownicy TT oraz 18-dniowe zgrupowanie liderów na Teide.',
          strategicTag: 'INWESTYCJA AERO',
          requiresMinBudgetEur: 450000,
          effect: StorylineChoiceEffect(
            budgetDeltaEur: -450000,
            sponsorSatisfactionDelta: 9.5,
            teamMoraleDelta: 6.0,
            prestigeDelta: 25,
            dynastyPointsDelta: 15,
            heatDelta: 8.0,
            outcomeSummary:
                'Liderzy zyskują przewagę sprzętową przed lipcem, a sponsor docenia bezkompromisową ambicję.',
          ),
        ),
        StorylineDecisionOption(
          id: 'opt_media_counter',
          title: 'Kontrofensywa medialna i premia dla sponsora',
          description:
              'Zorganizuj ekskluzywny dzień mediowy dla prasy międzynarodowej i przekieruj uwagę na młodych wychowanków ekipy.',
          strategicTag: 'DYPLOMACJA PR',
          requiresMinBudgetEur: 0,
          effect: StorylineChoiceEffect(
            budgetDeltaEur: 180000,
            sponsorSatisfactionDelta: 5.0,
            teamMoraleDelta: 2.5,
            prestigeDelta: 10,
            dynastyPointsDelta: 8,
            heatDelta: 4.0,
            outcomeSummary:
                'Dodatkowy pakiet ekspozycji w mediach zasila kasę klubu i stabilizuje relacje ze sponsorem.',
          ),
        ),
        StorylineDecisionOption(
          id: 'opt_silent_focus',
          title: 'Cisza przed burzą — pełna ochrona budżetu',
          description:
              'Odrzuć wojnę na słowa i zamroź wydatki do okna transferowego, stawiając na konserwatywną taktykę w górach.',
          strategicTag: 'OSZCZĘDNOŚĆ',
          requiresMinBudgetEur: 0,
          effect: StorylineChoiceEffect(
            budgetDeltaEur: 0,
            sponsorSatisfactionDelta: -3.5,
            teamMoraleDelta: -2.0,
            prestigeDelta: -5,
            dynastyPointsDelta: 2,
            heatDelta: -4.0,
            outcomeSummary:
                'Budżet pozostaje nienaruszony, lecz prasa i sponsor zarzucają drużynie brak odwagi.',
          ),
        ),
      ],
    );
  }
}

/// Wyświetla filmowy modal wydarzenia fabularnego i zwraca podjętą decyzję.
Future<CareerStorylineCutsceneResult?> showCareerStorylineCutsceneCardModal(
  BuildContext context, {
  required CareerStorylineCutsceneCardData data,
  bool isReadOnly = false,
  bool barrierDismissible = true,
}) {
  return showDialog<CareerStorylineCutsceneResult>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (dialogContext) {
      return CareerStorylineCutsceneCardModal(
        data: data,
        isReadOnly: isReadOnly,
        onDecisionConfirmed: (result) {
          Navigator.of(dialogContext).pop(result);
        },
        onClose: () {
          Navigator.of(dialogContext).pop();
        },
      );
    },
  );
}

/// Filmowa karta wydarzenia fabularnego kariery z ilustracjami wektorowymi,
/// cytatami z prasy sportowej oraz wyborami strategicznymi wpływającymi
/// na budżet i cele długoterminowe drużyny.
class CareerStorylineCutsceneCardModal extends StatefulWidget {
  final CareerStorylineCutsceneCardData data;
  final ValueChanged<CareerStorylineCutsceneResult>? onDecisionConfirmed;
  final VoidCallback? onClose;
  final bool isReadOnly;

  const CareerStorylineCutsceneCardModal({
    super.key,
    required this.data,
    this.onDecisionConfirmed,
    this.onClose,
    this.isReadOnly = false,
  });

  @override
  State<CareerStorylineCutsceneCardModal> createState() =>
      _CareerStorylineCutsceneCardModalState();
}

class _CareerStorylineCutsceneCardModalState
    extends State<CareerStorylineCutsceneCardModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  String? _selectedOptionId;
  bool _closeHovered = false;
  bool _confirmHovered = false;
  bool _confirmFocused = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _selectedOptionId = _resolveInitialSelectionId();
    _entranceController.forward();
  }

  @override
  void didUpdateWidget(covariant CareerStorylineCutsceneCardModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.id != widget.data.id ||
        oldWidget.data.preselectedOptionId != widget.data.preselectedOptionId) {
      _selectedOptionId = _resolveInitialSelectionId();
    }
  }

  String? _resolveInitialSelectionId() {
    if (widget.data.preselectedOptionId != null) {
      final exists = widget.data.options
          .any((o) => o.id == widget.data.preselectedOptionId);
      if (exists) return widget.data.preselectedOptionId;
    }
    return null;
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  StorylineDecisionOption? get _selectedOption {
    if (_selectedOptionId == null) return null;
    for (final option in widget.data.options) {
      if (option.id == _selectedOptionId) return option;
    }
    return null;
  }

  bool get _canConfirm {
    if (widget.isReadOnly) return false;
    final option = _selectedOption;
    if (option == null) return false;
    return option.isAffordable(widget.data.currentBudgetEur);
  }

  void _handleConfirm() {
    if (!_canConfirm) return;
    final option = _selectedOption!;
    final result = CareerStorylineCutsceneResult(
      cardId: widget.data.id,
      selectedOption: option,
      previousBudgetEur: widget.data.currentBudgetEur,
      updatedBudgetEur:
          widget.data.currentBudgetEur + option.effect.budgetDeltaEur,
      decidedAt: DateTime.now(),
    );
    widget.onDecisionConfirmed?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.data.archetype.accentColor;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          widget.onClose?.call();
        },
      },
      child: FocusScope(
        autofocus: true,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                final viewportHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : MediaQuery.sizeOf(context).height;

                final isCompact = viewportWidth < 900;
                final horizontalMargin = viewportWidth < 480 ? 12.0 : 28.0;
                final verticalMargin = viewportHeight < 700 ? 12.0 : 24.0;
                final maxDialogWidth = math.min(
                  1120.0,
                  math.max(300.0, viewportWidth - horizontalMargin * 2),
                );
                final maxDialogHeight = math.max(
                  360.0,
                  viewportHeight - verticalMargin * 2,
                );

                return Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: maxDialogWidth,
                      constraints: BoxConstraints(maxHeight: maxDialogHeight),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2A2F3D),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: accent.withValues(alpha: 0.12),
                            blurRadius: 24,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTopCinemaBar(accent, isCompact),
                          Flexible(
                            child: isCompact
                                ? _buildMobileLayout(accent)
                                : _buildDesktopLayout(accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCinemaBar(Color accent, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.data.archetype.icon,
                  size: 14,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.data.archetype.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.data.chapterBadge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (!isCompact) ...[
            _BudgetPill(
              label: 'BUDŻET',
              amountEur: widget.data.currentBudgetEur,
              projectedAmountEur: _selectedOption != null
                  ? widget.data.currentBudgetEur +
                      _selectedOption!.effect.budgetDeltaEur
                  : null,
            ),
            const SizedBox(width: 12),
          ],
          MouseRegion(
            cursor: widget.onClose != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _closeHovered = true),
            onExit: (_) => setState(() => _closeHovered = false),
            child: InkWell(
              key: const Key('cutscene_close_button'),
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _closeHovered
                      ? AppColors.surfaceLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _closeHovered
                        ? AppColors.goldAccent.withValues(alpha: 0.5)
                        : const Color(0xFF2A2F3D),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIllustrationBanner(accent, height: 210),
                  const SizedBox(height: 16),
                  _PressQuoteGazetteCard(
                    pressSource: widget.data.pressSource,
                    pressHeadline: widget.data.pressHeadline,
                    pressQuote: widget.data.pressQuote,
                    accentColor: accent,
                  ),
                  const SizedBox(height: 16),
                  _LongTermGoalCard(
                    goalTitle: widget.data.longTermGoalTitle,
                    progress: widget.data.clampedGoalProgress,
                    accentColor: accent,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNarrativeHeader(accent),
                      const SizedBox(height: 16),
                      _buildOptionsSection(accent),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    top: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
                  ),
                ),
                child: _buildActionFooter(accent, isCompact: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIllustrationBanner(accent, height: 168),
          const SizedBox(height: 12),
          _BudgetPill(
            label: 'BUDŻET DRUŻYNY',
            amountEur: widget.data.currentBudgetEur,
            projectedAmountEur: _selectedOption != null
                ? widget.data.currentBudgetEur +
                    _selectedOption!.effect.budgetDeltaEur
                : null,
          ),
          const SizedBox(height: 12),
          _buildNarrativeHeader(accent),
          const SizedBox(height: 14),
          _PressQuoteGazetteCard(
            pressSource: widget.data.pressSource,
            pressHeadline: widget.data.pressHeadline,
            pressQuote: widget.data.pressQuote,
            accentColor: accent,
          ),
          const SizedBox(height: 14),
          _LongTermGoalCard(
            goalTitle: widget.data.longTermGoalTitle,
            progress: widget.data.clampedGoalProgress,
            accentColor: accent,
          ),
          const SizedBox(height: 16),
          _buildOptionsSection(accent),
          const SizedBox(height: 16),
          _buildActionFooter(accent, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildIllustrationBanner(Color accent, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: StorylineCutsceneVectorPainter(
              sceneType: widget.data.sceneType,
              accentColor: accent,
              tone: widget.data.tone,
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
              ),
              child: const Text(
                'WYDARZENIE FABULARNE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.goldAccent,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Text(
              widget.data.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeHeader(Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.data.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.data.narrativeBody,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              height: 1.5,
              letterSpacing: -0.1,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(Color accent) {
    if (widget.data.options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Brak dostępnych decyzji strategicznych dla tego rozdziału.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'DECYZJE STRATEGICZNE',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ...widget.data.options.map((option) {
          final isSelected = option.id == _selectedOptionId;
          final isAffordable = option.isAffordable(widget.data.currentBudgetEur);
          final isDisabled = widget.isReadOnly || !isAffordable;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StrategicDecisionOptionCard(
              option: option,
              isSelected: isSelected,
              isDisabled: isDisabled,
              isAffordable: isAffordable,
              accentColor: accent,
              onTap: isDisabled
                  ? null
                  : () {
                      setState(() {
                        _selectedOptionId = option.id;
                      });
                    },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionFooter(Color accent, {required bool isCompact}) {
    final selected = _selectedOption;
    final canConfirm = _canConfirm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected != null) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selected.effect.outcomeSummary,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Focus(
          onFocusChange: (focused) {
            if (_confirmFocused != focused) {
              setState(() => _confirmFocused = focused);
            }
          },
          child: MouseRegion(
            cursor: canConfirm
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            onEnter: (_) => setState(() => _confirmHovered = true),
            onExit: (_) => setState(() => _confirmHovered = false),
            child: GestureDetector(
              key: const Key('cutscene_confirm_button'),
              onTap: canConfirm ? _handleConfirm : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: isCompact ? 13 : 14,
                ),
                decoration: BoxDecoration(
                  color: !canConfirm
                      ? AppColors.surfaceLight
                      : _confirmHovered
                          ? AppColors.goldAccent
                          : AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _confirmFocused
                        ? AppColors.cyanAccent
                        : canConfirm
                            ? AppColors.goldAccent.withValues(alpha: 0.7)
                            : const Color(0xFF2A2F3D),
                    width: _confirmFocused ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isReadOnly
                          ? Icons.lock_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: !canConfirm
                          ? AppColors.textSecondary
                          : _confirmHovered
                              ? AppColors.background
                              : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.isReadOnly
                            ? 'TRYB PODGLĄDU ARCHIWUM'
                            : selected == null
                                ? 'WYBIERZ DECYZJĘ STRATEGICZNĄ'
                                : 'ZATWIERDŹ DECYZJĘ STRATEGICZNĄ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: !canConfirm
                              ? AppColors.textSecondary
                              : _confirmHovered
                                  ? AppColors.background
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetPill extends StatelessWidget {
  final String label;
  final int amountEur;
  final int? projectedAmountEur;

  const _BudgetPill({
    required this.label,
    required this.amountEur,
    this.projectedAmountEur,
  });

  @override
  Widget build(BuildContext context) {
    final hasProjection =
        projectedAmountEur != null && projectedAmountEur != amountEur;
    final isPositiveDelta =
        hasProjection && (projectedAmountEur! - amountEur) > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 14,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            Formatters.formatCompactCurrency(amountEur),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (hasProjection) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 12,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              Formatters.formatCompactCurrency(projectedAmountEur!),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPositiveDelta
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PressQuoteGazetteCard extends StatelessWidget {
  final String pressSource;
  final String pressHeadline;
  final String pressQuote;
  final Color accentColor;

  const _PressQuoteGazetteCard({
    required this.pressSource,
    required this.pressHeadline,
    required this.pressQuote,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.newspaper_rounded,
                      size: 13,
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      pressSource.isEmpty ? 'PRASA SPORTOWA' : pressSource,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pressHeadline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accentColor, width: 2.5),
              ),
            ),
            child: Text(
              pressQuote,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LongTermGoalCard extends StatelessWidget {
  final String goalTitle;
  final double progress;
  final Color accentColor;

  const _LongTermGoalCard({
    required this.goalTitle,
    required this.progress,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_circle_rounded, size: 16, color: accentColor),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'CEL DŁUGOTERMINOWY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            goalTitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrategicDecisionOptionCard extends StatefulWidget {
  final StorylineDecisionOption option;
  final bool isSelected;
  final bool isDisabled;
  final bool isAffordable;
  final Color accentColor;
  final VoidCallback? onTap;

  const _StrategicDecisionOptionCard({
    required this.option,
    required this.isSelected,
    required this.isDisabled,
    required this.isAffordable,
    required this.accentColor,
    this.onTap,
  });

  @override
  State<_StrategicDecisionOptionCard> createState() =>
      _StrategicDecisionOptionCardState();
}

class _StrategicDecisionOptionCardState
    extends State<_StrategicDecisionOptionCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDisabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.6)
        : widget.isSelected
            ? AppColors.goldAccent
            : _focused
                ? AppColors.cyanAccent
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.8)
                    : const Color(0xFF2A2F3D);

    final backgroundColor = widget.isDisabled
        ? AppColors.background.withValues(alpha: 0.65)
        : widget.isSelected
            ? AppColors.goldAccent.withValues(alpha: 0.1)
            : _pressed
                ? AppColors.surfaceLight.withValues(alpha: 0.9)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background;

    return Focus(
      canRequestFocus: !widget.isDisabled,
      onFocusChange: (focused) {
        if (_focused != focused) setState(() => _focused = focused);
      },
      onKeyEvent: (node, event) {
        if (!widget.isDisabled &&
            event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          key: Key('cutscene_option_${widget.option.id}'),
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _pressed = true),
          onTapUp: widget.isDisabled
              ? null
              : (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _focused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: widget.isDisabled ? 0.55 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.option.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? AppColors.goldAccent.withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: widget.isSelected
                                ? AppColors.goldAccent
                                : const Color(0xFF2A2F3D),
                          ),
                        ),
                        child: Text(
                          widget.isSelected
                              ? 'WYBRANO'
                              : widget.option.strategicTag,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: widget.isSelected
                                ? AppColors.goldAccent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.option.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _buildImpactChips(),
                  ),
                  if (!widget.isAffordable) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: AppColors.crimsonAlert,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Wymagany budżet: ${Formatters.formatCompactCurrency(widget.option.requiresMinBudgetEur)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.crimsonAlert,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildImpactChips() {
    final effect = widget.option.effect;
    final chips = <Widget>[];

    if (effect.budgetDeltaEur != 0) {
      final isGain = effect.budgetDeltaEur > 0;
      final prefix = isGain ? '+' : '';
      chips.add(
        _ImpactChip(
          icon: Icons.euro_rounded,
          label:
              '$prefix${Formatters.formatCompactCurrency(effect.budgetDeltaEur)}',
          color: isGain ? AppColors.statusSuccess : AppColors.amberWarning,
        ),
      );
    }

    if (effect.sponsorSatisfactionDelta != 0) {
      final isGain = effect.sponsorSatisfactionDelta > 0;
      final val = effect.sponsorSatisfactionDelta.toStringAsFixed(1);
      chips.add(
        _ImpactChip(
          icon: Icons.handshake_outlined,
          label: '${isGain ? '+' : ''}$val% Sponsor',
          color: isGain ? AppColors.accentBlue : AppColors.crimsonAlert,
        ),
      );
    }

    if (effect.teamMoraleDelta != 0) {
      final isGain = effect.teamMoraleDelta > 0;
      final val = effect.teamMoraleDelta.toStringAsFixed(1);
      chips.add(
        _ImpactChip(
          icon: Icons.favorite_outline_rounded,
          label: '${isGain ? '+' : ''}$val Morale',
          color: isGain ? AppColors.statusSuccess : AppColors.crimsonAlert,
        ),
      );
    }

    if (effect.prestigeDelta != 0) {
      final isGain = effect.prestigeDelta > 0;
      chips.add(
        _ImpactChip(
          icon: Icons.star_outline_rounded,
          label: '${isGain ? '+' : ''}${effect.prestigeDelta} Prestiż',
          color: isGain ? AppColors.goldAccent : AppColors.crimsonAlert,
        ),
      );
    }

    if (effect.dynastyPointsDelta != 0) {
      final isGain = effect.dynastyPointsDelta > 0;
      chips.add(
        _ImpactChip(
          icon: Icons.emoji_events_outlined,
          label: '${isGain ? '+' : ''}${effect.dynastyPointsDelta} Dynastia',
          color: AppColors.goldAccent,
        ),
      );
    }

    return chips;
  }
}

class _ImpactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ImpactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dedykowany painter wektorowych ilustracji filmowych dla kart fabularnych.
class StorylineCutsceneVectorPainter extends CustomPainter {
  final CutsceneIllustrationScene sceneType;
  final Color accentColor;
  final StorylineTone tone;

  const StorylineCutsceneVectorPainter({
    required this.sceneType,
    required this.accentColor,
    required this.tone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Kinematograficzne tło z radialnym światłem
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          accentColor.withValues(alpha: 0.22),
          const Color(0xFF141821),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Scena tematyczna
    switch (sceneType) {
      case CutsceneIllustrationScene.alpineDuel:
        _paintAlpineDuel(canvas, size);
      case CutsceneIllustrationScene.pressStorm:
        _paintPressStorm(canvas, size);
      case CutsceneIllustrationScene.medicalComeback:
        _paintMedicalComeback(canvas, size);
      case CutsceneIllustrationScene.dynastyTrophy:
        _paintDynastyTrophy(canvas, size);
      case CutsceneIllustrationScene.sponsorBoardroom:
        _paintSponsorBoardroom(canvas, size);
      case CutsceneIllustrationScene.cobbleClassic:
        _paintCobbleClassic(canvas, size);
    }

    // 3. Kinowe pasy letterbox góra/dół oraz dolny gradient czytelności napisów
    final bottomScrim = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.background.withValues(alpha: 0.88),
        ],
        stops: const [0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bottomScrim);
  }

  void _paintAlpineDuel(Canvas canvas, Size size) {
    final mountainBack = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width * 0.22, size.height * 0.34)
      ..lineTo(size.width * 0.44, size.height * 0.62)
      ..lineTo(size.width * 0.70, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.56)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      mountainBack,
      Paint()..color = const Color(0xFF1C2230),
    );

    // Kręta droga podjazdowa
    final roadPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final road = Path()
      ..moveTo(size.width * 0.08, size.height * 0.86)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.78,
        size.width * 0.55,
        size.height * 0.56,
        size.width * 0.74,
        size.height * 0.36,
      );
    canvas.drawPath(road, roadPaint);

    // Dwaj kolarze wektorowi na podjeździe
    _drawCyclistSilhouette(
      canvas,
      Offset(size.width * 0.56, size.height * 0.60),
      1.0,
      AppColors.goldAccent,
    );
    _drawCyclistSilhouette(
      canvas,
      Offset(size.width * 0.46, size.height * 0.66),
      0.88,
      accentColor,
    );
  }

  void _paintPressStorm(Canvas canvas, Size size) {
    // Promienie fleszy fotoreporterów
    final flashCenter = Offset(size.width * 0.76, size.height * 0.26);
    for (int i = 0; i < 6; i++) {
      final angle = -math.pi * 0.9 + i * 0.28;
      final end = Offset(
        flashCenter.dx + math.cos(angle) * size.width * 0.7,
        flashCenter.dy + math.sin(angle) * size.height * 0.8,
      );
      canvas.drawLine(
        flashCenter,
        end,
        Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.14)
          ..strokeWidth = 14,
      );
    }

    // Stylizowana okładka gazety sportowej
    final pageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.24,
        size.width * 0.44,
        size.height * 0.58,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(pageRect, Paint()..color = const Color(0xFF1F2430));
    canvas.drawRRect(
      pageRect,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Linie tekstu na okładce
    final linePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.45)
      ..strokeWidth = 3;
    for (int row = 0; row < 4; row++) {
      final y = size.height * (0.36 + row * 0.09);
      canvas.drawLine(
        Offset(size.width * 0.16, y),
        Offset(size.width * (row == 0 ? 0.50 : 0.44), y),
        linePaint,
      );
    }
  }

  void _paintMedicalComeback(Canvas canvas, Size size) {
    // Siatka EKG
    final gridPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Fala EKG przechodząca w szczyt górski
    final ecg = Path()
      ..moveTo(0, size.height * 0.60)
      ..lineTo(size.width * 0.22, size.height * 0.60)
      ..lineTo(size.width * 0.28, size.height * 0.42)
      ..lineTo(size.width * 0.34, size.height * 0.72)
      ..lineTo(size.width * 0.42, size.height * 0.28)
      ..lineTo(size.width * 0.50, size.height * 0.64)
      ..lineTo(size.width * 0.64, size.height * 0.52)
      ..lineTo(size.width * 0.78, size.height * 0.34)
      ..lineTo(size.width, size.height * 0.55);

    canvas.drawPath(
      ecg,
      Paint()
        ..color = AppColors.statusSuccess
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );

    _drawCyclistSilhouette(
      canvas,
      Offset(size.width * 0.78, size.height * 0.34),
      0.95,
      AppColors.goldAccent,
    );
  }

  void _paintDynastyTrophy(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.48);

    // Promienie chwały
    for (int i = 0; i < 8; i++) {
      final angle = -math.pi + (i / 7) * math.pi;
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle) * size.width * 0.55,
          center.dy + math.sin(angle) * size.height * 0.6,
        ),
        Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.14)
          ..strokeWidth = 10,
      );
    }

    // Wektorowy puchar mistrzowski
    final cupPaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    final cupPath = Path()
      ..moveTo(center.dx - 26, center.dy - 26)
      ..lineTo(center.dx + 26, center.dy - 26)
      ..quadraticBezierTo(
        center.dx + 22,
        center.dy + 8,
        center.dx,
        center.dy + 14,
      )
      ..quadraticBezierTo(
        center.dx - 22,
        center.dy + 8,
        center.dx - 26,
        center.dy - 26,
      );
    canvas.drawPath(cupPath, cupPaint);
    canvas.drawLine(
      Offset(center.dx, center.dy + 14),
      Offset(center.dx, center.dy + 34),
      cupPaint,
    );
    canvas.drawLine(
      Offset(center.dx - 18, center.dy + 34),
      Offset(center.dx + 18, center.dy + 34),
      cupPaint,
    );
  }

  void _paintSponsorBoardroom(Canvas canvas, Size size) {
    // Wykres wzrostu budżetu i ekspozycji w tle
    final chart = Path()
      ..moveTo(size.width * 0.10, size.height * 0.72)
      ..lineTo(size.width * 0.28, size.height * 0.64)
      ..lineTo(size.width * 0.46, size.height * 0.68)
      ..lineTo(size.width * 0.66, size.height * 0.42)
      ..lineTo(size.width * 0.88, size.height * 0.26);

    canvas.drawPath(
      chart,
      Paint()
        ..color = AppColors.accentBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );

    // Tarcza zespołu
    final shieldCenter = Offset(size.width * 0.72, size.height * 0.50);
    final shield = Path()
      ..moveTo(shieldCenter.dx, shieldCenter.dy - 28)
      ..lineTo(shieldCenter.dx + 24, shieldCenter.dy - 16)
      ..lineTo(shieldCenter.dx + 18, shieldCenter.dy + 16)
      ..lineTo(shieldCenter.dx, shieldCenter.dy + 30)
      ..lineTo(shieldCenter.dx - 18, shieldCenter.dy + 16)
      ..lineTo(shieldCenter.dx - 24, shieldCenter.dy - 16)
      ..close();
    canvas.drawPath(
      shield,
      Paint()..color = AppColors.surfaceLight.withValues(alpha: 0.9),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..color = AppColors.goldAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _paintCobbleClassic(Canvas canvas, Size size) {
    // Perspektywa brukowanego sektora
    final cobblePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int row = 0; row < 5; row++) {
      final y = size.height * (0.48 + row * 0.09);
      final spread = 0.2 + row * 0.12;
      canvas.drawLine(
        Offset(size.width * (0.5 - spread), y),
        Offset(size.width * (0.5 + spread), y),
        cobblePaint,
      );
    }

    _drawCyclistSilhouette(
      canvas,
      Offset(size.width * 0.52, size.height * 0.56),
      1.05,
      AppColors.goldAccent,
    );
  }

  void _drawCyclistSilhouette(
    Canvas canvas,
    Offset wheelCenter,
    double scale,
    Color color,
  ) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale
      ..strokeCap = StrokeCap.round;

    final r = 9.0 * scale;
    final rear = Offset(wheelCenter.dx - 13 * scale, wheelCenter.dy);
    final front = Offset(wheelCenter.dx + 13 * scale, wheelCenter.dy);
    canvas.drawCircle(rear, r, stroke);
    canvas.drawCircle(front, r, stroke);

    final saddle = Offset(wheelCenter.dx - 5 * scale, wheelCenter.dy - 14 * scale);
    final bars = Offset(wheelCenter.dx + 10 * scale, wheelCenter.dy - 14 * scale);
    canvas.drawLine(rear, saddle, stroke);
    canvas.drawLine(saddle, bars, stroke);
    canvas.drawLine(bars, front, stroke);
    canvas.drawCircle(
      Offset(wheelCenter.dx + 6 * scale, wheelCenter.dy - 24 * scale),
      4.2 * scale,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant StorylineCutsceneVectorPainter oldDelegate) {
    return oldDelegate.sceneType != sceneType ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.tone != tone;
  }
}
