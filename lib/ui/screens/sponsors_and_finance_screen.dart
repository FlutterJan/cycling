import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/career/career_save.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../../services/career/finance_and_budget_service.dart';
import '../../services/career/sponsor_negotiation_service.dart';
import '../../state/career_controller.dart';
import 'sponsor_pitch_deck_negotiation_modal.dart';

/// Zakładki główne ekranu Sponsorów i Finansów.
enum SponsorsFinanceTab {
  jerseyAndObjectives,
  sponsorMarket,
  financesAndForecast;

  String get label {
    switch (this) {
      case SponsorsFinanceTab.jerseyAndObjectives:
        return 'Koszulka & Cele';
      case SponsorsFinanceTab.sponsorMarket:
        return 'Rynek Sponsorów';
      case SponsorsFinanceTab.financesAndForecast:
        return 'Finanse & Prognoza';
    }
  }

  IconData get icon {
    switch (this) {
      case SponsorsFinanceTab.jerseyAndObjectives:
        return Icons.checkroom_rounded;
      case SponsorsFinanceTab.sponsorMarket:
        return Icons.business_center_rounded;
      case SponsorsFinanceTab.financesAndForecast:
        return Icons.account_balance_rounded;
    }
  }
}

/// Ekran Sponsorów, Koszulki Zespołu i Finansów (`SponsorsAndFinanceScreen`).
class SponsorsAndFinanceScreen extends ConsumerStatefulWidget {
  const SponsorsAndFinanceScreen({super.key});

  @override
  ConsumerState<SponsorsAndFinanceScreen> createState() => _SponsorsAndFinanceScreenState();
}

class _SponsorsAndFinanceScreenState extends ConsumerState<SponsorsAndFinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filtry rynku sponsorów
  SponsorTier? _selectedTierFilter;
  SponsorIndustry? _selectedIndustryFilter;

  // Widok koszulki: przód vs tył
  bool _showJerseyBack = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final careerState = ref.watch(careerProvider);
    final save = careerState.save;

    if (save == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text(
            'Brak aktywnego zapisu gry kariery.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final team = save.playerTeam;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(team, save),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJerseyAndObjectivesView(save, team),
                  _buildSponsorMarketView(save, team),
                  _buildFinancesAndForecastView(save, team),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. NAGŁÓWEK I GŁÓWNE ZAKŁADKI
  // ===========================================================================

  Widget _buildTopHeader(CyclingTeam team, CareerSave save) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primaryGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        team.division.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Budżet klubu: €${_formatCurrency(team.cashBalanceEur)} • Roczne wpływy sponsorskie: €${_formatCurrency(team.annualSponsorIncomeEur)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.cardSurface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryGold,
        indicatorWeight: 3,
        labelColor: AppColors.primaryGold,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: SponsorsFinanceTab.values.map((tab) {
          return Tab(
            icon: Icon(tab.icon, size: 18),
            text: tab.label,
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 2. WIDOK 1: KOSZULKA ZESPOŁU & CELE SPONSORSKIE
  // ===========================================================================

  Widget _buildJerseyAndObjectivesView(CareerSave save, CyclingTeam team) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 950;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lewa kolumna: Podgląd koszulki 2D
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildJerseyCard(team),
                      const SizedBox(height: 16),
                      _buildBoardSatisfactionOverallCard(team),
                    ],
                  ),
                ),
              ),

              // Prawa kolumna: Aktywne kontrakty i cele
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActiveSponsorsSection(team),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          // Układ mobilny / pionowy
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJerseyCard(team),
                const SizedBox(height: 14),
                _buildBoardSatisfactionOverallCard(team),
                const SizedBox(height: 18),
                _buildActiveSponsorsSection(team),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildJerseyCard(CyclingTeam team) {
    final primarySponsor = team.sponsors.firstWhere(
      (s) => s.sponsorTier == SponsorTier.titlePrimary,
      orElse: () => team.sponsors.isNotEmpty
          ? team.sponsors.first
          : SponsorContract(
              id: 'none',
              companyName: team.name,
              industry: SponsorIndustry.finance,
              sponsorTier: SponsorTier.titlePrimary,
              annualBudgetEur: 0,
              contractDurationYears: 1,
              sponsorSatisfaction: 80.0,
              objectives: const [],
            ),
    );

    final secondarySponsor = team.sponsors.firstWhere(
      (s) => s.sponsorTier == SponsorTier.titleSecondary,
      orElse: () => team.sponsors.length > 1
          ? team.sponsors[1]
          : SponsorContract(
              id: 'none_sec',
              companyName: team.bikeDeal.manufacturerName,
              industry: SponsorIndustry.tech,
              sponsorTier: SponsorTier.titleSecondary,
              annualBudgetEur: 0,
              contractDurationYears: 1,
              sponsorSatisfaction: 85.0,
              objectives: const [],
            ),
    );

    final primaryColor = _parseHex(team.primaryJerseyColorHex, AppColors.accentBlue);
    final secondaryColor = _parseHex(team.secondaryJerseyColorHex, const Color(0xFF1E1E2C));
    final accentColor = _parseHex(team.accentJerseyColorHex, AppColors.primaryGold);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pasek tytułowy koszulki
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'OFICJALNA KOSZULKA ZESPOŁU',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showJerseyBack = !_showJerseyBack),
                  icon: const Icon(Icons.flip_rounded, size: 16, color: AppColors.primaryGold),
                  label: Text(
                    _showJerseyBack ? 'Pokaż Przód' : 'Pokaż Tył',
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Wizualizacja wektorowa koszulki
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 240,
                height: 270,
                child: CustomPaint(
                  painter: TeamJerseyPainter(
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    accentColor: accentColor,
                    primarySponsorName: primarySponsor.companyName,
                    secondarySponsorName: secondarySponsor.companyName,
                    bikeManufacturerName: team.bikeDeal.manufacturerName,
                    teamCountryIso: team.countryIso,
                    isBackView: _showJerseyBack,
                  ),
                ),
              ),
            ),
          ),

          // Informacja o barwach
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColorCircle('Główny', primaryColor),
                const SizedBox(width: 14),
                _buildColorCircle('Rękawy', secondaryColor),
                const SizedBox(width: 14),
                _buildColorCircle('Akcent', accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBoardSatisfactionOverallCard(CyclingTeam team) {
    double avgSatisfaction = 0.0;
    if (team.sponsors.isNotEmpty) {
      avgSatisfaction = team.sponsors.fold(0.0, (acc, s) => acc + s.sponsorSatisfaction) / team.sponsors.length;
    } else {
      avgSatisfaction = 75.0;
    }

    final Color satisfactionColor = avgSatisfaction >= 75
        ? AppColors.statusSuccess
        : (avgSatisfaction >= 50 ? AppColors.primaryGold : AppColors.powerZone6);

    String statusLabel = 'Wyśmienite relacje z zarządami';
    if (avgSatisfaction < 50) {
      statusLabel = 'Zarządy zaniepokojone brakiem wyników!';
    } else if (avgSatisfaction < 75) {
      statusLabel = 'Umiarkowana stabilność kontraktów';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Zaufanie Zarządów Sponsorów',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${avgSatisfaction.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: satisfactionColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (avgSatisfaction / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.cardDark,
              valueColor: AlwaysStoppedAnimation<Color>(satisfactionColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusLabel,
            style: TextStyle(
              color: satisfactionColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSponsorsSection(CyclingTeam team) {
    if (team.sponsors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Brak aktywnych kontraktów sponsorskich. Przejdź do zakładki Rynek Sponsorów.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AKTYWNE KONTRAKTY & CELE SPONSORSKIE',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ...team.sponsors.map((sponsor) => _buildSponsorCardWithObjectives(sponsor)),
      ],
    );
  }

  Widget _buildSponsorCardWithObjectives(SponsorContract sponsor) {
    final satisfactionColor = sponsor.sponsorSatisfaction >= 75
        ? AppColors.statusSuccess
        : (sponsor.sponsorSatisfaction >= 50 ? AppColors.primaryGold : AppColors.powerZone6);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek sponsora
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apartment_rounded, color: AppColors.primaryGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sponsor.companyName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sponsor.sponsorTier.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Branża: ${sponsor.industry.name.toUpperCase()} • Pozostało: ${sponsor.contractDurationYears} lata umowy',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€${_formatCurrency(sponsor.annualBudgetEur)}/rok',
                    style: const TextStyle(
                      color: AppColors.statusSuccess,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '€${_formatCurrency((sponsor.annualBudgetEur / 12).round())}/msc',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pasek zadowolenia
          Row(
            children: [
              const Text(
                'Zadowolenie zarządu: ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                '${sponsor.sponsorSatisfaction.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: satisfactionColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                'Cele: ${sponsor.completedObjectivesCount}/${sponsor.totalObjectivesCount} zaliczonych',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (sponsor.sponsorSatisfaction / 100.0).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.cardDark,
              valueColor: AlwaysStoppedAnimation<Color>(satisfactionColor),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),

          // Lista celów sponsorskich
          const Text(
            'WYMOGI & OBIETNICE SPORTOWE',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          ...sponsor.objectives.map((obj) => _buildObjectiveTile(obj)),
        ],
      ),
    );
  }

  Widget _buildObjectiveTile(SponsorObjective obj) {
    Color importanceColor;
    switch (obj.importance) {
      case ObjectiveImportance.critical:
        importanceColor = AppColors.powerZone6;
        break;
      case ObjectiveImportance.high:
        importanceColor = AppColors.powerZone5;
        break;
      case ObjectiveImportance.medium:
        importanceColor = AppColors.primaryGold;
        break;
      case ObjectiveImportance.low:
        importanceColor = AppColors.textSecondary;
        break;
    }

    final isDone = obj.isCompleted || obj.progressPercentage >= 100.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone ? AppColors.statusSuccess.withValues(alpha: 0.3) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: isDone ? AppColors.statusSuccess : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  obj.description,
                  style: TextStyle(
                    color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: importanceColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  obj.importance.name.toUpperCase(),
                  style: TextStyle(
                    color: importanceColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (obj.progressPercentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.cardSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? AppColors.statusSuccess : AppColors.accentBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${obj.currentProgress.toInt()}/${obj.targetProgress.toInt()} (${obj.progressPercentage.toStringAsFixed(0)}%)',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              const SizedBox(width: 8),
              Text(
                '+€${_formatCurrency(obj.bonusPaymentEur)}',
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. WIDOK 2: RYNEK SPONSORÓW & NEGOCJACJE PITCH DECK
  // ===========================================================================

  Widget _buildSponsorMarketView(CareerSave save, CyclingTeam team) {
    final prospectiveSponsors = ref
        .read(careerProvider.notifier)
        .getProspectiveSponsors(
          tierFilter: _selectedTierFilter,
          industryFilter: _selectedIndustryFilter,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner informacyjny
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cardDark,
                  AppColors.primaryGold.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.handshake_rounded, color: AppColors.primaryGold, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poszukiwanie Partnerów Tytularnych & Sponsorów',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Zbuduj profesjonalną ofertę handlową (Pitch Deck), wyznacz kolarza-gwiazdę i złóż obietnice sportowe, aby pozyskać miliony euro na kolejny sezon.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Filtry rynkowe
          _buildMarketFilters(),
          const SizedBox(height: 16),

          // Lista potencjalnych sponsorów
          if (prospectiveSponsors.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'Brak dostępnych sponsorów spełniających wybrane kryteria filtrów.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prospectiveSponsors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final company = prospectiveSponsors[index];
                return _buildProspectiveSponsorCard(save, team, company);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMarketFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Wszystkie
          ChoiceChip(
            label: const Text('Wszyscy Sponsorzy'),
            selected: _selectedTierFilter == null,
            onSelected: (_) => setState(() => _selectedTierFilter = null),
            selectedColor: AppColors.primaryGold,
            backgroundColor: AppColors.cardSurface,
            side: const BorderSide(color: AppColors.cardBorder),
            labelStyle: TextStyle(
              color: _selectedTierFilter == null ? Colors.black : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),

          // Rangi
          ...SponsorTier.values.map((tier) {
            final isSelected = _selectedTierFilter == tier;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(tier.name.toUpperCase()),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedTierFilter = tier),
                selectedColor: AppColors.primaryGold,
                backgroundColor: AppColors.cardSurface,
                side: const BorderSide(color: AppColors.cardBorder),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProspectiveSponsorCard(
    CareerSave save,
    CyclingTeam team,
    PotentialSponsorCompany company,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.domain_rounded, color: AppColors.primaryGold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        company.countryIso,
                        style: const TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        company.defaultTier.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  company.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Budżet bazowy: €${_formatCurrency(company.baseAnnualBudgetEur)}/rok',
                      style: const TextStyle(
                        color: AppColors.statusSuccess,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                    Text(
                      'Wymóg prestiżu: ${company.minimumTeamPrestigeRequirement.toInt()} pkt',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            onPressed: () => _openPitchDeckDialog(save, team, company),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Negocjuj Umowę',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPitchDeckDialog(
    CareerSave save,
    CyclingTeam team,
    PotentialSponsorCompany company,
  ) async {
    final int wtStarts = save.calendar.races
        .where((r) => r.uciCategory.name.toLowerCase().contains('world'))
        .length;

    final signedContract = await SponsorPitchDeckNegotiationModal.show(
      context,
      company: company,
      team: team,
      roster: save.playerRoster,
      worldTourStartsCount: wtStarts > 0 ? wtStarts : null,
    );

    if (signedContract != null && mounted) {
      ref.read(careerProvider.notifier).acceptSponsorContract(signedContract);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusSuccess,
          content: Text(
            'Podpisano oficjalny kontrakt ze sponsorem ${signedContract.companyName}!',
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // 4. WIDOK 3: FINANSE, RAPORT CASHFLOW & PROGNOZA NA KONIEC SEZONU
  // ===========================================================================

  Widget _buildFinancesAndForecastView(CareerSave save, CyclingTeam team) {
    final report = FinanceAndBudgetService.generateMonthlyCashflowReport(save: save);

    // Prognoza budżetowa na koniec sezonu (31 grudnia)
    final remainingMonths = math.max(1, 12 - save.currentDate.month);
    final projectedOperationalNet = report.netCashflowEur * remainingMonths;

    // Szacowane potencjalne premie za cele sponsorskie
    final potentialBonuses = team.sponsors.fold(
      0,
      (acc, s) => acc + s.objectives.where((o) => !o.isCompleted).fold(0, (bAcc, o) => bAcc + (o.bonusPaymentEur * 0.4).round()),
    );

    final projectedEndingBalance = team.cashBalanceEur + projectedOperationalNet + potentialBonuses;
    final isProjectedSurplus = projectedEndingBalance >= team.cashBalanceEur;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Karty KPI budżetu
          _buildFinancialKpiGrid(team, report),
          const SizedBox(height: 20),

          // Karta prognozy na koniec sezonu
          _buildEndOfSeasonProjectionCard(
            team: team,
            remainingMonths: remainingMonths,
            projectedOperationalNet: projectedOperationalNet,
            potentialBonuses: potentialBonuses,
            projectedEndingBalance: projectedEndingBalance,
            isProjectedSurplus: isProjectedSurplus,
          ),
          const SizedBox(height: 20),

          // Tabela przychodów i kosztów
          _buildCashflowBreakdownTable(report),
          const SizedBox(height: 20),

          // Rekomendacje doradcy finansowego
          _buildFinancialAdvisorRecommendationsCard(report),
          const SizedBox(height: 20),

          // Dziennik ostatnich transakcji
          _buildRecentTransactionsLedger(save),
        ],
      ),
    );
  }

  Widget _buildFinancialKpiGrid(CyclingTeam team, MonthlyCashflowReport report) {
    final healthScore = report.financialHealthScore;
    final healthColor = healthScore >= 70
        ? AppColors.statusSuccess
        : (healthScore >= 40 ? AppColors.primaryGold : AppColors.powerZone6);

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildKpiTile(
          title: 'STAN KONTA',
          value: '€${_formatCurrency(team.cashBalanceEur)}',
          subtitle: 'Dostępna płynność gotówkowa',
          icon: Icons.account_balance_wallet_rounded,
          accentColor: AppColors.statusSuccess,
        ),
        _buildKpiTile(
          title: 'BILANS MIESIĘCZNY',
          value: '${report.netCashflowEur >= 0 ? "+" : ""}€${_formatCurrency(report.netCashflowEur)}',
          subtitle: report.isProfitable ? 'Klub generuje zysk' : 'Deficyt operacyjny',
          icon: report.isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          accentColor: report.isProfitable ? AppColors.statusSuccess : AppColors.powerZone6,
        ),
        _buildKpiTile(
          title: 'FINANCIAL RUNWAY',
          value: '${report.runwayMonths.toStringAsFixed(1)} msc',
          subtitle: 'Bezpieczeństwo rezerw klubu',
          icon: Icons.timer_rounded,
          accentColor: report.runwayMonths >= 6.0 ? AppColors.accentBlue : AppColors.powerZone6,
        ),
        _buildKpiTile(
          title: 'FINANCIAL HEALTH',
          value: '$healthScore / 100',
          subtitle: healthScore >= 70 ? 'Stabilna sytuacja' : 'Wymaga cięcia kosztów',
          icon: Icons.shield_rounded,
          accentColor: healthColor,
        ),
      ],
    );
  }

  Widget _buildKpiTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfSeasonProjectionCard({
    required CyclingTeam team,
    required int remainingMonths,
    required int projectedOperationalNet,
    required int potentialBonuses,
    required int projectedEndingBalance,
    required bool isProjectedSurplus,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardDark,
            isProjectedSurplus
                ? AppColors.statusSuccess.withValues(alpha: 0.12)
                : AppColors.powerZone6.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isProjectedSurplus
              ? AppColors.statusSuccess.withValues(alpha: 0.3)
              : AppColors.powerZone6.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.query_stats_rounded,
                color: isProjectedSurplus ? AppColors.statusSuccess : AppColors.powerZone6,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'PROGNOZA BUDŻETOWA NA KONIEC SEZONU (31 GRUDNIA)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isProjectedSurplus
                      ? AppColors.statusSuccess.withValues(alpha: 0.2)
                      : AppColors.powerZone6.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isProjectedSurplus ? 'STABILNA NADWYŻKA' : 'RYZYKO DEFICYTU',
                  style: TextStyle(
                    color: isProjectedSurplus ? AppColors.statusSuccess : AppColors.powerZone6,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pozostałe miesiące:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('$remainingMonths msc', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Przepływ operacyjny:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${projectedOperationalNet >= 0 ? "+" : ""}€${_formatCurrency(projectedOperationalNet)}',
                      style: TextStyle(
                        color: projectedOperationalNet >= 0 ? AppColors.statusSuccess : AppColors.powerZone6,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Oczekiwane premie:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('+€${_formatCurrency(potentialBonuses)}', style: const TextStyle(color: AppColors.primaryGold, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prognozowane saldo:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '€${_formatCurrency(projectedEndingBalance)}',
                      style: TextStyle(
                        color: projectedEndingBalance >= 0 ? AppColors.statusSuccess : AppColors.powerZone6,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowBreakdownTable(MonthlyCashflowReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ZESTAWIENIE PRZYCHODÓW I KOSZTÓW MIESIĘCZNYCH',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),

          // Przychody
          const Text(
            'PRZYCHODY (INCOME)',
            style: TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 6),
          _buildCashflowLine('Transze sponsorskie', report.sponsorPayoutEur, isIncome: true),
          _buildCashflowLine('Wsparcie producenta rowerów', report.bikeManufacturerCashEur, isIncome: true),
          _buildCashflowLine('Nagrody z wyścigów (udział klubu)', report.prizeMoneyClubShareEur, isIncome: true),
          _buildCashflowLine('Wpływy z transferów i wykupów', report.riderBuyoutIncomeEur, isIncome: true),
          _buildCashflowLine('Inne przychody komercyjne', report.otherIncomeEur, isIncome: true),
          const Divider(height: 12, color: AppColors.cardBorder),
          _buildCashflowLine('ŁĄCZNE PRZYCHODY', report.totalIncomeEur, isIncome: true, isBold: true),
          const SizedBox(height: 16),

          // Koszty
          const Text(
            'KOSZTY I WYDATKI (EXPENSES)',
            style: TextStyle(color: AppColors.powerZone6, fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(height: 6),
          _buildCashflowLine('Wynagrodzenia kolarzy', report.riderSalariesEur, isIncome: false),
          _buildCashflowLine('Wynagrodzenia sztabu szkoleniowego', report.staffSalariesEur, isIncome: false),
          _buildCashflowLine('Logistyka wyścigów, hotele i podróże', report.raceLogisticsEur, isIncome: false),
          _buildCashflowLine('Zgrupowania i obozy wysokogórskie', report.trainingCampsEur, isIncome: false),
          _buildCashflowLine('Badania laboratoryjne i fizjologia', report.physiologicalTestingEur, isIncome: false),
          _buildCashflowLine('Serwis rowerów i zakup części', report.equipmentServiceAndPurchasesEur, isIncome: false),
          _buildCashflowLine('Utrzymanie bazy i infrastruktury', report.facilitiesMaintenanceEur, isIncome: false),
          const Divider(height: 12, color: AppColors.cardBorder),
          _buildCashflowLine('ŁĄCZNE KOSZTY OPERACYJNE', report.totalExpensesEur, isIncome: false, isBold: true),
        ],
      ),
    );
  }

  Widget _buildCashflowLine(String title, int amount, {required bool isIncome, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              fontSize: isBold ? 12.5 : 11.5,
            ),
          ),
          Text(
            '${isIncome ? "+" : "-"}€${_formatCurrency(amount)}',
            style: TextStyle(
              color: isIncome ? AppColors.statusSuccess : AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontSize: isBold ? 13 : 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialAdvisorRecommendationsCard(MonthlyCashflowReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates_rounded, color: AppColors.primaryGold, size: 20),
              SizedBox(width: 8),
              Text(
                'Rekomendacje Doradcy Finansowego',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...report.recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w900)),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsLedger(CareerSave save) {
    final ledger = save.financeLedger.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DZIENNIK OSTATNICH TRANSAKCJI FINANSOWYCH',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (ledger.isEmpty)
            const Text('Brak zarejestrowanych transakcji w bieżącym okresie.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
          else
            ...ledger.map((entry) {
              final isPositive = entry.amountEur >= 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text(
                      '${entry.date.day}.${entry.date.month}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      ),
                    ),
                    Text(
                      '${isPositive ? "+" : ""}€${_formatCurrency(entry.amountEur)}',
                      style: TextStyle(
                        color: isPositive ? AppColors.statusSuccess : AppColors.powerZone6,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERY I FORMATOWANIE
  // ===========================================================================

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  Color _parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }
}

// =============================================================================
// WEKTOROWY PAINTER KOSZULKI KOLARSKIEJ (TEAM JERSEY PAINTER)
// =============================================================================

class TeamJerseyPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String primarySponsorName;
  final String secondarySponsorName;
  final String bikeManufacturerName;
  final String teamCountryIso;
  final bool isBackView;

  TeamJerseyPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.primarySponsorName,
    required this.secondarySponsorName,
    required this.bikeManufacturerName,
    required this.teamCountryIso,
    required this.isBackView,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final bodyPaint = Paint()..color = primaryColor;
    final sleevePaint = Paint()..color = secondaryColor;
    final accentPaint = Paint()..color = accentColor;
    final strokePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. RĘKAW LEWY
    final leftSleevePath = Path()
      ..moveTo(w * 0.28, h * 0.18)
      ..lineTo(w * 0.04, h * 0.36)
      ..lineTo(w * 0.12, h * 0.46)
      ..lineTo(w * 0.30, h * 0.36)
      ..close();
    canvas.drawPath(leftSleevePath, sleevePaint);
    canvas.drawPath(leftSleevePath, strokePaint);

    // 2. RĘKAW PRAWY
    final rightSleevePath = Path()
      ..moveTo(w * 0.72, h * 0.18)
      ..lineTo(w * 0.96, h * 0.36)
      ..lineTo(w * 0.88, h * 0.46)
      ..lineTo(w * 0.70, h * 0.36)
      ..close();
    canvas.drawPath(rightSleevePath, sleevePaint);
    canvas.drawPath(rightSleevePath, strokePaint);

    // 3. KORPUS GŁÓWNY (TORSO)
    final torsoPath = Path()
      ..moveTo(w * 0.36, h * 0.14) // lewy kołnierz
      ..quadraticBezierTo(w * 0.50, isBackView ? h * 0.15 : h * 0.19, w * 0.64, h * 0.14) // dekolt
      ..lineTo(w * 0.72, h * 0.18) // prawe ramię
      ..lineTo(w * 0.70, h * 0.36) // prawa pacha
      ..quadraticBezierTo(w * 0.67, h * 0.60, w * 0.68, h * 0.88) // prawy bok
      ..lineTo(w * 0.32, h * 0.88) // dolny ściągacz
      ..quadraticBezierTo(w * 0.33, h * 0.60, w * 0.30, h * 0.36) // lewy bok
      ..lineTo(w * 0.28, h * 0.18) // lewa pacha
      ..close();
    canvas.drawPath(torsoPath, bodyPaint);
    canvas.drawPath(torsoPath, strokePaint);

    // 4. BOCZNE PANELE WENTYLACYJNE (AKCENT)
    final leftSidePanel = Path()
      ..moveTo(w * 0.30, h * 0.36)
      ..lineTo(w * 0.33, h * 0.38)
      ..quadraticBezierTo(w * 0.35, h * 0.62, w * 0.35, h * 0.88)
      ..lineTo(w * 0.32, h * 0.88)
      ..quadraticBezierTo(w * 0.33, h * 0.60, w * 0.30, h * 0.36)
      ..close();
    canvas.drawPath(leftSidePanel, accentPaint);

    final rightSidePanel = Path()
      ..moveTo(w * 0.70, h * 0.36)
      ..lineTo(w * 0.67, h * 0.38)
      ..quadraticBezierTo(w * 0.65, h * 0.62, w * 0.65, h * 0.88)
      ..lineTo(w * 0.68, h * 0.88)
      ..quadraticBezierTo(w * 0.67, h * 0.60, w * 0.70, h * 0.36)
      ..close();
    canvas.drawPath(rightSidePanel, accentPaint);

    // 5. ZAMEK BŁYSKAWICZNY / SZWY
    if (!isBackView) {
      final zipPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(w * 0.50, h * 0.19), Offset(w * 0.50, h * 0.88), zipPaint);
    }

    // 6. LOGOTYPY I GRAFIKI SPONSORSKIE
    if (!isBackView) {
      // Przód koszulki: Główny pas sponsorski
      final chestBannerRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.52), width: w * 0.34, height: h * 0.14),
        const Radius.circular(6),
      );
      canvas.drawRRect(chestBannerRect, Paint()..color = Colors.white.withValues(alpha: 0.95));

      // Napis sponsora tytularnego
      final textSpan = TextSpan(
        text: primarySponsorName.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w * 0.32);
      tp.paint(canvas, Offset(w * 0.50 - tp.width / 2, h * 0.52 - tp.height / 2));

      // Drugi sponsor na górze klatki
      final secTextSpan = TextSpan(
        text: secondarySponsorName.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      );
      final secTp = TextPainter(
        text: secTextSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w * 0.28);
      secTp.paint(canvas, Offset(w * 0.50 - secTp.width / 2, h * 0.30));

      // Producent roweru na kołnierzu
      final bikeTextSpan = TextSpan(
        text: bikeManufacturerName.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      );
      final bikeTp = TextPainter(
        text: bikeTextSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w * 0.20);
      bikeTp.paint(canvas, Offset(w * 0.50 - bikeTp.width / 2, h * 0.72));
    } else {
      // Tył koszulki: Numer startowy (Race Bib)
      final bibRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.48), width: w * 0.22, height: h * 0.16),
        const Radius.circular(4),
      );
      canvas.drawRRect(bibRect, Paint()..color = Colors.white);
      canvas.drawRRect(bibRect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.0);

      const numberSpan = TextSpan(
        text: '1',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      );
      final numTp = TextPainter(
        text: numberSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      numTp.paint(canvas, Offset(w * 0.50 - numTp.width / 2, h * 0.48 - numTp.height / 2));

      // Kieszenie kolarskie z tyłu (3 przegrody)
      final pocketLineY = h * 0.68;
      canvas.drawLine(Offset(w * 0.33, pocketLineY), Offset(w * 0.67, pocketLineY), strokePaint);
      canvas.drawLine(Offset(w * 0.44, pocketLineY), Offset(w * 0.44, h * 0.88), strokePaint);
      canvas.drawLine(Offset(w * 0.56, pocketLineY), Offset(w * 0.56, h * 0.88), strokePaint);

      // Sponsor na kieszeniach
      final pocketSponsorSpan = TextSpan(
        text: primarySponsorName.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      );
      final pocketTp = TextPainter(
        text: pocketSponsorSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w * 0.30);
      pocketTp.paint(canvas, Offset(w * 0.50 - pocketTp.width / 2, h * 0.76));
    }
  }

  @override
  bool shouldRepaint(covariant TeamJerseyPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.primarySponsorName != primarySponsorName ||
        oldDelegate.secondarySponsorName != secondarySponsorName ||
        oldDelegate.isBackView != isBackView;
  }
}

