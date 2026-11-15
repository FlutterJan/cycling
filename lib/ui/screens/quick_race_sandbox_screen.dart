import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../services/generators/fictional_brands_catalog.dart';
import '../../services/generators/stage_profile_builder.dart';
import '../../services/generators/uci_calendar_generator.dart';
import '../../services/generators/world_teams_generator.dart';
import '../../state/race_simulation_notifier.dart';
import '../widgets/elevation_profile_chart.dart';
import 'race_simulation_screen.dart';

/// Typ presetu trasy w Laboratorium Taktycznym Sandbox
enum QuickRacePresetType {
  alpeDHuezSummit,
  parisRoubaixCobbles,
  champsElyseesSprint,
  qatarCrosswind,
  mountainItt,
}

/// Opcja pogody dostępna w Sandboxie
enum SandboxWeatherPreset {
  sunny,
  heavyRain,
  thunderstorm,
  extremeHeat38,
  mountainFrost2,
}

/// Szybki preset sprzętowy dla całej drużyny
enum SandboxBikePreset {
  fullAero65mm,
  ultralightClimbing,
  cobbleTubeless32mm,
}

/// Ekran "Szybki Wyścig / Laboratorium Taktyczne Sandbox" (Zadanie #166).
/// Pozwala skonfigurować i uruchomić dowolny wyścig 3D w 10 sekund z poziomu menu głównego.
class QuickRaceSandboxScreen extends ConsumerStatefulWidget {
  const QuickRaceSandboxScreen({super.key});

  @override
  ConsumerState<QuickRaceSandboxScreen> createState() =>
      _QuickRaceSandboxScreenState();
}

class _QuickRaceSandboxScreenState extends ConsumerState<QuickRaceSandboxScreen>
    with SingleTickerProviderStateMixin {
  late final WorldTourGenerationResult _worldData;
  late final List<TourRace> _allCalendarRaces;
  late final List<_QuickStageEntry> _presetStages;
  late final TabController _mobileTabController;

  // Kolumna 1: Trasa i Warunki
  bool _showAllRacesList = false;
  String _stageSearchQuery = '';
  late RaceStage _baseStage;
  String _selectedStageKey = 'preset_alpe';
  SandboxWeatherPreset _weatherPreset = SandboxWeatherPreset.sunny;
  double _windSpeedKmh = 18.0;
  double _windDirectionDegrees = 270.0;

  // Kolumna 2: Drużyna i Skład
  late CyclingTeam _selectedTeam;
  List<Rider> _teamFullRoster = const [];
  List<Rider> _selectedLineup = const [];
  String _teamSearchQuery = '';

  // Kolumna 3: Sprzęt
  SandboxBikePreset _bikePreset = SandboxBikePreset.ultralightClimbing;

  // Stan przycisku startowego
  bool _isStartingRace = false;

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 3, vsync: this);
    _worldData = WorldTeamsGenerator.generateWorldTourSystem(seed: 2026);
    final teamIds = _worldData.teams.map((t) => t.id).toList();
    _allCalendarRaces = UciCalendarGenerator.generateFullSeasonCalendar(
      seasonYear: 2026,
      participatingTeamIds: teamIds,
    );
    _presetStages = _buildPresetStages();

    final firstPreset = _presetStages.first;
    _selectedStageKey = firstPreset.key;
    _baseStage = firstPreset.stage;
    _weatherPreset = firstPreset.defaultWeather;
    _windSpeedKmh = firstPreset.defaultWindKmh;
    _windDirectionDegrees = firstPreset.defaultWindDir;

    _selectedTeam = _worldData.worldTourTeams.first;
    _teamFullRoster = _worldData.getTeamRoster(_selectedTeam.id);
    _autoPickOptimalRoster(notify: false);
    _suggestBikePresetForStage(_baseStage, notify: false);
  }

  @override
  void dispose() {
    _mobileTabController.dispose();
    super.dispose();
  }

  List<_QuickStageEntry> _buildPresetStages() {
    final alpeStage = StageProfileBuilder.buildHighMountainStage(
      id: 'sandbox_alpe_dhuez',
      stageNumber: 18,
      name: "Alpe d'Huez Summit Finish",
      distanceKm: 164.5,
      climbs: const [
        StageProfileBuilder.galibier,
        StageProfileBuilder.alpeDHuez,
      ],
      isSummitFinish: true,
      baseTemperatureCelsius: 19.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 16.0,
    );

    final roubaixStage = StageProfileBuilder.buildCobbledClassicStage(
      id: 'sandbox_roubaix',
      stageNumber: 1,
      name: 'Paryż-Roubaix 5-Star Cobbles',
      distanceKm: 256.6,
      sectors: StageProfileBuilder.getParisRoubaixSectors(),
      baseTemperatureCelsius: 12.0,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 28.0,
    );

    final champsStage = StageProfileBuilder.buildFlatSprintStage(
      id: 'sandbox_champs_elysees',
      stageNumber: 21,
      name: 'Champs-Élysées Sprint',
      distanceKm: 115.2,
      baseElevationM: 35.0,
      windSpeedKmh: 12.0,
      weatherCondition: WeatherCondition.sunny,
      includesCrosswindZone: false,
    );

    final qatarStage = StageProfileBuilder.buildFlatSprintStage(
      id: 'sandbox_qatar_crosswind',
      stageNumber: 3,
      name: 'Wachlarze w Katarze 50 km/h Crosswind',
      distanceKm: 146.0,
      baseElevationM: 12.0,
      windSpeedKmh: 50.0,
      windDirectionDegrees: 0.0,
      weatherCondition: WeatherCondition.crosswindGale,
      includesCrosswindZone: true,
    );

    final mountainIttStage = StageProfileBuilder.buildTimeTrialStage(
      id: 'sandbox_mountain_itt',
      stageNumber: 16,
      name: 'Górska Czasówka ITT',
      distanceKm: 34.8,
      intermediateClimb: StageProfileBuilder.alpeDHuez,
      startElevationM: 720.0,
      windSpeedKmh: 14.0,
    );

    return [
      _QuickStageEntry(
        key: 'preset_alpe',
        title: "Alpe d'Huez Summit Finish",
        subtitle: '164.5 km • HC Galibier + Alpe d\'Huez',
        badge: 'GÓRY HC',
        badgeColor: AppColors.crimsonAlert,
        stage: alpeStage,
        defaultWeather: SandboxWeatherPreset.sunny,
        defaultWindKmh: 16.0,
        defaultWindDir: 250.0,
      ),
      _QuickStageEntry(
        key: 'preset_roubaix',
        title: 'Paryż-Roubaix 5-Star Cobbles',
        subtitle: '256.6 km • Trouée d\'Arenberg & Carrefour',
        badge: 'BRUK 5★',
        badgeColor: AppColors.amberWarning,
        stage: roubaixStage,
        defaultWeather: SandboxWeatherPreset.heavyRain,
        defaultWindKmh: 28.0,
        defaultWindDir: 290.0,
      ),
      _QuickStageEntry(
        key: 'preset_champs',
        title: 'Champs-Élysées Sprint',
        subtitle: '115.2 km • Finałowy sprint w Paryżu',
        badge: 'SPRINT',
        badgeColor: AppColors.statusSuccess,
        stage: champsStage,
        defaultWeather: SandboxWeatherPreset.sunny,
        defaultWindKmh: 12.0,
        defaultWindDir: 225.0,
      ),
      _QuickStageEntry(
        key: 'preset_qatar',
        title: 'Wachlarze w Katarze 50 km/h Crosswind',
        subtitle: '146.0 km • Otwarta pustynia, ranty echelon',
        badge: 'RANTY 50+',
        badgeColor: AppColors.cyanAccent,
        stage: qatarStage,
        defaultWeather: SandboxWeatherPreset.extremeHeat38,
        defaultWindKmh: 50.0,
        defaultWindDir: 0.0,
      ),
      _QuickStageEntry(
        key: 'preset_itt',
        title: 'Górska Czasówka ITT',
        subtitle: '34.8 km • Walka z czasem pod górę',
        badge: 'ITT',
        badgeColor: AppColors.accentBlue,
        stage: mountainIttStage,
        defaultWeather: SandboxWeatherPreset.mountainFrost2,
        defaultWindKmh: 14.0,
        defaultWindDir: 180.0,
      ),
    ];
  }

  WeatherCondition _mapWeatherCondition(
      SandboxWeatherPreset preset, double windKmh) {
    if (windKmh >= 42.0 && preset == SandboxWeatherPreset.sunny) {
      return WeatherCondition.crosswindGale;
    }
    switch (preset) {
      case SandboxWeatherPreset.sunny:
        return WeatherCondition.sunny;
      case SandboxWeatherPreset.heavyRain:
        return WeatherCondition.lightRain;
      case SandboxWeatherPreset.thunderstorm:
        return WeatherCondition.heavyStorm;
      case SandboxWeatherPreset.extremeHeat38:
        return WeatherCondition.extremeHeat;
      case SandboxWeatherPreset.mountainFrost2:
        return WeatherCondition.overcast;
    }
  }

  double _mapTemperatureCelsius(SandboxWeatherPreset preset) {
    switch (preset) {
      case SandboxWeatherPreset.sunny:
        return 22.0;
      case SandboxWeatherPreset.heavyRain:
        return 13.0;
      case SandboxWeatherPreset.thunderstorm:
        return 11.0;
      case SandboxWeatherPreset.extremeHeat38:
        return 38.0;
      case SandboxWeatherPreset.mountainFrost2:
        return 2.0;
    }
  }

  RaceStage get _configuredStage {
    final mappedWeather = _mapWeatherCondition(_weatherPreset, _windSpeedKmh);
    final mappedTemp = _mapTemperatureCelsius(_weatherPreset);
    final updatedSegments = _baseStage.segments
        .map(
          (seg) => StageSegment(
            index: seg.index,
            startKm: seg.startKm,
            lengthKm: seg.lengthKm,
            startElevationM: seg.startElevationM,
            endElevationM: seg.endElevationM,
            surfaceType: seg.surfaceType,
            technicalDifficulty: seg.technicalDifficulty,
            windDirectionDegrees: _windDirectionDegrees,
            roadBearingDegrees: seg.roadBearingDegrees,
            sprintOrKomClassification: seg.sprintOrKomClassification,
          ),
        )
        .toList(growable: false);

    return _baseStage.copyWith(
      weatherCondition: mappedWeather,
      baseTemperatureCelsius: mappedTemp,
      windSpeedKmh: _windSpeedKmh,
      segments: updatedSegments,
    );
  }

  void _selectPreset(_QuickStageEntry entry) {
    setState(() {
      _selectedStageKey = entry.key;
      _baseStage = entry.stage;
      _weatherPreset = entry.defaultWeather;
      _windSpeedKmh = entry.defaultWindKmh;
      _windDirectionDegrees = entry.defaultWindDir;
    });
    _suggestBikePresetForStage(entry.stage);
  }

  void _selectCalendarStage(String key, RaceStage stage) {
    setState(() {
      _selectedStageKey = key;
      _baseStage = stage;
      _windSpeedKmh = stage.windSpeedKmh.clamp(0.0, 70.0);
      if (stage.segments.isNotEmpty) {
        _windDirectionDegrees = stage.segments.first.windDirectionDegrees;
      }
      _weatherPreset = _inferWeatherPreset(stage);
    });
    _suggestBikePresetForStage(stage);
  }

  SandboxWeatherPreset _inferWeatherPreset(RaceStage stage) {
    if (stage.baseTemperatureCelsius >= 33.0 ||
        stage.weatherCondition == WeatherCondition.extremeHeat) {
      return SandboxWeatherPreset.extremeHeat38;
    }
    if (stage.baseTemperatureCelsius <= 5.0) {
      return SandboxWeatherPreset.mountainFrost2;
    }
    switch (stage.weatherCondition) {
      case WeatherCondition.heavyStorm:
        return SandboxWeatherPreset.thunderstorm;
      case WeatherCondition.lightRain:
        return SandboxWeatherPreset.heavyRain;
      default:
        return SandboxWeatherPreset.sunny;
    }
  }

  void _suggestBikePresetForStage(RaceStage stage, {bool notify = true}) {
    final SandboxBikePreset suggested;
    if (stage.stageType == StageType.cobbleClassic ||
        stage.segments.any((s) => s.isCobblestone)) {
      suggested = SandboxBikePreset.cobbleTubeless32mm;
    } else if (stage.stageType == StageType.highMountain ||
        stage.stageType == StageType.summitFinish ||
        stage.totalElevationGainM > 2400) {
      suggested = SandboxBikePreset.ultralightClimbing;
    } else {
      suggested = SandboxBikePreset.fullAero65mm;
    }

    if (notify) {
      setState(() => _bikePreset = suggested);
    } else {
      _bikePreset = suggested;
    }
  }

  double _scoreRiderForCurrentStage(Rider rider) {
    final stage = _configuredStage;
    final wkg = rider.physiology.wattsPerKg;
    final ftp = rider.physiology.ftpWatts.toDouble();
    final sprint5s = rider.powerProfile.watts5s;
    final punch1m = rider.powerProfile.watts1m /
        math.max(50.0, rider.physiology.weightKg);
    final vo25m = rider.powerProfile.watts5m /
        math.max(50.0, rider.physiology.weightKg);
    final skills = rider.skills;

    double weatherBonus = 0.0;
    if (_weatherPreset == SandboxWeatherPreset.heavyRain ||
        _weatherPreset == SandboxWeatherPreset.thunderstorm) {
      weatherBonus += skills.rainResistance * 0.25;
    } else if (_weatherPreset == SandboxWeatherPreset.extremeHeat38) {
      weatherBonus += skills.heatTolerance * 0.25;
    }
    if (_windSpeedKmh >= 35.0) {
      weatherBonus += skills.draftingEfficiency * 0.35 + skills.raceIq * 0.2;
    }

    switch (stage.stageType) {
      case StageType.summitFinish:
      case StageType.highMountain:
        return (wkg * 18.0) +
            (vo25m * 8.0) +
            (rider.physiology.vo2Max * 0.6) +
            (skills.descending * 0.25) +
            weatherBonus;
      case StageType.cobbleClassic:
        return (skills.cobbles * 1.4) +
            (skills.bikeHandling * 0.7) +
            (vo25m * 7.0) +
            (ftp * 0.08) +
            weatherBonus;
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        final climbWeight = stage.totalElevationGainM > 900 ? 10.0 : 2.0;
        return (skills.timeTrialPositioning * 1.2) +
            (skills.aeroPositioning * 0.8) +
            (ftp * 0.16) +
            (wkg * climbWeight) +
            weatherBonus;
      case StageType.hilly:
        return (punch1m * 7.5) +
            (vo25m * 6.5) +
            (skills.punch * 0.8) +
            (skills.descending * 0.3) +
            weatherBonus;
      case StageType.flat:
        return (sprint5s * 0.075) +
            (skills.draftingEfficiency * 0.7) +
            (skills.aeroPositioning * 0.5) +
            (skills.bikeHandling * 0.4) +
            weatherBonus;
    }
  }

  void _autoPickOptimalRoster({bool notify = true}) {
    final sorted = List<Rider>.from(_teamFullRoster)
      ..sort(
        (a, b) =>
            _scoreRiderForCurrentStage(b).compareTo(_scoreRiderForCurrentStage(a)),
      );
    final picked = sorted.take(8).toList(growable: false);
    if (notify) {
      setState(() {
        _selectedLineup = picked;
      });
    } else {
      _selectedLineup = picked;
    }
  }

  void _selectTeam(CyclingTeam team) {
    setState(() {
      _selectedTeam = team;
      _teamFullRoster = _worldData.getTeamRoster(team.id);
    });
    _autoPickOptimalRoster();
  }

  CompleteBike _buildBikeForPreset(SandboxBikePreset preset, String brandId) {
    switch (preset) {
      case SandboxBikePreset.fullAero65mm:
        final base = FictionalBrandsCatalog.assembleBike(
          brandId: brandId,
          frameCategory: FrameCategory.aero,
          cockpitWidthMm: 370,
          hoodInwardTiltDegrees: 12.0,
          slammedStem: true,
        );
        return base.copyWith(
          id: 'sandbox_bike_full_aero_65',
          name: 'Full Aero 65mm Pro',
          wheelset: base.wheelset.copyWith(
            name: '${base.wheelset.name} 65mm',
            rimDepthMm: 65,
            aeroCdaModifier: -0.0115,
            crosswindStabilityPenalty: 0.42,
          ),
        );
      case SandboxBikePreset.ultralightClimbing:
        final base = FictionalBrandsCatalog.assembleBike(
          brandId: brandId,
          frameCategory: FrameCategory.lightweightClimbing,
          cockpitWidthMm: 390,
          hoodInwardTiltDegrees: 6.0,
          slammedStem: true,
        );
        return base.copyWith(
          id: 'sandbox_bike_ultralight_68',
          name: 'Ultralight Climbing 6.8kg',
          frame: base.frame.copyWith(weightGrams: 680),
          wheelset: base.wheelset.copyWith(
            rimDepthMm: 32,
            weightGrams: 1180,
          ),
        );
      case SandboxBikePreset.cobbleTubeless32mm:
        final base = FictionalBrandsCatalog.assembleBike(
          brandId: brandId,
          frameCategory: FrameCategory.cobbleEndurance,
          cockpitWidthMm: 410,
          hoodInwardTiltDegrees: 4.0,
          slammedStem: false,
        );
        final cobbleTire = TireModel(
          id: 'sandbox_tire_cobble_32',
          brandId: brandId,
          name: 'Roubaix Tubeless 32mm (3.8 bar)',
          widthMm: 32,
          weightGrams: 295,
          rollingResistanceCrr: 0.0038,
          punctureResistanceIndex: 4.8,
          wetGripIndex: 4.7,
          isTubeless: true,
          priceEur: 95,
        );
        return base.copyWith(
          id: 'sandbox_bike_cobble_32',
          name: 'Cobble Tubeless 32mm 3.8 bar',
          tire: cobbleTire,
          wheelset: base.wheelset.copyWith(
            rimDepthMm: 38,
            crosswindStabilityPenalty: 0.12,
          ),
        );
    }
  }

  Future<void> _start3dSimulation() async {
    if (_selectedLineup.isEmpty || _isStartingRace) return;
    setState(() => _isStartingRace = true);

    final configuredStage = _configuredStage;
    final playerBike = _buildBikeForPreset(
      _bikePreset,
      _selectedTeam.bikeDeal.brandId,
    );

    // Zbuduj pełny peleton (drużyna gracza z wybranym składem + 17 drużyn WorldTour/ProTeam)
    final Map<String, CyclingTeam> allTeamsMap = {};
    final Map<String, Rider> allRidersMap = {};
    final Map<String, CompleteBike> allBikesMap = {};

    final playerRiderIds = _selectedLineup.map((r) => r.id).toList();
    allTeamsMap[_selectedTeam.id] = _selectedTeam.copyWith(
      rosterRiderIds: playerRiderIds,
      inventoryBikes: [playerBike],
    );
    for (final rider in _selectedLineup) {
      allRidersMap[rider.id] = rider;
      allBikesMap[rider.id] = playerBike;
    }

    int rivalCount = 0;
    for (final team in _worldData.teams) {
      if (team.id == _selectedTeam.id) continue;
      if (rivalCount >= 17) break;

      final roster = _worldData.getTeamRoster(team.id).take(8).toList();
      if (roster.isEmpty) continue;

      final rivalBike = team.inventoryBikes.isNotEmpty
          ? team.inventoryBikes.first
          : FictionalBrandsCatalog.assembleBike(
              brandId: team.bikeDeal.brandId,
              frameCategory: FrameCategory.allRounder,
            );

      allTeamsMap[team.id] = team.copyWith(
        rosterRiderIds: roster.map((r) => r.id).toList(),
      );
      for (final rider in roster) {
        allRidersMap[rider.id] = rider;
        allBikesMap[rider.id] = rivalBike;
      }
      rivalCount++;
    }

    ref.read(raceSimulationProvider.notifier).initializeStage(
          stage: configuredStage,
          playerTeamId: _selectedTeam.id,
          allRidersMap: allRidersMap,
          allBikesMap: allBikesMap,
          allTeamsMap: allTeamsMap,
        );

    if (!mounted) return;
    context.goToRaceLive(initialCameraMode: RaceCameraMode.road3D);
  }

  @override
  Widget build(BuildContext context) {
    final stage = _configuredStage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktopOrTablet = constraints.maxWidth >= 920;
            final isCompactTablet =
                constraints.maxWidth >= 920 && constraints.maxWidth < 1200;

            return Column(
              children: [
                _buildTopHeader(isCompact: !isDesktopOrTablet),
                if (!isDesktopOrTablet) _buildMobileTabBar(),
                Expanded(
                  child: isDesktopOrTablet
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(
                            isCompactTablet ? 12 : 20,
                            8,
                            isCompactTablet ? 12 : 20,
                            16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 11,
                                child: _buildColumn1RouteAndWeather(stage),
                              ),
                              SizedBox(width: isCompactTablet ? 10 : 16),
                              Expanded(
                                flex: 10,
                                child: _buildColumn2TeamAndRoster(stage),
                              ),
                              SizedBox(width: isCompactTablet ? 10 : 16),
                              Expanded(
                                flex: 9,
                                child: _buildColumn3EquipmentAndStart(stage),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _mobileTabController,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              child: _buildColumn1RouteAndWeather(stage),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              child: _buildColumn2TeamAndRoster(stage),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              child: _buildColumn3EquipmentAndStart(stage),
                            ),
                          ],
                        ),
                ),
                if (!isDesktopOrTablet) _buildMobileStickyFooter(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader({required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          _InteractiveIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Powrót do Menu Głównego',
            onPressed: () => context.goToStart(),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.6),
              ),
            ),
            child: const Icon(
              Icons.science_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCompact
                      ? 'SZYBKI WYŚCIG 3D'
                      : 'SZYBKI WYŚCIG • LABORATORIUM TAKTYCZNE SANDBOX',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Skonfiguruj trasę, pogodę, skład i sprzęt w 10 sekund i uruchom symulację 3D',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 12),
            const _StatusPill(
              icon: Icons.bolt_rounded,
              label: 'TRYB 10s SANDBOX',
              color: AppColors.goldAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _mobileTabController,
        indicatorColor: AppColors.goldAccent,
        indicatorWeight: 2.5,
        labelColor: AppColors.goldAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.terrain_rounded, size: 18), text: 'Trasa'),
          Tab(icon: Icon(Icons.groups_rounded, size: 18), text: 'Skład (8)'),
          Tab(icon: Icon(Icons.pedal_bike_rounded, size: 18), text: 'Sprzęt 3D'),
        ],
      ),
    );
  }

  Widget _buildMobileStickyFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: _Start3dSimulationButton(
        isEnabled: _selectedLineup.isNotEmpty && !_isStartingRace,
        isLoading: _isStartingRace,
        onPressed: _start3dSimulation,
      ),
    );
  }

  // ===========================================================================
  // KOLUMNA 1: WYBÓR TRASY I WARUNKÓW
  // ===========================================================================
  Widget _buildColumn1RouteAndWeather(RaceStage stage) {
    return _BentoPanel(
      title: '1. Trasa i Warunki',
      icon: Icons.route_rounded,
      accentColor: AppColors.accentBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Przełącznik: Presety / Pełny Kalendarz UCI
            Row(
              children: [
                Expanded(
                  child: _SegmentToggleButton(
                    label: '5 Presetów Taktycznych',
                    isSelected: !_showAllRacesList,
                    onTap: () => setState(() => _showAllRacesList = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SegmentToggleButton(
                    label: 'Wszystkie Wyścigi (${_allCalendarRaces.length})',
                    isSelected: _showAllRacesList,
                    onTap: () => setState(() => _showAllRacesList = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (!_showAllRacesList)
              _buildPresetsList()
            else
              _buildAllCalendarRacesSelector(),

            const SizedBox(height: 12),

            // Interaktywny podgląd ElevationProfileChart
            SizedBox(
              height: 155,
              child: ElevationProfileChart(
                stage: stage,
                showHeader: false,
                enableScrubber: true,
                height: 155,
              ),
            ),

            const SizedBox(height: 10),

            // Szybkie metryki trasy
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TelemetryTag(
                  label: 'DYSTANS',
                  value: '${stage.totalDistanceKm.toStringAsFixed(1)} km',
                  color: AppColors.accentBlue,
                ),
                _TelemetryTag(
                  label: 'PRZEWYŻSZENIE',
                  value: '+${stage.totalElevationGainM.round()} m',
                  color: AppColors.amberWarning,
                ),
                _TelemetryTag(
                  label: 'TEMP.',
                  value: '${stage.baseTemperatureCelsius.round()}°C',
                  color: stage.baseTemperatureCelsius >= 32
                      ? AppColors.crimsonAlert
                      : (stage.baseTemperatureCelsius <= 4
                          ? AppColors.cyanAccent
                          : AppColors.statusSuccess),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const _SectionLabel('POGODA NA TRASIE'),
            const SizedBox(height: 8),
            _buildWeatherSelector(),

            const SizedBox(height: 14),
            _buildWindControls(stage),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsList() {
    return Column(
      children: _presetStages.map((entry) {
        final isSelected = _selectedStageKey == entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _InteractiveListTile(
            isSelected: isSelected,
            accentColor: entry.badgeColor,
            onTap: () => _selectPreset(entry),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textPrimary.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle,
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
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: entry.badgeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: entry.badgeColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    entry.badge,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: entry.badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAllCalendarRacesSelector() {
    final query = _stageSearchQuery.trim().toLowerCase();
    final List<_CalendarStageItem> items = [];
    for (final race in _allCalendarRaces) {
      for (final s in race.stages) {
        final fullLabel = '${race.name} ${s.name}'.toLowerCase();
        if (query.isEmpty || fullLabel.contains(query)) {
          items.add(_CalendarStageItem(race: race, stage: s));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (v) => setState(() => _stageSearchQuery = v),
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 12.5,
          ),
          decoration: InputDecoration(
            hintText: 'Szukaj wyścigu lub etapu (np. Roubaix, Giro, Alpe)...',
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.goldAccent),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'Brak pasujących etapów.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(6),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final key = 'cal_${item.race.id}_${item.stage.id}';
                    final isSelected = _selectedStageKey == key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _InteractiveListTile(
                        isSelected: isSelected,
                        accentColor: AppColors.goldAccent,
                        onTap: () => _selectCalendarStage(key, item.stage),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.race.name} • Etap ${item.stage.stageNumber}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: AppColors.goldAccent,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    item.stage.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.stage.totalDistanceKm.round()} km',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontFeatures: [FontFeature.tabularFigures()],
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
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

  Widget _buildWeatherSelector() {
    const weatherOptions = [
      (
        preset: SandboxWeatherPreset.sunny,
        label: 'Słońce',
        icon: Icons.wb_sunny_rounded,
        color: AppColors.goldAccent,
      ),
      (
        preset: SandboxWeatherPreset.heavyRain,
        label: 'Ulewa',
        icon: Icons.water_drop_rounded,
        color: AppColors.accentBlue,
      ),
      (
        preset: SandboxWeatherPreset.thunderstorm,
        label: 'Burza',
        icon: Icons.thunderstorm_rounded,
        color: AppColors.powerZone7,
      ),
      (
        preset: SandboxWeatherPreset.extremeHeat38,
        label: 'Upał 38°C',
        icon: Icons.thermostat_rounded,
        color: AppColors.crimsonAlert,
      ),
      (
        preset: SandboxWeatherPreset.mountainFrost2,
        label: 'Mróz w górach 2°C',
        icon: Icons.ac_unit_rounded,
        color: AppColors.cyanAccent,
      ),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: weatherOptions.map((opt) {
        final isSelected = _weatherPreset == opt.preset;
        return _InteractiveChip(
          label: opt.label,
          icon: opt.icon,
          accentColor: opt.color,
          isSelected: isSelected,
          onTap: () => setState(() => _weatherPreset = opt.preset),
        );
      }).toList(),
    );
  }

  Widget _buildWindControls(RaceStage stage) {
    final windColor = _windSpeedKmh >= 40
        ? AppColors.crimsonAlert
        : (_windSpeedKmh >= 25 ? AppColors.amberWarning : AppColors.accentBlue);

    final roadBearing = stage.segments.isNotEmpty
        ? stage.segments.first.roadBearingDegrees
        : 90.0;
    double relAngle = (_windDirectionDegrees - roadBearing).abs() % 360.0;
    if (relAngle > 180.0) relAngle = 360.0 - relAngle;
    final String windEffectLabel;
    if (relAngle >= 60.0 && relAngle <= 120.0) {
      windEffectLabel = _windSpeedKmh >= 30
          ? 'Wiatr boczny (RYZYKO RANTÓW!)'
          : 'Wiatr boczny';
    } else if (relAngle < 60.0) {
      windEffectLabel = 'Wiatr w plecy';
    } else {
      windEffectLabel = 'Wiatr czołowy';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'PRĘDKOŚĆ WIATRU',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_windSpeedKmh.round()} km/h',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: windColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: windColor,
                    inactiveTrackColor: AppTheme.borderColor,
                    thumbColor: AppColors.goldAccent,
                    overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _windSpeedKmh,
                    min: 0.0,
                    max: 70.0,
                    divisions: 70,
                    onChanged: (val) => setState(() => _windSpeedKmh = val),
                  ),
                ),
                Text(
                  windEffectLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: windColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _WindCompassWidget(
            angleDegrees: _windDirectionDegrees,
            windSpeedKmh: _windSpeedKmh,
            onAngleChanged: (deg) =>
                setState(() => _windDirectionDegrees = deg),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // KOLUMNA 2: WYBÓR DRUŻYNY I SKŁADU
  // ===========================================================================
  Widget _buildColumn2TeamAndRoster(RaceStage stage) {
    final avgWkg = _selectedLineup.isEmpty
        ? 0.0
        : _selectedLineup
                .map((r) => r.physiology.wattsPerKg)
                .reduce((a, b) => a + b) /
            _selectedLineup.length;

    return _BentoPanel(
      title: '2. Drużyna i Skład',
      icon: Icons.groups_rounded,
      accentColor: AppColors.goldAccent,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wybór drużyny z pełnej bazy (53 drużyny)
            _buildTeamPickerTrigger(),
            const SizedBox(height: 10),

            // Przycisk Auto-Pick Optimal Roster + statystyka składu
            Row(
              children: [
                Expanded(
                  child: _InteractiveActionButton(
                    label: 'Auto-Pick Optimal Roster',
                    icon: Icons.auto_awesome_rounded,
                    backgroundColor: AppColors.surfaceLight,
                    hoverBorderColor: AppColors.goldAccent,
                    foregroundColor: AppColors.goldAccent,
                    onPressed: () => _autoPickOptimalRoster(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'ŚR. W/KG',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        avgWkg.toStringAsFixed(2),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.statusSuccess,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
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
                _SectionLabel('SKŁAD STARTOWY (${_selectedLineup.length}/8)'),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Kliknij kolarza aby wymienić',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                itemCount: _selectedLineup.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final rider = _selectedLineup[index];
                  return _buildLineupRiderRow(rider, index, stage);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPickerTrigger() {
    final teamColor = _parseHexColor(_selectedTeam.primaryJerseyColorHex);
    return _InteractiveListTile(
      isSelected: false,
      accentColor: AppColors.goldAccent,
      onTap: _openTeamPickerDialog,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Center(
              child: Text(
                _selectedTeam.countryIso,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedTeam.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_selectedTeam.division.label} • ${_teamFullRoster.length} kolarzy w bazie',
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
          const Icon(
            Icons.swap_horiz_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLineupRiderRow(Rider rider, int index, RaceStage stage) {
    final wkg = rider.physiology.wattsPerKg.toStringAsFixed(2);
    final keySkillLabel = _keySkillLabelForStage(rider, stage);

    return _InteractiveListTile(
      isSelected: false,
      accentColor: AppColors.accentBlue,
      onTap: () => _openRiderSwapDialog(index, stage),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.goldAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  rider.specialization.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$wkg W/kg',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.statusSuccess,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                keySkillLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.accentBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.edit_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  String _keySkillLabelForStage(Rider rider, RaceStage stage) {
    final s = rider.skills;
    switch (stage.stageType) {
      case StageType.cobbleClassic:
        return 'BRK ${s.cobbles} • ZJD ${s.descending}';
      case StageType.individualTimeTrial:
      case StageType.teamTimeTrial:
        return 'TT ${s.timeTrialPositioning} • AERO ${s.aeroPositioning}';
      case StageType.highMountain:
      case StageType.summitFinish:
        return 'VO2 ${rider.physiology.vo2Max.round()} • ZJD ${s.descending}';
      case StageType.flat:
        return 'SPR ${rider.powerProfile.watts5s.round()}W • DRF ${s.draftingEfficiency}';
      case StageType.hilly:
        return 'PUNCH ${s.punch} • IQ ${s.raceIq}';
    }
  }

  Future<void> _openTeamPickerDialog() async {
    _teamSearchQuery = '';
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filtered = _worldData.teams.where((t) {
              if (_teamSearchQuery.trim().isEmpty) return true;
              final q = _teamSearchQuery.trim().toLowerCase();
              return t.name.toLowerCase().contains(q) ||
                  t.countryIso.toLowerCase().contains(q) ||
                  t.division.label.toLowerCase().contains(q);
            }).toList();

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_rounded,
                              color: AppColors.goldAccent, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Wybierz Drużynę z Pełnej Bazy (53)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (v) =>
                            setDialogState(() => _teamSearchQuery = v),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Filtruj po nazwie, kraju lub dywizji...',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.textSecondary, size: 18),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final team = filtered[i];
                            final isSelected = team.id == _selectedTeam.id;
                            return _InteractiveListTile(
                              isSelected: isSelected,
                              accentColor: AppColors.goldAccent,
                              onTap: () {
                                _selectTeam(team);
                                Navigator.of(ctx).pop();
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _parseHexColor(
                                          team.primaryJerseyColorHex),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          team.name,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${team.division.label} • ${team.countryIso}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.goldAccent, size: 18),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openRiderSwapDialog(int lineupIndex, RaceStage stage) async {
    final currentRider = _selectedLineup[lineupIndex];
    final selectedIds = _selectedLineup.map((r) => r.id).toSet();
    final benchRiders = _teamFullRoster
        .where((r) => !selectedIds.contains(r.id))
        .toList()
      ..sort(
        (a, b) =>
            _scoreRiderForCurrentStage(b).compareTo(_scoreRiderForCurrentStage(a)),
      );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swap_vert_rounded,
                          color: AppColors.accentBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Wymień: ${currentRider.fullName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: benchRiders.isEmpty
                        ? const Center(
                            child: Text(
                              'Brak rezerwowych w kadrze tej drużyny.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: benchRiders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (ctx, i) {
                              final candidate = benchRiders[i];
                              final wkg = candidate.physiology.wattsPerKg
                                  .toStringAsFixed(2);
                              return _InteractiveListTile(
                                isSelected: false,
                                accentColor: AppColors.statusSuccess,
                                onTap: () {
                                  setState(() {
                                    final updated = List<Rider>.from(_selectedLineup);
                                    updated[lineupIndex] = candidate;
                                    _selectedLineup = updated;
                                  });
                                  Navigator.of(ctx).pop();
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            candidate.fullName,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            candidate.specialization.displayName,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$wkg W/kg (${candidate.physiology.ftpWatts}W)',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontFeatures: [
                                              FontFeature.tabularFigures()
                                            ],
                                            color: AppColors.statusSuccess,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          _keySkillLabelForStage(
                                              candidate, stage),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontFeatures: [
                                              FontFeature.tabularFigures()
                                            ],
                                            color: AppColors.accentBlue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // KOLUMNA 3: SZYBKI SETUP SPRZĘTOWY & START SYMULACJI 3D
  // ===========================================================================
  Widget _buildColumn3EquipmentAndStart(RaceStage stage) {
    final activeBike =
        _buildBikeForPreset(_bikePreset, _selectedTeam.bikeDeal.brandId);

    return _BentoPanel(
      title: '3. Szybki Setup Sprzętowy',
      icon: Icons.pedal_bike_rounded,
      accentColor: AppColors.primaryAccent,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBikePresetCard(
                      preset: SandboxBikePreset.fullAero65mm,
                      title: 'Full Aero 65mm',
                      subtitle:
                          'Stożki 65mm, rama aero, kokpit 370mm • Maksymalna prędkość na płaskim i rantach',
                      specs: '7.15 kg • CdA -0.025 • Crr 0.0033',
                      icon: Icons.air_rounded,
                      accentColor: AppColors.accentBlue,
                    ),
                    const SizedBox(height: 8),
                    _buildBikePresetCard(
                      preset: SandboxBikePreset.ultralightClimbing,
                      title: 'Ultralight Climbing 6.8kg',
                      subtitle:
                          'Rama 680g, koła 32mm 1180g • Minimalna masa na Alpe d\'Huez i strome ściany',
                      specs: '6.80 kg (UCI) • CdA -0.011 • Crr 0.0034',
                      icon: Icons.landscape_rounded,
                      accentColor: AppColors.goldAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildBikePresetCard(
                      preset: SandboxBikePreset.cobbleTubeless32mm,
                      title: 'Cobble Tubeless 32mm 3.8 bar',
                      subtitle:
                          'Opony 32mm bezdętkowe 3.8 bar • Odporność na przebicia na bruku Roubaix',
                      specs: '7.45 kg • Ryzyko defektu -62% • Grip 4.7/5',
                      icon: Icons.grid_on_rounded,
                      accentColor: AppColors.amberWarning,
                    ),
                    const SizedBox(height: 14),
                    _buildExperimentSummaryCard(stage, activeBike),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Start3dSimulationButton(
              isEnabled: _selectedLineup.isNotEmpty && !_isStartingRace,
              isLoading: _isStartingRace,
              onPressed: _start3dSimulation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBikePresetCard({
    required SandboxBikePreset preset,
    required String title,
    required String subtitle,
    required String specs,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _bikePreset == preset;
    return _InteractiveListTile(
      isSelected: isSelected,
      accentColor: accentColor,
      onTap: () => setState(() => _bikePreset = preset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentColor.withValues(alpha: isSelected ? 0.8 : 0.3),
              ),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: accentColor, size: 17),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  specs,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: accentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperimentSummaryCard(RaceStage stage, CompleteBike bike) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PODSUMOWANIE SYMULACJI',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.goldAccent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          _SummaryRow('Etap', stage.name),
          _SummaryRow('Drużyna', '${_selectedTeam.name} (${_selectedLineup.length} kol.)'),
          _SummaryRow('Rower', '${bike.name} (${bike.totalWeightKg.toStringAsFixed(2)} kg)'),
          _SummaryRow(
            'Pogoda / Wiatr',
            '${stage.baseTemperatureCelsius.round()}°C • ${_windSpeedKmh.round()} km/h (${_windDirectionDegrees.round()}°)',
          ),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    final clean = hex.replaceAll('#', '');
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return AppColors.primaryAccent;
    return Color(clean.length == 6 ? (0xFF000000 | value) : value);
  }
}

// =============================================================================
// POMOCNICZE MODELE I KOMPONENTY UI (Z PEŁNYMI STANAMI HOVER/ACTIVE/FOCUS)
// =============================================================================

class _QuickStageEntry {
  final String key;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final RaceStage stage;
  final SandboxWeatherPreset defaultWeather;
  final double defaultWindKmh;
  final double defaultWindDir;

  const _QuickStageEntry({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.stage,
    required this.defaultWeather,
    required this.defaultWindKmh,
    required this.defaultWindDir,
  });
}

class _CalendarStageItem {
  final TourRace race;
  final RaceStage stage;

  const _CalendarStageItem({required this.race, required this.stage});
}

class _BentoPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _BentoPanel({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textSecondary,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryTag extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryTag({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused || _hovered
                    ? AppColors.goldAccent
                    : AppTheme.borderColor,
              ),
            ),
            child: Icon(
              widget.icon,
              color: _hovered ? AppColors.goldAccent : AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentToggleButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SegmentToggleButton> createState() => _SegmentToggleButtonState();
}

class _SegmentToggleButtonState extends State<_SegmentToggleButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent.withValues(alpha: 0.25)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : (_focused || _hovered
                      ? AppColors.goldAccent.withValues(alpha: 0.6)
                      : AppTheme.borderColor),
            ),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveListTile extends StatefulWidget {
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;

  const _InteractiveListTile({
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_InteractiveListTile> createState() => _InteractiveListTileState();
}

class _InteractiveListTileState extends State<_InteractiveListTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: _pressed
              ? Matrix4.diagonal3Values(0.99, 0.99, 1.0)
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.14)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accentColor
                  : (_focused || _hovered
                      ? widget.accentColor.withValues(alpha: 0.65)
                      : AppTheme.borderColor),
              width: widget.isSelected ? 1.4 : 1.0,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _InteractiveChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _InteractiveChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.2)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accentColor
                  : (_focused || _hovered
                      ? widget.accentColor.withValues(alpha: 0.6)
                      : AppTheme.borderColor),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.isSelected
                    ? widget.accentColor
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
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
  final Color backgroundColor;
  final Color hoverBorderColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.hoverBorderColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _pressed
                ? widget.hoverBorderColor.withValues(alpha: 0.25)
                : (_hovered
                    ? widget.hoverBorderColor.withValues(alpha: 0.14)
                    : widget.backgroundColor),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused || _hovered
                  ? widget.hoverBorderColor
                  : AppTheme.borderColor,
              width: _focused || _hovered ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.foregroundColor, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: widget.foregroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Główny przycisk "START SYMULACJI 3D" w kolorze #8E4A49 ze złotym podświetleniem hover #D4AF37
class _Start3dSimulationButton extends StatefulWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _Start3dSimulationButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_Start3dSimulationButton> createState() =>
      _Start3dSimulationButtonState();
}

class _Start3dSimulationButtonState extends State<_Start3dSimulationButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled && !widget.isLoading;
    final bgColor = !enabled
        ? AppColors.surfaceLight
        : (_pressed
            ? const Color(0xFF723736)
            : (_hovered ? AppColors.primaryAccent : AppColors.primaryAccent));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: !enabled
                  ? AppTheme.borderColor
                  : (_hovered || _focused
                      ? AppColors.goldAccent
                      : AppColors.goldAccent.withValues(alpha: 0.45)),
              width: _hovered || _focused ? 2.0 : 1.2,
            ),
            boxShadow: enabled && (_hovered || _focused)
                ? [
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.goldAccent,
                  ),
                )
              else
                Icon(
                  Icons.view_in_ar_rounded,
                  color: enabled
                      ? (_hovered ? AppColors.goldAccent : Colors.white)
                      : AppColors.textSecondary,
                  size: 20,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.isLoading
                      ? 'URUCHAMIANIE 3D...'
                      : 'START SYMULACJI 3D',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: enabled
                        ? (_hovered ? AppColors.goldAccent : Colors.white)
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interaktywny kompas kierunku wiatru (0°–360°)
class _WindCompassWidget extends StatelessWidget {
  final double angleDegrees;
  final double windSpeedKmh;
  final ValueChanged<double> onAngleChanged;

  const _WindCompassWidget({
    required this.angleDegrees,
    required this.windSpeedKmh,
    required this.onAngleChanged,
  });

  String _cardinalLabel(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((deg + 22.5) % 360.0) ~/ 45;
    return dirs[idx.clamp(0, 7)];
  }

  void _updateFromLocalOffset(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final rad = math.atan2(dx, -dy);
    final deg = (rad * 180.0 / math.pi + 360.0) % 360.0;
    onAngleChanged((deg / 15.0).round() * 15.0 % 360.0);
  }

  @override
  Widget build(BuildContext context) {
    const size = Size(76, 76);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanDown: (d) => _updateFromLocalOffset(d.localPosition, size),
          onPanUpdate: (d) => _updateFromLocalOffset(d.localPosition, size),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: CustomPaint(
              painter: _WindCompassPainter(
                angleDegrees: angleDegrees,
                windColor: windSpeedKmh >= 40
                    ? AppColors.crimsonAlert
                    : AppColors.goldAccent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_cardinalLabel(angleDegrees)} (${angleDegrees.round()}°)',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontFeatures: [FontFeature.tabularFigures()],
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WindCompassPainter extends CustomPainter {
  final double angleDegrees;
  final Color windColor;

  const _WindCompassPainter({
    required this.angleDegrees,
    required this.windColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // Kreski N/E/S/W
    final tickPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final p1 = Offset(
        center.dx + math.sin(a) * (radius - 5),
        center.dy - math.cos(a) * (radius - 5),
      );
      final p2 = Offset(
        center.dx + math.sin(a) * radius,
        center.dy - math.cos(a) * radius,
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Strzałka kierunku wiatru
    final rad = angleDegrees * math.pi / 180.0;
    final tip = Offset(
      center.dx + math.sin(rad) * (radius - 9),
      center.dy - math.cos(rad) * (radius - 9),
    );
    final tail = Offset(
      center.dx - math.sin(rad) * (radius - 13),
      center.dy + math.cos(rad) * (radius - 13),
    );

    final arrowPaint = Paint()
      ..color = windColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(tail, tip, arrowPaint);
    canvas.drawCircle(tip, 3.5, Paint()..color = windColor);
    canvas.drawCircle(center, 2.5, Paint()..color = AppColors.textPrimary);
  }

  @override
  bool shouldRepaint(covariant _WindCompassPainter oldDelegate) {
    return oldDelegate.angleDegrees != angleDegrees ||
        oldDelegate.windColor != windColor;
  }
}
