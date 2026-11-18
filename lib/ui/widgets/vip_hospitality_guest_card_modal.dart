import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/team/sponsor_contract.dart';
import '../../services/career/team_sponsor_hospitality_vip_events.dart';

/// Rozbicie bonusu do relacji ze sponsorem wynikającego z zaproszenia VIP.
class VipHospitalityBonusBreakdown {
  final double baseAttractionBonus;
  final double preferenceMatchBonus;
  final double venuePrestigeMultiplier;
  final double vipRoleMultiplier;
  final double totalRelationshipBonus;
  final double currentRelationshipScore;
  final double projectedRelationshipScore;
  final double renewalChanceDeltaPct;
  final int matchedGuestPreferencesCount;

  const VipHospitalityBonusBreakdown({
    required this.baseAttractionBonus,
    required this.preferenceMatchBonus,
    required this.venuePrestigeMultiplier,
    required this.vipRoleMultiplier,
    required this.totalRelationshipBonus,
    required this.currentRelationshipScore,
    required this.projectedRelationshipScore,
    required this.renewalChanceDeltaPct,
    required this.matchedGuestPreferencesCount,
  });

  static const VipHospitalityBonusBreakdown zero =
      VipHospitalityBonusBreakdown(
    baseAttractionBonus: 0.0,
    preferenceMatchBonus: 0.0,
    venuePrestigeMultiplier: 1.0,
    vipRoleMultiplier: 1.0,
    totalRelationshipBonus: 0.0,
    currentRelationshipScore: 0.0,
    projectedRelationshipScore: 0.0,
    renewalChanceDeltaPct: 0.0,
    matchedGuestPreferencesCount: 0,
  );
}

/// Kalkulator kosztów i bonusu do relacji ze sponsorem dla zaproszenia VIP.
class VipHospitalityBonusCalculator {
  const VipHospitalityBonusCalculator._();

  static const TeamSponsorHospitalityVipEvents _service =
      TeamSponsorHospitalityVipEvents();

  /// Domyślne 3 główne atrakcje VIP na wyścigu.
  static const List<VipHospitalityExperiencePackage> defaultModalAttractions = [
    VipHospitalityExperiencePackage.secondTeamCarConvoy,
    VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet,
    VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto,
  ];

  /// Zwraca czytelny tytuł atrakcji w kontekście zaproszenia na wyścig.
  static String attractionTitle(VipHospitalityExperiencePackage pkg) {
    switch (pkg) {
      case VipHospitalityExperiencePackage.secondTeamCarConvoy:
        return 'Przejazd w wozie dyrektora sportowego';
      case VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet:
        return 'Spotkanie z liderem w autobusie po etapie';
      case VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto:
        return 'Pamiątkowa koszulka z autografami';
      case VipHospitalityExperiencePackage.finishLineVipLounge:
        return 'Loża VIP na linii mety';
      case VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite:
        return 'Pakiet Platynowy Executive';
    }
  }

  /// Zwraca kontekstowy opis atrakcji z uwzględnieniem dyrektora sportowego i lidera.
  static String attractionSubtitle(
    VipHospitalityExperiencePackage pkg, {
    required String sportsDirectorName,
    required String teamLeaderName,
  }) {
    switch (pkg) {
      case VipHospitalityExperiencePackage.secondTeamCarConvoy:
        return 'Miejsce na tylnej kanapie wozu #$sportsDirectorName za peletonem z nasłuchem radia wyścigowego na żywo.';
      case VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet:
        return 'Prywatny briefing i kawa w autobusie drużyny z liderem ($teamLeaderName) tuż po przekroczeniu linii mety.';
      case VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto:
        return 'Oficjalna koszulka startowa w ramie z autografami całego składu i sesją zdjęciową pod podium.';
      case VipHospitalityExperiencePackage.finishLineVipLounge:
        return 'Dostęp do strefy gościnnej tuż za metą z cateringiem, szampanem i podglądem telemetrii.';
      case VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite:
        return 'Pełen pakiet VIP łączący przejazd w konwoju, strefę mety i kolację zarządu.';
    }
  }

  /// Bazowy bonus do relacji (w punktach 0–100) dla pojedynczej atrakcji.
  static double attractionRelationshipPoints(
    VipHospitalityExperiencePackage pkg,
  ) {
    switch (pkg) {
      case VipHospitalityExperiencePackage.secondTeamCarConvoy:
        return 8.5;
      case VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet:
        return 6.0;
      case VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto:
        return 4.0;
      case VipHospitalityExperiencePackage.finishLineVipLounge:
        return 6.5;
      case VipHospitalityExperiencePackage.fullExecutiveHospitalitySuite:
        return 11.5;
    }
  }

  /// Oblicza całkowity koszt organizacji zaproszenia VIP w EUR.
  static int calculateTotalCostEur({
    required VipHospitalityStageVenue venue,
    required List<VipHospitalityExperiencePackage> selectedPackages,
    required int guestCount,
  }) {
    return _service.calculatePackageCostEur(
      venue: venue,
      packages: selectedPackages,
      guestCount: guestCount,
    );
  }

  /// Wylicza szczegółowy bonus do relacji ze sponsorem i szansy przedłużenia kontraktu.
  static VipHospitalityBonusBreakdown calculateBonus({
    required double currentRelationshipScore,
    required VipHospitalityStageVenue venue,
    required List<VipSponsorGuestProfile> selectedGuests,
    required List<VipHospitalityExperiencePackage> selectedPackages,
  }) {
    final double clampedCurrent = currentRelationshipScore.clamp(0.0, 100.0);
    if (selectedGuests.isEmpty || selectedPackages.isEmpty) {
      return VipHospitalityBonusBreakdown(
        baseAttractionBonus: 0.0,
        preferenceMatchBonus: 0.0,
        venuePrestigeMultiplier: venue.prestigeMultiplier,
        vipRoleMultiplier: 1.0,
        totalRelationshipBonus: 0.0,
        currentRelationshipScore: clampedCurrent,
        projectedRelationshipScore: clampedCurrent,
        renewalChanceDeltaPct: 0.0,
        matchedGuestPreferencesCount: 0,
      );
    }

    final double baseAttraction = selectedPackages.fold<double>(
      0.0,
      (sum, pkg) => sum + attractionRelationshipPoints(pkg),
    );

    int matchCount = 0;
    double roleWeightSum = 0.0;
    for (final guest in selectedGuests) {
      roleWeightSum += guest.roleTier.renewalDecisionWeight;
      if (selectedPackages.contains(guest.personalPreference)) {
        matchCount += 1;
      }
    }

    final double avgRoleMultiplier = roleWeightSum / selectedGuests.length;
    final double preferenceBonus = matchCount * 2.5;
    final double venueMult = venue.prestigeMultiplier;

    final double rawTotal =
        (baseAttraction + preferenceBonus) * venueMult * avgRoleMultiplier;
    // Maksymalny jednorazowy skok relacji z jednego zaproszenia to 32 pkt.
    final double totalBonus =
        double.parse(rawTotal.clamp(0.0, 32.0).toStringAsFixed(1));
    final double projected =
        double.parse((clampedCurrent + totalBonus).clamp(0.0, 100.0).toStringAsFixed(1));
    final double renewalDelta =
        double.parse((totalBonus * 1.15).clamp(0.0, 35.0).toStringAsFixed(1));

    return VipHospitalityBonusBreakdown(
      baseAttractionBonus: double.parse(baseAttraction.toStringAsFixed(1)),
      preferenceMatchBonus: double.parse(preferenceBonus.toStringAsFixed(1)),
      venuePrestigeMultiplier: venueMult,
      vipRoleMultiplier: double.parse(avgRoleMultiplier.toStringAsFixed(2)),
      totalRelationshipBonus: totalBonus,
      currentRelationshipScore: clampedCurrent,
      projectedRelationshipScore: projected,
      renewalChanceDeltaPct: renewalDelta,
      matchedGuestPreferencesCount: matchCount,
    );
  }
}

/// Dane wejściowe dla modalu zaproszenia gości VIP sponsora na wyścig.
class VipHospitalityGuestCardData {
  final String sponsorId;
  final String sponsorName;
  final SponsorTier sponsorTier;
  final double currentRelationshipScore;
  final String stageName;
  final VipHospitalityStageVenue venue;
  final String eventDateLabel;
  final String teamLeaderName;
  final String sportsDirectorName;
  final int availableTeamBudgetEur;
  final List<VipSponsorGuestProfile> guests;
  final List<VipHospitalityExperiencePackage> availablePackages;
  final Set<String> initialSelectedGuestIds;
  final Set<VipHospitalityExperiencePackage> initialSelectedPackages;
  final bool isReadOnly;

  const VipHospitalityGuestCardData({
    required this.sponsorId,
    required this.sponsorName,
    required this.sponsorTier,
    required this.currentRelationshipScore,
    required this.stageName,
    required this.venue,
    required this.eventDateLabel,
    required this.teamLeaderName,
    required this.sportsDirectorName,
    required this.availableTeamBudgetEur,
    required this.guests,
    this.availablePackages =
        VipHospitalityBonusCalculator.defaultModalAttractions,
    this.initialSelectedGuestIds = const {},
    this.initialSelectedPackages = const {
      VipHospitalityExperiencePackage.secondTeamCarConvoy,
    },
    this.isReadOnly = false,
  });

  /// Przykładowe dane produkcyjne do szybkiego podglądu lub inicjalizacji.
  factory VipHospitalityGuestCardData.sample({bool isReadOnly = false}) {
    return VipHospitalityGuestCardData(
      sponsorId: 'sp_nordic_energy',
      sponsorName: 'NordicGrid Energy',
      sponsorTier: SponsorTier.titlePrimary,
      currentRelationshipScore: 64.0,
      stageName: 'Etap 21 — Champs-Élysées, Paryż',
      venue: VipHospitalityStageVenue.champsElyseesFinale,
      eventDateLabel: '26 lipca 2026',
      teamLeaderName: 'Kacper Kowalski',
      sportsDirectorName: 'Marek Nowak',
      availableTeamBudgetEur: 250000,
      guests: const [
        VipSponsorGuestProfile(
          id: 'vip_ceo_lindqvist',
          fullName: 'Henrik Lindqvist',
          title: 'Prezes Zarządu (CEO)',
          companyName: 'NordicGrid Energy',
          sponsorId: 'sp_nordic_energy',
          roleTier: VipGuestRoleTier.sponsorCeo,
          industry: SponsorIndustry.energy,
          personalPreference:
              VipHospitalityExperiencePackage.secondTeamCarConvoy,
          patienceScore: 76.0,
          affinityScore: 71.0,
        ),
        VipSponsorGuestProfile(
          id: 'vip_cmo_zielinska',
          fullName: 'Anna Zielińska',
          title: 'Dyrektor Marketingu',
          companyName: 'NordicGrid Energy',
          sponsorId: 'sp_nordic_energy',
          roleTier: VipGuestRoleTier.marketingDirector,
          industry: SponsorIndustry.energy,
          personalPreference:
              VipHospitalityExperiencePackage.teamBusLeaderMeetAndGreet,
          patienceScore: 82.0,
          affinityScore: 68.0,
        ),
        VipSponsorGuestProfile(
          id: 'vip_board_berg',
          fullName: 'Tomasz Berg',
          title: 'Członek Rady Nadzorczej',
          companyName: 'NordicGrid Energy',
          sponsorId: 'sp_nordic_energy',
          roleTier: VipGuestRoleTier.boardMember,
          industry: SponsorIndustry.energy,
          personalPreference:
              VipHospitalityExperiencePackage.signedPodiumJerseyAndPhoto,
          patienceScore: 74.0,
          affinityScore: 63.0,
        ),
      ],
      initialSelectedGuestIds: const {'vip_ceo_lindqvist'},
      initialSelectedPackages: const {
        VipHospitalityExperiencePackage.secondTeamCarConvoy,
      },
      isReadOnly: isReadOnly,
    );
  }

  VipHospitalityGuestCardData copyWith({
    String? sponsorId,
    String? sponsorName,
    SponsorTier? sponsorTier,
    double? currentRelationshipScore,
    String? stageName,
    VipHospitalityStageVenue? venue,
    String? eventDateLabel,
    String? teamLeaderName,
    String? sportsDirectorName,
    int? availableTeamBudgetEur,
    List<VipSponsorGuestProfile>? guests,
    List<VipHospitalityExperiencePackage>? availablePackages,
    Set<String>? initialSelectedGuestIds,
    Set<VipHospitalityExperiencePackage>? initialSelectedPackages,
    bool? isReadOnly,
  }) {
    return VipHospitalityGuestCardData(
      sponsorId: sponsorId ?? this.sponsorId,
      sponsorName: sponsorName ?? this.sponsorName,
      sponsorTier: sponsorTier ?? this.sponsorTier,
      currentRelationshipScore:
          currentRelationshipScore ?? this.currentRelationshipScore,
      stageName: stageName ?? this.stageName,
      venue: venue ?? this.venue,
      eventDateLabel: eventDateLabel ?? this.eventDateLabel,
      teamLeaderName: teamLeaderName ?? this.teamLeaderName,
      sportsDirectorName: sportsDirectorName ?? this.sportsDirectorName,
      availableTeamBudgetEur:
          availableTeamBudgetEur ?? this.availableTeamBudgetEur,
      guests: guests ?? this.guests,
      availablePackages: availablePackages ?? this.availablePackages,
      initialSelectedGuestIds:
          initialSelectedGuestIds ?? this.initialSelectedGuestIds,
      initialSelectedPackages:
          initialSelectedPackages ?? this.initialSelectedPackages,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }

  Map<String, dynamic> toJson() => {
        'sponsorId': sponsorId,
        'sponsorName': sponsorName,
        'sponsorTier': sponsorTier.toJson(),
        'currentRelationshipScore': currentRelationshipScore,
        'stageName': stageName,
        'venue': venue.toJson(),
        'eventDateLabel': eventDateLabel,
        'teamLeaderName': teamLeaderName,
        'sportsDirectorName': sportsDirectorName,
        'availableTeamBudgetEur': availableTeamBudgetEur,
        'guests': guests.map((g) => g.toJson()).toList(),
        'availablePackages': availablePackages.map((p) => p.toJson()).toList(),
        'initialSelectedGuestIds': initialSelectedGuestIds.toList(),
        'initialSelectedPackages':
            initialSelectedPackages.map((p) => p.toJson()).toList(),
        'isReadOnly': isReadOnly,
      };

  factory VipHospitalityGuestCardData.fromJson(Map<String, dynamic> json) {
    final rawGuests = (json['guests'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              VipSponsorGuestProfile.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    final rawPackages = (json['availablePackages'] as List<dynamic>?)
        ?.map((p) => VipHospitalityExperiencePackage.fromJson(p as String))
        .toList();
    final rawSelectedGuests =
        (json['initialSelectedGuestIds'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toSet();
    final rawSelectedPackages =
        (json['initialSelectedPackages'] as List<dynamic>? ?? const [])
            .map((p) => VipHospitalityExperiencePackage.fromJson(p as String))
            .toSet();

    return VipHospitalityGuestCardData(
      sponsorId: json['sponsorId'] as String,
      sponsorName: json['sponsorName'] as String,
      sponsorTier: SponsorTier.fromJson(json['sponsorTier'] as String),
      currentRelationshipScore:
          (json['currentRelationshipScore'] as num).toDouble(),
      stageName: json['stageName'] as String,
      venue: VipHospitalityStageVenue.fromJson(json['venue'] as String),
      eventDateLabel: json['eventDateLabel'] as String,
      teamLeaderName: json['teamLeaderName'] as String,
      sportsDirectorName: json['sportsDirectorName'] as String,
      availableTeamBudgetEur:
          (json['availableTeamBudgetEur'] as num).toInt(),
      guests: rawGuests,
      availablePackages: rawPackages != null && rawPackages.isNotEmpty
          ? rawPackages
          : VipHospitalityBonusCalculator.defaultModalAttractions,
      initialSelectedGuestIds: rawSelectedGuests,
      initialSelectedPackages: rawSelectedPackages,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
    );
  }
}

/// Wynik zatwierdzenia zaproszenia VIP z modalu.
class VipHospitalityGuestCardResult {
  final List<VipSponsorGuestProfile> selectedGuests;
  final List<VipHospitalityExperiencePackage> selectedPackages;
  final int totalCostEur;
  final VipHospitalityBonusBreakdown bonusBreakdown;
  final String personalNote;

  const VipHospitalityGuestCardResult({
    required this.selectedGuests,
    required this.selectedPackages,
    required this.totalCostEur,
    required this.bonusBreakdown,
    required this.personalNote,
  });
}

/// Modal zaproszenia gości VIP sponsora na wyścig z wyborem atrakcji
/// i podglądem bonusu do relacji ze sponsorem.
class VipHospitalityGuestCardModal extends StatefulWidget {
  final VipHospitalityGuestCardData data;
  final ValueChanged<VipHospitalityGuestCardResult>? onConfirmInvitation;
  final VoidCallback? onCancel;

  const VipHospitalityGuestCardModal({
    super.key,
    required this.data,
    this.onConfirmInvitation,
    this.onCancel,
  });

  /// Wyświetla modal w oknie dialogowym i zwraca wynik konfiguracji zaproszenia.
  static Future<VipHospitalityGuestCardResult?> show(
    BuildContext context, {
    required VipHospitalityGuestCardData data,
  }) {
    return showDialog<VipHospitalityGuestCardResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 820),
            child: VipHospitalityGuestCardModal(
              data: data,
              onConfirmInvitation: (result) =>
                  Navigator.of(dialogContext).pop(result),
              onCancel: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  @override
  State<VipHospitalityGuestCardModal> createState() =>
      _VipHospitalityGuestCardModalState();
}

class _VipHospitalityGuestCardModalState
    extends State<VipHospitalityGuestCardModal> {
  late Set<String> _selectedGuestIds;
  late Set<VipHospitalityExperiencePackage> _selectedPackages;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _selectedGuestIds = Set<String>.from(widget.data.initialSelectedGuestIds);
    if (_selectedGuestIds.isEmpty && widget.data.guests.isNotEmpty) {
      _selectedGuestIds.add(widget.data.guests.first.id);
    }
    _selectedPackages = Set<VipHospitalityExperiencePackage>.from(
      widget.data.initialSelectedPackages,
    );
    _noteController = TextEditingController(
      text:
          'Serdecznie zapraszamy do naszej strefy VIP oraz wozu technicznego podczas etapu ${widget.data.venue.shortLabel}.',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<VipSponsorGuestProfile> get _selectedGuests => widget.data.guests
      .where((g) => _selectedGuestIds.contains(g.id))
      .toList(growable: false);

  List<VipHospitalityExperiencePackage> get _orderedSelectedPackages =>
      widget.data.availablePackages
          .where((p) => _selectedPackages.contains(p))
          .toList(growable: false);

  void _toggleGuest(String guestId) {
    if (widget.data.isReadOnly) return;
    setState(() {
      if (_selectedGuestIds.contains(guestId)) {
        _selectedGuestIds.remove(guestId);
      } else {
        _selectedGuestIds.add(guestId);
      }
    });
  }

  void _togglePackage(VipHospitalityExperiencePackage pkg) {
    if (widget.data.isReadOnly) return;
    setState(() {
      if (_selectedPackages.contains(pkg)) {
        _selectedPackages.remove(pkg);
      } else {
        _selectedPackages.add(pkg);
      }
    });
  }

  void _handleConfirm(
    int totalCostEur,
    VipHospitalityBonusBreakdown breakdown,
  ) {
    final result = VipHospitalityGuestCardResult(
      selectedGuests: _selectedGuests,
      selectedPackages: _orderedSelectedPackages,
      totalCostEur: totalCostEur,
      bonusBreakdown: breakdown,
      personalNote: _noteController.text.trim(),
    );
    if (widget.onConfirmInvitation != null) {
      widget.onConfirmInvitation!(result);
    } else {
      Navigator.of(context).maybePop(result);
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedGuests = _selectedGuests;
    final selectedPackages = _orderedSelectedPackages;
    final int totalCostEur = VipHospitalityBonusCalculator.calculateTotalCostEur(
      venue: widget.data.venue,
      selectedPackages: selectedPackages,
      guestCount: selectedGuests.length,
    );
    final VipHospitalityBonusBreakdown breakdown =
        VipHospitalityBonusCalculator.calculateBonus(
      currentRelationshipScore: widget.data.currentRelationshipScore,
      venue: widget.data.venue,
      selectedGuests: selectedGuests,
      selectedPackages: selectedPackages,
    );
    final bool overBudget = totalCostEur > widget.data.availableTeamBudgetEur;
    final bool canConfirm = !widget.data.isReadOnly &&
        selectedGuests.isNotEmpty &&
        selectedPackages.isNotEmpty &&
        !overBudget;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 760;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isCompact ? 14 : 20),
                  child: isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildGuestsSection(),
                            const SizedBox(height: 16),
                            _buildAttractionsSection(selectedGuests),
                            const SizedBox(height: 16),
                            _buildVipPassAndBonusPanel(
                              selectedGuests: selectedGuests,
                              selectedPackages: selectedPackages,
                              totalCostEur: totalCostEur,
                              breakdown: breakdown,
                              overBudget: overBudget,
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildGuestsSection(),
                                  const SizedBox(height: 18),
                                  _buildAttractionsSection(selectedGuests),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: _buildVipPassAndBonusPanel(
                                selectedGuests: selectedGuests,
                                selectedPackages: selectedPackages,
                                totalCostEur: totalCostEur,
                                breakdown: breakdown,
                                overBudget: overBudget,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              _buildFooter(
                isCompact: isCompact,
                totalCostEur: totalCostEur,
                overBudget: overBudget,
                canConfirm: canConfirm,
                selectedGuestsCount: selectedGuests.length,
                selectedPackagesCount: selectedPackages.length,
                breakdown: breakdown,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.goldAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.goldAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'VIP HOSPITALITY PASS',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                    Text(
                      widget.data.sponsorName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                    if (widget.data.isReadOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Text(
                          'TYLKO PODGLĄD',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Zaproszenie Gości VIP na Wyścig',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 16 : 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.data.stageName} • ${widget.data.eventDateLabel}',
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
          _ModalIconButton(
            tooltip: 'Zamknij modal',
            icon: Icons.close_rounded,
            onPressed: _handleCancel,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.badge_rounded,
                size: 18,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '1. Wybierz Gości VIP Sponsora',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_selectedGuestIds.length}/${widget.data.guests.length} wybranych',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.data.guests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Text(
                'Brak dostępnych przedstawicieli sponsora do zaproszenia.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.data.guests.map((guest) {
                final bool isSelected = _selectedGuestIds.contains(guest.id);
                return _InteractiveGuestChip(
                  guest: guest,
                  isSelected: isSelected,
                  isDisabled: widget.data.isReadOnly,
                  onTap: () => _toggleGuest(guest.id),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAttractionsSection(List<VipSponsorGuestProfile> selectedGuests) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 18,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '2. Wybierz Atrakcje Dnia Wyścigowego',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${_selectedPackages.length} aktywne',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Dopasuj atrakcje do preferencji gości, aby zmaksymalizować bonus do relacji ze sponsorem.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.data.availablePackages.map((pkg) {
            final bool isSelected = _selectedPackages.contains(pkg);
            final List<VipSponsorGuestProfile> matchingGuests = selectedGuests
                .where((g) => g.personalPreference == pkg)
                .toList(growable: false);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InteractiveAttractionCard(
                package: pkg,
                title: VipHospitalityBonusCalculator.attractionTitle(pkg),
                subtitle: VipHospitalityBonusCalculator.attractionSubtitle(
                  pkg,
                  sportsDirectorName: widget.data.sportsDirectorName,
                  teamLeaderName: widget.data.teamLeaderName,
                ),
                relationshipPoints:
                    VipHospitalityBonusCalculator.attractionRelationshipPoints(
                  pkg,
                ),
                matchingGuests: matchingGuests,
                isSelected: isSelected,
                isDisabled: widget.data.isReadOnly,
                onTap: () => _togglePackage(pkg),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVipPassAndBonusPanel({
    required List<VipSponsorGuestProfile> selectedGuests,
    required List<VipHospitalityExperiencePackage> selectedPackages,
    required int totalCostEur,
    required VipHospitalityBonusBreakdown breakdown,
    required bool overBudget,
  }) {
    final double currentRatio =
        (breakdown.currentRelationshipScore / 100.0).clamp(0.0, 1.0);
    final double projectedRatio =
        (breakdown.projectedRelationshipScore / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Karta VIP i Bonus Relacji
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceLight,
                AppColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'BONUS DO RELACJI ZE SPONSOREM',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.goldAccent,
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
                      color: AppColors.statusSuccess.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.statusSuccess.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      '+${breakdown.totalRelationshipBonus.toStringAsFixed(1)} pkt',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.statusSuccess,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    breakdown.projectedRelationshipScore.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      '/ 100',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Było: ${breakdown.currentRelationshipScore.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Pasek postępu relacji: bazowy + prognozowany bonus
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Container(color: AppColors.background),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        widthFactor: projectedRatio,
                        alignment: Alignment.centerLeft,
                        child: Container(color: AppColors.statusSuccess),
                      ),
                      FractionallySizedBox(
                        widthFactor: currentRatio,
                        alignment: Alignment.centerLeft,
                        child: Container(color: AppColors.accentBlue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _BonusMetricRow(
                label: 'Atrakcje bazowe (${selectedPackages.length})',
                value:
                    '+${breakdown.baseAttractionBonus.toStringAsFixed(1)} pkt',
                valueColor: AppColors.textPrimary,
              ),
              const SizedBox(height: 6),
              _BonusMetricRow(
                label:
                    'Dopasowanie preferencji (${breakdown.matchedGuestPreferencesCount})',
                value:
                    '+${breakdown.preferenceMatchBonus.toStringAsFixed(1)} pkt',
                valueColor: breakdown.matchedGuestPreferencesCount > 0
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              _BonusMetricRow(
                label: 'Prestiż etapu (${widget.data.venue.shortLabel})',
                value: 'x${breakdown.venuePrestigeMultiplier.toStringAsFixed(2)}',
                valueColor: AppColors.accentBlue,
              ),
              const SizedBox(height: 6),
              _BonusMetricRow(
                label: 'Ranga gości (${selectedGuests.length})',
                value: 'x${breakdown.vipRoleMultiplier.toStringAsFixed(2)}',
                valueColor: AppColors.textPrimary,
              ),
              const Divider(color: AppTheme.borderColor, height: 20),
              _BonusMetricRow(
                label: 'Szansa przedłużenia kontraktu',
                value:
                    '+${breakdown.renewalChanceDeltaPct.toStringAsFixed(1)}%',
                valueColor: AppColors.statusSuccess,
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Podsumowanie kosztów i notatka na zaproszeniu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: overBudget ? AppColors.crimsonAlert : AppTheme.borderColor,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KOSZT OBSŁUGI I KARTA ZAPROSZENIA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _BonusMetricRow(
                label: 'Koszt całkowity pakietu',
                value: Formatters.formatCurrency(totalCostEur),
                valueColor:
                    overBudget ? AppColors.crimsonAlert : AppColors.textPrimary,
                isBold: true,
              ),
              const SizedBox(height: 6),
              _BonusMetricRow(
                label: 'Dostępny budżet zespołu',
                value: Formatters.formatCurrency(
                  widget.data.availableTeamBudgetEur,
                ),
                valueColor: AppColors.textSecondary,
              ),
              if (overBudget) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonAlert.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.crimsonAlert.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.crimsonAlert,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Koszt przekracza dostępny budżet zespołu.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.crimsonAlert,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Dedykowana wiadomość na karcie VIP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                enabled: !widget.data.isReadOnly,
                maxLines: 3,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.goldAccent),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter({
    required bool isCompact,
    required int totalCostEur,
    required bool overBudget,
    required bool canConfirm,
    required int selectedGuestsCount,
    required int selectedPackagesCount,
    required VipHospitalityBonusBreakdown breakdown,
  }) {
    final String helperHint;
    if (widget.data.isReadOnly) {
      helperHint = 'Tryb podglądu — edycja zaproszenia zablokowana.';
    } else if (selectedGuestsCount == 0) {
      helperHint = 'Wybierz co najmniej jednego gościa VIP.';
    } else if (selectedPackagesCount == 0) {
      helperHint = 'Wybierz co najmniej jedną atrakcję dla gości.';
    } else if (overBudget) {
      helperHint = 'Zmniejsz liczbę atrakcji lub gości, aby zmieścić się w budżecie.';
    } else {
      helperHint =
          'Gotowe do wysłania: $selectedGuestsCount gości • $selectedPackagesCount atrakcji • +${breakdown.totalRelationshipBonus.toStringAsFixed(1)} pkt relacji.';
    }

    final Widget cancelBtn = _InteractiveActionButton(
      label: 'Anuluj',
      isPrimary: false,
      isDisabled: false,
      onPressed: _handleCancel,
    );

    final Widget confirmBtn = _InteractiveActionButton(
      label: 'Wyślij Zaproszenie VIP',
      icon: Icons.send_rounded,
      isPrimary: true,
      isDisabled: !canConfirm,
      onPressed: canConfirm ? () => _handleConfirm(totalCostEur, breakdown) : null,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  helperHint,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: overBudget
                        ? AppColors.crimsonAlert
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: cancelBtn),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: confirmBtn),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    helperHint,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: overBudget
                          ? AppColors.crimsonAlert
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                cancelBtn,
                const SizedBox(width: 10),
                confirmBtn,
              ],
            ),
    );
  }
}

class _BonusMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _BonusMetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _InteractiveGuestChip extends StatefulWidget {
  final VipSponsorGuestProfile guest;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _InteractiveGuestChip({
    required this.guest,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_InteractiveGuestChip> createState() => _InteractiveGuestChipState();
}

class _InteractiveGuestChipState extends State<_InteractiveGuestChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : widget.isSelected
            ? AppColors.goldAccent
            : (_isHovered || _isFocused)
                ? AppColors.goldAccent.withValues(alpha: 0.55)
                : AppTheme.borderColor;

    final Color bgColor = widget.isSelected
        ? AppColors.goldAccent.withValues(alpha: 0.14)
        : _isHovered
            ? AppColors.surfaceLight
            : AppColors.background;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isSelected
                      ? Icons.check_circle_rounded
                      : Icons.person_outline_rounded,
                  size: 16,
                  color: widget.isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : widget.isSelected
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.guest.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.isDisabled
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.guest.roleTier.label} • Relacja ${widget.guest.affinityScore.toStringAsFixed(0)}%',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
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

class _InteractiveAttractionCard extends StatefulWidget {
  final VipHospitalityExperiencePackage package;
  final String title;
  final String subtitle;
  final double relationshipPoints;
  final List<VipSponsorGuestProfile> matchingGuests;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _InteractiveAttractionCard({
    required this.package,
    required this.title,
    required this.subtitle,
    required this.relationshipPoints,
    required this.matchingGuests,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_InteractiveAttractionCard> createState() =>
      _InteractiveAttractionCardState();
}

class _InteractiveAttractionCardState
    extends State<_InteractiveAttractionCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : widget.isSelected
            ? AppColors.goldAccent
            : (_isHovered || _isFocused)
                ? AppColors.goldAccent.withValues(alpha: 0.55)
                : AppTheme.borderColor;

    final Color bgColor = widget.isSelected
        ? AppColors.goldAccent.withValues(alpha: 0.11)
        : _isHovered
            ? AppColors.surfaceLight
            : AppColors.background;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? AppColors.goldAccent.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.isSelected
                          ? AppColors.goldAccent.withValues(alpha: 0.5)
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Icon(
                    widget.package.icon,
                    size: 20,
                    color: widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
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
                            widget.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.isDisabled
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (widget.matchingGuests.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusSuccess
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.statusSuccess
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'Preferencja: ${widget.matchingGuests.first.fullName.split(' ').first}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.statusSuccess,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Koszt: ${Formatters.formatCurrency(widget.package.packageCostEur)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Relacja: +${widget.relationshipPoints.toStringAsFixed(1)} pkt',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  widget.isSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 20,
                  color: widget.isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : widget.isSelected
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
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
  final IconData? icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    this.icon,
    required this.isPrimary,
    required this.isDisabled,
    required this.onPressed,
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
    final Color bgColor;
    final Color fgColor;
    final Color borderColor;

    if (widget.isDisabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.5);
      fgColor = AppColors.textSecondary.withValues(alpha: 0.5);
      borderColor = AppTheme.borderColor.withValues(alpha: 0.5);
    } else if (widget.isPrimary) {
      bgColor = _isHovered
          ? AppColors.goldAccent.withValues(alpha: 0.9)
          : AppColors.goldAccent;
      fgColor = AppColors.background;
      borderColor = _isFocused ? AppColors.textPrimary : AppColors.goldAccent;
    } else {
      bgColor = _isHovered ? AppColors.surfaceLight : AppColors.background;
      fgColor = AppColors.textPrimary;
      borderColor = _isFocused ? AppColors.goldAccent : AppTheme.borderColor;
    }

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: fgColor),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
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

class _ModalIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _ModalIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_ModalIconButton> createState() => _ModalIconButtonState();
}

class _ModalIconButtonState extends State<_ModalIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused ? AppColors.goldAccent : AppTheme.borderColor,
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
    );
  }
}
