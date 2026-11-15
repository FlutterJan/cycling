import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/career/season_calendar.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_health.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/race_calendar_selection_service.dart';
import '../../services/career/team_chemistry_and_builder_service.dart';
import '../../state/career_controller.dart';
import '../widgets/rider_avatar_painter.dart';

const Color _cyanAccent = Color(0xFF00E5FF);
const Color _accentRed = Color(0xFFEF4444);

/// Ekran Kalendarza UCI i Planowania Sezonu (Calendar and Race Planner).
///
/// Zawiera:
/// 1. Widok miesiąc po miesiącu wszystkich wyścigów (styczeń–październik):
///    - Grand Toury (21 etapów: Giro, Tour, Vuelta),
///    - Monumenty kolarstwa (1 dzień: Sanremo, Flandria, Roubaix, Liège, Lombardia),
///    - Wyścigi tygodniowe WorldTour (7-8 dni: Dauphiné, Tour de Suisse, Tirreno, Paris-Nice, Tour de Pologne),
///    - Klasyki WorldTour, ProSeries i Klasa 1.
/// 2. Obsługę Dzikich Kart (Wildcards):
///    - Wnioskowanie o dziką kartę do organizatorów (A.S.O., RCS Sport, Unipublic, Flanders Classics),
///    - Podgląd szans z rozbiciem na 4 filary (ranking UCI, narodowość, waleczność, gwiazdy),
///    - Oficjalne pisma od dyrekcji wyścigów.
/// 3. Planer składów wyścigowych (Race Squad Planner):
///    - Wybór 7 lub 8 kolarzy na każdy wyścig,
///    - Kontrola limitu dni wyścigowych w sezonie (max 75 dni startowych),
///    - Weryfikacja medyczna kolarzy (blokada kontuzjowanych zawodników),
///    - Wyznaczanie Lidera GC i Głównego Sprintera,
///    - Podsumowanie siły składu (średnie FTP, W/kg, moc pociągu górskiego i sprinterskiego),
///    - Algorytmiczny asystent wyboru optymalnego składu (AI DS).
class CalendarAndRacePlannerScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const CalendarAndRacePlannerScreen({
    super.key,
    this.showAppBar = false,
  });

  @override
  ConsumerState<CalendarAndRacePlannerScreen> createState() =>
      _CalendarAndRacePlannerScreenState();
}

class _CalendarAndRacePlannerScreenState
    extends ConsumerState<CalendarAndRacePlannerScreen> {
  int? _selectedMonth; // null = Cały sezon, 1..10 = Styczeń..Październik
  String _categoryFilter = 'all'; // all, grandTour, monument, worldTourStageRace, worldTourOneDay, proSeries, myTeam
  String _searchQuery = '';
  final Set<String> _expandedRaceIds = {};

  // Miesiące w kalendarzu kolarskim
  static const List<Map<String, dynamic>> _months = [
    {'number': 1, 'name': 'Styczeń', 'short': 'STY'},
    {'number': 2, 'name': 'Luty', 'short': 'LUT'},
    {'number': 3, 'name': 'Marzec', 'short': 'MAR'},
    {'number': 4, 'name': 'Kwiecień', 'short': 'KWI'},
    {'number': 5, 'name': 'Maj', 'short': 'MAJ'},
    {'number': 6, 'name': 'Czerwiec', 'short': 'CZE'},
    {'number': 7, 'name': 'Lipiec', 'short': 'LIP'},
    {'number': 8, 'name': 'Sierpień', 'short': 'SIE'},
    {'number': 9, 'name': 'Wrzesień', 'short': 'WRZ'},
    {'number': 10, 'name': 'Październik', 'short': 'PAŹ'},
  ];

  @override
  void initState() {
    super.initState();
    // Domyślnie ustawiamy bieżący miesiąc z gry, jeśli zapis jest dostępny
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final save = ref.read(careerProvider).save;
      if (save != null && _selectedMonth == null) {
        setState(() {
          _selectedMonth = save.currentDate.month.clamp(1, 10);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final careerUiState = ref.watch(careerProvider);
    final careerController = ref.read(careerProvider.notifier);
    final save = careerUiState.save;

    if (save == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.goldAccent),
        ),
      );
    }

    final calendar = save.calendar;
    final allRaces = calendar.races;
    final playerTeam = save.playerTeam;

    // Filtrowanie wyścigów
    final filteredRaces = allRaces.where((race) {
      // Filtr miesiąca
      if (_selectedMonth != null && race.startMonth != _selectedMonth) {
        return false;
      }

      // Filtr kategorii
      switch (_categoryFilter) {
        case 'grandTour':
          if (!race.isGrandTour) return false;
          break;
        case 'monument':
          if (race.uciCategory != RaceCategory.monument) return false;
          break;
        case 'worldTourStageRace':
          if (race.uciCategory != RaceCategory.worldTourStageRace) return false;
          break;
        case 'worldTourOneDay':
          if (race.uciCategory != RaceCategory.worldTourOneDay) return false;
          break;
        case 'proSeries':
          if (race.uciCategory != RaceCategory.proSeries &&
              race.uciCategory != RaceCategory.class1) {
            return false;
          }
          break;
        case 'myTeam':
          if (!race.participatingTeamIds.contains(playerTeam.id)) return false;
          break;
        case 'all':
        default:
          break;
      }

      // Wyszukiwanie tekstowe
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = race.name.toLowerCase().contains(q);
        final matchesCountry = race.countryIso.toLowerCase().contains(q);
        if (!matchesName && !matchesCountry) return false;
      }

      return true;
    }).toList();

    // Statystyki sezonu dla nagłówka
    final myRacesCount = allRaces
        .where((r) => r.participatingTeamIds.contains(playerTeam.id))
        .length;
    final totalPlannedRaceDays = _calculateTotalTeamRaceDays(save);
    final grantedWildcardsCount = save.wildcardApplications
        .where((a) => a.status == WildcardStatus.granted)
        .length;
    final pendingWildcardsCount = save.wildcardApplications
        .where((a) => a.status == WildcardStatus.pending)
        .length;
    final totalPrizeMoneyEur = allRaces
        .where((r) => r.participatingTeamIds.contains(playerTeam.id))
        .fold(0, (sum, r) => sum + r.prizePoolEur);

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Belka informacyjna i podsumowanie sezonu
          _buildSeasonHeader(
            save: save,
            playerTeam: playerTeam,
            myRacesCount: myRacesCount,
            totalPlannedDays: totalPlannedRaceDays,
            grantedWildcards: grantedWildcardsCount,
            pendingWildcards: pendingWildcardsCount,
            totalPrizeMoneyEur: totalPrizeMoneyEur,
            careerController: careerController,
          ),
          const SizedBox(height: 16),

          // 2. Karuzela selektora miesięcy (Styczeń – Październik)
          _buildMonthCarousel(save: save, allRaces: allRaces),
          const SizedBox(height: 14),

          // 3. Pasek filtrów kategorii i wyszukiwarki
          _buildFilterBar(allRaces: allRaces, playerTeamId: playerTeam.id),
          const SizedBox(height: 16),

          // 4. Lista wyścigów
          if (filteredRaces.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRaces.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final race = filteredRaces[idx];
                return _buildRaceCard(
                  context: context,
                  race: race,
                  save: save,
                  careerController: careerController,
                );
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.goldAccent),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: AppColors.goldAccent, size: 20),
              SizedBox(width: 10),
              Text(
                'Kalendarz UCI & Planer Sezonu',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: content,
    );
  }

  // ===========================================================================
  // 1. NAGŁÓWEK SEZONU I TELEMETRIA KALENDARZA
  // ===========================================================================

  Widget _buildSeasonHeader({
    required CareerSave save,
    required CyclingTeam playerTeam,
    required int myRacesCount,
    required int totalPlannedDays,
    required int grantedWildcards,
    required int pendingWildcards,
    required int totalPrizeMoneyEur,
    required CareerController careerController,
  }) {
    final String divisionTitle;
    final Color divisionColor;
    final String divisionDesc;

    switch (playerTeam.division) {
      case TeamDivision.worldTour:
        divisionTitle = 'UCI WORLDTEAM';
        divisionColor = _cyanAccent;
        divisionDesc = 'Gwarantowany i obowiązkowy start we wszystkich 35 wyścigach WorldTour';
        break;
      case TeamDivision.proTeam:
        divisionTitle = 'UCI PROTEAM';
        divisionColor = AppColors.goldAccent;
        divisionDesc = 'Wymaga składania wniosków o Dzikie Karty (Wildcards) na Grand Toury i Monumenty';
        break;
      case TeamDivision.continental:
        divisionTitle = 'UCI CONTINENTAL';
        divisionColor = AppColors.powerZone3;
        divisionDesc = 'Udział w wyścigach narodowych klasy 1.1 / 2.1 i wybranych ProSeries';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: divisionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: divisionColor.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.event_note_rounded, color: divisionColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$divisionTitle • OFICJALNY KALENDARZ UCI',
                          style: TextStyle(
                            color: divisionColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            'SEZON ${save.currentSeasonYear}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      playerTeam.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      divisionDesc,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Przycisk alokacji Dzikich Kart (przydatny dla ProTeam)
              if (playerTeam.division == TeamDivision.proTeam ||
                  playerTeam.division == TeamDivision.continental)
                ElevatedButton.icon(
                  onPressed: () {
                    careerController.simulateSeasonWildcardAllocation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Przeprowadzono posiedzenie komitetów UCI i organizatorów wyścigów! Statusy Dzikich Kart zostały zaktualizowane.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: AppColors.goldAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.black),
                  label: const Text(
                    'Symuluj Wildcards',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 12),

          // Paski statystyk
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildHeaderStatPill(
                icon: Icons.flag_rounded,
                label: 'Zaplanowane starty',
                value: '$myRacesCount wyścigów',
                color: AppColors.goldAccent,
              ),
              _buildHeaderStatPill(
                icon: Icons.timer_outlined,
                label: 'Dni startowe ekipy',
                value: '$totalPlannedDays dni',
                color: _cyanAccent,
              ),
              _buildHeaderStatPill(
                icon: Icons.confirmation_number_outlined,
                label: 'Dzikie Karty (Wildcards)',
                value: '$grantedWildcards przyznanych / $pendingWildcards oczek.',
                color: AppColors.powerZone3,
              ),
              _buildHeaderStatPill(
                icon: Icons.monetization_on_outlined,
                label: 'Pula nagród w zasięgu',
                value: '€${_formatCompactCurrency(totalPrizeMoneyEur)}',
                color: const Color(0xFF69F0AE),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
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
  // 2. KARUZELA SELEKTORA MIESIĘCY (STYCZEŃ – PAŹDZIERNIK)
  // ===========================================================================

  Widget _buildMonthCarousel({
    required CareerSave save,
    required List<TourRace> allRaces,
  }) {
    final currentInGameMonth = save.currentDate.month;
    final playerTeamId = save.playerTeamId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.goldAccent),
                SizedBox(width: 6),
                Text(
                  'MIESIĄCE SEZONU SZOSOWEGO',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMonth = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _selectedMonth == null
                      ? AppColors.goldAccent
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _selectedMonth == null
                        ? AppColors.goldAccent
                        : Colors.white12,
                  ),
                ),
                child: Text(
                  'Cały Sezon (Wszystkie)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _selectedMonth == null ? Colors.black : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _months.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final month = _months[idx];
              final int mNumber = month['number'] as int;
              final String mShort = month['short'] as String;
              final String mName = month['name'] as String;

              final isSelected = _selectedMonth == mNumber;
              final isCurrent = currentInGameMonth == mNumber;

              // Liczba wyścigów w danym miesiącu
              final monthRaces = allRaces.where((r) => r.startMonth == mNumber).toList();
              final racesCount = monthRaces.length;

              // Czy nasza drużyna jedzie w tym miesiącu
              final hasMyTeamRace = monthRaces.any(
                (r) => r.participatingTeamIds.contains(playerTeamId),
              );

              return Tooltip(
                message: '$mName - $racesCount wyścigów w kalendarzu',
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMonth = mNumber;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2E2412)
                        : (isCurrent ? const Color(0xFF1B2332) : AppColors.surface),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldAccent
                          : (isCurrent ? _cyanAccent : AppTheme.borderColor),
                      width: isSelected || isCurrent ? 1.5 : 1.0,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mShort,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? AppColors.goldAccent
                                  : (isCurrent
                                      ? _cyanAccent
                                      : AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$racesCount wyśc.',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.goldAccent.withValues(alpha: 0.8)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (hasMyTeamRace)
                        Positioned(
                          top: 0,
                          right: 2,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.goldAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. PASEK FILTRÓW KATEGORII I WYSZUKIWARKI
  // ===========================================================================

  Widget _buildFilterBar({
    required List<TourRace> allRaces,
    required String playerTeamId,
  }) {
    final int gtCount = allRaces.where((r) => r.isGrandTour).length;
    final int monumentCount =
        allRaces.where((r) => r.uciCategory == RaceCategory.monument).length;
    final int wtStageCount =
        allRaces.where((r) => r.uciCategory == RaceCategory.worldTourStageRace).length;
    final int wtOneDayCount =
        allRaces.where((r) => r.uciCategory == RaceCategory.worldTourOneDay).length;
    final int proCount = allRaces
        .where((r) =>
            r.uciCategory == RaceCategory.proSeries ||
            r.uciCategory == RaceCategory.class1)
        .length;
    final int myTeamCount =
        allRaces.where((r) => r.participatingTeamIds.contains(playerTeamId)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pole wyszukiwania
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Szukaj wyścigu, kraju lub etapu...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Filtry kategorii
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildCategoryChip('Wszystkie (${allRaces.length})', 'all'),
              const SizedBox(width: 6),
              _buildCategoryChip('🏆 Grand Toury ($gtCount)', 'grandTour'),
              const SizedBox(width: 6),
              _buildCategoryChip('🏛️ Monumenty ($monumentCount)', 'monument'),
              const SizedBox(width: 6),
              _buildCategoryChip('⏱️ WorldTour Etapowe ($wtStageCount)', 'worldTourStageRace'),
              const SizedBox(width: 6),
              _buildCategoryChip('🏁 WorldTour 1-dniowe ($wtOneDayCount)', 'worldTourOneDay'),
              const SizedBox(width: 6),
              _buildCategoryChip('🚴 ProSeries & Klasa 1 ($proCount)', 'proSeries'),
              const SizedBox(width: 6),
              _buildCategoryChip('⭐ Moja Drużyna ($myTeamCount)', 'myTeam'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String key) {
    final isSelected = _categoryFilter == key;
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
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
      ),
      onSelected: (_) {
        setState(() {
          _categoryFilter = key;
        });
      },
    );
  }

  // ===========================================================================
  // 4. KARTA WYŚCIGU (RACE CARD)
  // ===========================================================================

  Widget _buildRaceCard({
    required BuildContext context,
    required TourRace race,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final bool isPlayerRegistered =
        race.participatingTeamIds.contains(save.playerTeamId);
    final WildcardStatus status = careerController.getRaceWildcardStatus(race);
    final RaceOrganizer organizer =
        RaceCalendarSelectionService.getOrganizerForRace(race);
    final bool isCompleted = save.calendar.isRaceCompleted(race.id);
    final bool isActive = save.calendar.isRaceActive(race.id);
    final bool isExpanded = _expandedRaceIds.contains(race.id);

    // Znajdź zaplanowany skład dla tego wyścigu (jeśli istnieje w dedicatedSquads)
    final plannedSquad = save.dedicatedSquads.firstWhere(
      (s) => s.targetSeasonObjective == race.id || s.name == 'Skład: ${race.name}',
      orElse: () => const DedicatedSquad(
        id: '',
        name: '',
        leaderRiderId: '',
        domestiqueRiderIds: [],
        targetSeasonObjective: '',
      ),
    );
    final bool hasPlannedSquad = plannedSquad.id.isNotEmpty;
    final int plannedCount = hasPlannedSquad ? plannedSquad.allRiderIds.length : 0;

    // Styl kategorii i ikona
    final categoryMeta = _getCategoryMetadata(race);
    final Color categoryColor = categoryMeta.color;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF261D10)
            : (isPlayerRegistered ? const Color(0xFF161922) : AppColors.surface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.goldAccent
              : (isPlayerRegistered ? AppColors.goldAccent.withValues(alpha: 0.4) : AppTheme.borderColor),
          width: isActive ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Górna belka karty
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data startu kafelka
                _buildDateBadge(race: race, isActive: isActive, isCompleted: isCompleted),
                const SizedBox(width: 12),

                // Środek: Nazwa, kategoria, organizator, parametry
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategoria i organizator
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(categoryMeta.icon, size: 10, color: categoryColor),
                                const SizedBox(width: 4),
                                Text(
                                  categoryMeta.title.toUpperCase(),
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Flaga / Kraj
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_getCountryFlagEmoji(race.countryIso)} ${race.countryIso.toUpperCase()}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Organizator (ASO, RCS itp.)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: _parseHexColor(organizer.badgeColorHex).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              organizer.name.split(' ').first,
                              style: TextStyle(
                                color: _parseHexColor(organizer.badgeColorHex),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Nazwa wyścigu
                      Text(
                        race.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Dystans, etapy, przewyższenie i nagrody
                      Text(
                        '${race.stages.length == 1 ? "1 dzień" : "${race.stages.length} etapów"} • ${race.totalRaceDistanceKm.round()} km • ${race.totalRaceElevationGainM.round()} m w pionie • Pula: €${_formatCompactCurrency(race.prizePoolEur)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Prawa strona: plakietka statusu
                _buildStatusBadge(
                  status: status,
                  isPlayerRegistered: isPlayerRegistered,
                  isCompleted: isCompleted,
                  isActive: isActive,
                  historyEntry: save.calendar.raceHistory[race.id],
                ),
              ],
            ),
          ),

          // Pasek podglądu składu i akcji
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF13151D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                // Podgląd składu (jeśli drużyna zarejestrowana)
                Expanded(
                  child: isPlayerRegistered
                      ? _buildSquadPreviewPill(
                          race: race,
                          save: save,
                          hasPlannedSquad: hasPlannedSquad,
                          plannedSquad: plannedSquad,
                        )
                      : Text(
                          status == WildcardStatus.eligibleToApply
                              ? 'Wymaga zaproszenia od organizatora (${organizer.name})'
                              : 'Brak zgłoszenia drużyny',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),

                // Przyciski akcji
                _buildRaceCardActions(
                  context: context,
                  race: race,
                  save: save,
                  status: status,
                  isPlayerRegistered: isPlayerRegistered,
                  careerController: careerController,
                  hasPlannedSquad: hasPlannedSquad,
                  plannedCount: plannedCount,
                  isExpanded: isExpanded,
                ),
              ],
            ),
          ),

          // Rozwijana lista etapów wyścigu
          if (isExpanded)
            _buildStagesExpansion(race: race, isGrandTour: race.isGrandTour),
        ],
      ),
    );
  }

  Widget _buildDateBadge({
    required TourRace race,
    required bool isActive,
    required bool isCompleted,
  }) {
    final String monthShort = _getMonthShortName(race.startMonth);

    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.goldAccent
            : (isCompleted ? AppColors.surfaceLight : const Color(0xFF1D2230)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.goldAccent : Colors.white12,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${race.startDay}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isActive ? Colors.black : AppColors.goldAccent,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            monthShort,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.black87 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required WildcardStatus status,
    required bool isPlayerRegistered,
    required bool isCompleted,
    required bool isActive,
    RaceHistoryEntry? historyEntry,
  }) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.goldAccent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_filled_rounded, size: 12, color: Colors.black),
            SizedBox(width: 4),
            Text(
              'W TRAKCIE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'UKOŃCZONY',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (historyEntry != null)
              Text(
                '🏆 ${historyEntry.winnerRiderName}',
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      );
    }

    // Status Dzikiej Karty i prawa startu
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case WildcardStatus.automaticEntry:
        badgeColor = _cyanAccent;
        badgeText = 'Gwarantowany Start (WT)';
        badgeIcon = Icons.verified_rounded;
        break;
      case WildcardStatus.granted:
        badgeColor = AppColors.powerZone3;
        badgeText = 'Dzika Karta Przyznana';
        badgeIcon = Icons.check_circle_rounded;
        break;
      case WildcardStatus.pending:
        badgeColor = const Color(0xFFFFB74D);
        badgeText = 'Wniosek Rozpatrywany';
        badgeIcon = Icons.hourglass_top_rounded;
        break;
      case WildcardStatus.rejected:
        badgeColor = _accentRed;
        badgeText = 'Wildcard Odrzucony';
        badgeIcon = Icons.cancel_rounded;
        break;
      case WildcardStatus.eligibleToApply:
        badgeColor = AppColors.goldAccent;
        badgeText = 'Wymaga Wildcard';
        badgeIcon = Icons.assignment_outlined;
        break;
      case WildcardStatus.notEligible:
        badgeColor = AppColors.textSecondary;
        badgeText = 'Brak Uprawnień';
        badgeIcon = Icons.block_rounded;
        break;
      case WildcardStatus.withdrawn:
        badgeColor = AppColors.textSecondary;
        badgeText = 'Wycofany';
        badgeIcon = Icons.remove_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 11, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadPreviewPill({
    required TourRace race,
    required CareerSave save,
    required bool hasPlannedSquad,
    required DedicatedSquad plannedSquad,
  }) {
    final requiredCount = race.ridersPerTeam;

    if (!hasPlannedSquad || plannedSquad.allRiderIds.isEmpty) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF332211),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.goldAccent),
                SizedBox(width: 4),
                Text(
                  'Skład nieustalony',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '(wymagane $requiredCount kolarzy)',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      );
    }

    final count = plannedSquad.allRiderIds.length;
    final isFull = count == requiredCount;
    final leader = save.playerRoster.firstWhere(
      (r) => r.id == plannedSquad.leaderRiderId,
      orElse: () => save.playerRoster.first,
    );

    return Row(
      children: [
        // Plakietka z liczbą kolarzy
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isFull
                ? AppColors.powerZone3.withValues(alpha: 0.15)
                : const Color(0xFF332211),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isFull ? AppColors.powerZone3 : AppColors.goldAccent,
            ),
          ),
          child: Text(
            '$count / $requiredCount kolarzy',
            style: TextStyle(
              color: isFull ? AppColors.powerZone3 : AppColors.goldAccent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Lider składu
        Text(
          'Lider: 👑 ${leader.lastName}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRaceCardActions({
    required BuildContext context,
    required TourRace race,
    required CareerSave save,
    required WildcardStatus status,
    required bool isPlayerRegistered,
    required CareerController careerController,
    required bool hasPlannedSquad,
    required int plannedCount,
    required bool isExpanded,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Przycisk Planera Składu (jeśli drużyna zarejestrowana lub ma pewny start)
        if (isPlayerRegistered || status.hasGuaranteedEntry)
          ElevatedButton.icon(
            onPressed: () {
              _openRaceSquadPlanner(context, race, save, careerController);
            },
            icon: const Icon(Icons.group_add_rounded, size: 13, color: Colors.black),
            label: Text(
              hasPlannedSquad ? 'Zmień Skład ($plannedCount)' : 'Ustal Skład',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),

        // 2. Przycisk wnioskowania o Dziką Kartę
        if (!isPlayerRegistered && status.canSubmitApplication)
          ElevatedButton.icon(
            onPressed: () {
              _openWildcardEvaluationModal(context, race, save, careerController);
            },
            icon: const Icon(Icons.send_rounded, size: 13, color: Colors.black),
            label: const Text(
              'Wniosek o Wildcard',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),

        // 3. Jeśli wniosek oczekuje na decyzję - podgląd listu
        if (status == WildcardStatus.pending ||
            status == WildcardStatus.granted ||
            status == WildcardStatus.rejected)
          OutlinedButton.icon(
            onPressed: () {
              _openWildcardEvaluationModal(context, race, save, careerController);
            },
            icon: const Icon(Icons.description_outlined, size: 13, color: AppColors.goldAccent),
            label: const Text(
              'Pismo Dyrekcji',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldAccent),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.goldAccent),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),

        // 4. Samodzielna rejestracja (np. ProSeries lub Class 1)
        if (!isPlayerRegistered &&
            (race.uciCategory == RaceCategory.proSeries ||
                race.uciCategory == RaceCategory.class1) &&
            status != WildcardStatus.notEligible)
          TextButton(
            onPressed: () {
              careerController.registerForRace(race.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Drużyna ${save.playerTeam.name} została zgłoszona do wyścigu ${race.name}!'),
                  backgroundColor: AppColors.powerZone3,
                ),
              );
            },
            child: const Text('Zgłoś drużynę', style: TextStyle(fontSize: 11, color: _cyanAccent)),
          ),

        const SizedBox(width: 4),

        // Przełącznik rozwijania etapów
        IconButton(
          icon: Icon(
            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              if (isExpanded) {
                _expandedRaceIds.remove(race.id);
              } else {
                _expandedRaceIds.add(race.id);
              }
            });
          },
          tooltip: 'Pokaż profil i listę etapów',
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. ROZWIJANA LISTA ETAPÓW WYŚCIGU (STAGE BREAKDOWN)
  // ===========================================================================

  Widget _buildStagesExpansion({
    required TourRace race,
    required bool isGrandTour,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1118),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HARMONOGRAM ETAPÓW (${race.stages.length})',
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'Razem: ${race.totalRaceDistanceKm.round()} km • ${race.totalRaceElevationGainM.round()} m przewyższenia',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: race.stages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (ctx, idx) {
              final stage = race.stages[idx];
              final stageTypeMeta = _getStageTypeMetadata(stage.stageType);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    // Numer etapu
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: stageTypeMeta.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${stage.stageNumber}',
                        style: TextStyle(
                          color: stageTypeMeta.color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Nazwa etapu
                    Expanded(
                      child: Text(
                        stage.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Profil etapu
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stageTypeMeta.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(stageTypeMeta.icon, size: 10, color: stageTypeMeta.color),
                          const SizedBox(width: 4),
                          Text(
                            stageTypeMeta.label,
                            style: TextStyle(
                              color: stageTypeMeta.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Dystans i metry
                    Text(
                      '${stage.totalDistanceKm.round()} km  •  ${stage.totalElevationGainM.round()} m',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. MODAL: WNIOSEK O DZIKĄ KARTĘ (WILDCARD EVALUATION)
  // ===========================================================================

  void _openWildcardEvaluationModal(
    BuildContext context,
    TourRace race,
    CareerSave save,
    CareerController careerController,
  ) {
    final organizer = RaceCalendarSelectionService.getOrganizerForRace(race);
    final evaluation = careerController.evaluateWildcardForRace(race);
    final existingApplication = save.wildcardApplications.firstWhere(
      (a) => a.raceId == race.id && a.teamId == save.playerTeamId,
      orElse: () => WildcardApplication(
        id: '',
        raceId: race.id,
        raceName: race.name,
        teamId: save.playerTeamId,
        teamName: save.playerTeam.name,
        applicationDate: DateTime.now(),
        status: WildcardStatus.eligibleToApply,
        overallScore: evaluation?.overallScore ?? 50.0,
        rankingScore: evaluation?.rankingScore ?? 50.0,
        nationalityScore: evaluation?.nationalityScore ?? 50.0,
        combativityScore: evaluation?.combativityScore ?? 50.0,
        rosterStarScore: evaluation?.rosterStarScore ?? 50.0,
        directorQuote: evaluation?.directorQuote ?? '',
        officialLetter: evaluation?.officialLetter ?? '',
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final app = save.wildcardApplications.firstWhere(
              (a) => a.raceId == race.id && a.teamId == save.playerTeamId,
              orElse: () => existingApplication,
            );
            final currentStatus = app.status;

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Color(0xFF141722),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: AppColors.goldAccent, width: 2)),
              ),
              child: Column(
                children: [
                  // Belka nagłówka modalu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_turned_in_rounded,
                            color: AppColors.goldAccent, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WNIOSEK O DZIKĄ KARTĘ: ${race.name}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Organizator: ${organizer.name} (${organizer.countryIso}) • Dyrektor: ${organizer.directorName}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),

                  // Główna treść
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filozofia organizatora
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.format_quote_rounded,
                                    size: 20, color: AppColors.goldAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '"${organizer.philosophy}"',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Szanse ogólne (Probability Gauge)
                          if (evaluation != null) ...[
                            _buildEvaluationSummaryBox(evaluation),
                            const SizedBox(height: 16),

                            // Rozbicie 4 filarów
                            const Text(
                              '4 KRYTERIA OCENY PRZEZ KOMITET ORGANIZACYJNY',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 10),

                            _buildEvaluationPillarRow(
                              title: '1. Pozycja w Rankingu UCI & Punkty Sezonu',
                              weightDesc: '35% wagi decyzji',
                              score: evaluation.rankingScore,
                              icon: Icons.leaderboard_rounded,
                              color: _cyanAccent,
                            ),
                            const SizedBox(height: 8),

                            _buildEvaluationPillarRow(
                              title: '2. Zbieżność Narodowościowa ze Sponsorem & Bazą',
                              weightDesc: '30% wagi decyzji',
                              score: evaluation.nationalityScore,
                              icon: Icons.flag_rounded,
                              color: AppColors.goldAccent,
                            ),
                            const SizedBox(height: 8),

                            _buildEvaluationPillarRow(
                              title: '3. Waleczność, Harcownicy & Styl Ucieczek',
                              weightDesc: '20% wagi decyzji',
                              score: evaluation.combativityScore,
                              icon: Icons.bolt_rounded,
                              color: const Color(0xFFFF7043),
                            ),
                            const SizedBox(height: 8),

                            _buildEvaluationPillarRow(
                              title: '4. Gwiazdy Światowej Klasy w Zespole',
                              weightDesc: '15% wagi decyzji',
                              score: evaluation.rosterStarScore,
                              icon: Icons.star_rounded,
                              color: const Color(0xFFBA68C8),
                            ),
                            const SizedBox(height: 16),

                            // Mocne i słabe strony
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildProsConsList(
                                    title: 'Mocne strony kandydatury',
                                    items: evaluation.strengths,
                                    isPositive: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildProsConsList(
                                    title: 'Czynniki ryzyka / Słabości',
                                    items: evaluation.weaknesses,
                                    isPositive: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Podgląd oficjalnego pisma (jeśli wniosek złożony)
                          if (currentStatus != WildcardStatus.eligibleToApply &&
                              app.officialLetter.isNotEmpty) ...[
                            const Text(
                              'OFICJALNY KOMUNIKAT DYREKCJI WYŚCIGU',
                              style: TextStyle(
                                color: AppColors.goldAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1C16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.mark_email_read_rounded,
                                          color: AppColors.goldAccent, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Decyzja komitetu: ${currentStatus.label.toUpperCase()}',
                                        style: TextStyle(
                                          color: currentStatus == WildcardStatus.granted
                                              ? AppColors.powerZone3
                                              : (currentStatus == WildcardStatus.pending
                                                  ? AppColors.goldAccent
                                                  : _accentRed),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    app.officialLetter,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Dolna belka akcji
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppTheme.borderColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          child: const Text('Zamknij', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        if (currentStatus == WildcardStatus.eligibleToApply)
                          ElevatedButton.icon(
                            onPressed: () {
                              final submittedApp = careerController.applyForWildcard(race.id);
                              if (submittedApp != null) {
                                setModalState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Wniosek o Dziką Kartę na ${race.name} został oficjalnie złożony w komitecie organizacyjnym!',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    backgroundColor: AppColors.goldAccent,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.send_rounded, size: 15, color: Colors.black),
                            label: const Text(
                              'Złóż Oficjalny Wniosek do Organizatora',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Status: ${currentStatus.label}',
                              style: const TextStyle(
                                color: AppColors.goldAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildEvaluationSummaryBox(WildcardEvaluation evaluation) {
    final score = evaluation.overallScore;
    final bool isHigh = score >= 65.0;
    final bool isMedium = score >= 45.0 && score < 65.0;

    final Color statusColor =
        isHigh ? AppColors.powerZone3 : (isMedium ? AppColors.goldAccent : _accentRed);
    final String statusText =
        isHigh ? 'WYSOKIE PRAWDOPODOBIEŃSTWO PRZYZNANIA' : (isMedium ? 'UMIARKOWANE SZANSE (WALKA O SLOT)' : 'RYZYKO ODRZUCENIA WNIOSKU');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Zegar / Licznik punktów
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 2.5),
            ),
            child: Text(
              '${score.toStringAsFixed(0)}%',
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ogólny wskaźnik szans: ${score.toStringAsFixed(1)} / 100 pkt. Organizator dysponuje 4 dzikimi kartami dla całej stawki ProTeam.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationPillarRow({
    required String title,
    required String weightDesc,
    required double score,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '${score.toStringAsFixed(1)} pkt',
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Pasek postępu
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (score / 100.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                weightDesc,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProsConsList({
    required String title,
    required List<String> items,
    required bool isPositive,
  }) {
    final color = isPositive ? AppColors.powerZone3 : _accentRed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Brak kluczowych czynników', style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5))
          else
            ...items.map(
              (it) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                      size: 11,
                      color: color,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        it,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10.5,
                          height: 1.25,
                        ),
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

  // ===========================================================================
  // 7. MODAL: PLANER SKŁADU WYŚCIGOWEGO (RACE SQUAD PLANNER)
  // ===========================================================================

  void _openRaceSquadPlanner(
    BuildContext context,
    TourRace race,
    CareerSave save,
    CareerController careerController,
  ) {
    // Odczytaj aktualny skład z dedicatedSquads jeśli istnieje
    final existingSquad = save.dedicatedSquads.firstWhere(
      (s) => s.targetSeasonObjective == race.id || s.name == 'Skład: ${race.name}',
      orElse: () => DedicatedSquad(
        id: '',
        name: '',
        leaderRiderId: '',
        domestiqueRiderIds: const [],
        targetSeasonObjective: race.id,
      ),
    );

    final playerRoster = save.playerRoster;
    final int requiredRidersCount = race.ridersPerTeam; // zazwyczaj 7 lub 8

    // Stan lokalny wyboru składu w modalu
    final Set<String> selectedRiderIds = existingSquad.allRiderIds.isNotEmpty
        ? Set<String>.from(existingSquad.allRiderIds)
        : <String>{};

    String designatedLeaderId = existingSquad.leaderRiderId.isNotEmpty
        ? existingSquad.leaderRiderId
        : (selectedRiderIds.isNotEmpty ? selectedRiderIds.first : '');

    String designatedSprinterId = '';
    // Wybierz domyślnego sprintera jeśli mamy sprinterów w wybranym składzie
    for (final rId in selectedRiderIds) {
      final r = playerRoster.firstWhere((rk) => rk.id == rId, orElse: () => playerRoster.first);
      if (r.specialization == RiderSpecialization.pureSprinter ||
          r.specialization == RiderSpecialization.versatileSprinter) {
        designatedSprinterId = r.id;
        break;
      }
    }

    String plannerRosterFilter = 'all'; // all, climbers, sprinters, domestiques, healthyOnly

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            // Przeliczanie metryk aktualnie wybranego składu
            final chosenRiders =
                playerRoster.where((r) => selectedRiderIds.contains(r.id)).toList();

            double avgFtp = 0.0;
            double avgWKg = 0.0;
            double climbingPowerWKg = 0.0;
            double sprintPowerWatts = 0.0;

            if (chosenRiders.isNotEmpty) {
              double ftpSum = 0.0;
              double wKgSum = 0.0;
              for (final r in chosenRiders) {
                final wKg = r.powerProfile.watts20m /
                    (r.physiology.weightKg > 0 ? r.physiology.weightKg : 70.0);
                ftpSum += r.powerProfile.watts20m;
                wKgSum += wKg;
              }
              avgFtp = ftpSum / chosenRiders.length;
              avgWKg = wKgSum / chosenRiders.length;

              // Najlepsi w górach
              final sortedClimbers = List<Rider>.from(chosenRiders)
                ..sort((a, b) {
                  final aW = a.powerProfile.watts20m / a.physiology.weightKg;
                  final bW = b.powerProfile.watts20m / b.physiology.weightKg;
                  return bW.compareTo(aW);
                });
              final top3Climbers = sortedClimbers.take(3);
              climbingPowerWKg = top3Climbers.fold(
                      0.0,
                      (s, r) =>
                          s + (r.powerProfile.watts20m / r.physiology.weightKg)) /
                  (top3Climbers.isNotEmpty ? top3Climbers.length : 1);

              // Najlepszy sprint
              sprintPowerWatts = chosenRiders.fold(
                  0.0, (maxW, r) => math.max(maxW, r.powerProfile.watts5s.toDouble()));
            }

            // Filtrowanie listy kolarzy
            final displayedRoster = playerRoster.where((r) {
              switch (plannerRosterFilter) {
                case 'healthyOnly':
                  return r.health.isFitToRace;
                case 'climbers':
                  return r.specialization == RiderSpecialization.gcClimber ||
                      r.specialization == RiderSpecialization.pureClimber;
                case 'sprinters':
                  return r.specialization == RiderSpecialization.pureSprinter ||
                      r.specialization == RiderSpecialization.versatileSprinter;
                case 'domestiques':
                  return r.specialization == RiderSpecialization.domestiqueEngine ||
                      r.specialization == RiderSpecialization.breakawaySpecialist;
                case 'all':
                default:
                  return true;
              }
            }).toList();

            final int currentCount = selectedRiderIds.length;
            final bool isTargetReached = currentCount == requiredRidersCount;

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Color(0xFF131620),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: AppColors.goldAccent, width: 2.5)),
              ),
              child: Column(
                children: [
                  // 1. Nagłówek planera
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.groups_rounded, color: AppColors.goldAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PLANER SKŁADU NA WYŚCIG: ${race.name}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${race.stages.length == 1 ? "Klasyk 1-dniowy" : "${race.stages.length} etapów"} • Wymóg UCI: dokładnie $requiredRidersCount kolarzy w drużynie',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Przycisk AI DS - Sugeruj Optymalny Skład
                        ElevatedButton.icon(
                          onPressed: () {
                            _autoSelectOptimalSquad(
                              race: race,
                              roster: playerRoster,
                              save: save,
                              requiredCount: requiredRidersCount,
                              onSelected: (newSelected, newLeader, newSprinter) {
                                setModalState(() {
                                  selectedRiderIds.clear();
                                  selectedRiderIds.addAll(newSelected);
                                  designatedLeaderId = newLeader;
                                  designatedSprinterId = newSprinter;
                                });
                              },
                            );
                          },
                          icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.black),
                          label: const Text(
                            'Sugeruj Skład (AI DS)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        const SizedBox(width: 8),

                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),

                  // 2. Belka telemetryczna wybranego składu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF191D2A),
                      border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                    ),
                    child: Column(
                      children: [
                        // Licznik kolarzy i pasek limitu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'POWOŁANI KOLARZE: $currentCount / $requiredRidersCount',
                                  style: TextStyle(
                                    color: isTargetReached
                                        ? AppColors.powerZone3
                                        : AppColors.goldAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (isTargetReached) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.check_circle_rounded,
                                      size: 14, color: AppColors.powerZone3),
                                ],
                              ],
                            ),
                            Text(
                              isTargetReached
                                  ? 'Skład kompletny do zatwierdzenia'
                                  : 'Pozostało miejsc: ${requiredRidersCount - currentCount}',
                              style: TextStyle(
                                color: isTargetReached
                                    ? AppColors.powerZone3
                                    : AppColors.textSecondary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Pasek zapełnienia
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (currentCount / requiredRidersCount).clamp(0.0, 1.0),
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isTargetReached ? AppColors.powerZone3 : AppColors.goldAccent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Statystyki pociągu
                        Row(
                          children: [
                            _buildSquadStatCard(
                              label: 'Średnie FTP',
                              value: '${avgFtp.toStringAsFixed(0)} W',
                              color: _cyanAccent,
                            ),
                            const SizedBox(width: 8),
                            _buildSquadStatCard(
                              label: 'Średnia W/kg',
                              value: '${avgWKg.toStringAsFixed(2)} W/kg',
                              color: AppColors.goldAccent,
                            ),
                            const SizedBox(width: 8),
                            _buildSquadStatCard(
                              label: 'Moc pociągu górskiego',
                              value: '${climbingPowerWKg.toStringAsFixed(2)} W/kg',
                              color: const Color(0xFFFF8A65),
                            ),
                            const SizedBox(width: 8),
                            _buildSquadStatCard(
                              label: 'Max sprint (5s)',
                              value: '${sprintPowerWatts.toStringAsFixed(0)} W',
                              color: const Color(0xFF69F0AE),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. Pasek filtrów kolarzy
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildModalFilterChip('Wszyscy (${playerRoster.length})', 'all',
                              plannerRosterFilter, (v) => setModalState(() => plannerRosterFilter = v)),
                          const SizedBox(width: 6),
                          _buildModalFilterChip('Tylko zdrowi', 'healthyOnly',
                              plannerRosterFilter, (v) => setModalState(() => plannerRosterFilter = v)),
                          const SizedBox(width: 6),
                          _buildModalFilterChip('Górale GC', 'climbers',
                              plannerRosterFilter, (v) => setModalState(() => plannerRosterFilter = v)),
                          const SizedBox(width: 6),
                          _buildModalFilterChip('Sprinterzy', 'sprinters',
                              plannerRosterFilter, (v) => setModalState(() => plannerRosterFilter = v)),
                          const SizedBox(width: 6),
                          _buildModalFilterChip('Lokomotywy / Rouleur', 'domestiques',
                              plannerRosterFilter, (v) => setModalState(() => plannerRosterFilter = v)),
                        ],
                      ),
                    ),
                  ),

                  // 4. Lista kolarzy z weryfikacją limitu dni wyścigowych i kontuzji
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      itemCount: displayedRoster.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final rider = displayedRoster[idx];
                        final bool isSelected = selectedRiderIds.contains(rider.id);
                        final bool isLeader = designatedLeaderId == rider.id;
                        final bool isSprinter = designatedSprinterId == rider.id;

                        // Weryfikacja medyczna
                        final bool isFit = rider.health.isFitToRace;
                        final Injury? injury = rider.health.currentInjury;

                        // Weryfikacja dni startowych w sezonie (limit 75 dni)
                        final int currentRaceDays = _getRiderAccumulatedRaceDays(save, rider.id);
                        final int daysAfterThisRace = currentRaceDays + race.stages.length;
                        final bool exceedsLimit = daysAfterThisRace > 75;
                        final bool nearLimit = daysAfterThisRace >= 65 && !exceedsLimit;

                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isLeader
                                    ? const Color(0xFF2C2210)
                                    : const Color(0xFF1C2230))
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isLeader
                                  ? AppColors.goldAccent
                                  : (isSelected
                                      ? _cyanAccent
                                      : AppTheme.borderColor),
                              width: isLeader || isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Awatar
                              RiderAvatarWidget(
                                appearance: rider.appearance,
                                team: save.playerTeam,
                                size: 40,
                                showHelmet: true,
                              ),
                              const SizedBox(width: 10),

                              // Informacje o kolarzu
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          rider.fullName,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getCountryFlagEmoji(rider.nationalityIso),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const SizedBox(width: 6),

                                        // Rola w wyścigu
                                        if (isLeader)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.goldAccent,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '👑 LIDER GC',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          )
                                        else if (isSprinter)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF69F0AE),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              '⚡ SPRINTER',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),

                                    // Parametry fizjologiczne
                                    Row(
                                      children: [
                                        Text(
                                          '${rider.specialization.name} • ${rider.physiology.weightKg.toStringAsFixed(1)} kg',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'FTP: ${rider.powerProfile.watts20m} W (${(rider.powerProfile.watts20m / rider.physiology.weightKg).toStringAsFixed(2)} W/kg)',
                                          style: const TextStyle(
                                            color: _cyanAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Pasek dni startowych & stan zdrowia
                                    Row(
                                      children: [
                                        // Wskaźnik dni startowych (max 75)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: exceedsLimit
                                                ? _accentRed.withValues(alpha: 0.15)
                                                : (nearLimit
                                                    ? AppColors.goldAccent.withValues(alpha: 0.15)
                                                    : AppColors.surfaceLight),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: exceedsLimit
                                                  ? _accentRed
                                                  : (nearLimit ? AppColors.goldAccent : Colors.white12),
                                            ),
                                          ),
                                          child: Text(
                                            exceedsLimit
                                                ? '⚠️ $daysAfterThisRace / 75 dni (PRZEMĘCZENIE!)'
                                                : '$daysAfterThisRace / 75 dni startowych',
                                            style: TextStyle(
                                              color: exceedsLimit
                                                  ? _accentRed
                                                  : (nearLimit ? AppColors.goldAccent : AppColors.textSecondary),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Status medyczny
                                        if (!isFit)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _accentRed.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: _accentRed),
                                            ),
                                            child: Text(
                                              '🚫 KONTUZJA: ${injury?.name ?? "Uraz"} (${injury?.daysRemaining ?? 1} dni)',
                                              style: const TextStyle(
                                                color: _accentRed,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          )
                                        else
                                          const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded, size: 10, color: AppColors.powerZone3),
                                              SizedBox(width: 3),
                                              Text(
                                                'Zdolny do startu',
                                                style: TextStyle(color: AppColors.powerZone3, fontSize: 9.5),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Przyciski roli (jeśli kolarz wybrany)
                              if (isSelected) ...[
                                IconButton(
                                  icon: Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 18,
                                    color: isLeader ? AppColors.goldAccent : AppColors.textSecondary,
                                  ),
                                  tooltip: 'Ustaw jako Lidera GC',
                                  onPressed: () {
                                    setModalState(() {
                                      designatedLeaderId = rider.id;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.flash_on_rounded,
                                    size: 18,
                                    color: isSprinter ? const Color(0xFF69F0AE) : AppColors.textSecondary,
                                  ),
                                  tooltip: 'Ustaw jako Głównego Sprintera',
                                  onPressed: () {
                                    setModalState(() {
                                      designatedSprinterId = isSprinter ? '' : rider.id;
                                    });
                                  },
                                ),
                              ],

                              // Checkbox wyboru kolarza
                              Checkbox(
                                value: isSelected,
                                activeColor: AppColors.goldAccent,
                                checkColor: Colors.black,
                                onChanged: (val) {
                                  if (!isFit) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Kolarz ${rider.fullName} jest kontuzjowany (${injury?.name}) i nie może wystartować!',
                                        ),
                                        backgroundColor: _accentRed,
                                      ),
                                    );
                                    return;
                                  }

                                  if (val == true) {
                                    if (selectedRiderIds.length >= requiredRidersCount) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Osiągnięto maksymalną liczbę kolarzy dla tego wyścigu ($requiredRidersCount). Odznacz innego zawodnika.',
                                          ),
                                          backgroundColor: _accentRed,
                                        ),
                                      );
                                      return;
                                    }
                                    setModalState(() {
                                      selectedRiderIds.add(rider.id);
                                      if (designatedLeaderId.isEmpty) {
                                        designatedLeaderId = rider.id;
                                      }
                                    });
                                  } else {
                                    setModalState(() {
                                      selectedRiderIds.remove(rider.id);
                                      if (designatedLeaderId == rider.id) {
                                        designatedLeaderId = selectedRiderIds.isNotEmpty
                                            ? selectedRiderIds.first
                                            : '';
                                      }
                                      if (designatedSprinterId == rider.id) {
                                        designatedSprinterId = '';
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 5. Dolna belka zapisu składu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppTheme.borderColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          child: const Text('Anuluj', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        ElevatedButton.icon(
                          onPressed: selectedRiderIds.isEmpty
                              ? null
                              : () {
                                  if (selectedRiderIds.length != requiredRidersCount) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Uwaga: Wybrano ${selectedRiderIds.length} z wymaganych $requiredRidersCount kolarzy. Zalecamy pełen skład.',
                                        ),
                                        backgroundColor: const Color(0xFFFFB74D),
                                      ),
                                    );
                                  }

                                  final leaderId = designatedLeaderId.isNotEmpty
                                      ? designatedLeaderId
                                      : selectedRiderIds.first;
                                  final domestiques = selectedRiderIds
                                      .where((id) => id != leaderId)
                                      .toList();

                                  careerController.saveRaceLineup(
                                    raceId: race.id,
                                    raceName: race.name,
                                    leaderRiderId: leaderId,
                                    domestiqueRiderIds: domestiques,
                                  );

                                  Navigator.pop(modalCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Skład drużyny ${save.playerTeam.name} na ${race.name} został pomyślnie zatwierdzony! (${selectedRiderIds.length} kolarzy)',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      backgroundColor: AppColors.powerZone3,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: Colors.black),
                          label: Text(
                            'Zatwierdź Skład na Wyścig (${selectedRiderIds.length}/$requiredRidersCount)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
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

  Widget _buildSquadStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalFilterChip(
    String label,
    String key,
    String currentKey,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = key == currentKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.black : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.goldAccent,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
      ),
      onSelected: (_) => onSelected(key),
    );
  }

  // ===========================================================================
  // 8. ALGORYTM ASYSTENTA DS (AUTO-SELECT OPTIMAL SQUAD)
  // ===========================================================================

  void _autoSelectOptimalSquad({
    required TourRace race,
    required List<Rider> roster,
    required CareerSave save,
    required int requiredCount,
    required void Function(Set<String> selected, String leader, String sprinter)
        onSelected,
  }) {
    // 1. Odrzuć kolarzy kontuzjowanych i przekraczających 75 dni
    final healthyCandidates = roster.where((r) {
      if (!r.health.isFitToRace) return false;
      final accDays = _getRiderAccumulatedRaceDays(save, r.id);
      if (accDays + race.stages.length > 78) return false; // unikaj ostrego przeciążenia
      return true;
    }).toList();

    if (healthyCandidates.isEmpty) return;

    // 2. Sortowanie wg profilu wyścigu
    final bool isClimbersRace = race.isGrandTour ||
        race.uciCategory == RaceCategory.worldTourStageRace ||
        race.totalRaceElevationGainM > 3500;

    final bool isCobbledRace = race.name.toLowerCase().contains('roubaix') ||
        race.name.toLowerCase().contains('flandr') ||
        race.name.toLowerCase().contains('e3');

    final chosen = <Rider>[];

    if (isCobbledRace) {
      // Wyścig brukowy: kluczowe cobbles i bike handling
      healthyCandidates.sort((a, b) {
        final aScore = a.skills.cobbles * 0.7 + a.skills.bikeHandling * 0.3;
        final bScore = b.skills.cobbles * 0.7 + b.skills.bikeHandling * 0.3;
        return bScore.compareTo(aScore);
      });
      chosen.addAll(healthyCandidates.take(requiredCount));
    } else if (isClimbersRace) {
      // Wyścig górski / Grand Tour: Lider GC + najlepsi wspinacze W/kg + czasowiec + pomocnicy
      healthyCandidates.sort((a, b) {
        final aW = a.powerProfile.watts20m / a.physiology.weightKg;
        final bW = b.powerProfile.watts20m / b.physiology.weightKg;
        return bW.compareTo(aW);
      });
      chosen.addAll(healthyCandidates.take(requiredCount));
    } else {
      // Wyścig sprinterski / płaski: Sprinterzy + pociąg
      healthyCandidates.sort((a, b) {
        final aSprint = a.powerProfile.watts5s;
        final bSprint = b.powerProfile.watts5s;
        return bSprint.compareTo(aSprint);
      });
      chosen.addAll(healthyCandidates.take(requiredCount));
    }

    final newSelectedIds = chosen.map((r) => r.id).toSet();

    // Wyznacz lidera (najwyższy rating lub W/kg)
    String leaderId = chosen.isNotEmpty ? chosen.first.id : '';
    // Wyznacz sprintera
    String sprinterId = '';
    for (final r in chosen) {
      if (r.specialization == RiderSpecialization.pureSprinter ||
          r.specialization == RiderSpecialization.versatileSprinter) {
        sprinterId = r.id;
        break;
      }
    }

    onSelected(newSelectedIds, leaderId, sprinterId);
  }

  // ===========================================================================
  // 9. POMOCNICZE OBLICZENIA I METADANE
  // ===========================================================================

  int _calculateTotalTeamRaceDays(CareerSave save) {
    int total = 0;
    for (final race in save.calendar.races) {
      if (race.participatingTeamIds.contains(save.playerTeamId)) {
        total += race.stages.length;
      }
    }
    return total;
  }

  int _getRiderAccumulatedRaceDays(CareerSave save, String riderId) {
    int days = 0;
    for (final race in save.calendar.races) {
      // Jeśli wyścig jest ukończony i gracz startował
      if (save.calendar.completedRaceIds.contains(race.id)) {
        if (race.participatingTeamIds.contains(save.playerTeamId)) {
          days += race.stages.length;
        }
      } else {
        // Dla zaplanowanych wyścigów sprawdź dedykowane składy
        final squad = save.dedicatedSquads.firstWhere(
          (s) => s.targetSeasonObjective == race.id || s.name == 'Skład: ${race.name}',
          orElse: () => const DedicatedSquad(
            id: '',
            name: '',
            leaderRiderId: '',
            domestiqueRiderIds: [],
            targetSeasonObjective: '',
          ),
        );
        if (squad.allRiderIds.contains(riderId)) {
          days += race.stages.length;
        }
      }
    }
    return days;
  }

  _CategoryMeta _getCategoryMetadata(TourRace race) {
    if (race.isGrandTour) {
      return const _CategoryMeta(
        title: 'Grand Tour (2.UWT)',
        color: Color(0xFFE5A93C),
        icon: Icons.emoji_events_rounded,
      );
    }
    if (race.uciCategory == RaceCategory.monument) {
      return const _CategoryMeta(
        title: 'Monument Kolarstwa (1.UWT)',
        color: Color(0xFFBA68C8),
        icon: Icons.account_balance_rounded,
      );
    }
    if (race.uciCategory == RaceCategory.worldTourStageRace) {
      return const _CategoryMeta(
        title: 'WorldTour Etapówka (2.UWT)',
        color: _cyanAccent,
        icon: Icons.speed_rounded,
      );
    }
    if (race.uciCategory == RaceCategory.worldTourOneDay) {
      return const _CategoryMeta(
        title: 'Klasyk WorldTour (1.UWT)',
        color: Color(0xFF64B5F6),
        icon: Icons.flag_rounded,
      );
    }
    if (race.uciCategory == RaceCategory.proSeries) {
      return const _CategoryMeta(
        title: 'UCI ProSeries (2.Pro / 1.Pro)',
        color: AppColors.powerZone3,
        icon: Icons.directions_bike_rounded,
      );
    }
    return const _CategoryMeta(
      title: 'Klasa UCI 1.1 / 2.1',
      color: AppColors.textSecondary,
      icon: Icons.timeline_rounded,
    );
  }

  _StageTypeMeta _getStageTypeMetadata(StageType type) {
    switch (type) {
      case StageType.flat:
        return const _StageTypeMeta('Płaski / Sprinterski', Icons.horizontal_rule_rounded, Color(0xFF69F0AE));
      case StageType.hilly:
        return const _StageTypeMeta('Pagórkowaty', Icons.show_chart_rounded, Color(0xFFFFB74D));
      case StageType.highMountain:
        return const _StageTypeMeta('Wysokogórski', Icons.terrain_rounded, Color(0xFFFF5252));
      case StageType.summitFinish:
        return const _StageTypeMeta('Meta na podjeździe', Icons.vertical_align_top_rounded, Color(0xFFE040FB));
      case StageType.individualTimeTrial:
        return const _StageTypeMeta('Jazda na Czas (ITT)', Icons.timer_outlined, _cyanAccent);
      case StageType.teamTimeTrial:
        return const _StageTypeMeta('Drużynowa na Czas (TTT)', Icons.group_work_rounded, _cyanAccent);
      case StageType.cobbleClassic:
        return const _StageTypeMeta('Brukowy', Icons.view_module_rounded, AppColors.goldAccent);
    }
  }

  String _getMonthShortName(int month) {
    switch (month) {
      case 1:
        return 'STY';
      case 2:
        return 'LUT';
      case 3:
        return 'MAR';
      case 4:
        return 'KWI';
      case 5:
        return 'MAJ';
      case 6:
        return 'CZE';
      case 7:
        return 'LIP';
      case 8:
        return 'SIE';
      case 9:
        return 'WRZ';
      case 10:
        return 'PAŹ';
      case 11:
        return 'LIS';
      case 12:
        return 'GRU';
      default:
        return 'M$month';
    }
  }

  String _formatCompactCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000.0).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000.0).toStringAsFixed(0)}k';
    }
    return '$amount';
  }

  Color _parseHexColor(String hexString, {Color fallback = AppColors.goldAccent}) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _getCountryFlagEmoji(String countryIso) {
    final code = countryIso.toUpperCase();
    switch (code) {
      case 'FR':
        return '🇫🇷';
      case 'IT':
        return '🇮🇹';
      case 'ES':
        return '🇪🇸';
      case 'BE':
        return '🇧🇪';
      case 'NL':
        return '🇳🇱';
      case 'PL':
        return '🇵🇱';
      case 'CH':
        return '🇨🇭';
      case 'GB':
      case 'UK':
        return '🇬🇧';
      case 'DE':
        return '🇩🇪';
      case 'DK':
        return '🇩🇰';
      case 'NO':
        return '🇳🇴';
      case 'SI':
        return '🇸🇮';
      case 'CO':
        return '🇨🇴';
      case 'US':
        return '🇺🇸';
      case 'AU':
        return '🇦🇺';
      case 'AE':
        return '🇦🇪';
      case 'CA':
        return '🇨🇦';
      default:
        return '🌍';
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text(
            'Brak wyścigów spełniających wybrane kryteria',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Zmień wybrany miesiąc lub filtr kategorii, aby zobaczyć pozostałe wyścigi sezonu.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedMonth = null;
                _categoryFilter = 'all';
                _searchQuery = '';
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.goldAccent),
            ),
            child: const Text('Zresetuj filtry', style: TextStyle(color: AppColors.goldAccent, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _CategoryMeta {
  final String title;
  final Color color;
  final IconData icon;

  const _CategoryMeta({
    required this.title,
    required this.color,
    required this.icon,
  });
}

class _StageTypeMeta {
  final String label;
  final IconData icon;
  final Color color;

  const _StageTypeMeta(this.label, this.icon, this.color);
}
