import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/rendering3d/team_bus_paddock_3d_scene_renderer.dart';
import '../../models/team/team_bus_and_warmup_protocol_model.dart';

/// Ekran Paddocku Przedstartowego z interaktywną sceną 3D autobusu drużyny,
/// konfiguracją protokołów rozgrzewki (`VO2 Priming` +4.5% mocy na starcie ITT)
/// oraz strategią chłodzenia `Pre-Cooling Ice Vest` przed startem etapu.
class PreStagePaddockAndWarmupScreen extends StatefulWidget {
  final TeamBusAndWarmupProtocolModel? initialModel;
  final PaddockWeatherPreset initialWeatherPreset;
  final String teamName;
  final String teamShortCode;
  final Color primaryTeamColor;
  final bool autoPlay3d;
  final bool isReadOnly;
  final VoidCallback? onBack;
  final ValueChanged<TeamBusAndWarmupProtocolModel>? onModelChanged;
  final ValueChanged<TeamBusAndWarmupProtocolModel>? onProceedToStart;

  const PreStagePaddockAndWarmupScreen({
    super.key,
    this.initialModel,
    this.initialWeatherPreset = PaddockWeatherPreset.hotGrandTour,
    this.teamName = 'Veloce Pro Cycling',
    this.teamShortCode = 'VPC',
    this.primaryTeamColor = AppColors.primaryAccent,
    this.autoPlay3d = true,
    this.isReadOnly = false,
    this.onBack,
    this.onModelChanged,
    this.onProceedToStart,
  });

  /// Tworzy domyślny stan paddocku przed etapem jazdy indywidualnej na czas (ITT).
  static TeamBusAndWarmupProtocolModel buildDefaultModel({
    TeamBusTier busTier = TeamBusTier.worldTourFlagshipBus,
    String teamName = 'Veloce Pro Cycling',
    double ambientTempCelsius = 33.0,
    bool isIndividualTimeTrial = true,
    bool isTeamTimeTrial = false,
    bool hasSteepEarlyClimb = false,
  }) {
    final bus = TeamBusSpecification.forTier(busTier, teamName: teamName);
    final baseRiders = PaddockWarmupRider3D.buildDefaultRoster(
      busTier: busTier,
      teamJerseyColor: AppColors.primaryAccent,
    );

    final assignments = List<RiderWarmupAssignment>.generate(
      baseRiders.length,
      (index) {
        final r = baseRiders[index];
        final cooling = r.coolingStrategy == CoolingStrategyType.preCoolingIceVest &&
                !bus.hasIceVestFreezer
            ? CoolingStrategyType.fanAndColdTowels
            : r.coolingStrategy;
        return RiderWarmupAssignment(
          riderId: r.riderId,
          riderName: r.riderName,
          trainerSlotIndex: r.slotIndex,
          protocolType: r.protocolType,
          coolingStrategy: cooling,
          minutesBeforeStart: 12,
          riderFtpWatts: r.ftpWatts.round(),
          riderWeightKg: 68.0 + (index % 4) * 2.5,
          ambientTempCelsius: ambientTempCelsius,
          isIttOrPrologue: isIndividualTimeTrial || isTeamTimeTrial,
          status: WarmupCompletionStatus.inProgress,
        );
      },
    );

    return TeamBusAndWarmupProtocolModel(
      stageId: 'stage_paddock_itt',
      stageName: isIndividualTimeTrial
          ? 'Etap 14 • ITT Pau — Pau (34.2 km)'
          : 'Etap Królewski • Col du Tourmalet (168 km)',
      isIndividualTimeTrial: isIndividualTimeTrial,
      isTeamTimeTrial: isTeamTimeTrial,
      ambientTempCelsius: ambientTempCelsius,
      hasSteepEarlyClimb: hasSteepEarlyClimb,
      teamBus: bus,
      assignments: assignments,
    );
  }

  @override
  State<PreStagePaddockAndWarmupScreen> createState() =>
      _PreStagePaddockAndWarmupScreenState();
}

class _PreStagePaddockAndWarmupScreenState
    extends State<PreStagePaddockAndWarmupScreen> {
  static const Color _cardBorderColor = Color(0xFF2A2F3D);
  static const Duration _animDuration = Duration(milliseconds: 250);

  late TeamBusAndWarmupProtocolModel _model;
  late PaddockWeatherPreset _weatherPreset;
  late String _selectedRiderId;
  int _sceneSyncVersion = 0;

  @override
  void initState() {
    super.initState();
    _weatherPreset = widget.initialWeatherPreset;
    _model = widget.initialModel ??
        PreStagePaddockAndWarmupScreen.buildDefaultModel(
          teamName: widget.teamName,
          ambientTempCelsius: _weatherPreset.ambientTempCelsius,
        );
    _selectedRiderId = _model.assignments.isNotEmpty
        ? _model.assignments.first.riderId
        : '';
  }

  @override
  void didUpdateWidget(covariant PreStagePaddockAndWarmupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialModel != null &&
        widget.initialModel != oldWidget.initialModel) {
      _model = widget.initialModel!;
      if (!_model.assignments.any((a) => a.riderId == _selectedRiderId)) {
        _selectedRiderId = _model.assignments.isNotEmpty
            ? _model.assignments.first.riderId
            : '';
      }
      _sceneSyncVersion++;
    }
  }

  RiderWarmupAssignment? get _selectedAssignment {
    if (_model.assignments.isEmpty) return null;
    for (final a in _model.assignments) {
      if (a.riderId == _selectedRiderId) return a;
    }
    return _model.assignments.first;
  }

  void _commitModel(TeamBusAndWarmupProtocolModel nextModel) {
    setState(() {
      _model = nextModel;
      if (!_model.assignments.any((a) => a.riderId == _selectedRiderId)) {
        _selectedRiderId = _model.assignments.isNotEmpty
            ? _model.assignments.first.riderId
            : '';
      }
      _sceneSyncVersion++;
    });
    widget.onModelChanged?.call(nextModel);
  }

  void _selectRider(String riderId) {
    if (_selectedRiderId == riderId) return;
    setState(() {
      _selectedRiderId = riderId;
    });
  }

  void _changeWeatherPreset(PaddockWeatherPreset preset) {
    if (widget.isReadOnly) return;
    final updatedAssignments = _model.assignments
        .map(
          (a) => a.copyWith(ambientTempCelsius: preset.ambientTempCelsius),
        )
        .toList(growable: false);
    setState(() {
      _weatherPreset = preset;
    });
    _commitModel(
      _model.copyWith(
        ambientTempCelsius: preset.ambientTempCelsius,
        assignments: updatedAssignments,
      ),
    );
  }

  void _changeBusTier(TeamBusTier tier) {
    if (widget.isReadOnly || tier == _model.teamBus.tier) return;
    final nextBus = TeamBusSpecification.forTier(
      tier,
      busId: _model.teamBus.busId,
      teamName: widget.teamName,
    );
    final maxSlots = nextBus.trainerStationCount;
    final current = _model.assignments;
    final nextAssignments = <RiderWarmupAssignment>[];

    for (int i = 0; i < math.min(current.length, maxSlots); i++) {
      final a = current[i];
      final sanitizedCooling =
          a.coolingStrategy == CoolingStrategyType.preCoolingIceVest &&
                  !nextBus.hasIceVestFreezer
              ? CoolingStrategyType.fanAndColdTowels
              : a.coolingStrategy;
      nextAssignments.add(
        a.copyWith(
          trainerSlotIndex: i,
          coolingStrategy: sanitizedCooling,
        ),
      );
    }

    if (nextAssignments.length < maxSlots) {
      final defaults = PaddockWarmupRider3D.buildDefaultRoster(
        busTier: tier,
        teamJerseyColor: widget.primaryTeamColor,
      );
      for (int i = nextAssignments.length; i < maxSlots; i++) {
        final d = defaults[i % defaults.length];
        final sanitizedCooling =
            d.coolingStrategy == CoolingStrategyType.preCoolingIceVest &&
                    !nextBus.hasIceVestFreezer
                ? CoolingStrategyType.fanAndColdTowels
                : d.coolingStrategy;
        nextAssignments.add(
          RiderWarmupAssignment(
            riderId: 'rider_$i',
            riderName: d.riderName,
            trainerSlotIndex: i,
            protocolType: d.protocolType,
            coolingStrategy: sanitizedCooling,
            minutesBeforeStart: 12,
            riderFtpWatts: d.ftpWatts.round(),
            riderWeightKg: 68.5 + (i % 3) * 2.0,
            ambientTempCelsius: _model.ambientTempCelsius,
            isIttOrPrologue:
                _model.isIndividualTimeTrial || _model.isTeamTimeTrial,
            status: WarmupCompletionStatus.inProgress,
          ),
        );
      }
    }

    _commitModel(
      _model.copyWith(
        teamBus: nextBus,
        assignments: nextAssignments,
      ),
    );
  }

  void _updateSelectedRider({
    WarmupProtocolType? protocolType,
    CoolingStrategyType? coolingStrategy,
    int? minutesBeforeStart,
  }) {
    final current = _selectedAssignment;
    if (widget.isReadOnly || current == null) return;

    final nextProtocol = protocolType ?? current.protocolType;
    var nextCooling = coolingStrategy ?? current.coolingStrategy;
    if (nextCooling == CoolingStrategyType.preCoolingIceVest &&
        !_model.teamBus.hasIceVestFreezer) {
      nextCooling = CoolingStrategyType.fanAndColdTowels;
    }
    final nextMinutes = (minutesBeforeStart ?? current.minutesBeforeStart)
        .clamp(0, 30);

    final updated = _model.assignRiderToTrainer(
      riderId: current.riderId,
      riderName: current.riderName,
      riderFtpWatts: current.riderFtpWatts,
      riderWeightKg: current.riderWeightKg,
      protocolType: nextProtocol,
      coolingStrategy: nextCooling,
      minutesBeforeStart: nextMinutes,
      preferredSlotIndex: current.trainerSlotIndex,
    );
    _commitModel(updated);
  }

  void _autoOptimizeTeam() {
    if (widget.isReadOnly || _model.assignments.isEmpty) return;
    final recommendedProtocol = _model.recommendProtocolForStage(
      isItt: _model.isIndividualTimeTrial,
      isTtt: _model.isTeamTimeTrial,
      hasSteepEarlyClimb: _model.hasSteepEarlyClimb,
      isShortPrologueOrCrit: false,
    );
    final recommendedCooling =
        _model.recommendCoolingForProtocol(recommendedProtocol);

    final optimized = _model.assignments
        .map(
          (a) => a.copyWith(
            protocolType: recommendedProtocol,
            coolingStrategy: recommendedCooling,
            minutesBeforeStart: 12,
          ),
        )
        .toList(growable: false);

    _commitModel(_model.copyWith(assignments: optimized));
  }

  List<PaddockWarmupRider3D> _build3dRiders() {
    final outcomes = _model.evaluateAllAssignments();
    return List<PaddockWarmupRider3D>.generate(_model.assignments.length, (i) {
      final a = _model.assignments[i];
      final outcome = outcomes[i];
      final preset = WarmupProtocolPreset.fromType(a.protocolType);
      final targetRatio = preset.steps.isEmpty
          ? 0.0
          : preset.steps.last.averageFtpPercent / 100.0;
      return PaddockWarmupRider3D(
        riderId: a.riderId,
        riderName: a.riderName,
        bibNumber: 11 + i,
        roleLabel: i == 0 ? 'Lider' : 'Ekipa',
        slotIndex: a.trainerSlotIndex,
        trainerType: _model.teamBus.trainerType,
        protocolType: a.protocolType,
        coolingStrategy: a.coolingStrategy,
        ftpWatts: a.riderFtpWatts.toDouble(),
        currentPowerWatts: (a.riderFtpWatts * targetRatio).roundToDouble(),
        cadenceRpm: a.protocolType == WarmupProtocolType.none ? 0.0 : 94.0,
        heartRateBpm: a.protocolType == WarmupProtocolType.none ? 68 : 138 + i * 3,
        coreTempCelsius: outcome.estimatedStartCoreTempCelsius,
        warmupProgress: a.protocolType == WarmupProtocolType.none ? 0.0 : 0.72,
        isLeader: i == 0,
        jerseyColor: i == 0 ? AppColors.goldAccent : widget.primaryTeamColor,
        helmetColor: i == 0 ? AppColors.goldAccent : AppColors.textPrimary,
      );
    });
  }

  void _handleProceedToStart() {
    if (widget.isReadOnly) return;
    if (widget.onProceedToStart != null) {
      widget.onProceedToStart!(_model);
      return;
    }
    final avgBonus = _model.averageStartPowerBonusPercent.toStringAsFixed(1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Ekipa gotowa do startu (śr. premia mocy: +$avgBonus%).',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1100;
            final isTablet = width >= 720 && width < 1100;

            return Column(
              children: [
                _buildHeaderBar(compact: width < 720),
                Expanded(
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : isTablet
                          ? _buildTabletLayout()
                          : _buildMobileLayout(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderBar({required bool compact}) {
    final avgBonus = _model.averageStartPowerBonusPercent;
    final iceVestCount = _model.assignments
        .where((a) => a.coolingStrategy == CoolingStrategyType.preCoolingIceVest)
        .length;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: _cardBorderColor, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onBack != null || Navigator.of(context).canPop())
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _InteractivePaddockButton(
                    onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                    disabled: false,
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryAccent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _model.isIndividualTimeTrial
                                ? 'PADDOCK ITT'
                                : 'PADDOCK PRZEDSTARTOWY',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_model.ambientTempCelsius.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentBlue,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _model.stageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
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
              _HeaderStatChip(
                icon: Icons.bolt_rounded,
                label: 'Śr. premia',
                value:
                    '${avgBonus >= 0 ? '+' : ''}${avgBonus.toStringAsFixed(1)}%',
                accentColor: avgBonus >= 2.0
                    ? AppColors.statusSuccess
                    : AppColors.goldAccent,
              ),
              _HeaderStatChip(
                icon: Icons.ac_unit_rounded,
                label: 'Ice Vest',
                value: '$iceVestCount/${_model.assignments.length}',
                accentColor: AppColors.cyanAccent,
              ),
              _InteractivePaddockButton(
                onTap: _autoOptimizeTeam,
                disabled: widget.isReadOnly || _model.assignments.isEmpty,
                backgroundColor: AppColors.surfaceLight,
                borderColor: AppColors.accentBlue.withValues(alpha: 0.5),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_fix_high_rounded,
                      size: 16,
                      color: AppColors.accentBlue,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Auto-Optymalizuj',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _InteractivePaddockButton(
                onTap: _handleProceedToStart,
                disabled: widget.isReadOnly,
                backgroundColor: AppColors.primaryAccent,
                borderColor: AppColors.goldAccent.withValues(alpha: 0.7),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 16,
                      color: AppColors.goldAccent,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Start KM 0.0',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 310,
            child: _buildRosterColumn(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(child: _build3dViewportCard()),
                const SizedBox(height: 12),
                _buildBusAndWeatherBar(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 380,
            child: _buildConfiguratorColumn(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 300, child: _build3dViewportCard()),
                  const SizedBox(height: 12),
                  _buildBusAndWeatherBar(),
                  const SizedBox(height: 12),
                  _buildRosterListInline(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: _buildConfiguratorColumn(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 250, child: _build3dViewportCard()),
          const SizedBox(height: 12),
          _buildBusAndWeatherBar(),
          const SizedBox(height: 12),
          _buildRosterListInline(),
          const SizedBox(height: 12),
          _buildConfiguratorContent(),
        ],
      ),
    );
  }

  Widget _build3dViewportCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: TeamBusPaddock3dViewportWidget(
        key: ValueKey('paddock_3d_$_sceneSyncVersion'),
        autoPlay: widget.autoPlay3d,
        initialConfig: TeamBusPaddock3dConfig(
          busTier: _model.teamBus.tier,
          weatherPreset: _weatherPreset,
          teamName: widget.teamName,
          teamShortCode: widget.teamShortCode,
          primaryColor: widget.primaryTeamColor,
          accentColor: AppColors.goldAccent,
        ),
        initialRiders: _build3dRiders(),
        onRiderSelected: (rider) => _selectRider(rider.riderId),
      ),
    );
  }

  Widget _buildBusAndWeatherBar() {
    final bus = _model.teamBus;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_bus_filled_rounded,
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Autokar: ${bus.tier.displayNamePl} • ${bus.trainerType.displayNamePl}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bus.hasIceVestFreezer
                      ? AppColors.cyanAccent.withValues(alpha: 0.14)
                      : AppColors.amberWarning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: bus.hasIceVestFreezer
                        ? AppColors.cyanAccent.withValues(alpha: 0.5)
                        : AppColors.amberWarning.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  bus.hasIceVestFreezer
                      ? 'Zamrażarka Ice Vest: AKTYWNA'
                      : 'Brak zamrażarki Ice Vest',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: bus.hasIceVestFreezer
                        ? AppColors.cyanAccent
                        : AppColors.amberWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TeamBusTier.values.map((tier) {
              final selected = bus.tier == tier;
              return _InteractivePaddockButton(
                onTap: () => _changeBusTier(tier),
                disabled: widget.isReadOnly,
                isActive: selected,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '${tier.defaultTrainerSlots} stan. (${tier.prestigeStars}★)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: PaddockWeatherPreset.values.map((preset) {
              final selected = _weatherPreset == preset;
              return _InteractivePaddockButton(
                onTap: () => _changeWeatherPreset(preset),
                disabled: widget.isReadOnly,
                isActive: selected,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  preset.labelPl,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.accentBlue
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterColumn() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRosterHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: _model.assignments.isEmpty
                ? _buildEmptyRosterState()
                : ListView.separated(
                    itemCount: _model.assignments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildRiderSlotCard(_model.assignments[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterListInline() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRosterHeader(),
          const SizedBox(height: 10),
          if (_model.assignments.isEmpty)
            _buildEmptyRosterState()
          else
            ...List.generate(_model.assignments.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _model.assignments.length - 1 ? 0 : 8,
                ),
                child: _buildRiderSlotCard(_model.assignments[index], index),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRosterHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Stanowiska Trenażerów',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_model.assignedRidersCount}/${_model.teamBus.trainerStationCount}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.goldAccent,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRosterState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Brak przypisanych kolarzy na trenażerach w paddocku.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRiderSlotCard(RiderWarmupAssignment assignment, int index) {
    final isSelected = assignment.riderId == _selectedAssignment?.riderId;
    final outcome = _model.evaluateRiderWarmup(assignment);
    final hasIceVest =
        assignment.coolingStrategy == CoolingStrategyType.preCoolingIceVest;

    return _InteractivePaddockButton(
      onTap: () => _selectRider(assignment.riderId),
      disabled: false,
      isActive: isSelected,
      backgroundColor:
          isSelected ? AppColors.surfaceLight : AppColors.background,
      borderColor: isSelected ? AppColors.goldAccent : _cardBorderColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: index == 0
                      ? AppColors.goldAccent.withValues(alpha: 0.18)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${assignment.trainerSlotIndex + 1}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: index == 0
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assignment.riderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${outcome.effectiveStartPowerBonusPercent >= 0 ? '+' : ''}${outcome.effectiveStartPowerBonusPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: outcome.isOverheatedRisk
                      ? AppColors.crimsonAlert
                      : outcome.effectiveStartPowerBonusPercent > 0
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.protocolType.displayNamePl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (hasIceVest) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.ac_unit_rounded,
                  size: 14,
                  color: AppColors.cyanAccent,
                ),
              ] else if (outcome.isOverheatedRisk) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.crimsonAlert,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguratorColumn() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1.0),
      ),
      child: SingleChildScrollView(
        child: _buildConfiguratorContent(),
      ),
    );
  }

  Widget _buildConfiguratorContent() {
    final assignment = _selectedAssignment;
    if (assignment == null) {
      return _buildEmptyRosterState();
    }

    final outcome = _model.evaluateRiderWarmup(assignment);
    final preset = WarmupProtocolPreset.fromType(assignment.protocolType);
    final freezerAvailable = _model.teamBus.hasIceVestFreezer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.riderName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'FTP ${assignment.riderFtpWatts} W • ${assignment.riderWeightKg.toStringAsFixed(1)} kg • Stanowisko #${assignment.trainerSlotIndex + 1}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: outcome.isOverheatedRisk
                    ? AppColors.crimsonAlert.withValues(alpha: 0.16)
                    : AppColors.statusSuccess.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: outcome.isOverheatedRisk
                      ? AppColors.crimsonAlert
                      : AppColors.statusSuccess,
                ),
              ),
              child: Text(
                '${outcome.effectiveStartPowerWatts.toStringAsFixed(0)} W',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: outcome.isOverheatedRisk
                      ? AppColors.crimsonAlert
                      : AppColors.statusSuccess,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Protokół Rozgrzewki na Trenażerze',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...WarmupProtocolType.values.map((protocol) {
          final isSelected = assignment.protocolType == protocol;
          final p = WarmupProtocolPreset.fromType(protocol);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _InteractivePaddockButton(
              onTap: () => _updateSelectedRider(protocolType: protocol),
              disabled: widget.isReadOnly,
              isActive: isSelected,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.namePl,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.goldAccent
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.totalDurationMinutes} min • Glikogen ${p.glycogenCostGrams.toStringAsFixed(0)}g • +${p.coreTempRiseCelsius.toStringAsFixed(2)}°C',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${p.ittStartPowerBonusPercent >= 0 ? '+' : ''}${p.ittStartPowerBonusPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.ittStartPowerBonusPercent >= 4.0
                          ? AppColors.goldAccent
                          : p.ittStartPowerBonusPercent > 0
                              ? AppColors.statusSuccess
                              : AppColors.crimsonAlert,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        _buildIntervalChartCard(preset),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Chłodzenie & Pre-Cooling Ice Vest',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            if (!freezerAvailable)
              const Text(
                'Wymaga autokaru WorldTour',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amberWarning,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...CoolingStrategyType.values.map((strategy) {
          final isSelected = assignment.coolingStrategy == strategy;
          final isIceVest = strategy == CoolingStrategyType.preCoolingIceVest;
          final isDisabled =
              widget.isReadOnly || (isIceVest && !freezerAvailable);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _InteractivePaddockButton(
              onTap: () => _updateSelectedRider(coolingStrategy: strategy),
              disabled: isDisabled,
              isActive: isSelected,
              borderColor: isSelected
                  ? (isIceVest ? AppColors.cyanAccent : AppColors.goldAccent)
                  : _cardBorderColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isIceVest
                        ? Icons.ac_unit_rounded
                        : strategy == CoolingStrategyType.fanAndColdTowels
                            ? Icons.air_rounded
                            : Icons.block_rounded,
                    size: 16,
                    color: isDisabled
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : isIceVest
                            ? AppColors.cyanAccent
                            : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strategy.displayNamePl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isDisabled
                            ? AppColors.textSecondary.withValues(alpha: 0.5)
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    strategy.coreTempReductionCelsius == 0
                        ? '0.00°C'
                        : '-${strategy.coreTempReductionCelsius.toStringAsFixed(2)}°C',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDisabled
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : isIceVest
                              ? AppColors.cyanAccent
                              : AppColors.accentBlue,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        _buildTimingSliderCard(assignment),
        const SizedBox(height: 12),
        _buildPhysiologicalSummaryCard(outcome),
      ],
    );
  }

  Widget _buildIntervalChartCard(WarmupProtocolPreset preset) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Profil Interwałów Mocy (% FTP)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${preset.totalDurationMinutes} min',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            width: double.infinity,
            child: CustomPaint(
              painter: WarmupIntervalProfilePainter(steps: preset.steps),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSliderCard(RiderWarmupAssignment assignment) {
    final inOptimalWindow =
        assignment.minutesBeforeStart >= 8 && assignment.minutesBeforeStart <= 15;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Zejście z trenażera przed startem',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${assignment.minutesBeforeStart} min',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: inOptimalWindow
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: inOptimalWindow
                  ? AppColors.statusSuccess
                  : AppColors.amberWarning,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: assignment.minutesBeforeStart.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: widget.isReadOnly
                  ? null
                  : (v) => _updateSelectedRider(minutesBeforeStart: v.round()),
            ),
          ),
          const Text(
            'Optymalne okno resyntezy W\': 8–15 min przed startem.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysiologicalSummaryCard(WarmupPhysiologicalOutcome outcome) {
    final tempColor = outcome.isOverheatedRisk
        ? AppColors.crimsonAlert
        : outcome.estimatedStartCoreTempCelsius >= 37.8
            ? AppColors.amberWarning
            : AppColors.statusSuccess;

    return AnimatedContainer(
      duration: _animDuration,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: outcome.isOverheatedRisk
              ? AppColors.crimsonAlert
              : _cardBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Temp. głęboka',
                  value:
                      '${outcome.estimatedStartCoreTempCelsius.toStringAsFixed(2)}°C',
                  valueColor: tempColor,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'Gotowość W\'',
                  value:
                      '${(outcome.wPrimeRecoveryReadinessRatio * 100).toStringAsFixed(0)}%',
                  valueColor: AppColors.accentBlue,
                ),
              ),
              Expanded(
                child: _MetricTile(
                  label: 'Okno czasowe',
                  value:
                      '${(outcome.timingEfficiencyFactor * 100).toStringAsFixed(0)}%',
                  valueColor: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            outcome.summaryNotePl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: outcome.isOverheatedRisk
                  ? AppColors.crimsonAlert
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rysuje proporcjonalny profil bloków interwałowych rozgrzewki wg stref mocy.
class WarmupIntervalProfilePainter extends CustomPainter {
  final List<WarmupIntervalStep> steps;

  const WarmupIntervalProfilePainter({required this.steps});

  @override
  void paint(Canvas canvas, Size size) {
    if (steps.isEmpty || size.width <= 0 || size.height <= 0) {
      final linePaint = Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.35)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(0, size.height * 0.85),
        Offset(size.width, size.height * 0.85),
        linePaint,
      );
      return;
    }

    final totalMinutes = steps.fold<int>(0, (s, e) => s + e.durationMinutes);
    if (totalMinutes <= 0) return;

    double cursorX = 0.0;
    const double maxPowerRatio = 140.0;

    for (final step in steps) {
      final stepWidth = (step.durationMinutes / totalMinutes) * size.width;
      final normalizedHeight =
          (step.averageFtpPercent / maxPowerRatio).clamp(0.12, 1.0);
      final barHeight = normalizedHeight * (size.height - 6);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cursorX + 1,
          size.height - barHeight,
          math.max(2.0, stepWidth - 2),
          barHeight,
        ),
        const Radius.circular(4),
      );
      final zoneIndex = _zoneIndexFromFtp(step.averageFtpPercent);
      final paint = Paint()..color = AppColors.getPowerZoneColor(zoneIndex);
      canvas.drawRRect(rect, paint);
      cursorX += stepWidth;
    }
  }

  int _zoneIndexFromFtp(double ftpPercent) {
    if (ftpPercent < 56) return 1;
    if (ftpPercent < 76) return 2;
    if (ftpPercent < 91) return 3;
    if (ftpPercent < 106) return 4;
    if (ftpPercent < 121) return 5;
    return 6;
  }

  @override
  bool shouldRepaint(covariant WarmupIntervalProfilePainter oldDelegate) {
    return oldDelegate.steps != steps;
  }
}

class _HeaderStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _HeaderStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
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
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _InteractivePaddockButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool disabled;
  final bool isActive;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  const _InteractivePaddockButton({
    required this.onTap,
    required this.child,
    this.disabled = false,
    this.isActive = false,
    this.backgroundColor = AppColors.surfaceLight,
    this.borderColor = const Color(0xFF2A2F3D),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  State<_InteractivePaddockButton> createState() =>
      _InteractivePaddockButtonState();
}

class _InteractivePaddockButtonState extends State<_InteractivePaddockButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = widget.disabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.4)
        : widget.isActive
            ? AppColors.goldAccent
            : _focused
                ? AppColors.cyanAccent
                : _hovered
                    ? widget.borderColor.withValues(alpha: 0.95)
                    : widget.borderColor;

    final effectiveBg = widget.disabled
        ? widget.backgroundColor.withValues(alpha: 0.45)
        : _hovered
            ? Color.lerp(widget.backgroundColor, Colors.white, 0.05)!
            : widget.backgroundColor;

    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.disabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: effectiveBorder,
                width: widget.isActive || _focused ? 1.4 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
