// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/junior_development_loan_system_service.dart';

/// Filtr dywizji klubów partnerskich w oknie zarządzania wypożyczeniami.
enum LoanPartnerDivisionFilter {
  all('Wszystkie'),
  proTeam('ProTeam'),
  continental('Continental');

  final String label;

  const LoanPartnerDivisionFilter(this.label);

  bool matches(LoanPartnerDivision division) {
    switch (this) {
      case LoanPartnerDivisionFilter.all:
        return true;
      case LoanPartnerDivisionFilter.proTeam:
        return division == LoanPartnerDivision.proTeam;
      case LoanPartnerDivisionFilter.continental:
        return division == LoanPartnerDivision.continental;
    }
  }
}

/// Kryterium sortowania listy klubów partnerskich.
enum LoanPartnerSortOrder {
  guaranteedDays('Dni wyścigowe'),
  salaryCoverage('Pokrycie pensji'),
  friendship('Relacje'),
  coaching('Szkolenie');

  final String label;

  const LoanPartnerSortOrder(this.label);
}

/// Zakładka mobilna / kompaktowa modalu wypożyczeń.
enum RiderLoanModalTab {
  partnerClubs('Kluby Partnerskie'),
  dealTerms('Dni & Pensja'),
  activeLoans('Aktywne Umowy');

  final String label;

  const RiderLoanModalTab(this.label);
}

/// Wynik sesji zarządzania wypożyczeniami zwrócony przy zamknięciu modalu.
class RiderLoanManagementModalResult {
  final int activeLoansCount;
  final String? lastActionMessage;
  final String? selectedCandidateId;
  final String? selectedPartnerId;

  const RiderLoanManagementModalResult({
    required this.activeLoansCount,
    this.lastActionMessage,
    this.selectedCandidateId,
    this.selectedPartnerId,
  });
}

/// Otwiera okno zarządzania wypożyczeniami młodych kolarzy [RiderLoanManagementModal].
Future<RiderLoanManagementModalResult?> showRiderLoanManagementModal(
  BuildContext context, {
  String? initialCandidateId,
  String? initialPartnerId,
  bool isReadOnly = false,
}) {
  return showGeneralDialog<RiderLoanManagementModalResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Zamknij okno wypożyczeń juniorów',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1180,
                maxHeight: 840,
              ),
              child: Material(
                color: Colors.transparent,
                child: RiderLoanManagementModal(
                  initialCandidateId: initialCandidateId,
                  initialPartnerId: initialPartnerId,
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

/// Okno zarządzania wypożyczeniami młodych kolarzy do klubów partnerskich.
///
/// Prezentuje:
/// - listę zaprzyjaźnionych klubów ProTeam i Continental z wolnymi miejscami,
/// - gwarantowaną liczbę dni wyścigowych dla juniora vs ławkę WorldTour,
/// - podział pokrycia pensji pomiędzy klub partnerski a drużynę macierzystą,
/// - zarządzanie aktywnymi umowami (symulacja postępów oraz awaryjne ściągnięcie).
class RiderLoanManagementModal extends ConsumerStatefulWidget {
  final String? initialCandidateId;
  final String? initialPartnerId;
  final bool isReadOnly;
  final VoidCallback? onClose;

  const RiderLoanManagementModal({
    super.key,
    this.initialCandidateId,
    this.initialPartnerId,
    this.isReadOnly = false,
    this.onClose,
  });

  @override
  ConsumerState<RiderLoanManagementModal> createState() =>
      _RiderLoanManagementModalState();
}

class _RiderLoanManagementModalState
    extends ConsumerState<RiderLoanManagementModal> {
  static const Color _borderColor = Color(0xFF2A2F3D);
  static const String _fontFamily = 'Inter';

  LoanPartnerDivisionFilter _divisionFilter = LoanPartnerDivisionFilter.all;
  LoanPartnerSortOrder _sortOrder = LoanPartnerSortOrder.guaranteedDays;
  RiderLoanModalTab _mobileTab = RiderLoanModalTab.partnerClubs;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(juniorDevelopmentLoanProvider.notifier);
      if (widget.initialCandidateId != null) {
        notifier.selectCandidate(widget.initialCandidateId!);
      }
      if (widget.initialPartnerId != null) {
        notifier.selectPartner(widget.initialPartnerId!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PartnerClubProfile> _filteredPartners(List<PartnerClubProfile> clubs) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = clubs.where((club) {
      if (!_divisionFilter.matches(club.division)) return false;
      if (query.isEmpty) return true;
      return club.name.toLowerCase().contains(query) ||
          club.shortCode.toLowerCase().contains(query) ||
          club.countryIso.toLowerCase().contains(query) ||
          club.calendarFocus.label.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOrder) {
        case LoanPartnerSortOrder.guaranteedDays:
          final cmp = b.guaranteedRaceDays.compareTo(a.guaranteedRaceDays);
          return cmp != 0 ? cmp : b.friendshipScore.compareTo(a.friendshipScore);
        case LoanPartnerSortOrder.salaryCoverage:
          final cmp = b.salarySharePercent.compareTo(a.salarySharePercent);
          return cmp != 0
              ? cmp
              : b.guaranteedRaceDays.compareTo(a.guaranteedRaceDays);
        case LoanPartnerSortOrder.friendship:
          return b.friendshipScore.compareTo(a.friendshipScore);
        case LoanPartnerSortOrder.coaching:
          return b.coachingQuality.compareTo(a.coachingQuality);
      }
    });
    return filtered;
  }

  void _handleClose(JuniorLoanSystemState state) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    final activeCount = state.agreements
        .where((a) => a.status == LoanContractStatus.active)
        .length;
    Navigator.of(context).maybePop(
      RiderLoanManagementModalResult(
        activeLoansCount: activeCount,
        lastActionMessage: state.lastFeedbackMessage,
        selectedCandidateId: state.selectedCandidateId,
        selectedPartnerId: state.selectedPartnerId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(juniorDevelopmentLoanProvider);
    final service = ref.watch(juniorDevelopmentLoanServiceProvider);
    final notifier = ref.read(juniorDevelopmentLoanProvider.notifier);

    final audit = service.auditWorldTourRoster(
      wtRosterSize: state.wtRosterSize,
      injuredCount: state.injuredWtCount,
      juniors: state.candidates,
      agreements: state.agreements,
    );

    final filteredPartners = _filteredPartners(state.partnerClubs);
    final selectedCandidate = state.selectedCandidate ??
        (state.candidates.isNotEmpty ? state.candidates.first : null);
    final selectedPartner = state.selectedPartner ??
        (filteredPartners.isNotEmpty
            ? filteredPartners.first
            : (state.partnerClubs.isNotEmpty ? state.partnerClubs.first : null));

    final LoanProgressionComparison? comparison =
        (selectedCandidate != null && selectedPartner != null)
            ? service.compareLoanVsBench(
                candidate: selectedCandidate,
                partner: selectedPartner,
                focus: state.selectedFocus,
                recallClause: state.selectedRecallClause,
              )
            : null;

    final activeAgreements = state.agreements
        .where((a) => a.status == LoanContractStatus.active)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final isTablet = width >= 700 && width < 1020;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(
                  state: state,
                  audit: audit,
                  notifier: notifier,
                  isMobile: isMobile,
                ),
                if (state.lastFeedbackMessage != null)
                  _buildFeedbackBanner(
                    message: state.lastFeedbackMessage!,
                    isError: state.lastFeedbackIsError,
                  ),
                Expanded(
                  child: isMobile
                      ? _buildMobileLayout(
                          state: state,
                          audit: audit,
                          notifier: notifier,
                          filteredPartners: filteredPartners,
                          selectedCandidate: selectedCandidate,
                          selectedPartner: selectedPartner,
                          comparison: comparison,
                          activeAgreements: activeAgreements,
                        )
                      : isTablet
                          ? _buildTabletLayout(
                              state: state,
                              notifier: notifier,
                              filteredPartners: filteredPartners,
                              selectedCandidate: selectedCandidate,
                              selectedPartner: selectedPartner,
                              comparison: comparison,
                              activeAgreements: activeAgreements,
                            )
                          : _buildDesktopLayout(
                              state: state,
                              notifier: notifier,
                              filteredPartners: filteredPartners,
                              selectedCandidate: selectedCandidate,
                              selectedPartner: selectedPartner,
                              comparison: comparison,
                              activeAgreements: activeAgreements,
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required JuniorLoanSystemState state,
    required JuniorLoanRosterAudit audit,
    required JuniorLoanSystemNotifier notifier,
    required bool isMobile,
  }) {
    final plagueActive = audit.isInjuryPlagueActive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                fit: isMobile ? FlexFit.tight : FlexFit.loose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zarządzanie Wypożyczeniami Juniorów',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sezon ${state.seasonYear} • Kadra WT ${audit.wtRosterSize}/${audit.maxWtRosterLimit} • Aktywne wypożyczenia: ${audit.activeLoansCount}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LoanModalButton(
                label: plagueActive ? 'Plaga kontuzji ON' : 'Symuluj kontuzje',
                icon: plagueActive
                    ? Icons.medical_services_rounded
                    : Icons.health_and_safety_outlined,
                isDisabled: widget.isReadOnly,
                accentColor:
                    plagueActive ? AppColors.crimsonAlert : AppColors.surfaceLight,
                textColor:
                    plagueActive ? AppColors.textPrimary : AppColors.textSecondary,
                onTap: notifier.toggleInjuryPlagueSimulation,
              ),
              _LoanModalButton(
                label: 'Zamknij',
                icon: Icons.close_rounded,
                accentColor: AppColors.surfaceLight,
                textColor: AppColors.textPrimary,
                onTap: () => _handleClose(state),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required String message,
    required bool isError,
  }) {
    final tone = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        border: Border(
          bottom: BorderSide(color: tone.withValues(alpha: 0.45), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 18,
            color: tone,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout({
    required JuniorLoanSystemState state,
    required JuniorLoanSystemNotifier notifier,
    required List<PartnerClubProfile> filteredPartners,
    required JuniorLoanCandidate? selectedCandidate,
    required PartnerClubProfile? selectedPartner,
    required LoanProgressionComparison? comparison,
    required List<JuniorLoanAgreement> activeAgreements,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 270,
            child: _buildCandidatesColumn(
              state: state,
              notifier: notifier,
              selectedCandidate: selectedCandidate,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: _buildPartnerClubsPanel(
              state: state,
              notifier: notifier,
              partners: filteredPartners,
              selectedPartner: selectedPartner,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDealTermsInspector(
                    state: state,
                    notifier: notifier,
                    candidate: selectedCandidate,
                    partner: selectedPartner,
                    comparison: comparison,
                  ),
                  const SizedBox(height: 14),
                  _buildActiveLoansSection(
                    state: state,
                    notifier: notifier,
                    activeAgreements: activeAgreements,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout({
    required JuniorLoanSystemState state,
    required JuniorLoanSystemNotifier notifier,
    required List<PartnerClubProfile> filteredPartners,
    required JuniorLoanCandidate? selectedCandidate,
    required PartnerClubProfile? selectedPartner,
    required LoanProgressionComparison? comparison,
    required List<JuniorLoanAgreement> activeAgreements,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _buildCompactCandidateStrip(
            state: state,
            notifier: notifier,
            selectedCandidate: selectedCandidate,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildPartnerClubsPanel(
                    state: state,
                    notifier: notifier,
                    partners: filteredPartners,
                    selectedPartner: selectedPartner,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDealTermsInspector(
                          state: state,
                          notifier: notifier,
                          candidate: selectedCandidate,
                          partner: selectedPartner,
                          comparison: comparison,
                        ),
                        const SizedBox(height: 12),
                        _buildActiveLoansSection(
                          state: state,
                          notifier: notifier,
                          activeAgreements: activeAgreements,
                        ),
                      ],
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

  Widget _buildMobileLayout({
    required JuniorLoanSystemState state,
    required JuniorLoanRosterAudit audit,
    required JuniorLoanSystemNotifier notifier,
    required List<PartnerClubProfile> filteredPartners,
    required JuniorLoanCandidate? selectedCandidate,
    required PartnerClubProfile? selectedPartner,
    required LoanProgressionComparison? comparison,
    required List<JuniorLoanAgreement> activeAgreements,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompactCandidateStrip(
            state: state,
            notifier: notifier,
            selectedCandidate: selectedCandidate,
          ),
          const SizedBox(height: 10),
          _buildMobileTabBar(activeLoansCount: activeAgreements.length),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              child: switch (_mobileTab) {
                RiderLoanModalTab.partnerClubs => _buildPartnerClubsPanel(
                    key: const ValueKey('mobile_partners'),
                    state: state,
                    notifier: notifier,
                    partners: filteredPartners,
                    selectedPartner: selectedPartner,
                  ),
                RiderLoanModalTab.dealTerms => SingleChildScrollView(
                    key: const ValueKey('mobile_terms'),
                    child: _buildDealTermsInspector(
                      state: state,
                      notifier: notifier,
                      candidate: selectedCandidate,
                      partner: selectedPartner,
                      comparison: comparison,
                    ),
                  ),
                RiderLoanModalTab.activeLoans => SingleChildScrollView(
                    key: const ValueKey('mobile_loans'),
                    child: _buildActiveLoansSection(
                      state: state,
                      notifier: notifier,
                      activeAgreements: activeAgreements,
                    ),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabBar({required int activeLoansCount}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: RiderLoanModalTab.values.map((tab) {
          final isSelected = _mobileTab == tab;
          final label = tab == RiderLoanModalTab.activeLoans
              ? '${tab.label} ($activeLoansCount)'
              : tab.label;
          return Expanded(
            child: _LoanModalChipButton(
              label: label,
              isSelected: isSelected,
              onTap: () => setState(() => _mobileTab = tab),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactCandidateStrip({
    required JuniorLoanSystemState state,
    required JuniorLoanSystemNotifier notifier,
    required JuniorLoanCandidate? selectedCandidate,
  }) {
    if (state.candidates.isEmpty) {
      return _buildEmptyCard('Brak juniorów w kadrze WorldTour do wypożyczenia.');
    }
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.candidates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final candidate = state.candidates[index];
          final isSelected = selectedCandidate?.riderId == candidate.riderId;
          return SizedBox(
            width: 218,
            child: _LoanSelectableCard(
              isSelected: isSelected,
              onTap: () => notifier.selectCandidate(candidate.riderId),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            candidate.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(
                          text: candidate.isCurrentlyOnLoan
                              ? 'WYPOŻ.'
                              : '${candidate.age}l',
                          color: candidate.isCurrentlyOnLoan
                              ? AppColors.accentBlue
                              : AppColors.goldAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OVR ${candidate.overallRating.toStringAsFixed(1)} • POT ${candidate.potential} • WT ${candidate.projectedWtRaceDays} dni',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCandidatesColumn({
    required JuniorLoanSystemState state,
    required JuniorLoanSystemNotifier notifier,
    required JuniorLoanCandidate? selectedCandidate,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_bike_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Juniorzy w Kadrze WT',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(
                text: '${state.candidates.length}',
                color: AppColors.surfaceLight,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: state.candidates.isEmpty
                ? _buildEmptyCard('Brak juniorów w kadrze.')
                : ListView.separated(
                    itemCount: state.candidates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final candidate = state.candidates[index];
                      final isSelected =
                          selectedCandidate?.riderId == candidate.riderId;
                      return _LoanSelectableCard(
                        isSelected: isSelected,
                        onTap: () => notifier.selectCandidate(candidate.riderId),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      candidate.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _StatusBadge(
                                    text: '${candidate.age} lat',
                                    color: AppColors.surfaceLight,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${candidate.nationalityIso} • ${candidate.specialization.displayName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _MetricInline(
                                    label: 'OVR/POT',
                                    value:
                                        '${candidate.overallRating.toStringAsFixed(1)}/${candidate.potential}',
                                  ),
                                  _MetricInline(
                                    label: 'Pensja/rok',
                                    value: Formatters.formatCurrency(
                                      candidate.annualSalaryEur,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _StatusBadge(
                                    text: candidate.isCurrentlyOnLoan
                                        ? 'Na wypożyczeniu'
                                        : candidate.isInjured
                                            ? 'Kontuzja'
                                            : candidate.isBenchStagnating
                                                ? 'Ławka: ${candidate.projectedWtRaceDays} dni'
                                                : 'WT: ${candidate.projectedWtRaceDays} dni',
                                    color: candidate.isCurrentlyOnLoan
                                        ? AppColors.accentBlue
                                        : candidate.isInjured
                                            ? AppColors.crimsonAlert
                                            : candidate.isBenchStagnating
                                                ? AppColors.amberWarning
                                                : AppColors.statusSuccess,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerClubsPanel({
    Key? key,
    required JuniorLoanSystemState state,
    required JuniorLoanSystemNotifier notifier,
    required List<PartnerClubProfile> partners,
    required PartnerClubProfile? selectedPartner,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake_outlined,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kluby Partnerskie (ProTeam & Continental)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(
                text: '${partners.length}',
                color: AppColors.surfaceLight,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 12.5,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Szukaj klubu, kodu lub specjalizacji...',
              hintStyle: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...LoanPartnerDivisionFilter.values.map(
                (filter) => _LoanModalChipButton(
                  label: filter.label,
                  isSelected: _divisionFilter == filter,
                  onTap: () => setState(() => _divisionFilter = filter),
                ),
              ),
              const SizedBox(width: 4),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: DropdownButton<LoanPartnerSortOrder>(
                    value: _sortOrder,
                    dropdownColor: AppColors.surfaceLight,
                    iconEnabledColor: AppColors.textSecondary,
                    isDense: true,
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    items: LoanPartnerSortOrder.values
                        .map(
                          (order) => DropdownMenuItem(
                            value: order,
                            child: Text('Sort: ${order.label}'),
                          ),
                        )
                        .toList(),
                    onChanged: (next) {
                      if (next != null) {
                        setState(() => _sortOrder = next);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: partners.isEmpty
                ? _buildEmptyCard('Brak klubów partnerskich spełniających kryteria.')
                : ListView.separated(
                    itemCount: partners.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final club = partners[index];
                      final isSelected = selectedPartner?.id == club.id;
                      final divisionColor =
                          club.division == LoanPartnerDivision.proTeam
                              ? AppColors.accentBlue
                              : AppColors.goldAccent;
                      final parentShare = 100 - club.salarySharePercent;

                      return _LoanSelectableCard(
                        isSelected: isSelected,
                        onTap: () => notifier.selectPartner(club.id),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: divisionColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color:
                                            divisionColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      club.shortCode,
                                      style: TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: divisionColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      club.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: _fontFamily,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _StatusBadge(
                                    text: club.hasOpenSlot
                                        ? '${club.availableRosterSlots} wolne'
                                        : 'Brak miejsc',
                                    color: club.hasOpenSlot
                                        ? AppColors.statusSuccess
                                        : AppColors.crimsonAlert,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${club.division.label} • ${club.countryIso} • Cel: ${club.calendarFocus.label}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: _fontFamily,
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 14,
                                runSpacing: 6,
                                children: [
                                  _MetricInline(
                                    label: 'Gwarantowane dni',
                                    value: '${club.guaranteedRaceDays} dni',
                                    valueColor: AppColors.statusSuccess,
                                  ),
                                  _MetricInline(
                                    label: 'Pokrycie pensji',
                                    value:
                                        '${club.salarySharePercent}% / $parentShare%',
                                    valueColor: AppColors.goldAccent,
                                  ),
                                  _MetricInline(
                                    label: 'Relacje',
                                    value: '${club.friendshipScore}/100',
                                  ),
                                  _MetricInline(
                                    label: 'Szkolenie',
                                    value: '${club.coachingQuality}/100',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealTermsInspector({
    required JuniorLoanSystemState state,
    required JuniorLoanSystemNotifier notifier,
    required JuniorLoanCandidate? candidate,
    required PartnerClubProfile? partner,
    required LoanProgressionComparison? comparison,
  }) {
    if (candidate == null || partner == null || comparison == null) {
      return _buildEmptyCard(
        'Wybierz juniora oraz klub partnerski, aby zobaczyć szczegóły dni wyścigowych i podziału pensji.',
      );
    }

    final partnerPercent = partner.salarySharePercent.clamp(0, 100);
    final parentPercent = 100 - partnerPercent;
    final annualSalary = candidate.annualSalaryEur;
    final partnerEur = (annualSalary * partnerPercent / 100).round();
    final parentEur = annualSalary - partnerEur;
    final monthlySavedEur = (partnerEur / 12).round();

    final canSend = !widget.isReadOnly &&
        candidate.isEligibleForLoan &&
        partner.hasOpenSlot;

    String? blockReason;
    if (widget.isReadOnly) {
      blockReason = 'Tryb tylko do odczytu.';
    } else if (candidate.isCurrentlyOnLoan) {
      blockReason = '${candidate.fullName} jest już na wypożyczeniu.';
    } else if (candidate.isInjured) {
      blockReason = '${candidate.fullName} jest kontuzjowany.';
    } else if (!partner.hasOpenSlot) {
      blockReason = '${partner.name} nie ma wolnych miejsc w składzie.';
    }

    final maxRaceDays = math.max(
      1,
      math.max(
        comparison.loanProjectedRaceDays,
        comparison.benchProjectedRaceDays,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Warunki Kontraktu & Podział Pensji',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(
                text: '${partner.division.developmentMultiplier.toStringAsFixed(2)}x XP',
                color: AppColors.accentBlue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gwarantowana liczba dni wyścigowych dla juniora
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Gwarantowane dni wyścigowe',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${partner.guaranteedRaceDays} dni / sezon',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.statusSuccess,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ComparisonBarRow(
                  label: 'Ławka WT (${candidate.fullName.split(' ').last})',
                  valueText: '${comparison.benchProjectedRaceDays} dni',
                  ratio: comparison.benchProjectedRaceDays / maxRaceDays,
                  color: AppColors.amberWarning,
                ),
                const SizedBox(height: 6),
                _ComparisonBarRow(
                  label: 'Wypożyczenie (${partner.shortCode})',
                  valueText: '${comparison.loanProjectedRaceDays} dni',
                  ratio: comparison.loanProjectedRaceDays / maxRaceDays,
                  color: AppColors.statusSuccess,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _MetricInline(
                      label: 'Prognoza OVR',
                      value:
                          '+${comparison.loanProjectedOvrGain.toStringAsFixed(1)} (vs +${comparison.benchProjectedOvrGain.toStringAsFixed(1)})',
                      valueColor: AppColors.accentBlue,
                    ),
                    _MetricInline(
                      label: 'Race IQ',
                      value:
                          '+${comparison.loanProjectedRaceIqGain} (vs +${comparison.benchProjectedRaceIqGain})',
                    ),
                    _MetricInline(
                      label: 'FTP',
                      value:
                          '+${comparison.loanProjectedFtpGain} W (vs +${comparison.benchProjectedFtpGain} W)',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Podział pokrycia pensji
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Podział pokrycia pensji',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Roczna: ${Formatters.formatCurrency(annualSalary)}',
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        if (partnerPercent > 0)
                          Expanded(
                            flex: partnerPercent,
                            child: Container(color: AppColors.statusSuccess),
                          ),
                        if (parentPercent > 0)
                          Expanded(
                            flex: parentPercent,
                            child: Container(color: AppColors.primaryAccent),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SalarySplitBox(
                        title: '${partner.shortCode} (Partner)',
                        percent: partnerPercent,
                        amountEur: partnerEur,
                        dotColor: AppColors.statusSuccess,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SalarySplitBox(
                        title: 'Twój Klub (WT)',
                        percent: parentPercent,
                        amountEur: parentEur,
                        dotColor: AppColors.primaryAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Oszczędność budżetu płacowego: ${Formatters.formatCurrency(partnerEur)} / rok (${Formatters.formatCurrency(monthlySavedEur)} / mies.)',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Konfiguracja celu i klauzuli powrotu
          Row(
            children: [
              Expanded(
                child: _LabeledDropdown<LoanDevelopmentFocus>(
                  label: 'Cel szkoleniowy',
                  value: state.selectedFocus,
                  items: LoanDevelopmentFocus.values,
                  itemLabel: (e) => e.label,
                  isDisabled: widget.isReadOnly,
                  onChanged: notifier.setDevelopmentFocus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LabeledDropdown<LoanRecallClauseType>(
                  label: 'Klauzula powrotu',
                  value: state.selectedRecallClause,
                  items: LoanRecallClauseType.values,
                  itemLabel: (e) => e.shortBadge,
                  isDisabled: widget.isReadOnly,
                  onChanged: notifier.setRecallClause,
                ),
              ),
            ],
          ),
          if (blockReason != null) ...[
            const SizedBox(height: 8),
            Text(
              blockReason,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 11.5,
                color: AppColors.amberWarning,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _LoanModalButton(
            label: 'Wypożycz ${candidate.fullName} do ${partner.shortCode}',
            icon: Icons.send_rounded,
            isDisabled: !canSend,
            accentColor: AppColors.primaryAccent,
            textColor: AppColors.textPrimary,
            expand: true,
            onTap: notifier.sendSelectedJuniorOnLoan,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLoansSection({
    required JuniorLoanSystemState state,
    required JuniorLoanSystemNotifier notifier,
    required List<JuniorLoanAgreement> activeAgreements,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.accentBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aktywne Wypożyczenia (${activeAgreements.length})',
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _LoanModalButton(
                label: '+30 dni',
                icon: Icons.fast_forward_rounded,
                isDisabled: widget.isReadOnly || activeAgreements.isEmpty,
                accentColor: AppColors.surfaceLight,
                textColor: AppColors.textPrimary,
                onTap: notifier.advanceActiveLoansMonth,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (activeAgreements.isEmpty)
            _buildEmptyCard('Brak aktywnych wypożyczeń w bieżącym sezonie.')
          else
            Column(
              children: activeAgreements.map((loan) {
                final daysRatio = loan.guaranteedRaceDays <= 0
                    ? 0.0
                    : (loan.accumulatedRaceDays / loan.guaranteedRaceDays)
                        .clamp(0.0, 1.0);
                final canRecall = !widget.isReadOnly && loan.canInstantRecall;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${loan.riderName} → ${loan.partnerClubName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _StatusBadge(
                            text: 'Pokrycie ${loan.salaryCoveredByPartnerPercent}%',
                            color: AppColors.goldAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dni wyścigowe: ${loan.accumulatedRaceDays}/${loan.guaranteedRaceDays} • OVR +${loan.accumulatedOvrGain.toStringAsFixed(2)} • IQ +${loan.accumulatedRaceIqGain} • FTP +${loan.accumulatedFtpGainWatts} W',
                        style: const TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: daysRatio,
                          minHeight: 7,
                          backgroundColor: AppColors.background,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accentBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusBadge(
                            text: loan.recallClause.shortBadge,
                            color: AppColors.surface,
                          ),
                          _LoanModalButton(
                            label: 'Ściągnij',
                            icon: Icons.keyboard_return_rounded,
                            isDisabled: !canRecall,
                            accentColor: AppColors.crimsonAlert.withValues(
                              alpha: 0.2,
                            ),
                            textColor: AppColors.crimsonAlert,
                            onTap: () => notifier.recallLoanById(loan.loanId),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LoanModalButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;
  final Color accentColor;
  final Color textColor;
  final bool expand;

  const _LoanModalButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
    required this.accentColor,
    required this.textColor,
    this.expand = false,
  });

  @override
  State<_LoanModalButton> createState() => _LoanModalButtonState();
}

class _LoanModalButtonState extends State<_LoanModalButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isDisabled;
    final bgColor = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _isPressed
            ? widget.accentColor.withValues(alpha: 0.85)
            : _isHovered
                ? Color.lerp(widget.accentColor, Colors.white, 0.08)!
                : widget.accentColor;

    final borderColor = _isFocused
        ? AppColors.goldAccent
        : _isHovered && !disabled
            ? AppColors.goldAccent.withValues(alpha: 0.7)
            : const Color(0xFF2A2F3D);

    final fgColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.textColor;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: disabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: disabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _isPressed && !disabled ? 0.98 : 1.0,
              _isPressed && !disabled ? 0.98 : 1.0,
              1.0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
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

class _LoanModalChipButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LoanModalChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LoanModalChipButton> createState() => _LoanModalChipButtonState();
}

class _LoanModalChipButtonState extends State<_LoanModalChipButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? AppColors.primaryAccent
        : _isHovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final border = _isFocused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.goldAccent.withValues(alpha: 0.7)
            : const Color(0xFF2A2F3D);

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected
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

class _LoanSelectableCard extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _LoanSelectableCard({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  State<_LoanSelectableCard> createState() => _LoanSelectableCardState();
}

class _LoanSelectableCardState extends State<_LoanSelectableCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused || widget.isSelected
        ? AppColors.goldAccent
        : _isHovered
            ? AppColors.goldAccent.withValues(alpha: 0.55)
            : const Color(0xFF2A2F3D);

    final bgColor = widget.isSelected
        ? AppColors.surfaceLight
        : _isHovered
            ? Color.lerp(AppColors.background, AppColors.surfaceLight, 0.6)!
            : AppColors.background;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _isPressed ? 0.99 : 1.0,
              _isPressed ? 0.99 : 1.0,
              1.0,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color == AppColors.surfaceLight || color == AppColors.surface
              ? AppColors.textSecondary
              : color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _MetricInline extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricInline({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ComparisonBarRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double ratio;
  final Color color;

  const _ComparisonBarRow({
    required this.label,
    required this.valueText,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SalarySplitBox extends StatelessWidget {
  final String title;
  final int percent;
  final int amountEur;
  final Color dotColor;

  const _SalarySplitBox({
    required this.title,
    required this.percent,
    required this.amountEur,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
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
          const SizedBox(height: 4),
          Text(
            '$percent% • ${Formatters.formatCurrency(amountEur)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final bool isDisabled;
  final ValueChanged<T> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.isDisabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceLight,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        itemLabel(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: isDisabled
                  ? null
                  : (next) {
                      if (next != null) onChanged(next);
                    },
            ),
          ),
        ),
      ],
    );
  }
}
