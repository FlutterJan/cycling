import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/race/tour_race.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/historical_records_and_palmares_service.dart';

const Color _borderColor = Color(0xFF2E3440);

/// Ekran Gabloty Trofeów, Historii Kolarstwa i Rekordów Podjazdów (Hall of Fame & Records).
///
/// Prezentuje 4 główne moduły:
/// 1. Wizualna Gablota z Pucharami (Bruk z Roubaix, Puchar z Paryża, Trofeo Senza Fine, Koszulki Liderów).
/// 2. Tabela Rekordów Podjazdów (KOM Time Records na Alpe d'Huez, Ventoux, Stelvio, Angliru z czasem, VAM i W/kg).
/// 3. Pełna Historia Sezon po Sezonie (zwycięzcy wyścigów, podsumowania Grand Tourów i Monumentów).
/// 4. Oficjalny Ranking Wszech Czasów (Panteon Legend i All-Time GOAT Index).
class HallOfFameAndRecordsScreen extends StatefulWidget {
  final HistoricalRecordsAndPalmaresService? palmaresService;
  final CyclingTeam? playerTeam;
  final int currentSeasonYear;
  final int initialTab;

  const HallOfFameAndRecordsScreen({
    super.key,
    this.palmaresService,
    this.playerTeam,
    this.currentSeasonYear = 2026,
    this.initialTab = 0,
  });

  @override
  State<HallOfFameAndRecordsScreen> createState() =>
      _HallOfFameAndRecordsScreenState();
}

class _HallOfFameAndRecordsScreenState extends State<HallOfFameAndRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HistoricalRecordsAndPalmaresService _service;

  // Filtry gabloty
  PalmaresAchievementType? _selectedCategoryFilter;

  // Wybrany sezon w historii
  late int _selectedSeasonYear;

  // Wyszukiwarka podjazdów
  String _climbSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _selectedSeasonYear = widget.currentSeasonYear;

    if (widget.palmaresService != null) {
      _service = widget.palmaresService!;
    } else {
      _service = HistoricalRecordsAndPalmaresService();
      _seedDemoDataIfEmpty();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _seedDemoDataIfEmpty() {
    // Rejestrujemy przykładowe triumfy zespołu gracza, aby gablota od początku wyglądała okazale
    final playerTeamId = widget.playerTeam?.id ?? 'team_player';
    final playerTeamName = widget.playerTeam?.name ?? 'Veloce Pro Cycling';

    _service.registerRaceCompletion(
      race: const TourRace(
        id: 'race_roubaix_monument_2026',
        name: 'Hell of the North Pavé Monument (Paryż-Roubaix)',
        countryIso: 'FRA',
        uciCategory: RaceCategory.monument,
        startMonth: 4,
        startDay: 12,
        stages: [],
        prizePoolEur: 180000,
        participatingTeamIds: [],
        ridersPerTeam: 7,
        classifications: RaceClassifications(
          generalClassification: [],
          pointsClassification: [],
          mountainsClassification: [],
          youthClassification: [],
          teamClassification: [],
        ),
      ),
      seasonYear: widget.currentSeasonYear,
      winningRiderId: 'rider_pave_hero',
      winningRiderName: 'Mathieu van Veloce',
      winningTeamId: playerTeamId,
      winningTeamName: playerTeamName,
      winningMarginSeconds: 42,
      podiumRiderNames: ['Mathieu van Veloce', 'Nils Politt', 'Stefan Küng'],
      notes: 'Samotny rajd na sektorze Carrefour de l\'Arbre i triumf na welodromie!',
    );

    _service.registerRaceCompletion(
      race: const TourRace(
        id: 'race_tour_de_france_2026',
        name: 'Tour de France (La Grande Boucle)',
        countryIso: 'FRA',
        uciCategory: RaceCategory.grandTour,
        startMonth: 7,
        startDay: 4,
        stages: [],
        prizePoolEur: 2600000,
        participatingTeamIds: [],
        ridersPerTeam: 8,
        classifications: RaceClassifications(
          generalClassification: [],
          pointsClassification: [],
          mountainsClassification: [],
          youthClassification: [],
          teamClassification: [],
        ),
      ),
      seasonYear: widget.currentSeasonYear,
      winningRiderId: 'pogacar_legend',
      winningRiderName: 'Tadej Pogačar',
      winningTeamId: 'team_uae',
      winningTeamName: 'UAE Team Emirates',
      winningMarginSeconds: 345,
      podiumRiderNames: ['Tadej Pogačar', 'Jonas Vingegaard', 'Remco Evenepoel'],
      stageWinners: {
        18: (riderId: 'rider_climber_ace', riderName: 'Mateusz Alpejski', teamId: playerTeamId, teamName: playerTeamName),
      },
      jerseyWinners: {
        'Maillot Jaune': (riderId: 'pogacar_legend', riderName: 'Tadej Pogačar'),
        'Maillot à Pois': (riderId: 'rider_climber_ace', riderName: 'Mateusz Alpejski'),
      },
      daysInLeaderJersey: {'pogacar_legend': 15},
      notes: 'Mateusz Alpejski zdobywa koszulkę w grochy dla naszej drużyny!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrophyCabinetTab(),
          _buildClimbRecordsTab(),
          _buildSeasonsHistoryTab(),
          _buildHallOfFameTab(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.goldAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gablota Trofeów & Palmarès',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              Text(
                'Historia kolarstwa, rekordy przełęczy i Panteon Legend',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.goldAccent,
        indicatorWeight: 3,
        labelColor: AppColors.goldAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(
            text: 'Gablota Trofeów',
            icon: Icon(Icons.military_tech, size: 20),
          ),
          Tab(
            text: 'Rekordy Podjazdów',
            icon: Icon(Icons.terrain, size: 20),
          ),
          Tab(
            text: 'Historia Sezonów',
            icon: Icon(Icons.history_edu, size: 20),
          ),
          Tab(
            text: 'Ranking Wszech Czasów',
            icon: Icon(Icons.stars, size: 20),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: GABLOTA TROFEÓW (TROPHY CABINET & VISUAL PALMARES)
  // ===========================================================================

  Widget _buildTrophyCabinetTab() {
    // Zbieramy wszystkie wpisy sukcesów
    final allEntries = <PalmaresEntry>[];
    final allRiders = _service.getAllTimeHallOfFame();
    for (final r in allRiders) {
      final p = _service.getRiderPalmares(r.riderId);
      if (p != null) {
        allEntries.addAll(p.entries);
      }
    }

    // Filtr kategorii
    final filtered = _selectedCategoryFilter == null
        ? allEntries
        : allEntries.where((e) => e.achievementType == _selectedCategoryFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Podświetlana Szklana Gablota Wystawowa (Visual Showcase)
          _buildGlassShowcaseHeader(),
          const SizedBox(height: 24),

          // 2. Filtry Kategorii Trofeów
          _buildTrophyFilters(),
          const SizedBox(height: 16),

          // 3. Siatka zdobytych pucharów i trofeów
          if (filtered.isEmpty)
            _buildEmptyTrophyPlaceholder()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = filtered[index];
                return _buildTrophyCard(entry);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGlassShowcaseHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C2230),
            Color(0xFF131722),
            AppColors.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: AppColors.goldAccent, size: 28),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'ZŁOTA SALA SŁAWY (TROPHY ROOM)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'EXCELLENCE ÉTERNEL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Panteon Wizualnych Pucharów
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildVisualTrophyStand(
                  title: 'Bruk z Roubaix',
                  subtitle: 'Paryż-Roubaix',
                  icon: Icons.square,
                  accentColor: const Color(0xFF94A3B8),
                  trophyWidget: const _RoubaixCobbleTrophyWidget(),
                ),
                const SizedBox(width: 16),
                _buildVisualTrophyStand(
                  title: 'Puchar z Paryża',
                  subtitle: 'Tour de France GC',
                  icon: Icons.emoji_events,
                  accentColor: const Color(0xFFFFD700),
                  trophyWidget: const _ParisTrophyCupWidget(),
                ),
                const SizedBox(width: 16),
                _buildVisualTrophyStand(
                  title: 'Trofeo Senza Fine',
                  subtitle: 'Giro d\'Italia',
                  icon: Icons.all_inclusive,
                  accentColor: const Color(0xFFF472B6),
                  trophyWidget: const _GiroSpiralTrophyWidget(),
                ),
                const SizedBox(width: 16),
                _buildVisualTrophyStand(
                  title: 'Tęczowa Koszulka',
                  subtitle: 'Mistrzostwo Świata',
                  icon: Icons.stars,
                  accentColor: AppColors.cyanAccent,
                  trophyWidget: const _RainbowJerseyMiniWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualTrophyStand({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Widget trophyWidget,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          SizedBox(height: 70, child: Center(child: trophyWidget)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Wszystkie Trofea'),
            selected: _selectedCategoryFilter == null,
            onSelected: (_) => setState(() => _selectedCategoryFilter = null),
            selectedColor: AppColors.goldAccent.withValues(alpha: 0.2),
            checkmarkColor: AppColors.goldAccent,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Grand Tour (Generalki)'),
            selected: _selectedCategoryFilter ==
                PalmaresAchievementType.grandTourGeneralClassification,
            onSelected: (_) => setState(() => _selectedCategoryFilter =
                PalmaresAchievementType.grandTourGeneralClassification),
            selectedColor: AppColors.goldAccent.withValues(alpha: 0.2),
            checkmarkColor: AppColors.goldAccent,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Monumenty Kolarstwa'),
            selected: _selectedCategoryFilter ==
                PalmaresAchievementType.monumentClassic,
            onSelected: (_) => setState(() => _selectedCategoryFilter =
                PalmaresAchievementType.monumentClassic),
            selectedColor: AppColors.goldAccent.withValues(alpha: 0.2),
            checkmarkColor: AppColors.goldAccent,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Etapy Grand Tour'),
            selected: _selectedCategoryFilter ==
                PalmaresAchievementType.grandTourStage,
            onSelected: (_) => setState(() => _selectedCategoryFilter =
                PalmaresAchievementType.grandTourStage),
            selectedColor: AppColors.goldAccent.withValues(alpha: 0.2),
            checkmarkColor: AppColors.goldAccent,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Koszulki Lidera / KOM'),
            selected: _selectedCategoryFilter ==
                PalmaresAchievementType.komJerseyWinner,
            onSelected: (_) => setState(() => _selectedCategoryFilter =
                PalmaresAchievementType.komJerseyWinner),
            selectedColor: AppColors.goldAccent.withValues(alpha: 0.2),
            checkmarkColor: AppColors.goldAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyCard(PalmaresEntry entry) {
    Color badgeColor = AppColors.goldAccent;
    IconData badgeIcon = Icons.emoji_events;

    if (entry.achievementType == PalmaresAchievementType.monumentClassic) {
      badgeColor = AppColors.cyanAccent;
      badgeIcon = Icons.flag;
    } else if (entry.achievementType == PalmaresAchievementType.grandTourStage) {
      badgeColor = AppColors.statusSuccess;
      badgeIcon = Icons.bolt;
    } else if (entry.achievementType == PalmaresAchievementType.komJerseyWinner) {
      badgeColor = AppColors.crimsonAlert;
      badgeIcon = Icons.terrain;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 26),
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
                      'SEZON ${entry.seasonYear}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: badgeColor,
                      ),
                    ),
                    if (entry.jerseyWorn != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.jerseyWorn!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.raceName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.riderName} (${entry.teamName})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (entry.details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.details,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
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

  Widget _buildEmptyTrophyPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'Brak trofeów w wybranej kategorii',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: REKORDY PODJAZDÓW (KOM TIME RECORDS & VAM TABLE)
  // ===========================================================================

  Widget _buildClimbRecordsTab() {
    final allClimbs = _service.getClimbRecords();
    final query = _climbSearchQuery.trim().toLowerCase();
    final filteredClimbs = query.isEmpty
        ? allClimbs
        : allClimbs.where((c) =>
            c.climbName.toLowerCase().contains(query) ||
            c.recordHolderRiderName.toLowerCase().contains(query) ||
            c.mountainRange.toLowerCase().contains(query)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pasek wyszukiwania podjazdów
          TextField(
            onChanged: (val) => setState(() => _climbSearchQuery = val),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Szukaj podjazdu (np. Alpe d\'Huez, Ventoux, Stelvio)...',
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.goldAccent),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tabela rekordów
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              children: [
                // Nagłówek tabeli
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'PODJAZD / GÓRA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'POSIADACZ KOM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'CZAS (KOM)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'VAM & MOC',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyanAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Wiersze podjazdów
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredClimbs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: _borderColor, height: 1),
                  itemBuilder: (context, index) {
                    final climb = filteredClimbs[index];
                    return _buildClimbRow(climb);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimbRow(ClimbKomRecord climb) {
    final isPlayerRider = widget.playerTeam != null &&
        climb.recordHolderTeamName == widget.playerTeam!.name;

    return InkWell(
      onTap: () => _showClimbLeaderboardModal(climb),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Podjazd & nachylenie
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    climb.climbName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${climb.lengthKm} km @ ${climb.averageGradientPct}% (+${climb.elevationGainM.round()} m)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Kolarz & zespół
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        climb.recordHolderRiderName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isPlayerRider) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: AppColors.goldAccent, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${climb.recordHolderTeamName} (${climb.achievedInSeasonYear})',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Czas rekordu
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    climb.formattedRecordTime,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ),
              ),
            ),

            // VAM & W/kg
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${climb.vamMetersPerHour.round()} VAM',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyanAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '~${climb.estimatedWattsPerKg.toStringAsFixed(2)} W/kg',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.statusSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClimbLeaderboardModal(ClimbKomRecord climb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.70,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Uchwyt i nagłówek
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          climb.climbName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${climb.mountainRange} • ${climb.lengthKm} km @ ${climb.averageGradientPct}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: _borderColor),

              // Lista Top Prób
              Expanded(
                child: climb.topAttempts.isEmpty
                    ? Center(
                        child: Text(
                          'Brak zarejestrowanych prób w karierze',
                          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: climb.topAttempts.length,
                        itemBuilder: (context, i) {
                          final a = climb.topAttempts[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: i == 0
                                  ? AppColors.goldAccent.withValues(alpha: 0.2)
                                  : AppColors.surfaceLight,
                              child: Text(
                                '#${i + 1}',
                                style: TextStyle(
                                  color: i == 0 ? AppColors.goldAccent : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              a.riderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${a.teamName} • ${a.raceName} (${a.seasonYear})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  a.formattedTime,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: i == 0 ? AppColors.goldAccent : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${a.vamMetersPerHour.round()} VAM • ${a.estimatedWattsPerKg} W/kg',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.cyanAccent,
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
      },
    );
  }

  // ===========================================================================
  // TAB 3: HISTORIA SEZONÓW (SEASON BY SEASON ARCHIVE)
  // ===========================================================================

  Widget _buildSeasonsHistoryTab() {
    final archives = _service.getSeasonWinners(_selectedSeasonYear);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selektor Sezonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ARCHIWUM ROZGRYWEK',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.goldAccent,
                ),
              ),
              DropdownButton<int>(
                value: _selectedSeasonYear,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                items: [2024, 2025, 2026, 2027, 2028].map((y) {
                  return DropdownMenuItem(
                    value: y,
                    child: Text('Sezon $y'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSeasonYear = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista rozegranych wyścigów w danym sezonie
          if (archives.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Text(
                'Brak rozegranych wyścigów w tym sezonie',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: archives.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final arc = archives[index];
                return _buildSeasonRaceCard(arc);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSeasonRaceCard(RaceSeasonArchiveRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.raceName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.winningMarginSeconds > 0
                      ? '+${Formatters.formatRaceTime(record.winningMarginSeconds, showHoursAlways: false)}'
                      : 'SPRINT',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.goldAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                'Zwycięzca: ${record.winnerRiderName} (${record.winnerTeamName})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (record.podiumRiderNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Podium: ${record.podiumRiderNames.join(" • ")}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (record.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              record.notes,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: RANKING WSZECH CZASÓW (ALL-TIME GOAT HALL OF FAME)
  // ===========================================================================

  Widget _buildHallOfFameTab() {
    final ranking = _service.getAllTimeHallOfFame();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nagłówek i opis GOAT Index
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.surfaceLight.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.stars, color: AppColors.goldAccent, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PANTEON WSZECH CZASÓW (ALL-TIME GOAT INDEX)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.goldAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Oficjalna punktacja historyczna: Tour de France (1000 pkt), Giro/Vuelta (750 pkt), Monumenty (450 pkt), Mistrzostwo Świata (500 pkt).',
                        style: TextStyle(
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
          const SizedBox(height: 16),

          // Tabela Hall of Fame
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ranking.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: _borderColor, height: 1),
              itemBuilder: (context, index) {
                final entry = ranking[index];
                return _buildHallOfFameRow(entry);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallOfFameRow(AllTimeRankingEntry entry) {
    Color rankColor = AppColors.textSecondary;
    if (entry.rank == 1) rankColor = AppColors.goldAccent;
    if (entry.rank == 2) rankColor = const Color(0xFFCBD5E1);
    if (entry.rank == 3) rankColor = const Color(0xFFB45309);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Pozycja w rankingu
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: rankColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Kolarz i dorobek
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.riderName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${entry.nationalityIso})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (entry.isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AKTYWNY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusSuccess,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.trophySummary,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Punkty GOAT
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.allTimePoints} pkt',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.goldAccent,
                ),
              ),
              const Text(
                'GOAT SCORE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// WIZUALNE WIDGETY TROFEÓW (ROUBAIX PAVE, PARIS CUP, SENZA FINE, RAINBOW JERSEY)
// =============================================================================

/// Wizualny Puchar Kostki Brukowej z Paryż-Roubaix na granitowym postumencie.
class _RoubaixCobbleTrophyWidget extends StatelessWidget {
  const _RoubaixCobbleTrophyWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF64748B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(3, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.grain, color: Color(0xFFE2E8F0), size: 22),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'ROUBAIX',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.w900,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wizualny Puchar Tour de France (Paryż - Champs-Élysées).
class _ParisTrophyCupWidget extends StatelessWidget {
  const _ParisTrophyCupWidget();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.emoji_events,
      color: Color(0xFFFFD700),
      size: 52,
    );
  }
}

/// Wizualna Złota Spirala Trofeo Senza Fine z Giro d'Italia.
class _GiroSpiralTrophyWidget extends StatelessWidget {
  const _GiroSpiralTrophyWidget();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.all_inclusive,
      color: Color(0xFFF472B6),
      size: 48,
    );
  }
}

/// Miniaturka Tęczowej Koszulki Mistrza Świata UCI.
class _RainbowJerseyMiniWidget extends StatelessWidget {
  const _RainbowJerseyMiniWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(height: 3, color: const Color(0xFF38BDF8)),
          Container(height: 3, color: const Color(0xFFEF4444)),
          Container(height: 3, color: const Color(0xFF000000)),
          Container(height: 3, color: const Color(0xFFF59E0B)),
          Container(height: 3, color: const Color(0xFF10B981)),
        ],
      ),
    );
  }
}
