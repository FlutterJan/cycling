import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../state/career_controller.dart';
import '../../state/career_state_notifier.dart';
import '../../state/race_simulation_notifier.dart';
import '../widgets/global_search_spotlight_modal.dart';
import 'bike_garage_rnd_screen.dart';
import 'calendar_and_race_planner_screen.dart';
import 'career_dashboard_screen.dart';
import 'dashboard_hq_screen.dart';
import 'development_academy_screen.dart';
import 'hall_of_fame_and_records_screen.dart';
import 'jersey_and_bike_livery_studio_screen.dart';
import 'manager_profile_and_achievements_screen.dart';
import 'medical_and_recovery_center_screen.dart';
import 'physiology_lab_screen.dart';
import 'pre_race_briefing_screen.dart';
import 'settings_and_mod_screen.dart';
import 'sponsors_and_finance_screen.dart';
import 'squad_roster_screen.dart';
import 'staff_management_screen.dart';
import 'stage_editor_creator_screen.dart';
import 'team_builder_hierarchy_screen.dart';
import 'training_and_camps_screen.dart';
import 'transfer_market_scouting_screen.dart';
import 'wind_tunnel_and_bike_fit_screen.dart';

/// 4 główne kategorie bocznego paska nawigacyjnego (Sidebar / Drawer).
enum MainNavigationSection {
  commandCenter(
    title: 'CENTRUM DOWODZENIA',
    icon: Icons.hub_rounded,
  ),
  teamPerformance(
    title: 'ZESPÓŁ I WYDOLNOŚĆ',
    icon: Icons.groups_rounded,
  ),
  equipmentFinance(
    title: 'SPRZĘT I FINANSE',
    icon: Icons.precision_manufacturing_rounded,
  ),
  uciWorld(
    title: 'ŚWIAT UCI',
    icon: Icons.public_rounded,
  );

  final String title;
  final IconData icon;

  const MainNavigationSection({
    required this.title,
    required this.icon,
  });
}

/// Wszystkie 20 zakładek nawigacyjnych głównego szkieletu gry (MainShellScreen).
enum MainNavigationTab {
  // 1. CENTRUM DOWODZENIA
  dashboard(
    section: MainNavigationSection.commandCenter,
    routePath: AppRoutes.dashboard,
    title: 'Biuro HQ',
    shortLabel: 'HQ',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    description: 'Centrum dowodzenia drużyną',
  ),
  inbox(
    section: MainNavigationSection.commandCenter,
    routePath: AppRoutes.inbox,
    title: 'Skrzynka Odbiorcza',
    shortLabel: 'Poczta',
    icon: Icons.mail_outline_rounded,
    selectedIcon: Icons.mail_rounded,
    description: 'Odprawy, raporty i oferty',
  ),
  calendar(
    section: MainNavigationSection.commandCenter,
    routePath: AppRoutes.calendar,
    title: 'Kalendarz UCI & Planer',
    shortLabel: 'Kalendarz',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    description: 'Harmonogram sezonu i starty',
  ),

  // 2. ZESPÓŁ I WYDOLNOŚĆ
  roster(
    section: MainNavigationSection.teamPerformance,
    routePath: AppRoutes.roster,
    title: 'Kadra Zespołu',
    shortLabel: 'Kadra',
    icon: Icons.people_alt_outlined,
    selectedIcon: Icons.people_alt_rounded,
    description: 'Kolarze, formy i kontrakty',
  ),
  teamBuilder(
    section: MainNavigationSection.teamPerformance,
    routePath: AppRoutes.teamBuilder,
    title: 'Budowa Teamu i Hierarchia',
    shortLabel: 'Hierarchia',
    icon: Icons.account_tree_outlined,
    selectedIcon: Icons.account_tree_rounded,
    description: 'Liderzy, pociągi i chemia',
  ),
  training(
    section: MainNavigationSection.teamPerformance,
    routePath: AppRoutes.training,
    title: 'Treningi i Obozy (PMC)',
    shortLabel: 'Trening',
    icon: Icons.fitness_center_outlined,
    selectedIcon: Icons.fitness_center_rounded,
    description: 'Obciążenia CTL/ATL i zgrupowania',
  ),
  physiologyLab(
    section: MainNavigationSection.teamPerformance,
    routePath: AppRoutes.physiologyLab,
    title: 'Laboratorium Fizjologiczne',
    shortLabel: 'Lab',
    icon: Icons.biotech_outlined,
    selectedIcon: Icons.biotech_rounded,
    description: 'Mleczan, VO2max i krzywa mocy',
  ),
  medical(
    section: MainNavigationSection.teamPerformance,
    routePath: AppRoutes.medical,
    title: 'Centrum Medyczne',
    shortLabel: 'Medycyna',
    icon: Icons.medical_services_outlined,
    selectedIcon: Icons.medical_services_rounded,
    description: 'Kontuzje, krew i regeneracja',
  ),
  academy(
    section: MainNavigationSection.teamPerformance,
    routePath: AppRoutes.academy,
    title: 'Akademia U23 (Devo)',
    shortLabel: 'U23',
    icon: Icons.school_outlined,
    selectedIcon: Icons.school_rounded,
    description: 'Młode talenty i skauting',
  ),
  staff(
    section: MainNavigationSection.teamPerformance,
    routePath: AppRoutes.staff,
    title: 'Sztab Szkoleniowy',
    shortLabel: 'Sztab',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge_rounded,
    description: 'Dyrektorzy, trenerzy, lekarze',
  ),

  // 3. SPRZĘT I FINANSE
  equipment(
    section: MainNavigationSection.equipmentFinance,
    routePath: AppRoutes.garage,
    title: 'Garaż i R&D',
    shortLabel: 'Garaż',
    icon: Icons.pedal_bike_outlined,
    selectedIcon: Icons.pedal_bike_rounded,
    description: 'Rowery, ramy i osprzęt',
  ),
  windTunnel(
    section: MainNavigationSection.equipmentFinance,
    routePath: AppRoutes.windTunnel,
    title: 'Tunel Aero & Bike Fit',
    shortLabel: 'Tunel',
    icon: Icons.air_outlined,
    selectedIcon: Icons.air_rounded,
    description: 'Pozycja CdA i aerodynamika',
  ),
  finances(
    section: MainNavigationSection.equipmentFinance,
    routePath: AppRoutes.sponsors,
    title: 'Sponsorzy i Finanse',
    shortLabel: 'Finanse',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance_rounded,
    description: 'Budżet, umowy i cele',
  ),
  transfers(
    section: MainNavigationSection.equipmentFinance,
    routePath: AppRoutes.transfers,
    title: 'Rynek Transferowy',
    shortLabel: 'Transfery',
    icon: Icons.person_search_outlined,
    selectedIcon: Icons.person_search_rounded,
    description: 'Negocjacje i skauting',
  ),
  liveryStudio(
    section: MainNavigationSection.equipmentFinance,
    routePath: AppRoutes.liveryStudio,
    title: 'Studio Malowania',
    shortLabel: 'Malowanie',
    icon: Icons.palette_outlined,
    selectedIcon: Icons.palette_rounded,
    description: 'Koszulki i malowanie ram',
  ),

  // 4. ŚWIAT UCI
  uciRankings(
    section: MainNavigationSection.uciWorld,
    routePath: AppRoutes.uciRankings,
    title: 'Rankingi UCI & Licencja',
    shortLabel: 'UCI',
    icon: Icons.leaderboard_outlined,
    selectedIcon: Icons.leaderboard_rounded,
    description: 'Walka o WorldTour i punkty',
  ),
  hallOfFame(
    section: MainNavigationSection.uciWorld,
    routePath: AppRoutes.hallOfFame,
    title: 'Gablota Trofeów & KOM',
    shortLabel: 'Trofea',
    icon: Icons.emoji_events_outlined,
    selectedIcon: Icons.emoji_events_rounded,
    description: 'Puchary i rekordy podjazdów',
  ),
  managerProfile(
    section: MainNavigationSection.uciWorld,
    routePath: AppRoutes.managerProfile,
    title: 'Profil Menedżera',
    shortLabel: 'Menedżer',
    icon: Icons.military_tech_outlined,
    selectedIcon: Icons.military_tech_rounded,
    description: 'Reputacja, baza i osiągnięcia',
  ),
  stageEditor(
    section: MainNavigationSection.uciWorld,
    routePath: AppRoutes.stageEditor,
    title: 'Kreator Tras',
    shortLabel: 'Kreator',
    icon: Icons.route_outlined,
    selectedIcon: Icons.route_rounded,
    description: 'Projektowanie własnych etapów',
  ),
  settings(
    section: MainNavigationSection.uciWorld,
    routePath: AppRoutes.settings,
    title: 'Ustawienia i Mody',
    shortLabel: 'Ustawienia',
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune_rounded,
    description: 'Zapisy, grafika i baza modów',
  );

  final MainNavigationSection section;
  final String routePath;
  final String title;
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;
  final String description;

  const MainNavigationTab({
    required this.section,
    required this.routePath,
    required this.title,
    required this.shortLabel,
    required this.icon,
    required this.selectedIcon,
    required this.description,
  });
}

/// Dodatkowe trasy trybów specjalnych i ekspansji Paczki #8 dostępne z powłoki MainShellScreen.
enum MainShellPackage8Route {
  goldenEraRetro(
    routePath: AppRoutes.goldenEraRetro,
    title: 'Złota Era 1970–2015',
    shortLabel: 'Retro',
    description: 'Kampanie historyczne bez mierników mocy',
    icon: Icons.history_edu_outlined,
    selectedIcon: Icons.history_edu_rounded,
    accentColor: AppColors.goldAccent,
  ),
  cyclingEsports(
    routePath: AppRoutes.cyclingEsports,
    title: 'UCI Cycling Esports',
    shortLabel: 'e-Sports',
    description: 'Cyber-Welodrom & Virtual Talent ID',
    icon: Icons.sensors_outlined,
    selectedIcon: Icons.sensors_rounded,
    accentColor: AppColors.cyanAccent,
  ),
  esgGreenFleet(
    routePath: AppRoutes.esgGreenFleet,
    title: 'Flota EV & Ekonomia ESG',
    shortLabel: 'ESG',
    description: 'Bilans CO₂, pojazdy EV/FCEV i sponsorzy',
    icon: Icons.eco_outlined,
    selectedIcon: Icons.eco_rounded,
    accentColor: AppColors.statusSuccess,
  ),
  nationalTeamHq(
    routePath: AppRoutes.nationalTeamHq,
    title: 'Reprezentacja Narodowa',
    shortLabel: 'Kadra PL',
    description: 'Biuro Selekcjonera na MŚ i Igrzyska',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag_rounded,
    accentColor: AppColors.primaryAccent,
  ),
  grandTourRouteReveal(
    routePath: AppRoutes.grandTourRouteReveal,
    title: 'Prezentacja Tras GT',
    shortLabel: 'Trasy GT',
    description: 'Ceremonia tras Tour / Giro / Vuelta',
    icon: Icons.map_outlined,
    selectedIcon: Icons.map_rounded,
    accentColor: AppColors.goldAccent,
  ),
  managerLegacyBook(
    routePath: AppRoutes.managerLegacyBook,
    title: 'Księga Legendy (NG+)',
    shortLabel: 'Dynastia',
    description: 'Panteon menedżera i dziedzictwo NG+',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories_rounded,
    accentColor: AppColors.goldAccent,
  );

  final String routePath;
  final String title;
  final String shortLabel;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final Color accentColor;

  const MainShellPackage8Route({
    required this.routePath,
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    required this.accentColor,
  });
}

/// Dodatkowe trasy trybów specjalnych, rozwoju i analityki BI Paczki #9 dostępne z powłoki MainShellScreen.
enum MainShellPackage9Route {
  paracyclingWorldCup(
    routePath: AppRoutes.paracyclingWorldCup,
    title: 'UCI Para-Cycling',
    shortLabel: 'Para',
    description: 'Tandemy B, Handbike H1–H5 & Igrzyska',
    icon: Icons.accessible_forward_outlined,
    selectedIcon: Icons.accessible_forward_rounded,
    accentColor: AppColors.cyanAccent,
  ),
  clubMuseum(
    routePath: AppRoutes.clubMuseum,
    title: 'Muzeum & Rowery 3D',
    shortLabel: 'Muzeum',
    description: 'Historyczne ramy i pamiątki klubu',
    icon: Icons.museum_outlined,
    selectedIcon: Icons.museum_rounded,
    accentColor: AppColors.goldAccent,
  ),
  weeklyMicrocycle(
    routePath: AppRoutes.weeklyMicrocycle,
    title: 'Mikrocykle Treningowe',
    shortLabel: 'Mikrocykl',
    description: 'Kalendarz TSS/TSB i adaptacja aero',
    icon: Icons.view_week_outlined,
    selectedIcon: Icons.view_week_rounded,
    accentColor: AppColors.statusSuccess,
  ),
  talentCombine(
    routePath: AppRoutes.talentCombine,
    title: 'Global Talent Combine',
    shortLabel: 'Combine',
    description: 'Testy lab i wyścig selekcyjny U19',
    icon: Icons.star_outline_rounded,
    selectedIcon: Icons.star_rounded,
    accentColor: AppColors.accentBlue,
  ),
  careerAnalyticsBi(
    routePath: AppRoutes.careerAnalyticsBi,
    title: 'Analityka BI & ROI',
    shortLabel: 'BI & ROI',
    description: 'Zwrot z transferów, R&D i eksport',
    icon: Icons.analytics_outlined,
    selectedIcon: Icons.analytics_rounded,
    accentColor: AppColors.primaryAccent,
  );

  final String routePath;
  final String title;
  final String shortLabel;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final Color accentColor;

  const MainShellPackage9Route({
    required this.routePath,
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    required this.accentColor,
  });
}

/// Dodatkowe trasy Paczki #10 (Reżyserka TV na Żywo, Poranny Raport Medyczny GT,
/// Grudniowy Obóz Aero oraz Centrum Przedłużeń Kontraktów; Muzeum Klubowe znajduje się w Paczce #9).
enum MainShellPackage10Route {
  tvBroadcastDirector(
    routePath: AppRoutes.tvBroadcastDirector,
    title: 'Reżyserka TV Live',
    shortLabel: 'TV Live',
    description: 'Produkcja transmisji i kamery 3D',
    icon: Icons.live_tv_outlined,
    selectedIcon: Icons.live_tv_rounded,
    accentColor: AppColors.crimsonAlert,
  ),
  grandTourMorningMedical(
    routePath: AppRoutes.grandTourMorningMedical,
    title: 'Raport Medyczny GT',
    shortLabel: 'HRV / Fizjo',
    description: 'Poranne HRV i triaż fizjoterapeutów',
    icon: Icons.monitor_heart_outlined,
    selectedIcon: Icons.monitor_heart_rounded,
    accentColor: AppColors.statusSuccess,
  ),
  winterWindTunnelCamp(
    routePath: AppRoutes.winterWindTunnelCamp,
    title: 'Obóz Aero (Grudzień)',
    shortLabel: 'Obóz Aero',
    description: 'Pomiary oporu w Newtonach i CdA',
    icon: Icons.air_outlined,
    selectedIcon: Icons.air_rounded,
    accentColor: AppColors.cyanAccent,
  ),
  contractRenewalsWarRoom(
    routePath: AppRoutes.contractRenewalsWarRoom,
    title: 'Przedłużenia Kontraktów',
    shortLabel: 'Kontrakty',
    description: 'Priorytety kadrowe i budżet płacowy',
    icon: Icons.handshake_outlined,
    selectedIcon: Icons.handshake_rounded,
    accentColor: AppColors.goldAccent,
  );

  final String routePath;
  final String title;
  final String shortLabel;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final Color accentColor;

  const MainShellPackage10Route({
    required this.routePath,
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    required this.accentColor,
  });
}

/// Responsywny szkielet nawigacyjny gry (MainShellScreen):
/// - Mobile (<768px, np. 390x844): Compact AppBar + Drawer z 4 kategoriami + BottomBar + pasek akcji.
/// - Tablet/Desktop (>=768px, np. 1024x768 / 1600x900): Kategoryzowany Sidebar + TopBar
///   z herbem i barwami drużyny, budżetem EUR, datą, pogodą w bazie, mini-odliczaniem do wyścigu
///   oraz przyciskiem NASTĘPNY DZIEŃ / START WYŚCIGU.
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
  bool _isSpotlightOpen = false;

  Future<void> _openGlobalSearchSpotlight(CareerSave save) async {
    if (_isSpotlightOpen) return;
    _isSpotlightOpen = true;
    try {
      await GlobalSearchSpotlightModal.show(
        context,
        careerSave: save,
      );
    } finally {
      if (mounted) {
        _isSpotlightOpen = false;
      }
    }
  }

  MainNavigationTab get activeTab =>
      widget.child != null ? _resolveTabFromLocation(widget.currentLocation) : _activeTab;

  MainNavigationTab _resolveTabFromLocation(String? location) {
    if (location == null) return _activeTab;
    if (location.startsWith(AppRoutes.inbox)) return MainNavigationTab.inbox;
    if (location.startsWith(AppRoutes.calendar)) return MainNavigationTab.calendar;
    if (location.startsWith(AppRoutes.roster) || location.startsWith('/career/rider')) {
      return MainNavigationTab.roster;
    }
    if (location.startsWith(AppRoutes.teamBuilder)) return MainNavigationTab.teamBuilder;
    if (location.startsWith(AppRoutes.training)) return MainNavigationTab.training;
    if (location.startsWith(AppRoutes.physiologyLab)) return MainNavigationTab.physiologyLab;
    if (location.startsWith(AppRoutes.medical)) return MainNavigationTab.medical;
    if (location.startsWith(AppRoutes.academy)) return MainNavigationTab.academy;
    if (location.startsWith(AppRoutes.staff)) return MainNavigationTab.staff;
    if (location.startsWith(AppRoutes.garage)) return MainNavigationTab.equipment;
    if (location.startsWith(AppRoutes.windTunnel)) return MainNavigationTab.windTunnel;
    if (location.startsWith(AppRoutes.sponsors)) return MainNavigationTab.finances;
    if (location.startsWith(AppRoutes.transfers)) return MainNavigationTab.transfers;
    if (location.startsWith(AppRoutes.liveryStudio)) return MainNavigationTab.liveryStudio;
    if (location.startsWith(AppRoutes.uciRankings)) return MainNavigationTab.uciRankings;
    if (location.startsWith(AppRoutes.hallOfFame)) return MainNavigationTab.hallOfFame;
    if (location.startsWith(AppRoutes.managerProfile)) return MainNavigationTab.managerProfile;
    if (location.startsWith(AppRoutes.stageEditor)) return MainNavigationTab.stageEditor;
    if (location.startsWith(AppRoutes.settings)) return MainNavigationTab.settings;
    return MainNavigationTab.dashboard;
  }

  void _onTabSelected(MainNavigationTab tab) {
    setState(() {
      _activeTab = tab;
    });
    if (widget.child != null) {
      context.go(tab.routePath);
    }
  }

  void _onSpecialRouteSelected(
    BuildContext context,
    String routePath, {
    bool closeDrawer = false,
  }) {
    if (closeDrawer) {
      Navigator.of(context).pop();
    }
    final router = GoRouter.maybeOf(context);
    router?.go(routePath);
  }

  List<Widget> _buildSpecialRouteSection(
    BuildContext context, {
    required String headerTitle,
    required IconData headerIcon,
    required Color headerIconColor,
    required List<_SpecialRouteNavEntry> entries,
    required bool isCollapsed,
    required bool isDrawer,
  }) {
    final location = widget.currentLocation ?? '';
    return [
      if (!isCollapsed)
        Padding(
          padding: EdgeInsets.fromLTRB(isDrawer ? 10 : 8, 12, isDrawer ? 10 : 8, 6),
          child: Row(
            children: [
              Icon(
                headerIcon,
                size: 12,
                color: headerIconColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  headerTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        )
      else
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      for (final entry in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: _SidebarSpecialRouteItem(
            entry: entry,
            isSelected: location.startsWith(entry.routePath),
            isCollapsed: isCollapsed,
            onTap: () => _onSpecialRouteSelected(
              context,
              entry.routePath,
              closeDrawer: isDrawer,
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildPackage8NavSection(
    BuildContext context, {
    required bool isCollapsed,
    required bool isDrawer,
  }) {
    return _buildSpecialRouteSection(
      context,
      headerTitle: 'EKSPANSJE & TRYBY SPECJALNE',
      headerIcon: Icons.auto_awesome_rounded,
      headerIconColor: AppColors.goldAccent.withValues(alpha: 0.9),
      entries: [
        for (final r in MainShellPackage8Route.values)
          _SpecialRouteNavEntry(
            routePath: r.routePath,
            title: r.title,
            description: r.description,
            icon: r.icon,
            selectedIcon: r.selectedIcon,
            accentColor: r.accentColor,
          ),
      ],
      isCollapsed: isCollapsed,
      isDrawer: isDrawer,
    );
  }

  List<Widget> _buildPackage9NavSection(
    BuildContext context, {
    required bool isCollapsed,
    required bool isDrawer,
  }) {
    return _buildSpecialRouteSection(
      context,
      headerTitle: 'EKSPANSJA GLOBALNA & BI',
      headerIcon: Icons.public_rounded,
      headerIconColor: AppColors.cyanAccent.withValues(alpha: 0.9),
      entries: [
        for (final r in MainShellPackage9Route.values)
          _SpecialRouteNavEntry(
            routePath: r.routePath,
            title: r.title,
            description: r.description,
            icon: r.icon,
            selectedIcon: r.selectedIcon,
            accentColor: r.accentColor,
          ),
      ],
      isCollapsed: isCollapsed,
      isDrawer: isDrawer,
    );
  }

  List<Widget> _buildPackage10NavSection(
    BuildContext context, {
    required bool isCollapsed,
    required bool isDrawer,
  }) {
    return _buildSpecialRouteSection(
      context,
      headerTitle: 'PRODUKCJA TV, MEDYCYNA & KONTRAKTY',
      headerIcon: Icons.broadcast_on_personal_rounded,
      headerIconColor: AppColors.goldAccent.withValues(alpha: 0.9),
      entries: [
        for (final r in MainShellPackage10Route.values)
          _SpecialRouteNavEntry(
            routePath: r.routePath,
            title: r.title,
            description: r.description,
            icon: r.icon,
            selectedIcon: r.selectedIcon,
            accentColor: r.accentColor,
          ),
      ],
      isCollapsed: isCollapsed,
      isDrawer: isDrawer,
    );
  }

  int _badgeForTab(MainNavigationTab tab, CareerSave save, CareerState careerState) {
    switch (tab) {
      case MainNavigationTab.inbox:
        return careerState.unreadMessagesCount;
      case MainNavigationTab.medical:
        return save.playerRoster
            .where((r) => !r.health.isFitToRace || r.health.trainingStressBalance < -25)
            .length;
      case MainNavigationTab.roster:
        return save.playerRoster.where((r) => !r.health.isFitToRace).length;
      case MainNavigationTab.transfers:
        return save.contractOffers
            .where((o) => o.status == ContractOfferStatus.pending)
            .length;
      default:
        return 0;
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
    if (save == null) {
      return _buildNoSaveWelcomeScreen(careerController);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _openGlobalSearchSpotlight(save),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _openGlobalSearchSpotlight(save),
      },
      child: LayoutBuilder(
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
      ),
    );
  }

  // ===========================================================================
  // 1. UKŁAD DESKTOP / TABLET
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
    final bool isCompactSidebar = _isSidebarCollapsed || constraints.maxWidth < 1000;
    final double sidebarWidth = isCompactSidebar ? 76.0 : 264.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDesktopTopStatusBar(
                  context: context,
                  constraints: constraints,
                  save: save,
                  careerUiState: careerUiState,
                  careerController: careerController,
                  simController: simController,
                ),
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
  // 2. UKŁAD MOBILNY (390x844)
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
    final unreadMessages = careerState.unreadMessagesCount;
    final activeRace = save.calendar.activeRace;
    final activeStage = save.calendar.activeStage;
    final bool isPlayerInTodayRace = activeRace != null &&
        activeStage != null &&
        activeRace.participatingTeamIds.contains(save.playerTeamId);
    final weather = _computeBaseWeather(save.currentDate, playerTeam.countryIso);

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
            _TeamCrestBadge(team: playerTeam, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activeTab.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.goldAccent,
              size: 21,
            ),
            tooltip: 'Szukaj globalnie (Ctrl+K)',
            onPressed: () => _openGlobalSearchSpotlight(save),
          ),
          _TopStatusPill(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.goldAccent,
            label: _formatShortPolishDate(save.currentDate),
            compact: true,
          ),
          const SizedBox(width: 4),
          _TopStatusPill(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.statusSuccess,
            label: _formatCompactCurrency(playerTeam.cashBalanceEur),
            textColor: AppColors.statusSuccess,
            compact: true,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildMobileDrawer(
        context: context,
        save: save,
        careerUiState: careerUiState,
        careerController: careerController,
        careerState: careerState,
        simController: simController,
        weather: weather,
      ),
      body: Column(
        children: [
          // Pasek statusu pogody, odliczania i szybkiej akcji na Mobile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                _TopStatusPill(
                  icon: weather.icon,
                  iconColor: weather.color,
                  label: '${weather.tempC}°C',
                  compact: true,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildNextRaceMiniCountdown(
                    save: save,
                    activeRace: activeRace,
                    activeStage: activeStage,
                    nextRace: save.calendar.nextUpcomingRace,
                    isPlayerInTodayRace: isPlayerInTodayRace,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                _buildAdvanceActionButton(
                  context: context,
                  save: save,
                  careerUiState: careerUiState,
                  careerController: careerController,
                  simController: simController,
                  isPlayerInTodayRace: isPlayerInTodayRace,
                  activeRace: activeRace,
                  activeStage: activeStage,
                  compact: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.child ??
                _buildActiveTabContent(
                  context: context,
                  save: save,
                  careerUiState: careerUiState,
                  careerController: careerController,
                  careerState: careerState,
                  careerStateNotifier: careerStateNotifier,
                ),
          ),
        ],
      ),
      bottomNavigationBar: _buildMobileBottomNavBar(unreadMessages),
    );
  }

  // ===========================================================================
  // 3. KATEGORYZOWANY SIDEBAR (4 SEKCJE + BADGES + HOVER/ACTIVE/FOCUS)
  // ===========================================================================

  Widget _buildSidebarPanel({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerState careerState,
    required bool isCollapsed,
  }) {
    final playerTeam = save.playerTeam;

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
          // Nagłówek marki
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
                      colors: [AppColors.goldAccent, Color(0xFFB4861C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldAccent.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_bike_rounded,
                      color: Colors.black,
                      size: 21,
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
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.goldAccent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'MANAGER 2026',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Karta drużyny z herbem i barwami
          if (!isCollapsed)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  _TeamCrestBadge(team: playerTeam, size: 32),
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
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(
                                playerTeam.division.label,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.goldAccent,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (careerUiState.activeSlotNumber != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  careerUiState.activeSlotNumber == 0
                                      ? 'Auto-Save'
                                      : 'Slot #${careerUiState.activeSlotNumber}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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

          // Kategoryzowana lista 4 sekcji
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8 : 10,
                vertical: 6,
              ),
              children: [
                for (final section in MainNavigationSection.values) ...[
                  if (!isCollapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                      child: Row(
                        children: [
                          Icon(
                            section.icon,
                            size: 12,
                            color: AppColors.goldAccent.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              section.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      child: Divider(height: 1, color: AppTheme.borderColor),
                    ),
                  ...MainNavigationTab.values
                      .where((t) => t.section == section)
                      .map((tab) {
                    final isSelected = activeTab == tab;
                    final badgeCount = _badgeForTab(tab, save, careerState);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: _SidebarNavItem(
                        tab: tab,
                        isSelected: isSelected,
                        isCollapsed: isCollapsed,
                        badgeCount: badgeCount,
                        onTap: () => _onTabSelected(tab),
                      ),
                    );
                  }),
                ],
                ..._buildPackage10NavSection(
                  context,
                  isCollapsed: isCollapsed,
                  isDrawer: false,
                ),
                ..._buildPackage9NavSection(
                  context,
                  isCollapsed: isCollapsed,
                  isDrawer: false,
                ),
                ..._buildPackage8NavSection(
                  context,
                  isCollapsed: isCollapsed,
                  isDrawer: false,
                ),
              ],
            ),
          ),

          // Stopka: zwijanie panelu
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 12,
              vertical: 6,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.borderColor, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  const Expanded(
                    child: Text(
                      'WorldTour 2026 • v1.0',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isSidebarCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
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

  // ===========================================================================
  // 4. GÓRNY PASEK STATUSU (TOPBAR DESKTOP / TABLET)
  // ===========================================================================

  Widget _buildDesktopTopStatusBar({
    required BuildContext context,
    required BoxConstraints constraints,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required RaceSimulationNotifier simController,
  }) {
    final playerTeam = save.playerTeam;
    final activeRace = save.calendar.activeRace;
    final activeStage = save.calendar.activeStage;
    final nextRace = save.calendar.nextUpcomingRace;
    final weather = _computeBaseWeather(save.currentDate, playerTeam.countryIso);

    final bool isPlayerInTodayRace = activeRace != null &&
        activeStage != null &&
        activeRace.participatingTeamIds.contains(save.playerTeamId);
    final bool isWide = constraints.maxWidth >= 1280;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Lewa strona: Herb i barwy drużyny + aktualny ekran
          _TeamCrestBadge(team: playerTeam, size: 32),
          const SizedBox(width: 10),
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 280 : 180),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeTab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${playerTeam.name} • ${activeTab.section.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Prawa strona: Telemetria statusu + przycisk akcji
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Stan konta EUR
                  _TopStatusPill(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.statusSuccess,
                    label: _formatMoney(playerTeam.cashBalanceEur),
                    textColor: AppColors.statusSuccess,
                  ),
                  const SizedBox(width: 8),

                  // 2. Aktualna data
                  _TopStatusPill(
                    icon: Icons.calendar_month_rounded,
                    iconColor: AppColors.goldAccent,
                    label: isWide
                        ? _formatPolishFullDate(save.currentDate)
                        : _formatShortPolishDate(save.currentDate),
                  ),
                  const SizedBox(width: 8),

                  // 3. Pogoda w bazie
                  _TopStatusPill(
                    icon: weather.icon,
                    iconColor: weather.color,
                    label: isWide
                        ? '${weather.condition} ${weather.tempC}°C • ${weather.windKmh} km/h'
                        : '${weather.tempC}°C',
                  ),
                  const SizedBox(width: 8),

                  // 4. Mini-odliczanie dni do kolejnego wyścigu
                  _buildNextRaceMiniCountdown(
                    save: save,
                    activeRace: activeRace,
                    activeStage: activeStage,
                    nextRace: nextRace,
                    isPlayerInTodayRace: isPlayerInTodayRace,
                  ),
                  const SizedBox(width: 10),

                  // 4b. Globalna wyszukiwarka Spotlight (Ctrl+K)
                  Tooltip(
                    message: 'Szukaj kolarzy, drużyn, wyścigów i podjazdów (Ctrl+K)',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openGlobalSearchSpotlight(save),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppColors.goldAccent,
                              size: 16,
                            ),
                            if (isWide) ...[
                              const SizedBox(width: 6),
                              const Text(
                                'Szukaj...',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                  ),
                                ),
                                child: const Text(
                                  'Ctrl+K',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 5. Szybki zapis
                  Tooltip(
                    message: 'Szybki Zapis Kariery',
                    child: IconButton(
                      icon: const Icon(
                        Icons.save_outlined,
                        color: AppColors.goldAccent,
                        size: 20,
                      ),
                      onPressed: careerUiState.isLoading
                          ? null
                          : () {
                              careerController.saveCurrentGame(isAutoSave: false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Stan kariery zapisany.'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: AppColors.surfaceLight,
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 6. Wielki dynamiczny przycisk akcji
                  _buildAdvanceActionButton(
                    context: context,
                    save: save,
                    careerUiState: careerUiState,
                    careerController: careerController,
                    simController: simController,
                    isPlayerInTodayRace: isPlayerInTodayRace,
                    activeRace: activeRace,
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

  Widget _buildNextRaceMiniCountdown({
    required CareerSave save,
    required TourRace? activeRace,
    required RaceStage? activeStage,
    required TourRace? nextRace,
    required bool isPlayerInTodayRace,
    bool compact = false,
  }) {
    if (activeRace != null && activeStage != null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 11,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: isPlayerInTodayRace
              ? AppColors.primaryAccent.withValues(alpha: 0.25)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPlayerInTodayRace ? AppColors.goldAccent : AppTheme.borderColor,
            width: isPlayerInTodayRace ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlayerInTodayRace ? Icons.local_fire_department_rounded : Icons.flag_rounded,
              size: compact ? 13 : 15,
              color: isPlayerInTodayRace ? AppColors.goldAccent : AppColors.cyanAccent,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isPlayerInTodayRace
                    ? (compact ? 'DZIŚ: ${activeRace.name}' : 'DZIŚ: ${activeRace.name} (E${activeStage.stageNumber})')
                    : 'Dziś: ${activeRace.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isPlayerInTodayRace ? AppColors.goldAccent : AppColors.textPrimary,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (nextRace != null) {
      final raceDate = DateTime(save.currentSeasonYear, nextRace.startMonth, nextRace.startDay);
      final daysDiff = raceDate.difference(save.currentDate).inDays;
      final daysText = daysDiff <= 0
          ? 'Dziś'
          : (daysDiff == 1 ? 'Jutro' : 'Za $daysDiff d');

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 11,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: compact ? 13 : 14, color: AppColors.cyanAccent),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '$daysText: ${nextRace.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const _TopStatusPill(
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.textSecondary,
      label: 'Koniec sezonu',
    );
  }

  Widget _buildAdvanceActionButton({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required RaceSimulationNotifier simController,
    required bool isPlayerInTodayRace,
    required TourRace? activeRace,
    required RaceStage? activeStage,
    bool compact = false,
  }) {
    final bool isDisabled = careerUiState.isLoading;
    final bool isRaceDay = isPlayerInTodayRace && activeStage != null && activeRace != null;

    if (isDisabled) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
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
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final String label = isRaceDay
        ? (compact ? 'START WYŚCIGU' : 'START WYŚCIGU: ${activeRace.name}')
        : 'NASTĘPNY DZIEŃ';

    return _InteractiveActionButton(
      label: label,
      icon: isRaceDay ? Icons.sports_score_rounded : Icons.fast_forward_rounded,
      isRaceDay: isRaceDay,
      compact: compact,
      onPressed: () {
        if (isRaceDay) {
          _startRaceSimulation(context, save, activeStage, simController);
        } else {
          careerController.advanceDay();
        }
      },
    );
  }

  // ===========================================================================
  // 5. MOBILNY DRAWER & BOTTOM BAR
  // ===========================================================================

  Widget _buildMobileDrawer({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required CareerState careerState,
    required RaceSimulationNotifier simController,
    required _BaseWeatherInfo weather,
  }) {
    final playerTeam = save.playerTeam;
    final activeRace = save.calendar.activeRace;
    final activeStage = save.calendar.activeStage;
    final bool isPlayerInTodayRace = activeRace != null &&
        activeStage != null &&
        activeRace.participatingTeamIds.contains(save.playerTeamId);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TeamCrestBadge(team: playerTeam, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerTeam.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Dyrektor: ${save.playerManagerName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _formatPolishFullDate(save.currentDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.goldAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${weather.condition} ${weather.tempC}°C',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  for (final section in MainNavigationSection.values) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
                      child: Row(
                        children: [
                          Icon(section.icon, size: 12, color: AppColors.goldAccent),
                          const SizedBox(width: 6),
                          Text(
                            section.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...MainNavigationTab.values
                        .where((t) => t.section == section)
                        .map((tab) {
                      final isSelected = activeTab == tab;
                      final badge = _badgeForTab(tab, save, careerState);
                      return _SidebarNavItem(
                        tab: tab,
                        isSelected: isSelected,
                        isCollapsed: false,
                        badgeCount: badge,
                        onTap: () {
                          Navigator.pop(context);
                          _onTabSelected(tab);
                        },
                      );
                    }),
                  ],
                  ..._buildPackage10NavSection(
                    context,
                    isCollapsed: false,
                    isDrawer: true,
                  ),
                  ..._buildPackage9NavSection(
                    context,
                    isCollapsed: false,
                    isDrawer: true,
                  ),
                  ..._buildPackage8NavSection(
                    context,
                    isCollapsed: false,
                    isDrawer: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildAdvanceActionButton(
                context: context,
                save: save,
                careerUiState: careerUiState,
                careerController: careerController,
                simController: simController,
                isPlayerInTodayRace: isPlayerInTodayRace,
                activeRace: activeRace,
                activeStage: activeStage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBottomNavBar(int unreadCount) {
    const primaryTabs = [
      MainNavigationTab.dashboard,
      MainNavigationTab.inbox,
      MainNavigationTab.calendar,
      MainNavigationTab.roster,
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
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
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
                              color: isSelected
                                  ? AppColors.goldAccent
                                  : AppColors.textSecondary,
                            ),
                            if (badge > 0)
                              Positioned(
                                top: -4,
                                right: -7,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.crimsonAlert,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    badge > 9 ? '9+' : '$badge',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.shortLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.goldAccent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Builder(
                builder: (drawerCtx) => InkWell(
                  onTap: () => Scaffold.of(drawerCtx).openDrawer(),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apps_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Więcej',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
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
  // 6. PRZEŁĄCZNIK ZAKŁADEK (STANDALONE FALLBACK GDY BRAK GO_ROUTER CHILD)
  // ===========================================================================

  Widget _buildActiveTabContent({
    required BuildContext context,
    required CareerSave save,
    required CareerUiState careerUiState,
    required CareerController careerController,
    required CareerState careerState,
    required CareerStateNotifier careerStateNotifier,
  }) {
    switch (_activeTab) {
      case MainNavigationTab.dashboard:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  _buildSubViewPill(
                    'Biuro HQ (Bento Grid)',
                    _useBentoHq,
                    () => setState(() => _useBentoHq = true),
                  ),
                  const SizedBox(width: 8),
                  _buildSubViewPill(
                    'Centrum Operacyjne (Hub)',
                    !_useBentoHq,
                    () => setState(() => _useBentoHq = false),
                  ),
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
      case MainNavigationTab.inbox:
        return const CareerInboxView();
      case MainNavigationTab.calendar:
        return const CalendarAndRacePlannerScreen(showAppBar: false);
      case MainNavigationTab.roster:
        return const SquadRosterScreen(showAppBar: false);
      case MainNavigationTab.teamBuilder:
        return const TeamBuilderHierarchyScreen();
      case MainNavigationTab.training:
        return const TrainingAndCampsScreen(showAppBar: false);
      case MainNavigationTab.physiologyLab:
        return const PhysiologyLabScreen(showAppBar: false);
      case MainNavigationTab.medical:
        return const MedicalAndRecoveryCenterScreen(showAppBar: false);
      case MainNavigationTab.academy:
        return const DevelopmentAcademyScreen(showAppBar: false);
      case MainNavigationTab.staff:
        return const StaffManagementScreen(showAppBar: false);
      case MainNavigationTab.equipment:
        return const BikeGarageRndScreen();
      case MainNavigationTab.windTunnel:
        return const WindTunnelAndBikeFitScreen(showAppBar: false);
      case MainNavigationTab.finances:
        return const SponsorsAndFinanceScreen();
      case MainNavigationTab.transfers:
        return const TransferMarketScoutingScreen();
      case MainNavigationTab.liveryStudio:
        return const JerseyAndBikeLiveryStudioScreen();
      case MainNavigationTab.uciRankings:
        return const UciRankingsAndLicenseView();
      case MainNavigationTab.hallOfFame:
        return HallOfFameAndRecordsScreen(
          playerTeam: save.playerTeam,
          currentSeasonYear: save.currentSeasonYear,
        );
      case MainNavigationTab.managerProfile:
        return const ManagerProfileAndAchievementsScreen();
      case MainNavigationTab.stageEditor:
        return const StageEditorCreatorScreen();
      case MainNavigationTab.settings:
        return const SettingsAndModScreen();
    }
  }

  Widget _buildSubViewPill(String title, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.borderColor,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. EKRAN POWITALNY GDY BRAK AKTYWNEGO ZAPISU
  // ===========================================================================

  Widget _buildNoSaveWelcomeScreen(CareerController careerController) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.goldAccent, Color(0xFFB4861C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.directions_bike_rounded, size: 34, color: Colors.black),
                ),
                const SizedBox(height: 18),
                const Text(
                  'PRO PELOTON MANAGER',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Brak aktywnego zapisu kariery. Wybierz jedną z opcji poniżej.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.newCareer),
                    icon: const Icon(Icons.add_road_rounded),
                    label: const Text('Kreator Nowej Kariery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => careerController.startNewCareer(
                      saveName: 'Kariera WorldTour 2026',
                      playerManagerName: 'Dyrektor Sportowy',
                      playerTeamId: 'wt_aethel_veloce',
                    ),
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text('Szybki Start (WorldTour 2026)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => careerController.loadAutoSave(),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Wczytaj Ostatni Auto-Save'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ===========================================================================
  // 8. METODY POMOCNICZE
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

  _BaseWeatherInfo _computeBaseWeather(DateTime date, String countryIso) {
    final int month = date.month;
    final int seed = date.day + date.month * 31 + countryIso.hashCode.abs();
    final int baseTemp;
    if (month >= 6 && month <= 8) {
      baseTemp = 22 + (seed % 9);
    } else if (month >= 4 && month <= 5 || month == 9) {
      baseTemp = 15 + (seed % 7);
    } else if (month == 3 || month == 10) {
      baseTemp = 10 + (seed % 6);
    } else {
      baseTemp = 3 + (seed % 6);
    }
    final int windKmh = 8 + (seed % 18);
    final int condIdx = seed % 4;
    switch (condIdx) {
      case 0:
        return _BaseWeatherInfo('Słonecznie', baseTemp, windKmh, Icons.wb_sunny_rounded, AppColors.goldAccent);
      case 1:
        return _BaseWeatherInfo('Lekkie chmury', baseTemp - 1, windKmh, Icons.wb_cloudy_rounded, AppColors.accentBlue);
      case 2:
        return _BaseWeatherInfo('Wietrznie', baseTemp - 2, windKmh + 8, Icons.air_rounded, AppColors.cyanAccent);
      default:
        return _BaseWeatherInfo('Przelotny deszcz', baseTemp - 3, windKmh + 4, Icons.grain_rounded, AppColors.textSecondary);
    }
  }

  String _formatPolishFullDate(DateTime dt) {
    const months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia',
    ];
    const weekdays = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Nd'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} (${weekdays[dt.weekday - 1]})';
  }

  String _formatShortPolishDate(DateTime dt) {
    const months = [
      'sty', 'lut', 'mar', 'kwi', 'maj', 'cze',
      'lip', 'sie', 'wrz', 'paź', 'lis', 'gru',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatMoney(int amountEur) {
    if (amountEur.abs() >= 1000000) {
      return '€${(amountEur / 1000000).toStringAsFixed(2)} mln';
    } else if (amountEur.abs() >= 1000) {
      return '€${(amountEur / 1000).toStringAsFixed(0)}k';
    }
    return '€$amountEur';
  }

  String _formatCompactCurrency(int amountEur) {
    if (amountEur.abs() >= 1000000) {
      return '€${(amountEur / 1000000).toStringAsFixed(1)}M';
    } else if (amountEur.abs() >= 1000) {
      return '€${(amountEur / 1000).toStringAsFixed(0)}k';
    }
    return '€$amountEur';
  }
}

class _BaseWeatherInfo {
  final String condition;
  final int tempC;
  final int windKmh;
  final IconData icon;
  final Color color;

  const _BaseWeatherInfo(this.condition, this.tempC, this.windKmh, this.icon, this.color);
}

// =============================================================================
// KOMPONENTY INTERAKTYWNE (HOVER / ACTIVE / FOCUS / DISABLED)
// =============================================================================

class _TeamCrestBadge extends StatelessWidget {
  final CyclingTeam team;
  final double size;

  const _TeamCrestBadge({required this.team, this.size = 32});

  Color _parseHex(String hexString, Color fallback) {
    try {
      String hex = hexString.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = _parseHex(team.primaryJerseyColorHex, AppColors.primaryAccent);
    final secondary = _parseHex(team.secondaryJerseyColorHex, AppColors.goldAccent);
    final accent = _parseHex(team.accentJerseyColorHex, Colors.white);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.shield_rounded,
          size: size * 0.52,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _TopStatusPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color textColor;
  final bool compact;

  const _TopStatusPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.textColor = AppColors.textPrimary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: iconColor),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: textColor,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final MainNavigationTab tab;
  final bool isSelected;
  final bool isCollapsed;
  final int badgeCount;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.tab,
    required this.isSelected,
    required this.isCollapsed,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.isSelected;
    final Color bgColor = isSelected
        ? AppColors.surfaceLight
        : _isHovered
            ? AppColors.surfaceLight.withValues(alpha: 0.55)
            : Colors.transparent;
    final Color borderColor = isSelected
        ? AppColors.goldAccent.withValues(alpha: 0.65)
        : _isFocused
            ? AppColors.cyanAccent.withValues(alpha: 0.7)
            : _isHovered
                ? AppTheme.borderColor
                : Colors.transparent;

    final iconWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isSelected ? widget.tab.selectedIcon : widget.tab.icon,
          size: 19,
          color: isSelected
              ? AppColors.goldAccent
              : (_isHovered ? AppColors.textPrimary : AppColors.textSecondary),
        ),
        if (widget.badgeCount > 0 && widget.isCollapsed)
          Positioned(
            top: -5,
            right: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surface, width: 1.2),
              ),
              child: Text(
                widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
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

    if (widget.isCollapsed) {
      return Tooltip(
        message: '${widget.tab.title}\n${widget.tab.description}',
        preferBelow: false,
        child: FocusableActionDetector(
          onShowHoverHighlight: (v) => setState(() => _isHovered = v),
          onShowFocusHighlight: (v) => setState(() => _isFocused = v),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Center(child: iconWidget),
            ),
          ),
        ),
      );
    }

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tab.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.tab.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.badgeCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonAlert,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isRaceDay;
  final bool compact;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isRaceDay,
    required this.compact,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() => _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors = widget.isRaceDay
        ? [
            _isHovered ? const Color(0xFFDC2626) : AppColors.crimsonAlert,
            _isHovered ? const Color(0xFFE5C158) : AppColors.goldAccent,
          ]
        : [
            _isHovered ? const Color(0xFFA65756) : AppColors.primaryAccent,
            _isHovered ? const Color(0xFF753B3A) : const Color(0xFF6B3433),
          ];

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(maxWidth: widget.compact ? 170 : 300),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 12 : 18,
              vertical: widget.compact ? 8 : 11,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? AppColors.cyanAccent
                    : (widget.isRaceDay ? AppColors.goldAccent : AppColors.goldAccent.withValues(alpha: 0.45)),
                width: _isFocused ? 1.8 : 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.isRaceDay ? AppColors.crimsonAlert : AppColors.primaryAccent)
                      .withValues(alpha: _isHovered ? 0.45 : 0.25),
                  blurRadius: _isHovered ? 14 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: widget.compact ? 15 : 18,
                  color: widget.isRaceDay ? Colors.white : AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: widget.compact ? 11 : 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
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

// =============================================================================
// DEDYKOWANY WIDOK: SKRZYNKA ODBIORCZA (INBOX)
// =============================================================================

class CareerInboxView extends ConsumerStatefulWidget {
  const CareerInboxView({super.key});

  @override
  ConsumerState<CareerInboxView> createState() => _CareerInboxViewState();
}

class _CareerInboxViewState extends ConsumerState<CareerInboxView> {
  String _filter = 'all';
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final careerState = ref.watch(careerStateNotifierProvider);
    final notifier = ref.read(careerStateNotifierProvider.notifier);
    final messages = careerState.inboxMessages;

    final filtered = messages.where((m) {
      if (_filter == 'unread') return !m.isRead;
      if (_filter == 'race') {
        return m.category == InboxCategory.raceBriefing ||
            m.category == InboxCategory.raceResults;
      }
      if (_filter == 'medical') return m.category == InboxCategory.medicalReport;
      if (_filter == 'finance') {
        return m.category == InboxCategory.finance ||
            m.category == InboxCategory.sponsorNews ||
            m.category == InboxCategory.transferMarket;
      }
      return true;
    }).toList();

    final selected = filtered.isEmpty
        ? null
        : filtered.firstWhere(
            (m) => m.id == _selectedId,
            orElse: () => filtered.first,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 900;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildChip('Wszystkie (${messages.length})', 'all'),
                      _buildChip('Nieprzeczytane (${careerState.unreadMessagesCount})', 'unread'),
                      _buildChip('Wyścigi', 'race'),
                      _buildChip('Medyczne', 'medical'),
                      _buildChip('Finanse & Transfery', 'finance'),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: careerState.unreadMessagesCount > 0
                        ? () => notifier.markAllMessagesAsRead()
                        : null,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Oznacz wszystkie jako przeczytane'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: filtered.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Center(
                          child: Text(
                            'Brak wiadomości spełniających kryteria.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    : isWide
                        ? Row(
                            children: [
                              Expanded(flex: 5, child: _buildMessageList(filtered, selected, notifier)),
                              const SizedBox(width: 14),
                              Expanded(flex: 6, child: _buildMessageDetail(selected!)),
                            ],
                          )
                        : _buildMessageList(filtered, selected, notifier),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, String key) {
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? Colors.black : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.goldAccent,
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide(color: selected ? AppColors.goldAccent : AppTheme.borderColor),
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _buildMessageList(
    List<CareerInboxMessage> filtered,
    CareerInboxMessage? selected,
    CareerStateNotifier notifier,
  ) {
    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final msg = filtered[idx];
        final isSel = selected?.id == msg.id;
        return InkWell(
          onTap: () {
            setState(() => _selectedId = msg.id);
            if (!msg.isRead) notifier.markMessageAsRead(msg.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.surfaceLight
                  : (msg.isRead ? AppColors.surface : const Color(0xFF1D2230)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSel
                    ? AppColors.goldAccent
                    : (msg.isRead ? AppTheme.borderColor : AppColors.cyanAccent.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  msg.isRead ? Icons.mail_outline_rounded : Icons.mark_email_unread_rounded,
                  color: msg.isRead ? AppColors.textSecondary : AppColors.goldAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${msg.senderName} • ${msg.senderRole}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (msg.priority == InboxPriority.urgent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.crimsonAlert.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PILNE',
                                style: TextStyle(
                                  color: AppColors.crimsonAlert,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        msg.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: msg.isRead ? AppColors.textPrimary : AppColors.goldAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        msg.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageDetail(CareerInboxMessage msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  msg.category.label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${msg.date.day}.${msg.date.month}.${msg.date.year}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            msg.subject,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Od: ${msg.senderName} (${msg.senderRole})',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
          const Divider(height: 28, color: AppTheme.borderColor),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                msg.body,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DEDYKOWANY WIDOK: RANKINGI UCI I WALKA O LICENCJĘ WORLDTOUR
// =============================================================================

class UciRankingsAndLicenseView extends ConsumerWidget {
  const UciRankingsAndLicenseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(careerProvider).save;
    if (save == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.goldAccent));
    }

    final sortedTeams = List<CyclingTeam>.from(save.teams)
      ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));
    final playerRank = sortedTeams.indexWhere((t) => t.id == save.playerTeamId) + 1;

    final topRiders = List<Rider>.from(save.riders)
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KLASYFIKACJA DRUŻYNOWA UCI & LICENCJA WORLDTOUR',
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pozycja ${save.playerTeam.name}: #$playerRank / ${sortedTeams.length}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playerRank <= 18
                          ? 'Strefa bezpieczna licencji UCI WorldTour (Top 18).'
                          : 'Poza strefą Top 18 — wymagana walka o punkty UCI.',
                      style: TextStyle(
                        color: playerRank <= 18 ? AppColors.statusSuccess : AppColors.amberWarning,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _TopStatusPill(
                  icon: Icons.stars_rounded,
                  iconColor: AppColors.goldAccent,
                  label: '${save.playerTeam.uciPointsSeason} pkt UCI',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 960;
              final teamsCard = _buildTeamsTable(sortedTeams, save.playerTeamId);
              final ridersCard = _buildTopRidersCard(topRiders.take(15).toList(), save.playerTeamId);
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: teamsCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: ridersCard),
                  ],
                );
              }
              return Column(
                children: [
                  teamsCard,
                  const SizedBox(height: 16),
                  ridersCard,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsTable(List<CyclingTeam> teams, String playerTeamId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ranking Drużyn (Linia Licencji = #18)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < teams.length && i < 25; i++) ...[
            if (i == 18)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.crimsonAlert.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'GRANICA LICENCJI UCI WORLDTOUR (TOP 18)',
                  style: TextStyle(
                    color: AppColors.crimsonAlert,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: teams[i].id == playerTeamId
                    ? AppColors.primaryAccent.withValues(alpha: 0.22)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: teams[i].id == playerTeamId
                      ? AppColors.goldAccent
                      : AppTheme.borderColor,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                        color: i < 18 ? AppColors.goldAccent : AppColors.textSecondary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      teams[i].name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  Text(
                    teams[i].division.label,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${teams[i].uciPointsSeason} pkt',
                    style: const TextStyle(
                      color: AppColors.cyanAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopRidersCard(List<Rider> riders, String playerTeamId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Kolarze Świata (OVR)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < riders.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: riders[i].teamId == playerTeamId
                    ? AppColors.primaryAccent.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '#${i + 1}',
                      style: const TextStyle(
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      riders[i].fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    'OVR ${riders[i].overallRating}',
                    style: const TextStyle(
                      color: AppColors.statusSuccess,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
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

// =============================================================================
// DEDYKOWANY WIDOK: PROFIL MENEDŻERA I OSIĄGNIĘCIA
// =============================================================================

class ManagerProfileAndAchievementsView extends ConsumerWidget {
  const ManagerProfileAndAchievementsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(careerProvider).save;
    if (save == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.goldAccent));
    }

    final achievements = [
      (
        'Pierwsze Trofeum',
        'Zdobądź pierwsze zwycięstwo lub trofeum w karierze.',
        save.trophiesWon.isNotEmpty,
        Icons.emoji_events_rounded,
      ),
      (
        'Inżynier Aerodynamiki',
        'Rozbuduj Tunel Aerodynamiczny co najmniej do poziomu 3.',
        save.windTunnelLevel >= 3,
        Icons.air_rounded,
      ),
      (
        'Klinika WorldTour',
        'Rozbuduj Centrum Medyczne co najmniej do poziomu 3.',
        save.medicalCenterLevel >= 3,
        Icons.medical_services_rounded,
      ),
      (
        'Stabilne Finanse',
        'Utrzymuj ponad €2,000,000 na koncie drużyny.',
        save.playerTeam.cashBalanceEur >= 2000000,
        Icons.account_balance_wallet_rounded,
      ),
      (
        'Elita WorldTour',
        'Osiągnij reputację menedżerską 75+.',
        save.managerReputation >= 75,
        Icons.military_tech_rounded,
      ),
      (
        'Baza Logistyczna Pro',
        'Rozbuduj Service Course co najmniej do poziomu 3.',
        save.serviceCourseLevel >= 3,
        Icons.warehouse_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Wrap(
              spacing: 20,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TeamCrestBadge(team: save.playerTeam, size: 52),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            save.playerManagerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${save.playerTeam.name} • Sezon ${save.currentSeasonYear}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            save.difficulty.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.goldAccent, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Reputacja: ${save.managerReputation} / 100',
                      style: const TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (save.managerReputation / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _infraCard('Service Course', 'Poziom ${save.serviceCourseLevel} / 5', Icons.build_rounded),
              _infraCard('Tunel Aero', 'Poziom ${save.windTunnelLevel} / 5', Icons.air_rounded),
              _infraCard('Centrum Medyczne', 'Poziom ${save.medicalCenterLevel} / 5', Icons.local_hospital_rounded),
              _infraCard('Trofea w Gablocie', '${save.trophiesWon.length}', Icons.emoji_events_rounded),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Osiągnięcia Kariery',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((a) {
              final unlocked = a.$3;
              return Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked ? AppColors.goldAccent : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? AppColors.goldAccent.withValues(alpha: 0.18)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        a.$4,
                        color: unlocked ? AppColors.goldAccent : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.$1,
                            style: TextStyle(
                              color: unlocked ? AppColors.goldAccent : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.$2,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
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

  Widget _infraCard(String title, String value, IconData icon) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyanAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
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
}

class _SpecialRouteNavEntry {
  final String routePath;
  final String title;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final Color accentColor;

  const _SpecialRouteNavEntry({
    required this.routePath,
    required this.title,
    required this.description,
    required this.icon,
    required this.selectedIcon,
    required this.accentColor,
  });
}

class _SidebarSpecialRouteItem extends StatefulWidget {
  final _SpecialRouteNavEntry entry;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback? onTap;

  const _SidebarSpecialRouteItem({
    required this.entry,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarSpecialRouteItem> createState() =>
      _SidebarSpecialRouteItemState();
}

class _SidebarSpecialRouteItemState extends State<_SidebarSpecialRouteItem> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onTap != null;
    final bool isSelected = widget.isSelected;
    final Color accent = widget.entry.accentColor;

    final Color bgColor = !isEnabled
        ? AppColors.surface.withValues(alpha: 0.35)
        : isSelected
            ? AppColors.surfaceLight
            : _isPressed
                ? AppColors.surfaceLight.withValues(alpha: 0.75)
                : _isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.55)
                    : Colors.transparent;

    final Color borderColor = !isEnabled
        ? Colors.transparent
        : isSelected
            ? accent.withValues(alpha: 0.65)
            : _isFocused
                ? AppColors.cyanAccent.withValues(alpha: 0.7)
                : _isHovered
                    ? AppTheme.borderColor
                    : Colors.transparent;

    final Color iconColor = !isEnabled
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : isSelected
            ? accent
            : _isHovered
                ? AppColors.textPrimary
                : accent.withValues(alpha: 0.85);

    final Widget iconWidget = Icon(
      isSelected ? widget.entry.selectedIcon : widget.entry.icon,
      size: 19,
      color: iconColor,
    );

    if (widget.isCollapsed) {
      return Tooltip(
        message: '${widget.entry.title}\n${widget.entry.description}',
        preferBelow: false,
        child: FocusableActionDetector(
          enabled: isEnabled,
          onShowHoverHighlight: (v) => setState(() => _isHovered = v),
          onShowFocusHighlight: (v) => setState(() => _isFocused = v),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _isPressed = v),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Center(child: iconWidget),
            ),
          ),
        ),
      );
    }

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _isPressed = v),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: !isEnabled
                            ? AppColors.textSecondary.withValues(alpha: 0.45)
                            : isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.entry.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary.withValues(alpha: 0.72),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: isSelected
                    ? accent
                    : AppColors.textSecondary.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
