import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../../services/career/sponsor_negotiation_service.dart';
import '../widgets/custom_jersey_painter.dart';

/// Prognoza ekspozycji telewizyjnej i wartości medialnej drużyny dla Pitch Decku.
class PitchDeckMediaForecast {
  final double mediaValueIndex; // 0.0 - 100.0
  final int worldTourStartsCount;
  final double leaderPopularityScore; // 0.0 - 100.0
  final double estimatedTvAirtimeHours;
  final int estimatedAveEur;
  final String exposureTierLabel;

  const PitchDeckMediaForecast({
    required this.mediaValueIndex,
    required this.worldTourStartsCount,
    required this.leaderPopularityScore,
    required this.estimatedTvAirtimeHours,
    required this.estimatedAveEur,
    required this.exposureTierLabel,
  });
}

/// Wynik zakończenia rozmów negocjacyjnych w oknie Pitch Decku.
enum PitchNegotiationStatus {
  inProgress,
  accepted,
  counterOfferReceived,
  walkedAway,
}

/// Interaktywne okno negocjacji ze sponsorem tytularnym (`SponsorPitchDeckNegotiationModal`).
///
/// Prezentuje:
/// 1. Wizualny Pitch Deck (koszulka + spodenki z logo sponsora na piersi i nogawkach,
///    prognozę ekspozycji telewizyjnej Media Value Index).
/// 2. 3-rundowe negocjacje z suwakami (roczna kwota EUR, długość 1–4 lata,
///    premia za GT/Monument) oraz listą 3 modyfikowalnych celów obowiązkowych.
/// 3. Wskaźnik cierpliwości dyrektora marketingu sponsora (0–100%) reagujący na żywo.
class SponsorPitchDeckNegotiationModal extends StatefulWidget {
  final PotentialSponsorCompany company;
  final CyclingTeam team;
  final List<Rider> roster;
  final int? worldTourStartsCount;
  final void Function(SponsorContract signedContract)? onContractSigned;

  const SponsorPitchDeckNegotiationModal({
    super.key,
    required this.company,
    required this.team,
    required this.roster,
    this.worldTourStartsCount,
    this.onContractSigned,
  });

  int get effectiveWorldTourStarts =>
      worldTourStartsCount ??
      (team.division == TeamDivision.worldTour
          ? 28
          : (team.division == TeamDivision.proTeam ? 14 : 4));

  /// Otwiera responsywne okno negocjacji i zwraca podpisany [SponsorContract] lub `null`.
  static Future<SponsorContract?> show(
    BuildContext context, {
    required PotentialSponsorCompany company,
    required CyclingTeam team,
    required List<Rider> roster,
    int? worldTourStartsCount,
    void Function(SponsorContract signedContract)? onContractSigned,
  }) {
    return showDialog<SponsorContract>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => SponsorPitchDeckNegotiationModal(
        company: company,
        team: team,
        roster: roster,
        worldTourStartsCount: worldTourStartsCount,
        onContractSigned: onContractSigned,
      ),
    );
  }

  /// Wylicza prognozę ekspozycji telewizyjnej (Media Value Index 0–100)
  /// na podstawie liczby startów w WorldTourze oraz popularności liderów zespołu.
  static PitchDeckMediaForecast calculateMediaForecast({
    required int worldTourStartsCount,
    required List<Rider> roster,
    Rider? featuredLeader,
  }) {
    final clampedStarts = worldTourStartsCount.clamp(0, 35);
    final double wtScore = (clampedStarts / 35.0) * 50.0;

    final List<double> starRatings = roster
        .map(SponsorNegotiationService.calculateRiderMediaStarRating)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    double weightedPopularity = 30.0;
    if (starRatings.isNotEmpty) {
      final double top1 = featuredLeader != null
          ? SponsorNegotiationService.calculateRiderMediaStarRating(featuredLeader)
          : starRatings[0];
      final double top2 = starRatings.length > 1 ? starRatings[1] : top1 * 0.82;
      final double top3 = starRatings.length > 2 ? starRatings[2] : top2 * 0.80;
      weightedPopularity = (top1 * 0.55 + top2 * 0.30 + top3 * 0.15).clamp(0.0, 100.0);
    }

    final double leaderScore = (weightedPopularity / 100.0) * 50.0;
    final double mediaIndex = (wtScore + leaderScore).clamp(5.0, 100.0);
    final double tvHours = (clampedStarts * 4.3) + (mediaIndex * 0.75);
    final int aveEur = ((mediaIndex * 185000) + (clampedStarts * 210000)).round();

    String tierLabel;
    if (mediaIndex >= 82.0) {
      tierLabel = 'Globalna Ekspozycja Tier-1';
    } else if (mediaIndex >= 64.0) {
      tierLabel = 'Wysoki Zasięg WorldTour';
    } else if (mediaIndex >= 44.0) {
      tierLabel = 'Stabilna Widoczność TV';
    } else {
      tierLabel = 'Ekspozycja Rozwojowa';
    }

    return PitchDeckMediaForecast(
      mediaValueIndex: mediaIndex,
      worldTourStartsCount: clampedStarts,
      leaderPopularityScore: weightedPopularity,
      estimatedTvAirtimeHours: tvHours,
      estimatedAveEur: aveEur,
      exposureTierLabel: tierLabel,
    );
  }

  /// Zwraca mnożnik ambicji celu obowiązkowego (wpływ na akceptowalny budżet bazowy).
  static double objectiveAmbitionUplift(PromisedObjectiveType type) {
    switch (type) {
      case PromisedObjectiveType.winGrandTourGc:
        return 0.18;
      case PromisedObjectiveType.podiumGrandTourGc:
        return 0.12;
      case PromisedObjectiveType.winCyclingMonument:
        return 0.11;
      case PromisedObjectiveType.finishTop5UciTeamRanking:
        return 0.09;
      case PromisedObjectiveType.winPointsGreenJersey:
        return 0.08;
      case PromisedObjectiveType.winMountainsJersey:
        return 0.06;
      case PromisedObjectiveType.targetStageWinsCount:
        return 0.06;
      case PromisedObjectiveType.breakawayTvAirtimeKm:
        return 0.04;
      case PromisedObjectiveType.winMostCombativeAward:
        return 0.03;
    }
  }

  @override
  State<SponsorPitchDeckNegotiationModal> createState() =>
      _SponsorPitchDeckNegotiationModalState();
}

class _SponsorPitchDeckNegotiationModalState
    extends State<SponsorPitchDeckNegotiationModal> {
  static const int _maxRounds = 3;
  static const int _minGtBonusEur = 100000;
  static const int _maxGtBonusEur = 3000000;

  late int _currentRound;
  late double _accumulatedRoundPenalty;
  late double _requestedAnnualBudgetEur;
  late int _contractDurationYears;
  late double _gtMonumentBonusEur;
  late List<PromisedObjectiveType> _mandatoryObjectives;
  late String? _featuredRiderId;

  bool _showBackView = false;
  PitchNegotiationStatus _status = PitchNegotiationStatus.inProgress;
  int? _lastCounterOfferBudgetEur;
  SponsorContract? _signedContract;
  String _directorFeedbackQuote = '';

  @override
  void initState() {
    super.initState();
    _currentRound = 1;
    _accumulatedRoundPenalty = 0.0;
    _requestedAnnualBudgetEur = widget.company.baseAnnualBudgetEur.toDouble();
    _contractDurationYears = 2;
    _gtMonumentBonusEur = 600000.0;
    _mandatoryObjectives = [
      PromisedObjectiveType.targetStageWinsCount,
      PromisedObjectiveType.breakawayTvAirtimeKm,
      PromisedObjectiveType.podiumGrandTourGc,
    ];

    if (widget.roster.isNotEmpty) {
      final sorted = [...widget.roster]
        ..sort((a, b) => SponsorNegotiationService.calculateRiderMediaStarRating(b)
            .compareTo(SponsorNegotiationService.calculateRiderMediaStarRating(a)));
      _featuredRiderId = sorted.first.id;
    } else {
      _featuredRiderId = null;
    }

    _directorFeedbackQuote =
        'Czekamy na Waszą propozycję budżetową i plan ekspozycji marki ${widget.company.name}.';
  }

  Rider? get _featuredRider {
    if (widget.roster.isEmpty || _featuredRiderId == null) return null;
    for (final r in widget.roster) {
      if (r.id == _featuredRiderId) return r;
    }
    return widget.roster.first;
  }

  double get _minBudgetSlider =>
      (widget.company.baseAnnualBudgetEur * 0.60 / 100000).round() * 100000.0;

  double get _maxBudgetSlider =>
      (widget.company.baseAnnualBudgetEur * 1.65 / 100000).round() * 100000.0;

  double get _totalObjectivesUplift {
    double sum = 0.0;
    for (final obj in _mandatoryObjectives) {
      sum += SponsorPitchDeckNegotiationModal.objectiveAmbitionUplift(obj);
    }
    return sum;
  }

  /// Maksymalny budżet bazowy, na jaki gotów jest przystać zarząd sponsora
  /// przy obecnych celach obowiązkowych oraz Media Value Index.
  int _computeSponsorAcceptableBudgetEur(PitchDeckMediaForecast forecast) {
    final double mediaFactor = 0.88 + (forecast.mediaValueIndex / 100.0) * 0.24;
    final double raw =
        widget.company.baseAnnualBudgetEur * (1.0 + _totalObjectivesUplift) * mediaFactor;
    return ((raw / 50000.0).round() * 50000).clamp(
      _minBudgetSlider.round(),
      _maxBudgetSlider.round(),
    );
  }

  /// Wskaźnik cierpliwości dyrektora marketingu (0–100%) reagujący na żywo.
  double _computeLivePatience(PitchDeckMediaForecast forecast) {
    if (_status == PitchNegotiationStatus.walkedAway) return 0.0;

    final int acceptableBudget = _computeSponsorAcceptableBudgetEur(forecast);
    final double askRatio = _requestedAnnualBudgetEur / math.max(1, acceptableBudget);

    double liveDemandPenalty = 0.0;
    if (askRatio > 1.0) {
      // Im wyższe żądanie ponad akceptowalny budżet bazowy, tym szybszy spadek cierpliwości
      liveDemandPenalty = math.pow((askRatio - 1.0) * 100.0, 1.18) * 1.45;
    } else if (askRatio < 0.90) {
      // Umiarkowane żądania lekko uspokajają dyrektora
      liveDemandPenalty = -6.0;
    }

    // Bardzo wysoka premia za GT/Monument względem budżetu lub zbyt długi kontrakt przy słabej ekspozycji
    final double bonusRatio = _gtMonumentBonusEur / math.max(1, acceptableBudget);
    if (bonusRatio > 0.14) {
      liveDemandPenalty += (bonusRatio - 0.14) * 90.0;
    }

    if (_contractDurationYears == 4 && forecast.mediaValueIndex < 55.0) {
      liveDemandPenalty += 8.0;
    } else if (_contractDurationYears == 3 && forecast.mediaValueIndex >= 70.0) {
      liveDemandPenalty -= 3.0;
    }

    final double patience = 100.0 - _accumulatedRoundPenalty - liveDemandPenalty;
    return patience.clamp(0.0, 100.0);
  }

  String _liveMoodDescription(double patience) {
    if (patience >= 75.0) {
      return 'Dyrektor marketingu jest bardzo przychylny warunkom.';
    } else if (patience >= 45.0) {
      return 'Rozmowy są napięte, ale zarząd widzi przestrzeń do kompromisu.';
    } else if (patience >= 20.0) {
      return 'Uwaga: żądania finansowe mocno nadwyrężają cierpliwość sponsora!';
    } else if (patience > 0.0) {
      return 'Krytyczny poziom cierpliwości — jeszcze krok i rozmowy upadną!';
    }
    return 'Dyrektor marketingu zamknął teczkę i opuścił salę obrad.';
  }

  void _updateObjectiveAt(int index, PromisedObjectiveType newType) {
    if (_status != PitchNegotiationStatus.inProgress &&
        _status != PitchNegotiationStatus.counterOfferReceived) {
      return;
    }
    setState(() {
      final existingIdx = _mandatoryObjectives.indexOf(newType);
      if (existingIdx != -1 && existingIdx != index) {
        final previous = _mandatoryObjectives[index];
        _mandatoryObjectives[existingIdx] = previous;
      }
      _mandatoryObjectives[index] = newType;
    });
  }

  void _submitRoundOffer(PitchDeckMediaForecast forecast) {
    if (_status == PitchNegotiationStatus.accepted ||
        _status == PitchNegotiationStatus.walkedAway) {
      return;
    }

    final int acceptableBudget = _computeSponsorAcceptableBudgetEur(forecast);
    final double livePatience = _computeLivePatience(forecast);
    final int requestedEur = _requestedAnnualBudgetEur.round();

    // Warunek akceptacji w danej rundzie:
    // Żądany budżet mieści się w limicie akceptowalnym (z małym marginesem przy wysokim Media Value Index)
    // oraz cierpliwość nie spadła do zera.
    final double mediaGraceMargin =
        forecast.mediaValueIndex >= 75.0 ? 1.04 : 1.01;

    if (livePatience <= 2.0) {
      setState(() {
        _status = PitchNegotiationStatus.walkedAway;
        _directorFeedbackQuote =
            'Te żądania całkowicie rozmijają się z naszym budżetem ROI. Wycofujemy ofertę dla ${widget.team.name}.';
      });
      return;
    }

    if (requestedEur <= (acceptableBudget * mediaGraceMargin).round()) {
      final contract = _buildSignedContract(
        finalBudgetEur: requestedEur,
      );
      setState(() {
        _signedContract = contract;
        _status = PitchNegotiationStatus.accepted;
        _directorFeedbackQuote =
            'Świetna prezentacja i ambitne cele sportowe! Zarząd ${widget.company.name} akceptuje warunki umowy.';
      });
      return;
    }

    // Jeśli to była runda 3 i nadal żądania przekraczają budżet:
    if (_currentRound >= _maxRounds) {
      setState(() {
        _status = PitchNegotiationStatus.walkedAway;
        _directorFeedbackQuote =
            'Po 3 rundach rozmów nie udało nam się zbliżyć stanowisk finansowych. Dziękujemy za spotkanie.';
      });
      return;
    }

    // Przejście do kolejnej rundy z kontrofertą
    final int counterEur =
        ((acceptableBudget * (0.94 + (_currentRound * 0.03))) / 50000.0).round() *
            50000;
    final double roundWear =
        14.0 + ((requestedEur - acceptableBudget) / acceptableBudget) * 32.0;

    setState(() {
      _accumulatedRoundPenalty =
          (_accumulatedRoundPenalty + roundWear.clamp(10.0, 38.0)).clamp(0.0, 95.0);
      _currentRound += 1;
      _lastCounterOfferBudgetEur = counterEur;
      _status = PitchNegotiationStatus.counterOfferReceived;
      _directorFeedbackQuote =
          'Doceniamy prognozę ${forecast.mediaValueIndex.toStringAsFixed(0)} pkt Media Index, '
          'ale ${Formatters.formatCurrency(requestedEur)} to za dużo. '
          'Możemy położyć na stole ${Formatters.formatCurrency(counterEur)} rocznie.';
    });
  }

  void _acceptCounterOffer() {
    final int? counterEur = _lastCounterOfferBudgetEur;
    if (counterEur == null) return;
    final contract = _buildSignedContract(finalBudgetEur: counterEur);
    setState(() {
      _signedContract = contract;
      _requestedAnnualBudgetEur = counterEur.toDouble();
      _status = PitchNegotiationStatus.accepted;
      _directorFeedbackQuote =
          'Mądra decyzja! Kontroferta została przyjęta — witamy ${widget.team.name} w rodzinie ${widget.company.name}.';
    });
  }

  SponsorContract _buildSignedContract({required int finalBudgetEur}) {
    final List<SponsorObjective> objectives = [];
    for (int i = 0; i < _mandatoryObjectives.length; i++) {
      final type = _mandatoryObjectives[i];
      final bool isGtOrMonument = type == PromisedObjectiveType.winGrandTourGc ||
          type == PromisedObjectiveType.winCyclingMonument;
      objectives.add(
        SponsorObjective(
          id: 'pitch_obj_${DateTime.now().millisecondsSinceEpoch}_$i',
          description: type.label,
          bonusPaymentEur:
              isGtOrMonument ? _gtMonumentBonusEur.round() : type.defaultBonusEur,
          importance: ObjectiveImportance.high,
          isCompleted: false,
          currentProgress: 0.0,
          targetProgress:
              type == PromisedObjectiveType.breakawayTvAirtimeKm ? 1200.0 : 1.0,
        ),
      );
    }

    return SponsorContract(
      id: 'spc_pitch_${DateTime.now().millisecondsSinceEpoch}_${widget.company.id}',
      companyName: widget.company.name,
      industry: widget.company.industry,
      sponsorTier: widget.company.defaultTier,
      annualBudgetEur: finalBudgetEur,
      contractDurationYears: _contractDurationYears,
      sponsorSatisfaction: 85.0,
      objectives: objectives,
    );
  }

  void _finalizeAndClose() {
    final contract = _signedContract;
    if (contract != null) {
      widget.onContractSigned?.call(contract);
    }
    Navigator.of(context).pop(contract);
  }

  Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) return Color(int.parse('0xFF$clean'));
      if (clean.length == 8) return Color(int.parse('0x$clean'));
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final forecast = SponsorPitchDeckNegotiationModal.calculateMediaForecast(
      worldTourStartsCount: widget.effectiveWorldTourStarts,
      roster: widget.roster,
      featuredLeader: _featuredRider,
    );
    final double livePatience = _computeLivePatience(forecast);
    final int acceptableBudget = _computeSponsorAcceptableBudgetEur(forecast);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 760;
          final double maxWidth = math.min(constraints.maxWidth, 1180.0);
          final double maxHeight = math.min(constraints.maxHeight, 840.0);

          return Container(
            width: maxWidth,
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModalHeader(isCompact),
                Flexible(
                  child: isCompact
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPitchDeckColumn(forecast, isCompact: true),
                              const SizedBox(height: 14),
                              _buildNegotiationColumn(
                                forecast,
                                livePatience,
                                acceptableBudget,
                                isCompact: true,
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: _buildPitchDeckColumn(
                                    forecast,
                                    isCompact: false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 7,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: _buildNegotiationColumn(
                                    forecast,
                                    livePatience,
                                    acceptableBudget,
                                    isCompact: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                _buildModalFooter(forecast, livePatience, isCompact),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.handshake_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PITCH DECK & NEGOCJACJE: ${widget.company.name.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: isCompact ? 13 : 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.company.defaultTier.name.toUpperCase()} • ${widget.company.marketingFocus.label}',
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
          const SizedBox(width: 8),
          _RoundStepperBadge(
            currentRound: _currentRound,
            maxRounds: _maxRounds,
            status: _status,
          ),
          const SizedBox(width: 8),
          _InteractiveIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Zamknij okno negocjacji',
            onPressed: () => Navigator.of(context).pop(_signedContract),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchDeckColumn(
    PitchDeckMediaForecast forecast, {
    required bool isCompact,
  }) {
    final Color primaryColor =
        _parseHex(widget.team.primaryJerseyColorHex, AppColors.primaryAccent);
    final Color secondaryColor =
        _parseHex(widget.team.secondaryJerseyColorHex, AppColors.surfaceLight);
    final Color accentColor =
        _parseHex(widget.team.accentJerseyColorHex, AppColors.goldAccent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Karta 1: Wizualizacja koszulki + spodenek z logo negocjowanego sponsora
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.checkroom_rounded,
                    color: AppColors.goldAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'PREZENTACJA STROJU ZESPOŁU',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  _ViewTogglePill(
                    isBackView: _showBackView,
                    onToggle: (back) => setState(() => _showBackView = back),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.22),
                        AppColors.background.withValues(alpha: 0.85),
                      ],
                      radius: 0.9,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: Column(
                          key: ValueKey<bool>(_showBackView),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomPaint(
                              size: Size(
                                isCompact ? 136 : 162,
                                isCompact ? 142 : 168,
                              ),
                              painter: TeamJerseyPainter(
                                primaryColor: primaryColor,
                                secondaryColor: secondaryColor,
                                accentColor: accentColor,
                                pattern: JerseyPattern.chestStripe,
                                sponsorName: widget.company.name,
                                teamName: widget.team.name,
                                isBackView: _showBackView,
                                countryCode: widget.team.countryIso,
                              ),
                            ),
                            const SizedBox(height: 2),
                            CustomPaint(
                              size: Size(
                                isCompact ? 112 : 132,
                                isCompact ? 84 : 98,
                              ),
                              painter: TeamBibShortsPainter(
                                primaryColor: primaryColor,
                                accentColor: accentColor,
                                sponsorName: widget.company.name,
                                isBackView: _showBackView,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ekspozycja logo "${widget.company.name}" na piersi i spodenkach',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Karta 2: Prognoza Ekspozycji Telewizyjnej (Media Value Index)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.live_tv_rounded,
                    color: AppColors.accentBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'PROGNOZA EKSPOZYCJI TV (MEDIA VALUE INDEX)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accentBlue.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '${forecast.mediaValueIndex.toStringAsFixed(1)} / 100',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.0,
                  end: (forecast.mediaValueIndex / 100.0).clamp(0.0, 1.0),
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentBlue,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Text(
                forecast.exposureTierLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.goldAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricMiniTile(
                      label: 'Starty WorldTour',
                      value: '${forecast.worldTourStartsCount} wyścigów',
                      accent: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricMiniTile(
                      label: 'Popularność liderów',
                      value: '${forecast.leaderPopularityScore.toStringAsFixed(1)} pkt',
                      accent: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MetricMiniTile(
                      label: 'Czas antenowy TV',
                      value: '~${forecast.estimatedTvAirtimeHours.round()} h / sezon',
                      accent: AppColors.statusSuccess,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricMiniTile(
                      label: 'Szacowane AVE',
                      value: Formatters.formatCurrency(forecast.estimatedAveEur),
                      accent: AppColors.goldAccent,
                    ),
                  ),
                ],
              ),
              if (widget.roster.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Twarz kampanii (Lider w Pitch Decku):',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _featuredRiderId,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceLight,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.goldAccent),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                  items: widget.roster.map((r) {
                    final rating =
                        SponsorNegotiationService.calculateRiderMediaStarRating(r);
                    return DropdownMenuItem<String>(
                      value: r.id,
                      child: Text(
                        '${r.fullName} (Media: ${rating.toStringAsFixed(0)} pkt)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (_status == PitchNegotiationStatus.accepted ||
                          _status == PitchNegotiationStatus.walkedAway)
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _featuredRiderId = val);
                          }
                        },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNegotiationColumn(
    PitchDeckMediaForecast forecast,
    double livePatience,
    int acceptableBudget, {
    required bool isCompact,
  }) {
    final bool isLocked = _status == PitchNegotiationStatus.accepted ||
        _status == PitchNegotiationStatus.walkedAway;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Wskaźnik cierpliwości dyrektora marketingu (0–100%)
        _buildPatienceCard(livePatience),
        const SizedBox(height: 14),

        // 2. Suwaki negocjacyjne
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: AppColors.goldAccent,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'WARUNKI FINANSOWE KONTRAKTU',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      'Limit zarządu: ${Formatters.formatCurrency(acceptableBudget)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Suwak 1: Roczna kwota wsparcia (EUR)
              _SliderHeaderRow(
                label: 'Roczna kwota wsparcia',
                valueText:
                    '${Formatters.formatCurrency(_requestedAnnualBudgetEur.round())} / rok',
                valueColor: _requestedAnnualBudgetEur > acceptableBudget
                    ? AppColors.amberWarning
                    : AppColors.statusSuccess,
              ),
              SliderTheme(
                data: _sliderTheme(
                  context,
                  activeColor: _requestedAnnualBudgetEur > acceptableBudget
                      ? AppColors.amberWarning
                      : AppColors.statusSuccess,
                ),
                child: Slider(
                  value: _requestedAnnualBudgetEur.clamp(
                    _minBudgetSlider,
                    _maxBudgetSlider,
                  ),
                  min: _minBudgetSlider,
                  max: _maxBudgetSlider,
                  divisions: math.max(
                    1,
                    ((_maxBudgetSlider - _minBudgetSlider) / 250000).round(),
                  ),
                  onChanged: isLocked
                      ? null
                      : (v) => setState(() => _requestedAnnualBudgetEur = v),
                ),
              ),
              const SizedBox(height: 8),

              // Suwak 2: Długość kontraktu (1–4 lata)
              _SliderHeaderRow(
                label: 'Długość kontraktu',
                valueText: _contractDurationYears == 1
                    ? '1 rok'
                    : '$_contractDurationYears lata',
                valueColor: AppColors.accentBlue,
              ),
              SliderTheme(
                data: _sliderTheme(context, activeColor: AppColors.accentBlue),
                child: Slider(
                  value: _contractDurationYears.toDouble(),
                  min: 1,
                  max: 4,
                  divisions: 3,
                  onChanged: isLocked
                      ? null
                      : (v) =>
                          setState(() => _contractDurationYears = v.round()),
                ),
              ),
              const SizedBox(height: 8),

              // Suwak 3: Premia za wygranie Wielkiego Touru / Monumentu
              _SliderHeaderRow(
                label: 'Premia za wygranie Wielkiego Touru / Monumentu',
                valueText: Formatters.formatCurrency(_gtMonumentBonusEur.round()),
                valueColor: AppColors.goldAccent,
              ),
              SliderTheme(
                data: _sliderTheme(context, activeColor: AppColors.goldAccent),
                child: Slider(
                  value: _gtMonumentBonusEur.clamp(
                    _minGtBonusEur.toDouble(),
                    _maxGtBonusEur.toDouble(),
                  ),
                  min: _minGtBonusEur.toDouble(),
                  max: _maxGtBonusEur.toDouble(),
                  divisions: 58,
                  onChanged: isLocked
                      ? null
                      : (v) => setState(
                            () => _gtMonumentBonusEur =
                                ((v / 50000.0).round() * 50000).toDouble(),
                          ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Lista 3 celów obowiązkowych modyfikowanych przez gracza
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: AppColors.primaryAccent,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '3 CELE OBOWIĄZKOWE SEZONU',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccess.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.statusSuccess.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '+${(_totalObjectivesUplift * 100).round()}% budżetu bazowego',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.statusSuccess,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Im ambitniejsze cele wybierzesz, tym wyższy budżet bazowy zgodzi się wypłacić zarząd sponsora.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < 3; i++) ...[
                _MandatoryObjectiveRow(
                  index: i,
                  selectedType: _mandatoryObjectives[i],
                  isLocked: isLocked,
                  onChanged: (val) => _updateObjectiveAt(i, val),
                ),
                if (i < 2) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatienceCard(double livePatience) {
    final Color barColor = livePatience >= 65.0
        ? AppColors.statusSuccess
        : (livePatience >= 30.0
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: barColor.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                livePatience >= 45.0
                    ? Icons.sentiment_satisfied_alt_rounded
                    : (livePatience > 0.0
                        ? Icons.warning_amber_rounded
                        : Icons.cancel_rounded),
                color: barColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'CIERPLIWOŚĆ DYREKTORA MARKETINGU',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Text(
                '${livePatience.round()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: barColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: livePatience / 100.0,
              end: livePatience / 100.0,
            ),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            _liveMoodDescription(livePatience),
            style: TextStyle(
              fontFamily: 'Inter',
              color: barColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              '„$_directorFeedbackQuote”',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalFooter(
    PitchDeckMediaForecast forecast,
    double livePatience,
    bool isCompact,
  ) {
    final bool isAccepted = _status == PitchNegotiationStatus.accepted;
    final bool isWalkedAway = _status == PitchNegotiationStatus.walkedAway;
    final bool hasCounterOffer =
        _status == PitchNegotiationStatus.counterOfferReceived &&
            _lastCounterOfferBudgetEur != null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          Text(
            'Wartość umowy: ${Formatters.formatCurrency(_requestedAnnualBudgetEur.round() * _contractDurationYears)} ($_contractDurationYears ${_contractDurationYears == 1 ? 'rok' : 'lata'})',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (!isAccepted && !isWalkedAway) ...[
                _InteractiveOutlineButton(
                  label: 'Przerwij',
                  onPressed: () => Navigator.of(context).pop(null),
                ),
                if (hasCounterOffer)
                  _InteractivePrimaryButton(
                    label:
                        'Akceptuj ${Formatters.formatCurrency(_lastCounterOfferBudgetEur!)}',
                    backgroundColor: AppColors.statusSuccess,
                    foregroundColor: Colors.black,
                    onPressed: _acceptCounterOffer,
                  ),
                _InteractivePrimaryButton(
                  label: 'Złóż Ofertę (Runda $_currentRound/$_maxRounds)',
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  onPressed: () => _submitRoundOffer(forecast),
                ),
              ] else if (isAccepted) ...[
                _InteractivePrimaryButton(
                  label: 'Podpisz Kontrakt',
                  backgroundColor: AppColors.statusSuccess,
                  foregroundColor: Colors.black,
                  onPressed: _finalizeAndClose,
                ),
              ] else ...[
                _InteractivePrimaryButton(
                  label: 'Zamknij',
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context, {required Color activeColor}) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: activeColor,
      inactiveTrackColor: AppColors.cardBorder,
      thumbColor: activeColor,
      overlayColor: activeColor.withValues(alpha: 0.18),
      trackHeight: 5.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.5),
    );
  }
}

/// CustomPainter rysujący kolarskie spodenki drużynowe (bib shorts)
/// z wyeksponowanym logo sponsora na nogawkach.
class TeamBibShortsPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final String sponsorName;
  final bool isBackView;

  const TeamBibShortsPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.sponsorName,
    this.isBackView = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;

    final Path shortsPath = Path()
      ..moveTo(w * 0.18, h * 0.04)
      ..lineTo(w * 0.82, h * 0.04)
      ..lineTo(w * 0.94, h * 0.88)
      ..lineTo(w * 0.56, h * 0.92)
      ..lineTo(w * 0.50, h * 0.44)
      ..lineTo(w * 0.44, h * 0.92)
      ..lineTo(w * 0.06, h * 0.88)
      ..close();

    final baseColor = Color.lerp(primaryColor, const Color(0xFF111318), 0.72)!;
    canvas.drawPath(
      shortsPath,
      Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill,
    );

    canvas.save();
    canvas.clipPath(shortsPath);

    // Pasek pasa + wstawki na nogawkach
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.12),
      Paint()..color = primaryColor.withValues(alpha: 0.85),
    );

    // Ściągacze (grippers) na końcach nogawek
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.80, w, h * 0.15),
      Paint()..color = accentColor.withValues(alpha: 0.85),
    );

    // Subtelny szew centralny
    canvas.drawLine(
      Offset(w * 0.50, h * 0.12),
      Offset(w * 0.50, h * 0.44),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 1.2,
    );

    canvas.restore();

    // Kontur spodenek
    canvas.drawPath(
      shortsPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Logo sponsora na lewej i prawej nogawce
    final String shortSponsor = sponsorName.split(' ').first.toUpperCase();
    _paintLegLogo(canvas, shortSponsor, Offset(w * 0.25, h * 0.56), w * 0.28);
    _paintLegLogo(canvas, shortSponsor, Offset(w * 0.75, h * 0.56), w * 0.28);
  }

  void _paintLegLogo(Canvas canvas, String text, Offset center, double maxW) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxW);

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant TeamBibShortsPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.sponsorName != sponsorName ||
        oldDelegate.isBackView != isBackView;
  }
}

class _RoundStepperBadge extends StatelessWidget {
  final int currentRound;
  final int maxRounds;
  final PitchNegotiationStatus status;

  const _RoundStepperBadge({
    required this.currentRound,
    required this.maxRounds,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String label = status == PitchNegotiationStatus.accepted
        ? 'PODPISANO'
        : (status == PitchNegotiationStatus.walkedAway
            ? 'ZERWANO'
            : 'RUNDA $currentRound/$maxRounds');
    final Color color = status == PitchNegotiationStatus.accepted
        ? AppColors.statusSuccess
        : (status == PitchNegotiationStatus.walkedAway
            ? AppColors.crimsonAlert
            : AppColors.goldAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ViewTogglePill extends StatelessWidget {
  final bool isBackView;
  final ValueChanged<bool> onToggle;

  const _ViewTogglePill({
    required this.isBackView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            label: 'Przód',
            active: !isBackView,
            onTap: () => onToggle(false),
          ),
          _ToggleSegment(
            label: 'Tył',
            active: isBackView,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: active ? Colors.black : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricMiniTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricMiniTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              color: accent,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderHeaderRow extends StatelessWidget {
  final String label;
  final String valueText;
  final Color valueColor;

  const _SliderHeaderRow({
    required this.label,
    required this.valueText,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          valueText,
          style: TextStyle(
            fontFamily: 'Inter',
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _MandatoryObjectiveRow extends StatelessWidget {
  final int index;
  final PromisedObjectiveType selectedType;
  final bool isLocked;
  final ValueChanged<PromisedObjectiveType> onChanged;

  const _MandatoryObjectiveRow({
    required this.index,
    required this.selectedType,
    required this.isLocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final upliftPct =
        (SponsorPitchDeckNegotiationModal.objectiveAmbitionUplift(selectedType) *
                100)
            .round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PromisedObjectiveType>(
                value: selectedType,
                isExpanded: true,
                dropdownColor: AppColors.surfaceLight,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                items: PromisedObjectiveType.values.map((obj) {
                  final pct = (SponsorPitchDeckNegotiationModal
                              .objectiveAmbitionUplift(obj) *
                          100)
                      .round();
                  return DropdownMenuItem<PromisedObjectiveType>(
                    value: obj,
                    child: Text(
                      '${obj.label} (+$pct%)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: isLocked
                    ? null
                    : (val) {
                        if (val != null) onChanged(val);
                      },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$upliftPct%',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.goldAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractivePrimaryButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  const _InteractivePrimaryButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceLight;
          }
          if (states.contains(WidgetState.pressed)) {
            return Color.lerp(backgroundColor, Colors.black, 0.18);
          }
          if (states.contains(WidgetState.hovered)) {
            return Color.lerp(backgroundColor, Colors.white, 0.12);
          }
          return backgroundColor;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textSecondary;
          }
          return foregroundColor;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: AppColors.accentBlue, width: 2);
          }
          return BorderSide.none;
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InteractiveOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _InteractiveOutlineButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.textPrimary;
          }
          return AppColors.textSecondary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.surfaceLight;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.surfaceLight.withValues(alpha: 0.65);
          }
          return Colors.transparent;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return const BorderSide(color: AppColors.accentBlue, width: 1.5);
          }
          return const BorderSide(color: AppColors.cardBorder, width: 1);
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InteractiveIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.textPrimary;
          }
          return AppColors.textSecondary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.cardBorder;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.surfaceLight;
          }
          return Colors.transparent;
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}
