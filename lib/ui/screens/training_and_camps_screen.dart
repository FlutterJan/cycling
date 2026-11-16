import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/training_and_camps_service.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../../state/career_controller.dart';
import '../widgets/rider_avatar_painter.dart';

// Stałe kolorystyczne wykresu PMC wzorowane na TrainingPeaks WKO5
const Color _cyanAccent = Color(0xFF00E5FF);
const Color _accentRed = Color(0xFFEF4444);
const Color _ctlColor = Color(0xFF38BDF8); // Błękit - CTL (Chronic Training Load - "Fitness / Baza")
const Color _atlColor = Color(0xFFF43F5E); // Róż/Karmin - ATL (Acute Training Load - "Fatigue / Zmęczenie")
const Color _tsbColor = Color(0xFFF59E0B); // Złoto/Żółty - TSB (Training Stress Balance - "Form / Świeżość")
const Color _peakZoneColor = Color(0xFF10B981); // Szmaragd - Strefa Superkompensacji (+10 do +20 TSB)

/// Ekran Treningów, Periodyzacji i Obozów Wysokogórskich (Training and Altitude Camps Screen).
///
/// Funkcjonalności:
/// 1. Wykres Performance Management Chart (PMC) w skali całego sezonu (wzorowany na TrainingPeaks WKO5):
///    - Krzywa CTL (Fitness / Baza 42-dniowa),
///    - Krzywa ATL (Fatigue / Zmęczenie 7-dniowe),
///    - Krzywa TSB (Form / Świeżość = CTL - ATL),
///    - Wyznaczona strefa szczytu formy (+10 do +20 TSB) oraz strefa przeciążenia (TSB < -25),
///    - Oznaczenia docelowych wyścigów (np. Tour de France, Giro, Monumenty) na osi czasu.
/// 2. Planer Obozów Wysokogórskich (Altitude Camp Planner):
///    - Wybór kultowych baz: Teide (Teneryfa), Sierra Nevada (Andaluzja), Livigno (Alpy), Font-Romeu (Pireneje), St. Moritz (Szwajcaria),
///    - Dobór czasu trwania (7, 10, 14, 21 dni) oraz uczestników z kadry zespołu,
///    - Kalkulacja kosztów w czasie rzeczywistym i weryfikacja budżetu klubu,
///    - Raport medyczny lekarza drużyny ze wzrostem FTP, VO2max i akumulacją zmęczenia.
/// 3. Przypisywanie Bodźców Treningowych & Szczyt Formy (Periodization Engine):
///    - Wybór docelowego wyścigu sezonu (Target Tour),
///    - Kalkulator superkompensacji i asystent taperingu (doprowadzenie TSB do +10..+20 na 1. etap),
///    - Przypisywanie tygodniowych kierunków treningowych (Baza Z2, FTP Z4, VO2max Z5, Sprint Z7, TT Aero, Tapering/Regeneracja Z1)
///      oraz 4 poziomów intensywności.
class TrainingAndCampsScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final String? initialRiderId;

  const TrainingAndCampsScreen({
    super.key,
    this.showAppBar = true,
    this.initialRiderId,
  });

  @override
  ConsumerState<TrainingAndCampsScreen> createState() =>
      _TrainingAndCampsScreenState();
}

class _TrainingAndCampsScreenState extends ConsumerState<TrainingAndCampsScreen> {
  // Aktywna zakładka: 0 = Wykres PMC, 1 = Obozy Wysokogórskie, 2 = Periodyzacja & Cel
  int _activeTab = 0;

  // Wybrany kolarz do analizy PMC i planu treningowego
  String? _selectedRiderId;

  // Filtr widoku krzywych PMC: 'all', 'ctl', 'atl', 'tsb'
  String _pmcFilter = 'all';

  // Czy pokazywać prognozę przyszłości (Projection Mode) do docelowego wyścigu
  bool _showProjection = true;

  // Planer obozów wysokogórskich
  late AltitudeCampLocation _selectedCampLocation;
  int _campDurationDays = 14; // 7, 10, 14, 21 dni
  final Set<String> _selectedCampRiderIds = {};

  // Periodyzacja & Cel Sezonu
  String? _targetRaceId;
  RiderTrainingFocus _selectedTrainingFocus = RiderTrainingFocus.ftpDevelopment;
  TrainingIntensity _selectedIntensity = TrainingIntensity.moderate;

  @override
  void initState() {
    super.initState();
    _selectedCampLocation = TrainingAndCampsService.availableCampLocations.first;
    _selectedRiderId = widget.initialRiderId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final save = ref.read(careerProvider).save;
      if (save != null) {
        final playerRoster = save.playerRoster;
        if (playerRoster.isNotEmpty && _selectedRiderId == null) {
          setState(() {
            _selectedRiderId = playerRoster.first.id;
          });
        }
        // Domyślnie zaznacz 4 czołowych kolarzy do obozu
        if (_selectedCampRiderIds.isEmpty && playerRoster.isNotEmpty) {
          setState(() {
            _selectedCampRiderIds.addAll(
              playerRoster.take(math.min(5, playerRoster.length)).map((r) => r.id),
            );
          });
        }
        // Domyślny docelowy wyścig (np. La Grande Boucle de France lub pierwszy Grand Tour)
        if (_targetRaceId == null) {
          final gt = save.calendar.races.firstWhere(
            (r) => r.isGrandTour,
            orElse: () => save.calendar.races.first,
          );
          setState(() {
            _targetRaceId = gt.id;
          });
        }
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

    final playerTeam = save.playerTeam;
    final playerRoster = save.playerRoster;

    // Pobierz aktualnie wybranego kolarza
    final selectedRider = playerRoster.firstWhere(
      (r) => r.id == _selectedRiderId,
      orElse: () => playerRoster.isNotEmpty ? playerRoster.first : _createFallbackRider(),
    );

    // Znajdź docelowy wyścig
    final targetRace = save.calendar.races.firstWhere(
      (r) => r.id == _targetRaceId,
      orElse: () => save.calendar.races.first,
    );

    final content = Column(
      children: [
        // 1. Górna belka telemetryczna sztabu szkoleniowego i budżetu
        _buildTrainingHeader(save: save, playerTeam: playerTeam),

        // 2. Selektor 3 podwidoków (Pill Bar)
        _buildTabNavigationPillBar(),

        // 3. Główny obszar roboczy zakładki
        Expanded(
          child: IndexedStack(
            index: _activeTab,
            children: [
              // Zakładka 0: Wykres PMC (TrainingPeaks)
              _buildPmcAnalyticsTab(
                context: context,
                save: save,
                roster: playerRoster,
                selectedRider: selectedRider,
                targetRace: targetRace,
                careerController: careerController,
              ),

              // Zakładka 1: Planer Obozów Wysokogórskich
              _buildAltitudeCampsTab(
                context: context,
                save: save,
                playerTeam: playerTeam,
                roster: playerRoster,
                careerController: careerController,
              ),

              // Zakładka 2: Periodyzacja & Cel Sezonu (Szczyt TSB +10..+20)
              _buildPeriodizationAndGoalsTab(
                context: context,
                save: save,
                playerTeam: playerTeam,
                roster: playerRoster,
                selectedRider: selectedRider,
                targetRace: targetRace,
                careerController: careerController,
              ),
            ],
          ),
        ),
      ],
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
              Icon(Icons.insights_rounded, color: AppColors.goldAccent, size: 20),
              SizedBox(width: 10),
              Text(
                'Centrum Treningowe & Obozy Wysokogórskie',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
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
      body: SafeArea(child: content),
    );
  }

  // ===========================================================================
  // 1. GÓRNA BELKA TELEMETRYCZNA SZTABU I BUDŻETU
  // ===========================================================================

  Widget _buildTrainingHeader({
    required CareerSave save,
    required CyclingTeam playerTeam,
  }) {
    final trainersLevel = playerTeam.staff.trainersLevel;
    final doctorsLevel = playerTeam.staff.doctorsLevel;

    // Średnie TSB drużyny
    double teamTsbSum = 0.0;
    for (final r in save.playerRoster) {
      teamTsbSum += r.health.trainingStressBalance;
    }
    final avgTeamTsb = save.playerRoster.isNotEmpty ? teamTsbSum / save.playerRoster.length : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 860;
          final titleRow = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: AppColors.goldAccent, size: 22),
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
                          playerTeam.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.goldAccent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PERIODYZACJA & PMC',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Centrum Przygotowania Fizycznego & Bazy Hipoksyjne',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final pills = Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildHeaderMetricPill(
                icon: Icons.sports_rounded,
                label: 'Trenerzy',
                value: '$trainersLevel/100',
                color: _cyanAccent,
              ),
              _buildHeaderMetricPill(
                icon: Icons.medical_services_outlined,
                label: 'Medycyna',
                value: '$doctorsLevel/100',
                color: _peakZoneColor,
              ),
              _buildHeaderMetricPill(
                icon: Icons.speed_rounded,
                label: 'Średnie TSB',
                value: '${avgTeamTsb >= 0 ? "+" : ""}${avgTeamTsb.toStringAsFixed(1)}',
                color: avgTeamTsb >= 10 ? _peakZoneColor : (avgTeamTsb >= 0 ? AppColors.goldAccent : _atlColor),
              ),
              _buildHeaderMetricPill(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Budżet na obozy',
                value: '€${_formatCompactCurrency(playerTeam.cashBalanceEur)}',
                color: const Color(0xFF69F0AE),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    context.goToPhysiologyLab(riderId: _selectedRiderId),
                icon: const Icon(Icons.biotech_rounded, size: 16),
                label: const Text('Laboratorium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyanAccent,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleRow,
                const SizedBox(height: 10),
                pills,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleRow),
              const SizedBox(width: 12),
              pills,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderMetricPill({
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
  // 2. SELEKTOR PODWIDOKÓW (TAB PILL BAR)
  // ===========================================================================

  Widget _buildTabNavigationPillBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildNavPill(
              index: 0,
              icon: Icons.show_chart_rounded,
              title: 'Wykres PMC (TrainingPeaks)',
            ),
            const SizedBox(width: 8),
            _buildNavPill(
              index: 1,
              icon: Icons.terrain_rounded,
              title: 'Planer Obozów Wysokogórskich',
            ),
            const SizedBox(width: 8),
            _buildNavPill(
              index: 2,
              icon: Icons.track_changes_rounded,
              title: 'Periodyzacja & Cel Sezonu (Szczyt TSB)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavPill({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool isSelected = _activeTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.goldAccent : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. ZAKŁADKA 0: PERFORMANCE MANAGEMENT CHART (TRAININGPEAKS PMC)
  // ===========================================================================

  Widget _buildPmcAnalyticsTab({
    required BuildContext context,
    required CareerSave save,
    required List<Rider> roster,
    required Rider selectedRider,
    required TourRace targetRace,
    required CareerController careerController,
  }) {
    // Generowanie punktów PMC dla całego 40-tygodniowego sezonu
    final pmcData = _generatePmcSeasonSeries(
      rider: selectedRider,
      save: save,
      targetRace: targetRace,
      includeProjection: _showProjection,
    );

    final currentCtl = selectedRider.health.chronicTrainingLoad;
    final currentAtl = selectedRider.health.acuteTrainingLoad;
    final currentTsb = selectedRider.health.trainingStressBalance;
    final supercompFactor =
        TrainingAndCampsService.calculateRiderSupercompensationFactor(selectedRider.health);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Horyzontalny selektor kolarzy z zespołu
          _buildRiderSelectorCarousel(roster: roster, selectedRiderId: selectedRider.id),
          const SizedBox(height: 16),

          // 2. Karta profilu wybranego kolarza i panel kontrolny PMC
          _buildPmcControlCard(
            selectedRider: selectedRider,
            currentCtl: currentCtl,
            currentAtl: currentAtl,
            currentTsb: currentTsb,
            supercompFactor: supercompFactor,
            targetRace: targetRace,
          ),
          const SizedBox(height: 16),

          // 3. Główny wykres Performance Management Chart (fl_chart)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nagłówek wykresu i legenda TrainingPeaks
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PERFORMANCE MANAGEMENT CHART (PMC)',
                          style: TextStyle(
                            color: AppColors.goldAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Krzywe Banistera • Baza 42 dni (CTL), Zmęczenie 7 dni (ATL) & Świeżość (TSB) • Sezon ${save.currentSeasonYear}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),

                    // Przełączniki widoku krzywych
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPmcFilterChip('Wszystkie', 'all'),
                        const SizedBox(width: 4),
                        _buildPmcFilterChip('CTL (Baza)', 'ctl'),
                        const SizedBox(width: 4),
                        _buildPmcFilterChip('ATL (Zmęczenie)', 'atl'),
                        const SizedBox(width: 4),
                        _buildPmcFilterChip('TSB (Forma)', 'tsb'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Legenda barwna
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _buildLegendItem(color: _ctlColor, label: 'CTL (Fitness / Baza wydolnościowa)'),
                    _buildLegendItem(color: _atlColor, label: 'ATL (Fatigue / Ostre zmęczenie)'),
                    _buildLegendItem(color: _tsbColor, label: 'TSB (Form / Świeżość startowa)'),
                    _buildLegendItem(
                      color: _peakZoneColor,
                      label: 'Strefa Szczytu Formy (+10 do +20 TSB)',
                      isZone: true,
                    ),
                    _buildLegendItem(
                      color: _accentRed,
                      label: 'Strefa Przeciążenia (< -25 TSB)',
                      isZone: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Sam wykres LineChart
                SizedBox(
                  height: 320,
                  child: LineChart(
                    _buildPmcLineChartData(
                      pmcData: pmcData,
                      filter: _pmcFilter,
                      targetRace: targetRace,
                      currentWeek: _getCurrentSeasonWeek(save.currentDate),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Etykieta osi X
                const Center(
                  child: Text(
                    'OŚ CZASU SEZONU: Tygodnie 1–40 (Styczeń – Październik)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Panel edukacyjny i interpretacja fizjologiczna
          _buildPmcInterpretationCard(
            tsb: currentTsb,
            ctl: currentCtl,
            atl: currentAtl,
            supercompFactor: supercompFactor,
          ),
        ],
      ),
    );
  }

  Widget _buildRiderSelectorCarousel({
    required List<Rider> roster,
    required String selectedRiderId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.groups_rounded, size: 14, color: AppColors.goldAccent),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'WYBIERZ KOLARZA DO ANALIZY PMC',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: roster.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final rider = roster[idx];
              final isSelected = rider.id == selectedRiderId;
              final tsb = rider.health.trainingStressBalance;

              final Color tsbColor = tsb >= 10.0
                  ? _peakZoneColor
                  : (tsb >= 0.0 ? AppColors.goldAccent : (tsb >= -20 ? _cyanAccent : _atlColor));

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedRiderId = rider.id;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 175,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF261E10) : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      RiderAvatarWidget(
                        appearance: rider.appearance,
                        size: 38,
                        showHelmet: false,
                        showGlasses: false,
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              rider.lastName,
                              style: TextStyle(
                                color: isSelected ? AppColors.goldAccent : AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              rider.specialization.name,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              children: [
                                Text(
                                  'CTL ${rider.health.chronicTrainingLoad.round()}',
                                  style: const TextStyle(color: _ctlColor, fontSize: 9.5, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '• TSB ${tsb >= 0 ? "+" : ""}${tsb.round()}',
                                  style: TextStyle(color: tsbColor, fontSize: 9.5, fontWeight: FontWeight.w800),
                                ),
                              ],
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
      ],
    );
  }

  Widget _buildPmcControlCard({
    required Rider selectedRider,
    required double currentCtl,
    required double currentAtl,
    required double currentTsb,
    required double supercompFactor,
    required TourRace targetRace,
  }) {
    final bool isPeak = currentTsb >= 10.0 && currentTsb <= 20.0;
    final bool isOverreaching = currentTsb < -25.0;

    final String formLabel = isPeak
        ? 'SZCZYT FORMY (PEAK FORM) 🚀'
        : (isOverreaching
            ? 'PRZECIĄŻENIE / RYZYKO KONTUZJI ⚠️'
            : (currentTsb >= 0 ? 'DOBRA DYSPOZYCJA ROBOCZA' : 'BLOK BUDOWANIA FORMY (ZMĘCZENIE)'));

    final Color formColor = isPeak
        ? _peakZoneColor
        : (isOverreaching ? _accentRed : (currentTsb >= 0 ? AppColors.goldAccent : _cyanAccent));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Awatar kolarza
          RiderAvatarWidget(
            appearance: selectedRider.appearance,
            size: 56,
            showHelmet: true,
          ),
          const SizedBox(width: 14),

          // Dane kolarza i status formy
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
                      selectedRider.fullName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: formColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: formColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        formLabel,
                        style: TextStyle(
                          color: formColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${selectedRider.age} lat • FTP: ${selectedRider.physiology.ftpWatts}W (${(selectedRider.physiology.ftpWatts / selectedRider.physiology.weightKg).toStringAsFixed(2)} W/kg) • Cel docelowy: ${targetRace.name}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 8),

                // 4 klocki telemetryczne
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPmcMetricTile(
                      label: 'CTL (Baza / Fitness)',
                      value: currentCtl.toStringAsFixed(1),
                      color: _ctlColor,
                      subtext: 'Wykładnicza 42 dni',
                    ),
                    _buildPmcMetricTile(
                      label: 'ATL (Zmęczenie)',
                      value: currentAtl.toStringAsFixed(1),
                      color: _atlColor,
                      subtext: 'Wykładnicza 7 dni',
                    ),
                    _buildPmcMetricTile(
                      label: 'TSB (Świeżość / Forma)',
                      value: '${currentTsb >= 0 ? "+" : ""}${currentTsb.toStringAsFixed(1)}',
                      color: _tsbColor,
                      subtext: 'CTL minus ATL',
                    ),
                    _buildPmcMetricTile(
                      label: 'Współczynnik mocy',
                      value: '${(supercompFactor * 100).toStringAsFixed(1)}%',
                      color: supercompFactor >= 1.03 ? _peakZoneColor : AppColors.textPrimary,
                      subtext: isPeak ? '+4% do watów!' : 'Standard',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Przełącznik Projection Mode
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Prognoza sezonu:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(width: 6),
                  Switch(
                    value: _showProjection,
                    activeThumbColor: AppColors.goldAccent,
                    onChanged: (val) {
                      setState(() {
                        _showProjection = val;
                      });
                    },
                  ),
                ],
              ),
              Text(
                _showProjection ? 'Prognoza włączona' : 'Tylko historia',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPmcMetricTile({
    required String label,
    required String value,
    required Color color,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
          ),
          Text(
            subtext,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPmcFilterChip(String label, String key) {
    final isSelected = _pmcFilter == key;
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
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide(color: isSelected ? AppColors.goldAccent : Colors.white12),
      onSelected: (_) {
        setState(() {
          _pmcFilter = key;
        });
      },
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isZone = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isZone ? 14 : 10,
          height: isZone ? 8 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isZone ? 2 : 5),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  LineChartData _buildPmcLineChartData({
    required List<_PmcWeekDataPoint> pmcData,
    required String filter,
    required TourRace targetRace,
    required int currentWeek,
  }) {
    final List<FlSpot> ctlSpots = [];
    final List<FlSpot> atlSpots = [];
    final List<FlSpot> tsbSpots = [];

    for (final pt in pmcData) {
      final x = pt.weekNumber.toDouble();
      ctlSpots.add(FlSpot(x, pt.ctl));
      atlSpots.add(FlSpot(x, pt.atl));
      tsbSpots.add(FlSpot(x, pt.tsb));
    }

    final List<LineChartBarData> lines = [];

    // Linia CTL (Fitness / Baza)
    if (filter == 'all' || filter == 'ctl') {
      lines.add(
        LineChartBarData(
          spots: ctlSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: _ctlColor,
          barWidth: 2.8,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: _ctlColor.withValues(alpha: 0.08),
          ),
        ),
      );
    }

    // Linia ATL (Fatigue / Zmęczenie)
    if (filter == 'all' || filter == 'atl') {
      lines.add(
        LineChartBarData(
          spots: atlSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: _atlColor,
          barWidth: 2.0,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: _atlColor.withValues(alpha: 0.04),
          ),
        ),
      );
    }

    // Linia TSB (Form / Świeżość)
    if (filter == 'all' || filter == 'tsb') {
      lines.add(
        LineChartBarData(
          spots: tsbSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: _tsbColor,
          barWidth: 2.8,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) {
              // Pokaż kropki na szczytach formy (TSB >= 10 i <= 20)
              return spot.y >= 10.0 && spot.y <= 20.0;
            },
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: _peakZoneColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      );
    }

    // Tydzień startu docelowego wyścigu (np. T28 dla Tour de France)
    final targetWeek = _getRaceSeasonWeek(targetRace);

    return LineChartData(
      minX: 1.0,
      maxX: 40.0,
      minY: -45.0,
      maxY: 160.0,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => const Color(0xFF141722),
          tooltipBorder: const BorderSide(color: Color(0xFF2E3345), width: 1.5),
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final weekIdx = spot.x.round().clamp(1, pmcData.length) - 1;
              final pt = pmcData[weekIdx];
              final isCurrent = pt.weekNumber == currentWeek;

              final String seriesName;
              final Color textColor;
              if (spot.barIndex == 0 && (filter == 'all' || filter == 'ctl')) {
                seriesName = 'CTL (Baza)';
                textColor = _ctlColor;
              } else if (spot.barIndex == 1 && filter == 'all') {
                seriesName = 'ATL (Zmęczenie)';
                textColor = _atlColor;
              } else {
                seriesName = 'TSB (Świeżość)';
                textColor = _tsbColor;
              }

              return LineTooltipItem(
                'Tydz. ${pt.weekNumber} (${pt.monthName})${isCurrent ? " • TERAZ" : ""}\n$seriesName: ${spot.y.toStringAsFixed(1)}',
                TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 25.0,
        verticalInterval: 4.0,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white.withValues(alpha: 0.05),
          strokeWidth: 1.0,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.white.withValues(alpha: 0.05),
          strokeWidth: 1.0,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: 30.0,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.round()}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: 4.0,
            getTitlesWidget: (value, meta) {
              final int w = value.toInt();
              final String label = _getWeekLabelShort(w);
              final bool isTarget = w == targetWeek;

              return Text(
                label,
                style: TextStyle(
                  color: isTarget ? AppColors.goldAccent : AppColors.textSecondary,
                  fontSize: 9.5,
                  fontWeight: isTarget ? FontWeight.w900 : FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          // Strefa docelowa szczytu formy (+10 do +20 TSB)
          HorizontalLine(
            y: 10.0,
            color: _peakZoneColor.withValues(alpha: 0.4),
            strokeWidth: 1.2,
            dashArray: [5, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              style: const TextStyle(
                color: _peakZoneColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
              labelResolver: (_) => 'Szczyt formy min (+10 TSB)',
            ),
          ),
          HorizontalLine(
            y: 20.0,
            color: _peakZoneColor.withValues(alpha: 0.4),
            strokeWidth: 1.2,
            dashArray: [5, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 6, bottom: 2),
              style: const TextStyle(
                color: _peakZoneColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
              labelResolver: (_) => 'Szczyt formy max (+20 TSB)',
            ),
          ),
          // Linia neutralna TSB = 0
          HorizontalLine(
            y: 0.0,
            color: Colors.white24,
            strokeWidth: 1.0,
          ),
          // Granica przeciążenia TSB = -25
          HorizontalLine(
            y: -25.0,
            color: _accentRed.withValues(alpha: 0.35),
            strokeWidth: 1.2,
            dashArray: [5, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.only(right: 6, top: 2),
              style: const TextStyle(
                color: _accentRed,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
              labelResolver: (_) => 'Strefa wyczerpania (-25 TSB)',
            ),
          ),
        ],
        verticalLines: [
          // Linia bieżącego tygodnia w grze
          VerticalLine(
            x: currentWeek.toDouble(),
            color: _cyanAccent.withValues(alpha: 0.6),
            strokeWidth: 1.5,
            dashArray: [4, 3],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topCenter,
              style: const TextStyle(
                color: _cyanAccent,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
              labelResolver: (_) => 'BIEŻĄCY TYDZIEŃ',
            ),
          ),
          // Linia docelowego Touru
          VerticalLine(
            x: targetWeek.toDouble(),
            color: AppColors.goldAccent,
            strokeWidth: 2.0,
            dashArray: [6, 3],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.bottomCenter,
              style: const TextStyle(
                color: AppColors.goldAccent,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
              labelResolver: (_) => '🏆 ${targetRace.name.split(" ").first.toUpperCase()}',
            ),
          ),
        ],
      ),
      lineBarsData: lines,
    );
  }

  Widget _buildPmcInterpretationCard({
    required double tsb,
    required double ctl,
    required double atl,
    required double supercompFactor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_alt_rounded, size: 16, color: AppColors.goldAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DIAGNOZA FIZJOLOGICZNA DS & PRAWO SUPERKOMPENSACJI',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getBanisterAdviceText(tsb: tsb, ctl: ctl, atl: atl),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. ZAKŁADKA 1: PLANER OBOZÓW WYSOKOGÓRSKICH (ALTITUDE CAMPS)
  // ===========================================================================

  Widget _buildAltitudeCampsTab({
    required BuildContext context,
    required CareerSave save,
    required CyclingTeam playerTeam,
    required List<Rider> roster,
    required CareerController careerController,
  }) {
    final availableLocations = careerController.getAvailableAltitudeCampLocations();
    final int selectedRidersCount = _selectedCampRiderIds.length;
    final int totalCampCostEur =
        _selectedCampLocation.costPerRiderPerDayEur * selectedRidersCount * _campDurationDays;
    final bool canAfford = playerTeam.cashBalanceEur >= totalCampCostEur;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nagłówek sekcji baz wysokogórskich
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.terrain_rounded, color: AppColors.goldAccent, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BAZY HIPOKSYJNE I OBOZY WYSOKOGÓRSKIE',
                        style: TextStyle(
                          color: AppColors.goldAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pobyty na wysokości 1800–2400 m n.p.m. stymulują wydzielanie EPO, skok hematokrytu, '
                        'wzrost masy hemoglobiny i trwałe podniesienie pułapu VO2max oraz mocy na progu FTP.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Karty 5 prestiżowych ośrodków wysokogórskich
          const Text(
            'WYBIERZ PRESTIŻOWĄ BAZĘ WYSOKOGÓRSKĄ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availableLocations.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 185,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (ctx, idx) {
              final loc = availableLocations[idx];
              final isSelected = loc.id == _selectedCampLocation.id;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCampLocation = loc;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF281E10) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${loc.altitudeMeters} m n.p.m.',
                              style: const TextStyle(
                                color: AppColors.goldAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '€${loc.costPerRiderPerDayEur}/os/dzień',
                            style: const TextStyle(
                              color: _cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'FTP: +${loc.ftpGainWatts}W',
                            style: const TextStyle(
                              color: _peakZoneColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'VO2max: +${loc.vo2maxBoostPct}%',
                            style: const TextStyle(
                              color: _cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. Konfigurator zgrupowania: czas trwania i uczestnicy
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lewa kolumna: czas trwania i kalkulator kosztorysu
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CZAS TRWANIA ZGRUPOWANIA',
                        style: TextStyle(
                          color: AppColors.goldAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Przyciski wyboru dni
                      Row(
                        children: [
                          _buildDurationButton(days: 7, label: '7 dni (Mikrocykl)'),
                          const SizedBox(width: 6),
                          _buildDurationButton(days: 10, label: '10 dni (Średni)'),
                          const SizedBox(width: 6),
                          _buildDurationButton(days: 14, label: '14 dni (Optimum)'),
                          const SizedBox(width: 6),
                          _buildDurationButton(days: 21, label: '21 dni (Pełny)'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Podsumowanie kosztorysu
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            _buildCostRow('Baza hipoksyjna:', _selectedCampLocation.name),
                            const SizedBox(height: 4),
                            _buildCostRow('Czas trwania:', '$_campDurationDays dni'),
                            const SizedBox(height: 4),
                            _buildCostRow('Liczba powołanych kolarzy:', '$selectedRidersCount zawodników'),
                            const SizedBox(height: 4),
                            _buildCostRow('Stawka za osobodzień:', '€${_selectedCampLocation.costPerRiderPerDayEur}'),
                            const Divider(height: 14, color: Colors.white12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ŁĄCZNY KOSZT OBOZU:',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '€${_formatMoney(totalCampCostEur)}',
                                  style: TextStyle(
                                    color: canAfford ? AppColors.goldAccent : _accentRed,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Komunikat budżetu
                      if (!canAfford)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _accentRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _accentRed),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 16, color: _accentRed),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Brak wystarczających funduszy w kasie klubu. Stan konta: €${_formatMoney(playerTeam.cashBalanceEur)}.',
                                  style: const TextStyle(color: _accentRed, fontSize: 10.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Przycisk zatwierdzenia i wysłania ekipy na obóz
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: (selectedRidersCount == 0 || !canAfford)
                              ? null
                              : () {
                                  _executeAltitudeCamp(
                                    context: context,
                                    careerController: careerController,
                                    location: _selectedCampLocation,
                                    riderIds: _selectedCampRiderIds.toList(),
                                    durationDays: _campDurationDays,
                                  );
                                },
                          icon: const Icon(Icons.flight_takeoff_rounded, size: 16, color: Colors.black),
                          label: Text(
                            'Rozpocznij Zgrupowanie w ${_selectedCampLocation.name.split(" ").first}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldAccent,
                            disabledBackgroundColor: Colors.white12,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Prawa kolumna: lista kolarzy z checkboxami
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'POWOŁANI ZAWODNICY ($selectedRidersCount / ${roster.length})',
                            style: const TextStyle(
                              color: AppColors.goldAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCampRiderIds.clear();
                                    _selectedCampRiderIds.addAll(roster.map((r) => r.id));
                                  });
                                },
                                child: const Text('Zaznacz wszystkich', style: TextStyle(color: _cyanAccent, fontSize: 10.5)),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCampRiderIds.clear();
                                  });
                                },
                                child: const Text('Wyczyść', style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: roster.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (ctx, idx) {
                          final rider = roster[idx];
                          final isSelected = _selectedCampRiderIds.contains(rider.id);
                          final isFit = rider.health.isFitToRace;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF221D12) : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.goldAccent : Colors.white10,
                              ),
                            ),
                            child: Row(
                              children: [
                                RiderAvatarWidget(
                                  appearance: rider.appearance,
                                  size: 32,
                                  showHelmet: false,
                                  showGlasses: false,
                                ),
                                const SizedBox(width: 10),

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
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            rider.specialization.name,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'FTP: ${rider.physiology.ftpWatts}W • VO2max: ${rider.physiology.vo2Max.toStringAsFixed(1)} • CTL: ${rider.health.chronicTrainingLoad.round()}',
                                        style: const TextStyle(color: _cyanAccent, fontSize: 9.5),
                                      ),
                                    ],
                                  ),
                                ),

                                Checkbox(
                                  value: isSelected,
                                  activeColor: AppColors.goldAccent,
                                  checkColor: Colors.black,
                                  onChanged: isFit
                                      ? (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedCampRiderIds.add(rider.id);
                                            } else {
                                              _selectedCampRiderIds.remove(rider.id);
                                            }
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationButton({required int days, required String label}) {
    final isSelected = _campDurationDays == days;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _campDurationDays = days;
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.goldAccent : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? AppColors.goldAccent : Colors.white10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textPrimary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        Text(val, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }

  void _executeAltitudeCamp({
    required BuildContext context,
    required CareerController careerController,
    required AltitudeCampLocation location,
    required List<String> riderIds,
    required int durationDays,
  }) {
    try {
      final outcome = careerController.conductAltitudeTrainingCamp(
        location: location,
        riderIds: riderIds,
        durationDays: durationDays,
      );

      showDialog(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161A24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.goldAccent, width: 2),
            ),
            title: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.goldAccent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Zakończono Zgrupowanie w ${location.name.split(" ").first}!',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RAPORT LEKARZA DRUŻYNY & KONSULTACJA HIPOKSYJNA:',
                        style: TextStyle(color: AppColors.goldAccent, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        outcome.doctorMedicalReport,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildOutcomeBadge('Średni zysk FTP', '+${outcome.averageFtpGainWatts.toStringAsFixed(1)}W', _peakZoneColor),
                    const SizedBox(width: 8),
                    _buildOutcomeBadge('Wzrost VO2max', '+${outcome.averageVo2maxGain.toStringAsFixed(1)} ml', _cyanAccent),
                    const SizedBox(width: 8),
                    _buildOutcomeBadge('Akumulacja ATL', '+${outcome.averageAtlFatigueAdded.round()} pkt', _atlColor),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Zatwierdź i Wróć do Bazy', style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd organizacji obozu: $e'),
          backgroundColor: _accentRed,
        ),
      );
    }
  }

  Widget _buildOutcomeBadge(String label, String val, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: col.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: col.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8.5)),
            Text(val, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. ZAKŁADKA 2: PERIODYZACJA & CEL SEZONU (SZCZYT TSB +10..+20)
  // ===========================================================================

  Widget _buildPeriodizationAndGoalsTab({
    required BuildContext context,
    required CareerSave save,
    required CyclingTeam playerTeam,
    required List<Rider> roster,
    required Rider selectedRider,
    required TourRace targetRace,
    required CareerController careerController,
  }) {
    final currentWeek = _getCurrentSeasonWeek(save.currentDate);
    final targetWeek = _getRaceSeasonWeek(targetRace);
    final weeksLeft = (targetWeek - currentWeek).clamp(0, 40);

    // Wyliczenie prognozy TSB w dniu startu docelowego wyścigu
    final projectedTsbAtTarget = _calculateProjectedTsb(
      currentRider: selectedRider,
      currentWeek: currentWeek,
      targetWeek: targetWeek,
      focus: _selectedTrainingFocus,
      intensity: _selectedIntensity,
    );

    final bool isTargetPeakReached = projectedTsbAtTarget >= 10.0 && projectedTsbAtTarget <= 20.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Karta docelowego wyścigu (Target Tour)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flag_rounded, color: AppColors.goldAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'DOCELOWY WYŚCIG SEZONU (TARGET RACE)',
                          style: TextStyle(
                            color: AppColors.goldAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Pozostało: $weeksLeft tygodni przygotowań',
                      style: const TextStyle(color: _cyanAccent, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Wybór wyścigu
                DropdownButtonFormField<String>(
                  initialValue: _targetRaceId,
                  dropdownColor: const Color(0xFF191D2A),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  items: save.calendar.races.map((r) {
                    final int startW = _getRaceSeasonWeek(r);
                    return DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        '${r.name} (${r.uciCategory.name.toUpperCase()} • Tydzień $startW • ${r.stages.length == 1 ? "Klasyk" : "${r.stages.length} etapów"})',
                      ),
                    );
                  }).toList(),
                  onChanged: (newRaceId) {
                    if (newRaceId != null) {
                      setState(() {
                        _targetRaceId = newRaceId;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Prognoza Superkompensacji TSB na 1. etap
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isTargetPeakReached
                  ? _peakZoneColor.withValues(alpha: 0.1)
                  : const Color(0xFF261D10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isTargetPeakReached ? _peakZoneColor : AppColors.goldAccent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Zegar TSB
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isTargetPeakReached ? _peakZoneColor : AppColors.goldAccent,
                      width: 3.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${projectedTsbAtTarget >= 0 ? "+" : ""}${projectedTsbAtTarget.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: isTargetPeakReached ? _peakZoneColor : AppColors.goldAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'TSB FORMA',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 7.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTargetPeakReached
                            ? 'IDEALNY SZCZYT FORMY (+10 DO +20 TSB) 🎯'
                            : 'WYMAGANA KOREKTA TAPERINGU PRZED WYŚCIGIEM',
                        style: TextStyle(
                          color: isTargetPeakReached ? _peakZoneColor : AppColors.goldAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Prognozowana dyspozycja ${selectedRider.fullName} na 1. etapie ${targetRace.name}: '
                        'TSB ${projectedTsbAtTarget >= 0 ? "+" : ""}${projectedTsbAtTarget.toStringAsFixed(1)} pkt. '
                        '${isTargetPeakReached ? "Kolarz wejdzie w wyścig z maksymalną bazą CTL i świeżymi nogami (+4% do mocy)!" : "Zalecamy wdrożenie bloku Aktywnej Regeneracji na 7-10 dni przed startem."}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Konfigurator tygodniowego bodźca treningowego
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ZARZĄDZANIE BODŹCEM DLA: ${selectedRider.fullName.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Aktualne FTP: ${selectedRider.physiology.ftpWatts}W • VO2max: ${selectedRider.physiology.vo2Max.toStringAsFixed(1)}',
                      style: const TextStyle(color: _cyanAccent, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Wybór kierunku treningowego
                const Text('KIERUNEK I PROFIL TRENINGOWY:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                DropdownButtonFormField<RiderTrainingFocus>(
                  initialValue: _selectedTrainingFocus,
                  dropdownColor: const Color(0xFF191D2A),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  items: RiderTrainingFocus.values.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.label),
                    );
                  }).toList(),
                  onChanged: (newFocus) {
                    if (newFocus != null) {
                      setState(() {
                        _selectedTrainingFocus = newFocus;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTrainingFocus.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 14),

                // Wybór intensywności
                const Text('INTENSYWNOŚĆ BLOKU TRENINGOWEGO (TSS MULTIPLIER):', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: TrainingIntensity.values.map((i) {
                    final isSel = _selectedIntensity == i;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedIntensity = i),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.goldAccent : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSel ? AppColors.goldAccent : Colors.white12),
                            ),
                            child: Text(
                              '${i.label.split(" ").first} (${i.tssMultiplier}x)',
                              style: TextStyle(
                                color: isSel ? Colors.black : AppColors.textPrimary,
                                fontSize: 10,
                                fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Przycisk aplikacji bodźca treningowego
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      careerController.setRiderTrainingFocus(
                        riderId: selectedRider.id,
                        focus: _selectedTrainingFocus,
                        intensity: _selectedIntensity,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Zastosowano blok: ${_selectedTrainingFocus.label} dla ${selectedRider.fullName}! '
                            'Parametry adaptacji i krzywe PMC zostały zaktualizowane.',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          backgroundColor: _peakZoneColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.black),
                    label: Text(
                      'Zastosuj Bodziec Treningowy dla ${selectedRider.lastName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  // 6. POMOCNICZY SILNIK GENEROWANIA SERII DANYCH PMC
  // ===========================================================================

  List<_PmcWeekDataPoint> _generatePmcSeasonSeries({
    required Rider rider,
    required CareerSave save,
    required TourRace targetRace,
    required bool includeProjection,
  }) {
    final int currentWeek = _getCurrentSeasonWeek(save.currentDate);
    final int targetWeek = _getRaceSeasonWeek(targetRace);

    final double curCtl = rider.health.chronicTrainingLoad;
    final double curAtl = rider.health.acuteTrainingLoad;

    final List<_PmcWeekDataPoint> series = [];

    // Faza 1: Tygodnie 1 do currentWeek (Historia od stycznia)
    for (int w = 1; w <= currentWeek; w++) {
      final double progress = w / currentWeek.toDouble();

      // Baza CTL rośnie powoli z ~50 do curCtl
      final double weekCtl = 48.0 + (curCtl - 48.0) * math.pow(progress, 0.85);

      // Zmęczenie ATL oscyluje w cyklach 3 tyg. obciążenia + 1 tydz. odpoczynku
      final double cycleWave = math.sin((w % 4) * (math.pi / 2.0));
      final double weekAtl = (weekCtl * 0.95) + (cycleWave * 16.0) + (progress * (curAtl - weekCtl));

      final double weekTsb = weekCtl - weekAtl;

      series.add(
        _PmcWeekDataPoint(
          weekNumber: w,
          monthName: _getWeekMonthName(w),
          ctl: weekCtl.clamp(20.0, 150.0),
          atl: weekAtl.clamp(10.0, 160.0),
          tsb: weekTsb.clamp(-40.0, 30.0),
        ),
      );
    }

    // Faza 2: Tygodnie currentWeek + 1 do 40 (Prognoza przyszłości do docelowego wyścigu)
    if (includeProjection && currentWeek < 40) {
      double runningCtl = curCtl;
      double runningAtl = curAtl;

      for (int w = currentWeek + 1; w <= 40; w++) {
        final int weeksToTarget = targetWeek - w;

        if (weeksToTarget == 0) {
          // Tydzień wyścigu głównego: wyścig generuje ogromne zmęczenie
          runningAtl += 35.0;
          runningCtl += 8.0;
        } else if (weeksToTarget == 1 || weeksToTarget == 2) {
          // Ostatnie 1-2 tygodnie przed Tourem: TAPERING & ODNOWA
          // ATL gwałtownie spada, CTL trzyma poziom -> TSB szybuje do +12..+18!
          runningAtl = (runningAtl * 0.65).clamp(30.0, 70.0);
          runningCtl = (runningCtl * 0.98).clamp(80.0, 140.0);
        } else if (weeksToTarget >= 3 && weeksToTarget <= 5) {
          // 3-5 tygodni przed Tourem: OBÓZ WYSOKOGÓRSKI & BUDOWANIE
          // ATL rośnie do 130, CTL rośnie do 115
          runningAtl = (runningAtl + 18.0).clamp(60.0, 145.0);
          runningCtl = (runningCtl + 6.0).clamp(60.0, 135.0);
        } else {
          // Pozostałe tygodnie: stabilny trening bazowy
          runningAtl = (runningCtl * 1.05) + (math.sin(w.toDouble()) * 8.0);
          runningCtl = (runningCtl + 1.2).clamp(50.0, 130.0);
        }

        final double weekTsb = runningCtl - runningAtl;

        series.add(
          _PmcWeekDataPoint(
            weekNumber: w,
            monthName: _getWeekMonthName(w),
            ctl: runningCtl.clamp(20.0, 150.0),
            atl: runningAtl.clamp(10.0, 160.0),
            tsb: weekTsb.clamp(-40.0, 30.0),
          ),
        );
      }
    }

    return series;
  }

  double _calculateProjectedTsb({
    required Rider currentRider,
    required int currentWeek,
    required int targetWeek,
    required RiderTrainingFocus focus,
    required TrainingIntensity intensity,
  }) {
    if (targetWeek <= currentWeek) {
      return currentRider.health.trainingStressBalance;
    }

    // Przy prawidłowym tapering w ostatnich 2 tygodniach:
    if (focus == RiderTrainingFocus.activeRecovery) {
      return 15.5; // Idealny szczyt superkompensacji
    }

    // Obliczenie na podstawie bazy kolarza i asystenta taperingu
    final double baseCtl = currentRider.health.chronicTrainingLoad;
    final double weeksToPrep = (targetWeek - currentWeek).toDouble();

    if (weeksToPrep >= 4) {
      // Wystarczająco dużo czasu na obóz i tapering -> celny szczyt
      return math.min(18.0, 10.0 + (baseCtl > 70 ? 5.0 : 2.0));
    } else if (weeksToPrep >= 2) {
      return math.min(14.0, 8.0 + (baseCtl > 70 ? 4.0 : 1.0));
    } else {
      return (currentRider.health.trainingStressBalance + 8.0).clamp(-20.0, 20.0);
    }
  }

  int _getCurrentSeasonWeek(DateTime dt) {
    // 40 tygodni od stycznia do października (1-40)
    final int week = ((dt.month - 1) * 4 + (dt.day / 7).floor() + 1);
    return week.clamp(1, 40);
  }

  int _getRaceSeasonWeek(TourRace race) {
    final int week = ((race.startMonth - 1) * 4 + (race.startDay / 7).floor() + 1);
    return week.clamp(1, 40);
  }

  String _getWeekLabelShort(int week) {
    switch (week) {
      case 1:
        return 'STY';
      case 5:
        return 'LUT';
      case 9:
        return 'MAR';
      case 13:
        return 'KWI';
      case 17:
        return 'MAJ';
      case 21:
        return 'CZE';
      case 25:
        return 'LIP';
      case 29:
        return 'SIE';
      case 33:
        return 'WRZ';
      case 37:
        return 'PAŹ';
      default:
        return 'T$week';
    }
  }

  String _getWeekMonthName(int week) {
    if (week <= 4) return 'Styczeń';
    if (week <= 8) return 'Luty';
    if (week <= 12) return 'Marzec';
    if (week <= 16) return 'Kwiecień';
    if (week <= 20) return 'Maj';
    if (week <= 24) return 'Czerwiec';
    if (week <= 28) return 'Lipiec';
    if (week <= 32) return 'Sierpień';
    if (week <= 36) return 'Wrzesień';
    return 'Październik';
  }

  String _getBanisterAdviceText({
    required double tsb,
    required double ctl,
    required double atl,
  }) {
    if (tsb >= 10.0 && tsb <= 20.0) {
      return 'Kolarz znajduje się w Złotej Strefie Superkompensacji (+10 do +20 TSB). '
          'Ostre zmęczenie (ATL) zostało zmetabolizowane, a baza tlenowa (CTL) pozostała nienaruszona. '
          'Wskaźnik mocy progowej wzrasta o +4.0%. To perfekcyjny moment na start w kluczowym Tourze!';
    } else if (tsb > 20.0) {
      return 'TSB wynosi +${tsb.toStringAsFixed(1)} (Zbyt długi odpoczynek). '
          'Kolarz traci napięcie nerwowo-mięśniowe i adaptację metaboliczną. '
          'Zalecam krótki 30-minutowy rozjazd z dwoma zrywami 1-minutowymi w celu aktywacji układu nerwowego.';
    } else if (tsb >= 0.0 && tsb < 10.0) {
      return 'TSB na poziomie +${tsb.toStringAsFixed(1)} (Dobra dyspozycja robocza). '
          'Zawodnik jest zregenerowany i gotowy do solidnego startu, lecz do pełni superkompensacji brakuje jeszcze 2–3 dni lekkiego taperingu.';
    } else if (tsb >= -20.0 && tsb < 0.0) {
      return 'TSB wynosi ${tsb.toStringAsFixed(1)} (Strefa Budowania Formy). '
          'Kolarz absorbuje ciężkie jednostki treningowe. Na tym etapie wysokie ATL jest zjawiskiem naturalnym. '
          'Pamiętaj, aby na 7 dni przed docelowym wyścigiem zmniejszyć objętość o 60%.';
    } else {
      return 'KRYTYCZNE PRZECIĄŻENIE: TSB poniżej -25 pkt (${tsb.toStringAsFixed(1)}). '
          'Skrajne wyczerpanie układu hormonalnego i nerwowego. Drastyczny wzrost ryzyka kontuzji mięśniowej i choroby. '
          'Koniecznie wdrożyć 3-4 dni biernego odpoczynku i zabiegów odnowy biologicznej!';
    }
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000.0).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000.0).toStringAsFixed(0)}k';
    }
    return '$amount';
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

  Rider _createFallbackRider() {
    return RiderProceduralGenerator.generateRider(
      id: 'fallback_rider',
      specialization: RiderSpecialization.gcClimber,
      targetOverallRating: 92,
      teamId: 'team_player',
    );
  }
}

/// Pojedynczy punkt pomiarowy na wykresie Performance Management Chart
class _PmcWeekDataPoint {
  final int weekNumber;
  final String monthName;
  final double ctl;
  final double atl;
  final double tsb;

  const _PmcWeekDataPoint({
    required this.weekNumber,
    required this.monthName,
    required this.ctl,
    required this.atl,
    required this.tsb,
  });
}
