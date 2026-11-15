import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../models/career/career_save.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../services/generators/fictional_brands_catalog.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../../services/generators/stage_profile_builder.dart';
import '../../state/career_controller.dart';
import '../../state/race_simulation_notifier.dart';
import '../widgets/bike_preview_painter.dart';
import '../widgets/elevation_profile_chart.dart';
import '../widgets/rider_avatar_painter.dart';
import 'race_simulation_screen.dart';

// Stałe kolorystyczne kokpitu odprawy taktycznej
const Color _cyanAccent = Color(0xFF00E5FF);
const Color _emeraldGreen = Color(0xFF10B981);
const Color _amberWarning = Color(0xFFF59E0B);
const Color _crimsonAlert = Color(0xFFEF4444);
const Color _cardSurface = Color(0xFF191D28);

/// Rola taktyczna kolarza wyznaczana na dany etap wyścigu.
enum StageTacticalRole {
  breakawayHunter(
    name: 'Uciekinier Dnia',
    shortLabel: 'Ucieczka',
    icon: Icons.flash_on_rounded,
    badgeColor: Color(0xFFF59E0B),
    tacticalOrder: TacticalOrder.attack,
    description: 'Atak od km 0, ucieczka dnia, walka o premie KOM/Sprint i ekspozycja sponsorów.',
  ),
  protectedLeader(
    name: 'Lider Generalny (GC)',
    shortLabel: 'Lider GC',
    icon: Icons.shield_rounded,
    badgeColor: Color(0xFFFFD700),
    tacticalOrder: TacticalOrder.holdPosition,
    description: 'Chroń w peletonie, oszczędzaj energię na finałowy podjazd lub kluczową batalię GC.',
  ),
  sprintFinisher(
    name: 'Główny Sprinter',
    shortLabel: 'Sprinter',
    icon: Icons.sports_score_rounded,
    badgeColor: Color(0xFF10B981),
    tacticalOrder: TacticalOrder.saveEnergy,
    description: 'Chroń na płaskich kilometrach, zachowaj 100% W\' i glikogenu na finiszowe 200m.',
  ),
  leadoutPilot(
    name: 'Rozprowadzający (Lead-out)',
    shortLabel: 'Pociąg',
    icon: Icons.double_arrow_rounded,
    badgeColor: Color(0xFF38BDF8),
    tacticalOrder: TacticalOrder.pullGroup,
    description: 'Rozpędzanie pociągu na ostatnich 2 km z prędkością 65+ km/h przed finiszem.',
  ),
  bodyguardRoadCaptain(
    name: 'Ochroniarz Lidera (Kapitan)',
    shortLabel: 'Ochroniarz',
    icon: Icons.security_rounded,
    badgeColor: Color(0xFF818CF8),
    tacticalOrder: TacticalOrder.protectLeader,
    description: 'Osłania lidera przed wiatrem, kasuje groźne kontry i oddaje koło w razie defektu.',
  ),
  mountainPaceSetter(
    name: 'Górski Pociąg (Tempo)',
    shortLabel: 'Góral Tempo',
    icon: Icons.terrain_rounded,
    badgeColor: Color(0xFFEC4899),
    tacticalOrder: TacticalOrder.pullGroup,
    description: 'Mocne tempo na pierwszych podjazdach, odsiewanie rywali i kasowanie ucieczki.',
  ),
  waterCarrier(
    name: 'Bidonowiec (Gregario)',
    shortLabel: 'Bidony',
    icon: Icons.local_drink_rounded,
    badgeColor: Color(0xFF06B6D4),
    tacticalOrder: TacticalOrder.fetchBidonsFromCar,
    description: 'Zjazdy do wozu technicznego po bidony i batony energetyczne dla kolegów.',
  ),
  freeAgent(
    name: 'Wolny Strzelec',
    shortLabel: 'Wolny',
    icon: Icons.directions_bike_rounded,
    badgeColor: Color(0xFF94A3B8),
    tacticalOrder: TacticalOrder.followWheels,
    description: 'Jazda elastyczna, reakcja na wydarzenia na trasie i pilnowanie koła faworytów.',
  );

  final String name;
  final String shortLabel;
  final IconData icon;
  final Color badgeColor;
  final TacticalOrder tacticalOrder;
  final String description;

  const StageTacticalRole({
    required this.name,
    required this.shortLabel,
    required this.icon,
    required this.badgeColor,
    required this.tacticalOrder,
    required this.description,
  });
}

/// Szybkie presety konfiguracji roweru na etap
enum StageBikePreset {
  climbingLightweight(
    title: 'Górski Lekki',
    subtitle: 'Stożki 33mm • Opony 28mm • 5.2 bar',
    icon: Icons.terrain_rounded,
    color: Color(0xFFEC4899),
    rimDepthMm: 33,
    tireWidthMm: 28,
    isTubeless: true,
    pressureBar: 5.2,
    isWax: true,
  ),
  aeroSpeed(
    title: 'Aero Szybki',
    subtitle: 'Stożki 60mm • Opony 28mm • 5.8 bar',
    icon: Icons.air_rounded,
    color: Color(0xFF38BDF8),
    rimDepthMm: 60,
    tireWidthMm: 28,
    isTubeless: true,
    pressureBar: 5.8,
    isWax: true,
  ),
  cobbleRoubaix(
    title: 'Piekło Bruków',
    subtitle: 'Stożki 35mm • Opony 32mm • 3.8 bar',
    icon: Icons.grid_view_rounded,
    color: Color(0xFFF59E0B),
    rimDepthMm: 33,
    tireWidthMm: 32,
    isTubeless: true,
    pressureBar: 3.8,
    isWax: true,
  ),
  rainWetRoad(
    title: 'Deszcz & Śliska Szosa',
    subtitle: 'Stożki 45mm • Opony 30mm • 4.4 bar • Olej',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF06B6D4),
    rimDepthMm: 45,
    tireWidthMm: 30,
    isTubeless: true,
    pressureBar: 4.4,
    isWax: false,
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int rimDepthMm;
  final int tireWidthMm;
  final bool isTubeless;
  final double pressureBar;
  final bool isWax;

  const StageBikePreset({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.rimDepthMm,
    required this.tireWidthMm,
    required this.isTubeless,
    required this.pressureBar,
    required this.isWax,
  });
}

/// Ekran Odprawy Taktycznej Przed Startem Etapu (PreRaceBriefingScreen).
///
/// Zawiera 3 kluczowe filary przygotowania zespołu:
/// 1. Analiza profilu etapu (`ElevationProfileChart`), pogody, róży wiatrów i ryzyka wachlarzy (echelons).
/// 2. Konfiguracja sprzętu dla drużyny (stożki kół 33/45/60/dysk, opony 25-32mm, ciśnienie na deszcz/bruk).
/// 3. Przypisanie ról taktycznych (ucieczka dnia od km 0, ochrona lidera, sprinter i rozprowadzający).
class PreRaceBriefingScreen extends ConsumerStatefulWidget {
  final RaceStage? stage;
  final TourRace? race;
  final bool isStandalone;

  const PreRaceBriefingScreen({
    super.key,
    this.stage,
    this.race,
    this.isStandalone = false,
  });

  @override
  ConsumerState<PreRaceBriefingScreen> createState() => _PreRaceBriefingScreenState();
}

class _PreRaceBriefingScreenState extends ConsumerState<PreRaceBriefingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Aktywna kadra na etap
  List<Rider> _stageLineup = [];
  bool _isDataLoaded = false;

  // Przypisanie ról taktycznych: riderId -> StageTacticalRole
  final Map<String, StageTacticalRole> _assignedRoles = {};

  // Konfiguracja sprzętu drużynowego
  int _teamRimDepthMm = 45;
  int _teamTireWidthMm = 28;
  bool _teamIsTubeless = true;
  double _teamTirePressureBar = 5.2;
  bool _teamIsHotMeltWax = true;
  String _teamTireCompound = 'all_round'; // 'all_round', 'rain_grip', 'cobble_shield'
  StageBikePreset _activePreset = StageBikePreset.climbingLightweight;

  // Nadpisania sprzętu dla konkretnego kolarza
  String? _selectedRiderForBikePreview;
  final Map<String, int> _riderRimDepthOverrides = {};
  final Map<String, int> _riderTireWidthOverrides = {};

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

  void _ensureDataInitialized(CareerSave? save, RaceStage activeStage) {
    if (_isDataLoaded) return;

    // Pobranie składu kolarzy gracza
    if (save != null && save.playerTeam.rosterRiderIds.isNotEmpty) {
      final teamRiderIds = save.playerTeam.rosterRiderIds;
      final allRiders = save.riders.where((r) => teamRiderIds.contains(r.id)).toList();

      // Wybierz do 8 kolarzy do składu na etap
      _stageLineup = allRiders.take(8).toList();
    }

    if (_stageLineup.isEmpty) {
      _stageLineup = _generateSampleBriefingLineup();
    }

    _selectedRiderForBikePreview = _stageLineup.first.id;

    // Automatyczne, inteligentne przypisanie ról na podstawie typu etapu i specjalizacji
    _autoAssignTacticalRoles(activeStage);

    // Automatyczne dopasowanie wstępnego presetu sprzętu
    _autoSelectPresetForStage(activeStage);

    _isDataLoaded = true;
  }

  void _autoSelectPresetForStage(RaceStage stage) {
    final bool hasCobbles = stage.segments.any((s) => s.isCobblestone);
    final bool isRain = stage.weatherCondition == WeatherCondition.lightRain ||
        stage.weatherCondition == WeatherCondition.heavyStorm;

    if (hasCobbles) {
      _applyPreset(StageBikePreset.cobbleRoubaix);
    } else if (isRain) {
      _applyPreset(StageBikePreset.rainWetRoad);
    } else if (stage.stageType == StageType.highMountain ||
        stage.stageType == StageType.summitFinish) {
      _applyPreset(StageBikePreset.climbingLightweight);
    } else {
      _applyPreset(StageBikePreset.aeroSpeed);
    }
  }

  void _autoAssignTacticalRoles(RaceStage stage) {
    if (_stageLineup.isEmpty) return;

    final sortedByOvr = List<Rider>.from(_stageLineup)
      ..sort((a, b) => b.overallRating.compareTo(a.overallRating));

    // 1. Wyznaczenie lidera GC (najlepszy góral lub najwyższy OVR)
    final leader = sortedByOvr.firstWhere(
      (r) => r.specialization == RiderSpecialization.gcClimber ||
          r.specialization == RiderSpecialization.pureClimber,
      orElse: () => sortedByOvr.first,
    );
    _assignedRoles[leader.id] = StageTacticalRole.protectedLeader;

    // 2. Jeśli etap płaski lub pagórkowaty, wyznacz sprintera
    String? sprinterId;
    if (stage.stageType == StageType.flat || stage.stageType == StageType.hilly) {
      final sprinter = sortedByOvr.firstWhere(
        (r) => (r.specialization == RiderSpecialization.pureSprinter ||
                r.specialization == RiderSpecialization.versatileSprinter) &&
            r.id != leader.id,
        orElse: () => sortedByOvr.firstWhere(
          (r) => r.id != leader.id,
          orElse: () => leader,
        ),
      );
      if (sprinter.id != leader.id) {
        sprinterId = sprinter.id;
        _assignedRoles[sprinter.id] = StageTacticalRole.sprintFinisher;
      }
    }

    // 3. Wyznaczenie uciekiniera dnia
    final breakawayHunter = sortedByOvr.firstWhere(
      (r) => (r.specialization == RiderSpecialization.breakawaySpecialist ||
              r.specialization == RiderSpecialization.puncher ||
              r.specialization == RiderSpecialization.classicCobbles) &&
          r.id != leader.id &&
          r.id != sprinterId,
      orElse: () => sortedByOvr.lastWhere(
        (r) => r.id != leader.id && r.id != sprinterId,
        orElse: () => sortedByOvr.last,
      ),
    );
    if (breakawayHunter.id != leader.id && breakawayHunter.id != sprinterId) {
      _assignedRoles[breakawayHunter.id] = StageTacticalRole.breakawayHunter;
    }

    // 4. Przypisanie pozostałych ról: ochroniarz, rozprowadzający, pomocnicy
    int remainingCount = 0;
    for (final rider in _stageLineup) {
      if (_assignedRoles.containsKey(rider.id)) continue;

      if (sprinterId != null && remainingCount == 0) {
        _assignedRoles[rider.id] = StageTacticalRole.leadoutPilot;
      } else if (remainingCount <= 1) {
        _assignedRoles[rider.id] = StageTacticalRole.bodyguardRoadCaptain;
      } else if (stage.stageType == StageType.highMountain) {
        _assignedRoles[rider.id] = StageTacticalRole.mountainPaceSetter;
      } else if (remainingCount == 2) {
        _assignedRoles[rider.id] = StageTacticalRole.waterCarrier;
      } else {
        _assignedRoles[rider.id] = StageTacticalRole.freeAgent;
      }
      remainingCount++;
    }
  }

  void _applyPreset(StageBikePreset preset) {
    setState(() {
      _activePreset = preset;
      _teamRimDepthMm = preset.rimDepthMm;
      _teamTireWidthMm = preset.tireWidthMm;
      _teamIsTubeless = preset.isTubeless;
      _teamTirePressureBar = preset.pressureBar;
      _teamIsHotMeltWax = preset.isWax;

      if (preset == StageBikePreset.rainWetRoad) {
        _teamTireCompound = 'rain_grip';
      } else if (preset == StageBikePreset.cobbleRoubaix) {
        _teamTireCompound = 'cobble_shield';
      } else {
        _teamTireCompound = 'all_round';
      }

      // Wyczyszczenie indywidualnych nadpisań
      _riderRimDepthOverrides.clear();
      _riderTireWidthOverrides.clear();
    });
  }

  double _calculateOptimalPressure(RaceStage stage, Rider? rider) {
    // Bazowe ciśnienie dla wagi kolarza ~68kg i opony 28mm: 5.4 bar
    double basePressure = 5.4;

    if (rider != null) {
      final double weight = rider.physiology.weightKg;
      // Korekta o masę ciała: +/- 0.1 bar na każde 3 kg różnicy od 68 kg
      basePressure += (weight - 68.0) * 0.033;
    }

    // Korekta szerokości opony
    if (_teamTireWidthMm == 25) basePressure += 0.7;
    if (_teamTireWidthMm == 30) basePressure -= 0.5;
    if (_teamTireWidthMm == 32) basePressure -= 1.0;

    // Korekta na deszcz i mokrą nawierzchnię
    if (stage.weatherCondition == WeatherCondition.lightRain ||
        stage.weatherCondition == WeatherCondition.heavyStorm) {
      basePressure -= 0.6;
    }

    // Korekta na bruki
    final bool hasCobbles = stage.segments.any((s) => s.isCobblestone);
    if (hasCobbles) {
      basePressure -= 1.0;
    }

    return double.parse(basePressure.clamp(3.2, 7.2).toStringAsFixed(1));
  }

  CompleteBike _buildConfiguredBikeForRider(String riderId, RaceStage stage) {
    final int rimDepth = _riderRimDepthOverrides[riderId] ?? _teamRimDepthMm;
    final int tireWidth = _riderTireWidthOverrides[riderId] ?? _teamTireWidthMm;

    // Dobór kół z katalogu fikcyjnych marek
    final wheelset = FictionalBrandsCatalog.allWheelsets.firstWhere(
      (w) => (w.rimDepthMm - rimDepth).abs() <= 5,
      orElse: () => FictionalBrandsCatalog.allWheelsets.first,
    );

    // Dobór ramy
    final frame = (stage.stageType == StageType.highMountain)
        ? FictionalBrandsCatalog.lightestClimbingFrame
        : FictionalBrandsCatalog.mostAeroRoadFrame;

    // Dobór opony
    final baseTire = FictionalBrandsCatalog.allTires.firstWhere(
      (t) => t.widthMm == tireWidth,
      orElse: () => FictionalBrandsCatalog.fastestTire,
    );

    final configuredTire = baseTire.copyWith(
      isTubeless: _teamIsTubeless,
      rollingResistanceCrr: _teamIsTubeless ? 0.0033 : 0.0038,
      wetGripIndex: (_teamTireCompound == 'rain_grip') ? 4.8 : 3.5,
      punctureResistanceIndex: (_teamTireCompound == 'cobble_shield') ? 4.9 : 3.8,
    );

    return CompleteBike(
      id: 'briefing_bike_$riderId',
      name: '${frame.name} Team Spec',
      frame: frame,
      wheelset: wheelset,
      groupset: FictionalBrandsCatalog.allGroupsets.first,
      tire: configuredTire,
      cockpitWidthMm: (stage.stageType == StageType.flat) ? 380 : 400,
      hoodInwardTiltDegrees: 8.0,
      slammedStem: true,
    );
  }

  void _launchRaceSimulation({
    required BuildContext context,
    required CareerSave save,
    required RaceStage activeStage,
    required RaceSimulationNotifier simController,
  }) {
    // 1. Zbudowanie mapy kolarzy i drużyn
    final Map<String, Rider> allRidersMap = {
      for (final r in save.riders) r.id: r,
    };
    final Map<String, CyclingTeam> allTeamsMap = {
      for (final t in save.teams) t.id: t,
    };

    // 2. Zbudowanie mapy rowerów uwzględniającej konfigurację z odprawy
    final Map<String, CompleteBike> allBikesMap = {};
    for (final r in save.riders) {
      if (_stageLineup.any((lr) => lr.id == r.id)) {
        // Rower skonfigurowany przez gracza podczas odprawy
        allBikesMap[r.id] = _buildConfiguredBikeForRider(r.id, activeStage);
      } else {
        // Domyślny rower dla rywali
        final team = allTeamsMap[r.contract.teamId];
        final bike = (team?.teamBikes.isNotEmpty ?? false)
            ? team!.teamBikes.first
            : _buildConfiguredBikeForRider(r.id, activeStage);
        allBikesMap[r.id] = bike;
      }
    }

    // 3. Inicjalizacja etapu w symulatorze
    simController.initializeStage(
      stage: activeStage,
      playerTeamId: save.playerTeamId,
      allRidersMap: allRidersMap,
      allBikesMap: allBikesMap,
      allTeamsMap: allTeamsMap,
    );

    // 4. Przypisanie rozkazów taktycznych dla kolarzy gracza
    for (final rider in _stageLineup) {
      final role = _assignedRoles[rider.id] ?? StageTacticalRole.freeAgent;
      simController.setRiderTacticalOrder(rider.id, role.tacticalOrder);
    }

    // 5. Przejście do aktywnego ekranu symulacji wyścigu 3D / HUD
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const RaceSimulationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final careerUiState = ref.watch(careerProvider);
    final simController = ref.watch(raceSimulationProvider.notifier);
    final save = careerUiState.save;

    // Rozstrzygnięcie aktywnego etapu i wyścigu
    final activeStage = widget.stage ??
        save?.calendar.activeStage ??
        _resolveNextUpcomingStage(save) ??
        _generateFallbackStage();

    final activeRace = widget.race ??
        save?.calendar.activeRace ??
        _resolveNextUpcomingRace(save, activeStage);

    _ensureDataInitialized(save, activeStage);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _cyanAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _cyanAccent.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_bike_rounded, color: _cyanAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'ODPRAWA PRZEDSTARTOWA',
                    style: TextStyle(
                      color: _cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${activeRace?.name ?? "WorldTour"} • Etap #${activeStage.stageNumber}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surfaceLight.withValues(alpha: 0.6),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.goldAccent,
              indicatorWeight: 3,
              labelColor: AppColors.goldAccent,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              tabs: const [
                Tab(
                  icon: Icon(Icons.show_chart_rounded, size: 18),
                  text: 'PROFIL & WIATR',
                ),
                Tab(
                  icon: Icon(Icons.settings_outlined, size: 18),
                  text: 'SPRZĘT & OPONY',
                ),
                Tab(
                  icon: Icon(Icons.groups_rounded, size: 18),
                  text: 'ROLE TAKTYCZNE',
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Górny pasek metryk etapu
            _buildTopStageMetricsBar(activeStage),

            // Główny obszar roboczy z zakładkami
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabProfileAndWind(activeStage),
                  _buildTabEquipment(activeStage),
                  _buildTabTacticsAndRoles(activeStage),
                ],
              ),
            ),

            // Dolny pasek gotowości do startu
            _buildBottomActionBar(
              context: context,
              save: save,
              activeStage: activeStage,
              simController: simController,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // GÓRNY PASEK METRYK ETAPU
  // ===========================================================================

  Widget _buildTopStageMetricsBar(RaceStage stage) {
    final int komCount = stage.segments.where((s) => s.isKom).length;
    final int sprintCount = stage.segments.where((s) => s.isIntermediateSprint).length;
    final int cobbleKm = stage.segments
        .where((s) => s.isCobblestone)
        .fold(0.0, (acc, s) => acc + s.lengthKm)
        .round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          _buildStageTypeBadge(stage.stageType),
          const SizedBox(width: 14),
          _buildStageMetricPill(
            icon: Icons.straighten_rounded,
            label: 'Dystans',
            value: '${stage.totalDistanceKm.toStringAsFixed(1)} km',
          ),
          const SizedBox(width: 14),
          _buildStageMetricPill(
            icon: Icons.trending_up_rounded,
            label: 'Przewyższenie',
            value: '+${stage.totalElevationGainM.round()} m',
          ),
          const SizedBox(width: 14),
          _buildStageMetricPill(
            icon: Icons.landscape_rounded,
            label: 'Szczyt',
            value: '${stage.maxElevationM.round()} m',
          ),
          const SizedBox(width: 14),
          _buildStageMetricPill(
            icon: Icons.terrain_rounded,
            label: 'Górskie / Sprint',
            value: '$komCount KOM / $sprintCount Sprint',
          ),
          const Spacer(),
          if (cobbleKm > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _amberWarning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _amberWarning),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: _amberWarning, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$cobbleKm km Bruków!',
                    style: const TextStyle(
                      color: _amberWarning,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          _buildWeatherPill(stage),
        ],
      ),
    );
  }

  Widget _buildStageTypeBadge(StageType type) {
    String label;
    Color color;

    switch (type) {
      case StageType.highMountain:
        label = 'WYSOKOGÓRSKI';
        color = const Color(0xFFEF4444);
        break;
      case StageType.summitFinish:
        label = 'FINISZ POD GÓRĘ';
        color = const Color(0xFFF97316);
        break;
      case StageType.hilly:
        label = 'PAGÓRKOWATY';
        color = const Color(0xFFEAB308);
        break;
      case StageType.cobbleClassic:
        label = 'BRUKI / KLASYK';
        color = const Color(0xFFD97706);
        break;
      case StageType.individualTimeTrial:
        label = 'CZASÓWKA (ITT)';
        color = const Color(0xFF3B82F6);
        break;
      case StageType.teamTimeTrial:
        label = 'CZASÓWKA (TTT)';
        color = const Color(0xFF8B5CF6);
        break;
      case StageType.flat:
        label = 'PŁASKI / SPRINT';
        color = const Color(0xFF10B981);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStageMetricPill({required IconData icon, required String label, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherPill(RaceStage stage) {
    IconData icon;
    String label;
    Color color;

    switch (stage.weatherCondition) {
      case WeatherCondition.lightRain:
        icon = Icons.grain_rounded;
        label = 'Mokry Asfalt';
        color = _cyanAccent;
        break;
      case WeatherCondition.heavyStorm:
        icon = Icons.thunderstorm_rounded;
        label = 'Burza & Ulewa';
        color = _crimsonAlert;
        break;
      case WeatherCondition.crosswindGale:
        icon = Icons.air_rounded;
        label = 'Wichura Boczna';
        color = _amberWarning;
        break;
      case WeatherCondition.extremeHeat:
        icon = Icons.wb_sunny_rounded;
        label = 'Upał > 34°C';
        color = Colors.orange;
        break;
      case WeatherCondition.overcast:
        icon = Icons.cloud_rounded;
        label = 'Pochmurno';
        color = Colors.blueGrey;
        break;
      case WeatherCondition.sunny:
        icon = Icons.wb_sunny_outlined;
        label = 'Słonecznie';
        color = AppColors.goldAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            '${stage.baseTemperatureCelsius.round()}°C • $label',
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 1: PROFIL ETAPU, POGODA, WIATR & SEKTORY
  // ===========================================================================

  Widget _buildTabProfileAndWind(RaceStage stage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil wysokościowy etapu
          Container(
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.show_chart_rounded, color: AppColors.goldAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'PROFIL WYSOKOŚCIOWY: ${stage.name.toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Przeciągnij suwak, by zbadać nachylenia',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: ElevationProfileChart(
                    stage: stage,
                    height: 250,
                    showHeader: false,
                    enableScrubber: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Siatka: Pogoda i Analiza Wiatru & Wachlarzy
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Karta Pogody & Nawierzchni
              Expanded(
                flex: 5,
                child: _buildWeatherAnalysisCard(stage),
              ),
              const SizedBox(width: 14),

              // Karta Wiatru & Zagrożenia Wachlarzami
              Expanded(
                flex: 6,
                child: _buildWindEchelonAnalysisCard(stage),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wykaz kluczowych sektorów i podjazdów
          _buildKeySegmentsCard(stage),
        ],
      ),
    );
  }

  Widget _buildWeatherAnalysisCard(RaceStage stage) {
    final bool isRain = stage.weatherCondition == WeatherCondition.lightRain ||
        stage.weatherCondition == WeatherCondition.heavyStorm;
    final bool hasCobbles = stage.segments.any((s) => s.isCobblestone);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.thermostat_rounded, color: _cyanAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'WARUNKI ATMOSFERYCZNE',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildDetailInfoRow('Temperatura odczuwalna', '${stage.baseTemperatureCelsius.toStringAsFixed(1)} °C'),
          _buildDetailInfoRow('Opady i stan asfaltu', isRain ? 'Mokry / Śliski asfalt (Ryzyko kraks)' : 'Suchy i szybki'),
          _buildDetailInfoRow('Przyczepność w zakrętach', isRain ? '62% (Wymagana ostrożność)' : '98% (Optymalna)'),
          _buildDetailInfoRow('Nawierzchnia specjalna', hasCobbles ? 'Sektory brukowane (Paris-Roubaix)' : 'Gładki asfalt szosowy'),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRain ? _cyanAccent.withValues(alpha: 0.1) : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isRain ? _cyanAccent.withValues(alpha: 0.4) : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  isRain ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                  color: isRain ? _cyanAccent : _emeraldGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRain
                        ? 'Zalecenie mechanika: Obniż ciśnienie w oponach o 0.6 bar i wybierz miękką mieszankę deszczową!'
                        : 'Warunki idealne na wysokie ciśnienie i maksymalną prędkość toczenia.',
                    style: TextStyle(
                      color: isRain ? _cyanAccent : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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

  Widget _buildWindEchelonAnalysisCard(RaceStage stage) {
    final double windSpeed = stage.windSpeedKmh;

    // Szukanie sektorów z bocznym wiatrem (kąt 60° - 120°)
    final crosswindSegments = stage.segments.where((s) {
      final angle = s.relativeWindAngleDegrees;
      return angle >= 65.0 && angle <= 115.0;
    }).toList();

    final bool hasHighCrosswindRisk = windSpeed >= 25.0 && crosswindSegments.isNotEmpty;
    final bool hasModerateRisk = windSpeed >= 18.0 && crosswindSegments.isNotEmpty;

    Color riskColor = _emeraldGreen;
    String riskLabel = 'NISKIE RYZYKO WACHLARZA';
    String riskExplanation = 'Wiatr zbyt słaby (< 18 km/h), by peleton pękł na otwartej przestrzeni.';

    if (hasHighCrosswindRisk) {
      riskColor = _crimsonAlert;
      riskLabel = 'BARDZO WYSOKIE RYZYKO RANTOWANIA!';
      riskExplanation = 'Boczny wiatr ${windSpeed.round()} km/h! Peleton rozerwie się na wachlarze. Liderzy muszą jechać w czubie!';
    } else if (hasModerateRisk) {
      riskColor = _amberWarning;
      riskLabel = 'UMIARKOWANE RYZYKO WACHLARZA';
      riskExplanation = 'Boczny wiatr ${windSpeed.round()} km/h na wybranych odcinkach. Czujna jazda w czołówce.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.air_rounded, color: riskColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'RÓŻA WIATRÓW & WACHLARZE (ECHELONS)',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // Wizualny kompas wiatru
              _buildWindCompassWidget(stage.windSpeedKmh),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailInfoRow('Średnia siła wiatru', '${windSpeed.round()} km/h'),
                    _buildDetailInfoRow('Porywy na odsłoniętych polach', '${(windSpeed * 1.35).round()} km/h'),
                    _buildDetailInfoRow('Odcinki z bocznym wiatrem', '${crosswindSegments.length} sektorów na trasie'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign_rounded, color: riskColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    riskExplanation,
                    style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindCompassWidget(double speedKmh) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceLight,
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text('N', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800)),
          Transform.rotate(
            angle: 1.2, // ~70 stopni kąta bocznego
            child: const Icon(Icons.navigation_rounded, color: AppColors.goldAccent, size: 28),
          ),
          Positioned(
            bottom: 6,
            child: Text(
              '${speedKmh.round()} km/h',
              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeySegmentsCard(RaceStage stage) {
    final climbsAndCobbles = stage.segments.where((s) => s.isKom || s.isCobblestone || s.isIntermediateSprint).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.goldAccent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'KLUCZOWE PUNKTY ETAPU (KOM, SPRINTY, BRUKI)',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                'Łącznie punktów: ${climbsAndCobbles.length}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (climbsAndCobbles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Etap o łagodnym profilu bez kategoryzowanych premii górskich.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: climbsAndCobbles.take(6).length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 12),
              itemBuilder: (ctx, idx) {
                final seg = climbsAndCobbles[idx];
                return Row(
                  children: [
                    Text(
                      'km ${seg.startKm.toStringAsFixed(1)}',
                      style: const TextStyle(color: _cyanAccent, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 12),
                    if (seg.isKom) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'KOM Kat. ${seg.climbCategory ?? "Góra"}',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dystans: ${seg.lengthKm.toStringAsFixed(1)} km • Śr. ${seg.gradientPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                      ),
                    ] else if (seg.isIntermediateSprint) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _emeraldGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Lotna Premia',
                          style: TextStyle(color: _emeraldGreen, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sprint o zieloną koszulkę i punkty',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 11),
                      ),
                    ] else if (seg.isCobblestone) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _amberWarning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Bruk Pavé ★★★★',
                          style: TextStyle(color: _amberWarning, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sektor brukowy: ${seg.lengthKm.toStringAsFixed(1)} km',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDetailInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 2: KONFIGURACJA SPRZĘTU (KOŁA, OPONY, CIŚNIENIE)
  // ===========================================================================

  Widget _buildTabEquipment(RaceStage stage) {
    final previewRiderId = _selectedRiderForBikePreview ?? _stageLineup.first.id;
    final configuredBike = _buildConfiguredBikeForRider(previewRiderId, stage);
    final optimalPressure = _calculateOptimalPressure(stage, _stageLineup.firstWhere((r) => r.id == previewRiderId));

    final double pressureDelta = (_teamTirePressureBar - optimalPressure).abs();
    final bool isPressureOptimal = pressureDelta <= 0.2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Szybkie presety konfiguracji
          const Text(
            'SZYBKIE PRESETY DRUŻYNOWE NA ETAP:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: StageBikePreset.values.map((preset) {
                final bool isSelected = _activePreset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _applyPreset(preset),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? preset.color.withValues(alpha: 0.2) : _cardSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? preset.color : AppTheme.borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(preset.icon, color: isSelected ? preset.color : AppColors.textSecondary, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.title,
                                style: TextStyle(
                                  color: isSelected ? preset.color : AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                preset.subtitle,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Podgląd roweru wyścigowego (BikePreviewWidget)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(12),
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
                        Icon(Icons.pedal_bike_rounded, color: AppColors.goldAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'MASZYNA STARTOWA: DRUGIE POKOLENIE WORLDTOUR',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Text(
                      'Waga: ${configuredBike.totalWeightKg.toStringAsFixed(2)} kg (Limit UCI: 6.80 kg)',
                      style: const TextStyle(color: _cyanAccent, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Podgląd wizualny roweru
                SizedBox(
                  height: 190,
                  child: Center(
                    child: BikePreviewWidget(
                      bike: configuredBike,
                      height: 180,
                      showSpecsPill: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sekcja parametrów: Koła, Opony, Ciśnienie i Smarowanie
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolumna 1: Koła i wysokość stożka
              Expanded(
                child: _buildWheelsetSelectorCard(),
              ),
              const SizedBox(width: 14),

              // Kolumna 2: Opony, ciśnienie i smarowanie
              Expanded(
                child: _buildTireAndPressureCard(stage, optimalPressure, isPressureOptimal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheelsetSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tire_repair_rounded, color: _cyanAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'WYSOKOŚĆ STOŻKA KÓŁ',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildRimDepthOption(
            depthMm: 33,
            name: '33 mm • Niskoprofilowe',
            weightGrams: 1180,
            aeroWatts: '+0.0 W',
            advantage: 'Minimalna masa na alpejskie wspinaczki, zerowa podatność na wiatr boczny.',
          ),
          const SizedBox(height: 8),
          _buildRimDepthOption(
            depthMm: 45,
            name: '45 mm • All-Round',
            weightGrams: 1350,
            aeroWatts: '-4.5 W',
            advantage: 'Złoty środek: znakomita dynamika na podjazdach i odczuwalny zysk aero.',
          ),
          const SizedBox(height: 8),
          _buildRimDepthOption(
            depthMm: 60,
            name: '60 mm • Wysoki Stożek Aero',
            weightGrams: 1520,
            aeroWatts: '-8.2 W',
            advantage: 'Maksymalny zysk watów na płaskich etapach i finiszach sprinterskich.',
          ),
        ],
      ),
    );
  }

  Widget _buildRimDepthOption({
    required int depthMm,
    required String name,
    required int weightGrams,
    required String aeroWatts,
    required String advantage,
  }) {
    final bool isSelected = _teamRimDepthMm == depthMm;

    return InkWell(
      onTap: () {
        setState(() {
          _teamRimDepthMm = depthMm;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? _cyanAccent.withValues(alpha: 0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? _cyanAccent : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? _cyanAccent : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$weightGrams g • $aeroWatts',
                  style: const TextStyle(color: AppColors.goldAccent, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(advantage, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildTireAndPressureCard(RaceStage stage, double optimalPressure, bool isOptimal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed_rounded, color: AppColors.goldAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'OPONY, CIŚNIENIE & NAPĘD',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Szerokość opony (25, 28, 30, 32)
          Row(
            children: [
              const Text('Szerokość:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const Spacer(),
              ...[25, 28, 30, 32].map((w) {
                final isSelected = _teamTireWidthMm == w;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _teamTireWidthMm = w;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.goldAccent : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${w}mm',
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),

          // Suwak ciśnienia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ciśnienie w oponach:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text(
                '${_teamTirePressureBar.toStringAsFixed(1)} bar (${(_teamTirePressureBar * 14.5038).round()} PSI)',
                style: TextStyle(
                  color: isOptimal ? _emeraldGreen : _amberWarning,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Slider(
            value: _teamTirePressureBar,
            min: 3.2,
            max: 7.0,
            divisions: 38,
            activeColor: isOptimal ? _emeraldGreen : _amberWarning,
            inactiveColor: Colors.white12,
            onChanged: (val) {
              setState(() {
                _teamTirePressureBar = double.parse(val.toStringAsFixed(1));
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rekomendowane: ${optimalPressure.toStringAsFixed(1)} bar',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isOptimal ? _emeraldGreen : _amberWarning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOptimal ? 'IDEALNE CIŚNIENIE' : (_teamTirePressureBar > optimalPressure ? 'ZBYT TWARDE NA BRUK' : 'ZBYT NISKIE'),
                  style: TextStyle(
                    color: isOptimal ? _emeraldGreen : _amberWarning,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Smarowanie napędu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Smarowanie łańcucha:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Gorący Wosk (-3.5W)', style: TextStyle(fontSize: 10)),
                    selected: _teamIsHotMeltWax,
                    selectedColor: AppColors.goldAccent,
                    onSelected: (val) => setState(() => _teamIsHotMeltWax = true),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Olej Mokry', style: TextStyle(fontSize: 10)),
                    selected: !_teamIsHotMeltWax,
                    selectedColor: _cyanAccent,
                    onSelected: (val) => setState(() => _teamIsHotMeltWax = false),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 3: PRZYPISANIE RÓL TAKTYCZNYCH DLA KOLARZY
  // ===========================================================================

  Widget _buildTabTacticsAndRoles(RaceStage stage) {
    final int breakawayCount = _assignedRoles.values.where((r) => r == StageTacticalRole.breakawayHunter).length;
    final int leaderCount = _assignedRoles.values.where((r) => r == StageTacticalRole.protectedLeader).length;
    final int sprinterCount = _assignedRoles.values.where((r) => r == StageTacticalRole.sprintFinisher).length;
    final int helperCount = _assignedRoles.values.where((r) =>
        r == StageTacticalRole.bodyguardRoadCaptain ||
        r == StageTacticalRole.mountainPaceSetter ||
        r == StageTacticalRole.waterCarrier).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baner odprawy Dyrektora Sportowego (DS Briefing Speech)
          _buildDsBriefingSpeechCard(stage, breakawayCount, leaderCount, sprinterCount),
          const SizedBox(height: 14),

          // Pasek podsumowania ról w zespole
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRoleStatItem('Uciekinier', breakawayCount, const Color(0xFFF59E0B)),
                _buildRoleStatItem('Lider GC', leaderCount, const Color(0xFFFFD700)),
                _buildRoleStatItem('Sprinter', sprinterCount, const Color(0xFF10B981)),
                _buildRoleStatItem('Pomocnicy', helperCount, const Color(0xFF818CF8)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista kolarzy do przypisania ról
          const Text(
            'KADRA ZESPOŁU NA DZISIEJSZY ETAP (7-8 ZAWODNIKÓW):',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stageLineup.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final rider = _stageLineup[idx];
              final currentRole = _assignedRoles[rider.id] ?? StageTacticalRole.freeAgent;
              return _buildRiderTacticalCard(rider, currentRole);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleStatItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildDsBriefingSpeechCard(
    RaceStage stage,
    int breakawayCount,
    int leaderCount,
    int sprinterCount,
  ) {
    String speech;

    if (stage.segments.any((s) => s.isCobblestone)) {
      speech =
          '„Panowie, dzisiaj Piekło Północy! Sektory brukowane zaczną się po 90. kilometrze. '
          'Wszyscy trzymać się blisko lidera przed wjazdem w Arenberg. ${breakawayCount > 0 ? "Uciekinier zabiera się od razu po starcie, by zdjąć presję." : "Zostajemy czujni w peletonie."} '
          'Ciśnienie w oponach obniżone, żadnego panikowania w kurzu!”';
    } else if (stage.stageType == StageType.highMountain || stage.stageType == StageType.summitFinish) {
      speech =
          '„Królewski etap wysokogórski! Kluczowa próba pod finałowy podjazd. '
          'Pomocnicy dyktują równe tempo na dolnych serpentynach. Lider chroni energię w tunelu aero '
          'i rusza dopiero na ostatnich 5 kilometrach. Żadnych strat czasu w generalce!”';
    } else if (stage.windSpeedKmh >= 24.0) {
      speech =
          '„Uwaga na boczny wiatr! Prognoza przewiduje porywy do ${(stage.windSpeedKmh * 1.35).round()} km/h na otwartych polach. '
          'Jedziemy w pierwszej piętnastce peletonu, by nie dać się odciąć w drugim wachlarzu! '
          'Pomocnicy osłaniają kapitana z prawej strony.”';
    } else {
      speech =
          '„Płaski etap pod klasyczny sprint z peletonu. '
          '${breakawayCount > 0 ? "Nasz uciekinier powalczy o premie lotne i ekspozycję sponsorów." : "Jedziemy spokojnie w szyku."} '
          'Na ostatnich 3 kilometrach formujemy pociąg rozprowadzający z pełną prędkością!”';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.record_voice_over_rounded, color: AppColors.goldAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ODPRAWA DYREKTORA SPORTOWEGO (DS DISPATCH):',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  speech,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderTacticalCard(Rider rider, StageTacticalRole currentRole) {
    final double wPerKg = rider.physiology.wattsPerKg;
    final double tsb = rider.health.trainingStressBalance;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: currentRole.badgeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Awatar kolarza
          RiderAvatarWidget(
            appearance: rider.appearance,
            size: 46,
            showHelmet: true,
          ),
          const SizedBox(width: 12),

          // Dane personalne i forma
          Expanded(
            flex: 3,
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
                      rider.nationalityIso.toUpperCase(),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'FTP: ${rider.physiology.ftpWatts}W (${wPerKg.toStringAsFixed(1)} W/kg)',
                      style: const TextStyle(color: _cyanAccent, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: (tsb >= 10 ? _emeraldGreen : (tsb < -10 ? _crimsonAlert : AppColors.goldAccent)).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TSB: ${tsb > 0 ? "+${tsb.round()}" : "${tsb.round()}"}',
                        style: TextStyle(
                          color: (tsb >= 10 ? _emeraldGreen : (tsb < -10 ? _crimsonAlert : AppColors.goldAccent)),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Selektor roli taktycznej
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<StageTacticalRole>(
              initialValue: currentRole,
              dropdownColor: const Color(0xFF1E2330),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              items: StageTacticalRole.values.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(role.icon, color: role.badgeColor, size: 14),
                      const SizedBox(width: 6),
                      Text(role.shortLabel, style: TextStyle(color: role.badgeColor, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newRole) {
                if (newRole != null) {
                  setState(() {
                    _assignedRoles[rider.id] = newRole;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DOLNY PASEK STARTU ETAPU
  // ===========================================================================

  Widget _buildBottomActionBar({
    required BuildContext context,
    required CareerSave? save,
    required RaceStage activeStage,
    required RaceSimulationNotifier simController,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SKŁAD: ${_stageLineup.length} KOLARZY GOTOWYCH',
                style: const TextStyle(color: _emeraldGreen, fontSize: 11, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                'Sprzęt: ${_activePreset.title} (${_teamRimDepthMm}mm / ${_teamTireWidthMm}mm)',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              if (save != null) {
                _launchRaceSimulation(
                  context: context,
                  save: save,
                  activeStage: activeStage,
                  simController: simController,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Brak aktywnego zapisu kariery – uruchomiono symulację próbną.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.sports_score_rounded, size: 20, color: Colors.black),
            label: const Text(
              'RUSZAJ NA START ETAPU! 🏁',
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // METODY POMOCNICZE I FALLBACKI
  // ===========================================================================

  RaceStage? _resolveNextUpcomingStage(CareerSave? save) {
    if (save == null || save.calendar.races.isEmpty) return null;

    for (final race in save.calendar.races) {
      if (race.stages.isNotEmpty) {
        return race.stages.first;
      }
    }
    return null;
  }

  TourRace? _resolveNextUpcomingRace(CareerSave? save, RaceStage stage) {
    if (save == null) return null;
    for (final race in save.calendar.races) {
      if (race.stages.any((s) => s.id == stage.id)) {
        return race;
      }
    }
    return save.calendar.races.isNotEmpty ? save.calendar.races.first : null;
  }

  RaceStage _generateFallbackStage() {
    return StageProfileBuilder.buildCobbledClassicStage(
      id: 'briefing_roubaix_stage',
      stageNumber: 5,
      name: 'Lille Metropole > Arenberg Porte du Hainaut',
      distanceKm: 157.0,
      sectors: [
        StageProfileBuilder.alpeDHuez,
        StageProfileBuilder.tourmalet,
      ],
      baseElevationM: 45.0,
      baseTemperatureCelsius: 16.0,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 28.0,
    );
  }

  List<Rider> _generateSampleBriefingLineup() {
    return [
      RiderProceduralGenerator.generateRider(
        id: 'sample_leader',
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 94,
        teamId: 'team_player',
      ),
      RiderProceduralGenerator.generateRider(
        id: 'sample_sprinter',
        specialization: RiderSpecialization.pureSprinter,
        targetOverallRating: 91,
        teamId: 'team_player',
      ),
      RiderProceduralGenerator.generateRider(
        id: 'sample_breakaway',
        specialization: RiderSpecialization.breakawaySpecialist,
        targetOverallRating: 88,
        teamId: 'team_player',
      ),
      RiderProceduralGenerator.generateRider(
        id: 'sample_domestique_1',
        specialization: RiderSpecialization.domestiqueEngine,
        targetOverallRating: 84,
        teamId: 'team_player',
      ),
      RiderProceduralGenerator.generateRider(
        id: 'sample_domestique_2',
        specialization: RiderSpecialization.domestiqueEngine,
        targetOverallRating: 82,
        teamId: 'team_player',
      ),
      RiderProceduralGenerator.generateRider(
        id: 'sample_leadout',
        specialization: RiderSpecialization.puncher,
        targetOverallRating: 85,
        teamId: 'team_player',
      ),
      RiderProceduralGenerator.generateRider(
        id: 'sample_climber',
        specialization: RiderSpecialization.pureClimber,
        targetOverallRating: 86,
        teamId: 'team_player',
      ),
    ];
  }
}
