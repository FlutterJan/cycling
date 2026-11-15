// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../../services/career/press_conference_service.dart';

/// Okno modalne oficjalnej Konferencji Prasowej UCI i wywiadów z mediami
/// (Press Interview Modal).
///
/// Prezentuje autentyczną atmosferę sali prasowej Grand Touru:
/// 1. **Ścianka sponsorska (Sponsor Backdrop Wall)** z logotypami sponsorów drużyny,
///    producenta rowerów i organizatora wyścigu (step-and-repeat pattern).
/// 2. **Stół konferencyjny z mikrofonami czołowych stacji sportowych** (Eurosport,
///    France TV, RAI Sport, Sporza, Cyclingnews, L'Équipe) z aktywnym wskaźnikiem ON-AIR.
/// 3. **Identyfikator dziennikarza i treść pytania** w formie dymka dialogowego.
/// 4. **4 warianty odpowiedzi menedżera** w zróżnicowanych tonach:
///    - Blef taktyczny (Tactical Bluff)
///    - Agresywna pewność siebie (Aggressive Confidence)
///    - Spokojna dyplomacja (Diplomatic Shield)
///    - Przeniesienie presji (Pressure Deflection)
/// 5. **Natychmiastowy podgląd reakcji na żywo (Live Reaction Preview)**:
///    - Presja i morale lidera
///    - Peloton Twitter / Social Media Buzz (nagłówek i zasięg)
///    - Satysfakcja sponsora tytularnego
///    - Radar czujności rywali AI i premia do ucieczki z dystansu.
/// 6. **Końcowy raport prasowy i nagłówki gazet** po zakończeniu sesji.
class PressInterviewModal extends StatefulWidget {
  final PressConferenceSession session;
  final CyclingTeam team;
  final Rider? focalRider;
  final void Function(PressConferenceResult result)? onCompleted;

  const PressInterviewModal({
    super.key,
    required this.session,
    required this.team,
    this.focalRider,
    this.onCompleted,
  });

  /// Statyczna metoda pomocnicza do wyświetlenia modalnego okna konferencji.
  static Future<PressConferenceResult?> show({
    required BuildContext context,
    required PressConferenceSession session,
    required CyclingTeam team,
    Rider? focalRider,
    void Function(PressConferenceResult result)? onCompleted,
  }) async {
    return showDialog<PressConferenceResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => PressInterviewModal(
        session: session,
        team: team,
        focalRider: focalRider,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<PressInterviewModal> createState() => _PressInterviewModalState();
}

class _PressInterviewModalState extends State<PressInterviewModal>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final Map<String, String> _chosenOptionIds = {};
  bool _showingFinalSummary = false;
  PressConferenceResult? _computedResult;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  PressConferenceQuestion get _currentQuestion =>
      widget.session.questions[_currentQuestionIndex];

  PressConferenceAnswerOption? get _selectedOptionForCurrentQuestion {
    final chosenId = _chosenOptionIds[_currentQuestion.id];
    if (chosenId == null) return null;
    try {
      return _currentQuestion.options.firstWhere((o) => o.id == chosenId);
    } catch (_) {
      return null;
    }
  }

  SponsorContract? get _primaryTitleSponsor {
    try {
      return widget.team.sponsors.firstWhere(
        (s) => s.sponsorTier == SponsorTier.titlePrimary,
      );
    } catch (_) {
      return widget.team.sponsors.isNotEmpty
          ? widget.team.sponsors.first
          : null;
    }
  }

  void _selectOption(PressConferenceAnswerOption option) {
    setState(() {
      _chosenOptionIds[_currentQuestion.id] = option.id;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.session.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _animController.forward(from: 0.0);
    } else {
      _finishConference();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _animController.forward(from: 0.0);
    }
  }

  void _finishConference() {
    final result = PressConferenceService.processCompletedConference(
      session: widget.session,
      chosenOptionIdsByQuestionId: _chosenOptionIds,
      team: widget.team,
    );

    setState(() {
      _computedResult = result;
      _showingFinalSummary = true;
    });
    _animController.forward(from: 0.0);
  }

  void _confirmAndClose() {
    if (_computedResult != null) {
      widget.onCompleted?.call(_computedResult!);
      Navigator.of(context).pop(_computedResult);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          width: 860,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.94,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryGold.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.70),
                blurRadius: 36,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  _buildHeaderBar(theme),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: _showingFinalSummary
                            ? _buildSummaryView(theme)
                            : _buildInterviewFlow(theme),
                      ),
                    ),
                  ),
                  _buildBottomBar(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. GŁÓWNY PASEK NAGŁÓWKA SALI KONFERENCYJNEJ
  // ===========================================================================
  Widget _buildHeaderBar(ThemeData theme) {
    final isLastQuestion =
        _currentQuestionIndex == widget.session.questions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Ikona i oznaczenie statusu mediów
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.mic_external_on,
              color: AppColors.primaryGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Nazwa wyścigu i kontekst
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.session.raceName.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.session.stageNumber != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.cardBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'ETAP ${widget.session.stageNumber}',
                          style: const TextStyle(
                            color: AppColors.accentBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.session.context.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Numer pytania lub podsumowanie
          if (!_showingFinalSummary) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLastQuestion
                      ? AppColors.primaryGold.withValues(alpha: 0.5)
                      : AppColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.question_answer_outlined,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pytanie ${_currentQuestionIndex + 1} z ${widget.session.questions.length}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Przycisk zamknięcia / rezygnacji
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            tooltip: 'Opuść salę prasową',
            splashRadius: 20,
            onPressed: () {
              if (_chosenOptionIds.isNotEmpty && !_showingFinalSummary) {
                _showExitConfirmationDialog();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. GŁÓWNY PRZEBIEG KONFERENCJI PRASOWEJ
  // ===========================================================================
  Widget _buildInterviewFlow(ThemeData theme) {
    final activeOutlet = _currentQuestion.outlet;
    final selectedOption = _selectedOptionForCurrentQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ścianka sponsorska i stół z mikrofonami
        _buildStagePodiumWithMicrophones(activeOutlet),
        const SizedBox(height: 16),

        // Identyfikator dziennikarza i pytanie
        _buildJournalistQuestionCard(theme, _currentQuestion),
        const SizedBox(height: 16),

        // Nagłówek sekcji odpowiedzi
        Row(
          children: [
            const Icon(
              Icons.record_voice_over,
              color: AppColors.primaryGold,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'WYBIERZ ODPOWIEDŹ MENEDŻERA DO MIKROFONU:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
            const Spacer(),
            if (selectedOption != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.statusSuccess.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.statusSuccess, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Odpowiedź wybrana',
                      style: TextStyle(
                        color: AppColors.statusSuccess,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // 4 Karty odpowiedzi
        ..._currentQuestion.options.map((option) {
          final isSelected = selectedOption?.id == option.id;
          return _buildAnswerOptionCard(theme, option, isSelected);
        }),
        const SizedBox(height: 16),

        // Natychmiastowy podgląd reakcji po zaznaczeniu opcji
        if (selectedOption != null) ...[
          _buildLiveReactionPreview(theme, selectedOption),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ===========================================================================
  // 3. ŚCIANKA SPONSORSKA I STÓŁ KONFERENCYJNY Z MIKROFONAMI
  // ===========================================================================
  Widget _buildStagePodiumWithMicrophones(MediaOutlet activeOutlet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ŚCIANKA SPONSORSKA (Backdrop Wall)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.95),
                  AppColors.surfaceLight,
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Column(
              children: [
                // Rząd sponsorów i brandów (Step & Repeat)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSponsorBackdropTile(
                      label: widget.session.raceName,
                      isGold: true,
                      icon: Icons.emoji_events,
                    ),
                    if (_primaryTitleSponsor != null)
                      _buildSponsorBackdropTile(
                        label: _primaryTitleSponsor!.companyName,
                        isPrimary: true,
                        icon: Icons.verified,
                      ),
                    _buildSponsorBackdropTile(
                      label: widget.team.bikeDeal.manufacturerName,
                      icon: Icons.directions_bike,
                    ),
                    _buildSponsorBackdropTile(
                      label: 'UCI WorldTour',
                      icon: Icons.shield_outlined,
                    ),
                    if (widget.team.sponsors.length > 1)
                      _buildSponsorBackdropTile(
                        label: widget.team.sponsors[1].companyName,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // STÓŁ KONFERENCYJNY Z MIKROFONAMI I TABLICZKĄ
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222B),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              children: [
                // Tabliczka menedżera i lidera
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryGold.withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge,
                              color: AppColors.primaryGold, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'MENEDŻER: ${widget.team.name.toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '|',
                            style: TextStyle(
                              color: AppColors.cardBorder,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'LIDER: ${widget.session.targetRiderName.toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.accentBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rząd mikrofonów mediów sportowych
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBrandedMicrophone(
                        brand: 'EUROSPORT',
                        cubeColor: const Color(0xFF001E50),
                        textColor: Colors.white,
                        isActive: activeOutlet.id == 'cyclingnews' ||
                            activeOutlet.id == 'eurosport',
                      ),
                      const SizedBox(width: 12),
                      _buildBrandedMicrophone(
                        brand: 'L\'ÉQUIPE',
                        cubeColor: const Color(0xFF151515),
                        textColor: const Color(0xFFEF4444),
                        isActive: activeOutlet.id == 'lequipe',
                      ),
                      const SizedBox(width: 12),
                      _buildBrandedMicrophone(
                        brand: 'FRANCE TV',
                        cubeColor: const Color(0xFF0055A5),
                        textColor: Colors.white,
                        isActive: activeOutlet.countryIso == 'FR',
                      ),
                      const SizedBox(width: 12),
                      _buildBrandedMicrophone(
                        brand: 'RAI SPORT',
                        cubeColor: const Color(0xFF0082C8),
                        textColor: Colors.white,
                        isActive: activeOutlet.id == 'gazzetta',
                      ),
                      const SizedBox(width: 12),
                      _buildBrandedMicrophone(
                        brand: 'SPORZA',
                        cubeColor: const Color(0xFFFFCC00),
                        textColor: Colors.black,
                        ringColor: const Color(0xFFEF4444),
                        isActive: activeOutlet.countryIso == 'BE' ||
                            activeOutlet.id == 'wielerflits',
                      ),
                      const SizedBox(width: 12),
                      _buildBrandedMicrophone(
                        brand: 'CYCLINGNEWS',
                        cubeColor: const Color(0xFFE10600),
                        textColor: Colors.white,
                        isActive: activeOutlet.id == 'cyclingnews',
                      ),
                      const SizedBox(width: 12),
                      _buildBrandedMicrophone(
                        brand: 'MARCA / AS',
                        cubeColor: const Color(0xFF8B0000),
                        textColor: Colors.white,
                        isActive: activeOutlet.id == 'marca',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorBackdropTile({
    required String label,
    bool isGold = false,
    bool isPrimary = false,
    IconData? icon,
  }) {
    Color borderColor = AppColors.cardBorder.withValues(alpha: 0.6);
    Color textColor = AppColors.textSecondary;
    Color bgColor = AppColors.backgroundDark.withValues(alpha: 0.7);

    if (isGold) {
      borderColor = AppColors.primaryGold.withValues(alpha: 0.6);
      textColor = AppColors.primaryGold;
      bgColor = AppColors.primaryGold.withValues(alpha: 0.1);
    } else if (isPrimary) {
      borderColor = AppColors.accentBlue.withValues(alpha: 0.6);
      textColor = AppColors.textPrimary;
      bgColor = AppColors.accentBlue.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandedMicrophone({
    required String brand,
    required Color cubeColor,
    required Color textColor,
    Color? ringColor,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Główka mikrofonu (siatka kapsuły)
        Container(
          width: 22,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF333842),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(
              color: isActive
                  ? AppColors.crimsonAlert
                  : const Color(0xFF555C6B),
              width: 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.crimsonAlert.withValues(alpha: 0.7),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ringColor != null
              ? Center(
                  child: Container(
                    height: 2,
                    color: ringColor,
                  ),
                )
              : null,
        ),
        // Kostka piankowa z logo stacji
        Container(
          width: 56,
          height: 24,
          decoration: BoxDecoration(
            color: cubeColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isActive ? Colors.white : Colors.black.withValues(alpha: 0.4),
              width: isActive ? 1.4 : 0.8,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            brand,
            style: TextStyle(
              color: textColor,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Stojak i podstawa
        Container(
          width: 4,
          height: 12,
          color: const Color(0xFF6B7280),
        ),
        Container(
          width: 26,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF374151),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 3),
        // Wskaźnik ON-AIR
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.crimsonAlert,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 6.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }

  // ===========================================================================
  // 4. KARTA DZIENNIKARZA I PYTANIA (Journalist Question Card)
  // ===========================================================================
  Widget _buildJournalistQuestionCard(
      ThemeData theme, PressConferenceQuestion question) {
    final outlet = question.outlet;
    final flag = _getCountryFlagEmoji(outlet.countryIso);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pasek identyfikacyjny dziennikarza (Press Credential / Lanyard Badge)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      outlet.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accentBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outlet.journalistName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      outlet.editorialTone,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Pigułka tematu pytania
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatTopicLabel(question.topic),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Treść pytania
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.cardBorder.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote,
                  color: AppColors.accentBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.questionText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        question.contextDescription,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. KARTY ODPOWIEDZI MENEDŻERA (Answer Options)
  // ===========================================================================
  Widget _buildAnswerOptionCard(
    ThemeData theme,
    PressConferenceAnswerOption option,
    bool isSelected,
  ) {
    final toneColor = _getToneColor(option.tone);
    final toneIcon = _getToneIcon(option.tone);

    return InkWell(
      onTap: () => _selectOption(option),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? toneColor.withValues(alpha: 0.12)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? toneColor : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: toneColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etykieta tonu odpowiedzi i radio button
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: toneColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: toneColor.withValues(alpha: 0.7),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(toneIcon, size: 12, color: toneColor),
                      const SizedBox(width: 5),
                      Text(
                        option.tone.displayName.toUpperCase(),
                        style: TextStyle(
                          color: toneColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Wskaźnik wyboru
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? toneColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? toneColor : AppColors.textSecondary,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Treść wypowiedzi menedżera
            Text(
              option.answerText,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Szybkie pigułki przewidywanych skutków
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildImpactPill(
                  label: 'Presja: ${option.riderPressureDelta > 0 ? "+${option.riderPressureDelta}" : "${option.riderPressureDelta}"} pkt',
                  isPositive: option.riderPressureDelta <= 0,
                  icon: Icons.psychology,
                ),
                _buildImpactPill(
                  label: 'Sponsorzy: ${option.sponsorSatisfactionDelta > 0 ? "+${option.sponsorSatisfactionDelta.toStringAsFixed(1)}" : option.sponsorSatisfactionDelta.toStringAsFixed(1)} pkt',
                  isPositive: option.sponsorSatisfactionDelta >= 0,
                  icon: Icons.monetization_on_outlined,
                ),
                _buildImpactPill(
                  label: 'Czujność rywali: ${option.rivalAlertnessMultiplier.toStringAsFixed(2)}x',
                  isPositive: option.rivalAlertnessMultiplier <= 1.0,
                  icon: Icons.radar,
                ),
                if (option.tacticalSurpriseBonusPercent > 0)
                  _buildImpactPill(
                    label: 'Atak z zaskoczenia: +${(option.tacticalSurpriseBonusPercent * 100).toStringAsFixed(0)}%',
                    isPositive: true,
                    icon: Icons.flash_on,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactPill({
    required String label,
    required bool isPositive,
    required IconData icon,
  }) {
    final color = isPositive ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. NATYCHMIASTOWY PODGLĄD REAKCJI NA ŻYWO (Live Reaction Preview)
  // ===========================================================================
  Widget _buildLiveReactionPreview(
    ThemeData theme,
    PressConferenceAnswerOption option,
  ) {
    final sponsor = _primaryTitleSponsor;
    final currentSponsorSat = sponsor?.sponsorSatisfaction ?? 75.0;
    final newSponsorSat =
        (currentSponsorSat + option.sponsorSatisfactionDelta).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundDark,
            AppColors.surfaceLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.5),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek sekcji Live Reactions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sensors,
                  color: AppColors.primaryGold,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ECHO MEDIALNE I REAKCJE NA ŻYWO',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record,
                        color: AppColors.crimsonAlert, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'SZUM W SIECI',
                      style: TextStyle(
                        color: AppColors.crimsonAlert,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Siatka 4 paneli reakcji:
          // 1. Morale i Presja Lidera
          // 2. Peloton Twitter Buzz
          // 3. Sponsor Tytularny
          // 4. Radar Czujności Rywali AI
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              if (isNarrow) {
                return Column(
                  children: [
                    _buildRiderPsychologyReactionCard(option),
                    const SizedBox(height: 10),
                    _buildPelotonTwitterCard(option),
                    const SizedBox(height: 10),
                    _buildSponsorSatisfactionCard(
                        sponsor, currentSponsorSat, newSponsorSat, option),
                    const SizedBox(height: 10),
                    _buildRivalAlertnessCard(option),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildRiderPsychologyReactionCard(option)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPelotonTwitterCard(option)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildSponsorSatisfactionCard(
                          sponsor,
                          currentSponsorSat,
                          newSponsorSat,
                          option,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildRivalAlertnessCard(option)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 6a. Karta psychologii lidera i morale
  Widget _buildRiderPsychologyReactionCard(PressConferenceAnswerOption option) {
    final pressureDelta = option.riderPressureDelta;
    final isPressureRelief = pressureDelta <= 0;
    final moraleDelta = option.teamMoraleDelta;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPressureRelief
              ? AppColors.statusSuccess.withValues(alpha: 0.4)
              : AppColors.crimsonAlert.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                size: 14,
                color: isPressureRelief
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              const SizedBox(width: 6),
              const Text(
                'LIDER & SZATNIA',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.session.targetRiderName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Presja: ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                pressureDelta > 0 ? '+$pressureDelta pkt' : '$pressureDelta pkt',
                style: TextStyle(
                  color: isPressureRelief
                      ? AppColors.statusSuccess
                      : AppColors.crimsonAlert,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Text(
                'Morale: ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                moraleDelta > 0
                    ? '+${moraleDelta.toStringAsFixed(1)}'
                    : moraleDelta.toStringAsFixed(1),
                style: TextStyle(
                  color: moraleDelta >= 0
                      ? AppColors.statusSuccess
                      : AppColors.crimsonAlert,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPressureRelief
                ? 'Zdjęcie presji pozwala liderowi jechać ze spokojną głową.'
                : 'Zwiększone oczekiwania mogą zmotywować lub sparaliżować nogi.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // 6b. Karta Peloton Twitter / Social Media Buzz
  Widget _buildPelotonTwitterCard(PressConferenceAnswerOption option) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF1DA1F2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'X',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '@PelotonWire • Teraz',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.verified, size: 12, color: Color(0xFF1DA1F2)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '„${option.expectedMediaReaction}”',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTwitterStat(Icons.repeat, '1.4K'),
              const SizedBox(width: 12),
              _buildTwitterStat(Icons.favorite, '4.8K'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.amberWarning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '🔥 TRENDUJĄCE',
                  style: TextStyle(
                    color: AppColors.amberWarning,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterStat(IconData icon, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          count,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 6c. Karta satysfakcji sponsora tytularnego
  Widget _buildSponsorSatisfactionCard(
    SponsorContract? sponsor,
    double currentSat,
    double newSat,
    PressConferenceAnswerOption option,
  ) {
    final sponsorName = sponsor?.companyName ?? widget.team.name;
    final isIncrease = option.sponsorSatisfactionDelta >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isIncrease
              ? AppColors.statusSuccess.withValues(alpha: 0.4)
              : AppColors.amberWarning.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 14,
                color: AppColors.primaryGold,
              ),
              SizedBox(width: 6),
              Text(
                'SPONSOR TYTULARNY',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sponsorName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Zadowolenie: ${newSat.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${option.sponsorSatisfactionDelta > 0 ? "+${option.sponsorSatisfactionDelta.toStringAsFixed(1)}" : option.sponsorSatisfactionDelta.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: isIncrease
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (newSat / 100.0).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isIncrease ? AppColors.statusSuccess : AppColors.amberWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6d. Karta radaru czujności rywali AI i ataku dalekiego zasięgu
  Widget _buildRivalAlertnessCard(PressConferenceAnswerOption option) {
    final alertness = option.rivalAlertnessMultiplier;
    final isAsleep = alertness < 0.95;
    final isHighAlert = alertness > 1.15;

    Color radarColor = AppColors.accentBlue;
    String statusTitle = 'Standardowa czujność peletonu';
    if (isAsleep) {
      radarColor = AppColors.statusSuccess;
      statusTitle = '😴 Rywale uśpieni blefem!';
    } else if (isHighAlert) {
      radarColor = AppColors.crimsonAlert;
      statusTitle = '🚨 Rywale w pełnym alercie!';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: radarColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar, size: 14, color: radarColor),
              const SizedBox(width: 6),
              const Text(
                'RADAR CZUJNOŚCI RYWALI AI',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusTitle,
            style: TextStyle(
              color: radarColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Mnożnik czujności: ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                '${alertness.toStringAsFixed(2)}x',
                style: TextStyle(
                  color: radarColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (option.tacticalSurpriseBonusPercent > 0)
            Text(
              '⚡ +${(option.tacticalSurpriseBonusPercent * 100).toStringAsFixed(0)}% do szansy ucieczki z dystansu (Long-range attack)!',
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            const Text(
              'Rywale natychmiast odpowiedzą na każdy atak lidera.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. NAWIGACJA MIĘDZY PYTANIAMI
  // ===========================================================================
  Widget _buildQuestionNavigationControls() {
    final isLastQuestion =
        _currentQuestionIndex == widget.session.questions.length - 1;
    final hasSelectedCurrent = _selectedOptionForCurrentQuestion != null;

    return Row(
      children: [
        if (_currentQuestionIndex > 0)
          OutlinedButton.icon(
            onPressed: _previousQuestion,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Poprzednie pytanie'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.cardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: hasSelectedCurrent ? _nextQuestion : null,
          icon: Icon(
            isLastQuestion ? Icons.check_circle_outline : Icons.arrow_forward,
            size: 18,
          ),
          label: Text(
            isLastQuestion
                ? 'Zakończ konferencję prasową'
                : 'Następne pytanie (${_currentQuestionIndex + 2} z ${widget.session.questions.length})',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isLastQuestion ? AppColors.primaryGold : AppColors.accentBlue,
            foregroundColor:
                isLastQuestion ? Colors.black : Colors.black,
            disabledBackgroundColor: AppColors.surfaceLight,
            disabledForegroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: hasSelectedCurrent ? 4 : 0,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    if (_showingFinalSummary) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: AppColors.cardBorder.withValues(alpha: 0.8),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _confirmAndClose,
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'Zatwierdź i wróć do gry',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
      ),
      child: _buildQuestionNavigationControls(),
    );
  }

  // ===========================================================================
  // 8. KOŃCOWY RAPORT I PODSUMOWANIE KONFERENCJI PRASOWEJ
  // ===========================================================================
  Widget _buildSummaryView(ThemeData theme) {
    final result = _computedResult;
    if (result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nagłówek sukcesu konferencji
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryGold,
                width: 2.0,
              ),
            ),
            child: const Icon(
              Icons.newspaper,
              color: AppColors.primaryGold,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'KONFERENCJA PRASOWA ZAKOŃCZONA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryGold,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Dziennikarze opuścili salę. Twoje wypowiedzi obiegły media sportowe całego świata.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),

        // PODSUMOWANIE SKUMULOWANYCH WSKAŹNIKÓW
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics,
                      color: AppColors.primaryGold, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'SKUMULOWANY BILANS WYSTĄPIENIA',
                    style: TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetricItem(
                      title: 'Presja Lidera',
                      value: result.totalRiderPressureDelta > 0
                          ? '+${result.totalRiderPressureDelta} pkt'
                          : '${result.totalRiderPressureDelta} pkt',
                      isPositive: result.totalRiderPressureDelta <= 0,
                      icon: Icons.psychology,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryMetricItem(
                      title: 'Sponsorzy',
                      value: result.totalSponsorSatisfactionDelta > 0
                          ? '+${result.totalSponsorSatisfactionDelta.toStringAsFixed(1)}%'
                          : '${result.totalSponsorSatisfactionDelta.toStringAsFixed(1)}%',
                      isPositive: result.totalSponsorSatisfactionDelta >= 0,
                      icon: Icons.handshake,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetricItem(
                      title: 'Czujność Rywali',
                      value:
                          '${result.rivalAlertnessFactor.toStringAsFixed(2)}x',
                      isPositive: result.rivalAlertnessFactor <= 1.0,
                      icon: Icons.radar,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryMetricItem(
                      title: 'Reputacja DS',
                      value: result.totalManagerReputationDelta > 0
                          ? '+${result.totalManagerReputationDelta}'
                          : '${result.totalManagerReputationDelta}',
                      isPositive: result.totalManagerReputationDelta >= 0,
                      icon: Icons.star,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // JUTRZEJSZE NAGŁÓWKI PRASOWE (Front Page Headlines)
        const Row(
          children: [
            Icon(Icons.feed_outlined, color: AppColors.accentBlue, size: 16),
            SizedBox(width: 8),
            Text(
              'JUTRZEJSZE JEDYNKI W NAJWIĘKSZYCH DZIENNIKACH:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...result.frontPageHeadlines.map((headline) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📰', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headline,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryMetricItem({
    required String title,
    required String value,
    required bool isPositive,
    required IconData icon,
  }) {
    final color = isPositive ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 9. DIALOG POTWIERDZENIA OPUSZCZENIA
  // ===========================================================================
  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Opuścić salę konferencyjną?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Twoje dotychczasowe odpowiedzi nie zostaną zapisane, a media zinterpretują nagłe wyjście jako brak szacunku.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Zostań'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimsonAlert,
              foregroundColor: Colors.white,
            ),
            child: const Text('Opuść konferencję'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 10. METODY POMOCNICZE
  // ===========================================================================
  Color _getToneColor(PressAnswerTone tone) {
    switch (tone) {
      case PressAnswerTone.tacticalBluff:
        return const Color(0xFF8B5CF6); // Fiolet / Indigo
      case PressAnswerTone.aggressiveConfidence:
        return const Color(0xFFEF4444); // Karmazyn / Czerwień
      case PressAnswerTone.diplomaticShield:
        return const Color(0xFF10B981); // Szmaragd / Zieleń
      case PressAnswerTone.pressureDeflection:
        return const Color(0xFFF59E0B); // Bursztyn / Złoto
    }
  }

  IconData _getToneIcon(PressAnswerTone tone) {
    switch (tone) {
      case PressAnswerTone.tacticalBluff:
        return Icons.psychology;
      case PressAnswerTone.aggressiveConfidence:
        return Icons.local_fire_department;
      case PressAnswerTone.diplomaticShield:
        return Icons.shield;
      case PressAnswerTone.pressureDeflection:
        return Icons.reply_all;
    }
  }

  String _formatTopicLabel(QuestionTopic topic) {
    switch (topic) {
      case QuestionTopic.leaderConditionAndForm:
        return 'FORMA & DYSPOZYCJA';
      case QuestionTopic.mountainTacticsAndPacing:
        return 'TAKTYKA W GÓRACH';
      case QuestionTopic.crashDamageAndPainManagement:
        return 'ZDROWIE PO KRAKSIE';
      case QuestionTopic.transferRumorsAndContract:
        return 'PLOTKI TRANSFEROWE';
      case QuestionTopic.dualLeaderDynamicAndHierarchy:
        return 'HIERARCHIA LIDERÓW';
      case QuestionTopic.rivalryAndMindGames:
        return 'WOJNA PSYCHOLOGICZNA';
    }
  }

  String _getCountryFlagEmoji(String iso) {
    switch (iso.toUpperCase()) {
      case 'FR':
        return '🇫🇷';
      case 'IT':
      case 'ITA':
        return '🇮🇹';
      case 'GB':
      case 'UK':
        return '🇬🇧';
      case 'NL':
        return '🇳🇱';
      case 'ES':
        return '🇪🇸';
      case 'BE':
        return '🇧🇪';
      case 'PL':
        return '🇵🇱';
      case 'US':
      case 'USA':
        return '🇺🇸';
      case 'CO':
      case 'COL':
        return '🇨🇴';
      case 'SI':
      case 'SLO':
        return '🇸🇮';
      case 'DK':
      case 'DEN':
        return '🇩🇰';
      default:
        return '🌐';
    }
  }
}
