import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../state/career_controller.dart';
import '../../state/career_state_notifier.dart';
import '../../state/race_simulation_notifier.dart';
import 'bike_garage_rnd_screen.dart';
import 'career_dashboard_screen.dart';
import 'dashboard_hq_screen.dart';
import 'calendar_and_race_planner_screen.dart';
import 'pre_race_briefing_screen.dart';
import 'sponsors_and_finance_screen.dart';
import 'squad_roster_screen.dart';
import 'training_and_camps_screen.dart';
import 'transfer_market_scouting_screen.dart';

const Color _cyanAccent = Color(0xFF00E5FF);

/// Zakładki nawigacyjne głównego szkieletu gry (MainShellScreen)
enum MainNavigationTab {
  dashboard(
    title: 'Pulpit',
    shortLabel: 'Pulpit',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    description: 'Centrum dowodzenia drużyną',
  ),
  roster(
    title: 'Skład Kolarzy',
    shortLabel: 'Kolarze',
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt_rounded,
    description: 'Kadra, formy i kontrakty',
  ),
  training(
    title: 'Trening & Obozy',
    shortLabel: 'Trening',
    icon: Icons.fitness_center_outlined,
    selectedIcon: Icons.fitness_center_rounded,
    description: 'Wykres PMC, obozy i szczyt formy',
  ),
  calendar(
    title: 'Kalendarz & Wyścigi',
    shortLabel: 'Kalendarz',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    description: 'Harmonogram sezonu i etapy',
  ),
  equipment(
    title: 'Sprzęt & Warsztat',
    shortLabel: 'Sprzęt',
    icon: Icons.pedal_bike_outlined,
    selectedIcon: Icons.pedal_bike_rounded,
    description: 'Rowery, ramy i stożki kół',
  ),
  finances(
    title: 'Finanse & Sponsorzy',
    shortLabel: 'Finanse',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance_rounded,
    description: 'Budżet, premie i bilans',
  ),
  transfers(
    title: 'Transfery & Skauting',
    shortLabel: 'Transfery',
    icon: Icons.person_search_outlined,
    selectedIcon: Icons.person_search_rounded,
    description: 'Rynek, akademia U23 i PDC',
  ),
  inbox(
    title: 'Poczta (Inbox)',
    shortLabel: 'Poczta',
    icon: Icons.mail_outline_rounded,
    selectedIcon: Icons.mail_rounded,
    description: 'Odprawy i raporty medyczne',
  ),
  settings(
    title: 'Zapisy & Mody',
    shortLabel: 'Zapisy',
    icon: Icons.save_outlined,
    selectedIcon: Icons.save_rounded,
    description: 'Sloty 1-5, Auto-Save i mody',
  );

  final String title;
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;
  final String description;

  const MainNavigationTab({
    required this.title,
    required this.shortLabel,
    required this.icon,
    required this.selectedIcon,
    required this.description,
  });
}

/// Responsywny szkielet nawigacyjny gry (MainShellScreen):
/// - Na telefonach (<768px): Dolny pasek nawigacji + wysuwany Drawer.
/// - Na tabletach/desktopie (>=768px): Stały elegancki lewy panel nawigacyjny,
///   górny pasek statusu (data, budżet, następny wyścig, przycisk "Następny Dzień / Kontynuuj")
///   oraz główny obszar roboczy.
class MainShellScreen extends ConsumerStatefulWidget {
  final Widget? child;
  final String? currentLocation;

  const MainShellScreen({
    super.key,
    this.child,
    this.currentLocation,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  MainNavigationTab _activeTab = MainNavigationTab.dashboard;
  bool _isSidebarCollapsed = false;
  bool _useBentoHq = true;

  // Filtry stanu dla poszczególnych widoków
  String _inboxCategoryFilter = 'all';

  MainNavigationTab get activeTab =>
      widget.child != null ? _resolveTabFromLocation(widget.currentLocation) : _activeTab;

  MainNavigationTab _resolveTabFromLocation(String? location) {
    if (location == null) return _activeTab;
    if (location.startsWith('/career/roster') ||
        location.startsWith('/career/rider') ||
        location.startsWith('/career/team-builder')) {
      return MainNavigationTab.roster;
    }
    if (location.startsWith('/career/training') ||
        location.startsWith('/career/lab')) {
      return MainNavigationTab.training;
    }
    if (location.startsWith('/career/calendar')) {
      return MainNavigationTab.calendar;
    }
    if (location.startsWith('/career/garage')) {
      return MainNavigationTab.equipment;
    }
    if (location.startsWith('/career/sponsors')) {
      return MainNavigationTab.finances;
    }
    if (location.startsWith('/career/transfers')) {
      return MainNavigationTab.transfers;
    }
    if (location.startsWith('/career/settings')) {
      return MainNavigationTab.settings;
    }
    return MainNavigationTab.dashboard;
  }

  void _onTabSelected(MainNavigationTab tab) {
    setState(() {
      _activeTab = tab;
    });

    if (widget.child != null) {
      switch (tab) {
        case MainNavigationTab.dashboard:
          context.go('/career/dashboard');
          break;
        case MainNavigationTab.roster:
          context.go('/career/roster');
          break;
        case MainNavigationTab.training:
          context.go('/career/training');
          break;
        case MainNavigationTab.calendar:
          context.go('/career/calendar');
          break;
        case MainNavigationTab.equipment:
          context.go('/career/garage');
          break;
        case MainNavigationTab.finances:
          context.go('/career/sponsors');
          break;
        case MainNavigationTab.transfers:
          context.go('/career/transfers');
          break;
        case MainNavigationTab.inbox:
          context.go('/career/dashboard');
          break;
        case MainNavigationTab.settings:
          context.go('/career/settings');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final careerUiState = ref.watch(careerProvider);
    final careerController = ref.read(careerProvider.notifier);
    final careerState = ref.watch(careerStateNotifierProvider);
    final careerStateNotifier = ref.read(careerStateNotifierProvider.notifier);
    final simController = ref.read(raceSimulationProvider.notifier);

    final save = careerUiState.save;

    // Gdy brak aktywnego zapisu w pamięci, wyświetl ekran powitalny
    if (save == null) {
      return _buildNoSaveWelcomeScreen(careerController, careerUiState);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktopOrTablet = constraints.maxWidth >= 768;

        if (isDesktopOrTablet) {
          return _buildDesktopLayout(
            context: context,
            constraints: constraints,
            save: save,
            careerUiState: careerUiState,
            careerController: careerController,
            careerState: careerState,
            careerStateNotifier: careerStateNotifier,
            simController: simController,
          );
        } else {
          return _buildMobileLayout(
            context: context,
            save: save,
            careerUiState: careerUiState,
            careerController: careerController,
            careerState: careerState,
            careerStateNotifier: careerStateNotifier,
            simController: simController,
          );
        }
      },
    );
  }

  // ===========================================================================
  // 1. UKŁAD DESKTOP / TABLET (STAŁY BOCZNY PANEL + GÓRNY PASEK STATUSU)
  // ===========================================================================

  Widget _buildDesktopLayout({
    required BuildContext context,
    required BoxConstraints constraints,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required CareerState careerState,
    required CareerStateNotifier careerStateNotifier,
    required RaceSimulationNotifier simController,
  }) {
    final bool isCompactSidebar = _isSidebarCollapsed || constraints.maxWidth < 960;
    final double sidebarWidth = isCompactSidebar ? 78.0 : 252.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // 1. Stały elegancki boczny panel nawigacyjny po lewej stronie
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: sidebarWidth,
            child: _buildSidebarPanel(
              context: context,
              save: save,
              careerUiState: careerUiState,
              careerState: careerState,
              isCollapsed: isCompactSidebar,
            ),
          ),

          // 2. Główny obszar z górnym paskiem statusu i obszarem roboczym
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Górny pasek statusu (Top Status Bar)
                _buildDesktopTopStatusBar(
                  context: context,
                  save: save,
                  careerUiState: careerUiState,
                  careerController: careerController,
                  careerState: careerState,
                  simController: simController,
                ),

                // Główny obszar roboczy (Main Workspace)
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: widget.child ??
                        _buildActiveTabContent(
                          context: context,
                          save: save,
                          careerUiState: careerUiState,
                          careerController: careerController,
                          careerState: careerState,
                          careerStateNotifier: careerStateNotifier,
                          simController: simController,
                          isDesktop: true,
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

  // ===========================================================================
  // 2. UKŁAD MOBILNY (DOLNY PASEK NAWIGACJI + WYSUWANE MENU DRAWER)
  // ===========================================================================

  Widget _buildMobileLayout({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required CareerState careerState,
    required CareerStateNotifier careerStateNotifier,
    required RaceSimulationNotifier simController,
  }) {
    final playerTeam = save.playerTeam;
    final teamColor = _parseHexColor(playerTeam.primaryJerseyColorHex);
    final unreadMessages = careerState.unreadMessagesCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (drawerCtx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.goldAccent),
            tooltip: 'Otwórz Menu',
            onPressed: () => Scaffold.of(drawerCtx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: teamColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activeTab.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Pigułka z datą
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 11, color: AppColors.goldAccent),
                const SizedBox(width: 4),
                Text(
                  _formatShortPolishDate(save.currentDate),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Pigułka z budżetem
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, size: 12, color: AppColors.powerZone3),
                const SizedBox(width: 4),
                Text(
                  _formatCompactCurrency(playerTeam.cashBalanceEur),
                  style: const TextStyle(
                    color: AppColors.powerZone3,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      // Wysuwane menu (Drawer) na telefonach
      drawer: _buildMobileDrawer(
        context: context,
        save: save,
        careerUiState: careerUiState,
        careerController: careerController,
        careerState: careerState,
        simController: simController,
      ),

      // Główny obszar widoku
      body: widget.child ??
          _buildActiveTabContent(
            context: context,
            save: save,
            careerUiState: careerUiState,
            careerController: careerController,
            careerState: careerState,
            careerStateNotifier: careerStateNotifier,
            simController: simController,
            isDesktop: false,
          ),

      // Dolny pasek nawigacji (Bottom Navigation Bar)
      bottomNavigationBar: _buildMobileBottomNavBar(unreadMessages),
    );
  }

  // ===========================================================================
  // 3. BOCZNY PANEL NAWIGACYJNY (SIDEBAR NA DESKTOP / TABLET)
  // ===========================================================================

  Widget _buildSidebarPanel({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerState careerState,
    required bool isCollapsed,
  }) {
    final playerTeam = save.playerTeam;
    final teamColor = _parseHexColor(playerTeam.primaryJerseyColorHex);
    final unreadMessages = careerState.unreadMessagesCount;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nagłówek panelu z brandingiem gry
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.goldAccent, Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldAccent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_bike_rounded,
                      color: Colors.black,
                      size: 22,
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRO PELOTON',
                          style: TextStyle(
                            color: AppColors.goldAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'MANAGER 2026',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Karta drużyny gracza (gdy pasek rozwinięty)
          if (!isCollapsed)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: teamColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playerTeam.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                playerTeam.division.name.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.goldAccent,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (careerUiState.activeSlotNumber != null)
                              Text(
                                careerUiState.activeSlotNumber == 0
                                    ? 'Auto-Save'
                                    : 'Slot #${careerUiState.activeSlotNumber}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 8),

          // Lista zakładek nawigacyjnych
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8 : 10,
                vertical: 4,
              ),
              itemCount: MainNavigationTab.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 3),
              itemBuilder: (ctx, index) {
                final tab = MainNavigationTab.values[index];
                final isSelected = activeTab == tab;
                final badgeCount = (tab == MainNavigationTab.inbox) ? unreadMessages : 0;

                return _buildSidebarItem(
                  tab: tab,
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  badgeCount: badgeCount,
                  onTap: () => _onTabSelected(tab),
                );
              },
            ),
          ),

          // Stopka panelu: Przycisk zwijania/rozwijania paska i wersja
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 12,
              vertical: 8,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.borderColor, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  const Expanded(
                    child: Text(
                      'Wersja 1.0 • WorldTour',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isSidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  tooltip: _isSidebarCollapsed ? 'Rozwiń panel boczny' : 'Zwiń panel boczny',
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required MainNavigationTab tab,
    required bool isSelected,
    required bool isCollapsed,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    final iconWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isSelected ? tab.selectedIcon : tab.icon,
          size: 20,
          color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.powerZone6,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surface, width: 1.2),
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );

    if (isCollapsed) {
      return Tooltip(
        message: '${tab.title}\n${tab.description}',
        preferBelow: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceLight : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.goldAccent.withValues(alpha: 0.6) : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Center(child: iconWidget),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.goldAccent.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tab.title,
                    style: TextStyle(
                      color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  Text(
                    tab.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.powerZone6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. GÓRNY PASEK STATUSU (TOP STATUS BAR NA DESKTOP / TABLET)
  // ===========================================================================

  Widget _buildDesktopTopStatusBar({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required CareerState careerState,
    required RaceSimulationNotifier simController,
  }) {
    final playerTeam = save.playerTeam;
    final activeRace = save.calendar.activeRace;
    final activeStage = save.calendar.activeStage;
    final nextRace = save.calendar.nextUpcomingRace;

    // Sprawdzenie, czy drużyna gracza startuje w dzisiejszym wyścigu
    final bool isPlayerInTodayRace = activeRace != null &&
        activeStage != null &&
        activeRace.participatingTeamIds.contains(save.playerTeamId);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // 1. Lewa strona: Nazwa aktualnej sekcji / Okruszki chleba
          Row(
            children: [
              Icon(activeTab.selectedIcon, size: 20, color: AppColors.goldAccent),
              const SizedBox(width: 10),
              Text(
                activeTab.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${activeTab.description}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // 2. Środek / Prawa strona: Kluczowe wskaźniki telemetryczne statusu
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A. Aktualna data w grze
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 15, color: AppColors.goldAccent),
                        const SizedBox(width: 8),
                        Text(
                          _formatPolishFullDate(save.currentDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // B. Budżet klubu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, size: 15, color: AppColors.powerZone3),
                        const SizedBox(width: 8),
                        Text(
                          _formatMoney(playerTeam.cashBalanceEur),
                          style: const TextStyle(
                            color: AppColors.powerZone3,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // C. Następny / Dzisiejszy wyścig
                  _buildNextRaceStatusBadge(
                    save: save,
                    activeRace: activeRace,
                    activeStage: activeStage,
                    nextRace: nextRace,
                    isPlayerInTodayRace: isPlayerInTodayRace,
                  ),
                  const SizedBox(width: 16),

                  // D. Szybki zapis gry (Quick Save)
                  IconButton(
                    icon: const Icon(Icons.save_outlined, color: AppColors.goldAccent, size: 20),
                    tooltip: 'Szybki Zapis Gry (Slot bieżący)',
                    onPressed: () {
                      careerController.saveCurrentGame(isAutoSave: false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stan kariery został pomyślnie zapisany na dysku.'),
                          duration: Duration(seconds: 2),
                          backgroundColor: AppColors.surfaceLight,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // E. Kluczowy przycisk akcji: "Następny Dzień / Kontynuuj" lub "Do Wyścigu!"
                  _buildAdvanceActionButton(
                    context: context,
                    save: save,
                    careerUiState: careerUiState,
                    careerController: careerController,
                    simController: simController,
                    isPlayerInTodayRace: isPlayerInTodayRace,
                    activeStage: activeStage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pigułka statusu prezentująca dzisiejszy lub następny wyścig
  Widget _buildNextRaceStatusBadge({
    required CareerSave save,
    required TourRace? activeRace,
    required RaceStage? activeStage,
    required TourRace? nextRace,
    required bool isPlayerInTodayRace,
  }) {
    if (activeRace != null && activeStage != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isPlayerInTodayRace ? const Color(0xFF2E1906) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPlayerInTodayRace ? AppColors.goldAccent : AppTheme.borderColor,
            width: isPlayerInTodayRace ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlayerInTodayRace ? Icons.local_fire_department_rounded : Icons.sports_score_rounded,
              size: 15,
              color: isPlayerInTodayRace ? AppColors.goldAccent : _cyanAccent,
            ),
            const SizedBox(width: 6),
            Text(
              isPlayerInTodayRace
                  ? 'DZIŚ: ${activeRace.name} (Etap ${activeStage.stageNumber})'
                  : 'Dziś: ${activeRace.name} (Brak udziału)',
              style: TextStyle(
                color: isPlayerInTodayRace ? AppColors.goldAccent : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    if (nextRace != null) {
      final raceDate = DateTime(save.currentSeasonYear, nextRace.startMonth, nextRace.startDay);
      final daysDiff = raceDate.difference(save.currentDate).inDays;
      final daysText = (daysDiff == 0)
          ? 'Dziś start'
          : (daysDiff == 1)
              ? 'Jutro'
              : 'za $daysDiff dni';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_rounded, size: 14, color: _cyanAccent),
            const SizedBox(width: 6),
            Text(
              'Następny: ${nextRace.name} ($daysText)',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: AppColors.textSecondary),
          SizedBox(width: 6),
          Text(
            'Brak wyścigów w kalendarzu',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Przycisk "Następny Dzień / Kontynuuj" lub "Do Wyścigu!"
  Widget _buildAdvanceActionButton({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required RaceSimulationNotifier simController,
    required bool isPlayerInTodayRace,
    required RaceStage? activeStage,
  }) {
    if (careerUiState.isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldAccent),
            ),
            SizedBox(width: 8),
            Text(
              'Przetwarzanie...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    if (isPlayerInTodayRace && activeStage != null) {
      return ElevatedButton.icon(
        onPressed: () {
          _startRaceSimulation(context, save, activeStage, simController);
        },
        icon: const Icon(Icons.sports_score_rounded, size: 18),
        label: const Text('ODPRAWA & START 🏁'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () {
        careerController.advanceDay();
      },
      icon: const Icon(Icons.fast_forward_rounded, size: 18),
      label: const Text('Następny Dzień ⏩'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ===========================================================================
  // 5. OBSŁUGA MOBILNA: DRAWER I DOLNY PASEK
  // ===========================================================================

  Widget _buildMobileDrawer({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required CareerState careerState,
    required RaceSimulationNotifier simController,
  }) {
    final playerTeam = save.playerTeam;
    final teamColor = _parseHexColor(playerTeam.primaryJerseyColorHex);
    final activeRace = save.calendar.activeRace;
    final activeStage = save.calendar.activeStage;
    final bool isPlayerInTodayRace = activeRace != null &&
        activeStage != null &&
        activeRace.participatingTeamIds.contains(save.playerTeamId);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nagłówek Drawera z danymi klubu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF141822),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: teamColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playerTeam.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Dyrektor: ${save.playerManagerName}',
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
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatPolishFullDate(save.currentDate),
                      style: const TextStyle(color: AppColors.goldAccent, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatMoney(playerTeam.cashBalanceEur),
                      style: const TextStyle(color: AppColors.powerZone3, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista wszystkich 8 zakładek
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: MainNavigationTab.values.map((tab) {
                final isSelected = activeTab == tab;
                final badge = (tab == MainNavigationTab.inbox) ? careerState.unreadMessagesCount : 0;

                return ListTile(
                  leading: Icon(
                    isSelected ? tab.selectedIcon : tab.icon,
                    color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                  ),
                  title: Text(
                    tab.title,
                    style: TextStyle(
                      color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  subtitle: Text(
                    tab.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                  trailing: badge > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.powerZone6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$badge',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: AppColors.surfaceLight,
                  onTap: () {
                    Navigator.pop(context);
                    _onTabSelected(tab);
                  },
                );
              }).toList(),
            ),
          ),

          // Dolny przycisk akcji w menu
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildAdvanceActionButton(
              context: context,
              save: save,
              careerUiState: careerUiState,
              careerController: careerController,
              simController: simController,
              isPlayerInTodayRace: isPlayerInTodayRace,
              activeStage: activeStage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNavBar(int unreadCount) {
    // 4 główne destynacje + przycisk otwarcia menu Więcej
    const primaryTabs = [
      MainNavigationTab.dashboard,
      MainNavigationTab.roster,
      MainNavigationTab.calendar,
      MainNavigationTab.inbox,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...primaryTabs.map((tab) {
                final isSelected = activeTab == tab;
                final badge = (tab == MainNavigationTab.inbox) ? unreadCount : 0;

                return InkWell(
                  onTap: () => _onTabSelected(tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isSelected ? tab.selectedIcon : tab.icon,
                              size: 20,
                              color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                            ),
                            if (badge > 0)
                              Positioned(
                                top: -3,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.powerZone6,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$badge',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.shortLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Przycisk "Więcej" otwierający boczny Drawer
              Builder(
                builder: (drawerCtx) => InkWell(
                  onTap: () => Scaffold.of(drawerCtx).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.textSecondary),
                        SizedBox(height: 4),
                        Text(
                          'Więcej',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. GŁÓWNY OBSZAR ROBOCZY: PRZEŁĄCZNIK WIDOKÓW (TAB CONTENT SWITCHER)
  // ===========================================================================

  Widget _buildActiveTabContent({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required CareerState careerState,
    required CareerStateNotifier careerStateNotifier,
    required RaceSimulationNotifier simController,
    required bool isDesktop,
  }) {
    switch (_activeTab) {
      case MainNavigationTab.dashboard:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF141722),
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  _buildSubViewPill('Biuro HQ (Bento Grid)', _useBentoHq, () => setState(() => _useBentoHq = true)),
                  const SizedBox(width: 8),
                  _buildSubViewPill('Centrum Operacyjne (Hub)', !_useBentoHq, () => setState(() => _useBentoHq = false)),
                ],
              ),
            ),
            Expanded(
              child: _useBentoHq
                  ? const DashboardHqScreen()
                  : const CareerDashboardScreen(showAppBar: false),
            ),
          ],
        );

      case MainNavigationTab.roster:
        return const SquadRosterScreen();

      case MainNavigationTab.training:
        return const TrainingAndCampsScreen(showAppBar: false);

      case MainNavigationTab.calendar:
        return _buildCalendarView(context, save);

      case MainNavigationTab.equipment:
        return _buildEquipmentView(context, save);

      case MainNavigationTab.finances:
        return _buildFinancesView(context, save);

      case MainNavigationTab.transfers:
        return _buildTransfersView(context, save, careerController);

      case MainNavigationTab.inbox:
        return _buildInboxView(context, careerState, careerStateNotifier);

      case MainNavigationTab.settings:
        return _buildSavesAndModsView(context, save, careerController, careerUiState);
    }
  }

  Widget _buildSubViewPill(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 8. WIDOK: KALENDARZ & WYŚCIGI (CALENDAR VIEW)
  // ===========================================================================

  Widget _buildCalendarView(BuildContext context, CareerSave save) {
    return const CalendarAndRacePlannerScreen();
  }

  // ===========================================================================
  // 9. WIDOK: SPRZĘT & WARSZTAT (EQUIPMENT VIEW)
  // ===========================================================================

  Widget _buildEquipmentView(BuildContext context, CareerSave save) {
    return const BikeGarageRndScreen();
  }

  // ===========================================================================
  // 10. WIDOK: FINANSE & SPONSORZY (FINANCES VIEW)
  // ===========================================================================

  Widget _buildFinancesView(BuildContext context, CareerSave save) {
    return const SponsorsAndFinanceScreen();
  }

  // ===========================================================================
  // 11. WIDOK: TRANSFERY & SKAUTING (TRANSFERS VIEW)
  // ===========================================================================

  Widget _buildTransfersView(
    BuildContext context,
    CareerSave save,
    CareerController careerController,
  ) {
    return const TransferMarketScoutingScreen();
  }

  // ===========================================================================
  // 12. WIDOK: SKRZYNKA ODBIORCZA (INBOX VIEW)
  // ===========================================================================

  Widget _buildInboxView(
    BuildContext context,
    CareerState careerState,
    CareerStateNotifier careerStateNotifier,
  ) {
    final messages = careerState.inboxMessages;

    final filteredMessages = messages.where((msg) {
      if (_inboxCategoryFilter == 'unread') return !msg.isRead;
      if (_inboxCategoryFilter == 'race') return msg.category == InboxCategory.raceBriefing || msg.category == InboxCategory.raceResults;
      if (_inboxCategoryFilter == 'medical') return msg.category == InboxCategory.medicalReport;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildInboxFilterChip('Wszystkie (${messages.length})', 'all'),
                  _buildInboxFilterChip('Nieprzeczytane (${careerState.unreadMessagesCount})', 'unread'),
                  _buildInboxFilterChip('Wyścigi', 'race'),
                  _buildInboxFilterChip('Medyczne', 'medical'),
                ],
              ),
              TextButton.icon(
                onPressed: () => careerStateNotifier.markAllMessagesAsRead(),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('Oznacz wszystkie jako przeczytane', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: filteredMessages.isEmpty
                ? const Center(
                    child: Text(
                      'Brak wiadomości w skrzynce odbiorczej.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredMessages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final msg = filteredMessages[idx];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: msg.isRead ? AppColors.surface : const Color(0xFF1B2232),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: msg.isRead ? AppTheme.borderColor : _cyanAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              msg.isRead ? Icons.mail_outline_rounded : Icons.mark_email_unread_rounded,
                              color: msg.isRead ? AppColors.textSecondary : AppColors.goldAccent,
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${msg.senderName} (${msg.senderRole})',
                                        style: TextStyle(
                                          fontWeight: msg.isRead ? FontWeight.w600 : FontWeight.w800,
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        _formatShortPolishDate(msg.date),
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg.subject,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: msg.isRead ? AppColors.textPrimary : AppColors.goldAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg.body,
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxFilterChip(String label, String filterKey) {
    final isSelected = _inboxCategoryFilter == filterKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.black : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.goldAccent,
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide(color: isSelected ? AppColors.goldAccent : AppTheme.borderColor),
      onSelected: (_) {
        setState(() {
          _inboxCategoryFilter = filterKey;
        });
      },
    );
  }

  // ===========================================================================
  // 13. WIDOK: ZAPISY GRY & MODY (SAVES & MODS VIEW)
  // ===========================================================================

  Widget _buildSavesAndModsView(
    BuildContext context,
    CareerSave save,
    CareerController careerController,
    CareerUiState careerUiState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menedżer Zapisów Gry (Sloty 1-5 & Auto-Save)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Twórz niezależne kopie zapasowe, przenoś zapisy między urządzeniami i zarządzaj modyfikacjami.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Sloty zapisu
          ...List.generate(5, (idx) {
            final slotNum = idx + 1;
            final isCurrentSlot = careerUiState.activeSlotNumber == slotNum;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrentSlot ? const Color(0xFF1B2332) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentSlot ? AppColors.goldAccent : AppTheme.borderColor,
                  width: isCurrentSlot ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#$slotNum',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.goldAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Slot zapisu kariery #$slotNum', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary)),
                        Text(isCurrentSlot ? 'Bieżący aktywny slot kariery' : 'Gotowy do zapisu/wczytania', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await careerController.saveToSlot(slotNum);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Zapisano do slotu #$slotNum')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Zapisz'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await careerController.loadFromSlot(slotNum);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Wczytaj'),
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
  // 14. EKRAN POWITALNY GDY BRAK AKTYWNEGO ZAPISU (NO SAVE SCREEN)
  // ===========================================================================

  Widget _buildNoSaveWelcomeScreen(
    CareerController careerController,
    CareerUiState careerUiState,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.goldAccent, Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.directions_bike_rounded, size: 36, color: Colors.black),
              ),
              const SizedBox(height: 20),
              const Text(
                'PRO PELOTON MANAGER',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Zarządzaj profesjonalną drużyną kolarską WorldTour.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/new-career');
                  },
                  icon: const Icon(Icons.add_road_rounded),
                  label: const Text('Kreator Nowej Kariery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await careerController.startNewCareer(
                      saveName: 'Kariera WorldTour 2026',
                      playerManagerName: 'Dyrektor Sportowy',
                      playerTeamId: 'wt_aethel_veloce',
                    );
                  },
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('Szybki Start (WorldTour 2026)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await careerController.loadAutoSave();
                  },
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Wczytaj Ostatni Auto-Save'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_rounded, size: 16),
                label: const Text('Menu Główne & Sloty Zapisów'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 15. METODY POMOCNICZE I DIALOGI
  // ===========================================================================

  void _startRaceSimulation(
    BuildContext context,
    CareerSave save,
    RaceStage activeStage,
    RaceSimulationNotifier simController,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreRaceBriefingScreen(
          stage: activeStage,
          race: save.calendar.activeRace,
        ),
      ),
    );
  }

  Color _parseHexColor(String hexString, [Color fallback = AppColors.primaryAccent]) {
    try {
      String hex = hexString.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  String _formatPolishFullDate(DateTime dt) {
    const months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'
    ];
    const weekdays = [
      'Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'
    ];
    final dayName = weekdays[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '${dt.day} $monthName ${dt.year} ($dayName)';
  }

  String _formatShortPolishDate(DateTime dt) {
    const months = [
      'sty', 'lut', 'mar', 'kwi', 'maj', 'cze',
      'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatMoney(int amountEur) {
    if (amountEur >= 1000000) {
      return '€${(amountEur / 1000000).toStringAsFixed(2)} mln';
    } else if (amountEur >= 1000) {
      return '€${(amountEur / 1000).toStringAsFixed(0)}k';
    }
    return '€$amountEur';
  }

  String _formatCompactCurrency(int amountEur) {
    if (amountEur >= 1000000) {
      return '€${(amountEur / 1000000).toStringAsFixed(1)}M';
    } else if (amountEur >= 1000) {
      return '€${(amountEur / 1000).toStringAsFixed(0)}k';
    }
    return '€$amountEur';
  }
}

