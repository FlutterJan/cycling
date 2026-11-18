import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/team_esg_sustainability_and_green_fleet_model.dart';

/// Zakładki ekranu zarządzania flotą EV/wodorową i bilansem ESG drużyny.
enum EsgSustainabilityFleetTab {
  fleet('Flota EV/FCEV', Icons.electric_car_rounded),
  carbonLedger('Bilans CO₂ & Offset', Icons.co2_rounded),
  convoyAndInfra('Konwój & OZE', Icons.ev_station_rounded),
  greenSponsors('Zieloni Sponsorzy', Icons.eco_rounded);

  const EsgSustainabilityFleetTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Katalog gotowych pojazdów bezemisyjnych (EV / FCEV) i hybrydowych do zakupu lub wymiany.
class EsgVehicleCatalog {
  EsgVehicleCatalog._();

  static List<TeamFleetVehicle> buildPurchaseCatalog({int sequenceSeed = 1}) {
    final String suffix = sequenceSeed.toString();
    return [
      TeamFleetVehicle(
        id: 'cat_ds_taycan_$suffix',
        name: 'Porsche Taycan Cross Turismo DS',
        vehicleType: FleetVehicleType.directorSportifCar,
        powertrain: PowertrainType.batteryElectric,
        batteryCapacityKwh: 105.0,
        wltpRangeKm: 610.0,
        co2GramsPerKm: 0.0,
        purchaseCostEur: 112000.0,
        annualMaintenanceEur: 4200.0,
        conditionPercent: 100.0,
        odometerKm: 0.0,
        isActiveInRaceConvoy: true,
        assignedRoleLabel: 'DS Car #1 (BEV)',
      ),
      TeamFleetVehicle(
        id: 'cat_mech_mirai_$suffix',
        name: 'Toyota Mirai FCEV Support',
        vehicleType: FleetVehicleType.mechanicSupportCar,
        powertrain: PowertrainType.hydrogenFuelCell,
        batteryCapacityKwh: 1.2,
        wltpRangeKm: 650.0,
        co2GramsPerKm: 0.0,
        purchaseCostEur: 78000.0,
        annualMaintenanceEur: 5100.0,
        conditionPercent: 100.0,
        odometerKm: 0.0,
        isActiveInRaceConvoy: true,
        assignedRoleLabel: 'Mechanic FCEV',
      ),
      TeamFleetVehicle(
        id: 'cat_bus_etourismo_$suffix',
        name: 'Mercedes eTourismo Team Coach',
        vehicleType: FleetVehicleType.teamCoachBus,
        powertrain: PowertrainType.batteryElectric,
        batteryCapacityKwh: 520.0,
        wltpRangeKm: 480.0,
        co2GramsPerKm: 0.0,
        purchaseCostEur: 540000.0,
        annualMaintenanceEur: 14000.0,
        conditionPercent: 100.0,
        odometerKm: 0.0,
        isActiveInRaceConvoy: true,
        assignedRoleLabel: 'Zero-Emission Bus',
      ),
      TeamFleetVehicle(
        id: 'cat_truck_fcev_$suffix',
        name: 'Hyundai XCIENT FCEV Cargo Truck',
        vehicleType: FleetVehicleType.equipmentCargoTruck,
        powertrain: PowertrainType.hydrogenFuelCell,
        batteryCapacityKwh: 72.0,
        wltpRangeKm: 560.0,
        co2GramsPerKm: 0.0,
        purchaseCostEur: 390000.0,
        annualMaintenanceEur: 12500.0,
        conditionPercent: 100.0,
        odometerKm: 0.0,
        isActiveInRaceConvoy: false,
        assignedRoleLabel: 'Hydrogen Service Truck',
      ),
      TeamFleetVehicle(
        id: 'cat_van_nexo_$suffix',
        name: 'Hyundai Nexo FCEV Medical & Kitchen',
        vehicleType: FleetVehicleType.medicalAndKitchenVan,
        powertrain: PowertrainType.hydrogenFuelCell,
        batteryCapacityKwh: 1.6,
        wltpRangeKm: 665.0,
        co2GramsPerKm: 0.0,
        purchaseCostEur: 86000.0,
        annualMaintenanceEur: 4800.0,
        conditionPercent: 100.0,
        odometerKm: 0.0,
        isActiveInRaceConvoy: true,
        assignedRoleLabel: 'Medical & Kitchen FCEV',
      ),
    ];
  }
}

/// Kontroler stanu Riverpod dla zarządzania flotą EV/wodorową i bilansem ESG.
class EsgSustainabilityFleetNotifier
    extends StateNotifier<TeamEsgSustainabilityAndGreenFleetModel> {
  EsgSustainabilityFleetNotifier([
    TeamEsgSustainabilityAndGreenFleetModel? initial,
  ]) : super(
          initial ??
              TeamEsgSustainabilityAndGreenFleetModel.createStarterWorldTour(
                teamId: 'team_player_wt',
              ),
        );

  void toggleVehicleConvoyActive(String vehicleId) {
    final updatedVehicles = state.vehicles.map((v) {
      if (v.id != vehicleId) return v;
      return v.copyWith(isActiveInRaceConvoy: !v.isActiveInRaceConvoy);
    }).toList();
    state = state.copyWith(vehicles: updatedVehicles);
  }

  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      purchaseOrUpgradeVehicle(
    TeamFleetVehicle newVehicle, {
    String? replaceVehicleId,
  }) {
    final res = state.purchaseOrUpgradeVehicle(
      newVehicle,
      replaceVehicleId: replaceVehicleId,
    );
    if (res.success && res.data != null) {
      state = res.data!;
    }
    return res;
  }

  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      upgradeChargingInfrastructure(ChargingInfrastructureTier targetTier) {
    final res = state.upgradeChargingInfrastructure(targetTier);
    if (res.success && res.data != null) {
      state = res.data!;
    }
    return res;
  }

  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      recordRaceConvoyTrip({
    required String stageId,
    required String stageName,
    required double distanceKm,
    required double elevationGainM,
    required double ambientTempC,
    required String dateIso,
  }) {
    final res = state.recordRaceConvoyTrip(
      stageId: stageId,
      stageName: stageName,
      distanceKm: distanceKm,
      elevationGainM: elevationGainM,
      ambientTempC: ambientTempC,
      dateIso: dateIso,
    );
    if (res.success && res.data != null) {
      state = res.data!;
    }
    return res;
  }

  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> recordTeamTravel({
    required String description,
    required TravelTransportMode mode,
    required double distanceKm,
    required int delegationSize,
    required String dateIso,
  }) {
    final res = state.recordTeamTravel(
      description: description,
      mode: mode,
      distanceKm: distanceKm,
      delegationSize: delegationSize,
      dateIso: dateIso,
    );
    if (res.success && res.data != null) {
      state = res.data!;
    }
    return res;
  }

  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      purchaseCarbonOffsets({
    required double tonsCo2,
    required CarbonOffsetProgramType program,
    required String dateIso,
  }) {
    final res = state.purchaseCarbonOffsets(
      tonsCo2: tonsCo2,
      program: program,
      dateIso: dateIso,
    );
    if (res.success && res.data != null) {
      state = res.data!;
    }
    return res;
  }

  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> signGreenSponsor(
    String sponsorId,
  ) {
    final res = state.signGreenSponsor(sponsorId);
    if (res.success && res.data != null) {
      state = res.data!;
    }
    return res;
  }

  EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel>
      collectAnnualGreenSponsorPayouts() {
    final res = state.collectAnnualGreenSponsorPayouts();
    if (res.success && res.data != null) {
      state = res.data!;
    }
    return res;
  }

  void togglePolicy({
    bool? railOverFlight,
    bool? recycledKit,
    bool? ecoBottles,
  }) {
    state = state.togglePolicy(
      railOverFlight: railOverFlight,
      recycledKit: recycledKit,
      ecoBottles: ecoBottles,
    );
  }
}

final esgSustainabilityFleetProvider = StateNotifierProvider<
    EsgSustainabilityFleetNotifier,
    TeamEsgSustainabilityAndGreenFleetModel>((ref) {
  return EsgSustainabilityFleetNotifier();
});

/// Ekran zarządzania flotą EV/wodorową i bilansem ekologicznym drużyny (Zadanie #572).
class EsgSustainabilityAndFleetScreen extends ConsumerStatefulWidget {
  const EsgSustainabilityAndFleetScreen({
    super.key,
    this.initialModel,
    this.onModelChanged,
    this.showAppBar = true,
    this.initialTab = EsgSustainabilityFleetTab.fleet,
  });

  /// Opcjonalny stan początkowy (używany w testach lub podglądach izolowanych).
  final TeamEsgSustainabilityAndGreenFleetModel? initialModel;

  /// Callback wywoływany po każdej zmianie modelu ESG.
  final ValueChanged<TeamEsgSustainabilityAndGreenFleetModel>? onModelChanged;

  /// Czy wyświetlać górny pasek nawigacji [AppBar].
  final bool showAppBar;

  /// Domyślnie aktywna zakładka po otwarciu ekranu.
  final EsgSustainabilityFleetTab initialTab;

  @override
  ConsumerState<EsgSustainabilityAndFleetScreen> createState() =>
      _EsgSustainabilityAndFleetScreenState();
}

class _EsgSustainabilityAndFleetScreenState
    extends ConsumerState<EsgSustainabilityAndFleetScreen> {
  TeamEsgSustainabilityAndGreenFleetModel? _localModel;
  late EsgSustainabilityFleetTab _activeTab;

  String? _statusMessage;
  bool _statusIsError = false;

  // Stan Floty i zakupów
  String? _replaceVehicleId;
  int _purchaseSeq = 1;

  // Stan Kalkulatora Offsetów i Podróży
  CarbonOffsetProgramType _selectedOffsetProgram =
      CarbonOffsetProgramType.reforestation;
  double _selectedOffsetTons = 10.0;
  TravelTransportMode _selectedTravelMode = TravelTransportMode.highSpeedRail;
  double _travelDistanceKm = 480.0;
  int _travelDelegationSize = 18;
  CarbonLedgerCategory? _ledgerFilter;

  // Stan Symulatora Konwoju Etapowego
  double _simStageDistanceKm = 185.0;
  double _simElevationGainM = 2400.0;
  double _simAmbientTempC = 19.0;
  int _simChargingStops = 0;
  bool _simMobileSolarSupport = false;

  bool get _usesLocalModel => widget.initialModel != null;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    if (widget.initialModel != null) {
      _localModel = widget.initialModel;
    }
  }

  @override
  void didUpdateWidget(covariant EsgSustainabilityAndFleetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialModel != null &&
        widget.initialModel != oldWidget.initialModel) {
      _localModel = widget.initialModel;
    }
  }

  TeamEsgSustainabilityAndGreenFleetModel _currentModel() {
    if (_usesLocalModel) {
      return _localModel!;
    }
    return ref.watch(esgSustainabilityFleetProvider);
  }

  void _applyModel(TeamEsgSustainabilityAndGreenFleetModel updated) {
    if (_usesLocalModel) {
      setState(() {
        _localModel = updated;
      });
    }
    widget.onModelChanged?.call(updated);
  }

  void _showFeedback(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
  }

  void _handleToggleVehicleConvoy(String vehicleId) {
    if (_usesLocalModel) {
      final updatedVehicles = _localModel!.vehicles.map((v) {
        if (v.id != vehicleId) return v;
        return v.copyWith(isActiveInRaceConvoy: !v.isActiveInRaceConvoy);
      }).toList();
      _applyModel(_localModel!.copyWith(vehicles: updatedVehicles));
    } else {
      ref
          .read(esgSustainabilityFleetProvider.notifier)
          .toggleVehicleConvoyActive(vehicleId);
      widget.onModelChanged?.call(ref.read(esgSustainabilityFleetProvider));
    }
  }

  void _handlePurchaseVehicle(TeamFleetVehicle template) {
    final uniqueVehicle = template.copyWith(
      id: '${template.id}_${DateTime.now().microsecondsSinceEpoch}_$_purchaseSeq',
    );
    _purchaseSeq++;

    final EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> res;
    if (_usesLocalModel) {
      res = _localModel!.purchaseOrUpgradeVehicle(
        uniqueVehicle,
        replaceVehicleId: _replaceVehicleId,
      );
      if (res.success && res.data != null) {
        _applyModel(res.data!);
      }
    } else {
      res = ref
          .read(esgSustainabilityFleetProvider.notifier)
          .purchaseOrUpgradeVehicle(
            uniqueVehicle,
            replaceVehicleId: _replaceVehicleId,
          );
      if (res.success && res.data != null) {
        widget.onModelChanged?.call(res.data!);
      }
    }

    if (res.success) {
      setState(() {
        _replaceVehicleId = null;
      });
    }
    _showFeedback(res.messagePl, isError: !res.success);
  }

  void _handlePurchaseOffsets() {
    final EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> res;
    if (_usesLocalModel) {
      res = _localModel!.purchaseCarbonOffsets(
        tonsCo2: _selectedOffsetTons,
        program: _selectedOffsetProgram,
        dateIso: '2026-06-15',
      );
      if (res.success && res.data != null) {
        _applyModel(res.data!);
      }
    } else {
      res = ref
          .read(esgSustainabilityFleetProvider.notifier)
          .purchaseCarbonOffsets(
            tonsCo2: _selectedOffsetTons,
            program: _selectedOffsetProgram,
            dateIso: '2026-06-15',
          );
      if (res.success && res.data != null) {
        widget.onModelChanged?.call(res.data!);
      }
    }
    _showFeedback(res.messagePl, isError: !res.success);
  }

  void _handleRecordTeamTravel() {
    final String label = switch (_selectedTravelMode) {
      TravelTransportMode.shortHaulFlight => 'Przelot regionalny na wyścig',
      TravelTransportMode.longHaulFlight => 'Przelot międzykontynentalny',
      TravelTransportMode.highSpeedRail => 'Przejazd TGV / Koleją Dużych Prędkości',
      TravelTransportMode.electricTeamBus => 'Transfer Autokarem Elektrycznym',
      TravelTransportMode.dieselTeamBus => 'Transfer Autokarem Diesel',
    };

    final EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> res;
    if (_usesLocalModel) {
      res = _localModel!.recordTeamTravel(
        description: label,
        mode: _selectedTravelMode,
        distanceKm: _travelDistanceKm,
        delegationSize: _travelDelegationSize,
        dateIso: '2026-06-18',
      );
      if (res.success && res.data != null) {
        _applyModel(res.data!);
      }
    } else {
      res = ref.read(esgSustainabilityFleetProvider.notifier).recordTeamTravel(
            description: label,
            mode: _selectedTravelMode,
            distanceKm: _travelDistanceKm,
            delegationSize: _travelDelegationSize,
            dateIso: '2026-06-18',
          );
      if (res.success && res.data != null) {
        widget.onModelChanged?.call(res.data!);
      }
    }
    _showFeedback(res.messagePl, isError: !res.success);
  }

  void _handleRecordStageConvoy() {
    final EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> res;
    if (_usesLocalModel) {
      res = _localModel!.recordRaceConvoyTrip(
        stageId: 'sim_stage_${_localModel!.ledger.length + 1}',
        stageName:
            'Etap ${_simStageDistanceKm.round()} km (+${_simElevationGainM.round()} m)',
        distanceKm: _simStageDistanceKm,
        elevationGainM: _simElevationGainM,
        ambientTempC: _simAmbientTempC,
        dateIso: '2026-07-04',
      );
      if (res.success && res.data != null) {
        _applyModel(res.data!);
      }
    } else {
      res = ref
          .read(esgSustainabilityFleetProvider.notifier)
          .recordRaceConvoyTrip(
            stageId: 'sim_stage_${DateTime.now().millisecondsSinceEpoch}',
            stageName:
                'Etap ${_simStageDistanceKm.round()} km (+${_simElevationGainM.round()} m)',
            distanceKm: _simStageDistanceKm,
            elevationGainM: _simElevationGainM,
            ambientTempC: _simAmbientTempC,
            dateIso: '2026-07-04',
          );
      if (res.success && res.data != null) {
        widget.onModelChanged?.call(res.data!);
      }
    }
    _showFeedback(res.messagePl, isError: !res.success);
  }

  void _handleUpgradeInfrastructure(ChargingInfrastructureTier tier) {
    final EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> res;
    if (_usesLocalModel) {
      res = _localModel!.upgradeChargingInfrastructure(tier);
      if (res.success && res.data != null) {
        _applyModel(res.data!);
      }
    } else {
      res = ref
          .read(esgSustainabilityFleetProvider.notifier)
          .upgradeChargingInfrastructure(tier);
      if (res.success && res.data != null) {
        widget.onModelChanged?.call(res.data!);
      }
    }
    _showFeedback(res.messagePl, isError: !res.success);
  }

  void _handleTogglePolicy({
    bool? railOverFlight,
    bool? recycledKit,
    bool? ecoBottles,
  }) {
    if (_usesLocalModel) {
      _applyModel(
        _localModel!.togglePolicy(
          railOverFlight: railOverFlight,
          recycledKit: recycledKit,
          ecoBottles: ecoBottles,
        ),
      );
    } else {
      ref.read(esgSustainabilityFleetProvider.notifier).togglePolicy(
            railOverFlight: railOverFlight,
            recycledKit: recycledKit,
            ecoBottles: ecoBottles,
          );
      widget.onModelChanged?.call(ref.read(esgSustainabilityFleetProvider));
    }
    _showFeedback('Zaktualizowano politykę zrównoważonego rozwoju drużyny.');
  }

  void _handleSignGreenSponsor(String sponsorId) {
    final EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> res;
    if (_usesLocalModel) {
      res = _localModel!.signGreenSponsor(sponsorId);
      if (res.success && res.data != null) {
        _applyModel(res.data!);
      }
    } else {
      res = ref
          .read(esgSustainabilityFleetProvider.notifier)
          .signGreenSponsor(sponsorId);
      if (res.success && res.data != null) {
        widget.onModelChanged?.call(res.data!);
      }
    }
    _showFeedback(res.messagePl, isError: !res.success);
  }

  void _handleCollectSponsorPayouts() {
    final EsgOperationResult<TeamEsgSustainabilityAndGreenFleetModel> res;
    if (_usesLocalModel) {
      res = _localModel!.collectAnnualGreenSponsorPayouts();
      if (res.success && res.data != null) {
        _applyModel(res.data!);
      }
    } else {
      res = ref
          .read(esgSustainabilityFleetProvider.notifier)
          .collectAnnualGreenSponsorPayouts();
      if (res.success && res.data != null) {
        widget.onModelChanged?.call(res.data!);
      }
    }
    _showFeedback(res.messagePl, isError: !res.success);
  }

  @override
  Widget build(BuildContext context) {
    final model = _currentModel();
    final overview = model.computeOverview();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              title: const Text(
                'Flota EV / Wodorowa & Ekonomia ESG',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: _CashBadge(cashEur: model.cashBalanceEur),
                  ),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isCompact = width < 640;
            final bool isDesktop = width >= 1120;
            final double horizontalPadding = isCompact ? 12.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12.0,
                horizontalPadding,
                28.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!widget.showAppBar) ...[
                        _InlineScreenHeader(cashEur: model.cashBalanceEur),
                        const SizedBox(height: 12),
                      ],
                      if (_statusMessage != null) ...[
                        _StatusFeedbackBanner(
                          message: _statusMessage!,
                          isError: _statusIsError,
                          onDismiss: () =>
                              setState(() => _statusMessage = null),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _EsgKpiHeaderStrip(
                        model: model,
                        overview: overview,
                        isCompact: isCompact,
                        isDesktop: isDesktop,
                      ),
                      const SizedBox(height: 16),
                      _EsgTabBar(
                        activeTab: _activeTab,
                        onSelect: (tab) => setState(() => _activeTab = tab),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: KeyedSubtree(
                          key: ValueKey(_activeTab),
                          child: switch (_activeTab) {
                            EsgSustainabilityFleetTab.fleet => _buildFleetTab(
                                model,
                                overview,
                                isCompact: isCompact,
                                isDesktop: isDesktop,
                              ),
                            EsgSustainabilityFleetTab.carbonLedger =>
                              _buildCarbonLedgerTab(
                                model,
                                overview,
                                isCompact: isCompact,
                                isDesktop: isDesktop,
                              ),
                            EsgSustainabilityFleetTab.convoyAndInfra =>
                              _buildConvoyAndInfraTab(
                                model,
                                isCompact: isCompact,
                                isDesktop: isDesktop,
                              ),
                            EsgSustainabilityFleetTab.greenSponsors =>
                              _buildGreenSponsorsTab(
                                model,
                                overview,
                                isCompact: isCompact,
                                isDesktop: isDesktop,
                              ),
                          },
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
    );
  }

  Widget _buildFleetTab(
    TeamEsgSustainabilityAndGreenFleetModel model,
    TeamEsgOverview overview, {
    required bool isCompact,
    required bool isDesktop,
  }) {
    final catalog = EsgVehicleCatalog.buildPurchaseCatalog(
      sequenceSeed: _purchaseSeq,
    );

    final fleetSection = _SectionCard(
      title: 'Aktywna Flota Zespołu (${model.vehicles.length})',
      subtitle: overview.allRaceCarsZeroEmission
          ? 'Wszystkie wozy wyścigowe są bezemisyjne (BEV/FCEV)'
          : 'Wymień spalinowe wozy wyścigowe na EV/FCEV, aby odblokować premie ESG',
      trailing: _replaceVehicleId != null
          ? _EsgActionButton(
              label: 'Anuluj wymianę',
              icon: Icons.close_rounded,
              isSecondary: true,
              onPressed: () => setState(() => _replaceVehicleId = null),
            )
          : null,
      child: model.vehicles.isEmpty
          ? const _EmptyStateBox(
              icon: Icons.directions_car_outlined,
              message: 'Brak pojazdów we flocie. Kup pierwszy pojazd poniżej.',
            )
          : LayoutBuilder(
              builder: (context, c) {
                final int cols = c.maxWidth >= 900 ? 2 : 1;
                const double gap = 12.0;
                final double itemWidth =
                    (c.maxWidth - (gap * (cols - 1))) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: model.vehicles.map((vehicle) {
                    final bool isSelectedForReplace =
                        _replaceVehicleId == vehicle.id;
                    return SizedBox(
                      width: itemWidth,
                      child: _FleetVehicleCard(
                        vehicle: vehicle,
                        isSelectedForReplace: isSelectedForReplace,
                        elevationGainM: _simElevationGainM,
                        ambientTempC: _simAmbientTempC,
                        onToggleConvoy: () =>
                            _handleToggleVehicleConvoy(vehicle.id),
                        onSelectReplace: () {
                          setState(() {
                            _replaceVehicleId = isSelectedForReplace
                                ? null
                                : vehicle.id;
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );

    final TeamFleetVehicle? replacingVehicle = _replaceVehicleId == null
        ? null
        : model.vehicles
            .where((v) => v.id == _replaceVehicleId)
            .firstOrNull;
    final double tradeInBonus = replacingVehicle == null
        ? 0.0
        : replacingVehicle.purchaseCostEur *
            0.40 *
            (replacingVehicle.conditionPercent / 100.0);

    final catalogSection = _SectionCard(
      title: replacingVehicle != null
          ? 'Wymiana pojazdu: ${replacingVehicle.name}'
          : 'Katalog Pojazdów EV & Wodorowych (BEV / FCEV)',
      subtitle: replacingVehicle != null
          ? 'Wartość rozliczeniowa (trade-in 40%): ${Formatters.formatCurrency(tradeInBonus)}'
          : 'Zero emisji spalin na trasie, wyższy wskaźnik elektryfikacji i niższe koszty energii',
      child: LayoutBuilder(
        builder: (context, c) {
          final int cols = c.maxWidth >= 900 ? 2 : 1;
          const double gap = 12.0;
          final double itemWidth = (c.maxWidth - (gap * (cols - 1))) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: catalog.map((item) {
              final double netCost =
                  math.max(0.0, item.purchaseCostEur - tradeInBonus);
              final bool canAfford = model.cashBalanceEur >= netCost;
              return SizedBox(
                width: itemWidth,
                child: _CatalogVehicleCard(
                  vehicle: item,
                  netCostEur: netCost,
                  hasTradeIn: tradeInBonus > 0,
                  canAfford: canAfford,
                  onPurchase:
                      canAfford ? () => _handlePurchaseVehicle(item) : null,
                ),
              );
            }).toList(),
          );
        },
      ),
    );

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fleetSection,
          const SizedBox(height: 16),
          catalogSection,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fleetSection,
        const SizedBox(height: 16),
        catalogSection,
      ],
    );
  }

  Widget _buildCarbonLedgerTab(
    TeamEsgSustainabilityAndGreenFleetModel model,
    TeamEsgOverview overview, {
    required bool isCompact,
    required bool isDesktop,
  }) {
    final double estimatedOffsetCost = _selectedOffsetTons *
        model.carbonCreditPricePerTonEur *
        _selectedOffsetProgram.priceMultiplier;
    final bool canAffordOffset = model.cashBalanceEur >= estimatedOffsetCost;

    final double travelPreviewCo2 = _travelDistanceKm *
        _travelDelegationSize *
        ((model.railOverFlightPolicyEnabled &&
                _selectedTravelMode == TravelTransportMode.shortHaulFlight &&
                _travelDistanceKm <= 700.0)
            ? TravelTransportMode.highSpeedRail.kgCo2PerPassengerKm
            : _selectedTravelMode.kgCo2PerPassengerKm);

    final filteredLedger = _ledgerFilter == null
        ? model.ledger
        : model.ledger.where((e) => e.category == _ledgerFilter).toList();

    final balanceCard = _SectionCard(
      title: 'Bilans Węglowy Sezonu (${model.seasonYear})',
      subtitle: overview.isCarbonNeutral
          ? 'Drużyna osiągnęła neutralność węglową netto (Net Zero)'
          : 'Limit roczny Karty Klimatycznej UCI: ${model.annualCo2BudgetTons.toStringAsFixed(0)} t CO₂',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 76,
            child: CustomPaint(
              painter: _CarbonBalanceBreakdownPainter(
                totalEmissionsKg: overview.totalEmissionsKg,
                totalOffsetsKg: overview.totalOffsetsKg,
                annualCapKg: overview.annualBudgetEmissionsCapKg,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendChip(
                color: AppColors.crimsonAlert,
                label:
                    'Emisje brutto: ${(overview.totalEmissionsKg / 1000.0).toStringAsFixed(2)} t',
              ),
              _LegendChip(
                color: AppColors.statusSuccess,
                label:
                    'Kompensacja: ${(overview.totalOffsetsKg / 1000.0).toStringAsFixed(2)} t',
              ),
              _LegendChip(
                color: overview.isCarbonNeutral
                    ? AppColors.cyanAccent
                    : AppColors.goldAccent,
                label:
                    'Bilans netto: ${(overview.netCarbonBalanceKg / 1000.0).toStringAsFixed(2)} t',
              ),
            ],
          ),
        ],
      ),
    );

    final offsetCard = _SectionCard(
      title: 'Zakup Kredytów Węglowych (Carbon Offsets)',
      subtitle:
          'Cena bazowa: ${Formatters.formatCurrency(model.carbonCreditPricePerTonEur)} / t CO₂',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CarbonOffsetProgramType.values.map((prog) {
              final bool selected = _selectedOffsetProgram == prog;
              return _EsgChoicePill(
                label:
                    '${prog.displayNamePl} (${prog.priceMultiplier.toStringAsFixed(2)}x)',
                selected: selected,
                onTap: () => setState(() => _selectedOffsetProgram = prog),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5.0, 10.0, 25.0, 50.0].map((tons) {
              return _EsgChoicePill(
                label: '${tons.toStringAsFixed(0)} t CO₂',
                selected: (_selectedOffsetTons - tons).abs() < 0.01,
                onTap: () => setState(() => _selectedOffsetTons = tons),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Koszt operacji: ${Formatters.formatCurrency(estimatedOffsetCost)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _EsgActionButton(
                label: 'Kup kompensację',
                icon: Icons.forest_rounded,
                onPressed: canAffordOffset ? _handlePurchaseOffsets : null,
              ),
            ],
          ),
        ],
      ),
    );

    final travelCard = _SectionCard(
      title: 'Rejestrator Podróży Delegacji',
      subtitle: model.railOverFlightPolicyEnabled
          ? 'Polityka kolejowa aktywna: loty ≤ 700 km automatycznie zamieniane na TGV'
          : 'Porównaj emisję CO₂ lotu vs kolei dużych prędkości',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TravelTransportMode.values.map((mode) {
              return _EsgChoicePill(
                label: _travelModeLabel(mode),
                selected: _selectedTravelMode == mode,
                onTap: () => setState(() => _selectedTravelMode = mode),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _LabeledSlider(
            label: 'Dystans podróży',
            valueLabel: '${_travelDistanceKm.round()} km',
            value: _travelDistanceKm,
            min: 100,
            max: 2500,
            divisions: 24,
            onChanged: (v) => setState(() => _travelDistanceKm = v),
          ),
          _LabeledSlider(
            label: 'Liczebność delegacji',
            valueLabel: '$_travelDelegationSize os.',
            value: _travelDelegationSize.toDouble(),
            min: 4,
            max: 40,
            divisions: 36,
            onChanged: (v) => setState(() => _travelDelegationSize = v.round()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Szacowana emisja: ${travelPreviewCo2.toStringAsFixed(1)} kg CO₂',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentBlue,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _EsgActionButton(
                label: 'Zaksięguj podróż',
                icon: Icons.train_rounded,
                onPressed: _handleRecordTeamTravel,
              ),
            ],
          ),
        ],
      ),
    );

    final ledgerCard = _SectionCard(
      title: 'Księga Emisji i Kompensacji (${filteredLedger.length})',
      subtitle: 'Pełny audyt operacji logistycznych i kredytów węglowych',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EsgChoicePill(
                label: 'Wszystkie',
                selected: _ledgerFilter == null,
                onTap: () => setState(() => _ledgerFilter = null),
              ),
              ...CarbonLedgerCategory.values.map((cat) {
                return _EsgChoicePill(
                  label: _ledgerCategoryLabel(cat),
                  selected: _ledgerFilter == cat,
                  onTap: () => setState(() => _ledgerFilter = cat),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          if (filteredLedger.isEmpty)
            const _EmptyStateBox(
              icon: Icons.receipt_long_outlined,
              message: 'Brak wpisów w wybranej kategorii księgi CO₂.',
            )
          else
            Column(
              children: filteredLedger.reversed.map((entry) {
                final bool isOffset = entry.isOffset;
                final Color deltaColor = isOffset
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert;
                final String deltaPrefix = isOffset ? '' : '+';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOffset
                            ? Icons.park_rounded
                            : Icons.local_shipping_rounded,
                        color: deltaColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.description,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.dateIso} • ${_ledgerCategoryLabel(entry.category)}'
                              '${entry.distanceKm > 0 ? ' • ${entry.distanceKm.toStringAsFixed(0)} km' : ''}',
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
                            '$deltaPrefix${entry.co2KgDelta.toStringAsFixed(1)} kg CO₂',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: deltaColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(entry.costEur),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          balanceCard,
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: offsetCard),
              const SizedBox(width: 16),
              Expanded(child: travelCard),
            ],
          ),
          const SizedBox(height: 16),
          ledgerCard,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        balanceCard,
        const SizedBox(height: 16),
        offsetCard,
        const SizedBox(height: 16),
        travelCard,
        const SizedBox(height: 16),
        ledgerCard,
      ],
    );
  }

  Widget _buildConvoyAndInfraTab(
    TeamEsgSustainabilityAndGreenFleetModel model, {
    required bool isCompact,
    required bool isDesktop,
  }) {
    final readiness = model.evaluateStageConvoyReadiness(
      StageConvoyLogisticsPlan(
        stageId: 'preview_stage',
        stageName: 'Symulacja Etapu',
        stageDistanceKm: _simStageDistanceKm,
        elevationGainM: _simElevationGainM,
        ambientTempC: _simAmbientTempC,
        chargingStopsPlanned: _simChargingStops,
        hasMobileSolarSupport: _simMobileSolarSupport,
      ),
    );

    final simulatorCard = _SectionCard(
      title: 'Symulator Gotowości Konwoju na Etap',
      subtitle:
          'Sprawdź zasięg rzeczywisty (WLTP po korekcie na góry/temperaturę) przed startem',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledSlider(
            label: 'Dystans etapu',
            valueLabel: '${_simStageDistanceKm.round()} km (+35 km dojazdy)',
            value: _simStageDistanceKm,
            min: 80,
            max: 270,
            divisions: 38,
            onChanged: (v) => setState(() => _simStageDistanceKm = v),
          ),
          _LabeledSlider(
            label: 'Przewyższenie',
            valueLabel: '${_simElevationGainM.round()} m',
            value: _simElevationGainM,
            min: 200,
            max: 5200,
            divisions: 25,
            onChanged: (v) => setState(() => _simElevationGainM = v),
          ),
          _LabeledSlider(
            label: 'Temperatura otoczenia',
            valueLabel: '${_simAmbientTempC.round()} °C',
            value: _simAmbientTempC,
            min: -5,
            max: 40,
            divisions: 45,
            onChanged: (v) => setState(() => _simAmbientTempC = v),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Postoje ładowania DC:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              ...[0, 1, 2].map((stops) {
                return _EsgChoicePill(
                  label: '$stops',
                  selected: _simChargingStops == stops,
                  onTap: () => setState(() => _simChargingStops = stops),
                );
              }),
              _EsgChoicePill(
                label: 'Mobilny Magazyn PV',
                selected: _simMobileSolarSupport,
                onTap: () => setState(
                  () => _simMobileSolarSupport = !_simMobileSolarSupport,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: readiness.rangeAnxietyRisk
                    ? AppColors.amberWarning
                    : AppColors.statusSuccess.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _MiniMetric(
                      label: 'Emisja konwoju',
                      value:
                          '${readiness.totalConvoyCo2Kg.toStringAsFixed(1)} kg CO₂',
                      color: readiness.isFullyZeroEmission
                          ? AppColors.statusSuccess
                          : AppColors.textPrimary,
                    ),
                    _MiniMetric(
                      label: 'Koszt energii/paliwa',
                      value: Formatters.formatCurrency(
                        readiness.totalEnergyCostEur,
                      ),
                      color: AppColors.accentBlue,
                    ),
                    _MiniMetric(
                      label: 'Min. margines zasięgu',
                      value:
                          '${readiness.minMarginRangeKm.toStringAsFixed(0)} km',
                      color: readiness.rangeAnxietyRisk
                          ? AppColors.crimsonAlert
                          : AppColors.statusSuccess,
                    ),
                  ],
                ),
                if (readiness.warnings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...readiness.warnings.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.amberWarning,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              w,
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
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _EsgActionButton(
              label: 'Zarejestruj przejazd konwoju',
              icon: Icons.flag_rounded,
              onPressed: _handleRecordStageConvoy,
            ),
          ),
        ],
      ),
    );

    final infraCard = _SectionCard(
      title: 'Infrastruktura Ładowania i OZE w Bazie',
      subtitle:
          'Redukuje ślad węglowy ładowania EV nawet o 90% i dodaje do +15 pkt ESG',
      child: Column(
        children: ChargingInfrastructureTier.values.map((tier) {
          final bool isCurrent = model.infrastructureTier == tier;
          final bool isOwnedOrLower =
              tier.index <= model.infrastructureTier.index;
          final bool canAfford = model.cashBalanceEur >= tier.upgradeCostEur;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.primaryAccent.withValues(alpha: 0.14)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent ? AppColors.goldAccent : AppTheme.borderColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.displayNamePl,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${tier.esgScorePoints.toStringAsFixed(0)} pkt ESG • Redukcja sieci CO₂: ${(tier.gridCarbonReductionFactor * 100).round()}%',
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
                if (isCurrent)
                  const _BadgePill(
                    label: 'AKTYWNE',
                    color: AppColors.goldAccent,
                  )
                else if (isOwnedOrLower)
                  const _BadgePill(
                    label: 'POSIADANE',
                    color: AppColors.textSecondary,
                  )
                else
                  _EsgActionButton(
                    label: Formatters.formatCurrency(tier.upgradeCostEur),
                    icon: Icons.upgrade_rounded,
                    onPressed: canAfford
                        ? () => _handleUpgradeInfrastructure(tier)
                        : null,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );

    final policiesCard = _SectionCard(
      title: 'Polityki Zrównoważonego Rozwoju Drużyny',
      subtitle: 'Łącznie do +20 pkt ESG i zgodność z Kartą Klimatyczną UCI',
      child: Column(
        children: [
          _PolicyToggleTile(
            title: 'Kolej zamiast krótkich lotów (≤ 700 km)',
            subtitle:
                'Automatycznie przekierowuje krótkie delegacje na koleje TGV (+9 pkt ESG)',
            value: model.railOverFlightPolicyEnabled,
            onChanged: (val) => _handleTogglePolicy(railOverFlight: val),
          ),
          const SizedBox(height: 10),
          _PolicyToggleTile(
            title: 'Stroje startowe z włókien z recyklingu',
            subtitle:
                'Produkcja kompletów kolarskich w obiegu zamkniętym (+6 pkt ESG)',
            value: model.recycledKitEnabled,
            onChanged: (val) => _handleTogglePolicy(recycledKit: val),
          ),
          const SizedBox(height: 10),
          _PolicyToggleTile(
            title: 'Program biodegradowalnych bidonów Eco-Bottle',
            subtitle:
                'Strefy zbiórki i kompostowalne bidony na etapach (+5 pkt ESG)',
            value: model.ecoBottleProgramEnabled,
            onChanged: (val) => _handleTogglePolicy(ecoBottles: val),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: simulatorCard),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                infraCard,
                const SizedBox(height: 16),
                policiesCard,
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        simulatorCard,
        const SizedBox(height: 16),
        infraCard,
        const SizedBox(height: 16),
        policiesCard,
      ],
    );
  }

  Widget _buildGreenSponsorsTab(
    TeamEsgSustainabilityAndGreenFleetModel model,
    TeamEsgOverview overview, {
    required bool isCompact,
    required bool isDesktop,
  }) {
    final bool hasActiveSponsors = overview.projectedGreenSponsorRevenueEur > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Przychody z Zielonego Sponsoringu',
          subtitle:
              'Spełnienie wymogów ESG gwarantuje 100% podstawy + premię ekologiczną',
          trailing: _EsgActionButton(
            label: 'Rozlicz wypłaty roczne',
            icon: Icons.payments_rounded,
            onPressed: hasActiveSponsors ? _handleCollectSponsorPayouts : null,
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _MiniMetric(
                label: 'Aktywni zieloni sponsorzy',
                value: '${overview.activeGreenSponsorsCount}',
                color: AppColors.statusSuccess,
              ),
              _MiniMetric(
                label: 'Prognozowany przychód roczny',
                value: Formatters.formatCurrency(
                  overview.projectedGreenSponsorRevenueEur,
                ),
                color: AppColors.goldAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (model.greenSponsors.isEmpty)
          const _EmptyStateBox(
            icon: Icons.handshake_outlined,
            message: 'Brak dostępnych ofert zielonych sponsorów w tym sezonie.',
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final int cols = c.maxWidth >= 900 ? 2 : 1;
              const double gap = 12.0;
              final double itemWidth = (c.maxWidth - (gap * (cols - 1))) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: model.greenSponsors.map((sponsor) {
                  return SizedBox(
                    width: itemWidth,
                    child: _GreenSponsorCard(
                      sponsor: sponsor,
                      overview: overview,
                      onSign: sponsor.isActive || !sponsor.isEligible(overview)
                          ? null
                          : () => _handleSignGreenSponsor(sponsor.id),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  String _travelModeLabel(TravelTransportMode mode) {
    switch (mode) {
      case TravelTransportMode.shortHaulFlight:
        return 'Krótki lot';
      case TravelTransportMode.longHaulFlight:
        return 'Długi lot';
      case TravelTransportMode.highSpeedRail:
        return 'Kolej TGV';
      case TravelTransportMode.electricTeamBus:
        return 'Autokar EV';
      case TravelTransportMode.dieselTeamBus:
        return 'Autokar Diesel';
    }
  }

  String _ledgerCategoryLabel(CarbonLedgerCategory cat) {
    switch (cat) {
      case CarbonLedgerCategory.fleetConvoy:
        return 'Konwój';
      case CarbonLedgerCategory.teamTravel:
        return 'Podróże';
      case CarbonLedgerCategory.logisticsFreight:
        return 'Fracht';
      case CarbonLedgerCategory.hqOperations:
        return 'Baza HQ';
      case CarbonLedgerCategory.offsetCredit:
        return 'Offset CO₂';
    }
  }
}

class _InlineScreenHeader extends StatelessWidget {
  const _InlineScreenHeader({required this.cashEur});

  final double cashEur;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Flota EV / Wodorowa & Ekonomia ESG',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CashBadge(cashEur: cashEur),
      ],
    );
  }
}

class _CashBadge extends StatelessWidget {
  const _CashBadge({required this.cashEur});

  final double cashEur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            size: 16,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 6),
          Text(
            Formatters.formatCurrency(cashEur),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
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

class _StatusFeedbackBanner extends StatelessWidget {
  const _StatusFeedbackBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final Color color =
        isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _EsgKpiHeaderStrip extends StatelessWidget {
  const _EsgKpiHeaderStrip({
    required this.model,
    required this.overview,
    required this.isCompact,
    required this.isDesktop,
  });

  final TeamEsgSustainabilityAndGreenFleetModel model;
  final TeamEsgOverview overview;
  final bool isCompact;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final Color tierColor = switch (overview.ratingTier) {
      EsgRatingTier.platinumUciCharter => AppColors.cyanAccent,
      EsgRatingTier.gold => AppColors.goldAccent,
      EsgRatingTier.silver => AppColors.accentBlue,
      EsgRatingTier.bronze => AppColors.amberWarning,
    };

    final kpiCards = [
      _KpiCard(
        title: 'Ocena ESG Drużyny',
        value: '${overview.esgScore.toStringAsFixed(1)} / 100',
        subtitle: overview.ratingTier.displayNamePl,
        accentColor: tierColor,
        leading: SizedBox(
          width: 44,
          height: 44,
          child: CustomPaint(
            painter: _EsgScoreArcPainter(
              score: overview.esgScore,
              accentColor: tierColor,
            ),
          ),
        ),
      ),
      _KpiCard(
        title: 'Elektryfikacja Floty',
        value: '${(overview.fleetElectrificationRatio * 100).round()}%',
        subtitle: overview.allRaceCarsZeroEmission
            ? 'Wozy wyścigowe: 100% Zero-Emission'
            : 'Wymagane EV/FCEV w kolumnie',
        accentColor: overview.allRaceCarsZeroEmission
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.electric_car_rounded,
      ),
      _KpiCard(
        title: 'Bilans Netto CO₂',
        value: '${(overview.netCarbonBalanceKg / 1000.0).toStringAsFixed(1)} t',
        subtitle: overview.isCarbonNeutral
            ? 'Neutralność Węglowa (Net Zero)'
            : 'Limit roczny: ${model.annualCo2BudgetTons.toStringAsFixed(0)} t CO₂',
        accentColor: overview.isCarbonNeutral
            ? AppColors.statusSuccess
            : AppColors.accentBlue,
        icon: Icons.co2_rounded,
      ),
      _KpiCard(
        title: 'Karta Klimatyczna UCI',
        value: overview.uciCharterCompliant ? 'ZGODNA' : 'DO POPRAWY',
        subtitle:
            'Sponsorzy: ${Formatters.formatCurrency(overview.projectedGreenSponsorRevenueEur)}/rok',
        accentColor: overview.uciCharterCompliant
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.verified_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int cols = isDesktop
            ? 4
            : isCompact
                ? 1
                : 2;
        const double gap = 12.0;
        final double itemWidth =
            (constraints.maxWidth - (gap * (cols - 1))) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: kpiCards
              .map((card) => SizedBox(width: itemWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    this.icon,
    this.leading,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.35)),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

class _EsgTabBar extends StatelessWidget {
  const _EsgTabBar({
    required this.activeTab,
    required this.onSelect,
  });

  final EsgSustainabilityFleetTab activeTab;
  final ValueChanged<EsgSustainabilityFleetTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: EsgSustainabilityFleetTab.values.map((tab) {
          final bool isSelected = tab == activeTab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _EsgInteractiveSurface(
              onTap: () => onSelect(tab),
              borderRadius: BorderRadius.circular(12),
              baseColor: isSelected
                  ? AppColors.primaryAccent.withValues(alpha: 0.28)
                  : AppColors.surface,
              hoverColor: isSelected
                  ? AppColors.primaryAccent.withValues(alpha: 0.38)
                  : AppColors.surfaceLight,
              borderColor:
                  isSelected ? AppColors.goldAccent : AppTheme.borderColor,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 16,
                      color: isSelected
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final bool stackTrailing =
                  trailing != null && headerConstraints.maxWidth < 460;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );

              if (stackTrailing) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 10),
                    trailing!,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FleetVehicleCard extends StatelessWidget {
  const _FleetVehicleCard({
    required this.vehicle,
    required this.isSelectedForReplace,
    required this.elevationGainM,
    required this.ambientTempC,
    required this.onToggleConvoy,
    required this.onSelectReplace,
  });

  final TeamFleetVehicle vehicle;
  final bool isSelectedForReplace;
  final double elevationGainM;
  final double ambientTempC;
  final VoidCallback onToggleConvoy;
  final VoidCallback onSelectReplace;

  @override
  Widget build(BuildContext context) {
    final Color powertrainColor = vehicle.isZeroEmission
        ? AppColors.statusSuccess
        : vehicle.powertrain.isElectrified
            ? AppColors.accentBlue
            : AppColors.amberWarning;

    final double realRangeKm = vehicle.effectiveRangeKm(
      elevationGainM: elevationGainM,
      ambientTempC: ambientTempC,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelectedForReplace
              ? AppColors.goldAccent
              : AppTheme.borderColor,
          width: isSelectedForReplace ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _vehicleIcon(vehicle.vehicleType),
                color: powertrainColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${vehicle.vehicleType.displayNamePl} • ${vehicle.assignedRoleLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _BadgePill(
                label: vehicle.powertrain.displayNamePl,
                color: powertrainColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _MiniMetric(
                label: 'Zasięg realny',
                value: '${realRangeKm.round()} km',
                color: AppColors.textPrimary,
              ),
              _MiniMetric(
                label: 'Emisja CO₂',
                value: '${vehicle.co2GramsPerKm.toStringAsFixed(0)} g/km',
                color: powertrainColor,
              ),
              _MiniMetric(
                label: 'Koszt / 100 km',
                value: Formatters.formatCurrency(
                  vehicle.energyCostPer100KmEur,
                  showDecimals: true,
                ),
                color: AppColors.accentBlue,
              ),
              _MiniMetric(
                label: 'Stan / Przebieg',
                value:
                    '${vehicle.conditionPercent.round()}% • ${(vehicle.odometerKm / 1000).toStringAsFixed(1)}k km',
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _EsgChoicePill(
                label: vehicle.isActiveInRaceConvoy
                    ? 'W konwoju wyścigu'
                    : 'Poza konwojem',
                selected: vehicle.isActiveInRaceConvoy,
                onTap: onToggleConvoy,
              ),
              _EsgActionButton(
                label: isSelectedForReplace
                    ? 'Wybrano do wymiany'
                    : 'Wymień (Trade-in)',
                icon: Icons.swap_horiz_rounded,
                isSecondary: !isSelectedForReplace,
                onPressed: onSelectReplace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _vehicleIcon(FleetVehicleType type) {
    switch (type) {
      case FleetVehicleType.directorSportifCar:
        return Icons.directions_car_filled_rounded;
      case FleetVehicleType.mechanicSupportCar:
        return Icons.build_circle_rounded;
      case FleetVehicleType.teamCoachBus:
        return Icons.directions_bus_rounded;
      case FleetVehicleType.equipmentCargoTruck:
        return Icons.local_shipping_rounded;
      case FleetVehicleType.medicalAndKitchenVan:
        return Icons.medical_services_rounded;
    }
  }
}

class _CatalogVehicleCard extends StatelessWidget {
  const _CatalogVehicleCard({
    required this.vehicle,
    required this.netCostEur,
    required this.hasTradeIn,
    required this.canAfford,
    required this.onPurchase,
  });

  final TeamFleetVehicle vehicle;
  final double netCostEur;
  final bool hasTradeIn;
  final bool canAfford;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vehicle.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _BadgePill(
                label: vehicle.powertrain.displayNamePl,
                color: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${vehicle.vehicleType.displayNamePl} • WLTP ${vehicle.wltpRangeKm.round()} km • ${vehicle.batteryCapacityKwh.toStringAsFixed(1)} kWh',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatCurrency(netCostEur),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: canAfford
                            ? AppColors.goldAccent
                            : AppColors.crimsonAlert,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (hasTradeIn)
                      const Text(
                        'Cena po odliczeniu trade-in',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                  ],
                ),
              ),
              _EsgActionButton(
                label: hasTradeIn ? 'Wymień teraz' : 'Kup do floty',
                icon: Icons.add_shopping_cart_rounded,
                onPressed: onPurchase,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GreenSponsorCard extends StatelessWidget {
  const _GreenSponsorCard({
    required this.sponsor,
    required this.overview,
    required this.onSign,
  });

  final GreenSponsorOffer sponsor;
  final TeamEsgOverview overview;
  final VoidCallback? onSign;

  @override
  Widget build(BuildContext context) {
    final bool eligible = sponsor.isEligible(overview);
    final bool scoreMet = overview.esgScore >= sponsor.requiredEsgScore;
    final bool co2Met =
        (overview.netCarbonBalanceKg / 1000.0) <= sponsor.maxAllowedNetCo2Tons;
    final bool zeroCarsMet =
        !sponsor.requiresZeroEmissionRaceCars ||
        overview.allRaceCarsZeroEmission;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sponsor.isActive
              ? AppColors.statusSuccess
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sponsor.sponsorName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${sponsor.category.displayNamePl} • ${sponsor.contractYears} lata',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _BadgePill(
                label: sponsor.isActive
                    ? 'AKTYWNY'
                    : eligible
                        ? 'KWALIFIKUJE'
                        : 'WYMAGA ESG',
                color: sponsor.isActive
                    ? AppColors.statusSuccess
                    : eligible
                        ? AppColors.goldAccent
                        : AppColors.amberWarning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _MiniMetric(
                label: 'Podstawa roczna',
                value: Formatters.formatCurrency(sponsor.annualBaseValueEur),
                color: AppColors.textPrimary,
              ),
              _MiniMetric(
                label: 'Premia ESG',
                value: '+${Formatters.formatCurrency(sponsor.esgBonusValueEur)}',
                color: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RequirementLine(
            label:
                'Ocena ESG ≥ ${sponsor.requiredEsgScore.toStringAsFixed(0)} pkt',
            met: scoreMet,
          ),
          _RequirementLine(
            label:
                'Bilans netto CO₂ ≤ ${sponsor.maxAllowedNetCo2Tons.toStringAsFixed(0)} t',
            met: co2Met,
          ),
          if (sponsor.requiresZeroEmissionRaceCars)
            _RequirementLine(
              label: '100% bezemisyjnych wozów wyścigowych',
              met: zeroCarsMet,
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _EsgActionButton(
              label: sponsor.isActive
                  ? 'Kontrakt aktywny'
                  : 'Podpisz kontrakt',
              icon: sponsor.isActive
                  ? Icons.check_circle_rounded
                  : Icons.draw_rounded,
              onPressed: onSign,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 15,
            color: met ? AppColors.statusSuccess : AppColors.crimsonAlert,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: met ? AppColors.textSecondary : AppColors.crimsonAlert,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyToggleTile extends StatelessWidget {
  const _PolicyToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _EsgInteractiveSurface(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      baseColor: AppColors.surfaceLight,
      hoverColor: AppColors.surfaceLight.withValues(alpha: 0.85),
      borderColor: value ? AppColors.statusSuccess : AppTheme.borderColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.statusSuccess,
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                valueLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
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
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.goldAccent,
          inactiveColor: AppTheme.borderColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
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

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _EmptyStateBox extends StatelessWidget {
  const _EmptyStateBox({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EsgChoicePill extends StatelessWidget {
  const _EsgChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _EsgInteractiveSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      baseColor: selected
          ? AppColors.goldAccent.withValues(alpha: 0.18)
          : AppColors.surface,
      hoverColor: AppColors.surfaceLight,
      borderColor: selected ? AppColors.goldAccent : AppTheme.borderColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.goldAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EsgActionButton extends StatelessWidget {
  const _EsgActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isSecondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color baseColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : isSecondary
            ? AppColors.surface
            : AppColors.primaryAccent;
    final Color hoverColor = !enabled
        ? baseColor
        : isSecondary
            ? AppColors.surfaceLight
            : AppColors.primaryAccent.withValues(alpha: 0.85);
    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : isSecondary
            ? AppTheme.borderColor
            : AppColors.goldAccent.withValues(alpha: 0.6);
    final Color textColor =
        !enabled ? AppColors.textSecondary : AppColors.textPrimary;

    return _EsgInteractiveSurface(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      baseColor: baseColor,
      hoverColor: hoverColor,
      borderColor: borderColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Powierzchnia interaktywna z pełnymi stanami hover / active / disabled / focus.
class _EsgInteractiveSurface extends StatefulWidget {
  const _EsgInteractiveSurface({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    required this.baseColor,
    required this.hoverColor,
    required this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Color baseColor;
  final Color hoverColor;
  final Color borderColor;

  @override
  State<_EsgInteractiveSurface> createState() => _EsgInteractiveSurfaceState();
}

class _EsgInteractiveSurfaceState extends State<_EsgInteractiveSurface> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final Color effectiveBg = !_enabled
        ? widget.baseColor
        : _isPressed
            ? widget.hoverColor.withValues(alpha: 0.9)
            : _isHovered
                ? widget.hoverColor
                : widget.baseColor;

    final Color effectiveBorder = !_enabled
        ? widget.borderColor
        : _isFocused
            ? AppColors.accentBlue
            : _isHovered
                ? AppColors.goldAccent.withValues(alpha: 0.8)
                : widget.borderColor;

    return FocusableActionDetector(
      enabled: _enabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      mouseCursor:
          _enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            _enabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _enabled && _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: effectiveBorder,
                width: _isFocused ? 1.6 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _EsgScoreArcPainter extends CustomPainter {
  const _EsgScoreArcPainter({
    required this.score,
    required this.accentColor,
  });

  final double score;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 4;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const double startAngle = math.pi * 0.75;
    const double totalSweep = math.pi * 1.5;
    final double progress = (score.clamp(0.0, 100.0)) / 100.0;

    canvas.drawArc(rect, startAngle, totalSweep, false, trackPaint);
    canvas.drawArc(
      rect,
      startAngle,
      totalSweep * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EsgScoreArcPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.accentColor != accentColor;
  }
}

class _CarbonBalanceBreakdownPainter extends CustomPainter {
  const _CarbonBalanceBreakdownPainter({
    required this.totalEmissionsKg,
    required this.totalOffsetsKg,
    required this.annualCapKg,
  });

  final double totalEmissionsKg;
  final double totalOffsetsKg;
  final double annualCapKg;

  @override
  void paint(Canvas canvas, Size size) {
    final double maxScale = math.max(
      annualCapKg,
      math.max(totalEmissionsKg, totalOffsetsKg) + 1000.0,
    );

    const double barHeight = 16.0;
    final RRect bgTrack1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 10, size.width, barHeight),
      const Radius.circular(8),
    );
    final RRect bgTrack2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 40, size.width, barHeight),
      const Radius.circular(8),
    );

    final bgPaint = Paint()..color = AppColors.surfaceLight;
    canvas.drawRRect(bgTrack1, bgPaint);
    canvas.drawRRect(bgTrack2, bgPaint);

    final double emissionsWidth =
        ((totalEmissionsKg / maxScale).clamp(0.0, 1.0)) * size.width;
    final double offsetsWidth =
        ((totalOffsetsKg / maxScale).clamp(0.0, 1.0)) * size.width;
    final double capX = ((annualCapKg / maxScale).clamp(0.0, 1.0)) * size.width;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 10, emissionsWidth, barHeight),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.crimsonAlert,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 40, offsetsWidth, barHeight),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.statusSuccess,
    );

    final capLinePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(capX, 4),
      Offset(capX, 64),
      capLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CarbonBalanceBreakdownPainter oldDelegate) {
    return oldDelegate.totalEmissionsKg != totalEmissionsKg ||
        oldDelegate.totalOffsetsKg != totalOffsetsKg ||
        oldDelegate.annualCapKg != annualCapKg;
  }
}
