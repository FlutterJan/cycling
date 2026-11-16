// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/physics/bike_fit_and_wind_tunnel_engine.dart';
import '../../models/equipment/bike_fit_configuration.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/equipment/groupset_model.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/equipment/wheelset_model.dart';
import '../../models/rider/rider.dart';
import '../../services/generators/rider_procedural_generator.dart';
import '../../state/career_controller.dart';
import '../widgets/rider_avatar_painter.dart';
import '../widgets/wind_tunnel_cda_delta_comparator.dart';

/// Tryb pozycji korby w wizualizacji kinematyki
enum CrankKinematicMode {
  topDeadCenter, // GMP - 12:00 (Maksymalne zgięcie biodra)
  powerPhase, // Faza Mocy - 3:00 (Maksymalny moment obrotowy)
  bottomDeadCenter, // DMP - 6:00 (Maksymalny wyprost kolana)
  animating, // Płynny ciągły obrót korby
}

/// Ekran Wirtualnego Tunelu Aerodynamicznego i Studia Bike Fittingu.
///
/// Zawiera:
/// 1. Suwaki wszystkich parametrów pozycji kolarza (wysokość siodła, kąt siodła,
///    szerokość kokpitu, podkładki mostka, długość korb, rotacja klamek).
/// 2. Wizualizację sylwetki kolarza na rowerze z naniesionymi kątami stawu
///    kolanowego i biodrowego (`RiderBikeFitGeometryPainter`).
/// 3. Symulator tunelu aerodynamicznego: test przy wietrze 45 km/h pod różnymi
///    kątami odchylenia (Yaw Angle -15° do +15°), pokazujący wyliczone CdA,
///    wymaganą moc w watach oraz poziom komfortu i bezpieczeństwa stawów.
class WindTunnelAndBikeFitScreen extends ConsumerStatefulWidget {
  final String? initialRiderId;
  final bool showAppBar;

  const WindTunnelAndBikeFitScreen({
    super.key,
    this.initialRiderId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<WindTunnelAndBikeFitScreen> createState() =>
      _WindTunnelAndBikeFitScreenState();
}

class _WindTunnelAndBikeFitScreenState
    extends ConsumerState<WindTunnelAndBikeFitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Aktywny kolarz i kadra
  late Rider _selectedRider;
  List<Rider> _squadRiders = [];

  // ===========================================================================
  // PARAMETRY BIKE FITTINGU (STAN SUWAKÓW)
  // ===========================================================================
  late double _saddleHeightMm;
  late double _saddleSetbackMm;
  late double _saddleTiltDegrees;
  late int _cockpitWidthMm;
  late int _stemLengthMm;
  late int _spacersStackMm;
  late double _hoodInwardTiltDegrees;
  late double _crankArmLengthMm;
  late double _cleatOffsetMm;

  // ===========================================================================
  // PARAMETRY TUNELU AERODYNAMICZNEGO
  // ===========================================================================
  double _yawAngleDegrees = 0.0; // Kąt pozornego wiatru (-15.0° do +15.0°)
  double _windSpeedKmh = 45.0; // Prędkość wiatru w tunelu (domyślnie 45 km/h)
  bool _showSmokeStreamers = true; // Wizualizacja strug dymu tunelu
  bool _showJointAngleBadges = true; // Wyświetlanie łuków i kątów biomechanicznych
  CrankKinematicMode _crankMode = CrankKinematicMode.topDeadCenter;

  // Aktywny rower (lub domyślna maszyna aero)
  late CompleteBike _activeBike;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _initializeData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final careerState = ref.read(careerControllerProvider);
    final save = careerState.save;

    if (save != null && save.riders.isNotEmpty) {
      final teamRiders =
          save.riders.where((r) => r.contract.teamId == save.playerTeamId).toList();
      _squadRiders = teamRiders.isNotEmpty ? teamRiders : save.riders.take(8).toList();
    } else {
      _squadRiders = _generateDemoSquad();
    }

    if (widget.initialRiderId != null) {
      _selectedRider = _squadRiders.firstWhere(
        (r) => r.id == widget.initialRiderId,
        orElse: () => _squadRiders.first,
      );
    } else {
      _selectedRider = _squadRiders.first;
    }

    final initialFit = BikeFitConfiguration.proceduralForRider(
      heightCm: _selectedRider.physiology.heightCm,
      weightKg: _selectedRider.physiology.weightKg,
      isAeroFocus: true,
    );
    _saddleHeightMm = initialFit.saddleHeightMm;
    _saddleSetbackMm = initialFit.saddleSetbackMm;
    _saddleTiltDegrees = initialFit.saddleTiltDegrees;
    _cockpitWidthMm = initialFit.cockpitWidthMm;
    _stemLengthMm = initialFit.stemLengthMm;
    _spacersStackMm = initialFit.spacersStackMm;
    _hoodInwardTiltDegrees = initialFit.hoodInwardTiltDegrees;
    _crankArmLengthMm = initialFit.crankArmLengthMm;
    _cleatOffsetMm = initialFit.cleatOffsetMm;

    _activeBike = _buildDefaultBikeForRider(_selectedRider);
  }

  void _applyFitToState(BikeFitConfiguration fit) {
    setState(() {
      _saddleHeightMm = fit.saddleHeightMm;
      _saddleSetbackMm = fit.saddleSetbackMm;
      _saddleTiltDegrees = fit.saddleTiltDegrees;
      _cockpitWidthMm = fit.cockpitWidthMm;
      _stemLengthMm = fit.stemLengthMm;
      _spacersStackMm = fit.spacersStackMm;
      _hoodInwardTiltDegrees = fit.hoodInwardTiltDegrees;
      _crankArmLengthMm = fit.crankArmLengthMm;
      _cleatOffsetMm = fit.cleatOffsetMm;
    });
  }

  BikeFitConfiguration _currentFit() {
    return BikeFitConfiguration(
      saddleHeightMm: _saddleHeightMm,
      saddleSetbackMm: _saddleSetbackMm,
      saddleTiltDegrees: _saddleTiltDegrees,
      cockpitWidthMm: _cockpitWidthMm,
      stemLengthMm: _stemLengthMm,
      spacersStackMm: _spacersStackMm,
      hoodInwardTiltDegrees: _hoodInwardTiltDegrees,
      crankArmLengthMm: _crankArmLengthMm,
      cleatOffsetMm: _cleatOffsetMm,
    );
  }

  List<Rider> _generateDemoSquad() {
    return [
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.timeTrialist,
        targetOverallRating: 88,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        targetOverallRating: 89,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.pureSprinter,
        targetOverallRating: 87,
      ),
      RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.classicCobbles,
        targetOverallRating: 85,
      ),
    ];
  }

  CompleteBike _buildDefaultBikeForRider(Rider rider) {
    return CompleteBike(
      id: 'bike_wt_aero_${rider.id}',
      name: 'AeroLab TT / Road Machine',
      frame: const FrameModel(
        id: 'f_aero_lab',
        brandId: 'brand_aerolab',
        name: 'AeroFlight Carbon Monocoque',
        category: FrameCategory.aero,
        weightGrams: 890,
        aeroCdaModifier: -0.016,
        stiffnessToWeightIndex: 2.1,
        comfortCompliance: 0.65,
        priceEur: 4200,
        mesh3dAssetPath: 'models/bike.glb',
        primaryColorHex: '#00E5FF',
      ),
      wheelset: const WheelsetModel(
        id: 'w_carbon_60',
        brandId: 'brand_aerolab',
        name: 'AeroStream 60mm Carbon',
        rimDepthMm: 60,
        weightGrams: 1410,
        aeroCdaModifier: -0.012,
        crosswindStabilityPenalty: 0.28,
        momentOfInertia: 0.13,
        hubEngagementDragWatts: 0.5,
        priceEur: 1900,
      ),
      groupset: const GroupsetModel(
        id: 'g_dura_di2',
        brandId: 'brand_shim',
        name: 'Shimano Dura-Ace Di2 12s',
        weightGrams: 2250,
        isElectronic: true,
        speedCount: 12,
        mechanicalEfficiency: 0.985,
        priceEur: 2900,
      ),
      tire: const TireModel(
        id: 't_gp5000_tt',
        brandId: 'brand_conti',
        name: 'Continental GP5000 TT TR',
        widthMm: 28,
        weightGrams: 225,
        rollingResistanceCrr: 0.0028,
        punctureResistanceIndex: 3.5,
        wetGripIndex: 4.2,
        isTubeless: true,
        priceEur: 85,
      ),
      cockpitWidthMm: _cockpitWidthMm,
      hoodInwardTiltDegrees: _hoodInwardTiltDegrees,
      slammedStem: _spacersStackMm <= 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFit = _currentFit();
    final evaluation = BikeFitAndWindTunnelEngine.evaluateFit(
      fit: currentFit,
      physiology: _selectedRider.physiology,
      skills: _selectedRider.skills,
      bike: _activeBike,
      riderAge: _selectedRider.age,
      testingAirSpeedKmh: _windSpeedKmh,
    );

    // Wyznaczenie telemetrycznego punktu dla wybranego kąta Yaw
    final yawPoint = _getYawPointForAngle(
      evaluation.windTunnelReport,
      _yawAngleDegrees,
      currentFit,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text(
                'TUNEL AERODYNAMICZNY & BIKE FITTING',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              backgroundColor: AppColors.surface,
              elevation: 0,
              actions: [
                _buildRiderSelector(),
                const SizedBox(width: 12),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Jeśli nie ma AppBara (np. w powłoce shell), wyświetlamy smukły nagłówek
            if (!widget.showAppBar) _buildHeaderBar(),

            // Pasek Szybkich Presetów Fittingu
            _buildPresetsBar(currentFit),

            // Główna część robocza: Podział ekranu na Wizualizację Tunelu i Panel Suwaków
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 980;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lewa / Środkowa część: Wizualizacja Sylwetki + Symulator Tunelu
                        Expanded(
                          flex: 11,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildWindTunnelStage(currentFit, evaluation),
                                const SizedBox(height: 16),
                                _buildAeroTelemetryCards(yawPoint, evaluation),
                                const SizedBox(height: 16),
                                WindTunnelCdaDeltaComparator(
                                  physiology: _selectedRider.physiology,
                                  currentFit: currentFit,
                                  currentBike: _activeBike,
                                  windSpeedKmh: _windSpeedKmh,
                                  onBikeChanged: (updatedBike) {
                                    setState(() => _activeBike = updatedBike);
                                  },
                                  onSpacersChanged: (newSpacers) {
                                    setState(() => _spacersStackMm = newSpacers);
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildJointSafetyAndComfortPanel(
                                    evaluation.biomechanicalImpact, currentFit),
                                const SizedBox(height: 16),
                                _buildWindTunnelSweepGraphCard(
                                    evaluation.windTunnelReport),
                              ],
                            ),
                          ),
                        ),

                        // Prawa część: Suwaki parametrów pozycji
                        Container(
                          width: 440,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildControlsPanel(currentFit, evaluation),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Wąski ekran (pionowy scroll)
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _buildWindTunnelStage(currentFit, evaluation),
                          const SizedBox(height: 14),
                          _buildAeroTelemetryCards(yawPoint, evaluation),
                          const SizedBox(height: 14),
                          WindTunnelCdaDeltaComparator(
                            physiology: _selectedRider.physiology,
                            currentFit: currentFit,
                            currentBike: _activeBike,
                            windSpeedKmh: _windSpeedKmh,
                            onBikeChanged: (updatedBike) {
                              setState(() => _activeBike = updatedBike);
                            },
                            onSpacersChanged: (newSpacers) {
                              setState(() => _spacersStackMm = newSpacers);
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildJointSafetyAndComfortPanel(
                              evaluation.biomechanicalImpact, currentFit),
                          const SizedBox(height: 14),
                          _buildWindTunnelSweepGraphCard(
                              evaluation.windTunnelReport),
                          const SizedBox(height: 16),
                          _buildControlsPanel(currentFit, evaluation),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // NAGŁÓWEK I WYBÓR KOLARZA
  // ===========================================================================

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          const titleRow = Row(
            children: [
              Icon(Icons.air_rounded, color: AppColors.cyanAccent, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'STUDIO BIKE FITTINGU & TUNEL AERODYNAMICZNY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Cyfrowy tunel aerodynamiczny WorldTour i analiza kinematyki stawów',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleRow,
                const SizedBox(height: 10),
                _buildRiderSelector(),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: titleRow),
              const SizedBox(width: 12),
              _buildRiderSelector(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRiderSelector() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedRider.id,
            dropdownColor: AppColors.surface,
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.cyanAccent),
            items: _squadRiders.map((rider) {
              return DropdownMenuItem<String>(
                value: rider.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RiderAvatarWidget(
                      appearance: rider.appearance,
                      size: 26,
                      showHelmet: true,
                      showGlasses: false,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        rider.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                    '(${rider.specialization.displayName})',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (riderId) {
            if (riderId == null) return;
            final rider = _squadRiders.firstWhere((r) => r.id == riderId);
            setState(() {
              _selectedRider = rider;
              _activeBike = _buildDefaultBikeForRider(rider);
              _applyFitToState(BikeFitConfiguration.proceduralForRider(
                heightCm: rider.physiology.heightCm,
                weightKg: rider.physiology.weightKg,
                isAeroFocus: true,
              ));
            });
          },
        ),
      ),
    ),
    );
  }

  // ===========================================================================
  // PASEK PRESETÓW (1-CLICK FIT PRESETS)
  // ===========================================================================

  Widget _buildPresetsBar(BikeFitConfiguration currentFit) {
    final presets = [
      (
        'Slammed Aero Road',
        Icons.flash_on_rounded,
        BikeFitConfiguration.slammedAeroRoad(),
        AppColors.cyanAccent,
      ),
      (
        'WorldTour Balanced',
        Icons.balance_rounded,
        BikeFitConfiguration.uciWorldTourBalanced(),
        AppColors.emeraldGreen,
      ),
      (
        'Climber Lightweight',
        Icons.terrain_rounded,
        BikeFitConfiguration.climberLightweight(),
        AppColors.goldAccent,
      ),
      (
        'Cobbled Endurance',
        Icons.view_comfortable_rounded,
        BikeFitConfiguration.cobbledEnduranceComfort(),
        AppColors.powerZone4,
      ),
      (
        'Time Trial Pursuit',
        Icons.speed_rounded,
        BikeFitConfiguration.timeTrialAeroPursuit(),
        AppColors.primaryAccent,
      ),
      (
        'Dopasuj do Kolarza',
        Icons.auto_fix_high_rounded,
        BikeFitConfiguration.proceduralForRider(
          heightCm: _selectedRider.physiology.heightCm,
          weightKg: _selectedRider.physiology.weightKg,
        ),
        AppColors.accentBlue,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: presets.map((item) {
            final title = item.$1;
            final icon = item.$2;
            final fit = item.$3;
            final color = item.$4;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(icon, color: color, size: 16),
                label: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                backgroundColor: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                onPressed: () => _applyFitToState(fit),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ===========================================================================
  // SCENA TUNELU AERODYNAMICZNEGO I KINEMATYKI KOLARZA
  // ===========================================================================

  Widget _buildWindTunnelStage(
    BikeFitConfiguration fit,
    BikeFitEvaluationReport evaluation,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pasek narzędziowy sceny tunelu (Sterowanie kamerą, pozycją korby i dymem)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded, color: AppColors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'KOMORA TESTOWA TUNELU AERODYNAMICZNEGO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_windSpeedKmh == 45.0) {
                            _windSpeedKmh = 50.0;
                          } else if (_windSpeedKmh == 50.0) {
                            _windSpeedKmh = 40.0;
                          } else {
                            _windSpeedKmh = 45.0;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.cyanAccent.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'V_WIND: ${_windSpeedKmh.toStringAsFixed(0)} KM/H',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.cyanAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    // Przełącznik strug dymu
                    FilterChip(
                      selected: _showSmokeStreamers,
                      label: const Text('Dym Tunelu'),
                      selectedColor: AppColors.cyanAccent.withValues(alpha: 0.25),
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: TextStyle(
                        fontSize: 10.5,
                        color: _showSmokeStreamers
                            ? AppColors.cyanAccent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (val) => setState(() => _showSmokeStreamers = val),
                    ),

                    // Przełącznik kątów biomechanicznych
                    FilterChip(
                      selected: _showJointAngleBadges,
                      label: const Text('Kąty Biomechaniczne'),
                      selectedColor: AppColors.goldAccent.withValues(alpha: 0.25),
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: TextStyle(
                        fontSize: 10.5,
                        color: _showJointAngleBadges
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (val) => setState(() => _showJointAngleBadges = val),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderColor),

          // Płótno graficzne symulacji (Kolarz + Rower + Dym + Kąty)
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return SizedBox(
                height: 380,
                width: double.infinity,
                child: CustomPaint(
                  painter: RiderBikeFitGeometryPainter(
                    fit: fit,
                    rider: _selectedRider,
                    bike: _activeBike,
                    crankMode: _crankMode,
                    animationPhase: _animController.value,
                    yawAngleDegrees: _yawAngleDegrees,
                    showSmokeStreamers: _showSmokeStreamers,
                    showJointAngleBadges: _showJointAngleBadges,
                    evaluationReport: evaluation,
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1, color: AppTheme.borderColor),

          // Dolna listwa sterowania fazą korby & kątem odchylenia Yaw (-15° do +15°)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // 1. Wybór fazy obrotu korby
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 8,
                  spacing: 8,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rotate_right_rounded,
                            color: AppColors.goldAccent, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Faza Obrotu Korby:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCrankModeChip(
                          mode: CrankKinematicMode.topDeadCenter,
                          label: 'GMP (TDC - 12:00) • Kąt Biodra',
                        ),
                        _buildCrankModeChip(
                          mode: CrankKinematicMode.powerPhase,
                          label: 'Faza Mocy (3:00)',
                        ),
                        _buildCrankModeChip(
                          mode: CrankKinematicMode.bottomDeadCenter,
                          label: 'DMP (BDC - 6:00) • Kąt Kolana',
                        ),
                        _buildCrankModeChip(
                          mode: CrankKinematicMode.animating,
                          label: 'Płynny Obrót (Animacja)',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Suwak Kąta Odchylenia Wiatru (Yaw Angle Slider: -15° do +15°)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 6,
                  spacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.explore_rounded,
                            color: AppColors.cyanAccent, size: 18),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KĄT NAWROTU WIATRU (YAW):',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${_yawAngleDegrees > 0 ? "+" : ""}${_yawAngleDegrees.toStringAsFixed(1)}° (${_getYawDescription(_yawAngleDegrees)})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _yawAngleDegrees.abs() >= 7.5 &&
                                        _yawAngleDegrees.abs() <= 12.5
                                    ? AppColors.cyanAccent
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(minWidth: 180, maxWidth: 320),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.cyanAccent,
                          inactiveTrackColor: AppColors.surfaceLight,
                          thumbColor: AppColors.cyanAccent,
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                        ),
                        child: Slider(
                          value: _yawAngleDegrees,
                          min: -15.0,
                          max: 15.0,
                          divisions: 60,
                          onChanged: (val) =>
                              setState(() => _yawAngleDegrees = val),
                        ),
                      ),
                    ),
                    // Przyciski szybkiego przeskoku do typowych kątów Yaw
                    Wrap(
                      spacing: 4,
                      children: [-10.0, 0.0, 7.5, 12.5].map((y) {
                        final isSel = (_yawAngleDegrees - y).abs() < 0.2;
                        return InkWell(
                          onTap: () => setState(() => _yawAngleDegrees = y),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.cyanAccent
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${y > 0 ? "+" : ""}${y.toStringAsFixed(1)}°',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isSel
                                    ? Colors.black
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildCrankModeChip({
    required CrankKinematicMode mode,
    required String label,
  }) {
    final isSelected = _crankMode == mode;
    return InkWell(
      onTap: () => setState(() => _crankMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.goldAccent.withValues(alpha: 0.22)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  static String _getYawDescription(double yaw) {
    final abs = yaw.abs();
    if (abs < 2.0) return 'Wiatr Czołowy';
    if (abs <= 6.0) return 'Lekki Wiatr Boczny';
    if (abs <= 12.5) return 'Sailing Effect / Sweet Spot';
    return 'Silny Wiatr Boczny (Turbulencja)';
  }

  // ===========================================================================
  // KARTY TELEMETRII AERODYNAMICZNEJ (CdA, MOC, DARMOWE WATY)
  // ===========================================================================

  Widget _buildAeroTelemetryCards(
    WindTunnelYawPoint yawPoint,
    BikeFitEvaluationReport evaluation,
  ) {
    final aero = evaluation.aeroReport;
    final double baselineCdA = aero.baselineCdA;
    final double fittedCdA = yawPoint.cda;
    final double cdaDeltaPercent = baselineCdA > 0
        ? ((fittedCdA - baselineCdA) / baselineCdA) * 100.0
        : 0.0;

    return Row(
      children: [
        // 1. Współczynnik oporu CdA
        _buildMetricPill(
          title: 'WSPÓŁCZYNNIK OPORU (CdA)',
          value: '${fittedCdA.toStringAsFixed(3)} m²',
          subValue:
              '${cdaDeltaPercent <= 0 ? "" : "+"}${cdaDeltaPercent.toStringAsFixed(1)}% vs Baza (${baselineCdA.toStringAsFixed(3)})',
          icon: Icons.air_rounded,
          accentColor: AppColors.cyanAccent,
        ),
        const SizedBox(width: 10),

        // 2. Wymagana moc w watach przy 45 km/h
        _buildMetricPill(
          title: 'WYMAGANA MOC @ 45 KM/H',
          value: '${yawPoint.aeroPowerWattsAt45Kmh.round()} W',
          subValue:
              'Siła czołowa: ${yawPoint.dragForceNewtonsAt45Kmh.toStringAsFixed(1)} N',
          icon: Icons.electric_bolt_rounded,
          accentColor: AppColors.goldAccent,
        ),
        const SizedBox(width: 10),

        // 3. Darmowe Waty (Oszczędność mocy)
        _buildMetricPill(
          title: 'DARMOWE WATY (FREE WATTS)',
          value: '+${aero.wattsSavedAt45Kmh} W',
          subValue: '@ 50 km/h: +${aero.wattsSavedAt50Kmh} W',
          icon: Icons.flash_on_rounded,
          accentColor: AppColors.emeraldGreen,
        ),
        const SizedBox(width: 10),

        // 4. Siła Boczna i Zysk Czasu
        _buildMetricPill(
          title: 'SIŁA BOCZNA & CZAS 40 KM',
          value: '${yawPoint.sideForceNewtonsAt45Kmh.toStringAsFixed(1)} N',
          subValue:
              'Czasówka 40km: -${aero.timeSavedSecondsOver40Km.round()} sek.',
          icon: Icons.timer_rounded,
          accentColor: AppColors.accentBlue,
        ),
      ],
    );
  }

  Widget _buildMetricPill({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subValue,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PANEL BEZPIECZEŃSTWA STAWÓW I KOMFORTU BIOMECHANICZNEGO
  // ===========================================================================

  Widget _buildJointSafetyAndComfortPanel(
    BiomechanicalFitImpact bio,
    BikeFitConfiguration fit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 8,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.health_and_safety_rounded,
                      color: AppColors.emeraldGreen, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'KOMFORT, ZDROWIE STAWÓW I SPADEK MOCY W GÓRACH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              // Status zgodności UCI
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: fit.isUciLegal
                      ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                      : AppColors.crimsonAlert.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: fit.isUciLegal
                        ? AppColors.emeraldGreen
                        : AppColors.crimsonAlert,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      fit.isUciLegal
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      color: fit.isUciLegal
                          ? AppColors.emeraldGreen
                          : AppColors.crimsonAlert,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fit.isUciLegal ? 'REGULAMIN UCI: ZGODNY' : 'NIELEGALNY (UCI)',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: fit.isUciLegal
                            ? AppColors.emeraldGreen
                            : AppColors.crimsonAlert,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Paski wskaźników ryzyka
          Row(
            children: [
              // 1. Ogólny Komfort
              Expanded(
                child: _buildRiskGauge(
                  label: 'Komfort Ogólny:',
                  score: bio.overallComfortIndex,
                  statusText: bio.overallComfortIndex >= 75
                      ? 'Wysoki (Brak bólu)'
                      : (bio.overallComfortIndex >= 55 ? 'Średni' : 'Niski'),
                  isFlipped: false, // Im wyżej tym lepiej
                ),
              ),
              const SizedBox(width: 16),

              // 2. Bezpieczeństwo Kolan (Ścięgno rzepki / ITB)
              Expanded(
                child: _buildRiskGauge(
                  label: 'Ryzyko Urazu Kolan:',
                  score: bio.kneeMicrotraumaRiskScore,
                  statusText: bio.kneeMicrotraumaRiskScore <= 35
                      ? 'Bezpieczne'
                      : (bio.kneeMicrotraumaRiskScore <= 60
                          ? 'Umiarkowane'
                          : 'Wysokie Ryzyko'),
                  isFlipped: true, // Im niżej tym lepiej
                ),
              ),
              const SizedBox(width: 16),

              // 3. Ryzyko Odcinka Lędźwiowego
              Expanded(
                child: _buildRiskGauge(
                  label: 'Przeciążenie Pleców:',
                  score: bio.lowerBackMicrotraumaRiskScore,
                  statusText: bio.lowerBackMicrotraumaRiskScore <= 35
                      ? 'Bezpieczne'
                      : (bio.lowerBackMicrotraumaRiskScore <= 60
                          ? 'Napięcie'
                          : 'Rwa / Przeciążenie'),
                  isFlipped: true,
                ),
              ),
              const SizedBox(width: 16),

              // 4. Spadek Mocy na Podjazdach (1-3%)
              Expanded(
                child: _buildClimbingPenaltyBadge(bio),
              ),
            ],
          ),

          // Komunikat ostrzegawczy jeśli występuje spadek mocy na podjazdach
          if (bio.climbingPowerPenaltyPercent > 0.0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amberWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.amberWarning.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: AppColors.amberWarning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zbyt agresywny kąt kokpitu dla mobilności kolarza (${bio.riderMobilityScore.round()}/100) ogranicza ruchomość klatki piersiowej i kompresuje przeponę: strata ${bio.climbingPowerPenaltyWatts.toStringAsFixed(0)} W (${bio.climbingPowerPenaltyPercent.toStringAsFixed(1)}%) na podjazdach powyżej 6%!',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.amberWarning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskGauge({
    required String label,
    required double score,
    required String statusText,
    required bool isFlipped,
  }) {
    // Normalizacja do koloru: jeśli isFlipped (ryzyko), to 0 = zielony, 100 = czerwony
    final Color barColor;
    if (isFlipped) {
      barColor = score <= 35
          ? AppColors.emeraldGreen
          : (score <= 60 ? AppColors.amberWarning : AppColors.crimsonAlert);
    } else {
      barColor = score >= 70
          ? AppColors.emeraldGreen
          : (score >= 50 ? AppColors.amberWarning : AppColors.crimsonAlert);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100.0).clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildClimbingPenaltyBadge(BiomechanicalFitImpact bio) {
    final hasPenalty = bio.climbingPowerPenaltyPercent > 0.0;
    final color = hasPenalty ? AppColors.crimsonAlert : AppColors.emeraldGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            const Text(
              'Kara Mocy w Górach:',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              hasPenalty
                  ? '-${bio.climbingPowerPenaltyPercent.toStringAsFixed(1)}%'
                  : '0.0% (Optimum)',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hasPenalty
                ? (bio.climbingPowerPenaltyPercent / 3.0).clamp(0.0, 1.0)
                : 0.0,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // WYKRES BADAŃ TUNELOWYCH (POLAR SWEEP: CdA vs YAW ANGLE)
  // ===========================================================================

  Widget _buildWindTunnelSweepGraphCard(WindTunnelPolarReport polarReport) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 6,
            spacing: 8,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart_rounded,
                      color: AppColors.cyanAccent, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'POLARNA KRZYWA OPORU W TUNELU (CdA vs KĄT YAW)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.cyanAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Efekt Żagla (Sailing Effect)',
                    style: TextStyle(fontSize: 10, color: AppColors.cyanAccent),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Wykres w CustomPainter
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: WindTunnelPolarChartPainter(
                report: polarReport,
                currentYawDegrees: _yawAngleDegrees,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PANEL BOCZNY: SUWAKI WSZYSTKICH PARAMETRÓW POZYCJI
  // ===========================================================================

  Widget _buildControlsPanel(
    BikeFitConfiguration fit,
    BikeFitEvaluationReport evaluation,
  ) {
    final phys = _selectedRider.physiology;
    final recommendedSaddle = (phys.heightCm * 10 * 0.465 * 0.883).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 10,
          spacing: 10,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_suggest_rounded,
                    color: AppColors.goldAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'STUDIO BIKE FITTINGU',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 14),
              label: const Text('Zapisz Fitting', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _saveBikeFitConfiguration(fit);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ---------------------------------------------------------------------
        // 1. WYSOKOŚĆ I GEOMETRIA SIODŁA
        // ---------------------------------------------------------------------
        _buildSectionHeader('1. STREFA SIODEŁKA (SADDLE)', Icons.chair_alt_rounded),
        const SizedBox(height: 10),

        // Wysokość siodła
        _buildSliderTile(
          label: 'Wysokość siodła (BB Center):',
          valueDisplay: '${_saddleHeightMm.round()} mm',
          subLabel: 'Wzór LeMonda ~${recommendedSaddle}mm',
          value: _saddleHeightMm,
          min: 640.0,
          max: 880.0,
          divisions: 240,
          accentColor: AppColors.cyanAccent,
          onChanged: (val) => setState(() => _saddleHeightMm = val),
        ),

        // Kąt pochylenia siodła
        _buildSliderTile(
          label: 'Kąt nachylenia siodła (Tilt):',
          valueDisplay:
              '${_saddleTiltDegrees.toStringAsFixed(1)}° (${_saddleTiltDegrees < 0 ? "Nos w dół" : "Poziom"})',
          subLabel: 'Norma UCI: max ±9.0°',
          value: _saddleTiltDegrees,
          min: -6.0,
          max: 2.0,
          divisions: 16,
          accentColor: AppColors.goldAccent,
          onChanged: (val) => setState(() => _saddleTiltDegrees = val),
        ),

        // Cofnięcie siodła (Setback)
        _buildSliderTile(
          label: 'Cofnięcie siodła (Setback):',
          valueDisplay: '${_saddleSetbackMm.toStringAsFixed(1)} mm',
          subLabel: _saddleSetbackMm < 50.0
              ? 'Wymaga ulgi morfologicznej UCI (<50mm)'
              : 'Standard UCI ≥50mm',
          value: _saddleSetbackMm,
          min: 35.0,
          max: 85.0,
          divisions: 50,
          accentColor: AppColors.accentBlue,
          onChanged: (val) => setState(() => _saddleSetbackMm = val),
        ),

        const SizedBox(height: 16),

        // ---------------------------------------------------------------------
        // 2. KOKPIT, MOSTEK I ROTACJA KLAMEK
        // ---------------------------------------------------------------------
        _buildSectionHeader(
            '2. KOKPIT, MOSTEK I KLAMKI', Icons.directions_bike_rounded),
        const SizedBox(height: 10),

        // Szerokość kokpitu (360 - 440 mm)
        const Text(
          'Szerokość kierownicy (Cockpit):',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [360, 380, 400, 420, 440].map((w) {
            final isSelected = _cockpitWidthMm == w;
            return ChoiceChip(
              label: Text('$w mm'),
              selected: isSelected,
              selectedColor: AppColors.cyanAccent,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.black : AppColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _cockpitWidthMm = w),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Podkładki pod mostkiem (0 mm = Slammed)
        const Text(
          'Podkładki pod mostek (Spacers Stack):',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [0, 5, 10, 15, 20, 30].map((s) {
            final isSelected = _spacersStackMm == s;
            final label = s == 0 ? '0 mm (Slammed)' : '$s mm';
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.cyanAccent,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.black : AppColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _spacersStackMm = s),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Długość mostka
        const Text(
          'Długość mostka (Stem Length):',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [90, 100, 110, 120, 130, 140].map((st) {
            final isSelected = _stemLengthMm == st;
            return ChoiceChip(
              label: Text('$st mm'),
              selected: isSelected,
              selectedColor: AppColors.goldAccent,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.black : AppColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _stemLengthMm = st),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Rotacja klamkomanetek (0° do 35° pod puppy paws)
        _buildSliderTile(
          label: 'Rotacja klamek do środka (Inward Tilt):',
          valueDisplay:
              '${_hoodInwardTiltDegrees.toStringAsFixed(1)}° (${_hoodInwardTiltDegrees > 14.0 ? "Aero Puppy Paws" : "Legalne UCI"})',
          subLabel: _hoodInwardTiltDegrees > 14.0
              ? 'Przekracza limit UCI 14.0°!'
              : 'Zgodne z limitem UCI 14°',
          value: _hoodInwardTiltDegrees,
          min: 0.0,
          max: 35.0,
          divisions: 35,
          accentColor: _hoodInwardTiltDegrees > 14.0
              ? AppColors.crimsonAlert
              : AppColors.cyanAccent,
          onChanged: (val) => setState(() => _hoodInwardTiltDegrees = val),
        ),

        const SizedBox(height: 16),

        // ---------------------------------------------------------------------
        // 3. KORBY I PEDAŁOWANIE
        // ---------------------------------------------------------------------
        _buildSectionHeader(
            '3. DŁUGOŚĆ KORB I BLOKI', Icons.pedal_bike_rounded),
        const SizedBox(height: 10),

        // Długość ramion korby
        const Text(
          'Długość ramion korby (Crank Arm):',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [165.0, 167.5, 170.0, 172.5, 175.0].map((c) {
            final isSelected = _crankArmLengthMm == c;
            return ChoiceChip(
              label: Text('${c.toStringAsFixed(1)} mm'),
              selected: isSelected,
              selectedColor: AppColors.goldAccent,
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.black : AppColors.textPrimary,
              ),
              onSelected: (_) => setState(() => _crankArmLengthMm = c),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Przesunięcie bloków
        _buildSliderTile(
          label: 'Przesunięcie bloków w butach (Cleats):',
          valueDisplay:
              '${_cleatOffsetMm > 0 ? "+" : ""}${_cleatOffsetMm.toStringAsFixed(1)} mm',
          subLabel: _cleatOffsetMm < -2.0
              ? 'Mid-foot (Odciążenie łydki i Achillesa)'
              : 'Dźwignia sprintu / Neutralne',
          value: _cleatOffsetMm,
          min: -10.0,
          max: 10.0,
          divisions: 20,
          accentColor: AppColors.accentBlue,
          onChanged: (val) => setState(() => _cleatOffsetMm = val),
        ),

        const SizedBox(height: 18),

        // ---------------------------------------------------------------------
        // 4. PORADY TRENERA I BIKE FITTERA
        // ---------------------------------------------------------------------
        _buildCoachingAdviceCard(evaluation.coachingAdvice),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cyanAccent, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required String label,
    required String valueDisplay,
    required String subLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color accentColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              valueDisplay,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: accentColor,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Text(
          subLabel,
          style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildCoachingAdviceCard(List<String> adviceList) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppColors.goldAccent, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'RAPORT EKSPERCKI TUNELU I BIKE FITTERA',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.goldAccent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...adviceList.take(3).map((advice) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(
                          color: AppColors.cyanAccent,
                          fontWeight: FontWeight.w900)),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _saveBikeFitConfiguration(BikeFitConfiguration fit) {
    _activeBike = _activeBike.applyBikeFit(fit);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Zapisano fitting dla ${_selectedRider.fullName}! Zysk: +${fit.estimatedWattsSavedAt45Kmh} W @ 45 km/h.',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.cyanAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static WindTunnelYawPoint _getYawPointForAngle(
    WindTunnelPolarReport report,
    double angle,
    BikeFitConfiguration fit,
  ) {
    if (report.points.isEmpty) {
      return const WindTunnelYawPoint(
        yawDegrees: 0.0,
        cda: 0.220,
        dragForceNewtonsAt45Kmh: 24.0,
        sideForceNewtonsAt45Kmh: 0.0,
        aeroPowerWattsAt45Kmh: 285.0,
      );
    }

    // Znajdź najbliższy punkt pomiarowy lub interpoluj
    WindTunnelYawPoint closest = report.points.first;
    double minDiff = (closest.yawDegrees - angle).abs();

    for (final p in report.points) {
      final diff = (p.yawDegrees - angle).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = p;
      }
    }
    return closest;
  }
}

// =============================================================================
// PAINTER: WIZUALIZACJA KINEMATYKI KOLARZA NA ROWERZE W TUNELU
// =============================================================================

/// Rysuje rower, anatomiczną sylwetkę kolarza, łuki kątowe stawów
/// oraz strugi dymu tunelu aerodynamicznego w znormalizowanym układzie 520x360.
class RiderBikeFitGeometryPainter extends CustomPainter {
  final BikeFitConfiguration fit;
  final Rider rider;
  final CompleteBike bike;
  final CrankKinematicMode crankMode;
  final double animationPhase;
  final double yawAngleDegrees;
  final bool showSmokeStreamers;
  final bool showJointAngleBadges;
  final BikeFitEvaluationReport evaluationReport;

  RiderBikeFitGeometryPainter({
    required this.fit,
    required this.rider,
    required this.bike,
    required this.crankMode,
    required this.animationPhase,
    required this.yawAngleDegrees,
    required this.showSmokeStreamers,
    required this.showJointAngleBadges,
    required this.evaluationReport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Skalowanie z zachowaniem proporcji do wirtualnego okna 520x360
    final double scale = math.min(size.width / 520.0, size.height / 360.0);
    final double offsetX = (size.width - 520.0 * scale) / 2.0;
    final double offsetY = (size.height - 360.0 * scale) / 2.0;

    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    // 1. Tło komory tunelu: siatka telemetryczna i dysza nadmuchu
    _drawTunnelBackground(canvas);

    // 2. Kąt obrotu korby w zależności od wybranego trybu
    double crankAngleRad;
    switch (crankMode) {
      case CrankKinematicMode.topDeadCenter:
        crankAngleRad = -math.pi / 2.0; // 12:00
        break;
      case CrankKinematicMode.powerPhase:
        crankAngleRad = 0.0; // 3:00
        break;
      case CrankKinematicMode.bottomDeadCenter:
        crankAngleRad = math.pi / 2.0; // 6:00
        break;
      case CrankKinematicMode.animating:
        crankAngleRad = (animationPhase * 2.0 * math.pi) - (math.pi / 2.0);
        break;
    }

    // 3. Strugi dymu aerodynamicznego przed kolarzem (warstwa dolna)
    if (showSmokeStreamers) {
      _drawSmokeStreamlines(canvas, isForeground: false);
    }

    // 4. Rower wyścigowy (Koła, rama, kokpit, korba)
    final bikePoints = _calculateBikePoints();
    _drawBicycle(canvas, bikePoints, crankAngleRad);

    // 5. Sylwetka kolarza (Biodro, tułów, ramiona, głowa, kask, nogi)
    final riderKinematics = _calculateRiderKinematics(bikePoints, crankAngleRad);
    _drawCyclist(canvas, riderKinematics);

    // 6. Strugi dymu aerodynamicznego nad kolarzem (warstwa górna)
    if (showSmokeStreamers) {
      _drawSmokeStreamlines(canvas, isForeground: true);
    }

    // 7. Łuki i etykiety kątowe (Kąt biodra, kąt kolana, kąt tułowia)
    if (showJointAngleBadges) {
      _drawJointAngleOverlays(canvas, riderKinematics);
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // A. OBLICZENIA GEOMETRII ROWERU
  // ---------------------------------------------------------------------------

  _BikeGeometryPoints _calculateBikePoints() {
    // Współrzędne wirtualne (oś X od lewej do prawej, jazda w prawo)
    const double rearAxleX = 110.0;
    const double rearAxleY = 270.0;
    const double frontAxleX = 420.0;
    const double frontAxleY = 270.0;

    // Suport (Bottom Bracket - BB)
    const double bbX = 230.0;
    const double bbY = 280.0;

    // Rura podsiodłowa (Seat Tube ~73.5°)
    const double seatTubeAngleRad = 73.5 * math.pi / 180.0;
    final double saddleHeightScale = 175.0 + (fit.saddleHeightMm - 740.0) * 0.22;

    // Pozycja siodła
    final double rawSaddleX = bbX - (saddleHeightScale * math.cos(seatTubeAngleRad));
    final double rawSaddleY = bbY - (saddleHeightScale * math.sin(seatTubeAngleRad));

    // Korekta cofnięcia siodła (Setback) i pochylenia (Tilt)
    final double saddleX = rawSaddleX - ((fit.saddleSetbackMm - 50.0) * 0.4);
    final double saddleY = rawSaddleY;

    // Główka ramy (Head Tube) i Mostek (Stem)
    const double headTubeTopX = 365.0;
    const double headTubeTopY = 145.0;

    // Podkładki pod mostkiem (0 mm = Slammed stem)
    final double spacersOffset = fit.spacersStackMm * 0.5;
    final double stemClampX = headTubeTopX - (spacersOffset * 0.3);
    final double stemClampY = headTubeTopY - spacersOffset;

    // Mostek (długość 90-140mm, kąt -6°)
    final double stemLengthScale = fit.stemLengthMm * 0.35;
    final double stemEndX = stemClampX + stemLengthScale * math.cos(0.08);
    final double stemEndY = stemClampY + stemLengthScale * math.sin(0.08);

    // Klamkomanetki (Hoods)
    final double hoodInwardEffect = fit.hoodInwardTiltDegrees * 0.25;
    final double hoodsX = stemEndX + 22.0 - hoodInwardEffect;
    final double hoodsY = stemEndY - 6.0;

    return _BikeGeometryPoints(
      rearAxle: const Offset(rearAxleX, rearAxleY),
      frontAxle: const Offset(frontAxleX, frontAxleY),
      bb: const Offset(bbX, bbY),
      saddleCenter: Offset(saddleX, saddleY),
      stemClamp: Offset(stemClampX, stemClampY),
      handlebarClamp: Offset(stemEndX, stemEndY),
      hoodsContact: Offset(hoodsX, hoodsY),
    );
  }

  // ---------------------------------------------------------------------------
  // B. OBLICZENIA KINEMATYKI KOLARZA (ODWRÓCONA KINEMATYKA STAWÓW)
  // ---------------------------------------------------------------------------

  _RiderKinematics _calculateRiderKinematics(
    _BikeGeometryPoints bikePts,
    double crankAngleRad,
  ) {
    // 1. Punkt biodra (Hip) - zlokalizowany na siodle
    final Offset hip = Offset(
      bikePts.saddleCenter.dx + 4.0,
      bikePts.saddleCenter.dy - 12.0,
    );

    // 2. Dłonie (Hands) - na klamkomanetkach
    final Offset hand = bikePts.hoodsContact;

    // 3. Pozycja pedału i kostki (Ankle)
    final double crankLengthPx = fit.crankArmLengthMm * 0.22;
    final double pedalX = bikePts.bb.dx + crankLengthPx * math.cos(crankAngleRad);
    final double pedalY = bikePts.bb.dy + crankLengthPx * math.sin(crankAngleRad);

    // Kąt stopy i przesunięcie bloków
    final double cleatOffsetPx = fit.cleatOffsetMm * 0.3;
    final Offset ankle = Offset(pedalX - 6.0 + cleatOffsetPx, pedalY - 14.0);

    // 4. Kinematyka nogi: Staw kolanowy (Knee) za pomocą 2-ogniwowej kinematyki odwrotnej
    const double femurLength = 82.0; // Udo
    const double tibiaLength = 76.0; // Podudzie

    final double distHipAnkle = (ankle - hip).distance.clamp(10.0, femurLength + tibiaLength - 2.0);
    final double cosAlpha = ((femurLength * femurLength + distHipAnkle * distHipAnkle - tibiaLength * tibiaLength) /
            (2.0 * femurLength * distHipAnkle))
        .clamp(-1.0, 1.0);
    final double angleAlpha = math.acos(cosAlpha);
    final double baseAngle = math.atan2(ankle.dy - hip.dy, ankle.dx - hip.dx);

    // Kolano ugina się do przodu (dodajemy kąt alpha)
    final double kneeAngleGlobal = baseAngle + angleAlpha;
    final Offset knee = Offset(
      hip.dx + femurLength * math.cos(kneeAngleGlobal),
      hip.dy + femurLength * math.sin(kneeAngleGlobal),
    );

    // 5. Tułów i Ramię: Bark (Shoulder), Łokieć (Elbow) i Głowa/Kask
    // Kąt tułowia zależy od wysokości siodła i mostka
    final double dropSaddleToBars = bikePts.hoodsContact.dy - hip.dy;
    final double reach = bikePts.hoodsContact.dx - hip.dx;
    final double torsoAngleRad = math.atan2(dropSaddleToBars, reach);

    const double torsoLength = 85.0;
    final Offset shoulder = Offset(
      hip.dx + torsoLength * math.cos(torsoAngleRad * 0.85),
      hip.dy + torsoLength * math.sin(torsoAngleRad * 0.85),
    );

    // Łokieć (naturalne zgięcie w stronę chwytów, większe przy podgiętych klamkach)
    const double upperArmLength = 48.0;
    const double forearmLength = 46.0;
    final double distShoulderHand = (hand - shoulder).distance.clamp(10.0, upperArmLength + forearmLength - 2.0);
    final double cosElbow = ((upperArmLength * upperArmLength + distShoulderHand * distShoulderHand - forearmLength * forearmLength) /
            (2.0 * upperArmLength * distShoulderHand))
        .clamp(-1.0, 1.0);
    final double elbowAngleAlpha = math.acos(cosElbow);
    final double armBaseAngle = math.atan2(hand.dy - shoulder.dy, hand.dx - shoulder.dx);

    final double elbowGlobal = armBaseAngle + elbowAngleAlpha;
    final Offset elbow = Offset(
      shoulder.dx + upperArmLength * math.cos(elbowGlobal),
      shoulder.dy + upperArmLength * math.sin(elbowGlobal),
    );

    // Głowa i Kask Aero
    final Offset headCenter = Offset(shoulder.dx + 22.0, shoulder.dy - 12.0);

    // 6. Dokładne wyliczenie kątów stawowych
    // Kąt biodra: między wektorem (Hip -> Shoulder) a (Hip -> Knee)
    final Offset vTorso = shoulder - hip;
    final Offset vFemur = knee - hip;
    final double hipDot = (vTorso.dx * vFemur.dx + vTorso.dy * vFemur.dy) /
        (vTorso.distance * vFemur.distance);
    final double hipAngleDeg = math.acos(hipDot.clamp(-1.0, 1.0)) * 180.0 / math.pi;

    // Kąt kolana: wyprost między (Knee -> Hip) a (Knee -> Ankle)
    final Offset vKneeHip = hip - knee;
    final Offset vKneeAnkle = ankle - knee;
    final double kneeDot = (vKneeHip.dx * vKneeAnkle.dx + vKneeHip.dy * vKneeAnkle.dy) /
        (vKneeHip.distance * vKneeAnkle.distance);
    final double kneeAngleDeg = math.acos(kneeDot.clamp(-1.0, 1.0)) * 180.0 / math.pi;

    // Kąt pochylenia tułowia względem poziomu
    final double torsoAngleDeg = (-vTorso.dy / vTorso.dx).abs() > 0
        ? math.atan2(-vTorso.dy, vTorso.dx) * 180.0 / math.pi
        : 22.0;

    return _RiderKinematics(
      hip: hip,
      knee: knee,
      ankle: ankle,
      pedal: Offset(pedalX, pedalY),
      shoulder: shoulder,
      elbow: elbow,
      hand: hand,
      headCenter: headCenter,
      hipAngleDegrees: hipAngleDeg,
      kneeAngleDegrees: kneeAngleDeg,
      torsoAngleDegrees: torsoAngleDeg,
    );
  }

  // ---------------------------------------------------------------------------
  // C. RYSOWANIE TŁA TUNELU
  // ---------------------------------------------------------------------------

  void _drawTunnelBackground(Canvas canvas) {
    // Siatka podłogowa i metryczna
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2433).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    for (double x = 40.0; x <= 480.0; x += 40.0) {
      canvas.drawLine(Offset(x, 40), Offset(x, 320), gridPaint);
    }
    for (double y = 60.0; y <= 320.0; y += 40.0) {
      canvas.drawLine(Offset(40, y), Offset(480, y), gridPaint);
    }

    // Podłoże / Rolki trenażera tunelu
    final floorPaint = Paint()
      ..color = const Color(0xFF161A24)
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(20, 316, 480, 20), floorPaint);

    final floorLinePaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(20, 316), const Offset(500, 316), floorLinePaint);
  }

  // ---------------------------------------------------------------------------
  // D. RYSOWANIE ROWERU
  // ---------------------------------------------------------------------------

  void _drawBicycle(
    Canvas canvas,
    _BikeGeometryPoints pts,
    double crankAngleRad,
  ) {
    const double wheelRadius = 46.0;

    // Koła (Obręcze karbonowe 60mm)
    final rimPaint = Paint()
      ..color = const Color(0xFF1A1C23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    final tirePaint = Paint()
      ..color = const Color(0xFF0F1015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    for (final axle in [pts.rearAxle, pts.frontAxle]) {
      // Opona i obręcz
      canvas.drawCircle(axle, wheelRadius, rimPaint);
      canvas.drawCircle(axle, wheelRadius + 3.0, tirePaint);

      // Szprychy aero
      for (int i = 0; i < 12; i++) {
        final double a = (i * 30.0) * math.pi / 180.0;
        canvas.drawLine(
          axle,
          Offset(axle.dx + wheelRadius * math.cos(a), axle.dy + wheelRadius * math.sin(a)),
          spokePaint,
        );
      }
      // Oś / Piasta
      canvas.drawCircle(axle, 5.0, Paint()..color = const Color(0xFF404554));
    }

    // Rama rowerowa
    final frameColor = _parseColor(bike.frame.primaryColorHex, AppColors.cyanAccent);
    final framePaint = Paint()
      ..color = frameColor
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final darkFramePaint = Paint()
      ..color = const Color(0xFF141720)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Trójkąt tylny: Widełki podsiodłowe i łańcuchowe
    canvas.drawLine(pts.rearAxle, pts.bb, darkFramePaint);
    canvas.drawLine(pts.rearAxle, Offset(pts.saddleCenter.dx + 4, pts.saddleCenter.dy + 35), darkFramePaint);

    // Trójkąt główny: Rura podsiodłowa, ukośna (Down Tube), pozioma (Top Tube)
    final Offset seatJunction = Offset(pts.saddleCenter.dx + 4, pts.saddleCenter.dy + 35);
    final Offset headJunction = Offset(pts.stemClamp.dx + 4, pts.stemClamp.dy + 25);

    canvas.drawLine(pts.bb, seatJunction, framePaint);
    canvas.drawLine(pts.bb, headJunction, framePaint);
    canvas.drawLine(seatJunction, headJunction, framePaint);

    // Widelec przedni
    canvas.drawLine(headJunction, pts.frontAxle, framePaint);

    // Sztyca podsiodłowa i siodło
    final seatpostPaint = Paint()
      ..color = const Color(0xFF2B303C)
      ..strokeWidth = 5.0;
    canvas.drawLine(seatJunction, pts.saddleCenter, seatpostPaint);

    // Siodło (z kątem pochylenia Tilt)
    canvas.save();
    canvas.translate(pts.saddleCenter.dx, pts.saddleCenter.dy);
    canvas.rotate(fit.saddleTiltDegrees * math.pi / 180.0);
    final saddlePath = Path()
      ..moveTo(-18, 0)
      ..lineTo(14, 0)
      ..quadraticBezierTo(20, 2, 22, 6)
      ..lineTo(-16, 5)
      ..close();
    canvas.drawPath(saddlePath, Paint()..color = const Color(0xFF1E2028));
    canvas.restore();

    // Mostek i kierownica (Cockpit)
    final cockpitPaint = Paint()
      ..color = const Color(0xFF2B303C)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pts.stemClamp, pts.handlebarClamp, cockpitPaint);

    // Dropy kierownicy i klamki
    final dropPath = Path()
      ..moveTo(pts.handlebarClamp.dx, pts.handlebarClamp.dy)
      ..quadraticBezierTo(
        pts.handlebarClamp.dx + 16,
        pts.handlebarClamp.dy - 4,
        pts.hoodsContact.dx,
        pts.hoodsContact.dy,
      )
      ..quadraticBezierTo(
        pts.hoodsContact.dx + 8,
        pts.hoodsContact.dy + 18,
        pts.handlebarClamp.dx - 8,
        pts.hoodsContact.dy + 24,
      );
    canvas.drawPath(
      dropPath,
      Paint()
        ..color = const Color(0xFF181B22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );

    // Tarcza napędu (Chainring 54T)
    canvas.drawCircle(pts.bb, 18.0, Paint()..color = const Color(0xFF262A36));

    // Ramię korby
    final double crankLen = fit.crankArmLengthMm * 0.22;
    final Offset pedalPos = Offset(
      pts.bb.dx + crankLen * math.cos(crankAngleRad),
      pts.bb.dy + crankLen * math.sin(crankAngleRad),
    );
    canvas.drawLine(
      pts.bb,
      pedalPos,
      Paint()
        ..color = const Color(0xFF6B7280)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    // Pedał zatrzaskowy
    canvas.drawRect(
      Rect.fromCenter(center: pedalPos, width: 10, height: 4),
      Paint()..color = const Color(0xFF374151),
    );
  }

  // ---------------------------------------------------------------------------
  // E. RYSOWANIE SYLWETKI KOLARZA
  // ---------------------------------------------------------------------------

  void _drawCyclist(Canvas canvas, _RiderKinematics kin) {
    // Styl sylwetki - nowoczesny cyber/aero kombinezon
    final suitPaint = Paint()
      ..color = const Color(0xFF1F2430)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final limbPaint = Paint()
      ..color = const Color(0xFF2C3242)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final skinPaint = Paint()
      ..color = const Color(0xFFD4A373)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    // 1. Noga: Udo (Femur) i Podudzie (Tibia)
    canvas.drawLine(kin.hip, kin.knee, limbPaint);
    canvas.drawLine(kin.knee, kin.ankle, limbPaint);

    // But rowerowy aero
    final shoePath = Path()
      ..moveTo(kin.ankle.dx - 4, kin.ankle.dy)
      ..lineTo(kin.pedal.dx + 10, kin.pedal.dy + 2)
      ..lineTo(kin.pedal.dx - 12, kin.pedal.dy + 2)
      ..close();
    canvas.drawPath(shoePath, Paint()..color = Colors.white);

    // 2. Tułów (Klatka piersiowa i brzuch)
    final torsoPath = Path()
      ..moveTo(kin.hip.dx - 6, kin.hip.dy - 6)
      ..lineTo(kin.shoulder.dx + 2, kin.shoulder.dy - 8)
      ..lineTo(kin.shoulder.dx - 4, kin.shoulder.dy + 8)
      ..lineTo(kin.hip.dx + 4, kin.hip.dy + 8)
      ..close();
    canvas.drawPath(torsoPath, suitPaint..color = const Color(0xFF1E2330));

    // Linia kręgosłupa
    canvas.drawLine(
      kin.hip,
      kin.shoulder,
      Paint()
        ..color = AppColors.cyanAccent.withValues(alpha: 0.3)
        ..strokeWidth = 2.0,
    );

    // 3. Ręka: Ramię (Shoulder -> Elbow) i Przedramię (Elbow -> Hand)
    canvas.drawLine(kin.shoulder, kin.elbow, limbPaint);
    canvas.drawLine(kin.elbow, kin.hand, skinPaint);

    // Rękawiczka aero
    canvas.drawCircle(kin.hand, 5.0, Paint()..color = const Color(0xFF11141B));

    // 4. Kask Aero z owiewką i ogonem (Teardrop shape)
    canvas.save();
    canvas.translate(kin.headCenter.dx, kin.headCenter.dy);
    final helmetPath = Path()
      ..moveTo(-16, -6) // Ogon kasku leżący na karku
      ..quadraticBezierTo(2, -18, 14, -6) // Czubek kasku
      ..quadraticBezierTo(18, 2, 10, 8) // Osłona czoła / wizjer
      ..lineTo(-6, 6)
      ..close();

    canvas.drawPath(helmetPath, Paint()..color = AppColors.cyanAccent);

    // Wizjer aerodynamiczny
    final visorPath = Path()
      ..moveTo(10, -4)
      ..quadraticBezierTo(16, 2, 8, 8)
      ..close();
    canvas.drawPath(visorPath, Paint()..color = const Color(0xFF0F172A));
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // F. STRUGI DYMU W TUNELU AERODYNAMICZNYM
  // ---------------------------------------------------------------------------

  void _drawSmokeStreamlines(Canvas canvas, {required bool isForeground}) {
    // 6 strug dymu opływających kask, plecy, suport i koła
    final List<double> streamHeights = isForeground
        ? [80.0, 120.0, 160.0]
        : [195.0, 240.0, 275.0];

    final double phase = animationPhase;
    final double yawRad = (yawAngleDegrees * math.pi / 180.0) * 0.25;

    for (int i = 0; i < streamHeights.length; i++) {
      final double baseY = streamHeights[i];
      final Path path = Path();
      path.moveTo(30.0, baseY);

      // Trajektoria fali opływu wokół sylwetki
      for (double x = 30.0; x <= 490.0; x += 15.0) {
        // Odchylenie zależne od kąta Yaw
        final double yawDrift = (x - 200.0) * math.tan(yawRad);

        // Deformacja wokół kasku / pleców
        double obstructionDeflect = 0.0;
        if (baseY < 140.0 && x > 300.0 && x < 420.0) {
          obstructionDeflect = -18.0 * math.sin((x - 300.0) / 120.0 * math.pi);
        } else if (baseY >= 140.0 && baseY < 210.0 && x > 200.0 && x < 360.0) {
          obstructionDeflect = -12.0 * math.sin((x - 200.0) / 160.0 * math.pi);
        }

        final double y = baseY + yawDrift + obstructionDeflect;
        path.lineTo(x, y);
      }

      // Rysowanie świecącej strugi z efektem przepływu
      final double alpha = isForeground ? 0.45 : 0.25;
      final smokePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.cyanAccent.withValues(alpha: 0.0),
            AppColors.cyanAccent.withValues(alpha: alpha),
            AppColors.accentBlue.withValues(alpha: alpha * 0.7),
            AppColors.cyanAccent.withValues(alpha: 0.0),
          ],
          stops: [
            (phase - 0.3).clamp(0.0, 1.0),
            phase,
            (phase + 0.3).clamp(0.0, 1.0),
            1.0,
          ],
        ).createShader(const Rect.fromLTWH(30, 0, 460, 360))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isForeground ? 2.5 : 1.8;

      canvas.drawPath(path, smokePaint);
    }
  }

  // ---------------------------------------------------------------------------
  // G. ŁUKI I ODZNACZENIA KĄTÓW BIOMECHANICZNYCH
  // ---------------------------------------------------------------------------

  void _drawJointAngleOverlays(Canvas canvas, _RiderKinematics kin) {
    // 1. KĄT BIODRA (Wokół stawu biodrowego)
    final Color hipColor = kin.hipAngleDegrees >= 60.0
        ? AppColors.emeraldGreen
        : (kin.hipAngleDegrees >= 55.0
            ? AppColors.goldAccent
            : AppColors.crimsonAlert);

    _drawAngleArc(
      canvas: canvas,
      center: kin.hip,
      radius: 24.0,
      startAngle: math.atan2(kin.knee.dy - kin.hip.dy, kin.knee.dx - kin.hip.dx),
      sweepAngle: -kin.hipAngleDegrees * math.pi / 180.0,
      color: hipColor,
    );

    _drawAngleBadge(
      canvas: canvas,
      position: Offset(kin.hip.dx - 65, kin.hip.dy - 35),
      label: 'BIODRO: ${kin.hipAngleDegrees.toStringAsFixed(1)}°',
      subLabel: kin.hipAngleDegrees >= 60.0 ? 'Optymalny' : 'Ciasny (Kara W)',
      color: hipColor,
    );

    // 2. KĄT KOLANA (Wokół stawu kolanowego)
    final Color kneeColor = (kin.kneeAngleDegrees >= 138.0 && kin.kneeAngleDegrees <= 147.0)
        ? AppColors.emeraldGreen
        : (kin.kneeAngleDegrees >= 134.0 && kin.kneeAngleDegrees <= 150.0
            ? AppColors.goldAccent
            : AppColors.crimsonAlert);

    _drawAngleArc(
      canvas: canvas,
      center: kin.knee,
      radius: 20.0,
      startAngle: math.atan2(kin.ankle.dy - kin.knee.dy, kin.ankle.dx - kin.knee.dx),
      sweepAngle: kin.kneeAngleDegrees * math.pi / 180.0,
      color: kneeColor,
    );

    _drawAngleBadge(
      canvas: canvas,
      position: Offset(kin.knee.dx + 18, kin.knee.dy - 12),
      label: 'KOLANO: ${kin.kneeAngleDegrees.toStringAsFixed(1)}°',
      subLabel: (kin.kneeAngleDegrees >= 138.0 && kin.kneeAngleDegrees <= 147.0)
          ? 'Wyprost OK'
          : 'Ryzyko Rzepki',
      color: kneeColor,
    );

    // 3. KĄT POCHYLENIA TUŁOWIA (Tułów / Kręgosłup)
    _drawAngleBadge(
      canvas: canvas,
      position: Offset(kin.shoulder.dx - 55, kin.shoulder.dy - 40),
      label: 'TUŁÓW: ${kin.torsoAngleDegrees.toStringAsFixed(1)}°',
      subLabel: 'Pozycja Aero',
      color: AppColors.cyanAccent,
    );
  }

  void _drawAngleArc({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required Color color,
  }) {
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Wskaźnik punktu centralnego stawu
    canvas.drawCircle(center, 3.5, Paint()..color = color);
  }

  void _drawAngleBadge({
    required Canvas canvas,
    required Offset position,
    required String label,
    required String subLabel,
    required Color color,
  }) {
    const double badgeWidth = 92.0;
    const double badgeHeight = 28.0;

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(position.dx, position.dy, badgeWidth, badgeHeight),
      const Radius.circular(6),
    );

    // Tło plakietki
    canvas.drawRRect(
      badgeRect,
      Paint()..color = const Color(0xFF141722).withValues(alpha: 0.92),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Tekst główny
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(position.dx + 6, position.dy + 3));

    // Podtekst statusu
    final subPainter = TextPainter(
      text: TextSpan(
        text: subLabel,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 7.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    subPainter.paint(canvas, Offset(position.dx + 6, position.dy + 15));
  }

  static Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  bool shouldRepaint(covariant RiderBikeFitGeometryPainter oldDelegate) {
    return true; // Płynne odświeżanie animacji dymu i suwaków
  }
}

class _BikeGeometryPoints {
  final Offset rearAxle;
  final Offset frontAxle;
  final Offset bb;
  final Offset saddleCenter;
  final Offset stemClamp;
  final Offset handlebarClamp;
  final Offset hoodsContact;

  const _BikeGeometryPoints({
    required this.rearAxle,
    required this.frontAxle,
    required this.bb,
    required this.saddleCenter,
    required this.stemClamp,
    required this.handlebarClamp,
    required this.hoodsContact,
  });
}

class _RiderKinematics {
  final Offset hip;
  final Offset knee;
  final Offset ankle;
  final Offset pedal;
  final Offset shoulder;
  final Offset elbow;
  final Offset hand;
  final Offset headCenter;
  final double hipAngleDegrees;
  final double kneeAngleDegrees;
  final double torsoAngleDegrees;

  const _RiderKinematics({
    required this.hip,
    required this.knee,
    required this.ankle,
    required this.pedal,
    required this.shoulder,
    required this.elbow,
    required this.hand,
    required this.headCenter,
    required this.hipAngleDegrees,
    required this.kneeAngleDegrees,
    required this.torsoAngleDegrees,
  });
}

// =============================================================================
// PAINTER: MINI-WYKRES POLARNY TUNELU AERODYNAMICZNEGO (CdA vs YAW)
// =============================================================================

class WindTunnelPolarChartPainter extends CustomPainter {
  final WindTunnelPolarReport report;
  final double currentYawDegrees;

  WindTunnelPolarChartPainter({
    required this.report,
    required this.currentYawDegrees,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (report.points.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    // Zakres kąta Yaw: -15° do +15°
    const double minYaw = -15.0;
    const double maxYaw = 15.0;

    // Zakres CdA
    double minCda = report.minCdA * 0.96;
    double maxCda = report.points.map((p) => p.cda).reduce(math.max) * 1.04;
    if (maxCda <= minCda) maxCda = minCda + 0.05;

    double toX(double yaw) => ((yaw - minYaw) / (maxYaw - minYaw)) * width;
    double toY(double cda) => height - ((cda - minCda) / (maxCda - minCda)) * height;

    // 1. Pasmo sweet-spotu efektu żagla (Sailing Effect: 5° do 12.5°)
    final sweetLeftX1 = toX(-12.5);
    final sweetRightX1 = toX(-5.0);
    final sweetLeftX2 = toX(5.0);
    final sweetRightX2 = toX(12.5);

    final sweetPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTRB(sweetLeftX1, 0, sweetRightX1, height), sweetPaint);
    canvas.drawRect(Rect.fromLTRB(sweetLeftX2, 0, sweetRightX2, height), sweetPaint);

    // 2. Osie i linia środkowa Yaw = 0°
    final zeroX = toX(0.0);
    canvas.drawLine(
      Offset(zeroX, 0),
      Offset(zeroX, height),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.25)
        ..strokeWidth = 1.0,
    );

    // 3. Rysowanie krzywej polarnej CdA
    final curvePath = Path();
    final pointsInOrder = report.points.where((p) => p.yawDegrees >= -15.0 && p.yawDegrees <= 15.0).toList()
      ..sort((a, b) => a.yawDegrees.compareTo(b.yawDegrees));

    if (pointsInOrder.isNotEmpty) {
      curvePath.moveTo(toX(pointsInOrder.first.yawDegrees), toY(pointsInOrder.first.cda));
      for (int i = 1; i < pointsInOrder.length; i++) {
        final p = pointsInOrder[i];
        curvePath.lineTo(toX(p.yawDegrees), toY(p.cda));
      }

      // Linia krzywej
      canvas.drawPath(
        curvePath,
        Paint()
          ..color = AppColors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      // Punkty pomiarowe
      for (final p in pointsInOrder) {
        final Offset pt = Offset(toX(p.yawDegrees), toY(p.cda));
        canvas.drawCircle(pt, 3.0, Paint()..color = AppColors.cyanAccent);
      }
    }

    // 4. Kropka aktywnego kąta Yaw
    final activeX = toX(currentYawDegrees.clamp(-15.0, 15.0));
    final activePoint = _interpolateCdaAtYaw(pointsInOrder, currentYawDegrees);
    final activeY = toY(activePoint);

    // Pionowa linia wskaźnika
    canvas.drawLine(
      Offset(activeX, 0),
      Offset(activeX, height),
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.6)
        ..strokeWidth = 1.5,
    );

    // Pulsujący punkt
    canvas.drawCircle(
      Offset(activeX, activeY),
      6.0,
      Paint()..color = AppColors.goldAccent,
    );
    canvas.drawCircle(
      Offset(activeX, activeY),
      2.5,
      Paint()..color = Colors.black,
    );

    // Etykiety osi X: -15°, 0°, +15°
    _drawLabel(canvas, Offset(2, height - 12), '-15°');
    _drawLabel(canvas, Offset(zeroX - 8, height - 12), '0°');
    _drawLabel(canvas, Offset(width - 24, height - 12), '+15°');
  }

  double _interpolateCdaAtYaw(List<WindTunnelYawPoint> points, double yaw) {
    if (points.isEmpty) return 0.220;
    WindTunnelYawPoint closest = points.first;
    double minDiff = (closest.yawDegrees - yaw).abs();
    for (final p in points) {
      final diff = (p.yawDegrees - yaw).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = p;
      }
    }
    return closest.cda;
  }

  void _drawLabel(Canvas canvas, Offset offset, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant WindTunnelPolarChartPainter oldDelegate) {
    return oldDelegate.currentYawDegrees != currentYawDegrees ||
        oldDelegate.report != report;
  }
}
