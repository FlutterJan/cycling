// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import '../../services/career/pre_season_wind_tunnel_camp_event.dart';

/// Pomiar fizyczny oporu aerodynamicznego w Newtonach przy prędkości 50 km/h
/// dla wybranego kąta odchylenia wiatru pozornego (Yaw).
class WindTunnelYawDragSample {
  final int yawDegrees;
  final double baselineDragNewtons;
  final double optimizedDragNewtons;

  const WindTunnelYawDragSample({
    required this.yawDegrees,
    required this.baselineDragNewtons,
    required this.optimizedDragNewtons,
  });

  double get dragReductionNewtons =>
      math.max(0.0, baselineDragNewtons - optimizedDragNewtons);
}

/// Zestaw obliczeń fizycznych dla pomiarów oporu w Newtonach przy 50 km/h
/// oraz raportu zaoszczędzonych watów w Grudniowym Obozie Aerodynamicznym.
class WinterWindTunnelCampTelemetry {
  WinterWindTunnelCampTelemetry._();

  static const double referenceSpeedKmh = 50.0;
  static const double referenceSpeedMs = referenceSpeedKmh / 3.6;

  /// Oblicza siłę oporu aerodynamicznego [N] przy zadanej prędkości [km/h].
  ///
  /// Wzór: $F_d = \frac{1}{2} \cdot \rho \cdot CdA \cdot v^2$
  static double computeDragForceNewtons({
    required double cdaM2,
    double speedKmh = referenceSpeedKmh,
  }) {
    if (cdaM2 <= 0.0 || speedKmh <= 0.0) return 0.0;
    final vMs = speedKmh / 3.6;
    return 0.5 *
        PreSeasonWindTunnelCampEvent.airDensitySeaLevelKgM3 *
        cdaM2 *
        vMs *
        vMs;
  }

  /// Redukcja siły oporu w Newtonach przy 50 km/h dla danego wyniku testu.
  static double computeDragReductionNewtonsAt50Kmh(RiderAeroTestResult result) {
    final baseN = computeDragForceNewtons(cdaM2: result.initialBaseCdaM2);
    final optN = computeDragForceNewtons(cdaM2: result.optimizedBaseCdaM2);
    return math.max(0.0, baseN - optN);
  }

  /// Generuje krzywą oporu w Newtonach przy 50 km/h w funkcji kąta Yaw.
  static List<WindTunnelYawDragSample> buildYawDragCurve({
    required RiderAeroTestResult result,
    required WindTunnelFacility facility,
  }) {
    final maxYaw = facility.maxYawAngleDeg;
    final step = maxYaw >= 15 ? 5 : 4;
    final samples = <WindTunnelYawDragSample>[];

    final helmetYawFactor = switch (result.chosenHelmet) {
      AeroHelmetOption.standardRoadAero => 1.0,
      AeroHelmetOption.teardropTailLong => 0.94,
      AeroHelmetOption.wideVisorStubby => 0.80,
      AeroHelmetOption.custom3dPrintedVisor => 0.78,
    };

    for (int yaw = -maxYaw; yaw <= maxYaw; yaw += step) {
      final absYaw = yaw.abs().toDouble();
      // Bazowy opór rośnie parabolicznie wraz z kątem wiatru bocznego
      final baseYawPenalty = 1.0 + math.pow(absYaw / 24.0, 2) * 0.14;
      // Zoptymalizowany zestaw lepiej wykorzystuje efekt żagla przy umiarkowanym yaw
      final optYawPenalty =
          1.0 + math.pow(absYaw / 26.0, 2) * 0.10 * helmetYawFactor;

      final baseN = computeDragForceNewtons(
        cdaM2: result.initialBaseCdaM2 * baseYawPenalty,
      );
      final optN = computeDragForceNewtons(
        cdaM2: result.optimizedBaseCdaM2 * optYawPenalty,
      );

      samples.add(
        WindTunnelYawDragSample(
          yawDegrees: yaw,
          baselineDragNewtons: baseN,
          optimizedDragNewtons: optN,
        ),
      );
    }
    return samples;
  }

  /// Domyślna kadra 8 zawodników do samodzielnego uruchomienia ekranu obozu.
  static List<Rider> buildDefaultCampRoster() {
    Rider makeRider({
      required String id,
      required String firstName,
      required String lastName,
      required String nat,
      required RiderSpecialization spec,
      required RiderRole role,
      required double heightCm,
      required double weightKg,
      required int ftp,
      required int aero,
      required int tt,
      required int potential,
    }) {
      return Rider(
        id: id,
        firstName: firstName,
        lastName: lastName,
        nationalityIso: nat,
        birthDate: DateTime(1998, 5, 14),
        potential: potential,
        specialization: spec,
        physiology: RiderPhysiology(
          heightCm: heightCm,
          weightKg: weightKg,
          bodyFatPercentage: 7.4,
          ftpWatts: ftp,
          wPrimeJoules: 24500,
          vo2Max: 81.5,
          maxHr: 192,
          restingHr: 39,
          lactateThresholdHr: 174,
          recoveryRate: 85.0,
          glycogenCapacityGrams: 540.0,
        ),
        powerProfile: RiderPowerProfile(
          watts5s: (ftp * 3.1).round(),
          watts15s: (ftp * 2.55).round(),
          watts30s: (ftp * 2.05).round(),
          watts1m: (ftp * 1.65).round(),
          watts3m: (ftp * 1.25).round(),
          watts5m: (ftp * 1.16).round(),
          watts20m: (ftp * 1.05).round(),
          watts60m: ftp,
        ),
        skills: RiderSkills(
          cobbles: 72,
          descending: 78,
          bikeHandling: 79,
          aeroPositioning: aero,
          draftingEfficiency: 80,
          raceIq: 82,
          rainResistance: 75,
          heatTolerance: 76,
          timeTrialPositioning: tt,
        ),
        appearance: const RiderAppearance(
          faceShapeIndex: 1,
          skinToneHex: '#E0B59A',
          hairStyleIndex: 2,
          hairColorHex: '#3B2F2F',
          facialHairIndex: 0,
          glassesModelId: 'aero_shield',
          glassesLensColorHex: '#38BDF8',
          helmetModelId: 'tt_aero',
          shoeColorHex: '#FFFFFF',
          sockHeightProportion: 0.72,
          bodyBuildType: BodyBuildType.allRounder,
        ),
        contract: RiderContract(
          teamId: 'team_obsidian',
          role: role,
          monthlySalaryEur: 45000,
          signingBonusEur: 0,
          winBonusEur: 15000,
          releaseClauseEur: 1200000,
          contractEndYear: 2028,
          morale: 84.0,
          leaderLoyalty: 86.0,
          requiredRacesIds: const ['tour_de_france'],
        ),
        health: const RiderHealth(
          acuteTrainingLoad: 42.0,
          chronicTrainingLoad: 64.0,
        ),
        careerPointsUci: 1450,
      );
    }

    return [
      makeRider(
        id: 'wt_rider_1',
        firstName: 'Michał',
        lastName: 'Kowalski',
        nat: 'POL',
        spec: RiderSpecialization.timeTrialist,
        role: RiderRole.teamLeader,
        heightCm: 183,
        weightKg: 72,
        ftp: 445,
        aero: 84,
        tt: 88,
        potential: 91,
      ),
      makeRider(
        id: 'wt_rider_2',
        firstName: 'Lucas',
        lastName: 'Vermeulen',
        nat: 'BEL',
        spec: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        heightCm: 176,
        weightKg: 62,
        ftp: 412,
        aero: 77,
        tt: 76,
        potential: 93,
      ),
      makeRider(
        id: 'wt_rider_3',
        firstName: 'Matteo',
        lastName: 'Bellini',
        nat: 'ITA',
        spec: RiderSpecialization.classicCobbles,
        role: RiderRole.coLeader,
        heightCm: 185,
        weightKg: 76,
        ftp: 438,
        aero: 75,
        tt: 74,
        potential: 89,
      ),
      makeRider(
        id: 'wt_rider_4',
        firstName: 'Sander',
        lastName: 'De Vries',
        nat: 'NED',
        spec: RiderSpecialization.timeTrialist,
        role: RiderRole.superDomestique,
        heightCm: 188,
        weightKg: 75,
        ftp: 430,
        aero: 81,
        tt: 83,
        potential: 86,
      ),
      makeRider(
        id: 'wt_rider_5',
        firstName: 'Julien',
        lastName: 'Moreau',
        nat: 'FRA',
        spec: RiderSpecialization.puncher,
        role: RiderRole.coLeader,
        heightCm: 178,
        weightKg: 67,
        ftp: 405,
        aero: 71,
        tt: 67,
        potential: 88,
      ),
      makeRider(
        id: 'wt_rider_6',
        firstName: 'Jakub',
        lastName: 'Nowak',
        nat: 'POL',
        spec: RiderSpecialization.pureSprinter,
        role: RiderRole.sprinter,
        heightCm: 181,
        weightKg: 77,
        ftp: 418,
        aero: 73,
        tt: 63,
        potential: 87,
      ),
      makeRider(
        id: 'wt_rider_7',
        firstName: 'Henrik',
        lastName: 'Lindqvist',
        nat: 'SWE',
        spec: RiderSpecialization.domestiqueEngine,
        role: RiderRole.domestique,
        heightCm: 184,
        weightKg: 74,
        ftp: 398,
        aero: 69,
        tt: 68,
        potential: 81,
      ),
      makeRider(
        id: 'wt_rider_8',
        firstName: 'David',
        lastName: 'Alvarez',
        nat: 'ESP',
        spec: RiderSpecialization.pureClimber,
        role: RiderRole.superDomestique,
        heightCm: 171,
        weightKg: 58,
        ftp: 378,
        aero: 66,
        tt: 59,
        potential: 85,
      ),
    ];
  }
}

/// Ekran Grudniowego Obozu Aerodynamicznego w tunelu i na welodromie.
///
/// Umożliwia interaktywny dobór do 6 zawodników do sesji testowych, wybór obiektu,
/// testowanie 3 pozycji czasowych, kasków oraz kombinezonów, podgląd pomiarów oporu
/// aerodynamicznego w Newtonach przy 50 km/h oraz analizę raportu zaoszczędzonych watów.
class WinterWindTunnelCampScreen extends ConsumerStatefulWidget {
  final int seasonYear;
  final int teamBudgetEur;
  final List<Rider>? initialRoster;
  final bool isReadOnly;
  final ValueChanged<PreSeasonWindTunnelCampOutcome>? onCampCompleted;

  const WinterWindTunnelCampScreen({
    super.key,
    this.seasonYear = 2027,
    this.teamBudgetEur = 250000,
    this.initialRoster,
    this.isReadOnly = false,
    this.onCampCompleted,
  });

  @override
  ConsumerState<WinterWindTunnelCampScreen> createState() =>
      _WinterWindTunnelCampScreenState();
}

class _WinterWindTunnelCampScreenState
    extends ConsumerState<WinterWindTunnelCampScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _airflowController;
  String _rosterQuery = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _airflowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      _initialized = true;
      final current = ref.read(preSeasonWindTunnelCampProvider);
      if (current.roster.isEmpty) {
        final roster = widget.initialRoster ??
            WinterWindTunnelCampTelemetry.buildDefaultCampRoster();
        ref.read(preSeasonWindTunnelCampProvider.notifier).initializeCamp(
              seasonYear: widget.seasonYear,
              teamBudgetEur: widget.teamBudgetEur,
              roster: roster,
            );
      }
    });
  }

  @override
  void dispose() {
    _airflowController.dispose();
    super.dispose();
  }

  void _resetCamp() {
    if (widget.isReadOnly) return;
    final roster = widget.initialRoster ??
        WinterWindTunnelCampTelemetry.buildDefaultCampRoster();
    ref.read(preSeasonWindTunnelCampProvider.notifier).initializeCamp(
          seasonYear: widget.seasonYear,
          teamBudgetEur: widget.teamBudgetEur,
          roster: roster,
        );
  }

  void _finalizeCamp() {
    if (widget.isReadOnly) return;
    final outcome = ref
        .read(preSeasonWindTunnelCampProvider.notifier)
        .finalizeCampAndApplyCda();
    if (outcome != null) {
      widget.onCampCompleted?.call(outcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preSeasonWindTunnelCampProvider);
    final notifier = ref.read(preSeasonWindTunnelCampProvider.notifier);
    final totalCost = notifier.currentTotalCostEur;
    final previewResults = notifier.evaluateAllSelectedPreview();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            final isDesktop = constraints.maxWidth >= 1200;
            final horizontalPad = isMobile ? 12.0 : (isDesktop ? 28.0 : 20.0);

            return Column(
              children: [
                _CampTopBar(
                  state: state,
                  totalCostEur: totalCost,
                  isMobile: isMobile,
                  isReadOnly: widget.isReadOnly,
                  canPop: Navigator.of(context).canPop(),
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                if (widget.isReadOnly)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(
                      horizontalPad,
                      8,
                      horizontalPad,
                      0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amberWarning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.amberWarning.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppColors.amberWarning,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tryb tylko do odczytu — podgląd pomiarów tunelu aerodynamicznego bez możliwości zapisu zmian.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.amberWarning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      10,
                      horizontalPad,
                      0,
                    ),
                    child: _CampErrorBanner(message: state.errorMessage!),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPad,
                      vertical: 16,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: switch (state.phase) {
                        WindTunnelCampPhase.facilityAndSquadSelection =>
                          _FacilityAndRiderSelectionStep(
                            key: const ValueKey('step_selection'),
                            state: state,
                            isMobile: isMobile,
                            isDesktop: isDesktop,
                            isReadOnly: widget.isReadOnly,
                            rosterQuery: _rosterQuery,
                            onQueryChanged: (q) =>
                                setState(() => _rosterQuery = q),
                            onSelectFacility: widget.isReadOnly
                                ? null
                                : notifier.selectFacility,
                            onToggleRider: widget.isReadOnly
                                ? null
                                : notifier.toggleKeyRider,
                            onProceed: widget.isReadOnly
                                ? null
                                : notifier.proceedToTestingPhase,
                          ),
                        WindTunnelCampPhase.tunnelAndTrackTesting =>
                          _TunnelSessionsWorkbenchStep(
                            key: const ValueKey('step_testing'),
                            state: state,
                            previewResults: previewResults,
                            totalCostEur: totalCost,
                            airflowAnimation: _airflowController,
                            isMobile: isMobile,
                            isDesktop: isDesktop,
                            isReadOnly: widget.isReadOnly,
                            onSelectActiveRider: notifier.setActiveRider,
                            onSelectPosture: widget.isReadOnly
                                ? null
                                : notifier.setRiderPosture,
                            onSelectHelmet: widget.isReadOnly
                                ? null
                                : notifier.setRiderHelmet,
                            onSelectSkinsuit: widget.isReadOnly
                                ? null
                                : notifier.setRiderSkinsuit,
                            onValidateRiderTrack: widget.isReadOnly
                                ? null
                                : notifier.runTrackValidationForRider,
                            onValidateAllTrack: widget.isReadOnly
                                ? null
                                : notifier.runTrackValidationForAllSelected,
                            onBackToSelection: widget.isReadOnly
                                ? null
                                : notifier.backToFacilitySelection,
                            onFinalizeCamp:
                                widget.isReadOnly ? null : _finalizeCamp,
                          ),
                        WindTunnelCampPhase.completed =>
                          _WattsSavedFinalReportStep(
                            key: const ValueKey('step_report'),
                            state: state,
                            isMobile: isMobile,
                            isDesktop: isDesktop,
                            isReadOnly: widget.isReadOnly,
                            onResetCamp: widget.isReadOnly ? null : _resetCamp,
                          ),
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CampTopBar extends StatelessWidget {
  final PreSeasonWindTunnelCampState state;
  final int totalCostEur;
  final bool isMobile;
  final bool isReadOnly;
  final bool canPop;
  final VoidCallback onBack;

  const _CampTopBar({
    required this.state,
    required this.totalCostEur,
    required this.isMobile,
    required this.isReadOnly,
    required this.canPop,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final overBudget = totalCostEur > state.teamBudgetEur;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (canPop) ...[
                _IconActionChip(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Wróć',
                  onTap: onBack,
                ),
                const SizedBox(width: 10),
              ],
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentBlue.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.air_rounded,
                  color: AppColors.accentBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grudniowy Obóz Aerodynamiczny ${state.seasonYear}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.selectedFacility.label} • Pomiary 50 km/h (N) & Raport Watów',
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
              if (!isMobile) ...[
                const SizedBox(width: 12),
                _StatPill(
                  label: 'Budżet',
                  value: Formatters.formatCurrency(state.teamBudgetEur),
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  label: 'Koszt sesji',
                  value: Formatters.formatCurrency(totalCostEur),
                  color: overBudget
                      ? AppColors.crimsonAlert
                      : AppColors.statusSuccess,
                ),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(
                  label: 'Budżet',
                  value: Formatters.formatCurrency(state.teamBudgetEur),
                  color: AppColors.goldAccent,
                ),
                _StatPill(
                  label: 'Koszt',
                  value: Formatters.formatCurrency(totalCostEur),
                  color: overBudget
                      ? AppColors.crimsonAlert
                      : AppColors.statusSuccess,
                ),
                _StatPill(
                  label: 'Kadra',
                  value:
                      '${state.selectedRiderIds.length}/${PreSeasonWindTunnelCampEvent.maxKeyRiders}',
                  color: AppColors.accentBlue,
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _PhaseStepperRow(currentPhase: state.phase, isMobile: isMobile),
        ],
      ),
    );
  }
}

class _PhaseStepperRow extends StatelessWidget {
  final WindTunnelCampPhase currentPhase;
  final bool isMobile;

  const _PhaseStepperRow({
    required this.currentPhase,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        WindTunnelCampPhase.facilityAndSquadSelection,
        '1. Dobór Kadry',
        Icons.groups_rounded,
      ),
      (
        WindTunnelCampPhase.tunnelAndTrackTesting,
        '2. Pomiary 50 km/h (N)',
        Icons.speed_rounded,
      ),
      (
        WindTunnelCampPhase.completed,
        '3. Raport Watów',
        Icons.analytics_rounded,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _PhaseStepChip(
              label: steps[i].$2,
              icon: steps[i].$3,
              isActive: currentPhase == steps[i].$1,
              isDone: currentPhase.index > steps[i].$1.index,
              compact: isMobile,
            ),
          ),
          if (i < steps.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _PhaseStepChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDone;
  final bool compact;

  const _PhaseStepChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDone,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.goldAccent
        : (isDone ? AppColors.statusSuccess : AppColors.textSecondary);
    final bg = isActive
        ? AppColors.goldAccent.withValues(alpha: 0.14)
        : (isDone
            ? AppColors.statusSuccess.withValues(alpha: 0.10)
            : AppColors.surfaceLight);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive || isDone
              ? color.withValues(alpha: 0.55)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isDone ? Icons.check_circle_rounded : icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: compact ? 11 : 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityAndRiderSelectionStep extends StatelessWidget {
  final PreSeasonWindTunnelCampState state;
  final bool isMobile;
  final bool isDesktop;
  final bool isReadOnly;
  final String rosterQuery;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<WindTunnelFacility>? onSelectFacility;
  final ValueChanged<String>? onToggleRider;
  final VoidCallback? onProceed;

  const _FacilityAndRiderSelectionStep({
    super.key,
    required this.state,
    required this.isMobile,
    required this.isDesktop,
    required this.isReadOnly,
    required this.rosterQuery,
    required this.onQueryChanged,
    required this.onSelectFacility,
    required this.onToggleRider,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final filteredRoster = state.roster.where((r) {
      if (rosterQuery.trim().isEmpty) return true;
      final q = rosterQuery.toLowerCase();
      return r.fullName.toLowerCase().contains(q) ||
          r.specialization.displayName.toLowerCase().contains(q);
    }).toList(growable: false);

    final facilityPanel = _CampSectionCard(
      title: 'Wybór Tunelu Aerodynamicznego',
      subtitle: 'Precyzja obiektu skaluje redukcję CdA i zakres testów Yaw',
      icon: Icons.science_rounded,
      accentColor: AppColors.accentBlue,
      child: Column(
        children: [
          for (final facility in WindTunnelFacility.values) ...[
            _InteractiveCampOptionCard(
              isSelected: state.selectedFacility == facility,
              isDisabled: isReadOnly,
              accentColor: AppColors.accentBlue,
              onTap: onSelectFacility == null
                  ? null
                  : () => onSelectFacility!(facility),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${facility.location} • Yaw ±${facility.maxYawAngleDeg}°',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          facility.specialtyDescription,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(facility.baseRentalCostEur),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.goldAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Precyzja ×${facility.precisionMultiplier.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (facility != WindTunnelFacility.values.last)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );

    final squadPanel = _CampSectionCard(
      title:
          'Dobór Zawodników do Sesji (${state.selectedRiderIds.length}/${PreSeasonWindTunnelCampEvent.maxKeyRiders})',
      subtitle:
          'Wybierz od 1 do 6 kluczowych kolarzy na grudniowe testy w tunelu',
      icon: Icons.directions_bike_rounded,
      accentColor: AppColors.goldAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            enabled: !isReadOnly,
            onChanged: onQueryChanged,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Szukaj zawodnika lub specjalizacji...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
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
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (filteredRoster.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Brak zawodników pasujących do filtra.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            for (final rider in filteredRoster) ...[
              _RiderSelectionRow(
                rider: rider,
                isSelected: state.selectedRiderIds.contains(rider.id),
                isDisabled: isReadOnly,
                onTap: onToggleRider == null
                    ? null
                    : () => onToggleRider!(rider.id),
              ),
              if (rider != filteredRoster.last) const SizedBox(height: 8),
            ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _CampPrimaryButton(
              label:
                  'Rozpocznij Sesje Testowe (${state.selectedRiderIds.length} kolarzy)',
              icon: Icons.play_arrow_rounded,
              onPressed: onProceed,
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: facilityPanel),
          const SizedBox(width: 18),
          Expanded(flex: 6, child: squadPanel),
        ],
      );
    }

    return Column(
      children: [
        facilityPanel,
        const SizedBox(height: 16),
        squadPanel,
      ],
    );
  }
}

class _RiderSelectionRow extends StatelessWidget {
  final Rider rider;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _RiderSelectionRow({
    required this.rider,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseCda = PreSeasonWindTunnelCampEvent.computeBaselineCdaM2(rider);
    final baseDragN =
        WinterWindTunnelCampTelemetry.computeDragForceNewtons(cdaM2: baseCda);

    return _InteractiveCampOptionCard(
      isSelected: isSelected,
      isDisabled: isDisabled,
      accentColor: AppColors.goldAccent,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            size: 20,
            color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rider.fullName} (${rider.nationalityIso})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rider.specialization.displayName} • Aero ${rider.skills.aeroPositioning} • TT ${rider.skills.timeTrialPositioning}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${baseDragN.toStringAsFixed(1)} N',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.accentBlue,
                ),
              ),
              Text(
                'CdA ${baseCda.toStringAsFixed(4)} m²',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
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

class _TunnelSessionsWorkbenchStep extends StatelessWidget {
  final PreSeasonWindTunnelCampState state;
  final List<RiderAeroTestResult> previewResults;
  final int totalCostEur;
  final Animation<double> airflowAnimation;
  final bool isMobile;
  final bool isDesktop;
  final bool isReadOnly;
  final ValueChanged<String> onSelectActiveRider;
  final void Function(String riderId, TimeTrialPostureOption posture)?
      onSelectPosture;
  final void Function(String riderId, AeroHelmetOption helmet)? onSelectHelmet;
  final void Function(String riderId, SkinsuitOption skinsuit)?
      onSelectSkinsuit;
  final ValueChanged<String>? onValidateRiderTrack;
  final VoidCallback? onValidateAllTrack;
  final VoidCallback? onBackToSelection;
  final VoidCallback? onFinalizeCamp;

  const _TunnelSessionsWorkbenchStep({
    super.key,
    required this.state,
    required this.previewResults,
    required this.totalCostEur,
    required this.airflowAnimation,
    required this.isMobile,
    required this.isDesktop,
    required this.isReadOnly,
    required this.onSelectActiveRider,
    required this.onSelectPosture,
    required this.onSelectHelmet,
    required this.onSelectSkinsuit,
    required this.onValidateRiderTrack,
    required this.onValidateAllTrack,
    required this.onBackToSelection,
    required this.onFinalizeCamp,
  });

  @override
  Widget build(BuildContext context) {
    final activeId = state.activeRiderId ??
        (state.selectedRiderIds.isNotEmpty ? state.selectedRiderIds.first : '');
    final activeRider =
        state.roster.where((r) => r.id == activeId).firstOrNull;
    final activeConfig = state.configsByRiderId[activeId] ??
        WindTunnelRiderTestConfig(riderId: activeId);
    final activeResult =
        previewResults.where((r) => r.riderId == activeId).firstOrNull;

    final totalWattsSaved50 = previewResults.fold<double>(
      0.0,
      (sum, r) => sum + r.wattsSavedAt50Kmh,
    );
    final totalDragDropN = previewResults.fold<double>(
      0.0,
      (sum, r) =>
          sum +
          WinterWindTunnelCampTelemetry.computeDragReductionNewtonsAt50Kmh(r),
    );

    final riderTabs = _CampSectionCard(
      title: 'Sesje Testowe Zawodników',
      subtitle: 'Wybierz zawodnika, aby dostroić pozycję TT, kask i kombinezon',
      icon: Icons.tune_rounded,
      accentColor: AppColors.goldAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in state.selectedRiderIds)
                _RiderSessionChip(
                  rider: state.roster.where((r) => r.id == id).firstOrNull,
                  result:
                      previewResults.where((r) => r.riderId == id).firstOrNull,
                  isActive: id == activeId,
                  onTap: () => onSelectActiveRider(id),
                ),
            ],
          ),
          if (activeRider != null && activeResult != null) ...[
            const SizedBox(height: 16),
            _ActiveRiderConfigBlock(
              rider: activeRider,
              config: activeConfig,
              result: activeResult,
              isReadOnly: isReadOnly,
              onSelectPosture: onSelectPosture == null
                  ? null
                  : (p) => onSelectPosture!(activeId, p),
              onSelectHelmet: onSelectHelmet == null
                  ? null
                  : (h) => onSelectHelmet!(activeId, h),
              onSelectSkinsuit: onSelectSkinsuit == null
                  ? null
                  : (s) => onSelectSkinsuit!(activeId, s),
              onValidateTrack: onValidateRiderTrack == null
                  ? null
                  : () => onValidateRiderTrack!(activeId),
            ),
          ],
        ],
      ),
    );

    final telemetryPanel = Column(
      children: [
        if (activeResult != null)
          _CampSectionCard(
            title: 'Pomiary Oporu w Tunelu przy 50 km/h',
            subtitle:
                'Wizualizacja strug powietrza i siły oporu $referenceLabel w Newtonach',
            icon: Icons.speed_rounded,
            accentColor: AppColors.cyanAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: isMobile ? 130 : 150,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      painter: WindTunnelAirflowPainter(
                        posture: activeConfig.testedPosture,
                        helmet: activeConfig.testedHelmet,
                        skinsuit: activeConfig.testedSkinsuit,
                        trackValidated: activeConfig.trackValidationCompleted,
                        cdaReductionPercent: activeResult.cdaReductionPercent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _DragNewtonsTelemetryGrid(
                  result: activeResult,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Krzywa oporu przy 50 km/h (N) w funkcji kąta wiatru (Yaw)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: WindTunnelDragNewtonsChartPainter(
                      samples: WinterWindTunnelCampTelemetry.buildYawDragCurve(
                        result: activeResult,
                        facility: state.selectedFacility,
                      ),
                    ),
                  ),
                ),
                if (activeResult.sustainabilityWarning != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.amberWarning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.amberWarning.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.amberWarning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activeResult.sustainabilityWarning!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.amberWarning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        _CampSectionCard(
          title: 'Podsumowanie Zaoszczędzonych Watów (Live)',
          subtitle:
              'Łączny zysk zespołu przed zatwierdzeniem obozu (${previewResults.length} kolarzy)',
          icon: Icons.bolt_rounded,
          accentColor: AppColors.statusSuccess,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _KpiTile(
                      label: 'Zaoszczędzone Waty (50 km/h)',
                      value: '+${totalWattsSaved50.toStringAsFixed(1)} W',
                      accentColor: AppColors.statusSuccess,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiTile(
                      label: 'Redukcja Oporu (50 km/h)',
                      value: '-${totalDragDropN.toStringAsFixed(2)} N',
                      accentColor: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _CampSecondaryButton(
                    label: 'Zmień Kadrę / Tunel',
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBackToSelection,
                  ),
                  _CampSecondaryButton(
                    label: 'Waliduj Wszystkich na Torze',
                    icon: Icons.verified_rounded,
                    onPressed: onValidateAllTrack,
                  ),
                  _CampPrimaryButton(
                    label:
                        'Zatwierdź Obóz (${Formatters.formatCurrency(totalCostEur)})',
                    icon: Icons.check_circle_rounded,
                    onPressed: onFinalizeCamp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: riderTabs),
          const SizedBox(width: 18),
          Expanded(flex: 6, child: telemetryPanel),
        ],
      );
    }

    return Column(
      children: [
        telemetryPanel,
        const SizedBox(height: 16),
        riderTabs,
      ],
    );
  }

  static const String referenceLabel = '(50 km/h)';
}

class _RiderSessionChip extends StatelessWidget {
  final Rider? rider;
  final RiderAeroTestResult? result;
  final bool isActive;
  final VoidCallback onTap;

  const _RiderSessionChip({
    required this.rider,
    required this.result,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (rider == null) return const SizedBox.shrink();
    final watts = result?.wattsSavedAt50Kmh ?? 0.0;

    return _InteractiveCampOptionCard(
      isSelected: isActive,
      isDisabled: false,
      accentColor: AppColors.goldAccent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (result?.trackValidated ?? false) ...[
            const Icon(
              Icons.verified_rounded,
              size: 14,
              color: AppColors.statusSuccess,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            rider!.lastName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.goldAccent : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '+${watts.toStringAsFixed(1)}W',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.statusSuccess,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveRiderConfigBlock extends StatelessWidget {
  final Rider rider;
  final WindTunnelRiderTestConfig config;
  final RiderAeroTestResult result;
  final bool isReadOnly;
  final ValueChanged<TimeTrialPostureOption>? onSelectPosture;
  final ValueChanged<AeroHelmetOption>? onSelectHelmet;
  final ValueChanged<SkinsuitOption>? onSelectSkinsuit;
  final VoidCallback? onValidateTrack;

  const _ActiveRiderConfigBlock({
    required this.rider,
    required this.config,
    required this.result,
    required this.isReadOnly,
    required this.onSelectPosture,
    required this.onSelectHelmet,
    required this.onSelectSkinsuit,
    required this.onValidateTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${rider.fullName} — ${rider.specialization.displayName}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _CampSecondaryButton(
              label: config.trackValidationCompleted
                  ? 'Tor Zweryfikowany (+8%)'
                  : 'Waliduj na Torze',
              icon: config.trackValidationCompleted
                  ? Icons.verified_rounded
                  : Icons.track_changes_rounded,
              onPressed:
                  config.trackValidationCompleted ? null : onValidateTrack,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          '1. Pozycja Czasowa (TT)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.goldAccent,
          ),
        ),
        const SizedBox(height: 8),
        for (final posture in TimeTrialPostureOption.values) ...[
          _InteractiveCampOptionCard(
            isSelected: config.testedPosture == posture,
            isDisabled: isReadOnly,
            accentColor: AppColors.goldAccent,
            onTap: onSelectPosture == null
                ? null
                : () => onSelectPosture!(posture),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        posture.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        posture.biomechanicsNote,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '-${(posture.baseCdaReductionM2 * 1000).toStringAsFixed(1)}×10⁻³',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.accentBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        const Text(
          '2. Kask Aerodynamiczny',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.accentBlue,
          ),
        ),
        const SizedBox(height: 8),
        for (final helmet in AeroHelmetOption.values) ...[
          _InteractiveCampOptionCard(
            isSelected: config.testedHelmet == helmet,
            isDisabled: isReadOnly,
            accentColor: AppColors.accentBlue,
            onTap:
                onSelectHelmet == null ? null : () => onSelectHelmet!(helmet),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        helmet.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        helmet.aeroProfileNote,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  helmet.costPerRiderEur == 0
                      ? 'Baza'
                      : Formatters.formatCurrency(helmet.costPerRiderEur),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.goldAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        const Text(
          '3. Kombinezon Czasowy (Skinsuit)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.statusSuccess,
          ),
        ),
        const SizedBox(height: 8),
        for (final suit in SkinsuitOption.values) ...[
          _InteractiveCampOptionCard(
            isSelected: config.testedSkinsuit == suit,
            isDisabled: isReadOnly,
            accentColor: AppColors.statusSuccess,
            onTap:
                onSelectSkinsuit == null ? null : () => onSelectSkinsuit!(suit),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suit.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        suit.fabricNote,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  suit.costPerRiderEur == 0
                      ? 'Baza'
                      : Formatters.formatCurrency(suit.costPerRiderEur),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.goldAccent,
                  ),
                ),
              ],
            ),
          ),
          if (suit != SkinsuitOption.values.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DragNewtonsTelemetryGrid extends StatelessWidget {
  final RiderAeroTestResult result;
  final bool isMobile;

  const _DragNewtonsTelemetryGrid({
    required this.result,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final baseN = WinterWindTunnelCampTelemetry.computeDragForceNewtons(
      cdaM2: result.initialBaseCdaM2,
    );
    final optN = WinterWindTunnelCampTelemetry.computeDragForceNewtons(
      cdaM2: result.optimizedBaseCdaM2,
    );
    final deltaN = math.max(0.0, baseN - optN);

    final tiles = [
      _KpiTile(
        label: 'Opór Bazowy (50 km/h)',
        value: '${baseN.toStringAsFixed(2)} N',
        accentColor: AppColors.textSecondary,
      ),
      _KpiTile(
        label: 'Opór Po Optymalizacji',
        value: '${optN.toStringAsFixed(2)} N',
        accentColor: AppColors.cyanAccent,
      ),
      _KpiTile(
        label: 'Redukcja Oporu (ΔF)',
        value: '-${deltaN.toStringAsFixed(2)} N',
        accentColor: AppColors.accentBlue,
      ),
      _KpiTile(
        label: 'Zaoszczędzone Waty (50 km/h)',
        value: '+${result.wattsSavedAt50Kmh.toStringAsFixed(1)} W',
        accentColor: AppColors.statusSuccess,
      ),
      _KpiTile(
        label: 'CdA Bazowe → Nowe',
        value:
            '${result.initialBaseCdaM2.toStringAsFixed(3)} → ${result.optimizedBaseCdaM2.toStringAsFixed(3)} m²',
        accentColor: AppColors.goldAccent,
      ),
      _KpiTile(
        label: 'Zysk na 40 km ITT',
        value: '-${result.estimated40KmTtGainSeconds.toStringAsFixed(1)} s',
        accentColor: AppColors.statusSuccess,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < tiles.length; i += 2) ...[
            Row(
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 8),
                Expanded(child: tiles[i + 1]),
              ],
            ),
            if (i + 2 < tiles.length) const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 8),
            Expanded(child: tiles[1]),
            const SizedBox(width: 8),
            Expanded(child: tiles[2]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: tiles[3]),
            const SizedBox(width: 8),
            Expanded(child: tiles[4]),
            const SizedBox(width: 8),
            Expanded(child: tiles[5]),
          ],
        ),
      ],
    );
  }
}

class _WattsSavedFinalReportStep extends StatelessWidget {
  final PreSeasonWindTunnelCampState state;
  final bool isMobile;
  final bool isDesktop;
  final bool isReadOnly;
  final VoidCallback? onResetCamp;

  const _WattsSavedFinalReportStep({
    super.key,
    required this.state,
    required this.isMobile,
    required this.isDesktop,
    required this.isReadOnly,
    required this.onResetCamp,
  });

  @override
  Widget build(BuildContext context) {
    final outcome = state.outcome;
    if (outcome == null) {
      return const Center(
        child: Text(
          'Brak danych raportu końcowego.',
          style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'),
        ),
      );
    }

    final totalDragDropN = outcome.riderResults.fold<double>(
      0.0,
      (sum, r) =>
          sum +
          WinterWindTunnelCampTelemetry.computeDragReductionNewtonsAt50Kmh(r),
    );
    final avgDragDropN = outcome.riderResults.isEmpty
        ? 0.0
        : totalDragDropN / outcome.riderResults.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CampSectionCard(
          title: 'Raport Zaoszczędzonych Watów — Sezon ${outcome.seasonYear}',
          subtitle: outcome.summaryHeadline,
          icon: Icons.emoji_events_rounded,
          accentColor: AppColors.goldAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: isMobile ? double.infinity : 230,
                    child: _KpiTile(
                      label: 'Suma Zaoszczędzonych Watów (50 km/h)',
                      value:
                          '+${outcome.totalWattsSavedAt50Kmh.toStringAsFixed(1)} W',
                      accentColor: AppColors.statusSuccess,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 230,
                    child: _KpiTile(
                      label: 'Śr. Redukcja Oporu (50 km/h)',
                      value: '-${avgDragDropN.toStringAsFixed(2)} N',
                      accentColor: AppColors.accentBlue,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 230,
                    child: _KpiTile(
                      label: 'Średnia Redukcja CdA',
                      value:
                          '-${(outcome.averageCdaReductionM2 * 1000).toStringAsFixed(1)}×10⁻³ m²',
                      accentColor: AppColors.goldAccent,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 230,
                    child: _KpiTile(
                      label: 'Koszt Całkowity Obozu',
                      value: Formatters.formatCurrency(outcome.totalCostEur),
                      accentColor: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final res in outcome.riderResults) ...[
                _FinalRiderReportRow(result: res, isMobile: isMobile),
                if (res != outcome.riderResults.last)
                  const SizedBox(height: 10),
              ],
              if (!isReadOnly && onResetCamp != null) ...[
                const SizedBox(height: 16),
                _CampSecondaryButton(
                  label: 'Nowa Symulacja Obozu',
                  icon: Icons.refresh_rounded,
                  onPressed: onResetCamp,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FinalRiderReportRow extends StatelessWidget {
  final RiderAeroTestResult result;
  final bool isMobile;

  const _FinalRiderReportRow({
    required this.result,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final baseN = WinterWindTunnelCampTelemetry.computeDragForceNewtons(
      cdaM2: result.initialBaseCdaM2,
    );
    final optN = WinterWindTunnelCampTelemetry.computeDragForceNewtons(
      cdaM2: result.optimizedBaseCdaM2,
    );
    final deltaN = math.max(0.0, baseN - optN);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.riderName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${result.wattsSavedAt50Kmh.toStringAsFixed(1)} W @ 50 km/h',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.statusSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${result.chosenPosture.shortTag} • ${result.chosenHelmet.label} • ${result.chosenSkinsuit.label}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Text(
                'Opór 50 km/h: ${baseN.toStringAsFixed(2)} N → ${optN.toStringAsFixed(2)} N (-${deltaN.toStringAsFixed(2)} N)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.cyanAccent,
                ),
              ),
              Text(
                '40 km ITT: -${result.estimated40KmTtGainSeconds.toStringAsFixed(1)} s',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
              Text(
                'Trwały bonus: +${result.aeroSkillGain} Aero / +${result.ttSkillGain} TT',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rysuje wykres porównawczy oporu aerodynamicznego w Newtonach przy 50 km/h
/// w zależności od kąta natarcia wiatru pozornego (Yaw).
class WindTunnelDragNewtonsChartPainter extends CustomPainter {
  final List<WindTunnelYawDragSample> samples;

  const WindTunnelDragNewtonsChartPainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.surfaceLight;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bgPaint,
    );

    if (samples.length < 2) return;

    const leftPad = 42.0;
    const rightPad = 14.0;
    const topPad = 14.0;
    const bottomPad = 24.0;
    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      math.max(10.0, size.width - leftPad - rightPad),
      math.max(10.0, size.height - topPad - bottomPad),
    );

    double minN = double.infinity;
    double maxN = 0.0;
    for (final s in samples) {
      minN = math.min(minN, s.optimizedDragNewtons);
      maxN = math.max(maxN, s.baselineDragNewtons);
    }
    minN = (minN - 1.5).clamp(0.0, double.infinity);
    maxN = maxN + 1.5;
    final rangeN = math.max(1.0, maxN - minN);

    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final t = i / 3.0;
      final y = chartRect.bottom - t * chartRect.height;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      final labelVal = minN + t * rangeN;
      final tp = TextPainter(
        text: TextSpan(
          text: '${labelVal.toStringAsFixed(0)}N',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(6, y - tp.height / 2));
    }

    final basePath = Path();
    final optPath = Path();

    for (int i = 0; i < samples.length; i++) {
      final t = i / (samples.length - 1);
      final x = chartRect.left + t * chartRect.width;
      final yBase = chartRect.bottom -
          ((samples[i].baselineDragNewtons - minN) / rangeN) * chartRect.height;
      final yOpt = chartRect.bottom -
          ((samples[i].optimizedDragNewtons - minN) / rangeN) *
              chartRect.height;

      if (i == 0) {
        basePath.moveTo(x, yBase);
        optPath.moveTo(x, yOpt);
      } else {
        basePath.lineTo(x, yBase);
        optPath.lineTo(x, yOpt);
      }

      if (i == 0 || i == samples.length ~/ 2 || i == samples.length - 1) {
        final yawTp = TextPainter(
          text: TextSpan(
            text: '${samples[i].yawDegrees}°',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        yawTp.paint(
          canvas,
          Offset(x - yawTp.width / 2, chartRect.bottom + 5),
        );
      }
    }

    final basePaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final optPaint = Paint()
      ..color = AppColors.cyanAccent
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;

    canvas.drawPath(basePath, basePaint);
    canvas.drawPath(optPath, optPaint);
  }

  @override
  bool shouldRepaint(covariant WindTunnelDragNewtonsChartPainter oldDelegate) {
    return oldDelegate.samples != samples;
  }
}

class _CampSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const _CampSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InteractiveCampOptionCard extends StatefulWidget {
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Widget child;

  const _InteractiveCampOptionCard({
    required this.isSelected,
    required this.isDisabled,
    required this.accentColor,
    this.padding = const EdgeInsets.all(12),
    required this.onTap,
    required this.child,
  });

  @override
  State<_InteractiveCampOptionCard> createState() =>
      _InteractiveCampOptionCardState();
}

class _InteractiveCampOptionCardState
    extends State<_InteractiveCampOptionCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? widget.accentColor.withValues(alpha: 0.14)
        : (_isHovered
            ? AppColors.surfaceLight.withValues(alpha: 0.85)
            : AppColors.surfaceLight);
    final border = widget.isSelected || _isFocused
        ? widget.accentColor
        : (_isHovered
            ? widget.accentColor.withValues(alpha: 0.5)
            : AppTheme.borderColor);

    return Opacity(
      opacity: widget.isDisabled ? 0.55 : 1.0,
      child: FocusableActionDetector(
        enabled: !widget.isDisabled && widget.onTap != null,
        onShowFocusHighlight: (f) => setState(() => _isFocused = f),
        onShowHoverHighlight: (h) => setState(() => _isHovered = h),
        child: InkWell(
          onTap: widget.isDisabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
                width: widget.isSelected || _isFocused ? 1.4 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconActionChip extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionChip({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _CampErrorBanner extends StatelessWidget {
  final String message;

  const _CampErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 17,
            color: AppColors.crimsonAlert,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.crimsonAlert,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _CampPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.surfaceLight,
        disabledForegroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CampSecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _CampSecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppTheme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
