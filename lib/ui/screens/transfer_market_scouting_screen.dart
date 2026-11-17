import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/scouting_and_youth_academy_service.dart';
import '../../services/career/transfer_market_service.dart';
import '../../state/career_controller.dart';
import '../widgets/rider_avatar_painter.dart';
import '../widgets/rider_career_trajectory_forecast_chart.dart';

/// Zakładki główne ekranu rynku transferowego i skautingu.
enum TransferScoutingTab {
  transferMarket,
  scoutingAcademy;

  String get label {
    switch (this) {
      case TransferScoutingTab.transferMarket:
        return 'Rynek Transferowy';
      case TransferScoutingTab.scoutingAcademy:
        return 'Skauting U23 & Akademia';
    }
  }

  IconData get icon {
    switch (this) {
      case TransferScoutingTab.transferMarket:
        return Icons.swap_horiz_rounded;
      case TransferScoutingTab.scoutingAcademy:
        return Icons.search_rounded;
    }
  }
}

/// Kryteria sortowania kolarzy na rynku transferowym.
enum TransferSortBy {
  marketValue,
  wattsPerKg,
  sprint,
  age,
  releaseClause,
  name;

  String get label {
    switch (this) {
      case TransferSortBy.marketValue:
        return 'Wartość Rynkowa';
      case TransferSortBy.wattsPerKg:
        return 'Moc W/kg';
      case TransferSortBy.sprint:
        return 'Sprint';
      case TransferSortBy.age:
        return 'Wiek';
      case TransferSortBy.releaseClause:
        return 'Klauzula Wykupu';
      case TransferSortBy.name:
        return 'Nazwisko';
    }
  }
}

/// Ekran Rynku Transferowego i Skautingu (`TransferMarketScoutingScreen`).
class TransferMarketScoutingScreen extends ConsumerStatefulWidget {
  const TransferMarketScoutingScreen({super.key});

  @override
  ConsumerState<TransferMarketScoutingScreen> createState() =>
      _TransferMarketScoutingScreenState();
}

class _TransferMarketScoutingScreenState
    extends ConsumerState<TransferMarketScoutingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filtry wyszukiwarki rynku
  String _searchQuery = '';
  String _selectedAgeGroup = 'ALL'; // ALL, U23, PRIME, VETERAN
  bool _onlyExpiringContracts = false;
  double _minWattsPerKg = 0.0;
  int _minSprint = 0;
  final String _selectedCountryIso = 'ALL';
  bool _onlyWithReleaseClause = false;
  TransferSortBy _sortBy = TransferSortBy.marketValue;

  // Filtr adeptów skautingu
  ScoutingDiscoveryStage? _prospectStageFilter;
  final Set<String> _expandedForecastProspectIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                  _buildTransferMarketView(save, team),
                  _buildScoutingAcademyView(save, team),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. NAGŁÓWEK I PRZEŁĄCZNIK ZAKŁADEK
  // ===========================================================================

  Widget _buildTopHeader(CyclingTeam team, CareerSave save) {
    final isOpen = TransferMarketService.isTransferWindowOpen(save.currentDate);
    final daysUntil = TransferMarketService.daysUntilTransferWindowOpens(save.currentDate);

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
              color: AppColors.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.swap_horizontal_circle_rounded,
              color: AppColors.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Rynek Transferowy & Skauting Młodzieżowy',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? AppColors.statusSuccess.withValues(alpha: 0.15)
                            : AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOpen
                              ? AppColors.statusSuccess.withValues(alpha: 0.4)
                              : AppColors.primaryGold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isOpen ? 'OKNO OTWARTE (UCI)' : 'OTWARCIE ZA $daysUntil DNI',
                        style: TextStyle(
                          color: isOpen ? AppColors.statusSuccess : AppColors.primaryGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Budżet transferowy i płacowy: €${_formatCurrency(team.cashBalanceEur)} • Kadra: ${team.rosterRiderIds.length} zawodników',
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
        indicatorColor: AppColors.accentBlue,
        indicatorWeight: 3,
        labelColor: AppColors.accentBlue,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: TransferScoutingTab.values.map((tab) {
          return Tab(
            icon: Icon(tab.icon, size: 18),
            text: tab.label,
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 2. WIDOK 1: RYNEK TRANSFEROWY & WYSZUKIWARKA KOLARZY
  // ===========================================================================

  Widget _buildTransferMarketView(CareerSave save, CyclingTeam team) {
    final filteredRiders = _getFilteredRiders(save);

    return Column(
      children: [
        _buildFilterBar(save),
        Expanded(
          child: filteredRiders.isEmpty
              ? const Center(
                  child: Text(
                    'Brak kolarzy spełniających wybrane kryteria wyszukiwania.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRiders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final rider = filteredRiders[index];
                    return _buildRiderMarketCard(save, team, rider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(CareerSave save) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardDark,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Column(
        children: [
          // Pole wyszukiwania + sortowanie
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Szukaj kolarza po nazwisku lub kraju...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TransferSortBy>(
                      value: _sortBy,
                      isExpanded: true,
                      dropdownColor: AppColors.cardSurface,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                      items: TransferSortBy.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text('Sortuj: ${s.label}'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pasek filtrów w pigułkach
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Kończący się kontrakt
                FilterChip(
                  label: const Text('Kończący się kontrakt'),
                  selected: _onlyExpiringContracts,
                  selectedColor: AppColors.primaryGold.withValues(alpha: 0.2),
                  backgroundColor: AppColors.cardSurface,
                  side: BorderSide(
                    color: _onlyExpiringContracts ? AppColors.primaryGold : AppColors.cardBorder,
                  ),
                  labelStyle: TextStyle(
                    color: _onlyExpiringContracts ? AppColors.primaryGold : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  onSelected: (val) => setState(() => _onlyExpiringContracts = val),
                ),
                const SizedBox(width: 8),

                // Wiek
                ...['ALL', 'U23', 'PRIME', 'VETERAN'].map((ageKey) {
                  final isSelected = _selectedAgeGroup == ageKey;
                  String label = 'Wiek: Wszystkie';
                  if (ageKey == 'U23') label = 'Do 23 lat (U23)';
                  if (ageKey == 'PRIME') label = '24-29 lat (Prime)';
                  if (ageKey == 'VETERAN') label = '30+ lat';

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: AppColors.accentBlue.withValues(alpha: 0.2),
                      backgroundColor: AppColors.cardSurface,
                      side: BorderSide(
                        color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setState(() => _selectedAgeGroup = ageKey),
                    ),
                  );
                }),

                // Min. W/kg
                ...[0.0, 4.8, 5.2, 5.6, 6.0].map((wkg) {
                  final isSelected = _minWattsPerKg == wkg;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(wkg == 0.0 ? 'W/kg: Dowolne' : '>$wkg W/kg'),
                      selected: isSelected,
                      selectedColor: AppColors.powerZone5.withValues(alpha: 0.2),
                      backgroundColor: AppColors.cardSurface,
                      side: BorderSide(
                        color: isSelected ? AppColors.powerZone5 : AppColors.cardBorder,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.powerZone5 : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setState(() => _minWattsPerKg = wkg),
                    ),
                  );
                }),

                // Min. Sprint
                ...[0, 75, 80, 85].map((sprintVal) {
                  final isSelected = _minSprint == sprintVal;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(sprintVal == 0 ? 'Sprint: Dowolny' : 'Sprint >$sprintVal'),
                      selected: isSelected,
                      selectedColor: AppColors.powerZone6.withValues(alpha: 0.2),
                      backgroundColor: AppColors.cardSurface,
                      side: BorderSide(
                        color: isSelected ? AppColors.powerZone6 : AppColors.cardBorder,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.powerZone6 : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setState(() => _minSprint = sprintVal),
                    ),
                  );
                }),

                // Tylko z klauzulą wykupu
                FilterChip(
                  label: const Text('Z klauzulą wykupu'),
                  selected: _onlyWithReleaseClause,
                  selectedColor: AppColors.statusSuccess.withValues(alpha: 0.2),
                  backgroundColor: AppColors.cardSurface,
                  side: BorderSide(
                    color: _onlyWithReleaseClause ? AppColors.statusSuccess : AppColors.cardBorder,
                  ),
                  labelStyle: TextStyle(
                    color: _onlyWithReleaseClause ? AppColors.statusSuccess : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  onSelected: (val) => setState(() => _onlyWithReleaseClause = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Rider> _getFilteredRiders(CareerSave save) {
    final currentYear = save.currentSeasonYear;

    final filtered = save.riders.where((rider) {
      // 1. Wyszukiwarka tekstowa
      if (_searchQuery.isNotEmpty) {
        final matchName = rider.fullName.toLowerCase().contains(_searchQuery);
        final matchCountry = rider.nationalityIso.toLowerCase().contains(_searchQuery);
        if (!matchName && !matchCountry) return false;
      }

      // 2. Kończący się kontrakt
      if (_onlyExpiringContracts && !rider.contract.isExpiring(currentYear)) {
        return false;
      }

      // 2b. Narodowość
      if (_selectedCountryIso != 'ALL' && rider.nationalityIso != _selectedCountryIso) {
        return false;
      }

      // 3. Wiek
      if (_selectedAgeGroup == 'U23' && rider.age > 23) return false;
      if (_selectedAgeGroup == 'PRIME' && (rider.age < 24 || rider.age > 29)) return false;
      if (_selectedAgeGroup == 'VETERAN' && rider.age < 30) return false;

      // 4. Min W/kg
      final wKg = rider.physiology.ftpWatts / rider.physiology.weightKg;
      if (wKg < _minWattsPerKg) return false;

      // 5. Min Sprint
      if (rider.scoreSprint < _minSprint) return false;

      // 6. Klauzula wykupu
      if (_onlyWithReleaseClause && rider.contract.releaseClauseEur <= 0) return false;

      return true;
    }).toList();

    // Sortowanie
    filtered.sort((a, b) {
      switch (_sortBy) {
        case TransferSortBy.marketValue:
          return TransferMarketService.calculateMarketValue(b).compareTo(
            TransferMarketService.calculateMarketValue(a),
          );
        case TransferSortBy.wattsPerKg:
          final wKgA = a.physiology.ftpWatts / a.physiology.weightKg;
          final wKgB = b.physiology.ftpWatts / b.physiology.weightKg;
          return wKgB.compareTo(wKgA);
        case TransferSortBy.sprint:
          return b.scoreSprint.compareTo(a.scoreSprint);
        case TransferSortBy.age:
          return a.age.compareTo(b.age);
        case TransferSortBy.releaseClause:
          return b.contract.releaseClauseEur.compareTo(a.contract.releaseClauseEur);
        case TransferSortBy.name:
          return a.lastName.compareTo(b.lastName);
      }
    });

    return filtered;
  }

  Widget _buildRiderMarketCard(CareerSave save, CyclingTeam playerTeam, Rider rider) {
    final isPlayerRider = rider.contract.teamId == playerTeam.id;
    final riderTeam = save.teams.firstWhere(
      (t) => t.id == rider.contract.teamId,
      orElse: () => playerTeam,
    );

    final wKg = rider.physiology.ftpWatts / rider.physiology.weightKg;
    final marketVal = TransferMarketService.calculateMarketValue(rider);
    final isExpiring = rider.contract.isExpiring(save.currentSeasonYear);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPlayerRider
            ? AppColors.cardSurface.withValues(alpha: 0.6)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpiring
              ? AppColors.primaryGold.withValues(alpha: 0.4)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Portret kolarza
          RiderAvatarWidget(
            appearance: rider.appearance,
            team: riderTeam,
            size: 46,
          ),
          const SizedBox(width: 14),

          // Dane kolarza
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      rider.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rider.nationalityIso,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isPlayerRider)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TWÓJ ZESPÓŁ',
                          style: TextStyle(
                            color: AppColors.statusSuccess,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${rider.age} lat • ${riderTeam.name} • ${rider.specialization.name.toUpperCase()}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildMiniParamPill('W/kg', wKg.toStringAsFixed(2), AppColors.powerZone5),
                    _buildMiniParamPill('FTP', '${rider.physiology.ftpWatts}W', AppColors.accentBlue),
                    _buildMiniParamPill('Sprint', '${rider.scoreSprint.round()}', AppColors.powerZone6),
                    _buildMiniParamPill('Góry', '${rider.scoreClimb.round()}', AppColors.primaryGold),
                  ],
                ),
              ],
            ),
          ),

          // Informacje kontraktowe
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Wartość: €${_formatCurrency(marketVal)}',
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pensja: €${_formatCurrency(rider.contract.annualSalaryEur)}/rok',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                if (rider.contract.releaseClauseEur > 0)
                  Text(
                    'Klauzula: €${_formatCurrency(rider.contract.releaseClauseEur)}',
                    style: const TextStyle(color: AppColors.statusSuccess, fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                if (isExpiring)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'KONIEC KONTRAKTU 2026',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Przycisk negocjacji
          ElevatedButton(
            onPressed: isPlayerRider ? null : () => _openNegotiationModal(save, playerTeam, rider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isExpiring ? 'Podpisz za darmo' : 'Złóż Ofertę',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniParamPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. EKRAN / MODAL NEGOCJACJI KONTRAKTU Z AGENTEM
  // ===========================================================================

  void _openNegotiationModal(CareerSave save, CyclingTeam playerTeam, Rider rider) {
    final marketSalary = TransferMarketService.calculateMarketValue(rider);
    int proposedSalary = (rider.contract.annualSalaryEur * 1.05 / 1000).round() * 1000;
    int winBonus = 15000;
    int durationYears = 2;
    RiderRole proposedRole = RiderRole.teamLeader;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nagłówek kolarza
                  Row(
                    children: [
                      RiderAvatarWidget(
                        appearance: rider.appearance,
                        size: 48,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Wycena rynkowa: €${_formatCurrency(marketSalary)} • Aktualna pensja: €${_formatCurrency(rider.contract.annualSalaryEur)}/rok',
                              style: const TextStyle(color: AppColors.primaryGold, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  const SizedBox(height: 14),

                  // Suwak pensji rocznej
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Proponowana Pensja Roczna:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        '€${_formatCurrency(proposedSalary)} / rok',
                        style: const TextStyle(color: AppColors.statusSuccess, fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  Slider(
                    value: proposedSalary.toDouble(),
                    min: (rider.contract.annualSalaryEur * 0.4).clamp(15000.0, 10000000.0),
                    max: math.max(proposedSalary * 2.0, (rider.contract.annualSalaryEur * 2.2).toDouble()),
                    divisions: 30,
                    activeColor: AppColors.statusSuccess,
                    inactiveColor: AppColors.cardBorder,
                    onChanged: (val) => setModalState(() => proposedSalary = (val / 1000).round() * 1000),
                  ),

                  // Suwak premii za wygraną
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Premia za zwycięstwo w wyścigu:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(
                        '€${_formatCurrency(winBonus)}',
                        style: const TextStyle(color: AppColors.primaryGold, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Slider(
                    value: winBonus.toDouble(),
                    min: 5000,
                    max: 100000,
                    divisions: 19,
                    activeColor: AppColors.primaryGold,
                    inactiveColor: AppColors.cardBorder,
                    onChanged: (val) => setModalState(() => winBonus = val.round()),
                  ),

                  // Wybór roli w zespole
                  const Text('Proponowana rola w kadrze drużyny:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RiderRole>(
                        value: proposedRole,
                        isExpanded: true,
                        dropdownColor: AppColors.cardSurface,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                        items: RiderRole.values.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => proposedRole = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Długość umowy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Długość kontraktu:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text('$durationYears lata', style: const TextStyle(color: AppColors.accentBlue, fontSize: 13, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  Slider(
                    value: durationYears.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AppColors.accentBlue,
                    inactiveColor: AppColors.cardBorder,
                    onChanged: (val) => setModalState(() => durationYears = val.round()),
                  ),
                  const SizedBox(height: 14),

                  // Przycisk złożenia oferty
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _submitContractOfferToAgent(
                        rider: rider,
                        salaryEur: proposedSalary,
                        years: durationYears,
                        role: proposedRole,
                        winBonusEur: winBonus,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Prześlij Ofertę do Agenta Kolarza',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submitContractOfferToAgent({
    required Rider rider,
    required int salaryEur,
    required int years,
    required RiderRole role,
    required int winBonusEur,
  }) {
    final result = ref.read(careerProvider.notifier).submitTransferOffer(
      riderId: rider.id,
      annualSalaryEur: salaryEur,
      contractDurationYears: years,
      proposedRole: role,
      winBonusEur: winBonusEur,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Row(
            children: [
              Icon(
                result.isAccepted
                    ? Icons.check_circle_rounded
                    : (result.isCounterOffer ? Icons.handshake_rounded : Icons.cancel_rounded),
                color: result.isAccepted
                    ? AppColors.statusSuccess
                    : (result.isCounterOffer ? AppColors.primaryGold : AppColors.powerZone6),
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                result.isAccepted
                    ? 'Oferta Zaakceptowana!'
                    : (result.isCounterOffer ? 'Kontroferta Agenta' : 'Oferta Odrzucona'),
                style: TextStyle(
                  color: result.isAccepted
                      ? AppColors.statusSuccess
                      : (result.isCounterOffer ? AppColors.primaryGold : AppColors.powerZone6),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${result.agentQuote}"',
                style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Text(
                'Nota całościowa oferty: ${result.overallScore.toStringAsFixed(1)} / 100 pkt',
                style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w800, fontSize: 12),
              ),
              const SizedBox(height: 8),

              // Breakdown filarów
              _buildFilerBar('Wynagrodzenie i finanse (35%)', result.salaryScore / 35.0),
              _buildFilerBar('Rola w zespole (25%)', result.roleScore / 25.0),
              _buildFilerBar('Prestiż dywizji klubu (20%)', result.prestigeScore / 20.0),
              _buildFilerBar('Jakość sprzętu rowerowego (10%)', result.equipmentScore / 10.0),
              _buildFilerBar('Konflikt liderów (10%)', result.leaderConflictScore / 10.0),

              if (result.hasLeaderConflict && result.conflictingLeaderName != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.powerZone6.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚠️ Konflikt liderów: Pozycja zablokowana przez ${result.conflictingLeaderName}',
                    style: const TextStyle(color: AppColors.powerZone6, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zamknij', style: TextStyle(color: AppColors.textSecondary)),
            ),
            if (result.isAccepted)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.statusSuccess,
                      content: Text('Kolarz ${rider.fullName} oficjalnie dołączy do twojego zespołu w nowym sezonie!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusSuccess),
                child: const Text('Zatwierdź Transfer'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilerBar(String label, double ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.cardSurface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ratio >= 0.7 ? AppColors.statusSuccess : (ratio >= 0.4 ? AppColors.primaryGold : AppColors.powerZone6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. WIDOK 2: SKAUTING U23 & AKADEMIA TALENTÓW
  // ===========================================================================

  Widget _buildScoutingAcademyView(CareerSave save, CyclingTeam team) {
    final prospects = ref.read(careerProvider.notifier).getScoutedProspects();
    final academy = ref.read(careerProvider.notifier).getYouthAcademy() ?? save.youthAcademy;

    final filteredProspects = prospects.where((p) {
      if (_prospectStageFilter != null && p.discoveryStage != _prospectStageFilter) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Karta statusu Akademii Młodzieżowej
          _buildAcademyStatusCard(team, academy),
          const SizedBox(height: 20),

          // Panel wysyłania skautów na zawody
          _buildScoutMissionPanel(team),
          const SizedBox(height: 20),

          // Pula adeptów skautingu
          _buildProspectsSection(save, filteredProspects),
        ],
      ),
    );
  }

  Widget _buildAcademyStatusCard(CyclingTeam team, YouthAcademy academy) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: AppColors.accentBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      academy.levelName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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
                        'POZIOM ${academy.level}/5',
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Miejsca: ${academy.enrolledProspectIds.length} / ${academy.maxCapacity} adeptów • Koszt: €${_formatCurrency(academy.monthlyMaintenanceCostEur)}/msc • Rozwój: +${((academy.developmentMultiplier - 1.0) * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (academy.level < 5)
            ElevatedButton.icon(
              onPressed: () {
                ref.read(careerProvider.notifier).upgradeYouthAcademy();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.statusSuccess,
                    content: Text('Rozbudowano Akademię Młodzieżową na kolejny poziom!'),
                  ),
                );
              },
              icon: const Icon(Icons.upgrade_rounded, size: 18),
              label: const Text('Rozbuduj Akademię', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoutMissionPanel(CyclingTeam team) {
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
              Icon(Icons.explore_rounded, color: AppColors.primaryGold, size: 20),
              SizedBox(width: 8),
              Text(
                'WYŚLIJ SKAUTA W TEREN (ODKRYWANIE TALENTÓW)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ScoutingSource.values.map((source) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: OutlinedButton(
                    onPressed: () => _dispatchScoutMission(source),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      backgroundColor: AppColors.cardSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source.badgeLabel,
                          style: TextStyle(
                            color: _parseHex(source.badgeColorHex, AppColors.accentBlue),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          source.label,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _dispatchScoutMission(ScoutingSource source) {
    try {
      final outcome = ref.read(careerProvider.notifier).sendScoutOnMission(source);
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.statusSuccess, size: 24),
                const SizedBox(width: 8),
                Text('Raport z Misji: ${source.badgeLabel}'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outcome.summary, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                const SizedBox(height: 12),
                Text('Koszt misji: €${_formatCurrency(outcome.totalCostEur)}', style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w700, fontSize: 12)),
                Text('Zaktualizowano profil ${outcome.discoveredOrUpdatedProspects.length} adeptów.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                child: const Text('Przejrzyj Odkrytych Kolarzy'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.powerZone6, content: Text('Błąd misji: $e')),
      );
    }
  }

  Widget _buildProspectsSection(CareerSave save, List<ScoutedProspect> prospects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PULA ADEPTÓW & MŁODYCH TALENTÓW',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            // Filtry stadium odkrycia
            Row(
              children: [
                _buildProspectFilterChip('Wszyscy', null),
                const SizedBox(width: 6),
                _buildProspectFilterChip('Wstępny raport', ScoutingDiscoveryStage.rawTalent),
                const SizedBox(width: 6),
                _buildProspectFilterChip('Po badaniach Lab', ScoutingDiscoveryStage.laboratoryTested),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (prospects.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Brak adeptów w wybranym filtrze.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...prospects.map((prospect) => _buildProspectCard(save, prospect)),
      ],
    );
  }

  Widget _buildProspectFilterChip(String label, ScoutingDiscoveryStage? stage) {
    final isSelected = _prospectStageFilter == stage;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.accentBlue.withValues(alpha: 0.2),
      backgroundColor: AppColors.cardSurface,
      side: BorderSide(
        color: isSelected ? AppColors.accentBlue : AppColors.cardBorder,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.accentBlue : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 10,
      ),
      onSelected: (_) => setState(() => _prospectStageFilter = stage),
    );
  }

  Widget _buildProspectCard(CareerSave save, ScoutedProspect prospect) {
    final isLabTested = prospect.discoveryStage == ScoutingDiscoveryStage.laboratoryTested;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLabTested ? AppColors.accentBlue.withValues(alpha: 0.4) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_search_rounded, color: AppColors.accentBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${prospect.firstName} ${prospect.lastName}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            prospect.nationalityIso,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _parseHex(prospect.source.badgeColorHex, AppColors.accentBlue).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            prospect.source.badgeLabel,
                            style: TextStyle(
                              color: _parseHex(prospect.source.badgeColorHex, AppColors.accentBlue),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${prospect.age} lat • Status: ${prospect.discoveryStage.label}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (prospect.isEnrolledInAcademy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'W AKADEMII',
                    style: TextStyle(color: AppColors.accentBlue, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Szacowane widełki parametrów (Mgła wojny)
          Row(
            children: [
              Expanded(
                child: _buildProspectStatTile(
                  label: 'Szacowane FTP',
                  value: isLabTested
                      ? '${prospect.trueRider.physiology.ftpWatts} W'
                      : '${prospect.estimatedMinFtpWatts} - ${prospect.estimatedMaxFtpWatts} W',
                  color: AppColors.statusSuccess,
                ),
              ),
              Expanded(
                child: _buildProspectStatTile(
                  label: 'Szacowane VO2max',
                  value: isLabTested
                      ? prospect.trueRider.physiology.vo2Max.toStringAsFixed(1)
                      : '${prospect.estimatedMinVo2Max.toStringAsFixed(0)} - ${prospect.estimatedMaxVo2Max.toStringAsFixed(0)}',
                  color: AppColors.accentBlue,
                ),
              ),
              Expanded(
                child: _buildProspectStatTile(
                  label: 'Potencjał Rozwoju',
                  value: isLabTested
                      ? '${prospect.trueRider.potential} pkt'
                      : '${prospect.estimatedMinPotential} - ${prospect.estimatedMaxPotential} pkt',
                  color: AppColors.primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prospect.scoutReport,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),

          // Przyciski akcji
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_expandedForecastProspectIds.contains(prospect.id)) {
                      _expandedForecastProspectIds.remove(prospect.id);
                    } else {
                      _expandedForecastProspectIds.add(prospect.id);
                    }
                  });
                },
                icon: Icon(
                  _expandedForecastProspectIds.contains(prospect.id)
                      ? Icons.expand_less_rounded
                      : Icons.auto_graph_rounded,
                  size: 16,
                ),
                label: Text(
                  _expandedForecastProspectIds.contains(prospect.id)
                      ? 'Ukryj prognozę 5L'
                      : 'Prognoza 5L',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGold,
                  side: const BorderSide(color: AppColors.primaryGold),
                ),
              ),
              if (!isLabTested)
                OutlinedButton.icon(
                  onPressed: () => _testProspectInLab(prospect),
                  icon: const Icon(Icons.science_rounded, size: 16),
                  label: const Text('Badania w Labie (€1 500)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentBlue,
                    side: const BorderSide(color: AppColors.accentBlue),
                  ),
                ),
              if (!prospect.isEnrolledInAcademy)
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(careerProvider.notifier).enrollProspectInAcademy(prospect.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.statusSuccess,
                        content: Text('Zapisano adepta ${prospect.firstName} do Akademii Młodzieżowej!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school_rounded, size: 16),
                  label: const Text('Zapisz do Akademii', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardDark,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(careerProvider.notifier).promoteProspectToProTeam(prospect.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.statusSuccess,
                      content: Text('Podpisano kontrakt zawodowy Neo-Pro z ${prospect.firstName} ${prospect.lastName}!'),
                    ),
                  );
                },
                icon: const Icon(Icons.badge_rounded, size: 16),
                label: const Text('Promuj do Zawodowców (Neo-Pro)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          if (_expandedForecastProspectIds.contains(prospect.id)) ...[
            const SizedBox(height: 12),
            RiderCareerTrajectoryForecastChart(
              prospect: prospect,
              startSeasonYear: save.currentDate.year,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }

  void _testProspectInLab(ScoutedProspect prospect) {
    try {
      final outcome = ref.read(careerProvider.notifier).testProspectInLab(prospect.id);
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Row(
              children: [
                const Icon(Icons.science_rounded, color: AppColors.accentBlue, size: 24),
                const SizedBox(width: 8),
                Text('Certyfikat Laboratoryjny: ${prospect.fullName}'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outcome.labCertificate, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                const SizedBox(height: 12),
                Text('Zmierzony FTP: ${outcome.measuredFtpWatts.toInt()} W', style: const TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.w800)),
                Text('Zmierzony VO2max: ${outcome.measuredVo2Max.toStringAsFixed(1)} ml/kg/min', style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w800)),
                Text('Potencjał mistrzowski: ${outcome.measuredPotential} pkt', style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.w800)),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                child: const Text('Zatwierdź Wyniki'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.powerZone6, content: Text('Błąd badań: $e')),
      );
    }
  }

  Widget _buildProspectStatTile({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
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

