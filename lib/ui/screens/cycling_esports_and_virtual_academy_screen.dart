// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/physics/esports_smart_trainer_erg_and_powerups_solver.dart';
import '../../engine/rendering3d/esports_cyber_velodrome_and_hologram_3d.dart';
import '../../models/esports/uci_cycling_esports_world_model.dart';

/// Ekran Centrum e-Sports i naboru talentów *Virtual Talent ID Academy*.
///
/// Integruje wirtualne Mistrzostwa Świata UCI Cycling Esports (renderer 3D
/// Cyber-Welodromu, eliminację co 60 s, Power-Upy oraz symulację trenażerów
/// Smart/ERG i Dual-Recording) z panelem skautingu i rekrutacji talentów
/// programu *Virtual Talent ID Academy*.
class CyclingEsportsAndVirtualAcademyScreen extends StatefulWidget {
  /// Opcjonalny początkowy stan świata e-Sports (ułatwia integrację i testy).
  final UciCyclingEsportsWorldModel? initialWorldModel;

  /// Czy viewport 3D ma automatycznie uruchamiać pętlę animacji.
  final bool autoAnimate3d;

  const CyclingEsportsAndVirtualAcademyScreen({
    super.key,
    this.initialWorldModel,
    this.autoAnimate3d = true,
  });

  @override
  State<CyclingEsportsAndVirtualAcademyScreen> createState() =>
      _CyclingEsportsAndVirtualAcademyScreenState();
}

class _CyclingEsportsAndVirtualAcademyScreenState
    extends State<CyclingEsportsAndVirtualAcademyScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _animDuration = Duration(milliseconds: 240);
  static const EsportsSmartTrainerErgAndPowerupsSolver _solver =
      EsportsSmartTrainerErgAndPowerupsSolver();

  late TabController _tabController;
  late UciCyclingEsportsWorldModel _worldModel;
  late EsportsCyberWorldPreset _selectedPreset;
  EsportsTrainerControlMode _trainerControlMode =
      EsportsTrainerControlMode.simMode;

  double _targetPowerWatts = 420.0;
  String _selectedRiderId = 'esp_r1';
  String? _selectedTalentId;
  bool _isSimulationRunning = false;
  Timer? _simulationTimer;

  String _talentSearchQuery = '';
  bool _onlyUnsignedTalents = false;
  _TalentSortField _talentSortField = _TalentSortField.eloDesc;
  final TextEditingController _searchController = TextEditingController();

  EsportsRiderPhysicsResult? _lastPhysicsResult;
  String? _statusBannerMessage;
  Color _statusBannerColor = AppColors.cyanAccent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _worldModel = widget.initialWorldModel ??
        _buildDefaultWorldWithExtendedTalentPool();
    _selectedPreset =
        EsportsCyberWorldPreset.fromTheme(_worldModel.worldSpec.theme);
    if (_worldModel.riders.isNotEmpty) {
      _selectedRiderId = _worldModel.riders.first.riderId;
      _targetPowerWatts = _worldModel.riders.first.ftpWatts;
    }
    if (_worldModel.talentIdPool.isNotEmpty) {
      _selectedTalentId = _worldModel.talentIdPool.first.id;
    }
    _recomputeSelectedRiderPhysics(dtSeconds: 0.25);
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  UciCyclingEsportsWorldModel _buildDefaultWorldWithExtendedTalentPool() {
    final base = UciCyclingEsportsWorldModel.uciWorldChampionshipElimination();
    return base.copyWith(
      talentIdPool: [
        ...base.talentIdPool,
        const VirtualTalentIdCandidate(
          id: 'vt_id_3',
          athleteName: 'Mateo Valenzuela',
          nationalityCode: 'COL',
          age: 18,
          weightKg: 58.6,
          verifiedFtpWatts: 375.0,
          verifiedFiveMinWkg: 7.32,
          peakSprintWatts: 1180,
          esportsElo: 2195,
          dualRecordingScore: 98,
        ),
        const VirtualTalentIdCandidate(
          id: 'vt_id_4',
          athleteName: 'Noah Van Der Berg',
          nationalityCode: 'NED',
          age: 21,
          weightKg: 73.5,
          verifiedFtpWatts: 446.0,
          verifiedFiveMinWkg: 6.72,
          peakSprintWatts: 1610,
          esportsElo: 2040,
          dualRecordingScore: 95,
        ),
        const VirtualTalentIdCandidate(
          id: 'vt_id_5',
          athleteName: 'Zuzanna Kowalczyk',
          nationalityCode: 'POL',
          age: 20,
          weightKg: 56.0,
          verifiedFtpWatts: 332.0,
          verifiedFiveMinWkg: 6.65,
          peakSprintWatts: 1090,
          esportsElo: 2110,
          dualRecordingScore: 100,
        ),
      ],
    );
  }

  EsportsRiderLiveState? get _selectedRider {
    for (final rider in _worldModel.riders) {
      if (rider.riderId == _selectedRiderId) return rider;
    }
    return _worldModel.riders.isNotEmpty ? _worldModel.riders.first : null;
  }

  VirtualTalentIdCandidate? get _selectedTalent {
    for (final talent in _worldModel.talentIdPool) {
      if (talent.id == _selectedTalentId) return talent;
    }
    return _worldModel.talentIdPool.isNotEmpty
        ? _worldModel.talentIdPool.first
        : null;
  }

  void _toggleSimulation() {
    if (_isSimulationRunning) {
      _simulationTimer?.cancel();
      _simulationTimer = null;
      setState(() {
        _isSimulationRunning = false;
      });
    } else {
      setState(() {
        _isSimulationRunning = true;
      });
      _simulationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _advanceRaceStep(seconds: 5);
      });
    }
  }

  void _advanceRaceStep({int seconds = 5}) {
    final updatedRiders = <EsportsRiderLiveState>[];
    EsportsRiderPhysicsResult? selectedResult;

    for (var i = 0; i < _worldModel.riders.length; i++) {
      final rider = _worldModel.riders[i];
      if (!rider.isActiveInRace) {
        updatedRiders.add(rider);
        continue;
      }

      final isPlayer = rider.riderId == _selectedRiderId;
      final desiredPower = isPlayer
          ? _targetPowerWatts
          : (rider.ftpWatts * (0.94 + ((i % 3) * 0.04)));

      final result = _solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: rider,
          world: _worldModel.worldSpec,
          targetPowerWatts: desiredPower,
          controlMode: isPlayer
              ? _trainerControlMode
              : EsportsTrainerControlMode.simMode,
          deltaTimeSeconds: seconds.toDouble(),
          hasDraftTargetAhead: i > 0,
          baseDraftShelterIntensity: i == 0 ? 0.0 : 0.55,
          eliminationSchedule: _worldModel.eliminationSchedule,
        ),
      );
      if (isPlayer) {
        selectedResult = result;
      }
      updatedRiders.add(result.updatedRider);
    }

    final elimResult = _solver.evaluateEliminationRound(
      schedule: _worldModel.eliminationSchedule,
      riders: updatedRiders,
      elapsedIncrementSeconds: seconds,
    );

    final eliminatedRecord = elimResult.eliminationRecord;

    setState(() {
      _worldModel = _worldModel.copyWith(
        riders: elimResult.updatedRiders,
        eliminationSchedule: elimResult.updatedSchedule,
      );
      if (selectedResult != null) {
        _lastPhysicsResult = selectedResult;
      }
      if (eliminatedRecord != null) {
        _statusBannerMessage =
            'Eliminacja Runda #${eliminatedRecord.roundNumber}: '
            '${eliminatedRecord.eliminatedRiderName} odpada (${eliminatedRecord.eliminatedWkg.toStringAsFixed(2)} W/kg)!';
        _statusBannerColor = AppColors.crimsonAlert;
      }
      if (_worldModel.activeRiders.length <= 1) {
        _isSimulationRunning = false;
        _simulationTimer?.cancel();
        _simulationTimer = null;
      }
    });
  }

  void _recomputeSelectedRiderPhysics({double dtSeconds = 1.0}) {
    final rider = _selectedRider;
    if (rider == null) return;

    final result = _solver.solveRiderPhysicsStep(
      EsportsRiderPhysicsInput(
        rider: rider,
        world: _worldModel.worldSpec,
        targetPowerWatts: _targetPowerWatts,
        controlMode: _trainerControlMode,
        deltaTimeSeconds: dtSeconds,
        hasDraftTargetAhead: rider.rank > 1,
        baseDraftShelterIntensity: rider.rank == 1 ? 0.0 : 0.55,
        eliminationSchedule: _worldModel.eliminationSchedule,
      ),
    );
    _lastPhysicsResult = result;
  }

  void _activatePowerUpForSelectedRider([EsportsPowerUpType? overrideType]) {
    final rider = _selectedRider;
    if (rider == null || !rider.isActiveInRace) return;

    final currentSlot = rider.powerUpSlot;
    final EsportsPowerUpInventorySlot slotToActivate;

    if (overrideType != null) {
      slotToActivate = EsportsPowerUpInventorySlot(
        slotIndex: currentSlot.slotIndex,
        powerUp: overrideType,
        state: EsportsPowerUpSlotState.ready,
      ).activate();
    } else if (currentSlot.state == EsportsPowerUpSlotState.ready &&
        currentSlot.powerUp != null) {
      slotToActivate = currentSlot.activate();
    } else {
      return;
    }

    final updatedRiders = _worldModel.riders
        .map(
          (r) => r.riderId == rider.riderId
              ? r.copyWith(powerUpSlot: slotToActivate)
              : r,
        )
        .toList();

    setState(() {
      _worldModel = _worldModel.copyWith(riders: updatedRiders);
      _recomputeSelectedRiderPhysics(dtSeconds: 0.5);
      final name = slotToActivate.powerUp?.displayName ?? 'Power-Up';
      _statusBannerMessage =
          '${rider.riderName} aktywuje Power-Up: $name!';
      _statusBannerColor = AppColors.cyanAccent;
    });
  }

  void _resetEvent() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    setState(() {
      _isSimulationRunning = false;
      _worldModel = _buildDefaultWorldWithExtendedTalentPool();
      _selectedPreset =
          EsportsCyberWorldPreset.fromTheme(_worldModel.worldSpec.theme);
      _selectedRiderId = _worldModel.riders.first.riderId;
      _targetPowerWatts = _worldModel.riders.first.ftpWatts;
      _statusBannerMessage = 'Zresetowano wyścig eliminacyjny UCI Cycling Esports.';
      _statusBannerColor = AppColors.accentBlue;
      _recomputeSelectedRiderPhysics(dtSeconds: 0.25);
    });
  }

  void _switchWorldPreset(EsportsCyberWorldPreset preset) {
    final updatedWorld = EsportsVirtualWorldSpec(
      id: 'world_${preset.theme.name}',
      name: preset.labelPl,
      theme: preset.theme,
      lapLengthMeters: _worldModel.worldSpec.lapLengthMeters,
      totalLaps: _worldModel.worldSpec.totalLaps,
      elevationGainPerLapMeters:
          _worldModel.worldSpec.elevationGainPerLapMeters,
      airDensityKgM3: _worldModel.worldSpec.airDensityKgM3,
      segments: _worldModel.worldSpec.segments,
    );
    setState(() {
      _selectedPreset = preset;
      _worldModel = _worldModel.copyWith(worldSpec: updatedWorld);
      _recomputeSelectedRiderPhysics(dtSeconds: 0.25);
    });
  }

  void _switchRaceFormat(EsportsRaceFormat format) {
    setState(() {
      _worldModel = _worldModel.copyWith(raceFormat: format);
    });
  }

  void _applyTrainerSpecToSelectedRider(SmartTrainerHardwareSpec spec) {
    final rider = _selectedRider;
    if (rider == null) return;
    final updatedRiders = _worldModel.riders
        .map(
          (r) => r.riderId == rider.riderId
              ? r.copyWith(
                  trainerSpec: spec,
                  dualRecordingDeltaPercent:
                      spec.isUciCompliant ? 0.6 : 2.9,
                )
              : r,
        )
        .toList();
    setState(() {
      _worldModel = _worldModel.copyWith(riders: updatedRiders);
      _recomputeSelectedRiderPhysics(dtSeconds: 0.5);
    });
  }

  void _calibrateSelectedRiderTrainer() {
    final rider = _selectedRider;
    if (rider == null) return;
    final calibrated = rider.trainerSpec.copyWith(
      calibrationDriftWatts: 0.0,
      calibrationStatus: SmartTrainerCalibrationStatus.calibrated,
      dualPowerMeterVerified: true,
    );
    final updatedRiders = _worldModel.riders
        .map(
          (r) => r.riderId == rider.riderId
              ? r.copyWith(
                  trainerSpec: calibrated,
                  dualRecordingDeltaPercent: 0.4,
                )
              : r,
        )
        .toList();
    setState(() {
      _worldModel = _worldModel.copyWith(riders: updatedRiders);
      _recomputeSelectedRiderPhysics(dtSeconds: 0.5);
      _statusBannerMessage =
          'Spindown OK: trenażer ${calibrated.modelName} skalibrowany (Δ 0.4%).';
      _statusBannerColor = AppColors.statusSuccess;
    });
  }

  void _toggleTalentContract(VirtualTalentIdCandidate talent) {
    final nextSigned = !talent.isSignedToDevelopmentSquad;
    final updatedPool = _worldModel.talentIdPool
        .map(
          (t) => t.id == talent.id
              ? t.copyWith(isSignedToDevelopmentSquad: nextSigned)
              : t,
        )
        .toList();

    setState(() {
      _worldModel = _worldModel.copyWith(talentIdPool: updatedPool);
      _statusBannerMessage = nextSigned
          ? '${talent.athleteName} podpisany do zespołu rozwojowego (Devo Squad)!'
          : 'Rozwiązano wstępny list intencyjny z ${talent.athleteName}.';
      _statusBannerColor =
          nextSigned ? AppColors.statusSuccess : AppColors.amberWarning;
    });
  }

  void _runCombineTestForTalent(VirtualTalentIdCandidate talent) {
    final eloGain = talent.dualRecordingScore >= 97 ? 24 : 12;
    final updatedPool = _worldModel.talentIdPool
        .map(
          (t) => t.id == talent.id
              ? t.copyWith(
                  esportsElo: t.esportsElo + eloGain,
                  dualRecordingScore: math.min(100, t.dualRecordingScore + 1),
                )
              : t,
        )
        .toList();

    setState(() {
      _worldModel = _worldModel.copyWith(talentIdPool: updatedPool);
      _statusBannerMessage =
          'Test Combine 5-min ukończony: ${talent.athleteName} +$eloGain ELO '
          '(${talent.verifiedFiveMinWkg.toStringAsFixed(2)} W/kg).';
      _statusBannerColor = AppColors.goldAccent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Inter',
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 640;
              final isDesktop = width >= 1200;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isMobile: isMobile, isDesktop: isDesktop),
                  if (_statusBannerMessage != null)
                    _buildStatusBanner(isMobile: isMobile),
                  _buildTabBar(isMobile: isMobile),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLiveArenaTab(
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                        _buildTrainerAndDualRecordingTab(
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                        _buildTalentIdAcademyTab(
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                        _buildRegulationsAndPowerUpsTab(
                          isMobile: isMobile,
                          isDesktop: isDesktop,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isMobile, required bool isDesktop}) {
    final sched = _worldModel.eliminationSchedule;
    final inWarning = sched.isInFinalTenSecondsWarning;
    final signedCount = _worldModel.talentIdPool
        .where((t) => t.isSignedToDevelopmentSquad)
        .length;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    _EsportsActionButton(
                      icon: Icons.arrow_back_rounded,
                      label: isMobile ? '' : 'Powrót',
                      onPressed: () => Navigator.of(context).maybePop(),
                      compact: true,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.cyanAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cyanAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.cyanAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UCI Cycling Esports & Virtual Talent ID',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_worldModel.worldSpec.name} • ${_worldModel.raceFormat.displayNamePl}',
                          maxLines: 1,
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
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _EsportsKpiChip(
                    icon: Icons.timer_rounded,
                    label: 'Eliminacja R${sched.currentRound}',
                    value: '${sched.secondsUntilNextElimination}s',
                    accent: inWarning
                        ? AppColors.crimsonAlert
                        : AppColors.cyanAccent,
                  ),
                  _EsportsKpiChip(
                    icon: Icons.groups_rounded,
                    label: 'W grze',
                    value:
                        '${_worldModel.activeRiders.length}/${_worldModel.riders.length}',
                    accent: AppColors.statusSuccess,
                  ),
                  if (!isMobile)
                    _EsportsKpiChip(
                      icon: Icons.school_rounded,
                      label: 'Devo Squad',
                      value: '$signedCount/${_worldModel.talentIdPool.length}',
                      accent: AppColors.goldAccent,
                    ),
                  _EsportsActionButton(
                    icon: _isSimulationRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: _isSimulationRunning ? 'Pauza' : 'Start Live',
                    accentColor: _isSimulationRunning
                        ? AppColors.amberWarning
                        : AppColors.statusSuccess,
                    onPressed: _worldModel.activeRiders.length > 1
                        ? _toggleSimulation
                        : null,
                    compact: isMobile,
                  ),
                  _EsportsActionButton(
                    icon: Icons.fast_forward_rounded,
                    label: '+15s',
                    accentColor: AppColors.accentBlue,
                    onPressed: _worldModel.activeRiders.length > 1
                        ? () => _advanceRaceStep(seconds: 15)
                        : null,
                    compact: true,
                  ),
                  _EsportsActionButton(
                    icon: Icons.refresh_rounded,
                    label: isMobile ? '' : 'Reset',
                    onPressed: _resetEvent,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({required bool isMobile}) {
    return AnimatedContainer(
      duration: _animDuration,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _statusBannerColor.withValues(alpha: 0.14),
        border: Border(
          bottom: BorderSide(
            color: _statusBannerColor.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _statusBannerColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusBannerMessage ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _statusBannerMessage = null),
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Zamknij powiadomienie',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar({required bool isMobile}) {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: isMobile,
        tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
        indicatorColor: AppColors.cyanAccent,
        indicatorWeight: 2.5,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.stadium_rounded, size: 18),
            text: 'Arena 3D & Wyścig',
          ),
          Tab(
            icon: Icon(Icons.settings_input_component_rounded, size: 18),
            text: 'Trenażer & Dual-Rec',
          ),
          Tab(
            icon: Icon(Icons.stars_rounded, size: 18),
            text: 'Virtual Talent ID',
          ),
          Tab(
            icon: Icon(Icons.gavel_rounded, size: 18),
            text: 'Regulamin & Power-Upy',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: ARENA 3D & WYŚCIG LIVE
  // ===========================================================================

  Widget _buildLiveArenaTab({required bool isMobile, required bool isDesktop}) {
    final padding = isMobile ? 12.0 : 20.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWorldAndFormatSelector(isMobile: isMobile),
          const SizedBox(height: 16),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildViewportAndPowerUpConsole(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _buildLeaderboardAndEliminationCard(),
                ),
              ],
            )
          else ...[
            _buildViewportAndPowerUpConsole(),
            const SizedBox(height: 16),
            _buildLeaderboardAndEliminationCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildWorldAndFormatSelector({required bool isMobile}) {
    return _EsportsPanelCard(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arena Wirtualna i Format Rozgrywek',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EsportsCyberWorldPreset.values.map((preset) {
              final selected = preset == _selectedPreset;
              return _EsportsChoiceChip(
                label: preset.shortTag,
                selected: selected,
                accentColor: preset.primaryNeon,
                onTap: () => _switchWorldPreset(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EsportsRaceFormat.values.map((format) {
              final selected = format == _worldModel.raceFormat;
              return _EsportsChoiceChip(
                label: format.displayNamePl,
                selected: selected,
                accentColor: AppColors.goldAccent,
                onTap: () => _switchRaceFormat(format),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewportAndPowerUpConsole() {
    final rider = _selectedRider;
    final strategy = rider != null
        ? _solver.evaluatePowerUpStrategy(
            rider: rider,
            world: _worldModel.worldSpec,
            eliminationSchedule: _worldModel.eliminationSchedule,
            activeRidersCount: _worldModel.activeRiders.length,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EsportsCyberVelodromeViewportWidget(
          key: ValueKey(_selectedPreset.name),
          initialConfig: EsportsCyberVelodromeConfig(
            worldPreset: _selectedPreset,
          ),
          autoAnimate: widget.autoAnimate3d,
          onTriggerPowerUp: _activatePowerUpForSelectedRider,
        ),
        const SizedBox(height: 16),
        _EsportsPanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.cyanAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Konsola Taktyczna Power-Up & Eliminacja 60 s',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (rider != null)
                    Text(
                      rider.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (strategy != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        strategy.shouldActivateNow
                            ? Icons.flash_on_rounded
                            : Icons.schedule_rounded,
                        color: strategy.shouldActivateNow
                            ? AppColors.statusSuccess
                            : AppColors.amberWarning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doradca DS: ${strategy.recommendedAction.labelPl}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strategy.reasonPl,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EsportsPowerUpType.values.map((type) {
                  final isActive = rider?.activePowerUpType == type;
                  final isReady =
                      rider?.powerUpSlot.state == EsportsPowerUpSlotState.ready &&
                          rider?.powerUpSlot.powerUp == type;
                  return _EsportsActionButton(
                    icon: Icons.bolt_rounded,
                    label: type.displayName,
                    accentColor: isActive
                        ? AppColors.statusSuccess
                        : isReady
                            ? AppColors.cyanAccent
                            : AppColors.accentBlue,
                    onPressed: rider != null && rider.isActiveInRace
                        ? () => _activatePowerUpForSelectedRider(type)
                        : null,
                    compact: true,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardAndEliminationCard() {
    final atRisk = _worldModel.atRiskEliminationRider;
    final sched = _worldModel.eliminationSchedule;

    return _EsportsPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.leaderboard_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Klasyfikacja Live & Strefa Eliminacji',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(sched.progressFraction * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: sched.progressFraction,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                sched.isInFinalTenSecondsWarning
                    ? AppColors.crimsonAlert
                    : AppColors.cyanAccent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._worldModel.riders.map((rider) {
            final isSelected = rider.riderId == _selectedRiderId;
            final isAtRisk = atRisk?.riderId == rider.riderId;
            final dualOk = _worldModel.checkDualRecordingCompliance(rider);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InteractiveEsportsCard(
                selected: isSelected,
                borderColor: isAtRisk
                    ? AppColors.crimsonAlert
                    : isSelected
                        ? AppColors.cyanAccent
                        : AppColors.cardBorder,
                onTap: () {
                  setState(() {
                    _selectedRiderId = rider.riderId;
                    _targetPowerWatts = rider.ftpWatts;
                    _recomputeSelectedRiderPhysics(dtSeconds: 0.25);
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rider.isActiveInRace
                            ? (rider.rank == 1
                                ? AppColors.goldAccent.withValues(alpha: 0.2)
                                : AppColors.surface)
                            : AppColors.crimsonAlert.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rider.isActiveInRace ? '${rider.rank}' : 'OUT',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: rider.isActiveInRace
                              ? (rider.rank == 1
                                  ? AppColors.goldAccent
                                  : AppColors.textPrimary)
                              : AppColors.crimsonAlert,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  rider.riderName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: rider.isActiveInRace
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                rider.teamCode,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${rider.currentWkg.toStringAsFixed(2)} W/kg • '
                            '${rider.currentPowerWatts.toStringAsFixed(0)} W • '
                            '${rider.speedKmh.toStringAsFixed(1)} km/h',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isAtRisk)
                          const _MiniStatusTag(
                            label: 'ZAGROŻONY',
                            color: AppColors.crimsonAlert,
                          )
                        else if (!dualOk)
                          const _MiniStatusTag(
                            label: 'DUAL !',
                            color: AppColors.amberWarning,
                          )
                        else if (rider.activePowerUpType != null)
                          _MiniStatusTag(
                            label: rider.activePowerUpType!.displayName,
                            color: AppColors.cyanAccent,
                          )
                        else
                          Text(
                            rider.gapToLeaderSeconds <= 0.05
                                ? 'LIDER'
                                : '+${rider.gapToLeaderSeconds.toStringAsFixed(1)}s',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 54,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: rider.wPrimeFraction,
                              minHeight: 4,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rider.wPrimeFraction > 0.35
                                    ? AppColors.statusSuccess
                                    : AppColors.amberWarning,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          if (sched.eliminationHistory.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 10),
            const Text(
              'Historia Eliminacji',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...sched.eliminationHistory.reversed.take(4).map(
                  (rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'R${rec.roundNumber} (${rec.triggerTimeSeconds}s): '
                      '${rec.eliminatedRiderName} (${rec.eliminatedWkg.toStringAsFixed(2)} W/kg)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: TRENAŻER SMART & DUAL-RECORDING
  // ===========================================================================

  Widget _buildTrainerAndDualRecordingTab({
    required bool isMobile,
    required bool isDesktop,
  }) {
    final rider = _selectedRider;
    final padding = isMobile ? 12.0 : 20.0;

    if (rider == null) {
      return const Center(
        child: Text(
          'Brak aktywnego kolarza do konfiguracji trenażera.',
          style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
        ),
      );
    }

    final trainerPresets = <SmartTrainerHardwareSpec>[
      SmartTrainerHardwareSpec.smartBike(),
      SmartTrainerHardwareSpec.proDirectDrive(),
      const SmartTrainerHardwareSpec(
        id: 'trainer_std_dd',
        brand: 'Elite / Saris',
        modelName: 'Direct-Drive Standard S3',
        tier: SmartTrainerTier.directDriveStandard,
        accuracyPercent: 2.0,
        maxSimulatedGradientPercent: 16.0,
        flywheelInertiaKg: 5.1,
        maxPowerWatts: 1800,
        dualPowerMeterVerified: false,
      ),
      const SmartTrainerHardwareSpec(
        id: 'trainer_wheel_on',
        brand: 'Tacx Basic',
        modelName: 'Wheel-On Flow T2',
        tier: SmartTrainerTier.wheelOnBasic,
        accuracyPercent: 3.5,
        maxSimulatedGradientPercent: 7.0,
        flywheelInertiaKg: 2.4,
        maxPowerWatts: 950,
        calibrationStatus: SmartTrainerCalibrationStatus.warmUpRequired,
        dualPowerMeterVerified: false,
      ),
    ];

    final hardwareCard = _EsportsPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_input_component_rounded,
                color: AppColors.cyanAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Konfiguracja Trenażera Smart (${rider.riderName})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EsportsTrainerControlMode.values.map((mode) {
              return _EsportsChoiceChip(
                label: mode.labelPl,
                selected: mode == _trainerControlMode,
                accentColor: AppColors.cyanAccent,
                onTap: () {
                  setState(() {
                    _trainerControlMode = mode;
                    _recomputeSelectedRiderPhysics(dtSeconds: 0.5);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Zadana moc (ERG / Symulacja):',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_targetPowerWatts.toStringAsFixed(0)} W '
                '(${(_targetPowerWatts / rider.weightKg).toStringAsFixed(2)} W/kg)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          Slider(
            value: _targetPowerWatts.clamp(150.0, 650.0),
            min: 150.0,
            max: 650.0,
            divisions: 50,
            activeColor: AppColors.cyanAccent,
            inactiveColor: AppColors.surfaceLight,
            onChanged: (value) {
              setState(() {
                _targetPowerWatts = value;
                _recomputeSelectedRiderPhysics(dtSeconds: 0.5);
              });
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Wybierz klasę sprzętu Smart:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...trainerPresets.map((preset) {
            final isCurrent = rider.trainerSpec.id == preset.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InteractiveEsportsCard(
                selected: isCurrent,
                borderColor: isCurrent
                    ? AppColors.cyanAccent
                    : AppColors.cardBorder,
                onTap: () => _applyTrainerSpecToSelectedRider(preset),
                child: Row(
                  children: [
                    Icon(
                      preset.tier.isUciWorldChampionshipEligible
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      color: preset.tier.isUciWorldChampionshipEligible
                          ? AppColors.statusSuccess
                          : AppColors.amberWarning,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${preset.brand} — ${preset.modelName}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${preset.tier.displayNamePl} • Max ${preset.maxPowerWatts} W • '
                            'Nachylenie ${preset.maxSimulatedGradientPercent.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MiniStatusTag(
                      label: preset.tier.isUciWorldChampionshipEligible
                          ? 'UCI OK'
                          : 'AMATOR',
                      color: preset.tier.isUciWorldChampionshipEligible
                          ? AppColors.statusSuccess
                          : AppColors.amberWarning,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );

    final physics = _lastPhysicsResult;
    final dualCompliant = _worldModel.checkDualRecordingCompliance(rider);

    final telemetryCard = _EsportsPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Weryfikacja Dual-Recording & Bilans Mocy',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _MiniStatusTag(
                label: dualCompliant ? 'UCI ZGODNY' : 'BŁĄD UCI',
                color: dualCompliant
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Status kalibracji',
            rider.trainerSpec.calibrationStatus.displayNamePl,
            valueColor: rider.trainerSpec.calibrationStatus ==
                    SmartTrainerCalibrationStatus.calibrated
                ? AppColors.statusSuccess
                : AppColors.amberWarning,
          ),
          _buildMetricRow(
            'Rozbieżność Dual-Recording',
            '${rider.dualRecordingDeltaPercent.toStringAsFixed(2)}% '
                '(limit ≤ ${_worldModel.uciDualRecordingMaxDeltaPercent.toStringAsFixed(1)}%)',
            valueColor: dualCompliant
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert,
          ),
          _buildMetricRow(
            'Margines błędu sprzętu',
            '±${rider.trainerSpec.effectivePowerErrorMarginWatts(_targetPowerWatts).toStringAsFixed(1)} W',
          ),
          if (physics != null) ...[
            const Divider(color: AppColors.cardBorder, height: 20),
            _buildMetricRow(
              'Odcinek trasy',
              '${physics.currentSegment.name} (${physics.currentSegment.gradientPercent.toStringAsFixed(1)}%)',
            ),
            _buildMetricRow(
              'Prędkość symulowana',
              '${physics.speedKmh.toStringAsFixed(1)} km/h',
              valueColor: AppColors.cyanAccent,
            ),
            _buildMetricRow(
              'Opór aerodynamiczny (Aero)',
              '${physics.aeroDragWatts.toStringAsFixed(1)} W',
            ),
            _buildMetricRow(
              'Opór toczenia (CRR)',
              '${physics.rollingResistanceWatts.toStringAsFixed(1)} W',
            ),
            _buildMetricRow(
              'Składowa grawitacyjna',
              '${physics.gravityWatts.toStringAsFixed(1)} W',
            ),
            _buildMetricRow(
              'Oszczędność z Power-Upa',
              '${physics.powerSavingsFromPowerUpWatts.toStringAsFixed(1)} W',
              valueColor: AppColors.statusSuccess,
            ),
          ],
          const SizedBox(height: 14),
          _EsportsActionButton(
            icon: Icons.tune_rounded,
            label: 'Wykonaj Spindown & Kalibrację Dual-Recording',
            accentColor: AppColors.statusSuccess,
            onPressed: _calibrateSelectedRiderTrainer,
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: hardwareCard),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: telemetryCard),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hardwareCard,
                const SizedBox(height: 16),
                telemetryCard,
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 3: VIRTUAL TALENT ID ACADEMY
  // ===========================================================================

  Widget _buildTalentIdAcademyTab({
    required bool isMobile,
    required bool isDesktop,
  }) {
    final padding = isMobile ? 12.0 : 20.0;
    final filtered = _worldModel.talentIdPool.where((t) {
      if (_onlyUnsignedTalents && t.isSignedToDevelopmentSquad) {
        return false;
      }
      if (_talentSearchQuery.trim().isNotEmpty) {
        final q = _talentSearchQuery.trim().toLowerCase();
        return t.athleteName.toLowerCase().contains(q) ||
            t.nationalityCode.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_talentSortField) {
        case _TalentSortField.eloDesc:
          return b.esportsElo.compareTo(a.esportsElo);
        case _TalentSortField.fiveMinWkgDesc:
          return b.verifiedFiveMinWkg.compareTo(a.verifiedFiveMinWkg);
        case _TalentSortField.ftpWkgDesc:
          return b.ftpWkg.compareTo(a.ftpWkg);
      }
    });

    final selectedTalent = _selectedTalent;

    final poolListCard = _EsportsPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pula Skautingu — Virtual Talent ID Academy',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filtered.length} kandydatów',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _talentSearchQuery = val),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Szukaj kandydata lub kraju (np. POL, COL)...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cyanAccent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EsportsChoiceChip(
                label: 'Sortuj: ELO',
                selected: _talentSortField == _TalentSortField.eloDesc,
                accentColor: AppColors.goldAccent,
                onTap: () =>
                    setState(() => _talentSortField = _TalentSortField.eloDesc),
              ),
              _EsportsChoiceChip(
                label: 'Sortuj: 5-min W/kg',
                selected: _talentSortField == _TalentSortField.fiveMinWkgDesc,
                accentColor: AppColors.cyanAccent,
                onTap: () => setState(
                  () => _talentSortField = _TalentSortField.fiveMinWkgDesc,
                ),
              ),
              _EsportsChoiceChip(
                label: 'Sortuj: FTP W/kg',
                selected: _talentSortField == _TalentSortField.ftpWkgDesc,
                accentColor: AppColors.accentBlue,
                onTap: () => setState(
                  () => _talentSortField = _TalentSortField.ftpWkgDesc,
                ),
              ),
              _EsportsChoiceChip(
                label: 'Tylko wolni',
                selected: _onlyUnsignedTalents,
                accentColor: AppColors.statusSuccess,
                onTap: () => setState(
                  () => _onlyUnsignedTalents = !_onlyUnsignedTalents,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Brak kandydatów spełniających wybrane kryteria.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...filtered.map((talent) {
              final isSelected = selectedTalent?.id == talent.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InteractiveEsportsCard(
                  selected: isSelected,
                  borderColor: isSelected
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
                  onTap: () => setState(() => _selectedTalentId = talent.id),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: talent.isSignedToDevelopmentSquad
                            ? AppColors.statusSuccess.withValues(alpha: 0.2)
                            : AppColors.surface,
                        child: Text(
                          talent.nationalityCode,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: talent.isSignedToDevelopmentSquad
                                ? AppColors.statusSuccess
                                : AppColors.goldAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${talent.athleteName} (${talent.age} l.)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '5m: ${talent.verifiedFiveMinWkg.toStringAsFixed(2)} W/kg • '
                              'FTP: ${talent.ftpWkg.toStringAsFixed(2)} W/kg • '
                              'Sprint: ${talent.peakSprintWatts} W',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontFeatures: [FontFeature.tabularFigures()],
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'ELO ${talent.esportsElo}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.cyanAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _MiniStatusTag(
                            label: talent.isSignedToDevelopmentSquad
                                ? 'DEVO SQUAD'
                                : 'KANDYDAT',
                            color: talent.isSignedToDevelopmentSquad
                                ? AppColors.statusSuccess
                                : AppColors.accentBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );

    final dossierCard = selectedTalent == null
        ? const _EsportsPanelCard(
            child: Text(
              'Wybierz kandydata z listy, aby przeanalizować jego profil fizjologiczny.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          )
        : _EsportsPanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.analytics_rounded,
                      color: AppColors.cyanAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Karta Skautingowa: ${selectedTalent.athleteName}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _MiniStatusTag(
                      label: selectedTalent.isSignedToDevelopmentSquad
                          ? 'PODPISANY'
                          : 'WOLNY AGENT',
                      color: selectedTalent.isSignedToDevelopmentSquad
                          ? AppColors.statusSuccess
                          : AppColors.goldAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildMetricRow(
                  'Kraj / Wiek / Masa',
                  '${selectedTalent.nationalityCode} • ${selectedTalent.age} lat • '
                      '${selectedTalent.weightKg.toStringAsFixed(1)} kg',
                ),
                _buildMetricRow(
                  'Zweryfikowane FTP',
                  '${selectedTalent.verifiedFtpWatts.toStringAsFixed(0)} W '
                      '(${selectedTalent.ftpWkg.toStringAsFixed(2)} W/kg)',
                  valueColor: AppColors.cyanAccent,
                ),
                _buildMetricRow(
                  'Moc 5-minutowa (VO2max)',
                  '${selectedTalent.verifiedFiveMinWkg.toStringAsFixed(2)} W/kg',
                  valueColor: AppColors.goldAccent,
                ),
                _buildMetricRow(
                  'Szczytowy Sprint (5 s)',
                  '${selectedTalent.peakSprintWatts} W',
                ),
                _buildMetricRow(
                  'Ranking UCI e-Sports ELO',
                  '${selectedTalent.esportsElo} pkt',
                  valueColor: AppColors.accentBlue,
                ),
                _buildMetricRow(
                  'Wiarygodność Dual-Recording',
                  '${selectedTalent.dualRecordingScore}/100',
                  valueColor: selectedTalent.dualRecordingScore >= 97
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _EsportsActionButton(
                      icon: selectedTalent.isSignedToDevelopmentSquad
                          ? Icons.person_remove_rounded
                          : Icons.person_add_alt_1_rounded,
                      label: selectedTalent.isSignedToDevelopmentSquad
                          ? 'Zwolnij z Devo Squad'
                          : 'Podpisz do Devo Squad',
                      accentColor: selectedTalent.isSignedToDevelopmentSquad
                          ? AppColors.primaryAccent
                          : AppColors.statusSuccess,
                      onPressed: () => _toggleTalentContract(selectedTalent),
                    ),
                    _EsportsActionButton(
                      icon: Icons.speed_rounded,
                      label: 'Test Combine 5-min',
                      accentColor: AppColors.goldAccent,
                      onPressed: () => _runCombineTestForTalent(selectedTalent),
                    ),
                  ],
                ),
              ],
            ),
          );

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: poolListCard),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: dossierCard),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                poolListCard,
                const SizedBox(height: 16),
                dossierCard,
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 4: REGULAMIN UCI & KATALOG POWER-UPÓW
  // ===========================================================================

  Widget _buildRegulationsAndPowerUpsTab({
    required bool isMobile,
    required bool isDesktop,
  }) {
    final padding = isMobile ? 12.0 : 20.0;
    final currentSegment = _selectedRider != null
        ? _worldModel.worldSpec.segmentAtDistance(_selectedRider!.distanceMeters)
        : _worldModel.worldSpec.segments.first;

    final powerUpsCard = _EsportsPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.cyanAccent, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Katalog Power-Upów UCI Cycling Esports',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Bieżący odcinek: ${currentSegment.name} '
            '(${currentSegment.gradientPercent.toStringAsFixed(1)}%)',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...EsportsPowerUpSpec.catalog.values.map((spec) {
            final optimalNow =
                spec.isOptimalForGradient(currentSegment.gradientPercent);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: optimalNow
                      ? AppColors.statusSuccess.withValues(alpha: 0.65)
                      : AppColors.cardBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${spec.displayName} (${spec.durationSeconds.toStringAsFixed(0)} s)',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _MiniStatusTag(
                        label: optimalNow ? 'OPTYMALNY TERAZ' : 'POZA OKNEM',
                        color: optimalNow
                            ? AppColors.statusSuccess
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec.descriptionPl,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Okno nachylenia: ${spec.idealSlopeMinPercent.toStringAsFixed(1)}% '
                    'do ${spec.idealSlopeMaxPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    final rulesCard = _EsportsPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppColors.goldAccent, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Przepisy Techniczne UCI Cycling Esports',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            'Limit rozbieżności Dual-Recording',
            '≤ ${_worldModel.uciDualRecordingMaxDeltaPercent.toStringAsFixed(1)}%',
            valueColor: AppColors.cyanAccent,
          ),
          _buildMetricRow(
            'Obowiązkowe ważenie przed startem',
            '${_worldModel.uciMinWeighInHoursBeforeStart} h przed wyścigiem',
          ),
          _buildMetricRow(
            'Interwał eliminacji',
            'Co ${_worldModel.eliminationSchedule.intervalSeconds} s (ostatni kolarz odpada)',
          ),
          _buildMetricRow(
            'Pula nagród wydarzenia',
            '€${_worldModel.prizePoolEur.toStringAsFixed(0)}',
            valueColor: AppColors.goldAccent,
          ),
          _buildMetricRow(
            'Ranga zawodów',
            _worldModel.platformTier.displayNamePl,
          ),
          _buildMetricRow(
            'Sankcjonowanie UCI',
            _worldModel.isUciSanctioned ? 'Tak (Oficjalne MŚ)' : 'Nie',
            valueColor: _worldModel.isUciSanctioned
                ? AppColors.statusSuccess
                : AppColors.amberWarning,
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: powerUpsCard),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: rulesCard),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                powerUpsCard,
                const SizedBox(height: 16),
                rulesCard,
              ],
            ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value, {
    Color valueColor = AppColors.textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TalentSortField {
  eloDesc,
  fiveMinWkgDesc,
  ftpWkgDesc,
}

// =============================================================================
// KOMPONENTY UI Z PEŁNYMI STANAMI HOVER / ACTIVE / DISABLED / FOCUS
// =============================================================================

class _EsportsPanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _EsportsPanelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: child,
    );
  }
}

class _InteractiveEsportsCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final Color borderColor;

  const _InteractiveEsportsCard({
    required this.child,
    required this.onTap,
    required this.selected,
    required this.borderColor,
  });

  @override
  State<_InteractiveEsportsCard> createState() =>
      _InteractiveEsportsCardState();
}

class _InteractiveEsportsCardState extends State<_InteractiveEsportsCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final activeBorder = _focused
        ? AppColors.cyanAccent
        : widget.selected
            ? widget.borderColor
            : _hovered
                ? AppColors.accentBlue.withValues(alpha: 0.7)
                : widget.borderColor;

    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      mouseCursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _pressed
                  ? AppColors.surface
                  : widget.selected || _hovered
                      ? AppColors.surfaceLight
                      : AppColors.surfaceLight.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activeBorder,
                width: widget.selected || _focused ? 1.5 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _EsportsActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool compact;

  const _EsportsActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accentColor = AppColors.primaryAccent,
    this.compact = false,
  });

  @override
  State<_EsportsActionButton> createState() => _EsportsActionButtonState();
}

class _EsportsActionButtonState extends State<_EsportsActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final effectiveColor =
        enabled ? widget.accentColor : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: MouseRegion(
        onEnter: (_) {
          if (enabled) setState(() => _hovered = true);
        },
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: widget.compact ? 7 : 10,
            ),
            decoration: BoxDecoration(
              color: !enabled
                  ? AppColors.surfaceLight.withValues(alpha: 0.4)
                  : _pressed
                      ? effectiveColor.withValues(alpha: 0.34)
                      : _hovered
                          ? effectiveColor.withValues(alpha: 0.25)
                          : effectiveColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.textPrimary
                    : enabled
                        ? effectiveColor.withValues(alpha: 0.6)
                        : AppColors.cardBorder,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: enabled ? effectiveColor : AppColors.textSecondary,
                ),
                if (widget.label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EsportsChoiceChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _EsportsChoiceChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_EsportsChoiceChip> createState() => _EsportsChoiceChipState();
}

class _EsportsChoiceChipState extends State<_EsportsChoiceChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      mouseCursor: SystemMouseCursors.click,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accentColor.withValues(alpha: 0.2)
                  : _hovered
                      ? AppColors.surfaceLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.textPrimary
                    : widget.selected
                        ? widget.accentColor
                        : AppColors.cardBorder,
                width: widget.selected || _focused ? 1.4 : 1.0,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                color: widget.selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EsportsKpiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _EsportsKpiChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniStatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
