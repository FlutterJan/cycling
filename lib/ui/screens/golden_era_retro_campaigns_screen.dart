import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/physics/retro_steel_frame_and_no_powermeter_solver.dart';
import '../../engine/rendering3d/retro_sepia_film_grain_and_steel_bikes_3d.dart';
import '../../models/retro/golden_era_retro_season_model.dart';

/// Zakładki widoku kampanii historycznych w układzie mobilnym i tabletowym.
enum GoldenEraScreenTab {
  campaignAndCalendar('Kampania', Icons.emoji_events_outlined),
  garageAndRpe('Garaż & RPE', Icons.build_outlined),
  cinema3d('Kino 3D', Icons.videocam_outlined);

  final String label;
  final IconData icon;

  const GoldenEraScreenTab(this.label, this.icon);
}

/// Filtr dekad historycznych 1970–2015 dla listy kampanii.
enum GoldenEraDecadeFilter {
  all('Wszystkie (1970–2015)', null),
  era1970s('1970–1979', GoldenEraDecade.steelCannibalEra1970s),
  era1980s('1980–1989', GoldenEraDecade.badgerAndAeroDawn1980s),
  era1990s('1990–1999', GoldenEraDecade.stiAndRadioDawn1990s),
  era2000s('2000–2015', GoldenEraDecade.carbonAndPowerEra2000s);

  final String label;
  final GoldenEraDecade? decade;

  const GoldenEraDecadeFilter(this.label, this.decade);
}

/// Wynik symulacji pojedynczego wyścigu historycznego w kampanii Złotej Ery.
@immutable
class GoldenEraRaceSimulationOutcome {
  final String eventId;
  final String eventName;
  final int placement;
  final int prestigeAwarded;
  final double averageSpeedKmh;
  final double borgRpeScore;
  final int misshiftsCount;
  final double wetJerseyPenaltyWatts;
  final String summaryNote;

  const GoldenEraRaceSimulationOutcome({
    required this.eventId,
    required this.eventName,
    required this.placement,
    required this.prestigeAwarded,
    required this.averageSpeedKmh,
    required this.borgRpeScore,
    required this.misshiftsCount,
    required this.wetJerseyPenaltyWatts,
    required this.summaryNote,
  });
}

/// Ekran kampanii historycznych „Złota Era Kolarstwa: 1970–2015”.
///
/// Łączy wybór epoki (1970–2015), regulaminy UCI bez radia i watów,
/// kalendarz monumentów, konfigurator stalowego sprzętu z kalkulatorem
/// nasiąkania wełnianej koszulki, symulator RPE (Borg 6–20) z manetkami
/// na dolnej rurze oraz podgląd 3D z filtrem taśmy 16mm/VHS.
class GoldenEraRetroCampaignsScreen extends StatefulWidget {
  final int initialYear;
  final ValueChanged<GoldenEraRetroSeasonModel>? onCampaignActivated;
  final ValueChanged<GoldenEraRaceSimulationOutcome>? onRaceSimulated;

  const GoldenEraRetroCampaignsScreen({
    super.key,
    this.initialYear = 1976,
    this.onCampaignActivated,
    this.onRaceSimulated,
  });

  @override
  State<GoldenEraRetroCampaignsScreen> createState() =>
      _GoldenEraRetroCampaignsScreenState();
}

class _GoldenEraRetroCampaignsScreenState
    extends State<GoldenEraRetroCampaignsScreen> {
  static const TextStyle _baseInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle _tabularInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  final RetroSteelFrameAndNoPowermeterSolver _physicsSolver =
      const RetroSteelFrameAndNoPowermeterSolver();
  late final TextEditingController _teamNameController;

  late List<GoldenEraRetroSeasonModel> _campaigns;
  late int _selectedCampaignIndex;
  GoldenEraDecadeFilter _decadeFilter = GoldenEraDecadeFilter.all;
  GoldenEraScreenTab _activeTab = GoldenEraScreenTab.campaignAndCalendar;

  late int _customYear;
  double _rainIntensity = 0.35;
  double _wetnessProgress = 0.40;
  double _climbGradientPercent = 7.5;
  double _targetBorgRpe = 15.0;

  late DowntubeShiftState _shiftState;
  late RetroPhysicsAndRpeResult _rpeResult;
  GoldenEraRaceSimulationOutcome? _lastOutcome;
  bool _campaignActivatedBanner = false;

  GoldenEraRetroSeasonModel get _activeSeason =>
      _campaigns[_selectedCampaignIndex];

  @override
  void initState() {
    super.initState();
    _campaigns = GoldenEraRetroSeasonModel.presets();
    final safeInitialYear = widget.initialYear.clamp(1970, 2015);
    final matchIndex = _campaigns.indexWhere(
      (c) => c.seasonYear == safeInitialYear,
    );
    if (matchIndex >= 0) {
      _selectedCampaignIndex = matchIndex;
    } else {
      _campaigns = [
        GoldenEraRetroSeasonModel.createForYear(safeInitialYear),
        ..._campaigns,
      ];
      _selectedCampaignIndex = 0;
    }
    _customYear = _activeSeason.seasonYear;
    _teamNameController = TextEditingController(text: _activeSeason.teamName);
    _shiftState = DowntubeShiftState.initial(
      frontTeeth: _activeSeason.teamEquipment.frontChainrings.first,
      rearTeeth: _activeSeason.teamEquipment.rearFreewheelMaxTeeth - 2,
    );
    _rpeResult = _evaluateCurrentPhysics(seed: 42);
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  RetroPhysicsAndRpeResult _evaluateCurrentPhysics({
    int seed = 42,
    int? requestedFrontTeeth,
    int? requestedRearTeeth,
  }) {
    final season = _activeSeason;
    return _physicsSolver.stepSimulation(
      input: RetroPhysicsAndRpeInput(
        frameMaterial: season.teamEquipment.frameMaterial,
        shifterType: season.teamEquipment.shifterType,
        jerseyMaterial: season.teamEquipment.jerseyMaterial,
        telemetryMode: season.ruleset.telemetryMode,
        riderFtpWatts: 385.0,
        requestedPowerWatts: 320.0,
        targetBorgRpe: _targetBorgRpe,
        rainIntensity: _rainIntensity,
        surfaceRoughness: _rainIntensity * 0.45,
        gradePercent: _climbGradientPercent,
        riderCraftSkill: 0.78,
        speedMs: _climbGradientPercent > 4.0 ? 6.2 : 11.4,
        deltaTimeSeconds: 0.85,
        deterministicSeed: seed,
        requestedFrontTeeth: requestedFrontTeeth,
        requestedRearTeeth: requestedRearTeeth,
      ),
      shiftState: _shiftState,
    );
  }

  void _selectCampaign(int index) {
    if (index < 0 || index >= _campaigns.length) return;
    setState(() {
      _selectedCampaignIndex = index;
      _customYear = _activeSeason.seasonYear;
      _teamNameController.text = _activeSeason.teamName;
      _shiftState = DowntubeShiftState.initial(
        frontTeeth: _activeSeason.teamEquipment.frontChainrings.first,
        rearTeeth: _activeSeason.teamEquipment.rearFreewheelMaxTeeth - 2,
      );
      _rpeResult = _evaluateCurrentPhysics(seed: _activeSeason.seasonYear);
      _campaignActivatedBanner = false;
    });
  }

  void _createOrSwitchCustomYear(int year) {
    final safeYear = year.clamp(1970, 2015);
    final rawTeam = _teamNameController.text.trim();
    final teamName = rawTeam.isEmpty ? 'Heritage Peloton $safeYear' : rawTeam;
    final customSeason = GoldenEraRetroSeasonModel.createForYear(
      safeYear,
      teamName: teamName,
      seasonId: 'retro_custom_$safeYear',
    );
    setState(() {
      final existingIdx = _campaigns.indexWhere(
        (c) => c.seasonId == customSeason.seasonId,
      );
      if (existingIdx >= 0) {
        _campaigns[existingIdx] = customSeason;
        _selectedCampaignIndex = existingIdx;
      } else {
        _campaigns = [..._campaigns, customSeason];
        _selectedCampaignIndex = _campaigns.length - 1;
      }
      _customYear = safeYear;
      _decadeFilter = GoldenEraDecadeFilter.all;
      _shiftState = DowntubeShiftState.initial(
        frontTeeth: customSeason.teamEquipment.frontChainrings.first,
        rearTeeth: customSeason.teamEquipment.rearFreewheelMaxTeeth - 2,
      );
      _rpeResult = _evaluateCurrentPhysics(seed: safeYear);
      _campaignActivatedBanner = false;
    });
  }

  void _updateEquipment(RetroEquipmentSetup nextEquipment) {
    final season = _activeSeason;
    final defaultEq = RetroEquipmentSetup.forYear(season.seasonYear);
    double authenticity = 100.0;
    if (nextEquipment.frameMaterial != defaultEq.frameMaterial) {
      authenticity -= 8.0;
    }
    if (nextEquipment.shifterType != defaultEq.shifterType) {
      authenticity -= 10.0;
    }
    if (nextEquipment.jerseyMaterial != defaultEq.jerseyMaterial) {
      authenticity -= 6.0;
    }
    if (nextEquipment.hasHardShellHelmet != defaultEq.hasHardShellHelmet &&
        season.seasonYear < 2003) {
      authenticity -= 4.0;
    }

    setState(() {
      _campaigns[_selectedCampaignIndex] = season.copyWith(
        teamEquipment: nextEquipment,
        historicalAuthenticityScore: authenticity.clamp(55.0, 100.0),
      );
      _rpeResult = _evaluateCurrentPhysics(seed: season.seasonYear + 7);
    });
  }

  void _shiftRearGear(int deltaTeeth) {
    final eq = _activeSeason.teamEquipment;
    final nextRear = (_shiftState.currentRearTeeth + deltaTeeth).clamp(
      eq.rearFreewheelMinTeeth,
      eq.rearFreewheelMaxTeeth,
    );
    if (nextRear == _shiftState.currentRearTeeth) return;
    setState(() {
      _rpeResult = _evaluateCurrentPhysics(
        seed: DateTime.now().microsecondsSinceEpoch % 10000,
        requestedRearTeeth: nextRear,
      );
      _shiftState = _rpeResult.shiftState;
    });
  }

  void _simulateHistoricalRace(RetroHistoricalRaceEvent event) {
    final season = _activeSeason;
    final rain = event.rainProbability.clamp(0.0, 1.0);
    final roughness = (event.cobbleSectorsCount / 26.0).clamp(0.0, 1.0);
    final simResult = _physicsSolver.stepSimulation(
      input: RetroPhysicsAndRpeInput(
        frameMaterial: season.teamEquipment.frameMaterial,
        shifterType: season.teamEquipment.shifterType,
        jerseyMaterial: season.teamEquipment.jerseyMaterial,
        telemetryMode: season.ruleset.telemetryMode,
        riderFtpWatts: 392.0,
        requestedPowerWatts: 335.0,
        targetBorgRpe: _targetBorgRpe,
        rainIntensity: rain,
        surfaceRoughness: roughness,
        gradePercent: event.isGrandTour ? 7.8 : 2.4,
        riderCraftSkill: 0.80,
        speedMs: event.isGrandTour ? 6.4 : 11.1,
        deltaTimeSeconds: 1.0,
        deterministicSeed: event.id.hashCode.abs() + season.seasonYear,
      ),
      shiftState: _shiftState,
    );

    final woolPenalty = season.computeWoolJerseyPenaltyWatts(
      rainIntensity01: rain,
      speedMs: event.isGrandTour ? 6.4 : 11.1,
      gradientPercent: event.isGrandTour ? 7.8 : 2.4,
      wetnessProgress01: rain * 0.85,
    );

    final powerRatio = (simResult.effectiveWheelPowerWatts / 340.0).clamp(
      0.7,
      1.35,
    );
    final authBonus = season.historicalAuthenticityScore >= 90.0 ? 1.06 : 1.0;
    final rawScore = powerRatio * authBonus * (1.0 - (woolPenalty / 450.0));
    final int placement = (14 - (rawScore * 11).round()).clamp(1, 25).toInt();
    final int prestige =
        (event.isMonument || event.isGrandTour ? 240 : 150) +
        math.max(0, (12 - placement) * 18);
    final avgSpeed = (event.isGrandTour ? 34.8 : 40.6) * powerRatio;

    final updatedSeason = season.markEventCompleted(
      event.id,
      prestigeEarned: prestige,
    );
    final outcome = GoldenEraRaceSimulationOutcome(
      eventId: event.id,
      eventName: event.name,
      placement: placement,
      prestigeAwarded: prestige,
      averageSpeedKmh: avgSpeed,
      borgRpeScore: simResult.borgRpeScore,
      misshiftsCount: simResult.shiftState.totalMisshifts,
      wetJerseyPenaltyWatts: woolPenalty,
      summaryNote: placement <= 3
          ? 'Podium historyczne! Kolarz utrzymał tempo bez miernika mocy.'
          : 'Ukończono klasyk w warunkach epoki (${season.ruleset.communicationMode.displayNamePl}).',
    );

    setState(() {
      _campaigns[_selectedCampaignIndex] = updatedSeason;
      _lastOutcome = outcome;
      _shiftState = simResult.shiftState;
      _rpeResult = simResult;
    });
    widget.onRaceSimulated?.call(outcome);
  }

  void _resetActiveCampaignProgress() {
    final season = _activeSeason;
    if (season.completedEventIds.isEmpty) return;
    setState(() {
      _campaigns[_selectedCampaignIndex] = season.copyWith(
        completedEventIds: const [],
        seasonPrestigePoints: 0,
      );
      _lastOutcome = null;
    });
  }

  void _activateCampaign() {
    setState(() {
      _campaignActivatedBanner = true;
    });
    widget.onCampaignActivated?.call(_activeSeason);
  }

  List<GoldenEraRetroSeasonModel> get _filteredCampaigns {
    final targetDecade = _decadeFilter.decade;
    if (targetDecade == null) return _campaigns;
    return _campaigns
        .where((c) => c.ruleset.era == targetDecade)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1120;
            final isTablet = width >= 680 && width < 1120;
            final horizontalPadding = isDesktop ? 24.0 : (isTablet ? 18.0 : 12.0);

            return Column(
              children: [
                _buildTopHeader(
                  context,
                  isCompact: !isDesktop,
                  horizontalPadding: horizontalPadding,
                ),
                if (_campaignActivatedBanner)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 6,
                    ),
                    child: _buildActivatedBanner(),
                  ),
                if (!isDesktop)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      6,
                      horizontalPadding,
                      8,
                    ),
                    child: _buildMobileTabBar(),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      24,
                    ),
                    child: isDesktop
                        ? _buildDesktopLayout()
                        : _buildTabbedLayout(isTablet: isTablet),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context, {
    required bool isCompact,
    required double horizontalPadding,
  }) {
    final season = _activeSeason;
    final canPop = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RetroInteractiveButton(
                label: 'Wstecz',
                icon: Icons.arrow_back_rounded,
                isCompact: true,
                enabled: canPop,
                onPressed: canPop ? () => Navigator.of(context).maybePop() : null,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.history_edu_rounded,
                          color: AppColors.goldAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Złota Era Kolarstwa · Kampanie 1970–2015',
                            overflow: TextOverflow.ellipsis,
                            style: _baseInter.copyWith(
                              fontSize: isCompact ? 16 : 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${season.teamName} • ${season.ruleset.era.displayNamePl}',
                      overflow: TextOverflow.ellipsis,
                      style: _baseInter.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusPillBadge(
                label: season.isPureAnalogEra
                    ? 'PURE ANALOG'
                    : '${season.seasonYear} ERA',
                color: season.isPureAnalogEra
                    ? AppColors.goldAccent
                    : AppColors.accentBlue,
              ),
              _StatusPillBadge(
                label: '${season.seasonPrestigePoints} PTS',
                color: AppColors.statusSuccess,
                tabular: true,
              ),
              _RetroInteractiveButton(
                label: 'Aktywuj Kampanię',
                icon: Icons.flag_rounded,
                isPrimary: true,
                isCompact: isCompact,
                onPressed: _activateCampaign,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivatedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusSuccess.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.statusSuccess,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aktywowano kampanię ${_activeSeason.campaignTitle} (${_activeSeason.teamName}).',
              style: _baseInter.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Row(
        children: GoldenEraScreenTab.values.map((tab) {
          final isSelected = _activeTab == tab;
          return Expanded(
            child: _RetroSelectableTab(
              label: tab.label,
              icon: tab.icon,
              selected: isSelected,
              onTap: () => setState(() => _activeTab = tab),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildCampaignSelectorCard(),
              const SizedBox(height: 16),
              _buildRulesetCard(),
              const SizedBox(height: 16),
              _buildCalendarCard(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildEquipmentWorkshopCard(),
              const SizedBox(height: 16),
              _buildRpeSimulatorCard(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: _buildCinema3dPreviewCard(),
        ),
      ],
    );
  }

  Widget _buildTabbedLayout({required bool isTablet}) {
    switch (_activeTab) {
      case GoldenEraScreenTab.campaignAndCalendar:
        if (isTablet) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildCampaignSelectorCard(),
                    const SizedBox(height: 16),
                    _buildRulesetCard(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildCalendarCard()),
            ],
          );
        }
        return Column(
          children: [
            _buildCampaignSelectorCard(),
            const SizedBox(height: 14),
            _buildRulesetCard(),
            const SizedBox(height: 14),
            _buildCalendarCard(),
          ],
        );
      case GoldenEraScreenTab.garageAndRpe:
        if (isTablet) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildEquipmentWorkshopCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildRpeSimulatorCard()),
            ],
          );
        }
        return Column(
          children: [
            _buildEquipmentWorkshopCard(),
            const SizedBox(height: 14),
            _buildRpeSimulatorCard(),
          ],
        );
      case GoldenEraScreenTab.cinema3d:
        return _buildCinema3dPreviewCard();
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color accentColor = AppColors.goldAccent,
    Widget? trailing,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: _baseInter.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCampaignSelectorCard() {
    final filtered = _filteredCampaigns;
    final season = _activeSeason;

    return _buildSectionCard(
      title: 'Wybór Kampanii i Epoki (1970–2015)',
      icon: Icons.auto_stories_rounded,
      trailing: _StatusPillBadge(
        label: '${season.historicalAuthenticityScore.toStringAsFixed(0)}% AUTH',
        color: AppColors.goldAccent,
        tabular: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GoldenEraDecadeFilter.values.map((filter) {
                final selected = _decadeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _RetroChoiceChip(
                    label: filter.label,
                    selected: selected,
                    onTap: () => setState(() => _decadeFilter = filter),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                'Brak zapisanych presetów dla wybranej dekady. Użyj generatora roku poniżej.',
                style: _baseInter.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: filtered.map((preset) {
                final realIndex = _campaigns.indexWhere(
                  (c) => c.seasonId == preset.seasonId,
                );
                final isSelected = realIndex == _selectedCampaignIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CampaignPresetTile(
                    season: preset,
                    selected: isSelected,
                    onTap: () => _selectCampaign(realIndex),
                  ),
                );
              }).toList(growable: false),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Własny Rok Historyczny',
                        overflow: TextOverflow.ellipsis,
                        style: _baseInter.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_customYear',
                      style: _tabularInter.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.goldAccent,
                    inactiveTrackColor: AppTheme.borderColor,
                    thumbColor: AppColors.goldAccent,
                  ),
                  child: Slider(
                    value: _customYear.toDouble(),
                    min: 1970,
                    max: 2015,
                    divisions: 45,
                    label: '$_customYear',
                    onChanged: (value) {
                      setState(() {
                        _customYear = value.round();
                      });
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _teamNameController,
                        style: _baseInter.copyWith(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Nazwa zespołu retro...',
                          hintStyle: _baseInter.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RetroInteractiveButton(
                      label: 'Utwórz $_customYear',
                      icon: Icons.add_circle_outline_rounded,
                      isCompact: true,
                      onPressed: () => _createOrSwitchCustomYear(_customYear),
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

  Widget _buildRulesetCard() {
    final ruleset = _activeSeason.ruleset;
    return _buildSectionCard(
      title: 'Regulamin i Ograniczenia Epoki (${ruleset.year})',
      icon: Icons.gavel_rounded,
      accentColor: AppColors.accentBlue,
      child: Column(
        children: [
          _RuleInfoRow(
            label: 'Łączność taktyczna',
            value: ruleset.communicationMode.displayNamePl,
            badgeColor: ruleset.hasRaceRadio
                ? AppColors.accentBlue
                : AppColors.amberWarning,
          ),
          const SizedBox(height: 8),
          _RuleInfoRow(
            label: 'Telemetria fizjologiczna',
            value: ruleset.telemetryMode.displayNamePl,
            badgeColor: ruleset.hasPowerMeter
                ? AppColors.statusSuccess
                : AppColors.primaryAccent,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMetricTile(
                label: 'Skład ekipy',
                value: '${ruleset.maxRidersPerTeam} kolarzy',
              ),
              _MiniMetricTile(
                label: 'Limit UCI',
                value: ruleset.uciMinimumWeightKg > 0
                    ? '${ruleset.uciMinimumWeightKg.toStringAsFixed(1)} kg'
                    : 'Brak limitu',
              ),
              _MiniMetricTile(
                label: 'Kaski',
                value: ruleset.mandatoryHelmetRule ? 'Obowiązkowe' : 'Opcjonalne',
              ),
              _MiniMetricTile(
                label: 'Neutralny serwis',
                value: ruleset.allowNeutralServiceMoto ? 'Dostępny' : 'Brak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    final season = _activeSeason;
    final progress = season.calendarCompletionProgress;
    final completedSet = season.completedEventIds.toSet();

    return _buildSectionCard(
      title: 'Kalendarz Historyczny (${season.completedEventIds.length}/${season.calendarEvents.length})',
      icon: Icons.calendar_month_rounded,
      trailing: _RetroInteractiveButton(
        label: 'Resetuj',
        icon: Icons.refresh_rounded,
        isCompact: true,
        enabled: season.completedEventIds.isNotEmpty,
        onPressed: season.completedEventIds.isNotEmpty
            ? _resetActiveCampaignProgress
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.goldAccent,
              ),
            ),
          ),
          if (_lastOutcome != null) ...[
            const SizedBox(height: 12),
            _buildOutcomeBanner(_lastOutcome!),
          ],
          const SizedBox(height: 12),
          ...season.calendarEvents.map((event) {
            final isDone = completedSet.contains(event.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoricalRaceEventCard(
                event: event,
                isCompleted: isDone,
                onSimulate: () => _simulateHistoricalRace(event),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOutcomeBanner(GoldenEraRaceSimulationOutcome outcome) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: outcome.placement <= 3
              ? AppColors.goldAccent
              : AppColors.accentBlue,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                outcome.placement <= 3
                    ? Icons.workspace_premium_rounded
                    : Icons.flag_circle_rounded,
                color: outcome.placement <= 3
                    ? AppColors.goldAccent
                    : AppColors.accentBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${outcome.eventName} · #${outcome.placement} miejsce (+${outcome.prestigeAwarded} pts)',
                  overflow: TextOverflow.ellipsis,
                  style: _tabularInter.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            outcome.summaryNote,
            style: _baseInter.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Śr. ${outcome.averageSpeedKmh.toStringAsFixed(1)} km/h',
                style: _tabularInter.copyWith(fontSize: 12),
              ),
              Text(
                'Borg RPE ${outcome.borgRpeScore.toStringAsFixed(1)}',
                style: _tabularInter.copyWith(fontSize: 12),
              ),
              Text(
                'Strata wełny: +${outcome.wetJerseyPenaltyWatts.toStringAsFixed(1)} W',
                style: _tabularInter.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentWorkshopCard() {
    final season = _activeSeason;
    final eq = season.teamEquipment;
    final wetTotalKg = season.computeTotalWetWeightKg(
      riderWeightKg: 68.0,
      rainIntensity01: _rainIntensity,
      wetnessProgress01: _wetnessProgress,
    );
    final woolPenaltyW = season.computeWoolJerseyPenaltyWatts(
      rainIntensity01: _rainIntensity,
      speedMs: _climbGradientPercent > 4.0 ? 6.2 : 11.4,
      gradientPercent: _climbGradientPercent,
      wetnessProgress01: _wetnessProgress,
    );

    return _buildSectionCard(
      title: 'Garaż Stalowy & Koszulka Wełniana',
      icon: Icons.pedal_bike_rounded,
      trailing: _StatusPillBadge(
        label: '${eq.completeBikeWeightKg.toStringAsFixed(1)} kg',
        color: AppColors.primaryAccent,
        tabular: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Materiał ramy',
            style: _baseInter.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: RetroFrameMaterial.values.map((material) {
              return _RetroChoiceChip(
                label: material.displayNamePl,
                selected: eq.frameMaterial == material,
                onTap: () => _updateEquipment(
                  eq.copyWith(
                    frameMaterial: material,
                    frameName: material.displayNameEn,
                    completeBikeWeightKg: material.defaultCompleteBikeWeightKg,
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            'Manetki zmiany biegów',
            style: _baseInter.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: RetroShifterType.values.map((shifter) {
              return _RetroChoiceChip(
                label: shifter.displayNamePl,
                selected: eq.shifterType == shifter,
                onTap: () => _updateEquipment(eq.copyWith(shifterType: shifter)),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            'Materiał koszulki',
            style: _baseInter.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: RetroJerseyMaterial.values.map((jersey) {
              return _RetroChoiceChip(
                label: jersey.displayNamePl,
                selected: eq.jerseyMaterial == jersey,
                onTap: () =>
                    _updateEquipment(eq.copyWith(jerseyMaterial: jersey)),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RetroToggleChip(
                label: 'Noski i paski',
                value: eq.hasToeClipsAndStraps,
                onChanged: (v) =>
                    _updateEquipment(eq.copyWith(hasToeClipsAndStraps: v)),
              ),
              _RetroToggleChip(
                label: 'Bidon na kierownicy',
                value: eq.handlebarBottleCage,
                onChanged: (v) =>
                    _updateEquipment(eq.copyWith(handlebarBottleCage: v)),
              ),
              _RetroToggleChip(
                label: 'Twardy kask',
                value: eq.hasHardShellHelmet,
                onChanged: (v) =>
                    _updateEquipment(eq.copyWith(hasHardShellHelmet: v)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Symulator deszczu i nasiąkania wełny',
                  style: _baseInter.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _CompactSliderRow(
                  label: 'Deszcz',
                  valueText: '${(_rainIntensity * 100).round()}%',
                  value: _rainIntensity,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) {
                    setState(() {
                      _rainIntensity = v;
                      _wetnessProgress = math.max(_wetnessProgress, v * 0.7);
                      _rpeResult = _evaluateCurrentPhysics(seed: 91);
                    });
                  },
                ),
                _CompactSliderRow(
                  label: 'Nachylenie',
                  valueText: '${_climbGradientPercent.toStringAsFixed(1)}%',
                  value: _climbGradientPercent,
                  min: -4.0,
                  max: 16.0,
                  onChanged: (v) {
                    setState(() {
                      _climbGradientPercent = v;
                      _rpeResult = _evaluateCurrentPhysics(seed: 92);
                    });
                  },
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniMetricTile(
                      label: 'Masa systemu (68 kg)',
                      value: '${wetTotalKg.toStringAsFixed(2)} kg',
                    ),
                    _MiniMetricTile(
                      label: 'Kara mokrej wełny',
                      value: '+${woolPenaltyW.toStringAsFixed(1)} W',
                    ),
                    _MiniMetricTile(
                      label: 'Napęd',
                      value: eq.drivetrainSummary,
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

  Widget _buildRpeSimulatorCard() {
    final eq = _activeSeason.teamEquipment;
    return _buildSectionCard(
      title: 'Percepcja RPE (Borg 6–20) & Manetki',
      icon: Icons.speed_rounded,
      accentColor: AppColors.cyanAccent,
      child: RetroSteelAndRpeHudPanel(
        result: _rpeResult,
        shifterType: eq.shifterType,
        frameMaterial: eq.frameMaterial,
        onTargetRpeChanged: (nextRpe) {
          setState(() {
            _targetBorgRpe = nextRpe;
            _rpeResult = _evaluateCurrentPhysics(seed: nextRpe.round() * 13);
          });
        },
        onShiftEasier: () => _shiftRearGear(2),
        onShiftHarder: () => _shiftRearGear(-2),
      ),
    );
  }

  Widget _buildCinema3dPreviewCard() {
    final season = _activeSeason;
    final filmConfig = RetroSepiaFilmConfig.forDecade(season.ruleset.era);
    final framePreset = _matchSteelPresetForDecade(season.ruleset.era);

    return _buildSectionCard(
      title: 'Kino Archiwalne 3D · ${filmConfig.filterMode.badgeText}',
      icon: Icons.movie_filter_rounded,
      accentColor: AppColors.goldAccent,
      padding: const EdgeInsets.all(10),
      child: RetroSepiaFilmGrainAndSteelBikesPanel(
        key: ValueKey('retro_3d_${season.seasonId}_${season.ruleset.era.name}'),
        initialConfig: filmConfig.copyWith(
          enableHandlebarBidons: season.teamEquipment.handlebarBottleCage,
          enableCasquette: !season.teamEquipment.hasHardShellHelmet,
          enableDowntubeShifters:
              season.teamEquipment.shifterType.requiresHandOffBar,
        ),
        initialPose: RetroSteelBikeRider3dPose(
          framePreset: framePreset,
          capStyle: season.teamEquipment.hasHardShellHelmet
              ? RetroCapStyle.hairnetLeatherBanane
              : RetroCapStyle.classicCottonCasquette,
          roadGradientPercent: _climbGradientPercent,
        ),
      ),
    );
  }

  SteelBikeFramePreset _matchSteelPresetForDecade(GoldenEraDecade decade) {
    switch (decade) {
      case GoldenEraDecade.steelCannibalEra1970s:
        return SteelBikeFramePreset.columbusSlChrome1974;
      case GoldenEraDecade.badgerAndAeroDawn1980s:
        return SteelBikeFramePreset.columbusSlxTeam1985;
      case GoldenEraDecade.stiAndRadioDawn1990s:
      case GoldenEraDecade.carbonAndPowerEra2000s:
        return SteelBikeFramePreset.titaniumEarlySti1994;
    }
  }
}

class _CampaignPresetTile extends StatefulWidget {
  final GoldenEraRetroSeasonModel season;
  final bool selected;
  final VoidCallback onTap;

  const _CampaignPresetTile({
    required this.season,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CampaignPresetTile> createState() => _CampaignPresetTileState();
}

class _CampaignPresetTileState extends State<_CampaignPresetTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.season;
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.goldAccent.withValues(alpha: 0.5)
                : AppTheme.borderColor;
    final bgColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.22)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: widget.selected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? AppColors.goldAccent.withValues(alpha: 0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.selected
                          ? AppColors.goldAccent
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    '${s.seasonYear}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.campaignTitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.teamName} • ${s.teamEquipment.frameName}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  widget.selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoricalRaceEventCard extends StatelessWidget {
  final RetroHistoricalRaceEvent event;
  final bool isCompleted;
  final VoidCallback onSimulate;

  const _HistoricalRaceEventCard({
    required this.event,
    required this.isCompleted,
    required this.onSimulate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.statusSuccess.withValues(alpha: 0.08)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppColors.statusSuccess.withValues(alpha: 0.55)
              : AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPillBadge(
                label: event.countryCode,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (event.isMonument)
                const _StatusPillBadge(
                  label: 'MONUMENT',
                  color: AppColors.goldAccent,
                )
              else if (event.isGrandTour)
                const _StatusPillBadge(
                  label: 'GRAND TOUR',
                  color: AppColors.primaryAccent,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            event.surfaceSummaryPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                '${event.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '↑ ${event.elevationGainMeters} m',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Deszcz ${(event.rainProbability * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Zwycięzca: ${event.historicalWinner}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _RetroInteractiveButton(
              label: isCompleted ? 'Ukończono · Powtórz' : 'Rozpocznij Wyścig',
              icon: isCompleted
                  ? Icons.replay_rounded
                  : Icons.play_arrow_rounded,
              isPrimary: !isCompleted,
              isCompact: true,
              onPressed: onSimulate,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color badgeColor;

  const _RuleInfoRow({
    required this.label,
    required this.value,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

class _MiniMetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool tabular;

  const _StatusPillBadge({
    required this.label,
    required this.color,
    this.tabular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
        ),
      ),
    );
  }
}

class _CompactSliderRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _CompactSliderRow({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: AppTheme.borderColor,
              thumbColor: AppColors.accentBlue,
              trackHeight: 3.0,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _RetroSelectableTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RetroSelectableTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RetroSelectableTab> createState() => _RetroSelectableTabState();
}

class _RetroSelectableTabState extends State<_RetroSelectableTab> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent.withValues(alpha: 0.35)
                : _hovered
                    ? AppColors.surfaceLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected
                  ? AppColors.goldAccent
                  : _focused
                      ? AppColors.accentBlue
                      : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.selected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
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

class _RetroInteractiveButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isCompact;
  final bool enabled;

  const _RetroInteractiveButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isCompact = false,
    this.enabled = true,
  });

  @override
  State<_RetroInteractiveButton> createState() =>
      _RetroInteractiveButtonState();
}

class _RetroInteractiveButtonState extends State<_RetroInteractiveButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _isActive => widget.enabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final bgColor = !_isActive
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isPrimary
            ? (_hovered
                ? AppColors.goldAccent.withValues(alpha: 0.9)
                : AppColors.goldAccent)
            : (_hovered ? AppColors.surfaceLight : AppColors.background);

    final fgColor = !_isActive
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isPrimary
            ? AppColors.background
            : AppColors.textPrimary;

    final borderColor = !_isActive
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : _focused
            ? AppColors.accentBlue
            : widget.isPrimary
                ? AppColors.goldAccent
                : (_hovered ? AppColors.goldAccent : AppTheme.borderColor);

    return FocusableActionDetector(
      enabled: _isActive,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: _isActive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _isActive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            _isActive ? () => setState(() => _pressed = false) : null,
        onTap: _isActive ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 10 : 14,
              vertical: widget.isCompact ? 7 : 10,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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

class _RetroChoiceChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RetroChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RetroChoiceChip> createState() => _RetroChoiceChipState();
}

class _RetroChoiceChipState extends State<_RetroChoiceChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent.withValues(alpha: 0.30)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected
                  ? AppColors.goldAccent
                  : _focused
                      ? AppColors.accentBlue
                      : AppTheme.borderColor,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RetroToggleChip extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RetroToggleChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_RetroToggleChip> createState() => _RetroToggleChipState();
}

class _RetroToggleChipState extends State<_RetroToggleChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.value
                ? AppColors.statusSuccess.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.value
                  ? AppColors.statusSuccess
                  : _focused
                      ? AppColors.accentBlue
                      : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 14,
                color: widget.value
                    ? AppColors.statusSuccess
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: widget.value ? FontWeight.w700 : FontWeight.w500,
                  color: widget.value
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
