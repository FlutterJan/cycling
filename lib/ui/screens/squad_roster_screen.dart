import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../state/career_controller.dart';
import '../widgets/power_curve_chart_widget.dart';
import '../widgets/rider_avatar_painter.dart';
import 'rider_detail_screen.dart';
import 'team_builder_hierarchy_screen.dart';

/// Kryteria sortowania kolarzy w kadrze
enum RosterSortCriteria {
  lastName('Nazwisko (A-Z)', defaultAscending: true),
  ftp('FTP (W)', defaultAscending: false),
  wKg('Moc na wagę (W/kg)', defaultAscending: false),
  tsb('Świeżość (TSB)', defaultAscending: false),
  form('Forma (CTL)', defaultAscending: false),
  fatigue('Zmęczenie (ATL)', defaultAscending: true),
  age('Wiek', defaultAscending: true),
  weight('Waga (kg)', defaultAscending: true),
  salary('Pensja (€/rok)', defaultAscending: false),
  contractEnd('Koniec kontraktu', defaultAscending: true),
  potential('Potencjał', defaultAscending: false);

  final String label;
  final bool defaultAscending;

  const RosterSortCriteria(this.label, {required this.defaultAscending});
}

/// Ekran zarządzania kadrą zespołu (Squad Roster Screen).
/// Wyświetla listę wszystkich kolarzy w drużynie w formie siatki kart lub profesjonalnej tabeli:
/// - Portrety wektorowe (RiderAvatarWidget),
/// - Rola w drużynie i specjalizacja,
/// - Waga, FTP (W i W/kg),
/// - Forma, zmęczenie i wskaźnik świeżości (TSB = CTL - ATL),
/// - Stan zdrowia (kontuzje / dni rekonwalescencji),
/// - Długość kontraktu i zarobki,
/// - Filtrowanie wg specjalizacji (Górale, Sprinterzy, Klasykowcy, Czasowcy, Pomocnicy, Kontuzjowani),
/// - Sortowanie wg dowolnej statystyki,
/// - Podgląd Krzywej Mocy (PDC) i zmiana roli zawodnika.
class SquadRosterScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const SquadRosterScreen({
    super.key,
    this.showAppBar = false,
  });

  @override
  ConsumerState<SquadRosterScreen> createState() => _SquadRosterScreenState();
}

class _SquadRosterScreenState extends ConsumerState<SquadRosterScreen> {
  // Filtrowanie i sortowanie
  String _specializationFilter = 'all'; // all, climbers, sprinters, classics, timeTrialists, domestiques, injured
  RosterSortCriteria _sortCriteria = RosterSortCriteria.wKg;
  bool _isAscending = false;
  String _searchQuery = '';
  bool _isTableView = false;

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

    final playerTeam = save.playerTeam;
    final allRoster = save.playerRoster;

    // 1. Filtrowanie
    final filteredRoster = allRoster.where((rider) {
      // Filtr tekstowy (Imię / Nazwisko / Kraj)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = rider.fullName.toLowerCase().contains(q);
        final matchCountry = rider.countryIso.toLowerCase().contains(q);
        final matchSpec = _getSpecializationLabel(rider.specialization).toLowerCase().contains(q);
        if (!matchName && !matchCountry && !matchSpec) return false;
      }

      // Filtr specjalizacji
      return _matchesSpecializationFilter(rider, _specializationFilter);
    }).toList();

    // 2. Sortowanie
    filteredRoster.sort((a, b) => _compareRiders(a, b, _sortCriteria, _isAscending));

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Górny pasek podsumowania kadry (KPI drużyny)
              _buildRosterSummaryKpiBar(allRoster),
              const SizedBox(height: 16),

              // 2. Pasek narzędzi: Filtry specjalizacji, Wyszukiwarka, Sortowanie, Przełącznik widoku
              _buildToolbar(
                context: context,
                allRoster: allRoster,
                isDesktop: isDesktop,
              ),
              const SizedBox(height: 16),

              // 3. Główna zawartość: Tabela lub Siatka Kart
              if (filteredRoster.isEmpty)
                _buildEmptyState()
              else if (_isTableView)
                _buildProTableView(
                  context: context,
                  save: save,
                  playerTeam: playerTeam,
                  riders: filteredRoster,
                  careerController: careerController,
                )
              else
                _buildCardGridView(
                  context: context,
                  save: save,
                  playerTeam: playerTeam,
                  riders: filteredRoster,
                  careerController: careerController,
                  constraints: constraints,
                ),
            ],
          ),
        );
      },
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Zarządzanie Kadrą Zespołu'),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: content,
      );
    }

    return content;
  }

  // ===========================================================================
  // 1. PASEK PODSUMOWANIA KADRY (ROSTER KPI BAR)
  // ===========================================================================

  Widget _buildRosterSummaryKpiBar(List<Rider> roster) {
    if (roster.isEmpty) return const SizedBox.shrink();

    final int count = roster.length;
    final double avgFtp = roster.fold<double>(0.0, (s, r) => s + r.physiology.ftpWatts) / count;
    final double avgWeight = roster.fold<double>(0.0, (s, r) => s + r.physiology.weightKg) / count;
    final double avgWKg = avgWeight > 0 ? avgFtp / avgWeight : 0.0;
    final double avgAge = roster.fold<double>(0.0, (s, r) => s + r.age) / count;
    final int totalSalary = roster.fold<int>(0, (s, r) => s + r.contract.annualSalaryEur);
    final int injuredCount = roster.where((r) => r.health.currentInjury != null).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildKpiItem('KADRA', '$count kolarzy', Icons.people_alt_rounded, AppColors.goldAccent),
          const SizedBox(width: 12),
          _buildKpiItem('ŚR. FTP', '${avgFtp.round()} W', Icons.bolt_rounded, AppColors.cyanAccent),
          const SizedBox(width: 12),
          _buildKpiItem('ŚR. W/KG', '${avgWKg.toStringAsFixed(2)} W/kg', Icons.speed_rounded, AppColors.powerZone3),
          const SizedBox(width: 12),
          _buildKpiItem('ŚR. WIEK', '${avgAge.toStringAsFixed(1)} lat', Icons.cake_rounded, AppColors.textPrimary),
          const SizedBox(width: 12),
          _buildKpiItem('BUDŻET PŁAC', '€${(totalSalary / 1000000).toStringAsFixed(2)}M/rok', Icons.account_balance_wallet_rounded, AppColors.powerZone3),
          if (injuredCount > 0) ...[
            const SizedBox(width: 12),
            _buildKpiItem('KONTUZJE', '$injuredCount w rekonwalescencji', Icons.medical_services_rounded, AppColors.powerZone6),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
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

  // ===========================================================================
  // 2. PASEK NARZĘDZI: FILTRY, WYSZUKIWARKA, SORTOWANIE, PRZEŁĄCZNIK WIDOKU
  // ===========================================================================

  Widget _buildToolbar({
    required BuildContext context,
    required List<Rider> allRoster,
    required bool isDesktop,
  }) {
    // Liczniki dla poszczególnych specjalizacji
    final climbersCount = allRoster.where((r) => _matchesSpecializationFilter(r, 'climbers')).length;
    final sprintersCount = allRoster.where((r) => _matchesSpecializationFilter(r, 'sprinters')).length;
    final classicsCount = allRoster.where((r) => _matchesSpecializationFilter(r, 'classics')).length;
    final ttCount = allRoster.where((r) => _matchesSpecializationFilter(r, 'timeTrialists')).length;
    final domestiquesCount = allRoster.where((r) => _matchesSpecializationFilter(r, 'domestiques')).length;
    final injuredCount = allRoster.where((r) => r.health.currentInjury != null).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Górny wiersz paska: Wyszukiwarka, Dropdown Sortowania i Przełącznik Widoku
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Pole wyszukiwania
              SizedBox(
                width: isDesktop ? 320 : 240,
                height: 38,
                child: TextField(
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Szukaj kolarza po nazwisku, kraju lub roli...',
                      hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14, color: AppColors.textSecondary),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

              // Dropdown sortowania
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort_rounded, size: 15, color: AppColors.goldAccent),
                      const SizedBox(width: 6),
                      const Text('Sortuj: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Flexible(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<RosterSortCriteria>(
                            isExpanded: true,
                            value: _sortCriteria,
                        dropdownColor: AppColors.surfaceLight,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.goldAccent, size: 18),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                        items: RosterSortCriteria.values.map((criteria) {
                          return DropdownMenuItem(
                            value: criteria,
                            child: Text(criteria.label),
                          );
                        }).toList(),
                        onChanged: (newCriteria) {
                          if (newCriteria != null) {
                            setState(() {
                              if (_sortCriteria == newCriteria) {
                                _isAscending = !_isAscending;
                              } else {
                                _sortCriteria = newCriteria;
                                _isAscending = newCriteria.defaultAscending;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(width: 8),

              // Przycisk kierunku sortowania (Rosnąco / Malejąco)
              IconButton(
                icon: Icon(
                  _isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: AppColors.goldAccent,
                  size: 18,
                ),
                tooltip: _isAscending ? 'Kolejność: Rosnąco' : 'Kolejność: Malejąco',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() => _isAscending = !_isAscending);
                },
              ),
              const SizedBox(width: 12),

              // Przełącznik: Siatka Kart vs Tabela Pro
              Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewTogglePill(
                      icon: Icons.grid_view_rounded,
                      label: 'Karty',
                      isSelected: !_isTableView,
                      onTap: () => setState(() => _isTableView = false),
                    ),
                    const SizedBox(width: 4),
                    _buildViewTogglePill(
                      icon: Icons.table_rows_rounded,
                      label: 'Tabela Pro',
                      isSelected: _isTableView,
                      onTap: () => setState(() => _isTableView = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Przycisk otwierający Budowę Zespołu i Hierarchię
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeamBuilderHierarchyScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.hub_rounded, size: 15),
                label: const Text('Hierarchia & Pociągi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2638),
                  foregroundColor: AppColors.goldAccent,
                  side: const BorderSide(color: AppColors.goldAccent, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dolny wiersz: Pigułki filtrów specjalizacji
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Wszyscy (${allRoster.length})', 'all', Icons.groups_rounded),
                const SizedBox(width: 8),
                _buildFilterChip('Górale ($climbersCount)', 'climbers', Icons.terrain_rounded),
                const SizedBox(width: 8),
                _buildFilterChip('Sprinterzy ($sprintersCount)', 'sprinters', Icons.bolt_rounded),
                const SizedBox(width: 8),
                _buildFilterChip('Klasykowcy ($classicsCount)', 'classics', Icons.handyman_rounded),
                const SizedBox(width: 8),
                _buildFilterChip('Czasowcy ($ttCount)', 'timeTrialists', Icons.timer_rounded),
                const SizedBox(width: 8),
                _buildFilterChip('Pomocnicy ($domestiquesCount)', 'domestiques', Icons.shield_rounded),
                if (injuredCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildFilterChip('Kontuzjowani ($injuredCount)', 'injured', Icons.medical_services_rounded, isWarning: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTogglePill({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, IconData icon, {bool isWarning = false}) {
    final isSelected = _specializationFilter == key;
    final activeColor = isWarning ? AppColors.powerZone6 : AppColors.goldAccent;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 13,
        color: isSelected ? Colors.black : (isWarning ? AppColors.powerZone6 : AppColors.textSecondary),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          color: isSelected ? Colors.black : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide(color: isSelected ? activeColor : AppTheme.borderColor),
      onSelected: (_) {
        setState(() => _specializationFilter = key);
      },
    );
  }

  // ===========================================================================
  // 3. WIDOK SIATKI KART (CARD GRID VIEW)
  // ===========================================================================

  Widget _buildCardGridView({
    required BuildContext context,
    required CareerSave save,
    required CyclingTeam playerTeam,
    required List<Rider> riders,
    required CareerController careerController,
    required BoxConstraints constraints,
  }) {
    // Określenie liczby kolumn w zależności od szerokości ekranu
    int crossAxisCount = 1;
    if (constraints.maxWidth >= 1400) {
      crossAxisCount = 3;
    } else if (constraints.maxWidth >= 840) {
      crossAxisCount = 2;
    }

    return LayoutBuilder(
      builder: (ctx, subConstraints) {
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: riders.map((rider) {
            final double cardWidth = crossAxisCount == 1
                ? subConstraints.maxWidth
                : (subConstraints.maxWidth - (crossAxisCount - 1) * 14) / crossAxisCount;

            return SizedBox(
              width: cardWidth,
              child: _buildRiderCard(
                context: context,
                save: save,
                playerTeam: playerTeam,
                rider: rider,
                careerController: careerController,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRiderCard({
    required BuildContext context,
    required CareerSave save,
    required CyclingTeam playerTeam,
    required Rider rider,
    required CareerController careerController,
  }) {
    final bool isInjured = rider.health.currentInjury != null;
    final double form = rider.physiology.form.clamp(0.0, 100.0);
    final double fatigue = rider.physiology.fatigue.clamp(0.0, 100.0);
    final double tsb = _calculateTsb(rider);
    final tsbStatus = _getTsbStatus(tsb, isInjured);

    final double wKg = rider.physiology.weightKg > 0
        ? rider.physiology.ftpWatts / rider.physiology.weightKg
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInjured ? AppColors.powerZone6.withValues(alpha: 0.6) : AppTheme.borderColor,
          width: isInjured ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Górny wiersz: Awatar kolarza, Imię, Kraj, Rola i Specjalizacja
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wektorowy awatar kolarza
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiderDetailScreen(riderId: rider.id, initialRider: rider),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(29),
                child: RiderAvatarWidget(
                  appearance: rider.appearance,
                  team: playerTeam,
                  size: 58,
                ),
              ),
              const SizedBox(width: 12),

              // Dane identyfikacyjne
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RiderDetailScreen(riderId: rider.id, initialRider: rider),
                                ),
                              );
                            },
                            child: Text(
                              rider.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rider.countryIso,
                            style: const TextStyle(color: AppColors.cyanAccent, fontSize: 9.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${rider.age} lat',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(width: 6),
                        Text(
                          'Waga: ${rider.physiology.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Etykiety roli i specjalizacji
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            _getSpecializationLabel(rider.specialization).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.goldAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _showRoleSelectionDialog(context, rider, careerController),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B2333),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getRoleLabel(rider.contract.role),
                                  style: const TextStyle(
                                    color: AppColors.cyanAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.edit, size: 8.5, color: AppColors.cyanAccent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pomiary mocy (FTP, W/kg, Sprint 5s, Potencjał)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('FTP', '${rider.physiology.ftpWatts} W', AppColors.cyanAccent),
                _buildMetricCol('W/KG', '${wKg.toStringAsFixed(2)} W/kg', AppColors.powerZone3),
                _buildMetricCol('SPRINT 5S', '${rider.powerProfile.watts5s} W', AppColors.goldAccent),
                _buildMetricCol('POTENCJAŁ', '${rider.potential}/100', AppColors.textPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Wskaźniki kondycyjne: Forma (CTL) vs Zmęczenie (ATL) oraz TSB
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Flexible(
                          child: Text(
                            'Forma / Zmęczenie: ',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                          ),
                        ),
                        Text(
                          '${form.round()}% / ${fatigue.round()}%',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: tsbStatus.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: tsbStatus.color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${tsb > 0 ? "+" : ""}${tsb.round()} TSB • ${tsbStatus.label}',
                      style: TextStyle(
                        color: tsbStatus.color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Pasek progresu formy
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Row(
                  children: [
                    Expanded(
                      flex: form.round().clamp(1, 100),
                      child: Container(height: 5, color: AppColors.powerZone3),
                    ),
                    Expanded(
                      flex: (100 - form).round().clamp(1, 100),
                      child: Container(height: 5, color: Colors.white10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stan zdrowia i kontrakt
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (isInjured)
                Flexible(
                  child: Text(
                    '⚠️ ${rider.health.currentInjury!.name} (${rider.health.recoveryDaysRemaining} dni)',
                    style: const TextStyle(color: AppColors.powerZone6, fontSize: 10.5, fontWeight: FontWeight.w800),
                  ),
                )
              else
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 12, color: AppColors.powerZone3),
                    SizedBox(width: 4),
                    Text('100% Zdrowia', style: TextStyle(color: AppColors.powerZone3, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              Text(
                '€${(rider.contract.annualSalaryEur / 1000).round()}k/rok • do ${rider.contract.contractEndYear}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Przycisk analityczny Krzywej Mocy
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showRiderPowerAnalysisDialog(context, save, rider);
              },
              icon: const Icon(Icons.show_chart_rounded, size: 16, color: AppColors.goldAccent),
              label: const Text('Krzywa Mocy & Radar Atrybutów (PDC)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldAccent,
                side: BorderSide(color: AppColors.goldAccent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // ===========================================================================
  // 4. WIDOK TABELI PRO (PRO TABLE VIEW)
  // ===========================================================================

  Widget _buildProTableView({
    required BuildContext context,
    required CareerSave save,
    required CyclingTeam playerTeam,
    required List<Rider> riders,
    required CareerController careerController,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF131722)),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return AppColors.surfaceLight;
            return Colors.transparent;
          }),
          horizontalMargin: 16,
          columnSpacing: 18,
          columns: [
            const DataColumn(label: Text('KOLARZ', style: _tableHeaderStyle)),
            DataColumn(
              label: _buildSortableHeader('FTP (W)', RosterSortCriteria.ftp),
            ),
            DataColumn(
              label: _buildSortableHeader('W/KG', RosterSortCriteria.wKg),
            ),
            DataColumn(
              label: _buildSortableHeader('WAGA', RosterSortCriteria.weight),
            ),
            DataColumn(
              label: _buildSortableHeader('WIEK', RosterSortCriteria.age),
            ),
            DataColumn(
              label: _buildSortableHeader('TSB (ŚWIEŻOŚĆ)', RosterSortCriteria.tsb),
            ),
            const DataColumn(label: Text('SPECJALIZACJA', style: _tableHeaderStyle)),
            const DataColumn(label: Text('ROLA W DRUŻYNIE', style: _tableHeaderStyle)),
            const DataColumn(label: Text('ZDROWIE', style: _tableHeaderStyle)),
            DataColumn(
              label: _buildSortableHeader('PENSJA', RosterSortCriteria.salary),
            ),
            DataColumn(
              label: _buildSortableHeader('KONTRAKT', RosterSortCriteria.contractEnd),
            ),
            const DataColumn(label: Text('ANALIZA', style: _tableHeaderStyle)),
          ],
          rows: riders.map((rider) {
            final double wKg = rider.physiology.weightKg > 0
                ? rider.physiology.ftpWatts / rider.physiology.weightKg
                : 0.0;
            final double tsb = _calculateTsb(rider);
            final bool isInjured = rider.health.currentInjury != null;
            final tsbStatus = _getTsbStatus(tsb, isInjured);

            return DataRow(
              cells: [
                // 1. Kolarz (Portret + Imię + Kraj)
                DataCell(
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiderDetailScreen(riderId: rider.id, initialRider: rider),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        RiderAvatarWidget(
                          appearance: rider.appearance,
                          team: playerTeam,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rider.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              rider.countryIso,
                              style: const TextStyle(color: AppColors.cyanAccent, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. FTP
                DataCell(
                  Text(
                    '${rider.physiology.ftpWatts} W',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.cyanAccent, fontSize: 12),
                  ),
                ),

                // 3. W/kg
                DataCell(
                  Text(
                    wKg.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.powerZone3, fontSize: 12),
                  ),
                ),

                // 4. Waga
                DataCell(
                  Text(
                    '${rider.physiology.weightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5),
                  ),
                ),

                // 5. Wiek
                DataCell(
                  Text(
                    '${rider.age} lat',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5),
                  ),
                ),

                // 6. TSB
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tsbStatus.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${tsb > 0 ? "+" : ""}${tsb.round()} TSB',
                      style: TextStyle(
                        color: tsbStatus.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // 7. Specjalizacja
                DataCell(
                  Text(
                    _getSpecializationLabel(rider.specialization),
                    style: const TextStyle(color: AppColors.goldAccent, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),

                // 8. Rola w drużynie
                DataCell(
                  InkWell(
                    onTap: () => _showRoleSelectionDialog(context, rider, careerController),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getRoleLabel(rider.contract.role),
                          style: const TextStyle(color: AppColors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 10, color: AppColors.cyanAccent),
                      ],
                    ),
                  ),
                ),

                // 9. Zdrowie
                DataCell(
                  isInjured
                      ? Text(
                          '⚠️ ${rider.health.recoveryDaysRemaining} dni',
                          style: const TextStyle(color: AppColors.powerZone6, fontSize: 11, fontWeight: FontWeight.w800),
                        )
                      : const Text(
                          '100% OK',
                          style: TextStyle(color: AppColors.powerZone3, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                ),

                // 10. Pensja
                DataCell(
                  Text(
                    '€${(rider.contract.annualSalaryEur / 1000).round()}k/rok',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5),
                  ),
                ),

                // 11. Koniec kontraktu
                DataCell(
                  Text(
                    '${rider.contract.contractEndYear}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                ),

                // 12. Akcje (PDC)
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.show_chart_rounded, color: AppColors.goldAccent, size: 18),
                    tooltip: 'Krzywa Mocy i Radar Atrybutów (PDC)',
                    onPressed: () {
                      _showRiderPowerAnalysisDialog(context, save, rider);
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSortableHeader(String label, RosterSortCriteria criteria) {
    final isSelected = _sortCriteria == criteria;
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortCriteria == criteria) {
            _isAscending = !_isAscending;
          } else {
            _sortCriteria = criteria;
            _isAscending = criteria.defaultAscending;
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _isAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: AppColors.goldAccent,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  static const TextStyle _tableHeaderStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  // ===========================================================================
  // 5. PUSTY STAN WYSZUKIWANIA
  // ===========================================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.person_search_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Brak kolarzy spełniających wybrane kryteria.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Spróbuj zresetować filtry specjalizacji lub wyczyścić frazę wyszukiwania.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _specializationFilter = 'all';
                  _searchQuery = '';
                });
              },
              child: const Text('Zresetuj Filtry'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. METODY POMOCNICZE, COMPARATOR I DIALOGI
  // ===========================================================================

  bool _matchesSpecializationFilter(Rider rider, String filter) {
    switch (filter) {
      case 'climbers':
        return rider.specialization == RiderSpecialization.gcClimber ||
            rider.specialization == RiderSpecialization.pureClimber;
      case 'sprinters':
        return rider.specialization == RiderSpecialization.pureSprinter ||
            rider.specialization == RiderSpecialization.versatileSprinter;
      case 'classics':
        return rider.specialization == RiderSpecialization.puncher ||
            rider.specialization == RiderSpecialization.classicCobbles;
      case 'timeTrialists':
        return rider.specialization == RiderSpecialization.timeTrialist;
      case 'domestiques':
        return rider.specialization == RiderSpecialization.domestiqueEngine ||
            rider.specialization == RiderSpecialization.breakawaySpecialist;
      case 'injured':
        return rider.health.currentInjury != null;
      case 'all':
      default:
        return true;
    }
  }

  int _compareRiders(Rider a, Rider b, RosterSortCriteria criteria, bool isAscending) {
    int result;
    switch (criteria) {
      case RosterSortCriteria.lastName:
        result = a.lastName.compareTo(b.lastName);
        break;
      case RosterSortCriteria.ftp:
        result = a.physiology.ftpWatts.compareTo(b.physiology.ftpWatts);
        break;
      case RosterSortCriteria.wKg:
        final wKgA = a.physiology.weightKg > 0 ? a.physiology.ftpWatts / a.physiology.weightKg : 0.0;
        final wKgB = b.physiology.weightKg > 0 ? b.physiology.ftpWatts / b.physiology.weightKg : 0.0;
        result = wKgA.compareTo(wKgB);
        break;
      case RosterSortCriteria.tsb:
        result = _calculateTsb(a).compareTo(_calculateTsb(b));
        break;
      case RosterSortCriteria.form:
        result = a.physiology.form.compareTo(b.physiology.form);
        break;
      case RosterSortCriteria.fatigue:
        result = a.physiology.fatigue.compareTo(b.physiology.fatigue);
        break;
      case RosterSortCriteria.age:
        result = a.age.compareTo(b.age);
        break;
      case RosterSortCriteria.weight:
        result = a.physiology.weightKg.compareTo(b.physiology.weightKg);
        break;
      case RosterSortCriteria.salary:
        result = a.contract.annualSalaryEur.compareTo(b.contract.annualSalaryEur);
        break;
      case RosterSortCriteria.contractEnd:
        result = a.contract.contractEndYear.compareTo(b.contract.contractEndYear);
        break;
      case RosterSortCriteria.potential:
        result = a.potential.compareTo(b.potential);
        break;
    }
    return isAscending ? result : -result;
  }

  double _calculateTsb(Rider rider) {
    return rider.physiology.form - rider.physiology.fatigue;
  }

  ({String label, Color color}) _getTsbStatus(double tsb, bool isInjured) {
    if (isInjured) {
      return (label: 'Kontuzja', color: AppColors.powerZone6);
    }
    if (tsb >= 15) {
      return (label: 'Szczyt formy', color: AppColors.powerZone3);
    } else if (tsb >= 0) {
      return (label: 'Optymalna dyspozycja', color: const Color(0xFF10B981));
    } else if (tsb >= -10) {
      return (label: 'Lekkie zmęczenie', color: AppColors.goldAccent);
    } else {
      return (label: 'Przetrenowanie', color: AppColors.powerZone6);
    }
  }

  String _getRoleLabel(RiderRole role) {
    switch (role) {
      case RiderRole.teamLeader:
        return 'Lider Zespołu';
      case RiderRole.coLeader:
        return 'Współlider';
      case RiderRole.superDomestique:
        return 'Super-Pomocnik';
      case RiderRole.sprinter:
        return 'Lider Sprinter';
      case RiderRole.breakawaySpecialist:
        return 'Hulaka / Uciekinier';
      case RiderRole.domestique:
        return 'Pomocnik (Domestique)';
      case RiderRole.neoPro:
        return 'Młody Talent (Neo-Pro)';
    }
  }

  String _getSpecializationLabel(RiderSpecialization spec) {
    switch (spec) {
      case RiderSpecialization.gcClimber:
        return 'Góral GC';
      case RiderSpecialization.pureClimber:
        return 'Czysty Góral';
      case RiderSpecialization.puncher:
        return 'Puncheur';
      case RiderSpecialization.classicCobbles:
        return 'Brukowiec';
      case RiderSpecialization.pureSprinter:
        return 'Czysty Sprinter';
      case RiderSpecialization.versatileSprinter:
        return 'Sprinter Wszechstronny';
      case RiderSpecialization.timeTrialist:
        return 'Czasowiec';
      case RiderSpecialization.domestiqueEngine:
        return 'Motor Peletonu';
      case RiderSpecialization.breakawaySpecialist:
        return 'Uciekinier';
    }
  }

  void _showRoleSelectionDialog(
    BuildContext context,
    Rider rider,
    CareerController careerController,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: Text('Zmień Rolę: ${rider.fullName}'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: RiderRole.values.map((role) {
                final isCurrent = rider.contract.role == role;
                return ListTile(
                  title: Text(
                    _getRoleLabel(role),
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                      color: isCurrent ? AppColors.goldAccent : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isCurrent ? const Icon(Icons.check, color: AppColors.goldAccent) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    careerController.updateRiderRole(riderId: rider.id, newRole: role);
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Zaktualizowano rolę dla ${rider.fullName}')),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Anuluj'),
            ),
          ],
        );
      },
    );
  }

  void _showRiderPowerAnalysisDialog(
    BuildContext context,
    CareerSave save,
    Rider riderA,
  ) {
    Rider? defaultRiderB;
    if (save.playerTeam.rosterRiderIds.isNotEmpty) {
      final leaderId = save.playerTeam.rosterRiderIds.first;
      if (leaderId != riderA.id) {
        defaultRiderB = save.getRiderById(leaderId);
      } else if (save.playerTeam.rosterRiderIds.length > 1) {
        defaultRiderB = save.getRiderById(save.playerTeam.rosterRiderIds[1]);
      }
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            child: PowerCurveChartWidget(
              riderA: riderA,
              riderB: defaultRiderB,
              height: 480,
              showHeader: true,
              showTabs: true,
            ),
          ),
        );
      },
    );
  }
}

