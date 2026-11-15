// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/staff_member.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../../state/career_controller.dart';

/// Ekran Zarządzania Sztabem Szkoleniowo-Technicznym Drużyny (Staff Management Screen).
///
/// Funkcjonalności:
/// 1. **Zatrudniony Sztab**:
///    - Szczegółowa lista zatrudnionych Dyrektorów Sportowych, Trenerów Przygotowania Fizycznego,
///      Lekarzy Klubowych, Głównych Mechaników i Skautów.
///    - Prezentacja atrybutów, miesięcznych pensji, morale, kontraktów i unikalnych cech.
///    - Możliwość przedłużania kontraktów oraz rozwiązywania umów.
/// 2. **Rynek Wolnych Specjalistów (Free Agent Staff Market)**:
///    - Przegląd dostępnych na rynku specjalistów z filtrowaniem wg ról i sortowaniem.
///    - Opcja negocjacji i zatrudnienia kandydata z pobraniem premii za podpisanie (Signing Bonus)
///      oraz weryfikacją budżetu klubowego.
/// 3. **Grupy Treningowe (Coach-to-Rider Assignments)**:
///    - Podział kadry kolarzy na dedykowane grupy 4–5 osobowe (np. Górale GC, Pociąg Sprinterski,
///      Czasowcy Aero, Młodzieżowcy).
///    - Przypisywanie konkretnego Trenera Przygotowania Fizycznego do grupy.
///    - Dynamiczne wyliczanie synergii specjalizacji trenera z kolarzami i bonusu rozwoju (+10% do +20% FTP).
/// 4. **Wóz Techniczny na Wyścig (Race DS Selection)**:
///    - Wybór docelowego wyścigu z kalendarza UCI.
///    - Przypisanie Głównego Dyrektora Sportowego (Wóz #1) oraz Drugiego Dyrektora (Wóz #2).
///    - Podgląd taktyki: kalkulacja szybkości wymiany roweru (pit-stop), bonus morale z porannej
///      odprawy w autobusie oraz filozofia taktyczna wozu.
class StaffManagementScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final bool showAppBar;

  const StaffManagementScreen({
    super.key,
    this.initialTab = 0,
    this.showAppBar = true,
  });

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filtr ról w zakładce aktualnego sztabu
  StaffRole? _rosterRoleFilter;
  final TextEditingController _rosterSearchController = TextEditingController();

  // Filtr ról i sortowanie na rynku wolnych agentów
  StaffRole? _marketRoleFilter;
  String _marketSortMode = 'level_desc'; // 'level_desc', 'salary_asc', 'reputation_desc'
  final TextEditingController _marketSearchController = TextEditingController();

  // Stan kadry sztabu, kolarzy, rynku i budżetu
  late FullTeamStaffRoster _roster;
  late List<StaffMember> _freeAgentMarket;
  late List<TrainingGroup> _trainingGroups;
  late List<Rider> _teamRiders;
  late int _cashBalanceEur;

  // Obsada wozów technicznych na wyścig
  String _selectedRaceId = 'tour_de_france_2026';
  String _selectedRaceName = 'Tour de France 2026';
  String? _selectedLeadDirectorId;
  String? _selectedSupportDirectorId;

  // Kalendarz dostępnych wyścigów
  final List<(String id, String name, String category)> _availableRaces = [
    ('tour_de_france_2026', 'Tour de France 2026', 'Grand Tour (21 etapów)'),
    ('giro_d_italia_2026', 'Giro d\'Italia 2026', 'Grand Tour (21 etapów)'),
    ('vuelta_a_espana_2026', 'Vuelta a España 2026', 'Grand Tour (21 etapów)'),
    ('paris_roubaix_2026', 'Paris - Roubaix 2026', 'Monument (Piekło Północy)'),
    ('ronde_van_vlaanderen_2026', 'Ronde van Vlaanderen 2026', 'Monument (Bruki Flandrii)'),
    ('milan_san_remo_2026', 'Milano - Sanremo 2026', 'Monument (La Classicissima)'),
    ('liege_bastogne_liege_2026', 'Liège - Bastogne - Liège 2026', 'Monument (La Doyenne)'),
    ('criterium_du_dauphine_2026', 'Critérium du Dauphiné 2026', 'WorldTour etapówka'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rosterSearchController.dispose();
    _marketSearchController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final careerState = ref.read(careerControllerProvider);
    final save = careerState.save;

    if (save != null) {
      _cashBalanceEur = save.playerTeam.cashBalanceEur;
      final playerTeam = save.playerTeam;

      // Kolarze drużyny
      final teamRiderIds = playerTeam.rosterRiderIds;
      _teamRiders = save.riders.where((r) => teamRiderIds.contains(r.id)).toList();
      if (_teamRiders.isEmpty) {
        _teamRiders = _generateDemoRiders();
      }

      // Sztab gracza
      _roster = StaffProceduralGenerator.generateDefaultTeamStaffRoster(
        division: playerTeam.division,
        teamCountryIso: playerTeam.countryIso,
      );

      // Grupy treningowe
      _trainingGroups = StaffProceduralGenerator.generateDefaultTrainingGroups(
        availableCoaches: _roster.coaches,
        availableRiders: _teamRiders,
      );
    } else {
      _cashBalanceEur = 1450000;
      _teamRiders = _generateDemoRiders();
      _roster = StaffProceduralGenerator.generateDefaultTeamStaffRoster(
        division: TeamDivision.worldTour,
        teamCountryIso: 'BEL',
        seed: 777,
      );
      _trainingGroups = StaffProceduralGenerator.generateDefaultTrainingGroups(
        availableCoaches: _roster.coaches,
        availableRiders: _teamRiders,
      );
    }

    // Pula wolnych agentów
    _freeAgentMarket = StaffProceduralGenerator.generateFreeAgentMarketPool(
      countPerRole: 3,
      seed: 999,
    );

    // Domyślny wybór DS dla wyścigu
    if (_roster.sportsDirectors.isNotEmpty) {
      _selectedLeadDirectorId = _roster.sportsDirectors.first.id;
      if (_roster.sportsDirectors.length > 1) {
        _selectedSupportDirectorId = _roster.sportsDirectors[1].id;
      }
    }
  }

  List<Rider> _generateDemoRiders() {
    return [
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 92,
      ).copyWith(id: 'r_01', firstName: 'Tadej', lastName: 'Pogačar'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureClimber,
        targetOverallRating: 90,
      ).copyWith(id: 'r_02', firstName: 'Jonas', lastName: 'Vingegaard'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.puncher,
        targetOverallRating: 88,
      ).copyWith(id: 'r_03', firstName: 'Remco', lastName: 'Evenepoel'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 85,
      ).copyWith(id: 'r_04', firstName: 'Enric', lastName: 'Mas'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
        targetOverallRating: 89,
      ).copyWith(id: 'r_05', firstName: 'Jasper', lastName: 'Philipsen'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
        targetOverallRating: 87,
      ).copyWith(id: 'r_06', firstName: 'Tim', lastName: 'Merlier'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.versatileSprinter,
        targetOverallRating: 86,
      ).copyWith(id: 'r_07', firstName: 'Dylan', lastName: 'Groenewegen'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.versatileSprinter,
        targetOverallRating: 85,
      ).copyWith(id: 'r_08', firstName: 'Olav', lastName: 'Kooij'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        targetOverallRating: 89,
      ).copyWith(id: 'r_09', firstName: 'Filippo', lastName: 'Ganna'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        targetOverallRating: 86,
      ).copyWith(id: 'r_10', firstName: 'Stefan', lastName: 'Küng'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.classicCobbles,
        targetOverallRating: 91,
      ).copyWith(id: 'r_11', firstName: 'Wout', lastName: 'van Aert'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        targetOverallRating: 84,
      ).copyWith(id: 'r_12', firstName: 'Joshua', lastName: 'Tarling'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.domestiqueEngine,
        targetOverallRating: 82,
      ).copyWith(id: 'r_13', firstName: 'Michał', lastName: 'Kwiatkowski'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.puncher,
        targetOverallRating: 84,
      ).copyWith(id: 'r_14', firstName: 'Tom', lastName: 'Pidcock'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.breakawaySpecialist,
        targetOverallRating: 80,
      ).copyWith(id: 'r_15', firstName: 'Thibau', lastName: 'Nys'),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 81,
      ).copyWith(id: 'r_16', firstName: 'Isaac', lastName: 'Del Toro'),
    ];
  }

  // ===========================================================================
  // BUILD SCREEN
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: widget.showAppBar ? _buildAppBar() : null,
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmployedStaffTab(),
                  _buildMarketTab(),
                  _buildTrainingGroupsTab(),
                  _buildRaceCarTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cyanAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.cyanAccent.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: AppColors.cyanAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SZTAB SZKOLENIOWY & ZARZĄDZANIE',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Dyrektorzy, Trenerzy, Lekarze, Mechanicy, Skauci i Wóz Techniczny',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.goldAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '€${_formatMoney(_cashBalanceEur)}',
                    style: const TextStyle(
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppColors.cyanAccent,
        indicatorWeight: 3,
        labelColor: AppColors.cyanAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.people_alt_rounded, size: 18),
            text: 'Zatrudniony Sztab',
          ),
          Tab(
            icon: Icon(Icons.storefront_rounded, size: 18),
            text: 'Rynek Wolnych Specjalistów',
          ),
          Tab(
            icon: Icon(Icons.fitness_center_rounded, size: 18),
            text: 'Grupy Treningowe (Opieka)',
          ),
          Tab(
            icon: Icon(Icons.directions_car_filled_rounded, size: 18),
            text: 'Wóz Techniczny na Wyścig',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: ZATRUDNIONY SZTAB (EMPLOYED STAFF)
  // ===========================================================================

  Widget _buildEmployedStaffTab() {
    final query = _rosterSearchController.text.trim().toLowerCase();
    final allMembers = _roster.allMembers.where((m) {
      if (_rosterRoleFilter != null && m.role != _rosterRoleFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = m.fullName.toLowerCase().contains(query);
        final matchesRole = m.role.displayName.toLowerCase().contains(query);
        return matchesName || matchesRole;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRosterKpiBanner(),
          const SizedBox(height: 16),
          _buildRosterFilterBar(),
          const SizedBox(height: 16),
          if (allMembers.isEmpty)
            _buildEmptyState(
              icon: Icons.person_off_rounded,
              title: 'Brak pracowników spełniających kryteria',
              subtitle: 'Zmień filtr lub zatrudnij nowych specjalistów z rynku pracy.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allMembers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = allMembers[index];
                return _buildStaffMemberCard(member);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRosterKpiBanner() {
    final teamStaff = _roster.toTeamStaff();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    color: AppColors.cyanAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Podsumowanie Kadr Sztabu',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Średnia ocena: ${teamStaff.averageStaffLevel.toStringAsFixed(1)}/100',
                  style: const TextStyle(
                    color: AppColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildKpiChip(
                label: 'Zatrudnionych',
                value: '${_roster.allMembers.length} osób',
                icon: Icons.person_rounded,
                color: AppColors.accentBlue,
              ),
              _buildKpiChip(
                label: 'Miesięczne Pensje',
                value: '€${_formatMoney(_roster.totalMonthlySalariesEur)}',
                icon: Icons.payments_rounded,
                color: AppColors.goldAccent,
              ),
              _buildKpiChip(
                label: 'Dyrektorzy Sportowi',
                value: '${_roster.sportsDirectors.length} (Ocena: ${teamStaff.sportsDirectorsLevel})',
                icon: Icons.directions_car_rounded,
                color: AppColors.cyanAccent,
              ),
              _buildKpiChip(
                label: 'Trenerzy Przygotowania',
                value: '${_roster.coaches.length} (Ocena: ${teamStaff.trainersLevel})',
                icon: Icons.fitness_center_rounded,
                color: AppColors.emeraldGreen,
              ),
              _buildKpiChip(
                label: 'Lekarze Klubowi',
                value: '${_roster.doctors.length} (Ocena: ${teamStaff.doctorsLevel})',
                icon: Icons.medical_services_rounded,
                color: const Color(0xFFF43F5E),
              ),
              _buildKpiChip(
                label: 'Mechanicy & Skauci',
                value: '${_roster.mechanics.length} mech. | ${_roster.scouts.length} skaut.',
                icon: Icons.build_rounded,
                color: AppColors.amberWarning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRosterFilterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wyszukiwarka
        TextField(
          controller: _rosterSearchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Szukaj po nazwisku lub roli...',
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
            suffixIcon: _rosterSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                    onPressed: () {
                      _rosterSearchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.cardSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cyanAccent),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Filtr ról
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRoleFilterChip(
                label: 'Wszyscy (${_roster.allMembers.length})',
                isSelected: _rosterRoleFilter == null,
                onTap: () => setState(() => _rosterRoleFilter = null),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Dyrektorzy (${_roster.sportsDirectors.length})',
                isSelected: _rosterRoleFilter == StaffRole.sportsDirector,
                onTap: () => setState(() => _rosterRoleFilter = StaffRole.sportsDirector),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Trenerzy (${_roster.coaches.length})',
                isSelected: _rosterRoleFilter == StaffRole.performanceCoach,
                onTap: () => setState(() => _rosterRoleFilter = StaffRole.performanceCoach),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Lekarze (${_roster.doctors.length})',
                isSelected: _rosterRoleFilter == StaffRole.teamDoctor,
                onTap: () => setState(() => _rosterRoleFilter = StaffRole.teamDoctor),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Mechanicy (${_roster.mechanics.length})',
                isSelected: _rosterRoleFilter == StaffRole.headMechanic,
                onTap: () => setState(() => _rosterRoleFilter = StaffRole.headMechanic),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Skauci (${_roster.scouts.length})',
                isSelected: _rosterRoleFilter == StaffRole.scout,
                onTap: () => setState(() => _rosterRoleFilter = StaffRole.scout),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      selectedColor: AppColors.cyanAccent,
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildStaffMemberCard(StaffMember member) {
    final roleColor = _getRoleColor(member.role);
    final roleIcon = _getRoleIcon(member.role);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header karty
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: roleColor.withValues(alpha: 0.2),
                  child: Icon(roleIcon, color: roleColor, size: 20),
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
                              member.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildCountryBadge(member.nationalityIso),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${member.role.displayName} • Wiek: ${member.age} lat',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.goldAccent),
                      const SizedBox(width: 4),
                      Text(
                        '${member.experienceLevel}/100',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Podstawowe dane kontraktowe
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        label: 'Wynagrodzenie',
                        value: '€${_formatMoney(member.monthlySalaryEur)} / mies.',
                        icon: Icons.payments_rounded,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        label: 'Wygasa w',
                        value: 'Koniec ${member.contractEndYear} r.',
                        icon: Icons.event_rounded,
                        color: AppColors.cyanAccent,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        label: 'Morale',
                        value: '${member.morale.toStringAsFixed(0)}%',
                        icon: Icons.sentiment_very_satisfied_rounded,
                        color: member.morale >= 80
                            ? AppColors.emeraldGreen
                            : (member.morale >= 60
                                ? AppColors.amberWarning
                                : AppColors.crimsonAlert),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.cardBorder, height: 1),
                const SizedBox(height: 12),

                // Specjalistyczne statystyki w zależności od roli
                _buildRoleSpecificDetails(member),

                // Cechy unikalne (Special traits)
                if (member.specialTraits.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: member.specialTraits.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 12, color: AppColors.goldAccent),
                            const SizedBox(width: 4),
                            Text(
                              t,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),
                // Przyciski akcji (Przedłuż kontrakt / Zwolnij)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.crimsonAlert,
                        side: const BorderSide(color: AppColors.crimsonAlert),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _confirmFireMember(member),
                      icon: const Icon(Icons.person_remove_rounded, size: 16),
                      label: const Text('Zwolnij', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => _extendContract(member),
                      icon: const Icon(Icons.update_rounded, size: 16),
                      label: const Text('Przedłuż (+1 rok)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificDetails(StaffMember member) {
    if (member is SportsDirector) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Jazda w kolumnie aut',
                  value: member.convoyCarDrivingSkill,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Zmysł taktyczny AI',
                  value: member.tacticalAiInsight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Charyzma na odprawie',
                  value: member.preRaceBriefingCharisma,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Łączność radiowa',
                  value: member.radioCommunicationClarity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, size: 14, color: AppColors.cyanAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Filozofia: ${member.tacticalPhilosophy.displayName}',
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Pit-stop: ${member.calculateBikeSwapTimeSeconds().toStringAsFixed(1)}s',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (member is PerformanceCoach) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Efektywność FTP (+${((member.ftpProgressionMultiplier - 1.0) * 100).toStringAsFixed(1)}%)',
                  value: member.ftpDevelopmentEfficiency,
                  progressColor: AppColors.emeraldGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Trening sprintu (+${member.calculateSprintBonusWatts(1400)}W)',
                  value: member.sprintAndNeuromuscularFocus,
                  progressColor: AppColors.amberWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Periodyzacja siłowni',
                  value: member.winterGymPeriodizationSkill,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Prewencja przetrenowania',
                  value: member.overtrainingPrevention,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, size: 14, color: AppColors.emeraldGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Specjalizacja: ${member.specialization.displayName}',
                    style: const TextStyle(
                      color: AppColors.emeraldGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (member is TeamDoctor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Diagnostyka krwi & Hct',
                  value: member.bloodDiagnosticsSkill,
                  progressColor: const Color(0xFFF43F5E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Zrost złamań (-${member.calculateFractureDaysReduction(28)} dni)',
                  value: member.fractureAndOrthopedicRehabSpeed,
                  progressColor: AppColors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Prewencja infekcji',
                  value: member.infectionPreventionAndHygiene,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Leczenie szlifów & ran',
                  value: member.woundHealingCare,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_rounded, size: 14, color: Color(0xFFF43F5E)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Klinika: ${member.medicalSpecialization.displayName}',
                    style: const TextStyle(
                      color: Color(0xFFF43F5E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (member is HeadMechanic) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Niezawodność napędu (${(member.mechanicalFailureRateMultiplier * 100).toStringAsFixed(0)}% def.)',
                  value: member.drivetrainReliabilitySkill,
                  progressColor: AppColors.amberWarning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Opony & Tubeless (-${member.punctureRiskReductionPercent.toStringAsFixed(0)}% kapcia)',
                  value: member.tubelessAndTireMastery,
                  progressColor: AppColors.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Woskowanie na gorąco (+${member.chainWaxWattageSavings.toStringAsFixed(1)}W)',
                  value: member.chainWaxingExpertise,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Centrowanie kół',
                  value: member.wheelTruingPrecision,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, size: 14, color: AppColors.amberWarning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Średni czas serwisu roweru: ${member.serviceTimeMinutesPerBike} minut',
                    style: const TextStyle(
                      color: AppColors.amberWarning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (member is Scout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Odkrywanie talentów U23',
                  value: member.talentDiscoveryRating,
                  progressColor: const Color(0xFFA855F7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatProgress(
                  label: 'Precyzja oceny (błąd: ±${member.potentialEstimationMargin})',
                  value: member.evaluationPrecision,
                  progressColor: AppColors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatProgress(
                  label: 'Siatka kontaktów',
                  value: member.networkReach,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  label: 'Profil',
                  value: member.specialtyFocus.displayName,
                  icon: Icons.track_changes_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, size: 14, color: Color(0xFFA855F7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Region: ${member.assignedRegion.displayName}',
                    style: const TextStyle(
                      color: Color(0xFFA855F7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatProgress({
    required String label,
    required int value,
    Color progressColor = AppColors.cyanAccent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$value/100',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / 100.0).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: RYNEK WOLNYCH SPECJALISTÓW (FREE AGENT MARKET)
  // ===========================================================================

  Widget _buildMarketTab() {
    final query = _marketSearchController.text.trim().toLowerCase();
    List<StaffMember> filtered = _freeAgentMarket.where((m) {
      if (_marketRoleFilter != null && m.role != _marketRoleFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        return m.fullName.toLowerCase().contains(query) ||
            m.role.displayName.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Sortowanie
    if (_marketSortMode == 'level_desc') {
      filtered.sort((a, b) => b.experienceLevel.compareTo(a.experienceLevel));
    } else if (_marketSortMode == 'salary_asc') {
      filtered.sort((a, b) => a.monthlySalaryEur.compareTo(b.monthlySalaryEur));
    } else if (_marketSortMode == 'reputation_desc') {
      filtered.sort((a, b) => b.reputation.compareTo(a.reputation));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMarketHeaderBanner(),
          const SizedBox(height: 16),
          _buildMarketFilterAndSortBar(),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _buildEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Brak wolnych specjalistów',
              subtitle: 'Spróbuj zresetować filtry wyszukiwania.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final candidate = filtered[index];
                return _buildCandidateCard(candidate);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMarketHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.work_history_rounded,
              color: AppColors.goldAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rynek Wolnych Trenerów i Dyrektorów',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Zatrudniaj wybitnych fachowców z wolnego rynku. Podpisanie kontraktu wiąże się z jednorazową premią powitalną (Signing Bonus).',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Dostępny Budżet',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
                Text(
                  '€${_formatMoney(_cashBalanceEur)}',
                  style: const TextStyle(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketFilterAndSortBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _marketSearchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Szukaj kandydata na rynku...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  suffixIcon: _marketSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            _marketSearchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cyanAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _marketSortMode,
                  dropdownColor: AppColors.cardSurface,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  icon: const Icon(Icons.sort_rounded, color: AppColors.cyanAccent, size: 18),
                  items: const [
                    DropdownMenuItem(value: 'level_desc', child: Text('Najwyższe doświadczenie')),
                    DropdownMenuItem(value: 'salary_asc', child: Text('Najniższa pensja')),
                    DropdownMenuItem(value: 'reputation_desc', child: Text('Najwyższa renoma')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _marketSortMode = val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRoleFilterChip(
                label: 'Wszyscy Kandydaci (${_freeAgentMarket.length})',
                isSelected: _marketRoleFilter == null,
                onTap: () => setState(() => _marketRoleFilter = null),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Dyrektorzy Sportowi',
                isSelected: _marketRoleFilter == StaffRole.sportsDirector,
                onTap: () => setState(() => _marketRoleFilter = StaffRole.sportsDirector),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Trenerzy Przygotowania',
                isSelected: _marketRoleFilter == StaffRole.performanceCoach,
                onTap: () => setState(() => _marketRoleFilter = StaffRole.performanceCoach),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Lekarze Klubowi',
                isSelected: _marketRoleFilter == StaffRole.teamDoctor,
                onTap: () => setState(() => _marketRoleFilter = StaffRole.teamDoctor),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Główni Mechanicy',
                isSelected: _marketRoleFilter == StaffRole.headMechanic,
                onTap: () => setState(() => _marketRoleFilter = StaffRole.headMechanic),
              ),
              const SizedBox(width: 8),
              _buildRoleFilterChip(
                label: 'Skauci Talentów',
                isSelected: _marketRoleFilter == StaffRole.scout,
                onTap: () => setState(() => _marketRoleFilter = StaffRole.scout),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateCard(StaffMember candidate) {
    final roleColor = _getRoleColor(candidate.role);
    final roleIcon = _getRoleIcon(candidate.role);
    final signingCost = candidate.signingBonusEur;
    final canAfford = _cashBalanceEur >= signingCost;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: roleColor.withValues(alpha: 0.2),
                  child: Icon(roleIcon, color: roleColor, size: 20),
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
                              candidate.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildCountryBadge(candidate.nationalityIso),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${candidate.role.displayName} • Wiek: ${candidate.age} lat',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.goldAccent),
                      const SizedBox(width: 4),
                      Text(
                        'Ocena: ${candidate.experienceLevel}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleSpecificDetails(candidate),
                const SizedBox(height: 14),
                const Divider(color: AppColors.cardBorder, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Pensja: ',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              Flexible(
                                child: Text(
                                  '€${_formatMoney(candidate.monthlySalaryEur)} / mies.',
                                  style: const TextStyle(
                                    color: AppColors.goldAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text(
                                'Premia za podpis: ',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              Flexible(
                                child: Text(
                                  '€${_formatMoney(signingCost)}',
                                  style: TextStyle(
                                    color: canAfford ? AppColors.textPrimary : AppColors.crimsonAlert,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? AppColors.emeraldGreen : AppColors.surface,
                        foregroundColor: canAfford ? Colors.black : AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: canAfford ? () => _showHireDialog(candidate) : null,
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: Text(
                        canAfford ? 'Zatrudnij' : 'Brak funduszy',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHireDialog(StaffMember candidate) {
    int contractYears = 2;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final signingCost = candidate.signingBonusEur;
            final canAfford = _cashBalanceEur >= signingCost;

            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              title: const Row(
                children: [
                  Icon(Icons.handshake_rounded, color: AppColors.emeraldGreen, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Zatrudnienie Specjalisty',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Czy na pewno chcesz zatrudnić ${candidate.fullName} na stanowisko ${candidate.role.displayName}?',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildDialogRow('Doświadczenie i poziom:', '${candidate.experienceLevel}/100'),
                          const SizedBox(height: 6),
                          _buildDialogRow('Miesięczna pensja:', '€${_formatMoney(candidate.monthlySalaryEur)}'),
                          const SizedBox(height: 6),
                          _buildDialogRow('Premia powitalna (Signing Fee):', '€${_formatMoney(signingCost)}', highlight: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Długość kontraktu:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [1, 2, 3].map((years) {
                        final isSel = contractYears == years;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => setDialogState(() => contractYears = years),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.cyanAccent : AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel ? AppColors.cyanAccent : AppColors.cardBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$years ${years == 1 ? 'rok' : 'lata'}',
                                  style: TextStyle(
                                    color: isSel ? Colors.black : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kasa klubu po transakcji: €${_formatMoney(_cashBalanceEur - signingCost)}',
                      style: TextStyle(
                        color: canAfford ? AppColors.goldAccent : AppColors.crimsonAlert,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Anuluj', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: canAfford
                      ? () {
                          Navigator.of(ctx).pop();
                          _executeHire(candidate, contractYears);
                        }
                      : null,
                  child: const Text('Podpisz Kontrakt', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _executeHire(StaffMember candidate, int contractYears) {
    final signingCost = candidate.signingBonusEur;
    final endYear = 2026 + contractYears;

    StaffMember hiredMember;
    if (candidate is SportsDirector) {
      hiredMember = candidate.copyWith(contractEndYear: endYear);
    } else if (candidate is PerformanceCoach) {
      hiredMember = candidate.copyWith(contractEndYear: endYear);
    } else if (candidate is TeamDoctor) {
      hiredMember = candidate.copyWith(contractEndYear: endYear);
    } else if (candidate is HeadMechanic) {
      hiredMember = candidate.copyWith(contractEndYear: endYear);
    } else if (candidate is Scout) {
      hiredMember = candidate.copyWith(contractEndYear: endYear);
    } else {
      hiredMember = candidate;
    }

    setState(() {
      _cashBalanceEur -= signingCost;
      _freeAgentMarket.removeWhere((m) => m.id == candidate.id);

      switch (hiredMember.role) {
        case StaffRole.sportsDirector:
          _roster = _roster.copyWith(
            sportsDirectors: [..._roster.sportsDirectors, hiredMember as SportsDirector],
          );
          break;
        case StaffRole.performanceCoach:
          _roster = _roster.copyWith(
            coaches: [..._roster.coaches, hiredMember as PerformanceCoach],
          );
          break;
        case StaffRole.teamDoctor:
          _roster = _roster.copyWith(
            doctors: [..._roster.doctors, hiredMember as TeamDoctor],
          );
          break;
        case StaffRole.headMechanic:
          _roster = _roster.copyWith(
            mechanics: [..._roster.mechanics, hiredMember as HeadMechanic],
          );
          break;
        case StaffRole.scout:
          _roster = _roster.copyWith(
            scouts: [..._roster.scouts, hiredMember as Scout],
          );
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Zatrudniono: ${hiredMember.fullName} (${hiredMember.role.displayName}) na $contractYears lata!',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmFireMember(StaffMember member) {
    final severanceEur = member.monthlySalaryEur;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.crimsonAlert, size: 24),
              SizedBox(width: 8),
              Text(
                'Rozwiązanie Kontraktu',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Czy na pewno chcesz zwolnić ${member.fullName}?\n\n'
            'Odprawa wynosi 1-miesięczne wynagrodzenie (€${_formatMoney(severanceEur)}).',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Anuluj', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimsonAlert,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _executeFire(member, severanceEur);
              },
              child: const Text('Zwolnij Specjalistę'),
            ),
          ],
        );
      },
    );
  }

  void _executeFire(StaffMember member, int severanceEur) {
    setState(() {
      _cashBalanceEur = math.max(0, _cashBalanceEur - severanceEur);

      switch (member.role) {
        case StaffRole.sportsDirector:
          final updated = _roster.sportsDirectors.where((m) => m.id != member.id).toList();
          _roster = _roster.copyWith(sportsDirectors: updated);
          if (_selectedLeadDirectorId == member.id) {
            _selectedLeadDirectorId = updated.isNotEmpty ? updated.first.id : null;
          }
          if (_selectedSupportDirectorId == member.id) {
            _selectedSupportDirectorId = updated.length > 1 ? updated[1].id : null;
          }
          break;
        case StaffRole.performanceCoach:
          final updated = _roster.coaches.where((m) => m.id != member.id).toList();
          _roster = _roster.copyWith(coaches: updated);
          // Usunięcie trenera z przypisanych grup
          _trainingGroups = _trainingGroups.map((g) {
            if (g.assignedCoachId == member.id) {
              return g.copyWith(clearCoach: true);
            }
            return g;
          }).toList();
          break;
        case StaffRole.teamDoctor:
          _roster = _roster.copyWith(
            doctors: _roster.doctors.where((m) => m.id != member.id).toList(),
          );
          break;
        case StaffRole.headMechanic:
          _roster = _roster.copyWith(
            mechanics: _roster.mechanics.where((m) => m.id != member.id).toList(),
          );
          break;
        case StaffRole.scout:
          _roster = _roster.copyWith(
            scouts: _roster.scouts.where((m) => m.id != member.id).toList(),
          );
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(
          'Rozwiązano kontrakt z: ${member.fullName}. Wypłacono odprawę €${_formatMoney(severanceEur)}.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  void _extendContract(StaffMember member) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.update_rounded, color: AppColors.cyanAccent, size: 24),
              SizedBox(width: 8),
              Text('Przedłużenie Kontraktu', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            ],
          ),
          content: Text(
            'Przedłużyć kontrakt dla ${member.fullName} o kolejny 1 rok (do końca ${member.contractEndYear + 1} r.)?\n\n'
            'Podwyżka lojalnościowa: +5% do miesięcznej pensji.',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Anuluj', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyanAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  final newEndYear = member.contractEndYear + 1;
                  final newSalary = (member.monthlySalaryEur * 1.05).round();

                  StaffMember updated;
                  if (member is SportsDirector) {
                    updated = member.copyWith(contractEndYear: newEndYear, monthlySalaryEur: newSalary, morale: (member.morale + 5).clamp(0, 100));
                    _roster = _roster.copyWith(
                      sportsDirectors: _roster.sportsDirectors.map((m) => m.id == member.id ? updated as SportsDirector : m).toList(),
                    );
                  } else if (member is PerformanceCoach) {
                    updated = member.copyWith(contractEndYear: newEndYear, monthlySalaryEur: newSalary, morale: (member.morale + 5).clamp(0, 100));
                    _roster = _roster.copyWith(
                      coaches: _roster.coaches.map((m) => m.id == member.id ? updated as PerformanceCoach : m).toList(),
                    );
                  } else if (member is TeamDoctor) {
                    updated = member.copyWith(contractEndYear: newEndYear, monthlySalaryEur: newSalary, morale: (member.morale + 5).clamp(0, 100));
                    _roster = _roster.copyWith(
                      doctors: _roster.doctors.map((m) => m.id == member.id ? updated as TeamDoctor : m).toList(),
                    );
                  } else if (member is HeadMechanic) {
                    updated = member.copyWith(contractEndYear: newEndYear, monthlySalaryEur: newSalary, morale: (member.morale + 5).clamp(0, 100));
                    _roster = _roster.copyWith(
                      mechanics: _roster.mechanics.map((m) => m.id == member.id ? updated as HeadMechanic : m).toList(),
                    );
                  } else if (member is Scout) {
                    updated = member.copyWith(contractEndYear: newEndYear, monthlySalaryEur: newSalary, morale: (member.morale + 5).clamp(0, 100));
                    _roster = _roster.copyWith(
                      scouts: _roster.scouts.map((m) => m.id == member.id ? updated as Scout : m).toList(),
                    );
                  }
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text(
                      'Kontrakt ${member.fullName} przedłużony do końca ${member.contractEndYear + 1} roku!',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                );
              },
              child: const Text('Zatwierdź', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: GRUPY TRENINGOWE (COACH-TO-RIDER ASSIGNMENT)
  // ===========================================================================

  Widget _buildTrainingGroupsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrainingGroupsBanner(),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _trainingGroups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final group = _trainingGroups[index];
              return _buildTrainingGroupCard(group);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingGroupsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.emeraldGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Podział na Grupy Treningowe (4–5 Kolarzy)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Przypisuj trenerów przygotowania motorycznego do grup. Synergia specjalizacji z profilem kolarzy zapewnia do +20% szybszego rozwoju FTP, VO2max i watów w sprincie.',
                  style: TextStyle(
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

  Widget _buildTrainingGroupCard(TrainingGroup group) {
    PerformanceCoach? assignedCoach;
    if (group.assignedCoachId != null) {
      for (final c in _roster.coaches) {
        if (c.id == group.assignedCoachId) {
          assignedCoach = c;
          break;
        }
      }
    }

    final groupRiders = _teamRiders.where((r) => group.assignedRiderIds.contains(r.id)).toList();
    final synergyPercent = group.calculateSynergyBonusPercent(assignedCoach, groupRiders);
    final synergyRatio = group.calculateSynergyRatio(assignedCoach, groupRiders);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header grupy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getGroupIcon(group.focusSpecialization),
                  color: AppColors.emeraldGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        group.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    '${groupRiders.length} / 5 kolarzy',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trener prowadzący
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trener Prowadzący:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.cyanAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onPressed: () => _showCoachSelectionDialog(group),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      label: Text(
                        assignedCoach != null ? 'Zmień Trenera' : 'Przypisz Trenera',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (assignedCoach != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.emeraldGreen.withValues(alpha: 0.2),
                          child: const Icon(Icons.fitness_center_rounded, color: AppColors.emeraldGreen, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignedCoach.fullName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${assignedCoach.specialization.displayName} • Ocena: ${assignedCoach.experienceLevel}/100',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${((assignedCoach.ftpProgressionMultiplier - 1.0) * 100).toStringAsFixed(1)}% FTP',
                            style: const TextStyle(
                              color: AppColors.emeraldGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.amberWarning, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Brak przypisanego trenera – grupa trenuje bez indywidualnego wsparcia (0% synergii).',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                // Wskaźnik synergii
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.hub_rounded, size: 14, color: AppColors.goldAccent),
                              SizedBox(width: 6),
                              Text(
                                'Synergia Grupy Treningowej:',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '+$synergyPercent% Rozwoju',
                            style: const TextStyle(
                              color: AppColors.goldAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: synergyRatio,
                          minHeight: 6,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Lista kolarzy w grupie
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Przypisani Kolarze (4–5):',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (groupRiders.length < 5)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.emeraldGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: () => _showAddRiderToGroupDialog(group),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Dodaj Kolarza', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (groupRiders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Brak kolarzy w tej grupie. Dodaj do 5 zawodników.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: groupRiders.map((r) {
                      final isMatch = assignedCoach != null &&
                          TrainingGroup.isSynergistic(assignedCoach.specialization, r.specialization);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isMatch ? AppColors.emeraldGreen.withValues(alpha: 0.4) : AppColors.cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              r.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                r.specialization.displayName,
                                style: TextStyle(
                                  color: isMatch ? AppColors.emeraldGreen : AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _removeRiderFromGroup(group, r.id),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: AppColors.crimsonAlert,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCoachSelectionDialog(TrainingGroup group) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Text('Wybierz Trenera Prowadzącego', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: SizedBox(
            width: 400,
            child: _roster.coaches.isEmpty
                ? const Text(
                    'Brak zatrudnionych trenerów przygotowania fizycznego! Przejdź do zakładki rynku i zatrudnij trenera.',
                    style: TextStyle(color: AppColors.crimsonAlert, fontSize: 13),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _roster.coaches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final coach = _roster.coaches[idx];
                      final isSelected = coach.id == group.assignedCoachId;
                      return InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          setState(() {
                            _trainingGroups = _trainingGroups.map((g) {
                              if (g.id == group.id) {
                                return g.copyWith(assignedCoachId: coach.id);
                              }
                              return g;
                            }).toList();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.cyanAccent.withValues(alpha: 0.15) : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.emeraldGreen.withValues(alpha: 0.2),
                                child: const Icon(Icons.fitness_center_rounded, color: AppColors.emeraldGreen, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      coach.fullName,
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      '${coach.specialization.displayName} • Ocena: ${coach.experienceLevel}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.cyanAccent, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Anuluj', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  void _showAddRiderToGroupDialog(TrainingGroup group) {
    final unassignedOrOtherRiders = _teamRiders.where((r) => !group.assignedRiderIds.contains(r.id)).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            'Dodaj Kolarza do: ${group.name}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 420,
            height: 380,
            child: ListView.separated(
              itemCount: unassignedOrOtherRiders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final rider = unassignedOrOtherRiders[idx];
                final isSynergic = TrainingGroup.isSynergistic(group.focusSpecialization, rider.specialization);

                return InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _addRiderToGroup(group, rider.id);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSynergic ? AppColors.emeraldGreen.withValues(alpha: 0.4) : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.surfaceLight,
                          child: Text(
                            rider.firstName.isNotEmpty ? rider.firstName[0] : 'K',
                            style: const TextStyle(color: AppColors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rider.fullName,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                rider.specialization.displayName,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (isSynergic)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star_rounded, size: 12, color: AppColors.emeraldGreen),
                                SizedBox(width: 2),
                                Text(
                                  'Synergia',
                                  style: TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Zamknij', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  void _addRiderToGroup(TrainingGroup group, String riderId) {
    if (group.assignedRiderIds.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.amberWarning,
          content: Text('Grupa osiągnęła maksymalny limit 5 kolarzy!'),
        ),
      );
      return;
    }

    setState(() {
      _trainingGroups = _trainingGroups.map((g) {
        if (g.id == group.id) {
          return g.copyWith(assignedRiderIds: [...g.assignedRiderIds, riderId]);
        }
        // Usunięcie kolarza z innej grupy, jeśli już w niej był
        return g.copyWith(
          assignedRiderIds: g.assignedRiderIds.where((id) => id != riderId).toList(),
        );
      }).toList();
    });
  }

  void _removeRiderFromGroup(TrainingGroup group, String riderId) {
    setState(() {
      _trainingGroups = _trainingGroups.map((g) {
        if (g.id == group.id) {
          return g.copyWith(
            assignedRiderIds: g.assignedRiderIds.where((id) => id != riderId).toList(),
          );
        }
        return g;
      }).toList();
    });
  }

  // ===========================================================================
  // TAB 4: WÓZ TECHNICZNY NA WYŚCIG (RACE DS SELECTION)
  // ===========================================================================

  Widget _buildRaceCarTab() {
    SportsDirector? leadDirector;
    SportsDirector? supportDirector;

    if (_selectedLeadDirectorId != null) {
      for (final ds in _roster.sportsDirectors) {
        if (ds.id == _selectedLeadDirectorId) {
          leadDirector = ds;
          break;
        }
      }
    }
    if (_selectedSupportDirectorId != null) {
      for (final ds in _roster.sportsDirectors) {
        if (ds.id == _selectedSupportDirectorId) {
          supportDirector = ds;
          break;
        }
      }
    }

    final leadMechanicSkill = _roster.leadMechanic?.experienceLevel ?? 75;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRaceCarBanner(),
          const SizedBox(height: 16),
          // Selektor wyścigu z kalendarza
          _buildRaceSelectorCard(),
          const SizedBox(height: 16),
          // Sekcja Wóz #1 (Główny Dyrektor)
          _buildCarSelectionCard(
            carNumber: 1,
            title: 'WÓZ #1 – GŁÓWNY DYREKTOR SPORTOWY (LEAD DS)',
            subtitle: 'Kieruje taktyką peletonu, poranną odprawą i natychmiastowym pit-stopem ucieczek.',
            selectedDirector: leadDirector,
            allDirectors: _roster.sportsDirectors,
            mechanicSkill: leadMechanicSkill,
            onSelectDirector: (id) => setState(() => _selectedLeadDirectorId = id),
          ),
          const SizedBox(height: 16),
          // Sekcja Wóz #2 (Wsparcie)
          _buildCarSelectionCard(
            carNumber: 2,
            title: 'WÓZ #2 – DRUGI DYREKTOR SPORTOWY (SUPPORT DS)',
            subtitle: 'Asekuracja ogona peletonu, bidony z tyłu stawki i wsparcie kolarzy w kryzysie.',
            selectedDirector: supportDirector,
            allDirectors: _roster.sportsDirectors.where((d) => d.id != _selectedLeadDirectorId).toList(),
            mechanicSkill: leadMechanicSkill,
            onSelectDirector: (id) => setState(() => _selectedSupportDirectorId = id),
          ),
          const SizedBox(height: 16),
          // Symulator porannej odprawy w autobusie
          if (leadDirector != null) _buildBriefingSimulatorCard(leadDirector),
          const SizedBox(height: 20),
          // Przycisk zatwierdzenia obsady wozów
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: leadDirector != null
                  ? () => _saveRaceAssignment(leadDirector!, supportDirector)
                  : null,
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text(
                'Zatwierdź Obsadę Wozów Technicznych',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceCarBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cyanAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.cyanAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wóz Techniczny w Kolumnie Wyścigowej UCI',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Wybierz Dyrektora Sportowego, który poprowadzi wóz nr 1 w kolumnie aut. Umiejętności kierowania wozem i charyzma DS decydują o szybkości wymiany koła i morale kolarzy.',
                  style: TextStyle(
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

  Widget _buildRaceSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: AppColors.goldAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nadchodzący Wyścig Docelowy:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedRaceName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRaceId,
              dropdownColor: AppColors.cardSurface,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.cyanAccent),
              items: _availableRaces.map((r) {
                return DropdownMenuItem(
                  value: r.$1,
                  child: Text('${r.$2} (${r.$3})'),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId != null) {
                  final found = _availableRaces.firstWhere((r) => r.$1 == newId);
                  setState(() {
                    _selectedRaceId = found.$1;
                    _selectedRaceName = found.$2;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarSelectionCard({
    required int carNumber,
    required String title,
    required String subtitle,
    required SportsDirector? selectedDirector,
    required List<SportsDirector> allDirectors,
    required int mechanicSkill,
    required ValueChanged<String?> onSelectDirector,
  }) {
    final double swapTime = selectedDirector != null
        ? selectedDirector.calculateBikeSwapTimeSeconds()
        : 14.0;
    final double moraleBonus = selectedDirector != null
        ? selectedDirector.calculateBriefingMoraleBonus(isQueenStage: true)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: carNumber == 1 ? AppColors.cyanAccent.withValues(alpha: 0.5) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: carNumber == 1 ? AppColors.cyanAccent : AppColors.accentBlue,
                  child: Text(
                    '#$carNumber',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Wybierz Dyrektora: ',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedDirector?.id,
                            hint: const Text('Brak wyboru', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            dropdownColor: AppColors.cardSurface,
                            isExpanded: true,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            items: allDirectors.map((d) {
                              return DropdownMenuItem(
                                value: d.id,
                                child: Text('${d.fullName} (Ocena: ${d.experienceLevel}) • ${d.nationalityIso}'),
                              );
                            }).toList(),
                            onChanged: onSelectDirector,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedDirector != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildRaceStatBox(
                        label: 'Czas wymiany roweru',
                        value: '${swapTime.toStringAsFixed(1)}s',
                        icon: Icons.timer_rounded,
                        color: swapTime < 9.5 ? AppColors.emeraldGreen : AppColors.amberWarning,
                      ),
                      _buildRaceStatBox(
                        label: 'Bonus morale z odprawy',
                        value: '+${moraleBonus.toStringAsFixed(1)} pkt',
                        icon: Icons.record_voice_over_rounded,
                        color: AppColors.goldAccent,
                      ),
                      _buildRaceStatBox(
                        label: 'Manewry w kolumnie aut',
                        value: '${selectedDirector.convoyCarDrivingSkill}/100',
                        icon: Icons.directions_car_rounded,
                        color: AppColors.cyanAccent,
                      ),
                      _buildRaceStatBox(
                        label: 'Zmysł taktyczny AI',
                        value: '${selectedDirector.tacticalAiInsight}/100',
                        icon: Icons.psychology_rounded,
                        color: AppColors.accentBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.goldAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filozofia taktyczna: ${selectedDirector.tacticalPhilosophy.displayName}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBriefingSimulatorCard(SportsDirector director) {
    final speech = _generateBriefingSpeech(director.tacticalPhilosophy, director.fullName);
    final bonus = director.calculateBriefingMoraleBonus(isQueenStage: true);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_rounded, color: AppColors.goldAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Poranna Odprawa w Autobusie Zespołu',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Bonus: +${bonus.toStringAsFixed(1)} Morale',
                  style: const TextStyle(
                    color: AppColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🗣️ ${director.fullName} mówi do kolarzy:',
                  style: const TextStyle(
                    color: AppColors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"$speech"',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _generateBriefingSpeech(DirectorTacticalPhilosophy philosophy, String name) {
    switch (philosophy) {
      case DirectorTacticalPhilosophy.aggressiveAttacking:
        return 'Panowie, od 40. kilometra zaczyna się otwarty teren i silny boczny wiatr! Dzielimy peleton na rantach. Nie czekamy na rywali – od razu pełen gaz w pierwszej grupie!';
      case DirectorTacticalPhilosophy.cautiousDefensive:
        return 'Nasz cel jest prosty: chronimy żółtą koszulkę i unikamy kraks. Trzymamy zwartą grupę na czele peletonu, nikt nie traci energii na zbędne szarpanie tempa.';
      case DirectorTacticalPhilosophy.breakawayGambler:
        return 'Dzisiejszy profil to raj dla ucieczki! Jeśli odjazd zyska ponad 3 minuty, peleton go nie dogoni. Mamy mieć co najmniej dwóch zawodników w odjeździe dnia!';
      case DirectorTacticalPhilosophy.sprinterTrainSpecialist:
        return 'Cała drużyna pracuje dzisiaj na nasz pociąg sprinterski! Na ostatnich 3 kilometrach każdy z was ma oddać wszystkie waty. Wyprowadzamy naszego sprintera na idealną pozycję!';
      case DirectorTacticalPhilosophy.gcCalculator:
        return 'Wspinaczka pod finałowy szczyt wymaga zimnej kalkulacji watów na kilogram. Żadnych gwałtownych zrywów – utrzymujemy docelowe tempo progowe i kontrolujemy rywali!';
    }
  }

  void _saveRaceAssignment(SportsDirector lead, SportsDirector? support) {
    final assignment = RaceDirectorAssignment(
      raceId: _selectedRaceId,
      raceName: _selectedRaceName,
      leadDirectorId: lead.id,
      supportDirectorId: support?.id,
      assignedAt: DateTime.now(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.cyanAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Zatwierdzono wóz #1 (${lead.fullName}) dla wyścigu ${assignment.raceName}!',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDŻETY POMOCNICZE
  // ===========================================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryBadge(String iso) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        iso.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.goldAccent : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  Color _getRoleColor(StaffRole role) {
    switch (role) {
      case StaffRole.sportsDirector:
        return AppColors.cyanAccent;
      case StaffRole.performanceCoach:
        return AppColors.emeraldGreen;
      case StaffRole.teamDoctor:
        return const Color(0xFFF43F5E);
      case StaffRole.headMechanic:
        return AppColors.amberWarning;
      case StaffRole.scout:
        return const Color(0xFFA855F7);
    }
  }

  IconData _getRoleIcon(StaffRole role) {
    switch (role) {
      case StaffRole.sportsDirector:
        return Icons.directions_car_rounded;
      case StaffRole.performanceCoach:
        return Icons.fitness_center_rounded;
      case StaffRole.teamDoctor:
        return Icons.medical_services_rounded;
      case StaffRole.headMechanic:
        return Icons.build_rounded;
      case StaffRole.scout:
        return Icons.search_rounded;
    }
  }

  IconData _getGroupIcon(CoachSpecialization spec) {
    switch (spec) {
      case CoachSpecialization.enduranceAndClimbing:
        return Icons.terrain_rounded;
      case CoachSpecialization.sprintAndExplosiveness:
        return Icons.flash_on_rounded;
      case CoachSpecialization.timeTrialAero:
        return Icons.timer_rounded;
      case CoachSpecialization.allRoundDevelopment:
        return Icons.sports_score_rounded;
    }
  }

  String _formatMoney(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write(' ');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }
}
