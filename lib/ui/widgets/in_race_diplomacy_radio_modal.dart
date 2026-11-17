import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/peloton/in_race_peloton_diplomacy_engine.dart';

/// Zakładka aktywna w modalu radia dyplomatycznego na szosie.
enum DiplomacyRadioTab {
  incomingOffers,
  proposePact,
  activePacts,
}

/// Przychodząca propozycja układu dyplomatycznego od rywala przez radio wyścigowe.
class IncomingRivalPactOffer {
  final String offerId;
  final DiplomacyPactType pactType;
  final DiplomacyTeamContext fromTeam;
  final double offeredAtKm;
  final double expiresAtKm;
  final String headline;
  final String termsSummary;
  final String? targetLeaderTeamId;
  final bool isCrashOrHazardNeutralization;

  const IncomingRivalPactOffer({
    required this.offerId,
    required this.pactType,
    required this.fromTeam,
    required this.offeredAtKm,
    required this.expiresAtKm,
    required this.headline,
    required this.termsSummary,
    this.targetLeaderTeamId,
    this.isCrashOrHazardNeutralization = false,
  });

  Map<String, dynamic> toJson() => {
        'offerId': offerId,
        'pactType': pactType.toJson(),
        'fromTeam': fromTeam.toJson(),
        'offeredAtKm': offeredAtKm,
        'expiresAtKm': expiresAtKm,
        'headline': headline,
        'termsSummary': termsSummary,
        'targetLeaderTeamId': targetLeaderTeamId,
        'isCrashOrHazardNeutralization': isCrashOrHazardNeutralization,
      };

  factory IncomingRivalPactOffer.fromJson(Map<String, dynamic> json) {
    return IncomingRivalPactOffer(
      offerId: json['offerId'] as String? ?? '',
      pactType: DiplomacyPactType.fromJson(json['pactType'] as String? ?? ''),
      fromTeam: DiplomacyTeamContext.fromJson(
        json['fromTeam'] as Map<String, dynamic>? ?? const {},
      ),
      offeredAtKm: (json['offeredAtKm'] as num?)?.toDouble() ?? 0.0,
      expiresAtKm: (json['expiresAtKm'] as num?)?.toDouble() ?? 0.0,
      headline: json['headline'] as String? ?? '',
      termsSummary: json['termsSummary'] as String? ?? '',
      targetLeaderTeamId: json['targetLeaderTeamId'] as String?,
      isCrashOrHazardNeutralization:
          json['isCrashOrHazardNeutralization'] as bool? ?? false,
    );
  }
}

/// Wynik sesji negocjacji w modalu `InRaceDiplomacyRadioModal`.
class InRaceDiplomacyRadioResult {
  final PelotonDiplomacyState updatedState;
  final List<String> acceptedOfferIds;
  final List<String> rejectedOfferIds;
  final List<DiplomacyPact> newlyCreatedPacts;
  final List<BetrayalEvent> triggeredBetrayals;

  const InRaceDiplomacyRadioResult({
    required this.updatedState,
    this.acceptedOfferIds = const [],
    this.rejectedOfferIds = const [],
    this.newlyCreatedPacts = const [],
    this.triggeredBetrayals = const [],
  });
}

/// Wyświetla modal negocjacji na szosie `InRaceDiplomacyRadioModal`.
Future<InRaceDiplomacyRadioResult?> showInRaceDiplomacyRadioModal(
  BuildContext context, {
  required PelotonDiplomacyState initialState,
  required DiplomacyTeamContext playerTeam,
  required List<DiplomacyTeamContext> rivalCandidates,
  List<IncomingRivalPactOffer> incomingOffers = const [],
  required double currentStageKm,
  required double totalStageKm,
  String? targetLeaderTeamId,
  bool isInteractiveEnabled = true,
  DiplomacyRadioTab initialTab = DiplomacyRadioTab.incomingOffers,
}) {
  return showGeneralDialog<InRaceDiplomacyRadioResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Zamknij radio dyplomatyczne',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1080,
                maxHeight: 780,
              ),
              child: Material(
                color: Colors.transparent,
                child: InRaceDiplomacyRadioModal(
                  initialState: initialState,
                  playerTeam: playerTeam,
                  rivalCandidates: rivalCandidates,
                  incomingOffers: incomingOffers,
                  currentStageKm: currentStageKm,
                  totalStageKm: totalStageKm,
                  targetLeaderTeamId: targetLeaderTeamId,
                  isInteractiveEnabled: isInteractiveEnabled,
                  initialTab: initialTab,
                  onCloseWithResult: (result) {
                    Navigator.of(dialogContext).pop(result);
                  },
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

/// Interfejs negocjacji na szosie (`InRaceDiplomacyRadioModal`) pozwalający
/// zawierać lub odrzucać układy z rywalami podczas etapu przez radio wyścigowe.
class InRaceDiplomacyRadioModal extends StatefulWidget {
  final PelotonDiplomacyState initialState;
  final DiplomacyTeamContext playerTeam;
  final List<DiplomacyTeamContext> rivalCandidates;
  final List<IncomingRivalPactOffer> incomingOffers;
  final double currentStageKm;
  final double totalStageKm;
  final String? targetLeaderTeamId;
  final bool isInteractiveEnabled;
  final DiplomacyRadioTab initialTab;
  final ValueChanged<PelotonDiplomacyState>? onStateChanged;
  final ValueChanged<InRaceDiplomacyRadioResult>? onCloseWithResult;

  const InRaceDiplomacyRadioModal({
    super.key,
    required this.initialState,
    required this.playerTeam,
    required this.rivalCandidates,
    this.incomingOffers = const [],
    required this.currentStageKm,
    required this.totalStageKm,
    this.targetLeaderTeamId,
    this.isInteractiveEnabled = true,
    this.initialTab = DiplomacyRadioTab.incomingOffers,
    this.onStateChanged,
    this.onCloseWithResult,
  });

  @override
  State<InRaceDiplomacyRadioModal> createState() =>
      _InRaceDiplomacyRadioModalState();
}

class _InRaceDiplomacyRadioModalState extends State<InRaceDiplomacyRadioModal>
    with SingleTickerProviderStateMixin {
  late PelotonDiplomacyState _state;
  late List<IncomingRivalPactOffer> _pendingOffers;
  late DiplomacyRadioTab _activeTab;
  late AnimationController _radioPulseController;

  String? _selectedRivalTeamId;
  DiplomacyPactType _selectedPactType = DiplomacyPactType.stageForGcDeal;
  bool _isHazardTruce = false;
  PactProposalOutcome? _lastProposalOutcome;

  final List<String> _acceptedOfferIds = [];
  final List<String> _rejectedOfferIds = [];
  final List<DiplomacyPact> _newlyCreatedPacts = [];
  final List<BetrayalEvent> _triggeredBetrayals = [];
  final List<String> _radioLog = [];

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _pendingOffers = List<IncomingRivalPactOffer>.from(widget.incomingOffers);
    _activeTab = widget.initialTab;
    if (_pendingOffers.isEmpty &&
        _activeTab == DiplomacyRadioTab.incomingOffers) {
      _activeTab = widget.rivalCandidates.isNotEmpty
          ? DiplomacyRadioTab.proposePact
          : DiplomacyRadioTab.activePacts;
    }
    if (widget.rivalCandidates.isNotEmpty) {
      _selectedRivalTeamId = widget.rivalCandidates.first.teamId;
    }
    if (_state.latestRadioFeed.isNotEmpty) {
      _radioLog.add(_state.latestRadioFeed);
    }

    _radioPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _radioPulseController.dispose();
    super.dispose();
  }

  DiplomacyTeamContext? get _selectedRival {
    if (_selectedRivalTeamId == null) return null;
    for (final candidate in widget.rivalCandidates) {
      if (candidate.teamId == _selectedRivalTeamId) {
        return candidate;
      }
    }
    return null;
  }

  void _appendRadioLog(String message) {
    _radioLog.insert(0, message);
    if (_radioLog.length > 12) {
      _radioLog.removeLast();
    }
  }

  void _acceptIncomingOffer(IncomingRivalPactOffer offer) {
    if (!widget.isInteractiveEnabled) return;

    final bool duplicate = _state.activePacts.any(
      (p) =>
          p.isActive &&
          p.type == offer.pactType &&
          ((p.initiatorTeamId == offer.fromTeam.teamId &&
                  p.partnerTeamId == widget.playerTeam.teamId) ||
              (p.initiatorTeamId == widget.playerTeam.teamId &&
                  p.partnerTeamId == offer.fromTeam.teamId)),
    );

    if (duplicate) {
      final msg =
          'RADIO (${offer.fromTeam.teamName}): Taki pakt już obowiązuje na trasie.';
      setState(() {
        _pendingOffers.removeWhere((o) => o.offerId == offer.offerId);
        _state = _state.copyWith(latestRadioFeed: msg);
        _appendRadioLog(msg);
      });
      widget.onStateChanged?.call(_state);
      return;
    }

    final double kmRemaining =
        math.max(0.5, widget.totalStageKm - widget.currentStageKm);
    final double clampedExpiry = math.min(
      widget.totalStageKm,
      math.max(
        widget.currentStageKm + 1.0,
        offer.expiresAtKm > widget.currentStageKm
            ? offer.expiresAtKm
            : widget.currentStageKm + math.min(kmRemaining, 25.0),
      ),
    );

    final pact = DiplomacyPact(
      pactId:
          '${offer.pactType.name}_${offer.fromTeam.teamId}_${widget.playerTeam.teamId}_${widget.currentStageKm.toStringAsFixed(1)}',
      type: offer.pactType,
      status: DiplomacyPactStatus.active,
      initiatorTeamId: offer.fromTeam.teamId,
      initiatorTeamName: offer.fromTeam.teamName,
      initiatorRiderId: offer.fromTeam.riderId,
      partnerTeamId: widget.playerTeam.teamId,
      partnerTeamName: widget.playerTeam.teamName,
      partnerRiderId: widget.playerTeam.riderId,
      createdAtKm: widget.currentStageKm,
      expiresAtKm: clampedExpiry,
      cooperationBonusMultiplier: switch (offer.pactType) {
        DiplomacyPactType.stageForGcDeal => 1.38,
        DiplomacyPactType.antiLeaderCoalition => 1.32,
        DiplomacyPactType.neutralizationTruce => 1.0,
      },
      blocksAttacks: offer.pactType == DiplomacyPactType.neutralizationTruce,
      targetLeaderTeamId: offer.pactType == DiplomacyPactType.antiLeaderCoalition
          ? (offer.targetLeaderTeamId ?? widget.targetLeaderTeamId)
          : null,
      stageWinnerTeamId: offer.pactType == DiplomacyPactType.stageForGcDeal
          ? offer.fromTeam.teamId
          : null,
    );

    final String radioMsg =
        'RADIO (${widget.currentStageKm.toStringAsFixed(1)} km): Zaakceptowano '
        '${offer.pactType.displayName} od ${offer.fromTeam.riderName} '
        '(${offer.fromTeam.teamName}).';

    final Map<String, double> nextTrust = Map<String, double>.from(
      _state.teamTrustScores,
    );
    final double currentTrust = nextTrust[offer.fromTeam.teamId] ??
        offer.fromTeam.trustScore;
    nextTrust[offer.fromTeam.teamId] = math.min(100.0, currentTrust + 4.0);

    setState(() {
      _pendingOffers.removeWhere((o) => o.offerId == offer.offerId);
      _acceptedOfferIds.add(offer.offerId);
      _newlyCreatedPacts.add(pact);
      _state = _state.copyWith(
        activePacts: [..._state.activePacts, pact],
        teamTrustScores: nextTrust,
        latestRadioFeed: radioMsg,
      );
      _appendRadioLog(radioMsg);
    });
    widget.onStateChanged?.call(_state);
  }

  void _rejectIncomingOffer(IncomingRivalPactOffer offer) {
    if (!widget.isInteractiveEnabled) return;

    final String radioMsg =
        'RADIO (${widget.currentStageKm.toStringAsFixed(1)} km): Odrzucono ofertę '
        '${offer.pactType.displayName} od ${offer.fromTeam.teamName}.';

    final Map<String, double> nextTrust = Map<String, double>.from(
      _state.teamTrustScores,
    );
    final double currentTrust = nextTrust[offer.fromTeam.teamId] ??
        offer.fromTeam.trustScore;
    nextTrust[offer.fromTeam.teamId] = math.max(0.0, currentTrust - 2.0);

    setState(() {
      _pendingOffers.removeWhere((o) => o.offerId == offer.offerId);
      _rejectedOfferIds.add(offer.offerId);
      _state = _state.copyWith(
        teamTrustScores: nextTrust,
        latestRadioFeed: radioMsg,
      );
      _appendRadioLog(radioMsg);
    });
    widget.onStateChanged?.call(_state);
  }

  void _proposeNewPact() {
    if (!widget.isInteractiveEnabled) return;
    final rival = _selectedRival;
    if (rival == null) return;

    final result = InRacePelotonDiplomacyEngine.proposePact(
      state: _state,
      type: _selectedPactType,
      initiator: widget.playerTeam,
      partner: rival,
      currentStageKm: widget.currentStageKm,
      totalStageKm: widget.totalStageKm,
      targetLeaderTeamId: widget.targetLeaderTeamId,
      isCrashOrHazardNeutralization: _isHazardTruce,
    );

    setState(() {
      _lastProposalOutcome = result.outcome;
      _state = result.nextState;
      if (result.outcome.accepted && result.outcome.createdPact != null) {
        _newlyCreatedPacts.add(result.outcome.createdPact!);
      }
      _appendRadioLog(result.outcome.radioMessage);
    });
    widget.onStateChanged?.call(_state);
  }

  void _breakActivePact(DiplomacyPact pact) {
    if (!widget.isInteractiveEnabled) return;

    final result = InRacePelotonDiplomacyEngine.triggerManualBetrayal(
      state: _state,
      pactId: pact.pactId,
      betrayerTeamId: widget.playerTeam.teamId,
      currentStageKm: widget.currentStageKm,
    );

    setState(() {
      _state = result.nextState;
      _triggeredBetrayals.add(result.event);
      _appendRadioLog(result.event.radioHeadline);
    });
    widget.onStateChanged?.call(_state);
  }

  void _handleClose() {
    final result = InRaceDiplomacyRadioResult(
      updatedState: _state,
      acceptedOfferIds: List<String>.unmodifiable(_acceptedOfferIds),
      rejectedOfferIds: List<String>.unmodifiable(_rejectedOfferIds),
      newlyCreatedPacts: List<DiplomacyPact>.unmodifiable(_newlyCreatedPacts),
      triggeredBetrayals: List<BetrayalEvent>.unmodifiable(_triggeredBetrayals),
    );
    if (widget.onCloseWithResult != null) {
      widget.onCloseWithResult!(result);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isDesktopWide = constraints.maxWidth >= 900;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTopRadioHeader(isMobile: isMobile),
                _buildTabBar(isMobile: isMobile),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 18),
                    child: isDesktopWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _buildMainTabContent(isMobile: isMobile),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: _buildRadioSidePanel(isMobile: isMobile),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMainTabContent(isMobile: isMobile),
                              const SizedBox(height: 14),
                              _buildRadioSidePanel(isMobile: isMobile),
                            ],
                          ),
                  ),
                ),
                _buildBottomBar(isMobile: isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopRadioHeader({required bool isMobile}) {
    final double rep = _state.playerPelotonReputation;
    final Color repColor = rep >= 65
        ? AppColors.statusSuccess
        : (rep >= 40 ? AppColors.amberWarning : AppColors.crimsonAlert);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _radioPulseController,
            builder: (context, child) {
              final double pulse = 0.45 + 0.55 * _radioPulseController.value;
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: pulse),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.settings_input_antenna_rounded,
                  size: 18,
                  color: AppColors.goldAccent.withValues(alpha: 0.75 + 0.25 * pulse),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RADIO WYŚCIGOWE — DYPLOMACJA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.playerTeam.teamName} • ${widget.playerTeam.riderName}',
                  maxLines: 1,
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
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: [
              _TelemetryChip(
                label: 'ETAP',
                value:
                    '${widget.currentStageKm.toStringAsFixed(1)}/${widget.totalStageKm.toStringAsFixed(0)} km',
                color: AppColors.accentBlue,
              ),
              if (!isMobile)
                _TelemetryChip(
                  label: 'REPUTACJA',
                  value: '${rep.toStringAsFixed(0)}/100',
                  color: repColor,
                ),
            ],
          ),
          const SizedBox(width: 8),
          _RadioIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Zamknij radio',
            onTap: _handleClose,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 18,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _RadioTabChip(
              label: 'Oferty Przychodzące',
              badgeCount: _pendingOffers.length,
              badgeColor: AppColors.goldAccent,
              isSelected: _activeTab == DiplomacyRadioTab.incomingOffers,
              onTap: () => setState(
                () => _activeTab = DiplomacyRadioTab.incomingOffers,
              ),
            ),
            const SizedBox(width: 8),
            _RadioTabChip(
              label: 'Zaproponuj Układ',
              badgeCount: widget.rivalCandidates.length,
              badgeColor: AppColors.accentBlue,
              isSelected: _activeTab == DiplomacyRadioTab.proposePact,
              onTap: () => setState(
                () => _activeTab = DiplomacyRadioTab.proposePact,
              ),
            ),
            const SizedBox(width: 8),
            _RadioTabChip(
              label: 'Aktywne Pakty',
              badgeCount: _state.activePacts.length,
              badgeColor: AppColors.statusSuccess,
              isSelected: _activeTab == DiplomacyRadioTab.activePacts,
              onTap: () => setState(
                () => _activeTab = DiplomacyRadioTab.activePacts,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabContent({required bool isMobile}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: switch (_activeTab) {
        DiplomacyRadioTab.incomingOffers => _buildIncomingOffersTab(
            key: const ValueKey('incoming'),
            isMobile: isMobile,
          ),
        DiplomacyRadioTab.proposePact => _buildProposePactTab(
            key: const ValueKey('propose'),
            isMobile: isMobile,
          ),
        DiplomacyRadioTab.activePacts => _buildActivePactsTab(
            key: const ValueKey('active'),
            isMobile: isMobile,
          ),
      },
    );
  }

  Widget _buildIncomingOffersTab({Key? key, required bool isMobile}) {
    if (_pendingOffers.isEmpty) {
      return _EmptyStateCard(
        key: key,
        icon: Icons.mark_chat_read_outlined,
        title: 'Brak oczekujących ofert radiowych',
        subtitle:
            'Rywale nie wysłali nowych propozycji układów na tym odcinku. '
            'Możesz samodzielnie wywołać rywala w zakładce „Zaproponuj Układ”.',
        actionLabel: widget.rivalCandidates.isNotEmpty
            ? 'Przejdź do propozycji'
            : null,
        onAction: widget.rivalCandidates.isNotEmpty
            ? () => setState(() => _activeTab = DiplomacyRadioTab.proposePact)
            : null,
      );
    }

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _pendingOffers.length; i++) ...[
          _IncomingOfferCard(
            offer: _pendingOffers[i],
            trustScore: _state.trustForTeam(_pendingOffers[i].fromTeam.teamId),
            vendettaStages:
                _state.vendettaForTeam(_pendingOffers[i].fromTeam.teamId),
            isMobile: isMobile,
            isEnabled: widget.isInteractiveEnabled,
            onAccept: () => _acceptIncomingOffer(_pendingOffers[i]),
            onReject: () => _rejectIncomingOffer(_pendingOffers[i]),
          ),
          if (i < _pendingOffers.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildProposePactTab({Key? key, required bool isMobile}) {
    if (widget.rivalCandidates.isEmpty) {
      return _EmptyStateCard(
        key: key,
        icon: Icons.group_off_outlined,
        title: 'Brak rywali w zasięgu radia',
        subtitle:
            'W Twojej grupie nie ma obecnie kolarzy innych ekip dostępnych do negocjacji.',
      );
    }

    final selected = _selectedRival;
    final double selectedTrust =
        selected != null ? _state.trustForTeam(selected.teamId) : 0.0;
    final int selectedVendetta =
        selected != null ? _state.vendettaForTeam(selected.teamId) : 0;

    return Container(
      key: key,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. WYBIERZ RYWALA W GRUPIE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.rivalCandidates.map((candidate) {
              final bool isSelected = candidate.teamId == _selectedRivalTeamId;
              final int vendetta = _state.vendettaForTeam(candidate.teamId);
              final double trust = _state.trustForTeam(candidate.teamId);
              return _RivalSelectorPill(
                candidate: candidate,
                trustScore: trust,
                vendettaStages: vendetta,
                isSelected: isSelected,
                isEnabled: widget.isInteractiveEnabled,
                onTap: () => setState(() {
                  _selectedRivalTeamId = candidate.teamId;
                  _lastProposalOutcome = null;
                }),
              );
            }).toList(),
          ),
          if (selected != null) ...[
            const SizedBox(height: 12),
            _RivalContextSummaryStrip(
              rival: selected,
              trustScore: selectedTrust,
              vendettaStages: selectedVendetta,
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            '2. RODZAJ UKŁADU TAKTYCZNEGO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: DiplomacyPactType.values.map((pactType) {
              final bool isSelected = _selectedPactType == pactType;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PactTypeOptionCard(
                  pactType: pactType,
                  isSelected: isSelected,
                  isEnabled: widget.isInteractiveEnabled,
                  onTap: () => setState(() {
                    _selectedPactType = pactType;
                    _lastProposalOutcome = null;
                  }),
                ),
              );
            }).toList(),
          ),
          if (_selectedPactType == DiplomacyPactType.neutralizationTruce) ...[
            const SizedBox(height: 4),
            _RadioToggleRow(
              label: 'Neutralizacja po kraksie lub zagrożeniu na trasie',
              value: _isHazardTruce,
              enabled: widget.isInteractiveEnabled,
              onChanged: (v) => setState(() => _isHazardTruce = v),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _RadioActionButton(
              label: selected != null
                  ? 'Nadaj propozycję do ${selected.teamName}'
                  : 'Nadaj propozycję',
              icon: Icons.send_rounded,
              variant: _RadioButtonVariant.primaryGold,
              enabled: widget.isInteractiveEnabled && selected != null,
              onPressed: _proposeNewPact,
            ),
          ),
          if (_lastProposalOutcome != null) ...[
            const SizedBox(height: 12),
            _ProposalOutcomeBanner(outcome: _lastProposalOutcome!),
          ],
        ],
      ),
    );
  }

  Widget _buildActivePactsTab({Key? key, required bool isMobile}) {
    if (_state.activePacts.isEmpty) {
      return _EmptyStateCard(
        key: key,
        icon: Icons.handshake_outlined,
        title: 'Brak aktywnych paktów na etapie',
        subtitle:
            'Nie zawarto jeszcze żadnego sojuszu. Przyjmij ofertę rywala lub zaproponuj układ w radiu.',
      );
    }

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _state.activePacts.length; i++) ...[
          _ActivePactCard(
            pact: _state.activePacts[i],
            currentStageKm: widget.currentStageKm,
            isEnabled: widget.isInteractiveEnabled,
            isMobile: isMobile,
            onBetray: () => _breakActivePact(_state.activePacts[i]),
          ),
          if (i < _state.activePacts.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildRadioSidePanel({required bool isMobile}) {
    final BetrayalEvent? betrayal = _state.latestBetrayalAlert;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (betrayal != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.crimsonAlert.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.crimsonAlert.withValues(alpha: 0.75),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.crimsonAlert,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ALERT ZDRADY (BETRAYAL!)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.crimsonAlert,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  betrayal.radioHeadline,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wendeta: ${betrayal.vendettaStagesAssigned} et. • '
                  'Reputacja: ${betrayal.pelotonReputationDelta.toStringAsFixed(0)} pkt',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: EdgeInsets.all(isMobile ? 14 : 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    size: 16,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'NASŁUCH RADIA WYŚCIGOWEGO',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${_state.activePacts.length} akt.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.goldAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_radioLog.isEmpty)
                const Text(
                  'Brak zarejestrowanych transmisji dyplomatycznych.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _radioLog.take(5).map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        entry,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Przyjęto: ${_acceptedOfferIds.length} • Odrzucono: ${_rejectedOfferIds.length} • Nowe pakty: ${_newlyCreatedPacts.length}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _RadioActionButton(
            label: 'Wróć na trasę',
            icon: Icons.check_circle_outline_rounded,
            variant: _RadioButtonVariant.secondary,
            enabled: true,
            onPressed: _handleClose,
          ),
        ],
      ),
    );
  }
}

class _IncomingOfferCard extends StatelessWidget {
  final IncomingRivalPactOffer offer;
  final double trustScore;
  final int vendettaStages;
  final bool isMobile;
  final bool isEnabled;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingOfferCard({
    required this.offer,
    required this.trustScore,
    required this.vendettaStages,
    required this.isMobile,
    required this.isEnabled,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final Color typeColor = switch (offer.pactType) {
      DiplomacyPactType.stageForGcDeal => AppColors.goldAccent,
      DiplomacyPactType.antiLeaderCoalition => AppColors.accentBlue,
      DiplomacyPactType.neutralizationTruce => AppColors.statusSuccess,
    };

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: typeColor.withValues(alpha: 0.55)),
                ),
                child: Text(
                  offer.pactType.displayName.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
              _TelemetryChip(
                label: 'ZAKRES',
                value:
                    '${offer.offeredAtKm.toStringAsFixed(1)}–${offer.expiresAtKm.toStringAsFixed(1)} km',
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            offer.headline,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            offer.termsSummary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _RivalContextSummaryStrip(
            rival: offer.fromTeam,
            trustScore: trustScore,
            vendettaStages: vendettaStages,
          ),
          const SizedBox(height: 14),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RadioActionButton(
                  label: 'Zawrzyj układ',
                  icon: Icons.handshake_rounded,
                  variant: _RadioButtonVariant.acceptSuccess,
                  enabled: isEnabled,
                  onPressed: onAccept,
                ),
                const SizedBox(height: 8),
                _RadioActionButton(
                  label: 'Odrzuć ofertę',
                  icon: Icons.close_rounded,
                  variant: _RadioButtonVariant.rejectDanger,
                  enabled: isEnabled,
                  onPressed: onReject,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _RadioActionButton(
                    label: 'Odrzuć ofertę',
                    icon: Icons.close_rounded,
                    variant: _RadioButtonVariant.rejectDanger,
                    enabled: isEnabled,
                    onPressed: onReject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RadioActionButton(
                    label: 'Zawrzyj układ',
                    icon: Icons.handshake_rounded,
                    variant: _RadioButtonVariant.acceptSuccess,
                    enabled: isEnabled,
                    onPressed: onAccept,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivePactCard extends StatelessWidget {
  final DiplomacyPact pact;
  final double currentStageKm;
  final bool isEnabled;
  final bool isMobile;
  final VoidCallback onBetray;

  const _ActivePactCard({
    required this.pact,
    required this.currentStageKm,
    required this.isEnabled,
    required this.isMobile,
    required this.onBetray,
  });

  @override
  Widget build(BuildContext context) {
    final double totalSpan = math.max(0.5, pact.expiresAtKm - pact.createdAtKm);
    final double progress =
        ((currentStageKm - pact.createdAtKm) / totalSpan).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusSuccess.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${pact.type.displayName} • ${pact.partnerTeamName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TelemetryChip(
                label: 'BONUS',
                value:
                    'x${pact.cooperationBonusMultiplier.toStringAsFixed(2)}',
                color: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${pact.initiatorTeamName} ↔ ${pact.partnerTeamName} • '
            'do ${pact.expiresAtKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.statusSuccess,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _RadioActionButton(
              label: 'Zerwij pakt (Zdrada!)',
              icon: Icons.gpp_bad_outlined,
              variant: _RadioButtonVariant.rejectDanger,
              enabled: isEnabled,
              onPressed: onBetray,
            ),
          ),
        ],
      ),
    );
  }
}

class _RivalSelectorPill extends StatefulWidget {
  final DiplomacyTeamContext candidate;
  final double trustScore;
  final int vendettaStages;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _RivalSelectorPill({
    required this.candidate,
    required this.trustScore,
    required this.vendettaStages,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_RivalSelectorPill> createState() => _RivalSelectorPillState();
}

class _RivalSelectorPillState extends State<_RivalSelectorPill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool hostile = widget.vendettaStages > 0;
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.goldAccent.withValues(alpha: 0.14)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hostile)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: AppColors.crimsonAlert,
                    ),
                  ),
                Text(
                  '${widget.candidate.riderName} (${widget.candidate.teamName})',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.trustScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: hostile
                        ? AppColors.crimsonAlert
                        : AppColors.accentBlue,
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

class _RivalContextSummaryStrip extends StatelessWidget {
  final DiplomacyTeamContext rival;
  final double trustScore;
  final int vendettaStages;

  const _RivalContextSummaryStrip({
    required this.rival,
    required this.trustScore,
    required this.vendettaStages,
  });

  @override
  Widget build(BuildContext context) {
    final String gapFormatted = rival.gcGapToLeaderSeconds <= 0
        ? 'Lider GC'
        : '+${(rival.gcGapToLeaderSeconds / 60).floor()}:${(rival.gcGapToLeaderSeconds % 60).toStringAsFixed(0).padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          _TelemetryChip(
            label: 'GC',
            value: '#${rival.gcPosition} ($gapFormatted)',
            color: rival.isRaceLeader
                ? AppColors.goldAccent
                : AppColors.textPrimary,
          ),
          _TelemetryChip(
            label: 'ZAUFANIE',
            value: '${trustScore.toStringAsFixed(0)}/100',
            color: trustScore >= 55
                ? AppColors.statusSuccess
                : (trustScore >= 30
                    ? AppColors.amberWarning
                    : AppColors.crimsonAlert),
          ),
          _TelemetryChip(
            label: 'POZYCJA',
            value: rival.isInSameGroup ? 'Ta sama grupa' : 'Inna grupa',
            color: rival.isInSameGroup
                ? AppColors.accentBlue
                : AppColors.amberWarning,
          ),
          if (vendettaStages > 0)
            _TelemetryChip(
              label: 'WENDETA',
              value: '$vendettaStages et.',
              color: AppColors.crimsonAlert,
            ),
        ],
      ),
    );
  }
}

class _PactTypeOptionCard extends StatefulWidget {
  final DiplomacyPactType pactType;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _PactTypeOptionCard({
    required this.pactType,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_PactTypeOptionCard> createState() => _PactTypeOptionCardState();
}

class _PactTypeOptionCardState extends State<_PactTypeOptionCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.goldAccent.withValues(alpha: 0.12)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pactType.displayName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.pactType.shortDescription,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
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

class _ProposalOutcomeBanner extends StatelessWidget {
  final PactProposalOutcome outcome;

  const _ProposalOutcomeBanner({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final Color color =
        outcome.accepted ? AppColors.statusSuccess : AppColors.amberWarning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            outcome.accepted
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outcome.radioMessage,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  outcome.rationale,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            _RadioActionButton(
              label: actionLabel!,
              icon: Icons.arrow_forward_rounded,
              variant: _RadioButtonVariant.primaryGold,
              enabled: true,
              onPressed: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

class _RadioTabChip extends StatefulWidget {
  final String label;
  final int badgeCount;
  final Color badgeColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioTabChip({
    required this.label,
    required this.badgeCount,
    required this.badgeColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RadioTabChip> createState() => _RadioTabChipState();
}

class _RadioTabChipState extends State<_RadioTabChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primaryAccent.withValues(alpha: 0.25)
                  : (_hovered ? AppColors.surfaceLight : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.goldAccent
                    : (_focused
                        ? AppColors.accentBlue
                        : AppColors.cardBorder),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.badgeCount}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: widget.badgeColor,
                    ),
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

class _RadioToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _RadioToggleRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: enabled ? (v) => onChanged(v ?? false) : null,
              activeColor: AppColors.goldAccent,
              checkColor: AppColors.background,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RadioButtonVariant {
  primaryGold,
  acceptSuccess,
  rejectDanger,
  secondary,
}

class _RadioActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final _RadioButtonVariant variant;
  final bool enabled;
  final VoidCallback onPressed;

  const _RadioActionButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_RadioActionButton> createState() => _RadioActionButtonState();
}

class _RadioActionButtonState extends State<_RadioActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (widget.variant) {
      _RadioButtonVariant.primaryGold => AppColors.goldAccent,
      _RadioButtonVariant.acceptSuccess => AppColors.statusSuccess,
      _RadioButtonVariant.rejectDanger => AppColors.crimsonAlert,
      _RadioButtonVariant.secondary => AppColors.textSecondary,
    };

    final Color bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? accent.withValues(alpha: 0.28)
            : (_hovered
                ? accent.withValues(alpha: 0.22)
                : accent.withValues(alpha: 0.14)));

    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder
        : (_focused ? AppColors.accentBlue : accent.withValues(alpha: 0.65));

    final Color fgColor =
        widget.enabled ? AppColors.textPrimary : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.enabled ? accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                    ),
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

class _RadioIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RadioIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_RadioIconButton> createState() => _RadioIconButtonState();
}

class _RadioIconButtonState extends State<_RadioIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused ? AppColors.accentBlue : AppColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.38), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
